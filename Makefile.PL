use strict;
use warnings;

use ExtUtils::MakeMaker;
use Devel::CheckLib;

use Alien::AntTweakBar;
use Alien::SDL;

check_lib_or_exit( lib => 'GL' );

my $atb_inc = Alien::AntTweakBar->config('cflags');
my $atb_libs = Alien::AntTweakBar->config('libs');

my $sdl_inc = Alien::SDL->config('cflags');
my $sdl_libs = Alien::SDL->config('libs');

my $all_inc = "$atb_inc $sdl_inc";
my $all_libs = "$atb_libs $sdl_libs -lGL";

print "using libs: $all_libs\n";

WriteMakefile(
    NAME              => 'AntTweakBar',
    VERSION_FROM      => 'lib/AntTweakBar.pm',
    ABSTRACT_FROM     => 'lib/AntTweakBar.pm',
    CONFIGURE_REQUIRES => {
        'Alien::AntTweakBar'  => '0.02_06',
        'Alien::SDL'          => '1.444',
        'ExtUtils::MakeMaker' => '6.52',
        'Devel::CheckLib'     => '1.01',
    },
    PREREQ_PM         => {
        'Carp'               => 0,
        'Exporter'           => 0,
        'XSLoader'           => 0,
        'Alien::AntTweakBar' => '0.02_06',
    },
    TEST_REQUIRES     => {
        'Test::More'     => 0,
        'Test::Fatal'    => 0,
        'Test::Warnings' => 0,
    },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:basiliscos/p5-anttweakbar.git',
                web => 'https://github.com/basiliscos/p5-anttweakbar',
            },

        },

    },
    AUTHOR            => 'Ivan Baidakou <dmol@gmx.com>',
    LICENSE           => 'perl',
    CCFLAGS           => '-g',
    LD                => '$(CXX)', # AntTweakBar is compiled via c++
    LIBS              => $all_libs,
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. $all_inc",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
