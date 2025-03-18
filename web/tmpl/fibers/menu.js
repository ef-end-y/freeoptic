fibers.show_modal = function(div, params)
{
	nody.modal_window.content( div );
	fibers.add_listeners( div, params );
	nody.modal_window.show( nody.click_pos.x, nody.click_pos.y );
};

fibers.menu_actions = {
	'toggle-link-editing' : function(params) {
		fibers.toggle_link_editing();
	},
	'center-pan' : function(params) {
		fibers.cy.fit();
		/* 
		let z = fibers.cy.zoom();
		z = 1;
		fibers.cy.pan({x: fibers.cy.width()/2 - params.x*z, y: fibers.cy.height()/2 - params.y*z});
		fibers.cy.zoom(1);
		*/
	},
	'show_all': function(params) {
		let url = new URL(document.location);
		url.searchParams.delete('start');
		url.searchParams.delete('end');
		history.replaceState({}, '', url.toString());

		url = new URL(fibers.current_url_without_gid);
		url.searchParams.delete('start');
		url.searchParams.delete('end');
		fibers.current_url_without_gid = url.toString();

		fibers.show_path_mode = false;
		fibers.get_all_now();
	},
	'position_grid'		: function(params) {
		fibers.position_grid_en = !fibers.position_grid_en;
	},
	'create-panel'		: function(params) { fibers.frame_create_menu_select_connectors(params.x, params.y, 'panel') },
	'create-coupler'	: function(params) { fibers.frame_create_menu_select_connectors(params.x, params.y, 'coupler') },
	'create-splitter'	: function(params) { fibers.frame_create_menu_select_connectors(params.x, params.y, 'splitter') },
	'create-switch'		: function(params) { fibers.frame_create_menu_select_connectors(params.x, params.y, 'switch') },
	'create-onu'		: function(params) {
		//nody.modal_window.close();
		api_base.ajax({
			act		: 'frame_create',
			x		: params.x,
			y		: params.y,
			type	: 'onu',
			ok_func	: 'fibers.create_unit_callback'
		});
	},
	'create-cable': function(params) {
		fibers.cable_create_menu(params.x, params.y);
	},
	'toggle-description': function(params) {
		fibers.get_all_now();
		let downed = fibers.show_description = !fibers.show_description;
		$('#toggle-description').toggleClass('downed', downed);
	},
	'toggle-all-linked-schemes': function(params) {
		const downed = fibers.show_all_linked_schemes = !fibers.show_all_linked_schemes;
		if( !downed ) fibers.fit_after_draw = true;
		fibers.tag_filters = [];
		$('#tags-filter-btn').removeClass('active');
		api_base.ajax({
			act      : 'get_all',
			ok_func  : 'fibers.show_all_callback'
		});
		if( fibers.is_map_view ) fibers.map_get_all_now();
		$('#toggle-all-linked-schemes').toggleClass('downed', downed);
	},
	'toggle-fibers-desc' : function(params) {
		fibers.get_all_now();
		fibers.show_fibers_desc = !fibers.show_fibers_desc;
		$('#toggle-fibers-desc').toggleClass('downed', fibers.show_fibers_desc);
	},
	'toggle-infrastructure-view' : function(params) {
		fibers.get_all_now();
		fibers.is_infrastructure_view = !fibers.is_infrastructure_view;
		$('#toggle-infrastructure-view').toggleClass('downed', fibers.is_infrastructure_view);
	},
	'toggle-simplified': function(params) {
		fibers.simplified_scheme = !fibers.simplified_scheme;
		fibers.fix_simplified_scheme = true;
		$('#btn-toggle-simplified').trigger('show-state');
		fibers.get_all_now();
	},
	'toggle-tx-rx': function(params) {
		let mode = fibers.tx_rx_mode;
		let label;
		if( mode === '' ) {
			mode = 'TX';
			label = [$('<span>', {class: 'error', text: 'TX'}), '/RX'];
		} else if( mode === 'TX' ) {
			mode = 'RX';
			label = ['TX/', $('<span>', {class: 'error', text: 'RX'})];
		} else if( mode === 'RX' ) {
			mode = 'DESCR';
			label = 'remote id';
		} else {
			mode = '';
			label = 'TX/RX';
		}
		fibers.tx_rx_mode = mode;
		$('#btn-toggle-tx-rx').html(label).toggleClass('downed', Boolean(mode));
		fibers.get_all_now();
	},
	'center_unit_by_name': function(params) {
		if( cy.zoom() < 0.55 ) cy.zoom( 0.55 );
		api_base.ajax({
			act     : 'get_all_end_center_unit',
			id      : params.id,
			ok_func : 'fibers.show_all_callback'
		});
	},
	'show-trunk': function(params) {
		cy.center(cy.$('[trunk=' + params.trunk +']').toggleClass('trunk'));
	},
	'path_start' : function(params) {
		let start_point = params.id + ':' + params.inner_id;
		sessionStorage.setItem('fibers_path_start', start_point);
		let url = new URL(document.location);
		url.searchParams.set('start', start_point);
		history.replaceState({}, '', url.toString());
	},
	'path_end' : function(params) {
		let end_point = params.id + ':' + params.inner_id;
		sessionStorage.setItem('fibers_path_end', end_point);
		let url = new URL(document.location);
		url.searchParams.set('end', end_point);
		history.replaceState({}, '', url.toString());
	},
	'path' : function(params) {
		let start_point = sessionStorage.getItem('fibers_path_start');
		let end_point = sessionStorage.getItem('fibers_path_end');

		let url = new URL(fibers.current_url_without_gid);
		url.searchParams.set('start', start_point);
		url.searchParams.set('end', end_point);
		fibers.current_url_without_gid = url.toString();

		fibers.simplified_scheme = 0;
		fibers.show_path_mode = true;
		api_base.ajax({
			act     : 'path',
			start   : start_point,
			end     : end_point,
			ok_func : 'fibers.show_all_callback'
		});
	},
	'frame-size' : function(params) {
		fibers.cy.getElementById(params.id + ':0').children('[cls="size_control"]').removeClass('display_none');
	},
	'move-all' : function(params) {
		fibers.cy.getElementById(params.id + ':cable:edge:' + params.side + ':container').data('action', 'move_all');
	},

	'copy' : function(params) {
		let bb = cy.$(':selected').boundingBox();
		api_base.ajax({
			act       : 'copy',
			copy_area : bb,
			// ok_func : 'fibers.show_all_callback'
			ok_func   : 'api_base.modal_error'
		});
	},
	'copy-from-collection': function(params) {
		api_base.ajax({
			act       : 'copy',
			force_gid : params.scheme_gid,
			ok_func   : 'api_base.modal_error'
		});
	},
	'read-only': function(params) {
		fibers.set_read_only(!fibers.read_only, true);
	},

	'export-img': function(params) {
		let png64 = fibers.cy.png({full: true, scale: 1});
		let img = $('<img>');
		img.attr('src', png64);
		let w = window.open();
		$(w.document.body).html(img);
	},
	'export-json': function(params) {
		api_base.ajax({
			act     : 'export',
			start   : fibers.path_start,
			end     : fibers.path_end,
			ok_func : 'fibers.export_json_callback'
		});
	},
	'tags-filter': function(params) {
		if( fibers.scheme_settings && fibers.scheme_settings.tags ) {
			let tags = [];
			for (const [tag, title] of Object.entries(fibers.scheme_settings.tags)) {
				tags.push({
					tag: tag,
					title: title,
					checked: fibers.tag_filters.includes(tag.toString())
				});
			}
			if( tags.length ) {
				tags = tags.sort(function (obj1, obj2) {
					return obj1.title.localeCompare(obj2.title);
				});
				params.the_tags = tags;
			}
		}
		let div = api_base.template('tags_filter', params);
		fibers.show_modal( div, params );
	},

	'toggle-map-view': function(params) {
		fibers.set_map_view(!fibers.is_map_view);
		if( fibers.is_map_view ) fibers.map_get_all_now();
	},
	'map_unit_position': function(params) {
		fibers.set_map_view(true);
		fibers.map_unit_position(params.id, params.lat, params.lng);
	},
	'map_center': function(params) {
		fibers.set_map_view(true);
		fibers.map_center();
	},
	'map_unit_center_view': function(params) {
		if( fibers.cy.zoom() < 0.9 ) fibers.cy.zoom(0.9);
		if( ! fibers.center_scheme_to_unit(params.id) ) api_base.modal_error('not found');
		if( fibers.map_info_window ) fibers.map_info_window.close();
	},
	'toggle-map-cable-length': function(params) {
		const downed = fibers.map_state.show_cable_length = !fibers.map_state.show_cable_length;
		$('#btn-toggle-map-cable-length').toggleClass('downed', downed);
		fibers.map_get_all_now();
	}
};

