import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../services/local_storage.dart';
import '../../../../../utils/helper/helper.dart';
import '../../../../../utils/routes/routes_import.gr.dart';
import '../../../../../widgets/common/internet_image.dart';
import '../../../../b_splash_stage/splash_service.dart';

class HomeCustomBalanceHeader extends StatelessWidget {
  const HomeCustomBalanceHeader({
    super.key,
    required this.coins,
    required this.gems,
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.country,
    required this.isGuest,
    required this.currentIndex,
  });

  final double coins;
  final int gems;
  final String userId;
  final String name;
  final String photoUrl;
  final String country;
  final bool isGuest;
  final ValueNotifier<int> currentIndex;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final cardHeight = 250.5.h;
    final ellipseTop = topPadding + 88.h;
    final ellipseSize = 209.w;
    final orbitWidth = 237.w;
    final orbitHeight = 237.w;
    final orbitTop = ellipseTop - ((orbitHeight - ellipseSize) / 2);
    final totalWidgetHeight = orbitTop + orbitHeight + 12.h;

    return SizedBox(
      width: double.infinity,
      height: totalWidgetHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. MAIN CARD BACKGROUND (Rectangle 61 (3).png)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: cardHeight,
            child: Image.asset(
              'assets/icons_2/Rectangle 61 (3).png',
              fit: BoxFit.fill,
              width: double.infinity,
              height: cardHeight,
            ),
          ),

          // 2. DASHED CIRCLE ORBIT (Behind Center Ellipse)
          Positioned(
            top: orbitTop,
            child: IgnorePointer(
              child: SizedBox(
                width: orbitWidth,
                height: orbitHeight,
                child: CustomPaint(
                  painter: _DashedCirclePainter(
                    color: const Color(0xFF6346CA).withValues(alpha: 0.45),
                    strokeWidth: 1.5,
                    dashWidth: 6,
                    dashSpace: 5,
                  ),
                ),
              ),
            ),
          ),

          // 3. CENTER ROUND CARD (Ellipse 67 (1).png) - Half inside, half outside card
          Positioned(
            top: ellipseTop,
            child: SizedBox(
              width: ellipseSize,
              height: ellipseSize,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Image.asset(
                    'assets/icons_2/Ellipse 67 (1).png',
                    width: ellipseSize,
                    height: ellipseSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF362187),
                            const Color(0xFF362187).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 13.h,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your Balance',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          NumberFormat('#,##0').format(coins),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Value in Currency (≈ ₹0.00)
                        Builder(
                          builder: (context) {
                            final rate = SplashService.coinConversionRate > 0
                                ? SplashService.coinConversionRate
                                : 150;
                            final valueText = (coins / rate).toStringAsFixed(2);
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h, bottom: 4.h),
                              child: Text(
                                '≈ ₹$valueText',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF34D399),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            );
                          },
                        ),
                        // Gems Balance under Coins Balance
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            AutoRouter.of(context).push(
                              SuperOfferScreenRoute(userId: userId),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.5.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/gems.png',
                                  width: 14.w,
                                  height: 14.w,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.diamond_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 14,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${NumberFormat('#,##0').format(gems)} Gems',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. LEFT BUTTON: REVERSE WITHDRAWAL (Ellipse 69 + hugeicons_reverse-withdrawal-02 (1).png)
          Positioned(
            left: 12.w,
            top: cardHeight - 68.h,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                AutoRouter.of(context).push(
                  RedeemScreenRoute(
                    userId: userId,
                    country: country,
                    isGuest: isGuest,
                  ),
                );
              },
              child: SizedBox(
                width: 42.w,
                height: 42.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/icons_2/Ellipse 69.png',
                      width: 42.w,
                      height: 42.w,
                      fit: BoxFit.contain,
                    ),
                    Image.asset(
                      'assets/icons_2/hugeicons_reverse-withdrawal-02 (1).png',
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. RIGHT BUTTON: HISTORY (Ellipse 69 + boxicons_history.png)
          Positioned(
            right: 12.w,
            top: cardHeight - 68.h,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                AutoRouter.of(context).push(
                  RedeemHistoryScreenRoute(
                    userId: userId,
                  ),
                );
              },
              child: SizedBox(
                width: 42.w,
                height: 42.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/icons_2/Ellipse 69.png',
                      width: 42.w,
                      height: 42.w,
                      fit: BoxFit.contain,
                    ),
                    Image.asset(
                      'assets/icons_2/boxicons_history.png',
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. TOP HEADER ROW: USER PROFILE + NOTIFICATION BELL
          Positioned(
            top: topPadding + 10.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Profile Capsule + Greeting
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => currentIndex.value = 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // White capsule containing Avatar + Hamburger lines
                      Container(
                        height: 42.h,
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34.w,
                              height: 34.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2C1C6C),
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? AvatarInternetImage(
                                        url: photoUrl,
                                        size: 34.w,
                                        borderWidth: 0,
                                        borderColor: Colors.transparent,
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16.w,
                                  height: 2.2.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C1C6C),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Container(
                                  width: 16.w,
                                  height: 2.2.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C1C6C),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Container(
                                  width: 16.w,
                                  height: 2.2.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C1C6C),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 6.w),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // "Hi, \n{name}"
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hi,',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 130.w),
                            child: Text(
                              name.isNotEmpty ? name : 'User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Notification Bell Button (Polygon 2.png + iconoir_bell-notification-solid.png)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await AutoRouter.of(context).push(const NotificationScreenRoute());
                    LocalStorage.hasUnreadNotificationNotifier.value = LocalStorage.hasUnreadNotifications();
                  },
                  child: SizedBox(
                    width: 42.w,
                    height: 42.w,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          'assets/icons_2/Polygon 2.png',
                          width: 42.w,
                          height: 42.w,
                          fit: BoxFit.contain,
                        ),
                        Image.asset(
                          'assets/icons_2/iconoir_bell-notification-solid.png',
                          width: 20.w,
                          height: 20.w,
                          color: Colors.white,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: LocalStorage.hasUnreadNotificationNotifier,
                          builder: (context, hasUnread, _) {
                            if (!hasUnread) return const SizedBox.shrink();
                            return Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 7. BOTTOM "VIEW WALLET" PILL BUTTON (Half above and half below main card bottom)
          Positioned(
            top: cardHeight - 20.h,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                AutoRouter.of(context).push(
                  RedeemScreenRoute(
                    userId: userId,
                    country: country,
                    isGuest: isGuest,
                  ),
                );
              },
              child: SizedBox(
                width: 146.w,
                height: 40.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/icons_2/Rectangle 60.png',
                      width: 146.w,
                      height: 40.h,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1052),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                    ),
                    Text(
                      'View Wallet',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
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
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final a = (size.width - strokeWidth) / 2;
    final b = (size.height - strokeWidth) / 2;
    final h = a == b ? 0.0 : math.pow(a - b, 2) / math.pow(a + b, 2);
    final circumference = a == b
        ? 2 * math.pi * a
        : math.pi * (a + b) * (1 + (3 * h) / (10 + math.sqrt(4 - 3 * h)));

    final count = (circumference / (dashWidth + dashSpace)).floor();
    final sweepAngle = (dashWidth / circumference) * 2 * math.pi;
    final spaceAngle = (dashSpace / circumference) * 2 * math.pi;

    for (int i = 0; i < count; i++) {
      final startAngle = i * (sweepAngle + spaceAngle);
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
