  ##############################################################################
 #  Data::Deep/TEST  : search
  ##############################################################################
;# Tests related to the compare function of Data::Deep
 ###############################################################################
 ### search.t
###
##
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { plan tests => 130};
require 'TEST.pl';
START_TEST_MODULE(__FILE__);

o_complex(0);

#############################################################################


ok(testPath(" 0 depth",
	    [\{a=>3,b=>sub{return 'test'}}],
   ['@0$%a=3',
    '@0$%a=4',
    '@0$%a',
    '@0$%b&',
    '@0$%b'
   ],
   0,
   [1,0,3,'test',sub{}]
  ));

my $dom;
ok(testPath(" -1 depth",
	    ($dom=[\{a=>3,b=>sub{return 'test'}}]),
   ['@0$%a=3',
    '@0$%a=4', # value is not checked
    '@0$%a',
    '@0$%b&',
    '@0$%b'
   ],
   -1,
   [ 3,
     3,
     ${$dom->[0]},
     ${$dom->[0]}->{b},
     ${$dom->[0]}
   ]
  ));

ok(testPath(" 0 depth",
	    [\{a=>3}],
   [['@',0,'$','%','a','=',4]],
   0,
   [0]
  ));


ok(testSearch("node root",
	      [\{a=>3}],
   ['%','a','=',3], 0, [1]
  ));

ok(testSearch("node root 2",
	      [\{a=>3}],
   ['%','a','=',4], 0, []
  ));

ok(testSearch("node root 2",
	      3,
	      ['=','3'],0,[1]
	     ));

ok(testSearch("node 0",
	      {a=>3},
	      ['%','a'],0,[3]
	     ));

ok(testSearch("node 0'",
	      {a=>3},
	      ['%','a'],
	      -2,
	      [{a=>3}]
	     ));

ok(testSearch("node 0''",
	      [{r=>\{a=>3}}],
   ['%','a'],
   -2,
   [\{a=>3}]  # got the same thing with -2 depth
));

ok(testSearch("node 1",
	      [\{a=>3}],
   ['=',3],
   1,
   [\{a=>3}]   # do not mistake : \{a=>3} is returned
));

ok(testSearch("node 1'",
	      [\{a=>3}],
   ['=',3],
   2,
   [{a=>3}]
  ));

ok(testSearch("node 1''",
	      [\{a=>3}],
   ['=',3],
   3,
   [3]
  ));

ok(testSearch("node 2", # -1 depth return the value matched
	      \[{r=>\{a=>3}}],
  ['%','r'],
  -1,
  [{r=>\{a=>3}}]
));

my $deep1=
    ['a',
     {
      a1=>[1,2,3],
      g=>['r',3,'432zlurg432a1'],
      d2=>{u=>undef},
      o=>{
	  d=>12,
	  a1=>[8],
	  po=>\[3],
	  'zluRG__'=>'__found'
	 },
      a1bis=>'toto'
     }
    ];

# test the path checks in all ways


#testPathSearch('path 1', $dom, what, [<waited>],  3)


ok(testPathSearch( 'not found 1',$deep1, ['%','unknown'], [] ));
ok(testPathSearch( 'not found 2',$deep1, ['@',3], [] ));
ok(testPathSearch( 'not found 3',$deep1, ['=','unknown'], [] ));

ok(testPathSearch( 'scalar 1',$deep1, ['=','a'], [['@',0,'=','a']] ));
ok(testPathSearch( 'scalar 2',$deep1, ['=',12] , [['@',1,'%','o','%','d','=',12]] ));

ok(testPathSearch( 'hash 1',$deep1, ['%','po'], [['@',1, '%', 'o', '%', 'po']] ));
ok(testPathSearch( 'hash 2',$deep1, ['%','d'] , [['@',1, '%', 'o', '%', 'd']]  ));
ok(testPathSearch( 'hash 3',$deep1, ['%','d2'], [['@',1, '%', 'd2']] ));
ok(testPathSearch(
		  'hash 4',
		  $deep1, 
		  ['%','a1'], 
		  [['@',1,'%','o','%','a1'],
		   ['@',1, '%', 'a1']
		  ] ));

ok(testPathSearch(
		  'hash 5',
		  [{"a"=>[1],'b'=>{r=>'io'},'c'=>3},2],
		  ['%','b','%','r'],
		  [['@',0,'%','b','%','r']]
		 ));

ok(testPathSearch(
		  'hash 6',
		  {e=>{
		       r=>
		       {kl=>
			{toto=>45,tre=>3}
		       }
		      }
		  },
		  ['?%','?%','=',45],
		  [['%','e','%','r','%','kl','%','toto','=',45]]
		 ));


ok(testPathSearch("hash key 1",$deep1,
		  ['?%','=','12'],
		  [['@',1,'%','o','%','d','=',12]],
		  2
		 ));

