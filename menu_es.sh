#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_UL=$'\033[4m'

# Premium Color Palette
C_RED=$'\033[38;5;196m'      # Bright Red
C_GREEN=$'\033[38;5;46m'     # Neon Green
C_YELLOW=$'\033[38;5;226m'   # Bright Yellow
C_BLUE=$'\033[38;5;39m'      # Deep Sky Blue
C_PURPLE=$'\033[38;5;135m'   # Light Purple
C_CYAN=$'\033[38;5;51m'      # Cyan
C_WHITE=$'\033[38;5;255m'    # Bright White
C_GRAY=$'\033[38;5;245m'     # Gray
C_ORANGE=$'\033[38;5;208m'   # Orange

# Semantic Aliases
C_TITLE=$C_PURPLE
C_CHOICE=$C_CYAN
C_PROMPT=$C_BLUE
C_WARN=$C_YELLOW
C_DANGER=$C_RED
C_STATUS_A=$C_GREEN
C_STATUS_I=$C_GRAY
C_ACCENT=$C_ORANGE

DB_DIR="/etc/firewallfalcon"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
BADVPN_SERVICE_FILE="/etc/systemd/system/badvpn.service"
BADVPN_BUILD_DIR="/root/badvpn-build"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/default"
SSL_CERT_DIR="/etc/firewallfalcon/ssl"
SSL_CERT_FILE="$SSL_CERT_DIR/firewallfalcon.pem"
SSL_CERT_CHAIN_FILE="$SSL_CERT_DIR/firewallfalcon.crt"
SSL_CERT_KEY_FILE="$SSL_CERT_DIR/firewallfalcon.key"
EDGE_CERT_INFO_FILE="$DB_DIR/edge_cert.conf"
NGINX_PORTS_FILE="$DB_DIR/nginx_ports.conf"
EDGE_PUBLIC_HTTP_PORT="80"
EDGE_PUBLIC_TLS_PORT="443"
NGINX_INTERNAL_HTTP_PORT="8880"
NGINX_INTERNAL_TLS_PORT="8443"
HAPROXY_INTERNAL_DECRYPT_PORT="10443"
DNSTT_SERVICE_FILE="/etc/systemd/system/dnstt.service"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_KEYS_DIR="/etc/firewallfalcon/dnstt"
DNSTT_CONFIG_FILE="$DB_DIR/dnstt_info.conf"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
UDP_CUSTOM_DIR="/root/udp"
UDP_CUSTOM_SERVICE_FILE="/etc/systemd/system/udp-custom.service"
UDPGW_BINARY="/usr/local/bin/udpgw"
UDPGW_SERVICE_FILE="/etc/systemd/system/udpgw.service"
SSH_BANNER_FILE="/etc/bannerssh"
FALCONPROXY_SERVICE_FILE="/etc/systemd/system/falconproxy.service"
FALCONPROXY_BINARY="/usr/local/bin/falconproxy"
FALCONPROXY_CONFIG_FILE="$DB_DIR/falconproxy_config.conf"
LIMITER_SCRIPT="/usr/local/bin/firewallfalcon-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/firewallfalcon-limiter.service"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANDWIDTH_SCRIPT="/usr/local/bin/firewallfalcon-bandwidth.sh"
BANDWIDTH_SERVICE="/etc/systemd/system/firewallfalcon-bandwidth.service"
LEGACY_BANDWIDTH_DIR="/usr/local/bin/firewallfalcon-bandwidth"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/firewallfalcon-trial-cleanup.sh"
LOGIN_INFO_SCRIPT="/usr/local/bin/firewallfalcon-login-info.sh"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/firewallfalcon.conf"

# --- Web Panel Variables ---
PANEL_SCRIPT="/usr/local/bin/firewallfalcon-panel.py"
PANEL_HTML_DIR="$DB_DIR/panel"
PANEL_HTML_FILE="$DB_DIR/panel/index.html"
PANEL_CONF="$DB_DIR/panel.conf"
PANEL_SERVICE_FILE="/etc/systemd/system/firewallfalcon-panel.service"
PANEL_PORT=44380
PANEL_REPO_BASE="https://raw.githubusercontent.com/FirewallFalconsLabs/FirewallFalcon-Manager/main/panel"

# --- ZiVPN Variables ---
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
ZIVPN_CERT_FILE="$ZIVPN_DIR/zivpn.crt"
ZIVPN_KEY_FILE="$ZIVPN_DIR/zivpn.key"

DESEC_TOKEN="vQqFrrENFzGw5iPYR2ud8kZQVdZt"
DESEC_DOMAIN="manager.fixxed.site"

SELECTED_USER=""
UNINSTALL_MODE="interactive"
BANNER_CACHE_TTL=15
BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""
BANNER_CACHE_UP_TIME=""
BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""
BANNER_CACHE_ONLINE_USERS=0
BANNER_CACHE_TOTAL_USERS=0
SSH_SESSION_CACHE_TTL=10
SSH_SESSION_CACHE_TS=0
SSH_SESSION_CACHE_DB_MTIME=0
SSH_SESSION_TOTAL=0
APT_CACHE_READY=0
FF_USERS_GROUP="ffusers"
declare -A SSH_SESSION_COUNTS=()
declare -A SSH_SESSION_PIDS=()

# --- Package Manager Abstraction ---
FF_PKG_MGR=""
_detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        FF_PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        FF_PKG_MGR="dnf"
    elif command -v yum &>/dev/null; then
        FF_PKG_MGR="yum"
    elif command -v zypper &>/dev/null; then
        FF_PKG_MGR="zypper"
    elif command -v pacman &>/dev/null; then
        FF_PKG_MGR="pacman"
    else
        echo -e "${C_RED}❌ No supported package manager found (apt/dnf/yum/zypper/pacman).${C_RESET}"
        exit 1
    fi
}
_detect_pkg_manager

_map_pkg_names() {
    local -a result=()
    local pkg
    for pkg in "$@"; do
        case "$FF_PKG_MGR" in
            dnf|yum)
                case "$pkg" in
                    build-essential) result+=(gcc gcc-c++ make) ;;
                    libssl-dev) result+=(openssl-devel) ;;
                    libnspr4-dev) result+=(nspr-devel) ;;
                    libnss3-dev) result+=(nss-devel) ;;
                    nginx-common) result+=(nginx) ;;
                    pkg-config) result+=(pkgconf) ;;
                    *) result+=("$pkg") ;;
                esac ;;
            zypper)
                case "$pkg" in
                    build-essential) result+=(gcc gcc-c++ make) ;;
                    libssl-dev) result+=(libopenssl-devel) ;;
                    libnspr4-dev) result+=(mozilla-nspr-devel) ;;
                    libnss3-dev) result+=(mozilla-nss-devel) ;;
                    nginx-common) result+=(nginx) ;;
                    *) result+=("$pkg") ;;
                esac ;;
            pacman)
                case "$pkg" in
                    build-essential) result+=(base-devel) ;;
                    libssl-dev) result+=(openssl) ;;
                    libnspr4-dev) result+=(nspr) ;;
                    libnss3-dev) result+=(nss) ;;
                    nginx-common) result+=(nginx) ;;
                    bc) result+=(bc) ;;
                    *) result+=("$pkg") ;;
                esac ;;
            *) result+=("$pkg") ;;
        esac
    done
    printf '%s\n' "${result[@]}"
}

if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ Error: Este script requiere privilegios de root para ejecutarse..${C_RESET}"
   exit 1
fi

get_ubuntu_codename() {
    local codename=""

    if [[ -r /etc/os-release ]]; then
        codename=$(awk -F= '/^(VERSION_CODENAME|UBUNTU_CODENAME)=/{gsub(/"/, "", $2); if ($2 != "") { print $2; exit }}' /etc/os-release 2>/dev/null)
    fi

    if [[ -z "$codename" ]] && command -v lsb_release &>/dev/null; then
        codename=$(lsb_release -sc 2>/dev/null)
    fi

    echo "$codename"
}

is_known_eol_ubuntu_codename() {
    case "$1" in
        yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish|kinetic|lunar|mantic|oracular|plucky)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

rewrite_ubuntu_apt_sources() {
    local mode="$1"
    local os_id=""
    local changed=false
    local file backup_file
    local from_archive to_archive from_security to_security from_ports to_ports
    local -a source_files=("/etc/apt/sources.list" /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)

    if [[ -r /etc/os-release ]]; then
        os_id=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release 2>/dev/null)
    fi
    [[ "$os_id" == "ubuntu" ]] || return 1

    case "$mode" in
        primary)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://archive.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://security.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://ports.ubuntu.com/ubuntu-ports'
            ;;
        old-releases)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://old-releases.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://old-releases.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://old-releases.ubuntu.com/ubuntu'
            ;;
        *)
            return 1
            ;;
    esac

    for file in "${source_files[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -Eq "$from_archive|$from_security|$from_ports" "$file" 2>/dev/null; then
            backup_file="${file}.bak.firewallfalcon"
            [[ -f "$backup_file" ]] || cp "$file" "$backup_file" 2>/dev/null || true
            sed -i -E \
                -e "s|$from_archive|$to_archive|g" \
                -e "s|$from_security|$to_security|g" \
                -e "s|$from_ports|$to_ports|g" \
                "$file" 2>/dev/null
            changed=true
        fi
    done

    $changed
}

repair_ubuntu_apt_mirrors() {
    rewrite_ubuntu_apt_sources "primary"
}

switch_ubuntu_to_old_releases() {
    local codename
    codename=$(get_ubuntu_codename)
    [[ -n "$codename" ]] || return 1
    is_known_eol_ubuntu_codename "$codename" || return 1
    rewrite_ubuntu_apt_sources "old-releases"
}

ff_apt_update() {
    local -a apt_opts=(
        -o Acquire::Retries=3
        -o Acquire::ForceIPv4=true
        -o Acquire::http::Timeout=20
        -o Acquire::https::Timeout=20
        -o Acquire::http::Pipeline-Depth=0
    )

    if (( APT_CACHE_READY == 1 )); then
        return 0
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
        APT_CACHE_READY=1
        return 0
    fi

    if repair_ubuntu_apt_mirrors; then
        echo -e "${C_YELLOW}⚠️ Se agotó el tiempo de espera del espejo de APT. Cambiando las fuentes de Ubuntu a archive.ubuntu.com y reintentando....${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    if switch_ubuntu_to_old_releases; then
        echo -e "${C_YELLOW}⚠️ Se detectó una versión de Ubuntu que ha llegado al final de su ciclo de vida. Cambiando las fuentes de APT a old-releases.ubuntu.com y reintentando....${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    echo -e "${C_RED}❌ No se pudieron actualizar las listas de paquetes. Por favor, comprueba la red del VPS, el DNS o si hay réplicas de Ubuntu bloqueadas.${C_RESET}"
    return 1
}

ff_apt_install() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0

    ff_apt_update || return 1
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "${packages[@]}"
}

ff_apt_purge() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "${packages[@]}"
}

ff_pkg_install() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    local -a mapped=()
    mapfile -t mapped < <(_map_pkg_names "${packages[@]}")
    case "$FF_PKG_MGR" in
        apt) ff_apt_install "${mapped[@]}" ;;
        dnf) dnf install -y -q "${mapped[@]}" ;;
        yum) yum install -y -q "${mapped[@]}" ;;
        zypper) zypper install -y -q "${mapped[@]}" ;;
        pacman) pacman -S --noconfirm --needed "${mapped[@]}" ;;
        *) echo -e "${C_RED}❌ Gestor de paquetes no compatible.${C_RESET}"; return 1 ;;
    esac
}

ff_pkg_purge() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    local -a mapped=()
    mapfile -t mapped < <(_map_pkg_names "${packages[@]}")
    case "$FF_PKG_MGR" in
        apt) ff_apt_purge "${mapped[@]}" ;;
        dnf) dnf remove -y -q "${mapped[@]}" ;;
        yum) yum remove -y -q "${mapped[@]}" ;;
        zypper) zypper remove -y "${mapped[@]}" ;;
        pacman) pacman -Rns --noconfirm "${mapped[@]}" 2>/dev/null ;;
        *) echo -e "${C_RED}❌ Gestor de paquetes no compatible.${C_RESET}"; return 1 ;;
    esac
}

ff_pkg_autoremove() {
    case "$FF_PKG_MGR" in
        apt) apt-get autoremove -y >/dev/null 2>&1 ;;
        dnf) dnf autoremove -y -q >/dev/null 2>&1 ;;
        yum) yum autoremove -y -q >/dev/null 2>&1 ;;
        zypper) zypper packages --unneeded 2>/dev/null | awk -F'|' 'NR>3{print $3}' | xargs -r zypper remove -y >/dev/null 2>&1 ;;
        pacman) pacman -Qdtq 2>/dev/null | xargs -r pacman -Rns --noconfirm >/dev/null 2>&1 ;;
    esac
    return 0
}

ff_pkg_is_installed() {
    local pkg="$1"
    case "$FF_PKG_MGR" in
        apt) dpkg -s "$pkg" &>/dev/null ;;
        dnf|yum) rpm -q "$pkg" &>/dev/null ;;
        zypper) rpm -q "$pkg" &>/dev/null ;;
        pacman) pacman -Q "$pkg" &>/dev/null ;;
    esac
}

