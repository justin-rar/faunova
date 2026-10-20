import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppViewStatus _currentStatus = AppViewStatus.content;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.emas,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.teksPutih,
          unselectedLabelColor: AppColors.sageMuda,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: const [
            Tab(text: 'Untuk Kamu'),
            Tab(text: 'Mengikuti'),
          ],
        ),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Sinkronisasi feed observasi satwa...',
        emptyTitle: 'Belum Ada Observasi',
        emptyMessage: 'Ikuti penjelajah lain atau potret satwa liar pertamamu untuk memulai rantai!',
        errorMessage: 'Gagal memuat feed lapangan. Periksa sambungan data Anda.',
        offlineMessage: 'Mode luring. Menampilkan postingan tersimpan dari cache terenkripsi.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 16),
            _buildJournalFeedItem(
              authorName: 'Budi Satria Wibowo',
              authorUsername: 'budi_satria',
              isVerified: true,
              commonName: 'Jalak Bali',
              scientificName: 'Leucopsar rothschildi',
              taxonomyClass: 'Aves • Passeriformes',
              conservationStatus: 'Kritis (CR)',
              locationArea: 'Taman Nasional Bali Barat (Grid Snapped)',
              timeAgo: '20 menit lalu',
              likesCount: 38,
              blockSeq: 14,
              fieldNotes: 'Teramati sepasang Jalak Bali bertengger di dahan pohon beringin pesisir Teluk Brumbun. Bulu jambul tegak sempurna.',
              imageAccent: const Color(0xFF4A6572),
              animalIcon: Icons.flutter_dash_rounded,
            ),
            const SizedBox(height: 18),
            _buildJournalFeedItem(
              authorName: 'Siti Rahmawati',
              authorUsername: 'siti_flora_fauna',
              isVerified: true,
              commonName: 'Kucing Kuwuk (Kucing Hutan)',
              scientificName: 'Prionailurus bengalensis',
              taxonomyClass: 'Mammalia • Carnivora',
              conservationStatus: 'Risiko Rendah (LC)',
              locationArea: 'Lereng Gunung Ciremai, Kuningan',
              timeAgo: '2 jam lalu',
              likesCount: 114,
              blockSeq: 9,
              fieldNotes: 'Tertangkap kamera di semak belukar dekat aliran sungai berbatu saat senja. Gerakan sangat lincah dan waspada.',
              imageAccent: const Color(0xFF6B5841),
              animalIcon: Icons.pets_rounded,
            ),
            const SizedBox(height: 18),
            _buildJournalFeedItem(
              authorName: 'drh. Indra Perkasa',
              authorUsername: 'indra_vet',
              isVerified: false,
              commonName: 'Cenderawasih Kuning-Kecil',
              scientificName: 'Paradisaea minor',
              taxonomyClass: 'Aves • Paradisaeidae',
              conservationStatus: 'Risiko Rendah (LC)',
              locationArea: 'Cagar Alam Pegunungan Cycloop, Papua',
              timeAgo: '5 jam lalu',
              likesCount: 205,
              blockSeq: 27,
              fieldNotes: 'Suara panggilan jantan terdengar menggema sebelum tampak melakukan display bulu hiasan di kanopi hutan primer.',
              imageAccent: const Color(0xFF8B6B38),
              animalIcon: Icons.wb_sunny_rounded,
            ),
            const SizedBox(height: 18),
            _buildJournalFeedItem(
              authorName: 'Alam Lestari Nusantara',
              authorUsername: 'alam_lestari',
              isVerified: true,
              commonName: 'Rusa Bawean',
              scientificName: 'Axis kuhlian',
              taxonomyClass: 'Mammalia • Artiodactyla',
              conservationStatus: 'Kritis (CR)',
              locationArea: 'Pulau Bawean, Laut Jawa (Area Kasar)',
              timeAgo: '1 hari lalu',
              likesCount: 89,
              blockSeq: 3,
              fieldNotes: 'Spesimen endemik langka terekam sedang merumput di batas hutan sekunder pada pagi berkabut.',
              imageAccent: const Color(0xFF475844),
              animalIcon: Icons.eco_rounded,
            ),
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
                'Pengujian State Fitur (AGENTS.md)',
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

  Widget _buildJournalFeedItem({
    required String authorName,
    required String authorUsername,
    required bool isVerified,
    required String commonName,
    required String scientificName,
    required String taxonomyClass,
    required String conservationStatus,
    required String locationArea,
    required String timeAgo,
    required int likesCount,
    required int blockSeq,
    required String fieldNotes,
    required Color imageAccent,
    required IconData animalIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.sage.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.sageTua,
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.teksPutih,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.teksGelap,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF1E88E5),
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@$authorUsername • $timeAgo',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.teksGelap.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Verifiable Chain Block Badge (Plan 5.2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sageTua,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_rounded, size: 12, color: AppColors.teksPutih),
                      const SizedBox(width: 4),
                      Text(
                        '#$blockSeq',
                        style: const TextStyle(
                          color: AppColors.teksPutih,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Field Observation Photo Surface
          Container(
            height: 210,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: imageAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(animalIcon, size: 54, color: AppColors.gading.withValues(alpha: 0.9)),
                      const SizedBox(height: 8),
                      Text(
                        commonName,
                        style: const TextStyle(
                          color: AppColors.gading,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Snapped Location Pill
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gading),
                        const SizedBox(width: 4),
                        Text(
                          locationArea,
                          style: const TextStyle(
                            color: AppColors.gading,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Species Classification & Field Notes
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commonName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksGelap,
                            ),
                          ),
                          Text(
                            scientificName,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.teksGelap.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Conservation status tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: conservationStatus.contains('CR')
                            ? AppColors.merahStatus.withValues(alpha: 0.15)
                            : AppColors.sageTua.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        conservationStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: conservationStatus.contains('CR')
                              ? AppColors.merahStatus
                              : AppColors.sageTua,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  fieldNotes,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.teksGelap,
                  ),
                ),
                const SizedBox(height: 12),
                // Footer row with Like and Hash Chain verification mark
                Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.merahStatus,
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$likesCount Suka',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.teksGelap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      taxonomyClass,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.teksGelap.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.share_outlined,
                      color: AppColors.teksGelap,
                      size: 19,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
