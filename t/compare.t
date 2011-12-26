  ##############################################################################
 #  Data::Deep/TEST  : Compare / ApplyPath
  ##############################################################################
;# Tests related to the compare function of Data::Deep
 ###############################################################################
 ### compare.t
###
##
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'


use strict;
use Test;
BEGIN { plan tests =>62};

use lib '.';
use lib 't';

require 'TEST.pl';
START_TEST_MODULE(__FILE__);


o_complex(0);


#############################################################################
my $cplx;

foreach $cplx (0..1) {

  bug("\n\n                  >>>>>>>>   ".($cplx
					   &&
					   "TESTING WITH COMPLEX ANALYSIS"
					   ||
					   "TESTING WITH SIMPLE ANALYSIS"
					  )
      . "   <<<<<<<<<<\n\n"
     );

  o_complex($cplx);

  ok(testCompare( "undef compare", undef , undef, [],1));
  ok(testCompare( "undef compare 2", undef , 1, ['change(,)=undef/=>1'],1));
  ok(testCompare( "undef compare 2", 1 , undef, ['change(,)=1/=>undef'],1));

  #############################################################################
  ok(testCompare( "Equality", 'toto\'23_=\n=$jkl' , 'toto\'23_=\n=$jkl', [] ));
  #############################################################################
  ok(testCompare( "scalar" , "abc123\'=\n,\$\"{}[]()" , "tit\'i",
		  [ 'change(,)="abc123\'=\n,\$\"{}[]()"/=>"tit\'i"'
		  ] ));

  ok(testCompare( "Scalar 1", [123], "jklj",
		  [ 'change(,)=[123]/=>"jklj"'] ));

  ok(testCompare( "Scalar 2", 1, [5],
		  [ 'change(,)=1/=>[5]' ] ));

  ok(testCompare( "Scalar 3", \ { a=>2 }, \ [5],
		  [ 'change($,$)={"a"=>2}/=>[5]' ], 1 ));

  #############################################################################
  my $a1= [1,2,3,'x'];
  my $a2= [1,2];

  ok(testCompare( "Array", $a1,$a2,
		  [
		   'remove(@2,)=3',
		   'remove(@3,)="x"'
		  ]
		));

  #############################################################################
  ok(testCompare( "Array 2", $a2,$a1,
		  [ 'add(,@3)="x"',
		    'add(,@2)=3'
		  ]
		));

  #############################################################################
  $a1= ["a","b","c"];
  $a2= ["c","a","d","b"];

  ok(testCompare( "Array 3", $a1,$a2,
		  (($cplx)?
		   [ 'add(,@2)="d"',
		     'move(@0,@1)=',
		     'move(@1,@3)=',
		     'move(@2,@0)=',
		   ]:['add(,@3)="b"',
		      'change(@0,@0)="a"/=>"c"',
		      'change(@1,@1)="b"/=>"a"',
		      'change(@2,@2)="c"/=>"d"',
		     ])));

  #############################################################################

  ($cplx) or #patch KO in cplx mode (TODO)
    ok(testCompare( "Array 4", $a2,$a1,
		    (($cplx)?[ 'move(@0,@2)=',
			       'move(@1,@0)=',
			       'remove(@2,)="d"',
			       'move(@3,@1)='
			     ]:[ 'change(@0,@0)="c"/=>"a"',
				 'change(@1,@1)="a"/=>"b"',
				 'change(@2,@2)="d"/=>"c"',
				 'remove(@3,)="b"'
			       ]),1));
  if ($cplx) {
    ($cplx) or #patch KO in cplx mode (TODO)
      ok(testCompare( "Array 5",
		      ['c','a','d','b'],
		      ['a',2,'b','c',1],
		      [ 'move(@0,@3)=',
			'move(@1,@0)=',
			'remove(@2,)="d"',
			'move(@3,@2)=',
			'add(,@1)=2',
			'add(,@4)=1'
		      ],1));
  }


  #############################################################################

  ok(testCompare( "Hash-table 1",
		  [2,{a=>5}],
		  [2,{a=>5,b=>[0]} ],
		  [ 'add(@1,@1%b)=[0]' ]
		));

  ok(testCompare( "Hash-table 2",
		  {a=>5,b=>3},
		  {a=>5},
		  [ 'remove(%b,)=3' ]
		));

  if ($cplx) {
    ok(testCompare( "Hash-table 3",
		    [1,{a=>5,b=>3}],
		    [1,{a=>5}],
		    [ 'remove(@1%b,@1)=3' ]
		  ));
  }

  #############################################################################
  ok(testCompare( "References",
		  [[3],\2],
		  [1,\2,[3]],
		  (($cplx)?[ 'move(@0,@2)=',
			     'add(,@0)=1'
			   ]:[
			      'change(@0,@0)=[3]/=>1',
			      'add(,@2)=[3]'
			     ])
		));

  #############################################################################
  ($cplx) or #patch KO in cplx mode (TODO)
    ok(testCompare( "References 2",
		    [[1], 2, [1], \ [], \ {}],
		    [{} , 2, \ [], \ {}],
		    [
		     'change(@0,@0)=[1]/=>{}',
		     (($cplx)?(
			       'remove(@2,)=[1]',
			       'move(@3,@2)=',
			       'move(@4,@3)='
			      ):(
				 'change(@2,@2)=[1]/=>\[]',
				 'change(@3$,@3$)=[]/=>{}',
				 'remove(@4,)=\{}'
				))
		    ],
		    1
		  ));

  ok(testCompare( "Ref module 1",
		  [[3],sub{},    sub{}, *STDIN,(new Data::Dumper(['l']))],
		  [[3],sub{'io'},'klm', 432   ,(new Data::Dumper([123]))],
		  ['change(@2,@2)=sub { "DUMMY" }/=>"klm"',
		   'change(@3,@3)=*::STDIN/=>432',
		   'change(@4|Data::Dumper%todump@0,@4|Data::Dumper%todump@0)="l"/=>123'
		  ]
		));

  use Math::BigInt;

  my $diff=<<'__DIFF';
change(@0,@0)=bless( {
          "seen" => {},
          "maxdepth" => 0,
          "purity" => 0,
          "xpad" => "  ",
          "freezer" => "",
          "apad" => "",
          "toaster" => "",
          "useqq" => 0,
          "terse" => 0,
          "varname" => "VAR",
          "todump" => [
                        1
                      ],
          "bless" => "bless",
          "level" => 0,
          "quotekeys" => 1,
          "sep" => "\n",
          "deepcopy" => 0,
          "names" => [],
          "pad" => "",
          "indent" => 2
        }, 'Data::Dumper' )/=>bless( do{\(my $o = "+3")}, 'Math::BigInt')
__DIFF
  ;


#ok . not fully supported !
#  testCompare( "Ref module 2",
#	       [new Data::Dumper([1])],
#	       [new Math::BigInt(3)],
#	       [$diff]
#	     );

#  This test : 
  ok(testCompare( "Ref module 3",
		  [new Math::BigInt(5)],
		  [new Math::BigInt(3)],

		  ($^V and $^V lt v5.8.0)
		  &&	       ['change(@0|Math::BigInt$,@0|Math::BigInt$)="+5"/=>"+3"']	
		  ||             ['change(@0|Math::BigInt%value@0,@0|Math::BigInt%value@0)=5/=>3']
		));

  local *a=[2,3,4];
  local *h={a=>3,b=>4};
  local *s=\3;

  ok(testCompare( "Glob 0",
		  [\*a,\*h,\*s],
		  [\*a,\*h,\*s],
		  []
		));

  ok(testCompare( "Glob 1",
		  [1,\*h,\*s,\*a],
		  [2,\*a,\*h,\*s],
		  ['change(@0,@0)=1/=>2',
		   (($cplx)?
		    (		
		     'move(@1,@2)=',
		     'move(@2,@3)=',
		     'move(@3,@1)='):
		    (
		     'change(@1*main::h,@1*main::a)={"a"=>3,"b"=>4}/=>[2,3,4]',
		     'change(@2*main::s,@2*main::h)=\3/=>{"a"=>3,"b"=>4}',
		     'change(@3*main::a,@3*main::s)=[2,3,4]/=>\3')
		   )
		  ]
		));

  #############################################################################
  my $deep1={
	     a1=>[1,2,3],
	     g=>['r',3],
	     o=>{
		 d=>12,
		 d2=>{u=>undef},
		 d3=>[],
		 po=>3
		}
	    };

  my $deep2={
	     a1=>[1,2,3,[]],
	     g=>['r',3],
	     o=>{
		 d=>1,
		 d2=>3,
		 d3=>10
		}
	    };

  ok(testCompare(	"Equality",
			$deep1,$deep1,
			[ ]
		));

  #############################################################################
  my @patch_1_2 =
    (
     'change(%o%d3,%o%d3)=[]/=>10',
     'change(%o%d2,%o%d2)={"u"=>undef}/=>3',
     'remove(%o%po,%o)=3',
     'add(%a1,%a1@3)=[]',
     'change(%o%d,%o%d)=12/=>1'
    );

  ok(testCompare( 	"Differences",
			$deep1,
			$deep2,
			\@patch_1_2,
			1
		));

  #############################################################################
  my $deep1_patched = applyPatch($deep1, @patch_1_2);

  ok(testCompare( 	"Equality after patch",
			$deep1_patched, $deep2,
			[ ]
		));

  ok(testCompare( 	"Differences bis ",
			$deep1,
			$deep2,
			\@patch_1_2,
			1
		));


  ok(testCompare( 	"Differences bis twice (previous bord effect) ",
			$deep1,
			$deep2,
			\@patch_1_2,
			1
		));

  #############################################################################
  my @patch_2_1_ =
    (
     'remove(%a1@3,%a1)=[]',
     'change(%o%d,%o%d)=1/=>12',
     'change(%o%d3,%o%d3)=10/=>[]',
     'change(%o%d2,%o%d2)=3/=>{"u"=>undef}',
     'add(%o,%o%po)=3',
    );


  ok(testCompare( 	"Differences 2",
			$deep2,
			$deep1,
			\@patch_2_1_,
			1
		));

  $deep1_patched = applyPatch($deep2, @patch_2_1_ );

  ok(testCompare( 	"Equality after automatic patch 2",
			$deep1_patched,$deep1,
			[ ]
		));

  ok(testCompare( 	"Differences 3",
			{test=> [
				 \ {a=>'toto'},
				 \ 3321,
				 {o=>5,  d=>12},
				 55
				], equal=>432
			},
			{test=> [
				 \ {a=>'titi',b=>3},
				 {o=>5,  d=>12},
				 543,
				 \3321
				], equal=>432
			},
			[
			 'change(%test@0$%a,%test@0$%a)="toto"/=>"titi"',
			 'add(%test@0$,%test@0$%b)=3',
			 (($cplx)?
			  (
			   'move(%test@1,%test@3)=',
			   'move(%test@2,%test@1)=',
			   'remove(%test@3,%test)=55',
			   'add(%test,%test@2)=543'
			  )
			  :
			  (
			   'change(%test@1,%test@1)=\3321/=>{"d"=>12,"o"=>5}',
			   'change(%test@2,%test@2)={"d"=>12,"o"=>5}/=>543',
			   'change(%test@3,%test@3)=55/=>\3321'
			  ))
			],
			1
		));

  ok(testCompare( 	"Differences 4",
			[
			 \ {'toto' => 12},
			 33,
			 {
			  o=>5,
			  d=>12
			 },
			 'titi'
			],
			[
			 \ {'toto' => 12,E=>3},
			 {
			  d=>12,
			  o=>5
			 },
			 'titi'
			],
			[
			 'add(@0$,@0$%E)=3',
			 (($cplx)?(
				   'remove(@1,)=33',
				   'move(@2,@1)=',
				   'move(@3,@2)='
				  ):(
				     'change(@1,@1)=33/=>{"d"=>12,"o"=>5}',
				     'change(@2,@2)={"d"=>12,"o"=>5}/=>"titi"',
				     'remove(@3,)="titi"'
				    ))
			],
			1
		));


  if ($cplx) { 	  # test the post replacement of a add/remove by a move

    ok(testCompare( "post patch move 1",
		    {a=>2},
		    {b=>2},
		    [ 'move(%a,%b)=' ],1
		  ));

    ok(testCompare( "post patch move 2",
		    \ {a=>2},
		    \ {b=>2},
		    [ 'move($%a,$%b)=' ],1
		  ));

    ok(testCompare( "post patch move 3", # reg
		    [2],
		    {b=>2},
		    [ 'change(,)=[2]/=>{"b"=>2}' ],1
		  ));

    ok(testCompare( "post patch move 4", # limit
		    [{a=>2,e=>2},1],
		    [{b=>2},1,{e=>2}],
		    [ 'move(@0%a,@0%b)=',
		      'remove(@0%e,@0)=2',
		      'add(,@2)={"e"=>2}'
		    ],1
		  ));
  }
  else {

    local *c = {a=>2};
    local *b = {b=>2};

    ok(testCompare( "post patch move 5",
		    \*c, \*b,
		    [
		     'remove(*main::c%a,*main::b)=2',
		     'add(*main::c,*main::b%b)=2'
		    ]
		    # Complex mode
		    # [ 'move(*main::c%a,*main::b%b)=' ],1
		  ));

  }

}


END_TEST_MODULE(__FILE__);
   ###########################################################################
1;#############################################################################
__END__ compare.t
###########################################################################
