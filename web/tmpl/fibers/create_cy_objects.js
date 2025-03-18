fibers.make_unit = function(data, do_replace=false)
{
	if( !Array.isArray(data) ) data = [ data ];
	let same_tied = {};

	for( let d of data )
	{
		d.id = +d.id;
		let t = d.tied = +d.tied;
		if( !t || d.type === 'none' ) continue;
		if( !same_tied[t] ) same_tied[t] = [];
		same_tied[t].push(d.id);
	}

	// multimode cables have same 'tied' value. Mark all cables part_id = index of sorted ids
	for( let v of Object.values(same_tied) ) v.sort((a,b)=>a-b);
	let elements = [];
	for( let d of data.sort((a,b)=>a.id-b.id) )
	{
	d.part_id = same_tied[d.tied] && same_tied[d.tied].length > 1 ? same_tied[d.tied].indexOf(d.id) + 1 : 0;
	elements = elements.concat(fibers._make_unit(d, do_replace));
	}
	return elements;
	}

fibers._make_unit = function(data, do_replace)
{
	if( !data ) return [];
	let container_i = data.id;
	let is_infrastructure_view = fibers.is_infrastructure_view;
	let simplified_scheme = fibers.simplified_scheme;
	let elements = [];
	let cls = data.cls;
	let container_id = container_i;
	let unit_id = container_i;
	let x = +data.x;
	let y = +data.y;
	let inner_units = data.inner_units;
	let add_data = data.add_data;
	let place_id = data.place_id > 0 ? +data.place_id : 0;
	let classes = data.mute ? 'mute' : '';
	if( data.warning ) classes += ' warning';

	let subtype = add_data ? (add_data.subtype || '') : '';
	if( !is_infrastructure_view && subtype === 'only_map' ) return [];

	let def_params = {
		group     : 'nodes',
		removed   : false,
		selected  : false,
		selectable: false,
		locked    : false,
		grabbable : true,
		pannable  : false
	};

	if( simplified_scheme ) {
		def_params.locked = true;
		def_params.grabbable = false;
	}

	let join_params = function(params)
	{
		return Object.assign({}, def_params, params);
	}

	if( data.type == 'none' )
	{
		// do not show
	}
	 else if( cls == 'cable' )
	{
		if( do_replace )
		{
			if( data.part_id < 2 ) fibers.cy.remove(fibers.cy.elements('[id^="cable:' + data.tied + ':"]'));
			fibers.cy.remove(fibers.cy.elements('[id^="' + unit_id + ':cable:"]'));
			fibers.cy.remove(fibers.cy.elements('[id^="' + unit_id + ':fiber:"]'));
		}

		// A and B side positions
		let xa = x + +data.xa;
		let ya = y + +data.ya;
		let xb = +data.x0 + +data.xb;
		let yb = +data.y0 + +data.yb;

		let inner_units_values = simplified_scheme ? [] : Object.values(inner_units);
		if( simplified_scheme ) classes += ' simplified';

		let left_rotate  = +add_data.rotate[0];
		let right_rotate = +add_data.rotate[1];

		let father_container_id;
		let side_containers = []; // Left and right containers with fibers
		let side_joints = [];

		let sides = [{
			side : 0,
			x    : xa,
			y    : ya,
			place_id : add_data.places ? +add_data.places[0] : 0
		},{
			side : 1,
			x    : xb,
			y    : yb,
			place_id : add_data.places ? +add_data.places[1] : 0
		}];
		for( let i of sides )
		{
			let side = i.side;
			let rotate = +add_data.rotate[side];
			let side_container_id = container_id + ':' + side;
			if( !father_container_id ) father_container_id = side_container_id;
			let container = join_params({
				data: {
					cls     : 'cable_side_container',
					i       : container_i,
					id      : side_container_id,
					father  : father_container_id,
					side    : side,
					rotate  : rotate,
					joints  : data.joints.length
				}
			});
			container.classes = classes;
			if( add_data.linked_scheme ) container.classes += ' linked_scheme';
			if( is_infrastructure_view ) container.classes += ' hidden';
			side_containers.push(container);

			let d0 = 0; // 40
			let d1 = 0;
			if( add_data.collapsed_coord && add_data.collapsed_coord[side] ) d1 += +add_data.collapsed_coord[side];
			let change_position = [
				[ d0, d1],
				[-d0, d1],
				[ d1, d0],
				[ d1,-d0]
			];

			side_joints.push({
				id        : container_id + ':cable:edge:' + i.side,
				x         : i.x + change_position[rotate][0],
				y         : i.y + change_position[rotate][1],
				is_edge   : true,
				tied_with : side_container_id,
				rotate    : rotate,
				name      : data.part_id || '',
				place_id  : i.place_id
			});
		}

		let joints = [];

		joints.push(side_joints[0]);
		joints = joints.concat(data.joints);
		joints.push(side_joints[1]);

		if( !do_replace )
		{
			elements.push(side_containers[0]);
			elements.push(side_containers[1]);
		}

		/*
			Collapsed fragments of a cable
		*/

		let joints_x = []; // X distances between joints. Labels will be shown only on long cable fragments
		let last_x = +joints[0].x;
		for( let j of joints )
		{
			j.x = +j.x;
			j.y = +j.y;
			joints_x.push(Math.abs(j.x-last_x));
			last_x = j.x;
		}
		let first_id = undefined;
		let last_id = undefined;
		let prev_id = undefined;
		let i = 0;
		let pre_last_i = joints.length - 1;
		let min_distance_for_labels = Math.min(Math.max(...joints_x), 200);
		for( let joint of joints )
		{
			i++;
			let id_prefix = 'cable:' + data.tied + ':' + i;
			let joint_id = joint.id || id_prefix;
			let joint_container_id = joint_id + ':container';

			if( data.part_id < 2 || joint.is_edge ) 
			{
				let is_path_joint = !joint.is_edge && (data.part_id < 1 || (i>2 && i<pre_last_i));
				let secondary_action = joint.is_edge ? 'slide' : (is_path_joint ? 'move_all' : 'move_side');
				let place_id = +(joint.place_id || 0);
				if( is_path_joint )
				{
					if( is_infrastructure_view && (!joint.subtype || joint.subtype !== 'only_map') ) continue;
					if( !is_infrastructure_view && joint.subtype && joint.subtype === 'only_map' ) continue;
				}
				let place_parent = place_id ? place_id + ':0' : undefined;
				let joint_classes = classes;
				if( fibers.tx_rx_mode ) joint_classes += ' mute_border';
				if( !simplified_scheme )
				{
					let joint_container_data = {
						cls       : joint.is_edge ? 'cable_end_joint_container' : 'cable_joint_container',
						i         : i,
						id        : joint_container_id,
						father    : father_container_id,
						parent    : place_parent,
						joint_num : i,
						tied_with : joint.tied_with || father_container_id,
						place_id  : place_id,
						label     : joint.name,
						action    : 'primary',
						primary_action   : joint.is_edge ? 'move_with' : undefined,
						secondary_action : secondary_action,
						fragment_link    : joint.fragment_link
					};
					if( joint.is_edge && add_data.linked_scheme ) joint_container_data['linked_scheme'] = add_data.linked_scheme;
					elements.push(join_params({
						data : joint_container_data,
						selectable : true,
						classes : joint_classes
					}));
				}

				elements.push(join_params({
					data : {
					    cls     : joint.is_edge ? 'cable_end_joint' : 'cable_joint',
					    i       : i,
					    id      : joint_id,
					    parent  : simplified_scheme ? place_parent : joint_container_id,
					    father  : father_container_id,
					    joint_num : i,
					    tied_with : joint.tied_with || father_container_id
					},
					position  : {
					    x : joint.x,
					    y : joint.y
					},
					classes : classes
				}));
			}

			if( last_id && (data.part_id < 2 || joint.is_edge || i == 2) ) 
			{
				let cable_classes = classes;
				let cable_data = {
					i      : i-1,
					father : father_container_id,
					source : joint_id,
					target : prev_id,
					cls    : 'collapsed_cable'
				};
				if( simplified_scheme )
				{
				}
				 else if( joints_x[i-1] >= min_distance_for_labels )
				{
					let label = +data.length || '';
					if( data.name ) label = data.name + (label ? ': ' + label : '');
					cable_data.label = label;
				}
				
				if( data.in_path ) {
					cable_classes += ' in_path';
				} else if( fibers.tx_rx_mode ) {
					cable_classes += ' mute';
				}
				if( +data.trunk ) cable_data.trunk = +data.trunk;
				if( (joint.is_edge || i == 2) && add_data.linked_scheme ) cable_data.linked_scheme = add_data.linked_scheme;
				elements.push({
					data      : cable_data,
					group     : 'edges',
					selectable: false,
					classes   : cable_classes
				});
			}

			if( !last_id ) first_id = joint_container_id;
			last_id = joint_container_id;
			prev_id = joint_id;
		}

		if( is_infrastructure_view ) return elements;
		/*
		    Fibers of a cable
		*/

		function fibers_sort(side)
		{
		    return function(a, b)
		    {
		        let order_a = a.offset === undefined ? a.i : a.offset[side];
		        let order_b = b.offset === undefined ? b.i : b.offset[side];
		        if( +order_a < +order_b ) return -1;
		        if( +order_a > +order_b ) return 1;
		        return 0;
		    }
		}

		sides[0].connect_with = first_id;
		sides[1].connect_with = last_id;

		let xi = x;
		let yi = y;
		let links = [];
		let any_mute = inner_units_values.some((param) => param.mute);
		for( let p of sides )
		{
			let fragment_link = +side_joints[p.side].fragment_link;

			let rotate = +add_data.rotate[p.side];
			let prev_pos= -100;
			let prev_fiber_tip = undefined;
			let parent_id = container_id + ':' + p.side;

			if( !fragment_link )
			{
				let bone_fiber_tip = join_params({
				    data : {
				        cls    : 'bone_fiber_tip',
				        id     : parent_id + ':bone',
				        parent : parent_id
				    },
				    position : {
				        x : side_joints[p.side].x,
				        y : side_joints[p.side].y
				    }
				});
				elements.push(bone_fiber_tip);
			}

			for( let param of inner_units_values.sort(fibers_sort(p.side)) )
			{
				let offset = param.offset ? +param.offset[p.side] : (+param.i) * fibers.settings.fiber_connector_distance;
				let pos = (rotate % 2 == 0 ? offset : -offset);
				let tip_id = parent_id + ':' + param.i;
				let xx = p.x + (!fragment_link && rotate > 1 ? pos : 0);
				let yy = p.y + (fragment_link || rotate > 1 ? 0 : pos);

				let color, color_obj;
				if( fibers.tx_rx_mode || fibers.show_fibers_desc ) {
					color = '#c0c0c0';
				} else {
					color_obj = fibers.fibers_colors[param.color];
					color = color_obj ? color_obj.color : '#505050';
				}
				let classes = (fragment_link || param.mute ? 'mute' : '');

				let fiber_tip = join_params({
					data : {
						cls       : 'fiber_tip',
						i         : param.i,
						id        : tip_id,
						parent    : parent_id,
						father    : father_container_id,
						color     : color,
						label     : (fibers.show_fibers_desc && color_obj ? color_obj.description : ''),
						pos       : pos,
						prev_pos  : prev_pos,
						next_pos  : pos + 100,
						tied_with : parent_id,
						action    : 'primary',
						primary_action : 'slide',
						fragment_link  : fragment_link
					},
					position : {
						x : xx,
						y : yy,
					},
					grabbable : true,
					selectable: false,
					classes   : classes
				});
				elements.push(fiber_tip);

				//if( fragment_link ) continue;

				let d = {
					data      : {
						cls    : 'single_fiber',
						i      : param.i,
						id     : unit_id +':fiber:' + p.side + ':' + param.i,
						source : tip_id,
						target : p.connect_with,
						father : father_container_id
					},
					group     : 'edges',
					selectable: false,
					classes   : classes
				};

				let need_splice = (rotate < 2 && yy > side_joints[p.side].y) ||
				                  (rotate > 1 && xx > side_joints[p.side].x)  ;
				if( rotate % 2 != 0 ) need_splice = ! need_splice;
				if( any_mute ? param.mute : need_splice ) links.splice(0, 0, d); else links.push(d);

				if( prev_fiber_tip ) prev_fiber_tip.data.next_pos = pos;
				prev_pos = pos;
				prev_fiber_tip = fiber_tip;
			}
			let j = 0;
			for( let param of Object.values(links) )
			{
			    param.data.zIndex = 2000 + j;
			    elements.push(param);
			    j++;
			}
		}

	}
	 else if( data.type == 'fragment' )
	{
	}
	 else if( data.type == 'container' )
	{
		if( is_infrastructure_view && data.add_data.layers == 'scheme' ) return [];
		if( !is_infrastructure_view && data.add_data.layers == 'infrastructure' ) return [];
		let container_classes = '';
		if( simplified_scheme ) container_classes += ' simplified';
		container_id = container_id + ':0';
		elements.push(join_params({
			data : {
				i     : container_i,
				id    : container_id,
				type  : data.type,
				label : data.name + '',
				cls   : cls,
				all_data : data,
				fragment : data.add_data.fragment,
				action   : 'primary',
				primary_action : 'move_with'
			},
			selectable: false,
			position  : {
				x : x,
				y : y,
			},
			classes : container_classes
		}));
	}
	 else if( is_infrastructure_view )
	{
	}
	 else
	{
		// Frame
		let is_hidden_frame = fibers.hidden_units_ids.includes(container_i);
		container_id = container_id + ':0';
		let picture_id = container_id + ':frame_picture';
		let place_parent = place_id ? place_id + ':0' : undefined;
		let frame_classes = classes;
		if( fibers.show_description ) frame_classes += ' small-font';
		let grp = data.grp;
		if( grp )
		{
			place_parent = 'grp:' + grp;
		}

		if( simplified_scheme ) frame_classes += ' simplified';
		if( data.in_path ) {
			frame_classes += ' in_path';
		} else if( fibers.tx_rx_mode ) {
			frame_classes += ' mute_border';
		}

		let inner_units_values = Object.values(inner_units);
		let xs = inner_units_values.map(function( param ) { return parseFloat(param.x); });
		let x_min = Math.min(...xs);
		let x_max = Math.max(...xs);
		let x_center = (x_min + Math.max(...xs))/2;
		let ys = inner_units_values.map(function( param ) { return parseFloat(param.y); });
		let y_min = Math.min(...ys);
		let y_max = Math.max(...ys);

		let frame_data = {
			i         : container_i,
			id        : container_id,
			type      : data.type,
			name      : data.name,
			cls       : cls,
			img       : data.img,
			all_data  : data,
			tied_with : picture_id,
			parent    : place_parent,
			place_id  : place_id,
			action    : 'primary',
			primary_action : 'move_with'
		};

		if( +data.width > 0 && +data.height> 0 ) {
		    frame_data.set_width = +data.width;
		    frame_data.set_height = +data.height;
		    //x += 50;
		}

		elements.push(join_params({
		    data      : frame_data,
		    selectable: true,
		    classes   : frame_classes,
		    position  : {
		        x : x + x_min,
		        y : y + y_min
		    }
		}));

		elements.push(join_params({
			data : {
				id     : container_id + ':size_control',
				parent : container_id,
				father : container_id,
				cls    : 'size_control'
			},
			position : {
				x : x + x_max,
				y : y + y_max
			},
			classes : 'display_none'
		}));

		if( !grp && !is_hidden_frame && !simplified_scheme )
		{
			let pic_margin = fibers.settings.frame_pictures[data.type];
			pic_margin = pic_margin ? pic_margin.margin : 0;
			elements.push(join_params({
				data : {
					id        : picture_id,
					father    : container_id,
					cls       : 'frame_picture',
					type      : data.type,
					label     : data.name,
					parent    : place_parent,
					tied_with : container_id,
					action    : 'primary',
					primary_action : 'move_with'
				},
				position : {
					x : x + x_center,
					y : y + y_min - pic_margin
				},
				classes : classes
			}));
		}

		if( simplified_scheme ) inner_units_values = [];
		let splitter_links = [];
		let zero_splitter_exists = false;
		for( let param of inner_units_values )
		{
			if( param.i == 0 ) zero_splitter_exists = true;
			let inner_position = {
				x : parseFloat(param.x),
				y : parseFloat(param.y)
			};
			// protection
			if( Math.abs(inner_position.x) > 2000 ) inner_position.x = 2000;
			if( Math.abs(inner_position.y) > 2000 ) inner_position.y = 2000;

			let el_data = {
				i      : param.i,
				id     : container_id + ':' + param.i,
				parent : container_id,
				father : container_id,
				cls    : 'frame_inner',
				type   : param.type,
				inner_position : inner_position
			};

			let label = !fibers.scheme_gid ? undefined : (
			    fibers.tx_rx_mode === 'DESCR' ? param.remote_id :
			    (fibers.show_description ? param.description : (param.type == 'solder' ? undefined : param.name))
			);
			const label_len = (label || '').length;
			el_data.label = label;
			let frame_inner_classes = (classes == 'mute' || !param.mute ? '' : 'mute');
			if( fibers.tx_rx_mode ) {
				frame_inner_classes = label_len ? 'accent' : 'mute';
			} else if( label_len > 2 ) {
				frame_inner_classes += ' small-font';
			}

			elements.push(join_params({
				data : el_data,
				position : {
					x : x + inner_position.x,
					y : y + inner_position.y
				},
				classes : frame_inner_classes
			}));

			if( param.type == 'splitter' && param.i > 0 )
			{
				splitter_links.push({
					data : {
						id     : container_id + ':link:' + param.i,
						source : container_id + ':0',
						target : container_id + ':' + param.i,
						cls    : 'splitter_connection',
						type   : 'splitter_connection',
					},
					group      : 'edges',
					selectable : false,
					classes    : (!param.mute ? '' : 'mute')
				});
			}
		}
		if( do_replace ) fibers.cy.remove(fibers.cy.elements('[id^="' + container_id + ':link:"]'));
		if( zero_splitter_exists ) elements = elements.concat(splitter_links);
	}
	// console.log(elements);
	return elements;
}

