import 'package:rohd/rohd.dart';

import '../../../harbor.dart';

/// TileLink operation opcodes for Channel A (master → slave).
enum TileLinkAOpcode {
  putFullData(0),
  putPartialData(1),
  get(4),
  acquireBlock(6),
  acquirePerm(7);

  final int value;
  const TileLinkAOpcode(this.value);
}

/// TileLink operation opcodes for Channel D (slave → master).
enum TileLinkDOpcode {
  accessAck(0),
  accessAckData(1),
  grant(4),
  grantData(5),
  releaseAck(6);

  final int value;
  const TileLinkDOpcode(this.value);
}

/// Configuration for a TileLink bus interface.
class TileLinkConfig with HarborPrettyString {
  /// Address bus width in bits.
  final int addressWidth;

  /// Data bus width in bits. Must be a power of 2.
  final int dataWidth;

  /// Transfer size field width in bits.
  final int sizeWidth;

  /// Source ID width (identifies in-flight transactions from master).
  final int sourceWidth;

  /// Sink ID width (identifies in-flight transactions from slave).
  final int sinkWidth;

  /// Enable coherency channels (B, C, E) for TileLink-C.
  final bool withBCE;

  const TileLinkConfig({
    required this.addressWidth,
    required this.dataWidth,
    this.sizeWidth = 3,
    this.sourceWidth = 1,
    this.sinkWidth = 1,
    this.withBCE = false,
  });

  /// Byte mask width: one bit per byte lane.
  int get maskWidth => dataWidth ~/ 8;

  /// Validates parameters. Returns error messages (empty = valid).
  List<String> validate() {
    final errors = <String>[];
    if (addressWidth < 1) errors.add('addressWidth must be >= 1');
    if (dataWidth < 8) errors.add('dataWidth must be >= 8');
    if (dataWidth & (dataWidth - 1) != 0) {
      errors.add('dataWidth must be a power of 2');
    }
    if (sizeWidth < 1) errors.add('sizeWidth must be >= 1');
    if (sourceWidth < 1) errors.add('sourceWidth must be >= 1');
    return errors;
  }

  @override
  String toString() =>
      'TileLinkConfig(addr: $addressWidth, data: $dataWidth, '
      'bce: $withBCE)';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}TileLinkConfig(\n');
    buf.writeln('${c}addressWidth: $addressWidth,');
    buf.writeln('${c}dataWidth: $dataWidth,');
    buf.writeln('${c}sizeWidth: $sizeWidth,');
    buf.writeln('${c}sourceWidth: $sourceWidth,');
    buf.writeln('${c}sinkWidth: $sinkWidth,');
    if (withBCE) buf.writeln('${c}withBCE: true,');
    buf.write('$p)');
    return buf.toString();
  }
}

/// A TileLink bus interface using [PairInterface].
///
/// Provider role = master (drives Channel A + D_READY).
/// Consumer role = slave (drives Channel D + A_READY).
///
/// Channels B, C, E are included when [TileLinkConfig.withBCE] is true.
///
/// Works with [BridgeModule.addInterface] and [connectInterfaces].
class TileLinkInterface extends PairInterface {
  /// The configuration for this interface.
  final TileLinkConfig config;

  // -- Channel A (master → slave) --

  Logic get aValid => port('A_VALID');
  Logic get aReady => port('A_READY');
  Logic get aOpcode => port('A_OPCODE');
  Logic get aParam => port('A_PARAM');
  Logic get aSize => port('A_SIZE');
  Logic get aSource => port('A_SOURCE');
  Logic get aAddress => port('A_ADDRESS');
  Logic get aMask => port('A_MASK');
  Logic get aData => port('A_DATA');
  Logic get aCorrupt => port('A_CORRUPT');

  // -- Channel D (slave → master) --

  Logic get dValid => port('D_VALID');
  Logic get dReady => port('D_READY');
  Logic get dOpcode => port('D_OPCODE');
  Logic get dParam => port('D_PARAM');
  Logic get dSize => port('D_SIZE');
  Logic get dSource => port('D_SOURCE');
  Logic get dSink => port('D_SINK');
  Logic get dData => port('D_DATA');
  Logic get dCorrupt => port('D_CORRUPT');
  Logic get dDenied => port('D_DENIED');

  // -- Channel B (slave → master, coherency) --

