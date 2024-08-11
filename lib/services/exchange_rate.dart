import 'currency.dart';

class ExchangeRate {
  static final Map<Currency, double> rates = {
    Currency.USD: 1.0,
    Currency.Euro: 0.9253, // Taux de change actuel de 1 USD en Euro
    Currency.XAF: 616.028, // Taux de change actuel de 1 USD en XAF
    Currency.Rand: 15.384615, // Inverse du taux Rand vers USD (1 / 0.065)
    Currency.Naira: 416.666667, // Inverse du taux Naira vers USD (1 / 0.0024)
    Currency.Dirham: 3.703704, // Inverse du taux Dirham vers USD (1 / 0.27)
    Currency.Shilling:
        112.359551, // Inverse du taux Shilling vers USD (1 / 0.0089)
    Currency.Kwacha: 833.333333, // Inverse du taux Kwacha vers USD (1 / 0.0012)
    Currency.Birr: 43.478261, // Inverse du taux Birr vers USD (1 / 0.023)
    Currency.Dinar: 136.986301, // Inverse du taux Dinar vers USD (1 / 0.0073)
  };

  /// Convertit un montant d'une devise source à une devise cible.
  /// [amount] le montant à convertir.
  /// [rate] la devise source.
  /// [to] la devise cible.
  /// Retourne le montant converti.
  static double convertFromUSD(double amount, Currency currency) {
    double rate = rates[currency] ?? 1.0; // Utilise 1.0 pour USD comme fallback
    double convertedAmount = amount * rate; // Convertit directement depuis USD
    //print("Converting $amount from USD to $currency: $convertedAmount");
    return convertedAmount;
  }

  static double convertToUSD(double amount, Currency currency) {
    double rate = rates[currency] ?? 1.0; // Utilise 1.0 pour USD comme fallback
    double convertedAmount =
        amount / rate; // Convertit depuis la devise cible vers USD
    //print("Converting $amount from $currency to USD: $convertedAmount");
    return convertedAmount;
  }
}
