CREATE TABLE IF NOT EXISTS `channels` (
  `prefix` tinytext DEFAULT NULL,
  `locale` tinytext DEFAULT NULL,
  `notify` int(11) DEFAULT NULL,
  `id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `dunce_instants` (
  `user_id` bigint(20) NOT NULL,
  `undunce_instant` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `dunce_instants_user_id_uindex` (`user_id`)
);

CREATE TABLE IF NOT EXISTS `dunce_stored_roles` (
  `user_id` bigint(20) NOT NULL,
  `role_id` bigint(20) NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`)
);

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(4) NOT NULL DEFAULT 1,
  `server` bigint(20) DEFAULT NULL,
  `creator` bigint(20) DEFAULT NULL,
  `target` tinytext NOT NULL,
  `target_id` bigint(20) NOT NULL DEFAULT 0,
  `permissions` bigint(20) NOT NULL,
  `unremovable` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
);

CREATE TABLE IF NOT EXISTS `pin_blacklist` (
  `server` bigint(20) NOT NULL,
  `channel` bigint(20) NOT NULL,
  PRIMARY KEY (`server`,`channel`),
  UNIQUE KEY `pin_blacklist_channel_uindex` (`channel`)
);

CREATE TABLE IF NOT EXISTS `pin_notifications` (
  `pinned_message` bigint(20) NOT NULL,
  `pin_notification` bigint(20) NOT NULL,
  PRIMARY KEY (`pinned_message`),
  UNIQUE KEY `pin_notifications_pin_notification_uindex` (`pin_notification`)
);

CREATE TABLE IF NOT EXISTS `ping_counts` (
  `user_id` bigint(20) NOT NULL,
  `ping_count` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `ping_counts_user_id_uindex` (`user_id`)
);

CREATE TABLE IF NOT EXISTS `ping_leaderboard` (
  `user_id` bigint(20) NOT NULL,
  `ping` int(11) NOT NULL,
  PRIMARY KEY (`user_id`)
);

CREATE TABLE IF NOT EXISTS `servers` (
  `prefix` tinytext DEFAULT NULL,
  `locale` tinytext DEFAULT NULL,
  `logging_channel` bigint(20) DEFAULT NULL,
  `streams_channel` varchar(45) DEFAULT NULL,
  `notify` int(11) NOT NULL,
  `monthly_clarifai_cap` int(11) NOT NULL,
  `clarifai_count` int(11) NOT NULL,
  `clarifai_reset_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `id` bigint(20) unsigned NOT NULL,
  `pin_emoji_unicode` varchar(45) DEFAULT NULL,
  `pin_emoji_custom` bigint(20) DEFAULT NULL,
  `pin_threshold` int(11) DEFAULT NULL,
  `pin_channel` bigint(20) DEFAULT NULL,
  `pin_editable` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
);

CREATE TABLE IF NOT EXISTS `user_connection_attempts` (
  `user_id` bigint(20) NOT NULL,
  `server_id` bigint(20) NOT NULL,
  `ip` varchar(45) NOT NULL,
  PRIMARY KEY (`user_id`,`server_id`,`ip`)
);

CREATE TABLE IF NOT EXISTS `user_records` (
  `id` bigint(20) NOT NULL,
  `server_id` bigint(20) NOT NULL,
  `discord_token` varchar(128) NOT NULL,
  `verified` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`,`server_id`)
);

CREATE TABLE IF NOT EXISTS `verified_connections` (
  `vc_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `server_id` bigint(20) NOT NULL,
  `id` varchar(45) NOT NULL,
  `connection_type` varchar(45) NOT NULL,
  `connection_name` varchar(45) NOT NULL,
  `token` varchar(256) DEFAULT NULL,
  `removed` tinyint(4) NOT NULL DEFAULT 0,
  `association_level` tinyint(4) NOT NULL DEFAULT 0,
  `association_tree` varchar(45) DEFAULT NULL,
  `notify` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`vc_id`)
);

CREATE TABLE IF NOT EXISTS `warnings` (
  `user_id` bigint(20) NOT NULL,
  `warning_instant` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reason` varchar(1024) DEFAULT NULL,
  `message_link` varchar(1024) NOT NULL,
  PRIMARY KEY (`user_id`,`warning_instant`)
);

-- Migration: ensure `verified_connections` has a surrogate `vc_id` primary key
-- This sequence is idempotent and safe to run on existing databases.
-- 1) Add `vc_id` column if missing (non-AUTO_INCREMENT)
SELECT COUNT(*) INTO @vc_exists FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='verified_connections' AND column_name='vc_id';
SET @sql = IF(@vc_exists=0, 'ALTER TABLE verified_connections ADD COLUMN vc_id BIGINT NOT NULL', 'SELECT "vc_id exists"');
PREPARE migrate_stmt FROM @sql; EXECUTE migrate_stmt; DEALLOCATE PREPARE migrate_stmt;

-- 2) Populate `vc_id` for existing rows where it's NULL or 0
SET @rownum = 0;
UPDATE verified_connections SET vc_id = (@rownum := @rownum + 1) WHERE vc_id IS NULL OR vc_id = 0 ORDER BY user_id, server_id, id;

-- 3) If primary key is not `vc_id`, replace it with `vc_id`
SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) INTO @pkcols FROM information_schema.KEY_COLUMN_USAGE WHERE table_schema=DATABASE() AND table_name='verified_connections' AND CONSTRAINT_NAME='PRIMARY';
SET @sql = IF(@pkcols IS NULL OR @pkcols <> 'vc_id', 'ALTER TABLE verified_connections DROP PRIMARY KEY, ADD PRIMARY KEY (vc_id)', 'SELECT "pk ok"');
PREPARE migrate_stmt FROM @sql; EXECUTE migrate_stmt; DEALLOCATE PREPARE migrate_stmt;

-- 4) Make `vc_id` AUTO_INCREMENT and set next AUTO_INCREMENT value
SELECT IFNULL(MAX(vc_id), 0) INTO @max_vc FROM verified_connections;
SET @sql = CONCAT('ALTER TABLE verified_connections MODIFY vc_id BIGINT NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=', @max_vc + 1);
PREPARE migrate_stmt FROM @sql; EXECUTE migrate_stmt; DEALLOCATE PREPARE migrate_stmt;

-- 5) (noop) we intentionally do not add a unique constraint so multiple rows
--    (eg. removed vs active) can coexist. `vc_id` is the sole primary key.
