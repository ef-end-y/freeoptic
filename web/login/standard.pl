# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;
use Debug;

my $check = sub
{
    my($param) = @_;
    my $uu = ses::input('_uu');
    {
        ses::input('_hash') eq '' && ses::input('_pp') eq '' && return { start=>1 };
        $uu eq '' && return { start=>1 };
        foreach my $h(
            [ 'admin', "SELECT id, AES_DECRYPT(passwd,?) AS pass FROM admin WHERE BINARY login=? LIMIT 1" ],
        ){
            my %p = Db->line($h->[1], $cfg::Passwd_Key, $uu);
            Db->ok or Error($lang::err_try_again);
            %p or next;
            my $hash = Digest::MD5->new;
            $hash = $hash->add($param->{unikey}.' '.$p{pass});
            $hash = $hash->hexdigest;
            if(
                ( ses::input('_hash') ne '' && ses::input('_hash') eq $hash ) ||
                ( ses::input('_pp') ne '' && ses::input('_pp') eq $p{pass} )
            ) {
                my $uid = $p{id};
                return { id=>$uid, role=>$h->[0], trust=>1 };
            }
            debug("auth error: '".ses::input('_hash')."' <> '$hash'");
            last;
        }
    }

    ToLog("! $ses::ip. Auth error. Login: $uu");
    return { 
        error => L('Неверный логин или пароль'),
        err_cod => 'wrong_password',
    };
};

my $start = sub
{
    my($param)= @_;
    return {
        params => {
            _ses  => $param->{ses},
            _salt => $param->{unikey},
            _mod  => $param->{mod},
        },
        template => 'login',
    };
};

sub get_auth_sub
{
    return {
        start => $start,
        check => $check,
        title => L('Авторизация по логину и паролю'),
    };
}

1;