#!/usr/bin/env perl
# NetBSD.sk bot
# $Id: robik.pl 34 2007-06-03 11:02:03Z lkundrak $

use warnings;
use strict;
use config;
use Memor;

use Net::IRC;
use POSIX;
use MongoDB;
use MongoDB::OID;
use Data::Dumper;

my $me = $config::nicks[0];
my $prefix = $config::prefix;
my $buddy = $config::buddies[0];
my $degug = $config::degug;

open(my $LOG, ">>".$ARGV[0]) && printf("Logfile is: ".$ARGV[0]."\n") unless $degug;

my $irc = new Net::IRC;
my $conn = $irc->newconn (
	'Nick'		=> $me,
	'Server'	=> $config::server,
	'Ircname'	=> $config::ircname,
);
my $memo = Memor->spawn();

$conn->add_handler('public', \&msg);
$conn->add_handler('msg', \&msg);
$conn->add_handler('join', \&on_join);
$conn->add_default_handler(\&logit);
# nicknameinuse endofmotd motd topic

$conn->add_handler('endofmotd', \&on_connect);
$conn->add_handler('disconnect', \&on_disconnect);
$conn->add_handler(433, \&on_nick_taken);

# Reconnect to the server when we die.
sub on_disconnect {
	my ($conn, $event) = @_;
	logit($conn, $event, "Disconnected from ", $event->from(), " (",($event->args())[0], "). Attempting to reconnect...\n");
	sleep 10;
	$conn->connect();
}

# What to do when the bot successfully connects.
sub on_connect {
	print "Connected\n";
	$conn->join ($_) foreach (@config::channels);

	if (%config::login and $me eq  $config::nicks[0]) {
		$conn->privmsg($config::login{nickserv}, "IDENTIFY $config::login{password}");
	}
}

# Change our nick if someone stole it.
sub on_nick_taken {
	my ($self) = shift;
	$self->nick( $config::nicks[0].int(rand(99)) );
}


sub usermode
{
	my ($chan, $nick, $ident) = @_;

	foreach my $op_match (@config::ops) {
		if ($ident =~ $op_match) {
			$conn->mode ($chan, '+o', $nick);
		}		
	}
}

sub on_join {
	my ($conn, $event) = @_;
	my $chan = ($event->to)[0];
	my $nick = $event->nick;
	my $ident = $event->userhost;

	usermode ($chan, $nick, $ident);
}

sub cmd {
	my ($from, $ident, $to, $_) = @_;

	unless ($to eq $me) {
		print "$_\n";
		if (/^(\+\+)\s+(\w{1,64})\s+(.{1,256})$/) {
			$memo->set($2, $3, "$from!$ident", $to);
			return "";
		}
		elsif (/^(\?\?|wtf)\s+(\w{1,64})$/) {
			my $qt = $memo->get($2, "$to");
			return "$qt->{value}" if $qt and $qt ne "";
			return "Ani srnky netusia co $2 je.";
		}
		elsif (/^(--)\s+(\w{1,64})$/) {
			$memo->del($2);
			return "";
		}
		elsif (/^s(?:earch)?\s+(\w{1,64})/) {
			my $qt = $memo->search($1, $to);
			return "$qt\n" if $qt and $qt ne "";
			return "Vyschla studna.";
		}
		elsif (/^i(?:nfo)?\s+(\w{1,64})/) {
			my $qt = $memo->get($1, "$to");
			return "$qt->{key}: $qt->{author}, ".localtime($qt->{date})."\n" if $qt and $qt ne "";
			return "Neznam.";
		}
	}

#	/^say\s+(\S+)\s*(.*)$/ and return $conn->privmsg ($1, $2);
	/^(time|date)/ and return localtime(time);

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

sub msg {
	logit(@_);

	my ($conn, $event) = @_;
	my ($message) = $event->args;
	my ($to) = $event->to;
	my $from = $event->nick;
	my $ident = $event->userhost;
	my $response = '';

	if ($degug) {
		print "MSG $from -> $to: $message\n";
	}

	$_ = $message;

	if (($to ne $me) and (/^$me(?::\s*)?(.*)/ || /^$prefix(.*)/ || /^((?:--|\?\?|\+\+|wtf)\s+.*)/)) {
		$response = cmd($from, $ident, $to, $1);
	}

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
