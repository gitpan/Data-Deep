#!/usr/bin/perl
    ###########################################################################
   ############################################################################
  #    Data::Deep Tester
 ##############################################################################
 # Before `make install' is performed this script should be runnable with
 # `make test'. After `make install' it should work as `perl test.pl'
 ############################################################################
 ### TEST.t
###
##
#
#


use strict;

use Data::Dumper;

# avoid $VAR1 in subexpressions
$Data::Dumper::Terse = 1;

use lib 'lib/';
use Data::Deep qw(:DEFAULT :convert :config);


our $TEST_FILTER;

#$TEST_FILTER = '/search.+?array\sindex\s2/';
#$TEST_FILTER = '/complex\smode/';
#$TEST_FILTER = '/glob\s1/i';

#o_debug(1);


##############################################################################
sub bug { 
  Data::Deep::o_debug()
      and 
	print STDERR @_;
}
##############################################################################


##############################################################################
sub START_TEST_MODULE($) {
  Data::Deep::o_debug()
      and
	print "\n".('#' x 80)
	  ."\n              >>>>>>>>>>>>>>>  ".shift()." <<<<<<<<<<<<<<<<<<<<<<< \n"
	    .('#' x 80)."\n";
}

sub END_TEST_MODULE($)   {
  Data::Deep::o_debug()
      and
	print
	  "\n              ~~~~~~~~~~~~~~~  ".shift()." Finished   ~~~~~~~~~~~~ \n";
}

##############################################################################

