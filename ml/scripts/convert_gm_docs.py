import pandas as pd
import re
import os
import argparse

def parse_gm_csv(input_csv, output_metadata):
    """
    Parses GMDCSA24 CSV format: 
    File Name, Length, ..., Labels[Start to End]; Labels[Start to End]
    Converts to: File Name, Start Sec, End Sec, Label
    """
    df = pd.read_csv(input_csv)
    rows = []
    
    for _, row in df.iterrows():
        file_name = str(row.iloc[0]).strip()
        # The last column (usually index 5) contains the classes/times
        labels_str = str(row.iloc[-1])
        
        # Pattern: LabelName[Start to End]
        matches = re.finditer(r'([a-zA-Z\s]+)\[([\d\.]+)\s+to\s+([\d\.]+)\]', labels_str)
        
        for match in matches:
            label = match.group(1).strip().lower().replace(' ', '_')
            start = match.group(2)
            end = match.group(3)
            rows.append({
                'File Name': file_name,
                'Start Sec': start,
                'End Sec': end,
                'Label': label
            })
            
    if rows:
        out_df = pd.DataFrame(rows)
        out_df.to_csv(output_metadata, index=False)
        print(f"Successfully converted {len(rows)} segments to {output_metadata}")
    else:
        print(f"No valid segments found in {input_csv}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Path to GMDCSA24 CSV")
    parser.add_argument("--output", required=True, help="Path to save processed metadata CSV")
    args = parser.parse_args()
    
    parse_gm_csv(args.input, args.output)
