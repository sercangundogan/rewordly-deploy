# Rewordly Deployment

Docker Compose setup for Rewordly services.

## Services

- **languagetool**: LanguageTool grammar checking service (port 8010)
- **rewordly-server**: Rewordly WebSocket server (port 8081)

## Quick Start

### Automated Deployment (Recommended)

Run the deployment script directly on the server to pull latest code and start services:

```bash
cd /root/rewordly/rewordly-deploy
./deploy.sh
```

**Note:** The script will automatically make itself executable. If you get "Permission denied", run once:
```bash
chmod +x deploy.sh
./deploy.sh
```

After that, the script handles file permissions automatically and git will ignore chmod changes.

**With custom directory:**
```bash
REWORDLY_DIR=/opt/rewordly ./deploy.sh
```

### Manual Deployment

1. Copy environment file:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` and add your OpenAI API key:
   ```env
   OPENAI_API_KEY=your_openai_api_key_here
   ```

3. Start services:
   ```bash
   # Docker Compose V2 (newer)
   docker compose up -d
   
   # Or Docker Compose V1 (older)
   docker-compose up -d
   ```

4. Check logs:
   ```bash
   docker compose logs -f
   # or
   docker-compose logs -f
   ```

5. Stop services:
   ```bash
   docker compose down
   # or
   docker-compose down
   ```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WS_PORT` | `8081` | WebSocket server port |
| `ALLOWED_ORIGINS` | `chrome-extension://*` | Allowed WebSocket origins |
| `LANGUAGETOOL_PORT` | `8010` | LanguageTool service port |
| `OPENAI_API_KEY` | **Required** | OpenAI API key |

## Service URLs

- **LanguageTool**: `http://localhost:8010`
- **Rewordly WebSocket (WSS)**: `wss://161.35.153.201` (via Nginx)
- **Rewordly WebSocket (direct)**: `ws://localhost:8081` (internal only)

## SSL/WSS Setup

⚠️ **Important**: HTTPS pages require WSS (secure WebSocket). See [SSL_SETUP.md](./SSL_SETUP.md) for SSL certificate setup.

After SSL setup, extension will connect via `wss://161.35.153.201`.

## Health Checks

Both services include health checks:
- LanguageTool: Checks `/v2/languages` endpoint
- Rewordly Server: Checks WebSocket connection

## Network

Services communicate via Docker network `rewordly-network`. LanguageTool is accessible to rewordly-server at `http://languagetool:8010`.

## Deployment Script

The `deploy.sh` script automates:
1. Git pull for both `rewordly-server` and `rewordly-deploy`
2. Docker Compose build and start
3. Service status check

**Prerequisites:**
- Run on the server (SSH into server first)
- Git repositories cloned on server
- Docker and Docker Compose installed on server

**Environment variables (optional):**
- `REWORDLY_DIR`: Target directory on server (default: /root/rewordly)

## Rebuilding

To rebuild rewordly-server after code changes:

```bash
# Use docker compose (V2) or docker-compose (V1)
docker compose build rewordly-server
docker compose up -d rewordly-server

# Or with docker-compose (V1)
docker-compose build rewordly-server
docker-compose up -d rewordly-server
```

Or use the deployment script which automatically pulls latest code and detects the correct command.

## Troubleshooting

### Check service status:
```bash
docker compose ps
# or
docker-compose ps
```

### View logs:
```bash
docker compose logs languagetool
docker compose logs rewordly-server
# or
docker-compose logs languagetool
docker-compose logs rewordly-server
```

### Restart a service:
```bash
docker compose restart rewordly-server
# or
docker-compose restart rewordly-server
```
