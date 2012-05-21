CREATE TABLE `agents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `encrypted_password` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `reset_password_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `reset_password_sent_at` datetime DEFAULT NULL,
  `remember_created_at` datetime DEFAULT NULL,
  `sign_in_count` int(11) DEFAULT '0',
  `current_sign_in_at` datetime DEFAULT NULL,
  `last_sign_in_at` datetime DEFAULT NULL,
  `current_sign_in_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_sign_in_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_salt` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `confirmation_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `confirmation_sent_at` datetime DEFAULT NULL,
  `unconfirmed_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `failed_attempts` int(11) DEFAULT '0',
  `unlock_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `authentication_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `username` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_agents_on_email` (`email`),
  UNIQUE KEY `index_agents_on_reset_password_token` (`reset_password_token`),
  UNIQUE KEY `index_agents_on_confirmation_token` (`confirmation_token`),
  UNIQUE KEY `index_agents_on_unlock_token` (`unlock_token`),
  UNIQUE KEY `index_agents_on_authentication_token` (`authentication_token`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `clubs` (
  `description` text COLLATE utf8_unicode_ci,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `partner_id` bigint(20) DEFAULT NULL,
  `logo_file_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `logo_content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `logo_file_size` int(11) DEFAULT NULL,
  `logo_updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `communications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `template_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `scheduled_at` datetime DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `client` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_attributes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `template_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sent_success` tinyint(1) DEFAULT NULL,
  `request` text COLLATE utf8_unicode_ci,
  `response` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `credit_cards` (
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  `blacklisted` tinyint(1) DEFAULT '0',
  `encrypted_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expire_month` int(11) DEFAULT NULL,
  `expire_year` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `last_successful_bill_date` datetime DEFAULT NULL,
  `last_digits` varchar(4) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `decline_strategies` (
  `gateway` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `installment_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'monthly',
  `credit_card_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'all',
  `response_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `limit` int(11) DEFAULT '0',
  `days` int(11) DEFAULT '0',
  `decline_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'soft',
  `notes` text COLLATE utf8_unicode_ci,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) DEFAULT '0',
  `attempts` int(11) DEFAULT '0',
  `handler` text COLLATE utf8_unicode_ci,
  `last_error` text COLLATE utf8_unicode_ci,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `queue` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `delayed_jobs_priority` (`priority`,`run_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `domains` (
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `data_rights` text COLLATE utf8_unicode_ci,
  `partner_id` bigint(20) DEFAULT NULL,
  `hosted` tinyint(1) DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `club_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `email_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_attributes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `template_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `enumerations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `position` int(11) DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `visible` tinyint(1) DEFAULT '1',
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fulfillments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `product` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `renewable_at` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `member_notes` (
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_by_id` bigint(20) DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `disposition_type_id` int(11) DEFAULT NULL,
  `communication_type_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `members` (
  `visible_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `club_id` bigint(20) NOT NULL,
  `uuid` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `zip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `join_date` datetime DEFAULT NULL,
  `cancel_date` date DEFAULT NULL,
  `bill_date` date DEFAULT NULL,
  `next_retry_bill_date` date DEFAULT NULL,
  `created_by_id` int(11) DEFAULT NULL,
  `quota` int(11) DEFAULT '0',
  `recycled_times` int(11) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wrong_address` int(11) DEFAULT NULL,
  `wrong_phone_number` int(11) DEFAULT NULL,
  `blacklisted` tinyint(1) DEFAULT '0',
  `member_group_type_id` int(11) DEFAULT NULL,
  `enrollment_info` text COLLATE utf8_unicode_ci,
  `email_unsubscribed_at` date DEFAULT NULL,
  `reactivation_times` int(11) DEFAULT '0',
  `member_since_date` datetime DEFAULT NULL,
  PRIMARY KEY (`club_id`,`visible_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `operations` (
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `operation_date` datetime DEFAULT NULL,
  `created_by_id` int(11) DEFAULT NULL,
  `resource_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `resource_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `notes` text COLLATE utf8_unicode_ci,
  `operation_type` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `partners` (
  `prefix` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contract_uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `website_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `payment_gateway_configurations` (
  `report_group` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `merchant_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mode` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'development',
  `descriptor_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descriptor_phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order_mark` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `gateway` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `terms_of_memberships` (
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `club_id` bigint(20) DEFAULT NULL,
  `trial_days` int(11) DEFAULT '30',
  `mode` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'development',
  `needs_enrollment_approval` tinyint(1) DEFAULT '0',
  `grace_period` int(11) DEFAULT '0',
  `installment_amount` float DEFAULT '0',
  `installment_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT '30.days',
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `transactions` (
  `uuid` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `payment_gateway_configuration_id` bigint(20) DEFAULT NULL,
  `report_group` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `merchant_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descriptor_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `descriptor_phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order_mark` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `gateway` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `encrypted_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expire_month` int(11) DEFAULT NULL,
  `expire_year` int(11) DEFAULT NULL,
  `recurrent` tinyint(1) DEFAULT '0',
  `transaction_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `invoice_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `zip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` float DEFAULT NULL,
  `decline_strategy_id` bigint(20) DEFAULT NULL,
  `response` text COLLATE utf8_unicode_ci,
  `response_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `response_result` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `response_transaction_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `response_auth_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `credit_card_id` bigint(20) DEFAULT NULL,
  `refunded_amount` decimal(10,0) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('20120406144426');

INSERT INTO schema_migrations (version) VALUES ('20120411184315');

INSERT INTO schema_migrations (version) VALUES ('20120411222700');

INSERT INTO schema_migrations (version) VALUES ('20120413182202');

INSERT INTO schema_migrations (version) VALUES ('20120413230600');

INSERT INTO schema_migrations (version) VALUES ('20120413233029');

INSERT INTO schema_migrations (version) VALUES ('20120413234924');

INSERT INTO schema_migrations (version) VALUES ('20120414014459');

INSERT INTO schema_migrations (version) VALUES ('20120417234643');

INSERT INTO schema_migrations (version) VALUES ('20120418001504');

INSERT INTO schema_migrations (version) VALUES ('20120419001124');

INSERT INTO schema_migrations (version) VALUES ('20120419181211');

INSERT INTO schema_migrations (version) VALUES ('20120419232834');

INSERT INTO schema_migrations (version) VALUES ('20120425121141');

INSERT INTO schema_migrations (version) VALUES ('20120425172347');

INSERT INTO schema_migrations (version) VALUES ('20120427154823');

INSERT INTO schema_migrations (version) VALUES ('20120503183957');

INSERT INTO schema_migrations (version) VALUES ('20120506210619');

INSERT INTO schema_migrations (version) VALUES ('20120509160307');

INSERT INTO schema_migrations (version) VALUES ('20120509191136');

INSERT INTO schema_migrations (version) VALUES ('20120510145907');

INSERT INTO schema_migrations (version) VALUES ('20120510173417');

INSERT INTO schema_migrations (version) VALUES ('20120510174705');

INSERT INTO schema_migrations (version) VALUES ('20120510175757');

INSERT INTO schema_migrations (version) VALUES ('20120514180055');

INSERT INTO schema_migrations (version) VALUES ('20120514210600');

INSERT INTO schema_migrations (version) VALUES ('20120516172104');

INSERT INTO schema_migrations (version) VALUES ('20120517150111');

INSERT INTO schema_migrations (version) VALUES ('20120517152910');

INSERT INTO schema_migrations (version) VALUES ('20120518120706');

INSERT INTO schema_migrations (version) VALUES ('20120518134941');