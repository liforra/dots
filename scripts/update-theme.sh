#!/bin/bash

# Script name for logging
SCRIPT_NAME=$(basename "$0" .sh)
LOG_DIR="$HOME/.log"
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories (kept for detection purposes)
# We will use these paths to *detect* the theme, but not to *directly* mount them for Flatpak.
PLASMA_THEME_DIR="$HOME/.local/share/plasma/desktoptheme"
COLOR_SCHEME_DIR="$HOME/.local/share/color-schemes"
GTK_THEME_DIR="$HOME/.themes"
AURORAE_DIR="$HOME/.local/share/aurorae/themes"

# Cursor theme directories
CURSOR_USER_DIR="$HOME/.local/share/icons"
CURSOR_USER_ALT_DIR="$HOME/.icons" # Also a common location for user icons/cursors

# KDE Config files
KDE_GLOBALS="$HOME/.config/kdeglobals"
PLASMA_RC="$HOME/.config/plasmarc"
KWIN_RC="$HOME/.config/kwinrc"
KCMINPUT_RC="$HOME/.config/kcminputrc" # This is a file, not a directory

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Start logging
log "=== Theme Update Script Started ==="

echo "🎨 Configuring Flatpak theme access..."

# Function to find theme in user or system directories
# This is now only for *detection*, not for passing to --filesystem directly.
# Flatpak runtimes generally handle /usr/share paths.
find_theme() {
    local theme_name=$1
    local user_dir=$2
    local system_dir=$3 # Kept for robust detection from system if needed

    if [ -d "$user_dir/$theme_name" ]; then
        echo "$user_dir/$theme_name"
    elif [ -d "$system_dir/$theme_name" ]; then
        echo "$system_dir/$theme_name"
    else
        echo ""
    fi
}

# Function to find cursor theme
find_cursor_theme() {
    local cursor_name=$1

    # Check user directories first
    if [ -d "$CURSOR_USER_DIR/$cursor_name" ]; then
        echo "$CURSOR_USER_DIR/$cursor_name"
    elif [ -d "$CURSOR_USER_ALT_DIR/$cursor_name" ]; then
        echo "$CURSOR_USER_ALT_DIR/$cursor_name"
    # Flatpak apps generally have access to /usr/share/icons via their runtime
    # so we don't need to explicitly find and mount it.
    else
        echo ""
    fi
}

# 1. Detect GTK Theme (KDE way)
log "Detecting GTK Theme..."
GTK_THEME=""

if [ -f "$KDE_GLOBALS" ]; then
    GTK_THEME=$(grep -oP '(?<=gtk_theme=).*' "$KDE_GLOBALS" 2>/dev/null)
fi

if [ -z "$GTK_THEME" ] && command -v gsettings &> /dev/null; then
    GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
fi

if [ -n "$GTK_THEME" ] && [ "$GTK_THEME" != "Default" ]; then
    # Set the GTK_THEME environment variable for Flatpak applications
    flatpak override --user --env=GTK_THEME="$GTK_THEME" &>/dev/null
    flatpak override --user --env=GTK_APPLICATION_PREFER_DARK_THEME=1 &>/dev/null # Optional: for dark mode if preferred
    
    # Expose user GTK theme directory if it's where the theme is located
    if [ -d "$GTK_THEME_DIR/$GTK_THEME" ]; then
        flatpak override --user --filesystem="$GTK_THEME_DIR":ro &>/dev/null
    fi
    echo "✓ GTK Theme: $GTK_THEME configured for Flatpak"
    log "✓ GTK Theme: $GTK_THEME"
else
    log "No custom GTK theme detected"
    flatpak override --user --unset-env=GTK_THEME &>/dev/null
    flatpak override --user --unset-env=GTK_APPLICATION_PREFER_DARK_THEME &>/dev/null
    flatpak override --user --no-filesystem="$GTK_THEME_DIR" &>/dev/null # Remove if not used
fi

# 2. Detect Plasma Color Scheme
log "Detecting Plasma Color Scheme..."
COLOR_SCHEME=""

