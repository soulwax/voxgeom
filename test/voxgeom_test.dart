import 'package:test/test.dart';
import 'package:voxgeom/voxgeom.dart';

void main() {
  group('voxgeom GeomVec3', () {
    test('vector arithmetic, cross product, and dot product', () {
      const a = GeomVec3(1, 2, 3);
      const b = GeomVec3(4, 5, 6);

      expect(a + b, equals(const GeomVec3(5, 7, 9)));
      expect(b - a, equals(const GeomVec3(3, 3, 3)));
      expect(a * 2.0, equals(const GeomVec3(2, 4, 6)));
      expect(a.dot(b), closeTo(1 * 4 + 2 * 5 + 3 * 6, 1e-6));

      // Unit vector cross products
      expect(GeomVec3.right.cross(GeomVec3.up), equals(GeomVec3.back));
      expect(GeomVec3.up.cross(GeomVec3.right), equals(GeomVec3.forward));
    });
  });

  group('voxgeom Aabb3 & Sphere3', () {
    test('Aabb3 center, size, volume and containment', () {
      final aabb = Aabb3(const GeomVec3(-2, -2, -2), const GeomVec3(2, 2, 2));

      expect(aabb.center, equals(GeomVec3.zero));
      expect(aabb.size, equals(const GeomVec3(4, 4, 4)));
      expect(aabb.volume, closeTo(64.0, 1e-6));
      expect(aabb.surfaceArea, closeTo(96.0, 1e-6));

      expect(aabb.containsPoint(const GeomVec3(1, 1, 1)), isTrue);
      expect(aabb.containsPoint(const GeomVec3(3, 1, 1)), isFalse);
    });

    test('Sphere3 containment and intersection with AABB', () {
      const sphere = Sphere3(GeomVec3(0, 0, 0), 2.0);
      final aabb = Aabb3(const GeomVec3(1, 1, 1), const GeomVec3(3, 3, 3));

      expect(sphere.containsPoint(const GeomVec3(1, 0, 0)), isTrue);
      expect(sphere.containsPoint(const GeomVec3(3, 0, 0)), isFalse);

      expect(sphere.intersectsAabb(aabb), isTrue);

      final farAabb = Aabb3(const GeomVec3(5, 5, 5), const GeomVec3(6, 6, 6));
      expect(sphere.intersectsAabb(farAabb), isFalse);
    });
  });

  group('voxgeom Ray3 Intersections', () {
    test('Ray-AABB slab intersection', () {
      final ray = Ray3(const GeomVec3(0, 0, -5), const GeomVec3(0, 0, 1));
      final aabb = Aabb3(const GeomVec3(-1, -1, -1), const GeomVec3(1, 1, 1));

      final dist = ray.intersectAabb(aabb);
      expect(dist, isNotNull);
      expect(dist!, closeTo(4.0, 1e-6));

      final missRay = Ray3(const GeomVec3(0, 5, -5), const GeomVec3(0, 0, 1));
      expect(missRay.intersectAabb(aabb), isNull);
    });

    test('Ray-Sphere analytic intersection', () {
      final ray = Ray3(const GeomVec3(0, 0, -5), const GeomVec3(0, 0, 1));
      const sphere = Sphere3(GeomVec3.zero, 1.0);

      final dist = ray.intersectSphere(sphere);
      expect(dist, isNotNull);
      expect(dist!, closeTo(4.0, 1e-6));
    });

    test('Ray-Triangle Möller-Trumbore intersection', () {
      final ray = Ray3(const GeomVec3(0, 0, -5), const GeomVec3(0, 0, 1));
      const v0 = GeomVec3(-1, -1, 0);
      const v1 = GeomVec3(1, -1, 0);
      const v2 = GeomVec3(0, 1, 0);

      final hit = ray.intersectTriangle(v0, v1, v2, doubleSided: true);
      expect(hit, isNotNull);
      expect(hit!.distance, closeTo(5.0, 1e-6));
      expect(hit.point.x, closeTo(0.0, 1e-6));
      expect(hit.point.y, closeTo(0.0, 1e-6));
      expect(hit.point.z, closeTo(0.0, 1e-6));

      // Ray missing triangle
      final missRay = Ray3(const GeomVec3(2, 2, -5), const GeomVec3(0, 0, 1));
      expect(missRay.intersectTriangle(v0, v1, v2), isNull);
    });
  });

  group('voxgeom Frustum3', () {
    test('Frustum3 sphere and AABB tests', () {
      // Create a box frustum with bounds x in [-10, 10], y in [-10, 10], z in [-10, 10]
      const left = Plane3(GeomVec3(1, 0, 0), 10.0);
      const right = Plane3(GeomVec3(-1, 0, 0), 10.0);
      const bottom = Plane3(GeomVec3(0, 1, 0), 10.0);
      const top = Plane3(GeomVec3(0, -1, 0), 10.0);
      const near = Plane3(GeomVec3(0, 0, 1), 10.0);
      const far = Plane3(GeomVec3(0, 0, -1), 10.0);

      const frustum = Frustum3(
        left: left,
        right: right,
        bottom: bottom,
        top: top,
        near: near,
        far: far,
      );

      expect(frustum.containsPoint(GeomVec3.zero), isTrue);
      expect(frustum.containsPoint(const GeomVec3(15, 0, 0)), isFalse);

      // Sphere completely inside
      const insideSphere = Sphere3(GeomVec3.zero, 2.0);
      expect(frustum.intersectsSphere(insideSphere), equals(FrustumIntersection.inside));

      // Sphere intersecting boundary
      const boundarySphere = Sphere3(const GeomVec3(10, 0, 0), 2.0);
      expect(frustum.intersectsSphere(boundarySphere), equals(FrustumIntersection.intersecting));

      // Sphere completely outside
      const outsideSphere = Sphere3(const GeomVec3(20, 0, 0), 2.0);
      expect(frustum.intersectsSphere(outsideSphere), equals(FrustumIntersection.outside));

      // AABB inside
      final insideAabb = Aabb3(const GeomVec3(-2, -2, -2), const GeomVec3(2, 2, 2));
      expect(frustum.intersectsAabb(insideAabb), equals(FrustumIntersection.inside));

      // AABB outside
      final outsideAabb = Aabb3(const GeomVec3(12, 12, 12), const GeomVec3(15, 15, 15));
      expect(frustum.intersectsAabb(outsideAabb), equals(FrustumIntersection.outside));
    });
  });

  group('voxgeom AabbTree', () {
    test('dynamic AABB tree inserts, queries, updates, and raycasts', () {
      final tree = AabbTree<String>();

      final id1 = tree.insert('BoxA', Aabb3(const GeomVec3(0, 0, 0), const GeomVec3(2, 2, 2)));
      final id2 = tree.insert('BoxB', Aabb3(const GeomVec3(10, 0, 0), const GeomVec3(12, 2, 2)));

      expect(tree.count, 2);

      // Overlap query
      final queryResults = tree.query(Aabb3(const GeomVec3(1, 1, 1), const GeomVec3(3, 3, 3)));
      expect(queryResults, contains('BoxA'));
      expect(queryResults, isNot(contains('BoxB')));

      // Raycast query
      final ray = Ray3(const GeomVec3(11, 1, -5), const GeomVec3(0, 0, 1));
      final hits = tree.raycast(ray);
      expect(hits, hasLength(1));
      expect(hits.first.data, equals('BoxB'));
      expect(hits.first.distance, closeTo(5.0, 1e-6));

      // Update position
      tree.update(id1, Aabb3(const GeomVec3(20, 0, 0), const GeomVec3(22, 2, 2)));
      expect(tree.query(Aabb3(const GeomVec3(0, 0, 0), const GeomVec3(2, 2, 2))), isEmpty);
      expect(tree.query(Aabb3(const GeomVec3(20, 0, 0), const GeomVec3(22, 2, 2))), contains('BoxA'));

      // Remove
      tree.remove(id2);
      expect(tree.count, 1);
      expect(tree.query(Aabb3(const GeomVec3(10, 0, 0), const GeomVec3(12, 2, 2))), isEmpty);
    });
  });
}
