use Test::Simple tests => 8;

use Text::GenderFromName qw( :DEFAULT &gender_init );

my %genders = ('Josephine' => 'f',
               'Michael' => 'm',
               'Dondi' => 'm',
               'Jonny' => 'm',
               'Pascal' => 'm',
               'Velvet' => 'f',
               'Eamon' => 'm',
               'FLKMLKSJN' => '');


my @names = ('Josephine',
             'Michael',
             'Dondi', 
             'Jonny',
             'Pascal',
             'Velvet',
             'Eamon',
             'FLKMLKSJN');

push @Text::GenderFromName::MATCH_LIST, 'main::user_sub';

my @tests = @Text::GenderFromName::MATCH_LIST;

ok(@tests == 7, 'Found all 7 match subs');

# first of all, make sure we have the right number of match subs.

for (my $i = 0; $i < @tests; $i++) {
    @Text::GenderFromName::MATCH_LIST = ($tests[$i]);

    my $pos = &gender($names[$i]);
    my $neg = &gender($names[$i+1]);

    ok($pos eq $genders{$names[$i]} && !$neg,
       "$tests[$i]: $names[$i] => [$pos], $names[$i+1] => [$neg]");
}

sub user_sub {
    my $name = shift;
    return 'm' if $name =~ /^eamon/;
}
