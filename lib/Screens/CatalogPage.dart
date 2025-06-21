import 'package:flutter/material.dart';
import 'package:a_s_office_web/Screens/catalog/catalog_state.dart';
import 'package:a_s_office_web/Screens/catalog/catalog_widgets.dart';
import 'package:a_s_office_web/Screens/catalog/catalog_navigation.dart';
import 'package:a_s_office_web/widgets/SearchBarWidget.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> with CatalogStateMixin, CatalogWidgetsMixin, CatalogNavigationMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: buildFloatingActionButton(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                buildAppBar(),
                SliverToBoxAdapter(
                  child: SearchBarWidget(
                    controller: searchController,
                    onClear: clearSearch,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                buildCurrentView(),
                buildNavigationControls(),
              ],
            ),
    );
  }
}