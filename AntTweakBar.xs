#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "AntTweakBar.h"
#include "SDL.h"

#define CONSTANT(NAME) newCONSTSUB(stash, #NAME, newSViv((int)NAME))

void _int_getter(void* value, void* data);
void _int_setter(const void* value, void* data);

static HV * _btn_callback_mapping = NULL;
static HV * _type_map = NULL;
static HV * _getters_map = NULL;
static HV * _setters_map = NULL;
static HV * _sv_copy_names = NULL;
static SV* _modifiers_callback = NULL;

static void _add_type(const char* name, TwType type,
		      TwGetVarCallback getter, TwSetVarCallback setter) {
  hv_store(_type_map, name, strlen(name), newSViv(type), 0);
  hv_store(_getters_map, name, strlen(name), newSViv(PTR2IV(getter)), 0);
  hv_store(_setters_map, name, strlen(name), newSViv(PTR2IV(setter)), 0);
}

int _disabled_lib_mode() {
  HV* env = get_hv("main::ENV", 0);
  const char* env_flag = "ANTTWEAKBAR_DISABLE_LIB";
  int marker = hv_exists(env, env_flag, strlen(env_flag));
  return marker;
}

void init(TwGraphAPI graphic_api) {
  int result = TwInit(TW_OPENGL, NULL);
  if(!result)
    Perl_croak("Initialization error: %s", TwGetLastError());
}

void terminate() {
  int result = TwTerminate();
  if(!result)
    Perl_croak("Termination error: %s", TwGetLastError());
}

void window_size(width, height) {
  int result = TwWindowSize(width, height);
  if(!result)
    Perl_croak("Set window size error: %s", TwGetLastError());
}

TwBar* _create(const char *name) {
  if(_disabled_lib_mode()) return (TwBar*)-1;
  return TwNewBar(name);
}

void _destroy(TwBar* bar) {
  if(_disabled_lib_mode()) return;
  int result = TwDeleteBar(bar);
  if(!result)
    Perl_croak("AntTweakBar deletion error: %s", TwGetLastError());
}

void draw() {
  int result = TwDraw();
  if(!result)
    Perl_croak("AntTweakBar drawing error: %s", TwGetLastError());
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

  int result = TwAddButton(bar, name, _button_callback_bridge, (void*) callback_copy, definition);
  if(!result)
    Perl_croak("Button addition error: %s", TwGetLastError());
  hv_store(_btn_callback_mapping, (char*)callback_copy, sizeof(callback_copy), callback_copy, 0);
}

void _add_separator(TwBar* bar, const char *name, const char *definition) {
  int result = TwAddSeparator(bar, name, definition);
  if(!result)
    Perl_croak("Separator addition error: %s", TwGetLastError());
}

/* returns 1 if it has been handled by AntTweekBar */
int eventMouseButtonGLUT(int button, int state, int x, int y){
  return TwEventMouseButtonGLUT(button, state, x, y);
}

/* returns 1 if it has been handled by AntTweekBar */
int eventMouseMotionGLUT(int mouseX, int mouseY){
  return TwEventMouseMotionGLUT(mouseX, mouseY);
}

/* returns 1 if it has been handled by AntTweekBar */
int eventKeyboardGLUT(unsigned char key, int mouseX, int mouseY) {
  return TwEventKeyboardGLUT(key, mouseX, mouseY);
}

/* returns 1 if it has been handled by AntTweekBar */
int eventSpecialGLUT(int key, int mouseX, int mouseY) {
  return TwEventSpecialGLUT(key, mouseX, mouseY);
}

