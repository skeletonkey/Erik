# NAME

Erik - Erik's debugging methods

# Description

Quick methods for debugging.

When calling several variables can be passed in:

- text|html - the expected output format - Default: text

    If neither is provided then it will attempt to guess by checking %ENV for any keys starting with HTTP\_.

- on|off - initial state of debugging output on/off - Default: on
- force\_html\_header - print an HTML style header as soon as possible

    The header printed depends on what mode it is in:

    - text - Content-type: text/plain\\n\\n
    - html - Content-type: text/html\\n\\n

- line - print line/program info before all non sanity outputs
- log - print everything to a log file (/home/erik/erik.out)

    This is hardcoded for ease of use.  To change this update the $log\_filename variable.

    This will also force the mode into text.  Passing 'html' will not work - it'll be ignored.

- logger - use Log::Log4perl to write all information as 'debug'
- pid - print Process ID to each line
- report - print report when process is done

    Currently, this is just a summary of the methods that were called with a count.

- stderr - print everything to STDERR instead of STDOUT

# ENVIRONMENTAL VARIABLE

- ERIK\_OFF

    Same as passing 'off' when loading the module.  Found that sometimes it's easier
    to do this than find the right 'use Erik' and turn it off.  Also, enable/disable
    calls are honored.

- ERIK\_DISABLE

    Totally disables Erik's print method so nothing will show up.

# .erikrc

If .erikrc is found in your home directory ($ENV{HOME}/.erikrc).  It will be
loaded and those setting will be applied.

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

# USAGE

    use Erik qw(off html);

    Erik::dump('name', $ref_to_dump); # uses Data::Dumper;

    Erik::info('Just something to display');

    Erik::sanity();          # output: file_name [line_num]
    Erik::sanity('message'); # output: file_name [line_num]: message

    Erik::stack_trace(); # full blow stack trace telling you how you got there

    Erik::vars('name', $name); # just prints out that variable
    Erik::vars({ name1 => $name1, name2 => $name2 }); # print one line sep by tabs

# METHODS

## stack\_trace

- Description

        Erik::stack_trace_limit(9999); # known bug - without this line stack_trace will not print
        Erik::stack_trace();
        Erik::stack_trace(1);
        Erik::stack_trace(5);

    Full blown stack trace telling you how you got there.  This will only happen once per subroutine - so it's safe to call it in a loop. This can be changed by calling stack\_trace\_limit.

    The argument will limit the number of 'levels' that are displayed for a stack trace.  Using a '1' is simply asking what/who has called the current method.

## stack\_trace\_limit

- Description

        my $limit = Erik::stack_trace_limit();
        my $limit = Erik::stack_trace_limit(5);

    Set/Get the number of times a stack trace will be printed for a subroutine.

    Default is set to 1 so that you don't get a ton of output if a subroutine is called mulitple times.

## dump\_setting

- Description

        Erik::dump_setting(Indent => 1);
        Erik::dump_setting(Pad => 'ERIK');

    Set any of the config/method variable that are available.

    See Data::Dumper man page.

## dump

- Description

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

## module\_location

- Description

        Erik::module_location();
        Erik::module_location('carp');

        An alias for Erik::module_location(). See module_location documentation.

## yell

- Description

        Erik::yell('Some information to display');

    This will print the information between two lines of '\*\*\*\*\*'s.

## vars

- Description

        Erik::vars('name', $name);
        Erik::vars(name => $name);
        Erik::vars(name1 => $name1, name2 => $name2);

    Print out the line number and then name/value seperated by ':' if more than one pair is given.

## sanity

- Description

        Erik::sanity();
        Erik::sanity('message');

    Simply print a line with the following format:
    \*\*\* file\_name \[line\_num\]: message if provided \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

## info

- Description

        Erik::info();

        An alias for Erik::sanity(). See sanity documentation above.

## log

- Description

        Erik::log();

        An alias for Erik::sanity(). See sanity documentation above.

## warn

- Description

        Erik::warn();

        An alias for Erik::sanity(). See sanity documentation above.

## subroutine

- Description

        Erik::subroutine();

    Simply print a line with the following format:
    \*\*\* file\_name \[line\_num\]: Subroutine\_Name \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

## method

- Description

        Erik::method();

        An alias for Erik::subroutine(). See subroutine documentation above.

## min

- Description

        Erik::min('message');

    A compact way of printing things out.  Ideally used in a loop so that you don't
    burn through the scrollback buffer.

## toggle

- Description

        Erik::toggle();

    Toggles the enable/disable state of the debugger.  If it's off nothing gets printed.

## disable

- Description

        Erik::disable();
        Erik::disable('Module::Name::A', 'Module::Name::B');

    Turn off state of the debugger.

    If a list of modules name(s) is provided then only disable debugging in those. Calling it again without a list will disable debugging everywhere.

## enable

- Description

        Erik::enable();
        Erik::enable('Module::Name::A', 'Module::Name::B');

    Toggles the on state of the debugger.

    If a list of modules name(s) is provided then only enable debugging in those. Calling it again without a list will enable debugging everywhere.

## evaluate

- Description

        Erik::evaluate(sub { $line_of_code });

    If you believe that something is going wrong, but somewhere the error is being
    thrown away this method attempts to show you that errror first.

    It will most likely disrupt the running of the rest of your script, but if you
    are resorting to using it then your script is already crippled.

## single\_off

- Description

        Erik::single_off();

    Turns off debugging for the next command then it's turned back on again.  If debugging is off already then it does nothing.

## spacer

- Description

        Erik::spacer;
        Erik::spacer(3);

    Enter 1 or more new lines to help break up the output

## print\_file

- Description

        Erik::print_file($filename);

    Print out the content of the file.

# DEPENDENCIES

Data::Dumper - only if Erik::dump() is called

# AUTHOR

Erik Tank, tank@jundy.com

# COPYRIGHT AND LICENSE

Copyright (C) 2011 by Erik Tank

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
