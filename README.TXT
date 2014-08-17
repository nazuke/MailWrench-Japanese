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

	--from
	
		Path to text file containing email address of sender.

	--reply
	
		Path to text file containing email address for reply-to.

	--list
	
		Path to text file containing email addresses.

	--message
	
		Path to file containing message body, in plain text or HTML format.

	--subject
	
		Path to text file containing subject line.

	--attachment [may be repeated]

		Path to file to attach; accepts PDF, VCS, HTML, TXT, JPG, GIF and PNG.

	--logfile
	
		Path to log file.

	--mail-domain [optional]
	
		Some SMTP servers require your domain to be passed, consult your system administrator if this is required. This is often simply the domain part of your email address.

	--smtp-host
	
		SMTP server hostname or IP address.

	--smtp-port [optional]
	
		SMTP server port number, consult your system administrator for this.

	--encrypt [optional]

		If enabled, then an encrypted SMTP connection will be attempted. Will possibly also require --smtp-username and --smtp-password parameters to be passed.

	--smtp-username [optional]

		SMTP server username, if encryption is enabled.

	--smtp-password [optional]

		SMTP server password, if encryption is enabled.

	--bcc [optional]
	
		Email address to BCC a copy of each email sent to.

	--retries
	
		Requires an integer. Number of transmission tries before giving up.

	--view-track
	
		URL of view tracking service, see below for more information.

	--click-track
	
		URL of click tracking service, see below for more information.

	--mailshot-id
	
		A meaningful string value that will be incorporated into links in the HTML format version of the message body.
	
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

MAILSHOT-ID AND THE LEADCODE

For marketing purposes, it is often useful to employ a lead code to match email reponses to a particular marketing campaign.

Use the --mailshot-id parameter to do this. In the HTML format version of your message, you may then add the placeholder __LEADCODE__ to embedded URLs. The mailshot program will then concatenate and Base64-encode the mailshot-id, :: (two colons), and the recipient's email address. Your server software will be responsible for logging and decoding these values. 

-----------------------------------------------------------------------------

VIEW TRACK URL FORMAT

If your message body is in HTML format, then it is possible to use a view-tracking image tag that calls back to your own web server.

In your HTML message file, add an image tag like this:

	<img src="__TRACKER__" />

The mailshot program will process the __TRACKER__ placeholder string with the base URL specified in the --view-track command line parameter, and will append two URI parameters for your web server:

	i = Base64-encoded copy of the mailshot-id string.

	u = Base64-encoded copy of the recipient's email address.

-----------------------------------------------------------------------------

CLICK TRACK URL FORMAT

If your message body is in HTML format, then it is possible to have all anchors in the message converted into click-tracking links that call back to your own web server.

This is enabled by using the --click-track command line parameter, and will append three URI parameters for your web server:

	i = Base64-encoded copy of the mailshot-id string.

	u = Base64-encoded copy of the recipient's email address.

	l = Base64-encoded copy of the HREF value of the anchor clicked.

-----------------------------------------------------------------------------

ENQUIRIES

If you have any questions about the MailWrench-Japanese program, please contact me at nazuke.hondou@googlemail.com.

I cannot provide support for this program, however I would be like to hear any feedback or other comments regarding bugs or improvements.

I hope you find this software useful.

-----------------------------------------------------------------------------

LICENSE

The MailWrench-Japanese Perl application is licensed under the same terms as Perl.

-----------------------------------------------------------------------------
