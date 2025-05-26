# ------------------- NoDeny ------------------
#  (с) Volyk Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
use strict;
use Debug;
use JSON;

my $fibers__xy_bounds = {
	'x' => 25000,
	'y' => 25000,
};

my $fibers__inner_xy_bounds = {
	'x' => 800,
	'y' => 2500,
};

my $err_only_in_pro_version = 'This feature is only available in pro version. Contact: max.begemot@gmail.com';

my $CABLE_CREATE_WIDTH = 200;
my $PON_CABLE_CREATE_WIDTH = 100;
my $PON_LINK_CREATE_WIDTH = 60;
my $inner_units_distance = 30;
my $fiber_tips_distance = 30;
my $import_scheme__max_units = 4000;
my $import_scheme__max_links = 10000;

my $MAX_FRAME_TAGS = 15;
my $MIN_SIGNAL_LEVEL = -35;
my $MAX_SIGNAL_LEVEL = -10;

my $Uid = 0;

my $Scheme_data = {};
my $User = {
	is_owner => 0,
	role => '',
	ro => 0,
};

@cfg::fibers_stock_grp_ids_list = ();
%cfg::fibers_stock_grp_ids_hash = ();
$cfg::fibers_stock_enabled = 0;

sub go
{
	my($Url) = @_;

	$Fibers::MainDb = Db->self();

	if( $cfg::fibers_common_for_all )
	{
		$lang::ajFibers->{available_to_everyone} = $lang::ajFibers->{available_to_everyone0};
		$lang::ajFibers->{want_a_personal_scheme} = '';
	}

	my $role = $ses::auth->{role};
	$User->{role} = $role;

	$role eq 'admin' or Error('Access denied (wrong role)');
    $User->{superadmin} = 1 if Adm->chk_privil('SuperAdmin');
	$Uid = int $ses::auth->{adm}{uid};

	my $scheme_id = 0;
	if( my $gid = ses::input('force_gid') || ses::input('gid') )
	{
		my %p = Db->line('SELECT * FROM fibers_schemes WHERE gid=?', $gid);
		Db->ok or ApiError(L('DB error'));
		%p or ApiError('Wrong scheme id');

		$Scheme_data = \%p;
		$scheme_id = $p{id};
		my $uid = $p{uid};

		my $is_owner = $User->{is_owner} = int(!$uid || $uid == $Uid);

		if( !$is_owner && !$User->{superadmin} )
		{
			$p{shared} or ApiError(L('Access denied'));
			$User->{ro} = 1 if $p{shared} < 2;
		}
		$User->{full_access} = 1 if $User->{superadmin} || ($is_owner && $uid);

		if( $p{external_db} ne '' )
		{
			my($db_server, $db_name, $db_user, $db_pw) = split / *: */, $p{external_db};
			Db->new(
				host	=> $db_server,
				user	=> $db_user,
				pass	=> $db_pw,
				db		=> $db_name,
				timeout	=> 5,
				tries	=> 1,
				global	=> 1,
			);
			Db->connect;
			Db->is_connected or ApiError(L('db connection error'));
		}
	}

=head
	$User->{ro} = sharing mode, not current RO editing state

	$Uid != 0;  # = id in users table (!)
	$User->{role} = 'admin';
	$User->{is_owner} = 1 for his scheme (when fibers_schemes.uid = $Uid)
	$ses::auth->{role} = 'admin';

	--- Superadmin ---
	has full access but $User->{is_owner} is set (not always 1!)
	$User->{ro} = 0

=cut

    $Fibers::Scheme_id = $scheme_id;

	my %acts = (
		get_all					=> \&main_get_all,
		get_all_end_center_unit	=> \&get_all_end_center_unit,
		map_get_all				=> \&map_get_all,
		export					=> \&export_scheme,
		copy					=> \&copy,
		import					=> \&import_scheme,
		paste					=> \&import_all,
		into_collection			=> \&import_all,
		search					=> \&search,

		show_collection			=> \&show_collection,
		multimove				=> \&multimove,

		frame_create			=> \&frame_create,
		frame_remove			=> \&frame_remove,
		frame_add_inner			=> \&frame_add_inner,
		frame_data				=> \&frame_data,
		frame_data_save			=> \&frame_data_save,
		frame_change_type		=> \&frame_change_type,
		frame_position			=> \&frame_position,
		frame_size				=> \&frame_size,
		frame_inner_position	=> \&frame_inner_position,
		# frame_upload_img		=> \&frame_upload_img,
		frame_remove_img		=> \&frame_remove_img,
		frame_show_img			=> \&frame_show_img,
		frame_inner_remove		=> \&frame_inner_remove,
		frame_inner_data		=> \&frame_inner_data,
		frame_inner_data_save	=> \&frame_inner_data_save,
		frame_inner_align		=> \&frame_inner_align,
		frame_inner_align_grid	=> \&frame_inner_align_grid,
		frame_inner_align_connected => \&frame_inner_align_connected,
		frame_inner_align_lr	=> \&frame_inner_align_lr,
		frame_rotate			=> \&frame_rotate,

		cable_create			=> \&cable_create,
		cable_data				=> \&cable_data,
		cable_data_save			=> \&cable_data_save,
		cable_move				=> \&cable_move,
		cable_cut				=> \&cable_cut,
		cable_joint_add			=> \&cable_joint_add,
		cable_joint_position	=> \&cable_joint_position,
		cable_end_joint_slide	=> \&cable_end_joint_slide,
		cable_joint_align		=> \&cable_joint_align,
		cable_joint_remove		=> \&cable_joint_remove,
		cable_joint_data		=> \&cable_joint_data,
		cable_joint_data_save	=> \&cable_joint_data_save,
		cable_rotate_edge		=> \&cable_rotate_edge,
		cable_remove			=> \&cable_remove,
		cable_remove_all_joints	=> \&cable_remove_all_joints,
		cable_change_color		=> \&cable_change_color,
		cable_fibers_order		=> \&cable_fibers_move,
		cable_fibers_move		=> \&cable_fibers_move,
		cable_fiber_add			=> \&cable_fiber_add,
		cable_fiber_remove		=> \&cable_fiber_remove,
		cable_insert_splitter	=> \&cable_insert_splitter,
		cable_insert_splitter_now	=> \&cable_insert_splitter_now,
		cable_find_break		=> \&cable_find_break,
		link_with_scheme		=> \&cable_link_with_scheme,
		link_with_scheme_save	=> \&cable_link_with_scheme_save,
		goto_linked_scheme		=> \&cable_goto_linked_scheme,

		move_into_container		=> \&move_into_container,
		remove_from_container	=> \&remove_from_container,

		link_create				=> \&link_create,
		link_remove				=> \&link_remove,
		link_joint_add			=> \&link_joint_add,
		link_joint_remove		=> \&link_joint_remove,
		link_joint_position		=> \&link_joint_position,

		nomap					=> \&nomap,
		bookmark_create			=> \&bookmark_create,
		bookmark_remove			=> \&bookmark_remove,
		step_back				=> \&undo_redo,
		step_forward			=> \&undo_redo,
		history					=> \&history,
		path					=> \&path,
		pon_path				=> \&pon_path,
		create_color_preset		=> \&create_color_preset,
		delete_color_preset		=> \&delete_color_preset,

		map_position			=> \&map_position,
		map_unit_position		=> \&map_unit_position,
		map_unit_remove			=> \&map_unit_remove,

		scheme_data				=> \&scheme_data,
		scheme_data_save		=> \&scheme_data_save,
		scheme_remove			=> \&scheme_remove,
		check_history			=> \&check_history,
#<HOOK>acts
	);

	if( !$scheme_id )
	{
		%acts = ( get_all => \&get_all ); # !!!
	}
	 elsif( $User->{ro} )
    {
		debug 'read-only views only';
		%acts = (
			get_all					=> \&main_get_all,
			get_all_end_center_unit	=> \&get_all_end_center_unit,
			map_get_all				=> \&map_get_all,
			export					=> \&export_scheme,
			copy					=> \&copy,
			search					=> \&search,

			show_collection			=> \&show_collection,

			frame_data				=> \&frame_data,
			frame_show_img			=> \&frame_show_img,
			frame_inner_data		=> \&frame_inner_data,

			cable_data				=> \&cable_data,
			link_with_scheme		=> \&cable_link_with_scheme,
			goto_linked_scheme		=> \&cable_goto_linked_scheme,
			cable_find_break		=> \&cable_find_break,
			cable_joint_data		=> \&cable_joint_data,

			nomap					=> \&nomap,
			path					=> \&path,
			pon_path				=> \&pon_path,

			scheme_data				=> \&scheme_data,
		);
	}

	my $act = ses::input('act');
	exists $acts{$act} or return;
	my $id = ses::input_int('id');
	$ses::cmd = &{$acts{$act}}( $scheme_id, $id, $act );
}


sub _reload_page
{
	ApiError(L('refresh_page'));
	die;
}

sub _db_error
{
	ApiError(L('DB error'));
	die;
}

sub _data_error
{
	debug 'pre', 'error', 'data error', @_;
	ApiError(L('Data error'));
	die;
}

sub _corrupted_data
{
	debug 'error', 'data is corrupted';
	ApiError(L('Data is corrupted'));
	die;
}


# --- Utils ---

sub check_xy
{
	my($x, $y, $bounds, $ret_undef_if_err) = @_;
	$bounds ||= $fibers__xy_bounds;
	my $error = $x < -$bounds->{x} || $x > $bounds->{x} || $y < -$bounds->{y} || $y > $bounds->{y};
	$error or return( int($x + ($x <=> 0)*0.5), int($y + ($y <=> 0)*0.5) );
	defined $ret_undef_if_err ? return (undef, undef) : ApiError(L('coordinates_are_out_of_bounds'));
}

sub inner_count
{
	my($u, $inner_type) = @_;
	$inner_type or return scalar keys %{$u->{inner_units}};
	my $count = 0;
	foreach my $iu( values %{$u->{inner_units}} )
	{
		$count++ if $iu->{type} eq $inner_type;
	}
	return $count;
}

# ---