fibers.set_map_view = function(is_map_view)
{
	const view_changed = Boolean(fibers.is_map_view != is_map_view);
	fibers.is_map_view = is_map_view;
	$('#toggle-map-view').toggleClass('downed', is_map_view);
	if( view_changed )
	{
		const pan = fibers.cy.pan();
		fibers.cy.pan({ x: pan.x + (is_map_view ? -1 : 1) * $(window).width()/2, y: pan.y });
	}
	$('#map-container').toggle(is_map_view);
	$('#map-button-panel').toggle(is_map_view);
	fibers.cy.resize();
}

fibers.export_json_callback = function(data)
{
	let a = $('<a>', {
		'download': 'data.json',
		'href': 'data:application/json,' + encodeURIComponent(JSON.stringify(data)),
		'text': 'Download',
		'class': 'big'
	});
	nody.modal_window.content( a );
	nody.modal_window.show(-1, -1);
};

fibers.add_listeners = function(div, params)
{
	div.find('[data-menu]').on('click', function()
	{
		let $this = $(this);
		for( let key in $this.data() ) {
			params[key] = $this.data(key);
		}
		if( $this.data('menu-add-fibers') ) params.fibers = fibers;
		let block = api_base.template($this.data('menu'), params);
		let view = $this.data('menu-view')
		if( view === 'full' ) {
			nody.click_pos.x = -1;
			nody.click_pos.y = -1;
			block.width(nody.winW * 0.9);
			block.height(nody.winH * 0.9);
		}
		if( view === 'center' ) {
			nody.click_pos.x = -1;
			nody.click_pos.y = -1;
		}
		fibers.show_modal( block, params );
	});

	div.find('[data-action]').on('click', function()
	{
		nody.modal_window.close();
		let $this = $(this);

		if( $this.data('set-click-position') ) {
			const offset = $this.offset();
			nody.click_pos.x = offset.left;
			nody.click_pos.y = offset.top;
		}

		const action = $this.data('action');

		for( const key in $this.data() ) {
			params[key] = $this.data(key);
		}
		fibers.menu_actions[action](params);
	});

	div.find('a[data-ajax]').on('click', function(event)
	{
		let $this = $(this);

		if( $this.hasClass('correct-click-position') ) {
			nody.click_pos = { x: (event.pageX + nody.click_pos.x)/2, y: (event.pageY + nody.click_pos.y)/2 };
		} else {
			nody.click_pos = { x: event.pageX, y: event.pageY };
		}
		if( $this.data('confirm') == 'yes' )
		{
			$this.data('confirm', 'no');
			$this.addClass('error');
			return;
		}
		if( $this.data('wating-sigh') )
		{
			fibers.show_waiting_sign();
		} else {
			nody.modal_window.close();
		}
		const act = $this.data('ajax');
		const type = $this.data('type');
		let send_data = {
			act		: act,
			ok_func	: fibers.act_to_func[act]
		};
		Object.assign(send_data, params);
		if( type !== undefined ) send_data['type'] = type;
		for( let key in $this.data() )
		{
			if( key.startsWith('ajaxParam') ) {
				send_data[key.replace(/^ajaxParam/, '').toLowerCase()] = $this.data(key);
			}
		}
		api_base.ajax(send_data);
	});

	div.find('form[data-ajax]').each(function()
	{
		$(this).on('submit', function(event)
		{
			event.preventDefault();
			let form = $(this);
			let act = form.data('ajax');
			let enctype = form.attr('enctype');
			let data = {
				act		: act,
				ok_func	: fibers.act_to_func[act]
			};
			for( let pair of new FormData(form.get(0)).entries() )
			{
				data[pair[0]] = pair[1];
			}
			if( form.data('autoclose') ) nody.modal_window.close();
			api_base.ajax_with_enctype(data, enctype);
		});
	});
};

