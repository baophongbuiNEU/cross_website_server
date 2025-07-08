import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:universal_web/web.dart' as web;

enum SupportLanguage {
  en,
  vi,
  ja,
  ko,
}

class LanguageManager {
  static Map<String, Map<String, String>> translations = {};
  static Future<bool>? _loadFuture;
  static const _languageKey = 'lang';
  static const _cacheKey = 'translations_cache';
  static const _cacheTimestampKey = 'translations_cache_timestamp';
  static const _cacheDuration = Duration(hours: 24);
  static Map<String, dynamic> langAssets = {};
  static bool _hasCookieConsent = getCookieConsent();
  static bool get hasCookieConsent => _hasCookieConsent;

  static final cookieConsentProvider = StateProvider<bool?>((ref) {
    if (!isClient) return null;
    final cookies = web.document.cookie.split(';');
    for (var cookie in cookies) {
      final parts = cookie.trim().split('=');
      if (parts[0] == 'cookie_consent' && parts.length > 1) {
        return parts[1] == 'true' ? true : false;
      }
    }
    return null;
  });

  static const csvUrl =
      'https://docs.google.com/spreadsheets/d/1DJ2ViLI_pEUuDvSK80m5VY-Ksdhx47NsVokixHmKRtY/export?format=csv&gid=0';
  static bool get isClient => kIsWeb && web.window.self == web.window.top;

  static Future<Map<String, dynamic>> loadAsset(String assetsPath) async {
    throw UnimplementedError('Handle later');
  }

  // Add fallback translations for when CSV fails to load
  static Map<String, Map<String, String>> _getFallbackTranslations() {
    return {
      'header_home': {
        'en': 'Home',
        'vi': 'Trang chủ',
        'ko': '홈',
        'ja': 'ホーム',
      },
      'header_about': {
        'en': 'About',
        'vi': 'Giới thiệu',
        'ko': '소개',
        'ja': '紹介',
      },
      'header_services': {
        'en': 'Services',
        'vi': 'Dịch vụ',
        'ko': '서비스',
        'ja': 'サービス',
      },
      'header_contact': {
        'en': 'Contact',
        'vi': 'Liên hệ',
        'ko': '연락처',
        'ja': '連絡先',
      },
      'header_careers': {
        'en': 'Careers',
        'vi': 'Tuyển dụng',
        'ko': '채용',
        'ja': '採用',
      },
      'home_service_title': {
        'en': 'Our Services',
        'vi': 'Dịch vụ của chúng tôi',
        'ko': '우리의 서비스',
        'ja': '私たちのサービス',
      },
      'home_service_content': {
        'en': 'We provide comprehensive digital solutions',
        'vi': 'Chúng tôi cung cấp các giải pháp số toàn diện',
        'ko': '우리는 포괄적인 디지털 솔루션을 제공합니다',
        'ja': '包括的なデジタルソリューションを提供します',
      },
      'home_case_studies_title': {
        'en': 'Case Studies',
        'vi': 'Nghiên cứu trường hợp',
        'ko': '사례 연구',
        'ja': 'ケーススタディ',
      },
      'home_case_studies_content': {
        'en': 'Explore our successful projects',
        'vi': 'Khám phá các dự án thành công của chúng tôi',
        'ko': '성공적인 프로젝트를 탐색하세요',
        'ja': '成功したプロジェクトを探索する',
      },
      'home_process_title': {
        'en': 'Our Process',
        'vi': 'Quy trình của chúng tôi',
        'ko': '우리의 프로세스',
        'ja': '私たちのプロセス',
      },
      'home_process_content': {
        'en': 'How we work with our clients',
        'vi': 'Cách chúng tôi làm việc với khách hàng',
        'ko': '고객과 함께 일하는 방법',
        'ja': 'クライアントとの働き方',
      },
      'home_team_title': {
        'en': 'Our Team',
        'vi': 'Đội ngũ của chúng tôi',
        'ko': '우리 팀',
        'ja': '私たちのチーム',
      },
      'home_team_content': {
        'en': 'Meet our talented professionals',
        'vi': 'Gặp gỡ các chuyên gia tài năng của chúng tôi',
        'ko': '재능있는 전문가들을 만나보세요',
        'ja': '才能ある専門家に会う',
      },
      'home_contact_us_title': {
        'en': 'Contact Us',
        'vi': 'Liên hệ với chúng tôi',
        'ko': '문의하기',
        'ja': 'お問い合わせ',
      },
      'home_contact_us_content': {
        'en': 'Get in touch for your next project',
        'vi': 'Liên hệ cho dự án tiếp theo của bạn',
        'ko': '다음 프로젝트를 위해 연락하세요',
        'ja': '次のプロジェクトのためにお問い合わせください',
      },
    };
  }

