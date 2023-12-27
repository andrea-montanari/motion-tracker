import 'dart:math';

class RunningStat {
  late int _n;
  late double _oldM, _newM, _oldS, _newS, _var, _std, _maxVar, _maxStd;

  RunningStat() {
    _n = 0;
    _maxVar = _maxStd = 0.0;
  }

  void clear() {
    _n = 0;
    _maxVar = _maxStd = 0.0;
  }

  void push(double x) {
    _n++;

    if (_n == 1) {
      _oldM = _newM = x;
      _oldS = 0.0;
    } else {
      _newM = _oldM + (x - _oldM) / _n;
      _newS = _oldS + (x - _oldM) * (x - _newM);

      // Set up for next iteration
      _oldM = _newM;
      _oldS = _newS;

      // Calculate variance and std
      _var = ((_n > 1) ? _newS / (_n - 1) : 0.0);
      _std = sqrt(_var);

      // Calculate maximum variance and std
      _maxVar = _var > _maxVar ? _var : _maxVar;
      _maxStd = _std > _maxStd ? _std : _maxStd;
    }
  }

  int numDataValues() {
    return _n;
  }

  double mean() {
    return _n > 0 ? _newM : 0.0;
  }

  double variance() {
    return _var;
  }

  double standardDeviation() {
    return _std;
  }

  double maxVariance() {
    return _maxVar;
  }

  double maxStd() {
    return _maxStd;
  }
}