# =============================================================================
# Hytale Server Dockerfile
# Based on: https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Downloader - Download server files using Hytale Downloader CLI
# -----------------------------------------------------------------------------
FROM eclipse-temurin:25-jdk AS downloader

WORKDIR /download

# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download the Hytale Downloader CLI
RUN curl -fsSL -o hytale-downloader.zip https://downloader.hytale.com/hytale-downloader.zip \
    && unzip hytale-downloader.zip \
    && chmod +x hytale-downloader

# Note: The actual download requires OAuth2 authentication
# You will need to either:
# 1. Mount pre-downloaded server files
# 2. Run the downloader interactively first and copy the files
# 3. Use device authorization flow

# -----------------------------------------------------------------------------
# Stage 2: Runtime - Run the Hytale Server
# -----------------------------------------------------------------------------
FROM eclipse-temurin:25-jre

LABEL maintainer="Hytale Server Admin"
LABEL description="Hytale Dedicated Server"
LABEL version="1.0"

# Environment variables for server configuration
ENV JAVA_OPTS="-Xms4G -Xmx4G" \
    SERVER_PORT=5520 \
    ASSETS_PATH="/server/Assets.zip" \
    USE_AOT="false" \
    PUID=1000 \
    PGID=1000

# Create server user with configurable UID/GID for volume permissions
RUN groupadd -g ${PGID} hytale && useradd -u ${PUID} -g hytale hytale

# Create server directories
RUN mkdir -p /server/mods /server/universe /server/logs /server/.cache \
    && chown -R hytale:hytale /server

WORKDIR /server

# Copy server files from build context
# You need to place these files in the same directory as the Dockerfile:
# - Server/ folder contents (HytaleServer.jar, HytaleServer.aot, etc.)
# - Assets.zip

COPY --chown=hytale:hytale Server/ /server/
COPY --chown=hytale:hytale Assets.zip /server/

# Expose the default Hytale server port (UDP)
# Hytale uses QUIC protocol over UDP, NOT TCP
EXPOSE ${SERVER_PORT}/udp

# Health check - Note: Hytale uses QUIC/UDP, standard HTTP checks won't work
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
    CMD test -f /server/universe/config.json || exit 1

# Create entrypoint script to handle permissions and AOT cache
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Fix permissions on mounted volumes\n\
chown -R hytale:hytale /server/universe /server/logs /server/mods /server/.cache 2>/dev/null || true\n\
\n\
# Build Java command\n\
JAVA_CMD="java ${JAVA_OPTS}"\n\
\n\
# Add AOT cache only if enabled and file exists\n\
if [ "${USE_AOT}" = "true" ] && [ -f "/server/HytaleServer.aot" ]; then\n\
    JAVA_CMD="${JAVA_CMD} -XX:AOTCache=/server/HytaleServer.aot"\n\
fi\n\
\n\
# Start server as hytale user\n\
exec su-exec hytale ${JAVA_CMD} -jar HytaleServer.jar --assets ${ASSETS_PATH} --bind 0.0.0.0:${SERVER_PORT}\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Install su-exec for running as non-root
RUN apt-get update && apt-get install -y --no-install-recommends gosu \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/sbin/gosu /usr/local/bin/su-exec

ENTRYPOINT ["/entrypoint.sh"]
