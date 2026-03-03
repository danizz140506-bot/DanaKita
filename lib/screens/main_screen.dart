import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../providers/user_profile_provider.dart';
import 'home_page.dart';
import 'explore_page.dart';
import 'saved_page.dart';
import 'saved_campaigns.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  List<Widget>? _pages;
  final _profileProvider = UserProfileProvider();

  static const _tabDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _profileProvider.load();
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedNotifier = SavedNotifierProvider.read(context);
    _pages ??= [
      HomePage(
        onProfileTap: () => setState(() => _index = 3),
        profileProvider: _profileProvider,
      ),
      const ExplorePage(),
      SavedPage(notifier: savedNotifier),
      ProfilePage(profileProvider: _profileProvider),
    ];
    final pages = _pages!;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < pages.length; i++)
            if (i != _index)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 0,
                  duration: _tabDuration,
                  curve: Curves.easeOut,
                  child: pages[i],
                ),
              ),
          AnimatedOpacity(
            opacity: 1,
            duration: _tabDuration,
            curve: Curves.easeIn,
            child: pages[_index],
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                _navItem(Icons.explore_outlined, Icons.explore, 'Explore', 1),
                _navItem(
                    Icons.favorite_outline, Icons.favorite, 'Saved', 2),
                _navItem(
                    Icons.person_outline, Icons.person, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final active = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryLight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color: active ? AppColors.primaryLight : AppColors.textMuted,
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
