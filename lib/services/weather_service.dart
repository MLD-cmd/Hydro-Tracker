/// A tiny "island weather" model and a service that produces it.
///
/// To keep the app self-contained and offline-friendly, the temperature is
/// generated deterministically from the date (a believable tropical 26–33°C
/// that drifts day to day) rather than hitting a network API. The structure
/// mirrors a real weather call so a live source could be dropped in later.
class IslandWeather {
  const IslandWeather({required this.tempC, required this.label});

  final int tempC;
  final String label; // e.g. "Sunny", "Humid"
}

class WeatherService {
  const WeatherService();

  IslandWeather today() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    // 26..33 °C, gently varying by day.
    final tempC = 26 + (dayOfYear * 3 + now.day) % 8;
    final label = tempC >= 31
        ? 'Scorching'
        : tempC >= 29
        ? 'Hot & humid'
        : 'Balmy';
    return IslandWeather(tempC: tempC, label: label);
  }

  /// How much to add to the base goal for a given day's heat. Above 28°C we add
  /// ~50ml per degree, capped so it stays sensible.
  int goalBumpMl(IslandWeather weather) {
    if (weather.tempC <= 28) return 0;
    final bump = (weather.tempC - 28) * 50;
    return bump > 400 ? 400 : bump;
  }
}
