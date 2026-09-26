import 'dart:async';
import 'dart:math';

import 'package:auto_route/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../services/analytics_service.dart';
import '../../../../../widgets/common/custom_toast.dart';
import '../../../../b_splash_stage/splash_service.dart';
import '../../../provider/dashboard_provider.dart';
import 'diamond_catch_provider.dart';
import 'game_popup.dart';

// ==========================================
// 1. DATA STRUCTURES & PARTICLES
// ==========================================

enum HapticFeedbackType { light, medium, heavy }

enum RoadEntityType {
  coin, // Royal Gold Coin (+5 score)
  gem, // Diamond (+10 score)
  hurdle, // Ground Road Barricade (-1 chance)
}

class _RoadEntity {
  final int lane; // -1: Left, 0: Center, 1: Right
  double z; // Distance: 0.0 (horizon) -> 1.0 (player) -> 1.15+ (behind player)
  final RoadEntityType type;
  final int points;
  bool isCollected = false;
  bool hasHit = false;

  _RoadEntity({
    required this.lane,
    required this.z,
    required this.type,
    this.points = 0,
  });
}

class _SparkParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double life = 1.0;
  double size;

  _SparkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class _FloatingScore {
  double x;
  double y;
  final String text;
  final Color color;
  double opacity = 1.0;
  double life = 1.0;

  _FloatingScore({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
  });
}

// ==========================================
// 2. MAIN NINJA ROAD RUNNER SCREEN
// ==========================================

@RoutePage()
class DiamondCatchScreen extends ConsumerStatefulWidget {
  const DiamondCatchScreen({
    super.key,
    required this.userId,
    required this.gameGems,
    required this.installGems,
    required this.dailyGemsForInstall,
    required this.gemsRequired,
  });

  final String userId;
  final int gameGems;
  final int installGems;
  final int dailyGemsForInstall;
  final int gemsRequired;

  @override
  ConsumerState<DiamondCatchScreen> createState() => _DiamondCatchScreenState();
}

