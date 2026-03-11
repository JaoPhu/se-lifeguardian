import pandas as pd
import numpy as np
import os
from sklearn.model_selection import train_test_split

def prepare_data():
    raw_dir = 'ml/data/raw'
    processed_dir = 'ml/data/processed'
    os.makedirs(processed_dir, exist_ok=True)
    
    all_data = []
    
    # Map filenames/labels to numerical IDs
    labels = [f.split('.')[0] for f in os.listdir(raw_dir) if f.endswith('.csv')]
    label_map = {label: i for i, label in enumerate(labels)}
    
    print(f"Found labels: {label_map}")
    
    for label in labels:
        df = pd.read_csv(os.path.join(raw_dir, f'{label}.csv'))
        df['target'] = label_map[label]
        all_data.append(df)
        
    if not all_data:
        print("No data to process.")
        return
        
    full_df = pd.concat(all_data, ignore_index=True)
    
    # Shuffle and split
    train_df, test_df = train_test_split(full_df, test_size=0.2, random_state=42, stratify=full_df['target'])
    
    train_df.to_csv(os.path.join(processed_dir, 'train.csv'), index=False)
    test_df.to_csv(os.path.join(processed_dir, 'test.csv'), index=False)
    
    # Save label mapping for reference
    with open(os.path.join(processed_dir, 'labels.txt'), 'w') as f:
        for label, idx in label_map.items():
            f.write(f"{idx}:{label}\n")
            
    print(f"Prepared {len(full_df)} samples. Train: {len(train_df)}, Test: {len(test_df)}")

if __name__ == "__main__":
    prepare_data()
