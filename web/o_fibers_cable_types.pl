# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package op;
use strict;
use Debug;

my $new = {
    name        => L('типа кабеля'),
    table       => 'fibers_cable_types',
    field_id    => 'id',
    priv_show   => 'on',
    priv_edit   => 'on',
    allow_copy  => 1,
    sql_get     => 'SELECT * FROM fibers_cable_types WHERE id=?',
    menu_create => L('Новый тип'),
    menu_list   => L('Все типы кабелей'), 
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
 Doc->template('top_block')->{title} = L('Cable types');

 my $url = $d->{url}->new();
 my $sql = [
    'SELECT * FROM fibers_cable_types WHERE TRUE'
 ];
 if( !$cfg::fibers_collective_data )
 {
   $sql->[0] .= ' AND scheme_id=?';
   push @$sql, $d->{_scheme_id};
 }

 my($sql, $page_buttons, $rows, $db) = main::Show_navigate_list($sql, ses::input_int('start'), 22, $url);

 my $tbl = $d->{tbl};
 $tbl->add('head td_tall', 'cl3',
    L('id'),
    L('Тип'),
    L('Цвет на карте'),
    $lang::lbl_operations,
 );

 while( my %p = $db->line )
 {
    $tbl->add('*', 'clccc',
        $p{id},
        $p{type},
        [ _("[div style=background-color:#$p{color};width:30px;height:10px]", '') ],
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
 $d->{name_full} = L('типа кабеля [filtr|commas]', $d->{d}{type});
}

sub o_new
{
}

sub o_show
{
 my($d) = @_;

 my $tbl = tbl->new( -class=>'td_wide td_tall pretty' );

 $tbl->add('', 'll',
    L('Тип кабеля'),
    [ v::input_t( name=>'type', value=>$d->{d}{type}) ],
 );

 $tbl->add('', 'll',
    L('Цвет на карте'),
    [ v::tag( 'input', type=>'color', name=>'color', value=>'#'.($d->{d}{color} || '000000') ) ],
 );

 $tbl->add('', 'll',
    L('Толщина линии на карте'),
    [ v::input_t( name=>'line_width', value=>$d->{d}{line_width}) ],
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

 $d->{sql} .= 'SET scheme_id=?, type=?, color=?, line_width=?';

 push @{$d->{param}}, int $d->{_scheme_id};
 push @{$d->{param}}, v::trim(ses::input('type'));
 my $color = v::trim(ses::input('color'));
 $color =~ s/#//;
 push @{$d->{param}}, $color;
 my $line_width = ses::input_int('line_width');
 $line_width = 2 if $line_width < 1;
 push @{$d->{param}}, $line_width;
}

sub o_insert
{
 return o_update(@_);
}


1;