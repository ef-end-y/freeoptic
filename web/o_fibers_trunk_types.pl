# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package op;
use strict;
use Debug;

my $new = {
    name        => L('типа магистрали'),
    table       => 'fibers_trunk_types',
    field_id    => 'id',
    priv_show   => 'on',
    priv_edit   => 'SuperAdmin',
    sql_get     => 'SELECT * FROM fibers_trunk_types WHERE id=?',
    menu_create => L('Новый тип магистрали'),
    menu_list   => L('Все типы магистрали'), 
};


sub o_start
{
 my $menu = $new->{menu} ||= [];
 return $new;
}

sub o_list
{
 my($d) = @_;
 Doc->template('top_block')->{title} = L('Магистрали');

 my $url = $d->{url}->new();
 my $sql = ['SELECT * FROM fibers_trunk_types'];

 if( my $type = ses::input_int('type') )
 {
    $url->{type} = $type;
    ToTop L('Тип: [filtr]', $lang::mYamap_link_type->{$type} || $type);
    $sql->[0] .= ' WHERE type=?';
    push @$sql, $type;
 }

 if( my $state = ses::input_int('state') )
 {
    $url->{state} = $state;
    ToTop L('Состояние: [filtr]', $lang::mYamap_link_state->{$state} || $state);
    $sql->[0] .= ' WHERE state=?';
    push @$sql, $state;
 }

 $sql->[0] .= ' ORDER BY id';
 my($sql, $page_buttons, $rows, $db) = main::Show_navigate_list($sql, ses::input_int('start'), 22, $url);

 if( $rows<1 )
 {
    my $msg = $url->{type} ?  L('Данного типа магистралей нет') :
        $url->{state} ? L('В выбранном состоянии магистралей нет') : '';
    $msg ? Error($msg) : return;
 };

 my $tbl = $d->{tbl};
 $tbl->add('head td_tall', 'cllccC',
    L('id'),
    L('Тип'),
    L('Название'),
    L('Состояние'),
    L('Операции'),
 );

 while( my %p = $db->line )
 {
    $tbl->add('*', 'cllcccc',
        $p{id},
        $lang::mYamap_link_type->{$p{type}},
        $p{name},
        $lang::mYamap_link_state->{$p{state}},
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
    'магистрали [filtr|commas] № [filtr]',
    $lang::mYamap_link_type->{$d->{d}{type}} || L('без типа'), $d->{d}{id}
 );
}

sub o_new
{
}

sub o_show
{
 my($d) = @_;
 my @menu = ();

 my $tbl = tbl->new( -class=>'td_wide td_tall pretty' );

 my $type_list = v::select(
    name     => 'type',
    size     => 1,
    selected => $d->{d}{type},
    options  => { ''=>'', %$lang::mYamap_link_type },
 );

 $tbl->add('','ll',
    L('Имя магистрали'),
    [ v::input_t( name=>'name', value=>$d->{d}{name}) ],
 );

 $tbl->add('','ll',
    'Тип',
    [ $type_list ],
 );

 my $state_list = v::select(
    name     => 'state',
    size     => 1,
    selected => $d->{d}{state},
    options  => { ''=>'', %$lang::mYamap_link_state },
 );

 $tbl->add('','ll',
    L('Состояние'),
    [ $state_list ],
 );
 if( $d->chk_priv('priv_edit') )
 {
    $tbl->add('','C', [ v::submit($lang::btn_save) ]);
    push @menu, '<br>', $d->{url}->a($lang::btn_delete, op=>'del');
 }

 Show Center $d->{url}->form( id=>$d->{id}, $tbl->show );

 ToRight Menu( @menu );
}

sub o_update
{
 my($d) = @_;

 $d->{sql} .= 'SET name=?, state=?, type=?, comment=?';

 push @{$d->{param}}, v::trim(ses::input('name'));
 push @{$d->{param}}, ses::input_int('state');
 push @{$d->{param}}, ses::input_int('type');
 push @{$d->{param}}, ses::input('comment');
}

sub o_insert
{
 return o_update(@_);
}


1;