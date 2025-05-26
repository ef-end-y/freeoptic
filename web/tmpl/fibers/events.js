function click_debug(event, target)
{
	// console.log(target.data('cls'), target.classes());
	// console.log(target.css('z-index'), target.data('cls'));
	// console.log(event.position, { id: target.id(), cls: target.data('cls') });
	// console.log(target);
}

cy.on('position', 'node[type="fragment"]', function(event)
{
	let target = event.target;
	fibers.cy.elements('[fragment_link=' + target.data('i') + ']').position(target.position());
});

cy.on('add', '[type="link"],[cls="single_fiber"]', function(event)
{
	cy.startBatch();
	for( let n of event.target.connectedNodes() )
	{
		if( n.data('cls') == 'fiber_tip' ) {
			if( n.hasClass('hidden') ) {
				event.target.addClass('hidden');
			}
			event.target.data('color', n.data('color'));
		}
	}
	cy.endBatch();
});

change_fiber_tip_event = function(target)
{
	let connectedEdges = target.connectedEdges();
	let i = 0;
	let color, hide;
	let add_class = undefined;
	let remove_class = undefined;
	for( let e of connectedEdges )
	{
		if( !i++ )
		{
			color = target.data('color');
			hide = target.data('hide');
		}
		e.data('color', color);
		if( hide )
		{
			e.addClass('hidden');
		}
		 else if( !fibers.eh_enabled && connectedEdges.length < 2 )
		{
			add_class = 'unlinked';
			e.addClass('hidden');
		}
		 else
		{
			remove_class = 'hidden';
			e.removeClass('hidden');
		}
	}
	if( add_class ) target.addClass(add_class);
	if( remove_class ) {
		target.removeClass(remove_class);
		if( target.parent().hasClass('linked_scheme') ) target.parent().removeClass('linked_scheme');
	}
};

cy.on('click', '[cls="grp"]', function(event)
{
	fibers.mark_as_minor_group(false);
	let grp = event.target;
	for( let target of grp.children() )
	{
		fibers.unminor_unit(target);
	}
});


cy.on('click', '.minor', function(event)
{
	fibers.mark_as_minor_group(false);
	fibers.unminor_unit(event.target);
});


cy.on('click', '.minor > node', function(event)
{
	fibers.mark_as_minor_group(false);
	fibers.unminor_unit(event.target.parent());
});


