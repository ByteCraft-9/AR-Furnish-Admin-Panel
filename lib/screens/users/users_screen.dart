// ignore_for_file: library_private_types_in_public_api, unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/sidebar.dart';
import 'user_details_screen.dart';
import 'add_edit_user_screen.dart';
import '../widgets/line_chart.dart';
import '../widgets/pie_chart.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UsersScreenState createState() {
    return _UsersScreenState();
  }
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 4;
  TabController? _tabController;
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabChange);

    // Make sure we load data as soon as screen is opened
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load on first build to prevent repeated loading
    if (!_didInitialLoad) {
      _didInitialLoad = true;
      // Use addPostFrameCallback to ensure we're not updating state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserData();
      });
    }
  }

  bool _didInitialLoad = false;

  void _handleTabChange() {
    // Load chart data only when switching to analytics tab
    if (_tabController?.index == 1) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.hasLoadedChartData) {
        userProvider.loadChartData();
      }
    }
  }

  Future<void> _loadUserData() async {
    // Use a direct access to ensure we're getting the provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Ensure data is loaded
    userProvider.loadUsers();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Apply role filter
    if (_selectedRoleFilter == 'All') {
      userProvider.setRoleFilter(null);
    } else {
      userProvider.setRoleFilter(_selectedRoleFilter.toLowerCase());
    }

    // Apply status filter
    if (_selectedStatusFilter == 'All') {
      userProvider.setStatusFilter(null);
    } else if (_selectedStatusFilter == 'Active') {
      userProvider.setStatusFilter(true);
    } else {
      userProvider.setStatusFilter(false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedRoleFilter = 'All';
      _selectedStatusFilter = 'All';
      _searchController.clear();
    });

    Provider.of<UserProvider>(context, listen: false).clearFilters();
  }

  void _handleSearch(String query) {
    Provider.of<UserProvider>(context, listen: false).setSearchQuery(query);
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              userProvider.deleteUser(user);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuspendConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Suspend User' : 'Activate User'),
        content: Text(user.isActive
            ? 'Are you sure you want to suspend ${user.name}? They will not be able to access the system until reactivated.'
            : 'Are you sure you want to reactivate ${user.name}? They will regain access to the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              userProvider.toggleUserStatus(user);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(user.isActive
                      ? 'User suspended successfully'
                      : 'User activated successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: user.isActive ? Colors.orange : Colors.green),
            child: Text(user.isActive ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditUserScreen(),
      ),
    );
  }

  void _navigateToEditUser(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUserScreen(user: user),
      ),
    );
  }

  void _navigateToUserDetails(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(userId: user.id),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper methods for UI
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _confirmToggleStatus(UserModel user) {
    final newStatus = !user.isActive;
    final statusText = newStatus ? 'activate' : 'deactivate';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text('Are you sure you want to $statusText ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              userProvider.toggleUserStatus(user);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              userProvider.deleteUser(user);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final userProvider = Provider.of<UserProvider>(context);
    final users = userProvider.users;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar for large screens
          if (!isMobile)
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (isMobile) const SizedBox(width: 8),
                          const Text(
                            'User Management',
                            style: TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: isMobile ? 150 : 250,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search users...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onChanged: _handleSearch,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(isMobile ? '' : 'Add User'),
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: 8)),
                            onPressed: _navigateToAddUser,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tab bar
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primaryColor,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        tabs: const [
                          Tab(text: 'Users'),
                          Tab(text: 'Analytics'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Error message display
                if (userProvider.errorMessage != null)
                  Container(
                    color: Colors.red[100],
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userProvider.errorMessage!,
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadUserData,
                          tooltip: 'Try again',
                        ),
                      ],
                    ),
                  ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Users list tab
                      _buildUsersTab(users, userProvider, isMobile),

                      // Analytics tab
                      _buildAnalyticsTab(userProvider, isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(
      List<UserModel> users, UserProvider userProvider, bool isMobile) {
    // Filter controls
    final filterControls = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Role filter
              DropdownButton<String?>(
                value: userProvider.roleFilter,
                hint: const Text('Role'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Roles'),
                  ),
                  ...['admin', 'manager', 'customer'].map((role) {
                    return DropdownMenuItem<String?>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    );
                  }),
                ],
                onChanged: (value) {
                  userProvider.setRoleFilter(value);
                  userProvider.loadUsers();
                },
              ),
              const SizedBox(width: 16),
              // Status filter
              DropdownButton<bool?>(
                value: userProvider.statusFilter,
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem<bool?>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: true,
                    child: Text('Active'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: false,
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: (value) {
                  userProvider.setStatusFilter(value);
                  userProvider.loadUsers();
                },
              ),
              const SizedBox(width: 16),
              // Clear filters
              if (userProvider.roleFilter != null ||
                  userProvider.statusFilter != null ||
                  userProvider.searchQuery.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black),
                  onPressed: () {
                    userProvider.clearFilters();
                    _searchController.clear();
                    userProvider.loadUsers();
                  },
                ),
            ],
          ),
        ],
      ),
    );

    return userProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : users.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  filterControls,
                  Expanded(child: _buildEmptyState()),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      filterControls,
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: isMobile
                                ? _buildMobileUserList(users)
                                : _buildDesktopUserTable(users),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
  }

  Widget _buildDesktopUserTable(List<UserModel> users) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl != null
                              ? null
                              : Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(user.email)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role[0].toUpperCase() + user.role.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: user.isActive,
                      onChanged: (value) {
                        _confirmToggleStatus(user);
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDate(user.createdAt),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditUser(user),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteUser(user),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            userProvider.isLoading ? 'Loading users...' : 'No users found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (!userProvider.isLoading) ...[
            Text(
              'Try adjusting your filters or add some users',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First User'),
              onPressed: _navigateToAddUser,
            ),
          ] else ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileUserList(List<UserModel> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _navigateToUserDetails(user),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserAvatar(user),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRoleBadge(user.role),
                            const SizedBox(width: 8),
                            _buildStatusBadge(user.isActive),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              color: Colors.blue,
                              onPressed: () => _navigateToEditUser(user),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(
                                user.isActive
                                    ? Icons.block
                                    : Icons.check_circle,
                                size: 18,
                              ),
                              color:
                                  user.isActive ? Colors.orange : Colors.green,
                              onPressed: () =>
                                  _showSuspendConfirmation(context, user),
                              tooltip: user.isActive ? 'Suspend' : 'Activate',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              color: Colors.red,
                              onPressed: () =>
                                  _showDeleteConfirmation(context, user),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primaryColor,
      backgroundImage:
          user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
      child: user.photoUrl == null
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildRoleBadge(String role) {
    final Map<String, Color> roleColors = {
      'admin': Colors.red,
      'manager': Colors.purple,
      'staff': Colors.blue,
      'customer': Colors.green,
    };

    final color = roleColors[role.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.red;
    final text = isActive ? 'Active' : 'Suspended';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(UserProvider userProvider, bool isMobile) {
    return userProvider.isLoadingChartData
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'User Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // User registrations by month
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Registrations (Past 12 Months)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: userProvider.userRegistrationsByMonth.isEmpty
                              ? const Center(
                                  child: Text('No registration data available'),
                                )
                              : _buildChartSafely(
                                  userProvider.userRegistrationsByMonth),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // User roles distribution
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Roles Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: userProvider.userRoleDistribution.isEmpty
                              ? const Center(
                                  child: Text(
                                      'No role distribution data available'),
                                )
                              : _buildPieChartSafely(
                                  userProvider.userRoleDistribution),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  // Safely build a line chart or fallback to text representation
  Widget _buildChartSafely(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    try {
      return LineChartWidget(data: data);
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Could not display chart'),
            const SizedBox(height: 8),
            Text(
              'Data: ${data.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  // Safely build a pie chart or fallback to text representation
  Widget _buildPieChartSafely(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    try {
      return PieChartWidget(data: data);
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Could not display chart'),
            const SizedBox(height: 8),
            Text(
              'Data: ${data.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}
