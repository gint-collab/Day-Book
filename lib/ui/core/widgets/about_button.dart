import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// Info button that opens the About page (phones, where there's no sidebar).
class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'About Dayloom',
      onPressed: () => context.push(Routes.about),
      icon: const Icon(Icons.info_outline, size: 20),
    );
  }
}
