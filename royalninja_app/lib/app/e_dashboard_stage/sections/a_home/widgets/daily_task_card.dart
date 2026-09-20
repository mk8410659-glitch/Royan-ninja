import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/helper/helper.dart';
import '../../../../../utils/routes/routes_import.gr.dart';
import '../../../../../widgets/common/custom_loading.dart';
import '../../../../../widgets/common/internet_image.dart';
import '../../../../../widgets/common/shimmer_tag.dart';
import '../daily_task/daily_task_model.dart';
import '../../../../b_splash_stage/splash_service.dart';

class HomeDailyTaskSection extends HookConsumerWidget {
  const HomeDailyTaskSection({
    super.key,
    required this.offers,
    required this.userId,
    required this.email,
    required this.country,
  });

  final List<DailyTaskModel> offers;
  final String userId;
  final String email;
  final String country;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingId = useState<String?>(null);
    final randomLeftIndex = useState<int>(0);
    final randomRightIndex = useState<int>(offers.length > 1 ? 1 : 0);

    useEffect(() {
      if (offers.length <= 1) return null;
      final timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
        if (!context.mounted) return;
        final rng = math.Random();
        final newLeft = rng.nextInt(offers.length);
        final newRight = (newLeft + 1 + rng.nextInt(offers.length - 1)) % offers.length;
        randomLeftIndex.value = newLeft;
        randomRightIndex.value = newRight;
      });
      return timer.cancel;
    }, [offers.length]);

    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    final leftItem = offers[randomLeftIndex.value % offers.length];
    final rightItem = offers[randomRightIndex.value % offers.length];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row (Figma Style Gradient Capsule on Left + View All on Right)
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 148.w,
                  height: 31.h,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 14.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.2874, 0.9995],
                      colors: [
                        Color(0xFF362187),
                        Color(0x00362187),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    SplashService.dailyTaskTitle.isNotEmpty && SplashService.dailyTaskTitle != 'Daily Task'
                        ? SplashService.dailyTaskTitle
                        : 'Hot Offers',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AutoRouter.of(context).push(
                        DailyTaskScreenRoute(
                          userId: userId,
                          email: email,
                          country: country,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFF2B1055).withValues(alpha: 0.18),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B1055).withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2B1055),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF2B1055),
                            size: 9.5.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Both Cards Side by Side (Auto-scaled with Expanded to prevent any overflow)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                // Left Card: Yellow Theme (Spider-Man / Random offer with Claim button)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _HomeDailyTaskItemCard(
                      key: ValueKey('left_${leftItem.offerId}'),
                      item: leftItem,
                      isPurpleTheme: false,
                      isLoading: loadingId.value == leftItem.offerId,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await AutoRouter.of(context).push(
                          DailyTaskDetailsScreenRoute(
                            item: leftItem,
                            cardColor: leftItem.color,
                            userId: userId,
                            email: email,
                            country: country,
                            heroTag: 'left_task_${leftItem.offerId}',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Right Card: Blue Theme (Hot Offers with View All button)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _HomeDailyTaskItemCard(
                      key: ValueKey('right_${rightItem.offerId}'),
                      item: rightItem,
                      isPurpleTheme: true,
                      customTitle: 'Hot Offers',
                      isViewAllButton: true,
                      isLoading: false,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await AutoRouter.of(context).push(
                          DailyTaskScreenRoute(
                            userId: userId,
                            email: email,
                            country: country,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowLightingSpinner extends StatefulWidget {
  final double size;
  final List<Color> colors;

  const _GlowLightingSpinner({
    this.size = 15.0,
    required this.colors,
  });

  @override
  State<_GlowLightingSpinner> createState() => _GlowLightingSpinnerState();
}

class _GlowLightingSpinnerState extends State<_GlowLightingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: SizedBox(
            width: widget.size.w,
            height: widget.size.w,
            child: CustomPaint(
              painter: _GlowSpinnerPainter(colors: widget.colors),
            ),
          ),
        );
      },
    );
  }
}

class _GlowSpinnerPainter extends CustomPainter {
  final List<Color> colors;