fibers.main_menu = function(params)
{
	let render_params = {
		not_read_only: !fibers.read_only,
		eh_enabled: fibers.eh_enabled,
		position_grid_en: fibers.position_grid_en,
		is_infrastructure_view: fibers.is_infrastructure_view,
		can_trace_path: sessionStorage.getItem('fibers_path_start') && sessionStorage.getItem('fibers_path_end')
	};
	let div = api_base.template('main_menu', render_params);
	fibers.show_modal( div, params );
};

fibers.frame_create_menu_select_connectors = function(x, y, frame_type)
{
	let div = api_base.template('frame_create_menu_select_connectors', { frame_type: frame_type });
	fibers.show_modal(div, {})
	div.find('[type=submit]').on('click', function()
	{
		nody.modal_window.close();
		api_base.ajax({
			act			: 'frame_create',
			x			: x,
			y			: y,
			type		: frame_type,
			connectors	: div.find('[name=connectors]').val(),
			cols        : div.find('[name=cols]:checked').val(),
			ok_func		: 'fibers.create_unit_callback'
		});
	});
};

fibers.cable_create_menu = function(x, y)
{
	let colors_presets = [];
	let can_remove = false;
	for( let [preset_id, preset] of Object.entries(fibers.fibers_colors_presets) )
	{
		let colors = []
		colors_presets.push({
			preset_id   : preset_id,
			description : preset.description,
			colors      : colors
		});
		for( let color_idx of Object.values(preset.colors) )
		{
			let c = fibers.fibers_colors[color_idx].color.split(' ');
			colors.push({
				first : c[0],
				second: c.length > 1 ? c[1] : undefined
			});
		}
		if( +preset.can_remove ) can_remove = true;
	}
	let params =  { colors: fibers.fibers_colors, colors_presets: colors_presets, can_remove: can_remove };
	let div = api_base.template('cable_create_menu_select_color_preset', params);

	fibers.show_modal(div, params)

	div.find('[data-color-preset-id]').on('click', function()
	{
	    fibers.cable_create_menu_select_fibers(x, y, $(this).data('color-preset-id'));
	});
};

