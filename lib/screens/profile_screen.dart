import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<String> _selectedAllergens = [];

  final Map<String, String> _allergenEmojis = {
    'Peanuts': '🥜',
    'Tree Nuts': '🌰',
    'Milk (Dairy)': '🥛',
    'Eggs': '🥚',
    'Fish': '🐟',
    'Shellfish': '🦐',
    'Soy': '🌱',
    'Wheat': '🌾',
    // 'Sesame': '🌿',
    // 'Celery': '🌿',
    // 'Mustard': '🌿',
    // 'Lupin': '🌿',
    'Molluscs': '🐌',
    'Sulphites': '🍇',
    'Gluten': '🍞',
  };

  @override
  void initState() {
    super.initState();
    _loadAllergens();
  }

  Future<void> _loadAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final allergens = prefs.getStringList('selected_allergens') ?? [];
    setState(() {
      _selectedAllergens = allergens;
    });
  }

  Future<void> _updateAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_allergens', _selectedAllergens);
  }

  void _toggleAllergen(String allergen) {
    setState(() {
      if (_selectedAllergens.contains(allergen)) {
        _selectedAllergens.remove(allergen);
      } else {
        _selectedAllergens.add(allergen);
      }
    });
    _updateAllergens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF48BB78),
        title: Text(
          'SafePlate',
          style: GoogleFonts.playpenSans(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   'Add Allergens',
              //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
              //         fontWeight: FontWeight.bold,
              //       ),
              // ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _allergenEmojis.length,
                itemBuilder: (context, index) {
                  final allergen = _allergenEmojis.keys.toList()[index];
                  final emoji = _allergenEmojis[allergen];
                  final isSelected = _selectedAllergens.contains(allergen);

                  return GestureDetector(
                    onTap: () => _toggleAllergen(allergen),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            emoji ?? '',
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            allergen,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
