import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

// Test plugins

class ProviderPlugin extends FiberPlugin {
  @override
  String get name => 'Provider';

  final widthHandle = HarborHandle<int>();

  @override
  void init() {
    during.setup(() async {
      widthHandle.load(32);
    });
  }

  @override
  Map<String, dynamic> toJson() => {'name': name, 'width': 32};
}

class ConsumerPlugin extends FiberPlugin {
  @override
  String get name => 'Consumer';

  @override
  Set<Type> get dependencies => {ProviderPlugin};

  int? receivedWidth;

  @override
  void init() {
    during.build(() async {
      final provider = host.apply<ProviderPlugin>();
      receivedWidth = await provider.widthHandle.value;
    });
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class IndependentPlugin extends FiberPlugin {
  @override
  String get name => 'Independent';

  bool didRun = false;

  @override
  void init() {
    during.build(() async {
      didRun = true;
    });
  }

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class CyclicAPlugin extends FiberPlugin {
  @override
  String get name => 'CyclicA';

  @override
  Set<Type> get dependencies => {CyclicBPlugin};

  @override
  void init() {}

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class CyclicBPlugin extends FiberPlugin {
  @override
  String get name => 'CyclicB';

  @override
  Set<Type> get dependencies => {CyclicAPlugin};

  @override
  void init() {}

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class MissingDepPlugin extends FiberPlugin {
  @override
  String get name => 'MissingDep';

  @override
  Set<Type> get dependencies => {ProviderPlugin};

  @override
  void init() {}

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('PluginHost', () {
    test('provider/consumer across phases', () async {
      final host = PluginHost();
      final provider = ProviderPlugin();
      final consumer = ConsumerPlugin();

      host.addPlugin(provider);
      host.addPlugin(consumer);

      await host.elaborate();

      expect(consumer.receivedWidth, equals(32));
    });

    test('type-safe lookup', () {
      final host = PluginHost();
      host.addPlugin(ProviderPlugin());
      host.addPlugin(IndependentPlugin());

      expect(host.apply<ProviderPlugin>(), isA<ProviderPlugin>());
      expect(host.list<IndependentPlugin>(), hasLength(1));
      expect(host.tryApply<ConsumerPlugin>(), isNull);
    });

    test('apply throws on missing type', () {
      final host = PluginHost();
      expect(() => host.apply<ProviderPlugin>(), throwsStateError);
    });

    test('missing dependency throws', () {
      final host = PluginHost();
      host.addPlugin(MissingDepPlugin());

      expect(() => host.elaborate(), throwsA(isA<PluginDependencyException>()));
    });

    test('cyclic dependency throws', () {
      final host = PluginHost();
      host.addPlugin(CyclicAPlugin());
      host.addPlugin(CyclicBPlugin());

      expect(() => host.elaborate(), throwsA(isA<PluginDependencyException>()));
    });

    test('plugin cannot be bound twice', () {
      final plugin = ProviderPlugin();
      PluginHost().addPlugin(plugin);

      expect(() => PluginHost().addPlugin(plugin), throwsStateError);
    });

    test('multiple hosts elaborate in parallel', () async {
      final host1 = PluginHost()..addPlugin(IndependentPlugin());
      final host2 = PluginHost()..addPlugin(IndependentPlugin());

      await Future.wait([host1.elaborate(), host2.elaborate()]);

      expect((host1.apply<IndependentPlugin>()).didRun, isTrue);
      expect((host2.apply<IndependentPlugin>()).didRun, isTrue);
    });

    test('toJson serializes plugins', () {
      final host = PluginHost();
      host.addPlugin(ProviderPlugin());
      host.addPlugin(IndependentPlugin());

      final json = host.toJson();
      expect(json['plugins'], isList);
      expect((json['plugins'] as List), hasLength(2));
    });

    test('fromJson round-trip', () async {
      final registry = PluginRegistry()
        ..register('Provider', (_) => ProviderPlugin())
        ..register('Independent', (_) => IndependentPlugin());

      final original = PluginHost();
      original.addPlugin(ProviderPlugin());
      original.addPlugin(IndependentPlugin());

      final json = original.toJson();
      final restored = PluginHost.fromJson(json, registry);

      expect(restored.plugins, hasLength(2));
      expect(restored.apply<ProviderPlugin>(), isA<ProviderPlugin>());
      expect(restored.apply<IndependentPlugin>(), isA<IndependentPlugin>());

      await restored.elaborate();
      expect(restored.apply<IndependentPlugin>().didRun, isTrue);
    });
  });

  group('PluginRegistry', () {
    test('register and create', () {
      final registry = PluginRegistry()
        ..register('Provider', (_) => ProviderPlugin());

      expect(registry.has('Provider'), isTrue);
      expect(registry.has('Unknown'), isFalse);

      final plugin = registry.create({'name': 'Provider'});
      expect(plugin, isA<ProviderPlugin>());
    });

    test('duplicate registration throws', () {
      final registry = PluginRegistry()
        ..register('X', (_) => IndependentPlugin());

      expect(
        () => registry.register('X', (_) => IndependentPlugin()),
        throwsStateError,
      );
    });

    test('create with unknown name throws', () {
      final registry = PluginRegistry();
      expect(() => registry.create({'name': 'Unknown'}), throwsStateError);
    });

    test('create without name field throws', () {
      final registry = PluginRegistry();
      expect(() => registry.create({'foo': 'bar'}), throwsStateError);
    });
  });
}