fibers.cable_create_menu_select_fibers = function(x, y, color_preset_id)
{
	let div = api_base.template('cable_create_menu_select_fibers', {});
	nody.modal_window.content( div );
	div.find('[type=submit]').on('click', function()
	{
		nody.modal_window.close();
		api_base.ajax({
			act		: 'cable_create',
			x		: x,
			y		: y,
			fibers_count	: div.find('[name=fibers]').val(),
			multimode		: div.find('[name=multimode]').val(),
			color_preset_id	: color_preset_id,
			ok_func			: 'fibers.create_unit_callback'
		});
	});
};


fibers.cable_connector_menu = function(params)
{
	if( fibers.read_only ) return;
	let div = api_base.template('cable_connector_menu', { colors: fibers.fibers_colors });
	nody.modal_window.content( div );

	fibers.add_listeners( div, params );

	div.find('[data-color-id]').on('click', function()
	{
		nody.modal_window.close();
		api_base.ajax({
			act      : 'cable_change_color',
			id       : params.id,
			fiber_id : params.fiber_id,
			color    : $(this).data('color-id'),
			ok_func  : 'fibers.replace_obj'
		});
	});

	nody.modal_window.show( nody.click_pos.x, nody.click_pos.y );
};

fibers.frame_menu = function(params, target)
{
	params.can_resize = Boolean(target.children().length > 2); // 1 connector + 1 size control element
	let div = api_base.template('frame_menu', Object.assign({target: target.data()}, params));
	nody.modal_window.content( div );

	fibers.add_listeners( div, params );

	div.find('form').attr('action', nody.script_url);
	div.find('form').each(function(){
		$(this).append($('<input>', { type : 'hidden', name : 'id', value : params.id }));
	});

	nody.modal_window.show( nody.click_pos.x, nody.click_pos.y );
};

