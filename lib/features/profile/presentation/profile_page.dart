import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../camera/models/capture_model.dart';
import '../../camera/models/chain_verification_result.dart';
import '../models/badge_model.dart';
import '../models/public_profile_model.dart';
import 'widgets/badge_celebration_dialog.dart';
import 'widgets/collection_grid_view.dart';
import 'widgets/collection_map_view.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/currency_converter_card.dart';
import 'widgets/multi_timezone_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppViewStatus _currentStatus = AppViewStatus.content;

  List<CaptureModel> _captures = [];
  PublicProfileModel? _myProfile;
  List<BadgeModel> _badges = [];
  bool _isLoadingCaptures = false;
  bool _isLoadingBadges = false;
  String? _capturesError;
  int _collectionMode = 0; // 0: Grid Koleksi, 1: Peta Persebaran
  bool _isVerifyingChain = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadCaptures();
    _loadProfile();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoadingBadges = true);
    try {
      final list = await BadgeService.instance.getUserBadges();
      if (mounted) {
        setState(() {
          _badges = list;
          _isLoadingBadges = false;
        });

        // Pop-up lokal saat badge baru terbuka (Plan 204)
        final newlyUnlocked = list.where((b) => b.isNewlyUnlocked).toList();
        if (newlyUnlocked.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              BadgeCelebrationDialog.show(context, badge: newlyUnlocked.first);
            }
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBadges = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ProfileService.instance.getMyProfile();
      if (mounted) {
        setState(() {
          _myProfile = p;
        });
      }
    } catch (_) {}
  }

  void _showEditProfileSheet() {
    if (_myProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(
        initialProfile: _myProfile!,
        onSaved: (updated) {
          setState(() {
            _myProfile = updated;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teksGelap, fontSize: 17),
        ),
        content: const Text(
          'Sesi Anda akan dihapus dari perangkat ini. Anda perlu memasukkan email dan kata sandi kembali untuk masuk.',
          style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AuthService.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merahStatus,
              foregroundColor: AppColors.teksPutih,
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 14;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        centerTitle: true,
        title: const Text(
          'Profil Kolektor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  color: AppColors.gading,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == 'edit_profile') {
                      _showEditProfileSheet();
                    } else if (value == 'logout') {
                      _showLogoutDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menu dipilih: $value'),
                          backgroundColor: AppColors.sageTua,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_profile',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.teksGelap),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Edit Profil Kolektor',
                              style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'saran_kesan',
                      child: Row(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 18, color: AppColors.teksGelap),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Saran & Kesan Kuliah PAM',
                              style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'setting_biometrik',
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.teksGelap),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pengaturan & Sidik Jari',
                              style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: AppColors.merahStatus),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keluar Akun',
                              style: TextStyle(color: AppColors.merahStatus, fontSize: 13, fontWeight: FontWeight.w600),
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
        ],
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Memuat data portofolio koleksi...',
        emptyTitle: 'Profil Belum Terdaftar',
        emptyMessage: 'Silakan masuk atau buat akun baru untuk melihat portofolio Anda.',
        errorMessage: 'Gagal memuat profil pengguna dari server.',
        offlineMessage: 'Mode luring. Memuat data profil dari cache lokal terenkripsi.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 14),

            // 1. Profile Header Card
            _buildProfileHeroCard(),
            const SizedBox(height: 14),

            // 2. Centang Biru Subscription Card (Plan 5.4)
            _buildVerifiedSubscriptionCard(),
            const SizedBox(height: 14),

            // 3. Estimasi Kurs Centang Biru (Plan 78, 127) - Hive AES-256
            const CurrencyConverterCard(),
            const SizedBox(height: 14),

            // 4. Jam Observasi Dunia 4 Zona (Plan 40, 136, 318) - Live Clock WIB, WITA, WIT, London
            const MultiTimeZoneCard(
              title: 'Jam Observasi Lapangan (4 Zona)',
              subtitle: 'Sinkronisasi taktis WIB, WITA, WIT, dan London (BST/GMT)',
            ),
            const SizedBox(height: 14),

            // 5. Badge Shelf (Grid Pencapaian)
            _buildBadgeShelfCard(),
            const SizedBox(height: 14),

            // 6. Sub-tab: Postingan Publik vs Koleksi Privat + Verifikasi Rantai
            _buildSubTabsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Simulasi State (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildStateChip('Normal', AppViewStatus.content),
              _buildStateChip('Memuat', AppViewStatus.loading),
              _buildStateChip('Kosong', AppViewStatus.empty),
              _buildStateChip('Galat', AppViewStatus.error),
              _buildStateChip('Luring', AppViewStatus.offline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String label, AppViewStatus status) {
    final isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentStatus = status;
        });
      },
      selectedColor: AppColors.sageTua,
      backgroundColor: AppColors.gading,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildProfileHeroCard() {
    final displayName = _myProfile?.displayName ?? 'Arya Wicaksana';
    final username = _myProfile?.username ?? 'arya_wallacea';
    final bioText = _myProfile?.bio.isNotEmpty == true
        ? _myProfile!.bio
        : 'Penjelajah biodiversitas Indonesia Timur. Mengarsipkan reptilia dan aves endemik ke dalam buku besar terenkripsi.';
    final isVerified = _myProfile?.isVerified ?? true;
    final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.sageTua,
                child: Text(
                  initialLetter,
                  style: const TextStyle(
                    color: AppColors.teksPutih,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksGelap,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 18),
                        ],
                      ],
                    ),
                    Text(
                      '@$username',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.teksGelap, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Kolektor Satwa Wallacea',
                      style: TextStyle(fontSize: 11.5, color: AppColors.emasTua, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bioText,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.teksGelap.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showEditProfileSheet,
            icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.teksGelap),
            label: const Text(
              'Edit Profil',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.sage, width: 1.2),
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.sage),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(label: 'Koleksi', value: '${_captures.length}'),
              const _MetricItem(label: 'Postingan', value: '0'),
              const _MetricItem(label: 'Pengikut', value: '218'),
              const _MetricItem(label: 'Badge Sah', value: '4/8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centang Biru Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.teksGelap,
                  ),
                ),
                Text(
                  'Aktif s/d 30 Nov 2026 • Midtrans Sandbox',
                  style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.gading,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Langganan Centang Biru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const CurrencyConverterCard(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Perpanjang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeShelfCard() {
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Lencana Gelar Pencapaian (MVP)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gading,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emas.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  '$unlockedCount / ${_badges.length} Terbuka',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emasTua,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_badges.isEmpty && _isLoadingBadges)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemCount: _badges.length,
              itemBuilder: (context, index) {
                final badge = _badges[index];
                return _buildBadgeItem(badge);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BadgeModel badge) {
    final iconData = BadgeService.getBadgeIcon(badge.iconName);

    return InkWell(
      onTap: () => BadgeDetailSheet.show(context, badge: badge),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: badge.isUnlocked ? AppColors.sageTua : AppColors.gading,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.isUnlocked ? AppColors.emas : AppColors.sage.withValues(alpha: 0.35),
                    width: 1.8,
                  ),
                  boxShadow: badge.isUnlocked
                      ? [
                          BoxShadow(
                            color: AppColors.emas.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  badge.isUnlocked ? iconData : Icons.lock_outline_rounded,
                  size: 22,
                  color: badge.isUnlocked ? AppColors.emas : AppColors.sage,
                ),
              ),
              if (!badge.isUnlocked)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.teksGelap,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${badge.currentProgress}/${badge.targetCount}',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: badge.isUnlocked ? FontWeight.w700 : FontWeight.w500,
              color: badge.isUnlocked ? AppColors.teksGelap : AppColors.sage,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _loadCaptures() async {
    setState(() {
      _isLoadingCaptures = true;
      _capturesError = null;
    });

    try {
      final list = await CaptureService.instance.fetchUserCaptures();
      if (mounted) {
        setState(() {
          _captures = list;
          _isLoadingCaptures = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _capturesError = e.toString();
          _isLoadingCaptures = false;
        });
      }
    }
  }

  Future<void> _verifyChain() async {
    setState(() {
      _isVerifyingChain = true;
    });

    // Dialog progress audit
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.gading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircularProgressIndicator(color: AppColors.sageTua),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Mengaudit seluruh rantai blok SHA-256...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.teksGelap,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await CaptureService.instance.verifyUserChain();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isVerifyingChain = false;
        });
        _showChainVerificationDialog(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isVerifyingChain = false;
        });
        _showChainVerificationDialog(
          ChainVerificationResult(
            isValid: false,
            totalBlocks: _captures.length,
            message: 'Gagal menjalankan audit rantai: $e',
          ),
        );
      }
    }
  }

  void _showChainVerificationDialog(ChainVerificationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.gading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (result.isValid ? AppColors.sageTua : AppColors.merahStatus).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.isValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                color: result.isValid ? AppColors.sageTua : AppColors.merahStatus,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.isValid ? 'Rantai Integritas Sah' : 'Integritas Terputus!',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: result.isValid ? AppColors.sageTua : AppColors.merahStatus,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (result.isValid ? AppColors.sage : AppColors.merahStatus).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Blok:', style: TextStyle(fontSize: 12, color: AppColors.teksGelap)),
                      Text(
                        '${result.totalBlocks} Blok Koleksi',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.teksGelap),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.sageMuda),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status Rantai:', style: TextStyle(fontSize: 12, color: AppColors.teksGelap)),
                      Flexible(
                        child: Text(
                          result.isValid ? 'VALID (100% Cocok)' : 'RUSAK / TAMPERED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: result.isValid ? AppColors.sageTua : AppColors.merahStatus,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  if (result.brokenSeq != null) ...[
                    const Divider(height: 16, color: AppColors.sageMuda),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Terputus Pada:', style: TextStyle(fontSize: 12, color: AppColors.merahStatus)),
                        Text(
                          'Urutan #${result.brokenSeq}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.merahStatus),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: const TextStyle(fontSize: 12.5, color: AppColors.teksGelap, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sageMuda.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.sageTua),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fungsi database PostgreSQL `verify_chain` menghitung ulang serialisasi kanonis UTF-8 dari genesis hingga blok terakhir.',
                      style: TextStyle(fontSize: 11, color: AppColors.teksGelap),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageTua,
              foregroundColor: AppColors.teksPutih,
            ),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.sageTua,
            indicatorWeight: 3,
            labelColor: AppColors.teksGelap,
            unselectedLabelColor: AppColors.sage,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Postingan Publik'),
              Tab(text: 'Koleksi & Peta'),
            ],
          ),
          const SizedBox(height: 16),

          // Tampilan isi tab
          if (_tabController.index == 0)
            _buildPublicPostsTab()
          else
            _buildCollectionAndMapTab(),
        ],
      ),
    );
  }

  Widget _buildPublicPostsTab() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sageMuda.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dynamic_feed_rounded, size: 36, color: AppColors.sageTua),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Postingan Publik',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bagikan tangkapan dari koleksi pribadi Anda ke linimasa publik Faunova di Sesi S9.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.teksGelap.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionAndMapTab() {
    final validCoordinatesCount = _captures.where((c) => c.latitude != null && c.longitude != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Blockchain Hash-Chain Verifier Banner (Plan 5.2)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gading,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.sageTua, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Integritas Buku Besar (Simple Blockchain)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Setiap tangkapan dienkripsi dengan SHA-256 kanonis menyambung ke tangkapan sebelumnya.',
                style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap, height: 1.35),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isVerifyingChain ? null : _verifyChain,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sageTua,
                  side: const BorderSide(color: AppColors.sageTua, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: _isVerifyingChain
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                      )
                    : const Icon(Icons.verified_user_rounded, size: 18),
                label: const Text(
                  'Verifikasi Rantai (verify_chain)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tampilan Mode Switcher: Grid Koleksi vs Peta Persebaran
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _collectionMode = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _collectionMode == 0 ? AppColors.sageTua : AppColors.gading,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _collectionMode == 0 ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 16,
                        color: _collectionMode == 0 ? AppColors.teksPutih : AppColors.teksGelap,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Grid Koleksi (${_captures.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _collectionMode == 0 ? AppColors.teksPutih : AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _collectionMode = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _collectionMode == 1 ? AppColors.sageTua : AppColors.gading,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _collectionMode == 1 ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 16,
                        color: _collectionMode == 1 ? AppColors.teksPutih : AppColors.teksGelap,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Peta ($validCoordinatesCount)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _collectionMode == 1 ? AppColors.teksPutih : AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Konten Koleksi
        if (_isLoadingCaptures)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.sageTua),
          )
        else if (_capturesError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 32),
                const SizedBox(height: 8),
                Text(
                  _capturesError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.teksGelap),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loadCaptures,
                  child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          )
        else if (_collectionMode == 0)
          CollectionGridView(
            captures: _captures,
            onRefresh: _loadCaptures,
          )
        else
          CollectionMapView(
            captures: _captures,
            height: 380,
          ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.teksGelap,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.teksGelap.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
