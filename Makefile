dist:
	perl Build.PL && ./Build dist
	python setup.py sdist

perl-dist:
	perl Build.PL && ./Build dist

python-dist:
	python

clean:
	rm -rf *.tar.gz META.* MANIFEST.SKIP.bak optconfig.egg-info dist build
