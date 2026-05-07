---
weight: 180
title: "urltitle"
description: "Automatic URL title fetching for posted links"
draft: false
---

The URL Title module automatically fetches and displays titles for URLs posted in chat messages. It uses broadcast registration to listen to all messages and extracts URLs for title lookup.

## Features

- Automatic URL detection in chat messages
- Title extraction from webpages
- Support for standard HTML title tags
- Support for OpenGraph title meta tags as fallback
- YouTube video title and channel extraction via YouTube Data API
- URL title caching with automatic expiration
- IRC colorized output
- Cross-platform compatibility

## Usage

Simply post any URL in a channel where the bot is active, and it will automatically respond with the page title:

```none
<User> Check this out: https://example.com/some-page
<Bot> [Example Domain]
```

For YouTube videos, the module displays the video title and channel name:

```none
<User> https://www.youtube.com/watch?v=dQw4w9WgXcQ
<Bot> [Rick Astley - Never Gonna Give You Up]
```

The module listens to all incoming chat messages via broadcast registration and automatically extracts any URLs found in the text.

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
    envSecret:
      name: eevee-bot-urltitle-secrets
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

## Environment Variables

- `YOUTUBE_API_KEY` - YouTube Data API key for enhanced YouTube video information (optional)
