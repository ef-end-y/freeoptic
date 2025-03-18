let settings = {
    nodeny_api_url: undefined,
    scheme: undefined,
    scheme_gid: undefined,

    fiber_width: 7,
    fiber_connector_distance: 30,
    collapsed_cable_width: 12,
    cable_joint_width: 2,
    frame_pictures : {
        panel : {
            margin: 42,
        },
        splitter : {
            margin: 56,
        },
        coupler : {
            margin: 50,
        },
        box : {
            margin: 50,
        },
        fbt : {
            margin: 46,
        },
        onu : {
            margin: 48,
        },
        switch : {
            margin: 52,
        },
        empty : {
            margin: 0,
        },
        cable : {
            margin: 0,
        }
    },
    frame_padding: 10,
    frame_border_width: 2,
    frame_connector_width: 21,
    mute_color: '#e3e3e3',
    change_scheme_detailization_zoom: 0.235,
    min_auto_zoom: 0.132,
    area_border_k: 0.8
};

fibers = {
    settings: settings,
    scheme_settings: {},
    cy : undefined,
    first_request: true,
    fit_after_draw: true,
    dblclick   : { timeout: undefined, tapped_before: undefined },
    click_pos  : { x: 0, y: 0 },
    area       : { x1: -100000, y1: -100000, x2: 100000, y2: 100000},
    fibers_colors : {},
    fibers_colors_presets : {},
    cur_event_eles: [],
    eh_enabled : false,
    position_grid : undefined,
    position_grid_en: false,
    show_description: false,
    show_fibers_desc: false,
    last_multidrag: 0,
    simplified_scheme: undefined,
    fix_simplified_scheme: false,
    show_path_mode: false,    
    tx_rx_mode: '',
    read_only: false,
    show_all_linked_schemes: false,
    is_preview: false,
    is_map_view: false,
    is_infrastructure_view: false,
    browser_history_task: undefined,
    units_count: 0,
    tag_filters: [],
    map_options: {
        //mapTypeId: google.maps.MapTypeId.ROADMAP,
        zoom: 16,
        styles: [{
                featureType: 'poi.business',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.government',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.medical',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.school',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.place_of_worship',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.attraction',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.sports_complex',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'poi.park',
                stylers: [{visibility: 'off'}]
            },{
                featureType: 'transit.station',
                stylers: [{visibility: 'off'}]
            }
        ]
    },

    style: [
        {
            selector: 'node[debug]',
            style: {
                'content': 'data(debug)'
            }
        },{
            selector: 'node',
            style: {
                'z-index-compare': 'manual',
                'z-compound-depth': 'top',
                'z-index': 1000,
                'shape': 'rectangle'
            }
        },{
            selector: '.hidden,.temporary_hidden,[ignore]',
            style: {
                'opacity': 0
            }
        },{
            selector: '.display_none',
            style: {
                'display' : 'none'
            }
        },{
            selector: '.small-font *',
            style: {
                'font-size': 9
            }
        },{
            selector: 'node[color]',
            style: {
                'background-fill': 'linear-gradient',
                'background-gradient-stop-colors': 'data(color)'
            }
        },{
            selector: 'node[set_width]',
            style: {
                'width': 'data(set_width)',
                'height': 'data(set_height)',
                'shape': 'rectangle'
            }
        },{
            selector: 'edge',
            style: {
                'z-index': 9000,
                'z-compound-depth': 'top',
                'line-fill': 'linear-gradient',
                'line-gradient-stop-colors': '#a0a0a0',
                'overlay-padding': 0
            }
        },{
            selector: 'edge[color]',
            style: {
                'line-gradient-stop-colors': 'data(color)',
                'width': settings.fiber_width
            }
        },{
            selector: 'edge[cls="link"]',
            style: {
                'width': settings.fiber_width - 2
            }
        },{
            selector: 'edge.simplified',
            style: {
                'width': settings.collapsed_cable_width - 3,
                'line-gradient-stop-colors': '#304050',
            }
        },{
            selector: 'node[cls="grp"]',
            style: {
                'z-compound-depth': 'bottom',
                'background-opacity': '0.35',
                'border-color': '#c0c0c0',
                'border-width': 2,
                'padding-top': 10,
                'padding-bottom': 10,
                'padding-right': 40,
                'padding-left': 40
            }
        },{
            selector: 'node[cls="frame"]',
            style: {
                'text-halign': 'center',
                'text-valign': 'top',
                'border-width': settings.frame_border_width,
                'padding': settings.frame_padding,
                'background-color': '#e0e0e0'
            }
        },{
            selector: 'node[cls="frame_picture"]',
            style: {
                'z-index': 250,
                'shape': 'rectangle',
                'background-color': '#f0f0f0',
                'background-opacity': 0
            }
        },{
            selector: 'node[cls="frame_picture"][label]',
            style: {
                'label': 'data(label)'
            }
        },{
            selector: 'node[cls="frame_picture"][type="cable"]',
            style: {
                'width': 18,
                'height': 18,
                'shape': 'ellipse',
                'border-color': '#a0a0a0',
                'border-width': 4,
                'background-opacity': 1,
                'background-color': '#e0e0e0'
            }
        },{
            selector: 'node[cls="frame_picture"][type="panel"]',
            style: {
                'width': 84,
                'height': 20,
                'background-image': '/fibers/patchpanel.png'
            }
        },{
            selector: 'node[cls="frame_picture"][type="coupler"]',
            style: {
                'width': 78,
                'height': 50,
                'background-image': '/fibers/coupler.png'
            }
        },{
            selector: 'node[cls="frame_picture"][type="splitter"]',
            style: {
                'width': 80,
                'height': 47,
                'background-image': '/fibers/splitter.png'
            }
        },{
            selector: 'node[cls="frame_picture"][type="box"]',
            style: {
                'background-width': 69,
                'background-height': 51,
                'width': 69,
                'height': 51,
                'background-image': '/fibers/box.png'
            }
        },{
            selector: 'node[cls="frame_picture"][type="fbt"]',
            style: {
                'background-width': 69,
                'background-height': 37,
                'width': 69,
                'height': 37,
                'background-image': '/fibers/fbt.png'
            }
        },{
            selector: 'node[cls="frame_picture"][type="switch"]',
            style: {
                'width': 130,
                'height': 50,
                'background-image': '/fibers/switch1.png'
            }
        },{
            selector: 'node[cls="frame_picture"][type="onu"]',
            style: {
                'width': 80,
                'height': 40,
                'background-image': '/fibers/onu.png'
            }
        },{
            //selector: 'node[cls="frame"][type="panel"],node[cls="frame"][type="switch"],node[cls="frame"][type="coupler"]',
            selector: 'node[cls="frame"]',
            style: {
                'border-color': '#8dc1f7'
            }
        },{
            selector: 'node[type="container"]',
            style: {
                'z-compound-depth': 'bottom',
                'background-opacity': '0.5',
                'shape': 'round-rectangle',
                'border-color': '#d0d0d0',
                'border-width': 1,
                //'border-style': 'dashed',
                'width': 50,
                'height': 50,
                'padding': 16,
                'label': 'data(label)',
                'text-margin-y': 8,
                'color': '#a00000',
                'text-outline-color': '#b0b0b0',
                'text-outline-width': 1
            }
        },{
            selector: '.has_gps',
            style: {
                'border-color': '#60a060',
                'border-width': 3
            }
        },{
            selector: '.attention',
            style: {
                'border-color': '#ff0000',
                'border-width': 5
            }
        },{
            selector: 'node[cls="frame_inner"]',
            style: {
                'z-index': 7500,
                'text-halign': 'center',
                'text-valign': 'center',
                'width': settings.frame_connector_width,
                'height': settings.frame_connector_width,
                'font-size': 13,
                'min-zoomed-font-size': 6,
                'background-color': '#ffffff'
            }
        },{
            selector: 'node[cls="size_control"]',
            style: {
                'z-index': 7600,
                'background-color': '#ffffff',
                'width': settings.frame_connector_width,
                'height': settings.frame_connector_width,
                'background-width': 18,
                'background-height': 18,
                'background-image': '/fibers/move.png',
                'shape': 'ellipse'
            }
        },{
            selector: 'node[type="coupler"] > node[cls="size_control"]',
            style: {
                'width': 10,
                'height': 10
            }
        },{
            selector: 'node[cls="frame_inner"][label]',
            style: {
                'label': 'data(label)'
            }
        },{
            selector: '.small-font > node[cls="frame_inner"]',
            style: {
                'background-opacity': 0.6
            }
        },{
            selector: '.small-font > node[cls="frame_inner"][label]',
            style: {
                'text-rotation': -0.3,
                'background-opacity': 0,
                'text-background-opacity': 0.8,
                'text-background-color': '#ffffff'
            }
        },{
            selector: 'node[cls="frame_inner"].accent',
            style: {
                'color': '#ffffff',
                'text-background-shape': 'round-rectangle',
                'text-background-padding': 3,
                'text-background-opacity': 1,
                'text-background-color': '#007000'
            }
        },{
            selector: 'node[cls="frame_inner"][label].small-font',
            style: {
                'font-size': 8.5
            }
        },{
            selector: '[cls="position_grid"]',
            style: {
                'z-index': 7700,
                'border-width': 2,
                'border-color': '#000000',
                'background-color': '#ff0000',
                'background-opacity': 1,
                'border-opacity': 0.5,
                'width': 8,
                'height': 8
            }
        },{
            selector: 'node[type="connector"]',
            style: {
            //    'content': 'data(label)'
            }
        },{
            selector: '[type="port"]',
            style: {
                //'content': 'data(name)',
                'shape': 'round-rectangle'
            }
        },{
            selector: 'node[type="solder"]',
            style: {
                'background-color': '#a0a0a0',
                'width': 10,
                'height': 10
            }
        },{
            selector: 'node[type="splitter"] > node[type="splitter"]',
            style: {
               // 'content': 'data(name)'
            }
        },{
            selector: '.padding0',
            style: {
                'padding' : 0
            }
        },
        {
            selector: '.simplified',
            style: {
                'border-width' : 0
            }
        },

        /************************************

                        Cable

        *************************************/

        {
            selector: 'node[cls="cable_side_container"]',
            style: {
                'z-index': 100,
                'border-width': 2,
                'border-color': '#a0a0a0',
                'padding': 0,
                'shape': 'roundrectangle',
                'background-opacity': 1,
                'border-opacity': 0,
                'background-color': '#e0e0e0'
            }
        },{
            selector: 'node[cls="bone_fiber_tip"]',
            style: {
                'z-index': 50,
                'width': 1,
                'height': 1
            }
        },{
            selector: 'node[cls="fiber_tip"]',
            style: {
                'z-index': 4000,
                'width': 8,
                'height': 8,
                'shape': 'rectangle'
            }
        },{
            selector: 'node[cls="fiber_tip"].big',
            style: {
                'z-index': 6500,
                'width': 16,
                'height': 16,
                'shape': 'ellipse'
            }
        },{
            selector: 'node[cls="fiber_tip"]',
            style: {
                'font-size': 9,
                'label': 'data(label)'
            }
        },{
            selector: 'node[cls="fiber_tip"].unlinked',
            style: {
                'border-color': '#d0d0d0',
                'border-width': 4,
                'width': 1,
                'height': 1
            }
        },{
            selector: 'node[cls="cable_joint"],node[cls="cable_end_joint"]',
            style: {
                'z-index': 3000,
                'width': settings.cable_joint_width,
                'height': settings.cable_joint_width,
                'background-color': '#a0a0a0'
            }
        },{
            selector: 'node[cls="cable_joint_container"],node[cls="cable_end_joint_container"]',
            style: {
                'z-index': 3100,
                'shape': 'roundrectangle',
                'background-color': '#a0a0a0',
                'padding': 4,
                'border-width': 0
            }
        },{
            selector: 'node[cls="cable_end_joint"]',
            style: {
                'z-index': 4100
            }
        },{
            selector: 'node[cls="cable_end_joint_container"]',
            style: {
                'z-index': 4200
            }
        },{
            selector: 'node[cls="cable_end_joint_container"][label]',
            style: {
                'content': 'data(label)',
                'font-weight': 'bold'
            }
        },{
            selector: 'node[cls="cable_end_joint_container"][label]',
            style: {
                'content': 'data(label)',
                'font-weight': 'bold'
            }
        },{
            selector: 'node.linked_scheme',
            style: {
                'visibility': 'hidden'
            }
        },{
            selector: 'node[cls="link_joint"]',
            style: {
                'z-index': 3100,
                'width': 8,
                'height': 8
            }
        },{
            selector: 'node[action][action!="primary"]',
            style: {
                'background-opacity': 0
            }
        },{
            selector: 'node[action][action!="primary"] > node',
            style: {
                'width': 25,
                'height': 25,
                'background-color': '#ffffff',
                'border-color': '#900000',
                'color': '#000000',
                'border-width': 2,
                'text-valign': 'center',
                'font-size': 25
            }
        },{
            selector: 'node[action="move_all"] > node',
            style: {
                'width': 35,
                'height': 35,
                'background-width': 20,
                'background-height': 20,
                'background-image': '/fibers/move.png',
                'shape': 'ellipse'
            }
        },{
            selector: 'node[action="move_side"] > node',
            style: {
                'background-width': 15,
                'background-height': 15,
                'background-image': '/fibers/move.png',
                'shape': 'ellipse'
            }
        },{
            selector: 'node[action="slide"] > node',
            style: {
                'content': '⇕',
                'padding-top': 2
            }
        },{
            selector: 'edge[cls="collapsed_cable"]',
            style: {
                'z-index': 200,
                'width': settings.collapsed_cable_width
            }
        },{
            selector: 'edge[cls="collapsed_cable"][label]', // 'edge[cls="collapsed_cable"][length]',
            style: {
                'label': 'data(label)',
                'font-size': 12,
                'min-zoomed-font-size': 10,
                'color': '#ffffff',
                'text-outline-color': '#404040',
                'text-outline-width': 2
                //'text-margin-y': -14
            }
        },{
            selector: 'edge[linked_scheme]',
            style: {
                //'curve-style': 'unbundled-bezier',
                //'line-gradient-stop-colors': '#909090',
                'line-style': 'dashed'                
            }
        },{
            selector: 'edge[cls="single_fiber"]',
            style: {
                'z-index': 2000
            }
        },{
            selector: 'edge[cls="link"],edge[cls="splitter_connection"]',
            style: {
                'z-index': 3000
            }
        },{
            selector: 'edge[cls="grouped_links"]',
            style: {
                'width': settings.collapsed_cable_width/2,
                'opacity': 0.3
            }
        },{
            selector: 'edge[hide > 0]',
            style: {
                'display': 'none'
            }
        },

        {
            selector: 'node[cls="cable_joint_container"][parent],node[cls="cable_end_joint_container"][parent],node[cls="frame"][parent]',
            style: {
                'border-color': '#008000',
                'border-width': 1
            }
        },
        {
            selector: 'node.mute_border',
            style: {
                'border-opacity': 0.5,
                'border-width': 1
            }
        },
        

        {
            selector: '.in_path > node[cls="frame_inner"]',
            style: {
                'border-width': 1,
                'border-color': '#ff0000'
            }
        },{
            selector: '.mute',
            style: {
                'line-gradient-stop-colors': settings.mute_color,
                'border-color': settings.mute_color,
                'background-color': settings.mute_color,
                'color': settings.mute_color,
                'text-outline-width': 0
            }
        },{
            selector: 'node[cls="frame_picture"].mute',
            style: {
                'opacity': '0.15'
            }
        },{
            selector: '.mute > [cls="frame_inner"]',
            style: {
                'background-color': settings.mute_color,
                'color': '#ffffff'
            }
        },{
            selector: '.mute[cls="frame"]',
            style: {
                'background-color': '#f0f0f0'
            }
        },{
            selector: '.mute[cls="fiber_tip"]',
            style: {
                'opacity': 0
            }
        },{
            selector: '.mute[cls="cable_side_container"]',
            style: {
                'border-opacity': 0
            }
        },{
            selector: '.full_mute',
            style: {
                'line-gradient-stop-colors': settings.mute_color,
                'color': '#ffffff'
            }
        },{
            selector: '.minor',
            style: {
                'opacity': '0.3'
            }
        },{
            selector: '.warning',
            style: {
                'border-width': 6,
                'border-color': '#ff0000'
            }
        },{
            selector: '[zIndex]',
            style: {
                'z-index': 'data(zIndex)'
            }
        },

        // -----

        {
            selector: '[action!="slide"]:selected',
            style: {
                'border-color': '#ff0000',
                'z-index': 7700
            }
        },{
            selector: 'node[cls="cable_joint_container"]:selected,node[cls="cable_end_joint_container"]:selected',
            style: {
                'border-width': 3
            }
        },{
            selector: '[cls="frame"]:selected > node',
            style: {
                'visibility': 'hidden'
            }
        },
        {
            selector: 'node[cls="cable_joint"].simplified,node[cls="cable_end_joint"].simplified,node[cls="collapsed_cable"].simplified,node[cls="cable_side_container"].simplified',
            style: {
                'opacity': 0
            }
        },
        {
            selector: 'node[cls="frame"].simplified',
            style: {
                'background-color': '#506070',
                'padding-left': 15,
                'padding-right': 15,
                'border-width': 0
            }
        },
        {
            selector: 'node[type="container"].simplified',
            style: {
                'padding': 30,
                'background-color': '#8dc1f7'
            }
        },


        /*
            Drawing links
        */

        {
            selector: '.eh-handle',
            style: {
                'background-color': 'red',
                'width': 12,
                'height': 12,
                'shape': 'ellipse',
                'overlay-opacity': 0,
                'border-width': 12,
                'border-opacity': 0
            }
        },{
            selector: '.eh-hover',
            style: {
                'background-color': 'red'
            }
        },{
            selector: '.eh-source',
            style: {
                'border-width': 2,
                'border-color': 'red'
            }
        },{
            selector: '.eh-target',
            style: {
                'border-width': 2,
                'border-color': 'red'
            }
        },{
            selector: '.eh-preview, .eh-ghost-edge',
            style: {
                'background-color': 'red',
                'line-gradient-stop-colors': 'red',
            }
        },{
            selector: '.eh-ghost-edge.eh-preview-active',
            style: {
                'opacity': 0
            }
        },

        {
            selector: '[cls="collapsed_cable"].trunk',
            style: {
                'line-gradient-stop-colors': 'red'
            }
        }
    ]
};
