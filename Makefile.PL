
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Makes fork() in debugger to open a new Tmux window",
  "AUTHOR" => "L<Peter Vereshagin|http://vereshagin.org> <peter\@vereshagin.org>",
  "BUILD_REQUIRES" => {
    "Config" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Perl6::Slurp" => 0,
    "Scalar::Util" => 0,
    "Sort::Versions" => 0,
    "Sub::Name" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::Strict" => 0,
    "Test::Version" => 0,
    "autodie" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Debug-Fork-Tmux",
  "EXE_FILES" => [],
  "LICENSE" => "bsd",
  "NAME" => "Debug::Fork::Tmux",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Const::Fast" => 0,
    "Cwd" => 0,
    "File::Spec" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000007",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