# Mandatory Dependency Check (Added jq and curl)
check_environment() {
    local missing_packages=()
    local cmd

    for cmd in bc jq curl wget; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("$cmd")
        fi
    done

    if (( ${#missing_packages[@]} > 0 )); then
        echo -e "${C_YELLOW}⚠️ Instalación de dependencias faltantes: ${missing_packages[*]}${C_RESET}"
        ff_pkg_install "${missing_packages[@]}" >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Error: No se pudieron instalar las dependencias necesarias: ${missing_packages[*]}.${C_RESET}"
            exit 1
        }
    fi
}

ensure_firewallfalcon_dirs() {
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" /etc/ssh/sshd_config.d
    touch "$DB_FILE"
}

ensure_firewallfalcon_system_group() {
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1 || true
}

db_has_user() {
    [[ -f "$DB_FILE" ]] || return 1
    awk -F: -v target="$1" '$1 == target { found=1; exit } END { exit(found ? 0 : 1) }' "$DB_FILE"
}

is_firewallfalcon_orphan_user() {
    local username="$1"
    local passwd_line system_user _ uid _ home shell

    passwd_line=$(getent passwd "$username" 2>/dev/null) || return 1
    IFS=: read -r system_user _ uid _ _ home shell <<< "$passwd_line"
    [[ "$uid" =~ ^[0-9]+$ ]] || return 1
    db_has_user "$username" && return 1

    if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -Fxq "$FF_USERS_GROUP"; then
        return 0
    fi

    (( uid >= 1000 )) || return 1
    [[ "$home" == "/home/$username" || "$home" == /home/* ]] || return 1

    case "$shell" in
        /usr/sbin/nologin|/usr/bin/false|/bin/false) return 0 ;;
    esac

    return 1
}

get_firewallfalcon_orphan_users() {
    local username
    while IFS=: read -r username _rest; do
        [[ -n "$username" ]] || continue
        if is_firewallfalcon_orphan_user "$username"; then
            echo "$username"
        fi
    done < /etc/passwd
}

get_firewallfalcon_known_users() {
    local username
    local -A seen_users=()

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r username _rest; do
            [[ -n "$username" && "$username" != \#* ]] || continue
            seen_users["$username"]=1
        done < "$DB_FILE"
    fi

    while IFS= read -r username; do
        [[ -n "$username" ]] && seen_users["$username"]=1
    done < <(get_firewallfalcon_orphan_users)

    (( ${#seen_users[@]} > 0 )) || return 0
    printf "%s\n" "${!seen_users[@]}" | sort
}

delete_firewallfalcon_user_accounts() {
    local -a users_to_delete=("$@")
    local username

    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0

    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        pkill -9 -u "$username" &>/dev/null
        sleep 0.5
        if id "$username" &>/dev/null; then
            if userdel -rf "$username" &>/dev/null; then
                echo -e " ✅ Usuario del sistema '${C_YELLOW}$username${C_RESET}' eliminado."
            else
                # Retry after harder kill
                pkill -9 -u "$username" &>/dev/null
                sleep 1
                if userdel -rf "$username" &>/dev/null; then
                    echo -e " ✅ Usuario del sistema '${C_YELLOW}$username${C_RESET}' eliminado (reintentar)."
                else
                    echo -e " ❌ No se pudo eliminar el usuario del sistema '${C_YELLOW}$username${C_RESET}'."
                fi
            fi
        else
            echo -e " ℹ️ El usuario del sistema '${C_YELLOW}$username${C_RESET}' ya no existía. Se eliminan únicamente los datos del gestor.."
        fi
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -f "$BANDWIDTH_DIR/${username}.daily_usage"
        rm -f "$BANDWIDTH_DIR/${username}.conn_locked"
        rm -f "$BANDWIDTH_DIR/${username}.daily_locked"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
    done

    if [[ -f "$DB_FILE" ]]; then
        local db_tmp
        db_tmp=$(mktemp)
        awk -F: 'NR==FNR { drop[$1]=1; next } !($1 in drop)' <(printf "%s\n" "${users_to_delete[@]}") "$DB_FILE" > "$db_tmp" && mv "$db_tmp" "$DB_FILE"
        rm -f "$db_tmp" 2>/dev/null
    fi

    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

require_interactive_terminal() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        echo -e "${C_RED}❌ Error: El menú de FirewallFalcon debe ejecutarse desde una terminal interactiva.${C_RESET}"
        exit 1
    fi
}

initial_setup() {
    echo -e "${C_BLUE}⚙️ Iniciando la configuración de FirewallFalcon Manager...${C_RESET}"
    check_environment
    
    ensure_firewallfalcon_dirs
    ensure_firewallfalcon_system_group
    
    echo -e "${C_BLUE}🔹 Configurando el servicio de limitación de usuarios...${C_RESET}"
    setup_limiter_service
    
    echo -e "${C_BLUE}🔹 Configurando el servicio de supervisión del ancho de banda...${C_RESET}"
    setup_bandwidth_service
    
    echo -e "${C_BLUE}🔹 Instalación del script de limpieza de cuentas de prueba...${C_RESET}"
    setup_trial_cleanup_script
    
    echo -e "${C_BLUE}🔹 Limpieza de ganchos (hooks) heredados para banners SSH dinámicos...${C_RESET}"
    disable_dynamic_ssh_banner_system
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    
    if [ ! -f "$INSTALL_FLAG_FILE" ]; then
        touch "$INSTALL_FLAG_FILE"
    fi
    echo -e "${C_GREEN}✅ Configuración finalizada.${C_RESET}"
}

_is_valid_ipv4() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

check_and_open_firewall_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    local firewall_detected=false

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        firewall_detected=true
        if ! ufw status | grep -qw "$port/$protocol"; then
            echo -e "${C_YELLOW}🔥 El firewall UFW está activo y el puerto ${port}/${protocol} está cerrado.${C_RESET}"
            read -p "👉 ¿Quieres abrir este puerto ahora? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw allow "$port/$protocol"
                echo -e "${C_GREEN}✅ Puerto ${port}/${protocol} se ha abierto en UFW.${C_RESET}"
            else
                echo -e "${C_RED}❌ Advertencia: Puerto ${port}/${protocol} No se abrió. Es posible que el servicio no funcione correctamente.${C_RESET}"
                return 1
            fi
        else
             echo -e "${C_GREEN}✅ Puerto ${port}/${protocol} Ya está abierto en UFW.${C_RESET}"
        fi
    fi

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall_detected=true
        if ! firewall-cmd --list-ports --permanent | grep -qw "$port/$protocol"; then
            echo -e "${C_YELLOW}🔥 firewalld está activo y el puerto ${port}/${protocol} No está abierto.${C_RESET}"
            read -p "👉 ¿Quieres abrir este puerto ahora? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                firewall-cmd --add-port="$port/$protocol" --permanent
                firewall-cmd --reload
                echo -e "${C_GREEN}✅ Puerto ${port}/${protocol} se ha abierto en firewalld.${C_RESET}"
            else
                echo -e "${C_RED}❌ Advertencia: Puerto ${port}/${protocol} No se abrió. Es posible que el servicio no funcione correctamente.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Puerto ${port}/${protocol} Ya está abierto en el firewalld.${C_RESET}"
        fi
    fi

    if ! $firewall_detected; then
        echo -e "${C_BLUE}ℹ️ No se ha detectado ningún cortafuegos (UFW o firewalld) activo. Se asume que los puertos están abiertos.${C_RESET}"
    fi
    return 0
}

check_and_open_firewall_port_range() {
    local port_range="$1"
    local protocol="${2:-tcp}"
    local firewall_detected=false

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        firewall_detected=true
        if ! ufw status | grep -Fq "$port_range/$protocol"; then
            echo -e "${C_YELLOW}🔥 El cortafuegos UFW está activo y el rango... ${port_range}/${protocol} está cerrado.${C_RESET}"
            read -p "👉 ¿Quieres abrir este rango de puertos ahora? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw allow "$port_range/$protocol"
                echo -e "${C_GREEN}✅ Rango ${port_range}/${protocol} se ha abierto en UFW.${C_RESET}"
            else
                echo -e "${C_RED}❌ Advertencia: Rango ${port_range}/${protocol} No se abrió. Es posible que el servicio no funcione correctamente..${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Rango ${port_range}/${protocol} Ya está abierto en UFW.${C_RESET}"
        fi
    fi

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall_detected=true
        if ! firewall-cmd --quiet --query-port="$port_range/$protocol"; then
            echo -e "${C_YELLOW}🔥 firewalld está activo y el rango ${port_range}/${protocol} No está abierto.${C_RESET}"
            read -p "👉 ¿Quieres abrir este rango de puertos ahora? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                firewall-cmd --add-port="$port_range/$protocol" --permanent
                firewall-cmd --reload
                echo -e "${C_GREEN}✅ Rango ${port_range}/${protocol} se ha abierto en firewalld.${C_RESET}"
            else
                echo -e "${C_RED}❌ Advertencia: Rango ${port_range}/${protocol} No se abrió. Es posible que el servicio no funcione correctamente.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Rango ${port_range}/${protocol} ya está abierto en firewalld.${C_RESET}"
        fi
    fi

    if ! $firewall_detected; then
        echo -e "${C_BLUE}ℹ️ No se ha detectado ningún cortafuegos (UFW o firewalld) activo. Se asume el rango ${port_range}/${protocol} Está abierto.${C_RESET}"
    fi
    return 0
}

check_and_free_ports() {
    local ports_to_check=("$@")
    for port in "${ports_to_check[@]}"; do
        echo -e "\n${C_BLUE}🔎 Comprobando si el puerto $port está disponible...${C_RESET}"
        local conflicting_process_info
        conflicting_process_info=$(
            ss -H -lntp "( sport = :$port )" 2>/dev/null
            ss -H -lunp "( sport = :$port )" 2>/dev/null
        )
        
        if [[ -n "$conflicting_process_info" ]]; then
            local conflicting_pid
            conflicting_pid=$(echo "$conflicting_process_info" | grep -oP 'pid=\K[0-9]+' | head -n 1)
            local conflicting_name
            conflicting_name=$(echo "$conflicting_process_info" | grep -oP 'users:\(\("(\K[^"]+)' | head -n 1)
            
            echo -e "${C_YELLOW}⚠️ Advertencia: El puerto $port está siendo utilizado por un proceso '${conflicting_name:-unknown}' (PID: ${conflicting_pid:-N/A}).${C_RESET}"
            read -p "👉 ¿Quieres intentar detener este proceso? (y/n): " kill_confirm
            if [[ "$kill_confirm" == "y" || "$kill_confirm" == "Y" ]]; then
                if [[ -z "$conflicting_pid" ]]; then
                    echo -e "${C_RED}❌ No se pudo determinar qué PID posee el puerto $port. Libéralo manualmente..${C_RESET}"
                    return 1
                fi
                echo -e "${C_GREEN}🛑 Deteniendo el proceso con PID $conflicting_pid...${C_RESET}"
                systemctl stop "$(ps -p "$conflicting_pid" -o comm=)" &>/dev/null || kill -9 "$conflicting_pid"
                sleep 2
                
                if ss -H -lntp "( sport = :$port )" 2>/dev/null | grep -q . || ss -H -lunp "( sport = :$port )" 2>/dev/null | grep -q .; then
                     echo -e "${C_RED}❌ No se pudo liberar el puerto $port. Por favor, libéralo manualmente. Abortando.${C_RESET}"
                     return 1
                else
                     echo -e "${C_GREEN}✅ El puerto $port se ha liberado correctamente..${C_RESET}"
                fi
            else
                echo -e "${C_RED}❌ No es posible continuar sin liberar el puerto $port. Abortando.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ El puerto $port está disponible para su uso.${C_RESET}"
        fi
    done
    return 0
}

setup_limiter_service() {
    # Combined limiter + bandwidth monitoring
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
# FirewallFalcon limiter version 2026-07-23.4
DB_FILE="/etc/firewallfalcon/users.db"
BW_DIR="/etc/firewallfalcon/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/firewallfalcon/banners"
SCAN_INTERVAL=10
CONN_LOCK_DURATION=60

mkdir -p "$BW_DIR" "$PID_DIR"
shopt -s nullglob

write_banner_if_changed() {
    local user="$1"
    local content="$2"
    local banner_file="$BANNER_DIR/${user}.txt"
    local tmp_file="${banner_file}.tmp"

    printf "%s" "$content" > "$tmp_file"
    if ! cmp -s "$tmp_file" "$banner_file" 2>/dev/null; then
        mv "$tmp_file" "$banner_file"
    else
        rm -f "$tmp_file"
    fi
}

# Excess sessions are killed immediately every scan cycle. No account locking.

while true; do
    if [[ ! -s "$DB_FILE" ]]; then
        sleep "$SCAN_INTERVAL"
        continue
    fi
    
    # Daily reset logic
    today=$(date +%Y-%m-%d)
    if [[ ! -f "$BW_DIR/current_date" ]]; then
        echo "$today" > "$BW_DIR/current_date"
    fi
    saved_date=$(cat "$BW_DIR/current_date" 2>/dev/null || echo "$today")
    if [[ "$today" != "$saved_date" ]]; then
        # New day! Reset daily usage and unlock users locked due to daily limit
        rm -f "$BW_DIR/"*.daily_usage 2>/dev/null
        for locked_file in "$BW_DIR/"*.daily_locked; do
            [[ -f "$locked_file" ]] || continue
            locked_user=$(basename "$locked_file" .daily_locked)
            usermod -U "$locked_user" &>/dev/null
            rm -f "$locked_file"
        done
        echo "$today" > "$BW_DIR/current_date"
    fi

    # Connection limit auto-unlock: check marker files and unlock after CONN_LOCK_DURATION seconds
    for conn_lock_file in "$BW_DIR/"*.conn_locked; do
        [[ -f "$conn_lock_file" ]] || continue
        lock_ts=0
        read -r lock_ts < "$conn_lock_file" 2>/dev/null || lock_ts=0
        [[ "$lock_ts" =~ ^[0-9]+$ ]] || lock_ts=0
        printf -v now_ts '%(%s)T' -1
        if (( now_ts - lock_ts >= CONN_LOCK_DURATION )); then
            conn_locked_user=$(basename "$conn_lock_file" .conn_locked)
            usermod -U "$conn_locked_user" &>/dev/null
            rm -f "$conn_lock_file"
        fi
    done

    printf -v current_ts '%(%s)T' -1
    dynamic_banners_enabled=false

    # Reset associative arrays each cycle (unset first to avoid stale data)
    unset session_pids locked_users uid_to_user loginuid_pids
    declare -A session_pids=()
    declare -A locked_users=()
    declare -A uid_to_user=()
    declare -A loginuid_pids=()

    while IFS=: read -r username _ uid _rest; do
        [[ -n "$username" && "$uid" =~ ^[0-9]+$ ]] && uid_to_user["$uid"]="$username"
    done < /etc/passwd

    # Method 1: process owner from ps (primary source for connection counting)
    # sshd-session is the user-owned process on Ubuntu 24.04+ (OpenSSH 9.8+)
    # On Ubuntu 22, the per-session sshd is user-owned instead.
    # Either way, exactly 1 user-owned process exists per SSH session.
    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" ]]; then
            session_pids["$ssh_owner"]+="$ssh_pid "
        fi
    done < <(ps -C sshd,sshd-session -o pid=,user= 2>/dev/null)

    # Method 2: kernel loginuid (reliable even when sshd runs as root)
    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""
        read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue

        session_user="${uid_to_user[$login_uid]}"
        [[ -n "$session_user" ]] || continue

        pid_dir=$(dirname "$p")
        pid_num=$(basename "$pid_dir")
        comm=""
        read -r comm < "$pid_dir/comm" || comm=""
        [[ "$comm" == "sshd" ]] || continue

        ppid_val=""
        while read -r key value; do
            if [[ "$key" == "PPid:" ]]; then
                ppid_val="${value:-}"
                break
            fi
        done < "$pid_dir/status"
        [[ "$ppid_val" == "1" ]] && continue

        loginuid_pids["$session_user"]+="$pid_num "
    done

    # Detect locked users via /etc/shadow (cheaper than passwd -Sa)
    if [[ -r /etc/shadow ]]; then
        while IFS=: read -r shadow_user shadow_hash _rest; do
            [[ -n "$shadow_user" && "${shadow_hash:0:1}" == "!" ]] && locked_users["$shadow_user"]=1
        done < /etc/shadow
    else
        while read -r passwd_user _ passwd_status _rest; do
            [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
        done < <(passwd -Sa 2>/dev/null)
    fi

    if [[ -f "/etc/firewallfalcon/banners_enabled" ]]; then
        mkdir -p "$BANNER_DIR"
        dynamic_banners_enabled=true
    fi

    while IFS=: read -r user pass expiry limit bandwidth_gb daily_bandwidth_gb _extra; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        
        [[ ! "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]] && daily_bandwidth_gb=0

        # CRITICAL: unset before declare to reset per-user (bash declare is function-scoped)
        unset unique_pids
        declare -A unique_pids=()

        # Use ONLY ps-based session_pids for connection counting.
        # loginuid_pids can double-count (root-owned sshd has user's loginuid on Ubuntu 24)
        for pid in ${session_pids[$user]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        online_count=${#unique_pids[@]}
        user_locked=false
        if [[ -n "${locked_users[$user]+x}" ]]; then
            user_locked=true
        fi

        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    killall -u "$user" -9 &>/dev/null
                    locked_users["$user"]=1
                fi
                continue
            fi
        fi

        [[ "$limit" =~ ^[0-9]+$ ]] || limit=1
        if (( online_count > limit )); then
            # Kill only the EXCESS sessions, keep the oldest ones alive
            sorted_pids=()
            for pid in "${!unique_pids[@]}"; do
                sorted_pids+=("$pid")
            done
            IFS=$'\n' sorted_pids=($(sort -n <<<"${sorted_pids[*]}")); unset IFS

            for (( i=limit; i<${#sorted_pids[@]}; i++ )); do
                kill -9 "${sorted_pids[$i]}" &>/dev/null
            done

            # Remove killed PIDs from unique_pids so bandwidth tracking is correct
            for (( i=limit; i<${#sorted_pids[@]}; i++ )); do
                unset unique_pids["${sorted_pids[$i]}"]
            done
            online_count=${#unique_pids[@]}
        fi

        if $dynamic_banners_enabled; then
            days_left="N/A"
            if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry_ts" =~ ^[0-9]+$ && $expiry_ts -gt 0 ]]; then
                diff_secs=$((expiry_ts - current_ts))
                if (( diff_secs <= 0 )); then
                    days_left="EXPIRED"
                else
                    d_l=$(( diff_secs / 86400 ))
                    h_l=$(( (diff_secs % 86400) / 3600 ))
                    if (( d_l == 0 )); then
                        days_left="${h_l}h Restante"
                    else
                        days_left="${d_l}d ${h_l}h"
                    fi
                fi
            fi

            bw_info="Ilimitado"
            if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
                usagefile="$BW_DIR/${user}.usage"
                accum_disp=0
                if [[ -f "$usagefile" ]]; then
                    read -r accum_disp < "$usagefile"
                    [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
                fi
                used_gb_int=$((accum_disp / 1073741824))
                used_gb_frac=$(( (accum_disp % 1073741824) * 100 / 1073741824 ))
                printf -v used_gb "%d.%02d" "$used_gb_int" "$used_gb_frac"
                quota_b=$(( ${bandwidth_gb%%.*} * 1073741824 ))
                remain_b=$(( quota_b - accum_disp ))
                (( remain_b < 0 )) && remain_b=0
                remain_gb_int=$((remain_b / 1073741824))
                remain_gb_frac=$(( (remain_b % 1073741824) * 100 / 1073741824 ))
                printf -v remain_gb "%d.%02d" "$remain_gb_int" "$remain_gb_frac"
                bw_info="${used_gb}/${bandwidth_gb} GB Usados | ${remain_gb} GB Restantes"
            fi

            banner_content="<br><font color=\"yellow\"><b>      ボ NүxIαη.xүz      </b></font><br><br>"
            banner_content+="<font color=\"white\">〆 <b>Usuario   :</b> $user</font><br>"
            banner_content+="<font color=\"white\">〆 <b>Expiración :</b> $expiry ($days_left)</font><br>"
            
            if [[ "$bandwidth_gb" != "0" ]]; then
                banner_content+="<font color=\"white\">〆 <b>Anch. Ban   :</b> $bw_info</font><br>"
            fi
            
            if [[ "$daily_bandwidth_gb" != "0" ]]; then
                daily_usagefile="$BW_DIR/${user}.daily_usage"
                accum_disp=0
                if [[ -f "$daily_usagefile" ]]; then
                    read -r accum_disp < "$daily_usagefile"
                    [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
                fi
                used_gb_int=$((accum_disp / 1073741824))
                used_gb_frac=$(( (accum_disp % 1073741824) * 100 / 1073741824 ))
                printf -v used_gb "%d.%02d" "$used_gb_int" "$used_gb_frac"
                quota_b=$(( ${daily_bandwidth_gb%%.*} * 1073741824 ))
                remain_b=$(( quota_b - accum_disp ))
                (( remain_b < 0 )) && remain_b=0
                remain_gb_int=$((remain_b / 1073741824))
                remain_gb_frac=$(( (remain_b % 1073741824) * 100 / 1073741824 ))
                printf -v remain_gb "%d.%02d" "$remain_gb_int" "$remain_gb_frac"
                daily_bw_info="${used_gb}/${daily_bandwidth_gb} GB Usados | ${remain_gb} GB Restantes"
                banner_content+="<font color=\"white\">〆 <b>Anc. Diario. BW   :</b> $daily_bw_info</font><br>"
            fi
            
            banner_content+="<font color=\"white\">〆 <b>Sesiones   :</b> $online_count/$limit</font><br><br>"
            write_banner_if_changed "$user" "$banner_content"
        fi

        [[ ( -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ) && ( -z "$daily_bandwidth_gb" || "$daily_bandwidth_gb" == "0" ) ]] && continue

        usagefile="$BW_DIR/${user}.usage"
        accumulated=0
        if [[ -f "$usagefile" ]]; then
            read -r accumulated < "$usagefile"
            [[ "$accumulated" =~ ^[0-9]+$ ]] || accumulated=0
        fi

        if (( ${#unique_pids[@]} == 0 )); then
            rm -f "$PID_DIR/${user}__"*.last 2>/dev/null
            continue
        fi

        delta_total=0
        for pid in "${!unique_pids[@]}"; do
            io_file="/proc/$pid/io"
            cur=0
            if [[ -r "$io_file" ]]; then
                rchar=0
                wchar=0
                while read -r key value; do
                    case "$key" in
                        rchar:) rchar=${value:-0} ;;
                        wchar:) wchar=${value:-0} ;;
                    esac
                done < "$io_file"
                cur=$((rchar + wchar))
            fi

            pidfile="$PID_DIR/${user}__${pid}.last"
            if [[ -f "$pidfile" ]]; then
                read -r prev < "$pidfile"
                [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
                if (( cur >= prev )); then
                    d=$((cur - prev))
                else
                    d=$cur
                fi
                delta_total=$((delta_total + d))
            fi
            printf "%s\n" "$cur" > "$pidfile"
        done

        for f in "$PID_DIR/${user}__"*.last; do
            [[ -f "$f" ]] || continue
            fpid=${f##*__}
            fpid=${fpid%.last}
            [[ -d "/proc/$fpid" ]] || rm -f "$f"
        done

        new_total=$((accumulated + delta_total))
        printf "%s\n" "$new_total" > "$usagefile"

        if awk "BEGIN{exit(!($bandwidth_gb > 0))}" 2>/dev/null; then
            quota_bytes=$(awk "BEGIN{printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( quota_bytes > 0 && new_total >= quota_bytes )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    locked_users["$user"]=1
                    user_locked=true
                fi
            fi
        fi
        
        daily_usagefile="$BW_DIR/${user}.daily_usage"
        daily_accumulated=0
        if [[ -f "$daily_usagefile" ]]; then
            read -r daily_accumulated < "$daily_usagefile"
            [[ "$daily_accumulated" =~ ^[0-9]+$ ]] || daily_accumulated=0
        fi
        new_daily_total=$((daily_accumulated + delta_total))
        printf "%s\n" "$new_daily_total" > "$daily_usagefile"
        
        if awk "BEGIN{exit(!($daily_bandwidth_gb > 0))}" 2>/dev/null; then
            d_quota_bytes=$(awk "BEGIN{printf \"%.0f\", $daily_bandwidth_gb * 1073741824}")
            if [[ "$d_quota_bytes" =~ ^[0-9]+$ ]] && (( d_quota_bytes > 0 && new_daily_total >= d_quota_bytes )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    locked_users["$user"]=1
                    user_locked=true
                    touch "$BW_DIR/${user}.daily_locked"
                fi
            fi
        fi
    done < "$DB_FILE"

    sleep "$SCAN_INTERVAL"
done
EOF
    chmod +x "$LIMITER_SCRIPT"
    # Strip DOS line endings in case menu.sh was uploaded from Windows
    sed -i 's/\r$//' "$LIMITER_SCRIPT" 2>/dev/null

    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=FirewallFalcon Active User Limiter
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
MemoryHigh=48M
MemoryMax=64M

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/\r$//' "$LIMITER_SERVICE" 2>/dev/null

    pkill -f "firewallfalcon-limiter" 2>/dev/null

    if ! systemctl is-active --quiet firewallfalcon-limiter; then
        systemctl daemon-reload
        systemctl enable firewallfalcon-limiter &>/dev/null
        systemctl start firewallfalcon-limiter --no-block &>/dev/null
        
    else
        systemctl restart firewallfalcon-limiter --no-block &>/dev/null
        
    fi
}

sync_runtime_components_if_needed() {
    local limiter_marker="# FirewallFalcon limiter version 2026-07-23.8"
    cleanup_legacy_bandwidth_runtime
    setup_trial_cleanup_script >/dev/null 2>&1
    if [[ ! -f "$LIMITER_SCRIPT" ]] || ! grep -Fqx "$limiter_marker" "$LIMITER_SCRIPT" 2>/dev/null; then
        setup_limiter_service >/dev/null 2>&1
    fi
    if [[ -f "$BADVPN_SERVICE_FILE" ]]; then
        ensure_badvpn_service_is_quiet
    fi
    if [[ -f "/etc/firewallfalcon/banners_enabled" ]]; then
        update_ssh_banners_config
    elif [[ -f "$SSHD_FF_CONFIG" ]]; then
        disable_dynamic_ssh_banner_system
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    fi
}

setup_bandwidth_service() {
    mkdir -p "$BANDWIDTH_DIR"
    # Bandwidth monitoring is now integrated into the limiter service above.
    cleanup_legacy_bandwidth_runtime
}

cleanup_legacy_bandwidth_runtime() {
    local needs_reload=false

    systemctl stop firewallfalcon-bandwidth &>/dev/null || true
    systemctl disable firewallfalcon-bandwidth &>/dev/null || true
    pkill -f "firewallfalcon-bandwidth" &>/dev/null || true

    if [[ -e "$BANDWIDTH_SERVICE" || -e "$BANDWIDTH_SCRIPT" || -e "$LEGACY_BANDWIDTH_DIR" ]]; then
        rm -f "$BANDWIDTH_SERVICE" "$BANDWIDTH_SCRIPT" 2>/dev/null
        rm -rf "$LEGACY_BANDWIDTH_DIR" 2>/dev/null
        needs_reload=true
    fi

    if $needs_reload; then
        systemctl daemon-reload &>/dev/null || true
    fi
}

setup_trial_cleanup_script() {
    cat > "$TRIAL_CLEANUP_SCRIPT" << 'TREOF'
#!/bin/bash
# FirewallFalcon Trial Account Auto-Cleanup
# Usage: firewallfalcon-trial-cleanup.sh <username>
DB_FILE="/etc/firewallfalcon/users.db"
BW_DIR="/etc/firewallfalcon/bandwidth"

username="$1"
if [[ -z "$username" ]]; then exit 1; fi

db_line=$(grep "^${username}:" "$DB_FILE" 2>/dev/null | head -n 1)
if [[ -z "$db_line" ]]; then exit 0; fi

IFS=: read -r _ _ _ _ _ trial_marker _rest <<< "$db_line"
if [[ "$trial_marker" != "trial" ]]; then
    exit 0
fi

# Kill active sessions
killall -u "$username" -9 &>/dev/null
pkill -9 -u "$username" &>/dev/null
sleep 1

# Delete system user
userdel -rf "$username" &>/dev/null

# Remove from DB
sed -i "/^${username}:/d" "$DB_FILE"

# Remove bandwidth tracking
rm -f "$BW_DIR/${username}.usage"
rm -rf "$BW_DIR/pidtrack/${username}"
TREOF
    chmod +x "$TRIAL_CLEANUP_SCRIPT"
}

disable_dynamic_ssh_banner_system() {
    rm -f "/etc/firewallfalcon/banners_enabled" "$SSHD_FF_CONFIG" /usr/local/bin/firewallfalcon-login-info.sh 2>/dev/null
    rm -rf "/etc/firewallfalcon/banners" 2>/dev/null
    invalidate_banner_cache
}

disable_static_ssh_banner_in_sshd_config() {
    sed -i.bak -E "s|^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$|# Banner $SSH_BANNER_FILE|" /etc/ssh/sshd_config 2>/dev/null
}

is_static_ssh_banner_enabled() {
    grep -q -E "^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$" /etc/ssh/sshd_config 2>/dev/null && [ -f "$SSH_BANNER_FILE" ]
}

is_dynamic_ssh_banner_enabled() {
    [[ -f "/etc/firewallfalcon/banners_enabled" && -f "$SSHD_FF_CONFIG" ]]
}

get_ssh_banner_mode() {
    if is_dynamic_ssh_banner_enabled; then
        echo "dynamic"
    elif is_static_ssh_banner_enabled; then
        echo "static"
    else
        echo "disabled"
    fi
}

refresh_dynamic_banner_routing_if_enabled() {
    if is_dynamic_ssh_banner_enabled; then
        update_ssh_banners_config
    fi
}

update_ssh_banners_config() {
    local tmp_conf

    if [[ ! -f "/etc/firewallfalcon/banners_enabled" ]]; then
        if [[ -f "$SSHD_FF_CONFIG" ]]; then
            rm -f "$SSHD_FF_CONFIG" 2>/dev/null
            systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
        fi
        return
    fi

    ensure_firewallfalcon_dirs
    tmp_conf="/tmp/ff_banners_new.conf"
    echo "# FirewallFalcon - Banners SSH dinámicos por usuario" > "$tmp_conf"

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r u _rest; do
            [[ -z "$u" || "$u" == \#* ]] && continue
            echo "Match User $u" >> "$tmp_conf"
            echo "    Banner /etc/firewallfalcon/banners/${u}.txt" >> "$tmp_conf"
        done < "$DB_FILE"
    fi

    if ! cmp -s "$tmp_conf" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp_conf" "$SSHD_FF_CONFIG"
        if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        fi
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    else
        rm -f "$tmp_conf"
    fi
}

setup_ssh_login_info() {
    ensure_firewallfalcon_dirs || return 1
    if ! touch "/etc/firewallfalcon/banners_enabled"; then
        echo -e "${C_RED}❌ No se pudieron habilitar los banners SSH dinámicos.${C_RESET}"
        return 1
    fi
    disable_static_ssh_banner_in_sshd_config
    update_ssh_banners_config
    return 0
}


generate_dns_record() {
    echo -e "\n${C_BLUE}⚙️ Generando un dominio aleatorio...${C_RESET}"
    if ! command -v jq &> /dev/null; then
        echo -e "${C_YELLOW}⚠️ jq no encontrado, intentando instalar...${C_RESET}"
        ff_pkg_install jq >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ No se pudo instalar jq. No es posible gestionar los registros DNS.${C_RESET}"
            return 1
        }
    fi
    local SERVER_IPV4
    SERVER_IPV4=$(curl -s -4 icanhazip.com)
    if ! _is_valid_ipv4 "$SERVER_IPV4"; then
        echo -e "\n${C_RED}❌ Error: No se pudo obtener una dirección IPv4 pública válida de icanhazip.com.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Por favor, comprueba la conexión de red y la configuración del servidor DNS de tu servidor.${C_RESET}"
        echo -e "   Output received: '$SERVER_IPV4'"
        return 1
    fi

    local SERVER_IPV6
    SERVER_IPV6=$(curl -s -6 icanhazip.com --max-time 5)

    local RANDOM_SUBDOMAIN="vps-$(tr -dc a-z0-9 < /dev/urandom | head -c 8)"
    local FULL_DOMAIN="$RANDOM_SUBDOMAIN.$DESEC_DOMAIN"
    local HAS_IPV6="false"

    local API_DATA
    API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$RANDOM_SUBDOMAIN" "$SERVER_IPV4")

    if [[ -n "$SERVER_IPV6" ]]; then
        local aaaa_record
        aaaa_record=$(printf ',{"subname": "%s", "type": "AAAA", "ttl": 3600, "records": ["%s"]}' "$RANDOM_SUBDOMAIN" "$SERVER_IPV6")
        API_DATA="${API_DATA%?}${aaaa_record}]"
        HAS_IPV6="true"
    fi

    local CREATE_RESPONSE
    CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" \
        --data "$API_DATA")
    
    local HTTP_CODE=${CREATE_RESPONSE: -3}
    local RESPONSE_BODY=${CREATE_RESPONSE:0:${#CREATE_RESPONSE}-3}

    if [[ "$HTTP_CODE" -ne 201 ]]; then
        echo -e "${C_RED}❌ No se pudieron crear los registros DNS. La API devolvió un código HTTP $HTTP_CODE.${C_RESET}"
        if ! echo "$RESPONSE_BODY" | jq . > /dev/null 2>&1; then
            echo "Raw Response: $RESPONSE_BODY"
        else
            echo "Response: $RESPONSE_BODY" | jq
        fi
        return 1
    fi
    
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$RANDOM_SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
HAS_IPV6="$HAS_IPV6"
EOF
    echo -e "\n${C_GREEN}✅ Dominio creado correctamente: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
}

delete_dns_record() {
    if [ ! -f "$DNS_INFO_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No hay ningún dominio que eliminar.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}🗑️ Eliminación de registros DNS...${C_RESET}"
    source "$DNS_INFO_FILE"
    if [[ -z "$SUBDOMAIN" ]]; then
        echo -e "${C_RED}❌ No se pudieron leer los detalles del registro desde el archivo de configuración. Se omite la eliminación.${C_RESET}"
        return
    fi

    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" \
         -H "Authorization: Token $DESEC_TOKEN" > /dev/null

    if [[ "$HAS_IPV6" == "true" ]]; then
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/AAAA/" \
             -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    fi

    echo -e "\n${C_GREEN}✅ Dominio eliminado: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
    rm -f "$DNS_INFO_FILE"
}

dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Gestión de dominios DNS ---${C_RESET}"
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "\nℹ️ Ya existe un dominio para este servidor:"
        echo -e "  - ${C_CYAN}Domain:${C_RESET} ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        echo
        read -p "👉 ¿Quieres ELIMINAR este dominio? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            delete_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Acción cancelada.${C_RESET}"
        fi
    else
        echo -e "\nℹ️ Todavía no se ha generado ningún dominio para este servidor."
        echo
        read -p "👉 ¿Quieres generar un nuevo dominio aleatorio ahora? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            generate_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Acción cancelada.${C_RESET}"
        fi
    fi
}

_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then
        echo -e "${C_YELLOW}ℹ️ No se encontraron usuarios en la base de datos.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    local -A all_user_lookup=()
    local username
    for username in "${all_users[@]}"; do
        all_user_lookup["$username"]=1
    done
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Introduce un término de búsqueda (o pulsa Enter para listar todos): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No se encontraron usuarios que coincidan con tus criterios.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    echo -e "\nPor favor selecciona un usuario:\n"
    for i in "${!users[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"
    done
    echo -e "\n  ${C_RED} [ 0]${C_RESET} ↩️ Cancelar"
    echo -e "${C_CYAN}💡 Tip: también puedes escribir el nombre de usuario exacto directamente.${C_RESET}"
    echo
    local choice
    while true; do
        if ! read -r -p "👉 Introduce el número o el nombre de usuario exacto: " choice; then
            echo
            SELECTED_USER=""
            return
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#users[@]}" ]; then
            if [ "$choice" -eq 0 ]; then
                SELECTED_USER=""; return
            else
                SELECTED_USER="${users[$((choice-1))]}"; return
            fi
        elif [[ -n "${all_user_lookup[$choice]+x}" ]]; then
            SELECTED_USER="$choice"; return
        else
            echo -e "${C_RED}❌ Selección no válida. Por favor, inténtelo de nuevo.${C_RESET}"
        fi
    done
}

_select_multi_user_interface() {
    local title="$1"
    local include_orphan_users="${2:-false}"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    SELECTED_USERS=()
    local -a all_users=()
    local -a orphan_users=()
    local -A all_user_lookup=()
    local -A orphan_user_lookup=()
    local username

    if [[ -s $DB_FILE ]]; then
        mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    fi

    if [[ "$include_orphan_users" == "true" ]]; then
        mapfile -t orphan_users < <(get_firewallfalcon_orphan_users)
        for username in "${orphan_users[@]}"; do
            orphan_user_lookup["$username"]=1
            if ! printf "%s\n" "${all_users[@]}" | grep -Fxq "$username"; then
                all_users+=("$username")
            fi
        done
        if [[ ${#all_users[@]} -gt 0 ]]; then
            mapfile -t all_users < <(printf "%s\n" "${all_users[@]}" | sort)
        fi
    fi

    if [[ ${#all_users[@]} -eq 0 ]]; then
        echo -e "${C_YELLOW}ℹ️ No se encontraron usuarios en la base de datos del gestor.${C_RESET}"
        if [[ "$include_orphan_users" == "true" ]]; then
            echo -e "${C_DIM}Tampoco se encontraron usuarios del sistema FirewallFalcon huérfanos.${C_RESET}"
        fi
        SELECTED_USERS=("NO_USERS"); return
    fi

    for username in "${all_users[@]}"; do
        all_user_lookup["$username"]=1
    done
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Introduce un término de búsqueda (o pulsa Enter para listar todos): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No se encontraron usuarios que coincidan con tus criterios.${C_RESET}"
        SELECTED_USERS=("NO_USERS"); return
    fi
    echo -e "\nPor favor, seleccione usuarios:\n"
    for i in "${!users[@]}"; do
        local display_user="${users[$i]}"
        if [[ "$include_orphan_users" == "true" && -n "${orphan_user_lookup[${users[$i]}]+x}" ]]; then
            display_user="${display_user} ${C_DIM}(system-only)${C_RESET}"
        fi
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "$display_user"
    done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Selecciona TODOS los usuarios listados"
    echo -e "  ${C_RED}  [0]${C_RESET} ↩️ Cancelar y volver al menú principal"
    echo -e "\n${C_CYAN}💡 Puedes seleccionar varios indicando números, un rango o el nombre de usuario exacto.${C_RESET}"
    echo -e "${C_CYAN}   Ejemplo: '1 2 3' o '1,3' oo  '1-4' o 'tewianix fixxed'${C_RESET}"
    if [[ "$include_orphan_users" == "true" ]]; then
        echo -e "${C_CYAN}   Los usuarios marcados como '(system-only)' son cuentas antiguas que aún se encuentran en el VPS pero que no aparecen en users.db${C_RESET}"
    fi
    echo
    local choice
    while true; do
        if ! read -r -p "👉 Introduce números de usuario o nombres de usuario: " choice; then
            echo
            SELECTED_USERS=()
            return
        fi
        choice=${choice//,/ } # Replace commas with spaces
        
        if [[ -z "$choice" ]]; then
            echo -e "${C_RED}❌ Selección no válida. Por favor, inténtelo de nuevo.${C_RESET}"
            continue
        fi

        if [[ "$choice" == "0" ]]; then
            SELECTED_USERS=(); return
        fi
        
        if [[ "${choice,,}" == "all" ]]; then
            SELECTED_USERS=("${users[@]}")
            return
        fi
        
        local valid=true
        local selected_indices=()
        local selected_names=()
        for token in $choice; do
            if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
                local start=${token%-*}
                local end=${token#*-}
                if [ "$start" -le "$end" ]; then
                    for (( idx=start; idx<=end; idx++ )); do
                        if [ "$idx" -ge 1 ] && [ "$idx" -le "${#users[@]}" ]; then
                            selected_indices+=($idx)
                        else
                            valid=false; break
                        fi
                    done
                else
                    valid=false; break
                fi
            elif [[ "$token" =~ ^[0-9]+$ ]]; then
                if [ "$token" -ge 1 ] && [ "$token" -le "${#users[@]}" ]; then
                    selected_indices+=($token)
                elif [[ -n "${all_user_lookup[$token]+x}" ]]; then
                    selected_names+=("$token")
                else
                    valid=false; break
                fi
            elif [[ -n "${all_user_lookup[$token]+x}" ]]; then
                selected_names+=("$token")
            else
                valid=false; break
            fi
        done
        
        if [[ "$valid" == true && ( ${#selected_indices[@]} -gt 0 || ${#selected_names[@]} -gt 0 ) ]]; then
            mapfile -t unique_indices < <(printf "%s\n" "${selected_indices[@]}" | sort -u -n)
            for idx in "${unique_indices[@]}"; do
                SELECTED_USERS+=("${users[$((idx-1))]}")
            done
            if (( ${#selected_names[@]} > 0 )); then
                mapfile -t unique_names < <(printf "%s\n" "${selected_names[@]}" | sort -u)
                for username in "${unique_names[@]}"; do
                    if [[ -n "$username" ]] && ! printf "%s\n" "${SELECTED_USERS[@]}" | grep -Fxq "$username"; then
                        SELECTED_USERS+=("$username")
                    fi
                done
            fi
            return
        else
            echo -e "${C_RED}❌ Selección no válida. Por favor, revisa tus números o nombres de usuario..${C_RESET}"
            SELECTED_USERS=()
            selected_indices=()
            selected_names=()
        fi
    done
}

get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}No encontrado${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then echo -e "${C_YELLOW}🔒 Bloqueado${C_RESET}"; return; fi
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts ]]; then echo -e "${C_RED}🗓️ Expirado${C_RESET}"; return; fi
    echo -e "${C_GREEN}🟢 Activo${C_RESET}"
}

create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Crear nuevo usuario SSH ---${C_RESET}"
    read -p "👉 Introduce el nombre de usuario (o '0' para cancelar): " username
    local adopt_existing=false
    if [[ "$username" == "0" ]]; then
        echo -e "\n${C_YELLOW}❌ Creación de usuario cancelada.${C_RESET}"
        return
    fi
    if [[ -z "$username" ]]; then
        echo -e "\n${C_RED}❌ Error: El nombre de usuario no puede estar vacío.${C_RESET}"
        return
    fi
    if db_has_user "$username"; then
        echo -e "\n${C_RED}❌ Error: El usuario '$username' ya existe en FirewallFalcon.${C_RESET}"
        return
    fi
    if id "$username" &>/dev/null; then
        if is_firewallfalcon_orphan_user "$username"; then
            echo -e "\n${C_YELLOW}⚠️ El usuario '$username' ya existe en el sistema, pero no aparece en users.db${C_RESET}"
            echo -e "${C_DIM}Esto suele ocurrir después de desinstalar el script sin eliminar los usuarios SSH.${C_RESET}"
            read -p "👉 ¿Quieres tomar el control de este usuario existente y gestionarlo con FirewallFalcon? (y/n): " adopt_confirm
            if [[ "$adopt_confirm" == "y" || "$adopt_confirm" == "Y" ]]; then
                adopt_existing=true
            else
                echo -e "\n${C_YELLOW}❌ Creación de usuario cancelada.${C_RESET}"
                return
            fi
        else
            echo -e "\n${C_RED}❌ Error: El usuario del sistema '$username' ya existe y no parece una cuenta SSH de FirewallFalcon.${C_RESET}"
            return
        fi
    fi
    local password=""
    while true; do
        read -p "🔑 Introduce una contraseña (o Enter para una generada automáticamente): " password
        if [[ -z "$password" ]]; then
            password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
            echo -e "${C_GREEN}🔑 Contraseña generada automáticamente: ${C_YELLOW}$password${C_RESET}"
            break
        else
            break
        fi
    done
    read -p "🗓️ Introduce la duración de la cuenta (en días) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    read -p "📶 Introduce el límite de conexiones simultáneas [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    read -p "📦 Introduce el límite de ancho de banda en GB (0 = ilimitado) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    read -p "📦 Introduce el límite DIARIO de ancho de banda en GB (0 = ilimitado) [0]: " daily_bandwidth_gb
    daily_bandwidth_gb=${daily_bandwidth_gb:-0}
    if ! [[ "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    ensure_firewallfalcon_system_group
    if [[ "$adopt_existing" == "true" ]]; then
        usermod -s /usr/sbin/nologin "$username" &>/dev/null
    else
        useradd -m -s /usr/sbin/nologin "$username"
    fi
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd; chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:$daily_bandwidth_gb:trial" >> "$DB_FILE"
    
    local bw_display="Ilimitado"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    local daily_bw_display="Ilimitado"
    if [[ "$daily_bandwidth_gb" != "0" ]]; then daily_bw_display="${daily_bandwidth_gb} GB/Día"; fi
    
    clear; show_banner
    if [[ "$adopt_existing" == "true" ]]; then
        echo -e "${C_GREEN}✅ ¡El usuario del sistema existente '$username' se ha importado a FirewallFalcon!${C_RESET}\n"
    else
        echo -e "${C_GREEN}✅ Usuario '$username' creado correctamente${C_RESET}\n"
    fi
    echo -e "  - 👤 Usuario:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Contraseña:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - 🗓️ Expira el:        ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  - 📶 Límite de conexiones:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Ancho de banda total:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "  - 📦 Ancho de banda diario:   ${C_YELLOW}$daily_bw_display${C_RESET}"
    echo -e "    ${C_DIM}(El servicio de supervisión activa hará cumplir estos límites.)${C_RESET}"

    # Auto-ask for config generation
    echo
    read -p "👉 ¿Quieres generar una configuración de conexión para este usuario? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Eliminar usuarios de FirewallFalcon ---" "true"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_RED}⚠️ Has seleccionado ${#SELECTED_USERS[@]} usuario(s) a eliminar: ${C_YELLOW}${SELECTED_USERS[*]}${C_RESET}"
    read -p "👉 ¿Estás seguro de que quieres eliminarlos de forma PERMANENTE? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Eliminación cancelada.${C_RESET}"; return; fi
    
    echo -e "\n${C_BLUE}🗑️ Eliminar los usuarios seleccionados...${C_RESET}"
    delete_firewallfalcon_user_accounts "${SELECTED_USERS[@]}"
}

edit_user() {
    _select_user_interface "--- ✏️ Editar un usuario ---"
    local username=$SELECTED_USER
    if [[ "$username" == "NO_USERS" ]] || [[ -z "$username" ]]; then return; fi
    while true; do
        clear; show_banner; echo -e "${C_BOLD}${C_PURPLE}--- Editar usuario: ${C_YELLOW}$username${C_PURPLE} ---${C_RESET}"
        
        # Show current user details
        local current_line; current_line=$(grep "^$username:" "$DB_FILE")
        local cur_pass cur_expiry cur_limit cur_bw cur_daily_bw
        IFS=: read -r _ cur_pass cur_expiry cur_limit cur_bw cur_daily_bw _ <<< "$current_line"
        [[ -z "$cur_bw" ]] && cur_bw="0"
        [[ ! "$cur_daily_bw" =~ ^[0-9]+\.?[0-9]*$ ]] && cur_daily_bw="0"
        
        local cur_bw_display="Ilimitado"; [[ "$cur_bw" != "0" ]] && cur_bw_display="${cur_bw} GB"
        local cur_daily_bw_display="Ilimitado"; [[ "$cur_daily_bw" != "0" ]] && cur_daily_bw_display="${cur_daily_bw} GB/Día"
        
        # Show bandwidth usage
        local bw_used_display="N/A"
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
            local used_bytes=0; read -r used_bytes < "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null || used_bytes=0
            if [[ -n "$used_bytes" && "$used_bytes" != "0" ]]; then
                bw_used_display=$(awk "BEGIN {printf \"%.2f GB\", $used_bytes / 1073741824}")
            else
                bw_used_display="0.00 GB"
            fi
        fi
        
        local daily_bw_used_display="N/A"
        if [[ -f "$BANDWIDTH_DIR/${username}.daily_usage" ]]; then
            local d_used_bytes=0; read -r d_used_bytes < "$BANDWIDTH_DIR/${username}.daily_usage" 2>/dev/null || d_used_bytes=0
            if [[ -n "$d_used_bytes" && "$d_used_bytes" != "0" ]]; then
                daily_bw_used_display=$(awk "BEGIN {printf \"%.2f GB\", $d_used_bytes / 1073741824}")
            else
                daily_bw_used_display="0.00 GB"
            fi
        fi
        
        echo -e "\n  ${C_DIM}Current: Pass=${C_YELLOW}$cur_pass${C_RESET}${C_DIM} Exp=${C_YELLOW}$cur_expiry${C_RESET}${C_DIM} Conn=${C_YELLOW}$cur_limit${C_RESET}${C_DIM} BW=${C_YELLOW}$cur_bw_display${C_RESET}${C_DIM} Used=${C_CYAN}$bw_used_display${C_RESET}${C_DIM} Daily BW=${C_YELLOW}$cur_daily_bw_display${C_RESET}${C_DIM} Daily Used=${C_CYAN}$daily_bw_used_display${C_RESET}"
        echo -e "\nSelecciona un detalle para editar:\n"
        printf "  ${C_GREEN}[ 1]${C_RESET} %-35s\n" "🔑 Cambiar la contraseña"
        printf "  ${C_GREEN}[ 2]${C_RESET} %-35s\n" "🗓️ Cambiar fecha de expiración"
        printf "  ${C_GREEN}[ 3]${C_RESET} %-35s\n" "📶 Cambiar límite de conexiones"
        printf "  ${C_GREEN}[ 4]${C_RESET} %-35s\n" "📦 Modificar el límite de ancho de banda total"
        printf "  ${C_GREEN}[ 5]${C_RESET} %-35s\n" "📦 Cambiar el límite diario de ancho de banda"
        printf "  ${C_GREEN}[ 6]${C_RESET} %-35s\n" "🔄 Restablecer contadores de ancho de banda"
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ✅ Finalizar edición"
        echo
        if ! read -r -p "👉 Introduce tu elección: " edit_choice; then
            echo
            return
        fi
        case $edit_choice in
            1)
               local new_pass=""
               read -p "Introduce una nueva contraseña (o Enter para generar una automáticamente): " new_pass
               if [[ -z "$new_pass" ]]; then
                   new_pass=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
                   echo -e "${C_GREEN}🔑 Generado automáticamente: ${C_YELLOW}$new_pass${C_RESET}"
               fi
               echo "$username:$new_pass" | chpasswd
               sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw:$cur_daily_bw/" "$DB_FILE"
               echo -e "\n${C_GREEN}✅ La contraseña para '$username' cambió a: ${C_YELLOW}$new_pass${C_RESET}"
               ;;
            2) read -p "Introduce la nueva duración (en días a partir de hoy): " days
               if [[ "$days" =~ ^[0-9]+$ ]]; then
                   local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d); chage -E "$new_expire_date" "$username"
                   sed -i "s/^$username:.*/$username:$cur_pass:$new_expire_date:$cur_limit:$cur_bw:$cur_daily_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Expiración para '$username' establecido en ${C_YELLOW}$new_expire_date${C_RESET}."
               else echo -e "\n${C_RED}❌ Número de días no válido.${C_RESET}"; fi ;;
            3) read -p "Introduce el nuevo límite de conexiones simultáneas: " new_limit
               if [[ "$new_limit" =~ ^[0-9]+$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$new_limit:$cur_bw:$cur_daily_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Límite de conexiones para '$username' establecido en ${C_YELLOW}$new_limit${C_RESET}."
               else echo -e "\n${C_RED}❌ Límite no válido.${C_RESET}"; fi ;;
            4) read -p "Introduce el nuevo límite de ancho de banda TOTAL en GB (0 = ilimitado): " new_bw
               if [[ "$new_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$new_bw:$cur_daily_bw/" "$DB_FILE"
                   local bw_msg="Ilimitado"; [[ "$new_bw" != "0" ]] && bw_msg="${new_bw} GB"
                   echo -e "\n${C_GREEN}✅ Límite de ancho de banda total para '$username' ${C_YELLOW}$bw_msg${C_RESET}."
                   # Unlock user if they were locked due to bandwidth
                   if [[ "$new_bw" == "0" ]] || [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
                       local used_bytes; used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null || echo 0)
                       local new_quota_bytes; new_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $new_bw * 1073741824}")
                       if [[ "$new_bw" == "0" ]] || [[ "$used_bytes" -lt "$new_quota_bytes" ]]; then
                           usermod -U "$username" &>/dev/null
                       fi
                   fi
               else echo -e "\n${C_RED}❌ Valor de ancho de banda no válido.${C_RESET}"; fi ;;
            5) read -p "Introduce el nuevo límite diario de ancho de banda en GB (0 = ilimitado): " new_daily_bw
               if [[ "$new_daily_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$cur_bw:$new_daily_bw/" "$DB_FILE"
                   local daily_bw_msg="Ilimitado"; [[ "$new_daily_bw" != "0" ]] && daily_bw_msg="${new_daily_bw} GB/Día"
                   echo -e "\n${C_GREEN}✅ Límite de ancho de banda diario para '$username' establecido en ${C_YELLOW}$daily_bw_msg${C_RESET}."
                   # Unlock user if they were locked due to daily bandwidth
                   if [[ "$new_daily_bw" == "0" ]] || [[ -f "$BANDWIDTH_DIR/${username}.daily_usage" ]]; then
                       local d_used_bytes; d_used_bytes=$(cat "$BANDWIDTH_DIR/${username}.daily_usage" 2>/dev/null || echo 0)
                       local new_d_quota_bytes; new_d_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $new_daily_bw * 1073741824}")
                       if [[ "$new_daily_bw" == "0" ]] || [[ "$d_used_bytes" -lt "$new_d_quota_bytes" ]]; then
                           usermod -U "$username" &>/dev/null
                           rm -f "$BANDWIDTH_DIR/${username}.daily_locked"
                       fi
                   fi
               else echo -e "\n${C_RED}❌ Valor de ancho de banda no válido.${C_RESET}"; fi ;;
            6)
               echo "0" > "$BANDWIDTH_DIR/${username}.usage"
               echo "0" > "$BANDWIDTH_DIR/${username}.daily_usage"
               rm -f "$BANDWIDTH_DIR/${username}.daily_locked"
               # Unlock user if they were locked due to bandwidth
               usermod -U "$username" &>/dev/null
               echo -e "\n${C_GREEN}✅ Los contadores de ancho de banda para '$username' se han restablecido a 0.${C_RESET}"
               ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}" ;;
        esac
        echo -e "\nPulsa ${C_YELLOW}[Enter]${C_RESET} para continuar editando..." && read -r || return
    done
}

lock_user() {
    _select_multi_user_interface "--- 🔒 Bloquear usuarios (desde DB) ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔒 Bloqueo de usuarios seleccionados...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ El usuario '${C_YELLOW}$u${C_RESET}' no existe en este sistema."
             continue
        fi
        
        usermod -L "$u"
        if [ $? -eq 0 ]; then
            killall -u "$u" -9 &>/dev/null
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} sesiones bloqueadas y activas finalizadas."
        else
            echo -e " ❌ No se pudo bloquear ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Desbloquear usuarios (desde DB) ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔓 Desbloqueo de usuarios seleccionados...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ El usuario '${C_YELLOW}$u${C_RESET}' no existe en este sistema."
             continue
        fi
        
        usermod -U "$u"
        if [ $? -eq 0 ]; then
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} desbloqueado."
        else
            echo -e " ❌ No se pudo desbloquear ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

list_users() {
    clear; show_banner
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_YELLOW}ℹ️ Actualmente no se está gestionando ningún usuario..${C_RESET}"
        return
    fi
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Gestionar usuarios ---${C_RESET}"
    echo -e "${C_YELLOW}---------------------------------------------------------------------------------------------------${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-12s | %-10s | %-25s | %-20s${C_RESET}\n" "USUARIO" "EXPIRACIÓn" "SESIONES" "ANC. BANDA" "ESTADO"
    echo -e "${C_YELLOW}---------------------------------------------------------------------------------------------------${C_RESET}"

    local current_ts
    printf -v current_ts '%(%s)T' -1
    local -A system_user_lookup=()
    local -A locked_user_lookup=()

    while IFS=: read -r system_user _rest; do
        [[ -n "$system_user" ]] && system_user_lookup["$system_user"]=1
    done < /etc/passwd

    if [[ -r /etc/shadow ]]; then
        while IFS=: read -r shadow_user shadow_hash _rest; do
            [[ -n "$shadow_user" && "${shadow_hash:0:1}" == "!" ]] && locked_user_lookup["$shadow_user"]=1
        done < /etc/shadow
    else
        while read -r passwd_user _ passwd_status _rest; do
            [[ -z "$passwd_user" ]] && continue
            [[ "$passwd_status" == "L" ]] && locked_user_lookup["$passwd_user"]=1
        done < <(passwd -Sa 2>/dev/null)
    fi
    refresh_ssh_session_cache

    while IFS=: read -r user pass expiry limit bandwidth_gb daily_bandwidth_gb _extra; do
        local online_count="${SSH_SESSION_COUNTS[$user]:-0}"
        local connection_string="$online_count / $limit"
        local plain_status="Active"
        local status="${C_GREEN}🟢 Activo${C_RESET}"
        local quota_exceeded=false

        [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
        [[ ! "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]] && daily_bandwidth_gb="0"
        
        local bw_string="Ilimitado"
        local total_str=""
        local daily_str=""
        
        if [[ "$bandwidth_gb" != "0" ]]; then
            local used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.usage" ]]; then
                read -r used_bytes < "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null || used_bytes=0
                [[ "$used_bytes" =~ ^[0-9]+$ ]] || used_bytes=0
            fi
            local used_gb
            used_gb=$(awk "BEGIN {printf \"%.1f\", $used_bytes / 1073741824}")
            total_str="${used_gb}/${bandwidth_gb}G"
            local quota_bytes
            quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( used_bytes >= quota_bytes )); then
                quota_exceeded=true
            fi
        fi
        
        if [[ "$daily_bandwidth_gb" != "0" ]]; then
            local d_used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.daily_usage" ]]; then
                read -r d_used_bytes < "$BANDWIDTH_DIR/${user}.daily_usage" 2>/dev/null || d_used_bytes=0
                [[ "$d_used_bytes" =~ ^[0-9]+$ ]] || d_used_bytes=0
            fi
            local d_used_gb
            d_used_gb=$(awk "BEGIN {printf \"%.1f\", $d_used_bytes / 1073741824}")
            daily_str="${d_used_gb}/${daily_bandwidth_gb}G/d"
            local d_quota_bytes
            d_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $daily_bandwidth_gb * 1073741824}")
            if [[ "$d_quota_bytes" =~ ^[0-9]+$ ]] && (( d_used_bytes >= d_quota_bytes )); then
                quota_exceeded=true
            fi
        fi
        
        if [[ -n "$total_str" && -n "$daily_str" ]]; then
            bw_string="$total_str | $daily_str"
        elif [[ -n "$total_str" ]]; then
            bw_string="$total_str"
        elif [[ -n "$daily_str" ]]; then
            bw_string="$daily_str"
        fi

        if [[ -z "${system_user_lookup[$user]+x}" ]]; then
            plain_status="No encontrado"
            status="${C_RED}No encontrado${C_RESET}"
        elif [[ -n "$expiry" && "$expiry" != "Nunca" ]]; then
            local expiry_ts
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                plain_status="Expirado"
                status="${C_RED}🗓️ Expirado${C_RESET}"
            fi
        fi

        if [[ "$plain_status" == "Active" && "$quota_exceeded" == true ]]; then
            if [[ -n "${locked_user_lookup[$user]+x}" ]]; then
                plain_status="BW Locked"
                status="${C_RED}🔒 BW bloqueado${C_RESET}"
            else
                plain_status="Quota Exceeded"
                status="${C_RED}📦 Cuota excedida${C_RESET}"
            fi
        elif [[ "$plain_status" == "Active" && -n "${locked_user_lookup[$user]+x}" ]]; then
            plain_status="Locked"
            status="${C_YELLOW}🔒 Bloqueado${C_RESET}"
        fi

        local line_color="$C_WHITE"
        case "$plain_status" in
            "Active") line_color="$C_GREEN" ;;
            "Locked") line_color="$C_YELLOW" ;;
            "Expired") line_color="$C_RED" ;;
            "BW Locked") line_color="$C_RED" ;;
            "Quota Exceeded") line_color="$C_RED" ;;
            "Not Found") line_color="$C_DIM" ;;
        esac

        printf "${line_color}%-18s ${C_RESET}| ${C_YELLOW}%-12s ${C_RESET}| ${C_CYAN}%-10s ${C_RESET}| ${C_ORANGE}%-25s ${C_RESET}| %-20s\n" "$user" "$expiry" "$connection_string" "$bw_string" "$status"
    done < <(sort "$DB_FILE")
    echo -e "${C_CYAN}=========================================================================================${C_RESET}\n"
}

