import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to add category screen
            },
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return const LoadingWidget();
          }

          if (categoryProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${categoryProvider.errorMessage}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      categoryProvider.clearError();
                      categoryProvider.loadCategories();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (categoryProvider.categories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.category_outlined,
              title: 'No Categories',
              subtitle: 'Categories will appear here once you add them',
              action: FloatingActionButton(
                onPressed: () {
                  // TODO: Navigate to add category screen
                },
                child: const Icon(Icons.add),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(category.color.replaceFirst('#', '0xFF')),
                    ),
                    child: Icon(
                      _getIconData(category.icon),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    category.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: category.displayDescription.isNotEmpty
                      ? Text(category.displayDescription)
                      : null,
                  trailing: category.isDefault
                      ? Chip(
                          label: const Text('Default'),
                          backgroundColor: Colors.grey.shade200,
                        )
                      : null,
                  onTap: () {
                    // TODO: Navigate to category detail or filter lyrics
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'heart':
        return Icons.favorite;
      case 'pray':
        return Icons.back_hand;
      case 'star':
        return Icons.star;
      case 'cloud':
        return Icons.cloud;
      case 'scroll':
        return Icons.menu_book;
      case 'feather':
        return Icons.edit;
      default:
        return Icons.book;
    }
  }
}