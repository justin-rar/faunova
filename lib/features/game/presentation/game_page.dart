import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  AppViewStatus _currentStatus = AppViewStatus.content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekspedisi & Kuis Fauna'),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Menyiapkan bank soal dan status streak server...',
        emptyTitle: 'Sesi Belum Tersedia',
        emptyMessage: 'Tidak ada sesi kuis aktif saat ini. Tantangan baru diperbarui setiap 00:00 WIB.',
        errorMessage: 'Gagal menghubungkan ke server game. Periksa sambungan data.',
        offlineMessage: 'Mode luring. Kuis dengan skor tervalidasi server memerlukan internet.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 14),

            // 1. Streak Card with Day Dots
            _buildStreakTrackerCard(),
            const SizedBox(height: 14),

            // 2. Tantangan Hari Ini Card
            _buildDailyChallengeCard(),
            const SizedBox(height: 14),

            // 3. Kuis Utama (10 Soal, Timer 15 Detik, 3 Nyawa)
            _buildQuizArenaCard(),
            const SizedBox(height: 14),

            // 4. Shake-to-Quiz Sensor Banner (Quota 3x/hari)
            _buildShakeToQuizBanner(),
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

  Widget _buildStreakTrackerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.sageTua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.teksPutih,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Observasi Harian',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    Text(
                      '5 Hari Berturut-turut 🔥',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emasTua,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(70, 36),
                ),
                child: const Text('Klaim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Day streak dots: S S R K J S M
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayDot('Sen', true),
              _buildDayDot('Sel', true),
              _buildDayDot('Rab', true),
              _buildDayDot('Kam', true),
              _buildDayDot('Jum', true),
              _buildDayDot('Sab', false),
              _buildDayDot('Min', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(String dayLabel, bool isDone) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? AppColors.sageTua : AppColors.gading,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            isDone ? Icons.check_rounded : Icons.circle_outlined,
            size: 16,
            color: isDone ? AppColors.teksPutih : AppColors.sage,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.teksGelap,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChallengeCard() {
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
              const Icon(Icons.stars_rounded, color: AppColors.sageTua, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tantangan Hari Ini (Reset Tiap 00:00 WIB)',
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emasTua.withValues(alpha: 0.4), width: 1),
                ),
                child: const Text(
                  '+50 Poin',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emasTua,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Berapa jumlah kantung tenggorokan pada Bekantan (Nasalis larvatus) jantan dewasa?',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.teksGelap,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded, color: AppColors.teksGelap, size: 20),
            label: const Text('Mulai Tantangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizArenaCard() {
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
              const Text(
                'Arena Kuis Satwa Liar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.teksGelap,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageTua,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Skor Terbaik: 1.250',
                  style: TextStyle(
                    color: AppColors.teksPutih,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '10 soal taksonomi • Timer 15 detik • 3 nyawa • Bonus kombo. Skor dihitung dan divalidasi langsung oleh server database.',
            style: TextStyle(fontSize: 12, color: AppColors.teksGelap, height: 1.35),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sports_esports_outlined, size: 18),
            label: const Text('Mulai Sesi Kuis (10 Soal)'),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeToQuizBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gading.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vibration_rounded, color: AppColors.teksGelap, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Goyang HP (Shake-to-Quiz)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gading,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Kuota 3/3',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sensor accelerometer mendeteksi goyangan fisik untuk memunculkan soal kejutan acak.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
