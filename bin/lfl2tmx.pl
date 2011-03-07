#!/usr/bin/perl -sw
# $Id$

# @file lfl2tmx.pl
# @brief Creates a TMX from aligned plain text file pairs.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologiesm
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada



use strict;
use XML::Writer;

our ($x, $v);

# Prototype declaration for recursive function.
sub process(@);

my $writer = new XML::Writer( DATA_MODE => 'true', DATA_INDENT => 2 );

sub process(@) {
   print STDERR join(":", @_)."\n\n" if ($v);
   foreach my $item (@_) {
      # Clean up what will also become the id.
      $item =~ s#^\./##o;
      if( -d $item ) {
         # Load the names of all things in this
         # directory into an array
         my @sessions = (  );
         opendir( DIR, $item );
         my @files = grep( /\.id$/, readdir( DIR ));
         print STDERR join(":", @files) if ($v);
         foreach my $s (@files ) {
            next if( $s eq '.' or $s eq '..' );
            $s =~ s/\.id$//;
            push( @sessions, "$item/$s" );
         }
         closedir( DIR );

         # recurse on items in the directory
         foreach my $s ( @sessions ) {
            process( ("$s") );
         }
      }
      else {
         open (E, "${item}_en.al") or die "Unable to open ${item}_en.al";
         open (F, "${item}_fr.al") or die "Unable to open ${item}_fr.al";
         while (defined(my $e = <E>) and defined(my $f = <F>)) {
            chomp $e;
            chomp $f;
            if ($x) {
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
$writer->dataElement('note', 
   "Cette TMX est distribuée par le Conseil national de recherches Canada. Contact: Samuel Larkin (samuel.larkin\@cnrc-nrc.gc.ca).\nPrière de lire les restrictions légales dans http://www.parl.gc.ca/information/about/copyright/permission_hoc.asp?Language=F. (permission_hoc_fr.txt est une copie de cette information en date du 7 mars 2011).\nLe CNRC désire remercier Francis Morin et ses collègues des Services d’information de la Chambre des communes pour leur aide à la production de ce corpus.",
   'xml:lang'=>'FR-CA');
$writer->dataElement('note',
   "This TMX is distributed by the National Research Council Canada. Contact: Samuel Larkin (samuel.larkin\@cnrc-nrc.gc.ca).\nSee http://www.parl.gc.ca/information/about/copyright/permission_hoc.asp?Language=E for legal restrictions. (permission_hoc_en.txt is a copy of this information as of 7 March 2011).\nNRC wishes to thank Francis Morin and his colleagues from the House of Commons Information Services for their help in producing this corpus.",
   'xml:lang'=>'EN-CA');
$writer->endTag(  );  # ends header
$writer->startTag( 'body' );

process(@ARGV); 

$writer->endTag(  );   # ends  body
$writer->endTag(  );   # ends tmx
$writer->end(  );  # ends document

