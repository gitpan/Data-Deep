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

START_TEST_MODULE(__FILE__);

use Data::Deep qw(:config);

testPath " 0 depth",
    [\{a=>3,b=>sub{return 'test'}}],
    ['@0$%a=3',
     '@0$%a=4',
     '@0$%a',
     '@0$%b&',
     '@0$%b'
    ],
    0,
    [1,0,3,'test',sub{}];

my $dom;
testPath " -1 depth",
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
    ];

testPath " 0 depth",
    [\{a=>3}],
    [['@',0,'$','%','a','=',4]],
    0, [0];


testSearch "node root",
    [\{a=>3}],
    ['%','a','=',3], 0, [1];

testSearch "node root 2",
    [\{a=>3}],
    ['%','a','=',4], 0, [];

testSearch "node root 2",
    3,
    ['=','3'],0,[1];

testSearch "node 0",
    {a=>3},
    ['%','a'],0,[3];

testSearch "node 0'",
    {a=>3},
    ['%','a'],
    -2,
    [{a=>3}];

testSearch "node 0''",
    [{r=>\{a=>3}}],
    ['%','a'],
    -2,
    [\{a=>3}];  # got the same thing with -2 depth

testSearch "node 1",
    [\{a=>3}],
    ['=',3],
    1,
    [\{a=>3}];   # do not mistake : \{a=>3} is returned

testSearch "node 1'",
    [\{a=>3}],
    ['=',3],
    2,
    [{a=>3}];

testSearch "node 1''",
    [\{a=>3}],
    ['=',3],
    3,
    [3];

testSearch "node 2", # -1 depth return the value matched
    \[{r=>\{a=>3}}],
    ['%','r'],
    -1,
    [{r=>\{a=>3}}];

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


testPathSearch 'not found 1',$deep1, ['%','unknown'], [];
testPathSearch 'not found 2',$deep1, ['@',3], [];
testPathSearch 'not found 3',$deep1, ['=','unknown'], [];

testPathSearch 'scalar 1',$deep1, ['=','a'], [['@',0,'=','a']];
testPathSearch 'scalar 2',$deep1, ['=',12] , [['@',1,'%','o','%','d','=',12]];

testPathSearch 'hash 1',$deep1, ['%','po'], [['@',1, '%', 'o', '%', 'po']];
testPathSearch 'hash 2',$deep1, ['%','d'] , [['@',1, '%', 'o', '%', 'd']];
testPathSearch 'hash 3',$deep1, ['%','d2'], [['@',1, '%', 'd2']];
testPathSearch 
	'hash 4',
	$deep1, 
	['%','a1'], 
	[['@',1,'%','o','%','a1'],
	 ['@',1, '%', 'a1']
	];

testPathSearch 
	'hash 5',
  	[{"a"=>[1],'b'=>{r=>'io'},'c'=>3},2],
  	['%','b','%','r'],
	[['@',0,'%','b','%','r']];

testPathSearch 
	'hash 6',
  {e=>{
       r=>
       {kl=>
	{toto=>45,tre=>3}
       }
      }
  },
  	['?%','?%','=',45],
	[['%','e','%','r','%','kl','%','toto','=',45]];


testPathSearch "hash key 1",$deep1,
	['?%','=','12'],
	[['@',1,'%','o','%','d','=',12]],
	2;

testPathSearch "hash key 2",$deep1,
  ['?%','%','u'],
  [['@',1,'%','d2','%','u']],
  2;

testPathSearch 'regexp',$deep1,
  ['%',sub{/a1/}],
  [
   ['@',1,'%','a1bis'],
   ['@',1,'%','o','%','a1'],
   ['@',1, '%', 'a1']
  ];

testPathSearch 'array 1',$deep1,
  ['@',0],
  [
   ['@',0],
   ['@',1,'%','o','%','po','$','@',0],
   ['@',1, '%', 'g','@',0],
   ['@',1,'%','o','%','a1','@',0],
   ['@',1, '%', 'a1','@',0]
  ];


testPathSearch 'array 2',$deep1,
  ['@',1,'%','a1'],
  [
   ['@',1,'%','a1']
  ];

testPathSearch 'array 3',$deep1,
  ['@',2],
  [
   ['@',1,'%','g','@',2],
   ['@',1,'%','a1','@',2]
  ];

testPathSearch 'array 4',
  [1,4,3,
     [11,22,33,
      [111,222,333,
       [1111,2222,3333,5,4]
      ]
     ]
  ],
  ['?@','?@','=',4],
  [[ '@',3,'@',3,'@',3,'@',4,'=',4]] # give the two path  
;

testPathSearch 'mix 3',
    $deep1,
    ['=%',sub{/a1/}],
    [
     ['@',1,'%','a1bis'], 
     ['@',1,'%','o','%','a1'],
     ['@',1,'%','g','@',2,'=','432zlurg432a1'],
     ['@',1,'%','a1']
    ];

testSearch "mix 3",
    $deep1,
    ['=%',sub{/a1/}],
    0,
    [[1,2,3],'toto',1,[8]];

