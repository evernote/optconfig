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

      # tests_require = ['mamba', 'expects'],
      # test_loader   = 'mamba:Loader',

      zip_safe      = False)
