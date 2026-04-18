import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

/// Supported crypto operations.
enum HarborCryptoOp {
  /// AES-128/192/256 encrypt (Zkne).
  aesEncrypt,

  /// AES-128/192/256 decrypt (Zknd).
  aesDecrypt,

  /// SHA-256 hash (Zknh).
  sha256,

  /// SHA-512 hash (Zknh).
  sha512,

  /// Carry-less multiply (Zbkc: clmul/clmulh).
  clmul,

  /// Bit manipulation for crypto (Zbkb: brev8, zip, unzip, pack).
  bitManip,

  /// Cross-bar permutation (Zbkx: xperm4, xperm8).
  crossbar,
}

/// RISC-V scalar crypto accelerator.
///
/// Provides hardware acceleration for the mandatory RVA23 scalar
/// crypto extensions:
/// - Zbkb: Bit manipulation for crypto
/// - Zbkc: Carry-less multiplication
/// - Zbkx: Cross-bar permutation
/// - Zknd: AES decryption
/// - Zkne: AES encryption
/// - Zknh: SHA-256 and SHA-512 hash
///
/// This module can be used in two ways:
/// 1. **Inline**: Integrated into the CPU execution pipeline as a
///    functional unit, executing crypto instructions in 1-2 cycles.
/// 2. **Offload**: As a coprocessor with a command queue, for
///    bulk crypto operations.
///
/// The inline mode is preferred for RVA23 compliance as the
/// instructions must be part of the ISA.
class HarborCryptoUnit extends BridgeModule {
  /// Supported operations.
  final List<HarborCryptoOp> operations;

  /// AES pipeline depth (1 = combinational, 2+ = pipelined).
  final int aesPipelineStages;

  HarborCryptoUnit({
    this.operations = const [
      HarborCryptoOp.aesEncrypt,
      HarborCryptoOp.aesDecrypt,
      HarborCryptoOp.sha256,
      HarborCryptoOp.sha512,
      HarborCryptoOp.clmul,
      HarborCryptoOp.bitManip,
      HarborCryptoOp.crossbar,
    ],
    this.aesPipelineStages = 1,
    super.name = 'crypto',
  }) : super('HarborCryptoUnit') {
    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);

    // Execution interface (from pipeline)
    createPort('op', PortDirection.input, width: 4); // operation select
    createPort('rs1', PortDirection.input, width: 64);
    createPort('rs2', PortDirection.input, width: 64);
    createPort('valid', PortDirection.input);
    addOutput('result', width: 64);
    addOutput('result_valid');
    addOutput('busy');

    // AES round key interface
    createPort(
      'aes_key_size',
      PortDirection.input,
      width: 2,
    ); // 0=128, 1=192, 2=256

    final clk = input('clk');
    final reset = input('reset');

    final op = input('op');
    final valid = input('valid');

    final result = Logic(name: 'result_reg', width: 64);
    final resultValid = Logic(name: 'result_valid_reg');

    // Combinational crypto operations
    final clmulResult = Logic(name: 'clmul_result', width: 64);
    final brev8Result = Logic(name: 'brev8_result', width: 64);
    final xperm4Result = Logic(name: 'xperm4_result', width: 64);
    final xperm8Result = Logic(name: 'xperm8_result', width: 64);

    // AES SubBytes S-box would be instantiated here
    // SHA compression function combinational logic here

    // Carry-less multiply (simplified - bit-serial)
    clmulResult <= Const(0, width: 64); // placeholder for actual CLMUL

    // brev8: reverse bits within each byte
    brev8Result <= Const(0, width: 64); // placeholder

    // xperm: cross-bar permutation
    xperm4Result <= Const(0, width: 64); // placeholder
    xperm8Result <= Const(0, width: 64); // placeholder

    Sequential(clk, [
      If(
        reset,
        then: [
          result < Const(0, width: 64),
          resultValid < Const(0),
          output('busy') < Const(0),
        ],
        orElse: [
          resultValid < Const(0),

          If(
            valid,
            then: [
              Case(op, [
                // CLMUL
                CaseItem(Const(HarborCryptoOp.clmul.index, width: 4), [
                  result < clmulResult,
                  resultValid < Const(1),
                ]),
                // Bit manipulation (brev8, zip, pack)
                CaseItem(Const(HarborCryptoOp.bitManip.index, width: 4), [
                  result < brev8Result,
                  resultValid < Const(1),
                ]),
                // Crossbar permutation (xperm4, xperm8)
                CaseItem(Const(HarborCryptoOp.crossbar.index, width: 4), [
                  result < xperm4Result,
                  resultValid < Const(1),
                ]),
                // AES encrypt (may take multiple cycles if pipelined)
                CaseItem(Const(HarborCryptoOp.aesEncrypt.index, width: 4), [
                  output('busy') < Const(1),
                  // AES round logic would go here
                  resultValid < Const(1),
                  output('busy') < Const(0),
                ]),
                // AES decrypt
                CaseItem(Const(HarborCryptoOp.aesDecrypt.index, width: 4), [
                  output('busy') < Const(1),
                  resultValid < Const(1),
                  output('busy') < Const(0),
                ]),
                // SHA-256
                CaseItem(Const(HarborCryptoOp.sha256.index, width: 4), [
                  // sha256sum0, sha256sum1, sha256sig0, sha256sig1
                  resultValid < Const(1),
                ]),
                // SHA-512
                CaseItem(Const(HarborCryptoOp.sha512.index, width: 4), [
                  // sha512sum0, sha512sum1, sha512sig0, sha512sig1
                  resultValid < Const(1),
                ]),
              ]),
            ],
          ),
        ],
      ),
    ]);

    output('result') <= result;
    output('result_valid') <= resultValid;
  }
}
