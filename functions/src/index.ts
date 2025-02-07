import {onObjectFinalized} from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

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
      videoId: docId,
      videoUrl: signedUrl,
      title: docId, // Consider extracting a better title from metadata if possible
      category: "Default", //  Allow users to set this, or use metadata
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