cy.on('click cxttap', function(event)
{
	nody.click_pos = { x: event.originalEvent.pageX, y: event.originalEvent.pageY };
	fibers.click_pos = event.renderedPosition;
	let target = event.target;

	if( fibers.dblclick.click_task ) clearTimeout(fibers.dblclick.click_task);

	if( !fibers.cy.multiClickDebounceTime )
	{
		if( event.type == 'cxttap' ) return fibers.cy.trigger('dbl-click', event);


		if( fibers.dblclick.timeout && fibers.dblclick.tapped_before )
		{
			clearTimeout(fibers.dblclick.timeout);
		}
		if( fibers.dblclick.tapped_before === target )
		{
			cy.nodes('[action]').data('action', 'primary');
			fibers.cy.trigger('dbl-click', event);
			fibers.dblclick.tapped_before = null;
			return;
		}
		 else
		{
			fibers.dblclick.timeout = setTimeout(function(){ fibers.dblclick.tapped_before = null; }, 400);
			fibers.dblclick.tapped_before = target;
		}
	}

	let position_grid = fibers.position_grid;
	if( position_grid )
	{
		fibers.cy.nodes('[cls="position_grid"]').remove();
		fibers.position_grid = undefined;
	}

	if( target === fibers.cy )
	{
		cy.nodes('[action]').data('action', 'primary');
		cy.nodes('[cls="size_control"]').addClass('display_none');
		fibers.mark_as_minor_group(true);
		if( fibers.eh_enabled ) fibers.toggle_link_editing();
		return;
	}

	click_debug(event, target);

	let cls = target.data('cls');
	let type = cls + '.' + target.data('type');

	if( target.data('secondary_action') ) target.data('action', target.data('secondary_action'));

	if( cls == 'frame_inner' && fibers.position_grid_en )
	{
		let nodes = target.parent().children().sort(function( a, b ){
		    let p = a.position().y - b.position().y;
		    return p == 0 ? a.position().x - b.position().x : p;
		});

		let base_pos = nodes[0].position();
		let cur_pos = target.position();
		let dx = 30;
		let dy = 30;
		let dy2 = dy / 2;
		let x = Math.floor((cur_pos.x - base_pos.x)/dx + 0.5) * dx + base_pos.x;
		let y = Math.floor((cur_pos.y - base_pos.y)/dy2 + 0.5) * dy2 + base_pos.y;
		let elements = [];
		for (let j = -dy; j <= dy; j += dy2) {
			for (let i = -dx; i <= dx; i += dx) {
				if( Math.abs(j) == dy && Math.abs(i) == dx ) continue;
				elements.push({
					data : {
						cls : 'position_grid'
					},
					selectable: false,
					locked    : true,
					position  : {
						x : x + i,
						y : y + j,
					}
				});
			}
		}
		fibers.position_grid = target;
		fibers.cy.add(elements);
	}
	if( cls == 'position_grid' )
	{
		let pos = position_grid.position();
		api_base.ajax({
			act      : 'frame_inner_position',
			id       : position_grid.parent().data('i'),
			inner_id : position_grid.data('i'),
			x        : target.position().x - pos.x,
			y        : target.position().y - pos.y,
			ok_func  : 'fibers.replace_obj'
		});
	}
	if( cls == 'collapsed_cable' && target.data('linked_scheme') )
	{
		fibers.dblclick.click_task = setTimeout(function(){
			api_base.ajax({
				act : 'goto_linked_scheme',
				id : target.data('father'),
				ok_func : 'fibers.goto_linked_scheme_callback'
			});
		}, 400);
	}
});