if [ -f "$KDE_GLOBALS" ]; then
    COLOR_SCHEME=$(grep -oP '(?<=ColorScheme=).*' "$KDE_GLOBALS" 2>/dev/null)
    if [ -z "$COLOR_SCHEME" ]; then
        COLOR_SCHEME=$(awk '/^\[General\]/{flag=1; next} /^\[/{flag=0} flag && /ColorScheme=/{gsub(/ColorScheme=/, ""); print}' "$KDE_GLOBALS" 2>/dev/null)
    fi
fi

if [ -n "$COLOR_SCHEME" ]; then
    flatpak override --user --env=KDE_COLOR_SCHEME="$COLOR_SCHEME" &>/dev/null
    # Expose user color scheme directory if it's where the scheme is located
    if [ -f "$COLOR_SCHEME_DIR/$COLOR_SCHEME.colors" ]; then
        flatpak override --user --filesystem="$COLOR_SCHEME_DIR":ro &>/dev/null
    fi
    echo "✓ Color Scheme: $COLOR_SCHEME configured for Flatpak"
    log "✓ Color Scheme: $COLOR_SCHEME"
else
    log "No custom color scheme detected"
    flatpak override --user --unset-env=KDE_COLOR_SCHEME &>/dev/null
    flatpak override --user --no-filesystem="$COLOR_SCHEME_DIR" &>/dev/null
fi

# 3. Detect Active Plasma Desktop Theme
log "Detecting Plasma Desktop Theme..."
PLASMA_THEME=""

if [ -f "$PLASMA_RC" ]; then
    PLASMA_THEME=$(grep -oP '(?<=Theme=).*' "$PLASMA_RC" 2>/dev/null)
fi

if [ -n "$PLASMA_THEME" ] && [ "$PLASMA_THEME" != "default" ]; then
    # If the theme is in a user directory, expose that directory
    if [ -d "$PLASMA_THEME_DIR/$PLASMA_THEME" ]; then
        flatpak override --user --filesystem="$PLASMA_THEME_DIR":ro &>/dev/null
        echo "✓ Plasma Theme: $PLASMA_THEME (user directory exposed)"
        log "✓ Plasma Theme: $PLASMA_THEME"
    else
        echo "✓ Plasma Theme: $PLASMA_THEME (system theme, handled by runtime)"
        log "✓ Plasma Theme: $PLASMA_THEME (system)"
    fi
else
    log "Using default Plasma theme"
    flatpak override --user --no-filesystem="$PLASMA_THEME_DIR" &>/dev/null
fi

# 4. Detect Window Decoration Theme
log "Detecting Window Decoration..."
WINDOW_DECORATION=""

if [ -f "$KWIN_RC" ]; then
    WINDOW_DECORATION=$(grep -A 10 '\[org.kde.kdecoration2\]' "$KWIN_RC" | grep -oP '(?<=theme=).*' 2>/dev/null)
    
    if [ -n "$WINDOW_DECORATION" ]; then
        CLEAN_DECORATION=$(echo "$WINDOW_DECORATION" | sed 's/__aurorae__svg__//')
        
        # If the decoration is in a user directory, expose that directory
        if [ -d "$AURORAE_DIR/$CLEAN_DECORATION" ]; then
            flatpak override --user --filesystem="$AURORAE_DIR":ro &>/dev/null
            echo "✓ Window Decoration: $CLEAN_DECORATION (user directory exposed)"
            log "✓ Window Decoration: $CLEAN_DECORATION"
        else
            echo "✓ Window Decoration: $CLEAN_DECORATION (system theme or basic, handled by runtime)"
            log "✓ Window Decoration: $CLEAN_DECORATION (system)"
        fi
    else
        log "Using default window decoration"
        flatpak override --user --no-filesystem="$AURORAE_DIR" &>/dev/null
    fi
fi

# 5. Detect Mouse Cursor Theme
log "Detecting Mouse Cursor Theme..."
CURSOR_THEME=""

if [ -f "$KCMINPUT_RC" ]; then
    CURSOR_THEME=$(grep -oP '(?<=cursorTheme=).*' "$KCMINPUT_RC" 2>/dev/null)
fi

