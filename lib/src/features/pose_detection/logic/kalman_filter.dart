/// A simple 1D Kalman filter implementation.
class KalmanFilter1D {
  double _x = 0.0; // State estimate
  double _p = 1.0; // Estimation error covariance
  final double _q; // Process noise covariance
  final double _r; // Measurement noise covariance

  KalmanFilter1D({double q = 0.001, double r = 0.01})
      : _q = q,
        _r = r;

  /// Updates the filter with a new measurement [measurement]
  /// and returns the filtered value.
  double filter(double measurement) {
    // Prediction update
    _p = _p + _q;

    // Measurement update
    final k = _p / (_p + _r); // Kalman gain
    _x = _x + k * (measurement - _x);
    _p = (1 - k) * _p;

    return _x;
  }
  
  /// Resets the filter state
  void reset() {
    _x = 0.0;
    _p = 1.0;
  }
}

/// A Kalman filter for 2D points (X, Y).
class PointKalmanFilter {
  final KalmanFilter1D _filterX;
  final KalmanFilter1D _filterY;
  bool _isInitialized = false;

  PointKalmanFilter({double q = 0.001, double r = 0.01})
      : _filterX = KalmanFilter1D(q: q, r: r),
        _filterY = KalmanFilter1D(q: q, r: r);

  /// Filters a 2D point [x], [y].
  /// Returns a list [filteredX, filteredY].
  List<double> filter(double x, double y) {
    if (!_isInitialized) {
      // Initialize with the first measurement to avoid "flying in" from 0
      _filterX._x = x;
      _filterY._x = y;
      _isInitialized = true;
      return [x, y];
    }
    return [_filterX.filter(x), _filterY.filter(y)];
  }

  void reset() {
    _filterX.reset();
    _filterY.reset();
    _isInitialized = false;
  }
}
