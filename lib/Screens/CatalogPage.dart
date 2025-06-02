import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/services/product_service.dart';
import 'package:a_s_office_web/widgets/ProductCard.dart';
import 'package:a_s_office_web/widgets/CustomGrid.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    final products = await ProductService.loadProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = ProductService.filterProducts(
        _allProducts,
        _searchController.text,
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          product: product,
          onSave: _updateProduct,
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
        const SnackBar(
          content: Text('המוצר עודכן בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה בעדכון המוצר'),
          backgroundColor: Colors.red,
        ),
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
        const SnackBar(
          content: Text('המוצר נמחק בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה במחיקת המוצר'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewProduct() {
    // Create a new empty product for adding
    final newProduct = Product(
      productID: DateTime.now().millisecondsSinceEpoch, // Generate unique ID
      productName: '',
      productPrice: 0.0,
      productCapacity: 0,
      imagePath: '',
      dateAdded: DateTime.now().toIso8601String(),
      description: '',
      totalQuantitySold: 0,
      buyers: [],
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
    setState(() {
      _allProducts.add(newProduct);
      _filterProducts();
    });
    
    final success = await ProductService.saveProductsToFile(_allProducts);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('המוצר נוסף בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה בהוספת המוצר'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('הוסף מוצר'),
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
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue[600],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'קטלוג מוצרים',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithResponsiveColumns(
          minColumnWidth: 300,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
            return ProductCard(
              product: product,
              onTap: () => _editProduct(product),
              onDelete: () => _deleteProduct(product),
            );
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }
}