import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class HomeFilterModal extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final RangeValues? selectedPriceRange;
  final String selectedLocation;
  final List<String> locationOptions;
  final double minPrice;
  final double maxPrice;
  final VoidCallback onClearAll;
  final VoidCallback onApply;
  final VoidCallback onSelectDateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged<RangeValues?> onPriceRangeChanged;
  final ValueChanged<String> onLocationChanged;
  final StateSetter setModalState;

  const HomeFilterModal({
    super.key,
    required this.selectedDateRange,
    required this.selectedPriceRange,
    required this.selectedLocation,
    required this.locationOptions,
    required this.minPrice,
    required this.maxPrice,
    required this.onClearAll,
    required this.onApply,
    required this.onSelectDateRange,
    required this.onDateRangeChanged,
    required this.onPriceRangeChanged,
    required this.onLocationChanged,
    required this.setModalState,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Events',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: onClearAll,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Filter options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterSection(
                    title: 'Date Range',
                    child: _DateRangeFilter(
                      selectedDateRange: selectedDateRange,
                      onSelectDateRange: onSelectDateRange,
                      onClearDate: () => onDateRangeChanged(null),
                      formatDate: _formatDate,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FilterSection(
                    title: 'Location',
                    child: _LocationFilter(
                      selectedLocation: selectedLocation,
                      locationOptions: locationOptions,
                      onLocationChanged: onLocationChanged,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FilterSection(
                    title: 'Price Range (LKR)',
                    child: _PriceRangeFilter(
                      selectedPriceRange: selectedPriceRange,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                      onChanged: onPriceRangeChanged,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter section wrapper
// ---------------------------------------------------------------------------
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date range
// ---------------------------------------------------------------------------
class _DateRangeFilter extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearDate;
  final String Function(DateTime) formatDate;

  const _DateRangeFilter({
    required this.selectedDateRange,
    required this.onSelectDateRange,
    required this.onClearDate,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onSelectDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDateRange != null
                    ? '${formatDate(selectedDateRange!.start)} - ${formatDate(selectedDateRange!.end)}'
                    : 'Select date range',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedDateRange != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (selectedDateRange != null)
              InkWell(
                onTap: onClearDate,
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location
// ---------------------------------------------------------------------------
class _LocationFilter extends StatelessWidget {
  final String selectedLocation;
  final List<String> locationOptions;
  final ValueChanged<String> onLocationChanged;

  const _LocationFilter({
    required this.selectedLocation,
    required this.locationOptions,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: locationOptions.map((location) {
        final isSelected = selectedLocation == location;
        return InkWell(
          onTap: () => onLocationChanged(location),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              location,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Price range
// ---------------------------------------------------------------------------
class _PriceRangeFilter extends StatelessWidget {
  final RangeValues? selectedPriceRange;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<RangeValues?> onChanged;

  const _PriceRangeFilter({
    required this.selectedPriceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (selectedPriceRange != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LKR ${selectedPriceRange!.start.round()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'LKR ${selectedPriceRange!.end.round()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        RangeSlider(
          values: selectedPriceRange ?? RangeValues(minPrice, maxPrice),
          min: minPrice,
          max: maxPrice,
          divisions: 20,
          labels: selectedPriceRange != null
              ? RangeLabels(
                  'LKR ${selectedPriceRange!.start.round()}',
                  'LKR ${selectedPriceRange!.end.round()}',
                )
              : null,
          onChanged: (RangeValues values) => onChanged(values),
        ),
        if (selectedPriceRange != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(
              'Clear Price Filter',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}
