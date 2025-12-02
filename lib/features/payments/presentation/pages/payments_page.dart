import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _amountController = TextEditingController();
  bool _isToppingUp = false;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    // Fetch latest user data (including balance) when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBalance();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshBalance() async {
    final authProvider = context.read<AuthProvider>();
    // Always refresh balance when page opens to ensure we have latest data
    setState(() {
      _isLoadingBalance = true;
    });
    await authProvider.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }

  double _getCreditBalance(AuthProvider authProvider) {
    return authProvider.user?.creditBalance ?? 0.0;
  }

  Future<void> _topUpCredit(AuthProvider authProvider) async {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      Helpers.showErrorSnackBar(context, 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      Helpers.showErrorSnackBar(context, 'Please enter a valid amount');
      return;
    }

    setState(() {
      _isToppingUp = true;
    });

    try {
      final response = await _apiClient.post(
        ApiConstants.topUpCredit,
        data: {
          'amount': amount,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to read new balance from response if provided
        double? newBalance;
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['balance'] != null) {
            newBalance = (data['balance'] as num).toDouble();
          } else if (data['creditBalance'] != null) {
            newBalance = (data['creditBalance'] as num).toDouble();
          } else if (data['user'] != null &&
              data['user'] is Map<String, dynamic> &&
              ((data['user'] as Map<String, dynamic>)['creditBalance'] != null ||
                  (data['user'] as Map<String, dynamic>)['balance'] != null)) {
            final user = data['user'] as Map<String, dynamic>;
            final balanceValue = user['creditBalance'] ?? user['balance'];
            if (balanceValue != null) {
              newBalance = (balanceValue as num).toDouble();
            }
          }
        }

        // Refresh user profile to get latest balance if we couldn't parse it
        await authProvider.getCurrentUser();

        setState(() {
          _isToppingUp = false;
        });

        final balanceToShow = newBalance ?? _getCreditBalance(authProvider);

        Helpers.showSuccessSnackBar(
          context,
          'Top-up successful! New balance: ${Formatters.formatCurrency(balanceToShow)}',
        );
        _amountController.clear();
      } else {
        throw Exception('Top-up failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isToppingUp = false;
      });
      Helpers.showErrorSnackBar(
        context,
        'Failed to top up balance: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Balance'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final balance = _getCreditBalance(authProvider);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoadingBalance = true;
              });
              await authProvider.getCurrentUser();
              if (mounted) {
                setState(() {
                  _isLoadingBalance = false;
                });
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credit Balance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoadingBalance
                            ? const SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                Formatters.formatCurrency(balance),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                        const SizedBox(height: 12),
                        const Text(
                          'Use your balance to pay for bookings with \"Pay with credit\".',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Top-up section
                  Text(
                    'Top Up Balance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '\$ ',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: _isToppingUp ? 'Processing...' : 'Top Up Balance',
                            onPressed: _isToppingUp
                                ? null
                                : () => _topUpCredit(authProvider),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Top-ups use demo mode by default. No real charges are made.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment history placeholder
                  Text(
                    'Payment History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking payments will appear here in a future update.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current flows:\n'
                          '- Pay with card (demo) on the booking payment screen.\n'
                          '- Pay with credit when you have sufficient balance.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

