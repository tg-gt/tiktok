import "dotenv/config";
import Replicate from "replicate";
import { writeFile, readFile } from "node:fs/promises";

interface ErrorWithResponse extends Error {
  response?: {
    data: unknown;
  };
}

/**
 * Performs a face swap operation using the Replicate API.
 */
async function swapFace(): Promise<void> {
  console.log("Starting face swap process...");

  try {
    const replicate = new Replicate({
      auth: process.env.REPLICATE_API_TOKEN,
    });

    if (!process.env.REPLICATE_API_TOKEN) {
      throw new Error("REPLICATE_API_TOKEN is not set in environment variables");
    }

    console.log("Preparing input files...");
    const swapImageFile = await readFile("./assets/taylor-as-tiger-copy.jpg");
    const targetVideoFile = await readFile("./assets/never-copy.mp4");

    const input = {
      swap_image: swapImageFile,
      target_video: targetVideoFile,
      detect_target_face: true,
      output_format: "mp4",
      video_quality: "better",
    };

    console.log("Input configuration:", JSON.stringify(input, null, 2));
    console.log("Initiating API call to Replicate...");

    const modelName =
      "arabyai-replicate/roop_face_swap:11b6bf0f4e14d808f655e87e5448233cceff10a45f659d71539cafb7163b2e84";
    const output = await replicate.run(modelName, { input });

    console.log("Face swap completed, output:", output);
    console.log("Writing to file...");

    if (!output) {
      throw new Error("No output received from Replicate API");
    }

    await writeFile("output.mp4", output);
    console.log("Process completed successfully!");
  } catch (error: unknown) {
    const err = error as ErrorWithResponse;
    console.error("Error during face swap:", err);
    if (err.response) {
      console.error("API Response:", err.response.data);
    }
    throw error;
  }
}

// Execute the function
swapFace().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