  _GlowSpinnerPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4.0) / 2;
    const startAngle = 0.0;
    const sweepAngle = 4.4;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = colors.last.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [
        colors.last.withValues(alpha: 0.0),
        colors.length > 1 ? colors[1].withValues(alpha: 0.4) : colors.last.withValues(alpha: 0.4),
        colors.length > 2 ? colors[2] : colors.last,
        colors.last,
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 2.6
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    final headAngle = startAngle + sweepAngle;
    final headPoint = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );

    final outerGlowPaint = Paint()
      ..color = colors.last.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(headPoint, 4.2, outerGlowPaint);

    final innerGlowPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(headPoint, 2.6, innerGlowPaint);

    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headPoint, 1.8, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TicketPatternPainter extends CustomPainter {
  const _TicketPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Origin exactly at the right boundary of the green side (touching the center split)
    final origin = Offset(size.width, size.height * 0.05);

    // Primary waves fanning out from the right divider edge all the way to the left side
    for (int i = 0; i < 15; i++) {
      final path = Path();
      path.moveTo(origin.dx, origin.dy);

      final controlX = size.width * (0.1 + i * 0.06);
      final controlY = size.height * (0.95 - i * 0.05);
      final endX = size.width * (0.0 - i * 0.03);
      final endY = size.height * (0.2 + i * 0.06);

      path.quadraticBezierTo(controlX, controlY, endX, endY);
      canvas.drawPath(path, paint);
    }

    // Secondary waves flowing from left edge (0) and ending exactly on the right divider edge (size.width)
    for (int i = 0; i < 8; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.3 + i * 0.08));

      final controlX1 = size.width * 0.3;
      final controlY1 = size.height * (0.1 - i * 0.03);
      final controlX2 = size.width * 0.7;
      final controlY2 = size.height * (0.95 - i * 0.04);
      final endX = size.width; // Touches the center split exactly
      final endY = size.height * (0.25 + i * 0.06);

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, endX, endY);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HotSpecialOfferCard extends StatelessWidget {
  const _HotSpecialOfferCard({
    required this.item,
    required this.onTap,
    this.isLoading = false,
    this.heroTag,
  });

  final DailyTaskModel item;
  final VoidCallback onTap;
  final bool isLoading;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imagePath.isNotEmpty ? item.imagePath : item.bannerPath;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFF9333EA).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Row(
            children: [
              // Left Section (Purple Gradient)
              Expanded(
                flex: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7E10C8),
                        Color(0xFF3B0764),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: const _TicketPatternPainter(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Tag Row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: const Color(0xFFF472B6),
                                  size: 13.sp,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  item.offerCategory.isNotEmpty
                                      ? item.offerCategory.toUpperCase()
                                      : 'TASK',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFF472B6),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Title
                            Text(
                              item.offerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            // Subtext
                            Text(
                              item.cleanSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 8.5.sp,
                                height: 1.15,
                              ),
                            ),
                            // Button
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDB2777).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Start',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Image.asset(
                                          'assets/icons/coin.png',
                                          height: 14.sp,
                                          width: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          item.coins.formatCoins(),
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Section
              Expanded(
                flex: 8,
                child: Container(
                  color: const Color(0xFF1E1B4B),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 55.w,
                        height: 55.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: InternetImage(
                          url: imageUrl,
                          fit: BoxFit.cover,
                          width: 50.w,
                          height: 50.w,
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
    );
  }
}

class _ShimmeringHotOfferText extends StatefulWidget {
  const _ShimmeringHotOfferText();

  @override
  State<_ShimmeringHotOfferText> createState() => _ShimmeringHotOfferTextState();
}

class _ShimmeringHotOfferTextState extends State<_ShimmeringHotOfferText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double value = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(value * 3.6 - 1.8, 0),
              end: Alignment(value * 3.6 - 0.6, 0),
              colors: const [
                Color(0xFF9333EA),
                Color(0xFFC084FC),
                Color(0xFFF472B6),
                Color(0xFFC084FC),
                Color(0xFF9333EA),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            'Special Offers',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class DailyTaskHorizontalCard extends StatelessWidget {
  const DailyTaskHorizontalCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isLoading = false,
    this.heroTag,
  });

  final DailyTaskModel item;
  final VoidCallback onTap;
  final bool isLoading;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final isHighPaying = item.coins >= 300;
    final tagGradient = isHighPaying
        ? const LinearGradient(
            colors: [Color(0xFFFFF1C5), Color(0xFFFFD54F)], // Light Gold
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFF81C784)], // Soft Mint/Green
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    final tagText = isHighPaying ? 'High Reward' : 'New Offer';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 135.h,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Custom Painted Ticket background
            LayoutBuilder(
              builder: (context, constraints) {
                final clipX = constraints.maxWidth - 82.w;
                final ticketRadius = 10.r;
                final rrectRadius = 16.r;
                return SizedBox(
                  width: constraints.maxWidth,
                  height: 120.h,
                  child: Stack(
                    children: [
                      // 1. Ticket background and shadow
                      CustomPaint(
                        size: Size(constraints.maxWidth, 120.h),
                        painter: TicketPainter(
                          clipX: clipX,
                          radius: ticketRadius,
                        ),
                      ),
                      // 2. Subtle Rotating Sunburst Rays (Clipped to ticket shape)
                      Positioned.fill(
                        child: ClipPath(
                          clipper: TicketClipper(
                            clipX: clipX,
                            radius: ticketRadius,
                            rrectRadius: rrectRadius,
                          ),
                          child: RotatingSunburst(
                            rayColor: const Color(0xFFD3A32D).withValues(alpha: 0.1), // Subtle gold rays
                          ),
                        ),
                      ),
                      // 3. Foreground content
                      SizedBox(
                        width: constraints.maxWidth,
                        height: 120.h,
                        child: Row(
                          children: [
                            // Left Section: Main Ticket Body
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 14.w,
                                  right: 12.w,
                                  top: 12.h,
                                  bottom: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    // Logo
                                    Container(
                                      width: 52.w,
                                      height: 52.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14.r),
                                        child: InternetImage(
                                          url: item.imagePath,
                                          width: 52.w,
                                          height: 52.w,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    // Text details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.offerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: const Color(0xFF1E1C24),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13.sp,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(height: 3.h),
                                          Text(
                                            item.cleanSubtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: const Color(0xFF6B6675),
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item.trackingTime > 0) ...[
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_filled_rounded,
                                                  size: 10.sp,
                                                  color: const Color(0xFFFF5252),
                                                ),
                                                SizedBox(width: 3.w),
                                                Text(
                                                  '${item.trackingTime} mins',
                                                  style: TextStyle(
                                                    color: const Color(0xFFFF5252),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 9.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Right Section: Ticket Stub (Coin reward pill)
                            Container(
                              width: 92.w,
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: Container(
                                  width: 82.w,
                                  height: 35.h,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF9C487), // Lighter gold/brown
                                        Color(0xFFD68A2E), // Base Leaderboard brown
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD68A2E).withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isLoading
                                      ? const Center(
                                          child: GlowLightingSpinner(size: 14),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icons/coin.png',
                                              height: 15.sp,
                                              width: 15.sp,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              item.coins.formatCoins(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Floating Status Badge on top left
            Positioned(
              top: 2.h,
              left: 12.w,
              child: FlippingTag(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    gradient: tagGradient,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: (isHighPaying
                                ? const Color(0xFFFF8F00)
                                : const Color(0xFF81C784))
                            .withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHighPaying
                            ? Icons.local_fire_department_rounded
                            : Icons.star_rounded,
                        color: isHighPaying
                            ? const Color(0xFF7B5B00)
                            : const Color(0xFF2E7D32),
                        size: 9.sp,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        tagText,
                        style: TextStyle(
                          color: isHighPaying
                              ? const Color(0xFF7B5B00)
                              : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w900,
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyTaskGridCard extends StatelessWidget {
  const DailyTaskGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isLoading = false,
    this.heroTag,
  });

  final DailyTaskModel item;
  final VoidCallback onTap;
  final bool isLoading;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final isHighPaying = item.coins >= 300;
    final tagGradient = isHighPaying
        ? const LinearGradient(
            colors: [Color(0xFFFFF1C5), Color(0xFFFFD54F)], // Light Gold
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFECEC), Color(0xFFFF8A8A)], // Soft Pink/Coral
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFFDFD), // Cream White
              Color(0xFFFFF3F0), // Soft Peach
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A59).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              // Ambient glow spots peaking from behind in grid style
              Positioned(
                right: -25.w,
                bottom: -25.h,
                child: Container(
                  width: 70.w,
                  height: 70.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF8A65).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -25.w,
                top: -25.h,
                child: Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD54F).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Card contents layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Logo & Status Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Logo inside soft-shadow card (no border)
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: InternetImage(
                            url: item.imagePath,
                            width: 40.w,
                            height: 40.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      // Status Tag (New / High)
                      FlippingTag(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            gradient: tagGradient,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHighPaying ? Icons.local_fire_department_rounded : Icons.star_rounded,
                                color: isHighPaying ? const Color(0xFF7B5B00) : const Color(0xFFC62828),
                                size: 9.sp,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                isHighPaying ? 'High' : 'New',
                                style: TextStyle(
                                  color: isHighPaying ? const Color(0xFF7B5B00) : const Color(0xFFC62828),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 8.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Middle Section: Task texts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.offerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1E1C24), // High-contrast charcoal text
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        item.cleanSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF6B6675), // Readable grey-brown text
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom Section: Centered Premium Coin button (No Install category tag)
                  ShimmerTag(
                    type: ShimmerType.shining,
                    blendMode: BlendMode.srcATop,
                    baseColor: Colors.transparent,
                    highlightColor: Colors.white.withValues(alpha: 0.45),
                    child: Container(
                      width: double.infinity,
                      height: 33.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFC107), // Glossy Amber Gold
                            Color(0xFFFF8F00),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8F00).withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isLoading
                          ? const Center(
                              child: GlowLightingSpinner(size: 14),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/coin.png',
                                  height: 15.sp,
                                  width: 15.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  item.coins.formatCoins(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class TicketPainter extends CustomPainter {
  final double clipX;
  final double radius;

  TicketPainter({
    required this.clipX,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrectRadius = 16.r;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFFDF5),
        Color(0xFFFFF9E6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);

    final borderPaint = Paint()
      ..color = const Color(0xFFD3A32D).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, rrectRadius)
      // Top-left rounded corner
      ..quadraticBezierTo(0, 0, rrectRadius, 0)
      // Top line to cutout
      ..lineTo(clipX - radius, 0)
      // Top cutout (concave semi-circle going inwards)
      ..arcToPoint(
        Offset(clipX + radius, 0),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      // Top line to top-right corner
      ..lineTo(size.width - rrectRadius, 0)
      // Top-right corner
      ..quadraticBezierTo(size.width, 0, size.width, rrectRadius)
      // Right line to bottom-right corner
      ..lineTo(size.width, size.height - rrectRadius)
      // Bottom-right corner
      ..quadraticBezierTo(size.width, size.height, size.width - rrectRadius, size.height)
      // Bottom line to bottom cutout
      ..lineTo(clipX + radius, size.height)
      // Bottom cutout (concave semi-circle going inwards)
      ..arcToPoint(
        Offset(clipX - radius, size.height),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      // Bottom line to bottom-left corner
      ..lineTo(rrectRadius, size.height)
      // Bottom-left corner
      ..quadraticBezierTo(0, size.height, 0, size.height - rrectRadius)
      ..close();

    // Draw shadow
    canvas.drawShadow(
      path,
      const Color(0xFFD68A2E).withValues(alpha: 0.12),
      4.0,
      true,
    );

    // Draw ticket background
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Draw dashed vertical divider
    final dashPaint = Paint()
      ..color = const Color(0xFFD3A32D).withValues(alpha: 0.25) // Soft Watch gold divider
      ..strokeWidth = 1.2.w
      ..style = PaintingStyle.stroke;

    double startY = radius + 6.h;
    final endY = size.height - radius - 6.h;
    final dashHeight = 4.h;
    final dashSpace = 4.h;

    while (startY < endY) {
      canvas.drawLine(
        Offset(clipX, startY),
        Offset(clipX, startY + dashHeight),
        dashPaint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TicketPainter oldDelegate) {
    return oldDelegate.clipX != clipX || oldDelegate.radius != radius;
  }
}

class FlippingTag extends StatefulWidget {
  final Widget child;
  const FlippingTag({super.key, required this.child});

  @override
  State<FlippingTag> createState() => _FlippingTagState();
}

class _FlippingTagState extends State<FlippingTag> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 seconds total cycle
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Spin a full 360 degrees (2 * pi) in the last 0.8 seconds (20% of 4-sec duration)
        final double value = _controller.value;
        double angle = 0.0;
        if (value > 0.8) {
          final double t = (value - 0.8) / 0.2; // normalize to 0.0 -> 1.0
          final double curveT = Curves.easeInOutCubic.transform(t);
          angle = curveT * 2 * math.pi;
        }

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // 3D Perspective
            ..rotateY(angle),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  final double clipX;
  final double radius;
  final double rrectRadius;

  TicketClipper({
    required this.clipX,
    required this.radius,
    required this.rrectRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, rrectRadius)
      ..quadraticBezierTo(0, 0, rrectRadius, 0)
      ..lineTo(clipX - radius, 0)
      ..arcToPoint(
        Offset(clipX + radius, 0),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(size.width - rrectRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, rrectRadius)
      ..lineTo(size.width, size.height - rrectRadius)
      ..quadraticBezierTo(size.width, size.height, size.width - rrectRadius, size.height)
      ..lineTo(clipX + radius, size.height)
      ..arcToPoint(
        Offset(clipX - radius, size.height),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(rrectRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - rrectRadius)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant TicketClipper oldClipper) {
    return oldClipper.clipX != clipX || oldClipper.radius != radius || oldClipper.rrectRadius != rrectRadius;
  }
}

class SunburstPainter extends CustomPainter {
  final double rotationAngle;
  final Color rayColor;

  SunburstPainter({
    required this.rotationAngle,
    required this.rayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.sqrt(size.width * size.width + size.height * size.height);
    
    final paint = Paint()
      ..color = rayColor
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    const int numRays = 16;
    final double angleStep = 2 * math.pi / numRays;
    final double halfRayWidth = angleStep / 4; // ray occupies 50% of its step sector

    for (int i = 0; i < numRays; i++) {
      final double rayAngle = i * angleStep;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(radius * math.cos(rayAngle - halfRayWidth), radius * math.sin(rayAngle - halfRayWidth))
        ..lineTo(radius * math.cos(rayAngle + halfRayWidth), radius * math.sin(rayAngle + halfRayWidth))
        ..close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SunburstPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle || oldDelegate.rayColor != rayColor;
  }
}

class RotatingSunburst extends StatefulWidget {
  final Color rayColor;
  const RotatingSunburst({
    super.key,
    required this.rayColor,
  });

  @override
  State<RotatingSunburst> createState() => _RotatingSunburstState();
}

class _RotatingSunburstState extends State<RotatingSunburst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25), // slow, premium rotation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: SunburstPainter(
            rotationAngle: _controller.value * 2 * math.pi,
            rayColor: widget.rayColor,
          ),
        );
      },
    );
  }
}

class ArcadeCardClipper extends CustomClipper<Path> {
  const ArcadeCardClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final double r = 16.0; // corner radius
    final double arcR = 10.0; // bottom center arc height
    final double arcW = 38.0; // bottom center arc width

    // Start top-left
    path.moveTo(0, r);
    // Left corner rounds to y=10
    path.quadraticBezierTo(0, 10, 10, 10);
    // Smooth notch curving up to y=0
    path.cubicTo(16, 10, 18, 0, 26, 0);
    // Top tab line
    path.lineTo(size.width - 26, 0);
    // Smooth notch curving down to y=10
    path.cubicTo(size.width - 18, 0, size.width - 16, 10, size.width - 10, 10);
    // Right corner rounds down to y=r
    path.quadraticBezierTo(size.width, 10, size.width, r);

    // Right edge
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);

    // Bottom edge with a flat-topped smooth arch cut-out in the middle
    final double centerX = size.width / 2;
    path.lineTo(centerX + arcW / 2, size.height);
    
    // Smooth cubic bezier arch cutout
    path.cubicTo(
      centerX + arcW / 3,
      size.height - arcR,
      centerX - arcW / 3,
      size.height - arcR,
      centerX - arcW / 2,
      size.height,
    );

    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ArcadeCardBorderPainter extends CustomPainter {
  const ArcadeCardBorderPainter({required this.borderColor});
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final double r = 16.0;
    final double arcR = 10.0;
    final double arcW = 38.0;

    path.moveTo(0, r);
    // Left corner rounds to y=10
    path.quadraticBezierTo(0, 10, 10, 10);
    // Smooth notch curving up to y=0
    path.cubicTo(16, 10, 18, 0, 26, 0);
    // Top tab line
    path.lineTo(size.width - 26, 0);
    // Smooth notch curving down to y=10
    path.cubicTo(size.width - 18, 0, size.width - 16, 10, size.width - 10, 10);
    // Right corner rounds down to y=r
    path.quadraticBezierTo(size.width, 10, size.width, r);

    // Right edge
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);

    // Bottom edge with a flat-topped smooth arch cut-out in the middle
    final double centerX = size.width / 2;
    path.lineTo(centerX + arcW / 2, size.height);
    path.cubicTo(
      centerX + arcW / 3,
      size.height - arcR,
      centerX - arcW / 3,
      size.height - arcR,
      centerX - arcW / 2,
      size.height,
    );

    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.close();

    // Draw glowing border paint that fades from top to bottom
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          borderColor,
          borderColor.withValues(alpha: 0.6),
          borderColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.70],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TaperedCardPainter extends CustomPainter {
  const _TaperedCardPainter({
    this.taper = 14.0,
    this.radius = 38.0,
  });

  final double taper;
  final double radius;

  Path getCardPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = radius;
    final t = taper;

    // Top-left start
    path.moveTo(r, 0);
    // Top edge with subtle convex arch
    path.quadraticBezierTo(w / 2, -1.5, w - r, 0);
    // Top-right rounded corner
    path.quadraticBezierTo(w, 0, w, r);
    // Right side gently tapering down to (w - t, h - r)
    path.cubicTo(
      w - (t * 0.15), h * 0.40,
      w - (t * 0.75), h * 0.78,
      w - t, h - r,
    );
    // Bottom-right rounded corner (deep curve)
    path.quadraticBezierTo(w - t, h, w - t - r, h);
    // Bottom edge with smooth convex bowl curve matching screenshot
    path.quadraticBezierTo(w / 2, h + 6.0, t + r, h);
    // Bottom-left rounded corner (deep curve)
    path.quadraticBezierTo(t, h, t, h - r);
    // Left side gently tapering up to (0, r)
    path.cubicTo(
      t * 0.75, h * 0.78,
      t * 0.15, h * 0.40,
      0, r,
    );
    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = getCardPath(size);

    // Draw shadow first
    canvas.drawShadow(
      path,
      const Color(0xFF7640FE).withValues(alpha: 0.08),
      6.0,
      true,
    );

    // Draw solid white background
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawPath(path, paint);

    // Draw subtle purple border stroke
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF7640FE).withValues(alpha: 0.15);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeDailyTaskItemCard extends StatelessWidget {
  const _HomeDailyTaskItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isLoading = false,
    this.isPurpleTheme = false,
    this.customTitle,
    this.isViewAllButton = false,
  });

  final DailyTaskModel item;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isPurpleTheme;
  final String? customTitle;
  final bool isViewAllButton;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imagePath.trim().isNotEmpty
        ? item.imagePath.trim()
        : (item.bannerPath.trim().isNotEmpty ? item.bannerPath.trim() : '');

    const Color yellowColor = Color(0xFFFFF100); // Figma exact #FFF100
    const Color purpleColor = Color(0xFF362187); // Figma exact #362187

    return _PopScaleButton(
      onTap: onTap,
      scaleDown: 0.95,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final cardHeight = 172.h;
          final uperCardWidth = cardWidth * (141.52 / 158.39);
          final rightStripWidth = cardWidth - uperCardWidth;

          return SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Base Main Card: fills cardWidth x cardHeight, radius 21.77px (#362187)
                // Left Card (Yellow Theme) -> #362187 base
                // Right Card (Blue Theme) -> #FFF100 base
                Positioned(
                  left: 0,
                  top: 0,
                  width: cardWidth,
                  height: cardHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21.77.r),
                    child: isPurpleTheme
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(yellowColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 62.png',
                              fit: BoxFit.fill,
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(purpleColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 62.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                  ),
                ),

                // 2. Right Vertical "HOT" Text positioned at bottom right space
                Positioned(
                  right: 2.w,
                  bottom: 22.h,
                  width: rightStripWidth + 4.w,
                  height: 58.h,
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.14,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'HOT',
                          style: GoogleFonts.poppins(
                            color: isPurpleTheme ? purpleColor : yellowColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Front Card (Middle Layer): uperCardWidth x cardHeight, radius 21.77px (#FFF100)
                // Left Card (Yellow Theme) -> #FFF100 front
                // Right Card (Blue Theme) -> #362187 front
                Positioned(
                  left: 0,
                  top: 0,
                  width: uperCardWidth,
                  height: cardHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21.77.r),
                    child: isPurpleTheme
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(purpleColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 63.png',
                              fit: BoxFit.fill,
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(yellowColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 63.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                  ),
                ),

                // 4. Top White Frame (Top Layer): Frame 27.png inside uper card
                Positioned(
                  left: 6.w,
                  top: 7.h,
                  width: (uperCardWidth - 12.w).clamp(0.0, double.infinity),
                  height: 65.h,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/icons_2/Frame 27.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: imageUrl.isNotEmpty
                                ? InternetImage(
                                    url: imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.white,
                                    child: Center(
                                      child: Icon(
                                        Icons.sports_esports_rounded,
                                        color: purpleColor,
                                        size: 28.sp,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Card Body Content (Below Frame 27, within uperCardWidth)
                Positioned(
                  left: 4.w,
                  width: (uperCardWidth - 8.w).clamp(0.0, double.infinity),
                  top: 76.h,
                  bottom: 6.h,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Offer Title
                      Text(
                        customTitle ?? item.offerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isPurpleTheme ? yellowColor : purpleColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.05,
                        ),
                      ),

                      // Subtitle / Description
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          item.cleanSubtitle.isNotEmpty
                              ? item.cleanSubtitle
                              : 'Play coin master and build your own village',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: isPurpleTheme
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF5B4300),
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.05,
                          ),
                        ),
                      ),

                      // Win Upto Coins Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Win upto ${item.coins.toInt()}',
                            style: GoogleFonts.poppins(
                              color: isPurpleTheme ? Colors.white : purpleColor,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Image.asset(
                            'assets/icons/coin.png',
                            width: 11.w,
                            height: 11.w,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.monetization_on_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 11.sp,
                            ),
                          ),
                        ],
                      ),

                      // Claim / View All Button
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: isPurpleTheme ? yellowColor : purpleColor,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: (isPurpleTheme ? yellowColor : purpleColor).withValues(alpha: 0.35),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 10.w,
                                height: 10.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isPurpleTheme ? purpleColor : yellowColor,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isViewAllButton && !isPurpleTheme) ...[
                                    Icon(
                                      Icons.card_giftcard_rounded,
                                      color: yellowColor,
                                      size: 9.5.sp,
                                    ),
                                    SizedBox(width: 3.w),
                                  ],
                                  Text(
                                    isViewAllButton ? 'View All' : 'Claim',
                                    style: GoogleFonts.poppins(
                                      color: isPurpleTheme ? purpleColor : yellowColor,
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class _PopScaleButton extends StatefulWidget {
  const _PopScaleButton({
    required this.onTap,
    required this.child,
    this.scaleDown = 0.92,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scaleDown;

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
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOutBack,
        child: widget.child,
      ),
    );
  }
}

