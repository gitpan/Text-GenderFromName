package Text::GenderFromName;

# Text::GenderFromName.pm
#
# Jon Orwant, <orwant@media.mit.edu>
#
# 10 Mar 97 - created
#
# Copyright 1997 Jon Orwant.  All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 
# Version 0.102.  Module list status is "Rdpf."

require 5;

require Exporter;
@ISA = qw( Exporter );

=head1 NAME

C<Text::GenderFromName> - Guess the gender of a "Christian" first name.

=head1 SYNOPSIS

    use Text::GenderFromName;
 
    print gender("Jon");    # prints "m"

Text::GenderFromName is available at a CPAN site near you.

=head1 DESCRIPTION

This module provides a lone function: C<gender()>, which returns
one of three values: "m" for male, "f" for female", or UNDEF if
it doesn't know.  For instance, gender("Chris") is UNDEF.

The original code assumed a default of male, and I am happy to
contribute to the destruction of the oppressive Patriarchy by
returning an UNDEF value if no rule triggers.  Ha ha!  Seriously, it'll
be useful to know when C<gender()> has no clue.

For the curious, I ran Text::GenderFromName on The Perl Journal's
subscriber list.  The result?  

   Male:    68%
   Female:  32%

=head1 BUGS

C<gender()> can never be perfect.  

I'm sure that many of these rules could return immediately upon
firing.  However, it's possible that the original author arranged them
in a very deliberate order, with more specific rules at the end
overruling earlier rules.  Consequently, I can't turn all of these
rules into the speedier form C<return "f" if /.../> without throwing
away the meaning of the ordering.  If you have the stamina to plod
through the rules and determine when the ordering doesn't matter, let
me know!

The rules should probably be made case-insensitive, but I bet there's
some funky situation in which that'll lose.

=head1 AUTHOR

Jon Orwant

The Perl Journal and MIT Media Lab

orwant@tpj.com

This is an adaptation of an 8/91 awk script by Scott Pakin in the December 91 issue of Computer Language Monthly.

Small contributions by Andrew Langmead and John Strickler.

=cut

@EXPORT = qw(gender);

