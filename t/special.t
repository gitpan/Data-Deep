  ##############################################################################
 #  Data::Deep/TEST  : Compare / ApplyPath / Search
  ##############################################################################
;# Tests related to special caracters use in Data::Deep functions
 ###############################################################################
 ### special.t
###
##
#
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
START_TEST_MODULE(__FILE__);

use Data::Deep qw(:config);

o_complex(0);


#############################################################################
# search
#############################################################################

my @special = qw/a b c % @ $ _ = . * ' " & ^ , # - | ( ) { } [ ] \/ \\/;
my $hsh = { map {$_=>$i++} @special };
my $chr;

foreach $chr (@special) {
#  testSearch "encoding $chr", \@special, ['=', $chr], 1,  [$chr];

  testSearch "encoding $chr", $hsh,      ['%', $chr], 1, [$chr];
}



# tester differents formats de path et bug :
#   - avec des / non fermé ..
#   - codage a laa con (avec des caracteres speciaux )



#############################################################################
# compare
#############################################################################

my @special = qw/% @ $ _ = . * ' " a b c & ^ , # - | ( ) { } [ ] \/ \\/;
my $hsh = { map {$_=>$_} @special };

my $chr;

foreach $chr (@special) {
  $_=$chr;
  s/([@\$\^\|\(\)\[\]\/\\\.\*])/\\$1/g;

  testCompare( "special caracter 1", $chr, $chr, [] );
  testCompare( "special caracter 2", {$chr=>$chr}, {$chr=>$chr}, [] );
  testCompare( "special caracter 3", [\$chr], [\$chr], [] );

  my @waited=();;
  for(0..$#special) {
    my $s = $special[$_];
    next if ($s eq $chr);
    s/\'/\\'/g;
    #$s=~s/\'/\\'/g;
    $s =~ s/([\'\\])/\\$1/g;
    push @waited,'remove(@'.$_.",)='$s'";
  }
  testCompare( "special caracter 4", [@special], [$chr], [@waited] );

  my @waited=();;
  for(0..$#special) {
    my $s = $special[$_];
    next if ($s eq $chr);
    s/\'/\\'/g;
    #$s=~s/\'/\\'/g;
    $s =~ s/([\'\\])/\\$1/g;
    push @waited,'remove(%'.$s.",)='$s'";
  }
  testCompare( "special caracter 5", $hsh, {$chr=>$chr}, [@waited] );

#'/=_'.$_.'$/';
#'/%_('.$_.')_/';
}


END_TEST_MODULE(__FILE__);
   ###########################################################################
1;#############################################################################
__END__ compare.t
###########################################################################

tester avec des caractères spéciaux : 
  - les paths (et donc les clefs) ne doivent pas contenir  , )
(TODO : ne pourrais je pas les mettre en quotes)

  - les clefs de hash-table ne doivent pas avoir {}

