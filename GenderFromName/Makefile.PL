use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval {
    require Text::GenderFromName;
    if ($Text::GenderFromName::VERSION < .30) {
        print <<END_OF_WARNING;

Version $Text::GenderFromName::VERSION of Text::GenderFromName found!

WARNING! You seem to have an older version of Text::GenderFromName
already installed. Version 0.30 makes significant changes in behavior,
most notably using completely new seed lists and a very strict
matching method by default.

See Changes for details.

END_OF_WARNING

        print "Press enter to continue... ";
        my $x = <STDIN>;
        last if $x;
    }
};


WriteMakefile(
    'NAME'		=> 'Text::GenderFromName',
    'VERSION_FROM'	=> 'GenderFromName.pm',
    'PREREQ_PM'		=> { 'Text::DoubleMetaphone' => 0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'GenderFromName.pm',
       AUTHOR     => 'Eamon Daly <eamon@eamondaly.com>') : ()),
);