if( fibers.scheme_gid && !fibers.is_preview ) {

cy.on('dblclick', function(event)
{
	fibers.cy.trigger('dbl-click', event);
});

cy.on('dbl-click', function(event0, event)
{
	let target = event.target;

	if( target === fibers.cy )
	{
		return fibers.main_menu({
			x : event.position.x,
			y : event.position.y
		});
	}

	if( fibers.simplified_scheme ) return;

	let cls = target.data('cls');
	let type = cls + '.' + target.data('type');
	let father = fibers.cy.getElementById(target.data('father'));

	if( type == 'frame_picture.cable' || cls == 'cable_end_joint_container' || cls == 'cable_end_joint' )
	{
		if( fibers.read_only ) return;
		let side = target.data('side');
		if( side === undefined ) side = target.data('joint_num') == 1 ? 0 : 1;
		return fibers.menu('cable_menu', {
			id     : father.data('i'),
			side   : side,
			joints : father.data('joints'),
			place_id : target.data('place_id'),
			map_place_id : target.data('map_place_id'),
			joint_num : side
		});
	}

	if( type == 'frame.container' )
	{
		let all_data = target.data('all_data');
		return fibers.menu('container_menu', {
			id : target.data('i'),
			lat : all_data.lat,
			lng : all_data.lng,
			has_parent : Boolean(target.data('parent')),
			is_infrastructure_view: fibers.is_infrastructure_view
		});
	}

	if( cls == 'frame' || cls == 'frame_picture' )
	{
		if( fibers.read_only ) return;
		let frame = cls == 'frame_picture' ? fibers.cy.getElementById(target.data('father')) : target;
		let min_x = frame.children('[cls="frame_inner"]').min(function(e){ return e.boundingBox().x1; });
		let min_y = frame.children('[cls="frame_inner"]').min(function(e){ return e.boundingBox().y1; });
		if( min_x.ele === undefined || min_y.ele === undefined ) return; // a frame without connectors
		let x, y;
		let xb = min_x.ele.boundingBox();
		let yb = min_y.ele.boundingBox();
		if( cls == 'frame' )
		{
			x = event.position.x - (xb.x1 + xb.x2)/2 + min_x.ele.data('inner_position').x;
			y = event.position.y - (yb.y1 + yb.y2)/2 + min_y.ele.data('inner_position').y;
		} else
		{
			x = min_x.ele.data('inner_position').x - 30;
			y = min_y.ele.data('inner_position').y;
		}
		let all_data = frame.data('all_data');
		return fibers.frame_menu({
			id : frame.data('i'),
			x  : x,
			y  : y,
			lat : all_data.lat,
			lng : all_data.lng,
			has_img : Boolean(frame.data('img')),
			has_parent : Boolean(frame.data('parent'))
		}, frame);
	}

	if( cls == 'collapsed_cable' )
	{
		let xy = [];
		for( let i in [0, 1] )
		{
			let b = target.connectedNodes()[i].boundingBox();
			xy.push({ x : (b.x2+b.x1)/2, y : (b.y2+b.y1)/2 });
		}
		let tangent = Math.abs((xy[0].x-xy[1].x)/((xy[0].y-xy[1].y)||0.001));
		return fibers.collapsed_cable_menu({
			id        : father.data('i'),
			joint_num : target.data('i'),
			trunk     : +target.data('trunk'),
			x         : event.position.x,
			y         : event.position.y,
			tangent   : tangent,
			linked_scheme: target.data('linked_scheme'),
			is_infrastructure_view: fibers.is_infrastructure_view
		});
	}

	if( cls == 'cable_joint_container' )
	{
		if( fibers.read_only ) return;
		return fibers.menu('cable_joint_menu', {
			id        : father.data('i'),
			joint_num : target.data('i'),
			place_id  : target.data('place_id')
		});
	}

	if( cls == 'link_joint' )
	{
		return fibers.menu('link_joint_menu', {
			id        : target.data('link_id'),
			joint_num : target.data('joint_num')
		});
	}

	if( cls == 'frame_inner' )
	{
		//if( fibers.show_all_linked_schemes ) return;
		let data = {
			id       : father.data('i'),
			inner_id : target.data('i'),
			can_create_pon : target.parent().data('type') !== 'onu'
		};
		for( let i of [ 'fibers_path_start', 'fibers_path_end' ] )
		{
			let path = sessionStorage.getItem(i);
			if ( path ) {
				data[i] = path.split(':')[0] == fibers.scheme_gid ? 'current' : 'other';
			}
		}
		return fibers.menu('frame_inner_menu', data);
	}

	if( type == 'link.link' )
	{
		if( fibers.read_only ) return;
		return fibers.menu('link_menu', {
			id : target.data('i'),
			x  : event.position.x,
			y  : event.position.y,
			joint_num : target.data('fragment')
		});
	}

	if( cls == 'fiber_tip' || cls == 'single_fiber' )
	{
		return fibers.cable_connector_menu({
			id       : father.data('i'),
			fiber_id : target.data('i')
		});
	}
});
}

cy.on('grabon select', function(event)
{
	if( event.originalEvent ) nody.click_pos = { x: event.originalEvent.pageX, y: event.originalEvent.pageY };

	if( fibers.simplified_scheme ) return;

	let target = event.target;
	let cls = target.data('cls');
	fibers.update_start_position(target);
	if( cls == 'frame' )
	{
		let frame_picture = fibers.cy.getElementById(target.data('tied_with'));
		fibers.update_start_position(frame_picture);
		frame_picture.addClass('hide_picture_when_frame_is_selected');
	}
	if( target.data('tied_with') )
	{
		let father = fibers.cy.getElementById(target.data('tied_with'));
		fibers.update_start_position(father);
	}
});

cy.on('unselect', function(event)
{
	fibers.cy.elements('[cls="frame_picture"]').removeClass('hide_picture_when_frame_is_selected');
});

