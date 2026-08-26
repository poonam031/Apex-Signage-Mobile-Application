import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: 'admin@signage.com');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onQuickRoleSelect(String email, String pass) {
    setState(() {
      _identifierController.text = email;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.print_outlined,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Apex Signage & Print',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Production & Field Operations System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email or Phone Field
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address or Phone',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your email or phone' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your password' : null,
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    label: 'Sign In to Workspace',
                    isLoading: auth.isLoading,
                    icon: Icons.login,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        auth.login(_identifierController.text, _passwordController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  // Quick Role Selector for paired demo testing
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Switch Role (Demo Credentials):',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildRoleChip('Super Admin', 'admin@signage.com', 'admin123', AppColors.primary),
                      _buildRoleChip('Field Boy', 'fieldboy@signage.com', 'field123', AppColors.accent),
                      _buildRoleChip('Designer/Op', 'designer@signage.com', 'design123', Colors.indigo),
                      _buildRoleChip('Installer Lead', 'installer@signage.com', 'install123', Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String email, String pass, Color color) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 6,
      ),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      onPressed: () => _onQuickRoleSelect(email, pass),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
