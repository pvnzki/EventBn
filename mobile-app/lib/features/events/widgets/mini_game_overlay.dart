import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class MiniGameOverlay extends StatefulWidget {
  const MiniGameOverlay({super.key});

  @override
  State<MiniGameOverlay> createState() => _MiniGameOverlayState();
}

class _MiniGameOverlayState extends State<MiniGameOverlay>
    with TickerProviderStateMixin {
  bool _showWheel = false;
  int _spinsLeft = 3;
  DateTime _nextSpinTime =
      DateTime.now().add(const Duration(hours: 23, minutes: 9, seconds: 7));

  // Animation controllers
  late AnimationController _wheelController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _celebrationController;
  late AnimationController _bounceController;
  late AnimationController _shimmerController;

  double _wheelAngle = 0;
  bool _isSpinning = false;
  String? _selectedReward;

  // Enhanced animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;

    final List<String> _wheelRewards = [
      '1 Free Ticket',
      '2 Free Tickets',
      'VIP Ticket',
      'Backstage Pass',
      'LKR 500 Voucher',
      'LKR 1000 Voucher',
      'Try Again',
      'Extra Spin'
    ];

  final List<Color> _wheelColors = [
    const Color(0xFFFF6B35), // Vibrant orange
    const Color(0xFFF7931E), // Golden orange
    const Color(0xFF4285F4), // Google blue
    const Color(0xFFEA4335), // Google red
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF5722), // Deep orange
    const Color(0xFF4CAF50), // Green
    const Color(0xFF673AB7), // Deep purple
  ];

  // Particle system
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse animation for the floating button
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Particle animation
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));

    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Celebration animation
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    // Bounce animation
    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Shimmer animation
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    // Start continuous animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  void _generateParticles() {
    _particles = List.generate(20, (index) {
      final random = Random();
      return Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 400,
        dx: (random.nextDouble() - 0.5) * 4,
        dy: (random.nextDouble() - 0.5) * 4,
        size: random.nextDouble() * 8 + 4,
        color: _wheelColors[random.nextInt(_wheelColors.length)],
        life: random.nextDouble() * 0.5 + 0.5,
      );
    });
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _celebrationController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showWheel = true;
    });
    _bounceController.forward();
  }

  void _spinWheel() async {
    if (_isSpinning || _spinsLeft <= 0) return;

    // Haptic feedback for premium feel
    HapticFeedback.heavyImpact();

    setState(() {
      _isSpinning = true;
      _spinsLeft--;
      _selectedReward = null;
    });

    // Start particle effects
    _particleController.forward();
    _generateParticles();

    final random = Random();
    final targetIndex = random.nextInt(_wheelRewards.length);
    final singleSegment = 2 * pi / _wheelRewards.length;
    final targetAngle = (targetIndex * singleSegment) + (singleSegment / 2);

    // Enhanced spin physics - more rotations and better easing
    final minSpins = 6;
    final maxSpins = 10;
    final spins = minSpins + random.nextDouble() * (maxSpins - minSpins);
    final fullSpins = spins * 2 * pi;
    final finalAngle = _wheelAngle + fullSpins + (2 * pi - targetAngle);

    _wheelController.reset();
    final animation = Tween<double>(
      begin: _wheelAngle,
      end: finalAngle,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: const Cubic(0.25, 0.46, 0.45, 0.94), // Premium easing curve
    ));

    animation.addListener(() {
      setState(() {
        _wheelAngle = animation.value;
      });
    });

    animation.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Completion haptic
        await Future.delayed(const Duration(milliseconds: 200));
        HapticFeedback.heavyImpact();

        setState(() {
          _isSpinning = false;
          _selectedReward = _wheelRewards[targetIndex];
        });

        // Start celebration animation
        _celebrationController.forward();
      }
    });

    await _wheelController.forward();
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
    if (!_showWheel) {
      return Positioned(
        right: 6,
        bottom: 70,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: _startGame,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: const Color(0xFF32CD32).withOpacity(0.6),
                    //     blurRadius: 30,
                    //     offset: const Offset(0, 8),
                    //   ),
                    //   BoxShadow(
                    //     color: const Color(0xFF32CD32).withOpacity(0.3),
                    //     blurRadius: 20,
                    //     offset: const Offset(0, 16),
                    //   ),
                    // ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/icons/Offers_Green.png',
                      fit: BoxFit.cover,
                      width: 70,
                      height: 70,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FAFC), Color(0xFFE3E8EF)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Animated background particles
                  AnimatedBuilder(
                    animation: _particleAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ParticlePainter(_particles, _particleAnimation.value),
                        size: Size.infinite,
                      );
                    },
                  ),
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enhanced Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _showWheel = false;
                                    _selectedReward = null;
                                  });
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _bounceAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _bounceAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF32CD32), Color(0xFF1DE9B6)],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF32CD32).withOpacity(0.18),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flash_on, color: Colors.white, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$_spinsLeft spins left',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Enhanced Title
                        Text(
                          'Lucky Spin',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Enhanced Timer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Next free spins: ${_formatTimer(_nextSpinTime)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Spin Button
                        GestureDetector(
                          onTap: _spinWheel,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_glowAnimation, _bounceAnimation]),
                            builder: (context, child) {
                              final isDisabled = _isSpinning || _spinsLeft <= 0;
                              return Transform.scale(
                                scale: isDisabled ? 1.0 : _bounceAnimation.value,
                                child: Container(
                                  width: 180,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: isDisabled
                                        ? LinearGradient(
                                            colors: [Colors.grey.shade400, Colors.grey.shade600],
                                          )
                                        : LinearGradient(
                                            colors: [Color(0xFF32CD32), Color(0xFF1DE9B6)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: isDisabled
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: const Color(0xFF32CD32).withOpacity(0.18),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_isSpinning) ...[
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Text(
                                          _isSpinning ? 'Spinning...' : 'SPIN NOW',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Wheel
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 360,
                                    height: 360,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF32CD32).withOpacity(_glowAnimation.value * 0.12),
                                          blurRadius: 60,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Main wheel
                              AnimatedBuilder(
                                animation: _wheelController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _wheelAngle,
                                    child: CustomPaint(
                                      size: const Size(340, 340),
                                      painter: EnhancedWheelPainter(_wheelRewards, _wheelColors),
                                    ),
                                  );
                                },
                              ),
                              // Center decoration
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const RadialGradient(
                                    colors: [Color(0xFF32CD32), Color(0xFF1DE9B6)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF32CD32).withOpacity(0.18),
                                      blurRadius: 20,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.stars,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Enhanced Pointer
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.5 - 30,
                    left: MediaQuery.of(context).size.width * 0.5 + 150,
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(width: 20, color: Colors.transparent),
                          right: BorderSide(width: 20, color: Colors.transparent),
                          bottom: BorderSide(width: 30, color: Color(0xFF32CD32)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF32CD32),
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Enhanced Result Dialog
                  if (_selectedReward != null) _buildEnhancedResultDialog(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedResultDialog() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _celebrationAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B0000),
                      Color(0xFFDC143C),
                      Color(0xFFFF6347)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: const Color(0xFFDC143C).withOpacity(0.5),
                      blurRadius: 60,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Celebration effects
                    SizedBox(
                      width: 200,
                      height: 150,
                      child: CustomPaint(
                        painter:
                            CelebrationPainter(_celebrationAnimation.value),
                      ),
                    ),

                    // BIG WIN text with enhanced styling
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                          Color(0xFFFF6B35)
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'BIG WIN!',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Enhanced treasure chest
                    Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                            Color(0xFFB8860B)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: const Color(0xFF8B4513), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF8B4513),
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Enhanced reward text
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        _selectedReward == '60 freespins'
                            ? '+60 FREE SPINS'
                            : _selectedReward!,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Enhanced collect button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        _celebrationController.reset();
                        setState(() {
                          _selectedReward = null;
                        });
                      },
                      child: Container(
                        width: 200,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF32CD32),
                              Color(0xFF1DE9B6),
                              Color(0xFF00CED1)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF32CD32).withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'COLLECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Wheel Painter
class EnhancedWheelPainter extends CustomPainter {
  final List<String> rewards;
  final List<Color> colors;

  EnhancedWheelPainter(this.rewards, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * pi / rewards.length;

    // Draw outer ring
    final outerRingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, outerRingPaint);

    // Draw wheel segments with enhanced styling
    for (int i = 0; i < rewards.length; i++) {
      final segmentPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i % colors.length].withOpacity(0.9),
            colors[i % colors.length],
            colors[i % colors.length].withOpacity(0.7),
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      // Draw segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        i * sweepAngle - pi / 2,
        sweepAngle,
        true,
        segmentPaint,
      );

      // Draw segment border with gradient
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        i * sweepAngle - pi / 2,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw enhanced text
      final textSpan = TextSpan(
        text: rewards[i],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black87,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Calculate text position
      final textAngle = (i + 0.5) * sweepAngle - pi / 2;
      final textRadius = radius * 0.75;
      final textOffset = Offset(
        center.dx + cos(textAngle) * textRadius - textPainter.width / 2,
        center.dy + sin(textAngle) * textRadius - textPainter.height / 2,
      );

      canvas.save();
      canvas.translate(textOffset.dx + textPainter.width / 2,
          textOffset.dy + textPainter.height / 2);
      canvas.rotate(textAngle + pi / 2);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Draw inner decorative ring
    final innerRingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B4513), Color(0xFFCD853F)],
      ).createShader(Rect.fromCircle(center: center, radius: 40))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, 40, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle class for enhanced effects