cy.on('drag', function(event)
{
	let target = event.target;
	let action = target.data('action');
	if( action == 'primary' ) action = target.data('primary_action');

	if( action == 'slide' )
	{
		let slide_along_node = cy.getElementById(target.data('tied_with'));
		let pos = target.data('start_pos');
		target.position( slide_along_node.data('rotate') > 1
			? { x: target.position().x, y: pos.y }
			: { x: pos.x, y: target.position().y }
		);
		return;
	}
	if( action == 'move_with' )
	{
		let tied_node = fibers.cy.getElementById(target.data('tied_with'));
		if( tied_node )
		{
			let pos = tied_node.data('start_pos');
			if( pos )
			{
				let pos2 = target.data('start_pos');
				tied_node.position({x: target.position().x + pos.x - pos2.x, y: target.position().y + pos.y - pos2.y});
			}
		}
		if( target.data('type') == 'container' )
		{
			cy.startBatch();
			cy.nodes('[cls="fiber_tip"]').addClass('temporary_hidden');
			cy.edges('[cls="single_fiber"]').addClass('temporary_hidden');
			cy.edges('[cls="link"]').addClass('temporary_hidden');
			cy.nodes('[cls="cable_side_container"]').addClass('temporary_hidden');
			cy.endBatch();
			fibers.single_fibers_hidden = true;
		}
	}
	if( action == 'move_all' )
	{
		if( !fibers.single_fibers_hidden )
		{
			cy.nodes('[cls="fiber_tip"]').addClass('temporary_hidden');
			cy.edges('[cls="single_fiber"]').addClass('temporary_hidden');
		}
		let pos2 = target.data('start_pos');
		let c = target.children()[0];
		for( let j of [ c.successors(), c.predecessors() ] )
			for( let i of j )
			{
				let pos = i.data('start_pos');
				if( !pos || !fibers.single_fibers_hidden )
				{
					fibers.update_start_position(i);
				}
				 else
				{
					i.position({x: target.position().x + pos.x - pos2.x, y: target.position().y + pos.y - pos2.y});
				}
			}
		fibers.single_fibers_hidden = true;
	}
	if( action == 'move_side' )
	{
		if( !fibers.single_fibers_hidden )
		{
			cy.nodes('[cls="fiber_tip"]').addClass('temporary_hidden');
			cy.edges('[cls="single_fiber"]').addClass('temporary_hidden');
			single_fibers_hidden = true;
			// fibers.cy.nodes('[cls="cable_end_joint"]').hide();
		}
	}
});

