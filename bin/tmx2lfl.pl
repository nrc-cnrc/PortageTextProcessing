#!/usr/bin/env perl

# @file tmx2lfl.pl
# @brief Extract a parallel corpus from tmx files.
# 
# @author Samuel Larkin based on Michel Simard's work.
# 
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Conseil national de recherches du Canada /
# Copyright 2009, National Research Council of Canada

use strict;
use warnings;

BEGIN {
   # If this script is run from within src/ rather than being properly
   # installed, we need to add utils/ to the Perl library include path (@INC).
   if ( $0 !~ m#/bin/[^/]*$# ) {
      my $bin_path = $0;
      $bin_path =~ s#/[^/]*$##;
      unshift @INC, "$bin_path/../utils";
   }
}
use portage_utils;
printCopyright("tmx2lfl.pl", 2009);
$ENV{PORTAGE_INTERNAL_CALL} = 1;

# According to the change logs, text_only was added in version 3.28 but we'll
# require at least 3.32 as per commit 2b921af69.
# We will use this line to validate Portage's installation.
use XML::Twig 3.32;  # We must have text_only
use Data::Dumper;
$Data::Dumper::Indent=1;

use File::Basename;

binmode STDERR, ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";


# command-line
sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage $0 {options} [ tmx-file... ]

Convert TMX (Translation Memory Exchange) files into a LFL (line-for-line)
aligned pair of text files.  The languages specified with the -src and -tgt
arguments are extracted (if the TMX contains exactly two languages, the default
is to extract them both), and output goes to pair of files <output>.<src> and
<output>.<tgt>, where <output> is specified with the -output option (default is
lfl-output) and <src> and <tgt> correspond to language names given with -src
and -tgt.

Notes:
  The input should be a \"Well-Formed\" TMX in ASCII, UTF-16 or UTF-8;
  the output will always be in UTF-8.

  You can validate your TMX file by doing the following:
    # To obtain tmx14.dtd
    curl -o tmx14.dtd http://www.lisa.org/fileadmin/standards/tmx1.4/tmx14.dtd.txt
    # Validate that the TMX is \"Well-Formed\"
    xmllint --noout --valid YourFile.tmx

  Following http://www.gala-global.org/oscarStandards/tmx/tmx14b.html#xml:lang
  and http://www.ietf.org/rfc/rfc3066.txt, language tags in TMX files are case
  insensitive.

