package AntTweakBar::Type;

use 5.12.0;

use Carp;
use Alien::AntTweakBar;
use AntTweakBar;

sub new {
    my ($class, $name, $value) = @_;
    my $hash = ref($value) eq 'ARRAY'
        ? { map { ($_ => $value->[$_]) } (0 .. @$value-1) }
        : ref($value) eq 'HASH'
        ? { map { $value->{$_} => $_ } keys %$value }
        : die("New type value should be either hash or array reference");
    my $type_id = AntTweakBar::_register_enum($name, $hash);
    my $self = {
        _name    => $name,
        _type_id => $type_id,
    };
    return bless $self => $class;
}

sub name {
    shift->{_name};
}

1;
