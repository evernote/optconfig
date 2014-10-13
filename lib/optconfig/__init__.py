#!/usr/bin/env python
# /* Copyright 2014 Evernote Corp. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */

"""
NAME
====

Optconfig - Configure and parse command-line options

DESCRIPTION
===========

The Optconfig class implements the interface for standardized command-line
option parsing and JSON-based configuration file interpretation. See the
reference documentation in the Optconfig master distribution for details.

"""

################################################################################
import sys
import os
import json
import types
import re
import getopt

from .version import __version__

################################################################################
class Optconfig(dict):

    standard_opts = {
        'config=s': None,
        'debug+':   0,
        'verbose+': 0,
        'version':  False,
        'help':    False,
        'dry-run!': False
    }

    ################################################################################
    def croak(self, msg, err = ""):
        if len(err) > 0:
            print "%s: %s" % (msg, err)
        else:
            print msg
        sys.exit(1)

    ################################################################################
    def _add_standard_opts(self, optspec):
        for i in self.standard_opts:
            if i not in optspec:
                optspec[i] = self.standard_opts[i]
        return optspec

    ################################################################################
    def __init__(self, domain, submitted_optspec, version=None):
        self['_domain'] = domain
        self['_optspec'] = self._add_standard_opts(submitted_optspec)
        self['_version'] = version or 'Unknown version'

        cmdlineopt = {}
        defval = {}
        proto = { }
        optspecs = []
        getopt_arg = []

        for optspec in submitted_optspec:
            val = submitted_optspec[optspec]
            optspecs.append(optspec)
            opt, optproto = re.match('^([a-z0-9][^=+\!]*)([=+\!].*|)', optspec).groups()
            self[opt] = val
            proto[opt] = {
                'proto': optproto
            }
            if optproto.startswith('='):
                getopt_arg.append(opt + '=')
                proto[opt]['arg'] = True
            elif optproto == '!':
                getopt_arg.append(opt)
                getopt_arg.append('no' + opt)
                proto['no' + opt] = {
                    'collect': 'set',
                    'type': lambda s: None,
                    'value':   (opt, False)
                }
            else:
                getopt_arg.append(opt)

            if optproto.endswith('@'):
                proto[opt]['collect'] = 'array'
            elif optproto.endswith('%'):
                proto[opt]['collect'] = 'object'
            elif optproto.startswith('+'):
                proto[opt]['collect'] = 'count'
            else:
                proto[opt]['collect'] = False

            if 'i' in optproto:
                proto[opt]['type'] = lambda s: int(s)
            elif 'f' in optproto:
                proto[opt]['type'] = lambda s: float(s)
            elif '%' in optproto:
                proto[opt]['type'] = lambda s: s.split('=', 1)
            elif 's' in optproto:
                proto[opt]['type'] = lambda s: s
            else:
                proto[opt]['type'] = lambda s: True

            
        # So.. we need to read files first, then override from cmdline
        # TODO
        #GetOptions($cmdlineopt, @optspecs);
        #print "optspecs: %s" % (optspecs)
        #print "getopt_arg: %s" % (getopt_arg)

        cmdline_parsed = {}

        cmdlineopt, args = getopt.getopt(sys.argv[1:], "", getopt_arg)

        for (givenopt, optarg) in cmdlineopt:
            opt = givenopt[2:]
            collect = proto[opt]['collect']
            value = proto[opt]['type'](optarg)
            self.ocdbg("encountered opt '%s'/%s with value: %s" % (opt, collect, repr(value)))
            if collect == 'count':
                if opt not in cmdline_parsed or not cmdline_parsed[opt]:
                    cmdline_parsed[opt] = 0
                cmdline_parsed[opt] += 1
            elif collect == 'array':
                if opt not in cmdline_parsed or not cmdline_parsed[opt]:
                    cmdline_parsed[opt] = [ ]
                cmdline_parsed[opt].append(value)
            elif collect == 'object':
                if opt not in cmdline_parsed or not cmdline_parsed[opt]:
                    cmdline_parsed[opt] = { }
                cmdline_parsed[opt][value[0]] = value[1]
            elif collect == 'set':
                (newopt, newoptarg) = proto[opt]['value']
                cmdline_parsed[newopt] = newoptarg
            else:
                cmdline_parsed[opt] = value

        # First, load global file, then load $HOME file
        cfgfilepath = [ os.path.join('/usr/local/etc', domain + '.conf'),
                        os.path.join('/etc', domain + '.conf') ]
        if "HOME" in os.environ:
            cfgfilepath.insert(0, os.path.join(os.environ['HOME'], '.' + domain))

        self['config'] = False
        gotconfig = False;

        for file in cfgfilepath:
            # self['config'] = file -- ?
            rval = self._read_config(file, False)
            if gotconfig == False:
                gotconfig = rval

        # now overwrite defaults with command line config file..
        if "config" in cmdline_parsed:
            cmdlinefile_config = self._read_config(cmdline_parsed['config'], True)

        # now merge/override command line stuff
        for opt in cmdline_parsed:
            self._merge_cmdlineopt(opt, cmdline_parsed[opt])

        # TODO - not really necessary but.. might be nice
        #self.ocdbg(self['optconfig']));

        if self['version']:
            print self['_version']
            sys.exit(0)

        if self['help']:
            binfile = os.path.abspath(sys.argv[0])
            help_pattern = re.compile(
                '(?:^=head1 +SYNOPSIS|^SYNOPSIS *\r?\n[=\-\~\^]+)(.*?)(?:^=head1 +|^[A-Z]+\r?\n[=\-\~\^]+$)',
                re.MULTILINE | re.DOTALL)
            with open(binfile, 'r') as f:
                match = help_pattern.search(f.read())
                if match is None:
                    print "No help"
                else:
                    print match.group(1).replace('.. ::', '').strip()
            sys.exit(0)

    ################################################################################
    def _merge_cmdlineopt(self, opt, val):
    # This logic is based on the value of the existing (configured) option value
    # but it should be based on the type of the optspec. -jdb/20100812

        #self.ocdbg("->merge_cmdlineopt('$opt', " . _val($val));

        if opt in self:
            if type(self[opt]) == types.DictType or type(self[opt]) == types.ListType:
                if type(self[opt]) == types.DictType:
                    if type(val) == types.DictType:
                        # Merge, at least one-level
                        for i in val:
                            self[opt][i] = val[i]
                    else:
                        # The value given is a simple scalar value, all I can
                        # do is blow away the hash. Also, same consideration as
                        # below with the configured array value and the passed-in
                        # non-array value. -jdb/20100812
                        self[opt] = val
                elif type(self[opt]) == types.ListType:
                    if type(val) == types.ListType:
                        # The command-line values get put in *front* of the configured
                        # values.
                        self[opt] = val + self[opt]
                    else:
                        # This happens when the type of the optspec is NOT ...@, but
                        # the configuration file has a list value for this option.
                        # It shouldn't really happen. In this circumstance the right
                        # thing to do is follow the optspec instead of the configuration
                        # because the optspec is under the control of the programmer (so
                        # the program will actually expect the option value to match it)
                        # while the configuration comes from heck-know-where (and we
                        # should probably complain if it doesn't match the optspec
                        # anyway). -jdb/20100812
                        self[opt] = val
                else:
                    # It's a reference, but not a hash or array reference. Whuh?
                    # Blast it away.
                    self[opt] = val
            # else, not dict or list.. just overwrite it
            else:
                # Scalar value: override
                self[opt] = val
        else:
            # Not configured: normal set value
            self[opt] = val;

        return self[opt]

    ################################################################################
    # TODO: read_config should be cognizant of the option types, in particular
    # things like =s@.
    def _read_config(self, file, death):
        #print "reading config file %s" % (file)
        try:
            f = open(file, "r")
        except IOError as e:
            if death:
                self.croak(file, e[1])
            else:
                return False

        text = "\n".join(f.readlines())
        f.close()
        obj = self._from_json(text)
        for i in obj:
            self[i] = obj[i]
        return obj

    ################################################################################
    def _from_json(self, str):
        return json.loads(str)

    ################################################################################
    def _to_json(self, obj):
        return json.dumps(obj)

    ################################################################################
    def dict(self):
        return dict((k, v) for k, v in self.items() if not k.startswith('_'))

    ################################################################################
    def vrb(self, level, msg):
        if level <= int(self['verbose']):
            print "\n".join(msg)

    ################################################################################
    def dbg(self, level, msg):
        if level <= int(self['debug']):
            dbgstr = "\nDBG(%s)" % (self._domain)
            print "%s: %s" % (dbgstr, dbgstr.join(msg))

    ################################################################################
    def ocdbg(self, *arg):
    # This debugging is controlled by an environment variable, because
    # it's really orthogonal to the use of a 'debug' option in the constructor
    # or something like that. -jdb/20100812
        if "OPTCONFIG_DEBUG" in os.environ:
            print "\nDBG(Optconfig): ".join(arg)

    ################################################################################
    # end Optconfig class

class optconfig(Optconfig):
    pass
