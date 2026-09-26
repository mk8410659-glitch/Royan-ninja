import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../services/launch_url.dart';
import '../../../../../widgets/common/custom_toast.dart';
import '../../../../../widgets/common/screen_banner_widget.dart';
import '../../../../b_splash_stage/splash_service.dart';
import 'model/offerwall_data_model.dart';
import 'provider/offerwall_manager.dart';
import 'provider/offerwall_provider.dart';

class OfferwallTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final String bgAsset;
  final double bgAssetSize;

  const OfferwallTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.bgAsset,
    this.bgAssetSize = 100,
  });
}

OfferwallTheme getOfferwallTheme(String name) {
  final cleanName = name.toLowerCase().replaceAll(' ', '').replaceAll('-', '').replaceAll('_', '');
  switch (cleanName) {
    case 'tapjoy':
      return const OfferwallTheme(
        primaryColor: Color(0xFFE22119),
        backgroundColor: Color(0xFFFDECE9),
        borderColor: Color(0xFFF88E6D),
        bgAsset: 'assets/icons/tapjoy-logo.png',
        bgAssetSize: 120,
      );
    case 'sushiads':
      return const OfferwallTheme(
        primaryColor: Color(0xFFFF3B30),
        backgroundColor: Color(0xFFFFF3E0),
        borderColor: Color(0xFFFF8A65),
        bgAsset: 'assets/icons/sushiads-logo.png',
        bgAssetSize: 130,
      );
    case 'notik':
    case 'notikme':
      return const OfferwallTheme(
        primaryColor: Color(0xFF009688),
        backgroundColor: Color(0xFFE0F2F1),
        borderColor: Color(0xFF4DB6AC),
        bgAsset: 'assets/icons/notik-logo.png',
        bgAssetSize: 120,
      );
    case 'cpidroid':
      return const OfferwallTheme(
        primaryColor: Color(0xFF689F38),
        backgroundColor: Color(0xFFF1F8E9),
        borderColor: Color(0xFF9CCC65),
        bgAsset: 'assets/icons/cpidroid-logo.png',
        bgAssetSize: 130,
      );
    case 'taskwall':
      return const OfferwallTheme(
        primaryColor: Color(0xFF007AFF),
        backgroundColor: Color(0xFFE1F5FE),
        borderColor: Color(0xFF64B5F6),
        bgAsset: 'assets/icons/taskwall-logo.png',
        bgAssetSize: 120,
      );
    case 'adjoe':
      return const OfferwallTheme(
        primaryColor: Color(0xFF5856D6),
        backgroundColor: Color(0xFFEDE7F6),
        borderColor: Color(0xFF9575CD),
        bgAsset: 'assets/icons/adjoe-logo.png',
        bgAssetSize: 160,
      );
    case 'pubscale':
      return const OfferwallTheme(
        primaryColor: Color(0xFF008080),
        backgroundColor: Color(0xFFE0F2F1),
        borderColor: Color(0xFF4DB6AC),
        bgAsset: 'assets/icons/pubscale-logo.png',
        bgAssetSize: 130,
      );
    case 'timewall':
      return const OfferwallTheme(
        primaryColor: Color(0xFF1565C0),
        backgroundColor: Color(0xFFE3F2FD),
        borderColor: Color(0xFF64B5F6),
        bgAsset: 'assets/icons/timewall-logo.png',
        bgAssetSize: 130,
      );
    case 'wannads':
      return const OfferwallTheme(
        primaryColor: Color(0xFFEF6C00),
        backgroundColor: Color(0xFFFFF3E0),
        borderColor: Color(0xFFFFB74D),
        bgAsset: 'assets/icons/wannads-logo.png',
        bgAssetSize: 130,
      );
    case 'bitlabs':
      return const OfferwallTheme(
        primaryColor: Color(0xFF0277BD),
        backgroundColor: Color(0xFFE1F5FE),
        borderColor: Color(0xFF4FC3F7),
        bgAsset: 'assets/icons/bitlabs-logo.png',
        bgAssetSize: 130,
      );
    case 'cpxresearch':
      return const OfferwallTheme(
        primaryColor: Color(0xFF0288D1),
        backgroundColor: Color(0xFFE1F5FE),
        borderColor: Color(0xFF4FC3F7),
        bgAsset: 'assets/icons/cpxresearch-logo.png',
        bgAssetSize: 130,
      );
    case 'lootably':
      return const OfferwallTheme(
        primaryColor: Color(0xFFC62828),
        backgroundColor: Color(0xFFFFEBEE),
        borderColor: Color(0xFFE57373),
        bgAsset: 'assets/icons/lootably-logo.png',
        bgAssetSize: 130,
      );
    case 'growdeck':
      return const OfferwallTheme(
        primaryColor: Color(0xFF37474F),
        backgroundColor: Color(0xFFECEFF1),
        borderColor: Color(0xFF90A4AE),
        bgAsset: 'assets/icons/growdeck-logo.png',
        bgAssetSize: 130,
      );
    case 'playtimeads':
      return const OfferwallTheme(
        primaryColor: Color(0xFF6A1B9A),
        backgroundColor: Color(0xFFF3E5F5),
        borderColor: Color(0xFFBA68C8),
        bgAsset: 'assets/icons/playtimeads-logo.png',
        bgAssetSize: 130,
      );
    case 'theoremreach':
      return const OfferwallTheme(
        primaryColor: Color(0xFF3F51B5),
        backgroundColor: Color(0xFFE8EAF6),
        borderColor: Color(0xFFC5CAE9),
        bgAsset: 'assets/icons/theoremreach-logo.png',
        bgAssetSize: 130,
      );
    default:
      return const OfferwallTheme(
        primaryColor: Color(0xFF38BDF8),
        backgroundColor: Color(0xFFFFF2EC),
        borderColor: Color(0xFF38BDF8),
        bgAsset: 'assets/icons/suprerofferdhn.png',
        bgAssetSize: 120,
      );
  }
}

