#!/usr/bin/env perl

=pod

	AUTHOR: nazuke.hondou@googlemail.com
	UPDATED: 20140817

	ABOUT:

		This Perl program is for sending Japanese-format email messages.
		This program should work on UNIX/Linux and Windows systems.
		For Windows, this has been known to work under Strawberry Perl.

		See the accompanying README.TXT file for more information.

=cut

##########################################################################################

package MailWrench;

use strict;
use warnings;
use Carp qw( cluck );
use Getopt::Long;
use Encode qw( _utf8_on is_utf8 encode decode );
use MIME::Entity;
use MIME::Base64;
use Net::SMTP;
use Net::SMTP::SSL;
use HTTP::Date;
use XML::LibXML;

##########################################################################################


my $wrench = MailWrench->new();
$wrench->run();
exit(0);


##########################################################################################


sub new {
	my $package = shift;
	my $self    = {};
	bless( $self, $package );

	$self->{'logfile'}     = 'log.txt';
	$self->{'duplicates'}  = {};
	$self->{'sleep_count'} = 0;

	$self->{'SMTP'} = {
		'MAIL_DOMAIN'   => '', # Domain of the email user.
		'SMTP_HOST'     => '', # Address of SMTP Server.
		'SMTP_PORT'     => '', # Port to connect to on SMTP Server.
		'SMTP_USER'     => '', # Email address of user for SMTP Server.
		'SMTP_ENCRYPT'  => 0,  # true/false to use SSL.
		'SMTP_USERNAME' => '', # SMTP Username.
		'SMTP_PASSWORD' => '', # SMTP Password.
		'RETRIES'       => ''
	};

	$self->{'OPTIONS'} = {
		'subject_'      => undef,
		'subject'       => undef,
		'from_'         => undef,
		'from'          => undef,
		'reply_'        => undef,
		'reply'         => undef,
		'bcc'           => undef,
		'list_'         => undef,
		'list'          => undef,
		'template_'     => undef,
		'template'      => undef,
		'content-type'  => 'text/plain',
		'viewtrack_url' => undef,
		'cliktrack_url' => undef,
		'mailshot_id'   => undef,
		'attachments'   => []
	};

	GetOptions(

		'logfile=s'       => \$self->{'logfile'},

		'mail-domain=s'   => \$self->{'SMTP'}->{'MAIL_DOMAIN'},
		'smtp-host=s'     => \$self->{'SMTP'}->{'SMTP_HOST'},
		'smtp-port=i'     => \$self->{'SMTP'}->{'SMTP_PORT'},
		'encrypt'         => \$self->{'SMTP'}->{'SMTP_ENCRYPT'},
		'smtp-username:s' => \$self->{'SMTP'}->{'SMTP_USERNAME'},
		'smtp-password:s' => \$self->{'SMTP'}->{'SMTP_PASSWORD'},
		'retries:i'       => \$self->{'SMTP'}->{'RETRIES'},

		'subject=s'       => \$self->{'OPTIONS'}->{'subject_'},
		'from=s'          => \$self->{'OPTIONS'}->{'from_'},
		'reply:s'         => \$self->{'OPTIONS'}->{'reply_'},
		'bcc:s'           => \$self->{'OPTIONS'}->{'bcc'},
		'list=s'          => \$self->{'OPTIONS'}->{'list_'},
		'message=s'       => \$self->{'OPTIONS'}->{'template_'},
		'view-track:s'    => \$self->{'OPTIONS'}->{'viewtrack_url'},
		'click-track:s'   => \$self->{'OPTIONS'}->{'cliktrack_url'},
		'mailshot-id:s'   => \$self->{'OPTIONS'}->{'mailshot_id'},
		'attachment:s'    => $self->{'OPTIONS'}->{'attachments'}

	);

	$self->logger( qq(SUBJECT: "$self->{'OPTIONS'}->{'subject_'}") );

	unless( $self->{'SMTP'}->{'MAIL_DOMAIN'} ) {
		die( qq(ERROR: No Mail Domain Supplied!) );
	}

	unless( $self->{'SMTP'}->{'SMTP_HOST'} ) {
		die( qq(ERROR: No SMTP Hostname Supplied!) );
	}

	unless( $self->{'SMTP'}->{'SMTP_PORT'} ) {
		die( qq(ERROR: No SMTP Port Supplied!) );
	}

	if( $self->{'SMTP'}->{'SMTP_ENCRYPT'} ) {
		unless( $self->{'SMTP'}->{'SMTP_USERNAME'} ) {
			die( qq(ERROR: No SMTP Encryption Username Supplied!) );
		}
		unless( $self->{'SMTP'}->{'SMTP_PASSWORD'} ) {
			die( qq(ERROR: No SMTP Encryption Password Supplied!) );
		}
	}

	{	# Prepare Subject Header
		$self->logger( "Preparing Subject Line..." );
		my $subject = $self->load_file( $self->{'OPTIONS'}->{'subject_'} );
		chomp( $subject );
		$self->{'OPTIONS'}->{'subject'} = $self->encode_field( $subject );
	}

	{	# Prepare FROM/REPLY Headers
		$self->logger( "Preparing FROM Header..." );
		{
			my $from_                      = $self->load_file( $self->{'OPTIONS'}->{'from_'} );
			my ( $from_name, $from_email ) = ( $from_ =~ m/^(.+)\s+(<[^<>]+>)/ );
			$from_name                     = $self->encode_field( $from_name );
			$self->{'OPTIONS'}->{'from'}   = join( ' ', $from_name, $from_email );
		}
		$self->logger( "Preparing REPLY Header..." );
		{
			my $reply_                       = $self->load_file( $self->{'OPTIONS'}->{'reply_'} );
			my ( $reply_name, $reply_email ) = ( $reply_=~ m/^(.+)\s+(<[^<>]+>)/ );
			$reply_name                      = $self->encode_field( $reply_name );
			$self->{'OPTIONS'}->{'reply'}    = join( ' ', $reply_name, $reply_email );
		}
	}

	{	# Prepare Content-Type Header
		$self->logger( "Setting Content-Type Header..." );
		SWITCH: for( lc( $self->{'OPTIONS'}->{'template_'} ) ) {
			m/\.txt$/ && do {
				$self->{'OPTIONS'}->{'content-type'} = 'text/plain; charset=iso-2022-jp';
				last SWITCH;
			};
			m/\.html$/ && do {
				$self->{'OPTIONS'}->{'content-type'} = 'text/html; charset=iso-2022-jp';
				last SWITCH;
			};
			die( "ERROR: Message Content-Type could not be determined!" );
		}
	}

	{	# Loading Message Template into RAM
		$self->logger( "Loading Message Template into RAM..." );
		$self->{'OPTIONS'}->{'template'} = $self->load_file( $self->{'OPTIONS'}->{'template_'} );
	}

	{	# Loading List into RAM
		$self->logger( "Loading Mailing List into RAM..." );
		$self->{'OPTIONS'}->{'list'} = $self->load_file( $self->{'OPTIONS'}->{'list_'} );
	}

	return( $self );
}

