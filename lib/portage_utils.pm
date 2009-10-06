#!/usr/bin/perl -w

package portage_utils;

use strict;
use warnings;



# How to detect that a file was gzipped.
my $isZip = qr/\.(gz|z|Z)\s*$/;

# How to detect that a file was gzipped.
my $isBzip2 = qr/\.(bz2|bzip2|bz)\s*$/;

# How to detect that a file was gzipped.
my $isLzma = qr/\.lzma\s*$/;

our $DEBUG;


# ================= zopen ====================#

=head1 SUB

B< =============================================
 ====== zopen                             ======
 =============================================>

=over 4

=item B<DESCRIPTION>

 Portage's perl magicstream.  Tries to deduce if the stream is input or output,
 if it is compressed (.gz,z,Z,bz2,bzip2,bz,lzma), piped or just a normal file,
 and does the proper thing to open the stream.

=item B<SYNOPSIS>

 portage_utils::zopen($STREAM, $stream_name);
 portage_utils::zopen(*STREAM, $stream_name);
 portage_utils::zopen(*STREAM, "plain-text-input-file");
 portage_utils::zopen(*STREAM, "< plain-text-input-file");
 portage_utils::zopen(*STREAM, "compressed-input-file.gz");
 portage_utils::zopen(*STREAM, "< compressed-input-file.gz");
 portage_utils::zopen(*STREAM, "input pipe |");
 portage_utils::zopen(*STREAM, "> plain-text-output-file");
 portage_utils::zopen(*STREAM, "> compressed-output-file.gz");
 portage_utils::zopen(*STREAM, "| output pipe ");

 @PARAM $STREAM
 @PARAM $stream_name

 @RETURN Returns 0 if the stream was opened.

=item B<SEE ALSO>

 zout()

=back

=cut

sub zopen($$) {
   # if no argument is sent in
   if(not @_) {
      die "\n!!! ERROR: portage_utils::zopen requires input arguments! \taborting...\n";
   }
   # if we are called as a module then skip the our reference name
   elsif($_[0] and $_[0] =~ /^portage_utils/) {
      shift;
      # if no argument is sent in
      if(not @_) {
         die "\n!!! ERROR: portage_utils::zopen requires input arguments! \taborting...\n";
      }
   }

   my($STREAM, $stream_name) = @_;

   if ($stream_name =~ /^\s*(>|\|)/) {
      return zout($STREAM, $stream_name);
   }
   else {
      return zin($STREAM, $stream_name);
   }
}

# ================= zin ====================#

=head1 SUB

B< =============================================
 ====== zin                             ======
 =============================================>

=over 4

=item B<DESCRIPTION>

 Portage's perl magicstream.  Tries to deduce if the input is compressed, piped
 or just a normal file and does the proper thing to open the stream.

=item B<SYNOPSIS>

 portage_utils::zin($STREAM, $stream_name)
 portage_utils::zin(*STREAM, $stream_name)
 portage_utils::zin(*STREAM, "plain-text-input-file");
 portage_utils::zin(*STREAM, "< plain-text-input-file");
 portage_utils::zin(*STREAM, "compressed-input-file.gz");
 portage_utils::zin(*STREAM, "< compressed-input-file.gz");
 portage_utils::zin(*STREAM, "input pipe |");

 @PARAM $STREAM
 @PARAM $stream_name

 @RETURN Returns 0 if the stream was opened.

=item B<SEE ALSO>

 zout()

=back

=cut

