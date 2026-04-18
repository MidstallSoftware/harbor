import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

enum TestStage with HarborPipelineStage { fetch, decode, execute }

class _StubModule extends Module {
  _StubModule() : super(name: 'stub');
}

class PipelineTestModule extends Module {
  PipelineTestModule() : super(name: 'pipeline_test') {
    final clk = addInput('clk', Logic());
    final reset = addInput('reset', Logic());

    const pc = HarborPayload('PC', width: 32);
    const instruction = HarborPayload('INSTRUCTION', width: 32);
    const opcode = HarborPayload('OPCODE', width: 7);

    final pipeline = PipelineBuilder<TestStage>(parent: this)
        .stage(TestStage.fetch, payloads: [pc, instruction])
        .register(clk: clk, reset: reset)
        .stage(TestStage.decode, payloads: [opcode])
        .register(clk: clk, reset: reset)
        .stage(TestStage.execute)
        .build();

    // Verify nodes are accessible by typed stage
    addOutput('fetch_valid') <= pipeline[TestStage.fetch].valid;
  }
}

void main() {
  group('HarborPipeline', () {
    group('HarborPayload', () {
      test('equality', () {
        const a = HarborPayload('PC', width: 32);
        const b = HarborPayload('PC', width: 32);
        const c = HarborPayload('PC', width: 64);

        expect(a, equals(b));
        expect(a, isNot(equals(c)));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('HarborPipelineStage', () {
      test('enum values work as stage identifiers', () {
        expect(TestStage.fetch.name, equals('fetch'));
        expect(TestStage.values, hasLength(3));
      });
    });

    group('HarborNode', () {
      test('insert and access payloads', () {
        final node = HarborNode(TestStage.fetch);
        const pc = HarborPayload('PC', width: 32);

        final signal = node.insert(pc);
        expect(signal.width, equals(32));
        expect(node.has(pc), isTrue);
        expect(node[pc], same(signal));
      });

      test('duplicate insert throws', () {
        final node = HarborNode(TestStage.fetch);
        const pc = HarborPayload('PC', width: 32);

        node.insert(pc);
        expect(() => node.insert(pc), throwsStateError);
      });

      test('access missing payload throws', () {
        final node = HarborNode(TestStage.fetch);
        expect(() => node[const HarborPayload('MISSING')], throwsStateError);
      });
    });

    group('PipelineBuilder', () {
      test('builds a valid 3-stage pipeline', () async {
        final mod = PipelineTestModule();
        await mod.build();

        // Should build without errors
        expect(mod.output('fetch_valid'), isA<Logic>());
      });

      test('validation: no stages', () {
        expect(
          () => PipelineBuilder<TestStage>(parent: _StubModule()).build(),
          throwsA(isA<HarborPipelineValidationException>()),
        );
      });

      test('validation: duplicate stages', () {
        expect(
          () => PipelineBuilder<TestStage>(parent: _StubModule())
              .stage(TestStage.fetch)
              .register(clk: Logic())
              .stage(TestStage.fetch)
              .build(),
          throwsA(isA<HarborPipelineValidationException>()),
        );
      });

      test('validation: stages without links', () {
        expect(
          () => PipelineBuilder<TestStage>(
            parent: _StubModule(),
          ).stage(TestStage.fetch).stage(TestStage.decode).build(),
          throwsA(isA<HarborPipelineValidationException>()),
        );
      });

      test('register before any stage throws', () {
        expect(
          () => PipelineBuilder<TestStage>(
            parent: _StubModule(),
          ).register(clk: Logic()),
          throwsStateError,
        );
      });
    });

    group('HarborFlowControl', () {
      test('sealed type exhaustiveness', () {
        HarborFlowControl ctrl = HarborHaltWhen(Logic());
        final result = switch (ctrl) {
          HarborHaltWhen() => 'halt',
          HarborThrowWhen() => 'throw',
          HarborTerminateWhen() => 'terminate',
        };
        expect(result, equals('halt'));
      });
    });
  });
}
