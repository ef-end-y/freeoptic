#!/usr/bin/perl
# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
=head

Порядок вызова:

o_start ->

   o_list
   o_prenew     -> o_new  -> o_show
   o_precopy    -> o_edit -> o_show
   o_preedit    -> o_edit -> o_show
   o_preupdate  -> o_update -> o_postupdate -> o_postupdate_redirect
   o_preinsert  -> o_insert
   o_predel     -> o_postdel

Любой из вызовов может переопределяться в модуле o_<module>

=cut

sub go
{
  return op::go(@_);
}

package op;
use strict;
use Debug;

my %subs = (
  fibers_trunks => 2,
  fibers_trunk_types => 2,
  fibers_cable_types => 2,
  fibers_container_types => 2,
);

main->import( qw( _ L Error_Lang Error Show ToTop ToLeft ToRight Menu MessageBox MessageWideBox Center ) );

sub go
{
 my($Url) = @_;
 Doc->template('base')->{css_left_block} = 'block_with_menu';

 my $act = ses::input('act');
 my $url = $Url->new( act=>$act );

 exists $subs{$act} or Error_Lang('Неизвестная команда act = [filtr|bold]', $act);
 my $mod = $act;
 $mod =~ s/\d+$//;
 my $err_msg = main::Require_web_mod("o_$mod");
 $err_msg && Error($err_msg);

 my $d = op->o_start($url);
 bless $d;

 #   Получаем такие ключи:
 # name         : имя сущности в родительном падеже, например, 'записи в словаре'
 # table        : таблица БД
 # field_id     : имя ключевого поля, по которому происходит выборка уникального значения, обычно id
 # sql_get      : sql выборки значения по полю field_id (SELECT * FROM tbl WHERE id=?)
 # sql_all      : [ sql выборки всех значений ]
 # allow_copy   : разрешено ли копирование любой строки в таблице
 # menu_create  : название пункта меню создания ('Создать объект')
 # menu_list    : название пункта меню вывода списка всех объектов
 # menu         : массив с пунктами меню
 # priv_show    : имя привилегии для просмотра данных
 # priv_edit    : имя привилегии для изменения данных
 # keep_filters : фильтры, которые будут запомнены в url-е, после редактирования будут применены

 $d->{act} = $act;
 $d->{op}  = ses::input('op');
 $d->{id}  = ses::input('id');
 $d->{url} = $url;
 $d->{tbl} = tbl->new( -class=>'td_wide td_medium pretty', -head=>'head', -row1=>'row3', -row2=>'row3' );
 $d->{name_full} = $d->{name};
 $d->{errors} = [];
 $d->{field_id} ||= 'id';
 $d->{sql_get} ||= "SELECT * FROM $d->{table} WHERE  $d->{field_id}=?";

 map{ $d->{url}{$_} = $d->{url_params}{$_} } keys %{$d->{url_params}} if exists $d->{url_params};

 my $menu = $d->{menu} ||= [];

 unshift @$menu, [ $d->{menu_create}, op=>'new' ] if $d->{menu_create} && $d->chk_priv('priv_edit');
 unshift @$menu, [ $d->{menu_list}, op=>'list' ]  if $d->{menu_list};
 push @$menu, '<br>', [ $lang::Help, a=>'help', theme=>$d->{help_theme}, -ajax=>1 ] if $d->{help_theme};
 push @$menu, '<br>', [ L('Главные настройки'), a=>'tune' ] if Adm->chk_privil('Admin');

 map{ $d->{url}{$_} = $d->{url_params}{$_} } keys %{$d->{url_params}} if exists $d->{url_params};

 my $show_menu = join '', map{ ref $_ eq 'ARRAY' ? $url->a(@$_) : $_ } grep{ $_ } @$menu;

 main::Doc->template('base')->{top_lines} .= url->a('↔', '-id'=>'hide_left_block', '-data-show-or-hide'=>'left_block,right_block', -base=>'#');
 ToLeft( _('[div navmenu]', $show_menu) );

 my %subs_op = (
    edit   => $d->chk_priv('priv_edit') ? L('Изменение') : L('Просмотр'),
    new    => L('Создание'),
    update => L('Сохранение'),
    insert => L('Сохранение'),
    del    => L('Удаление'),
    copy   => L('Создание копии'),
 );

 my $method;
 if( $d->{op} && exists $d->{addsub} && exists $d->{addsub}{_$d->{op}} )
 {
    $method = "addsub_$d->{op}";
 }
  elsif( $d->{op} && defined($d->{"addsub_$d->{op}"}) )
 {
    $method = "addsub_$d->{op}";
 }
  elsif( $subs_op{$d->{op}} )
 {
    $method = 'o_pre'.$d->{op};
    $d->{name_action} = $subs_op{$d->{op}};
    Doc->template('top_block')->{title} = $d->{name_action}.' '.$d->{name};
 }
  else
 {
    $d->{op} = 'list';
    $method = 'o_list';
    $d->chk_priv('priv_show') or $d->error_priv(L('Нет привилегии []', $d->{priv_show}));
 }

 $d->$method();
}

