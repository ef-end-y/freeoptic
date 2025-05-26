package lang;

sub UcFirst
{
    my($str) = @_;
    utf8::decode($str);
    $str = ucfirst $str;
    utf8::encode($str);
    return $str;
}

$yes    = 'Да';
$no     = 'Нет';
$on     = 'Вкл';
$off    = 'Выкл';
$Now    = 'Сейчас';

$msg_after_submit   = 'Ждите...';
$msg_Changes_saved  = 'Изменения сохранены';

$error              = 'Ошибка';
$err_no_priv        = 'Недостаточно привилегий.';
$err_try_again      = 'Произошла временная ошибка. Попробуйте повторить запрос.';
$cannot_load_file   = 'Не могу загрузить файл []';
$cannot_save_file   = 'Не могу записать файл []';
$err_unauthorized   = 'Вы не авторизованы';

$Help               = 'Справка';
$today              = 'сегодня';
$today_at           = 'сегодня в';
$Today_at           = UcFirst($today_at);
$hidden             = 'скрыто';
$sec                = 'сек';

$lbl_data           = 'Данные';
$lbl_time           = 'Время';

$lbl_operations     = 'Операции';
$lbl_admin          = 'админ';
$lbl_comment        = 'комментарий';
$lbl_Comment        = UcFirst($lbl_comment);
$lbl_year           = 'год';
$lbl_Year           = UcFirst($lbl_year);

# Кнопки
$btn_enter          = '&nbsp;&nbsp;Вход&nbsp;&nbsp;';
$btn_logout         = 'Выход';
$btn_go_next        = 'Далее';
$btn_save           = 'Сохранить';
$btn_cancel         = 'Отменить';
$btn_delete         = 'Удалить';
$btn_create         = 'создать';
$btn_Create         = UcFirst($btn_create);
$btn_Change         = 'Изменить';
$btn_Execute        = 'Выполнить';
$btn_add            = 'добавить';
$btn_Add            = UcFirst($btn_add);

$chkbox_list_all    = 'Все';
$chkbox_list_invert = 'Инверсия';

$mLogin_login       = 'Логин';
$mLogin_pass        = 'Пароль';

$start_admin = {

};

