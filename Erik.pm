package Erik;

use strict;
no warnings;

=head1 NAME

Erik - Erik's debugging buddy

=head1 Description

Quick methods for debugging Perl.

When calling several variables can be passed in:

=over 4

=item epoch - pre-pend log lines with the epoch timestamp

=item force_html_header - print an HTML style header as soon as possible

The header printed depends on what mode it is in:

=over 4

=item text - Content-type: text/plain\n\n

=item html - Content-type: text/html\n\n

=back

=item disable_header - if set the no information is printed that identifies the starting a new logging session

=item line - print line/program info before all non sanity outputs

=item log - print everything to a log file (/tmp/erik.out)

This is hardcoded for ease of use.  To change this update the $log_filename variable.

This will also force the mode into text.  Passing 'html' will not work - it'll be ignored.

=item logger - use Log::Log4perl to write all information as 'debug'

=item on|off - initial state of debugging output on/off - Default: on

=item pid - print Process ID to each line

=item report - print report when process is done

Currently, this is just a summary of the methods that were called with a count.

=item stderr - print everything to STDERR instead of STDOUT

=item text|html - the expected output format - Default: text

If neither is provided then it will attempt to guess by checking %ENV for any keys starting with HTTP_.

=item time - pre-pend log lines with a human readable timestamp

=item time_stats - pre-pend log lines with timing stats: seconds since last log line - seconds since start of program

=back

=head1 ENVIRONMENTAL VARIABLE

=over 4

=item ERIK_OFF

Same as passing 'off' when loading the module.  Found that sometimes it's easier
to do this than find the right 'use Erik' and turn it off.  Also, enable/disable
calls are honored.

=item ERIK_DISABLE

Totally disables Erik's print method so nothing will show up.

=back

=head1 .erikrc

If .erikrc is found in your home directory ($ENV{HOME}/.erikrc, /etc/.erikrc).
The first one found will be loaded and those setting will be applied.

NOTE: settings are overwritten by what you specify while using Erik.

In an attempt to keep Erik light weight the config needs to be in a data
structure that can be eval'ed.

Example:

    {
        # any settings in the import method can be set
        on   => 1,
        log  => 1,
        mode => 'text',
        # Setting for Data::Dumper: https://metacpan.org/pod/Data::Dumper#Configuration-Variables-or-Methods
        # These will be only applied if Erik::dump is used
        dumper => {
            Indent   => 2,
            Maxdepth => 3,
            Sortkeys => 1,
        }
    }

=head1 USAGE

 use Erik qw(off html);

 Erik::dump('name', $ref_to_dump); # uses Data::Dumper;

 Erik::info('Just something to display');

 Erik::sanity();          # output: file_name [line_num]
 Erik::sanity('message'); # output: file_name [line_num]: message

 Erik::stack_trace(); # full blow stack trace telling you how you got there

 Erik::vars('name', $name); # just prints out that variable
 Erik::vars({ name1 => $name1, name2 => $name2 }); # print one line sep by tabs

=cut

my %_settings = (
  line   => 0, # 1 - auto print line/program info before most prints
  log    => 0, # 1 - print evertyhing to /tmp/erik.out
  logger => 0, # 1 - send prints also to Log::Log4perl's logger
  mode   => 0, # text|html
  pid    => 0, # 1 - print the process id and order id
  report => 0, # 1 - print a general report when done - right now just a method call count
  state  => 1, # 1 - on, 0 - off, -1 - single command off
  stderr => 0, # 1 - print everything to STDERR else to STDOUT

  _header_printed    => 1, # since only printed once a value of 0 means print
  _logger            => undef, # only get the Log::Log4perl's logger once
  _publish_separator => ' :: ', # separator used by the publish method
  _stack_trace_limit => 1, # num of stack traces to print out from a given subroutine - use stack_trace_limit to change this
  _time_last         => time,
  _time_start        => time,
);
my %_default_settings = %_settings;

my $log_filename       = '/tmp/erik.out';
my %class_restrictions = ( none => 1 ); # if enable/disable called for specific name spaces
my %_subroutine_report = ();

