import 'package:jaspr/jaspr.dart';
import 'package:cross_website/constants/app_colors.dart';
import 'package:universal_web/web.dart' as web;

class ThemeToggle extends StatefulComponent {
  const ThemeToggle({super.key});

  @override
  State createState() => ThemeToggleState();
}

class ThemeToggleState extends State<ThemeToggle> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _loadThemeFromCookies();
  }

  void _loadThemeFromCookies() {
    if (!kIsWeb) return;

    try {
      // Get theme from cookies
      final cookies = web.document.cookie.split(';');
      String? activeTheme;

      for (final cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts.length == 2 && parts[0] == 'active-theme') {
          activeTheme = parts[1];
          break;
        }
      }

      // Set theme based on cookie or default to light
      if (activeTheme != null) {
        isDark = activeTheme == 'dark';
      } else {
        // Check system preference if no cookie exists
        final prefersDark =
            web.window.matchMedia('(prefers-color-scheme: dark)').matches;
        isDark = prefersDark;
      }

      // Apply theme to document
      web.document.documentElement!.className = isDark ? 'dark' : 'light';

      // Save to cookie if not exists
      if (activeTheme == null) {
        _saveToCookie(isDark ? 'dark' : 'light');
      }
    } catch (e) {
      // Fallback to light theme if any error
      isDark = false;
      web.document.documentElement!.className = 'light';
    }
  }

  void _saveToCookie(String theme) {
    if (!kIsWeb) return;

    final expires = DateTime.now().add(const Duration(days: 365));
    web.document.cookie =
        'active-theme=$theme; expires=${expires.toUtc().toString()}; path=/';
  }

  void _toggleTheme() {
    setState(() {
      isDark = !isDark;
    });

    final newTheme = isDark ? 'dark' : 'light';
    web.document.documentElement!.className = newTheme;
    _saveToCookie(newTheme);
  }

  @override
  Iterable<Component> build(BuildContext context) sync* {
    // Add script to head for immediate theme loading (prevents flash)
    yield Document.head(children: [
      DomComponent(id: 'theme-script', tag: 'script', children: [
        raw('''
(function() {
  // Function to get cookie by name
  function getCookie(name) {
    const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
    return match ? match[2] : null;
  }
  
  // Function to set cookie
  function setCookie(name, value, days) {
    const expires = new Date();
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
    document.cookie = name + "=" + value + "; expires=" + expires.toUTCString() + "; path=/";
  }
  
  // Load theme immediately on page load
  const activeTheme = getCookie('active-theme');
  
  if (activeTheme) {
    // Use saved theme
    document.documentElement.className = activeTheme;
  } else {
    // Use system preference or default to light
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const defaultTheme = prefersDark ? 'dark' : 'light';
    document.documentElement.className = defaultTheme;
    setCookie('active-theme', defaultTheme, 365);
  }
})();
        ''')
      ]),
    ]);

    // Set HTML class attribute
    if (kIsWeb) {
      yield Document.html(attributes: {'class': isDark ? 'dark' : 'light'});
    }

    // Theme toggle button
    yield button(
      classes: 'theme-toggle',
      attributes: {'aria-label': 'Toggle Theme'},
      onClick: _toggleTheme,
      styles: !kIsWeb
          ? Styles(visibility: Visibility.hidden)
          : Styles(fontSize: 30.px),
      [
        img(
          src: isDark ? 'images/moon.svg' : 'images/sun.svg',
          alt: isDark ? 'Dark mode' : 'Light mode',
        )
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
        css('.theme-toggle', [
          css('&').styles(
            display: Display.flex,
            padding: Padding.all(.7.rem),
            border: Border.unset,
            radius: BorderRadius.circular(8.px),
            outline: Outline.unset,
            alignItems: AlignItems.center,
            color: AppColors.textBlack,
            backgroundColor: Colors.transparent,
            cursor: Cursor.pointer,
          ),
          css('&:hover').styles(
            backgroundColor: AppColors.hoverOverlayColor,
          ),
        ]),
      ];
}
