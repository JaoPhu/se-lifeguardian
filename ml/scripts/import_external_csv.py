import pandas as pd
import urllib.request
import os
import argparse

def download_and_import_htanh(output_path):
    """
    Downloads HTAnh2003 Sitting/Standing/Lying dataset (33 points, x and y only)
    Converts 66 columns to our 132 column format (padding Z and Visibility with 0)
    Uses urllib.request to avoid dependency issues.
    """
    url = "https://raw.githubusercontent.com/HTAnh2003/Classification-of-Human-Postures-Sitting-Standing-Lying/main/train_3label.csv"
    print(f"Downloading external data from {url}...")
    
    temp_file = "ml/data/temp_htanh.csv"
    try:
        # Bypass SSL verification for environments with missing certificates
        import ssl
        context = ssl._create_unverified_context()
        with urllib.request.urlopen(url, context=context) as response, open(temp_file, 'wb') as out_file:
            out_file.write(response.read())
    except Exception as e:
        print(f"Error: Could not download file. {e}")
        return
        
    df = pd.read_csv(temp_file)
    # HTAnh mapping: 0,1 are X,Y for point 0, etc.
    # Label mapping in HTAnh: 0=Standing, 1=Sitting, 2=Lying (Standard SVM labels)
    
    print(f"Processing {len(df)} rows from HTAnh...")
    
    new_data = []
    for _, row in df.iterrows():
        # Columns 0-65 are X, Y
        coords = row.iloc[:-1].values
        # Expand to 132 (X, Y, Z, V)
        expanded = []
        for i in range(0, 66, 2):
            x = coords[i]
            y = coords[i+1]
            expanded.extend([x, y, 0.0, 0.0]) # Pad Z and V with 0
        new_data.append(expanded)
        
    df_new = pd.DataFrame(new_data)
    df_new['label'] = df['label']
    
    # Map their numeric labels to names compatible with our system
    label_map = {0: 'standing_external', 1: 'sitting_external', 2: 'lying_external'}
    
    os.makedirs(output_path, exist_ok=True)
    
    for l_val, l_name in label_map.items():
        subset = df_new[df_new['label'] == l_val].drop(columns=['label'])
        if not subset.empty:
            out_file = os.path.join(output_path, f"{l_name}.csv")
            # Append if exists, else create
            if os.path.exists(out_file):
                subset.to_csv(out_file, mode='a', header=False, index=False)
            else:
                subset.to_csv(out_file, index=False)
            print(f"Imported {len(subset)} rows to {out_file}")
            
    os.remove(temp_file)
    print("HTAnh import complete.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", choices=['htanh'], default='htanh', help="External source to import")
    args = parser.parse_args()
    
    if args.source == 'htanh':
        download_and_import_htanh("ml/data/raw")