sub gender {
    my $gender;		
    my ($name) = @_;
    # Special cases added by orwant 
    return "m" if $name =~ /^Joh?n/; # Jon and John 
    return "m" if $name =~ /^Th?o(m|b)/; # Tom and Thomas and Tomas and Toby
    return "m" if $name =~ /^Frank/; 
    return "m" if $name =~ /^Bil/;
    return "m" if $name =~ /^Hans/;
    return "m" if $name =~ /^Ron/;
    return "f" if $name =~ /^Ro(z|s)/;
    return "m" if $name =~ /^Walt/;
    return "m" if $name =~ /^Krishna/;
    return "f" if $name =~ /^Tri(c|sh)/; 
    return "m" if $name =~ /^Pas(c|qu)al$/; # Pascal and Pasqual
    return "f" if $name =~ /^Ellie/;
    return "m" if $name =~ /^Anfernee/;

    # Rules from original code
    $gender = "f" if $name =~ /^.*[aeiy]$/;    # most names ending in a/e/i/y are female
    $gender = "f" if $name =~ /^All?[iy]((ss?)|z)on$/; # Allison and variations
    $gender = "f" if $name =~ /een$/; # Cathleen, Eileen, Maureen
    $gender = "m" if $name =~ /^[^S].*r[rv]e?y?$/; # Barry, Larry, Perry
    $gender = "m" if $name =~ /^[^G].*v[ei]$/; # Clive, Dave, Steve
    $gender = "f" if $name =~ /^[^BD].*(b[iy]|y|via)nn?$/; # Carolyn, Gwendolyn, Vivian
    $gender = "m" if $name =~ /^[^AJKLMNP][^o][^eit]*([glrsw]ey|lie)$/; # Dewey, Stanley, Wesley
    $gender = "f" if $name =~ /^[^GKSW].*(th|lv)(e[rt])?$/; # Heather, Ruth, Velvet
    $gender = "m" if $name =~ /^[CGJWZ][^o][^dnt]*y$/; # Gregory, Jeremy, Zachary
    $gender = "m" if $name =~ /^.*[Rlr][abo]y$/; # Leroy, Murray, Roy
    $gender = "f" if $name =~ /^[AEHJL].*il.*$/; # Abigail, Jill, Lillian
    $gender = "f" if $name =~ /^.*[Jj](o|o?[ae]a?n.*)$/; # Janet, Jennifer, Joan
    $gender = "m" if $name =~ /^.*[GRguw][ae]y?ne$/; # Duane, Eugene, Rene
    $gender = "f" if $name =~ /^[FLM].*ur(.*[^eotuy])?$/; # Fleur, Lauren, Muriel
    $gender = "m" if $name =~ /^[CLMQTV].*[^dl][in]c.*[ey]$/; # Lance, Quincy, Vince
    $gender = "f" if $name =~ /^M[aei]r[^tv].*([^cklnos]|([^o]n))$/; # Margaret, Marylou, Miri;  
    $gender = "m" if $name =~ /^.*[ay][dl]e$/; # Clyde, Kyle, Pascale
    $gender = "m" if $name =~ /^[^o]*ke$/; # Blake, Luke, Mi;  
    $gender = "f" if $name =~ /^[CKS]h?(ar[^lst]|ry).+$/; # Carol, Karen, Shar;  
    $gender = "f" if $name =~ /^[PR]e?a([^dfju]|qu)*[lm]$/; # Pam, Pearl, Rachel
    $gender = "f" if $name =~ /^.*[Aa]nn.*$/; # Annacarol, Leann, Ruthann
    $gender = "f" if $name =~ /^.*[^cio]ag?h$/; # Deborah, Leah, Sarah
    $gender = "f" if $name =~ /^[^EK].*[grsz]h?an(ces)?$/; # Frances, Megan, Susan
    $gender = "f" if $name =~ /^[^P]*([Hh]e|[Ee][lt])[^s]*[ey].*[^t]$/; # Ethel, Helen, Gretchen
    $gender = "m" if $name =~ /^[^EL].*o(rg?|sh?)?(e|ua)$/; # George, Joshua, Theodore
    $gender = "f" if $name =~ /^[DP][eo]?[lr].*s$/; # Delores, Doris, Precious
    $gender = "m" if $name =~ /^[^JPSWZ].*[denor]n.*y$/; # Anthony, Henry, Rodney
    $gender = "f" if $name =~ /^K[^v]*i.*[mns]$/; # Karin, Kim, Kristin
    $gender = "m" if $name =~ /^Br[aou][cd].*[ey]$/; # Bradley, Brady, Bruce
    $gender = "f" if $name =~ /^[ACGK].*[deinx][^aor]s$/; # Agnes, Alexis, Glynis
    $gender = "m" if $name =~ /^[ILW][aeg][^ir]*e$/; # Ignace, Lee, Wallace
    $gender = "f" if $name =~ /^[^AGW][iu][gl].*[drt]$/; # Juliet, Mildred, Millicent
    $gender = "m" if $name =~ /^[ABEIUY][euz]?[blr][aeiy]$/; # Ari, Bela, Ira
    $gender = "f" if $name =~ /^[EGILP][^eu]*i[ds]$/; # Iris, Lois, Phyllis
    $gender = "m" if $name =~ /^[ART][^r]*[dhn]e?y$/; # Randy, Timothy, Tony
    $gender = "f" if $name =~ /^[BHL].*i.*[rtxz]$/; # Beatriz, Bridget, Harriet
    $gender = "m" if $name =~ /^.*oi?[mn]e$/; # Antoine, Jerome, Tyrone
    $gender = "m" if $name =~ /^D.*[mnw].*[iy]$/; # Danny, Demetri, Dondi
    return "m" if $name =~ /^[^BG](e[rst]|ha)[^il]*e$/; # Pete, Serge, Shane
    return "f" if $name =~ /^[ADFGIM][^r]*([bg]e[lr]|il|wn)$/; # Angel, Gail, Isabel
    return $gender;
}

1;


