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
    $self->{_bar_ptr} = _create($name);
    return bless $self => $class;
}

sub DESTROY {
    my $self = shift;
    _destroy($self->{_bar_ptr});
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
