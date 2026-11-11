import 'aabb3.dart';
import 'ray3.dart';

/// Result from raycasting against an [AabbTree].
final class TreeRayHit<T> {
  final T data;
  final double distance;
  final int nodeId;

  const TreeRayHit({
    required this.data,
    required this.distance,
    required this.nodeId,
  });
}

final class _TreeNode<T> {
  Aabb3 aabb;
  T? userData;
  int parent;
  int child1;
  int child2;
  int height;

  _TreeNode({
    required this.aabb,
    this.userData,
    this.parent = -1,
    this.child1 = -1,
    this.child2 = -1,
    this.height = 0,
  });

  bool get isLeaf => child1 == -1;
}

/// A dynamic bounding volume hierarchy (BVH) using an AABB tree with surface area heuristic.
class AabbTree<T> {
  final List<_TreeNode<T>?> _nodes = [];
  int _root = -1;
  int _freeList = -1;
  int _count = 0;

  /// Total number of stored user items.
  int get count => _count;

  /// Root node ID or -1 if empty.
  int get root => _root;

  /// Inserts a new user item with [aabb] into the tree. Returns the leaf node ID.
  int insert(T data, Aabb3 aabb) {
    final nodeId = _allocateNode(aabb, data);
    _insertLeaf(nodeId);
    _count++;
    return nodeId;
  }

  /// Removes the leaf identified by [nodeId].
  void remove(int nodeId) {
    if (nodeId < 0 || nodeId >= _nodes.length || _nodes[nodeId] == null) return;
    final node = _nodes[nodeId]!;
    if (!node.isLeaf) return;

    _removeLeaf(nodeId);
    _freeNode(nodeId);
    _count--;
  }

  /// Updates the bounding box of leaf [nodeId].
  void update(int nodeId, Aabb3 newAabb) {
    if (nodeId < 0 || nodeId >= _nodes.length || _nodes[nodeId] == null) return;
    final node = _nodes[nodeId]!;
    if (node.aabb.containsAabb(newAabb)) return;

    _removeLeaf(nodeId);
    node.aabb = newAabb;
    _insertLeaf(nodeId);
  }

  /// Clears all entries.
  void clear() {
    _nodes.clear();
    _root = -1;
    _freeList = -1;
    _count = 0;
  }

  /// Queries all items whose bounding box overlaps [queryAabb].
  List<T> query(Aabb3 queryAabb) {
    final results = <T>[];
    if (_root == -1) return results;

    final stack = <int>[_root];
    while (stack.isNotEmpty) {
      final nodeId = stack.removeLast();
      final node = _nodes[nodeId];
      if (node == null) continue;

      if (node.aabb.intersectsAabb(queryAabb)) {
        if (node.isLeaf) {
          if (node.userData != null) results.add(node.userData as T);
        } else {
          if (node.child1 != -1) stack.add(node.child1);
          if (node.child2 != -1) stack.add(node.child2);
        }
      }
    }
    return results;
  }

  /// Performs raycast traversal against the hierarchy, returning all hits sorted by distance.
  List<TreeRayHit<T>> raycast(Ray3 ray, {double maxDistance = double.infinity}) {
    final hits = <TreeRayHit<T>>[];
    if (_root == -1) return hits;

    final stack = <int>[_root];
    while (stack.isNotEmpty) {
      final nodeId = stack.removeLast();
      final node = _nodes[nodeId];
      if (node == null) continue;

      final dist = ray.intersectAabb(node.aabb);
      if (dist != null && dist <= maxDistance) {
        if (node.isLeaf) {
          if (node.userData != null) {
            hits.add(TreeRayHit(
              data: node.userData as T,
              distance: dist,
              nodeId: nodeId,
            ));
          }
        } else {
          if (node.child1 != -1) stack.add(node.child1);
          if (node.child2 != -1) stack.add(node.child2);
        }
      }
    }

    hits.sort((a, b) => a.distance.compareTo(b.distance));
    return hits;
  }

  // --- Internal Tree Mechanics ---

  int _allocateNode(Aabb3 aabb, T? data) {
    if (_freeList != -1) {
      final nodeId = _freeList;
      _freeList = _nodes[nodeId]!.parent;
      final node = _nodes[nodeId]!;
      node.aabb = aabb;
      node.userData = data;
      node.parent = -1;
      node.child1 = -1;
      node.child2 = -1;
      node.height = 0;
      return nodeId;
    }

    final nodeId = _nodes.length;
    _nodes.add(_TreeNode<T>(aabb: aabb, userData: data));
    return nodeId;
  }

  void _freeNode(int nodeId) {
    final node = _nodes[nodeId]!;
    node.userData = null;
    node.parent = _freeList;
    node.height = -1;
    _freeList = nodeId;
  }