class _DiamondCatchScreenState extends ConsumerState<DiamondCatchScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final Random _random = Random();

  // 3-Lane Road Runner Player State
  int _currentLane = 0; // -1: Left, 0: Center, 1: Right
  double _ninjaLaneX = 0.0; // Smoothly interpolates to _currentLane
  bool _isJumping = false;
  double _jumpY = 0.0; // Height above road surface in pixels
  double _jumpVy = 0.0; // Jump velocity
  double _runStep = 0.0; // Running stride animation counter
  double _roadScrollZ = 0.0; // Perspective road lines scrolling
  int _invulnerableTimer = 0; // Brief grace period after impact
  int _shakeTimer = 0; // Screen shake timer on collision
  static const double _roadSpeed = 0.016; // Entity advance speed per frame (~60 FPS)

  // Road Entities (Coins, Gems, Hurdles)
  final List<_RoadEntity> _roadEntities = [];
  int _spawnCounter = 0;
  int _nextSpawnInterval = 45;

  // Countdown & Flow
  bool _isCountingDown = false;
  int _countdownNumber = 3;
  bool _gameStarted = false;
  bool _isGameOver = false;
  bool _isGameWon = false;

  // Score & Chances (100% Preserved Logic)
  int _score = 0;
  int _targetScore = 100;
  int _movesLeft = 5;

  // Settings
  final bool _isVibrateOn = true;

  // Visual Effects
  final List<_SparkParticle> _sparks = [];
  final List<_FloatingScore> _floatingScores = [];

  // Controllers
  late AnimationController _gameLoopController;
  late AnimationController _startScreenEntranceController;
  late AnimationController _buttonPulseController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _countdownAnimController;
  late Animation<double> _countdownScaleAnim;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userId.isNotEmpty) {
        ref.read(diamondCatchVerifierProvider(widget.userId));
      }
    });

    _startScreenEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );

    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _countdownScaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _countdownAnimController, curve: Curves.elasticOut),
    );

    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGameFrame);
    _gameLoopController.repeat();

    _setupNewGameRound();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _countdownAnimController.dispose();
    _gameLoopController.dispose();
    _startScreenEntranceController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  // ==========================================
  // 3. TARGET SCORE & SETUP (PRESERVED)
  // ==========================================

  void _pickRandomTargetScore() {
    final config = SplashService.superOfferConfig;
    final rawTargetScores = config['targetScores'];
    List<int> scoresList = [10, 20, 30];

    if (rawTargetScores is List) {
      scoresList = rawTargetScores
          .map((item) => int.tryParse(item.toString()) ?? 0)
          .where((n) => n > 0)
          .toList();
    } else if (rawTargetScores is String) {
      scoresList = rawTargetScores
          .split(',')
          .map((item) => int.tryParse(item.trim()) ?? 0)
          .where((n) => n > 0)
          .toList();
    }

    if (scoresList.isEmpty) {
      scoresList = [10, 20, 30];
    }

    final chosen = scoresList[_random.nextInt(scoresList.length)];
    _targetScore = chosen > 0 ? chosen : 10;
  }

  void _setupNewGameRound() {
    _pickRandomTargetScore();
    _movesLeft = 5;
    _score = 0;
    _isGameOver = false;
    _isGameWon = false;
    _currentLane = 0;
    _ninjaLaneX = 0.0;
    _isJumping = false;
    _jumpY = 0.0;
    _jumpVy = 0.0;
    _runStep = 0.0;
    _roadScrollZ = 0.0;
    _invulnerableTimer = 0;
    _shakeTimer = 0;
    _roadEntities.clear();
    _spawnCounter = 0;
    _nextSpawnInterval = 40;
  }

  void _startGame() {
    final verifier = ref.read(diamondCatchVerifierProvider(widget.userId)).value;
    if (verifier != null && verifier.gameEligible == false) {
      CustomToast.showToast(context, msg: 'Today game limit over, come tomorrow!');
      return;
    }
    AnalyticsService.logCustomEvent('ninja_runner_game_started');
    _triggerHaptic(HapticFeedbackType.medium);
    _setupNewGameRound();

    setState(() {
      _gameStarted = true;
      _isCountingDown = true;
      _countdownNumber = 3;
    });

    _countdownAnimController.forward(from: 0.0);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_gameStarted) {
        timer.cancel();
        return;
      }

      if (_countdownNumber > 1) {
        setState(() {
          _countdownNumber--;
        });
        _triggerHaptic(HapticFeedbackType.light);
        _countdownAnimController.forward(from: 0.0);
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _triggerHaptic(HapticFeedbackType.heavy);
      }
    });
  }

  // ==========================================
  // 4. TEMPLE RUN / SUBWAY SURFERS CONTROLS
  // ==========================================

  void _changeLane(int direction) {
    if (_isGameOver || _isGameWon || _isCountingDown || !_gameStarted) return;
    final int nextLane = (_currentLane + direction).clamp(-1, 1);
    if (nextLane != _currentLane) {
      _currentLane = nextLane;
      _triggerHaptic(HapticFeedbackType.light);
      if (mounted) setState(() {});
    }
  }

  void _jump() {
    if (_isGameOver || _isGameWon || _isCountingDown || !_gameStarted) return;
    if (!_isJumping) {
      _isJumping = true;
      _jumpVy = 13.5;
      _triggerHaptic(HapticFeedbackType.light);
      if (mounted) setState(() {});
    }
  }

  void _triggerHaptic(HapticFeedbackType type) {
    if (!_isVibrateOn) return;
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  // ==========================================
  // 5. VICTORY & GAME OVER HANDLERS
  // ==========================================

  void _onGameWon() {
    for (int i = 0; i < 45; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 3.0 + _random.nextDouble() * 9.0;
      _sparks.add(
        _SparkParticle(
          x: 0.5.sw,
          y: 0.4.sh,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 2.0,
          color: _neonPalette[_random.nextInt(_neonPalette.length)],
          size: 5.0,
        ),
      );
    }
    _showResultPopup(isWin: true);
  }

  void _onGameOver() {
    _showResultPopup(isWin: false);
  }

  void _showResultPopup({required bool isWin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameResultPopup(
        isWin: isWin,
        score: _score,
        stars: isWin ? 3 : 1,
        gameGems: widget.gameGems,
        installGems: widget.installGems,
        dailyGems: 0,
        dailyGemsForInstall: widget.dailyGemsForInstall,
        isInstallTask: false,
        onResume: !isWin
            ? () {
                setState(() {
                  _movesLeft = max(_movesLeft, 0) + 5;
                  _isGameOver = false;
                  _gameStarted = true;
                  _invulnerableTimer = 45;
                });
              }
            : null,
        onRestart: () {
          setState(() {
            _setupNewGameRound();
            _gameStarted = false;
          });
        },
        onHome: () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // ==========================================
  // 6. PARTICLES & VISUAL EFFECTS
  // ==========================================

  static const List<Color> _neonPalette = [
    Color(0xFF38BDF8),
    Color(0xFF818CF8),
    Color(0xFFA855F7),
    Color(0xFFC084FC),
    Color(0xFFE879F9),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
  ];

  static const List<Color> _diamondShatterPalette = [
    Color(0xFF38BDF8),
    Color(0xFFE0F2FE),
    Color(0xFF7DD3FC),
    Color(0xFFFFD700),
    Color(0xFFFFFFFF),
  ];

  void _spawnDiamondShatterSparks(double originX, double originY) {
    if (_sparks.length > 30) return;
    for (int i = 0; i < 10; i++) {
      final angle = (_random.nextDouble() - 0.5) * 2 * pi;
      final speed = 3.5 + _random.nextDouble() * 6.5;
      _sparks.add(
        _SparkParticle(
          x: originX,
          y: originY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: _diamondShatterPalette[_random.nextInt(_diamondShatterPalette.length)],
          size: 3.5 + _random.nextDouble() * 3.0,
        ),
      );
    }
  }

  void _spawnCatchSparks(double originX, double originY, Color color) {
    if (_sparks.length > 25) return;
    for (int i = 0; i < 8; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 1.5;
      final speed = 3.5 + _random.nextDouble() * 5.5;
      _sparks.add(
        _SparkParticle(
          x: originX,
          y: originY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
          size: 4.5,
        ),
      );
    }
  }

  void _spawnCatchScore(double originX, double originY, String text, Color color) {
    if (_floatingScores.length > 5) return;
    _floatingScores.add(
      _FloatingScore(
        x: originX,
        y: originY - 15,
        text: text,
        color: color,
      ),
    );
  }

  // ==========================================
  // 7. ROAD RUNNER GAME LOOP (PERSPECTIVE 3D)
  // ==========================================

  void _updateGameFrame() {
    if (!mounted) return;

    bool stateChanged = false;

    // 1. Update sparks
    for (int i = _sparks.length - 1; i >= 0; i--) {
      final s = _sparks[i];
      s.x += s.vx;
      s.y += s.vy;
      s.vy += 0.22;
      s.life -= 0.045;
      if (s.life <= 0) {
        _sparks.removeAt(i);
      }
    }

    // 2. Update floating score texts
    for (int i = _floatingScores.length - 1; i >= 0; i--) {
      final f = _floatingScores[i];
      f.y -= 1.0;
      f.life -= 0.038;
      f.opacity = (f.life * 1.5).clamp(0.0, 1.0);
      if (f.life <= 0) {
        _floatingScores.removeAt(i);
      }
    }

    // 3. Road Runner Gameplay Frame
    if (_gameStarted && !_isCountingDown && !_isGameOver && !_isGameWon) {
      stateChanged = true;

      _runStep += 1.0;
      _roadScrollZ = (_roadScrollZ + 0.04) % 1.0;

      // Smooth lane switching interpolation (Subway Surfers feel)
      _ninjaLaneX += (_currentLane - _ninjaLaneX) * 0.24;

      // Jump Physics
      if (_isJumping) {
        _jumpY += _jumpVy;
        _jumpVy -= 0.85; // Gravity
        if (_jumpY <= 0.0) {
          _jumpY = 0.0;
          _jumpVy = 0.0;
          _isJumping = false;
          _triggerHaptic(HapticFeedbackType.light);
        }
      }

      if (_invulnerableTimer > 0) _invulnerableTimer--;
      if (_shakeTimer > 0) _shakeTimer--;

      // Spawning road entities (Coins, Gems, Hurdles)
      _spawnCounter++;
      if (_spawnCounter >= _nextSpawnInterval) {
        _spawnCounter = 0;
        _nextSpawnInterval = 38 + _random.nextInt(26);

        final int patternRoll = _random.nextInt(100);

        if (patternRoll < 35) {
          // Pattern A: Hurdle on one lane + Coins on another lane
          final int hurdleLane = _random.nextInt(3) - 1;
          _roadEntities.add(_RoadEntity(
            lane: hurdleLane,
            z: 0.0,
            type: RoadEntityType.hurdle,
          ));
          final int coinLane = (hurdleLane == 0) ? (_random.nextBool() ? 1 : -1) : 0;
          _roadEntities.add(_RoadEntity(
            lane: coinLane,
            z: 0.0,
            type: RoadEntityType.coin,
            points: 5,
          ));
        } else if (patternRoll < 65) {
          // Pattern B: Arc of 2 Coins on center or side lane
          final int coinLane = _random.nextInt(3) - 1;
          _roadEntities.add(_RoadEntity(
            lane: coinLane,
            z: 0.0,
            type: RoadEntityType.coin,
            points: 5,
          ));
          _roadEntities.add(_RoadEntity(
            lane: coinLane,
            z: -0.18, // slightly behind for streaming line of coins
            type: RoadEntityType.coin,
            points: 5,
          ));
        } else if (patternRoll < 85) {
          // Pattern C: Rare High Gem (+10) on a random lane
          final int gemLane = _random.nextInt(3) - 1;
          _roadEntities.add(_RoadEntity(
            lane: gemLane,
            z: 0.0,
            type: RoadEntityType.gem,
            points: 10,
          ));
        } else {
          // Pattern D: Dual Hurdles on 2 lanes (Must find the 1 open lane or jump!)
          final int openLane = _random.nextInt(3) - 1;
          for (int l = -1; l <= 1; l++) {
            if (l != openLane) {
              _roadEntities.add(_RoadEntity(
                lane: l,
                z: 0.0,
                type: RoadEntityType.hurdle,
              ));
            }
          }
          _roadEntities.add(_RoadEntity(
            lane: openLane,
            z: 0.0,
            type: RoadEntityType.coin,
            points: 5,
          ));
        }
      }

      // Advance Road Entities & Collision Check
      for (int i = _roadEntities.length - 1; i >= 0; i--) {
        final entity = _roadEntities[i];
        entity.z += _roadSpeed;

        // Collision Zone: When entity reaches near the player's plane (z in [0.82, 0.98])
        if (!entity.isCollected && !entity.hasHit) {
          if (entity.z >= 0.82 && entity.z <= 0.98) {
            final double laneDistance = (entity.lane - _ninjaLaneX).abs();
            if (laneDistance < 0.48) {
              final double screenMidX = 0.5.sw;
              final double entityScreenX = screenMidX + entity.lane * 110.w;
              final double entityScreenY = 0.76.sh;

              if (entity.type == RoadEntityType.coin) {
                entity.isCollected = true;
                _score += entity.points;
                _triggerHaptic(HapticFeedbackType.light);
                _spawnCatchSparks(entityScreenX, entityScreenY, const Color(0xFFFFD700));
                _spawnCatchScore(entityScreenX, entityScreenY, "+${entity.points}", const Color(0xFFFFE082));

                if (_score >= _targetScore) {
                  _isGameWon = true;
                  _onGameWon();
                }
              } else if (entity.type == RoadEntityType.gem) {
                entity.isCollected = true;
                _score += entity.points;
                _triggerHaptic(HapticFeedbackType.light);
                _spawnDiamondShatterSparks(entityScreenX, entityScreenY);
                _spawnCatchScore(entityScreenX, entityScreenY, "+${entity.points}", const Color(0xFF38BDF8));

                if (_score >= _targetScore) {
                  _isGameWon = true;
                  _onGameWon();
                }
              } else if (entity.type == RoadEntityType.hurdle) {
                // If player is jumping high enough, they successfully LEAP over the hurdle!
                if (_jumpY > 26.h) {
                  // Leaped over hurdle!
                  entity.hasHit = true;
                  _spawnCatchSparks(entityScreenX, entityScreenY, const Color(0xFF4ADE80));
                } else if (_invulnerableTimer <= 0) {
                  // Hurdle impact!
                  entity.hasHit = true;
                  _movesLeft--;
                  _invulnerableTimer = 45;
                  _shakeTimer = 9;
                  _triggerHaptic(HapticFeedbackType.heavy);
                  _spawnCatchSparks(entityScreenX, entityScreenY, const Color(0xFFFF3333));
                  _spawnCatchScore(entityScreenX, entityScreenY, "-1 CHANCE", const Color(0xFFFF4D4D));

                  if (_movesLeft <= 0) {
                    _isGameOver = true;
                    _onGameOver();
                  }
                }
              }
            }
          }
        }

        // Remove entity once it passes behind the player
        if (entity.z > 1.25) {
          _roadEntities.removeAt(i);
        }
      }
    }

    if (stateChanged && mounted) {
      setState(() {});
    }
  }

  // ==========================================
  // 8. BUILD UI WIDGETS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final String currentUid = widget.userId.isNotEmpty
        ? widget.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    final userGemsAsync = currentUid.isNotEmpty
        ? ref.watch(DashboardService.userGemsProvider(currentUid))
        : null;
    final int userGems = userGemsAsync?.value ?? widget.gemsRequired;

    return PopScope(
      canPop: !_gameStarted && !_isCountingDown,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _gameStarted && !_isCountingDown) {
          setState(() {
            _gameStarted = false;
          });
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            children: [
              // 1. Japanese Pagoda Sunset Background (assets/icons_2/ninja_runner_bg.jpg)
              Positioned.fill(
                child: Image.asset(
                  'assets/icons_2/ninja_runner_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. Safe Area Foreground
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(userGems),
                    Expanded(
                      child: _gameStarted
                          ? _build3DGameBoard()
                          : _buildStartScreen(userGems),
                    ),
                  ],
                ),
              ),

              // 3. Particle FX Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticleOverlayPainter(
                      sparks: _sparks,
                      floatingScores: _floatingScores,
                    ),
                  ),
                ),
              ),

              // 4. 100% Fullscreen 3D Cartoon 3-2-1 Countdown Overlay
              if (_isCountingDown)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Center(
                        child: ScaleTransition(
                          scale: _countdownScaleAnim,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '$_countdownNumber',
                                style: GoogleFonts.fredoka(
                                  fontSize: 130.sp,
                                  fontWeight: FontWeight.w900,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 16
                                    ..color = const Color(0xFF3E1C03),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFFFE082),
                                    Color(0xFFFFB300),
                                    Color(0xFFE65100),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds),
                                child: Text(
                                  '$_countdownNumber',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 130.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int userGems) {
    if (_gameStarted) return SizedBox(height: 6.h);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PopScaleButton(
            onTap: () {
              _triggerHaptic(HapticFeedbackType.light);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF87171),
                    Color(0xFFEF4444),
                    Color(0xFFB91C1C),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: const Color(0xFF81C784),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/gems.png',
                  width: 24.w,
                  height: 24.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$userGems',
                  style: GoogleFonts.fredoka(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 9. 3D TEMPLE RUN / SUBWAY SURFERS BOARD
  // ==========================================

  Widget _build3DGameBoard() {
    final double targetProgress = (_score / _targetScore).clamp(0.0, 1.0);
    final double shakeOffset = _shakeTimer > 0 ? (_random.nextDouble() - 0.5) * 8.0 : 0.0;

    return Transform.translate(
      offset: Offset(shakeOffset, 0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            SizedBox(height: 4.h),

            // 3D Cartoon Wooden HUD Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6E370F),
                    Color(0xFF8B4513),
                    Color(0xFF532809),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _PopScaleButton(
                        onTap: () {
                          if (_isCountingDown) return;
                          _triggerHaptic(HapticFeedbackType.light);
                          setState(() {
                            _gameStarted = false;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 6.w),
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF87171),
                                Color(0xFFEF4444),
                                Color(0xFFB91C1C),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 1.8,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHudStat(
                              label: 'TARGET SCORE',
                              value: '$_score / $_targetScore',
                              color: const Color(0xFFFFD700),
                              icon: Icons.emoji_events_rounded,
                            ),
                            _buildHudStat(
                              label: 'CHANCE',
                              value: '$_movesLeft',
                              color: _movesLeft <= 1
                                  ? const Color(0xFFFF4D4D)
                                  : const Color(0xFF4ADE80),
                              icon: Icons.favorite_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C1607),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: const Color(0xFF8B4513),
                        width: 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        height: 9.h,
                        color: const Color(0xFF1E0E04),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            widthFactor: targetProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFEF08A),
                                    Color(0xFFBEF264),
                                    Color(0xFF22C55E),
                                    Color(0xFF15803D),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // 3D Perspective Road Play Area with Swipe Support
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double h = constraints.maxHeight;

                  final double horizonY = h * 0.22;
                  final double roadTopWidth = w * 0.28;
                  final double roadBottomWidth = w * 0.94;
                  final double playerY = h * 0.78;

                  // Mascot coordinates
                  final double ninjaX = (w / 2) + (_ninjaLaneX * (roadBottomWidth / 3) * 0.94);
                  final double ninjaY = playerY - _jumpY;
                  final double shadowWidth = (52.w * (1.0 - (_jumpY / 120.0)).clamp(0.35, 1.0));
                  final double shadowOpacity = (0.45 * (1.0 - (_jumpY / 120.0)).clamp(0.15, 0.45));

                  // Ninja dynamic tilt during lane transitions
                  final double ninjaTilt = (_currentLane - _ninjaLaneX) * 0.32;
                  final bool isFlashing = _invulnerableTimer > 0 && (_invulnerableTimer % 6 < 3);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanEnd: (details) {
                      final dx = details.velocity.pixelsPerSecond.dx;
                      final dy = details.velocity.pixelsPerSecond.dy;

                      if (dy < -250) {
                        // Swipe Up -> Jump!
                        _jump();
                      } else if (dx < -180) {
                        // Swipe Left -> Move Left Lane
                        _changeLane(-1);
                      } else if (dx > 180) {
                        // Swipe Right -> Move Right Lane
                        _changeLane(1);
                      }
                    },
                    onTapUp: (details) {
                      final tapX = details.localPosition.dx;
                      if (tapX < w * 0.35) {
                        _changeLane(-1);
                      } else if (tapX > w * 0.65) {
                        _changeLane(1);
                      } else {
                        _jump();
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Perspective 3-Lane Road Canvas
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PerspectiveRoadPainter(
                              horizonY: horizonY,
                              topWidth: roadTopWidth,
                              bottomWidth: roadBottomWidth,
                              scrollZ: _roadScrollZ,
                            ),
                          ),
                        ),

                        // 2. Road Entities (Coins, Gems, Hurdles) sorted from back to front
                        for (final entity in _roadEntities)
                          if (!entity.isCollected && entity.z >= 0.0 && entity.z <= 1.15)
                            _buildProjectedEntity(entity, w, horizonY, playerY, roadTopWidth, roadBottomWidth),

                        // 3. Ninja Road Shadow
                        Positioned(
                          left: ninjaX - shadowWidth / 2,
                          top: playerY + 36.h,
                          child: Container(
                            width: shadowWidth,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: shadowOpacity),
                              borderRadius: BorderRadius.all(Radius.elliptical(shadowWidth, 12.h)),
                            ),
                          ),
                        ),

                        // 4. Hero Mascot: Battle Ninja
                        Positioned(
                          left: ninjaX - 38.w,
                          top: ninjaY - 38.w + sin(_runStep * 0.35) * 3.5.h,
                          child: Opacity(
                            opacity: isFlashing ? 0.35 : 1.0,
                            child: Transform.rotate(
                              angle: ninjaTilt,
                              child: Image.asset(
                                'assets/icons_2/Battle ninja.png',
                                width: 76.w,
                                height: 76.w,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/icons/loginicon.png',
                                  width: 76.w,
                                  height: 76.w,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5. Initial Swipe Guide
                        if (_score == 0)
                          Positioned(
                            top: 8.h,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swipe_rounded, color: const Color(0xFFFFD700), size: 14.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Swipe ◀ ▶ to change lane • Swipe ▲ to Jump!',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 6.h),

            // On-Screen 3D Arcade Control Buttons (Left | Jump | Right)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Lane Button
                  Expanded(
                    child: _PopScaleButton(
                      onTap: () => _changeLane(-1),
                      child: _buildArcadeControlButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'LEFT',
                        gradientColors: [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
                        borderColor: const Color(0xFFBAE6FD),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Jump Button
                  Expanded(
                    flex: 1,
                    child: _PopScaleButton(
                      onTap: _jump,
                      child: _buildArcadeControlButton(
                        icon: Icons.arrow_upward_rounded,
                        label: 'JUMP',
                        gradientColors: [const Color(0xFFFFD54F), const Color(0xFFEA580C)],
                        borderColor: const Color(0xFFFED7AA),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Right Lane Button
                  Expanded(
                    child: _PopScaleButton(
                      onTap: () => _changeLane(1),
                      child: _buildArcadeControlButton(
                        icon: Icons.arrow_forward_rounded,
                        label: 'RIGHT',
                        gradientColors: [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
                        borderColor: const Color(0xFFBAE6FD),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  Widget _buildArcadeControlButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectedEntity(
    _RoadEntity entity,
    double areaWidth,
    double horizonY,
    double playerY,
    double roadTopWidth,
    double roadBottomWidth,
  ) {
    final double z = entity.z.clamp(0.0, 1.15);
    final double scale = (0.26 + z * 0.74).clamp(0.25, 1.1);

    // Quadratic perspective projection curve
    final double y = horizonY + (playerY - horizonY) * (z * z * 1.05);
    final double roadW = roadTopWidth + (roadBottomWidth - roadTopWidth) * z;
    final double laneWidth = roadW / 3;
    final double x = (areaWidth / 2) + (entity.lane * laneWidth);

    final double baseSize = (entity.type == RoadEntityType.hurdle ? 44.w : 38.w);
    final double renderSize = baseSize * scale;

    Widget content;
    switch (entity.type) {
      case RoadEntityType.coin:
        content = Image.asset(
          'assets/icons_2/coin.png',
          width: renderSize,
          height: renderSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.monetization_on_rounded,
            color: const Color(0xFFFFD700),
            size: renderSize,
          ),
        );
        break;

      case RoadEntityType.gem:
        content = Image.asset(
          'assets/icons/gems.png',
          width: renderSize,
          height: renderSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.diamond_rounded,
            color: const Color(0xFF38BDF8),
            size: renderSize,
          ),
        );
        break;

      case RoadEntityType.hurdle:
        content = Container(
          width: renderSize * 1.25,
          height: renderSize * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5E3C), Color(0xFF4A2810)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6.r * scale),
            border: Border.all(
              color: const Color(0xFFFFCC80),
              width: 1.5 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6 * scale,
                offset: Offset(0, 3 * scale),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '⚠️',
              style: TextStyle(fontSize: 16.sp * scale),
            ),
          ),
        );
        break;
    }

    return Positioned(
      left: x - (renderSize / 2),
      top: y - (renderSize / 2),
      child: content,
    );
  }

  Widget _buildHudStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 4.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 10. START SCREEN
  // ==========================================

  Widget _buildStartScreen(int userGems) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _startScreenEntranceController,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: _startScreenEntranceController,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.black, Colors.transparent],
                          stops: [0.0, 0.55, 0.95],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        'assets/icons_2/Battle ninja.png',
                        width: 200.w,
                        height: 200.w,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/icons/gems.png',
                          width: 150.w,
                          height: 150.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'NINJA RUNNER',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          height: 1.1,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 6.5
                            ..color = const Color(0xFF3E1C03),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFFF176),
                            Color(0xFFFFB300),
                            Color(0xFFFB8C00),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.35, 0.75, 1.0],
                        ).createShader(bounds),
                        child: Text(
                          'NINJA RUNNER',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.0,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF795548), Color(0xFF4E342E)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'SWIPE LANES • JUMP HURDLES • WIN GEMS',
                  style: GoogleFonts.fredoka(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFECB3),
                    letterSpacing: 0.7,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Rules Card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRulePill(
                      icon: '💎',
                      label: '+10 Gem',
                      color: const Color(0xFF38BDF8),
                    ),
                    _buildRulePill(
                      icon: '🪙',
                      label: '+5 Coin',
                      color: const Color(0xFFFFD700),
                    ),
                    _buildRulePill(
                      icon: '⚠️',
                      label: 'Jump Hurdle',
                      color: const Color(0xFFFF6B6B),
                    ),
                    _buildRulePill(
                      icon: '◀ ▶',
                      label: '3 Lanes',
                      color: const Color(0xFF4ADE80),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 22.h),

              // GIANT 3D Arcade Play Button
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _PopScaleButton(
                    onTap: () {
                      _triggerHaptic(HapticFeedbackType.medium);
                      _startGame();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF86EFAC),
                            Color(0xFF22C55E),
                            Color(0xFF16A34A),
                            Color(0xFF15803D),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.25, 0.70, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFFDCFCE7),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF15803D).withValues(alpha: 0.8),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: const Color(0xFF15803D),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'PLAY NOW',
                              maxLines: 1,
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulePill({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 18.sp)),
        SizedBox(height: 3.h),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 11. PERSPECTIVE 3-LANE ROAD PAINTER
// ==========================================

class _PerspectiveRoadPainter extends CustomPainter {
  final double horizonY;
  final double topWidth;
  final double bottomWidth;
  final double scrollZ;

  _PerspectiveRoadPainter({
    required this.horizonY,
    required this.topWidth,
    required this.bottomWidth,
    required this.scrollZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midX = size.width / 2;
    final double bottomY = size.height;

    // 1. Draw Road Base Trapezoid (Subway Surfers / Temple Run 3-lane road)
    final roadPath = Path()
      ..moveTo(midX - topWidth / 2, horizonY)
      ..lineTo(midX + topWidth / 2, horizonY)
      ..lineTo(midX + bottomWidth / 2, bottomY)
      ..lineTo(midX - bottomWidth / 2, bottomY)
      ..close();

    final roadPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF1E293B), // Dark slate near horizon
          Color(0xFF0F172A), // Deep navy asphalt
          Color(0xFF020617), // Road foreground
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, bottomY - horizonY));
    canvas.drawPath(roadPath, roadPaint);

    // 2. Neon Golden Side Curbs
    final curbPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // Left curb
    canvas.drawLine(
      Offset(midX - topWidth / 2, horizonY),
      Offset(midX - bottomWidth / 2, bottomY),
      curbPaint,
    );
    // Right curb
    canvas.drawLine(
      Offset(midX + topWidth / 2, horizonY),
      Offset(midX + bottomWidth / 2, bottomY),
      curbPaint,
    );

    // 3. Streaming Horizontal Cross-Ties (Creates depth & forward speed sensation!)
    final tiePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 2.0;

    for (int i = 0; i < 9; i++) {
      final double z = (i / 9.0 + scrollZ) % 1.0;
      final double y = horizonY + (bottomY - horizonY) * (z * z);
      final double w = topWidth + (bottomWidth - topWidth) * z;
      canvas.drawLine(
        Offset(midX - w / 2, y),
        Offset(midX + w / 2, y),
        tiePaint,
      );
    }

    // 4. Two Dashed Lane Dividers (Splits road into Left, Center, Right lanes)
    final laneDividerPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.70)
      ..strokeWidth = 2.5;

    for (int l = -1; l <= 1; l += 2) {
      for (int i = 0; i < 8; i++) {
        final double z1 = (i / 8.0 + scrollZ) % 1.0;
        final double z2 = (z1 + 0.055).clamp(0.0, 1.0);

        final double y1 = horizonY + (bottomY - horizonY) * (z1 * z1);
        final double y2 = horizonY + (bottomY - horizonY) * (z2 * z2);

        final double w1 = topWidth + (bottomWidth - topWidth) * z1;
        final double w2 = topWidth + (bottomWidth - topWidth) * z2;

        final double laneX1 = midX + (l * (w1 / 6));
        final double laneX2 = midX + (l * (w2 / 6));

        canvas.drawLine(Offset(laneX1, y1), Offset(laneX2, y2), laneDividerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PerspectiveRoadPainter oldDelegate) => true;
}

class _ParticleOverlayPainter extends CustomPainter {
  final List<_SparkParticle> sparks;
  final List<_FloatingScore> floatingScores;

  _ParticleOverlayPainter({
    required this.sparks,
    required this.floatingScores,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: (s.life * 1.5).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(s.x, s.y), s.size * s.life, paint);
    }

    for (final f in floatingScores) {
      final textSpan = TextSpan(
        text: f.text,
        style: GoogleFonts.fredoka(
          fontSize: 16.sp,
          fontWeight: FontWeight.w900,
          color: f.color.withValues(alpha: f.opacity),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
      textPainter.paint(
        canvas,
        Offset(f.x - textPainter.width / 2, f.y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PopScaleButton extends StatefulWidget {
  const _PopScaleButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PopScaleButton> createState() => _PopScaleButtonState();
}

class _PopScaleButtonState extends State<_PopScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOutBack,
        child: widget.child,
      ),
    );
  }
}