sub search
{
	my($scheme_id) = @_;
	my $search = v::trim(ses::input('search'));
	$search =~ s|\\|\\\\|g;
	$search =~ s|(['"%])|\\$1|g;
	$search =~ s|[\r\n\0]||g;
	my $db = Db->sql(
		"SELECT id, name, type FROM fibers_units WHERE removed=0 AND scheme_id=? ".
		"AND (name LIKE '$search%' OR inner_units LIKE '%\"remote_id\":\"$search\"%') ".
		"ORDER by name LIMIT 10", $scheme_id,
	);
	my $units = [];
	while( my %p = $db->line )
	{
		push @$units, {
			id   => $p{id},
			name => ($p{name} || $p{id}).($p{name} !~ /^$search/i ? ' (connector remote id)' : ''),
			type => $p{type},
		};
	}
	return scalar @$units ? $units : undef;
}

sub _get_all_linked_schemes
{
	my($scheme_id, $main_scheme, $params) = @_;
	$params ||= {};

	debug 'All accessible schemes for gid->id converter';
	my $db = Db->sql("SELECT id, gid, settings FROM fibers_schemes WHERE shared>0 or uid=?", $Uid);
	Db->ok or ApiError(L('DB error'));
	my $scheme_settings = {};
	my $gid_to_scheme_id = {};
	my $scheme_gid;
	while( my %p = $db->line )
	{
		my($gid, $id) = ($p{gid}, $p{id});
		$gid_to_scheme_id->{$gid} = $id;
		$scheme_settings->{$id} = from_json($p{settings} || '{}');
		$scheme_gid = $gid if $scheme_id == $id;
	}
	$scheme_gid or ApiError("Internal error: scheme's gid not found");

	my $places_by_cable_id = {};
	my $schemes_linked_cables = { $scheme_id => [] };
	my $schemes = { $scheme_id => $main_scheme };
	my @unit_series = ([$scheme_gid, $main_scheme->{units}]);
	while( @unit_series )
	{
		my($gid, $units) = @{pop @unit_series};
		debug "get linked schemes for scheme $gid";
		my @debug_gids = ();
		$schemes_linked_cables->{$gid} = [];
		foreach my $u( grep{ $_->{cls} eq 'cable' && exists $_->{add_data}{linked_scheme} } @$units )
		{
			$u->{add_data}{linked_scheme} =~ /^([^:]+):(\d+)$/ or next;
			my($linked_scheme_gid, $linked_unit_id) = ($1, $2);
			my $linked_scheme_id = $gid_to_scheme_id->{$linked_scheme_gid};
			if( !$linked_scheme_id )
			{
				debug "incorrect link to other scheme: no access to scheme gid=$linked_scheme_gid";
				next;
			}
			push @debug_gids, $linked_scheme_gid;
			push @{$schemes_linked_cables->{$gid_to_scheme_id->{$gid}}}, [$u, $linked_scheme_gid, $linked_unit_id];
			$schemes->{$linked_scheme_id} && next;
			my $d = $schemes->{$linked_scheme_id} = get_all($linked_scheme_id, {
				return => ['links'],
				tag_filters => ses::input('tag_filters'),
			});
			push @unit_series, [$linked_scheme_gid, $d->{units}];
			$places_by_cable_id->{$u->{id}} = $u->{add_data}{places} || [0, 0];
		}
		scalar @debug_gids && debug "scheme $gid is linked with:", @debug_gids;
	}

	my @res_units = @{$main_scheme->{units}};
	my $res_links = $main_scheme->{links} || [];
	my @res_links = @$res_links;

	# --- Reconnect links ---
	my %reconnect_links = ();
	foreach my $a_scheme_id( grep { $_ != $scheme_id } keys %$schemes )
	{
		foreach my $d( @{$schemes_linked_cables->{$a_scheme_id}} )
		{
			my($u, $b_scheme_gid, $b_unit_id) = @$d;
			my $b_scheme_id = $gid_to_scheme_id->{$b_scheme_gid} or next;
			if( $b_scheme_id == $scheme_id || $a_scheme_id < $b_scheme_id )
			{
				$reconnect_links{$u->{id}} = $b_unit_id;
				$u->{type} = 'none';
				if( my $places = $places_by_cable_id->{$b_unit_id} )
				{
					$u->{add_data}{places}[0] ||= $places->[0];
					$u->{add_data}{places}[1] ||= $places->[1];
					$places->[0] ||= $u->{add_data}{places}[0];
					$places->[1] ||= $u->{add_data}{places}[1];
				}
			}
		}
		push @res_units, @{$schemes->{$a_scheme_id}{units}};
	}

	foreach my $a_scheme_id( keys %$schemes )
	{
		$a_scheme_id == $scheme_id && next;
		my @a_links = ();
		foreach my $l( @{$schemes->{$a_scheme_id}{links}} )
		{
			$l->{src} = $reconnect_links{$l->{src}} if exists $reconnect_links{$l->{src}};
			$l->{dst} = $reconnect_links{$l->{dst}} if exists $reconnect_links{$l->{dst}};
			push @a_links, $l;
		}
		push @res_links, @a_links;
	}


	# --- Combine schemes ---
	if( $params->{combine_schemes} )
	{
		# debug 'Combine schemes';
		my $process_schemes = {};
		my @scheme_ids = ([$scheme_gid, $scheme_id]);
		while( @scheme_ids )
		{
			my($a_scheme_gid, $a_scheme_id) = @{pop @scheme_ids};
			# debug "scheme $a_scheme_gid";
			foreach my $d( @{$schemes_linked_cables->{$a_scheme_id}} )
			{
				my($ua, $b_scheme_gid, $b_unit_id) = @$d;

				$process_schemes->{$b_scheme_gid}++ && next;
				my $b_scheme_id = $gid_to_scheme_id->{$b_scheme_gid} or next;

				push @scheme_ids, [$b_scheme_gid, $b_scheme_id];

				my $a_unit_id = $ua->{id};
				my $box_a = Fibers::Units->new(%$ua)->bounding_box();
				my($dx, $dy);
				debug "scheme $a_scheme_gid links $b_scheme_gid. Search cable with link $a_scheme_gid:$a_unit_id";

				foreach my $d( @{$schemes_linked_cables->{$b_scheme_id}} )
				{
					my($ub, $x_scheme_gid, $x_unit_id) = @$d;
					"$x_scheme_gid:$x_unit_id" eq "$a_scheme_gid:$a_unit_id" or next;

					my $box_b = Fibers::Units->new(%$ub)->bounding_box();
					$dx = $box_a->{'center_x'} - $box_b->{'center_x'};
					$dy = $box_a->{'center_y'} - $box_b->{'center_y'};
					last;
				}

				defined $dx or next;

				foreach my $ub ( @{$schemes->{$b_scheme_id}{units}} )
				{
					if( $ub->{cls} eq 'cable' )
					{
						$ub->{xa} += $dx;
						$ub->{ya} += $dy;
						$ub->{xb} += $dx;
						$ub->{yb} += $dy;

						foreach my $i( @{$ub->{joints}} )
						{
							$i->{x} += $dx;
							$i->{y} += $dy;
						}
					}
					 else
					{
						$ub->{x} += $dx;
						$ub->{y} += $dy;
					}
				}
				foreach my $link ( @{$schemes->{$b_scheme_id}{links}} )
				{
					$link->{joints} = [];
				}
			}
		}

		foreach my $units( values %$schemes_linked_cables )
		{
			if( @$units )
			{
				map{ delete $_->[0]{add_data}{linked_scheme} } @$units;
			}
		}
	}

	return(\@res_units, \@res_links, $scheme_settings);
}

sub copy
{
	my($scheme_id, undef, undef) = @_;
	my $res = get_all($scheme_id, { return=>['links'], process_area=>1, copy_action=>1 });

	my $units_count = scalar @{$res->{units}};
	my $ret_message = "$units_count units were copied";
	$units_count or return $ret_message;

	Db->do(
		'DELETE FROM webses_data WHERE module=? AND role=? AND aid=?',
		'ajFibers__clipboard', $ses::auth->{role}, $ses::auth->{uid}
	);

	my $unikey = Save_webses_data(
		module => 'ajFibers__clipboard',
		data => $res,
	);

	return $ret_message;
}

sub export_scheme
{
	ApiError(L($err_only_in_pro_version));
}

sub import_scheme
{
	ApiError($err_only_in_pro_version);
}

sub map_get_all
{
	my($scheme_id) = @_;
	return _main_get_all($scheme_id, { return=>['user', 'map_data'] });
}

sub get_all_end_center_unit
{
	my($scheme_id, $centered_unit_id) = @_;
	#my $u = Fibers::Units->get_by_id($centered_unit_id, { check_removed=>1 });
	#$u->{type} eq 'container' && return undef;
	my $ret = ['user', 'links', 'map_data'];
	if( ses::input_int('first_request') )
	{
		push @$ret, 'bookmarks', 'fibers_colors', 'fibers_colors_presets', 'templates';
	}
	my $res = _main_get_all($scheme_id, { return=>$ret });
	$res->{center_unit_id} = $centered_unit_id;
	return $res;
}

sub main_get_all
{
	my($scheme_id) = @_;
	my $scheme = $Scheme_data;

	my $ret = ['user', 'links'];
	my $params = {
		auto_simplify_scheme => 1,
		return => $ret,
	};
	if( ses::input_int('preview') )
	{   # scheme preview when a collection are shown
		push @$ret, 'fibers_colors';
	}
	 else
	{
		$params->{process_area} = 1;
		if( ses::input_exists('simple') )
		{
			$params->{simplified_scheme} = ses::input_int('simple');
			$params->{auto_simplify_scheme} = 0;
		}
		push @$ret, 'map_data';
		if( ses::input_int('first_request') )  # || !ses::input_exists('simple') )
		{
			push @$ret, 'bookmarks', 'fibers_colors', 'fibers_colors_presets', 'templates';
		}
		# connector data from external db
		$params->{tx_rx_mode} = ses::input('tx_rx_mode') if (
			ses::input('tx_rx_mode') && $scheme_id == $scheme->{id}
			&& $scheme->{inner_data_db} && $scheme->{inner_data_db_fields}
		);
		$params->{tag_filters} = ses::input('tag_filters');
	}

	return _main_get_all($scheme_id, $params);
}

sub _combine_tags
{
	my($common_tags, $scheme_tags, $scheme_id) = @_;
	ref $scheme_tags ne 'HASH' && return;
	foreach my $tag( keys %$scheme_tags )
	{
		my $title = $scheme_tags->{$tag};
		$common_tags->{$title} ||= {};
		$common_tags->{$title}{"$scheme_id:$tag"} = 1;
	}
}

sub _main_get_all
{
	my($scheme_id, $params) = @_;

	my $scheme = $Scheme_data;

	my $res = get_all($scheme_id, $params);
	$res->{settings} = from_json($scheme->{settings} || '{}');
	my $tags = {};
	_combine_tags( $tags, $res->{settings}{tags}, $scheme_id );

	{   # all_linked_schemes
		ses::input('all_linked_schemes') or last;

		my($units, $links, $scheme_settings) = _get_all_linked_schemes($scheme_id, $res, { combine_schemes=>1, return=>['links'] });
		$res->{units} = $units;
		$res->{links} = $links;
		foreach my $sid( keys %$scheme_settings )
		{
			_combine_tags( $tags, $scheme_settings->{$sid}{tags}, $sid );
		}
	}
	$res->{settings}{tags} = { map { join(',', sort{ int($a) <=> int($b) } keys %{$tags->{$_}}) => $_ } keys %$tags };
	$res->{full_access} = int $User->{full_access};
	$res->{stock_enabled} = $cfg::fibers_stock_enabled;
	return $res;
}

sub get_all
{
	my($scheme_id, $params) = @_;
	$params ||= {
		return => ['user', 'links', 'fibers_colors', 'fibers_colors_presets', 'bookmarks', 'templates', 'map_data']
	};
	my @r = @{$params->{return}};
	$params->{return} = {};
	map{ $params->{return}{$_} = 1 } ( @r );

	my $inner_titles = {};
	my $inner_styles = {};
	if( $params->{tx_rx_mode} =~ /^(TX|RX)$/ )
	{
		my($db_server, $db_name, $db_user, $db_pw, $db_table) = split / *: */, $Scheme_data->{inner_data_db};
		ApiError('check inner data db table: '.$db_table) if $db_table !~ /^\w+$/;
		my($id_fields, $tx_field, $rx_field) = split / *: */, $Scheme_data->{inner_data_db_fields};
		my @id_fields = split / *\+ */, $id_fields;
		foreach my $i( @id_fields ) {
			ApiError('check inner data db id field: '.$i) if $i !~ /^\w+$/;
		}
		ApiError('check inner data db tx field: '.$tx_field) if $tx_field !~ /^\w+$/;
		ApiError('check inner data db rx field: '.$rx_field) if $rx_field !~ /^\w+$/;
		my $ext_db = Db->new(
			host    => $db_server,
			user    => $db_user,
			pass    => $db_pw,
			db      => $db_name,
			timeout => 5,
			tries   => 1,
		);
		$ext_db->connect;
		$ext_db->is_connected or ApiError(L('inner data db connection error'));

		my $s = (from_json($Scheme_data->{settings} || '{}'))->{signal_levels};
		my $db = $ext_db->sql("SELECT `$tx_field`, `$rx_field`, ".join(', ', map{ "`$_`" } @id_fields)." FROM `$db_table` LIMIT 15000");
		while( my %p = $db->line )
		{
			my $remote_id = join ':', map{ $p{$_} } @id_fields;
			my $val = $inner_titles->{$remote_id} = $params->{tx_rx_mode} eq 'RX' ? $p{$rx_field} : $p{$tx_field};
#<HOOK>get_all_tx_rx
		}
	}

	my $area_x1 = ses::input_int('area_x1');
	my $area_x2 = ses::input_int('area_x2');
	my $area_y1 = ses::input_int('area_y1');
	my $area_y2 = ses::input_int('area_y2');
	($area_x1, $area_x2) = ($area_x2, $area_x1) if $area_x1 > $area_x2;
	($area_y1, $area_y2) = ($area_y2, $area_y1) if $area_y1 > $area_y2;
	my $area = $params->{process_area} && ($area_x1 || $area_x2 || $area_y1 || $area_y2);

	my $units = [];
	my $cable_types = {};
	my $container_types = {};
	my $ignore = [];

	my $res = {
	  ver => '1.0',
	  units => $units,
	};

	if( $params->{return}{user} )
	{
		$res->{user} = $User;
		$res->{ignore} = $ignore;
		$res->{is_block} = $Scheme_data->{is_block};
	}

	my %tag_filters = ();
	my $has_tag_filters = length $params->{tag_filters};
	if( $has_tag_filters )
	{
		foreach my $tag( split ',', $params->{tag_filters} )
		{
			my($sid, $tag) = split ':', $tag;
			$tag_filters{$tag} = 1 if $sid == $scheme_id;
		}
	}

	my %units = ();
	my %stat = ();
	my %hidden_id = ();
	my %visible_containers = ();

	my $db = Db->sql(
		'SELECT u.*, c.xa, c.ya, c.xb, c.yb, c.joints, c.length, c.trunk '.
		'FROM fibers_units u LEFT JOIN fibers_cables c ON u.tied=c.id '.
		'WHERE u.removed=0 AND u.scheme_id=? ORDER by u.type=?',
		$scheme_id, 'container'
	);

	if( keys %$inner_titles )
	{
		$params->{simplified_scheme} = 0;
	}
	 elsif( $params->{auto_simplify_scheme} && $scheme_id && $db->rows > 100 )
	{
		$params->{simplified_scheme} = 1;
	}

	while( my %p = $db->line )
	{
		my $u = Fibers::Units->new(%p);

		$res->{has_linked_schemes} = 1 if $u->{add_data} && $u->{add_data}{linked_scheme};

		if( $has_tag_filters && $u->{cls} ne 'cable' )
		{
			my $show = 0;
			my $tags = $u->{add_data}{tags} || [];
			foreach my $tag( @$tags )
			{
				if( $tag_filters{int $tag} )
				{
					$show = 1;
					last;
				}
			}
			$show or next;
		}

		if( $params->{tx_rx_mode} )
		{
			foreach my $iu( values %{$u->{inner_units}} )
			{
				$iu->{name} = '';
				if( exists $iu->{remote_id} && $inner_titles->{$iu->{remote_id}} )
				{
					my $r_id = $iu->{remote_id};
					$iu->{name} = $inner_titles->{$r_id};
					$iu->{style} = $inner_styles->{$r_id} if $inner_styles->{$r_id};
				}
			}
		}

		my $id = $u->{id};
		my $data = $u->data();
		if( $area )
		{
			my $box = $u->bounding_box();
			my $x1 = $box->{x_min};
			my $y1 = $box->{y_min};
			my $x2 = $box->{x_max};
			my $y2 = $box->{y_max};

			if(
				!$visible_containers{$id} && (
					($x1 < $area_x1 && $x2 < $area_x1) ||
					($x1 > $area_x2 && $x2 > $area_x2) ||
					($y1 < $area_y1 && $y2 < $area_y1) ||
					($y1 > $area_y2 && $y2 > $area_y2)
				)
			) {
				$hidden_id{$id} = 1;
				next;
			}
		}
		$data->{grp} = $data->{scheme_id}.':'.$data->{grp} if int($data->{grp}) && !$params->{export_action};
		delete $data->{old};
		delete $data->{removed};
		delete $data->{scheme_id};
		if( $data->{type} eq 'container' && !$data->{add_data}{layers} )
		{
			$data->{layers} = $data->{add_data}{subtype} ? 'infrastructure' : '';
		}
		push @$units, $data;
		$units{$id} = $data;
		my $stat_id = $stat{$id} ||= {};
		if( $params->{simplified_scheme} )
		{
			my $box = $u->box_size();
			my $w = $box->{width} || 1;
			my $h = $box->{height} || 1;
			my $new_x = $data->{x} + $box->{x_min} + int(0.5 * $w);
			my $new_y = $data->{y} + $box->{y_min} + int(0.5 * $h);
			if( $params->{simplified_scheme} )
			{
				$data->{x} = $new_x;
				$data->{y} = $new_y;
				$data->{width} = $w;
				$data->{height} = $h;
			}
		}
		map{ $stat_id->{$_} = 1 } keys %{$u->{inner_units}};
		$visible_containers{$data->{place_id}} = 1 if $data->{place_id};
	}

	if( $params->{return}{links} )
	{
		my $links = $res->{links} = [];
		my $db = Db->sql(
			'SELECT l.*, c.joints FROM fibers_links l LEFT JOIN fibers_cables c ON l.tied=c.id '.
			'WHERE l.removed=0 AND l.scheme_id=?', $scheme_id
		);
		my %dup_links = ();
		my %connected_utits = ();
		while( my %p = $db->line )
		{
			if( exists $hidden_id{$p{src}} && exists $stat{$p{dst}}{$p{dst_inner}} )
			{
				push @$ignore, "$p{dst}:$p{dst_side}:$p{dst_inner}";
			}
			if( exists $hidden_id{$p{dst}} && exists $stat{$p{src}}{$p{src_inner}} )
			{
				push @$ignore, "$p{src}:$p{src_side}:$p{src_inner}";
			}
			# dead links
			exists $stat{$p{src}}{$p{src_inner}} or next;
			exists $stat{$p{dst}}{$p{dst_inner}} or next;

			$connected_utits{$p{src}} = 1;
			$connected_utits{$p{dst}} = 1;

			my $link = Fibers::Links->new(%p);
			my $link_data = $link->data();

			delete $link_data->{old};
			delete $link_data->{tied};

			if( $params->{simplified_scheme} )
			{
				my $src_str = "$link_data->{src}:$link_data->{src_side}";
				my $dst_str = "$link_data->{dst}:$link_data->{dst_side}";
				$src_str eq $dst_str && next;
				($dup_links{"$src_str-$dst_str"} || $dup_links{"$dst_str-$src_str"}) && next;
				$dup_links{"$src_str-$dst_str"}++;
				delete $link_data->{src_inner};
				delete $link_data->{dst_inner};
				$link_data->{joints} = [];
			}

			my $u_src = $units{$p{src}};
			my $u_dst = $units{$p{dst}};

			$link_data->{src_grp} = $u_src->{grp} if $u_src->{grp};
			$link_data->{dst_grp} = $u_dst->{grp} if $u_dst->{grp};
			$link_data->{color} = $u_src->{inner_units}{$link_data->{src_inner}}{color} if
				$u_src->{cls} eq 'cable' &&
				$u_src->{inner_units}{$link_data->{src_inner}};
			$link_data->{color} = $u_dst->{inner_units}{$link_data->{dst_inner}}{color} if
				$u_dst->{cls} eq 'cable' &&
				$u_dst->{inner_units}{$link_data->{dst_inner}};

			push @$links, $link_data;
		}
		if( $has_tag_filters )
		{
			my $filtered_units = [];
			foreach my $u( @$units )
			{
				$u->{cls} eq 'cable' && !$connected_utits{$u->{id}} && !$u->{add_data}{linked_scheme} && next;
				push @$filtered_units, $u;
			}
			$res->{units} = $units = $filtered_units;
		}
	}

	if( $params->{return}{fibers_colors_presets} )
	{
		my $fibers_colors_presets = $res->{fibers_colors_presets} = {};
		my $db = Db->sql(
			'SELECT * FROM fibers_colors_presets '.
			'WHERE scheme_id=(SELECT MAX(scheme_id) FROM fibers_colors_presets WHERE scheme_id=0 OR scheme_id=?)', $scheme_id
		);
		while( my %p = $db->line )
		{
			my $id = int $p{id};
			$fibers_colors_presets->{$id} = {
				colors => [map{ int $_ } split / *, */, $p{colors}],
				description => v::trim($p{description}) || $id,
			};
			$fibers_colors_presets->{$id}{can_remove} = int(!!$p{scheme_id}) if !$params->{export_action};
		}
	}

	if( $params->{return}{bookmarks} )
	{
		my $bookmarks = $res->{bookmarks} = [];
		my $db = Db->sql('SELECT grp, name, x, y, zoom FROM fibers_bookmarks WHERE removed=0 AND scheme_id=? ORDER BY name', $scheme_id);
		while( my %p = $db->line )
		{
			push @$bookmarks, \%p;
		}
	}

	if( $params->{return}{fibers_colors} )
	{
		my $fibers_colors = $res->{fibers_colors} = {};
		my $copy_colors_into_external_db = 0;
		my $db0 = Db->self();
		while( 1 )
		{
			my $db = $db0->sql('SELECT * FROM fibers_colors');
			while( my %p = $db->line )
			{
				$fibers_colors->{$p{id}} = {
					id => $p{id},
					color => $scheme_id ? $p{color} : '#c0c0c0',
					description => L(v::trim($p{description})) || $p{color}
				};
				if( $copy_colors_into_external_db )
				{
					Db->do(
						'INSERT INTO fibers_colors set id=?, color=?, description=?',
						$p{id}, $p{color}, $p{description}
					);
				}
			}
			keys %$fibers_colors && last;
			$copy_colors_into_external_db && last;
			$copy_colors_into_external_db = 1;
			$db0 = $Fibers::MainDb;
		}
	}

	if( $params->{return}{templates} )
	{
		my $raw_templates = '';
		my $tmpl_name = $cfg::tmpl_dir.'fibers/templates.html';
		open( my $f, "<:raw", $tmpl_name ) or die "cannot load file $tmpl_name";
		binmode($f);
		$raw_templates .= $_ while(<$f>);
		close($f);
		my $templates = {};
		foreach my $t( split /<nodeny>/, $raw_templates )
		{
			$t =~ /<\/nodeny>/ or next;
			my($name, $value) = split /<\/nodeny>/, $t;
			$name = v::trim($name);
			$templates->{$name} = v::trim($value);
		}

		$res->{templates} = $templates;
		$res->{translate} = $lang::ajFibers;
	}

	if( $params->{return}{map_data} )
	{
		my $sql_end = $cfg::fibers_collective_data ? '' : 'WHERE scheme_id='.int($scheme_id);
		my $db = Db->sql("SELECT id, type, color, line_width FROM fibers_cable_types $sql_end");
		while( my %p = $db->line )
		{
		  $cable_types->{$p{id}} = \%p;
		}
		my $db = Db->sql("SELECT id, type, color, shape, size, hide_on_zoom FROM fibers_container_types $sql_end");
		while( my %p = $db->line )
		{
		  $container_types->{$p{id}} = \%p;
		}
	#        my $name_field = $cfg::Lang eq 'RU' ? 'name_ru' : 'name_uk';
	#        my $db = Db->sql('SELECT id, name_ru, name_uk, comment FROM fibers_trunks WHERE scheme_id=?', $scheme_id);
	#        while( my %p = $db->line )
	#        {
	#            $p{name} = $p{$name_field};
	#            delete $p{name_ru};
	#            delete $p{name_uk};
	#            push @$trunks, \%p;
	#        }
		$res->{map_data} = {
			cable_types => $cable_types,
			container_types => $container_types,
			center => {
				lat => $Scheme_data->{lat} || 50.44951948506466,
				lng => $Scheme_data->{lng} || 30.525366076726748,
			}
		};
	}

	if( !$params->{export_action} )
	{
		$res->{simplified_scheme} = $params->{simplified_scheme};
		$res->{hidden_ids} = [keys %hidden_id];
	}

	return $res;
}

sub _delete_scheme_now
{
	my($scheme_id, undef, $act) = @_;
	Db->do('DELETE FROM fibers_units WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_links WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_history WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_bookmarks WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_colors_presets WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_cable_types WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_container_types WHERE scheme_id=?', $scheme_id);
	Db->do('DELETE FROM fibers_trunks WHERE scheme_id=?', $scheme_id);
}

sub _validate_signal_levels
{
	my($levels) = @_;
	ref $levels eq 'ARRAY' or return '';
	scalar @$levels == 4 or return '';
	my @levels = map{ +$_ } @$levels;
	$levels[0] >= $MIN_SIGNAL_LEVEL or return '';
	$levels[1] > $levels[0] or return '';
	$levels[2] > $levels[1] or return '';
	$levels[3] > $levels[2] or return '';
	$levels[3] <= $MAX_SIGNAL_LEVEL or last;
	return \@levels;
}

sub import_all
{
	my($scheme_id, undef, $act) = @_;
	my($data, $x, $y);
	my $is_import_action = 0;

#<HOOK>import_all
	{   # paste into the scheme/collection from clipboard
		($x, $y) = check_xy(ses::input_int('x', 'y'));
		my %p = Db->line(
			'SELECT * FROM webses_data WHERE module=? AND role=? AND aid=? ORDER BY created DESC LIMIT 1',
			'ajFibers__clipboard', $ses::auth->{role}, $ses::auth->{uid}
		);
		$data = %p ? Debug->do_eval($p{data}) : '';
		$data or ApiError(L('Сlipboard is empty'));

		if( $act eq 'into_collection' )
		{
			$Uid or ApiError(L('You need to log in'));
			my $gid = md5_base64(rand 10**10); $gid =~ s/[\+\/]//g;
			Db->do("INSERT INTO fibers_schemes SET shared=0, is_block=1, gid=?, uid=?, name=?", $gid, $Uid, 'Block');
			Db->ok or ApiError(L('DB error'));
			$Fibers::Scheme_id = $scheme_id = Db::result->insertid;
		}
	}

	if( ref $data ne 'HASH' )
	{
		debug 'error', 'root: hash required';
		_corrupted_data();
	}
	foreach my $i( 'units', 'links' )
	{
		if( ref $data->{$i} ne 'ARRAY' )
		{
			debug 'error', "$i is not an array";
			_corrupted_data();
		}
	}

	my $units = [];
	my $i = 0;
	my $x_min = $fibers__xy_bounds->{x};
	my $y_min = $fibers__xy_bounds->{y};
	foreach my $p( @{$data->{units}} )
	{
		if( ++$i > $import_scheme__max_units )
		{
			debug 'pre', 'error', {
				units => $i,
				max => $import_scheme__max_units,
			};
			ApiError(L('Too many units'));
			die;
		}

		if( ref $p ne 'HASH' )
		{
			debug 'error', 'element of an unit is not a hash';
			_corrupted_data();
		}

		$p->{type} eq 'fragment' && next;

		$p->{scheme_id} = $scheme_id;
		$p->{removed} = 0;
		$p->{img} = '';

		my $pkg = Fibers::Units->package_by_cls($p->{cls});
		my $d = $pkg->check_data($p);
		if( ! ref $d )
		{
			debug 'pre', 'error', {
				'error' => $d,
				'data' => $p,
			};
			_corrupted_data();
		}
		push @$units, $d;
		my $u = Fibers::Units->new(%$d);
		my $box = $u->bounding_box();
		$x_min = $box->{x_min} if $box->{x_min} < $x_min;
		$y_min = $box->{y_min} if $box->{y_min} < $y_min;
	}

	$x -= $x_min;
	$y -= $y_min;

	my $links = [];
	my $i = 0;
	foreach my $p( @{$data->{links}} )
	{
		if( ++$i > $import_scheme__max_links )
		{
			debug 'pre', 'error', {
				links => $i,
				max => $import_scheme__max_links,
			};
			ApiError(L('Too many links'));
			die;
		}

		if( ref $p ne 'HASH' )
		{
			debug 'error', 'a link is not a hash';
			_corrupted_data();
		}

		my $d = Fibers::Links->check_data($p);
		if( ! ref $d )
		{
			debug 'pre', 'error', {
				'error' => $d,
				'data' => $p,
			};
			_corrupted_data();
		}
		if( !$is_import_action && ref $d->{joints} )
		{
			foreach my $joint( @{$d->{joints}} )
			{
				$joint->{x} += $x;
				$joint->{y} += $y;
			}
		}
		push @$links, $d;
	}

	my $select_units_on_viewport = [];
	my @warn = ();

	Db->begin_work or _db_error();

#<HOOK>import_all_transaction

	my %already_moved = ();
	my %old_to_new_id = ();
	my $tieds = {};

	my $create_params = { no_commit=>1, heap_history=>1, without_transaction=>1 };

	foreach my $p(
	  sort{ int($a->{place_id}) <=> int($b->{place_id}) }
	  sort{ ($b->{type} eq 'container') <=> ($a->{type} eq 'container') }
	  @$units
	) {
		my $id = $p->{id};
		my $tied = $p->{tied};
		$p->{tied} = int $tieds->{$tied} if $tieds;
		$p->{place_id} = int $old_to_new_id{int($p->{place_id})} if int($p->{place_id}) > 0;
		if( $p->{cls} eq 'cable' )
		{
			if( ref $p->{joints} eq 'ARRAY' )
			{
				foreach my $i( @{$p->{joints}} )
				{
					ref $i eq 'HASH' or next;
					$i->{place_id} = int $old_to_new_id{int($i->{place_id})} if int($i->{place_id}) > 0;
				}
			}
			if( ref $p->{add_data}{places} eq 'ARRAY' )
			{
				my $i = $p->{add_data}{places};
				$i->[0] = int $old_to_new_id{int($i->[0])} if int($i->[0]) > 0;
				$i->[1] = int $old_to_new_id{int($i->[1])} if int($i->[1]) > 0;
			}
		}
		$p->{grp} = 0 if !$is_import_action;
		my $u = Fibers::Units->create($p, '', $create_params);
		$old_to_new_id{$id} = $u->{id};
		$tieds->{$tied} = $u->{tied} if $tied;
		if( !$is_import_action && (!$u->{tied} || !$already_moved{$u->{tied}}++) )
		{
			$u->change_position($x, $y);
			$u->save('', {no_history=>1, no_commit=>1});
		}
		push @$select_units_on_viewport, $u->{id};
	}

	foreach my $p( @$links )
	{
		$p->{src} = $old_to_new_id{$p->{src}} or next;
		$p->{dst} = $old_to_new_id{$p->{dst}} or next;
		my $joints = $p->{joints} || [];
		my $u = Fibers::Links->create($p, '', $create_params);
		push @$select_units_on_viewport, $u->{id};
	}

	$act eq 'paste' && Fibers->create_history_record(['paste'], $Fibers::History);

	Db->commit;

	$act eq 'into_collection' && return undef;

	scalar @warn && debug 'warn', 'pre', @warn;
	my $res = main_get_all($scheme_id);
	$res->{select_units} = $select_units_on_viewport if $act eq 'paste';
	return $res;
}

sub show_collection
{
	$Uid or ApiError(L('You need to log in'));
	my $on_page = 10;
	my $page = ses::input_int('page');
	my $limit_from = $on_page * $page;
	my $schemes = [];
	my $all_schemes = $User->{superadmin} && ses::input_int('all_schemes');
	my($sql, @sql_params) = ('FROM fibers_schemes fs', ());
	if( $all_schemes )
	{
		$sql .= " JOIN fibers_units fu ON fs.id = fu.scheme_id WHERE fs.is_block=0 AND fu.removed=0";
	}
	 else
	{
		$sql .= " WHERE is_block=1 AND ".($cfg::fibers_common_for_all ? '(uid=? OR shared>0)' : 'uid=?');
		@sql_params = ($Uid, $Uid);
	}

	my %p = Db->line("SELECT COUNT(DISTINCT fs.id) n $sql", @sql_params);
	my $pages = int($p{n} / $on_page) + 1;

	$sql .= $all_schemes ? " GROUP BY fs.gid, fs.id ORDER BY fs.id DESC" : " ORDER BY (uid=?) DESC, name, id DESC";

	my $db = Db->sql("SELECT DISTINCT fs.gid $sql LIMIT $limit_from, $on_page", @sql_params);
	while( my %p = $db->line )
	{
		push @$schemes, \%p;
	}
	return [{
		schemes => $schemes,
		all_schemes => $all_schemes,
		pages => $pages,
	}];
}

sub frame_create
{
	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $type = ses::input('type');
	my $connectors = ses::input_int('connectors');
	return _frame_create( $scheme_id, {
		type => $type, x => $x, y => $y, connectors => $connectors
	});
}

sub _frame_create
{
	my($scheme_id, $params) = @_;
	my $type = $params->{type};
	my $x = $params->{x};
	my $y = $params->{y};
	my $connectors = $params->{connectors};
	my $solder_count = int $params->{solder_count};
	my $create_params = $params->{create_params} || {};

	($x, $y) = check_xy($x, $y);
	$type =~ /^(panel|coupler|switch|splitter|onu|container)$/ or ApiError('Type error');
	$solder_count = 0 if $solder_count < 0;
	$solder_count = 64 if $solder_count > 64;

	my $inner = {};
	my $add_data = {};

	if( $type eq 'onu' )
	{
		$connectors = 1;
		$solder_count = 0;
	}
	 elsif( $type eq 'container' )
	{
		$add_data->{layers} = ses::input('fibers_mode') eq 'map' ? 'infrastructure' : '';
	}
	 elsif( $connectors <= 0 || $connectors > 100 )
	{
		ApiError('Connectors count error');
	}

	my $yi = 0;
	my $xi = 0;
	my $i = $type eq 'splitter' ? 0 : 1;
	my $inner_type = $type eq 'switch'	?	'port' :
					 $type eq 'coupler'	?	'solder' :
					 $type eq 'splitter'?	'splitter' :
											'connector';
	my $set_cols = ses::input_int('cols') || 1;
	# id of the first connector in the second column
	my $col2_starts_with_connector_id = $set_cols > 1 ? int(($connectors+1)/2) + 1 : 100;
	$col2_starts_with_connector_id = 1 if $type eq 'splitter';
	my $connector_y_distance = $connectors > (16 * $set_cols) ? int($inner_units_distance*0.8) : $inner_units_distance;
	$yi = int($connector_y_distance * ($connectors-1) / 2) if $type eq 'splitter' && $solder_count;
	my $x_bias = 0;
	while( $i <= ($connectors + $solder_count) )
	{
		if( $i > $connectors )
		{
			$inner_type = 'solder';
			$x_bias = -$inner_units_distance;
			$connector_y_distance = $inner_units_distance;
		}
		$inner->{$i} = {
			'i'    => $i,
			'x'    => $xi + $x_bias,
			'y'    => $yi,
			'name' => $connectors < 2 ? '' : $i || '',
			'type' => $inner_type,
		};
		$yi += $connector_y_distance;
		$i++;
		if( $yi > $fibers__inner_xy_bounds->{y} )
		{
			$yi = 0;
			$xi += 2*$inner_units_distance;
		}
		 elsif( $i == $col2_starts_with_connector_id )
		{
			$yi = 0;
			$xi += $inner_units_distance;
			$xi += $inner_units_distance if $type eq 'splitter';
		}
	}

	my $data = {
		'scheme_id' => $scheme_id,
		'cls'   => 'frame',
		'type'  => $type,
		'name'  => '',
		'x'     => $x,
		'y'     => $y,
		'x0'    => 0,
		'y0'    => 0,
		'img'   => '',
		'grp'   => 0,
		'place_id'    => 0,
		'description' => '',
		'inner_units' => $inner,
		'add_data'    => $add_data,
	};
	my $u = Fibers::Units->create($data, ['creating_of', 'of_'.$type], $create_params);
	$params->{return_unit} && return $u;
	return $u->data();
}

sub frame_show_img
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	return $u->{img} ? [{
		type  => 'image',
		image => "$cfg::img_dir/fibers/u_".$scheme_id."_$id.".$u->{img},
	}] : '';
}

sub frame_upload_img
{
	my($scheme_id, $id) = @_;

	my $u = Fibers::Units::Frame->get_by_id($id);
	$u->{img} = '';
	my $img = ses::input_file('img');
	{
		$img eq '' && last;
		debug(ses::input('img')->{file});
		ses::input('img')->{file} =~ /\.($cfg::valid_img_ext)$/i or ApiError("Only $cfg::valid_img_ext");
		my $ext = $u->{img} = lc $1;
		my $file = "$cfg::dir_home/htdocs/fibers/upload/u_".$scheme_id."_$id.$ext";

		my $fh_out;
		if( !open( $fh_out, '>', $file) )
		{
			debug('error', _($lang::cannot_save_file, $file));
			ApiError($lang::err_try_again);
		}

		binmode $fh_out;
		flock($fh_out, 2);
		print $fh_out $img;
		flock($fh_out, 8);
		close($fh_out);
	}
	$u->save('picture uploading', { no_need_dumps_in_history=>1 });
	return $u->data();
}

sub frame_remove_img
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	$u->{img} = '';
	$u->save('picture removing', { no_need_dumps_in_history=>1 });
	return $u->data();
}

