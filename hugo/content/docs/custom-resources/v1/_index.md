---
weight: 510
title: "eevee.bot/v1"
description: "Custom Resource Definitions for eevee.bot v1 API"
draft: false
---

The eevee.bot/v1 API provides Custom Resource Definitions (CRDs) for managing chatbot
components in Kubernetes.

## Available CRDs

- [botmodule](botmodule/) - Defines individual bot modules
- [ipcconfig](ipcconfig/) - Defines Inter-Process Communication configuration
- [s3store](s3store/) - Defines S3-compatible object storage connections
- [backupschedule](backupSchedule/) - Schedules recurring PVC backups to S3
- [backuprestore](backupRestore/) - Triggers oneshot PVC restores from S3