renew_user() {
    _select_multi_user_interface "--- 🔄 Renovar usuarios ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    read -p "👉 Ingrese la cantidad de días para extender la(s) cuenta(s): " days; if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    local new_expire_date; new_expire_date=$(date -d "+$days Días" +%Y-%m-%d)
    
    echo -e "\n${C_BLUE}🔄 Renovar a los usuarios seleccionados por $days días...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$new_expire_date" "$u"
        local line pass _expiry limit bw
        line=$(grep "^$u:" "$DB_FILE")
        IFS=: read -r _ pass _expiry limit bw _ <<< "$line"
        [[ -z "$bw" ]] && bw="0"
        sed -i "s/^$u:.*/$u:$pass:$new_expire_date:$limit:$bw/" "$DB_FILE"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} renovado hasta ${C_GREEN}${new_expire_date}${C_RESET}."
    done
}

cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Limpiar usuarios Expirados ---${C_RESET}"
    
    local expired_users=()
    local current_ts
    current_ts=$(date +%s)

    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_GREEN}✅ La base de datos de usuarios está vacía. No se han encontrado usuarios expirados..${C_RESET}"
        return
    fi
    
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local expiry_ts
        expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        
        if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then
            expired_users+=("$user")
        fi
    done < "$DB_FILE"

    if [ ${#expired_users[@]} -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ No se han encontrado usuarios expirados.${C_RESET}"
        return
    fi

    echo -e "\nLos siguientes usuarios han expirado.: ${C_RED}${expired_users[*]}${C_RESET}"
    read -p "👉 ¿Quieres borrarlos todos? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo -e "\n${C_BLUE}🗑️ Eliminación de usuarios caducados...${C_RESET}"
        delete_firewallfalcon_user_accounts "${expired_users[@]}"
        echo -e "\n${C_GREEN}✅ Los usuarios caducados han sido limpiados.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Limpieza cancelada.${C_RESET}"
    fi
}


backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Realizar copia de seguridad de los datos del usuario ---${C_RESET}"
    read -p "👉 Introduce la ruta del archivo de copia de seguridad [/root/firewallfalcon_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/firewallfalcon_users.tar.gz}
    if [ ! -d "$DB_DIR" ] || [ ! -s "$DB_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No se encontraron usuarios para realizar una copia de seguridad.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}⚙️ Realizar una copia de seguridad de la base de datos de usuarios y la configuración en ${C_YELLOW}$backup_path${C_RESET}..."
    tar -czf "$backup_path" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")"
    if [ $? -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ ÉXITO: ​​Copia de seguridad de datos de usuario creada en ${C_YELLOW}$backup_path${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: La copia de seguridad ha fallado.${C_RESET}"
    fi
}

restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restaurar datos de usuario ---${C_RESET}"
    read -p "👉 Introduce la ruta completa al archivo de copia de seguridad [/root/firewallfalcon_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/firewallfalcon_users.tar.gz}
    if [ ! -f "$backup_path" ]; then
        echo -e "\n${C_RED}❌ ERROR: No se encontró el archivo de copia de seguridad en '$backup_path'.${C_RESET}"
        return
    fi
    echo -e "\n${C_RED}${C_BOLD}⚠️ ADVERTENCIA:${C_RESET} Esto sobrescribirá todos los usuarios y la configuración actuales."
    echo -e "Restaurará las cuentas de usuario, las contraseñas, los límites y las fechas expiración a partir del archivo de copia de seguridad."
    read -p "👉 ¿Estás seguro de que quieres continuar? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Restauración cancelada.${C_RESET}"; return; fi
    local temp_dir
    temp_dir=$(mktemp -d)
    echo -e "\n${C_BLUE}⚙️ Extrayendo el archivo de copia de seguridad a una ubicación temporal...${C_RESET}"
    tar -xzf "$backup_path" -C "$temp_dir"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ ERROR: No se pudo extraer el archivo de copia de seguridad. Abortando.${C_RESET}"
        rm -rf "$temp_dir"
        return
    fi
    local restored_db_file="$temp_dir/firewallfalcon/users.db"
    if [ ! -f "$restored_db_file" ]; then
        echo -e "\n${C_RED}❌ ERROR: no se encontró users.db en la copia de seguridad. No es posible restaurar las cuentas de usuario.${C_RESET}"
        rm -rf "$temp_dir"
        return
    fi
    echo -e "${C_BLUE}⚙️ Sobrescribiendo la base de datos de usuarios actual...${C_RESET}"
    mkdir -p "$DB_DIR"
    cp "$restored_db_file" "$DB_FILE"
    if [ -d "$temp_dir/firewallfalcon/ssl" ]; then
        cp -r "$temp_dir/firewallfalcon/ssl" "$DB_DIR/"
    fi
    if [ -d "$temp_dir/firewallfalcon/dnstt" ]; then
        cp -r "$temp_dir/firewallfalcon/dnstt" "$DB_DIR/"
    fi
    if [ -f "$temp_dir/firewallfalcon/dns_info.conf" ]; then
        cp "$temp_dir/firewallfalcon/dns_info.conf" "$DB_DIR/"
    fi
    if [ -f "$temp_dir/firewallfalcon/dnstt_info.conf" ]; then
        cp "$temp_dir/firewallfalcon/dnstt_info.conf" "$DB_DIR/"
    fi
    if [ -f "$temp_dir/firewallfalcon/falconproxy_config.conf" ]; then
        cp "$temp_dir/firewallfalcon/falconproxy_config.conf" "$DB_DIR/"
    fi
    
    echo -e "${C_BLUE}⚙️ Resincronización de las cuentas del sistema con la base de datos restaurada...${C_RESET}"
    ensure_firewallfalcon_system_group
    
    while IFS=: read -r user pass expiry limit; do
        echo "Procesando usuario: ${C_YELLOW}$user${C_RESET}"
        if ! id "$user" &>/dev/null; then
            echo " - El usuario no existe en el sistema. Creando..."
            useradd -m -s /usr/sbin/nologin "$user"
        fi
        usermod -aG "$FF_USERS_GROUP" "$user" 2>/dev/null
        echo " - Establecer contraseña..."
        echo "$user:$pass" | chpasswd
        echo " - Establecer la fecha de expiración en $expiry..."
        chage -E "$expiry" "$user"
        echo " - El límite de conexiones es $limit (aplicado mediante PAM)"
    done < "$DB_FILE"
    rm -rf "$temp_dir"
    echo -e "\n${C_GREEN}✅ ÉXITO: ​​Restauración de datos de usuario completada.${C_RESET}"
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

_enable_banner_in_sshd_config() {
    echo -e "\n${C_BLUE}⚙️ Configuración de sshd_config...${C_RESET}"
    disable_dynamic_ssh_banner_system
    sed -i.bak -E 's/^( *Banner *).*/#\1/' /etc/ssh/sshd_config
    if ! grep -q -E "^Banner $SSH_BANNER_FILE" /etc/ssh/sshd_config; then
        echo -e "\n# FirewallFalcon SSH Banner\nBanner $SSH_BANNER_FILE" >> /etc/ssh/sshd_config
    fi
    echo -e "${C_GREEN}✅ sshd_config actualizado.${C_RESET}"
}

_restart_ssh() {
    echo -e "\n${C_BLUE}🔄 Reiniciando el servicio SSH para aplicar los cambios...${C_RESET}"
    local ssh_service_name=""
    if [ -f /lib/systemd/system/sshd.service ]; then
        ssh_service_name="sshd.service"
    elif [ -f /lib/systemd/system/ssh.service ]; then
        ssh_service_name="ssh.service"
    else
        echo -e "${C_RED}❌ No se pudo encontrar sshd.service ni ssh.service. No es posible reiniciar SSH.${C_RESET}"
        return 1
    fi

    systemctl restart "${ssh_service_name}"
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}✅ Servicio SSH ('${ssh_service_name}') reiniciado correctamente.${C_RESET}"
    else
        echo -e "${C_RED}❌ No se pudo reiniciar el servicio SSH ('${ssh_service_name}'). Por favor, compruebe 'journalctl -u ${ssh_service_name}' en busca de errores.${C_RESET}"
    fi
}

set_ssh_banner_paste() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Pegar banner SSH estático ---${C_RESET}"
    echo -e "Pega tu banner personalizado a continuación. Presiona ${C_ YELLOW}[Ctrl+D]${C_ RESET} cuando hayas terminado."
    echo -e "${C_DIM}Esto se mostrará a todos los usuarios de SSH a través de 'Banner $SSH_BANNER_FILE'.${C_RESET}"
    echo -e "${C_DIM}El banner actual (si existe) será sobrescrito.${C_RESET}"
    echo -e "--------------------------------------------------"
    cat > "$SSH_BANNER_FILE"
    chmod 644 "$SSH_BANNER_FILE"
    echo -e "\n--------------------------------------------------"
    echo -e "\n${C_GREEN}✅ Static banner content saved.${C_RESET}"
    _enable_banner_in_sshd_config
    _restart_ssh
    echo -e "\nPresione ${C_YELLOW}[Enter]${C_RESET} para regresar..." && read -r
}

view_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👁️ Banner SSH actual ---${C_RESET}"
    if [ -f "$SSH_BANNER_FILE" ]; then
        echo -e "\n${C_CYAN}--- INICIO DEL BANNER ---${C_RESET}"
        cat "$SSH_BANNER_FILE"
        echo -e "${C_CYAN}---- BANNER FINAL ----${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No se encontró ningún archivo de banner en $SSH_BANNER_FILE.${C_RESET}"
    fi
    echo -e "\nPresione ${C_YELLOW}[Enter]${C_RESET} para regresar..." && read -r
}

