  ##############################################################################
 #  Data::Deep/TEST  : key()
  ##############################################################################
;# Tests related to key in use with search and compare functions of Data::Deep
 ###############################################################################
 ### key.t
###
##
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { plan tests => 11};

use lib '.';
use lib 't';

require 'TEST.pl';
START_TEST_MODULE(__FILE__);

o_complex(0);

#############################################


  my $fs1={
	content =>{
		   dir1=>
		   {
		    content=> {
			       file1=>
			       {
				crc32=>4562,
				sz=>4
			       },
			       'test.doc'=> {
					     crc32=>8,
					     sz=>5
					    }
			      },
		    crc32=>123,
		    sz=>2
		   }
		  }
       };


  #############################################

  my $fs2 = eval Dumper( $fs1 );

  my $test_doc = $fs2->{content}{dir1}{content}{'test.doc'};

  delete $fs2->{content}{dir1}{content}{'test.doc'};

  $fs2->{content}{dir1}{content}{docs}=
      {
       crc32=>0,sz=>45,
       content=>{}
      };

  $fs2->{content}{dir1}{sz}=1;

  $fs2->{content}{'test.doc'} = $test_doc;

  #############################################


  my $crc_k = ['%','crc32'];
  my $sz_k = ['%','sz'];

  ok(testSearch("Search key SZ",  $fs1, $sz_k,  0, [4,5,2]));
  ok(testSearch("Search key CRC", $fs1, $crc_k, 0, [4562,8,123]));


  #############################################

  o_key({ CRC => {regexp=>['%','crc32','?='],
		  eval=>'{crc32}'
		 },
	  SZ  => {regexp=>['%','sz','?='],
		  eval=>'{sz}',
		 }
	});
  #############################################


  ok(testPathSearch("Search Complex key 1", $fs1,
		    ['/','CRC'], # you cannot put '=','value' because the ?= eat it!
		    #    ['/','CRC'], # you cannot put '=','value' because the ?= eat it!
		    [
		     ['%','content','%','dir1','%','content','%','test.doc','/','CRC'],
		     ['%','content','%','dir1','%','content','%','file1','/','CRC'],
		     ['%','content','%','dir1','/','CRC'],
		    ]));

  o_key({ A => {regexp=>['|','Data::Dumper','%','todump','@',0,'$','%','key'],
	      eval=>'[0]->{key}'
	     }
      });

  ok(testPathSearch("Search Complex key 2",
		    { toto1=> new Data::Dumper([\ {key=>'toto one'}]),
		      toto2=> new Data::Dumper([\ {key=>'toto two'}])
		    },
		    ['/','A','=',sub{/two/}], # you can put '=','value'
		    [['%','toto2','/','A','=','toto two']]));


  o_key({
	 CRC => {regexp=>$crc_k,
		 eval=>'{crc32}',
		 priority=>1
		},
	 SZ  => {regexp=>$sz_k,
		 eval=>'{sz}',
		 priority=>2
		},
	 '.'  => {regexp=>['%','content'],
		  eval=>'{content}',
		  priority=>3
		 }
	});

  ok(testPathSearch("Search Complex key 3",$fs1,
		    ['/','CRC','=',4562],
		    [['/','.','%','dir1','/','.','%','file1','/','CRC','=',4562]]));


  ok(testSearch("Search Complex key 4",
    $fs1,
    ['/','CRC','=',123],
    -2,
    [ $fs1->{'content'}{'dir1'} ]));

  ok(testSearch("Search Complex key 5",
		$fs1,
		['/','CRC','=',4562],
		-2,
		[ $fs1->{'content'}{'dir1'}{'content'}{'file1'} ]));



####
###
## compare dom with key
###
####
#
#
#
#
#############################################


  testCompare( "key compare",
	       {
		crc32=>20,sz=>45,
		content=>{op=>'ds'}
	       },
	       {
		crc32=>24,sz=>45,
		content=>{op=>'ds'}
	       },
	       [ 'change(/CRC,/CRC)=20/=>24' ]
	     );



  title('test to modify a returned node') and do {
    my @nodes = path($fs2,
		     [ search($fs2,['/','CRC','=',4562])
		     ],-2);	

    $nodes[0]->{sz}=46; # change size of the pointed file with CRC 4562
  };


  o_complex(1);

  # Power

  #warn Dumper($fs1).' Vs '.Dumper($fs2);

  testCompare( "key compare 2", $fs1 , $fs2,
	       [ 'add(/.%dir1/.,/.%dir1/.%docs)={"sz"=>45,"content"=>{},"crc32"=>0}',
		 'change(/.%dir1/SZ,/.%dir1/SZ)=2/=>1',
		 'change(/.%dir1/.%file1/SZ,/.%dir1/.%file1/SZ)=4/=>46',

		 'move(/.%dir1/.%test.doc,/.%test.doc)=',
		 'move(/.%dir1/.%test.doc/CRC,/.%test.doc/CRC)=',  # TODO : remove them (OPTIMIZATION at the end of compare)
		 'move(/.%dir1/.%test.doc/SZ,/.%test.doc/SZ)='   # TODO : remove them (OPTIMIZATION at the end of compare)
	       ],1);

#  Results remain :
        #remove(/.%dir1/.%test.doc,/.%dir1/.)={"sz"=>5,"crc32"=>8}
        #add(/.,/.%test.doc)={"sz"=>5,"crc32"=>8}


# key priority check

# key depth check



END_TEST_MODULE(__FILE__);
   ###########################################################################
1;#############################################################################
__END__ key.t
###########################################################################

