class PensionFund {
  final String id;
  final String name;
  final String institution;
  final double returns1y;
  final double returns3y;
  final double returns5y;
  final double totalAssets;
  final int riskLevel;
  final String type;

  PensionFund({
    required this.id,
    required this.name,
    required this.institution,
    required this.returns1y,
    required this.returns3y,
    required this.returns5y,
    required this.totalAssets,
    required this.riskLevel,
    required this.type,
  });
}
