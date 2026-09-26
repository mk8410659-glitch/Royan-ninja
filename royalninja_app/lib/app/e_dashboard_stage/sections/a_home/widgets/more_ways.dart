// ignore_for_file: unused_element_parameter
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../utils/routes/routes_import.gr.dart';
import '../../../../../widgets/common/custom_status_popup.dart';
import '../../../../b_splash_stage/splash_service.dart';

class MoreWaysSection extends StatelessWidget {
  const MoreWaysSection({
    super.key,
    required this.userId,
    required this.email,
    required this.country,
    required this.currentIndex,
  });

  final String userId;
  final String email;
  final String country;
  final ValueNotifier<int> currentIndex;

  @override
  Widget build(BuildContext context) {
    final bool hideRead = SplashService.isScreenHidden('readAndEarn') || SplashService.isScreenHidden('readTask');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "More Ways" Capsule: Rectangle 85.png
        Padding(
          padding: EdgeInsets.only(top: 10.h, bottom: 12.h),
          child: Row(
            children: [
              SizedBox(
                width: 148.w,
                height: 31.h,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Image.asset(
                      'assets/icons_2/Rectangle 85.png',
                      width: 148.w,
                      height: 31.h,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 14.w),
                      child: Text(
                        'More Ways',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Vertical List of Horizontal Banner Cards matching Demo Image
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              // 1. Quick Reads (Read Task)
              if (!hideRead) ...[
                _buildListItemCard(
                  context: context,
                  title: 'Read Articles',
                  subtitle: 'Read articles & earn coins',
                  leftWidget: _buildReadArticleLeftIcon(),
                  rightWidget: _buildReadArticleRightGraphic(),
                  themeColor: const Color(0xFF6366F1), // Royal Indigo
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (!SplashService.isScreenEnabled('readTask') && !SplashService.isScreenEnabled('readAndEarn')) {
                      CustomStatusPopup.showComingSoon(context: context);
                      return;
                    }
                    AutoRouter.of(context).push(
                      ReadTskScreenRoute(
                        userId: userId,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8.h),
              ],

              // 2. Invite Friends
              _buildListItemCard(
                context: context,
                title: 'Invite Friends',
                subtitle: 'Invite your friends & earn coins per referral!',
                leftWidget: _buildInviteFriendsLeftIcon(),
                rightWidget: _buildInviteFriendsRightGraphic(),
                themeColor: const Color(0xFF6366F1), // Matches Read Articles exactly
                onTap: () {
                  HapticFeedback.lightImpact();
                  currentIndex.value = 1;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Left Icon Badge for Read Articles (Frame 31.png with book (1).png on top)
  Widget _buildReadArticleLeftIcon() {
    return SizedBox(
      width: 52.w,
      height: 52.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/icons_2/Frame 31.png',
            width: 52.w,
            height: 52.w,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Image.asset(
                'assets/icons_2/book (1).png',
                width: 27.w,
                height: 27.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Side Graphic for Read Articles
  Widget _buildReadArticleRightGraphic() {
    return SizedBox(
      width: 64.w,
      height: 64.h,
      child: Center(
        child: Image.asset(
          'assets/icons_2/book (1).png',
          width: 50.w,
          height: 50.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Left Icon Badge for Invite Friends (Frame 31.png with invite.png on top)
  Widget _buildInviteFriendsLeftIcon() {
    return SizedBox(
      width: 52.w,
      height: 52.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/icons_2/Frame 31.png',
            width: 52.w,
            height: 52.w,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Image.asset(
                'assets/icons/invite.png',
                width: 27.w,
                height: 27.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Side Graphic for Invite Friends
  Widget _buildInviteFriendsRightGraphic() {
    return SizedBox(
      width: 64.w,
      height: 64.h,
      child: Center(
        child: Image.asset(
          'assets/icons/invite.png',
          width: 48.w,
          height: 48.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 1-to-1 Replica Card Layout from Reference Image
  Widget _buildListItemCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget leftWidget,
    required Widget rightWidget,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return _PopScaleButton(
      scaleDown: 0.97,
      onTap: onTap,
      child: Container(
        height: 76.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF362187),
              Color(0xFF0D0821),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D0821).withValues(alpha: 0.40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Stack(
            children: [
              // 1. Right Side Soft Dome Gradient Backdrop
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 95.w,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColor.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(45.r),
                      bottomLeft: Radius.circular(45.r),
                      topRight: Radius.circular(18.r),
                      bottomRight: Radius.circular(18.r),
                    ),
                  ),
                ),
              ),

              // 2. Right Side Graphic Artwork
              Positioned(
                right: 6.w,
                top: 6.h,
                bottom: 6.h,
                width: 64.w,
                child: Center(
                  child: rightWidget,
                ),
              ),

              // 3. Circular Arrow Action Button (Positioned cleanly without overlapping artwork)
              Positioned(
                right: 76.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Foreground Content (Left Icon + Middle Text) - No overflow guarantee
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(left: 12.w, right: 114.w, top: 8.h, bottom: 8.h),
                  child: Row(
                    children: [
                      leftWidget,
                      SizedBox(width: 10.w),

                      // Middle Text Column: Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w400,
                                height: 1.22,
                              ),
                            ),
                          ],
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

// Backward compatibility alias
typedef MoreWaysToEarnRewardsSection = MoreWaysSection;

class _PopScaleButton extends StatefulWidget {
  const _PopScaleButton({
    required this.onTap,
    required this.child,
    this.scaleDown = 0.94,
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
