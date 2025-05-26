package lang;

sub UcFirst
{
    my($str) = @_;
    utf8::decode($str);
    $str = ucfirst $str;
    utf8::encode($str);
    return $str;
}

$yes = 'Yes';
$no = 'No';
$on = 'On';
$off = 'Off';
$Now = 'Now';

$msg_after_submit = 'Wait ...';
$msg_Changes_saved = 'Changes saved';

$error = 'Error';
$err_no_priv = 'Not enough privileges.';
$err_try_again = 'A temporary error occurred. Please try again.';
$cannot_load_file = 'Cannot upload file []';
$cannot_save_file = 'Cannot save file []';
$err_unauthorized = 'You are not authorized';

$Help = 'Help';
$today = 'today';
$today_at = 'today at';
$Today_at = UcFirst($today_at);
$hidden = 'hidden';
$sec = 'sec';

$lbl_data = 'Data';
$lbl_time = 'Time';

$lbl_operations = 'operations';
$lbl_admin = 'admin';
$lbl_comment = 'comment'; 
$lbl_Comment = UcFirst($lbl_comment);
$lbl_year = 'year';
$lbl_Year = UcFirst($lbl_year);

# Buttons 
$btn_enter = '&nbsp;&nbsp;Login&nbsp;&nbsp;';
$btn_logout = 'Logout';
$btn_go_next = 'Next';
$btn_save = 'Save';
$btn_cancel = 'Cancel';
$btn_delete = 'Delete';
$btn_create = 'create';
$btn_Create = UcFirst($btn_create);
$btn_Change = 'Change';
$btn_Execute = 'Execute';
$btn_add = 'add';

$adm_is_not_exist   = 'non-existent admin id = [filtr]';

$chkbox_list_all    = 'All';
$chkbox_list_invert = 'Invert';

$mLogin_login       = 'Login';
$mLogin_pass        = 'Password';


$login = {
    'Вы можете авторизоваться одним из данных способов'
      => 'You can log in using one of these methods',
};

$start_admin = {
    'Несуществующий админ в таблице сессий: id=[]' => 'Non-existent admin in session table: id=[]',
    'Доступ для логина [bold] заблокирован' => 'Access for login [bold] is blocked',
    "Неизвестная команда '[]'" => "Unknown command '[]'",
    "В cfg/web_plugins.list нет команды '[]'" => "There is no command '[]' in cfg/web_plugins.list",
    "Команда [] выполняется в ajax-контексте, но http-запрос не ajax - выводим титульную страницу"
      => 'The [] command is executed in an ajax context, but the http request is not ajax, so we return the front page', 
};


$settings = {
    'Ошибочная строка'              => 'Error line',
    'Изменен параметр'              => 'Changed parameter',
    'Файл не существует'            => 'File does not exist',
    'Параметр должен быть числом'   => 'Parameter must be a number',
    'Ошибка записи конфига в базу данных'
                                    => 'Error writing the config to the database',
    'Конфигурационный файл записан успешно'
                                    => 'The configuration was written successfully',
    'Раздел: [bold]'                => 'Section: [bold]',
    'имя'                           => 'name',
    'пункт в меню'                  => 'menu item',
    'описание'                      => 'description',
    'Список доступных плагинов'     => 'Available plugins list',
    'Некоторые плагины вспомогательные и не отображаются в меню клиентской статистики'
                                    => 'Some plugins are auxiliary and are not displayed in the user page menu',
    'Подробнее о настройке меню'    => 'More about menu settings',
    'Неизвестный код параметра []. имя: []'
                                    => 'Unknown parameter code []. name: []',
    'Сохранить'                     => 'Save',
    'Ip пул'                        => 'Ip pool',
    'Сети'                          => 'Networks',
    'Группы'                        => 'Groups',
    'Объекты'                       => 'Objects',
    'Дополнительные поля'           => 'Additional fields',
    'Пользователи'                  => 'Users',
    'Не могу прочитать каталог [filtr|bold|p]Если существует, проверьте права доступа'
                                    => "Can't read directory [filtr|bold|p]If it exists, check permissions",
    'Замечание'                     => 'Remark',
    'Было'                          => 'Was',
    'Стало'                         => 'Became',
};