##############################################################################
sub title {
  my $title = shift();

  if ($TEST_FILTER) {
    eval '$title =~ '.$TEST_FILTER or return;
    bug "\n+++ $title ";
  }
  else {
    bug "\n== ".$title;
  }
  bug " : ";
  return 1;
}
##############################################################################


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub testRes($$) {	
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my @result = @{shift()};  # DOM format
  my @waited = @{shift()};  # TEXT format
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  bug "\n_____________________________________________________________\n";
  bug "Result = \n\t".join("\n\t", map({domPatch2TEXT $_} @result))."\n";
  bug "Waited = \n\t".join("\n\t", @waited)."\n";

  my @err;
  my $res;

  foreach $res (@result) {
    my $r = domPatch2TEXT($res);

    my $i=0;
    my $found=undef;
    my $t;

    foreach $t (@waited) {
      ref($t) and $t = domPatch2TEXT($t);
      # comparer les deux chaines
      if($t eq $r)
       {
	$found=$i;
	#print "\nFOUND $found == $i: $r\nIN : $t.";
	last;
      }
      else {
	#print "\nNOT FOUND : ".$r."\n      <!> : ".$t."\n";
      }
      $i++;
    }

    if (defined $found) { # delete this one
      splice @waited,$found,1;
    }
    else {
      push @err,$res
    }
  }
  if (@err or @waited) {
    my $msg;
    $msg = "\n  Waited result remain :\n\t".join("\n\t",map({(ref($_)?domPatch2TEXT($_):$_)} @waited))
      if (@waited);
    $msg .= "\n  Results remain :\n\t".join("\n\t",map({domPatch2TEXT $_} @err))
      if (@err);

    return $msg
  }

  return undef
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub testPathSearch($$$$;$) { # testing if search() return the right paths
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $msg = "search() / ".shift()." : ";
  my $dom = shift;
  my $what = shift;
  my $waited = shift;
  my $nb_occ = shift || 999;
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  title $msg or return;

  my $dom_before = Dumper($dom);

  #          search() TEST
  #########################################
  my @paths = search $dom, $what, $nb_occ;

  bug "\n - check bords effect. ";
  if (Dumper($dom) ne $dom_before) {
    bug "\nWaited    : ".$dom_before."\n";
    bug "\nCorrupted : ".Dumper($dom)."\n";
    return 0;
  }

  bug " - check search results. ";
  my $res = testRes( \@paths, $waited );
  $res and bug "$res\n";
  (!defined($res)) or return 0;
  return 1;
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub testTravel { # testing if travel() goes into the right values
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $msg = shift();
  my $dom = shift;
  my $waited = shift; # we'll try to automatise that
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  title "travel through a node / $msg ()" or return;

  my $visitor_test =  sub {
    my $node = shift();
    my $depth = shift;
    my @cur_path = @_;

    return $depth.' > '.join('',@cur_path).' : '.ref($node);
  };

  #         travel() TEST
  #########################################
  my $dom_before = Dumper($dom);
  my @res = travel($dom, $visitor_test);

  bug "\n - check bords effect. ";
  if (Dumper($dom) ne $dom_before) {
    bug "\nWaited    : ".$dom_before."\n";
    bug "\nCorrupted : ".Dumper($dom)."\n";
    return 0;
  }

  #

  bug " - check search results. ";
  Data::Deep::debug(@res);
  my $d1= Dumper(\@res);
  my $d2= Dumper($waited);

  $d1=~s/\n$//;
  $d2=~s/\n$//;
  if ($d1 ne $d2) {
    bug "\nWaited    : ".$d1."\n";
    bug "\nCorrupted : ".$d2."\n";
    return 0;
  }
  return 1;	
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub testSearch { # testing if search() then path() return the right values
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $msg = shift();
  my $dom = shift;
  my $what = shift;
  my $depth = shift;
  my $waited = shift;
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  title "search a node / $msg " or return;

  my $dom_before = Dumper($dom);

  #          search() TEST
  #########################################
  my @res = search($dom, $what, 999);

  #          path() TEST
  #########################################
  my @nodes= path($dom,
		  [@res],
		  $depth);

  bug "\n - check bords effect. ";
  if (Dumper($dom) ne $dom_before) {
    bug "\nWaited    : ".$dom_before."\n";
    bug "\nCorrupted : ".Dumper($dom)."\n";
    return 0;
  }

  my $t1 = ok(Dumper($dom), $dom_before);

  #my $res = testRes( \@nodes, $waited );
  #$res and ko($res) or ok($msg)

  my $d1= Dumper(\@nodes);
  my $d2= Dumper($waited);

  bug " - check search results. ";
  $d1=~s/\n$//;
  $d2=~s/\n$//;

  return $t1 and ok($d1,$d2);
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub testPath { # test for path()
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $msg = "testPath / ".shift();
  my $dom = shift;
  my $what = shift;
  my $depth = shift;
  my $waited = shift;
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  title $msg or return;

  my $dom_before = Dumper($dom);

  #          path() TEST
  #########################################
  my @nodes= path($dom,
		  $what,
		  $depth);

  my $dom_after = Dumper($dom);
  ok($dom_before, $dom_after);

  #my $res = testRes( \@nodes, $waited );
  #$res and ko($res) or ok($msg)

  my $d1= Dumper(\@nodes);
  my $d2= Dumper($waited);

  $d1=~s/\n$//;
  $d2=~s/\n$//;

  ok($d1,$d2);
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub testCompare {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $msg = "compare() / ".shift().(o_complex()?' (complex mode)':'').' : ';
  my $a1 = shift;
  my $a2 = shift;
  my $waited_patch = shift;
  my $patch_test = shift;
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  title $msg or return;


  my $d1 = Dumper($a1);
  my $d2 = Dumper($a2);

  #          compare() TEST
  ############################################
  my @pth_1_2 = compare($a1,$a2);

  bug "\n - check compare results : ";
  my $res = testRes( \@pth_1_2, $waited_patch );
  $res and bug "$res\n";
  (!defined($res)) or return 0;

  bug "\n - check bords effect.";
  if (Dumper($a1) ne $d1) {
    bug "\nWaited    : ".$d1."\n";
    bug "\nCorrupted : ".Dumper($a1)."\n";
    return 0;
  }

  if (Dumper($a2) ne $d2) {
    bug "\nWaited    : ".$d2."\n";
    bug "\nCorrupted : ".Dumper($a2)."\n";
    return 0;
  }

  if ($patch_test) {  ##  applyPatch() TEST

    bug "\n - check applyPatch. ";

    my $a1_patched = applyPatch($a1, @pth_1_2);

    my @res = compare($a1_patched,$a2);

    if (@res) {
      bug "After applying patch {\n  - "
	.join("\n  - ",map {domPatch2TEXT $_} @pth_1_2)
	  ."\n}\nStill found remaining differences {\n  - "
	.join("\n  - ",map {domPatch2TEXT $_} @res)
	  ."\n}\nDom dump after patch is ".Dumper($a1_patched);
      return 0;
    }
    else {  ## Apply reverse patch

      my @patch_2_1 = compare($a2,$a1);
      bug "\n - ApplyPatch reverse :";

      #                applyPatch() TEST
      ############################################
      my $a2_patched = applyPatch($a2, @patch_2_1);

      #      compare() TEST
      ############################################
      @res = compare($a1,$a2_patched);
      if (@res) {
	bug("Remaining differences after applying reverse patcher :\n"
	    .join("\n",map {domPatch2TEXT $_} @res)
	    ."\nResult after patch is ".Dumper($a2_patched));

	return 0;
      }
    }
  }
  return 1;
}

##############################################################################
use strict;
use Test;
BEGIN { plan tests =>380};
##############################################################################




  ##############################################################################
 # Tests related to the compare function of Data::Deep
 ###############################################################################
START_TEST_MODULE('Search');
 ###
###
##
#

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

END_TEST_MODULE('Search');


  ##############################################################################
 # Tests related to the compare function of Data::Deep
 ###############################################################################
START_TEST_MODULE('Compare');
 ###
###
##
#

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
END_TEST_MODULE('Compare');


  ##############################################################################
 # Tests related to the travel function of Data::Deep
 ###############################################################################
START_TEST_MODULE('Travel');
 ###
###
##
#

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

END_TEST_MODULE('Travel');



  ##############################################################################
 # Tests related to key in use with search and compare functions of Data::Deep
 ###############################################################################
START_TEST_MODULE('key');
 ###
###
##
#

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



END_TEST_MODULE('key');



  ##############################################################################
 # Tests related to zap to avoid node during search and compare functions
 ###############################################################################
START_TEST_MODULE('zap');
 ###
###
##
#

o_complex(0);
#ok(1); # TODO : zap() 


END_TEST_MODULE('zap');


  ##############################################################################
 # Tests related to special caracters use in Data::Deep functions
 ###############################################################################
START_TEST_MODULE('special');
 ###
###
##
#

o_complex(0);

#############################################################################


#############################################################################
# search
#############################################################################


# TODO unsupported now ' \\

# tester differents formats de path et bug :
#   - avec des / non fermé ..
#   - codage a laa con (avec des caracteres speciaux )

my @special = ('a', 'b', 'c', '%,', '@', '$', '\,', '_', 
	       '=', '.', '*', '"', '&', '^', '#', '-', '|',
	       '(', ')', '{', '}', '[', ']', '\/', '/');

my $i=0;
my $hsh = { map {$_=>$i++} @special };
my $chr;

$i=0;
foreach $chr (@special) {

  ok(testSearch("encoding $chr", \@special, ['=', $chr], 1,  [$chr]));
  ok(testSearch("encoding $chr", $hsh, ['%', $chr], 1, [$i++]));
}


#############################################################################
# compare
#############################################################################

$hsh = { map {$_=>$_} @special };

foreach $chr (@special) {
  $_=$chr;
  s/([@\$\^\|\(\)\[\]\/\\\.\*])/\\$1/g;

  ok(testCompare( "special caracter 1", $chr, $chr, [] ));
  ok(testCompare( "special caracter 2", {$chr=>$chr}, {$chr=>$chr}, [] ));
  ok(testCompare( "special caracter 3", [\$chr], [\$chr], [] ));


  # IN DEV / TODO : caracters @ " ' \ are badly protected

  my @waited=();
  for(0..$#special) {
    my $s = $special[$_];
    next if ($s eq $chr);
    s/\'/\\'/g;
    #$s=~s/\'/\\'/g;
    $s =~ s/([\'\\])/\\$1/g;


    push @waited,'remove(@'.$_.",)=\"$s\"";
  }
  # SQUIZED
  0 and testCompare( "special caracter 4", [@special], [$chr], [@waited] );

  @waited=();
  for(0..$#special) {
    my $s = $special[$_];
    next if ($s eq $chr);
    s/\'/\\'/g;
    #$s=~s/\'/\\'/g;
    $s =~ s/([\'\\])/\\$1/g;
    push @waited,'remove(%'.$s.",)=\"$s\"";
  }
  # SQUIZED
  0 and testCompare( "special caracter 5", $hsh, {$chr=>$chr}, [@waited] );

#'/=_'.$_.'$/';
#'/%_('.$_.')_/';
}



END_TEST_MODULE('special');



   ###########################################################################
1;#############################################################################
__END__ TEST.PL
###########################################################################

