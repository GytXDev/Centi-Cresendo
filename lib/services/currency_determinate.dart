import 'currency.dart';

class Range {
  final double start;
  final double end;

  Range(this.start, this.end);

  bool contains(double value) => value >= start && value <= end;
}
// Determiner la devise en fonction de la localisation 
class CurrencyService {
  static Currency determineCurrency(double latitude, double longitude) {
    final euroLatRange = Range(35.0, 72.0);
    final euroLongRange = Range(-32.0, 42.0);

    final usdLatRange = Range(24.396308, 49.384358);
    final usdLongRange = Range(-125.000000, -66.934570);

    final cfaLatRange = Range(-37.0, 15.0);
    final cfaLongRange = Range(-20.0, 56.0);

    final randLatRange = Range(-35.0, -22.0);
    final randLongRange = Range(16.0, 33.0);

    final nairaLatRange = Range(4.0, 14.0);
    final nairaLongRange = Range(3.0, 15.0);

    final dirhamLatRange = Range(21.0, 35.0);
    final dirhamLongRange = Range(-18.0, -5.0);

    final shillingLatRange = Range(-11.0, 6.0);
    final shillingLongRange = Range(33.0, 47.0);

    final kwachaLatRange = Range(-18.0, -8.0);
    final kwachaLongRange = Range(24.0, 36.0);

    final birrLatRange = Range(3.0, 15.0);
    final birrLongRange = Range(33.0, 48.0);

    final dinarLatRange = Range(20.0, 37.0);
    final dinarLongRange = Range(-13.0, 12.0);

    if (euroLatRange.contains(latitude) && euroLongRange.contains(longitude)) {
      return Currency.Euro;
    } else if (usdLatRange.contains(latitude) &&
        usdLongRange.contains(longitude)) {
      return Currency.USD;
    } else if (cfaLatRange.contains(latitude) &&
        cfaLongRange.contains(longitude)) {
      return Currency.XAF;
    } else if (randLatRange.contains(latitude) &&
        randLongRange.contains(longitude)) {
      return Currency.Rand;
    } else if (nairaLatRange.contains(latitude) &&
        nairaLongRange.contains(longitude)) {
      return Currency.Naira;
    } else if (dirhamLatRange.contains(latitude) &&
        dirhamLongRange.contains(longitude)) {
      return Currency.Dirham;
    } else if (shillingLatRange.contains(latitude) &&
        shillingLongRange.contains(longitude)) {
      return Currency.Shilling;
    } else if (kwachaLatRange.contains(latitude) &&
        kwachaLongRange.contains(longitude)) {
      return Currency.Kwacha;
    } else if (birrLatRange.contains(latitude) &&
        birrLongRange.contains(longitude)) {
      return Currency.Birr;
    } else if (dinarLatRange.contains(latitude) &&
        dinarLongRange.contains(longitude)) {
      return Currency.Dinar;
    } else {
      return Currency.USD;
    }
  }
}
