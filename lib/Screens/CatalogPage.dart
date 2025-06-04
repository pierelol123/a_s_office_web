import 'dart:math'; // For min/max functions

import 'package:a_s_office_web/widgets/CustomGrid.dart';
import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/services/product_service.dart';
import 'package:a_s_office_web/services/pdf_service.dart'; // Add this import
import 'package:a_s_office_web/widgets/ProductCard.dart';
import 'package:a_s_office_web/widgets/SearchBarWidget.dart';
import 'package:a_s_office_web/Screens/ProductEditPage.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;

  // Pagination state
  int _currentPage = 1; // 1-indexed page numbers
  int _totalPages = 0;
  static const int _rowsPerPage = 2; // 2 rows per page

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProducts() async {
    final products = await ProductService.loadProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = List.from(_allProducts);
      _isLoading = false;
      _currentPage = 1;
      _calculateTotalPages();
    });
  }

  void _calculateTotalPages() {
    if (_filteredProducts.isEmpty) {
      _totalPages = 0;
    } else {
      final maxPage = _filteredProducts.map((p) => p.pageNumber).fold(0, max);
      _totalPages = maxPage;
    }
    // Ensure _currentPage is valid after recalculation
    if (_currentPage > _totalPages && _totalPages > 0) {
      _currentPage = _totalPages;
    } else if (_totalPages == 0) {
      _currentPage = 1;
    }
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _filterProducts() {
    final query = _searchController.text;
    setState(() {
      _filteredProducts = ProductService.filterProducts(_allProducts, query);
      _currentPage = 1;
      _calculateTotalPages();
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  bool _isBigScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  // Gets products for a specific page
  List<Product> _getProductsForPage(int pageNumber) {
    return _filteredProducts
        .where((product) => product.pageNumber == pageNumber)
        .toList()
      ..sort((a, b) => a.rowInPage.compareTo(b.rowInPage));
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          product: product,
          onSave: _updateProduct,
          isNewProduct: false,
        ),
      ),
    );
  }

  Future<void> _updateProduct(Product updatedProduct) async {
    final success = await ProductService.updateProduct(_allProducts, updatedProduct);
    if (success) {
      setState(() {
        final index = _allProducts.indexWhere((p) => p.productID == updatedProduct.productID);
        if (index != -1) {
          _allProducts[index] = updatedProduct;
          _filterProducts();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('המוצר עודכן בהצלחה'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בעדכון המוצר'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final success = await ProductService.deleteProduct(_allProducts, product.productID);
    if (success) {
      setState(() {
        _allProducts.removeWhere((p) => p.productID == product.productID);
        _filterProducts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('המוצר נמחק בהצלחה'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה במחיקת המוצר'), backgroundColor: Colors.red),
      );
    }
  }

  void _addNewProduct() {
    // Use the current page as default
    int defaultPage = _currentPage;
    int defaultRow = 1;
    
    // Find the next available row in the current page
    final productsInCurrentPage = _allProducts.where((p) => p.pageNumber == _currentPage).toList();
    if (productsInCurrentPage.isNotEmpty) {
      defaultRow = productsInCurrentPage.map((p) => p.rowInPage).fold(0, max) + 1;
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
      pageNumber: defaultPage, // Default to current page
      rowInPage: defaultRow, // Next available row
      height: 160.0, // Default height
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          product: newProduct, 
          onSave: _addProduct, 
          isNewProduct: true,
        ),
      ),
    );
  }

  Future<void> _addProduct(Product newProduct) async {
    _allProducts.add(newProduct);
    final success = await ProductService.saveProductsToFile(_allProducts);
    setState(() {
      _filterProducts();
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('המוצר נוסף בהצלחה'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בשמירת המוצר'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Add product button
          FloatingActionButton.extended(
            onPressed: _addNewProduct,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            heroTag: "add_product", // Unique hero tag
            icon: const Icon(Icons.add),
            label: const Text('הוסף מוצר'),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  controller: _searchController,
                  onClear: _clearSearch,
                ),
              ),
              _buildProductCount(),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildProductGrid(),
              _buildPaginationControls(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
    );
  }

  // Add this method
  Future<void> _generatePdf() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      await PdfService.generateCatalogPdf(_allProducts, context);
      
      // Close loading dialog
      Navigator.of(context).pop();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה ביצירת הקטלוג: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false, pinned: true,
      backgroundColor: Colors.blue[600],
      actions: [
        IconButton(
          onPressed: _generatePdf,
          icon: const Icon(Icons.print, color: Colors.white),
          tooltip: 'הדפס קטלוג',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('קטלוג מוצרים',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCount() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'נמצאו ${_filteredProducts.length} מוצרים',
          style: Theme.of(context).textTheme.titleMedium,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildGridForSinglePage(List<Product> products, int pageNumber) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          "אין מוצרים בעמוד $pageNumber", 
          style: TextStyle(color: Colors.grey[400]),
          textDirection: TextDirection.rtl,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12.0),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          height: product.height, // Use the product's custom height
          margin: const EdgeInsets.only(bottom: 12),
          child: ProductCard(
            product: product,
            onTap: () => _editProduct(product),
            onDelete: () => _deleteProduct(product),
            isCompact: true,
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty && !_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _searchController.text.isNotEmpty
                  ? 'לא נמצאו מוצרים התואמים לחיפוש "${_searchController.text}".'
                  : 'אין מוצרים להצגה כרגע.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center, textDirection: TextDirection.rtl,
            ),
          ),
        ),
      );
    }

    // If there's an active search, show search results in a simple list
    if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }

    // Otherwise, show the normal paginated view
    if (_isBigScreen(context)) {
      final productsForRightPage = _getProductsForPage(_currentPage);
      final productsForLeftPage = _getProductsForPage(_currentPage + 1);

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: MediaQuery.of(context).size.height - 300,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT SIDE: Page (_currentPage + 1)
                Expanded(
                  child: Container(
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
                          child: _buildGridForSinglePage(productsForLeftPage, _currentPage + 1),
                        ),
                        Container(
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
                          child: Text(
                            'עמוד ${_currentPage + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // DIVIDER
                Container(
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
                ),
                // RIGHT SIDE: Page (_currentPage)
                Expanded(
                  child: Container(
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
                          child: _buildGridForSinglePage(productsForRightPage, _currentPage),
                        ),
                        Container(
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
                          child: Text(
                            'עמוד $_currentPage',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Small screen: show single page
      final productsToDisplay = _getProductsForPage(_currentPage);
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = productsToDisplay[index];
              return Container(
                height: product.height,
                margin: const EdgeInsets.only(bottom: 12),
                child: ProductCard(
                  product: product,
                  onTap: () => _editProduct(product),
                  onDelete: () => _deleteProduct(product),
                  isCompact: true,
                ),
              );
            },
            childCount: productsToDisplay.length,
          ),
        ),
      );
    }
  }

  // New method to build search results
  Widget _buildSearchResults() {
    if (_isBigScreen(context)) {
      // For big screen, show search results in a single scrollable list
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: MediaQuery.of(context).size.height - 300,
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
                // Header for search results
                Container(
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
                    'תוצאות חיפוש: "${_searchController.text}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      fontSize: 16,
                    ),
                  ),
                ),
                // Search results list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Container(
                        height: product.height,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ProductCard(
                          product: product,
                          onTap: () => _editProduct(product),
                          onDelete: () => _deleteProduct(product),
                          isCompact: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Small screen search results
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = _filteredProducts[index];
              return Container(
                height: product.height,
                margin: const EdgeInsets.only(bottom: 12),
                child: ProductCard(
                  product: product,
                  onTap: () => _editProduct(product),
                  onDelete: () => _deleteProduct(product),
                  isCompact: true,
                ),
              );
            },
            childCount: _filteredProducts.length,
          ),
        ),
      );
    }
  }

  Widget _buildPaginationControls() {
    // Hide pagination controls when searching
    if (_searchController.text.isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    int pagesToIncrementOrDecrement = _isBigScreen(context) ? 2 : 1;
    
    if (_totalPages == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());
    if (_totalPages == 1 && !_isBigScreen(context)) return const SliverToBoxAdapter(child: SizedBox.shrink());
    if (_totalPages <= 2 && _isBigScreen(context)) return const SliverToBoxAdapter(child: SizedBox.shrink());

    bool canGoPrevious = _currentPage > 1;
    bool canGoNext = (_currentPage + pagesToIncrementOrDecrement) <= _totalPages;

    String pageIndicatorText;
    int firstPageNumInView = _currentPage;
    int lastPageNumInView = min(_currentPage + pagesToIncrementOrDecrement - 1, _totalPages);

    if (_isBigScreen(context) && lastPageNumInView > firstPageNumInView) {
      pageIndicatorText = 'עמודים $firstPageNumInView-$lastPageNumInView מתוך $_totalPages';
    } else {
      pageIndicatorText = 'עמוד $firstPageNumInView מתוך $_totalPages';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: canGoNext
                      ? () {
                          setState(() {
                            _currentPage += pagesToIncrementOrDecrement;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('הבא'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  pageIndicatorText, 
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: canGoPrevious
                      ? () {
                          setState(() {
                            _currentPage = max(1, _currentPage - pagesToIncrementOrDecrement);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('הקודם'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}