import json
from pathlib import Path

PLAYERS_FILE = Path("assets/data/players.json")


def normalize_old_difficulty(value: str) -> str:
    value = str(value).strip().lower()

    old_to_new = {
        "easy": "amateur",
        "medium": "pro",
        "hard": "elite",
        "expert": "exceptional",
        "amateur": "amateur",
        "pro": "pro",
        "elite": "elite",
        "exceptional": "exceptional",
    }

    return old_to_new.get(value, "")


def difficulty_by_rank(index: int) -> str:
    """
    Use this when the old difficulty is missing or unknown.
    The generated database is roughly ordered by importance/fame.
    """
    rank = index + 1

    if rank <= 400:
        return "amateur"

    if rank <= 1200:
        return "pro"

    if rank <= 2200:
        return "elite"

    return "exceptional"


def main():
    if not PLAYERS_FILE.exists():
        raise FileNotFoundError(f"Could not find {PLAYERS_FILE}")

    players = json.loads(PLAYERS_FILE.read_text(encoding="utf-8"))

    if not isinstance(players, list):
        raise ValueError("players.json must contain a list of players")

    counts = {
        "amateur": 0,
        "pro": 0,
        "elite": 0,
        "exceptional": 0,
    }

    for index, player in enumerate(players):
        old_difficulty = player.get("difficulty", "")
        new_difficulty = normalize_old_difficulty(old_difficulty)

        if not new_difficulty:
            new_difficulty = difficulty_by_rank(index)

        player["difficulty"] = new_difficulty

        tags = player.get("tags", [])
        if not isinstance(tags, list):
            tags = []

        tags = [
            str(tag).strip().lower()
            for tag in tags
            if str(tag).strip().lower()
            not in [
                "easy",
                "medium",
                "hard",
                "expert",
                "amateur",
                "pro",
                "elite",
                "exceptional",
            ]
        ]

        tags.append(new_difficulty)
        player["tags"] = tags

        counts[new_difficulty] += 1

    PLAYERS_FILE.write_text(
        json.dumps(players, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print("Done. Updated difficulty categories:")
    for difficulty, count in counts.items():
        print(f"{difficulty}: {count}")


if __name__ == "__main__":
    main()