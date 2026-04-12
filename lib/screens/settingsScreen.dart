import 'package:financetracker_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _expenseAlert = true;
  bool _incomeAlert = true;
  bool _budgetAlert = true;
  bool _billSplitAlert = true;

  //loading state for first time
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFromCacheThenNetwork();
  }

  Future<void> _loadFromCacheThenNetwork() async {
    final prefs = await SharedPreferences.getInstance();

    //get saved data from phone storage
    final cachedName = prefs.getString('cached_name') ?? '';
    final cachedPhone = prefs.getString('cached_phone') ?? '';
    final cachedEmail = prefs.getString('cached_email') ?? '';

    setState(() {
      _nameController.text = cachedName;
      _phoneController.text = cachedPhone;
      _emailController.text = cachedEmail;
      _expenseAlert = prefs.getBool('cached_notify_expense') ?? true;
      _incomeAlert = prefs.getBool('cached_notify_income') ?? true;
      _budgetAlert = prefs.getBool('cached_notify_budget') ?? true;
      _billSplitAlert = prefs.getBool('cached_notify_bill_split') ?? true;
      //stop loading and show data
      _isLoading = false; 
    });

    //get latest data after showing cached data
    _refreshFromBackend();
  }

  Future<void> _refreshFromBackend() async {
    try {
      final data = await _settingsService.getSettings();
      final prefs = await SharedPreferences.getInstance();

      //saving new data locally
      await prefs.setString('cached_name', data['name'] ?? '');
      await prefs.setString('cached_phone', data['phone'] ?? '');
      await prefs.setString('cached_email', data['email'] ?? '');
      await prefs.setBool('cached_notify_expense', data['notify_expense'] ?? true);
      await prefs.setBool('cached_notify_income', data['notify_income'] ?? true);
      await prefs.setBool('cached_notify_budget', data['notify_budget'] ?? true);
      await prefs.setBool('cached_notify_bill_split', data['notify_bill_split'] ?? true);

      //checking if widget is still active before calling setState
      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _expenseAlert = data['notify_expense'] ?? true;
          _incomeAlert = data['notify_income'] ?? true;
          _budgetAlert = data['notify_budget'] ?? true;
          _billSplitAlert = data['notify_bill_split'] ?? true;
        });
      }
    } catch (error) {
      print("Background refresh failed: $error");
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _settingsService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      //save data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_name', _nameController.text.trim());
      await prefs.setString('cached_phone', _phoneController.text.trim());

      _showSuccess("Profile updated successfully!");
    } catch (error) {
      _showError("Failed to update profile.");
    }
    setState(() => _isSaving = false);
  }

  Future<void> _saveNotificationPrefs() async {
    try {
      await _settingsService.updateNotificationPrefs(
        notifyExpense: _expenseAlert,
        notifyIncome: _incomeAlert,
        notifyBudget: _budgetAlert,
        notifyBillSplit: _billSplitAlert,
      );

      //save settings locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cached_notify_expense', _expenseAlert);
      await prefs.setBool('cached_notify_income', _incomeAlert);
      await prefs.setBool('cached_notify_budget', _budgetAlert);
      await prefs.setBool('cached_notify_bill_split', _billSplitAlert);
    } catch (error) {
      _showError("Failed to save. Please try again.");
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');

      //tell backend to delete the session
      if (refreshToken != null) {
        await _settingsService.logout(refreshToken);
      }

      //clearing local data
      await prefs.clear();

      //checking if widget is still active before navigating
      if (mounted) {
        //navigation to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (error) {
      //if error still logout user
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      //checking if widget is still active before navigating
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.teal[700],
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red[600],
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Change Password",
                  style: GoogleFonts.karma(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildTextField(currentCtrl, "Current Password", obscure: true),
              const SizedBox(height: 10),
              _buildTextField(newCtrl, "New Password", obscure: true),
              const SizedBox(height: 10),
              _buildTextField(confirmCtrl, "Confirm New Password", obscure: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    //checking if both passwords match
                    if (newCtrl.text != confirmCtrl.text) {
                      _showError("Passwords do not match!");
                      return;
                    }
                    try {
                      await _settingsService.changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      Navigator.pop(context);
                      _showSuccess("Password changed successfully!");
                    } catch (e) {
                      _showError("Failed to change password.");
                    }
                  },
                  child: const Text("Update Password",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Text("Settings",
            style: GoogleFonts.karma(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FOR PROFILE SECTION
            _sectionTitle("Profile"),
            const SizedBox(height: 12),
            _buildTextField(_nameController, "Full Name"),
            const SizedBox(height: 10),
            _buildTextField(_phoneController, "Phone Number",
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _buildReadOnlyEmailField(_emailController.text),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Save Profile",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 30),

            // FOR SECURITY SECTION
            _sectionTitle("Security"),
            const SizedBox(height: 12),
            _buildTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: _showChangePasswordSheet,
            ),

            const SizedBox(height: 30),

            // NOTIFICATIONS SECTION
            _sectionTitle("Notifications"),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  _buildToggle("Expense Alerts", _expenseAlert, (val) {
                    setState(() => _expenseAlert = val);
                    _saveNotificationPrefs();
                  }),
                  _divider(),
                  _buildToggle("Income Alerts", _incomeAlert, (val) {
                    setState(() => _incomeAlert = val);
                    _saveNotificationPrefs();
                  }),
                  _divider(),
                  _buildToggle("Budget Limit Alerts", _budgetAlert, (val) {
                    setState(() => _budgetAlert = val);
                    _saveNotificationPrefs();
                  }),
                  _divider(),
                  _buildToggle("Bill Split Alerts", _billSplitAlert, (val) {
                    setState(() => _billSplitAlert = val);
                    _saveNotificationPrefs();
                  }),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // APP INFO SECTION
            _sectionTitle("App Info"),
            const SizedBox(height: 12),
            _buildTile(
              icon: Icons.info_outline,
              title: "About App",
              onTap: () => showAboutDialog(
                context: context,
                applicationName: "Smart Budget",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2026 Smart Budget App",
              ),
            ),
            const SizedBox(height: 10),
            _buildTile(
              icon: Icons.help_outline,
              title: "FAQ & Help",
              onTap: () => _showSuccess("FAQ page yet to upload!"),
            ),
            const SizedBox(height: 10),
            _buildTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () => _showSuccess("Privacy Policy yet to upload!"),
            ),

            const SizedBox(height: 30),

            // LOGOUT SECTION
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout",
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Logout?"),
                      content:
                          const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("No")),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Yes")),
                      ],
                    ),
                  );
                  if (confirm == true) _logout();
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

//Helper widgets
  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.karma(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800]));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.teal[700]),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal[700]!)),
      ),
    );
  }

  Widget _buildReadOnlyEmailField(String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[350]!,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Email (cannot be changed)",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal[700]),
            const SizedBox(width: 15),
            Expanded(
                child: Text(title, style: GoogleFonts.karma(fontSize: 16))),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
      String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.karma(fontSize: 15)),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.teal[700]),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]);
}
