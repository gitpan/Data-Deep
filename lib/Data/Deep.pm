 ######################################################################
#############################################################################
package Data::Deep;
##############################################################################
  # Ultimate tool for Perl data manipulation
  ############################################################################
 ### Deep.pm
  ############################################################################
  # Copyright (c) 2005 Matthieu Damerose. All rights reserved.
  # This program is free software; you can redistribute it and/or
  # modify it under the same terms as Perl itself.
  ############################################################################
###
##
#
#


=head1 NAME

Data::Deep - Complexe Data Structure analysis and manipulation

=head1 SYNOPSIS

use Data::Deep;

$dom1=[ \{'toto' => 12}, 33,  {o=>5,d=>12}, 'titi' ];

$dom2=[ \{'toto' => 12, E=>3},{d=>12,o=>5}, 'titi' ];

my @patch = compare($dom1, $dom2);

use Data::Deep qw(:DEFAULT :convert :config);

o_complex(1);        # deeper analysis results

print join("\n", domPatch2TEXT( compare($dom1,$dom2) ) );

@patch = (
	  'add(@0$,@0$%E)=3',
	  'remove(@1,)=33',
	  'move(@2,@1)=',
	  'move(@3,@2)='
	);

$dom2 = applyPatch($dom1,@patch);

$h_toto = search $dom1, '@1'

=head1 DESCRIPTION

Data::Deep provides search, compare and applyPatch functions which are very
usefull for complex Perl Data Structure manipulation (ref, hash or array,
array of hash, blessed object and siple scalar).
Filehandles and sub functions are not compared (just type is considered).


=head2 path definition

First thing to understand is the definition of a path expression,
it identify a node in a complex Perl data structure.

Path is composed of the following elements :

   ('%', '<key>') to match a hash table at <key> value
   ('@', <index>) to match an array at specified index value
   ('*', '<glob name>') to match a global reference
   ('|', '<module name>') to match a blessed module reference

   ('$') to match a reference
   ('&') to match a code reference

   ('/') to match a key defined by key() function

   ('=' <value>) to match the leaf node <value>

Modifier <?> can be placed in the path with types to checks :

EX:

   ?%  : match with hash-table content (any key is ok)
   ?@  : match with an array content (any index will match)
   ?=  : any value
   ?*  : any glob type
   ?$  : any reference
   ?=%@      : any value, hash-table or array
   ?%@*|$&=  : everything

Evaluation function :
   sub{... test with $_ ... } will be executed to match the node
   EX: sub { /\d{2,}/ } match numbers of minimal size of two


Patch is an operation between two nodes, Patch is composed of :
   - An action :
        'add' for addition of an element from source to destination
        'remove' is the suppression from source to destination
        'move' if possible the move of a value or Perl Dom
        'change' describe the modification of a value
   - a source path
   - a destination path

Three patch formats can be use : dom (internal), text (need convertion) and
ihm (output format format only) :

   DOM  : Internal dom patch is an hash-table :

        EX: my $patch1 =
                     { action=>'change',
                       path_orig=>['@0','$','%a'],
                       path_dest=>['@0','$','%a'],
                       val_orig=>"toto",
                       val_dest=>"tata"
                     };

   TEXT : text output mode patch could be :

          add(<path source>,<path destination>)=<val dest>
          remove(<path source>,<path destination>)=<val src>
          change(<path source>,<path destination>)=<val src>/=><val dest>
          move(<path source>,<path destination>)

   IHM  : Visual output


=head2 Important note :

* search() and path() functions use paths in both format :
      TEXT
            EX: '@1%r=432')

  or
      DOM (simple array of elements described above)
            EX: ['@',1,'%','r','=',432]

* applyPath() can use TEXT or DOM patch format in input.

* compare() produce dom patch format in output.


All function prefer the use of dom (internal format) then no convertion is done.
Output (user point of view) is text or ihm.

format patches dom  can be converted to TEXT : domPatch2TEXT
format patches text can be converted to DOM  : textPatch2DOM
format patches dom  can be converted to IHM  : domPatch2IHM

See conversion function

=cut


##############################################################################
# General version and rules
##############################################################################
use 5.004;
$VERSION = '0.10';
#$| = 1;

##############################################################################
# Module dep
##############################################################################
use Data::Dumper;
# c:\Perl\lib\Data\Dumper.pm  line 229
use Carp;
use strict;
use warnings;
no integer;
no strict 'refs';
no warnings;

use overload; require Exporter; our @ISA = qw(Exporter);


our @DEFAULT =
  qw(
     travel
     visitor_dumper
     visitor_search
     search
     compare
     path
     applyPatch
    );

our @EXPORT = @DEFAULT;


our @CONFIG =
  qw(
     o_debug
     o_follow_ref
     o_complex
     o_key
    );

our @CONVERT =
  qw(
     textPatch2DOM
     domPatch2TEXT
     domPatch2IHM
    );

our @EXPORT_OK = (@DEFAULT,
	      @CONFIG,
	      @CONVERT
	     );


our %EXPORT_TAGS=(
	      convert=>[@CONVERT],
	      config=>[@CONFIG]
	     );
##############################################################################
#/````````````````````````````````````````````````````````````````````````````\


my $CONSOLE_LINE=78;

##############################################################################


=head2 Options Methods

=over 4

=item I<zap>(<array of path>)

configure nodes to skip (in search or compare)
without parameter will return those nodes

=cut


sub zap {
  @_ and $Data::Deep::CFG->{zap}=shift()
    or return $Data::Deep::CFG->{zap};
}


 #############################################################################
### OPTIONS DECLARATION 
##############################################################################
 # Declare option  : _opt_dcl 'o_flg'
 # Read the option :           o_flg()
 # Set the option  :           o_flg(1)
 ############################################################################

our $CFG = {};

my $__opt_dcl = sub { my $name = shift();
		      my $proto = shift() || '$';

		      eval 'sub '.$name."(;$proto) {"
			  .' @_ and $Data::Deep::CFG->{'.$name.'}=shift()
                               or return $Data::Deep::CFG->{'.$name.'} }';
		      $@ and die '__bool_opt_dcl('.$name.') : '.$@;
		  };
 ############################################################################

=item I<o_debug>([<debug mode>])

debug mode :
   1: set debug mode on
   0: set debug mode off
   undef : return debug mode

=cut

$__opt_dcl->('o_debug');

 ############################################################################

=item I<o_follow_ref>([<follow mode>])

follow mode :
   1: follow every reference (default)
   0: do not enter into any reference
   undef: return if reference are followed

