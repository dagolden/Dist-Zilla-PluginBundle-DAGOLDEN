use strict;
use warnings;
package Dist::Zilla::PluginBundle::DAGOLDEN;
# ABSTRACT: Dist::Zilla configuration the way DAGOLDEN does it

# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 2.101040; # DZRPB::Easy

use Dist::Zilla::PluginBundle::Basic ();
use Dist::Zilla::PluginBundle::Filter ();
use Dist::Zilla::PluginBundle::Git ();

use Dist::Zilla::Plugin::BumpVersionFromGit ();
use Dist::Zilla::Plugin::CheckExtraTests ();
use Dist::Zilla::Plugin::CompileTests ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::MetaProvides::Package ();
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::PodSpellingTests ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::TaskWeaver ();
use Dist::Zilla::Plugin::PortabilityTests ();
use Dist::Zilla::Plugin::Prepender ();
use Dist::Zilla::Plugin::ReadmeFromPod ();
use Dist::Zilla::Plugin::Repository ();

with 'Dist::Zilla::Role::PluginBundle::Easy';

has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{is_task} },
);

has autoprereq => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { 
    exists $_[0]->payload->{autoprereq} ? $_[0]->payload->{autoprereq} : 1
  },
);

sub configure {
  my $self = shift;

  # @Basic minus stuff replaced below 
  $self->add_bundle( 
    Filter => {
      bundle => '@Basic',
      remove => [qw/Readme ExtraTests/],
    }
  );

  $self->add_plugins (

  # version number
    [ BumpVersionFromGit => { version_regexp => '^release-(.+)$' } ],

  # file modifications
    'PkgVersion',         # core
    'NextRelease',        # core
    'Prepender',

  # other generated files
    'ReadmeFromPod',

  # xt tests
    'MetaTests',          # core
    'PodSyntaxTests',     # core
    'PodCoverageTests',   # core
    'PodSpellingTests',
    'PortabilityTests',
    [ CompileTests => { fake_home => 1 } ],

  # metadata
    'MinimumPerl',
    'MetaProvides::Package',
    [ Repository => { git_remote => 'github' } ],
    [ MetaNoIndex => { directory => [qw/t xt examples corpus/] } ],

  # before release
    'CheckExtraTests',
  );

  if ( $self->autoprereq ) {
    $self->add_plugins('TaskWeaver');
  }

  if ($self->is_task) {
    $self->add_plugins('TaskWeaver');
  } else {
    $self->add_plugins('PodWeaver');
  }

  # git integration -- do this late
  $self->add_bundle(
    Git => {
      tag_format => 'release-%v',
      push_to => [qw/ origin github /],
    }
  );

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage configure

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

