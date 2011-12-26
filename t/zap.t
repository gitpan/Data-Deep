  ##############################################################################
 #  Data::Deep/TEST  : zap() function
  ##############################################################################
;# Tests related to key in use with search and compare functions of Data::Deep
 ###############################################################################
 ### zap.t
###
##
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { plan tests => 1};

use lib '.';
use lib 't';

require 'TEST.pl';
START_TEST_MODULE(__FILE__);

o_complex(0);
ok(1);

#############################################################################

# test le zap avec tous les types 
# mettre ici le test de boucle



END_TEST_MODULE(__FILE__);