=cut

$__opt_dcl->('o_follow_ref');

o_follow_ref(1);


 ############################################################################

=item I<o_complex>([<complex mode>])

complex mode is used for intelligency complex (EX: elements move in an array)
   1: complex mode used in search() & compare()
   0: simple analysis (no complex search)
   undef: return if reference are followed

=cut

$__opt_dcl->('o_complex');


##############################################################################
sub debug {
##############################################################################
  o_debug() or return;

  # B.S./WIN : no output using STDERR 
  sub out__ { (($^O=~/win/i)?print @_:print SDTERR @_) }

  my $l;
  foreach $l(@_) {
    (ref $l)
      and out__ "\n".__d($l)
	or do {
	  out__$l;
	  if (length($l)>$CONSOLE_LINE) { out__ "\n" }
	  else { out__ ' ' }
	}
      }
  out__ "\n"
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub  __d { # Data::Dumper / escaped for eval
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  local $Data::Dumper::Useqq = 1;  # quot \n ...
  local $Data::Dumper::Terse = 1;  # no $VAR1
  local $Data::Dumper::Indent= 0;
#  local $Data::Dumper::Quotekeys = 1;
#  local $Data::Dumper::Purity = 1;
#  local $Data::Dumper::Indent = 1;
#  local $Data::Dumper::Deparse = 1;

  my $t = Dumper(shift());
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  #  $t=~s/\'/\'/g;
  #my $p='\''.substr(substr($t,0,length($t)-2),1).'\'';
  #print "\nDEBUG (".$t.") $p = ".eval($t)."\n";die $@ if ($@);
  return $t;
}

##############################################################################
###############################################################################
###############################################################################
# PRIVATE FX
###############################################################################
###############################################################################



##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $pathText2Dom = sub($) { # text path convertion to dom
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my @pathTxt = (split '',shift());
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my @path;
  my $val;
  #debug "pathText2Dom(".join('',@pathTxt).')';
  while (@pathTxt) {
    $_ = shift @pathTxt;
    /([%\@\$\=\|\*\&\/])/ and do {
      ($path[-1] eq '@') and $val = int($val);
      push(@path,$val) if ($val ne '');
      $val='';
      push(@path,$1);
    }
      or
	$val .= $_;
  }
  ($path[-1] eq '@') and $val = int($val);
  push(@path,$val) if ($val ne '');

  #debug '=>'.join('.',@path);
  return [@path];
};

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $patchDOM = sub($$$;$$) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my $action = shift;
  my $p1= shift();
  my $p2= shift();
  my $v1 = shift();
  my $v2 = shift();
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my $dom = {};
  $dom->{action} = $action;
  $dom->{path_orig} = $p1;
  $dom->{path_dest} = $p2;
  $dom->{val_orig}  = $v1;
  $dom->{val_dest}  = $v2;

  return $dom;
};


#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $patchText=sub ($$$$$) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my $action = shift;
  my @p1=@{shift()};
  my @p2=@{shift()};
  my $v1 = shift();
  my $v2 = shift();
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my $patch = $action
    .'('
      .join('',@p1)
	.','
	  .join('',@p2)
	    .')=';

  if (($action eq 'remove') or ($action eq 'change')) {
    $v1 = __d($v1);
    $v1 =~ s|/=>|\/\\054\>|g;
    $v1 =~ s/\s=>\s/=>/sg;
    $patch .= $v1;
  }

  ($action eq 'change') and $patch .= '/=>';

  if (($action eq 'add') or ($action eq 'change')) {
    $v2 = __d($v2);
    $v2 =~ s|/=>|\/\\054\>|g;
    $v2 =~ s/\s=>\s/=>/sg;
    $patch .= $v2;
  }
  return $patch;
};


