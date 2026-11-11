import 'aabb3.dart';
import 'plane3.dart';
import 'sphere3.dart';
import 'vec3.dart';

/// Intersection relationship between a bounding volume and a viewing frustum.
enum FrustumIntersection {
  outside,
  intersecting,
  inside,
}

/// A 6-plane viewing frustum used for camera visibility tests and spatial culling.
final class Frustum3 {
  final Plane3 left;
  final Plane3 right;
  final Plane3 bottom;
  final Plane3 top;
  final Plane3 near;
  final Plane3 far;

  const Frustum3({
    required this.left,
    required this.right,
    required this.bottom,
    required this.top,
    required this.near,
    required this.far,
  });

  /// Extracts the 6 frustum planes from a 4x4 View-Projection matrix (16 doubles).
  ///
  /// Assumes standard column-major order (like OpenGL, WebGL, and package:vector_math).
  /// If [isZeroToOneDepth] is true (Vulkan/Direct3D/Metal), the near plane is extracted with depth range [0, 1].
  factory Frustum3.fromMatrix(List<double> m, {bool isZeroToOneDepth = false}) {
    // Column-major indices:
    // m0  m4  m8   m12
    // m1  m5  m9   m13
    // m2  m6  m10  m14
    // m3  m7  m11  m15
    final m0 = m[0], m1 = m[1], m2 = m[2], m3 = m[3];
    final m4 = m[4], m5 = m[5], m6 = m[6], m7 = m[7];
    final m8 = m[8], m9 = m[9], m10 = m[10], m11 = m[11];
    final m12 = m[12], m13 = m[13], m14 = m[14], m15 = m[15];

    // Left: row3 + row0
    final left = Plane3(
      GeomVec3(m3 + m0, m7 + m4, m11 + m8),
      m15 + m12,
    ).normalized();

    // Right: row3 - row0
    final right = Plane3(
      GeomVec3(m3 - m0, m7 - m4, m11 - m8),
      m15 - m12,
    ).normalized();

    // Bottom: row3 + row1
    final bottom = Plane3(
      GeomVec3(m3 + m1, m7 + m5, m11 + m9),
      m15 + m13,
    ).normalized();

    // Top: row3 - row1
    final top = Plane3(
      GeomVec3(m3 - m1, m7 - m5, m11 - m9),
      m15 - m13,
    ).normalized();

    // Near:
    // For OpenGL [-1, 1]: row3 + row2
    // For Vulkan/Metal [0, 1]: row2
    final nearPlaneRaw = isZeroToOneDepth
        ? Plane3(GeomVec3(m2, m6, m10), m14)
        : Plane3(GeomVec3(m3 + m2, m7 + m6, m11 + m10), m15 + m14);
    final near = nearPlaneRaw.normalized();

    // Far: row3 - row2
    final far = Plane3(
      GeomVec3(m3 - m2, m7 - m6, m11 - m10),
      m15 - m14,
    ).normalized();

    return Frustum3(
      left: left,
      right: right,
      bottom: bottom,
      top: top,
      near: near,
      far: far,
    );
  }

  /// List of all 6 planes [left, right, bottom, top, near, far].
  List<Plane3> get planes => [left, right, bottom, top, near, far];

  /// Tests if a point lies inside the frustum.
  bool containsPoint(GeomVec3 point) {
    for (final plane in planes) {
      if (plane.distanceToPoint(point) < 0.0) return false;
    }
    return true;
  }

  /// Tests a [Sphere3] against the frustum.
  FrustumIntersection intersectsSphere(Sphere3 sphere) {
    var result = FrustumIntersection.inside;
    for (final plane in planes) {
      final dist = plane.distanceToPoint(sphere.center);
      if (dist < -sphere.radius) {
        return FrustumIntersection.outside;
      }
      if (dist < sphere.radius) {
        result = FrustumIntersection.intersecting;
      }
    }
    return result;
  }

  /// Tests an [Aabb3] against the frustum using p-vertex/n-vertex culling.
  FrustumIntersection intersectsAabb(Aabb3 aabb) {
    var result = FrustumIntersection.inside;

    for (final plane in planes) {
      final nx = plane.normal.x;
      final ny = plane.normal.y;
      final nz = plane.normal.z;

      // Positive vertex: point in direction of plane normal
      final px = nx >= 0 ? aabb.max.x : aabb.min.x;
      final py = ny >= 0 ? aabb.max.y : aabb.min.y;
      final pz = nz >= 0 ? aabb.max.z : aabb.min.z;

      if (plane.distanceToPoint(GeomVec3(px, py, pz)) < 0.0) {
        return FrustumIntersection.outside;
      }

      // Negative vertex: point in opposite direction
      final negX = nx >= 0 ? aabb.min.x : aabb.max.x;
      final negY = ny >= 0 ? aabb.min.y : aabb.max.y;
      final negZ = nz >= 0 ? aabb.min.z : aabb.max.z;

      if (plane.distanceToPoint(GeomVec3(negX, negY, negZ)) < 0.0) {
        result = FrustumIntersection.intersecting;
      }
    }

    return result;
  }
}
