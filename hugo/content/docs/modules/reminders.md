---
weight: 195
title: "reminders"
description: "Time-based reminders with timezone support and recurring schedules"
draft: false
---

The Reminders module delivers time-based reminders back to the originating
channel or by direct message. Reminders can be one-shot ("remind me in 90
minutes") or recurring on a crontab schedule, with per-user timezone
preferences, channel announcements for admins, and full list, cancel, and
edit management.

## Features

- One-shot reminders with relative (`1h30m`) or wall-clock (`10:00`) times
- Recurring reminders with 5- or 6-field crontab expressions
- Per-user timezone preferences (`tzset`) with DST handling, plus a
  per-reminder `-z` override
- DM delivery (`-p`) and channel-admin announcements (`-a`)
- List, cancel, and edit by short reminder id
- ASCII bell passthrough on `-p` and `-a` reminders
- Persistent storage using SQLite database
- Restart-safe: reminders survive module restarts and fire late with a
  `[delayed]` marker rather than being silently dropped
- Rate limiting to prevent abuse

## Usage

### Setting a Reminder

```none
remind <time> <text>
```

Examples:

```none
remind 1h30m walk the dog
remind 10:00 standup time
remind 30 9 * * * daily standup
```

Time formats:

- **Relative:** `1h30m`, `2d12h`, `45s` — composable day/hour/minute/second
- **Wall-clock:** `10:00`, `9:30:15`, `10:00pm`, `10:00 am` — a time that
  already passed today means tomorrow's
- **Crontab:** 5-field (`30 9 * * *`) or 6-field with seconds
  (`0 30 9 * * *`), resolved in your timezone

### Flags

`-p`, `-r`, and `-a` are orthogonal and combine freely:

```none
remind -p 1h30m ping me privately
remind -r 0 9 * * 1 weekly report
remind -p -r 30 8 * * * morning reminder, by DM
remind -a 45m stream starting soon
remind -z est 10:00 sync in New York
```

- `-p` — deliver the reminder by DM (allows ASCII bells)
- `-r` — recurring; the time spec is a crontab expression (no bells)
- `-a` — announcement: no nick highlight, bells allowed; channel admins
  only
- `-z <tz>` — timezone override for this reminder only

ASCII BEL characters in reminder text are passed through for `-p` and `-a`
reminders and stripped everywhere else; the module never adds its own bell.

### Setting Your Timezone

```none
tzset <tz>
```

Examples:

```none
tzset est
tzset America/New_York
tzset Etc/UTC
```

Accepts common US/Euro abbreviations (`est`, `pdt`, `cet`) or IANA names.
Wall-clock times and crontab schedules resolve in your timezone with full
DST support. Users without a preference use the module default (UTC).

### Listing Your Reminders

```none
list-reminders
```

Shows your reminders with their short ids, schedule, and text. DM reminders
are only included when the request is itself a DM — a channel-issued list
never leaks DM content.

Channel admins can list all announcements for a channel, set by any admin:

```none
list-reminders -a
```

### Cancelling a Reminder

```none
cancel-reminder <id>
```

Example:

```none
cancel-reminder a1b2c3d4
```

Ids are the first 8 characters shown by `list-reminders`. You can cancel
your own reminders; channel admins can additionally cancel announcements in
their channel.

### Editing a Reminder

```none
edit-reminder <id> [flags] <time> <text>
```

Example:

```none
edit-reminder a1b2c3d4 45m moved the standup
```

Fully re-specifies the reminder — time, text, and flags. The when-format may
flip a reminder between one-shot and recurring. Whenever the target is an
announcement or the edit carries `-a`, the channel-admin gate is re-run.

## Configuration

To deploy the reminders module, add it to your bot's `botModules`
configuration with `moduleName: "reminders"`:

```yaml
botModules:
- name: reminders
  spec:
    size: 1
    image: ghcr.io/eeveebot/reminders:latest
    pullPolicy: Always
    metrics: true
    metricsPort: 8080
    ipcConfig: my-eevee-bot
    moduleName: reminders
    moduleConfig: |
      ratelimit:
        mode: drop
        level: user
        limit: 5
        interval: 1m
      defaultTz: "Etc/UTC"
      maxHorizonDays: 366
      maxRemindersPerUser: 500
    persistentVolumeClaim:
      storageClassName: filesystem
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

## Requirements

This module uses `better-sqlite3` for persistent storage, which requires
native compilation during `npm install`. Ensure your build environment has
a C++ compiler and Python 3 (for `node-gyp`).
