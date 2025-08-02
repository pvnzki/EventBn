import 'package:flutter/material.dart';
import '../models/event_model.dart';

class CategoryFilterBar extends StatelessWidget {
  final ExploreEventCategory selectedCategory;
  final Function(ExploreEventCategory) onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ExploreEventCategory.values.length,
        itemBuilder: (context, index) {
          final category = ExploreEventCategory.values[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category.label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(category);
                }
              },
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
              checkmarkColor: colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final String? initialQuery;
  final Function(String) onSearchChanged;
  final VoidCallback? onSearchCleared;

  const SearchBar({
    super.key,
    this.initialQuery,
    required this.onSearchChanged,
    this.onSearchCleared,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onSearchChanged(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