remove_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Disable SSH Banners ---${C_RESET}"
    read -p "👉 ¿Estás seguro de que quieres desactivar todos los banners SSH? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo -e "\n${C_YELLOW}❌ Acción cancelada.${C_RESET}"
        echo -e "\nPresione ${C_YELLOW}[Enter]${C_RESET} para regresar..." && read -r
        return
    fi
    if [ -f "$SSH_BANNER_FILE" ]; then
        rm -f "$SSH_BANNER_FILE"
        echo -e "\n${C_GREEN}✅ Archivo de banner eliminado: $SSH_BANNER_FILE${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No hay ningún archivo de banner que eliminar.${C_RESET}"
    fi
    disable_dynamic_ssh_banner_system
    echo -e "\n${C_BLUE}⚙️ Desactivar el banner en sshd_config...${C_RESET}"
    disable_static_ssh_banner_in_sshd_config
    echo -e "${C_GREEN}✅ Banner deshabilitado en la configuración.${C_RESET}"
    _restart_ssh
    echo -e "\nPresione ${C_YELLOW}[Enter]${C_RESET} para regresar..." && read -r
}

preview_dynamic_ssh_banner() {
    if ! is_dynamic_ssh_banner_enabled; then
        echo -e "\n${C_RED}❌ Los banners dinámicos no están habilitados en este momento.${C_RESET}"
        press_enter
        return
    fi

    echo -e "${C_DIM}Refreshing dynamic banner worker...${C_RESET}"
    setup_limiter_service >/dev/null 2>&1
    _select_user_interface "--- 📝 Vista previa del banner dinámico ---"
    local u=$SELECTED_USER
    if [[ -z "$u" || "$u" == "NO_USERS" ]]; then
        return
    fi

    echo -e "\n${C_CYAN}--- Vista previa de banner dinámico para el usuario '$u' ---${C_RESET}\n"
    if [[ -f "/etc/firewallfalcon/banners/${u}.txt" ]]; then
        cat "/etc/firewallfalcon/banners/${u}.txt"
    else
        echo -e "${C_RED}El archivo del banner aún no se ha generado. Espera hasta 10s a que el proceso de trabajo finalice...${C_RESET}"
        sleep 5
        if ! cat "/etc/firewallfalcon/banners/${u}.txt" 2>/dev/null; then
            echo -e "\n${C_RED}Aún no se ha generado. Aquí están los últimos registros del limitador:${C_RESET}"
            echo -e "----------------------------------------------------------------------"
            journalctl -u firewallfalcon-limiter -n 15 --no-pager
            echo -e "----------------------------------------------------------------------"
        fi
    fi
    press_enter
}

# NOTE: The full ssh_banner_menu() with dynamic/static support is defined later in the file.

install_udp_custom() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Instalación de udp-custom ---${C_RESET}"
    if [ -f "$UDP_CUSTOM_SERVICE_FILE" ] || [ -f "$UDPGW_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ udp-custom ya está instalado.${C_RESET}"
        return
    fi

    check_and_free_ports 36712 7800 || return
    check_and_open_firewall_port 36712 udp || return

    echo -e "\n${C_GREEN}⚙️ Creando directorio para udp-custom...${C_RESET}"
    rm -rf "$UDP_CUSTOM_DIR"
    mkdir -p "$UDP_CUSTOM_DIR"

    echo -e "\n${C_GREEN}⚙️ Detección de la arquitectura del sistema...${C_RESET}"
    local arch
    arch=$(uname -m)
    local binary_url=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_url="https://raw.githubusercontent.com/ianalejandrook14x/SSH-PANEL/main/udp/udp-custom-linux-amd64[1]"
        echo -e "${C_BLUE}ℹ️ Se ha detectado la arquitectura x86_64 (amd64).${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_url="https://raw.githubusercontent.com/ianalejandrook14x/SSH-PANEL/main/udp/udp-custom-linux-arm[1]"
        echo -e "${C_BLUE}ℹ️ Arquitectura ARM64 detectada.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Arquitectura no compatible: $arch. No es posible instalar udp-custom.${C_RESET}"
        rm -rf "$UDP_CUSTOM_DIR"
        return
    fi

    echo -e "\n${C_GREEN}📥 Descargando el binario udp-custom...${C_RESET}"
    wget -q --show-progress -O "$UDP_CUSTOM_DIR/udp-custom" "$binary_url"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ No se pudo descargar el binario udp-custom.${C_RESET}"
        rm -rf "$UDP_CUSTOM_DIR"
        return
    fi
    chmod +x "$UDP_CUSTOM_DIR/udp-custom"

    echo -e "\n${C_GREEN}📦 Configuración del asistente udpgw...${C_RESET}"
    if [[ "$arch" == "x86_64" ]]; then
        wget -q --show-progress -O "$UDPGW_BINARY" "https://raw.githubusercontent.com/http-custom/udp-custom/main/module/udpgw"
        if [ $? -ne 0 ]; then
            echo -e "\n${C_RED}❌ No se pudo descargar el binario auxiliar udpgw.${C_RESET}"
            rm -rf "$UDP_CUSTOM_DIR"
            return
        fi
        chmod +x "$UDPGW_BINARY"
    else
        echo -e "${C_YELLOW}ℹ️ La arquitectura es $arch. Compilando udpgw a partir del código fuente (esto puede tardar un minuto)...${C_RESET}"
        ff_pkg_install cmake g++ make git >/dev/null 2>&1
        local temp_build="/tmp/badvpn_build"
        rm -rf "$temp_build"
        git clone -q https://github.com/ambrop72/badvpn.git "$temp_build"
        (cd "$temp_build" && cmake . >/dev/null 2>&1 && make >/dev/null 2>&1)
        local compiled_bin=$(find "$temp_build" -name "badvpn-udpgw" -type f | head -n 1)
        if [[ -n "$compiled_bin" && -f "$compiled_bin" ]]; then
            cp "$compiled_bin" "$UDPGW_BINARY"
            chmod +x "$UDPGW_BINARY"
        else
            echo -e "\n${C_RED}❌ Error al compilar el asistente udpgw para $arch.${C_RESET}"
            rm -rf "$UDP_CUSTOM_DIR" "$temp_build"
            return
        fi
        rm -rf "$temp_build"
    fi

    echo -e "\n${C_GREEN}📝 Creando valores predeterminados config.json...${C_RESET}"
    cat > "$UDP_CUSTOM_DIR/config.json" <<EOF
{
  "listen": ":36712",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF
    chmod 644 "$UDP_CUSTOM_DIR/config.json"

    echo -e "\n${C_GREEN}📝 Creación del archivo de servicio systemd para udpgw...${C_RESET}"
    cat > "$UDPGW_SERVICE_FILE" <<EOF
[Unit]
Description=FirewallFalcon UDPGW Backend
After=network.target

[Service]
User=root
Type=simple
ExecStart=$UDPGW_BINARY --listen-addr 127.0.0.1:7800 --max-clients 1000 --max-connections-for-client 100
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n${C_GREEN}📝 Creación de un archivo de servicio de systemd...${C_RESET}"
    cat > "$UDP_CUSTOM_SERVICE_FILE" <<EOF
[Unit]
Description=UDP Custom by FirewallFalcon
After=network.target

[Service]
User=root
Type=simple
ExecStart=$UDP_CUSTOM_DIR/udp-custom server
WorkingDirectory=$UDP_CUSTOM_DIR/
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n${C_GREEN}▶️ Habilitar y iniciar el servicio udp-custom...${C_RESET}"
    systemctl daemon-reload
    systemctl enable udpgw.service
    systemctl start udpgw.service
    systemctl enable udp-custom.service
    systemctl start udp-custom.service
    sleep 2
    if systemctl is-active --quiet udpgw && systemctl is-active --quiet udp-custom; then
        echo -e "\n${C_GREEN}✅ ÉXITO: ​​udp-custom está instalado y activo..${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: el servicio udp-custom no pudo iniciarse.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Se muestran las últimas 15 líneas de los registros de udp-custom y udpgw para fines de diagnóstico:${C_RESET}"
        journalctl -u udp-custom.service -n 15 --no-pager
        journalctl -u udpgw.service -n 15 --no-pager
    fi
}

uninstall_udp_custom() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalando udp-custom ---${C_RESET}"
    if [ ! -f "$UDP_CUSTOM_SERVICE_FILE" ] && [ ! -f "$UDPGW_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ udp-custom no está instalado; se omite.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Detener y deshabilitar el servicio udpgw...${C_RESET}"
    systemctl stop udpgw.service >/dev/null 2>&1
    systemctl disable udpgw.service >/dev/null 2>&1
    echo -e "${C_GREEN}🛑 Detener y deshabilitar el servicio udp-custom...${C_RESET}"
    systemctl stop udp-custom.service >/dev/null 2>&1
    systemctl disable udp-custom.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Eliminación del archivo de servicio de systemd...${C_RESET}"
    rm -f "$UDP_CUSTOM_SERVICE_FILE"
    rm -f "$UDPGW_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Eliminando el directorio y los archivos de udp-custom...${C_RESET}"
    rm -rf "$UDP_CUSTOM_DIR"
    rm -f "$UDPGW_BINARY"
    echo -e "${C_GREEN}✅ udp-custom se ha desinstalado correctamente.${C_RESET}"
}


ensure_badvpn_service_is_quiet() {
    if [[ ! -f "$BADVPN_SERVICE_FILE" ]] || grep -q "^StandardOutput=null$" "$BADVPN_SERVICE_FILE" 2>/dev/null; then
        return
    fi

    local tmp_service
    tmp_service=$(mktemp)
    awk '
        /^\[Service\]$/ {
            print
            print "StandardOutput=null"
            print "StandardError=null"
            next
        }
        { print }
    ' "$BADVPN_SERVICE_FILE" > "$tmp_service" && mv "$tmp_service" "$BADVPN_SERVICE_FILE"
    rm -f "$tmp_service" 2>/dev/null
    systemctl daemon-reload
    systemctl restart badvpn.service >/dev/null 2>&1 || true
}

install_badvpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Instalación de badvpn (udpgw) ---${C_RESET}"
    if [ -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Badvpn ya está instalado.${C_RESET}"
        return
    fi
    check_and_open_firewall_port 7300 udp || return
    echo -e "\n${C_GREEN}🔄 Actualizando las listas de paquetes...${C_RESET}"
    ff_apt_update || return
    echo -e "\n${C_GREEN}📦 Instalando todos los paquetes necesarios...${C_RESET}"
    ff_pkg_install cmake g++ make screen git build-essential libssl-dev libnspr4-dev libnss3-dev pkg-config || {
        echo -e "${C_RED}❌ No se pudieron instalar las dependencias de compilación de badvpn.${C_RESET}"
        return
    }
    echo -e "\n${C_GREEN}📥 Clonar badvpn desde GitHub...${C_RESET}"
    git clone https://github.com/ambrop72/badvpn.git "$BADVPN_BUILD_DIR"
    cd "$BADVPN_BUILD_DIR" || { echo -e "${C_RED}❌ No se pudo cambiar el directorio a la carpeta de compilación.${C_RESET}"; return; }
    echo -e "\n${C_GREEN}⚙️ Ejecución de CMake...${C_RESET}"
    cmake . || { echo -e "${C_RED}❌ La configuración de CMake ha fallado.${C_RESET}"; rm -rf "$BADVPN_BUILD_DIR"; return; }
    echo -e "\n${C_GREEN}🛠️ Compiling source...${C_RESET}"
    make || { echo -e "${C_RED}❌ la compilación (make) falló.${C_RESET}"; rm -rf "$BADVPN_BUILD_DIR"; return; }
    local badvpn_binary
    badvpn_binary=$(find "$BADVPN_BUILD_DIR" -name "badvpn-udpgw" -type f | head -n 1)
    if [[ -z "$badvpn_binary" || ! -f "$badvpn_binary" ]]; then
        echo -e "${C_RED}❌ ERROR: No se pudo encontrar el binario compilado 'badvpn-udpgw' tras la compilación..${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    fi
    echo -e "${C_GREEN}ℹ️ Encontrado binario en: $badvpn_binary${C_RESET}"
    chmod +x "$badvpn_binary"
    echo -e "\n${C_GREEN}📝 creación de un archivo de servicio de systemd...${C_RESET}"
    cat > "$BADVPN_SERVICE_FILE" <<-EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target
[Service]
ExecStart=$badvpn_binary --listen-addr 0.0.0.0:7300 --max-clients 1000 --max-connections-for-client 8
User=root
Restart=always
RestartSec=3
StandardOutput=null
StandardError=null
[Install]
WantedBy=multi-user.target
EOF
    echo -e "\n${C_GREEN}▶️ Habilitar e iniciar el servicio badvpn...${C_RESET}"
    systemctl daemon-reload
    systemctl enable badvpn.service
    systemctl start badvpn.service
    sleep 2
    if systemctl is-active --quiet badvpn; then
        echo -e "\n${C_GREEN}✅ ÉXITO: ​​badvpn (udpgw) está instalado y activo en el puerto 7300.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: el servicio badvpn no pudo iniciarse.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Se muestran las últimas 15 líneas del registro del servicio para fines de diagnóstico:${C_RESET}"
        journalctl -u badvpn.service -n 15 --no-pager
    fi
}

uninstall_badvpn() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalación de badvpn (udpgw) ---${C_RESET}"
    if [ ! -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ badvpn no está instalado; se omite.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Detener y deshabilitar el servicio badvpn...${C_RESET}"
    systemctl stop badvpn.service >/dev/null 2>&1
    systemctl disable badvpn.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Eliminación del archivo de servicio de systemd...${C_RESET}"
    rm -f "$BADVPN_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Eliminando el directorio de compilación de badvpn...${C_RESET}"
    rm -rf "$BADVPN_BUILD_DIR"
    echo -e "${C_GREEN}✅ badvpn se ha desinstalado correctamente.${C_RESET}"
}

load_edge_cert_info() {
    EDGE_CERT_MODE=""
    EDGE_DOMAIN=""
    EDGE_EMAIL=""
    if [ -f "$EDGE_CERT_INFO_FILE" ]; then
        source "$EDGE_CERT_INFO_FILE"
    fi
}

save_edge_cert_info() {
    local cert_mode="$1"
    local cert_domain="$2"
    local cert_email="$3"
    mkdir -p "$DB_DIR"
    cat > "$EDGE_CERT_INFO_FILE" <<EOF
EDGE_CERT_MODE="$cert_mode"
EDGE_DOMAIN="$cert_domain"
EDGE_EMAIL="$cert_email"
EOF
}

detect_preferred_host() {
    local host_domain=""
    load_edge_cert_info
    if [[ -n "$EDGE_DOMAIN" ]]; then
        host_domain="$EDGE_DOMAIN"
    fi
    if [[ -z "$host_domain" && -f "$DNS_INFO_FILE" ]]; then
        host_domain=$(grep 'FULL_DOMAIN' "$DNS_INFO_FILE" | cut -d'"' -f2)
    fi
    if [[ -z "$host_domain" && -f "$NGINX_CONFIG_FILE" ]]; then
        local nginx_domain
        nginx_domain=$(grep -oP 'server_name \K[^\s;]+' "$NGINX_CONFIG_FILE" 2>/dev/null | head -n 1)
        if [[ "$nginx_domain" != "_" && -n "$nginx_domain" ]]; then
            host_domain="$nginx_domain"
        fi
    fi
    if [[ -z "$host_domain" ]]; then
        host_domain=$(curl -s -4 icanhazip.com)
    fi
    echo "$host_domain"
}

backup_edge_configs() {
    if [ -f "$NGINX_CONFIG_FILE" ] && [ ! -f "${NGINX_CONFIG_FILE}.bak.firewallfalcon" ]; then
        cp "$NGINX_CONFIG_FILE" "${NGINX_CONFIG_FILE}.bak.firewallfalcon" 2>/dev/null
    fi
    if [ -f "$HAPROXY_CONFIG" ] && [ ! -f "${HAPROXY_CONFIG}.bak.firewallfalcon" ]; then
        cp "$HAPROXY_CONFIG" "${HAPROXY_CONFIG}.bak.firewallfalcon" 2>/dev/null
    fi
}

ensure_edge_stack_packages() {
    local missing_packages=()
    if ! command -v haproxy &> /dev/null || [ ! -f "/etc/haproxy/haproxy.cfg" ]; then
        missing_packages+=("haproxy")
    fi
    if ! command -v nginx &> /dev/null || [ ! -f "/etc/nginx/nginx.conf" ]; then
        missing_packages+=("nginx")
    fi
    command -v openssl &> /dev/null || missing_packages+=("openssl")

    if (( ${#missing_packages[@]} > 0 )); then
        echo -e "\n${C_BLUE}📦 Instalación de los paquetes necesarios: ${missing_packages[*]}${C_RESET}"
        if ! ff_pkg_install "${missing_packages[@]}"; then
            echo -e "${C_YELLOW}⚠️ La instalación del paquete ha fallado. Se está intentando corregir configuraciones dañadas....${C_RESET}"
            if command -v apt-get &>/dev/null; then
                apt-get purge -y nginx nginx-common haproxy >/dev/null 2>&1
            fi
            if ! ff_pkg_install "${missing_packages[@]}"; then
                echo -e "${C_RED}❌ No se pudieron instalar los paquetes necesarios.${C_RESET}"
                return 1
            fi
        fi
    fi
    return 0
}

build_shared_tls_bundle() {
    if [ ! -s "$SSL_CERT_CHAIN_FILE" ] || [ ! -s "$SSL_CERT_KEY_FILE" ]; then
        echo -e "${C_RED}❌ Falta la cadena de certificados o la clave.${C_RESET}"
        return 1
    fi
    cat "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE" > "$SSL_CERT_FILE" || return 1
    chmod 644 "$SSL_CERT_CHAIN_FILE"
    chmod 600 "$SSL_CERT_KEY_FILE" "$SSL_CERT_FILE"
    return 0
}

generate_self_signed_edge_cert() {
    local common_name="$1"
    mkdir -p "$SSL_CERT_DIR"
    echo -e "\n${C_GREEN}🔐 Generando un certificado autofirmado compartido...${C_RESET}"
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout "$SSL_CERT_KEY_FILE" \
        -out "$SSL_CERT_CHAIN_FILE" \
        -subj "/CN=$common_name" \
        >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ No se pudo generar el certificado autofirmado.${C_RESET}"
            return 1
        }
    build_shared_tls_bundle || return 1
    save_edge_cert_info "self-signed" "$common_name" ""
    echo -e "${C_GREEN}✅ Certificado compartido creado para ${C_YELLOW}$common_name${C_RESET}"
    return 0
}

_install_certbot() {
    if command -v certbot &> /dev/null; then
        echo -e "${C_GREEN}✅ Certbot ya está instalado.${C_RESET}"
        return 0
    fi
    echo -e "${C_BLUE}📦 Installing Certbot...${C_RESET}"
    ff_pkg_install certbot || {
        echo -e "${C_RED}❌ No se pudo instalar Certbot.${C_RESET}"
        return 1
    }
    echo -e "${C_GREEN}✅ Certbot se ha instalado correctamente.${C_RESET}"
    return 0
}

obtain_certbot_edge_cert() {
    local domain_name="$1"
    local email="$2"
    local restart_haproxy=0
    local restart_nginx=0

    mkdir -p "$SSL_CERT_DIR"
    _install_certbot || return 1

    if systemctl is-active --quiet haproxy; then restart_haproxy=1; fi
    if systemctl is-active --quiet nginx; then restart_nginx=1; fi

    echo -e "\n${C_BLUE}🛑 Detención de HAProxy y Nginx para la validación de Certbot...${C_RESET}"
    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 2

    check_and_free_ports "$EDGE_PUBLIC_HTTP_PORT" "$EDGE_PUBLIC_TLS_PORT" || {
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    }

    echo -e "\n${C_BLUE}🚀 Solicitar un certificado Certbot para ${C_YELLOW}$domain_name${C_RESET}"
    certbot certonly --standalone -d "$domain_name" --non-interactive --agree-tos -m "$email"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Certbot no pudo obtener un certificado.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Asegúrate de que el dominio apunte a este servidor y de que el puerto 80 sea accesible..${C_RESET}"
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    fi

    local certbot_chain="/etc/letsencrypt/live/$domain_name/fullchain.pem"
    local certbot_key="/etc/letsencrypt/live/$domain_name/privkey.pem"
    if [ ! -f "$certbot_chain" ] || [ ! -f "$certbot_key" ]; then
        echo -e "\n${C_RED}❌ Certbot ha finalizado, pero no se han encontrado los archivos del certificado.${C_RESET}"
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    fi

    cp "$certbot_chain" "$SSL_CERT_CHAIN_FILE"
    cp "$certbot_key" "$SSL_CERT_KEY_FILE"
    build_shared_tls_bundle || {
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    }
    save_edge_cert_info "certbot" "$domain_name" "$email"
    echo -e "${C_GREEN}✅ Certificado de Certbot copiado en ${C_YELLOW}$SSL_CERT_DIR${C_RESET}"
    return 0
}

select_edge_certificate() {
    local preferred_host
    local cert_choice
    local has_existing_cert=false

    preferred_host=$(detect_preferred_host)
    if [[ -z "$preferred_host" ]]; then
        preferred_host="firewallfalcon.local"
    fi

    if [ -s "$SSL_CERT_FILE" ] && [ -s "$SSL_CERT_CHAIN_FILE" ] && [ -s "$SSL_CERT_KEY_FILE" ]; then
        has_existing_cert=true
    fi

    load_edge_cert_info

    echo -e "\n${C_BOLD}${C_PURPLE}--- 🔐 Certificado TLS compartido ---${C_RESET}"
    echo -e "${C_DIM}El mismo certificado será utilizado por HAProxy y por el proxy Nginx interno.${C_RESET}"

    if $has_existing_cert; then
        local existing_label="${EDGE_CERT_MODE:-existing}"
        if [[ -n "$EDGE_DOMAIN" ]]; then
            existing_label="$existing_label - $EDGE_DOMAIN"
        fi
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-52s\n" "Reutilizar el certificado existente (${existing_label})"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-52s\n" "Reemplazar por un nuevo certificado autofirmado"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %-52s\n" "Reemplazar con un certificado de Certbot"
        echo
        read -p "👉 Introduce tu elección [1]: " cert_choice
        cert_choice=${cert_choice:-1}
    else
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-52s\n" "Generar un certificado autofirmado"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-52s\n" "Utiliza un certificado de Certbot"
        echo
        read -p "👉 Introduce tu elección [1]: " cert_choice
        cert_choice=${cert_choice:-1}
    fi

    case "$cert_choice" in
        1)
            if $has_existing_cert; then
                echo -e "${C_GREEN}✅ Reutilización del certificado compartido existente.${C_RESET}"
                return 0
            fi
            local common_name
            read -p "👉 Introduzca el nombre común/etiqueta SNI del certificado. [$preferred_host]: " common_name
            common_name=${common_name:-$preferred_host}
            generate_self_signed_edge_cert "$common_name"
            ;;
        2)
            if $has_existing_cert; then
                local common_name
                read -p "👉 Introduzca el nombre común/etiqueta SNI del certificado. [$preferred_host]: " common_name
                common_name=${common_name:-$preferred_host}
                generate_self_signed_edge_cert "$common_name"
            else
                local default_domain=""
                local domain_name
                local email
                if ! _is_valid_ipv4 "$preferred_host"; then
                    default_domain="$preferred_host"
                fi
                if [[ -n "$default_domain" ]]; then
                    read -p "👉 Introduce tu nombre de dominio [$default_domain]: " domain_name
                    domain_name=${domain_name:-$default_domain}
                else
                    read -p "👉 Introduce tu nombre de dominio (e.j. fixxed.site): " domain_name
                fi
                if [[ -z "$domain_name" ]]; then
                    echo -e "${C_RED}❌ El nombre de dominio no puede estar vacío.${C_RESET}"
                    return 1
                fi
                if _is_valid_ipv4 "$domain_name"; then
                    echo -e "${C_RED}❌ Certbot requiere un nombre de dominio real, no una dirección IP sin procesar..${C_RESET}"
                    return 1
                fi
                read -p "👉 Introduce tu correo electrónico para Let's Encrypt: " email
                if [[ -z "$email" ]]; then
                    echo -e "${C_RED}❌ El correo electrónico no puede estar vacío.${C_RESET}"
                    return 1
                fi
                obtain_certbot_edge_cert "$domain_name" "$email"
            fi
            ;;
        3)
            if ! $has_existing_cert; then
                echo -e "${C_RED}❌ Opción no válida.${C_RESET}"
                return 1
            fi
            local default_domain=""
            local domain_name
            local email
            if [[ -n "$EDGE_DOMAIN" ]] && ! _is_valid_ipv4 "$EDGE_DOMAIN"; then
                default_domain="$EDGE_DOMAIN"
            fi
            if [[ -z "$default_domain" ]] && ! _is_valid_ipv4 "$preferred_host"; then
                default_domain="$preferred_host"
            fi
            if [[ -n "$default_domain" ]]; then
                read -p "👉 Introduce tu nombre de dominio [$default_domain]: " domain_name
                domain_name=${domain_name:-$default_domain}
            else
                read -p "👉 Introduce tu nombre de dominio (e.j. fixxed.site): " domain_name
            fi
            if [[ -z "$domain_name" ]]; then
                echo -e "${C_RED}❌ El nombre de dominio no puede estar vacío.${C_RESET}"
                return 1
            fi
            if _is_valid_ipv4 "$domain_name"; then
                echo -e "${C_RED}❌ Certbot requiere un nombre de dominio real, no una dirección IP sin procesar.${C_RESET}"
                return 1
            fi
            read -p "👉 Introduce tu correo electrónico para Let's Encrypt [${EDGE_EMAIL}]: " email
            email=${email:-$EDGE_EMAIL}
            if [[ -z "$email" ]]; then
                echo -e "${C_RED}❌ El correo electrónico no puede estar vacío.${C_RESET}"
                return 1
            fi
            obtain_certbot_edge_cert "$domain_name" "$email"
            ;;
        *)
            echo -e "${C_RED}❌ Opción no válida.${C_RESET}"
            return 1
            ;;
    esac
}

