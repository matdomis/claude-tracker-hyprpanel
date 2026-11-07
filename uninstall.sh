#!/usr/bin/env bash
# Remove claude-tracker. Your config in ~/.config/claude-tracker is kept.
set -euo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPRPANEL="$CONFIG_HOME/hyprpanel"

rm -f "$HOME/.local/bin/claude-tracker" "${XDG_CACHE_HOME:-$HOME/.cache}/claude-tracker.json"
rm -rf "$DATA/claude-tracker" "$DATA/fonts/claude-tracker"

if [[ -d "$HYPRPANEL" ]]; then
    /usr/bin/python3 - "$HYPRPANEL" <<'EOF'
import json, os, re, sys
hp = sys.argv[1]
path = f"{hp}/modules.json"
if os.path.exists(path):
    modules = json.load(open(path))
    modules.pop("custom/claude-tracker", None)
    with open(path, "w") as f:
        json.dump(modules, f, indent=2)
        f.write("\n")
path = f"{hp}/modules.scss"
if os.path.exists(path):
    scss = open(path).read()
    scss = re.sub(r"\n*/\* claude-tracker:start \*/.*?/\* claude-tracker:end \*/\n?", "\n", scss, flags=re.S)
    open(path, "w").write(scss.strip("\n") + "\n" if scss.strip() else "")
EOF
fi

echo "Removed. Also remove \"custom/claude-tracker\" from your HyprPanel bar layout and restart HyprPanel."
