import 'package:flutter/material.dart';
import 'package:a_s_office_web/Screens/catalog/catalog_state.dart';

mixin CatalogNavigationMixin<T extends StatefulWidget> on State<T>, CatalogStateMixin<T> {
  void navigateToPage(int pageNumber) {
    setState(() {
      currentPage = pageNumber;
      if (currentPage == 0) {
        currentView = CatalogView.intro;
      } else if (currentPage == 1) {
        currentView = CatalogView.catalogIndex;
      } else {
        currentView = CatalogView.products;
      }
    });
  }

  Widget buildNavigationControls() {
    if (searchController.text.isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    bool canGoNext = currentPage < totalPages - 1;
    bool canGoPrevious = currentPage > 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          children: [
            // Next button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoNext ? () => navigateToPage(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('הבא'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Jump to specific page
            Expanded(
              child: DropdownButtonFormField<int>(
                value: currentPage,
                decoration: const InputDecoration(
                  labelText: 'קפוץ לעמוד',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(totalPages, (index) {
                  String label;
                  if (index == 0) label = 'מבוא (עמוד 1)';
                  else if (index == 1) label = 'תוכן עניינים (עמוד 2)';
                  else label = 'עמוד ${index + 1}';
                  return DropdownMenuItem(value: index, child: Text(label));
                }),
                onChanged: (value) {
                  if (value != null) navigateToPage(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            // Previous button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoPrevious ? () => navigateToPage(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('הקודם'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}