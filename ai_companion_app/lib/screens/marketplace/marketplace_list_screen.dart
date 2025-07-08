import 'package:flutter/material.dart';
import '../../services/marketplace_api.dart';

class MarketplaceListScreen extends StatefulWidget {
  const MarketplaceListScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceListScreen> createState() => _MarketplaceListScreenState();
}

class _MarketplaceListScreenState extends State<MarketplaceListScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = MarketplaceApi.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _productsFuture = MarketplaceApi.fetchProducts();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/marketplace/create').then((_) {
                setState(() {
                  _productsFuture = MarketplaceApi.fetchProducts();
                });
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final status = product['status'] ?? 'available';
              final quantity = product['quantity'] ?? 1;
              
              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          _buildProductImage(product),
                          const SizedBox(width: 12),
                          
                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _buildStatusChip(status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product['description'] ?? '',
                                  style: TextStyle(color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '\$${product['price']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Qty: $quantity',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Action Buttons
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context, 
                                    '/marketplace/detail', 
                                    arguments: product
                                  );
                                },
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: const Text('Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (status == 'available')
                                ElevatedButton.icon(
                                  onPressed: () => _showBuyDialog(product),
                                  icon: const Icon(Icons.shopping_cart, size: 16),
                                  label: const Text('Buy'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          
                          // Delete button (for testing - in production, only show for owner)
                          IconButton(
                            onPressed: () => _showDeleteDialog(product),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Product',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/marketplace/create');
          if (result == true) {
            // Product was created successfully, refresh the list
            setState(() {
              _productsFuture = MarketplaceApi.fetchProducts();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    // Check if product has images array
    if (product['images'] != null && product['images'].isNotEmpty) {
      final imageUrl = product['images'][0]['image']; // Already contains full URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Image load error: $error'); // Debug print
            return const Icon(Icons.shopping_bag, size: 40);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 56,
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }
    // Fallback to image_url field
    else if (product['image_url'] != null && product['image_url'] != '') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product['image_url'],
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.shopping_bag, size: 40);
          },
        ),
      );
    }
    return const Icon(Icons.shopping_bag, size: 40);
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;
    
    switch (status.toLowerCase()) {
      case 'available':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'sold':
        chipColor = Colors.red;
        chipIcon = Icons.remove_circle;
        break;
      case 'reserved':
        chipColor = Colors.orange;
        chipIcon = Icons.pending;
        break;
      case 'inactive':
        chipColor = Colors.grey;
        chipIcon = Icons.pause_circle;
        break;
      default:
        chipColor = Colors.blue;
        chipIcon = Icons.info;
    }
    
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _showBuyDialog(Map<String, dynamic> product) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Buy ${product['title']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Price: \$${product['price']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _processPurchase(
                product,
                emailController.text,
                phoneController.text,
                addressController.text,
                int.tryParse(quantityController.text) ?? 1,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buy Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPurchase(
    Map<String, dynamic> product,
    String email,
    String phone,
    String address,
    int quantity,
  ) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required')),
      );
      return;
    }
    
    Navigator.pop(context); // Close dialog
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await MarketplaceApi.createOrder(
        productId: product['id'],
        quantity: quantity,
        buyerEmail: email.trim(),
        buyerPhone: phone.trim(),
        deliveryAddress: address.trim(),
      );
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the product list to show updated status
      setState(() {
        _productsFuture = MarketplaceApi.fetchProducts();
      });
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product['title']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _deleteProduct(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    Navigator.pop(context); // Close dialog
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final success = await MarketplaceApi.deleteProduct(product['id']);
      
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the product list
        setState(() {
          _productsFuture = MarketplaceApi.fetchProducts();
        });
      } else {
        throw Exception('Delete operation failed');
      }
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
