import 'dart:math'; // For min/max functions
import 'dart:io'; // Add this import for Process and Platform
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import

import 'package:a_s_office_web/widgets/CustomGrid.dart';
import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/services/product_service.dart';
import 'package:a_s_office_web/services/pdf_service.dart';
import 'package:a_s_office_web/widgets/ProductCard.dart';
import 'package:a_s_office_web/widgets/SearchBarWidget.dart';
import 'package:a_s_office_web/Screens/ProductEditPage.dart';
import 'package:a_s_office_web/model/CatalogIntro.dart';
import 'package:flutter/services.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
  
}
  enum CatalogView { intro, catalogIndex, products }
class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;

  // Pagination state
  int _currentPage = 0; // Start with 0 for intro page
  int _totalPages = 0;
  static const int _rowsPerPage = 2;

  // View modes
  CatalogView _currentView = CatalogView.intro;

  // Catalog intro data
  late CatalogIntro _catalogIntro;
  late CatalogIndex _catalogIndex;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeCatalogIntro();
    _searchController.addListener(_onSearchChanged);
    // Start with intro page
    _currentPage = 0;
    _currentView = CatalogView.intro;
  }

  void _initializeCatalogIntro() {
    _catalogIntro = CatalogIntro(
      title: 'אמין סבאח \n ס.א ציוד משרדי ופרסום',
      subtitle: 'פתרונות מקצועיים לכל צרכי המשרד',
      description: 'ברוכים הבאים לקטלוג המוצרים שלנו. כאן תמצאו מגוון רחב של מוצרי משרד איכותיים במחירים תחרותיים.',
      features: [
        'מוצרים איכותיים ממותגים מובילים',
        'מתנות לעובדים וללקוחות',
        'מחירים תחרותיים',
        'משלוח מהיר',
        'שירות לקוחות מקצועי',
        'אחריות מלאה על כל המוצרים',
      ],
      contactInfo: 'טלפון: 0507715891 | אימייל: a.s.office.paper@gmail.com \n טלפון פקס: 04-6024177',
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _loadProducts() async {
    final products = await ProductService.loadProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = List.from(_allProducts);
      _catalogIndex = CatalogIndex.fromProducts(_allProducts);
      _isLoading = false;
      _calculateTotalPages();
    });
  }

  void _calculateTotalPages() {
    if (_filteredProducts.isEmpty) {
      _totalPages = 2; // Intro + Index pages only
    } else {
      // Find the maximum page number in the products
      final maxProductPage = _filteredProducts.map((p) => p.pageNumber).fold(0, max);
      // Total pages = max product page (since intro=page 1, index=page 2, products start at page 3)
      _totalPages = maxProductPage;
    }
  }

  void _navigateToPage(int pageNumber) {
    setState(() {
      _currentPage = pageNumber;
      if (_currentPage == 0) {
        _currentView = CatalogView.intro;
      } else if (_currentPage == 1) {
        _currentView = CatalogView.catalogIndex;
      } else {
        _currentView = CatalogView.products;
      }
    });
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _filterProducts() {
    final query = _searchController.text;
    setState(() {
      _filteredProducts = ProductService.filterProducts(_allProducts, query);
      
      // If there's a search query, switch to products view and skip intro/index
      if (query.isNotEmpty) {
        _currentView = CatalogView.products;
        // Don't change _currentPage when searching - we'll show all results
      } else {
        // If search is cleared, go back to intro page
        _currentPage = 0;
        _currentView = CatalogView.intro;
      }
      
      _calculateTotalPages();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    // When clearing search, don't automatically reset to intro page
    // Instead, stay on current page if it's valid, or go to first product page
    setState(() {
      _filteredProducts = List.from(_allProducts);
      _calculateTotalPages();
      
      // If current page is still valid, keep it
      if (_currentPage < _totalPages) {
        // Update view based on current page
        if (_currentPage == 0) {
          _currentView = CatalogView.intro;
        } else if (_currentPage == 1) {
          _currentView = CatalogView.catalogIndex;
        } else {
          _currentView = CatalogView.products;
        }
      } else {
        // If current page is invalid, go to first product page (page 2 = products)
        if (_totalPages > 2) {
          _currentPage = 2; // First product page
          _currentView = CatalogView.products;
        } else {
          _currentPage = 0;
          _currentView = CatalogView.intro;
        }
      }
    });
  }

  bool _isBigScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  // Gets products for a specific page
  List<Product> _getProductsForPage(int displayPageNumber) {
    // displayPageNumber comes from _currentPage + 1
    // _currentPage starts at 0 for intro, 1 for index, 2 for first product page
    // So when _currentPage = 2, displayPageNumber = 3
    // We want to show products with pageNumber = 3
    
    // The actual page number in the product data should match the display page number
    final actualPageNumber = displayPageNumber;
    
    return _filteredProducts
        .where((product) => product.pageNumber == actualPageNumber)
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
      // Store current state before updating
      final currentPageBeforeUpdate = _currentPage;
      final currentViewBeforeUpdate = _currentView;
      final hasSearchQuery = _searchController.text.isNotEmpty;
      
      setState(() {
        final index = _allProducts.indexWhere((p) => p.productID == updatedProduct.productID);
        if (index != -1) {
          _allProducts[index] = updatedProduct;
          
          // Update filtered products without changing current page/view
          if (hasSearchQuery) {
            // If we're searching, just update the filtered list
            _filteredProducts = ProductService.filterProducts(_allProducts, _searchController.text);
          } else {
            // If not searching, update filtered products but preserve current state
            _filteredProducts = List.from(_allProducts);
          }
          
          // Preserve the current page and view
          _currentPage = currentPageBeforeUpdate;
          _currentView = currentViewBeforeUpdate;
          
          // Recalculate total pages
          _calculateTotalPages();
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המוצר עודכן בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        // Show detailed error information
        _showDetailedError('עדכון מוצר', 'שגיאה בעדכון המוצר');
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final success = await ProductService.deleteProduct(_allProducts, product.productID);
    if (success) {
      // Store current state before deleting
      final currentPageBeforeDelete = _currentPage;
      final currentViewBeforeDelete = _currentView;
      final hasSearchQuery = _searchController.text.isNotEmpty;
      
      setState(() {
        _allProducts.removeWhere((p) => p.productID == product.productID);
        
        // Update catalog index with remaining products
        _catalogIndex = CatalogIndex.fromProducts(_allProducts);
        
        // Update filtered products without changing current page/view
        if (hasSearchQuery) {
          // If we're searching, just update the filtered list
          _filteredProducts = ProductService.filterProducts(_allProducts, _searchController.text);
        } else {
          // If not searching, update filtered products but preserve current state
          _filteredProducts = List.from(_allProducts);
        }
        
        // Preserve the current page and view, but adjust if current page is now empty
        _currentPage = currentPageBeforeDelete;
        _currentView = currentViewBeforeDelete;
        
        // Recalculate total pages
        _calculateTotalPages();
        
        // If current page is now beyond total pages, go to last page
        if (_currentPage >= _totalPages) {
          _currentPage = _totalPages - 1;
          if (_currentPage < 0) _currentPage = 0;
          
          // Update view based on new current page
          if (_currentPage == 0) {
            _currentView = CatalogView.intro;
          } else if (_currentPage == 1) {
            _currentView = CatalogView.catalogIndex;
          } else {
            _currentView = CatalogView.products;
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
        // Show detailed error information
        _showDetailedError('מחיקת מוצר', 'שגיאה במחיקת המוצר');
      }
    }
  }

  void _addNewProduct() {
    // When in search mode, add to a default page (page 3, first product page)
    int defaultPage = _searchController.text.isNotEmpty ? 3 : max(3, _currentPage + 3);
    int defaultRow = 1;
    
    // Find the next available row in the target page
    final productsInTargetPage = _allProducts.where((p) => p.pageNumber == defaultPage).toList();
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
      pageNumber: defaultPage, // Start from page 3
      rowInPage: defaultRow,
      height: 160.0,
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

  // New method to add product to specific page
  void _addProductToPage(int pageNumber) {
    // Find the next available row in the target page
    final productsInTargetPage = _allProducts.where((p) => p.pageNumber == pageNumber).toList();
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
          onSave: _addProduct, 
          isNewProduct: true,
        ),
      ),
    );
  }

  Future<void> _addProduct(Product newProduct) async {
    // Store current state before adding
    final currentPageBeforeAdd = _currentPage;
    final currentViewBeforeAdd = _currentView;
    final hasSearchQuery = _searchController.text.isNotEmpty;
    
    _allProducts.add(newProduct);
    final success = await ProductService.saveProductsToFile(_allProducts);
    
    setState(() {
      // Update catalog index with new products
      _catalogIndex = CatalogIndex.fromProducts(_allProducts);
      
      // Update filtered products without changing current page/view
      if (hasSearchQuery) {
        // If we're searching, just update the filtered list
        _filteredProducts = ProductService.filterProducts(_allProducts, _searchController.text);
      } else {
        // If not searching, update filtered products but preserve current state
        _filteredProducts = List.from(_allProducts);
      }
      
      // Preserve the current page and view
      _currentPage = currentPageBeforeAdd;
      _currentView = currentViewBeforeAdd;
      
      // Recalculate total pages
      _calculateTotalPages();
    });
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המוצר נוסף בהצלחה'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        // Show detailed error information
        _showDetailedError('הוספת מוצר', 'שגיאה בשמירת המוצר');
      }
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
      floatingActionButton: (_currentView == CatalogView.products || _searchController.text.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: _addNewProduct,
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('הוסף מוצר'),
            )
          : null,
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
                //_buildPageIndicator(),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                _buildCurrentView(),
                _buildNavigationControls(),
              ],
            ),
    );
  }

  Widget _buildCurrentView() {
    // When searching, always show search results regardless of current view
    if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }
    
    // Always use the same logic for all views - no special cases
    switch (_currentView) {
      case CatalogView.intro:
      case CatalogView.catalogIndex:
      case CatalogView.products:
        return _buildPageGrid();
    }
  }

  // Single method to handle all page types (intro, index, and products)
  Widget _buildPageGrid() {
    if (_isBigScreen(context)) {
      // For big screens, show current page and next page side by side
      final currentDisplayPage = _currentPage + 1;
      final nextDisplayPage = currentDisplayPage + 1;
      
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: MediaQuery.of(context).size.height - 300,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT SIDE: Next page (higher number)
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
                          child: _buildPageContent(nextDisplayPage),
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
                            'עמוד $nextDisplayPage',
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
                // RIGHT SIDE: Current page
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
                          child: _buildPageContent(currentDisplayPage),
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
                            'עמוד $currentDisplayPage',
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
      final currentDisplayPage = _currentPage + 1;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: MediaQuery.of(context).size.height - 300,
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
                  child: _buildPageContent(currentDisplayPage),
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
                    'עמוד $currentDisplayPage',
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
      );
    }
  }

  // Single method to build content for any page type
  Widget _buildPageContent(int displayPageNumber) {
    if (displayPageNumber == 1) {
      // Intro page content
      return _buildIntroPageContent();
    } else if (displayPageNumber == 2) {
      // Index page content
      return _buildIndexPageContent();
    } else {
      // Product page content
      final products = _getProductsForPage(displayPageNumber);
      return _buildGridForSinglePage(products, displayPageNumber);
    }
  }

  Widget _buildPageIndicator() {
    // Hide page indicator when searching
    if (_searchController.text.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'תוצאות חיפוש: "${_searchController.text}"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  'נמצאו ${_filteredProducts.length} מוצרים',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Simple page title based on current page
    String pageTitle;
    final currentDisplayPage = _currentPage + 1;
    if (currentDisplayPage == 1) {
      pageTitle = 'מבוא לקטלוג';
    } else if (currentDisplayPage == 2) {
      pageTitle = 'תוכן עניינים';
    } else {
      pageTitle = 'עמוד $currentDisplayPage - מוצרים';
    }

    // Show range for big screens
    if (_isBigScreen(context)) {
      final nextDisplayPage = currentDisplayPage + 1;
      if (nextDisplayPage <= _totalPages) {
        String nextTitle;
        if (nextDisplayPage == 1) {
          nextTitle = 'מבוא';
        } else if (nextDisplayPage == 2) {
          nextTitle = 'תוכן עניינים';
        } else {
          nextTitle = 'עמוד $nextDisplayPage';
        }
        pageTitle = '$pageTitle | $nextTitle';
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pageTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                _isBigScreen(context) && _currentPage + 2 <= _totalPages
                    ? 'עמודים ${_currentPage + 1}-${_currentPage + 2} מתוך $_totalPages'
                    : 'עמוד ${_currentPage + 1} מתוך $_totalPages',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simplify navigation controls
  Widget _buildNavigationControls() {
    // Hide navigation controls when searching
    if (_searchController.text.isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    bool canGoNext = _currentPage < _totalPages - 1;
    bool canGoPrevious = _currentPage > 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          children: [
            // Next button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoNext ? () => _navigateToPage(_currentPage + 1) : null,
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
                  value: _currentPage,
                  decoration: const InputDecoration(
                    labelText: 'קפוץ לעמוד',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(_totalPages, (index) {
                    String label;
                    if (index == 0) label = 'מבוא (עמוד 1)';
                    else if (index == 1) label = 'תוכן עניינים (עמוד 2)';
                    else label = 'עמוד ${index + 1}';
                    return DropdownMenuItem(value: index, child: Text(label));
                  }),
                  onChanged: (value) {
                    if (value != null) _navigateToPage(value);
                  },
                ),
              ),
            
            const SizedBox(width: 16),
            // Previous button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoPrevious ? () => _navigateToPage(_currentPage - 1) : null,
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

  // Add this method
  Future<void> _generatePdf() async {
    try {
      // Don't show a loading dialog here - PdfService already shows one
      await PdfService.generateCatalogPdf(_allProducts, context);
      print('PDF generated successfully');
    } catch (e) {
      print('Error in _generatePdf: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה ביצירת הקטלוג: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this method to open file location
  Future<void> _openFileLocation() async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('פתיחת מיקום קובץ לא זמינה בגרסת הווב'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get system info to find the file location
      final systemInfo = await ProductService.getSystemInfo();
      final appDirectory = systemInfo['appDirectory'] as String?;
      
      if (appDirectory == null) {
        throw Exception('לא ניתן למצוא את תיקיית האפליקציה');
      }

      // Check if directory exists
      final directory = Directory(appDirectory);
      if (!await directory.exists()) {
        throw Exception('תיקיית האפליקציה לא קיימת: $appDirectory');
      }

      // Open file explorer based on platform
      if (Platform.isWindows) {
        await Process.run('explorer', [appDirectory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [appDirectory]);
      } else if (Platform.isLinux) {
        // Try different file managers
        try {
          await Process.run('xdg-open', [appDirectory]);
        } catch (e) {
          try {
            await Process.run('nautilus', [appDirectory]);
          } catch (e) {
            try {
              await Process.run('dolphin', [appDirectory]);
            } catch (e) {
              throw Exception('לא ניתן לפתוח את סייר הקבצים');
            }
          }
        }
      } else {
        throw Exception('פלטפורמה לא נתמכת: ${Platform.operatingSystem}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('נפתח סייר קבצים: $appDirectory'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error opening file location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת מיקום הקובץ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add method to show file info dialog
  Future<void> _showFileInfo() async {
    try {
      final systemInfo = await ProductService.getSystemInfo();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('מידע על קבצי הנתונים'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow('פלטפורמה', systemInfo['platform']?.toString() ?? 'לא ידוע'),
                  _buildInfoRow('תיקיית מסמכים', systemInfo['documentsDirectory']?.toString() ?? 'לא נמצאה'),
                  _buildInfoRow('תיקיית האפליקציה', systemInfo['appDirectory']?.toString() ?? 'לא נמצאה'),
                  _buildInfoRow('קובץ נתונים', systemInfo['dataFilePath']?.toString() ?? 'לא נמצא'),
                  _buildInfoRow('קובץ קיים', systemInfo['dataFileExists'] == true ? 'כן' : 'לא'),
                  if (systemInfo['dataFileSize'] != null)
                    _buildInfoRow('גודל קובץ', '${systemInfo['dataFileSize']} בייטים'),
                  if (systemInfo['dataFileLastModified'] != null)
                    _buildInfoRow('עודכן לאחרונה', systemInfo['dataFileLastModified'].toString()),
                  _buildInfoRow('תיקיית גיבויים', systemInfo['historyDirectory']?.toString() ?? 'לא נמצאה'),
                  _buildInfoRow('גיבויים זמינים', systemInfo['backupFilesCount']?.toString() ?? '0'),
                  _buildInfoRow('הרשאות כתיבה', systemInfo['canWrite'] == true ? 'כן' : 'לא'),
                ],
              ),
            ),
            actions: [
              if (!kIsWeb) ...[
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openFileLocation();
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('פתח תיקייה'),
                ),
              ],
              TextButton.icon(
                onPressed: () async {
                  final infoText = systemInfo.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n');
                  
                  await Clipboard.setData(ClipboardData(text: infoText));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('מידע הועתק ללוח'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('העתק מידע'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('סגור'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בקבלת מידע על הקובץ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 60.0,
      floating: false, pinned: true,
      backgroundColor: Colors.blue[600],
      centerTitle: true,
      actions: [
        const Spacer(),
        // File info button
        IconButton(
          onPressed: _showFileInfo,
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'מידע על קבצי הנתונים',
        ),
        const SizedBox(width: 8),
        // Open file location button
        if (!kIsWeb) // Only show on desktop platforms
          IconButton(
            onPressed: _openFileLocation,
            icon: const Icon(Icons.folder_open, color: Colors.white),
            tooltip: 'פתח מיקום קבצי הנתונים',
          ),
        if (!kIsWeb) const SizedBox(width: 8),
        // PDF generation button
        IconButton(
          onPressed: _generatePdf,
          icon: const Icon(Icons.print, color: Colors.white),
          tooltip: 'הדפס קטלוג',
        ),
        const SizedBox(width: 8),
        const Spacer(),
      ],
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
              onPressed: () => _addProductToPage(pageNumber),
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

  // Extract the intro page content (without the SliverToBoxAdapter wrapper)
  Widget _buildIntroPageContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title
          Text(
            _catalogIntro.title,
            style: TextStyle(
              fontSize: 32, // Increased from 20
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12), // Increased spacing
          // Subtitle
          Text(
            _catalogIntro.subtitle,
            style: TextStyle(
              fontSize: 24, // Increased from 16
              color: Colors.blue[600],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24), // Increased spacing
          // Description
          Text(
            _catalogIntro.description,
            style: const TextStyle(fontSize: 18), // Increased from 12
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 24), // Increased spacing
          // Features
          Text(
            'מה אנחנו מציעים:',
            style: TextStyle(
              fontSize: 20, // Increased from 14
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12), // Increased spacing
          ..._catalogIntro.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Increased spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 16), // Increased from 11
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.green[600], size: 20), // Increased icon size
              ],
            ),
          )),
          const SizedBox(height: 24), // Increased spacing
          // Contact info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // Increased padding
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
                    fontSize: 18, // Increased from 12
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  _catalogIntro.contactInfo,
                  style: const TextStyle(fontSize: 16), // Increased from 10
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Last updated
          Text(
            'עודכן לאחרונה: ${_catalogIntro.lastUpdated.day}/${_catalogIntro.lastUpdated.month}/${_catalogIntro.lastUpdated.year}',
            style: TextStyle(
              fontSize: 14, // Increased from 9
              color: Colors.grey[600],
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // Extract the index page content (without the SliverToBoxAdapter wrapper)
  Widget _buildIndexPageContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title
          Text(
            'תוכן עניינים',
            style: TextStyle(
              fontSize: 20, // Reduced for side-by-side view
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          // Index entries with correct page numbers
          _buildIndexEntryCompact('מבוא לקטלוג', 1, () => _navigateToPage(0)),
          _buildIndexEntryCompact('תוכן עניינים', 2, () => _navigateToPage(1)),
          const Divider(),
          ..._catalogIndex.sections.map((section) => 
            _buildIndexEntryCompact(
              section.title + ' (${section.productCount} מוצרים)',
              section.pageNumber, // This is the actual page number (3, 4, 5...)
              () => _navigateToPage(section.pageNumber - 1), // Convert to internal page number (2, 3, 4...)
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
                  'סך הכל: ${_allProducts.length} מוצרים ב-${_catalogIndex.sections.length} עמודים',
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

  // Compact version of index entry for side-by-side view
  Widget _buildIndexEntryCompact(String title, int pageNum, VoidCallback onTap) {
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

  // Add this method to show detailed error information
  Future<void> _showDetailedError(String operation, String basicMessage) async {
    try {
      final systemInfo = await ProductService.getSystemInfo();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                SizedBox(width: 8),
                Text('שגיאה ב$operation'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    basicMessage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'פרטים טכניים:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פלטפורמה: ${systemInfo['platform'] ?? 'לא ידוע'}'),
                        Text('ספריית מסמכים: ${systemInfo['documentsDirectory'] ?? 'לא נמצאה'}'),
                        Text('תיקיית האפליקציה: ${systemInfo['appDirectory'] ?? 'לא נמצאה'}'),
                        Text('קובץ נתונים: ${systemInfo['dataFilePath'] ?? 'לא נמצא'}'),
                        Text('קובץ קיים: ${systemInfo['dataFileExists'] ?? false ? 'כן' : 'לא'}'),
                        Text('הרשאות כתיבה: ${systemInfo['canWrite'] ?? false ? 'כן' : 'לא'}'),
                        if (systemInfo['writeError'] != null)
                          Text('שגיאת כתיבה: ${systemInfo['writeError']}'),
                        if (systemInfo['dataFileSize'] != null)
                          Text('גודל קובץ: ${systemInfo['dataFileSize']} בייטים'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'פתרונות אפשריים:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• הרץ את האפליקציה כמנהל מערכת\n'
                    '• וודא שאין הגנת וירוסים חוסמת\n'
                    '• בדוק שיש מקום פנוי בדיסק\n'
                    '• נסה לסגור ולפתוח מחדש את האפליקציה',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final info = await ProductService.getSystemInfo();
                  final infoText = info.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n');
                  
                  await Clipboard.setData(ClipboardData(text: infoText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('פרטים טכניים הועתקו ללוח'),
                      backgroundColor: Colors.blue[600],
                    ),
                  );
                },
                icon: Icon(Icons.copy),
                label: Text('העתק פרטים'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('סגור'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Fallback if even the detailed error fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$basicMessage\nשגיאה טכנית: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}