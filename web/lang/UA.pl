package lang;

sub UcFirst
{
    my($str) = @_;
    utf8::decode($str);
    $str = ucfirst $str;
    utf8::encode($str);
    return $str;
}

$yes = 'Так';
$no  = 'Нi';
$on  = 'Включений';
$off = 'Вимкнений';
$Now = 'Зараз';

$msg_after_submit 	= 'Чекайте ...';
$msg_Changes_saved	= 'Зміни збережені';

$error					= 'Помилка';
$err_no_priv			= 'Недостатньо прав.';
$err_try_again			= 'Виникла тимчасова помилка. Спробуйте повторити запит.';
$cannot_load_file		= 'Не можу завантажити файл []';
$cannot_save_file		= 'Не можу записати файл []';
$err_unauthorized		= 'Ви не авторизовані';

$Help				= 'Довідка';
$today				= 'сьогодні';
$today_at			= 'сьогодні в';
$Today_at			= UcFirst($today_at);
$hidden				= 'приховано';
$sec				= 'сек';

$lbl_data			= 'Дані';
$lbl_time			= 'Час';

$lbl_operations		= 'Операції';
$lbl_admin			= 'адмін';
$lbl_comment		= 'коментар';
$lbl_Comment		= UcFirst($lbl_comment);
$lbl_year			= 'рік';
$lbl_Year			= UcFirst($lbl_year);

# Кнопки
$btn_enter		= 'Вхід';
$btn_logout		= 'Вихід';
$btn_go_next	= 'Далі';
$btn_save		= 'Зберегти';
$btn_cancel		= 'Відмінити';
$btn_delete		= 'Видалити';
$btn_create		= 'створити';
$btn_Create		= UcFirst($btn_create);
$btn_Change		= 'Змiнити';
$btn_Execute	= 'Виконати';
$btn_add		= 'додати';
$btn_Add		= UcFirst($btn_add);

$adm_is_not_exist	= 'неіснуючий адмін id = [filtr]';

$chkbox_list_all	= 'Всі';
$chkbox_list_invert	= 'Інверсія';


$mLogin_login	= 'Логін';
$mLogin_pass	= 'Пароль';

$login = {
	'Вы можете авторизоваться одним из данных способов'
		=> 'Ви можете авторизуватися одним з даних методів',
};

$start_admin = {
	'Несуществующий админ в таблице сессий: id=[]' => 'Неіснуючий адмін в таблиці сесій: id=[]',
	'Доступ для логина [bold] заблокирован' => 'Доступ для логіна [bold] заблокований.',
	"Неизвестная команда '[]'"	  => "Невідома команда '[]'",
	"В cfg/web_plugins.list нет команды '[]'" => "В cfg/web_plugins.list немає команди '[]'",
	"Команда [] выполняется в ajax-контексте, но http-запрос не ajax - выводим титульную страницу" => "Команда [] виконується в ajax - контексті, але http-запит не ajax - виводимо титульну сторінку",
};

$settings = {
	'Ошибочная строка'				=> 'Помилковий рядок',
	'Изменен параметр'				=> 'Змінено параметр',
	'Файл не существует'			=> 'Файл не існує',
	'Параметр должен быть числом'	=> 'Параметр повинен бути числом',
	'Ошибка записи конфига в базу данных'
		=> 'Помилка запису конфіга в базу даних',
	'Конфигурационный файл записан успешно'
		=> 'Конфігураційний файл записано успішно',
	'Раздел: [bold]'				=> 'Роздiл: [bold]',
	'имя'							=> "ім`я",
	'пункт в меню'					=> 'пункт в меню',
	'описание'						=> 'опис',
	'Список доступных плагинов'		=> 'Список доступних плагінів',
	'Некоторые плагины вспомогательные и не отображаются в меню клиентской статистики'
		=> 'Деякі плагіни допоміжні і не відображаються в меню клієнтської статистики',
	'Подробнее о настройке меню'	=> 'Детальніше про налаштування меню',
	'Неизвестный код параметра []. имя: []'
		=> "Невідомий код параметра []. ім'я: []",
	'Сохранить'						=> 'Зберегти',
	'Ip пул'						=> 'Ip пул',
	'Сети'							=> 'Мережі',
	'Группы'						=> 'Групи',
	'Объекты'						=> "Об'єкти",
	'Дополнительные поля'			=> 'Додаткові поля',
	'Пользователи'					=> 'Користувачі',
	'Не могу прочитать каталог [filtr|bold|p]Если существует, проверьте права доступа'
		=> 'Не можу прочитати каталог [filtr|bold|p]Якщо існує, перевірте права доступу',
	'Замечание'						=> 'Зауваження',
	'Было'							=> 'Було',
	'Стало'							=> 'Стало',
};

