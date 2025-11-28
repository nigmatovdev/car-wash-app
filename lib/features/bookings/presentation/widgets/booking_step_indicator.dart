import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber == currentStep;
          final isCompleted = stepNumber < currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '$stepNumber',
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