##########################################################################################

sub run {
	my $self = shift;
	$self->logger( "Starting..." );

	$self->logger( qq(      SMTP_HOST: "$self->{'SMTP'}->{'SMTP_HOST'}") );
	$self->logger( qq(      SMTP_PORT: "$self->{'SMTP'}->{'SMTP_PORT'}") );
	$self->logger( qq(  SMTP_USERNAME: "$self->{'SMTP'}->{'SMTP_USERNAME'}") );
	$self->logger( qq(  SMTP_PASSWORD: "********") );
	$self->logger( qq(           FROM: "$self->{'OPTIONS'}->{'from'}") );
	$self->logger( qq(       REPLY-TO: "$self->{'OPTIONS'}->{'reply'}") );
	$self->logger( qq(            BCC: "$self->{'OPTIONS'}->{'bcc'}") );
	$self->logger( qq(        SUBJECT: "$self->{'OPTIONS'}->{'subject_'}") );
	$self->logger( qq(   CONTENT-TYPE: "$self->{'OPTIONS'}->{'content-type'}") );
	$self->logger( qq(   MESSAGE PATH: "$self->{'OPTIONS'}->{'template_'}") );
	$self->logger( qq(       LISTPATH: "$self->{'OPTIONS'}->{'list_'}") );

	foreach my $attached ( @{$self->{'OPTIONS'}->{'attachments'}} ) {
		$self->logger( qq(     ATTACHMENT: "$attached") );
	}

	eval {
		$self->process_list();
	};
	if( $@ ) {
		$self->logger( $@, 1 );
	}

	$self->logger( "Done." );
	
	return(1);
}

