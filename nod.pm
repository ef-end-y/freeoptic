# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;
use Time::HiRes qw( clock_gettime CLOCK_MONOTONIC );
use Getopt::Long;
use Debug;
use Db;
use nod::tasks;

my $help_msg = 
<<HELP;
    -v      : verbose
    -vv     : very verbose
    -d      : demonize
    -f=file : log file, default {{file_log}}
    -c=file : config file, default {{file_cfg}}
HELP

my $terminate;

sub new
{
    my($class, %param) = @_;
    my $new = {%param};
    bless $new, $class;
    return $new;
}

sub Start
{
    my($M) = @_;

    $M->{uniq_process_id} = int rand(10**8);

    $_ = $help_msg;
    s/\{\{ *file_log *\}\}/$M->{file_log}/;
    s/\{\{ *file_cfg *\}\}/$M->{file_cfg}/;

    $M->{help_msg} .= $_;

    $cfg::dir_home = $INC{'nod.pm'};
    $cfg::dir_home =~ s|/+[^/]+$|| or die 'cannot get nodeny dir';
    $cfg::dir_log = $cfg::dir_home.'/logs/';

    $M->{cmd_line_options} ||= {};
    
    my($v, $vv, $demonize, $help);
    GetOptions(
        'v'      => \$v,
        'vv'     => \$vv,
        'f=s'    => \$M->{file_log},
        'c=s'    => \$M->{file_cfg},
        'd'      => \$demonize,
        'h'      => \$help,
        %{$M->{cmd_line_options}}
    );

    $M->{demonize} = $demonize;
    $M->{log_prefix} = $demonize ? "[$M->{uniq_process_id}]" : undef;

    $cfg::verbose = $vv? 2 : $v? 1 : 0;

    if( $M->{file_log} !~ m|^/| )
    {
        -d $cfg::dir_log or die "run:\nmkdir $cfg::dir_log && perl install.pl -w=www\n";
        $M->{file_log} = $cfg::dir_log.($M->{file_log} || $M->{default_log} || 'common.log');
    }

    $M->{file_cfg} = $cfg::dir_home.'/'.$M->{file_cfg} if $M->{file_cfg} !~ m|^/|;

    if( $help )
    {
        print $M->{help_msg};
        exit 1;
    }

    Debug->param(
        -type     => $demonize? 'file' : 'console',
        -file     => $M->{file_log},
        -nochain  => $cfg::verbose<2,
        -only_log => $cfg::verbose<1,
    );

    $SIG{TERM} = $SIG{INT} = sub
    {
        tolog("Got the $_[0] sign");
        $terminate = 1;
    };

    $SIG{'__DIE__'} = sub
    {
        die @_ if $^S; # die внутри eval
        my($err) = @_;
        eval { Hard_exit(undef, $err) };
        $err .= "\n\n".$@;
        eval {
            open(my $f, '>>/tmp/nod_die.log');
            $f && print $f $err;
        };
        print $err;
        exit;
    };

    if( $demonize )
    {
        open(STDOUT, '>>', $M->{file_log});
        open(STDERR, '>>', $M->{file_log});
    }

    tolog($M->{log_prefix}, "Start. Flag -h for help");
    tolog($M->{log_prefix}, "Loading $M->{file_cfg}");
    eval "
        require '$M->{file_cfg}';
    ";
    $@ && die $@;

    Db->new(
        host    => $cfg::Db_server,
        user    => $cfg::Db_user,
        pass    => $cfg::Db_pw,
        db      => $cfg::Db_name,
        timeout => $cfg::Db_connect_timeout,
        tries   => 3, # попыток с интервалом в секунду соединиться
        global  => 1, # создать глобальный объект Db, чтобы можно было вызывать абстрактно: Db->sql()
        pool    => $cfg::Db_pool || [],
    );

    nod::tasks->register_term_sub( \&Is_terminated );
}

sub Hard_exit
{
    my(undef, $msg) = @_;
    tolog($msg);
    sleep 2;
    exit 1;
}

sub Time
{
    return clock_gettime(CLOCK_MONOTONIC);
}

sub Is_terminated
{
    return $terminate;
}

sub Error
{
    my(undef, $type, $err, $debug) = @_;
    # Регистрируем ошибку в логах не чаще раз в 5 минут для каждого типа ошибки
    nod::tasks->protect_time(5*60, "<error type $type>") or return;
    $debug ||= Debug->self();
    $debug->tolog('!', $err);
}

1;