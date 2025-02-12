import Replicate from "replicate";
import * as logger from "firebase-functions/logger";

// Initialize Replicate with API token
const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

/**
 * Performs face swap operation using Replicate's roop_face_swap model.
 * @param {string} swapImageUrl - URL of the face image to swap from
 * @param {string} targetVideoUrl - URL of the video to swap into
 * @return {Promise<string>} A promise that resolves to the URL of the generated video
 */
export async function performFaceSwap(
  swapImageUrl: string,
  targetVideoUrl: string,
): Promise<string> {
  logger.info("Starting face swap operation", { swapImageUrl, targetVideoUrl });

  try {
    const input = {
      swap_image: swapImageUrl,
      target_video: targetVideoUrl,
      detect_target_face: true,
      output_format: "mp4",
      video_quality: "better",
    };

    logger.info("Calling Replicate API with input", input);

    // Split the model name so it doesn't exceed 80 chars
    const modelName =
      "arabyai-replicate/roop_face_swap:11b6bf0f4e14d808f655e87e5448233cceff10a45f659d71539cafb7163b2e84";
    const output = await replicate.run(modelName, { input });

    if (!output) {
      logger.error("No output received from Replicate");
      throw new Error("No output from replicate");
    }

    if (typeof output !== "string") {
      logger.error("Unexpected output type from Replicate", { output });
      throw new Error("Unexpected output type from Replicate");
    }

    logger.info("Face swap completed successfully", { output });
    return output;
  } catch (error) {
    logger.error("Face swap operation failed", error);
    throw error;
  }
}
