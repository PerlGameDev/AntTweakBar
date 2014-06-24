#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "AntTweakBar.h"

int init(TwGraphAPI graphic_api) {
  return TwInit(TW_OPENGL, NULL);
}

int terminate() {
  return TwTerminate();
}

int window_size(width, height) {
  return TwWindowSize(width, height);
}


MODULE = AntTweakBar		PACKAGE = AntTweakBar		

BOOT:
{
#define CONSTANT(NAME) newCONSTSUB(stash, #NAME, newSViv((int)NAME))
  HV *stash = gv_stashpv("AntTweakBar", TRUE);
  CONSTANT(TW_OPENGL);
  CONSTANT(TW_OPENGL_CORE);
  CONSTANT(TW_DIRECT3D9);
  CONSTANT(TW_DIRECT3D10);
  CONSTANT(TW_DIRECT3D11);
}

int
init(graphic_api)
  TwGraphAPI graphic_api
  PROTOTYPE: $

int 
terminate()


int 
window_size(width, height)
  int width
  int height
     PROTOTYPE: $$
