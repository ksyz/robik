# NetBSD.sk bot configuration
# $Id: config.pm 35 2007-07-11 13:19:12Z lkundrak $

use strict;

$config::degug = 1;
$config::server = 'irc.freenode.net';
$config::ircname = 'Robert Fico';
$config::prefix = '\.';
@config::nicks = ('c0ck');
@config::buddies = (
	'.*@norkia.v3.sk',
	'.*@91.210.183.14',
	'.*@127.0.0.1',
);
%config::login = (
	nickserv => "nickserv",
	password => "c0ck"
);

if ($config::degug = 1) {
	@config::channels = ('#testbed');
} else {
	@config::channels = ('#testbed', '#fedora-cs', '#progressbar');
}

@config::ops = (
	'.*@norkia.v3.sk',
	'.*@91.210.183.14',
);

1;
