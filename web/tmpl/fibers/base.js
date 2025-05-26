{% include '../api_base/base.js' %}

fibers.act_to_func = {
  'get_all'               : 'fibers.show_all_callback',
  'paste'                 : 'fibers.show_all_callback',
  'check_history'         : 'fibers.show_all_callback',
  'get_fragment'          : 'fibers.reload_new_scheme',
  'pon_path'              : 'fibers.show_all_callback',
  'pon_create'            : 'fibers.show_all_callback',
  'frame_create'          : 'fibers.create_unit_callback',
  'frame_add_inner'       : 'fibers.replace_obj',
  'frame_inner_align'     : 'fibers.replace_obj',
  'frame_inner_align_grid' : 'fibers.replace_obj',
  'frame_inner_align_lr'  : 'fibers.replace_obj',
  'frame_inner_align_connected' : 'fibers.replace_obj',
  'frame_remove'          : 'fibers.frame_remove',
  'frame_inner_remove'    : 'fibers.frame_inner_remove_callback',
  'frame_data'            : 'fibers.frame_data',
  'frame_data_save'       : 'fibers.update_obj',
  'frame_inner_data'      : 'fibers.frame_inner_data',
  'frame_inner_data_save' : 'fibers.update_obj',
  'frame_upload_img'      : 'fibers.update_obj',
  'frame_remove_img'      : 'fibers.update_obj',
  'frame_change_type'     : 'fibers.update_obj',
  'frame_rotate'          : 'fibers.update_obj',
  'cable_data'            : 'fibers.cable_data',
  'cable_data_save'       : 'fibers.replace_obj',
  'cable_joint_align'     : 'fibers.replace_obj',
  'cable_joint_add'       : 'fibers.replace_obj',
  'cable_joint_remove'    : 'fibers.replace_obj',
  'cable_joint_data'      : 'fibers.cable_joint_data',
  'cable_joint_data_save' : 'nody.modal_window.close',
  'cable_rotate_edge'     : 'fibers.replace_obj',
  'cable_remove'          : 'fibers.cable_remove_callback',
  'cable_remove_all_joints' : 'fibers.replace_obj',
  'cable_fiber_add'       : 'fibers.replace_obj',
  'cable_fiber_remove'    : 'fibers.cable_remove_fiber_callback',
  'cable_cut'             : 'fibers.show_all_callback',
  'cable_insert_splitter' : 'fibers.cable_insert_splitter',
  'cable_insert_splitter_now': 'fibers.show_all_callback',
  'cable_find_break'      : 'fibers.map_all_callback',

  'link_remove'           : 'fibers.link_remove_callback',
  'link_joint_add'        : 'fibers.link_replace_callback',
  'link_joint_remove'     : 'fibers.link_replace_callback',

  'remove_from_container' : 'fibers.container_callback',
  'move_into_container'   : 'fibers.container_callback',

  'nomap'                 : 'fibers.nomap_callback',
  'bookmark_create'       : 'fibers.show_bookmark_link',
  'history'               : 'fibers.history_callback',
  'step_back'             : 'fibers.show_all_callback',
  'step_forward'          : 'fibers.show_all_callback',
  'create_color_preset'   : 'fibers.show_all_callback',
  'delete_color_preset'   : 'fibers.show_all_callback',
  'import'                : 'fibers.show_all_callback',
  'scheme_data'           : 'fibers.scheme_data_callback',
  'scheme_data_save'      : 'fibers.scheme_data_save_callback',
  'scheme_remove'         : 'fibers.scheme_remove_callback',
  'link_with_scheme'      : 'fibers.link_with_scheme_callback',
  'link_with_scheme_save' : 'fibers.link_with_scheme_save_callback',
  'goto_linked_scheme'    : 'fibers.goto_linked_scheme_callback',

  'map_unit_remove'       : 'fibers.map_unit_position_callback',
};

