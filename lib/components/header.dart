import 'dart:async' show StreamSubscription, scheduleMicrotask;

import 'package:cross_website/components/common/menu_button.dart';
import 'package:cross_website/constants/app_colors.dart';
import 'package:cross_website/constants/image_constant.dart';
import 'package:cross_website/constants/theme_toogle.dart';
import 'package:cross_website/language/language_manager.dart';
import 'package:cross_website/utils/events.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:universal_web/web.dart' as web;

class Header extends StatefulComponent {
  const Header({super.key});

  @override
  State<Header> createState() => HeaderState();
}

class HeaderState extends State<Header> {
  static const mobileBreakpoint = 1000;

  final contentKey = GlobalKey();
  bool menuOpen = false;

  StreamSubscription? screenSizeSub;

  @override
  void initState() {
    super.initState();
    resizedWebsite();
  }

  @override
  void dispose() {
    screenSizeSub?.cancel();
    super.dispose();
  }

  void resizedWebsite() {
    if (!kIsWeb) return;
    captureVisit();
    screenSizeSub =
        web.EventStreamProviders.resizeEvent.forTarget(web.window).listen((e) {
      if (menuOpen && web.window.innerWidth > mobileBreakpoint) {
        setState(() {
          menuOpen = false;
        });
      }
    });
  }

  static String getFlagAsset(String langCode) {
    switch (langCode) {
      case 'en':
        return 'images/flags/us.svg';
      case 'vi':
        return 'images/flags/vn.svg';
      case 'ja':
        return 'images/flags/jp.svg';
      case 'ko':
        return 'images/flags/kr.svg';
      default:
        return 'images/flags/default.svg';
    }
  }

