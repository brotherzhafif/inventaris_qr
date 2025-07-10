import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class UserFormDialog extends StatefulWidget {
  final User? user;
  final VoidCallback? onSaved;

  const UserFormDialog({super.key, this.user, this.onSaved});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  UserRole _selectedRole = UserRole.viewer;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _fullNameController.text = widget.user!.fullName;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Tambah Pengguna' : 'Edit Pengguna'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap*',
                    hintText: 'Masukkan nama lengkap',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username*',
                    hintText: 'Masukkan username',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    if (value.length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password (only show if creating new user or editing)
                if (widget.user == null || _passwordController.text.isNotEmpty)
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: widget.user == null
                          ? 'Password*'
                          : 'Password Baru',
                      hintText: widget.user == null
                          ? 'Masukkan password'
                          : 'Kosongkan jika tidak ingin mengubah',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (widget.user == null) {
                        // Required for new user
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                      } else {
                        // Optional for existing user, but if provided must be valid
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                      }
                      return null;
                    },
                  ),

                if (widget.user != null && _passwordController.text.isEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _passwordController.text =
                            ' '; // Trigger password field
                      });
                    },
                    child: const Text('Ubah Password'),
                  ),

                const SizedBox(height: 16),

                // Role
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role*'),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(_getRoleIcon(role), color: _getRoleColor(role)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role.displayName),
                              Text(
                                _getRoleDescription(role),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Role Permissions Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hak Akses ${_selectedRole.displayName}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildPermissionInfo(
                        'Kelola Barang',
                        _selectedRole.canManageItems,
                      ),
                      _buildPermissionInfo(
                        'Kelola Transaksi',
                        _selectedRole.canManageTransactions,
                      ),
                      _buildPermissionInfo(
                        'Scan Barcode',
                        _selectedRole.canScanBarcode,
                      ),
                      _buildPermissionInfo(
                        'Lihat Laporan',
                        _selectedRole.canViewReports,
                      ),
                      _buildPermissionInfo(
                        'Kelola Pengguna',
                        _selectedRole.canManageUsers,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.user == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  Widget _buildPermissionInfo(String label, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.petugas:
        return Icons.person_pin;
      case UserRole.viewer:
        return Icons.visibility;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.petugas:
        return Colors.blue;
      case UserRole.viewer:
        return Colors.green;
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Akses penuh ke semua fitur';
      case UserRole.petugas:
        return 'Dapat kelola barang dan transaksi';
      case UserRole.viewer:
        return 'Hanya dapat melihat data';
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.user == null) {
        // Create new user
        final user = User(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: _selectedRole,
          createdAt: DateTime.now(),
        );

        final success = await authProvider.registerUser(user);

        if (mounted) {
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengguna berhasil ditambahkan'),
                backgroundColor: Colors.green,
              ),
            );
            widget.onSaved?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Gagal menambah pengguna',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Update existing user
        final user = widget.user!.copyWith(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim().isEmpty
              ? widget.user!.password
              : _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: _selectedRole,
        );

        final success = await authProvider.updateUser(user);

        if (mounted) {
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengguna berhasil diupdate'),
                backgroundColor: Colors.green,
              ),
            );
            widget.onSaved?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Gagal mengupdate pengguna',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
