import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/constants.dart';
import 'routes/app_routes.dart';
import 'providers/bluetooth_provider.dart';
import 'data/repositories/pairing_repository.dart';
import 'data/repositories/ping_repository.dart';
import 'data/repositories/discussion_repository.dart';
import 'core/bluetooth/bluetooth_manager.dart';

void main() {
  runApp(const SaathiApp());
}

class SaathiApp extends StatelessWidget {
  const SaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories
    final pairingRepo = PairingRepository();
    final pingRepo = PingRepository();
    final discussionRepo = DiscussionRepository();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BluetoothProvider(
            pairingRepository: pairingRepo,
            bluetoothManager: BluetoothManager(
              pairingRepo: pairingRepo,
              pingRepo: pingRepo,
              discussionRepo: discussionRepo,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
