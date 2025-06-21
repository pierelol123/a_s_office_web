import 'dart:math';
import 'package:flutter/material.dart';
import 'package:a_s_office_web/model/Product.dart';
import 'package:a_s_office_web/model/CatalogIntro.dart';
import 'package:a_s_office_web/services/product_service.dart';
import 'package:a_s_office_web/services/pdf/pdf_capacity_calculator.dart';

enum CatalogView { intro, catalogIndex, products }

mixin CatalogStateMixin<T extends StatefulWidget> on State<T> {
  // Controllers and state
  final TextEditingController searchController = TextEditingController();
  List<Product> filteredProducts = [];
  List<Product> allProducts = [];
  bool isLoading = true;

  // Pagination state
  int currentPage = 0;
  int totalPages = 0;

  // View modes
  CatalogView currentView = CatalogView.intro;

  // Catalog data
  late CatalogIntro catalogIntro;
  late CatalogIndex catalogIndex;

  @override
  void initState() {
    super.initState();
    loadProducts();
    initializeCatalogIntro();
    searchController.addListener(onSearchChanged);
    currentPage = 0;
    currentView = CatalogView.intro;
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void initializeCatalogIntro() {
    catalogIntro = CatalogIntro(
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

  Future<void> loadProducts() async {
    final products = await ProductService.loadProducts();
    setState(() {
      allProducts = products;
      filteredProducts = List.from(allProducts);
      catalogIndex = CatalogIndex.fromProducts(allProducts);
      isLoading = false;
      calculateTotalPages();
    });
  }

  void calculateTotalPages() {
    if (filteredProducts.isEmpty) {
      totalPages = 2;
    } else {
      final maxProductPage = filteredProducts.map((p) => p.pageNumber).fold(0, max);
      totalPages = maxProductPage;
    }
  }

  void onSearchChanged() {
    filterProducts();
  }

  void filterProducts() {
    final query = searchController.text;
    setState(() {
      filteredProducts = ProductService.filterProducts(allProducts, query);
      
      if (query.isNotEmpty) {
        currentView = CatalogView.products;
      } else {
        currentPage = 0;
        currentView = CatalogView.intro;
      }
      
      calculateTotalPages();
    });
  }

  void clearSearch() {
    searchController.clear();
    setState(() {
      filteredProducts = List.from(allProducts);
      calculateTotalPages();
      
      if (currentPage < totalPages) {
        if (currentPage == 0) {
          currentView = CatalogView.intro;
        } else if (currentPage == 1) {
          currentView = CatalogView.catalogIndex;
        } else {
          currentView = CatalogView.products;
        }
      } else {
        if (totalPages > 2) {
          currentPage = 2;
          currentView = CatalogView.products;
        } else {
          currentPage = 0;
          currentView = CatalogView.intro;
        }
      }
    });
  }

  List<Product> getProductsForPage(int displayPageNumber) {
    final actualPageNumber = displayPageNumber;
    return filteredProducts
        .where((product) => product.pageNumber == actualPageNumber)
        .toList()
      ..sort((a, b) => a.rowInPage.compareTo(b.rowInPage));
  }

  bool isBigScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  // ADD: Method to get PDF capacity for a specific page
  PdfPageCapacity getPdfCapacityForPage(int displayPageNumber) {
    if (displayPageNumber <= 2) {
      // Intro and index pages always fit
      return PdfPageCapacity(
        canFitInSinglePage: true,
        estimatedHeight: 400.0,
        availableHeight: 900.0,
        utilizationPercentage: 44.4,
        productHeights: [],
        warnings: [],
      );
    }
    
    final products = getProductsForPage(displayPageNumber);
    return PdfCapacityCalculator.calculatePageCapacity(products);
  }
  
  // ADD: Method to get capacity for all pages
  Map<int, PdfPageCapacity> getAllPagesCapacity() {
    final capacities = <int, PdfPageCapacity>{};
    
    for (int i = 1; i <= totalPages; i++) {
      capacities[i] = getPdfCapacityForPage(i);
    }
    
    return capacities;
  }
}