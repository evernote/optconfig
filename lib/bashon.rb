#!ruby
# /* Copyright 2013 Proofpoint, Inc. All rights reserved.
#    Copyright 2014 Evernote Corp. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */

module BashOn
   def name_key(name)
      name.join('_').gsub(/[^a-zA-Z0-9\_]/, '_')
   end

   @@manpage = <<EOF
=head1 NAME

bashon - Serialization library for bash object notation

=head1 SYNOPSIS

   require 'bashon'

   puts var.to_bashon('var')

=head1 DESCRIPTION

This module enables you to serialize some ruby objects as "bashon" objects
("bashon meaning bash object notation"). Mostly, this means that bash code is
emitted that creates functions returning (echoing) the proper value.

The name that is passed to the B<to_bashon> method is the name of the function
that will output the serialized value. It also forms the root of a hierarchy of
function names that are used for serializing complex (array and hash) types.

The output is expected to be evaluated using the L<eval> command in bash.

=head2 Types

=head3 Nils

An unset command is emitted.

=head3 Booleans

A function is created with the specified name that can be used as a truth
test. That is, the function exits with a true value when serializing the
C<true> literal and with a false value when serializing the C<false>
literal. This enables you to use the resulting functions directly in
conditionals in bash.

=head3 Other simple types

A function is created with the specified name that outputs the value of the
type using B<to_s>.

=head3 Complex types

The important thing to note about complex types (hashes and arrays) is that
the values in the collection are always the I<names of functions> that, when
invoked, will yield a bashon-serialized value. This is especially important
to remember when the value of a hash entry or array element is itself a
complex type.

=head4 Arrays

A function is created with the specified name that outputs a space-separated,
ordered list of function names. Each function name is also created; when the
function is invoked, it will yield the value of that element.

head4 Hashes

A function is created with the specified name that outputs a space-separated
list of hash keys. When the same function is invoked with a hash key as an
argument, it outputs the name of a function. That function, when invoked,
will yield the value of that element.

=head1 EXAMPLES

In the following example, each example is shown with three blocks: the ruby
code snippet emitting the serialization, its standard output, and a shell
session in which the resulting code has been eval'd

This shows how a boolean value is serialized:

   puts true.to_bashon('var')

   function var { return 0; }

   $ if var; then echo got it; fi
   got it

This shows how a nil value is serialized:

   puts nil.to_bashon('var')

   unset var

   $ if [ -z "$(var)" ]; then echo No var; fi
   No var

This shows how a string is serialized and used:

   puts "catalog data".to_bashon('var')

   function var { echo catalog data; }

   $ string=$(var)
   $ echo $string
   catalago data

This shows how an array of strings is serialized:

   puts ["file1", "file2", "file3"].to_bashon('var')

   function var { echo var_0 var_1 var_2; } ; function var_0 { echo file1; };function var_1 { echo file2; };function var_2 { echo file3; }

   $ for filefun in $(var); do file=$($filefun); touch $file; done; ls file*
   file1   file2   file3

And a hash of strings:

   var = { "log" => "logfile.txt",
           "err" => "errfile.txt",
           "input" => "data.txt" }
   puts var.to_bashon('var')

   function var { case "$1" in log) echo var_log;; err) echo var_err;; input) echo var_input;; '') echo log err input;; esac; }; function var_log { echo logfile.txt; };function var_err { echo errfile.txt; };function var_input { echo data.txt; }

   $ for key in $(var); do valfun=$(var $key); val=$($valfun); echo $key=$val; done
   log=logfile.txt
   err=errfile.txt
   input=data.txt
   $ echo "Error message" >>$($(var err))

This shows how to deal with a heterogeneous array:

   var = ['one', { 'type' => 'number', 'value' => 2 }, false]
   puts var.to_bashon('var')

function var { echo var_0 var_1 var_2; } ; function var_0 { echo one; };function var_1 { case "$1" in value) echo var_1_value;; type) echo var_1_type;; '') echo value type;; esac; }; function var_1_value { echo 2; };function var_1_type { echo number; };function var_2 { return 1; }

   $ for elfun $(var)
   > do
   >    $elfun

