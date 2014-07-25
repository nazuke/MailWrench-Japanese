#!/usr/local/bin/perl

=pod

	AUTHOR: nazuke.hondou@googlemail.com
	UPDATED: 20140725

	ABOUT:

		This Perl program is for sending Japanese-format email messages.
		This program should work on UNIX/Linux and Windows systems.
		For Windows, this has been known to work under Strawberry Perl.

	OPTIONS:

		-a = path to text file containing email addresses
		-m = path to file containing message body, text or HTML
		-b = Email address to BCC a copy of each email sent to
		-u = SMTP Server Username, usually your email address
		-s = path to file containing text file containing subject line
		-h = SMTP Server Hostname or IP Address
		-e = email address of sender
		-r = Return email address
		-f = CSV of paths of files to attach, accepts PDF, VCS, HTML and TXT
		-l = Path to log file
		-t = Mailshot or other unique ID
		-v = URL of view tracking service

=cut

##########################################################################################

use strict;
use warnings;
use Getopt::Std;
use Encode qw( _utf8_on is_utf8 encode decode );
use MIME::Entity;
use MIME::Base64;
use Net::SMTP;
use Net::SMTP::SSL;
use HTTP::Date;
use XML::LibXML;

##########################################################################################

our $LOGFILE = 'log.txt';

##########################################################################################

my %options = (
	'a' => '',
	'm' => '',
	'b' => '',
	'u' => '',
	's' => '',
	'h' => '',
	'e' => '',
	'r' => '',
	'd' => '',
	'f' => '',
	'l' => '',
	't' => '',
	'i' => '',
	'k' => '',
	'p' => '',
	'n' => '',
	'w' => '',
	'q' => '',
	'c' => ''
);

Getopt::Std::getopt( 'ambusherdfltikpqnwc', \%options );

my $subject       = load_file( $options{'s'} );
my $from          = load_file( $options{'e'} );
my $reply         = load_file( $options{'r'} ) || $from;
my $list          = load_file( $options{'a'} );
my $template      = load_file( $options{'m'} );
my $viewtrack_url = $options{'i'} || undef;
my $cliktrack_url = $options{'k'} || undef;
my $mailshot_id   = $options{'t'} || undef;
my $contenttype   = 'text/plain';
my %duplicates    = ();
my $sleep_count   = 0;
my $retries       = 20;

my $MAIL_DOMAIN   = '';	# Domain of the email user.
my $SMTP_HOST     = '';	# Address of SMTP Server.
my $SMTP_PORT     = '';	# Port to connect to on SMTP Server.
my $SMTP_USER     = '';	# Email address of user for SMTP Server.
my $SMTP_ENCRYPT  = '';	# true/false to use SSL.
my $SMTP_USERNAME = '';	# SMTP Username.
my $SMTP_PASSWORD = '';	# SMTP Password.
my $BCC           = '';	# Email address to BCC copies of each email sent to.

if( $options{'d'} ) {
	$MAIL_DOMAIN = $options{'d'};
} else {
	logger( qq(ERROR: No Mail Domain Supplied!) );
	exit(-1);
}

if( $options{'c'} ) {
	if( lc( $options{'c'} ) eq 'true' ) {
		$SMTP_ENCRYPT = 1;
	} else {
		$SMTP_ENCRYPT = 0;
	}
} else {
	$SMTP_ENCRYPT = 0;
}

if( $options{'l'} ) {
	$LOGFILE = $options{'l'};
}

if( $options{'h'} ) {
	$SMTP_HOST = $options{'h'};
} else {
	logger( qq(ERROR: No SMTP Hostname Supplied!) );
	exit(-1);
}

if( $options{'p'} ) {
	$SMTP_PORT = $options{'p'};
} else {
	logger( qq(ERROR: No SMTP Port Supplied!) );
	exit(-1);
}

