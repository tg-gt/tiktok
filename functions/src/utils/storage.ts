import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import fetch from "node-fetch";

/**
 * Downloads a file from a URL and returns it as a Buffer
 */
export async function downloadFile(url: string): Promise<Buffer> {
  logger.info("Downloading file from URL", { url });
  
  const response = await fetch(url);
  if (!response.ok) {
    logger.error("Failed to download file", { url, status: response.status });
    throw new Error(`Failed to download file from ${url}`);
  }
  
  const buffer = Buffer.from(await response.arrayBuffer());
  logger.info("File downloaded successfully", { url, size: buffer.length });
  return buffer;
}

/**
 * Uploads a buffer to Firebase Storage and returns a signed URL
 */
export async function uploadToStorage(
  buffer: Buffer,
  path: string,
  contentType: string
): Promise<string> {
  logger.info("Uploading file to storage", { path, contentType });
  
  const bucket = admin.storage().bucket();
  const fileRef = bucket.file(path);

  try {
    await fileRef.save(buffer, {
      metadata: { contentType },
    });

    // Generate a signed URL that expires far in the future
    const [signedUrl] = await fileRef.getSignedUrl({
      action: "read",
      expires: "03-01-2500",
    });

    logger.info("File uploaded successfully", { path, signedUrl });
    return signedUrl;
  } catch (error) {
    logger.error("Failed to upload file", { path, error });
    throw error;
  }
} 