$ajFibers = {
    'No' => 'No',
    'ReadOnly' => 'Read only',
    'FullAccess' => 'Full access',
    'Redo' => 'Redo',
    'Undo' => 'Undo',
    'Copy' => 'Copy',
    'Paste' => 'Paste',
    'Save' => 'Save',
    'Show' => 'Show',
    'Show_all' => 'Show all',
    'Into_collection' => 'Into collection',
    'Collection' => 'Collection',
    'Blanks_collection' => 'Blanks collection',
    'db connection error' => "Db connection error. Check the scheme's params",
    'Trunk' => 'Trunk',
    'Scheme_blank' => 'Scheme blank',
    'main_menu' => 'Main',
    'help' => 'Help',
    'map' => 'Map',
    'infrastructure' => 'Infrastructure',
    'show_all_linked_schemes' => 'Show all linked schemes',
    'Scheme_id' => 'Scheme id',
    'scheme' => 'Scheme',
    'scheme_data' => 'Scheme data',
    'store_in_db' => 'Store in your DB',
    'inner_data_in_db' => 'Get signal levels from DB',
    'inner_data_connection_params' => 'connection parameters',
    'inner_data_db_fields' => 'id fields → tx, rx fields',
    'select_a_scheme' => 'Select another scheme',
    'create_new_scheme' => 'Create new scheme',
    'open_scheme' => 'Open scheme by id',
    'your_schemes' => 'Your schemes',
    'Other_schemes' => 'Other schemes',
    'shared_scheme' => 'Shared',
    'in_favorites' => 'In favorites',
    'Cable_types' => 'Cable types',
    'Container_types' => 'Container types',
    'Type' => 'Type',
    'Layers' => 'Layers',
    'Stock' => 'Stock',
    'Track_length' => 'Track length',
    'available_to_everyone' => 'The scheme is available to everyone who has a link',
    'available_to_everyone0' => 'The scheme is available to everyone',
    'want_a_personal_scheme' => 'if you want a personal scheme, export this one, create a new one and import from a file',
    'this_is_fragment' => 'This scheme is part of another scheme. Everyone who has access to the parent scheme has access to this one',
    'The cable to be connected to must be on a other scheme' => 'The cable to be connected to must be on a other scheme',
    'Cannot remove a fiber from a linked cable' => 'You cannot remove a fiber from a cable that is linked to another scheme. Remove the link first',
    'Cannot add a fiber to a linked cable' => 'You cannot add a fiber to a cable that is linked to another scheme. Remove the link first',
    'Cannot remove a linked cable' => 'You cannot remove cable that is linked to another scheme. Remove the link first',
    'First remove the link to the other scheme' => 'First remove the link to the other scheme',
    'Target cable has a different number of fibers' => 'Target cable has a different number of fibers',
    'Click on the map where you want to place the object' => 'Click on the map where you want to place the object',
    'Click on the map to set its center' => 'Click on the map to set its center',
    'Can only be imported into an empty project' => 'Can only be imported into an empty project',
    'Cable length is not specified' => 'Cable length is not specified',
    'Break distance is not specified' => 'Break distance is not specified',
    'Cable ends must be in containers' => 'Cable ends must be in containers',
    'The container cannot be removed from the infrastructure layer because it is set on the map' => 'The container cannot be removed from the infrastructure layer because it is set on the map',

    'синий' => 'blue',
    'оранжевый' => 'orange',
    'зеленый' => 'green',
    'коричневый' => 'brown',
    'серый' => 'slate',
    'белый' => 'white',
    'красный' => 'red',
    'черный' => 'black',
    'желтый' => 'yellow',
    'фиолетовый' => 'violet',
    'розовый' => 'rose',
    'бирюзовый' => 'turquoise',
    'голубой' => 'light blue',
    'аквамарин' => 'aqua',
    'синий+' => 'blue+',
    'оранжевый+' => 'orange+',
    'зеленый+' => 'green+',
    'коричневый+' => 'brown+',
    'серый+' => 'slate+',
    'белый+' => 'white+',
    'красный+' => 'red+',
    'черный+' => 'black+',
    'желтый+' => 'yellow+',
    'фиолетовый+' => 'violet+',
    'розовый+' => 'rose+',
    'бирюзовый+' => 'turquoise+',
    'голубой+' => 'light blue+',
    'аквамарин+' => 'aqua+',

    'panel' => 'Patchpanel',
    'switch' => 'Switch',
    'coupler' => 'Splice closure',
    'splitter' => 'Splitter',
    'box' => 'Box',
    'cable' => 'Cable',

    'of_panel' => 'patchpanel',
    'of_switch' => 'switch',
    'of_coupler' => 'splice closure',
    'of_splitter' => 'splitter',
    'of_box' => 'box',
    'of_fbt' => 'splitter',
    'of_onu' => 'onu',
    'of_empty' => 'container',
    'of_fragment' => 'fragment',
    'of_container' => 'container',
    'of_cable' => 'cable',
    'of_cable_joint' => 'cable joint',
    'of_cable_data' => 'cable data',
    'of_link_joint' => 'link joint',

    'link_creation_mode' =>'Link creation mode',
    'to_center' => 'To the center',
    'add' => 'Add',
    'add_patchpanel' => 'Patchpanel',
    'add_splice_closure' => 'Splice closure',
    'add_splitter' => 'Splitter',
    'add_commutator' => 'Commutator',
    'add_cable' => 'Cable',
    'set_on_map' => 'Put it on a map',
    'remove_from_map' => 'Remove it from the map',
    'path' => 'Path',
    'options' => 'Options',
    'image_export' => 'Image export',
    'scheme_export' => 'Scheme export',
    'scheme_import' => 'Scheme import',
    'upload_scheme' => 'Upload scheme',
    'Upload' => 'Upload',
    'number_of_connectors' => 'Number of connectors',
    'number_of_solders' => 'Number of solders',
    'number_of_ports' => 'Number of ports',
    'data' => 'Data',
    'add_port' => 'Add a port',
    'add_connector' => 'Add a connector',
    'add_solder' => 'Add a solder',
    #'add_splitter' => 'Add a splitter',
    'align_inner_elements' => 'Align inner elements',
    'change_avatar' => 'Change avatar',
    'change_size' => 'Change size',
    'remove' => 'Remove',
    'remove_container' => 'Remove container',
    'remove_from_container' => 'Remove from container',
    'link_with_scheme' => 'Link with scheme',
    'goto_linked_scheme' => 'Go to linked scheme',
    'cable_ref' => 'Cable id',
    'cable_in_linked_scheme' => 'Cable id in linked scheme',
    'align' => 'Align',
    'grid_align' => 'Grid align',
    'directions_align' => 'Directions align',
    'name' => 'Name',
    'description' => 'Description',
    'place_id' => 'Place id',
    'group' => 'Group',
    'start_path_point' => 'Start path point',
    'end_path_point' => 'End path point',
    'on_the_other_scheme' => 'on the other scheme',
    'select_the_fibers_color_sequence' => 'Select the fibers color sequence',
    'create_own_fibers_color_sequence' => 'Create own sequence',
    'remove_the_fibers_color_sequence' => 'Remove the color sequence',
    'create' => 'Create',
    'preset_name' => 'Preset name',
    'number_of_fibers' => 'Number of fibers',
    'number_of_tubes' => 'Number of tubes',
    'move_cable' => 'Cable moving',
    'rotate' => 'Rotate',
    'add_fiber' => 'Add a fiber',
    'cable fiber adding' => 'Cable fiber adding',
    'cable fiber position shift' => 'cable fiber position shift',
    'remove_all_joints' => 'Remove all joints',
    'remove_the_cable' => 'Remove the cable',
    'remove_the_joint' => 'Remove the joint',
    'create_a_cable_joint' => 'Create a joint',
    'create_a_link_joint' => 'Create a joint',
    'cut_the_cable' => 'Cut the cable',
    'vertically' => 'Vertically',
    'horizontally' => 'Horizontally',
    'add_a_fiber' => 'Add a fiber',
    'insert_a_splitter' => 'Insert a splitter',
    'length_with_m' => 'Length, m',
    'select_the_fiber_color' => 'Select the fiber color',
    'remove_the_fiber' => 'Remove the fiber',
    'order_changing' => 'Order changing',
    'position_changing' => 'Position changing',
    'bookmark_name' => 'Bookmark name',
    'remove_the_photo' => 'Remove the photo',
    'show_the_photo' => 'Show the photo',
    'history' => 'History',
    'descriptions' => 'Descriptions',
    'fibers_colors' => 'Fibers colors',
    'add_to_bookmarks' => 'Add to bookmarks',
    'refresh_page' => 'Refresh the page',
    'coordinates_are_out_of_bounds' => 'Coordinates are out of bounds',
    'one_link_connects_a_fiber' => 'Only one link can connect to a fiber',
    'soldering_connects_to_a_fiber_only' => 'Soldering connects to a fiber only',
    'position_changing_of' => '[] position changing',
    'rotating_of' => '[] rotating',
    'inner_element_position_changing' => '[] inner element position changing',
    'data_changing_of' => '[] data changing',
    'creating_of' => '[] creating',
    'inner_element_data_changing_of' => '[] inner element data changing',
    'size_changing_of' => '[] size changing',
    'map_position_of' => '[] gps position',
    'inner_element_adding' => 'Inner element adding ([])',
    'inner_elements_aligning' => 'Inner elements aligning',
    'cable aligning' => 'Cable aligning',
    'cable_joint_adding' => 'Cable joint adding',
    'cable removing' => 'Cable removing',
    'link_removing' => 'Link removing',
    'link_creating' => 'Link creating',
    'link_joint_adding' => 'Link joint adding',
    'link_joint_removing' => 'Link joint removing',
    'cable_creating' => 'Cable creating',
    'cable_cutting' => 'Cable cutting',
    'cable joint removing' => 'Cable joint removing',
    'length =' => 'Length = [] m',
    'type_changing' => 'Type changing',
    'container removing' => 'container removing',
    'moving_into_container' => 'Moving into container',
    'map_unit_remove' => 'removing [] from a map',
    'into_map' => 'Into a map',
    'map_center' => 'Map center',
    'cannot_create_link' => 'The link cannot be created',
    # 'only_for_map' => 'Only for a map',
    'multimoving' => 'Multimoving',
    'meters' => 'meters',
    'Signal_level_colors' => 'Signal level colors',
    'PON_tree' => 'PON tree',
    'split' => 'split',
    'splice' => 'splice',
    'not_connected' => 'not<br>connected',
    'km' => 'km',
    'splitting_ratio' => 'Splitting ratio, %',
    'Total attenuation: []' => 'Total attenuation: []',
    'soldering' => 'soldering',
    'connector' => 'connector',
    'input' => 'input',
    'output' => 'output',
};

