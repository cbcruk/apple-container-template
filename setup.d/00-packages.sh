PACKAGES=(
  build-essential pkg-config
  python3 python3-venv
  jq ripgrep fd-find
)

apt-get update
apt-get install -y --no-install-recommends "${PACKAGES[@]}"
