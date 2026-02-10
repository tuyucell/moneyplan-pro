import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:moneyplan_pro/core/services/google_auth_service.dart';

class GmailSyncService {
  static final GoogleSignIn _googleSignIn = GoogleAuthService().instance;

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // First ensure basic sign in
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      // Request Gmail scopes specifically when this service is used
      final scopeGranted = await GoogleAuthService().requestGmailScopes();
      if (!scopeGranted) return null;

      return account;
    } catch (error) {
      debugPrint('Gmail Sign In Error: $error');
      return null;
    }
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      debugPrint('Gmail Silent Sign In Error: $error');
      return null;
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();

  static Future<List<Message>> searchFinancialEmails({
    required DateTime startDate,
    List<String>? customKeywords,
    List<String>? excludeKeywords,
  }) async {
    // Ensure we have scopes before proceeding
    final scopeGranted = await GoogleAuthService().requestGmailScopes();
    if (!scopeGranted) return [];

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return [];

    final gmailApi = GmailApi(authClient);

    // Construct query: After specific date and containing keywords
    const dateQueryFormat = 'yyyy/MM/dd';
    final dateQuery = 'after:${DateFormat(dateQueryFormat).format(startDate)}';

    // Dynamic keywords
    final keywords = customKeywords ??
        [
          'BES',
          'emeklilik',
          'ekstre',
          'dekont',
          'fatura',
          'sigorta',
          'hesap özeti'
        ];
    final keywordQuery = '(${keywords.map((k) => '"$k"').join(' OR ')})';

    // Dynamic exclude query
    final excludes = excludeKeywords ??
        ['teslim edildi', 'kargoya verildi', 'siparişiniz alındı'];
    final excludeQuery = excludes.map((e) => '-"$e"').join(' ');

    final query = '$dateQuery $keywordQuery $excludeQuery';

    try {
      final response = await gmailApi.users.messages.list('me', q: query);
      return response.messages ?? [];
    } catch (e) {
      debugPrint('Gmail Search Error: $e');
      return [];
    }
  }

  static Future<Message?> getMessageDetails(String messageId) async {
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;

    final gmailApi = GmailApi(authClient);
    try {
      return await gmailApi.users.messages.get('me', messageId);
    } catch (e) {
      debugPrint('Gmail Get Message Error: $e');
      return null;
    }
  }

  static String getPlainText(Message message) {
    if (message.payload == null) return '';
    return _extractTextFromPart(message.payload!);
  }

  static String _extractTextFromPart(MessagePart part) {
    // Priority 1: Plain Text
    if (part.mimeType == 'text/plain' && part.body?.data != null) {
      try {
        final data = part.body!.data!.replaceAll('-', '+').replaceAll('_', '/');
        return utf8.decode(base64.decode(data));
      } catch (e) {
        debugPrint('Base64 Decode Error (plain): $e');
      }
    }

    // Priority 2: HTML Text (if no plain text found)
    if (part.mimeType == 'text/html' && part.body?.data != null) {
      try {
        final data = part.body!.data!.replaceAll('-', '+').replaceAll('_', '/');
        return utf8.decode(base64.decode(data));
      } catch (e) {
        debugPrint('Base64 Decode Error (html): $e');
      }
    }

    if (part.parts != null) {
      for (var subPart in part.parts!) {
        var text = _extractTextFromPart(subPart);
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  static Future<MessagePartBody?> getAttachment(
      String messageId, String attachmentId) async {
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;

    final gmailApi = GmailApi(authClient);
    try {
      return await gmailApi.users.messages.attachments
          .get('me', messageId, attachmentId);
    } catch (e) {
      debugPrint('Gmail Get Attachment Error: $e');
      return null;
    }
  }

  static String extractTextFromPdf(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('PDF Text Extraction Error: $e');
      return '';
    }
  }

  static List<MessagePart> getPdfAttachments(Message message) {
    final attachments = <MessagePart>[];
    if (message.payload?.parts == null) return attachments;

    void findAttachments(List<MessagePart> parts) {
      for (var part in parts) {
        if (part.filename != null &&
            part.filename!.isNotEmpty &&
            part.body?.attachmentId != null) {
          if (part.filename!.toLowerCase().endsWith('.pdf') ||
              part.mimeType == 'application/pdf') {
            attachments.add(part);
          }
        }
        if (part.parts != null) {
          findAttachments(part.parts!);
        }
      }
    }

    findAttachments(message.payload!.parts!);
    return attachments;
  }
}
