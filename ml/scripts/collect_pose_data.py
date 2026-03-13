import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions
import pandas as pd
import numpy as np
import argparse
import os

def collect_data(video_path, label, start, end):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.normpath(os.path.join(script_dir, '..', 'models', 'pose_landmarker.task'))
    if not os.path.exists(model_path):
        print(f"Error: Model file {model_path} not found.")
        print("Please ensure you've downloaded the task model.")
        return

    # Initialize MediaPipe Tasks Pose Landmarker
    base_options = python.BaseOptions(model_asset_path=model_path)
    options = PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=python.vision.RunningMode.VIDEO
    )

    data = []

    with PoseLandmarker.create_from_options(options) as landmarker:
        cap = cv2.VideoCapture(video_path)

        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps <= 0:
            fps = 30

        # คำนวณ frame ที่จะเริ่มและหยุด
        start_frame = int(start * fps)
        end_frame = int(end * fps) if end else None

        cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)
        current_frame = start_frame

        frame_timestamp_ms = start * 1000

        print(f"Processing {video_path} for label: {label}...")
        print(f"Using video segment: {start}s → {end}s")

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            if end_frame and current_frame > end_frame:
                break

            # Convert to RGB for MediaPipe
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)

            # Detect landmarks
            detection_result = landmarker.detect_for_video(mp_image, int(frame_timestamp_ms))
            frame_timestamp_ms += 1000 / fps
            current_frame += 1

            if detection_result.pose_landmarks:
                landmarks = detection_result.pose_landmarks[0]
                row = []

                for lm in landmarks:
                    row.extend([lm.x, lm.y, lm.z, lm.visibility or 0.0])

                data.append(row)

        cap.release()

    if not data:
        print("No pose detected in video.")
        return

    # Save CSV — use absolute path so it works from any working directory
    output_dir = os.path.normpath(os.path.join(script_dir, '..', 'data', 'raw'))
    os.makedirs(output_dir, exist_ok=True)
    df = pd.DataFrame(data)
    output_path = os.path.join(output_dir, f'{label}.csv')

    if os.path.exists(output_path):
        df.to_csv(output_path, mode='a', header=False, index=False)
    else:
        df.to_csv(output_path, index=False)

    print(f"Saved {len(data)} frames to {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", required=True, help="Path to video file")
    parser.add_argument("--label", required=True, help="Label for the pose")
    parser.add_argument("--start", type=float, default=0, help="Start time in seconds")
    parser.add_argument("--end", type=float, default=None, help="End time in seconds")

    args = parser.parse_args()

    collect_data(args.video, args.label, args.start, args.end)