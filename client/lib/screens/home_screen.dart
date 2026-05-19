import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/kalaam_provider.dart';
import '../providers/group_provider.dart';
import '../models/kalaam_model.dart';
import '../widgets/kalaam_card.dart';
import '../widgets/server_url_dialog.dart';
import 'groups_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KalaamProvider>().loadFeed();
      context.read<KalaamProvider>().loadSavedKalaams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _FeedTab(),
      const _MyBayaazTab(),
      const GroupsScreen(),
      _ProfileTab(onSignOut: () async {
        final nav = Navigator.of(context);
        await context.read<AuthProvider>().signOut();
        if (!mounted) return;
        nav.pushReplacementNamed('/login');
      }),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1a),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFe2b96f),
              onPressed: () => Navigator.pushNamed(context, '/add'),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1a1a2e),
        selectedItemColor: const Color(0xFFe2b96f),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) {
            context.read<KalaamProvider>().loadMyKalaams();
            context.read<KalaamProvider>().loadSavedKalaams();
          }
          if (i == 2) {
            context.read<GroupProvider>().loadGroups();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'My Bayaaz'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── Feed Tab ────────────────────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KalaamProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOnline) const _OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFFe2b96f)),
                const SizedBox(width: 8),
                const Text('بیاض', style: TextStyle(fontSize: 22, color: Color(0xFFe2b96f), fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white70),
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => context.read<KalaamProvider>().loadFeed(category: provider.selectedCategory),
                ),
                IconButton(
                  tooltip: 'Server URL',
                  icon: Icon(
                    Icons.cloud_outlined,
                    color: AppConfig.isOverridden
                        ? const Color(0xFFe2b96f)
                        : Colors.white54,
                  ),
                  onPressed: () async {
                    final changed = await showServerUrlDialog(context);
                    if (changed && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Server URL updated. Restart the app to fully apply.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          _CategoryFilter(
            selected: provider.selectedCategory,
            onSelected: (cat) => context.read<KalaamProvider>().loadFeed(category: cat),
          ),
          Expanded(
            child: provider.feedLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFe2b96f)))
                : provider.feedError != null
                    ? Center(child: Text(provider.feedError!, style: const TextStyle(color: Colors.redAccent)))
                    : provider.feed.isEmpty
                        ? const Center(child: Text('No kalaams yet. Be the first!', style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.feed.length + (provider.feedHasMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              // Index-based prefetch: after item 17 (or feed.length-3,
                              // whichever fires first) request the next page.
                              if (provider.feedHasMore &&
                                  i == provider.feed.length - 3 &&
                                  i >= 0) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  context.read<KalaamProvider>().loadMoreFeed();
                                });
                              }
                              if (i >= provider.feed.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFe2b96f),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return KalaamCard(kalaam: provider.feed[i]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF3a2a1a),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: Color(0xFFe2b96f), size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — showing cached kalaams',
              style: TextStyle(color: Color(0xFFe2b96f), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Filter ─────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cats = [null, ...kKalaamCategories];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = cats[i];
          final label = cat == null ? 'All' : cat[0].toUpperCase() + cat.substring(1);
          final isSelected = selected == cat;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFe2b96f) : const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFFe2b96f) : Colors.white24),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── My Bayaaz Tab ────────────────────────────────────────────────────────────

class _MyBayaazTab extends StatelessWidget {
  const _MyBayaazTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KalaamProvider>();

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: Color(0xFFe2b96f), size: 22),
                  const SizedBox(width: 8),
                  const Text('My Bayaaz', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                    onPressed: () {
                      context.read<KalaamProvider>().loadMyKalaams();
                      context.read<KalaamProvider>().loadSavedKalaams();
                    },
                  ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: Color(0xFFe2b96f),
              indicatorWeight: 2.5,
              labelColor: Color(0xFFe2b96f),
              unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.4),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, letterSpacing: 0.4),
              tabs: [
                Tab(icon: Icon(Icons.edit_note, size: 18), text: 'My Kalaams'),
                Tab(icon: Icon(Icons.bookmark_outline, size: 18), text: 'Saved'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MyKalaamsList(provider: provider),
                  _SavedKalaamsList(provider: provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyKalaamsList extends StatelessWidget {
  final KalaamProvider provider;
  const _MyKalaamsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.myLoading && provider.myKalaams.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFe2b96f)));
    }
    if (provider.myError != null && provider.myKalaams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: _ErrorRow(message: provider.myError!)),
      );
    }
    if (provider.myKalaams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: _EmptyRow(message: 'No kalaams yet. Tap + to add one.'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: provider.myKalaams.length,
      itemBuilder: (ctx, i) {
        final kalaam = provider.myKalaams[i];
        return KalaamCard(
          kalaam: kalaam,
          showDeleteButton: true,
          showEditButton: true,
          showVisibilityToggle: true,
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF1a1a2e),
                title: const Text('Delete Kalaam', style: TextStyle(color: Colors.white)),
                content: const Text('Are you sure?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              context.read<KalaamProvider>().deleteKalaam(kalaam.id);
            }
          },
        );
      },
    );
  }
}

class _SavedKalaamsList extends StatelessWidget {
  final KalaamProvider provider;
  const _SavedKalaamsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.savedLoading && provider.savedKalaams.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFe2b96f)));
    }
    if (provider.savedError != null && provider.savedKalaams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: _ErrorRow(message: provider.savedError!)),
      );
    }
    if (provider.savedKalaams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: _EmptyRow(
            message: 'No saved kalaams yet.\nTap the bookmark icon on any kalaam.',
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: provider.savedKalaams.length,
      itemBuilder: (ctx, i) =>
          KalaamCard(kalaam: provider.savedKalaams[i]),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 13)),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final VoidCallback onSignOut;
  const _ProfileTab({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFe2b96f),
                backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                child: user?.avatar == null
                    ? Text(
                        user?.name.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 36, color: Colors.black, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(user?.name ?? '', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