api_base.register({
  ajax_with_enctype_prepare: function(data, send_data) {
      {% if ! scheme %}if( data.act != 'get_all' && data.a != '_set_ses' ) return undefined;{% endif %}

      let pan = fibers.cy.pan();
      send_data.pan_x = Math.round(pan.x);
      send_data.pan_y = Math.round(pan.y);
      send_data.zoom = fibers.cy.zoom();

      let area = data.copy_area ? data.copy_area : fibers.area;
      if( data.copy_area ) delete data.copy_area;
      send_data.area_x1 = area.x1;
      send_data.area_x2 = area.x2;
      send_data.area_y1 = area.y1;
      send_data.area_y2 = area.y2;
      if( fibers.is_infrastructure_view ) send_data.fibers_mode = 'map';
      if( fibers.simplified_scheme !== undefined ) send_data.simple = fibers.simplified_scheme ? 1 : 0;
      if( fibers.tx_rx_mode ) send_data.tx_rx_mode = fibers.tx_rx_mode;
      if( fibers.first_request ) {
          fibers.first_request = false;
          send_data.first_request = 1;
      }
      if( fibers.show_all_linked_schemes ) {
          send_data.all_linked_schemes = 1;
      }
      if( fibers.tag_filters.length ) {
          send_data.tag_filters = fibers.tag_filters;
      }
      return send_data;
  }
});

fibers.reload = function()
{
  let url = new URL(document.location);
  let p = url.searchParams;
  p.set('x', fibers.cy.pan().x);
  p.set('y', fibers.cy.pan().y);
  p.set('zoom', fibers.cy.zoom());
  p.set('version', Math.random());
  window.location.href = url.toString();
};

fibers.current_node_position = function(target)
{
  let b = target.boundingBox({includeLabels: false});
  return {
      x  : (b.x2+b.x1)/2,
      y  : (b.y2+b.y1)/2,
      x1 : b.x1,
      y1 : b.y1
  };
};

fibers.update_start_position = function(target)
{
  target.data('start_pos', fibers.current_node_position(target));
};

fibers.update_center_info = function(target)
{
  target.data('center', fibers.current_node_position(target));
};

fibers.create_unit_callback = function(data)
{
  nody.modal_window.close();
  fibers.cy.add(fibers.make_unit(data));
};

fibers.replace_obj = function(data)
{
  let unit_data = fibers.make_unit(data, true);
  fibers.cy.add(unit_data);
  fibers.update_obj(data);
};

fibers.update_obj = function(data)
{
  nody.modal_window.close();
  if( data === 'reload' ) return fibers.get_all_now();

  if( fibers.is_map_view )
  {
      let reload_map = false;
      for( let p of (Array.isArray(data) ? data : [ data ]) )
      {
          if( (p.lat || p.cls === 'cable') && p.map_type !== undefined && p.old !== undefined && p.map_type != p.old.map_type ) reload_map = true;
      }
      if( reload_map ) fibers.map_get_all_now();
  }

  if( data.grp !== undefined && data.old !== undefined && data.old.grp !== undefined && +data.grp != +data.old.grp )
  {
      return fibers.get_all_now();
  }

  data = fibers.make_unit(data);
  for( let p of data )
  {
      let target = fibers.cy.getElementById(p.data.id);
      if( p.position && (target.data('type') != 'container' || !target.isParent()) )
      {
          target.position(p.position);
      }
      if( p.data.parent != target.data('parent') )
      {
          target.move({parent: p.data.parent || null});
      }
      target.data(p.data);
      //if( fibers.is_map_view && data.map_type !== undefined && data.old !== undefined && data.map_type != data.old.map_type
      //){
      //    reload_map = true;
      //}
  }
};

fibers.frame_remove = function(id)
{
  nody.modal_window.close();
  id += ':0';
  let unit = fibers.cy.getElementById(id);
  if( unit.data('type') == 'container' ) return fibers.get_all_now();
  fibers.cy.remove(unit);
  fibers.cy.remove(fibers.cy.elements('[id^="' + id + ':frame_picture"]'));
};

fibers.frame_inner_remove_callback = function(data)
{
  nody.modal_window.close();
  if( data.parent_removed ) return fibers.frame_remove(data.data.id);
  fibers.cy.remove(fibers.cy.getElementById(data.data.id + ':0:' + data.inner_id));
};

fibers.link_create_callback = function(data)
{
  if( Object.keys(data).length ) fibers.cy.add(fibers.make_link(data));
};

fibers.link_remove = function(id)
{
  fibers.cy.remove(fibers.cy.elements('[id^="link:' + id + ':"]'));
};

fibers.link_remove_callback = function(data)
{
  nody.modal_window.close();
  fibers.link_remove(data.id);
};