sub frame_data
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id, { without_transaction=>1, check_removed=>1 });
	my $tags = $u->{add_data}{tags} || [];
	my $res = {
		id => $id,
		name => $u->{name},
		description => $u->{description},
		place_id => $u->{place_id} || '',
		grp => $u->{grp},
		map_type => $u->{map_type},
		nodeny_obj_id => $u->{nodeny_obj_id},
		is_container => 0,
		tags => [ map{ $_.'' } @$tags ],
	};
	if( $u->{type} eq 'container' )
	{
		$res->{is_container} = 1;
		my $map_types = $res->{map_types} = [];
		my $sql_end = $cfg::fibers_collective_data ? '' : 'WHERE scheme_id='.int($scheme_id);
		my $db = Db->sql("SELECT * FROM fibers_container_types $sql_end");
		while( my %p = $db->line )
		{
			push @$map_types, \%p;
		}
		$res->{layers} = exists $u->{add_data}{layers} ? $u->{add_data}{layers} : $u->{add_data}{subtype} ? 'infrastructure' : '';
	}
	return $res;
}

sub frame_data_save
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my %fl = %Fibers::Units::fields_lengths;
	my $reload = 0;
	foreach my $field( 'name', 'description' )
	{
		ses::input_exists($field) or next;
		$u->{$field} = substr(ses::input($field), 0, $fl{$field});
	}
	if( $u->{type} eq 'container' )
	{
		if( ses::input_exists('map_type') )
		{
			my $map_type = ses::input_int('map_type');
			my $sql_end = $cfg::fibers_collective_data ? '' : 'AND scheme_id='.int($scheme_id);
			$map_type && !Db->line(
				"SELECT 1 FROM fibers_container_types WHERE id=? $sql_end", $map_type
			) && ApiError('type number error');
			$u->{map_type} = $map_type;
		}
		if( ses::input_exists('layers') && ses::input('layers') =~ /^(|scheme|infrastructure)$/ )
		{
			my $new_val = ses::input('layers');
			$new_val eq 'scheme' && ($u->{lat} || $u->{lng}) && ApiError(
			  L('The container cannot be removed from the infrastructure layer because it is set on the map'));
			# $u->{add_data}{subtype} deprecated
			my $old_val = exists $u->{add_data}{layers} ? $u->{add_data}{layers} : $u->{add_data}{subtype} ? 'infrastructure' : '';
			$u->{add_data}{layers} = $new_val;
			delete $u->{add_data}{subtype} if exists $u->{add_data}{subtype};
			$reload = 1 if $old_val ne $new_val;
		}
	}
	 else
	{
		$u->{grp} = ses::input_int('grp') if ses::input_exists('grp');
	}

	delete $u->{add_data}{tags};
	foreach my $i( 0..$MAX_FRAME_TAGS )
	{
		if( ses::input_int("tag_$i") )
		{
			$u->{add_data}{tags} ||= [];
			push @{$u->{add_data}{tags}}, $i;
		}
	}

	$u->save(['data_changing_of', 'of_'.$u->{type}]);
	return $reload ? 'reload' : $u->data();
}

sub _in_out_container
{
	my($scheme_id, $id, $place_id) = @_;

	($place_id < 0 || $place_id == $id) && return undef;

	my $u = Fibers::Units->get_by_id($id);
	$u->{type} eq 'container' && return undef;
	my $only_map = ses::input('fibers_mode') eq 'map';
	$only_map && $u->{cls} ne 'cable' && return undef;

	if( $place_id )
	{
		my $container = Fibers::Units::Frame->get_by_id($place_id, {without_transaction=>1});
		$container->{type} eq 'container' or return undef;
	}

	my($target, $old_place_id, $x, $y);
	if( $u->{cls} eq 'cable' )
	{
		my $joint_num = ses::input_int('joint_num');
		if( $joint_num == 0 || $joint_num == 1 )
		{
			$u->{add_data}{places} ||= [0, 0];
			$target = $u->{add_data}{places};
			$old_place_id = int $target->[$joint_num];
			$target->[$joint_num] = $place_id;
			$x = $joint_num ? $u->{x0} + $u->{xb} : $u->{x} + $u->{xa};
			$y = $joint_num ? $u->{y0} + $u->{yb} : $u->{y} + $u->{yb};
		}
		elsif( $joint_num > 1 && $joint_num < scalar(@{$u->{joints}}) + 2 )
		{
			$target = $u->{joints}[$joint_num-2];
			$old_place_id = int $target->{place_id};
			$target->{place_id} = $place_id;
			$x = $target->{x};
			$y = $target->{y};
		}
	}
	elsif( $u->{grp} )
	{
		$u->{grp} = 0;
		$u->save(['data_changing_of', 'of_'.$u->{type}]);
		return 'reload';
	}
	else
	{
		$target = $u;
		$old_place_id = $u->{place_id};
		$u->{place_id} = $place_id;
		$x = $u->{x};
		$y = $u->{y};
	}

	my $res = { old_place_id => $old_place_id };
	if( $target )
	{
		if( !$place_id && $old_place_id )
		{
			my $container = Fibers::Units::Frame->get_by_id($old_place_id, { without_transaction=>1, no_api_error=>1 });
			if( $container && $container->{type} eq 'container' )
			{
				$container->{x} = $x;
				$container->{y} = $y;
				$container->save('', {no_commit=>1, heap_history=>1});
				$res->{container} = $container->all_tied_units_data();
			}
		}

		$u->save([$place_id ? 'moving_into_container' : 'removing_from_container']);
	}

	$res->{data} = $u->all_tied_units_data();
	return $res;
}

sub move_into_container
{
	my($scheme_id, $id) = @_;
	my $place_id = ses::input_int('place_id');
	return _in_out_container($scheme_id, $id, $place_id);
}

sub remove_from_container
{
	my($scheme_id, $id) = @_;
	return _in_out_container($scheme_id, $id, 0);
}

sub frame_change_type
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	# $u->{type} eq 'switch' && ApiError('Type error');

	my $type = ses::input('type');
	$type =~ /^(panel|coupler|splitter|box|fbt|onu|empty)$/ or ApiError('Type error');

	$u->{type} = $type;
	$u->save('type_changing', { no_need_dumps_in_history=>1 });
	return $u->data();
}

sub multimove
{
	my($scheme_id) = @_;
	my $data = from_json(ses::input('data'));
	ref $data eq 'ARRAY' or _data_error();

	my $act_to_method = {
		frame_position => { method => 'change_position', pkg => 'Fibers::Units' },
		cable_joint_position => { method => 'joint_change_position', pkg => 'Fibers::Units' },
		link_joint_position => { method => 'joint_change_position', pkg => 'Fibers::Links' },
	};

	my $is_map_view = ses::input('fibers_mode') eq 'map';
	my %history = ();
	my %id_to_unit = ();

	Db->begin_work or _db_error();

	foreach my $d( @$data )
	{
		ref $d eq 'HASH' or _data_error($d);
		my $id = int $d->{id};
		$id <= 0 && _data_error();

		my $act = $d->{act};
		exists $act_to_method->{$act} or _data_error();
		my $method = $act_to_method->{$act}{method};

		my $u = $id_to_unit{$id} || $act_to_method->{$act}{pkg}->get_by_id($id, {without_transaction=>1});
		$u->{removed} && _reload_page();

		my @fields = ( 'tied', 'x', 'y', 'x0', 'y0', 'joints' );
		my $u_copy = $u->data();
		my %back = map{ $u->full_field_name($_) => $u_copy->{$_} } grep{ exists $u_copy->{$_} } @fields;

		$u->$method(int $d->{x}, int $d->{y}, int $d->{joint_num}, $is_map_view);

		my $u_copy = $u->data();
		my %forward = map{ $u->full_field_name($_) => $u_copy->{$_} } grep{ exists $u_copy->{$_} } @fields;

		$id_to_unit{$id} = $u;
		$history{$id} ||= { back => \%back };
		$history{$id}{forward} = \%forward;
	}

	my @sqls = ();
	my $history = [];
	foreach my $u( values %id_to_unit )
	{
		my $id = $u->{id};
		push @sqls, @{$u->prepare_save_sqls()};
		push @$history, $u->make_history_fragment($history{$id}{back}, $history{$id}{forward});
	}

	my($ok);
	{
		foreach my $sql( @sqls )
		{
			Db->do(@$sql);
			Db->ok or last;
		}
		Db->ok or last;

		Fibers->create_history_record('multimoving', $history) or last;

		$ok = 1;
	}
	if( !$ok || !Db->commit )
	{
		Db->rollback;
		_db_error();
	}

	return get_all($scheme_id);
}

sub frame_position
{
	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $u = Fibers::Units::Frame->get_by_id($id);

	$u->change_position($x, $y);

	$u->save(['position_changing_of', 'of_'.$u->{type}], { no_need_dumps_in_history=>1 });
	return $u->data();
}

sub frame_size
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my($x, $y) = ses::input_int('x', 'y');

	my $iu = $u->{inner_units};
	my @iu = values %$iu;
	scalar @iu or return $u->data();

	my $box = $u->box_size();

	my $h = $box->{height};
	my $w = $box->{width};

	my $kh = $h ? ($h + $y)/$h : 1;
	my $kw = $w ? ($w + $x)/$w : 1;

	($w, $h) = check_xy($w, $h, $fibers__inner_xy_bounds, 1);
	defined $w or return $u->data();

	foreach my $i( @iu )
	{
		$i->{x} = ($i->{x} - $box->{x_min}) * $kw;
		$i->{y} = ($i->{y} - $box->{y_min}) * $kh;
	}

	$u->{x} += $box->{x_min};
	$u->{y} += $box->{y_min};

	$u->save(['size_changing_of', 'of_'.$u->{type}]);
	return $u->data();
}

sub frame_add_inner
{
	my($scheme_id, $id) = @_;
	my($x, $y) = check_xy(ses::input_int('x', 'y'), $fibers__inner_xy_bounds);
	my $type = ses::input('type');
	my $u = Fibers::Units::Frame->get_by_id($id);

	$u->{type} eq 'switch' && $type !~ /^(port)$/ && ApiError('Invalid type');
	$u->{type} ne 'switch' && $type !~ /^(connector|splitter|solder)$/ && ApiError('Invalid type');

	my $iu = $u->{inner_units};
	my $name = 1;
	foreach my $p( sort{ $a <=> $b } grep{ $_ > 0 } map{ int($_->{name}) } grep{ $_->{type} ne 'solder' }values %$iu )
	{
		$name > $p && next;
		$name++ == $p && next;
		$name--;
		last;
	}
	my $i = (sort{ $b <=> $a } keys %$iu)[0] + 1;
	if( $type eq 'splitter' && !exists $iu->{0} )
	{
		$iu->{0} = {
			i    => 0,
			name => '',
			x    => $x,
			y    => $y,
			type => $type,
		};
		$x += $inner_units_distance*2;
	}
	$iu->{$i} = {
		i    => $i,
		name => $name,
		x    => $x,
		y    => $y,
		type => $type,
	};
	if( $type eq 'splitter' && $u->inner_count('splitter') != 3 )
	{
		foreach my $i( values %$iu )
		{
			exists $i->{signal_ratio} && delete $i->{signal_ratio};
		}
	}
	$u->save(['inner_element_adding', $type]);
	return $u->data();
}

sub frame_inner_position
{
	my($scheme_id, $id) = @_;
	my $inner_id = ses::input_int('inner_id');
	my $u = Fibers::Units::Frame->get_by_id($id);
	my($x, $y) = ses::input_int('x', 'y');

	exists $u->{inner_units}{$inner_id} or _reload_page();
	my $inner = $u->{inner_units}{$inner_id};
	$inner->{x} = int($inner->{x} + $x);
	$inner->{y} = int($inner->{y} + $y);

	my($x0, $y0) = check_xy($inner->{x}, $inner->{y}, $fibers__inner_xy_bounds, 1);
	defined $x or return $u->data();

	map{ $inner->{$_} = ($inner->{$_} <=> 0) * $fibers__inner_xy_bounds->{$_} if abs($inner->{$_}) > $fibers__inner_xy_bounds->{$_} } ('x', 'y');

	$u->save(['inner_element_position_changing', 'of_'.$u->{type}]);
	return $u->data();
}

sub frame_remove
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units->get_by_id($id);
	$u->delete();
	return $u->{id};
}

sub frame_inner_remove
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my $inner_id = ses::input_int('inner_id');
	exists $u->{inner_units}{$inner_id} or _reload_page();
	$u->{inner_units}{$inner_id}{type} eq 'splitter' && $inner_id == 0 && ApiError('You cannot remove the main connector');
	my $res = $u->inner_remove($inner_id);

	return {
		inner_id => $inner_id,
		data => $u->data(),
		parent_removed => $res == 2,
	};
}

sub frame_inner_data
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id, { without_transaction=>1, maybe_other_scheme=>1 });
	my $inner_id = ses::input_int('inner_id');
	exists $u->{inner_units}{$inner_id} or _reload_page();
	my $inner_unit = $u->{inner_units}{$inner_id};
	my $res = {
		id => $id,
		inner_id => $inner_id,
		name => $inner_unit->{name},
		description => $inner_unit->{description},
		remote_id => $inner_unit->{remote_id}.'',
	};

	{	# connection type && signal ratio (40%/60%)
		$u->{type} eq 'switch' && last;
		$inner_unit->{type} ne 'splitter' && last;
		if( !$inner_id )
		{
			$res->{con_type} = $inner_unit->{con_type} || 'cc';
			last;
		}
		$u->inner_count('splitter') == 3 or last;
		$res->{signal_ratio} = int($inner_unit->{signal_ratio}) || 50;
	}
	return $res;
}

sub frame_inner_data_save
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my $inner_id = ses::input_int('inner_id');
	exists $u->{inner_units}{$inner_id} or _reload_page();
	my $inner_unit = $u->{inner_units}{$inner_id};
	my $old_remote_id = $inner_unit->{remote_id}.'';
	my %fl = %Fibers::Units::fields_lengths;
	foreach my $field( 'name', 'description', 'remote_id' )
	{
		ses::input_exists($field) or next;
		$inner_unit->{$field} = substr(ses::input($field), 0, $fl{"inner__$field"});
	}

	{	# connection type && signal ratio
		$u->{type} eq 'switch' && last;
		$inner_unit->{type} ne 'splitter' && last;
		if( !$inner_id )
		{
			my $con_type = ses::input('con_type');
			if( $con_type =~ /^(ss|sc|cs)$/ )
			{
				$inner_unit->{con_type} = $con_type;
			}
			 elsif( exists $inner_unit->{con_type} )
			{	# cc is default value, do not save
				delete $inner_unit->{con_type};
			}
			last;
		}
		my @splitter_connectors = grep{ $_->{type} eq 'splitter' } values %{$u->{inner_units}};
		scalar @splitter_connectors == 3 or last;
		my $signal_ratio = ses::input_int('signal_ratio');
		$signal_ratio = 50 if $signal_ratio <=0 || $signal_ratio >= 100;
		foreach my $iu( @splitter_connectors )
		{
			my $iid = int $iu->{i} or next;
			my $sr = $iid == $inner_id ? $signal_ratio : 100 - $signal_ratio;
			if( $sr == 50 ) {
				exists $iu->{signal_ratio} && delete $iu->{signal_ratio};
			} else {
				$iu->{signal_ratio} = $sr;
			}
		}
	}

	my $action = ['inner_element_data_changing_of', 'of_'.$u->{type}];

	my $remote_id = v::trim(ses::input('remote_id'));
	if( $remote_id ne $old_remote_id && 0 )
	{
		$u->save($action, {no_commit=>1, heap_history=>1});
		Db->do(
			'INSERT INTO fibers_inner_units SET scheme_id=?, unit_id=?, inner_id=?, remote_id=? '.
			'ON DUPLICATE KEY UPDATE remote_id=? ',
			$scheme_id, $id, $inner_id, $remote_id, $remote_id
		);
		my %p = Db->line(
			'SELECT id FROM fibers_inner_units WHERE scheme_id=? AND unit_id=? AND inner_id=?',
			$scheme_id, $id, $inner_id
		);
		if( %p )
		{
			push @$Fibers::History, {
				table	=> 'fibers_inner_units',
				id		=> $p{id},
				back	=> { remote_id=>$old_remote_id },
				forward	=> { remote_id=>$remote_id },
			};
		}
		Fibers->create_history_record($action, $Fibers::History) or _db_error();
		if( !Db->commit )
		{
			Db->rollback;
			_db_error();
		}
	}
	 else
	{
		$u->save($action);
	}

	return $u->data();
}