Options:
  -output=P     Set output file prefix [lfl-output]
  -src=S        Specify source language [auto-detect]
  -tgt=T        Specify target language [auto-detect]
  -txt=X        Specify and trigger outputing a text-only parallel corpus []
  -extra        Add an extra empty line between pairs of TU's [don't]
  -filename     If doc id is UNKNOWN, use the filename stem as the doc id [don't]
  -timestamp    Add TU creation date timestamp to doc id [don't]
  -verbose      Verbose mode
  -d            debugging mode.
  -help,-h      Print this help message and exit
";
   exit @_ ? 1 : 0;
}

use Getopt::Long;
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $debug = undef;
my $verbose = 0;
my $output  = "lfl-output";
my $extra   = undef;
my $add_filename  = undef;
my $add_timestamp = undef;
my $src = undef;
my $tgt = undef;
my $txt = undef;
GetOptions(
   extra       => \$extra,
   filename    => \$add_filename,
   timestamp   => \$add_timestamp,
   "output=s"  => \$output,
   "src=s"     => \$src,
   "tgt=s"     => \$tgt,
   "txt=s"     => \$txt,

   help        => sub { usage },
   verbose     => sub { ++$verbose },
   quiet       => sub { $verbose = 0 },
   debug       => \$debug,
) or usage "Error: Invalid option(s).";

my @filename = @ARGV;


# Validate input files.
die "Error: You don't have xmllint on your system!" if (system("which-test.sh xmllint") != 0);

my @lang_specifiers;
foreach my $file (@filename) {
   verbose("[Checking XML well-formedness of $file]");
   if (system("xmllint --stream --noout \"$file\" 2> /dev/null") != 0) {
      # YES, we rerun the command.  The first xmllint call would complain if
      # there is no dtd accessible but would still return that the TMX is valid
      # if so.  It is simpler to run it once muted and, if there are errors, to
      # rerun xmllint this time showing the user what xmllint found.
      system("xmllint --stream --noout \"$file\"");
      die "[BAD]\nError: Fix $file to be XML well-formed.";
   }
   verbose("\r[Checking XML well-formness of $file] [OK]]\n");
   
   # Quickly grab language specifiers from the TMX.
   my $spec;
   # In order to minimize dependencies and since there is no speed difference
   # between sort -u & get_voc on a small set, we will prefer the former.
   # NOTE: Why not simply call xml_grep?  xml_grep is a perl script and in the
   # case where you change your perl in your environment, this will not pickup
   # the correct perl.  This was found by the daily build because the machine
   # on which it runs is not properly installed anymore.  We prefer to keep
   # xml_grep in the pipeline because xml tag can be exploded on several lines
   # and a simple grep on the xml file becomes much harder to find the @lang
   # attribut for tuv tags only.
   #my $findLanguageTags = "grep '^[[:space:]]*<tuv' | egrep -m10 -o '(xml:)?lang=\"[^\"]+\"' | sort -u";
   my $findLanguageTags = "perl `which xml_grep` --nb_results 10 --cond 'tuv[\@xml:lang]' --cond 'tuv[\@lang]' --pretty_print record_c | egrep -m10 -o '(xml:)?lang=\"[^\"]+\"' | sort -u";
   debug("cat \"$file\" | $findLanguageTags");
   $spec .= `cat \"$file\" | $findLanguageTags`;
   while ($spec =~ /"([^\"]+)"/g) {
      push(@lang_specifiers, $1);
   }
}

# No language specifiers given by the user, let's auto-detect them.
if (not defined($src) and not defined($tgt)) {
   # Remove duplicate language identifiers.
   @lang_specifiers = keys %{{ map { $_ => 1 } @lang_specifiers }};
   unless (scalar(@lang_specifiers) == 2) {
      die "Error: Too many language identifiers to automatically extract segments.\n" 
      . "Select two language identifiers and rerun using -src=X -tgt=Y\n"
      . "Language identifiers found are: " . join(":", sort @lang_specifiers) . "\n"
      . "Too many or too few language specifiers in your input TMX.\n";
   }

   $src = $lang_specifiers[0];
   $tgt = $lang_specifiers[1];
}

# Make sure we have language specifiers for src and tgt
die "Error: You must provide a source language specifier\n" unless(defined($src));
die "Error: You must provide a target language specifier\n" unless(defined($tgt));

if ( $debug ) {
   no warnings;
   print STDERR "
   files        = @filename
   extra        = $extra
   add_filename = $add_filename
   timestamp    = $add_timestamp
   output       = $output
   src          = $src
   tgt          = $tgt
   txt          = $txt
   verbose      = $verbose
   debug        = $debug

";
}


# Start processing input files.
my $parser = XML::Twig->new( twig_handlers=> { tu => \&processTU, ph => \&processPH }, ignore_elts => { header => 1 } );
$parser->{tu_count} = 0;
$parser->{outfile_prefix} = $output;
$parser->{outfile} = {};
openOutfile($parser, $src);
openOutfile($parser, $tgt);

# If the user specifies a TEXT_ONLY extension, lets add two streams for those.
my $lc_txt;
if ( defined($txt) ) {
   openOutfile($parser, "$src$txt");
   openOutfile($parser, "$tgt$txt");
   $lc_txt = lc $txt;
}

# We will also keep track of the docids.
open(ID, ">:encoding(utf-8)", "$output.id") || die "Error: Unable to open doc id file!";

foreach my $file (@filename) {
    verbose("[Reading in TMX file $file...]\n");
    $parser->{infile} = basename($file, ".tmx");
    $parser->parsefile($file);
}

verbose("\r[%d... Done]\n", $parser->{tu_count});

close(ID);
closeOutfiles($parser);

# $parser->flush;

exit 0;


# Callback to process ph tags.
# Here, we only extract the dashes for example like assurance-emploi.
sub processPH {
   my ($parser, $ph) = @_;
   my $string = join(" ", map(normalize($_->text_only), $ph));
   debug("PH: $string\n");
   #print STDERR "PH: " . Dumper($ph);
   #$ph->print(\*STDERR, 1);

   # Special treatment for \- and \_ in compounded words.
   if ($string =~ /^\s*\\([-_])\s*$/) {
      # \_ is the RTF and Trados encoding for a non-breaking hyphen; replace it
      # by -, the regular hyphen, since it is generally used in ad-hoc ways,
      # when an author or translator doesn't like a particular line-splitting
      # choice their software has made.
      $ph->set_text("-") if ($1 eq '_');
      # \- is the rtf and Trados encoding for an optional hyphen; remove it
      $ph->set_text("") if ($1 eq '-');
      $ph->erase();
   }
}


sub processTU {
   my ($parser, $tu) = @_;

   #print "TU: " . Dumper($tu);
   my $n = $parser->{tu_count};
   verbose("\r[$n...]") if $n % 100 == 0;

   my $tuid = $tu->{att}{tuid};
   $tuid = $n unless defined $tuid;


   # Get the docid for this translation pair
   my $docid = "UNKNOWN";
   my @props = $tu->children('prop');
   foreach my $prop (@props) {
      if ($prop->{att}->{'type'} eq "Txt::Document") {
         ($docid) = split(/, /, $prop->text, 1);
         debug("DOCID: $docid\n");
      }
   }
   
   if ($add_filename and $docid eq "UNKNOWN") {
      $docid = $parser->{infile};
   }
   
   if ($add_timestamp) {
      my $creationdate = $tu->{att}{creationdate};
      $creationdate = 0 unless defined $creationdate;
      $docid .= " $creationdate";
   }
   
   print ID "$docid\n";
   if (defined($debug) and $docid eq "UNKNOWN") {
      print STDERR "no docid for tuid: $tuid\n";
      #print STDERR "TU: " . Dumper($tu);
      $tu->print(\*STDERR, 1);
   }


   # Process the Translation Unit Variants.
   my @tuvs = $tu->children('tuv');
   warn("Warning: Missing variants in TU $tuid") if (!@tuvs);
   my %variants = ();
   foreach my $tuv (@tuvs) {
      #print "TUV: " . Dumper($tuv);
      #$tuv->print(\*STDERR);

      my $lang = $tuv->{att}->{'xml:lang'};
      $lang = $tuv->{att}->{'lang'} unless $lang; # for TMX 1.1 compatibility
      warn("Warning: Missing language attribute in TU $tuid") unless $lang;
      my $lc_lang = lc $lang;

      my @segs = $tuv->children('seg');
      warn("Warning: No segs in TUV (TU $tuid)") unless @segs;
      #print "SEG: " . Dumper(@segs);

      if ($lc_lang) {
         $variants{$lc_lang} = [] if not exists $variants{$lc_lang};
         # Get content WITH the rtf markings.
         push @{$variants{$lc_lang}}, join(" ", map(normalize($_->text), @segs));
         # Get content WITHOUT the rtf markings.
         if ( defined($txt) ) {
            push @{$variants{"$lc_lang$lc_txt"}}, join(" ", map(normalize($_->text_only), @segs));
         }  
      }
   }

   foreach my $lc_lang (keys(%{$parser->{outfile}})) {
      my $segs = exists($variants{$lc_lang}) ? join(" ", @{$variants{$lc_lang}}) : "EMPTY_\n";
      $segs =~ s/^\s+//;   # Trim white spaces at the beginning of each line.
      $segs =~ s/\s+$//;   # Trim white spaces at the end of each line.
      print { $parser->{outfile}->{$lc_lang} } $segs, "\n";
      print { $parser->{outfile}->{$lc_lang} } "\n" if $extra;
      debug("SEG: $segs\n");
   }
   $parser->{tu_count} = $n + 1;

   # Delete from memory the parse tree so far.
   $parser->purge;
}

sub verbose { printf STDERR (@_) if $verbose; }

sub debug { printf STDERR (@_) if (defined($debug)); }

sub normalize {
    my ($text) = @_;
    
    $text =~ s/[\n\r\t\f]/ /go; # Newlines etc. are converted to spaces
    $text =~ s/ +/ /go;         # Multiple spaces are compressed;

    return $text;
}

sub openOutfile {
    my ($parser, $lang) = @_;
    my $lc_lang = lc $lang;

    if (!exists $parser->{outfile}->{$lc_lang}) {
        my $output = $parser->{outfile_prefix};
        my $filename = "$output.$lang";
        verbose("[Opening output file $filename]\n");
        open(my $stream, ">:encoding(UTF-8)", "$filename") || die "Error: Can't open output file $filename";
        $parser->{outfile}->{$lc_lang} = $stream;

        # Catch up with other files:
        for (my $i = 0; $i < $parser->{tu_count}; ++$i) {
            print { $parser->{outfile}->{$lc_lang} } "\n";
        }

    }
    return $parser->{outfile}->{$lc_lang};
}

sub closeOutfiles {
    my ($parser) = @_;

    for my $lc_lang (keys %{$parser->{outfile}}) {
        close $parser->{outfile}->{$lc_lang};
    }
}

