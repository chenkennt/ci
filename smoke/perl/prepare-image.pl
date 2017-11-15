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
use Getopt::Long qw(:config gnu_getopt no_ignore_case auto_version auto_help);
use Data::Dumper;
use Helpers qw(:log :shell throw_if_empty);
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
    'name|n=s',
    'jenkins-version|j=s',
    'build-plugin|b=s@'
) or pod2usage(2);

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

__END__

=head1 NAME

prepare-image.pl - Script to build the Jenkins docker image with the Azure Jenkins plugins installed,
                   either from update center or build from source.

=head1 SYNOPSIS

prepare-image.pl [options]

 Options:
   --name|-n                The tag for the result image
   --jenkins-version|-j     The base Jenkins image version, default 'lts'
   --build-plugin|-b        Comma separated list of Azure Jenkins plugin IDs that needs to be build 
                            from source and installed to the result image. It can be applied multiple times.
                            The default source repository is the GitHub jenkinsci repository, which can 
                            be override with 'plugin-id=repo-url', e.g.,
                                --build-plugin azure-commons -b azure-credentials=https://my.repo.address
   
   --help                   Show the help documentation

=cut