END {
  print("\n") if $_settings{_min_mode};

  if (keys %_subroutine_report && $_settings{report}) {
    my $report = "\nSubroutine Call Report\n**********************\n";
    $report .= sprintf("%10d :: %s\n", $_subroutine_report{$_}, $_)
      for sort {$a cmp $b} keys %_subroutine_report;
    $report .= "\n";
    _print($report);
  }
}

=head1 METHODS

=head2 stack_trace

=over 4

=item Description

 Erik::stack_trace_limit(9999); # known bug - without this line stack_trace will not print
 Erik::stack_trace();
 Erik::stack_trace(1);
 Erik::stack_trace(5);

Full blown stack trace telling you how you got there.  This will only happen once per subroutine - so it's safe to call it in a loop. This can be changed by calling stack_trace_limit.

The argument will limit the number of 'levels' that are displayed for a stack trace.  Using a '1' is simply asking what/who has called the current method.

=back

=cut
my %stack_trace_limit = ();
sub stack_trace {
  my $display_level = shift || 999999; # # of level's to show in a stack trace
  my $level = 1; # level counter
  my $limit_reached; # signal that we reached the max # of stack traces for a method
  my $output = _header('stack trace');
  CALLER: while (my @data = caller($level)) {
    $limit_reached = 1, last CALLER if ++$stack_trace_limit{$data[3]} > $_settings{_stack_trace_limit};
    last unless $display_level > 0;
    if ($level == 1 && $display_level == 1) { # we only want to see what called this instead of full stack trace
      $output = 'Caller: ' . join(' - ', @data[0..3]) . "\n";
    }
    else {
      $output .= "Level $level: " . join(' - ', @data[0..3]) . "\n";
    }
    $display_level--;
    $level++;
  }
  # I'm sure there's a more effecient way of doing this, but I can't think of it right now
  $output .= "WARNING: called from main - no stack trace available\n"
    if $level == 1;
  $output .= _header('end of stack trace') unless $level == 2 && $display_level == 0;
  $output = '' if $limit_reached;
  _print($output);
}

=head2 stack_trace_limit

=over 4

=item Description

 my $limit = Erik::stack_trace_limit();
 my $limit = Erik::stack_trace_limit(5);

Set/Get the number of times a stack trace will be printed for a subroutine.

Default is set to 1 so that you don't get a ton of output if a subroutine is called mulitple times.

=back

=cut
sub stack_trace_limit {
    my $new_setting = shift || 0;
    $_settings{_stack_trace_limit} = $new_setting if $new_setting;
    return $_settings{_stack_trace_limit};
}

=head2 dump_setting

=over 4

=item Description

 Erik::dump_setting(Indent => 1);
 Erik::dump_setting(Pad => 'ERIK');

Set any of the config/method variable that are available.

See Data::Dumper man page.

=back

=cut
sub dump_setting {
    my $method   = shift || die("No method provided to dump_setting\n");
    my $value    = shift;
    my $internal = shift || 0; # internal use so that setting max depth isn't permanent

    die("No value provided to dump_setting for $method\n") unless defined $value;

    delete $_settings{_rc_settings}{dumper}{$method}
        if exists $_settings{_rc_settings}{dumper}{$method} && !$internal;

    require Data::Dumper;

    {
        no strict;
        ${"Data::Dumper::$method"} = $value;
    }
}

=head2 dump

=over 4

=item Description


 Erik::dump('name', $ref_to_dump);
 Erik::dump(name => $ref_to_dump);
 Erik::dump(name => $ref_to_dump, maxdepth => 3);
 Erik::dump(name => $ref_to_dump, 3);
 Erik::dump($ref_to_dump);
 Erik::dump($ref_to_dump, maxdepth => 3); # WILL NOT WORK!!!!!!!!!!!!!!!!
 Erik::dump($ref_to_dump, 3);             # WILL NOT WORK!!!!!!!!!!!!!!!!

This will 'dump' the content of the variable reference that is passed.  The name is simply what is displayed above and below it.

