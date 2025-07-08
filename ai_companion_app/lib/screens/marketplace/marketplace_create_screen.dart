import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/marketplace_api.dart';

class MarketplaceCreateScreen extends StatefulWidget {
  const MarketplaceCreateScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceCreateScreen> createState() => _MarketplaceCreateScreenState();
}

class _MarketplaceCreateScreenState extends State<MarketplaceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  String title = '';
  String description = '';
  String price = '';
  bool _loading = false;
  String? _error;
  File? _imageFile;
  Uint8List? _webImage;
  String? _imageName;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageName = pickedFile.name;
            _imageFile = null;
          });
        } else {
          // For mobile, use File
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _imageName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await MarketplaceApi.createProduct(
        title: title, 
        description: description, 
        price: price,
        imageFile: _imageFile,
        webImage: _webImage,
        imageName: _imageName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product listed!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List a Product/Hotel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Upload Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: (_imageFile != null || _webImage != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.memory(
                                  _webImage!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add product image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (val) => setState(() => title = val),
                validator: (val) => val == null || val.isEmpty ? 'Enter a title' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (val) => setState(() => description = val),
                validator: (val) => val == null || val.isEmpty ? 'Enter a description' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() => price = val),
                validator: (val) => val == null || val.isEmpty ? 'Enter a price' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('List Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
