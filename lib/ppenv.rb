#!ruby
# /* Copyright 2013 Proofpoint, Inc. All rights reserved.
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


require 'rbconfig'

rubylib = [ ]
saved_rubylib = [ ]
if $LOAD_PATH[0] == "/usr/local"
   $LOAD_PATH.shift
end
if ENV.has_key? 'RUBYLIB' and ! ENV['RUBYLIB'].empty?
   rubylib = ENV['RUBYLIB'].split(':')
   while rubylib[0] == $LOAD_PATH[0]
      saved_rubylib.push(rubylib.shift)
      $LOAD_PATH.shift
   end
end

$LOAD_PATH.unshift("/usr/local/lib/ruby/#{RbConfig::CONFIG['ruby_version']}/#{RbConfig::CONFIG['sitearch']}")
$LOAD_PATH.unshift("/usr/local/lib/ruby/#{RbConfig::CONFIG['ruby_version']}")
$LOAD_PATH.unshift('/usr/local/lib/ruby')
$LOAD_PATH.unshift('/usr/local/lib')

if ! saved_rubylib.empty?
   $LOAD_PATH.unshift(*saved_rubylib)
end