It will attempt to use Data::Dumper.  If it is not installed then it just blows up.

maxdepth (or a simple number as the 3rd arg) will limit the depth of the dump.  (Used to set $Data::Dumper::Maxdepth)  No argument or 0 assumes unlimited.

If you only provide a reference to a variable it will dump that out.  There is no ability to set maxdepth with this.  Infact, using maxdepth at that point will not work!!!!

=back

=cut
sub dump {
    my $name = shift;
    my $var  = shift;

    if (!defined $var) {
        if (ref $name) {
            $var  = $name;
            $name = 'No Name Provided';
        }
        else {
            my @called_from = caller;
            warn("dump called improperly ("
                . $called_from[1] . ' [' . $called_from[2]
                . "]): USAGE: Erik::dump(title => \\\%var);\n");
        }
    }

    my $max_depth_label = shift;
    my $max_depth       = shift;

    $max_depth = $max_depth_label if $max_depth_label =~ /^\d+$/;

    require Data::Dumper;

    Erik::dump_setting($_, $_settings{_rc_settings}{dumper}{$_}, 1)
      for keys %{$_settings{_rc_settings}{dumper}};
    Erik::dump_setting(Maxdepth => $max_depth, 1) if defined $max_depth;

    my $dump = Data::Dumper->Dump([$var]);

    Erik::dump_setting(Maxdepth => (exists $_settings{_rc_settings}{Maxdepth} ? $_settings{_rc_settings}{Maxdepth} : 0))
      if defined $max_depth; # reset so it doesn't effect the next call

  _print(_header($name) . $dump . _header("END: $name"));
}

=head2 module_location

=over 4

=item Description


 Erik::module_location();
 Erik::module_location('carp');
 Erik::module_location('ssl');

 Will print out all loaded modules (that match case-insensitive to the provided string) and the locations of their code.

=back

=cut
sub module_location {
    my $search_arg = shift || '';

    my $name = 'Module Location';
    _print(_header($name));
    my $found = 0;
    KEY: foreach my $key (sort {uc($a) cmp uc($b)} keys %INC) {
        next KEY if $search_arg && $key !~ /$search_arg/i;
        _print($key . ' => ' . $INC{$key} . "\n");
        $found = 1;
    }
    _print("Search arg ($search_arg) no found in \%INC\n") unless $found;
    _print(_header("END: $name"));

}

=head2 yell

=over 4

=item Description


 Erik::yell('Some information to display');

This will print the information between two lines of '*****'s.

=back

=cut
sub yell {
  _print('*'x80, shift, '*'x80 . "\n");
}

=head2 vars

=over 4

=item Description

 Erik::vars('name', $name);
 Erik::vars(name => $name);
 Erik::vars(name1 => $name1, name2 => $name2);

Print out the line number and then name/value seperated by ':' if more than one pair is given.

=back

=cut
sub vars {
  my $args = _prep_args(@_);

  my @data = caller;
  _print(_noticable(" $data[2] - "
    . join("\t", map({"$_: " . _is_defined($args->{$_})} sort {$a cmp $b} keys %$args))));
}

=head2 sanity

=over 4

=item Description

 Erik::sanity();
 Erik::sanity('message');

Simply print a line with the following format:
*** file_name [line_num]: message if provided *********************************

=back

=cut
sub sanity {
  my $string = shift;
  chomp($string);
  my @data = caller;
  my $stack_level = 1;
  while ($data[0] eq 'Erik') {
      @data = caller $stack_level++;
  }
  _print(_header("$data[1] [$data[2]]" . (defined($string) ? ": $string" : '')));
}

=head2 info

=over 4

=item Description

 Erik::info();

 An alias for Erik::sanity(). See sanity documentation above.

=back

=cut
sub info { goto &sanity; }

=head2 log

=over 4

=item Description

 Erik::log();

 An alias for Erik::sanity(). See sanity documentation above.

=back

=cut
sub log { goto &sanity; }

=head2 warn

=over 4

=item Description

 Erik::warn();

 An alias for Erik::sanity(). See sanity documentation above.

=back

