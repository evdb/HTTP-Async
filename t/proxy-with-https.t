use strict;
use warnings;
use URI::Escape;

use Test::More;
use HTTP::Request;

require 't/TestServer.pm';

eval "require LWP::Protocol::https";
if ($@) {
    plan skip_all => "LWP::Protocol::https required";
    exit 0;
}

plan tests => 5;

my $s1          = TestServer->new(10249);
$s1->{is_proxy} = 1;
my $s1_url_root = $s1->started_ok("starting a test server");

ok( $s1_url_root, "got $s1_url_root" );

my %tests = (
    "https://www.google.co.uk/images/srpr/logo4w.png" => 200,
);

use HTTP::Async;
my $q = HTTP::Async->new;

while ( my ( $url, $code ) = each %tests ) {

    my $req = HTTP::Request->new( 'GET', $url );

    my %opts = ( proxy_host => '127.0.0.1', proxy_port => 10249, );

    my $id = $q->add_with_opts( $req, \%opts );

    ok $id, "Added request to the queue - $url";

    my $res = $q->wait_for_next_response;
    is( $res->code, $code, "Got a '$code' response" )
        || warn $res->as_string;

    # check that the proxy header was found if this was a proxy request.
    my $proxy_header = $res->header('WasProxied') || '';
    is $proxy_header, 'yes', "check for proxy header 'yes'";
}