# ----------------------------------------------------------------------------#
sub zin($$) {
   # if no argument is sent in
   if(not @_) {
      die "\n!!! ERROR: portage_utils::zin requires input arguments! \taborting...\n";
   }
   # if we are called as a module then skip the our reference name
   elsif($_[0] and $_[0] =~ /^portage_utils/) {
      shift;
      # if no argument is sent in
      if(not @_) {
         die "\n!!! ERROR: portage_utils::zin requires input arguments! \taborting...\n";
      }
   }

   my($STREAM, $stream_name) = @_;

   print "DEBUG zin with $stream_name.\n" if ($DEBUG);

   die "Don't use zin to open an output stream!!\n" if ($stream_name =~ /^\s*>/);

   # remove leading < if present
   $stream_name =~ s/^\s*<//;

   # Is this a pipe.
   if ($stream_name =~ /\|\s*$/) {
      print "DEBUG zin is a pipe.\n" if ($DEBUG);
      return open($STREAM, "$stream_name");
   }
   # Is this a bzipped 2 stream.
   elsif ($stream_name =~ /$isBzip2/) {
      print "DEBUG zin is bzip2.\n" if ($DEBUG);
      return open($STREAM, "bzip2 -cqfd $stream_name |");
   }
   # Is this a gzipped stream.
   elsif ($stream_name =~ /$isZip/) {
      print "DEBUG zin is zip.\n" if (defined $DEBUG);
      return open($STREAM, "gzip -cqfd $stream_name |");
   }
   # Is this a lzma stream.
   elsif ($stream_name =~ /$isLzma/) {
      print "DEBUG zin is lzma.\n" if ($DEBUG);
      return open($STREAM, "lzma -4 -cqfd $stream_name |");
   }
   # Assume it is a normal file.
   else {
      print "DEBUG zin is plain.\n" if ($DEBUG);
      return open($STREAM, "<$stream_name");
   }
}



# ================= zout ====================#

=head1 SUB

B< =============================================
 ====== zout                             ======
 =============================================>

=over 4

=item B<DESCRIPTION>

 Portage's perl magicstream.  Tries to deduce if the output is compressed, piped
 or just a normal file and does the proper thing to open the stream.

=item B<SYNOPSIS>

 portage_utils::zout($STREAM, $stream_name)
 portage_utils::zout(*STREAM, $stream_name)
 portage_utils::zout(*STREAM, "> plain-text-output-file");
 portage_utils::zout(*STREAM, "> compressed-output-file.gz");
 portage_utils::zout(*STREAM, "| output pipe ");

 @PARAM $STREAM
 @PARAM $stream_name

 @RETURN Returns 0 if the stream was opened.

=item B<SEE ALSO>

 zin()

=back

=cut

# ----------------------------------------------------------------------------#
sub zout($$) {
   # if no argument is sent in
   if(not @_) {
      die "\n!!! ERROR: portage_utils::zout requires input arguments! \taborting...\n";
   }
   # if we are called as a module then skip the our reference name
   elsif($_[0] and $_[0] =~ /^portage_utils/) {
      shift;
      # if no argument is sent in
      if(not @_) {
         die "\n!!! ERROR: portage_utils::zout requires input arguments! \taborting...\n";
      }
   }

   my($STREAM, $stream_name) = @_;

   print "DEBUG zout with $stream_name.\n" if ($DEBUG);

   die "Don't use zout to open an input stream!!\n" if ($stream_name =~ /^\s*</);

   # Remove one redir.
   $stream_name =~ s/^\s*>//;

   # Is this a pipe.
   if ($stream_name =~ /^\s*\|/) {
      print "DEBUG zout is a pipe.\n" if ($DEBUG);
      die "Can't append to a pipe." if ($stream_name =~ /^\s*>/);
      return open($STREAM, "$stream_name");
   }
   # Is this a bzipped stream.
   elsif ($stream_name =~ /$isBzip2/) {
      print "DEBUG zout is bzip2.\n" if ($DEBUG);
      return open($STREAM, "| bzip2 -cqf >$stream_name");
   }
   # Is this a gzipped stream.
   elsif ($stream_name =~ /$isZip/) {
      print "DEBUG zout is zip.\n" if ($DEBUG);
      return open($STREAM, "| gzip -cqf >$stream_name");
   }
   # Is this a lzma stream.
   elsif ($stream_name =~ /$isLzma/) {
      print "DEBUG zout is lzma.\n" if ($DEBUG);
      die "Can't append to a lzma file." if ($stream_name =~ /^\s*>/);
      return open($STREAM, "| lzma -cqf >$stream_name");
   }
   # Assume it is a normal file.
   else {
      print "DEBUG zout is plain.\n" if ($DEBUG);
      $stream_name =~ s/^\s*>\s*-\s*$/-/;
      return open($STREAM, ">$stream_name");
   }
}

# The library was properly loaded.
return 1
