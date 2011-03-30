
use strict;
use warnings;

use Test::More tests => 9;

use HTTP::Request;

use HTTP::Async;
my $q = HTTP::Async->new;

# Try to add some requests for bad hosts. HTTP::Async should not fail
# but should return HTTP::Responses with the correct status code etc.

my @bad_requests =
  map { HTTP::Request->new( GET => $_ ) }
  ( 'http://i.dont.exist/foo/bar', 'ftp://wrong.protocol.com/foo/bar' );

ok $q->add(@bad_requests), "Added bad requests";

while ( $q->not_empty ) {
    my $res = $q->next_response || next;

    isa_ok $res, 'HTTP::Response', "Got a proper response";
    ok !$res->is_success, "Response was not a success";
    ok $res->is_error, "Response was an error";
    ok $res->request,  "response has a request attached.";
}
