#!/bin/bash

# --- Auto elevación a root ---
if [ "$EUID" -ne 0 ]; then
    echo "Reiniciando el script con privilegios de administrador..."
    exec sudo "$0" "$@"
    exit
fi

# --- Verificar ejecución mediante sudo ---
if [ -z "$SUDO_USER" ]; then
    echo "Error: Este script requiere ejecución mediante sudo."
    exit 1
fi

# --- Configuración inicial ---
USER_HOME=$(eval echo ~$SUDO_USER)
DIRECTORIOS_BASE=("$USER_HOME/HTB" "$USER_HOME/THM")
DEPENDENCIAS=("inotify-tools")
SERVICIO_SYSTEMD="/etc/systemd/system/monitor_HTB_THM.service"
SCRIPT_MONITOR="/usr/local/bin/monitor_HTB_THM.sh"
SCRIPT_CARPETAS="/usr/local/bin/crear_carpetas.sh"

# --- Funciones principales ---
configurar_permisos() {
    local directorio="$1"
    mkdir -p "$directorio"
    chown "$SUDO_USER:$SUDO_USER" "$directorio"
    chmod 755 "$directorio"
}

instalar_dependencias() {
    apt update
    for paquete in "${DEPENDENCIAS[@]}"; do
        if ! dpkg -l | grep -q "^ii  $paquete"; then
            apt install -y "$paquete"
        fi
    done
}

generar_script_monitor() {
    cat << 'EOF' > "$SCRIPT_MONITOR"
#!/bin/bash

DIRECTORIOS=("$HOME/HTB" "$HOME/THM")

verificar_directorios() {
    for dir in "${DIRECTORIOS[@]}"; do
        if [ ! -d "$dir" ]; then
            echo "Error: Directorio $dir no encontrado"
            exit 1
        fi
    done
}

monitorear_directorio() {
    local directorio="$1"
    inotifywait -m -e create --format "%w%f" "$directorio" | while read ruta
    do
        if [ -d "$ruta" ]; then
            echo "Nuevo proyecto detectado: $ruta"
            /usr/local/bin/crear_carpetas.sh "$ruta"
        fi
    done
}

iniciar_monitoreo() {
    verificar_directorios
    echo "Iniciando monitoreo en: ${DIRECTORIOS[*]}"
    for dir in "${DIRECTORIOS[@]}"; do
        monitorear_directorio "$dir" &
    done
    wait
}

iniciar_monitoreo
EOF
}

generar_script_carpetas() {
    cat << 'EOF' > "$SCRIPT_CARPETAS"
#!/bin/bash

[ -z "$1" ] && { echo "Uso: $0 <directorio>"; exit 1; }

directorio="$1"
subdirectorios=("content" "exploits" "nmap" "scripts")

mkdir -p "${subdirectorios[@]/#/$directorio/}"
echo "Estructura creada en: $directorio"
EOF
}

configurar_servicio_systemd() {
    cat << EOF > "$SERVICIO_SYSTEMD"
[Unit]
Description=Monitor de directorios HTB/THM
After=network.target

[Service]
ExecStart=$SCRIPT_MONITOR
Restart=always
User=$SUDO_USER
WorkingDirectory=$USER_HOME
StandardOutput=append:$USER_HOME/monitor_HTB_THM.log
StandardError=append:$USER_HOME/monitor_HTB_THM.log

[Install]
WantedBy=default.target
EOF
}

# --- Ejecución principal ---
echo "Iniciando proceso de instalación..."

# Configurar directorios base
for dir in "${DIRECTORIOS_BASE[@]}"; do
    echo "Configurando directorio: $dir"
    configurar_permisos "$dir"
done

# Instalar dependencias
echo "Verificando dependencias..."
instalar_dependencias

# Generar scripts
echo "Generando scripts..."
generar_script_monitor
generar_script_carpetas

# Configurar permisos de ejecución
chmod +x "$SCRIPT_MONITOR" "$SCRIPT_CARPETAS"

# Configurar servicio systemd
echo "Configurando servicio..."
configurar_servicio_systemd

# Recargar e iniciar servicio
systemctl daemon-reload
systemctl enable --now monitor_HTB_THM.service

echo "Instalación completada exitosamente."
echo "Estado del servicio: systemctl status monitor_HTB_THM.service"
echo "Registros del sistema: $USER_HOME/monitor_HTB_THM.log"
