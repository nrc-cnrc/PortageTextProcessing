#!/usr/bin/perl -w

# $Id$

# @file portage_utils.pm
# @brief Library to transparently use compressed file formats, plus some other common perl methods.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada

package portage_utils;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(zopen printCopyright explainSystemRC);  # symbols to export on request

use strict;
use warnings;

=head1 portage_utils.pm

B< >

 This Perl module is intended to contain common utility functions for all Perl
 scripts in the Portage project.

B< >

=cut


# ================ printCopyright =================#

=head1 SUB

B< =============================================
 ====== printCopyright                  ======
 =============================================>

=over 4

=item B<DESCRIPTION>

 Print the standard NRC Copyright notice

=item B<SYNOPSIS>

 printCopyright("PROGRAM_NAME", START_YEAR);

 START_YEAR should be the first year of Copyright for PROGRAM_NAME;
 the Crown Copyright will be asserted for START_YEAR to latest release year.
 
=back

=cut

my $current_year = 2010;

sub printCopyright($$) {
   # Just like in sh_utils.sh, we don't actually bother with the Copyright
   # statement within Portage.
}


# How to detect that a file was gzipped.
my $isZip = qr/\.(gz|z|Z)\s*$/;

# How to detect that a file was gzipped.
my $isBzip2 = qr/\.(bz2|bzip2|bz)\s*$/;

# How to detect that a file was gzipped.
my $isLzma = qr/\.lzma\s*$/;

our $DEBUG;


# ================ explainSystemRC =================#

=head1 SUB

B< =============================================
 ====== explainSystemRC                 ======
 =============================================>

=over 4

=item B<DESCRIPTION>

 When calling system(), the return code requires a 3-way contidional to
 reliably provide the user with a correct error message, as documentated in
 perldoc -f system.  This function encapsulates that logic, returning a string
 that looks like one of these three
    Command "$cmd" failed to execute: [system error message]
    Command "$cmd" died with signal 15, without coredump
    Command "$cmd" exited with value 1

=item B<SYNOPSIS>

 system($cmd)==0 or die "prog.pl: " . explainSystemRC($?, $cmd) . ".\n";
 system($cmd)==0 or die explainSystemRC($?, $cmd);

 The return value does not end in a newline, so die will print a script and
 line number if you don't add one, such as in the second example.  The first
 example, however, will usually produce an error message that is more
 meaningful to the user.

 system($cmd)==0 or die explainSystemRC($?, $cmd, $0);

 If you provide the optional program name argument, the basename of your
 program is prepended to the message, and a newline is added at the end.

=back

=cut

sub explainSystemRC($$;$) {
   my $rc = shift;
   my $cmd = shift;
   my $prog = shift;
   my $explanation;
   if ($rc == -1) {
      $explanation = "failed to execute: $!";
   } elsif ($rc & 127) {
      $explanation =
         sprintf "died with signal %d, %s coredump",
                 ($rc & 127),  ($rc & 128) ? 'with' : 'without';
   } else {
      $explanation = sprintf "exited with value %d", $rc >> 8;
   }

   if ( defined $prog ) {
      $prog =~ s#.*/##;
      return "$prog: Command \"$cmd\" $explanation.\n";
   } else {
      return "Command \"$cmd\" $explanation";
   }
}


# ================= zopen ====================#

=head1 SUB

B< =============================================
 ====== zopen                           ======
 =============================================>

=over 4

=item B<DESCRIPTION>

 Portage's perl magicstream.  Tries to deduce if the stream is input or output,
 if it is compressed (.gz,z,Z,bz2,bzip2,bz,lzma), piped or just a normal file,
 and does the proper thing to open the stream.

=item B<SYNOPSIS>

 zopen($STREAM, $stream_name);
 zopen(*STREAM, $stream_name);
 zopen(*STREAM, "plain-text-input-file");
 zopen(*STREAM, "< plain-text-input-file");
 zopen(*STREAM, "compressed-input-file.gz");
 zopen(*STREAM, "< compressed-input-file.gz");
 zopen(*STREAM, "input pipe |");
 zopen(*STREAM, "> plain-text-output-file");
 zopen(*STREAM, "> compressed-output-file.gz");
 zopen(*STREAM, "| output pipe ");

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

   print STDERR "DEBUG zin with $stream_name.\n" if ($DEBUG);

   die "Don't use zin to open an output stream!!\n" if ($stream_name =~ /^\s*>/);

   # remove leading < if present
   $stream_name =~ s/^\s*<//;

   # Is this a pipe.
   if ($stream_name =~ /\|\s*$/) {
      print STDERR "DEBUG zin is a pipe.\n" if ($DEBUG);
      return open($STREAM, "$stream_name");
   }
   # Is this a bzipped 2 stream.
   elsif ($stream_name =~ /$isBzip2/) {
      print STDERR "DEBUG zin is bzip2.\n" if ($DEBUG);
      return open($STREAM, "bzip2 -cqfd $stream_name |");
   }
   # Is this a gzipped stream.
   elsif ($stream_name =~ /$isZip/) {
      print STDERR "DEBUG zin is zip.\n" if (defined $DEBUG);
      return open($STREAM, "gzip -cqfd $stream_name |");
   }
   # Is this a lzma stream.
   elsif ($stream_name =~ /$isLzma/) {
      print STDERR "DEBUG zin is lzma.\n" if ($DEBUG);
      return open($STREAM, "lzma -4 -cqfd $stream_name |");
   }
   # Assume it is a normal file.
   else {
      print STDERR "DEBUG zin is plain.\n" if ($DEBUG);
      return open($STREAM, "<$stream_name");
   }
}



# ================= zout ====================#

=head1 SUB

B< =============================================
 ====== zout                            ======
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

   print STDERR "DEBUG zout with $stream_name.\n" if ($DEBUG);

   die "Don't use zout to open an input stream!!\n" if ($stream_name =~ /^\s*</);

   # Remove one redir.
   $stream_name =~ s/^\s*>//;

   # Is this a pipe.
   if ($stream_name =~ /^\s*\|/) {
      print STDERR "DEBUG zout is a pipe.\n" if ($DEBUG);
      die "Can't append to a pipe." if ($stream_name =~ /^\s*>/);
      return open($STREAM, "$stream_name");
   }
   # Is this a bzipped stream.
   elsif ($stream_name =~ /$isBzip2/) {
      print STDERR "DEBUG zout is bzip2.\n" if ($DEBUG);
      return open($STREAM, "| bzip2 -cqf >$stream_name");
   }
   # Is this a gzipped stream.
   elsif ($stream_name =~ /$isZip/) {
      print STDERR "DEBUG zout is zip.\n" if ($DEBUG);
      return open($STREAM, "| gzip -cqf >$stream_name");
   }
   # Is this a lzma stream.
   elsif ($stream_name =~ /$isLzma/) {
      print STDERR "DEBUG zout is lzma.\n" if ($DEBUG);
      die "Can't append to a lzma file." if ($stream_name =~ /^\s*>/);
      return open($STREAM, "| lzma -cqf >$stream_name");
   }
   # Assume it is a normal file.
   else {
      print STDERR "DEBUG zout is plain.\n" if ($DEBUG);
      $stream_name =~ s/^\s*>\s*-\s*$/-/;
      return open($STREAM, ">$stream_name");
   }
}

# The library was properly loaded.
1;
