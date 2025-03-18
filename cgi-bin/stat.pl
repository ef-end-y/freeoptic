#!/usr/bin/perl
# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;
use Time::HiRes qw( gettimeofday tv_interval );
BEGIN {
    $ses::gettimeofday = [gettimeofday];
}

$cfg::main_config = '/usr/local/freeoptic/freeoptic.cfg';

$ses::debug = 0; # Do not change this for sucurity reason

$ses::api = 0;
$ses::ajax = lc($ENV{HTTP_X_REQUESTED_WITH}) eq 'xmlhttprequest';
$cfg::main_config = "$ENV{FREEOPTIC_ROOT}/sat.cfg" if $ENV{FREEOPTIC_ROOT} =~ m|^/|;

$cfg::dir_home = $cfg::main_config;
$cfg::dir_home =~ s|/[^/]+$||;
$cfg::dir_web  = $cfg::dir_home.'/web';
$cfg::tmpl_dir = $cfg::dir_web.'/tmpl/';

$cfg::debug_log = ($ENV{FREEOPTIC_LOGS} ? $ENV{FREEOPTIC_LOGS}.'/' : $cfg::dir_home.'/logs/').'err_' . time() . '_' . int(rand 5**10) . '.log';

unshift @INC, $cfg::dir_home;

$SIG{'__DIE__'} = sub {
    die @_ if $^S; # die внутри eval{ }, не eval "code"
    eval{ Hard_exit(@_) };
    _hard_exit_html('very hard error');
};

!$ses::api && $ENV{QUERY_STRING} =~ /^a=_(js|css)/ && require "$cfg::dir_web/file.pl";

sub _hard_exit_ajax
{
    my($err) = @_;
    eval {
        eval 'use JSON';
        $@ && die $@;
        $ses::debug && debug('error', $err);
        my $json = [];
        if( $ses::api )
        {
            $json = {
                error => 'Internal error',
            };
            if( $ses::debug )
            {
                Debug->param( -type=>'plain' );
                $json->{debug} = [grep{ $_ ne ''} split /\n/, Debug->show];
            } else
            {
                $json->{debug} = 'Turn debug on';
            }
        }
         else
        {   # ajax
            if( $ses::debug )
            {
                push @$json, { id=>'debug', data=>Debug->show, action=>'insert' };
                push @$json, { type=>'js', data=>"console.log('look at debug')" };
            }
             elsif( !$ses::calls_pm_is_loaded )
            {
                debug($err);
                Debug->param( -type=>'file', -file=>$cfg::debug_log, -nochain=>0 );
                Debug->show; # into file
                push @$json, { type=>'js', data=>"console.log('cat $cfg::debug_log')" };
            }
             else
            {
                push @$json, { type=>'js', data=>"console.log('internal error. Turn debug on')" };
            }
        }
        $err = JSON->new->pretty->encode($json);
    };
    if( $@ )
    {
        $err = $ses::debug ? $err."\n\n".$@ : 'Hard Error. Need debug mode';
    }
    print "Content-type: text/html; charset=utf-8\n\n".$err;
    exit;
}
sub _hard_exit_html
{
    print "Content-type: text/html\n\n";
    print "<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8'></head>".
            "<body style='margin-top:10%; text-align:center'>".$_[0]."</body></html>";
    exit;
}
sub Hard_exit
{
    my $err = join ' ', @_;
    ($ses::api || $ses::ajax) && _hard_exit_ajax($err);
    if( $ses::debug )
    {
        eval{
            debug('error', $err);
            $err = Debug->show;
        };
        $err .= '<br><br>'.$@ if $@;
        $ses::calls_pm_is_loaded && eval{
            Debug->flush;
            # flush main window
            Doc->template('base')->{main_block} = '';
            Error($err);
        };
        # die in eval{} or calls.pm is not loaded
        _hard_exit_html($err);
    }
    open(F, ">>$cfg::debug_log") or _hard_exit_html("Cannot save to $cfg::debug_log");
    eval { 
        debug($err);
        Debug->param( -type=>'file', -file=>$cfg::debug_log, -nochain=>0 );
        Debug->show; # into file
    };
    if( $@ )
    {
        my @info = caller(0);
        print F "\n--- $info[1] line $info[2] ---\n$err";
    }
    $ses::calls_pm_is_loaded && eval{
        Doc->template('base')->{main_block} = '';
        Error($cfg::critical_error_msg || "Error code: $cfg::debug_log");
    };
    _hard_exit_html($cfg::critical_error_msg || "Temporary error<br>cat $cfg::debug_log");
}

eval "use Debug";
Debug->param( tm_start=>$ses::gettimeofday );

eval "use web::calls";
$ses::calls_pm_is_loaded = 1;

$ses::subs->{render} = $cfg::renders->{ses::input('__render')} or die 'Unknown render' if ses::input_exists('__render');

Db->is_connected or die 'No DB connection';


{
    $cfg::plugins = {};

    $_ = 'web_plugins.list';
    my $dir = "$cfg::dir_home/cfg";
    my $plugins_file = (-e "$dir/_$_") ? "$dir/_$_" : "$dir/$_";
    open(my $f, '<', $plugins_file) or die _($lang::cannot_load_file, $plugins_file);
    my($for_adm, $cod_prefix, $dir_prefix, $type) = (1, '', '', '');
    while( <$f> )
    {
        chomp;
        /^\s*#/ && next;
        /^\s*$/ && next; 
        if( /^\s*\[([^:]*):([^:]*):(.+):(.+)\]/ )
        {
            $cod_prefix = $1;
            $dir_prefix = $2;
            $type = $3;
            $for_adm = $4;
            next;
        }
        my($cod, $ajax, $file, $title) = split /\s+/, $_, 4;
        $cod  = $cod_prefix.$cod;
        $file = $dir_prefix.$file;
        my $param = {};
        if( $title =~ s/\s*(\{.*\})\s*// )
        {
            $param = eval $1;
            $title = $param->{title};
        }
        $ses::api && $param->{no_api} && next;
        $cfg::plugins->{$cod} = { type=>$type, for_adm=>$for_adm, ajax=>$ajax, title=>$title, file=>$file, param=>$param };
    }
    close($f);
}

my $cmd = ses::input('a') || 'main';
exists $cfg::plugins->{$cmd} or Error(L("Неизвестная команда '[]'", v::filtr($cmd)));

if( $cfg::plugins->{$cmd}{param}{noauth} )
{
    my $err = Require_web_mod($cfg::plugins->{$cmd}{file});
    $err && die $err;
    Exit();
}

if( !$ses::auth->{auth} )
{
    if( $ses::ajax )
    {
        ajModal_window('Reload the page');
        Exit();
    }
    debug('Not authorized. Starting login.pl');
    my $err = Require_web_mod('login');
    $err && die $err;
    Exit();
}

my $is_guest = $ses::auth->{adm}{privil} =~ /,801,/;
if( $is_guest && !$cfg::plugins->{$cmd}{param}{allow_guest} )
{
    debug("cmd '$cmd' is not allowed for a guest. Login required");
    remove_session();
    my $err = Require_web_mod('login');
    $err && die $err;
    Exit();
}

ses::input('__preset_redirect') && $cfg::preset_redirect_url && url->redirect( -base=>$cfg::preset_redirect_url );

if( $is_guest )
{
    foreach my $cod( keys %$cfg::plugins )
    {
        delete $cfg::plugins->{$cod} if !$cfg::plugins->{$cod}{param}{allow_guest};
    }
}

my $start_mod = 'start_'.$ses::auth->{role};
my $err = Require_web_mod($start_mod);
$err && die $err;

Exit();