A deeply nested hash:

   cfg = { "prod" => { "db" => { "host" => "dbhost001",
                                 "port" => 3389 },
                       "url" => "https://api/",
                       "log" => { "file" => "/var/log/app.log",
                                  "debug" => false },
                       "notify" => [ "www", "ops" ] },
           "qa" => { "db" => { "host" => "qa02",
                               "port" => 18009 },
                     "url" => "https://qa02:18008/v2/",
                     "log" => { "file" => "~qa/build9/log/app.log",
                                "debug" => true },
                     "notify" => [ "build", "test" ] }
          }
   puts cfg.to_bashon('cfg')

function cfg { case "$1" in prod) echo cfg_prod;; qa) echo cfg_qa;; '') echo prod qa;; esac; }; function cfg_prod { case "$1" in notify) echo cfg_prod_notify;; log) echo cfg_prod_log;; url) echo cfg_prod_url;; db) echo cfg_prod_db;; '') echo notify log url db;; esac; }; function cfg_prod_notify { echo cfg_prod_notify_0 cfg_prod_notify_1; } ; function cfg_prod_notify_0 { echo www; };function cfg_prod_notify_1 { echo ops; };function cfg_prod_log { case "$1" in debug) echo cfg_prod_log_debug;; file) echo cfg_prod_log_file;; '') echo debug file;; esac; }; function cfg_prod_log_debug { return 1; };function cfg_prod_log_file { echo /var/log/app.log; };function cfg_prod_url { echo https://api/; };function cfg_prod_db { case "$1" in port) echo cfg_prod_db_port;; host) echo cfg_prod_db_host;; '') echo port host;; esac; }; function cfg_prod_db_port { echo 3389; };function cfg_prod_db_host { echo dbhost001; };function cfg_qa { case "$1" in notify) echo cfg_qa_notify;; log) echo cfg_qa_log;; url) echo cfg_qa_url;; db) echo cfg_qa_db;; '') echo notify log url db;; esac; }; function cfg_qa_notify { echo cfg_qa_notify_0 cfg_qa_notify_1; } ; function cfg_qa_notify_0 { echo build; };function cfg_qa_notify_1 { echo test; };function cfg_qa_log { case "$1" in debug) echo cfg_qa_log_debug;; file) echo cfg_qa_log_file;; '') echo debug file;; esac; }; function cfg_qa_log_debug { return 0; };function cfg_qa_log_file { echo ~qa/build9/log/app.log; };function cfg_qa_url { echo https://qa02:18008/v2/; };function cfg_qa_db { case "$1" in port) echo cfg_qa_db_port;; host) echo cfg_qa_db_host;; '') echo port host;; esac; }; function cfg_qa_db_port { echo 18009; };function cfg_qa_db_host { echo qa02; }

   $ env=prod
   $ curl $($(cfg $env) url)/report.sql | \
   > mysql -h $($($(cfg $env) db) host) -p $($($(cfg $env) db) port) | \
   > tee -a $($($(cfg $env) log) file) | \
   > mailx -s "Report" `for m in $($($(cfg $env) notify)); do echo $($m); done`
   $ $($($(cfg $env) log) debug) && echo `date` `whoami`>>$($($(cfg $env) log) file)

=head1 BUGS

Right now string serialization makes no attempt to quote strings. If the
string contains a shell metacharacter, results can be unexpected. In fact,
results can be a bit unexpected anyway. I've tried different quoting schemes
and they all get real ugly real fast. In fact, things can be unexpected with
just a run of spaces or a newline.

You can't have a space in hash keys, but there's no helpful error message
until you eval the result. The problem is that it's really hard to return a
list of things that is useful for a 'for' loop where the list of things might
contain a space.

There's no good way of determining the "type" of something you encounter. You
can test the output of a function, and if each of the words in it is itself a
function, it's an array. However, if they're not, there's no way to
distinguish between a string that has multiple words and a list of hash keys.

Possibly arrays should work exactly like hashes, returning a list of indexes
instead of keys. Right now you can't access an array by index at all.

=head1 NOTES

Why not use variables instead of functions? I went down that road, but the
problem is that even bash 4, with its associative arrays, doesn't provide
enough flexibility to do nested structures, and you run into all kinds of
quoting difficulties and whatnot when you try to serialize to variables.

For example, you can serialize an array of strings in bash like this:

   declare -a var
   var=([0]=one [1]=two [2]=three)

But what if the values in the array are themselves arrays? Or associative
arrays? Bash can't handle that. Also, all your quoting has to be right in
order for that assignment to work, which is really difficult to get right
in a general solution with the possibility of arbitrarily nested structures.

Also, I'll note that arrays and associative arrays aren't really that
convenient in bash. I'm not sure that $(var key1) is really any harder to use
or read than ${var[key1]}.

So, I went with functions, and for consistency's sake serialized everything as
functions. That way you always know that when you get something back from
fetching a hash entry, you have to call it, there's no ambiguity about whether
it's a raw value or a hash.

There's another approach to this, which is to serialize everything into some
kind of text structure and then provide bash functions/commands to operate on
this blob of text. For example:

   puts var.to_json

   var='{"key1":"val1","key2":["val2one","val2two"],"key3":{"subkey1":1,"subkey2":2}}'

   $ json_get "$var" key1
   val1
   $ json_get "$var" key2
   ["val2one","val2two"]
   $ json_get "$var" key2 0
   val2one
   $ json_get "$var" key3
   {"subkey1":1,"subkey2":2}
   $ json_keys "$var"
   key1
   key2
   key3
   $ json_keys "$var" key3
   subkey1
   subkey2
   $ json_keys "$var" key3 subkey2
   2

This is viable but I think it's less convenient to use from bash.

=head1 AUTHOR

Jeremy Brinkley, E<lt>jbrinkley@evernote.comE<gt>

=cut
EOF
end

class Object
   include BashOn
   def to_bashon(*name)
      if name.empty?
         "#{self.to_s}"
      else
         "function #{name_key(name)} { echo #{self.to_bashon()}; }"
      end
   end
end

class TrueClass
   include BashOn
   def to_bashon(*name)
      if name.empty?
         "true"
      else
         "function #{name_key(name)} { return 0; }"
      end
   end
end

class FalseClass
   include BashOn
   def to_bashon(*name)
      if name.empty?
         "false"
      else
         "function #{name_key(name)} { return 1; }"
      end
   end
end

class NilClass
   include BashOn
   def to_bashon(*name)
      if name.empty?
         ""
      else
         "unset #{name_key(name)}"
      end
   end
end

class String
   include BashOn

   def bq
      self.gsub("'", "'\''")
   end

   def to_bashon(*name)
      if name.empty?
         self
      else
         "function #{name_key(name)} { echo '#{self.to_bashon.bq}'; }"
      end
   end
end

# Enumerable?
class Array
   include BashOn
   def to_bashon(*name)
      "function #{name_key(name)} { echo " +
         (0 .. (self.nitems-1)).map { |i|
         name_key(name + [i.to_s]) }.join(' ') + "; } " +
         (self.empty? ? ' ' : '; ') +
         (0 .. (self.nitems-1)).map { |i|
         self[i].to_bashon(*(name + [i.to_s])) }.join(';')
   end
end

class Hash
   include BashOn
   def to_bashon(*name)
      "function #{name_key(name)} { case \"$1\" in " +
         self.map { |k, v| "#{k}) echo '#{name_key(name + [k])}';;" }.join(' ') +
         " '') echo '#{self.keys.join(' ')}';;" +
         " esac; }" + (self.empty? ? ' ' : '; ') +
         self.map { |k, v| self[k].to_bashon(*(name + [k])) }.join(';')
   end
end
