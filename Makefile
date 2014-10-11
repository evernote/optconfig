dist:
	perl Build.PL && ./Build dist
	python setup.py sdist

perl-dist:
	perl Build.PL && ./Build dist

python-dist:
	python

clean:
	find . -name \*.pyc -exec rm {} \;
	rm -rf *.tar.gz META.* MANIFEST.SKIP.bak optconfig.egg-info dist build pkg
