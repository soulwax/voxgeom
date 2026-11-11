# voxgeom

Fast, allocation-conscious 3D geometric testing, raycasting, frustum culling, and spatial queries for Dart.

Built specifically for high-performance pure Dart game engines and graphics pipelines.

## Features

- **Geometric Primitives**: `GeomVec3`, `Plane3`, `Aabb3`, `Sphere3`, `Ray3`, and `Frustum3`.
- **Fast Raycasting**:
  - Kay-Kajiya slab method for Ray-AABB intersection.
  - Analytic Ray-Sphere intersection with near and far hits.
  - Möller-Trumbore Ray-Triangle intersection with barycentric coordinates `u, v, w`.
  - Ray-Plane intersection.
- **Frustum Culling**:
  - Gribb-Hartmann 6-plane extraction directly from a 4x4 View-Projection matrix.
  - Sphere-frustum and AABB-frustum intersection testing with p-vertex / n-vertex acceleration (`inside`, `intersecting`, `outside`).
- **Dynamic AABB Tree**:
  - High-performance bounding volume hierarchy (BVH) with Surface Area Heuristic (SAH).
  - Fast range queries and accelerated raycast traversal.
- **Zero Dependencies**: Pure Dart 3, fully host-decoupled.

## Quick Start

```dart
import 'package:voxgeom/voxgeom.dart';

void main() {
  // Ray-AABB Slab intersection
  final ray = Ray3(GeomVec3(0, 0, -5), GeomVec3(0, 0, 1));
  final aabb = Aabb3(GeomVec3(-1, -1, -1), GeomVec3(1, 1, 1));
  final hitDist = ray.intersectAabb(aabb);
  print('AABB hit at distance: $hitDist'); // 4.0

  // Ray-Triangle (Möller-Trumbore)
  final hit = ray.intersectTriangle(
    GeomVec3(-1, -1, 0),
    GeomVec3(1, -1, 0),
    GeomVec3(0, 1, 0),
  );
  if (hit != null) {
    print('Triangle hit at ${hit.point}, uv=(${hit.u}, ${hit.v})');
  }

  // Dynamic AABB Tree
  final tree = AabbTree<String>();
  tree.insert('Enemy', Aabb3(GeomVec3(10, 0, 0), GeomVec3(12, 2, 2)));
  final rayHits = tree.raycast(Ray3(GeomVec3(0, 1, 1), GeomVec3(1, 0, 0)));
  print('Ray hit: ${rayHits.first.data}');
}
```

## License

MIT
