import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _featuredImageController =
      TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final List<TextEditingController> _imageControllers = [];
  String _selectedCategory = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with at least one image controller
    _imageControllers.add(TextEditingController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      // Load categories if not already loaded
      if (productProvider.categories.isEmpty ||
          productProvider.categories.length == 1) {
        productProvider.loadCategories();
      }

      // Set default category
      if (productProvider.categories.isNotEmpty &&
          productProvider.categories.length > 1) {
        setState(() {
          _selectedCategory =
              productProvider.categories[1]; // First category after 'All'
        });
      }
    });

    // If editing an existing product, populate form fields
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description;
      _featuredImageController.text = widget.product!.featuredImage;
      _colorController.text = widget.product!.color;
      _quantityController.text = widget.product!.quantity.toString();
      _selectedCategory = widget.product!.category;

      // Clear default image controller if we have images
      if (widget.product!.images.isNotEmpty) {
        _imageControllers.clear();

        // Add a controller for each image URL
        for (var imageUrl in widget.product!.images) {
          final controller = TextEditingController(text: imageUrl);
          _imageControllers.add(controller);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _featuredImageController.dispose();
    _colorController.dispose();
    _quantityController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    if (_imageControllers.length > 1) {
      setState(() {
        _imageControllers[index].dispose();
        _imageControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final images = _imageControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final product = ProductModel(
        docId: widget.product?.docId ?? '',
        id: widget.product?.id ?? 0,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        color: _colorController.text.trim(),
        featuredImage: _featuredImageController.text.trim(),
        images: images,
        rating: widget.product?.rating ?? 0,
        reviewCount: widget.product?.reviewCount ?? 0,
        quantity: int.parse(_quantityController.text.trim()),
      );

      bool success;
      if (widget.product == null) {
        // Add new product
        success = await productProvider.addProduct(product);
      } else {
        // Update existing product
        success = await productProvider.updateProduct(product);
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product added successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'An error occurred'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add New Product' : 'Edit Product',
          style: const TextStyle(color: AppColors.textPrimaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryColor,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    _buildFormField(
                      label: 'Product Name',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Category in a row for larger screens
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPriceField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildQuantityField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildCategoryDropdown()),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceField(),
                              const SizedBox(height: 16),
                              _buildQuantityField(),
                              const SizedBox(height: 16),
                              _buildCategoryDropdown(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildFormField(
                      label: 'Product Description',
                      controller: _descriptionController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product description';
                        }
                        return null;
                      },
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // Color
                    _buildFormField(
                      label: 'Color (hex code or name)',
                      controller: _colorController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a color';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Featured Image
                    _buildFormField(
                      label: 'Featured Image URL',
                      controller: _featuredImageController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a featured image URL';
                        }
                        if (!Uri.tryParse(value)!.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Additional Images section
                    const Text(
                      'Additional Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ..._buildImageFields(),

                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addImageField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Image URL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryColor,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            widget.product == null
                                ? 'Add Product'
                                : 'Update Product',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Please enter a valid price';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryBackgroundColor,
            prefixText: 'PKR ',
            prefixStyle: const TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a quantity';
            }
            if (int.tryParse(value) == null || int.parse(value) < 0) {
              return 'Please enter a valid quantity';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = Provider.of<ProductProvider>(context).categories;
    final dropdownCategories = categories.isEmpty || categories.length <= 1
        ? ['Sofas', 'Tables', 'Chairs', 'Beds', 'Cabinets', 'Decoration']
        : categories.where((c) => c != 'All').toList();

    // Set default category if none selected and categories are available
    if (_selectedCategory.isEmpty && dropdownCategories.isNotEmpty) {
      _selectedCategory = dropdownCategories[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
              isExpanded: true,
              hint: const Text('Select Category'),
              items: dropdownCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildImageFields() {
    return List.generate(
      _imageControllers.length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _imageControllers[index],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.secondaryBackgroundColor,
                  hintText: 'Image URL ${index + 1}',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusS),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!Uri.tryParse(value)!.isAbsolute) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.remove_circle,
                color: Colors.red,
              ),
              onPressed: () => _removeImageField(index),
            ),
          ],
        ),
      ),
    );
  }
}
