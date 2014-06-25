#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "AntTweakBar.h"

static HV * btn_callback_mapping = (HV*)NULL;

int init(TwGraphAPI graphic_api) {
  return TwInit(TW_OPENGL, NULL);
}

int terminate() {
  return TwTerminate();
}

int window_size(width, height) {
  return TwWindowSize(width, height);
}

TwBar* _create(const char *name) {
  return TwNewBar(name);
}

int _destroy(TwBar* bar) {
  return TwDeleteBar(bar);
}

int draw() {
  return TwDraw();
}

void _button_callback_bridge(void *data) {
  dSP;
  SV* callback = (SV*) data;
  PUSHMARK(SP);
  call_sv(callback, G_NOARGS|G_DISCARD|G_VOID);
}

void _add_button(TwBar* bar, const char *name, SV* callback, const char *definition) {
  SvGETMAGIC(callback);
  if(!SvROK(callback)
     || (SvTYPE(SvRV(callback)) != SVt_PVCV))
  {
    croak("Callback for _add_button should be a closure...\n");
  }
  if(!btn_callback_mapping) btn_callback_mapping = newHV();
  SV* callback_copy = newSVsv(callback);

  TwAddButton(bar, name, _button_callback_bridge, (void*) callback_copy, definition);
  hv_store(btn_callback_mapping, (char*)callback_copy, sizeof(callback_copy), callback_copy, 0);
}

void _add_separator(TwBar* bar, const char *name, const char *definition) {
  TwAddSeparator(bar, name, definition);
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


TwBar*
_create(name)
  const char *name
  PROTOTYPE: $

int
_destroy(bar)
  TwBar* bar
  PROTOTYPE: $

int
window_size(width, height)
  int width
  int height
  PROTOTYPE: $$

void
_add_button(bar, name, callback, definition)
  TwBar* bar
  const char *name
  SV* callback
  const char *definition
  PROTOTYPE: $$$$

void
_add_separator(bar, name, definition)
  TwBar* bar
  const char *name
  const char *definition
  PROTOTYPE: $$$

int
draw()
