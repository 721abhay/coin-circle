#!/bin/bash
# Script to replace all $ symbols with ₹ (Indian Rupee) in Dart files

# Find all Dart files and replace ₹ with ₹
find lib -name "*.dart" -type f -exec sed -i "s/\\₹'/₹'/g" {} \;
find lib -name "*.dart" -type f -exec sed -i 's/symbol: "\₹/symbol: "₹/g' {} \;
find lib -name "*.dart" -type f -exec sed -i "s/prefixText: '\₹ '/prefixText: '₹ '/g" {} \;

echo "Currency symbols updated from $ to ₹"
