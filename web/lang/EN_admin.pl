package lang;

$admin = {

    main_menu => [
      [ 1 => [ 'User list', act=>'list' ] ],
      [ 0 => [ 'Create', act=>'new', '-data-ajax-into-here'=>1 ] ],
      [ 1 => [ 'Main settings', a=>'settings' ] ],
    ],

    priv_descr => [

        { priv => 1,   title => 'Access' },
        { priv => 3,   title => 'Admin' },
    ],

    no_admin_exists       => 'There are no user in the database',
    admin_not_exists      => 'There is no user with id = [bold]',

    admin_create_question => 'Create a new user?',
    admin_del_question    => 'Delete user [filtr|bold]?',

    admin_is_created      => 'User created',
    admin_is_deleted      => 'User deleted',

    fields => {
        login       => 'Login',
        name        => 'Name',
        password    => 'Password',
        is_on       => 'Access',
        is_admin    => 'Admin',
    },

    where_is_id   => 'User id not specified',
};
