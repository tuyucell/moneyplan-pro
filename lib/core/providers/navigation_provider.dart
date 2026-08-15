import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();
// Wallet is the primary experience while market-data features are limited.
final bottomNavProvider = StateProvider<int>((ref) => 1);
