#!/bin/sh

perl MailWrench-Japanese.pl \
-a "batch/test-addresses.ja.txt" \
-b "some-other-email-address@domain.com" \
-c true \
-d "mail.domain.com" \
-e "batch/from.ja.txt" \
-h "smtp.domain.com" \
-i "https://your-domain.com/path/to/view/track/service" \
-k "https://your-domain.com/path/to/click/track/service" \
-l "batch/log.txt" \
-m "batch/message.ja.txt" \
-n "smtp-username" \
-p 465 \
-q 10 \
-r "batch/from.ja.txt" \
-s "batch/subject.ja.txt" \
-t "development-mode" \
-u "your-email-address@domain.com" \
-w "smtp-password"
