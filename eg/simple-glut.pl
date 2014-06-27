use 5.12.0;

use OpenGL qw/:all/;
use AntTweakBar qw/:all/;
use Data::Dump qw/dump/;

sub display {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glEnable(GL_NORMALIZE);

    AntTweakBar::draw;
    glutSwapBuffers;
    glutPostRedisplay;
}

sub reshape {
    my ($width, $height) = @_;
    glViewport(0, 0, $width, $height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(40, $width/$height, 1, 10);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5, 0,0,0, 0,1,0);
    glTranslatef(0, 0.6, -1);

    say "window size: ${width} x ${height}";
    AntTweakBar::window_size($width, $height);
}


glutInit;
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
glutInitWindowSize(640, 480);
glutCreateWindow("[perl] AntTweakBar simple example using GLUT");

AntTweakBar::init(TW_OPENGL);

glutDisplayFunc(\&display);
glutReshapeFunc(\&reshape);
glutMouseFunc(\&AntTweakBar::eventMouseButtonGLUT);
glutMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
glutPassiveMotionFunc(\&AntTweakBar::eventMouseMotionGLUT);
glutKeyboardFunc(\&AntTweakBar::eventKeyboardGLUT);
glutSpecialFunc(\&AntTweakBar::eventSpecialGLUT);
AntTweakBar::GLUTModifiersFunc(\&glutGetModifiers);

reshape(640, 480);
my $bar = AntTweakBar->new("TweakBar & Perl");
$bar->add_separator("x-sep");

my $bool_ro = 1;
my $bool_rw = 0;
my $int_ro = 100;
my $int_rw = 200;
my $number_ro = 3.14;
my $number_rw = 2.78;
my $string_ro = "abc";
my $string_rw = "cde";
my $color3f_ro = [1.0, 1.0, 0.0];
my $color3f_rw = [0.5, 0.5, 1.0];
my $color4f_ro = [1.0, 1.0, 0.0, 0.1];
my $color4f_rw = [0.5, 0.5, 1.0, 0.2];

# types: bool, integer, number, string, color3f, color4f, direction, quaternion, custom enums
$bar->add_variable(
    mode       => 'ro',
    name       => "bool_ro",
    type       => 'bool',
    value      => \$bool_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "bool_rw",
    type       => 'bool',
    value      => \$bool_rw,
    definition => "",
);
$bar->add_variable(
    mode       => 'ro',
    name       => "integer_ro",
    type       => 'integer',
    value      => \$int_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "integer_rw",
    type       => 'integer',
    value      => \$int_rw,
    definition => "max=300 step=5",
);
$bar->add_variable(
    mode       => 'ro',
    name       => "number_ro",
    type       => 'number',
    value      => \$number_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "number_rw",
    type       => 'number',
    value      => \$number_rw,
    definition => "min=0 step=0.01",
);
$bar->add_variable(
    mode       => 'ro',
    name       => "string_ro",
    type       => 'string',
    value      => \$string_ro,
    definition => "",
);
$bar->add_variable(
    mode       => 'rw',
    name       => "string_rw",
    type       => 'string',
    value      => \$string_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "color3f_ro",
    type       => 'color3f',
    value      => \$color3f_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "color3f_rw",
    type       => 'color3f',
    value      => \$color3f_rw,
);
$bar->add_variable(
    mode       => 'ro',
    name       => "color4f_ro",
    type       => 'color4f',
    value      => \$color4f_ro,
);
$bar->add_variable(
    mode       => 'rw',
    name       => "color4f_rw",
    type       => 'color4f',
    value      => \$color4f_rw,
);

$bar->add_button(
    name       => "my-btn-name",
    cb         => sub {
        say "bool_ro=$bool_ro, bool_rw=$bool_rw";
        say "int_ro=$int_ro, int_rw=$int_rw";
        say "number_ro=$number_ro, number_rw=$number_rw";
        say "string_ro=$string_ro, string_rw=$string_rw";
        say "color3f_ro=", dump($color3f_ro), ", color3f_rw=", dump($color3f_rw);
        say "color4f_ro=", dump($color4f_ro), ", color4f_rw=", dump($color4f_rw);
    },
    definition => "label='dump'",
);
$bar->add_separator("separator2");


glutMainLoop;