sub _frame_inner_align
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);

	my $dy = $inner_units_distance;
	my $dx = int($inner_units_distance * 1.5);

	my %iu = %{$u->{inner_units}};
	keys %iu or return $u;

	my $j = 0;
	my $side = 1;
	while( ++$j < 100 && keys %iu )
	{
		my $x = (sort{ ($a <=> $b) * $side } map{ $_->{x} } values %iu)[0];
		foreach my $i( keys %iu )
		{
			if( ($side > 0 && $iu{$i}{x} < ($x + $dx)) ||
				($side < 0 && $iu{$i}{x} > ($x - $dx)) )
			{
				$u->{inner_units}{$i}{x} = $x;
				delete $iu{$i};
			}
		}
		$side *= -1;
	}

	my %iu = %{$u->{inner_units}};
	my @iu = values %iu;
	my @y = map{ $_->{y} } @iu;
	my $min_y = (sort{ $a <=> $b } @y)[0];
	my $max_y = (sort{ $b <=> $a } @y)[0];
	my $j = 0;
	my $last_y = $min_y - $dy - 100;
	while( ++$j < 100 && keys %iu )
	{
		my $y = (sort{ $a <=> $b } map{ $_->{y} } values %iu)[0];
		$y = $last_y + $dy if $y < $last_y + $dy;
		my $y0 = $y + $dy/2;
		foreach my $i( keys %iu )
		{
			if( $iu{$i}{y} < $y0 )
			{
				$u->{inner_units}{$i}{y} = $y;
				delete $iu{$i};
			}
		}
		$last_y = $min_y;
	}

	if( $j > 2 )
	{
		my $delta_y = ($max_y - $min_y) / ($j - 2);
		$delta_y = $dy if $delta_y < $dy;
		my $last_y = $min_y;
		my $y = 0;
		foreach my $i( sort{ $a->{y} <=> $b->{y} } @iu )
		{
			if( $last_y != $i->{y} )
			{
			  $y += $delta_y;
			  $last_y = $i->{y};
			}
			$i->{y} = $y;
		}

		my @x = do{ my %seen; grep{ !$seen{$_}++ } map{ $_->{x} } sort{ $a->{x} <=> $b->{x} } @iu };
		my @y = do{ my %seen; grep{ !$seen{$_}++ } map{ $_->{y} } sort{ $a->{y} <=> $b->{y} } @iu };

		my $ii = scalar(@x) - 1;
		my $jj = scalar(@y) - 1;

		my %same_pos = ();
		foreach my $u( @iu )
		{
			my($i) = grep { $x[$_] == $u->{x} } (0 .. $ii);
			my($j) = grep { $y[$_] == $u->{y} } (0 .. $jj);
			$same_pos{"$i:$j"} ||= [];
			push @{$same_pos{"$i:$j"}}, $u;
		}

		foreach my $i( 1..50 ) { push @y, $max_y + $i * $dy; }

		foreach my $j( 0 .. $jj )
		{
			foreach my $i( 0 .. $ii )
			{
				exists $same_pos{"$i:$j"}  or next;
				my $sp = $same_pos{"$i:$j"};
				while( scalar(@$sp) > 1 )
				{
					my $u = shift @$sp;
					my $i0 = $i;
					my $j0 = $j;
					{
						$j0--;
						$j0 >= 0 && !$same_pos{"$i0:$j0"} && last;
						$j0++;
						$i0++;
						$i0 <= $ii && !$same_pos{"$i0:$j0"} && last;
						$i0--;
						$j0++;
						while( exists $same_pos{"$i0:$j0"} ) { $j0++; }
						while( $j0 > $j )
						{
						  my $sp0 = $same_pos{"$i0:".($j0-1)};
						  delete $same_pos{"$i0:".($j0-1)};
						  $same_pos{"$i0:$j0"} = $sp0;
						  foreach my $u0( @$sp0 )
						  {
						      $u0->{y} = $y[$j0];
						  }
						  $j0--;
						}
					}
					$u->{x} = $x[$i0];
					$u->{y} = $y[$j0];
					$same_pos{"$i0:$j0"} = [$u];
				}
			}
		}

	}
	return $u;
}

sub frame_inner_align
{
	my($scheme_id, $id) = @_;
	my $u = _frame_inner_align($scheme_id, $id);
	$u->save('inner_elements_aligning');
	return $u->data();
}

sub frame_inner_align_grid
{
	my($scheme_id, $id) = @_;
	my $u = _frame_inner_align($scheme_id, $id);
	my $dy = $inner_units_distance;
	my $dx = int($inner_units_distance * 1.5);
	my @iu = values %{$u->{inner_units}};
	foreach my $i( @iu )
	{
		$i->{x} = int($i->{x}/$dx) * $dx;
		$i->{y} = int($i->{y}/$dy) * $dy;
	}
	my $last_y = -1000;
	my $y = -$dy;
	foreach my $i( sort{ $a->{y} <=> $b->{y} } @iu )
	{
		if( $last_y != $i->{y} )
		{
			$y += $dy;
			$last_y = $i->{y};
		}
		$i->{y} = $y;
	}
	$u->save('inner_elements_aligning');
	return $u->data();
}

sub frame_inner_align_connected
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my $iu = $u->{inner_units};
	my @iu = values %$iu;
	scalar @iu or return $u->data();
	my $db = Db->sql('SELECT src, src_inner, dst_inner FROM fibers_links WHERE removed=0 AND (src=? OR dst=?)', $id, $id);
	my %connected = ();
	while( my %p = $db->line )
	{
		$connected{$p{src} == $id ? $p{src_inner} : $p{dst_inner}} = 1;
	}
	my $y0 = 0;
	my $y1 = 0;
	my $x0 = 0;
	my $x1 = $inner_units_distance;
	my $box = $u->box_size();
	my $y_min = $box->{y_min};
	my $x_min = $box->{x_min};
	foreach my $i( sort{ $iu->{$a}{y} <=> $iu->{$b}{y} } keys %$iu )
	{
		my($x, $y) = $connected{$i} ? ($x0, $y0++) : ($x1, $y1++);
		$iu->{$i}{x} = $x_min + $x;
		$iu->{$i}{y} = $y_min + $y * $inner_units_distance;
	}
	$u->{x} += int(($box->{x_max} - $x_min - $inner_units_distance)/2);
	$u->save('inner_elements_aligning');
	return $u->data();
}

sub frame_inner_align_lr
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my $iu = $u->{inner_units};
	keys %$iu or return $u->data();

	my $sql = <<SQL;
	SELECT l.src_inner AS inner_id, IF(IF(l.dst_side=1, u.x0+c.xb, u.x+c.xa) > ?, 1, -1) AS dir
	FROM fibers_links l JOIN fibers_units u ON l.dst=u.id JOIN fibers_cables c ON u.tied=c.id WHERE l.removed=0 AND l.src=?
	    UNION
	SELECT l.dst_inner AS inner_id, IF(IF(l.src_side=1, u.x0+c.xb, u.x+c.xa) > ?, 1, -1) AS dir
	FROM fibers_links l JOIN fibers_units u ON l.src=u.id JOIN fibers_cables c ON u.tied=c.id WHERE l.removed=0 AND l.dst=?
SQL
	my $db = Db->sql($sql, $u->{x}, $id, $u->{x}, $id);
	my %dir = ();
	while( my %p = $db->line )
	{
		$dir{$p{inner_id}} += $p{dir};
	}

	my $x_distance = int($inner_units_distance * 1.5);

	my($any_on_center, $any_on_right, $any_on_left) = (0, 0, 0);
	foreach my $i( keys %$iu )
	{
		$any_on_center++ if !$dir{$i};
		$any_on_right++ if $dir{$i} > 0;
		$any_on_left++ if $dir{$i} < 0;
	}

	my $xl = 0;
	my $xc = $any_on_left && $any_on_center ? $x_distance : 0;
	my $xr = $xc + ($any_on_right && ($any_on_left || $any_on_center) ? $x_distance : 0);
	my($yl, $yc, $yr) = (0, 0, 0);

	my $m = $u->box_size();
	my $y_min = $m->{y_min};
	my $x_min = $m->{x_min};

	foreach my $i( sort{ $iu->{$a}{y} <=> $iu->{$b}{y} } keys %$iu )
	{
		if( !$i )
		{
			$iu->{$i}{x} = -$inner_units_distance;
			$iu->{$i}{y} = $y_min;
			next;
		}
		my($x, $y) = $dir{$i} < 0 ? ($xl, $yl++) : $dir{$i} > 0 ? ($xr, $yr++) : ($xc, $yc++);
		$iu->{$i}{x} = $x;
		$iu->{$i}{y} = $y_min + $y * $inner_units_distance;
	}

	$u->{x} = int((2*$u->{x} + $m->{x_min} + $m->{x_max} - $xr)/2);
	$u->save('inner_elements_aligning');
	return $u->data();
}

sub frame_rotate
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my $iu = $u->{inner_units};
	my @iu = values %$iu;
	scalar @iu or return $u->data();
	my $box = $u->box_size();
	my $center_x = int($box->{x_min} + $box->{x_max})/2;
	my $center_y = int($box->{y_min} + $box->{y_max})/2;
	foreach my $i( keys %$iu )
	{
		($iu->{$i}{x}, $iu->{$i}{y}) = ($center_x-$iu->{$i}{y}+$center_y, $center_y+$iu->{$i}{x}-$center_x);
	}
	$u->save(['rotating_of', 'of_'.$u->{type}]);
	return $u->data();
}


# --- Cable ---

sub cable_create
{
	my($scheme_id) = @_;
	my($xa, $ya) = ses::input_int('x', 'y');
	my $fibers_count = ses::input_int('fibers_count');
	my $multimode = ses::input_int('multimode');
	my $color_preset_id = ses::input_int('color_preset_id');
	return _cable_create($scheme_id, $xa, $ya, $fibers_count, $multimode, $color_preset_id, $CABLE_CREATE_WIDTH, 0);
}

sub _cable_create
{
	my($scheme_id, $xa, $ya, $fibers_count, $multimode, $color_preset_id, $cable_width, $cable_height, $create_params) = @_;
	($xa, $ya) = check_xy($xa, $ya);

	($fibers_count <= 0 || $fibers_count > 100) && ApiError('Fibers count error');
	($multimode <= 0 || $multimode > 8) && ApiError('Multimode count error');

	my($xb, $yb) = ($multimode > 1 ? $xa+2*$cable_width : $xa+$cable_width, $ya + $cable_height);
	my $offset = int($fiber_tips_distance * (($fibers_count-0.5)/2 - 0.25));
	my $add_data = {
		rotate => [0, 0],
		collapsed_coord => $fibers_count > 1 ? [$offset, $offset] : [0, 0],
		places => [0, 0],
	};

	my %p = Db->line('SELECT colors FROM fibers_colors_presets WHERE id=?', $color_preset_id);
	%p or ApiError('Color preset not found');

	my @colors = split /,/, $p{colors};
	my $offset = 0;
	my $inner = {};
	foreach my $i( 1..$fibers_count )
	{
		$inner->{$i} = {
			i      => $i,
			offset => [ $offset, $offset ],
			color  => $colors[$i-1],
		};
		$offset += $fiber_tips_distance;
	}

	my $data = {
		cls  => 'cable',
		type => '',
		name => '',
		x    => $xa,
		y    => $ya,
		x0   => $xb,
		y0   => $yb,
		xa   => 0,
		ya   => 0,
		xb   => 0,
		yb   => 0,
		grp    => 0,
		img    => '',
		place_id    => 0,
		description => '',
		scheme_id   => $scheme_id,
		inner_units => $inner,
		add_data    => $add_data,
		joints      => $multimode < 2 ? [] : [ { x => $xa+45, y => $ya-60 }, { x => $xb-15, y => $yb-60 } ],
	};
	my $u;
	my $res = [];
	my $half_distance = int($fiber_tips_distance/2);
	while( $multimode )
	{
		$u = Fibers::Units->create($data, 'cable_creating', $create_params);
		push @$res, $u->data();
		$data->{tied} = $u->{tied};
		$data->{x} += $half_distance;
		$data->{y} += $fiber_tips_distance;
		$data->{x0} += $half_distance;
		$data->{y0} += $fiber_tips_distance;
		$multimode--;
	}
	return $res;
}

sub cable_data
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id, {without_transaction=>1});
	my $trunks = [];
	my $name_field = $cfg::Lang eq 'RU' ? 'name_ru' : 'name_uk';
	my $db = Db->sql('SELECT id, name_ru, name_uk, comment FROM fibers_trunks WHERE scheme_id=?', $scheme_id);
	while( my %p = $db->line )
	{
		$p{name} = $p{$name_field};
		delete $p{name_ru};
		delete $p{name_uk};
		push @$trunks, \%p;
	}
	my $map_types = [];
	my $sql_end = $cfg::fibers_collective_data ? '' : 'WHERE scheme_id='.int($scheme_id);
	my $db = Db->sql("SELECT * FROM fibers_cable_types $sql_end");
	while( my %p = $db->line )
	{
		push @$map_types, \%p;
	}
	my $res = {
		id => $id,
		name => $u->{name},
		description => $u->{description},
		length => $u->{length},
		trunk => $u->{trunk},
		trunks => $trunks,
		map_type => $u->{map_type},
		map_types => $map_types,
		nodeny_obj_id => $cfg::fibers_stock_enabled ? $u->{nodeny_obj_id} : 0,
	};
	return $res;
}

sub cable_data_save
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	my %fl = %Fibers::Units::fields_lengths;
	foreach my $field( 'name', 'description' )
	{
		ses::input_exists($field) or next;
		$u->{$field} = substr(ses::input($field), 0, $fl{$field});
	}

	if( ses::input_exists('length') )
	{
		my $length = ses::input_int('length');
		$length < 0 && ApiError('length must be a positive number');
		$u->{length} = $length if $length <= 10000000;
	}

	if( ses::input_exists('trunk') )
	{
		my $trunk = ses::input_int('trunk');
		$trunk && !Db->line(
			'SELECT 1 FROM fibers_trunks WHERE id=? AND scheme_id=?', $trunk, $scheme_id
		) && ApiError('Trunk number error');
		$u->{trunk} = $trunk;
	}

	if( ses::input_exists('map_type') )
	{
		my $map_type = ses::input_int('map_type');
		my $sql_end = $cfg::fibers_collective_data ? '' : 'AND scheme_id='.int($scheme_id);
		$map_type && !Db->line(
			"SELECT 1 FROM fibers_cable_types WHERE id=? $sql_end", $map_type
		) && ApiError('Type number error');
		$u->{map_type} = $map_type;
	}

	if( ses::input_exists('nodeny_obj_id') && $cfg::fibers_stock_enabled )
	{
		my $nodeny_obj_id = ses::input_int('nodeny_obj_id');
		if( $nodeny_obj_id )
		{
			my $grp_ids = join ',', map{ int $_ } @cfg::fibers_stock_grp_ids_list;
			Db->line(
				"SELECT 1 FROM users WHERE grp IN($grp_ids) AND id=?", $nodeny_obj_id
			) or ApiError('Object not found in the stock');
			Db->line(
				"SELECT id FROM fibers_units WHERE nodeny_obj_id=? AND id<>? AND scheme_id=?",
				$nodeny_obj_id, $u->{id}, $scheme_id
			) && ApiError('Stock id is tied with another object');
		}
		$u->{nodeny_obj_id} = $nodeny_obj_id;
	}

	$u->save(['data_changing_of', 'of_cable']);
	return $u->all_tied_units_data();
}

sub cable_move
{
	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $u = Fibers::Units::Cable->get_by_id($id);

	if( ses::input_exists('side') )
	{
		my $side = ses::input_int('side');
		if( $side )
		{
			$u->{xb} += $x;
			$u->{yb} += $y;
			check_xy($u->{x0} + $u->{xb}, $u->{y0} + $u->{yb});
			$u->{joints}[-1]{x} += $x;
			$u->{joints}[-1]{y} += $y;
		}
		else
		{
			$u->{joints}[0]{x} += $x;
			$u->{joints}[0]{y} += $y;
		}
	}
	else
	{
		$u->change_position($x, $y);
	}

	$u->save(['position_changing_of', 'of_cable']);
	return $u->all_tied_units_data();
}

sub cable_cut
{
	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $joint_num = ses::input_int('joint_num');
	return _cable_cut($scheme_id, { id=>$id, x =>$x, y =>$y, joint_num=>$joint_num });
}

sub _cable_cut
{
	my($scheme_id, $params) = @_;
	my $id = $params->{id};
	my $x = $params->{x};
	my $y = $params->{y};
	my $joint_num = $params->{joint_num};
	my $gap = $params->{gap};
	my $create_params = $params->{create_params} || {};

	my($x, $y) = check_xy($x, $y);
	$joint_num < 1 && return get_all($scheme_id);
	$gap = 15 if $gap < 15;
	$gap = 300 if $gap > 300;

	my $u = Fibers::Units::Cable->get_by_id($id);
	$u->{add_data}{linked_scheme} ne '' && ApiError(L('First remove the link to the other scheme'));

	$u->{tied} && Db->line(
		"SELECT id FROM fibers_units WHERE id<>? AND tied=? AND removed=0",
		$id, $u->{tied}
	) && ApiError('Unable to cut a multimode cable');

	my $data = $u->data();
	$y -= int($fiber_tips_distance * scalar(keys %{$data->{inner_units}})/2) if !$params->{cable_end_joint_on_top};

	$u->{x0} = $x;
	$u->{y0} = $y;
	$u->{add_data}{rotate}[1] = 0;
	$u->{joints} = [];
	while( --$joint_num && scalar @{$data->{joints}} )
	{
		push @{$u->{joints}}, shift @{$data->{joints}};
	}
	$u->{add_data}{collapsed_coord}[1] = 0 if $params->{cable_end_joint_on_top};

	$data->{x} = $x + $gap;
	$data->{y} = $y;
	$data->{add_data}{rotate}[0] = 0;
	$data->{tied} = 0;
	$data->{nodeny_obj_id} = 0;
	$data->{length} = 0;
	$data->{add_data}{collapsed_coord}[0] = 0 if $params->{cable_end_joint_on_top};

	my $new_u = Fibers::Units->create($data, 'cable_creating', {
	  no_commit=>1, heap_history=>1, without_transaction=>1
	});
	my $new_id = $new_u->{id};

	my $db = Db->sql('SELECT id FROM fibers_links WHERE removed=0 AND src=? AND src_side=1', $id);
	while( my %p = $db->line )
	{
		push @$Fibers::History, {
			table   => 'fibers_links',
			id      => $p{id},
			back    => { src=>$id },
			forward => { src=>$new_id },
		};
	}
	my $db = Db->sql('SELECT id FROM fibers_links WHERE removed=0 AND dst=? AND dst_side=1', $id);
	while( my %p = $db->line )
	{
		push @$Fibers::History, {
			table   => 'fibers_links',
			id      => $p{id},
			back    => { dst=>$id },
			forward => { dst=>$new_id },
		};
	}

	my($ok);
	{
		Db->sql(
			'UPDATE fibers_links SET src=? WHERE removed=0 AND scheme_id=? AND src=? AND src_side=1',
			  $new_id, $u->{scheme_id}, $id
		);
		Db->ok or last;
		Db->sql(
			'UPDATE fibers_links SET dst=? WHERE removed=0 AND scheme_id=? AND dst=? AND dst_side=1',
			  $new_id, $u->{scheme_id}, $id
		);
		Db->ok or last;

		$u->save('', {no_commit=>1, heap_history=>1});

		Fibers->create_history_record(['cable_cutting'], $Fibers::History) or last;

		$ok = 1;
	}

	if( !$create_params->{no_commit} && (!$ok || !Db->commit) )
	{
		Db->rollback;
		_db_error();
	}

	$create_params->{return_cables} && return($u, $new_u);
	return get_all($scheme_id);
}

sub cable_joint_add
{
	my($scheme_id, $id) = @_;
	my($x, $y) = check_xy(ses::input_int('x', 'y'));
	my $joint_num = ses::input_int('joint_num');
	my $u = Fibers::Units::Cable->get_by_id($id);

	$joint_num > 0 or return $u->all_tied_units_data();

	my $data = { x => $x, y => $y };
	$data->{subtype} = 'only_map' if ses::input('fibers_mode') eq 'map';
	splice(@{$u->{joints}}, $joint_num-1, 0, $data);
	$u->save('cable_joint_adding');
	return $u->all_tied_units_data();
}

sub cable_joint_position
{
	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $joint_num = ses::input_int('joint_num');
	my $u = Fibers::Units::Cable->get_by_id($id);
	my $is_map_view = ses::input('fibers_mode') eq 'map';

	$u->joint_change_position($x, $y, $joint_num, $is_map_view);

	$u->save(['position_changing_of', 'of_cable_joint']);
	return $u->all_tied_units_data();
}

sub cable_end_joint_slide
{
	my($scheme_id, $id) = @_;
	my $delta = ses::input_int('delta');
	my $side = ses::input_int('side');
	my $u = Fibers::Units::Cable->get_by_id($id);

	$side = !$side ? 0 : 1;
	(!$delta || abs($delta) > 1000) && return $u->data();

	$u->{add_data}{collapsed_coord} ||= [0, 0];
	$u->{add_data}{collapsed_coord}[$side] += $delta;

	$u->save('cable joint moving');
	return $u->all_tied_units_data();
}

sub cable_joint_align
{
	my($scheme_id, $id) = @_;
	my $joint_num = ses::input_int('joint_num');
	my $type = ses::input('type');
	$type =~ /^(x|y)$/ or ApiError(L('Align type error'));
	my $u = Fibers::Units::Cable->get_by_id($id);

	my $add_data = $u->{add_data};
	my $rotate = $add_data->{rotate};
	my $joints = $u->{joints};
	my $joints_count = scalar @$joints;

	if( $joints_count )
	{
		my $side = $joint_num <= 1 ? 0 : $joint_num >= $joints_count+1 ? 1 : -1;
		my $d = ($type eq 'x' && $rotate->[$side] > 1) ||
		      ($type eq 'y' && $rotate->[$side] < 2) ? $add_data->{collapsed_coord}[$side] : 0;
		if( $side == 0 )
		{
			$joints->[0]{$type} = $d + ($type eq 'x' ? $u->{x} + $u->{xa} : $u->{y} + $u->{ya});
		}
		 elsif( $side == 1 )
		{
			$joints->[$joints_count-1]{$type} = $d + ($type eq 'x' ? $u->{x0} + $u->{xb} : $u->{y0} + $u->{yb});
		}
		 else
		{
			$joints->[$joint_num-1]{$type} = $joints->[$joint_num-2]{$type};
		}
	}
	 else
	{
		if( int($rotate->[0]/2) == int($rotate->[1]/2) )
		{
			my $d = $type eq 'x'
			      ? $u->{x} + $u->{xa} - $u->{x0} - $u->{xb}
			      : $u->{y} + $u->{ya} - $u->{y0} - $u->{yb};
			$add_data->{collapsed_coord}[1] = $add_data->{collapsed_coord}[0] + $d;
		}
		 elsif( $rotate->[0] < 2 )
		{
			push @$joints, { x => $u->{x0} + $add_data->{collapsed_coord}[1], y => $add_data->{collapsed_coord}[0] };
		}
		 else
		{
			push @$joints, { x => $u->{x} + $add_data->{collapsed_coord}[0], y => $u->{y0} + $add_data->{collapsed_coord}[1] };
		}
	}

	$u->save('cable aligning');
	return $u->all_tied_units_data();
}

