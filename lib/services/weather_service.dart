import 'dart:convert';
import 'package:http/http.dart' as http;

/// A Philippine city the user can pick in Settings. Coordinates feed the live
/// weather lookup; Baguio is included as a deliberately cooler option so the
/// Smart Goal bump can be demoed switching on and off.
class WeatherCity {
  const WeatherCity({required this.name, required this.lat, required this.lon});

  final String name;
  final double lat;
  final double lon;
}

const List<WeatherCity> kPhCities = [
  WeatherCity(name: 'Manila', lat: 14.5995, lon: 120.9842),
  WeatherCity(name: 'Quezon City', lat: 14.6760, lon: 121.0437),
  WeatherCity(name: 'Cebu', lat: 10.3157, lon: 123.8854),
  WeatherCity(name: 'Davao', lat: 7.1907, lon: 125.4553),
  WeatherCity(name: 'Iloilo', lat: 10.7202, lon: 122.5621),
  WeatherCity(name: 'Baguio', lat: 16.4023, lon: 120.5960),
];

/// Resolves a saved city name, defaulting to the first city for unknown values.
WeatherCity cityByName(String name) =>
    kPhCities.firstWhere((c) => c.name == name, orElse: () => kPhCities.first);

/// Today's weather for the chosen place. [isLive] is true when it came from the
/// real API, false when it's the offline simulation — so the UI can be honest
/// about which one it's showing.
class IslandWeather {
  const IslandWeather({
    required this.tempC,
    required this.label,
    this.place = 'the island',
    this.isLive = false,
  });

  final int tempC;
  final String label; // e.g. "Scorching", "Balmy"
  final String place; // city name, or "the island" for the simulation
  final bool isLive;
}

/// A weather-appropriate, *hydration-friendly* drink tip for [tempC]. Hot days
/// point to water/coconut (cooling + replaces electrolytes); cold days to a
/// cozy tea (warm but still hydrating). Coffee is deliberately left out — it
/// hydrates the least, so recommending it would fight the app's own water nudge.
String drinkSuggestionFor(int tempC) {
  if (tempC >= 31) return 'Cool down with water or fresh coconut 🥥';
  if (tempC >= 25) return 'Keep plain water flowing 💧';
  return 'Warm up with a cozy cup of tea 🍵';
}

class WeatherService {
  const WeatherService();

  /// Fetches the live temperature for [city] from Open-Meteo (free, no API key)
  /// and maps it to an [IslandWeather]. On any failure — no internet, a slow
  /// network, an API hiccup — it falls back to the deterministic simulation so
  /// the app (and a live demo) keeps working offline.
  Future<IslandWeather> fetch(WeatherCity city) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${city.lat}&longitude=${city.lon}&current=temperature_2m',
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) {
        throw Exception('weather HTTP ${res.statusCode}');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final temp = (json['current']['temperature_2m'] as num).round();
      return IslandWeather(
        tempC: temp,
        label: _labelFor(temp),
        place: city.name,
        isLive: true,
      );
    } catch (_) {
      // Offline / API down — use the simulation but keep the chosen place name.
      final sim = simulated();
      return IslandWeather(
        tempC: sim.tempC,
        label: sim.label,
        place: city.name,
        isLive: false,
      );
    }
  }

  /// An offline, deterministic "island weather" derived from the date — a
  /// believable tropical 26–33°C that drifts day to day. Used as the instant
  /// first value before the network responds, and as the fallback when it
  /// doesn't.
  IslandWeather simulated() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final tempC = 26 + (dayOfYear * 3 + now.day) % 8; // 26..33 °C
    return IslandWeather(tempC: tempC, label: _labelFor(tempC));
  }

  String _labelFor(int tempC) {
    if (tempC >= 33) return 'Scorching';
    if (tempC >= 31) return 'Hot & humid';
    if (tempC >= 28) return 'Warm';
    if (tempC >= 24) return 'Balmy';
    return 'Cool';
  }

  /// How much to add to the base goal for a given day's heat. Above 28°C we add
  /// ~50ml per degree, capped so it stays sensible.
  int goalBumpMl(IslandWeather weather) {
    if (weather.tempC <= 28) return 0;
    final bump = (weather.tempC - 28) * 50;
    return bump > 400 ? 400 : bump;
  }
}