=cut
sub warn { goto &sanity; }

=head2 subroutine

=over 4

=item Description

 Erik::subroutine();

Simply print a line with the following format:
*** file_name [line_num]: Subroutine_Name **************************************

=back

=cut
sub subroutine {
  my @data = caller;
  my $string = "$data[1] [$data[2]]: ";

  @data = caller 1;
  my ($subroutine) = $data[3] =~ /([^:]+)$/;
  $_subroutine_report{$subroutine}++;
  $string .= $subroutine;

  _print(_header($string));
}

=head2 method

=over 4

=item Description

 Erik::method();

 An alias for Erik::subroutine(). See subroutine documentation above.

=back

=cut
sub method { goto &subroutine; }

=head2 min

=over 4

=item Description

 Erik::min('message');

A compact way of printing things out.  Ideally used in a loop so that you don't
burn through the scrollback buffer.

=back

=cut
sub min {
  my $string = shift;

  if ($_settings{_min_mode}) {
    $string = ", $string";
  }
  else {
    $_settings{_min_mode} = 1;
  }

  _print($string);
}

=head2 toggle

=over 4

=item Description

 Erik::toggle();

Toggles the enable/disable state of the debugger.  If it's off nothing gets printed.

=back

=cut
sub toggle { $_settings{state} = !$_settings{state}; }

=head2 disable

=over 4

=item Description

 Erik::disable();
 Erik::disable('Module::Name::A', 'Module::Name::B');

Turn off state of the debugger.

If a list of modules name(s) is provided then only disable debugging in those. Calling it again without a list will disable debugging everywhere.

=back

=cut
sub disable {
    my @modules = @_;

    if (@modules) {
        %class_restrictions = ( disable => \@modules );
    }
    else {
        %class_restrictions = ( none    => 1         );
    }

    $_settings{state} = 0;
}

=head2 enable

=over 4

=item Description

 Erik::enable();
 Erik::enable('Module::Name::A', 'Module::Name::B');

Toggles the on state of the debugger.

If a list of modules name(s) is provided then only enable debugging in those. Calling it again without a list will enable debugging everywhere.

=back

=cut
sub enable  {
    my @modules = @_;

    if (@modules) {
        %class_restrictions = ( enable => \@modules );
    }
    else {
        %class_restrictions = ( none   => 1         );
    }

    $_settings{state} = 1;
}

=head2 evaluate

=over 4

=item Description

 Erik::evaluate(sub { $line_of_code });

If you believe that something is going wrong, but somewhere the error is being
thrown away this method attempts to show you that errror first.

It will most likely disrupt the running of the rest of your script, but if you
are resorting to using it then your script is already crippled.

=back

=cut
sub evaluate {
    my $sub = shift;
    eval { &$sub; };
    if ($@) {
        sanity("Eval produced error: $@");
    }
    else {
        sanity("no errors during eval");
    }
}

=head2 single_off

=over 4

=item Description

 Erik::single_off();

Turns off debugging for the next command then it's turned back on again.  If debugging is off already then it does nothing.

=back

=cut
sub single_off { $_settings{state} = -1 if $_settings{state}; }

=head2 spacer

=over 4

=item Description

 Erik::spacer;
 Erik::spacer(3);

Enter 1 or more new lines to help break up the output

=back

=cut
sub spacer {
  my $count = shift || 1;

  {
    $_settings{line} = 0;
    $_settings{pid} = 0;

    _print("\n" x $count);
  }
}

=head2 print_file

=over 4

=item Description

 Erik::print_file($filename);

Print out the content of the file.

=back

=cut
sub print_file {
    my $filename = shift;
    die("$filename does not exists") unless -e $filename;
    die("$filename is not a file") unless -f $filename;

    my $contents;
    open(my $fh, '<', $filename) || die("Unable to open $filename for read: $!\n");
    {
        $/ = undef;
        $contents = <$fh>;
    }
    close($fh);

    _print(_header("BEGIN: $filename"));
    _print($contents);
    _print(_header("END: $filename"));
}

=head2 append

=over 4

