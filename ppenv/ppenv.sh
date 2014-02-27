#!sh
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


# This script should be portable, that is, not use bash-only features. I'm
# not sure I've actually done that but it works in ksh, too, at least.

# Well-known path
WKP=/usr/local

make_ppenv_path()
{
   any=0
   before=1
   first_part=
   after_part=
   
   oifs="$IFS"
   IFS=:
   export IFS
   set $PATH
   IFS="$oifs"
   export IFS
   for pc
   do
      if [ "$pc" = "$WKP" -a $any -eq 0 ]
      then
      # We just skip the very first occurrence of
      # $WKP, because every script prepends it to PATH
      # and we can't use it as a landmark to find where the
      # "before" and "after" parts of PATH are
         any=1
      elif [ "$pc" = "$WKP" ]
      then
      # We're switching from the before part to the after part.
      # We still want to get rid of $WKP in the path, though, because
      # we only put in in PATH to find this.
         before=0
      elif [ "$pc" = "$WKP"/bin -o "$pc" = "$WKP"/sbin ]
      then
      # We actually want to get rid of these for two reasons: to ensure
      # their correct placement between the "after part" and "before part"
      # and to make sure ppenv.sh doesn't fill the PATH with duplicate
      # entries
         continue
      elif [ $before -eq 1 ]
      then
      # We're in the "before" part of the PATH, so path components
      # get put on the first_part
         if [ -z "$first_part" ]
         then
            first_part="$pc"
         else
            first_part="$first_part":"$pc"
         fi
      else
      # Put it on the after part
         if [ -z "$after_part" ]
         then
            after_part="$pc"
         else
            after_part="$after_part":"$pc"
         fi
      fi
   done
   
   if [ -z "$after_part" ]
   then
   # If we have no after part, it means no part of the PATH was after
   # an entry for the WKP--that means the whole path is an after part
   # and no path components should come before our standard locations
      after_part="$first_part"
      first_part=
   fi
   
   if [ -z "$first_part" ]
   then
      PATH="$WKP"/bin:"$WKP"/sbin:"$after_part"
   else
      PATH="$first_part":"$WKP"/bin:"$WKP"/sbin:"$after_part"
   fi

   #echo dbg $PATH >&2
   echo $PATH
}

PATH=`make_ppenv_path`
export PATH
   
MANPATH="$WKP"/man:"$WKP"/share/man:"${MANPATH:-}"
export MANPATH
   
# Please please please build properly with LD_RUN_PATH
# and compiler options so that LD_LIBRARY_PATH is
# not required -jdb/20100610

# RUBYLIB and PERLLIB (and similar) should not be set in this script because
# that removes the ability of ppenv.pm and ppenv.rb to distinguish between
# "overridden" library locations and the standard "local" library locations
# -jdb/20100921
