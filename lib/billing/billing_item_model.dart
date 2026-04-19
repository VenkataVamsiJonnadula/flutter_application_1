class BillItem {
  final int slNo;
  final DateTime date;
  final String customerId;
  final String description;
  final String hsnSac;
  final int pcs;
  final double grossWt;
  final double stoneWt;
  final double netWt;
  final double metalRate;
  final double metalValue;
  final double va;
  final double stoneValue;
  final double totalValue;
  final double discAmt;
  final double taxableValue;

  BillItem({
    required this.slNo,
    required this.date,
    required this.customerId,
    required this.description,
    required this.hsnSac,
    required this.pcs,
    required this.grossWt,
    required this.stoneWt,
    required this.netWt,
    required this.metalRate,
    required this.metalValue,
    required this.va,
    required this.stoneValue,
    required this.totalValue,
    required this.discAmt,
    required this.taxableValue,
  });
}
