# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;

die;

$ses::set_cookie->{$cfg::cookie_name_for_ses} = {
    value => ses::input('ses'),
    SameSite => 'None',
    Secure => '',
};


1;