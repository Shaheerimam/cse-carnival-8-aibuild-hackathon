import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../theme/app_theme.dart';

enum _AuthMode { login, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _identifierController = TextEditingController();

  static const _departments = <String>[
    'CSE',
    'EEE',
    'CE',
    'ME',
    'BBA',
    'English',
    'Architecture',
    'Administration',
  ];

  static const _roles = <String>['Student', 'Faculty', 'Staff'];

  _AuthMode _mode = _AuthMode.login;
  String _selectedDepartment = _departments.first;
  String _selectedRole = _roles.first;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    setState(() => _errorText = null);

    try {
      final session = context.read<SessionProvider>();
      if (_mode == _AuthMode.login) {
        await session.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await session.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          department: _selectedDepartment,
          role: _selectedRole,
          identifier: _identifierController.text.trim().isEmpty
              ? null
              : _identifierController.text.trim(),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _errorText = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEDE9FE), Color(0xFFF9FAFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo/wordmark-logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _mode == _AuthMode.login ? 'Welcome back' : 'Create your account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mode == _AuthMode.login
                          ? 'Sign in with your email to continue to your department dashboard.'
                          : 'Sign up with your department so CampusOS can personalize your dashboard.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SegmentedButton<_AuthMode>(
                              segments: const [
                                ButtonSegment(
                                  value: _AuthMode.login,
                                  label: Text('Login'),
                                  icon: Icon(Icons.login_rounded),
                                ),
                                ButtonSegment(
                                  value: _AuthMode.signUp,
                                  label: Text('Sign up'),
                                  icon: Icon(Icons.person_add_alt_rounded),
                                ),
                              ],
                              selected: {_mode},
                              onSelectionChanged: (selection) {
                                setState(() => _mode = selection.first);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (_mode == _AuthMode.signUp) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  hintText: 'Enter your name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) {
                                  if (_mode == _AuthMode.login) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'name@campus.edu',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: _mode == _AuthMode.login
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (_mode == _AuthMode.signUp) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: Icon(Icons.lock_reset_rounded),
                                ),
                                validator: (value) {
                                  if (_mode == _AuthMode.login) return null;
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _identifierController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Student / staff ID',
                                  hintText: 'Optional',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'User type',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _roles
                                    .map(
                                      (role) => ChoiceChip(
                                        label: Text(role),
                                        selected: _selectedRole == role,
                                        onSelected: (_) {
                                          setState(() => _selectedRole = role);
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 18),
                              DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  prefixIcon: Icon(Icons.apartment_outlined),
                                ),
                                items: _departments
                                    .map(
                                      (department) => DropdownMenuItem(
                                        value: department,
                                        child: Text(department),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedDepartment = value);
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (_errorText != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  _errorText!,
                                  style: const TextStyle(color: AppTheme.error),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.2),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  _isSubmitting
                                      ? (_mode == _AuthMode.login ? 'Signing in...' : 'Creating account...')
                                      : (_mode == _AuthMode.login ? 'Login' : 'Create account'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _InfoPill(icon: Icons.shield_outlined, text: 'Firebase login ready'),
                        _InfoPill(icon: Icons.tune_outlined, text: 'Department-aware view'),
                        _InfoPill(icon: Icons.storage_rounded, text: 'User profile in Firestore'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}