import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lyric_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class LyricsListScreen extends StatefulWidget {
  const LyricsListScreen({Key? key}) : super(key: key);

  @override
  State<LyricsListScreen> createState() => _LyricsListScreenState();
}

class _LyricsListScreenState extends State<LyricsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LyricProvider>(context, listen: false).loadLyrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayaaz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: Consumer<LyricProvider>(
        builder: (context, lyricProvider, child) {
          if (lyricProvider.isLoading) {
            return const LoadingWidget();
          }

          if (lyricProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${lyricProvider.errorMessage}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      lyricProvider.clearError();
                      lyricProvider.loadLyrics();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (lyricProvider.lyrics.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book_outlined,
              title: 'No Lyrics Yet',
              subtitle: 'Start adding your favorite poetry and verses',
              action: FloatingActionButton(
                onPressed: () {
                  // TODO: Navigate to add lyric screen
                },
                child: const Icon(Icons.add),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lyricProvider.lyrics.length,
            itemBuilder: (context, index) {
              final lyric = lyricProvider.lyrics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    lyric.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lyric.displayPoet.isNotEmpty)
                        Text(
                          lyric.displayPoet,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        lyric.categoryName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lyric.isFavorite)
                        const Icon(Icons.favorite, color: Colors.red, size: 20),
                      if (lyric.isPinned)
                        const Icon(Icons.push_pin, color: Colors.orange, size: 20),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to lyric detail screen
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add lyric screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add lyric screen coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}