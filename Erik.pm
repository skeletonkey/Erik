package Erik;

use strict;
no warnings;

=head1 NAME

Erik - Erik's debugging methods

=head1 Description

Quick methods for debugging.

When calling several variables can be passed in:

=over 4

=item text|html - the expected output format - Default: text

If neither is provided then it will attempt to guess by checking %ENV for any keys starting with HTTP_.

=item on|off - initial state of debugging output on/off - Default: on

=item force_html_header - print an HTML style header as soon as possible

The header printed depends on what mode it is in:

=over 4

=item text - Content-type: text/plain\n\n

=item html - Content-type: text/html\n\n

=back

=item log - print everything to a log file (/home/erik/erik.out)

This is hardcoded for ease of use.  To change this update the $log_filename variable.

=item line - print line/program info before all non sanity outputs

=item stderr - print everything to STDERR instead of STDOUT

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

=head1 USAGE

 use Erik qw(off html);

 Erik::dump('name', $ref_to_dump); # uses Data::Dumper;

 Erik::info('Just something to display');

 Erik::sanity();          # output: file_name [line_num]
 Erik::sanity('message'); # output: file_name [line_num]: message

 Erik::stackTrace(); # full blow stack trace telling you how you got there

 Erik::vars('name', $name); # just prints out that variable
 Erik::vars({ name1 => $name1, name2 => $name2 }); # print one line sep by tabs

=cut

my %_settings = (
	mode   => 0, # text|html
	state  => 1, # 1 - on, 0 - off, -1 - single command off
	line   => 0, # 1 - auto print line/program info before most prints
	stderr => 0, # 1 - print everything to STDERR else to STDOUT
	log    => 0, # 1 - print evertyhing to /home/erik/erik.out
	logger => 0, # 1 - send prints also to Log::Log4perl's logger
	pid    => 0, # 1 - print the process id and order id

  _header_printed => 1, # since only printed once a value of 0 means print
	_logger         => undef, # only get the Log::Log4perl's logger once
);

my $log_filename = '/home/erik/erik.out';

=head1 METHODS

=head2 stackTrace

=over 4

=item Description

 Erik::stackTrace();

Full blown stack trace telling you how you got there.  This will only happen once per subroutine - so it's safe to call it in a loop.

=back

=cut
my %stackTraceLimit = ();
sub stackTrace {
	my $level = 1;
	my $output = '';
	CALLER: while (my @data = caller($level++)) {
		last CALLER if $stackTraceLimit{$data[3]}++ > 20;
		$output .= _header('stack trace') if $level == 2;
		$output .= 'Level ' . ($level - 1) . ': ' . join(' - ', @data[0..3]) . "\n";
	}
	$output .= _header('end of stack trace') if $level > 2;
	_print($output);
} # END: stackTrace

=head2 dump

=over 4

=item Description


 Erik::dump('name', $ref_to_dump);
 Erik::dump(name => $ref_to_dump);

This will 'dump' the content of the variable reference that is passed.  The name is simply what is displayed above and below it.

It will attempt to use Data::Dumper.  If it is not installed then it just blows up.

=back

=cut
sub dump {
	my $args = _prep_args(@_);
	my $name = (keys(%$args))[0];
	my $var = $args->{$name};

    require Data::Dumper;
    my $dump = Data::Dumper->Dump([$var]);

	_print(_header($name) . $dump . _header("END: $name"));
} # END: dump

=head2 moduleLocation

=over 4

=item Description


 Erik::moduleLocation();
 Erik::moduleLocation('carp');

This will display a nice version of %INC.  If an arg is provided it will be
used to filter for that string (case in-sensitive) in %INC's keys.

=back

=cut
sub moduleLocation {
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

} # END: dump

=head2 info

=over 4

=item Description


 Erik::info('Some information to display');

This will print the information between two lines of '*****'s.

=back

