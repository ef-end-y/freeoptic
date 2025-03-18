(function($)
{
  function new_modal_window(modal_div)
  {
    var modal = this;
/*
    <div class='modal_container'>
        <div class='modal_mask'></div>              - затемненный фон, пока отключен
        <div class='modal_box'>                     - модальное окно
            <a class='modal_close' href='#'></a>    - кнопка 'закрыть'
            <modal_div></modal_div>                 - dom элемент с данными в модальном окне
        </div>
    </div>
*/
    var modal_container    = $('<div></div>', { 'class': 'modal_container' });
    var modal_content      = modal_div.replaceWith( modal_container );
    var modal_box          = $('<div></div>', { 'class': 'modal_box' });
    var modal_close_button = $('<a></a>',     { 'class': 'modal_close', href: '#' });
    var modal_mask         = $('<div></div>', { 'class': 'modal_mask' }).fadeTo('fast', 0.22);

    modal_content.css({ 'overflow-x': 'auto' });
    //modal_box.append( modal_close_button );
    modal_box.append( modal_content );
    modal_box.css({'position': 'absolute', 'z-index': 101});
    //modal_container.append( modal_mask );
    modal_container.append( modal_box );

    modal._show = function()
    {
        modal_container.addClass( 'modal_is_visible' );
        modal_container.show();
    }
    modal._hide = function()
    {
        modal_container.removeClass( 'modal_is_visible' );
        modal_container.hide();
    }
    
    modal._hide();

    var winH, winW, docH, docW;

    function resize()
    {
        winH = $(window).height();
        winW = $(window).width();
        docH = $(document).height();
        docW = $(document).width();
        modal_mask.css({
            width  : docW,
            height : docH 
        });
    }

    resize();
    $(window).resize( resize );

    modal.width = 0;
    modal.height = 0;

    modal.content = function(html)
    {
        modal_div.html(html);
    }

    modal.position = function(x, y)
    {
        var pos = { left:'auto', right:'auto', width:'auto', height:'auto' };
        modal.width = modal_box.width();
        modal.height = modal_box.height();
        if( modal.width > 0.9 * winW )
        {
            modal.width = 0.9 * winW;
            modal_box.width( modal.width );
        }
        if( x > 0 )
        {
            y = Math.max( 0, (modal.height + y) > docH ? docH - modal.height - 40 : y );
            pos.top = y + 'px';
            if( (modal.width + x)  > docW )
            { 
                pos.right = docW - x + 'px';
                modal_close_button.css({left: 'auto', right: '-12px'});
            }
             else
            {
                pos.left = x + 'px';
                modal_close_button.css({left: '-12px', right: 'auto'});
            }
        }
         else
        {
            pos.left = (winW - modal.width) / 2;
            pos.top = Math.max(5, (winH - modal.height) / 2);
        }
        modal_box.css(pos); 
    }

    modal.show = function(x, y)
    {
        modal._show();
        if( x ) modal.position(x, y); // else modal.position(0, 0);
    }

    modal.fullscreen = function()
    {
        modal._show();
        modal.width = 0.9 * winW;
        modal.height = 0.9 * winH;
        modal_box.width( modal.width );
        modal_box.height( modal.height );
        modal_box.css({ left: 0.05 * winW, top: 0.05 * winH });
    }

    modal.close = function()
    {
        modal._hide();
        modal_box.css({ width:'auto', height:'auto' });
        modal_content.css({ width:'auto', height:'auto' });
    }

    modal_mask.click(modal.close);
    modal_close_button.click(modal.close);

    $(document).on('keyup', 'body', function(event)
    {
        if( ! modal_container.is(':visible') ) return true;
        if( event.keyCode == 27 )
        {   // ESC key
            modal.close();
        }
        return true;
    });

    $(document).on('mousedown', 'body', function(event)
    {
        if( ! modal_container.is(':visible') ) return true;
        var target = $(event.target);
        if( target.closest(modal_box).length ) return true;
        if( target.parents('.datepicker').length ) return true;
        modal.close();
        return true;
    });

    modal_div.bind('close', function()
    {
        modal.close();
    });

    return modal;
  }

  $.fn.modal_window = function(options)
  {
    return new new_modal_window($(this), options);
  }
})(jQuery);


(function($)
{
  function new_nody_box(el)
  {
    if( el.data('nody_box') ) return el;
    el.attr('data-nody_box', 1);
    var box = $('<div></div>', { 'class': 'box' }).html(
       "<div class='box_tr'><div class='box_tl'><div class='box_t'></div></div></div>" +
       "<div class='box_r'><div class='box_l'><div class='box_content'></div></div></div>" +
       "<div class='box_br'><div class='box_bl'><div class='box_b'></div></div></div>"
    );
    if( ! el.data('wide') )
    {
        box = $('<div></div>', { 'class': 'box-mini' }).append(box);
    }
    var original = el.replaceWith(box);
    box.find('.box_content').replaceWith(original);
    if( original.data('title') )
    {
        box.find('.box_t').html("<div class='box_title'><span>" + original.data('title') + "</span></div>");
    }

    return el;
  }

  $.fn.nody_box = function(options)
  {
    return this.each( function(){
        new_nody_box($(this), options);
    });
  }
})(jQuery);
