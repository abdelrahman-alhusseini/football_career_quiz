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
    if (clubs.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final clubsPerRow = width >= 520 ? 3 : 2;

        final rows = <List<ClubModel>>[];
        for (int i = 0; i < clubs.length; i += clubsPerRow) {
          rows.add(
            clubs.sublist(
              i,
              (i + clubsPerRow > clubs.length) ? clubs.length : i + clubsPerRow,
            ),
          );
        }

        return Column(
          children: List.generate(rows.length, (rowIndex) {
            final rowClubs = rows[rowIndex];
            final isLastRow = rowIndex == rows.length - 1;
            final startNumber = rowIndex * clubsPerRow + 1;

            return Column(
              children: [
                _TimelineRow(
                  clubs: rowClubs,
                  startNumber: startNumber,
                  clubsPerRow: clubsPerRow,
                  availableWidth: width,
                ),
                if (!isLastRow) const _RowDownConnector(),
              ],
            );
          }),
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final List<ClubModel> clubs;
  final int startNumber;
  final int clubsPerRow;
  final double availableWidth;

  const _TimelineRow({
    required this.clubs,
    required this.startNumber,
    required this.clubsPerRow,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    const arrowWidth = 28.0;
    const gap = 6.0;

    final totalArrowWidth = arrowWidth * (clubsPerRow - 1);
    final totalGapWidth = gap * 2 * (clubsPerRow - 1);
    final cardWidth =
        (availableWidth - totalArrowWidth - totalGapWidth) / clubsPerRow;

    final children = <Widget>[];

    for (int i = 0; i < clubs.length; i++) {
      children.add(
        SizedBox(
          width: cardWidth,
          child: _ClubNode(
            club: clubs[i],
            number: startNumber + i,
          ),
        ),
      );

      if (i != clubs.length - 1) {
        children.add(const SizedBox(width: gap));
        children.add(const _SideArrow(width: arrowWidth));
        children.add(const SizedBox(width: gap));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _SideArrow extends StatelessWidget {
  final double width;

  const _SideArrow({
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Icon(
        Icons.arrow_forward_rounded,
        color: AppTheme.gold.withOpacity(0.95),
        size: 24,
      ),
    );
  }
}

class _RowDownConnector extends StatelessWidget {
  const _RowDownConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Container(
          width: 34,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: AppTheme.gold.withOpacity(0.08),
            border: Border.all(
              color: AppTheme.gold.withOpacity(0.20),
            ),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.gold.withOpacity(0.95),
            size: 22,
          ),
        ),
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
      height: 170,
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
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
          BoxShadow(
            color: AppTheme.pitchGreen.withOpacity(0.04),
            blurRadius: 18,
            spreadRadius: 1,
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
              const SizedBox(height: 4),
              _BadgeBox(club: club),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: Center(
                  child: Text(
                    club.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: Text(
                  club.country,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.subText,
                    fontSize: 10,
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
      return _BadgeImage(url: club.badgeUrl);
    }

    return FutureBuilder<String?>(
      future: BadgeService.getBadgeUrl(club.name),
      builder: (context, snapshot) {
        final url = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FallbackBadge(loading: true);
        }

        if (url == null || url.trim().isEmpty) {
          return const _FallbackBadge();
        }

        return _BadgeImage(url: url);
      },
    );
  }
}

class _BadgeImage extends StatelessWidget {
  final String url;

  const _BadgeImage({
    required this.url,
  });

  bool get isSvg => url.toLowerCase().contains('.svg');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.pitchGreen.withOpacity(0.14),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isSvg
              ? SvgPicture.network(
                  url,
                  width: 61,
                  height: 61,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => const _FallbackBadge(
                    loading: true,
                  ),
                )
              : Image.network(
                  url,
                  width: 61,
                  height: 61,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, __, ___) => const _FallbackBadge(),
                ),
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
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.pitchGreen.withOpacity(0.08),
        border: Border.all(
          color: AppTheme.pitchGreen.withOpacity(0.20),
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
                size: 26,
              ),
      ),
    );
  }
}
