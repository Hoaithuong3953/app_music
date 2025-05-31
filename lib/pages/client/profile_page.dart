import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/custom_alert_dialog.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.user?.firstName ?? 'User';
    final lastName = userProvider.user?.lastName ?? '';
    final userEmail = userProvider.user?.email ?? 'user@example.com';
    final avatarImgURL = userProvider.user?.avatarImgURL; // Lấy avatarImgURL

    // Kết hợp firstName và lastName
    final fullName = '$firstName $lastName'.trim();

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
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
                      backgroundImage: avatarImgURL != null ? NetworkImage(avatarImgURL) : null, // Hiển thị ảnh từ avatarImgURL
                      child: avatarImgURL == null // Nếu không có avatarImgURL, hiển thị chữ cái đầu
                          ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: screenHeight * 0.08,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    fullName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: screenHeight * 0.03,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  if (userProvider.user?.isPremium == true && 
                      (userProvider.user?.premiumExpired == null || 
                       userProvider.user!.premiumExpired!.isAfter(DateTime.now())))
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: screenHeight * 0.02,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.018,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                      print('About to navigate to EditProfilePage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                      print('Navigation completed');
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  _buildListTile(
                    context,
                    icon: Icons.workspace_premium,
                    iconColor: Colors.amber,
                    title: 'Premium',
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    onTap: () async {
                      final user = Provider.of<UserProvider>(context, listen: false).user;
                      if (user?.isPremium == true && (user?.premiumExpired == null || user!.premiumExpired!.isAfter(DateTime.now()))) {
                        final expired = user!.premiumExpired != null ? '\nHạn đến: ' + user.premiumExpired!.toString().split(' ')[0] : '';
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Premium'),
                            content: Text('Bạn đã là thành viên Premium.$expired'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
                            ],
                          ),
                        );
                        return;
                      }
                      // Nếu chưa premium, cho chọn gói
                      showDialog(
                        context: context,
                        builder: (context) {
                          String? selected;
                          return StatefulBuilder(
                            builder: (context, setState) => AlertDialog(
                              title: Text('Đăng ký Premium'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RadioListTile<String>(
                                    title: Text('1 tháng (100.000đ)'),
                                    value: '1month',
                                    groupValue: selected,
                                    onChanged: (v) => setState(() => selected = v),
                                  ),
                                  RadioListTile<String>(
                                    title: Text('3 tháng (270.000đ)'),
                                    value: '3months',
                                    groupValue: selected,
                                    onChanged: (v) => setState(() => selected = v),
                                  ),
                                  RadioListTile<String>(
                                    title: Text('12 tháng (900.000đ)'),
                                    value: '12months',
                                    groupValue: selected,
                                    onChanged: (v) => setState(() => selected = v),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
                                ElevatedButton(
                                  onPressed: selected == null ? null : () async {
                                    try {
                                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                                      final url = await userProvider.upgradeToPremium(selected!);
                                      Navigator.pop(context); // Đóng dialog sau khi đã lấy xong url
                                      print('Payment URL: ' + url);
                                      if (url.isNotEmpty) {
                                        // Mở dialog xác nhận
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Thanh toán Premium'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Nhấn OK để mở trang thanh toán.'),
                                                SizedBox(height: 16),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    final uri = Uri.parse(url);
                                                    if (kIsWeb) {
                                                      if (await canLaunchUrl(uri)) {
                                                        await launchUrl(uri, webOnlyWindowName: '_blank');
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Không mở được link thanh toán!')),
                                                        );
                                                      }
                                                    } else {
                                                      if (await canLaunchUrl(uri)) {
                                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Không mở được link thanh toán!')),
                                                        );
                                                      }
                                                    }
                                                    // Sau khi mở trang thanh toán, show nút kiểm tra trạng thái
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: Text('Xác nhận thanh toán'),
                                                        content: Text('Sau khi thanh toán xong, nhấn nút bên dưới để kiểm tra trạng thái Premium.'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.pop(context);
                                                              final rootContext = Navigator.of(context, rootNavigator: true).context;
                                                              try {
                                                                final userProvider = Provider.of<UserProvider>(rootContext, listen: false);
                                                                await userProvider.loadUser();
                                                                final isPremium = userProvider.user?.isPremium == true;
                                                                if (isPremium) {
                                                                  showDialog(
                                                                    context: rootContext,
                                                                    builder: (context) => CustomAlertDialog(
                                                                      isSuccess: true,
                                                                      title: 'Thanh toán thành công',
                                                                      message: 'Bạn đã nâng cấp Premium thành công!',
                                                                      autoDismiss: true,
                                                                      autoDismissDuration: Duration(seconds: 2),
                                                                      onConfirm: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                    ),
                                                                  );
                                                                } else {
                                                                  showDialog(
                                                                    context: rootContext,
                                                                    builder: (context) => CustomAlertDialog(
                                                                      isSuccess: false,
                                                                      title: 'Thanh toán chưa được xác nhận',
                                                                      message: 'Vui lòng thử lại sau hoặc liên hệ hỗ trợ.',
                                                                      autoDismiss: true,
                                                                      autoDismissDuration: Duration(seconds: 2),
                                                                      onConfirm: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                    ),
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                showDialog(
                                                                  context: rootContext,
                                                                  builder: (context) => CustomAlertDialog(
                                                                    isSuccess: false,
                                                                    title: 'Lỗi',
                                                                    message: 'Không kiểm tra được trạng thái thanh toán. Vui lòng thử lại.',
                                                                    autoDismiss: true,
                                                                    autoDismissDuration: Duration(seconds: 4),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: Text('Tôi đã thanh toán'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                  child: Text('OK'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Không nhận được link thanh toán!')),
                                        );
                                      }
                                    } catch (e) {
                                      Navigator.pop(context); // Đóng dialog nếu có lỗi
                                      print('Lỗi đăng ký premium: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi đăng ký premium: $e')),
                                      );
                                    }
                                  },
                                  child: Text('Đăng ký'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
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