if( $options{'u'} ) {
	$SMTP_USER = $options{'u'};
} else {
	logger( qq(ERROR: No SMTP User Email Address Supplied!) );
	exit(-1);
}

if( $options{'n'} ) {
	$SMTP_USERNAME = $options{'n'};
} else {
	if( $ENV{'MAILWRENCH_SMTP_USERNAME'} ) {
		$SMTP_USERNAME = $ENV{'MAILWRENCH_SMTP_USERNAME'};
	} else {
		logger( qq(ERROR: No SMTP Username Supplied!) );
		exit(-1);
	}
}

if( $options{'w'} ) {
	$SMTP_PASSWORD = $options{'w'};
} else {
	if( $ENV{'MAILWRENCH_SMTP_PASSWORD'} ) {
		$SMTP_PASSWORD = $ENV{'MAILWRENCH_SMTP_PASSWORD'};
	} else {
		logger( qq(ERROR: No SMTP Password Supplied!) );
		exit(-1);
	}
}

if( $options{'b'} ) {
	$BCC = $options{'b'};
}

if( $options{'q'} && ( int( $options{'q'} ) > 0 ) ) {
$retries = int( $options{'q'} );
}

##########################################################################################

logger( "Starting..." );

logger( "Preparing Subject Line..." );

chomp( $subject );

my $subject_enc = encode_field( $subject );

{
	my ( $from_name, $from_email ) = ( $from =~ m/^(.+)\s+(<[^<>]+>)/ );
	$from_name                     = encode_field( $from_name );
	$from                          = join( ' ', $from_name, $from_email );
}

{
	my ( $reply_name, $reply_email ) = ( $reply =~ m/^(.+)\s+(<[^<>]+>)/ );
	$reply_name                      = encode_field( $reply_name );
	$reply                           = join( ' ', $reply_name, $reply_email );
}

logger( "Setting Content-Type..." );

SWITCH: for( $options{'m'} ) {
	m/\.txt$/ && do {
		$contenttype = 'text/plain; charset=iso-2022-jp';
		last SWITCH;
	};
	m/\.html$/ && do {
		$contenttype = 'text/html; charset=iso-2022-jp';
		last SWITCH;
	};
	die( "oops" );
}

logger( qq(      SMTP_HOST: "$SMTP_HOST") );
logger( qq(      SMTP_PORT: "$SMTP_PORT") );
logger( qq(      SMTP_USER: "$SMTP_USER") );
logger( qq(  SMTP_USERNAME: "$SMTP_USERNAME") );
logger( qq(  SMTP_PASSWORD: "********") );
logger( qq(            BCC: "$BCC") );
logger( qq(       LISTPATH: "$options{'a'}") );
logger( qq(       PATHNAME: "$options{'m'}") );
logger( qq(           FROM: "$from") );
logger( qq(       REPLY-TO: "$reply") );
logger( qq(        SUBJECT: "$subject_enc") );
logger( qq(     ATTACHPATH: "$options{'f'}") );
logger( qq(    CONTENTTYPE: "$contenttype") );

