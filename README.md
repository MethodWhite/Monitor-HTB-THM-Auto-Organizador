# Monitor HTB & THM Auto-Organizador

Este proyecto automatiza la creación de subdirectorios en los directorios **HTB** y **THM** ubicados en el home del usuario. Al detectar la creación de un nuevo subdirectorio en cualquiera de estos, el monitor (mediante `inotify-tools` y `systemd`) ejecuta un script que crea automáticamente las carpetas `content`, `exploits`, `nmap` y `scripts` para mantener una estructura organizada.

## Descripción Corta

Monitor HTB & THM Auto-Organizador es una herramienta Linux que vigila los directorios HTB y THM en el home del usuario y, al detectar un nuevo subdirectorio, crea automáticamente las carpetas `content`, `exploits`, `nmap` y `scripts`.

## Características

- **Auto-elevación:** El instalador se reinicia automáticamente con privilegios sudo si no se ejecuta como root.
- **Auto asignación de permisos:** Se asignan automáticamente los permisos de ejecución para el instalador y los scripts instalados.
- **Monitoreo continuo:** Utiliza `inotify-tools` para vigilar los directorios **HTB** y **THM**.
- **Integración con systemd:** Configura un servicio que se inicia automáticamente al arrancar el sistema.

## Requisitos

- Sistema operativo Linux.
- `inotify-tools` (se instalará automáticamente si no está presente).
- Permisos de sudo.

## Instalación

1. **Descarga el archivo `instalar_monitor_HTB_THM.sh`.**
2. **(Opcional) Asigna permisos de ejecución:**
   ```bash
   chmod +x instalar_monitor_HTB_THM.sh
   ```
3. **Ejecuta el script:**
   ```bash
   ./instalar_monitor_HTB_THM.sh
   ```
   - El script se reiniciará automáticamente con sudo si es necesario.
   - Se crearán los directorios **HTB** y **THM** en el home del usuario.
   - Se configurará el servicio `monitor_HTB_THM` para que se inicie al arrancar el sistema.

## Uso

- **Subdirectorios automáticos:** Al crear un nuevo directorio dentro de **HTB** o **THM**, se generan automáticamente los subdirectorios: `content`, `exploits`, `nmap` y `scripts`.
- **Verificar el servicio:** Comprueba el estado del servicio con:
  ```bash
  systemctl status monitor_HTB_THM.service
  ```
- **Logs:** La salida se guarda en `/var/log/monitor_HTB_THM.log`.

## Desinstalación

Para desinstalar el servicio y eliminar los scripts:

1. Detén y deshabilita el servicio:
   ```bash
   sudo systemctl stop monitor_HTB_THM.service
   sudo systemctl disable monitor_HTB_THM.service
   ```
2. Elimina el servicio y los scripts:
   ```bash
   sudo rm /etc/systemd/system/monitor_HTB_THM.service
   sudo rm /usr/local/bin/monitor_HTB_THM.sh /usr/local/bin/crear_carpetas.sh
   ```
3. Recarga systemd:
   ```bash
   sudo systemctl daemon-reload
   ```

## Notas

- El instalador asigna automáticamente los permisos necesarios.
- Se crean los directorios **HTB** y **THM** en el home del usuario si no existen.
- Este proyecto facilita la organización y automatiza tareas repetitivas.

