import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Gestiona el estado: true = Oscuro, false = Claro
final isDarkModeProvider = StateProvider<bool>((ref) => false);