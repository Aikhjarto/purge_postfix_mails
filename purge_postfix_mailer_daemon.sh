#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 Thomas Wagner
# delete bounced mails once mail loop occured
# postfix might kept running, but it will be much faster if postfix was stopped
# requires postfix >= 3.1 (postqueue -j) and jq
MYORIGIN=$(postconf -xh myorigin)

# null sender (bounces) or any recipient postmaster@myorigin
postqueue -j | jq -r --arg postmaster "postmaster@${MYORIGIN}" '
    select(.sender == "" or .sender == "MAILER-DAEMON"
           or any(.recipients[]; .address == $postmaster))
    | .queue_id' | postsuper -d -

for FOLDER in /var/spool/postfix/incoming /var/spool/postfix/active ; do
    (
        cd "${FOLDER}" || exit
        grep -l -R "postmaster@${MYORIGIN}" | postsuper -d -
        grep -l -R "MAILER-DAEMON@${MYORIGIN}" | postsuper -d -
    )
done
