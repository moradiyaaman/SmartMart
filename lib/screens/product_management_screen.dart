import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/admin_service.dart';
import '../models/app_models.dart' as models;
import '../widgets/custom_widgets.dart';
import '../constants/approved_categories.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<models.Product>>(
        stream: _adminService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Products Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add your first product to get started'),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isGrid = constraints.maxWidth >= 720;
              final crossAxisCount = isGrid
                  ? (constraints.maxWidth ~/ 360).clamp(2, 4)
                  : 1;
              final itemSpacing = isGrid ? 16.0 : 12.0;

              if (!isGrid) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: itemSpacing,
                        crossAxisSpacing: itemSpacing,
                        childAspectRatio: 0.95,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return _buildProductCard(product);
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 12),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddProductDialog(),
          label: const Text('Add Product'),
          icon: const Icon(Icons.add),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductCard(models.Product product) {
    final theme = Theme.of(context);
    final priceStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.primaryColor,
      fontWeight: FontWeight.w700,
    );

    Widget buildProductImage() {
      if (product.images.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.image, size: 28, color: Colors.grey.shade500),
        );
      }

      final path = product.images.first;
      if (path.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(path, fit: BoxFit.cover),
        );
      } else if (path.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(imageUrl: path, fit: BoxFit.cover),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(File(path), fit: BoxFit.cover),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: buildProductImage(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              product.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: priceStyle,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Stock: ${product.stock}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.isActive ? Icons.visibility : Icons.visibility_off,
                                size: 16,
                                color: product.isActive ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                product.isActive ? 'Active' : 'Inactive',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: product.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            Text(
              product.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final buttonStyle = TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );

                final editButton = TextButton.icon(
                  onPressed: () => _showEditProductDialog(product),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: buttonStyle.copyWith(
                    foregroundColor: WidgetStateProperty.all(theme.primaryColor),
                  ),
                );

                final deleteButton = TextButton.icon(
                  onPressed: () => _deleteProduct(product),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: buttonStyle.copyWith(
                    foregroundColor: WidgetStateProperty.all(Colors.red.shade600),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      editButton,
                      const SizedBox(height: 8),
                      deleteButton,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    editButton,
                    const SizedBox(width: 12),
                    deleteButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    );
  }

  void _showEditProductDialog(models.Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(models.Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class AddEditProductScreen extends StatefulWidget {
  final models.Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  
  final AdminService _adminService = AdminService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isActive = true;

  final List<String> _categories = ApprovedCategories.categories;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields(widget.product!);
    }
  }

  void _populateFields(models.Product product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _categoryController.text = product.category;
    _isActive = product.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      setState(() {
        _selectedImages = images;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = models.Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      category: _categoryController.text.trim(),
      images: widget.product?.images ?? [], // Keep existing images for updates
      stock: int.parse(_stockController.text),
      isActive: _isActive,
      createdBy: widget.product?.createdBy ?? 'admin',
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {

      if (widget.product == null) {
        // Add new product - Pass the XFile images to AdminService for proper handling
        await _adminService.addProduct(product, _selectedImages);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedImages.isNotEmpty 
                  ? 'Product added successfully with ${_selectedImages.length} image(s)'
                  : 'Product added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing product - Pass the XFile images if any were selected
        await _adminService.updateProduct(
          product, 
          _selectedImages.isNotEmpty ? _selectedImages : null
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedImages.isNotEmpty 
                  ? 'Product updated successfully with ${_selectedImages.length} new image(s)'
                  : 'Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error saving product';
        
        if (e.toString().contains('Failed to save image') && e.toString().contains('local storage')) {
          errorMessage = '❌ Local Image Storage Error\n\n'
              'Unable to save images to device storage.\n\n'
              '🔧 Possible fixes:\n'
              '• Check available storage space on device\n'
              '• Ensure app has storage permissions\n'
              '• Try with smaller image files\n'
              '• Restart the app and try again\n\n'
              'Images are being saved locally since Firebase Storage is not configured.';
        } else if (e.toString().contains('STORAGE_NOT_CONFIGURED')) {
          errorMessage = '📱 Using Local Image Storage\n\n'
              'Firebase Storage is not configured, so images are being saved locally on your device.\n\n'
              '✅ This is perfectly fine for development and testing!\n\n'
              '📖 See FIREBASE_SETUP_COMPLETE.md if you want to set up cloud storage.';
        } else if (e.toString().contains('Failed to upload image')) {
          if (e.toString().contains('project-not-found') || e.toString().contains('invalid-project-id')) {
            errorMessage = '❌ Firebase Project Configuration Error\n\n'
                'The projectId in firebase_options.dart appears to be a placeholder.\n\n'
                '🔧 Fix: Replace "your-project-id" with your actual Firebase project ID.\n\n'
                '📱 For now, images will be saved locally to your device.\n\n'
                '📖 See FIREBASE_SETUP_COMPLETE.md for complete instructions.';
          } else if (e.toString().contains('bucket-not-found')) {
            errorMessage = '❌ Firebase Storage Not Enabled\n\n'
                'Firebase Storage is not set up for this project.\n\n'
                '🔧 Fix: Enable Storage in Firebase Console → Storage → Get Started\n\n'
                '📱 For now, images will be saved locally to your device.\n\n'
                '📖 See FIREBASE_SETUP_COMPLETE.md for detailed setup.';
          } else if (e.toString().contains('unauthorized')) {
            errorMessage = '❌ Storage Access Denied\n\n'
                'You may not be logged in as an admin or Storage rules need updating.\n\n'
                '🔧 Fix: Check your admin role in Firestore users collection\n\n'
                '📱 For now, images will be saved locally to your device.\n\n'
                '📖 See FIREBASE_SETUP_COMPLETE.md for admin setup.';
          } else {
            errorMessage = '❌ Image Processing Failed\n\n'
                'There was an error processing your images.\n\n'
                '🔧 Try: Use smaller images (under 5MB) or different image formats (JPG, PNG)\n\n'
                '📱 Images are being saved locally since cloud storage has issues.\n\n'
                '📖 See FIREBASE_SETUP_COMPLETE.md if issues persist.';
          }
        } else {
          errorMessage = '❌ Error Saving Product\n\n'
              'An unexpected error occurred.\n\n'
              '🔧 Try: Check your internet connection and try again\n\n'
              '📖 See FIREBASE_SETUP_COMPLETE.md for troubleshooting\n\n'
              'Error details: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: e.toString().contains('STORAGE_NOT_CONFIGURED') 
                ? SnackBarAction(
                    label: 'Add Without Images',
                    onPressed: () async {
                      try {
                        await _adminService.addProductWithoutImages(product);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product added successfully without images'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add product: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // Removed legacy Cloudinary/storage helper dialogs.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: widget.product == null ? 'Adding product...' : 'Updating product...',
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Product Name
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Enter product description',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product description';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Price and Stock Row
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _priceController,
                        labelText: 'Price (\$)',
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _stockController,
                        labelText: 'Stock',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter stock';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid stock';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Category Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _categories.contains(_categoryController.text) 
                          ? _categoryController.text 
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Select category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _categoryController.text = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Active Status
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Product is visible to customers'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Image Selection with Preview
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Product Images',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Select Images'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Note: Images are saved locally. No cloud configuration needed.
                    
                    // Selected Images Preview
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Images (${_selectedImages.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  final image = _selectedImages[index];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(image.path),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.product?.images.isNotEmpty == true)
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Images (${widget.product!.images.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.product!.images.length,
                                itemBuilder: (context, index) {
                                  final url = widget.product!.images[index];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: () {
                                        if (url.startsWith('assets/')) {
                                          return Image.asset(
                                            url,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          );
                                        } else if (url.startsWith('http')) {
                                          return CachedNetworkImage(
                                            imageUrl: url,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return Image.file(
                                            File(url),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                      }(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: Colors.grey[400], size: 24),
                              const SizedBox(height: 4),
                              Text(
                                'No images selected',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Save Button
                CustomButton(
                  text: widget.product == null ? 'Add Product' : 'Update Product',
                  onPressed: _saveProduct,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
