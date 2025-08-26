import 'package:flutter/material.dart';
import 'dart:math';

class MiniGameOverlay extends StatefulWidget {
  const MiniGameOverlay({super.key});

  @override
  State<MiniGameOverlay> createState() => _MiniGameOverlayState();
}

class _MiniGameOverlayState extends State<MiniGameOverlay>
    with TickerProviderStateMixin {
  bool _showGame = false;
  bool _isGameActive = false;
  int _score = 0;
  int _timeLeft = 30;
  List<GameItem> _gameItems = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _showGame = true;
      _isGameActive = true;
      _score = 0;
      _timeLeft = 30;
      _gameItems = _generateGameItems();
    });

    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isGameActive) {
        setState(() {
          _timeLeft--;
        });
        if (_timeLeft > 0) {
          _startTimer();
        } else {
          _endGame();
        }
      }
    });
  }

  void _endGame() {
    setState(() {
      _isGameActive = false;
    });

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultDialog(),
    );
  }

  List<GameItem> _generateGameItems() {
    final random = Random();
    final items = <GameItem>[];

    for (int i = 0; i < 8; i++) {
      items.add(GameItem(
        id: i,
        x: random.nextDouble() * 0.8,
        y: random.nextDouble() * 0.6,
        type: random.nextBool() ? GameItemType.good : GameItemType.bad,
        isVisible: true,
      ));
    }

    return items;
  }

  void _onItemTap(GameItem item) {
    if (!_isGameActive || !item.isVisible) return;

    setState(() {
      if (item.type == GameItemType.good) {
        _score += 10;
      } else {
        _score = max(0, _score - 5);
      }
      item.isVisible = false;
    });

    // Add new item after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isGameActive) {
        setState(() {
          final random = Random();
          final newItem = GameItem(
            id: DateTime.now().millisecondsSinceEpoch,
            x: random.nextDouble() * 0.8,
            y: random.nextDouble() * 0.6,
            type: random.nextBool() ? GameItemType.good : GameItemType.bad,
            isVisible: true,
          );
          _gameItems.add(newItem);
        });
      }
    });
  }

  Widget _buildResultDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String message;
    String offer;

    if (_score >= 80) {
      message = 'Amazing! You\'re a pro!';
      offer = '🎉 50% OFF on your next event ticket!';
    } else if (_score >= 50) {
      message = 'Great job!';
      offer = '🎉 25% OFF on your next event ticket!';
    } else if (_score >= 20) {
      message = 'Good effort!';
      offer = '🎉 10% OFF on your next event ticket!';
    } else {
      message = 'Better luck next time!';
      offer = '🎉 5% OFF on your next event ticket!';
    }

    return Dialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _score >= 50 ? Icons.celebration : Icons.emoji_events,
              size: 64,
              color: const Color(0xFF32CD32), // Lime Green
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $_score',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF32CD32)
                    .withValues(alpha: 0.1), // Light lime green background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF32CD32)
                        .withValues(alpha: 0.3)), // Lime green border
              ),
              child: Text(
                offer,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF32CD32), // Lime Green
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _showGame = false;
                      });
                    },
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _startGame();
                    },
                    child: const Text('Play Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showGame) {
      return Positioned(
        right: 20,
        bottom: 100,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: () {
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                    _startGame();
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF32CD32), // Lime Green
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF32CD32).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Column(
          children: [
            // Game Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showGame = false;
                        _isGameActive = false;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time: $_timeLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Game Instructions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Text(
                'Tap the green circles to score points! Avoid red circles!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Game Area
            Expanded(
              child: Stack(
                children: _gameItems
                    .where((item) => item.isVisible)
                    .map((item) => Positioned(
                          left: item.x * MediaQuery.of(context).size.width,
                          top: item.y * MediaQuery.of(context).size.height,
                          child: GestureDetector(
                            onTap: () => _onItemTap(item),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: item.type == GameItemType.good
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (item.type == GameItemType.good
                                            ? Colors.green
                                            : Colors.red)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.type == GameItemType.good
                                    ? Icons.add
                                    : Icons.remove,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GameItemType { good, bad }

class GameItem {
  final int id;
  final double x;
  final double y;
  final GameItemType type;
  bool isVisible;

  GameItem({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isVisible,
  });
}
