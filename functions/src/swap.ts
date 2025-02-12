import 'dotenv/config';
import Replicate from "replicate";
import { writeFile } from "node:fs/promises";
import { readFile } from "node:fs/promises";

async function swapFace() {
    console.log('Starting face swap process...');
    
    try {
        const replicate = new Replicate({
            auth: process.env.REPLICATE_API_TOKEN,
        });

        if (!process.env.REPLICATE_API_TOKEN) {
            throw new Error('REPLICATE_API_TOKEN is not set in environment variables');
        }

        // Use publicly accessible URLs instead of local files
        console.log('Preparing input files...');
        const swapImageFile = await readFile("./assets/taylor-as-tiger-copy.jpg");
        const targetVideoFile = await readFile("./assets/never-copy.mp4");

        const input = {
            swap_image: swapImageFile,
            target_video: targetVideoFile,
            detect_target_face: true,
            output_format: "mp4",
            video_quality: "better"  // or try "fast" for testing
        };


        console.log('Input configuration:', JSON.stringify(input, null, 2));
        console.log('Initiating API call to Replicate...');

        const output = await replicate.run(
            "arabyai-replicate/roop_face_swap:11b6bf0f4e14d808f655e87e5448233cceff10a45f659d71539cafb7163b2e84",
            { input }
        );

        console.log('Face swap completed, output:', output);
        console.log('Writing to file...');
        
        if (!output) {
            throw new Error('No output received from Replicate API');
        }

        await writeFile("output.mp4", output);
        console.log('Process completed successfully!');
    } catch (error) {
        console.error('Error during face swap:', error);
        if (error.response) {
            console.error('API Response:', error.response.data);
        }
        throw error;
    }
}

// Execute the function
swapFace().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});