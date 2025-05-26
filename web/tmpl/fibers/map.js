fibers.map_state = {
  zoom: 16,
  show_cable_length: false,
  objects: {
      marker: null,
      markers: [],
      line_markers: [],
      lines: []
  }
};

fibers.correct_viewport = function()
{
  let zoom = fibers.map_options.zoom = fibers.map.getZoom();
  fibers.map_state.zoom = zoom;
  let k = Math.max(0, 1 - (16 - zoom) * 0.25);
  let circle_k = Math.max(0.1, Math.pow((22 - zoom) * 0.4, 2.4) / 9);
  for( let object of fibers.map_state.objects.markers )
  {
      if( object.is_circle )
      {
          object.marker.setRadius(object.hide_on_zoom && zoom < 16 ? 0 : circle_k * object.size);
          continue;
      }
      let label = object.marker.getLabel();
      if( object.hide_on_zoom && zoom < 16 )
      {
          label.text = ' ';
      } else {
          let size = k * object.size;
          label.fontSize = size + 'px';
          label.text = object.text;
      }
      object.marker.setLabel(label);
  }
};

fibers.map_create = function(message)
{
  $('#map_action_title').text(message || '');
  if( fibers.map )
  {
      google.maps.event.clearListeners(fibers.map, 'click');
      google.maps.event.clearListeners(fibers.map, 'dragend');
      let objects = fibers.map_state.objects;
      while( objects.markers.length > 0 ) objects.markers.pop().marker.setMap(null);
      while( objects.line_markers.length > 0 ) objects.line_markers.pop().setMap(null);
      while( objects.lines.length > 0 ) objects.lines.pop().setMap(null);
      if( objects.marker ) {
          objects.marker.setMap(null);
          objects.marker = null;
      }
      return;
  }
  fibers.map = new google.maps.Map(document.getElementById('gmap'), fibers.map_options);
  if( fibers.map_options.zoom ) fibers.map.setZoom(fibers.map_options.zoom);
  fibers.map.addListener('center_changed', function()
  {
      fibers.map_options.center = fibers.map.center;
      fibers.map_options.zoom = fibers.map.getZoom();
  });
  fibers.map.addListener('bounds_changed', function()
  {
      if( fibers.map_state.zoom != fibers.map.getZoom() ) fibers.correct_viewport();
  });
};


fibers.map_unit_position = function(id, lat, lng)
{
  if( lat && lng )
  {
      let position = fibers.map_options.center = { lat: lat, lng: lng };
      fibers.map_options.zoom = 16;
      fibers.map_get_all_now();
      fibers.map_state.objects.marker = new google.maps.Marker({position: position, map: fibers.map});
  }
   else
  {
      fibers.map_get_all_now(api_base.translate['Click on the map where you want to place the object']);
      fibers.map.addListener('click', function(e) {
          let lat_lng = e.latLng;
          let lat = lat_lng.lat();
          let lng = lat_lng.lng();
          // fibers.map_create();
          api_base.ajax({
              act : 'map_unit_position',
              id  : id,
              lat : lat,
              lng : lng,
              ok_func: 'fibers.map_unit_position_callback'
          });
      });
  }
};


fibers.map_center = function()
{
  fibers.map_create(api_base.translate['Click on the map to set its center']);
  fibers.map.addListener('click', function(e)
  {
      const lat_lng = e.latLng;
      const lat = lat_lng.lat();
      const lng = lat_lng.lng();
      api_base.ajax({
          act : 'map_position',
          lat : lat,
          lng : lng
      });
      fibers.map_options.center = { lat: lat, lng: lng };
      fibers.set_map_view(false);
  });
};


fibers.map_get_all_now = function(message)
{
  fibers.map_create(message);
  api_base.ajax({
      act     : 'map_get_all',
      ok_func : 'fibers.map_all_callback'
  });
};


fibers._map_cables = function(units, places, polylines)
{
  let lines = fibers.map_state.objects.lines;
  for( let param of units.values() )
  {
      if( param.cls != 'cable' ) continue;

      const cable_type_params = fibers.map_data.cable_types[+param.map_type];
      const color = cable_type_params ? '#' + cable_type_params.color : '#ff0000';
      const line_width = cable_type_params ? +cable_type_params.line_width : 2;

      let joints = [];
      const add_data = param.add_data;
      const place_ids = add_data.places || [0, 0];
      if( places[+place_ids[0]] ) joints.push(places[+place_ids[0]]);
      for( let joint of param.joints )
      {
          let place_id = +joint.place_id;
          if( place_id > 0 && places[place_id] ) joints.push(places[place_id]);
      }
      if( places[+place_ids[1]] ) joints.push(places[+place_ids[1]]);
      let path = [];
      let last_point = undefined;
      for( let j of joints )
      {
          const point = { lat: j.lat, lng: j.lng };
          path.push(point);
          if( fibers.map_state.show_cable_length && last_point )
          {
              const distance = google.maps.geometry.spherical.computeDistanceBetween(point, last_point);
              fibers.map_state.objects.line_markers.push(new google.maps.Marker({
                  position: { lat: (point.lat + last_point.lat)/2, lng: (point.lng + last_point.lng)/2},
                  map: fibers.map,
                  label: '' + Math.floor(distance),
                  icon: {
                      path: google.maps.SymbolPath.CIRCLE,
                      fillColor: '#ffffff',
                      fillOpacity: 1,
                      strokeColor: '#ffffff',
                      scale: 9
                  },
              }));
          }
          last_point = point;
      }
      const polyline = new google.maps.Polyline({
          path: path,
          geodesic: true,
          strokeColor: color,
          strokeOpacity: 1.0,
          strokeWeight: line_width
      });

      polyline.setMap(fibers.map);
      lines.push(polyline);
  }

  cy.nodes().removeClass('has_gps');
  for( let param of units.values() )
  {
      if( param.cls !== 'frame' || param.type !== 'container' || !(param.lat || param.lng) ) continue;
      cy.getElementById(param.id + ':0').addClass('has_gps');
  }

  fibers.correct_viewport();
};