sub cable_joint_remove
{
	my($scheme_id, $id) = @_;
	my $joint_num = ses::input_int('joint_num');
	my $u = Fibers::Units::Cable->get_by_id($id);

	$joint_num > 1 or return $u->all_tied_units_data();

	splice(@{$u->{joints}}, $joint_num-2, 1);

	$u->save('cable joint removing');
	return $u->all_tied_units_data();
}

sub cable_joint_data
{
	my($scheme_id, $id) = @_;
	my $joint_num = ses::input_int('joint_num') - 2;
	my $u = Fibers::Units::Cable->get_by_id($id, {without_transaction=>1});
	($joint_num < 0 || $joint_num >= scalar @{$u->{joints}}) && ApiError('Joint number error');
	my $joint = $u->{joints}[$joint_num];
	return {
		id => $id,
		joint_num => $joint_num + 2,
		coil => int($joint->{coil}) || '',
	}
}

sub cable_joint_data_save
{
	my($scheme_id, $id) = @_;
	my $joint_num = ses::input_int('joint_num') - 2;
	my $u = Fibers::Units::Cable->get_by_id($id);
	($joint_num < 0 || $joint_num >= scalar @{$u->{joints}}) && ApiError('Joint number error');
	my $joint = $u->{joints}[$joint_num];
	if( ses::input_exists('coil') )
	{
		my $coil_length = ses::input_int('coil');
		$coil_length < 0 && ApiError('length must be a positive number');
		if( $coil_length == 333 )
		{
			$joint->{subtype} = 'only_map';
		} else {
			$joint->{coil} = $coil_length;
		}
		$u->save(['data_changing_of', 'of_cable_joint']);
	}
	return {};
}

sub cable_remove_all_joints
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	$u->{joints} = [];
	$u->save('cable joints removing');
	return $u->all_tied_units_data();
}

sub cable_rotate_edge
{
	my($scheme_id, $id) = @_;
	my $side = ses::input_int('side');
	my $u = Fibers::Units::Cable->get_by_id($id);
	$side = !$side ? 0 : 1;
	my $rotations = { 0=>2, 2=>0 }; # { 0=>2, 2=>1, 1=>3, 3=>0 }
	$u->{add_data}{rotate}[$side] = int($rotations->{$u->{add_data}{rotate}[$side]});
	$u->save('cable rotation');
	return $u->all_tied_units_data();
}

sub cable_remove
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	$u->{add_data}{linked_scheme} ne '' && ApiError(L('Cannot remove a linked cable'));
	$u->delete('cable removing');
	return $u->{id};
}

sub cable_change_color
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	my $color = ses::input_int('color');
	my $fiber_id = ses::input_int('fiber_id');
	if( exists $u->{inner_units}{$fiber_id} )
	{
		$u->{inner_units}{$fiber_id}{color} = $color;
		$u->save('fiber color changing');
	}
	return $u->all_tied_units_data();
}

sub cable_fibers_move
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	my $fiber_id = ses::input_int('fiber_id');
	my $side = ses::input_int('side');
	my $delta = ses::input_int('delta');

	(!$delta || abs($delta) > 1000) && return $u->data();
	exists $u->{inner_units}{$fiber_id} or return $u->data();

	my $fiber = $u->{inner_units}{$fiber_id};
	$side = 1 if $side;

	my $iu = $u->{inner_units};
	map{ $_->{offset} = [ 0, 0 ] } grep{ !exists $_->{offset} || ref $_->{offset} ne 'ARRAY' } values %$iu;

	my $offset = $fiber->{offset}[$side];
	my $target_offset = $offset + $delta;
	my $prev_offset = $target_offset;
	if( ses::input('act') eq 'cable_fibers_order' )
	{
		$fiber->{offset}[$side] = $target_offset;
		$offset = $prev_offset = -500;
		$delta = 1;
	}
	if( $delta > 0 )
	{
		foreach my $i( sort{ $a->{offset}[$side] <=> $b->{offset}[$side] } grep{ $_->{offset}[$side] > $offset } values %$iu )
		{
			$i->{offset}[$side] = $prev_offset + $fiber_tips_distance  if ($prev_offset + $fiber_tips_distance) > $i->{offset}[$side];
			$prev_offset = $i->{offset}[$side];
		}
	}
	else
	{
		foreach my $i( sort{ $b->{offset}[$side] <=> $a->{offset}[$side] } grep{ $_->{offset}[$side] < $offset } values %$iu )
		{
			$i->{offset}[$side] = $prev_offset - $fiber_tips_distance if ($prev_offset - $fiber_tips_distance) < $i->{offset}[$side];
			$prev_offset = $i->{offset}[$side];
		}
	}
	$fiber->{offset}[$side] = $target_offset if ses::input('act') ne 'cable_fibers_order';
	$u->save('cable fiber position shift');

	return $u->all_tied_units_data();
}

sub cable_fiber_add
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	$u->{add_data}{linked_scheme} ne '' && ApiError(L('Cannot add a fiber to a linked cable'));
	my $i = ( sort{ $b <=> $a } keys %{$u->{inner_units}} )[0] + 1;
	my $of = sub{ my $side = shift; return ( sort{ $b <=> $a } map{ $_->{offset}[$side] } values %{$u->{inner_units}} )[0] + $fiber_tips_distance; };
	$u->{inner_units}{$i} = {
		i => $i,
		color => 1,
		offset => [ $of->(0), $of->(1) ],
	};
	$u->save('cable fiber adding');
	return $u->all_tied_units_data();
}

sub cable_fiber_remove
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	$u->{add_data}{linked_scheme} ne '' && ApiError(L('Cannot remove a fiber from a linked cable'));
	$u->inner_remove(ses::input_int('fiber_id'));
	return {};
}

sub cable_link_with_scheme
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	return {
		cable_ref => $Scheme_data->{gid}.':'.$id,
		id => $id,
		linked_scheme => $u->{add_data}{linked_scheme},
	}
}

sub cable_link_with_scheme_save
{
	my($scheme_id, $id) = @_;
	my $scheme_gid = $Scheme_data->{gid};
	my $cable = Fibers::Units::Cable->get_by_id($id);
	my $new_linked_scheme = v::trim(ses::input('linked_scheme'));

	my $linked_scheme = $cable->{add_data}{linked_scheme};

	{   # Remove the backward link if the current link is removing or changing

		$linked_scheme or last;
		my($linked_scheme_gid, $linked_cable_id) = split /:/, $linked_scheme;

		# Do not check access because we remove link to OUR scheme
		my %p = Db->line('SELECT id FROM fibers_schemes WHERE gid=?', $linked_scheme_gid);
		%p or last;  # incorrect linked_scheme reference
		my $linked_scheme_id = $p{id};
		my $linked_cable = Fibers::Units::Cable->get_by_id(
			$linked_cable_id, { scheme_id=>$linked_scheme_id, without_transaction=>1, no_api_error=>1 }
		);
		$linked_cable or last;  # no unit or unit is not a cable
		$linked_cable->{add_data}{linked_scheme} eq $scheme_gid.':'.$id or last;  # backward link is empty or incorrect

		$linked_cable->{add_data}{linked_scheme} = '';
		$linked_cable->save('', { no_commit=>1, no_history=>1 });
	}

	if( !$new_linked_scheme )
	{
		$cable->{add_data}{linked_scheme} = '';
		$cable->save('', { no_history=>1 });
		return $cable->all_tied_units_data();
	}

	my($linked_scheme_gid, $linked_cable_id) = split /:/, $new_linked_scheme;
	$linked_scheme_gid eq $scheme_gid && ApiError(L('The cable to be connected to must be on a other scheme'));

	my %p = Db->line(
		'SELECT s.id, s.uid, s.shared FROM fibers_units u JOIN fibers_schemes s ON u.scheme_id=s.id '.
		'WHERE s.is_block=0 AND u.id=? AND s.gid=?', $linked_cable_id, $linked_scheme_gid
	);
	Db->ok or _db_error();
	%p or ApiError('Scheme not found');
	!$p{shared} && $p{uid} != $Uid && ApiError(L('Access denied'));
	my $linked_scheme_id = $p{id};

	my $linked_cable = Fibers::Units::Cable->get_by_id(
		$linked_cable_id, { scheme_id=>$linked_scheme_id, without_transaction=>1, no_api_error=>1 }
	);
	$linked_cable or ApiError('Target cable not found');
	my $linked_scheme = $linked_cable->{add_data}{linked_scheme};

	$linked_scheme && ($linked_scheme ne $scheme_gid.':'.$id) && ApiError('Target cable is linked with other cable');
	(scalar keys %{$linked_cable->{inner_units}}) != (scalar keys %{$cable->{inner_units}})
		&& ApiError(L('Target cable has a different number of fibers'));

	$linked_cable->{add_data}{linked_scheme} = $scheme_gid.':'.$id;
	$cable->{add_data}{linked_scheme} = $linked_scheme_gid.':'.$linked_cable_id;

	my $length = int($cable->{length}) || int($linked_cable->{length});
	$cable->{length} = $linked_cable->{length} = $length if $length;

	$linked_cable->save('', { no_commit=>1, no_history=>1 });
	$cable->save('', { no_history=>1 });

	return $cable->all_tied_units_data();
}

sub cable_goto_linked_scheme
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id);
	my($gid, $u_id) = split /:/, $u->{add_data}{linked_scheme};
	return {
		gid => $gid,
		id  => $u_id,
	};
}

sub cable_find_break
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Cable->get_by_id($id, {without_transaction=>1});
	my $cable_length = $u->{length};
	$cable_length > 0 or ApiError(L('Cable length is not specified'));
	my $cable_break = ses::input_int('break');
	$cable_break > 0 or ApiError(L('Break distance is not specified'));
	$cable_break > $cable_length && ApiError('Відстань до обрива більше за довжину кабелю');

	$u->{add_data}{places} ||= [0, 0];
	my $err_container = L('Cable ends must be in containers');
	my @gps = ();
	foreach my $i( 0..1 )
	{
		my $place_id = int $u->{add_data}{places}[$i];
		$place_id > 0 or ApiError($err_container);
		my $container = Fibers::Units::Frame->get_by_id($place_id, {without_transaction=>1});
		$container->{type} eq 'container' or ApiError('Internal error');
		$container->{removed} && ApiError($err_container);
		(!int($container->{lat}) || !int($container->{lng})) && ApiError('Контейнери, в які входять кінці кабелів, не розміщені на карті');
		push @gps, { lat=>$container->{lat}, lng=>$container->{lng} };
	}
	my $last_gps = pop(@gps);
	foreach my $i( @{$u->{joints}} )
	{
		my $place_id = int $i->{place_id};
		$place_id > 0 or next;
		my $container = Fibers::Units::Frame->get_by_id($place_id, {without_transaction=>1});
		$container->{type} eq 'container' or next;
		$container->{removed} && next;
		!$container->{lat} && !$container->{lng} && next;
		push @gps, { lat=>$container->{lat}, lng=>$container->{lng} };
	}
	push @gps, $last_gps;
	@gps = reverse @gps if ses::input_int('side');

	my @lengths = ();
	my $last_gps;
	my $gps_sum = 0;
	foreach my $gps( @gps )
	{
		if( $last_gps )
		{
			my $length = sqrt(($gps->{lat} - $last_gps->{lat})**2 + ($gps->{lng} - $last_gps->{lng})**2);
			push @lengths, $length;
			$gps_sum += $length;
		}
		$last_gps = $gps;
	}
	my $gps_length_break = $gps_sum * $cable_break / $cable_length;

	my $last_gps;
	my $segment = 0;
	foreach my $length( @lengths )
	{
		$gps_length_break < $length && last;
		$gps_length_break -= $length;
		$segment++;
	}

	my $segment_length = $lengths[$segment];
	my $k = $segment_length ? $gps_length_break / $segment_length : 0;
	my $gps1 = $gps[$segment];
	my $gps2 = $gps[$segment+1];
	my $lat = ($gps2->{lat} - $gps1->{lat})*$k + $gps1->{lat};
	my $lng = ($gps2->{lng} - $gps1->{lng})*$k + $gps1->{lng};

	my $res = main_get_all($scheme_id);
	$res->{set_marker} = {
		lat => $lat,
		lng => $lng,
	};
	return $res;
}

sub cable_insert_splitter
{
	my($scheme_id, $id) = @_;
	my $res = Fibers::Units::Cable->get_by_id($id, {without_transaction=>1})->data();
	$res = {
		id => $res->{id},
		inner_units => $res->{inner_units},
		joint_num => ses::input_int('joint_num'),
		x => ses::input_int('x'),
		y => ses::input_int('y'),
	};
	return $res;
}

sub cable_insert_splitter_now
{
	my $GAP = 80;

	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $joint_num = ses::input_int('joint_num');
	my $connectors = ses::input_int('connectors');
	my $fiber_to_splitter = ses::input_int('splitter');

	my $create_params = { no_commit=>1, heap_history=>1, without_transaction=>1 };

	my($cable1, $cable2) = _cable_cut( $scheme_id, {
		id => $id,
		x => $x,
		y => $y,
		joint_num => $joint_num,
		gap => $GAP,
		cable_end_joint_on_top => 1,
		create_params => { no_commit=>1, return_cables=>1 },
	});

	my $fiber_to_splitter_ok = 0;
	my $solder_count = 0;
	my $solder_fiber = {};
	my @ordered_fibers_with_solder = ();
	my @ordered_fibers_without_solder = ();
	foreach my $fiber_unit( sort{ $a->{offset}[1] <=> $b->{offset}[1] } values %{$cable1->{inner_units}})
	{
		my $fiber_id = $fiber_unit->{i};
		if( $fiber_to_splitter == $fiber_id )
		{
			$fiber_to_splitter_ok = 1;
		}
		 elsif( ses::input_int('soldering'.$fiber_id) )
		{
			$solder_fiber->{$fiber_id} = 1;
			$solder_count++;
			push @ordered_fibers_with_solder, $fiber_id;
		}
		 else
		{
			push @ordered_fibers_without_solder, $fiber_id;
		}
	}
	$fiber_to_splitter_ok or ApiError(L('Select the fiber to link to a splitter'));

	my $splitter = _frame_create($scheme_id, {
		type => 'splitter',
		x => $x + 10,
		y => $y - $connectors * $fiber_tips_distance * ($connectors > 16 ? 0.8 : 1),
		connectors => $connectors,
		solder_count => scalar(keys %{$cable1->{inner_units}}) - 1,
		create_params => $create_params,
		return_unit => 1,
	});

	my $ratio = ses::input('ratio');
	if( $connectors == 2 && $ratio ne '50/50' && $ratio =~ m|^(\d+)/(\d+)$| && ($1 + $2) == 100 )
	{
		$splitter->{inner_units}{1}{signal_ratio} = $2;
		$splitter->{inner_units}{2}{signal_ratio} = $1;
		$splitter->save('', {no_history=>1, no_commit=>1});
	}

	my @sorted_by_offset_solder_ids =
		map{ $_->{i} }
		sort{ $a->{y} <=> $b->{y} }
		grep{ $_->{type} eq 'solder' }
		values %{$splitter->{inner_units}};

	$cable1->{inner_units}{$fiber_to_splitter}{offset}[1] = -$fiber_tips_distance;
	$cable2->{inner_units}{$fiber_to_splitter}{offset}[0] = -$fiber_tips_distance;

	my $y_first_solder = scalar @sorted_by_offset_solder_ids ? $splitter->{inner_units}{$sorted_by_offset_solder_ids[0]}->{y} : 0;
	my $y_fiber_tip = 0;

	my @fibers_order = (@ordered_fibers_with_solder, @ordered_fibers_without_solder);
	foreach my $fiber_id( @fibers_order )
	{
		$cable1->{inner_units}{$fiber_id}{'offset'}[1] = $y_fiber_tip;
		$cable2->{inner_units}{$fiber_id}{'offset'}[0] = $y_fiber_tip;
		$y_fiber_tip += $fiber_tips_distance;
	}
	$cable1->save('', {no_history=>1, no_commit=>1});
	$cable2->save('', {no_history=>1, no_commit=>1});

	my $data = [
		[ $cable1->{id}, $fiber_to_splitter, 1 ],
		[ $splitter->{id}, 0, 0 ],
	];
	_link_create($scheme_id, $data, $create_params);

	foreach my $fiber_num( @fibers_order )
	{
		$solder_fiber->{$fiber_num} or next;
		my $solder_id = shift @sorted_by_offset_solder_ids;
		$splitter->{inner_units}{$solder_id} or next;
		$data = [
			[ $cable1->{id}, $fiber_num, 1 ],
			[ $splitter->{id}, $solder_id, 0 ],
		];
		_link_create($scheme_id, $data, $create_params);
		$data = [
			[ $cable2->{id}, $fiber_num, 0 ],
			[ $splitter->{id}, $solder_id, 0 ],
		];
		_link_create($scheme_id, $data, $create_params);
	}

	Fibers->create_history_record(['creating_of', 'of_splitter'], $Fibers::History) or _db_error();
	if( !Db->commit )
	{
		Db->rollback;
		_db_error();
	}

	my $res = get_all($scheme_id);
	#$res->{select_units} = $select_units_on_viewport;
	return $res;
} #efend

# --- Links ---

sub link_create
{
	my($scheme_id, $id) = @_;
	my $data = [
		[ ses::input_int('src'), ses::input_int('src_inner'), ses::input_int('src_side') ],
		[ ses::input_int('dst'), ses::input_int('dst_inner'), ses::input_int('dst_side') ],
	];
	return _link_create($scheme_id, $data);
}

sub _link_create
{
	my($scheme_id, $data, $create_params) = @_;

	my @data = @$data;
	my @units = (
		Fibers::Units->get_by_id($data[0][0], {without_transaction=>1}),
		Fibers::Units->get_by_id($data[1][0], {without_transaction=>1}),
	);
	foreach my $i( 0..1 )
	{
		my $u = $units[$i];
		exists $u->{inner_units}{$data[$i][1]} or ApiError(L('connector does not exist'));
		my $inner_type = $u->{cls} eq 'cable' ? 'fiber' : $u->{inner_units}{$data[$i][1]}{type};
		if( $u->{cls} eq 'cable' )
		{
			Db->line(
				'SELECT 1 FROM fibers_links WHERE removed=0 AND ((src=? AND src_inner=? AND src_side=?) OR (dst=? AND dst_inner=? AND dst_side=?))',
				$data[$i][0], $data[$i][1], $data[$i][2], $data[$i][0], $data[$i][1], $data[$i][2]
			) && return ApiError(L('one_link_connects_a_fiber'));
		}
		 else
		{
			my $target_cls = $units[1-$i]->{cls};
			my $target_type = $units[1-$i]->{type};
			#$u->{type} eq 'switch' && $target_type !~ /^(switch|panel)$/ && ApiError(L('Можно соединить только с рамой или другим коммутатором'));
			$u->{type} eq 'switch' && $u->{id} == $units[1-$i]->{id} && ApiError(L('Петля'));
			$inner_type eq 'solder' && $target_cls ne 'cable' && ApiError(L('soldering_connects_to_a_fiber_only'));
			my $db = Db->sql(
				'SELECT u.cls, u.type FROM fibers_links l JOIN fibers_units u ON l.dst=u.id WHERE l.removed=0 AND src=? AND src_inner=?'.
				' UNION ALL '.
				'SELECT u.cls, u.type FROM fibers_links l JOIN fibers_units u ON l.src=u.id WHERE l.removed=0 AND dst=? AND dst_inner=?',
				$data[$i][0], $data[$i][1], $data[$i][0], $data[$i][1]
			);
			$db->ok or _db_error();
			my $fibers_connection_count = 0;
			while( my %p = $db->line )
			{
				if( $inner_type eq 'solder' )
				{
					++$fibers_connection_count > 1 && ApiError(L('Только 2 волокна в пайке'));
				}
				 else
				{
					$p{cls} eq $target_cls && ApiError(L('cannot_create_link'));
				}
			}
			$data[$i][2] = 0;
		}
	}

	my $link_data = {
		src => $data[0][0],
		src_inner => $data[0][1],
		src_side => $data[0][2],
		dst => $data[1][0],
		dst_inner => $data[1][1],
		dst_side => $data[1][2],
		comment => '',
		removed => 0,
		scheme_id => $scheme_id,
		joints => [],
	};

	my $link = Fibers::Links->create($link_data, 'link_creating', $create_params);

	return $link->data();
}

sub link_remove
{
	my($scheme_id, $id) = @_;
	my $link = Fibers::Links->get_by_id($id);
	my $rows = Db->do('UPDATE fibers_links SET removed=1 WHERE removed=0 AND id=? AND scheme_id=?', $id, $scheme_id);
	if( $rows > 0 )
	{
		my $back = { removed=>0 };
		my $forward = { removed=>1 };
		$link->into_history('link_removing', $back, $forward);
	}
	Db->commit or _db_error();
	return {
		id => $id,
	};
}


