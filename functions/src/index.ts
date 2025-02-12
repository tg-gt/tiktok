import {onObjectFinalized} from "firebase-functions/v2/storage";
import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import fetch from "node-fetch";

admin.initializeApp();

// Replicate API configuration
const REPLICATE_API_KEY = process.env.REPLICATE_API_KEY;
const FACE_SWAP_MODEL = "codeplugtech/face-swap";
const VIDEO_GEN_MODEL = "stability-ai/stable-video-diffusion";

// Helper function to extract first frame from video
async function extractFirstFrame(videoUrl: string): Promise<string> {
    // TODO: Implement using FFmpeg Cloud Function
    // For now, we'll use a placeholder implementation
    logger.info("Extracting first frame from video:", videoUrl);
    
    // This should be replaced with actual FFmpeg implementation
    return videoUrl;
}

// Helper function to call Replicate API
async function callReplicate(modelVersion: string, input: any) {
    logger.info("Calling Replicate API with model:", modelVersion);
    
    const response = await fetch("https://api.replicate.com/v1/predictions", {
        method: "POST",
        headers: {
            "Authorization": `Token ${REPLICATE_API_KEY}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            version: modelVersion,
            input: input,
        }),
    });

    if (!response.ok) {
        const error = await response.text();
        logger.error("Replicate API error:", error);
        throw new Error(`Replicate API error: ${error}`);
    }

    const prediction = await response.json();
    logger.info("Replicate prediction started:", prediction);

    // Poll for completion
    while (true) {
        const statusResponse = await fetch(`https://api.replicate.com/v1/predictions/${prediction.id}`, {
            headers: {
                "Authorization": `Token ${REPLICATE_API_KEY}`,
            },
        });
        
        const status = await statusResponse.json();
        
        if (status.status === "succeeded") {
            logger.info("Replicate prediction succeeded:", status);
            return status.output;
        } else if (status.status === "failed") {
            logger.error("Replicate prediction failed:", status);
            throw new Error(`Prediction failed: ${status.error}`);
        }
        
        // Wait before polling again
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
}

export const onVideoUpload = onObjectFinalized(async (event) => {
  // Destructure data directly, handling potential undefined values safely
  const {name: filePath, bucket: bucketName, contentType} = event.data;

  // 1. Input Validation and Content Type Check:
  if (!filePath) {
    logger.warn("No file path provided in the event.");
    return;
  }

  if (!contentType || !contentType.startsWith("video/mp4")) {
    logger.info(`Ignoring non-mp4 file: ${filePath} (Type: ${contentType})`);
    return;
  }
  if (!bucketName) {
    logger.error("No bucket name found in event.");
    return;
  }

  logger.info(`Processing new MP4 upload: ${filePath}`);

  // 2. Get a reference to the bucket and file:
  const bucket = admin.storage().bucket(bucketName);
  const file = bucket.file(filePath);

  // 3. Generate Signed URL (with error handling):
  let signedUrl: string;
  try {
    const [url] = await file.getSignedUrl({
      action: "read",
      expires: "03-01-2030", // Long expiration date
    });
    signedUrl = url;
    logger.info(`Generated signed URL: ${signedUrl}`);
  } catch (error) {
    logger.error(`Error generating signed URL for ${filePath}:`, error);
    return; // Critical: Exit if we can't get the URL
  }

  // 4. Extract Document ID (safely handle path):
  const docId = filePath.replace(/\.mp4$/i, "").replace(/^.*\//, ""); // Use regex for case-insensitivity and remove any leading path
  if (!docId) {
    logger.error("Could not determine document ID from filename " + filePath);
    return; // Cannot continue
  }

  logger.info(`Extracted Doc ID: ${docId}`);

  // 5. Firestore Document Creation (with error handling):
  try {
    const videoData = {
      videoUrl: signedUrl,
      title: docId,
      category: ["Default"],
      likesCount: 0,
      commentsCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore().collection("videos").doc(docId).set(videoData, {merge: true});
    logger.info(`Successfully created/updated document in 'videos' collection: ${docId}`);
  } catch (error) {
    logger.error(`Error writing to Firestore for ${docId}:`, error);
    // Consider:  Do you want to delete the file if Firestore fails?
  }
});

// MARK: - Face Swap Function
export const generateFaceSwap = onCall(async (data, context) => {
    // Log function invocation
    logger.info("Face swap generation requested", { userId: context.auth?.uid });

    // Authenticate request
    if (!context.auth) {
        logger.error("Unauthorized face swap attempt");
        throw new Error('Unauthorized');
    }

    const {sourceVideoId, faceImageUrl} = data;
    
    // Validate input parameters
    if (!sourceVideoId || !faceImageUrl) {
        logger.error("Missing required parameters", { sourceVideoId, faceImageUrl });
        throw new Error('Missing required parameters');
    }

    try {
        // 1. Get source video URL from Firestore
        logger.info("Fetching source video", { sourceVideoId });
        const videoDoc = await admin.firestore().collection('videos').doc(sourceVideoId).get();
        const videoData = videoDoc.data();
        if (!videoData?.videoUrl) {
            logger.error("Source video not found", { sourceVideoId });
            throw new Error('Source video not found');
        }

        // 2. Create new video document with processing status
        const newVideoRef = admin.firestore().collection('videos').doc();
        const newVideoData = {
            userId: context.auth.uid,
            sourceVideoId,
            status: 'processing',
            title: `Face Swap of ${videoData.title || 'Video'}`,
            description: `AI-generated face swap video`,
            category: videoData.category || [],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            likesCount: 0,
            commentsCount: 0,
            isAIGenerated: true,
            originalVideoUrl: videoData.videoUrl,
            faceImageUrl: faceImageUrl
        };

        logger.info("Creating new video document", { newVideoId: newVideoRef.id });
        await newVideoRef.set(newVideoData);

        // 3. Extract first frame from source video
        const firstFrame = await extractFirstFrame(videoData.videoUrl);
        logger.info("First frame extracted", { firstFrame });

        // 4. Perform face swap on first frame
        const faceSwapOutput = await callReplicate(FACE_SWAP_MODEL, {
            source_image: firstFrame,
            target_image: faceImageUrl,
        });
        logger.info("Face swap completed", { faceSwapOutput });

        // 5. Generate video from face-swapped image
        const videoOutput = await callReplicate(VIDEO_GEN_MODEL, {
            image: faceSwapOutput,
            motion_bucket_id: 127,  // Controls the amount of motion
            fps: 24,
        });
        logger.info("Video generation completed", { videoOutput });

        // 6. Update video document with result
        await newVideoRef.update({
            status: 'completed',
            videoUrl: videoOutput,
            thumbnailUrl: faceSwapOutput,  // Use the face-swapped first frame as thumbnail
        });

        return {
            success: true,
            videoId: newVideoRef.id,
            status: 'completed',
            videoUrl: videoOutput
        };
    } catch (error) {
        logger.error('Face swap generation failed:', error);
        throw new Error('Failed to generate face swap: ' + error.message);
    }
});