int eventSDL(SDL_Event* event){
  return TwEventSDL(event, SDL_MAJOR_VERSION, SDL_MINOR_VERSION);
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

int GLUTModifiersFunc(SV* callback){
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
  return TwGLUTModifiersFunc(_modifiers_callback_bridge);
}

void _add_variable(TwBar* bar, const char* mode, const char* name,
		   const char* type, SV* value_ref, const char* definition) {
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
  TwGetVarCallback tw_getter = (TwGetVarCallback) INT2PTR(IV, iv_getter);

  TwSetVarCallback tw_setter = NULL;
  if(strcmp(mode, "rw") == 0) {
    SV** getter_ref = hv_fetch(_setters_map, type, strlen(type), 0);
    IV  iv_setter = SvIV(*getter_ref);
    tw_setter = (TwSetVarCallback) INT2PTR(IV, iv_setter);
  }

  SV* value_copy = newSVsv(value_ref);
  hv_store(_sv_copy_names, name, strlen(name), value_copy, 0);
  if(_disabled_lib_mode()) return;
  int result = TwAddVarCB(bar, name, tw_type, tw_setter, tw_getter, value_copy, definition);
  if(!result){
    hv_delete(_sv_copy_names, name, strlen(name), 0);
    Perl_croak("Variable addition error: %s", TwGetLastError());
  }
}

void _remove_variable(TwBar* bar, const char* name) {
  SV* value_copy = hv_delete(_sv_copy_names, name, strlen(name), 0);
  if(!value_copy) {
    Perl_croak("No variable with name: %s", name);
  }
  if(_disabled_lib_mode()) return;
  int result = TwRemoveVar(bar, name);
  if(!result)
    Perl_croak("Removing variable %s error: %s", name, TwGetLastError());
}

TwType _register_enum(const char* name, SV* hash_ref){
  if(!SvOK(hash_ref) || !SvROK(hash_ref)){
    Perl_croak("Hashref cannot be undefined");
  }
  HV* hv =(HV*) SvRV(hash_ref);
  HE* entry;
  U32 total_keys = 0;
  hv_iterinit(hv);
  while((entry = hv_iternext(hv)) != NULL){
    I32 key_length;
    char* key = hv_iterkey(entry, &key_length);
    SV* sv_index = hv_iterval(hv, entry);
    if(sv_index && SvOK(sv_index)){
      total_keys++;
    }
  }
  TwEnumVal* enum_values = (TwEnumVal*) malloc(sizeof(TwEnumVal) * total_keys);
  TwEnumVal* enum_ptr = enum_values;
  while((entry = hv_iternext(hv)) != NULL){
    I32 key_length;
    char* key = hv_iterkey(entry, &key_length);
    SV* sv_label = hv_iterval(hv, entry);
    if(sv_label && SvOK(sv_label)){
      const char* label = SvPV_nolen(sv_label);
      (*enum_ptr).Value = atoi(key);
      (*enum_ptr).Label = label;
      enum_ptr++;
    }
  }
  TwType new_type = !_disabled_lib_mode()
    ? TwDefineEnum(name, enum_values, total_keys)
    : 0;
  _add_type(name, new_type, _int_getter, _int_setter);
  free(enum_values);
  return new_type;
}

void _refresh(TwBar* bar){
  int result = TwRefreshBar(bar);
  if(!result)
    Perl_croak("Refreshing error: %s", TwGetLastError());
}

void _set_bar_parameter(TwBar* bar, const char* param_name, const char* param_value) {
  int result = TwSetParam(bar, NULL, param_name, TW_PARAM_CSTRING, 1, param_value);
  if(!result)
    Perl_croak("Error applying value '%s' to parameter %s : %s",
	       param_value, param_name, TwGetLastError());
}

/* CALLBACKS */
/* int/bool callbacks */

void _int_getter(void* value, void* data){
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  int iv = SvIV(sv);
  *(int*)value = iv;
}

void _int_setter(const void* value, void* data){
  SV* sv = SvRV((SV*) data);
  sv_setiv(sv, *(int*)value );
  SvSETMAGIC(sv);
}

/* number(double) callbacks */

void _number_getter(void* value, void* data){
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  double dv = SvNV(sv);
  *(double*)value = dv;
}

void _number_setter(const void* value, void* data){
  SV* sv = SvRV((SV*) data);
  sv_setnv(sv, *(double*)value );
  SvSETMAGIC(sv);
}

/* string callbacks */

void _string_getter(void* value, void* data){
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  const char* string = SvPV_nolen(sv);
  *(const char**)value = string;
}

void _string_setter(const void* value, void* data){
  SV* sv = SvRV((SV*) data);
  const char* string = *(const char**)value;
  printf("set string: %s\n", string);
  sv_force_normal(sv);
  sv_setpv(sv, string);
  SvSETMAGIC(sv);
}

/* double/float array callback generators */
#define DOUBLE_CALLBACK_GETTER(NAME, NUMBER, TYPE)	 \
void NAME(void* value, void* data) { \
  SV* sv = SvRV((SV*) data); \
  if(!(SvTYPE(SvRV(sv)) == SVt_PVAV)){ \
    croak("reference does not point to array any more\n"); \
  } \
  SvGETMAGIC(sv); \
  AV* av = (AV*)SvRV(sv); \
  int my_last = av_top_index(av); \
  if(my_last != (NUMBER-1)) { \
	  Perl_croak("%s array must be %d-valued array of floats, while provided: %d\n", #NAME, NUMBER, my_last); \
  } \
  TYPE* values = (TYPE*) value; \
  int i; \
  for(i = 0; i <= my_last; i++) { \
    SV** element = av_fetch(av, i, 0); \
    if(element && SvNOK(*element)) { \
      SvGETMAGIC(*element); \
      values[i] = (float)SvNV(*element); \
    } \
  } \
};

#define DOUBLE_CALLBACK_SETTER(NAME, NUMBER, TYPE)	 \
void NAME(const void* value, void* data) { \
  SV* sv = SvRV((SV*) data); \
  if(!(SvTYPE(SvRV(sv)) == SVt_PVAV)){ \
    croak("reference does not point to array any more\n"); \
  } \
  SvGETMAGIC(sv); \
  AV* av = (AV*)SvRV(sv); \
  int my_last = av_top_index(av); \
  if(my_last != (NUMBER-1)) { \
	  Perl_croak("%s array must be %d-valued array of floats, while provided: %d\n", #NAME, NUMBER, my_last); \
  } \
  TYPE* values = (TYPE*) value; \
  int i; \
  for(i = 0; i <= my_last; i++) { \
    SV** element = av_fetch(av, i, 0); \
    if(element) { \
      double value = values[i]; \
      sv_setnv(*element, value); \
      SvGETMAGIC(*element); \
      SvSETMAGIC(sv); \
    } \
  } \
};

DOUBLE_CALLBACK_GETTER(_color3f_getter, 3, float);
DOUBLE_CALLBACK_SETTER(_color3f_setter, 3, float);
DOUBLE_CALLBACK_GETTER(_color4f_getter, 4, float);
DOUBLE_CALLBACK_SETTER(_color4f_setter, 4, float);
DOUBLE_CALLBACK_GETTER(_dir3d_getter, 3, double);
DOUBLE_CALLBACK_SETTER(_dir3d_setter, 3, double);
DOUBLE_CALLBACK_GETTER(_quat4d_getter, 4, double);
DOUBLE_CALLBACK_SETTER(_quat4d_setter, 4, double);

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
  _sv_copy_names = newHV();

  _add_type("bool", TW_TYPE_BOOL32, _int_getter, _int_setter);
  _add_type("integer", TW_TYPE_INT32,  _int_getter, _int_setter);
  _add_type("number", TW_TYPE_DOUBLE,  _number_getter, _number_setter);
  _add_type("string", TW_TYPE_CDSTRING, _string_getter, _string_setter);
  _add_type("color3f", TW_TYPE_COLOR3F, _color3f_getter, _color3f_setter);
  _add_type("color4f", TW_TYPE_COLOR4F, _color4f_getter, _color4f_setter);
  _add_type("direction", TW_TYPE_DIR3D, _dir3d_getter, _dir3d_setter);
  _add_type("quaternion", TW_TYPE_QUAT4D, _quat4d_getter, _quat4d_setter);
}

void
init(graphic_api)
  TwGraphAPI graphic_api
  PROTOTYPE: $

void
terminate()


TwBar*
_create(name)
  const char *name
  PROTOTYPE: $

void
_destroy(bar)
  TwBar* bar
  PROTOTYPE: $

void
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

void
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

int
GLUTModifiersFunc(callback)
  SV* callback
  PROTOTYPE: $

int
eventSDL(event)
 SDL_Event* event
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

void
_remove_variable(bar, name)
  TwBar* bar
  const char* name
  PROTOTYPE: $$$$$$

TwType
_register_enum(name, hash_ref)
  const char* name
  SV* hash_ref
  PROTOTYPE: $$

void
_refresh(bar)
  TwBar* bar
  PROTOTYPE: $

void
_set_bar_parameter(bar, param_name, param_value)
  TwBar* bar
  const char* param_name
  const char* param_value
  PROTOTYPE: $$$
