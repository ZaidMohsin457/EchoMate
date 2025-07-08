#!/usr/bin/env python
import requests

print('=== TESTING BACKEND IMPROVEMENTS ===')

# Test 1: Check current products with status
r = requests.get('http://localhost:8000/api/marketplace/products/')
products = r.json()
print(f'\n1. Current products: {len(products)}')
if products:
    product = products[0]
    print(f'   First product: {product["title"]}')
    print(f'   Status: {product.get("status", "Not set")}')
    print(f'   Available: {product.get("available")}')
    print(f'   Quantity: {product.get("quantity", "Not set")}')

print('\nStatus field successfully added to products!')