ok(testPathSearch("hash key 2",$deep1,
		  ['?%','%','u'],
		  [['@',1,'%','d2','%','u']],
		  2
		 ));

ok(testPathSearch('regexp',$deep1,
		  ['%',sub{/a1/}],
		  [
		   ['@',1,'%','a1bis'],
		   ['@',1,'%','o','%','a1'],
		   ['@',1, '%', 'a1']
		  ]
		 ));

ok(testPathSearch('array 1',$deep1,
		  ['@',0],
		  [
		   ['@',0],
		   ['@',1,'%','o','%','po','$','@',0],
		   ['@',1, '%', 'g','@',0],
		   ['@',1,'%','o','%','a1','@',0],
		   ['@',1, '%', 'a1','@',0]
		  ]
		 ));


ok(testPathSearch('array 2',$deep1,
		  ['@',1,'%','a1'],
		  [
		   ['@',1,'%','a1']
		  ]
		 ));

ok(testPathSearch('array 3',$deep1,
		  ['@',2],
		  [
		   ['@',1,'%','g','@',2],
		   ['@',1,'%','a1','@',2]
		  ]
		 ));

ok(testPathSearch('array 4',
		  [1,4,3,
		   [11,22,33,
		    [111,222,333,
		     [1111,2222,3333,5,4]
		    ]
		   ]
		  ],
		  ['?@','?@','=',4],
		  [[ '@',3,'@',3,'@',3,'@',4,'=',4]] # give the two path  
		 ));

local ($_)='init';
ok(testPathSearch('mix 3',
		  $deep1,
		  ['=%',sub {m/a1/}],
		  [
		   ['@',1,'%','a1bis'],
		   ['@',1,'%','o','%','a1'],
		   ['@',1,'%','g','@',2,'=','432zlurg432a1'],
		   ['@',1,'%','a1']
		  ]
		 ));

ok(testSearch("mix 3",
	      $deep1,
	      ['=%',sub{/a1/}],
	      0,
	      [[1,2,3],'toto',1,[8]]
	     ));

ok(testSearch("regexp 1",$deep1, ['=',    sub{/zlurg/}],  -1,['432zlurg432a1']));
ok(testSearch("regexp 2",$deep1, ['%',    sub{/zlurg/i}],  0,['__found']));
ok(testSearch("regexp 3",$deep1, ['@%$=', sub{/zlurg/i}],  0,[1,'__found']));
ok(testSearch("regexp 4",$deep1, ['%',    sub{/d/}],       0,[{u=>undef},12]));
ok(testSearch("regexp 5",$deep1, ['%',    sub{/d/}],      -1,[$deep1->[1],$deep1->[1]{o}]));

##############################################################################################
## pbm under Perl cygwin-thread-multi-64int v5.10.0 
## don't remove the our, I got PERL_CORE ... unable to release SV_... Bad free() ...

my $ex=[ { a=>2,
	   b=>3,
	   c=>[3,4,5]
	 },
	 { a=>6,
	   b=>7,
	   c=>[8,9,10,
	       { 'm'=>50,
		 'o'=>38,
		 'g'=>3
	       },3
	      ],
	   m=>50,
	   d=>sub {return 'toto'},
	   e=>\ [432]
	 },
	 543
       ];

###
ok(testSearch("node 0",
	      $ex,
	      ['=',432],
	      -2,
	      [[432]]
	     ));

ok(testSearch( "node 0'",
	       $ex,
	       ['=',7],
	       -1,
	       [7]
	     ));

ok(testSearch( "node 0''",
	       $ex,
	       ['=',3],
	       -1,
	       [3,3,3,3]
	     ));

my $waited = [
	      $ex->[0],
	      $ex->[0]{c},
	      $ex->[1]{c}[3],
	      $ex->[1]{c}
	     ];

$waited->[0]{c} = $waited->[1];


ok(testSearch( "node 1",
	       $ex,
	       ['?@%','=', 3],
	       -2,
	       $waited
	     ));

ok(testSearch( "node 2",
	       $ex,
	       ['=','432'],
	       -3,
	       [\[432]]
  ));

ok(testSearch( "node 2'",
	       $ex,
	       ['=','432'],
	       2,
	       [\[432]]
  ));

ok(testSearch( "node 3",
	       $ex,
	       ['=','432'],
	       1,
	       [$ex->[1]]
	     ));

# we dont want upper father here
ok(testSearch( "node 4",
	       $ex,
	       ['%','c','@',3],
	       -1,
	       [$ex->[1]{c}]
	     ));

ok(testPathSearch( "array index 1",
		   $ex,
		   ['?@','%','b'],
		   [
		    ['@',0,'%','b'],
		    ['@',1,'%','b']
		   ]
		 ));

