#!/usr/bin/env bash
# Install claude-tracker for the current user and add its module to HyprPanel.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE="$DATA/claude-tracker"
FONTS="$DATA/fonts/claude-tracker"
CONF="$CONFIG_HOME/claude-tracker"
HYPRPANEL="$CONFIG_HOME/hyprpanel"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

say "Checking dependencies"
if ! /usr/bin/python3 -c '
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gtk4LayerShell
' 2>/dev/null; then
    echo "Missing GTK 4, gtk4-layer-shell or PyGObject."
    echo "On Arch: sudo pacman -S gtk4 gtk4-layer-shell python-gobject"
    exit 1
fi

say "Installing the app to $BIN/claude-tracker"
install -Dm755 "$REPO/claude-tracker" "$BIN/claude-tracker"
mkdir -p "$SHARE" && cp "$REPO"/assets/*.png "$SHARE/"

say "Installing pixel fonts to $FONTS"
mkdir -p "$FONTS" && cp "$REPO"/fonts/*.ttf "$REPO"/fonts/OFL-*.txt "$FONTS/"
command -v fc-cache >/dev/null && fc-cache -f "$FONTS" >/dev/null

if [[ ! -f "$CONF/config.toml" ]]; then
    say "Creating $CONF/config.toml (edit it to list your accounts)"
    install -Dm644 "$REPO/config.example.toml" "$CONF/config.toml"
else
    say "Keeping your existing $CONF/config.toml"
fi

if [[ -d "$HYPRPANEL" ]]; then
    say "Adding the custom/claude-tracker module to HyprPanel"
    touch "$HYPRPANEL/modules.scss"
    [[ -s "$HYPRPANEL/modules.json" ]] || echo '{}' > "$HYPRPANEL/modules.json"
    /usr/bin/python3 - "$REPO" "$HYPRPANEL" "$BIN" "$SHARE" <<'EOF'
import json, re, sys
repo, hp, bin_dir, share = sys.argv[1:]
snippet = json.loads(open(f"{repo}/hyprpanel/modules.json").read().replace("@BIN@", bin_dir))
modules = json.load(open(f"{hp}/modules.json"))
modules.update(snippet)
with open(f"{hp}/modules.json", "w") as f:
    json.dump(modules, f, indent=2)
    f.write("\n")
scss = open(f"{hp}/modules.scss").read()
block = open(f"{repo}/hyprpanel/modules.scss").read().replace("@SHARE@", share)
scss = re.sub(r"/\* claude-tracker:start \*/.*?/\* claude-tracker:end \*/\n?", "", scss, flags=re.S)
with open(f"{hp}/modules.scss", "w") as f:
    f.write(scss.rstrip("\n") + ("\n\n" if scss.strip() else "") + block)
EOF
else
    echo "HyprPanel config not found at $HYPRPANEL; skipping the bar module."
fi

cat <<EOF

Done. Two steps left:
  1. Add "custom/claude-tracker" to a bar layout in $HYPRPANEL/config.json
     (bar.layouts -> left/middle/right), or through HyprPanel's settings.
  2. Restart HyprPanel:  hyprpanel -q; hyprctl dispatch exec hyprpanel

Try it without the bar:  claude-tracker
EOF
