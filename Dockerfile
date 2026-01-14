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
    AOT_CACHE="/server/HytaleServer.aot"

# Create server user for security (non-root)
RUN groupadd -r hytale && useradd -r -g hytale hytale

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

# Switch to non-root user
USER hytale

# Volume mounts for persistent data
# VOLUME ["/server/universe", "/server/logs", "/server/mods", "/server/.cache"]

# Health check - Note: Hytale uses QUIC/UDP, standard HTTP checks won't work
# Consider using a plugin like Nitrado:Query for HTTP status endpoint
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
    CMD test -f /server/universe/config.json || exit 1

# Default command to start the server
# Uses AOT cache for faster startup (JEP-514)
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -XX:AOTCache=${AOT_CACHE} -jar HytaleServer.jar --assets ${ASSETS_PATH} --bind 0.0.0.0:${SERVER_PORT}"]
