# Copyright (c) 2004 - 2007, Sa Majeste la Reine du Chef du Canada /
# Copyright (c) 2004 - 2007, Her Majesty in Right of Canada
#
# This software is distributed to the GALE project participants under the terms
# and conditions specified in GALE project agreements, and remains the sole
# property of the National Research Council of Canada.
#
# For further information, please contact :
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# See http://iit-iti.nrc-cnrc.gc.ca/locations-bureaux/gatineau_e.html


# $Id$
#
# LexiTools.pm
# PROGRAMMER: George Foster / UTF-8 adaptation by Michel Simard
# 
# COMMENTS: POD at end of file.


# TODO:
# - fix $main::bla for args in tokenize.pl - and in prog.pl, for that matter
# - add "..." handling to split_sentences
# - markup options in tokenize.pl...
# - what about common capitalization for seed stuff too? eg I, some proper nouns
# - make simple abbr / complex abbr selectable

use utf8;

package ULexiTools;

use strict;
use warnings;
require Exporter;

our (@ISA, @EXPORT);

@ISA = qw(Exporter);
@EXPORT = (
    "get_para", "tokenize", "split_sentences",
    "get_tokens", "get_token",
    "matches_known_abbr_en", "matches_known_abbr_fr",
    "good_turing_estm"
);

# Module global stuff.

our %known_abbr_hash_en;
our %known_abbr_hash_fr;
our %short_stops_hash_en;
our %short_stops_hash_fr;

