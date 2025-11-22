import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const WeatherDashboardApp());
}

class WeatherDashboardApp extends StatelessWidget {
  const WeatherDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const WeatherDashboard(),
    );
  }
}

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  final TextEditingController _indexController = TextEditingController(text: '224084');
  
  double? _latitude;
  double? _longitude;
  String? _requestUrl;
  String? _lastUpdated;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;
  
  // Weather data
  double? _temperature;
  double? _windSpeed;
  int? _weatherCode;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }

  // Load cached weather data
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('weather_data');
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        setState(() {
          _temperature = data['temperature']?.toDouble();
          _windSpeed = data['windSpeed']?.toDouble();
          _weatherCode = data['weatherCode'];
          _latitude = data['latitude']?.toDouble();
          _longitude = data['longitude']?.toDouble();
          _requestUrl = data['requestUrl'];
          _lastUpdated = data['lastUpdated'];
          _isCached = true;
        });
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Save weather data to cache
  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'temperature': _temperature,
        'windSpeed': _windSpeed,
        'weatherCode': _weatherCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'requestUrl': _requestUrl,
        'lastUpdated': _lastUpdated,
      };
      await prefs.setString('weather_data', json.encode(data));
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Calculate coordinates from student index
  void _calculateCoordinates() {
    final index = _indexController.text.trim();
    
    if (index.length < 4) {
      setState(() {
        _errorMessage = 'Index must be at least 4 characters';
        _latitude = null;
        _longitude = null;
      });
      return;
    }

    try {
      final firstTwo = int.parse(index.substring(0, 2));
      final nextTwo = int.parse(index.substring(2, 4));
      
      setState(() {
        _latitude = 5.0 + (firstTwo / 10.0);
        _longitude = 79.0 + (nextTwo / 10.0);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid index format';
        _latitude = null;
        _longitude = null;
      });
    }
  }

  // Fetch weather data from Open-Meteo API
  Future<void> _fetchWeather() async {
    _calculateCoordinates();
    
    if (_latitude == null || _longitude == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCached = false;
    });

    final url = 'https://api.open-meteo.com/v1/forecast?latitude=${_latitude!.toStringAsFixed(1)}&longitude=${_longitude!.toStringAsFixed(1)}&current_weather=true';
    
    setState(() {
      _requestUrl = url;
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentWeather = data['current_weather'];
        
        final now = DateTime.now();
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        
        setState(() {
          _temperature = currentWeather['temperature']?.toDouble();
          _windSpeed = currentWeather['windspeed']?.toDouble();
          _weatherCode = currentWeather['weathercode'];
          _lastUpdated = formatter.format(now);
          _isLoading = false;
          _errorMessage = null;
        });

        // Save to cache
        await _saveCachedData();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch weather data (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: Unable to fetch weather data. ${_temperature != null ? "Showing cached data." : ""}';
        if (_temperature != null) {
          _isCached = true;
        }
      });
    }
  }

  // Get weather icon based on weather code
  IconData _getWeatherIcon() {
    if (_weatherCode == null) return Icons.cloud;
    
    if (_weatherCode == 0) return Icons.wb_sunny;
    if (_weatherCode! <= 3) return Icons.cloud;
    if (_weatherCode! <= 48) return Icons.foggy;
    if (_weatherCode! <= 67) return Icons.grain;
    if (_weatherCode! <= 77) return Icons.ac_unit;
    if (_weatherCode! <= 99) return Icons.thunderstorm;
    
    return Icons.cloud;
  }

  // Get weather description based on weather code
  String _getWeatherDescription() {
    if (_weatherCode == null) return 'Unknown';
    
    if (_weatherCode == 0) return 'Clear Sky';
    if (_weatherCode! <= 3) return 'Partly Cloudy';
    if (_weatherCode! <= 48) return 'Foggy';
    if (_weatherCode! <= 67) return 'Rainy';
    if (_weatherCode! <= 77) return 'Snowy';
    if (_weatherCode! <= 99) return 'Thunderstorm';
    
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 20),
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Weather Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Personalized Weather Forecast',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Input Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Index',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _indexController,
                          decoration: InputDecoration(
                            hintText: 'Enter your index (e.g., 224084B)',
                            prefixIcon: const Icon(Icons.badge),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fetchWeather,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_download, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Fetch Weather',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Coordinates Display
                if (_latitude != null && _longitude != null)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCoordinateBox(
                            'Latitude',
                            _latitude!.toStringAsFixed(2),
                            Icons.public,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey.shade300,
                          ),
                          _buildCoordinateBox(
                            'Longitude',
                            _longitude!.toStringAsFixed(2),
                            Icons.map,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Card(
                    elevation: 4,
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_errorMessage != null) const SizedBox(height: 24),

                // Weather Data Display
                if (_temperature != null)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Weather',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isCached)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.offline_bolt,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(Cached)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Icon(
                            _getWeatherIcon(),
                            size: 80,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_temperature!.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getWeatherDescription(),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherDetail(
                                'Wind Speed',
                                '${_windSpeed!.toStringAsFixed(1)} km/h',
                                Icons.air,
                              ),
                              _buildWeatherDetail(
                                'Weather Code',
                                _weatherCode.toString(),
                                Icons.code,
                              ),
                            ],
                          ),
                          if (_lastUpdated != null) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Last updated: $_lastUpdated',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Request URL Display
                if (_requestUrl != null)
                  Card(
                    elevation: 4,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Request URL:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _requestUrl!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
