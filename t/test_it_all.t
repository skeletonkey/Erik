#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Mock::Simple;

unshift @INC, '.'; require_ok('Erik');

my %default_settings = (
    _header_printed    => 1,
    _logger            => undef,
    _stack_trace_limit => 1,
    _min_mode          => 0,
    line               => 0,
    log                => 0,
    logger             => 0,
    mode               => 0,
    pid                => 0,
    state              => 1,
    stderr             => 0,
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
Erik::single_off();
is(Erik::_get_settings()->{state}, -1, 'State is in single off mode');
Erik::disable();
is(Erik::_get_settings()->{state}, 0, 'State is off after disable');
Erik::single_off();
is(Erik::_get_settings()->{state}, 0, 'State is still off after single_off attempt');

Erik::enable();

my $erik_mock = Test::Mock::Simple->new(module => 'Erik');
my $temp_var = '';
$erik_mock->add(_print => sub { $temp_var = join("\n", @_); });

Erik::sanity("Testing 2");
is(
    $temp_var,
    "*** t/test_it_all.t [70]: Testing 2 ********************************************\n",
    "Sanity with a string works"
);

Erik::sanity();
is(
    $temp_var,
    "*** t/test_it_all.t [77] *******************************************************\n",
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
    "***  95 - x: 1 *****************************************************************\n",
    "vars with just x"
);

undef($x);
Erik::vars(z => $z, 'Just Me' => $y, x => $x);
is(
    $temp_var,
    "***  103 - Just Me: 2\tx: [UNDEF]\tz: 3 ******************************************\n",
    "vars with just x"
);

Erik::info();
is(
    $temp_var,
    "*** t/test_it_all.t [110] ******************************************************\n",
    "info works"
);

Erik::log('Log This');
is(
    $temp_var,
    "*** t/test_it_all.t [117]: Log This ********************************************\n",
    "info works"
);

sub yas { Erik::subroutine(); }
yas();
is(
    $temp_var,
    "*** t/test_it_all.t [124]: yas *************************************************\n",
    "info works"
);

sub yam { Erik::method(); }
yam();
is(
    $temp_var,
    "*** t/test_it_all.t [132]: yam *************************************************\n",
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

is(Erik::stack_trace_limit(),  1, 'Get stack trace limit');
is(Erik::stack_trace_limit(5), 5, 'Set stack trace limit');
is(Erik::stack_trace_limit(),  5, 'Get stack trace limit after setting it');
Erik::stack_trace_limit(1);
sub yast  { yast2(); }
sub yast2 { Erik::stack_trace(); }
yast();
is(
    $temp_var,
    q+*** stack trace ****************************************************************
Level 1: main - t/test_it_all.t - 164 - main::yast2
Level 2: main - t/test_it_all.t - 166 - main::yast
*** end of stack trace *********************************************************
+,
    "Stack Trace"
);

Erik::stack_trace();
is(
    $temp_var,
    '',
    "StackTracing nothing"
);

yast() for 1..2;
is(
    $temp_var,
    '',
    "stack_trace called 2 times with default limit"
);

# why 5? the count is done through the run the program so to make sure that
# limit works ... just trust me this tests the correct thing :)
Erik::stack_trace_limit(5);
yast() for 1..2;
is(
    $temp_var,
    q+*** stack trace ****************************************************************
Level 1: main - t/test_it_all.t - 164 - main::yast2
Level 2: main - t/test_it_all.t - 194 - main::yast
*** end of stack trace *********************************************************
+,
    "stack_trace called 2 times with limit set to 5"
);

yast();
is(
    $temp_var,
    '',
    "stack_trace called after limit has been reached"
);

$x = [
    1,
    { 2 => 'two' },
    3,
];
Erik::dump(x => $x);
is(
    $temp_var,
    q+*** x **************************************************************************
$VAR1 = [
          1,
          {
            '2' => 'two'
          },
          3
        ];
*** END: x *********************************************************************
+,
    "Dump a variable"
);

Erik::dump(x => $x, 1);
is(
    $temp_var,
    qq+*** x **************************************************************************
\$VAR1 = [
          1,
          '$x->[1]',
          3
        ];
*** END: x *********************************************************************
+,
    "Dump a variable with max depth of 1"
);

is(
    Erik::_html_friendly(),
    '',
    "_html_friendly with no arg"
);

is(
    Erik::_html_friendly('Hello World'),
    'Hello World',
    "_html_friendly with Hello World"
);

is(
    Erik::_html_friendly('<h1>Hello World  </h1>'),
    '&lt;h1&gt;Hello World&nbsp;&nbsp;&lt;/h1&gt;',
    '_html_friendly with <h1>Hello World  </h1>'
);

eval { Erik::_get_header() };
is(
    $@,
    "Unsupported mode type: 0\n",
    'Header gonna die!!!!'
);

Erik->import(html => 1);
is(
    Erik::_get_header(),
    "Content-type: text/html\n\n",
    "HTML header"
);

Erik->import(text => 1);
is(
    Erik::_get_header(),
    "Content-type: text/plain\n\n",
    "Text header without logging"
);

Erik::_reset_settings(),
$ENV{ERIK_OFF} = 1;
$ENV{HTTP_TESTING} = 1;
Erik->import();
is(
    Erik::_get_header(),
    "Content-type: text/html\n\n",
    "HTML header from ENV"
);
delete $ENV{ERIK_OFF};
delete $ENV{HTTP_TESTING};

Erik::enable();
is(
    Erik::_im_disabled(),
    0,
    "Shouldn't be disabled"
);

Erik::min(1);
is(
    $temp_var,
    '1',
    'using min with 1'
);
Erik::min(2);
is(
    $temp_var,
    ', 2',
    'min a second time'
);

Erik::dump($x);
is(
    $temp_var,
q+*** No Name Provided ***********************************************************
$VAR1 = [
          1,
          {
            '2' => 'two'
          },
          3
        ];
*** END: No Name Provided ******************************************************
+,
    "Dump a variable with only a ref"
);

done_testing();