=cut
sub info {
	_print('*'x80, shift, '*'x80, "\n");
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
		. join("\t", map({"$_: " . _isDefined($args->{$_})} sort {$a cmp $b} keys %$args))));
} # END: vars

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
	my @data = caller;
	_print(_header("$data[1] [$data[2]]" . (defined($string) ? ": $string" : '')));
} # END: sanity

=head2 subroutine

=over 4

=item Description

 Erik::subroutine();

Simply print a line with the following format:
*** file_name [line_num]: SubroutineName ***************************************

=back

=cut
sub subroutine {
	my @data = caller;
	my $string = "$data[1] [$data[2]]: ";

	@data = caller 1;
	my ($subroutine) = $data[3] =~ /([^:]+)$/;
	$string .= $subroutine;
	
	_print(_header($string));
} # END: sanity

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
} # END: min

=head2 toggle

=over 4

=item Description

 Erik::toggle();

Toggles the on/off state of the debugger.  If it's off nothing gets printed.

=back

=cut
sub toggle { $_settings{state} = !$_settings{state}; } # END: toggle

=head2 disable

=over 4

=item Description

 Erik::disable();

Turn off state of the debugger.

=back

=cut
sub disable { $_settings{state} = 0; } # END: disable

=head2 enable

=over 4

=item Description

 Erik::enable();

Toggles the on state of the debugger.

=back

=cut
sub enable  { $_settings{state} = 1; } # END: enable

=head2 singleOff

=over 4

=item Description

 Erik::singleOff();

Turns off debugging for the next command then it's turned back on again.  If debugging is off already then it does nothing.

=back

=cut
sub singleOff { $_settings{state} = -1 if $_settings{state}; } # END: toggle

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

=head2 printFile

=over 4

=item Description

 Erik::printFile($filename);

Print out the content of the file.

=back

=cut
sub printFile {
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

sub _isDefined {
	my $var = shift;
	$var = '[UNDEF]' unless defined($var);
	return $var;
} # END: _isDefined

sub _header {
	return _noticable(shift);
} # END: _header

sub _noticable {
	my $string = shift || return 'nothing passed';

	return '*'x3 . " $string " . '*'x(75 - length($string)) . "\n";
} # END: _noticable

sub _print {
	return if $_settings{state} == 0 || $ENV{ERIK_DISABLE};

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

	if ($_settings{state} == -1) {
		$_settings{state} = 1;
	}
	else {
		my $output = join("\n", @_);

		if ($_settings{line} && (caller(1))[3] ne 'Erik::sanity') {
			my @data = caller(1);
			$output = _header("$data[1] [$data[2]]") . $output;
		}

		if ($_settings{pid}) {
			$output = "[$$." . ++$_settings{pid_counters}{$$} . '] ' . $output;
		}

		$output = _html_friendly($output) if $_settings{mode} eq 'html';

		if ($_settings{logger}) {
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
} # END: _print

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
  if ($_settings{mode} eq 'html') {
    return "Content-type: text/html\n\n";
  }
  else {
    die("Unsupported mode type: $_settings{mode}\n");
  }
} # END: _get_header

sub _prep_args {
	return UNIVERSAL::isa($_[0], 'HASH') ? $_[0] : { @_ };
} # END: _prep_args

sub import {
	shift;
	foreach (@_) {
		$_settings{mode}   = 'html', next if /^html$/i;
		$_settings{mode}   = 'text', next if /^text$/i;
		$_settings{line}   = 1,      next if /^line$/i;
		$_settings{log}    = 1,      next if /^log$/i;
		$_settings{logger} = 1,      next if /^logger$/i;
		$_settings{state}  = 0,      next if /^off$/i;
		$_settings{stderr} = 1,      next if /^stderr$/i;
		$_settings{pid}    = 1,      next if /^pid$/i;

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
} # END: import

sub _html_friendly {
	my $string = shift || return '';

	$string =~ s/  /&nbsp;&nbsp;/g;
	$string =~ s/>/&gt;/g;
	$string =~ s/</&lt;/g;
	
	$string =~ s/\n/<BR>/g;

	return $string;
} # END: _html_friendly

1;

__END__

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
