#!/usr/bin/env perl
#===============================================================================
#         FILE:  prepare-image.pl
#
#  DESCRIPTION:  
#
#       AUTHOR:  ArieShout, arieshout@gmail.com
#      CREATED:  2017-11-15 08:46
#===============================================================================
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Builder;
use Getopt::Long qw(:config gnu_getopt no_ignore_case auto_version auto_help);
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path qw(make_path remove_tree);
use Helpers qw(:log :shell throw_if_empty process_file);
use Pod::Usage;

my @plugins = qw(
    azure-commons
    azure-credentials
    kubernetes-cd
    azure-acs
    windows-azure-storage
    azure-container-agents
    azure-vm-agents
    azure-app-service
    azure-function
);

my %repo_of = map { ($_, "https://github.com/jenkinsci/$_-plugin.git") } @plugins;

my %options = (
    'jenkins-version' => 'lts'
);

GetOptions(\%options,
    'tag|t=s',
    'jenkins-version|j=s',
    'build-plugin|b=s@'
) or pod2usage(2);

throw_if_empty("Docker image tag", $options{tag});

$options{'build-plugin'} ||= [];
@{$options{'build-plugin'}} = split(/,/, join(',', @{$options{'build-plugin'}}));
for (@{$options{'build-plugin'}}) {
    my ($id, $repo) = split(/=/, $_, 2);
    if ($repo) {
        log_info("Set repository of $id to $repo");
        $repo_of{$id} = $repo;
        # update the value in-place via the alias
        $_ = $id;
    }
}

print Data::Dumper->Dump([\%options, \%repo_of], ['options', 'repositories']);

my %plugin_version;

my $docker_root = "$Bin/../docker-build";
my $plugin_dir = File::Spec->catfile($docker_root, 'plugins');
my $git_root = "$Bin/../git";
remove_tree($docker_root, $git_root);
make_path($git_root, $plugin_dir);
for my $plugin (@{$options{'build-plugin'}}) {
    my $repo = $repo_of{$plugin};
    if (not $repo) {
        die "Cannot find repository for plugin $plugin";
    }
    my ($hpi, $version) = Builder::build($plugin, $git_root, $repo);
    copy($hpi, File::Spec->catfile($plugin_dir, basename($hpi, '.hpi') . '.jpi'))
        or die "Cannot copy $hpi to $plugin_dir: $!";
    $plugin_version{$plugin} = $version;
}

$options{'all-plugins-list'} = list2cmdline(@plugins);
# TODO we need to resolve the plugin dependencies as in install-plugins.sh
$options{'docker-copy-jpi'} = %plugin_version ? q{COPY plugins/*.jpi "$PLUGIN_DIR"} : "";

process_file("$Bin/../Dockerfile.jenkins", $docker_root, \%options);

chdir $docker_root;

checked_run(qw(docker build -f Dockerfile.jenkins -t), $options{tag}, '.');

__END__

=head1 NAME

prepare-image.pl - Script to build the Jenkins docker image with the Azure Jenkins plugins installed,
                   either from update center or build from source.

=head1 SYNOPSIS

prepare-image.pl [options]

 Options:
   --tag|-t                 The tag for the result image
   --jenkins-version|-j     The base Jenkins image version, default 'lts'
   --build-plugin|-b        Comma separated list of Azure Jenkins plugin IDs that needs to be build 
                            from source and installed to the result image. It can be applied multiple times.
                            The default source repository is the GitHub jenkinsci repository, which can 
                            be override with 'plugin-id=repo-url', e.g.,
                                --build-plugin azure-commons -b azure-credentials=https://my.repo.address
   
   --help                   Show the help documentation

=cut