  @override
  Iterable<Component> build(BuildContext context) sync* {
    final selectedLang =
        context.watch(LanguageManager.selectedLanguageProvider);

    final currentUrl = context.url;
    final currentHash = Uri.parse(currentUrl).fragment;
    if (currentHash.isNotEmpty && kIsWeb) {
      scheduleMicrotask(() {});
    }
    void closeMenu() {
      if (menuOpen) {
        setState(() {
          menuOpen = false;
        });
      }
    } // Get current path without query parameters or fragments

    void scrollToMeet(String destination) {
      var el = web.document.querySelector(destination) as web.HTMLElement;
      web.window
          .scrollTo(web.ScrollToOptions(top: el.offsetTop, behavior: 'smooth'));
      closeMenu();
    }

    final currentPath = Uri.parse(currentUrl).path;

    var content = Fragment(key: contentKey, children: [
      nav(classes: 'nav-menu', [
        for (var route in [
          if (currentPath != '/') ...[
            (
              label: LanguageManager.translate('header_home', selectedLang),
              path: '/'
            ),
          ],
          (
            label: LanguageManager.translate('header_about', selectedLang),
            path: '/about'
          ),

          // Only show anchor links when on home page
          if (currentPath == '/') ...[
            (
              label: LanguageManager.translate('header_services', selectedLang),
              path: '#services'
            ),
            (
              label: LanguageManager.translate('header_contact', selectedLang),
              path: '#contact'
            ),
            (
              label: LanguageManager.translate('header_careers', selectedLang),
              path: '#careers'
            ),
          ],
        ])
          div(classes: 'nav-item', [
            if (route.path == '/about' || route.path == '/')
              a(
                href: route.path,
                [(text(route.label))],
              )
            else
              div(
                  styles: Styles(
                      cursor: Cursor.pointer,
                      textDecoration: TextDecoration.none),
                  events: {
                    'click': (event) {
                      scrollToMeet(route.path);
                      closeMenu();
                    },
                  },
                  [
                    text(route.label)
                  ]),
          ]),
        Builder(builder: (context) sync* {
          final selectedLang =
              context.watch(LanguageManager.selectedLanguageProvider);

          yield div(classes: "language-header", [
            div(
              classes: "custom-select-display",
              styles: Styles(
                display: Display.flex,
                padding: Spacing.symmetric(horizontal: 8.px),
                cursor: Cursor.pointer,
                alignItems: AlignItems.center,
              ),
              [
                img(
                  src: getFlagAsset(selectedLang),
                  styles: Styles(
                    width: 35.px,
                    height: 25.px,
                  ),
                ),
              ],
            ),
            select(
              styles: Styles(
                position: Position.absolute(),
                zIndex: ZIndex(1),
                width: Unit.pixels(50),
                height: Unit.pixels(30),
                opacity: 0,
                cursor: Cursor.pointer,
              ),
              events: {
                'change': (dynamic event) {
                  final value = event.target.value as String?;
                  if (value != null) {
                    LanguageManager.saveLanguage(value, context);
                  }
                },
              },
              [
                for (var lang in LanguageManager.languages.entries)
                  option(
                    styles: Styles(
                      display: Display.flex,
                      padding:
                          Spacing.symmetric(vertical: 2.px, horizontal: 1.px),
                      alignItems: AlignItems.center,
                      color: AppColors.textBlack,
                    ),
                    attributes: {
                      'value': lang.key,
                      if (lang.key == selectedLang) 'selected': '',
                    },
                    [
                      img(
                        src: getFlagAsset(lang.key),
                        styles: Styles(
                          width: 20.px,
                          height: 15.px,
                          margin: Spacing.only(right: 12.px),
                        ),
                      ),
                      span(
                        styles: Styles(
                          flex: Flex(grow: 1),
                        ),
                        [text(lang.value)],
                      ),
                    ],
                  ),
              ],
            ),
          ]);
        }),
        div(classes: "theme_toggle", [
          ThemeToggle(),
        ]),
      ]),
    ]);

    yield header([
      a(href: '/', [
        img(
          src: Images.crossLogo,
          styles: Styles(
            width: Unit.pixels(120),
            height: Unit.pixels(120),
            padding: Padding.all(.7.rem),
            margin: Margin.only(left: 5.percent),
            radius: BorderRadius.circular(8.px),
            color: AppColors.textBlack,
          ),
        ),
      ]),
      if (!menuOpen) content,
      MenuButton(
        onClick: () {
          setState(() {
            menuOpen = !menuOpen;
          });
        },
        child: menuOpen ? content : null,
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
        css.import(
            "https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&display=swap"),
        css('header', [
          css('&').styles(
            display: Display.flex,
            zIndex: ZIndex(1),
            maxWidth: 100.percent,
            padding: Padding.only(
              top: 1.rem,
              left: 2.rem,
              right: 2.rem,
            ),
            justifyContent: JustifyContent.spaceBetween,
            alignItems: AlignItems.center,
          ),
          css('& > *').styles(
            display: Display.flex,
            alignItems: AlignItems.center,
          ),
          css('.nav-menu a', [
            css('&').styles(
                color: AppColors.textBlack,
                fontFamily: FontFamily.list(
                    [FontFamily("Space Grotesk"), FontFamilies.andaleMono]),
                fontSize: 20.px,
                fontWeight: FontWeight.w400,
                textDecoration: TextDecoration.none),
          ]),
          css('.nav-item', [
            css('&').styles(
                margin: Margin.symmetric(horizontal: 20.px),
                color: AppColors.textBlack,
                fontFamily: FontFamily.list(
                    [FontFamily("Space Grotesk"), FontFamilies.andaleMono]),
                fontSize: 20.px,
                fontWeight: FontWeight.w400,
                textDecoration: TextDecoration.none),
          ]),
          css('.nav-menu', [
            css('&').styles(
              justifyContent: JustifyContent.center,
              alignItems: AlignItems.center,
            ),
          ]),
          css('.nav-menu div', [
            css('&')
                .styles(display: Display.flex, alignItems: AlignItems.center),
          ]),
        ]),
        css('.theme_toggle').styles(
          margin: Spacing.only(left: 5.px),
        ),
        css.media(MediaQuery.screen(maxWidth: mobileBreakpoint.px), [
          css('header', [
            css('&').styles(
              display: Display.flex,
              justifyContent: JustifyContent.spaceBetween,
            ),
            css('& > .nav-menu').styles(display: Display.none),
            css('& > nav').styles(display: Display.none),
          ]),
          css('.theme_toggle').styles(
            margin: Spacing.only(left: 0.px, right: 0.rem),
          ),
        ]),
        css('.language-header', [
          css('&').styles(
            display: Display.flex,
            height: 45.px,
            padding: Padding.symmetric(horizontal: 10.px),
            radius: BorderRadius.circular(14.px),
            alignItems: AlignItems.center,
          ),
          css('&:hover').styles(
            backgroundColor: AppColors.hoverOverlayColor,
          ),
          css('select').styles(
            border: Border.none,
            cursor: Cursor.pointer,
            color: AppColors.textBlack,
            textAlign: TextAlign.center,
            fontFamily: FontFamily.list(
                [FontFamily("Space Grotesk"), FontFamilies.andaleMono]),
            fontSize: 18.px,
            fontWeight: FontWeight.w400,
            backgroundColor: Colors.transparent,
          ),
        ]),
      ];
}
