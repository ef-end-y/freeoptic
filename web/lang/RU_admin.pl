package lang;

$admin = {

    main_menu => [
      [ 1 => [ 'Список пользователей', act=>'list' ] ],
      [ 0 => [ 'Создать', act=>'new', '-data-ajax-into-here'=>1 ] ],
      [ 1 => [ 'Главные настройки', a=>'settings' ] ],
    ],

    priv_descr => [

        { priv => 1,   title => 'Доступ включен' },
        { priv => 3,   title => 'Админ' },
    ],

    no_admin_exists       => 'Не существует ни одного пользователя в БД',
    admin_not_exists      => 'Не существует пользователя с id = [bold]',

    admin_create_question => 'Создать нового пользователя?',
    admin_del_question    => 'Удалить пользователя [filtr|bold]?',

    admin_is_created      => 'Создана пользователь',
    admin_is_deleted      => 'Удалена пользователь',

    fields => {
        login       => 'Логин',
        name        => 'Имя',
        password    => 'Пароль',
        is_on       => 'Доступ',
        is_admin    => 'Админ',
    },

    where_is_id   => 'Не указан id пользователя',

    'User list'   => 'Список пользователей',
};

1;