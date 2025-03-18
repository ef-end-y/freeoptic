package lang;

$admin = {

    main_menu => [
      [ 1 => [ 'Список користувачів', act=>'list' ] ],
      [ 0 => [ 'Створити', act=>'new', '-data-ajax-into-here'=>1 ] ],
      [ 1 => [ 'Головні налаштування', a=>'settings' ] ],
    ],

    priv_descr => [

        { priv => 1,   title => 'Доступ включено' },
        { priv => 3,   title => 'Адмін' },
    ],

    no_admin_exists       => 'Не існує жодного користувача в БД',
    admin_not_exists      => 'Не існує користувача з id = [bold]',

    admin_create_question => 'Створити нового користувача?',
    admin_del_question    => 'Видалити користувача [filtr|bold]?',

    admin_is_created      => 'Створено користувача',
    admin_is_deleted      => 'Видалено користувача',

    fields => {
        login       => 'Логін',
        name        => "Iм'я",
        password    => 'Пароль',
        is_on       => 'Доступ',
        is_admin    => 'Адмін',
    },

    where_is_id   => 'Не вказаний id користувача',

    'User list'   => 'Список користувачів',
};

1;