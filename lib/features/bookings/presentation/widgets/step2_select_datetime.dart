import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../providers/booking_provider.dart';

class Step2SelectDateTime extends StatefulWidget {
  const Step2SelectDateTime({super.key});

  @override
  State<Step2SelectDateTime> createState() => _Step2SelectDateTimeState();
}

class _Step2SelectDateTimeState extends State<Step2SelectDateTime> {
  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Date Display
              if (bookingProvider.selectedDate != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Selected: ${DateFormat('EEEE, MMMM dd, yyyy').format(bookingProvider.selectedDate!)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Calendar Picker
              Text(
                'Select Date',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CalendarDatePicker(
                  initialDate: bookingProvider.selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  onDateChanged: (date) {
                    bookingProvider.setDate(date);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Time Slots
              Text(
                'Select Time',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _timeSlots.map((timeSlot) {
                  final isSelected = bookingProvider.selectedTimeSlot == timeSlot;
                  return ChoiceChip(
                    label: Text(timeSlot),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        bookingProvider.setTimeSlot(timeSlot);
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

