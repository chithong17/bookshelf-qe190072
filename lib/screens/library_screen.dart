import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/book_form.dart';
import 'detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.user});
  final User user;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _service = BookService();
  final _search = TextEditingController();
  final _addFormKey = GlobalKey<BookFormState>();
  String? _genre;
  String? _status;
  bool _favoritesOnly = false;
  bool _showAddForm = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Book> _visible(List<Book> books) {
    final query = _search.text.trim().toLowerCase();
    final result = books.where((book) {
      return (_genre == null || book.genre == _genre) &&
          (_status == null || book.status == _status) &&
          (!_favoritesOnly || book.favorite) &&
          (query.isEmpty ||
              book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query));
    }).toList();
    result.sort((a, b) {
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return byTitle != 0
          ? byTitle
          : a.author.toLowerCase().compareTo(b.author.toLowerCase());
    });
    return result;
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _genre = null;
      _status = null;
      _favoritesOnly = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BookShelf'),
            Text(
              widget.user.email ?? '',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showAddForm = !_showAddForm),
        icon: Icon(_showAddForm ? Icons.close_rounded : Icons.add_rounded),
        label: Text(_showAddForm ? 'Close' : 'Add Book'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder<List<ConnectivityResult>>(
              stream: Connectivity().onConnectivityChanged,
              builder: (context, snapshot) {
                final offline =
                    snapshot.hasData &&
                    snapshot.data!.contains(ConnectivityResult.none);
                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: offline
                      ? Semantics(
                          liveRegion: true,
                          child: Container(
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.errorContainer,
                            padding: const EdgeInsets.all(AppSpace.sm),
                            child: const Text(
                              "You're offline. Cached books may still be available.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<List<Book>>(
                stream: _service.watchBooks(widget.user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const _LibraryLoading();
                  }
                  if (snapshot.hasError) {
                    final denied = snapshot.error.toString().contains(
                      'permission-denied',
                    );
                    return _LibraryError(
                      message: denied
                          ? 'You do not have permission to view these books.'
                          : 'Books could not be loaded.',
                      onRetry: () => setState(() {}),
                    );
                  }
                  final allBooks = snapshot.data ?? const <Book>[];
                  final books = _visible(allBooks);
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          AppSpace.md,
                          AppSpace.md,
                          96,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (_showAddForm)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpace.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Add a book',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpace.md),
                                      BookForm(
                                        key: _addFormKey,
                                        submitLabel: 'Add Book',
                                        successMessage: 'Book added',
                                        onSubmit: (value) => _service.addBook(
                                          userId: widget.user.uid,
                                          title: value.title,
                                          author: value.author,
                                          genre: value.genre,
                                          status: value.status,
                                          rating: value.rating,
                                          notes: value.notes,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_showAddForm)
                              const SizedBox(height: AppSpace.md),
                            _FilterPanel(
                              search: _search,
                              genre: _genre,
                              status: _status,
                              favoritesOnly: _favoritesOnly,
                              onSearch: (_) => setState(() {}),
                              onGenre: (value) =>
                                  setState(() => _genre = value),
                              onStatus: (value) =>
                                  setState(() => _status = value),
                              onFavorites: (value) =>
                                  setState(() => _favoritesOnly = value),
                              onClear: _clearFilters,
                            ),
                            const SizedBox(height: AppSpace.md),
                            _Summary(books: books),
                            const SizedBox(height: AppSpace.md),
                            if (books.isEmpty)
                              _EmptyLibrary(
                                filtered: allBooks.isNotEmpty,
                                onClear: _clearFilters,
                              ),
                            ...books.map(
                              (book) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpace.sm,
                                ),
                                child: _BookCard(
                                  book: book,
                                  onFavorite: () async {
                                    try {
                                      await _service.toggleFavorite(book);
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Favorite could not be updated',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  onOpen: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetailScreen(
                                        book: book,
                                        service: _service,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.search,
    required this.genre,
    required this.status,
    required this.favoritesOnly,
    required this.onSearch,
    required this.onGenre,
    required this.onStatus,
    required this.onFavorites,
    required this.onClear,
  });
  final TextEditingController search;
  final String? genre;
  final String? status;
  final bool favoritesOnly;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onGenre;
  final ValueChanged<String?> onStatus;
  final ValueChanged<bool> onFavorites;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        children: [
          TextField(
            controller: search,
            onChanged: onSearch,
            decoration: const InputDecoration(
              labelText: 'Search by title or author',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: genre,
                  decoration: const InputDecoration(labelText: 'Genre'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...Book.genres.map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    ),
                  ],
                  onChanged: onGenre,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...Book.statuses.map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    ),
                  ],
                  onChanged: onStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorites only'),
            secondary: const Icon(Icons.star_rounded),
            value: favoritesOnly,
            onChanged: onFavorites,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final status in Book.statuses)
        status: books.where((book) => book.status == status).length,
    };
    final ordered =
        Book.statuses.where((status) => counts[status]! > 0).toList()
          ..sort((a, b) {
            final difference = counts[b]!.compareTo(counts[a]!);
            return difference != 0
                ? difference
                : Book.statuses.indexOf(a).compareTo(Book.statuses.indexOf(b));
          });
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  Chip(
                    avatar: const Icon(Icons.menu_book_rounded),
                    label: Text('Books: ${books.length}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.star_rounded),
                    label: Text(
                      'Favorites: ${books.where((book) => book.favorite).length}',
                    ),
                  ),
                ],
              ),
              for (final status in ordered)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(status),
                      Text(
                        '${counts[status]}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onFavorite,
    required this.onOpen,
  });
  final Book book;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(book.author),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    children: [
                      Chip(label: Text(book.genre)),
                      Chip(label: Text(book.status)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: book.favorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: onFavorite,
              icon: Icon(
                book.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: book.favorite
                    ? Theme.of(context).colorScheme.tertiary
                    : null,
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.filtered, required this.onClear});
  final bool filtered;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
      child: Column(
        children: [
          Icon(
            filtered ? Icons.search_off_rounded : Icons.auto_stories_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpace.md),
          const Text(
            'No books found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            filtered
                ? 'Try clearing your filters or changing your search.'
                : 'Add your first book to start your private library.',
            textAlign: TextAlign.center,
          ),
          if (filtered)
            TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    ),
  );
}

class _LibraryLoading extends StatelessWidget {
  const _LibraryLoading();
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(AppSpace.md),
    itemCount: 4,
    itemBuilder: (_, _) => const Card(child: SizedBox(height: 112)),
  );
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpace.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.md),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
