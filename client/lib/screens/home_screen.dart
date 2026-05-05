import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/kalaam_provider.dart';
import '../providers/group_provider.dart';
import '../models/kalaam_model.dart';
import '../widgets/kalaam_card.dart';
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

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KalaamProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFFe2b96f)),
                const SizedBox(width: 8),
                const Text('بیاض', style: TextStyle(fontSize: 22, color: Color(0xFFe2b96f), fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => context.read<KalaamProvider>().loadFeed(category: provider.selectedCategory),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white38, size: 18),
                    SizedBox(width: 8),
                    Text('Search kalaams, poets, lines…', style: TextStyle(color: Colors.white30, fontSize: 14)),
                  ],
                ),
              ),
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
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.feed.length,
                            itemBuilder: (ctx, i) => KalaamCard(kalaam: provider.feed[i]),
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
    final isLoading = provider.myLoading || provider.savedLoading;

    return SafeArea(
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFe2b96f)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── My Kalaams section ──
                      _SectionHeader(label: 'My Kalaams', icon: Icons.edit_note),
                      const SizedBox(height: 8),
                      if (provider.myError != null)
                        _ErrorRow(message: provider.myError!)
                      else if (provider.myKalaams.isEmpty)
                        const _EmptyRow(message: 'No kalaams yet. Tap + to add one.')
                      else
                        ...provider.myKalaams.map((kalaam) => KalaamCard(
                              kalaam: kalaam,
                              showDeleteButton: true,
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
                            )),

                      const SizedBox(height: 24),

                      // ── Saved section ──
                      _SectionHeader(label: 'Saved', icon: Icons.bookmark_outline),
                      const SizedBox(height: 8),
                      if (provider.savedError != null)
                        _ErrorRow(message: provider.savedError!)
                      else if (provider.savedKalaams.isEmpty)
                        const _EmptyRow(message: 'No saved kalaams yet.\nTap the bookmark icon on any kalaam.')
                      else
                        ...provider.savedKalaams.map((kalaam) => KalaamCard(kalaam: kalaam)),

                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFe2b96f)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFFe2b96f), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
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