sub link_joint_add
{
	my($scheme_id, $id) = @_;
	my($x, $y) = check_xy(ses::input_int('x', 'y'));
	my $joint_num = ses::input_int('joint_num');
	my $link = Fibers::Links->get_by_id($id, { get_color=>1 });

	$joint_num >= 0 or return $link->data();

	my $old_joints = [@{$link->{joints}}];
	splice(@{$link->{joints}}, $joint_num, 0, { x => $x, y => $y });

	my($ok);
	{
		if( $link->{tied} )
		{
			my $rows = Db->do("UPDATE fibers_cables SET joints=? WHERE id=?", $link->encode($link->{joints}), $link->{tied});
			$rows < 1 && last;
		}
		 else
		{
			Db->do("INSERT INTO fibers_cables SET joints=?", $link->encode($link->{joints}));
			Db->ok or _db_error();
			$link->{tied} = Db::result->insertid;
			my $rows = Db->do('UPDATE fibers_links SET tied=? WHERE tied=0 AND id=?', $link->{tied}, $id);
			$rows < 1 && last;
		}

		my $back = { 'fibers_cables.joints' => $old_joints, tied => $link->{tied} };
		my $forward = { 'fibers_cables.joints' => $link->{joints}, tied => $link->{tied} };
		$link->into_history('link_joint_adding', $back, $forward) or last;
		$ok = 1;
	}
	if( !$ok || !Db->commit )
	{
		Db->rollback;
		_db_error();
	}

	return $link->data();
}

sub link_joint_remove
{
	my($scheme_id, $id) = @_;
	my $joint_num = ses::input_int('joint_num');
	my $link = Fibers::Links->get_by_id($id);

	$joint_num >= 0 or $link->data();

	splice(@{$link->{joints}}, $joint_num, 1);

	$link->save('link_joint_removing');
	return $link->data();
}

sub link_joint_position
{
	my($scheme_id, $id) = @_;
	my($x, $y) = ses::input_int('x', 'y');
	my $joint_num = ses::input_int('joint_num');
	my $link = Fibers::Links->get_by_id($id, { get_color=>1 });

	$link->joint_change_position($x, $y, $joint_num);

	$link->save(['position_changing_of', 'of_link_joint']);
	return $link->data();
}

# --------

sub nomap
{
	my($scheme_id) = @_;
	my $units = {};
	my $cables = {};
	my $db = Db->sql(
		'SELECT l.src AS src_id, l.src_inner, l.dst AS dst_id, l.dst_inner, '.
			's.cls AS src_cls, d.cls AS dst_cls, s.place_id AS src_place, d.place_id AS dst_place '.
		'FROM fibers_links l JOIN fibers_units s ON l.src=s.id JOIN fibers_units d ON l.dst=d.id '.
			'WHERE s.removed=0 AND d.removed=0 AND l.scheme_id=?', $scheme_id
	);
	while( my %p = $db->line )
	{
		foreach my $i( ['src', 'dst'], ['dst', 'src'] )
		{
			my($i1, $i2) = @$i;
			my %p1 = map{ $_ => $p{$i1.'_'.$_} } grep{ s/^${i1}_// } keys %p;
			my %p2 = map{ $_ => $p{$i2.'_'.$_} } grep{ s/^${i2}_// } keys %p;
			if( $p1{cls} eq 'cable' )
			{
				my $id = $p1{id}.':'.$p1{inner};
				$cables->{$id} ||= [];
				push @{$cables->{$id}}, $p2{id};
			}
			 else
			{
				$units->{$p1{id}} = \%p1;
			}
		}
	}
	my $links = [];
	my $exists = {};
	foreach my $i( values %$cables )
	{
		scalar @$i > 1 or next;
		my $src = $units->{$i->[0]} or next;
		my $dst = $units->{$i->[1]} or next;
		$src = $src->{place};
		$dst = $dst->{place};
		($exists->{"$src:$dst"} || $exists->{"$dst:$src"}) && next;
		$exists->{"$src:$dst"} = 1;
		push @$links, [$src, $dst];
	}
	return { links=>$links };
}

sub bookmark_create
{
	my($scheme_id) = @_;
	my($x, $y) = check_xy(ses::input_int('x', 'y'));
	my $zoom = ses::input('zoom') + 0;
	my $name = v::trim(ses::input('name'));
	$name = 'bookmark' if $name eq '';
	($zoom <= 0 or $zoom > 10) && ApiError(L('Data error'));
	Db->do(
		"INSERT INTO fibers_bookmarks SET scheme_id=?, grp=?, x=?, y=?, zoom=?, name=? ON DUPLICATE KEY UPDATE name=?, removed=0",
		$scheme_id, 0, $x, $y, $zoom, $name, $name
	);
	Db->ok or _db_error();
	my $id = Db::result->insertid;
	my $bookmark = Fibers::Bookmarks->new(id=>$id, scheme_id=>$scheme_id, grp=>0, x => $x, y => $y, zoom=>$zoom, name=>$name);
	my $back = { removed=>1 };
	my $forward = { removed=>0 };
	$bookmark->into_history('bookmark creating', $back, $forward);
	return $bookmark->data();
}


sub bookmark_remove
{
	my($scheme_id, $id) = @_;
	my %p = Db->line("SELECT * FROM fibers_bookmarks WHERE scheme_id=? AND id=?", $scheme_id, $id);
	Db->ok or _db_error();
	%p or return $id;
	my $bookmark = Fibers::Bookmarks->new(%p);
	my($ok);
	{
		Db->begin_work or last;
		my $rows = Db->do("UPDATE fibers_bookmarks SET removed=1 WHERE scheme_id=? AND id=? AND removed=0", $scheme_id, $id);
		$rows < 1 && last;
		my $back = { removed=>0 };
		my $forward = { removed=>1 };
		$bookmark->into_history('bookmark removing', $back, $forward) or last;
		$ok = 1;
	}
	if( !$ok || !Db->commit )
	{
		Db->rollback;
		_db_error();
	}
	return $id;
}

sub pon_path
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	my $inner_id = ses::input_int('inner_id');
	exists $u->{inner_units}{$inner_id} or _reload_page();
	my $gid = $Scheme_data->{gid};
	return _path($scheme_id, 1, "$id:$inner_id", '');
}

sub path
{
	my($scheme_id) = @_;
	my $start_point = ses::input('start');
	my $end_point = ses::input('end');
	return _path($scheme_id, 0, $start_point, $end_point);
}

sub _path
{
	my $loss_settings = {
		'connector' => 0.5,
		'solder'=> 0.05,
		'cable' => 0.36,
		'coupler'=> 0.05,
		'panel' => 0.5,
		'FBT' => {
			1 => 24,
			2 => 20,
			3 => 17,
			4 => 15,
			5 => 13.7,
			10 => 10.8,
			15 => 8.16,
			20 => 7.11,
			25 => 6.29,
			30 => 5.39,
			35 => 4.56,
			40 => 4.01,
			45 => 3.63,
			50 => 3.17,
			55 => 2.71,
			60 => 2.34,
			65 => 1.93,
			70 => 1.56,
			75 => 1.42,
			80 => 1.06,
			85 => 0.76,
			90 => 0.49,
			95 => 0.32,
			96 => 0.3,
			97 => 0.28,
			98 => 0.27,
			99 => 0.26,
		}
	};

	my($scheme_id, $multipath, $start_point, $end_point) = @_;

	my $start_unit_id = int $start_point;
	my $end_unit_id = int $end_point;

	my $res = get_all($scheme_id);

	my $points_on_this_scheme = 0;
	foreach my $u( @{$res->{units}} )
	{
		$points_on_this_scheme++ if $u->{id} == $start_unit_id;
		$points_on_this_scheme++ if $u->{id} == $end_unit_id;
		$points_on_this_scheme > 1 && last;
	}

	my(@units, @links);
	if( $points_on_this_scheme < 2 )
	{
		my $all_linked_schemes = ses::input('all_linked_schemes');
		my $params = $all_linked_schemes ? { combine_schemes => 1 } : {};
		my($units, $links, $scheme_settings) = _get_all_linked_schemes($scheme_id, $res, $params);
		@units = @$units;
		@links = @$links;
		if( $all_linked_schemes )
		{
			$res->{units} = $units;
			$res->{links} = $links;
		}
	}
	 else
	{
		@units = @{$res->{units}};
		@links = @{$res->{links}};
	}

	my %existent_links = ();
	my %connections_on_connector = ();
	foreach my $l( @links )
	{
		my $src = $l->{src}.':'.$l->{src_inner};
		my $dst = $l->{dst}.':'.$l->{dst_inner};
		$existent_links{"$src,$dst"} = 1;
		$existent_links{"$dst,$src"} = 1;
		$connections_on_connector{$src}++;
		$connections_on_connector{$dst}++;
	}

	my @onu = ();
	# units that connectors are logicaly connected together
	my %connected_together = ();
	my %non_existent_links = ();
	foreach my $u( @units )
	{
		my $id = $u->{id};

		$u->{cls} eq 'cable' && next;

		if( $u->{type} eq 'switch' )
		{
			$connected_together{$id} = 1 if !$multipath;
			next;
		}

		if( $multipath )
		{
			foreach my $port( keys %{$u->{inner_units}} ) { push @onu, "$id:$port" };
		}

		my @iu = values %{$u->{inner_units}};

		foreach my $i( @iu )
		{
			$i->{type} eq 'splitter' or next;
			$i->{i} or next;
			push @links, {
				src => $id,
				dst => $id,
				src_inner => 0,
				dst_inner => $i->{i},
				splitter => 1,
			};
		}

		if( !$multipath )
		{
			foreach my $i( @iu )
			{
				$i->{type} eq 'splitter' && next;
				my $s = $i->{i};
				foreach my $j( @iu )
				{
					$j->{type} eq 'splitter' && next;
					my $d = $j->{i};
					$s == $d && next;
					my $src = "$id:$s";
					my $dst = "$id:$d";
					$existent_links{"$src,$dst"} && next;
					$non_existent_links{"$src,$dst"} && next;
					$non_existent_links{"$src,$dst"} = 1;
					$non_existent_links{"$dst,$src"} = 1;
					my $weight = $j->{type} eq 'solder' ? 1000000 :
						($connections_on_connector{$src} > 1 || $connections_on_connector{$dst} > 2) ? 100000 : 1000;
					push @links, {
						src => $id,
						dst => $id,
						src_inner => $s,
						dst_inner => $d,
						weight => $weight,
					};
				}
			}
		}
	}

	eval 'use Graph';
	my %graph_params = $multipath ? ( directed=>1 ) : ( undirected=>1 );
	my $g = Graph->new( %graph_params );

	my %links = ();
	foreach my $l( @links )
	{
		my $src = $l->{src};
		if( !$connected_together{$src} )
		{
			$src .= ':'.$l->{src_inner};
		}
		my $dst = $l->{dst};
		if( !$connected_together{$dst} )
		{
			$dst .= ':'.$l->{dst_inner};
		}
		$links{"$src,$dst"} = $l;
		$g->add_weighted_edge($src, $dst, int($l->{weight}));
		if( $multipath && !$l->{splitter} )
		{
			$links{"$dst,$src"} = $l;
			$g->add_weighted_edge($dst, $src, int($l->{weight}));
		}
	}
	# debug 'pre', 'links:', \%links;

	my %units = map{ $_->{id} => $_ } @units;
	foreach my $u ( @{$res->{units}} )
	{
		$u->{mute} = 1;
		map{ $_->{mute} = 1 } values %{$u->{inner_units}};
	}
	map{ $_->{mute} = 1 } @{$res->{links}};

	$start_point = int $start_point if $connected_together{int $start_point};
	$end_point   = int $end_point   if $connected_together{int $end_point};

	my $total_length = 0;
	my @length = ();
	my @path = ();
	my $total_loss = 0;
	my @loss_chain = ();

	my @endpoints = $multipath ? @onu : ($end_point);
	foreach my $end_point( @endpoints )
	{
		@path = (@path, $g->SP_Dijkstra($start_point, $end_point));
	}
	debug 'path:', \@path;

	my $pad = '&nbsp;&nbsp;&nbsp;';
	my $last_loss_signal_object = 0;
	my $last_p = undef;
	foreach my $p( @path )
	{
		my $id = int $p;
		if( defined $last_p )
		{
			delete $links{"$last_p,$p"}{mute};
			delete $links{"$p,$last_p"}{mute};
			if( $non_existent_links{"$last_p,$p"} )
			{
				$units{$id}{warning} = 1 if $units{$id};
			}
		}
		$last_p = $p;
		$units{$id} or next;

		#if( $units{$id}{cls} ne 'cable' && gid_eq_current_gid )
		#{
		#    my $u = Fibers::Units::Frame->get_by_id($id, {without_transaction=>1});
		#    my $box = $u->bounding_box();
		#    my $path_bounds = $res->{path_bounds} ||= {
		#        x_min => $box->{x_min}, y_min => $box->{y_min}, x_max => $box->{x_max}, y_max => $box->{y_max},
		#    };
		#    $path_bounds->{x_min} = $box->{x_min} if $box->{x_min} < $path_bounds->{x_min};
		#    $path_bounds->{y_min} = $box->{y_min} if $box->{y_min} < $path_bounds->{y_min};
		#    $path_bounds->{x_max} = $box->{x_max} if $box->{x_max} > $path_bounds->{x_max};
		#    $path_bounds->{y_max} = $box->{y_max} if $box->{y_max} > $path_bounds->{y_max};
		#}

		my $unit = $units{$id};
		delete $unit->{mute};
		if( $id eq $p )
		{
			map{ delete $_->{mute} } values %{$unit->{inner_units}};
			next;
		}
		if( exists $unit->{length} )
		{
			my $len = $unit->{length};
			push @length, $len || '??';
			$total_length += $len;
		}

		my(undef, $iid) = split /:/, $p;

		my $loss = 0;
		if( $unit->{cls} eq 'cable' )
		{
			my $len = $unit->{length};
			my $km = $len > 0 ? sprintf('%.3f', $len / 1000) : '?';
			my $k = $loss_settings->{cable};
			$loss = $len > 0 ? sprintf('%.2f', $km * $k) : '?';
			my $msg = _("[] $km [] × $k = $loss", L('cable'), L('km'));
			$msg = _('[span disabled]', $msg) if $len <= 0;
			push @loss_chain, $msg;
		}
		 else
		{

			$last_loss_signal_object ne $unit->{id} && push @loss_chain, L($unit->{type}).($unit->{name} ? ' '.$unit->{name} : '');
			$last_loss_signal_object = $unit->{id};
			{
				my $inner_unit = $unit->{inner_units}{$iid};
				if( $inner_unit->{type} eq 'solder' )
				{
					$loss  = $loss_settings->{solder};
					push @loss_chain, $pad.L('soldering').' = '.$loss;
					last;
				}
				if( $inner_unit->{type} eq 'connector' )
				{
					$loss  = $loss_settings->{connector};
					push @loss_chain, $pad.L('connector').' = '.$loss;
					last;
				}

				if( $inner_unit->{type} eq 'splitter' )
				{
					if( !$iid )
					{
						my $con_type = $inner_unit->{con_type} || 'cc';
						my($c1, $c2) = split //, $con_type;
						my $loss1 = $loss_settings->{$c1 eq 'c' ? 'connector' : 'solder'};
						my $loss2 = $loss_settings->{$c2 eq 'c' ? 'connector' : 'solder'};
						push @loss_chain, $pad.L('input' ).' '.($c1 eq 'c' ? L('connector') : L('soldering')).' = '.$loss1;
						push @loss_chain, $pad.L('output').' '.($c2 eq 'c' ? L('connector') : L('soldering')).' = '.$loss2;
						$loss = $loss1 + $loss2;
						last;
					}

					my $splitter_connectors = inner_count($unit, 'splitter') - 1;
					my $signal_ratio = $inner_unit->{signal_ratio} || 50;
					if( $splitter_connectors == 2 && $signal_ratio != 50 )
					{
						my $sr = exists $loss_settings->{FBT}{$signal_ratio} ? $signal_ratio : int(($signal_ratio+2) / 5) * 5;
						$loss = $loss_settings->{FBT}{$sr};
						push @loss_chain, $pad.$signal_ratio.'% = '.$loss;
					}
					 else
					{
						$loss = sprintf('%.2f', 4.68 * log($splitter_connectors>32 ? $splitter_connectors**(1 + $splitter_connectors*0.0008) : $splitter_connectors) + 0.97);
						push @loss_chain, $pad.'split 1x'.$splitter_connectors.' = '.$loss;
					}
				}
			}
		}

		$total_loss += $loss;

		delete $units{$id}{inner_units}{$iid}{mute} if exists $units{$id}{inner_units}{$iid};
		$units{$id}{in_path} = 1;
	}
	push @loss_chain, '', L('Total attenuation: []', $total_loss);
	$res->{path} = 1;
	if( !$multipath )
	{
		$res->{show_message} = L('length =', $total_length);
		$res->{show_message} .= ': '.join(' + ', @length) if scalar @length;
		$res->{show_message} .= '<br><br>'.join('<br>', @loss_chain) if scalar @loss_chain;
	}
	return $res;
}

# ----------- History -----------

sub undo_redo
{
	my($scheme_id) = @_;
	my $undo = ses::input('act') eq 'step_back';

	my $sql = 'SELECT * FROM fibers_history WHERE scheme_id=? AND actual=';
	$sql .= $undo ? '1 ORDER BY id DESC LIMIT 1' : '0 ORDER BY id LIMIT 1';

	my %p = Db->line($sql, $scheme_id);
	%p or ApiError(L('No history'));

	utf8::decode($p{data});
	my $data = from_json($p{data});

	ref $data or _data_error();

	$data = [ $data ] if ref $data ne 'ARRAY';

	my @all_sql = ();
	foreach my $d( @$data )
	{
		my $restore = $undo ? $d->{back} : $d->{forward};
		ref $restore eq 'HASH' or _data_error($restore);

		my %sqls = ();
		my $db_table = $d->{table};
		foreach my $k( keys %$restore )
		{
			my($table, $field) = $k =~ /\./ ? split(/\./, $k) : ($db_table, $k);
			$field =~ /^\w+$/ or _data_error({field=>$field});
			my $val = $restore->{$k};
			$val = Fibers->encode($val) if ref $val;
			$sqls{$table} ||= [ [] ];
			push @{$sqls{$table}[0]}, $field;
			push @{$sqls{$table}}, $val;
		}
		foreach my $table( keys %sqls )
		{
			if( $table !~ /^(fibers_units|fibers_links|fibers_cables|fibers_inner_units|fibers_bookmarks)$/ )
			{
				debug 'warn', 'internal errror: wrong table', $table;
				_data_error();
			}
			my $params = $sqls{$table};
			$params->[0] = "UPDATE $table SET ".join(', ', map{ "$_=?" } @{$params->[0]})." WHERE ";
			if( $table eq $db_table )
			{
				$params->[0] .= 'id=? AND scheme_id=?';
				push @$params, $d->{id}, $scheme_id;
			}
			 else
			{
				$params->[0] .= 'id=?';
				push @$params, $restore->{tied};
			}
			push @all_sql, $params;
		}
	}

	push @all_sql, [ "UPDATE fibers_history SET actual=? WHERE id=?", ($undo ? 0 : 1), $p{id} ];

	Db->do_all( @all_sql ) or ApiError(L('DB error'));
	my $res = get_all($scheme_id);
	if( exists $data->[0]{back_pos} )
	{
		my $b = $data->[0]{back_pos};
		$res->{'pan_x'} = $b->{'pan_x'};
		$res->{'pan_y'} = $b->{'pan_y'};
		$res->{zoom} = $b->{zoom};
	}
	return $res;
}

sub history
{
	my($scheme_id) = @_;

	my $history = [];
	my $future = [];
	my $sql = 'SELECT id, action, time FROM fibers_history WHERE';
	my $db1 = Db->sql("$sql actual=1 AND scheme_id=? ORDER BY id DESC LIMIT 10", $scheme_id);
	my $db2 = Db->sql("$sql actual=0 AND scheme_id=? ORDER BY id LIMIT 10", $scheme_id);

	foreach my $i( [$db1, $history], [$db2, $future] )
	{
		while( my %p = $i->[0]->line )
		{
			my $action;
			eval{ $action = Fibers::Units->decode($p{action}) };
			$action = [$p{action}] if $@ || ref $action ne 'ARRAY';
			my $action0 = shift @$action;
			$action = L($action0, map{ L($_) } @$action);
			my $data = { id=>$p{id}, action=>$action, time=>the_short_time($p{time}, 1) };
			push @{$i->[1]}, $data;
		}
	}
	return {
		history => $history,
		future => $future,
	};
}


sub create_color_preset
{
	my($scheme_id) = @_;
	my $fibers_colors = {};
	my $db = Db->sql('SELECT * FROM fibers_colors');
	while( my %p = $db->line )
	{
		$fibers_colors->{$p{id}} = 1;
	}
	my @colors = ();
	my %input = ses::input_all();
	foreach my $k( sort{ $input{$a} <=> $input{$b} } keys %input )
	{
		$k =~ /^color_(\d+)/ or next;
		push @colors, $1 if $fibers_colors->{$1};
	}
	Db->do('INSERT INTO fibers_colors_presets SET scheme_id=?, description=?, colors=?', $scheme_id, ses::input('description'), join(',', @colors));
	return get_all($scheme_id);
}

sub delete_color_preset
{
	my($scheme_id) = @_;
	Db->do('DELETE FROM fibers_colors_presets WHERE scheme_id=? AND id=?', $scheme_id, ses::input_int('type'));
	return get_all($scheme_id);
}


sub scheme_data
{
	my($scheme_id) = @_;
	my $Db = $Fibers::MainDb;
	my %p = $Db->line(
		'SELECT gid, uid, name, shared, favorite, is_block, inner_data_db, inner_data_db_fields, settings '.
		'FROM fibers_schemes WHERE id=?', $scheme_id
	);
	%p or ApiError(L('DB error'));
	$p{ro} = $User->{ro};
	$p{is_owner} = $User->{is_owner};
	$p{can_change_sharing} = $User->{is_owner} && !!$p{uid};
	$p{access_cable_types} = $User->{role} eq 'admin';
	delete $p{uid};
	if( !$p{can_change_sharing} )
	{
		delete $p{inner_data_db};
		delete $p{inner_data_db_fields};
	}
	$p{settings} = from_json($p{settings} || '{}');
	$p{settings}{tags} ||= {};
	foreach my $i( 0..$MAX_FRAME_TAGS )
	{
		$p{settings}{tags}{$i} .= '';
	}
	$p{settings}{min_signal_level} ||= $MIN_SIGNAL_LEVEL;
	$p{settings}{max_signal_level} ||= $MAX_SIGNAL_LEVEL;
	$p{settings}{signal_levels} ||= [];
	return \%p;
}

sub scheme_data_save
{
	my($scheme_id) = @_;
	my $Db = $Fibers::MainDb;
	my $name = v::trim(ses::input('name'));
	my $shared = ses::input_int('shared');
	$shared = $shared > 1 ? 2 : $shared ? 1 : 0;
	my $favorite = ses::input_int('favorite');
	$favorite = $favorite ? 1 : 0;
	my $inner_data_db = v::trim(ses::input('inner_data_db').'');
	my $inner_data_db_fields = v::trim(ses::input('inner_data_db_fields').'');
	my $tags = {};
	my $settings = {
		tags => $tags
	};
	foreach my $i( 0..$MAX_FRAME_TAGS )
	{
		my $tag = v::trim(ses::input("tag_$i"));
		utf8::decode($tag);
		utf8::upgrade($tag);
		$tags->{$i} = $tag if length($tag);
	}
	{
		my $levels = v::trim(ses::input('signal_levels')) or last;
		my @levels = split / *, */, $levels;
		$levels = _validate_signal_levels(\@levels);
		scalar @levels == 4 or last;
		$settings->{signal_levels} = $levels if ref $levels;
	}
	$Db->line(
		'UPDATE fibers_schemes SET name=?, '.
			'shared=IF(uid=0 OR uid<>?, shared, ?),  '.
			'favorite=IF(uid=0 OR uid<>?, favorite, ?), '.
			'inner_data_db=IF(uid=0 OR uid<>?, inner_data_db, ?), '.
			'inner_data_db_fields=IF(uid=0 OR uid<>?, inner_data_db_fields, ?), '.
			'settings=? '.
		'WHERE id=?',
			$name,
			$Uid, $shared,
			$Uid, $favorite,
			$Uid, $inner_data_db,
			$Uid, $inner_data_db_fields,
			to_json($settings),
			$scheme_id
	);
	$Db->ok or ApiError(L('DB error'));

	my %tags = map{ $scheme_id.':'.$_ => $tags->{$_} } keys %$tags;
	$settings->{tags} = \%tags;
	return {
		settings => $settings
	};
}


sub scheme_remove()
{
	my($scheme_id) = @_;
	$User->{full_access} or ApiError(L('Access denied'));
	my $Db = $Fibers::MainDb;
	$Db->do('DELETE FROM fibers_schemes WHERE id=?', $scheme_id);
	$Db->ok or _db_error();

	_delete_scheme_now($scheme_id);

	return [];
}

sub map_position
{
	my($scheme_id) = @_;
	my $lat = ses::input('lat') + 0;
	my $lng = ses::input('lng') + 0;
	Db->do('UPDATE fibers_schemes SET lat=?, lng=? WHERE id=?', $lat, $lng, $scheme_id);
	return undef;
}

sub map_unit_position
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id, { check_removed=>1 });
	$u->{type} eq 'container' or ApiError('Only container can be set on a map');
	$u->{lat} = ses::input('lat') + 0;
	$u->{lng} = ses::input('lng') + 0;
	$u->save(['map_position_of', 'of_'.$u->{type}], { no_need_dumps_in_history=>1 });
	return {
		unit => {
			id => $id,
			lat => $u->{lat},
			lng => $u->{lng},
		},
		scheme => map_get_all($scheme_id),
	}
}

