// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/promotion_model.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/sidebar.dart';
import 'add_edit_promotion_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  _PromotionsScreenState createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 9; // Adjust based on sidebar position

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PromotionProvider>(context, listen: false).loadPromotions();
    });
  }

  void _addPromotion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPromotionScreen(),
      ),
    );
  }

  void _editPromotion(PromotionModel promotion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPromotionScreen(promotion: promotion),
      ),
    );
  }

  Future<void> _deletePromotion(PromotionModel promotion) async {
    // Confirm delete
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete "${promotion.promotionName}"?'),
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
      final promotionProvider =
          Provider.of<PromotionProvider>(context, listen: false);
      final success = await promotionProvider.deletePromotion(promotion.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotion deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                promotionProvider.errorMessage ?? 'Failed to delete promotion'),
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
    final promotionProvider = Provider.of<PromotionProvider>(context);
    final promotions = promotionProvider.promotions;

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
                            'Promotions',
                            style: AppTextStyles.h2,
                          ),
                        ],
                      ),
                      // Add promotion button
                      if (!isMobile)
                        ElevatedButton.icon(
                          onPressed: _addPromotion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Promotion'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),

                // Promotions content
                Expanded(
                  child: promotionProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : promotions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_offer_outlined,
                                    size: 64,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No promotions found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add your first promotion to get started',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _addPromotion,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Promotion'),
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
                                itemCount: promotions.length,
                                itemBuilder: (context, index) {
                                  final promotion = promotions[index];
                                  return _buildPromotionCard(promotion);
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

  Widget _buildPromotionCard(PromotionModel promotion) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4, top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promotion image
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: promotion.imageUrls.isNotEmpty
                    ? Image.network(
                        promotion.imageUrls[0],
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
                      )
                    : Container(
                        color: AppColors.secondaryBackgroundColor,
                        child: const Center(
                          child: Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.textSecondaryColor,
                            size: 40,
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
                      _editPromotion(promotion);
                    } else if (value == 'delete') {
                      _deletePromotion(promotion);
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
              // Discount badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${promotion.discount.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Promotion details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotion name
                Text(
                  promotion.promotionName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Duration
                Text(
                  promotion.duration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  children: [
                    Text(
                      'PKR ${promotion.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PKR ${(promotion.price * (1 - promotion.discount / 100)).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
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
