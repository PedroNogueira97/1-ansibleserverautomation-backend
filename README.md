# Ansible Server Automation

Este projeto provisiona uma VPS (Ubuntu 22.04+ / Debian) para servir **um app por vez** com **Nginx** e, em seguida, habilita **SSL via Let’s Encrypt (Certbot)**.

A execução do Ansible acontece **100% via Docker** (sem instalar nada na máquina local). Você sobe um runner e executa os playbooks a partir do seu terminal.

## Estrutura

- `backend/` : Docker runner do Ansible (compose)
- `inventory/` : hosts e variáveis
- `playbooks/` : automações `setup_vps.yml` e `setup_ssl.yml`
- `roles/` : `base`, `app_user`, `nginx_site`, `ssl`

## Pré-requisitos

- Docker + Docker Compose
- Acesso SSH à VPS (usuário tipicamente `root`, conforme `inventory/hosts.ini`)
- Para SSL: DNS de `vps_domain` apontando para a VPS (registro `A` para `@` e `www`)

## Como usar (fluxo)

### 1) Subir o runner

```bash
cd backend
docker compose up -d
```

### 2) Provisionar VPS para um APP (Nginx por app)

Exemplo (ajuste variáveis):

```bash
docker compose exec ansible-runner ansible-playbook \
  /workspace/1-ansibleserverautomation-backend-dev.local/playbooks/setup_vps.yml \
  -e "app_name=meuapp" \
  -e "app_dir=/var/www/meuapp" \
  -e "app_user=deploy_meuapp" \
  -e "vps_domain=meusite.com.br"
```

### 3) Gerar SSL para o domínio do app

```bash
docker compose exec ansible-runner ansible-playbook \
  /workspace/1-ansibleserverautomation-backend-dev.local/playbooks/setup_ssl.yml \
  -e "vps_domain=meusite.com.br" \
  -e "certbot_email=admin@meusite.com.br"
```

## Variáveis principais

- `app_name`: nome do app (também usado no nome do site Nginx)
- `app_dir`: diretório root do site
- `app_user`: usuário criado para o deploy do app (multi-app)
- `vps_domain`: domínio principal
- `certbot_email`: e-mail para notificações do certbot

## Observações

- O objetivo do projeto é ser idempotente: reexecutar playbooks não deve quebrar ambientes existentes.
- Tasks e critérios de aceitação estão documentados em `docs/TASKS.md` e `docs/PRD.md`.
