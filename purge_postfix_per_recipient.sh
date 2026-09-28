#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 Thomas Wagner
# delete all queued mails that have at least one of the given recipients
# the whole mail is deleted, i.e. also for its other recipients
# requires postfix >= 3.1 (postqueue -j) and jq
if [ $# -eq 0 ]; then
    echo "usage: $0 recipient [recipient ...]" >&2
    exit 1
fi

# addresses are compared case-insensitively
postqueue -j | jq -r '
    ($ARGS.positional | map(ascii_downcase)) as $purge
    | select(any(.recipients[]; .address | ascii_downcase | IN($purge[])))
    | .queue_id' --args "$@" | postsuper -d -
