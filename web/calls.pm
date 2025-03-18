# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

use Time::localtime;
use Time::Local;
use Digest::MD5 qw( md5_base64 );
use base qw( Exporter );

use Db;
use nod::tmpl;

$cfg::cookie_name_for_ses = 'noses';
$cfg::max_byte_upload     = 44000;  # максимальное количество байт, которые мы можем принять по методу post

our @EXPORT = qw( _ L Error Error_ Error_Lang Show ToTop ToLeft ToRight Menu Center MessageBox MessageWideBox );

require $cfg::main_config;

$cfg::net_title = 'Test Network';
$cfg::img_dir = '';
$cfg::Lang = 'EN';
$cfg::languages = 'UA, RU, EN';
$cfg::web_session_ttl = 10*24*60*60;
$cfg::fibers_common_for_all = 0;
$cfg::fibers_collective_data = 0;
$cfg::fibers_map_api_key = '';

$cfg::Db_server ||= 'localhost';
$cfg::Db_name   ||= 'freeoptic';

Db->new(
    host    => $cfg::Db_server,
    user    => $cfg::Db_user,
    pass    => $cfg::Db_pw,
    db      => $cfg::Db_name,
    timeout => $cfg::Db_connect_timeout,
    tries   => 2, # 2 tries to connect
    global  => 1, # global Db object for Db->sql()
    pool    => $cfg::Db_pool || [],
);

my %p = Db->line('SELECT *, UNIX_TIMESTAMP() AS t FROM config ORDER BY time DESC LIMIT 1');
Db->is_connected or die 'No DB connection';

if( %p )
{
    $cfg::config = $p{data};
    eval "
        no strict;
        $cfg::config;
        use strict;
    ";
}
 else
{
    %p = Db->line('SELECT UNIX_TIMESTAMP() AS t');
}

$ses::t = $p{t};

$cfg::web_session_ttl ||= 10*24*60*60;
$cfg::img_dir =~ s|/$||;
$cfg::tmpl_dir ||= "$cfg::dir_web/tmpl/";

nod::tmpl::set_cur_dir($cfg::tmpl_dir);

$cfg::kb = $cfg::kb + 0 || 1000;

my $tt = localtime($ses::t);
$ses::day_now  = $tt->mday;
$ses::mon_now  = $tt->mon+1;
$ses::year_now = $tt->year+1900;
$ses::time_now = the_time($ses::t);
$ses::date_now = the_date($ses::t);

$ses::ip = $ENV{HTTP_X_REAL_IP} || $ENV{REMOTE_ADDR};
$ses::ip =~ s|[^\d\.]||g;

$ses::server = $ENV{SERVER_NAME};
$ses::server =~ s|/$||;
$ses::script = $ENV{SCRIPT_NAME};
$ses::script =~ s|'||g && die '$ENV{SCRIPT_NAME} error';

$ses::http_prefix = $ENV{HTTPS} || $ENV{HTTP_X_FORWARDED_PROTOCOL} =~ /https/i? 'https://' : 'http://';

$ses::server_port = $ENV{HTTP_X_FORWARDED_PORT} || $ENV{SERVER_PORT};
$ses::server .= ':'.$ses::server_port if ($ses::server_port != 80 && !$ENV{HTTPS}) ||
                                         ($ses::server_port != 443 && $ENV{HTTPS});

$ses::script_url = $ses::http_prefix.$ses::server.$ses::script;

if( $cfg::img_dir !~ /^http/ )
{
    $cfg::img_url = $ses::http_prefix.$ses::server.($cfg::img_dir =~ m|^[^/]| && '/').$cfg::img_dir;
}

$cfg::err_pic = "$cfg::img_dir/err.png";

%cfg::pr_def = (
  1 => 'on',
  3 => 'SuperAdmin',
);

package Doc;

my $Doc = {
    'base' => {
        'file'            => 'base',
        'script_url'      => $ses::script_url,
        'Url'             => url->new(),
        'css_left_block'  => '',
        'css_right_block' => '',
    },
    'box' => {
        'file' => 'box',
    },
    'menu' => {
        'file' => 'menu',
    },
};

bless $Doc;

sub template
{
    my(undef, $template) = @_;
    $Doc->{$template} ||= {};
    return $Doc->{$template};
}

sub template_file
{
    my(undef, $template) = @_;
    $Doc->{$template} ||= {};
    return $Doc->{$template}{file} || $template;
}

package main;

our %F = ();

