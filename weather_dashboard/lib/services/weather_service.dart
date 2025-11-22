import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import '../models/coordinates.dart';

class WeatherService {
  static const String _cacheKey = 'cached_weather_data';
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(Coordinates coords) async {
    final url = '$_baseUrl?latitude=${coords.latitude}&longitude=${coords.longitude}&current_weather=true';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = WeatherData.fromJson(data, url);
        
        // Cache the successful result
        await _cacheWeatherData(weatherData);
        
        return weatherData;
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Try to return cached data if available
      final cachedData = await getCachedWeather();
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  Future<void> _cacheWeatherData(WeatherData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(data.toJson()));
  }

  Future<WeatherData?> getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      
      if (cachedString != null) {
        final cachedJson = json.decode(cachedString);
        return WeatherData.fromCache(cachedJson);
      }
    } catch (e) {
      // If cache is corrupted, return null
      return null;
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