if [ -z "$CURSOR_THEME" ] && [ -f "$HOME/.icons/default/index.theme" ]; then
    CURSOR_THEME=$(grep -oP '(?<=Inherits=).*' "$HOME/.icons/default/index.theme" 2>/dev/null)
fi

if [ -z "$CURSOR_THEME" ] && [ -f "$HOME/.Xresources" ]; then
    CURSOR_THEME=$(grep -oP '(?<=Xcursor.theme:\s).*' "$HOME/.Xresources" 2>/dev/null)
fi

if [ -n "$CURSOR_THEME" ] && [ "$CURSOR_THEME" != "default" ]; then
    # Set the XCURSOR_THEME environment variable
    flatpak override --user --env=XCURSOR_THEME="$CURSOR_THEME" &>/dev/null
    
    # Expose user cursor theme directories
    # Check if the theme exists in user directories first
    if [ -d "$CURSOR_USER_DIR/$CURSOR_THEME" ]; then
        flatpak override --user --filesystem="$CURSOR_USER_DIR":ro &>/dev/null
    elif [ -d "$CURSOR_USER_ALT_DIR/$CURSOR_THEME" ]; then
        flatpak override --user --filesystem="$CURSOR_USER_ALT_DIR":ro &>/dev/null
    fi
    echo "✓ Cursor Theme: $CURSOR_THEME configured for Flatpak"
    log "✓ Cursor Theme: $CURSOR_THEME"
else
    log "Using default cursor theme"
    flatpak override --user --unset-env=XCURSOR_THEME &>/dev/null
    flatpak override --user --no-filesystem="$CURSOR_USER_DIR" &>/dev/null
    flatpak override --user --no-filesystem="$CURSOR_USER_ALT_DIR" &>/dev/null
fi


# 6. Apply global theme and icon overrides for Flatpaks
echo ""
echo "Setting global Flatpak configuration overrides..."

# Common environment variables and filesystem access
# Using :ro for read-only to enhance security
flatpak override --user \
    --env=GTK_CSD=0 \
    --env=QT_QPA_PLATFORMTHEME=qt5ct \
    --env=KDE_NO_FILENO_CHECK=1 \
    --filesystem=xdg-config/gtk-3.0:ro \
    --filesystem=xdg-config/gtk-4.0:ro \
    --filesystem=xdg-config/kdeglobals:ro \
    --filesystem=xdg-config/kcminputrc:ro \
    --filesystem=xdg-config/plasma-localrc:ro \
    --filesystem=xdg-config/plasmarc:ro \
    --filesystem=xdg-config/kwinrc:ro \
    --filesystem=xdg-data/icons:ro \
    --filesystem=xdg-data/themes:ro \
    --filesystem=xdg-data/color-schemes:ro \
    --filesystem=xdg-data/plasma/desktoptheme:ro \
    --filesystem=xdg-data/aurorae/themes:ro \
    --filesystem=~/.config/qt5ct:ro \
    --filesystem=~/.config/KDE:ro \
    --filesystem=xdg-config/gtk-2.0:ro \
    --filesystem=xdg-config/xsettingsd:ro \
    --persist=.icons \
    --persist=.themes \
    --persist=.config/gtk-3.0 \
    --persist=.config/gtk-4.0 \
    --persist/config/kdeglobals \
    --persist/config/kcminputrc \
    --persist/config/plasma-localrc \
    --persist/config/plasmarc \
    --persist/config/kwinrc \
    --persist/config/qt5ct \
    --persist/config/KDE \
    --persist/config/gtk-2.0 \
    --persist/config/xsettingsd \
    --persist/.local/share/color-schemes \
    --persist/.local/share/plasma/desktoptheme \
    --persist/.local/share/aurorae/themes \
    &>/dev/null # Suppress output from this large command

echo "✓ Global Flatpak configuration overrides applied."
log "Global Flatpak configuration overrides applied."


echo ""
echo -e "${GREEN}🎉 Theme configuration complete!${NC}"
echo "📋 Detailed log: $LOG_FILE"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC} Restart any running Flatpak apps (including Brave) to apply changes."
echo "You might need to restart your entire session or reboot for some changes to take full effect."

# Log completion
log "=== Theme Update Script Completed ==="
log ""
