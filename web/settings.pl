# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

sub filtr_param
{
    local $_ = shift;
    s|\\|\\\\|g;
    s|'|\\'|g;
    s|\r||g;
    return $_;
}

sub next_line
{
    local $_;
    my($cfg_lines) = @_;
    while( defined($_ = shift @$cfg_lines) )
    {
        /^\s*#/ && next; # комментарий
        /^\s*$/ && next; # пустая строка
        if( /\s*(.)\s+(.+?)\s+(.+?)\s+(.*)$/ )
        {
            my @a = ($1, $2, $3, $4);
            $a[3] =~ s/^'//;
            $a[3] =~ s/'\s*$//;
            return @a;
        }
        debug 'error', _(L('Ошибочная строка').":\n[]", $_);
    }
    return undef;
}

sub go
{
    my($Url) = @_;
    my $edt_priv = Adm->chk_privil('SuperAdmin');
    $edt_priv or Adm->chk_privil_or_die('Admin');
    $edt_priv = '' if !$ses::auth->{trust};

    my $dir_config = "$cfg::dir_home/cfg/$cfg::Lang";

    opendir(my $dh, $dir_config) or
        Error_Lang('Не могу прочитать каталог [filtr|bold|p]Если существует, проверьте права доступа', $dir_config);
    my %configs = map{ $_ => 1 } grep{ /.cfg$/ } readdir($dh);
    closedir $dh;
    map{ delete $configs{$_} } grep{ s/^_// } keys %configs;

    my $tbl_made = tbl->new( -class=>'td_ok pretty width100' );
    my @cfg_lines = ();
    foreach my $file( keys %configs )
    {
        $file = "$dir_config/$file";
        open(my $f, '<', $file) or Error_($lang::cannot_load_file, $file);
        push @cfg_lines, $_ while( <$f> );
        close($f);
    }

    my $Fact = ses::input('act');

    if( $Fact eq 'save' )
    {
        $edt_priv or Error($lang::err_no_priv);

        my @lines = @cfg_lines;
        my $config = "package cfg;\nmy ";
        %cfg::LANG = () if ! keys %cfg::LANG;
        $config .= Debug->dump(\%cfg::LANG);
        $config .= "\n\%cfg::LANG = \%\$VAR1;\n";

        while( 1 )
        {
            my($type, $name, $params, $comment) = next_line(\@lines);
            defined $type or last;

            $type eq 'R' && next;

            $comment =~ s|\\n|<br>|g;
            $comment = [ $comment ];

            if( $type =~ /[sfnbe]/ )
            {  # параметр - переменная
                no strict;
                my $old = ${"cfg::$name"};
                use strict;
                my $new = $old;
                if( defined ses::input($name) )
                {
                    $new = ses::input($name);
                    $new =~ s|\s+$||; # уберем завершающие пробелы в переданных через форму данных
                    $new = $old if $params =~ /=/ && $new eq ''; # скрытый параметр и ничего не введено - не меняем
                    if( $new ne $old )
                    {
                        $tbl_made->add('', '^^^^', $comment, $old, $new, '');
                    }
                }
                if( $type eq 'f' && $new && !(-e $new) )
                {
                    $tbl_made->add('error', '^^^^', $comment, '', $new, L('Файл не существует'));
                }
                if( $type eq 's' || $type eq 'f' )
                {   # строковой параметр
                    $new =~ s|\n| |g if $params !~ /4|5/;
                    $new ="'".filtr_param($new)."'";
                }
                elsif( $type eq 'e' )
                {   # код
                    if( $new =~ /^\s*$/ )
                    {
                        $new = "''";
                    }
                     else
                    {
                        eval $new;
                        my $err = $@;
                        $err && $tbl_made->add('error', '^^^^', $comment, '', $new, L('Ошибка в коде: [filtr]', $err));
                        $new ="'".filtr_param($new)."'";
                    }
                }
                 elsif( $type eq 'n' )
                {   # число
                    $new =~ /^-?\d*\.?\d*$/ or
                        $tbl_made->add('error', '^^^^', $comment, '', $new, L('Параметр должен быть числом'));
                    $new += 0;
                }
                 else
                {   # type eq 'b'
                    $new = int $new;
                }

                $config .= "\$$name = $new;\n";
                next;
            }

            if( $type eq '@' )
            {   # параметр - массив.
                no strict;
                my @old = @{"cfg::$name"};
                use strict;
                my @new;
                if( defined ses::input($name) )
                {  # отфильтровываем символ 'возврат каретки' (\r)
                    my $v = ses::input($name);
                    $v =~ s/\n+|(\r\n)+/\n/g;
                    @new = split /\n/, $v;
                    if( "@new" ne "@old" )
                    {
                        $tbl_made->add('', '^^^^', $comment, '', '', '');
                    }
                }
                 else
                {
                    @new = @old;
                }

                $config .= "\@$name = (\n '".join("',\n '",map{ filtr_param($_) } @new)."'\n);\n";
                next;
            }

            if( $type =~ /^(M|m|g|h|l|%)$/ )
            {   # массив, трехэлементный хеш (элемент1 => "элемент2-элемент3") или хеш
                my %new = ();
                no strict;
                my %old = $type eq 'l' ? %{${"lang::$name"}} : %{"cfg::$name"};
                use strict;
                if( defined ses::input("$name#a1") )
                {
                    my $start = $type eq 'M' ? 0 : 1;
                    foreach my $i( $start .. 100 )
                    {
                        my $a = ses::input("$name#a$i");
                        my $b = ses::input("$name#b$i");
                        $a =~ s|\s+$||;
                        if( $type =~ /[lh%]/ )
                        {
                            $a eq '' && next;
                            $b =~ s|\s+$||;
                            $new{$a} = $b;
                            next;
                        }
                        if( $type eq 'g' )
                        {
                            $a =~ s|-|_|; # '-' является разделителем
                            $b =~ s|-|_|;
                            $b =~ s|\s+$||;
                            $a .= '-'.$b if $b ne '';
                        }
                        $a eq '' && next;
                        $new{$i} = $a;
                    }
                    if( join('',map{ $_.'|'.$new{$_}} sort keys %new)
                        ne
                        join('',map{ $_.'|'.$old{$_}} sort keys %old)
                    )
                    {
                        $tbl_made->add('', '^^^^', $comment, '', '', '');
                    }
                }
                 else
                {
                    $type eq 'l' && next;
                    %new = %old;
                }
            my $c = '';
            while( my($key, $val) = each %new )
            {
                $val = filtr_param($val);
                $key = filtr_param($key);
                $c .= " '$key' => '$val',\n";
            }
            $config .= $type eq 'l'
                ? "\$LANG{'$cfg::Lang'} ||= {};\n\$LANG{'$cfg::Lang'}{'$name'} = {\n$c};\n"
                : "\%$name = (\n$c);\n";
            next;
        }
    }

    # запишем конфиг в БД
    my $rows = Db->do("INSERT INTO config SET time=UNIX_TIMESTAMP(), data=?", $config);
    my @made = $rows<1? _('[span error]', L('Ошибка записи конфига в базу данных')) : L('Конфигурационный файл записан успешно');
    $tbl_made->rows && $tbl_made->ins(
        'head', 'llll',
        L('Параметр'),
        L('Было'),
        L('Стало'),
        L('Замечание'),
    );
    push @made, $tbl_made->show;
    if( ses::input('Passwd_Key') && ses::input('Passwd_Key') ne $cfg::Passwd_Key )
    {   # изменился ключ кодирования
        Db->do("UPDATE users SET passwd=AES_ENCRYPT(AES_DECRYPT(passwd,?),?)", $cfg::Passwd_Key, ses::input('Passwd_Key'));
        Db->do("UPDATE admin SET passwd=AES_ENCRYPT(AES_DECRYPT(passwd,?),?)", $cfg::Passwd_Key, ses::input('Passwd_Key'));
    }

    package cfg;
    no strict;
    eval $config;
    use strict;
    package main;

    debug('pre', $config);
    $Url->redirect( i => ses::input('i'), -made => join '<hr>', @made );
 }

 # =======       Отображение параметров      ===========

 my $first_tbl_line = '';
 my $save_button = 0;
 my %menu = ();
 my $selected_section = ses::input('i') || 'Main'; # выбранный раздел
 my $section = 0;      # счетчик разделов
 my $cur_section = ''; # текущий раздел
 my $tbl = tbl->new( -class => 'tune_tbl_narrow tune_tbl' );
 my @lines = @cfg_lines;
 while( 1 )
 {
    my($type, $name, $params, $comment) = next_line(\@lines);
    defined $type or last;

    if( $type eq 'R' )
    {   # Раздел конфига
        $cur_section = $params eq '-' ? $section : $params;
        ++$section;
        if( $selected_section eq $cur_section )
        {
            $first_tbl_line = $comment if $selected_section =~ /:/;
            $name ne '-' && $tbl->set( -class => $name.' tune_tbl' );
        }
        if( $cur_section =~ /:/ )
        {
            $cur_section =~ /^$selected_section:[^:]+$/ && $tbl->add('big wide', 'E', [ $Url->a($comment, i=>$cur_section) ], '');
            next;
        }
        my $s = (split /:/, $selected_section)[0];
        my $section_url = $Url->a($comment, i=>$cur_section, '-class'=>$cur_section eq $s? 'active' : '');
        $menu{$comment =~ /^\W/? '2'.$comment : $comment} = $section_url;
        next;
    }

    $cur_section eq $selected_section or next;

    $save_button = 1;

    $comment =~ s|\\n|<br>|g;

    no strict;
    if( $type eq 'C' )
    {
        $tbl->add('', 'E', [ ($tbl->rows() ? '<hr>' : '') . $comment ]);
        next;
    }
    if( $type =~ /^(M|m|g|h|l|C|%)$/ )
    {
        # массив или трехэлементный массив
        $tbl->add('', 'E', [ '<hr>' ]) if $tbl->rows();
        my %var = $type eq 'l' ? %{${"lang::$name"}} : %{"cfg::$name"};

        my $start = $type eq 'M' ? 0 : 1;
        # количество элементов хеша возъмем: текущее (приведенное к четному) + 8
        my $count = int((keys %var)/2 * 2) + 4 - $start;

        # вложенная таблица с 6 колонками (3 колонки на элемент хеша)
        my $tbl2 = tbl->new();
        my @cell = ();
        my @keys = keys %var;
        foreach my $i( $start .. $count )
        {
            my $val1 = $type =~ /[hl%]/ ? shift @keys : $var{$i};
            my $val2 = '';
            if( $type =~ /[l%]/ )
            {
                $val2 = v::input_t( name=>"$name#b$i", value=>$var{$val1}, class=>$params =~ /6/ ? 'wide' : '' );
            }
             elsif( $type eq 'g' )
            {
                $val2 = $val1 =~ s/^([^\-]+)-(.*)$/$1/ ? $2 : '';
                $val2 = v::input_t( name=>"$name#b$i", value=>$val2 );
            }
             elsif( $type eq 'h' )
            {
                $val2 = $var{$val1};
                $val2 = v::input_t( name=>"$name#b$i", value=>$val2 );
            }
            push @cell, [ _('№[bold]', $i) ], [ v::input_t( name=>"$name#a$i", value=>$val1 ) ], [ $val2 ];
            # scalar @cell < 6 && next;
            # $tbl2->add('*', 'llllll', @cell);
            $tbl2->add('', 'lll', @cell);
            @cell = ();
        }
        $params =~ /6/ ? $tbl->add('',  '3', [ $comment.$tbl2->show ] ) : $tbl->add('',  'L^', [ $tbl2->show ], [ $comment ]);
        next;
    }
    use strict;

    if( $type eq '@' )
    {
        no strict;
        my @val = @{"cfg::$name"};
        use strict;
        if( $name eq 'Plugins')
        {
            my $tbl2 = tbl->new( -class=>'td_wide', -head=>'head' );
            foreach my $cod( sort{ $a cmp $b } keys %$cfg::plugins )
            {
                my $plg = $cfg::plugins->{$cod};
                $plg->{type} eq 'user' or next;
                $plg->{param}{always_on} && next;
                my $title = $lang::start_user->{$cod} || '';
                $cod =~ s/^u_//;
                $tbl2->add('*', [
                    [ '', L('имя'),          $cod ],
                    [ '', L('пункт в меню'), [ $title ] ],
                    [ '', L('описание'),     CommonLocalize($plg->{param}{descr}) ],
                ]);
            }
            $tbl->add('*', 'E', [ _('[p][p][]',
                L('Список доступных плагинов').'. '.
                L('Некоторые плагины вспомогательные и не отображаются в меню клиентской статистики').'.',
                url->a(L('Подробнее о настройке меню'), -base=>'http://nodeny.com.ua/wiki/index.php/%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0_%D0%BC%D0%B5%D0%BD%D1%8E_%D0%BA%D0%B0%D0%B1%D0%B8%D0%BD%D0%B5%D1%82%D0%B0_%D0%B0%D0%B1%D0%BE%D0%BD%D0%B5%D0%BD%D1%82%D0%B0'),
                $tbl2->show
            )]);
        }
        $tbl->add('', 'E', [ '<hr>' ]) if $tbl->rows();
        $tbl->add('', '<^', [ v::input_textarea(-body=>join("\n", @val), name=>$name, class=>'wide', rows=>scalar(@val)+3) ], [ $comment ]);
        next;
    }

    no strict;
    my $val = ${"cfg::$name"};
    use strict;

    if( $type =~ /[sfne]/ )
    {  # параметр - переменная
        $val = '' if $params =~ /=/;
        if( $params =~ /4/ )
        {
            $tbl->add('', 'E', [ $comment.'<br>'.v::input_ta($name, $val, 255, 4) ]);
            next;
        }
        if( $params =~ /5/ )
        {
            $val = v::input_textarea( -body=>$val, name=>$name, class=>'wide tall' );
        }
         elsif( $params =~ /6/ )
        {
            $val = v::input_t( name=>$name, value=>$val, class=>'wide' );
            $tbl->add('', '<l', [ $val ], [ $comment ]);
            next;
        }
         else
        {
            $val = v::input_t( name=>$name, value=>$val );
        }
    }
     elsif( $type eq 'b' )
    {  # да/нет
        $val = "<select name='$name' size='1'>".
         ($val? "<option value=1 selected>".$lang::yes."<option value=0>".$lang::no."</option>" :
                "<option value=1>".$lang::yes."<option value=0 selected>".$lang::no."</option>").
        '</select>';
    }
     else
    {
        debug('error', L('Неизвестный код параметра []. имя: []', $type, $comment));
    }
    $tbl->add('', '^L', [ $val ], [ $comment ]);
 }

 $tbl->ins('big', 'E', [ $first_tbl_line ]) if $first_tbl_line;
 my $body;
 if( $edt_priv && $save_button )
 {
    $tbl->add('', '3', [ v::submit(L('Сохранить')) ]);
    $body = $tbl->show;
    $body = $Url->form('act'=>'save', 'i'=>$selected_section, $body);
 }
  else
 {
    $body = $tbl->show;
 }

 $menu{1} = url->a(L('Пользователи'), a=>'admin');

 ToLeft _('[div navmenu]', join '', map{ $menu{$_} } sort keys %menu );

 Doc->template('base')->{css_left_block} = 'block_with_menu';

 Show $body;
}

1;