  void _insertLeaf(int leaf) {
    if (_root == -1) {
      _root = leaf;
      _nodes[_root]!.parent = -1;
      return;
    }

    final leafAabb = _nodes[leaf]!.aabb;
    var index = _root;

    while (!_nodes[index]!.isLeaf) {
      final child1 = _nodes[index]!.child1;
      final child2 = _nodes[index]!.child2;

      final area = _nodes[index]!.aabb.surfaceArea;
      final combinedAabb = _nodes[index]!.aabb.encapsulateAabb(leafAabb);
      final combinedArea = combinedAabb.surfaceArea;

      final cost = 2.0 * combinedArea;
      final inheritanceCost = 2.0 * (combinedArea - area);

      // Cost of descending into child1
      double cost1;
      if (_nodes[child1]!.isLeaf) {
        final aabb = _nodes[child1]!.aabb.encapsulateAabb(leafAabb);
        cost1 = aabb.surfaceArea + inheritanceCost;
      } else {
        final aabb = _nodes[child1]!.aabb.encapsulateAabb(leafAabb);
        final oldArea = _nodes[child1]!.aabb.surfaceArea;
        final newArea = aabb.surfaceArea;
        cost1 = (newArea - oldArea) + inheritanceCost;
      }

      // Cost of descending into child2
      double cost2;
      if (_nodes[child2]!.isLeaf) {
        final aabb = _nodes[child2]!.aabb.encapsulateAabb(leafAabb);
        cost2 = aabb.surfaceArea + inheritanceCost;
      } else {
        final aabb = _nodes[child2]!.aabb.encapsulateAabb(leafAabb);
        final oldArea = _nodes[child2]!.aabb.surfaceArea;
        final newArea = aabb.surfaceArea;
        cost2 = (newArea - oldArea) + inheritanceCost;
      }

      // Descend according to the minimum cost
      if (cost < cost1 && cost < cost2) break;

      index = cost1 < cost2 ? child1 : child2;
    }

    final sibling = index;
    final oldParent = _nodes[sibling]!.parent;
    final newParent = _allocateNode(
      _nodes[sibling]!.aabb.encapsulateAabb(leafAabb),
      null,
    );
    _nodes[newParent]!.parent = oldParent;
    _nodes[newParent]!.child1 = sibling;
    _nodes[newParent]!.child2 = leaf;
    _nodes[newParent]!.height = _nodes[sibling]!.height + 1;

    _nodes[sibling]!.parent = newParent;
    _nodes[leaf]!.parent = newParent;

    if (oldParent != -1) {
      if (_nodes[oldParent]!.child1 == sibling) {
        _nodes[oldParent]!.child1 = newParent;
      } else {
        _nodes[oldParent]!.child2 = newParent;
      }
    } else {
      _root = newParent;
    }

    // Walk back up the tree refitting AABBs
    var walk = _nodes[leaf]!.parent;
    while (walk != -1) {
      final c1 = _nodes[walk]!.child1;
      final c2 = _nodes[walk]!.child2;
      _nodes[walk]!.aabb = _nodes[c1]!.aabb.encapsulateAabb(_nodes[c2]!.aabb);
      _nodes[walk]!.height = 1 + (_nodes[c1]!.height > _nodes[c2]!.height ? _nodes[c1]!.height : _nodes[c2]!.height);
      walk = _nodes[walk]!.parent;
    }
  }

  void _removeLeaf(int leaf) {
    if (leaf == _root) {
      _root = -1;
      return;
    }

    final parent = _nodes[leaf]!.parent;
    final grandParent = _nodes[parent]!.parent;
    final sibling = _nodes[parent]!.child1 == leaf ? _nodes[parent]!.child2 : _nodes[parent]!.child1;

    if (grandParent != -1) {
      if (_nodes[grandParent]!.child1 == parent) {
        _nodes[grandParent]!.child1 = sibling;
      } else {
        _nodes[grandParent]!.child2 = sibling;
      }
      _nodes[sibling]!.parent = grandParent;
      _freeNode(parent);

      var walk = grandParent;
      while (walk != -1) {
        final c1 = _nodes[walk]!.child1;
        final c2 = _nodes[walk]!.child2;
        _nodes[walk]!.aabb = _nodes[c1]!.aabb.encapsulateAabb(_nodes[c2]!.aabb);
        _nodes[walk]!.height = 1 + (_nodes[c1]!.height > _nodes[c2]!.height ? _nodes[c1]!.height : _nodes[c2]!.height);
        walk = _nodes[walk]!.parent;
      }
    } else {
      _root = sibling;
      _nodes[sibling]!.parent = -1;
      _freeNode(parent);
    }
  }
}
