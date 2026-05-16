---
weight: 180
title: "urltitle"
description: "Automatic URL title fetching for posted links"
draft: false
---

The URL Title module automatically fetches and displays titles for URLs posted in chat messages. It operates as a broadcast listener — it registers a broadcast filter with the router (matching only messages containing URLs), receives matching messages via NATS, and sends titled responses back through the same messaging pipeline. No explicit command invocation is needed; the module activates automatically whenever someone posts a link.

## Features

- Automatic URL detection — regex-based extraction of `http`/`https` URLs from any chat message
- HTML title extraction — fetches the `<title>` tag from the target page
- YouTube integration — rich metadata (title, publish date, view count, likes, duration) for videos, Shorts, and live streams via the YouTube Data API
- In-memory caching — 10-minute TTL cache reduces duplicate fetches for repeated URLs
- Platform-aware colorization — IRC responses use mIRC color codes; other platforms receive plain text
- Content-type filtering — only processes `text/html` responses; skips images, PDFs, and other binary content
- Configurable rate limiting
- Automatic help registration

## Usage

Simply post any URL in a channel where the bot is active, and it will automatically respond with the page title. Only the first URL title per message is posted, to avoid spam in messages containing multiple links.

**Standard URL:**

```none
<User> Check this out: https://example.com/some-page
<Bot> Title: Example Domain
```

**YouTube video (with API key configured):**

```none
<User> https://www.youtube.com/watch?v=dQw4w9WgXcQ
<Bot> Rick Astley - Never Gonna Give You Up | 📅 Oct 28, 2009 | 👁️ 1.5B | 👍 15.0M | ⏱️ 3:33
```

**YouTube Short:**

```none
<User> https://youtube.com/shorts/abc12345678
<Bot> Some Short Title #[SHORT] | 📅 Jan 1, 2025 | 👁️ 50.0K | 👍 2.1K | ⏱️ 0:15
```

**YouTube Live stream:**

```none
<User> https://youtube.com/live/xyz12345678
<Bot> Live Stream Title #[LIVE] | 📅 Mar 15, 2026 | 👁️ 12.0K | 👍 800 | ⏱️ 1:45:00
```

## YouTube Integration

When a `YOUTUBE_API_KEY` is configured, the module queries the YouTube Data API for rich metadata. It detects three URL patterns:

- **Standard videos:** `youtube.com/watch?v=` — labeled with video metadata
- **Shorts:** `youtube.com/shorts/` — labeled with `#[SHORT]`
- **Live streams:** `youtube.com/live/` — labeled with `#[LIVE]`

Without an API key, YouTube links fall back to standard HTML title fetching.

## Caching

The module maintains an in-memory `Map<string, CacheEntry>` with a 10-minute TTL. A cleanup interval runs every 5 minutes to evict expired entries. This reduces duplicate fetches when the same URL is posted multiple times in quick succession.

## Content-Type Filtering

The module only processes HTTP responses with a `text/html` content type. Binary content (images, PDFs, etc.) is skipped entirely, preventing unnecessary processing and potential errors from trying to parse non-HTML responses.

Other defaults:

| Setting | Default | Description |
|---------|---------|-------------|
| HTTP User-Agent | `Mozilla/5.0 (compatible; eevee.bot URL Title Fetcher; +https://eevee.bot)` | Hardcoded in fetch requests |
| HTTP timeout | 10 seconds | Via `AbortSignal.timeout(10000)` |
| Title max length | 200 characters | Truncated with `...` if exceeded |
| Cache TTL | 10 minutes | In-memory, cleaned every 5 minutes |
| Broadcast TTL | 120 seconds | Router broadcast registration TTL |

## NATS Subjects

| Direction | Subject | Purpose |
|-----------|---------|---------|
| Out | `broadcast.register` | Register URL-filtered broadcast with the router |
| In | `broadcast.message.<UUID>` | Receive messages containing URLs |
| In | `control.registerBroadcasts` | Re-register broadcasts (global) |
| In | `control.registerBroadcasts.urltitle` | Re-register broadcasts (module-specific) |
| Out | `chat.message.outgoing.*` | Send titled responses |

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

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `YOUTUBE_API_KEY` | No | YouTube Data API v3 key. Enables rich metadata for YouTube URLs. Without it, YouTube links fall back to standard HTML title fetching. |