# sub patchIHM {


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $matchPath = sub {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my @pattern=@{shift()};  # to match
  my @where=@_;    # current path
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  #warn 'matchPath('.join(' ',@where).' , '.join(' ',@pattern).')';

  # Great optimization
  unless (defined $CFG->{o_key}) {
    my ($wh,$pt) = (
		    join('',@where),
		    join('',@pattern)
		 );

    my $idx = rindex($wh,$pt);
    if (($idx!=-1 and (length($wh) - $idx)==length($pt))) {
      # ???if ($wh=~/${pt}(?=[%@\$*|=]?.*)$/) {
	#warn "Matched optimized  !";
	return 1;
	# }
    }
  }

  my $ok;
  #warn 'matchPath:LongAlgo('.join(' ',@where).' , '.join(' ',@pattern).')';
  my $i = 0;
 PATH:while ($i<=$#where) {

    my $j = 0;
    my $sav_i = $i;

  PATTERN: while ($i<=$#where) {

      ### CURRENT PATH
      my $t_where = $where[$i++]; # TYPE
      my $v_where;                # VALUE

      ## PATTERN
      my $t_patt = $pattern[$j++]; # TYPE
      my $v_patt;

      #print "$t_where =~ $t_patt : ";
#print $t_where;
      (index($t_patt,$t_where)==-1) and last PATTERN; # type where should be found in the pattern

      my $key;
      if ($t_where eq '/') {
        $key = $where[$i++]
	  or
	    die 'internal matchPath : key waited in path after /';

	($key ne $pattern[$j++]) and last PATTERN
      }
      elsif ($t_where eq '&') { }
      elsif ($t_where eq '$') { }
      elsif ($t_where eq '=' or
	     $t_where eq '%' or
	     $t_where eq '@' or
	     $t_where eq '*' or
	     $t_where eq '|'
	    ) {

	$v_where = $where[$i++];

	unless (substr($t_patt,0,1) eq '?') {
#print 'v';

	  $v_patt = $pattern[$j++];

	  if (ref($v_patt) eq 'CODE') { # regexp or complexe val
            local ($_) = ($v_where);
	    $v_patt->($_) or last PATTERN
	  }
	  elsif (ref($v_patt) and (Dumper($v_patt) ne Dumper($v_where))) {
	    last PATTERN;
	  }
	  elsif ($v_patt ne $v_where) {
	    # print '!';
	    last PATTERN;
	  }
	}
      }
      else {
#print '#';
	($i-1==$#where)
	  or
	    die 'Error in matched expression "'.join('',@where).'" not supported char type "'.$t_where.'".';
      }
#print '.';
      if ($j-1==$#pattern and $i-1==$#where) {
	# warn "#found($i,$j)";
	return $sav_i;
      }

    }# PATTERN:

    # next time
    ($j>1) and $i = $sav_i+1;

  }# WHERE:

  #print "\n";
  return undef;
};



##############################################################################
# KEY DCL :
our $CFG;
sub o_key {
  @_ and $CFG->{o_key}=shift()
    or return $CFG->{o_key};
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $isKey = sub {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my @path=@_;
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}


  (defined $CFG->{o_key}) or return @path;

  my $sz_path = scalar(@path);

  # debug "\n###".join('.',@{$path}).' '.join('|',keys %{$CFG->{o_key}});    <>;

  my %keys=%{$CFG->{o_key}};

  my $k;
  foreach $k (
		 sort {
		   ($keys{$a}{priority} - $keys{$b}{priority})
		 } keys %keys)
    {
      my $match = $keys{$k}{regexp};
      #warn "\n=$k on ".join('',@path);

      my $min_index = $matchPath->($match, @path);

      if (defined $min_index) {
	# debug " -> key($k -> ".join(' ',@{$match}).")  = $min_index\n";

	# replace the (matched key expression) by ('/' , <key name>)

	splice @path, $min_index, $sz_path, '/',$k;
	#warn "__key $k -> ".join('.',@path)."\n";
	return @path;
      }
    }

  return @path;
};


=item I<o_key>(<hash of key path>)

key is a search pattern for simplifying search or compare.
or a group of pattern for best identification of nodes.

hash of key path:


EX:
         key(
		CRC => {regexp=>['%','crc32'],
			eval=>'{crc32}',
			priority=>1
		       },
		SZ  => {regexp=>['%','sz'),
			eval=>'{sz}',
			priority=>2
		       }
             )


regexp   : path to search in the dom
eval     : is the perl way to match the node
priority : on the same node two ambigues keys are prioritized
depth    : how many upper node to return from the current match node

=back

=cut



##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
my $path2eval__ = sub {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $first_eval = shift();
  my $deepness = shift();  # [ 0.. N ] return N from root
                           # [-N..-1]  return N stage from leaves
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  my $evaled = $first_eval;

  my $dbg_head = __PACKAGE__."::path2eval__($evaled,$deepness,".join(',',@_).") : ";
  debug $dbg_head;
  my $max=$#_;

  @_ or return $evaled;

  if (defined $deepness and $deepness<=0) { # start from the end
    while ($deepness++<0 and $max>=0) {
      $_[$max-1] =~ /^[\@%\*\|\/=]$/ and $max-=2
	or
      $_[$max] =~ /^[\$\&]$/    and $max--;
    }
    ($max==0) and return $evaled; # upper as root

    debug "\n negative depth $deepness: -> remaining path(".join(',',@_[0..$max]).")\n";
    $deepness=undef;
  }
  my $deref='->';

  my $i=0;
  while($i<=$max) {
    $_ = $_[$i++];

    if ($_ eq '$') {
      $evaled = '${'.$evaled.'}';
      $deref = '->';
    }
    elsif ($_ eq '%') {
      $evaled .= $deref."{'".$_[$i++]."'}";
      $deref='';
    }
    elsif ($_ eq '@') {
      $evaled .= $deref.'['.$_[$i++].']';
      $deref='';
    }
    elsif ($_ eq '|') {
      $i++;
    }
    elsif ($_ eq '*') {
      $i++;
      my $suiv = $_[$i] or next;
      if ($suiv eq '%') {
	$evaled = '*{'.$evaled.'}{HASH}';
	$deref = '->';
      }
      elsif ($suiv eq '@'){
	$evaled = '*{'.$evaled.'}{ARRAY}';
	$deref = '->';
      }
      elsif ($suiv eq '$' or $suiv eq '='){
	$evaled = '*{'.$evaled.'}{SCALAR}';
	$deref = '->';
      }
    }
    elsif ($_ eq '/') { # KEY->{eval}
      my $keyname = $_[$i++];
      my $THEKEY  = $CFG->{o_key}{$keyname};
      my $ev = $THEKEY->{eval} or die $dbg_head.'bad eval code for '.$keyname;
      $evaled .= $deref.$ev;
      $deref='';
    }
    elsif ($_ eq '&') {
      $evaled = $evaled.'->()';
    }
    elsif ($_ eq '=') {
      ($i==$#_) or die $dbg_head.'bad path format : value waited in path after "="';

      if ($_[$i]=~/^\d+$/) {	
	$evaled = 'int('.$evaled.'=='.$_[$i++].')'
      }
      else {
	$evaled = 'int('.$evaled.' eq \''.$_[$i++].'\')'
      }

      $deref='';
    }
    else {
      die $dbg_head.'bad path format : Type '.$_.' not supported.'
    }

    if (defined($deepness)) {  # >0 start from root
      #print "\n positive depth $deepness:";
      last if (--$deepness==0);
    }
  }
  debug "-> $evaled #\n";
  return $evaled;
};

my %loop_ref=();
##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub loop_det($;@) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  my $r = shift();
  ref($r) or return 0;

  $r = $r.' ';
  #defined *$d1{SCALAR}

  if (exists($loop_ref{$r})) {
    debug "loop_det => LOOP".join('',@_) ;
    return 1;
  }

  $loop_ref{$r}=1;
  return 0;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PUBLIC FX
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


=head2 Operation Methods

=over 4

=cut


#############################################################
sub visitor_dumper { # exemple of visitor
#############################################################
    my $node = shift();
    my $depth = shift;
    my @cur_path = @_;

    my $dump = join(' ',@cur_path);

    return $dump;

    # get the source code => How ?
#   (ref($node) eq 'CODE') and return $dump.'CODE';#(&$node());
 #   return $dump.ref($node);

}

#############################################################
# IDEA : sub visitor_search { 
# IDEA : searching visitor to replace search
#############################################################
#    my $node = shift();
#    my $depth = shift;
#    my @cur_path = @_;

#    if (defined $matchPath->($pattern, @cur_path)) {
#	    defined($nb_occ) and (--$nb_occ<1) and die 'STOP';

#            return $node;
#    }
#}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub travel($;@) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  my $where=shift();
  my $visitor = shift() || \&visitor_dumper;
  my $depth = shift()||0;
  my @path = @_;


=over 4

=item I<travel>(<dom> [,<visitor function>])

travel make the visitor function to travel through each node of the <dom>

   <dom>    complexe perl data structure to travel into
   <visitor_fx>()

Return a list path where the <pattern> argument match with the
   corresponding node in the <dom> tree data type

I<EX:>

   travel( {ky=>['l','r','t',124],r=>2}

   returns ( [ '%', 'ky', '@' , 3 , '=' , 124 ] )

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  my $arr = wantarray();
  @path or %loop_ref=();

  #debug "travel()".($arr && ' return ARRAY ');

  my @list;
  my $found=undef;

  my ($k,$res);


  #}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

  my $ref_type = ref $where;


  ######################################## !!!!! Modules type resolution
#  if (index($ref_type,'::')!=-1) {
  my ($realpack, $realtype, $id) =
    (overload::StrVal($where) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

  if ($realpack) {

    my $y = undef;
    if ($realtype eq 'SCALAR') {
      $y=$$where;
    }
    elsif ($realtype eq 'HASH') {
      $y=\%$where
    }
    elsif ($realtype eq 'ARRAY') {
      $y=\@$where
    }
    else {
      die $y
    }
    $where = $y;

    #debug ref($y)." = $realpack -> real $realtype, $id";

    push @path,'|',$ref_type;

    $ref_type = $realtype;
  }

  debug "travel__ ( dom=",join('',@path), ' is ',$ref_type,")";

  ######################################## !!!!! Loop detection
  my @p;

  if (loop_det($where)) {
    @p = $isKey->(@path, '$loop');
    $res = &$visitor($where, $depth , @p);
    $arr and (push(@list, $res)) or $found=$res;
  }
  else {
    ######################################## !!!!! SCALAR TRAVEL
    if (!$ref_type) {
      @p = $isKey->(@path, '=', $where);
      $res = &$visitor($where, $depth , @p);
      $arr and (push(@list, $res)) or $found=$res;

    }
    ######################################## !!!!! HASH TRAVEL
    elsif ($ref_type eq 'HASH')
      {
	my $k;
	foreach $k (sort {$a cmp $b} keys(%{ $where })) {
	  @p = $isKey->(@path, '%', $k);

          $res = &$visitor($where, $depth, @p);
          $arr and (push(@list, $res)) or $found=$res;

	  push(@list, travel($where->{$k},$visitor,$depth+1, @p));
	}
      }
    ######################################## !!!!! ARRAY TRAVEL
    elsif ($ref_type eq 'ARRAY')
      {
	for my $i (0..$#{ $where }) {
	  #print "\narray  $i (".$where->[$i].','.join('.',@p).")\n" if (join('_',@p)=~ /\@_1_\%_g_/);
	  @p = $isKey->(@path, '@', $i);
          $res = &$visitor($where, $depth, @p);
          $arr and (push(@list, $res)) or $found=$res;

	  push(@list, travel($where->[$i],$visitor,$depth+1, @p));
	}
      }
    ######################################## !!!!! REFERENCE TRAVEL
    elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR')
      {
	 @p = $isKey->(@path, '$');

        $res = &$visitor($where, $depth, @p );
        $arr and (push(@list, $res)) or $found=$res;

	push(@list, travel( ${ $where }, $visitor, $depth+1, @p ));
      }
    else { # others types
      ######################################## !!!!! CODE TRAVEL
      if ($ref_type eq 'CODE') {
	@p = $isKey->(@path, '&');
      }
      ######################################## !!!!! GLOB TRAVEL
      elsif ($ref_type eq 'GLOB') {
	my $name=$$where;
	$name=~s/b^\*//;
	@p = $isKey->(@path, '*', $name);
      }
      ######################################## !!!!! MODULE TRAVEL
      else {
	die $ref_type;
      }

      $res = &$visitor($where, $depth, @p );
      $arr and (push(@list, $res)) or $found=$res;

      ######################################## !!!!! GLOB TRAVEL
      # cf IO::Handle or Symbol::gensym()

      if ($p[-2] eq '*') { # GLOB
	for $k (qw(SCALAR ARRAY HASH)) {
	  my $gval = *$where{$k};
	  defined($gval) or next;
	  next if ($k eq "SCALAR" && ! defined $$gval);  # always there
	  return (@list,travel($gval, $visitor, $depth+1, @p));
	}
      }
    }
  }

  $arr and return @list;
  return $found;
}


my %circular_ref;
##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub search($$;$@) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $where = shift();
  my $pattern = shift();
  my $nb_occ = shift();
  my @path=@_;

#  warn "search for #$nb_occ (",join('',@{$pattern}),")";


=item I<search>(<tree>, <pattern> [,<max occurrences>])

search the <pattern> into <tree>

   <tree>      is a complexe perl data structure to search into
   <pattern>   is an array of type description to match
   <max occ.>  optional argument to limit the number of results
                  if undef all results are returned
		  if 1 first one is returned

Return a list path where the <pattern> argument match with the
    corresponding node in the <dom> tree data type

EX:
    search( {ky=>['l','r','t',124],r=>2}
            ['?@','=',124])

      Returns ( [ '%', 'ky', '@' , 3 , '=' , 124 ] )


    search( [5,2,3,{r=>3,h=>5},4,\{r=>4},{r=>5}],
            ['%','r'], 2 )

      Returns (['@',3,'%','r'],['@',5,'$','%','r'])


    search( [5,2,3,{r=>3},4,\3],
            ['?$@%','=',sub {$_ == 3 }],
            2;

      Returns (['@',2,'=',3], ['@',3,'%','r','=',3])

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
#  warn "search($where / ref=".ref($where).','.$nb_occ.' ,'.join('',@path).")";

  (defined($nb_occ) and ($nb_occ<1)) and return ();

  my $ref_type = ref $where;

  my @list;
  my $next = undef;
  my @p;

  ######################################## !!!!! Modules type resolution
  if ($ref_type) {

    #if (index($where,'::')!=-1) {  ## !!!!! MODULE SEARCH

    my ($realpack, $realtype, $id) =
      (overload::StrVal($where) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    if ($realpack) {
      push @path, ('|', $ref_type);

      $ref_type = $realtype;

      # warn "$ref_type -> ($realpack, $realtype, $id )";
    }


    ######################################## !!!!! Loop detection
    @path or %loop_ref=();

    if (loop_det($where)) {
      @p = (@path, '$loop');
    }
    ######################################## HASH Search
    elsif ($ref_type eq 'HASH') {
      my $k;
      foreach $k (sort {$a cmp $b} keys(%{ $where })) {
	@p = $isKey->(@path, '%', $k);
	# warn "\n".join('.',@p).">HASH{$k} =".$where->{$k}.' (ref='.ref($where->{$k}).')';

	if (defined $matchPath->($pattern, @p)) {
	  push @list,[@p];
	  defined($nb_occ) and (--$nb_occ<1) and last;
	}
	else {
	  my @res = search($where->{$k}, $pattern, $nb_occ, @p);
	  @res and push @list,@res;
	}
      }
      return @list;
    }
    ######################################## HASH Search
    elsif ($ref_type eq 'ARRAY')
      {
	for my $i (0..$#{ $where }) {
	  @p = $isKey->(@path, '@', $i);

	  if (defined $matchPath->($pattern, @p)) {
	    push @list,[@p];
	    defined($nb_occ) and (--$nb_occ<1) and last;
	  }
	  else {
	    my @res = search($where->[$i], $pattern, $nb_occ, @p);
	    @res and push @list,@res;
	  }
	}
	return @list;
      }
    ######################################## REF Search
    elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR') {
      @p = $isKey->(@path, '$');
      $next = ${ $where };
    }
    ######################################## CODE Search
    elsif ($ref_type eq 'CODE') {
      @p = $isKey->(@path, '&');
    }
    ######################################## GLOB Search
    elsif ($ref_type eq 'GLOB') {
      my $name = $$where;
      $name=~s/^\*//;
      @p = $isKey->(@path, '*',$name);
      if (defined *$where{SCALAR} and defined(${*$where{SCALAR}})) {
	$next = *$where{SCALAR};
      }
      elsif (defined *$where{ARRAY}) {
	$next = *$where{ARRAY};
      }
      elsif (defined *$where{HASH}) {
	$next = *$where{HASH};
      }
    }
  }
  ######################################
  else { ## !!!!! SCALAR Search
    @p = $isKey->(@path, '=', $where);
  }
  ######################################

  if (defined $matchPath->($pattern, @p)) {
    push @list,[@p];
    defined($nb_occ) and --$nb_occ;
  }

  if ((defined($next))) {
    my @res = search($next, $pattern, $nb_occ, @p);
    @res and push @list,@res;
  }

  return @list;
}


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub path($$;$) {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $dom = shift();
  my @paths = @{shift()};
  my $father_nb = shift() or 0;


=item I<path>(<tree>, <paths> [,<depth>])

gives a list of nodes pointed by <paths>
   <tree> is the complex perl data structure
   <paths> is the array reference of paths
   <depth> is the depth level to return from tree
      <nb> start counting from the top
      -<nb> start counting from the leaf
      0 return the leaf or check the leaf with '=' or '&' types):
             * if code give the return of execution
             * scalar will check the value

Return a list of nodes reference to the <dom>

EX:

    $eq_3 = path([5,{a=>3,b=>sub {return 'test'}}],
                  ['@1%a'])

    $eq_3 = path([5,{a=>3,b=>sub {return 'test'}}],
                  '@1%a','@1%b')


    @nodes = path([5,{a=>3,b=>sub {return 'test'}}],
                   ['@1%b&'], # or [['@',1,'%','b','&']]

                   0  # return ('test')
                      # -1 or 2 return ( sub { "DUMMY" } )
		      # -2 or 1 get the hash table
		      # -3 get the root tree
                   )]);

    @nodes = path([5,{a=>3,b=>sub {return 'test'}}],
                   ['@1%a'], # or [['@',1,'%','b','&']]

                   0  # return 3
                      # -1 or 2 get the hash table
		      # -2 or 1 get the root tree
                   )]);


