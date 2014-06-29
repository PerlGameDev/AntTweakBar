package AntTweakBar;

use 5.12.0;

use Carp;
use Alien::AntTweakBar;

require Exporter;

our @ISA = qw(Exporter);

our @constants =
    qw/
          TW_OPENGL
          TW_OPENGL_CORE
          TW_DIRECT3D9
          TW_DIRECT3D10
          TW_DIRECT3D11
      /;

our %EXPORT_TAGS = (
    'all' => [ qw(init window_size terminate), @constants ],
    'constants' => \@constants,
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('AntTweakBar', $VERSION);

sub new {
    my ($class, $name) = @_;
    croak "AntTweakBar name should be specified"
        unless defined $name;
    my $self = {};
    $self->{_bar_ptr} = _create( $name );
    return bless $self => $class;
}

sub DESTROY {
    my $self = shift;
    _destroy($self->{_bar_ptr});
}

sub add_button {
    my ($self, %args) = @_;

    my $name        = $args{name      };
    my $cb          = $args{cb        };
    my $definition  = $args{definition} // "";

    croak "Button name should be specified"
        unless defined $name;
    croak "Button callback should be specified"
        if(!defined($cb) || ref($cb) ne 'CODE');

    _add_button($self->{_bar_ptr}, $name, $cb, $definition);
}

sub add_separator {
    my ($self, $name, $definition) = @_;
    croak "Separator name should be specified"
        unless defined $name;

    $definition //= "";

    _add_separator($self->{_bar_ptr}, $name, $definition);
}

sub add_variable {
    my ($self, %args) = @_;

    for (qw/mode name type value/) {
        croak "'$_' is mandatory argument for add_variable"
            unless exists $args{$_};
    }

    my $mode       = $args{mode      };
    my $name       = $args{name      };
    my $type       = $args{type      };
    my $value      = $args{value     };
    my $definition = $args{definition} // "";

    croak "value should be a reference"
        unless ref($value);
    $type = $type->name if(ref($type) eq 'AntTweakBar::Type');

    _add_variable($self->{_bar_ptr}, $mode, $name, $type, $value, $definition);
}

sub remove_variable {
    my ($self, $name) = @_;
    _remove_variable($self->{_bar_ptr}, $name);
}

sub refresh {
    my $self = shift;
    _refresh($self->{_bar_ptr});
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

AntTweakBar - Perl extension for blah blah blah

=head1 SYNOPSIS

  use AntTweakBar;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for AntTweakBar, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>dmol@(none)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