fibers.link_replace_callback = function(data)
{
  nody.modal_window.close();
  fibers.link_remove(data.id);
  fibers.cy.add(fibers.make_link(data));
};


fibers.cable_remove_callback = function(id)
{
  nody.modal_window.close();
  fibers.get_all_now();
};

fibers.cable_remove_fiber_callback = function(data)
{
  nody.modal_window.close();
  fibers.get_all_now();
};

fibers.container_callback = function(data)
{
  if( !data ) return;
  if( data === 'reload' ) return fibers.get_all_now();
  fibers.replace_obj(data.data);
  if( data.container )
  {
      fibers.replace_obj(data.container);
  }
  if( fibers.is_map_view ) fibers.map_get_all_now();
};


fibers.show_bookmark_link = function(bookmark)
{
  let div = $('<div>', { html: api_base.template('bookmark_item', { title: bookmark.name } ) });
  nody.modal_window.content( div );
  fibers.add_listeners( div, {} );

  div.find('a[data-viewport]').on('click', function(){
      fibers.cy.viewport({
          zoom: parseFloat(bookmark.zoom),
          pan: {x: parseFloat(bookmark.x), y: parseFloat(bookmark.y)}
      });
  });
  div.find('a[data-remove-bookmark]').on('click', function(){
      div.hide();
      api_base.ajax({
          act     : 'bookmark_remove',
          id      : bookmark.id,
          ok_func : ''
      });
  });

  $('#fibers__bookmarks_list').append(div);
};

fibers.mark_as_minor = function(target)
{
	cy.startBatch();
	for( let c of target.children() )
	{
		let edges = c.connectedEdges();
		for( let e of edges )
		{
			for( let n of e.connectedNodes() )
			{
				if( n.id() != c.id() ) n.hide();
			}
		}
	}
	target.addClass('minor');
	cy.endBatch();
};

fibers.mark_as_minor_group = function(show_grouped_links)
{
	cy.nodes('[cls="grp"] > [cls="frame"]').forEach(function( target )
	{
		fibers.mark_as_minor(target);
		let gl = target.incomers('[cls="grouped_links"]');
		show_grouped_links ? gl.show() : gl.hide();
	});
};

fibers.unminor_unit = function(target)
{
	target.removeClass('minor');
	for( let c of target.children() )
	{
		let edges = c.connectedEdges();
		for( let e of edges )
		{
			let n = e.connectedNodes();
			n.show();
			for( let e1 of n.connectedEdges() )
			{
			  e1.show();
			}
		}
	}
};

fibers.get_cookie = function(name)
{
  let matches = document.cookie.match(new RegExp(
    "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
  ));
  return matches ? decodeURIComponent(matches[1]) : undefined;
};

fibers.set_read_only = function(ro, as_click)
{
	if( fibers.forced_read_only )
	{
		fibers.read_only = true;
		$('#btn-read-only').html('Read <span class="blink">Only</span>').addClass('downed');
		setTimeout(function(){ $('#btn-read-only span').removeClass('blink') }, as_click ? 650 : 10);
	}
	 else
	{
		fibers.read_only = ro;
		$('#btn-read-only').text('RO').toggleClass('downed', ro);
		document.cookie = 'fibers-ro=' + (ro ? '1' : '') + '; path=/; expires=Tue, 19 Jan 2038 03:14:07 GMT; SameSite=Lax';
	}
	fibers.read_only ? cy.nodes().lock() : cy.nodes().unlock();
	$('.toggle-on-read-only').toggle(!ro);
	$('#history-buttons a').toggleClass('disabled', fibers.read_only);
};


fibers.check_read_only = function()
{
	fibers.set_read_only( fibers.get_cookie('fibers-ro') === '1', false )
};


fibers.center_scheme_to_unit = function(unit_id)
{
	let center_units = cy.$('[i=' + unit_id + ']');
	if( ! center_units.length ) return false;
	cy.center( center_units );
	if( fibers.center_timer_id ) {
		cy.nodes().removeClass('attention');
		clearTimeout(fibers.center_timer_id);
	}
	center_units.addClass('attention');
	fibers.center_timer_id = setTimeout(function(){ cy.nodes().removeClass('attention') }, 4000);
	return true;
};