=item Description

  Erik::append("First piece of info");

Adds information to an internal store that will get printed with the 'publish' method.

Each piece of information will be seperate by 'publish_seperator'.

=back

=cut
sub append {
    my $string = shift || return '';
    push(@{$_settings{_publish}}, $string);
}

=head2 publish

=over 4

=item Description

  Erik::publish("Optional last message");

Prints out everything that has been 'append'ed.

It will then reset the internal store.

Each piece of information will be seperate by 'publish_seperator'.

=back

=cut
sub publish {
    my $string = shift || '';
    append($string);
    sanity(join($_settings{_publish_separator}, @{$_settings{_publish}}));
    delete $_settings{_publish};
}

=head2 publish_separator

=over 4

=item Description

  Erik::publish_separator("|");

Set the separator that 'publish' will use when printing everything out.

Default: ' :: ';

=back

=cut
sub publish_separator {
    my $separator = shift || return '';
    $_settings{_publish_separator} = $separator;
}

sub _is_defined {
  my $var = shift;
  $var = '[UNDEF]' unless defined($var);
  return $var;
}

sub _header {
  return _noticable(shift);
}

sub _noticable {
  my $string = shift || return 'nothing passed';

  return '*'x3 . " $string " . '*'x(75 - length($string)) . "\n";
}

# Bad name - inspired by The IT Crowd - Season 2 Episode 1
#                        "I'm Disabled" - Roy
sub _im_disabled {
    my $disabled = 1;
    return $disabled if $ENV{ERIK_DISABLE};

    if (exists $class_restrictions{none}) {
        if ($_settings{state} == 1) {
            $disabled = 0;
        }
        elsif ($_settings{state} == -1) {
            $_settings{state} = 1;
        }
    }
    else {
        my $calling_namespace = '';
        my $level = 1;
        CALLER: while (my @data = caller($level++)) {
            next CALLER if $data[0] eq 'Erik';
            $calling_namespace = $data[0];
            last CALLER;
        }
        if (exists $class_restrictions{disable}) {
            $disabled = 0 unless grep { $calling_namespace eq $_ } @{$class_restrictions{disable}};
        }
        else {
            $disabled = 0 if grep { $calling_namespace eq $_ } @{$class_restrictions{enable}};
        }
    }

    return $disabled;
}

sub _print {
  return if _im_disabled();

  if ($_settings{_min_mode} && (caller(1))[3] ne 'Erik::min') {
    $_settings{_min_mode} = 0;
    _print("\n");
  }

  if (!$_settings{_header_printed}) {
    if ($_settings{stderr}) {
      print(STDERR _get_header());
    }
    elsif ($_settings{log}) {
      open(LOG, ">>$log_filename") || die("Can't open file ($log_filename): $!\n");
      print(LOG _get_header());
      close(LOG);
    }
    else {
      print(_get_header());
    }
    $_settings{_header_printed} = 1;
  }

  my $output = join("\n", @_);

  if ($_settings{line} && (caller(1))[3] ne 'Erik::sanity') {
    my @data = caller(1);
    $output = _header("$data[1] [$data[2]]") . $output;
  }

  if ($_settings{pid}) {
    $output = "[$$." . ++$_settings{pid_counters}{$$} . '] ' . $output;
  }

  my $time_current = time;
  my $total_time = $time_current - $_settings{_time_start};
  my $diff_time  = $time_current - $_settings{_time_last};
  $_settings{_time_last} = $time_current;
  if ($_settings{epoch} || $_settings{time}) {
    $time_current = localtime if $_settings{time};
    $time_current .= " - $diff_time - $total_time" if $_settings{time_stats};

    $output = "[$time_current] " . $output;
  }
  elsif ($_settings{time_stats}) {
    $output = "[$diff_time - $total_time] " . $output;
  }

  $output = _html_friendly($output) if $_settings{mode} eq 'html';

  if ($_settings{logger}) {
    require Log::Log4perl;

    $_settings{_logger} ||= Log::Log4perl->get_logger;

    $_settings{_logger}->debug($output);
  }

  if ($_settings{stderr}) {
    print(STDERR $output);
  }
  elsif ($_settings{log}) {
    open(LOG, ">>$log_filename") || die("Can't open file ($log_filename): $!\n");
    print(LOG $output);
    close(LOG);
  }
  else {
    print($output);
  }
}