String getOfferwallSubtitle(String name) {
  final clean = name.toLowerCase().replaceAll(' ', '').replaceAll('-', '').replaceAll('_', '');
  switch (clean) {
    case 'cpxresearch':
      return 'Answer surveys & earn instant rewards';
    case 'timewall':
      return 'Complete quick tasks & collect coins';
    case 'bitlabs':
      return 'Share your opinion & earn big coins';
    case 'pubscale':
      return 'Play new games and complete offers';
    case 'notik':
    case 'notikme':
      return 'Install apps & get instant rewards';
    case 'taskwall':
      return 'Complete easy tasks & earn daily coins';
    case 'sushiads':
      return 'Explore top games & earn rewards';
    case 'cpidroid':
      return 'Download apps & claim coin bonuses';
    case 'theoremreach':
      return 'High paying surveys with daily bonus';
    case 'wannads':
      return 'Browse exclusive apps & survey offers';
    case 'lootably':
      return 'Watch videos, surveys & exciting offers';
    case 'growdeck':
      return 'Complete quick quizzes & earn coins';
    case 'playtimeads':
    case 'playtime':
      return 'Play games every minute & earn coins';
    case 'tapjoy':
      return 'Unlock rewards with top game offers';
    default:
      return 'Complete offers & collect instant coins';
  }
}

@RoutePage()
class OfferwallScreen extends HookConsumerWidget {
  const OfferwallScreen({
    super.key,
    required this.userId,
    required this.offerwallList,
    required this.title,
    required this.email,
  });

  final String userId;
  final List<OfferwallProvider> offerwallList;
  final String title;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final topPadding = MediaQuery.of(context).padding.top;

    useEffect(() {
      Future.microtask(() {
        ref.invalidate(SplashService.appDataProvider);
      });
      return null;
    }, const []);

    ref.watch(SplashService.appDataProvider);

    final currentList = title.toLowerCase().contains('task')
        ? OfferwallManager.getOffersByCategory(category: OfferwallCategory.task)
        : OfferwallManager.getOffersByCategory(category: OfferwallCategory.survey);

