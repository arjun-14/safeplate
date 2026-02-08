import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> response;
  final String? imagePath;
  final VoidCallback onBackHome;

  const ResultsScreen({
    super.key,
    required this.response,
    this.imagePath,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF48BB78),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackHome,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analysis Results',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryCards(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Results content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: response['success'] == true
                ? _buildSuccessContent(context)
                : _buildErrorContent(context),
          ),

          // Bottom padding for button
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBackHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48BB78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF48BB78).withOpacity(0.3),
              ),
              child: const Text(
                'New Scan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final dishesCount = data['dishes_count'] ?? 0;
    final ingredients = data['ingredients'] as List? ?? [];
    
    // Count allergens
    int allergenCount = 0;
    if (ingredients is List) {
      for (var ingredient in ingredients) {
        if (ingredient is Map) {
          final safety = ingredient['safety'] as Map?;
          if (safety != null && safety['status'] == 'UNSAFE') {
            allergenCount++;
          }
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            dishesCount.toString(),
            'DISHES',
          ),
        ),
        // const SizedBox(width: 10),
        // Expanded(
        //   child: _buildSummaryCard(
        //     ingredients.length.toString(),
        //     'INGREDIENTS',
        //   ),
        //),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            allergenCount.toString(),
            allergenCount == 1 ? 'UNSAFE DISH' : 'UNSAFE DISHES',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final ingredients = data['ingredients'] as List? ?? [];

    if (ingredients.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'No dishes detected',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dish = ingredients[index] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildDishCard(dish, index + 1, context),
          );
        },
        childCount: ingredients.length,
      ),
    );
  }

  Widget _buildDishCard(Map<String, dynamic> dish, int dishNumber, BuildContext context) {
    final dishName = dish['dish'] ?? 'Unknown Dish';
    final ingredientsList = dish['ingredients'] as List? ?? [];
    final safety = dish['safety'] as Map<String, dynamic>?;
    final safetyStatus = safety?['status'] ?? 'SAFE';
    final safetyReason = safety?['reason'];
    final safetySuggestion = safety?['suggestion'];

    // Determine card color based on safety status
    Color cardColor;
    Color borderColor;
    
    switch (safetyStatus) {
      case 'UNSAFE':
        cardColor = const Color(0xFFFFF3F3); // Light red
        borderColor = const Color(0xFFFF6B6B);
        break;
      case 'MODIFIABLE':
        cardColor = const Color(0xFFFFFBF0); // Light yellow
        borderColor = const Color(0xFFFFC107);
        break;
      default: // SAFE
        cardColor = const Color(0xFFF0FFF4); // Light green
        borderColor = const Color(0xFF48BB78);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dish header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dishName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: borderColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      dishNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Ingredients section
            const Text(
              'INGREDIENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ingredientsList.map((ingredient) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    ingredient.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),

            // Safety status section
            const Text(
              'SAFETY STATUS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildSafetyBanner(safetyStatus, safetyReason, safetySuggestion),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyBanner(String status, String? reason, String? suggestion) {
    IconData icon;
    Color bgColor;
    Color borderColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'UNSAFE':
        icon = Icons.warning_rounded;
        bgColor = const Color(0xFFFFF3CD);
        borderColor = const Color(0xFFFFC107);
        textColor = const Color(0xFF856404);
        displayText = reason ?? 'Contains allergens';
        if (suggestion != null && suggestion.isNotEmpty) {
          displayText += '\n\n💡 $suggestion';
        }
        break;
      case 'MODIFIABLE':
        icon = Icons.info_outline_rounded;
        bgColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFB300);
        textColor = const Color(0xFF6D5200);
        displayText = reason ?? 'Can be modified';
        if (suggestion != null && suggestion.isNotEmpty) {
          displayText += '\n\n💡 $suggestion';
        }
        break;
      default: // SAFE
        icon = Icons.check_circle_outline_rounded;
        bgColor = const Color(0xFFD4EDDA);
        borderColor = const Color(0xFF48BB78);
        textColor = const Color(0xFF155724);
        displayText = 'No allergens detected';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.red[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    response['error'] ?? 'An unknown error occurred',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}