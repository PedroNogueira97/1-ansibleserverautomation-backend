# Deploy

## Secrets necessários no GitHub

- `VPS_HOST`
- `VPS_SSH_PORT`
- `VPS_USER`
- `VPS_SSH_PRIVATE_KEY`
- `VPS_APP_DIR`
- `APP_PORT`
- `APP_ENV_FILE_EXTRA`

## Exemplo de VPS_APP_DIR

```bash
/opt/ansibleserverautomation

## Exemplo de APP_ENV_FILE_EXTRA

DATABASE_URL=postgresql://user:pass@host:5432/dbname
SECRET_KEY=supersecret
API_KEY=xxxxx

# Fluxo
Push na main:

- roda CI
- faz upload para a VPS
- recria .env
- executa ops/deploy.sh


---

# 6 Templates de produção por tipo

## Backend
Arquivo:

`workspace/project-templates/backend/docker-compose.prod.yml.tpl`

```yaml
services:
  app:
    build: .
    container_name: ansibleserverautomation-app
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "{{APP_PORT}}:{{APP_PORT}}"

## Frontend
Arquivo:

`workspace/project-templates/frontend/docker-compose.prod.yml.tpl`

services:
  frontend:
    build: .
    container_name: ansibleserverautomation-frontend
    restart: unless-stopped
    ports:
      - "{{APP_PORT}}:80"

