
use strict;
use warnings;

use Test::More skip_all => 'just a template to base other tests on';

use Test::More tests => 5;

use HTTP::Async;
my $q = HTTP::Async->new;

require 't/TestServer.pm';

# my $s = TestServer->new;
# my $url_root = $s->started_ok("starting a test server");

my @servers = map { TestServer->new($_) } 80800 .. 80804;
foreach my $s (@servers) {
    my $url_root = $s->started_ok("starting a test server");
}
