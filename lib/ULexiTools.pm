# @file ULexiTools.pm
# @brief Library for tokenizing, detokenizing and sentence-splitting.
# 
# @author George Foster, Michel Simard, Eric Joanis, Samuel Larkin,
#         UTF-8 adaptation by Michel Simard,
#         Spanish support added by Samuel Larkin
#
# See POD at end of file.
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2004 - 2013, Sa Majeste la Reine du Chef du Canada /
# Copyright 2004 - 2013, Her Majesty in Right of Canada


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
use File::Temp;
require Exporter;

our (@ISA, @EXPORT, @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = (
   "get_para", "tokenize", "split_sentences",
   "get_tokens", "get_token", "get_collapse_token",
   "matches_known_abbr",
   "good_turing_estm", "get_sentence",
   "setTokenizationLang", "setDetokenizationLang",
   "detokenize", "detokenize_array",
   "get_tag_re", "strip_xml_entities"
);

# Signatures so the array refs work correctly everywhere
sub get_token(\$$\@); #(para_string, index, token_positions)
sub tok_abuts_prev($\@); #(index, token_positions)
sub tok_is_dot(\$$\@); #(para_string, index, token_positions)
sub tok_is_xtag(\$$\@); #($para_string, index, token_positions)
sub context_says_abbr(\$$\@); #($para_string, index_of_dot, token_positions)
sub looks_like_abbr(\$$\@); # (para_string, index_of_abbr, token_positions)
sub len(\$); #(string)
sub matches_known_abbr($); #(word)

# Module global stuff.

# Single quotes: ascii ` and ', cp-1252 145 (U+2018) and 146 (U+2019), cp-1252/iso-8859-1 180
my $apostrophes = quotemeta("\`\'‘’´");
# Quotes: ascii ", cp-1252 147 (U+201C) and 148 (U+201D), cp-1252/iso-8859-1 171 and 187
my $quotes = quotemeta("\"“”«»");
# specifically left/right quotes and single quotes
my $leftquotes = quotemeta("‘«“\`");
my $rightquotes = quotemeta("’»”´");
# Hyphens: U+2010, U+2011, figure dash (U+2012), n-dash (cp-1252 150, U+2013),
# m-dash (cp-1252 151, U+2014), horizontal bar (U+2015), hyphen (ascii -)
my $wide_dashes = quotemeta("‐‑‒–—―");
my $hyphens = $wide_dashes . quotemeta("-");
my $splitleft = qr/[\"“«\$\#¡¿]|[$hyphens]+|‘‘?|\'\'?|\`\`?/;
my $splitright = qr/\.{2,}|[\"”»!,:;\?%.]|[$hyphens]+|’’?|\'\'?|´´?|…/;

my $debug_xtags = 0;

# Regular expressions for parsing XML tags
# Ref: http://www.w3.org/TR/REC-xml/#sec-starttags
my $tag_inner_re = qr/(?:"[^"]*"|[^">])/;
my $tag_re = qr/(?:<$tag_inner_re+>)/;
sub get_tag_re {
   return $tag_re;
}

# Modifies $_[0] in place, removing entities and replacing &gt;, &lt; and &amp;
# by the caracter they represent.
sub strip_xml_entities(\$) {
   foreach (@_) {
      $$_ =~ s/$tag_re//g;  # Remove tags
      $$_ =~ s/&gt;/>/g;    # unescape greater than
      $$_ =~ s/&lt;/</g;    # unescape less than
      $$_ =~ s/&amp;/&/g;   # unescape ampersand
   }
}

# XML tag names - the standard is not fully followed here - I only keep the
# ASCII subset of allowed characters.
# Ref: http://www.w3.org/TR/REC-xml/#NT-NameStartChar
my $tag_name_re = qr/(?:[a-zA-Z_:][a-zA-Z_:.0-9-]*)/;
# Spaces within an XML tag
# Ref: http://www.w3.org/TR/REC-xml/#NT-S
my $tag_space_re = qr/[ \x09\x0D\x0A]/;

my @known_abbrs_en = qw {
   acad adm aka al apr aug ba bc blvd bsc btw c ca capt cdn ceo cf
   cm cmdr c/o co col com comdr comdt corp dec deg dept depts desc dir dr
   drs ed eds edt edu eg eng engr est et ext fax feb febr fig figs fri
   ft fwd fyi g gb/s gmt hon hr hrs i ie ii iii info isbn iv ix jan
   janu jul jun kb/s kg kgs km ko lb lbs lib lieut lt m ma mar max meg
   messrs mg mhz min mins mlle mlles mme mmes mon mr mrs ms msec msecs msc
   n/a natl nov novem oct p phd pls pp pps pres prof profs ps pub re
   rel rep rept rev revd revds rtfm rsvp sec secs secy sen sens sep
   sept sgt st ste tbsp tbsps tech tel thu thur thurs tko tsp tsps tue
   tues txt u univ v vi vii viii vol vols vs wed wk wks wrt www x
   xi xii xiii xiv xv xx yr yrs
   chas
};

my @known_abbrs_fr = qw {
   acad ad adm aka al am appt ardt av avr ba bc bd blvd bsc cap cdn ceo cf
   c cial cm cmdr c/o co col com comdr comdt corp dec déc deg dept depts
   desc dim dir dr drs ed eds edt edu eg eng engr et ex ext f fax
   fév févr fig figs fwd fyi g gb/s gmt ha hon hr hrs i ie ii iii ind
   ing isbn iv ix jan janv juil kb/s kg kgs km ko lb lbs lib lieut lt
   lun m ma mar me meg merc messrs mg mgr mhz min mins mlle mlles
   mm mme mmes mr mrs ms msec msecs msc n/a natl nb no nov novem oct p pm
   pp pps phd pl pres prés prof profs ps r re rech ref rel rep rept
   rev revd revds rtfm rstp rsvp sec secs secy sen sep sept sgt
   st ste sté stp svp tbsp tbsps tech tél tko tsp tsps txt u univ
   usa v ven vi vii viii www x xi xii xiii xiv xv xx
   chas
};


# The following stop-words were mined from the WMT-ACL10 es corpora.
# f(word.[^$]) => frequency of word that ends witn a dot but are not at the end of a sentence (may be abbreviations)
# f(word.$) => frequency of word that ends with a dot and are at the end of a sentence.
# f(word) => frequency of word
# word     f(word.[^$])  f(word.$)  f(word)
# sr.      146145        26895      112
# op.      499           832        104
# co.      442           232        696
# st.      717           269        142
# dr.      1617          423        43
# km.      148           267        1048
# mm.      39            126        700
my @known_abbrs_es = qw {
   av avda c d da dr dra esq gob gral ing lic prof profa sr sra srta st
};

my @known_abbrs_da = qw {
   hr frk frøken fr fru
};

# short words and abbreviation-like words that can end a sentence
my @short_stops_en = qw {
   to in is be on it we as by an at or do my he if no am us so up me go
   oh ye ox ho ab fa hi se of
   un tv ei ui mp ok cn ad uk cp sr eu pm bp id
};

my @short_stops_fr = qw {
   de la le à et du en au un ce ne je il se ou y on si sa me où ma eu va là
   ni pu vu dû lu ça ai an su fi tu né eh te es ta os bu ri ô us nu ci if oh
   çà pû mû na ès té ah dé or
   tv cn cp pm bp pq gm ae ue cd fm al mg ed pc fc dp
};

# The following stop-words were mined from the WMT-ACL10 es corpora.
# f(word.[^$]) => frequency of word that ends witn a dot but are not at the end of a sentence (may be abbreviations)
# f(word.$) => frequency of word that ends with a dot and are at the end of a sentence.
# f(word) => frequency of word
# word     f(word.[^$])  f(word.$)  f(word)
#   al     82            338        1923410
#   ap     4             178        438
#   at     8             150        11289
#   cc     22            233        1036
#   ce     3             369        1900
#   cp     6             167        1765
#   da     12            137        41583
#   ed     82            303        244
#   ee     23            316        6573
#   ep     1             1296       371
#   es     32            1337       1445279
#   eu     0             130        943
#   fe     14            982        8188
#   ff     27            116        77
#   gm     1             187        2162
#   ii     101           2402       17399
#   ir     6             224        20960
#   iu     3             316        2621
#   iv     16            566        6026
#   mw     2             248        1162
#   mí     57            927        11077
#   no     2151          24012      1919963
#   pc     2             104        617
#   pp     265           3103       27447
#   se     0             106        3780348
#   si     3             93         403658
#   ss     96            249        151
#   sé     8             321        11155
#   sí     79            4967       62292
#   ti     7             2102       619
#   tv     7             207        1329
#   ue     69            11471      41734
#   uu     202           1038       3703
#   va     6             207        65371
#   ve     6             102        15142
#   vi     16            463        6302
#   xx     7             949        1790
#   ya     17            675        318626
#   yo     37            726        49211
#   él     134           8626       42908
my @short_stops_es = qw {
   al ap at cc ce cp da ed ee ep es eu fe ff gm ii ir iu iv mw mí no pc pp se
   si ss sé sí ti tv ue uu va ve vi xx ya yo él
};

my @short_stops_da = qw {
   æf æg af åg al ål am ar år at bb bi bo cd cm co cv da de dø dr
   ed eg ej el en én er et ét få fe ff fr µg gå gr hk hl hu ii iv
   ja jf jo jr km ko kø lå le ly µm må mg ml mm mø mr mv nå næ ni nr nu ny
   og øl om op os på pt rå ro ry så si sø sr tå tb te ti ud ug ve vi vu
};

# Get the next paragraph from a file. Return: text in para (including trailing
# markup, if any)

sub get_para #(\*FILEHANDLE, $one_para_per_line)
{
   local $/ = "\n";     # protect record separator against external meddling
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

my $tokenizationLang;
my $split_word;
my %short_stops_hash;
my %known_abbr_hash;
sub setTokenizationLang($) {
   if (defined $tokenizationLang) {
      $tokenizationLang eq shift or die "Error: ULexiTools library does not support calling setTokenizationLang() twice with different languages, because of regular expressions using /o with variables set in this function.";
   } else {
      $tokenizationLang = shift or die "Error: You must provide a detokenization language id.";
      if ($tokenizationLang eq "en") {
         $split_word = \&split_word_en;
         @known_abbr_hash{@known_abbrs_en} = (1) x @known_abbrs_en;
         @short_stops_hash{@short_stops_en} = (1) x @short_stops_en;
      } elsif ($tokenizationLang eq "fr") {
         $split_word = \&split_word_fr;
         @known_abbr_hash{@known_abbrs_fr} = (1) x @known_abbrs_fr;
         @short_stops_hash{@short_stops_fr} = (1) x @short_stops_fr;
      } elsif ($tokenizationLang eq "es") {
         $split_word = \&split_word_es;
         @known_abbr_hash{@known_abbrs_es} = (1) x @known_abbrs_es;
         @short_stops_hash{@short_stops_es} = (1) x @short_stops_es;
      } elsif ($tokenizationLang eq "da") {
         $split_word = \&split_word_da;
         @known_abbr_hash{@known_abbrs_da} = (1) x @known_abbrs_da;
         @short_stops_hash{@short_stops_da} = (1) x @short_stops_da;
         $leftquotes  = quotemeta("»›„“‚");
         $rightquotes = quotemeta("«‹“”‘");
         $splitleft   = qr/[\"»›„“‚\$\#¡¿]|[$hyphens]+|‘‘?|\'\'?|\`\`?/;
         $splitright  = qr/\.{2,}|[\"«‹“”‘!,:;\?%.]|[$hyphens]+|’’?|\'\'?|´´?|…/;
      }
      else {die "Error: Unknown lang in tokenizer: $tokenizationLang";}

      setDetokenizationLang($tokenizationLang); # We use some functions from the detokenizer
   }
}

# Split a paragraph into tokens. Return list of (start,len) token positions.

# EJJ note: We use the signature ($$$) instead of (\$$$) here because $para is
# modified in this method, and we don't want the changes reflected for the
# caller.
sub tokenize($$$) #(paragraph, pretok?, xtags?)
{
   die "Error: You must call setTokenizationLang(\$lang_id) first." unless(defined($tokenizationLang));

   my $para = shift;
   my $pretok = shift;
   my $xtags = shift;
   my @tok_posits = ();

   # break up into whitespace-separated chunks, pull off punc, and break up
   # words (don't switch order of subexps in main match expr!)

   # Replace non-breaking spaces by spaces (yes, it's \xA0 in Unicode too,
   # even if it's represented differently in utf-8!)
   $para =~ s/\xA0/ /g;

   my $token_re = $xtags ?
      # closer to "proper" XML markup parsing, will parse correctly formed
      # XML tags correctly, unbalanced > is taken literally, as per XML
      # specifications, unbalanced < should be rejected, but is parsed as a
      # stand-alone token because we don't want the Portage pipeline to crash.
      qr/($tag_re)|(<|[^<[:space:]]+)/ :
      # In non-XML mode, tags in angle braces are recognized and protected, as
      # long as they are preceded by whitespace.
      qr/($tag_re)|([[:^space:]]+)/;
   while ($para =~ /$token_re/go) {
      if (defined $1) {
         push(@tok_posits, pos($para)-len($1), len($1)); # markup
      } elsif ($pretok) {
         # pre-tokenized: don't retokenize, just mark token positions.
         push(@tok_posits, pos($para)-len($2), len($2)); # real token
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
   if (!$pretok) {
      for (my $i = 0; $i < $#tok_posits; $i += 2) {
         if (tok_is_dot($para, $i, @tok_posits) && tok_abuts_prev($i, @tok_posits)) {
            if (context_says_abbr($para, $i, @tok_posits) ||
                  matches_known_abbr(get_token($para, $i-2, @tok_posits)) ||
                  looks_like_abbr($para, $i-2, @tok_posits)) {
               $tok_posits[$i-1]++;
               splice(@tok_posits, $i, 2);
               $i -= 2;    # account for splice
            }
         }
      }
   }


   if ($xtags) {
      use constant {
         OPEN_TAG       => 0,
         CLOSE_TAG      => 1,
         SELF_CLOSE_TAG => 2,
         PUNCT_TOKEN    => 3,
         TEXT_TOKEN     => 4,
      };
      for (my $i = 0; $i < $#tok_posits;) {
         my $j = $i;
         my @tok_types;
         for (; $j < $#tok_posits; $j += 2) {
            last unless $j == $i || tok_abuts_prev($j, @tok_posits);
            my $token = get_token($para, $j, @tok_posits);
            if ($token =~ /^<\/$tag_name_re$tag_space_re*>$/o) {
               push @tok_types, CLOSE_TAG;
            } elsif ($token =~ /^<open_wrap $tag_inner_re+\/>$/o) {
               push @tok_types, OPEN_TAG;
            } elsif ($token =~ /^<close_wrap $tag_inner_re+\/>$/o) {
               push @tok_types, CLOSE_TAG;
            } elsif ($token =~ /^<$tag_inner_re+\/>$/o) {
               push @tok_types, SELF_CLOSE_TAG;
            } elsif ($token =~ /^$tag_re$/o) {
               push @tok_types, OPEN_TAG;
            } elsif (is_punctuation($token) || is_bracket($token)) {
               print STDOUT "TYPE SEQ BEFORE \"$token\": @tok_types\n" if $debug_xtags;
               if (grep { $_ != OPEN_TAG && $_ != SELF_CLOSE_TAG } @tok_types) {
                  print STDOUT "GREP SAID YES\n" if $debug_xtags;
                  while (@tok_types && $tok_types[-1] == OPEN_TAG) {
                     $j -= 2;
                     pop @tok_types;
                  }
               } else {
                  print STDOUT "GREP SAID NO\n" if $debug_xtags;
                  push @tok_types, PUNCT_TOKEN;
                  for ($j += 2; $j < $#tok_posits; $j += 2) {
                     last unless tok_abuts_prev($j, @tok_posits);
                     my $next_token = get_token($para, $j, @tok_posits);
                     if ($next_token =~ /^<\/$tag_name_re$tag_space_re*>$/o) {
                        push @tok_types, CLOSE_TAG;
                     } elsif ($next_token =~ /^<close_wrap $tag_inner_re+\/>$/o) {
                        push @tok_types, CLOSE_TAG;
                     } elsif ($next_token =~ /^<open_wrap $tag_inner_re+\/>$/o) {
                        last; # we stop at an open tag
                     } elsif ($next_token =~ /^<$tag_inner_re+\/>$/o) {
                        push @tok_types, SELF_CLOSE_TAG;
                     } else {
                        last; # text, or other open tags
                     }
                  }
               }
               last;
            } else {
               push @tok_types, TEXT_TOKEN;
            }
         }
         if ($j == $i + 2) {
            print STDOUT "STAND-ALONE: ", get_token($para, $i, @tok_posits), "\n" if $debug_xtags;
            $i += 2;
            next;
         }
         # Now we know tokens [$i, $j) abut each other and the non-tag content
         # is either a single punctuation mark or all non-punctuation text.
         my @open_stack;
         my @left_tags;
         my @right_tags;
         my @inner_tags;
         my $found_non_tag = 0;
         for (my $k = $i; $k < $j; $k += 2) {
            if (tok_is_xtag($para, $k, @tok_posits)) {
               if ($found_non_tag) {
                  push @right_tags, $k;
               } else {
                  push @left_tags, $k;
               }
            } else {
               $found_non_tag = 1;
               if (@right_tags) {
                  push @inner_tags, @right_tags;
                  @right_tags = ();
               }
            }
         }
         my @inner_matched = (0) x scalar(@inner_tags);
         FOR_INNER_I: for (my $inner_i = 0; $inner_i <= $#inner_tags; ++$inner_i) {
            next if ($inner_matched[$inner_i]); # already found match, no need to look again.
            my $tag = get_token($para, $inner_tags[$inner_i], @tok_posits);
            if ($tag =~ /^<open_wrap $tag_inner_re*\bid="(\d+)"$tag_inner_re*\/>$/o) {
               # TMX opening tag, wrapped in an open_wrap tag.
               my $open_id = $1;
               foreach my $subsequent_tag (@inner_tags[$inner_i+1 .. $#inner_tags], @right_tags) {
                  my $othertag = get_token($para, $subsequent_tag, @tok_posits);
                  if ($othertag =~ /^<close_wrap $tag_inner_re*\bid="(\d+)"$tag_inner_re*\/>$/o &&
                      $open_id eq $1) {
                     $inner_matched[$inner_i] = 1;
                  }
               }
            } elsif ($tag =~ /^<close_wrap $tag_inner_re*\bid="(\d+)"$tag_inner_re*\/>$/o) {
               # TMX closing tag, wrapped in a close_wrap tag.
               my $close_id = $1;
               foreach my $preceeding_tag (@left_tags, @inner_tags[0 .. $inner_i-1]) {
                  my $othertag = get_token($para, $preceeding_tag, @tok_posits);
                  if ($othertag =~ /^<open_wrap $tag_inner_re*\bid="(\d+)"$tag_inner_re*\/>$/o &&
                      $close_id eq $1) {
                     $inner_matched[$inner_i] = 1;
                  }
               }
            } elsif ($tag =~ /^<($tag_name_re)$tag_inner_re*>$/o) {
               # Regular opening tag (e.g., XLIFF)
               my $tagname = $1;
               print "INNER OPEN TAG $tagname\n" if $debug_xtags;
               # tag is opening tag, see if it's closed later in the same string
               foreach my $subsequent_tag (@inner_tags[$inner_i+1 .. $#inner_tags], @right_tags) {
                  my $othertag = get_token($para, $subsequent_tag, @tok_posits);
                  if ($othertag =~ /^<\/$tagname$tag_space_re*>$/) {  # Don't put /o here!
                     $inner_matched[$inner_i] = 1;
                     print "MATCHING INNER CLOSING TAG $othertag\n" if $debug_xtags;
                     next FOR_INNER_I;
                  }
               }
            } elsif ($tag =~ /^<\/($tag_name_re)$tag_space_re*>$/o) {
               # Regular closing tag (e.g., XLIFF)
               my $tagname = $1;
               # tag is closing tag, see if it's opened earlier in the same string
               foreach my $preceeding_tag (@left_tags, @inner_tags[0 .. $inner_i-1]) {
                  my $othertag = get_token($para, $preceeding_tag, @tok_posits);
                  if ($othertag =~ /^<$tagname(?:$tag_space_re$tag_inner_re*|)>$/) {  # Don't put /o here!
                     $inner_matched[$inner_i] = 1;
                     next FOR_INNER_I;
                  }
               }
            }
         }

         if ($debug_xtags) {
            print STDOUT "LEFT: @left_tags  INNER: @inner_tags  RIGHT: @right_tags\n";
            print STDOUT "INNER MATCHES: @inner_matched\n";
            print STDOUT "BEFORE: ", get_token($para, $i, @tok_posits);
            for (my $k = $i+2; $k < $j; $k += 2) {
               print STDOUT " | ", get_token($para, $k, @tok_posits);
            }
            print STDOUT "\n";
         }

         if ((@inner_tags && !grep {$_ == 0} @inner_matched) || !$found_non_tag) {
            # If all inner tags are matched, or if there is no non-tag part,
            # glue the whole thing back as one token
            my $merge_end = $j;
            for (my $k = $i + 2; $k < $j; $k += 2) {
               $tok_posits[$i+1] += $tok_posits[$k+1];
            }
            splice(@tok_posits, $i+2, $j-$i-2);
            $j = $i + 2;
            @left_tags = @right_tags = ();
         } else {
            # glue the right tags back on, if any
            if (@right_tags) {
               my $k = $right_tags[0]-2;
               for (@right_tags) {
                  $tok_posits[$k+1] += $tok_posits[$_+1];
               }
               splice(@tok_posits, $k+2, 2*scalar(@right_tags));
               $j -= 2*scalar(@right_tags);
            }
            # inner tags are glued to the following token if they're opening or
            # self-closing, or to the previous token if they're closing
            if (@inner_tags) {
               print "TYPE SEQ @tok_types\n" if $debug_xtags;
               foreach my $k (reverse @inner_tags) {
                  print "INNER TAG $k TYPE $tok_types[($k-$i)/2]\n" if $debug_xtags;
                  if ($tok_types[($k-$i)/2] == CLOSE_TAG) {
                     $tok_posits[$k-1] += $tok_posits[$k+1];
                     splice(@tok_posits, $k, 2);
                  } else {
                     $tok_posits[$k+1] += $tok_posits[$k+3];
                     splice(@tok_posits, $k+2, 2);
                  }
                  $j -= 2;
               }
            }
            # glue the left tags back on, if any
            if (@left_tags) {
               die "Error: left tag" unless $left_tags[0] == $i;
               for (@left_tags) {
                  $tok_posits[$i+1] += $tok_posits[$_+2+1];
               }
               splice(@tok_posits, $i+2, 2*scalar(@left_tags));
               $j -= 2*scalar(@left_tags);
            }
         }

         if ($debug_xtags) {
            print STDOUT "AFTER: ", get_token($para, $i, @tok_posits);
            for (my $k = $i+2; $k < $j; $k += 2) {
               print STDOUT " | ", get_token($para, $k, @tok_posits);
            }
            print STDOUT "\n";
         }
         $i = $j;
      }
   }

   return @tok_posits;
}


# Split sentences, given a tokenized paragraph. Return a list of indexes into
# @para_string, giving the start token of successive sentences (except the
# 1st, incl last+1). This completely relies on the tokenizer for dot
# disambiguation, and assumes that abbrev-ending dots are never full stops.
# TODO: add handling for "..." & pos "---"

sub split_sentences(\$\@) #(para_string, token_positions)
{
   my $para = shift;
   my $token_positions = shift;

   my @sent_posits;

   my $end_pending = 0;

   for (my $i = 0; $i < $#$token_positions; $i += 2) {
      my $tok = get_token($$para, $i, @$token_positions);
      if ($end_pending) {
         next if ( $tok =~ /^[!?]$/ );  # Spanish cases where [!?]{2,} => i.e. !!! but also .!!??
         if ($tok !~ /^([$quotes\)\]]|[$apostrophes]{1,2}|<\/[^>]+>)$/o ||
             $tok =~ /^[$leftquotes]{1,2}/ ||
             $tok =~ /^[¡¿]$/) {
            push(@sent_posits, $i);
            $end_pending = 0;
         }
      } else {
         if ($tok =~ /^[.!?]$/o) {$end_pending = 1;}
      }
   }
   push(@sent_posits, $#$token_positions+1);

   return @sent_posits;
}

# Convert token positions into actual tokens. Return a list of strings.

sub get_tokens(\$\@) #(para_string, token_positions)
{
   my $string = shift;
   my $token_positions = shift;
   my @tokens;

   for (my $i = 0; $i < $#$token_positions; $i += 2) {
      push @tokens, get_token($$string, $i, @$token_positions);
   }

   return @tokens;
}

# Get the token corresponding to a given index value (0, 2, 4, ...).
# Return a string.

sub get_token(\$$\@) #(para_string, index, token_positions)
{
   my $string = shift;
   my $index = shift;
   my $token_positions = shift;
   return $index >= 0 && $index+1 <= $#$token_positions ?
      substr($$string, $token_positions->[$index], $token_positions->[$index+1]) : "";
}

#
# Get the token corresponding to a given index value (0, 2, 4, ...) and perform
# hyphens and elipsis collapse.
# Return a string.

sub get_collapse_token(\$$\@$) #(para_string, index, token_positions, nocollapse)
{
   my $string = shift;
   my $index = shift;
   my $token_positions = shift;
   my $nocollapse = shift || 0;
   my $tok = get_token($$string, $index, @$token_positions);

   unless ($nocollapse) {
      if (($tok =~ /^(.*[^$hyphens])?([$hyphens]{2,4}|[$wide_dashes])([^$hyphens].*)?$/o) ||
          ($tok =~ /^(.*[^\.])?(\.{2,4}|…)([^\.].*)?$/o)) {
         my ($p1, $p2, $p3) = ($1, $2, $3);
         $tok = "";
         $tok .= $p1 if (defined $p1);
         $tok .= substr($p2, 0, length($p2) == 1 ? 1 : 2);
         $tok .= $p3 if (defined $p3);
      }
   }
   return $tok;
}

# Get the sentence corresponding to a given index value (0, 2, 4, ...). Return a
# string.

sub get_sentence(\$$$) #(para_string, start, end)
{
   my $string = shift;
   my $start = shift;
   my $end = shift;
   return ($start >= 0 and $end > $start)
        ? substr($$string, $start, $end - $start) : "";
}

# Does token at given index immediately follow the preceding one (without
# intervening chars)?

sub tok_abuts_prev($\@) #(index, token_positions)
{
   my $index = shift;
   my $token_positions = shift;
   return $index >= 2 &&
          $token_positions->[$index-2] + $token_positions->[$index-1]
            == $token_positions->[$index];
}

# Is token at current index a plain dot?

sub tok_is_dot(\$$\@) #($para_string, index, token_positions)
{
   my $string = shift;
   my $index = shift;
   my $token_positions = shift;
   return $token_positions->[$index+1] == 1 &&
          get_token($$string, $index, @$token_positions) eq ".";
}

sub tok_is_xtag(\$$\@) #($para_string, index, token_positions)
{
   my $string = shift;
   my $index = shift;
   my $token_positions = shift;
   return $token_positions->[$index+1] > 2 &&
          get_token($$string, $index, @$token_positions) =~ /^$tag_re$/o;
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

sub context_says_abbr(\$$\@) #($para_string, index_of_dot, token_positions)
{
   my $string = shift;
   my $index = shift;
   my $token_positions = shift;

   # skip ambig punc
   for ($index += 2; $index < $#$token_positions; $index += 2) {
      if (get_token($$string, $index, @$token_positions) !~
            /^([$quotes\(\)\[\]\{\}…]|[$apostrophes]{1,2}|[$hyphens]{1,3}|[.]{2,4}|$tag_re)$/o) {last;}
   }

   if ($index > $#$token_positions) {return 0;} # end of para

   my $tok = get_token($$string, $index, @$token_positions);
   if ($tok =~ /^[,:;]$/o) {
      return 1;         # never begins a sentence
   } elsif ($tok =~ /^[.!?]/) {
      return 1;         # always ends a sentence
   } elsif ($tok =~ /^[¡¿]$/) {
      # TODO: what if UU.EE. ¿a question?
      # Let's assume that this is not a mid sentence question even if it is allowed in spanish.
      return 0;
   } else {
      return $tok !~ /^[[:upper:]]/o;   # next real word not cap'd
   }
}

# Determine if a word matches a known abbreviation.
# The language used is determined by setTokenizationLang(), which initializes
# known_abbr_hash accordingly.

sub matches_known_abbr($) # (word)
{
   my $word = shift;
   $word =~ s/[.]//go;
   return $known_abbr_hash{lc($word)} ? 1 : 0;
}

# Does the current token look like it is an abbreviation?

sub looks_like_abbr(\$$\@) # (para_string, index_of_abbr, token_positions)
{
   my $para = shift;
   my $p = shift;
   my $token_positions = shift;
   my $word = substr($$para, $token_positions->[$p], $token_positions->[$p+1]);

   # abbr must match this pattern..
   if ($word !~ /^[[:alpha:]][[:alpha:]]?([.][[:alpha:]])*$/o) {
      return 0;
   }

   # but if it matches one of these, then the context must REALLY look like a
   # sentence boundary

   if (exists($short_stops_hash{lc($word)})) {return 0;}
   return 1;
}


# Split a whitespace-bounded token into constituents. Return list of
# (start,len) atom positions.

sub split_punc #(string, offset[0])
{
   my $tok = shift;
   my $offset = shift || 0;
   my @atoms;

   if (!defined $tok) {return ();}

   my $tok_len = len($tok);
   my $first_char = substr($tok, 0, 1);
   my $last_char = substr($tok, $tok_len-1, 1);

   # split internal --, ---, n-dash, m-dash, .., ..., etc.
   if (($tok =~ /^(.*[^$hyphens])?([$hyphens]{2,4}|[$wide_dashes])([^$hyphens].*)?$/o) ||
       ($tok =~ /^(.*[^\.])?(\.{2,4}|…)([^\.].*)?$/o)) {
      my ($p1, $p2, $p3) = ($1, $2, $3);
      push(@atoms, split_punc($p1, $offset));
      # NOTE: if we actually apply collapsing here, the definition of tokens
      # changes thus doing sentence splitting versus not doing sentence
      # splitting changes and yeilds different result in the case that the
      # input is "---. 1983."
      push(@atoms, $offset+len($p1), len($p2));
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
      if ($1 eq ";" and $tok =~ /&[a-z]+;$/i) {
         # Leave a trailing ; intact when it looks like an XML entity
         push(@atoms, $offset, $tok_len);
      } else {
         my $l1 = $tok_len - len($1);
         if ($l1 > 0) {
            push(@atoms, split_punc(substr($tok, 0, $l1), $offset));
         }
         push(@atoms, $offset+$l1, $tok_len - $l1);
      }
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
   #don't need this, because we now systematically split trailing .
   #} elsif ($tok =~ /[^a-zA-Z\xC0-\xFF]\.$/o) { # thingy). -> thingy) .
   #   push(@atoms, split_punc(substr($tok, 0, $tok_len-1), $offset));
   #   push(@atoms, $offset+$tok_len-1, 1);
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

   if ($word !~ /^it[$apostrophes]s/i && $word =~ /^([[:alpha:]]+)([$apostrophes][Ss])$/o) {
      push(@atom_positions, $os, len($1), $os+len($1), len($2));
   } else {
      push(@atom_positions, $os, len($word));
   }
   return @atom_positions;
}

# Split a French word into parts, eg l'amour -> l' amour. Return list of
# (start,len) atom positions.
# TODO
# - look into splitting forms like province-c'etait, ie you can assume the - is
#   a dash if there's a legit apostr prefix in the middle of it...

# exemples: ce jour-là, vas-y, y-a-t-il, y a-t-il, qu'est-ce
my ($hyph_endings, $vowel_hyph_endings);
BEGIN {
   $hyph_endings =
      "je|tu|ils?|elles?|on|nous|vous|moi|toi|lui|eux|en|y|ci|ce|les?|leurs?|la|l[àÀ]|donc";
   $vowel_hyph_endings = "ils?|elles?|on|eux|en";
}

sub split_word_fr #(word, offset)
{
   my $word = shift;
   my $os = shift || 0;
   my @atom_positions = ();

   if ($word !~ /^(d[$apostrophes]ailleurs|d[$apostrophes]abord|d[$apostrophes]autant|quelqu[$apostrophes]un(e|s|es)?|n[$apostrophes]djamena)$/oi &&
       $word =~ /^([cdjlmnst][$apostrophes]|[[:alpha:]]*qu[$apostrophes]|y[$hyphens])(.+)/oi) {
      # y-a-t-il is actually wrong, so we replace it by y a-t-il.
      my $thing = $1;
      my $l1 = ($thing =~ /^y[$hyphens]$/i) ? 1 : len($thing);
      push(@atom_positions, $os, $l1);
      push(@atom_positions, split_word_fr(substr($word, len($thing)),$os+len($thing)));
   } elsif ($word =~ /^(?:est-ce)$/io) {
      # special case for this very common combination
      push(@atom_positions, $os, len($word));
   } elsif ($word =~ /^(.+)-t-($vowel_hyph_endings)$/oi) {
      my $l1 = len($1);
      push(@atom_positions, split_word_fr(substr($word, 0, $l1), $os));
      push(@atom_positions, $os + $l1, len($word)-$l1);
   } elsif ($word !~ /rendez[$hyphens]vous$/ && $word =~ /^(.+)[$hyphens]($hyph_endings)$/oi) {
      my $l1 = len($1);
      push(@atom_positions, split_word_fr(substr($word, 0, $l1), $os));
      push(@atom_positions, $os + $l1, len($word)-$l1);
   } else {
      push(@atom_positions, $os, len($word));
   }

   return @atom_positions;
}

# Split a Spanish word into parts, eg ?????
# Return list of (start,len) atom positions.

sub split_word_es #(word, offset)
{
   my $word = shift;
   my $os = shift || 0;
   my @atom_positions = ();

   push(@atom_positions, $os, len($word));

   return @atom_positions;
}

# Split a Danish word into parts, eg ?????
# Return list of (start,len) atom positions.

sub split_word_da #(word, offset)
{
   my $word = shift;
   my $os = shift || 0;
   my @atom_positions = ();

   if ($word !~ /^it[$apostrophes]s/i && $word =~ /^([[:alpha:]]+)([$apostrophes][Ss])$/o) {
      push(@atom_positions, $os, len($1), $os+len($1), len($2));
   } else {
      push(@atom_positions, $os, len($word));
   }
   return @atom_positions;
}

# Return length of a possibly-undefined string.

sub len(\$) #(string)
{
   my $string = shift;
   return defined $$string ? length($$string) : 0;
}

# Do good-turing smoothing on a list of word frequencies.
# Return a corresponding list of smoothed frequencies. This just wraps a call
# to the good_turing_estm program.

sub good_turing #(freq-list)
{
   my $tmpfile = File::Temp::tempdir("/tmp/TPM-XXXX") . "/estimate";
   open(TMP, "| good_turing_estm > $tmpfile");
   print TMP join("\n", @_), "\n";
   close(TMP);
   open(TMP, "< $tmpfile");
   my @gt_freqs = <TMP>;
   close(TMP);
   unlink $tmpfile;
   return @gt_freqs;
}


################################################################################
# Detokenize functions

my $space=" ";
my $apos = qr/(?:'|´|’)/; # don't use ['´’]: broken in utf-8
my ($word_pre, $word_before, $word_after);
my @double_quote=();
my @single_quote=();
my @out_sentence;
my $detok_left_bracket;
my $detok_right_bracket;
my $punctuation;


my $detokenizationLang;
sub setDetokenizationLang($) # Two letters language id
{
   if (defined $detokenizationLang) {
      $detokenizationLang eq shift or die "Error: ULexiTools library does not support calling setDetokenizationLang() twice with different languages, because of regular expressions using /o with variables set in this function.";
   } else {
      # IMPORTANT NOTE ABOUT $detok_left_bracket and $detok_right_bracket: “
      # and ‘ are left out of all the character sets below to work around a bug
      # in Perl 5.8 and 5.10, fixed in 5.14.  The bug: characters above U+00FF
      # should not be in character sets, but separately placed after a |.

      $detokenizationLang = shift or die "Error: You must provide a detokenization language id.";
      #print ref($detokenizationLang), "\n";
      if ($detokenizationLang eq "es") {
         #$detok_left_bracket  = quotemeta("[({«“‘`¡¿"); # broken with Perl 5.8 or 5.10
         #$detok_right_bracket = quotemeta("])}»”’´!?"); # broken with Perl 5.8 or 5.10
         $detok_left_bracket  = qr/(?:[[({«`¡¿]|“|‘)/;
         $detok_right_bracket = qr/(?:[])}»´!?]|”|’)/;
         $punctuation = qr/[,.:;]/;
      }
      elsif ($detokenizationLang eq "da") {
         # NOTE: there is ambiguity for <“> which could probably be resolved by
         # keeping track of the opening quote for that pair „…“ or “…”.
         #$detok_left_bracket  = quotemeta("[({»›„“‚"); # broken with Perl 5.8 or 5.10
         #$detok_right_bracket = quotemeta("])}«‹“”‘"); # broken with Perl 5.8 or 5.10
         $detok_left_bracket  = qr/(?:[[({»`¡¿]|„|“|‚|›)/;
         $detok_right_bracket = qr/(?:[])}«´!?]|“|”|‘|‹)/;
         $punctuation = qr/[,.:!?;]/;
      }
      elsif ($detokenizationLang eq "fr") {
         # "«" and "»" are left out because French keeps them separate from
         # their contents.
         #$detok_left_bracket  = quotemeta("[({“‘`"); # broken with Perl 5.8 or 5.10
         #$detok_right_bracket = quotemeta("])}”’´"); # broken with Perl 5.8 or 5.10
         $detok_left_bracket  = qr/(?:[[({`]|“|‘)/;
         $detok_right_bracket = qr/(?:[])}´]|”|’)/;
         #$detok_right_bracket = qr/[\])}”’´]/;
         $punctuation = qr/(?:[,.!?;]|…|\.\.\.)/;
      }
      else {
         # Includes left double and single quotes, since they require the same
         # treatment as brackets
         # Excludes < and ‹ since we don't split them in utokenize.pl
         $detok_left_bracket = quotemeta("[({“‘`"); # broken with Perl 5.8 or 5.10
         $detok_left_bracket  = qr/(?:[[({`]|“|‘)/;
         # Includes right double and single quotes, since they require the same
         # treatment as brackets
         # Excludes > and › since we don't split them in utokenize.pl
         $detok_right_bracket = quotemeta("])}”’´"); # broken with Perl 5.8 or 5.10
         $detok_right_bracket = qr/(?:[])}´]|”|’)/;
         $punctuation = qr/[,.:!?;]/;
      }
   }
}

sub detokenize(\$) # (sent)
{
   my $sent = shift;
   #my @tokens = split(/[ ]+/, $$sent);
   my @tokens = $$sent =~ /((?:$tag_re|[^ ])+)/go;
   #print STDERR "TOKENS: ", join(" | ", @tokens), "\n";
   my @out = detokenize_array(\@tokens);
   return join("", @out);
}

sub detokenize_array(\@) # Ref Array containing words of sentence to be detokenized.
{
   my $tokens_ref = shift;

   die "Error: You must call setDetokenizationLang(\$lang_id) first." unless(defined($detokenizationLang));

   @out_sentence = ();#initialize the containers
   @double_quote = ();# assume  a pair of quotations only bound to one line of sentence.
   @single_quote = ();# it's because in the machine output, quotation without paired is normal.
   # this assumption could be taken off if the text file was grammartically correct.

   # Reset global array.
   $#out_sentence=-1;
   while( defined (my $word_pre=shift @$tokens_ref) )
   {
      if ($word_pre eq "..") {$word_pre = "...";}

      if( $#out_sentence == -1 ){ # first word just push in
         push ( @out_sentence, $word_pre);
         if( is_quote( $word_pre )){
            check_quote( $word_pre);
         }
      } else {  # if it is not first word, considering the situations(punctuations, brackets, quotes, normal words)
         $word_before= $out_sentence[-1];
         if( is_punctuation($word_pre) ){ # don't add space before the word
            push ( @out_sentence, $word_pre);
         }
         elsif ( $detokenizationLang eq "es" and $word_pre =~ /[¡¿]/ ) {
            push ( @out_sentence, $space) unless ( $word_before =~ /[¡¿]/ );
            push ( @out_sentence, $word_pre);
         }
         elsif( is_quote( $word_pre) ){ # process quote according it is start or end
            process_quote($word_pre, $word_before);
         }
         elsif( is_bracket( $word_pre)){ # process bracket according it is start or end
            process_bracket($word_pre, $word_before);
         }
         elsif (is_poss($word_pre)) {
            push ( @out_sentence, $word_pre );
         }
         elsif (is_fr_hyph_ending($word_pre)) {
            push ( @out_sentence, $word_pre);
         }
         else{
            process_word( $word_pre, $word_before);
         }
      }
   }

   return @out_sentence;
}

sub process_word #ch1, ch2
{
   my( $ch_pre, $ch_before)= @_;
   if( ($ch_pre eq "%") ){ # take care of (%)
      if ( $detokenizationLang eq "fr" ) {
         push ( @out_sentence, $space );
      }
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_price_abut_left($ch_pre, $ch_before) ) {
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_punctuation($ch_before) || is_right_bracket($ch_before)){
      push ( @out_sentence, $space);
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_left_bracket($ch_before)){
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_quote($ch_before)){
      process_quote_before($ch_pre,$ch_before);
   }
   elsif (is_prefix($ch_before)) {
      push ( @out_sentence, $ch_pre);
   }
   else{
      push ( @out_sentence, $space);
      push ( @out_sentence, $ch_pre);
   }
}

sub process_bracket #ch1, ch2
{
   my $ch_pre=shift;
   my $ch_before=shift;
   if( is_right_bracket($ch_pre)){
      push ( @out_sentence, $ch_pre);
   }
   else{
#     if( is_punctuation($ch_before)){
#        push ( @out_sentence, $ch_pre);
#     }
      if( is_quote($ch_before)){
         process_quote_before($ch_pre, $ch_before);
      }
      else{
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
}

sub process_quote_before # ch1
{
   my $ch_pre= shift;
   my $ch_before= shift;
   if ( is_double_quote($ch_before)){
      if(&double_quote_not_empty){
         push ( @out_sentence, $ch_pre);
      }
      else{
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
   elsif ( is_single_quote($ch_before)){
      if(&single_quote_not_empty){
         push ( @out_sentence, $ch_pre);
      }
      else{
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
}

sub process_quote #ch1 ,ch2
{
   my $ch_pre=shift;
   my $ch_before=shift;
   if ( is_double_quote($ch_pre)){# in end place, just push in
      if( &double_quote_not_empty ){
         push ( @out_sentence, $ch_pre);
         pop @double_quote;
      }
      else{# in start place, push a space first (changed on Dec 13 2004)
         push ( @double_quote, $ch_pre);
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
   elsif( is_single_quote($ch_pre)){
      if( $ch_before=~/s$/){# in the situations like ( someones ' something). It is not true always, but mostly.
         push ( @out_sentence, $ch_pre);
      }
      else{
         if( &single_quote_not_empty){
            push ( @out_sentence, $ch_pre);
            pop @single_quote;
         }
         else{# in start place, push a space first (changed on Dec 13 2004)
            push ( @single_quote, $ch_pre);
            push ( @out_sentence, $space);
            push ( @out_sentence, $ch_pre);
         }
      }
   }
}

sub check_quote #$ch
{
   my $ch_pre=shift;
   if ( is_double_quote( $ch_pre )){
      if( &double_quote_not_empty){
         pop @double_quote;
      }
      else{
         push (@double_quote, $ch_pre);
      }
   }
   elsif( is_single_quote($ch_pre)){
      if( &single_quote_not_empty ){
         pop @single_quote;
      }
      else{
         push (@single_quote, $ch_pre);
      }
   }
}

sub is_quote # ch
{
   my $ch_pre=shift;
   return is_double_quote($ch_pre) || is_single_quote($ch_pre);
}

sub is_double_quote # $ch
{
   my $ch_pre=shift;
   # « and » (French angled double quotes) left out intentionally, since
   # they are not glued to the text in French.
   # Angled quotes don't belong here in general, because they are treated
   # as brackets, since they are left/right specific
   return ((defined $ch_pre)&&($ch_pre =~ /^$tag_re*"$tag_re*$/o));
}

sub is_single_quote # $ch
{
   my $ch_pre=shift;
   # `, ´, ‘ and ’ (back and forward tick, English angled single quotes) left
   # out: we treat them as brackets instead, since they are left/right specific
   return ((defined $ch_pre)&&($ch_pre =~ /^$tag_re*'$tag_re*$/o));
}

sub double_quote_not_empty
{
   return ( $#double_quote>= 0);
}

sub single_quote_not_empty
{
   return ( $#single_quote>= 0);
}

sub is_special # $var1
{
   my $ch=shift;
   return (is_bracket($ch) || is_punctuation($ch) );
}

sub is_punctuation
{
   my $ch_pre=shift;
   return $ch_pre =~ m/^$tag_re*$punctuation$tag_re*$/o;
}

sub is_bracket # $ch
{
   my $ch_pre=shift;
   return ( is_left_bracket($ch_pre) || is_right_bracket($ch_pre) );
}

sub is_left_bracket # $ch
{
   my $ch=shift;
   return ($ch =~ /^$tag_re*$detok_left_bracket$tag_re*$/o);
}


sub is_right_bracket #ch
{
   #use re qw(Debug All);
   if (0) {
      my $re = qr/^(<[a]>)*[])}”’´]$/;
      use Devel::Peek;
      print "RE=$re\n";
   }
   my $ch=shift;
   return ($ch =~ /^$tag_re*$detok_right_bracket$tag_re*$/o);
   #return ($ch =~ m/^(<[a]>)*(?:[])}´]|”|’)$/o);
   #return ($ch =~ /^[$detok_right_bracket]$/o);
}

sub is_prefix # ch
{
   my $ch=shift;
   return ($detokenizationLang eq "fr" &&
           $ch =~ /^$tag_re*(?:[cdjlmnst]|^[a-z]*qu)$apos$tag_re*$/oi);
}

sub is_poss # ch
{
   my $ch=shift;
   return (($detokenizationLang eq "en" or $detokenizationLang eq "da") &&
           $ch =~ /^$tag_re*${apos}s$tag_re*$/oi);
}

sub is_fr_hyph_ending #ch
{
   my $ch=shift;
   return ($detokenizationLang eq "fr" &&
           $ch =~ /^$tag_re*-(?:t-)?$tag_re*(?:$hyph_endings)$tag_re*$/oi);
}

sub is_price_abut_left # ch1, ch2
{
   my $ch_pre=shift;
   my $ch_before=shift;
   return (($detokenizationLang eq "en" or $detokenizationLang eq "es") &&
           $ch_before =~ /^$tag_re*\$$tag_re*$/ && $ch_pre =~ /^$tag_re*\.?\d/oi);
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

Copyright (c) 2004 - 2009, Sa Majeste la Reine du Chef du Canada /
Copyright (c) 2004 - 2009, Her Majesty in Right of Canada

 For further information, please contact :
 Technologies langagieres interactives / Interactive Language Technologies
 Inst. de technologie de l'information / Institute for Information Technology
 Conseil national de recherches Canada / National Research Council Canada
 See http://iit-iti.nrc-cnrc.gc.ca/locations-bureaux/gatineau_e.html

=head1 AUTHOR

George Foster / Michel Simard / Eric Joanis / Samuel Larkin

=cut
