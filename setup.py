#!python

from setuptools import setup

# Set __version__
exec(open('lib/optconfig/version.py').read())

setup(name          = 'optconfig',
      version       = __version__,

      description   = 'Parse command-line arguments and configuration files consistently',
      url           = 'http://github.com/evernote/optconfig',
      author        = 'Eric Robbins',
      author_email  = 'erobbins@evernote.com',
      license       = 'Apache-2',

      package_dir   = { '': 'lib' },
      packages      = ['optconfig'],
      scripts       = ['bin/python-showconfig'],

      test_suite    = 'tests',
      test_loader   = 'unittest:TestLoader',

      zip_safe      = False)
