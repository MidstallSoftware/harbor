import 'package:rohd/rohd.dart';

import 'link.dart';
import 'node.dart';
import 'payload.dart';
import 'stage.dart';

/// Validation error found during pipeline build.
class HarborPipelineValidationError {
  final String message;
  const HarborPipelineValidationError(this.message);

  @override
  String toString() => message;
}

/// Thrown when pipeline validation fails.
class HarborPipelineValidationException implements Exception {
  final List<HarborPipelineValidationError> errors;

  const HarborPipelineValidationException(this.errors);

  @override
  String toString() {
    final buf = StringBuffer('HarborPipelineValidationException:');
    for (final error in errors) {
      buf.write('\n  - $error');
    }
    return buf.toString();
  }
}

/// A built pipeline containing nodes, links, and validation results.
class HarborPipeline<S extends HarborPipelineStage> {
  /// All nodes in this pipeline, in order.
  final List<HarborNode<S>> nodes;

  /// All links connecting the nodes.
  final List<HarborLink<S>> links;

  const HarborPipeline._({required this.nodes, required this.links});

  /// Accesses the node for the given [stage].
  HarborNode<S> operator [](S stage) => nodes.firstWhere(
    (n) => n.stage == stage,
    orElse: () => throw StateError('No node for stage $stage'),
  );
}

/// Composable, type-safe pipeline builder.
///
/// Constructs a pipeline by chaining stage and link declarations,
/// then validates and connects everything on [build].
///
/// ```dart
/// enum MyStage with HarborPipelineStage { fetch, decode, execute }
///
/// final pipeline = PipelineBuilder<MyStage>(parent: module)
///   .stage(MyStage.fetch, payloads: [pc, instruction])
///   .register(clk: clk, reset: reset)
///   .stage(MyStage.decode, payloads: [opcode, rs1, rs2])
///   .ctrl(controls: [HarborHaltWhen(hazard)])
///   .stage(MyStage.execute, payloads: [aluResult])
///   .build();
/// ```
class PipelineBuilder<S extends HarborPipelineStage> {
  final Module _parent;
  final List<HarborNode<S>> _nodes = [];
  final List<HarborLink<S>> _links = [];

  // Pending link to apply when the next stage is added.
  _PendingLink? _pendingLink;

  PipelineBuilder({required Module parent}) : _parent = parent;

  /// Adds a stage to the pipeline with the given [payloads].
  ///
  /// If a [register] or [ctrl] call preceded this, a link is created
  /// connecting the previous stage to this one.
  PipelineBuilder<S> stage(S stage, {List<HarborPayload> payloads = const []}) {
    final node = HarborNode<S>(stage);
    for (final p in payloads) {
      node.insert(p);
    }
    _nodes.add(node);

    // Resolve any pending link now that we have the downstream node
    if (_pendingLink != null && _nodes.length >= 2) {
      final up = _nodes[_nodes.length - 2];
      switch (_pendingLink!) {
        case _PendingRegister(:final clk, :final reset):
          _links.add(
            HarborStageLink(up: up, down: node, clk: clk, reset: reset),
          );
        case _PendingCtrl(:final controls):
          _links.add(HarborCtrlLink(up: up, down: node, controls: controls));
      }
      _pendingLink = null;
    }
    return this;
  }

  /// Specifies that the next [stage] should be connected to the
  /// previous stage via pipeline registers (flip-flops).
  ///
  /// Must be called between two [stage] calls.
  PipelineBuilder<S> register({required Logic clk, Logic? reset}) {
    if (_nodes.isEmpty) {
      throw StateError('Cannot call register() before adding a stage.');
    }
    _pendingLink = _PendingRegister(clk: clk, reset: reset);
    return this;
  }

  /// Specifies that the next [stage] should be connected to the
  /// previous stage via a combinational control link.
  PipelineBuilder<S> ctrl({List<HarborFlowControl> controls = const []}) {
    if (_nodes.isEmpty) {
      throw StateError('Cannot call ctrl() before adding a stage.');
    }
    _pendingLink = _PendingCtrl(controls: controls);
    return this;
  }

  /// Validates and builds the pipeline, connecting all links.
  ///
  /// Throws [HarborPipelineValidationException] if validation fails.
  HarborPipeline<S> build() {
    _validate();

    for (final link in _links) {
      link.connect(_parent);
    }

    return HarborPipeline._(
      nodes: List.unmodifiable(_nodes),
      links: List.unmodifiable(_links),
    );
  }

  /// Validates the pipeline structure.
  void _validate() {
    final errors = <HarborPipelineValidationError>[];

    if (_nodes.isEmpty) {
      errors.add(
        const HarborPipelineValidationError('HarborPipeline has no stages.'),
      );
    }

    if (_nodes.length >= 2 && _links.isEmpty) {
      errors.add(
        const HarborPipelineValidationError(
          'HarborPipeline has multiple stages but no links connecting them.',
        ),
      );
    }

    // Check for duplicate stages
    final stages = <S>{};
    for (final node in _nodes) {
      if (!stages.add(node.stage)) {
        errors.add(
          HarborPipelineValidationError('Duplicate stage: ${node.stage.name}'),
        );
      }
    }

    // Check all nodes are connected
    final connectedNodes = <HarborNode<S>>{};
    for (final link in _links) {
      connectedNodes.add(link.up);
      connectedNodes.add(link.down);
    }
    if (_nodes.length > 1) {
      for (final node in _nodes) {
        if (!connectedNodes.contains(node)) {
          errors.add(
            HarborPipelineValidationError(
              'Stage "${node.stage.name}" is not connected to any link.',
            ),
          );
        }
      }
    }

    if (errors.isNotEmpty) {
      throw HarborPipelineValidationException(errors);
    }
  }
}

// Internal pending link types for the builder chain.
sealed class _PendingLink {}

class _PendingRegister extends _PendingLink {
  final Logic clk;
  final Logic? reset;
  _PendingRegister({required this.clk, this.reset});
}

class _PendingCtrl extends _PendingLink {
  final List<HarborFlowControl> controls;
  _PendingCtrl({this.controls = const []});
}
