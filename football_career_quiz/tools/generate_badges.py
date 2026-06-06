import re
import requests
from bs4 import BeautifulSoup
from pathlib import Path

COMPETITIONS = {
    "Ligue 1": "https://www.footylogos.com/competition/ligue-1",
    "Eredivisie": "https://www.footylogos.com/competition/eredivisie",
    "Liga Portugal": "https://www.footylogos.com/competition/liga-portugal",
    "MLS": "https://www.footylogos.com/competition/mls",
    "Saudi Pro League": "https://www.footylogos.com/competition/saudi-pro-league",
    "Brasileirao Serie A": "https://www.footylogos.com/competition/brasileirao-serie-a",
    "Argentina Liga Profesional": "https://www.footylogos.com/competition/liga-profesional-argentina",
    "Belgian Pro League": "https://www.footylogos.com/competition/belgian-pro-league",
    "Liga MX": "https://www.footylogos.com/competition/liga-mx",
    "Süper Lig": "https://www.footylogos.com/competition/super-lig",
    "Scottish Premiership": "https://www.footylogos.com/competition/scottish-premiership",
    "Swiss Football League": "https://www.footylogos.com/competition/swiss-football-league",
    "Austrian Bundesliga": "https://www.footylogos.com/competition/austrian-bundesliga",
    "J1 League": "https://www.footylogos.com/competition/j1-league",
    "K League 1": "https://www.footylogos.com/competition/k-league-1",
    "Chinese Super League": "https://www.footylogos.com/competition/chinese-super-league",
    "Egyptian Premier League": "https://www.footylogos.com/competition/egyptian-premier-league",
    "Botola Pro 1": "https://www.footylogos.com/competition/botola-pro-1",
    "South Africa PSL": "https://www.footylogos.com/competition/premier-soccer-league-south-africa",
}

OUTPUT_FILE = Path("lib/data/generated_badge_overrides.dart")


def clean_team_name(raw: str) -> str:
    name = raw.strip()
    name = re.sub(r"\s+", " ", name)
    name = re.sub(r"\s+logo$", "", name, flags=re.I)
    name = re.sub(r"\s+footballlogos.*$", "", name, flags=re.I)
    name = re.sub(r"\s+footylogos.*$", "", name, flags=re.I)
    return name.strip()


def is_logo_url(url: str) -> bool:
    lowered = url.lower()
    return (
        ("footballlogos" in lowered or "footylogos" in lowered)
        and (lowered.endswith(".png") or lowered.endswith(".svg") or ".png" in lowered or ".svg" in lowered)
    )


def extract_logos(competition_name: str, url: str):
    print(f"Fetching {competition_name}...")
    html = requests.get(url, timeout=20).text
    soup = BeautifulSoup(html, "html.parser")

    logos = {}

    for img in soup.find_all("img"):
        src = img.get("src") or img.get("data-src") or ""
        alt = img.get("alt") or ""

        if not src:
            continue

        if src.startswith("//"):
            src = "https:" + src
        elif src.startswith("/"):
            src = "https://www.footylogos.com" + src

        if not is_logo_url(src):
            continue

        team_name = clean_team_name(alt)

        if not team_name:
            # fallback from filename
            filename = src.split("/")[-1]
            filename = re.sub(r"\.(png|svg).*", "", filename, flags=re.I)
            filename = re.sub(r"^[a-f0-9]{8,}_", "", filename)
            filename = filename.replace("-footballlogos-org", "")
            filename = filename.replace("-footylogos", "")
            filename = filename.replace("-", " ")
            team_name = filename.title()

        if team_name and team_name.lower() not in ["image", "logo"]:
            logos[team_name] = src

    return logos


def dart_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def main():
    all_logos = {}

    for competition, url in COMPETITIONS.items():
        try:
            logos = extract_logos(competition, url)
            print(f"  found {len(logos)} logos")
            all_logos[competition] = logos
        except Exception as e:
            print(f"  failed: {e}")

    lines = []
    lines.append("// Auto-generated from FootyLogos.")
    lines.append("// You can copy useful entries into badge_overrides.dart later.")
    lines.append("")
    lines.append("const Map<String, String> generatedBadgeOverrides = {")

    for competition, logos in all_logos.items():
        lines.append(f"  // {competition}")
        for team, logo_url in sorted(logos.items()):
            lines.append(f"  '{dart_escape(team)}':")
            lines.append(f"      '{dart_escape(logo_url)}',")
        lines.append("")

    lines.append("};")
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text("\n".join(lines), encoding="utf-8")

    print(f"\nDone. Wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()