=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}


  debug "path( \$dom, $#paths patch, $father_nb)";

  my @nodes;

  foreach my $node (@paths) {
    my @path = @{(ref($node) eq 'ARRAY') && $node || $pathText2Dom->($node)};

    # perl evaluation of the dom path
    my $e = $path2eval__->('$dom', $father_nb, @path);

    my $r = eval $e;
    debug $dom;
    debug $e.' evaluated to '.Dumper($r);
    die __FILE__.' : path() '.$e.' : '.$@ if ($@);
    push @nodes,$r
  }
  return shift @nodes unless (wantarray());
  return @nodes;
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub compare {
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{

  # ############ ret : 0 if equal / 1 else
  my $d1 = shift();
  my $d2 = shift();

  my (@p1,@p2,$do_resolv_patch);
  if (@_) {
    @p1 = $isKey->(@{$_[0]});
    @p2 = $isKey->(@{$_[1]});
  }
  else {
    %loop_ref=();
    # equiv TEST on each function call: if ($CFG->{o_complex} and ($#a1==-1 and $#a2==-1)) {
    $CFG->{o_complex} and $do_resolv_patch=1;
  }

=item I<compare>(<node origine>, <node destination>)

compare nodes from origine to destination
nodes are complex perl data structure

Return a list of <patch in dom format> (empty if node structures are equals)

EX:

   compare(
           [{r=>new Data::Dumper([5],ui=>54},4],
           [{r=>new Data::Dumper([5,2],ui=>52},4]
          )

    return ({ action=>'add',
              ...
            },
            { action=>'change',
              ...
            },
             ...
          )

=cut


#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}



  ###############################################################################
  sub searchSuffix__{
    my @a1=@{shift()};
    my @a2=@{shift()};
    my @patch=@{shift()};

    my @common;
    while (@a1 and @a2) {
      $_= pop(@a1);
      ($_ eq pop(@a2)) and unshift @common,$_ or return @common
    }
    return @common
  }
  ###############################################################################

  sub resolve_patch {
    my @patch = @_;
    my ($p1,$p2);

    foreach $p1 (@patch) {
      foreach $p2 (@patch) {

	if ($p1->{action} eq 'remove' and
	    $p2->{action} eq 'add' and
	    (Dumper($p1->{val_orig}) eq Dumper($p2->{val_dest}))) {


	  #my @com = searchSuffix__($p1->{path_orig}, $p2->{path_dest}, \@patch);
	  #@com or next;
	  #grep({$_ eq '&'}  @com) or next;
	  push @patch,
	    compare($p1->{val_orig},
		    $p2->{val_dest},
		    [@{$p1->{path_orig}}],
		    [@{$p2->{path_dest}}]
		   );

	  $p1->{action}='move';
	  $p1->{val_orig}= $p1->{val_dest}= undef;
	  $p1->{path_dest}= $p2->{path_dest};
	  $p2->{action}='erase';
	}
      }
    }

    my $o;
    while ($o<=$#patch) {
      ($patch[$o]->{action} eq 'erase') and splice(@patch,$o,1) and next;
      $o++
    }

    return @patch
  }

  ###############################################################################
  debug "\nComparing ORIG(".join('.',@p1,'=',ref($d1)||$d1).") <> DEST(".join('.',@p2,'=',ref($d2)||$d2).")\n";

  # ############ ret : 0 if equal / 1 else
  my @msg=();

  ######################################## !!!!! Type resolution
  my $ref_type = ref $d1;

  if ($ref_type) {

    ($ref_type ne ref($d2))
      and 
	return ( $patchDOM->('change', \@p1,\@p2, $d1,$d2) );

    #if (index($ref_type,'::')!=-1) {

    my ($realpack, $realtype, $id) =
      (overload::StrVal($d1) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    if ($realpack) {
      my ($realpack2, $realtype2, $id2) =
	(overload::StrVal($d2) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

      ($realtype ne $realtype2)
	and
	  push @msg, $patchDOM->('change', \@p1 ,\@p2 , $realtype ,$realtype2);

      push @p1, '|',$ref_type;
      push @p2, '|',$ref_type;
	
      debug "$ref_type -> ($realpack, $realtype, $id : $ref_type)";

      $ref_type = $realtype;
    }
  }

  ######################################## !!!!! KEY COMPARE

  # DISABLED AND NOT TESTED : very complex use of key for deep comparing
  ##
  if (0 and $CFG->{o_key}) {

    # TODO : retrieve the keyname from last isKey call
    my $key1;
    my $key2;

    my $k = $CFG->{o_key}{$key1};

    # Depth return (key cfg)
    my $depth = (exists $k->{depth} && $k->{depth} || 0);


    if (!defined $key2 or $key1 ne $key2) {
      #warn "### search for &$key1 in ".join('',@p2);<>;
      #@path2 or return ($patchDOM->('remove', \@p1,\@p2 , undef ,undef));

      # @p2 = @{shift @path2};
    }
    debug "\nkey compare {{ ".join('.',@p1).' Vs '.join('.',@p2).' }}';

    my $nb_occ=((exists $k->{occ})?$k->{occ}:1);

    # TODO: compare node from keys
    my @srh1 = search($d1, ['/',$key1], $nb_occ);
    my @srh2 = search($d2, ['/',$key1], $nb_occ);

    (join('',@srh1) ne join('',@srh2))
      and 
	push @msg, $patchDOM->('move', \@srh1,\@srh2);

    my @nodes1 = path($d1, @srh1, $depth);
    @nodes1 or die "Could'nt find this path ".join('.',map {join('',@{$_})} @srh1).' ! ';

    my @nodes2 = path($d2, @srh2, $depth);
    @nodes2 or die "Could'nt find this path ".join('.',map {join('',@{$_})} @srh2).' ! ';


    my $i;
    for $i (1..$nb_occ) {
      push @msg, compare(shift(@nodes1), shift(@nodes2), \@srh1, \@srh2);
    }

    $do_resolv_patch or return @msg;
    return resolve_patch(@msg);
  }

  ######################################## !!!!! SCALAR COMPARE
  if (!$ref_type)
    {
      ($d1 ne $d2) and return ($patchDOM->('change', \@p1,\@p2, $d1,$d2) );
      return ();
    }
  ######################################## !!!!! HASH COMPARE
  elsif ($ref_type eq 'HASH')
    {
      my (%seen,$k);

      foreach $k (sort {$a cmp $b}
		  keys(%{ $d1 }))
	{
	  $seen{$k}=1;

	  if (exists $d2->{$k}) {

	    loop_det($d1->{$k},@p1) and next;

	    push @msg,
	      compare( $d1->{$k},
		       $d2->{$k},
		       [$isKey->( @p1, '%',$k) ],
		       [$isKey->( @p2, '%',$k) ],
		     );
	  } else {
	    push @msg,$patchDOM->('remove', [ $isKey->(@p1, '%', $k) ] ,\@p2 , $d1->{$k} ,undef)
	  }

	}#foreach($d1)

      foreach $k (sort {$a cmp $b} keys(%{ $d2 })) {
	next if exists $seen{$k};

	my $v = $d2->{$k};
	push @msg,$patchDOM->('add', \@p1, [ $isKey->(@p2, '%', $k) ], undef, $v)
      }

      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);
    }
  elsif ($ref_type eq 'ARRAY')
    {
      ######################################## !!!!! ARRAY COMPARE (not complex mode)

      unless ($CFG->{o_complex}) {

	my $min = $#{$d1};
	$min = $#{$d2} if ($#{$d2}<$min); # min ($#{$d1},$#{$d2})

	my $i;
	foreach $i (0..$min) {

	  loop_det($d1->[$i], @p1)
	    and
	      next;

	  push @msg,
	    compare( $d1->[$i], $d2->[$i], [@p1, '@',$i], [@p2, '@',$i]);
	}

	foreach $i ($min+1..$#{$d1}) { # $d1 is bigger
	  # silent just for complexe search mode
	  push @msg,$patchDOM->('remove', [ $isKey->(@p1, '@', $i) ], \@p2 ,$d1->[$i], undef)
	}
	foreach $i ($#{$d1}+1..$#{$d2}) { # d2 is bigger
	  push @msg,$patchDOM->('add', \@p1, [ $isKey->(@p2, '@', $i) ], undef, $d2->[$i])
	}
	return @msg;
      }

      ######################################## !!!!! ARRAY COMPARE (in complex mode)
      my @seen_src;
      my @seen_dst;
      my @res_Eq;
      # perhaps not on the same index (search in the dest @)
      my $i; 
    ARRAY_CPLX:
      foreach $i (0..$#{$d1}) {
	my $val1 = $d1->[$i];
	
	#print "\n SAR($i) {";
	#if ($i<$#{$d2}) {
	if (exists $d2->[$i]) {
	  my @res;

	  loop_det($val1, @p1)
	    or
	      @res = compare($val1,
			     $d2->[$i],
			     [ $isKey->(@p1, '@',$i) ],
			     [ $isKey->(@p2, '@',$i) ]);

	  if (@res) {	$res_Eq[$i] = [@res]	    }   # (*)
	  else
	    {
	      $seen_src[$i]=$i;
	      $seen_dst[$i]=$i;
	      next ARRAY_CPLX;
	    }
	}
	my $j;
	foreach $j (0..$#{$d2}) {  #print " -> $j ";
	  next if ($i==$j);
	  next if (defined($seen_dst[$j]));

	  unless (compare( $val1,
			   $d2->[$j],
			   [ $isKey->(@p1, '@',$i) ],
			   [ $isKey->(@p2, '@',$j) ]))
	    {  #print " (found) ";

	      $seen_dst[$j] = 1;
	      $seen_src[$i] = $patchDOM->('move', 
					  [ $isKey->(@p1, '@', $i) ],
					  [ $isKey->(@p2, '@', $j) ]);
	      next ARRAY_CPLX;
	    }
	}
	(defined  $seen_src[$i])
	  or
	    $seen_src[$i] = $patchDOM->('remove', 
					[ $isKey->(@p1, '@', $i) ],
					\@p2,
					$val1,
					undef
				       );

	#print " }SAR($i)";
      } # for $d1 (0..$min)

      ### destination table $d2 is bigger
      ##
      foreach $i (0..$#{$d2}) {
	defined($seen_dst[$i]) and next;

	$seen_dst[$i] = $patchDOM->('add',
				    \@p1,
				    [ $isKey->(@p2, '@', $i) ], 
				    undef, 
				    $d2->[$i]
				   )
      }

      my $max = $#seen_dst;

      ($#seen_src>$max) and $max = $#seen_src;

      foreach (0..$max) {
	my $src = $seen_src[$_];
	my $dst = $seen_dst[$_];

	if (ref($res_Eq[$_]) and # differences on the same index (*)
	    ref($src) and ref($dst)) {

	  #print "\n src/dst : ".domPatch2TEXT($src)."/ ".domPatch2TEXT($dst)."\n";

	  # remove(@2,)=<val1> add(,@2)=<val2 => <patch val1 val2>
	  ($src->{action} eq 'remove') and
	    ($dst->{action} eq 'add') and
	      (push @msg, @{ $res_Eq[$_] })
		and next;
	}
	(ref $src) and push @msg,$src;
	(ref $dst) and push @msg,$dst;
      }

      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);
    }
  ######################################## !!!!! REF COMPARE
  elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR')
    {
      if (loop_det($$d1, @p1)) {
      }
      else {
	@msg = ( compare($$d1, $$d2,
			 [ $isKey->(@p1, '$') ],
			 [ $isKey->(@p2, '$') ])
	       );
      }
      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);
    }
  ######################################## !!!!! GLOBAL REF COMPARE
  elsif ($ref_type eq 'GLOB')
    {
      my $name1=$$d1;
      $name1=~s/^\*//;
      my $name2=$$d2;
      $name2=~s/^\*//;

      push @p1,'*', $name1;
      push @p2,'*', $name2;

      push @msg, $patchDOM->('change', \@p1 ,\@p2);

      my ($k,$g_d1,$g_d2)=(undef,undef,undef);

      if (defined *$d1{SCALAR} and defined(${*$d1{SCALAR}})) {
	$g_d1 = *$d1{SCALAR};
      }
      elsif (defined *$d1{ARRAY}) {
	$g_d1 = *$d1{ARRAY};
      }
      elsif (defined*$d1{HASH}) {
	$g_d1 = *$d1{HASH};
      }
      elsif (defined*$d1{GLOB}) {
	$g_d1 = *$d1{GLOB};
	loop_det($g_d1, @p1) and return ();
      }
      else {
	die $name1;
      }

      if (defined *$d2{SCALAR} and defined(${*$d2{SCALAR}})) {
	$g_d2 = *$d2{SCALAR};
      }
      elsif (defined *$d2{ARRAY}) {
	$g_d2 = *$d2{ARRAY};
      }
      elsif (defined*$d2{HASH}) {
	$g_d2 = *$d2{HASH};
      }
      elsif (defined*$d2{GLOB}) {
	$g_d2 = *$d2{GLOB};
      }
      else {
	die $name2;
      }

      my @msg = ( compare($g_d1, $g_d2, \@p1, \@p2));

      $do_resolv_patch or return @msg;
      return resolve_patch(@msg);

    }
  ######################################## !!!!! CODE REF COMPARE
  elsif ($ref_type eq 'CODE') {      # cannot compare this type

    #push @msg,$patchDOM->('change', \@p1, [@p2, '@', $i ], undef, $d2->[$i])
    return ();
  }
  ######################################## !!!!! What's that ?
  else {
    die 'unknown type /'.$ref_type.'/ '.join('',@p1);
  }
  return ();
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub applyPatch($@) { # modify a dom source with a patch
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
  my $dom = shift();


=item I<applyPatch>(<tree>, <patch 1> [, <patch N>] )

applies the patches to the <tree> (perl data structure)
<patch1> [,<patch N> ] is the list of your patches to apply
supported patch format should be text or dom types,
the patch should a clear description of a modification
no '?' modifier or ambiguities)

Return the modified dom, die if patch are badly formated

EX:
    applyPatch([1,2,3],'add(,@4)=4')
    return [1,2,3,4]

=back

=cut

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
  debug 'applyPatch('.__d($dom).') :';
  my (@remove,@add,@change,@move);

  while (@_) { # ordering the patch operations
    my $p = pop;

    (ref($p) eq 'HASH')
      or ($p)=textPatch2DOM($p);
    debug(domPatch2TEXT($p));

    eval 'push @'.$p->{action}.', $p;';
    $@ and die 'applyPatch() : '.$@;
  }

  my ($d,$t);
  local $Data::Dumper::Purity=1;

  my ($d1,$d2,$d3,$d4,$d5);
  my ($t1,$t2,$t3,$t4,$t5);

  $Data::Dumper::Varname='d';
  my $patch_eval='$d='.Dumper($dom).";\n";

  $Data::Dumper::Varname='t';
  $patch_eval .= '$t='.Dumper($dom).";\n";

  my $post_eval;

  my $r;
  foreach $r (@remove) {
    my @porig = @{$r->{path_orig}};

    my $key =  pop @porig;
    my $type = pop @porig;

    if ($type eq '@') {
      $patch_eval .= 'splice @{'.$path2eval__->('$d',undef,@porig) ."},$key,1;\n";
    }
    else {
      $patch_eval .= 'delete '.$path2eval__->('$d',undef,@porig,$type,$key) .";\n";
    }
  }

  my $m;
  my @remove_patch = sort
		 {
		   # the array indexes order from smallest to biggest
		   if (${$a->{path_orig}}[-2] eq '@') {
		     return (${$a->{path_orig}}[-1] >
			     ${$b->{path_orig}}[-1])
		   }
		   # smallest path after bigger ones
		   return $#{$a->{path_orig}} < $#{$b->{path_orig}};
		 } @move;

  foreach $m (@remove_patch) {
    my @porig = @{$m->{path_orig}};

    my $key =  pop @porig;
    my $type = pop @porig;

    if ($type eq '@') {
      $patch_eval .= 'splice @{'.$path2eval__->('$d',undef,@porig)."},$key,1;\n";
    }
    else {
      $patch_eval .= 'delete '.$path2eval__->('$d',undef,@porig,$type,$key) .";\n";
    }
  }

  foreach $m (@remove_patch) {
    my @porig = @{$m->{path_orig}};
    $patch_eval .= $path2eval__->('$d',undef,@{$m->{path_dest}}).
      ' = '.$path2eval__->('$t',undef,@porig).";\n";
  }


  my $a;
  foreach $a (@add) {
    $patch_eval .=
      $path2eval__->('$d',undef,@{$a->{path_dest}}).
	' = '.__d($a->{val_dest}) .";\n";
  }
  my $c;
  foreach $c (@change) {
    $patch_eval .=
      $path2eval__->('$d',undef,@{$c->{path_dest}}).
	' = '.__d($c->{val_dest}).";\n";
  }

  $patch_eval = $patch_eval.'$d;';

  my $res = eval($patch_eval);

  debug "\nEval=>> $patch_eval >>=".__d($res).".\n";

  $@
    and
      die 'applyPatch() : '.$patch_eval.$@;

  return $res
}

=back

=head2 Conversion Methods

=over 4

=cut


##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub domPatch2TEXT(@) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

=over 4

=item I<domPatch2TEXT>(<patch 1>, <patch 2> [,<patch N>])

convert a list of patches formatted in perl dom (man perldsc)
into a readable text format.
Mainly used to convert the compare result (format dom)

ARGS:
   a list of <patch in dom format>

Return a list of patches in TEXT mode

EX:
   domPatch2TEXT($patch1)
   returns 'change(@0$%a,@0$%a)="toto"/=>"tata"'

=cut

  my @res;
  foreach (@_) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

    (ref($_) eq 'HASH') and do {
      die 'domPatch2TEXT(): bad internal dom structure '.Dumper($_) unless(exists $_->{action});
      push @res,
	$patchText->($_->{action},
		     $_->{path_orig},
		     $_->{path_dest},
		     $_->{val_orig},
		     $_->{val_dest});
      next
    } or
    (ref($_) eq 'ARRAY') and do {
      push @res,join '', @{$_};
      next
    } or
      die 'unknown internal dom structure ';
  }

  # we logically don't want the array size=1 but to have the only result
  # from the only one arg given in input 
  return shift(@res) if ($#_ ==0 and !wantarray);
  return @res;
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub domPatch2IHM(@) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

=item I<domPatch2IHM>(<patch 1>, <patch 2> [,<patch N>])

convert a list of patches in DOM format (internal Data;;Deep format)
into a IHM format.
Mainly used to convert the compare result (format dom)

ARGS:
   a list of <patch in dom format>

Return a list of patches in IHM mode
   IHM format is not convertible

EX:
   C<domPatch2IHM>($patch1)
   returns
       '"toto" changed in "tata" from @0$%a
                       into @0$%a
=cut


  my ($msg,$patch);

  foreach $patch (@_) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
    $_ = $patch->{action};

    /^add$/ and ($msg .= __d($patch->{val_orig}).' added')
      or
	/^remove$/ and ($msg .= __d($patch->{val_orig}).' removed')
	  or 
	    /^move$/ and ($msg .= 'Moved ')
	      or 
		/^change$/ and ($msg .= __d($patch->{val_orig})
				.' changed in '
				.__d($patch->{val_dest}));
    my $l = length($msg);
    my $MAX_COLS=40;
    if ($l>$MAX_COLS) {
      $msg .= "\n   from ".join('',@{$patch->{path_orig}});
      $msg .= "\n   into ".join('',@{$patch->{path_dest}});
    }
    else {
      $l-=($msg=~ s/\n//g);
      $msg .= ' from '.join('',@{$patch->{path_orig}});
      $msg .= "\n".(' 'x $l).' into '.join('',@{$patch->{path_dest}});
    }
    $msg .= "\n";
  }
  return $msg;
}

##############################################################################
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
sub textPatch2DOM(@) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

=item I<textPatch2DOM>(<text patch 1>, <text patch 2> [,<text patch N>])

convert a list of patches formatted in text (readable text format format)
to a perl DOM format (man  perldsc).
Mainly used to convert the compare result (format dom)

ARGS:
   a list of <patch in text format>

Return a list of patches in dom mode

EX:
   C<textPatch2DOM>( 'change(@0$%a,@0$%a)="toto"/=>"tata"',
                        'move(... '
                      )

returns (
   { action=>'change',
     path_orig=>['@0','$','%a'],
     path_dest=>['@0','$','%a'],
     val_orig=>"toto",
     val_dest=>"tata"
   },
   { action=>'move',
     ...
   });

=cut

  my @res;
  while (@_) {
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
    my $patch=pop;

    debug "textPatch2DOM in ".$patch;

    my ($p1,$p2,$v1,$v2);
    $patch =~ s/^(\w+)\(// or die 'Data::Deep::textPatch2DOM / bad patch format :'.$patch.'  !!!';

    my $action = $1; # or die 'action ???';

    ( $patch =~ s/^([^,]*?),//
    ) and $p1 = $pathText2Dom->($1);

    ( $patch =~ s/^([^\(]*?)\)=//
    ) and $p2 = $pathText2Dom->($1);

    if ($action ne 'move') {
      my $i = index($patch, '/=>');
      if ($i ==-1 ) {
	($action eq 'add') && ($v2 = $patch) or ($v1 = $patch);
      }
      else {
	$v1 = substr($patch, 0, $i);
	$v2 = substr($patch, $i+3);
      }
    }
    my $a = eval($v1);
    die "textPatch2DOM() error in eval($v1) : ".$@ if ($@);

    my $b = eval($v2);
    die "textPatch2DOM() error in eval($v2) : ".$@ if ($@);

    #debug Dumper($patchDOM->($action, $p1, $p2, $a, $b));
    push @res,$patchDOM->($action, $p1, $p2, $a, $b);
  }

  # we logically don't want the array size=1 but to have the only result
  # from the only one arg given in input 
  return shift(@res) if ($#_ ==0 and !wantarray);
  return @res;
}


=begin end

=head1 AUTHOR


Data::Deep was written by Matthieu Damerose I<E<lt>damo@cpan.orgE<gt>> in 2005.

=cut


   ###########################################################################
1;#############################################################################
__END__ Deep::Manip.pm
###########################################################################


