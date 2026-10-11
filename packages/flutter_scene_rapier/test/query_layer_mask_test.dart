import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene/physics.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  late RapierWorld world;
  late int near;
  late int far;
  final ray = Ray.originDirection(Vector3.zero(), Vector3(0, 0, 1));

  setUp(() async {
    await RapierWorld.ensureInitialized();
    world = RapierWorld(gravity: Vector3.zero());
    int add(double z, int layer) {
      final body = world.createBody(
        target: SimplePoseTarget(translation: Vector3(0, 0, z)),
        type: BodyType.fixed,
      );
      return world
          .createColliders(
            body,
            const SphereShape(radius: 1),
            collisionLayer: layer,
            collisionMask: 0,
          )
          .single;
    }

    near = add(4, 1);
    far = add(8, 0x80000000);
    world.step(1 / 60);
  });
  tearDown(() => world.dispose());

  test('ray queries skip nearer excluded layer, including bit 31', () {
    expect(world.raycast(ray)!.colliderHandle, near);
    expect(world.raycast(ray, layerMask: 0x80000000)!.colliderHandle, far);
    expect(
      world.raycast(ray, layerMask: 0x80000000)!.distance,
      closeTo(7, .001),
    );
    expect(world.raycastAll(ray).map((h) => h.colliderHandle), [near, far]);
    expect(
      world.raycastAll(ray, layerMask: 0x80000000).map((h) => h.colliderHandle),
      [far],
    );
    expect(world.raycast(ray, layerMask: 0), isNull);
    expect(world.raycastAll(ray, layerMask: 0), isEmpty);
    expect(world.raycast(ray, layerMask: 2), isNull);
    expect(
      world.raycast(ray, layerMask: 0x80000000, includeFixed: false),
      isNull,
    );
  });

  test('overlap queries combine layer and body filters', () {
    for (final mask in [0, 1, 0x80000000, 0xffffffff]) {
      final expected = {
        if ((mask & 1) != 0) near,
        if ((mask & 0x80000000) != 0) far,
      };
      expect(
        world
            .overlapSphere(Vector3(0, 0, 6), 10, layerMask: mask)
            .map((h) => h.colliderHandle)
            .toSet(),
        expected,
      );
      expect(
        world
            .overlapBox(
              Vector3(0, 0, 6),
              Vector3.all(10),
              Quaternion.identity(),
              layerMask: mask,
            )
            .map((h) => h.colliderHandle)
            .toSet(),
        expected,
      );
    }
    expect(
      world.overlapSphere(Vector3.zero(), 20, includeFixed: false),
      isEmpty,
    );
    expect(
      world.overlapBox(
        Vector3.zero(),
        Vector3.all(20),
        Quaternion.identity(),
        includeFixed: false,
      ),
      isEmpty,
    );
  });

  for (final shape in <Shape>[
    const SphereShape(radius: .25),
    BoxShape(halfExtents: Vector3.all(.25)),
    const CapsuleShape(halfHeight: .25, radius: .25),
    const CylinderShape(halfHeight: .25, radius: .25),
  ]) {
    test(
      '${shape.runtimeType} cast sees allowed target behind excluded one',
      () {
        SimShapeCastHit? cast(int mask) => world.shapeCast(
          shape,
          Matrix4.identity(),
          Vector3(0, 0, 1),
          20,
          layerMask: mask,
        );
        expect(cast(0xffffffff)!.colliderHandle, near);
        expect(cast(0x80000000)!.colliderHandle, far);
        expect(cast(0), isNull);
      },
    );
  }

  test('live filter changes and snapshot restore preserve memberships', () {
    final snapshot = world.snapshot();
    world.setColliderFilter(near, 0x80000000, 0);
    expect(world.raycast(ray, layerMask: 0x80000000)!.colliderHandle, near);
    expect(world.restore(snapshot), isTrue);
    world.step(1 / 60);
    expect(world.raycast(ray, layerMask: 0x80000000)!.colliderHandle, far);
  });
}
