import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/wpcc_shimmer.dart';

const _kPrimaryText = Color(0xFF111827);
const _kSecondaryText = Color(0xFF4B5563);
const _kCard = Color(0xFFFCFBF9);
const _kBorder = Color(0x1A111827);
const _kCream = Color(0xFFF1EADD);

/// Skeleton cards matching the real result card dimensions.
class SearchLoadingSkeleton extends StatelessWidget {
  const SearchLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          const WpccShimmerCard(
            height: 124,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WpccShimmerBlock(width: 50, height: 50, radius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WpccShimmerBlock(width: 90, height: 10, radius: 6),
                      SizedBox(height: 10),
                      WpccShimmerBlock(width: 180, height: 14, radius: 8),
                      SizedBox(height: 8),
                      WpccShimmerBlock(width: 220, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < 3; i++) ...[
            const SizedBox(height: 10),
            const WpccShimmerCard(
              height: 82,
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  WpccShimmerCircle(size: 50),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WpccShimmerBlock(width: 80, height: 10, radius: 6),
                        SizedBox(height: 8),
                        WpccShimmerBlock(width: 160, height: 13, radius: 7),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _kCream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF111113)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              height: 1.45,
              color: _kSecondaryText,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Shown before the user has typed a query.
class SearchIdleState extends StatelessWidget {
  const SearchIdleState({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.search_rounded,
      title: 'Search the app',
      body:
          'Find people, events, notices and departments across the app. '
          'Type at least two characters to begin.',
    );
  }
}

/// Shown when the query returned no rows.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.search_off_rounded,
      title: 'No results for “${query.trim()}”',
      body: 'Check the spelling or try a different keyword. '
          'You can also switch to another section filter.',
    );
  }
}

/// Shown when the search request failed.
class SearchErrorCard extends StatelessWidget {
  const SearchErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.wifi_off_rounded,
      title: 'Something went wrong',
      body: 'We could not complete the search. Check your connection and try again.',
      action: GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111113),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
