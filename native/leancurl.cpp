#include <string>
#include <time.h>
#include <string.h>
#include <lean/lean.h>
#include <curl.h>

extern "C" LEAN_EXPORT lean_object* lean_curl_version () {
    curl_version_info_data* ver = curl_version_info(CURLVERSION_NOW);
    return lean_io_result_mk_ok(lean_mk_string(ver->version));
}

struct context {
    CURL *curl;
    lean_object *headerfunction;
    lean_object *headerdata;
    lean_object *writefunction;
    lean_object *writedata;
    lean_object *readfunction;
    lean_object *readdata;
    struct curl_slist *slist; // todo: dynamic
};

typedef struct context Context;

static lean_external_class * g_curl_handle_external_class = nullptr;
 
static void curl_handle_finalizer(void * h) {
    Context *context = (Context *)h;
#if DEBUG
    fprintf(stderr, "curl_handle_finalizer %p\n", context->curl);
#endif
    curl_easy_cleanup(context->curl);
    free(context);
}

static void curl_handle_foreach(void * /* mod */, b_lean_obj_arg /* fn */) {
}

lean_object * context_wrap_handle(Context  *hcurl) {
    return lean_alloc_external(g_curl_handle_external_class, hcurl);
}

static Context * context_get_handle(lean_object * hcurl) {
    return static_cast<Context *>(lean_get_external_data(hcurl));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_init () {
    if (g_curl_handle_external_class == nullptr) {
        curl_global_init(CURL_GLOBAL_ALL);
        g_curl_handle_external_class = lean_register_external_class(curl_handle_finalizer, curl_handle_foreach);
    }

    CURL *curl = curl_easy_init();

    Context *context = (Context *)malloc(sizeof *context);

    if (!context) return lean_io_result_mk_error(lean_mk_io_error_other_error(1, lean_mk_string("failed to create context handle")));

    context->curl = curl;
    context->headerfunction = NULL;
    context->headerdata = NULL;
    context->writefunction = NULL;
    context->writedata = NULL;
    context->readfunction = NULL;
    context->readdata = NULL;
    context->slist = NULL;

#if DEBUG
    fprintf(stderr, "curl_easy_init %p\n", curl);
#endif

    if (!curl) return lean_io_result_mk_error(lean_mk_io_error_other_error(1, lean_mk_string("failed to create curl handle")));
    else return lean_io_result_mk_ok(context_wrap_handle(context));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_perform (b_lean_obj_arg h) {
    Context * context = context_get_handle(h);

#if DEBUG
    fprintf(stderr, "curl_easy_perform %p starting\n", context->curl);
#endif

    CURLcode res = curl_easy_perform(context->curl);

#if DEBUG
    fprintf(stderr, "curl_easy_perform %p result %d\n", context->curl, res);
#endif

    context->headerdata = NULL;
    if (context->headerfunction) {
        lean_dec(context->headerfunction);
        context->headerfunction = NULL;
    }
    context->writedata = NULL;
    if (context->writefunction) {
        lean_dec(context->writefunction);
        context->writefunction = NULL;
    }
    context->readdata = NULL;
    if (context->readfunction) {
        lean_dec(context->readfunction);
        context->readfunction = NULL;
    }
    if (context->slist) {
        curl_slist_free_all(context->slist);
        context->slist = NULL;
    }

    if (res == 0) return lean_io_result_mk_ok(lean_box(0));
    else return lean_io_result_mk_error(lean_mk_io_error_other_error(res, lean_mk_string("curl_easy_perform failed")));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_long (b_lean_obj_arg h, uint32_t opt, uint32_t v) {
    Context * context = context_get_handle(h);

    CURLcode  res = curl_easy_setopt(context->curl, (CURLoption)opt, v);

#if DEBUG
    fprintf(stderr, "curl_easy_setopt %p %d %d\n", context->curl, opt, v);
#endif

    return lean_io_result_mk_ok(lean_box(0));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_string (b_lean_obj_arg h, uint32_t opt, lean_object *str) {
    Context * context = context_get_handle(h);
    const char* cstr = lean_string_cstr(str);

    CURLcode  res = curl_easy_setopt(context->curl, (CURLoption)opt, cstr);

#if DEBUG
    fprintf(stderr, "curl_easy_setopt %p %d %s\n", context->curl, opt, cstr);
#endif

    return lean_io_result_mk_ok(lean_box(0));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_strings (b_lean_obj_arg h, uint32_t opt, b_lean_obj_arg o) {
    Context * context = context_get_handle(h);
    size_t size = lean_array_size(o); 

    if (size > 0) {
        struct curl_slist *list = NULL;

        for (int n = 0; n < size; n++) {
            const char* cstr = lean_string_cstr(lean_array_get_core(o, n));
            list = curl_slist_append(list, cstr);

#if DEBUG
            fprintf(stderr, "curl_easy_setopt %p %d %s\n", context->curl, opt, cstr);
#endif
        }

        curl_easy_setopt(context->curl, (CURLoption)opt, list);
        context->slist = list;

        return lean_io_result_mk_ok(lean_box(0));
    } else {
        return lean_io_result_mk_error(lean_mk_io_error_other_error(1, lean_mk_string("expected array with size gt 0")));
    }
}

static size_t header_callback(void *data, size_t size, size_t nmemb, void *clientp)
{
    Context *context = (Context *)clientp;
    size_t realsize = size * nmemb;
    char *response = (char *)data;

#if DEBUG
    fprintf(stderr, "curl header_callback %p, headerfunction tag %d, headerdata tag %d, got %ld bytes\n", 
        	        context->curl, context->headerfunction->m_tag, context->headerdata->m_tag, realsize);
#endif

    lean_obj_res bytearray = lean_mk_empty_byte_array(lean_box(realsize));
    memcpy(lean_sarray_cptr(bytearray), data, realsize);
    lean_sarray_set_size(bytearray, realsize);

    lean_inc(context->headerfunction);
    lean_inc(context->headerdata);

    lean_apply_3(context->headerfunction, context->headerdata, bytearray, lean_box(0));

    return realsize;
}

static size_t write_callback(void *data, size_t size, size_t nmemb, void *clientp)
{
    Context *context = (Context *)clientp;
    size_t realsize = size * nmemb;
    char *response = (char *)data;

#if DEBUG
    fprintf(stderr, "curl write_callback %p, writefunction tag %d, writedata tag %d, got %ld bytes\n", 
        	        context->curl, context->writefunction->m_tag, context->writedata->m_tag, realsize);
#endif

    lean_obj_res bytearray = lean_mk_empty_byte_array(lean_box(realsize));
    memcpy(lean_sarray_cptr(bytearray), data, realsize);
    lean_sarray_set_size(bytearray, realsize);

    lean_inc(context->writefunction);
    lean_inc(context->writedata);

    lean_apply_3(context->writefunction, context->writedata, bytearray, lean_box(0));

    return realsize;
}

size_t read_callback(char *ptr, size_t size, size_t nmemb, void *userdata)
{
    Context *context = (Context *)userdata;

#if DEBUG
    fprintf(stderr, "curl read_callback %p, readfunction tag %d, readdata tag %d\n", 
        	        context->curl, context->readfunction->m_tag, context->readdata->m_tag);
#endif

    /* copy as much data as possible into the 'ptr' buffer, but no more than 'size' * 'nmemb' bytes! */

    lean_inc(context->readfunction);
    lean_inc(context->readdata);

    lean_object *res = lean_apply_3(context->readfunction, context->readdata, lean_box(size * nmemb), lean_box(0));   

    lean_object* bytearray = lean_ctor_get(res, 0);
    lean_object* ok = lean_ctor_get(res, 1);

    size_t len = 0;

    if (ok == (void *)1) {
        len = lean_sarray_size(bytearray);

#if DEBUG
        fprintf(stderr, "curl read_callback, copied %ld bytes\n", len);
#endif

        if (len > 0) {
            memcpy(ptr, lean_sarray_cptr(bytearray), len);
        }
    }

    return len;
}

static lean_object* lean_curl_easy_setopt_data (b_lean_obj_arg h, CURLoption opt, lean_object *r) {
    Context * context = context_get_handle(h);

    if (CURLOPT_READDATA == opt) {
        context->readdata = r;
    } else if (CURLOPT_WRITEDATA == opt) {
        context->writedata = r;
    } else if (CURLOPT_HEADERDATA == opt) {
        context->headerdata = r;
    } else {
        fprintf(stderr, "%s:%d lean_curl_easy_setopt_data opt %d unkown\n", __FILE__, __LINE__, opt);
    }

    curl_easy_setopt(context->curl, opt, (void *)context);
 
#if DEBUG
    fprintf(stderr, "lean_curl_easy_setopt_data %p %p %d tag %d\n", context->curl, r, opt, r->m_tag);
#endif

    return lean_io_result_mk_ok(lean_box(0));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_readdata (b_lean_obj_arg h, lean_object *r) {
    return lean_curl_easy_setopt_data (h, CURLOPT_READDATA, r);
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_writedata (b_lean_obj_arg h, lean_object *r) {
    return lean_curl_easy_setopt_data (h, CURLOPT_WRITEDATA, r);
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_headerdata (b_lean_obj_arg h, lean_object *r) {
    return lean_curl_easy_setopt_data (h, CURLOPT_HEADERDATA, r);
}

static lean_object* lean_curl_easy_setopt_function (b_lean_obj_arg h, CURLoption opt, lean_object *f) {
    Context * context = context_get_handle(h);

    void *callback = NULL;

    if (CURLOPT_READFUNCTION == opt) {
        context->readfunction = f;
        callback = (void *)read_callback;
    } else if (CURLOPT_WRITEFUNCTION == opt) {
        context->writefunction = f;
        callback = (void *)write_callback;
    } else if (CURLOPT_HEADERFUNCTION == opt) {
        context->headerfunction = f;
        callback = (void *)header_callback;
    } else {
        fprintf(stderr, "%s:%d lean_curl_easy_setopt_function opt %d unkown\n", __FILE__, __LINE__, opt);
    }

    curl_easy_setopt(context->curl, opt, callback);
 
#if DEBUG
    fprintf(stderr, "lean_curl_easy_setopt_function %p %p %d tag %d\n", context->curl, f, opt, f->m_tag);
#endif

    return lean_io_result_mk_ok(lean_box(0));
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_readfunction (b_lean_obj_arg h, lean_object *f) {
    return lean_curl_easy_setopt_function(h, CURLOPT_READFUNCTION, f);
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_writefunction (b_lean_obj_arg h, lean_object *f) {
    return lean_curl_easy_setopt_function(h, CURLOPT_WRITEFUNCTION, f);
}

extern "C" LEAN_EXPORT lean_object* lean_curl_easy_setopt_headerfunction (b_lean_obj_arg h, lean_object *f) {
    return lean_curl_easy_setopt_function(h, CURLOPT_HEADERFUNCTION, f);
}
