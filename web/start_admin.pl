# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;
$ses::lang = $lang::start_admin;

my $aid = $ses::auth->{uid};

if( ! $ses::auth->{adm}{id} )
{
    debug('warn', L('Несуществующий админ в таблице сессий: id=[]', $aid));
    remove_session();
    url->redirect(a=>'', @_);
    die;
}

Adm->set_current( $ses::auth->{adm} );


my $login_chain = Adm->login;
$ses::adm_infoline = "Adm $login_chain(id=$aid, ip=$ses::ip)";

my $trusted = $ses::auth->{role} eq 'admin';
$ses::debug = 1 if Adm->chk_privil('SuperAdmin') && $trusted && $ses::cookie->{debug};

# --- Переключение на другого админа ---
{
    my $new_adm_id = int $ses::cookie->{new_admin} or last;
    Adm->chk_privil('SuperAdmin') or last;
    my %p = Db->line("SELECT * FROM admin WHERE id=?", $new_adm_id);
    %p or last;

    $ses::adm_infoline .= " -> $p{login}(id=$p{id})";
    $login_chain .= ' → '.$p{login};

    Adm->set_current( \%p );

    $aid = $new_adm_id;
}

Adm->chk_privil(1) or Error L('Доступ для логина [bold] заблокирован', Adm->login);

my $cmd = ses::input('a') || 'main';
$ses::input->{a} = $cmd;

if( $cfg::plugins->{$cmd}{ajax} && !$ses::ajax )
{
    debug('warn', L('Команда [] выполняется в ajax-контексте, но http-запрос не ajax - выводим титульную страницу', $cmd));
    $cmd = 'main';
}

my $plg = $cfg::plugins->{$cmd};
$plg->{param}{only_api} && !$ses::api && Error 'Only api access';
$plg->{param}{check_priv} && Adm->chk_privil_or_die($plg->{param}{check_priv});

my $top_block = Doc->template('top_block');
$top_block->{login_chain} = $login_chain;
$top_block->{admin} = Doc->template('base')->{admin} = Adm->get($aid);
$top_block->{Ugrp} = 'Ugrp';
$top_block->{title} = CommonLocalize($plg->{title});
$top_block->{Url} = url->new(a=>$cmd);
$top_block->{top_tmpl} = exists $plg->{param}{top_tmpl} ? $plg->{param}{top_tmpl} : 'adm_top_block';
push @{$ses::subs->{exit}}, \&_show_top_block;

sub go{};

my $mod = $plg->{file};
my $err = Require_web_mod($mod);
$err && die $err;

go( url->new(a=>$cmd) );

sub _show_top_block
{
    my $data = Doc->template('top_block');
    my $tmpl = $data->{top_tmpl} or return;
    Doc->template('base')->{top_block} .= render_template($tmpl, %$data);
}

sub ToTopTitle
{
    Doc->template('base')->{top_lines} .= _('[div top_msg title][div adm_top_line]', "@_");
}

1;