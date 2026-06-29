
BEGIN;
INSERT INTO `card` (`id`, `card_key`, `name`, `image_url`, `args`, `modified`, `created`) VALUES (4, 'template-1', '左侧图标', 'https://statics.xspaceagi.com/images/template-1.png', '[{\"key\": \"title\", \"placeholder\": \"为标题选择数据来源\"}, {\"key\": \"content\", \"placeholder\": \"为内容选择数据来源\"}, {\"key\": \"image\", \"placeholder\": \"为图标选择数据来源\"}]', '2025-01-06 10:23:00', '2025-01-04 16:00:29');
INSERT INTO `card` (`id`, `card_key`, `name`, `image_url`, `args`, `modified`, `created`) VALUES (5, 'template-2', '右侧图标', 'https://statics.xspaceagi.com/images/template-2.png', '[{\"key\": \"title\", \"placeholder\": \"为标题选择数据来源\"}, {\"key\": \"content\", \"placeholder\": \"为内容选择数据来源\"}, {\"key\": \"image\", \"placeholder\": \"为图标选择数据来源\"}]', '2025-01-04 16:00:47', '2025-01-04 16:00:47');
INSERT INTO `card` (`id`, `card_key`, `name`, `image_url`, `args`, `modified`, `created`) VALUES (6, 'template-3', '无图标', 'https://statics.xspaceagi.com/images/template-3.png', '[{\"key\": \"title\", \"placeholder\": \"为标题选择数据来源\"}, {\"key\": \"content\", \"placeholder\": \"为内容选择数据来源\"}]', '2025-01-04 16:01:45', '2025-01-04 16:01:00');
INSERT INTO `card` (`id`, `card_key`, `name`, `image_url`, `args`, `modified`, `created`) VALUES (7, 'template-4', '中间图标', 'https://statics.xspaceagi.com/images/template-4.png', '[{\"key\": \"title\", \"placeholder\": \"为标题选择数据来源\"}, {\"key\": \"content\", \"placeholder\": \"为内容选择数据来源\"}, {\"key\": \"image\", \"placeholder\": \"为图标选择数据来源\"}]', '2025-01-04 16:01:22', '2025-01-04 16:01:22');
COMMIT;



BEGIN;
INSERT INTO `schedule_task` (`id`, `task_id`, `bean_id`, `cron`, `params`, `status`, `lock_time`, `exec_times`, `max_exec_times`, `modified`, `created`) VALUES (1, 'conversationApplicationService', 'conversationApplicationService', '0 0/10 * * * ?', '{}', 'CONTINUE', '2025-04-15 21:10:00', 3, 9223372036854775807, '2025-04-15 21:00:00', '2025-04-15 20:34:33');
INSERT INTO `schedule_task` (`id`, `task_id`, `bean_id`, `cron`, `params`, `status`, `lock_time`, `exec_times`, `max_exec_times`, `modified`, `created`) VALUES (2, 'spaceDeleteTaskService', 'spaceDeleteTaskService', '0/10 * * * * ?', '{}', 'CONTINUE', '2025-04-15 21:02:00', 164, 9223372036854775807, '2025-04-15 21:01:50', '2025-04-15 20:34:33');
COMMIT;


BEGIN;
INSERT INTO `space` (`id`, `_tenant_id`, `name`, `description`, `icon`, `creator_id`, `type`, `yn`, `modified`, `created`) VALUES (1, 1, '个人空间', '个人空间', NULL, 1743762321, 'Personal', 0, '2025-04-04 10:25:26', '2025-04-04 10:25:26');
INSERT INTO `space` (`id`, `_tenant_id`, `name`, `description`, `icon`, `creator_id`, `type`, `yn`, `modified`, `created`) VALUES (2, 1, '第一个团队空间', NULL, '', 1743762321, 'Team', 0, '2025-04-04 11:29:54', '2025-04-04 11:19:12');
COMMIT;

BEGIN;
INSERT INTO `space_user` (`id`, `_tenant_id`, `space_id`, `user_id`, `role`, `modified`, `created`) VALUES (1, 1, 1, 1743762321, 'Owner', '2025-04-04 10:25:26', '2025-04-04 10:25:26');
INSERT INTO `space_user` (`id`, `_tenant_id`, `space_id`, `user_id`, `role`, `modified`, `created`) VALUES (2, 1, 2, 1743762321, 'Owner', '2025-04-04 11:19:12', '2025-04-04 11:19:12');
COMMIT;



BEGIN;
INSERT INTO `tenant` (`id`, `name`, `description`, `status`, `domain`, `modified`, `created`) VALUES (1, '女娲智能体OS', '女娲智能体OS', 'Enabled', 'localhost', '2025-04-03 17:42:00', '2024-12-31 15:50:49');
COMMIT;



BEGIN;
insert into agent_platform.user (id, _tenant_id, uid, user_name, nick_name, avatar, status, role, password, reset_pass, email, phone, last_login_time, created, modified)
values  (1743762321, 1, '1743762321', 'admin', 'admin', null, 'Enabled', 'Admin', 'c8dc90833d72c907436763077ce76c67', 1, 'admin@nuwax.com', '', null, '2025-05-20 15:42:05', '2025-05-20 15:42:05');
COMMIT;