  static String _getClientLanguage() {
    if (!isClient) return 'en';
    try {
      final navigator = web.window.navigator;
      if (navigator.language.isEmpty) return 'en';

      final browserLang = navigator.language.toLowerCase();
      if (browserLang.startsWith('vi')) return 'vi';
      if (browserLang.startsWith('ja')) return 'ja';
      if (browserLang.startsWith('ko')) return 'ko';
      return 'en';
    } catch (e) {
      print('Error detecting client language: $e');
      return 'en';
    }
  }

  static void saveLanguage(String langCode, BuildContext context) {
    if (!isClient || !_hasCookieConsent) {
      print('Skipping saveLanguage due to no cookie consent');
      return;
    }
    try {
      final expires = DateTime.now().add(Duration(days: 365)).toUtc();
      final cookie =
          '$_languageKey=$langCode; expires=${expires.toIso8601String()}; path=/';
      web.document.cookie = cookie;
    } catch (e) {
      print('Error saving language to cookie: $e');
    }
  }

  static String? getStoredLanguage() {
    if (!isClient) {
      print('Not client side, returning null');
      return null;
    }

    if (!_hasCookieConsent) {
      print('No cookie consent or not client, skipping cookie read');
      return null;
    }
    try {
      final cookies = web.document.cookie.split(';');
      for (var cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts[0] == _languageKey && parts.length > 1) {
          return parts[1];
        }
      }
    } catch (e) {
      print('Error reading language from cookie: $e');
    }
    return null;
  }

  static void setCookieConsent(bool consent, BuildContext context) {
    print('setCookieConsent called with consent: $consent');
    _hasCookieConsent = consent;
    context.read(cookieConsentProvider.notifier).state = consent;

    if (isClient) {
      try {
        final expires = DateTime.now().add(Duration(days: 365)).toUtc();
        final consentCookie =
            'cookie_consent=$consent; expires=${expires.toIso8601String()}; path=/';
        web.document.cookie = consentCookie;

        if (!consent) {
          print('Clearing language cookie due to Decline');
          web.document.cookie =
              '$_languageKey=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
          context.read(selectedLanguageProvider.notifier).state = 'en';
        } else {
          final langCode = _getClientLanguage();
          saveLanguage(langCode, context);
          context.read(selectedLanguageProvider.notifier).state = langCode;
        }
      } catch (e) {
        print('Error saving cookie consent or language: $e');
      }
    } else {
      final langCode = consent ? _getClientLanguage() : 'en';
      context.read(selectedLanguageProvider.notifier).state = langCode;
    }
  }

  static bool getCookieConsent() {
    if (!isClient) return false;
    try {
      final cookies = web.document.cookie.split(';');
      for (var cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts[0] == 'cookie_consent' && parts.length > 1) {
          return parts[1] == 'true';
        }
      }
    } catch (e) {
      print('Error reading cookie consent: $e');
    }
    return false;
  }

  static final selectedLanguageProvider = StateProvider<String>((ref) {
    // Default to English for server-side rendering
    if (!isClient) {
      print('Server-side rendering, defaulting to English');
      return 'en';
    }

    final hasConsent = ref.watch(cookieConsentProvider);
    if (hasConsent == null) {
      print('No cookie consent decision, defaulting to English');
      return 'en';
    }
    if (!hasConsent) {
      print('Cookie consent declined, defaulting to English');
      return 'en';
    }
    final storedLang = getStoredLanguage();
    if (storedLang != null && languages.containsKey(storedLang)) {
      print('Using stored language: $storedLang');
      return storedLang;
    }
    final clientLang = _getClientLanguage();
    print('Using client language: $clientLang');
    return languages.containsKey(clientLang) ? clientLang : 'en';
  });

  static final languages = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'ko': '한국어',
    'ja': '日本語',
  };

  static Future<bool> loadTranslations({bool forceRefresh = false}) async {
    if (_loadFuture != null && !forceRefresh) {
      return _loadFuture!;
    }

    if (!forceRefresh && isClient) {
      final cachedTranslations = _getCachedTranslations();
      if (cachedTranslations != null && !_isCacheExpired()) {
        translations = cachedTranslations;
        return Future.value(true);
      }
    }

    _loadFuture = _loadTranslationsImpl();
    try {
      final result = await _loadFuture!;
      _loadFuture = null;
      return result;
    } catch (e) {
      _loadFuture = null;
      print('Error in loadTranslations: $e');
      return false;
    }
  }

  static Future<bool> _loadTranslationsImpl() async {
    try {
      final response = await http.get(
        Uri.parse(csvUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/csv,application/csv,text/plain,*/*',
        },
      );

      if (response.statusCode != 200) {
        print('CSV load failed with status: ${response.statusCode}');
        throw Exception('Failed to load CSV: ${response.statusCode}');
      }

      final utf8Body = utf8.decode(response.bodyBytes);
      final rows = const CsvToListConverter().convert(utf8Body);

      if (rows.isEmpty) {
        print('CSV is empty, using fallback translations');
        throw Exception('CSV is empty');
      }

      final headers = rows.first.cast<String>();
      translations.clear();

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final key = row[0].toString();
        for (var j = 1; j < headers.length; j++) {
          final langCode = headers[j].toString().toLowerCase();
          final value = j < row.length ? row[j].toString() : '';
          translations.putIfAbsent(key, () => {})[langCode] = value;
        }
      }

      if (isClient) {
        _saveToCache(translations);
      }
      return true;
    } catch (e) {
      print('Error loading CSV from server: $e');

      // Try cached translations first
      final cachedTranslations = _getCachedTranslations();
      if (cachedTranslations != null) {
        print('Using cached translations as fallback');
        translations = cachedTranslations;
        return true;
      }

      // Use fallback translations if cache fails
      final fallbackTranslations = _getFallbackTranslations();
      print('Using fallback translations');
      translations = fallbackTranslations;
      return true;
    }
  }

  static Map<String, Map<String, String>>? _getCachedTranslations() {
    if (!isClient) {
      print('Not client side, skipping cache read');
      return null;
    }

    if (!_hasCookieConsent) {
      print('No cookie consent, skipping cache read');
      return null;
    }

    try {
      final cachedData = web.window.localStorage[_cacheKey];
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(
              key,
              (value as Map)
                  .map((k, v) => MapEntry(k.toString(), v.toString())),
            ));
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    return null;
  }

  static void _saveToCache(Map<String, Map<String, String>> translations) {
    if (!isClient) return;
    try {
      web.window.localStorage[_cacheKey] = jsonEncode(translations);
      web.window.localStorage[_cacheTimestampKey] =
          DateTime.now().toIso8601String();
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  static bool _isCacheExpired() {
    if (!isClient) return true;
    try {
      final timestampStr = web.window.localStorage[_cacheTimestampKey];
      if (timestampStr == null) return true;
      final timestamp = DateTime.parse(timestampStr);
      return DateTime.now().difference(timestamp) > _cacheDuration;
    } catch (e) {
      print('Error checking cache expiration: $e');
      return true;
    }
  }

  static String translate(String key, [String? langCode]) {
    final language = langCode ?? 'en';

    // Check if translations are loaded
    if (translations.isEmpty) {
      print('Translations not loaded yet, returning key: $key');
      return key; // Return key instead of error message
    }

    final translation = translations[key]?[language];
    if (translation == null || translation.isEmpty) {
      print('Translation not found for key: $key, language: $language');
      return key; // Return key as fallback
    }

    return translation;
  }

  static String tr(String key, String langCode) {
    return translations[key]?[langCode] ?? 'unknown';
  }
}
