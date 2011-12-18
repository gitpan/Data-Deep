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


   ###########################################################################
1;#############################################################################
__END__ TEST.PL
###########################################################################

