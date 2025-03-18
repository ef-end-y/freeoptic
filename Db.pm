#!/usr/bin/perl
# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package Db;
use strict;
use Time::HiRes qw( gettimeofday tv_interval clock_gettime CLOCK_MONOTONIC );
use Debug;
use DBI;

our $Db;

my $def_connect = {
    PrintError => 0,
    RaiseError => 0,        # 1 - die при ошибке
    AutoCommit => 1,
};

my %defaults = (
    host    => 'localhost',
    pool    => [],
    port    => 3306,
    user    => 'root',
    pass    => '',
    db      => 'test',
    timeout => 3,
    tries   => 2,
    global  => 0,
    async   => 0,
    dsn     => '',
    dbh     => '',
);

sub self
{
 my $db = shift;
 return ref $db? $db : $Db;
}

sub new
{
 my $cls = shift;
 my %param = @_;
 my $db = {};
 bless $db;
 map{ $db->{$_} = exists $param{$_}? $param{$_} : ref $cls? $cls->{$_} : $defaults{$_} } keys %defaults;
 if( !grep{ $db->{host} eq $_ } @{$db->{pool}} )
 {
    unshift @{$db->{pool}}, $db->{host};
 }
 # Если объект создается как копия другого, то соединение с БД нужно новое
 $db->{dbh} = 0;
 $Db = $db if $db->{global};
 return $db;
}

sub is_connected
{
 my $db = shift;
 $db = $Db if ! ref $db;
 return !defined $db? 0 : $db->{dbh}? 1 : 0;
}

sub disconnect
{
 my $db = shift;
 $db = $Db if ! ref $db;
 $db->{dbh} = 0;
}

sub connect
{
 my $db = shift;
 $db = $Db if ! ref $db;
 $db->{do_reconnect} = 0;
 my $i = int $db->{tries};
 $i = 1 if $i<1;
 $db->{tries} = $i;
 # Пробуем $i раз соединиться с БД с интервалом 1 сек
 my $tm = [gettimeofday];
 CONNECT : while( 1 )
 {
    foreach my $host( @{$db->{pool}} )
    {
        $db->{dsn} = "DBI:mysql:database=$db->{db};host=$host;port=$db->{port};mysql_connect_timeout=$db->{timeout}";
        $db->{dbh} = DBI->connect($db->{dsn}, $db->{user}, $db->{pass}, $def_connect);
        $db->{dbh} && last CONNECT;
    }
    --$i or last;
    sleep 1;
 }
 if( $db->{dbh} )
 {
    debug('Connecting to',$db->{dsn},':', tv_interval($tm), 'sec');
    $db->{dbh}->do("SET NAMES 'utf8' COLLATE 'utf8_general_ci'");
 }
  else
 {
    debug('error','No DB connection,',$db->{dsn},':',$DBI::errstr);
 }
}

sub sql
{
 my $db = shift;
 my $param = shift;
 $db = $Db if ! ref $db;

 my %param = ref $param? %$param : ( sql=>$param, param=>[@_] );
 $param{db} = $db;

 $db->is_connected or $db->connect;
 # Предыдущий sql был с ошибкой, переконнектимся для перестраховки
 $db->{do_reconnect} && $db->connect;

 my $dbres = Db::result->new( \%param );

 # Если нет коннекта больше 300 сек, то сообщение в лог
 if( !$db->is_connected )
 {
    debug('error', 'mysql is disconnected');
    my $error_tm = clock_gettime(CLOCK_MONOTONIC);
    $db->{error_tm} ||= $error_tm;
    if( ($error_tm - $db->{error_tm}) > 300 )
    {
        tolog('error', "No DB connection: $db->{dsn}");
        $db->{error_tm} = 0;
    }
    return $dbres;
 }
 $db->{error_tm} = 0;

 $dbres->sql( \%param );
 $db->{do_reconnect} = 1 if !$dbres->ok;
 return $dbres;
}

# --- Выборка одной строки ---

