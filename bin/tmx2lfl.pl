#!/usr/bin/perl -sw

# tmx2lfl.pl
# 
# PROGRAMMER: Michel Simard
# 
# COMMENTS:
# 
# Groupe de technologies langagières interactives / Interactive Language Technologies Group
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2006, Conseil national de recherches du Canada / Copyright 2006, National Research Council of Canada

use strict;
use warnings;
use XML::Twig;
use Data::Dumper;
$Data::Dumper::Indent=1;

binmode STDERR, ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

my $txt = undef;

# command-line
my $HELP = 
"Usage tmx2lfl.pl {options} [ tmx-file... ]

Convert TMX (Translation Memory Exchange) files into a LFL
(line-for-line) aligned pair of text files.  Only the languages
specified with the -src and -tgt arguments are extracted (default is
en and fr), and output goes to pair of files <output>.<src> and
<output>.<tgt>, where <output> is specified with the -output option
(default is lfl-output) and <src> and <tgt> correspond to language
names given with -src and -tgt.

Note:
  The input should be a \"Well-Formed\" tmx and can be in either UCS-2 or UTF-8
  but the output will be in UTF-8.
  You can validate your tmx file by:
    # To obtain tmx14.dtd
    curl -o tmx14.dtd http://www.lisa.org/fileadmin/standards/tmx1.4/tmx14.dtd.txt
    # Valid that the tms is \"Well-Formed\"
    xmllint --noout --valid YourFile.tmx

Options:
  -output=P     Set output file prefix [lfl-output]
  -src=S        Specify source language [en]
  -tgt=T        Specify target language [fr]
  -txt=X        Specify and trigger outputing a text-only parallel corpus []
  -extra        Add an extra line space between pairs of TU's
  -verbose      Verbose mode
  -d            debugging mode.
  -help,-h      Print this thing and exit
";

our ($h, $help, $v, $d, $verbose, $output, $src, $tgt, $extra, $txt);

if (defined($h) or defined($help)) {
    print STDERR $HELP;
    exit 0;
}

$verbose = 0 unless defined $verbose;
$output = "lfl-output" unless defined $output;
$src = "en" unless defined $src;
$tgt = "fr" unless defined $tgt;
$extra = 0 unless defined $extra;

my @filename = @ARGV;


# Validate input files.
die "You don't have xmllint on your system!" if (system("which-test.sh xmllint") != 0);

foreach my $file (@filename) {
   verbose("[Checking XML well-formness of $file]");
   die " [BAD]\nFix $file to be XML well-formed." if (system("xmllint --noout $file") != 0);
   verbose("\r[Checking XML well-formness of $file] [OK]]\n");
}


# Start processing input files.
my $parser = XML::Twig->new( twig_handlers=> { tu => \&processTU, ph => \&processPH }, ignore_elts => { header => 1 } );
$parser->{tu_count} = 0;
$parser->{outfile_prefix} = $output;
$parser->{outfile} = {};
openOutfile($parser, $src);
openOutfile($parser, $tgt);

# If the user specifies a TEXT_ONLY extension, lets add two streams for those.
if ( defined($txt) ) {
   openOutfile($parser, "$src$txt");
   openOutfile($parser, "$tgt$txt");
}

# We will also keep track of the docids.
open(ID, ">:encoding(utf-8)", "$output.id") || die "Unable to open doc id file!";

foreach my $file (@filename) {
    verbose("[Reading in TMX file $file...]\n");
    $parser->parsefile($file);
}

verbose("\r[%d... Done]\n", $parser->{tu_count});

close(ID);
closeOutfiles($parser);

# $parser->flush;

exit 0;


# Callback to process ph tages.
# Here, we only extract the dashes for example like assurance-emploi.
sub processPH {
   my ($parser, $ph) = @_;
   my $string = join(" ", map(normalize($_->text_only), $ph));
   print STDERR "PH: $string\n" if ($d);
   #print STDERR "PH: " . Dumper($ph);
   #$ph->print(\*STDERR, 1);

   # Special treatment for \- \_ in compounded words.
   if ($string =~ /\\([-_])/) {
      $ph->set_text($1);
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
   print ID "$docid\n";
   if (defined($d) and $docid eq "UNKNOWN") {
      print STDERR "no docid for tuid: $tuid\n";
      #print STDERR "TU: " . Dumper($tu);
      $tu->print(\*STDERR, 1);
   }


   # Process the Translation Unit Variants.
   my @tuvs = $tu->children('tuv');
   warn("Missing variants in TU $tuid") if (!@tuvs);
   my %variants = ();
   foreach my $tuv (@tuvs) {
      #print "TUV: " . Dumper($tuv);
      #$tuv->print(\*STDERR);

      my $lang = $tuv->{att}->{'xml:lang'};
      warn("Missing language attribute in TU $tuid") unless $lang;

      my @segs = $tuv->children('seg');
      warn("No segs in TUV (TU $tuid)") unless @segs;
      #print "SEG: " . Dumper(@segs);

      $variants{$lang} = [] if not exists $variants{$lang};
      # Get content WITH the rtf markings.
      push @{$variants{$lang}}, join(" ", map(normalize($_->text), @segs));
      # Get content WITHOUT the rtf markings.
      if ( defined($txt) ) {
         push @{$variants{"$lang$txt"}}, join(" ", map(normalize($_->text_only), @segs));
      }
   }

   foreach my $lang (keys(%{$parser->{outfile}})) {
      my $segs = exists($variants{$lang}) ? join(" ", @{$variants{$lang}}) : "EMPTY_\n";
      $segs =~ s/^\s+//;   # Trim white spaces at the beginning of each line.
      $segs =~ s/\s+$//;   # Trim white spaces at the end of each line.
      print { $parser->{outfile}->{$lang} } $segs, "\n";
      print { $parser->{outfile}->{$lang} } "\n" if $extra;
      print STDERR "SEG: $segs\n" if ($d);
   }
   $parser->{tu_count} = $n + 1;

   # Delete from memory the parse tree so far.
   $parser->purge;
}

sub verbose { printf STDERR (@_) if $verbose; }

sub debug { printf STDERR (@_) if (defined($d)); }

sub normalize {
    my ($text) = @_;
    
    $text =~ s/[\n\r\t\f]/ /go; # Newlines etc. are converted to spaces
    $text =~ s/ +/ /go;         # Multiple spaces are compressed;

    return $text;
}

sub openOutfile {
    my ($parser, $lang) = @_;

    if (!exists $parser->{outfile}->{$lang}) {
        my $output = $parser->{outfile_prefix};
        my $filename = "$output.$lang";
        verbose("[Opening output file $filename]\n");
        open(my $stream, ">:encoding(UTF-8)", "$filename") || die "Can't open output file $filename";
        $parser->{outfile}->{$lang} = $stream;

        # Catch up with other files:
        for (my $i = 0; $i < $parser->{tu_count}; ++$i) {
            print { $parser->{outfile}->{$lang} } "\n";
        }

    }
    return $parser->{outfile}->{$lang};
}

sub closeOutfiles {
    my ($parser) = @_;

    for my $lang (keys %{$parser->{outfile}}) {
        close $parser->{outfile}->{$lang};
    }
}

