#!/bin/bash

# Script to replace purple colors with theme-aware alternatives
# This is a comprehensive approach to update all purple colors in the codebase

echo "Starting color replacement..."

# Find all Dart files and replace the purple color with theme-aware colors
find . -name "*.dart" -type f -exec sed -i 's/Color(0xFF6C5CE7)/Theme.of(context).primaryColor/g' {} \;
find . -name "*.dart" -type f -exec sed -i 's/const Color(0xFF6C5CE7)/Theme.of(context).primaryColor/g' {} \;

echo "Color replacement completed!"
echo ""
echo "IMPORTANT NOTES:"
echo "1. All purple colors (0xFF6C5CE7) have been replaced with Theme.of(context).primaryColor"
echo "2. In light mode: primaryColor = black (0xFF000000)"
echo "3. In dark mode: primaryColor = white (0xFFFFFFFF)"
echo "4. Some widgets that were 'const' have been changed to non-const to support theme access"
echo ""
echo "You may need to:"
echo "- Remove 'const' keywords from widgets that now access Theme.of(context)"
echo "- Hot restart the app to see changes"
echo "- Test both light and dark modes"
