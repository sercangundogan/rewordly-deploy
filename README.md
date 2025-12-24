# Rewordly Deployment

Docker Compose setup for Rewordly services.

## Services

- **languagetool**: LanguageTool grammar checking service (port 8010)
- **rewordly-server**: Rewordly WebSocket server (port 8081)

## Quick Start

### Automated Deployment (Recommended)

Use the deployment script to automatically pull latest code and start services:

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

**Windows (PowerShell):**
```powershell
.\deploy.ps1
```

**With custom settings:**
```bash
DEPLOY_HOST=your-server.com DEPLOY_USER=root ./deploy.sh
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
   docker-compose up -d
   ```

4. Check logs:
   ```bash
   docker-compose logs -f
   ```

5. Stop services:
   ```bash
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

The `deploy.sh` (Linux/Mac) or `deploy.ps1` (Windows) script automates:
1. SSH connection to server
2. Git pull for both `rewordly-server` and `rewordly-deploy`
3. Docker Compose build and start
4. Service status check

**Prerequisites:**
- SSH access to server
- Git repositories cloned on server
- Docker and Docker Compose installed on server

**Environment variables (optional):**
- `DEPLOY_HOST`: Server IP/hostname (default: 161.35.153.201)
- `DEPLOY_USER`: SSH user (default: root)
- `REWORDLY_DIR`: Target directory on server (default: /root/rewordly)

## Rebuilding

To rebuild rewordly-server after code changes:

```bash
docker-compose build rewordly-server
docker-compose up -d rewordly-server
```

Or use the deployment script which automatically pulls latest code.

## Troubleshooting

### Check service status:
```bash
docker-compose ps
```

### View logs:
```bash
docker-compose logs languagetool
docker-compose logs rewordly-server
```

### Restart a service:
```bash
docker-compose restart rewordly-server
```
