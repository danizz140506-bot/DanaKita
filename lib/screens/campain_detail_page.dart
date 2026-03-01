import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'saved_campaigns.dart';
import 'donate_page.dart';

class CampaignDetailPage extends StatefulWidget {
  final String title, description, raised, target;
  final double progress;
  final String? imagePath, category;
  final String organizerName, organizationName;
  final int donorsCount, daysLeft;
  final String aboutText;

  const CampaignDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.raised,
    required this.target,
    required this.progress,
    this.imagePath,
    this.category,
    this.organizerName = 'Ravi Patel',
    this.organizationName = 'Global Relief Initiative',
    this.donorsCount = 342,
    this.daysLeft = 12,
    this.aboutText =
        'Access to clean water is a fundamental human right, yet thousands in remote areas still walk miles daily for unsafe water.',
  });

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  SavedCampaignsNotifier? _saved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final n = SavedNotifierProvider.of(context);
    if (n != _saved) {
      _saved?.removeListener(_refresh);
      _saved = n;
      _saved?.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _saved?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});
  bool get _fav => _saved?.isSaved(widget.title) ?? false;

  void _share() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption('assets/images/instagram.png', 'Instagram', () =>
                    _shareFeedback(context, 'Instagram')),
                _shareOption('assets/images/facebook.png', 'Facebook', () =>
                    _shareFeedback(context, 'Facebook')),
                _shareOption('assets/images/whatsapp.png', 'WhatsApp', () =>
                    _shareFeedback(context, 'WhatsApp')),
                _shareOption('assets/images/x.png', 'X', () =>
                    _shareFeedback(context, 'X')),
                _iconShareOption(Icons.link, 'Copy link', () =>
                    _shareFeedback(context, 'Copy link')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(String imagePath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.share_rounded,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  void _shareFeedback(BuildContext context, String option) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$option (placeholder)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> get _map => {
        'title': widget.title,
        'description': widget.description,
        'raised': widget.raised,
        'target': widget.target,
        'progress': widget.progress,
        'imagePath': widget.imagePath,
        'category': widget.category,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildBody()),
            ],
          ),
          // Sticky bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryLight,
      leading: _circleButton(
        Icons.arrow_back_rounded,
        () => Navigator.pop(context),
      ),
      actions: [
        _circleButton(
          _fav ? Icons.favorite : Icons.favorite_border_rounded,
          () => _saved?.toggle(_map),
          color: _fav ? AppColors.error : null,
        ),
        _circleButton(Icons.share_outlined, _share),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.imagePath != null)
              Image.asset(widget.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _imgPlaceholder())
            else
              _imgPlaceholder(),
            // Dark gradient overlay at bottom
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardGradient),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, size: 20, color: color ?? AppColors.textDark),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.shimmer,
        child: const Icon(Icons.image_outlined,
            size: 64, color: AppColors.iconMuted),
      );

  Widget _buildBody() {
    return Container(
      transform: Matrix4.translationValues(0, -24, 0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTags(),
            const SizedBox(height: 14),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5)),
            const SizedBox(height: 18),
            _buildOrganizer(),
            const SizedBox(height: 24),
            _buildProgress(),
            const SizedBox(height: 20),
            _buildStats(),
            const SizedBox(height: 28),
            _buildAbout(),
            const SizedBox(height: 28),
            _buildWhereMoneyGoes(),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      children: [
        _tag('INFRASTRUCTURE', AppColors.tagGreenBg, AppColors.tagGreenText),
        _tag('URGENT', AppColors.tagOrangeBg, AppColors.tagOrangeText),
      ],
    );
  }

  Widget _tag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildOrganizer() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.surface,
          child: const Icon(Icons.person, color: AppColors.primaryLight, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(widget.organizationName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Organized by ${widget.organizerName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.raised,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('raised of ${widget.target}',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(widget.progress * 100).toInt()}% funded',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _statBox(Icons.people_alt_rounded, '${widget.donorsCount}', 'Donors'),
        const SizedBox(width: 12),
        _statBox(
            Icons.access_time_rounded, '${widget.daysLeft}', 'Days Left'),
      ],
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About the Campaign',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(widget.aboutText,
            style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textBody)),
      ],
    );
  }

  Widget _buildWhereMoneyGoes() {
    final items = _moneyItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Where your money goes',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 14),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(_iconFor(item['icon']!),
                          color: AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']!,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(item['desc']!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  DonatePage(campaignTitle: widget.title)),
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.glow,
          ),
          child: const Center(
            child: Text('Donate Now',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String n) {
    switch (n) {
      case 'emergency':
        return Icons.emergency_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'build':
        return Icons.construction_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'clean':
        return Icons.cleaning_services_rounded;
      case 'assessment':
        return Icons.assessment_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  List<Map<String, String>> _moneyItems() {
    switch (widget.category) {
      case 'disaster':
        return [
          {'title': 'Emergency relief supplies', 'desc': 'Food, water, blankets and basic hygiene kits for families affected by the flood.', 'icon': 'emergency'},
          {'title': 'Temporary shelter', 'desc': 'Funds help set up safe shelters and repair damaged homes so families have a roof.', 'icon': 'home'},
          {'title': 'Rebuilding & repairs', 'desc': 'Materials and labour to repair roads, schools and community buildings.', 'icon': 'build'},
        ];
      case 'education':
        return [
          {'title': 'Building & facilities', 'desc': 'Construction materials, classrooms and safe toilets so children can learn in a proper school.', 'icon': 'build'},
          {'title': 'Teachers & learning', 'desc': 'Salaries for teachers, books and learning materials for students.', 'icon': 'school'},
          {'title': 'Community involvement', 'desc': 'Training for parents and locals to support the school long after it opens.', 'icon': 'groups'},
        ];
      case 'medical':
        return [
          {'title': 'Water infrastructure', 'desc': 'Pumps, pipes and water points so communities get clean, safe drinking water.', 'icon': 'water'},
          {'title': 'Hygiene & training', 'desc': 'Handwashing stations and training on safe water use and hygiene practices.', 'icon': 'clean'},
          {'title': 'Maintenance & monitoring', 'desc': 'Ongoing repairs and water quality checks so the system keeps working.', 'icon': 'assessment'},
        ];
      default:
        return [
          {'title': 'Direct project costs', 'desc': 'Funds go to materials, equipment and labour needed to deliver the project on the ground.', 'icon': 'build'},
          {'title': 'Community & training', 'desc': 'Part of the funds support local training and community programmes so benefits last long-term.', 'icon': 'groups'},
          {'title': 'Monitoring & reporting', 'desc': 'A small share is used to track impact and report back to donors so you can see the difference.', 'icon': 'assessment'},
        ];
    }
  }
}
