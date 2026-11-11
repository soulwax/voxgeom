import 'dart:math' as math;

/// A 3D vector used for geometric calculations.
final class GeomVec3 {
  final double x;
  final double y;
  final double z;

  const GeomVec3(this.x, this.y, this.z);

  static const GeomVec3 zero = GeomVec3(0, 0, 0);
  static const GeomVec3 one = GeomVec3(1, 1, 1);
  static const GeomVec3 forward = GeomVec3(0, 0, -1);
  static const GeomVec3 back = GeomVec3(0, 0, 1);
  static const GeomVec3 up = GeomVec3(0, 1, 0);
  static const GeomVec3 down = GeomVec3(0, -1, 0);
  static const GeomVec3 left = GeomVec3(-1, 0, 0);
  static const GeomVec3 right = GeomVec3(1, 0, 0);

  GeomVec3 operator +(GeomVec3 other) => GeomVec3(x + other.x, y + other.y, z + other.z);
  GeomVec3 operator -(GeomVec3 other) => GeomVec3(x - other.x, y - other.y, z - other.z);
  GeomVec3 operator -() => GeomVec3(-x, -y, -z);
  GeomVec3 operator *(double scalar) => GeomVec3(x * scalar, y * scalar, z * scalar);
  GeomVec3 operator /(double scalar) => GeomVec3(x / scalar, y / scalar, z / scalar);

  double dot(GeomVec3 other) => x * other.x + y * other.y + z * other.z;

  GeomVec3 cross(GeomVec3 other) => GeomVec3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  double get lengthSquared => x * x + y * y + z * z;
  double get length => math.sqrt(lengthSquared);

  GeomVec3 get normalized {
    final len = length;
    if (len < 1e-9) return GeomVec3.zero;
    return this / len;
  }

  double distanceTo(GeomVec3 other) => (this - other).length;
  double distanceToSquared(GeomVec3 other) => (this - other).lengthSquared;

  GeomVec3 min(GeomVec3 other) => GeomVec3(
        math.min(x, other.x),
        math.min(y, other.y),
        math.min(z, other.z),
      );

  GeomVec3 max(GeomVec3 other) => GeomVec3(
        math.max(x, other.x),
        math.max(y, other.y),
        math.max(z, other.z),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeomVec3 &&
          (x - other.x).abs() < 1e-9 &&
          (y - other.y).abs() < 1e-9 &&
          (z - other.z).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(x.toStringAsFixed(5), y.toStringAsFixed(5), z.toStringAsFixed(5));

  @override
  String toString() => 'GeomVec3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})';
}

/// Convenient alias for [GeomVec3].
typedef GVec3 = GeomVec3;
