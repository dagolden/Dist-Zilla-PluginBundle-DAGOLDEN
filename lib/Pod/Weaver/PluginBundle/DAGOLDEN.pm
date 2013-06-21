use strict;
use warnings;

package Pod::Weaver::PluginBundle::DAGOLDEN;
# VERSION

use Pod::Weaver 3.101635; # fixed ABSTRACT scanning
use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Weaver::Plugin::WikiDoc ();
use Pod::Weaver::Plugin::Encoding ();
use Pod::Elemental::Transformer::List 0.101620 ();
use Pod::Weaver::Section::Support 1.001        ();
use Pod::Weaver::Section::Contributors 0.001   ();

sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }

my $repo_intro = <<'END';
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
END

my $bugtracker_content = <<'END';
Please report any bugs or feature requests through the issue tracker
at {WEB}.
You will be notified automatically of any progress on your issue.
END

sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        [ '@DAGOLDEN/Encoding', _exp('-Encoding'), {} ],
        [ '@DAGOLDEN/WikiDoc',  _exp('-WikiDoc'),  {} ],
        [ '@DAGOLDEN/CorePrep', _exp('@CorePrep'), {} ],
        [ '@DAGOLDEN/Name',     _exp('Name'),      {} ],
        [ '@DAGOLDEN/Version',  _exp('Version'),   {} ],

        [ '@DAGOLDEN/Prelude',     _exp('Region'),  { region_name => 'prelude' } ],
        [ '@DAGOLDEN/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS' } ],
        [ '@DAGOLDEN/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
        [ '@DAGOLDEN/Overview',    _exp('Generic'), { header      => 'OVERVIEW' } ],

        [ '@DAGOLDEN/Stability', _exp('Generic'), { header => 'STABILITY' } ],
    );

    for my $plugin (
        [ 'Usage',        _exp('Collect'), { command => 'usage' } ],
        [ 'Functions',    _exp('Collect'), { command => 'func' } ],
        [ 'Attributes',   _exp('Collect'), { command => 'attr' } ],
        [ 'Constructors', _exp('Collect'), { command => 'construct' } ],
        [ 'Methods',      _exp('Collect'), { command => 'method' } ],
      )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins,
      (
        [ '@DAGOLDEN/Leftovers', _exp('Leftovers'), {} ],
        [ '@DAGOLDEN/postlude', _exp('Region'), { region_name => 'postlude' } ],
        [
            '@DAGOLDEN/Support',
            _exp('Support'),
            {
                perldoc            => 0,
                websites           => 'none',
                bugs               => 'metadata',
                bugs_content       => $bugtracker_content,
                repository_link    => 'both',
                repository_content => $repo_intro
            }
        ],
        [ '@DAGOLDEN/Authors', _exp('Authors'), {} ],
        [ '@DAGOLDEN/Contributors', _exp('Contributors'), {} ],
        [ '@DAGOLDEN/Legal',   _exp('Legal'),   {} ],
        [ '@DAGOLDEN/List', _exp('-Transformer'), { 'transformer' => 'List' } ],
      );

    return @plugins;
}

# ABSTRACT: DAGOLDEN's default Pod::Weaver config
# COPYRIGHT

1;

=for Pod::Coverage mvp_bundle_config

=begin wikidoc

= DESCRIPTION

This is a [Pod::Weaver] PluginBundle.  It is roughly equivalent to the
following weaver.ini:

  [-Encoding]

  [-WikiDoc]

  [@Default]

  [Support]
  perldoc = 0
  websites = none
  bugs = metadata
  bugs_content = ... stuff (web only, email omitted) ...
  repository_link = both
  repository_content = ... stuff ...

  [Contributors]

  [-Transformer]
  transformer = List

= USAGE

This PluginBundle is used automatically with the C<@DAGOLDEN> [Dist::Zilla]
plugin bundle.

It also has region collectors for:

* construct
* attr
* method
* func
* usage

= SEE ALSO

* [Pod::Weaver]
* [Pod::Weaver::Plugin::WikiDoc]
* [Pod::Elemental::Transformer::List]
* [Pod::Weaver::Section::Contributors]
* [Pod::Weaver::Section::Support]
* [Dist::Zilla::Plugin::PodWeaver]

=end wikidoc

=cut
