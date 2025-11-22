class WeatherData {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final DateTime lastUpdated;
  final bool isCached;
  final String requestUrl;

  WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.lastUpdated,
    this.isCached = false,
    required this.requestUrl,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String url) {
    final currentWeather = json['current_weather'];
    return WeatherData(
      temperature: currentWeather['temperature'].toDouble(),
      windSpeed: currentWeather['windspeed'].toDouble(),
      weatherCode: currentWeather['weathercode'],
      lastUpdated: DateTime.now(),
      requestUrl: url,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'windSpeed': windSpeed,
      'weatherCode': weatherCode,
      'lastUpdated': lastUpdated.toIso8601String(),
      'requestUrl': requestUrl,
    };
  }

  factory WeatherData.fromCache(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature'],
      windSpeed: json['windSpeed'],
      weatherCode: json['weatherCode'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isCached: true,
      requestUrl: json['requestUrl'],
    );
  }

  String getWeatherDescription() {
    // WMO Weather interpretation codes
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode <= 3) return 'Partly cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 82) return 'Rain showers';
    if (weatherCode <= 86) return 'Snow showers';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}