fibers.show_all_callback = function(data)
{
	let timeInMs = Date.now();

	nody.modal_window.close();

	fibers.simplified_scheme = data.simplified_scheme;
	$('#btn-toggle-simplified').trigger('show-state');
	$('#btn-scheme-remove-container').toggle(!!data.full_access);
	$('#tags-filter-btn').toggleClass('active', Boolean(fibers.tag_filters.length)); //.toggleClass('disabled', fibers.simplified_scheme);
	$('#toggle-all-linked-schemes').toggle(!!data.has_linked_schemes);

	cy.startBatch();

	cy.elements().remove();

	if( data.bookmarks !== undefined ) $('#fibers__bookmarks_list').html('');

	if( data.error_message ) {
		api_base.modal_error(data.error_message);
	}

	fibers.trunks = data.trunks;
	fibers.ignore_units = data.ignore;
	fibers.hidden_units_ids = data.hidden_ids ? data.hidden_ids.map(x=>+x) : [];

	if( data.map_data !== undefined && !fibers.map_options.center ) fibers.map_options.center = data.map_data.center;
	if( data.stock_enabled !== undefined ) fibers.stock_enabled = data.stock_enabled;
	if( data.fibers_colors_presets !== undefined ) fibers.fibers_colors_presets = data.fibers_colors_presets;
	if( data.fibers_colors !== undefined ) fibers.fibers_colors = data.fibers_colors;
	if( data.templates !== undefined ) api_base.templates = data.templates;
	if( data.translate !== undefined ) api_base.translate = data.translate;
	if( data.settings !== undefined ) fibers.scheme_settings = data.settings;

	$('#main-panel .disabled-overlay').remove();
	cy.removeListener('data style', '[cls="fiber_tip"]');
	cy.on('data style', '[cls="fiber_tip"]', function(event)
	{
		let target = event.target;

		if( fibers.cur_event_eles.includes(target.id()) ) return;
		fibers.cur_event_eles.push(target.id());

		change_fiber_tip_event(target);

		fibers.cur_event_eles.pop();
	});


	if( !data.center_unit_id && data.zoom && data.pan_x && data.pan_y )
	{
		cy.viewport({
			zoom: parseFloat(data.zoom),
			pan: {x: parseFloat(data.pan_x), y: parseFloat(data.pan_y)}
		});
	}

	if( fibers.eh_enabled ) fibers.toggle_link_editing();

	let units = data.units;
	fibers.units_count = units.length;
	let elements = [];
	let uniq_grp = {};
	for( let param of units.values() )
	{
		let grp = param.grp;
		if( grp && !uniq_grp[grp] )
		{
			uniq_grp[grp] = 1;
			elements.push({
				data      : {
					id    : 'grp:' + param.grp,
					cls   : 'grp',
					label : 'Группа ' + param.grp,
					fixed : true
				},
				group     : 'nodes',
				selectable: false
			});
		}
	}

	if( elements ) cy.add(elements);

	elements = fibers.make_unit(units);

	if( ! fibers.is_infrastructure_view )
	{
		for( let param of data.links ) {
			elements = elements.concat(fibers.make_link(param));
		}
		if( !fibers.simplified_scheme ) {
			elements = elements.concat(fibers.make_grouped_links(data.links));
		}
	}

	cy.add(elements);

	for( let id of fibers.ignore_units.values() )
	{
		fibers.cy.getElementById(id).data('ignore', true);
	}

	cy.edges('[cls="grouped_links"]').hide();

	cy.endBatch();

	fibers.mark_as_minor_group(true);

	if( fibers.is_preview )
	{
		let iframe = $('#iframe_{{scheme}}', window.parent.document);
		let preview_side = iframe.width();
		let png64 = fibers.cy.png({
			full: true,
			maxWidth: preview_side,
			bg: '#ffffff'
		});
		let $img = $('<img>', {src: png64, class: 'collection_item_preveiw'});
		$('body').html($img);
		$img.on('load', function() {
			if( $img.height() > preview_side ) {
				$img.width((preview_side / $img.height()) * $img.width());
				$img.height(preview_side);
			}
			$('body').css({'opacity': 1, 'margin': 0, 'background-color': '#ffffff'});
			let iframe = $('#iframe_{{scheme}}', window.parent.document);
			$img.on('click', function() {
				iframe.trigger('click');
			});
		});
	}
	 else
	{
		fibers.forced_read_only = Boolean(fibers.simplified_scheme || fibers.show_all_linked_schemes || data.user.ro);
		fibers.check_read_only();
		cy.$('[fixed]').lock();

		if( data.bookmarks !== undefined )
		{
			for( let bookmark of Object.values(data.bookmarks) )
			{
				fibers.show_bookmark_link(bookmark);
			}
		}

		$('#show_all').css('display', data.path ? 'block' : 'none');
		fibers.data_path_is_active = Boolean(data.path);

		if( data.show_message )
		{
			nody.modal_window.content( data.show_message );
			nody.modal_window.show( -1, -1 );
		}

		if( data.center_unit_id )
		{
			fibers.center_scheme_to_unit(data.center_unit_id);
			fibers.fit_after_draw = false;
		}
		 else if( data.path )
		{
			let in_path = cy.$('.in_path');            
			cy.fit( in_path );
			const zoom = cy.zoom() * 0.8;
			cy.zoom( zoom > 1.2 ? 1.2 : zoom );
			cy.center( in_path );
			fibers.fit_after_draw = false;
		}

		if( fibers.fit_after_draw )
		{
			fibers.fit_after_draw = false;
			cy.fit();
			const zoom = cy.zoom();
			if( zoom > 1 ) {
				cy.zoom(1);
				cy.center();
			} else if( zoom < fibers.settings.min_auto_zoom ) {
				cy.zoom( fibers.settings.min_auto_zoom );
				cy.center();
			}
		}
	}

	if( data.select_units )
	{
		let id_map = {};
		for( el of fibers.cy.elements(':selectable') ) {
			const id_with_side = $.grep(el.id().split(':'), function(n, i) {return parseInt(n) >= 0});
			id_map[id_with_side.join(':')] = [ el ];
			id_map[id_with_side[0]] ||= [];
			id_map[id_with_side[0]].push(el);
		}
		for( const p of data.select_units ) {
			const els = id_map[p];
			if( els ) {
				for( const el of els ) el.select();
			}
		}
	}

	// console.log((Date.now() - timeInMs)/1000, 'elements:', elements.length);
};

