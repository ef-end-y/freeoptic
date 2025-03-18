# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

sub go
{
    if( ses::input('empty_domid') )
    {
        push @$ses::cmd, {
            id   => ses::input('empty_domid'),
            data => '',
        };
    }
    push @$ses::cmd, {
        type => 'js',
        data => 'modal_window.close()',
    };
}

1;