sub chk_priv
{
 my($d, $priv) = @_;
 my $priv = $d->{$priv};
 $priv = [ $priv ] if ! ref $priv;
 foreach my $i( @$priv )
 {
    Adm->chk_privil($i) && return 1;
 }
 return '';
}

sub error_priv
{
 my($d, $debug_msg) = @_;
 defined $debug_msg && debug('warn', $debug_msg);
 Error($lang::err_no_priv);
}


sub o_predel
{
 my($d) = @_;
 $d->chk_priv('priv_edit') or $d->error_priv();
 $d->o_getdata();
 $d->o_edit();
 $d->{no_delete} && Error(L('Удаление [] заблокировано системой, поскольку []', $d->{name_full}, $d->{no_delete}));

 ses::input_int('now') or Error(
    _('[] [][hr space][div h_center]',
        L('Удаление'), $d->{name_full}, '', $d->{url}->form(op=>'del', id=>$d->{id}, now=>1, v::submit($lang::btn_Execute))
    )
 );
 my $ok = Db->do_all(
    [ "DELETE FROM $d->{table} WHERE $d->{field_id}=? LIMIT 1", $d->{id} ],
    [ "INSERT INTO changes SET act='delete', new_data='', time=UNIX_TIMESTAMP(), tbl=?, fid=?, adm=?, old_data=?",
        $d->{table}, $d->{id}, Adm->id, Debug->dump($d->{d}) ],
 );
 $ok or Error(L('Удаление [] НЕ выполнено.', $d->{name_full}));
 $d->o_postdel();
 my $made_msg = $d->{del_made_msg} || L('Удаление [] выполнено', $d->{name_full});
 $d->{url}->redirect(op=>'list', -made=>$made_msg);
}

sub o_postdel
{
}

sub o_prenew
{
 my($d) = @_;
 $d->chk_priv('priv_edit') or $d->error_priv();
 $d->{id} = 0;
 $d->{d} = {};
 $d->o_new();
 $d->{url}{op} = 'insert';
 $d->{url}{id} = 0;
 $d->{save_button} = v::submit($lang::btn_Create);
 $d->o_show();
}

sub o_new
{
}

sub o_precopy
{
 my($d) = @_;
 $d->chk_priv('priv_edit') or $d->error_priv();
 $d->{allow_copy} or $d->error_priv();
 $d->o_getdata();
 $d->o_edit();
 $d->{id} = 0;
 $d->{url}{op} = 'insert';
 $d->{url}{id} = 0;
 $d->{save_button} = v::submit($lang::btn_Create);
 $d->o_show();
}

sub o_copy
{
}

