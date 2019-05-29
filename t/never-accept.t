#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;
use HTTP::Request;
use HTTP::Async;
use Net::EmptyPort ();
use Time::HiRes qw(gettimeofday);

my $port = Net::EmptyPort::empty_port();
die "missing port" if ! $port;

my $IPC_SOCKET = new IO::Socket::INET(Listen    => 5, LocalAddr => '127.0.0.1', LocalPort => $port, Proto   => "tcp" );

my ($start,$end);
my $q = HTTP::Async->new( timeout => 2 );
$start = gettimeofday();
ok $q->add(HTTP::Request->new(GET => "http://127.0.0.1:$port/this_will_hang")), "added request";
$end = gettimeofday();
ok( $end-$start < .5, "did not block on connect: " . ($end-$start) );
my $resp = $q->wait_for_next_response(4);
$end = gettimeofday();
ok( $resp->status_line eq '504 Gateway Timeout', "got gateway timeout" );

# grab and close client socket
{ my $client = $IPC_SOCKET->accept;
$client->close; }

$start = gettimeofday();
ok $q->add(HTTP::Request->new(GET => "https://127.0.0.1:$port/this_will_hang")), "added request (ssl)";
$end = gettimeofday();
ok( $end-$start < .5, "did not block on connect (ssl): " . ($end-$start) );
$resp = $q->wait_for_next_response(4);
$end = gettimeofday();
ok( $resp->status_line eq '504 Gateway Timeout', "got gateway timeout (ssl)" );

{ my $client = $IPC_SOCKET->accept;
$client->close; }

$IPC_SOCKET->close;
