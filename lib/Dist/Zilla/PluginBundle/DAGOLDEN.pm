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
    $self->add_plugins('AutoPrereq');
  }

  if ($self->is_task) {
    $self->add_plugins('TaskWeaver');
  } else {
    $self->add_plugins('PodWeaver');
  }

  # git integration -- do this manually to get multi-values right
  # and do it late to make sure checks happen after all files are munged
  $self->add_plugins(
    'Git::Check',
    'Git::Commit',
    [ 'Git::Tag' => { tag_format => 'release-%v' } ],
    [ 'Git::Push' => { push_to => [ qw/origin github/ ] } ],
  );

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage configure

=begin wikidoc

= SYNOPSIS

  # in dist.ini
  [@DAGOLDEN]

= DESCRIPTION

This is a [Dist::Zilla] PluginBundle.  It is roughly equivalent to the
following dist.ini:

  [@Filter]
  bundle = @Basic
  remove = Readme
  remove = ExtraTests

  ; version provider
  [BumpVersionFromGit]
  version_regexp = ^release-(.+)$

  ; file modifications
  [PkgVersion]
  [NextRelease]
  [Prepender]
  [PodWeaver]

  ; other generated files
  [ReadmeFromPod]

  ; xt tests
  [MetaTests]
  [PodSyntaxTests]
  [PodCoverageTests]
  [PodSpellingTests]
  [PortabilityTests]

  ; t tests
  [CompileTests]
  fake_home = 1

  ; metadata
  [AutoPrereq]
  [MinimumPerl]
  [MetaProvides::Package]

  [Repository]
  git_remote = github

  [MetaNoIndex]
  directory = t
  directory = xt
  directory = examples
  directory = corpus

  ; before release
  [CheckExtraTests]

  ; git integration
  [Git::Check]
  [Git::Commit]

  [Git::Tag]
  tag_format = release-%v

  [Git::Push]
  push_to = origin
  push_to = github

= USAGE

  # in dist.ini
  [@DAGOLDEN]
  ; is_task = 0
  ; autoprereq = 1

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

* {is_task} -- this indicates whether TaskWeaver or PodWeaver should be used.
Default is 0.
* {autoprereq} -- this indicates whether AutoPrereq should be used or not.
Default is 1.

= SEE ALSO

* [Dist::Zilla]
* [Dist::Zilla::Plugin::TaskWeaver]

=end wikidoc

=cut

