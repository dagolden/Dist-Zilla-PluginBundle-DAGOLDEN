use strict;
use warnings;
package Pod::Weaver::PluginBundle::DAGOLDEN;
# ABSTRACT: DAGOLDEN's default Pod::Weaver config

use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Weaver::Plugin::WikiDoc ();
use Pod::Elemental::Transformer::List 0.101620 ();

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  my @plugins;
  push @plugins, (
    [ '@DAGOLDEN/WikiDoc',     _exp('-WikiDoc'), {} ],
    [ '@DAGOLDEN/CorePrep',    _exp('@CorePrep'), {} ],
    [ '@DAGOLDEN/Name',        _exp('Name'),      {} ],
    [ '@DAGOLDEN/Version',     _exp('Version'),   {} ],

    [ '@DAGOLDEN/Prelude',     _exp('Region'),  { region_name => 'prelude'     } ],
    [ '@DAGOLDEN/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS'    } ],
    [ '@DAGOLDEN/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
    [ '@DAGOLDEN/Overview',    _exp('Generic'), { header      => 'OVERVIEW'    } ],

    [ '@DAGOLDEN/Stability',   _exp('Generic'), { header      => 'STABILITY'   } ],
  );

  for my $plugin (
    [ 'Attributes', _exp('Collect'), { command => 'attr'   } ],
    [ 'Methods',    _exp('Collect'), { command => 'method' } ],
    [ 'Functions',  _exp('Collect'), { command => 'func'   } ],
  ) {
    $plugin->[2]{header} = uc $plugin->[0];
    push @plugins, $plugin;
  }

  push @plugins, (
    [ '@DAGOLDEN/Leftovers', _exp('Leftovers'), {} ],
    [ '@DAGOLDEN/postlude',  _exp('Region'),    { region_name => 'postlude' } ],
    [ '@DAGOLDEN/Authors',   _exp('Authors'),   {} ],
    [ '@DAGOLDEN/Legal',     _exp('Legal'),     {} ],
    [ '@DAGOLDEN/List',      _exp('-Transformer'), { 'transformer' => 'List' } ],
  );

  return @plugins;
}

1;

=for Pod::Coverage mvp_bundle_config