write_internal_nginx_config() {
    local server_name="$1"
    [[ -z "$server_name" ]] && server_name="_"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > "$NGINX_CONFIG_FILE" <<EOF
server {
    listen 127.0.0.1:${NGINX_INTERNAL_HTTP_PORT} default_server;
    listen 127.0.0.1:${NGINX_INTERNAL_TLS_PORT} ssl http2 default_server;
    server_tokens off;
    server_name ${server_name};

    ssl_certificate ${SSL_CERT_CHAIN_FILE};
    ssl_certificate_key ${SSL_CERT_KEY_FILE};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!MD5:!DES:!RC4:!ADH:!SSLv3:!EXP:!PSK:!DSS;
    resolver 1.1.1.1 8.8.8.8 ipv6=off valid=300s;

    location ~ ^/(?<fwdport>\d+)/(?<fwdpath>.*)$ {
        client_max_body_size 0;
        client_body_timeout 1d;
        grpc_read_timeout 1d;
        grpc_socket_keepalive on;
        proxy_read_timeout 1d;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_socket_keepalive on;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        if (\$content_type ~* "GRPC") { grpc_pass grpc://127.0.0.1:\$fwdport\$is_args\$args; break; }
        proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
        break;
    }

    location / {
        proxy_read_timeout 3600s;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_socket_keepalive on;
        tcp_nodelay on;
        tcp_nopush off;
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
    ln -sf "$NGINX_CONFIG_FILE" /etc/nginx/sites-enabled/default
}

write_haproxy_edge_config() {
    mkdir -p /etc/haproxy
    cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5s
    timeout client  24h
    timeout server  24h

# ====================================================================
# TIER 1: PORT ${EDGE_PUBLIC_HTTP_PORT} (Cleartext Payloads & Raw SSH)
# ====================================================================
frontend port_80_edge
    bind *:${EDGE_PUBLIC_HTTP_PORT}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30

    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP

    use_backend direct_ssh if is_ssh
    default_backend nginx_cleartext

# ====================================================================
# TIER 1: PORT ${EDGE_PUBLIC_TLS_PORT} (TLS v2ray, SSL Payloads, Raw SSH)
# ====================================================================
frontend port_443_edge
    bind *:${EDGE_PUBLIC_TLS_PORT}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    acl is_tls req.ssl_hello_type 1
    acl has_web_alpn req.ssl_alpn -m sub h2 http/1.1

    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP
    tcp-request content accept if is_tls

    use_backend direct_ssh if is_ssh
    use_backend nginx_cleartext if HTTP
    use_backend nginx_tls if is_tls has_web_alpn
    default_backend loopback_ssl_terminator

# ====================================================================
# TIER 2: INTERNAL DECRYPTOR (Only for Any-SNI SSH-TLS)
# ====================================================================
frontend internal_decryptor
    bind 127.0.0.1:${HAPROXY_INTERNAL_DECRYPT_PORT} ssl crt ${SSL_CERT_FILE}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP

    use_backend direct_ssh if is_ssh
    default_backend nginx_cleartext

# ====================================================================
# DESTINATION BACKENDS (Clean handoffs, no proxy headers)
# ====================================================================
backend direct_ssh
    mode tcp
    server ssh_server 127.0.0.1:22

backend nginx_cleartext
    mode tcp
    server nginx_8880 127.0.0.1:${NGINX_INTERNAL_HTTP_PORT}

backend nginx_tls
    mode tcp
    server nginx_8443 127.0.0.1:${NGINX_INTERNAL_TLS_PORT}

backend loopback_ssl_terminator
    mode tcp
    server haproxy_ssl 127.0.0.1:${HAPROXY_INTERNAL_DECRYPT_PORT}
EOF
}

save_edge_ports_info() {
    cat > "$NGINX_PORTS_FILE" <<EOF
EDGE_HTTP_PORT="${EDGE_PUBLIC_HTTP_PORT}"
EDGE_TLS_PORT="${EDGE_PUBLIC_TLS_PORT}"
HTTP_PORTS="${NGINX_INTERNAL_HTTP_PORT}"
TLS_PORTS="${NGINX_INTERNAL_TLS_PORT}"
EOF
}

configure_edge_stack() {
    local server_name="$1"
    [[ -z "$server_name" ]] && server_name="_"

    backup_edge_configs

    echo -e "\n${C_BLUE}📝 Redacción de la configuración interna de Nginx (127.0.0.1:${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT})...${C_RESET}"
    write_internal_nginx_config "$server_name"

    echo -e "${C_BLUE}📝 Redacción de la configuración del Edge de HAProxy (${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT})...${C_RESET}"
    write_haproxy_edge_config

    echo -e "\n${C_BLUE}🧪 Validación de la configuración de Nginx...${C_RESET}"
    if ! nginx -t >/dev/null 2>&1; then
        echo -e "${C_RED}❌ La validación de la configuración de Nginx ha fallado.${C_RESET}"
        nginx -t
        return 1
    fi

    echo -e "${C_BLUE}🧪 Validación de la configuración de HAProxy...${C_RESET}"
    if ! haproxy -c -f "$HAPROXY_CONFIG" >/dev/null 2>&1; then
        echo -e "${C_RED}❌ La validación de la configuración de HAProxy ha fallado.${C_RESET}"
        haproxy -c -f "$HAPROXY_CONFIG"
        return 1
    fi

    systemctl daemon-reload
    systemctl enable nginx >/dev/null 2>&1
    systemctl enable haproxy >/dev/null 2>&1

    echo -e "\n${C_BLUE}▶️ Reiniciando el Nginx interno...${C_RESET}"
    systemctl restart nginx || {
        echo -e "${C_RED}❌ Nginx no pudo reiniciarse.${C_RESET}"
        systemctl status nginx --no-pager
        return 1
    }

    echo -e "${C_BLUE}▶️ Reiniciando HAProxy edge...${C_RESET}"
    systemctl restart haproxy || {
        echo -e "${C_RED}❌ HAProxy no pudo reiniciarse.${C_RESET}"
        systemctl status haproxy --no-pager
        return 1
    }

    sleep 2
    if ! systemctl is-active --quiet nginx; then
        echo -e "${C_RED}❌ Nginx no está activo después de reiniciar.${C_RESET}"
        systemctl status nginx --no-pager
        return 1
    fi
    if ! systemctl is-active --quiet haproxy; then
        echo -e "${C_RED}❌ HAProxy no está activo después de reiniciar.${C_RESET}"
        systemctl status haproxy --no-pager
        return 1
    fi

    save_edge_ports_info
    return 0
}

install_ssl_tunnel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Instalación de HAProxy Edge Stack (80/443 -> 8880/8443) ---${C_RESET}"
    echo -e "\n${C_CYAN}Este instalador configurará:${C_RESET}"
    echo -e "   • HAProxy en ${C_WHITE}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Nginx interno activado ${C_WHITE}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "   • Descifrador SSL de bucle invertido en ${C_WHITE}${HAPROXY_INTERNAL_DECRYPT_PORT}${C_RESET}"

    if [ -f "$HAPROXY_CONFIG" ] || [ -f "$NGINX_CONFIG_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ Las configuraciones existentes de HAProxy/Nginx serán reemplazadas por la estructura de borde (edge ​​layout) de FirewallFalcon.${C_RESET}"
        read -p "👉 ¿Continuar con el reemplazo? (y/n): " confirm_replace
        if [[ "$confirm_replace" != "y" && "$confirm_replace" != "Y" ]]; then
            echo -e "${C_RED}❌ Instalación cancelada.${C_RESET}"
            return
        fi
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"

    ensure_edge_stack_packages || return

    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 1

    check_and_free_ports \
        "$EDGE_PUBLIC_HTTP_PORT" \
        "$EDGE_PUBLIC_TLS_PORT" \
        "$NGINX_INTERNAL_HTTP_PORT" \
        "$NGINX_INTERNAL_TLS_PORT" \
        "$HAPROXY_INTERNAL_DECRYPT_PORT" || return

    check_and_open_firewall_port "$EDGE_PUBLIC_HTTP_PORT" tcp || return
    check_and_open_firewall_port "$EDGE_PUBLIC_TLS_PORT" tcp || return

    select_edge_certificate || return

    load_edge_cert_info
    local server_name="${EDGE_DOMAIN:-$(detect_preferred_host)}"
    [[ -z "$server_name" ]] && server_name="_"

    configure_edge_stack "$server_name" || return

    echo -e "\n${C_GREEN}✅ SUCCESS: HAProxy edge stack is active.${C_RESET}"
    echo -e "   • Puertos edge publico: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Puertos internos de Nginx: ${C_YELLOW}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "   • Certificado compartido: ${C_YELLOW}${EDGE_CERT_MODE:-unknown}${C_RESET}"
}

uninstall_ssl_tunnel() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalando HAProxy Edge Stack ---${C_RESET}"
    if ! command -v haproxy &> /dev/null; then
        echo -e "${C_YELLOW}ℹ️ HAProxy no está instalado; se omite la eliminación del servicio.${C_RESET}"
    else
        echo -e "${C_GREEN}🛑 Detención y desactivación de HAProxy...${C_RESET}"
        systemctl stop haproxy >/dev/null 2>&1
        systemctl disable haproxy >/dev/null 2>&1
    fi

    if [ -f "$HAPROXY_CONFIG" ]; then
        cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice

defaults
    log     global
EOF
    fi

    local delete_cert="n"
    if [[ "$UNINSTALL_MODE" == "silent" ]]; then
        delete_cert="y"
    elif [ -f "$SSL_CERT_FILE" ] || [ -f "$SSL_CERT_CHAIN_FILE" ] || [ -f "$SSL_CERT_KEY_FILE" ]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${C_YELLOW}⚠️ El certificado compartido también es utilizado por el proxy Nginx interno.${C_RESET}"
        fi
        read -p "👉 ¿Eliminar también el certificado TLS compartido? (y/n): " delete_cert
    fi

    if [[ "$delete_cert" == "y" || "$delete_cert" == "Y" ]]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${C_GREEN}🛑 Se detiene Nginx porque se va a eliminar el certificado compartido....${C_RESET}"
            systemctl stop nginx >/dev/null 2>&1
        fi
        rm -f "$SSL_CERT_FILE" "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE" "$EDGE_CERT_INFO_FILE"
        rm -f "$NGINX_PORTS_FILE"
        echo -e "${C_GREEN}🗑️ Shared certificate files removed.${C_RESET}"
    fi

    echo -e "${C_GREEN}✅ Se ha eliminado la pila perimetral (edge ​​stack) de HAProxy..${C_RESET}"
    if systemctl is-active --quiet nginx; then
        echo -e "${C_DIM}El proxy Nginx interno todavía está instalado en ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"
    fi
}

show_dnstt_details() {
    if [ -f "$DNSTT_CONFIG_FILE" ]; then
        source "$DNSTT_CONFIG_FILE"
        echo -e "\n${C_GREEN}=====================================================${C_RESET}"
        echo -e "${C_GREEN}            📡 Detalles de la conexión DNSTT             ${C_RESET}"
        echo -e "${C_GREEN}=====================================================${C_RESET}"
        echo -e "\n${C_WHITE}Tus datos de conexión:${C_RESET}"
        echo -e "  - ${C_CYAN}Dominio de túnel:${C_RESET} ${C_YELLOW}$TUNNEL_DOMAIN${C_RESET}"
        echo -e "  - ${C_CYAN}Clave pública:${C_RESET}    ${C_YELLOW}$PUBLIC_KEY${C_RESET}"
        if [[ -n "$FORWARD_DESC" ]]; then
            echo -e "  - ${C_CYAN}Reenviando a:${C_RESET} ${C_YELLOW}$FORWARD_DESC${C_RESET}"
        else
            echo -e "  - ${C_CYAN}Reenviando a:${C_RESET} ${C_YELLOW}Desconocido (config_missing)${C_RESET}"
        fi
        if [[ -n "$MTU_VALUE" ]]; then
            echo -e "  - ${C_CYAN}MTU Value:${C_RESET}     ${C_YELLOW}$MTU_VALUE${C_RESET}"
        fi
        if [[ "$DNSTT_RECORDS_MANAGED" == "false" && -n "$NS_DOMAIN" ]]; then
             echo -e "  - ${C_CYAN}NS Record:${C_RESET}     ${C_YELLOW}$NS_DOMAIN${C_RESET}"
        fi
        
        if [[ "$FORWARD_DESC" == *"V2Ray"* ]]; then
             echo -e "  - ${C_CYAN}Se requiere acción:${C_RESET} ${C_YELLOW}Asegúrese de que un servicio V2Ray (vless/vmess/trojan) escuche en el puerto 8787 (sin TLS)${C_RESET}"
        elif [[ "$FORWARD_DESC" == *"SSH"* ]]; then
             echo -e "  - ${C_CYAN}Se requiere acción:${C_RESET} ${C_YELLOW}Asegúrate de que tu cliente SSH esté configurado para utilizar el túnel DNS.${C_RESET}"
        fi
        
        echo -e "\n${C_DIM}Utiliza estos detalles en la configuración de tu cliente..${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No se ha encontrado el archivo de configuración de DNSTT. No hay detalles disponibles.${C_RESET}"
    fi
}

install_dnstt() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📡 Gestión de DNSTT (túnel DNS) ---${C_RESET}"
    if [ -f "$DNSTT_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ DNSTT ya está instalado.${C_RESET}"
        show_dnstt_details
        return
    fi
    
    # --- FIX: Force release of Port 53 / Disable systemd-resolved ---
    echo -e "${C_GREEN}⚙️ Forzando la liberación del Puerto 53 (deteniendo systemd-resolved)...${C_RESET}"
    systemctl stop systemd-resolved >/dev/null 2>&1
    systemctl disable systemd-resolved >/dev/null 2>&1
    # Mask it so it never starts again on reboot
    systemctl mask systemd-resolved >/dev/null 2>&1
    chattr -i /etc/resolv.conf &>/dev/null
    rm -f /etc/resolv.conf
    printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n' > /etc/resolv.conf
    chattr +i /etc/resolv.conf
    # ----------------------------------------------------------------
    
    echo -e "\n${C_BLUE}🔎 Comprobando si el puerto 53 (UDP) está disponible...${C_RESET}"
    if ss -lunp | grep -q ':53\s'; then
        if [[ $(ps -p $(ss -lunp | grep ':53\s' | grep -oP 'pid=\K[0-9]+') -o comm=) == "systemd-resolve" ]]; then
            echo -e "${C_YELLOW}⚠️ Advertencia: El puerto 53 está siendo utilizado por 'systemd-resolved'.${C_RESET}"
            echo -e "${C_YELLOW}Este es el «stub resolver» DNS del sistema. Debe estar deshabilitado para ejecutar DNSTT..${C_RESET}"
            read -p "👉 ¿Permitir que el script lo deshabilite automáticamente y reconfigure el DNS? (y/n): " resolve_confirm
            if [[ "$resolve_confirm" == "y" || "$resolve_confirm" == "Y" ]]; then
                echo -e "${C_GREEN}⚙️ Detener y deshabilitar systemd-resolved para liberar el puerto 53...${C_RESET}"
                systemctl stop systemd-resolved
                systemctl disable systemd-resolved
                chattr -i /etc/resolv.conf &>/dev/null
                rm -f /etc/resolv.conf
                echo "nameserver 8.8.8.8" > /etc/resolv.conf
                chattr +i /etc/resolv.conf
                echo -e "${C_GREEN}✅ El puerto 53 ha sido liberado y el DNS está configurado en 8.8.8.8.${C_RESET}"
            else
                echo -e "${C_RED}❌ No es posible continuar sin liberar el puerto 53. Abortando.${C_RESET}"
                return
            fi
        else
            check_and_free_ports "53" || return
        fi
    else
        echo -e "${C_GREEN}✅ El puerto 53 (UDP) está disponible para su uso.${C_RESET}"
    fi

    check_and_open_firewall_port 53 udp || return



    local forward_port=""
    local forward_desc=""
    echo -e "\n${C_BLUE}Por favor, elige a dónde debe reenviar el tráfico DNSTT.:${C_RESET}"
    echo -e "  ${C_GREEN}[ 1]${C_RESET} ➡️ Reenviar al servicio SSH local (port 22)"
    echo -e "  ${C_GREEN}[ 2]${C_RESET} ➡️ Reenviar al backend local de V2Ray (port 8787)"
    read -p "👉 Introduce tu elección [2]: " fwd_choice
    fwd_choice=${fwd_choice:-2}
    if [[ "$fwd_choice" == "1" ]]; then
        forward_port="22"
        forward_desc="SSH (port 22)"
        echo -e "${C_GREEN}ℹ️ DNSTT reenviará a SSH en 127.0.0.1:22.${C_RESET}"
        

        
    elif [[ "$fwd_choice" == "2" ]]; then
        forward_port="8787"
        forward_desc="V2Ray (port 8787)"
        echo -e "${C_GREEN}ℹ️ DNSTT reenviará a V2Ray a través de 127.0.0.1:8787.${C_RESET}"
    else
        echo -e "${C_RED}❌ Opción no válida. Cancelando..${C_RESET}"
        return
    fi
    local FORWARD_TARGET="127.0.0.1:$forward_port"
    
    local NS_DOMAIN=""
    local TUNNEL_DOMAIN=""
    local DNSTT_RECORDS_MANAGED="true"
    local NS_SUBDOMAIN=""
    local TUNNEL_SUBDOMAIN=""
    local HAS_IPV6="false"

    read -p "👉 ¿Generar registros DNS automáticamente o utilizar registros personalizados? (auto/custom) [auto]: " dns_choice
    dns_choice=${dns_choice:-auto}

    if [[ "$dns_choice" == "custom" ]]; then
        DNSTT_RECORDS_MANAGED="false"
        read -p "👉 Introduce los nameserver de tu dominio (e.g., ns1.yourdomain.com): " NS_DOMAIN
        if [[ -z "$NS_DOMAIN" ]]; then echo -e "\n${C_RED}❌ El servidor de nombres (nameserver) del dominio no puede estar vacío. Abortando..${C_RESET}"; return; fi
        read -p "👉 Introduce tu dominio de túnel completo (e.g., tun.yourdomain.com): " TUNNEL_DOMAIN
        if [[ -z "$TUNNEL_DOMAIN" ]]; then echo -e "\n${C_RED}❌ El dominio del túnel no puede estar vacío. Abortando..${C_RESET}"; return; fi
    else
        echo -e "\n${C_BLUE}⚙️ Configuring DNS records for DNSTT...${C_RESET}"
        local SERVER_IPV4
        SERVER_IPV4=$(curl -s -4 icanhazip.com)
        if ! _is_valid_ipv4 "$SERVER_IPV4"; then
            echo -e "\n${C_RED}❌ Error: No se pudo obtener una dirección IPv4 pública válida desde icanhazip.com.${C_RESET}"
            echo -e "${C_YELLOW}ℹ️ Por favor, comprueba la conexión de red y la configuración del servidor DNS de tu servidor.${C_RESET}"
            echo -e "   Resultado recibido: '$SERVER_IPV4'"
            return 1
        fi
        
        local SERVER_IPV6
        SERVER_IPV6=$(curl -s -6 icanhazip.com --max-time 5)
        
        local RANDOM_STR
        RANDOM_STR=$(tr -dc a-z0-9 < /dev/urandom | head -c 6)
        NS_SUBDOMAIN="ns-$RANDOM_STR"
        TUNNEL_SUBDOMAIN="tun-$RANDOM_STR"
        NS_DOMAIN="$NS_SUBDOMAIN.$DESEC_DOMAIN"
        TUNNEL_DOMAIN="$TUNNEL_SUBDOMAIN.$DESEC_DOMAIN"

        local API_DATA
        API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}, {"subname": "%s", "type": "NS", "ttl": 3600, "records": ["%s."]}]' \
            "$NS_SUBDOMAIN" "$SERVER_IPV4" "$TUNNEL_SUBDOMAIN" "$NS_DOMAIN")

        if [[ -n "$SERVER_IPV6" ]]; then
            local aaaa_record
            aaaa_record=$(printf ',{"subname": "%s", "type": "AAAA", "ttl": 3600, "records": ["%s"]}' "$NS_SUBDOMAIN" "$SERVER_IPV6")
            API_DATA="${API_DATA%?}${aaaa_record}]"
            HAS_IPV6="true"
        fi

        local CREATE_RESPONSE
        CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
            -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" \
            --data "$API_DATA")
        
        local HTTP_CODE=${CREATE_RESPONSE: -3}
        local RESPONSE_BODY=${CREATE_RESPONSE:0:${#CREATE_RESPONSE}-3}

        if [[ "$HTTP_CODE" -ne 201 ]]; then
            echo -e "${C_RED}❌ No se pudieron crear los registros DNSTT. La API devolvió un código HTTP $HTTP_CODE.${C_RESET}"
            echo "Response: $RESPONSE_BODY" | jq
            return 1
        fi
    fi
    
    read -p "👉 Introduzca el valor MTU (p. ej., 512, 1200) o pulse [Enter] para el valor predeterminado: " mtu_value
    local mtu_string=""
    if [[ "$mtu_value" =~ ^[0-9]+$ ]]; then
        mtu_string=" -mtu $mtu_value"
        echo -e "${C_GREEN}ℹ️ Uso de MTU: $mtu_value${C_RESET}"
    else
        mtu_value=""
        echo -e "${C_YELLOW}ℹ️ Uso de la MTU predeterminada.${C_RESET}"
    fi

    echo -e "\n${C_BLUE}📥 Descargando el binario del servidor DNSTT precompilado...${C_RESET}"
    local arch
    arch=$(uname -m)
    local binary_url=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_url="https://dnstt.network/dnstt-server-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Se ha detectado la arquitectura x86_64 (amd64).${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_url="https://dnstt.network/dnstt-server-linux-arm64"
        echo -e "${C_BLUE}ℹ️ Arquitectura ARM64 detectada.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Arquitectura no compatible: $arch. No es posible instalar DNSTT.${C_RESET}"
        return
    fi
    
    curl -sL "$binary_url" -o "$DNSTT_BINARY"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ No se pudo descargar el binario de DNSTT.${C_RESET}"
        return
    fi
    chmod +x "$DNSTT_BINARY"

    echo -e "${C_BLUE}🔐 Generando claves criptográficas...${C_RESET}"
    mkdir -p "$DNSTT_KEYS_DIR"
    "$DNSTT_BINARY" -gen-key -privkey-file "$DNSTT_KEYS_DIR/server.key" -pubkey-file "$DNSTT_KEYS_DIR/server.pub"
    if [[ ! -f "$DNSTT_KEYS_DIR/server.key" ]]; then echo -e "${C_RED}❌ No se pudieron generar las claves DNSTT.${C_RESET}"; return; fi
    
    local PUBLIC_KEY
    PUBLIC_KEY=$(cat "$DNSTT_KEYS_DIR/server.pub")
    
    echo -e "\n${C_BLUE}📝 Creación de un servicio systemd...${C_RESET}"
    cat > "$DNSTT_SERVICE_FILE" <<-EOF
[Unit]
Description=DNSTT (DNS Tunnel) Server for $forward_desc
After=network-online.target
Wants=network-online.target
Conflicts=systemd-resolved.service
[Service]
Type=simple
User=root
ExecStartPre=/bin/bash -c 'systemctl stop systemd-resolved 2>/dev/null; systemctl mask systemd-resolved 2>/dev/null; chattr -i /etc/resolv.conf 2>/dev/null; printf "nameserver 8.8.8.8\\nnameserver 8.8.4.4\\n" > /etc/resolv.conf; chattr +i /etc/resolv.conf; sleep 1'
ExecStart=$DNSTT_BINARY -udp :53$mtu_string -privkey-file $DNSTT_KEYS_DIR/server.key $TUNNEL_DOMAIN $FORWARD_TARGET
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    echo -e "\n${C_BLUE}💾 Guardando la configuración e iniciando el servicio...${C_RESET}"
    cat > "$DNSTT_CONFIG_FILE" <<-EOF
NS_SUBDOMAIN="$NS_SUBDOMAIN"
TUNNEL_SUBDOMAIN="$TUNNEL_SUBDOMAIN"
NS_DOMAIN="$NS_DOMAIN"
TUNNEL_DOMAIN="$TUNNEL_DOMAIN"
PUBLIC_KEY="$PUBLIC_KEY"
FORWARD_DESC="$forward_desc"
DNSTT_RECORDS_MANAGED="$DNSTT_RECORDS_MANAGED"
HAS_IPV6="$HAS_IPV6"
MTU_VALUE="$mtu_value"
EOF
    systemctl daemon-reload
    systemctl enable dnstt.service
    systemctl start dnstt.service
    sleep 2
    if systemctl is-active --quiet dnstt.service; then
        echo -e "\n${C_GREEN}✅ ÉXITO: ​​¡DNSTT se ha instalado y iniciado!${C_RESET}"
        show_dnstt_details
    else
        echo -e "\n${C_RED}❌ ERROR: El servicio DNSTT no pudo iniciarse.${C_RESET}"
        journalctl -u dnstt.service -n 15 --no-pager
    fi
}

uninstall_dnstt() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalación de DNSTT ---${C_RESET}"
    if [ ! -f "$DNSTT_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ DNSTT no parece estar instalado; se omite.${C_RESET}"
        return
    fi
    local confirm="y"
    if [[ "$UNINSTALL_MODE" != "silent" ]]; then
        read -p "👉 ¿Estás seguro de que quieres desinstalar DNSTT? Esto eliminará los registros DNS si fueron generados automáticamente. (y/n): " confirm
    fi
    if [[ "$confirm" != "y" ]]; then
        echo -e "\n${C_YELLOW}❌ Desinstalación cancelada.${C_RESET}"
        return
    fi
    echo -e "${C_BLUE}🛑 Detención y desactivación del servicio DNSTT...${C_RESET}"
    systemctl stop dnstt.service > /dev/null 2>&1
    systemctl disable dnstt.service > /dev/null 2>&1
    if [ -f "$DNSTT_CONFIG_FILE" ]; then
        source "$DNSTT_CONFIG_FILE"
        if [[ "$DNSTT_RECORDS_MANAGED" == "true" ]]; then
            echo -e "${C_BLUE}🗑️ Eliminación de registros DNS generados automáticamente...${C_RESET}"
            curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$TUNNEL_SUBDOMAIN/NS/" \
                 -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$NS_SUBDOMAIN/A/" \
                 -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            if [[ "$HAS_IPV6" == "true" ]]; then
                curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$NS_SUBDOMAIN/AAAA/" \
                     -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            fi
            echo -e "${C_GREEN}✅ Se han eliminado los registros DNS.${C_RESET}"
        else
            echo -e "${C_YELLOW}⚠️ Los registros DNS se configuraron manualmente. Por favor, elimínalos desde tu proveedor de DNS.${C_RESET}"
        fi
    fi
    echo -e "${C_BLUE}🗑️ Eliminación de archivos de servicio y binarios...${C_RESET}"
    rm -f "$DNSTT_SERVICE_FILE"
    rm -f "$DNSTT_BINARY"
    rm -rf "$DNSTT_KEYS_DIR"
    rm -f "$DNSTT_CONFIG_FILE"
    systemctl daemon-reload
    
    echo -e "${C_YELLOW}ℹ️ Restauración del resolutor DNS del sistema...${C_RESET}"
    chattr -i /etc/resolv.conf &>/dev/null
    systemctl unmask systemd-resolved &>/dev/null
    systemctl enable systemd-resolved &>/dev/null
    systemctl start systemd-resolved &>/dev/null

    echo -e "\n${C_GREEN}✅ DNSTT se ha desinstalado correctamente..${C_RESET}"
}

install_falcon_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- TewIanIx - (Websockets/Socks) ---${C_RESET}"
    
    if [ -f "$FALCONPROXY_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ El protocolo Websocket ya está instalado.${C_RESET}"
        if [ -f "$FALCONPROXY_CONFIG_FILE" ]; then
            source "$FALCONPROXY_CONFIG_FILE"
            echo -e "   Está configurado para ejecutarse en el puerto(s): ${C_YELLOW}$PORTS${C_RESET}"
            echo -e "   Versión instalada: ${C_YELLOW}${INSTALLED_VERSION:-Unknown}${C_RESET}"
        fi
        read -p "👉 ¿Quieres reinstalar/actualizar? (y/n): " confirm_reinstall
        if [[ "$confirm_reinstall" != "y" ]]; then return; fi
    fi

    echo -e "\n${C_BLUE}🌐 Obteniendo las versiones disponibles desde GitHub...${C_RESET}"
    local releases_json=$(curl -s "https://api.github.com/repos/FirewallFalconsLabs/FirewallFalcon-Manager/releases")
    if [[ -z "$releases_json" || "$releases_json" == "[]" ]]; then
        echo -e "${C_RED}❌ Error: No se pudieron obtener las versiones. Comprueba la conexión a internet o los límites de la API.${C_RESET}"
        return
    fi

    # Extract tag names
    mapfile -t versions < <(echo "$releases_json" | jq -r '.[].tag_name')
    
    if [ ${#versions[@]} -eq 0 ]; then
        echo -e "${C_RED}❌ No se han encontrado versiones en el repositorio.${C_RESET}"
        return
    fi

    echo -e "\n${C_CYAN}Selecciona una versión para instalar:${C_RESET}"
    for i in "${!versions[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${versions[$i]}"
    done
    echo -e "  ${C_RED} [ 0]${C_RESET} ↩️ Cancelar"
    
    local choice
    while true; do
        if ! read -r -p "👉 Introduce el número de versión [1]: " choice; then
            echo
            return
        fi
        choice=${choice:-1}
        if [[ "$choice" == "0" ]]; then return; fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#versions[@]}" ]; then
            SELECTED_VERSION="${versions[$((choice-1))]}"
            break
        else
            echo -e "${C_RED}❌ Selección no válida.${C_RESET}"
        fi
    done

    local ports
    read -p "👉 Introduce el/los puerto(s) para Falcon Proxy (e.g., 8080 or 8080 8888) [8080]: " ports
    ports=${ports:-8080}

    local port_array=($ports)
    for port in "${port_array[@]}"; do
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "\n${C_RED}❌ Número de puerto no válido: $port. Cancelando.${C_RESET}"
            return
        fi
        check_and_free_ports "$port" || return
        check_and_open_firewall_port "$port" tcp || return
    done

    echo -e "\n${C_GREEN}⚙️ Detección de la arquitectura del sistema...${C_RESET}"
    local arch=$(uname -m)
    local binary_name=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_name="falconproxy"
        echo -e "${C_BLUE}ℹ️ Detectada x86_64 (amd64) arquitectura.${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_name="falconproxyarm"
        echo -e "${C_BLUE}ℹ️ Detectada ARM64 arquitectura.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Arquitectura no compatible: $arch. No es posible instalar Falcon Proxy.${C_RESET}"
        return
    fi
    
    # Construct download URL based on selected version
    local download_url="https://github.com/FirewallFalconsLabs/FirewallFalcon-Manager/releases/download/$SELECTED_VERSION/$binary_name"

    echo -e "\n${C_GREEN}📥 Descargando Falcon Proxy $SELECTED_VERSION ($binary_name)...${C_RESET}"
    wget -q --show-progress -O "$FALCONPROXY_BINARY" "$download_url"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ No se pudo descargar el binario. Asegúrese de que la versión $SELECTED_VERSION tenga un activo '$binary_name'.${C_RESET}"
        return
    fi
    chmod +x "$FALCONPROXY_BINARY"

    echo -e "\n${C_GREEN}📝 Creación de un archivo de servicio de systemd...${C_RESET}"
    cat > "$FALCONPROXY_SERVICE_FILE" <<EOF
[Unit]
Description=Falcon Proxy ($SELECTED_VERSION)
After=network.target

[Service]
User=root
Type=simple
ExecStart=$FALCONPROXY_BINARY -p $ports
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF

    echo -e "\n${C_GREEN}💾 Guardando configuración...${C_RESET}"
    cat > "$FALCONPROXY_CONFIG_FILE" <<EOF
PORTS="$ports"
INSTALLED_VERSION="$SELECTED_VERSION"
EOF

    echo -e "\n${C_GREEN}▶️ Habilitar e iniciar el servicio Falcon Proxy...${C_RESET}"
    systemctl daemon-reload
    systemctl enable falconproxy.service
    systemctl restart falconproxy.service
    sleep 2
    
    if systemctl is-active --quiet falconproxy; then
        echo -e "\n${C_GREEN}✅ SUCCESS: Falcon Proxy $SELECTED_VERSION Está instalado y activo.${C_RESET}"
        echo -e "   Listening on port(s): ${C_YELLOW}$ports${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: El servicio Falcon Proxy no pudo iniciarse.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Se muestran las últimas 15 líneas del registro del servicio para fines de diagnóstico:${C_RESET}"
        journalctl -u falconproxy.service -n 15 --no-pager
    fi
}

uninstall_falcon_proxy() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalación de Falcon Proxy ---${C_RESET}"
    if [ ! -f "$FALCONPROXY_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ Falcon Proxy no está instalado; se omite.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Detención y deshabilitación del servicio Falcon Proxy...${C_RESET}"
    systemctl stop falconproxy.service >/dev/null 2>&1
    systemctl disable falconproxy.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Eliminando archivo de servicio...${C_RESET}"
    rm -f "$FALCONPROXY_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Eliminación de archivos binarios y de configuración...${C_RESET}"
    rm -f "$FALCONPROXY_BINARY"
    rm -f "$FALCONPROXY_CONFIG_FILE"
    echo -e "${C_GREEN}✅ Falcon Proxy se ha desinstalado correctamente..${C_RESET}"
}

# --- ZiVPN Installation Logic ---
install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Instalando ZiVPN (UDP/VPN) ---${C_RESET}"
    
    if [ -f "$ZIVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN ya está instalado.${C_RESET}"
        return
    fi

    if [ ! -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ ZiVPN requiere el backend badvpn (udpgw) para proporcionar acceso a Internet..${C_RESET}"
        echo -e "${C_GREEN}📦 Instalación automática del backend de badvpn...${C_RESET}"
        sleep 2
        install_badvpn
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Reanudación de la instalación de ZiVPN ---${C_RESET}"
    fi

    check_and_free_ports 5667 || return
    check_and_open_firewall_port 5667 udp || return
    check_and_open_firewall_port_range "6000:19999" udp || return

    echo -e "\n${C_GREEN}⚙️ Comprobación de la arquitectura del sistema...${C_RESET}"
    local arch=$(uname -m)
    local zivpn_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Arquitectura AMD64/x86_64 detectada.${C_RESET}"
    elif [[ "$arch" == "aarch64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
        echo -e "${C_BLUE}ℹ️ Arquitectura ARM64 detectada.${C_RESET}"
    elif [[ "$arch" == "armv7l" || "$arch" == "arm" ]]; then
         zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm"
         echo -e "${C_BLUE}ℹ️ Arquitectura ARM detectada.${C_RESET}"
    else
        echo -e "${C_RED}❌ Arquitectura no compatible: $arch${C_RESET}"
        return
    fi

    echo -e "\n${C_GREEN}📦 Descargando el binario de ZiVPN...${C_RESET}"
    if ! wget -q --show-progress -O "$ZIVPN_BIN" "$zivpn_url"; then
        echo -e "${C_RED}❌Error en la descarga. Comprueba la conexión a internet..${C_RESET}"
        return
    fi
    chmod +x "$ZIVPN_BIN"

    echo -e "\n${C_GREEN}⚙️ Configuración de ZIVPN...${C_RESET}"
    mkdir -p "$ZIVPN_DIR"
    
    # Generate Certificates
    echo -e "${C_BLUE}🔐 Generación de certificados autofirmados...${C_RESET}"
    if ! command -v openssl &>/dev/null; then
        ff_pkg_install openssl >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ No se pudo instalar OpenSSL para la generación de certificados de ZiVPN.${C_RESET}"
            return
        }
    fi
    
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
        -keyout "$ZIVPN_KEY_FILE" -out "$ZIVPN_CERT_FILE" 2>/dev/null

    if [ ! -f "$ZIVPN_CERT_FILE" ]; then
        echo -e "${C_RED}❌ No se pudieron generar los certificados.${C_RESET}"
        return
    fi

    # System Tuning
    echo -e "${C_BLUE}🔧 Ajuste de los parámetros de red del sistema...${C_RESET}"
    sysctl -w net.core.rmem_max=16777216 >/dev/null
    sysctl -w net.core.wmem_max=16777216 >/dev/null

    # Create Service
    echo -e "${C_BLUE}📝 Creando un archivo de servicio de systemd...${C_RESET}"
    cat <<EOF > "$ZIVPN_SERVICE_FILE"
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$ZIVPN_BIN server -c $ZIVPN_CONFIG_FILE
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    # Configure Passwords
    echo -e "\n${C_YELLOW}🔑 Configuración de contraseña de ZiVPN${C_RESET}"
    read -p "👉 Introduce contraseñas separadas por comas (ej, userio1,userio2) [Por defecto: 'zi']: " input_config
    
    if [ -n "$input_config" ]; then
        IFS=',' read -r -a config_array <<< "$input_config"
        # Ensure array format for JSON
        json_passwords=$(printf '"%s",' "${config_array[@]}")
        json_passwords="[${json_passwords%,}]"
    else
        json_passwords='["zi"]'
    fi

    # Create Config File
    cat <<EOF > "$ZIVPN_CONFIG_FILE"
{
  "listen": ":5667",
   "cert": "$ZIVPN_CERT_FILE",
   "key": "$ZIVPN_KEY_FILE",
   "obfs":"zivpn",
   "auth": {
    "mode": "passwords", 
    "config": $json_passwords
  }
}
EOF

    echo -e "\n${C_GREEN}🚀 Iniciando el servicio ZiVPN...${C_RESET}"
    systemctl daemon-reload
    systemctl enable zivpn.service
    systemctl start zivpn.service

    # Port Forwarding / Firewall
    echo -e "${C_BLUE}🔥 Configuración de reglas del firewall (Redirecting 6000-19999 -> 5667)...${C_RESET}"
    
    # Determine primary interface
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    if [ -n "$iface" ]; then
        iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || \
            iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
        # Note: IPTables rules are not persistent by default without iptables-persistent package
    else
        echo -e "${C_YELLOW}⚠️ No se pudo detectar la interfaz predeterminada para la redirección de IPTables..${C_RESET}"
    fi

    # Cleanup
    rm -f zi.sh zi2.sh 2>/dev/null

    if systemctl is-active --quiet zivpn.service; then
        echo -e "\n${C_GREEN}✅ ¡ZiVPN se ha instalado correctamente!${C_RESET}"
        echo -e "   - UDP Puerto: 5667 (Directo)"
        echo -e "   - UDP Puertos: 6000-19999 (Reenviado)"
    else
        echo -e "\n${C_RED}❌ El servicio ZiVPN no pudo iniciarse. Revise los registros: journalctl -u zivpn.service${C_RESET}"
    fi
}

uninstall_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalar ZiVPN ---${C_RESET}"
    
    if [ ! -f "$ZIVPN_SERVICE_FILE" ] && [ ! -f "$ZIVPN_BIN" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN no parece estar instalado.${C_RESET}"
        return
    fi

    read -p "👉 ¿Estás seguro de que quieres desinstalar ZiVPN? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "${C_YELLOW}Cancelled.${C_RESET}"; return; fi

    echo -e "\n${C_BLUE}🛑 Detención de servicios...${C_RESET}"
    systemctl stop zivpn.service 2>/dev/null
    systemctl disable zivpn.service 2>/dev/null

    local iface
    iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    if [ -n "$iface" ]; then
        iptables -t nat -D PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true
    fi
    
    echo -e "${C_BLUE}🗑️ Eliminación de archivos...${C_RESET}"
    rm -f "$ZIVPN_SERVICE_FILE"
    rm -rf "$ZIVPN_DIR"
    rm -f "$ZIVPN_BIN"
    
    systemctl daemon-reload
    
    # Clean cache (from original uninstall script logic)
    echo -e "${C_BLUE}🧹 Limpiando la memoria caché...${C_RESET}"
    sync; echo 3 > /proc/sys/vm/drop_caches

    echo -e "\n${C_GREEN}✅ ZiVPN desinstalado correctamente.${C_RESET}"
}

purge_nginx() {
    local mode="$1"
    if [[ "$mode" != "silent" ]]; then
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🔥 Eliminar el proxy interno de Nginx ---${C_RESET}"
        if ! command -v nginx &> /dev/null; then
            rm -f "$NGINX_PORTS_FILE"
            echo -e "\n${C_YELLOW}ℹ️ Nginx no está instalado. Nada que hacer..${C_RESET}"
            return
        fi
        echo -e "\n${C_YELLOW}⚠️ Esto elimina el proxy interno de Nginx en ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"
        if systemctl is-active --quiet haproxy; then
            echo -e "${C_YELLOW}⚠️ HAProxy permanecerá instalado, pero el enrutamiento de la carga útil web desde ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} se detendrá hasta que reinstales la pila.${C_RESET}"
        fi
        read -p "👉 ¿Continuar y eliminar Nginx? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "\n${C_YELLOW}❌ Desinstalación cancelada.${C_RESET}"
            return
        fi
    fi
    echo -e "\n${C_BLUE}🛑 Deteniendo el servicio Nginx...${C_RESET}"
    systemctl stop nginx >/dev/null 2>&1
    systemctl disable nginx >/dev/null 2>&1
    echo -e "\n${C_BLUE}🗑️ Eliminar completamente los paquetes de Nginx...${C_RESET}"
    ff_pkg_purge nginx nginx-common >/dev/null 2>&1
    ff_pkg_autoremove
    echo -e "\n${C_BLUE}🗑️ Eliminación de archivos residuales...${C_RESET}"
    rm -f /etc/ssl/certs/nginx-selfsigned.pem
    rm -f /etc/ssl/private/nginx-selfsigned.key
    rm -rf /etc/nginx
    rm -f "${NGINX_CONFIG_FILE}.bak"
    rm -f "${NGINX_CONFIG_FILE}.bak.certbot"
    rm -f "${NGINX_CONFIG_FILE}.bak.selfsigned"
    rm -f "${NGINX_CONFIG_FILE}.bak.firewallfalcon"
    rm -f "$NGINX_PORTS_FILE"
    if [[ "$mode" != "silent" ]]; then
        echo -e "\n${C_GREEN}✅ Se ha eliminado el proxy interno de Nginx. Se conservaron los certificados compartidos de FirewallFalcon.${C_RESET}"
    fi
}

install_nginx_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Reconfiguración del proxy interno de Nginx (8880/8443) ---${C_RESET}"
    echo -e "\n${C_CYAN}Esto mantiene a HAProxy en ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} y redirige al proxy interno Nginx en ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"

    if [ ! -s "$SSL_CERT_FILE" ] || [ ! -s "$SSL_CERT_CHAIN_FILE" ] || [ ! -s "$SSL_CERT_KEY_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ No se encontró ningún certificado compartido de FirewallFalcon.${C_RESET}"
        echo -e "${C_DIM}Ejecutar el instalador completo de HAProxy para el perímetro, de modo que el certificado y ambos servicios permanezcan alineados..${C_RESET}"
        install_ssl_tunnel
        return
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"
    ensure_edge_stack_packages || return

    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 1

    check_and_free_ports \
        "$EDGE_PUBLIC_HTTP_PORT" \
        "$EDGE_PUBLIC_TLS_PORT" \
        "$NGINX_INTERNAL_HTTP_PORT" \
        "$NGINX_INTERNAL_TLS_PORT" \
        "$HAPROXY_INTERNAL_DECRYPT_PORT" || return

    check_and_open_firewall_port "$EDGE_PUBLIC_HTTP_PORT" tcp || return
    check_and_open_firewall_port "$EDGE_PUBLIC_TLS_PORT" tcp || return

    load_edge_cert_info
    local server_name="${EDGE_DOMAIN:-$(detect_preferred_host)}"
    [[ -z "$server_name" ]] && server_name="_"

    configure_edge_stack "$server_name" || return

    echo -e "\n${C_GREEN}✅ Proxy interno de Nginx reconfigurado correctamente.${C_RESET}"
    echo -e "   • HAProxy de borde público: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Nginx interno: ${C_YELLOW}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
}

request_certbot_ssl() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 Certificado de Certbot compartido (HAProxy + Nginx) ---${C_RESET}"
    echo -e "\n${C_DIM}Esto reemplazará el certificado compartido utilizado por HAProxy en ${EDGE_PUBLIC_TLS_PORT} y por el Nginx interno en ${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"
    ensure_edge_stack_packages || return
    load_edge_cert_info

    local preferred_host
    local default_domain=""
    local domain_name
    local email

    preferred_host=$(detect_preferred_host)
    if [[ -n "$EDGE_DOMAIN" ]] && ! _is_valid_ipv4 "$EDGE_DOMAIN"; then
        default_domain="$EDGE_DOMAIN"
    elif [[ -n "$preferred_host" ]] && ! _is_valid_ipv4 "$preferred_host"; then
        default_domain="$preferred_host"
    fi

    if [[ -n "$default_domain" ]]; then
        read -p "👉 Introduce tu nombre de dominio [$default_domain]: " domain_name
        domain_name=${domain_name:-$default_domain}
    else
        read -p "👉 Introduce tu nombre de dominio (p. ej., tewianix.xyz): " domain_name
    fi
    if [[ -z "$domain_name" ]]; then
        echo -e "\n${C_RED}❌ El nombre de dominio no puede estar vacío.${C_RESET}"
        return
    fi
    if _is_valid_ipv4 "$domain_name"; then
        echo -e "\n${C_RED}❌Certbot requiere un nombre de dominio real, no una dirección IP sin procesar.${C_RESET}"
        return
    fi

    read -p "👉 Introduce tu correo electrónico para Let's Encrypt [${EDGE_EMAIL}]: " email
    email=${email:-$EDGE_EMAIL}
    if [[ -z "$email" ]]; then
        echo -e "\n${C_RED}❌ La dirección de correo electrónico no puede estar vacía.${C_RESET}"
        return
    fi

    check_and_open_firewall_port "$EDGE_PUBLIC_HTTP_PORT" tcp || return
    check_and_open_firewall_port "$EDGE_PUBLIC_TLS_PORT" tcp || return

    obtain_certbot_edge_cert "$domain_name" "$email" || return
    configure_edge_stack "$domain_name" || return

    echo -e "\n${C_GREEN}✅ Shared Certbot certificate applied successfully.${C_RESET}"
    echo -e "   • Dominio: ${C_YELLOW}${domain_name}${C_RESET}"
    echo -e "   • Borde público: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
}

nginx_proxy_menu() {
    while true; do
    show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Gestión de proxy interno de Nginx ---${C_RESET}"

    local nginx_status="${C_STATUS_I}Inactive${C_RESET}"
    local haproxy_status="${C_STATUS_I}Inactive${C_RESET}"
    if systemctl is-active --quiet nginx; then
        nginx_status="${C_STATUS_A}Active${C_RESET}"
    fi
    if systemctl is-active --quiet haproxy; then
        haproxy_status="${C_STATUS_A}Active${C_RESET}"
    fi

    load_edge_cert_info
    local cert_info="${EDGE_CERT_MODE:-Not configured}"
    if [[ -n "$EDGE_DOMAIN" ]]; then
        cert_info="${cert_info} - ${EDGE_DOMAIN}"
    fi

    echo -e "\n${C_WHITE}Nginx:${C_RESET} ${nginx_status}"
    echo -e "${C_WHITE}HAProxy:${C_RESET} ${haproxy_status}"
    echo -e "${C_DIM}Public Edge: ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} | Internal Nginx: ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "${C_DIM}Shared Certificate: ${cert_info}${C_RESET}"

    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    
    if systemctl is-active --quiet nginx; then
         printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🛑 Detener el servicio Nginx"
         printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔄 volver a arrancar HAProxy + Nginx Stack"
         printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "⚙️ Reinstalar/Reconfigurar Edge Stack"
         printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "🔒 Cambiar/Renovar compartido SSL (Certbot)"
         printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "🔥 Desinstalar/Eliminar Nginx"
    else
         printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "▶️ Iniciar el servicio Nginx"
         printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "⚙️ Instalar/Configurar Edge Stack"
         printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "🔒 Cambiar/Renovar compartido SSL (Certbot)"
         printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "🔥 Desinstalar/Eliminar Nginx"
    fi

    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Regresar"
    echo
    if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Ingresa una opción: "${C_RESET})" choice; then
        echo
        return
    fi
    
    case $choice in
        1) 
            if systemctl is-active --quiet nginx; then
                echo -e "\n${C_BLUE}🛑 Detención de Nginx...${C_RESET}"
                systemctl stop nginx
                echo -e "${C_GREEN}✅ Nginx se ha detenido.${C_RESET}"
                if systemctl is-active --quiet haproxy; then
                    echo -e "${C_YELLOW}⚠️ HAProxy sigue en ejecución, pero el tráfico web que depende del Nginx interno no funcionará hasta que Nginx se inicie de nuevo.${C_RESET}"
                fi
            else
                echo -e "\n${C_BLUE}▶️ Iniciando Nginx...${C_RESET}"
                systemctl start nginx
                if systemctl is-active --quiet nginx; then
                    echo -e "${C_GREEN}✅ Nginx iniciado.${C_RESET}"
                else
                    echo -e "${C_RED}❌ No se pudo iniciar Nginx.${C_RESET}"
                fi
            fi
            press_enter
            ;;
        2)
            echo -e "\n${C_BLUE}🔄 Reiniciando Nginx y HAProxy...${C_RESET}"
            local restart_ok=true
            systemctl restart nginx || restart_ok=false
            if command -v haproxy &> /dev/null; then
                systemctl restart haproxy || restart_ok=false
            else
                restart_ok=false
            fi
            if $restart_ok && systemctl is-active --quiet nginx && systemctl is-active --quiet haproxy; then
                echo -e "${C_GREEN}✅ HAProxy + Nginx stack reiniciado.${C_RESET}"
            else
                echo -e "${C_RED}❌ Uno o más servicios no pudieron reiniciarse.${C_RESET}"
            fi
            press_enter
            ;;
        3) 
             install_nginx_proxy; press_enter
             ;;
        4)
             request_certbot_ssl; press_enter
             ;;
        5)
             purge_nginx; press_enter
             ;;
        0) return ;;
        *) invalid_option ;;
    esac
    done
}

