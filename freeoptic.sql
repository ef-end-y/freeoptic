SET NAMES 'utf8' COLLATE 'utf8_general_ci';

CREATE TABLE `admin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(32) NOT NULL,
  `passwd` varchar(32) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '',
  `privil` varchar(1023) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `admin` (`login`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `changes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tbl` char(32) NOT NULL,
  `act` enum('create','edit','delete') NOT NULL DEFAULT 'create',
  `time` int(10) unsigned NOT NULL DEFAULT '0',
  `fid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `adm` mediumint(9) unsigned NOT NULL DEFAULT '0',
  `old_data` longtext NOT NULL,
  `new_data` longtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tbl` (`tbl`,`act`,`fid`),
  KEY `time` (`time`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time` int(11) NOT NULL DEFAULT '0',
  `data` mediumtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `webses_data` (
  `role` varchar(32) NOT NULL,
  `aid` mediumint(8) unsigned NOT NULL,
  `unikey` varchar(200) NOT NULL,
  `module` varchar(32) NOT NULL,
  `data` longtext NOT NULL,
  `created` int(10) unsigned NOT NULL,
  `expire` int(10) unsigned NOT NULL,
  UNIQUE KEY `unikey` (`unikey`),
  KEY `aid` (`aid`),
  KEY `expire` (`expire`),
  KEY `role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `websessions` (
  `ses` varchar(200) NOT NULL,
  `uid` int(11) NOT NULL,
  `role` varchar(32) NOT NULL,
  `trust` tinyint(4) NOT NULL DEFAULT '1',
  `expire` int(10) unsigned NOT NULL,
  UNIQUE KEY `ses` (`ses`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_bookmarks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `grp` int unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `x` float NOT NULL DEFAULT '0',
  `y` float NOT NULL DEFAULT '0',
  `zoom` float NOT NULL DEFAULT '0',
  `removed` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `owner` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_cable_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `type` varchar(32) NOT NULL DEFAULT '',
  `color` varchar(8) NOT NULL DEFAULT 'FF0000',
  `line_width` tinyint unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `scheme_id` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_cables` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `xa` int NOT NULL DEFAULT '0',
  `ya` int NOT NULL DEFAULT '0',
  `xb` int NOT NULL DEFAULT '0',
  `yb` int NOT NULL DEFAULT '0',
  `joints` text NOT NULL,
  `length` int NOT NULL DEFAULT '0',
  `trunk` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_colors` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `color` varchar(32) NOT NULL DEFAULT '',
  `description` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_colors_presets` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `description` varchar(32) NOT NULL DEFAULT '',
  `colors` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_container_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `type` varchar(32) NOT NULL DEFAULT '',
  `color` varchar(8) NOT NULL DEFAULT 'FF0000',
  `shape` varchar(4) NOT NULL DEFAULT 'f111',
  `size` tinyint unsigned NOT NULL DEFAULT '20',
  `hide_on_zoom` tinyint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `scheme_id` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_history` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `time` int unsigned NOT NULL DEFAULT '0',
  `action` varchar(128) NOT NULL DEFAULT '',
  `entity_id` int unsigned NOT NULL DEFAULT '0',
  `data` text NOT NULL,
  `actual` tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `owner` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_inner_units` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `unit_id` int unsigned NOT NULL,
  `inner_id` int unsigned NOT NULL,
  `remote_id` varchar(32) NOT NULL DEFAULT '',
  `tx_power` decimal(3,3) NOT NULL DEFAULT '0.000',
  `rx_power` decimal(3,3) NOT NULL DEFAULT '0.000',
  PRIMARY KEY (`id`),
  UNIQUE KEY `inner` (`scheme_id`,`unit_id`,`inner_id`),
  KEY `scheme_id` (`scheme_id`),
  KEY `remote_id` (`remote_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_links` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `src` int unsigned NOT NULL,
  `src_inner` int unsigned NOT NULL,
  `src_side` tinyint unsigned NOT NULL DEFAULT '0',
  `dst` int unsigned NOT NULL,
  `dst_inner` int unsigned NOT NULL,
  `dst_side` tinyint unsigned NOT NULL DEFAULT '0',
  `comment` varchar(64) NOT NULL DEFAULT '',
  `removed` tinyint NOT NULL DEFAULT '0',
  `tied` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `dbl` (`src`,`src_inner`,`dst`,`dst_inner`),
  KEY `owner` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_schemes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `gid` varchar(32) NOT NULL,
  `uid` int NOT NULL DEFAULT '0',
  `shared` tinyint NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `parent` int unsigned NOT NULL DEFAULT '0',
  `lat` float NOT NULL DEFAULT '0',
  `lng` float NOT NULL DEFAULT '0',
  `external_db` varchar(255) NOT NULL DEFAULT '',
  `favorite` tinyint NOT NULL DEFAULT '1',
  `is_block` tinyint NOT NULL DEFAULT '0',
  `inner_data_db` varchar(255) NOT NULL DEFAULT '',
  `inner_data_db_fields` varchar(255) NOT NULL DEFAULT '',
  `settings` varchar(1024) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `gid` (`gid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_trunk_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `type` int unsigned NOT NULL,
  `descr_uk` varchar(32) NOT NULL DEFAULT '',
  `descr_ru` varchar(32) NOT NULL DEFAULT '',
  `descr_en` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_trunks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `name_uk` varchar(64) NOT NULL DEFAULT '',
  `name_ru` varchar(64) NOT NULL DEFAULT '',
  `comment` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `scheme_id` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `fibers_units` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` int unsigned NOT NULL,
  `cls` varchar(32) NOT NULL DEFAULT '',
  `type` varchar(32) NOT NULL DEFAULT '',
  `map_type` int NOT NULL DEFAULT '0',
  `name` varchar(64) NOT NULL DEFAULT '',
  `description` varchar(128) NOT NULL DEFAULT '',
  `place_id` int unsigned NOT NULL DEFAULT '0',
  `tied` int unsigned NOT NULL DEFAULT '0',
  `grp` int unsigned NOT NULL DEFAULT '0',
  `x` int NOT NULL DEFAULT '0',
  `y` int NOT NULL DEFAULT '0',
  `x0` int NOT NULL DEFAULT '0',
  `y0` int NOT NULL DEFAULT '0',
  `inner_units` text NOT NULL,
  `add_data` text NOT NULL,
  `img` varchar(5) NOT NULL DEFAULT '',
  `removed` tinyint NOT NULL DEFAULT '0',
  `lat` float(15,12) NOT NULL DEFAULT '0.000000000000',
  `lng` float(15,12) NOT NULL DEFAULT '0.000000000000',
  `nodeny_obj_id` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `type` (`type`),
  KEY `owner` (`scheme_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

INSERT INTO `fibers_colors` VALUES
  (1,'blue','синий'),
  (2,'orange','оранжевый'),
  (3,'green','зеленый'),
  (4,'brown','коричневый'),
  (5,'#505050','серый'),
  (6,'#d0d0d0','белый'),
  (7,'red','красный'),
  (8,'black','черный'),
  (9,'yellow','желтый'),
  (10,'violet','фиолетовый'),
  (11,'#ffe4e1','розовый'),
  (12,'aqua','аквамарин'),
  (13,'#00bfff','голубой'),
  (14,'#7fffd4','бирюзовый'),
  (15,'blue black','синий+'),
  (16,'orange black','оранжевый+'),
  (17,'green black','зеленый+'),
  (18,'brown black','коричневый+'),
  (19,'grey black','серый+'),
  (20,'#e0e0e0 #000000 #e0e0e0 #000000','белый+'),
  (21,'red black','красный+'),
  (22,'#d0d0d0 yellow','черный+'),
  (23,'yellow black','желтый+'),
  (24,'violet black','фиолетовый+'),
  (25,'#ffe4e1 black','розовый+'),
  (26,'aqua black','бирюзовый+'),
  (27,'#00bfff black','голубой+'),
  (28,'#7fffd4 black','аквамарин+');


INSERT INTO `fibers_colors_presets` VALUES
  (1,0,'EIA598', '1,2,3,4,5,6,7,8,9,10,11,12,15,16,17,18,19,20,21,22,23,24,25,26'),
  (2,0,'UZ-CABLE','6,7,1,3,9,10,2,4,12,11,5,8'),
  (3,0,'ODESSA-CABLE', '7,3,13,9,6,5,4,10,2,8,11,14'),
  (4,0,'Premise', '2,5,1,3,9,7,5,10');
