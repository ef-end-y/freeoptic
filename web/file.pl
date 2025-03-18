# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

$ENV{QUERY_STRING} =~ /^a=_(js|css)&file=(\w+)$/ or die;

my $file = $1 eq 'js'? "$cfg::dir_home/htdocs/js/$2.js" : "$cfg::dir_home/htdocs/$2.css";
my $header = 'Content-type: '.($1 eq 'js'? 'application/javascript' : 'text/css')."\n";

my $fh;
my $data = open($fh, '<', $file)? join('',<$fh>) : "$file is not found";
$fh && close $fh;

eval "use Digest::MD5 qw( md5_base64 )";
my $hash = '"'.Digest::MD5->new->add($data)->hexdigest().'"';
$header .= qq{ETag: $hash\n};

if( $ENV{'HTTP_IF_NONE_MATCH'} eq $hash )
{
    eval "use CGI";
    print CGI->new->header(-status=>304);
}
 else
{
    print "$header\n$data";
}

exit;

1;