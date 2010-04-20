package Text::GenderFromName;

# Text::GenderFromName.pm
#
# Originally by Jon Orwant, <orwant@readable.com>
# Created 10 Mar 97
#
# Version 0.30 - Jul 29 2003 by
# Eamon Daly, <eamon@eamondaly.com>

use Carp;
use strict;
use warnings;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

@ISA = qw(Exporter);
@EXPORT = qw(&gender);
@EXPORT_OK = qw(&gender_init);
$VERSION = '0.33';

=head1 NAME

Text::GenderFromName - Guess the gender of an American first name.

=head1 SYNOPSIS

    use Text::GenderFromName;

    print gender("Jon");    # prints 'm'

    See EXAMPLES for additional uses.

=head1 DESCRIPTION

This module provides C<gender()>, which takes a name and returns one
of three values: 'm' for male, 'f' for female, or undef for unknown.

=head1 CHANGES

Version 0.30 is a significant departure from previous versions. By
default, version 0.30 uses the U.S. Social Security Administration's
"Most Popular Names of the 1980's" list of 1001 male first names and
1013 female first names. See CAVEATS below for details on this list.

Version 0.30 also allows for arbitrary female and male hashed lists to
be provided at run-time, and includes several built-ins to provide
matches based on exclusivity, weight, metaphones, and both version
0.20 and version 0.10 regexp-style matching. The user can also specify
additional match subroutines and change the match order at run-time.

=head1 EXPORT

The single exported function is:

=over 4

=item gender ($name [, $looseness])

Returns one of three values: 'm' for male, 'f' for female, or undef
for unknown. C<gender()> also accepts a "looseness" level: the higher
the looseness value, the broader the match. See THE MATCH LIST below
for details.

=back

=head1 NON-EXPORT

The non-exported matching subs are:

=over 4

=item one_only ($name)

Returns 'm' or 'f' if and only if $name is found in only one of the
two lists.

=item either_weight ($name)

Returns 'm' or 'f' if $name is found in either list. If $name is in
both lists, it returns the more heavily weighted of the two.

=item one_only_metaphone ($name)

Uses Text::DoubleMetaphone for comparison. Returns 'm' or 'f' if and
only if the metaphone for $name is found in only one of the two lists.

Note that this function builds a copy of the female/male name lists to
speed up the metaphone lookup.

=item either_weight_metaphone ($name)

Uses Text::DoubleMetaphone for comparison. Returns 'm' or 'f' if $name
is found in either list. If $name is in both lists, it sums the
weights of all matching metaphones and returns the larger of the two.

Note that this function builds a copy of the female/male name lists to
speed up the metaphone lookup.

=item v2_rules ($name)

Uses Jon Orwant's v0.20 rules for matching.

=item v1_rules ($name)

Uses Jon Orwant's adaptation of Scott Pakin's awk script from v0.10
for matching.

=back

If you wish to use your own hash refs containing names and weights,
you should explicitly import:

=over 4

=item gender_init ($female_names_ref, $male_names_ref)

Initializes the male and female hashes. This package calls
C<gender_init()> internally: without arguments it uses the table
provided by the U.S. Social Security Administration. Don't call this
function unless you want to override the supplied lists. See THE
FEMALE/MALE HASHES below for details.

=back

=head1 THE MATCH LIST

C<@MATCH_LIST> contains the list of subs C<gender> will use to
determine the gender of a given name.

By default, there are 6 items in @MATCH_LIST, corresponding to the
non-exported functions above. Strictly matching subs should go first,
loosely matching subs should go last, as C<gender> will iterate over
the list from 0 to the specified looseness value or the number of subs
in C<@MATCH_LIST>, whichever comes first.

You may override this like so:

    @Text::GenderFromName::MATCH_LIST = ('main::my_matching_routine');

=head1 THE FEMALE/MALE HASHES

By default, these hashes are built using data from the U.S. SSA. You
may override them by calling C<gender_init()> with your own female and male
hash refs, like so:

    use Text::GenderFromName qw( :DEFAULT &gender_init );

    my %females = ('barbly' => 4.1, 'bar' => 2.3, ...);
    my %males   = ('foobly' => 4.5, 'foo' => 1.3, ...);

    &gender_init(\%females, \%males);

The hash keys are lowercase names, and their values are their relative
weights. This allows for names that could be male or female, but are
more often one or the other.

=head1 EXAMPLES

Very strict usage:

    use Text::GenderFromName;

    my @names = ('Josephine', 'Michael', 'Dondi', 'Jonny',
                 'Pascal', 'Velvet', 'Eamon', 'FLKMLKSJN');

    for (@names) {
        # Use strict matching
        my $gender = &gender($_) || '';

        if    ($gender eq 'f') { print "$_: Female\n" }
        elsif ($gender eq 'm') { print "$_: Male\n"   }
        else                   { print "$_: UNSURE\n" }
    }

returns:

    Josephine: Female
    Michael: UNSURE
    Dondi: UNSURE
    Jonny: UNSURE
    Pascal: UNSURE
    Velvet: UNSURE
    Eamon: UNSURE
    FLKMLKSJN: UNSURE

