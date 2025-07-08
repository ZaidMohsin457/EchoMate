import 'package:flutter/material.dart';

class MarketplaceBuyScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const MarketplaceBuyScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy / Book Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to buy:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(product['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Price: \$${product['price']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(product['description'] ?? ''),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement real buy/order logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed! (Demo)')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Confirm Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
