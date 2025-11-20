class AmountRoundingDropdownModel {
  late String value;
  late String option;

  AmountRoundingDropdownModel({required this.value, required this.option});
}

final List<AmountRoundingDropdownModel> roundingMethods = [
  AmountRoundingDropdownModel(value: 'none', option: 'None'),
  AmountRoundingDropdownModel(
      value: 'round_up', option: 'Round to whole number'),
  AmountRoundingDropdownModel(
      value: 'nearest_whole_number', option: 'Round to nearest whole number'),
  AmountRoundingDropdownModel(
      value: 'nearest_0.05', option: 'Round to nearest decimal (0.05)'),
  AmountRoundingDropdownModel(
      value: 'nearest_0.1', option: 'Round to nearest decimal (0.1)'),
  AmountRoundingDropdownModel(
      value: 'nearest_0.5', option: 'Round to nearest decimal (0.5)'),
];

double _roundHalfUp(num value) {
  final doubleValue = value.toDouble();

  if (doubleValue.isNegative) {
    final ceilValue = doubleValue.ceil();
    final fraction = doubleValue - ceilValue;
    final adjusted =
        fraction.abs() >= 0.5 ? (ceilValue - 1) : ceilValue;
    return adjusted.toDouble();
  }

  final floorValue = doubleValue.floor();
  final fraction = doubleValue - floorValue;
  final adjusted = fraction >= 0.5 ? (floorValue + 1) : floorValue;
  return adjusted.toDouble();
}

num roundNumber({required num value, required String roundingType}) {
  switch (roundingType) {
    case "none":
      return value;

    case "round_up":
      return value.ceilToDouble();

    case "nearest_whole_number":
      return _roundHalfUp(value);

    case "nearest_0.05":
      return (value / 0.05).round() * 0.05;

    case "nearest_0.1":
      return (value / 0.1).round() * 0.1;

    case "nearest_0.5":
      return (value / 0.5).round() * 0.5;

    default:
      return value;
  }
}
