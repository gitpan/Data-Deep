
  ##############################################################################
 #  Data::Deep/TEST  : travel
  ##############################################################################
;# Tests related to the travel function of Data::Deep
 ###############################################################################
 ### travel.t
###
##
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { plan tests => 2};
require 'TEST.pl';
START_TEST_MODULE(__FILE__);

o_complex(0);

#############################################################################
#o_debug(1);

ok(testTravel(" 0 travellig through ",
	      [\{a=>3,b=>sub{return 'test'}}],
   [
    '0 > @0 : ARRAY',
    '1 > @0$ : REF',
    '2 > @0$%a : HASH',
    '3 > @0$%a=3 : ',
    '2 > @0$%b : HASH',
    '3 > @0$%b& : CODE'
   ]));


ok(testTravel(" 0 travellig through ",
	      [\{a=>3,b=>sub{return 'test'}}],
   [
    '0 > @0 : ARRAY',
    '1 > @0$ : REF',
    '2 > @0$%a : HASH',
    '3 > @0$%a=3 : ',
    '2 > @0$%b : HASH',
    '3 > @0$%b& : CODE'
   ]));

END_TEST_MODULE(__FILE__);
   ###########################################################################
1;#############################################################################
__END__ travel.t
###########################################################################
