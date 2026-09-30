#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 Thomas Wagner
# delete all queued mails from one of the given senders
# an empty sender ('') selects the bounces, which have the null sender
# requires postfix >= 3.1 (postqueue -j) and jq
if [ $# -eq 0 ]; then
    echo "usage: $0 sender [sender ...]" >&2
    exit 1
fi

# addresses are compared case-insensitively
postqueue -j | jq -r '
    ($ARGS.positional | map(ascii_downcase)) as $purge
    | select((.sender // "") | ascii_downcase | IN($purge[]))
    | .queue_id' --args "$@" | postsuper -d -
