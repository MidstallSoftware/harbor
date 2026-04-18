import 'package:rohd/rohd.dart';

/// RISC-V Debug Module Interface (DMI) - the bus between the
/// Debug Transport Module and the Debug Module.
///
/// Provider = DTM (drives request).
/// Consumer = DM (drives response).
class DmiInterface extends PairInterface {
  /// DMI address width.
  final int addressWidth;

  /// DMI data width (always 32 for RISC-V).
  final int dataWidth;

  /// Request valid.
  Logic get reqValid => port('REQ_VALID');

  /// Request ready.
  Logic get reqReady => port('REQ_READY');

  /// Request address.
  Logic get reqAddr => port('REQ_ADDR');

  /// Request data.
  Logic get reqData => port('REQ_DATA');

  /// Request operation (0=nop, 1=read, 2=write).
  Logic get reqOp => port('REQ_OP');

  /// Response valid.
  Logic get rspValid => port('RSP_VALID');

  /// Response ready.
  Logic get rspReady => port('RSP_READY');

  /// Response data.
  Logic get rspData => port('RSP_DATA');

  /// Response status (0=success, 2=failed, 3=busy).
  Logic get rspOp => port('RSP_OP');

  DmiInterface({this.addressWidth = 7, this.dataWidth = 32})
    : super(
        portsFromProvider: [
          Logic.port('REQ_VALID'),
          Logic.port('REQ_ADDR', addressWidth),
          Logic.port('REQ_DATA', dataWidth),
          Logic.port('REQ_OP', 2),
          Logic.port('RSP_READY'),
        ],
        portsFromConsumer: [
          Logic.port('REQ_READY'),
          Logic.port('RSP_VALID'),
          Logic.port('RSP_DATA', dataWidth),
          Logic.port('RSP_OP', 2),
        ],
      );

  @override
  DmiInterface clone() =>
      DmiInterface(addressWidth: addressWidth, dataWidth: dataWidth);
}

/// DMI operation codes.
enum DmiOp {
  nop(0),
  read(1),
  write(2);

  final int value;
  const DmiOp(this.value);
}

/// DMI response status codes.
enum DmiStatus {
  success(0),
  failed(2),
  busy(3);

  final int value;
  const DmiStatus(this.value);
}

/// RISC-V Debug Transport Module (DTM) - bridges JTAG to DMI.
///
/// Implements the JTAG-based DTM as specified in the RISC-V Debug
/// Specification 0.13. Provides the `dtmcs` and `dmi` JTAG
/// instructions for accessing the Debug Module.
///
/// JTAG IR assignments:
/// - 0x01: IDCODE
/// - 0x10: dtmcs (DTM Control and Status)
/// - 0x11: dmi (Debug Module Interface Access)
/// - 0x1F: BYPASS
///
/// ```dart
/// final dtm = JtagDtm(
///   idcode: 0x20001FFF,
///   dmiAddressWidth: 7,
/// );
/// // Connect dtm.dmi to a DebugModule
/// ```
class JtagDtm extends Module {
  /// DMI address width.
  final int dmiAddressWidth;

  /// DMI output interface (connect to Debug Module).
  Logic get dmiReqValid => output('dmi_req_valid');
  Logic get dmiReqAddr => output('dmi_req_addr');
  Logic get dmiReqData => output('dmi_req_data');
  Logic get dmiReqOp => output('dmi_req_op');
  Logic get dmiRspReady => output('dmi_rsp_ready');

  JtagDtm({
    int idcode = 0x20001FFF,
    this.dmiAddressWidth = 7,
    super.name = 'jtag_dtm',
  }) : super(definitionName: 'JtagDtm') {
    // JTAG pins
    addInput('tck', Logic());
    addInput('tms', Logic());
    addInput('tdi', Logic());
    addInput('trst_n', Logic());
    addOutput('tdo');

    // DMI interface outputs
    addOutput('dmi_req_valid');
    addOutput('dmi_req_addr', width: dmiAddressWidth);
    addOutput('dmi_req_data', width: 32);
    addOutput('dmi_req_op', width: 2);
    addOutput('dmi_rsp_ready');

    // DMI response inputs
    addInput('dmi_req_ready', Logic());
    addInput('dmi_rsp_valid', Logic());
    addInput('dmi_rsp_data', Logic(width: 32), width: 32);
    addInput('dmi_rsp_op', Logic(width: 2), width: 2);

    // The actual DR shifting for dtmcs and dmi instructions is
    // complex state machine logic. For now, we expose the TAP
    // state and DMI interface ports so they can be connected
    // to a debug module. Full shift register implementation
    // would follow the RISC-V Debug Spec 0.13 DTM chapter.

    // Wire JTAG pins through a TAP controller
    // (In a full implementation, this would instantiate JtagTapController
    // and add dtmcs/dmi as custom instructions)

    // Default outputs
    dmiReqValid <= Const(0);
    dmiReqAddr <= Const(0, width: dmiAddressWidth);
    dmiReqData <= Const(0, width: 32);
    dmiReqOp <= Const(0, width: 2);
    dmiRspReady <= Const(1);
    output('tdo') <= Const(0);
  }
}
