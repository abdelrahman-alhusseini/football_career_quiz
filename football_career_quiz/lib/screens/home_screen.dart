import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_career_quiz/screens/difficulty_screen.dart';
import 'package:football_career_quiz/screens/friend_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/';

  // Keep this as your actual home wallpaper path.
  // If your image has a different name, change only this line.
  static const String _backgroundAsset =
      'assets/images/home_screen_background.png';

  // Turn this to true if you want to see the invisible button areas.
  static const bool _showTapAreas = false;

  // Your selected home image is 864 x 1536.
  static const double _imageWidth = 864;
  static const double _imageHeight = 1536;

  // Button positions measured from the image itself.
  // These match the new selected wallpaper.
  static const Rect _soloButtonRect = Rect.fromLTWH(96, 1012, 672, 152);
  static const Rect _friendsButtonRect = Rect.fromLTWH(96, 1182, 672, 152);
  static const Rect _rankedButtonRect = Rect.fromLTWH(96, 1348, 672, 152);

  const HomeScreen({super.key});

  Rect _imageRectToScreenRect(Size screenSize, Rect imageRect) {
    final scale = math.max(
      screenSize.width / _imageWidth,
      screenSize.height / _imageHeight,
    );

    final displayedImageWidth = _imageWidth * scale;
    final displayedImageHeight = _imageHeight * scale;

    final offsetX = (screenSize.width - displayedImageWidth) / 2;
    final offsetY = (screenSize.height - displayedImageHeight) / 2;

    return Rect.fromLTWH(
      offsetX + imageRect.left * scale,
      offsetY + imageRect.top * scale,
      imageRect.width * scale,
      imageRect.height * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          final soloRect = _imageRectToScreenRect(screenSize, _soloButtonRect);
          final friendsRect =
              _imageRectToScreenRect(screenSize, _friendsButtonRect);
          final rankedRect =
              _imageRectToScreenRect(screenSize, _rankedButtonRect);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              _InvisibleMenuButton(
                rect: soloRect,
                debugColor: Colors.green,
                onTap: () {
                  Navigator.of(context).pushNamed(DifficultyScreen.routeName);
                },
              ),
              _InvisibleMenuButton(
                rect: friendsRect,
                debugColor: Colors.blue,
                onTap: () {
                  Navigator.of(context).pushNamed(FriendModeScreen.routeName);
                },
              ),
              _InvisibleMenuButton(
                rect: rankedRect,
                debugColor: Colors.amber,
                onTap: () {
                  Navigator.of(context).pushNamed('/coming-soon');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvisibleMenuButton extends StatelessWidget {
  final Rect rect;
  final Color debugColor;
  final VoidCallback onTap;

  const _InvisibleMenuButton({
    required this.rect,
    required this.debugColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Container(
          decoration: HomeScreen._showTapAreas
              ? BoxDecoration(
                  color: debugColor.withOpacity(0.25),
                  border: Border.all(
                    color: debugColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(26),
                )
              : null,
        ),
      ),
    );
  }
}
