# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

sub go
{
    my $domid = ses::input('domid') || 'modal_window';
    my $res = _proc($_[0], $domid);
    push @$ses::cmd, {
        id   => $domid,
        data => _('[div small_info close h_left]', $res),
    };
}

sub _proc
{
    my($Url, $domid) = @_;

    my $err_msg = Require_web_mod('lang/'.$cfg::Lang.'_admin');
    $err_msg && die $err_msg;

    my $aid = ses::input_int('aid') or return L('where_is_id');
    my @res = ();
    push @res, url->a($lang::lbl_data, a=>'admin', aid=>$aid, act=>'edit');
    if( Adm->chk_privil('SuperAdmin') )
    {
        push @res, url->a($lang::btn_delete, a=>'admin', aid=>$aid, act=>'del', login=>ses::input('login'), domid=>$domid, -ajax=>1);
    }
    return join '', map{ _('[p]', $_) } @res;
}

1;