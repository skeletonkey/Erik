#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

unshift @INC, '.';

require_ok('Erik');

{
    my $temp_out;

    close STDOUT;
    open STDOUT, '>', \$temp_out || die "Unable to open STDOUT: $!\n";
    $ENV{ERIK_DISABLE} = 1;
    Erik::sanity("This will not print");
    is($temp_out, undef, 'No printing while ENV ERIK_DISABLE is set');

    delete $ENV{ERIK_DISABLE};
    close STDOUT;
    open STDOUT, '>', \$temp_out || die "Unable to open STDOUT: $!\n";
    Erik::sanity("This will print");
    is(
        $temp_out,
        "*** t/another_test.t [" . (__LINE__ - 3) . "]: This will print *************************************\n",
        "Sanity prints again"
    );

    close STDOUT;
    open STDOUT, '>', \$temp_out || die "Unable to open STDOUT: $!\n";
    Erik::min(1);
    is($temp_out, '1', 'Make sure that we have min mode');

    close STDOUT;
    open STDOUT, '>', \$temp_out || die "Unable to open STDOUT: $!\n";
    Erik::sanity('Yet another sanity');
    is(
        $temp_out,
        "\n*** t/another_test.t [" . (__LINE__ - 3) . "]: Yet another sanity **********************************\n",
        "Script should not get an extra \\n at the end because of min mode\n"
    );
    
}

done_testing();
