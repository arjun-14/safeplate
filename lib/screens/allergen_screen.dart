import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllergenScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const AllergenScreen({super.key, required this.onComplete});

  @override
  State<AllergenScreen> createState() => _AllergenScreenState();
}

class _AllergenScreenState extends State<AllergenScreen> {
  final Map<String, String> _allergenEmojis = {
    'Peanuts': '🥜',
    'Tree Nuts': '🌰',
    'Milk (Dairy)': '🥛',
    'Eggs': '🥚',
    'Fish': '🐟',
    'Shellfish': '🦐',
    'Soy': '🌱',
    'Wheat': '🌾',
    'Molluscs': '🐌',
    'Sulphites': '🍇',
    'Gluten': '🍞',
  };

  late Set<String> selectedAllergens = {};

  @override
  void initState() {
    super.initState();
    _loadSavedAllergens();
  }

  Future<void> _loadSavedAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('selected_allergens') ?? [];
    setState(() {
      selectedAllergens = saved.toSet();
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_allergens', selectedAllergens.toList());
    await prefs.setBool('profile_setup_complete', true);
    
    if (mounted) {
      widget.onComplete();
    }
  }

  void _toggleAllergen(String allergen) {
    setState(() {
      if (selectedAllergens.contains(allergen)) {
        selectedAllergens.remove(allergen);
      } else {
        selectedAllergens.add(allergen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'What are you avoiding?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 32),
              // Allergen chips grid
              Expanded(
                child: GridView.builder(
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
                    final isSelected = selectedAllergens.contains(allergen);

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
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Save Profile button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save Profile',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