sub map_unit_remove
{
	my($scheme_id, $id) = @_;
	my $u = Fibers::Units::Frame->get_by_id($id);
	$u->{lat} = 0;
	$u->{lng} = 0;
	$u->save(['map_unit_remove', 'of_'.$u->{type}], { no_need_dumps_in_history=>1 });
	return {
		unit => {
			id => $id,
			lat => $u->{lat},
			lng => $u->{lng},
		},
		scheme => map_get_all($scheme_id),
	}
}


sub check_history
{
	my($scheme_id) = @_;
	my $db = Db->sql('SELECT id FROM fibers_units WHERE removed=0 AND scheme_id=?', $scheme_id);
	my %units = ();
	while( my %p = $db->line )
	{
		$units{$p{id}} = 1;
	}
	my $db = Db->sql('SELECT * FROM fibers_history WHERE scheme_id=?', $scheme_id);
	while( my %p = $db->line )
	{
		utf8::decode($p{data});
		my $data = from_json($p{data});
		$data = [$data] if ref $data ne 'ARRAY';
		foreach my $i( @$data )
		{
			my $id = $i->{id} or next;
			# delete $units{$id};
		}
	}
	debug [keys %units];
	return get_all($scheme_id);
}

#<HOOK>main_end

# -----------------


package Fibers;
use JSON;
use Debug;

our $Scheme_id;
our $History = [];

sub api_db_error
{
	main::ApiError(main::L('DB error'));
}

sub encode
{
	my(undef, $data) = @_;
	$data = to_json($data);
	utf8::decode($data);
	utf8::upgrade($data);
	return $data;
}

sub decode
{
	my(undef, $data) = @_;
	return from_json($data);
}

sub clean_future
{
	my(undef) = @_;
	Db->do("DELETE FROM fibers_history WHERE actual=0 AND scheme_id=?", $Scheme_id);
	return Db->ok;
}

sub make_history_fragment
{
	my($it, $back, $forward) = @_;
	my $data = {
		table   => $it->db_table(),
		id      => $it->{id},
		back    => $back,
		forward => $forward,
	};
	if( ses::input_exists('zoom') )
	{
		$data->{back_pos} = {
			pan_x => ses::input('pan_x') + 0,
			pan_y => ses::input('pan_y') + 0,
			zoom  => ses::input('zoom') + 0,
		};
	}
	return $data;
}

sub create_history_record
{
	my($it, $action, $history_record) = @_;
	my $data = $it->encode($history_record);
	$action = $it->encode($action) if ref $action eq 'ARRAY';
	Db->do(
		"INSERT INTO fibers_history SET time=UNIX_TIMESTAMP(), scheme_id=?, action=?, data=?",
		$Scheme_id, $action, $data
	);
	Db->ok or return 0;
	return $it->clean_future();
}

sub into_history
{
	my($it, $action, $back, $forward) = @_;
	my $history_record = $it->make_history_fragment($back, $forward);
	return $it->create_history_record($action, $history_record);
}

sub save
{
	# $params = {
	#    no_commit    => do not commit sql
	#    no_history   => do not create history records
	#    heap_history => save history in $Fibers::History
	# }
	my($u, $action, $params) = @_;
	$params ||= {};

	my $sqls = $u->prepare_save_sqls();
	my $db_table = $u->db_table();

	my($ok);
	{
		foreach my $sql( @$sqls )
		{
			Db->do(@$sql);
			Db->ok or last;
		}
		Db->ok or last;

		if( !$params->{no_history} )
		{
			my $old = $u->{old};
			my $back = {};
			my $forward = {};
			foreach my $o( keys %$old )
			{
				my $field_name = $u->full_field_name($o);
				$back->{$field_name} = $old->{$o};
				$forward->{$field_name} = $u->{$o};
			}
			if( $params->{no_need_dumps_in_history} )
			{
				delete $back->{inner_units};
				delete $back->{add_data};
				delete $forward->{inner_units};
				delete $forward->{add_data};
			}
			$action ||= ['[] []', $u->{type}, 'changing'];
			if( $params->{heap_history} )
			{
				push @$Fibers::History, {
					table   => $u->db_table(),
					id      => $u->{id},
					back    => $back,
					forward => $forward,
				};
			}
			  else
			{
				$u->into_history($action, $back, $forward) or last;
			}
		}
		$ok = 1;
	}
	if( !$ok || (!$params->{no_commit} && !Db->commit) )
	{
		Db->rollback;
		$u->api_db_error();
	}
}

sub _data
{
	my $param = shift;
	defined($param) or return undef;
	if( ref $param eq 'ARRAY' )
	{
		return [ map{ _data($_) } @$param ];
	}
	if( ref $param )
	{
		return { map{ $_ => _data($param->{$_}) } keys %$param };
	}
	return $param.'';
}


package Fibers::Units;
use base 'Fibers';
use Debug;
main->import( qw( _ L Error ) );

our %fields_lengths = (
	cls  => 32,
	type => 32,
	name => 64,
	img  => 5,
	description => 128,
	inner__name => 12,
	inner__description => 48,
	inner__remote_id => 32,
);

sub package_by_cls
{
	my(undef, $cls) = @_;
	return $cls eq 'cable' ? 'Fibers::Units::Cable' : 'Fibers::Units::Frame';
}

sub new
{
	my($cls, %d) = @_;
	my $pkg = $cls->package_by_cls($d{cls});
	return $pkg->new(%d);
}

sub get_by_id
{
	my($cls, $id, $params) = @_;
	my %p = Db->line("SELECT cls FROM fibers_units WHERE id=?", $id);
	%p or $cls->api_db_error();
	my $pkg = $cls->package_by_cls($p{cls});
	return $pkg->get_by_id($id, $params);
}

sub prepare_save_sqls
{
	my($u) = @_;
	# use int/+0 for optional parameters
	my $sqls = [[
		'UPDATE fibers_units SET '.
			'x=?, y=?, x0=?, y0=?, '.
			'name=?, type=?, map_type=?, description=?, img=?, grp=?, place_id=?, '.
			'tied=?, nodeny_obj_id=?, lat=?, lng=?, inner_units=?, add_data=? '.
		'WHERE id=?',
			$u->{x}, $u->{y}, $u->{x0}+0, $u->{y0}+0,
			$u->{name}, $u->{type}, int($u->{map_type}), $u->{description}, $u->{img}, $u->{grp}, $u->{place_id},
			$u->{tied}, int $u->{nodeny_obj_id}, $u->{lat}+0, $u->{lng}+0, $u->encode($u->{inner_units}), $u->encode($u->{add_data}),
			$u->{id}
	]];
	return $sqls;
}

sub create
{
	my($cls, $data, $action, $params)= @_;
	$params ||= {};

	my $prepared = {%$data};

	my($ok, $u);
	{
		!$params->{without_transaction} && !Db->begin_work && last;

		my $pkg = $cls->package_by_cls($data->{cls});
		if( $data->{cls} eq 'cable' )
		{
			if( !$data->{tied} )
			{
				my $joints = $data->{joints} || [];
				Db->do(
					"INSERT INTO fibers_cables SET xa=?, ya=?, xb=?, yb=?, length=?, trunk=?, joints=?",
					int($data->{xa}), int($data->{ya}), int($data->{xb}), int($data->{yb}),
					int($data->{length}), int($data->{trunk}), $cls->encode($joints)
				);
				Db->ok or last;
				$prepared->{tied} = Db::result->insertid;
			}
			foreach( 'xa', 'ya', 'xb', 'yb', 'length', 'trunk', 'joints' ) { delete $prepared->{$_}; }
		}
		 else
		{
			$prepared->{tied} = 0;
		}

		$prepared->{add_data} = $cls->encode($data->{add_data});
		$prepared->{inner_units} = $cls->encode($data->{inner_units});

		map{ $prepared->{$_} = int $prepared->{$_} } ('map_type', 'nodeny_obj_id');
		$prepared->{lat} += 0;
		$prepared->{lng} += 0;

		my @sql = ();
		my @sql_params = ();
		foreach my $p(
			'scheme_id', 'cls', 'name', 'type', 'map_type', 'description', 'x', 'y', 'x0', 'y0',
			'img', 'grp', 'lat', 'lng', 'place_id', 'tied', 'nodeny_obj_id', 'inner_units', 'add_data',
		){
			push @sql, "$p=?";
			push @sql_params, $prepared->{$p};
		}
		my $sql = 'INSERT INTO fibers_units SET '.join(', ', @sql);

	    Db->do($sql, @sql_params);
	    Db->ok or last;
	    my $id = Db::result->insertid;
	    $u = $pkg->get_by_id($id, {without_transaction=>1});

		if( !$params->{no_history} )
		{
			my $back = { removed=>1 };
			my $forward = { removed=>0 };
			if( $params->{heap_history} )
			{
				push @$Fibers::History, {
					table   => $u->db_table(),
					id      => $u->{id},
					back    => $back,
					forward => $forward,
				};
			}
			 else
			{
				$u->into_history($action, $back, $forward) or last;
			}
		}

		$ok = 1;
	}

	if( !$ok || (!$params->{no_commit} && !Db->commit) )
	{
		Db->rollback;
		Fibers->api_db_error();
	}

	return $u;
}

sub delete
{
	my($u, $action) = @_;
	$action ||= ["$u->{type} removing"];
	my $history = [];
	my $db = Db->sql('SELECT id FROM fibers_links WHERE removed=0 AND (src=? OR dst=?)', $u->{id}, $u->{id});
	while( my %p = $db->line )
	{
		push @$history, {
			table   => 'fibers_links',
			id      => $p{id},
			back    => { removed=>0 },
			forward => { removed=>1 },
		};
	}
	if( $u->{type} eq 'container' )
	{
		my $db = Db->sql('SELECT id FROM fibers_units WHERE removed=0 AND place_id=?', $u->{id});
		while( my %p = $db->line )
		{
			push @$history, {
				table   => 'fibers_units',
				id      => $p{id},
				back    => { place_id=>$u->{id} },
				forward => { place_id=>0 },
			};
		}
	}
	push @$history, {
		table   => 'fibers_units',
		id      => $u->{id},
		back    => { removed=>$u->{removed} },
		forward => { removed=>1 },
	};
	my $data = $u->encode($history);
	$action = $u->encode($action) if ref $action eq 'ARRAY';
	my($ok);
	{
		Db->do('UPDATE fibers_links SET removed=1 WHERE removed=0 AND (src=? OR dst=?)', $u->{id}, $u->{id});
		Db->ok or last;
		Db->do('UPDATE fibers_units SET place_id=0 WHERE removed=0 AND place_id=?', $u->{id});
		Db->ok or last;
		Db->do('UPDATE fibers_units SET removed=1 WHERE id=?', $u->{id});
		Db->ok or last;
		Db->do("INSERT INTO fibers_history SET time=UNIX_TIMESTAMP(), scheme_id=?, action=?, data=?", $u->{scheme_id}, $action, $data);
		Db->ok or last;
		$u->clean_future() or last;
		$ok = 1;
	}
	if( !$ok || !Db->commit )
	{
		Db->rollback;
		$u->api_db_error();
	}
}

sub inner_remove
{
	my($u, $inner_id) = @_;
	my $iu = $u->{inner_units};
	exists $iu->{$inner_id} or return 0;

	if( keys %$iu < 2 )
	{
		$u->delete();
		return 2;
	}

	my $id = $u->{id};
	my $history = [];
	my $where = 'WHERE removed=0 AND ((src=? AND src_inner=?) OR (dst=? AND dst_inner=?))';
	my $db = Db->sql("SELECT id FROM fibers_links $where", $id, $inner_id, $id, $inner_id);
	while( my %p = $db->line )
	{
		push @$history, { table=>'fibers_links', id=>$p{id}, back=>{removed=>0}, forward=>{removed=>1} };
	}

	if( scalar @$history )
	{
		my($ok);
		{
			Db->do("UPDATE fibers_links SET removed=1 $where", $id, $inner_id, $id, $inner_id);
			Db->ok or last;

			Db->do(
				"INSERT INTO fibers_history SET time=UNIX_TIMESTAMP(), scheme_id=?, action=?, data=?",
				$u->{scheme_id}, 'links removing', $u->encode($history)
			);
			Db->ok or last;

			$ok = 1;
		}

		if( !$ok )
		{
			Db->rollback;
			$u->api_db_error();
		}
	}

	delete $u->{inner_units}{$inner_id};
	my $act_descr = $u->{cls} eq 'cable' ? 'cable fiber removing' : 'inner element removing';
	$u->save($act_descr);
	return 1;
}

sub box_size
{
	my($u) = @_;
	my $iu = $u->{inner_units};
	my @iu = values %$iu;
	my @x = map{ $_->{x} } sort{ $a->{x} <=> $b->{x} } @iu;
	my @y = map{ $_->{y} } sort{ $a->{y} <=> $b->{y} } @iu;
	return {
		x_min => $x[0],
		x_max => $x[-1],
		y_min => $y[0],
		y_max => $y[-1],
		width => $x[-1] - $x[0],
		height => $y[-1] - $y[0],
	};
}

sub bounding_box
{
	my($u) = @_;
	my $box = $u->box_size();
	my $res = {
		x_min => $u->{x} + $box->{x_min},
		x_max => $u->{x} + $box->{x_max},
		y_min => $u->{y} + $box->{y_min},
		y_max => $u->{y} + $box->{y_max},
		width => $box->{width},
		height => $box->{height},
	};
	$res->{'center_x'} = ($res->{x_max} + $res->{x_min}) / 2;
	$res->{'center_y'} = ($res->{y_max} + $res->{y_min}) / 2;
	return $res;
}

sub all_tied_units_data
{
	my($u) = @_;
	my $res = [ $u->data() ];
	if( $u->{cls} eq 'cable' )
	{
		my $db = Db->sql('SELECT id FROM fibers_units WHERE removed=0 AND scheme_id=? AND tied=? AND id<>?', $u->{scheme_id}, $u->{tied}, $u->{id});
		while( my %p = $db->line )
		{
			push @$res, Fibers::Units::Cable->get_by_id($p{id}, {without_transaction=>1})->data();
		}
	}
	return $res;
}

sub inner_count
{
	my($u, $inner_type) = @_;
	return main::inner_count($u, $inner_type);
}


package Fibers::Units::Frame;
use base 'Fibers::Units';
use Debug;
main->import( qw( _ L Error ) );

sub db_table { return 'fibers_units' }

sub full_field_name
{
	my(undef, $f) = @_;
	return $f;
}

our @allowed_types = ( 'panel', 'coupler', 'switch', 'splitter', 'box', 'fbt', 'onu', 'empty', 'container' );
my %allowed_types;

sub new
{
	my $cls = shift;
	my %d = @_;
	my $u = {
		id        => int $d{id},
		scheme_id => int $d{scheme_id},
		removed   => int $d{removed},
		cls       => $d{cls}.'',
		type      => $d{type}.'',
		map_type  => $d{map_type}.'',
		name      => $d{name}.'',
		x         => int $d{x},
		y         => int $d{y},
		lat       => $d{lat} + 0,
		lng       => $d{lng} + 0,
		place_id  => int $d{place_id},
		tied      => int $d{tied},
		add_data  => $d{data},
		img       => $d{img}.'',
		grp       => int $d{grp},
		description => $d{description}.'',
		inner_units => ref $d{inner_units} ? $d{inner_units} : $cls->decode($d{inner_units}),
		add_data  => ref $d{add_data} ? $d{add_data} : $cls->decode($d{add_data}),
		nodeny_obj_id => int $d{nodeny_obj_id},
	};
	bless $u, $cls;
	$u->{old} = $u->data();
	return $u;
}

sub data
{
	my($u) = @_;
	my $data = Fibers::_data($u);
	$data->{id} += 0;
	$data->{x} += 0;
	$data->{y} += 0;
	$data->{lat} += 0;
	$data->{lng} += 0;
	$data->{grp} += 0;
	$data->{place_id} += 0;
	$data->{tied} += 0;
	if( exists $data->{inner_units} && ref $data->{inner_units} eq 'HASH' )
	{
		foreach my $i( values %{$data->{inner_units}} )
		{
			$i->{x} = int $i->{x};
			$i->{y} = int $i->{y};
		}
	}
	return $data;
}

sub get_by_id
{
	my($cls, $id, $params) = @_;
	$params ||= {};

	my($sql, @sql_params);
	if( $params->{maybe_other_scheme} )
	{
		$sql = 'SELECT s.uid, s.shared, u.* FROM fibers_units u JOIN fibers_schemes s ON u.scheme_id=s.id '.
			'WHERE s.is_block=0 AND u.id=?';
		@sql_params = ($id);
	}
	 else
	{
		$sql = "SELECT * FROM fibers_units u WHERE u.cls='frame' AND u.id=? AND u.scheme_id=?";
		@sql_params = ($id, $Fibers::Scheme_id);
	}

	$params->{without_transaction} or Db->begin_work or $cls->api_db_error();
	$sql .= ' FOR UPDATE' if !$params->{without_transaction};

	my %p = Db->line( $sql, @sql_params );
	%p or $cls->api_db_error();

	$params->{maybe_other_scheme} && !$p{shared} && $p{uid} != $Uid && !$User->{superadmin}
		&& main::ApiError(L('Access denied'));
	$params->{check_removed} && $p{removed} && main::ApiError(L('Object is deleted'));

	return $cls->new(%p);
}

sub prepare_save_sqls
{
	my($u) = @_;
	my $sqls = $u->SUPER::prepare_save_sqls();
	return $sqls;
}

=cut
+-------------+------------------+------+-----+---------+
| Field       | Type             | Null | Key | Default |
+-------------+------------------+------+-----+---------+
| id          | int(11) unsigned | NO   | PRI | NULL    |
| scheme_id   | int(11) unsigned | NO   | MUL | NULL    |
| cls         | varchar(32)      | NO   |     |         |
| type        | varchar(32)      | NO   | MUL |         |
| name        | varchar(64)      | NO   |     |         |
| description | varchar(128)     | NO   |     |         |
| place_id    | int(11) unsigned | NO   |     | 0       |
| tied        | int(11) unsigned | NO   |     | 0       |
| grp         | int(11) unsigned | NO   |     | 0       |
| x           | int(11)          | NO   |     | 0       |
| y           | int(11)          | NO   |     | 0       |
| x0          | int(11)          | NO   |     | 0       |
| y0          | int(11)          | NO   |     | 0       |
| inner_units | text             | NO   |     | NULL    |
| add_data    | text             | NO   |     | NULL    |
| img         | varchar(5)       | NO   |     |         |
| removed     | tinyint(4)       | NO   |     | 0       |
+-------------+------------------+------+-----+---------+
=cut

