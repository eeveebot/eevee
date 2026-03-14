---
weight: 200
title: "Specification"
description: "Message schema and communication protocols for eevee.bot"
draft: false
toc: true
---

This section describes the message schemas and communication protocols used by eevee.bot modules to interact with each other through the NATS message broker.

eevee.bot is built on a modular, message-driven architecture that enables flexible and scalable chatbot functionality. Understanding these specifications is essential for developing new modules or integrating with existing ones.

## Core Concepts

eevee.bot uses a message-driven architecture where modules communicate by publishing and subscribing to specific subjects on a NATS message broker. This decoupled approach allows modules to be developed, deployed, and scaled independently.

The key benefits of this architecture include:

- **Modularity**: Each module has a specific responsibility and can be developed in isolation
- **Scalability**: Modules can be scaled independently based on demand
- **Fault Tolerance**: If one module fails, it doesn't affect others
- **Flexibility**: New functionality can be added without modifying existing modules

## Message Flow

The typical message flow in eevee.bot follows this pattern:

1. **Incoming Messages**: Connector modules receive messages from chat platforms and publish them to NATS
2. **Routing**: The router module processes incoming messages and determines which commands or broadcasts should handle them
3. **Command Execution**: Matched commands receive execution messages with parsed parameters
4. **Broadcast Distribution**: Matched broadcasts receive copies of messages
5. **Outgoing Messages**: Modules publish responses which are sent back to users through connector modules

Each step in this flow is designed to be modular and independent, allowing for flexible processing and routing of messages throughout the system.

## Related Documentation

- [**Incoming Messages**](../specification/incoming-messages/) - How messages flow through the system
- [**Command Registry**](../specification/command-registry/) - How modules register to handle specific commands
- [**Broadcast Registry**](../specification/broadcast-registry/) - How modules can listen to all messages matching criteria
