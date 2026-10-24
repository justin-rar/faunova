// ==============================================================================
// FAUNOVA PRESENTATION: SearchPage
// Halaman Pencarian Komunitas: Tab Akun Pengguna & Tab Katalog Spesies Satwa
// Sesuai Plan 5.2, 5.4, 5.7 & AGENTS.md (Sesi S11)
// Catatan Keras: Akun Centang Biru diprioritaskan di atas; koordinat privat tidak pernah bocor.
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/search_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../profile/models/public_profile_model.dart';
import '../../profile/presentation/public_profile_page.dart';
import '../models/species_catalog_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  Timer? _debounceTimer;

  AppViewStatus get _searchStatus {
    if (_searchError != null && _searchedAccounts.isEmpty && _searchedSpecies.isEmpty) {
      return AppViewStatus.error;
    }
    return AppViewStatus.content;
  }

  List<PublicProfileModel> _searchedAccounts = [];
  List<SpeciesCatalogModel> _searchedSpecies = [];
  bool _isLoading = false;
  String? _searchError;

  final List<String> _categories = const [
    'Semua',
    'Mamalia',
    'Aves (Burung)',
    'Reptilia',
    'Amfibi',
    'Biota Air',
    'Serangga',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _executeSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch();
    });
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim();
    setState(() {
      _isLoading = true;
      _searchError = null;
    });

    try {
      final accountsFuture = SearchService.instance.searchAccounts(query);
      final speciesFuture = SearchService.instance.searchSpecies(query, category: _selectedCategory);

      final results = await Future.wait([accountsFuture, speciesFuture]);

      if (mounted) {
        setState(() {
          _searchedAccounts = results[0] as List<PublicProfileModel>;
          _searchedSpecies = results[1] as List<SpeciesCatalogModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        centerTitle: true,
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: EdgeInsets.symmetric(horizontal: 10),
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.60),
          labelStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          tabs: const [
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Akun Pengguna'),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Katalog Spesies'),
              ),
            ),
          ],
        ),
      ),
      body: AppStateView(
        status: _searchStatus,
        loadingMessage: 'Mencari entri dalam basis data...',
        emptyTitle: 'Hasil Tidak Ditemukan',
        emptyMessage: 'Coba gunakan kata kunci lain atau periksa ejaan.',
        errorMessage: 'Gagal melakukan pencarian server. Periksa sambungan data.',
        offlineMessage: 'Pencarian daring terbatas dalam mode luring.',
        onRetry: _executeSearch,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchInput(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAccountsTab(),
                  _buildSpeciesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        style: AppTypography.bodyMedium(fontSize: 14, color: AppColors.teksGelap),
        decoration: InputDecoration(
          hintText: _tabController.index == 0
              ? 'Cari nama kolektor atau @username...'
              : 'Cari nama lokal satwa atau nama binomial...',
          hintStyle: AppTypography.bodyCompact(
            fontSize: 13,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.sageTua, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.teksGelap),
                  onPressed: () {
                    _searchController.clear();
                    _executeSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildAccountsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sageTua));
    }

    if (_searchError != null && _searchedAccounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 40),
              const SizedBox(height: 10),
              Text(_searchError!, style: const TextStyle(fontSize: 13, color: AppColors.teksGelap), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _executeSearch,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageTua),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchedAccounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_rounded, size: 48, color: AppColors.sage),
              const SizedBox(height: 12),
              const Text(
                'Akun Tidak Ditemukan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada penjelajah yang cocok dengan kata kunci "${_searchController.text.trim()}".',
                style: TextStyle(fontSize: 13, color: AppColors.teksGelap.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      children: [
        const Row(
          children: [
            Icon(Icons.verified_rounded, size: 16, color: Color(0xFF1E88E5)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Hasil Akun (Prioritas Centang Biru Teratas)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teksGelap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._searchedAccounts.map((account) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAccountCard(account),
            )),
      ],
    );
  }

  Widget _buildAccountCard(PublicProfileModel account) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.isVerifiedActive
              ? const Color(0xFF1E88E5).withValues(alpha: 0.45)
              : AppColors.surfaceContainerHighest,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfilePage(
                  userId: account.id,
                  initialAuthorName: account.displayName,
                  initialAuthorUsername: account.username,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: account.isVerifiedActive ? const Color(0xFF1E88E5) : AppColors.sageTua,
                      width: 1.5,
                    ),
                  ),
                  child: AppAvatar(
                    avatarPath: account.avatarPath,
                    displayName: account.displayName,
                    radius: 22,
                    backgroundColor: account.isVerifiedActive ? AppColors.sageTua : AppColors.sage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.displayName,
                              style: AppTypography.titleUi(
                                fontSize: 14,
                                color: AppColors.teksGelap,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isVerifiedActive) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF1E88E5),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${account.username}',
                        style: AppTypography.labelCaption(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (account.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyCompact(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
                      ),
                      child: Text(
                        '${account.capturesCount} Obs',
                        style: AppTypography.labelCaption(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${account.followersCount} pengikut',
                      style: AppTypography.labelCaption(
                        fontSize: 10.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesTab() {
    return Column(
      children: [
        _buildCategoryFilterBar(),
        const SizedBox(height: 6),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.sageTua))
              : _searchedSpecies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pets_outlined, size: 48, color: AppColors.sage),
                            const SizedBox(height: 12),
                            const Text(
                              'Spesies Tidak Ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Coba gunakan nama lokal Indonesia atau nama ilmiah binomial latin.',
                              style: TextStyle(fontSize: 13, color: AppColors.teksGelap.withValues(alpha: 0.7)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                      children: [
                        ..._searchedSpecies.map((species) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSpeciesCard(species),
                            )),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = cat;
              });
              _executeSearch();
            },
            selectedColor: AppColors.sageTua,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.35),
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildSpeciesThumbnail(String photoPath) {
    const double size = 70;
    Widget img;

    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      img = Image.network(
        photoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: AppColors.sageMuda.withValues(alpha: 0.5),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageTua),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.sageMuda,
          child: const Center(
            child: Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 30),
          ),
        ),
      );
    } else if (photoPath.startsWith('assets/')) {
      img = Image.asset(
        photoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.sageMuda,
          child: const Center(
            child: Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 30),
          ),
        ),
      );
    } else {
      img = Container(
        width: size,
        height: size,
        color: AppColors.sageMuda,
        child: const Center(
          child: Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 30),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: img,
      ),
    );
  }

  Widget _buildSpeciesCard(SpeciesCatalogModel sp) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSpeciesDetailModal(context, sp),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpeciesThumbnail(sp.samplePhotoPath),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sp.speciesName,
                              style: AppTypography.headlineSpecies(
                                fontSize: 15,
                                color: AppColors.teksGelap,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: _getConservationBadgeColor(sp.conservationStatus).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sp.conservationStatus,
                              style: AppTypography.labelCaption(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _getConservationBadgeColor(sp.conservationStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sp.scientificName,
                        style: AppTypography.subheadSpecies(
                          fontSize: 12,
                          color: AppColors.sageTua,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sp.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyCompact(
                          fontSize: 11.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.surfaceContainerHighest, width: 0.8),
                            ),
                            child: Text(
                              sp.taxonomyClass,
                              style: AppTypography.labelCaption(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageTua,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${sp.observationsCount} observasi',
                            style: AppTypography.labelCaption(
                              fontSize: 10.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeciesDetailModal(BuildContext context, SpeciesCatalogModel sp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: AppColors.gading,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Foto Besar (Ketuk untuk Layar Penuh)
                      GestureDetector(
                        onTap: () {
                          FullScreenImageViewer.open(
                            context,
                            imageUrl: sp.samplePhotoPath,
                            title: sp.speciesName,
                            subtitle: sp.scientificName,
                            description: sp.description,
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: sp.samplePhotoPath.startsWith('http')
                                    ? Image.network(
                                        sp.samplePhotoPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.sageMuda,
                                          child: const Center(
                                            child: Icon(Icons.pets_rounded, size: 54, color: AppColors.sageTua),
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        sp.samplePhotoPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.sageMuda,
                                          child: const Center(
                                            child: Icon(Icons.pets_rounded, size: 54, color: AppColors.sageTua),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Layar Penuh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nama Satwa & Badge Status IUCN
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sp.speciesName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.teksGelap,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sp.scientificName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.teksGelap.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getConservationBadgeColor(sp.conservationStatus).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getConservationBadgeColor(sp.conservationStatus).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              sp.conservationStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _getConservationBadgeColor(sp.conservationStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Baris Taksonomi & Observasi
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sageTua,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.category_rounded, size: 13, color: AppColors.teksPutih),
                                const SizedBox(width: 5),
                                Text(
                                  sp.taxonomyClass,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teksPutih,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sageMuda,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility_rounded, size: 13, color: AppColors.teksGelap),
                                const SizedBox(width: 5),
                                Text(
                                  '${sp.observationsCount} Observasi Komunitas',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teksGelap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Deskripsi & Catatan Konservasi
                      const Text(
                        'Deskripsi & Perilaku Alami',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sp.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.teksGelap.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Catatan Konservasi
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.sageMuda.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_rounded, color: AppColors.sageTua, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Spesies satwa terdata dalam repositori konservasi Faunova Nusantara. Foto lapangan terverifikasi rantai hash kriptografi.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.teksGelap,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sageTua,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tutup Detail Satwa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksPutih,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getConservationBadgeColor(String status) {
    if (status.contains('Kritis') || status.contains('CR')) {
      return AppColors.merahStatus;
    }
    if (status.contains('Terancam') || status.contains('EN')) {
      return const Color(0xFFD84315);
    }
    if (status.contains('Rentan') || status.contains('VU')) {
      return AppColors.emasTua;
    }
    return AppColors.sageTua;
  }
}
