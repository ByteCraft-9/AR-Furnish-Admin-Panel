// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/sidebar.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; // Products is the second item in sidebar
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // New status filter

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    if (category == 'All') {
      productProvider.clearFilters();
    } else {
      productProvider.filterByCategory(category);
    }
  }

  // New method to filter by status (enabled/disabled)
  void _filterByStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    if (status == 'All') {
      productProvider.loadProducts();
    } else if (status == 'Enabled') {
      productProvider.loadEnabledProducts();
    } else if (status == 'Disabled') {
      productProvider.loadDisabledProducts();
    }
  }

  // New method to toggle product enabled state
  Future<void> _toggleProductStatus(ProductModel product) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    final newStatus = !product.isEnabled;
    final success = await productProvider.toggleProductEnabledState(
        product.docId, newStatus);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${product.name} is now ${newStatus ? 'enabled' : 'disabled'}'),
          backgroundColor: AppColors.successColor,
        ),
      );
      // Refresh product list based on current filter
      _filterByStatus(_selectedStatus);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.errorMessage ??
              'Failed to update product status'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    );
  }

  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    // Confirm delete
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(product.docId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                productProvider.errorMessage ?? 'Failed to delete product'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.filteredProducts;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context); // Close drawer when item selected
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for desktop/tablet
          if (!isMobile)
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top app bar
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Menu button for mobile
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                            ),
                          const Text(
                            'Products',
                            style: AppTextStyles.h2,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Search box
                          Container(
                            width: isMobile ? 150 : 300,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackgroundColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusS,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search products...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onChanged: _search,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Add product button
                          if (!isMobile)
                            ElevatedButton.icon(
                              onPressed: _addProduct,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Category filters
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: productProvider.categories
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (_) {
                                  _filterByCategory(category);
                                },
                                backgroundColor: AppColors.backgroundColor,
                                selectedColor:
                                    AppColors.primaryColor.withOpacity(0.1),
                                checkmarkColor: AppColors.primaryColor,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == category
                                      ? AppColors.primaryColor
                                      : AppColors.textPrimaryColor,
                                  fontWeight: _selectedCategory == category
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                // Status filters
                Container(
                  padding:
                      const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedStatus == 'All',
                        onSelected: (_) => _filterByStatus('All'),
                        backgroundColor: AppColors.backgroundColor,
                        selectedColor: AppColors.primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _selectedStatus == 'All'
                              ? AppColors.primaryColor
                              : AppColors.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Enabled'),
                        selected: _selectedStatus == 'Enabled',
                        onSelected: (_) => _filterByStatus('Enabled'),
                        backgroundColor: AppColors.backgroundColor,
                        selectedColor: Colors.green.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _selectedStatus == 'Enabled'
                              ? Colors.green
                              : AppColors.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Disabled'),
                        selected: _selectedStatus == 'Disabled',
                        onSelected: (_) => _filterByStatus('Disabled'),
                        backgroundColor: AppColors.backgroundColor,
                        selectedColor: Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _selectedStatus == 'Disabled'
                              ? Colors.red
                              : AppColors.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Products content
                Expanded(
                  child: productProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No products found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    productProvider.searchQuery.isNotEmpty ||
                                            productProvider
                                                .selectedCategory.isNotEmpty
                                        ? 'Try adjusting your search or filters'
                                        : 'Add your first product to get started',
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _addProduct,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Product'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile
                                      ? 1
                                      : screenWidth > 1400
                                          ? 4
                                          : screenWidth > 1000
                                              ? 3
                                              : 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _buildProductCard(product);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4, top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.featuredImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.secondaryBackgroundColor,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondaryColor,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Status badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isEnabled
                        ? Colors.green.withOpacity(0.8)
                        : Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.isEnabled ? 'Enabled' : 'Disabled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: AppColors.textPrimaryColor,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editProduct(product);
                    } else if (value == 'delete') {
                      _deleteProduct(product);
                    } else if (value == 'toggle') {
                      _toggleProductStatus(product);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            product.isEnabled
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: product.isEnabled
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.isEnabled ? 'Disable' : 'Enable',
                            style: TextStyle(
                              color: product.isEnabled
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Product details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Category
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Price and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PKR ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${product.reviewCount})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
