import 'package:intl/intl.dart';

class Formatters {
  // Date Formatters
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _displayTimeFormat = DateFormat('hh:mm a');
  static final DateFormat _displayDateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  
  // Currency Formatter
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  // Number Formatter
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00');
  
  // Phone Formatter
  static String formatPhone(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }
  
  // Date Formatters
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  static String formatDisplayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }
  
  static String formatDisplayTime(DateTime dateTime) {
    return _displayTimeFormat.format(dateTime);
  }
  
  static String formatDisplayDateTime(DateTime dateTime) {
    return _displayDateTimeFormat.format(dateTime);
  }
  
  // Currency Formatter
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }
  
  // Number Formatter
  static String formatNumber(double number) {
    return _numberFormat.format(number);
  }
  
  // Parse Date
  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return _dateTimeFormat.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
}

