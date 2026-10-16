#!/bin/bash
set -Eeuo pipefail

# ==========================================
# FirewallFalcon Manager - Instalador completo
# ==========================================

# Must be root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# URLs (IPv4 forced to avoid GitHub IPv6 issues)
BASE_URL="https://raw.githubusercontent.com/ianalejandrook14x/PANEL-SSH/refs/heads/main"
MENU_URL="$BASE_URL/menu.sh"
SSHD_URL="$BASE_URL/ssh"
FIXX_URL="$BASE_URL/FIXX"

echo "=========================================="
echo " Instalando FirewallFalcon Manager..."
echo "=========================================="

# Temporary directory
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ==========================================
# 1. Install menu
# ==========================================

echo "[1/5] Instalando FirewallFalcon menu..."

wget -4 -q -O "$TMP_DIR/menu" "$MENU_URL"

if [[ ! -s "$TMP_DIR/menu" ]]; then
    echo "ERROR: Fallo al descargar el menu."
    exit 1
fi

install -m 755 "$TMP_DIR/menu" /usr/local/bin/menu

# ==========================================
# 2. Configure SSH
# ==========================================

echo "[2/5] Aplicando la configuración SSH de FirewallFalcon..."

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F-%H%M%S)"

if [[ ! -f "$SSHD_CONFIG" ]]; then
    echo "ERROR: No se encontró la configuración de SSH: $SSHD_CONFIG"
    exit 1
fi

# Backup current SSH config
cp -a "$SSHD_CONFIG" "$BACKUP"
echo "SSH copia de seguridad creada: $BACKUP"

# Download SSH configuration to a temporary file
wget -4 -q -O "$TMP_DIR/sshd_config" "$SSHD_URL"

if [[ ! -s "$TMP_DIR/sshd_config" ]]; then
    echo "ERROR: No se pudo descargar la configuración de SSH.."
    exit 1
fi

chmod 600 "$TMP_DIR/sshd_config"
install -m 600 "$TMP_DIR/sshd_config" "$SSHD_CONFIG"

# Validate SSH config
if ! sshd -t 2>/dev/null; then
    echo "ERROR: ¡La configuración SSH no es válida!"
    echo "Restaurando la configuración anteriorn..."
    cp -a "$BACKUP" "$SSHD_CONFIG"
    exit 1
fi

echo "Configuración SSH validada."

# Restart SSH quietly and safely
restart_ssh() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart sshd 2>/dev/null \
            || systemctl restart ssh 2>/dev/null \
            || return 1
    elif command -v service >/dev/null 2>&1; then
        service sshd restart 2>/dev/null \
            || service ssh restart 2>/dev/null \
            || return 1
    elif command -v rc-service >/dev/null 2>&1; then
        rc-service sshd restart 2>/dev/null \
            || rc-service ssh restart 2>/dev/null \
            || return 1
    elif [[ -x /etc/init.d/sshd ]]; then
        /etc/init.d/sshd restart >/dev/null 2>&1
    elif [[ -x /etc/init.d/ssh ]]; then
        /etc/init.d/ssh restart >/dev/null 2>&1
    else
        return 1
    fi
}

if restart_ssh; then
    echo "SSH servicio reiniciado."
else
    echo "ADVERTENCIA: El reinicio de SSH no es compatible con este sistema."
    echo "Se aplicó la configuración de SSH, pero el servicio no se reinició automáticamente."
fi

# ==========================================
# 3. Instalar FalconProxy files
# ==========================================

echo "[3/5] Descargando archivos de FalconProxy..."

download_file() {
    local filename="$1"

    echo "Descargando $filename..."

    if ! wget -4 -q -O "$TMP_DIR/$filename" "$FIXX_URL/$filename"; then
        echo "ERROR: Error al descargar $filename"
        exit 1
    fi

    if [[ ! -s "$TMP_DIR/$filename" ]]; then
        echo "ERROR: El archivo descargado está vacío: $filename"
        exit 1
    fi
}

download_file "falconproxy_config.conf"
download_file "falconproxy.service"
download_file "falconproxy"

# Create required directories
install -d -m 755 /etc/firewallfalcon
install -d -m 755 /etc/systemd/system
install -d -m 755 /usr/local/bin

echo "Instalación de los archivos de FalconProxy..."

# Install configuration
install -m 600 \
    "$TMP_DIR/falconproxy_config.conf" \
    /etc/firewallfalcon/falconproxy_config.conf

# Install systemd service
install -m 644 \
    "$TMP_DIR/falconproxy.service" \
    /etc/systemd/system/falconproxy.service

# Install executable
install -m 755 \
    "$TMP_DIR/falconproxy" \
    /usr/local/bin/falconproxy

echo "Los archivos de FalconProxy se han instalado correctamente."

# ==========================================
# 4. Start FalconProxy
# ==========================================

echo "[4/5] Recargando systemd..."

systemctl daemon-reload

echo "Iniciando FalconProxy..."

if ! systemctl start falconproxy; then
    echo "ERROR: No se pudo iniciar FalconProxy."
    echo "Registros de servicio:"
    journalctl -u falconproxy -n 30 --no-pager || true
    exit 1
fi

# Verify service status
if systemctl is-active --quiet falconproxy; then
    echo "ÉXITO: ​​FalconProxy está activo."
else
    echo "ERROR: FalconProxy no está activo."
    systemctl status falconproxy --no-pager -l || true
    journalctl -u falconproxy -n 30 --no-pager || true
    exit 1
fi

echo ""
echo "FalconProxy estado:"
systemctl status falconproxy --no-pager -l || true

# ==========================================
# 5. Run FirewallFalcon setup
# ==========================================

echo "[5/5] Ejecutando la instalación de FirewallFalcon..."

bash /usr/local/bin/menu --install-setup

echo ""
echo "=========================================="
echo " Instalación de FirewallFalcon completada"
echo "=========================================="
echo "FalconProxy: $(systemctl is-active falconproxy)"
echo "Escribe 'menú' para comenzar."
