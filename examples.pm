#!/usr/bin/perl

$| = 1;

use strict;
use warnings;

use Erik;
use CGI;

my $tmp_file = '/tmp/Erik.txt';
if (!-e $tmp_file) {
    open(my $fh, '>', $tmp_file)
        || die("Unable to open file ($tmp_file) for write: $!\n");
    print $fh "This is Erik.txt!!!!\n";
    close($fh);
}

my $cgi = CGI->new();
$cgi->param('cgi', $cgi);
my $x = 'XX';

Erik::sanity();
Erik::sanity('This is a sanity line');
Erik::info('This is a info line');
Erik::log('This is a log line');
my_sub();

Erik::dump(cgi => $cgi);
Erik::dump(cgi => $cgi, 1);
Erik::dump(cgi => $cgi, max_depth => 2);


Erik::disable;
Erik::sanity("This should not be printed");
Erik::enable;
Erik::sanity("You should see this now");

second::testing();
yans::yam();

Erik::enable('second');
second::testing();
yans::yam();
Erik::sanity("Shouldn't see main sanity");
Erik::enable();
Erik::sanity("Should have only seen second::testing above");
Erik::disable('second');
second::testing();
yans::yam();
Erik::enable();
Erik::sanity("Should have only seen yans::yam above");
Erik::disable('second', 'yans');
second::testing();
yans::yam();
Erik::sanity("Should only see this sanity line");
Erik::enable();



Erik::info("This is what info looks like");

Erik::vars(cgi => $cgi);
Erik::vars(cgi => $cgi, x => $x);

Erik::min($_) for 1..10;
Erik::sanity("1 though 10 should be on the previous line");

Erik::moduleLocation();
Erik::moduleLocation('Erik');

Erik::printFile($tmp_file);

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

Erik::yell("This is the end");

Erik::min('Good-bye');
Erik::min("this is min and the command prompt should be on the next line");

sub my_sub {
    Erik::subroutine;
    Erik::method;
}

sub stackTrace {
    _stackTrace();
}
sub _stackTrace {
    Erik::stackTrace;
}

package second;

sub testing {
    Erik::subroutine;
    Erik::sanity("This is in another name space");
}

package yans;

sub yam {
    Erik::subroutine;
    Erik::sanity("This is yet another method in yet another name space");
}
