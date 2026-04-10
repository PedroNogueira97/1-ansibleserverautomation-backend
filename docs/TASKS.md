# TASKS — Projeto Ansible (Provisionar VPS + Nginx + SSL)

> Objetivo operacional: você roda **Ansible no seu terminal local**, escolhe o host (VPS) no `inventory`, parametriza um “novo ambiente/projeto” (ex.: `app_name`, `app_dir`, `app_user`, `vps_domain`) e executa os playbooks para deixar **Nginx por app** e **SSL por domínio**.

---

## Configuração base do Ansible (estrutura do repo)

### Rodar Ansible 100% via Docker (sem instalar na máquina local)

- [ ] Usar `@1-ansibleserverautomation-backend-dev.local/backend/docker-compose.yml` para subir um container com Ansible
- [ ] Garantir que **nenhuma dependência Ansible** seja instalada no seu host local (só Docker)
- [ ] Montar volumes necessários para acessar:
  - [ ] `inventory/`
  - [ ] `group_vars/`
  - [ ] `playbooks/`
  - [ ] `roles/`
  - [ ] chave SSH (ex.: `~/.ssh` no host, se necessário)
- [ ] Garantir que o container tenha acesso à rede/porta SSH da VPS


- [x] Garantir/definir `ansible.cfg` (inventory, remote_user, host_key_checking, etc.)
- [x] Garantir/definir `inventory/hosts.ini` com um grupo para suas VPS (ex.: `[vps]`)
- [x] Garantir/definir `inventory/group_vars/all.yml` com defaults (pelo menos placeholders de variáveis)

### Definition of Done (base)

- [ ] `ansible all -m ping` conecta nos hosts do inventory (quando credenciais/ssh estiverem ok)

---

## Automação 1 — Provisionar VPS para um APP (Nginx por app + deploy user por app)

### Variáveis mínimas para parametrizar um novo app

- `app_name` (ex.: `meuapp`)
- `app_dir` (ex.: `/var/www/meuapp`)
- `app_user` (ex.: `deploy_meuapp`)
- `vps_domain` (domínio do app)
- `deploy_user_shell` (opcional, se você quiser shell padrão)

*(As variáveis devem ser aceitas via `group_vars` e/ou `-e` na execução.)*

### Playbook e roles

- [x] Criar/validar playbook `playbooks/setup_vps.yml`
  - [ ] Orquestrar roles: `base`, `app_user`, `nginx_site`

- [ ] Criar/validar role `base`
  - [ ] `apt update && apt upgrade -y`
  - [ ] Instalar pacotes base: `nginx`, `git`, `openssh-server`, `rsync`, `curl`

- [ ] Criar/validar role `app_user`
  - [ ] Criar usuário do app: `app_user` (sem privilégios root)
  - [ ] Criar diretório `app_dir`
  - [ ] `chown app_user:app_user app_dir`
  - [ ] Permissões padrão (ex.: 755 para diretórios)
  - [ ] Criar `index.html` em `app_dir` com `<h1>Deploy OK</h1>` rodando como `app_user`

- [ ] Criar/validar role `nginx_site`
  - [ ] Criar arquivo do site em `/etc/nginx/sites-available/{{ app_name }}`
  - [ ] Configurar `root {{ app_dir }}` e `index index.html`
  - [ ] Implementar `try_files` para SPA se aplicável ao seu caso (se não, manter mínimo conforme PRD)
  - [ ] Habilitar o site via symlink em `/etc/nginx/sites-enabled/{{ app_name }}`
  - [ ] **Não** remover `sites-enabled/default` de forma global se você puder ter ambientes diferentes (a task deve deixar claro como tratar)
  - [ ] Garantir `nginx -t` antes de restart
  - [ ] `systemctl restart nginx` e `systemctl enable nginx`

### Definition of Done (Automação 1)

- [ ] Você consegue provisionar **um app por vez** sem quebrar outros apps (multi-site)
- [ ] O playbook é **idempotente**
- [ ] `http://<ip-da-vps>` (ou `http://<vps_domain>`) retorna “Deploy OK” para o app correto
- [ ] `nginx -t` passa antes de qualquer restart

---

## Automação 2 — Gerar SSL (Certbot) para um APP/domínio

### Playbook e role

- [ ] Criar/validar playbook `playbooks/setup_ssl.yml`
  - [ ] Orquestrar role `ssl`

- [ ] Criar/validar role `ssl`
  - [ ] Instalar `certbot` e `python3-certbot-nginx`
  - [ ] Emitir certificado com:
    - `certbot --nginx -d {{ vps_domain }} -d www.{{ vps_domain }}`
  - [ ] Validar renovação:
    - `certbot renew --dry-run`
  - [ ] Garantir timer ativo:
    - `systemctl status certbot.timer`

### Definition of Done (Automação 2)

- [ ] Automação 1 já foi executada para o app e o Nginx está respondendo em 80
- [ ] DNS de `vps_domain` e `www.vps_domain` aponta para a VPS
- [ ] `https://{{ vps_domain }}` serve com certificado válido
- [ ] Renovação automática está habilitada (timer ativo)

---

## Segurança e parametrização (multi-app e multi-user)

- [ ] Variáveis sensíveis devem ser tratadas com Ansible Vault quando aplicável
- [ ] Garantir que criação de usuário/aplicação por app não vaze permissões entre apps
- [ ] (Opcional, mas previsto em docs) após setup inicial, desabilitar login root por senha em `sshd_config`

---

## Validação (checks que você roda localmente)

- [ ] `ansible all -m ping`
- [ ] `ansible-playbook playbooks/setup_vps.yml --check`
- [ ] `ansible-playbook playbooks/setup_vps.yml` e validar:
  - [ ] criação do usuário `app_user`
  - [ ] `index.html` correto em `app_dir`
  - [ ] Nginx carregou o site do app (`nginx -t` sem erros)
- [ ] `ansible-playbook playbooks/setup_ssl.yml --check`
- [ ] `ansible-playbook playbooks/setup_ssl.yml` e validar:
  - [ ] `certbot renew --dry-run`
  - [ ] HTTPS funcionando e timer ativo

---

## Fora do escopo (por ora)

- [ ] Configuração de firewall (UFW/iptables)
- [ ] Deploy da aplicação em si (apenas provisionamento de infraestrutura)
- [ ] Suporte a distribuições não-Debian
- [ ] Suporte a múltiplos sites no mesmo `app_name` (o foco é 1 nginx/site por app)
