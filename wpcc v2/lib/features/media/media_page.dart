import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';

class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Media')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(19, 4, 19, 30),
          children: [
            const Text(
              'Messages & podcasts',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Listen to recent WPCC podcast episodes and messages.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: WpccColors.inkSoft,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: WpccColors.line),
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: WpccColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      PhosphorIcons.microphoneStage(),
                      size: 26,
                      color: WpccColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Spotify podcast not connected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Episodes will appear here automatically after the WPCC Spotify show is connected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: WpccColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