Loose matching:

    for (@names) {
        # Use loose matching
        my $gender = &gender($_, 9) || '';
    ...

returns:

    Josephine: Female
    Michael: Male
    Dondi: Male
    Jonny: Male
    Pascal: Male
    Velvet: Female
    Eamon: UNSURE
    FLKMLKSJN: UNSURE

Turn on debugging:

    $Text::GenderFromName::DEBUG = 1;

returns:

    Matching "josephine":
            one_only...
            ==> HIT (f)

    Matching "michael":
            one_only...
            either_weight...
            F: 0.0271266376105491, M: 3.4091409099979
            ==> HIT (m)

    Matching "dondi":
            one_only...
            either_weight...
            one_only_metaphone...
            M: dondi => dante => TNT: 0.020568
            ==> HIT (m)

    Matching "jonny":
            one_only...
            either_weight...
            one_only_metaphone...
            F: jonny => jenna => JN: 0.193945
            M: jonny => john => JN: 1.629871
            either_weight_metaphone...
            F: jonny => jenna => JN: 0.193945
            F: jonny => joanna => JN: 0.118652
            F: jonny => jenny => JN: 0.104875
            ...
            M: jonny => john => JN: 1.629871
            M: jonny => juan => JN: 0.309234
            M: jonny => johnny => JN: 0.127193
            ...
            ==> HIT (m)

    Matching "pascal":
            one_only...
            either_weight...
            one_only_metaphone...
            either_weight_metaphone...
            v2_rules...
            ==> HIT (m)

    Matching "velvet":
            one_only...
            either_weight...
            one_only_metaphone...
            either_weight_metaphone...
            v2_rules...
            v1_rules...
            ==> HIT (f)

    Matching "eamon":
            one_only...
            either_weight...
            one_only_metaphone...
            either_weight_metaphone...
            v2_rules...
            v1_rules...

    Matching "flkmlksjn":
            one_only...
            either_weight...
            one_only_metaphone...
            either_weight_metaphone...
            v2_rules...
            v1_rules...

    Josephine: Female
    Michael: Male
    Dondi: Male
    Jonny: Male
    Pascal: Male
    Velvet: Female
    Eamon: UNSURE
    FLKMLKSJN: UNSURE

Add your own match sub:

    push @Text::GenderFromName::MATCH_LIST, 'main::eamon_hack';

    sub eamon_hack {
        my $name = shift;
        return 'm' if $name =~ /^eamon/;
    }

returns:

    ...
    Matching "eamon":
            one_only...
            either_weight...
            one_only_metaphone...
            either_weight_metaphone...
            v2_rules...
            v1_rules...
            main::eamon_hack...
            ==> HIT (m)

    Eamon: Male

Don't use metaphones:

    @Text::GenderFromName::MATCH_LIST =
      grep !/metaphone/, @Text::GenderFromName::MATCH_LIST;

Use your own female/male hash lists:

    use Text::GenderFromName qw( :DEFAULT &gender_init );

    my %females = ('josephine' => 2.1);
    my %males = ('dondi' => 4.5);
    &gender_init(\%females, \%males);

Use female/male hash lists from a database:

    use Text::GenderFromName qw( :DEFAULT &gender_init );

    use Tie::RDBM;
    tie my %females, 'Tie::RDBM', {db       => 'mysql:common',
                                   table    => 'females',
                                   key      => 'name',
                                   value    => 'weight'};
    tie my %males,   'Tie::RDBM', {db       => 'mysql:common',
                                   table    => 'males',
                                   key      => 'name',
                                   value    => 'weight'};
    &gender_init(\%females, \%males);

=head1 COMPATIBILITY

To run v0.30 in a (mostly) backward compatible mode, override the
MATCH_LIST like so:

    @Text::GenderFromName::MATCH_LIST = ('v2_rules', 'v1_rules');

and set the looseness to any value greater than 1:

    &gender($_, 9);

Note that v0.30 uses significantly different lists than before. If
you'd like to use the v0.20 name lists, you may download a previous
version of C<Text::GenderFromName>, cut out the hashes, and use the
&gender_init() function to use those lists instead. To minimize the
size of this module, they are not included in this module.

=head1 CAVEATS

=head2 REGARDING THIS MODULE

Rules are now case-insensitive, which is a departure from earlier
versions of this module. Also, Orwant's v0.20 rules no longer fall
through, though v0.10's do.

Version 0.30 was a complete overhaul by someone who's never submitted a
module to CPAN before. Please consider this fact when using
C<Text::GenderFromName> module in a production environment.

Also note that the matching routines in this module are strongly
biased toward American first names. None of the methods included in
this module correctly identify the v0.30 author's gender (m) from his
first name (Eamon).

=head2 REGARDING THE DEFAULT LIST

From http://www.ssa.gov/OACT/babynames/1999/top1000of80s.html:

"The data comes from a 5% sampling of Social Security card
applications with dates of birth from January 1980 through December
1989."

"All names which occurred at least five times in the sample are
included in the table below. The total number of males in the sample
is 977,255 and the total number of females is 936,349. Criteria to be
included in the sample is simply that a Social Security card
application was filed, that the year of birth was between 1980 and
1989, and that the birth was on US soil. As always each unique
spelling is considered a unique name. It may be appropriate for
purposes of ranking popularity of names to combine similar spellings
of the same name. This kind of grouping, however, is subjective and
time consuming, and is beyond the scope of this document. The 2000
edition of the World Almanac lists the top 10 names of each decade
based on this data after combining different spellings of the same
name."

"No effort has been made to edit the data and as a result some coding
errors are obvious. For example initials like "A" are included in the
lists. Another common problem, especially for the earlier decades is
females coded as being male. For example Jessica is the ranked 647
among male names. Finally entries like "Unknown" and "Baby" are not
removed from the lists."

=head2 REGARDING HENRY

m (0.111843889261247)

=head1 BUGS

Did I mention this module doesn't match the v0.30 author's name?

=head1 AUTHOR

Originally by Jon Orwant <orwant@readable.com>, v0.30 by Eamon Daly
<eamon@eamondaly.com>.

This is an adaptation of an 8/91 awk script by Scott Pakin in the
December 91 issue of Computer Language Monthly.

Small contributions by Andrew Langmead and John Strickler.  Thanks to
Bob Baldwin, Matt Bishop, Daniel Klein, and the U.S. SSA for their
lists of names.

=head1 SEE ALSO

L<Text::DoubleMetaphone>

=cut

our ($Males, $Females);

our $DEBUG = 0;

our @MATCH_LIST = ('one_only',
                   'either_weight',
                   'one_only_metaphone',
                   'either_weight_metaphone',
                   'v2_rules',
                   'v1_rules');

eval "use Text::DoubleMetaphone qw(double_metaphone)";

if ($@) {
    @MATCH_LIST = grep !/metaphone/, @MATCH_LIST;
}

my $DEBUG_MSG = '';

&gender_init();

sub gender_init {
    my ($females_ref, $males_ref) = @_;

    if (!$females_ref || !$males_ref) {
        my $eval = join '', (<DATA>);
        eval $eval;
    }
    elsif ($males_ref && !$females_ref) {
        carp "Male hash supplied, but not female!";
    }
    elsif ($females_ref && !$males_ref) {
        carp "Female hash supplied, but not male!";
    }
    else {
        $Males = $males_ref;
        $Females = $females_ref;
    }
}

sub gender {
    my $name = lc(shift);
    my $looseness = shift || 1;
    my $gender = undef;

    if (!$name) {
        carp "No name specified";
        return undef;
    }

    $DEBUG_MSG = qq{Matching "$name":\n} if $DEBUG;

    no strict 'refs';

    for (my $i = 0; $i < $looseness; $i++) {
        last if !$MATCH_LIST[$i];

        $DEBUG_MSG .= "\t$MATCH_LIST[$i]...\n" if $DEBUG;

        $gender = &{ $MATCH_LIST[$i] }($name);

        $DEBUG_MSG .= "\t==> HIT ($gender)\n" if $DEBUG && $gender;

        last if $gender;
    }

    print STDERR "$DEBUG_MSG\n" if $DEBUG;

    return $gender;
}

sub one_only {
    my $name = shift;
    my $gender = undef;

    # Match one list only

    my $male_hit = $Males->{$name};
    my $female_hit = $Females->{$name};

    if ($female_hit && !$male_hit) {
        $gender = 'f';
    }
    elsif ($male_hit && !$female_hit) {
        $gender = 'm';
    }

    return $gender;
}

sub either_weight {
    my $name = shift;
    my $gender = undef;

    # Match either, weight

    my $male_hit = $Males->{$name};
    my $female_hit = $Females->{$name};

    if ($female_hit || $male_hit) {
        $gender = ($female_hit > $male_hit) ? 'f' : 'm';
    }

    $DEBUG_MSG .= "\tF: $female_hit, M: $male_hit\n" if $DEBUG && $gender;

    return $gender;
}

sub one_only_metaphone {
    my $name = shift;
    my $gender = undef;

    # Match one list only, use DoubleMetaphone

    my $meta_name = &double_metaphone($name);
    my $metaphone_hit = '';

    # Copy $Females and $Males to speed sorting.

    my %females_copy = %{ $Females };
    my %males_copy = %{ $Males };

    my $male_hit = 0;
    my $female_hit = 0;

    foreach my $list_name (sort
                           { $females_copy{$b} <=> $females_copy{$a} }
                           keys %females_copy) {
        last if $female_hit;

        my $meta_list_name = double_metaphone($list_name);

        if ($meta_name eq $meta_list_name) {
            $female_hit = $females_copy{$list_name};

            $DEBUG_MSG .= sprintf "\tF: %s => %s => %s: %f\n",
              $name, $list_name, $meta_list_name, $females_copy{$list_name}
                if $DEBUG;
        }
    }

    foreach my $list_name (sort
                           { $males_copy{$b} <=> $males_copy{$a} }
                           keys %males_copy) {
        last if $male_hit;

        my $meta_list_name = double_metaphone($list_name);

        if ($meta_name eq $meta_list_name) {
            $male_hit = $males_copy{$list_name};

            $DEBUG_MSG .= sprintf "\tM: %s => %s => %s: %f\n",
              $name, $list_name, $meta_list_name, $males_copy{$list_name}
                if $DEBUG;
        }
    }

    if ($female_hit && !$male_hit) {
        $gender = 'f';
    }
    elsif ($male_hit && !$female_hit) {
        $gender = 'm';
    }

    return $gender;
}

sub either_weight_metaphone {
    my $name = shift;
    my $gender = undef;

    # Match either, weight, use DoubleMetaphone

    my $meta_name = &double_metaphone($name);

    # Copy $Females and $Males to speed sorting.

    my %females_copy = %{ $Females };
    my %males_copy = %{ $Males };

    my $male_hit = 0;
    my $female_hit = 0;

    foreach my $list_name (sort
                           { $females_copy{$b} <=> $females_copy{$a} }
                           keys %females_copy) {
        my $meta_list_name = double_metaphone($list_name);

        if ($meta_name eq $meta_list_name) {
            $female_hit += $females_copy{$list_name};

            $DEBUG_MSG .= sprintf "\tF: %s => %s => %s: %f\n",
              $name, $list_name, $meta_list_name, $females_copy{$list_name}
                if $DEBUG;
        }
    }

    foreach my $list_name (sort
                           { $males_copy{$b} <=> $males_copy{$a} }
                           keys %males_copy) {
        my $meta_list_name = double_metaphone($list_name);

        if ($meta_name eq $meta_list_name) {
            $male_hit += $males_copy{$list_name};

            $DEBUG_MSG .= sprintf "\tM: %s => %s => %s: %f\n",
              $name, $list_name, $meta_list_name, $males_copy{$list_name}
                if $DEBUG;
        }
    }

    if ($female_hit || $male_hit) {
        $gender = ($female_hit > $male_hit) ? 'f' : 'm';
    }

    return $gender;
}

sub v2_rules {
    my $name = shift;
    my $gender = undef;

    # Match using Orwant's rules from v0.20 of Text::GenderFromName

    # Note that this no longer 'falls through' as in v0.20. Jon makes
    # mention of the fact that the v0.10 rules are ordered, but Jon's
    # additions appear to be exclusive.

    # jon and john
    if ($name =~ /^joh?n/) { $gender = 'm' }
    # tom and thomas and tomas and toby
    elsif ($name =~ /^th?o(m|b)/) { $gender = 'm' }
    elsif ($name =~ /^frank/) { $gender = 'm' }
    elsif ($name =~ /^bil/) { $gender = 'm' }
    elsif ($name =~ /^hans/) { $gender = 'm' }
    elsif ($name =~ /^ron/) { $gender = 'm' }
    elsif ($name =~ /^ro(z|s)/) { $gender = 'f' }
    elsif ($name =~ /^walt/) { $gender = 'm' }
    elsif ($name =~ /^krishna/) { $gender = 'm' }
    elsif ($name =~ /^tri(c|sh)/) { $gender = 'f' }
    # pascal and pasqual
    elsif ($name =~ /^pas(c|qu)al$/) { $gender = 'm' }
    elsif ($name =~ /^ellie/) { $gender = 'f' }
    elsif ($name =~ /^anfernee/) { $gender = 'm' }

    return $gender;
}

sub v1_rules {
    my $name = shift;
    my $gender = undef;

    # Match using rules from v0.10 of Text::GenderFromName

    # most names ending in a/e/i/y are female
    $gender = 'f' if $name =~ /^.*[aeiy]$/;
    # allison and variations
    $gender = 'f' if $name =~ /^all?[iy]((ss?)|z)on$/;
    # cathleen, eileen, maureen
    $gender = 'f' if $name =~ /een$/;
    # barry, larry, perry
    $gender = 'm' if $name =~ /^[^s].*r[rv]e?y?$/;
    # clive, dave, steve
    $gender = 'm' if $name =~ /^[^g].*v[ei]$/;
    # carolyn, gwendolyn, vivian
    $gender = 'f' if $name =~ /^[^bd].*(b[iy]|y|via)nn?$/;
    # dewey, stanley, wesley
    $gender = 'm' if $name =~ /^[^ajklmnp][^o][^eit]*([glrsw]ey|lie)$/;
    # heather, ruth, velvet
    $gender = 'f' if $name =~ /^[^gksw].*(th|lv)(e[rt])?$/;
    # gregory, jeremy, zachary
    $gender = 'm' if $name =~ /^[cgjwz][^o][^dnt]*y$/;
    # leroy, murray, roy
    $gender = 'm' if $name =~ /^.*[rlr][abo]y$/;
    # abigail, jill, lillian
    $gender = 'f' if $name =~ /^[aehjl].*il.*$/;
    # janet, jennifer, joan
    $gender = 'f' if $name =~ /^.*[jj](o|o?[ae]a?n.*)$/;
    # duane, eugene, rene
    $gender = 'm' if $name =~ /^.*[grguw][ae]y?ne$/;
    # fleur, lauren, muriel
    $gender = 'f' if $name =~ /^[flm].*ur(.*[^eotuy])?$/;
    # lance, quincy, vince
    $gender = 'm' if $name =~ /^[clmqtv].*[^dl][in]c.*[ey]$/;
    # margaret, marylou, miri;
    $gender = 'f' if $name =~ /^m[aei]r[^tv].*([^cklnos]|([^o]n))$/;
    # clyde, kyle, pascale
    $gender = 'm' if $name =~ /^.*[ay][dl]e$/;
    # blake, luke, mi;
    $gender = 'm' if $name =~ /^[^o]*ke$/;
    # carol, karen, shar;
    $gender = 'f' if $name =~ /^[cks]h?(ar[^lst]|ry).+$/;
    # pam, pearl, rachel
    $gender = 'f' if $name =~ /^[pr]e?a([^dfju]|qu)*[lm]$/;
    # annacarol, leann, ruthann
    $gender = 'f' if $name =~ /^.*[aa]nn.*$/;
    # deborah, leah, sarah
    $gender = 'f' if $name =~ /^.*[^cio]ag?h$/;
    # frances, megan, susan
    $gender = 'f' if $name =~ /^[^ek].*[grsz]h?an(ces)?$/;
    # ethel, helen, gretchen
    $gender = 'f' if $name =~ /^[^p]*([hh]e|[ee][lt])[^s]*[ey].*[^t]$/;
    # george, joshua, theodore
    $gender = 'm' if $name =~ /^[^el].*o(rg?|sh?)?(e|ua)$/;
    # delores, doris, precious
    $gender = 'f' if $name =~ /^[dp][eo]?[lr].*s$/;
    # anthony, henry, rodney
    $gender = 'm' if $name =~ /^[^jpswz].*[denor]n.*y$/;
    # karin, kim, kristin
    $gender = 'f' if $name =~ /^k[^v]*i.*[mns]$/;
    # bradley, brady, bruce
    $gender = 'm' if $name =~ /^br[aou][cd].*[ey]$/;
    # agnes, alexis, glynis
    $gender = 'f' if $name =~ /^[acgk].*[deinx][^aor]s$/;
    # ignace, lee, wallace
    $gender = 'm' if $name =~ /^[ilw][aeg][^ir]*e$/;
    # juliet, mildred, millicent
    $gender = 'f' if $name =~ /^[^agw][iu][gl].*[drt]$/;
    # ari, bela, ira
    $gender = 'm' if $name =~ /^[abeiuy][euz]?[blr][aeiy]$/;
    # iris, lois, phyllis
    $gender = 'f' if $name =~ /^[egilp][^eu]*i[ds]$/;
    # randy, timothy, tony
    $gender = 'm' if $name =~ /^[art][^r]*[dhn]e?y$/;
    # beatriz, bridget, harriet
    $gender = 'f' if $name =~ /^[bhl].*i.*[rtxz]$/;
    # antoine, jerome, tyrone
    $gender = 'm' if $name =~ /^.*oi?[mn]e$/;
    # danny, demetri, dondi
    $gender = 'm' if $name =~ /^d.*[mnw].*[iy]$/;
    # pete, serge, shane
    $gender = 'm' if $name =~ /^[^bg](e[rst]|ha)[^il]*e$/;
    # angel, gail, isabel
    $gender = 'f' if $name =~ /^[adfgim][^r]*([bg]e[lr]|il|wn)$/;

    return $gender;
}

1;

__DATA__
# From http://www.ssa.gov/OACT/babynames/1999/top1000of80s.html
#
# See CAVEATS in the perldoc for details.
#
$Males = {
          'michael' => '3.4091409099979',
          'christopher' => '2.83416303830628',
          'matthew' => '2.34473090442106',
          'joshua' => '2.0448091849108',
          'david' => '2.00111536906949',
          'daniel' => '1.79277670618211',
          'james' => '1.7912417946186',
          'robert' => '1.66097896659521',
          'john' => '1.6298714255747',
          'joseph' => '1.540846554891',
          'jason' => '1.50206445605292',
          'justin' => '1.48507810141672',
          'andrew' => '1.44885418851784',
          'ryan' => '1.41948621393597',
          'william' => '1.2658927301472',
          'brian' => '1.20664514379563',
          'jonathan' => '1.20040317010402',
          'brandon' => '1.17287708939837',
          'nicholas' => '1.13368568081002',
          'anthony' => '1.09132212165709',
          'eric' => '1.05427958925767',
          'adam' => '0.989813303590158',
          'kevin' => '0.97313393126666',
          'steven' => '0.929747097738052',
          'thomas' => '0.907235061473208',
          'timothy' => '0.877662432016209',
          'richard' => '0.795595827087096',
          'jeremy' => '0.785363083330349',
          'kyle' => '0.740236683363094',
          'jeffrey' => '0.729901612168779',
          'benjamin' => '0.727957390854997',
          'aaron' => '0.726115496978782',
          'mark' => '0.670244716066943',
          'charles' => '0.669323769128835',
          'jacob' => '0.638830192733729',
          'stephen' => '0.594727067142148',
          'jose' => '0.578559332006488',
          'patrick' => '0.564028835871907',
          'scott' => '0.544484295296519',
          'paul' => '0.538446976480038',
          'nathan' => '0.535684135665717',
          'sean' => '0.527600268097886',
          'zachary' => '0.519311745654921',
          'travis' => '0.51532097558979',
          'dustin' => '0.497311346577915',
          'gregory' => '0.478380770627932',
          'kenneth' => '0.455561752050386',
          'alexander' => '0.4404172912904',
          'jesse' => '0.439394016914725',
          'tyler' => '0.434379972473919',
          'bryan' => '0.42220300740339',
          'samuel' => '0.378816173874782',
          'derek' => '0.365206624678308',
          'bradley' => '0.351494748044267',
          'chad' => '0.349857509043187',
          'shawn' => '0.334303738532932',
          'edward' => '0.319261605210513',
          'jared' => '0.318033675959703',
          'juan' => '0.309233516328901',
          'luis' => '0.302070595699178',
          'cody' => '0.299717064635126',
          'jordan' => '0.296135604320264',
          'peter' => '0.295623967132427',
          'carlos' => '0.268711851052182',
          'corey' => '0.263288496861106',
          'keith' => '0.260423328609217',
          'donald' => '0.255306956730843',
          'marcus' => '0.254795319543006',
          'joel' => '0.24046947828356',
          'ronald' => '0.238627584407345',
          'phillip' => '0.235660088717888',
          'george' => '0.233818194841674',
          'cory' => '0.223483123647359',
          'antonio' => '0.221334247458442',
          'shane' => '0.218776061519255',
          'douglas' => '0.216217875580069',
          'raymond' => '0.211817795764667',
          'brett' => '0.208338662887373',
          'alex' => '0.204552547697377',
          'gary' => '0.203222291009',
          'nathaniel' => '0.196775662442249',
          'craig' => '0.196366352691979',
          'derrick' => '0.195650060629007',
          'casey' => '0.187873175373879',
          'ian' => '0.186849900998204',
          'philip' => '0.185519644309827',
          'gabriel' => '0.180096290118751',
          'victor' => '0.179379998055779',
          'erik' => '0.177742759054699',
          'christian' => '0.177538104179564',
          'frank' => '0.168533289673627',
          'evan' => '0.167305360422817',
          'jesus' => '0.163826227545523',
          'larry' => '0.163007608044983',
          'seth' => '0.161370369043904',
          'austin' => '0.158607528229582',
          'dennis' => '0.158402873354447',
          'vincent' => '0.157993563604177',
          'brent' => '0.156765634353367',
          'jeffery' => '0.154923740477153',
          'wesley' => '0.154309775851748',
          'randy' => '0.154002793539046',
          'todd' => '0.153388828913641',
          'curtis' => '0.152263227100399',
          'miguel' => '0.150625988099319',
          'jeremiah' => '0.150421333224184',
          'adrian' => '0.144690996720406',
          'jorge' => '0.143463067469596',
          'alan' => '0.142849102844191',
          'angel' => '0.139779279717167',
          'mario' => '0.13885833277906',
          'luke' => '0.138244368153655',
          'russell' => '0.137937385840952',
          'jerry' => '0.135993164527171',
          'trevor' => '0.134867562713928',
          'carl' => '0.132514031649876',
          'ricardo' => '0.130979120086364',
          'johnny' => '0.127193004896368',
          'blake' => '0.1270906774588',
          'lucas' => '0.126579040270963',
          'shaun' => '0.125760420770423',
          'mitchell' => '0.125248783582586',
          'tony' => '0.125248783582586',
          'cameron' => '0.124020854331776',
          'terry' => '0.123713872019074',
          'francisco' => '0.120541721454482',
          'martin' => '0.120030084266645',
          'troy' => '0.118699827578268',
          'allen' => '0.116448623951783',
          'devin' => '0.116141641639081',
          'johnathan' => '0.114709057513136',
          'manuel' => '0.113583455699894',
          'henry' => '0.111843889261247',
          'bobby' => '0.110615960010437',
          'andre' => '0.11051363257287',
          'kristopher' => '0.108978721009358',
          'ricky' => '0.10846708382152',
          'jimmy' => '0.108364756383953',
          'marc' => '0.108057774071251',
          'billy' => '0.107136827133143',
          'garrett' => '0.105192605819361',
          'hector' => '0.104885623506659',
          'caleb' => '0.102532092442607',
          'danny' => '0.102122782692337',
          'roberto' => '0.101918127817202',
          'lance' => '0.101713472942067',
          'albert' => '0.10079252600396',
          'randall' => '0.0996669241907179',
          'lee' => '0.0993599418780155',
          'lawrence' => '0.0989506321277456',
          'jonathon' => '0.0982343400647733',
          'taylor' => '0.0979273577520708',
          'mathew' => '0.0951645169377491',
          'isaac' => '0.0944482248747768',
          'micheal' => '0.093834260249372',
          'clinton' => '0.0930156407488322',
          'jamie' => '0.0928109858736973',
          'walter' => '0.0914807291853201',
          'javier' => '0.090150472496943',
          'rodney' => '0.0897411627466731',
          'louis' => '0.0891271981212683',
          'edwin' => '0.0890248706837008',
          'roger' => '0.0883085786207285',
          'willie' => '0.0874899591201887',
          'colin' => '0.0868759944947839',
          'jon' => '0.086466684744514',
          'alejandro' => '0.0860573749942441',
          'clayton' => '0.0860573749942441',
          'oscar' => '0.0855457378064067',
          'omar' => '0.0852387554937043',
          'chase' => '0.0848294457434344',
          'rafael' => '0.0848294457434344',
          'pedro' => '0.0841131536804621',
          'ross' => '0.0833968616174898',
          'gerald' => '0.0823735872418151',
          'jack' => '0.0807363482407355',
          'bruce' => '0.0800200561777632',
          'arthur' => '0.0798154013026283',
          'joe' => '0.0796107464274933',
          'roy' => '0.0796107464274933',
          'spencer' => '0.0789967818020885',
          'ruben' => '0.0785874720518186',
          'darren' => '0.0783828171766837',
          'jay' => '0.0777688525512788',
          'maurice' => '0.0769502330507391',
          'wayne' => '0.0762339409877668',
          'calvin' => '0.0759269586750643',
          'drew' => '0.0753129940496595',
          'grant' => '0.0737780824861474',
          'brendan' => '0.073471100173445',
          'fernando' => '0.073471100173445',
          'brad' => '0.0729594629856076',
          'dylan' => '0.0711175691093932',
          'eduardo' => '0.0705036044839883',
          'jaime' => '0.0695826575458811',
          'raul' => '0.0681500734199365',
          'darrell' => '0.067843091107234',
          'julian' => '0.0665128344188569',
          'sergio' => '0.0655918874807496',
          'logan' => '0.0654895600431822',
          'frederick' => '0.0646709405426424',
          'levi' => '0.0646709405426424',
          'emmanuel' => '0.0642616307923725',
          'jermaine' => '0.0640569759172376',
          'noah' => '0.0631360289791303',
          'terrance' => '0.0629313741039954',
          'edgar' => '0.0626243917912929',
          'ivan' => '0.0626243917912929',
          'dominic' => '0.062419736916158',
          'geoffrey' => '0.0622150820410231',
          'jerome' => '0.0621127546034556',
          'reginald' => '0.0617034448531857',
          'alberto' => '0.0616011174156182',
          'eddie' => '0.0616011174156182',
          'theodore' => '0.0614987899780508',
          'tyrone' => '0.0611918076653484',
          'neil' => '0.0610894802277809',
          'marvin' => '0.0600662058521062',
          'armando' => '0.0597592235394037',
          'julio' => '0.0596568961018363',
          'ramon' => '0.0595545686642688',
          'ernest' => '0.0586336217261615',
          'steve' => '0.0579173296631892',
          'micah' => '0.0567917278499471',
          'jake' => '0.0560754357869747',
          'eugene' => '0.0559731083494073',
          'jessie' => '0.0559731083494073',
          'ronnie' => '0.0550521614113',
          'darryl' => '0.0548475065361651',
          'glenn' => '0.0548475065361651',
          'andres' => '0.0547451790985976',
          'karl' => '0.0531079400975181',
          'leonard' => '0.0529032852223831',
          'ethan' => '0.0525963029096807',
          'nicolas' => '0.0525963029096807',
          'dale' => '0.0523916480345457',
          'kurt' => '0.0522893205969783',
          'tommy' => '0.0522893205969783',
          'terrence' => '0.0517776834091409',
          'devon' => '0.0516753559715734',
          'melvin' => '0.0512660462213035',
          'bryce' => '0.0509590639086011',
          'barry' => '0.0506520815958987',
          'cesar' => '0.0504474267207638',
          'marco' => '0.0504474267207638',
          'bryant' => '0.0503450992831963',
          'preston' => '0.0503450992831963',
          'stanley' => '0.0498334620953589',
          'clifford' => '0.049628807220224',
          'kelly' => '0.049424152345089',
          'harold' => '0.0490148425948192',
          'jarrod' => '0.0490148425948192',
          'erick' => '0.0488101877196842',
          'orlando' => '0.0477869133440095',
          'alexis' => '0.0468659664059022',
          'nelson' => '0.0465589840931998',
          'byron' => '0.0462520017804974',
          'shannon' => '0.0460473469053625',
          'dwayne' => '0.0458426920302275',
          'francis' => '0.0455357097175251',
          'max' => '0.0455357097175251',
          'andy' => '0.0449217450921203',
          'xavier' => '0.0446147627794179',
          'alfredo' => '0.0445124353418504',
          'josue' => '0.0445124353418504',
          'enrique' => '0.044205453029148',
          'gerardo' => '0.0434891609661757',
          'joey' => '0.0433868335286082',
          'tyson' => '0.0429775237783383',
          'cole' => '0.0428751963407708',
          'dean' => '0.0428751963407708',
          'ralph' => '0.0428751963407708',
          'clint' => '0.0426705414656359',
          'abraham' => '0.0421589042777985',
          'tristan' => '0.0417495945275286',
          'j' => '0.0416472670899612',
          'ray' => '0.0416472670899612',
          'clarence' => '0.0414426122148262',
          'franklin' => '0.0414426122148262',
          'gilbert' => '0.0412379573396913',
          'arturo' => '0.0409309750269889',
          'marshall' => '0.0408286475894214',
          'warren' => '0.040317010401584',
          'damien' => '0.0401123555264491',
          'kelvin' => '0.0401123555264491',
          'cedric' => '0.0400100280888816',
          'alvin' => '0.0397030457761792',
          'earl' => '0.0392937360259093',
          'branden' => '0.0390890811507744',
          'harry' => '0.0387820988380719',
          'colby' => '0.038577443962937',
          'elijah' => '0.0384751165253695',
          'marcos' => '0.0382704616502346',
          'brady' => '0.0381681342126671',
          'terrell' => '0.0381681342126671',
          'alfred' => '0.0378611518999647',
          'rene' => '0.0377588244623972',
          'beau' => '0.0375541695872623',
          'jamal' => '0.0373495147121273',
          'salvador' => '0.0372471872745599',
          'israel' => '0.0369402049618574',
          'demetrius' => '0.03683787752429',
          'kirk' => '0.0365308952115876',
          'nickolas' => '0.0364285677740201',
          'wade' => '0.0363262403364526',
          'darius' => '0.0362239128988851',
          'ernesto' => '0.0361215854613177',
          'isaiah' => '0.0358146031486153',
          'leon' => '0.0356099482734803',
          'felix' => '0.0354052933983454',
          'lorenzo' => '0.0352006385232104',
          'morgan' => '0.0346890013353731',
          'courtney' => '0.0345866738978056',
          'dane' => '0.0344843464602381',
          'antoine' => '0.0342796915851032',
          'daryl' => '0.0341773641475357',
          'angelo' => '0.0338703818348333',
          'emanuel' => '0.0336657269596983',
          'clifton' => '0.0335633995221309',
          'stuart' => '0.0334610720845634',
          'darnell' => '0.0333587446469959',
          'kenny' => '0.0332564172094285',
          'howard' => '0.033154089771861',
          'bernard' => '0.032949434896726',
          'brock' => '0.0327447800215911',
          'johnathon' => '0.0324377977088887',
          'roderick' => '0.0324377977088887',
          'allan' => '0.0320284879586188',
          'lamar' => '0.0318238330834838',
          'noel' => '0.0318238330834838',
          'damian' => '0.0314145233332139',
          'pablo' => '0.0314145233332139',
          'chris' => '0.0313121958956465',
          'trent' => '0.0311075410205115',
          'quentin' => '0.0310052135829441',
          'dallas' => '0.0303912489575392',
          'gavin' => '0.0301865940824043',
          'collin' => '0.0300842666448368',
          'miles' => '0.0300842666448368',
          'trenton' => '0.0300842666448368',
          'mason' => '0.0299819392072693',
          'hunter' => '0.0298796117697019',
          'bret' => '0.0297772843321344',
          'eli' => '0.0297772843321344',
          'leroy' => '0.0297772843321344',
          'norman' => '0.0297772843321344',
          'rodolfo' => '0.0296749568945669',
          'zachery' => '0.0296749568945669',
          'damon' => '0.029265647144297',
          'lewis' => '0.0287540099564597',
          'charlie' => '0.0284470276437573',
          'tanner' => '0.0283447002061898',
          'terence' => '0.0283447002061898',
          'jayson' => '0.0280377178934874',
          'landon' => '0.0280377178934874',
          'vernon' => '0.0280377178934874',
          'desmond' => '0.0279353904559199',
          'heath' => '0.0278330630183524',
          'gustavo' => '0.0276284081432175',
          'don' => '0.02752608070565',
          'glen' => '0.0274237532680825',
          'lonnie' => '0.0272190983929476',
          'kent' => '0.0270144435178126',
          'neal' => '0.0270144435178126',
          'ashley' => '0.0267074612051102',
          'maxwell' => '0.0267074612051102',
          'ismael' => '0.0262981514548403',
          'gordon' => '0.0261958240172729',
          'dominique' => '0.0260934965797054',
          'graham' => '0.0260934965797054',
          'guillermo' => '0.0260934965797054',
          'elias' => '0.025786514267003',
          'rickey' => '0.025581859391868',
          'kendrick' => '0.0253772045167331',
          'zachariah' => '0.0253772045167331',
          'derick' => '0.0252748770791656',
          'duane' => '0.0251725496415982',
          'jarvis' => '0.0251725496415982',
          'chance' => '0.0250702222040307',
          'marquis' => '0.0250702222040307',
          'abel' => '0.0249678947664632',
          'fredrick' => '0.0248655673288957',
          'quinton' => '0.0246609124537608',
          'rudy' => '0.0246609124537608',
          'dillon' => '0.0245585850161933',
          'simon' => '0.0245585850161933',
          'jamar' => '0.0242516027034909',
          'dwight' => '0.0241492752659234',
          'elliot' => '0.024046947828356',
          'dana' => '0.0239446203907885',
          'fred' => '0.0239446203907885',
          'alfonso' => '0.023842292953221',
          'jarrett' => '0.023842292953221',
          'julius' => '0.0237399655156535',
          'bradford' => '0.0234329832029511',
          'elliott' => '0.0234329832029511',
          'roland' => '0.0234329832029511',
          'rolando' => '0.0234329832029511',
          'saul' => '0.0234329832029511',
          'nolan' => '0.0233306557653837',
          'stephan' => '0.0233306557653837',
          'dominick' => '0.0232283283278162',
          'malcolm' => '0.0232283283278162',
          'rocky' => '0.0232283283278162',
          'brenton' => '0.0231260008902487',
          'felipe' => '0.0231260008902487',
          'diego' => '0.0230236734526812',
          'kurtis' => '0.0229213460151138',
          'cornelius' => '0.0228190185775463',
          'kendall' => '0.0228190185775463',
          'jarred' => '0.0227166911399788',
          'carlton' => '0.0226143637024113',
          'deandre' => '0.0226143637024113',
          'donovan' => '0.0225120362648439',
          'fabian' => '0.0223073813897089',
          'clay' => '0.0222050539521415',
          'kerry' => '0.0222050539521415',
          'perry' => '0.0222050539521415',
          'lloyd' => '0.021898071639439',
          'rory' => '0.021898071639439',
          'herbert' => '0.0217957442018716',
          'marlon' => '0.0216934167643041',
          'owen' => '0.0216934167643041',
          'freddie' => '0.0215910893267366',
          'efrain' => '0.0214887618891692',
          'gilberto' => '0.0214887618891692',
          'josiah' => '0.0214887618891692',
          'jeff' => '0.0213864344516017',
          'oliver' => '0.0213864344516017',
          'giovanni' => '0.0210794521388993',
          'leo' => '0.0210794521388993',
          'stefan' => '0.0210794521388993',
          'dusty' => '0.0207724698261968',
          'roman' => '0.0207724698261968',
          'antwan' => '0.0206701423886294',
          'harrison' => '0.0206701423886294',
          'ben' => '0.0205678149510619',
          'dante' => '0.0205678149510619',
          'dexter' => '0.0205678149510619',
          'rogelio' => '0.0205678149510619',
          'jamaal' => '0.0204654875134944',
          'rick' => '0.0204654875134944',
          'gene' => '0.020363160075927',
          'pierre' => '0.020363160075927',
          'wilfredo' => '0.0202608326383595',
          'darin' => '0.020158505200792',
          'jean' => '0.020158505200792',
          'leslie' => '0.020158505200792',
          'ramiro' => '0.020158505200792',
          'kory' => '0.0198515228880896',
          'skyler' => '0.0198515228880896',
          'esteban' => '0.0197491954505221',
          'ariel' => '0.0196468680129547',
          'quincy' => '0.0196468680129547',
          'tracy' => '0.0196468680129547',
          'colton' => '0.0195445405753872',
          'donnie' => '0.0194422131378197',
          'nathanael' => '0.0194422131378197',
          'donte' => '0.0193398857002522',
          'hugo' => '0.0192375582626848',
          'jimmie' => '0.0192375582626848',
          'weston' => '0.0191352308251173',
          'robin' => '0.0190329033875498',
          'rusty' => '0.0190329033875498',
          'greg' => '0.0189305759499823',
          'rashad' => '0.0186235936372799',
          'sam' => '0.0186235936372799',
          'darrin' => '0.0185212661997125',
          'floyd' => '0.0185212661997125',
          'frankie' => '0.0185212661997125',
          'riley' => '0.0185212661997125',
          'johnnie' => '0.018418938762145',
          'loren' => '0.018418938762145',
          'guy' => '0.0183166113245775',
          'lamont' => '0.0183166113245775',
          'mike' => '0.0183166113245775',
          'moises' => '0.01821428388701',
          'lester' => '0.0181119564494426',
          'salvatore' => '0.0181119564494426',
          'sidney' => '0.0180096290118751',
          'blaine' => '0.0178049741367402',
          'jody' => '0.0177026466991727',
          'toby' => '0.0177026466991727',
          'chadwick' => '0.0176003192616052',
          'milton' => '0.0176003192616052',
          'wilson' => '0.0174979918240377',
          'reynaldo' => '0.0173956643864703',
          'r' => '0.0172933369489028',
          'cecil' => '0.0171910095113353',
          'jerrod' => '0.0171910095113353',
          'kody' => '0.0171910095113353',
          'lionel' => '0.0171910095113353',
          'jackson' => '0.0170886820737679',
          'sterling' => '0.0169863546362004',
          'emilio' => '0.0167816997610654',
          'ty' => '0.0167816997610654',
          'tyrell' => '0.016679372323498',
          'brendon' => '0.0165770448859305',
          'edgardo' => '0.016474717448363',
          'kasey' => '0.016474717448363',
          'zackary' => '0.016474717448363',
          'trey' => '0.0163723900107955',
          'sheldon' => '0.0161677351356606',
          'tomas' => '0.0161677351356606',
          'alonzo' => '0.0160654076980931',
          'brennan' => '0.0160654076980931',
          'jamel' => '0.0159630802605257',
          'kellen' => '0.0159630802605257',
          'santiago' => '0.0159630802605257',
          'sebastian' => '0.0159630802605257',
          'dewayne' => '0.0158607528229582',
          'jackie' => '0.0158607528229582',
          'leonardo' => '0.0158607528229582',
          'reid' => '0.0158607528229582',
          'connor' => '0.0157584253853907',
          'dan' => '0.0157584253853907',
          'wendell' => '0.0153491156351208',
          'moses' => '0.0152467881975533',
          'kareem' => '0.0151444607599859',
          'stewart' => '0.0151444607599859',
          'herman' => '0.0150421333224184',
          'korey' => '0.0150421333224184',
          'zackery' => '0.0150421333224184',
          'alec' => '0.0149398058848509',
          'aron' => '0.0149398058848509',
          'gerard' => '0.0148374784472835',
          'clyde' => '0.0146328235721485',
          'humberto' => '0.0146328235721485',
          'demarcus' => '0.014530496134581',
          'forrest' => '0.014530496134581',
          'noe' => '0.014530496134581',
          'anton' => '0.0144281686970136',
          'avery' => '0.0144281686970136',
          'jonah' => '0.0144281686970136',
          'myles' => '0.0144281686970136',
          'randolph' => '0.0143258412594461',
          'ted' => '0.0143258412594461',
          'jim' => '0.0142235138218786',
          'vicente' => '0.0142235138218786',
          'brice' => '0.0141211863843112',
          'reuben' => '0.0141211863843112',
          'scotty' => '0.0141211863843112',
          'carson' => '0.0139165315091762',
          'freddy' => '0.0139165315091762',
          'jess' => '0.0139165315091762',
          'lyle' => '0.0139165315091762',
          'parker' => '0.0138142040716087',
          'dakota' => '0.0137118766340413',
          'everett' => '0.0137118766340413',
          'thaddeus' => '0.0137118766340413',
          'jarod' => '0.0136095491964738',
          'kaleb' => '0.0136095491964738',
          'kristofer' => '0.0136095491964738',
          'arnold' => '0.0135072217589063',
          'joaquin' => '0.0135072217589063',
          'chaz' => '0.0134048943213389',
          'alvaro' => '0.0133025668837714',
          'brooks' => '0.0133025668837714',
          'randal' => '0.0133025668837714',
          'chester' => '0.0132002394462039',
          'cristian' => '0.0132002394462039',
          'erin' => '0.0132002394462039',
          'nick' => '0.0132002394462039',
          'clark' => '0.0130979120086364',
          'jameson' => '0.0130979120086364',
          'bryon' => '0.012995584571069',
          'deangelo' => '0.012995584571069',
          'reed' => '0.012995584571069',
          'quinn' => '0.0128932571335015',
          'sonny' => '0.0128932571335015',
          'wyatt' => '0.0128932571335015',
          'dion' => '0.012790929695934',
          'will' => '0.012790929695934',
          'keenan' => '0.0126886022583665',
          'sammy' => '0.0126886022583665',
          'solomon' => '0.0126886022583665',
          'zane' => '0.0125862748207991',
          'ali' => '0.0124839473832316',
          'jamison' => '0.0124839473832316',
          'rex' => '0.0124839473832316',
          'robbie' => '0.0124839473832316',
          'josh' => '0.0123816199456641',
          'ashton' => '0.0122792925080967',
          'donnell' => '0.0122792925080967',
          'ignacio' => '0.0122792925080967',
          'conrad' => '0.0121769650705292',
          'harley' => '0.0120746376329617',
          'santos' => '0.0120746376329617',
          'conor' => '0.0119723101953942',
          'erich' => '0.0119723101953942',
          'myron' => '0.0119723101953942',
          'braden' => '0.0118699827578268',
          'garry' => '0.0118699827578268',
          'joesph' => '0.0118699827578268',
          'leland' => '0.0118699827578268',
          'rodrigo' => '0.0118699827578268',
          'ron' => '0.0118699827578268',
          'leonel' => '0.0117676553202593',
          'luther' => '0.0117676553202593',
          'marques' => '0.0117676553202593',
          'adan' => '0.0116653278826918',
          'davis' => '0.0116653278826918',
          'demario' => '0.0116653278826918',
          'guadalupe' => '0.0116653278826918',
          'heriberto' => '0.0115630004451244',
          'rigoberto' => '0.0115630004451244',
          'dorian' => '0.0114606730075569',
          'sherman' => '0.0114606730075569',
          'alton' => '0.0113583455699894',
          'sylvester' => '0.0113583455699894',
          'otis' => '0.0112560181324219',
          'shayne' => '0.0112560181324219',
          'ahmad' => '0.0111536906948545',
          'harvey' => '0.0111536906948545',
          'jaron' => '0.0111536906948545',
          'earnest' => '0.011051363257287',
          'markus' => '0.011051363257287',
          'tom' => '0.011051363257287',
          'blair' => '0.0109490358197195',
          'bryson' => '0.0109490358197195',
          'colt' => '0.0109490358197195',
          'marcel' => '0.0109490358197195',
          'vance' => '0.0109490358197195',
          'claude' => '0.010846708382152',
          'marty' => '0.010846708382152',
          'benito' => '0.0107443809445846',
          'bo' => '0.0107443809445846',
          'd' => '0.0107443809445846',
          'davon' => '0.0107443809445846',
          'gregg' => '0.0107443809445846',
          'mickey' => '0.0107443809445846',
          'raphael' => '0.0107443809445846',
          'agustin' => '0.0106420535070171',
          'benny' => '0.0106420535070171',
          'royce' => '0.0106420535070171',
          'tyree' => '0.0106420535070171',
          'barrett' => '0.0105397260694496',
          'eliezer' => '0.0105397260694496',
          'mauricio' => '0.0105397260694496',
          'ira' => '0.0104373986318822',
          'deon' => '0.0103350711943147',
          'garret' => '0.0103350711943147',
          'morris' => '0.0103350711943147',
          't' => '0.0102327437567472',
          'deshawn' => '0.0101304163191797',
          'elvin' => '0.0101304163191797',
          'jessica' => '0.0100280888816123',
          'jordon' => '0.0100280888816123',
          'quintin' => '0.0100280888816123',
          'akeem' => '0.0099257614440448',
          'matt' => '0.0099257614440448',
          'nathanial' => '0.0099257614440448',
          'nigel' => '0.0099257614440448',
          'bennie' => '0.00982343400647733',
          'elvis' => '0.00982343400647733',
          'roosevelt' => '0.00982343400647733',
          'kristian' => '0.00972110656890986',
          'shelby' => '0.00972110656890986',
          'antwon' => '0.00961877913134238',
          'bradly' => '0.00951645169377491',
          'hans' => '0.00951645169377491',
          'lane' => '0.00951645169377491',
          'aubrey' => '0.00941412425620744',
          'bill' => '0.00941412425620744',
          'm' => '0.00941412425620744',
          'osvaldo' => '0.00941412425620744',
          'pete' => '0.00941412425620744',
          'brant' => '0.00931179681863997',
          'damion' => '0.00931179681863997',
          'c' => '0.00920946938107249',
          'mitchel' => '0.00920946938107249',
          'nestor' => '0.00920946938107249',
          'dalton' => '0.00910714194350502',
          'jerod' => '0.00910714194350502',
          'maximilian' => '0.00910714194350502',
          'winston' => '0.00910714194350502',
          'hugh' => '0.00900481450593755',
          'jonas' => '0.00900481450593755',
          'darrel' => '0.00890248706837008',
          'reggie' => '0.00890248706837008',
          'w' => '0.00890248706837008',
          'whitney' => '0.00890248706837008',
          'amir' => '0.00880015963080261',
          'corbin' => '0.00880015963080261',
          'jennifer' => '0.00880015963080261',
          'kiel' => '0.00880015963080261',
          'raymundo' => '0.00880015963080261',
          'tory' => '0.00880015963080261',
          'virgil' => '0.00880015963080261',
          'bennett' => '0.00869783219323513',
          'irvin' => '0.00869783219323513',
          'jed' => '0.00869783219323513',
          'jerad' => '0.00869783219323513',
          'jerald' => '0.00869783219323513',
          'jovan' => '0.00869783219323513',
          'laurence' => '0.00869783219323513',
          'robby' => '0.00869783219323513',
          'german' => '0.00859550475566766',
          'nikolas' => '0.00859550475566766',
          'waylon' => '0.00859550475566766',
          'carey' => '0.00849317731810019',
          'chandler' => '0.00849317731810019',
          'domingo' => '0.00849317731810019',
          'isiah' => '0.00849317731810019',
          'jace' => '0.00849317731810019',
          'liam' => '0.00849317731810019',
          'rico' => '0.00849317731810019',
          'bronson' => '0.00839084988053272',
          'derik' => '0.00839084988053272',
          'teddy' => '0.00839084988053272',
          'willis' => '0.00839084988053272',
          'amos' => '0.00828852244296525',
          'jefferson' => '0.00828852244296525',
          'jeramy' => '0.00828852244296525',
          'arron' => '0.00818619500539777',
          'brenden' => '0.00818619500539777',
          'edmund' => '0.00818619500539777',
          'gregorio' => '0.00818619500539777',
          'jan' => '0.00818619500539777',
          'carter' => '0.0080838675678303',
          'dave' => '0.0080838675678303',
          'jasper' => '0.0080838675678303',
          'moshe' => '0.0080838675678303',
          'tucker' => '0.0080838675678303',
          'wallace' => '0.0080838675678303',
          'cary' => '0.00798154013026283',
          'cortney' => '0.00798154013026283',
          'curt' => '0.00798154013026283',
          'cyrus' => '0.00798154013026283',
          'jacques' => '0.00798154013026283',
          'keegan' => '0.00798154013026283',
          'rudolph' => '0.00798154013026283',
          'shea' => '0.00798154013026283',
          'tobias' => '0.00798154013026283',
          'ahmed' => '0.00787921269269536',
          'aric' => '0.00787921269269536',
          'dejuan' => '0.00787921269269536',
          'jered' => '0.00787921269269536',
          'jeremie' => '0.00787921269269536',
          'lukas' => '0.00787921269269536',
          'carlo' => '0.00777688525512788',
          'cruz' => '0.00777688525512788',
          'jamil' => '0.00777688525512788',
          'jerrell' => '0.00777688525512788',
          'josef' => '0.00777688525512788',
          'kelsey' => '0.00777688525512788',
          'prince' => '0.00777688525512788',
          'rodrick' => '0.00777688525512788',
          'skylar' => '0.00777688525512788',
          'stephon' => '0.00777688525512788',
          'chauncey' => '0.00767455781756041',
          'elmer' => '0.00767455781756041',
          'javon' => '0.00767455781756041',
          'jeromy' => '0.00767455781756041',
          'buddy' => '0.00757223037999294',
          'coty' => '0.00757223037999294',
          'issac' => '0.00757223037999294',
          'mikel' => '0.00757223037999294',
          'octavio' => '0.00757223037999294',
          'antione' => '0.00746990294242547',
          'brandan' => '0.00746990294242547',
          'darwin' => '0.00746990294242547',
          'efren' => '0.00746990294242547',
          'kameron' => '0.00746990294242547',
          'mohammad' => '0.00746990294242547',
          'brain' => '0.007367575504858',
          'daron' => '0.007367575504858',
          'davin' => '0.007367575504858',
          'devan' => '0.007367575504858',
          'donny' => '0.007367575504858',
          'ellis' => '0.007367575504858',
          'ezekiel' => '0.007367575504858',
          'ezra' => '0.007367575504858',
          'jeremey' => '0.007367575504858',
          'rocco' => '0.007367575504858',
          'cortez' => '0.00726524806729052',
          'darrick' => '0.00726524806729052',
          'duncan' => '0.00726524806729052',
          'griffin' => '0.00726524806729052',
          'leif' => '0.00726524806729052',
          'malik' => '0.00726524806729052',
          'timmy' => '0.00726524806729052',
          'adolfo' => '0.00716292062972305',
          'nicholaus' => '0.00716292062972305',
          'raheem' => '0.00716292062972305',
          'rhett' => '0.00716292062972305',
          'scottie' => '0.00716292062972305',
          'vaughn' => '0.00716292062972305',
          'cordell' => '0.00706059319215558',
          'ernie' => '0.00706059319215558',
          'estevan' => '0.00706059319215558',
          'norberto' => '0.00706059319215558',
          'tommie' => '0.00706059319215558',
          'addison' => '0.00695826575458811',
          'aldo' => '0.00695826575458811',
          'grady' => '0.00695826575458811',
          'jeffry' => '0.00695826575458811',
          'marion' => '0.00695826575458811',
          'shelton' => '0.00695826575458811',
          'ulysses' => '0.00695826575458811',
          'reinaldo' => '0.00685593831702063',
          'arnaldo' => '0.00675361087945316',
          'bernardo' => '0.00675361087945316',
          'cedrick' => '0.00675361087945316',
          'dario' => '0.00675361087945316',
          'irving' => '0.00675361087945316',
          'isaias' => '0.00675361087945316',
          'johnpaul' => '0.00675361087945316',
          'kirby' => '0.00675361087945316',
          'mackenzie' => '0.00675361087945316',
          'michel' => '0.00675361087945316',
          'mohammed' => '0.00675361087945316',
          'stevie' => '0.00675361087945316',
          'cristopher' => '0.00665128344188569',
          'dereck' => '0.00665128344188569',
          'gonzalo' => '0.00665128344188569',
          'hiram' => '0.00665128344188569',
          'rickie' => '0.00665128344188569',
          'stacy' => '0.00665128344188569',
          'tyrel' => '0.00665128344188569',
          'van' => '0.00665128344188569',
          'bart' => '0.00654895600431822',
          'keon' => '0.00654895600431822',
          'kraig' => '0.00654895600431822',
          'marquise' => '0.00654895600431822',
          'rashawn' => '0.00654895600431822',
          'tremaine' => '0.00654895600431822',
          'anderson' => '0.00644662856675075',
          'andrea' => '0.00644662856675075',
          'daren' => '0.00644662856675075',
          'deonte' => '0.00644662856675075',
          'dirk' => '0.00644662856675075',
          'ken' => '0.00644662856675075',
          'kristoffer' => '0.00644662856675075',
          'tim' => '0.00644662856675075',
          'a' => '0.00634430112918327',
          'amanda' => '0.00634430112918327',
          'antony' => '0.00634430112918327',
          'asa' => '0.00634430112918327',
          'eliseo' => '0.00634430112918327',
          'ervin' => '0.00634430112918327',
          'fidel' => '0.00634430112918327',
          'francesco' => '0.00634430112918327',
          'jedidiah' => '0.00634430112918327',
          'maria' => '0.00634430112918327',
          'paris' => '0.00634430112918327',
          'stacey' => '0.00634430112918327',
          'alphonso' => '0.0062419736916158',
          'horace' => '0.0062419736916158',
          'justen' => '0.0062419736916158',
          'kenton' => '0.0062419736916158',
          'monte' => '0.0062419736916158',
          'trever' => '0.0062419736916158',
          'westley' => '0.0062419736916158',
          'brannon' => '0.00613964625404833',
          'coleman' => '0.00613964625404833',
          'coy' => '0.00613964625404833',
          'cullen' => '0.00613964625404833',
          'denis' => '0.00613964625404833',
          'greggory' => '0.00613964625404833',
          'marlin' => '0.00613964625404833',
          'scot' => '0.00613964625404833',
          'tyron' => '0.00613964625404833',
          'dontae' => '0.00603731881648086',
          'hubert' => '0.00603731881648086',
          'lynn' => '0.00603731881648086',
          'cleveland' => '0.00593499137891338',
          'darian' => '0.00593499137891338',
          'denny' => '0.00593499137891338',
          'jarret' => '0.00593499137891338',
          'jedediah' => '0.00593499137891338',
          'judson' => '0.00593499137891338',
          'lincoln' => '0.00593499137891338',
          'mack' => '0.00593499137891338',
          'abram' => '0.00583266394134591',
          'cooper' => '0.00583266394134591',
          'darron' => '0.00583266394134591',
          'delbert' => '0.00583266394134591',
          'denver' => '0.00583266394134591',
          'isidro' => '0.00583266394134591',
          'jairo' => '0.00583266394134591',
          'jude' => '0.00583266394134591',
          'junior' => '0.00583266394134591',
          'keven' => '0.00583266394134591',
          'torrey' => '0.00583266394134591',
          'baby' => '0.00573033650377844',
          'chaim' => '0.00573033650377844',
          'elisha' => '0.00573033650377844',
          'galen' => '0.00573033650377844',
          'willard' => '0.00573033650377844',
          'adalberto' => '0.00562800906621097',
          'archie' => '0.00562800906621097',
          'cale' => '0.00562800906621097',
          'dewey' => '0.00562800906621097',
          'drake' => '0.00562800906621097',
          'garland' => '0.00562800906621097',
          'justine' => '0.00562800906621097',
          'lauren' => '0.00562800906621097',
          'louie' => '0.00562800906621097',
          'carmen' => '0.0055256816286435',
          'christoper' => '0.0055256816286435',
          'jayme' => '0.0055256816286435',
          'jeramie' => '0.0055256816286435',
          'johathan' => '0.0055256816286435',
          'l' => '0.0055256816286435',
          'roel' => '0.0055256816286435',
          's' => '0.0055256816286435',
          'sarah' => '0.0055256816286435',
          'tremayne' => '0.0055256816286435',
          'anibal' => '0.00542335419107602',
          'ari' => '0.00542335419107602',
          'augustine' => '0.00542335419107602',
          'broderick' => '0.00542335419107602',
          'cornell' => '0.00542335419107602',
          'demarco' => '0.00542335419107602',
          'federico' => '0.00542335419107602',
          'g' => '0.00542335419107602',
          'jade' => '0.00542335419107602',
          'lazaro' => '0.00542335419107602',
          'samir' => '0.00542335419107602',
          'vince' => '0.00542335419107602',
          'august' => '0.00532102675350855',
          'brandyn' => '0.00532102675350855',
          'chadd' => '0.00532102675350855',
          'e' => '0.00532102675350855',
          'grayson' => '0.00532102675350855',
          'jabari' => '0.00532102675350855',
          'jamey' => '0.00532102675350855',
          'lindsey' => '0.00532102675350855',
          'sammie' => '0.00532102675350855',
          'titus' => '0.00532102675350855',
          'wilbert' => '0.00532102675350855',
          'alonso' => '0.00521869931594108',
          'cassidy' => '0.00521869931594108',
          'darrius' => '0.00521869931594108',
          'donavan' => '0.00521869931594108',
          'elton' => '0.00521869931594108',
          'garrick' => '0.00521869931594108',
          'gino' => '0.00521869931594108',
          'hank' => '0.00521869931594108',
          'kris' => '0.00521869931594108',
          'kip' => '0.00511637187837361',
          'mohamed' => '0.00511637187837361',
          'percy' => '0.00511637187837361',
          'ryne' => '0.00511637187837361',
          'alexandro' => '0.00501404444080614',
          'bob' => '0.00501404444080614',
          'christop' => '0.00501404444080614',
          'danial' => '0.00501404444080614',
          'darien' => '0.00501404444080614',
          'deric' => '0.00501404444080614',
          'donta' => '0.00501404444080614',
          'edmond' => '0.00501404444080614',
          'jarrell' => '0.00501404444080614',
          'kai' => '0.00501404444080614',
          'muhammad' => '0.00501404444080614',
          'ramsey' => '0.00501404444080614',
          'wilfred' => '0.00501404444080614',
          'adrain' => '0.00491171700323866',
          'armand' => '0.00491171700323866',
          'aurelio' => '0.00491171700323866',
          'charley' => '0.00491171700323866',
          'derrell' => '0.00491171700323866',
          'edwardo' => '0.00491171700323866',
          'elizabeth' => '0.00491171700323866',
          'emerson' => '0.00491171700323866',
          'ezequiel' => '0.00491171700323866',
          'hassan' => '0.00491171700323866',
          'houston' => '0.00491171700323866',
          'jakob' => '0.00491171700323866',
          'kyler' => '0.00491171700323866',
          'michelle' => '0.00491171700323866',
          'rufus' => '0.00491171700323866',
          'schuyler' => '0.00491171700323866',
          'silas' => '0.00491171700323866',
          'uriel' => '0.00491171700323866',
          'abner' => '0.00480938956567119',
          'axel' => '0.00480938956567119',
          'brandt' => '0.00480938956567119',
          'dameon' => '0.00480938956567119',
          'emmett' => '0.00480938956567119',
          'erwin' => '0.00480938956567119',
          'hayden' => '0.00480938956567119',
          'jasen' => '0.00480938956567119',
          'jerel' => '0.00480938956567119',
          'joshuah' => '0.00480938956567119',
          'juston' => '0.00480938956567119',
          'keaton' => '0.00480938956567119',
          'laron' => '0.00480938956567119',
          'ronny' => '0.00480938956567119',
          'russel' => '0.00480938956567119',
          'tad' => '0.00480938956567119',
          'taurean' => '0.00480938956567119',
          'travon' => '0.00480938956567119',
          'bruno' => '0.00470706212810372',
          'cade' => '0.00470706212810372',
          'christina' => '0.00470706212810372',
          'coby' => '0.00470706212810372',
          'demetris' => '0.00470706212810372',
          'eddy' => '0.00470706212810372',
          'rey' => '0.00470706212810372'
         };

$Females = {
            'jessica' => '2.535806627657',
            'jennifer' => '2.37881388243059',
            'amanda' => '1.95012756995522',
            'ashley' => '1.86778647705076',
            'sarah' => '1.46056651953492',
            'stephanie' => '1.17392126226439',
            'melissa' => '1.16964935082966',
            'nicole' => '1.12917298998557',
            'elizabeth' => '1.06658948746675',
            'heather' => '1.03764728749644',
            'tiffany' => '0.856625040449661',
            'michelle' => '0.836760652278157',
            'amber' => '0.825546884761985',
            'megan' => '0.814439915031682',
            'rachel' => '0.79062400878305',
            'amy' => '0.787740468564606',
            'lauren' => '0.786245299562449',
            'kimberly' => '0.766808102534418',
            'christina' => '0.76606051803334',
            'brittany' => '0.763283775600764',
            'crystal' => '0.745341747574889',
            'rebecca' => '0.726224943904463',
            'laura' => '0.722059830255599',
            'emily' => '0.698884710722177',
            'danielle' => '0.696641957218943',
            'samantha' => '0.660544305595456',
            'angela' => '0.614514459886218',
            'erin' => '0.613446482027535',
            'kelly' => '0.597640409719026',
            'sara' => '0.554280508656494',
            'lisa' => '0.540930785422957',
            'katherine' => '0.533027749268702',
            'andrea' => '0.515940103529774',
            'mary' => '0.515406114600432',
            'jamie' => '0.514338136741749',
            'erica' => '0.504405942655997',
            'courtney' => '0.448977891790347',
            'kristen' => '0.439152495490464',
            'shannon' => '0.418540522817881',
            'april' => '0.412987037952729',
            'maria' => '0.386287591485653',
            'kristin' => '0.381054499978106',
            'katie' => '0.379345735404214',
            'lindsey' => '0.377209779686847',
            'alicia' => '0.363753258667441',
            'vanessa' => '0.358520167159894',
            'lindsay' => '0.353073480080611',
            'christine' => '0.350510333219772',
            'allison' => '0.341218925849229',
            'kathryn' => '0.332141114050424',
            'julie' => '0.326480831399403',
            'tara' => '0.305441667583348',
            'anna' => '0.297004642499752',
            'natalie' => '0.2958298668552',
            'kayla' => '0.293693911137834',
            'victoria' => '0.282052952478189',
            'jacqueline' => '0.281946154692321',
            'monica' => '0.280237390118428',
            'holly' => '0.26816924031531',
            'cassandra' => '0.257916652871953',
            'patricia' => '0.24862524550141',
            'kristina' => '0.245421311925361',
            'catherine' => '0.233353162122243',
            'cynthia' => '0.232391982049428',
            'brandy' => '0.231110408619009',
            'whitney' => '0.228867655115774',
            'chelsea' => '0.227586081685355',
            'veronica' => '0.22598411489733',
            'brandi' => '0.22534332818212',
            'leslie' => '0.21338197616487',
            'kathleen' => '0.209537255873611',
            'stacy' => '0.205799333368221',
            'diana' => '0.204624557723669',
            'erika' => '0.201634219719357',
            'natasha' => '0.201527421933488',
            'meghan' => '0.200886635218279',
            'dana' => '0.199071072858517',
            'carrie' => '0.196614723783546',
            'krystal' => '0.196080734854205',
            'karen' => '0.194585565852049',
            'jenna' => '0.193944779136839',
            'leah' => '0.192556407920551',
            'melanie' => '0.189672867702107',
            'valerie' => '0.187857305342346',
            'alexandra' => '0.186041742982584',
            'brooke' => '0.180381460331564',
            'jasmine' => '0.179099886901145',
            'julia' => '0.178031909042462',
            'alyssa' => '0.176002751110964',
            'caitlin' => '0.174187188751203',
            'hannah' => '0.1718376374621',
            'brittney' => '0.168633703886051',
            'stacey' => '0.168526906100183',
            'sandra' => '0.16617735481108',
            'margaret' => '0.163507410164372',
            'susan' => '0.163507410164372',
            'candice' => '0.16115785887527',
            'bethany' => '0.157313138584011',
            'casey' => '0.156458756297064',
            'katrina' => '0.15549757622425',
            'latoya' => '0.154429598365567',
            'tracy' => '0.15421600279383',
            'misty' => '0.150798473646044',
            'kelsey' => '0.149730495787361',
            'kara' => '0.148342124571073',
            'nichole' => '0.145031393209156',
            'alison' => '0.144283808708078',
            'molly' => '0.141827459633107',
            'tina' => '0.140652683988556',
            'denise' => '0.140118695059214',
            'heidi' => '0.139050717200531',
            'alexis' => '0.138837121628794',
            'jillian' => '0.138409930485321',
            'brenda' => '0.135633188052745',
            'candace' => '0.134138019050589',
            'nancy' => '0.133817625692984',
            'rachael' => '0.133070041191906',
            'pamela' => '0.132856445620169',
            'morgan' => '0.131681669975618',
            'renee' => '0.131040883260408',
            'gina' => '0.129972905401725',
            'jill' => '0.128904927543042',
            'kendra' => '0.128050545256096',
            'teresa' => '0.127302960755018',
            'sabrina' => '0.12591458953873',
            'miranda' => '0.124846611680047',
            'krista' => '0.123565038249627',
            'felicia' => '0.123137847106154',
            'kristy' => '0.122283464819207',
            'anne' => '0.121642678103998',
            'robin' => '0.121108689174656',
            'monique' => '0.120574700245315',
            'linda' => '0.119827115744236',
            'desiree' => '0.119506722386631',
            'theresa' => '0.119506722386631',
            'wendy' => '0.119079531243158',
            'joanna' => '0.118652340099685',
            'tanya' => '0.117370766669265',
            'melinda' => '0.117157171097529',
            'lori' => '0.116623182168187',
            'jaclyn' => '0.116195991024714',
            'tamara' => '0.115341608737768',
            'alisha' => '0.114700822022558',
            'kelli' => '0.114166833093216',
            'dawn' => '0.113526046378006',
            'colleen' => '0.113098855234533',
            'marissa' => '0.113098855234533',
            'lacey' => '0.110962899517167',
            'christy' => '0.110001719444352',
            'abigail' => '0.109788123872616',
            'angelica' => '0.106797785868303',
            'jenny' => '0.104875425722674',
            'barbara' => '0.101885087718361',
            'tabitha' => '0.101457896574888',
            'caroline' => '0.100389918716205',
            'kari' => '0.1000695253586',
            'meredith' => '0.1000695253586',
            'kristi' => '0.0980403674271025',
            'ebony' => '0.0977199740694976',
            'deanna' => '0.0971859851401561',
            'rebekah' => '0.0960112094956047',
            'carolyn' => '0.0954772205662632',
            'marie' => '0.0936616582065021',
            'ana' => '0.0929140737054239',
            'michele' => '0.0922732869902141',
            'tonya' => '0.0916325002750043',
            'angel' => '0.0908849157739262',
            'sharon' => '0.090457724630453',
            'bridget' => '0.0903509268445847',
            'tasha' => '0.0901373312728481',
            'sheena' => '0.0891761512000333',
            'cristina' => '0.0888557578424284',
            'brianna' => '0.0885353644848235',
            'priscilla' => '0.0874673866261405',
            'deborah' => '0.0868265999109306',
            'cassie' => '0.0867198021250623',
            'ashlee' => '0.086613004339194',
            'carmen' => '0.0863994087674574',
            'meagan' => '0.0859722176239842',
            'ann' => '0.0853314309087744',
            'cindy' => '0.0847974419794329',
            'stefanie' => '0.0838362619066182',
            'tammy' => '0.0825546884761985',
            'dominique' => '0.0823410929044619',
            'carla' => '0.0819139017609887',
            'virginia' => '0.0818071039751204',
            'regina' => '0.0812731150457789',
            'jaime' => '0.080952721688174',
            'adrienne' => '0.079564350471886',
            'mallory' => '0.0791371593284128',
            'audrey' => '0.0778555858979932',
            'beth' => '0.0776419903262566',
            'olivia' => '0.0774283947545199',
            'katelyn' => '0.0770012036110467',
            'latasha' => '0.0766808102534418',
            'cheryl' => '0.0758264279664954',
            'taylor' => '0.0755060346088905',
            'jordan' => '0.0753992368230222',
            'janet' => '0.0751856412512856',
            'kristine' => '0.0732632811056561',
            'jacquelyn' => '0.0731564833197878',
            'mandy' => '0.0730496855339195',
            'aimee' => '0.0724088988187097',
            'claudia' => '0.0720885054611048',
            'autumn' => '0.0705933364589485',
            'trisha' => '0.0703797408872119',
            'bianca' => '0.0701661453154753',
            'cara' => '0.0701661453154753',
            'martha' => '0.070059347529607',
            'rosa' => '0.070059347529607',
            'suzanne' => '0.0685641785274508',
            'haley' => '0.0680301895981092',
            'nina' => '0.067602998454636',
            'carly' => '0.0673894028828994',
            'mindy' => '0.0672826050970311',
            'kate' => '0.0671758073111628',
            'donna' => '0.0670690095252945',
            'jodi' => '0.0657874360948749',
            'karla' => '0.0656806383090066',
            'shawna' => '0.0656806383090066',
            'yolanda' => '0.0655738405231383',
            'bonnie' => '0.06546704273727',
            'summer' => '0.0653602449514017',
            'evelyn' => '0.0637582781633771',
            'adriana' => '0.0635446825916405',
            'grace' => '0.0633310870199039',
            'kaitlin' => '0.0631174914481673',
            'ruth' => '0.0627970980905624',
            'toni' => '0.0627970980905624',
            'mayra' => '0.061942715803616',
            'alexandria' => '0.0608747379449329',
            'lydia' => '0.0606611423731963',
            'abby' => '0.0604475468014597',
            'kaitlyn' => '0.0604475468014597',
            'janelle' => '0.0602339512297231',
            'robyn' => '0.0602339512297231',
            'briana' => '0.0600203556579865',
            'gabrielle' => '0.0598067600862499',
            'joy' => '0.0593795689427767',
            'sheila' => '0.0590591755851718',
            'paula' => '0.0587387822275669',
            'diane' => '0.0582047932982253',
            'kellie' => '0.0577776021547521',
            'gloria' => '0.0571368154395423',
            'melody' => '0.0566028265102008',
            'naomi' => '0.0562824331525959',
            'jessie' => '0.0561756353667276',
            'sophia' => '0.0557484442232544',
            'daisy' => '0.0555348486515178',
            'raquel' => '0.0554280508656495',
            'christie' => '0.0553212530797811',
            'rose' => '0.0553212530797811',
            'krystle' => '0.0548940619363079',
            'amelia' => '0.0547872641504396',
            'paige' => '0.0547872641504396',
            'shanna' => '0.0547872641504396',
            'sonia' => '0.0546804663645713',
            'randi' => '0.0543600730069664',
            'johanna' => '0.0541464774352298',
            'kasey' => '0.0540396796493615',
            'frances' => '0.0536124885058883',
            'claire' => '0.05350569072002',
            'nikki' => '0.05350569072002',
            'ellen' => '0.0533988929341517',
            'hillary' => '0.0531852973624151',
            'sasha' => '0.0531852973624151',
            'yesenia' => '0.0530784995765468',
            'jeanette' => '0.0527581062189419',
            'ashleigh' => '0.0525445106472053',
            'emma' => '0.052437712861337',
            'marisa' => '0.0515833305743905',
            'traci' => '0.0505153527157075',
            'charlene' => '0.0501949593581026',
            'shana' => '0.0501949593581026',
            'shelly' => '0.0501949593581026',
            'roxanne' => '0.0500881615722343',
            'jocelyn' => '0.049981363786366',
            'sylvia' => '0.049981363786366',
            'kelley' => '0.0494473748570245',
            'carol' => '0.0491269814994196',
            'justine' => '0.0491269814994196',
            'britney' => '0.0490201837135512',
            'rachelle' => '0.0488065881418146',
            'charity' => '0.048592992570078',
            'keri' => '0.048592992570078',
            'kirsten' => '0.0483793969983414',
            'yvonne' => '0.0483793969983414',
            'debra' => '0.0482725992124731',
            'christa' => '0.0479522058548682',
            'shauna' => '0.0477386102831316',
            'sonya' => '0.0476318124972633',
            'chelsey' => '0.0469910257820535',
            'esther' => '0.0463502390668437',
            'charlotte' => '0.0462434412809754',
            'anita' => '0.0460298457092388',
            'savannah' => '0.0459230479233705',
            'sierra' => '0.0457094523516338',
            'angelina' => '0.0452822612081606',
            'brianne' => '0.0452822612081606',
            'sherry' => '0.0451754634222923',
            'gabriela' => '0.0448550700646874',
            'leigh' => '0.0447482722788191',
            'rhonda' => '0.0446414744929508',
            'stacie' => '0.0446414744929508',
            'kerry' => '0.0445346767070825',
            'karina' => '0.0444278789212142',
            'annie' => '0.0443210811353459',
            'kristie' => '0.0443210811353459',
            'kerri' => '0.0442142833494776',
            'carissa' => '0.044000687777741',
            'eva' => '0.044000687777741',
            'shelby' => '0.044000687777741',
            'lacy' => '0.0438938899918727',
            'alissa' => '0.0433599010625312',
            'tia' => '0.0433599010625312',
            'laurie' => '0.0430395077049263',
            'tracey' => '0.0430395077049263',
            'janice' => '0.0428259121331897',
            'alice' => '0.0427191143473213',
            'elise' => '0.0422919232038481',
            'miriam' => '0.0421851254179798',
            'elisabeth' => '0.0418647320603749',
            'yvette' => '0.0412239453451651',
            'helen' => '0.0411171475592968',
            'terri' => '0.0411171475592968',
            'latisha' => '0.0409035519875602',
            'tricia' => '0.0407967542016919',
            'maggie' => '0.0405831586299553',
            'breanna' => '0.0401559674864821',
            'camille' => '0.0400491697006138',
            'leticia' => '0.0398355741288772',
            'annette' => '0.0397287763430089',
            'tamika' => '0.0396219785571406',
            'jane' => '0.0394083829854039',
            'maureen' => '0.0394083829854039',
            'sandy' => '0.0393015851995356',
            'hilary' => '0.0391947874136673',
            'katharine' => '0.0385540006984575',
            'tabatha' => '0.0384472029125892',
            'keisha' => '0.038020011769116',
            'rochelle' => '0.0379132139832477',
            'aubrey' => '0.0378064161973794',
            'allyson' => '0.0376996184115111',
            'elisa' => '0.0374860228397745',
            'lesley' => '0.0373792250539062',
            'antoinette' => '0.0371656294821696',
            'cecilia' => '0.0371656294821696',
            'lynn' => '0.0371656294821696',
            'elaine' => '0.0370588316963013',
            'irene' => '0.0370588316963013',
            'staci' => '0.0370588316963013',
            'jana' => '0.036952033910433',
            'chasity' => '0.0368452361245647',
            'dorothy' => '0.0366316405528281',
            'faith' => '0.0365248427669598',
            'hope' => '0.0365248427669598',
            'lorena' => '0.0365248427669598',
            'alana' => '0.0360976516234865',
            'marilyn' => '0.0360976516234865',
            'elena' => '0.0356704604800133',
            'jade' => '0.0356704604800133',
            'bobbie' => '0.035563662694145',
            'brandie' => '0.035563662694145',
            'kathy' => '0.035563662694145',
            'maribel' => '0.0354568649082767',
            'cortney' => '0.0353500671224084',
            'clarissa' => '0.0352432693365401',
            'rita' => '0.0352432693365401',
            'shelley' => '0.0351364715506718',
            'juanita' => '0.0350296737648035',
            'destiny' => '0.0348160781930669',
            'sally' => '0.0347092804071986',
            'marquita' => '0.0346024826213303',
            'amie' => '0.0343888870495937',
            'jami' => '0.0343888870495937',
            'tanisha' => '0.0343888870495937',
            'norma' => '0.0342820892637254',
            'ericka' => '0.0340684936919888',
            'katy' => '0.0340684936919888',
            'ruby' => '0.0340684936919888',
            'tessa' => '0.0340684936919888',
            'madeline' => '0.033427706976779',
            'jackie' => '0.0333209091909107',
            'jennie' => '0.0333209091909107',
            'eileen' => '0.033107313619174',
            'ryan' => '0.033107313619174',
            'angie' => '0.0330005158333057',
            'ariel' => '0.0330005158333057',
            'leanne' => '0.0325733246898325',
            'guadalupe' => '0.0324665269039642',
            'marisol' => '0.0322529313322276',
            'meaghan' => '0.0322529313322276',
            'chrystal' => '0.0321461335463593',
            'alma' => '0.0319325379746227',
            'judith' => '0.0319325379746227',
            'alyson' => '0.0317189424028861',
            'jasmin' => '0.0317189424028861',
            'shirley' => '0.0317189424028861',
            'lakeisha' => '0.0316121446170178',
            'luz' => '0.0315053468311495',
            'nora' => '0.0315053468311495',
            'jenifer' => '0.0313985490452812',
            'mia' => '0.0312917512594129',
            'lillian' => '0.0311849534735446',
            'connie' => '0.0310781556876763',
            'beverly' => '0.030971357901808',
            'constance' => '0.0308645601159397',
            'patrice' => '0.0308645601159397',
            'taryn' => '0.0307577623300714',
            'jolene' => '0.0305441667583348',
            'lyndsey' => '0.0304373689724665',
            'alejandra' => '0.0302237734007299',
            'tiara' => '0.0301169756148616',
            'christin' => '0.0299033800431249',
            'gretchen' => '0.0299033800431249',
            'hayley' => '0.0299033800431249',
            'genevieve' => '0.0297965822572566',
            'latonya' => '0.0297965822572566',
            'becky' => '0.0293693911137834',
            'kira' => '0.0292625933279151',
            'kylie' => '0.0291557955420468',
            'nadia' => '0.0289421999703102',
            'joanne' => '0.0288354021844419',
            'joyce' => '0.0288354021844419',
            'lara' => '0.028515008826837',
            'christian' => '0.0284082110409687',
            'devon' => '0.0284082110409687',
            'iris' => '0.0284082110409687',
            'serena' => '0.0284082110409687',
            'shayla' => '0.0284082110409687',
            'tatiana' => '0.0283014132551004',
            'ariana' => '0.0279810198974955',
            'marlene' => '0.0279810198974955',
            'betty' => '0.0276606265398906',
            'blanca' => '0.0275538287540223',
            'rosemary' => '0.0275538287540223',
            'tania' => '0.027447030968154',
            'carolina' => '0.0273402331822857',
            'jean' => '0.0273402331822857',
            'josephine' => '0.0272334353964174',
            'lena' => '0.0271266376105491',
            'michael' => '0.0271266376105491',
            'corinne' => '0.0270198398246808',
            'judy' => '0.0269130420388125',
            'natalia' => '0.0268062442529441',
            'audra' => '0.0265926486812075',
            'jody' => '0.0264858508953392',
            'belinda' => '0.0263790531094709',
            'celeste' => '0.0263790531094709',
            'sherri' => '0.0263790531094709',
            'alisa' => '0.0262722553236026',
            'blair' => '0.0262722553236026',
            'elyse' => '0.0261654575377343',
            'hollie' => '0.0261654575377343',
            'anastasia' => '0.026058659751866',
            'esmeralda' => '0.026058659751866',
            'sheri' => '0.026058659751866',
            'trista' => '0.026058659751866',
            'brittani' => '0.0259518619659977',
            'elisha' => '0.0258450641801294',
            'isabel' => '0.0258450641801294',
            'leann' => '0.0258450641801294',
            'terra' => '0.0258450641801294',
            'jayme' => '0.0255246708225245',
            'alexa' => '0.0254178730366562',
            'darlene' => '0.0253110752507879',
            'noelle' => '0.0252042774649196',
            'callie' => '0.024990681893183',
            'chantel' => '0.024990681893183',
            'laurel' => '0.0247770863214464',
            'christen' => '0.0246702885355781',
            'tiffani' => '0.0246702885355781',
            'billie' => '0.0245634907497098',
            'chandra' => '0.0245634907497098',
            'margarita' => '0.0245634907497098',
            'brenna' => '0.0244566929638415',
            'liliana' => '0.0244566929638415',
            'joann' => '0.0242430973921049',
            'tameka' => '0.0242430973921049',
            'caitlyn' => '0.0240295018203683',
            'ginger' => '0.0240295018203683',
            'larissa' => '0.0240295018203683',
            'lucy' => '0.0239227040345',
            'tracie' => '0.0239227040345',
            'teri' => '0.0237091084627633',
            'ashlie' => '0.0234955128910267',
            'sydney' => '0.0234955128910267',
            'ciara' => '0.0231751195334218',
            'julianne' => '0.0231751195334218',
            'michaela' => '0.0231751195334218',
            'vivian' => '0.0231751195334218',
            'bobbi' => '0.0230683217475535',
            'dianna' => '0.0230683217475535',
            'francesca' => '0.0230683217475535',
            'mercedes' => '0.0230683217475535',
            'daniela' => '0.0229615239616852',
            'juliana' => '0.0229615239616852',
            'bridgette' => '0.0228547261758169',
            'kristal' => '0.0228547261758169',
            'lakisha' => '0.0227479283899486',
            'simone' => '0.0226411306040803',
            'jacklyn' => '0.0224275350323437',
            'janine' => '0.0224275350323437',
            'lorraine' => '0.0224275350323437',
            'mandi' => '0.0224275350323437',
            'marina' => '0.0224275350323437',
            'shaina' => '0.0223207372464754',
            'alaina' => '0.0222139394606071',
            'jodie' => '0.0222139394606071',
            'angelique' => '0.0221071416747388',
            'lynette' => '0.0221071416747388',
            'breanne' => '0.0220003438888705',
            'kyla' => '0.0220003438888705',
            'lee' => '0.0220003438888705',
            'arlene' => '0.0218935461030022',
            'gwendolyn' => '0.0218935461030022',
            'kimberley' => '0.0218935461030022',
            'aisha' => '0.0217867483171339',
            'jena' => '0.0217867483171339',
            'tiffanie' => '0.0217867483171339',
            'arielle' => '0.0216799505312656',
            'chelsie' => '0.0216799505312656',
            'jeannette' => '0.0216799505312656',
            'india' => '0.0215731527453973',
            'mackenzie' => '0.0215731527453973',
            'tiana' => '0.0215731527453973',
            'tori' => '0.0215731527453973',
            'karissa' => '0.021466354959529',
            'lea' => '0.0212527593877924',
            'betsy' => '0.0211459616019241',
            'casandra' => '0.0211459616019241',
            'shayna' => '0.0211459616019241',
            'kendall' => '0.0210391638160558',
            'racheal' => '0.0210391638160558',
            'christi' => '0.0207187704584509',
            'susana' => '0.0207187704584509',
            'abbey' => '0.0206119726725826',
            'devin' => '0.0206119726725826',
            'madison' => '0.0206119726725826',
            'melisa' => '0.0206119726725826',
            'bailey' => '0.0203983771008459',
            'clara' => '0.0203983771008459',
            'joan' => '0.0203983771008459',
            'christopher' => '0.0202915793149776',
            'chanel' => '0.0201847815291093',
            'fallon' => '0.0201847815291093',
            'adrian' => '0.020077983743241',
            'dena' => '0.020077983743241',
            'hailey' => '0.0198643881715044',
            'joni' => '0.0198643881715044',
            'lana' => '0.0197575903856361',
            'lora' => '0.0197575903856361',
            'shari' => '0.0197575903856361',
            'tierra' => '0.0197575903856361',
            'bernadette' => '0.0196507925997678',
            'celia' => '0.0196507925997678',
            'adrianna' => '0.0195439948138995',
            'cathy' => '0.0195439948138995',
            'dina' => '0.0195439948138995',
            'lashonda' => '0.0195439948138995',
            'jazmin' => '0.0194371970280312',
            'marsha' => '0.0194371970280312',
            'ashly' => '0.0193303992421629',
            'debbie' => '0.0193303992421629',
            'maritza' => '0.0193303992421629',
            'raven' => '0.0192236014562946',
            'kassandra' => '0.0191168036704263',
            'kim' => '0.0191168036704263',
            'roberta' => '0.0191168036704263',
            'selena' => '0.0191168036704263',
            'wanda' => '0.0191168036704263',
            'shantel' => '0.019010005884558',
            'asia' => '0.0189032080986897',
            'ashton' => '0.0187964103128214',
            'adrianne' => '0.0185828147410848',
            'janette' => '0.0185828147410848',
            'jaimie' => '0.0184760169552165',
            'kiara' => '0.0184760169552165',
            'precious' => '0.0184760169552165',
            'yadira' => '0.0184760169552165',
            'ingrid' => '0.0183692191693482',
            'trina' => '0.0183692191693482',
            'cori' => '0.0182624213834799',
            'kali' => '0.0182624213834799',
            'kaylee' => '0.0182624213834799',
            'mariah' => '0.0182624213834799',
            'rhiannon' => '0.0182624213834799',
            'edith' => '0.0180488258117433',
            'kacie' => '0.0180488258117433',
            'mollie' => '0.017942028025875',
            'araceli' => '0.0178352302400067',
            'cherie' => '0.0178352302400067',
            'cierra' => '0.0178352302400067',
            'janna' => '0.0178352302400067',
            'lacie' => '0.0178352302400067',
            'marjorie' => '0.0178352302400067',
            'rosanna' => '0.0178352302400067',
            'corina' => '0.0177284324541384',
            'eliza' => '0.0176216346682701',
            'chloe' => '0.0175148368824018',
            'maranda' => '0.0175148368824018',
            'alecia' => '0.0174080390965335',
            'cassidy' => '0.0174080390965335',
            'kenya' => '0.0174080390965335',
            'lucia' => '0.0174080390965335',
            'sade' => '0.0174080390965335',
            'marianne' => '0.0173012413106651',
            'shameka' => '0.0173012413106651',
            'cari' => '0.0170876457389285',
            'lakesha' => '0.0170876457389285',
            'talia' => '0.0170876457389285',
            'antonia' => '0.0169808479530602',
            'gladys' => '0.0169808479530602',
            'ivy' => '0.0169808479530602',
            'jeanne' => '0.0169808479530602',
            'loretta' => '0.0168740501671919',
            'sadie' => '0.0168740501671919',
            'tera' => '0.0168740501671919',
            'latosha' => '0.0167672523813236',
            'lyndsay' => '0.0167672523813236',
            'octavia' => '0.0167672523813236',
            'beatriz' => '0.0166604545954553',
            'liza' => '0.0166604545954553',
            'nikita' => '0.0166604545954553',
            'rocio' => '0.0166604545954553',
            'kristyn' => '0.016553656809587',
            'latrice' => '0.016553656809587',
            'silvia' => '0.016553656809587',
            'catrina' => '0.0164468590237187',
            'leanna' => '0.0164468590237187',
            'myra' => '0.0164468590237187',
            'olga' => '0.0164468590237187',
            'sonja' => '0.0164468590237187',
            'tami' => '0.0164468590237187',
            'dara' => '0.0163400612378504',
            'dayna' => '0.0163400612378504',
            'peggy' => '0.0163400612378504',
            'cheri' => '0.0162332634519821',
            'justina' => '0.0162332634519821',
            'ashely' => '0.0161264656661138',
            'giselle' => '0.0161264656661138',
            'marcella' => '0.0161264656661138',
            'beatrice' => '0.0160196678802455',
            'jesse' => '0.0160196678802455',
            'marcia' => '0.0160196678802455',
            'maya' => '0.0160196678802455',
            'damaris' => '0.0159128700943772',
            'bridgett' => '0.0158060723085089',
            'darcy' => '0.0158060723085089',
            'deidre' => '0.0158060723085089',
            'maricela' => '0.0158060723085089',
            'candy' => '0.0156992745226406',
            'glenda' => '0.0156992745226406',
            'marisela' => '0.0156992745226406',
            'nicolette' => '0.0156992745226406',
            'deana' => '0.0155924767367723',
            'marci' => '0.0155924767367723',
            'marla' => '0.0155924767367723',
            'athena' => '0.015485678950904',
            'lourdes' => '0.015485678950904',
            'maegan' => '0.015485678950904',
            'nadine' => '0.015485678950904',
            'corey' => '0.0153788811650357',
            'carina' => '0.0152720833791674',
            'daniel' => '0.0152720833791674',
            'elissa' => '0.0152720833791674',
            'irma' => '0.0152720833791674',
            'janie' => '0.0152720833791674',
            'desirae' => '0.0151652855932991',
            'eboni' => '0.0151652855932991',
            'james' => '0.0151652855932991',
            'mariana' => '0.0151652855932991',
            'pauline' => '0.0151652855932991',
            'noemi' => '0.0150584878074308',
            'penny' => '0.0150584878074308',
            'yahaira' => '0.0150584878074308',
            'ciera' => '0.0149516900215625',
            'tosha' => '0.0149516900215625',
            'leeann' => '0.0148448922356942',
            'martina' => '0.0148448922356942',
            'alanna' => '0.0147380944498259',
            'alesha' => '0.0147380944498259',
            'doris' => '0.0147380944498259',
            'shamika' => '0.0147380944498259',
            'jeannie' => '0.0146312966639576',
            'kayleigh' => '0.0146312966639576',
            'laci' => '0.0146312966639576',
            'marlena' => '0.0146312966639576',
            'hanna' => '0.0145244988780893',
            'shanika' => '0.0145244988780893',
            'cristal' => '0.014417701092221',
            'daniella' => '0.014417701092221',
            'maura' => '0.014417701092221',
            'yaritza' => '0.014417701092221',
            'georgia' => '0.0143109033063527',
            'justin' => '0.0142041055204843',
            'linsey' => '0.0142041055204843',
            'marcie' => '0.0142041055204843',
            'alycia' => '0.0139905099487477',
            'cora' => '0.0139905099487477',
            'janae' => '0.0139905099487477',
            'sheryl' => '0.0139905099487477',
            'geneva' => '0.0138837121628794',
            'kyra' => '0.0138837121628794',
            'lily' => '0.0138837121628794',
            'loren' => '0.0138837121628794',
            'valarie' => '0.0138837121628794',
            'david' => '0.0137769143770111',
            'janell' => '0.0137769143770111',
            'joshua' => '0.0137769143770111',
            'josie' => '0.0137769143770111',
            'kyle' => '0.0137769143770111',
            'roxana' => '0.0137769143770111',
            'sofia' => '0.0137769143770111',
            'candi' => '0.0136701165911428',
            'dora' => '0.0136701165911428',
            'joelle' => '0.0136701165911428',
            'karin' => '0.0136701165911428',
            'lizette' => '0.0136701165911428',
            'shante' => '0.0136701165911428',
            'brittni' => '0.0135633188052745',
            'marian' => '0.0135633188052745',
            'ramona' => '0.0135633188052745',
            'aileen' => '0.0134565210194062',
            'fatima' => '0.0134565210194062',
            'alysha' => '0.0133497232335379',
            'misti' => '0.0133497232335379',
            'rena' => '0.0133497232335379',
            'shawn' => '0.0133497232335379',
            'brook' => '0.0132429254476696',
            'chastity' => '0.0132429254476696',
            'mara' => '0.0132429254476696',
            'nathalie' => '0.0132429254476696',
            'deidra' => '0.0131361276618013',
            'kala' => '0.0131361276618013',
            'noel' => '0.0131361276618013',
            'selina' => '0.0131361276618013',
            'shanda' => '0.0131361276618013',
            'xiomara' => '0.0131361276618013',
            'carey' => '0.013029329875933',
            'celina' => '0.013029329875933',
            'christal' => '0.013029329875933',
            'keshia' => '0.013029329875933',
            'maryann' => '0.013029329875933',
            'sheree' => '0.013029329875933',
            'daphne' => '0.0129225320900647',
            'janel' => '0.0129225320900647',
            'eleanor' => '0.0128157343041964',
            'julianna' => '0.0128157343041964',
            'kacey' => '0.0128157343041964',
            'mckenzie' => '0.0128157343041964',
            'abbie' => '0.0127089365183281',
            'emilee' => '0.0127089365183281',
            'marta' => '0.0127089365183281',
            'matthew' => '0.0127089365183281',
            'rebeca' => '0.0127089365183281',
            'robert' => '0.0127089365183281',
            'kourtney' => '0.0126021387324598',
            'tanesha' => '0.0126021387324598',
            'andria' => '0.0124953409465915',
            'elsa' => '0.0124953409465915',
            'gail' => '0.0124953409465915',
            'malinda' => '0.0124953409465915',
            'danelle' => '0.0123885431607232',
            'emilie' => '0.0123885431607232',
            'gabriella' => '0.0123885431607232',
            'griselda' => '0.0123885431607232',
            'kandice' => '0.0123885431607232',
            'casie' => '0.0122817453748549',
            'cheyenne' => '0.0122817453748549',
            'demetria' => '0.0122817453748549',
            'kimberlee' => '0.0122817453748549',
            'roxanna' => '0.0122817453748549',
            'stephany' => '0.0122817453748549',
            'britni' => '0.0121749475889866',
            'chiquita' => '0.0121749475889866',
            'gillian' => '0.0121749475889866',
            'kati' => '0.0121749475889866',
            'kori' => '0.0121749475889866',
            'lynda' => '0.0121749475889866',
            'siobhan' => '0.0121749475889866',
            'chantelle' => '0.0120681498031183',
            'holli' => '0.0120681498031183',
            'jo' => '0.0120681498031183',
            'kelsie' => '0.0120681498031183',
            'vicki' => '0.0120681498031183',
            'vicky' => '0.0120681498031183',
            'marcy' => '0.01196135201725',
            'ashli' => '0.0118545542313817',
            'delia' => '0.0118545542313817',
            'jeanine' => '0.0118545542313817',
            'kaci' => '0.0118545542313817',
            'renae' => '0.0118545542313817',
            'sherrie' => '0.0118545542313817',
            'viviana' => '0.0118545542313817',
            'darla' => '0.0117477564455134',
            'edna' => '0.0117477564455134',
            'jesica' => '0.0117477564455134',
            'john' => '0.0117477564455134',
            'kylee' => '0.0117477564455134',
            'rosemarie' => '0.0117477564455134',
            'aja' => '0.0116409586596451',
            'cody' => '0.0116409586596451',
            'georgina' => '0.0116409586596451',
            'jazmine' => '0.0116409586596451',
            'kathrine' => '0.0116409586596451',
            'brandon' => '0.0115341608737768',
            'dolores' => '0.0115341608737768',
            'elaina' => '0.0115341608737768',
            'jeanna' => '0.0115341608737768',
            'joseph' => '0.0115341608737768',
            'lakeshia' => '0.0115341608737768',
            'sharonda' => '0.0115341608737768',
            'hilda' => '0.0114273630879085',
            'lynsey' => '0.0114273630879085',
            'alysia' => '0.0113205653020402',
            'cameron' => '0.0113205653020402',
            'lizbeth' => '0.0113205653020402',
            'jenelle' => '0.0112137675161719',
            'kia' => '0.0112137675161719',
            'kisha' => '0.0112137675161719',
            'leila' => '0.0112137675161719',
            'monika' => '0.0112137675161719',
            'nakia' => '0.0112137675161719',
            'charmaine' => '0.0111069697303036',
            'corrine' => '0.0111069697303036',
            'yasmin' => '0.0111069697303036',
            'cristy' => '0.0110001719444352',
            'diamond' => '0.0110001719444352',
            'ladonna' => '0.0110001719444352',
            'santana' => '0.0110001719444352',
            'shanta' => '0.0110001719444352',
            'susanna' => '0.0110001719444352',
            'tonia' => '0.0110001719444352',
            'kassie' => '0.0108933741585669',
            'katlyn' => '0.0108933741585669',
            'kristan' => '0.0108933741585669',
            'sophie' => '0.0108933741585669',
            'annmarie' => '0.0107865763726986',
            'cory' => '0.0107865763726986',
            'francis' => '0.0107865763726986',
            'kandace' => '0.0107865763726986',
            'kiley' => '0.0107865763726986',
            'portia' => '0.0107865763726986',
            'princess' => '0.0107865763726986',
            'terry' => '0.0107865763726986',
            'adriane' => '0.0106797785868303',
            'alexia' => '0.0106797785868303',
            'alyse' => '0.0106797785868303',
            'leilani' => '0.0106797785868303',
            'rikki' => '0.0106797785868303',
            'tamra' => '0.0106797785868303',
            'zoe' => '0.0106797785868303',
            'eunice' => '0.010572980800962',
            'krysta' => '0.010572980800962',
            'mariel' => '0.010572980800962',
            'stevie' => '0.010572980800962',
            'tammie' => '0.010572980800962',
            'brigitte' => '0.0104661830150937',
            'carley' => '0.0104661830150937',
            'chana' => '0.0104661830150937',
            'chantal' => '0.0104661830150937',
            'kami' => '0.0104661830150937',
            'lucinda' => '0.0104661830150937',
            'meghann' => '0.0104661830150937',
            'richelle' => '0.0104661830150937',
            'shasta' => '0.0104661830150937',
            'tarah' => '0.0104661830150937',
            'tyler' => '0.0104661830150937',
            'helena' => '0.0103593852292254',
            'mellissa' => '0.0103593852292254',
            'rene' => '0.0103593852292254',
            'stacia' => '0.0103593852292254',
            'wendi' => '0.0103593852292254',
            'aurora' => '0.0102525874433571',
            'eve' => '0.0102525874433571',
            'juana' => '0.0102525874433571',
            'shea' => '0.0102525874433571',
            'stella' => '0.0102525874433571',
            'liana' => '0.0101457896574888',
            'venessa' => '0.0101457896574888',
            'brittanie' => '0.0100389918716205',
            'janessa' => '0.0100389918716205',
            'kristian' => '0.0100389918716205',
            'william' => '0.0100389918716205',
            'june' => '0.00993219408575221',
            'magdalena' => '0.00993219408575221',
            'nikole' => '0.00993219408575221',
            'rosalinda' => '0.00993219408575221',
            'stefani' => '0.00993219408575221',
            'sue' => '0.00993219408575221',
            'delilah' => '0.00982539629988391',
            'jeri' => '0.00982539629988391',
            'katelynn' => '0.00982539629988391',
            'micah' => '0.00982539629988391',
            'savanna' => '0.00982539629988391',
            'stephani' => '0.00982539629988391',
            'arianna' => '0.00971859851401561',
            'colette' => '0.00971859851401561',
            'domonique' => '0.00971859851401561',
            'jerrica' => '0.00971859851401561',
            'laquita' => '0.00971859851401561',
            'rosalyn' => '0.00971859851401561',
            'graciela' => '0.0096118007281473',
            'jada' => '0.0096118007281473',
            'julissa' => '0.0096118007281473',
            'luisa' => '0.0096118007281473',
            'britany' => '0.009505002942279',
            'cathleen' => '0.009505002942279',
            'denisse' => '0.009505002942279',
            'jessika' => '0.009505002942279',
            'kacy' => '0.009505002942279',
            'mariela' => '0.009505002942279',
            'valencia' => '0.009505002942279',
            'ami' => '0.0093982051564107',
            'andrew' => '0.0093982051564107',
            'anthony' => '0.0093982051564107',
            'candis' => '0.0093982051564107',
            'chaya' => '0.0093982051564107',
            'cristin' => '0.0093982051564107',
            'geraldine' => '0.0093982051564107',
            'kaila' => '0.0093982051564107',
            'keely' => '0.0093982051564107',
            'lissette' => '0.0093982051564107',
            'alina' => '0.00929140737054239',
            'ava' => '0.00929140737054239',
            'clare' => '0.00929140737054239',
            'deena' => '0.00929140737054239',
            'jessi' => '0.00929140737054239',
            'jonathan' => '0.00929140737054239',
            'kerrie' => '0.00929140737054239',
            'salina' => '0.00929140737054239',
            'tess' => '0.00929140737054239',
            'brittny' => '0.00918460958467409',
            'deirdre' => '0.00918460958467409',
            'francine' => '0.00918460958467409',
            'ivette' => '0.00918460958467409',
            'jeana' => '0.00918460958467409',
            'reyna' => '0.00918460958467409',
            'sondra' => '0.00918460958467409',
            'tisha' => '0.00918460958467409',
            'breann' => '0.00907781179880579',
            'felecia' => '0.00907781179880579',
            'iesha' => '0.00907781179880579',
            'karli' => '0.00907781179880579',
            'katelin' => '0.00907781179880579',
            'keila' => '0.00907781179880579',
            'liz' => '0.00907781179880579',
            'milagros' => '0.00907781179880579',
            'reina' => '0.00907781179880579',
            'shalonda' => '0.00907781179880579',
            'shonda' => '0.00907781179880579',
            'tanika' => '0.00907781179880579',
            'felisha' => '0.00897101401293748',
            'johnna' => '0.00897101401293748',
            'katheryn' => '0.00897101401293748',
            'lindy' => '0.00897101401293748',
            'lisette' => '0.00897101401293748',
            'marion' => '0.00897101401293748',
            'renata' => '0.00897101401293748',
            'tianna' => '0.00897101401293748',
            'ada' => '0.00886421622706918',
            'chanda' => '0.00886421622706918',
            'danyelle' => '0.00886421622706918',
            'ella' => '0.00886421622706918',
            'latanya' => '0.00886421622706918',
            'maira' => '0.00886421622706918',
            'tenisha' => '0.00886421622706918',
            'therese' => '0.00886421622706918',
            'tyra' => '0.00886421622706918',
            'corrie' => '0.00875741844120088',
            'hallie' => '0.00875741844120088',
            'louise' => '0.00875741844120088',
            'natosha' => '0.00875741844120088',
            'shantell' => '0.00875741844120088',
            'sunny' => '0.00875741844120088',
            'tawny' => '0.00875741844120088',
            'yessenia' => '0.00875741844120088',
            'anya' => '0.00865062065533257',
            'bertha' => '0.00865062065533257',
            'cecelia' => '0.00865062065533257',
            'jamila' => '0.00865062065533257',
            'karrie' => '0.00865062065533257',
            'lia' => '0.00865062065533257',
            'margo' => '0.00865062065533257',
            'mari' => '0.00865062065533257',
            'paola' => '0.00865062065533257',
            'rosalie' => '0.00865062065533257',
            'alexander' => '0.00854382286946427',
            'bernice' => '0.00854382286946427',
            'cherish' => '0.00854382286946427',
            'darci' => '0.00854382286946427',
            'jaqueline' => '0.00854382286946427',
            'kiera' => '0.00854382286946427',
            'lashanda' => '0.00854382286946427',
            'mildred' => '0.00854382286946427',
            'perla' => '0.00854382286946427',
            'shanita' => '0.00854382286946427',
            'shara' => '0.00854382286946427',
            'aida' => '0.00843702508359597',
            'angelia' => '0.00843702508359597',
            'chanelle' => '0.00843702508359597',
            'francisca' => '0.00843702508359597',
            'kirstin' => '0.00843702508359597',
            'krystina' => '0.00843702508359597',
            'loni' => '0.00843702508359597',
            'malia' => '0.00843702508359597',
            'marcela' => '0.00843702508359597',
            'porsha' => '0.00843702508359597',
            'quiana' => '0.00843702508359597',
            'racquel' => '0.00843702508359597',
            'shanice' => '0.00843702508359597',
            'valeria' => '0.00843702508359597'
           };
