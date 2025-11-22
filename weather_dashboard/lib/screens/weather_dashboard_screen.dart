import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/coordinates.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherDashboardScreen extends StatefulWidget {
  const WeatherDashboardScreen({super.key});

  @override
  State<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends State<WeatherDashboardScreen> with TickerProviderStateMixin {
  final TextEditingController _indexController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  
  Coordinates? _coordinates;
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadCachedData();
  }

  @override
  void dispose() {
    _indexController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final cached = await _weatherService.getCachedWeather();
    if (cached != null && mounted) {
      setState(() {
        _weatherData = cached;
      });
    }
  }

  void _calculateCoordinates() {
    try {
      _coordinates = Coordinates.fromStudentIndex(_indexController.text);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Invalid index format. Please enter at least 4 digits.';
      _coordinates = null;
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _calculateCoordinates();
    
    if (_coordinates == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {});

    _slideController.forward(from: 0);

    try {
      final weatherData = await _weatherService.fetchWeather(_coordinates!);
      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoading = false;
          // Show message if displaying cached data
          if (weatherData.isCached) {
            _errorMessage = 'Network unavailable. Showing cached data from last successful fetch.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch weather data: ${e.toString()}';
        });
      }
    }
  }

  String _getWeatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                    const Color(0xFF4C1D95),
                  ]
                : [
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFC084FC),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 32),
                  
                  // Index Input Card
                  _buildInputCard(theme),
                  const SizedBox(height: 24),
                  
                  // Coordinates Display
                  if (_coordinates != null) _buildCoordinatesCard(theme),
                  if (_coordinates != null) const SizedBox(height: 24),
                  
                  // Fetch Button
                  _buildFetchButton(theme),
                  const SizedBox(height: 24),
                  
                  // Loading Indicator
                  if (_isLoading) _buildLoadingIndicator(),
                  
                  // Error Message
                  if (_errorMessage != null) _buildErrorCard(theme),
                  
                  // Weather Data
                  if (_weatherData != null && !_isLoading)
                    _buildWeatherCard(theme),
                  
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        FadeTransition(
          opacity: _pulseController,
          child: const Icon(
            Icons.wb_sunny_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Weather Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personalized by Student Index',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Student Index',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _indexController,
              decoration: InputDecoration(
                hintText: 'Enter your student index (e.g., 194123K)',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesCard(ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Computed Coordinates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCoordItem(
                    'Latitude',
                    _coordinates!.latitudeFormatted,
                    Icons.north,
                    theme,
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: theme.dividerColor,
                  ),
                  _buildCoordItem(
                    'Longitude',
                    _coordinates!.longitudeFormatted,
                    Icons.east,
                    theme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFetchButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _fetchWeather,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: Colors.black26,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isLoading ? Icons.hourglass_empty : Icons.cloud_download, size: 28),
          const SizedBox(width: 12),
          Text(
            _isLoading ? 'Fetching Weather...' : 'Fetch Weather',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Loading weather data...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Card(
        elevation: 12,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Cached badge
                if (_weatherData!.isCached)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.offline_bolt, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '(Cached)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Weather icon and temperature
                Text(
                  _getWeatherIcon(_weatherData!.weatherCode),
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  _weatherData!.getWeatherDescription(),
                  style: TextStyle(
                    fontSize: 20,
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Weather details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherDetail(
                      Icons.air,
                      'Wind Speed',
                      '${_weatherData!.windSpeed.toStringAsFixed(1)} km/h',
                      theme,
                    ),
                    _buildWeatherDetail(
                      Icons.code,
                      'Weather Code',
                      _weatherData!.weatherCode.toString(),
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Last updated
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: ${DateFormat('MMM dd, yyyy HH:mm:ss').format(_weatherData!.lastUpdated)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Request URL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Request URL:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _weatherData!.requestUrl,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