cy.on('dragfree', function(event)
{
	let cy = fibers.cy;
	if( fibers.single_fibers_hidden )
	{
		cy.nodes().removeClass('temporary_hidden');
		cy.edges().removeClass('temporary_hidden');
		fibers.single_fibers_hidden = false;
	}

	let target = event.target;
	let start_pos = target.data('start_pos');
	let end_pos = target.position();
	let delta_x = end_pos.x - start_pos.x;
	let delta_y = end_pos.y - start_pos.y;
	let multimove = false;
	let multimove_data = [];
	let units = [ target ];
	if( target.selected() )
	{
		let selected = cy.$(':selected');
		if( !selected.length ) return; // selection bug?
		if( selected.length > 1 )
		{
			if( (event.timeStamp - fibers.last_multidrag) < 2000 ) return;
			fibers.last_multidrag = event.timeStamp;
			units = selected.toArray();
			multimove = true;
		}
	}
	 else if( target.data('type') === 'container' && target.isParent() )
	{
		units = target.children(
			'node[cls="frame"],' +
			'node[cls="cable_end_joint_container"],' +
			'node[cls="cable_joint_container"]'
		).toArray();

		var joint_ids = [];  // for uniq elements
		target.children('node[cls="frame"]')
			.children('node')
			.connectedEdges()
			.forEach( function(ele) {
				cy.elements('[id^="link:' + ele.data('i') +':joint:"]')
					.forEach( function(ele) {
						if( ! joint_ids.includes(ele.id()) ) { units.push(ele); joint_ids.push(ele.id()); }
					});
			});
		multimove = true;
	}

	units.map( function(target)
	{
		let cls = target.data('cls');
		let type = cls + '.' + target.data('type');
		let data = {
		    x : delta_x,
		    y : delta_y,
		    ok_func : 'fibers.replace_obj'
		};
		let moving_obj = undefined;

		let action = target.data('action');
		if( action == 'primary' || multimove ) action = target.data('primary_action');

		if( action == 'slide' )
		{
			let slide_along_node = cy.getElementById(target.data('tied_with'));
			let delta = data['y'] || data['x'];
			if( slide_along_node.data('rotate') % 3 == 1 ) delta *= -1;
			data = {
				id      : slide_along_node.data('i'),
				side    : slide_along_node.data('side'),
				delta   : delta,
				ok_func : 'fibers.replace_obj'
			};

			if( cls == 'fiber_tip' )
			{
				data.fiber_id = target.data('i');
				let pos = target.data('pos') + delta;
				if( pos > target.data('next_pos') || pos < target.data('prev_pos') )
				{
					target.position({x: pos.x, y: pos.y});
					return fibers.menu('fiber_tip_drag', data);
				}
				 else
				{
					data.act = 'cable_fibers_move';
				}
			}
			 else
			{
				data.act = 'cable_end_joint_slide';
			}
		}
		 else if( action == 'move_all' )
		{
			let tied_node = fibers.cy.getElementById(target.data('tied_with'));
			data['act'] = 'cable_move';
			data['id'] = tied_node.data('i');
		}
		 else if( action == 'move_side' )
		{
			let tied_node = fibers.cy.getElementById(target.data('tied_with'));
			data['act'] = 'cable_move';
			data['id'] = tied_node.data('i');
			data['side'] = target.data('i') == 2 ? 0 : 1;
		}
		 else if( cls == 'size_control' )
		{
			data['act'] = 'frame_size';
			data['id'] = target.parent().data('i');
		}
		 else if( cls == 'cable_end_joint_container' )
		{
			let tied_node = cy.getElementById(target.data('tied_with'));
			for( let fragment of cy.nodes('[type="fragment"]') )
			{
				let pos1 = fragment.position();
				let pos2 = target.position();
				if( Math.sqrt(((pos1.x - pos2.x) ** 2) + ((pos1.y - pos2.y) ** 2)) < 20 )
				{
					return api_base.ajax({
						act      : 'fragment_link_create',
						fragment : fragment.data('i'),
						cable    : tied_node.data('i'),
						side     : tied_node.data('side'),
						ok_func  : 'fibers.show_all_callback'
					});
				}
			}
			data['act'] = 'cable_joint_position';
			data['id'] = tied_node.data('i');
			data['joint_num'] = tied_node.data('side');
			moving_obj = target;
		}
		 else if( cls == 'cable_joint_container' )
		{
			data['act'] = 'cable_joint_position';
			data['id'] = cy.getElementById(target.data('father')).data('i');
			data['joint_num'] = target.data('joint_num');
			moving_obj = target;
		}
		 else if( cls == 'link_joint' )
		{
			data['act'] = 'link_joint_position';
			data['id'] = target.data('link_id');
			data['joint_num'] = target.data('joint_num');
			data['ok_func'] = 'fibers.link_replace_callback';
		}
		 else if( cls == 'frame' )
		{
			data['act'] = 'frame_position';
			data['id'] = target.data('i');
			moving_obj = target;
		}
		 else if( cls == 'frame_picture' )
		{
			let father = cy.getElementById(target.data('father'));
			fibers.update_center_info(father);
			data['act'] = 'frame_position';
			data['id'] = father.data('i');
			moving_obj = father;
		}
		 else if( cls == 'frame_inner' )
		{
			data['act'] = 'frame_inner_position';
			data['id'] = target.parent().data('i');
			data['inner_id'] = target.data('i');
			moving_obj = target.parent();
		}
		 else
		{
			return;
		}

		if( multimove )
		{
			delete data.ok_func;
			multimove_data.push(data);
		}
		 else
		{
			// console.log('single act: ' + data.act);
			api_base.ajax(data);
		}

		if( moving_obj && moving_obj.data('type') !== 'container' )
		{
			let bb_u1 = moving_obj.boundingBox();
			let bb_u2;
			let m_cls = moving_obj.data('cls');
			let m_place_id = moving_obj.data('place_id');
			if( (m_cls == 'frame' || m_cls == 'frame_picture') && moving_obj.data('tied_with') )
			{
				bb_u2 = cy.getElementById(moving_obj.data('tied_with')).boundingBox();
			}
			let check_bounds = fibers.boundsOverlap;
			cy.nodes('[type="container"]').forEach( function(container)
			{
				if( !bb_u1 ) return;
				// if( container === moving_obj ) return;
				let place_id = container.data('i');
				if( m_place_id == place_id ) return;
				let bb_container = container.boundingBox();
				if( check_bounds(bb_container, bb_u1) || (bb_u2 && check_bounds(bb_container, bb_u2)) )
				{
					// because of parallel xxx_position ajax can finish after move_into_container ajax
					// we get "object is not in container yet" after "object is in container"
					// so send move_into_container ajax some later
					setTimeout(function(){
						api_base.ajax({
							act       : 'move_into_container',
							id        : data.id,
							joint_num : data.joint_num,
							place_id  : place_id,
							ok_func   : 'fibers.container_callback'
						});
						bb_u1 = undefined;
					}, 300);
				}
			});
		}
	});

	if( multimove_data.length )
	{
		fibers.show_waiting_sign();
		console.log('multimove');
		let data = {
			act : 'multimove',
			data : JSON.stringify(multimove_data),
			ok_func : 'fibers.show_all_callback'
		};
		api_base.ajax(data);
	}
});


