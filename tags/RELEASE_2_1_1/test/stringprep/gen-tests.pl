# --------------------------------------------------------------------------
#
# License
#
# The contents of this file are subject to the Jabber Open Source License
# Version 1.0 (the "License").  You may not copy or use this file, in either
# source code or executable form, except in compliance with the License.  You
# may obtain a copy of the License at http://www.jabber.com/license/ or at
# http://www.opensource.org/.  
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied.  See the License
# for the specific language governing rights and limitations under the
# License.
#
# Copyrights
# 
# Portions created by or assigned to Cursive Systems, Inc. are 
# Copyright (c) 2002 Cursive Systems, Inc.  All Rights Reserved.  Contact
# information for Cursive Systems, Inc. is available at http://www.cursive.net/.
#
# Portions Copyright (c) 2003 Joe Hildebrand.
# 
# Acknowledgements
# 
# Special thanks to the Jabber Open Source Contributors for their
# suggestions and support of Jabber.
# 
# --------------------------------------------------------------------------

use strict;

my $state = 0;
my $count = 1;
my $len = 0;
my $c;

open(OUT, ">TestDraft.cs") or die;
print OUT <<EOF;
/* This file is automatically generated.  DO NOT EDIT!
 * Instead, edit gen-tests.pl and re-run.
 */
#if !NO_STRINGPREP

using System;
using NUnit.Framework;
using stringprep;
using stringprep.steps;

namespace test.stringprep
{
    [TestFixture]
    public class TestDraft
    {
        private Profile nameprep = new Nameprep();

EOF

while (<>) {
  next if /^\s*\#/;

  if (/^4\. /) {
    $state = 1;
    next;
  }

  if ($state == 0) {
    next;
  } elsif ($state == 1) {
    if (/^(4\.[0-9]+ .+)/) {
      if ($count == 6) {
	print OUT "        \[Ignore(\"fails, due to lack of UTF-16 in .Net\")\]\n";
      }
      $c = sprintf("%02d", $count);
      print OUT <<EOF;
        // $1
        public void Test_4_$c()
        {
EOF
      print OUT "            string input = \"";
      $count++;
      $state = 2;
    }
  } elsif ($state == 2) {
    if (/^\s*input \(length ([0-9]+)\):/) {
      $state = 3;
      $len = $1;
    }
  } elsif ($state == 3) {
    if (/^\s*$/) {
      $state = 4;
      print OUT "\";\n";
      print OUT "            string expected = \"";
    }
    else {
      split /\s+/;
      foreach my $char (@_) {
		if ($char =~ s/^U\+//) {
		  if (length($char) > 4) {
			my $h = hex($char);
			printf OUT "\\x%04x\\x%04x", 0xD7C0 + ($h >> 10), 0xDC00 | ($h & 0x3FF);
		  } else {
			print OUT "\\x$char";
		  }
		}
      }
    }
  } elsif ($state == 4) {
    if (/^\s*output \(length ([0-9]+)\):/) {
      $state = 5;
      $len = $1;
    } elsif(/prohibits string/i) {
      print OUT "\";\n";
      print OUT <<EOF;
            try
            {
                expected = nameprep.Prepare(input);
                Assertion.Assert("Expected ProhibitedCharacterException", false);
            }
            catch (ProhibitedCharacterException)
            {
            }
            catch (AssertionException)
            {
                throw;
            }
            catch (Exception e)
            {
               Assertion.Assert("Expected ProhibitedCharacterException, got " + e.GetType().ToString(), false);
            }
        }

EOF
      $state = 1;
    } elsif(/contains both l and ral/i) {
      print OUT "\";\n";
      print OUT <<EOF;
            try
            {
                expected = nameprep.Prepare(input);
                Assertion.Assert("Expected BidiException", false);
            }
            catch (BidiException)
            {
            }
            catch (AssertionException)
            {
                throw;
            }
            catch (Exception e)
            {
               Assertion.Assert("Expected BidiException, got " + e.GetType().ToString(), false);
            }
        }

EOF
      $state = 1;
    } elsif(/bidi string does not start\/end with ral characters/i) {
      print OUT "\";\n";
      print OUT <<EOF;
            try
            {
                expected = nameprep.Prepare(input);
                Assertion.Assert("Expected BidiException", false);
            }
            catch (BidiException)
            {
            }
            catch (AssertionException)
            {
                throw;
            }
            catch (Exception e)
            {
               Assertion.Assert("Expected BidiException, got " + e.GetType().ToString(), false);
            }
        }

EOF
      $state = 1;
    }
  } elsif ($state == 5) {
    if (/^\s*$/ or /^\s*out/) {
      $state = 1;
      print OUT "\";\n";
      print OUT <<EOF;
            Assertion.AssertEquals(expected, nameprep.Prepare(input));
        }
EOF
    } else {
      split /\s+/;
      foreach my $char (@_) {
	if ($char =~ s/^U\+//) {
	  print OUT "\\x$char";
	}
      }
    }
  }
}
#  print;


print OUT <<EOF;
    }
}
#endif
EOF
close OUT;
