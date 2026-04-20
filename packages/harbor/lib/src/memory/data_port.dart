import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart';

/// A [DataPortInterface] with ready/valid handshake signals.
///
/// Extends rohd_hcl's [DataPortInterface] with [ready] and [valid]
/// signals for proper request/response handshaking. This enables
/// correct behavior with latency-based memory models where data
/// may not be available on the same cycle as the request.
///
/// - [ready]: target asserts when data is available (read) or
///   write has completed (write).
/// - [valid]: target asserts when the transaction succeeded
///   (address was in range, no error).
class HarborDataPortInterface extends DataPortInterface {
  Logic get ready => port('ready');

  Logic get valid => port('valid');

  HarborDataPortInterface(super.dataWidth, super.addrWidth) {
    setPorts([Logic.port('ready'), Logic.port('valid')], [DataPortGroup.data]);
  }

  @override
  HarborDataPortInterface clone() =>
      HarborDataPortInterface(dataWidth, addrWidth);
}
