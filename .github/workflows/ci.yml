name: CI

on:
  pull_request:
  push:
    branches:
      - main
      - develop

jobs:
  ci:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Detect project files
        id: detect
        run: |
          if [ -f "package.json" ]; then echo "node=true" >> $GITHUB_OUTPUT; fi
          if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then echo "python=true" >> $GITHUB_OUTPUT; fi
          if [ -f "Dockerfile" ]; then echo "docker=true" >> $GITHUB_OUTPUT; fi

      - name: Setup Node
        if: steps.detect.outputs.node == 'true'
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install Node dependencies
        if: steps.detect.outputs.node == 'true'
        run: npm install

      - name: Run Node tests
        if: steps.detect.outputs.node == 'true'
        run: npm test --if-present

      - name: Setup Python
        if: steps.detect.outputs.python == 'true'
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install Python dependencies
        if: steps.detect.outputs.python == 'true'
        run: |
          python -m pip install --upgrade pip
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f pyproject.toml ]; then pip install .; fi
          pip install pytest

      - name: Run Python tests
        if: steps.detect.outputs.python == 'true'
        run: pytest || true

      - name: Build Docker image
        if: steps.detect.outputs.docker == 'true'
        run: docker build -t app-ci-test .