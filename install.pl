#!/usr/bin/perl
# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package install;
use strict;
use FindBin;
use lib $FindBin::Bin;
use nod;

my $def_config = q{
package cfg;
$net_title = 'Test Network';
$img_dir = '';
$Lang = 'EN';
$languages = 'UA, RU, EN';
$web_session_ttl = 86400;
$fibers_common_for_all = 0;
$fibers_collective_data = 0;
$fibers_map_api_key = '';
1;
};

$< == 0 or die 'Must run as root';

my $M = __PACKAGE__->new(
    file_cfg => 'freeoptic.cfg',
    file_log => 'install.log',
);

my $cmd;
my $set_pass;
my $chown;
my $debuging_file;

$M->{cmd_line_options} = {
    'p=s%'  => \$set_pass,
    'w=s'   => \$chown,
    'm'     => sub{ $cmd = \&make_config; },
    'x'     => sub{ $cmd = \&make_modules; },
    't=s'   => \$debuging_file,
};

$M->{help_msg} =  <<MSG;
    -p login=pass : create superuser with login=login and password=pass
    -w=www  : chmod the project
    -m      : create start config
    -x      : connect all modules
    -t=file : file processing detail info
MSG

$M->Start;

$cfg::sql_err = 'sql error. Run with -v';

if( $cmd )
{
    __PACKAGE__->$cmd;
    exit;
}

if( $set_pass )
{
    tolog 'Create superuser';
    my($login, $pass) = %$set_pass;
    if( $login =~ /\W/ || length $login < 2 )
    {
        tolog 'login required more than 1 character';
        exit;
    }
    if( !defined $pass )
    {
        tolog 'password required';
        exit;
    }
    my $rows = Db->do(
        "INSERT INTO admin SET privil=',1,3,', login=?, passwd=AES_ENCRYPT(?,?)",
        $login, $pass, $cfg::Passwd_Key
    );
    tolog $rows<1? '[!] Sql error' : "Superuser $login created";
}

if( defined $chown )
{
    $cfg::dir_home or die '!';
    my @cmd = (
        "[ -d $cfg::dir_home/logs ] || mkdir $cfg::dir_home/logs",
        "chown -R {{www}} $cfg::dir_home",
        "chmod -R 500 $cfg::dir_home",
        "chmod -R 400 \$(find $cfg::dir_home ! -type d)",
        "chmod 500 $cfg::dir_home",
        "chmod -R 600 $cfg::dir_home/logs",
        "chmod 700 $cfg::dir_home/logs",
        "chmod 500 $cfg::dir_home/cgi-bin/*",
    );
    foreach my $cmd( @cmd )
    {
        $cmd =~ s/\{\{www\}\}/$chown/g;
        tolog $cmd;
        tolog `$cmd`;
    }
}

sub make_config
{
    tolog 'Start config creation';
    Db->line('SELECT 1');
    Db->is_connected or return tolog '[!] No DB connection. Check sat.cfg';
    my $rows = Db->do("INSERT INTO config SET time=UNIX_TIMESTAMP(), data=?", $def_config);
    tolog $rows<1? 'Sql error' : 'Config is created';
}

