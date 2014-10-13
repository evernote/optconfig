#!python

import json
import os
import sys
import unittest

from optconfig import Optconfig
import optconfig.version

from expects import *

domain = 'test-example'
version = optconfig.version.__version__

class JSONSpec:

    # Python lacks a built-in flatten()
    @classmethod
    def get_specs(cls, dir=None):
        result = []
        dir = dir or os.path.join(os.path.dirname(__file__), '..', 'json_spec')
        for root, dirs, files in os.walk(dir):
            for file in files:
                result.append(JSONSpec(os.path.join(root, file)))

        return result

    def __init__(self, file):
        with open(file, 'r') as fh:
            data = json.load(fh)

        self.name        = os.path.basename(file)
        self.context     = os.path.basename(os.path.dirname(file))
        self.argv        = data[0]
        self.optspec     = data[1]
        self.expectation = data[2]
        self.fixture     = data[3] if len(data) > 3 else None

    def fix(self, domain):
        if self.fixture:
            filename = domain if '/' in domain else os.path.join(os.environ['HOME'], '.' + domain)
            with open(filename, 'r') as fh:
                json.dump(self.fixture, fh,
                          indent = 4,
                          separators = (',', ': '))

class JSONTestCase(unittest.TestCase):
    def __init__(self, json_spec):
        case_name = (json_spec.context or 'general') + '_' + json_spec.name.split('.')[0]
        setattr(self, case_name, self.runTest)
        super(JSONTestCase, self).__init__(case_name)
        self.json_spec = json_spec

    def runTest(self):
        global domain, version
        sys.argv = list(sys.argv[0:1]) + list(self.json_spec.argv)
        self.json_spec.fix(domain)
        opt = Optconfig(domain,
                            self.json_spec.optspec,
                            version)
        expect(opt.dict()).to(have_keys(self.json_spec.expectation))
