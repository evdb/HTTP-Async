use strict;
use warnings;

use Test::More tests => 4;
use HTTP::Request;
use HTTP::Async;

require 't/TestServer.pm';

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

my $q = HTTP::Async->new;

{
    my $url = "$url_root/?not_modified=1";

    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    my $res = $q->wait_for_next_response;

    #    use Data::Dumper;
    #    warn Dumper $res;

    is $res->code, 304, "304 Not modified";
    ok !$res->previous, "does not have a previous reponse";
}

1;
