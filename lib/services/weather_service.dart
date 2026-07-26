import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final double tempC;
  final int precipProbability; // 0-100
  final double windKph;
  final int weatherCode; // WMO code

  const WeatherSnapshot({
    required this.tempC,
    required this.precipProbability,
    required this.windKph,
    required this.weatherCode,
  });

  /// Simplified WMO weather-code -> emoji/label mapping.
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode == 45 || weatherCode == 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '❄️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌦️';
    if (weatherCode >= 95) return '⛈️';
    return '🌤️';
  }

  String get label {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Partly cloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rainy';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snowy';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Showers';
    if (weatherCode >= 95) return 'Thunderstorms';
    return 'Mixed';
  }

  /// Whether outdoor sports at this venue carry meaningful rain risk.
  bool get isRainRisk => precipProbability >= 40 || (weatherCode >= 51 && weatherCode <= 99);
}

/// Free, no-API-key weather lookup via Open-Meteo — same "no key needed"
/// pattern as the CartoDB map tiles used elsewhere in the app. Fails soft:
/// any network/parse error returns null so the widget just hides itself
/// rather than blocking the game detail sheet.
class WeatherService {
  static Future<WeatherSnapshot?> fetch(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,precipitation_probability,weather_code,wind_speed_10m'
        '&forecast_days=1&timezone=auto',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      return WeatherSnapshot(
        tempC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
        precipProbability: (current['precipitation_probability'] as num?)?.toInt() ?? 0,
        windKph: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return null;
    }
  }
}
