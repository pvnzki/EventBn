import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class HomeCategories extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final ValueChanged<int> onCategoryTap;

  const HomeCategories({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category['isSelected'] ?? false;
          final String? iconPath = category['iconPath'];

          return GestureDetector(
            onTap: () => onCategoryTap(index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.bg01
                        : Colors.grey[100]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconPath != null) ...[
                    Image.asset(
                      iconPath,
                      width: 18,
                      height: 18,
                      color: isSelected
                          ? AppColors.background
                          : (isDark
                              ? AppColors.grey300
                              : Colors.grey[600]),
                    ),
                    const SizedBox(width: 6),
                  ] else if (category['name'] != 'All') ...[
                    Icon(
                      category['icon'],
                      size: 18,
                      color: isSelected
                          ? AppColors.background
                          : (isDark
                              ? AppColors.grey300
                              : Colors.grey[600]),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.background
                          : (isDark
                              ? AppColors.grey300
                              : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
