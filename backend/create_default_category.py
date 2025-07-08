#!/usr/bin/env python
import os
import sys
import django

# Add the project root to Python path
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.append(project_root)

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from marketplace.models import Category

# Create default categories
categories = [
    {'name': 'General', 'description': 'General products and items'},
    {'name': 'Electronics', 'description': 'Electronic devices and gadgets'},
    {'name': 'Fashion', 'description': 'Clothing, accessories, and fashion items'},
    {'name': 'Home & Garden', 'description': 'Home decor and garden items'},
    {'name': 'Automotive', 'description': 'Cars, motorcycles, and auto parts'},
    {'name': 'Sports', 'description': 'Sports equipment and gear'},
    {'name': 'Books', 'description': 'Books and educational materials'},
    {'name': 'Hotels', 'description': 'Hotel bookings and accommodations'},
]

for cat_data in categories:
    category, created = Category.objects.get_or_create(
        name=cat_data['name'],
        defaults={'description': cat_data['description']}
    )
    if created:
        print(f"Created category: {category.name}")
    else:
        print(f"Category already exists: {category.name}")

print("Default categories created successfully!")
