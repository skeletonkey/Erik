#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

unshift @INC, '.';

require_ok('Erik');

{
    my $temp_out;
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
