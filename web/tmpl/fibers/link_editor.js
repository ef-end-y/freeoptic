fibers.eh = cy.edgehandles(
{
    noEdgeEventsInDraw: true,
    snap: false,
    handleNodes: 'node[cls="frame_inner"][^ignore],node[cls="fiber_tip"][^ignore]',
    edgeType: function( sourceNode, targetNode ) {
        // returning null/undefined means an edge can't be added between the two nodes
        if( !targetNode.data() ) return undefined;
        let src_cls = sourceNode.data('cls');
        let dst_cls = targetNode.data('cls');
        let src_type = sourceNode.data('type');
        let dst_type = targetNode.data('type');
        // console.log({ src_cls : src_cls, dst_cls : dst_cls, src_type : src_type, dst_type : dst_type });
        if( src_cls == 'fiber_tip' )
        {
            if( dst_cls  != 'frame_inner' ) return undefined;
            return 'flat';
        }
        if( src_cls == 'frame_inner' )
        {
            if( dst_cls  == 'fiber_tip' ) return 'flat';
            if( dst_cls  != 'frame_inner' ) return undefined;
            //if( dst_type == 'splitter' && src_type == 'splitter' ) return 'flat';
            //if( dst_type == 'splitter' ) return undefined;
            if( dst_type == 'port' && sourceNode.parent().data('i') == targetNode.parent().data('i')) return undefined;
            if( src_type == 'port' && dst_type == 'solder' ) return undefined;
            if( src_type == 'solder' && dst_cls != 'fiber_tip' ) return undefined;
            if( src_type == 'connector' && dst_type == 'solder' ) return undefined;
            if( src_type == 'splitter' && dst_type == 'solder' ) return undefined;
            return 'flat';
        }
        return undefined;
    },
    complete: function( source, target, added_eles ) {
        api_base.ajax({
            act       : 'link_create',
            src       : source.parent().data('i'),
            src_side  : source.parent().data('side') || 0,
            src_inner : source.data('i'),
            dst       : target.parent().data('i'),
            dst_side  : target.parent().data('side') || 0,
            dst_inner : target.data('i'),
            ok_func   : 'fibers.link_create_callback'
        });
        added_eles.remove();
    },
});


fibers.toggle_link_editing = function()
{
    nody.modal_window.close();
    let el = fibers.cy.elements('node[cls="fiber_tip"]')
    fibers.eh_enabled = !fibers.eh_enabled;
    if( fibers.eh_enabled )
    {
        fibers.eh.enable();
        el.addClass('big');
        el.removeClass('unlinked');
    }
     else
    {
        fibers.eh.disable();
        el.removeClass('big');
    }
    fibers.eh.hide();   
};

fibers.eh.disable();
