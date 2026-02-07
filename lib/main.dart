import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/year_progress_utils.dart';
import 'widgets/dot_grid_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';

void main() {
  runApp(const YearTrackerApp());
}

class YearTrackerApp extends StatelessWidget {
  const YearTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Year Progress Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const YearTrackerScreen(),
    );
  }
}

class YearTrackerScreen extends StatefulWidget {
  const YearTrackerScreen({super.key});

  @override
  State<YearTrackerScreen> createState() => _YearTrackerScreenState();
}

class _YearTrackerScreenState extends State<YearTrackerScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.tracker/wallpaper');
  bool _isSettingWallpaper = false;
  Color _selectedColor = const Color(0xFF9ED9A3);
  bool _isPreviewMode = false;
  Timer? _refreshTimer;
  
  // Grid Customization Parameters
  double _dotScale = 1.0;
  double _spacingScale = 1.0;
  double _verticalOffset = 0.0;
  double _gridScale = 1.0;
  int _gridColumns = 12;

  @override
  void initState() {
    super.initState() ;
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh UI and sync widget when app returns to foreground
      setState(() {});
      _updateWidget();
    }
  }

  void _startRefreshTimer() {
    // Check every minute if the day has changed
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _updateWidget() async {
    await HomeWidget.updateWidget(
      name: 'YearWidgetProvider',
      androidName: 'YearWidgetProvider',
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedColor = Color(prefs.getInt('primary_color') ?? 0xFF9ED9A3);
      _dotScale = prefs.getDouble('dot_scale') ?? 1.0;
      _spacingScale = prefs.getDouble('spacing_scale') ?? 1.0;
      _verticalOffset = prefs.getDouble('vertical_offset') ?? 0.0;
      _gridScale = prefs.getDouble('grid_scale') ?? 1.0;
      _gridColumns = prefs.getInt('grid_columns') ?? 12;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) await prefs.setInt(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is bool) await prefs.setBool(key, value);

    if (key == 'primary_color') {
      final color = Color(value as int);
      await HomeWidget.saveWidgetData<String>('primary_color_hex', '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}');
    } else if (value is double) {
      await HomeWidget.saveWidgetData<double>(key, value);
    } else if (value is int) {
      await HomeWidget.saveWidgetData<int>(key, value);
    }
    
    await HomeWidget.updateWidget(
      name: 'YearWidgetProvider',
      androidName: 'YearWidgetProvider',
    );
  }

  Future<void> _saveColor(Color color) async {
    setState(() {
      _selectedColor = color;
    });
    await _saveSetting('primary_color', color.toARGB32());
  }

  Future<void> _setWallpaper(String target) async {
    setState(() {
      _isSettingWallpaper = true;
    });

    try {
      await platform.invokeMethod('setWallpaper', {
        'target': target,
        'color': '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
        'dot_scale': _dotScale,
        'spacing_scale': _spacingScale,
        'vertical_offset': _verticalOffset,
        'grid_scale': _gridScale,
        'grid_columns': _gridColumns,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage(target)),
            backgroundColor: _selectedColor,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set wallpaper: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingWallpaper = false;
        });
      }
    }
  }

  String _getSuccessMessage(String target) {
    switch (target) {
      case 'home':
        return 'Home screen wallpaper set!';
      case 'lock':
        return 'Lock screen wallpaper set!';
      default:
        return 'Wallpaper set for both screens!';
    }
  }

  void _showAppearanceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ColorOption(
                      color: const Color(0xFF9ED9A3),
                      isSelected: _selectedColor.toARGB32() == 0xFF9ED9A3,
                      onTap: () {
                        setSheetState(() => _saveColor(const Color(0xFF9ED9A3)));
                      },
                    ),
                    _ColorOption(
                      color: const Color(0xFFFF5252),
                      isSelected: _selectedColor.toARGB32() == 0xFFFF5252,
                      onTap: () {
                        setSheetState(() => _saveColor(const Color(0xFFFF5252)));
                      },
                    ),
                    _ColorOption(
                      color: const Color(0xFFFF9800),
                      isSelected: _selectedColor.toARGB32() == 0xFFFF9800,
                      onTap: () {
                        setSheetState(() => _saveColor(const Color(0xFFFF9800)));
                      },
                    ),
                    _ColorOption(
                      color: const Color(0xFF448AFF),
                      isSelected: _selectedColor.toARGB32() == 0xFF448AFF,
                      onTap: () {
                        setSheetState(() => _saveColor(const Color(0xFF448AFF)));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _CustomSlider(
                  label: 'Dot Size',
                  value: _dotScale,
                  min: 0.2,
                  max: 2.0,
                  activeColor: _selectedColor,
                  onChanged: (val) {
                    setSheetState(() {
                      _dotScale = val;
                      _saveSetting('dot_scale', val);
                    });
                    setState(() {});
                  },
                ),
                _CustomSlider(
                  label: 'Spacing',
                  value: _spacingScale,
                  min: 0.5,
                  max: 2.0,
                  activeColor: _selectedColor,
                  onChanged: (val) {
                    setSheetState(() {
                      _spacingScale = val;
                      _saveSetting('spacing_scale', val);
                    });
                    setState(() {});
                  },
                ),
                _CustomSlider(
                  label: 'Zoom',
                  value: _gridScale,
                  min: 0.5,
                  max: 1.5,
                  activeColor: _selectedColor,
                  onChanged: (val) {
                    setSheetState(() {
                      _gridScale = val;
                      _saveSetting('grid_scale', val);
                    });
                    setState(() {});
                  },
                ),
                _CustomSlider(
                  label: 'Vertical Position',
                  value: _verticalOffset,
                  min: -0.5,
                  max: 0.5,
                  activeColor: _selectedColor,
                  onChanged: (val) {
                    setSheetState(() {
                      _verticalOffset = val;
                      _saveSetting('vertical_offset', val);
                    });
                    setState(() {});
                  },
                ),
                _CustomSlider(
                  label: 'Columns',
                  value: _gridColumns.toDouble(),
                  min: 8,
                  max: 20,
                  divisions: 12,
                  activeColor: _selectedColor,
                  onChanged: (val) {
                    setSheetState(() {
                      _gridColumns = val.round();
                      _saveSetting('grid_columns', _gridColumns);
                    });
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWallpaperOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set as Wallpaper',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _WallpaperOption(
                icon: Icons.home_outlined,
                label: 'Home Screen',
                onTap: () {
                  Navigator.pop(context);
                  _setWallpaper('home');
                },
              ),
              const SizedBox(height: 12),
              _WallpaperOption(
                icon: Icons.lock_outline,
                label: 'Lock Screen',
                onTap: () {
                  Navigator.pop(context);
                  _setWallpaper('lock');
                },
              ),
              const SizedBox(height: 12),
                _WallpaperOption(
                  icon: Icons.wallpaper,
                  label: 'Both Screens',
                  onTap: () {
                    Navigator.pop(context);
                    _setWallpaper('both');
                  },
                  isPrimary: true,
                  primaryColor: _selectedColor,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: Wallpaper uses App colors and scales.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final utils = YearProgressUtils();
    final int totalDays = utils.totalDays;
    final int currentDayOfYear = utils.currentDayOfYear;
    final int daysRemaining = utils.daysRemaining;
    final int daysLived = utils.daysLived;
    final double percentageCompleted = utils.percentageCompleted;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(totalDays, currentDayOfYear, daysRemaining, daysLived, percentageCompleted),
    );
  }

  Widget _buildBody(int totalDays, int currentDayOfYear, int daysRemaining, int daysLived, double percentageCompleted) {
    return Stack(
      children: [
        // 1. Full screen grid (True Wallpaper View - Background)
        Positioned.fill(
          child: CustomPaint(
            painter: DotGridPainter(
              totalDays: totalDays,
              currentDayOfYear: currentDayOfYear,
              columns: _gridColumns,
              primaryColor: _selectedColor,
              dotScale: _dotScale,
              spacingScale: _spacingScale,
              verticalOffset: _verticalOffset,
              gridScale: _gridScale,
            ),
          ),
        ),

        // 2. Stats at exactly the same relative position as the wallpaper
        Positioned(
          top: MediaQuery.of(context).size.height * 0.72,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$daysRemaining',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Days remaining',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentageCompleted.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.08,
                        fontWeight: FontWeight.bold,
                        color: _selectedColor,
                      ),
                    ),
                    Text(
                      '$daysLived days lived',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 3. Control overlays (Only shown when NOT in preview mode)
        if (!_isPreviewMode) ...[
          // Top Left: Appearance & Preview
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAppearanceOptions,
                  icon: Icon(Icons.palette_outlined, color: _selectedColor, size: 28),
                  tooltip: 'Appearance',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _isPreviewMode = true),
                  icon: Icon(Icons.visibility_outlined, color: _selectedColor, size: 28),
                  tooltip: 'Preview',
                ),
              ],
            ),
          ),
          // Top Right: Wallpaper
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              onPressed: _isSettingWallpaper ? null : _showWallpaperOptions,
              icon: _isSettingWallpaper
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _selectedColor))
                  : Icon(Icons.wallpaper, color: _selectedColor, size: 28),
              tooltip: 'Set Wallpaper',
            ),
          ),
        ],

        // 4. Exit Preview Button (Only shown in preview mode)
        if (_isPreviewMode)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: TextButton.icon(
              onPressed: () => setState(() => _isPreviewMode = false),
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              label: const Text('Exit Preview', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
      ],
    );
  }
}

class _WallpaperOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color primaryColor;

  const _WallpaperOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.primaryColor = const Color(0xFF9ED9A3),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? primaryColor : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.black : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

class _CustomSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _CustomSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(color: activeColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: const Color(0xFF333333),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
