# purge_postfix_mails

Scripts to break a mail loop in Postfix by deleting queued mails that cannot be
delivered.

## The problem

A machine mails its admin whenever an error is logged. When the relayhost is
unreachable, each failed delivery is itself logged as an error. That error
triggers another mail, which also fails, and so on. The queue fills up with
alert mails, bounces and notices to `postmaster`.

These scripts remove those mails from the queue so the loop stops.

## Scripts

| Script | Deletes |
| --- | --- |
| `purge_postfix_mailer_daemon.sh` | Bounces (null sender / `MAILER-DAEMON`), mails to `postmaster@<myorigin>`, and mails in `incoming`/`active` that mention `postmaster@<myorigin>` or `MAILER-DAEMON@<myorigin>` |
| `purge_postfix_mails.sh` | Everything above, plus deferred mails whose delay reason shows the relayhost refused them (e.g. `421 Too many connections`, `454 4.7.0 Error: too many new TLS sessions`) |
| `purge_postfix_per_recipient.sh ADDR...` | Mails that have at least one of the given addresses as a recipient (compared case-insensitively). The whole mail is deleted, including for its other recipients. |

The first two scripts take the domain from Postfix's `myorigin` setting
(`postconf -xh myorigin`),
so the same scripts work on every machine without editing.

To match more relayhost errors, add patterns to `DEFER_REASONS` in
`purge_postfix_mails.sh`. They are jq regular expressions, so escape literal dots
as `\.`.

## Requirements

- Postfix 3.1 or newer (for `postqueue -j`)
- [jq](https://jqlang.org/)
- root privileges (`postsuper -d` and reading `/var/spool/postfix`)

## Usage

```sh
sudo systemctl stop postfix      # optional, but purging is much faster
sudo ./purge_postfix_mails.sh
sudo systemctl start postfix

sudo ./purge_postfix_per_recipient.sh root@example.org admin@example.org
```

The scripts also work while Postfix is running. Postfix may then move some
queue files while the script runs; `postsuper` reports those as warnings and
skips them.

**The deleted mails are gone for good.** Check `postqueue -p` first if the
queue might contain mail you want to keep.

## Preventing the loop

Purging only fixes the symptom. To stop the loop from starting:

- Keep Postfix's own delivery errors (`postfix/smtp`, `postfix/qmgr`,
  `postfix/bounce`) out of the log filter that triggers the alert mails.
- Rate-limit the alert action, e.g. `action.execOnlyOnceEveryInterval` for
  rsyslog's `ommail`.
- In `main.cf`, reduce follow-up mail:
  - `delay_warning_time = 0`: no "mail delayed" notices
  - `bounce_queue_lifetime = 1h`: give up on undeliverable bounces sooner
  - keep `notify_classes` minimal
  - point `2bounce_notice_recipient` at a local mailbox

## License

Copyright (C) 2026 Thomas Wagner

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version. See [LICENSE](LICENSE) for the full text.
