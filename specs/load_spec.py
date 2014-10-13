#!/usr/bin/env python

import sys
from expects import *

from optconfig import Optconfig
from optconfig.version import __version__ as __version__

domain = 'test-example'

with description('optconfig'):

    with it('constructs a new object'):
        opt = Optconfig(domain, { }, __version__)
        expect(opt).to(be_a(Optconfig))

