import Replicate from "replicate";
import * as logger from "firebase-functions/logger";

// Initialize Replicate with API token
const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

/**
 * Performs face swap operation using Replicate's roop_face_swap model
 * @param swapImageUrl URL of the face image to swap from
 * @param targetVideoUrl URL of the video to swap into
 * @returns Promise<string> URL of the generated video
 */
export async function performFaceSwap(
  swapImageUrl: string,
  targetVideoUrl: string
): Promise<string> {
  logger.info("Starting face swap operation", { swapImageUrl, targetVideoUrl });

  try {
    // Configure input for the roop_face_swap model
    const input = {
      swap_image: swapImageUrl,
      target_video: targetVideoUrl,
      detect_target_face: true,
      output_format: "mp4",
      video_quality: "better",
    };

    logger.info("Calling Replicate API with input", input);

    // Run the face swap model
    const output = await replicate.run(
      "arabyai-replicate/roop_face_swap:11b6bf0f4e14d808f655e87e5...",
      { input }
    );

    if (!output) {
      logger.error("No output received from Replicate");
      throw new Error("No output from replicate");
    }

    // Ensure output is a string (URL)
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