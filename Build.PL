
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
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
    "autodie" => 0,
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Makes fork() in debugger to open a new Tmux window",
  "dist_author" => [
    "L<Peter Vereshagin|http://vereshagin.org> <peter\@vereshagin.org>"
  ],
  "dist_name" => "Debug-Fork-Tmux",
  "dist_version" => "1.000009",
  "license" => "bsd",
  "module_name" => "Debug::Fork::Tmux",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Const::Fast" => 0,
    "Cwd" => 0,
    "File::Spec" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