class Particle {
  double x, y, dx, dy, size, life;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    required this.life,
  });
}

// Particle Painter for background effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final opacity = (1.0 - animationValue) * particle.life;
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.fill;

      final currentX = particle.x + (particle.dx * animationValue * 100);
      final currentY = particle.y + (particle.dy * animationValue * 100);
      final currentSize = particle.size * (1.0 - animationValue * 0.5);

      canvas.drawCircle(
        Offset(currentX, currentY),
        currentSize,
        paint,
      );

      // Add glow effect
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(currentX, currentY),
        currentSize * 1.5,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Celebration Painter for win effects
class CelebrationPainter extends CustomPainter {
  final double animationValue;

  CelebrationPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42); // Fixed seed for consistent animation

    // Draw confetti
    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * pi;
      final distance = animationValue * 80;
      final x = center.dx + cos(angle + animationValue * 2) * distance;
      final y = center.dy + sin(angle + animationValue * 2) * distance;

      final colors = [
        const Color(0xFFFFD700),
        const Color(0xFFF7931E),
        const Color(0xFF4285F4),
        const Color(0xFFEA4335),
        const Color(0xFF4CAF50),
      ];

      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(1.0 - animationValue)
        ..style = PaintingStyle.fill;

      final size = 6 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), size, paint);
    }

    // Draw sparkles
    for (int i = 0; i < 15; i++) {
      final angle = (i / 15) * 2 * pi + animationValue * 3;
      final distance = 60 + sin(animationValue * 4) * 20;
      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;

      final sparkleSize = 3 + sin(animationValue * 6 + i) * 2;

      final paint = Paint()
        ..color = Colors.white.withOpacity((1.0 - animationValue) * 0.8)
        ..style = PaintingStyle.fill;

      // Draw star shape
      _drawStar(canvas, Offset(x, y), sparkleSize, paint);
    }

    // Draw coins
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final distance = animationValue * 100;
      final x = center.dx + cos(angle) * distance;
      final y =
          center.dy + sin(angle) * distance + sin(animationValue * 4) * 10;

      final coinPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 8))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, coinPaint);

      final dollarPaint = Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.fill;

      final textSpan = TextSpan(
        text: '\',',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: dollarPaint.color,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 4, y - 6));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    const angle = 2 * pi / points;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? size : size * 0.5;
      final x = center.dx + cos(i * angle / 2 - pi / 2) * radius;
      final y = center.dy + sin(i * angle / 2 - pi / 2) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
