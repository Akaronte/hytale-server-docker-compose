# 🎮 Hytale Server - Docker

Servidor dedicado de Hytale usando Docker, basado en el [Manual Oficial de Hytale Server](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual).

## 📋 Requisitos

- **Docker** y **Docker Compose** instalados
- **Licencia de Hytale** (necesitas tener el juego comprado)
- **4GB RAM** mínimo (recomendado 6GB+)
- **Puerto 5520/UDP** abierto en tu firewall/router

## 📁 Estructura del Proyecto

```
hytale-server/
├── Dockerfile              # Imagen del servidor
├── docker-compose.yaml     # Configuración de Docker
├── config.json             # Configuración del servidor
├── permissions.json        # Sistema de permisos
├── whitelist.json          # Lista blanca de jugadores
├── bans.json               # Jugadores baneados
├── Server/                 # ⚠️ Archivos del servidor (ver paso 1)
│   ├── HytaleServer.jar
│   └── HytaleServer.aot
├── Assets.zip              # ⚠️ Recursos del juego (ver paso 1)
├── universe/               # Datos del mundo (persistente)
├── logs/                   # Logs del servidor
├── mods/                   # Mods instalados
└── cache/                  # Caché de archivos
```

---

## 🚀 Guía de Instalación

### Paso 1: Obtener Archivos del Servidor

Necesitas copiar los archivos desde tu instalación de Hytale:

#### Windows
```powershell
# Abre la carpeta del juego
explorer "%appdata%\Hytale\install\release\package\game\latest"
```

#### Linux
```bash
cd $XDG_DATA_HOME/Hytale/install/release/package/game/latest
```

#### macOS
```bash
cd ~/Application\ Support/Hytale/install/release/package/game/latest
```

**Copia estos archivos a la carpeta del proyecto:**
- 📁 `Server/` → Toda la carpeta
- 📦 `Assets.zip` → El archivo ZIP

---

### Paso 2: Construir y Ejecutar

```bash
# Construir la imagen
docker compose build

# Iniciar el servidor
docker compose up -d

# Ver logs en tiempo real
docker compose logs -f
```

El servidor mostrará cuando esté listo:
```
===============================================================================================
         Hytale Server Booted! [Multiplayer, Fresh Universe] took 10sec 185ms
===============================================================================================
```

---

### Paso 3: Autenticar el Servidor ⚠️ IMPORTANTE

El servidor **requiere autenticación** para aceptar conexiones de jugadores.

```bash
# Acceder a la consola del servidor
docker attach hytale-server
```

Dentro de la consola, ejecuta:
```
/auth login device
```

Verás algo como:
```
===================================================================
DEVICE AUTHORIZATION
===================================================================
Visit: https://accounts.hytale.com/device
Enter code: ABCD-1234
===================================================================
Waiting for authorization (expires in 900 seconds)...
```

1. 🌐 Abre el enlace en tu navegador
2. 🔑 Ingresa el código mostrado
3. 👤 Inicia sesión con tu cuenta de Hytale
4. ✅ El servidor confirmará: `Authentication successful!`

**Para salir de la consola sin detener el servidor:**
- Presiona `Ctrl+P` y luego `Ctrl+Q`

---

## 🌐 Conexión de Jugadores

Una vez autenticado, los jugadores pueden conectarse:

```
IP: tu-ip-publica
Puerto: 5520
```

### Configurar Firewall

#### Windows PowerShell (como administrador)
```powershell
New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

#### Linux (ufw)
```bash
sudo ufw allow 5520/udp
```

#### Linux (iptables)
```bash
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT
```

### Port Forwarding (Router)

Si estás detrás de un router, configura el reenvío de puertos:
- **Puerto externo:** 5520
- **Puerto interno:** 5520
- **Protocolo:** UDP (¡NO TCP!)
- **IP destino:** IP local de tu servidor

---

## ⚙️ Configuración

### Variables de Entorno

Edita `docker-compose.yaml` para personalizar:

| Variable | Valor por defecto | Descripción |
|----------|-------------------|-------------|
| `JAVA_OPTS` | `-Xms4G -Xmx4G` | Memoria RAM asignada |
| `SERVER_PORT` | `5520` | Puerto del servidor |

### Archivos de Configuración

| Archivo | Descripción |
|---------|-------------|
| `config.json` | Configuración general del servidor |
| `permissions.json` | Grupos y permisos de jugadores |
| `whitelist.json` | Lista blanca (si está habilitada) |
| `bans.json` | Jugadores baneados |

---

## 🔧 Comandos Útiles

```bash
# Iniciar servidor
docker compose up -d

# Detener servidor
docker compose down

