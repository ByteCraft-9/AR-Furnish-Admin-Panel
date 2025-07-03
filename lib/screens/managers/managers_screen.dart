// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/sidebar.dart';
import 'manager_permissions_screen.dart';
import '../users/add_edit_user_screen.dart';

class ManagersScreen extends StatefulWidget {
  const ManagersScreen({super.key});

  @override
  _ManagersScreenState createState() => _ManagersScreenState();
}

class _ManagersScreenState extends State<ManagersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 5;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  void _loadManagers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setRoleFilter('manager');
      userProvider.loadUsers();
    });
  }

  void _handleSearch(String query) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setSearchQuery(query);
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final managers = userProvider.users;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for tablet and desktop
          if (!isMobile)
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
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
                        'Manager Permissions',
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
                            hintText: 'Search managers...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onChanged: _handleSearch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditUserScreen(
                                user: UserModel(
                                  id: '', // Will be set by Firebase
                                  name: '',
                                  email: '',
                                  role: 'manager',
                                  isActive: true,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  permissions:
                                      userProvider.getDefaultPermissions(),
                                ),
                              ),
                            ),
                          ).then((_) => _loadManagers());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Manager'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content area
                Expanded(
                  child: userProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : managers.isEmpty
                          ? _buildEmptyState()
                          : _buildManagersList(managers),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasSearchFilter = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchFilter ? Icons.search_off : Icons.manage_accounts,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchFilter
                ? 'No managers match your search'
                : 'No managers added yet',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasSearchFilter)
            ElevatedButton.icon(
              onPressed: () {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditUserScreen(
                      user: UserModel(
                        id: '', // Will be set by Firebase
                        name: '',
                        email: '',
                        role: 'manager',
                        isActive: true,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        permissions: userProvider.getDefaultPermissions(),
                      ),
                    ),
                  ),
                ).then((_) => _loadManagers());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Manager'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          if (hasSearchFilter)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _handleSearch('');
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManagersList(List<UserModel> managers) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Managers (${managers.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: managers.length,
              itemBuilder: (context, index) {
                final manager = managers[index];
                return _buildManagerCard(manager);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard(UserModel manager) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: manager.photoUrl != null
                  ? NetworkImage(manager.photoUrl!)
                  : null,
              child: manager.photoUrl == null
                  ? Text(
                      manager.name.isNotEmpty
                          ? manager.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manager.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(manager.isActive),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                _buildActionButton(
                  label: 'Permissions',
                  icon: Icons.lock_outline,
                  color: AppColors.primaryColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManagerPermissionsScreen(
                          manager: manager,
                        ),
                      ),
                    ).then((_) => _loadManagers());
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: AppColors.secondaryColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditUserScreen(
                          user: manager,
                        ),
                      ),
                    ).then((_) => _loadManagers());
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: manager.isActive ? 'Suspend' : 'Activate',
                  icon: manager.isActive
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  color: manager.isActive ? Colors.red : Colors.green,
                  onPressed: () => _confirmToggleStatus(manager),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  void _confirmToggleStatus(UserModel manager) {
    final newStatus = !manager.isActive;
    final statusText = newStatus ? 'activate' : 'deactivate';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text('Are you sure you want to $statusText ${manager.name}?'),
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
              userProvider.toggleUserStatus(manager);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