$ajFibers = {
    'No' => 'Ні',
    'ReadOnly' => 'Тільки перегляд',
    'FullAccess' => 'Повний доступ',
    'Redo' => 'Повторити',
    'Undo' => 'Скасувати',
    'Paste' => 'Вставити',
    'Save' => 'Зберегти',
    'Show' => 'Показати',
    'Show_all' => 'Показати все',
    'Into_collection' => 'Додати фрагмент з буфера обміну до колекції',
    'Collection' => 'Колекція',
    'Blanks_collection' => 'Колекція заготовок',
    'db connection error' => 'Не вдалося з’єднатися з базою даних, зазначеної в параметрах схеми',
    'Trunk' => 'Магістраль',
    'Scheme_blank' => 'Заготовка',
    'main_menu' => 'Головна',
    'help' => 'Допомога',
    'map' => 'Карта',
    'infrastructure' => 'Інфраструктура',
    'show_all_linked_schemes' => 'показати всі пов’язані схеми',
    'Scheme_id' => 'Id схеми',
    'scheme' => 'Схема',
    'scheme_data' => 'Параметри схеми',
    'store_in_db' => 'Зберігати у вашій DB',
    'inner_data_in_db' => 'Брати рівні сигналів з DB',
    'inner_data_db_fields' => 'id поле → tx, rx поля',
    'select_a_scheme' => 'Обрати іншу схему',
    'create_new_scheme' => 'Створити нову схему',
    'open_scheme' => 'Відкрити схему по id',
    'your_schemes' => 'Ваші схеми',
    'Other_schemes' => 'Інші схеми',
    'shared_scheme' => 'Загальна',
    'in_favorites' => 'У обраному',
    'Cable_types' => 'Типи кабелів',
    'Container_types' => 'Типи контейнерів',
    'Type' => 'Тип',
    'Layers' => 'Шари',
    'Stock' => 'Склад',
    'Track_length' => 'Довжина трас',
    'available_to_everyone' => 'Схема доступна всім, у кого є посилання',
    'available_to_everyone0' => 'Схема доступна всім',
    'want_a_personal_scheme' => 'Якщо посилання комусь відомє і вам потрібна персональна схема, експортуйте, створіть нову, імпортуйте',
    'this_is_fragment' => 'Ця схема є частиною іншою. Всі, хто має доступ до батьківської схеми, матимуть доступ до цієї',
    'The cable to be connected to must be on a other scheme' => 'Кабель, що підключається, повинен знаходитися на іншой схемі',
    'Cannot remove a fiber from a linked cable' => 'Не можна видалити волокно у кабелю, який зв’язаний з іншою схемою. Спочатку видаліть зв’язок',
    'Cannot add a fiber to a linked cable' => 'Не можна додати волокно до кабелю, який зв’язаний з іншою схемою. Спочатку видаліть зв’язок',
    'Cannot remove a linked cable' => "Не можна видалити кабель, який зв'язаний з іншою схемою. Спочатку видаліть зв'язок",
    'First remove the link to the other scheme' => 'Спочатку видаліть посилання на іншу схему',
    'Target cable has a different number of fibers' => 'У кабелю, що підключається, інша кількість волокон',
    'Click on the map where you want to place the object' => 'Клікніть по карті куди необхідно помістити об’єкт',
    'Click on the map to set its center' => 'Клікніть по карті, щоб встановити її центр',
    'Can only be imported into an empty project' => 'Можна імпортувати лише у порожній проект',
    'Cable length is not specified' => 'У кабелю не задана довжина',
    'Break distance is not specified' => 'Ви не задали відстань до обрива',
    'Cable ends must be in containers' => 'Кінці кабелю мають бути у контейнерах',
    'The container cannot be removed from the infrastructure layer because it is set on the map' => 'Контейнер не можна прибрати з інфраструктурного шару, оскільки він встановлений на карту',

    'синий' => 'синій',
    'оранжевый' => 'помаранчевий',
    'зеленый' => 'зелений',
    'коричневый' => 'коричневий',
    'серый' => 'сірий',
    'белый' => 'білий',
    'красный' => 'червоний',
    'черный' => 'чорний',
    'желтый' => 'жовтий',
    'фиолетовый' => 'фіолетовий',
    'розовый' => 'рожевий',
    'бирюзовый' => 'бірюзовий',
    'голубой' => 'блакитний',
    'аквамарин' => 'аквамарин',
    'синий+' => 'синій+',
    'оранжевый+' => 'помаранчевий+',
    'зеленый+' => 'зелений+',
    'коричневый+' => 'коричневий+',
    'серый+' => 'сірий+',
    'белый+' => 'білий+',
    'красный+' => 'червоний+',
    'черный+' => 'чорний+',
    'желтый+' => 'жовтий+',
    'фиолетовый+' => 'фіолетовий+',
    'розовый+' => 'рожевий+',
    'бирюзовый+' => 'бірюзовий+',
    'голубой+' => 'блакитний+',
    'аквамарин+' => 'аквамарин+',

    'of_panel' => 'патчпанелі',
    'of_switch' => 'свіча',
    'of_coupler' => 'муфти',
    'of_splitter' => 'спліттера',
    'of_box' => 'бокса',
    'of_fbt' => 'спліттера',
    'of_onu' => 'ONU',
    'of_empty' => 'контейнера',
    'of_fragment' => 'фрагмента',
    'of_container' => 'контейнера',
    'of_cable' => 'кабеля',
    'of_cable_joint' => 'вигину кабеля',
    'of_cable_data' => 'даних кабелю',
    'of_link_joint' => "вигину з'єднання",

    'link_creation_mode' => "Режим створення з'єднань",
    'to_center' => 'В центр', 
    'add' => 'Додати',
    'add_patchpanel' => 'Крос',
    'add_junction_box' => 'Муфту',
    'add_splitter' => 'Спліттер',
    'add_commutator' => 'Комутатор',
    'add_cable' => 'Кабель',
    'set_on_map' => 'На карту',
    'remove_from_map' => 'Вилучити з карти',
    'path' => 'Шлях',
    'options' => 'Додатково',
    'image_export' => 'Експорт в png',
    'scheme_export' => 'Експорт схеми',
    'scheme_import' => 'Імпорт схеми',
    'upload_scheme' => 'Завантажити схему',
    'Upload' => 'Завантажити',
    'number_of_connectors' => 'Кількість конекторів',
    'number_of_solders' => 'Кількість пайок',
    'number_of_ports' => 'Кількість портів',
    'data' => 'Дані',
    'add_port' => 'Додати порт',
    'add_connector' => 'Додати конектор',
    'add_solder' => 'Додати пайку',
    #'add_splitter' => 'Додати спліттер',
    'align_inner_elements' => 'Вирівняти вміст',
    'change_avatar' => 'Змінити аватар',
    'change_size' => 'Змінити розмір',
    'remove' => 'Видалити',
    'remove_container' => 'Видалити контейнер',
    'remove_from_container' => 'Вивести з контейнера',
    'link_with_scheme' => "Зв'язати зі схемою",
    'goto_linked_scheme' => "Перейти на пов'язану схему",
    'cable_ref' => 'Id кабелю',
    'cable_in_linked_scheme' => "Id кабелю в пов'язаній схемі",
    'align' => 'Вирівняти',
    'grid_align' => 'Вирівняти по сітці',
    'directions_align' => 'За напрямками',
    'name' => "Ім'я",
    'description' => 'Опис',
    'place_id' => 'Точка топології',
    'group' => 'Група',
    'start_path_point' => 'Початкова точка шляху',
    'end_path_point' => 'Кінцева точка шляху',
    'on_the_other_scheme' => 'на іншій схемі',
    'select_the_fibers_color_sequence' => 'Виберіть колірну послідовність волокон',
    'create_own_fibers_color_sequence' => 'Створити свою послідовність',
    'remove_the_fibers_color_sequence' => 'Видалити колірну послідовність',
    'create' => 'Створити',
    'preset_name' => "Ім'я пресета",
    'number_of_fibers' => 'Кількість волокон',
    'number_of_tubes' => 'Модулей (туб)',
    'move_cable' => 'Перемістити кабель',
    'rotate' => 'Повернути',
    'add_fiber' => 'Додати волокно',
    'cable fiber adding' => 'Додано волокно у кабель',
    'cable fiber position shift' => 'Зміщення позиції волокна кабелю',
    'remove_all_joints' => 'Видалити всі вигини',
    'remove_the_cable' => 'Видалити кабель',
    'remove_the_joint' => 'Видалити вигин',
    'create_a_cable_joint' => 'Створити вигин кабелю',
    'create_a_link_joint' => 'Створити вигин',
    'cut_the_cable' => 'Розрізати кабель',
    'vertically' => 'Вертикально',
    'horizontally' => 'Горизонтально',
    'add_a_fiber' => 'Додати волокно',
    'length_with_m' => 'Довжина, м',
    'select_the_fiber_color' => 'Виберіть колір волокна',
    'remove_the_fiber' => 'Видалити волокно',
    'order_changing' => 'Змінити порядок',
    'position_changing' => 'Змістити',
    'bookmark_name' => "Ім'я закладки",
    'remove_the_photo' => 'Видалити фото',
    'show_the_photo' => 'Показати фото',
    'history' => 'История',
    'descriptions' => 'Описи',
    'fibers_colors' => 'Кольори волокон',
    'add_to_bookmarks' => 'Додати в закладки',
    'refresh_page' => 'Оновіть сторінку',
    'coordinates_are_out_of_bounds' => 'Координати вийшли за межі',
    'one_link_connects_a_fiber' => 'До волокна може йти тільки один лінк',
    'soldering_connects_to_a_fiber_only' => 'Пайку не можна з’єднати ні з чим крім волокна',
    'position_changing_of' => 'Позиція []',
    'rotating_of' => 'Обертання []',
    'inner_element_position_changing' => 'Позиція внутрішнього елемента []',
    'data_changing_of' => 'Дані []',
    'creating_of' => 'Створення []',
    'inner_element_data_changing_of' => 'Дані внутрішнього елемента []',
    'size_changing_of' => 'Зміна розміру []',
    'map_position_of' => 'Gps координати []',
    'inner_element_adding' => 'Додавання внутрішнього елемента ([])',
    'inner_elements_aligning' => 'Вирівнювання внутрішніх елементів',
    'cable aligning' => 'Вирівнювання кабелю',
    'cable_joint_adding' => 'Додавання вигину кабелю',
    'cable removing' => 'Вилучення кабелю',
    'link_removing' => "Вилучення з'єднання",
    'link_creating' => "Створення з'єднання",
    'link_joint_adding' => "Додавання вигину з'єднання",
    'link_joint_removing' => "Вилучення вигину з'єднання",
    'cable_creating' => 'Створення кабелю',
    'cable_cutting' => 'Розрізання кабелю',
    'cable joint removing' => 'Видалення вигину кабеля',
    'panel removing' => 'Видалення патчпанелі',
    'splitter removing' => 'Видалення спліттера',
    'switch removing' => 'Видалення свіча',
    'fbt removing' => 'Видалення спліттера',
    'onu removing' => 'Видалення ONU',
    'bookmark creating' => 'Створення закладки',
    'length =' => 'Довжина = [] м',
    'type_changing' => "Зміна типу об'єкта",
    'container removing' => 'Видалення контейнера',
    'moving_into_container' => 'Переміщення в контейнер',
    'map_unit_remove' => 'Видалення з карти []',
    'into_map' => 'На карту',
    'map_center' => 'Центр на карті',
    'cannot_create_link' => 'Не можна створити даний лінк',
    # 'only_for_map' => 'Тільки для карти',
    'multimoving' => 'Масове переміщення',
    'meters' => 'метрів',
};

