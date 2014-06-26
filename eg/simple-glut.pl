use 5.12.0;

use OpenGL qw/:all/;
use AntTweakBar qw/:all/;

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

# $bar->add_var(
#     mode => 'ro', # rw
#     name => "my-var-name",
#     type => # bool, integer, number, string, color3f, color4f, direction,
#     value => \$value,
#     definition => "mybar/WindVel  label='Wind velocity'",
# );

$bar->add_button(
    name       => "my-btn-name",
    cb         => sub { say "hello" },
    definition => "label='Wind velocity'",
);


glutMainLoop;