sub _get_header {
  if ($_settings{mode} eq 'text') {
    if ($_settings{log}) {
      my $header = ' ' . scalar(localtime()) . ' - NEW LOG START ';
      return "\n" x 2
        . '=' x 80 . "\n"
        . '=' x 3 . $header . '=' x (77 - length($header)) . "\n"
        . '=' x 80 . "\n";
    }
    else {
      return "Content-type: text/plain\n\n";
    }
  }
  elsif ($_settings{mode} eq 'html') {
    return "Content-type: text/html\n\n";
  }
  else {
    die("Unsupported mode type: $_settings{mode}\n");
  }
}

sub _prep_args {
  return UNIVERSAL::isa($_[0], 'HASH') ? $_[0] : { @_ };
}

sub _get_settings {
    return \%_settings;
}

sub _reset_settings {
    %_settings = %_default_settings;
}

# first check in the home directory then try in the /etc directory
sub _get_rc_file {
    my $file = '/.erikrc';

    return $ENV{HOME} . $file if exists $ENV{HOME} && -e $ENV{HOME} . $file;
    return "/etc$file" if -e "/etc$file";
    return undef;
}

sub import {
  shift;

  if (my $rc_file = _get_rc_file()) {
    unless ($_settings{_rc_settings} = do $rc_file) {
      warn "couldn't parse $rc_file: $@\n" if $@;
      warn "couldn't do $rc_file: $!\n"    unless defined $_settings{_rc_settings};
      warn "couldn't run $rc_file\n"       unless $_settings{_rc_settings};
    }

    foreach my $setting (keys %{$_settings{_rc_settings}}) {
      next if $setting eq 'dumper';
      $_settings{$setting} = $_settings{_rc_settings}{$setting};
    }
  }
  foreach (@_) {
    $_settings{epoch}  = 1,      next if /^epoch$/i;
    $_settings{line}   = 1,      next if /^line$/i;
    $_settings{logger} = 1,      next if /^logger$/i;
    $_settings{log}    = 1,      next if /^log$/i;
    $_settings{mode}   = 'html', next if /^html$/i;
    $_settings{mode}   = 'text', next if /^text$/i;
    $_settings{pid}    = 1,      next if /^pid$/i;
    $_settings{report} = 1,      next if /^report$/i;
    $_settings{state}  = 0,      next if /^off$/i;
    $_settings{stderr} = 1,      next if /^stderr$/i;
    $_settings{time}   = 1,      next if /^time$/i;
    $_settings{time_stats} = 1,  next if /^time_stats$/i;
    $_settings{disable_header}=1,next if /^disable_header$/i;

    $_settings{_header_printed} = 0, next if /^force_html_header$/i;
  }

  if (!$_settings{mode}) {
    $_settings{mode} = 'text';
    foreach (keys(%ENV)) {
      $_settings{mode} = 'html', last if /^HTTP_/;
    }
  }

  $_settings{_header_printed} = 0 unless $_settings{mode} eq 'text';

  if ($_settings{log}) {
    $_settings{mode}   = 'text';
    $_settings{stderr} = 0;
    $_settings{_header_printed} = 0;
  }

  $_settings{_min_mode} = 0;

  $_settings{state} = 0 if $ENV{ERIK_OFF};
  $_settings{_header_printed} = 1 if $_settings{disable_header};
}

sub _html_friendly {
  my $string = shift || return '';

  $string =~ s/  /&nbsp;&nbsp;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/</&lt;/g;

  $string =~ s/\n/<BR>/g;

  return $string;
}

1;

__END__

=head1 DEPENDENCIES

Data::Dumper - only if Erik::dump() is called

=head1 AUTHOR

Erik Tank, tank@jundy.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Erik Tank

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

Version 1.0
  Erik Tank - 2011/09/07

