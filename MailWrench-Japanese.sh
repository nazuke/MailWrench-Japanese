#!/bin/sh

perl MailWrench-Japanese.pl \
 -a "batch/test-addresses.ja.txt" \
 -m "batch/message.ja.txt" \
 -b "some-other-email-address@domain.com" \
 -u "your-email-address@domain.com" \
 -s "batch/subject.ja.txt" \
 -h "smtp.domain.com" \
 -e "batch/from.ja.txt" \
 -r "batch/from.ja.txt" \
 -d "mail.domain.com" \
 -l "batch/log.txt" \
 -t "development-mode" \
 -i "https://your-domain.com/path/to/view/track/service" \
 -k "https://your-domain.com/path/to/click/track/service" \
 -q 10 \
 -p 465 \
 -n "smtp-username" \
 -w "smtp-password" \
 -c true