fibers.make_link = function(data)
{
    let elements = [];
    let fragments = [];
    let joint_num = 0;
    let id = data.id;
    for( let joint of data.joints )
    {
        let joint_id = 'link:' + id + ':joint:' + joint_num;
        elements.push({
            data : {
                cls   : 'link_joint',
                id    : joint_id,
                link_id : id,
                joint_num : joint_num
            },
            position : {
                x : +joint.x,
                y : +joint.y
            }
        });
        fragments.push(joint_id);
        joint_num++;
    }
    let src = '' + data.src + ':' + data.src_side + (data.src_inner === undefined ? '' : ':' + data.src_inner);
    let dst = '' + data.dst + ':' + data.dst_side + (data.dst_inner === undefined ? '' : ':' + data.dst_inner);
    fragments.push(dst);
    let fragment_num = 0;
    const color_obj = fibers.fibers_colors[data.color];
    const color = color_obj ? color_obj.color : '#a0a0a0';
    for( let dst of fragments )
    {
        let link_classes = data.mute ? 'mute' : '';
        if( fibers.simplified_scheme ) link_classes += ' simplified';
        elements.push({
            data : {
                i      : data.id,
                id     : 'link:' + id + ':fragment:' + fragment_num,
                source : src,
                target : dst,
                cls    : 'link',
                type   : 'link',
                color  : color,
                fragment : fragment_num
            },
            group      : 'edges',
            selectable : false,
            classes    : link_classes
        });
        src = dst;
        fragment_num++;
    }
    return elements;
}

fibers.make_grouped_links = function(links_params)
{
    let elements = [];
    let already = {};
    for( let data of links_params )
    {
        let src = data.src + ':' + data.src_side;
        let dst = data.dst + ':' + data.dst_side;
        if( already[src + '+' + dst] || already[dst + '+' + src] ) continue;
        already[src + '+' + dst] = 1;
        elements.push({
            data : {
                id     : 'grouped_links:' + data.id,
                source : src,
                target : dst,
                cls    : 'grouped_links'
            },
            group      : 'edges',
            selectable : false,
            classes    : data.mute ? 'mute' : '',
            locked     : true
        });
    }
    return elements;
}

