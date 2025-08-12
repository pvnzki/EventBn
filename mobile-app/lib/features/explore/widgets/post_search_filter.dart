import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostSearchBar extends StatefulWidget {
  final String? initialQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchCleared;

  const PostSearchBar({
    super.key,
    this.initialQuery,
    this.onSearchChanged,
    this.onSearchCleared,
  });

  @override
  State<PostSearchBar> createState() => _PostSearchBarState();
}

class _PostSearchBarState extends State<PostSearchBar> {
  late TextEditingController _controller;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _isSearchActive = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearchActive
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search posts, users, or events...',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _isSearchActive
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _isSearchActive = false);
                    widget.onSearchCleared?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() => _isSearchActive = value.isNotEmpty);
          widget.onSearchChanged?.call(value);
        },
        onTap: () {
          setState(() => _isSearchActive = true);
        },
      ),
    );
  }
}

class PostCategoryFilterBar extends StatefulWidget {
  final PostCategory selectedCategory;
  final ValueChanged<PostCategory>? onCategoryChanged;

  const PostCategoryFilterBar({
    super.key,
    required this.selectedCategory,
    this.onCategoryChanged,
  });

  @override
  State<PostCategoryFilterBar> createState() => _PostCategoryFilterBarState();
}

class _PostCategoryFilterBarState extends State<PostCategoryFilterBar> {
  final List<PostCategory> _categories = PostCategory.values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == widget.selectedCategory;

          return FilterChip(
            label: Text(_getCategoryDisplayName(category)),
            selected: isSelected,
            onSelected: (_) => widget.onCategoryChanged?.call(category),
            backgroundColor: colorScheme.surface,
            selectedColor: colorScheme.primaryContainer,
            checkmarkColor: colorScheme.onPrimaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryDisplayName(PostCategory category) {
    switch (category) {
      case PostCategory.all:
        return 'All';
      case PostCategory.music:
        return 'Music';
      case PostCategory.sports:
        return 'Sports';
      case PostCategory.tech:
        return 'Tech';
      case PostCategory.food:
        return 'Food';
      case PostCategory.art:
        return 'Art';
      case PostCategory.business:
        return 'Business';
      case PostCategory.education:
        return 'Education';
      case PostCategory.entertainment:
        return 'Entertainment';
      case PostCategory.lifestyle:
        return 'Lifestyle';
    }
  }
}

class PostTypeFilterBar extends StatefulWidget {
  final PostType? selectedType;
  final ValueChanged<PostType?>? onTypeChanged;

  const PostTypeFilterBar({
    super.key,
    this.selectedType,
    this.onTypeChanged,
  });

  @override
  State<PostTypeFilterBar> createState() => _PostTypeFilterBarState();
}

class _PostTypeFilterBarState extends State<PostTypeFilterBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final postTypes = [null, ...PostType.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: postTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final postType = postTypes[index];
          final isSelected = postType == widget.selectedType;

          return ActionChip(
            label: Text(_getPostTypeDisplayName(postType)),
            backgroundColor:
                isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            onPressed: () => widget.onTypeChanged?.call(postType),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  String _getPostTypeDisplayName(PostType? type) {
    if (type == null) return 'All Types';

    switch (type) {
      case PostType.eventInterest:
        return 'Interested';
      case PostType.eventReview:
        return 'Reviews';
      case PostType.eventMoment:
        return 'Moments';
      case PostType.eventPromotion:
        return 'Promotions';
      case PostType.eventQuestion:
        return 'Questions';
      case PostType.eventMemory:
        return 'Memories';
    }
  }
}
