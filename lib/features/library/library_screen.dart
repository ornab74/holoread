import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/glass_panel.dart';
import '../../models/book.dart';
import '../../shared/providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';
  BookStatus? _status;

  @override
  Widget build(BuildContext context) {
    final booksValue = ref.watch(booksProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBook,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add book'),
      ),
      body: booksValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (books) {
          final filtered = books.where((book) {
            final text = '${book.title} ${book.author} ${book.genres.join(' ')} '
                    '${book.tags.join(' ')}'
                .toLowerCase();
            return text.contains(_query.toLowerCase()) &&
                (_status == null || book.status == _status);
          }).toList();
          return CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Holographic library',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search title, author, genre, or tag',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            ChoiceChip(
                              label: const Text('All'),
                              selected: _status == null,
                              onSelected: (_) => setState(() => _status = null),
                            ),
                            const SizedBox(width: 8),
                            ...BookStatus.values.map(
                              (status) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(status.label),
                                  selected: _status == status,
                                  onSelected: (_) => setState(() => _status = status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width > 1100
                        ? 4
                        : width > 760
                            ? 3
                            : width > 500
                                ? 2
                                : 1;
                    return SliverGrid.builder(
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: columns == 1 ? 2.1 : 1.05,
                      ),
                      itemBuilder: (context, index) => _LibraryCard(
                        book: filtered[index],
                        onTap: () => context.push('/book/${filtered[index].id}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addBook() async {
    final title = TextEditingController();
    final author = TextEditingController();
    final pages = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add library node'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(controller: author, decoration: const InputDecoration(labelText: 'Author')),
              const SizedBox(height: 10),
              TextField(
                controller: pages,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total pages'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (accepted != true || title.text.trim().isEmpty) return;
    final repository = await ref.read(bookRepositoryProvider.future);
    final now = DateTime.now();
    await repository.saveBook(
      Book(
        id: const Uuid().v4(),
        title: title.text.trim(),
        author: author.text.trim().isEmpty ? 'Unknown author' : author.text.trim(),
        status: BookStatus.wishlist,
        dateAdded: now,
        totalPages: int.tryParse(pages.text) ?? 0,
        updatedAt: now,
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.auto_stories_rounded),
              ),
              const Spacer(),
              Chip(label: Text(book.status.label)),
            ],
          ),
          const Spacer(),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: book.progress, minHeight: 7),
          const SizedBox(height: 8),
          Text(
            book.totalPages > 0
                ? '${book.currentPage} / ${book.totalPages} pages'
                : 'Page count not set',
          ),
        ],
      ),
    );
  }
}
