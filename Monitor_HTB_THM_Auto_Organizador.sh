#!/bin/bash

# --- Auto-elevación y auto asignación de permisos ---
# Si no se ejecuta como root, se reinicia el script con sudo
if [ "$EUID" -ne 0 ]; then
    echo "Reiniciando el script con sudo..."
    sudo "$0" "$@"
    exit
fi

# Auto asignar permisos de ejecución al propio script (en caso de que no tenga)
if [ ! -x "$0" ]; then
    echo "Asignando permisos de ejecución al instalador..."
    chmod +x "$0"
fi

# --- Variables y creación de directorios principales ---
# Verificar que SUDO_USER esté definido (nombre del usuario original)
if [ -z "$SUDO_USER" ]; then
    echo "Error: Este script debe ejecutarse a través de sudo."
    exit 1
fi

USER_HOME=$(eval echo ~$SUDO_USER)
HTB_DIR="$USER_HOME/HTB"
THM_DIR="$USER_HOME/THM"

# Crear directorios HTB y THM si no existen
for DIR in "$HTB_DIR" "$THM_DIR"; do
    if [ ! -d "$DIR" ]; then
        echo "Creando directorio $(basename "$DIR") en $DIR..."
        mkdir -p "$DIR"
    fi
done

# --- Instalación de inotify-tools ---
if ! command -v inotifywait &> /dev/null; then
    echo "Instalando inotify-tools..."
    apt update && apt install -y inotify-tools
fi

# --- Instalación del script de monitoreo ---
echo "Instalando monitor_HTB_THM.sh..."
cat << 'EOF' > /usr/local/bin/monitor_HTB_THM.sh
#!/bin/bash

# Directorios a monitorear (se usa $HOME del usuario que inició sesión)
DIRS=("$HOME/HTB" "$HOME/THM")

# Verificar que cada directorio exista
for DIR in "${DIRS[@]}"; do
    if [ ! -d "$DIR" ]; then
        echo "Error: El directorio $DIR no existe."
        exit 1
    fi
done

echo "✅ Monitoreando directorios: ${DIRS[@]} ... (Presiona Ctrl+C para detener)"

# Función para monitorear un directorio
monitor_dir() {
    local DIR="$1"
    inotifywait -m -e create --format "%w%f" "$DIR" | while read NEW_ENTRY
    do
        # Si se creó un directorio, se ejecuta el script para crear los subdirectorios
        if [ -d "$NEW_ENTRY" ]; then
            echo "📂 Nueva carpeta detectada en $DIR: $NEW_ENTRY"
            /usr/local/bin/crear_carpetas.sh "$NEW_ENTRY"
        fi
    done
}

# Monitorear cada directorio en segundo plano
for DIR in "${DIRS[@]}"; do
    monitor_dir "$DIR" &
done

# Espera a que finalicen los procesos en segundo plano
wait
EOF

# --- Instalación del script para crear subdirectorios ---
echo "Instalando crear_carpetas.sh..."
cat << 'EOF' > /usr/local/bin/crear_carpetas.sh
#!/bin/bash

# Verificar que se haya proporcionado un directorio como argumento
if [ -z "$1" ]; then
    echo "Uso: $0 <directorio>"
    exit 1
fi

DIRECTORIO="$1"

# Crear los 4 subdirectorios automáticamente
mkdir -p "$DIRECTORIO/content" "$DIRECTORIO/exploits" "$DIRECTORIO/nmap" "$DIRECTORIO/scripts"

echo "✅ Carpetas creadas en: $DIRECTORIO"
EOF

# --- Auto asignación de permisos a los scripts instalados ---
chmod +x /usr/local/bin/monitor_HTB_THM.sh
chmod +x /usr/local/bin/crear_carpetas.sh

# --- Creación del servicio systemd ---
echo "Creando servicio systemd para monitor_HTB_THM..."
cat << EOF > /etc/systemd/system/monitor_HTB_THM.service
[Unit]
Description=Monitorea la creación de carpetas en HTB y THM y ejecuta crear_carpetas.sh
After=network.target

[Service]
ExecStart=/usr/local/bin/monitor_HTB_THM.sh
Restart=always
User=$SUDO_USER
WorkingDirectory=$USER_HOME
StandardOutput=append:/var/log/monitor_HTB_THM.log
StandardError=append:/var/log/monitor_HTB_THM.log

[Install]
WantedBy=default.target
EOF

# --- Recargar systemd, habilitar e iniciar el servicio ---
echo "Habilitando y ejecutando el servicio monitor_HTB_THM..."
systemctl daemon-reload
systemctl enable monitor_HTB_THM.service
systemctl start monitor_HTB_THM.service

echo "✅ Instalación completa. El servicio monitor_HTB_THM ya está corriendo."
echo "Para verificar su estado, usa: systemctl status monitor_HTB_THM.service"
