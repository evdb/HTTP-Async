
use strict;
use warnings;

use Test::More tests => 21;
use HTTP::Request;

require 't/TestServer.pm';
my $s        = TestServer->new(80200);
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;
my $q = HTTP::Async->new;

# Check that the max_redirects is at a sensible level.
is $q->max_redirects, 7, "max_redirects == 7";

# Send a request to somewhere that will redirect a certain number of
# times:
#
# ?redirect=$num - if $num is > 0 then it redirects to $num - 1;

{    # Check that a couple of redirects work.
    my $url = "$url_root/foo/bar?redirect=3";

    # warn $url;
    # getc;

    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 200, "No longer a redirect";
    ok $res->previous, "Has a previous reponse";
    is $res->previous->code, 302, "previous request was a redirect";
}

{    # check that 20 redirects stop after the expected number.
    my $url = "$url_root?redirect=20";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 302, "Still a redirect";
    ok $res->previous, "Has a previous reponse";
    is $res->previous->code, 302, "previous request was a redirect";
    is $res->request->uri->as_string, "$url_root?redirect=13",
      "last request url correct";
}

{    # Set the max_redirect higher and try again.

    ok $q->max_redirects(30), "Set the max_redirects higher.";

    my $url = "$url_root?redirect=20";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 200, "No longer a redirect";
    ok $res->previous, "Has a previous reponse";
    is $res->previous->code, 302, "previous request was a redirect";
}

{    # Set the max_redirect to zero and check that none happen.

    is $q->max_redirects(0), 0, "Set the max_redirects to zero.";
    is $q->max_redirects, 0, "max_redirects is set to zero.";

    my $url = "$url_root?redirect=20";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 302, "No longer a redirect";
    ok !$res->previous, "Have no previous reponse";
}
