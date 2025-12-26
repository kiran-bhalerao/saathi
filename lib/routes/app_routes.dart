import 'package:flutter/material.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/onboarding/screens/pin_setup_screen.dart';
import '../features/onboarding/screens/gender_selection_screen.dart';
import '../features/female/screens/female_home_screen.dart';
import '../features/female/screens/chapter_detail_screen.dart';
import '../features/female/screens/chapter_reader_screen.dart';
import '../features/male/screens/male_home_screen.dart';
import '../features/male/screens/male_ping_view_screen.dart';
import '../features/female/screens/settings_screen.dart';
import '../data/models/chapter_model.dart';
import '../data/models/sync_models.dart';

/// App routes configuration
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String pinSetup = '/pin-setup';
  static const String genderSelection = '/gender-selection';
  static const String femaleHome = '/female-home';
  static const String maleHome = '/male-home';
  static const String chapterDetail = '/chapter-detail';
  static const String chapterReader = '/chapter-reader';
  static const String malePingView = '/male-ping-view';
  static const String settings = '/settings';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
        
      case pinSetup:
        return MaterialPageRoute(builder: (_) => const PINSetupScreen());
        
      case genderSelection:
        return MaterialPageRoute(builder: (_) => const GenderSelectionScreen());
        
      case femaleHome:
        return MaterialPageRoute(builder: (_) => const FemaleHomeScreen());
        
      case maleHome:
        return MaterialPageRoute(builder: (_) => const MaleHomeScreen());
      
      case chapterDetail:
        final chapterNumber = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ChapterDetailScreen(chapterNumber: chapterNumber),
        );
        
      case chapterReader:
        final chapter = settings.arguments as Chapter;
        return MaterialPageRoute(
          builder: (_) => ChapterReaderScreen(chapter: chapter),
        );
      
      case malePingView:
        final ping = settings.arguments as PingedSection;
        return MaterialPageRoute(
          builder: (_) => MalePingViewScreen(ping: ping),
        );
      
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
