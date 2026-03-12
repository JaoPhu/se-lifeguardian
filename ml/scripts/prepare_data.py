import pandas as pd
import numpy as np
import os
import re
from sklearn.model_selection import train_test_split

def prepare_data():
    raw_dir = 'ml/data/raw'
    processed_dir = 'ml/data/processed'
    os.makedirs(processed_dir, exist_ok=True)
    
    # Core categories used by the app's UI
    # We map all raw filenames to these 6 labels
    categories = ['falling', 'sitting', 'laying', 'walking', 'standing', 'exercise']
    category_to_id = {cat: i for i, cat in enumerate(categories)}
    
    print(f"Target Categories: {category_to_id}")
    
    all_data = []
    
    # Traverse raw_dir recursively
    for root, dirs, files in os.walk(raw_dir):
        for filename in files:
            if not filename.endswith('.csv'):
                continue
                
            filepath = os.path.join(root, filename)
            
            # Detect category from filename or parent folder
            # Lowercase and remove Thai " สำเนา" or "Copy" etc
            path_str = (filename + " " + root).lower()
            
            target_cat = None
            if any(k in path_str for k in ['fall', 'falling', 'fallen']):
                target_cat = 'falling'
            elif any(k in path_str for k in ['sitting', 'sit', 'siting', 'slumped', 'slouching', 'chair']):
                target_cat = 'sitting'
            elif any(k in path_str for k in ['lying', 'lay', 'resting', 'unconscious']):
                target_cat = 'laying'
            elif any(k in path_str for k in ['walking', 'walk', 'stairs']):
                target_cat = 'walking'
            elif any(k in path_str for k in ['standing', 'stand', 'upright']):
                target_cat = 'standing'
            elif any(k in path_str for k in ['exercise', 'pushups', 'squatting', 'squat']):
                target_cat = 'exercise'
            
            if target_cat:
                try:
                    df = pd.read_csv(filepath)
                    # Check if it has target column already, if so drop it to avoid confusion
                    if 'target' in df.columns:
                        df = df.drop('target', axis=1)
                    
                    df['target'] = category_to_id[target_cat]
                    all_data.append(df)
                    print(f"Loaded {len(df)} samples from {filename} -> Map to '{target_cat}'")
                except Exception as e:
                    print(f"Error loading {filename}: {e}")
            else:
                print(f"Skipping {filename}: Could not determine category")
    
    if not all_data:
        print("No CSV files found.")
        return
        
    full_df = pd.concat(all_data, ignore_index=True)
    
    # Shuffle and split
    # Stratify needs at least some samples from each class
    counts = full_df['target'].value_counts()
    print("\nSamples per category:")
    for cat, idx in category_to_id.items():
        print(f" - {cat}: {counts.get(idx, 0)}")

    train_df, test_df = train_test_split(full_df, test_size=0.2, random_state=42, stratify=full_df['target'])
    
    train_df.to_csv(os.path.join(processed_dir, 'train.csv'), index=False)
    test_df.to_csv(os.path.join(processed_dir, 'test.csv'), index=False)
    
    # Save label mapping for reference
    with open(os.path.join(processed_dir, 'labels.txt'), 'w') as f:
        for cat, idx in category_to_id.items():
            f.write(f"{idx}:{cat}\n")
            
    print(f"\nSUCCESS: Prepared {len(full_df)} total samples.")
    print(f"Train: {len(train_df)}, Test: {len(test_df)}")

if __name__ == "__main__":
    prepare_data()
