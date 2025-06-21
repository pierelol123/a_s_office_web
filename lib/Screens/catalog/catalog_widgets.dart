import 'dart:math';
import 'package:a_s_office_web/model/CatalogIntro.dart';
import 'package:a_s_office_web/services/pdf/pdf_capacity_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/widgets/ProductCard.dart';
import 'package:a_s_office_web/Screens/ProductEditPage.dart';
import 'package:a_s_office_web/Screens/catalog/catalog_state.dart';
import 'package:a_s_office_web/Screens/catalog/catalog_utils.dart';
import 'package:a_s_office_web/services/product_service.dart';
import 'package:a_s_office_web/widgets/PdfCapacityIndicator.dart';

mixin CatalogWidgetsMixin<T extends StatefulWidget> on State<T>, CatalogStateMixin<T> {
  Widget buildFloatingActionButton() {
    return (currentView == CatalogView.products || searchController.text.isNotEmpty)
        ? FloatingActionButton.extended(
            onPressed: addNewProduct,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('הוסף מוצר'),
          )
        : const SizedBox.shrink();
  }

  Widget buildAppBar() {
    return SliverAppBar(
      expandedHeight: 60.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue[600],
      centerTitle: true,
      actions: [
        const Spacer(),
        IconButton(
          onPressed: () => CatalogUtils.showFileInfo(context),
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'מידע על קבצי הנתונים',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => CatalogUtils.openFileLocation(context),
          icon: const Icon(Icons.folder_open, color: Colors.white),
          tooltip: 'פתח מיקום קבצי הנתונים',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => CatalogUtils.generatePdf(allProducts, context),
          icon: const Icon(Icons.print, color: Colors.white),
          tooltip: 'הדפס קטלוג',
        ),
        const SizedBox(width: 8),
        const Spacer(),
      ],
    );
  }

  Widget buildCurrentView() {
    if (searchController.text.isNotEmpty) {
      return buildSearchResults();
    }
    
    return buildPageGrid();
  }

  Widget buildPageGrid() {
    if (isBigScreen(context)) {
      return buildDualPageLayout();
    } else {
      return buildSinglePageLayout();
    }
  }

  Widget buildDualPageLayout() {
    final currentDisplayPage = currentPage + 1;
    final nextDisplayPage = currentDisplayPage + 1;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          height: getPageHeight(max(currentDisplayPage, nextDisplayPage)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side: Next page
              Expanded(
                child: buildPageContainer(nextDisplayPage),
              ),
              // Divider
              buildPageDivider(),
              // Right side: Current page
              Expanded(
                child: buildPageContainer(currentDisplayPage),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSinglePageLayout() {
    final currentDisplayPage = currentPage + 1;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          height: getPageHeight(currentDisplayPage),
          child: buildPageContainer(currentDisplayPage),
        ),
      ),
    );
  }

  Widget buildPageContainer(int displayPageNumber) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: buildPageContent(displayPageNumber),
          ),
          buildPageFooter(displayPageNumber),
        ],
      ),
    );
  }

  Widget buildPageDivider() {
    return Container(
      width: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[200]!,
            Colors.blue[400]!,
            Colors.blue[600]!,
            Colors.blue[400]!,
            Colors.blue[200]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }

  Widget buildPageFooter(int displayPageNumber) {
    final capacity = getPdfCapacityForPage(displayPageNumber); // ADD: Get capacity
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border(
          top: BorderSide(color: Colors.blue[300]!, width: 2),
        ),
      ),
      child: Row( // CHANGED: From single Text to Column
      mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'עמוד $displayPageNumber',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
              fontSize: 16,
            ),
          ),
          // ADD: PDF capacity indicator
          if (displayPageNumber > 2) ...[
            const SizedBox(height: 8),
            PdfCapacityIndicator(
              capacity: capacity,
              isCompact: true,
              onTap: () => _showPdfCapacityDialog(context, displayPageNumber, capacity),
            ),
          ],
        ],
      ),
    );
  }
  
  // ADD: Method to show detailed capacity dialog
  void _showPdfCapacityDialog(BuildContext context, int pageNumber, PdfPageCapacity capacity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text('התאמה ל-PDF - עמוד $pageNumber'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PdfCapacityIndicator(
                  capacity: capacity,
                  isCompact: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'פירוט טכני:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('גובה משוער:', '${capacity.estimatedHeight.toStringAsFixed(0)} נקודות'),
                _buildDetailRow('גובה זמין:', '${capacity.availableHeight.toStringAsFixed(0)} נקודות'),
                _buildDetailRow('מספר מוצרים:', '${capacity.productHeights.length}'),
                if (capacity.productHeights.isNotEmpty) ...[
                  _buildDetailRow('גובה ממוצע למוצר:', '${(capacity.estimatedHeight / capacity.productHeights.length).toStringAsFixed(0)} נקודות'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('סגור'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPageContent(int displayPageNumber) {
    if (displayPageNumber == 1) {
      return buildIntroPageContent();
    } else if (displayPageNumber == 2) {
      return buildIndexPageContent();
    } else {
      final products = getProductsForPage(displayPageNumber);
      return buildGridForSinglePage(products, displayPageNumber);
    }
  }

  // MISSING METHOD 1: buildIntroPageContent
  Widget buildIntroPageContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title
          Text(
            catalogIntro.title,
            style: TextStyle(
              fontSize: 32,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            catalogIntro.subtitle,
            style: TextStyle(
              fontSize: 24,
              color: Colors.blue[600],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Description
          Text(
            catalogIntro.description,
            style: const TextStyle(fontSize: 18),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 24),
          // Features
          Text(
            'מה אנחנו מציעים:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          ...catalogIntro.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 16),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              ],
            ),
          )),
          const SizedBox(height: 24),
          // Contact info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'צור קשר',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  catalogIntro.contactInfo,
                  style: const TextStyle(fontSize: 16),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Last updated
          Text(
            'עודכן לאחרונה: ${catalogIntro.lastUpdated.day}/${catalogIntro.lastUpdated.month}/${catalogIntro.lastUpdated.year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // MISSING METHOD 2: buildIndexPageContent
  Widget buildIndexPageContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title
          Text(
            'תוכן עניינים',
            style: TextStyle(
              fontSize: 20,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          // Index entries with correct page numbers
          buildIndexEntryCompact('מבוא לקטלוג', 1, () => navigateToPage(0)),
          buildIndexEntryCompact('תוכן עניינים', 2, () => navigateToPage(1)),
          const Divider(),
          ...catalogIndex.sections.map((section) => 
            buildIndexEntryCompact(
              section.title + ' (${section.productCount} מוצרים)',
              section.pageNumber,
              () => navigateToPage(section.pageNumber - 1),
            ),
          ),
          const SizedBox(height: 16),
          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'סיכום הקטלוג',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Text(
                  'סך הכל: ${allProducts.length} מוצרים ב-${catalogIndex.sections.length} עמודים',
                  style: const TextStyle(fontSize: 11),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for index entries
  Widget buildIndexEntryCompact(String title, int pageNum, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pageNum.toString(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.grey[300]!, Colors.transparent],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[700],
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MISSING METHOD 3: buildGridForSinglePage
  Widget buildGridForSinglePage(List<Product> products, int pageNumber) {
    return Column(
      children: [
        // Products list
        Expanded(
          child: products.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    "אין מוצרים בעמוד $pageNumber", 
                    style: TextStyle(color: Colors.grey[400]),
                    textDirection: TextDirection.rtl,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      height: product.height,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ProductCard(
                        product: product,
                        onTap: () => editProduct(product),
                        onDelete: () => deleteProduct(product),
                        isCompact: true,
                      ),
                    );
                  },
                ),
        ),
        // Add product button at bottom (only for product pages, not intro/index)
        if (pageNumber > 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(
                top: BorderSide(color: Colors.green[200]!, width: 1),
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () => addProductToPage(pageNumber),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'הוסף מוצר לעמוד $pageNumber',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildSearchResults() {
    if (isBigScreen(context)) {
      return buildBigScreenSearchResults();
    } else {
      return buildSmallScreenSearchResults();
    }
  }

  Widget buildBigScreenSearchResults() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange[400]!, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            color: Colors.white,
          ),
          child: Column(
            children: [
              buildSearchHeader(),
              Expanded(
                child: buildSearchResultsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSmallScreenSearchResults() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = filteredProducts[index];
            return Container(
              height: product.height,
              margin: const EdgeInsets.only(bottom: 12),
              child: ProductCard(
                product: product,
                onTap: () => editProduct(product),
                onDelete: () => deleteProduct(product),
                isCompact: true,
              ),
            );
          },
          childCount: filteredProducts.length,
        ),
      ),
    );
  }

  Widget buildSearchHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.orange[300]!, width: 2),
        ),
      ),
      child: Text(
        'תוצאות חיפוש: "${searchController.text}"',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange[800],
          fontSize: 16,
        ),
      ),
    );
  }

  Widget buildSearchResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Container(
          height: product.height,
          margin: const EdgeInsets.only(bottom: 12),
          child: ProductCard(
            product: product,
            onTap: () => editProduct(product),
            onDelete: () => deleteProduct(product),
            isCompact: true,
          ),
        );
      },
    );
  }

  // Helper methods
  double getPageHeight(int displayPageNumber) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (displayPageNumber == 1) {
      return screenHeight - 350;
    } else if (displayPageNumber == 2) {
      return screenHeight - 320;
    } else {
      return screenHeight - 250;
    }
  }

  // Product management methods
  void editProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          product: product,
          onSave: updateProduct,
          isNewProduct: false,
        ),
      ),
    );
  }

  void addNewProduct() {
    int defaultPage = searchController.text.isNotEmpty ? 3 : max(3, currentPage + 3);
    int defaultRow = 1;
    
    final productsInTargetPage = allProducts.where((p) => p.pageNumber == defaultPage).toList();
    if (productsInTargetPage.isNotEmpty) {
      defaultRow = productsInTargetPage.map((p) => p.rowInPage).fold(0, max) + 1;
    }

    final newProduct = Product(
      productID: DateTime.now().millisecondsSinceEpoch,
      productName: '',
      productPrice: 0.0,
      productCapacity: 0,
      imagePath: '',
      dateAdded: DateTime.now().toIso8601String(),
      description: '',
      totalQuantitySold: 0,
      buyers: [],
      pageNumber: defaultPage,
      rowInPage: defaultRow,
      height: 160.0,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          product: newProduct,
          onSave: addProduct,
          isNewProduct: true,
        ),
      ),
    );
  }

  // Method to add product to specific page
  void addProductToPage(int pageNumber) {
    final productsInTargetPage = allProducts.where((p) => p.pageNumber == pageNumber).toList();
    int nextRow = 1;
    if (productsInTargetPage.isNotEmpty) {
      nextRow = productsInTargetPage.map((p) => p.rowInPage).fold(0, max) + 1;
    }

    final newProduct = Product(
      productID: DateTime.now().millisecondsSinceEpoch,
      productName: '',
      productPrice: 0.0,
      productCapacity: 0,
      imagePath: '',
      dateAdded: DateTime.now().toIso8601String(),
      description: '',
      totalQuantitySold: 0,
      buyers: [],
      pageNumber: pageNumber,
      rowInPage: nextRow,
      height: 160.0,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          product: newProduct,
          onSave: addProduct,
          isNewProduct: true,
        ),
      ),
    );
  }

  // Navigation method
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

  // Product CRUD operations - these need to be implemented in the state mixin
  Future<void> updateProduct(Product updatedProduct) async {
    final success = await ProductService.updateProduct(allProducts, updatedProduct);
    if (success) {
      final currentPageBeforeUpdate = currentPage;
      final currentViewBeforeUpdate = currentView;
      final hasSearchQuery = searchController.text.isNotEmpty;
      
      setState(() {
        final index = allProducts.indexWhere((p) => p.productID == updatedProduct.productID);
        if (index != -1) {
          allProducts[index] = updatedProduct;
          
          if (hasSearchQuery) {
            filteredProducts = ProductService.filterProducts(allProducts, searchController.text);
          } else {
            filteredProducts = List.from(allProducts);
          }
          
          currentPage = currentPageBeforeUpdate;
          currentView = currentViewBeforeUpdate;
          calculateTotalPages();
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המוצר עודכן בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בעדכון המוצר'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> deleteProduct(Product product) async {
    final success = await ProductService.deleteProduct(allProducts, product.productID);
    if (success) {
      final currentPageBeforeDelete = currentPage;
      final currentViewBeforeDelete = currentView;
      final hasSearchQuery = searchController.text.isNotEmpty;
      
      setState(() {
        allProducts.removeWhere((p) => p.productID == product.productID);
        catalogIndex = CatalogIndex.fromProducts(allProducts);
        
        if (hasSearchQuery) {
          filteredProducts = ProductService.filterProducts(allProducts, searchController.text);
        } else {
          filteredProducts = List.from(allProducts);
        }
        
        currentPage = currentPageBeforeDelete;
        currentView = currentViewBeforeDelete;
        calculateTotalPages();
        
        if (currentPage >= totalPages) {
          currentPage = totalPages - 1;
          if (currentPage < 0) currentPage = 0;
          
          if (currentPage == 0) {
            currentView = CatalogView.intro;
          } else if (currentPage == 1) {
            currentView = CatalogView.catalogIndex;
          } else {
            currentView = CatalogView.products;
          }
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המוצר נמחק בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה במחיקת המוצר'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> addProduct(Product newProduct) async {
    final currentPageBeforeAdd = currentPage;
    final currentViewBeforeAdd = currentView;
    final hasSearchQuery = searchController.text.isNotEmpty;
    
    allProducts.add(newProduct);
    final success = await ProductService.saveProductsToFile(allProducts);
    
    setState(() {
      catalogIndex = CatalogIndex.fromProducts(allProducts);
      
      if (hasSearchQuery) {
        filteredProducts = ProductService.filterProducts(allProducts, searchController.text);
      } else {
        filteredProducts = List.from(allProducts);
      }
      
      currentPage = currentPageBeforeAdd;
      currentView = currentViewBeforeAdd;
      calculateTotalPages();
    });
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המוצר נוסף בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בשמירת המוצר'), backgroundColor: Colors.red),
        );
      }
    }
  }
}