$ALL->{Trunks} = $ajFibers->{Trunks} = 'Trunks';

$o_fibers_trunks = {
    'Имя магистрали на украинском' => 'Trunk name in Ukrainian',
    'Имя магистрали на русском' => 'Trunk name in Russian',
    'Новая магистраль' => 'New trunk',
    'Все магистрали' => 'All trunks',
    'Название' => 'Name',
    'Комментарий' => 'Comment',
};

$o_fibers_container_types = {
    'типа контейнера' => 'of container type',
    'Новый тип' => 'New type',
    'Все типы контейнеров' => 'All container types',
    'типа контейнера [filtr|commas]' => 'of container type [filtr|commas]',
    'Форма' => 'Form',
    'Размер' => 'Size',
    'Скрывать' => 'Hide',
    'Скрывать при уменьшении масштаба географической карты' => 'Hide when map is zooming out',
};

$o_fibers_cable_types = {
    'типа кабеля' => 'of cable type',
    'Новый тип' => 'New type',
    'Все типы кабелей' => 'All cable types',
    'типа кабеля [filtr|commas]' => 'of cable type [filtr|commas]',
    'Тип' => 'Type',
    'Тип кабеля' => 'Cable type',
    'Цвет на карте' => 'Color',
    'Толщина линии на карте' => 'Line width',
};

package lang::login;

$standard = {
    'Неверный логин или пароль'      => 'Invalid login or password',
    'Включите javascript в браузере' => 'Enable javascript in your browser',
    'Авторизация по логину и паролю' => 'Authorization by login and password',
};

1;