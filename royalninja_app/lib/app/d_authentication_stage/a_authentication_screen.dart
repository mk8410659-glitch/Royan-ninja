// ignore_for_file: depend_on_referenced_packages
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/launch_url.dart';
import '../../widgets/common/custom_loading.dart';
import '../../widgets/common/custom_status_popup.dart';
import '../b_splash_stage/splash_service.dart';
import 'authentication_service.dart';

@RoutePage()
class AuthenticationScreen extends HookWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuestLoading = useState<bool>(false);
    final isGoogleLoading = useState<bool>(false);
    final isGooglePressed = useState<bool>(false);
    final isGuestPressed = useState<bool>(false);

    final termsRecognizer = useMemoized(() => TapGestureRecognizer()..onTap = () {
      LaunchUrl.inWeb(
        url: SplashService.urlConfig.termsOfService,
        context: context,
      );
    });
    final privacyRecognizer = useMemoized(() => TapGestureRecognizer()..onTap = () {
      LaunchUrl.inWeb(
        url: SplashService.urlConfig.privacyPolicy,
        context: context,
      );
    });

    useEffect(() {
      return () {
        termsRecognizer.dispose();
        privacyRecognizer.dispose();
      };
    }, [termsRecognizer, privacyRecognizer]);

    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          CustomStatusPopup.showAppExit(context: context);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: true,
          body: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Stack(
              children: [
                // 1. App Wallpaper Background (Fixed Fullscreen)
                Positioned(
                  left: 0,
                  top: 0,
                  width: screenSize.width,
                  height: screenSize.height,
                  child: Image.asset(
                    'assets/icons/Splash (2).png',
                    fit: BoxFit.cover,
                  ),
                ),


                // 3. Main Login Content
                Positioned.fill(
                  child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Hero Section: App Logo + Welcome Text + Subtitle
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: const _AuthSingleHeroSection(),
                          ),

                          SizedBox(height: 24.h),

                          // Authentication Header
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Row(
                              children: [
                                Container(
                                  width: 5.w,
                                  height: 20.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(3.r),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Authentication',
                                  style: GoogleFonts.russoOne(
                                    fontSize: 17.sp,
                                    color: const Color(0xFF1E1B4B),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Login Buttons Column
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              children: [
                              // 1. Google Login (Signature Royal Home Card Style)
                              Center(
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    isGooglePressed.value = true;
                                    HapticFeedback.lightImpact();
                                  },
                                  onTapUp: (_) async {
                                    isGooglePressed.value = false;
                                    if (isGoogleLoading.value || isGuestLoading.value) return;
                                    isGoogleLoading.value = true;
                                    try {
                                      await AuthenticationService.signInWithGoogle(context);
                                    } finally {
                                      isGoogleLoading.value = false;
                                    }
                                  },
                                  onTapCancel: () {
                                    isGooglePressed.value = false;
                                  },
                                  child: AnimatedScale(
                                    scale: isGooglePressed.value ? 0.96 : 1.0,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      width: 230.w,
                                      height: 52.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withValues(
                                              alpha: isGooglePressed.value ? 0.08 : 0.14,
                                            ),
                                            blurRadius: isGooglePressed.value ? 6 : 14,
                                            offset: Offset(0, isGooglePressed.value ? 2 : 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 16.w),
                                          if (isGoogleLoading.value) ...[
                                            const GlowLightingSpinner(
                                              size: 20,
                                              colors: [
                                                Color(0xFFA855F7),
                                                Color(0xFF7C3AED),
                                                Color(0xFF5B21B6),
                                                Color(0xFFA855F7),
                                              ],
                                            ),
                                          ] else ...[
                                            Image.asset(
                                              'assets/icons/google.png',
                                              height: 22.h,
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            'Google',
                                            style: GoogleFonts.russoOne(
                                              fontSize: 15.sp,
                                              color: const Color(0xFF1E1B4B),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 13.sp,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 16.w),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 14.h),

                              // 2. Guest Login (Signature Royal Home Card Style)
                              Center(
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    isGuestPressed.value = true;
                                    HapticFeedback.lightImpact();
                                  },
                                  onTapUp: (_) async {
                                    isGuestPressed.value = false;
                                    if (isGuestLoading.value || isGoogleLoading.value) return;
                                    isGuestLoading.value = true;
                                    try {
                                      await AuthenticationService.signInAnonymously(context);
                                    } finally {
                                      isGuestLoading.value = false;
                                    }
                                  },
                                  onTapCancel: () {
                                    isGuestPressed.value = false;
                                  },
                                  child: AnimatedScale(
                                    scale: isGuestPressed.value ? 0.96 : 1.0,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      width: 230.w,
                                      height: 52.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withValues(
                                              alpha: isGuestPressed.value ? 0.08 : 0.14,
                                            ),
                                            blurRadius: isGuestPressed.value ? 6 : 14,
                                            offset: Offset(0, isGuestPressed.value ? 2 : 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 16.w),
                                          if (isGuestLoading.value) ...[
                                            const GlowLightingSpinner(
                                              size: 20,
                                              colors: [
                                                Color(0xFFA855F7),
                                                Color(0xFF7C3AED),
                                                Color(0xFF5B21B6),
                                                Color(0xFFA855F7),
                                              ],
                                            ),
                                          ] else ...[
                                            Container(
                                              width: 26.w,
                                              height: 26.w,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEDE9FE),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.person_rounded,
                                                color: const Color(0xFF7C3AED),
                                                size: 16.sp,
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            'Guest',
                                            style: GoogleFonts.russoOne(
                                              fontSize: 15.sp,
                                              color: const Color(0xFF1E1B4B),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 13.sp,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 16.w),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 28.h),

                          // Contact Support & Disclosure Links
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                onTap: () => LaunchUrl.openSupportMail(
                                  context: context,
                                  subject: 'Login Problem - royal_ninja',
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${'problem-in-login'.tr()} ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'contact-us'.tr(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF7C3AED),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Small Terms / Privacy disclosure
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'By continuing, you agree to our ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5.sp,
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms',
                                        recognizer: termsRecognizer,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7C3AED),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                      const TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        recognizer: privacyRecognizer,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7C3AED),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
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
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _AuthSingleHeroSection extends StatelessWidget {
  const _AuthSingleHeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Centered Ninja Mascot Image
        Center(
          child: Image.asset(
            'assets/icons_2/Battle ninja.png',
            height: 140.h,
            fit: BoxFit.contain,
          ),
        ),

        SizedBox(height: 12.h),

        // Brand Gaming Title (Centered with Royal Violet Theme)
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF5B21B6),
              Color(0xFF7C3AED),
              Color(0xFF9333EA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'royal_ninja',
            textAlign: TextAlign.center,
            style: GoogleFonts.russoOne(
              fontSize: 28.sp,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // Centered Subtitle / Description
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Play exciting games, complete tasks, compete on the leaderboard, and have fun every day!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
