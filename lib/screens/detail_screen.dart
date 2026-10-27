import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/book_form.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.book, required this.service});
  final Book book;
  final BookService service;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Book _book = widget.book;
  bool _editing = false;
  bool _favoriteBusy = false;

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    setState(() {
      _favoriteBusy = true;
      _book = _book.copyWith(favorite: !_book.favorite);
    });
    try {
      await widget.service.toggleFavorite(
        _book.copyWith(favorite: !_book.favorite),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _book = _book.copyWith(favorite: !_book.favorite));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorite could not be updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete “${_book.title}” from your BookShelf?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteBook(_book);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book could not be deleted')),
        );
      }
    }
  }

  Future<void> _save(BookFormValue value) async {
    final updated = _book.copyWith(
      title: value.title.trim(),
      author: value.author.trim(),
      genre: value.genre,
      status: value.status,
      rating: value.rating,
      clearRating: value.rating == null,
      notes: value.notes,
    );
    final saved = await widget.service.updateBook(_book, updated);
    if (mounted) {
      setState(() {
        _book = saved;
        _editing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book saved')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Book details'),
      actions: [
        if (!_editing)
          IconButton(
            tooltip: 'Edit',
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_rounded),
          ),
        if (!_editing)
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _editing
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: BookForm(
                        initial: _book,
                        submitLabel: 'Save',
                        onSubmit: _save,
                        onCancel: () => setState(() => _editing = false),
                      ),
                    ),
                  )
                : _BookDetails(
                    book: _book,
                    favoriteBusy: _favoriteBusy,
                    onFavorite: _toggleFavorite,
                  ),
          ),
        ),
      ),
    ),
  );
}

class _BookDetails extends StatelessWidget {
  const _BookDetails({
    required this.book,
    required this.favoriteBusy,
    required this.onFavorite,
  });
  final Book book;
  final bool favoriteBusy;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: book.favorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: favoriteBusy ? null : onFavorite,
                icon: Icon(
                  book.favorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 32,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpace.xl),
          _DetailRow(label: 'Genre', value: book.genre),
          _DetailRow(label: 'Status', value: book.status),
          _DetailRow(
            label: 'Rating',
            value: book.rating?.toString() ?? 'Not rated',
          ),
          _DetailRow(
            label: 'Notes',
            value: book.notes.isEmpty ? 'No notes' : book.notes,
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
