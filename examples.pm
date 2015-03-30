#!/usr/bin/perl

$| = 1;

use strict;
use warnings;

use Erik;
use CGI;

my $cgi = CGI->new();
$cgi->param('cgi', $cgi);
my $x = 'XX';

Erik::sanity();
Erik::sanity('This is a sanity line');
my_sub();

Erik::dump(cgi => $cgi);
Erik::dump(cgi => $cgi, 1);
Erik::dump(cgi => $cgi, max_depth => 2);


Erik::disable;
Erik::sanity("This should not be printed");
Erik::enable;
Erik::sanity("You should see this now");


Erik::info("This is what info looks like");

Erik::vars(cgi => $cgi);
Erik::vars(cgi => $cgi, x => $x);

Erik::min($_) for 1..10;
Erik::sanity("1 though 10 should be on the previous line");


Erik::moduleLocation();
Erik::moduleLocation('Erik');

Erik::printFile('test.pm');

Erik::singleOff();
Erik::sanity("This should not be printed");
Erik::sanity("You should see this line!!!!");

Erik::spacer(5);
Erik::sanity("There should be 5 empty lines above me");

stackTrace();

Erik::toggle;
stackTrace();
Erik::sanity("You should NOT be seeing this or the second stack trace");
Erik::toggle;
Erik::sanity("Toggled around and around - btw you should see this");

sub my_sub {
    Erik::subroutine;
}

sub stackTrace {
    _stackTrace();
}
sub _stackTrace {
    Erik::stackTrace;
}
