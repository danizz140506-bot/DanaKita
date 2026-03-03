import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/database_helper.dart';
import '../widgets/fade_in_widget.dart';
import 'campain_detail_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _catIndex = 0;
  String _query = '';

  // DB donation totals per campaign
  final Map<String, double> _dbTotals = {};

  @override
  void initState() {
    super.initState();
    _loadDbTotals();
  }

  Future<void> _loadDbTotals() async {
    try {
      for (final c in _campaigns) {
        final title = c['title'] as String;
        final total = await DatabaseHelper.instance.getTotalForCampaign(title);
        _dbTotals[title] = total;
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

  static const _campaigns = <Map<String, dynamic>>[
    {
      'title': 'Emergency Flood Relief',
      'description': 'Help families affected by flooding.',
      'raised': 'RM 45.2k',
      'target': 'RM 50k',
      'progress': 0.9,
      'imagePath': 'assets/images/flood_relief.jpg',
      'category': 'disaster',
    },
    {
      'title': 'Build a Dream School',
      'description': 'Support education in rural areas.',
      'raised': 'RM 12.4k',
      'target': 'RM 25k',
      'progress': 0.5,
      'imagePath': 'assets/images/dream_school.jpg',
      'category': 'education',
    },
    {
      'title': 'Clean Water for Everyone',
      'description': 'Infrastructure \u2022 2 days left',
      'raised': 'RM 8k',
      'target': 'RM 15k',
      'progress': 0.53,
      'imagePath': 'assets/images/clean_water.jpg',
      'category': 'medical',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_campaigns);
    if (_catIndex > 0) {
      const cats = ['disaster', 'education', 'medical'];
      list = list.where((c) => c['category'] == cats[_catIndex - 1]).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((c) {
        return (c['title'] as String).toLowerCase().contains(q) ||
            (c['description'] as String).toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = _filtered;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Explore',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5)),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Discover causes to support',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 18),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.card,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search campaigns...',
                    hintStyle: const TextStyle(
                        color: AppColors.textHint, fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 22),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories
            _buildCategoryChips(),
            const SizedBox(height: 8),

            // Results
            Expanded(
              child: campaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: AppColors.iconMuted),
                          const SizedBox(height: 12),
                          const Text('No campaigns found',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: campaigns.length,
                      itemBuilder: (_, i) => FadeIn(
                        delay: Duration(milliseconds: 60 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildCard(campaigns[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    const labels = ['All', 'Disaster', 'Education', 'Medical'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == _catIndex;
          return GestureDetector(
            onTap: () => setState(() => _catIndex = i),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? AppColors.primaryLight : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: sel ? null : Border.all(color: AppColors.border),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textBody)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final title = c['title'] as String;
    final baseRaised = _parseAmount(c['raised'] as String);
    final goal = _parseAmount(c['target'] as String);
    final dbTotal = _dbTotals[title] ?? 0;
    final currentRaised = baseRaised + dbTotal;
    final progress = goal > 0
        ? (currentRaised / goal).clamp(0.0, 1.0)
        : (c['progress'] as num).toDouble();
    final raisedText = _formatAmount(currentRaised);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CampaignDetailPage(
              title: title,
              description: c['description'] as String,
              raised: c['raised'] as String,
              target: c['target'] as String,
              progress: (c['progress'] as num).toDouble(),
              imagePath: c['imagePath'] as String?,
              category: c['category'] as String?,
            ),
          ),
        );
        _loadDbTotals();
      },
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _buildImage(c['imagePath'] as String?),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(c['description'] as String,
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
                              value: progress,
                              minHeight: 5,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primaryLight),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(progress * 100).toInt()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$raisedText / ${c['target']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? path) {
    if (path != null && path.isNotEmpty) {
      return Image.asset(path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AppColors.shimmer,
        child: const Icon(Icons.image_outlined,
            color: AppColors.iconMuted, size: 28),
      );
}