$o_fibers_trunks = {
    'Имя магистрали на украинском' => 'Ім’я магістралі українською',
    'Имя магистрали на русском' => 'Ім’я магістралі російською',
    'Новая магистраль' => 'Нова магістраль',
    'Все магистрали' => 'Всі магістралі',
    'Название' => 'Назва',
    'Комментарий' => 'Коментар',
};

$o_fibers_container_types = {
    'типа контейнера' => 'типу контейнера',
    'Новый тип' => 'Новий тип',
    'Все типы контейнеров' => 'Все типы контейнеров',
    'типа контейнера [filtr|commas]' => 'типу контейнера [filtr|commas]',
    'Форма' => 'Форма',
    'Размер' => 'Розмір',
    'Скрывать' => 'Приховувати',
    'Скрывать при уменьшении масштаба географической карты' => 'Приховувати при зменшенні масштабу географічної карти',
};

$o_fibers_cable_types = {
    'типа кабеля' => 'типу кабелю',
    'Новый тип' => 'Новий тип',
    'Все типы кабелей' => 'Всі типи кабелів',
    'типа кабеля [filtr|commas]' => 'типу кабелю [filtr|commas]',
    'Тип' => 'Тип',
    'Тип кабеля' => 'Тип кабелю',
    'Цвет на карте' => 'Колір на карті',
    'Толщина линии на карте' => 'Товщина лінії на карті',
};

$ALL->{'Scheme does not exist'} = 'Схема не знайдена';
$ALL->{Trunks} = $ajFibers->{Trunks} = 'Магістралі';

package lang::login;

$standard = {
	'Неверный логин или пароль'      => 'Невірний логін або пароль',
	'Включите javascript в браузере' => 'Увімкніть javascript в браузері',
	'Авторизация по логину и паролю' => 'Авторизація за логіном та паролем',
};


1;