sub make_modules
{
    tolog '<<< Connect all modules >>>';
    $cfg::dir_home or die '!';

    @warnings::messages = ();

    my %p = Db->line("SELECT * FROM config ORDER BY time DESC LIMIT 1");
    if( %p )
    {
        $cfg::config = $p{data};
        eval "
            no strict;
            $cfg::config;
            use strict;
        ";
    }

    system("find $cfg::dir_home -name '_*' -type f -delete");
    my $mod_dir = "$cfg::dir_home/modules";
    opendir(my $dh, $mod_dir) or return tolog "[!] Cannot read directory $mod_dir";
    my @mod_dirs = sort grep{ -d "$mod_dir/$_" } grep{ /^[^\.]/ } readdir($dh);
    closedir $dh;

    my $debuging_dir = $debuging_file =~ s|^.*?([^/]+)/([^/]+)$|$2| ? $1 : '';

    tolog "enable debug for dir: $debuging_dir, file: $debuging_file" if $debuging_file;

    my %files = ();
    my %block = ();
    foreach my $dir( sort @mod_dirs )
    {
        tolog "\n--- Module $dir ---" if !$debuging_file;
        my $full_dir = "$mod_dir/$dir";
        my $debug_in_this_dir = $dir eq $debuging_dir;
        tolog "Scanning $full_dir" if $debug_in_this_dir;
        my $filtr = '(patch|create)\.';
        my $enabled = 1;
        if( -e "$full_dir/no" )
        {
            tolog "File 'no' - ignore the module" if !$debuging_file;
            $enabled = 0;
            $filtr = '(patch)\.NOW\.';
        }
        opendir(my $dh, $full_dir) or return tolog "[!] Cannot read directory $full_dir";
        my @all_files = readdir($dh);
        closedir $dh;

        if( $debug_in_this_dir )
        {
            (grep{ $_ eq $debuging_file } @all_files)? tolog "file not found" : tolog "file not found!!!";
        }

        # --- SQL ---
        foreach my $file( @all_files )
        {
            $file =~ /^sql\./ or next;
            my $f = "$full_dir/$file";
            open(my $fh, '<', $f) or return tolog "[!] Cannot read file $f";
            my $data = join '', <$fh>;
            close $fh;
            Db->do($data);
        }

        # --- Запуск файла  ---
        if( $enabled )
        {
            foreach my $file( @all_files )
            {
                $file =~ /^run\./ or next;
                require "$full_dir/$file";
            }
        }

        my @patch_files = grep{ -e "$full_dir/$_" } grep{ /^$filtr/ } @all_files;
        
        if( $debug_in_this_dir )
        {
            (grep{ $_ eq $debuging_file } @patch_files)
                ? tolog "valid file name ^$filtr"
                : tolog "invalid file name ^$filtr !!!";
        }

        foreach my $patch_file( sort @patch_files )
        {
            my $f = "$full_dir/$patch_file";
            my $debug_this_file = $debug_in_this_dir && $debuging_file eq $patch_file;
            tolog "load $f ..." if $debug_this_file;

            open(my $fh, '<', $f) or return tolog "[!] Cannot read file $f";
            my $data = join '', "\n", <$fh>;
            close $fh;

            tolog "File $patch_file" if !$debuging_file;
            my @blocks = split "\n#<ACTION>", $data; 
            shift @blocks;

            tolog 'no line started with <ACTION>!!!' if $debug_this_file && !scalar @blocks;

            foreach my $block( sort @blocks )
            {
                $block =~ s/^ *([^\n]+) *\n// or next;
                my $param = "{ $1 }";
                tolog "  $param" if !$debuging_file or $debug_this_file;   
                $param = eval $param;

                my $file = $param->{file} or return tolog '  [!] file parameter required';
                my $name = $dir.':'.$file;

                $block{$name}->{debug} = 1 if $debug_this_file;

                if( my $require = $param->{require} )
                {
                     $require = [ $require ] if ! ref $require;
                    push @{$block{$name}->{require}}, @$require;
                }
                # после каких модулей нужно ставить патч (могут не существовать)
                if( my $after = $param->{after} )
                {
                    tolog "patch the file after module: $after" if $debug_this_file;
                    $after = [ $after ] if ! ref $after;
                    push @{$block{$name}->{after}}, @$after;
                }
                if( exists $param->{hook} )
                {
                    tolog "patch hook: $param->{hook}" if $debug_this_file;
                    push @{$block{$name}->{blocks}}, {
                        create => ($patch_file =~ /^create/ || 0),
                        hook   => $param->{hook},
                        code   => $block,
                    };
                }
                if( exists $param->{replace} )
                {
                    my($from, $to) = split /#<REPLACE>/, $block, 2;
                    push @{$block{$name}->{blocks}}, {
                        create    => 0,
                        replace   => $from,
                        code      => $to,
                    };
                }
            }
        }
    }

    tolog '-' x 50;

    my %filesave_report = ();

    my %existing_modules = map{ $_ => 1 } keys %block;

    while( keys %block )
    {
        my $deadlock = 1;

        MAIN : foreach my $mod_w_file(sort keys %block )
        {
            my($module, $file) = split /:/, $mod_w_file;   
            my $data = $block{$mod_w_file};
            if( $debuging_file )
            {
                if( $data->{debug} )
                {
                    tolog  '<<<<<<', $data, '>>>>>>';
                    $filesave_report{$file} = 1;
                }
            }
             else
            {
                tolog "Patching $file by $module";
                $filesave_report{$file} = 1;
            }

            # --- dependencies checking ---
            my $check_existence = 1;
            foreach my $req_mod( @{$data->{require}}, '', @{$data->{after}} )
            {
                if( $check_existence && $req_mod eq '' )
                {
                    $check_existence = 0;
                    next;
                }
                my $req_mod_w_file = $req_mod.':'.$file;
                if( !$existing_modules{$req_mod_w_file} )
                {
                    $check_existence && return tolog "[!] зависит от $req_mod_w_file, которого нет в папке modules";
                    # патч не ставим т.к. нет необязательного модуля после которого мы должны его поставить
                    delete $block{$mod_w_file};
                    next MAIN;
                }
                if( $block{$req_mod_w_file} )
                {
                    tolog "  зависит от $req_mod_w_file, который еще не обработан";
                    next MAIN;
                }
            }

            $deadlock = 0;
            delete $block{$mod_w_file};

            # --- patching ---
            foreach my $param( sort @{$data->{blocks}} )
            {
                if( $param->{create} )
                {
                    $files{$file} = "\n#<HOOK>new\n";   
                }
                if( !$files{$file} )
                {
                    open(my $fh, '<', $file) or return tolog "[!] cannot read $file";
                    $files{$file} = join '', "\n",<$fh>;
                    close $fh;
                    tolog "  $file is read" if $data->{debug};
                }
                if( $file =~ /html$/i )
                {
                    $files{$file} =~ s/<!--(.+?)-->/$1/sg;
                }
                if( my $hook = $param->{hook} )
                {
                    my $code = $param->{code};
                    $code =~ s/^\n+/\n/;
                    $code =~ s/\n+$//;
                    tolog "  Патчим хук: $hook" if $data->{debug};
                    my $n = ($files{$file} =~ s|(\n[#/]/?\s*<HOOK>\s*$hook\s*\n)|$code\n$1|g);
                    $n or return tolog "[?] hook not found: $hook";
                    tolog "  $n fragments are replaced" if $data->{debug};
                }
                if( my $replace = $param->{replace} )
                {
                    my $code = $param->{code};
                    $files{$file} =~ s/\Q$replace\E/$code/ or return tolog "[?] $file: fragment not found:\n$replace";
                    $files{$file} =~ /\Q$replace\E/ && return tolog "[?] $file: more than one fragment:\n$replace";
                }
            }
        }
        $deadlock && return tolog "[!] deadlock";
    }

    foreach my $file( sort keys %files )
    {
        my $new_file = $file;
        $new_file = "_$new_file" if $new_file !~ s|/([^/]+)$|/_$1|s;
        $files{$file} =~ s/\n+[#\/]\/?\s*<HOOK>[^\n]*\n*(?=\n|$)/$1/g;
        $new_file = "$cfg::dir_home/$new_file";
        tolog "Writing $new_file" if $filesave_report{$file};
        open(my $fh, '>', $new_file) or return tolog "[!] Cannot write file $new_file";
        print $fh $files{$file};
        close $fh;
    }
    local $SIG{'__DIE__'} = sub {};
    eval 'use JSON';
    $@ && tolog "\n\n".$@."\n\n"."Install modules JSON and JSON-XS! Or reinstall";

    foreach my $msg( @warnings::messages )
    {
        tolog $msg;
    }
}

1;