sub line
{
 my $db = shift;
 my $dbres = $db->sql(@_);
 $dbres->{sth} or return ();
 my $p = $dbres->{sth}->fetchrow_hashref;
 return $p? %$p : ();
}

sub select_line
{
 return line(@_);
}

sub do
{
 my $db = shift;
 my $dbres = $db->sql(@_);
 return $dbres->rows;
}

sub begin_work
{
 my $db = shift;
 $db = $Db if ! ref $db;
 debug('start transaction');
 return $db->{dbh}->begin_work();
}

sub commit
{
 my $db = shift;
 $db = $Db if ! ref $db;
 debug('commit');
 return $db->{dbh}->commit();
}

sub rollback
{
 my($db,$msg) = @_;
 $db = $Db if ! ref $db;
 debug('warn', 'rollback'.($msg ne '' && " ($msg)"));
 return $db->{dbh}->rollback();
}

sub do_all
{
 my($db, @sqls) = @_;
 if( !$db->begin_work )
 {
    debug('warn', 'Db->begin_work fail');
    return 0;
 }
 foreach my $sql( @sqls )
 {
    if( $db->do(@$sql) < 1 )
    {
        $db->rollback("fail: $sql->[0]");
        return 0;
    }
 }
 $db->commit && return 1;
 $db->rollback('commit error');
 return 0;
}

sub ok
{
 return Db::result->ok;
}

sub rows
{
 return Db::result->rows;
}

sub dbh
{
 my $db = shift;
 $db = $Db if ! ref $db;
 return $db->{dbh};
}

sub filtr
{
 shift;
 local $_=shift;
 utf8::is_utf8($_) && utf8::encode($_);
 s|\\|\\\\|g;
 s|'|\\'|g;
 s|"|\\"|g;
 s|\r||g;
 return $_;
}

# -------------------------------------------

package Db::result;
use strict;
use Time::HiRes qw( gettimeofday tv_interval );
use Debug;
use DBI;

my $Dbres;

# Вход:
#   sql     : sql
#   param   : параметры для плейсхолдеров
#   comment : комментарий к sql
#   db      : ссылка на родителя - объект Db

sub new
{
 shift;
 $Dbres = shift;
 bless $Dbres;
 my $dbres = $Dbres;
 $dbres->{ok} = 0;
 $dbres->{rows} = -1;

 my $sql = $dbres->{sql};
 my $param = $dbres->{param} || [];

 if( !$sql )
 {
    debug('error', 'sql is required', $dbres);
    return $dbres;
 }

 my $show_sql = $sql;
 if( ref $param eq 'ARRAY' && scalar @$param > 0 )
 {
    my @q_param = map{ $dbres->{db}->{dbh}->quote($_) } @$param;
    $show_sql =~ s|\?|shift @q_param|eg;
 }
 $dbres->{show_sql} = $show_sql;

 return $dbres;
}

sub sql
{
 my $dbres = shift;
 $dbres = $Dbres if ! ref $dbres;

 my($sql, $param) = ($dbres->{sql}, $dbres->{param});

 my $attr = {};

 my $comment = $dbres->{comment};
 $comment .= "\n" if $comment;
 $comment .= $dbres->{show_sql};

 my $async = $dbres->{db}{async};

 $attr->{async} = 1 if $async;

 my $tm_sql = [gettimeofday];

 $dbres->{sth} = $dbres->{db}{dbh}->prepare($sql, $attr);
 $dbres->{ok} = $dbres->{sth}->execute(@$param) if $dbres->{sth};

 if( !$dbres->{ok} )
 {
    debug('pre','error', $DBI::errstr,"\n",{ sql=>$sql, param=>$param },"\n",$comment);
    return $dbres;
 }

 if( $async )
 {
    debug('ASYNC: '.$comment);
    return $dbres;
 }

 $dbres->{rows} = $dbres->{sth}->rows;

 $tm_sql = tv_interval($tm_sql);
 my $time = $tm_sql>0.00009? sprintf("%.4f",$tm_sql) : sprintf("%.8f",$tm_sql);

 $comment .= "\n"."Строк: $dbres->{rows}. Время выполнения sql: $time сек";
 debug($comment);

 return $dbres;
}

