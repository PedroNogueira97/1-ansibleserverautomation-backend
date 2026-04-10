# ARCHITECTURE.md — Ansible Server Automation

## Visão Geral

A arquitetura é simples: uma máquina local com Ansible instalado executa playbooks diretamente nas VPS remotas via SSH. Sem agentes, sem serviços extras.

```
Máquina Local
┌─────────────────────────────┐
│  Ansible CLI                │
│  Git (versionamento)        │  ──── SSH ────► VPS Alvo (Ubuntu 22.04+)
│  Playbooks / Roles          │
└─────────────────────────────┘
```

O Ansible é agentless: o único requisito no host remoto é Python 3 (já presente no Ubuntu por padrão).

---

## Instalação do Ansible

**Via apt (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
```

**Via pip (alternativa, qualquer SO):**
```bash
pip install --user ansible
ansible --version
```

**Versão recomendada:** `ansible-core >= 2.15`

## Um adendo, no projeto existe o arquivo **`backend/docker-compose.yml`:** e **`backend/Dockerfile`:**, pode instalar o ansible no docker ao invés de rodar direto no SO local, existe uma imagem do Docker oficial do ansible: [Imagem Docker Ansible](https://hub.docker.com/r/ansible/ansible) , faça como achar melhor.

---

## Estrutura do Projeto (além do que já tem disponível)

```
1-ansibleserverautomation-backend-dev.local/
├── inventory/
│   ├── hosts.ini              # Lista de hosts e grupos
│   └── group_vars/
│       └── all.yml            # Variáveis globais
├── roles/
│   ├── base/                  # Atualização do sistema e pacotes base
│   ├── deploy_user/           # Criação do usuário deploy e diretórios
│   ├── nginx/                 # Configuração do virtual host Nginx
│   └── ssl/                   # Certbot e Let's Encrypt
├── playbooks/
│   ├── setup_vps.yml          # Automação 1: provisionamento da VPS
│   └── setup_ssl.yml          # Automação 2: certificado SSL
├── ansible.cfg                # Configuração global
└── requirements.yml           # Roles externas (Ansible Galaxy)
```

---

## Configuração

**`ansible.cfg`:**
```ini
[defaults]
inventory           = inventory/hosts.ini
remote_user         = root
host_key_checking   = False
retry_files_enabled = False

[ssh_connection]
pipelining = True
```

**`inventory/hosts.ini`:**
```ini
[vps]
meuservidor ansible_host=123.456.789.0

[vps:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3
```

**`inventory/group_vars/all.yml`:**
```yaml
deploy_user: deploy
app_name: meuapp
app_dir: /var/www/meuapp
vps_domain: meusite.com.br
certbot_email: admin@meusite.com.br
```

---

## Executando as Playbooks

**Testar conectividade:**
```bash
ansible all -m ping
```

**Automação 1 — Provisionar VPS:**
```bash
ansible-playbook playbooks/setup_vps.yml
```

**Automação 2 — Gerar certificado SSL:**
```bash
ansible-playbook playbooks/setup_ssl.yml
```

**Sobrescrever variável na execução:**
```bash
ansible-playbook playbooks/setup_vps.yml -e "vps_domain=outrosite.com.br"
```

**Dry-run (verificar sem aplicar):**
```bash
ansible-playbook playbooks/setup_vps.yml --check
```

---

## Credenciais e Segurança

- A chave SSH privada usada para acessar a VPS deve estar em `~/.ssh/` na máquina local
- Variáveis sensíveis podem ser encriptadas com **Ansible Vault**:
```bash
# Encriptar um arquivo de variáveis
ansible-vault encrypt inventory/group_vars/secrets.yml

# Executar playbook com vault
ansible-playbook playbooks/setup_vps.yml --ask-vault-pass
```
- Recomendado: após o setup inicial, desabilitar login root por senha na VPS (`PasswordAuthentication no` no `sshd_config`)

---

## Requisitos de Sistema

| Componente | Onde roda | Requisito |
|---|---|---|
| Ansible CLI | Máquina local | Python 3.9+, Linux/macOS |
| VPS alvo | Provedor de nuvem | Ubuntu 22.04+, Python 3 |

---

## Referências

- [Documentação Ansible](https://docs.ansible.com)
- [Imagem Docker Ansible](https://hub.docker.com/r/ansible/ansible)
- `PRD.md` — Automações planejadas e critérios de aceitação
- `docs/TASKS.md` — Tarefas e status de implementação