import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart' as models;
import '../services/order_service.dart';

class OrderDetailsScreen extends StatelessWidget {
  final models.Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(order.status),
                                size: 16,
                                color: _getStatusColor(order.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusText(order.status),
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildOrderTimeline(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...order.items.map((item) => _buildOrderItemTile(context, item, currencyFormat)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Address
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatAddress(order.shippingAddress),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment & Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment & Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Payment Method', order.paymentMethod),
                    _buildSummaryRow('Order Date', dateFormat.format(order.createdAt)),
                    _buildSummaryRow('Items Total', currencyFormat.format(_calculateSubtotal())),
                    _buildSummaryRow('Delivery Fee', currencyFormat.format(_calculateDeliveryFee())),
                    _buildSummaryRow('Tax', currencyFormat.format(_calculateTax())),
                    const Divider(),
                    _buildSummaryRow(
                      'Total Amount',
                      currencyFormat.format(order.totalAmount),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (_shouldShowActions(order.status))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePrimaryAction(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getPrimaryActionColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_getPrimaryActionText()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline() {
    final statuses = [
      models.OrderStatus.pending,
      models.OrderStatus.confirmed,
      models.OrderStatus.processing,
      models.OrderStatus.shipped,
      models.OrderStatus.delivered,
    ];

    final currentStatusIndex = statuses.indexOf(order.status);
    
    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentStatusIndex && order.status != models.OrderStatus.cancelled;
        final isCurrent = index == currentStatusIndex && order.status != models.OrderStatus.cancelled;
        
        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? (isCurrent ? _getStatusColor(order.status) : Colors.green)
                    : Colors.grey[300],
              ),
              child: isCompleted
                  ? Icon(
                      isCurrent ? _getStatusIcon(status) : Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildOrderItemTile(BuildContext context, models.OrderItem item, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.productImage.isNotEmpty
                  ? Image.network(
                      item.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(item.totalPrice),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(models.OrderStatus status) {
    switch (status) {
      case models.OrderStatus.pending:
        return Colors.orange;
      case models.OrderStatus.confirmed:
        return Colors.blue;
      case models.OrderStatus.processing:
        return Colors.indigo;
      case models.OrderStatus.shipped:
        return Colors.purple;
      case models.OrderStatus.delivered:
        return Colors.green;
      case models.OrderStatus.cancelled:
        return Colors.red;
      case models.OrderStatus.refunded:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(models.OrderStatus status) {
    switch (status) {
      case models.OrderStatus.pending:
        return Icons.schedule;
      case models.OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case models.OrderStatus.processing:
        return Icons.settings;
      case models.OrderStatus.shipped:
        return Icons.local_shipping;
      case models.OrderStatus.delivered:
        return Icons.check_circle;
      case models.OrderStatus.cancelled:
        return Icons.cancel;
      case models.OrderStatus.refunded:
        return Icons.money_off;
    }
  }

  String _getStatusText(models.OrderStatus status) {
    switch (status) {
      case models.OrderStatus.pending:
        return 'Order Placed';
      case models.OrderStatus.confirmed:
        return 'Confirmed';
      case models.OrderStatus.processing:
        return 'Processing';
      case models.OrderStatus.shipped:
        return 'Shipped';
      case models.OrderStatus.delivered:
        return 'Delivered';
      case models.OrderStatus.cancelled:
        return 'Cancelled';
      case models.OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String _formatAddress(models.Address address) {
    return '${address.street}\n${address.city}, ${address.state} ${address.zipCode}\n${address.country}';
  }

  double _calculateSubtotal() {
    return order.items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double _calculateDeliveryFee() {
    final subtotal = _calculateSubtotal();
    return subtotal > 500 ? 0.0 : 50.0;
  }

  double _calculateTax() {
    return _calculateSubtotal() * 0.18;
  }

  bool _shouldShowActions(models.OrderStatus status) {
    return status == models.OrderStatus.pending || status == models.OrderStatus.confirmed;
  }

  String _getPrimaryActionText() {
    if (order.status == models.OrderStatus.pending || order.status == models.OrderStatus.confirmed) {
      return 'Cancel Order';
    }
    return '';
  }

  Color _getPrimaryActionColor() {
    return Colors.red;
  }

  void _handlePrimaryAction(BuildContext context) {
    if (order.status == models.OrderStatus.pending || order.status == models.OrderStatus.confirmed) {
      _cancelOrder(context);
    }
  }

  void _cancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await OrderService().cancelOrder(order.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Go back to orders list
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel order: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