ok(testPathSearch( "array index 2",
		   $ex,
		   ['?%','?@'],
		   [
		    ['@',0,'%','c','@',0],
		    ['@',0,'%','c','@',1],
		    ['@',0,'%','c','@',2],
		    ['@',1,'%','c','@',0],
		    ['@',1,'%','c','@',1],
		    ['@',1,'%','c','@',2],
		    ['@',1,'%','c','@',3],
		    ['@',1,'%','c','@',4]
		   ],
		   5
		 ));


ok(testPathSearch( "key 1",$ex,
		   ['?@%','=', 3],
		   [
		    ['@',0,'%','b','=',3],
		    ['@',0,'%','c','@',0,'=',3],
		    ['@',1,'%','c','@',3,'%','g','=',3],
		    ['@',1,'%','c','@',4,'=',3]
		   ]
		 ));

ok(testPathSearch( "key 2",
		   [5,2,3,{r=>3},4,\3],
		   ['?$@%','=',3],
		   [
		    ['@',2,'=',3],
		    ['@',3,'%','r','=',3],
		    ['@',5,'$','=',3]
		   ]
		 ));

ok(testPathSearch( "key 3",
		   [5,2,3,{r=>\3},4,\3],
		   ['?$','=',3],
		   [
		    ['@',3,'%','r','$','=',3],
		    ['@',5,'$','=',3]
		   ]
		 ));

# TODO : Seg Fault
if (0) {
  ok(testSearch( "path number",
		 $ex,
		 ['=',sub{$_>10}],
		 -1,
		 [50,38,432,50,543]
	       )
    );

  ok(testSearch( "path 3",
		 $ex,
		 ['%',sub{1},'=',sub{$_<10}],
		 -1,
		 [2,3,6,7,3]
	       )
    );
  # = ['?%',...

  my $nbocc = search($ex,['?@%','=', 3],999);
  ($nbocc != 4) and ko('bad number of occurences found '.$nbocc.' instead of 4.');
}

sub fx__ {return "toto"};


my $pth_code=['%','b','&'];

$ex={a=>3,b=>\&fx__};

ok(testPathSearch('type code',
		  $ex,
		  ['&'],
		  [$pth_code]
		 ));

ok(testSearch('type code 2',
	      [5,{a=>3,b=>sub {return 'test'}}],
	      ['@1%b&'],
	      0,
	      [  { 'a' => 3, 'b' => sub{ } }  ]
	     ));

my @nodes = path($ex,[$pth_code],1); # deep

my $nbocc = scalar(@nodes);
($nbocc != 1) and ko('bad number of occurences found '.$nbocc.' instead of 1.');
(eval '&{shift(@nodes)}()' ne 'toto') and ko('path : code 2 test : bad function call.');


ok(testPathSearch( 'type glob',
		   {'a'=>3,'b'=>\*STDIN},
		   ['?*'],
		   [['%','b','*','main::STDIN']]
		 ));

ok(testSearch( 'type glob',
	       {a=>3,b=>\*STDIN},
	       ['?*'],
	       1,
	       [\*STDIN]
	     ));

local *a=[2,3,4];
local *h={'a'=>3,'b'=>4};
local *s=\3;

ok(testPathSearch( 'type glob 2',
		   [\*main::a,\*main::h,\*main::s],
		   ['=',3],
		   [
		    ['@',0,'*','main::a','@',1,'=',3],
		    ['@',1,'*','main::h','%','a','=',3],
		    ['@',2,'*','main::s','$','=',3]
		   ]
		 ));

ok(testSearch( 'type glob 2\'',
	       [\*main::a,\*main::h,\*main::s],
	       ['=',3],
	       -1,
	       [3,3,3]
	     ));

ok(testSearch( 'type glob 2"',
	       [\*a,\*h,\*s],
	       ['=',3],
	       -2,
	       [\@main::a,\%main::h,\$main::s]
	     ));

ok(testSearch( 'type glob 2"\'',
	       [\*main::a,\*main::h,\*main::s],
	       ['=',3],
	       -3,
	       [\*a,\*h,\*s]
	     ));

ok(testPathSearch( 'mix 1',
		   {"a"=>[1],'b'=>\{r=>'io'},'c'=>3},
   ['=','io'],
   [['%','b','$','%','r','=','io']]
  ));

ok(testPathSearch( 'mix 2',
		   {"a"=>[1],'b'=>\['a','b','c'],'c'=>3},
   ['$','?@','=','b'],
   [['%','b','$','@',1,'=','b']]
  ));

ok(testSearch( "hash bug",
	       \{
	       'v.d' =>[2],
	       'v1'=>{'kl'=>undef}
	    },
   ['%','v.d'],
   0,
   [[2]]
));

