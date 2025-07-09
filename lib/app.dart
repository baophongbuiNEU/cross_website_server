import 'package:cross_website/components/cookie_consent_banner.dart';
import 'package:cross_website/components/header.dart';
import 'package:cross_website/constants/app_colors.dart';
import 'package:cross_website/language/language_manager.dart';
import 'package:cross_website/pages/about_new.dart';
import 'package:cross_website/pages/loading_screen.dart';
import 'package:cross_website/pages/not_found_page.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'pages/home.dart';

final translationsProvider = FutureProvider<bool>((ref) async {
  final start = DateTime.now();
  final success = await LanguageManager.loadTranslations();
  print('Translations loaded in ${DateTime.now().difference(start)}');
  return success;
});

@client
class App extends StatefulComponent {
  @override
  State createState() => AppState();
}

class AppState extends State<App> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      final success = await LanguageManager.loadTranslations();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = !success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Iterable<Component> build(BuildContext context) sync* {
    if (_isLoading) {
      yield LoadingScreen();
    } else if (_hasError) {
      yield div(classes: 'main', [text('Error loading translations')]);
    } else {
      yield ProviderScope(
        child: div(classes: 'main', [
          CookieConsentBanner(),
          Router(
            routes: [
              Route(
                path: '/',
                title: 'Home',
                builder: (context, state) => div(classes: 'main', [
                  // Header(),
                  const Home(),
                ]),
              ),
              Route(
                path: '/about',
                title: 'About',
                builder: (context, state) => div(classes: 'main', [
                  // Header(),
                  const AboutNew(),
                ]),
              ),
              Route(
                path: '/:path',
                builder: (context, state) {
                  final currentPath = state.path;
                  if (currentPath != '/' && currentPath != '/about') {
                    return const NotFoundPage();
                  }
                  return div([]);
                },
              ),
            ],
          ),
        ]),
      );
    }
  }

  @css
  static List<StyleRule> get styles => [
        css('.main', [
          css('&').styles(
            display: Display.flex,
            maxWidth: 100.percent,
            flexDirection: FlexDirection.column,
            backgroundColor: AppColors.backgroundTheme,
          ),
          css('section').styles(
            display: Display.flex,
            flexDirection: FlexDirection.column,
            justifyContent: JustifyContent.center,
            alignItems: AlignItems.center,
            flex: Flex(grow: 1),
          ),
        ]),
      ];
}
