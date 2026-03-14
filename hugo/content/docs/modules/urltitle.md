---
weight: 180
title: "urltitle"
description: "Automatic URL title fetching for posted links"
draft: false
---

The URL Title module automatically fetches and displays titles for URLs posted in chat messages. It listens conversations by providing context about shared links.

## Features

- Automatic URL detection in chat messages
- Title extraction from webpages
- Support for standard HTML title tags
- Support for OpenGraph title meta tags as fallback
- Configurable user agent and timeout settings
- Automatic handling of redirects
- Cross-platform compatibility

## Usage

Simply post any URL in a channel where the bot is active, and it will automatically respond with the page title:

```
<User> Check this out: https://example.com/some-page
<Bot> [Example Domain]
```

The module listens to all incoming chat messages and automatically extracts any URLs found in the text. For each URL detected, it fetches the webpage and extracts the title tag, then posts the title back to the channel.

## Configuration

To deploy the urltitle module, add it to your bot's `botModules` configuration with `moduleName: "urltitle"`:

```yaml
botModules:
- name: urltitle
  spec:
    size: 1
    image: ghcr.io/eeveebot/urltitle:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: urltitle
    moduleConfig: |
      #: "Custom Bot Name 1.0"
      timeout: 5000
```

## Technical Details

- Listens to `chat.message.incoming.>` NATS topic
- Publishes responses to `chat.message.outgoing.$PLATFORM.$INSTANCE.$CHANNEL`
- Built with Node.js, TypeScript, axios, and cheerio