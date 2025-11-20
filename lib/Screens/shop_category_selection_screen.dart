import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos/constant.dart';
import 'Home/home.dart';

class ShopCategorySelectionScreen extends StatefulWidget {
  final String? preselectedCategoryName;
  
  const ShopCategorySelectionScreen({Key? key, this.preselectedCategoryName}) : super(key: key);

  @override
  State<ShopCategorySelectionScreen> createState() => _ShopCategorySelectionScreenState();
}

class _ShopCategorySelectionScreenState extends State<ShopCategorySelectionScreen> {
  String? _selectedCategoryName;
  
  // Define shop categories with their features
  final List<Map<String, dynamic>> shopCategories = [
    {
      'name': 'All Category',
      'icon': Icons.all_inclusive,
      'color': Colors.deepPurple,
      'description': 'All features enabled',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income',
        'order_booking',
        'salon_service'
      ]
    },
    {
      'name': 'Retail Shop',
      'icon': Icons.store,
      'color': Colors.blue,
      'description': 'General retail business',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Restaurant',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'description': 'Food & beverage service',
      'features': [
        'sale',
        'product',
        'parties',
        'dashboard',
        'reports',
        'expense',
        'income',
        'order_booking'
      ]
    },
    {
      'name': 'Grocery Store',
      'icon': Icons.shopping_basket,
      'color': Colors.green,
      'description': 'Grocery & provisions',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Fashion Store',
      'icon': Icons.checkroom,
      'color': Colors.pink,
      'description': 'Clothing & accessories',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Medical/Pharmacy',
      'icon': Icons.medical_services,
      'color': Colors.red,
      'description': 'Medicine & healthcare',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Electronics',
      'icon': Icons.devices,
      'color': Colors.purple,
      'description': 'Electronic goods',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Salon',
      'icon': Icons.face,
      'color': Colors.teal,
      'description': 'Beauty & wellness services',
      'features': [
        'sale',
        'parties',
        'dashboard',
        'reports',
        'expense',
        'income',
        'order_booking',
        'salon_service'
      ]
    },
    {
      'name': 'Hardware Store',
      'icon': Icons.build,
      'color': Colors.brown,
      'description': 'Tools & hardware',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Mobile Shop',
      'icon': Icons.smartphone,
      'color': Colors.indigo,
      'description': 'Mobile phones & accessories',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
    {
      'name': 'Stationery',
      'icon': Icons.book,
      'color': Colors.amber,
      'description': 'Books & stationery items',
      'features': [
        'sale',
        'purchase',
        'product',
        'parties',
        'dashboard',
        'reports',
        'stock',
        'due_calculation',
        'expense',
        'income'
      ]
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Set preselected category if provided
    _selectedCategoryName = widget.preselectedCategoryName;
    print('ShopCategorySelectionScreen - Preselected Category: $_selectedCategoryName');
    
    // If a category is preselected, automatically select it after a short delay
    if (_selectedCategoryName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            // Try to find the category - first exact match, then case-insensitive
            Map<String, dynamic>? foundCategory;
            
            // Try exact match first
            try {
              foundCategory = shopCategories.firstWhere(
                (cat) => cat['name']?.toString().trim() == _selectedCategoryName?.trim(),
              );
              print('Found category with exact match: ${foundCategory['name']}');
            } catch (e) {
              // Try case-insensitive match
              try {
                foundCategory = shopCategories.firstWhere(
                  (cat) => cat['name']?.toString().toLowerCase().trim() == _selectedCategoryName?.toLowerCase().trim(),
                );
                print('Found category with case-insensitive match: ${foundCategory['name']}');
              } catch (e2) {
                print('Category not found: $_selectedCategoryName');
                print('Available categories: ${shopCategories.map((c) => c['name']).toList()}');
                // If not found, don't auto-select - let user choose
                return;
              }
            }
            
            selectShopCategory(foundCategory['name'], List<String>.from(foundCategory['features']));
          }
        });
      });
    }
  }

  Future<void> selectShopCategory(String categoryName, List<String> features) async {
    // Update selected category in state
    setState(() {
      _selectedCategoryName = categoryName;
    });
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save selected shop category
    await prefs.setString('shop_category', categoryName);
    await prefs.setStringList('shop_features', features);
    
    // Navigate to home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        title: const Text(
          'Select Your Shop Category',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kMainColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose the category that best describes your business',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: shopCategories.length,
                itemBuilder: (context, index) {
                  final category = shopCategories[index];
                  return _buildCategoryCard(
                    name: category['name'],
                    icon: category['icon'],
                    color: category['color'],
                    description: category['description'],
                    features: List<String>.from(category['features']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required IconData icon,
    required Color color,
    required String description,
    required List<String> features,
  }) {
    final isSelected = _selectedCategoryName == name;
    
    return GestureDetector(
      onTap: () => selectShopCategory(name, features),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.4 : 0.2),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTitleColor,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${features.length} Features',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