fibers.nomap_callback = function(params)
{
	$.ajax({
		url     : nody.script_url,
		dataType: 'json',
		method  : 'post',
		data    : {
			a      : 'ajNoMapSesData',
			to_url : JSON.stringify({ filtr: 'link', link_type: 'from_ses'}),
			data   : JSON.stringify(params)
		},
		success : nody.ajax_response
	});
};

fibers.history_callback = function(data)
{
	if( !data.history.length && ! data.future.length ) {
		fibers.show_modal( $('<div>', {text: 'No history', class: 'error'}), {} );
		return;
	}
	let div = $('<div>', { html: api_base.template('history', { history: data.history, future: data.future }) });
	fibers.show_modal( div, {} );
};

fibers.show_waiting_sign = function()
{
	nody.modal_window.content( $('<div>', {class: ''}).append(nody.img_after_submit) );
	nody.modal_window.show( -1, -1 );
};

fibers.reload_new_scheme = function(data)
{
	let url = new URL(document.location);
	let p = url.searchParams;
	p.set('gid', data.gid);
	window.location.href = url.toString();
};

fibers.scheme_remove_callback = function(data)
{
	fibers.reload_new_scheme({gid: ''});
};

fibers.boundsOverlap = function(bb1, bb2)
{
	if( bb1.x1 > bb2.x2 ){ return false; }
	if( bb2.x1 > bb1.x2 ){ return false; }
	if( bb1.x2 < bb2.x1 ){ return false; }
	if( bb2.x2 < bb1.x1 ){ return false; }
	if( bb1.y2 < bb2.y1 ){ return false; }
	if( bb2.y2 < bb1.y1 ){ return false; }
	if( bb1.y1 > bb2.y2 ){ return false; }
	if( bb2.y1 > bb1.y2 ){ return false; }
	return true;
};


fibers.search_callback = function(data)
{
	if( ! data ) return nody.modal_window.close();
	let div = $('<div>', { html: api_base.template('search', { search: data }) });
	nody.modal_window.content( div );
	nody.modal_window.show( -1, -1 );
	fibers.add_listeners( div, {} );
};
