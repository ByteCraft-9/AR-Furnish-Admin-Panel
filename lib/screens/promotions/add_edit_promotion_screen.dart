import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../models/promotion_model.dart';
import '../../providers/promotion_provider.dart';

class AddEditPromotionScreen extends StatefulWidget {
  final PromotionModel? promotion;

  const AddEditPromotionScreen({super.key, this.promotion});

  @override
  State<AddEditPromotionScreen> createState() => _AddEditPromotionScreenState();
}

class _AddEditPromotionScreenState extends State<AddEditPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final List<TextEditingController> _imageControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with at least one image controller
    _imageControllers.add(TextEditingController());

    // If editing an existing promotion, populate form fields
    if (widget.promotion != null) {
      _nameController.text = widget.promotion!.promotionName;
      _priceController.text = widget.promotion!.price.toString();
      _discountController.text = widget.promotion!.discount.toString();
      _durationController.text = widget.promotion!.duration;

      // Clear default image controller if we have images
      if (widget.promotion!.imageUrls.isNotEmpty) {
        _imageControllers.clear();

        // Add a controller for each image URL
        for (var imageUrl in widget.promotion!.imageUrls) {
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
    _discountController.dispose();
    _durationController.dispose();
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

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final promotionProvider =
          Provider.of<PromotionProvider>(context, listen: false);
      final imageUrls = _imageControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final promotion = PromotionModel(
        id: widget.promotion?.id ?? '',
        promotionName: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        discount: double.parse(_discountController.text.trim()),
        duration: _durationController.text.trim(),
        imageUrls: imageUrls,
      );

      bool success;
      if (widget.promotion == null) {
        // Add new promotion
        success = await promotionProvider.addPromotion(promotion);
      } else {
        // Update existing promotion
        success = await promotionProvider.updatePromotion(promotion);
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.promotion == null
                  ? 'Promotion added successfully'
                  : 'Promotion updated successfully',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(promotionProvider.errorMessage ?? 'An error occurred'),
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
          widget.promotion == null ? 'Add New Promotion' : 'Edit Promotion',
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
                    // Promotion name
                    _buildFormField(
                      label: 'Promotion Name',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a promotion name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Discount in a row for larger screens
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPriceField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDiscountField()),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceField(),
                              const SizedBox(height: 16),
                              _buildDiscountField(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration
                    _buildFormField(
                      label: 'Duration (e.g., "Valid until Dec 31, 2023")',
                      controller: _durationController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a duration';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Image URLs section
                    const Text(
                      'Promotion Images',
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
                          onPressed: _savePromotion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            widget.promotion == null
                                ? 'Add Promotion'
                                : 'Update Promotion',
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
          'Original Price',
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

  Widget _buildDiscountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount Percentage',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a discount';
            }
            final discount = double.tryParse(value);
            if (discount == null || discount <= 0 || discount > 100) {
              return 'Discount must be between 1-100%';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryBackgroundColor,
            suffixText: '%',
            suffixStyle: const TextStyle(
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