fibers.frame_data = function(params)
{
	for( let type of (params.map_types || []) ) {
		if( type.id == params.map_type ) type.selected = true;
	}
	if( fibers.scheme_settings && fibers.scheme_settings.tags ) {
		let tags = [];
		for (let [tag, title] of Object.entries(fibers.scheme_settings.tags)) {
			tag = tag.split(':')[1];
			tags.push({
				tag: tag,
				title: title,
				checked: params.tags.includes(tag)
			});
		}
		if( tags.length ) params.the_tags = tags;
	}
	let div = api_base.template('frame_data', params);
	fibers.show_modal( div, params );
};

fibers.frame_inner_data = function(params)
{
	params.not_read_only = !fibers.read_only;
	let div = api_base.template('frame_inner_data', params);
	fibers.show_modal( div, params );
};

fibers.collapsed_cable_menu = function(params, target)
{
	params.can_align_y = params.tangent > 4;
	params.can_align_x = params.tangent < 0.6;
	params.not_read_only = !fibers.read_only;
	let div = api_base.template('collapsed_cable_menu', params);
	fibers.show_modal( div, params );
};

fibers.cable_data = function(params)
{
	params.read_only = fibers.read_only;
	params.not_read_only = !fibers.read_only;
	for( let trunk of (params.trunks || []) ) {
		if( trunk.id == params.trunk ) trunk.selected = true;
	}
	for( let type of (params.map_types || []) ) {
		if( type.id == params.map_type ) type.selected = true;
	}
	params.stock_enabled = fibers.stock_enabled;
	let div = api_base.template('cable_data', params);
	fibers.show_modal( div, params );
};

fibers.cable_joint_data = function(params)
{
	params.not_read_only = !fibers.read_only;
	let div = api_base.template('cable_joint_data', params);
	fibers.show_modal( div, params );
};

fibers.scheme_data_callback = function(params)
{
	params.favorite_checked = +params.favorite > 0 ? 'checked' : 0;
	params.current_url = fibers.current_url;
	let div = api_base.template('scheme_data', params);
	fibers.show_modal( div, params );
};

fibers.scheme_data_save_callback = function(params)
{
	fibers.scheme_settings = params.settings;
	nody.modal_window.close();
};

fibers.show_collection = function(all_schemes, page)
{
	api_base.ajax({
		act     : 'show_collection',
		ok_func : 'fibers.show_collection_callback',
		all_schemes : all_schemes,
		page : page
	});
};

fibers.show_collection_callback = function(params)
{
	params = params[0];
	for( let scheme of params.schemes )
	{
		let iframe = $('<iframe>', {
			id: 'iframe_' + scheme.gid,
			src: fibers.nodeny_api_url + '&a=fibers&action=preview&gid=' + scheme.gid,
			class: params.all_schemes ? 'full' : ''
		});
		$('#collection_container').append(iframe);
		iframe.on('click', function() {
			fibers.menu( 'collection_item_menu', {
				scheme_gid: scheme.gid,
				nodeny_api_url: fibers.nodeny_api_url
			});
		});
	}
	let collection_pagination = $('#collection_pagination');
	collection_pagination.text('');
	if( params.pages > 1 )
	{
		for( var i = 1; i <= params.pages; i++ ) {
			collection_pagination.append($('<a>', {
				'data-menu': (params.all_schemes ? 'show_all_schemes' : 'show_collection'),
				'data-menu-add-page': (i-1),
				'data-menu-view': 'full',
				'text': i + ' ',
				'class': 'big cursor_pointer'
			}));
		}
	}
	fibers.add_listeners(collection_pagination, {});
};

fibers.link_with_scheme_callback = function(params)
{
	let div = api_base.template('link_cable_with_scheme', params);
	fibers.show_modal( div, params );
};

fibers.link_with_scheme_save_callback = function(params)
{
	if( params && 'add_data' in params[0]) {
		console.log(params[0].add_data);
		$('#toggle-all-linked-schemes').toggle(Boolean(params[0].add_data.linked_scheme));
	}
	return fibers.replace_obj(params);
}

fibers.goto_linked_scheme_callback = function(params)
{
	if( params.gid && params.id )
	{
		document.location.href = fibers.current_url_without_gid + '&gid=' + params.gid + '&center_id=' + params.id;
	}
};

fibers.menu = function(template, params)
{
	params.not_read_only = !fibers.read_only;
	let block = api_base.template(template, params);    
	fibers.show_modal( block, params );
};

