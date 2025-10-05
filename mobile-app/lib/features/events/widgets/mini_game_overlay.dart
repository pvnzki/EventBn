import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'casino_painters.dart';

class SpinningWheelScreen extends StatefulWidget {
  const SpinningWheelScreen({super.key});

  @override
  State<SpinningWheelScreen> createState() => _SpinningWheelScreenState();
}

class _SpinningWheelScreenState extends State<SpinningWheelScreen>
    with TickerProviderStateMixin {
  int _spinsLeft = 3;
  final DateTime _nextSpinTime =
      DateTime.now().add(const Duration(hours: 23, minutes: 9, seconds: 7));

  // Animation controllers
  late AnimationController _wheelController;
  late AnimationController _celebrationAnimation;
  
  // Wheel state
  double _wheelAngle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  String? _selectedReward;

  // TEMU-style wheel rewards (8 segments)
  final List<String> _wheelRewards = [
    '\$100',
    '59 Freespins',
    '\$200',
    'Gift',
    '\$300',
    '59 Freespins',
    '\$500',
    '\$700',
  ];

  // TEMU-style colors (deep blues and golds)
  final List<Color> _wheelColors = [
    const Color(0xFF1A237E), // Deep blue
    const Color(0xFFFFD700), // Gold
    const Color(0xFF303F9F), // Medium blue
    const Color(0xFFFFA000), // Amber
    const Color(0xFF1A237E), // Deep blue
    const Color(0xFFFFD700), // Gold
    const Color(0xFF303F9F), // Medium blue
    const Color(0xFFFFA000), // Amber
  ];

  @override
  void initState() {
    super.initState();
    // Higher refresh rate animation controller for smoother spinning
    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _celebrationAnimation = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _celebrationAnimation.dispose();
    super.dispose();
  }

  void _spinWheel() async {
    if (_isSpinning || _spinsLeft <= 0) return;

    setState(() {
      _isSpinning = true;
      _spinsLeft--;
    });

    // Strong haptic feedback for spin start
    HapticFeedback.heavyImpact();

    // Store starting angle
    _startAngle = _wheelAngle;

    // Realistic spin physics - start fast, slow down gradually
    final Random random = Random();
    final double baseSpins = 12 + random.nextDouble() * 8; // 12-20 full rotations for dramatic effect
    final double randomOffset = random.nextDouble() * 2 * pi; // Random final position
    final double totalRotation = baseSpins * 2 * pi + randomOffset;
    
    // Calculate target angle
    _targetAngle = _startAngle + totalRotation;
    
    // Determine winning segment based on final position
    final double normalizedAngle = (_targetAngle % (2 * pi));
    final double segmentAngle = (2 * pi) / _wheelRewards.length;
    final int winningSegment = ((2 * pi - normalizedAngle) / segmentAngle).floor() % _wheelRewards.length;

    // Reset and start animation
    _wheelController.reset();
    
    // Animate with realistic easing and higher FPS
    await _wheelController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 5000), // Longer spin for more dramatic effect
      curve: Curves.easeOutCirc, // More realistic casino wheel deceleration
    );

    // Update final state
    setState(() {
      _wheelAngle = _targetAngle;
      _selectedReward = _wheelRewards[winningSegment];
      _isSpinning = false;
    });

    // Show celebration with enhanced feedback
    _celebrationAnimation.forward().then((_) {
      _celebrationAnimation.reverse();
    });

    // Victory haptic feedback sequence
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  String _formatTimer(DateTime nextSpinTime) {
    final now = DateTime.now();
    final diff = nextSpinTime.difference(now);
    if (diff.isNegative) return '00:00:00';

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            onPressed: () => context.go('/home'),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5)).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '$_spinsLeft spins remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.help_outline_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () {
                // Help/Info action
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D1117),
                  Color(0xFF161B22),
                  Color(0xFF21262D),
                  Color(0xFF0D1117),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFE2E8F0),
                  Color(0xFFF8FAFC),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Casino-style header
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                          ? [const Color(0xFF1C2128), const Color(0xFF22272E)]
                          : [Colors.white, const Color(0xFFFAFBFC)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Casino title with golden effect
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
                          ).createShader(bounds),
                          child: Text(
                            'LUCKY WHEEL',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Countdown timer with premium styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Next bonus in ${_formatTimer(_nextSpinTime)}',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              
              const SizedBox(height: 40),
              
              // Casino wheel section
              Expanded(
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                          ? [const Color(0xFF2D3748), const Color(0xFF1A202C)]
                          : [const Color(0xFFFFFFFF), const Color(0xFFF7FAFC)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring decoration
                        Container(
                          width: 310,
                          height: 310,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 8,
                              color: const Color(0xFFFFD700),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        
                        // The spinning wheel
                        AnimatedBuilder(
                          animation: _wheelController,
                          builder: (context, child) {
                            // Calculate current rotation angle during animation
                            double currentAngle = _wheelAngle;
                            if (_isSpinning) {
                              // During spinning, interpolate between start and target angle
                              currentAngle = _startAngle + ((_targetAngle - _startAngle) * _wheelController.value);
                            }
                            
                            return Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Add spinning glow effect
                                boxShadow: _isSpinning ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.6),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.3),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ] : [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: currentAngle,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  child: CustomPaint(
                                    painter: CasinoWheelPainter(
                                      _wheelRewards,
                                      _wheelColors,
                                      isDark,
                                    ),
                                    size: const Size(280, 280),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Center hub with casino styling
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.diamond,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        
                        // Casino-style pointer
                        Positioned(
                          top: 20,
                          child: Container(
                            width: 0,
                            height: 0,
                            child: CustomPaint(
                              painter: CasinoPointerPainter(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Casino-style spin button
              Container(
                margin: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: _spinWheel,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: _isSpinning || _spinsLeft <= 0
                          ? LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade600],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: _isSpinning || _spinsLeft <= 0
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        // Button shimmer effect
                        if (!_isSpinning && _spinsLeft > 0)
                          AnimatedBuilder(
                            animation: _celebrationAnimation,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(-1 + _celebrationAnimation.value * 3, 0),
                                      end: Alignment(0 + _celebrationAnimation.value * 3, 0),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        
                        // Button content
                        Center(
                          child: _isSpinning
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'SPINNING...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _spinsLeft <= 0 ? 'NO SPINS LEFT' : 'SPIN TO WIN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Add bottom padding for safe area
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 20,
              ),
                ],
              ),
            ),
            
            // Celebration overlay  
            if (_selectedReward != null) _buildEnhancedResultDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedResultDialog() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          color: Colors.black.withOpacity(0.85),
        ),
        
        // Confetti and celebration particles
        ...List.generate(50, (index) => 
          AnimatedBuilder(
            animation: _celebrationAnimation,
            builder: (context, child) {
              final randomX = (index * 7.3) % MediaQuery.of(context).size.width;
              final randomY = _celebrationAnimation.value * MediaQuery.of(context).size.height + (index * 20) % 200 - 100;
              final randomRotation = _celebrationAnimation.value * 8 + index;
              final colors = [
                Colors.amber,
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.purple,
                Colors.orange,
              ];
              final color = colors[index % colors.length];
              
              return Positioned(
                left: randomX,
                top: randomY,
                child: Transform.rotate(
                  angle: randomRotation,
                  child: Container(
                    width: 6 + (index % 4),
                    height: 6 + (index % 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: index % 3 != 0 ? BorderRadius.circular(1) : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Firework bursts from corners
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _celebrationAnimation,
            builder: (context, child) {
              List<Widget> fireworks = [];
              
              for (int corner = 0; corner < 4; corner++) {
                late double startX, startY;
                switch (corner) {
                  case 0: startX = 50; startY = 100; break;
                  case 1: startX = MediaQuery.of(context).size.width - 50; startY = 100; break;
                  case 2: startX = 50; startY = MediaQuery.of(context).size.height - 200; break;
                  case 3: startX = MediaQuery.of(context).size.width - 50; startY = MediaQuery.of(context).size.height - 200; break;
                }
                
                for (int burst = 0; burst < 8; burst++) {
                  final angle = (burst * 45.0) * (3.14159 / 180);
                  final distance = _celebrationAnimation.value * 120;
                  final x = startX + cos(angle) * distance;
                  final y = startY + sin(angle) * distance;
                  
                  fireworks.add(
                    Positioned(
                      left: x - 4,
                      top: y - 4,
                      child: Opacity(
                        opacity: 1.0 - _celebrationAnimation.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
              
              return Stack(children: fireworks);
            },
          ),
        ),
        
        // Central celebration content with smooth entrance
        Center(
          child: AnimatedBuilder(
            animation: _celebrationAnimation,
            builder: (context, child) {
              // Multi-stage animation
              final stage1 = Curves.elasticOut.transform((_celebrationAnimation.value * 1.5).clamp(0.0, 1.0));
              final stage2 = Curves.easeOutBack.transform((_celebrationAnimation.value * 2.0 - 0.5).clamp(0.0, 1.0));
              
              return Transform.scale(
                scale: stage1,
                child: Transform.translate(
                  offset: Offset(0, (1 - stage2) * 50),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated trophy/gift icon
                        AnimatedBuilder(
                          animation: _celebrationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: sin(_celebrationAnimation.value * 6) * 0.1,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.amber,
                                      Colors.orange,
                                      Colors.red.shade700,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.celebration,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // "BIG WIN!" text with golden effect
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.yellow, Colors.orange, Colors.red],
                          ).createShader(bounds),
                          child: const Text(
                            'BIG WIN!',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Prize amount with pulsing effect
                        AnimatedBuilder(
                          animation: _celebrationAnimation,
                          builder: (context, child) {
                            final pulse = 1.0 + sin(_celebrationAnimation.value * 8) * 0.05;
                            return Transform.scale(
                              scale: pulse,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1A237E),
                                      Color(0xFF3949AB),
                                      Color(0xFF1A237E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'You Won',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedReward ?? '',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Collect button with shimmer effect
                        AnimatedBuilder(
                          animation: _celebrationAnimation,
                          builder: (context, child) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedReward = null;
                                });
                              },
                              child: Container(
                                width: 200,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Shimmer overlay
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment(-1 + _celebrationAnimation.value * 3, 0),
                                            end: Alignment(0 + _celebrationAnimation.value * 3, 0),
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Button text
                                    const Center(
                                      child: Text(
                                        'Collect Reward',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Pointer Painter for the wheel indicator
// Enhanced 3D Pointer Painter with depth and shadows
class Enhanced3DPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Shadow for the pointer
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    final shadowPath = Path();
    shadowPath.moveTo(center.dx + 2, center.dy + 2);
    shadowPath.lineTo(center.dx - 13, center.dy - 28);
    shadowPath.lineTo(center.dx + 17, center.dy - 28);
    shadowPath.close();
    
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Main pointer with gradient
    final mainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFB8860B), // Darker gold
          const Color(0xFF8B6914), // Even darker
        ],
      ).createShader(Rect.fromLTWH(center.dx - 15, center.dy - 30, 30, 30))
      ..style = PaintingStyle.fill;
    
    final mainPath = Path();
    mainPath.moveTo(center.dx, center.dy);
    mainPath.lineTo(center.dx - 15, center.dy - 30);
    mainPath.lineTo(center.dx + 15, center.dy - 30);
    mainPath.close();
    
    canvas.drawPath(mainPath, mainPaint);
    
    // Highlight on the pointer
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final highlightPath = Path();
    highlightPath.moveTo(center.dx - 3, center.dy - 5);
    highlightPath.lineTo(center.dx - 8, center.dy - 20);
    highlightPath.lineTo(center.dx + 2, center.dy - 20);
    highlightPath.close();
    
    canvas.drawPath(highlightPath, highlightPaint);
    
    // Border for definition
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(mainPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(-15, -30);
    path.lineTo(15, -30);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Enhanced 3D Wheel Painter with realistic depth and lighting
class Enhanced3DWheelPainter extends CustomPainter {
  final List<String> rewards;
  final List<Color> colors;

  Enhanced3DWheelPainter(this.rewards, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final segmentAngle = 2 * pi / rewards.length;
    
    // Draw outer ring with 3D effect
    _draw3DRing(canvas, center, radius);
    
    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      final sweepAngle = segmentAngle;
      
      // Enhanced 3D segment painting
      _draw3DSegment(canvas, rect, startAngle, sweepAngle, colors[i % colors.length], i);
      
      // Draw enhanced text with better positioning
      _drawSegmentText(canvas, center, radius, startAngle, sweepAngle, rewards[i]);
    }
    
    // Draw inner center circle with 3D effect
    _draw3DCenterCircle(canvas, center, radius);
  }

  void _draw3DRing(Canvas canvas, Offset center, double radius) {
    // Outer shadow ring
    final outerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius + 2, outerShadowPaint);

    // Main outer ring with gradient
    final outerRingPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          const Color(0xFFFFD700), // Gold highlight
          const Color(0xFFFFD700).withOpacity(0.7),
          const Color(0xFFB8860B), // Darker gold
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius - 3, outerRingPaint);
  }

  void _draw3DSegment(Canvas canvas, Rect rect, double startAngle, double sweepAngle, Color baseColor, int index) {
    // Base segment
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, startAngle, sweepAngle, true, basePaint);

    // 3D lighting effect - lighter on top-left, darker on bottom-right
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4), // Light source position
        radius: 1.2,
        colors: [
          Colors.white.withOpacity(0.3), // Highlight
          Colors.transparent,
          Colors.black.withOpacity(0.2), // Shadow
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, startAngle, sweepAngle, true, gradientPaint);

    // Enhanced border with depth
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

    // Inner shadow for depth
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final innerRect = Rect.fromCircle(center: rect.center, radius: rect.width / 2 - 5);
    canvas.drawArc(innerRect, startAngle, sweepAngle, true, innerShadowPaint);
  }

  void _drawSegmentText(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String text) {
    final textAngle = startAngle + sweepAngle / 2;
    final textRadius = radius * 0.65; // Adjusted for better positioning
    final textX = center.dx + textRadius * cos(textAngle);
    final textY = center.dy + textRadius * sin(textAngle);
    
    // Enhanced text with shadow
    final shadowTextSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black.withOpacity(0.3),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    
    final mainTextSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
    
    final shadowTextPainter = TextPainter(
      text: shadowTextSpan,
      textDirection: TextDirection.ltr,
    );
    shadowTextPainter.layout();
    
    final mainTextPainter = TextPainter(
      text: mainTextSpan,
      textDirection: TextDirection.ltr,
    );
    mainTextPainter.layout();
    
    // Draw text with rotation
    canvas.save();
    canvas.translate(textX, textY);
    canvas.rotate(textAngle + pi / 2);
    
    // Draw shadow first
    shadowTextPainter.paint(canvas, Offset(-shadowTextPainter.width / 2 + 1, -shadowTextPainter.height / 2 + 1));
    // Draw main text
    mainTextPainter.paint(canvas, Offset(-mainTextPainter.width / 2, -mainTextPainter.height / 2));
    
    canvas.restore();
  }

  void _draw3DCenterCircle(Canvas canvas, Offset center, double radius) {
    final centerRadius = radius * 0.15;
    
    // Center circle shadow
    final centerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + 2, center.dy + 2), centerRadius, centerShadowPaint);
    
    // Center circle with gradient
    final centerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFB8860B), // Darker gold
          const Color(0xFF8B6914), // Even darker
        ],
      ).createShader(Rect.fromCircle(center: center, radius: centerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius, centerPaint);
    
    // Center highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 3, center.dy - 3), centerRadius * 0.3, highlightPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}