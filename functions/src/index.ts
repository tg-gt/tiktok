import { onObjectFinalized } from "firebase-functions/v2/storage";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { performFaceSwap } from "./services/faceSwapService.js";
import { downloadFile, uploadToStorage } from "./utils/storage.js";

admin.initializeApp();

// Replicate API configuration (Used in commented-out code)
// const REPLICATE_API_KEY = process.env.REPLICATE_API_KEY;
// ^ Removed or commented out to avoid no-unused-vars

/**
 * Firebase Storage trigger that creates/updates a Firestore document
 * when a new video is uploaded.
 */
export const onVideoUpload = onObjectFinalized(async (event) => {
  const { name: filePath, bucket: bucketName, contentType } = event.data;

  if (!filePath) {
    logger.warn("No file path provided in the event.");
    return;
  }

  if (!contentType || !contentType.startsWith("video/mp4")) {
    logger.info(
      `Ignoring non-mp4 file: ${filePath} (Type: ${contentType})`,
    );
    return;
  }
  if (!bucketName) {
    logger.error("No bucket name found in event.");
    return;
  }

  logger.info(`Processing new MP4 upload: ${filePath}`);

  const bucket = admin.storage().bucket(bucketName);
  const file = bucket.file(filePath);

  let signedUrl: string;
  try {
    const [url] = await file.getSignedUrl({
      action: "read",
      expires: "03-01-2030",
    });
    signedUrl = url;
    logger.info(
      `Generated signed URL: ${signedUrl}`,
    );
  } catch (error) {
    logger.error(`Error generating signed URL for ${filePath}:`, error);
    return;
  }

  const docId = filePath
    .replace(/\.mp4$/i, "")
    .replace(/^.*\//, ""); // Use regex
  if (!docId) {
    logger.error(
      `Could not determine document ID from filename ${filePath}`,
    );
    return;
  }

  logger.info(`Extracted Doc ID: ${docId}`);

  try {
    const videoData = {
      videoUrl: signedUrl,
      title: docId,
      category: ["Default"],
      likesCount: 0,
      commentsCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin
      .firestore()
      .collection("videos")
      .doc(docId)
      .set(videoData, { merge: true });

    logger.info(
      "Successfully created/updated document in 'videos' collection",
    );
  } catch (error) {
    logger.error(`Error writing to Firestore for ${docId}:`, error);
  }
});

interface FaceSwapRequest {
  sourceVideoUrl: string;
  faceImageUrl: string;
}

/**
 * Callable function to generate a face-swapped video.
 * @param {FaceSwapRequest} request - The request data containing source and face image URLs
 * @return {Promise<{success: boolean; videoId: string; videoUrl: string}>}
 */
export const generateFaceSwap = onCall<FaceSwapRequest>(async (request) => {
  const userId = request.auth?.uid;
  logger.info("Face swap generation requested", { userId });

  if (!userId) {
    logger.error("Unauthorized face swap attempt");
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const { sourceVideoUrl, faceImageUrl } = request.data;

  if (!sourceVideoUrl || !faceImageUrl) {
    logger.error("Missing required parameters", { sourceVideoUrl, faceImageUrl });
    throw new HttpsError(
      "invalid-argument",
      "Missing sourceVideoUrl or faceImageUrl",
    );
  }

  try {
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
      faceImageUrl: faceImageUrl,
    };

    logger.info("Creating new video document", { newVideoId: newVideoRef.id });
    await newVideoRef.set(newVideoData);

    logger.info("Starting face swap process");
    const swappedVideoUrl = await performFaceSwap(faceImageUrl, sourceVideoUrl);

    logger.info("Downloading swapped video for storage");
    const videoBuffer = await downloadFile(swappedVideoUrl);

    const storagePath = `face-swaps/${newVideoRef.id}.mp4`;
    const finalVideoUrl = await uploadToStorage(
      videoBuffer,
      storagePath,
      "video/mp4",
    );

    logger.info("Updating video document", { videoId: newVideoRef.id });
    await newVideoRef.update({
      status: "completed",
      videoUrl: finalVideoUrl,
      thumbnailUrl: faceImageUrl,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      videoId: newVideoRef.id,
      videoUrl: finalVideoUrl,
    };
  } catch (error: unknown) {
    logger.error("Face swap generation failed:", error);
    if (error instanceof Error) {
      throw new HttpsError("internal", "Failed to generate face swap", error.message);
    } else {
      throw new HttpsError("internal", "Failed to generate face swap");
    }
  }
});
