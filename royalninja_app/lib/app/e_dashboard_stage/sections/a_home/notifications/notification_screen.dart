import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

import '../../../../../services/local_storage.dart';
import '../../../../../widgets/common/custom_toast.dart';
import 'notification_model.dart';

final notificationsProvider = StateProvider.autoDispose<List<NotificationModel>>(
  (ref) => LocalStorage.getNotifications(),
);

@RoutePage()
class NotificationScreen extends HookConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final selectedCategory = useState<String>('all');

    // Collect all unique received notification types
    final receivedTypes = notifications
        .map((n) => n.type.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet();

    const allPossibleCategories = [
      {'key': 'all', 'label': 'All', 'icon': Icons.notifications_rounded},
      {'key': 'payment', 'label': 'Redeem', 'icon': Icons.account_balance_wallet_rounded},
      {'key': 'personal', 'label': 'Personal', 'icon': Icons.mail_rounded},
      {'key': 'support', 'label': 'Support', 'icon': Icons.headset_mic_rounded},
      {'key': 'service', 'label': 'Service', 'icon': Icons.work_rounded},
    ];

    // Build dynamically available categories based strictly on received notifications
    final availableCategories = <Map<String, dynamic>>[];
    if (notifications.isNotEmpty) {
      availableCategories.add(allPossibleCategories[0]); // 'all'

      for (int i = 1; i < allPossibleCategories.length; i++) {
        final cat = allPossibleCategories[i];
        if (receivedTypes.contains(cat['key'])) {
          availableCategories.add(cat);
        }
      }

      // Any dynamic type from backend not in predefined list
      final knownKeys = allPossibleCategories.map((c) => c['key']).toSet();
      for (final extraKey in receivedTypes) {
        if (!knownKeys.contains(extraKey)) {
          availableCategories.add({
            'key': extraKey,
            'label': extraKey[0].toUpperCase() + extraKey.substring(1),
            'icon': Icons.notifications_active_rounded,
          });
        }
      }
    }

    // Reset category if currently selected is no longer available
    useEffect(() {
      if (selectedCategory.value != 'all' && !receivedTypes.contains(selectedCategory.value.trim().toLowerCase())) {
        selectedCategory.value = 'all';
      }
      return null;
    }, [notifications]);

    final effectiveCategory = (selectedCategory.value != 'all' && !receivedTypes.contains(selectedCategory.value.trim().toLowerCase()))
        ? 'all'
        : selectedCategory.value;

    // Safely sync from local storage, mark all as read (clears unread red dot)
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        try {
          LocalStorage.markAllNotificationsAsRead();
          ref.read(notificationsProvider.notifier).state = LocalStorage.getNotifications();
        } catch (_) {}
      });
      return null;
    }, const []);

    // Filter notifications based on tab
    final filteredNotifications = notifications.where((n) {
      if (effectiveCategory == 'all') return true;
      return n.type.trim().toLowerCase() == effectiveCategory.trim().toLowerCase();
    }).toList();

    // Delete single notification confirmation modal
    Future<bool?> showDeleteSingleConfirmation(NotificationModel notif) {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Padding(
            padding: EdgeInsets.all(22.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Delete Notification?',
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Are you sure you want to delete this notification?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(ctx).pop(true);
                        },
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

    // Clear all confirm modal
    void showClearConfirmation() {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Padding(
            padding: EdgeInsets.all(22.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Clear Notifications?',
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Are you sure you want to clear all your notifications? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          HapticFeedback.mediumImpact();
                          try {
                            LocalStorage.clearNotifications();
                            ref.read(notificationsProvider.notifier).state = [];
                          } catch (_) {}

                          CustomToast.showToast(
                            context,
                            msg: 'Notifications Cleared',
                          );
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Executive Navigation Bar (Royal Ninja Brand Style)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
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
                    Expanded(
                      child: Text(
                        'Notifications',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E1B4B),
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    // Right Side: Clear All Button (Matching 40x40 executive button)
                    if (notifications.isNotEmpty)
                      GestureDetector(
                        onTap: showClearConfirmation,
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                              color: const Color(0xFFFEE2E2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: const Color(0xFFEF4444),
                            size: 21.sp,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 40.w),
                  ],
                ),
              ),

              // 2. Executive Category Filter Chips (Royal Purple & Gold Brand Theme)
              if (availableCategories.length > 1) ...[
                SizedBox(height: 6.h),
                _buildCategoryFilterBar(
                  selectedCategory: effectiveCategory,
                  categories: availableCategories,
                  notifications: notifications,
                  onSelect: (cat) {
                    HapticFeedback.selectionClick();
                    selectedCategory.value = cat;
                  },
                ),
                SizedBox(height: 12.h),
              ] else ...[
                SizedBox(height: 8.h),
              ],

              // 3. Notification List or Empty State
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    try {
                      final local = LocalStorage.getNotifications();
                      ref.read(notificationsProvider.notifier).state = local;
                    } catch (_) {}
                  },
                  color: const Color(0xFF362187),
                  backgroundColor: Colors.white,
                  child: filteredNotifications.isEmpty
                      ? _buildEmptyState(context, effectiveCategory)
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            16.w,
                            4.h,
                            16.w,
                            MediaQuery.of(context).padding.bottom + 20.h,
                          ),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final notif = filteredNotifications[index];
                            final itemKey = ValueKey(
                              '${notif.id ?? ''}_${notif.time.millisecondsSinceEpoch}_${notif.title}_$index',
                            );

                            return Dismissible(
                              key: itemKey,
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                final confirmed = await showDeleteSingleConfirmation(notif);
                                return confirmed == true;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 22.w),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Delete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                HapticFeedback.mediumImpact();
                                LocalStorage.deleteNotification(notif);
                                final current = ref.read(notificationsProvider);
                                final updated = List<NotificationModel>.from(current)
                                  ..removeWhere((item) {
                                    if (notif.id != null &&
                                        notif.id!.isNotEmpty &&
                                        item.id != null &&
                                        item.id!.isNotEmpty) {
                                      return item.id == notif.id;
                                    }
                                    return item.title == notif.title &&
                                        item.body == notif.body &&
                                        item.time.millisecondsSinceEpoch ==
                                            notif.time.millisecondsSinceEpoch;
                                  });
                                ref.read(notificationsProvider.notifier).state = updated;

                                CustomToast.showToast(
                                  context,
                                  msg: 'Notification deleted',
                                );
                              },
                              child: _NotificationCard(notif: notif),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar({
    required String selectedCategory,
    required List<Map<String, dynamic>> categories,
    required List<NotificationModel> notifications,
    required ValueChanged<String> onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat['key'];
          final key = cat['key']! as String;
          final count = key == 'all'
              ? notifications.length
              : notifications.where((n) => n.type.trim().toLowerCase() == key).length;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => onSelect(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF362187),
                            Color(0xFF5B34C4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF362187).withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 14.sp,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      cat['label']! as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF100) // Royal Gold Badge
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? const Color(0xFF362187) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String currentCategory) {
    String title = 'No Notifications Yet';
    String description = 'Your updates for redeems, support replies, service requests, and personal messages will appear here.';

    if (currentCategory == 'payment') {
      title = 'No Redeem Updates';
      description = 'Your redeem requests and account updates will appear here.';
    } else if (currentCategory == 'personal') {
      title = 'No Personal Messages';
      description = 'Custom messages sent to you by the admin will appear here.';
    } else if (currentCategory == 'support') {
      title = 'No Support Tickets';
      description = 'Replies and updates on your contact support tickets will appear here.';
    } else if (currentCategory == 'service') {
      title = 'No Service Requests';
      description = 'Updates on your promotion and service requests will appear here.';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 80.h),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF362187).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF362187).withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 32.sp,
                  color: const Color(0xFF362187),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notif});

  final NotificationModel notif;

  _CategoryMeta _getCategoryMeta(NotificationModel notif) {
    final type = notif.type.toLowerCase();
    final text = '${notif.title} ${notif.body}'.toLowerCase();

    if (type == 'payment' || text.contains('payout') || text.contains('redeem') || text.contains('refund')) {
      final isFailed = text.contains('fail') || text.contains('decline') || text.contains('reject');
      final isSuccess = text.contains('success') || text.contains('complete') || text.contains('approved');

      if (isFailed) {
        return const _CategoryMeta(
          label: 'REDEEM DECLINED',
          iconData: Icons.cancel_rounded,
          iconGradient: LinearGradient(
            colors: [Color(0xFFF87171), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          primaryColor: Color(0xFFEF4444),
          badgeBgColor: Color(0xFFFFF1F2),
          badgeTextColor: Color(0xFFBE123C),
          badgeBorderColor: Color(0xFFFECDD3),
          accentColor: Color(0xFFEF4444),
        );
      } else if (isSuccess) {
        return const _CategoryMeta(
          label: 'REDEEM SUCCESS',
          iconData: Icons.check_circle_rounded,
          iconGradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          primaryColor: Color(0xFF059669),
          badgeBgColor: Color(0xFFECFDF5),
          badgeTextColor: Color(0xFF047857),
          badgeBorderColor: Color(0xFFA7F3D0),
          accentColor: Color(0xFF10B981),
        );
      } else {
        return const _CategoryMeta(
          label: 'REDEEM PENDING',
          iconData: Icons.hourglass_top_rounded,
          iconGradient: LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          primaryColor: Color(0xFFD97706),
          badgeBgColor: Color(0xFFFFFBEB),
          badgeTextColor: Color(0xFFB45309),
          badgeBorderColor: Color(0xFFFDE68A),
          accentColor: Color(0xFFF59E0B),
        );
      }
    }

    switch (type) {
      case 'support':
        return const _CategoryMeta(
          label: 'SUPPORT',
          iconData: Icons.support_agent_rounded,
          iconGradient: LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          primaryColor: Color(0xFF0284C7),
          badgeBgColor: Color(0xFFF0F9FF),
          badgeTextColor: Color(0xFF0369A1),
          badgeBorderColor: Color(0xFFBAE6FD),
          accentColor: Color(0xFF0284C7),
        );
      case 'service':
        return const _CategoryMeta(
          label: 'SERVICE',
          iconData: Icons.assignment_rounded,
          iconGradient: LinearGradient(
            colors: [Color(0xFF5B34C4), Color(0xFF362187)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          primaryColor: Color(0xFF362187),
          badgeBgColor: Color(0xFFF5F3FF),
          badgeTextColor: Color(0xFF5B34C4),
          badgeBorderColor: Color(0xFFDDD6FE),
          accentColor: Color(0xFF362187),
        );
      case 'personal':
      default:
        return const _CategoryMeta(
          label: 'PERSONAL',
          iconData: Icons.mark_email_unread_rounded,
          iconGradient: LinearGradient(
            colors: [Color(0xFF5B34C4), Color(0xFF362187)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          primaryColor: Color(0xFF362187),
          badgeBgColor: Color(0xFFF5F3FF),
          badgeTextColor: Color(0xFF5B34C4),
          badgeBorderColor: Color(0xFFDDD6FE),
          accentColor: Color(0xFF362187),
        );
    }
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    try {
      final diff = DateTime.now().difference(dateTime);
      if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _getCategoryMeta(notif);
    final relativeTime = _formatRelativeTime(notif.time);

    // Normalize title: replace Payment/Payout Declined/Failed with Redeem Declined, Bonus Credited with Bonus Added
    String displayTitle = notif.title
        .replaceAll(RegExp(r'Payment\s+Declined', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payout\s+Declined', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payment\s+Failed', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payout\s+Failed', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payment\s+Rejected', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payout\s+Rejected', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Redeem\s+Failed', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Bonus\s+Credited', caseSensitive: false), 'Bonus Added')
        .replaceAll(RegExp(r'Balance\s+Credited', caseSensitive: false), 'Balance Added');

    final lowerTitle = displayTitle.toLowerCase();
    if (lowerTitle.contains('payment decline') ||
        lowerTitle.contains('payout decline') ||
        lowerTitle.contains('payment fail') ||
        lowerTitle.contains('payout fail') ||
        lowerTitle.contains('payment reject') ||
        lowerTitle.contains('payout reject') ||
        lowerTitle.contains('redeem fail')) {
      displayTitle = 'Redeem Declined';
    } else if (lowerTitle.contains('payment success') || lowerTitle.contains('payout success')) {
      displayTitle = 'Redeem Success';
    }

    // Normalize body: replace any Payment/Payout Declined, Admin credited -> Added, wallet -> account
    String displayBody = notif.body
        .replaceAll(RegExp(r'Payment\s+Declined', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payout\s+Declined', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payment\s+Failed', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payout\s+Failed', caseSensitive: false), 'Redeem Declined')
        .replaceAll(RegExp(r'Payment\s+request', caseSensitive: false), 'Redeem request')
        .replaceAll(RegExp(r'Payout\s+request', caseSensitive: false), 'Redeem request')
        .replaceAll(RegExp(r'Admin\s+credited', caseSensitive: false), 'Added')
        .replaceAll(RegExp(r'Admin\s+added', caseSensitive: false), 'Added')
        .replaceAll(RegExp(r'Admin\s+deducted', caseSensitive: false), 'Deducted')
        .replaceAll(RegExp(r'your\s+wallet', caseSensitive: false), 'your account')
        .replaceAll(RegExp(r'to\s+wallet', caseSensitive: false), 'to account');

    final isFailedRedeem = meta.label == 'REDEEM DECLINED';

    // Extract actual failure reason if present
    String? failureReason;
    try {
      failureReason = notif.data['reason']?.toString() ??
          notif.data['failureReason']?.toString() ??
          notif.data['rejectReason']?.toString();

      if (failureReason == null || failureReason.trim().isEmpty) {
        if (notif.body.toLowerCase().contains('reason:')) {
          final parts = notif.body.split(RegExp(r'reason:', caseSensitive: false));
          if (parts.length > 1) {
            final afterReason = parts[1].trim();
            failureReason = afterReason.split(RegExp(r'\.|\n'))[0].trim();
          }
        }
      }
      if (failureReason != null) {
        failureReason = failureReason
            .replaceAll(RegExp(r'Payment\s+Declined', caseSensitive: false), 'Redeem Declined')
            .replaceAll(RegExp(r'Payout\s+Declined', caseSensitive: false), 'Redeem Declined')
            .replaceAll(RegExp(r'Payment\s+Failed', caseSensitive: false), 'Redeem Declined')
            .replaceAll(RegExp(r'Payout\s+Failed', caseSensitive: false), 'Redeem Declined')
            .replaceAll(RegExp(r'your\s+wallet', caseSensitive: false), 'your account')
            .replaceAll(RegExp(r'to\s+wallet', caseSensitive: false), 'to account');
      }
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: isFailedRedeem ? const Color(0xFFFFF8F8) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isFailedRedeem ? const Color(0xFFFECDD3) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isFailedRedeem
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : const Color(0xFF362187).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent indicator stripe matching Royal Ninja aesthetic
              Container(
                width: 4.w,
                color: meta.accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category Gradient Icon + Title + Status Badge Pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36.w,
                            height: 36.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: meta.iconGradient,
                              borderRadius: BorderRadius.circular(11.r),
                              boxShadow: [
                                BoxShadow(
                                  color: meta.accentColor.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              meta.iconData,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              displayTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isFailedRedeem ? const Color(0xFF991B1B) : const Color(0xFF1E1B4B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
                            decoration: BoxDecoration(
                              color: meta.badgeBgColor,
                              borderRadius: BorderRadius.circular(100.r),
                              border: Border.all(
                                color: meta.badgeBorderColor,
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              meta.label,
                              style: GoogleFonts.poppins(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: meta.badgeTextColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Body Text
                      Text(
                        displayBody,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: const Color(0xFF475569),
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      // Highlighted Failure Reason Box (if failed)
                      if (isFailedRedeem && failureReason != null && failureReason.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: const Color(0xFFDC2626),
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  'Reason: $failureReason',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF991B1B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 10.h),

                      // Bottom Metadata (Timestamp)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            relativeTime,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5.sp,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

class _CategoryMeta {
  final String label;
  final IconData iconData;
  final LinearGradient iconGradient;
  final Color primaryColor;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final Color badgeBorderColor;
  final Color accentColor;

  const _CategoryMeta({
    required this.label,
    required this.iconData,
    required this.iconGradient,
    required this.primaryColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.badgeBorderColor,
    required this.accentColor,
  });
}