ok(testSearch( "hash bug II",
	       \{
	       'v.d' =>[2],
	       'v1'=>{'kl'=>undef}
	    },
   ['%',sub {/^v./}],
   0,
   [[2],{'kl'=>undef}]
  ));

ok(testSearch( "ref 1",
	       \{'a'=>'b'},
   ['$'],
   -1,
   [\{'a'=>'b'}]
));

ok(testSearch( "ref 2",
	       [2,\ [3],[],{j=>{},a=>\33}],
	       ['$'],
	       0,
	       [[3],33]
));

ok(testSearch( "ref 3",
	       [2,\ [3],[],{j=>{},a=>\33}],
	       ['$'],
	       -1,
	       [\[3],\33]
  ));

ok(testSearch( "ref 4",
	       [2,\ [3],{a=>\33}],
	       ['%',sub {1},'$'],
	       0,
	       [33]
	     ));

ok(testPathSearch( "ref 4",
		   [2,\ [3,3,3],{a=>\ 123},\ {}],
		   ['$','?@'],
		   [
		    ['@',1,'$','@',0],
		    ['@',1,'$','@',1],
		    ['@',1,'$','@',2]
		   ]
		 ));

ok(testSearch( "ref 4",
	       [2,\ [3,3,3],{a=>\ 123},\ {}],
	       ['$','?@'],
	       0,
	       [3,3,3]
	     ));

ok(testSearch( "ref 5",
	       [\ 2,\ [3],{a=>\ 123},\ {},{nb=>\ undef}],
	       ['?%','$','=',sub {/\d+/}],
	       -1,
	       [123]
	     ));


ok(testPathSearch( "Module Data::Dumper 0",
		   new Data::Dumper(
				    [\ 2,\ [3],{a=>\ 123},\ {},{nb=>\ undef}]
				   ),
		   ['?|','?%'],
		   [['|','Data::Dumper','%','apad']],
		   1
		 ));

ok(testSearch( "Module ref Data::Dumper 1",
	       (new Data::Dumper(
				 [\ 2,\[3],{a=>\123},\{},{nb=>\ undef}]
	     )),
  ['?%','$','=',sub {/\d+/}],
  -1,
  [123]
));

my $dd=[\ 2,\ [3], new Data::Dumper([{a=>\ 123}]), \ {},{nb=>\ undef}];

ok(testPathSearch( "Module ref 2",
		   $dd,
		   ['?%','$','=',sub {/\d+/}],
		   [['@',2,'|','Data::Dumper','%','todump','@',0,'%','a','$','=',123]]
		 ));

ok(testSearch( "Module ref 3",
	       $dd,
	       ['?%','$','=',sub {/\d+/}],
	       -4,
	       [${$dd->[2]}{todump}]
	     ));

ok(testSearch( "Module ref 3'",
	       $dd,
	       ['?%','$','=',sub {/\d+/}],
	       3,
	       [${$dd->[2]}{todump}]
	     ));

ok(testSearch( "Module ref 4",
	       $dd,
	       ['?%','$','=',sub {/\d{3}/}],
	       -3,
	       [{a=>\123}]
	     ));

ok(testSearch( "Module ref 5",
	       $dd,
	       ['?%','$','=',sub {/\d+/}],
	       4,
	       [{a=>\123}]
	     ));

ok(testSearch( "Module ref 6",
	       $dd,
	       ['=',123],
	       5,
	       [\123]
	     ));


########### PBM pas moyen de match quoiquecesoitdedans
package PKG_TEST;our $VAR_GLOB=87;sub new { return bless {a=>32};};1;

package main;
# warn Dumper(new PKG_TEST());

ok(testSearch( "Module ref 7",
	       [new PKG_TEST(),32],
	       ['=',32],
	       -1,
	       [32,32]
	     ));

# Bareword "VAR_GLOB" not allowed while "strict subs" in use at t/search.t
#testSearch( "Module ref 8",
#      [\*PKG_TEST::],
#      ['%',VAR_GLOB],
#      0,
#      [*PKG_TEST::VAR_GLOB]
#);


# TODO : \*PKG_TEST:: ko
# cannot search into GLOB values VAR_GLOB (only dynamic packages, not global var)


#============================================================================
my $exd = [5,2,3,{r=>3},4,\3];

#
title( "direct call of search function") and do {
  my @nodes = path($exd,
		   [ search($exd, #dom
			    ['?$@%','=',3], # what
			    2) # nb occ
		   ] ,-2); # deep

  my $a = Dumper([@nodes]);
  my $b = Dumper([$exd,
		  $exd->[3],
		  $exd->[5]
		 ]
		);

  ($a eq $b)  and ok(1) or ok($a,$b);
};

END_TEST_MODULE(__FILE__);
   ###########################################################################
1;#############################################################################
__END__ search.t
###########################################################################

