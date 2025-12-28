import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../shared/widgets/bluetooth_status_icon.dart';
import '../widgets/chapter_card.dart';

/// Female home screen - chapter list with progress
class FemaleHomeScreen extends StatefulWidget {
  const FemaleHomeScreen({super.key});

  @override
  State<FemaleHomeScreen> createState() => _FemaleHomeScreenState();
}

class _FemaleHomeScreenState extends State<FemaleHomeScreen> {
  final UserRepository _userRepo = UserRepository();
  final ChapterProgressRepository _progressRepo = ChapterProgressRepository();

  UserModel? _user;
  int _completedChapters = 0;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  int _rebuildCounter = 0; // Used to force chapter card rebuilds

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Skip if already loading to avoid multiple simultaneous calls
    if (_isLoading && _hasLoadedOnce) return;

    if (!_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }

    try {
      final user = await _userRepo.getUser();
      final completedCount = await _progressRepo.getCompletedCount();

      if (mounted) {
        setState(() {
          _user = user;
          _completedChapters = completedCount;
          _isLoading = false;
          _hasLoadedOnce = true;
          _rebuildCounter++; // Increment to force chapter card rebuilds
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Modern gradient header
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: const Color(0xFFE57373),
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                // Bluetooth connection icon (New Widget)
                const BluetoothStatusIcon(),

                const SizedBox(width: 2),
                // Settings icon
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                )
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE57373),
                        Color(0xFFEF5350),
                        Color(0xFFEC407A),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Journey',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Welcome back! 👋',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
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
              ),
            ),

            // Progress card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildProgressCard(),
              ),
            ),

            // Chapter list header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE57373),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Chapters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chapter list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chapterNumber = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChapterCard(
                        // Use ValueKey with rebuild counter to force refresh
                        key: ValueKey(
                            'chapter_${chapterNumber}_$_rebuildCounter'),
                        chapterNumber: chapterNumber,
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            '/chapter-detail',
                            arguments: chapterNumber,
                          );
                          // Reload data when returning from chapter detail
                          _loadData();
                        },
                      ),
                    );
                  },
                  childCount: AppConstants.totalChapters,
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final percentage = _completedChapters == 0
        ? 0.0
        : _completedChapters / AppConstants.totalChapters;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFFE57373),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_completedChapters/${AppConstants.totalChapters}',
                  style: const TextStyle(
                    color: Color(0xFFE57373),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage == 0 ? 0.02 : percentage,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE57373), Color(0xFFEC407A)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            percentage == 1.0
                ? '🎉 Congratulations! You\'ve completed all chapters!'
                : '💪 Keep going! You\'re doing great',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
