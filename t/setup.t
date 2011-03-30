
use strict;
use warnings;

use Test::More tests => 16;

use HTTP::Async;
use HTTP::Async::Polite;

foreach my $class ( 'HTTP::Async', 'HTTP::Async::Polite' ) {
    foreach my $number ( 0, 3 ) {

        my $q1 = $class->new;
        is $q1->max_redirects($number), $number, "set to $number";
        is $q1->max_redirects, $number, "got $number";

        my $q2 = $class->new( max_redirects => $number );
        ok $q2, "created object";
        is $q2->max_redirects, $number, "got $number";
    }
}
