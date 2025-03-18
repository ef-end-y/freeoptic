# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

sub go
{
 my($Url) = @_;
 Db->do('UPDATE websessions SET trust=0 WHERE BINARY ses=?', $ses::auth->{ses});

 url->redirect( -made=>
    L('Правильно сделали, что переключились в безопасный режим - это ничего не меняет, кроме блокировки важных операций.').' '.
    L('Если отлучитесь от компа, никто не навредит.')
 );

}

1;