sub o_preedit
{
 my($d) = @_;
 $d->chk_priv('priv_show') or $d->error_priv();
 $d->o_getdata();
 $d->o_edit();
 if( $d->{no_edit} )
 {
    debug($d->{no_edit});
    $d->{priv_edit} = 0;
 }
 $d->{url}{op} = 'update';
 $d->{url}{id} = $d->{id};
 $d->{save_button} = $d->chk_priv('priv_edit')? v::submit($lang::btn_save) : '';
 if( exists $d->{keep_filters} )
 {
   foreach my $filter( @{$d->{keep_filters}} )
   {
      my $filter = "_FILTER_$filter";
      ses::input_exists($filter) or next;
      $d->{url}{$filter} = ses::input($filter);
   }
 }
 $d->o_show();
}

sub o_edit
{
}

sub o_show
{
 my($d) = @_;
 my $lines = [];
 foreach my $k( keys %{$d->{d}} )
 {
    push @$lines, { type=>'text', value=>$d->{d}{$k}, name=>$k, title=>$k};
 }
 $d->chk_priv('priv_edit') && push @$lines, { type=>'submit', value=>$lang::btn_save};
 my $form = $d->{url}->form($lines);
 $form = _('[div wide_input txtpadding]', $form);
 Show( MessageBox( $form ) );
}

sub o_preupdate
{
 my($d) = @_;
 $d->chk_priv('priv_edit') or $d->error_priv();
 $d->o_getdata();
 $d->{param} = [];
 $d->{add_sql} = [];
 $d->{add_end_sql} = [];
 $d->o_update();
 my $sql = $d->{sql};
 push @{$d->{param}}, $d->{id};
 push @{$d->{add_sql}}, [ "UPDATE $d->{table} $sql WHERE $d->{field_id}=? LIMIT 1", @{$d->{param}} ];
 push @{$d->{add_sql}}, @{$d->{add_end_sql}} if scalar @{$d->{add_end_sql}};
 my $ok = Db->do_all( @{$d->{add_sql}} );
 $ok or Error( _('[] [] [span error].', L('Запрос на изменение'), $d->{name_full}, L('не выполнен')) );
 # Если при сохранении данных мы изменили поле идентифицирующее запись
 my $new_id = exists $d->{new_id}? $d->{new_id} : $d->{id};
 my %p = Db->line($d->{sql_get}, $new_id);
 my $new_data = %p? Debug->dump(\%p) : '';
 my $old_data = Debug->dump($d->{d});
 Db->do(
    "INSERT INTO changes SET act='edit', time=UNIX_TIMESTAMP(), tbl=?, fid=?, adm=?, new_data=?, old_data=?",
    $d->{table}, $d->{id}, Adm->id, $new_data, $old_data,
 );
 $d->o_postupdate();
 my $made_msg = join '. ', $lang::msg_Changes_saved, @{$d->{errors}};
 my $postupdate_redirect = $d->o_postupdate_redirect($new_id);
 $d->{url}->redirect(%$postupdate_redirect, -made=>$made_msg, -error=>scalar @{$d->{errors}}? 1 : 0 );
}

sub o_update
{
 my($d) = @_;
 $d->{sql} .= 'SET ';
 my @keys = ();
 foreach my $k( keys %{$d->{d}} )
 {
    push @keys, "$k=?";
    push @{$d->{param}}, ses::input($k);
 }
 $d->{sql} .= join ',', @keys;
}

sub o_postupdate
{
}

sub o_postupdate_redirect
{
 my($d, $id) = @_;
 return { op=>'edit', id=>$id } if $id && $d->{op} ne 'update';
 my $params = { op=>'list' };
 if( exists $d->{keep_filters} )
 {
   foreach my $filter( @{$d->{keep_filters}} )
   {
      my $kept_filter = "_FILTER_$filter";
      ses::input_exists($kept_filter) or next;
      $params->{$filter} = ses::input($kept_filter);
   }
 }
 return $params;
}

