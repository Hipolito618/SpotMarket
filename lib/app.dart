import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'shared/theme/app_theme.dart';

import 'shared/widgets/marco_conexion.dart';

class SpotMarketApp extends StatelessWidget {
  const SpotMarketApp({super.key, this.temaInicial});

  final AdaptiveThemeMode? temaInicial;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: AppTheme.claro(),
      dark: AppTheme.oscuro(),
      initial: temaInicial ?? AdaptiveThemeMode.system,
      builder: (claro, oscuro) => MaterialApp.router(
        title: 'SpotMarket',
        debugShowCheckedModeBanner: false,
        theme: claro,
        darkTheme: oscuro,
        routerConfig: appRouter,
        builder: (context, child) =>
            MarcoConexion(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}