sub check_data
{
	my $cls = shift;
	my $d = shift;

	my %fl = %Fibers::Units::fields_lengths;

	my $u = {};
	map{ $u->{$_} = substr $d->{$_}.'', 0, $fl{$_} } ( 'type', 'map_type', 'name', 'description', 'img' );
	map{ $u->{$_} = int $d->{$_} } ( 'id', 'x', 'y', 'x0', 'y0', 'place_id', 'tied', 'grp', 'nodeny_obj_id', 'removed', 'scheme_id' );

	$cls->check_type($u->{type}) or return 'frame type is incorrect';

	my $bounds = $fibers__xy_bounds;
	my $error = $d->{x} < -$bounds->{x} || $d->{x} > $bounds->{x} || $d->{y} < -$bounds->{y} || $d->{y} > $bounds->{y};
	$error && return 'frame xy bounds';

	$u->{cls} = 'frame';
	$u->{x0} = 0;
	$u->{y0} = 0;
	$u->{lat} = $d->{lat} + 0;
	$u->{lng} = $d->{lng} + 0;
	$u->{lat} = $u->{lng} = 0 if abs($u->{lat}) > 90 || abs($u->{lng}) > 90;
	$u->{inner_units} = {};
	my $add_data = $u->{add_data} = {};

	$add_data->{layers} = exists $d->{add_data}{layers} ? $d->{add_data}{layers} : $d->{add_data}{subtype} ? 'infrastructure' : '';
	$add_data->{layers} = '' if $add_data->{layers} !~ /^(|scheme|infrastructure)$/;
	$add_data->{layers} = '' if $add_data->{layers} eq 'scheme' && ($u->{lat} || $u->{lng});
	if( ref $d->{add_data}{tags} eq 'ARRAY' )
	{
		my $tags = [ grep{ $_ >= 0 && $_ < $MAX_FRAME_TAGS } map{ int $_} @{$d->{add_data}{tags}} ];
		$add_data->{tags} = $tags if scalar @$tags;
	}

	ref $d->{inner_units} eq 'HASH' or return 'inner_units is not a hash';
	my $iu = $d->{inner_units};
	my $bx = $fibers__inner_xy_bounds->{x};
	my $by = $fibers__inner_xy_bounds->{y};
	foreach my $id( keys %$iu )
	{
		$id =~ /^\d+$/ or return 'inner_units key is not a number';
		ref $iu->{$id} eq 'HASH' or return 'inner_units element is not a hash';
		my $iue = $iu->{$id};
		my $type = $iue->{type}.'';
		$type =~ /^(connector|solder|splitter|port)$/ or return 'inner_units element type is incorrect';
		my $x = int $iue->{x};
		my $y = int $iue->{y};
		($x < -$bx || $x > $bx || $y < -$by || $y > $by) && return "xy bounds of inner_units element #$id";
		$u->{inner_units}{$id} = {
			i => $id,
			x => $x,
			y => $y,
			name => substr($iue->{name}.'', 0, $fl{inner__name}),
			description => substr($iue->{description}.'', 0, $fl{inner__description}),
			type => $type,
		};
		$u->{inner_units}{$id}{remote_id} = substr($iue->{remote_id}.'', 0, $fl{inner__remote_id}) if exists $iue->{remote_id};
	}

	{
		$u->{type} eq 'switch' && last;
		my @splitter_connectors = grep{ $_->{type} eq 'splitter' } grep{ $_->{i} } values %$iu;
		scalar @splitter_connectors or last;

		if( !exists $u->{inner_units}{0} )
		{
			$u->{inner_units}{0} = { i=>0, name=>'', type=>'splitter', 'x'=>0, 'y'=>0 };
		}

		if( $iu->{0}{con_type}.'' =~ /^(ss|sc|cs)$/ )
		{
			$u->{inner_units}{0}{con_type} = $iu->{0}{con_type};
		}

		scalar @splitter_connectors == 2 or last;
		my $signal_ratio1 = int $splitter_connectors[0]->{signal_ratio};
		my $signal_ratio2 = int $splitter_connectors[1]->{signal_ratio};
		($signal_ratio1 > 0 && $signal_ratio1 < 100) or last;
		($signal_ratio2 > 0 && $signal_ratio2 < 100) or last;
		($signal_ratio1 + $signal_ratio2 == 100) or last;
		$u->{inner_units}{$splitter_connectors[0]->{i}}{signal_ratio} = $signal_ratio1;
		$u->{inner_units}{$splitter_connectors[1]->{i}}{signal_ratio} = $signal_ratio2;
	}

	return $u;
}

sub check_type
{
	ref $_[1] && return 0;
	%allowed_types = map{ $_ => 1 } @allowed_types if !%allowed_types;
	return $allowed_types{$_[1]};
}

sub change_position
{
	my($u, $x, $y, undef, $is_map_view) = @_;
	$is_map_view && return $u;
	$u->{x} += $x;
	$u->{y} += $y;
	main::check_xy($u->{x}, $u->{y});
	return $u;
}



package Fibers::Units::Cable;
use base 'Fibers::Units';
use Debug;
main->import( qw( _ L Error ) );

sub db_table { return 'fibers_units' }

sub full_field_name
{
	my(undef, $f) = @_;
	return $f =~ /^(xa|ya|xb|yb|joints|length|trunk)$/ ? 'fibers_cables.'.$f : $f;
}

sub new
{
	my $cls = shift;
	my %d = @_;
	my $u = {
		id => int $d{id},
		scheme_id => int $d{scheme_id},
		removed => int $d{removed},
		cls => $d{cls}.'',
		type => $d{type}.'',
		map_type => $d{map_type}.'',
		name => $d{name}.'',
		description => $d{description}.'',
		x  => int $d{x},
		y  => int $d{y},
		x0 => int $d{x0},
		y0 => int $d{y0},
		xa => int $d{xa},
		ya => int $d{ya},
		xb => int $d{xb},
		yb => int $d{yb},
		length => int $d{length},
		trunk => int $d{trunk},
		place_id => int $d{place_id},
		tied => int $d{tied},
		add_data => $d{data},
		img => $d{img}.'',
		grp => int $d{grp},
		inner_units => ref $d{inner_units} ? $d{inner_units} : $cls->decode($d{inner_units}),
		add_data => ref $d{add_data} ? $d{add_data} : $cls->decode($d{add_data}),
		joints => ref $d{joints} ? $d{joints} : $cls->decode($d{joints}),
		nodeny_obj_id => int $d{nodeny_obj_id},
	};
	bless $u, $cls;
	$u->{old} = $u->data();
	return $u;
}

sub get_by_id
{
	my($cls, $id, $params) = @_;
	$params->{without_transaction} or Db->begin_work or $cls->api_db_error();
	my $for_update = $params->{without_transaction} ? '' : 'FOR UPDATE';
	my $scheme_id = $params->{scheme_id} || $Fibers::Scheme_id;
	my %p = Db->line(
		"SELECT u.*, c.xa, c.ya, c.xb, c.yb, c.joints, c.length, c.trunk ".
		"FROM fibers_units u JOIN fibers_cables c ON u.tied=c.id ".
		"WHERE u.cls='cable' AND u.id=? AND u.scheme_id=? $for_update",
		$id, $scheme_id
	);
	if( !%p )
	{
		return undef if $params->{no_api_error};
		$cls->api_db_error();
	}
	my $u = $cls->new(%p);
	return $u;
}

sub data
{
	my($u) = @_;
	my $data = Fibers::_data($u);
	$data->{id} += 0;
	$data->{x} += 0;
	$data->{y} += 0;
	$data->{x0} += 0;
	$data->{y0} += 0;
	$data->{xa} += 0;
	$data->{ya} += 0;
	$data->{xb} += 0;
	$data->{yb} += 0;
	$data->{grp} += 0;
	$data->{place_id} += 0;
	$data->{length} += 0;
	$data->{trunk} += 0;
	if( exists $data->{inner_units} && ref $data->{inner_units} eq 'HASH' )
	{
		foreach my $i( values %{$data->{inner_units}} )
		{
			$i->{i} = int $i->{i};
			$i->{color} = int $i->{color};
			if( exists $i->{offset} )
			{
				$i->{offset}[0] = int($i->{offset}[0]);
				$i->{offset}[1] = int($i->{offset}[1]);
			}
		}
	}
	return $data;
}

sub prepare_save_sqls
{
	my($u) = @_;
	my $sqls = $u->SUPER::prepare_save_sqls();
	push @$sqls, [
		'UPDATE fibers_cables SET xa=?, ya=?, xb=?, yb=?, joints=?, length=?, trunk=? WHERE id=?',
			$u->{xa}, $u->{ya}, $u->{xb}, $u->{yb}, $u->encode($u->{joints}), $u->{length}, $u->{trunk}, $u->{tied}
	];
	return $sqls;
}

sub check_data
{
	my $cls = shift;
	my $d = shift;
	my %fl = %Fibers::Units::fields_lengths;

	$d->{place_id} = 0;

	map{ $d->{$_} = substr $d->{$_}.'', 0, $fl{$_} } ( 'type', 'map_type', 'name', 'description', 'img' );
	map{ $d->{$_} = int $d->{$_} } ( 'x', 'y', 'x0', 'y0', 'tied', 'grp', 'nodeny_obj_id', 'removed', 'scheme_id' );

	my $bx = $fibers__xy_bounds->{x};
	my $by = $fibers__xy_bounds->{y};
	foreach my $i( '', '0', 'a', 'b' )
	{
		my $x = $d->{"x$i"};
		my $y = $d->{"y$i"};
		($x < -$bx || $x > $bx || $y < -$by || $y > $by) && return 'cable x'.$i.'y'.$i.' bounds';
	}

	ref $d->{inner_units} eq 'HASH' or return 'inner_units is not a hash';
	my $iu = $d->{inner_units};
	foreach my $id( keys %$iu )
	{
		$id =~ /^\d+$/ or return 'inner_units key is not a number';
		ref $iu->{$id} eq 'HASH' or return 'inner_units element is not a hash';
		my $iue = $iu->{$id};
		ref $iue->{offset} eq 'ARRAY' or return 'inner_units element offset is not an array';
		$iu->{$id} = {
			i => $id,
			offset => [ $iue->{offset}[0]+0, $iue->{offset}[1]+0 ],
			color => $iue->{color},
		};
	}

	my $add_data = $d->{add_data};
	ref $add_data eq 'HASH' or return 'add_data is not a hash';
	$d->{add_data} = {};
	foreach my $i( 'rotate', 'collapsed_coord', 'places' )  # no 'linked_scheme'
	{
		$d->{add_data}{$i} = $add_data->{$i} if exists $add_data->{$i};
	}

	my $add_data = $d->{add_data};
	$add_data->{places} ||= [0, 0];
	$d->{joints} ||= [];

	ref $add_data->{rotate} eq 'ARRAY' or return 'add_data__rotate is not an array';
	ref $add_data->{collapsed_coord} eq 'ARRAY' or return 'add_data__collapsed_coord is not an array';
	ref $add_data->{places} eq 'ARRAY' or return 'add_data__places is not a array';
	ref $d->{joints} eq 'ARRAY' or return 'joints is not an array';

	$add_data->{rotate} = [ $add_data->{rotate}[0]+0, $add_data->{rotate}[1]+0 ];
	$add_data->{places} = [ int $add_data->{places}[0], int $add_data->{places}[1] ];
	$add_data->{collapsed_coord} = [ $add_data->{collapsed_coord}[0]+0, $add_data->{collapsed_coord}[1]+0 ];

	my $joints = [];
	foreach my $j( @{$d->{joints}} )
	{
		my $i = { x => int($j->{x}), y => int($j->{y}) };
		$i->{place_id} = int($j->{place_id}) if int($j->{place_id}) > 0;
		$i->{subtype} = $j->{subtype} if $j->{subtype} eq 'only_map';
		push @$joints, $i;
	}
	$d->{joints} = $joints;

	return $d;
}

sub joint_change_position
{
	my($u, $x, $y, $joint_num, $is_map_view) = @_;
	$u->{add_data}{collapsed_coord} ||= [0, 0];

	if( $joint_num > 1 && $joint_num < 100 )
	{
		my $joint = $u->{joints}[$joint_num-2];
		$x = $joint->{x} = int($joint->{x} + $x);
		$y = $joint->{y} = int($joint->{y} + $y);
	}
	 elsif( $joint_num == 0 )
	{
		$x = $u->{x} = int($u->{x} + $x);
		$y = $u->{y} = int($u->{y} + $y);
	}
	 elsif( $joint_num == 1 )
	{
		$x = $u->{x0} = int($u->{x0} + $x);
		$y = $u->{y0} = int($u->{y0} + $y);
	}
	 else
	{
		return $u;
	}
	main::check_xy($x, $y);
	return $u;
}


sub change_position
{
	my($u, $x, $y) = @_;

	$u->{xa} += $x;
	$u->{ya} += $y;
	main::check_xy($u->{x} + $u->{xa}, $u->{y} + $u->{ya});

	$u->{xb} += $x;
	$u->{yb} += $y;
	main::check_xy($u->{x0} + $u->{xb}, $u->{y0} + $u->{yb});

	foreach my $i( @{$u->{joints}} )
	{
		$i->{x} += $x;
		$i->{y} += $y;
		main::check_xy($i->{x}, $i->{y});
	}

	return $u;
}


sub bounding_box
{
	my($u) = @_;
	my @joints = @{$u->{joints}};
	push @joints, { x => ($u->{x}  + $u->{xa}), y => ($u->{y}  + $u->{ya}) };
	push @joints, { x => ($u->{x0} + $u->{xb}), y => ($u->{y0} + $u->{yb}) };

	my @x = map{ $_->{x} } sort{ $a->{x} <=> $b->{x} } @joints;
	my @y = map{ $_->{y} } sort{ $a->{y} <=> $b->{y} } @joints;

	my $res = {
		x_min => $x[0],
		x_max => $x[-1],
		y_min => $y[0],
		y_max => $y[-1],
		width => $x[-1] - $x[0],
		height => $y[-1] - $y[0],
	};
	$res->{'center_x'} = ($res->{x_max} + $res->{x_min}) / 2;
	$res->{'center_y'} = ($res->{y_max} + $res->{y_min}) / 2;
	return $res;
}


package Fibers::Links;
use base 'Fibers';
use Debug;
main->import( qw( _ L Error ) );

sub db_table { return 'fibers_links' }

sub full_field_name
{
	my(undef, $f) = @_;
	return $f =~ /^(joints)$/ ? 'fibers_cables.'.$f : $f;
}

sub new
{
	my $cls = shift;
	my $u = {@_};
	$u->{joints} = $u->{joints} ? $cls->decode($u->{joints}) : [];
	bless $u, $cls;
	$u->{old} = $u->data();
	return $u;
}

sub get_by_id
{
	my($cls, $id, $params) = @_;
	$params->{without_transaction} or Db->begin_work or $cls->api_db_error();
	my $for_update = $params->{without_transaction} ? '' : "FOR UPDATE";
	my %p = Db->line(
		"SELECT l.*, c.joints FROM fibers_links l LEFT JOIN fibers_cables c ON l.tied=c.id ".
		"WHERE l.id=? AND l.scheme_id=? $for_update",
		$id, $Fibers::Scheme_id
	);
	%p or $cls->api_db_error();
	my $u = $cls->new(%p);
	if( $params->{get_color} )
	{
		%p = Db->line(
			"SELECT id, inner_units FROM fibers_units WHERE cls='cable' AND id IN (?, ?) LIMIT 1", $u->{src}, $u->{dst}
		);
		if( %p )
		{
			my $inner_units = $cls->decode($p{inner_units});
			my $inner_num = $u->{src} == $p{id} ? $u->{src_inner} : $u->{dst_inner};
			$u->{color} = $inner_units->{$inner_num}{color};
		}
	}
	return $u;
}

sub data
{
	my($u) = @_;
	my $data = Fibers::_data($u);
	foreach my $i( 'id', 'src', 'dst', 'src_inner', 'dst_inner', 'src_side', 'dst_side' )
	{
		$data->{$i} = int $data->{$i};
	}
	$data->{tied} = int $data->{tied};
	delete $data->{removed};
	delete $data->{scheme_id};
	delete $data->{comment} if $data->{comment} eq '';
	return $data;
}

sub create
{
	my($cls, $data, $action, $params)= @_;

	my $scheme_id = $Fibers::Scheme_id;
	my $id;

	if( ref $data->{joints} eq 'ARRAY' && scalar @{$data->{joints}} )
	{
		Db->do("INSERT INTO fibers_cables SET joints=?", $cls->encode($data->{joints}));
		Db->ok or $cls->api_db_error();
		$data->{tied} = Db::result->insertid;
	}
	 else
	{
		$data->{tied} = 0;
		$data->{joints} = [];
	}

	my $where = 'WHERE src=? AND src_inner=? AND dst=? AND dst_inner=? AND scheme_id=?';
	my $rows = Db->do(
		"UPDATE fibers_links SET removed=0, src_side=?, dst_side=?, comment=?, tied=? $where",
		$data->{src_side}, $data->{dst_side}, $data->{comment}, $data->{tied},
		$data->{src}, $data->{src_inner}, $data->{dst}, $data->{dst_inner}, $scheme_id
	);
	if( $rows < 1 )
	{
		Db->do(
			"INSERT INTO fibers_links SET ".
			"src=?, src_inner=?, src_side=?, dst=?, dst_inner=?, dst_side=?, comment=?, tied=?, scheme_id=?",
			$data->{src}, $data->{src_inner}, $data->{src_side},
			$data->{dst}, $data->{dst_inner}, $data->{dst_side},
			$data->{comment}, $data->{tied}, $scheme_id
		);
		Db->ok or $cls->api_db_error();
		$id = Db::result->insertid;
	}
	 else
	{
		my %p = Db->line(
			"SELECT id FROM fibers_links $where",
			$data->{src}, $data->{src_inner}, $data->{dst}, $data->{dst_inner}, $scheme_id
		);
		%p or $cls->api_db_error();
		$id = $p{id};
	}

	my $u = $cls->get_by_id($id, { without_transaction => $params->{without_transaction} });

	if( !$params->{no_history} )
	{
		my $back = { removed=>1 };
		my $forward = { removed=>0 };
		if( $params->{heap_history} )
		{
			push @$Fibers::History, {
				table   => $u->db_table(),
				id      => $u->{id},
				back    => $back,
				forward => $forward,
			};
		}
		 else
		{
			$u->into_history($action, $back, $forward) or $cls->api_db_error();
		}
	}

	if( !$params->{no_commit} && !Db->commit )
	{
		Db->rollback;
		$cls->api_db_error();
	}

	return $u;
}

sub prepare_save_sqls
{
	my($u) = @_;
	my $tied = int $u->{tied};
	my $sqls = [[
		'UPDATE fibers_links SET '.
			'src=?, src_inner=?, src_side=?, dst=?, dst_inner=?, dst_side=?, '.
			'comment=?, tied=? '.
		'WHERE id=?',
			$u->{src}, $u->{src_inner}, $u->{src_side}, $u->{dst}, $u->{dst_inner}, $u->{dst_side},
			$u->{comment}, $tied,
			$u->{id}
	]];

	$tied or return $sqls;

	push @$sqls, [
		'UPDATE fibers_cables SET joints=? WHERE id=?',
			$u->encode($u->{joints}), $tied
	];

	return $sqls;
}

sub joint_change_position
{
	my($link, $x, $y, $joint_num, $is_map_view) = @_;
	$is_map_view && return $link;

	if( $joint_num < 0 || $joint_num > 100 || $joint_num > scalar(@{$link->{joints}}) - 1 )
	{
		main::ApiError(L('joint_does_not_exist'));
	}
	my $joint = $link->{joints}[$joint_num];
	$x = $joint->{x} = int($joint->{x} + $x);
	$y = $joint->{y} = int($joint->{y} + $y);
	main::check_xy($x, $y);
	return $link;
}

=cut
+-----------+---------------------+------+-----+---------+
| Field     | Type                | Null | Key | Default |
+-----------+---------------------+------+-----+---------+
| id        | int(11) unsigned    | NO   | PRI | NULL    |
| scheme_id | int(11) unsigned    | NO   | MUL | NULL    |
| src       | int(11) unsigned    | NO   | MUL | NULL    |
| src_inner | int(11) unsigned    | NO   |     | NULL    |
| src_side  | tinyint(3) unsigned | NO   |     | 0       |
| dst       | int(11) unsigned    | NO   |     | NULL    |
| dst_inner | int(11) unsigned    | NO   |     | NULL    |
| dst_side  | tinyint(3) unsigned | NO   |     | 0       |
| comment   | varchar(64)         | NO   |     |         |
| removed   | tinyint(4)          | NO   |     | 0       |
| tied      | int(10) unsigned    | NO   |     | 0       |
+-----------+---------------------+------+-----+---------+
=cut

sub check_data
{
	my $cls = shift;
	my $d = shift;

	my %fl = %Fibers::Units::fields_lengths;

	$d->{comment} = substr $d->{comment}.'', 0, 64;
	map{ $d->{$_} = int $d->{$_} } ( 'src', 'src_inner', 'src_side', 'dst', 'dst_inner', 'dst_side', 'removed', 'tied', 'scheme_id' );

	$d->{joints} ||= [];
	ref $d->{joints} eq 'ARRAY' or return 'joints is not an array';

	my $joints = [];
	foreach my $j( @{$d->{joints}} )
	{
		push @$joints, { x => int($j->{x}), y => int($j->{y}) };
	}
	$d->{joints} = $joints;

	return $d;
}



package Fibers::Bookmarks;
use base 'Fibers';
use Debug;
main->import( qw( _ L Error ) );

sub db_table { return 'fibers_bookmarks' }

sub new
{
	my $cls = shift;
	my $u = {@_};
	bless $u, $cls;
	return $u;
}

sub data
{
	my($u) = @_;
	return Fibers::_data($u);
}

#<HOOK>end

1;
