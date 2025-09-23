import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../models/app_models.dart' as models;

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';
  String _selectedRole = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _canChangeRoles = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final canChange = await _adminService.isCurrentUserSuperAdmin();
      print('User can change roles: $canChange');
      setState(() {
        _canChangeRoles = canChange;
      });
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() {
        _canChangeRoles = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
                // Role Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleChip('all', 'All Users'),
                      const SizedBox(width: 8),
                      _buildRoleChip('customer', 'Customers'),
                      const SizedBox(width: 8),
                      _buildRoleChip('admin', 'Admins'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: StreamBuilder<List<models.AppUser>>(
              stream: _adminService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading users',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];
                final filteredUsers = _filterUsers(users);

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Users will appear here once they register',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<models.AppUser> _filterUsers(List<models.AppUser> users) {
    return users.where((user) {
      // Role filter
      final roleMatch = _selectedRole == 'all' || 
                       user.role.name == _selectedRole;
      
      // Search filter
      final searchMatch = _searchQuery.isEmpty ||
                         user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return roleMatch && searchMatch;
    }).toList();
  }

  Widget _buildUserCard(models.AppUser user) {
    // Debug output to see what's happening
    print('DEBUG: User ${user.email} has role: ${user.role} (${user.role.toString()})');
    print('DEBUG: Role comparison - Is customer? ${user.role == models.UserRole.customer}');
    print('DEBUG: Can change roles? $_canChangeRoles');
    print('DEBUG: Should show button? ${_canChangeRoles && user.role == models.UserRole.customer}');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildRoleBadge(user.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (user.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Joined: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // SIMPLE LOGIC: Only customers should have the Change Role button
                if (_canChangeRoles && user.role != models.UserRole.admin && user.role != models.UserRole.superAdmin) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showRoleChangeDialog(user),
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('Change Role'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(models.UserRole role) {
    Color backgroundColor;
    Color textColor;
    
    switch (role) {
      case models.UserRole.customer:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case models.UserRole.admin:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case models.UserRole.superAdmin:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showUserDetails(models.AppUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Full Name', user.fullName),
                      _buildDetailRow('Email', user.email),
                      _buildDetailRow('Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not provided'),
                      _buildDetailRow('Role', user.role.name.toUpperCase()),
                      _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
                      _buildDetailRow('Member Since', DateFormat('MMM dd, yyyy').format(user.createdAt)),
                      
                      const SizedBox(height: 24),
                      
                      // User Statistics
                      FutureBuilder<Map<String, dynamic>>(
                        future: _getUserStatistics(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final stats = snapshot.data ?? {};
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'User Statistics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Orders',
                                      '${stats['totalOrders'] ?? 0}',
                                      Icons.shopping_cart,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Spent',
                                      '₹${NumberFormat('#,##,###.00').format(stats['totalSpent'] ?? 0)}',
                                      Icons.currency_rupee,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRoleChangeDialog(models.AppUser user) {
    models.UserRole? selectedRole = user.role;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${user.fullName}'),
              Text('Email: ${user.email}'),
              const SizedBox(height: 16),
              const Text('Select new role:'),
              const SizedBox(height: 8),
              ...models.UserRole.values
                .where((role) => _isRoleChangeAllowed(user.role, role))
                .map((role) => RadioListTile<models.UserRole>(
                title: Text(role.name.toUpperCase()),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) => setDialogState(() => selectedRole = value),
                subtitle: Text(_getRoleDescription(role)),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRole != null && selectedRole != user.role
                  ? () async {
                      try {
                        await _adminService.updateUserRole(user.uid, selectedRole!);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User role updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating role: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Update Role'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(models.UserRole role) {
    switch (role) {
      case models.UserRole.customer:
        return 'Can browse and purchase products';
      case models.UserRole.admin:
        return 'Can manage products and access admin features';
      case models.UserRole.superAdmin:
        return 'Full system access with user management';
    }
  }

  // Check if role change is allowed based on business rules
  bool _isRoleChangeAllowed(models.UserRole currentRole, models.UserRole newRole) {
    // SuperAdmin role cannot be changed (neither from nor to)
    if (currentRole == models.UserRole.superAdmin || newRole == models.UserRole.superAdmin) {
      return false;
    }
    
    // Cannot demote Admin to Customer (to prevent orphaned products)
    if (currentRole == models.UserRole.admin && newRole == models.UserRole.customer) {
      return false;
    }
    
    // Don't show current role as an option
    if (currentRole == newRole) {
      return false;
    }
    
    return true;
  }

  Future<Map<String, dynamic>> _getUserStatistics(String userId) async {
    try {
      return await _adminService.getUserStatistics(userId);
    } catch (e) {
      return {'totalOrders': 0, 'totalSpent': 0.0};
    }
  }
}
