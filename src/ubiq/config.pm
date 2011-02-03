#!/usr/bin/env perl
# NetBSD.sk bot configuration
# $Id: config.pm 35 2007-07-11 13:19:12Z lkundrak $

use strict;

@config::Ubiqs = ();
@config::Revis = ();
$config::server = 'irc.upc.cz';
$config::ircname = 'Robert Fico';
$config::prefix = "!";
@config::buddies = ('_8086', "xyzz", "lkundrak", "marek", "ksyz");

if ($config::degug = 0) {
	@config::nicks = ('degug');
	@config::channels = ('#testbed');
} else {
	@config::nicks = ('Ubiq', 'Yane', 'Revi');
	@config::channels = ('#netbsd.sk', '#fit', "#kanal");
}

# so we know our friends
@config::ops = (
	'.*@norkia.v3.sk',
	'bon@127.0.0.1',
);

1;
