---
weight: 220
title: "The Lifecycle of a Message"
description: "An explanation of message flow in eevee.bot"
draft: false
toc: true
---

## A Message Is Born

First, a user sends a message to the chat. This could be through any supported messaging platform, such as IRC, Discord, or Slack:

```none
# Example on IRC
<goos> | !weather 12345
```

This represents the origin of all interactions with eevee.bot, where user input initiates the processing pipeline.

## Your Voice Is Heard

The message is heard by the appropriate module, which is responsible for handling the incoming messages from specific platforms (e.g., `irc-connector@thegooscloud`). This module formats the message into a standardized JSON payload and forwards it to the NATS message broker:

Connector modules act as the bridge between external chat platforms and the eevee.bot ecosystem, translating platform-specific message formats into a consistent internal representation.

```json
{
  "producer": "ircClient",
  "subject": "chat.message.incoming.irc.thegooscloud.eevee.#general.goos@honk.com",
  "moduleUUID": "a3e978d9-33af-4d5c-b750-8b3c82e9ee17",
  "type": "chat.message.incoming",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed",
  "platform": "irc",
  "instance": "eevee",
  "network": "thegooscloud",
  "channel": "#general",
  "user": "goos",
  "userHost": "honk.com",
  "text": "!weather 12345",
  "botNick": "eevee",
  "commonPrefixRegex": "^[!~]",
  "rawEvent": {}
}
```

The message is published to a subject with the format: `chat.message.incoming.$platform.$network.$instance.$channel.$user`

## We Seek to Understand

The `router` module consumes the incoming message from NATS. The router performs several tasks:

1. **Command Matching:** The router attempts to match the message text against any registered command regular expressions.
2. **Broadcast Matching:** The router also checks if the message matches any registered broadcast listeners.
3. **Rate Limiting:** It checks the message against any rate limiting rules.
4. **Blocklist Filtering:** It checks if the message matches any configured blocklist patterns.
5. **Emitting Command Messages:** For each matching command, the router emits a structured message back into NATS with additional metadata.
6. **Emitting Broadcast Messages:** For each matching broadcast, the router emits a message to the broadcast channel.

The router serves as the central intelligence of eevee.bot, determining how each message should be processed and where it should be routed. This centralized approach ensures consistent handling of all messages while maintaining the modularity of individual components.

### Command Execution Message

For matched commands, the router publishes to the subject `command.execute.$commandUUID`:

```json
{
  "platform": "irc",
  "network": "thegooscloud",
  "instance": "eevee",
  "channel": "#general",
  "user": "goos",
  "userHost": "honk.com",
  "text": "12345",
  "originalText": "!weather 12345",
  "matchedCommand": "!weather",
  "timestamp": "2023-01-01T00:00:00.000Z"
}
```

### Broadcast Message

For matched broadcasts, the router publishes to the subject `broadcast.message.$broadcastUUID`:

```json
{
  "platform": "irc",
  "network": "thegooscloud",
  "instance": "eevee",
  "channel": "#general",
  "user": "goos",
  "userHost": "honk.com",
  "text": "!weather 12345",
  "timestamp": "2023-01-01T00:00:00.000Z"
}
```

## We Want to Help

The parsed command message is now delivered to the target module, which is identified by the `commandUUID`. This module performs the necessary action to fulfill the command, such as querying an external weather API. If the command requires a response, the module will construct and send a response message back to NATS.

Response messages are published to subjects that vary by module implementation, but typically follow patterns like `chat.message.outgoing.$platform.$network.$instance.$channel` for chat responses.

This step represents the core functionality of eevee.bot modules, where the actual work is performed in response to user requests. Each module is responsible for a specific domain of functionality, allowing for focused development and maintenance.

## Hear Our Voice

The connector module consumes outgoing messages from NATS and sends them to the appropriate platform. For example, the `irc-connector` module would receive a message like:

This final step completes the round-trip of communication, delivering the module's response back to the user through the original chat platform.

```json
{
  "channel": "#general",
  "network": "thegooscloud",
  "instance": "eevee",
  "platform": "irc",
  "text": "goos: the weather for 12345 is sunny and 72°F",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed"
}
```

And send it to the IRC channel:

```none
# Example on IRC
<eevee> | goos: the weather for 12345 is sunny and 72°F
```

## Notes

A module may register `.*` with no `prefix` specified to listen to all messages in a channel. This is useful for modules that need to react to specific content regardless of whether it starts with a command prefix. Notable examples include:

- **`tell`**: This module listens to all messages to identify any commands for delayed delivery.
- **`urltitle`**: This module listens to all messages to fetch and display titles of URLs posted in channels.

Additionally, modules can register for broadcast messages to receive copies of all messages that match their broadcast registration criteria, enabling features like logging or analytics.

These flexible registration options allow eevee.bot modules to implement a wide variety of functionality, from simple command responders to sophisticated monitoring and analysis tools.
