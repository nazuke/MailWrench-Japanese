#!/bin/sh
perl MailWrench-Japanese.pl \
\
--logfile "batch/log.txt" \
\
--mail-domain "mail.domain.com" \
--smtp-host "smtp.domain.com" \
--smtp-port 465 \
--smtp-user "your-email-address@domain.com" \
--username "smtp-username" \
--password "smtp-password" \
--retries 10 \
--encrypt \
\
--subject "batch/subject.ja.txt" \
--from "batch/from.ja.txt" \
--reply "batch/from.ja.txt" \
--bcc "some-other-email-address@domain.com" \
--list "batch/test-addresses.ja.txt" \
--message "batch/message.ja.txt" \
--attachment="batch/attachments/torii.jpg" \
--attachment="batch/attachments/ema.jpg" \
--view-track "https://your-domain.com/path/to/view/track/service" \
--click-track "https://your-domain.com/path/to/click/track/service" \
--mailshot-id "development-mode" \
