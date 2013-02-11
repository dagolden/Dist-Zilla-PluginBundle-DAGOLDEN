use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/DZ1' },
);

ok($tzil->build, "build dist with \@DAGOLDEN");

done_testing;
# COPYRIGHT
