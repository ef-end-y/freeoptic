# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

sub go
{
    my($Url) = @_;
    Adm->chk_privil_or_die('SuperAdmin');
    my $edt_priv = 1;

    my $err_msg = Require_web_mod('lang/'.$cfg::Lang.'_admin');
    $err_msg && die $err_msg;

    Doc->template('base')->{css_left_block} = 'block_with_menu';

    my $menu = join '', map{ $Url->a(@{$_->[1]}) } grep{ $edt_priv || $_->[0] } @{$lang::admin->{main_menu}};
    ToLeft _('[div navmenu]', $menu );

    my %subs = (
        list => \&list,
        edit => \&edit,
        save => $edt_priv && \&save,
        new  => $edt_priv && \&new,
        del  => $edt_priv && \&del,
    );

    my $sub = $subs{ses::input('act')} || \&list;

    $sub->($Url, $edt_priv);
}

sub list
{
    my($Url, $edt_priv) = @_;
    ToTopTitle L('User list');
    my $db = Db->sql("SELECT * FROM admin ORDER BY login");
    $db->rows or Error( $db->ok? L('no_admin_exists') : $lang::err_try_again );
    my $tbl = tbl->new( -class=>'td_wide td_medium pretty', -head=>'head', -row1=>'rowA', -row2=>'rowB' );
    my %header = %{$lang::admin->{fields}};
    while( my %p = $db->line )
    {
        my %priv = map{ $_ => 1 } grep{ $_ } split ',', $p{privil};
        my $url_op = $edt_priv && [ url->a( $lang::lbl_operations, a=>'ajAdmin', aid=>$p{id}, login=>$p{login}, , '-data-ajax-into-here'=>1 ) ];
        $tbl->add('*', [
            [ 'h_center',   'Id',               $p{id}      ],
            [ '',           $header{login},     $p{login}   ],
            [ '',           $header{name},      $p{name}    ],
            [ 'h_center',   $header{is_on},     $priv{1} && $lang::yes ],
            [ 'h_center',   $header{is_admin},  $priv{3} && $lang::yes ],
            [ 'h_center',   '',                 $url_op    ],
        ]);
    }
    Show $tbl->show;
}


sub edit
{
    my($Url, $edt_priv) = @_;
    my $aid = ses::input_int('aid');
    my %p = Db->line(
        "SELECT *, AES_DECRYPT(passwd,?) AS pass FROM admin WHERE id=?",
        $cfg::Passwd_Key, $aid
    );
    %p or Error L('admin_not_exists', $aid );

    my $tbl = tbl->new( -class=>'td_wide td_medium' );
    my %fields = %{$lang::admin->{fields}};

    $tbl->add('', 'll',
        $fields{login},
        [ v::input_t( name=>'login', value=>$p{login} ) ],
    );
    $edt_priv && $tbl->add('', 'll',
        $fields{password},
        [ v::input_t( name=>'pass', value=>'' ) ],
    );
    $tbl->add('', 'll',
        $fields{name},
        [ v::input_t( name=>'name', value=>$p{name} ) ],
    );

    # --- Привилегии ---
    my @privil = ();
    my @privil2 = ();
    foreach my $line( @{$lang::admin->{priv_descr}} )
    {
        if( $line->{no_buttons} )
        {
            push @privil2, $line->{priv} => $line->{title};
        }
         else
        {
            push @privil, $line->{priv} => $line->{title};
        }
    }
    my $privil = v::checkbox_list(
        name    => 'privil',
        list    => \@privil,
        checked => $p{privil},
        buttons => 1,
    );
    my $privil2 = v::checkbox_list(
        name    => 'privil',
        list    => \@privil2,
        checked => $p{privil},
    );

    $tbl->add('', 'll', '', [ $privil.$privil2 ]);
    $tbl->add('', 'C', [ _('[div txtpadding]', v::submit($lang::btn_save)) ]);
    my $form = $Url->form( act=>'save', aid=>$aid, $tbl->show );
    Show $form;
}