PROCESS: foreach my $line ( split( m/\n/s, $list ) ) {

  chomp( $line );

	if( $line =~ m/^#/ ) {
		next PROCESS;
	}

	my (
		$email,
		$name,
		@fields
	) = split( m/\t/, $line );

  if( $email =~ m/^[^\@]+\@[^\@]+\.[^\@]+$/i ) {

		$email = lc( $email );
		
		if( exists( $duplicates{$email} ) ) {
    	logger( qq(Already Sent: "$email") );
			next PROCESS;		
		} else {
			$duplicates{$email} = $email;
		}

    logger( $email, 1 );

		my $message = $template;

		if( $name ) {
			$message =~ s/__NAME__/$name/gs;
		}

   	logger( qq(mailshot_id: "$mailshot_id"), 2 );

		if( $mailshot_id ) {
			if( $contenttype =~ m:^text/html: ) {
				my $tracker_image = join(
					'',
					$viewtrack_url,
					'?',
					join(
						'&amp;',
						join( '=', 'i', MIME::Base64::encode_base64url( $mailshot_id ) ),
						join( '=', 'u', MIME::Base64::encode_base64url( $email ) )
					)
				);
				$message =~ s/__TRACKER__/$tracker_image/gs;
			}
			{
				my $leadcode = MIME::Base64::encode_base64url( join( '::', $mailshot_id, $email ) );
				$message =~ s/__LEADCODE__/$leadcode/gs;
			}
		}

		if( @fields ) {
			for( my $i = 0 ; $i < @fields ; $i++ ) {
				my $search  = join( '', '__FIELD', $i, '__' );
				my $replace = $fields[$i];
				$message =~ s/$search/$replace/gs;
			}
		}

		if( $contenttype =~ m:^text/html: ) {
			my $doc = XML::LibXML->load_html( string => $message );
			if( $doc ) {
				my @nodelist = $doc->getElementsByTagName( 'a' );
				NODES: foreach my $node ( @nodelist ) {
					my $href = $node->getAttribute( 'href' );
					logger( qq(Link: "$href"), 3 );
					my $href_new = join(
						'',
						$cliktrack_url,
						'?',
						join(
							'&',
							join( '=', 'i', MIME::Base64::encode_base64url( $mailshot_id ) ),
							join( '=', 'u', MIME::Base64::encode_base64url( $email ) ),
							join( '=', 'l', MIME::Base64::encode_base64url( $href ) )
						)
					);
					$node->setAttribute( 'href', $href_new );
				}
			}
			my $html = $doc->toStringHTML();
			if( $html ) {
				Encode::_utf8_on( $html );
				$message = $html;
			}
		}

		my @attachpath = split( m/,/, $options{'f'} );

		eval {

			my $attempt = $retries;

			do {
				logger( "Attempt: $attempt $email", 2 );
				my $success = sendmail(
					smtp_host     => $SMTP_HOST,
					smtp_port     => $SMTP_PORT,
					smtp_user     => $SMTP_USER,
					smtp_encrypt  => $SMTP_ENCRYPT,
					smtp_username => $SMTP_USERNAME,
					smtp_password => $SMTP_PASSWORD,
					from          => $from,
					reply         => $reply || $from,
					recipient     => $email,
					subject       => $subject_enc,
					contenttype   => $contenttype,
					message       => Encode::encode( 'iso-2022-jp', $message ),
					attachments   => \@attachpath
				);
				if( $success ) {
					$attempt = 0;
				}
				$attempt--;
			} while( $attempt > 0 );

		};
		if( $@ ) {
			logger( $@ );
		}

	}

	$sleep_count++;

	if( $sleep_count >= 10 ) {
		$sleep_count = 0;
		sleep(1);
	}

}

logger( "Done." );

exit(0);

##########################################################################################

sub load_file {
	my $pathname = shift;
	my $data     = '';
	if( open( FILE, "<:encoding(utf-8)", $pathname ) ) {
		while( my $line = <FILE> ) {
			$data .= $line;
		}
		close( FILE );
		return( $data );
	}
	return( undef );
}

##########################################################################################

