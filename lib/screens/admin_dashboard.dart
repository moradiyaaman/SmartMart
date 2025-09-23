import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'product_management_screen.dart';
import 'sales_analytics_screen.dart';
import 'user_management_screen.dart';
import 'auth_screen.dart';
import 'order_management_screen_simple.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back, Admin!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your SmartMart store efficiently',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Cards
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2, // Reduced from 1.5 to 1.2 for more height
                      children: [
                        _buildStatCard(
                          'Total Products',
                          _stats['totalProducts']?.toString() ?? '0',
                          Icons.inventory,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Total Orders',
                          _stats['totalOrders']?.toString() ?? '0',
                          Icons.shopping_cart,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Total Customers',
                          _stats['totalCustomers']?.toString() ?? '0',
                          Icons.people,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Pending Orders',
                          _stats['pendingOrders']?.toString() ?? '0',
                          Icons.pending_actions,
                          Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          'Manage Products',
                          'Add, edit, or delete products',
                          Icons.inventory_2,
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductManagementScreen(),
                            ),
                          ),
                        ),
                        _buildActionCard(
                          'Manage Orders',
                          'View and update order status',
                          Icons.assignment,
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrderManagementScreenSimple(),
                            ),
                          ),
                        ),
                        _buildActionCard(
                          'Sales Analytics',
                          'View sales reports and charts',
                          Icons.analytics,
                          Colors.purple,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SalesAnalyticsScreen(),
                            ),
                          ),
                        ),
                        _buildActionCard(
                          'User Management',
                          'Manage customer accounts',
                          Icons.people_alt,
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserManagementScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recent Activities
                    const Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _adminService.getRecentActivities(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Column(
                                children: [
                                  _buildActivityItem(
                                    'Welcome to SmartMart Admin',
                                    'Start adding products and managing orders',
                                    Icons.info,
                                    'Just now',
                                  ),
                                ],
                              );
                            }

                            final activities = snapshot.data!;
                            return Column(
                              children: [
                                for (int i = 0; i < activities.length; i++) ...[
                                  _buildActivityItem(
                                    activities[i]['title'],
                                    activities[i]['description'],
                                    _getIconFromString(activities[i]['icon']),
                                    activities[i]['time'],
                                  ),
                                  if (i < activities.length - 1) const Divider(),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(8), // Further reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible( // Made icon flexible
              child: Icon(icon, size: 24, color: color), // Further reduced icon size
            ),
            const SizedBox(height: 4), // Reduced spacing
            Flexible( // Made text flexible
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18, // Further reduced font size
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow
              ),
            ),
            const SizedBox(height: 2), 
            Flexible( // Made title flexible
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10, // Further reduced font size
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow
                maxLines: 2, // Allow 2 lines for title
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Icon(icon, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'person_add':
        return Icons.person_add;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.circle;
    }
  }
}
