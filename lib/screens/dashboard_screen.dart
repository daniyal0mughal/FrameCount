import 'dart:async';
import 'package:flutter/material.dart';
import '../services/tracker_bridge.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasAccessibilityPermission = false;

  int _reelsCount = 0;
  int _tiktokCount = 0;
  int _shortsCount = 0;
  int _totalCount = 0;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadStats();

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadStats();
      _checkPermission();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final access = await TrackerBridge.checkAccessibilityPermission();
    if (mounted) {
      setState(() {
        _hasAccessibilityPermission = access;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await TrackerBridge.getTodayStats();
    if (mounted) {
      setState(() {
        _reelsCount = stats['reels'] ?? 0;
        _tiktokCount = stats['tiktok'] ?? 0;
        _shortsCount = stats['shorts'] ?? 0;
        _totalCount = stats['total'] ?? 0;
      });
    }
  }

  Future<void> _confirmClearData() async {
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear All Data?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'This will reset your scroll counts for Instagram Reels, TikTok, and YouTube Shorts back to 0. Her mood will also reset to happy.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hotCrimson,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await TrackerBridge.clearAllData();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'All scroll data has been cleared!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  bool get _isGirlSad => _totalCount >= 30;

  String get _characterMoodTitle => _isGirlSad ? 'SAD & CRYING 😢' : 'CHILL & VIBING ✨';
  Color get _characterMoodColor => _isGirlSad ? AppColors.hotCrimson : AppColors.neonGreen;

  @override
  Widget build(BuildContext context) {
    final int minutesEstimated = ((_totalCount * 25) / 60).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _hasAccessibilityPermission
                    ? AppColors.neonGreen
                    : AppColors.hotCrimson,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FRAMECOUNT',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
            onPressed: () {
              _loadStats();
              _checkPermission();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasAccessibilityPermission) ...[
                _buildAccessibilityActivationCard(),
                const SizedBox(height: 16),
              ],

              // 3D Girl Companion Card
              _buildAnimeGirlCompanionCard(),
              const SizedBox(height: 16),

              // Main Stats Box
              _buildMainCountBox(minutesEstimated),
              const SizedBox(height: 20),

              // Active Platforms
              const Text(
                'LIVE SESSIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              _buildPlatformTile(
                title: 'Instagram Reels',
                count: _reelsCount,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 8),

              _buildPlatformTile(
                title: 'TikTok For You',
                count: _tiktokCount,
                accentColor: AppColors.cyberCyan,
              ),
              const SizedBox(height: 8),

              _buildPlatformTile(
                title: 'YouTube Shorts',
                count: _shortsCount,
                accentColor: AppColors.hotCrimson,
              ),
              const SizedBox(height: 20),

              // Clear All Data Action Button
              _buildClearDataButton(),
              const SizedBox(height: 16),

              // Auto-Overlay Status Notice
              _buildAutomatedEngineNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmClearData,
        icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.hotCrimson),
        label: const Text(
          'CLEAR ALL DATA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppColors.hotCrimson,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.hotCrimson.withAlpha(100), width: 1.2),
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimeGirlCompanionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _characterMoodColor.withAlpha(90), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 76,
              height: 76,
              color: AppColors.surfaceElevated,
              child: Image.asset(
                _isGirlSad ? 'assets/girl_sad.png' : 'assets/girl_happy.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(_isGirlSad ? '😢' : '💃', style: const TextStyle(fontSize: 36)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _characterMoodColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _characterMoodTitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: _characterMoodColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isGirlSad
                      ? 'Limit reached (30+ videos)! She is sad and crying.'
                      : 'Looking hot and happy! Keep your scrolling mindful.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'She floats on Instagram, TikTok & Shorts automatically.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCountBox(int minutesEstimated) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TODAY TOTAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '~$minutesEstimated MINS LOST',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_totalCount',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'videos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformTile({
    required String title,
    required int count,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityActivationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.solarAmber.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENABLE AUTO-TRACKING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.solarAmber,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Turn on FrameCount in Accessibility to enable automatic overlays and scroll tracking on Instagram, TikTok, and YouTube Shorts.',
            style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await TrackerBridge.requestAccessibilityPermission();
                Future.delayed(const Duration(seconds: 1), _checkPermission);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'ACTIVATE NOW',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedEngineNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SEAMLESS AUTOMATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '• The 3D anime girl automatically floats when you launch Instagram, TikTok, or YouTube Shorts.\n'
            '• Under 30 videos: she stays happy and winking.\n'
            '• At 30+ videos: she turns sad and starts crying.\n'
            '• When you switch apps, she disappears automatically.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
