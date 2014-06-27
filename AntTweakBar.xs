#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "AntTweakBar.h"

#define CONSTANT(NAME) newCONSTSUB(stash, #NAME, newSViv((int)NAME))
#define ADD_TYPE(NAME, TW_TYPE, GETTER, SETTER)				    \
  hv_store(_type_map, #NAME, strlen(#NAME), newSViv(TW_TYPE), 0);           \
  hv_store(_getters_map, #NAME, strlen(#NAME), newSViv(PTR2IV(GETTER)), 0); \
  hv_store(_setters_map, #NAME, strlen(#NAME), newSViv(PTR2IV(SETTER)), 0);


static HV * _btn_callback_mapping = NULL;
static HV * _type_map = NULL;
static HV * _getters_map = NULL;
static HV * _setters_map = NULL;
static HV * _sv_instance_types = NULL;
static SV* _modifiers_callback = NULL;

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
  if(!_btn_callback_mapping) _btn_callback_mapping = newHV();
  SV* callback_copy = newSVsv(callback);

  TwAddButton(bar, name, _button_callback_bridge, (void*) callback_copy, definition);
  hv_store(_btn_callback_mapping, (char*)callback_copy, sizeof(callback_copy), callback_copy, 0);
}

void _add_separator(TwBar* bar, const char *name, const char *definition) {
  TwAddSeparator(bar, name, definition);
}

int eventMouseButtonGLUT(int button, int state, int x, int y){
  return TwEventMouseButtonGLUT(button, state, x, y);
}

int eventMouseMotionGLUT(int mouseX, int mouseY){
  return TwEventMouseMotionGLUT(mouseX, mouseY);
}

int eventKeyboardGLUT(unsigned char key, int mouseX, int mouseY) {
  return TwEventKeyboardGLUT(key, mouseX, mouseY);
}

int eventSpecialGLUT(int key, int mouseX, int mouseY) {
  return TwEventSpecialGLUT(key, mouseX, mouseY);
}

int _modifiers_callback_bridge(){
  if(!_modifiers_callback){
    croak("internal error: no _modifiers_callback\n");
    return -1;
  }
  dSP;
  PUSHMARK(SP);
  call_sv(_modifiers_callback, G_NOARGS|G_DISCARD|G_VOID);
}

void GLUTModifiersFunc(SV* callback){
  SvGETMAGIC(callback);
  if(!SvROK(callback)
     || (SvTYPE(SvRV(callback)) != SVt_PVCV))
  {
    croak("Callback for GLUTModifiersFunc should be a closure...\n");
  }
  if(_modifiers_callback) {
     SvREFCNT_dec(_modifiers_callback);
  }
  _modifiers_callback = newSVsv(callback);
  TwGLUTModifiersFunc(_modifiers_callback_bridge);
}

void _add_variable(TwBar* bar, const char* mode, const char* name,
		   const char* type, SV* value, const char* definition) {
  SV** sv_type_ref = hv_fetch(_type_map, type, strlen(type), 0);
  TwType tw_type = 0;
  if(sv_type_ref) {
    tw_type = (TwType) SvIV(*sv_type_ref);
  }
  if(!sv_type_ref) {
    Perl_croak("Undefined var type: %s", type);
  }

  SV** getter_ref = hv_fetch(_getters_map, type, strlen(type), 0);
  IV  iv_getter = SvIV(*getter_ref);
  TwGetVarCallback tw_getter = (TwGetVarCallback*) INT2PTR(IV, iv_getter);

  TwSetVarCallback tw_setter = NULL;
  if(strcmp(mode, "rw") == 0) {
    SV** getter_ref = hv_fetch(_setters_map, type, strlen(type), 0);
    IV  iv_setter = SvIV(*getter_ref);
    tw_setter = (TwSetVarCallback*) INT2PTR(IV, iv_setter);
  }

  SV* value_copy = newSVsv(value);
  //SV* value_copy = newRV_inc(value);
  hv_store(_sv_instance_types, (char*)value_copy, sizeof(value_copy), *sv_type_ref, 0);
  TwAddVarCB(bar, name, tw_type, tw_setter, tw_getter, value_copy, definition);
}

void _int_getter(void* value, void* data){
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  int iv = SvIV(sv);
  printf("_int_getter: %d\n", iv);
  *(int*)value = iv;
}

void _int_setter(void* value, void* data){
  SV* sv = SvRV((SV*) data);
  sv_setiv(sv, *(int*)value );
  SvSETMAGIC(sv);
  printf("_int_setter: %d\n", SvIV(sv));
}

MODULE = AntTweakBar		PACKAGE = AntTweakBar

BOOT:
{
  HV *stash = gv_stashpv("AntTweakBar", TRUE);
  CONSTANT(TW_OPENGL);
  CONSTANT(TW_OPENGL_CORE);
  CONSTANT(TW_DIRECT3D9);
  CONSTANT(TW_DIRECT3D10);
  CONSTANT(TW_DIRECT3D11);

  _type_map = newHV();
  _getters_map = newHV();
  _setters_map = newHV();
  _sv_instance_types = newHV();

  ADD_TYPE(bool, TW_TYPE_BOOL32, _int_getter, _int_setter);
  ADD_TYPE(integer, TW_TYPE_INT32,  _int_getter, _int_setter);
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

int
eventMouseButtonGLUT(button, state, x, y)
  int button
  int state
  int x
  int y
  PROTOTYPE: $$$$

int
eventMouseMotionGLUT(mouseX, mouseY)
  int mouseX
  int mouseY
  PROTOTYPE: $$

int
eventKeyboardGLUT(key, mouseX, mouseY)
  unsigned char key
  int mouseX
  int mouseY
  PROTOTYPE: $$$

int
eventSpecialGLUT(key, mouseX, mouseY)
  int key
  int mouseX
  int mouseY
  PROTOTYPE: $$$

void
GLUTModifiersFunc(callback)
  SV* callback
  PROTOTYPE: $

void
_add_variable(bar, mode, name, type, value, definition)
  TwBar* bar
  const char* mode
  const char* name
  const char* type
  SV* value
  const char* definition
  PROTOTYPE: $$$$$$
