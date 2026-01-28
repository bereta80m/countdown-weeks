import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CountdownApp());
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Weeks',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final base = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7D5CFF),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFFDAD2FF),
      displayColor: Colors.white,
      fontFamily: 'Roboto',
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        backgroundColor: const Color(0xFF5C45D6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withOpacity(0.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    cardColor: const Color(0xFF2C1D6B).withOpacity(0.65),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _prefsKey = 'target_date';
  DateTime? _targetDate;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _loadTargetDate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTargetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (!mounted) return;
    setState(() {
      _targetDate = stored != null ? DateTime.tryParse(stored) : null;
    });
    _controller.forward();
  }

  Future<void> _navigateToDateScreen() async {
    final selectedDate = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (context) => DateScreen(initialDate: _targetDate),
      ),
    );

    if (!mounted || selectedDate == null) return;
    setState(() {
      _targetDate = selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B165F), Color(0xFF1C124B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'COUNTDOWN WEEKS',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DatePill(
                      label: _targetDate == null
                          ? 'Selecciona una fecha'
                          : formatDate(_targetDate!),
                    ),
                    const Spacer(),
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCountdown(theme),
                            const SizedBox(height: 20),
                            const _IndicatorDots(count: 7),
                            const SizedBox(height: 20),
                            Text(
                              'Cada día estás más cerca ✨',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _navigateToDateScreen,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Colors.white.withOpacity(0.75),
                        size: 18,
                      ),
                      label: Text(
                        'Cambiar fecha',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'countdown weeks',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.25),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown(ThemeData theme) {
    if (_targetDate == null) {
      return Text(
        'Selecciona una fecha para comenzar',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white.withOpacity(0.7),
        ),
        textAlign: TextAlign.center,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      _targetDate!.year,
      _targetDate!.month,
      _targetDate!.day,
    );
    final difference = target.difference(today).inDays;

    if (difference == 0) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: _switcherTransition,
        child: Text(
          '¡Hoy es el día!',
          key: const ValueKey('today'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (difference > 0) {
      final weeks = difference ~/ 7;
      final days = difference % 7;
      return Column(
        children: [
          Text(
            'FALTAN',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedValueText(
                value: weeks.toString(),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 54,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                label: 'SEMANAS',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: 1,
                  height: 60,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              _AnimatedValueText(
                value: days.toString(),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 54,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                label: 'DÍAS',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Faltan $weeks semanas y $days días',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      );
    }

    final pastDays = difference.abs();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: _switcherTransition,
      child: Text(
        'Han pasado $pastDays días desde tu fecha',
        key: ValueKey('past-$pastDays'),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _switcherTransition(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class DateScreen extends StatefulWidget {
  const DateScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  static const _prefsKey = 'target_date';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              surface: theme.cardColor,
            ),
            dialogBackgroundColor: theme.cardColor,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDate() async {
    if (_selectedDate == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _selectedDate!.toIso8601String());
    if (!mounted) return;
    Navigator.of(context).pop(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir fecha'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B165F), Color(0xFF1C124B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selecciona tu fecha objetivo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _selectedDate == null
                            ? 'Ninguna fecha seleccionada'
                            : formatDate(_selectedDate!),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _pickDate,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Elegir fecha'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _selectedDate == null ? null : _saveDate,
                        child: const Text('Guardar fecha'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedValueText extends StatelessWidget {
  const _AnimatedValueText({
    required this.value,
    required this.style,
    required this.label,
  });

  final String value;
  final TextStyle? style;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            value,
            key: ValueKey(value),
            style: style,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.55),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Colors.white.withOpacity(0.75),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorDots extends StatelessWidget {
  const _IndicatorDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == count ~/ 2
                  ? Colors.white.withOpacity(0.7)
                  : Colors.white.withOpacity(0.25),
            ),
          ),
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  final months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}