  Logic? get bValid => tryPort('B_VALID');
  Logic? get bReady => tryPort('B_READY');
  Logic? get bOpcode => tryPort('B_OPCODE');
  Logic? get bParam => tryPort('B_PARAM');
  Logic? get bSize => tryPort('B_SIZE');
  Logic? get bSource => tryPort('B_SOURCE');
  Logic? get bAddress => tryPort('B_ADDRESS');
  Logic? get bMask => tryPort('B_MASK');
  Logic? get bData => tryPort('B_DATA');
  Logic? get bCorrupt => tryPort('B_CORRUPT');

  // -- Channel C (master → slave, coherency) --

  Logic? get cValid => tryPort('C_VALID');
  Logic? get cReady => tryPort('C_READY');
  Logic? get cOpcode => tryPort('C_OPCODE');
  Logic? get cParam => tryPort('C_PARAM');
  Logic? get cSize => tryPort('C_SIZE');
  Logic? get cSource => tryPort('C_SOURCE');
  Logic? get cAddress => tryPort('C_ADDRESS');
  Logic? get cData => tryPort('C_DATA');
  Logic? get cCorrupt => tryPort('C_CORRUPT');

  // -- Channel E (master → slave, coherency) --

  Logic? get eValid => tryPort('E_VALID');
  Logic? get eReady => tryPort('E_READY');
  Logic? get eSink => tryPort('E_SINK');

  /// Creates a TileLink interface with the given [config].
  ///
  /// Throws [ArgumentError] if config validation fails.
  TileLinkInterface(this.config)
    : super(
        portsFromProvider: [
          // Channel A: master → slave (request)
          Logic.port('A_VALID'),
          Logic.port('A_OPCODE', 3),
          Logic.port('A_PARAM', 3),
          Logic.port('A_SIZE', config.sizeWidth),
          Logic.port('A_SOURCE', config.sourceWidth),
          Logic.port('A_ADDRESS', config.addressWidth),
          Logic.port('A_MASK', config.maskWidth),
          Logic.port('A_DATA', config.dataWidth),
          Logic.port('A_CORRUPT'),
          // D_READY: master acknowledges slave response
          Logic.port('D_READY'),
          // Coherency: Channel C (master → slave release)
          if (config.withBCE) ...[
            Logic.port('C_VALID'),
            Logic.port('C_OPCODE', 3),
            Logic.port('C_PARAM', 3),
            Logic.port('C_SIZE', config.sizeWidth),
            Logic.port('C_SOURCE', config.sourceWidth),
            Logic.port('C_ADDRESS', config.addressWidth),
            Logic.port('C_DATA', config.dataWidth),
            Logic.port('C_CORRUPT'),
            // B_READY: master acknowledges probe
            Logic.port('B_READY'),
            // Channel E (master → slave grant ack)
            Logic.port('E_VALID'),
            Logic.port('E_SINK', config.sinkWidth),
          ],
        ],
        portsFromConsumer: [
          // Channel D: slave → master (response)
          Logic.port('D_VALID'),
          Logic.port('D_OPCODE', 3),
          Logic.port('D_PARAM', 2),
          Logic.port('D_SIZE', config.sizeWidth),
          Logic.port('D_SOURCE', config.sourceWidth),
          Logic.port('D_SINK', config.sinkWidth),
          Logic.port('D_DATA', config.dataWidth),
          Logic.port('D_CORRUPT'),
          Logic.port('D_DENIED'),
          // A_READY: slave accepts request
          Logic.port('A_READY'),
          // Coherency: Channel B (slave → master probe)
          if (config.withBCE) ...[
            Logic.port('B_VALID'),
            Logic.port('B_OPCODE', 3),
            Logic.port('B_PARAM', 3),
            Logic.port('B_SIZE', config.sizeWidth),
            Logic.port('B_SOURCE', config.sourceWidth),
            Logic.port('B_ADDRESS', config.addressWidth),
            Logic.port('B_MASK', config.maskWidth),
            Logic.port('B_DATA', config.dataWidth),
            Logic.port('B_CORRUPT'),
            // C_READY: slave accepts release
            Logic.port('C_READY'),
            // E_READY: slave accepts grant ack
            Logic.port('E_READY'),
          ],
        ],
      ) {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid TileLinkConfig: ${errors.join("; ")}');
    }
  }

  @override
  TileLinkInterface clone() => TileLinkInterface(config);
}
