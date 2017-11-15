#===============================================================================
#         FILE:  Builder.pm
#
#  DESCRIPTION:  Functions to build Jenkins plugins from source.
#
#      CREATED:  2017-11-15 08:25
#===============================================================================
use strict;
use warnings;

package Builder;

use base qw(Exporter);
use Helpers qw(:log :shell throw_if_empty);
use File::Path qw(make_path remove_tree);

our @EXPORT_OK = qw(build);

sub build {
    my ($id, $root, $repo, $branch) = @_;

    $branch ||= 'dev';

    throw_if_empty('Plugin ID', $id);
    throw_if_empty('Plugin Repository', $repo);
    throw_if_empty('Git source root folder', $root);

    make_path($root);
    my $dir = File::Spec->catfile($root, $id);
    log_info("Clean directory $dir");
    remove_tree($dir);

    checked_run(qw(git clone), $repo, $dir);
    chdir $dir;
    checked_run(qw(git checkout), $branch);
    
    if (not -e 'pom.xml') {
        die "pom.xml was not found for plugin $id";
    }
    open my $fh, '+<', 'pom.xml' or die "Cannot modify pom.xml: $!";
    my @lines = <$fh>;
    seek $fh, 0, 0;
    truncate $fh, 0;
    my $version;
    my $found = 0;
    for my $line (@lines) {
        if (!$found and $line =~ />\s*([^>]+?)-SNAPSHOT\s*</) {
            $version = "$1-TEST";
            $line =~ s/>[^>]+</>$version</;
            $found = 1;
        }
        print $fh $line;
    }
    close $fh;
    if (not $version) {
        die "Cannot find plugin SNAPSHOT version for plugin $id";
    }

    checked_run(qw(mvn clean package -DskipTests));

    my $pattern = File::Spec->catfile($dir, 'target/*.hpi');
    my @results = glob $pattern;
    if (@results == 1) {
        return ($results[0], $version);
    } elsif (@results > 1) {
        die 'Multiple hpi packages were generated: ' . join(', ', @results);
    } else {
        die 'No hpi package was generated';
    }
}

