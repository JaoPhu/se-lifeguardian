import 'dart:convert';
import 'package:flutter/services.dart';

class OptimizedPoseClassifier {
  Map<int, String> _labels = {};
  List<dynamic> _trees = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/models/pose_classifier.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final Map<String, dynamic> labelMap = data['labels'];
      _labels = labelMap.map((key, value) => MapEntry(int.parse(key), value.toString()));
      _trees = data['trees'];
      _initialized = true;
    } catch (e) {
      print("Error initializing OptimizedPoseClassifier: $e");
    }
  }

  String predictLabel(List<double> features) {
    if (!_initialized || features.length < 33 * 4) return 'unknown';

    final List<int> votes = List.filled(_labels.length, 0);

    for (var tree in _trees) {
      final int prediction = _traverseTree(tree, features);
      if (prediction >= 0 && prediction < votes.length) {
        votes[prediction]++;
      }
    }

    int maxVotes = -1;
    int bestClass = -1;
    for (int i = 0; i < votes.length; i++) {
      if (votes[i] > maxVotes) {
        maxVotes = votes[i];
        bestClass = i;
      }
    }

    if (bestClass == -1) return 'unknown';
    return _labels[bestClass] ?? 'unknown';
  }

  int _traverseTree(Map<String, dynamic> node, List<double> features) {
    // Leaf node check: 'v' key exists
    if (node.containsKey('v')) {
      return node['v'] as int;
    }

    // Decision node: 'f' (feature), 't' (threshold), 'l' (left), 'r' (right)
    final int featureIndex = node['f'] as int;
    final double threshold = (node['t'] as num).toDouble();

    if (features[featureIndex] <= threshold) {
      return _traverseTree(node['l'], features);
    } else {
      return _traverseTree(node['r'], features);
    }
  }
}
