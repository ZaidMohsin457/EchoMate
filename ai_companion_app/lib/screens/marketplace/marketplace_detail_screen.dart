import 'package:flutter/material.dart';

class MarketplaceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const MarketplaceDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['title'] ?? 'Product Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['image'] != null)
              Image.network(product['image'], height: 200, fit: BoxFit.cover)
            else
              const Icon(Icons.shopping_bag, size: 100),
            const SizedBox(height: 16),
            Text(product['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(' 24${product['price']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(product['description'] ?? ''),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement buy/order logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed! (Demo)')),
                  );
                },
                child: const Text('Buy / Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
