use ExtUtils::MakeMaker;

use Alien::AntTweakBar;

my $inc = Alien::AntTweakBar->config('cflags');
my $libs = Alien::AntTweakBar->config('libs');

my $inc_sdl = `pkg-config --cflags sdl`;

print "using libs: $libs\n";

WriteMakefile(
    NAME              => 'AntTweakBar',
    VERSION_FROM      => 'lib/AntTweakBar.pm',
    ABSTRACT_FROM     => 'lib/AntTweakBar.pm',
    CONFIGURE_REQUIRES => {
        'Alien::AntTweakBar'  => 0,
        'ExtUtils::MakeMaker' => '6.52',
    },
    PREREQ_PM         => {
        'Carp'               => 0,
        'Exporter'           => 0,
        'XSLoader'           => 0,
        'Alien::AntTweakBar' => 0,
    },
    TEST_REQUIRES     => {
        'Test::More'     => 0,
        'Test::Fatal'    => 0,
        'Test::Warnings' => 0,
    },
    AUTHOR            => 'Ivan Baidakou <dmol@gmx.com>',
    LICENSE           => 'perl',
    CCFLAGS           => '-g',
    LIBS              => $libs, # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. $inc $inc_sdl",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
