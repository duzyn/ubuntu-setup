#!/bin/bash
set -e

# Source scripts only if they exist
for script in ./check-version.sh ./set-mirrors.sh ./terminal.sh ./desktop.sh; do
    if [ -f "$script" ]; then
        source "$script"
    fi
done

# Check if plank is installed and add to autostart
if command -v plank &>/dev/null; then
    echo "Plank is installed, adding to autostart..."
    
    # Create autostart directory if not exists
    mkdir -p ~/.config/autostart
    
    # Create plank autostart desktop entry
    cat > ~/.config/autostart/plank.desktop << 'EOF'
[Desktop Entry]
Name=Plank
Comment=Stupidly simple dock
Exec=plank
Icon=plank
Type=Application
Terminal=false
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF
    
    echo "Plank has been added to autostart."
else
    echo "Plank is not installed, skipping autostart configuration."
fi