    final isTaskScreen = title.toLowerCase().contains('task');
    final screenTitle = title.tr() == title
        ? (isTaskScreen ? 'Task Partners' : 'Survey Partners')
        : title.tr();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Solid Clean White Background
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),

            // 2. Main Feed
            Positioned.fill(
              child: Column(
                children: [
                  // Executive Top Header Bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      topPadding + 8.h,
                      16.w,
                      14.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Executive Back Arrow + Screen Title
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                AutoRouter.of(context).maybePop();
                              },
                              child: Container(
                                width: 40.w,
                                height: 40.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15.r),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF362187).withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: const Color(0xFF362187),
                                  size: 22.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),

                            Text(
                              screenTitle,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1E1B4B),
                                fontSize: 18.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),

                        // Right: Executive "How To?" Pill Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            LaunchUrl.inWeb(
                              url: isTaskScreen
                                  ? SplashService.getTutorialUrl('offerwall', SplashService.urlConfig.taskTutorial)
                                  : SplashService.getTutorialUrl('survey', SplashService.urlConfig.surveyTutorial),
                              context: context,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: const Color(0xFF5B34C4).withValues(alpha: 0.6),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF362187).withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  color: const Color(0xFF362187),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'How To?',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF362187),
                                    fontSize: 12.sp,
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

                  // Screen Banner (Admin Configurable 700x200 with AD badge)
                  const ScreenBannerWidget(
                    screenKey: 'offerwallScreen',
                    margin: EdgeInsets.only(left: 14, right: 14, bottom: 8),
                  ),

                  // 2 Cards Per Row Grid
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(SplashService.appDataProvider);
                        try {
                          await ref.read(SplashService.appDataProvider.future);
                        } catch (_) {}
                      },
                      color: const Color(0xFF362187),
                      backgroundColor: Colors.white,
                      child: GridView.builder(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 40.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14.h,
                          crossAxisSpacing: 10.w,
                          childAspectRatio: 0.93,
                        ),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final OfferwallProvider offerwall = currentList[index];
                          return OfferwallExecutiveCard(
                            offerwall: offerwall,
                            userId: userId,
                            email: email,
                            index: index,
                            isSurvey: !isTaskScreen,
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EXECUTIVE 2-CARD WIDE HORIZONTAL OFFERWALL CARD (HOT OFFERS RECTANGLE 62/63/FRAME 27 THEMED)
// -----------------------------------------------------------------------------
class OfferwallExecutiveCard extends HookWidget {
  const OfferwallExecutiveCard({
    super.key,
    required this.offerwall,
    required this.userId,
    required this.email,
    required this.index,
    required this.isSurvey,
  });

  final OfferwallProvider offerwall;
  final String userId;
  final String email;
  final int index;
  final bool isSurvey;

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    final theme = getOfferwallTheme(offerwall.name);
    final subtitle = getOfferwallSubtitle(offerwall.name);
    final isLocked = !offerwall.enabled;

    // Alternating Hot Offers Left/Right Theme:
    // Left card (index % 2 == 0): Yellow front (#FFF100), Purple base (#362187)
    // Right card (index % 2 == 1): Purple front (#362187), Yellow base (#FFF100)
    final bool isPurpleTheme = (index % 2 == 1);
    const Color yellowColor = Color(0xFFFFF100);
    const Color purpleColor = Color(0xFF362187);

    String displayName = offerwall.name;
    if (displayName.toLowerCase() == 'sushiads') {
      displayName = 'Sushi Ads';
    } else if (displayName.toLowerCase() == 'notik') {
      displayName = 'Notikme';
    } else if (displayName.toLowerCase() == 'cpidroid') {
      displayName = 'Cpi Droid';
    } else if (displayName.toLowerCase() == 'taskwall') {
      displayName = 'Task Wall';
    } else if (displayName.toLowerCase() == 'theoremreach') {
      displayName = 'Theorem Reach';
    } else if (displayName.toLowerCase() == 'cpxresearch') {
      displayName = 'CPX Research';
    } else if (displayName.toLowerCase() == 'timewall') {
      displayName = 'Timewall';
    } else if (displayName.toLowerCase() == 'bitlabs') {
      displayName = 'BitLabs';
    } else if (displayName.toLowerCase() == 'pubscale') {
      displayName = 'PubScale';
    }

    return GestureDetector(
      onTapDown: (_) {
        if (offerwall.enabled) {
          isPressed.value = true;
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) async {
        if (offerwall.enabled) {
          isPressed.value = false;
          HapticFeedback.lightImpact();
          await offerwall.show(
            context: context,
            userId: userId,
            email: email,
          );
        } else {
          HapticFeedback.vibrate();
          CustomToast.showToast(context, msg: 'offerwall-locked'.tr());
        }
      },
      onTapCancel: () {
        isPressed.value = false;
      },
      child: AnimatedScale(
        scale: isPressed.value ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = constraints.maxHeight;
            final uperCardWidth = cardWidth * (425.0 / 467.0);
            final rightStripWidth = cardWidth - uperCardWidth;

            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Base Main Card: Rectangle 62.png
                  Positioned(
                    left: 0,
                    top: 0,
                    width: cardWidth,
                    height: cardHeight,
                    child: isPurpleTheme
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(yellowColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 62.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(purpleColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 62.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
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
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Front Card (Middle Layer): Rectangle 63.png
                  Positioned(
                    left: 0,
                    top: 0,
                    width: uperCardWidth,
                    height: cardHeight,
                    child: isPurpleTheme
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(purpleColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 63.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(yellowColor, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/icons_2/Rectangle 63.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                  ),

                  // 4. Top White Frame (Top Layer): Frame 27.png
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
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Container(
                                color: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                child: Center(
                                  child: _buildPartnerLogo(offerwall, theme),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. Subtle Lock Indicator if locked
                  if (isLocked)
                    Positioned(
                      top: 10.h,
                      right: (cardWidth - uperCardWidth) + 9.w,
                      child: Container(
                        padding: EdgeInsets.all(3.5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 11.sp,
                        ),
                      ),
                    ),

                  // 6. Card Body Content (Below Frame 27, within uperCardWidth)
                  Positioned(
                    left: 4.w,
                    width: (uperCardWidth - 8.w).clamp(0.0, double.infinity),
                    top: 76.h,
                    bottom: 6.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Partner Name / Title
                        Text(
                          displayName,
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
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: isPurpleTheme
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF362187).withValues(alpha: 0.75),
                              fontSize: 7.5.sp,
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
                              'Win upto ',
                              style: GoogleFonts.poppins(
                                color: isPurpleTheme
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : purpleColor,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Coins',
                              style: GoogleFonts.poppins(
                                color: isPurpleTheme ? yellowColor : purpleColor,
                                fontSize: 9.5.sp,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Image.asset(
                              'assets/icons_2/coin.png',
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

                        // Action Button (Start / Locked)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isPurpleTheme
                                  ? (isLocked
                                      ? [const Color(0xFF64748B), const Color(0xFF475569)]
                                      : [const Color(0xFFFFEA79), const Color(0xFFFFB800)])
                                  : (isLocked
                                      ? [const Color(0xFF64748B), const Color(0xFF475569)]
                                      : [const Color(0xFF5B34C4), const Color(0xFF362187)]),
                            ),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isPurpleTheme
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isPurpleTheme
                                        ? (isLocked ? Colors.black26 : const Color(0xFFFF9E00))
                                        : (isLocked ? Colors.black26 : const Color(0xFF362187)))
                                    .withValues(alpha: 0.45),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLocked ? 'Locked' : 'Start',
                                style: GoogleFonts.poppins(
                                  color: isPurpleTheme && !isLocked
                                      ? const Color(0xFF24125C)
                                      : Colors.white,
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                isLocked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                                color: isPurpleTheme && !isLocked
                                    ? const Color(0xFF24125C)
                                    : Colors.white,
                                size: 11.sp,
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
      ),
    );
  }

  Widget _buildPartnerLogo(OfferwallProvider offerwall, OfferwallTheme theme) {
    final hasIconUrl = (offerwall.config?.iconUrl.isNotEmpty ?? false);
    if (hasIconUrl) {
      return Image.network(
        offerwall.config!.iconUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackLogo(offerwall, theme),
      );
    }
    return _buildFallbackLogo(offerwall, theme);
  }

  Widget _buildFallbackLogo(OfferwallProvider offerwall, OfferwallTheme theme) {
    return Image.asset(
      offerwall.logoImage,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        theme.bgAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_offer_rounded,
          color: const Color(0xFF362187),
          size: 26.sp,
        ),
      ),
    );
  }
}

