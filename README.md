# Rewordly Deployment

Docker Compose setup for Rewordly services.

## Services

- **languagetool**: LanguageTool grammar checking service (port 8010)
- **rewordly-server**: Rewordly WebSocket server (port 8081)

## Quick Start

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
- **Rewordly WebSocket**: `ws://localhost:8081`

## Health Checks

Both services include health checks:
- LanguageTool: Checks `/v2/languages` endpoint
- Rewordly Server: Checks WebSocket connection

## Network

Services communicate via Docker network `rewordly-network`. LanguageTool is accessible to rewordly-server at `http://languagetool:8010`.

## Rebuilding

To rebuild rewordly-server after code changes:

```bash
docker-compose build rewordly-server
docker-compose up -d rewordly-server
```

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
