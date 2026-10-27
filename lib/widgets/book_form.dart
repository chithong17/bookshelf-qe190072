import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../models/book.dart';

class BookFormValue {
  const BookFormValue({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.notes,
  });
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final String notes;
}

class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.onCancel,
    this.successMessage,
  });
  final Book? initial;
  final String submitLabel;
  final Future<void> Function(BookFormValue value) onSubmit;
  final VoidCallback? onCancel;
  final String? successMessage;

  @override
  State<BookForm> createState() => BookFormState();
}

class BookFormState extends State<BookForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _rating;
  late final TextEditingController _notes;
  String? _genre;
  String? _status;
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title);
    _author = TextEditingController(text: initial?.author);
    _rating = TextEditingController(text: initial?.rating?.toString());
    _notes = TextEditingController(text: initial?.notes);
    _genre = initial?.genre;
    _status = initial?.status;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _rating.dispose();
    _notes.dispose();
    super.dispose();
  }

  void clear() {
    _formKey.currentState?.reset();
    _title.clear();
    _author.clear();
    _rating.clear();
    _notes.clear();
    setState(() {
      _genre = null;
      _status = null;
      _submitted = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        BookFormValue(
          title: _title.text,
          author: _author.text,
          genre: _genre!,
          status: _status!,
          rating: _rating.text.trim().isEmpty
              ? null
              : int.parse(_rating.text.trim()),
          notes: _notes.text,
        ),
      );
      if (widget.initial == null) clear();
      if (mounted && widget.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.successMessage!)));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    autovalidateMode: _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _title,
          maxLength: 101,
          decoration: const InputDecoration(
            labelText: 'Title',
            prefixIcon: Icon(Icons.title_rounded),
          ),
          validator: Validators.title,
        ),
        const SizedBox(height: AppSpace.sm),
        TextFormField(
          controller: _author,
          maxLength: 61,
          decoration: const InputDecoration(
            labelText: 'Author',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: Validators.author,
        ),
        const SizedBox(height: AppSpace.sm),
        DropdownButtonFormField<String>(
          initialValue: _genre,
          decoration: const InputDecoration(
            labelText: 'Genre',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          hint: const Text('Choose genre'),
          items: Book.genres
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _genre = value),
          validator: Validators.genre,
        ),
        const SizedBox(height: AppSpace.md),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(Icons.bookmark_outline_rounded),
          ),
          hint: const Text('Choose status'),
          items: Book.statuses
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _status = value),
          validator: Validators.status,
        ),
        const SizedBox(height: AppSpace.md),
        TextFormField(
          controller: _rating,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Rating (optional)',
            prefixIcon: Icon(Icons.star_outline_rounded),
          ),
          validator: Validators.rating,
        ),
        const SizedBox(height: AppSpace.md),
        TextFormField(
          controller: _notes,
          maxLength: 301,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
          validator: Validators.notes,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        Row(
          children: [
            if (widget.onCancel != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
            if (widget.onCancel != null) const SizedBox(width: AppSpace.sm),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
