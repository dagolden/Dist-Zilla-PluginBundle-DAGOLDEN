use strict;
use warnings;
package Dist::Zilla::PluginBundle::DAGOLDEN;
# ABSTRACT: Dist::Zilla configuration the way DAGOLDEN does it

# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 3.101450; # Use CPAN::Meta

use Dist::Zilla::PluginBundle::Filter ();
use Dist::Zilla::PluginBundle::Git ();

use Dist::Zilla::Plugin::BumpVersionFromGit ();
use Dist::Zilla::Plugin::CheckChangesHasContent ();
use Dist::Zilla::Plugin::CheckExtraTests ();
use Dist::Zilla::Plugin::CompileTests ();
use Dist::Zilla::Plugin::GithubMeta 0.10 ();
use Dist::Zilla::Plugin::MetaNoIndex ();
use Dist::Zilla::Plugin::MetaProvides::Package ();
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::PodSpellingTests ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::TaskWeaver 0.101620 ();
use Dist::Zilla::Plugin::PortabilityTests ();
use Dist::Zilla::Plugin::Prepender ();
use Dist::Zilla::Plugin::ReadmeFromPod ();
use Dist::Zilla::Plugin::Repository 0.13 ();  # version 2 Meta Spec

use Pod::Weaver::Plugin::WikiDoc ();

with 'Dist::Zilla::Role::PluginBundle::Easy';

has fake_release => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{fake_release} },
);

has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{is_task} },
);

has auto_prereq => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{auto_prereq} ? $_[0]->payload->{auto_prereq} : 1
  },
);

has tag_format => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{tag_format} ? $_[0]->payload->{tag_format} : 'release-%v',
  },
);

has version_regexp => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{version_regexp} ? $_[0]->payload->{version_regexp} : '^release-(.+)$',
  },
);

has weaver_config => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->payload->{weaver_config} || '@DAGOLDEN' },
);

has git_remote => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{git_remote} ? $_[0]->payload->{git_remote} : 'origin',
  },
);


sub configure {
  my $self = shift;

  my @push_to = ('origin');
  push @push_to, $self->git_remote if $self->git_remote ne 'origin';

  $self->add_plugins (

  # version number
    [ BumpVersionFromGit => { version_regexp => $self->version_regexp } ],

  # gather and prune
    'GatherDir',          # core
    'PruneCruft',         # core
    'ManifestSkip',       # core

  # file munging
    'PkgVersion',         # core
    'Prepender',
    ( $self->is_task  
      ?  'TaskWeaver' 
      : [ 'PodWeaver' => { config_plugin => $self->weaver_config } ] 
    ),

  # generated distribution files
    'ReadmeFromPod',
    'License',            # core

  # generated t/ tests
    [ CompileTests => { fake_home => 1 } ],

  # generated xt/ tests
    'MetaTests',          # core
    'PodSyntaxTests',     # core
    'PodCoverageTests',   # core
#    'PodSpellingTests', # XXX disabled until stopwords and weaving fixed
    'PortabilityTests',

  # metadata
    'MinimumPerl',
    ( $self->auto_prereq ? 'AutoPrereq' : () ),
    'MetaProvides::Package',
    [ Repository => { git_remote => $self->git_remote }, github_http => 0 ],
    'GithubMeta',         # overrides Repository if github based
    [ MetaNoIndex => { directory => [qw/t xt examples corpus/] } ],
    'MetaYAML',           # core
    'MetaJSON',           # core

  # build system
    'ExecDir',            # core
    'ShareDir',           # core
    'MakeMaker',          # core

  # manifest -- must come after all generated files
    'Manifest',           # core

  # before release
    'Git::Check',
    'CheckChangesHasContent',
    'CheckExtraTests',
    'TestRelease',        # core
    'ConfirmRelease',     # core

  # release
    ( $self->fake_release ? 'FakeRelease' : 'UploadToCPAN'),       # core

  # after release
  # Note -- NextRelease is here to get the ordering right with
  # git actions.  It is *also* a file munger that acts earlier

    [ 'Git::Commit' => 'Commit_Dirty_Files' ], # Changes and/or dist.ini
    [ 'Git::Tag' => { tag_format => $self->tag_format } ],

    # bumps Changes
    'NextRelease',        # core (also munges files)

    [ 'Git::Commit' => 'Commit_Changes' => { commit_msg => "bump Changes" } ],

    [ 'Git::Push' => { push_to => \@push_to } ],

  );

}

__PACKAGE__->meta->make_immutable;

1;

__END__


=for stopwords
autoprereq dagolden fakerelease pluginbundle podweaver
taskweaver uploadtocpan dist ini

=for Pod::Coverage configure

=begin wikidoc

= SYNOPSIS

  # in dist.ini
  [@DAGOLDEN]

= DESCRIPTION

This is a [Dist::Zilla] PluginBundle.  It is roughly equivalent to the
following dist.ini:

  ; version provider
  [BumpVersionFromGit]
  version_regexp = ^release-(.+)$

  ; choose files to include
  [GatherDir]
  [PruneCruft]
  [ManifestSkip]

  ; file modifications
  [PkgVersion]
  [Prepender]
  [PodWeaver]
  config_plugin = @DAGOLDEN

  ; generated files
  [License]
  [ReadmeFromPod]

  ; t tests
  [CompileTests]
  fake_home = 1

  ; xt tests
  [MetaTests]
  [PodSyntaxTests]
  [PodCoverageTests]
  [PortabilityTests]

  ; metadata
  [AutoPrereq]
  [MinimumPerl]
  [MetaProvides::Package]

  [Repository]
  git_remote = origin
  github_http = 0

  ; overrides [Repository] if repository is on github
  [GithubMeta]
  remote = origin

  [MetaNoIndex]
  directory = t
  directory = xt
  directory = examples
  directory = corpus

  [MetaYAML]
  [MetaJSON]

  ; build system
  [ExecDir]
  [ShareDir]
  [MakeMaker]

  ; manifest (after all generated files)
  [Manifest]

  ; before release
  [Git::Check]
  [CheckChangesHasContent]
  [CheckExtraTests]
  [TestRelease]
  [ConfirmRelease]

  ; releaser
  [UploadToCPAN]

  ; after release
  [Git::Commit / Commit_Dirty_Files]

  [Git::Tag]
  tag_format = release-%v

  [NextRelease]
  [Git::Commit / Commit_Changes]

  [Git::Push]
  push_to = origin

= USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide
the following options:

* {is_task} -- this indicates whether TaskWeaver or PodWeaver should be used.
Default is 0.
* {auto_prereq} -- this indicates whether AutoPrereq should be used or not.
Default is 1.
* {tag_format} -- given to {Git::Tag}.  Default is 'release-%v' to be more
robust than just the version number when parsing versions for
{BumpVersionFromGit}
* {version_regexp} -- given to {BumpVersionFromGit}.  Default
is '^release-(.+)$'
* {git_remote} -- given to {Repository}.  Defaults to 'origin'.  If set to
something other than 'origin', it is also added as a {push_to} argument for
{Git::Push}
* {fake_release} -- swaps FakeRelease for UploadToCPAN. Mostly useful for
testing a dist.ini without risking a real release.
* {weaver_config} -- specifies a Pod::Weaver bundle.  Defaults to @DAGOLDEN.

= SEE ALSO

* [Dist::Zilla]
* [Dist::Zilla::Plugin::PodWeaver]
* [Dist::Zilla::Plugin::TaskWeaver]

=end wikidoc

=cut

