import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../models/news_article.dart';
import '../services/news_api_service.dart';
import '../widgets/fade_in_widget.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  /// Available search categories for fundraising-related news.
  static const _categories = <String, String>{
    'All': 'charity OR fundraising OR donation OR disaster relief',
    'Disaster': 'flood OR earthquake OR disaster relief',
    'Education': 'education fundraising OR school charity',
    'Medical': 'medical fundraising OR health charity',
    'Environment': 'clean water OR environment charity',
  };

  String _selectedCategory = 'All';
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = _categories[_selectedCategory]!;
      final articles = await NewsApiService.fetchNews(query: query);
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Map a keyword from the article title to a chip label.
  String _inferType(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('flood') ||
        lower.contains('earthquake') ||
        lower.contains('disaster') ||
        lower.contains('hurricane') ||
        lower.contains('wildfire')) {
      return 'Disaster';
    }
    if (lower.contains('school') ||
        lower.contains('education') ||
        lower.contains('student')) {
      return 'Education';
    }
    if (lower.contains('medical') ||
        lower.contains('health') ||
        lower.contains('hospital')) {
      return 'Medical';
    }
    if (lower.contains('water') || lower.contains('environment')) {
      return 'Environment';
    }
    return 'News';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('News & Updates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──
          _buildHeader(),

          // ── Category filter chips ──
          _buildCategoryChips(),

          // ── Content area ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.newspaper_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live News Feed',
                  style: TextStyle(color: Colors.black, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                _isLoading
                    ? 'Loading...'
                    : '${_articles.length} articles',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = _categories.keys.elementAt(i);
          final isSelected = label == _selectedCategory;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              if (label != _selectedCategory) {
                setState(() => _selectedCategory = label);
                _fetchNews();
              }
            },
            selectedColor: AppColors.light,
            backgroundColor: AppColors.white,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textBody,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          );
        },
      ),
    );
  }

  // ── Body content (loading / error / list) ──────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Fetching latest news...',
                style: TextStyle(color: AppColors.textBody, fontSize: 14)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Failed to load news',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textBody)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchNews,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return const Center(
        child: Text('No articles found.',
            style: TextStyle(color: AppColors.textBody)),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchNews,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _articles.length,
        itemBuilder: (_, i) {
          final article = _articles[i];
          return FadeIn(
            delay: Duration(milliseconds: 60 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArticleCard(article),
            ),
          );
        },
      ),
    );
  }

  // ── Open article in browser ─────────────────────────────────────────────

  Future<void> _openArticle(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    }
  }

  // ── Single article card ────────────────────────────────────────────────

  Widget _buildArticleCard(NewsArticle article) {
    final type = _inferType(article.title);

    return GestureDetector(
      onTap: () => _openArticle(article.url),
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Article image ──
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
              child: Image.network(
                article.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_rounded,
                        color: AppColors.iconMuted, size: 32),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type chip + source + date ──
                Row(
                  children: [
                    _typeChip(type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(article.sourceName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                    Text(article.formattedDate,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Title ──
                Text(article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),

                // ── Description ──
                Text(article.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textBody)),
                const SizedBox(height: 12),

                // ── Read more hint ──
                Row(
                  children: [
                    Text('Tap to read full article',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ── Type chip ──────────────────────────────────────────────────────────

  Widget _typeChip(String type) {
    Color bg;
    Color fg;
    switch (type) {
      case 'Disaster':
        bg = AppColors.tagOrangeBg;
        fg = AppColors.tagOrangeText;
        break;
      case 'Education':
        bg = AppColors.tagBlueBg;
        fg = AppColors.tagBlueText;
        break;
      case 'Medical':
        bg = const Color(0xFFFCE4EC);
        fg = const Color(0xFFC62828);
        break;
      case 'Environment':
        bg = AppColors.tagGreenBg;
        fg = AppColors.tagGreenText;
        break;
      default:
        bg = AppColors.tagGreenBg;
        fg = AppColors.tagGreenText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(type,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
