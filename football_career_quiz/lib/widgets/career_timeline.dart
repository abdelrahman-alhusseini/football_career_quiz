import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/club_model.dart';
import '../services/badge_service.dart';
import '../utils/app_theme.dart';

class CareerTimeline extends StatelessWidget {
  final List<ClubModel> clubs;

  const CareerTimeline({
    super.key,
    required this.clubs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clubs.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, __) => const _ArrowConnector(),
        itemBuilder: (context, index) {
          final club = clubs[index];
          return _ClubNode(club: club, number: index + 1);
        },
      ),
    );
  }
}

class _ClubNode extends StatelessWidget {
  final ClubModel club;
  final int number;

  const _ClubNode({
    required this.club,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppTheme.card.withOpacity(0.78),
            AppTheme.card2.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.stadiumBlue.withOpacity(0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              _BadgeBox(club: club),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    club.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 16,
                child: Text(
                  club.country,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.subText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeBox extends StatelessWidget {
  final ClubModel club;

  const _BadgeBox({
    required this.club,
  });

  @override
  Widget build(BuildContext context) {
    if (club.badgeUrl.trim().isNotEmpty) {
      return _NetworkBadge(url: club.badgeUrl);
    }

    return FutureBuilder<String?>(
      future: BadgeService.getBadgeUrl(club.name),
      builder: (context, snapshot) {
        final url = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FallbackBadge(loading: true);
        }

        if (url == null || url.isEmpty) {
          return const _FallbackBadge();
        }

        return _NetworkBadge(url: url);
      },
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  final String url;

  const _NetworkBadge({
    required this.url,
  });

  bool get isSvg => url.toLowerCase().contains('.svg');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: isSvg
          ? SvgPicture.network(
              url,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,

              // Important for Flutter Web/Chrome preview.
              // This helps some external image hosts render properly.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,

              errorBuilder: (_, __, ___) => const Icon(
                Icons.shield_outlined,
                color: AppTheme.card,
                size: 30,
              ),
            ),
    );
  }
}

class _FallbackBadge extends StatelessWidget {
  final bool loading;

  const _FallbackBadge({
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.stadiumBlue.withOpacity(0.25),
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              )
            : const Icon(
                Icons.sports_soccer,
                color: AppTheme.subText,
                size: 28,
              ),
      ),
    );
  }
}

class _ArrowConnector extends StatelessWidget {
  const _ArrowConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Center(
        child: Icon(
          Icons.arrow_forward_rounded,
          color: AppTheme.gold.withOpacity(0.9),
          size: 22,
        ),
      ),
    );
  }
}
