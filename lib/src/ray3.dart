import 'dart:math' as math;
import 'aabb3.dart';
import 'plane3.dart';
import 'sphere3.dart';
import 'vec3.dart';

/// Information regarding a ray-triangle intersection hit.
final class RayTriangleHit {
  final double distance;
  final double u;
  final double v;
  final GeomVec3 point;

  const RayTriangleHit({
    required this.distance,
    required this.u,
    required this.v,
    required this.point,
  });

  /// Barycentric coordinate w (1 - u - v).
  double get w => 1.0 - u - v;
}

/// A 3D ray starting at [origin] pointing along normalized [direction].
final class Ray3 {
  final GeomVec3 origin;
  final GeomVec3 direction;

  Ray3(this.origin, GeomVec3 direction) : direction = direction.normalized;

  /// Evaluates point along ray at distance [t].
  GeomVec3 pointAt(double t) => origin + direction * t;

  /// Tests ray against [plane]. Returns hit distance along ray, or `null` if parallel/facing away.
  double? intersectPlane(Plane3 plane) {
    final denom = plane.normal.dot(direction);
    if (denom.abs() < 1e-8) return null;

    final t = -(plane.normal.dot(origin) + plane.distance) / denom;
    return t >= 0.0 ? t : null;
  }

  /// Tests ray against [sphere]. Returns distance to closest intersection point, or `null` if no hit.
  double? intersectSphere(Sphere3 sphere) {
    final m = origin - sphere.center;
    final b = m.dot(direction);
    final c = m.dot(m) - sphere.radius * sphere.radius;

    // Ray origin outside sphere and pointing away
    if (c > 0.0 && b > 0.0) return null;

    final discr = b * b - c;
    if (discr < 0.0) return null;

    final sqrtDiscr = math.sqrt(discr);
    var t = -b - sqrtDiscr;

    if (t < 0.0) {
      t = -b + sqrtDiscr;
    }

    return t >= 0.0 ? t : null;
  }

  /// Tests ray against [aabb] using the Kay-Kajiya slab method.
  /// Returns distance to closest intersection point, or `null` if no hit.
  double? intersectAabb(Aabb3 aabb) {
    var tMin = -double.infinity;
    var tMax = double.infinity;

    // X axis
    if (direction.x.abs() > 1e-9) {
      final invD = 1.0 / direction.x;
      var t0 = (aabb.min.x - origin.x) * invD;
      var t1 = (aabb.max.x - origin.x) * invD;
      if (invD < 0.0) {
        final tmp = t0;
        t0 = t1;
        t1 = tmp;
      }
      tMin = math.max(tMin, t0);
      tMax = math.min(tMax, t1);
      if (tMax < tMin) return null;
    } else if (origin.x < aabb.min.x || origin.x > aabb.max.x) {
      return null;
    }

    // Y axis
    if (direction.y.abs() > 1e-9) {
      final invD = 1.0 / direction.y;
      var t0 = (aabb.min.y - origin.y) * invD;
      var t1 = (aabb.max.y - origin.y) * invD;
      if (invD < 0.0) {
        final tmp = t0;
        t0 = t1;
        t1 = tmp;
      }
      tMin = math.max(tMin, t0);
      tMax = math.min(tMax, t1);
      if (tMax < tMin) return null;
    } else if (origin.y < aabb.min.y || origin.y > aabb.max.y) {
      return null;
    }

    // Z axis
    if (direction.z.abs() > 1e-9) {
      final invD = 1.0 / direction.z;
      var t0 = (aabb.min.z - origin.z) * invD;
      var t1 = (aabb.max.z - origin.z) * invD;
      if (invD < 0.0) {
        final tmp = t0;
        t0 = t1;
        t1 = tmp;
      }
      tMin = math.max(tMin, t0);
      tMax = math.min(tMax, t1);
      if (tMax < tMin) return null;
    } else if (origin.z < aabb.min.z || origin.z > aabb.max.z) {
      return null;
    }

    final tHit = tMin >= 0.0 ? tMin : tMax;
    return tHit >= 0.0 ? tHit : null;
  }

  /// Tests ray against triangle defined by [v0], [v1], [v2] via the Möller-Trumbore algorithm.
  RayTriangleHit? intersectTriangle(
    GeomVec3 v0,
    GeomVec3 v1,
    GeomVec3 v2, {
    bool doubleSided = false,
  }) {
    final edge1 = v1 - v0;
    final edge2 = v2 - v0;
    final h = direction.cross(edge2);
    final a = edge1.dot(h);

    if (!doubleSided) {
      if (a < 1e-8) return null;
    } else {
      if (a.abs() < 1e-8) return null;
    }

    final f = 1.0 / a;
    final s = origin - v0;
    final u = f * s.dot(h);
    if (u < 0.0 || u > 1.0) return null;

    final q = s.cross(edge1);
    final v = f * direction.dot(q);
    if (v < 0.0 || u + v > 1.0) return null;

    final t = f * edge2.dot(q);
    if (t < 1e-8) return null;

    return RayTriangleHit(
      distance: t,
      u: u,
      v: v,
      point: pointAt(t),
    );
  }

  @override
  String toString() => 'Ray3(origin: $origin, direction: $direction)';
}