##########################################################################################

sub process_list {
	my $self = shift;
	my $list = $self->{'OPTIONS'}->{'list'};

	$self->logger( "Processing List...", 1 );

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
		
			if( exists( $self->{'duplicates'}->{$email} ) ) {
				$self->logger( qq(Already Sent: "$email"), 2 );
				next PROCESS;		
			} else {
				$self->{'duplicates'}->{$email} = $email;
			}

			$self->logger( $email, 2 );

			my $message = $self->{'OPTIONS'}->{'template'};

			if( $name ) {
				$message =~ s/__NAME__/$name/gs;
			}

			$self->logger( qq(mailshot_id: "$self->{'OPTIONS'}->{'mailshot_id'}"), 3 );

			if( $self->{'OPTIONS'}->{'mailshot_id'} ) {
				if( $self->{'OPTIONS'}->{'content-type'} =~ m:^text/html: ) {
					my $tracker_image = join(
						'',
						$self->{'OPTIONS'}->{'viewtrack_url'},
						'?',
						join(
							'&amp;',
							join( '=', 'i', MIME::Base64::encode_base64url( $self->{'OPTIONS'}->{'mailshot_id'} ) ),
							join( '=', 'u', MIME::Base64::encode_base64url( $email ) )
						)
					);
					$message =~ s/__TRACKER__/$tracker_image/gs;
				}
				{
					my $leadcode = MIME::Base64::encode_base64url( join( '::', $self->{'OPTIONS'}->{'mailshot_id'}, $email ) );
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

			if( $self->{'OPTIONS'}->{'content-type'} =~ m:^text/html: ) {
				my $doc = XML::LibXML->load_html( string => $message );
				if( $doc ) {
					my @nodelist = $doc->getElementsByTagName( 'a' );
					NODES: foreach my $node ( @nodelist ) {
						my $href = $node->getAttribute( 'href' );
						$self->logger( qq(Link: "$href"), 4 );
						my $href_new = join(
							'',
							$self->{'OPTIONS'}->{'cliktrack_url'},
							'?',
							join(
								'&',
								join( '=', 'i', MIME::Base64::encode_base64url( $self->{'OPTIONS'}->{'mailshot_id'} ) ),
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

			eval {

				my $attempt = $self->{'SMTP'}->{'RETRIES'};

				do {
					$self->logger( "Attempt: $attempt $email", 3 );
					my $success = undef;
					eval {
						$success = $self->sendmail(
							recipient => $email,
							message   => Encode::encode( 'iso-2022-jp', $message )
						);
					};
					if( $@ ) {
						die( $@ );
					}
					if( $success ) {
						$attempt = 0;
					}
					$attempt--;
				} while( $attempt > 0 );

			};
			if( $@ ) {
				die( $@ );
			}

		}

		$self->{'sleep_count'}++;

		if( $self->{'sleep_count'} >= 10 ) {
			$self->{'sleep_count'} = 0;
			sleep(1);
		}

	}

	return(1);
}

##########################################################################################

sub sendmail {
	my $self          = shift;
	my %args          = @_;
	my $recipient     = $args{'recipient'};
	my $message       = $args{'message'};
	my $smtp_encrypt  = $self->{'SMTP'}->{'SMTP_ENCRYPT'} || 0;
	my $smtp_username = $self->{'SMTP'}->{'SMTP_USERNAME'} || undef;
	my $smtp_password = $self->{'SMTP'}->{'SMTP_PASSWORD'} || undef;
	my $success       = undef;
	my $smtp          = undef;

	if( $smtp_encrypt ) {
		$smtp = Net::SMTP::SSL->new(
			$self->{'SMTP'}->{'SMTP_HOST'},
			Port  => $self->{'SMTP'}->{'SMTP_PORT'},
			Hello => $self->{'SMTP'}->{'MAIL_DOMAIN'},
			Debug => 0
		);
		if( defined( $smtp ) ) {
			if( $smtp_username && $smtp_password ) {
				$self->logger( qq(Authenticating...), 3 );
				$smtp->auth( $smtp_username, $smtp_password );
			} else {
				$self->logger( qq(Skipping Authentication), 3 );
			}
		}
	} else {
		$smtp = Net::SMTP->new(
			$self->{'SMTP'}->{'SMTP_HOST'},
			Hello => $self->{'SMTP'}->{'MAIL_DOMAIN'},
			Debug => 0
		);
	}

	if( defined( $smtp ) ) {

		if( $smtp->mail( $self->{'OPTIONS'}->{'from'} ) ) {

			if( $smtp->to( $recipient ) ) {
				if( $self->{'OPTIONS'}->{'bcc'} ) {
					$smtp->bcc( $self->{'OPTIONS'}->{'bcc'} );
				}
				$smtp->data();
				my $data = undef;
				eval {
					$data = $self->build_multipart(
						to      => $recipient,
						message => $message
					);
				};
				if( $@ ) {
					$smtp->quit();
					die( $@ );
				}
				$smtp->datasend( $data );
				$smtp->dataend();
				$success = 1;
				$self->logger( qq(SENT MAIL: "$recipient"), 2 );
			} else {
				$self->logger( qq(ERROR: sendmail 1: "$recipient"), 2 );
			}
		} else {
			$self->logger( qq(ERROR: sendmail 2: "$recipient"), 2 );
		}
		$smtp->quit();
	} else {
		$self->logger( qq(ERROR: Failed to connect to SMTP Server: "$self->{'SMTP'}->{'SMTP_HOST'}" "$recipient"), 2 );
	}
	return( $success );
}

##########################################################################################

sub build_multipart {
	my $self    = shift;
	my %args    = @_;
	my $to      = $args{'to'};
	my $message = $args{'message'};
	my $date    = HTTP::Date::time2str( time() );
	$date       =~ s/GMT/+0000/;
	my $mime    = MIME::Entity->build(
		'Type'     => "multipart/mixed",
		'From'     => $self->{'OPTIONS'}->{'from'},
		'To'       => $to,
		'Reply-To' => $self->{'OPTIONS'}->{'reply'} || $self->{'OPTIONS'}->{'from'},
		'Subject'  => $self->{'OPTIONS'}->{'subject'},
		'Date'     => $date,
		'Data'     => [ $message ]
	);
	foreach my $filename ( @{$self->{'OPTIONS'}->{'attachments'}} ) {
		if( -e $filename ) {
			my $ct = 'binary/octet-stream';

			SWITCH: for( $filename ) {
				m/\.vcs$/i && do {
					$ct = 'text/x-vCalendar; charset=us-ascii';
					last SWITCH;
				};
				m/\.gif$/i && do {
					$ct = 'image/gif';
					last SWITCH;
				};
				m/\.jpg$/i && do {
					$ct = 'image/jpeg';
					last SWITCH;
				};
				m/\.png$/i && do {
					$ct = 'image/png';
					last SWITCH;
				};
				m/\.pdf$/i && do {
					$ct = 'application/pdf';
					last SWITCH;
				};
				m/\.txt$/i && do {
					$ct = 'text/plain; charset=iso-2022-jp';
					last SWITCH;
				};
				m/\.html$/i && do {
					$ct = 'text/html; charset=iso-2022-jp';
					last SWITCH;
				};
				m// && do {
					last SWITCH;
				};
			}
			$mime->attach(
				Path     => $filename,
				Type     => $ct,
				Encoding => 'base64'
			);
		} else {
			die( qq(ERROR: Attachment file not found: "$filename") );
		}
	}
	$mime->attach(
		Data     => $message,
		Type     => $self->{'OPTIONS'}->{'content-type'},
		Encoding => '7bit'
	);
	return( $mime->stringify() );
}

##########################################################################################

sub encode_field {
	my $self    = shift;
	my $string  = shift;
	my $encoded = join(
		'?',
		'=',
		'iso-2022-jp',
		'B',
		MIME::Base64::encode_base64( encode( 'iso-2022-jp', $string ), '' ),
		'='
	);
	return( $encoded );
}

##########################################################################################

sub load_file {
	my $self     = shift;
	my $pathname = shift;
	unless( $pathname ) {
		cluck();
	}
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

sub logger {
	my $self    = shift;
	my $message = shift;
	my $depth   = shift || 0;
	open( LOGFILE, ">>" . $self->{'logfile'} );
	print( "  " x $depth . $message . "\n" );
	print( LOGFILE "  " x $depth . $message . "\n" );
	close( LOGFILE );
	return(1);
}

##########################################################################################
