import 'package:rohd/rohd.dart';

import 'node.dart';
import 'stage.dart';

/// Flow control actions for a [HarborCtrlLink].
sealed class HarborFlowControl {
  final Logic condition;
  const HarborFlowControl(this.condition);
}

/// Halts the pipeline when [condition] is high. Data stays in the
/// upstream node.
class HarborHaltWhen extends HarborFlowControl {
  const HarborHaltWhen(super.condition);
}

/// Flushes (throws) data when [condition] is high. Data is discarded.
class HarborThrowWhen extends HarborFlowControl {
  const HarborThrowWhen(super.condition);
}

/// Hides the transaction from downstream when [condition] is high,
/// without removing it from the upstream node.
class HarborTerminateWhen extends HarborFlowControl {
  const HarborTerminateWhen(super.condition);
}

/// Base class for pipeline links connecting two [HarborNode]s.
sealed class HarborLink<S extends HarborPipelineStage> {
  /// The upstream node.
  final HarborNode<S> up;

  /// The downstream node.
  final HarborNode<S> down;

  const HarborLink({required this.up, required this.down});

  /// Connects the link, creating hardware between [up] and [down]
  /// within [parent].
  void connect(Module parent);
}

/// A registered stage link: inserts flip-flops between two nodes.
///
/// Propagates payloads through pipeline registers on the rising
/// edge of [clk]. Payloads present in [up] are automatically
/// registered into [down].
class HarborStageLink<S extends HarborPipelineStage> extends HarborLink<S> {
  /// Clock signal for the pipeline registers.
  final Logic clk;

  /// Optional reset signal (active high).
  final Logic? reset;

  HarborStageLink({
    required super.up,
    required super.down,
    required this.clk,
    this.reset,
  });

  @override
  void connect(Module parent) {
    // Propagate payloads: create registered copies in downstream
    for (final payload in up.payloads) {
      if (!down.has(payload)) {
        down.insert(payload);
      }
    }

    // Build registered pipeline stage
    final conditionals = <Conditional>[];

    if (reset != null) {
      // On reset: clear valid, zero all payloads
      final resetBody = <Conditional>[
        down.valid < Const(0),
        for (final payload in up.payloads)
          down[payload] < Const(0, width: payload.width),
      ];

      // Normal operation: register valid and payloads
      final normalBody = <Conditional>[
        down.valid < up.valid,
        for (final payload in up.payloads) down[payload] < up[payload],
      ];

      conditionals.add(If(reset!, then: resetBody, orElse: normalBody));
    } else {
      conditionals.addAll([
        down.valid < up.valid,
        for (final payload in up.payloads) down[payload] < up[payload],
      ]);
    }

    Sequential(clk, conditionals);

    // Back-pressure: upstream ready when downstream ready or not valid
    up.ready <= down.ready | ~down.valid;
  }
}

/// A combinational (direct) link with flow control.
///
/// Passes payloads from [up] to [down] combinationally, with optional
/// flow control via [controls].
class HarborCtrlLink<S extends HarborPipelineStage> extends HarborLink<S> {
  /// Immutable list of flow control conditions.
  final List<HarborFlowControl> controls;

  HarborCtrlLink({
    required super.up,
    required super.down,
    this.controls = const [],
  });

  @override
  void connect(Module parent) {
    // Combinational pass-through of payloads
    for (final payload in up.payloads) {
      if (!down.has(payload)) {
        down.insert(payload);
      }
      down[payload] <= up[payload];
    }

    // Compute aggregate flow control signals
    Logic validOut = up.valid;
    Logic readyBack = down.ready;

    for (final ctrl in controls) {
      switch (ctrl) {
        case HarborHaltWhen():
          readyBack = readyBack & ~ctrl.condition;
          break;
        case HarborThrowWhen():
          validOut = validOut & ~ctrl.condition;
          down.cancel <= down.cancel | ctrl.condition;
          break;
        case HarborTerminateWhen():
          validOut = validOut & ~ctrl.condition;
          break;
      }
    }

    down.valid <= validOut;
    up.ready <= readyBack;
  }
}
