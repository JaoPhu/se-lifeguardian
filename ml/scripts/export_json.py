import pickle
import json
import os
import numpy as np

def export_to_json():
    model_path = 'ml/models/pose_classifier.pkl'
    labels_path = 'ml/data/processed/labels.txt'
    output_json = 'assets/models/pose_classifier.json'
    
    if not os.path.exists(model_path):
        print(f"Error: {model_path} not found.")
        return

    # Load labels
    label_map = {}
    if os.path.exists(labels_path):
        with open(labels_path, 'r') as f:
            for line in f:
                if ':' in line:
                    idx, name = line.strip().split(':')
                    label_map[int(idx)] = name

    print(f"Loading model: {model_path}")
    with open(model_path, 'rb') as f:
        model = pickle.load(f)

    def extract_tree(tree):
        # Recursive function to extract tree structure
        def get_node(node_id):
            if tree.children_left[node_id] == -1:
                # Leaf node: return class probabilities or best class
                return {
                    "v": int(np.argmax(tree.value[node_id]))
                }
            else:
                # Decision node
                return {
                    "f": int(tree.feature[node_id]), # feature index
                    "t": float(tree.threshold[node_id]), # threshold
                    "l": get_node(tree.children_left[node_id]), # left child
                    "r": get_node(tree.children_right[node_id]) # right child
                }
        return get_node(0)

    print(f"Converting {len(model.estimators_)} trees...")
    trees = [extract_tree(estimator.tree_) for estimator in model.estimators_]

    model_data = {
        "labels": label_map,
        "n_trees": len(trees),
        "trees": trees
    }

    os.makedirs(os.path.dirname(output_json), exist_ok=True)
    with open(output_json, 'w') as f:
        json.dump(model_data, f, separators=(',', ':')) # Compact format

    print(f"Model exported to {output_json} (Size: {os.path.getsize(output_json) / 1024:.1f} KB)")

if __name__ == "__main__":
    export_to_json()
