import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../services/test_data_service.dart';
import '../../../core/widgets/manager_footer.dart';

class TestDataScreen extends ConsumerStatefulWidget {
  const TestDataScreen({super.key});

  @override
  ConsumerState<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends ConsumerState<TestDataScreen> {
  final TestDataService _testDataService = TestDataService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _generateTestData() async {
    final rawdhaId = ref.read(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      _showMessage('❌ Rawdha ID not found', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Generate Large Dataset',
      'This will create 100 parents and 160 students with Arabic names. Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating 100 parents and 160 students...';
    });

    try {
      await _testDataService.seedLargeDataset(rawdhaId);
      _showMessage('✅ Successfully generated 100 parents and 160 students!');
    } catch (e) {
      _showMessage('❌ Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _clearTestData() async {
    final rawdhaId = ref.read(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      _showMessage('❌ Rawdha ID not found', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Clear All Data',
      'This will delete ALL parents, students, and payments for this school. Are you sure?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all data...';
    });

    try {
      await _testDataService.clearTestData(rawdhaId);
      _showMessage('✅ All data cleared successfully!');
    } catch (e) {
      _showMessage('❌ Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _clearCache() async {
    final rawdhaId = ref.read(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      _showMessage('❌ Rawdha ID not found', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing cache...';
    });

    try {
      await _testDataService.clearAllCache(rawdhaId);
      _showMessage('✅ Cache cleared successfully!');
    } catch (e) {
      _showMessage('❌ Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _clearAllCacheGlobally() async {
    final confirmed = await _showConfirmDialog(
      'Clear All Cache',
      'This will clear cache for ALL schools. Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all cache globally...';
    });

    try {
      await _testDataService.clearAllCacheGlobally();
      _showMessage('✅ All cache cleared globally!');
    } catch (e) {
      _showMessage('❌ Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('🧪 Test Data & Cache'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage, style: const TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Generate Test Data Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Generate Large Test Dataset',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This will generate:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.people, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('100 Parents with Arabic names'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.school, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('160 Students with Arabic names'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.payment, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('100 Payments (current month)'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _generateTestData,
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Generate Test Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clear Data Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🗑️ Clear Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _clearTestData,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Clear All Data (Parents, Students, Payments)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cache Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🧹 Cache Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _clearCache,
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Clear Cache (This School)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _clearAllCacheGlobally,
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Clear All Cache (All Schools)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }
}
