import pickle
import os
import numpy as np

def tree_to_dart(tree, depth_offset=0):
    left = tree.children_left
    right = tree.children_right
    threshold = tree.threshold
    feature = tree.feature
    value = tree.value

    def recurse(node, depth):
        indent = "  " * (depth + depth_offset)
        if left[node] != -1:
            code = f"{indent}if (features[{feature[node]}] <= {threshold[node]:.6f}) {{\n"
            code += recurse(left[node], depth + 1)
            code += f"{indent}}} else {{\n"
            code += recurse(right[node], depth + 1)
            code += f"{indent}}}\n"
            return code
        else:
            class_idx = np.argmax(value[node])
            return f"{indent}return {class_idx};\n"

    return recurse(0, 0)

def export_model():
    models_dir = 'ml/models'
    processed_dir = 'ml/data/processed'
    model_path = os.path.join(models_dir, 'pose_classifier.pkl')
    labels_path = os.path.join(processed_dir, 'labels.txt')
    output_dart = 'lib/src/features/pose_detection/data/pose_classifier.dart'
    
    if not os.path.exists(model_path):
        print(f"Model {model_path} not found. Please train the model first.")
        return

    # Load labels
    label_map = {}
    if os.path.exists(labels_path):
        with open(labels_path, 'r') as f:
            for line in f:
                if ':' in line:
                    idx, name = line.strip().split(':')
                    label_map[int(idx)] = name

    print(f"Loading model from {model_path}...")
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
        
    print(f"Generating Dart code to {output_dart}...")
    
    # Generate individual tree functions
    tree_functions = []
    for i, estimator in enumerate(model.estimators_):
        func = f"  int _predictTree{i}(List<double> features) {{\n"
        func += tree_to_dart(estimator.tree_, depth_offset=2)
        func += "  }"
        tree_functions.append(func)
    
    tree_calls = "\n".join([f"    votes[_predictTree{i}(features)]++;" for i in range(len(model.estimators_))])
    
    labels_dart = "{" + ", ".join([f"{k}: '{v}'" for k, v in label_map.items()]) + "}"
    
    dart_code = f"""// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Random Forest model with {len(model.estimators_)} trees

class PoseClassifier {{
  static const Map<int, String> labels = {labels_dart};

  /// Predicts the label index from normalized landmarks (x, y, z, visibility)
  int predict(List<double> features) {{
    if (features.length < 33 * 4) return -1;
    
    List<int> votes = List.filled(labels.length, 0);
    
{tree_calls}

    int maxVotes = -1;
    int bestClass = 0;
    for (int i = 0; i < votes.length; i++) {{
      if (votes[i] > maxVotes) {{
        maxVotes = votes[i];
        bestClass = i;
      }}
    }}
    return bestClass;
  }}

  String predictLabel(List<double> features) {{
    int index = predict(features);
    if (index == -1) return 'unknown';
    return labels[index] ?? 'unknown';
  }}

{chr(10).join(tree_functions)}
}}
"""
    
    os.makedirs(os.path.dirname(output_dart), exist_ok=True)
    with open(output_dart, 'w') as f:
        f.write(dart_code)
        
    print(f"Successfully exported to {output_dart}")

if __name__ == "__main__":
    export_model()
