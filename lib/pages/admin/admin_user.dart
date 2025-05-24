import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/user_provider.dart';

class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  _AdminUserPageState createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = false;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final email = user['email']?.toLowerCase() ?? '';
          final firstName = user['firstName']?.toLowerCase() ?? '';
          return email.contains(query) || firstName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchUsers({String? searchQuery}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uri = Uri.parse(
        'http://localhost:8080/api/v1/user?page=$currentPage&limit=$limit${searchQuery != null ? '&email=$searchQuery' : ''}',
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data['data'] is List ? data['data'] : [];
          filteredUsers = users;
          totalCount = data['counts'] ?? 0;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: ${response.statusCode}')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/user/$userId'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/user/register'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create user: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showCreateUserDialog() {
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isEmpty ||
                  firstNameController.text.isEmpty ||
                  lastNameController.text.isEmpty ||
                  mobileController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required')),
                );
                return;
              }
              final userData = {
                'email': emailController.text,
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'mobile': mobileController.text,
                'password': passwordController.text,
                'role': 'user',
              };
              createUser(userData);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void showEditUserDialog(dynamic user) {
    final emailController = TextEditingController(text: user['email']);
    final firstNameController = TextEditingController(text: user['firstName']);
    final lastNameController = TextEditingController(text: user['lastName']);
    final mobileController = TextEditingController(text: user['mobile']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedData = {
                'email': emailController.text,
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'mobile': mobileController.text,
              };
              updateUser(user['_id'], updatedData);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updatedData) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/v1/user/$userId'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm người dùng',
            onPressed: showCreateUserDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm theo email hoặc tên',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return ListTile(
                            leading: user['avatarImgURL'] != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(user['avatarImgURL']),
                                  )
                                : const Icon(Icons.person),
                            title: Text('${user['firstName']} ${user['lastName']}'),
                            subtitle: Text(user['email']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => showEditUserDialog(user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: Text(
                                            'Are you sure you want to delete ${user['firstName']} ${user['lastName']}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              deleteUser(user['_id']);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/admin/user/:uid',
                              arguments: user['_id'],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentPage > 1
                      ? () {
                          setState(() {
                            currentPage--;
                          });
                          fetchUsers();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $currentPage / ${(totalCount / limit).ceil()}'),
                IconButton(
                  onPressed: currentPage < (totalCount / limit).ceil()
                      ? () {
                          setState(() {
                            currentPage++;
                          });
                          fetchUsers();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}