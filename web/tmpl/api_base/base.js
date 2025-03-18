api_base = {
    ajax_with_enctype_prepare : undefined
};

api_base.register = function(params)
{
    api_base.ajax_with_enctype_prepare = params.ajax_with_enctype_prepare;
}

api_base.tmplate_render_init = function()
{
    Handlebars.registerHelper('if_eq', function(a, b, opts) {
        if (a == b) {
            return opts.fn(this);
        } else {
            return opts.inverse(this);
        }
    });
}

api_base.modal_error = function(error)
{
    nody.modal_window.content( $('<div>', { html: error, class: 'error bigpadding' }) );
    nody.modal_window.show( -1, -1 );
};


api_base.ajax_error = function(jqXHR, exception)
{
    nody.hide_ajax_wait_block();
    api_base.modal_error( 'API error!' );
};

api_base.ajax_with_enctype = function(data, enctype)
{
    let send_data = {
        __render : 'api_ext',
        a        : '{{ a_plugin }}',
        err_func : 'api_base.modal_error'
    };
    if( api_base.ajax_with_enctype_prepare )
    {
        send_data = api_base.ajax_with_enctype_prepare(data, send_data);
        if( ! send_data ) return;
    }
    Object.assign(send_data, data);
    let form_data = new FormData();

    for( let key in send_data )
    {
        form_data.append(key, send_data[key]);
    }

    let d = {
        method      : 'post',
        url         : '{{ nodeny_api_url }}',
        dataType    : 'json',
        data        : form_data,
        processData : false,
        contentType : false,
        xhrFields   : {
            withCredentials: true
        },
        success     : nody.ajax_response,
        error       : api_base.ajax_error
    };
    if( enctype ) d.enctype = enctype;
    nody.show_ajax_wait_block();
    $.ajax(d);
};

api_base.ajax = function(data)
{
    api_base.ajax_with_enctype(data, undefined);
}

api_base.template = function(template_name, params)
{
    if( !api_base.templates[template_name] ) console.log('template ' + template_name + ' not found');
    let tmpl_params = { lang: api_base.translate };
    Object.assign(tmpl_params, params)
    return $('<div>', { html: Handlebars.compile(api_base.templates[template_name])(tmpl_params) });
};
