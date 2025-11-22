import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
  String? _temperature;
  String? _windSpeed;
  String? _weatherCode;
  String? _lastUpdated;
  String? _requestUrl;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  // Load cached weather data
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _latitude = prefs.getDouble('latitude');
      _longitude = prefs.getDouble('longitude');
      _temperature = prefs.getString('temperature');
      _windSpeed = prefs.getString('windSpeed');
      _weatherCode = prefs.getString('weatherCode');
      _lastUpdated = prefs.getString('lastUpdated');
      _requestUrl = prefs.getString('requestUrl');
      _isCached = _temperature != null;
    });
  }

  // Save weather data to cache
  Future<void> _saveCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', _latitude!);
    await prefs.setDouble('longitude', _longitude!);
    await prefs.setString('temperature', _temperature!);
    await prefs.setString('windSpeed', _windSpeed!);
    await prefs.setString('weatherCode', _weatherCode!);
    await prefs.setString('lastUpdated', _lastUpdated!);
    await prefs.setString('requestUrl', _requestUrl!);
  }

  // Calculate coordinates from student index
  void _calculateCoordinates(String index) {
    if (index.length < 4) {
      setState(() {
        _errorMessage = 'Index must be at least 4 digits';
        _latitude = null;
        _longitude = null;
      });
      return;
    }

    try {
      int firstTwo = int.parse(index.substring(0, 2));
      int nextTwo = int.parse(index.substring(2, 4));
      
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

  // Fetch weather data from API
  Future<void> _fetchWeather() async {
    String index = _indexController.text.trim();
    if (index.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your student index';
      });
      return;
    }

    _calculateCoordinates(index);
    
    if (_latitude == null || _longitude == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCached = false;
    });

    _requestUrl = 'https://api.open-meteo.com/v1/forecast?latitude=${_latitude!.toStringAsFixed(1)}&longitude=${_longitude!.toStringAsFixed(1)}&current_weather=true';

    try {
      final response = await http.get(
        Uri.parse(_requestUrl!),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentWeather = data['current_weather'];
        
        setState(() {
          _temperature = currentWeather['temperature'].toString();
          _windSpeed = currentWeather['windspeed'].toString();
          _weatherCode = currentWeather['weathercode'].toString();
          _lastUpdated = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          _isLoading = false;
          _errorMessage = null;
        });

        await _saveCachedData();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch weather data (Status: ${response.statusCode})';
          _isCached = _temperature != null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: ${e.toString()}';
        _isCached = _temperature != null;
      });
    }
  }

  // Get weather description from code
  String _getWeatherDescription(String? code) {
    if (code == null) return 'Unknown';
    switch (code) {
      case '0':
        return 'Clear sky ☀️';
      case '1':
      case '2':
      case '3':
        return 'Partly cloudy ⛅';
      case '45':
      case '48':
        return 'Foggy 🌫️';
      case '51':
      case '53':
      case '55':
        return 'Drizzle 🌦️';
      case '61':
      case '63':
      case '65':
        return 'Rain 🌧️';
      case '71':
      case '73':
      case '75':
        return 'Snow 🌨️';
      case '95':
        return 'Thunderstorm ⛈️';
      default:
        return 'Code: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3),
              const Color(0xFF1976D2),
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 20),
                const Icon(
                  Icons.wb_sunny,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Weather Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Personalized Weather Information',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Input Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Index',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _indexController,
                          decoration: InputDecoration(
                            hintText: 'Enter your index (e.g., 224084)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.person),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchWeather,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_download),
                            label: Text(
                              _isLoading ? 'Fetching...' : 'Fetch Weather',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Coordinates Card
                if (_latitude != null && _longitude != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF2196F3)),
                              SizedBox(width: 8),
                              Text(
                                'Coordinates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCoordinateItem(
                                'Latitude',
                                _latitude!.toStringAsFixed(2),
                                Icons.horizontal_rule,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _buildCoordinateItem(
                                'Longitude',
                                _longitude!.toStringAsFixed(2),
                                Icons.vertical_align_center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage != null)
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Weather Data Card
                if (_temperature != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.thermostat, color: Color(0xFF2196F3)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Current Weather',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isCached)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '(cached)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 20),
                          
                          // Temperature Display
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '$_temperature°C',
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                                Text(
                                  _getWeatherDescription(_weatherCode),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Weather Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherDetail(
                                'Wind Speed',
                                '$_windSpeed km/h',
                                Icons.air,
                              ),
                              _buildWeatherDetail(
                                'Weather Code',
                                _weatherCode!,
                                Icons.code,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Last Updated
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Color(0xFF2196F3),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Last updated: $_lastUpdated',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Request URL Card
                if (_requestUrl != null)
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.link, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                'Request URL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _requestUrl!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }
}