our ($apostrophes, $quotes, $hyphens, $splitleft, $splitright);
$apostrophes = quotemeta("\`\'‘’’‘");
$quotes = quotemeta("\"“«»");
$hyphens = quotemeta("‐‑‒–—―-");
$splitleft = qr/[\"“«\$\#]|[${hyphens}]+|‘‘|‘‘|\'\'?|\`\`?/;
$splitright = qr/[\"»!,:;\?%.]|[${hyphens}]+|’’|’’|\'\'?|\.{2,4}/;


my @known_abbrs_en = qw {
    acad ad adm aka al am apr aug ba bc blvd bsc btw c ca capt cdn ceo cf 
    cm cmdr c/o co col com comdr comdt corp dec deg dept depts desc dir dr
    drs ed eds edt edu eg eng engr est et etc ext fax feb febr fig figs fri
    ft fwd fyi g gb/s gmt hon hr hrs i ie ii iii inc info isbn iv ix jan
    janu jul jun kb/s kg kgs km ko lb lbs lieut lt ltd m ma mar may max meg
    messrs mg mhz min mins mlle mlles mme mmes mon mr mrs ms msec msecs msc
    n/a natl no nov novem oct p phd pls pm pp pps pres prof profs ps pub re
    rel rep rept rev revd revds rtfm rsvp sat sec secs secy sen sens sep
    sept sgt st ste sun tbsp tbsps tech tel thu thur thurs tko tsp tsps tue
    tues txt tv u univ usa v vi vii viii vol vols vs wed wk wks wrt www x
    xi xii xiii xiv xv xx yr yrs 
    chas
};

my @known_abbrs_fr = qw {
    acad ad adm aka al am appt ardt av avr ba bc bd blvd bsc cap cdn ceo cf
    c cial cm cmdr c/o co col com comdr comdt corp dec déc deg dept depts
    desc dim dir dr drs ed eds edt edu eg eng engr est et etc ex ext f fax
    fév févr fig figs fwd fyi g gb/s gmt ha hon hr hrs i ie ii iii inc ind
    ing info isbn iv ix jan janv jeu juil kb/s kg kgs km ko lb lbs lieut lt
    ltd lun m ma mar max me meg merc messrs mg mgr mhz min mins mlle mlles
    mm mme mmes mr mrs ms msec msecs msc n/a natl nb no nov novem oct p pm
    pp pps phd pl pres prés prof profs ps pub r re rech ref rel rep rept
    rev revd revds rtfm rstp rsvp sam sec secs secy sen sens sep sept sgt
    st ste sté stp svp tbsp tbsps tech tel tél tko tsp tsps txt tv u univ
    usa v ven vend vi vii viii vol vols www x xi xii xiii xiv xv xx
    chas
};

# short stop words that can end a sentence
my @short_stops_en = qw { 
    to in is be on it we as by an at or do my he if no am us so up me go
    oh ye ox ho ab fa hi
};

my @short_stops_fr = qw { 
    de la le à et du en au un ce ne je il se ou y on si sa me où ma eu va là
    ni pu vu dû lu ça ai an su fi tu né eh te es ta os bu ri ô us nu ci if oh
    çà pû mû na ès té ah dé

};

# funky hash initializations...
@known_abbr_hash_en{@known_abbrs_en} = (1) x @known_abbrs_en;
@known_abbr_hash_fr{@known_abbrs_fr} = (1) x @known_abbrs_fr;
@short_stops_hash_en{@short_stops_en} = (1) x @short_stops_en;
@short_stops_hash_fr{@short_stops_fr} = (1) x @short_stops_fr;

# Get the next paragraph from a file. Return: text in para (including trailing
# markup, if any)

sub get_para #(\*FILEHANDLE, $one_para_per_line)
{
    local $/ = "\n";		# protect record separator against external
				# meddling
    my ($fh, $one_para_per_line) = @_;

    my ($line, $para) = ("", "");
    my $line_count = 0;
    
    # skip leading blank lines

    while ($line = <$fh>) {
	if ($line !~ /^[[:space:]]*$/o) {
	    $para .= $line;
            ++$line_count;
	    last;
	}
    }
    if ($line && ($line =~ /^[[:space:]]*<[^>]+>[[:space:]]*$/o || $one_para_per_line)) {return $para;}

    while ($line = <$fh>) {
	if ($line =~ /^[[:space:]]*$/o) {last;}
	$para .= $line;
	if ($line =~ /^[[:space:]]*<[^>]+>[[:space:]]*$/o) {last;}
    }
    
    return $para;
}

# Split a paragraph into tokens. Return list of (start,len) token positions.

sub tokenize #(paragraph, lang)
{
    my $para = shift;
    my $lang = shift || "en";
    my @tok_posits = ();

    my ($split_word, $matches_known_abbr);
    if ($lang eq "en") {
	$split_word = \&split_word_en;
	$matches_known_abbr = \&matches_known_abbr_en;
    } elsif ($lang eq "fr") {
	$split_word = \&split_word_fr;
	$matches_known_abbr = \&matches_known_abbr_fr;
    }
    else {die "unknown lang in tokenizer: $lang";}
    
    # break up into whitespace-separated chunks, pull off punc, and break up
    # words (don't switch order of subexps in main match expr!)

    while ($para =~ /(<[^>]+>)|([[:^space:]]+)/go) {
	if (defined $1) {
	    push(@tok_posits, pos($para)-len($1), len($1)); # markup
	} else {
	    my @posits = split_punc($2, pos($para) - len($2)); # real token
	    for (my $i = 0; $i < $#posits; $i += 2) {
		push (@tok_posits, 
		      &$split_word(substr($para, $posits[$i], $posits[$i+1]),
				   $posits[$i]));
	    }
	}
    }

    # Merge trailing dots with previous tokens if called for
    for (my $i = 0; $i < $#tok_posits; $i += 2) {
      if (tok_is_dot($para, $i, @tok_posits) && tok_abuts_prev($i, @tok_posits)) {
        if (context_says_abbr($para, $i, @tok_posits) ||
            &$matches_known_abbr(get_token($para, $i-2, @tok_posits)) ||
            looks_like_abbr($lang, $para, $i-2, @tok_posits)) {

          $tok_posits[$i-1]++;
          splice(@tok_posits, $i, 2);
          $i -= 2;	# account for splice
        }
      }
    }
    return @tok_posits;
}


# Split sentences, given a tokenized paragraph. Return a list of indexes into
# @para_string, giving the start token of successive sentences (except the
# 1st, incl last+1). This completely relies on the tokenizer for dot
# disambiguation, and assumes that abbrev-ending dots are never full stops.
# NB: add handling for "..." & pos "---"

sub split_sentences #(para_string, token_positions)
{
    my $para = shift;
    my @sent_posits;

    my $end_pending = 0;

    for (my $i = 0; $i < $#_; $i += 2) {
	my $tok = get_token($para, $i, @_);
	if ($end_pending) {
	    if ($tok !~ /^([${quotes})\]]|[${apostrophes}][${apostrophes}]?)$/o) {
		push(@sent_posits, $i);
		$end_pending = 0;
	    }
	} else {
	    if ($tok =~ /^[.!?]$/o) {$end_pending = 1;}
	}
    }
    push(@sent_posits, $#_+1);

    return @sent_posits;
}

# Convert token positions into actual tokens. Return a list of strings.

sub get_tokens #(para_string, token_positions)
{
    my $string = shift;
    my @tokens;

    for (my $i = 0; $i < $#_; $i += 2) {
	push @tokens, get_token($string, $i, @_);
    }
    
    return @tokens;
}

# Get the token corresponding to a given index value (0, 2, 4, ...). Return a
# string.

sub get_token #(para_string, index, token_positions)
{
    my $string = shift;
    my $index = shift;
    return $index >= 0 && $index+1 <= $#_ ?
	substr($string, $_[$index], $_[$index+1]) : "";
}

# Does token at given index immediately follow the preceding one (without
# intervening chars)?

sub tok_abuts_prev #(index, token_positions)
{
    my $index = shift;
    return $index >= 2 && $_[$index-2] + $_[$index-1] == $_[$index];
}

# Is token at current index a plain dot?

sub tok_is_dot #($para_string, index, token_positions)
{
    my $string = shift;
    my $index = shift;
    return $_[$index+1] == 1 && get_token($string, $index, @_) eq ".";
}

# Is there hard evidence from upcoming tokens (ignoring the current one), that
# we should treat current word + "." combo as an abbr (ie tokenize as
# "word.")?
# Eg, assuming current tok is "US":
# Born in the US.             -> NO, para ends here
# Born in the US., in NY      -> YES, commas are sentence-internal
# Born in the US.!            -> YES, exclamations end sentences
# Born in the US. Brucey was. -> NO, next real word is cap'd
# Born in the US. were all .. -> YES, next real word isn't cap'd
# All of these examples work the same if there is intervening punctuation whose
# status is ambiguous, eg ('Born in the US.'...), -> "US.", comma is what counts.

sub context_says_abbr #($para_string, index_of_dot, token_positions)
{
    my $string = shift;
    my $index = shift;

    # skip ambig punc
    for ($index += 2; $index < $#_; $index += 2) {
	if (get_token($string, $index, @_) !~
	    /^([${quotes}\(\)\[\]\{\}]|[${apostrophes}][${apostrophes}]?|[${hyphens}]{1,3}|[.]{2,4})$/o) {last;}
    }

    if ($index > $#_) {return 0;} # end of para

    my $tok = get_token($string, $index, @_);
    if ($tok =~ /^[,:;]$/o) {
	return 1;		# never begins a sentence
    } elsif ($tok =~ /^[.!?]/) {
	return 1;		# always ends a sentence
    } else {
	return $tok !~ /^[[:upper:]]/o;	# next real word not cap'd
    }
}

# Determine if a word matches an English known abbreviation.

sub matches_known_abbr_en #(word)
{
    my $word = shift;
    $word =~ s/[.]//go;
    return $known_abbr_hash_en{lc($word)} ? 1 : 0;
}

# Determine if a word matches a French known abbreviation.

sub matches_known_abbr_fr #(word)
{
    my $word = shift;
    $word =~ s/[.]//go;
    return $known_abbr_hash_fr{lc($word)} ? 1 : 0;
}

# Does the current token look like it is an abbreviation?

sub looks_like_abbr # (lang, para_string, index_of_abbr, token_positions)
{
    my $lang = shift;
    my $p = $_[1]+2;
    my $word = substr($_[0], $_[$p], $_[$p+1]);

    # abbr must match this pattern..
    if ($word !~ /^[[:alpha:]][[:alpha:]]?([.][[:alpha:]])*$/o) {
	return 0;
    }
    
    # but if it matches one of these, then the context must REALLY look like a
    # sentence boundary

    if ($lang eq "en") {
 	if (exists($short_stops_hash_en{lc($word)})) {return 0;}
    } elsif ($lang eq "fr") {
	if (exists($short_stops_hash_fr{lc($word)})) {return 0;}
    }
    return 1;
}
    

# Split a whitespace-bounded token into constituents. Return list of
# (start,len) atom positions.

sub split_punc #(string, offset[0])
{
    # NB: \xAB, \xBB are left and right angle quotes

    my $tok = shift;
    my $offset = shift || 0;
    my @atoms;
    
    if (!defined $tok) {return ();}

    my $tok_len = len($tok);
    my $first_char = substr($tok, 0, 1);
    my $last_char = substr($tok, $tok_len-1, 1);

    # split internal --- or ....
    if (($tok =~ /^(.*[^${hyphens}])?([${hyphens}]{2,4})([^${hyphens}].*)?$/o) ||
        ($tok =~ /^(.*[^\.])?(\.{2,4})([^\.].*)?$/o)) {
	my ($p1, $p2, $p3) = ($1, $2, $3);
	push(@atoms, split_punc($p1, $offset));
	push(@atoms, $offset+len($p1), 2);
	push(@atoms, split_punc($p3, $offset+len($p1)+len($p2)));
    }

    # split internal $ (as in 'US$30' -> 'US$ 30')
    elsif ($tok =~ /^([[:alpha:]]*\$)([[:digit:],.-]+)$/o) {
      my ($p1, $p2) = ($1, $2);
      push(@atoms, split_punc($p1, $offset));
      push(@atoms, split_punc($p2, $offset+len($p1)));
    }

    # pull off leading/trailing punc
    elsif ($tok =~ /^($splitleft)/o) {
	push(@atoms, $offset, len($1));
	if (len($1) < len($tok)) {
	    push(@atoms, split_punc(substr($tok, len($1)), $offset+len($1)));
	}
    } elsif ($tok =~ /($splitright)$/o) {
	my $l1 = $tok_len - len($1);
	if ($l1 > 0) {
	    push(@atoms, split_punc(substr($tok, 0, $l1), $offset));
	}
	push(@atoms, $offset+$l1, $tok_len - $l1);
    }
    # next 4 clauses do this:  abc) -> abc )
    #                but this: ab(c) -> ab(c)
    #                but this: ab(c)) -> ab(c) )
    #                also, this (a) -> (a) and a) -> a)
    elsif ($first_char eq "(" && $tok !~ /^(\([[:alnum:]]\)|\([^()]+\).+)$/o) { 
	push(@atoms, $offset, 1);
	push(@atoms, split_punc(substr($tok, 1), $offset+1));
    } elsif ($first_char eq "[" && $tok !~ /^(\[[[:alnum:]]\]|\[[^\[\]]+\].+)$/o) {
	push(@atoms, $offset, 1);
	push(@atoms, split_punc(substr($tok, 1), $offset+1));
    } elsif ($last_char eq ")" && $tok !~ /^(\(?[[:alnum:]]\)|.+\([^()]+\))$/o) {
	push(@atoms, split_punc(substr($tok, 0, $tok_len-1), $offset));
	push(@atoms, $offset+$tok_len-1, 1);
    } elsif ($last_char eq "]" && $tok !~ /^(\[[[:alnum:]]\]|.+\[[^\[\]]+\])$/o) {
	push(@atoms, split_punc(substr($tok, 0, $tok_len-1), $offset));
	push(@atoms, $offset+$tok_len-1, 1);
# don't need this, because we now systematically split trailing .
#     } elsif ($tok =~ /[^a-zA-Z\xC0-\xFF]\.$/o) { # thingy). -> thingy) .
#  	push(@atoms, split_punc(substr($tok, 0, $tok_len-1), $offset));
#  	push(@atoms, $offset+$tok_len-1, 1);
    } else { # keep token as is
	push(@atoms, $offset, $tok_len);
    }

    return @atoms;
}

# Split an English word into parts, eg John's -> John 's. Return list of
# (start,len) atom positions.

sub split_word_en #(word, offset)
{
    my $word = shift;
    my $os = shift || 0;
    my @atom_positions = ();
    
    if ($word !~ /^it[${apostrophes}]s/ && $word =~ /^([[:alpha:]]+)([${apostrophes}][Ss])$/o) {
	push(@atom_positions, $os, len($1), $os+len($1), len($2));
    } else {
	push(@atom_positions, $os, len($word));
    }
    return @atom_positions;
}

# Split a French word into parts, eg l'amour -> l' amour. Return list of
# (start,len) atom positions.
# TODO
# - look into splitting forms like province-c'etait, ie you can assume the - is a
#   dash if there's a legit apostr prefix in the middle of it...

sub split_word_fr #(word, offset)
{
    my $hyph_endings = 
	"je|tu|ils?|elles?|on|nous|vous|moi|toi|lui|eux|en|y|ci|ce|les?|leurs?|la|l[${apostrophes}]|donc";
    my $vowel_hyph_endings = "ils?|elles?|on|eux|en";
    
    my $word = shift;
    my $os = shift || 0;
    my @atom_positions = ();

    if ($word !~ /^(d[${apostrophes}]ailleurs|d[${apostrophes}]abord|d[${apostrophes}]autant|quelqu[${apostrophes}]un(e|s|es)?)$/oi && 
	$word =~ /^([cdjlmnst][${apostrophes}]|[[:alpha:]]*qu[${apostrophes}]|y[${hyphens}])(.+)/oi) {
        my $thing = $1;
	my $l1 = ($thing =~ /^y[${hyphens}]$/i) ? 1 : len($thing);
	push(@atom_positions, $os, $l1);
	push(@atom_positions, split_word_fr(substr($word, len($thing)),$os+len($thing)));
    } elsif ($word =~ /^(.+)-t-($vowel_hyph_endings)$/oi) {
	my $l1 = len($1);
	push(@atom_positions, split_word_fr(substr($word, 0, $l1), $os));
	push(@atom_positions, $os + $l1 + 3, len($word)-$l1-3);
    } elsif ($word !~ /rendez[${hyphens}]vous$/ && $word =~ /^(.+)[${hyphens}]($hyph_endings)$/oi) {
	my $l1 = len($1);
	push(@atom_positions, split_word_fr(substr($word, 0, $l1), $os));
	push(@atom_positions, $os + $l1 + 1, len($word)-$l1-1);
    } else {
	push(@atom_positions, $os, len($word));
    }

    return @atom_positions;
}

# Return length of a possibly-undefined string.

sub len #(string)
{
    my $string = shift;
    return defined $string ? length($string) : 0;
}

# Do good-turing smoothing on a list of word frequencies.
# Return a corresponding list of smoothed frequencies. This just wraps a call
# to the good_turing_estm program.

sub good_turing #(freq-list) 
{
    my $tmpfile = "/tmp/TMP$$";
    open(TMP, "| good_turing_estm > $tmpfile");
    print TMP join("\n", @_), "\n";
    close(TMP);
    open(TMP, "< $tmpfile");
    my @gt_freqs = <TMP>;
    close(TMP);
    unlink $tmpfile;
    return @gt_freqs;
}


1;

__END__

=head1 NAME

LexiTools - simple NL lex analysis tools

=head1 SYNOPSIS

  use LexiTools;

  code examples here ...

=head1 DESCRIPTION

This perl module groups some simple tools for lexical analysis of natural
language text: sentence boundary detection and tokenization. Input text is
assumed to be plain iso-latin1, in the following format:

=over

=item * 

Paragraphs delimited by one or more blank lines. This doesn't mean that blank
lines are essential, just that sentences are assumed never to span them.

=item * 

Markup is enclosed in angle brackets <> spanning at most one line. Whatever is
inside the brackets is not interpreted as text.

=item * 

A piece of markup that that occupies a complete line is interpreted as a
paragraph delimiter (just like a blank line).

=back

=head1 LICENSE

Copyright (c) 2004 - 2007, Sa Majeste la Reine du Chef du Canada /
Copyright (c) 2004 - 2007, Her Majesty in Right of Canada

This software is distributed to the GALE project participants under the terms
and conditions specified in GALE project agreements, and remains the sole
property of the National Research Council of Canada.

 For further information, please contact :
 Technologies langagieres interactives / Interactive Language Technologies
 Institut de technologie de l'information / Institute for Information Technology
 Conseil national de recherches Canada / National Research Council Canada
 See http://iit-iti.nrc-cnrc.gc.ca/locations-bureaux/gatineau_e.html

=head1 AUTHOR

George Foster / Michel Simard

=cut
