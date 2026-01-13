import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:invest_guide/core/config/api_config.dart';

/// Professional web scraping service with anti-bot bypass capabilities
/// Used when no official API is available (EGM, TSB, etc.)
class WebScraperService {
  static final Random _random = Random();
  static DateTime? _lastRequestTime;
  static int _requestCount = 0;

  /// Realistic User-Agent pool (rotates automatically)
  static final List<String> _userAgents = [
    // Chrome on Windows
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    // Chrome on Mac
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    // Firefox on Windows
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0',
    // Safari on Mac
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
    // Edge on Windows
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
  ];

  /// Get random User-Agent from pool
  static String _getRandomUserAgent() {
    return _userAgents[_random.nextInt(_userAgents.length)];
  }

  /// Generate realistic browser headers to bypass anti-bot systems
  static Map<String, String> _getRealisticHeaders({String? referer}) {
    return {
      'User-Agent': _getRandomUserAgent(),
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': referer != null ? 'same-origin' : 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
      'DNT': '1',
      if (referer != null) 'Referer': referer,
    };
  }

  /// Smart rate limiting - adds random delay between requests
  static Future<void> _respectfulDelay() async {
    // Minimum 1-3 seconds between requests (respectful scraping)
    final minDelay = 1000 + _random.nextInt(2000); // 1-3 seconds

    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!).inMilliseconds;
      if (timeSinceLastRequest < minDelay) {
        final delayNeeded = minDelay - timeSinceLastRequest;
        if (kDebugMode) {
          print('WebScraperService: Waiting ${delayNeeded}ms (respectful scraping)');
        }
        await Future.delayed(Duration(milliseconds: delayNeeded));
      }
    }

    _lastRequestTime = DateTime.now();
    _requestCount++;
  }

  /// Fetch HTML content with anti-bot bypass and retry logic
  static Future<String> fetchHtml(
    String url, {
    String? referer,
    int maxRetries = 3,
    bool respectRateLimit = true,
  }) async {
    if (respectRateLimit) {
      await _respectfulDelay();
    }

    Exception? lastException;

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('WebScraperService: Fetching HTML from $url (attempt ${attempt + 1}/$maxRetries)');
        }

        final response = await http.get(
          Uri.parse(url),
          headers: _getRealisticHeaders(referer: referer),
        ).timeout(ApiConfig.requestTimeout);

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('WebScraperService: Successfully fetched HTML (${response.body.length} bytes)');
            print('WebScraperService: Total requests made: $_requestCount');
          }
          return response.body;
        } else if (response.statusCode == 429) {
          // Rate limited - wait longer
          final backoffTime = Duration(seconds: pow(2, attempt).toInt() * 5);
          if (kDebugMode) {
            print('WebScraperService: Rate limited (429). Backing off for ${backoffTime.inSeconds}s');
          }
          await Future.delayed(backoffTime);
          continue;
        } else if (response.statusCode >= 500) {
          // Server error - retry with backoff
          final backoffTime = Duration(seconds: pow(2, attempt).toInt());
          if (kDebugMode) {
            print('WebScraperService: Server error (${response.statusCode}). Retrying in ${backoffTime.inSeconds}s');
          }
          await Future.delayed(backoffTime);
          continue;
        } else {
          throw Exception('Failed to fetch HTML: Status ${response.statusCode}');
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (kDebugMode) {
          print('WebScraperService: Error on attempt ${attempt + 1}: $e');
        }

        if (attempt < maxRetries - 1) {
          // Exponential backoff
          final backoffTime = Duration(seconds: pow(2, attempt).toInt());
          if (kDebugMode) {
            print('WebScraperService: Retrying in ${backoffTime.inSeconds}s');
          }
          await Future.delayed(backoffTime);
        }
      }
    }

    throw lastException ?? Exception('Failed to fetch HTML after $maxRetries attempts');
  }

  /// Parse HTML string into a DOM document
  static dom.Document parseHtml(String htmlContent) {
    return html_parser.parse(htmlContent);
  }

  /// Fetch and parse HTML in one step with anti-bot bypass
  static Future<dom.Document> fetchAndParse(
    String url, {
    String? referer,
    int maxRetries = 3,
    bool respectRateLimit = true,
  }) async {
    final htmlContent = await fetchHtml(
      url,
      referer: referer,
      maxRetries: maxRetries,
      respectRateLimit: respectRateLimit,
    );
    return parseHtml(htmlContent);
  }

  /// Reset rate limiter (useful for testing or new sessions)
  static void resetRateLimiter() {
    _lastRequestTime = null;
    _requestCount = 0;
    if (kDebugMode) {
      print('WebScraperService: Rate limiter reset');
    }
  }

  /// Get scraping statistics
  static Map<String, dynamic> getStats() {
    return {
      'total_requests': _requestCount,
      'last_request_time': _lastRequestTime?.toIso8601String(),
      'user_agents_pool_size': _userAgents.length,
    };
  }

  /// Extract table data from HTML
  /// Returns list of rows, where each row is a list of cell values
  static List<List<String>> extractTableData(
    dom.Document document, {
    String? tableSelector,
    int? tableIndex,
  }) {
    try {
      final tables = document.querySelectorAll('table');

      if (tables.isEmpty) {
        if (kDebugMode) {
          print('WebScraperService: No tables found');
        }
        return [];
      }

      dom.Element? targetTable;
      if (tableSelector != null) {
        targetTable = document.querySelector(tableSelector);
      } else if (tableIndex != null && tableIndex < tables.length) {
        targetTable = tables[tableIndex];
      } else {
        targetTable = tables.first;
      }

      if (targetTable == null) {
        return [];
      }

      final rows = targetTable.querySelectorAll('tr');
      final tableData = <List<String>>[];

      for (final row in rows) {
        final cells = row.querySelectorAll('td, th');
        final rowData = cells.map((cell) => cell.text.trim()).toList();
        if (rowData.isNotEmpty) {
          tableData.add(rowData);
        }
      }

      if (kDebugMode) {
        print('WebScraperService: Extracted ${tableData.length} rows from table');
      }

      return tableData;
    } catch (e) {
      if (kDebugMode) {
        print('WebScraperService: Error extracting table data: $e');
      }
      return [];
    }
  }

  /// Extract list items from HTML
  static List<String> extractListItems(
    dom.Document document, {
    String selector = 'li',
  }) {
    try {
      final items = document.querySelectorAll(selector);
      final listData = items.map((item) => item.text.trim()).toList();

      if (kDebugMode) {
        print('WebScraperService: Extracted ${listData.length} list items');
      }

      return listData;
    } catch (e) {
      if (kDebugMode) {
        print('WebScraperService: Error extracting list items: $e');
      }
      return [];
    }
  }

  /// Extract specific elements by CSS selector
  static List<String> extractElementsBySelector(
    dom.Document document,
    String selector,
  ) {
    try {
      final elements = document.querySelectorAll(selector);
      final data = elements.map((e) => e.text.trim()).toList();

      if (kDebugMode) {
        print('WebScraperService: Extracted ${data.length} elements with selector "$selector"');
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('WebScraperService: Error extracting elements: $e');
      }
      return [];
    }
  }

  /// Extract attribute values from elements
  static List<String> extractAttributes(
    dom.Document document,
    String selector,
    String attributeName,
  ) {
    try {
      final elements = document.querySelectorAll(selector);
      final attributes = elements
          .map((e) => e.attributes[attributeName])
          .where((attr) => attr != null)
          .map((attr) => attr!)
          .toList();

      if (kDebugMode) {
        print('WebScraperService: Extracted ${attributes.length} "$attributeName" attributes');
      }

      return attributes;
    } catch (e) {
      if (kDebugMode) {
        print('WebScraperService: Error extracting attributes: $e');
      }
      return [];
    }
  }

  /// Parse numeric value from string (handles Turkish number format)
  static double? parseNumeric(String value) {
    try {
      // Remove thousand separators and convert decimal comma to dot
      final cleaned = value
          .replaceAll('.', '')  // Remove thousand separator (Turkish: 1.234,56)
          .replaceAll(',', '.') // Convert decimal separator to dot
          .replaceAll('%', '')  // Remove percentage sign
          .replaceAll('₺', '')  // Remove currency symbol
          .replaceAll(' ', '')  // Remove spaces
          .trim();

      if (cleaned.isEmpty) return null;

      return double.tryParse(cleaned);
    } catch (e) {
      if (kDebugMode) {
        print('WebScraperService: Error parsing numeric value "$value": $e');
      }
      return null;
    }
  }

  /// Clean and normalize text
  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')  // Replace multiple spaces with single space
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')  // Replace newlines and tabs with space
        .trim();
  }
}
