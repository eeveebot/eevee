# The command registry

Modules register commands that they want to hear messages for as such:

```json
// topic: command.register

// Assumption: network prefix of "^!(.*)"

// This command matches stuff like:
// !weather 12345
// From all connections, in all rooms, on all networks, on all platforms
{
  "type": "command.register",
  "commandUUID": "d462389d-a4f5-4d38-b738-3fa2ae89c2ad",
  "platform": "^.*$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "regex": "^weather (0-9a-z)",
  "platformPrefixAllowed": true,
  "ratelimit": {
    "mode": "enqueue",
    "level": "channel",
    "limit": "10",
    "interval": "30s"
  },
},

// This command matches stuff like:
// !tell alice fizzbuzz
// In all rooms on all irc networks
{
  "type": "command.register",
  "commandUUID": "46b21d7a-9c8e-4109-8163-c53946eec809",
  "platform": "^irc$",
  "network": "^.*$",
  "instance": "^.*$",
  "channel": "^.*$",
  "user": "^.*$",
  "regex": "^tell (.*) (.*)$",
  "platformPrefixAllowed": true,
  "ratelimit": {
    "mode": "drop",
    "level": "user",
    "limit": "10",
    "interval": "10s"
  },
},

// This command matches stuff like:
// ~admin fizzbuzz
// In room #eevee-admin
// On platform irc
// On network thegooscloud
// From user goos@foo.bar.baz
// As heard by connection instance "eevee"
{
  "type": "command.register",
  "commandUUID": "cf3135fd-2459-45f5-809c-b27683885d9f",
  "platform": "^irc$",
  "network": "^thegooscloud$",
  "instance": "^eevee$",
  "channel": "^eevee-admin$",
  "user": "^goos@foo.bar.baz$",
  "regex": "^~admin .*$",
  "platformPrefixAllowed": false,
  "ratelimit": false,
},

// This "command" matches everything said
// in a certain room on a certain network
{
  "type": "command.register",
  "commandUUID": "cf3135fd-2459-45f5-809c-b27683885d9f",
  "platform": "^irc$",
  "network": "^thegooscloud$",
  "instance": "^eevee$",
  "channel": "^general$",
  "user": "^.*$",
  "regex": "^.*$",
  "platformPrefixAllowed": false,
  "ratelimit": false,
}
```

The registry component of the router stores these registrations in redis.
At runtime, it does lookups.
