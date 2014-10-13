NAME=optconfig

dist: perl-dist python-dist ruby-dist

perl-dist:
	perl Build.PL && ./Build dist

python-dist:
	python setup.py sdist && cp dist/$(NAME)-$(shell python -c 'exec(open("lib/optconfig/version.py").read()); print __version__').tar.gz .

ruby-dist:
	rake build && cp pkg/optconfig-$(shell ruby -Ilib -roptconfig/version -e 'puts Optconfig::VERSION').gem .

clean:
	find . -name \*.pyc -exec rm {} \;
	rm -rf *.tar.gz MYMETA.* META.* MANIFEST.SKIP.bak optconfig.egg-info dist build blib _build pkg doc lib/optconfig.egg-info *.gem
