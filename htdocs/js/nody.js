function nody_ready()
{
    var nody = this;

    $('#debug_href').click( function(){
        $('#debug').toggle();
        return false;
    });

    if( !$('#buffer').length )
    {
        var buffer = $('<div></div>', { 'id': 'buffer', 'display': 'none' });
        $('body').prepend(buffer);
    }

    var modal_window = $('<div></div>', { 'id': 'modal_window' });
    $('body').prepend(modal_window);
    nody.modal_window = modal_window = modal_window.modal_window();

    $(window).resize( function() {
        nody.winH = $(window).height();
        nody.winW = $(window).width();
        nody.docH = $(document).height();
        nody.docW = $(document).width();
    });
    $(window).resize();

    nody.img_after_submit = $('<img>').attr({'src':nody.img_after_submit, style:'vertical-align:middle'});

    nody.uniq_id = 0;

    nody.get_uniq_id = function()
    {
        return 'nody_js_uniq_id_' + ++nody.uniq_id;
    }

    var mobileAndTabletcheck = function() {
      var check = false;
      (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
      return check;
    };
    var is_mobile = mobileAndTabletcheck();

    nody.pretty = function()
    {
        $('[data-box]').nody_box();

        $('select.pretty').pretty_select({is_mobile: is_mobile});

        $('table.pretty').each( function()
        {
            var el = $(this);
            if( !el.data('ready') ) 
            {
                el.data('ready', true);
                var tbl_h = el.height();
                var bottom_space = $(document).height() - el.offset().top - tbl_h;
                if( bottom_space > tbl_h*0.4 )
                {
                    tbl_h = Math.min(tbl_h+bottom_space-50, tbl_h*1.4);
                    if( bottom_space > tbl_h ) tbl_h *= 1.2;
                    var rows = el.find('tr').length;
                    // в некоторых браузерах хедер не менял высоту при изменении высоты таблицы
                    if( rows>0 ) el.find('thead >tr').height( tbl_h/rows );
                    el.height(tbl_h);
                }
            }
        });

        $('.align_center.pretty').each( function()
        {
            var el = $(this);
            if( !el.data('ready') ) 
            {
                el.data('ready', true);
                var delta = el.parent().width() - el.width();
                delta = Math.min(delta/2.2, 500);
                if( delta > 0 ) el.css({'padding-right': delta + 'px'});
                console.log(delta);
            }
        });

        if( nody.msg_after_submit )
        {
            $('input[type="submit"].nav_button').each( function()
            {
                var btn = $(this);
                btn.removeClass('nav_button');
                btn.css({ position: 'absolute', left:'-8000px', 'z-index':-1 });
                var new_btn = $('<span></span>', { text:btn.val(), 'class':'nav_button' }).
                    click( function()
                    {
                        if(new_btn.data('busy'))
                        {
                            new_btn.html('Please wait');
                            return;
                        }
                        new_btn.data('busy',1);
                        new_btn.html(nody.img_after_submit).append(' '+nody.msg_after_submit);
                        setTimeout( function()
                        {
                            new_btn.html(btn.val());
                            new_btn.data('busy',0);
                        }, 5000);
                        btn.trigger('click');
                    });
                btn.after(new_btn);
            });
        }

        $('[data-autosubmit]').each(function()
        {
            var el = $(this);
            if( el.data('autosubmit') >= 0 )
            {
                setTimeout( function(){ el.click() }, 0 + el.data('autosubmit') );
                el.data('autosubmit',-1);
            }
        });

        $('[data-submit-on-change]').change(function()
        {
            $(this).closest('form').submit();
        });

        $('[data-autoshow-userinfo]').each(function()
        {
            var el = $(this);
            if( el.data('ready') ) return;
            el.data('ready', true);
            el.bind('change', function()
            {
                if( !el.val() )
                {
                    var target = $('#' + el.data('autoshow-userinfo'));
                    target.html('');
                    target.trigger('change');
                    return;
                }
                $.ajax({
                    url     : '?',
                    dataType: 'json',
                    data    : {
                        a       : 'ajUserInfo',
                        uid     : el.val(),
                        domid   : el.data('autoshow-userinfo'),
                        nowindow: 1,
                        cookie  : document.cookie
                    },
                    success : nody.ajax_response
                });
            });
            el.change();
        });

        $('[data-show-when-changed]').on('change', function()
        {
            var el = $(this);
            var target = $('#'+ el.attr('data-show-when-changed'));
            target.css('display', target.attr('data-original-display-type') || 'block');
        });

        $('[data-set-href-when-changed]').on('change', function()
        {
            var el = $(this);
            var target = $('#'+ el.attr('data-set-href-when-changed'));
            target.attr('href', target.attr('href') + '&val=' + el.val());
            target.val( el.val() );
        });

        $('[data-set-text-when-click]').on('click', function()
        {
            var el = $(this);
            var target = $('#'+ el.attr('data-set-text-when-click'));
            target.val( el.text() );
        });

        $('[data-add-text-when-click]').on('click', function()
        {
            var el = $(this);
            var target = $('#'+ el.attr('data-add-text-when-click'));
            var cur_val = target.val();
            target.val( cur_val + (cur_val != '' ? ', ' : '') + el.text() );
        });

        var d = 'ajax-when-change';
        $('[data-' + d + ']').each( function()
        {
            var el = $(this);
            var action = el.data(d);
            var param = {};
            $.each(this.attributes, function(i, a) {
                param[a.name] = a.value;
            });
            el  .removeAttr('data-' + d)
                .on('keyup change', function()
                {
                    param['a'] = action;
                    param['val'] = el.val();
                    $.ajax({
                        url     : '?',
                        dataType: 'json',
                        data    : param,
                        success : nody.ajax_response
                    });
                })
                .change();
        });

        var d = 'ajax-on-press-enter';
        $('[data-' + d + ']').each( function()
        {
            var el = $(this);
            var param = {};
            $.each(el.data(), function(key, value) {
                if( key != 'ajaxOnPressEnter' ) param[key] = value;
            });
            param['a'] = el.data(d);
            el  .removeAttr('data-' + d)
                .on('keyup', function(e)
                {
                    var key = e.keyCode;
                    if( key == 13 )
                    {
                        el.trigger('save-changes');
                        e.preventDefault();
                    }  
                }).on('keypress', function(e)
                {
                    if( e.keyCode == 13 ) e.preventDefault();
                }).on('input', function()
                {
                    el.addClass('changed_data');
                }).on('save-changes', function()
                {
                    param['value'] = el.val();
                    $.ajax({
                        url     : '?',
                        dataType: 'json',
                        data    : param,
                        success : nody.ajax_response
                    });
                })
        });

        $('[data-active=1]').attr('data-active',0).addClass('active');

        $('[data-autofocus=1]').attr('data-autofocus',0).focus();

        $('[data-neighbor_id]').each( function()
        {
            var el = $(this);
            var neighbor = $('#'+ el.attr('data-neighbor_id'));
            el  .removeAttr('data-neighbor_id')
                .change( function()
                {
                    var val = el.val();
                    var hide_if = el.attr('data-neighbor_hide_if');
                    if( hide_if.length && hide_if.split(',').indexOf(val) !== -1 )
                        neighbor.hide(); else neighbor.show();
                    var multiple_if = el.attr('data-neighbor_multiple_if');
                    var neighbor_select = neighbor.find('select');
                    if( multiple_if ) multiple_if == val
                        ? neighbor_select.attr('multiple', 'multiple')
                        : neighbor_select.removeAttr('multiple');
                    neighbor_select.change();
                })
                .change();
        });

        $('[data-depends-on]').each( function()
        {
            // список значений этого элемента зависит от значения элемента с именем в data-depends-on
            var el = $(this);
            var depends_on = el.attr('data-depends-on');
            el.removeAttr('data-depends-on');
            el.closest('form').find('[data-dopdata-name=' + depends_on + ']').on('change', function()
            {
                var sel_value_as_text = el.find('option:selected').text();
                var value = $(this).val() + ':';
                //if( value.length ) value += ':';
                el.attr('data-show-only', value);
                var i = 0;
                el.find('option').each( function() {
                    var option = $(this);
                    var option_val = option.val();
                    if( option_val.substring(0, value.length) == value || option_val == '' ) {
                        option.show();
                        if( option.text() == sel_value_as_text ) el.val(option_val); // меняем на иной пункт с таким же названием
                        i++;
                    } else {
                        option.prop('selected', false);
                        option.hide();
                    }
                });
                el.trigger('change');
                // i > 0? el.parent().show() : el.parent().hide();
            }).change();
        });

        $('.dateinput').each( function()
        {
            var el = $(this);
            if( el.data('fake') ) return;
            var uniq_id = nody.get_uniq_id();
            var link = $('<a></a>', {
                    'class': 'cursor_pointer',
                    'style': 'margin-left: 3px; margin-right: 5px',
                    'text': '📆'
                }).click( function(event)
                {
                    nody.click_pos = { x:'auto', y:'auto' };
                    $.ajax({
                        url     : '?',
                        dataType: 'json',
                        data    : {
                            a     : 'ajCalendar',
                            domid : uniq_id,
                            date  : el.val(),
                            years_ago : el.data('years_ago')
                        },
                        success : nody.ajax_response
                    });
                });
            el.after(link);
            el.removeClass('dateinput')
                .addClass('dateinput_field')
                .attr('id', uniq_id);
        });

        $('.select_date [data-date]').each( function()
        {
            var el = $(this);
            el.css('cursor','pointer')
                .click( function()
                {
                    var date_input_domid = el.parents()
                        .find('[data-select_date_input_domid]')
                        .attr('data-select_date_input_domid');
                    var date_input = $('#' + date_input_domid);
                    date_input.val(el.attr('data-date'));
                    modal_window.close();
                    if( date_input.data('have-fake') ) {
                        date_input.focusout();
                    }
                });
        });

        // --- Внутри блоков .hide_border поля input и select сделаем без бордюра ---
        // При наведении мыши бордюр будет появляться
        // Select заменяется на текстовое поле и скрывается, по клику появляется

        var text_editing = false;
        var hide_border = function(main_el, type, text)
        {
            if( is_mobile && type == 'select' ) return;
            var fake_el = type == 'textarea'
                ? $('<textarea></textarea>', { text: text })
                : $('<input></input>', { type: type, value: text, autocomplite: 'off' });
            
            fake_el
                .attr('data-fake','yes')
                .attr('class', main_el.attr('class'))
                .addClass('hide_border_now');

            main_el
                .attr('data-have-fake','yes')
                .hide()
                .after(fake_el);

            show_main_el = function(main_el, fake_el) {
                $('[data-fake]').show().addClass('hide_border_now');
                $('[data-have-fake]').hide();
                fake_el.hide();
                main_el.show().focus();
                text_editing = true;
                // курсор в конец
                var s = main_el.val(); main_el.val('').val(s);
            }
            fake_el.click( function() { show_main_el(main_el, fake_el) } );
            fake_el.focusin( function() { show_main_el(main_el, fake_el) } );
            main_el.focusout( function() {
                main_el.hide();
                fake_el.show();
                text_editing = false;
            });
            fake_el.mouseenter( function() {
                fake_el.removeClass('hide_border_now');
            })
            fake_el.mouseleave( function() {
                fake_el.addClass('hide_border_now');
            })
            return fake_el;
        }

        $('.hide_border input[type=text]').each( function()
        {
            var el = $(this);
            if( el.val() )
            {
                el.addClass('hide_border_now');
                el.mouseenter( function() {
                    el.removeClass('hide_border_now');
                })
                el.mouseleave( function() {
                    el.addClass('hide_border_now');
                })
                return;
            }
            if( !el.attr('data-fake') )
            {
                var fake_el = hide_border(el, 'text', el.val() || '...');
                el.focusout(function() {
                    fake_el.val(el.val() || '...').show();
                });
            }
        });
        $('.hide_border textarea').each( function()
        {
            var el = $(this);
            var fake_el = hide_border(el, 'textarea', el.val());
            el.focusout(function() {
                fake_el.val(el.val()).show();
            });
        });
        $('.hide_border select').each( function()
        {
            var el = $(this);
            if( is_mobile )
            {
                el.addClass('bright_bg');
                return;
            }
            if( el.is(':hidden') ) return;
            var fake_el = hide_border(el, 'text', el.find('option:selected').text() || '...');
            el.focusout(function() {
                fake_el.val(el.find('option:selected').text()).show();
            });
            el.click(function() {
                el.hide();
                fake_el.val(el.find('option:selected').text()).show();
            });
            var size = el.find('option').length;
            el.attr('size', size>35? 20 : size>10? 10 : size);
        });
        $('.hide_border a.pretty_select').addClass('hide_border_now');

        $('.hide_border').removeClass('hide_border');

        $('.rowinfo td:first-child').each(function(){
            $(this).html( '<span>' + $(this).html() + '</span>');
        });

        $('.close').removeClass('close').addClass('have-close-button').each( function()
        {
            var container = $(this);
            var link = $('<a></a>', {'class': 'close_button'}).click( function(event)
            {
                container.parent().html('');
                event.preventDefault();
            });
            container.prepend(link);
        });

        $('a[data-ajax-into-here]').each( function()
        {
            var link = $(this);
            if( link.data('ajax-into-here') < 0 ) return;
            link.data('ajax-into-here', -1);
            var id = 'js_randid_' + Math.floor(Math.random()*10000000000);
            link.addClass('ajax');
            link.attr('href', link.attr('href') + '&domid=' + id);
            var div = $('<div></div>', {'id': id});
            //div.css('display', 'inline-block');
            link.after(div);
        });
    }

    // --- Ajax links ---

    nody.click_pos = {};

    $(document).on('click', 'a.ajax', function(pos)
    {
        var link = $(this);
        const orig_title = link.html();
        var data = {};
        if( link.data('domid') ) data.domid = link.data('domid');
        if( link.data('send') ) data.send = link.data('send');
        link.html( nody.img_after_submit );
        const orig_title_timeout = setTimeout( function(){ link.html(orig_title); }, 5000 );
        if( !link.parents('#modal_window')[0] && !link.hasClass('ignore_position') ) {
            nody.click_pos = { x:pos.pageX, y:pos.pageY };
        }
        $.ajax({
            url     : this.href,
            data    : data,
            dataType: 'json',
            success : function(responseText, status) {
                    link.html(orig_title);
                    clearTimeout(orig_title_timeout);
                    nody.ajax_response(responseText, status);
            },
            error   : function(status) {
                    if( link.data('domid') ) $('#'+link.data('domid')).text('Error');
            }
        });
        return false;
    });

    // --- Ajax forms ---

    $(document).on('submit', 'form.ajax', function(event)
    {
        event.preventDefault();
        var form = $(this);
        var action = form.attr('action');
        var enctype = form.attr('enctype');
        var data = new FormData(form.get(0));
        var d = {
            method  : 'post',
            url     : action,
            dataType: 'json',
            data    : data,
            processData : false,
            contentType : false,
            success : nody.ajax_response
        };
        if( enctype )
        {
            d.enctype = enctype;
            d.processData = false;
        } 
        $.ajax(d);
    });

    $('[data-trigger]').each( function(){
        var obj = $(this);
        var trigger = obj.attr('data-trigger');
        $(document).bind( trigger, function(){
            obj.click();
        });
    });

    // --- Модальное окно при нажатии правой мышки на элементе .modal_menu ---

    var shown_modal = false;
    $(document).on('mousedown', '.modal_menu', function(event)
    {
        shown_modal = false;
        $('.modal_menu').removeClass('modal_menu_active')
        var el = $(this);
        el.addClass('modal_menu_active');
        // Если правая кнопка - сразу показываем,
        // если левая - только при зажатии на секунду
        var timeout = event.which == 3 ? 1 : 1000;
        var timeout_id = setTimeout( function(){
            shown_modal = true;
            nody.click_pos = { x: event.pageX, y: event.pageY };
            $.ajax({
                url     : el.attr('rel'),
                dataType: 'json',
                success : nody.ajax_response,
                data    : {'domid': el.data('domid') || 'modal_window'}
            });
        }, timeout);
        el.mouseup( function(){
            clearTimeout(timeout_id);
        });
    });

    $(document).on('click', '.modal_menu', function(event)
    {
        if( shown_modal ) event.preventDefault();
    });
    $(document).on('contextmenu', '.modal_menu', function(event)
    {
        event.preventDefault();
    });
    $(document).on('mouseenter', '[data-hoversubmit]', function(event)
    {
        el = $(this);
        var id = 'js_randid_' + Math.floor(Math.random()*10000000000);
        el.parent().attr('id', id);
        el.replaceWith(nody.img_after_submit.clone());
        $.ajax({
            url     : el.attr('href'),
            dataType: 'json',
            success : nody.ajax_response,
            data    : {'domid': id}
        });
    });

    $(document).on('click', '.new_window', function(event){
        modal_window.fullscreen();
        var iframe = $('<iframe></iframe>', {
            src : this.href,
            css : {height: modal_window.height},
            rel : $(this).data('parent')
        });
        $('#modal_window').html(iframe);
        event.preventDefault();
        return;
        var w = window.open(this.href, $(this).data('parent'),
            'left=25,top=' +
                (nody.winH * 0.15) +
            ',width=' + 
                (nody.winW-50) +
            ',height=' +
                (nody.winH * 0.7) +
            ',resizable=yes,location=no,status=no');
        w.focus();
        event.preventDefault();
    });

    // ---

    $(document).on('click', 'a[data-show-or-hide]', function(event){
        var a = $(this);
        a.attr('data-show-or-hide').split(',').forEach(function(item) {
            var rel = $('.' + item);
            if( rel.length ) {
                rel.is(':visible') ? a.removeClass('downed') : a.addClass('downed');
                rel.slideToggle(100);
            }
        });
        return false;
    });
    $('a[data-show-or-hide].downed:visible').trigger('click');

    $(document).on('click', "a[href='#chkbox_list_all']", function(){
        var chkbox = "#" + $(this).attr('rel') + ' input:checkbox';
        var checked = $(chkbox + ':first').is(':checked');
        $(chkbox).prop('checked', !checked);
        return false;
    });

    $(document).on('click', "a[href='#chkbox_list_invert']", function(){
        var chkbox = "#" + $(this).attr('rel') + ' input:checkbox';
        $(chkbox).each( function(){ $(this).prop('checked', !$(this).is(':checked')) } );
        return false;
    });

    nody.show_ajax_wait_block = function() { $('.ajax_wait').removeClass('hidden'); }
    nody.hide_ajax_wait_block = function() { $('.ajax_wait').addClass('hidden'); }

    nody.ajax = function(data)
    {
        nody.show_ajax_wait_block();
        $.ajax({
            url     : nody.script_url,
            dataType: 'json',
            data    : data,
            success : nody.ajax_response,
            error   : nody.hide_ajax_wait_block
        });
    }

    var debug_blocks_count = 0;
    
    nody.ajax_response = function( responseText, status )
    {
      nody.hide_ajax_wait_block();
      for( var r in responseText )
      {
        if( responseText[r].json == 'error' )
        {
            $('#debug').prepend("<div style='text-align:center; padding:14px'>SERVER JSON ERROR</div>");
            continue;
        }

        var id      = responseText[r].id;
        var action  = responseText[r].action || 'replace';
        var data    = responseText[r].data   || '';
        var target  = responseText[r].target || '';
        var type    = responseText[r].type   || '';

        id = '#' + id;

        if( target == 'iframe' )
        {
            target = $(id).contents().find('body');
        }
         else
        {
            target = $(id);
        }

        if( type == 'style' )
        {
            $(id).attr('style', data);
            continue;
        }
        if( type == 'class' )
        {
            action == 'remove' ? $(id).removeClass(data) : $(id).addClass(data);
            continue;
        }
        if( type == 'js' )
        {
            var js_func = responseText[r].js_func;
            if( js_func )
            {
                var p = js_func.split('.');
                js_func = window;
                while( p.length )
                {
                    js_func = js_func[p.shift()];
                }
                try{ eval(js_func(data)) } catch(err){ if( console ) console.log(js_func + ' ||| ' + err); }
            }
             else
            {
                try{ eval(data) } catch(err){ if( console ) console.log(data + ' ||| ' + err); }
            }
            
            continue;
        }
        if( type == 'url' )
        {
            if( history.pushState )
            {
                if( window.history.state && window.history.state['only_replace'] )
                {
                    history.replaceState({only_replace: 1}, '', data);
                }
                 else
                {
                    history.pushState({only_replace: 1}, '', data);
                    window.addEventListener('popstate', function(e) {
                        window.location.reload();
                    });
                }
            }
            continue;
        }

        if( action == 'redirect' )
        {
            window.location.href = data;
            continue;
        }
        if( action == 'cookie' )
        {
            var expires = new Date();
            expires.setTime(expires.getTime() + (1000 * 86400 * 365));
            document.cookie = id + '=' + escape(data) + '; expires=' + expires.toGMTString() + '; path=/';
            continue;
        }

        if( id == '#debug' && debug_blocks_count++ > 7 )
        {
            $(id).html('[NoDeny JS] clear debug area');
            debug_blocks_count = 0;
        }

        if( action == 'add' )
        {
            target.append(data);
        }
         else if( action == 'insert' )
        {
            target.prepend(data);
        }
         else if( action == 'value' )
        {
            target.val(data);
        }
         else if( action == 'move' )
        {
            $('#' + responseText[r].from + ' *').appendTo(target);
        }
         else
        {
            target.html(data);
        }
        target.trigger('change');

        if( id == '#modal_window' )
        {
            if( target.html() == '' )
            {
                modal_window.close();
                continue;
            }
            var x = responseText[r].x || nody.click_pos.x;
            var y = responseText[r].y || nody.click_pos.y;
            modal_window.show( x, y );
        }
      }
      nody.pretty();
    }

    nody.pretty();
}
