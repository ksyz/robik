package Memor;

use strict;
use warnings;

use MongoDB;
use MongoDB::OID;
use Data::Dumper;

my $mdb;
my $db;
my $c;

sub spawn {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { @_ };

	$mdb = MongoDB::Connection->new;
	$db = $mdb->robik;
	$c = $db->quotes;	
	
	return bless $self, $class;
}

sub set {
	my $self = shift;

	my ($key, $value, $author, $channel) = @_;
	$c->update(
		{key => $key, channel => $channel},
		{'$set' => {
				value => $value,
				author => $author,
				removed => 0,
				date => time,
				channel => $channel,
			}
		},
		{ upsert => 1 }
	);
}

sub search {
	my $self = shift;

	my ($key, $channel) = @_;
	my $filter = {removed => 0};

	$filter->{channel} = $channel if $channel;
	
	return "Daj mi aspon tri znaky." if (length($key) < 3);

	$filter->{key} = qr/$key/i;

	my $res = $c->find($filter);
	my @ret = ();

	while (my $doc = $res->next) {
		push @ret, $doc->{key} if ($doc->{key} and $doc->{value});
	}

	return join(", ", @ret);
}

sub get {
	my $self = shift;

	my ($key, $channel) = @_;
	my $filter = {removed => 0, key => $key};
	$filter->{channel} = $channel if $channel;
	
	my $res = $c->find($filter);
	while (my $doc = $res->next) {
		#print "$doc->{key}: $doc->{value}\n" if ($doc->{key} and $doc->{value});
		return $doc if ($doc->{key} and $doc->{value});
	}

	return undef;
}

sub del {
	my $self = shift;

	my ($key, $channel, $force) = @_;
	$force = 0 unless $force;

	if ($force) {
		print 1;
		$c->delete({key => $key, channel => $channel});
	}
	else {
		print 2;
		$c->update({key => $key}, {'$set' => { removed => 1 } }, { multi => 1 } );
		
	}
}

1;
