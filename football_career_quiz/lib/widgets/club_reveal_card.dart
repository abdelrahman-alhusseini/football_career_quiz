import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/club_model.dart';
import '../services/badge_service.dart';
import '../utils/app_theme.dart';

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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 150,
        ),
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF031521).withOpacity(0.58),
          border: Border.all(
            color: AppTheme.neonGreen.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.neonGreen.withOpacity(0.05),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -4,
              left: -2,
              child: _IndexBadge(number: index + 1),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                _PremiumBadgeImage(clubName: club.name),
                const SizedBox(height: 12),
                Text(
                  club.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.05,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBadgeImage extends StatelessWidget {
  final String clubName;

  const _PremiumBadgeImage({
    required this.clubName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: BadgeService.getBadgeUrl(clubName),
      builder: (context, snapshot) {
        final badgeUrl = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.neonGreen.withOpacity(0.9),
                ),
              ),
            ),
          );
        }

        if (badgeUrl == null || badgeUrl.trim().isEmpty) {
          return _FallbackBadge();
        }

        return Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonGreen.withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _BadgeImage(url: badgeUrl),
        );
      },
    );
  }
}

class _BadgeImage extends StatelessWidget {
  final String url;

  const _BadgeImage({
    required this.url,
  });

  bool get _isSvg => url.toLowerCase().trim().endsWith('.svg');
  bool get _isNetwork => url.toLowerCase().startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork && _isSvg) {
      return SvgPicture.network(
        url,
        width: 66,
        height: 66,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _SmallLoader(),
      );
    }

    if (_isNetwork) {
      return Image.network(
        url,
        width: 66,
        height: 66,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackBadge(),
      );
    }

    if (_isSvg) {
      return SvgPicture.asset(
        url,
        width: 66,
        height: 66,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _SmallLoader(),
      );
    }

    return Image.asset(
      url,
      width: 66,
      height: 66,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackBadge(),
    );
  }
}

class _SmallLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.neonGreen.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}

class _FallbackBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.neonGreen.withOpacity(0.08),
        border: Border.all(
          color: AppTheme.neonGreen.withOpacity(0.18),
        ),
      ),
      child: Icon(
        Icons.shield_rounded,
        color: AppTheme.neonGreen.withOpacity(0.85),
        size: 36,
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int number;

  const _IndexBadge({
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.gold.withOpacity(0.16),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.16),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        number.toString(),
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
