import 'vec3.dart';

/// A 3D plane defined by the equation `normal.dot(p) + distance == 0`.
final class Plane3 {
  final GeomVec3 normal;
  final double distance;

  const Plane3(this.normal, this.distance);

  /// Creates a plane passing through [point] with the given [normal].
  factory Plane3.fromNormalAndPoint(GeomVec3 normal, GeomVec3 point) {
    final n = normal.normalized;
    return Plane3(n, -n.dot(point));
  }

  /// Creates a plane passing through three non-collinear 3D points [a], [b], [c].
  factory Plane3.fromPoints(GeomVec3 a, GeomVec3 b, GeomVec3 c) {
    final edge1 = b - a;
    final edge2 = c - a;
    final normal = edge1.cross(edge2).normalized;
    return Plane3.fromNormalAndPoint(normal, a);
  }

  /// Signed distance from this plane to [point].
  /// Positive if the point is in front of the plane (in direction of normal), negative if behind.
  double distanceToPoint(GeomVec3 point) => normal.dot(point) + distance;

  /// Returns a normalized plane where `normal.length == 1`.
  Plane3 normalized() {
    final len = normal.length;
    if (len < 1e-9) return this;
    return Plane3(normal / len, distance / len);
  }

  @override
  String toString() => 'Plane3(normal: $normal, distance: ${distance.toStringAsFixed(3)})';
}
