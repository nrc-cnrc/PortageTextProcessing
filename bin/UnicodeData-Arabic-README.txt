The UnicodeData-Arabic* file are the models needed by normalize-unicode.pl.

They used to be in $PORTAGE/models/unicode but the Arabic versions are small
enough to add to source control.

UnicodeData.txt (not included) is the official Unicode
character list from http://www.unicode.org/Public/UNIDATA/UnicodeData.txt
You can obtain the up-to-date version at any time by doing wget on that URL.

UnicodeData-Arabic-full.txt is the result of doing "grep ARABIC
UnicodeData.txt", which yields the list of all relevant code points for
normalizing Arabic text.

UnicodeData-Arabic.txt has code points 0622 - 0626 removed, because although
these are more or less presentation forms, they have existed as separate code
points long enough to be processed by applications, and in particular, Nizar
Habash's converter from utf-8 to cp-1256 ("ArabicTokenizer_v2.pl UTF-8 CP-1256
notokenization") only handles them as such rather than as their two character
equivalents.

normalize-unicode.pl has "ar-full" and "ar" as shorthands for these two data
files.

Update history:
 - the original version in $PORTAGE/models/unicode was created in May 2006 when
   I wrote normalize-unicode.pl and stayed static until 2019.
 - 14/01/2019: normalize-unicode.pl was updated to optionally find its data
   files in its bin directory, for easier use in PortageLive plugins.
 - UnicodeData.txt downloaded fresh on 16/01/2016 to update the two Arabic
   files.  The only difference that affects normalize-unicode.pl is the addition
   of the Arabic mathematical font characters, code points 1EE00-1EEF1.
