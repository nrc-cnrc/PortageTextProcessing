#!/usr/bin/env perl

# @file lfl2tmx.pl
# @brief Create a TMX from aligned plain text file pairs.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada



use strict;
use warnings;
use XML::Writer;

binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";

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
printCopyright "lfl2tmx.pl", 2011;
$ENV{PORTAGE_INTERNAL_CALL} = 1;


sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [options] {paths | files.id}

  Create a tmx from a structure of parallel file pairs and outputs it to stdout.
  Looks for X.id and creates TUs from X_en.al & X_fr.al.

CAVEAT:
  This is still Hansard-HOC hardcoded/oriented.

Options:

  -x            remove xml markup. [don't]
  -t            detokenize sentences. [don't]
  -c(opyright)  copyright notice prefix.
  -h(elp)       print this help message
  -v(erbose)    increment the verbosity level by 1 (may be repeated)
  -d(ebug)      print debugging information
";
   exit @_ ? 1 : 0;
}

use Getopt::Long;
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
GetOptions(
   help        => sub { usage },
   verbose     => \my $verbose,
   debug       => \my $debug,
   x           => \my $strip_xml,
   t           => \my $detokenize,
   "copyright=s"  => \my $copyright,
) or usage "Error: Invalid option(s).";

# Prototype declaration for recursive function.
sub process(@);

my $writer = new XML::Writer( DATA_MODE => 'true', DATA_INDENT => 2 );

sub process(@) {
   print STDERR join(":", @_) . "\n\n" if ($verbose);
   foreach my $item (@_) {
      # Clean up what will also become the id.
      $item =~ s#^\./##o;
      if( -d $item ) {
         # Load the names of all things in this
         # directory into an array
         my @sessions = (  );
         opendir( DIR, $item );
         my @files = grep( /\.id$/, readdir( DIR ));
         print STDERR join(":", @files) . "\n" if ($verbose);
         foreach my $s (@files ) {
            next if( $s eq '.' or $s eq '..' );
            $s =~ s/\.id$//;
            push( @sessions, "$item/$s" );
         }
         closedir( DIR );

         # recurse on items in the directory
         foreach my $s ( sort @sessions ) {
            process( ("$s") );
         }
      }
      else {
         my ($file_en, $file_fr);
         $file_en = "${item}_en.al";
         $file_fr = "${item}_fr.al";
         if ($strip_xml) {
            $file_en = "perl -ple 's#</?[^>]+>##go' $file_en |";
            $file_en .= " udetokenize.pl -lang=en |" if ($detokenize);

            $file_fr = "perl -ple 's#</?[^>]+>##go' $file_fr |";
            $file_fr .= " udetokenize.pl -lang=fr |" if ($detokenize);
         }
         else {
            $file_en = "udetokenize.pl -lang=en $file_en |" if ($detokenize);
            $file_fr = "udetokenize.pl -lang=fr $file_fr |" if ($detokenize);
         }

         print STDERR "E: $file_en  F: $file_fr\n" if ($debug);
         open (E, "$file_en") or die "Error: Unable to open ${item}_en.al";
         binmode E, ":encoding(UTF-8)";
         open (F, "$file_fr") or die "Error: Unable to open ${item}_fr.al";
         binmode F, ":encoding(UTF-8)";
         while (defined(my $e = <E>) and defined(my $f = <F>)) {
            chomp $e;
            chomp $f;
            if ($strip_xml) {
               # Strip xml markup.
               $e =~ s#</?[^>]+>##go;
               $f =~ s#</?[^>]+>##go;
            }
            tu("$e", "$f", $item);
         }
         close(E);
         close(F);
      }
   }
}

sub tu ($$$) {
   my $e = shift;
   my $f = shift;
   my $id = shift;

   $writer->startTag('tu');
   $writer->dataElement('prop', $id, 'type'=>'Txt::Document');
   $writer->startTag('tuv', 'xml:lang'=>'EN-CA', 'creationid'=>'lfl2tmx.pl');
   $writer->dataElement( 'seg', $e );
   $writer->endTag(  );   # ends tuv
   $writer->startTag('tuv', 'xml:lang'=>'FR-CA', 'creationid'=>'lfl2tmx.pl');
   $writer->dataElement( 'seg', $f );
   $writer->endTag(  );   # ends tuv
   $writer->endTag(  );   # ends tu
}

$writer->xmlDecl( 'UTF-8' );
#$writer->doctype("tmx", "SYSTEM", "tmx14.dtd");
print "<!DOCTYPE tmx SYSTEM \"tmx14.dtd\">\n";
$writer->startTag('tmx', 'version'=>'1.4');
# All of the following attributes are required by the dtd.
$writer->startTag( 'header',
        'creationtool'=>'lfl2tmx.pl',
        'creationtoolversion'=>'1.0.0',
        'segtype'=>'sentence',
        'o-tmf'=>'none',
        'adminlang'=>'EN-CA',
        'srclang'=>'EN',
        'datatype'=>'PlainText',
        );
if ($copyright and $copyright ne "") {
   my @copyright;

   open(C, "${copyright}_fr.txt") or die "Error: Unable to open the English copyright file.";
   binmode(C, ":encoding(UTF-8)");
   @copyright = <C>;
   close C;
   $writer->dataElement('note', 
      "\n" . join("", @copyright),
      'xml:lang'=>'FR-CA');

   open(C, "${copyright}_en.txt") or die "Error: Unable to open the English copyright file.";
   binmode(C, ":encoding(UTF-8)");
   @copyright = <C>;
   close C;
   $writer->dataElement('note',
      "\n" . join("", @copyright),
      'xml:lang'=>'EN-CA');
}
$writer->endTag(  );  # ends header
$writer->startTag( 'body' );

process(@ARGV); 

$writer->endTag(  );   # ends  body
$writer->endTag(  );   # ends tmx
$writer->end(  );  # ends document

