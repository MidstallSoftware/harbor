import 'package:rohd/rohd.dart';

/// A generic memory port interface using [PairInterface].
///
/// Provider role = initiator (drives en, addr, wdata, we).
/// Consumer role = target (drives rdata, done, valid).
///
/// Used for CPU-to-cache, cache-to-memory, and MMU page table
/// walker connections.
class HarborMemoryPortInterface extends PairInterface {
  /// Data width in bits.
  final int dataWidth;

  /// Address width in bits.
  final int addrWidth;

  /// Enable.
  Logic get en => port('en');

  /// Address.
  Logic get addr => port('addr');

  /// Write enable.
  Logic get we => port('we');

  /// Write data (initiator to target).
  Logic get wdata => port('wdata');

  /// Read data (target to initiator).
  Logic get rdata => port('rdata');

  /// Transaction complete.
  Logic get done => port('done');

  /// Response valid (address was in range).
  Logic get valid => port('valid');

  HarborMemoryPortInterface({required this.dataWidth, required this.addrWidth})
    : super(
        portsFromProvider: [
          Logic.port('en'),
          Logic.port('addr', addrWidth),
          Logic.port('we'),
          Logic.port('wdata', dataWidth),
        ],
        portsFromConsumer: [
          Logic.port('rdata', dataWidth),
          Logic.port('done'),
          Logic.port('valid'),
        ],
      );

  @override
  HarborMemoryPortInterface clone() =>
      HarborMemoryPortInterface(dataWidth: dataWidth, addrWidth: addrWidth);
}

/// Memory access type.
enum HarborMemoryAccessType {
  /// Instruction fetch.
  instruction,

  /// Data read.
  read,

  /// Data write.
  write,
}