sub sendmail {
	my %args          = @_;
	my $smtp_domain   = $args{'smtp_domain'};
	my $smtp_host     = $args{'smtp_host'};
	my $smtp_port     = $args{'smtp_port'};
	my $smtp_user     = $args{'smtp_user'};

	my $smtp_encrypt  = $args{'smtp_encrypt'} || 0;
	my $smtp_username = $args{'smtp_username'} || undef;
	my $smtp_password = $args{'smtp_password'} || undef;

	my $from          = $args{'from'};
	my $reply         = $args{'reply'} || $from;
	my $recipient     = $args{'recipient'};
	my $subject       = $args{'subject'};
	my $contenttype   = $args{'contenttype'};
	my $message       = $args{'message'};
	my $attachments   = $args{'attachments'};
	my $success       = undef;

	my $smtp          = undef;

	if( $smtp_encrypt ) {
		$smtp = Net::SMTP::SSL->new(
			$smtp_host,
			Port  => $smtp_port,
			Hello => $smtp_domain,
			Debug => 0
		);
		if( defined( $smtp ) ) {
			if( $smtp_username && $smtp_password ) {
				logger( qq(Authenticating), 3 );
				$smtp->auth( $smtp_username, $smtp_password );
			} else {
				logger( qq(Skipping Authentication), 3 );
			}
		}
	} else {
		$smtp = Net::SMTP->new(
			$smtp_host,
			Hello => $smtp_domain,
			Debug => 0
		);
	}

	if( defined( $smtp ) ) {

		if( $smtp->mail( $from ) ) {

			if( $smtp->to( $recipient ) ) {
				if( $BCC ) {
					$smtp->bcc( $BCC );
				}
				$smtp->data();
				my $data = build_multipart(
					from        => $from,
					reply       => $reply,
					to          => $recipient,
					subject     => $subject,
					contenttype => $contenttype,
					message     => $message,
					attachments => $attachments
				);
				$smtp->datasend( $data );
				$smtp->dataend();
				$success = 1;
				logger( qq(SENT MAIL: "$recipient"), 2 );
			} else {
				logger( qq(ERROR: sendmail 1: "$recipient"), 2 );
			}
		} else {
			logger( qq(ERROR: sendmail 2: "$recipient"), 2 );
		}
		$smtp->quit();
	} else {
		logger( qq(ERROR: Failed to connect to SMTP Server: "$smtp_host" "$recipient"), 2 );
	}
	return( $success );
}

##########################################################################################

sub build_multipart {
	my %args        = @_;
	my $from        = $args{'from'};
	my $reply       = $args{'reply'} || $from;
	my $to          = $args{'to'};
	my $subject     = $args{'subject'};
	my $contenttype = $args{'contenttype'};
	my $message     = $args{'message'};
	my $attachments = $args{'attachments'};
	my $date        = HTTP::Date::time2str( time() );
	$date           =~ s/GMT/+0000/;
	my $mime        = MIME::Entity->build(
		'Type'     => "multipart/mixed",
		'From'     => $from,
		'Reply-To' => $reply,
		'To'       => $to,
		'Subject'  => $subject,
		'Date'     => $date,
		'Data'     => [ $message ]
	);
	foreach my $filename ( @{$attachments} ) {
		if( -e $filename ) {
			my $ct = 'text/plain';
			if( $filename =~ m/\.vcs$/i ) {
				$ct = 'text/x-vCalendar; charset=us-ascii';
			} elsif( $filename =~ m/\.pdf$/i ) {
				$ct = 'application/pdf';
			} elsif( $filename =~ m/\.txt$/i ) {
				$ct = 'text/plain; charset=iso-2022-jp';
			} elsif( $filename =~ m/\.html$/i ) {
				$ct = 'text/html; charset=iso-2022-jp';
			}
			$mime->attach(
				Path     => $filename,
				Type     => $ct,
				Encoding => 'base64'
			);
		}
	}
	$mime->attach(
		Data     => $message,
		Type     => $contenttype,
		Encoding => '7bit'
	);
	return( $mime->stringify() );
}

##########################################################################################

sub encode_field {
	my $string  = shift;
	my $encoded = join(
		'?',
		'=',
		'iso-2022-jp',
		'B',
		encode_base64( encode( 'iso-2022-jp', $string ), '' ),
		'='
	);
	return( $encoded );
}

##########################################################################################

sub logger {
	my $message = shift;
	my $depth   = shift || 0;
	open( LOGFILE, ">>" . $LOGFILE );
	print( "  " x $depth . $message . "\n" );
	print( LOGFILE "  " x $depth . $message . "\n" );
	close( LOGFILE );
	return(1);
}

##########################################################################################