sub o_preinsert
{
 my($d) = @_;
 $d->chk_priv('priv_edit') or $d->error_priv();
 $d->{param} = [];
 $d->{add_sql} = [];
 $d->o_insert();
 my $sql = $d->{sql};
 push @{$d->{add_sql}}, [ "INSERT INTO $d->{table} $sql", @{$d->{param}} ];
 my $ok = Db->do_all( @{$d->{add_sql}} );
 $ok or Error( _('[] [] [span error]', L('Создание'), $d->{name}, L('не выполнено')) );
 my $id = exists $d->{new_id}? $d->{new_id} : Db::result->insertid;
 if( $id )
 {
    my %p = Db->line($d->{sql_get}, $id);
    my $new_data = %p? Debug->dump(\%p) : '';
    Db->do(
        "INSERT INTO changes SET act='create', old_data='', time=UNIX_TIMESTAMP(), tbl=?, fid=?, adm=?, new_data=?",
        $d->{table}, $id, Adm->id, $new_data,
    );
 }
 $d->o_postinsert($id);
 $d->{url}->redirect( op=>'edit', id=>$id, -made=>L('Создано') );
}

sub o_insert
{
 my($d) = @_;
 $d->{sql} .= "SET $d->{field_id}=$d->{field_id}";
}

sub o_postinsert
{
}

sub o_list
{
 my($d) = @_;
 my $sql = $d->{sql_all} || "SELECT * FROM $d->{table} ORDER BY $d->{field_id}";
 my($sql, $page_buttons, $rows, $db) = main::Show_navigate_list($sql, ses::input_int('start'), 22, $d->{url});
 $rows or $d->{url}->redirect(op=>'new', -made=>L('Пока еще не создано ни одной записи []', $d->{name}));
 my $tbl = tbl->new( -class=>'td_wide pretty' );
 my(%p, $cols);
 while( my %p = $db->line )
 {
    if( !$cols )
    {
        my @keys = sort{ $a cmp $b } keys %p;
        $cols ||= 'l' x (scalar @keys + 2);
        $tbl->ins('head', $cols, @keys, '', '');
    }
    my @vals = map{ $p{$_} } sort{ $a cmp $b } keys %p;
    $tbl->add('*', $cols,
        @vals,
        $d->btn_edit($p{$d->{field_id}}),
        $d->btn_del($p{$d->{field_id}}),
    );
 }
 Show( MessageBox( $page_buttons.$tbl->show.$page_buttons) );
}

sub o_getdata
{
 my($d) = @_;
 my %p = Db->line($d->{sql_get}, $d->{id});
 Db->ok or Error($lang::err_try_again);
 if( !%p )
 {  # удалена ли запись?
    %p = Db->line("SELECT time, adm FROM changes WHERE act='delete' AND tbl=? AND fid=?", $d->{table}, $d->{id});
    if( %p )
    {
        my $time = main::the_short_time($p{time}, 1); # здесь единица указывает вставлять слово `сегодня`, если надо
        my $admin = Adm->get($p{adm})->admin;
        $d->{url}->redirect( op=>'list',
            -made=>L('[] запись № [] была удалена администратором [bold]', $time, $d->{id}, $admin)
        );
    }
    $d->{url}->redirect( op=>'list', -made=>L('Ошибка получения данных записи номер []', $d->{id}), -error=>1);
 }
 $d->{d} = \%p;
}

sub btn_edit
{
 my($d, $id) = @_;
 my $btn_title = $d->chk_priv('priv_edit')? L('Изменить') : L('Смотреть');
 my %params = (op=>'edit', id=>$id);
 if( exists $d->{keep_filters} )
 {
   foreach my $filter( @{$d->{keep_filters}} )
   {
      ses::input_exists($filter) or next;
      $params{"_FILTER_$filter"} = ses::input($filter);
   }
 }
 return[ $d->{url}->a($btn_title, %params) ];
}

sub btn_copy
{
 my($d, $id) = @_;
 $d->chk_priv('priv_edit') or return '';
 return[ $d->{url}->a(L('Копия'), op=>'copy', id=>$id) ];
}

sub btn_del
{
 my($d, $id) = @_;
 $d->chk_priv('priv_edit') or return '';
 return[ $d->{url}->a(L('Удалить'), op=>'del', id=>$id) ];
}

1;
