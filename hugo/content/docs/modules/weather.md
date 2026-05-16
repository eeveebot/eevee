---
weight: 190
title: "weather"
description: "Weather information provider using Pirate Weather API"
draft: false
---

The Weather module provides current conditions and 5-day forecasts for any location worldwide, powered by the Pirate Weather API. Locations are geocoded via OpenStreetMap Nominatim and stored per-user in SQLite, so you only need to set your location once.

## Features

- Current weather for any location (city, address, postal code, landmark, etc.)
- 5-day forecast via `forecast` and `fivecast` commands
- Per-user location storage — set it once, query without arguments
- Configurable units: imperial (°F/mph), metric (°C/km/h), or Kelvin
- Unit preference persistence — your chosen units are remembered across sessions
- Obscure mode (`-o` flag) — hides your location string from responses
- Colorized output on IRC with weather-condition emoji
- Rate limited to prevent abuse

## Commands

### `weather [location] [-c|-f|-k] [-o]`

Get current weather for a location. If no location is provided, your previously stored location is used.

| Flag | Description |
|------|-------------|
| `-c` | Use Celsius / metric units |
| `-f` | Use Fahrenheit / imperial units |
| `-k` | Use Kelvin |
| `-o` | Toggle obscure mode (hides your location in the response) |

**Examples:**

```
!weather New York
!weather 90210 -c
!weather -f
!weather Tokyo -o
```

The current weather output includes temperature, conditions summary, daily high/low, humidity, wind speed (with gusts), and precipitation chance.

### `forecast [location] [-c|-f|-k] [-o]`

Get a 5-day weather forecast. `fivecast` is an alias and works identically. Accepts the same flags as `weather`.

**Examples:**

```
!forecast London
!fivecast Berlin -c
!forecast -k
!fivecast -o
```

Each forecast day shows the day name, conditions summary, high and low temperatures, and precipitation chance.

## Unit Persistence

When you use a flag (e.g. `-c`, `-f`, `-k`, `-o`), the module saves that preference to the database. Future `weather` and `forecast` commands will use your stored preference automatically — no need to specify the flag every time.

To change your default units, just use a flag again:

```
!weather -c          # switches to Celsius and saves the preference
!weather             # next time, Celsius is used automatically
```

The default unit system is imperial (°F, mph) for new users.

## Obscure Mode

Obscure mode replaces your location string with your nickname in bot responses, so other users in the channel won't see where you are. Use the `-o` flag to toggle it on or off:

```
!weather -o          # toggles obscure mode (shows your nick instead of location)
!weather Tokyo -o    # sets location to Tokyo and toggles obscure mode
```

When obscure mode is **on**, responses appear as:

```
Weather for yournick: Clear, 72°F (H:78°F/L:65°F), 45% humidity, 5 mph wind
```

When obscure mode is **off** (the default), responses show the location:

```
Weather for Tokyo: Clear, 22°C (H:26°C/L:18°C), 45% humidity, 8 km/h wind
```

## Supported Location Formats

The module accepts a variety of location strings, geocoded through OpenStreetMap Nominatim:

| Format | Examples |
|--------|----------|
| US ZIP codes | `10001`, `90210` |
| Canadian postal codes | `M5A 1A1` |
| City names | `New York`, `London`, `Tokyo` |
| Addresses | `123 Main St, Anytown, ST` |
| Landmarks | `Statue of Liberty`, `Eiffel Tower` |

US ZIP codes and Canadian postal codes are detected automatically and queried with country-specific geocoding for more accurate results.

## Configuration

The module reads optional rate-limit configuration from a YAML file (path set by the `MODULE_CONFIG_PATH` environment variable):

```yaml
ratelimit:
  mode: drop       # "drop" or "queue"
  level: user      # "user" or "channel"
  limit: 5         # max requests per interval
  interval: 1m     # time window
```

All keys are optional — sensible defaults are provided by `@eeveebot/libeevee`.

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PIRATE_WEATHER_API_KEY` | Pirate Weather API key ([get one](https://pirateweather.net/)) | Yes |
| `MODULE_DATA` | Directory for the SQLite database (`weather.db`) | Yes |
| `NATS_HOST` | NATS server hostname | Yes |
| `NATS_TOKEN` | NATS authentication token | Yes |
| `MODULE_CONFIG_PATH` | Path to the YAML configuration file | No |
| `HTTP_API_PORT` | Port for the HTTP metrics/health server (default: `9000`) | No |
