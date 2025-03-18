# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package op;
use strict;
use Debug;

my $new = {
    name        => L('магистрали'),
    table       => 'fibers_trunks',
    field_id    => 'id',
    priv_show   => 'on',
    priv_edit   => 'on',
    allow_copy  => 1,
    sql_get     => 'SELECT * FROM fibers_trunks WHERE id=?',
    menu_create => L('Новая магистраль'),
    menu_list   => L('Все магистрали'), 
};


sub o_start
{
 my $menu = $new->{menu} ||= [];
 my $gid = ses::input('gid');
 $cfg::fibers_collective_data = 0;
 if( !$cfg::fibers_collective_data )
 {
    my $user_id = $ses::auth->{adm}{uid};
    my %p = Db->line(
       "SELECT id, uid, shared FROM fibers_schemes WHERE is_block=0 AND gid=? AND (shared>0 OR uid=?)", $gid, $user_id
    );
    %p or Error('Access denied');
    $new->{_scheme_id} = $p{id};
    $new->{url_params}{gid} = $gid;
    $new->{priv_edit} = 'SuperAdmin' if $p{shared} < 2 && $p{uid} != $user_id;
 }
 return $new;
}

sub o_list
{
 my($d) = @_;
 Doc->template('top_block')->{title} = L('Trunks');

 my $url = $d->{url}->new();
 my $sql = [
    'SELECT *, (SELECT SUM(`length`) FROM fibers_cables WHERE trunk=fibers_trunks.id) AS `length`'.
    'FROM fibers_trunks WHERE TRUE'
 ];
 if( !$cfg::fibers_collective_data )
 {
   $sql->[0] .= ' AND scheme_id=?';
   push @$sql, $d->{_scheme_id};
 }

 my($sql, $page_buttons, $rows, $db) = main::Show_navigate_list($sql, ses::input_int('start'), 22, $url);

 if( $rows<1 )
 {
    my $msg = $url->{type} ?  L('Данного типа магистралей нет') :
        $url->{state} ? L('В выбранном состоянии магистралей нет') : '';
    $msg ? Error($msg) : return;
 };

 my $name_field = $cfg::Lang eq 'RU' ? 'name_ru' : 'name_uk';

 my $tbl = $d->{tbl};
 $tbl->add('head td_tall', 'cl3',
    L('id'),
    L('Название'),
    L('Длина'),
    $lang::lbl_operations,
 );

 while( my %p = $db->line )
 {
    $tbl->add('*', 'clccc',
        $p{id},
        $p{$name_field},
        $p{length},
        $d->btn_edit($p{id}),
        $d->btn_copy($p{id}),
        $d->btn_del($p{id}),
    );
 }

 Show $page_buttons.$tbl->show.$page_buttons;
}


sub o_edit
{
 my($d) = @_;
 $d->{name_full} = L(
    'магистрали [filtr|commas] № [filtr]', $d->{d}{name_uk}, $d->{d}{id}
 );
}

sub o_new
{
}

sub o_show
{
 my($d) = @_;

 my $tbl = tbl->new( -class=>'td_wide td_tall pretty' );

 $tbl->add('', 'll',
    L('Имя магистрали на украинском'),
    [ v::input_t( name=>'name_uk', value=>$d->{d}{name_uk}) ],
 );

 $tbl->add('', 'll',
    L('Имя магистрали на русском'),
    [ v::input_t( name=>'name_ru', value=>$d->{d}{name_ru}) ],
 );

 $tbl->add('tune_tbl', 'll',
    L('Комментарий'),
    [ v::input_ta('comment', $d->{d}{comment}, 60, 4) ],
 );
 if( $d->chk_priv('priv_edit') )
 {
    $tbl->add('','C', [ v::submit($lang::btn_save) ]);
 }

 Show $d->{url}->form( id=>$d->{id}, $tbl->show );
}

sub o_update
{
 my($d) = @_;

 $d->{sql} .= 'SET scheme_id=?, name_uk=?, name_ru=?, comment=?';

 my $name_uk = v::trim(ses::input('name_uk'));
 my $name_ru = v::trim(ses::input('name_ru'));
 $name_uk ||= $name_ru;
 $name_ru ||= $name_uk;

 push @{$d->{param}}, int $d->{_scheme_id};
 push @{$d->{param}}, $name_uk;
 push @{$d->{param}}, $name_ru;
 push @{$d->{param}}, ses::input('comment');
}

sub o_insert
{
 return o_update(@_);
}


1;