cy.on('select', '[cls="frame_inner"]', function(event)
{
	fibers.cy.elements('[cls="frame"]').unselect();
});


cy.on('zoom pan', function(event)
{
	if( !fibers.scheme_gid ) return;

	const zoom = Math.round(cy.zoom()*1000)/1000;

	if( fibers.browser_history_task ) clearTimeout(fibers.browser_history_task);
	fibers.browser_history_task = setTimeout( function(){
		let url = new URL(document.location);
		let p = url.searchParams;
		p.set('zoom', zoom);
		p.set('x', Math.round(cy.pan().x));
		p.set('y', Math.round(cy.pan().y));
		history.replaceState({}, '', url.toString());
		fibers.browser_history_task = undefined;
	}, 100);

	if( fibers.show_path_mode ) return;
	if( fibers.fix_simplified_scheme && zoom < 0.6 ) return;

	let simple = fibers.simplified_scheme;
	let area = fibers.area;
	const vp = fibers.cy.viewport().extent();
	let reload_data = vp.x1 < area.x1 || vp.x2 > area.x2 || vp.y1 < area.y1 || vp.y2 > area.y2;

	const units_count = Math.min(+fibers.units_count || 1000, 1000);
	const change_scheme_detalization_zoom = fibers.settings.change_scheme_detalization_zoom * (0.35 + units_count * 0.65/1000);
	const detalization = zoom > change_scheme_detalization_zoom;
	
	if( (event.type == 'zoom') && (detalization && simple) || (!detalization && !simple) )
	{
		fibers.simplified_scheme = simple = !simple;
		$('#btn-toggle-simplified').trigger('show-state');
		reload_data = true;
	}

	if( reload_data )
	{
		console.log('zoom/pan: reload the scheme');
		fibers.set_pan_area_box(zoom);
		fibers.get_all_now();
	}
});
