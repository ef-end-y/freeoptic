# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
=head

    Модуль, запускающий модули авторизации

    Сначала создается сессия, а текущие GET/POST параметры, которые
    указывают на страницу на которую мы должны вернуться после
    авторизации, записываются в таблицу webses_data как параметр -input.

    Когда движок NoDeny получает запрос с параметром _unikey:
        http://...?_unikey=xxxx
    он выбирает из webses_data строку с unikey=xxxx и если в ней
    будет параметр -input, то все его данные будут восприняты как
    будто они посланы через браузер.

    После сохранения данных страницы, с которой пришли, происходит
    создание сессии в таблице websessions, при этом в записи:
        uid  = 0
        role = unikey, ссылающийся на данные страницы до авторизации
    Как видно, поле role выполняет иную функцию, чем обычно.

    Происходит запуск подпрограммы check конкретного модуля авторизации,
    которая должна вернуть хеш. Если в нем есть ключ:
        start - необходимо запустить подпрограмму start
        error - авторизация неудачная
    В противном случае авторизация считается успешной и хеш является
    параметрами для создании сессии: id авторизовавшегося, роль и др.

    В случае неуспешной авторизации, сессия по параметру _ses удаляется
    и происходит редирект на страницу до авторизации. При этом, если
    авторизации все еще нет (а она могла б произойти в соседнем окне),
    то авторизация начнется с начала.

    Удаление _ses необходимо, поскольку некоторые модули авторизации
    используют ключ unikey как соль авторизации, для бОльшей безопасности
    лучше перегенерировать.

=cut
use strict;
my $dir = 'login'; # каталог с модулями авторизации

sub show_login_page
{
    my($file, $params) = @_;
    $file ||= 'login_base';
    $params->{error_message} ||= v::filtr(ses::input('__auth_error')) if ses::input('__auth_error') ne '';
    $params->{Url} = url->new();
    Show render_template(Doc->template_file($file), %$params);
    Exit();
}

my $cmd = ses::input('a');
if( $cmd ne '_login' )
{
    $cmd = 'main' if ! exists $cfg::plugins->{$cmd};
    if(  $cfg::plugins->{$cmd}{param}{allow_guest} )
    {
        my %input = ses::input_all();
        url->new( %input, a=>'_guest', cmd=>$cmd )->redirect();
        die;
    }
}

my $dh;
if( ! opendir($dh, "$cfg::dir_web/$dir") )
{
    debug('error', "Не могу прочитать $cfg::dir_web/$dir");
    show_login_page( '', { error_message => $lang::err_try_again } );
}

my %auth_sub = map{ $_ => 0 } grep{ s/^_?(.+)\.pl$/$1/ } readdir($dh);
closedir $dh;

my @enabled_mod = ();
foreach my $mod( keys %auth_sub )
{
    exists $cfg::block_login_mods{$mod} && next;
    my $err_msg = Require_web_mod("$dir/$mod");
    if( $err_msg )
    {
        debug('error', $err_msg);
        next;
    }
    eval {
        $_ = get_auth_sub();
    };
    if( my $err = $@ )
    {
        debug('error', $err);
        next;
    }
    $auth_sub{$mod} = $_ or next;
    push @enabled_mod, $mod;
}

scalar @enabled_mod or show_login_page( '', { error_message => 'No auth modules' } );

# Сессия, переданная через параметр _ses, считается авторизационной

my $auth;
{
    my $ses = ses::input('_ses') or last;
    my %p = Db->line("SELECT * FROM websessions WHERE uid=0 AND BINARY ses=? LIMIT 1", $ses);
    %p or last;
    $auth = {
        ses     => $ses,
        unikey  => $p{role},
    };
}

# Сохраним все параметры страницы с которой пришли, чтобы после авторизации вернуться

