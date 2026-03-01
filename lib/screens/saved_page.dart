import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/fade_in_widget.dart';
import 'campain_detail_page.dart';
import 'saved_campaigns.dart';

class SavedPage extends StatefulWidget {
  final SavedCampaignsNotifier notifier;
  const SavedPage({super.key, required this.notifier});
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_up);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_up);
    super.dispose();
  }

  void _up() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final list = widget.notifier.list;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Saved',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${list.length} campaign${list.length == 1 ? '' : 's'} saved',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty ? _empty() : _list(list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_outline_rounded,
                size: 44, color: AppColors.soft),
          ),
          const SizedBox(height: 20),
          const Text('No saved campaigns',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the heart icon on any campaign to save it here for later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        final progress = (c['progress'] as num).toDouble();
        return FadeIn(
          delay: Duration(milliseconds: 60 * i),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampaignDetailPage(
                    title: c['title'] as String,
                    description: c['description'] as String,
                    raised: c['raised'] as String,
                    target: c['target'] as String,
                    progress: progress,
                    imagePath: c['imagePath'] as String?,
                    category: c['category'] as String?,
                  ),
                ),
              ),
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
                        child: _thumb(c['imagePath'] as String?),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['title'] as String,
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
                                    fontSize: 13,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value:
                                          progress.clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor:
                                          AppColors.divider,
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              AppColors.primaryLight),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.primaryLight)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.favorite_rounded,
                          size: 20, color: AppColors.error),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(String? path) {
    if (path != null && path.isNotEmpty) {
      return Image.asset(path, width: 80, height: 80, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _ph());
    }
    return _ph();
  }

  Widget _ph() => Container(
        width: 80,
        height: 80,
        color: AppColors.shimmer,
        child: const Icon(Icons.image_outlined,
            color: AppColors.iconMuted, size: 28),
      );
}
