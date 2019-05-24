# FreshDesk Maintenance

![Pipeline status](https://gitlab.com/opencontent/freshdesk-utils/badges/master/pipeline.svg)

This script closes tickets in state Resolved after 30 days without changes

In our freshdesk the field status is required for a ticket to be closed, so
this script checks for the existence of this field.

A notification to Slack is sent everytime the maintenance happens and list
the tickets altered by the script. Notification messages are in Italian,
sorry, I still can't image a simple way to internationalize the script :)

## Setup

    export FRESHDESK_DOMAIN=yourdomain
    export FRESHDESK_API_KEY=*********
    export SLACK_WEBHOOK=https://hooks.slack.com/...
    export SLACK_CHANNEL=you_preferred_channel

    ./close_older_resolved_tickets.sh

## Requirements

 * bash
 * httpie
 * jq

## Run with docker

    docker run -it --rm -e FRESHDESK_DOMAIN=yourdomain -e FRESHDESK_API_KEY=********* registry.gitlab.com/opencontent/freshdesk

We use a task in AWS Fargate to execute periodically the script, but you can use whatever option you prefer.

## Other configuration options

* Set environment variable TRACE=1 to enable debug mode of bash scripts



