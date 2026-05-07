---
weight: 190
title: "weather"
description: "Weather information provider using Pirate Weather API"
draft: false
---

The Weather module provides weather information using the Pirate Weather API. Users can get current weather conditions and 5-day forecasts for any location worldwide.

## Features

- Get current weather for any location (city, address, postal code, etc.)
- Get 5-day forecast with `forecast` or `fivecast` commands
- Stores user's location search string and coordinates in SQLite database
- Rate limited to prevent abuse
- Configurable through YAML configuration
- Supports global locations
- Cross-platform compatibility
- IRC colorized output

## Usage

### Getting Current Weather

To get weather information for a specific location:

```
weather [location]
```

Examples:
```
weather New York
weather London
weather 10001
```

If you've previously set a location, you can simply use:
```
weather
```

### Getting a Forecast

To get a 5-day weather forecast:

```
forecast [location]
fivecast [location]
```

Both `forecast` and `fivecast` work identically. If you've previously set a location with the weather command, you can omit it.

### Environment Variables

- `PIRATE_WEATHER_API_KEY` - Pirate Weather API key (get one at https://pirateweather.net/)