$ajFibers = {
    'No' => 'Нет',
    'ReadOnly' => 'Только просмотр',
    'FullAccess' => 'Полный доступ',
    'Redo' => 'Повторить',
    'Undo' => 'Отменить',
    'Copy' => 'Копировать',
    'Paste' => 'Вставить',
    'Save' => 'Сохранить',
    'Show' => 'Показать',
    'Show_all' => 'Показать все',
    'Into_collection' => 'Добавить фрагмент из буфера обмена в коллекцию',
    'Collection' => 'Коллекция',
    'Blanks_collection' => 'Коллекция заготовок',
    'db connection error' => 'Не удалось соединиться с базой данных, указанной в параметрах схемы',
    'Trunk' => 'Магистраль',
    'Scheme_blank' => 'Заготовка',
    'main_menu' => 'Главная',
    'help' => 'Помощь',
    'map' => 'Карта',
    'infrastructure' => 'Инфраструктура',
    'show_all_linked_schemes' => 'Показать все связанные схемы',
    'Scheme_id' => 'Id схеми',
    'scheme' => 'Схема',
    'scheme_data' => 'Параметры схемы',
    'store_in_db' => 'Хранить в вашей DB',
    'inner_data_in_db' => 'Брать уровни сигналов из DB',
    'inner_data_connection_params' => 'параметры соединения',
    'inner_data_db_fields' => 'id поле → tx, rx поля',
    'select_a_scheme' => 'Выбрать другую схему',
    'create_new_scheme' => 'Создать новую схему',
    'open_scheme' => 'Открыть схему по id',
    'your_schemes' => 'Ваши схемы',
    'Other_schemes' => 'Другие схемы',
    'shared_scheme' => 'Общая',
    'in_favorites' => 'В избранном',
    'Cable_types' => 'Типы кабелей',
    'Container_types' => 'Типы контейнеров',
    'Type' => 'Тип',
    'Layers' => 'Слои',
    'Stock' => 'Склад',
    'Track_length' => 'Длина трасс',
    'available_to_everyone' => 'Схема доступна всем, у кого есть ссылка',
    'available_to_everyone0' => 'Схема доступна всем',
    'want_a_personal_scheme' => 'Если ссылка кому-то известна и вам нужна персональная схема, экспортируйте, создайте новую, импортируйте',
    'this_is_fragment' => 'Эта схема является частью другой. Все, у кого есть доступ к родительской схеме, будут иметь доступ к этой',
    'The cable to be connected to must be on a other scheme' => 'Подключаемый кабель должен находиться на другой схеме',
    'Cannot remove a fiber from a linked cable' => 'Нельзя удалить волокно у кабеля, который связан с другой схемой. Сначала удалите связь',
    'Cannot add a fiber to a linked cable' => 'Нельзя добавить волокно кабелю, который связан с другой схемой. Сначала удалите связь',
    'Cannot remove a linked cable' => 'Нельзя удалить кабель, который связан с другой схемой. Сначала удалите связь',
    'First remove the link to the other scheme' => 'Сначала удалите ссылку на другую схему',
    'Target cable has a different number of fibers' => 'У подключаемого кабеля иное количество волокон',
    'Click on the map where you want to place the object' => 'Кликните по карте куда необходимо поместить объект',
    'Click on the map to set its center' => 'Кликните по карте чтобы установить ее центр',
    'Can only be imported into an empty project' => 'Можно импортировать только в пустой проект',
    'Cable length is not specified' => 'У кабеля не задана длинна',
    'Break distance is not specified' => 'Вы не задали расстояние до обрыва',
    'Cable ends must be in containers' => 'Концы кабеля должны быть в контейнерах',
    'The container cannot be removed from the infrastructure layer because it is set on the map' => 'Контейнер нельзя убрать с инфраструктурного слоя поскольку он установлен на карту',

    'синий' => 'синий',
    'оранжевый' => 'оранжевый',
    'зеленый' => 'зеленый',
    'коричневый' => 'коричневый',
    'серый' => 'серый',
    'белый' => 'белый',
    'красный' => 'красный',
    'черный' => 'черный',
    'желтый' => 'желтый',
    'фиолетовый' => 'фиолетовый',
    'розовый' => 'розовый',
    'бирюзовый' => 'бирюзовый',
    'голубой' => 'голубой',
    'аквамарин' => 'аквамарин',
    'синий+' => 'синий+',
    'оранжевый+' => 'оранжевый+',
    'зеленый+' => 'зеленый+',
    'коричневый+' => 'коричневый+',
    'серый+' => 'серый+',
    'белый+' => 'белый+',
    'красный+' => 'красный+',
    'черный+' => 'черный+',
    'желтый+' => 'желтый+',
    'фиолетовый+' => 'фиолетовый+',
    'розовый+' => 'розовый+',
    'бирюзовый+' => 'бирюзовый+',
    'голубой+' => 'голубой+',
    'аквамарин+' => 'аквамарин+',

    'panel' => 'Патчпанель',
    'switch' => 'Свич',
    'coupler' => 'Муфта',
    'splitter' => 'Сплиттер',
    'box' => 'Бокс',
    'cable' => 'Кабель',

    'of_panel' => 'патчпанели',
    'of_switch' => 'свича',
    'of_coupler' => 'муфты',
    'of_splitter' => 'сплиттера',
    'of_box' => 'бокса',
    'of_fbt' => 'сплиттера',
    'of_onu' => 'ONU',
    'of_empty' => 'контейнера',
    'of_fragment' => 'фрагмента',
    'of_container' => 'контейнера',
    'of_cable' => 'кабеля',
    'of_cable_joint' => 'изгиба кабеля',
    'of_cable_data' => 'данных кабеля',
    'of_link_joint' => 'изгиба соединения',

    'link_creation_mode' =>'Режим создания соединений',
    'to_center' => 'В центр', 
    'add' => 'Добавить',
    'add_patchpanel' => 'Кросс',
    'add_splice_closure' => 'Муфту',
    'add_splitter' => 'Сплиттер',
    'add_commutator' => 'Коммутатор',
    'add_cable' => 'Кабель',
    'set_on_map' => 'На карту',
    'remove_from_map' => 'Удалить с карты',
    'path' => 'Путь',
    'options' => 'Дополнительно',
    'image_export' => 'Экспорт в png',
    'scheme_export' => 'Экспорт схемы',
    'scheme_import' => 'Импорт схемы',
    'upload_scheme' => 'Загрузить схему',
    'Upload' => 'Загрузить',
    'number_of_connectors' => 'Количество коннекторов',
    'number_of_solders' => 'Количество паек',
    'number_of_ports' => 'Количество портов',
    'data' => 'Данные',
    'add_port' => 'Добавить порт',
    'add_connector' => 'Добавить коннектор',
    'add_solder' => 'Добавить пайку',
    #'add_splitter' => 'Добавить сплиттер',
    'align_inner_elements' => 'Выровнять содержимое',
    'change_avatar' => 'Изменить аватар',
    'change_size' => 'Изменить размер',
    'remove' => 'Удалить',
    'remove_container' => 'Удалить контейнер',
    'remove_from_container' => 'Вывести из контейнера',
    'link_with_scheme' => 'Связать со схемой',
    'goto_linked_scheme' => 'Перейти на связанную схему',
    'cable_ref' => 'Id кабеля',
    'cable_in_linked_scheme' => 'Id кабеля в связанной схеме',
    'align' => 'Выровнять',
    'grid_align' => 'Выровнять по сетке',
    'directions_align' => 'По направлениям',
    'name' => 'Имя',
    'description' => 'Описание',
    'place_id' => 'Точка топологии',
    'group' => 'Группа',
    'start_path_point' => 'Начальная точка пути',
    'end_path_point' => 'Конечная точка пути',
    'on_the_other_scheme' => 'на иной схеме',
    'select_the_fibers_color_sequence' => 'Выберите цветовую последовательность волокон',
    'create_own_fibers_color_sequence' => 'Создать свою последовательность',
    'remove_the_fibers_color_sequence' => 'Удалить цветовую последовательность',
    'create' => 'Создать',
    'preset_name' => 'Имя пресета',
    'number_of_fibers' => 'Количество волокон',
    'number_of_tubes' => 'Модулей (туб)',
    'move_cable' => 'Переместить кабель',
    'rotate' => 'Повернуть',
    'add_fiber' => 'Добавить волокно',
    'cable fiber adding' => 'Добавлено волокно в кабель',
    'cable fiber position shift' => 'Смещение позиции волокна кабеля',
    'remove_all_joints' => 'Удалить все изгибы',
    'remove_the_cable' => 'Удалить кабель',
    'remove_the_joint' => 'Удалить изгиб',
    'create_a_cable_joint' => 'Создать изгиб кабеля',
    'create_a_link_joint' => 'Создать изгиб',
    'cut_the_cable' => 'Разрезать кабель',
    'vertically' => 'Вертикально',
    'horizontally' => 'Горизонтально',
    'add_a_fiber' => 'Добавить волокно',
    'insert_a_splitter' => 'Вставить сплиттер',
    'length_with_m' => 'Длина, м',
    'select_the_fiber_color' => 'Выберите цвет волокна',
    'remove_the_fiber' => 'Удалить волокно',
    'order_changing' => 'Изменить порядок',
    'position_changing' => 'Сместить',
    'bookmark_name' => 'Имя закладки',
    'remove_the_photo' => 'Удалить фото',
    'show_the_photo' => 'Показать фото',
    'history' => 'История',
    'descriptions' => 'Описания',
    'fibers_colors' => 'Цвета волокон',
    'add_to_bookmarks' => 'Добавить в закладки',
    'refresh_page' => 'Обновите страницу',
    'coordinates_are_out_of_bounds' => 'Координаты вышли за пределы',
    'one_link_connects_a_fiber' => 'К волокну может идти только один линк',
    'soldering_connects_to_a_fiber_only' => 'Пайку нельзя соединить ни с чем кроме волокна',
    'position_changing_of' => 'Позиция []',
    'rotating_of' => 'Вращение []',
    'inner_element_position_changing' => 'Позиция внутреннего элемента []',
    'data_changing_of' => 'Данные []',
    'creating_of' => 'Создание []',
    'inner_element_data_changing_of' => 'Данные внутреннего элемента []',
    'size_changing_of' => 'Изменение размера []',
    'map_position_of' => 'Gps координаты []',
    'inner_element_adding' => 'Добавление внутреннего элемента ([])',
    'inner_elements_aligning' => 'Выравнивание внутренних элементов',
    'cable aligning' => 'Выравнивание кабеля',
    'cable_joint_adding' => 'Добавление изгиба кабеля',
    'cable removing' => 'Удаление кабеля',
    'link_removing' => 'Удаление соединения',
    'link_creating' => 'Создание соединения',
    'link_joint_adding' => 'Добавление изгиба соединения',
    'link_joint_removing' => 'Удаление изгиба соединения',
    'cable_creating' => 'Создание кабеля',
    'cable_cutting' => 'Разрезание кабеля',
    'cable joint removing' => 'Удаление изгиба кабеля',
    'panel removing' => 'Удаление патчпанели',
    'splitter removing' => 'Удаление сплиттера',
    'switch removing' => 'Удаление свича',
    'fbt removing' => 'Удаление сплиттера',
    'onu removing' => 'Удаление ONU',
    'bookmark creating' => 'Создание закладки',
    'length =' => 'Длина = [] м',
    'type_changing' => 'Изменение типа объекта',
    'container removing' => 'Удаление контейнера',
    'moving_into_container' => 'Перемещение в контейнер',
    'map_unit_remove' => 'Удаление с карты []',
    'into_map' => 'На карту',
    'map_center' => 'Центр на карте',
    'cannot_create_link' => 'Нельзя создать данное соединение',
    # 'only_for_map' => 'Только для карты',
    'multimoving' => 'Массовое перемещение',
    'meters' => 'метров',
    'Signal_level_colors' => 'Цвета уровня сигнала',
    'PON_tree' => 'PON дерево',
    'split' => 'разделить',
    'splice' => 'пайка',
    'not_connected' => 'не<br>соединять',
    'km' => 'км',
    'splitting_ratio' => '% разделения сигнала',
    'Total attenuation: []' => 'Общее затухание: []',
    'soldering' => 'пайка',
    'connector' => 'коннектор',
    'input' => 'вход',
    'output' => 'выход',
};

$ALL->{'Scheme does not exist'} = 'Схема не найдена';
$ALL->{Trunks} = $ajFibers->{Trunks} = 'Магистрали';


package lang::login;

1;