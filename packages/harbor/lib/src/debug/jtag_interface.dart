import 'package:rohd/rohd.dart';

/// Standard JTAG (IEEE 1149.1) port interface.
///
/// Four-wire interface: TCK, TMS, TDI, TDO. Optionally TRST.
///
/// Provider role = debugger (drives TCK, TMS, TDI).
/// Consumer role = target (drives TDO).
class JtagInterface extends PairInterface {
  /// Test Clock.
  Logic get tck => port('TCK');

  /// Test Mode Select.
  Logic get tms => port('TMS');

  /// Test Data In (debugger → target).
  Logic get tdi => port('TDI');

  /// Test Data Out (target → debugger).
  Logic get tdo => port('TDO');

  /// Optional active-low Test Reset.
  Logic? get trst => tryPort('TRST');

  /// Whether TRST is included.
  final bool useTrst;

  JtagInterface({this.useTrst = false})
    : super(
        portsFromProvider: [
          Logic.port('TCK'),
          Logic.port('TMS'),
          Logic.port('TDI'),
          if (useTrst) Logic.port('TRST'),
        ],
        portsFromConsumer: [Logic.port('TDO')],
      );

  @override
  JtagInterface clone() => JtagInterface(useTrst: useTrst);
}
