use 5.020000;
use ExtUtils::MakeMaker;

use Alien::AntTweakBar;

my $tw = Alien::AntTweakBar->new;
my $inc = $tw->cflags;
my $libs = $tw->libs;

print "using libs: $libs\n";

WriteMakefile(
    NAME              => 'AntTweakBar',
    VERSION_FROM      => 'lib/AntTweakBar.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/AntTweakBar.pm', # retrieve abstract from module
    AUTHOR            => 'Ivan Baidakou <dmol@gmx.com>',
    LICENSE           => 'perl',
    LIBS              => $libs, # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. $inc",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
