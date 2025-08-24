---
weight: 220
title: "The Lifecycle of a Message"
description: "An explanation of message flow"
draft: false
toc: true
---

## A Message Is Born

First, a user sends a message to the chat. This could be through any supported messaging platform, such as IRC, Discord, or Slack:

```none
# Example on IRC
<goos> | !weather 12345
```

## Your Voice Is Heard

The message is heard by the appropriate module, which is responsible for handling the incoming messages from specific platforms (e.g., `irc-connector@thegooscloud`). This module formats the message into a standardized JSON payload and forwards it to the NATS message broker:

```yaml
# Topic format: chat.message.incoming.$platform.$instance.$channel.$user
# Example topic: chat.message.incoming.irc.eevee.#general.goos
{
  "type": "message.incoming",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed", # Unique trace ID for the message
  "platform": "irc", # Platform the message came from
  "network": "thegooscloud", # Network identifier within the platform
  "instance": "eevee", # Instance identifier within the network
  "channel": "#general", # Channel where the message was posted
  "user": "goos", # User who sent the message
  "text": "!weather 12345", # Raw text of the message
  "raw_event": {}, # Placeholder for raw event data from the platform
}
```

## We Seek to Understand

The `router` module consumes the incoming message from NATS. The router performs several tasks:

1. **Common Prefix Check:** It verifies if the message starts with a recognized prefix (e.g., `!`).
2. **Regex Parsing:** The router attempts to match the message text against any registered regular expressions.
3. **Filtering and Ratelimiting:** It checks the message against any filtering or ratelimiting rules.
4. **Emitting a Parsed Message:** After processing, the router emits a structured message back into NATS with additional metadata:

```yaml
# Topic format: command.request.$command
# Example topic: command.request.weather
{
  "argv": [ "!weather", "12345" ], # Argument vector with command and parameters
  "channel": "#general", # Channel where the message originated
  "command": "weather", # Command extracted from the message
  "commandUUID": "d462389d-a4f5-4d38-b738-3fa2ae89c2ad", # Unique UUID for the command request
  "network": "thegooscloud", # Network identifier within the platform
  "instance": "eevee", # Instance identifier within the network
  "platform": "irc", # Platform where the message was received
  "prefix": "!", # Command prefix used
  "raw": {}, # Raw input data for reference
  "regexCaptured": ["12345"], # Any captured groups from regex matching
  "targetModule": "weather", # Target module for processing the command
  "text": "!weather 12345", # Original message text
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed", # Trace ID inherited from the original message
  "type": "command.request", # Type of message being processed
  "user": "goos@foo.bar.baz", # Full user identifier including network information
  "ratelimited": true, # Was this message held due to ratelimiting rules
}
```

## We Want to Help

The parsed `command.request` message is now delivered to the target module, which in this case is the `weather` module. This module performs the necessary action to fulfill the command, such as querying an external weather API. If the command requires a response, the module will construct and send a `command.response` message back to NATS:

```yaml
# Topic: command.response
{
  "channel": "#general", # Channel where the response should be sent
  "fromModule": "weather", # Module that processed the command
  "network": "thegooscloud", # Network identifier within the platform
  "instance": "eevee", # Instance identifier within the network
  "platform": "irc", # Platform where the response should be sent
  "text": "goos: the weather for 12345 is foo bar baz", # Response text to be sent to the user
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed", # Trace ID inherited from the original message
  "type": "command.response", # Type of message being sent
}
```

## Hear Our Voice

The `router` module consumes the `command.response` message from NATS. Similar to its role in understanding incoming messages, the router may apply additional filtering or ratelimiting rules to the response. Once processed, it emits a `chat.message.outgoing` message, which is picked up by the appropriate connector module:

```yaml
# Topic format: chat.message.outgoing.$platform.$network.$channel
# Example topic: chat.message.outgoing.irc.thegooscloud.#general
{
  "channel": "#general", # Channel where the message should be posted
  "network": "thegooscloud", # Network identifier within the platform
  "instance": "eevee", # Instance identifier within the network
  "platform": "irc", # Platform where the message should be sent
  "text": "goos: the weather for 12345 is foo bar baz", # Text of the message to be sent
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed", # Trace ID inherited from the original message
  "type": "message.outgoing", # Type of message being sent
}
```

This outgoing message is then consumed by the `irc-connector@thegooscloud` module, which is responsible for sending the message to the intended destination on the IRC network:

```none
# Example on IRC
<eevee> | goos: the weather for 12345 is foo bar baz
```

## Notes

A module may register `.*` with no `prefix` specified to listen to all messages in a channel. This is useful for modules that need to react to specific content regardless of whether it starts with a command prefix. Notable examples include:

- **`tell`**: This module listens to all messages to identify any commands for delayed delivery.
- **`urltitle`**: This module listens to all messages to fetch and display titles of URLs posted in channels.
