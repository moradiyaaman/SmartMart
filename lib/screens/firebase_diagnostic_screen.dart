import 'package:flutter/material.dart';
import '../services/admin_service.dart';

/// Firebase Configuration Diagnostic Screen
/// Helps troubleshoot image upload and Firebase setup issues
class FirebaseDiagnosticScreen extends StatefulWidget {
  const FirebaseDiagnosticScreen({super.key});

  @override
  State<FirebaseDiagnosticScreen> createState() => _FirebaseDiagnosticScreenState();
}

class _FirebaseDiagnosticScreenState extends State<FirebaseDiagnosticScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _diagnosticData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _adminService.debugFirebaseConfig();
      setState(() {
        _diagnosticData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticData = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Firebase Diagnostics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDiagnostics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Diagnostics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildConfigCard(),
                  const SizedBox(height: 16),
                  _buildRecommendationsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (_diagnosticData == null) return const SizedBox();

    final hasPlaceholders = _diagnosticData!['hasPlaceholderValues'] == true;
    final storageConfigured = _diagnosticData!['storageConfigured'] == true;
    final isAuthenticated = _diagnosticData!['isAuthenticated'] == true;
    final imageStorageMethod = _diagnosticData!['imageStorageMethod'] ?? 'Unknown';
    final localImagesCount = _diagnosticData!['localImagesCount'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 System Status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('🔧 Firebase Config', !hasPlaceholders ? '✅ Valid' : '❌ Placeholders'),
            _buildStatusRow('📦 Cloud Storage', storageConfigured ? '✅ Firebase Available' : '❌ Not Configured'),
            _buildStatusRow('📱 Local Storage', '✅ Always Available'),
            _buildStatusRow('👤 Authentication', isAuthenticated ? '✅ Logged In' : '❌ Not Logged In'),
            _buildStatusRow('�️ Storage Method', imageStorageMethod),
            _buildStatusRow('📸 Local Images', '$localImagesCount stored locally'),
            _buildStatusRow('✨ Image Upload', '✅ Will Work (Local Fallback)'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    if (_diagnosticData == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ Configuration Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildConfigRow('Project ID', _diagnosticData!['projectId']),
            _buildConfigRow('Storage Bucket', _diagnosticData!['storageBucket']),
            _buildConfigRow('Auth Domain', _diagnosticData!['authDomain']),
            _buildConfigRow('Current User', _diagnosticData!['currentUser'] ?? 'Not logged in'),
            const SizedBox(height: 8),
            Text('📱 Local Storage Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
            const SizedBox(height: 4),
            _buildConfigRow('Images Directory', _diagnosticData!['localStorageDir']),
            _buildConfigRow('Local Images Count', '${_diagnosticData!['localImagesCount']} files'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (_diagnosticData == null) return const SizedBox();

    final hasPlaceholders = _diagnosticData!['hasPlaceholderValues'] == true;
    final storageConfigured = _diagnosticData!['storageConfigured'] == true;
    final isAuthenticated = _diagnosticData!['isAuthenticated'] == true;

    List<String> recommendations = [];

    if (hasPlaceholders) {
      recommendations.add('🔧 Update firebase_options.dart with your actual Firebase project values');
    }
    if (!storageConfigured) {
      recommendations.add('📦 Enable Firebase Storage in your Firebase Console');
    }
    if (!isAuthenticated) {
      recommendations.add('👤 Login with an admin account to test image uploads');
    }

    if (recommendations.isEmpty) {
      if (storageConfigured) {
        recommendations.add('✅ Everything looks perfect! Images will be stored in Firebase Storage.');
      } else {
        recommendations.add('✅ Firebase Storage not configured, but that\'s fine! Images will be stored locally on your device.');
        recommendations.add('📱 Local storage is automatic and requires no setup - your images are safe!');
      }
    } else {
      recommendations.add('📱 Don\'t worry - even with these issues, images will still be saved locally to your device!');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Recommendations',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(rec, style: const TextStyle(fontSize: 14)),
            )),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Show setup guide
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('📖 Setup Guide'),
                    content: const Text(
                      'For complete step-by-step instructions to fix image upload issues:\n\n'
                      '1. Check the FIREBASE_SETUP_COMPLETE.md file in your project root\n'
                      '2. Follow all steps carefully\n'
                      '3. Run this diagnostic again to verify\n\n'
                      'The guide covers Firebase project setup, Storage configuration, and admin user creation.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.book),
              label: const Text('View Setup Guide'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(status, style: TextStyle(
            color: status.contains('✅') ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String? value) {
    final displayValue = value ?? 'Not set';
    final isPlaceholder = value?.contains('your-') == true;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            displayValue,
            style: TextStyle(
              color: isPlaceholder ? Colors.red : Colors.grey.shade700,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}