install_panel_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💻 Instalar X-UI / 3X-UI Panel ---${C_RESET}"
    echo -e "\n${C_CYAN}Seleccione qué panel instalar.:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-45s %s\n" "🚀 3X-UI Panel (MHSanaei)" "${C_STATUS_A}⭐ Default${C_RESET}"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-45s %s\n" "📦 X-UI Panel (alireza0)" ""
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancelar"
    echo
    read -p "👉 Seleccionar panel [1]: " panel_choice
    panel_choice=${panel_choice:-1}
    case $panel_choice in
        1) install_3xui_panel ;;
        2) install_xui_panel ;;
        0) echo -e "\n${C_YELLOW}❌ Instalación cancelada.${C_RESET}" ;;
        *) echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}" ;;
    esac
}

install_3xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Instalar 3X-UI Panel ---${C_RESET}"
    echo -e "\nEsto descargará y ejecutará el script de instalación oficial de 3X-UI (MHSanaei)."
    echo -e "Elige una opción de instalación:\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} %-40s\n" "Instala la versión más reciente de 3X-UI"
    printf "  ${C_GREEN}[ 2]${C_RESET} %-40s\n" "Instalar una versión específica de 3X-UI"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancelar instalación"
    echo
    read -p "👉 Ingresa una opción: " choice
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚙️ Instalación de la última versión...${C_RESET}"
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        2)
            read -p "👉 Enter the version to install (e.g., 2.4.5): " version
            if [[ -z "$version" ]]; then
                echo -e "\n${C_RED}❌ El número de versión no puede estar vacío.${C_RESET}"
                return
            fi
            echo -e "\n${C_BLUE}⚙️ Instalando versión ${C_YELLOW}$version...${C_RESET}"
            bash <(curl -Ls "https://raw.githubusercontent.com/mhsanaei/3x-ui/v$version/install.sh") "v$version"
            ;;
        0)
            echo -e "\n${C_YELLOW}❌ Instalación cancelada.${C_RESET}"
            ;;
        *)
            echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}"
            ;;
    esac
}

install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📦 Instalar el panel X-UI (versión anterior) ---${C_RESET}"
    echo -e "\nEsto descargará y ejecutará el script de instalación de X-UI (alireza0)."
    echo -e "Elige una opción de instalación:\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} %-40s\n" "Instalar la última versión de X-UI."
    printf "  ${C_GREEN}[ 2]${C_RESET} %-40s\n" "Instalar una versión específica de X-UI"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancelar instalación"
    echo
    read -p "👉 Ingresa una opción: " choice
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚙️ Instalación de la última versión...${C_RESET}"
            bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
            ;;
        2)
            read -p "👉 Ingrese la versión que desea instalar (e.g., 1.8.0): " version
            if [[ -z "$version" ]]; then
                echo -e "\n${C_RED}❌ El número de versión no puede estar vacío.${C_RESET}"
                return
            fi
            echo -e "\n${C_BLUE}⚙️ Instalando versión ${C_YELLOW}$version...${C_RESET}"
            VERSION=$version bash <(curl -Ls "https://raw.githubusercontent.com/alireza0/x-ui/$version/install.sh") "$version"
            ;;
        0)
            echo -e "\n${C_YELLOW}❌ Instalación cancelada.${C_RESET}"
            ;;
        *)
            echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}"
            ;;
    esac
}

uninstall_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalar X-UI / 3X-UI Panel ---${C_RESET}"
    if ! command -v x-ui &> /dev/null; then
        echo -e "\n${C_YELLOW}ℹ️ No parece haber ningún panel X-UI/3X-UI instalado.${C_RESET}"
        return
    fi
    read -p "👉 ¿Estás seguro de que quieres desinstalar completamente X-UI/3X-UI? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "\n${C_BLUE}⚙️ Ejecutar primero el desinstalador predeterminado...${C_RESET}"
        x-ui uninstall >/dev/null 2>&1
        echo -e "\n${C_BLUE}🧹 Realizar una limpieza completa para garantizar la eliminación total.${C_RESET}"
        echo " - Deteniendo y deshabilitando el servicio x-ui..."
        systemctl stop x-ui >/dev/null 2>&1
        systemctl disable x-ui >/dev/null 2>&1
        echo " - Eliminando archivos y directorios de x-ui..."
        rm -f /etc/systemd/system/x-ui.service
        rm -f /usr/local/bin/x-ui
        rm -rf /usr/local/x-ui/
        rm -rf /etc/x-ui/
        echo " - Reloading systemd daemon..."
        systemctl daemon-reload
        echo -e "\n${C_GREEN}✅ X-UI/3X-UI se ha desinstalado por completo.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Desinstalación cancelada.${C_RESET}"
    fi
}

