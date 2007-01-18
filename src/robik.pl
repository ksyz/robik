#!/usr/bin/env perl
# NetBSD.sk bot
# $Id$

use warnings;
use strict;
use config;

use Net::IRC;
use POSIX;
use Weather::Underground;

my $Ubiq = $config::Ubiqs[0];
my $Revi = $config::Revis[0];
my $me = $config::nicks[0];

my $irc = new Net::IRC;
my $conn = $irc->newconn (
	'Nick'		=> $me,
	'Server'	=> 'irc.nextra.sk',
	'Ircname'	=> 'Robert Fico',
);

$conn->add_handler('public', \&msg);
$conn->add_handler('msg', \&msg);
$conn->add_default_handler(\&logit);
# nicknameinuse endofmotd motd 

$conn->join ($_) foreach (@config::channels);

sub weather
{
	my $argument = shift;
	my $retval;

	unless ($argument) {
		return "Skus takto: weather <miesto>";
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
			$place->{'moonrise'},
			$place->{'moonset'},
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
	`PATH=/usr/games:/bin:/usr/bin:/usr/sbin wtf '$argument' 2>&1`;
}

sub command
{
	$_ = shift;

	/^wtf\s+(.*)/ and return wtf ($1);
	/^version/ and return '$Revision$';
	/^weather\s+(.*)/ and return weather ($1);
	/^weather/ and return
		weather ('Brno, Czech Republic').
		weather ('Bratislava, Slovakia');
#	/^join\s+(\S+)$/ and return $conn->join ($1);
#	/^part\s+(\S+)\s*(\S*)$/ and return $conn->part ("$1 $2");
#	/^quit\s+(\S*)$/ and return $conn->quit ("$1 $2");
	/^say\s+(\S+)\s*(.*)$/ and return $conn->privmsg ($1, $2);

	'Hlupemu dietatu ani vlastna matka nerozumie.';
}

sub answer
{
	my ($to, $from, $text) = @_;
	my @text = split /\n/,$text;

	foreach (@text) {
		if ($to eq $me) {	# query
	 		$conn->privmsg ($from, $_);
		} else {		# channel
		 	$conn->privmsg ($to, "$from: $_");
		}
	}
}

sub msg
{
	my ($conn, $event) = @_;
	my ($message) = $event->args;
	my ($to) = $event->to;
	my $from = $event->nick;
	my $response = '';

	$_ = $message;

	if ($to eq $me) {
		$response = command ($_);
	} else {
		/^$me(:\s*)?(.*)/ and $response = command ($2);
	}

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

	answer ($to, $from, $response);
}

sub logit
{
	my ($conn, $event) = @_;

	my $date = `date '+%D %T'`;
	chomp $date;
	
	open (LOG, '>>/tmp/robik.log');
	print LOG $date.' '.$event->type.":\t";
	foreach ($event->args) {
		print LOG "\t$_";
	}
	print LOG "\n";
	close (LOG);
}

sub daemonize {
	chdir ('/');
	open (STDIN, '/dev/null');
	open (STDOUT, '>>/dev/null');
	open (STDERR, '>>/dev/null');

    	fork () and exit (0);
	POSIX::setsid ();
}

daemonize ();
$irc->start ();
