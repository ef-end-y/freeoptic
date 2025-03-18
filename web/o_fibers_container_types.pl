# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package op;
use strict;
use Debug;

my $new = {
    name        => L('типа контейнера'),
    table       => 'fibers_container_types',
    field_id    => 'id',
    priv_show   => 'on',
    priv_edit   => 'on',
    allow_copy  => 1,
    sql_get     => 'SELECT * FROM fibers_container_types WHERE id=?',
    menu_create => L('Новый тип'),
    menu_list   => L('Все типы контейнеров'), 
};


sub o_start
{
 my $menu = $new->{menu} ||= [];
 my $gid = ses::input('gid');
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
 Doc->template('top_block')->{title} = L('Container types');

 my $url = $d->{url}->new();
 my $sql = [
    'SELECT * FROM fibers_container_types WHERE TRUE'
 ];
 if( !$cfg::fibers_collective_data )
 {
   $sql->[0] .= ' AND scheme_id=?';
   push @$sql, $d->{_scheme_id};
 }

 my($sql, $page_buttons, $rows, $db) = main::Show_navigate_list($sql, ses::input_int('start'), 22, $url);

 my $tbl = $d->{tbl};
 $tbl->add('head td_tall', 'clcc3',
    L('id'),
    L('Тип'),
    L('Форма'),
    L('Размер'),
    $lang::lbl_operations,
 );

 while( my %p = $db->line )
 {
    my $font_size = ($p{size}-10)/2 + 10;
    $tbl->add('*', 'clccccc',
        $p{id},
        $p{type},
        [ _("[span style=color:#$p{color};font-family:Fontawesome;font-size:${font_size}px]", "\&#x$p{shape};") ],
        $p{size},
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
 $d->{name_full} = L('типа контейнера [filtr|commas]', $d->{d}{type});
}

sub o_new
{
}

sub o_show
{
 my($d) = @_;

 my $tbl = tbl->new( -class=>'td_wide td_tall pretty' );

 $tbl->add('', 'll',
    L('Тип контейнера'),
    [ v::input_t( name=>'type', value=>$d->{d}{type}) ],
 );

 $tbl->add('', 'll',
    L('Цвет на карте'),
    [ v::tag( 'input', type=>'color', name=>'color', value=>'#'.($d->{d}{color} || '000000') ) ],
 );

 my $shapes_list = v::select(
    name     => 'shape',
    size     => 1,
    selected => $d->{d}{shape},
    class    => 'big',
    style    => 'font-family: Fontawesome',
    options  => [
        map{ $_ => ["\&#x$_;"] } ('f111', 'f005', 'f0c8', 'f041', 'f2ce', 'f042', 'f013', 'f1cd', 'f185', 'f260', 'f007', 'f05c', 'f0c1')
    ],
 );

 $tbl->add('', 'll',
    L('Форма'),
    [ $shapes_list ],
 );

 $tbl->add('', 'll',
    L('Размер'),
    [ v::input_t( name=>'size', value=>$d->{d}{size} || 14) ],
 );

 $tbl->add('', 'll',
    L('Скрывать'),
    [ v::checkbox( name=>'hide_on_zoom', value=>1, checked=>$d->{d}{hide_on_zoom},
        label=>L('Скрывать при уменьшении масштаба географической карты') ) ],
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

 $d->{sql} .= 'SET scheme_id=?, type=?, color=?, shape=?, size=?, hide_on_zoom=?';

 push @{$d->{param}}, int $d->{_scheme_id};
 push @{$d->{param}}, v::trim(ses::input('type'));
 my $color = v::trim(ses::input('color'));
 $color =~ s/#//;
 push @{$d->{param}}, $color;
 push @{$d->{param}}, v::trim(ses::input('shape'));
 my $size = ses::input_int('size');
 $size = 20 if $size < 1 || $size > 80;
 push @{$d->{param}}, $size;
 push @{$d->{param}}, ses::input_int('hide_on_zoom') ? 1 : 0;
}

sub o_insert
{
 return o_update(@_);
}


1;