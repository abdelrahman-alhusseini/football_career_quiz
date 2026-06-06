# Football Career Quiz

A Flutter mobile trivia game where users guess a football player from the clubs he played for, revealed one by one.

## Current version

This is the first Solo Mode MVP:

- Home screen
- Solo game screen
- Club reveal every 2.5 seconds
- Typing answer input
- Typo-tolerant answer checking
- Scoring rules
- Sample players
- Football pitch themed UI
- Coming soon screens for Friends and Ranked

## Scoring rules

- Guess from first club: 3 points
- If player has more than 8 clubs, guessing from first 2 clubs: 3 points
- Guess before full career is revealed: 2 points
- Guess after full career is revealed: 1 point
- Wrong / skip / no answer: 0 points

## How to run

Because this ZIP contains the clean Flutter source project, do this after unzipping:

```bash
cd football_career_quiz
flutter create .
flutter pub get
flutter run
```

Choose Android emulator or a real Android/iPhone device. This project is designed as a mobile app first, not a web app.

## Next recommended upgrades

1. Add real club badge images to `assets/badges/`.
2. Replace sample players with a bigger database.
3. Add difficulty levels.
4. Add local high score saving.
5. Add Firebase later for friends mode and ranked mode.
