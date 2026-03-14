---
weight: 120
title: "cli"
description: "Command-line interface for eevee management"
draft: false
---

The CLI module provides a command-line interface for managing eevee.bot instances. It allows administrators to perform various management tasks directly from the command line.

## Features

- Command-line management interface
- Administrative functions for eevee.bot instances
- Cross-platform compatibility

## Usage

The CLI module is designed to be used as a standalone command-line tool for managing eevee.bot deployments and configurations.

## Configuration

To deploy the CLI module, add it to your bot's `botModules` configuration with `moduleName: "cli"`:

```yaml
botModules:
- name: cli
  spec:
    size: 1
    image: ghcr.io/eeveebot/cli:latest
    pullPolicy: Always
    ipcConfig: my-eevee-bot
    moduleName: cli
```