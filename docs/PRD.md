# PRD — Ansible Server Automation

## Visão Geral

Este projeto irá utilizar **Ansible** (veja `ARCHITECTURE.md`) para criar automações reproduzíveis e idempotentes no servidor. O objetivo é eliminar configuração manual de VPS, reduzindo erros humanos e acelerando o processo de deploy em novos ambientes.

---

## Contexto e Motivação

Configurar manualmente uma VPS é repetitivo, propenso a inconsistências e difícil de auditar. Com Ansible, cada tarefa vira código versionável e reexecutável com segurança.

---

## Automações Planejadas

### 1. Preparar VPS para Projeto Simples com Nginx

**Objetivo:** Configurar uma VPS do zero para servir uma aplicação web estática, com Nginx corretamente configurado e usuário de deploy isolado.

**Pré-condições:**
- Acesso SSH root à VPS
- Ubuntu 22.04+ (ou Debian equivalente)
- Domínio com DNS gerenciável

**Etapas da Playbook:**

#### 1.1 Atualização do Sistema e Instalação de Dependências
```
apt update && apt upgrade -y
apt install -y nginx git openssh-server rsync curl
```

#### 1.2 Criação de Usuário e Estrutura de Diretórios
- Criar usuário `deploy` (sem privilégios root)
- Criar diretório `/var/www/meuapp`
- Atribuir ownership: `deploy:deploy`
- Definir permissões: `755`

#### 1.3 Página de Teste
- Criar `/var/www/meuapp/index.html` como usuário `deploy`
- Conteúdo mínimo para validar o setup: `<h1>Deploy OK</h1>`

#### 1.4 Configuração do Nginx

Criar o virtual host em `/etc/nginx/sites-available/meuapp`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name dominio.com.br www.dominio.com.br;

    root /var/www/meuapp;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
}
```

Ativar o site e remover o default:
```
ln -s /etc/nginx/sites-available/meuapp /etc/nginx/sites-enabled/meuapp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl enable nginx
```

#### 1.5 DNS (Fora do Escopo da Playbook — Ação Manual)
> Configurar no painel do provedor de domínio:
> - Registro `A` para `@` apontando para o IP da VPS
> - Registro `A` para `www` apontando para o IP da VPS
>
> Aguardar propagação de DNS antes de executar a automação de SSL.

**Variáveis da Playbook:**

| Variável | Descrição | Exemplo |
|---|---|---|
| `vps_domain` | Domínio principal | `meusite.com.br` |
| `app_name` | Nome da aplicação | `meuapp` |
| `app_dir` | Caminho raiz da aplicação | `/var/www/meuapp` |
| `deploy_user` | Usuário de deploy | `deploy` |

**Extensão Futura:** Adicionar flag opcional `install_database` para instalar e configurar PostgreSQL ou MySQL durante o provisionamento.

---

### 2. Gerar Certificado SSL com Let's Encrypt

**Objetivo:** Instalar o Certbot e emitir um certificado SSL válido via Let's Encrypt, com renovação automática configurada.

**Pré-condições:**
- Automação 1 concluída com sucesso
- DNS já propagado (registro A apontando corretamente para a VPS)
- Nginx em execução e respondendo na porta 80

**Etapas da Playbook:**

#### 2.1 Instalação do Certbot
```
apt update
apt install -y certbot python3-certbot-nginx
```

#### 2.2 Emissão do Certificado
```
certbot --nginx -d {{ vps_domain }} -d www.{{ vps_domain }}
```
O Certbot modifica automaticamente o virtual host Nginx para redirecionar HTTP → HTTPS.

#### 2.3 Validação da Renovação Automática
```
certbot renew --dry-run
systemctl status certbot.timer
```

**Variáveis da Playbook:**

| Variável | Descrição | Exemplo |
|---|---|---|
| `vps_domain` | Domínio principal | `meusite.com.br` |
| `certbot_email` | E-mail para notificações de expiração | `admin@meusite.com.br` |

---

## Critérios de Aceitação

- [ ] A playbook é **idempotente**: pode ser reexecutada sem efeitos colaterais
- [ ] Variáveis sensíveis (IP, domínio, e-mail) são parametrizadas via Ansible Vault
- [ ] Após a automação 1, a URL `http://<IP-da-VPS>` retorna a página de teste
- [ ] Após a automação 2, a URL `https://dominio.com.br` serve com certificado válido
- [ ] `nginx -t` passa sem erros antes de qualquer restart
- [ ] O timer de renovação automática do Certbot está ativo

---

## Fora do Escopo (por ora)

- Configuração de firewall (UFW/iptables)
- Deploy da aplicação em si (apenas provisionamento da infraestrutura)
- Suporte a distribuições não-Debian
- Configuração de múltiplos sites no mesmo servidor

---

## Referências

- `ARCHITECTURE.md` — Detalhes sobre Ansible
- `docs/TASKS.md` — Tarefas e status de implementação