Version 1.1
  Erik Tank - 2011/09/07 - added _noticable so that variables are all uc()'ed

Version 1.2
  Erik Tank - 2011/10/25 - added auto line number

Version 1.3
  Erik Tank - 2012/03/12 - added print to log ability

Version 1.4
  Erik Tank - 2012/03/30 - added pid to the output

Version 1.5
  Erik Tank - 2012/04/04 - added log 'header' to seperate program runs

Version 1.6
  Erik Tank - 2012/04/12 - removed the uc() from header because sometimes it gets in the way and it's not worth it

Version 1.7
  Erik Tank - 2013/01/04 - added spacer method

Version 1.8
  Erik Tank - 2013/01/09 - add min

Version 1.9
  Erik Tank - 2013/10/22 - updated dump to actually use Data::Dumper is LW code is not present

Version 1.10
  Erik Tank - 2014/01/13 - added environmental variable ERIK_DISABLE

Version 1.11
  Erik Tank - 2014/01/13 - converted env var ERIK_DISABLE to ERIK_OFF and turned ERIK_DISABLE into a true disable.

Version 1.12
  Erik Tank - 2014/04/01 - Fix info method so that output looks like what I'm expecting.

Version 1.13
  Erik Tank - 2014/10/21 - Remove the use of LW::Util::Dumper

Version 1.14
  Erik Tank - 2014/10/27 - Added module_location sub

Version 1.15
  Erik Tank - 2015/01/20 - Added print_file sub

Version 1.16
  Erik Tank - 2015/03/30 - All to set depth for dump

Version 1.17
  Erik Tank - 2015/04/06 - Added ability to enable/disable Erik in certain namespaces

Version 1.18
  Erik Tank - 2015/04/15 - Add method()

Version 1.19
  Erik Tank - 2015/05/13 - Add info() and log()

Version 1.20
  Erik Tank - 2015/05/13 - If the last command was a min() command print and \n when script ends

Version 1.21
  Erik Tank - 2015/05/26 - minor logic fix

Version 1.22
  Erik Tank - 2015/06/23 - fix yell and add testing

Version 1.23
  Erik Tank - 2015/06/24 - fixed/tested stackTrace - also added ability to change the limit for printing stack traces

Version 1.24
  Erik Tank - 2015/08/02 - added non-CamelCase version of methods

Version 2.00
  Erik Tank - 2015/10/28 - remove camelCase methods

Version 2.01
  Erik Tank - 2015/10/28 - update stack_trace to accept an argument to limit size of stack trace

Version 2.02
  Erik Tank - 2015/11/19 - warn instead of die if dump is used incorrectly. This is a better practice in the circumstance.

Version 2.03
  Erik Tank - 2016/01/06 - added Erik::warn(); another alias for sanity

Version 2.04
  Erik Tank - 2016/01/27 - fix warning on improper dump usage so it tells you where you misused it.

Version 2.05
  Erik Tank - 2016/03/02 - added the ability to set all of Data::Dumper's settings

Version 2.06
  Erik Tank - 2016/07/19 - added the method's called summary report

Version 2.07
  Erik Tank - 2016/09/02 - bug fix and sort Dumper's keys

Version 2.08
  Erik Tank - 2016/09/20 - added evaluate method

Version 2.09
  Erik Tank - 2016/11/18 - add use of .erikrc

Version 2.10
  Erik Tank - 2016/11/21 - minor bug fixes

Version 2.11
  Erik Tank - 2017/01/08 - only show summary report if using 'report' during import (also added POD)

Version 2.12
  Erik Tank - 2017/08/31 - add /etc/.erikrc for systems where you don't know or have access to the process' home directory

Version 2.13
  Erik Tank - 2018/01/29 - added epoch, time, and time_stats to show timing information

Version 2.14
  Erik Tank - 2018/10/22 - added append and publish ability

Version 2.15
  Erik Tank - 2018/10/25 - added 'disable_header' setting

Version 2.15.1
  Erik Tank - 2018/11/09 - update POD for module_location and other small changes
