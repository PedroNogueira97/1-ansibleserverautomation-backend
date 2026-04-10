(Este arquivo foi criado para atender seu pedido de colocar arquivos .md dentro de /workspace/1-ansibleserverautomation-backend-dev.local/docs.)

Plan atual:
- Runner Docker: `backend/docker-compose.yml` e `backend/Dockerfile`.
- Estrutura Ansible: `ansible.cfg`, `inventory/`, `playbooks/`, `roles/`.
- Automação 1: `setup_vps.yml` com roles base -> app_user -> nginx_site.
- Automação 2: `setup_ssl.yml` com role ssl e timer/renovação.