testSearch "regexp 1",$deep1, ['=',    sub{/zlurg/}],  -1,['432zlurg432a1'];
testSearch "regexp 2",$deep1, ['%',    sub{/zlurg/i}],  0,['__found'];
testSearch "regexp 3",$deep1, ['@%$=', sub{/zlurg/i}],  0,[1,'__found'];
testSearch "regexp 4",$deep1, ['%',    sub{/d/}],       0,[{u=>undef},12];
testSearch "regexp 5",$deep1, ['%',    sub{/d/}],      -1,[$deep1->[1],$deep1->[1]{o}];

##############################################################################################
## pbm under Perl cygwin-thread-multi-64int v5.10.0 
## don't remove the our, I got PERL_CORE ... unable to release SV_... Bad free() ...

$ex=[ { a=>2,
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
testSearch "node 0",
  $ex,
  ['=',432],
  -2,
  [[432]];

testSearch "node 0'",
  $ex,
  ['=',7],
  -1,
  [7];

testSearch "node 0''",
  $ex,
  ['=',3],
  -1,
  [3,3,3,3];

my $waited = [
	      $ex->[0],
	      $ex->[0]{c},
	      $ex->[1]{c}[3],
	      $ex->[1]{c}
	     ];

$waited->[0]{c} = $waited->[1];


testSearch "node 1",
  $ex,
  ['?@%','=', 3],
  -2,
  $waited;

testSearch "node 2",
  $ex,
  ['=','432'],
  -3,
  [\[432]];

testSearch "node 2'",
  $ex,
  ['=','432'],
  2,
  [\[432]];

testSearch "node 3",
  $ex,
  ['=','432'],
  1,
  [$ex->[1]];

# we dont want upper father here
testSearch "node 4",
    $ex,
    ['%','c','@',3],
    -1,
    [$ex->[1]{c}];

testPathSearch "array index 1",
    $ex,
    ['?@','%','b'],
    [
     ['@',0,'%','b'],
     ['@',1,'%','b']
    ];

testPathSearch "array index 2",
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
  5;


testPathSearch "key 1",$ex,
  ['?@%','=', 3],
  [
   ['@',0,'%','b','=',3],
   ['@',0,'%','c','@',0,'=',3],
   ['@',1,'%','c','@',3,'%','g','=',3],
   ['@',1,'%','c','@',4,'=',3]
  ];


testPathSearch "key 2",
    [5,2,3,{r=>3},4,\3],
    ['?$@%','=',3],
    [
     ['@',2,'=',3],
     ['@',3,'%','r','=',3],
     ['@',5,'$','=',3]
    ];

testPathSearch "key 3",
    [5,2,3,{r=>\3},4,\3],
    ['?$','=',3],
    [
     ['@',3,'%','r','$','=',3],
     ['@',5,'$','=',3]
    ];

# TODO : Seg Fault
if (0) {
testSearch "path number",
    $ex,
    ['=',sub{$_>10}],
    -1,
    [50,38,432,50,543];

testSearch "path 3",
    $ex,
    ['%',sub{1},'=',sub{$_<10}],
    -1,
    [2,3,6,7,3];
# = ['?%',...


my $nbocc = search($ex,['?@%','=', 3],999);
($nbocc != 4) and ko('bad number of occurences found '.$nbocc.' instead of 4.');

}
sub fx__ {return "toto"};


my $pth_code=['%','b','&'];
my $ex={a=>3,b=>\&fx__};

testPathSearch 'type code',
  $ex,
  ['&'],
  [$pth_code];

testSearch 'type code 2',
  [5,{a=>3,b=>sub {return 'test'}}],
  ['@1%b&'],
  0,
  [  { 'a' => 3, 'b' => sub{ } }  ];


my @nodes = path($ex,[$pth_code],1); # deep

my $nbocc = scalar(@nodes);
($nbocc != 1) and ko('bad number of occurences found '.$nbocc.' instead of 1.');
(eval '&{shift(@nodes)}()' ne 'toto') and ko('path : code 2 test : bad function call.');


testPathSearch 'type glob',
  {a=>3,b=>\*STDIN},
  ['?*'],
  [['%','b','*','main::STDIN']];

testSearch 'type glob',
  {a=>3,b=>\*STDIN},
  ['?*'],
  1,
  [\*STDIN];

local *a=[2,3,4];
local *h={a=>3,b=>4};
local *s=\3;

testPathSearch 'type glob 2',
  [\*a,\*h,\*s],
  ['=',3],
  [
   ['@',0,'*','main::a','@',1,'=',3],
   ['@',1,'*','main::h','%','a','=',3],
   ['@',2,'*','main::s','$','=',3]
  ];

testSearch 'type glob 2\'',
  [\*a,\*h,\*s],
  ['=',3],
  -1,
  [3,3,3];

testSearch 'type glob 2"',
  [\*a,\*h,\*s],
  ['=',3],
  -2,
  [\@a,\%h,\$s];

testSearch 'type glob 2"\'',
  [\*a,\*h,\*s],
  ['=',3],
  -3,
  [\*a,\*h,\*s];

testPathSearch 'mix 1',
  {"a"=>[1],'b'=>\{r=>'io'},'c'=>3},
  ['=','io'],
  [['%','b','$','%','r','=','io']],

testPathSearch 'mix 2',
  {"a"=>[1],'b'=>\['a','b','c'],'c'=>3},
  ['$','?@','=','b'],
  [['%','b','$','@',1,'=','b']];

testSearch "hash bug",
    \{
     'v.d' =>[2],
     v1=>{kl}
    },
    ['%','v.d'],
    0,
    [[2]];

testSearch "hash bug II",
    \{
     'v.d' =>[2],
     v1=>{kl}
    },
    ['%',sub {/^v./}],
    0,
    [[2],{kl}];

testSearch "ref 1",
    \{a=>b},
    ['$'],
    -1,
    [\{a=>b}];

testSearch "ref 2",
    [2,\ [3],[],{j=>{},a=>\33}],
    ['$'],
    0,
    [[3],33];

testSearch "ref 3",
    [2,\ [3],[],{j=>{},a=>\33}],
    ['$'],
    -1,
    [\[3],\33];

testSearch "ref 4",
    [2,\ [3],{a=>\33}],
    ['%',sub {1},'$'],
    0,
    [33];

testPathSearch "ref 4",
    [2,\ [3,3,3],{a=>\ 123},\ {}],
    ['$','?@'],
    [
     ['@',1,'$','@',0],
     ['@',1,'$','@',1],
     ['@',1,'$','@',2]
    ];

testSearch "ref 4",
    [2,\ [3,3,3],{a=>\ 123},\ {}],
    ['$','?@'],
    0,
    [3,3,3];

testSearch "ref 5",
    [\ 2,\ [3],{a=>\ 123},\ {},{nb=>\ undef}],
    ['?%','$','=',sub {/\d+/}],
    -1,
    [123];


testPathSearch "Module Data::Dumper 0",
  new Data::Dumper(
		   [\ 2,\ [3],{a=>\ 123},\ {},{nb=>\ undef}]
		  ),
  ['?|','?%'],
  [['|','Data::Dumper','%','apad']],
  1;


testSearch "Module ref Data::Dumper 1",
    (new Data::Dumper(
		     [\ 2,\[3],{a=>\123},\{},{nb=>\ undef}]
		    )),
    ['?%','$','=',sub {/\d+/}],
    -1,
    [123];

my $dd=[\ 2,\ [3], new Data::Dumper([{a=>\ 123}]), \ {},{nb=>\ undef}];

testPathSearch "Module ref 2",
      $dd,
      ['?%','$','=',sub {/\d+/}],
      [['@',2,'|','Data::Dumper','%','todump','@',0,'%','a','$','=',123]];

testSearch "Module ref 3",
      $dd,
      ['?%','$','=',sub {/\d+/}],
      -4,
      [${$dd->[2]}{todump}];

testSearch "Module ref 3'",
      $dd,
      ['?%','$','=',sub {/\d+/}],
      3,
      [${$dd->[2]}{todump}];

testSearch "Module ref 4",
      $dd,
      ['?%','$','=',sub {/\d{3}/}],
      -3,
      [{a=>\123}];

testSearch "Module ref 5",
      $dd,
      ['?%','$','=',sub {/\d+/}],
      4,
      [{a=>\123}];

testSearch "Module ref 6",
      $dd,
      ['=',123],
      5,
      [\123];


########### PBM pas moyen de match quoiquecesoitdedans
package PKG_TEST;$VAR_GLOB=87;sub new { return bless {a=>32};};1;
package main;
# warn Dumper(new PKG_TEST());

testSearch "Module ref 7",
      [new PKG_TEST(),32],
      ['=',32],
      -1,
      [32,32];

testSearch "Module ref 8",
      [\*PKG_TEST::],
      ['%',VAR_GLOB],
      0,
      [*PKG_TEST::VAR_GLOB];


# TODO : cannot search into GLOB values VAR_GLOB (only dynamic packages, not global var)
testSearch "Module ref 9",
      [\*PKG_TEST::],
      ['=',87],
      0,
      [87];



#============================================================================
my $ex = [5,2,3,{r=>3},4,\3];

# 
title "direct call of search function" and do {
  my @nodes = path($ex,
		   [ search($ex, #dom
			    ['?$@%','=',3], # what
			    2) # nb occ
		   ] ,-2); # deep


  local $Data::Dumper::Terse = 1;  # no $VAR1
  my $a = Dumper([@nodes]);
  my $b = Dumper([$ex,
		  $ex->[3],
		  $ex->[5]
		 ]
		);

  ($a eq $b)  and ok(1) or ok($a,$b);
};

END_TEST_MODULE(__FILE__);
   ###########################################################################
1;#############################################################################
__END__ search.t
###########################################################################

