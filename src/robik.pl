#!/usr/bin/env perl
# NetBSD.sk bot
# $Id: robik.pl 34 2007-06-03 11:02:03Z lkundrak $

use warnings;
use strict;
use config;

use Net::IRC;
use POSIX;
#use Weather::Underground;
		
open(my $LOG, ">>".$ARGV[0]) && printf("Logfile is: ".$ARGV[0]."\n");

my $Ubiq = $config::Ubiqs[0];
my $Revi = $config::Revis[0];
my $me = $config::nicks[0];
my $prefix = $config::prefix;
my $buddy = $config::buddies[0];
my $degug = $config::degug;

my $irc = new Net::IRC;
my $conn = $irc->newconn (
	'Nick'		=> $me,
	'Server'	=> $config::server,
	'Ircname'	=> $config::ircname,
);

my $pyxel_old = undef;
my $pyxel_new = undef;
my $pyxel_break = 'pyxel broke it';
my $pyxel_chan = undef;

$conn->add_handler('public', \&msg);
$conn->add_handler('msg', \&msg);
$conn->add_handler('join', \&onjoin);
$conn->add_default_handler(\&logit);
# nicknameinuse endofmotd motd topic

$conn->join ($_) foreach (@config::channels);

sub usermode
{
	my ($chan, $nick, $ident) = @_;

	foreach my $op_match (@config::ops) {
		if ($ident =~ $op_match) {
			$conn->mode ($chan, '+o', $nick);
		}		
	}
}

sub onjoin
{
	my ($conn, $event) = @_;
	my $chan = ($event->to)[0];
	my $nick = $event->nick;
	my $ident = $event->userhost;

	usermode ($chan, $nick, $ident);
}

sub pocasie
{
	my $argument = shift;
	my $retval;

	unless ($argument) {
		return "Skus takto: pocasie <miesto>";
	}
    
	my $weather = Weather::Underground->new (
		'place'	=> $argument,
		'debug'	=> 0,
	);

	my $places = $weather->get_weather ()
		or return 'Nemozem scucnut info pre toto miesto';

	foreach my $place (@{$places}) {
		$retval .= sprintf (

			" * %s: %s \xb0C, %s, Vietor %s Km/h (%s)\n".
			"   Slnko: %s - %s (Velke okruhle)\n".
			"   Mesiac: %s - %s (%s)\n".
			"   Viditelnost: %s Km. [%s]\n",

			$place->{'place'},
			$place->{'temperature_celsius'},
			$place->{'conditions'},
			$place->{'wind_kilometersperhour'},
			$place->{'wind_direction'},

			$place->{'sunrise'},
			$place->{'sunset'},
			$place->{'moonset'},
			$place->{'moonrise'},
			$place->{'moonphase'},

			$place->{'visibility_kilometers'},
			$place->{'updated'},

			#$place->{''},
		);
	}
	return $retval;
}

sub wtf
{
	my $argument = shift;
	$argument =~ s/\'//g;
	`PATH=/usr/games:/bin:/usr/bin:/usr/sbin wtf '$argument' 2>&1 |head -n1`;
}

sub break
{
	$pyxel_new = shift;
	$conn->privmsg ($Revi, "wtf $pyxel_break");
}

sub command
{
	$_ = shift;

#	/^wtf\s+(.*)/ and return wtf ($1);
#	/^version/ and return '$Revision: 34 $';
#	/^pocasie\s+(.*)/ and return pocasie ($1);
#	/^break\s+(.*)/ and return break ($1);
#	/^pocasie/ and return
#		pocasie ('Brno, Czech Republic').
#		pocasie ('Bratislava, Slovakia');
#	/^join\s+(\S+)$/ and return $conn->join ($1);
#	/^part\s+(\S+)\s*(\S*)$/ and return $conn->part ("$1 $2");
#	/^quit\s+(\S*)$/ and return $conn->quit ("$1 $2");
	/^say\s+(\S+)\s*(.*)$/ and return $conn->privmsg ($1, $2);

	/(time|date)/ and return localtime(time);

	my @odzdrav = ('ahoj', 'cau', 'Dobry den prajem!', "Ja pierdole!", 
		"Hello World!", "Nazdar", "Skap!", "Dzien dobry", 
		"Dzień dobry", "ciao", "cześć", "czesc");

	foreach my $pozdrav (@odzdrav) {
		/$pozdrav/i and return $odzdrav[rand(@odzdrav)];
	}

#	'Bad command or filename.';
}

sub answer
{
	my ($where, $whom, $text) = @_;
	my @text = split /\n/,$text;

	foreach (@text) {
		if ($where eq $me) {	# query
	 		$conn->privmsg ($whom, $_);
		} else {		# channel
		 	$conn->privmsg ($where, "$whom: $_");
		}
	}
}

sub msg
{
	logit(@_);
	my ($conn, $event) = @_;
	my ($message) = $event->args;
	my ($to) = $event->to;
	my $from = $event->nick;
	my $response = '';

	if ($degug) {
		print "MSG $from -> $to: $message\n";
	}

	$_ = $message;

	if ($to eq $me) {
		$response = command ($_);
	} else {
		if (/^$me(?::\s*)?(.*)/ || /^$prefix(.*)/) {
			$response = command ($1);
		}
	}

=pod
	if (/(.*), ani srnky netusia co \'([^\']+)\'/) {
		my ($caller, $arg) = ($1, $2);
		my $wtf = wtf ($arg);

		$response = ''; # not a command

		if ($wtf =~ /^wtf,/) {
			answer ($to, $caller, "Skutocne nevedia.");
		} else {
 			$conn->privmsg ($Revi, "wtf $arg = $wtf");
			answer ($to, $caller, "Skus teraz, teraz uz mozno vedia.");
		}
	}

	if (/\ (\!|\?)$/) {
		unless ($to eq $me) {
 			answer ($to, $from, "Pis slusne!");
			$conn->kick ($to, $from, "medzera pred '!' a '?' nepatri!");
		}
	}

	if (/(youtube|video.google.com|swf)/i) {
		unless ($to eq $me) {
 			answer ($to, $from, "Skus si to s flashom rozmysliet");
			#$conn->kick ($to, $from, 'flash');
		}
	}


	if ($pyxel_new and not $pyxel_chan) {
		$pyxel_chan = $to;
	}
	if (/\* pyxel broke it = (.*)  \[added by/) {
		$pyxel_old = $1;
		if ($pyxel_new) {
			$pyxel_old .= " | $pyxel_new";
			$conn->privmsg ($Revi, "wtf $pyxel_break = $pyxel_old");
			$conn->privmsg ($pyxel_chan, "wtf $pyxel_break");
			$pyxel_new = $pyxel_chan = undef;
		}
	}
=cut
	answer ($to, $from, $response);
}

sub logit
{
	my ($conn, $event) = @_;

	my $date = `date '+%D %T'`; chomp $date;
	my $logline = "$date ".$event->type.":\t";
	
	foreach ($event->args) {
		$logline .= "\t$_";
	}
	$logline .= "\n";

	if ($degug) {
		print $logline;
	} else {
		print $LOG $logline;
#		close (LOG);
	}
}

sub daemonize {
	chdir ('/');
	open (STDIN, '/dev/null');
	open (STDOUT, '>>/dev/null');
	open (STDERR, '>>/dev/null');

    	fork () and exit (0);
	POSIX::setsid ();
}

daemonize () unless $degug;
$irc->start ();
