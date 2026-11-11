import 'dart:math' as math;
import 'aabb3.dart';
import 'vec3.dart';

/// 3D Bounding Sphere.
final class Sphere3 {
  final GeomVec3 center;
  final double radius;

  const Sphere3(this.center, this.radius);

  /// Returns `true` if [point] is inside or on the surface of this sphere.
  bool containsPoint(GeomVec3 point) {
    return center.distanceToSquared(point) <= radius * radius;
  }

  /// Returns `true` if this sphere overlaps [other].
  bool intersectsSphere(Sphere3 other) {
    final rSum = radius + other.radius;
    return center.distanceToSquared(other.center) <= rSum * rSum;
  }

  /// Returns `true` if this sphere intersects [aabb].
  bool intersectsAabb(Aabb3 aabb) {
    // Find closest point on AABB to sphere center
    final cx = math.max(aabb.min.x, math.min(center.x, aabb.max.x));
    final cy = math.max(aabb.min.y, math.min(center.y, aabb.max.y));
    final cz = math.max(aabb.min.z, math.min(center.z, aabb.max.z));

    final closest = GeomVec3(cx, cy, cz);
    return center.distanceToSquared(closest) <= radius * radius;
  }

  /// Returns a bounding AABB enclosing this sphere.
  Aabb3 get aabb {
    final rVec = GeomVec3(radius, radius, radius);
    return Aabb3(center - rVec, center + rVec);
  }

  @override
  String toString() => 'Sphere3(center: $center, radius: ${radius.toStringAsFixed(3)})';
}
