---
weight: 190
title: "weather"
description: "Weather information provider using Pirate Weather API"
draft: false
---

The Weather module provides weather information using the Pirate Weather API. Users can get current weather conditions for any location worldwide.

## Features

- Get current weather for any location (city, address, postal code, etc.)
- Stores user's location search string and coordinates in SQLite database
- Rate limited to prevent abuse
- Configurable through YAML configuration
- Supports global locations
- Cross-platform compatibility

## Usage

### Getting Weather Information

To get weather information for a specific location:

```
weather [location]
```

Examples:
```
weather New York
weather London
weather 10001
weather Statue of Liberty
```

If you've previously set a location, you can simply use:
```
weather
```

### How It Works

1. When a user provides a location string, it's converted to coordinates using OpenStreetMap Nominatim
2. Both the original search string and coordinates are stored in a SQLite database for that user
3. Subsequent requests without a location use the stored search string and coordinates
4. Weather data is fetched from the Pirate Weather API using the coordinates

## Supported Location Formats

You can use various location formats:
- Postal codes (US, Canada, UK, etc.)
- City names ("New York", "London", "Tokyo")
- Addresses ("123 Main St, Anytown, ST")
- Landmarks ("Statue of Liberty", "Eiffel Tower")

## Configuration

To deploy the weather module, add it to your bot's `botModules` configuration with `moduleName: "weather"`:

```yaml
botModules:
- name: weather
  spec:
    size: 1
    image: ghcr.io/eeveebot/weather:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: weather
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
```

## Environment Variables

- `PIRATE_WEATHER_API_KEY` - Pirate Weather API key (get one at https://pirateweather.net/)