import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final icon = isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
        final tooltip = isDark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro';

        if (showLabel) {
          return ElevatedButton.icon(
            onPressed: ThemeController.instance.toggleTheme,
            icon: Icon(icon)
                .animate(key: ValueKey(isDark))
                .rotate(duration: 400.ms, curve: Curves.easeOutBack)
                .scale(duration: 300.ms),
            label: Text(isDark ? 'Modo Claro' : 'Modo Oscuro'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 44),
            ),
          );
        }

        return IconButton(
          tooltip: tooltip,
          onPressed: ThemeController.instance.toggleTheme,
          icon: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          )
              .animate(key: ValueKey(isDark))
              .rotate(duration: 400.ms, curve: Curves.easeOutBack)
              .scale(duration: 300.ms),
        );
      },
    );
  }
}
