# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;


sub go
{
    my $Url = shift;

    my $nodeny_api_url;
    my $nodeny_domain;
    my $uid;
    my $ajax_cmd;
    my $error_msg;
    my $sql_or_superadmin = '';
    my $is_preview = 0;
    my $units_count = 0;

    my $role = $ses::auth->{role};
    if( $role eq 'admin' )
    {
        $nodeny_api_url = $ses::script_url;
        $nodeny_domain = '';
        Adm->chk_privil('801') && Error('Not supported');
        $uid = $ses::auth->{adm}{uid};
        $ajax_cmd = 'ajFibers';
        $sql_or_superadmin = 'OR TRUE' if Adm->chk_privil('SuperAdmin');
    }
     else
    {
        Error('Access denied (wrong role)');
    }

    my $action = ses::input('action');

    if( $action eq 'new_scheme' )
    {
        my $gid = md5_base64(rand 10**10); $gid =~ s/[\+\/]//g;
        my $name = '';
        if( $uid )
        {
            my %p = Db->line("SELECT COUNT(*) AS n FROM fibers_schemes WHERE uid=?", $uid);
            $name = 'Scheme '.($p{n}+1) if %p;
        }
        Db->do(
            "INSERT INTO fibers_schemes SET shared=?, gid=?, uid=?, name=?",
             ($cfg::fibers_common_for_all || !$uid ? 2 : 0), $gid, $uid, $name
        );
        Db->ok or Error(L('DB error'));
        $Url->redirect( gid=>$gid );
    }

    my $gid = ses::input('gid');
    my $inner_data_db = 0;
    if( $gid )
    {
        my %p = Db->line(
            "SELECT s.id, s.is_block, s.inner_data_db, ".
            "(SELECT COUNT(*) FROM fibers_units WHERE removed=0 AND scheme_id=s.id) AS units ".
            "FROM fibers_schemes s WHERE (s.shared>0 OR s.uid=? $sql_or_superadmin) AND s.gid=?",
            $uid, $gid
        );
        if( %p )
        {
            $nodeny_api_url .= '?gid='.$gid;
            $inner_data_db = !!length($p{inner_data_db});
            $is_preview = int($action eq 'preview');
            $units_count = $p{units};
        }
         else
        {
            $gid = undef;
            $error_msg = L('Scheme does not exist');
            $error_msg .= '<br>or it will be accessible after login' if !$uid;
        }
    }

    my $schemes = [];
    my $favorite_schemes = [];

    {
        my $access_condition = $cfg::fibers_common_for_all ? '(uid=? or shared>0)' : 'uid=?';
        my $db = Db->sql(
            "SELECT *, (SELECT COUNT(*) FROM fibers_units WHERE removed=0 AND scheme_id=fs.id) AS units, ".
            "(SELECT MAX(time) FROM fibers_history WHERE scheme_id=fs.id) AS last_modified ".
            "FROM fibers_schemes fs WHERE is_block=0 AND $access_condition ORDER BY last_modified DESC", $uid
        );
        while( my %p = $db->line )
        {
            $p{url} = $Url->url(gid=>$p{gid});
            $p{name} = $p{name} eq '' ? $p{gid} : length($p{name}) < 4 ? 'scheme '.$p{name} : $p{name};
            $p{last_modified} = $p{last_modified} ? the_short_time($p{last_modified}, 1) : '';
            if( $p{favorite} && $p{uid} == $uid ) { push @$favorite_schemes, \%p }
              elsif( $cfg::fibers_common_for_all || $p{uid} == $uid ){ push @$schemes, \%p }
        }
    }

    my $url = $Url->new(gid=>$gid);
    my %params = (
        a_plugin         => $ajax_cmd,
        nodeny_api_url   => $nodeny_api_url,
        nodeny_domain    => $nodeny_domain,
        lang             => $lang::ajFibers,
        scheme           => $gid,
        schemes          => $schemes,
        favorite_schemes => $favorite_schemes,
        Url              => $url,
        is_guest         => 0,
        is_preview       => $is_preview,
        is_admin         => Adm->chk_privil('SuperAdmin'),
        inner_data_db    => $inner_data_db,
        units_count      => $units_count,
        error_msg        => $error_msg,
    );

    if( $role eq 'ext_user' )
    {
        $params{set_ses} = $ses::auth->{ses};
        $ses::cmd = {
            header => render_template('fibers/header.html', %params),
            js => render_template('fibers/index.js', %params),
            body => render_template('fibers/index.html', %params),
        };
    }
     else
    {
        my $tmpl = ses::input_int('map_view') && $gid ? 'fibers_map/index' : 'fibers/index';
        Doc->template('base')->{Url} = $url;
        Show render_template($tmpl, %params);
    }
}

1;
