#!/bin/sh

set -e

TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    echo 'Please specify the target directory!'
    exit 1
fi

mkdir -p "$TARGET_DIR"
mkdir "${TARGET_DIR}/home"
mkdir "${TARGET_DIR}/bin"

export HOME="${TARGET_DIR}/home"

echo '#!/bin/sh' > "${TARGET_DIR}/bin/php"
echo '# see: https://github.com/php/frankenphp/pull/610/commits/c6c9dccc457ce5fc3d3de5a731823dad69630434' >> "${TARGET_DIR}/bin/php"
echo 'for arg in "$@"; do' >> "${TARGET_DIR}/bin/php"
echo '    if [ "$arg" = "-d" ]; then' >> "${TARGET_DIR}/bin/php"
echo '        shift; shift' >> "${TARGET_DIR}/bin/php"
echo '    fi' >> "${TARGET_DIR}/bin/php"
echo 'done' >> "${TARGET_DIR}/bin/php"
echo 'selfDir="$( dirname -- "$( realpath -- "$0" )" )"' >> "${TARGET_DIR}/bin/php"
echo '"${selfDir}/../frankenphp/frankenphp" php-cli "$@"' >> "${TARGET_DIR}/bin/php"
chmod +x "${TARGET_DIR}/bin/php"

export PHP_BINARY="${TARGET_DIR}/bin/php"

mkdir "${TARGET_DIR}/dev-base"

echo '#!/bin/sh' > "${TARGET_DIR}/dev-base/prepare.sh"
echo "export HOME='${TARGET_DIR}/home'" >> "${TARGET_DIR}/dev-base/prepare.sh"
echo "export PHP_BINARY='${TARGET_DIR}/bin/php'" >> "${TARGET_DIR}/dev-base/prepare.sh"
echo 'if [ ! -e .env ] && [ -f .env.example ]; then cp .env.example .env; fi' >> "${TARGET_DIR}/dev-base/prepare.sh"
echo '../bin/php ../composer/composer.phar install' >> "${TARGET_DIR}/dev-base/prepare.sh"
echo 'touch database/database.sqlite' >> "${TARGET_DIR}/dev-base/prepare.sh"
echo '../bin/php artisan migrate:fresh --force --seed' >> "${TARGET_DIR}/dev-base/prepare.sh"
chmod +x "${TARGET_DIR}/dev-base/prepare.sh"

echo '#!/bin/sh' > "${TARGET_DIR}/dev-base/serve.sh"
echo "export PHP_BINARY='${TARGET_DIR}/bin/php'" >> "${TARGET_DIR}/dev-base/serve.sh"
echo '../frankenphp/frankenphp php-server --listen :8888 --root public' >> "${TARGET_DIR}/dev-base/serve.sh"
chmod +x "${TARGET_DIR}/dev-base/serve.sh"

mkdir "${TARGET_DIR}/frankenphp"
curl -fL -o "${TARGET_DIR}/frankenphp/frankenphp" 'https://github.com/php/frankenphp/releases/download/v1.11.1/frankenphp-linux-x86_64'
chmod +x "${TARGET_DIR}/frankenphp/frankenphp"

mkdir "${TARGET_DIR}/composer"
curl -fL -o "${TARGET_DIR}/composer/composer-setup.php" 'https://getcomposer.org/installer'
"${TARGET_DIR}/frankenphp/frankenphp" php-cli "${TARGET_DIR}/composer/composer-setup.php" --install-dir="${TARGET_DIR}/composer" --filename=composer.phar

mkdir "${TARGET_DIR}/vscodium"
curl -fL -o "${TARGET_DIR}/vscodium/vscodium.AppImage" 'https://github.com/VSCodium/vscodium/releases/download/1.108.10359/VSCodium-1.108.10359.glibc2.30-x86_64.AppImage'
chmod +x "${TARGET_DIR}/vscodium/vscodium.AppImage"

echo '#!/bin/sh' > "${TARGET_DIR}/vscodium/run.sh"
echo "export HOME='${TARGET_DIR}/home'" >> "${TARGET_DIR}/vscodium/run.sh"
echo 'export XDG_CONFIG_HOME="${HOME}/.config"' >> "${TARGET_DIR}/vscodium/run.sh"
echo 'export XDG_CACHE_HOME="${HOME}/.cache"' >> "${TARGET_DIR}/vscodium/run.sh"
echo 'export XDG_DATA_HOME="${HOME}/.local/share"' >> "${TARGET_DIR}/vscodium/run.sh"
echo 'export XDG_STATE_HOME="${HOME}/.local/state"' >> "${TARGET_DIR}/vscodium/run.sh"
echo 'selfDir="$( dirname -- "$( realpath -- "$0" )" )"' >> "${TARGET_DIR}/vscodium/run.sh"
echo '( cd "$selfDir" && ./vscodium.AppImage --no-sandbox --disable-setuid-sandbox )' >> "${TARGET_DIR}/vscodium/run.sh"
chmod +x "${TARGET_DIR}/vscodium/run.sh"
