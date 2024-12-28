# The lifecycle of a message

First, a user sends a message to the chat:

```none
// irc.thegoos.cloud#general
<goos> !weather 12345
```

The message is heard by the module `irc-connector@thegooscloud`, which forwards the message to kafka as such:

```json
// topic: chat.message.incoming.$platform.$instance.$channel.$user
{
  "type": "message.incoming",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed",
  "platform": "irc",
  "network": "thegooscloud",
  "instance": "eevee",
  "channel": "#general",
  "user": "goos",
  "text": "!weather 12345",
  "raw_event": {}, // TODO: fill this in with an example
}
```

This message is then consumed by the `router` module, which first checks it for a common prefix.
It then attempts to parse it against any number of registered regexes.
Then, it checks for any registered filtering or ratelimiting rules, and applies them as necessary
Finally, it emits the parsed message back into kafka as such:

```json
// topic: command.request.$command
{
  "argv": [ "!weather", "12345" ],
  "channel": "#general",
  "command": "weather",
  "commandUUID": "d462389d-a4f5-4d38-b738-3fa2ae89c2ad",
  "network": "thegooscloud",
  "instance": "eevee",
  "platform": "irc",
  "prefix": "!",
  "raw": {},
  "regexCaptured": ["12345"],
  "targetModule": "weather",
  "text": "!weather 12345",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed",
  "type": "command.request",
  "user": "goos@foo.bar.baz",
}
```

The message is consumed by command modules, in this case the `weather` module.
The module does any necessary logic with the message.
If a reply is required, it emits a message to kafka:

```json
// topic: command.response
{
  "channel": "#general",
  "fromModule": "weather",
  "network": "thegooscloud",
  "instance": "eevee",
  "platform": "irc",
  "text": "goos: the weather for 12345 is foo bar baz",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed",
  "type": "command.response",
}
```

This message is consumed by the `router` module, which applies any ratelimiting or filtering rules.
It then emits a message into kafka:

```json
// topic: chat.message.outgoing.$platform.$network.$channel
{
  "channel": "#general",
  "network": "thegooscloud",
  "instance": "eevee",
  "platform": "irc",
  "text": "goos: the weather for 12345 is foo bar baz",
  "trace": "c4f8f2e5-0fbe-4511-a398-cb43393c2eed",
  "type": "message.outgoing",
}
```

This is consumed by the proper connector, in this case `irc-connector@thegooscloud`, which sends the message to the requested destination:

```none
// irc.thegoos.cloud#general
<goos> !weather 12345
<eevee> goos: the weather for 12345 is foo bar baz
```

## Notes

A module may register `.*` with no `prefix` specified as a "command" in order to hear all messages sent in a channel.

`tell` does this in order to know when/where to deliver a message
