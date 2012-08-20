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
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT '--- []',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_agents_on_email` (`email`),
  UNIQUE KEY `index_agents_on_reset_password_token` (`reset_password_token`),
  UNIQUE KEY `index_agents_on_confirmation_token` (`confirmation_token`),
  UNIQUE KEY `index_agents_on_unlock_token` (`unlock_token`),
  UNIQUE KEY `index_agents_on_authentication_token` (`authentication_token`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `club_cash_transactions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` bigint(20) DEFAULT '0',
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=118 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `club_roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) DEFAULT NULL,
  `club_id` int(11) DEFAULT NULL,
  `role` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
  `drupal_domain_id` bigint(20) DEFAULT NULL,
  `api_username` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `theme` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'application',
  `requires_external_id` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `communications` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
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
  PRIMARY KEY (`id`),
  KEY `index_communications_on_member_id` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
  `cc_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_credit_cards_on_member_id` (`member_id`)
) ENGINE=InnoDB AUTO_INCREMENT=269365 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
  `hosted` tinyint(1) DEFAULT '0',
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `club_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `email_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_attributes` text COLLATE utf8_unicode_ci,
  `template_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `days_after_join_date` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `enrollment_infos` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `enrollment_amount` float DEFAULT NULL,
  `product_sku` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `product_description` text COLLATE utf8_unicode_ci,
  `mega_channel` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `marketing_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fulfillment_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `referral_host` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `referral_parameters` text COLLATE utf8_unicode_ci,
  `referral_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `landing_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `preferences` text COLLATE utf8_unicode_ci,
  `cookie_value` text COLLATE utf8_unicode_ci,
  `cookie_set` tinyint(1) DEFAULT NULL,
  `campaign_medium` text COLLATE utf8_unicode_ci,
  `campaign_description` text COLLATE utf8_unicode_ci,
  `campaign_medium_version` int(11) DEFAULT NULL,
  `joint` tinyint(1) DEFAULT NULL,
  `prospect_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fulfillments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `product` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `renewable_at` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `tracking_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `recurrent` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3112 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `member_notes` (
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_by_id` bigint(20) DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `disposition_type_id` int(11) DEFAULT NULL,
  `communication_type_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `index_member_notes_on_member_id` (`member_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12886 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `member_preferences` (
  `uuid` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `enrollment_info_id` bigint(20) DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `member_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `param` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `members` (
  `visible_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `club_id` bigint(20) NOT NULL,
  `uuid` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
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
  `blacklisted` tinyint(1) DEFAULT '0',
  `member_group_type_id` int(11) DEFAULT NULL,
  `email_unsubscribed_at` date DEFAULT NULL,
  `reactivation_times` int(11) DEFAULT '0',
  `member_since_date` datetime DEFAULT NULL,
  `wrong_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wrong_phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_synced_at` datetime DEFAULT NULL,
  `last_sync_error` text COLLATE utf8_unicode_ci,
  `club_cash_amount` bigint(20) DEFAULT '0',
  `joint` tinyint(1) DEFAULT '0',
  `club_cash_expire_date` date DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `preferences` text COLLATE utf8_unicode_ci,
  `last_sync_error_at` datetime DEFAULT NULL,
  `gender` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type_of_phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone_country_code` int(11) DEFAULT NULL,
  `phone_area_code` int(11) DEFAULT NULL,
  `phone_local_number` int(11) DEFAULT NULL,
  `autologin_url` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`club_id`,`visible_id`),
  UNIQUE KEY `index_members_on_uuid` (`uuid`),
  KEY `index_members_on_email` (`email`),
  KEY `index_members_on_club_id` (`club_id`)
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
  PRIMARY KEY (`id`),
  KEY `index_operations_on_member_id` (`member_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15092 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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

CREATE TABLE `products` (
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sku` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `recurrent` tinyint(1) DEFAULT '0',
  `stock` int(11) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `prospects` (
  `uuid` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `zip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `landing_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `preferences` text COLLATE utf8_unicode_ci,
  `product_sku` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mega_channel` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `marketing_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `referral_host` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `referral_parameters` text COLLATE utf8_unicode_ci,
  `cookie_value` text COLLATE utf8_unicode_ci,
  `joint` tinyint(1) DEFAULT '0',
  `phone_country_code` int(11) DEFAULT NULL,
  `phone_area_code` int(11) DEFAULT NULL,
  `phone_local_number` int(11) DEFAULT NULL,
  `type_of_phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `gender` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cookie_set` tinyint(1) DEFAULT NULL,
  `referral_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `product_description` text COLLATE utf8_unicode_ci,
  `fulfillment_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `campaign_medium` text COLLATE utf8_unicode_ci,
  `campaign_description` text COLLATE utf8_unicode_ci,
  `campaign_medium_version` int(11) DEFAULT NULL,
  UNIQUE KEY `index_prospects_on_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `terms_of_memberships` (
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `club_id` bigint(20) DEFAULT NULL,
  `provisional_days` int(11) DEFAULT '30',
  `mode` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'development',
  `needs_enrollment_approval` tinyint(1) DEFAULT '0',
  `grace_period` int(11) DEFAULT '0',
  `installment_amount` float DEFAULT '0',
  `installment_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT '30.days',
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `club_cash_amount` int(11) DEFAULT NULL,
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
  `refunded_amount` float DEFAULT '0',
  `enrollment_info_id` int(11) DEFAULT NULL,
  `join_date` datetime DEFAULT NULL,
  `cohort` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  UNIQUE KEY `index_transactions_on_uuid` (`uuid`)
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

INSERT INTO schema_migrations (version) VALUES ('20120507185841');

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

INSERT INTO schema_migrations (version) VALUES ('20120521150600');

INSERT INTO schema_migrations (version) VALUES ('20120521181809');

INSERT INTO schema_migrations (version) VALUES ('20120521235718');

INSERT INTO schema_migrations (version) VALUES ('20120522152656');

INSERT INTO schema_migrations (version) VALUES ('20120524154213');

INSERT INTO schema_migrations (version) VALUES ('20120528174051');

INSERT INTO schema_migrations (version) VALUES ('20120530221538');

INSERT INTO schema_migrations (version) VALUES ('20120601165634');

INSERT INTO schema_migrations (version) VALUES ('20120601175952');

INSERT INTO schema_migrations (version) VALUES ('20120604151244');

INSERT INTO schema_migrations (version) VALUES ('20120606141629');

INSERT INTO schema_migrations (version) VALUES ('20120607144647');

INSERT INTO schema_migrations (version) VALUES ('20120607154846');

INSERT INTO schema_migrations (version) VALUES ('20120608223149');

INSERT INTO schema_migrations (version) VALUES ('20120614180258');

INSERT INTO schema_migrations (version) VALUES ('20120620160033');

INSERT INTO schema_migrations (version) VALUES ('20120621211638');

INSERT INTO schema_migrations (version) VALUES ('20120621213008');

INSERT INTO schema_migrations (version) VALUES ('20120625171855');

INSERT INTO schema_migrations (version) VALUES ('20120627161226');

INSERT INTO schema_migrations (version) VALUES ('20120629122118');

INSERT INTO schema_migrations (version) VALUES ('20120629160352');

INSERT INTO schema_migrations (version) VALUES ('20120629171434');

INSERT INTO schema_migrations (version) VALUES ('20120702160318');

INSERT INTO schema_migrations (version) VALUES ('20120702165859');

INSERT INTO schema_migrations (version) VALUES ('20120703130216');

INSERT INTO schema_migrations (version) VALUES ('20120703132710');

INSERT INTO schema_migrations (version) VALUES ('20120703134504');

INSERT INTO schema_migrations (version) VALUES ('20120706133424');

INSERT INTO schema_migrations (version) VALUES ('20120706142527');

INSERT INTO schema_migrations (version) VALUES ('20120706145800');

INSERT INTO schema_migrations (version) VALUES ('20120706163030');

INSERT INTO schema_migrations (version) VALUES ('20120708203028');

INSERT INTO schema_migrations (version) VALUES ('20120710115812');

INSERT INTO schema_migrations (version) VALUES ('20120710182053');

INSERT INTO schema_migrations (version) VALUES ('20120712140444');

INSERT INTO schema_migrations (version) VALUES ('20120717122131');

INSERT INTO schema_migrations (version) VALUES ('20120718115700');

INSERT INTO schema_migrations (version) VALUES ('20120724152219');

INSERT INTO schema_migrations (version) VALUES ('20120727124711');

INSERT INTO schema_migrations (version) VALUES ('20120731125708');

INSERT INTO schema_migrations (version) VALUES ('20120731180421');

INSERT INTO schema_migrations (version) VALUES ('20120802165259');

INSERT INTO schema_migrations (version) VALUES ('20120803164002');

INSERT INTO schema_migrations (version) VALUES ('20120803182303');

INSERT INTO schema_migrations (version) VALUES ('20120803195357');

INSERT INTO schema_migrations (version) VALUES ('20120803223204');

INSERT INTO schema_migrations (version) VALUES ('20120809211347');

INSERT INTO schema_migrations (version) VALUES ('20120810133905');

INSERT INTO schema_migrations (version) VALUES ('20120813143725');

INSERT INTO schema_migrations (version) VALUES ('20120813151533');