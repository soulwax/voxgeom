import 'dart:math' as math;
import 'vec3.dart';

/// 3D Axis-Aligned Bounding Box.
final class Aabb3 {
  final GeomVec3 min;
  final GeomVec3 max;

  const Aabb3(this.min, this.max);

  /// Creates an empty bounding box with infinite bounds.
  static const Aabb3 empty = Aabb3(
    GeomVec3(double.infinity, double.infinity, double.infinity),
    GeomVec3(-double.infinity, -double.infinity, -double.infinity),
  );

  /// Creates an AABB from center point and half-extents.
  factory Aabb3.fromCenterExtents(GeomVec3 center, GeomVec3 extents) {
    return Aabb3(center - extents, center + extents);
  }

  /// Creates an AABB enclosing an array of points.
  factory Aabb3.fromPoints(Iterable<GeomVec3> points) {
    if (points.isEmpty) return empty;
    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    var maxZ = -double.infinity;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.z < minZ) minZ = p.z;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
      if (p.z > maxZ) maxZ = p.z;
    }
    return Aabb3(GeomVec3(minX, minY, minZ), GeomVec3(maxX, maxY, maxZ));
  }

  GeomVec3 get center => (min + max) * 0.5;
  GeomVec3 get size => max - min;
  GeomVec3 get extents => size * 0.5;

  double get volume => math.max(0.0, size.x) * math.max(0.0, size.y) * math.max(0.0, size.z);

  double get surfaceArea {
    final s = size;
    return 2.0 * (s.x * s.y + s.y * s.z + s.z * s.x);
  }

  bool get isEmpty => min.x > max.x || min.y > max.y || min.z > max.z;

  /// Returns `true` if [point] is inside or on the boundary of this box.
  bool containsPoint(GeomVec3 point) {
    return point.x >= min.x &&
        point.x <= max.x &&
        point.y >= min.y &&
        point.y <= max.y &&
        point.z >= min.z &&
        point.z <= max.z;
  }

  /// Returns `true` if [other] is completely inside this box.
  bool containsAabb(Aabb3 other) {
    return other.min.x >= min.x &&
        other.max.x <= max.x &&
        other.min.y >= min.y &&
        other.max.y <= max.y &&
        other.min.z >= min.z &&
        other.max.z <= max.z;
  }

  /// Returns `true` if this box intersects [other].
  bool intersectsAabb(Aabb3 other) {
    return min.x <= other.max.x &&
        max.x >= other.min.x &&
        min.y <= other.max.y &&
        max.y >= other.min.y &&
        min.z <= other.max.z &&
        max.z >= other.min.z;
  }

  /// Returns a new AABB encapsulating this box and [point].
  Aabb3 encapsulatePoint(GeomVec3 point) {
    return Aabb3(
      min.min(point),
      max.max(point),
    );
  }

  /// Returns a new AABB encapsulating this box and [other].
  Aabb3 encapsulateAabb(Aabb3 other) {
    return Aabb3(
      min.min(other.min),
      max.max(other.max),
    );
  }

  /// Expands box uniformly in all directions by [amount].
  Aabb3 expanded(double amount) {
    final delta = GeomVec3(amount, amount, amount);
    return Aabb3(min - delta, max + delta);
  }

  /// Returns all 8 corner vertices.
  List<GeomVec3> get corners => [
        GeomVec3(min.x, min.y, min.z),
        GeomVec3(max.x, min.y, min.z),
        GeomVec3(min.x, max.y, min.z),
        GeomVec3(max.x, max.y, min.z),
        GeomVec3(min.x, min.y, max.z),
        GeomVec3(max.x, min.y, max.z),
        GeomVec3(min.x, max.y, max.z),
        GeomVec3(max.x, max.y, max.z),
      ];

  @override
  String toString() => 'Aabb3(min: $min, max: $max)';
}
