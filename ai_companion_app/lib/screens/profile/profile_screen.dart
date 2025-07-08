import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  // Preference categories
  final Map<String, List<String>> _preferenceOptions = {
    'Shopping Categories': [
      'Electronics', 'Fashion', 'Home & Garden', 'Books', 'Sports', 
      'Beauty', 'Food & Beverages', 'Toys', 'Automotive', 'Health'
    ],
    'Price Range': ['Budget-friendly', 'Mid-range', 'Premium', 'Luxury'],
    'Shopping Style': [
      'Quick & Efficient', 'Research-heavy', 'Brand-conscious', 
      'Deal-hunter', 'Eco-friendly', 'Local-first'
    ],
    'Communication Style': [
      'Brief & Direct', 'Detailed & Thorough', 'Friendly & Casual', 
      'Professional', 'Encouraging'
    ],
  };

  Map<String, List<String>> _selectedPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profileData = await _apiService.getProfile();
      final preferencesData = await _apiService.getPreferences();
      
      setState(() {
        _profile = profileData;
        _preferences = preferencesData;
        _bioController.text = _profile?['bio'] ?? '';
        _parsePreferences();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load profile: $e');
    }
  }

  void _parsePreferences() {
    if (_preferences != null && _preferences!['graph'] != null) {
      final graph = _preferences!['graph'] as Map<String, dynamic>;
      _selectedPreferences.clear();
      
      for (final category in _preferenceOptions.keys) {
        if (graph.containsKey(category)) {
          final selected = List<String>.from(graph[category] ?? []);
          _selectedPreferences[category] = selected;
        } else {
          _selectedPreferences[category] = [];
        }
      }
    } else {
      // Initialize empty preferences
      for (final category in _preferenceOptions.keys) {
        _selectedPreferences[category] = [];
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Save profile
      final profileSuccess = await _apiService.updateProfile({
        'bio': _bioController.text,
      });
      
      // Save preferences
      final preferencesSuccess = await _apiService.updatePreferences(_selectedPreferences);
      
      if (profileSuccess && preferencesSuccess) {
        _showSuccessSnackBar('Profile updated successfully!');
        _loadProfile(); // Reload to get updated data
      } else {
        throw Exception('Failed to update profile or preferences');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildPreferenceSection(String category, List<String> options) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = _selectedPreferences[category]?.contains(option) ?? false;
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPreferences[category]!.add(option);
                      } else {
                        _selectedPreferences[category]!.remove(option);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Info Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _profile?['username'] ?? 'Unknown User',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _profile?['email'] ?? 'No email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bioController,
                            decoration: const InputDecoration(
                              labelText: 'Bio',
                              hintText: 'Tell us about yourself...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value != null && value.length > 500) {
                                return 'Bio must be less than 500 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Preferences Section
                  const Text(
                    'Shopping Preferences',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help your AI shopping assistant understand your preferences better.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Preference Categories
                  ..._preferenceOptions.entries.map((entry) {
                    return _buildPreferenceSection(entry.key, entry.value);
                  }).toList(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
}
