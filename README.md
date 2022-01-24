# Name

Erik - Erik's debugging buddy

# Description

Quick methods for debugging Perl.

Why use my name???  I found the I've never used my name as a variable; therefore I could create safe guards to make sure the 'Erik::' never makes it into production.  It should go without saying that debugging code (thus the Erik 'module') should never be found in production.

Erik has been designed to only require Perl.  However, if you use the 'dump' subroutine or specify 'logger' in the require statement supporting modules are loaded.

## Caveat Emptor

Erik was originally developed to troubleshoot a CGI script; hence the text|html flag. It attempts to guess if you are in browser and behave accordingly.  It's been a long time since I've used Erik in this manner. If you're trying to use it in browser and it no longer works please let me know.

# Usage

    use Erik qw(off html);

    Erik::dump('name', $ref_to_dump); # uses Data::Dumper;

    Erik::log();          # output: file_name [line_num]
    Erik::log('message'); # output: file_name [line_num]: message

    Erik::stack_trace(); # full blow stack trace telling you how you got there

    Erik::vars('name', $name); # just prints out that variable
    Erik::vars({ name1 => $name1, name2 => $name2 }); # print one line sep by tabs

    Erik::module_location(); # sometime you just need to know they are in the right place

    Erik::append("a");
    Erik::append("b");
    Erik::append("b");
    Erik::publish();  # output: a :: b :: b

    # compact output for loops
    Erik::min($_) for 1..100; # output: 1, 2, 3, 4, 5, ..., 100

    Erik::spacer(5); # add 5 lines of blank space - if you need some space

    Erik::print_file('file_name'); # if you need to see what is in the file right now

    sub some_method {
      Erik::method(); # output: file_name [line_num]: some_method
    }

# Require Flags

When requiring Erik several variables can be passed in.

Unless specified the default value is off/false.

- epoch

    pre-pend log lines with the epoch timestamp

- force\_html\_header

    Print an HTML style header as soon as possible.

    The header printed depends on what mode it is in:

    - text - Content-type: text/plain\\n\\n
    - html - Content-type: text/html\\n\\n

- disable\_header

    When Erik starts a new 'session' it will print a 'New Log' header.  This can be disabled by setting 'disable\_header' to true.

    NOTE: This has nothing to do with the 'force\_html\_header' flag.

- line

    print line/program info before all non 'log' outputs

- log

    print everything to a log file

    By default this is /tmp/erik.out.  The output can be configured using the 'log\_filename' setting.

    This will also force the mode into text.  Passing 'html' will not work - it'll be ignored.

- log\_filename

    name of the file that logs will be printed to

    This argument takes the form: log\_filename=/tmp/output\_file\_name

    Everything after the '=' will be used as the filename.  It is HIGHLY RECOMMENDED to ALWAYS use a full path.

    No guarantee is made for partial or relative paths!

- logger

    use Log::Log4perl to write all information as 'debug'

- on|off

    initial state of debugging output on/off - Default: on

- pid

    print Process ID to each line

- report

    print report when process is done

    Currently, this is just a summary of the methods that were called with a count.

    NOTE: only subroutine where Erik::method is called are included.

- stderr

    print everything to STDERR instead of STDOUT

- text|html

    the expected output format - Default: text

    If neither is provided then it will attempt to guess by checking %ENV for any keys starting with HTTP\_.

- time

    pre-pend log lines with a human readable timestamp

- time\_stats

    pre-pend log lines with timing stats: seconds since last log line - seconds since start of program

    This is not a replacement for benchmarking.  It is a simple way to try to find sections of the code that take a long time to execute.

# Environmental Variables

- ERIK\_OFF

    Same as passing 'off' when loading the module.  Found that sometimes it's easier
    to do this than find the right 'use Erik' and turn it off.  Also, enable/disable
    calls are honored.

- ERIK\_DISABLE

    Totally disables Erik's print method so nothing will show up.

# .erikrc

If .erikrc is found in your home directory ($ENV{HOME}/.erikrc, /etc/.erikrc).
The first one found will be loaded and those settings will be applied.

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

# METHODS

## append

- Description

        Erik::append("First piece of info");

    Adds information to an internal store that will get printed with the 'publish' method.

    Each piece of information will be seperate by 'publish\_seperator'.

## counter

- Description

        Erik::counter();
        Erik::counter('My Counter');

    Print out a counter that is incremented by one each time.

    If a name is provided then it will increment and print every time it sees that name.

    If no name is provided then a name will be constructed from the file name and line number.

    All counters start at 1.

## disable

- Description

        Erik::disable();
        Erik::disable('Module::Name::A', 'Module::Name::B');

    Turn off the debugger.

    If a list of modules name(s) is provided then only disable debugging in those. Calling it again without a list will disable debugging everywhere.

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

## dump\_setting

- Description

        Erik::dump_setting(Indent => 1);
        Erik::dump_setting(Pad => 'ERIK');

    Set any of the config/method variable that are available.

    See Data::Dumper man page.

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

## log

- Description

        Erik::log();
        Erik::log('message');

    Simply print a line with the following format:
    \*\*\* file\_name \[line\_num\]: message if provided \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

## method

- Description

        Erik::method();

    Simply print a line with the following format:
    \*\*\* file\_name \[line\_num\]: Subroutine\_Name \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

    also adds the method to the method report

## min

- Description

        Erik::min('message');

    A compact way of printing things out.  Ideally used in a loop so that you don't
    burn through the scrollback buffer.

## module\_location

- Description

        Erik::module_location();
        Erik::module_location('carp');
        Erik::module_location('ssl');

        Will print out all loaded modules (that match case-insensitive to the provided string) and the locations of their code.

## print\_file

- Description

        Erik::print_file($filename);

    Print out the content of the file.

## publish

- Description

        Erik::publish("Optional last message");

    Prints out everything that has been 'append'ed.

    It will then reset the internal store.

    Each piece of information will be seperate by 'publish\_seperator'.

## publish\_separator

- Description

        Erik::publish_separator("|");

    Set the separator that 'publish' will use when printing everything out.

    Default: ' :: ';

## single\_off

- Description

        Erik::single_off();

    Turns off debugging for the next command then it's turned back on again.  If debugging is off already then it does nothing.

## spacer

- Description

        Erik::spacer;
        Erik::spacer(3);

    Enter 1 or more new lines to help break up the output

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

## toggle

- Description

        Erik::toggle();

    Toggles the enable/disable state of the debugger.  If it's off nothing gets printed.

## vars

- Description

        Erik::vars('name', $name);
        Erik::vars(name => $name);
        Erik::vars(name1 => $name1, name2 => $name2);

    Print out the line number and then name/value seperated by ':' if more than one pair is given.

## yell

- Description

        Erik::yell('Some information to display');

    This will print the information between two lines of '\*\*\*\*\*'s.

# Alias Methods

There are many commands for Erik; these are their aliases.

Over time different method names have been used for the same command per user's requests.

There is no plan on deprecating them; feel free to use these as they suite your mood.

## info

- Description

        Erik::info();

        An alias for Erik::log(). See log documentation above.

## sanity

- Description

        Erik::sanity();

        An alias for Erik::log(). See log documentation above.

## subroutine

- Description

        Erik::subroutine();

        An alias for Erik::method(). See method documentation above.

## warn

- Description

        Erik::warn();

        An alias for Erik::log(). See log documentation above.

# Dependencies

Data::Dumper - only if Erik::dump() is called
Log::Log4perl - if 'logger' setting is provided during 'require'

# Author

Erik Tank, tank@jundy.com

# Copyright and License

Copyright (C) 2011 by Erik Tank

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