{
    my $debug = {};
    # Каждую присланную переменную обрезаем в debug-е по столько символов:
    my $show_len = 300;
    my $query = '';
    sub _show_query
    {
        my $str = substr ${$_[0]}, 0, $show_len;
        $str =~ s/(.{101})/$1\n/g;
        length ${$_[0]} <= $show_len && return $str;
        return{ "first $show_len symbols"=>$str };
    }

    my @pairs = ();
    my %multi = ();
    my %array = ();

    if( exists($ENV{CONTENT_TYPE}) && $ENV{CONTENT_TYPE} =~ m|^\s*multipart/form-data|i )
    {
        debug('multipart/form-data');
        my($boundary) = map{ s/^ *boundary=//i; $_ } grep{ /^ *boundary=/i } split /;/, $ENV{CONTENT_TYPE};
        if( $boundary )
        {
            my $len = $ENV{CONTENT_LENGTH};
            $len > 20000000 && die "Превышение допустимой длины запроса: $len > 20000000 (байт)";
            my $m_query;
            read(STDIN, $m_query, $len);
            foreach my $param (split /--$boundary/, $m_query)
            {
                my($k, $v) = split /\r?\n\r?\n/, $param, 2;
                defined $v or next;
                my($cd) = map{ s/Content-Disposition: *//i; $_ } grep{ /^Content-Disposition:/i } split /\r?\n/, $k;
                $cd or next;
                my %params = map{ s/^['" ]+//; s/['" ]+$//; $_ } map{ /^([^=]+)=(.*)$/? (lc($1), $2) : (lc($_), $_) } split /;/, $cd;
                $k = $params{name} or next;
                $v =~ s/\r?\n$//;
                if( exists $params{filename} )
                {
                    $v eq '' && next;
                    $F{$k} = {file=>$params{filename}, value=>$v};
                    $debug->{$k} = {file=>$params{filename}, value=>substr $v, 0, $show_len};
                }
                 else
                {
                    $debug->{$k} = substr $v, 0, $show_len;
                    if( $k eq '__multi' )
                    {
                        $multi{$v} = 1;
                    }
                     elsif( $k eq '__array' )
                    {
                        $array{$v} = 1;
                        $F{$v} = [];
                        next;
                    }
                     else
                    {
                        push @pairs, [$k, $v];
                    }
                }
            }
        }
    }
     elsif( $ENV{REQUEST_METHOD} eq 'POST' )
    {
        my $len = $ENV{CONTENT_LENGTH};
        $len > $cfg::max_byte_upload && die "Превышение допустимой длины запроса: $len > $cfg::max_byte_upload (байт)";
        read(STDIN, $query, $len);
        debug('POST data:', _show_query(\$query) );
    }

    my $query_get = $ENV{QUERY_STRING};

    if( length $query_get )
    {
        debug('GET data:', _show_query(\$query_get) );
        $query .= ($query && '&').$query_get;
    }

    # Рассматриваем запрос как набор байтов, а не utf8
    utf8::is_utf8($query) && utf8::encode($query);

    $ses::query = $query;
    foreach my $pair( split /&/, $query)
    {
        $pair eq '' && next;
        my($name, $value) = split /=/, $pair;
        $name =~ tr/+/ /;
        $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $value=~ tr/+/ /;
        $value=~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        if( $name eq '__multi' )
        {
            $multi{$value} = 1;
            next;
        }
        if( $name eq '__array' )
        {
            $array{$value} = 1;
            $F{$value} = [];
            next;
        }
        push @pairs, [$name, $value];
    }
    foreach my $pair( @pairs )
    {
        my($name, $value) = @$pair;
        $_ = $value;
        # искажен utf-8?
        utf8::decode($_) or next;
        if( $array{$name} )
        {
            push @{$F{$name}}, $value;
        }
         elsif( $multi{$name} && $F{$name} ne '' )
        {
            $F{$name} .= ','.$value;
        }
         else
        {
            $F{$name} = $value;
        }
        $debug->{$name} = ref $F{$name}? $F{$name} : substr $F{$name}, 0, $show_len;
    }
    keys %$debug && debug('pre', $debug);
}

$ses::input_orig = \%F;

$ses::cookie = {};

foreach( split/;/,$ENV{HTTP_COOKIE} )
{
   my($name,$value) = split /=/,$_;
   $name =~ s/^ +//;
   $ses::cookie->{$name} = $value;
}

keys %{$ses::cookie} && debug('pre', 'Cookies: ', $ses::cookie);

$ses::set_cookie = {};
foreach my $key( grep{ /^set_/ } keys %F )
{
    my $val = $F{$key};
    $key =~ s|^set_||;
    $key =~ s|^ +||;
    $ses::cookie->{$key} = $val;
    $ses::set_cookie->{$key} = $val;
    delete $F{$key};
}

# --- Язык ---

$cfg::Lang = uc $ses::cookie->{nolang} || uc $cfg::Lang || 'EN';
$cfg::lang = lc $cfg::Lang;
$cfg::Lang_file = "$cfg::dir_web/lang/_$cfg::Lang.pl";
$cfg::Lang_file = "$cfg::dir_web/lang/$cfg::Lang.pl" if !( -e $cfg::Lang_file );
$cfg::languages_list = $cfg::languages ne ''? [map{ uc $_ } split /, */, $cfg::languages] : ['UA', 'EN', 'RU'];

eval{ require $cfg::Lang_file };
if( my $err = $@ )
{
    Require_web_mod('lang/EN') && die $err;
    debug('error', $err);
}

my $lang_vars = $cfg::LANG{$cfg::Lang} || {};
no strict;
foreach my $v( keys %$lang_vars )
{
    if( ref $lang_vars->{$v} eq 'HASH' )
    {
        ${"lang::$v"} ||= {};
        foreach $_( keys %{$lang_vars->{$v}} )
        {
            ${"lang::$v"}->{$_} = $lang_vars->{$v}{$_};
        }
    }
     else
    {
        ${"lang::$v"} = $lang_vars->{$v};
    }
}
use strict;

$cfg::valid_img_ext ||= 'jpg|jpeg|jp2|jpg2|png|gif|tiff';


$ses::auth = { auth=>0, uid=>0, role=>'', trust=>0, adm=>{} };

{
    my $ttl = 0;
    my $expire = 0;
    my $ses = $ses::cookie->{$cfg::cookie_name_for_ses};
    if( $ses )
    {  # в куках передан id сессии
        my %p = Db->line(
            "SELECT * FROM websessions s LEFT JOIN admin a ON (s.uid=a.id AND s.role='admin') ".
            "WHERE BINARY ses=? AND uid>0 LIMIT 1", $ses
        );
        if( %p )
        {
            $expire = $p{expire};
            $ttl = $expire - $ses::t;
            if( $ttl > 0 )
            {
                $ses::auth = {
                    auth  => 1,
                    uid   => $p{uid},
                    role  => $p{role},
                    trust => $p{trust},
                    ses   => $ses,
                    adm   => \%p,
                };
                debug("Сессия `$ses` существует, uid: $p{uid}, role: $p{role}");
                my %privil = map{ int($_) => 1 } split /,/, $p{privil};
                if( $privil{801} )
                {
                    $ses::auth->{adm}{privil} = ',' . join(',', grep{ $_ != 2 && $_ != 3 } keys %privil) . ',';
                }
            }
             else
            {
                $ttl = 0;
                debug("Сессия `$ses` существует, но устарела.");
            }
        }
         elsif( Db->rows < 0 )
        {
            die '[[[ repair tables ]]]';
        }
         else
        {
            debug("Сессии $ses нет в БД. Скорее всего удалена по таймауту.");
        }
    }
     else
    {
        debug("Сессия через cookie $cfg::cookie_name_for_ses не передана.");
    }


    !$ses::ajax && $ttl && ($ses::t + $cfg::web_session_ttl - $expire > 60 ) &&
        Db->do("UPDATE websessions SET expire=UNIX_TIMESTAMP()+? WHERE BINARY ses=? LIMIT 1", $cfg::web_session_ttl, $ses);

    # --- в $F{_unikey} ключ к данным, которые передаются модулю с именем в поле module
    {
        $F{_unikey} or last;
        $ses::unikey = $F{_unikey};
        my %p = Db->line("SELECT * FROM webses_data WHERE BINARY unikey=? LIMIT 1", $ses::unikey);
        if( !%p )
        {
            %F = ();
            Db->ok && debug('warn', 'Данные по ключу _unikey не найдены. Возможно были удалены по времени');
            last;
        }
        my $VAR1;
        eval $p{data};
        if( $@ )
        {
            %F = ();
            debug('warn', "Ошибка парсинга данных: $@");
            last;
        }
        $ses::data = $VAR1;
        $ses::data_created = $p{created};
        debug('pre', "Данные по unikey $ses::unikey:", $ses::data) if length $p{data}<5000;
        delete $F{_unikey}; # не позже т.к. в самих данных может быть _unikey
        if( ref $ses::data->{-input} eq 'HASH' )
        {
            map{ $F{$_} = $ses::data->{-input}{$_} } grep{ ! defined $F{$_} } keys %{$ses::data->{-input}};
        }
        $F{a} = $p{module};
    }
}

$ses::input = \%F;

my $r = $cfg::renders = {
    html    => \&Render,
    api     => \&ApiRender,
    api_ext => \&ApiExtRender,
    ajax    => \&ajRender,
};

$ses::cmd = $ses::api ? {} : [];
$ses::subs = {
    exit    => [],
    render  => ($ses::api ? $r->{api} : $ses::ajax ? $r->{ajax} : $r->{html}),
};

my $is_admin = $ses::auth->{role} eq 'admin';

# -------------------------------------------------------------------------------------------------------

sub sub_zero {}

sub _set_cookie_str
{
    my $cookie = '';
    if( keys %$ses::set_cookie )
    {
        foreach my $key( keys %$ses::set_cookie )
        {
            my $val = $ses::set_cookie->{$key};
            my $expire = $val ne '' ? 'Thu,31-Dec-2025' : 'Thu,31-Dec-2025';
            my $add_cookie_data = '';
            if( ref $val eq 'HASH')
            {
                $add_cookie_data = join '', map{ $_.($val->{$_} eq '' ? '' : '='.$val->{$_}).';' } grep{ $_ ne 'value' } keys %$val;
                $val = $val->{value};
            }
            $cookie .= "Set-Cookie: $key=$val;path=/;expires=$expire 00:00:00 GMT;$add_cookie_data";
        }
        debug('pre', 'set cookie in response:', $cookie);
        $cookie .= "\n";
    }
    return $cookie;
}

sub _all_to_str
{
    my $param = shift;
    defined($param) or return undef;
    if( ref $param eq 'ARRAY' )
    {
        return [ map{ _all_to_str($_) } @$param ];
    }
    if( ref $param eq 'HASH' )
    {
        return { map{ $_ => _all_to_str($param->{$_}) } keys %$param };
    }
    return $param.'';
}

sub _ajax_headers
{
    my @headers = (
        'Content-type: text/html; charset=utf-8',
        'Cache-Control: no-store, no-cache, must-revalidate',
        'Access-Control-Allow-Credentials: true',
    );
    my $referer = $ENV{HTTP_REFERER};
    if( $referer =~ m|^(https?://[^/]+)| )
    {
        push @headers, "Access-Control-Allow-Origin: $1";
    }
    return join("\n", @headers)."\n"._set_cookie_str()."\n";
}

sub remove_session
{
    Db->do("DELETE FROM websessions WHERE uid=? AND role=?", $ses::auth->{uid}, $ses::auth->{role});
}

sub ApiExtRender
{
    if( ref $ses::cmd eq 'HASH' && exists $ses::cmd->{error} )
    {
        my $error = $ses::cmd->{error};
        if( ses::input_exists('err_func') )
        {
            $ses::cmd = [{
                type    => 'js',
                js_func => ses::input('err_func'),
                data    => $error,
            }];
        }
         else
        {
            $ses::cmd = [];
            ajModal_window($error);
        }
    }
     elsif( ses::input_exists('ok_func') )
    {
        my $result = $ses::cmd;
        $ses::cmd = [{
            type    => 'js',
            js_func => ses::input('ok_func'),
            data    => $result,
        }];
    }
    ajRender();
}

sub ajRender
{
    #if( ref $ses::cmd ne 'ARRAY' )
    #{
    #    debug($ses::cmd);
    #    $ses::cmd = [];
    #}
    $ses::debug && push @$ses::cmd, {
        id     => 'debug',
        data   => Debug->show,
        action => 'insert',
    };
    eval 'use JSON';
    $@ && die $@;
    print _ajax_headers().to_json($ses::cmd);
    exit;
}


sub ApiRender
{
    if( $ses::debug )
    {
        Debug->param( -type=>'plain' );
        $ses::cmd->{debug} = [grep{ $_ ne ''} split /\n/, Debug->show];
    }
    eval 'use JSON';
    $@ && die $@;
    my $cmd = _all_to_str($ses::cmd);
    print _ajax_headers().to_json($cmd, { convert_blessed => 1, pretty => 1 });
    exit;
}

sub Render
{
    my $cookie = _set_cookie_str();

    my $base = Doc->template('base');
    if( $ses::debug )
    {
        $base->{debug} = Debug->show;
        $base->{debug_errors} = Debug->errors || '';
        $ses::debug_info = {
            debug => $base->{debug},
            errors => $base->{debug_errors},
        };
    }
    my $html = render_template($base->{file}, %$base);

    foreach my $sub( @{$ses::subs->{end}} ) { &{ $sub } }

    print "Content-type: text/html\n".$cookie."\n";
    print $html;
    exit;
}

sub Exit
{
    {   # Сообщение в топ
        defined $ses::data->{-made} or last;
        my $m = $ses::data->{-made};
        # Сообщение выводим только, если оно было создано менее 15 сек назад
        my $msg_expire = $ses::t - ($ses::debug? 600:15);
        $m->{created} && $m->{created} < $msg_expire && last;
        # Не фильтруем т.к. сообщение передается через базу, т.е доверенное
        my $msg = _($m->{error}? '[div top_msg_error]' : '[div]', $m->{msg});
        Doc->template('top_block')->{made_msg} .= $msg;
        Doc->template('base')->{made_msg} = $msg;
        Doc->template('base')->{made_msg_error} = !!$m->{error};
    }

    if( ref $ses::cmd eq 'ARRAY' && scalar @$ses::cmd )
    {
        foreach my $p( @$ses::cmd )
        {
            if( $p->{type} eq 'js' )
            {
                Doc->template('base')->{document_ready} .= $p->{data}.';';
                next;
            }
            if( !$p->{type} && $p->{id} ne '' )
            {
                my $to_dom_id = $p->{id};
                my $from_dom_id = v::get_uniq_id();
                Doc->template('base')->{buffer} .= "<div id='$from_dom_id'>$p->{data}</div>";
                my $action = $p->{action} eq 'add'? 'append' : $p->{action} eq 'insert'? 'prepend' : 'html';
                Doc->template('base')->{document_ready} .= " \$('#$to_dom_id').$action(\$('#$from_dom_id'));";
            }
        }
    }
    foreach my $sub( @{$ses::subs->{exit}} ) { &{ $sub } }

    &{ $ses::subs->{render} };
}


# -------------------------

sub ajError
{
    my $err = join ' ', @_;
    debug('error', $err);
    Exit();
}

sub ApiError
{
    my $err = join ' ', @_;
    $ses::cmd = { error => $err };
    Exit();
}

# -------------------------


sub get_file_by_tmpl_name
{
    my $tmpl_name = shift;
    $tmpl_name .= '.html' if $tmpl_name !~ /\./;
    my $phantom = $tmpl_name = $cfg::tmpl_dir.$tmpl_name;
    $phantom =~ s/([^\/]+)$/_$1/;
    $tmpl_name = (-e $phantom) ? $phantom : $tmpl_name;
    return $tmpl_name;
}

sub render_template
{
    my $template = shift;
    {
        ref $template && last;
        $template = Doc->template_file($template);
        ref $template && last;
        $template = get_file_by_tmpl_name($template);
    }
    return nod::tmpl::render($template, @_);
}

sub tmpl
{
    return render_template(@_);
}

sub safe_tmpl
{
    my($template, %params) = @_;
    $template = _('[filtr]', $template);
    $template =~ s/\{/&#123;/g;
    $template =~ s/\}/&#125;/g;
    $template =~ s/\n/<br>/g;
    $template =~ s/\[(.*?)\-(.*?)\]/\{\{safe_tmpl.$1\('$2'\)\}\}/g;
    return render_template(\$template, %params);
}

sub ToTop
{
    Doc->template('base')->{top_lines} .= _('[div top_msg h_center]', "@_" );
}

sub ToLeft
{
    Doc->template('base')->{left_block} .= join '<p></p>', @_;
}

sub ToRight
{
    Doc->template('base')->{right_block} .= join '<p></p>', @_;
}

sub Show
{
    Doc->template('base')->{main_block} .= join '<p></p>', @_;
}

sub Box
{
    return render_template( Doc->template_file('box'), @_ );
    my %p = @_;
    my %param = ('data-box'=>1, -body=>[$p{msg}]);
    $param{class} = $p{css_class} if defined $p{css_class};
    $param{'data-title'} = $p{title} if defined $p{title};
    $param{'data-wide'} = $p{wide} if defined $p{wide};
    return v::div(%param);
}

sub WideBox
{
    return Box( wide=>1, @_ );
}

sub MessageBox
{
    return Box( msg=>$_[0] );
}

sub MessageWideBox
{
    return Box( msg=>$_[0], wide=>1 );
}

# --- Вывод окна с ошибкой ---

sub ErrorMess
{
    my($msg) = @_;
    Show render_template('error_box', msg=>$msg);
}

# --- Вывод окна с ошибкой и выход ---

sub Error
{
    my $err = join ' ', @_;
    $ses::api && ApiError($err);
    $ses::ajax && ajError($err);
    Show render_template('error_box', msg=>$err, vertical_center=>1);
    Exit();
}

sub Error_
{
    Error( _(@_) );
}

sub Error_Lang
{
    my $str = shift;
    my $file = [caller(0)]->[1];
    Error( _(__lang_var($str, $file), @_) );
}

sub Menu
{
    return render_template( Doc->template_file('menu'), msg=>join('', @_), css_class=>'navmenu', wide=>1 );
}

sub Center
{
    return _('[div align_center]', "@_");
}

sub ajModal_window
{
    push @$ses::cmd, {
        id   => 'modal_window',
        data => join('', @_),
    };
    return 1;
}

sub ajSmall_window
{
    my($domid, $data) = @_;
    $domid ||= 'modal_window';
    if( $domid ne 'modal_window' || $data ne '' )
    {
        push @$ses::cmd, {
            id   => $domid,
            data => $domid eq 'modal_window' ? $data : $data eq '' ? '' : _('[div small_info close]', $data),
        };
    }
}

sub _
{
 local $_;
 my($a, $f);
 my @b = split /\[/, shift @_;
 my $out = shift @b;
 while( $a = shift @b )
 {
    $f = '';
    $a =~ s|^(.*)]|| or next;

    my $tmpl = $1;

    if($tmpl eq 'br')  { $f .= '<br>'; next }
    if($tmpl eq 'br2') { $f .= '<br><br>'; next }
    if($tmpl eq 'hr')  { $f .= '<hr>'; next }
    if($tmpl =~ s|^lang:||i )
    {
        $f .= __lang_var(v::trim($tmpl), [caller(0)]->[1]);
        next;
    }

    my @f = split /\|/, $tmpl;
    $f = shift @_;
    foreach( @f )
    {
        if($_ eq 'bold') { $f = "<b>$f</b>"; next }
        if($_ eq 'commas') { $f = "«$f»"; next }
        if($_ eq 'trim') { $f = v::trim($f); next }
        if($_ eq 'safe_message') { $f = v::filtr($f); $f =~ s/\n/<br>/g; next }
        if($_ eq 'filtr') { $f = v::filtr($f); next }
        if($_ eq 'box') { $f = MessageBox($f); next }
        my($tag, $param) = split / +/, $_, 2;
        if( defined $param )
        {
            $param = " class='$param'" if $param !~ s|([^=]+)=([^ ]+)| $1='$2'|g;
        }
        $f = "<$tag$param>$f</$tag>";
    }
 }
  continue
 {
    $out .= $f.$a;
 }
 return $out;
}

sub __lang_var
{
    my($str, $file) = @_;
    $file = $file =~ /user\/_?([^\/]+)\.(pl|pm)$/? "user::$1" :
            $file =~ /login\/_?([^\/]+)\.(pl|pm)$/? "login::$1" :
            $file =~ /_?([^\/]+)\.(pl|pm)$/? $1 : 'ALL';
    no strict;
    $str = exists ${"lang::$file"}->{$str}? ${"lang::$file"}->{$str} :
           exists $lang::ALL->{$str}? $lang::ALL->{$str} : $str;
    use strict;
    return $str;
}
sub L
{
    my $str = shift;
    my $file = [caller(0)]->[1];
    return _(__lang_var($str, $file), @_);
}
sub CommonLocalize
{
    my $str = shift;
    return exists $lang::ALL->{$str}? $lang::ALL->{$str} : $str;
}

sub Inline_template
{
    my $template = shift;
    my $file = [caller(0)]->[1];
    $template = __lang_var($template, $file);
    return render_template( \$template, @_ );
}

# Время в виде dd.mm.gg hh:mm
sub the_time
{
    my $t = localtime(shift);
    return sprintf('%02d.%02d.%04d %02d:%02d', $t->mday,$t->mon+1,$t->year+1900,$t->hour,$t->min);
}

# Время в виде hh:mm
sub the_hour
{
    my $t = localtime(shift);
    return sprintf('%02d:%02d', $t->hour,$t->min);
}

# Время в виде dd.mm.gg hh:mm или hh:mm если день равен текущему
# Вход:
#  0 - время
#  1 - если установлен и день = текущему, то вернет `сегодня в hh:mm`
sub the_short_time
{
    my($time, $today) = @_;
    my $t1 = localtime($time);
    my $t2 = localtime($ses::t);
    return the_time($time) if !($t1->mday == $t2->mday && $t1->mon == $t2->mon && $t1->year == $t2->year);
    $t1 = the_hour($time);
    $today or return $t1;
    return $today>1? "$lang::Today_at $t1" : "$lang::today_at $t1";
}

# Время в виде dd.mm.gggg
sub the_date
{
    my $t = localtime(shift);
    return sprintf('%02d.%02d.%04d', $t->mday,$t->mon+1,$t->year+1900);
}

# Переводит период в секундах в вид чч:мм:сс
sub the_hh_mm_ss
{
    my($sec) = @_;
    return ($sec>59 && the_hh_mm($sec)).' '.($sec %  60).' '.$lang::sec;
}

# Переводит период в секундах в часы и минуты
sub the_hh_mm
{
    my $min = int($_[0]/60);
    my $res = '';
    if( $min >= 1440 )
    {
        $res .= int($min/1440).' '.L('дн.').' ';
        $min %= 1440;
        $min or return $res;
    }
    if( $min >= 60 )
    {
        $res .= int($min/60).' '.L('час').' ';
        $min %= 60;
    }
    $res .= $min.' '.L('мин');
    return $res;
}


sub ToLog
{
    my $dir = $ENV{NODENYLOGS} ? $ENV{NODENYLOGS} : "$cfg::dir_home/logs/";
    $dir .= '/' if $dir !~ m|/$|;
    my $file = "$dir/web.log";
    my $log;
    if( !open( $log, '>>', $file) )
    {
        debug('error', "Не могу открыть на запись файл $file");
        return;
    }
    flock($log, 2);
    my $msg = join ' ', the_time(time), (Adm->id? $ses::adm_infoline : "user id=$ses::auth->{uid}"), @_;
    print $log $msg."\n";
    flock($log, 8);
    close($log);
}

# Формирование кнопочек с сылками на страницы если результат sql-запроса не вмещается на страницу
# Вход:
#  0 - sql-запрос без команды LIMIT и обязательно начинающийся с SELECT, либо array ссылка
#       например, [ "SELECT * FROM users WHERE name LIKE = ?", '%test%' ]
#  1 - номер страницы, которая должна быть выведена
#  2 - максимальное количество записей на страницу
#  3 - объект url для кнопочек (в урл будут добавлены строки &start=xx)
#  4 - [объект Db] (не обязательный параметр)
#  5 - sql для подсчета общего количество записей, устанавливать только если, уверены,
#       что SQL_CALC_FOUND_ROWS замедлит выборку
# Выход:
#  0 - sql-запрос с проставленными LIMIT
#  1 - html с кнопочками
#  2 - общее количество строк в полном запросе
#  3 - указатель на $db c сформированным результатом, т.е для которого можно сделать $db->line

sub Show_navigate_list
{
    my($sql, $page, $on_page, $url, $db, $count_sql, $start_url_key) = @_;
    $db ||= 'Db';
    $on_page = int $on_page;
    $on_page = 1 if $on_page<1;
    $page = int $page;
    $page = 0 if $page<0;
    $start_url_key ||= 'start';

    my @param = ();
    if( ref $sql )
    {
        @param = @$sql;
        $sql = shift @param;
    }

    my $orig_sql = $sql;
    $sql .= " LIMIT ".($page*$on_page).", $on_page";
    my $run_sql = $sql;

    # Если общее количество записей нужно вычислить отдельным sql, то выполним его асинхронно
    my $async_db;
    if( $count_sql )
    {
        my $async_connect = $db->self->new(async=>1, global=>0);
        $async_db = $async_connect->sql( ref $count_sql? @$count_sql : $count_sql );
    }
     else
    {
        $run_sql =~ s/^\s*SELECT\s+/SELECT SQL_CALC_FOUND_ROWS /i;
    }

    my $dbres = $db->sql($run_sql, @param);
    my $rows = $dbres->{rows};
    $rows < 0 && return($sql, '', 0, $dbres, []);

    my $all_rows;
    if( !$count_sql )
    {
        $all_rows = $db->dbh->selectrow_array('SELECT FOUND_ROWS()');
    }
     else
    {
        (undef, $all_rows) = $async_db->line;
    }
    $all_rows ||= 0;

    debug('Всего строк:', $all_rows);

    my @page_buttons = ();
    if( !$rows )
    {
        $orig_sql .= " LIMIT 1";
        $dbres = $db->sql($orig_sql, @param);
        if( $dbres->rows > 0 )
        {
            push @page_buttons, {
                title  => L('Необходимо вернуться на').' '.L('страницу 1'),
                link   => $url->url($start_url_key=>0),
                active => 1,
                wide   => 0,
            };
        }
        return(
            $orig_sql,
            $dbres->rows > 0 ? L('Необходимо вернуться на').' '.$url->a(L('страницу 1'), $start_url_key=>0, -class=>'nav') : '',
            $all_rows,
            $dbres,
            \@page_buttons,
        );
    }

    my $n = $all_rows;
    my @out = ();

    # если кол-во строк больше кол-ва которое можно выводить за раз, то сформируем навигацию
    if( $n > $on_page )
    {
        # если страниц немного - кнопочки сделаем широкими
        my $wide = $n/$on_page <= 8;
        my $nav_class = $wide ? ' nav_wide' : '';

        # кнопка страницы №1 существует всегда
        my $active = !$page;
        push @out, $url->a('1', $start_url_key=>0, -class=>($active ? 'page active' : 'page').$nav_class);
        push @page_buttons, {
            title  => '1',
            link   => $url->url($start_url_key=>0),
            active => $active,
            wide   => $wide,
        };

        # соседние кнопки для выбранной страницы оформляются в стиле nav, за ними для сужения вывода кнопки
        # оформляются без стиля (как обычные гиперссылки). $steps указывает количество соседних кнопок в стиле nav.
        # чем больше номер выбранной страницы, тем $step меньше т.к. большое число на кнопке делает эту кнопку шире
        my $steps = $page<89? 8: $page<995? 5 : 2;

        my $i = 1; # начнем с кнопки для страницы №2
        $n -= $on_page;

        my($href, $title);
        while( $n>0 )
        {
            my $len  = abs($i-$page); # количество кнопок от текущей до активной сраницы
            my $url0 = $url->new($start_url_key=>$i, -title=>($i+1));
            my $active = !$len;
            $url0->{-class} = $active ? 'page active'.$nav_class : $len<$steps ? 'page'.$nav_class : '';
            if( $len<29 )
            {
                $i++;
                $n -= $on_page;
                $title = $len<$steps || $i%10==0 ? $i : '.';
                $href = $url0->a($title);
            }
             else
            {
                $title = ':';
                $href = $url0->a($title);
                my $s = $len<109 ? 10 : $len<2000 ? 100 : 1000;
                $n -= $on_page * $s;
                $i += $s;
            }
            if( $n<=0 && $len )
            {   # последняя кнопка и она не активна (не последняя страница выбрана)
                # Изменим номер последней страницы на действительно последнюю
                $i = int(($all_rows-1)/$on_page) + 1;
                $title = $i;
                $active = '';
                $url0 = $url->new($start_url_key=>$i-1);
                $href = $url0->a($title, -class=>'page'.$nav_class);
            }
            push @out, $href;
            push @page_buttons, {
                title  => $title,
                link   => $url0->url(),
                active => $active,
                wide   => $wide,
            };
        }
    }
    my $out = join '', @out;
    return( $sql, $out, $all_rows, $dbres, \@page_buttons );
}

sub Save_webses_data
{
    my %p = @_;
    $p{module} ||= '';
    $p{data} = Debug->dump($p{data});
    $p{expire} ||= 3 * 3600;
    my $unikey;
    foreach( 1..2 )
    {   # Теоретически, ключ может оказаться не уникальным, поэтому 2 попытки
        $unikey = md5_base64(rand 10**10);
        $unikey =~ s/\+/X/g;
        my $rows = Db->do(
            "INSERT INTO webses_data SET ".
                "created=UNIX_TIMESTAMP(), expire=UNIX_TIMESTAMP()+?, ".
                "role=?, aid=?, unikey=?, module=?, data=? ",
                $p{expire}, $ses::auth->{role}.'', int $ses::auth->{uid}, $unikey, $p{module}, $p{data}
        );
        $rows>0 && return $unikey;
    }
    # если произойдет невозможное: 2 коллизии подряд - пустой ключ будет проигнорирован
    return '';
}

sub get_fullusers_fields_names
{
    my($grp) = @_;
    my $field_names = Ugrp->grp($grp)->{field_login};
    my %field_names = %{$lang::fullusers_fields_name};
    $field_names{id} = 'Id';
    if( $field_names =~ /=.+/ )
    {   # У выбранной группы могут быть свои персональные названия полей
        map{ /([^=]+)=([^=]+)/; $field_names{$1} = $2; } grep{ /=/ } split /;/, $field_names;
    }
     elsif( $field_names )
    {
        $field_names{name} = $field_names;
    }
    return \%field_names;
}

sub get_db_obj
{
    $cfg::Trf_Db_name or return Db->self;
    my $db = Db->new(
        host    => $cfg::Trf_Db_server,
        user    => $cfg::Trf_Db_user,
        pass    => $cfg::Trf_Db_pw,
        db      => $cfg::Trf_Db_name,
        timeout => $cfg::Trf_Db_connect_timeout,
        tries   => 2,
        global  => 0,
        pool    => [],
    );
    $db->connect;
    return $db;
}

# Загружает фантом модуля (файл, начинающийся с подчеркивания), если его нет - сам модуль
# Если установлей 2й параметр - загрузка только 1 раз (как при use)
sub Require_mod
{
    my($name, $only_once)= @_;
    $ses::sub_Require_mod__Used_modules ||= {};
    $only_once && $ses::sub_Require_mod__Used_modules->{$name} && return '';
    my $file = "$cfg::dir_home/$name";
    $file .= '.pl' if $file !~ /\.(pl|pm)$/;
    my $phantom = $file;
    $phantom =~ s|/([^/]+)$|/_$1|s;
    $file = $phantom if( -e $phantom );
    debug "require $file";
    # eval, поскольку ошибка компиляции $file не даст загрузить модули в обработчике die (гугли BEGIN not safe after errors)
    eval{ require $file };
    $ses::sub_Require_mod__Used_modules->{$name} = 1 if !$@;
    return "$@";
}

sub Require_web_mod
{
    return Require_mod('web/'.$_[0], $_[1]);
}

sub Use_mod
{
    return Require_mod($_[0], 1);
}

# -----------------------------------------------------------
#
               package Adm;
#
# -----------------------------------------------------------
use Debug;

our $adm = {};
our $list = [];

our $Current_adm  = {};

my $all_load;

sub set_current
{
    $Current_adm = new(@_);
    return $Current_adm;
}

sub new
{
    my($pkg, $p) = @_;
    my $a = {
        id      => $p->{id},
        login   => $p->{login},
        pass    => $p->{pass},
        name    => $p->{name},
        privil  => $p->{privil},
        url     => url->a($p->{login}, a=>'pay_log', admin=>$p->{id}),
    };
    $a->{admin} = $a->{login};
    $a->{admin} .= " ($a->{name})" if $a->{name};
    $a->{priv_hash} = {};
    foreach( split /,/, $p->{privil} )
    {
        $_ or next;
        $a->{priv_hash}{$_} = 1;
        $a->{priv_hash}{$cfg::pr_def{$_}} = 1 if defined $cfg::pr_def{$_};
    }
    bless $a;
    $adm->{$p->{id}} = $a;
    return $a;
}

sub list
{
    my($pkg, $aid) = @_;
    $all_load && return $list;
    my $db = Db->sql("SELECT *, AES_DECRYPT(passwd,?) AS pass FROM admin ORDER BY login", $cfg::Passwd_Key);
    while( my %p = $db->line )
    {
        my $aid = $p{id};
        push @$list, $aid;
        $pkg->new( \%p );
    }
    $all_load = 1;
    return $list;
}

sub get
{
    my($pkg, $aid) = @_;
    $aid = int $aid;
    defined $adm->{$aid} && return $adm->{$aid};
    $pkg->list;
    defined $adm->{$aid} && return $adm->{$aid};
    my $msg = _($lang::adm_is_not_exist, $aid);
    return $pkg->new({ id=>$aid, login=>$msg });
}

sub id {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{id};
}
sub admin {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{admin};
}
sub login {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{login};
}
sub pass {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{pass};
}
sub name {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{name};
}
sub balance {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{balance};
}
sub privil {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{privil};
}
sub priv_hash {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{priv_hash};
}
sub url {
    my $a = ref $_[0]? shift : $Current_adm;
    return $a->{url};
}
sub chk_privil {
    my $a = shift;
    $a = ref $a? $a : $Current_adm;
    return $a->{priv_hash}{$_[0]};
}
sub chk_privil_or_die {
    my($a, $priv, $msg) = @_;
    $a = ref $a? $a : $Current_adm;
    $a->{priv_hash}{$priv} && return;
    debug('warn', "У текущего администратора нет привилегии `$priv`");
    main::Error($msg || $lang::err_no_priv);
}
sub why_no_usr_access {
    my($a, $uid) = @_;
    $a = ref $a? $a : $Current_adm;
    $uid>0 or return "Не задан id клиента";
    my(undef,$grp) = Db->line("SELECT grp FROM users WHERE id=?", $uid);
    Db->ok or return $lang::err_try_again;
    $grp or return "User id=$uid не найден в базе";
    $a->chk_usr_grp($grp) or return "Нет доступа к группе user id=$uid";
    return '';
}
sub exists { defined $_[0]->{name} }

# -----------------------------------------------------------
#
               package ses;
#
# -----------------------------------------------------------
use Debug;
use vars qw( $input );

sub input_exists
{
    return defined $input->{$_[0]};
}

sub input
{
    scalar @_ == 1 && return $input->{$_[0]};
    return( map{ $input->{$_} } @_ );
}

sub input_trim
{
    scalar @_ == 1 && return v::trim($input->{$_[0]});
    return( map{ v::trim($input->{$_}) } @_ );
}

sub input_int
{
    scalar @_ == 1 && return int $input->{$_[0]};
    return( map{ int $input->{$_} } @_ );
}

sub input_all
{
    return %$input;
}

sub input_file
{
    return ref $input->{$_[0]} && exists $input->{$_[0]}{file} ? $input->{$_[0]}{value} : '';
}

sub cur_module
{
    return $input->{a};
}

# -----------------------------------------------------------
#
               package url;
#
# -----------------------------------------------------------
use Debug;

sub new
{
    my $cls = shift;
    my $it = {};
    bless $it;
    $it->set(%$cls) if ref $cls;
    $it->set(@_);
    return $it;
}

sub set
{
    my $it = shift;
    my %param = @_;
    map{ defined $param{$_}? ($it->{$_} = $param{$_}) : delete $it->{$_} } keys %param;
}

sub url_encode
{
    my $url = shift;
    utf8::is_utf8($url) && utf8::encode($url);
    $url =~ s/([^a-zA-Z0-9])/sprintf('%%%02X',ord($1))/eg;
    return $url;
}

sub url
{
    my $it = shift;
    $it = $it->new(@_);
    my $url = $it->{-base} || '';
    if( $it->{-trust} || defined $it->{-made} )
    {
        my %param = map{ $_ => $it->{$_} } grep{ /^[^\-]/ } keys %$it;
        my $data = { -input=>\%param };
        $data->{-made} = { msg=>$it->{-made}, created=>$ses::t, error=>$it->{-error} } if defined $it->{-made};
        return $url."?_unikey=".main::Save_webses_data( module=>$it->{a}, data=>$data );
    }

    my $separator = $url =~ /\?/? '&' : '?';
    my $s = $it->{-separator} || '&';
    while( my($key, $val) = each %$it )
    {
        substr($key, 0, 1) eq '-' && next;
        if( ref $val eq 'ARRAY' )
        {
            $url .= $separator.'__array'.'='.url_encode($key);
            $separator = $s;
            $key = $separator.url_encode($key).'=';
            #map{ $url .= $key.url_encode($_) } @$val;
            foreach my $c( @$val ) { $url .= $key.url_encode($c) }
        }
         else
        {
            $url .= $separator.url_encode($key).'='.url_encode($val);
            $separator = $s;
        }
    }
    $url .= ($it->{-anchor} !~ /^#/ && '#').$it->{-anchor} if $it->{-anchor};
    return $url;
}

sub a
{
    my $it = shift;
    my $title = shift;
    $it = $it->new(@_);
    my $url = $it->url;

    if( $it->{-ajax} )
    {
        $it->{-class} .= ' ajax';
        delete $it->{-ajax};
    }
    if( $it->{-active} )
    {
        $it->{'-data-active'} = 1;
        delete $it->{-active};
    }
    my %param = ();
    while( my($key,$val) = each %$it )
    {
        $key =~ s/^\-// or next;
        ($key =~ /^(base|center)$/) && next;
        $param{$key} = $val;
    }

    $url = v::tag('a', href=>[$url], -body=>$title, %param);
    $url = main::Center($url) if $it->{-center};
    return $url;
}

sub post_a
{
    my $it = shift;
    my $title = shift;
    my $form_name = v::get_uniq_id();
    $title = "<a href='javascript:document.$form_name.submit();'>$title</a>";
    return $it->form( @_, -name=>$form_name, $title );
}

sub form
{
 my $it = shift;
 my $data = pop;
 $it = $it->new(@_);
 my $base = $it->{-base} || '?';
 $it->{-method} ||= 'post';
 my $params = '';
 my %hiddens = ();
 $it->{-onsubmit} = v::filtr($it->{-onsubmit},'; return true') if $it->{-onsubmit};
 while( my($key,$val) = each %$it )
 {
    if( $key =~ s/^\-// )
    {
       ($key =~ /^(base)$/) && next;
       $params .= " $key='".v::filtr($val)."'";
       next;
    }
    $hiddens{$key} = $val;
 }
 if( ref $data eq 'ARRAY' )
 {
    my $tbl = tbl->new( -class=>'td_tall td_wide' );
    foreach my $p( @$data )
    {
        my $r_col;
        my $l_col = $p->{title};
        delete $p->{title};
        if( $p->{type} eq 'descr' )
        {
            $r_col = $p->{value};
        }
        if( $p->{type} eq 'text' )
        {
            $r_col = [ v::input_t(%$p) ];
        }
        if( $p->{type} eq 'pass' )
        {
            $r_col = [ v::input_p(%$p) ];
        }
        if( $p->{type} eq 'text2' )
        {
            $l_col = [v::filtr($p->{title1}).v::input_t( name=>$p->{name1}, value=>$p->{value1})];
            $r_col = [v::filtr($p->{title2}).v::input_t( name=>$p->{name2}, value=>$p->{value2})];
        }
        if( $p->{type} eq 'textarea' )
        {
            $r_col = [ v::input_textarea(-body=>$p->{value}, name=>$p->{name}) ];
        }
        if( $p->{type} eq 'select' )
        {
            $r_col = [ v::select(name=>$p->{name}, size=>$p->{size}, selected=>$p->{selected}, options=>$p->{options}) ];
        }
        if( $p->{type} eq 'raw' )
        {
            $r_col = [ $p->{value} ];
        }

        if( $p->{type} eq 'submit' )
        {
            $r_col = [ v::submit($p->{value}) ];
        }

        if( defined $l_col)
        {
            $tbl->add('', 'll', $l_col, $r_col);
        }else
        {
            $tbl->add('', 'C', $r_col);
        }
    }
    $data = $tbl->show;
 }
 return "<form action='$base'$params>".v::input_h(%hiddens).$data."</form>";
}

sub redirect
{
    my $it = shift;
    if( !$ses::debug )
    {
        my $cookie = main::_set_cookie_str();
        my $url = $it->new(@_)->url( -separator => '&' );
        print "Status: 303\n".$cookie."Location: ".$url."\n\n";
        exit;
    }
    my $url = $it->new(@_)->url;
    main::ToTop 'Redirect to '.$url;
    main::Show(
        __PACKAGE__->new->a('redirect', -base=>$url,
        -style => 'display:block; text-align:center; width:100%; padding-top:150px; padding-bottom:150px; background-color: #ffffff;')
    );
    main::Exit();
}

# -----------------------------------------------------------
#
               package tbl;
#
# -----------------------------------------------------------

sub new
{
    my $cls = shift;
    my $it = {};
    bless $it, $cls;
    $it->set(%$cls) if ref $cls;
    $it->set(@_);
    $it->{-row1} = 'row1' if ! defined $it->{-row1};
    $it->{-row2} = 'row2' if ! defined $it->{-row2};
    return $it;
}

sub set
{
    my $it = shift;
    ref $it or die 'only obj context';
    my %param = @_;
    map{ $it->{$_} = $param{$_} } keys %param;
}

my $tc="td class='h_center'";
my $tr="td class='h_right'";
my $tl="td class='h_left'";

my %td = (
   'c' => [ $tc, 1 ],
   'l' => [ $tl, 1 ],
   'r' => [ $tr, 1 ],
   'C' => [ $tc, 2 ],
   'L' => [ $tl, 2 ],
   'R' => [ $tr, 2 ],
   '2' => [ $tc, 2 ],
   '3' => [ $tc, 3 ],
   '4' => [ $tc, 4 ],
   '5' => [ $tc, 5 ],
   '6' => [ $tc, 6 ],
   '7' => [ $tc, 7 ],
   '8' => [ $tc, 8 ],
   '9' => [ $tc, 9 ],
   't' => [ "$tc valign='top'", 1 ],
   'T' => [ "$tc valign='top'", 2 ],
   '^' => [ "$tl valign='top'", 1 ],
   '<' => [ "$tl valign='top'", 2 ],
   'E' => [ $tl, 3 ],
   ' ' => [ 'td', 1],
   '0' => [ "$tl style='width:1%' valign='top'", 1 ],
);

sub _row
{
    my($it,$row_class,$cmd,@cells) = @_;
    local $_;
    ref $it or die "only obj context";
    my $row = $it->{-row1};
    if( $row_class=~s/\*/$row/ )
    {
        ($it->{-row1},$it->{-row2}) = ($it->{-row2},$it->{-row1});
    }
    my $last_cols = $it->{cols};
    my $cols = 0;
    my $out = $row_class? "<tr class='$row_class'>" : '<tr>';
    if( ref $cmd eq 'ARRAY' )
    {
        my $head = '';
        foreach my $cell( @$cmd )
        {
            my $cls = v::filtr( shift @$cell );
            my $key = v::filtr( shift @$cell );
            my $val = v::filtr( shift @$cell );
            $out .= "<td class='$cls'>$val</td>";
            $head .= "<td class='$cls'>$key</td>";
            $cols++;
        }
        $it->{head} = "<thead><tr class='$it->{-head}'>$head</tr></thead>";
    }
     else
    {
        my @cmd = split //, $cmd;
        while( defined($_=shift @cmd) )
        {
            my $cell = shift @cells;
            $_ eq 'h' && next;
            my($td, $colspan) = @{$td{$_}};
            if( $last_cols && ! scalar @cmd )
            {# Последняя колонка и нам известно количество в прошлом ряду
                $colspan = $last_cols - $cols if ($last_cols - $cols)>0;
            }
            $td .= " colspan='$colspan'" if $colspan>1;
            $out .= "<$td>";
            $out .= v::filtr($cell);
            $out .= "</td>";
            $cols += $colspan;
        }
    }
    $it->{cols} ||= $cols;
    $it->{rows}++;
    return $out.'</tr>';
}

sub add
{
    my $it = shift;
    $it->{data} .= $it->_row(@_);
}

sub ins
{
    my $it = shift;
    $it->{data} = $it->_row(@_).$it->{data};
}

sub rows
{
    my $it = shift;
    return $it->{rows};
}

sub show
{
    my $it = shift;
    ref $it or die 'only obj context';
    $it->set(@_);
    my $prop = '';
    $prop .= " class='$it->{-class}'" if $it->{-class};
    $prop .= " style='$it->{-style}'" if $it->{-style};
    $prop .= " id='$it->{-id}'" if $it->{-id};
    return "<table$prop>".$it->{head}.$it->{data}."</table>";
}

# -----------------------------------------------------------
#
               package v;
#
# -----------------------------------------------------------
use Debug;

my $autoid_index = 0;

sub get_uniq_id
{
    return 'id'.$autoid_index++.'_'.int(rand 10**10);
}

sub filtr
{
    local $_=shift;
    ref $_ eq 'ARRAY' && return $_->[0];
    s|&|&amp;|g;
    s|<|&lt;|g;
    s|>|&gt;|g;
    s|'|&#39;|g;
    return $_;
}

sub tag
{
    my $tag = shift;
    my %p = @_;
    my $body = '';
    if( exists $p{-body} )
    {
        $body = ref $p{-body} eq 'ARRAY' ? $p{-body}[0] : filtr($p{-body});
        $body .= "</$tag>";
        delete $p{-body};
    }
    my $params = join ' ', map{ filtr($_)."='".filtr($p{$_})."'" } keys %p;
    return "<$tag $params>$body";
}

sub div
{
    my %p = @_;
    return tag('div', %p );
}

# Формирование элемента <input> типа hidden
# Вход: ( имя => значение, ... )
sub input_h
{
    my %p = @_;
    return( join '', map{ tag('input', type=>'hidden', name=>$_, value=>$p{$_}) } keys %p );
}


# Формирование элемента <input> типа text
sub input_t
{
    my %p = @_;
    $p{nochange} && return filtr($p{value});
    return tag('input', type=>'text', autocomplete=>'off', %p);
}

sub input_p
{
    my %p = @_;
    return tag('input', type=>'password', %p);
}

sub input_textarea
{
    my %p = @_;
    return v::tag('textarea', %p);
}

# имя, значение, колонок, строк
sub input_ta
{
    my($name,$value,$cols,$rows) = @_;
    return "<textarea name='$name' cols='$cols' rows='$rows'>".filtr($value).'</textarea>';
}

# --- Выпадающий список ---
=head
$_ = v::select(
    name     => 'grp',      # имя тега <select>
    size     => 1,          # размер выпадающего списка, необязательный параметр, по умолчанию = 1
    selected => $grp,       # какой пункт списка будет выбран
    nofit    => 'несуществующая группа', # если ни один пункт списка не будет выбран, то будет создан пункт с таким значением
    options  => [ 1,'первая группа', 2,'вторая группа' ]
);

# сортировка выпадающего списка:
$_ = v::select(
    name     => 'grp',
    size     => 1,
    selected => $grp,
    options  => { 2 => '2й в списке', 1 => '1й в списке' }
);
=cut
sub select
{
 my %p = @_;
 my $o = $p{options};
 my @options = ref $o eq 'ARRAY'? @$o :
               ref $o eq 'HASH'?  map{ $_ => $o->{$_} } sort{ $o->{$a} cmp $o->{$b} } keys %$o :
               ();
 my %selected = ref $p{selected}? map{ $_ => 1 } @{$p{selected}} : ($p{selected} => 1);
 my $options = '';
 my $was_selected;
 while( $#options>0 )
 {
    my $key = shift @options;
    my $val = shift @options;
    my $selected = exists $selected{$key}? " selected='selected'" : '';
    $key = v::filtr($key);
    $val = v::filtr($val);
    $was_selected = $val if $selected;
    $options .= "<option value='$key'$selected>$val</option>";
 }
 if( defined $p{nofit} && ! defined $was_selected )
 {
    my $key = v::filtr($p{selected});
    my $val = v::filtr($p{nofit});
    $options .= "<option value='$key' selected='selected'>$val</option>";
    $was_selected = $val;
 }

 $p{nochange} && return $was_selected;

 $p{multiple} = 'multiple' if ref $p{selected};

 delete $p{nofit};
 delete $p{selected};
 delete $p{options};
 delete $p{nochange};
 return tag('select', -body=>[$options], %p);
}

=head
v::checkbox(
    name    => 'chk_box',
    value   => '5',
    label   => 'five',
    checked => 1,
);
=cut
sub checkbox
{
    my %p = @_;
    $p{id} ||= get_uniq_id();
    my $tag = tag( 'input',
        type  => 'checkbox',
        name  => $p{name},
        value => $p{value},
        id    => $p{id},
        ($p{checked}? ( checked => 'checked' ) : ()),
    );
    $tag .= tag('label', for=>$p{id}, -body=>$p{label});
    return $tag;
}

=head
v::checkbox_list(
    name    => 'chk_box',
    list    => [ 1=>'one', 2=>'two' ],
    checked => '1,2',
    buttons => 1, # кнопки выбрать все/убрать все
);
=cut
sub checkbox_list
{
    my %p = @_;
    my @list = ref $p{list} eq 'ARRAY'? @{ $p{list} } :
               ref $p{list} eq 'HASH'?  %{ $p{list} } :
               ();
    my %checked = map{ $_ => 1 } split /,/, $p{checked};
    my $list = input_h( '__multi' => $p{name}, $p{name} => '' );
    while( scalar @list )
    {
        my $val = shift @list;
        my $label = shift @list;
        if( $val eq '' )
        {
            $list .= '<p>'.$label.'</p>';
        }
         else
        {
            $list .= main::_("[div data-value=$val]",
                checkbox(name=>$p{name}, value=>$val, checked=>$checked{$val}, label=>$label)
            );
        }
    }
    if( $p{buttons} )
    {
        my $div_id = get_uniq_id();
        $list = _('[div chkbox_list_buttons][]',
            _('[] | []',
                url->a($lang::chkbox_list_all,    -base=>'#chkbox_list_all',    -rel=>$div_id),
                url->a($lang::chkbox_list_invert, -base=>'#chkbox_list_invert', -rel=>$div_id),
            ),
            "<div id='$div_id'>$list</div>"
        );
    }
    return $list;
}


sub radio
{
    my %p = @_;
    $p{id} ||= get_uniq_id();
    my $tag = tag( 'input',
        type  => 'radio',
        name  => $p{name},
        value => $p{value},
        id    => $p{id},
        ($p{checked}? ( checked=>'checked' ) : ()),
    );
    $tag .= tag('label', for=>$p{id}, -body=>$p{label});
    return $tag;
}


sub submit
{
    return main::render_template( Doc->template_file('submit'), button_title=>$_[0] );
}

sub bold
{
    return "<b>$_[0]</b>";
}

sub commas
{
    return "&#171;$_[0]&#187;";
}

sub trim
{
    local $_=shift;
    s|^\s+||;
    s|\s+$||;
    return $_;
}

1;
