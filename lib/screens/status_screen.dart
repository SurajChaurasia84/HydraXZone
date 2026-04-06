import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screen_constants.dart';
import 'system_ui.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(background),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  const SizedBox(
                    height: 34,
                    width: 34,
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                  const SizedBox(height: 22),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
