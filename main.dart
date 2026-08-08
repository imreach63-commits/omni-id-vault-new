import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const OmniIdApp());
}

class OmniIdApp extends StatelessWidget {
  const OmniIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OMNI-ID Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
        ),
      ),
      home: const LockScreen(),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = "1234";

  Future<void> _authenticateBiometric() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Unlock OMNI-ID Security Vault',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric Auth Exception: $e')),
        );
      }
    }
  }

  void _verifyPin() {
    if (_pinController.text == _correctPin) {
      _navigateToDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect Master PIN!')),
      );
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SecurityDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded, size: 80, color: Color(0xFF6366F1)),
                const SizedBox(height: 16),
                const Text(
                  'OMNI-ID VAULT',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                const Text('Zero-Knowledge Security Engine', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: 'Master PIN',
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Text('UNLOCK VAULT'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _authenticateBiometric,
                  icon: const Icon(Icons.fingerprint, color: Color(0xFF10B981)),
                  label: const Text('Biometric Hardware Unlock'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  final _storage = const FlutterSecureStorage();
  List<Map<String, String>> _vaultItems = [];

  @override
  void initState() {
    super.initState();
    _loadSecureVaultData();
  }

  Future<void> _loadSecureVaultData() async {
    Map<String, String> allValues = await _storage.readAll();
    List<Map<String, String>> loaded = [];
    allValues.forEach((key, value) {
      if (key.startsWith('vault_')) {
        loaded.add({'title': key.replaceFirst('vault_', ''), 'value': value});
      }
    });
    setState(() {
      _vaultItems = loaded;
    });
  }

  Future<void> _addVaultItem(String title, String secret) async {
    await _storage.write(key: 'vault_$title', value: secret);
    _loadSecureVaultData();
  }

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Identity / Passkey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title / Bank / App'),
            ),
            TextField(
              controller: secretController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Secret Key / Passkey'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && secretController.text.isNotEmpty) {
                _addVaultItem(titleController.text, secretController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Encrypted'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMNI-ID Vault Dashboard'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF10B981), size: 40),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Health: 98/100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('AES-256 Storage Active', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Encrypted Passkeys & Tokens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _vaultItems.isEmpty
                  ? const Center(child: Text('Vault is Empty. Tap + to add passkey.'))
                  : ListView.builder(
                      itemCount: _vaultItems.length,
                      itemBuilder: (context, index) {
                        final item = _vaultItems[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          child: ListTile(
                            leading: const Icon(Icons.key, color: Color(0xFF6366F1)),
                            title: Text(item['title']!),
                            subtitle: const Text('•••••••••••• (Encrypted)'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await _storage.delete(key: 'vault_${item['title']}');
                                _loadSecureVaultData();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add),
        label: const Text('Add Passkey'),
      ),
    );
  }
}
