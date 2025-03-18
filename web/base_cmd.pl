# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;
use Debug;

sub only_api_msg
{
    Error('This cmd is allowed only in api');
}

my $cmd = ses::input('a');
exists $cfg::plugins->{$cmd} or Error('Unknown command');

if( $cmd eq '_set_ses' )
{
    $ses::api or only_api_msg();
    $ses::set_cookie->{$cfg::cookie_name_for_ses} = {
        value => ses::input('ses'),
        SameSite => 'None',
        Secure => '',
    };
    Exit();
}

if( $cmd eq 'check_auth' )
{
    $ses::api or only_api_msg();
    $ses::cmd = $ses::auth->{auth} ? {
        result => 'auth ok',
        data => {
            id    => $ses::auth->{uid},
            trust => $ses::auth->{trust},
            role  => $ses::auth->{role}
        }
    } : {
        error => $lang::err_unauthorized,
        err_cod =>'unauthorized',
    };
    Exit();
}

if( $cmd eq 'logout' )
{
    debug('Команда разлогиниться');
    $ses::auth->{auth} && remove_session();
    $ses::api or url->redirect(a=>'', @_);
    Exit();
}

1;