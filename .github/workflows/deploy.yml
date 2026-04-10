name: Deploy to VPS

on:
  push:
    branches:
      - main
  workflow_dispatch:

concurrency:
  group: deploy-production
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.VPS_SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan -p "${{ secrets.VPS_SSH_PORT }}" "${{ secrets.VPS_HOST }}" >> ~/.ssh/known_hosts

      - name: Upload project files
        run: |
          rsync -avz --delete \
            -e "ssh -p ${{ secrets.VPS_SSH_PORT }}" \
            --exclude ".git" \
            --exclude ".github" \
            ./ ${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}:${{ secrets.VPS_APP_DIR }}/

      - name: Create .env on VPS
        run: |
          ssh -p "${{ secrets.VPS_SSH_PORT }}" "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}" << 'EOF'
            mkdir -p "${{ secrets.VPS_APP_DIR }}"
            cat > "${{ secrets.VPS_APP_DIR }}/.env" << EOT
            APP_ENV=production
            APP_PORT=${{ secrets.APP_PORT }}
            ${{
              secrets.APP_ENV_FILE_EXTRA
            }}
            EOT
          EOF

      - name: Run deploy script
        run: |
          ssh -p "${{ secrets.VPS_SSH_PORT }}" "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}" \
            "cd '${{ secrets.VPS_APP_DIR }}' && chmod +x ops/deploy.sh && ./ops/deploy.sh"

      - name: Smoke check
        run: |
          ssh -p "${{ secrets.VPS_SSH_PORT }}" "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}" \
            "cd '${{ secrets.VPS_APP_DIR }}' && docker compose ps"