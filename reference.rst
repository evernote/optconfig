Optconfig
=========

This package of libraries provides a standard way to read configuration
and parse command-line options in a standard, consistent way. It also
provides helpful functions for minor functionality that should work the
same way in a set of consistent programs.


Invoking an optconfig program
-----------------------------

.. ::

   program [options] arguments...
      --config=file    Use file for configuration
      --verbose        Produce verbose output
      --dry-run        Do a dry run (don't change things)
      --version        Print program version number
      --help           Print usage message
      --debug          Produce debugging output
      Some programs will have options specific to them

Description
-----------

The Optconfig module looks in various places for its configuration. It will
read configuration from *one* of ``$HOME/.domain``,
``/usr/local/etc/domain.conf`` and the configuration file (if any) specified
with the **--config** command-line option.

The whole configuration is read from the file (even if the option spec doesn't
contain those configuration items--see Bugs_), and values can be overridden by
command-line options specified in the option spec.

There is a standard set of options you can pass (or configure in a config
file) to Optconfig programs.

Standard Options
~~~~~~~~~~~~~~~~

* **--config=file**

Optconfig reads the configuration in the named file. The configuration file
format is JSON.  If it can't read this file, it complains. If no --config
option is specified, it will search for a configuration file in the standard
locations as listed above. If it finds a file, it reads it and sets config
values accordingly, then overrides or merges these values with the ones on
the command line.

Some options can be specified multiple times. For example, a --define option
might allow you to define more than one key; or a --host option might allow
you to define more than one host. If these options appear in the configuration
file and the command line, their values are added to by the command line value
For example, if you have a configuration file with the following contents::

   { "define": { "name": "bob", "home": "/home/bob" }
     "host": [ "wiki.ppops.net", "tickets.ppops.net" ] }

And you pass ``--define mail=bob@opsexample.com`` ``--host=mail.opsexample.net`` into
the command, the resulting configuration will be::

   { "define": { "mail": "bob@proofpoint.com", "name": "bob",
                 "home": "/home/bob" },
     "host": [ "mail.ppops.net", "wiki.ppops.net", "tickets.ppops.net" ] }

Note how the command-line value for ``--host`` is prepended to the list.

* **--verbose**

Produce verbose output. You can specify this a number of times indicating
increased verbosity.

* **--dry-run**

The command will print what it would have done, but won't change anything in
databases or on disk. Programs using Optconfig should test this whenever
doing something "destructive".

* **--version**

Print the program version. (In some languages, the Optconfig library prints
the value of the ``$VERSION`` global variable)

* **--help**

Print a help message. (In some languages, the Optconfig library searches the
file being executed for a man-like **SYNOPSIS** section and prints it).

* **--debug**

Producing debugging output. You can specify this a number of times indicating
increased debugging output volume.

It's strongly encouraged that when libraries are using a configuration hash
that may come from Optconfig, they produce debugging output when the option
is 2 or greater. This allows the user to see debugging output from the command
when specifying ``--debug`` and from its libraries when specifying
``--debug --debug``.

Option Spec
-----------

In each language's library, Optconfig receives a *domain* which tells it the
names of configuration file locations to look in, and a hash table or similar
data structure called an *optspec*, in which the keys are option specifiers
and the values are default values. The option specifiers are similar to other
command-line parsers like Perl's Getopt::Long.

================ ============= ===================================================
Option Specifier Type of Value Description
================ ============= ===================================================
opt              boolean
opt+             integer       The number of times the option is specified in
                               command-line arguments (can be passed multiple
                               times)
opt=i            integer       The number specified as the option argument, as an
                               integer
opt=f            float         The number specified as the option argument, as a
                               floating point number
opt=s            string        The option argument, as a string
opt=x@           array         Array of option arguments, interpreted as above
                               (i means integers, f means floats, s means strings)
                               (can be specified multiple times)
opt=x%           hash          The option argument(s) are interpreted as hash
                               assignments, with the key separated from the value
                               by an equals sign (``=``) (can be specified
                               multiple times)
================ ============= ===================================================

Roadmap/Problems
----------------

When consulting a configuration file, Optconfig should check the options for
adherence to the optspec, and it doesn't. This could result in unclear
failures in the program where the wrong type is configured (for example,
a scalar for a list).

The languages use "native" command-line parsing libraries and aren't consistent
with how strict they are or how they fail.

There's no easy way to "empty out" an already-configured list or map value
from the configuration. In the example above, there's no combination of
command-line options that would result in a one-element list for the 'host'
option.

In general, there's no way to specify deep hash access.

When Optconfig is merging the command-line options into the configuration,
it is affected by the type of the existing option value (from the configuration
file) whereas it should honor only the optspec.

The next version of Optconfig will provide a new option specifier, ``%%``,
meaning a potentially deep hash. Deep hash keys will be specified on the command
line using JSON path (e.g. ``logging.value=DEBUG``).
