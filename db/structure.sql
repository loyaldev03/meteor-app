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
  UNIQUE KEY `index_agents_on_authentication_token` (`authentication_token`),
  UNIQUE KEY `index_agents_on_confirmation_token` (`confirmation_token`),
  UNIQUE KEY `index_agents_on_reset_password_token` (`reset_password_token`),
  UNIQUE KEY `index_agents_on_unlock_token` (`unlock_token`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `club_cash_transactions` (
  `amount` decimal(11,2) DEFAULT '0.00',
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `club_roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `role` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
  `drupal_domain_id` bigint(20) DEFAULT NULL,
  `api_username` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `theme` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'application',
  `requires_external_id` tinyint(1) DEFAULT '0',
  `time_zone` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'UTC',
  `billing_enable` tinyint(1) DEFAULT '1',
  `cs_phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `family_memberships_allowed` tinyint(1) DEFAULT '0',
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `club_cash_enable` tinyint(1) DEFAULT '1',
  `marketing_tool_attributes` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `communications` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `scheduled_at` datetime DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `client` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_attributes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `template_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sent_success` tinyint(1) DEFAULT NULL,
  `response` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `credit_cards` (
  `active` tinyint(1) DEFAULT '1',
  `blacklisted` tinyint(1) DEFAULT '0',
  `expire_month` int(11) DEFAULT NULL,
  `expire_year` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `last_successful_bill_date` datetime DEFAULT NULL,
  `last_digits` varchar(4) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cc_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `aus_sent_at` datetime DEFAULT NULL,
  `aus_answered_at` datetime DEFAULT NULL,
  `aus_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `index2` (`member_id`),
  KEY `index_credit_card_on_token` (`token`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=988 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `domains` (
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `data_rights` text COLLATE utf8_unicode_ci,
  `partner_id` bigint(20) DEFAULT NULL,
  `hosted` tinyint(1) DEFAULT '0',
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `email_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_attributes` text COLLATE utf8_unicode_ci,
  `template_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `days_after_join_date` int(11) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1849 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `enrollment_infos` (
  `enrollment_amount` decimal(11,2) DEFAULT '0.00',
  `product_sku` text COLLATE utf8_unicode_ci,
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
  `campaign_medium_version` text COLLATE utf8_unicode_ci,
  `joint` tinyint(1) DEFAULT NULL,
  `prospect_id` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `membership_id` bigint(20) unsigned DEFAULT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `index_enrollment_info_on_member_id` (`member_id`),
  KEY `index_membership_id` (`membership_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=557 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fulfillment_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `initial_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `all_times` tinyint(1) DEFAULT '0',
  `product` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fulfillment_files_fulfillments` (
  `fulfillment_id` bigint(20) DEFAULT NULL,
  `fulfillment_file_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `fulfillments` (
  `product_sku` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `renewable_at` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `tracking_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `recurrent` tinyint(1) DEFAULT '0',
  `renewed` tinyint(1) DEFAULT '0',
  `product_package` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `index2` (`member_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `member_notes` (
  `created_by_id` int(11) DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `disposition_type_id` int(11) DEFAULT NULL,
  `communication_type_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `member_preferences` (
  `uuid` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `param` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `members` (
  `club_id` bigint(20) NOT NULL,
  `external_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `zip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bill_date` datetime DEFAULT NULL,
  `next_retry_bill_date` datetime DEFAULT NULL,
  `recycled_times` int(11) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `blacklisted` tinyint(1) DEFAULT '0',
  `member_group_type_id` int(11) DEFAULT NULL,
  `reactivation_times` int(11) DEFAULT '0',
  `member_since_date` datetime DEFAULT NULL,
  `wrong_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wrong_phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_synced_at` datetime DEFAULT NULL,
  `last_sync_error` text COLLATE utf8_unicode_ci,
  `club_cash_amount` decimal(11,2) DEFAULT '0.00',
  `club_cash_expire_date` datetime DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `preferences` text COLLATE utf8_unicode_ci,
  `last_sync_error_at` datetime DEFAULT NULL,
  `gender` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type_of_phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone_country_code` int(11) DEFAULT NULL,
  `phone_area_code` int(11) DEFAULT NULL,
  `phone_local_number` int(11) DEFAULT NULL,
  `autologin_url` text COLLATE utf8_unicode_ci,
  `current_membership_id` bigint(20) unsigned DEFAULT NULL,
  `sync_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'not_synced',
  `pardot_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pardot_last_synced_at` datetime DEFAULT NULL,
  `pardot_synced_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'not_synced',
  `pardot_last_sync_error` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pardot_last_sync_error_at` datetime DEFAULT NULL,
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `additional_data` text COLLATE utf8_unicode_ci,
  `manual_payment` tinyint(1) DEFAULT '0',
  `exact_target_last_synced_at` datetime DEFAULT NULL,
  `exact_target_synced_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'not_synced',
  `exact_target_last_sync_error` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exact_target_last_sync_error_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_UNIQUE` (`club_id`,`email`),
  UNIQUE KEY `api_id_UNIQUE` (`club_id`,`api_id`),
  KEY `index_members_on_club_id` (`club_id`),
  KEY `index_members_on_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `memberships` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `terms_of_membership_id` bigint(20) DEFAULT NULL,
  `join_date` datetime DEFAULT NULL,
  `cancel_date` datetime DEFAULT NULL,
  `created_by_id` int(11) DEFAULT NULL,
  `quota` int(11) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index2` (`member_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `operations` (
  `description` text COLLATE utf8_unicode_ci,
  `operation_date` datetime DEFAULT NULL,
  `created_by_id` int(11) DEFAULT NULL,
  `resource_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `resource_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `notes` text COLLATE utf8_unicode_ci,
  `operation_type` int(11) DEFAULT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `index2` (`member_id`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
  `aus_login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `aus_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `products` (
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sku` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `recurrent` tinyint(1) DEFAULT '0',
  `stock` int(11) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `club_id` bigint(20) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `package` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `allow_backorder` tinyint(1) DEFAULT '0',
  `cost_center` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `prospects` (
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `zip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `landing_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
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
  `campaign_medium_version` text COLLATE utf8_unicode_ci,
  `uuid` varchar(36) COLLATE utf8_unicode_ci NOT NULL,
  `club_id` int(11) DEFAULT NULL,
  `exact_target_sync_result` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`uuid`),
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
  `installment_amount` decimal(11,2) DEFAULT '0.00',
  `installment_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT '1.month',
  `deleted_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `club_cash_amount` decimal(11,2) DEFAULT '0.00',
  `quota` int(11) DEFAULT '1',
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `downgrade_tom_id` bigint(20) DEFAULT NULL,
  `api_role` varchar(255) COLLATE utf8_unicode_ci DEFAULT '91284557',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=193 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `transactions` (
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
  `amount` decimal(11,2) DEFAULT '0.00',
  `decline_strategy_id` bigint(20) DEFAULT NULL,
  `response` text COLLATE utf8_unicode_ci,
  `response_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `response_result` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `response_transaction_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `response_auth_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `credit_card_id` bigint(20) DEFAULT NULL,
  `refunded_amount` decimal(11,2) DEFAULT '0.00',
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `membership_id` bigint(20) unsigned DEFAULT NULL,
  `token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cc_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_digits` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `member_id` bigint(20) unsigned DEFAULT NULL,
  `uuid` varchar(36) COLLATE utf8_unicode_ci NOT NULL,
  `success` tinyint(1) DEFAULT '0',
  `operation_type` int(11) DEFAULT NULL,
  PRIMARY KEY (`uuid`),
  KEY `index_transactions_on_member_id` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('20120406144426');

INSERT INTO schema_migrations (version) VALUES ('20130328132324');

INSERT INTO schema_migrations (version) VALUES ('20130405170058');

INSERT INTO schema_migrations (version) VALUES ('20130408151755');

INSERT INTO schema_migrations (version) VALUES ('20130408190913');

INSERT INTO schema_migrations (version) VALUES ('20130409160840');

INSERT INTO schema_migrations (version) VALUES ('20130409171903');

INSERT INTO schema_migrations (version) VALUES ('20130416175952');

INSERT INTO schema_migrations (version) VALUES ('20130423130214');

INSERT INTO schema_migrations (version) VALUES ('20130429125143');

INSERT INTO schema_migrations (version) VALUES ('20130506172140');

INSERT INTO schema_migrations (version) VALUES ('20130506190054');

INSERT INTO schema_migrations (version) VALUES ('20130513131936');

INSERT INTO schema_migrations (version) VALUES ('20130516125825');

INSERT INTO schema_migrations (version) VALUES ('20130519155730');

INSERT INTO schema_migrations (version) VALUES ('20130521140313');

INSERT INTO schema_migrations (version) VALUES ('20130524123055');

INSERT INTO schema_migrations (version) VALUES ('20130529203536');

INSERT INTO schema_migrations (version) VALUES ('20130531173716');

INSERT INTO schema_migrations (version) VALUES ('20130604175210');

INSERT INTO schema_migrations (version) VALUES ('20130610160137');

INSERT INTO schema_migrations (version) VALUES ('20130625122416');

INSERT INTO schema_migrations (version) VALUES ('20130702172522');