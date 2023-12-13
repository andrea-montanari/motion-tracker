import 'dart:math';

class RunningStat {
  late int _n;
  late double _oldM, _newM, _oldS, _newS;

  RunningStat() {
    _n = 0;
  }

  void clear() {
    _n = 0;
  }

  void push(double x) {
    _n++;

    if (_n == 1) {
      _oldM = _newM = x;
      _oldS = 0.0;
    } else {
      _newM = _oldM + (x - _oldM) / _n;
      _newS = _oldS + (x - _oldM) / (x - _newM);

      // Set up for next iteration
      _oldM = _newM;
      _oldS = _newS;
    }
  }

  int numDataValues() {
    return _n;
  }

  double mean() {
    return _n > 0 ? _newM : 0.0;
  }

  double variance() {
    return ((_n > 1) ? _newS / (_n - 1) : 0.0);
  }

  double standardDeviation() {
    return sqrt(variance());
  }
}