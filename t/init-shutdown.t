use 5.12.0;

use Test::More;

use AntTweakBar qw/:all/;

AntTweakBar::init(TW_OPENGL);
AntTweakBar::terminate;

ok 1, "survived";

done_testing;
