use strict;
use warnings;
package Dist::Zilla::PluginBundle::DAGOLDEN;
# ABSTRACT: Dist::Zilla configuration the way DAGOLDEN does it

# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 2;
with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git;

sub bundle_config {
  my ($self, $section) = @_;
  my $class = (ref $self) || $self;

  my $arg = $section->{payload};
  my $is_task = $arg->{task};

  my @plugins = Dist::Zilla::PluginBundle::Filter->bundle_config({
      name    => $section->{name} . '/@Classic',
      payload => {
        bundle => '@Classic',
        remove => [ qw(
          PodVersion 
          PodCoverageTests
        ) ],
      },
    });

  my $prefix = 'Dist::Zilla::Plugin::';
  my @extra = map {[ "$section->{name}/$_->[0]" => "$prefix$_->[0]" => $_->[1] ]}
  (
    [ AutoPrereq  => {} ],
    [ MetaConfig   => { } ],
    [ MetaJSON     => { } ],
    [ NextRelease  => { } ],
    [ ($is_task ? 'TaskWeaver' : 'PodWeaver') => { config_plugin => '@RJBS' } ],
    [ Repository   => { } ],
  );

  push @plugins, @extra;

  push @plugins, Dist::Zilla::PluginBundle::Git->bundle_config({
    name    => "$section->{name}/\@Git",
    payload => {
      tag_format => '%v',
    },
  });

  return @plugins;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage::TrustPod
  bundle_config

=begin wikidoc

= SYNOPSIS

  use Dist::Zilla::PluginBundle::DAGOLDEN;

= DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

= USAGE

Good luck!

= SEE ALSO

Maybe other modules do related things.

=end wikidoc

=cut

