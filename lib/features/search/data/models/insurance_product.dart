class InsuranceProduct {
  final String name;
  final String company;
  final String type; // 'savings' or 'term'
  final int minAge;
  final int maxAge;
  final int minTerm;
  final int maxTerm;
  final double? expectedReturn; // For savings type only
  final List<String> features;

  InsuranceProduct({
    required this.name,
    required this.company,
    required this.type,
    required this.minAge,
    required this.maxAge,
    required this.minTerm,
    required this.maxTerm,
    this.expectedReturn,
    required this.features,
  });
}
