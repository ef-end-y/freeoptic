fibers.scheme_gid = '{{ scheme }}';
fibers.nodeny_api_url = settings.nodeny_api_url = '{{ nodeny_api_url }}';
fibers.is_preview = {{ is_preview }};

let url = new URL(document.location);
fibers.current_url = url.toString().split('#')[0];
if( url.searchParams.get('gid') ) url.searchParams.delete('gid');
if( url.searchParams.get('center_id') ) url.searchParams.delete('center_id');
fibers.current_url_without_gid = url.toString().split('#')[0];

$('#main_block_content').css('padding', '0');
$('#main_block').css('padding', '0');
let adm_top_title = $('#adm_top_title').detach();
$('#adm_top_info_line').prepend(adm_top_title);

let $cy = $('#cy');
$cy.width(nody.winW-10);
$cy.height(nody.winH - $cy.offset().top);

let cy = fibers.cy = cytoscape(
{
    container: document.getElementById('cy'),

    layout: {
        name: 'preset'
    },

    zoom: 1,
    wheelSensitivity: 0.2,
    selectionType: 'single',

    elements: [],
    style: fibers.style,
    // textureOnViewport: {% if units_count > 500 %}true{% else %}false{% endif %}
});

fibers.set_pan_area_box = function(zoom)
{
    // Calulate the visible scheme part size. Make it bigger than the screen size
    // If we pan the scheme a short distance, we can see it without loading
    const k = fibers.simplified_scheme ? 3 : zoom * fibers.settings.area_border_k / fibers.settings.change_scheme_detailization_zoom;
    const vp = fibers.cy.viewport().extent();
    const border_w = vp.w * k;
    const border_h = vp.h * k;
    fibers.area.x1 = Math.round(vp.x1 - border_w);
    fibers.area.x2 = Math.round(vp.x1 + border_w + vp.w);
    fibers.area.y1 = Math.round(vp.y1 - border_h);
    fibers.area.y2 = Math.round(vp.y1 + border_h + vp.h);
};

let Cur_url = new URL(document.location);
let p = Cur_url.searchParams;

fibers.show_path_mode = Boolean(p.get('start') && p.get('end'));
if( fibers.show_path_mode )
{
    sessionStorage.setItem('fibers_path_start', p.get('start'));
    sessionStorage.setItem('fibers_path_end', p.get('end'));
}

let Center_unit_id = parseInt(p.get('center_id'));
if( Center_unit_id )
{
    p.delete('center_id');
    history.replaceState({}, '', Cur_url.toString())
}
 else if( parseFloat(p.get('zoom')) )
{
    fibers.fit_after_draw = false;
    const zoom = p.get('zoom');
    cy.viewport({
        zoom: parseFloat(zoom),
        pan: {
            x: parseFloat(p.get('x')) || 0,
            y: parseFloat(p.get('y')) || 0
        }
    });
    const simple = fibers.simplified_scheme = p.get('simple') ? +p.get('simple') : undefined;
    if( simple === 0 ) fibers.set_pan_area_box(+zoom);
}

{% include 'base.js' %}
{% include 'map.js' %}
{% include 'menu.js' %}
{% include 'create_cy_objects.js' %}
{% include 'events.js' %}
{% include 'link_editor.js' %}


if( fibers.scheme_gid )
{
    cy.panzoom({
        zoomFactor: 0.15,
        sliderHandleIcon: ''
    });
}

api_base.tmplate_render_init();

fibers.get_all_now = function(params)
{
    let send_params = {
        act     : 'get_all',
        ok_func : 'fibers.show_all_callback'
    };
    if( params ) send_params = Object.assign(send_params, params);
    api_base.ajax(send_params);
};

let nodeny_ext_ses = '{{ set_ses }}';

if( nodeny_ext_ses )
{
    api_base.ajax({
        a       : '_set_ses',
        ses     : nodeny_ext_ses,
        ok_func : 'fibers.get_all_now'
    });
}
 else if( fibers.show_path_mode )
{
    fibers.menu_actions['path']();
}
 else if( Center_unit_id )
{
    fibers.menu_actions['center_unit_by_name']({'id': Center_unit_id});
}
 else
{
    let params = fibers.is_preview ? {preview: 1} : {};
    fibers.get_all_now(params);
}

$('[data-fibers-menu]').on('click', (event) => {
    let $this = $(event.currentTarget);
    nody.click_pos = { x: event.pageX, y: event.pageY };
    fibers.menu($this.data('fibers-menu'), {
        cy : {
            pan  : fibers.cy.pan(),
            zoom : fibers.cy.zoom()
        }
    });
});


$('#fibers__options_box').offset({top: $cy.offset().top + 5});
$('.add_listeners').each( function(){ fibers.add_listeners($(this), {}) } );

document.addEventListener('keydown', (event) =>
{
    if( event.code == 'KeyZ' && (event.ctrlKey || event.metaKey) )
    {
        fibers.show_waiting_sign();
        api_base.ajax({
            act     : 'step_back',
            ok_func : 'fibers.show_all_callback'
        });
    }
    if( event.code == 'KeyC' && (event.ctrlKey || event.metaKey) )
    {
        if( !$('.modal_container').is(':visible') ) fibers.menu_actions.copy({});
    }
});


$('#btn-toggle-simplified').on('show-state', function() {
    const simple = !!fibers.simplified_scheme;
    $(this).toggleClass('downed', simple);
    $('#cy').toggleClass('simplified', simple);
    let url = new URL(document.location);
    let p = url.searchParams;
    p.set('simple', +simple);
    history.replaceState({}, '', url.toString());
});

var global_search_str = null;
var global_search_lock = 0;
setInterval( function()
{
    if( global_search_str == null || global_search_str.length < 3 ) return;
    if( global_search_lock )
    {
        global_search_lock++;
        if( global_search_lock < 10 ) return;
    }
    global_search_lock = 1;
    api_base.ajax({
        act     : 'search',
        search  : global_search_str,
        ok_func : 'fibers.search_callback'
    });
    global_search_str = null;
    $('.adm_top_made_msg').html('');
}, 100);

var global_search_input = $('#global_search input');
$(document).bind('nody_global_search', function(event, search_str)
{
    if( global_search_str != null ) return;
    global_search_str = search_str;
    global_search_input.val(search_str);
});

global_search_input
    .keyup( function(event){
        var input = $(this);
        var key = event.keyCode;
        if( key >= 37 && key <= 39 ) return;
        global_search_str = $(this).val();
    });


$('.dropdown-content').on('mouseleave', function () {
    $(this).find('[data-confirm]').removeClass('error').data('confirm', 'yes');
});


