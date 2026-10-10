# bash completion for purge_postfix_mails.sh, purge_postfix_mailer_daemon.sh,
# purge_postfix_per_recipient.sh and purge_postfix_per_sender.sh -*- shell-script -*-

# The scripts take no options. purge_postfix_mails.sh and
# purge_postfix_mailer_daemon.sh take no arguments, the others mail addresses.
# Reading them from the queue would be slow during a mail loop, so complete
# nothing instead of file names.
_purge_postfix_mails()
{
    COMPREPLY=()
}
complete -F _purge_postfix_mails purge_postfix_mails.sh purge_postfix_mailer_daemon.sh \
    purge_postfix_per_recipient.sh purge_postfix_per_sender.sh