if( !$auth )
{
    # Если мы пришли со страницы разлогинивания, то блокируем возврат на нее
    $ses::input_orig = {} if $ses::input_orig->{a} =~ /^(_login|logout)$/ || $ses::input_orig->{_hash};
    my $module = $ses::input_orig->{a} || 'main';
    my $unikey = Save_webses_data( module=>$module, data=>{ -input=>$ses::input_orig } );
    $unikey or show_login_page( '', { error_message => $lang::err_try_again } );

    my $ses = md5_base64(rand 10**10); $ses =~ s/[\+\/]//g;
    debug("Создаем авторизационную сессию $ses");
    my $rows = Db->do(
        "INSERT INTO websessions SET ses=?, role=?, trust=0, uid=0, expire=UNIX_TIMESTAMP()+300",
        $ses, $unikey,
    );
    $rows<1 && show_login_page( '', { error_message => $lang::err_try_again } );
    $auth = {
        ses    => $ses,
        unikey => $unikey,
    };
}

# Каким модулем авторизации пытается авторизоваться
my $sel_mod = ses::input('_mod');
$sel_mod = '' if ! $auth_sub{$sel_mod};

# Если можно авторизоваться всего одним модулем авторизации,
# будем считать, что клиент его и выбрал
if( scalar @enabled_mod == 1 )
{
    $sel_mod = $enabled_mod[0];
}
 elsif( $ses::api )
{
    $sel_mod = 'standard';
}

# Выбор метода авторизации
if( !$sel_mod )
{
    my @urls = ();
    foreach my $mod( sort{ $auth_sub{$a}{title} cmp $auth_sub{$b}{title} } grep{ $auth_sub{$_} } keys %auth_sub )
    {
        push @urls, $auth_sub{$mod}->{raw_html} ? $auth_sub{$mod}->{raw_html} :
                    url->a( $auth_sub{$mod}->{title}, _mod=>$mod, _ses=>$auth->{ses}, a=>'_login' );
    }
    show_login_page( 'login_select_mod', { urls => \@urls } );
    return 1;
}

$auth->{mod} = $sel_mod;

my $sub = $auth_sub{$sel_mod} or show_login_page( '', { error_message => 'Oops' } );

my $redirect_url = ses::input('__preset_redirect') && $cfg::preset_redirect_url ?
    url->new( -base=>$cfg::preset_redirect_url ) : url->new( _unikey=>$auth->{unikey} );

{
    my $result = $sub->{check}->($auth);
    if( $ses::api && $result->{error} )
    {
        $ses::cmd = { error=>$result->{error}, err_cod=>$result->{err_cod} };
        return 1;
    }

    $result->{start} && last;

    # Не даем авторизоваться больше одного раза по одной сессии
    my $rows = Db->do("DELETE FROM websessions WHERE uid=0 AND BINARY ses=? LIMIT 1", $auth->{ses});
    $rows<1 && show_login_page( '', { error_message => $lang::err_try_again } );

    if( $result->{error} )
    {
        debug('Неудачная авторизация - вернемся на исходную страницу до авторизации');
        $redirect_url->redirect( __auth_error=>$result->{error} );
    }

    my $ses = md5_base64(rand 10**10); $ses =~ s/[\+\/]//g;
    debug("Авторизация успешна. Создал сессию $ses, записываю в cookie: $cfg::cookie_name_for_ses");

    my $rows = Db->do(
        "INSERT INTO websessions SET ses=?, trust=?, uid=?, role=?, expire=UNIX_TIMESTAMP()+?",
        $ses, $result->{trust}, $result->{id}, $result->{role}, $cfg::web_session_ttl
    );
    $rows<1 && show_login_page( '', { error_message => $lang::err_try_again } );
    $ses::set_cookie->{$cfg::cookie_name_for_ses} = $ses;
    if( $ses::api )
    {
        $ses::cmd = { result=>'auth ok', data=>$result, ses=>$ses };
        return 1;
    }
    $redirect_url->redirect( _unikey=>$auth->{unikey} );
}

if( $ses::api )
{
    $ses::cmd = { error=>$lang::err_unauthorized, err_cod=>'unauthorized' };
    return 1;
}

my $result = $sub->{start}->($auth);
# debug $result;
show_login_page( $result->{template}.'', $result->{params} );

1;
