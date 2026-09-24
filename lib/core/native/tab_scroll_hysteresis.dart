enum TabScrollDirection { idle, up, down }

class TabScrollHysteresis {
  TabScrollHysteresis({
    this.engagePixels = 24,
    this.releasePixels = 8,
  });

  final double engagePixels;
  final double releasePixels;

  double _accum = 0;
  TabScrollDirection _direction = TabScrollDirection.idle;

  TabScrollDirection get direction => _direction;

  TabScrollDirection addDelta(double dy) {
    if (dy == 0) return _direction;
    if ((_accum > 0 && dy < 0) || (_accum < 0 && dy > 0)) {
      _accum = 0;
    }
    _accum += dy;
    if (_accum >= engagePixels) {
      _direction = TabScrollDirection.down;
      _accum = 0;
    } else if (_accum <= -engagePixels) {
      _direction = TabScrollDirection.up;
      _accum = 0;
    } else if (_direction != TabScrollDirection.idle &&
        _accum.abs() >= releasePixels) {
    }
    return _direction;
  }

  void reset() {
    _accum = 0;
    _direction = TabScrollDirection.idle;
  }
}
