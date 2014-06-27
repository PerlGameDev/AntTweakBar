use 5.12.0;

use Test::Fatal;
use Test::More;
use Test::Warnings;
use AntTweakBar qw/:all/;

$ENV{ANTTWEAKBAR_DISABLE_LIB} = 1;

subtest "types creation checking" => sub {
    my %type_for = (
        bool    => 1,
        integer => 2,
        number  => 3.14,
        string  => "abc"
    );
    my $bar = AntTweakBar->new("TweakBar");
    for my $type (keys %type_for) {
        my ($ro, $rw) = ($type_for{$type}) x 2;
        $bar->add_variable(
            mode       => 'ro',
            name       => "${type}_ro",
            type       => $type,
            value      => \$ro,
        );
        $bar->add_variable(
            mode       => 'rw',
            name       => "${type}_rw",
            type       => $type,
            value      => \$rw,
        );
        ok "type $type seems to be added";
    }
};

subtest "invalid type" => sub {
    my $bar = AntTweakBar->new("TweakBar");
    my $e = exception {
        my $val = 5;
        $bar->add_variable(
            mode       => 'ro',
            name       => "_ro",
            type       => 'unknown',
            value      => \$val,
        );
    };
    like $e, qr/Undefined var type/;
};

subtest "variable isn't reference" => sub {
    my $bar = AntTweakBar->new("TweakBar");
    my $e = exception {
        my $val = 5;
        $bar->add_variable(
            mode       => 'ro',
            name       => "_ro",
            type       => 'integer',
            value      => $val,
        );
    };
    like $e, qr/value should be a reference/;
};

done_testing;