# Ver logs
docker compose logs -f

# Reiniciar servidor
docker compose restart

# Acceder a consola
docker attach hytale-server

# Ver estado
docker compose ps

# Reconstruir imagen (después de actualizar archivos)
docker compose build --no-cache
docker compose up -d
```

---

## 🧩 Instalar Mods

1. Descarga mods (`.zip` o `.jar`) de [CurseForge](https://www.curseforge.com/hytale)
2. Colócalos en la carpeta `mods/`
3. Reinicia el servidor: `docker compose restart`

---

## 📊 Optimización

### Memoria RAM

Ajusta según tus necesidades en `docker-compose.yaml`:

```yaml
environment:
  - JAVA_OPTS=-Xms4G -Xmx8G  # Mínimo 4GB, máximo 8GB
```

### View Distance

El view distance afecta directamente el uso de RAM. Recomendado: **12 chunks** (384 bloques).

### AOT Cache

El servidor usa AOT Cache (`HytaleServer.aot`) para arranques más rápidos. Ya está configurado por defecto.

---

## ❓ Solución de Problemas

### El servidor no arranca
- Verifica que `Server/` y `Assets.zip` existan
- Revisa los logs: `docker compose logs`

### Los jugadores no pueden conectar
- ¿El servidor está autenticado? (`/auth login device`)
- ¿Puerto 5520/UDP abierto en firewall?
- ¿Port forwarding configurado en router?
- Recuerda: Hytale usa **UDP**, no TCP

### Error de memoria
- Aumenta `JAVA_OPTS` en docker-compose.yaml
- Verifica que tu sistema tenga suficiente RAM disponible

### Error de autenticación
- Cada licencia tiene límite de 100 servidores
- Contacta a Hytale si necesitas más capacidad

---

## 📚 Referencias

- [Manual Oficial de Hytale Server](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)
- [Guía de Autenticación para Proveedores](https://support.hytale.com/hc/en-us/articles/45328341414043)
- [Adoptium Temurin (Java 25)](https://adoptium.net/temurin/releases)

---

## 📄 Licencia

Este proyecto es solo una guía de configuración. Hytale es propiedad de Hypixel Studios.

---

**¿Problemas?** Abre un issue o consulta la [documentación oficial](https://support.hytale.com/).

sudo groupadd --system hytale
sudo useradd --system --gid hytale --home /opt/hytale --shell /usr/sbin/nologin hytale
usermod -s /bin/bash hytale

curl -fsSL -o hytale-downloader.zip https://downloader.hytale.com/hytale-downloader.zip
unzip hytale-downloader.zip

./hytale-downloader-linux-amd64



# 1. Instalar dependencias
sudo apt update
sudo apt install -y wget tar

# 2. Crear carpeta destino
sudo mkdir -p /opt/java

# 3. Descargar Temurin OpenJDK 25 (ajusta la URL si hay una versión más reciente)
wget -O /tmp/openjdk-25.tar.gz https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.1+8/OpenJDK25U-jdk_x64_linux_hotspot_25.0.1_8.tar.gz

# 4. Extraer en /opt/java/openjdk
sudo tar -xzf /tmp/openjdk-25.tar.gz -C /opt/java
sudo mv /opt/java/jdk-25.0.1+8 /opt/java/openjdk

# 5. Añadir a PATH (opcional, para la sesión actual)
export PATH=/opt/java/openjdk/bin:$PATH

# 6. Verificar instalación
java --version


/opt/java/openjdk/bin/java -Xms4G -Xmx4G -XX:AOTCache=/opt/hytale/Server/HytaleServer.aot -jar /opt/hytale/Server/HytaleServer.jar --assets /opt/hytale/Assets.zip --bind 0.0.0.0:5520


su - hytale -s /bin/bash -c "/opt/java/openjdk/bin/java -Xms4G -Xmx4G -XX:AOTCache=/opt/hytale/Server/HytaleServer.aot -jar /opt/hytale/Server/HytaleServer.jar --assets /opt/hytale/Assets.zip --bind 0.0.0.0:5520"

```
[Unit]
Description=Hytale Dedicated Server
After=network.target

[Service]
Type=simple
User=hytale
Group=hytale
WorkingDirectory=/opt/hytale
ExecStart=/opt/java/openjdk/bin/java -Xms4G -Xmx4G -XX:AOTCache=/opt/hytale/Server/HytaleServer.aot -jar /opt/hytale/Server/HytaleServer.jar --assets /opt/hytale/Assets.zip --bind 0.0.0.0:5520
Restart=on-failure
RestartSec=10
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

/auth login device

/auth persistence EnEncrypted

/auth status
