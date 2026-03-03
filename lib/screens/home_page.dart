import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../services/database_helper.dart';
import '../widgets/fade_in_widget.dart';
import 'campain_detail_page.dart';
import 'notification_page.dart';

const String _catDisaster = 'disaster';
const String _catEducation = 'education';
const String _catMedical = 'medical';

class _Campaign {
  final String title, description, raised, target, category;
  final double progress;
  final String? badge, imagePath;

  const _Campaign({
    required this.title,
    required this.description,
    required this.raised,
    required this.target,
    required this.progress,
    required this.category,
    this.badge,
    this.imagePath,
  });
}

class HomePage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final UserProfileProvider profileProvider;
  const HomePage({super.key, this.onProfileTap, required this.profileProvider});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _catIndex = 0;
  final Map<String, double> _dbTotals = {};

  UserProfileProvider get _profile => widget.profileProvider;

  @override
  void initState() {
    super.initState();
    _loadDbTotals();
    _profile.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDbTotals() async {
    try {
      for (final c in [..._urgentCampaigns, ..._recentCampaigns]) {
        final total =
            await DatabaseHelper.instance.getTotalForCampaign(c.title);
        _dbTotals[c.title] = total;
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading DB totals: $e');
    }
  }

  static double _parseAmount(String s) {
    var cleaned = s.replaceAll('RM', '').trim();
    double multiplier = 1;
    if (cleaned.toLowerCase().endsWith('k')) {
      multiplier = 1000;
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return (double.tryParse(cleaned) ?? 0) * multiplier;
  }

  static String _formatAmount(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      final display =
          k == k.roundToDouble() ? k.toInt().toString() : k.toStringAsFixed(1);
      return 'RM ${display}k';
    }
    return 'RM ${v.toStringAsFixed(0)}';
  }

  double _dynamicProgress(_Campaign c) {
    final base = _parseAmount(c.raised);
    final goal = _parseAmount(c.target);
    final current = base + (_dbTotals[c.title] ?? 0);
    return goal > 0 ? (current / goal).clamp(0.0, 1.0) : c.progress;
  }

  String _dynamicRaised(_Campaign c) {
    final base = _parseAmount(c.raised);
    final current = base + (_dbTotals[c.title] ?? 0);
    return _formatAmount(current);
  }

  void _openDetail(_Campaign c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignDetailPage(
          title: c.title,
          description: c.description,
          raised: c.raised,
          target: c.target,
          progress: c.progress,
          imagePath: c.imagePath,
          category: c.category,
        ),
      ),
    );
    _loadDbTotals();
  }

  List<_Campaign> _filter(List<_Campaign> list) {
    if (_catIndex == 0) return list;
    final cats = [_catDisaster, _catEducation, _catMedical];
    return list.where((c) => c.category == cats[_catIndex - 1]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _filter(_urgentCampaigns);
    final recent = _filter(_recentCampaigns);
    final display = _catIndex == 0 ? urgent : [...urgent, ...recent];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: FadeIn(
              delay: Duration.zero,
              duration: const Duration(milliseconds: 450),
              child: _buildHeader(),
            ),
          ),

          // ── Categories ──
          SliverToBoxAdapter(
            child: FadeIn(
              delay: const Duration(milliseconds: 80),
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
                child: _buildCategories(),
              ),
            ),
          ),

          // ── Urgent ──
          SliverToBoxAdapter(
            child: FadeIn(
              delay: const Duration(milliseconds: 160),
              duration: const Duration(milliseconds: 400),
              child: _sectionTitle('Urgent Needs', showSeeAll: _catIndex != 0,
                  onSeeAll: () => setState(() => _catIndex = 0)),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeIn(
              delay: const Duration(milliseconds: 240),
              duration: const Duration(milliseconds: 450),
              child: _buildFeaturedCards(display),
            ),
          ),

          // ── Recent ──
          if (_catIndex == 0) ...[
            SliverToBoxAdapter(
              child: FadeIn(
                delay: const Duration(milliseconds: 320),
                duration: const Duration(milliseconds: 400),
                child: _sectionTitle('Recent Updates'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => FadeIn(
                    delay: Duration(milliseconds: 80 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRecentCard(recent[i]),
                    ),
                  ),
                  childCount: recent.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.volunteer_activism,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Notification bell
              InkWell(
                onTap: () {
                  const catNames = ['All', 'Disaster', 'Education', 'Medical'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationPage(
                        initialCategory: catNames[_catIndex],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(21),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: AppColors.primary, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              // Avatar
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _profile.photoFile != null
                        ? Image.file(_profile.photoFile!,
                            width: 42, height: 42, fit: BoxFit.cover)
                        : const Icon(Icons.person,
                            color: AppColors.primary, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Good Morning,',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile.firstName,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Make a difference today',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips ──
  Widget _buildCategories() {
    const cats = ['All', 'Disaster', 'Education', 'Medical'];
    const icons = [
      Icons.grid_view_rounded,
      Icons.flood_rounded,
      Icons.school_rounded,
      Icons.medical_services_rounded,
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == _catIndex;
          return GestureDetector(
            onTap: () => setState(() => _catIndex = i),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: sel ? AppColors.primaryLight : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: sel
                    ? null
                    : Border.all(color: AppColors.border),
                boxShadow: sel ? AppShadows.glow : null,
              ),
              child: Row(
                children: [
                  Icon(icons[i],
                      size: 16,
                      color: sel ? Colors.white : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    cats[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section title ──
  Widget _sectionTitle(String title,
      {bool showSeeAll = false, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.3)),
          const Spacer(),
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See All',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight)),
            ),
        ],
      ),
    );
  }

  // ── Featured horizontal cards ──
  Widget _buildFeaturedCards(List<_Campaign> list) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (_, i) => FadeIn(
          delay: Duration(milliseconds: 280 + (i * 70)),
          duration: const Duration(milliseconds: 400),
          offsetY: 16,
          child: _buildFeaturedCard(list[i]),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(_Campaign c) {
    return GestureDetector(
      onTap: () => _openDetail(c),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.elevated,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _campaignImage(c.imagePath),

              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.cardGradient),
              ),

              // Badge
              if (c.badge != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.badge == 'Ending Soon'
                          ? AppColors.warning
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Text(
                      c.badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              // Bottom content
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _dynamicProgress(c),
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_dynamicRaised(c)} / ${c.target}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text('${(_dynamicProgress(c) * 100).toInt()}%',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent list card ──
  Widget _buildRecentCard(_Campaign c) {
    return GestureDetector(
      onTap: () => _openDetail(c),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _campaignImage(c.imagePath),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(c.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _dynamicProgress(c),
                              minHeight: 5,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primaryLight),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(_dynamicProgress(c) * 100).toInt()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campaignImage(String? path) {
    if (path != null && path.isNotEmpty) {
      return Image.asset(path, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.shimmer,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.iconMuted, size: 32),
      ),
    );
  }

  // ── Data ──
  static const _urgentCampaigns = [
    _Campaign(
      title: 'Emergency Flood Relief',
      description: 'Help families affected by flooding.',
      raised: 'RM 45.2k',
      target: 'RM 50k',
      progress: 0.9,
      badge: 'Ending Soon',
      imagePath: 'assets/images/flood_relief.jpg',
      category: _catDisaster,
    ),
    _Campaign(
      title: 'Build a Dream School',
      description: 'Support education in rural areas.',
      raised: 'RM 12.4k',
      target: 'RM 25k',
      progress: 0.5,
      badge: 'Trending',
      imagePath: 'assets/images/dream_school.jpg',
      category: _catEducation,
    ),
  ];

  static const _recentCampaigns = [
    _Campaign(
      title: 'Clean Water for Everyone',
      description: 'Infrastructure \u2022 2 days left',
      raised: 'RM 8k',
      target: 'RM 15k',
      progress: 0.53,
      imagePath: 'assets/images/clean_water.jpg',
      category: _catMedical,
    ),
  ];
}
