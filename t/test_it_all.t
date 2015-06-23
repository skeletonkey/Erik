#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Mock::Simple;

require_ok('Erik');

my %default_settings = (
    _header_printed => 1,
    _logger         => undef,
    _min_mode       => 0,
    line            => 0,
    log             => 0,
    logger          => 0,
    mode            => 0,
    pid             => 0,
    state           => 1,
    stderr          => 0,
);

my %setting_tests = (
    1234              => { mode => 'text', },
    force_html_header => { _header_printed => 0, mode => 'text'},
    html              => { mode => 'html', _header_printed => 0 },
    line              => { line => 1, mode => 'text' },
    log               => { log => 1, _header_printed => 0, mode => 'text' },
    logger            => { logger => 1, mode => 'text' },
    off               => { state => 0, mode => 'text' },
    pid               => { pid => 1, mode => 'text' },
    stderr            => { stderr => 1, mode => 'text' },
    text              => { mode => 'text' },
);

foreach my $key (keys %setting_tests) {
    Erik::_reset_settings(),
    Erik->import($key);
    cmp_deeply(
        Erik::_get_settings(),
        {%default_settings, %{$setting_tests{$key}}},
        "Trying: $key"
    );
}

Erik::_reset_settings();
is(Erik::_get_settings()->{state}, 1, 'State is on');
Erik::toggle();
is(Erik::_get_settings()->{state}, '', 'State is off after toggle');
Erik::disable();
is(Erik::_get_settings()->{state}, 0, 'State is off after disable');
Erik::enable();
is(Erik::_get_settings()->{state}, 1, 'State is on after enable');
Erik::singleOff();
is(Erik::_get_settings()->{state}, -1, 'State is in single off mode');
Erik::disable();
is(Erik::_get_settings()->{state}, 0, 'State is off after disable');
Erik::singleOff();
is(Erik::_get_settings()->{state}, 0, 'State is still off after singleOff attempt');

Erik::enable();

my $erik_mock = Test::Mock::Simple->new(module => 'Erik');
my $temp_var = '';
$erik_mock->add(_print => sub { $temp_var = join("\n", @_); });

Erik::sanity("Testing 2");
is(
    $temp_var,
    "*** t/test_it_all.t [69]: Testing 2 ********************************************\n",
    "Sanity with a string works"
);

Erik::sanity();
is(
    $temp_var,
    "*** t/test_it_all.t [76] *******************************************************\n",
    "Sanity without any string works"
);

Erik::yell('Hello World');
is(
    $temp_var,
    "********************************************************************************\n"
        . "Hello World\n"
        . "********************************************************************************\n",
    "Yelling"
);

my ($x, $y, $z) = (1, 2, 3);

Erik::vars(x => $x);
is(
    $temp_var,
    "***  94 - x: 1 *****************************************************************\n",
    "vars with just x"
);

undef($x);
Erik::vars(z => $z, 'Just Me' => $y, x => $x);
is(
    $temp_var,
    "***  102 - Just Me: 2\tx: [UNDEF]\tz: 3 ******************************************\n",
    "vars with just x"
);

Erik::info();
is(
    $temp_var,
    "*** t/test_it_all.t [109] ******************************************************\n",
    "info works"
);

Erik::log('Log This');
is(
    $temp_var,
    "*** t/test_it_all.t [116]: Log This ********************************************\n",
    "info works"
);

sub yas { Erik::subroutine(); }
yas();
is(
    $temp_var,
    "*** t/test_it_all.t [123]: yas *************************************************\n",
    "info works"
);

sub yam { Erik::method(); }
yam();
is(
    $temp_var,
    "*** t/test_it_all.t [131]: yam *************************************************\n",
    "method works"
);

Erik::spacer();
is(
    $temp_var,
    "\n",
    "Spacer with no args"
);

Erik::spacer(5);
is(
    $temp_var,
    "\n"x5,
    "Spacer with 5"
);

is(
    Erik::_noticable(),
    "nothing passed",
    "_noticable with nothing passed"
);

done_testing();