sub save
{
    my($Url, $edt_priv) = @_;
    my $aid = ses::input_int('aid');
    my @sqls = ();

    my $login = ses::input_trim('login') || 'admin '.int(rand() * 1000);

    my $privil = ses::input('privil');
    $privil =~ s/[^\d,]//g;
    my %privil = map{ $_ => 1 } grep{ $_ } split /,/, $privil;
    # Добавим привилегию 'Админ' суперадмину
    $privil{2} = 1 if $privil{3};
    $privil = join ',', keys %privil;
    $privil = ",$privil," if $privil;

    my %p = Db->line('SELECT * FROM admin WHERE id=?', $aid) or Error($lang::err_try_again);

    my $changed = {};

    my $name = ses::input_trim('name');
    my @sql = (
        'UPDATE admin SET login=?, name=?, privil=?',
        $login, $name, $privil,
    );
    if( my $pass = ses::input('pass') )
    {
        $sql[0] .= ', passwd=AES_ENCRYPT(?,?)';
        push @sql, $pass, $cfg::Passwd_Key;
        $changed->{pass} = '***';
    }

    $sql[0] .= ' WHERE id=?';
    push @sql, $aid;

    $changed->{login} = "$p{login} → $login" if $p{login} ne $login;
    $changed->{name} = "$p{name} → $name" if $p{name} ne $name;

    my %old_priv = map{ $_ => 1 } grep{ $_ } split /,/, $p{privil};
    my @add_priv = ();
    foreach my $priv( grep{ $_ } split /,/, $privil )
    {
        exists $old_priv{$priv}? delete $old_priv{$priv} : push @add_priv, $priv;
    }
    my @sub_priv = keys %old_priv;
    $changed->{add_priv} = join ', ', @add_priv if scalar @add_priv;
    $changed->{sub_priv} = join ', ', @sub_priv if scalar @sub_priv;

    my $rows;
    {
        Db->begin_work or last;

        $rows = Db->do(@sql);
        $rows < 1 && last;
    }
    if( $rows < 1 || !Db->commit )
    {
        Db->rollback;
        Error($lang::err_try_again);
    };

    ToLog L('изменил данные админа id=[], priv: []', $aid, $privil);
    $Url->redirect( act=>'edit', aid=>$aid, -made=>$lang::msg_Changes_saved );
}


# --- Создание админа ---

sub new
{
    my($Url, $edt_priv) = @_;
    if( $ses::ajax )
    {
        my $msg = _('[p][][]',
            L('admin_create_question'),
            $Url->a($lang::yes, act=>'new'),
            $Url->a($lang::no,  act=>'list'),
        );
        push @$ses::cmd, {
            id   => ses::input('domid') || 'modal_window',
            data => _('[div small_info close]', $msg),
        };
        return 1;
    }

    my($rows, $aid);
    {
        Db->begin_work or last;

        $rows = Db->do(
            "INSERT INTO admin SET login=CONCAT('admin ', FLOOR(RAND()*1000000)), ".
            "passwd='', name='', privil=''"
        );
        $rows < 1 && last;
        $aid = Db::result->insertid;
    }
    if( $rows < 1 || !Db->commit )
    {
        Db->rollback;
        Error($lang::err_try_again);
    }

    ToLog( L('User id=[] created', $aid) );

    $Url->redirect( act=>'edit', aid=>$aid, -made=>L('admin_is_created') );
}

# --- Удаление админа (ajax) ---

sub del
{
    my($Url, $edt_priv) = @_;
    my $aid = ses::input_int('aid');
    Adm->id == $aid && return push @$ses::cmd, { id=>'modal_window', data=>'Суицид?' };
    my $url = $Url->new();
    $url->{aid} = $aid;
    $url->{login} = ses::input('login');
    # Если запрос ajax - спросим подтверждение
    if( $ses::ajax )
    {
        my $msg = L('admin_del_question', ses::input('login'));
        my $url_yes = ses::input('sure') ?
            $url->a('Удалить?', act=>'del', -class=>'nav error' ) :
            $url->a($lang::yes, act=>'del', sure=>1, -class=>'nav', domid=>ses::input('domid'), -ajax=>1 );
        $msg = Center _('[p][div h_center]',
            $msg, $url_yes.' '.$url->a($lang::no,  act=>'list', -class=>'nav' ),
        );
        push @$ses::cmd, {
            id   => ses::input('domid') || 'modal_window',
            data => _('[div small_info close]', $msg),
        };
        return 1;
    }

    my $rows = Db->do("DELETE FROM admin WHERE id=? LIMIT 1", $aid);
    $rows < 1 && Error($lang::err_try_again);

    Db->do("DELETE FROM websessions WHERE role='admin' AND uid=?", $aid);

    ToLog( L('User id=[] deleted', $aid) );

    $url->redirect( act=>'list', -made=>L('admin_is_deleted') );
}

1;