sub ok
{
 my $dbres = shift;
 $dbres = $Dbres if ! ref $dbres;
 return $dbres->{ok};
}

sub rows
{
 my $dbres = shift;
 $dbres = $Dbres if ! ref $dbres;
 return $dbres->{rows};
}

sub sth
{
 my $dbres = shift;
 $dbres = $Dbres if ! ref $dbres;
 return $dbres->{sth};
}

sub insertid
{
 my $dbres = shift;
 $dbres = $Dbres if ! ref $dbres;
 return $dbres->{sth}? $dbres->{sth}->{mysql_insertid} : 0;
}

sub line
{
 my $dbres = shift;
 $dbres = $Dbres if ! ref $dbres;
 $dbres->{row} = undef;
 $dbres->{sth} or return ();
 my $p = $dbres->{row} = $dbres->{sth}->fetchrow_hashref;
 return $p? %$p : ();
}

sub get_line
{
 return line(@_);
}

1;

__END__

Если методы запускаются без объекта, то берется т.н. глобальное соединение

    2 формата вызова:
1) Db->sql( sql, параметры для плейсхолдеров )
2) Db->sql({ параметры })

    Если необходима выборка только одной строки:

my %p = Db->line( параметры );

Хеш %p пустой если:
1) пустая выборка
2) произошла ошибка (неверный sql, дисконнект БД,...)

Чтобы уточнить: Db->ok возвращает 1, если не было ошибок

    Выборка одной строки:

my %p = Db->line("SELECT * FROM users WHERE id=? AND grp=?", $id, $grp);
print %p? "$p{name}, $p{fio}" : Db->ok? 'пустая выборка' : 'внутренняя ошибка';

    Выборка нескольких строк:

my $db = Db->sql("SELECT id, name FROM users WHERE field=?", $unfiltered_field);
while( my %p = $db->line )
{
    print "$p{id} = $p{name}\n";
}

    Выборка нескольких строк с иным форматом вызова:

my $db = Db->sql(
    sql     => "SELECT * FROM tbl WHERE field=? AND val=?",
    param   => [ $filed, $val ],
    comment => 'Выборка номер 2',
);
while( my %p = $db->line ) { ... }

    Update/Insert:
 
my $rows = Db->do("UPDATE websessions SET uid=?, role=? WHERE ses=? LIMIT 1", $id, $role, $ses);
$rows>0 or Error('!'); # не делайте $rows or Error() т.к. rows может = -1


    Выполнение нескольких запросов в транзакции:

Db->do_all(
    [$sql1, $param1, $param2 ],
    [$sql2, $param3 ],
);

Проверяется, что каждый запрос затронул как минимум 1 строку. Внимание! Если запрос выполнился,
но не затронул ни одну строку (ни одного совпадение по условию WHERE), то будет откат транзакции.

--- Полный пример ---

Db->new(
    host    => $cfg::Db_server,
    port    => 3306,
    user    => $cfg::Db_user,
    pass    => $cfg::Db_pw,
    db      => $cfg::Db_name,
    timeout => $cfg::Db_mysql_connect_timeout,
    tries   => 3, # попыток с интервалом в секунду соединиться
    global  => 1, # создать глобальный объект Db, чтобы можно было вызывать абстрактно: Db->sql()
);

Db->is_connected or die 'No DB connection';

my $ok = Db->do_all(
    ["UPDATE ... WHERE ...", $param1, $param2 ],
    ["UPDATE ... WHERE ...", $param3 ],
    ["UPDATE ... WHERE ...", $param4 ],
);

$ok or print "Как минимум 1 запрос (или commit) не выполнился - все sql откатаны rollback-ом";

Для Db->new можно опустить любой из параметров - возьмутся дефолтные, см. %defaults

-- Соединение с теми же параметрами, что и $db1, но на порт 666 и бд test

my $db1 = Db->new( ... );
my $db2 = $db1=>new( port=>666, db=>'test' );