fibers.map_all_callback = function(data)
{
  nody.modal_window.close();

  let map = fibers.map;
  let units = data.units;
  fibers.map_data = data.map_data;

  let places_with_units = {};
  for( let param of units )
  {
      let id = +param.place_id;
      if( id > 0 ) places_with_units[id] = 1;
  }

  let places = {};
  let polylines = [];
  let unit;
  for( let param of units )
  {
      if( !param.lat && !param.lng ) continue;
      let id = +param.id;
      places[id] = param;
      let position = { lat: param.lat, lng: param.lng };
      let has_units = Boolean(places_with_units[id]);

      let container_params = fibers.map_data.container_types[+param.map_type];
      let color = container_params ? '#' + container_params.color : '#ff0000';
      let size = container_params ? container_params.size : 12;
      let label_text = container_params ? String.fromCharCode('0x' + container_params.shape) : '\uf111';

      let is_circle = Boolean(label_text === '\uf111');
      if( is_circle )
      {
          size *= 0.7;
          unit = new google.maps.Circle({
              strokeOpacity: 0,
              fillColor: color,
              fillOpacity: 1,
              map,
              center: position,
              radius: size,
              draggable: !fibers.show_all_linked_schemes
          });
      } else {
          unit = new google.maps.Marker({
              position: position,
              map: fibers.map,
              title: param.name || '',
              icon: {
                  path: google.maps.SymbolPath.CIRCLE,
                  fillColor: color,
                  fillOpacity: 0,
                  strokeOpacity: 0,
                  scale: 8
              },
              draggable: !fibers.show_all_linked_schemes,
              label: {
                  fontFamily: 'Fontawesome',
                  text: label_text,
                  fontSize: size + 'px',
                  color: color
              }
          });
      }

      fibers.map_state.objects.markers.push({
          marker: unit,
          size: size,
          text: label_text,
          is_circle: is_circle,
          hide_on_zoom: container_params ? container_params.hide_on_zoom : false
      });

      google.maps.event.addListener(unit, 'dragend', (e) => {
          const lat_lng = e.latLng;
          const lat = lat_lng.lat();
          const lng = lat_lng.lng();
          api_base.ajax({
              act : 'map_unit_position',
              id  : id,
              lat : lat,
              lng : lng,
              ok_func: 'fibers.map_unit_position_callback'
          });
          places[id].lat = lat;
          places[id].lng = lng;
          fibers.map_state.zoom = 0;
          fibers._map_cables(units, places, polylines);
      });

      unit.addListener('click', (e) => {
          if( e.domEvent && e.domEvent.ctrlKey ) {
              fibers.menu_actions['map_unit_center_view']({id: id});
              return;
          }
          if( fibers.map_info_window ) fibers.map_info_window.close();
          let unit = fibers.cy.getElementById(id + ':0');
          let menu_param = {id: id};
          if( unit ) {
              let all_data = unit.data('all_data');
              if( all_data ) {
                  menu_param.name = all_data.name;
                  menu_param.description = all_data.description;
              }
          }
          var menu = document.createElement('div');
          menu.innerHTML = api_base.template('map_marker_menu', menu_param).html();
          const info_window = fibers.map_info_window = new google.maps.InfoWindow({ content: menu });
          info_window.setPosition(e.latLng);
          info_window.open(map);
          fibers.add_listeners( $(menu), {id: id} );
      });
  }

  if( !fibers.is_infrastructure_view )
  {
      fibers.is_infrastructure_view = true;
      $('#toggle-infrastructure-view').addClass('downed');
      fibers.show_all_callback(data);
  }

  fibers._map_cables(units, places, polylines);

  if( data.set_marker )
  {  
      $('#map_action_title').text('Місце обриву');
      let position = { lat: data.set_marker.lat, lng: data.set_marker.lng };
      fibers.map_state.objects.marker = new google.maps.Marker({position: position, map: map});
      map.setCenter(position);
  }
};

fibers.map_unit_position_callback = function(data)
{
  let unit = fibers.cy.getElementById(data.unit.id + ':0');
  if( unit )
  {
      let all_data = unit.data('all_data');
      if( all_data )
      {
          all_data.lat = data.unit.lat;
          all_data.lng = data.unit.lng;
          all_data.lat && all_data.lng ? unit.addClass('has_gps') : unit.removeClass('has_gps');
      }
  }
  fibers.map_create();
  fibers.map_all_callback(data.scheme);
};

