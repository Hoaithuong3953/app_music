import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.user?.firstName ?? 'User';
    final lastName = userProvider.user?.lastName ?? '';
    final userEmail = userProvider.user?.email ?? 'user@example.com';

    // Kết hợp firstName và lastName
    final fullName = '$firstName $lastName'.trim();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.03, screenWidth * 0.04, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: screenWidth * 0.01),
                  ),
                  child: CircleAvatar(
                    radius: screenHeight * 0.1,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.08,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: screenHeight * 0.03,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  userEmail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: screenHeight * 0.02,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                _buildListTile(
                  context,
                  icon: Icons.edit,
                  iconColor: Theme.of(context).highlightColor,
                  title: 'Edit Profile',
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  onTap: () {
                    Navigator.pushNamed(context, '/edit-profile');
                  },
                ),
                SizedBox(height: screenHeight * 0.01),
                _buildListTile(
                  context,
                  icon: Icons.lock,
                  iconColor: Theme.of(context).highlightColor,
                  title: 'Change Password',
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  onTap: () {
                    Navigator.pushNamed(context, '/change-password');
                  },
                ),
                SizedBox(height: screenHeight * 0.01),
                _buildListTile(
                  context,
                  icon: Icons.settings,
                  iconColor: Theme.of(context).highlightColor,
                  title: 'Settings',
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                ),
                SizedBox(height: screenHeight * 0.01),
                _buildListTile(
                  context,
                  icon: Icons.exit_to_app,
                  iconColor: Colors.red,
                  title: 'Log Out',
                  textColor: Colors.red,
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  onTap: () async {
                    try {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      await userProvider.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        Color? textColor,
        required double screenHeight,
        required double screenWidth,
        VoidCallback? onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: Theme.of(context).colorScheme.secondary, width: screenWidth * 0.005),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
          size: screenHeight * 0.03,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: screenHeight * 0.02,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: screenHeight * 0.02,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015,
          horizontal: screenWidth * 0.04,
        ),
        textColor: textColor,
        onTap: onTap,
      ),
    );
  }
}