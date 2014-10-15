import unittest
import os

from expects import *
import json_spec
from json_spec import JSONSpec

def load_tests(loader=None, standard_tests=None, pattern=None):
    test_cases = unittest.TestSuite()
    for jspec in JSONSpec.get_specs(os.path.join(os.path.dirname(__file__), '..', 'json_spec')):
        test_cases.addTest(json_spec.JSONTestCase(jspec))
    return test_cases
