!!WARNING!! THIS IS STILL IN ALPHA AS OF 2014/07/23

-----------------------------------------------------------------------------

This is the README for MailWrench-Japanese.

Last Modified: 2014-07-23

See http://japanese-mailshots.blogspot.jp/ for more info.

-----------------------------------------------------------------------------

ABOUT MAILWRENCH-JAPANESE

This program is a very simple application for sending emails to a list of one or more recipients, such as for a marketing mailshot campaign. It was written to address the issue of sending quickly emails to Japanese users, including those using mobile phones to read their mail. It addresses the basic technical challenges of ensuring that the mail can be read by the recipient, chiefly ensuring that the various MIME headers and body are correctly encoded for Japanese readers.

The application operates on a fire-and-forget basis, no attempt is made to track failures or bounced messages, it simply attempts to send the email to each recipient. To address intermittent network faults, it does try to send a mail several times before giving up.

Depending on the configuration of your email infrastructure, failures may be returned to the user specified in the FROM configuration file. Your mileage may vary.

The mailshot recipient list may contain a simple list of email addresses, or may contain a limited number of fields which may be merged into the message text before sending. If additional fields are required to be merged, modifying the source of the script is a very simple process.

-----------------------------------------------------------------------------

MAILSHOT BEST PRACTICES

IT IS STRONGLY RECOMMENDED that you always test your mailshot, by using the "test-addresses.ja.txt" file with one or more test recipients, before running a live mailshot to external recipients.

Always remember that when you send an email, it cannot be recalled, so test and test and test to make sure that what is sent to the recipient is what you intend them to see.

Japanese text can be problematic at the best of times, so always check that the received text does not contain any malformed characters, or "mojibake". All of the input files MUST be saved using UTF-8 text encoding, with no byte-order marker. If necessary, use a text editor, or other conversion program, to convert the input files from ShiftJIS to UTF-8.

-----------------------------------------------------------------------------

MAILSHOT "BATCH"

The application generally runs in a batch mode, sending one email to each of the recipients in the recipient list in turn.

There is an example "batch" folder included, with example files for each piece of data that is required by the batch.

In addition, there is a sample BAT file, for MS Windows, and a sample Bash Shell file for Linux and UNIX-like systems.

You may put the Perl script anywhere that you would normally place Perl programs, as long as Perl itself can find it.

Currently, the application only supports the sending of HTML or "plain" text email message bodies. For Japanese recipients, I would recommend using plain unformatted text; HTML is not guaranteed to be readable by all mail readers, such as mobile devices.

If there is demand, I may add support for multipart message bodies, allowing for both HTML and plain text in the same message.

-----------------------------------------------------------------------------

MAILWRENCH-JAPANESE PROGRAM OPTIONS

The script may be used as-is, or it may be called from some other process.

The currently supported options are:

	-e = path to text file containing email address of sender
	-r = path to text file containing email address for reply-to
	-a = path to text file containing email addresses
	-m = path to file containing message body, text or HTML
	-s = path to file containing text file containing subject line
	-f = CSV of paths of files to attach, accepts PDF, VCS, HTML and TXT
	-l = Path to log file
	-h = SMTP Server Hostname or IP Address
	-u = SMTP Server Username, usually your email address
	-b = Email address to BCC a copy of each email sent to
	-q = Number of transmission tries before giving up
	-i = URL of view tracking service, see below for more information
	-k = URL of click tracking service, see below for more information

-----------------------------------------------------------------------------

WINDOWS USAGE

On Microsoft Windows, I recommend using Strawberry Perl.

1. Edit the "MailWrench-Japanese.bat" file.
2. Edit the files in "batch".
3. Open a command window on the directory containing the "MailWrench-Japanese.bat" file.
4. Run the "MailWrench-Japanese.bat" file.

-----------------------------------------------------------------------------

Linux, UNIX and Mac OS X USAGE:

1. Edit the "MailWrench-Japanese.sh" file.
2. Edit the files in "batch".
3. From a command prompt go to the directory containing the "MailWrench-Japanese.sh" file.
4. Run the "MailWrench-Japanese.sh" file.

-----------------------------------------------------------------------------

ENQUIRIES

If you have any questions about the MailWrench-Japanese program, please contact me at nazuke.hondou@googlemail.com.

I cannot provide support for this program, however I would be like to hear any feedback or other comments regarding bugs or improvements.

I hope you find this software useful.

-----------------------------------------------------------------------------

LICENSE

The MailWrench-Japanese Perl application is licensed under the same terms as Perl.

-----------------------------------------------------------------------------
