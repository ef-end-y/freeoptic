#!/usr/bin/perl
# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
package nod::tmpl;
use strict;
use Debug;
use Exporter 'import';

our @EXPORT = qw( render );

my $mem = {};
my $cache = 1;
my $cur_dir = '';
my $var_index = 0;
our $filters = {};

add_filter('safe', \&_safe_filter);

sub cache
{
    ($cache) = @_;
}

sub set_cur_dir
{
    ($cur_dir) = @_;
}

sub override_template
{
    my($tmpl_name, $template) = @_;
    $mem->{$tmpl_name} = {
        source  => $template,
        compiled => '',
    };
}

sub render
{
    local $_;
    my($tmpl_name, %T) = @_;

    # open(FF, ">>/tmp/render.txt");
    # my $d = Debug->dump(\%T);
    # $d =~ s/^\$VAR1/\$T/;
    # print FF "\n\n===========\n Run render. Input data:\n$d\n\n".(ref $tmpl_name? "Template:\n".$$tmpl_name : "file $tmpl_name");

    my $code = "my \@forloops=();\n\$T{0} = '';\n";
    my $out_var = 0;
 {

    my $tmpl = '';
    if( ref $tmpl_name )
    {
        $tmpl = $$tmpl_name;
    }
     else
    {
        if( $cache && exists $mem->{$tmpl_name} )
        {
            my $compiled = $mem->{$tmpl_name}{compiled};
            if( $compiled ne '' )
            {
                # print FF "\n=== CACHE! ===";
                $code = $compiled;
                last;
            }
            $tmpl = $mem->{$tmpl_name}{source};
            # print FF "\n\n Overriden template:\n$tmpl";
        }
        if( $tmpl eq '' )
        {
            open( my $f, "<:raw", $tmpl_name ) or die "cannot load file $tmpl_name";
            binmode($f);
            $tmpl .= $_ while(<$f>);
            close($f);
            $cur_dir = $tmpl_name;
            $cur_dir =~ s/[^\/]+$//;
        }
    }

    # NoDeny тег one_line, указывающий в блоке серию пробелов и переводы строк заменить одним пробелом
    $tmpl =~ s|\{% *one_line *%\}(.+?)\{% *one_line_end *%\}|_to_space($1)|eis;


    # В $code формирует $T{index} = 'текст на входе'; и возвращает index
    sub to_hash
    {
        my($code, $tab, $text) = @_;
        $var_index++;
        $text =~ s|\\|\\\\|g;
        $text =~ s|'|\\'|g;
        $$code .= _tabs($tab)."\$T{$var_index} = '$text';\n";
        return $var_index;
    }

    # Все, что не является управляющей последовательностью, заменяем на {{переменная}}.
    #    Здравствуйте.{% if show_time %} Сегодня {{time}}!{% endif %}
    # Будет сконвертировано в
    #    {{1}}{% if show_time %}{{2}}{{time}}{{3}}{% endif %}
    # А в $code:
    #   $T{1} = 'Здравствуйте.'; $T{2} = ' Сегодня '; $T{3} = '!';
    # В итоге $tmpl будет состоять исключительно из управляющих последовательностей
    $tmpl = '}}'.$tmpl.'{{'; # чтобы текст в начале и конце темплейта был захвачен в регексп
    $tmpl =~ s/(\}\}|%\})(.*?)(\{\{|\{%)/$1.'{{'.to_hash(\$code,0,$2).'}}'.$3/egs;
    chop $tmpl;
    chop $tmpl;
    $tmpl =~ s/^..//;

    my @tmpl = split /\{%/,$tmpl;
    my $tab = 0;
    $tmpl[0] = '%}'.$tmpl[0];

    my @out_vars = ($out_var);
    foreach my $block( @tmpl )
    {
        my $tag = _trim( $block =~ s|^(.*?)%\}|| ? $1 : $block );
        my($com, $p) =  split /\s+/, $tag, 2;
        $com = lc $com;
        if( $com eq 'if' || $com eq 'elif' )
        {
            # В $p условие
            # Все, что в кавычках вынесем в переменные
            $p =~ s/['"](.*?)['"]/'{{'.to_hash(\$code,$tab,$1).'}}'/egs;
            $p =~ s|([A-Za-z_][\w\.:\[\]\(\)\{\}]*)|get_var($1)|eg;
            $p =~ s|\{(\{.+?\})\}|\$T$1|g;
            $p =~ s|==|eq|g;
            if( $p !~ /\s/ )
            {
                $p = "ref $p eq 'ARRAY'? scalar @"."{$p} : ref $p eq 'HASH'? keys %"."{$p} : $p";
            }
            $code .= _tabs($tab).($com eq 'if' ? "if( $p ) {" : "} elsif( $p ) {");
            $tab++;
        }
        if( $com eq 'else' )
        {
            $code .= _tabs($tab-1)."} else {";
        }
        if( $com eq 'endif' )
        {
            $code .= _tabs(--$tab)."}";
        }
        if( $com eq 'eval' )
        {
            $p =~ s|([A-Za-z_][\w\.:\|]*)|get_var($1)|eg;
            $code .= _tabs($tab)."$p;";
        }
        if( $com eq 'include' )
        {
            $p = _trim($p);
            my($file_name, $param) = split /\s+/, $p, 2;
            if( $file_name =~ s|^\s*['"]|| )
            {
                $file_name =~ s|['"]\s*$||;
                my $dir = $cur_dir;
                if( $file_name =~ s|^\.\./|| )
                {
                    $dir =~ s|[^/]+/$||;
                }
                $file_name = "'$dir$file_name'";
            }
             else
            {
                $file_name = "\$T{'$file_name'}";
            }
            if( $param ne '' )
            {
                # Все, что в кавычках вынесем в переменные
                $param =~ s/['"](.*?)['"]/to_hash(\$code,$tab,$1)/egs;
                my @params = ();
                foreach my $pair( split /\s+/, $param )
                {
                    $pair =~ /(.+)=>?(.+)/ or next;
                    my($k, $v) = ($1, $2);
                    $v = get_var($v);
                    push @params, "$k => $v";
                }
                $param = join ', ', @params;
            }
             else
            {
                $param = '%T';
            }
            my $k = get_var($out_var);
            $code .= _tabs($tab)."$k .= render($file_name, $param);";
        }
        if( $com eq 'for' )
        {
            my($var, $array) = split / +in +/, $p, 2;
            $array = get_var($array);
            $code .= _tabs($tab)."push \@forloops, \$T{forloop};\n";
            $code .= _tabs($tab)."my \$a = ref $array eq 'ARRAY'; \$T{forloop} = {counter=>0, is_array=>\$a};\n";
            $code .= _tabs($tab)."foreach( \$a ? \@{$array} : values \%{$array} ){\n";
            $code .= _tabs(++$tab)."\$T{$var} = \$_; my \$b = ++\$T{forloop}{counter};\n";
            $code .= _tabs($tab)."\$T{forloop}{last} = \$T{forloop}{is_array} && \$b == scalar \@{$array};";
            
        }
        if( $com eq 'endfor' )
        {
            $code .= _tabs(--$tab)."}\n";
            $code .= _tabs($tab)."\$T{forloop} = pop \@forloops;";
        }
        if( $com eq 'block' )
        {
            push @out_vars, $out_var;
            $out_var = _trim($p);
            $code .= _tabs($tab).get_var($out_var)." = '';\n";
        }
        if( $com eq 'global_block' )
        {
            push @out_vars, $out_var;
            $out_var = _trim($p);
        }
        if( $com eq 'endblock' )
        {
            $out_var = shift @out_vars;
        }
        $code .= "\n";

        $block =~ s/\{\{\}\}//g;
        $block =~ s/\{\{ *(.*?) *\}\}/get_var($1).'.'/eg;
        $code .= _tabs($tab).get_var($out_var, 1)." .= $block'';\n";
    }

    #if( $tmpl_name =~ /\/base.html$/ ) {
    #    debug('pre', $code);
    #    die;
    #}
    $mem->{$tmpl_name}{compiled} = $code;
 }

    # print FF "\n\n-----\n Render end:\n\n $code\nreturn \$T\{$out_var\}";
    eval $code;
    if( my $err = $@ )
    {
        debug('pre', $code);
        die "Ошибка рендеринга $tmpl_name\n$err";
    }

    return $T{$out_var};
}

sub _tabs
{
    return $_[0]>0 && "\t" x $_[0];
}

sub add_filter
{
    my($name, $filter) = @_;
    $filters->{$name} = $filter;
}

sub _trim
{
    local $_=shift;
    s|^\s+||;
    s|\s+$||;
    return $_;
}

sub _to_space
{
    my($text) = @_;
    $text =~ s| *\n+ *| |g;
    return $text;
}

# Конвертация в perl код переменной в шаблоне
#
# or/and/eq не считаются переменной
#
# var1.var2.var3 конвертится в $T{var1}->{var2}->{var3}
# var1.var2().var3 конвертится в $T{var1}->var2()->{var3}

sub get_var
{
    my($var, $dont_check_ref) = @_;
    $var =~ /^(or|and|not|eq|ne)$/ && return $var;
    my @filter;
    ($var, @filter) = split / *\| */, $var;
    if( $var =~ /^(lang|cfg|ses|template)::([^\.]+)\.?(.*)$/ )
    {
        $var = "\$$1::$2".join('', map{ /\)$/ ? "->$_" : "->{$_}" } split /\./, $3);
    }
     else
    {
        my $res = '$T';
        my $i = 1;
        my $prefix = '';
        my $v;
        foreach my $w ( split /\./, $var )
        {
            if( $w =~ /\)$/ )
            {
                $v = $w;
                $prefix = '->';
                next;
            }
            if( $w =~ /\[(.+)\]/ )
            {
                $v = "{\$T{$1}}";
                next;
            }
            if( $w !~ /^\d+$/ || $dont_check_ref || $i )
            {
                $v = $w =~ /[\x80-\xff]/? "{'$w'}": "{$w}";
                next;
            }
            $res = "(ref $res eq 'ARRAY'? $res"."[$w] : $res"."{$w})";
            $prefix = '->';
            $v = '';
        }
         continue
        {
            $res .= $prefix.$v;
            $i = 0;
            $prefix = '';
        }
        $res =~ s/\->$//;
        $var = $res;
        #$var = '$T'.join('->', @res);
        #ref($T) eq 'ARRAY'? $T
        # map{ /\)$/? $_ : /\[(.+)\]/? "{\$T{$1}}":  } split /\./, $var);
    }
    foreach my $filter( @filter )
    {
        $filters->{$filter} or next;
        $var = "&{\$nod::tmpl::filters->{'$filter'}}($var)";
    }
    return $var;
}

sub _safe_filter
{
    local $_=shift;
    ref $_ eq 'ARRAY' && return $_->[0];
    s|&|&amp;|g;
    s|<|&lt;|g;
    s|>|&gt;|g;
    s|'|&#39;|g;
    return $_;
}

1;