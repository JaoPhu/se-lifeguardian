import 'dart:math';

/// A standard 1D Kalman Filter for smoothing noisy signals.
/// Based on standard control theory.
class KalmanFilter {
  double _processNoise; // Q: Process noise covariance
  double _measurementNoise; // R: Measurement noise covariance
  double _estimatedError; // P: Estimation error covariance
  double _value; // X: State estimate
  double _velocity = 0; // Velocity estimate

  bool _isInitialized = false;

  KalmanFilter({
    double processNoise = 1.0, 
    double measurementNoise = 3.0, 
    double estimatedError = 1.0
  })  : _processNoise = processNoise,
        _measurementNoise = measurementNoise,
        _estimatedError = estimatedError,
        _value = 0;

  /// Updates the filter with a new measurement from the ML model
  double filter(double measurement, [double? timeDelta]) {
    if (!_isInitialized) {
      _value = measurement;
      _estimatedError = 1.0;
      _isInitialized = true;
      return _value;
    }

    // Prediction Phase
    // X_p = X_k-1 (Simple constant position model for now)
    // P_p = P_k-1 + Q
    double predictedValue = _value; 
    double predictedError = _estimatedError + _processNoise;

    // Measurement Update (Correction) Phase
    // K = P_p / (P_p + R)
    double kalmanGain = predictedError / (predictedError + _measurementNoise);

    // X_k = X_p + K * (Z_k - X_p)
    _value = predictedValue + kalmanGain * (measurement - predictedValue);

    // P_k = (1 - K) * P_p
    _estimatedError = (1 - kalmanGain) * predictedError;

    return _value;
  }
}

/// A 3D Kalman Filter composing three 1D filters for X, Y, Z
class KalmanFilter3D {
  final KalmanFilter xFilter;
  final KalmanFilter yFilter;
  final KalmanFilter zFilter;
  final KalmanFilter visibilityFilter;

  KalmanFilter3D({double processNoise = 0.1, double measurementNoise = 2.0})
      : xFilter = KalmanFilter(processNoise: processNoise, measurementNoise: measurementNoise),
        yFilter = KalmanFilter(processNoise: processNoise, measurementNoise: measurementNoise),
        zFilter = KalmanFilter(processNoise: processNoise, measurementNoise: measurementNoise),
        visibilityFilter = KalmanFilter(processNoise: 0.1, measurementNoise: 0.1); // Low smoothing for visibility

  /// Smooths a 3D point + visibility
  List<double> filter(double x, double y, double z, double visibility) {
    return [
      xFilter.filter(x),
      yFilter.filter(y),
      zFilter.filter(z),
      visibilityFilter.filter(visibility)
    ];
  }
}