refresh_ssh_session_cache() {
    local now db_mtime
    printf -v now '%(%s)T' -1
    db_mtime=$(stat -c %Y "$DB_FILE" 2>/dev/null || echo 0)

    if (( SSH_SESSION_CACHE_TS > 0 && now - SSH_SESSION_CACHE_TS < SSH_SESSION_CACHE_TTL && db_mtime == SSH_SESSION_CACHE_DB_MTIME )); then
        return
    fi

    SSH_SESSION_COUNTS=()
    SSH_SESSION_PIDS=()
    SSH_SESSION_TOTAL=0
    SSH_SESSION_CACHE_DB_MTIME=$db_mtime

    if [[ ! -s "$DB_FILE" ]]; then
        SSH_SESSION_CACHE_TS=$now
        return
    fi

    local -A managed_user_lookup=()
    local -A uid_user_lookup=()
    local -A session_pids=()
    local -A loginuid_pids=()
    local managed_user system_user system_uid ssh_pid ssh_owner candidate_user login_uid

    while IFS=: read -r managed_user _rest; do
        [[ -n "$managed_user" && "$managed_user" != \#* ]] && managed_user_lookup["$managed_user"]=1
    done < "$DB_FILE"

    while IFS=: read -r system_user _ system_uid _rest; do
        [[ -n "$system_user" && "$system_uid" =~ ^[0-9]+$ ]] && uid_user_lookup["$system_uid"]="$system_user"
    done < /etc/passwd

    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue

        # Method 1: process owner matches a managed user directly
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" && -n "${managed_user_lookup[$ssh_owner]+x}" ]]; then
            session_pids["$ssh_owner"]+="$ssh_pid "
        fi
    done < <(ps -C sshd,sshd-session -o pid=,user= 2>/dev/null)

    # Method 2: kernel loginuid with comm/PPid validation (more robust — matches limiter logic)
    local p pid_dir pid_num comm ppid_val session_user
    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""
        read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue

        candidate_user="${uid_user_lookup[$login_uid]}"
        [[ -n "$candidate_user" && -n "${managed_user_lookup[$candidate_user]+x}" ]] || continue

        pid_dir=$(dirname "$p")
        pid_num=$(basename "$pid_dir")
        comm=""
        read -r comm < "$pid_dir/comm" 2>/dev/null || comm=""
        [[ "$comm" == "sshd" || "$comm" == "sshd-session" ]] || continue

        # Filter out the master sshd process (PPid=1)
        ppid_val=""
        while read -r key value; do
            [[ "$key" == "PPid:" ]] && { ppid_val="$value"; break; }
        done < "$pid_dir/status" 2>/dev/null
        [[ "$ppid_val" == "1" ]] && continue

        loginuid_pids["$candidate_user"]+="$pid_num "
    done

    local user pid
    for user in "${!managed_user_lookup[@]}"; do
        # CRITICAL: unset before declare to reset per-user (bash declare is function-scoped)
        unset unique_pids
        local -A unique_pids=()

        # Use ONLY ps-based session_pids for accurate counting.
        # loginuid_pids can double-count (root-owned sshd has user's loginuid on Ubuntu 24)
        for pid in ${session_pids[$user]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        SSH_SESSION_COUNTS["$user"]=${#unique_pids[@]}
        if (( ${#unique_pids[@]} > 0 )); then
            for pid in "${!unique_pids[@]}"; do
                SSH_SESSION_PIDS["$user"]+="$pid "
            done
            SSH_SESSION_TOTAL=$((SSH_SESSION_TOTAL + ${#unique_pids[@]}))
        fi
    done

    SSH_SESSION_CACHE_TS=$now
}

count_managed_online_sessions() {
    refresh_ssh_session_cache
    echo "$SSH_SESSION_TOTAL"
}

invalidate_banner_cache() {
    BANNER_CACHE_TS=0
    SSH_SESSION_CACHE_TS=0
}

refresh_banner_cache() {
    local now
    printf -v now '%(%s)T' -1
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then
        return
    fi

    if [[ -z "$BANNER_CACHE_OS_NAME" ]]; then
        BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    fi
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Desconocido")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    if [[ -s "$DB_FILE" ]]; then
        BANNER_CACHE_TOTAL_USERS=0
        while IFS=: read -r _u _rest; do
            [[ -n "$_u" && "$_u" != \#* ]] && (( BANNER_CACHE_TOTAL_USERS++ ))
        done < "$DB_FILE"
    else
        BANNER_CACHE_TOTAL_USERS=0
    fi
    BANNER_CACHE_ONLINE_USERS=$(count_managed_online_sessions)
    BANNER_CACHE_TS=$now
}

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_TITLE}   TewIaniX SSH ${C_RESET}${C_DIM}| v1.3.0 Fixx${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Activity: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online Sessions: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "User" "${BANNER_CACHE_TOTAL_USERS} managed account" "Sys Load (1m): ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

protocol_menu() {
    while true; do
        show_banner
        local badvpn_status; if systemctl is-active --quiet badvpn; then badvpn_status="${C_STATUS_A}(Activo)${C_RESET}"; else badvpn_status="${C_STATUS_I}(Inactivo)${C_RESET}"; fi
        local udp_custom_status; if systemctl is-active --quiet udp-custom; then udp_custom_status="${C_STATUS_A}(Activo)${C_RESET}"; else udp_custom_status="${C_STATUS_I}(Inactivo)${C_RESET}"; fi
        local zivpn_status; if systemctl is-active --quiet zivpn.service; then zivpn_status="${C_STATUS_A}(Activo)${C_RESET}"; else zivpn_status="${C_STATUS_I}(Inactivo)${C_RESET}"; fi
        
        local ssl_tunnel_text="HAProxy Edge Stack (80/443)"
        local ssl_tunnel_status="${C_STATUS_I}(Inactivo)${C_RESET}"
        if systemctl is-active --quiet haproxy; then
            ssl_tunnel_status="${C_STATUS_A}(Activo)${C_RESET}"
        fi
        
        local dnstt_status; if systemctl is-active --quiet dnstt.service; then dnstt_status="${C_STATUS_A}(Activo)${C_RESET}"; else dnstt_status="${C_STATUS_I}(Inactivo)${C_RESET}"; fi
        
        local falconproxy_status="${C_STATUS_I}(Inactivo)${C_RESET}"
        local falconproxy_ports=""
        if systemctl is-active --quiet falconproxy; then
            if [ -f "$FALCONPROXY_CONFIG_FILE" ]; then source "$FALCONPROXY_CONFIG_FILE"; fi
            falconproxy_ports=" ($PORTS)"
            falconproxy_status="${C_STATUS_A}(Activo - ${INSTALLED_VERSION:-latest})${C_RESET}"
        fi

        local nginx_status; if systemctl is-active --quiet nginx; then nginx_status="${C_STATUS_A}(Activo)${C_RESET}"; else nginx_status="${C_STATUS_I}(Inactivo)${C_RESET}"; fi
        local xui_status; if command -v x-ui &> /dev/null; then xui_status="${C_STATUS_A}(Instalado)${C_RESET}"; else xui_status="${C_STATUS_I}(No Instalado)${C_RESET}"; fi  # 3X-UI uses same 'x-ui' binary name
        
        echo -e "\n   ${C_TITLE}══════════════[ ${C_BOLD}🔌 GESTIÓN DE PROTOCOLOS Y PANELES ${C_RESET}${C_TITLE}]══════════════${C_RESET}"
        echo -e "     ${C_ACCENT}--- PROTOCOLOS DE TUNELIZACIÓN---${C_RESET}"
        printf "     ${C_CHOICE}[ 1]${C_RESET} %-45s %s\n" "🚀 Instalar badvpn (UDP 7300)" "$badvpn_status"
        printf "     ${C_CHOICE}[ 2]${C_RESET} %-45s\n" "🗑️ Desinstalar badvpn"
        printf "     ${C_CHOICE}[ 3]${C_RESET} %-45s %s\n" "🚀 Instalar udp-custom" "$udp_custom_status"
        printf "     ${C_CHOICE}[ 4]${C_RESET} %-45s\n" "🗑️ Desinstalar udp-custom"
        printf "     ${C_CHOICE}[ 5]${C_RESET} %-45s %s\n" "🔒 Instalar ${ssl_tunnel_text}" "$ssl_tunnel_status"
        printf "     ${C_CHOICE}[ 6]${C_RESET} %-45s\n" "🗑️ Desinstalar HAProxy Edge Stack"
        printf "     ${C_CHOICE}[ 7]${C_RESET} %-45s %s\n" "📡 Instalar/Ver DNSTT (Port 53)" "$dnstt_status"
        printf "     ${C_CHOICE}[ 8]${C_RESET} %-45s\n" "🗑️ Desinstalar DNSTT"
        printf "     ${C_CHOICE}[ 9]${C_RESET} %-45s %s\n" "🦅 Instalar Falcon Proxy (Select Version)" "$falconproxy_status"
        printf "     ${C_CHOICE}[10]${C_RESET} %-45s\n" "🗑️ Desinstalar Falcon Proxy"
        printf "     ${C_CHOICE}[11]${C_RESET} %-45s %s\n" "🌐 Instalar/Administrar interno Nginx (8880/8443)" "$nginx_status"
        printf "     ${C_CHOICE}[14]${C_RESET} %-45s %s\n" "🛡️ Instalar ZiVPN (UDP 5667)" "$zivpn_status"
        printf "     ${C_CHOICE}[15]${C_RESET} %-45s\n" "🗑️ Desinstalar ZiVPN"
        
        echo -e "     ${C_ACCENT}--- 💻 MANAGEMENT PANELS ---${C_RESET}"
        printf "     ${C_CHOICE}[12]${C_RESET} %-45s %s\n" "💻 Instalar X-UI / 3X-UI Panel" "$xui_status"
        printf "     ${C_CHOICE}[13]${C_RESET} %-45s\n" "🗑️ Desinstalar X-UI / 3X-UI Panel"
        
        echo -e "   ${C_DIM}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${C_RESET}"
        echo -e "     ${C_WARN}[ 0]${C_RESET} ↩️ Regresar"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Ingresa una opción: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1) install_badvpn; press_enter ;; 2) uninstall_badvpn; press_enter ;;
            3) install_udp_custom; press_enter ;; 4) uninstall_udp_custom; press_enter ;;
            5) install_ssl_tunnel; press_enter ;; 6) uninstall_ssl_tunnel; press_enter ;;
            7) install_dnstt; press_enter ;; 8) uninstall_dnstt; press_enter ;;
            9) install_falcon_proxy; press_enter ;; 10) uninstall_falcon_proxy; press_enter ;;
            11) nginx_proxy_menu ;;
            12) install_panel_menu; press_enter ;; 13) uninstall_xui_panel; press_enter ;;
            14) install_zivpn; press_enter ;; 15) uninstall_zivpn; press_enter ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}


# ====================================================================
# --- Web Control Panel Functions ---
# ====================================================================

install_web_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Instalación del panel de control web ---${C_RESET}"
    
    if [ -f "$PANEL_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ El panel web ya está instalado.${C_RESET}"
        show_panel_credentials
        return
    fi
    
    # Check Python 3
    if ! command -v python3 &>/dev/null; then
        echo -e "${C_RED}❌ Se requiere Python 3, pero no está instalado..${C_RESET}"
        echo -e "${C_YELLOW}Instalando python3...${C_RESET}"
        ff_pkg_install python3 || { echo -e "${C_RED}❌ No se pudo instalar python3.${C_RESET}"; return; }
    fi
    
    echo -e "${C_BLUE}🔎 Checking if port $PANEL_PORT is available...${C_RESET}"
    check_and_free_ports "$PANEL_PORT" || return
    check_and_open_firewall_port "$PANEL_PORT" tcp || return
    
    # Generate random credentials and secret URL path
    local panel_user
    panel_user=$(tr -dc 'a-z' < /dev/urandom | head -c 4)$(tr -dc '0-9' < /dev/urandom | head -c 4)
    local panel_pass
    panel_pass=$(tr -dc 'A-Za-z0-9@#$' < /dev/urandom | head -c 16)
    local panel_pass_hash
    panel_pass_hash=$(echo -n "$panel_pass" | sha256sum | awk '{print $1}')
    local panel_secret
    panel_secret="panel_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
    
    echo -e "${C_BLUE}📥 Descargando archivos del panel...${C_RESET}"
    mkdir -p "$PANEL_HTML_DIR"
    
    # Download backend
    curl -sL "$PANEL_REPO_BASE/panel.py" -o "$PANEL_SCRIPT"
    if [ $? -ne 0 ] || [ ! -s "$PANEL_SCRIPT" ]; then
        echo -e "${C_RED}❌ No se pudo descargar panel backend.${C_RESET}"
        return
    fi
    chmod +x "$PANEL_SCRIPT"
    sed -i 's/\r$//' "$PANEL_SCRIPT" 2>/dev/null
    
    # Download frontend
    curl -sL "$PANEL_REPO_BASE/index.html" -o "$PANEL_HTML_FILE"
    if [ $? -ne 0 ] || [ ! -s "$PANEL_HTML_FILE" ]; then
        echo -e "${C_RED}❌ No se pudo descargar panel frontend.${C_RESET}"
        return
    fi
    
    # Save credentials
    cat > "$PANEL_CONF" <<-PEOF
PANEL_USER="$panel_user"
PANEL_PASS_HASH="$panel_pass_hash"
PANEL_PASS_PLAIN="$panel_pass"
PANEL_SECRET="$panel_secret"
PEOF
    chmod 600 "$PANEL_CONF"
    
    # Create systemd service
    cat > "$PANEL_SERVICE_FILE" <<-SEOF
[Unit]
Description=FirewallFalcon Web Control Panel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $PANEL_SCRIPT
Restart=always
RestartSec=5
Nice=10
MemoryHigh=64M
MemoryMax=96M
Environment=PANEL_PORT=$PANEL_PORT

[Install]
WantedBy=multi-user.target
SEOF
    
    systemctl daemon-reload
    systemctl enable firewallfalcon-panel &>/dev/null
    systemctl start firewallfalcon-panel &>/dev/null
    sleep 2
    
    if systemctl is-active --quiet firewallfalcon-panel; then
        local server_ip
        server_ip=$(curl -s -4 --max-time 3 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
        
        clear; show_banner
        echo -e "${C_GREEN}=====================================================${C_RESET}"
        echo -e "${C_GREEN}     ✅ ¡Panel de control web instalado correctamente!     ${C_RESET}"
        echo -e "${C_GREEN}=====================================================${C_RESET}"
        echo -e "\n${C_CYAN}  🌐 Panel URL:${C_RESET}    ${C_YELLOW}http://${server_ip}:${PANEL_PORT}/${panel_secret}${C_RESET}"
        echo -e "${C_CYAN}  👤 Usuario:${C_RESET}     ${C_YELLOW}${panel_user}${C_RESET}"
        echo -e "${C_CYAN}  🔑 Contraseña:${C_RESET}     ${C_YELLOW}${panel_pass}${C_RESET}"
        echo -e "${C_CYAN}  🔐 Sendero secreto:${C_RESET}   ${C_YELLOW}/${panel_secret}${C_RESET}"
        echo -e "\n${C_DIM}  ¡Guarda estas credenciales! Podrás verlas más tarde desde la opción [21] > [3].${C_RESET}"
    else
        echo -e "\n${C_RED}❌ El servicio del panel no pudo iniciarse. Comprobando los registros.:${C_RESET}"
        journalctl -u firewallfalcon-panel -n 15 --no-pager
    fi
}

uninstall_web_panel() {
    if [ ! -f "$PANEL_SERVICE_FILE" ]; then
        if [[ "$UNINSTALL_MODE" != "silent" ]]; then
            echo -e "${C_YELLOW}ℹ️ El panel web no está instalado.${C_RESET}"
        fi
        return
    fi
    
    if [[ "$UNINSTALL_MODE" != "silent" ]]; then
        echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Desinstalación del panel de control web ---${C_RESET}"
        read -p "👉 ¿Estás seguro de que quieres desinstalar el panel web? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo -e "\n${C_YELLOW}❌ Desinstalación cancelada.${C_RESET}"
            return
        fi
    fi
    
    echo -e "${C_BLUE}🛑 Deteniendo y eliminando el servicio Web Panel...${C_RESET}"
    systemctl stop firewallfalcon-panel &>/dev/null
    systemctl disable firewallfalcon-panel &>/dev/null
    rm -f "$PANEL_SERVICE_FILE"
    rm -f "$PANEL_SCRIPT"
    rm -rf "$PANEL_HTML_DIR"
    rm -f "$PANEL_CONF"
    systemctl daemon-reload
    
    echo -e "${C_GREEN}✅ El panel web se ha desinstalado..${C_RESET}"
}

show_panel_credentials() {
    if [ ! -f "$PANEL_CONF" ]; then
        echo -e "\n${C_YELLOW}ℹ️ El panel web no está instalado.${C_RESET}"
        return
    fi
    
    source "$PANEL_CONF"
    local server_ip secret_suffix
    server_ip=$(curl -s -4 --max-time 3 icanhazip.com 2>/dev/null || echo "TU_SERVIDOR_IP")
    secret_suffix=""
    if [[ -n "$PANEL_SECRET" ]]; then
        secret_suffix="/${PANEL_SECRET}"
    fi
    
    echo -e "\n${C_GREEN}=====================================================${C_RESET}"
    echo -e "${C_GREEN}         🌐 Credenciales del panel web                    ${C_RESET}"
    echo -e "${C_GREEN}=====================================================${C_RESET}"
    echo -e "\n${C_CYAN}  🌐 Panel URL:${C_RESET}    ${C_YELLOW}http://${server_ip}:${PANEL_PORT}${secret_suffix}${C_RESET}"
    echo -e "${C_CYAN}  👤 Usuario:${C_RESET}     ${C_YELLOW}${PANEL_USER}${C_RESET}"
    echo -e "${C_CYAN}  🔑 Contraseña:${C_RESET}     ${C_YELLOW}${PANEL_PASS_PLAIN}${C_RESET}"
    if [[ -n "$PANEL_SECRET" ]]; then
        echo -e "${C_CYAN}  🔐 Sendero secreto:${C_RESET}   ${C_YELLOW}/${PANEL_SECRET}${C_RESET}"
    fi
    
    if systemctl is-active --quiet firewallfalcon-panel 2>/dev/null; then
        echo -e "\n${C_CYAN}  📡 Status:${C_RESET}       ${C_GREEN}🟢 Activo${C_RESET}"
    else
        echo -e "\n${C_CYAN}  📡 Status:${C_RESET}       ${C_RED}🔴 Detenido${C_RESET}"
    fi
}

change_panel_credentials() {
    if [ ! -f "$PANEL_CONF" ]; then
        echo -e "\n${C_YELLOW}ℹ️ El panel web no está instalado.${C_RESET}"
        return
    fi
    
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 Cambiar las credenciales y la ruta secreta del panel web ---${C_RESET}"
    show_panel_credentials
    
    echo ""
    read -p "👉 Ingrese un nuevo nombre de usuario (o Enter para mantener actualizado): " new_user
    read -p "🔑 Introduce una nueva contraseña (o Enter para generarla automáticamente): " new_pass
    read -p "🔐 Introduce una nueva ruta URL secreta (ej, secret123; o Enter para mantener la actual): " new_secret
    
    source "$PANEL_CONF"
    
    if [[ -z "$new_user" ]]; then
        new_user="$PANEL_USER"
    fi
    if [[ -z "$new_pass" ]]; then
        new_pass=$(tr -dc 'A-Za-z0-9@#$' < /dev/urandom | head -c 16)
        echo -e "${C_GREEN}🔑 Contraseña generada automáticamente: ${C_YELLOW}$new_pass${C_RESET}"
    fi
    if [[ -z "$new_secret" ]]; then
        new_secret="${PANEL_SECRET:-panel_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)}"
    fi
    new_secret=$(echo "$new_secret" | sed 's/^\///')
    
    local new_hash
    new_hash=$(echo -n "$new_pass" | sha256sum | awk '{print $1}')
    
    cat > "$PANEL_CONF" <<-PEOF
PANEL_USER="$new_user"
PANEL_PASS_HASH="$new_hash"
PANEL_PASS_PLAIN="$new_pass"
PANEL_SECRET="$new_secret"
PEOF
    chmod 600 "$PANEL_CONF"
    
    systemctl restart firewallfalcon-panel &>/dev/null
    echo -e "\n${C_GREEN}✅ Panel credentials & secret path updated!${C_RESET}"
    echo -e "  ${C_CYAN}👤 Username:${C_RESET}    ${C_YELLOW}$new_user${C_RESET}"
    echo -e "  ${C_CYAN}🔑 Password:${C_RESET}    ${C_YELLOW}$new_pass${C_RESET}"
    echo -e "  ${C_CYAN}🔐 Secret Path:${C_RESET}  ${C_YELLOW}/$new_secret${C_RESET}"
}

web_panel_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Panel de control web ---${C_RESET}\n"
        
        if [ -f "$PANEL_SERVICE_FILE" ]; then
            if systemctl is-active --quiet firewallfalcon-panel 2>/dev/null; then
                echo -e "  ${C_DIM}Status: ${C_GREEN}🟢 Instalado y en funcionamiento${C_RESET}\n"
            else
                echo -e "  ${C_DIM}Status: ${C_RED}🔴 Instalado pero detenido${C_RESET}\n"
            fi
        else
            echo -e "  ${C_DIM}Status: ${C_YELLOW}⚪ No instalado${C_RESET}\n"
        fi
        
        printf "  ${C_GREEN}[ 1]${C_RESET} %-35s\n" "🚀 Instalar panel web"
        printf "  ${C_GREEN}[ 2]${C_RESET} %-35s\n" "🗑️  Desinstalar el panel web"
        printf "  ${C_GREEN}[ 3]${C_RESET} %-35s\n" "🔑 Mostrar credenciales del panel"
        printf "  ${C_GREEN}[ 4]${C_RESET} %-35s\n" "🔄 Cambiar las credenciales del panel"
        printf "  ${C_GREEN}[ 5]${C_RESET} %-35s\n" "🔃 Reiniciar el servicio del panel"
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️  Volver al menú principal"
        echo
        
        read -r -p "👉 Ingresa una opción: " panel_choice
        case $panel_choice in
            1) install_web_panel; press_enter ;;
            2) uninstall_web_panel; press_enter ;;
            3) show_panel_credentials; press_enter ;;
            4) change_panel_credentials; press_enter ;;
            5)
                if [ -f "$PANEL_SERVICE_FILE" ]; then
                    systemctl restart firewallfalcon-panel &>/dev/null
                    sleep 1
                    if systemctl is-active --quiet firewallfalcon-panel; then
                        echo -e "\n${C_GREEN}✅ El servicio del panel web se reinició correctamente..${C_RESET}"
                    else
                        echo -e "\n${C_RED}❌ No se pudo reiniciar. Comprobando registros.:${C_RESET}"
                        journalctl -u firewallfalcon-panel -n 10 --no-pager
                    fi
                else
                    echo -e "\n${C_YELLOW}ℹ️ El panel web no está instalado.${C_RESET}"
                fi
                press_enter
                ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

