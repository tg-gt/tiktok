import {onObjectFinalized} from "firebase-functions/v2/storage";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {performFaceSwap} from "./services/faceSwapService.js";
import {downloadFile, uploadToStorage} from "./utils/storage.js";

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

interface FaceSwapRequest {
    sourceVideoUrl: string;
    faceImageUrl: string;
}

// MARK: - Face Swap Function
export const generateFaceSwap = onCall<FaceSwapRequest>(async (request) => {
    // Log function invocation
    const userId = request.auth?.uid;
    logger.info("Face swap generation requested", { userId });

    // Authenticate request
    if (!userId) {
        logger.error("Unauthorized face swap attempt");
        throw new HttpsError("unauthenticated", "Must be authenticated to perform face swap");
    }

    const {sourceVideoUrl, faceImageUrl} = request.data;
    
    // Validate input parameters
    if (!sourceVideoUrl || !faceImageUrl) {
        logger.error("Missing required parameters", { sourceVideoUrl, faceImageUrl });
        throw new HttpsError("invalid-argument", "Missing sourceVideoUrl or faceImageUrl");
    }

    try {
        // 1. Create new video document with processing status
        const newVideoRef = admin.firestore().collection("videos").doc();
        const newVideoData = {
            userId,
            status: "processing",
            title: "Face Swap Video",
            description: "AI-generated face swap video",
            category: ["AI Generated"],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            likesCount: 0,
            commentsCount: 0,
            isAIGenerated: true,
            originalVideoUrl: sourceVideoUrl,
            faceImageUrl: faceImageUrl
        };

        logger.info("Creating new video document", { newVideoId: newVideoRef.id });
        await newVideoRef.set(newVideoData);

        // 2. Perform face swap using Replicate
        logger.info("Starting face swap process");
        const swappedVideoUrl = await performFaceSwap(faceImageUrl, sourceVideoUrl);

        // 3. Download the swapped video and re-upload to our Storage
        logger.info("Downloading swapped video for storage");
        const videoBuffer = await downloadFile(swappedVideoUrl);
        
        // 4. Upload to our storage with a proper path
        const storagePath = `face-swaps/${newVideoRef.id}.mp4`;
        const finalVideoUrl = await uploadToStorage(
            videoBuffer,
            storagePath,
            "video/mp4"
        );

        // 5. Update video document with result
        logger.info("Updating video document with results", { videoId: newVideoRef.id });
        await newVideoRef.update({
            status: "completed",
            videoUrl: finalVideoUrl,
            thumbnailUrl: faceImageUrl, // Use the face image as thumbnail for now
            completedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            videoId: newVideoRef.id,
            videoUrl: finalVideoUrl
        };
    } catch (error: any) {
        logger.error("Face swap generation failed:", error);
        throw new HttpsError("internal", "Failed to generate face swap", error.message);
    }
});
