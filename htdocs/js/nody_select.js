(function($)
{
  function new_pretty_select(original_select, options)
  {
    if( original_select.data('pretty-select') ) return original_select;
    original_select.attr('data-pretty-select', 1);

    var can_create_value = original_select.data('can-create');
    var is_mobile = options.is_mobile;

    var multiple; // you can select multiple values

    // A modal window
    var select_window    = $('<div></div>', {'class': 'pretty_select_window'});
    var search_el        = $('<input></input>', {type: 'text'});
    var search_result_el = $('<div></div>', {class:'search_result'});
    var button           = can_create_value ? $('<a></a>', {'href': '#', 'class': 'nav'}).text('+') : '';
    var cloned_select    = original_select.clone();

    cloned_select.empty();

    select_window.append( button, search_el, search_result_el, cloned_select );
    $('body').append( select_window );

    var value_block   = $('<a></a>', {'href': '#', 'class': original_select.prop('multiple') ? 'pretty_select' : 'pretty_select nowrap'});
    var hidden_multi  = $('<input></input>', {'type': 'hidden', 'value': original_select.attr('name')});
    original_select.hide().after(value_block, hidden_multi);

    var select_window_obj = select_window.modal_window();

    var set_show_value = function(from_select)
    {
        var txt = [];
        if( !from_select ) from_select = original_select;
        from_select.find('option').each(function()
        {
            if( $(this).prop('selected') ) txt.push($(this).text());
        });
        txt = txt.join(' | ');
        value_block.text(from_select.val() == '' || txt == '' ? '...' : txt);
        select_window_obj.position(value_block.offset().left, value_block.offset().top + value_block.height() + 6);
    }

    set_show_value();

    original_select.on('change', function()
    {
        multiple = original_select.prop('multiple');
        if( multiple )
        {
            hidden_multi.attr('name', '__array');
            cloned_select.attr('multiple', 'multiple');
        }
         else
        {
            hidden_multi.attr('name', '');
            cloned_select.removeAttr('multiple');
        }
        cloned_select.empty();
        original_select.find('option').each( function()
        {
            var opt = $(this);
            if( opt.prop('style').display != 'none' && (!multiple || opt.val() != '') ) {
                var new_opt = opt.clone();
                new_opt.prop('selected', opt.prop('selected'));
                new_opt.appendTo(cloned_select);
            }
        });
        set_show_value();
    });

    value_block.click( function(pos)
    {
        original_select.trigger('change');
        var size = $('option', cloned_select).length;
        size = is_mobile ? 1 : size<2 ? 2 : size>10 ? 10 : size;
        cloned_select.attr({ size : size });
        cloned_select.show();
        search_result_el.hide();
        search_el.val('');
        search_el.focus();
        select_window_obj.show();
        return false;
    });

    var select_event = function()
    {
        var value = cloned_select.val();
        original_select.val(value).trigger('change');
        set_show_value();
        select_window_obj.close();
    }

    cloned_select.on('click', function(event)
    {
        if( is_mobile && ! multiple ) {
            cloned_select.val([]);
        }
    });
    cloned_select.on('click', 'option', function(event)
    {
        cloned_select.trigger('change');
    });


    cloned_select.change(function()
    {
        if( multiple )
        {
            var value = cloned_select.val();
            if( value.length == 1 )
            {
                var values = original_select.val();
                if( !values ) values = []; 
                var i = values.indexOf(value[0]);
                if( i == -1 )
                {
                    values.push(value[0])
                }
                 else
                {
                    values.splice(i, 1);
                }
                cloned_select.val(values);
            }
            original_select.val(cloned_select.val());
            set_show_value();
        }
         else
        {
            select_event();
        }
    });

    if( button ) button.on('click', function()
    {
        var text = search_el.val();
        if( text == '' ) return;
        var show_only = original_select.attr('data-show-only') || '';
        var value = show_only + text;
        original_select.append($("<option></option>").attr('value', value).text(text));
        original_select.val(value).trigger('change');
        set_show_value();
        select_window_obj.close();
        return false;
    });

    cloned_select.keyup( function(event)
    {
        if( event.keyCode == 13 ) select_event();
    })

    var original_options = original_select.find('option');
    search_el.keyup( function(event)
    {
        var sel_index = cloned_select.prop('selectedIndex');
        if( event.keyCode == 40 )
        {  // Down
            cloned_select.prop('selectedIndex', sel_index+1);
            return false;
        }
        if( event.keyCode == 38 )
        {  // Up
            cloned_select.prop('selectedIndex', Math.max(sel_index-1,0));
            return false;
        }

        if( event.keyCode == 13 )
        {   // Enter
            if( cloned_select.prop('selectedIndex') === -1 ) cloned_select.prop('selectedIndex', 0);
            select_event();
            return true;
        }

        var search_str = search_el.val();
        var q = new RegExp(search_str, 'ig');

        if( is_mobile && ! multiple ) {
            if( search_str === '' ) {
                cloned_select.show();
                search_result_el.hide();
            } else {
                cloned_select.hide();
                search_result_el.show();
            }
        }

        search_result_el.html('');
        cloned_select.empty();
        var res_counter = 0;
        original_options.each( function() {
            var opt = $(this);
            var val = opt.text();
            if( val.match(q) || q === '' ) {
                opt.clone().appendTo(cloned_select);
                if( search_str !== '' && res_counter++ < 5 ) {
                    var res_el = $('<div>', { text: val });
                    search_result_el.append(res_el);
                    res_el.on('click', function () {
                        cloned_select.val(val);
                        select_event();
                    });
                }
            }
        });
    });
    return original_select;
  }

  $.fn.pretty_select = function(options)
  {
    return this.each( function(){
        new_pretty_select($(this), options);
    });
  }
})(jQuery);