uninstall_script() {
    clear; show_banner
    echo -e "${C_RED}=====================================================${C_RESET}"
    echo -e "${C_RED}       🔥 PELIGRO: SCRIPT DE DESINSTALACIÓN Y TODOS LOS DATOS 🔥      ${C_RESET}"
    echo -e "${C_RED}=====================================================${C_RESET}"
    echo -e "${C_YELLOW}Esto eliminará PERMANENTEMENTE este script y todos sus componentes, incluyendo:"
    echo -e " - El comando principal ($(command -v menu))"
    echo -e " - Todos los datos de configuración y de usuario ($DB_DIR)"
    echo -e " - El servicio de limitador activo ($LIMITER_SERVICE)"
    echo -e " - Todos los servicios instalados (badvpn, udp-custom, HAProxy Edge Stack, Nginx, DNSTT)"
    echo -e "\n${C_RED}Esta acción es irreversible.${C_RESET}"
    echo ""
    read -p "👉 Escriba 'yes' para confirmar y proceder con la desinstalación: " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "\n${C_GREEN}✅ Desinstalación cancelada.${C_RESET}"
        return
    fi
    local -a removable_users=()
    local remove_users_confirm
    local remove_users_on_uninstall=false
    mapfile -t removable_users < <(get_firewallfalcon_known_users)
    if [[ ${#removable_users[@]} -gt 0 ]]; then
        echo -e "\n${C_YELLOW}FirewallFalcon: usuarios de SSH detectados en este VPS:${C_RESET} ${removable_users[*]}"
        read -p "👉 ¿También desea eliminar permanentemente estos usuarios SSH antes de desinstalar? (y/n): " remove_users_confirm
        if [[ "$remove_users_confirm" == "y" || "$remove_users_confirm" == "Y" ]]; then
            remove_users_on_uninstall=true
        fi
    fi
    export UNINSTALL_MODE="silent"
    echo -e "\n${C_BLUE}--- 💥 Iniciando la desinstalación 💥 ---${C_RESET}"
    
    if [[ "$remove_users_on_uninstall" == "true" ]]; then
        echo -e "\n${C_BLUE}🗑️ Eliminación de usuarios SSH de FirewallFalcon antes de la desinstalación...${C_RESET}"
        delete_firewallfalcon_user_accounts "${removable_users[@]}"
    fi
    
    echo -e "\n${C_BLUE}🗑️ Eliminación del servicio de limitador activo...${C_RESET}"
    systemctl stop firewallfalcon-limiter &>/dev/null
    systemctl disable firewallfalcon-limiter &>/dev/null
    rm -f "$LIMITER_SERVICE"
    rm -f "$LIMITER_SCRIPT"
    
    echo -e "\n${C_BLUE}🗑️ Eliminando el servicio de monitoreo de ancho de banda...${C_RESET}"
    systemctl stop firewallfalcon-bandwidth &>/dev/null
    systemctl disable firewallfalcon-bandwidth &>/dev/null
    rm -f "$BANDWIDTH_SERVICE"
    rm -f "$BANDWIDTH_SCRIPT"
    rm -rf "$LEGACY_BANDWIDTH_DIR"
    rm -f "$TRIAL_CLEANUP_SCRIPT"
    
    echo -e "\n${C_BLUE}\ud83d\uddd1\ufe0f Eliminación del banner de inicio de sesión SSH...${C_RESET}"
    rm -f "$LOGIN_INFO_SCRIPT"
    rm -f "$SSHD_FF_CONFIG"
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    
    chattr -i /etc/resolv.conf &>/dev/null

    purge_nginx "silent"
    uninstall_dnstt
    uninstall_badvpn
    uninstall_udp_custom
    uninstall_ssl_tunnel
    uninstall_falcon_proxy
    uninstall_zivpn
    uninstall_web_panel
    delete_dns_record
    
    echo -e "\n${C_BLUE}🔄 Recargando systemd daemon...${C_RESET}"
    systemctl daemon-reload
    
    echo -e "\n${C_BLUE}🗑️ Eliminación de scripts y archivos de configuración...${C_RESET}"
    rm -rf "$BADVPN_BUILD_DIR"
    rm -rf "$UDP_CUSTOM_DIR"
    rm -rf "$DB_DIR"
    rm -f "$(command -v menu)"
    
    echo -e "\n${C_GREEN}=============================================${C_RESET}"
    echo -e "${C_GREEN}      El script se ha desinstalado correctamente.     ${C_RESET}"
    echo -e "${C_GREEN}=============================================${C_RESET}"
    echo -e "\nTodos los archivos y servicios asociados han sido eliminados."
    echo "El comando 'menú' ya no funcionará."
    exit 0
}

# --- NEW FEATURES ---

create_trial_account() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⏱️ Crear cuenta de prueba ---${C_RESET}"
    
    # Ensure 'at' daemon is available
    if ! command -v at &>/dev/null; then
        echo -e "${C_YELLOW}⚠️ No se encontró el comando «at». Instalando...${C_RESET}"
        ff_pkg_install at >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ No se pudo instalar 'at'. No se puede programar la caducidad automática.${C_RESET}"
            return
        }
        systemctl enable atd &>/dev/null
        systemctl start atd &>/dev/null
    fi
    
    # Ensure atd is running
    if ! systemctl is-active --quiet atd; then
        systemctl start atd &>/dev/null
    fi
    
    echo -e "\n${C_CYAN}Seleccionar la duración de la prueba:${C_RESET}\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} ⏱️  1 Hora\n"
    printf "  ${C_GREEN}[ 2]${C_RESET} ⏱️  2 Horas\n"
    printf "  ${C_GREEN}[ 3]${C_RESET} ⏱️  3 Horas\n"
    printf "  ${C_GREEN}[ 4]${C_RESET} ⏱️  6 Horas\n"
    printf "  ${C_GREEN}[ 5]${C_RESET} ⏱️  12 Horas\n"
    printf "  ${C_GREEN}[ 6]${C_RESET} 📅  1 Día\n"
    printf "  ${C_GREEN}[ 7]${C_RESET} 📅  3 Días\n"
    printf "  ${C_GREEN}[ 8]${C_RESET} ⚙️  Personalizado (ingresar horas)\n"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️ Cancelar"
    echo
    read -p "👉 Seleccionar duración: " dur_choice
    
    local duration_hours=0
    local duration_label=""
    case $dur_choice in
        1) duration_hours=1;   duration_label="1 Hora" ;;
        2) duration_hours=2;   duration_label="2 Horas" ;;
        3) duration_hours=3;   duration_label="3 Horas" ;;
        4) duration_hours=6;   duration_label="6 Horass" ;;
        5) duration_hours=12;  duration_label="12 Horas" ;;
        6) duration_hours=24;  duration_label="1 Día" ;;
        7) duration_hours=72;  duration_label="3 Días" ;;
        8) read -p "👉 Introduce una duración personalizada en horas: " custom_hours
           if ! [[ "$custom_hours" =~ ^[0-9]+$ ]] || [[ "$custom_hours" -lt 1 ]]; then
               echo -e "\n${C_RED}❌ Número de horas no válido.${C_RESET}"; return
           fi
           duration_hours=$custom_hours
           duration_label="$custom_hours Hours"
           ;;
        0) echo -e "\n${C_YELLOW}❌ Cancelado.${C_RESET}"; return ;;
        *) echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}"; return ;;
    esac
    
    # Username
    local rand_suffix=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)
    local default_username="tew_${rand_suffix}"
    read -p "👤 Nombre de usuario [${default_username}]: " username
    username=${username:-$default_username}
    
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Error: El usuario '$ username' ya existe.${C_RESET}"; return
    fi
    
    # Password
    local password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
    read -p "🔑 Contraseña [${password}]: " custom_pass
    password=${custom_pass:-$password}
    
    # Connection limit
    read -p "📶 Límite de conexiones [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    
    # Bandwidth limit
    read -p "📦 Límite de ancho de banda en GB (0 = ilimitado) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    
    # Calculate expiry
    local expire_date
    if [[ "$duration_hours" -ge 24 ]]; then
        local days=$((duration_hours / 24))
        expire_date=$(date -d "+$days days" +%Y-%m-%d)
    else
        # For sub-day durations, set expiry to tomorrow to be safe (at job does the real cleanup)
        expire_date=$(date -d "+1 day" +%Y-%m-%d)
    fi
    local expiry_timestamp
    expiry_timestamp=$(date -d "+${duration_hours} hours" '+%Y-%m-%d %H:%M:%S')
    
    # Create the system user
    ensure_firewallfalcon_system_group
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:trial" >> "$DB_FILE"
    
    # Schedule auto-cleanup via 'at'
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    
    local bw_display="ilimitado"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    
    clear; show_banner
    echo -e "${C_GREEN}✅ ¡Cuenta de prueba creada correctamente!${C_RESET}\n"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  ⏱️  ${C_BOLD}CUENTA DE PRUEBA${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  - 👤 Usuario:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Contraseña:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - ⏱️ Duración:          ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  - 🕐 Caduca automáticamente el:   ${C_RED}$expiry_timestamp${C_RESET}"
    echo -e "  - 📶 Límite de conexiones:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Límite de ancho de banda:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "\n${C_DIM}La cuenta se eliminará automáticamente cuando expire el periodo de prueba.${C_RESET}"
    
    # Auto-ask for config generation
    echo
    read -p "👉 Generar configuración de cliente para este usuario de prueba? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 Ver ancho de banda del usuario ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📊 Detalles del ancho de banda: ${C_YELLOW}$u${C_PURPLE} ---${C_RESET}\n"
    
    local line; line=$(grep "^$u:" "$DB_FILE")
    local _u _p _e _l bandwidth_gb
    IFS=: read -r _u _p _e _l bandwidth_gb _ <<< "$line"
    [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
    
    local used_bytes=0
    if [[ -f "$BANDWIDTH_DIR/${u}.usage" ]]; then
        read -r used_bytes < "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null || used_bytes=0
        [[ -z "$used_bytes" ]] && used_bytes=0
    fi
    
    local used_mb; used_mb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1048576}")
    local used_gb; used_gb=$(awk "BEGIN {printf \"%.3f\", $used_bytes / 1073741824}")
    
    echo -e "  ${C_CYAN}Datos utilizados:${C_RESET}        ${C_WHITE}${used_gb} GB${C_RESET} (${used_mb} MB)"
    
    if [[ "$bandwidth_gb" == "0" ]]; then
        echo -e "  ${C_CYAN}Límite de ancho de banda:${C_RESET}  ${C_GREEN}ilimitado${C_RESET}"
        echo -e "  ${C_CYAN}Estado:${C_RESET}           ${C_GREEN}Sin restricciones de cuotas${C_RESET}"
    else
        local quota_bytes; quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        local percentage; percentage=$(awk "BEGIN {printf \"%.1f\", ($used_bytes / $quota_bytes) * 100}")
        local remaining_bytes; remaining_bytes=$((quota_bytes - used_bytes))
        if [[ "$remaining_bytes" -lt 0 ]]; then remaining_bytes=0; fi
        local remaining_gb; remaining_gb=$(awk "BEGIN {printf \"%.3f\", $remaining_bytes / 1073741824}")
        
        echo -e "  ${C_CYAN}Límite de ancho de banda:${C_RESET}  ${C_YELLOW}${bandwidth_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Restante:${C_RESET}        ${C_WHITE}${remaining_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Usado:${C_RESET}            ${C_WHITE}${percentage}%${C_RESET}"
        
        # Progress bar
        local bar_width=30
        local filled; filled=$(awk "BEGIN {printf \"%.0f\", ($percentage / 100) * $bar_width}")
        if [[ "$filled" -gt "$bar_width" ]]; then filled=$bar_width; fi
        local empty=$((bar_width - filled))
        local bar_color="$C_GREEN"
        if (( $(awk "BEGIN {print ($percentage > 80)}" ) )); then bar_color="$C_RED"
        elif (( $(awk "BEGIN {print ($percentage > 50)}" ) )); then bar_color="$C_YELLOW"
        fi
        printf "  ${C_CYAN}Progreso:${C_RESET}         ${bar_color}["
        for ((i=0; i<filled; i++)); do printf "█"; done
        for ((i=0; i<empty; i++)); do printf "░"; done
        printf "]${C_RESET} ${percentage}%%\n"
        
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
            echo -e "\n  ${C_RED}⚠️ EL USUARIO SUPERADO LA CUOTA DE ANCHO DE BANDA — CUENTA BLOQUEADA${C_RESET}"
        fi
    fi
}

bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Crear usuarios de forma masiva ---${C_RESET}"
    
    read -p "👉 Introduce el prefijo del nombre de usuario (ej. 'usuario'): " prefix
    if [[ -z "$prefix" ]]; then echo -e "\n${C_RED}❌ El prefijo no puede estar vacío.${C_RESET}"; return; fi
    
    read -p "🔢 ¿Cuántos usuarios crear? " count
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]]; then
        echo -e "\n${C_RED}❌ Recuento no válido (1-100).${C_RESET}"; return
    fi
    
    read -p "🗓️ Duración de la cuenta (en días) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    
    read -p "📶 Límite de conexiones por usuario [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    
    read -p "📦 Límite de ancho de banda en GB por usuario (0 = ilimitado) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    
    read -p "📦 Límite DIARIO de ancho de banda en GB por usuario (0 = ilimitado) [0]: " daily_bandwidth_gb
    daily_bandwidth_gb=${daily_bandwidth_gb:-0}
    if ! [[ "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Número no válido.${C_RESET}"; return; fi
    
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    local bw_display="Ilimitado"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    local daily_bw_display="Ilimitado"; [[ "$daily_bandwidth_gb" != "0" ]] && daily_bw_display="${daily_bandwidth_gb} GB/Día"
    ensure_firewallfalcon_system_group
    
    echo -e "\n${C_BLUE}⚙️ Creando $count usuarios con prefijo '${prefix}'...${C_RESET}\n"
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-20s | %-15s | %-12s${C_RESET}\n" "USUARIO" "CONTRASEÑA" "EXPIRA"
    echo -e "${C_YELLOW}----------------------------------------------------------------${C_RESET}"
    
    local created=0
    for ((i=1; i<=count; i++)); do
        local username="${prefix}${i}"
        if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
            echo -e "${C_RED}  ⚠️ Omitiendo '$username': ya existe.${C_RESET}"
            continue
        fi
        local password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
        useradd -m -s /usr/sbin/nologin "$username"
        usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
        echo "$username:$password" | chpasswd
        chage -E "$expire_date" "$username"
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb:$daily_bandwidth_gb:bulk" >> "$DB_FILE"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    echo -e "\n${C_GREEN}✅ Se han creado $created usuarios. Límite de conexiones: ${limit} | Ancho de banda total: ${bw_display} | Ancho de banda diario: ${daily_bw_display}${C_RESET}"
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

generate_client_config() {
    local user=$1
    local pass=$2
    
    local host_ip=$(curl -s -4 icanhazip.com)
    local host_domain
    host_domain=$(detect_preferred_host)
    [[ -z "$host_domain" ]] && host_domain="$host_ip"

    echo -e "\n${C_BOLD}${C_PURPLE}--- 📱 Configuración de la conexión del cliente ---${C_RESET}"
    echo -e "${C_CYAN}Copia los detalles en tu portapapeles:${C_RESET}\n"

    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "👤 ${C_BOLD}Detalles del usuario${C_RESET}"
    echo -e "   • Usuario: ${C_WHITE}$user${C_RESET}"
    echo -e "   • Contraseña: ${C_WHITE}$pass${C_RESET}"
    echo -e "   • Host/IP : ${C_WHITE}$host_domain${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    
    # 1. SSH Direct
    echo -e "\n🔹 ${C_BOLD}SSH Direct${C_RESET}:"
    echo -e "   • Host: $host_domain"
    echo -e "   • Port: 22"
    echo -e "   • Payload: (Standard SSH)"

    # 2. HAProxy edge stack
    if systemctl is-active --quiet haproxy; then
        echo -e "\n🔹 ${C_BOLD}HAProxy Edge Stack${C_RESET}:"
        echo -e "   • Host: $host_domain"
        echo -e "   • Puerto 80: HTTP payloads / raw SSH"
        echo -e "   • Puerto 443: TLS / SNI / SSL payloads"
        echo -e "   • Traspaso interno: Nginx ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}"
        echo -e "   • SNI (BugHost): $host_domain (o el SNI de tu preferencia)"
    elif systemctl is-active --quiet nginx; then
        echo -e "\n🔹 ${C_BOLD}Proxy interno de Nginx${C_RESET}:"
        echo -e "   • Solo interno: ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}"
        echo -e "   • Los clientes públicos deben conectarse a través de HAProxy en ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}"
    fi

    # 3. UDP Custom
    if systemctl is-active --quiet udp-custom; then
        echo -e "\n🔹 ${C_BOLD}UDP Custom${C_RESET}:"
        echo -e "   • IP: $host_ip (Se debe utilizar una dirección IP numérica.)"
        echo -e "   • Puerto: 1-65535 (Excluir 53, 5300)"
        echo -e "   • Ofuscación: (Ninguna/Sin ofuscación)"
    fi

    # 4. DNSTT
    if systemctl is-active --quiet dnstt; then
        if [ -f "$DNSTT_CONFIG_FILE" ]; then
            source "$DNSTT_CONFIG_FILE"
            echo -e "\n🔹 ${C_BOLD}DNSTT (SlowDNS)${C_RESET}:"
            echo -e "   • Nombre de servidor: $TUNNEL_DOMAIN"
            echo -e "   • Clave publica: $PUBLIC_KEY"
            echo -e "   • DNS IP: 1.1.1.1 / 8.8.8.8"
        fi
    fi
    
    # 5. ZiVPN
    if systemctl is-active --quiet zivpn; then
        echo -e "\n🔹 ${C_BOLD}ZiVPN${C_RESET}:"
        echo -e "   • UDP Puerto: 5667"
        echo -e "   • Puertos reenviados: 6000-19999"
    fi
    
    echo -e "${C_YELLOW}========================================${C_RESET}"

}

client_config_menu() {
    _select_user_interface "--- 📱 Generar configuración del cliente ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    # We need to find the password. It's in the DB.
    local pass=$(grep "^$u:" "$DB_FILE" | cut -d: -f2)
    generate_client_config "$u" "$pass"
}

format_rate_from_kbps() {
    local kbps=${1:-0}
    if (( kbps >= 1024 )); then
        printf "%d.%02d MB/s" $((kbps / 1024)) $((((kbps % 1024) * 100) / 1024))
    else
        printf "%d KB/s" "$kbps"
    fi
}

# Lightweight Bash Monitor (No vnStat required)
simple_live_monitor() {
    local iface=$1
    local rx_file="/sys/class/net/$iface/statistics/rx_bytes"
    local tx_file="/sys/class/net/$iface/statistics/tx_bytes"
    local interval=2
    local stop_monitor=0
    local rx1 tx1 rx2 tx2 rx_diff tx_diff rx_kbs tx_kbs rx_fmt tx_fmt

    if [[ -z "$iface" || ! -r "$rx_file" || ! -r "$tx_file" ]]; then
        echo -e "\n${C_RED}❌ No se pudo leer las estadísticas de la interfaz para '${iface:-unknown}'.${C_RESET}"
        return
    fi

    echo -e "\n${C_BLUE}⚡ Iniciando monitor de tráfico ligero para $iface...${C_RESET}"
    echo -e "${C_DIM}Presiona [Ctrl+C] para detenerse.${C_RESET}\n"

    read -r rx1 < "$rx_file"
    read -r tx1 < "$tx_file"

    printf "%-15s | %-15s\n" "⬇️ Descarga" "⬆️ Subida"
    echo "-----------------------------------"

    trap 'stop_monitor=1' INT TERM
    while (( ! stop_monitor )); do
        sleep "$interval"
        read -r rx2 < "$rx_file" || break
        read -r tx2 < "$tx_file" || break

        rx_diff=$((rx2 - rx1))
        tx_diff=$((tx2 - tx1))
        (( rx_diff < 0 )) && rx_diff=0
        (( tx_diff < 0 )) && tx_diff=0

        rx_kbs=$((rx_diff / 1024 / interval))
        tx_kbs=$((tx_diff / 1024 / interval))
        rx_fmt=$(format_rate_from_kbps "$rx_kbs")
        tx_fmt=$(format_rate_from_kbps "$tx_kbs")

        printf "\r%-15s | %-15s" "$rx_fmt" "$tx_fmt"

        rx1=$rx2
        tx1=$tx2
    done
    trap - INT TERM
    echo
}

traffic_monitor_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📈 Monitor de tráfico de red ---${C_RESET}"
    
    # Find active interface
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    echo -e "\nInterface: ${C_CYAN}${iface}${C_RESET}"
    
    echo -e "\n${C_BOLD}Select a monitoring option:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "⚡ Monitor en tiempo real ${C_DIM}(Ligero, sin instalación)${C_RESET}"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "📊 Ver tráfico total desde el arranque"
    printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "📅 Registros diarios/mensuales ${C_DIM}(Requiere vnStat)${C_RESET}"
    
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Regresar"
    echo
    read -p "👉 Ingresa una opción: " t_choice
    case $t_choice in
        1) 
           simple_live_monitor "$iface"
           ;;
        2)
            local rx_total=$(cat /sys/class/net/$iface/statistics/rx_bytes)
            local tx_total=$(cat /sys/class/net/$iface/statistics/tx_bytes)
            local rx_mb=$((rx_total / 1024 / 1024))
            local tx_mb=$((tx_total / 1024 / 1024))
            echo -e "\n${C_BLUE}📊 Tráfico total (Desde el arranque):${C_RESET}"
            echo -e "   ⬇️ Descarga: ${C_WHITE}${rx_mb} MB${C_RESET}"
            echo -e "   ⬆️ Subida:   ${C_WHITE}${tx_mb} MB${C_RESET}"
            press_enter
            ;;
        3) 
           # vnStat Logic
           if ! command -v vnstat &> /dev/null; then
               echo -e "\n${C_YELLOW}⚠️ vnStat no está instalado.${C_RESET}"
               echo -e "   Esta herramienta ofrece un historial persistente (informes diarios/mensuales).."
               echo -e "   Es ligero, pero requiere instalación.."
               read -p "👉 Instala vnStat ahora? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                     echo -e "\n${C_BLUE}📦 Instalando vnStat...${C_RESET}"
                     ff_pkg_install vnstat >/dev/null 2>&1 || {
                         echo -e "${C_RED}❌ No se pudo instalar vnStat.${C_RESET}"
                         sleep 1
                         return
                     }
                     systemctl enable vnstat >/dev/null 2>&1
                     systemctl restart vnstat >/dev/null 2>&1
                    local default_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
                    vnstat --add -i "$default_iface" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ Instalado.${C_RESET}"
                    sleep 1
               else
                    return
               fi
           fi
           echo
           vnstat -i "$iface"
           echo -e "\n${C_DIM}Ejecute 'vnstat -d' o 'vnstat -m' manualmente para vistas específicas.${C_RESET}"
           press_enter
           ;;
        *) return ;;
    esac
}

torrent_block_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Bloqueo de torrents (anti-torrent) ---${C_RESET}"
    
    # Check status
    local torrent_status="${C_STATUS_I}Disabled${C_RESET}"
    if iptables -L FORWARD | grep -q "ipp2p"; then
         torrent_status="${C_STATUS_A}Enabled${C_RESET}"
    elif iptables -L OUTPUT | grep -q "BitTorrent"; then
         # Fallback check for string matching
         torrent_status="${C_STATUS_A}Enabled${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Estado actual: ${torrent_status}${C_RESET}"
    echo -e "${C_DIM}Esta función utiliza la coincidencia de cadenas de iptables para bloquear palabras claves relacionadas con torrents..${C_RESET}"
    
    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🔒 Activar bloqueo de torrents"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔓 Desactivar bloqueo de torrents"
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Regresar"
    echo
    read -p "👉 Ingresa una opción: " b_choice
    
    case $b_choice in
        1)
            echo -e "\n${C_BLUE}🛡️ Aplicando las reglas anti-torrent...${C_RESET}"
            # Clean old rules first to avoid duplicates
            _flush_torrent_rules
            
            # Block Common Torrent Ports/Keywords
            # String matching using iptables extension
            iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP
            iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP
            iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "announce.php?passkey=" --algo bm -j DROP
            iptables -A FORWARD -m string --string "torrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP
            iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
            iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
            
            # Same for OUTPUT to be safe
            iptables -A OUTPUT -m string --string "BitTorrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "peer_id=" --algo bm -j DROP
            iptables -A OUTPUT -m string --string ".torrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "announce.php?passkey=" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "torrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "info_hash" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "get_peers" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "find_node" --algo bm -j DROP
            
            # Attempt to save if iptables-persistent exists
            if ff_pkg_is_installed iptables-persistent &>/dev/null; then
                netfilter-persistent save &>/dev/null
            fi
            
            echo -e "${C_GREEN}✅ Bloqueo de torrents activado.${C_RESET}"
            press_enter
            ;;
        2)
            echo -e "\n${C_BLUE}🔓 Removiendo las reglas antitorrent...${C_RESET}"
            _flush_torrent_rules
            if ff_pkg_is_installed iptables-persistent &>/dev/null; then
                netfilter-persistent save &>/dev/null
            fi
            echo -e "${C_GREEN}✅ Bloqueo de torrents desactivado.${C_RESET}"
            press_enter
            ;;
        *) return ;;
    esac
}

_flush_torrent_rules() {
    # Helper to remove rules containing specific strings
    # This is a bit brute-force but effective for this script's scope
    iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "announce.php?passkey=" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "torrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "find_node" --algo bm -j DROP 2>/dev/null

    iptables -D OUTPUT -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "announce.php?passkey=" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "torrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "find_node" --algo bm -j DROP 2>/dev/null
}

ssh_banner_menu() {
    while true; do
        show_banner
        local banner_mode
        local banner_status
        banner_mode=$(get_ssh_banner_mode)
        case "$banner_mode" in
            dynamic) banner_status="${C_STATUS_A}Dinamico${C_RESET}" ;;
            static) banner_status="${C_STATUS_A}Estático${C_RESET}" ;;
            *) banner_status="${C_STATUS_I}Desactivado${C_RESET}" ;;
        esac

        echo -e "\n   ${C_TITLE}═════════════════[ ${C_BOLD}🎨 MODO DE BANNER SSH: ${banner_status} ${C_RESET}${C_TITLE}]═════════════════${C_RESET}"
        echo -e "${C_DIM}El modo estático utiliza 'Banner $SSH_BANNER_FILE'. El modo dinámico muestra información de la cuenta de cada usuario.${C_RESET}"
        printf "     ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "✨ Habilitar banner de cuenta Dinámico"
        printf "     ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "📋 Pegar o reemplazar banner estático"
        printf "     ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "👁️ Ver banner estático actual"
        printf "     ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "📝 Vista previa del banner dinámico"
        printf "     ${C_DANGER}[ 5]${C_RESET} %-40s\n" "🗑️ Deshabilitar todos los banners SSH"
        echo -e "   ${C_DIM}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${C_RESET}"
        echo -e "     ${C_WARN}[ 0]${C_RESET} ↩️ Regresar"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Ingresa una opción: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1)
                if setup_ssh_login_info; then
                    echo -e "\n${C_GREEN}✅ Banner de cuenta dinámico habilitado.${C_RESET}"
                    echo -e "${C_DIM}Los usuarios verán ahora su banner de información de cuenta en lugar del banner estático.${C_RESET}"
                fi
                press_enter
                ;;
            2) set_ssh_banner_paste ;;
            3) view_ssh_banner ;;
            4) preview_dynamic_ssh_banner ;;
            5) remove_ssh_banner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}" && sleep 1 ;;
        esac
    done
}

auto_reboot_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Reinicio automatico ---${C_RESET}"
    
    # Check status
    local cron_check=$(crontab -l 2>/dev/null | grep "systemctl reboot")
    local status="${C_STATUS_I}Desactivado${C_RESET}"
    if [[ -n "$cron_check" ]]; then
        status="${C_STATUS_A}Activo (Medianoche)${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Estado actual: ${status}${C_RESET}"
    
    echo -e "\n${C_BOLD}Selecciona una acción:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🕐 Habilitar reinicio diario (00:00, medianoche)"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "❌ Desactivar el reinicio automático"
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Regresar"
    echo
    read -p "👉 Ingresa una opción: " r_choice
    
    case $r_choice in
        1)
            # Remove existing to prevent duplicates
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -
            # Add new job
            (crontab -l 2>/dev/null; echo "0 0 * * * systemctl reboot") | crontab -
            echo -e "\n${C_GREEN}✅Reinicio automático programado para todos los días a las 00:00..${C_RESET}"
            press_enter
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -
            echo -e "\n${C_GREEN}✅ Reinicio automático desactivado.${C_RESET}"
            press_enter
            ;;
        *) return ;;
    esac
}


press_enter() {
    echo -e "\nPresiona ${C_YELLOW}[Enter]${C_RESET} para volver al menú..." && read -r || true
}
invalid_option() {
    echo -e "\n${C_RED}❌ Opción no válida.${C_RESET}" && sleep 1
}

main_menu() {
    while true; do
        export UNINSTALL_MODE="interactive"
        show_banner
        
        echo
        echo -e "   ${C_TITLE}═══════════════════[ ${C_BOLD}👤 GESTIÓN DE USUARIOS ${C_RESET}${C_TITLE}]═══════════════════${C_RESET}"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "1" "✨ Crear nuevo usuario" "2" "🗑️  Eliminar usuario"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "3" "🔄 Renovar usuario" "4" "🔒 Bloquear usuario"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "5" "🔓 Desbloquear usuario" "6" "✏️  Editar usuario"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "7" "📋 Lista de usuarios" "8" "📱 Generar configuración del cliente"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "9" "⏱️ Crear cuenta de prueba" "10" "📊 Ver ancho de banda del usuario"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "11" "👥 Crear usuarios de forma masiva"
        
        echo
        echo -e "   ${C_TITLE}══════════════[ ${C_BOLD}🌐 VPN Y PROTOCOLOS ${C_RESET}${C_TITLE}]═══════════════${C_RESET}"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "12" "🔌 Gestor de protocolos" "13" "📈 Monitor de tráfico (Lite)"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "14" "🚫 Bloquear torrent (Anti-P2P)"

        echo
        echo -e "   ${C_TITLE}══════════════[ ${C_BOLD}⚙️ CONFIGURACIÓN DEL SISTEMA ${C_RESET}${C_TITLE}]═══════════════${C_RESET}"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "15" "🌐 Dominio gratuito (deSEC)" "16" "🎨 Configuración del banner SSH"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "17" "🔄 Tarea de reinicio automático" "18" "💾 Realizar copia de seguridad"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "19" "📥 Activar copia de seguridad" "20" "🧹 Limpiar usuarios expirados"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "21" "🌐 Web Control Panel"

        echo
        echo -e "   ${C_DANGER}═══════════════════[ ${C_BOLD}🔥 ZONA DE PELIGRO ${C_RESET}${C_DANGER}]═══════════════════${C_RESET}"
        echo -e "     ${C_DANGER}[99]${C_RESET} Desinstalar script             ${C_WARN}[0]${C_RESET} salir"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            exit 0
        fi
        case $choice in
            1) create_user; press_enter ;;
            2) delete_user; press_enter ;;
            3) renew_user; press_enter ;;
            4) lock_user; press_enter ;;
            5) unlock_user; press_enter ;;
            6) edit_user; press_enter ;;
            7) list_users; press_enter ;;
            8) client_config_menu; press_enter ;;
            9) create_trial_account; press_enter ;;
            10) view_user_bandwidth; press_enter ;;
            11) bulk_create_users; press_enter ;;
            
            12) protocol_menu ;;
            13) traffic_monitor_menu ;;
            14) torrent_block_menu ;;
            
            15) dns_menu; press_enter ;;
            16) ssh_banner_menu ;;
            17) auto_reboot_menu ;;
            18) backup_user_data; press_enter ;;
            19) restore_user_data; press_enter ;;
            20) cleanup_expired; press_enter ;;
            21) web_panel_menu ;;
            
            99) uninstall_script ;;
            0) exit 0 ;;
            *) invalid_option ;;
        esac
    done
}

if [[ "$1" == "--install-setup" ]]; then
    initial_setup
    exit 0
fi

require_interactive_terminal
sync_runtime_components_if_needed
main_menu
