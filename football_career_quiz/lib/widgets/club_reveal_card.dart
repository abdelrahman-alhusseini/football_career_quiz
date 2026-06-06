import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/club_model.dart';
import '../services/badge_service.dart';

class ClubRevealCard extends StatelessWidget {
  final ClubModel club;
  final int index;

  const ClubRevealCard({
    super.key,
    required this.club,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 14),
          _ClubBadge(club: club),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              club.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubBadge extends StatelessWidget {
  final ClubModel club;

  const _ClubBadge({
    required this.club,
  });

  @override
  Widget build(BuildContext context) {
    if (club.badgeUrl.trim().isNotEmpty) {
      return _BadgeImage(url: club.badgeUrl);
    }

    return FutureBuilder<String?>(
      future: BadgeService.getBadgeUrl(club.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingBadge();
        }

        final badgeUrl = snapshot.data;

        if (badgeUrl == null || badgeUrl.trim().isEmpty) {
          return const _FallbackBadge();
        }

        return _BadgeImage(url: badgeUrl);
      },
    );
  }
}

class _BadgeImage extends StatelessWidget {
  final String url;

  const _BadgeImage({
    required this.url,
  });

  bool get _isSvg => url.toLowerCase().contains('.svg');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isSvg
          ? SvgPicture.network(
              url,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const _SmallLoader(),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  color: Color(0xFF0B3D2E),
                  size: 32,
                );
              },
            ),
    );
  }
}

class _LoadingBadge extends StatelessWidget {
  const _LoadingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: const _SmallLoader(),
    );
  }
}

class _SmallLoader extends StatelessWidget {
  const _SmallLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF0B3D2E),
        ),
      ),
    );
  }
}

class _FallbackBadge extends StatelessWidget {
  const _FallbackBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: const Icon(
        Icons.sports_soccer,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
