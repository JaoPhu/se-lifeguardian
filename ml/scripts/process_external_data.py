import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions
import pandas as pd
import numpy as np
import argparse
import os
import glob

def process_image_folder(folder_path, label):
    model_path = 'ml/models/pose_landmarker.task'
    if not os.path.exists(model_path):
        print(f"Error: Model file {model_path} not found.")
        return 0

    base_options = python.BaseOptions(model_asset_path=model_path)
    options = PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=python.vision.RunningMode.IMAGE
    )
    
    data = []
    
    # Support common image extensions
    extensions = ['*.jpg', '*.jpeg', '*.png', '*.JPG', '*.PNG']
    image_paths = []
    for ext in extensions:
        image_paths.extend(glob.glob(os.path.join(folder_path, ext)))
    
    if not image_paths:
        # Check subdirectories too (Jethani structure)
        for ext in extensions:
            image_paths.extend(glob.glob(os.path.join(folder_path, "**", ext), recursive=True))

    if not image_paths:
        print(f"No images found in {folder_path}")
        return 0

    image_paths.sort()
    print(f"Processing {len(image_paths)} images from {folder_path} for label: {label}...")
    
    with PoseLandmarker.create_from_options(options) as landmarker:
        for i, img_path in enumerate(image_paths):
            if i % 50 == 0:
                print(f"Progress: {i}/{len(image_paths)} images processed...")
                
            frame = cv2.imread(img_path)
            if frame is None:
                continue
                
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)
            
            detection_result = landmarker.detect(mp_image)
            
            if detection_result.pose_landmarks:
                landmarks = detection_result.pose_landmarks[0]
                row = []
                for lm in landmarks:
                    row.extend([lm.x, lm.y, lm.z, lm.visibility or 0.0])
                data.append(row)
    
    if not data:
        print(f"No pose detected in images from {folder_path}.")
        return 0
        
    os.makedirs('ml/data/raw', exist_ok=True)
    df = pd.DataFrame(data)
    output_path = f'ml/data/raw/{label}.csv'
    
    if os.path.exists(output_path):
        df.to_csv(output_path, mode='a', header=False, index=False)
    else:
        df.to_csv(output_path, index=False)
        
    print(f"Saved {len(data)} frames to {output_path}")
    return len(data)

def process_segment(video_path, label, start_sec, end_sec):
    model_path = 'ml/models/pose_landmarker.task'
    if not os.path.exists(model_path):
        print(f"Error: Model file {model_path} not found.")
        return 0

    base_options = python.BaseOptions(model_asset_path=model_path)
    options = PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=python.vision.RunningMode.VIDEO
    )
    
    data = []
    
    with PoseLandmarker.create_from_options(options) as landmarker:
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps <= 0: fps = 30
        
        start_frame = int(start_sec * fps)
        end_frame = int(end_sec * fps)
        
        cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)
        
        current_frame = start_frame
        print(f"Processing {video_path} [{start_sec}s - {end_sec}s] for label: {label}...")
        
        while cap.isOpened() and current_frame <= end_frame:
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_timestamp_ms = int((current_frame / fps) * 1000)
            
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)
            
            detection_result = landmarker.detect_for_video(mp_image, frame_timestamp_ms)
            
            if detection_result.pose_landmarks:
                landmarks = detection_result.pose_landmarks[0]
                row = []
                for lm in landmarks:
                    row.extend([lm.x, lm.y, lm.z, lm.visibility or 0.0])
                data.append(row)
            
            current_frame += 1
                
        cap.release()
    
    if not data:
        print(f"No pose detected in segment of {video_path}.")
        return 0
        
    os.makedirs('ml/data/raw', exist_ok=True)
    df = pd.DataFrame(data)
    output_path = f'ml/data/raw/{label}.csv'
    
    if os.path.exists(output_path):
        df.to_csv(output_path, mode='a', header=False, index=False)
    else:
        df.to_csv(output_path, index=False)
        
    print(f"Saved {len(data)} frames to {output_path}")
    return len(data)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", help="Path to video file or image directory")
    parser.add_argument("--label", help="Label for the data")
    parser.add_argument("--start", type=float, default=0, help="Start time (sec) for video")
    parser.add_argument("--end", type=float, default=9999, help="End time (sec) for video")
    
    args = parser.parse_args()
    
    if args.input and args.label:
        if os.path.isdir(args.input):
            process_image_folder(args.input, args.label)
        else:
            process_segment(args.input, args.label, args.start, args.end)
    else:
        parser.print_help()
