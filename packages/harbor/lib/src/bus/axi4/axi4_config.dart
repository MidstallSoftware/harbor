/// Convenience configuration wrapping rohd_hcl's AXI4 interface parameters.
///
/// Groups read and write interface parameters together.
class Axi4Config {
  final int idWidth;
  final int addrWidth;
  final int dataWidth;
  final int lenWidth;
  final int userWidth;
  final bool useLock;
  final bool useLast;

  const Axi4Config({
    this.idWidth = 4,
    this.addrWidth = 32,
    this.dataWidth = 64,
    this.lenWidth = 8,
    this.userWidth = 0,
    this.useLock = true,
    this.useLast = true,
  });

  int get strbWidth => dataWidth ~/ 8;

  List<String> validate() {
    final errors = <String>[];
    if (addrWidth < 1 || addrWidth > 64) {
      errors.add('addrWidth must be 1..64');
    }
    if (![8, 16, 32, 64, 128, 256, 512, 1024].contains(dataWidth)) {
      errors.add('dataWidth must be a power of 2 from 8..1024');
    }
    return errors;
  }

  @override
  String toString() =>
      'Axi4Config(addr: $addrWidth, data: $dataWidth, id: $idWidth)';
}
