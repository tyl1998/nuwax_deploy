-- 平台使用,定义mysql单独一个数据库
CREATE DATABASE IF NOT EXISTS agent_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- 数据表组件使用,定义mysql单独一个数据库
CREATE DATABASE IF NOT EXISTS agent_custom_table CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON agent_platform.* TO 'agent_platform'@'%';
GRANT ALL PRIVILEGES ON agent_custom_table.* TO 'agent_platform'@'%';
FLUSH PRIVILEGES;


USE agent_platform;

create table agent_component_config
(
    id            bigint auto_increment
        primary key,
    _tenant_id    bigint   default 1                 not null comment '商户ID',
    name          varchar(64)                        null comment '节点名称',
    icon          varchar(255)                       null comment '组件图标',
    description   text                               null comment '组件描述',
    agent_id      bigint                             null comment 'AgentID',
    type          varchar(64)                        not null comment '组件类型',
    target_id     bigint                             null comment '关联的组件ID',
    bind_config   json                               null comment '组件绑定配置',
    exception_out tinyint  default 0                 not null comment '异常是否抛出，中断主要流程',
    fallback_msg  text                               null comment '异常时兜底内容',
    modified      datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created       datetime default CURRENT_TIMESTAMP not null
)
    comment '智能体组件配置';

create table agent_config
(
    id                    bigint auto_increment comment '智能体ID'
        primary key,
    uid                   varchar(64)                                      not null comment 'agent唯一标识',
    type                  varchar(32)            default 'ChatBot'         not null comment '智能体类型',
    _tenant_id            bigint                 default -1                not null comment '商户ID',
    space_id              bigint                                           null comment '空间ID',
    creator_id            bigint                                           not null comment '创建者ID',
    name                  varchar(64)                                      not null comment 'Agent名称',
    description           varchar(2000)                                    null comment 'Agent描述',
    icon                  varchar(255)                                     null comment '图标地址',
    system_prompt         mediumtext                                       null comment '系统提示词',
    user_prompt           text                                             null comment '用户消息提示词，{{AGENT_USER_MSG}}引用用户消息',
    open_suggest          enum ('Open', 'Close') default 'Open'            not null comment '是否开启问题建议',
    suggest_prompt        text                                             null comment '用户问题建议',
    opening_chat_msg      mediumtext                                       null comment '首次打开聊天框自动回复消息',
    opening_guid_question json                                             null comment '开场引导问题',
    open_long_memory      enum ('Open', 'Close') default 'Open'            not null comment '是否开启长期记忆',
    open_scheduled_task   varchar(32)                                      null comment '开启定时任务',
    publish_status        varchar(32)            default 'Developing'      not null comment 'Agent发布状态',
    dev_conversation_id   bigint                                           null,
    expand_page_area      tinyint                default 0                 not null comment '默认展开页面区域',
    hide_chat_area        tinyint                default 0                 not null comment '隐藏对话框',
    extra                 json                                             null comment '扩展信息',
    access_control        tinyint                default 0                 not null comment '是否受权限管控，0 不受管控；1 受控',
    hide_desktop          tinyint(1)             default 0                 not null comment '远程桌面展示控制：0 不隐藏；1 隐藏',
    allow_other_model     tinyint(1)             default 0                 not null comment '是否允许在对话框中选择其他模型',
    allow_at_skill        tinyint(1)             default 1                 not null comment '是否允许@技能',
    allow_private_sandbox tinyint(1)             default 1                 not null comment '是否允许使用自己的电脑',
    yn                    tinyint                default 0                 not null comment '逻辑删除，1为删除',
    modified              datetime               default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created               datetime               default CURRENT_TIMESTAMP not null comment '创建时间'
);

create index idx_space_id
    on agent_config (space_id);

create table agent_temp_chat
(
    id            bigint auto_increment
        primary key,
    _tenant_id    bigint                             not null,
    user_id       bigint                             not null comment '创建链接的用户ID',
    agent_id      bigint                             not null,
    chat_key      varchar(64)                        not null comment '临时会话标识',
    require_login tinyint  default 1                 not null comment '是否需要登录 1 是，0 否',
    expire        datetime                           null,
    modified      datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created       datetime default CURRENT_TIMESTAMP not null
);

create table card
(
    id        bigint auto_increment
        primary key,
    card_key  varchar(32)                        not null comment '卡片唯一标识，与前端组件做关联',
    name      varchar(64)                        not null comment '卡片名称',
    image_url varchar(255)                       null comment '卡片示例图片地址',
    args      json                               null comment '卡片参数',
    modified  datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created   datetime default CURRENT_TIMESTAMP not null
);

create table category
(
    id          bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id  bigint                             not null comment '租户ID',
    name        varchar(255)                       not null comment '分类名称',
    description varchar(500)                       null comment '分类描述',
    code        varchar(100)                       not null comment '分类编码',
    type        varchar(50)                        not null comment '分类类型：Agent、PageApp、Component',
    created     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modified    datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    constraint uk_tenant_code
        unique (_tenant_id, type, code)
)
    comment '分类管理表' collate = utf8mb4_unicode_ci;

create table config_history
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint                                        not null,
    op_user_id  bigint                                        null comment '操作用户',
    target_id   bigint                                        not null comment '目标对象ID',
    target_type enum ('Agent', 'Plugin', 'Workflow', 'Skill') not null comment '目标对象类型',
    type        varchar(64)                                   not null comment '历史记录类型',
    config      json                                          null comment '当时的配置',
    description varchar(255)                                  null comment '变更描述',
    modified    datetime default CURRENT_TIMESTAMP            not null on update CURRENT_TIMESTAMP comment '更新时间',
    created     datetime default CURRENT_TIMESTAMP            not null
);

create index target_id
    on config_history (target_type, target_id);

create table content_i18n
(
    id        bigint auto_increment comment 'ID'
        primary key,
    model     varchar(32)                        not null comment '业务模块标记',
    mid       varchar(32)                        not null comment '业务模块ID',
    lang      varchar(16)                        not null comment '语言，中文：zh-cn，英文:en-us',
    field_key varchar(64)                        not null comment '业务表字段',
    content   mediumtext                         null comment '具体内容',
    modified  datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created   datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    constraint uk_lang_content
        unique (model, mid, lang, field_key)
)
    comment '内容国际化表';

create table conversation
(
    id                 bigint auto_increment
        primary key,
    _tenant_id         bigint                                not null comment '商户ID',
    uid                varchar(64)                           not null comment '会话唯一标识',
    user_id            bigint                                not null comment '用户ID',
    agent_id           bigint                                not null comment '智能体ID',
    topic              varchar(255)                          not null comment '主题',
    summary            mediumtext                            null comment '汇总',
    variables          json                                  null comment '用户输入的变量值',
    dev_mode           tinyint     default 0                 not null,
    topic_updated      tinyint     default 0                 not null,
    type               varchar(32) default 'Chat'            not null comment '会话类型，Chat对话；Task 定时任务',
    task_id            varchar(64)                           null comment '对应的任务ID',
    task_status        varchar(32)                           null comment '任务状态',
    task_cron          varchar(32)                           null comment '任务配置',
    sandbox_server_id  varchar(64)                           null comment 'agent沙箱服务器编码',
    sandbox_session_id varchar(64)                           null comment '保存沙箱agent返回的session_id',
    modified           datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created            datetime    default CURRENT_TIMESTAMP not null comment '创建时间'
)
    comment '会话表';

create index idx_type_status
    on conversation (type, task_status);

create index idx_uid
    on conversation (uid);

create index idx_user_id
    on conversation (user_id);

create index modified
    on conversation (modified);

create index sandbox_server_id
    on conversation (sandbox_server_id);

create table conversation_message
(
    id              bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id      bigint                             null comment '租户ID',
    user_id         bigint                             null comment '用户ID',
    agent_id        bigint                             null comment '智能体ID',
    conversation_id bigint                             null comment '会话ID',
    message_id      varchar(255)                       null comment '消息ID',
    content         mediumtext                         null comment '消息内容',
    modified        datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '修改时间',
    created         datetime default CURRENT_TIMESTAMP null comment '创建时间'
)
    comment '对话消息表' collate = utf8mb4_unicode_ci;

create index idx_conversation_id
    on conversation_message (conversation_id);

create index idx_message_id
    on conversation_message (message_id);

create index idx_user_id
    on conversation_message (user_id);

create table custom_field_definition
(
    id                bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id        bigint                               not null comment '租户ID',
    space_id          bigint                               not null comment '所属空间ID',
    table_id          bigint                               not null comment '关联的表ID',
    field_name        varchar(64)                          not null comment '字段名',
    field_description varchar(200)                         null comment '字段描述',
    field_type        tinyint    default 1                 not null comment '字段类型：1:String;2:Integer;3:Number;4:Boolean;5:Date',
    nullable_flag     tinyint(1) default 1                 not null comment '是否可为空：1-可空 -1-非空',
    default_value     varchar(255)                         null comment '默认值',
    unique_flag       tinyint(1) default -1                not null comment '是否唯一：1-唯一 -1-非唯一',
    enabled_flag      tinyint(1) default 1                 not null comment '是否启用：1-启用 -1-禁用',
    sort_index        int                                  not null comment '字段顺序',
    created           datetime   default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id        bigint                               null comment '创建人id',
    creator_name      varchar(64)                          null comment '创建人',
    modified          datetime   default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id       bigint                               null comment '最后修改人id',
    modified_name     varchar(64)                          null comment '最后修改人',
    yn                tinyint    default 1                 null comment '逻辑标记,1:有效;-1:无效',
    system_field_flag tinyint    default -1                not null comment '是否系统字段;1:系统字段;-1:否',
    field_str_len     int                                  null comment '字符串字段长度,可空,比如字符串,可以指定长度使用',
    constraint uk_table_field
        unique (table_id, field_name)
)
    comment '自定义字段定义';

create index idx_table_id
    on custom_field_definition (table_id);

create table custom_page_build
(
    id                   bigint auto_increment comment '主键ID'
        primary key,
    project_id           bigint                             not null comment '项目ID',
    dev_running          tinyint  default -1                not null comment '开发服务器运行标记,1:运行中;-1:未运行',
    dev_pid              int                                null comment '开发服务器进程ID',
    dev_port             int                                null comment '开发服务器端口号',
    last_keep_alive_time datetime                           null comment '最后保活时间',
    build_running        tinyint  default -1                not null comment '线上运行标记,1:运行中;-1:未运行',
    build_time           datetime                           null comment '构建发布时间',
    build_version        int                                null comment '发布的版本号',
    code_version         int                                not null comment '代码版本',
    version_info         json                               null comment '版本信息',
    last_chat_model_id   bigint                             null comment '上次对话模型ID',
    last_multi_model_id  bigint                             null comment '上次多模态模型ID',
    _tenant_id           bigint                             not null comment '租户ID',
    space_id             bigint                             null comment '空间ID',
    created              datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id           bigint                             null comment '创建人ID',
    creator_name         varchar(64)                        null comment '创建人',
    modified             datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id          bigint                             null comment '最后修改人ID',
    modified_name        varchar(64)                        null comment '最后修改人',
    yn                   tinyint  default 1                 not null comment '逻辑标记,1:有效;-1:无效'
)
    comment '用户项目构建管理';

create index idx_dev_running_yn
    on custom_page_build (dev_running, yn);

create index idx_project_yn
    on custom_page_build (project_id, yn);

create table custom_page_config
(
    id                    bigint auto_increment comment '主键ID'
        primary key,
    name                  varchar(255)                       not null comment '项目名称',
    description           varchar(255)                       null comment '项目描述',
    icon                  varchar(500)                       null comment '项目图标',
    cover_img             varchar(500)                       null comment '封面图片',
    cover_img_source_type varchar(500)                       null comment '封面图片来源',
    base_path             varchar(255)                       not null comment '项目基础路径',
    build_running         tinyint                            not null comment '线上运行标记,1:运行中;-1:未运行',
    publish_type          varchar(100)                       null,
    need_login            tinyint                            null comment '是否需要登陆,1:需要',
    dev_agent_id          bigint                             null comment '开发关联智能体ID',
    project_type          varchar(100)                       not null comment '项目类型',
    proxy_config          json                               null comment '代理配置',
    page_arg_config       json                               null comment '路径参数配置',
    data_sources          json                               null comment '绑定的数据源',
    ext                   json                               null comment '扩展参数',
    _tenant_id            bigint                             not null comment '租户ID',
    space_id              bigint                             null comment '空间ID',
    created               datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id            bigint                             null comment '创建人ID',
    creator_name          varchar(64)                        null comment '创建人',
    modified              datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id           bigint                             null comment '最后修改人ID',
    modified_name         varchar(64)                        null comment '最后修改人',
    yn                   tinyint  default 1                 not null comment '逻辑标记,1:有效;-1:无效',
    sandbox_id           bigint                             null comment '沙盒ID',
    constraint uk_base_path
        unique (base_path)
)
    comment '用户页面配置';

create table custom_page_conversation
(
    id            bigint auto_increment comment '主键ID'
        primary key,
    project_id    bigint                             not null comment '项目ID',
    topic         varchar(500)                       null comment '会话主题',
    content       longtext                           not null comment '会话内容',
    _tenant_id    bigint                             not null comment '租户ID',
    space_id      bigint                             null comment '空间ID',
    created       datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                             null comment '创建者ID',
    creator_name  varchar(255)                       null comment '创建者名称',
    modified      datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '修改时间',
    modified_id   bigint                             null comment '修改者ID',
    modified_name varchar(255)                       null comment '修改者名称',
    yn            int      default 1                 not null comment '是否有效 1:有效 -1:无效',
    session_id    varchar(64)                      null comment '会话ID',
    role          varchar(32)                      null comment '消息发送者角色',
    request_id    varchar(64)                      null comment '请求ID'
)
    comment '自定义页面会话记录表';

create index idx_project_yn_created
    on custom_page_conversation (project_id, yn, created);

create table custom_page_domain
(
    id         bigint auto_increment comment '主键'
        primary key,
    _tenant_id bigint                             not null comment '租户ID',
    project_id bigint                             not null comment '项目ID',
    domain     varchar(255)                       not null comment '域名',
    created    datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modified   datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    constraint uk_domain
        unique (domain)
)
    comment '自定义页面域名绑定表' collate = utf8mb4_unicode_ci;

create index idx_domain
    on custom_page_domain (domain);

create index idx_tenant_project
    on custom_page_domain (_tenant_id, project_id);

create table custom_table_definition
(
    id                bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id        bigint                             not null comment '租户ID',
    space_id          bigint                             not null comment '所属空间ID',
    icon              varchar(255)                       null comment '图标图片地址',
    table_name        varchar(64)                        not null comment '表名',
    table_description varchar(256)                       null comment '表描述',
    doris_database    varchar(64)                        not null comment 'Doris数据库名',
    doris_table       varchar(64)                        not null comment 'Doris表名',
    status            tinyint  default 1                 not null comment '状态：1-启用 -1-禁用',
    created           datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id        bigint                             null comment '创建人id',
    creator_name      varchar(64)                        null comment '创建人',
    modified          datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id       bigint                             null comment '最后修改人id',
    modified_name     varchar(64)                        null comment '最后修改人',
    yn                tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效'
)
    comment '自定义数据表定义';

create index idx_table_name
    on custom_table_definition (table_name);

create table eco_market_client_config
(
    id                bigint auto_increment comment '主键id'
        primary key,
    uid               varchar(128)                       not null comment '唯一ID,分布式唯一UUID',
    name              varchar(128)                       not null comment '名称',
    description       varchar(256)                       null comment '描述',
    data_type         tinyint  default 1                 not null comment '市场类型,默认插件,1:插件;2:模板;3:MCP',
    target_type       varchar(64)                        null comment '细分类型,比如: 插件,智能体,工作流',
    target_sub_type   varchar(32)                        null comment '子类型',
    target_id         bigint                             null comment '具体目标的id,可以智能体,工作流,插件,还有mcp等',
    category_code     varchar(128)                       null comment '分类编码,商业服务等,通过接口获取',
    category_name     varchar(128)                       null comment '分类名称,商业服务等,通过接口获取',
    owned_flag        tinyint  default 0                 not null comment '是否我的分享,0:否(生态市场获取的);1:是(我的分享)',
    share_status      tinyint  default 1                 not null comment '分享状态,1:草稿;2:审核中;3:已发布;4:已下线;5:驳回',
    use_status        tinyint  default 2                 not null comment '使用状态,1:启用;2:禁用;',
    publish_time      datetime                           null comment '发布时间',
    offline_time      datetime                           null comment '下线时间',
    version_number    bigint   default 1                 not null comment '版本号,自增,发布一次增加1,初始值为1',
    author            varchar(256)                       null comment '作者信息',
    publish_doc       mediumtext                         null comment '发布文档',
    config_param_json json                               null comment '请求参数配置json',
    config_json       json                               null comment '配置json,存储插件的配置信息如果有其他额外的信息保存放这里',
    icon              varchar(255)                       null comment '图标图片地址',
    _tenant_id        bigint                             not null comment '租户ID',
    create_client_id  varchar(128)                       not null comment '创建者的客户端ID',
    created           datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id        bigint                             null comment '创建人id',
    creator_name      varchar(64)                        null comment '创建人',
    modified          datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id       bigint                             null comment '最后修改人id',
    modified_name     varchar(64)                        null comment '最后修改人',
    yn                tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效',
    approve_message   varchar(256)                       null comment '审批原因',
    tenant_enabled    tinyint  default 0                 null comment '是否租户自动启用插件,1:租户自动启用;0:非租户自动启用;默认:0',
    page_zip_url      varchar(500)                       null comment '页面压缩包地址',
    constraint uk_uid
        unique (uid, _tenant_id)
)
    comment '生态市场配置';

create table eco_market_client_publish_config
(
    id                bigint auto_increment comment '主键id'
        primary key,
    uid               varchar(128)                       not null comment '唯一ID,分布式唯一UUID',
    name              varchar(128)                       not null comment '名称',
    description       varchar(256)                       null comment '描述',
    data_type         tinyint  default 1                 not null comment '市场类型,默认插件,1:插件;2:模板;3:MCP',
    target_type       varchar(64)                        null comment '细分类型,比如: 插件,智能体,工作流',
    target_sub_type   varchar(32)                        null comment '子类型',
    target_id         bigint                             null comment '具体目标的id,可以智能体,工作流,插件,还有mcp等',
    category_code     varchar(128)                       null comment '分类编码,商业服务等,通过接口获取',
    category_name     varchar(128)                       null comment '分类名称,商业服务等,通过接口获取',
    owned_flag        tinyint  default 0                 not null comment '是否我的分享,0:否(生态市场获取的);1:是(我的分享)',
    share_status      tinyint  default 1                 not null comment '分享状态,1:草稿;2:审核中;3:已发布;4:已下线;5:驳回',
    use_status        tinyint  default 1                 not null comment '使用状态,1:启用;2:禁用;',
    publish_time      datetime                           null comment '发布时间',
    offline_time      datetime                           null comment '下线时间',
    version_number    bigint   default 1                 not null comment '版本号,自增,发布一次增加1,初始值为1',
    author            varchar(256)                       null comment '作者信息',
    publish_doc       mediumtext                         null comment '发布文档',
    config_param_json json                               null comment '请求参数配置json',
    config_json       json                               null comment '配置json,存储插件的配置信息如果有其他额外的信息保存放这里',
    icon              varchar(255)                       null comment '图标图片地址',
    _tenant_id        bigint                             not null comment '租户ID',
    create_client_id  varchar(128)                       not null comment '创建者的客户端ID',
    created           datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id        bigint                             null comment '创建人id',
    creator_name      varchar(64)                        null comment '创建人',
    modified          datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id       bigint                             null comment '最后修改人id',
    modified_name     varchar(64)                        null comment '最后修改人',
    yn                tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效',
    approve_message   varchar(256)                       null comment '审批原因',
    tenant_enabled    tinyint  default 0                 null comment '是否租户自动启用插件,1:租户自动启用;0:非租户自动启用;默认:0',
    page_zip_url      varchar(500)                       null comment '页面压缩包地址',
    constraint uk_uid
        unique (uid, _tenant_id)
)
    comment '生态市场,客户端,已发布配置';

create table eco_market_client_secret
(
    id            bigint auto_increment comment '主键id'
        primary key,
    name          varchar(128)                       not null comment '名称',
    description   varchar(256)                       null comment '描述',
    client_id     varchar(128)                       not null comment '客户端ID,分布式唯一UUID',
    client_secret varchar(256)                       null comment '客户端密钥',
    _tenant_id    bigint                             not null comment '租户ID',
    created       datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                             null comment '创建人id',
    creator_name  varchar(64)                        null comment '创建人',
    modified      datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn            tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效',
    constraint uk_client_id
        unique (client_id) comment '客户端ID唯一索引'
)
    comment '生态市场,客户端端配置';


create table im_channel_config
(
    id            bigint auto_increment comment '主键ID'
        primary key,
    channel       varchar(64)                          not null comment '渠道类型',
    target_type   varchar(64)                          not null comment '渠道目标类型',
    target_id     varchar(255)                         not null comment '渠道目标唯一标识',
    user_id       bigint                               not null comment '关联系统用户ID',
    agent_id      bigint                               not null comment '关联智能体ID',
    config_data   text                                 not null comment '渠道专有配置（JSON 字符串）',
    output_mode   varchar(32)                          null comment '输出方式',
    enabled       tinyint(1) default 1                 null comment '是否启用',
    name          varchar(255)                         null comment '配置名称备注',
    _tenant_id    bigint                               not null comment '租户ID',
    space_id      bigint                               null comment '空间ID',
    created       datetime   default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                               null comment '创建人ID',
    creator_name  varchar(64)                          null comment '创建人',
    modified      datetime   default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id   bigint                               null comment '最后修改人ID',
    modified_name varchar(64)                          null comment '最后修改人',
    yn            tinyint    default 1                 not null comment '逻辑标记,1:有效;-1:无效',
    constraint uk_channel_target
        unique (channel, target_type, target_id, yn)
)
    comment 'IM 渠道配置';

create index idx_tenant_space_channel_target
    on im_channel_config (_tenant_id, space_id, channel, target_type);

create table im_session
(
    id              bigint auto_increment comment '主键ID'
        primary key,
    channel         varchar(20)                        not null comment '渠道类型',
    target_type     varchar(32)                        null comment '渠道目标类型',
    session_key     varchar(255)                       not null comment '会话标识：单聊为用户ID，群聊为群ID',
    session_name    varchar(255)                       null comment '会话用户名：单聊用户名/昵称，群聊群名',
    chat_type       varchar(20)                        not null comment '会话类型：private-私聊、group-群聊',
    user_id         bigint                             not null comment '系统用户ID',
    agent_id        bigint                             not null comment '智能体ID',
    conversation_id bigint                             not null comment '系统会话ID',
    _tenant_id      bigint                             not null comment '租户ID',
    create_time     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    update_time     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    constraint uk_channel_target_session_key_agent_id
        unique (channel, target_type, session_key, agent_id, _tenant_id)
)
    comment 'IM会话表';

create table knowledge_config
(
    id                     bigint auto_increment comment '主键id'
        primary key,
    name                   varchar(128)                                            not null comment '知识库名称',
    description            varchar(1024)                                           null comment '知识库描述',
    pub_status             enum ('Waiting', 'Published') default 'Waiting'         not null,
    data_type              tinyint                       default 1                 not null comment '数据类型,默认文本,1:文本;2:表格',
    embedding_model_id     int                                                     null comment '知识库的嵌入模型ID',
    chat_model_id          int                                                     null comment '知识库的生成Q&A模型ID',
    _tenant_id             bigint                                                  not null comment '租户ID',
    space_id               bigint                                                  not null comment '所属空间ID',
    created                datetime                      default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id             bigint                                                  null comment '创建人id',
    creator_name           varchar(64)                                             null comment '创建人',
    modified               datetime                      default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id            bigint                                                  null comment '最后修改人id',
    modified_name          varchar(64)                                             null comment '最后修改人',
    yn                     tinyint                       default 1                 null comment '逻辑标记,1:有效;-1:无效',
    icon                   varchar(255)                                            null comment '图标图片地址',
    file_size              bigint                        default 0                 null comment '文件大小,单位字节byte',
    workflow_id            bigint                                                  null comment '工作流id,可选,已工作流的形式,来执行解析文档获取文本的任务',
    fulltext_sync_status   tinyint                       default 0                 null comment '全文检索同步状态: 0-未同步, 1-同步中, 2-已同步, -1-同步失败',
    fulltext_sync_time     datetime                                                null comment '全文检索最后同步时间',
    fulltext_segment_count bigint                        default 0                 null comment '已同步到全文检索的分段数量',
    access_control         tinyint(1)                    default 0                 not null comment '是否管控 0 不管控；1 管控'
)
    comment '知识库表';

create table knowledge_document
(
    id            bigint auto_increment comment '主键id'
        primary key,
    kb_id         bigint                               not null comment '文档所属知识库',
    name          varchar(128)                         not null comment '文档名称',
    doc_url       varchar(256)                         not null comment '文件URL',
    pub_status    enum ('Waiting', 'Published')        not null,
    has_qa        tinyint(1) default 0                 not null comment '是否已经生成Q&A',
    has_embedding tinyint(1) default 0                 not null comment '是否已经完成嵌入',
    segment       json                                 null comment '文档分段方式（需要记录分段方式，基于字符数量或换行，Q&A字段等）。如果为空，表示还没有进行分段',
    _tenant_id    bigint                               not null comment '租户ID',
    space_id      bigint                               not null comment '所属空间ID',
    created       datetime   default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                               null comment '创建人id',
    creator_name  varchar(64)                          null comment '创建人',
    modified      datetime   default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id   bigint                               null comment '最后修改人id',
    modified_name varchar(64)                          null comment '最后修改人',
    yn            tinyint    default 1                 null comment '逻辑标记,1:有效;-1:无效',
    file_content  longtext                             null comment '自定义文本内容,自定义添加会有',
    data_type     tinyint    default 1                 not null comment '文件类型,1:URL访问文件;2:自定义文本内容',
    file_size     bigint     default 0                 null comment '文件大小,单位字节byte'
)
    comment '知识库-原始文档表';

create index idx_id_kb_id_index
    on knowledge_document (space_id, kb_id);

create index idx_kb_id
    on knowledge_document (kb_id);

create table knowledge_qa_segment
(
    id            bigint auto_increment comment '主键id'
        primary key,
    doc_id        bigint                               not null comment '分段所属文档',
    raw_id        bigint                               null comment '所属原始分段ID,前端手动新增的没有归属分段内容',
    question      text                                 null comment '问题会进行嵌入（对分段的增删改会走大模型并调用向量数据库）',
    answer        text                                 null comment '答案会进行嵌入（对分段的增删改会走大模型并调用向量数据库）',
    kb_id         bigint                               not null comment '知识库ID',
    has_embedding tinyint(1) default 0                 not null comment '是否已经完成嵌入',
    _tenant_id    bigint                               not null comment '租户ID',
    space_id      bigint                               not null comment '所属空间ID',
    created       datetime   default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                               null comment '创建人id',
    creator_name  varchar(64)                          null comment '创建人',
    modified      datetime   default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id   bigint                               null comment '最后修改人id',
    modified_name varchar(64)                          null comment '最后修改人',
    yn            tinyint    default 1                 null comment '逻辑标记,1:有效;-1:无效'
)
    comment '问答表';

create index idx_doc_id
    on knowledge_qa_segment (doc_id);

create index idx_kb_id_space_id_doc_id_index
    on knowledge_qa_segment (kb_id, space_id, doc_id);

create table knowledge_raw_segment
(
    id                   bigint auto_increment comment '主键id'
        primary key,
    doc_id               bigint                             not null comment '分段所属文档',
    raw_txt              mediumtext                         null comment '原始文本',
    kb_id                bigint                             not null comment '知识库ID',
    sort_index           int                                not null comment '排序索引,在归属同一个文档下，段的排序',
    _tenant_id           bigint                             not null comment '租户ID',
    space_id             bigint                             not null comment '所属空间ID',
    created              datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id           bigint                             null comment '创建人id',
    creator_name         varchar(64)                        null comment '创建人',
    modified             datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id          bigint                             null comment '最后修改人id',
    modified_name        varchar(64)                        null comment '最后修改人',
    yn                   tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效',
    qa_status            tinyint  default -1                null comment '-1:待生成问答;1:已生成问答;',
    fulltext_sync_status tinyint  default 0                 null comment '全文检索同步状态: 0-未同步, 1-已同步',
    fulltext_sync_time   datetime                           null comment '全文检索同步时间'
)
    comment '原始分段（也称chunk）表，这些信息待生成问答后可以不再保存';

create index idx_doc_id
    on knowledge_raw_segment (doc_id);

create index idx_kb_fulltext_sync
    on knowledge_raw_segment (kb_id, fulltext_sync_status);

create index idx_kb_id
    on knowledge_raw_segment (kb_id);

create index idx_space_id_kb_id_doc_id_index
    on knowledge_raw_segment (space_id, kb_id, doc_id);

create table knowledge_task
(
    id            bigint auto_increment comment '主键id'
        primary key,
    kb_id         bigint                             not null comment '文档所属知识库',
    space_id      bigint                             not null comment '所属空间ID',
    doc_id        bigint                             not null comment '文档id',
    type          tinyint                            not null comment '任务重试阶段类型:1:文档分段;2:生成Q&A;3:生成嵌入;10:任务完毕',
    tid           varchar(100)                       not null comment 'tid',
    name          varchar(128)                       not null comment '任务名称',
    status        tinyint                            not null comment '状态，0:初始状态,1待重试，2重试成功，3重试失败，4禁止重试',
    max_retry_cnt int      default 5                 not null comment '最大重试次数',
    retry_cnt     int      default 0                 not null comment '已重试次数',
    result        mediumtext                         null comment '调用结果',
    _tenant_id    bigint                             not null comment '租户ID',
    created       datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                             null comment '创建人id',
    creator_name  varchar(64)                        null comment '创建人',
    modified      datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn            tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效'
)
    comment '知识库-定时任务';

create index idx_doc_id
    on knowledge_task (doc_id);

create index idx_status_kb_id_doc_id
    on knowledge_task (status, kb_id, doc_id);

create table knowledge_task_history
(
    id            bigint auto_increment comment '主键id'
        primary key,
    kb_id         bigint                             not null comment '文档所属知识库',
    space_id      bigint                             not null comment '所属空间ID',
    doc_id        bigint                             not null comment '文档id',
    type          tinyint                            not null comment '任务重试阶段类型:1:文档分段;2:生成Q&A;3:生成嵌入;10:任务完毕',
    tid           varchar(100)                       not null comment 'tid',
    name          varchar(128)                       not null comment '任务名称',
    status        tinyint                            not null comment '状态，0:初始状态,1待重试，2重试成功，3重试失败，4禁止重试',
    max_retry_cnt int      default 5                 not null comment '最大重试次数',
    retry_cnt     int      default 0                 not null comment '已重试次数',
    result        mediumtext                         null comment '调用结果',
    _tenant_id    bigint                             not null comment '租户ID',
    created       datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id    bigint                             null comment '创建人id',
    creator_name  varchar(64)                        null comment '创建人',
    modified      datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn            tinyint  default 1                 null comment '逻辑标记,1:有效;-1:无效'
)
    comment '知识库-定时任务-历史';

create index idx_status_kb_id_doc_id
    on knowledge_task_history (status, kb_id, doc_id);

create table mcp_config
(
    id              bigint auto_increment
        primary key,
    _tenant_id      bigint      default 1                 not null comment '租户ID',
    space_id        bigint                                not null comment '空间ID',
    creator_id      bigint                                not null comment '创建用户ID',
    uid             varchar(64)                           null,
    name            varchar(64)                           not null comment 'MCP名称',
    server_name     varchar(64)                           null,
    description     text                                  null comment 'MCP描述信息',
    icon            varchar(255)                          null comment 'icon图片地址',
    category        varchar(64)                           null,
    install_type    varchar(64)                           not null comment 'MCP安装类型',
    deploy_status   varchar(64) default 'Initialization'  not null comment '部署状态',
    config          json                                  null comment 'MCP配置',
    deployed_config json                                  null comment 'MCP已发布的配置',
    deployed        datetime                              null comment '部署时间',
    modified        datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created         datetime    default CURRENT_TIMESTAMP not null
);

create index idx_uid
    on mcp_config (uid);

create table memory_unit
(
    id           bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id   bigint                                                           not null comment '租户ID',
    user_id      bigint                                                           not null comment '用户ID',
    agent_id     bigint                                                           null comment '代理ID',
    category     varchar(50)                                                      not null comment '一级分类',
    sub_category varchar(100)                                                     null comment '二级分类',
    content_json json                                                             null comment '内容JSON',
    is_sensitive tinyint(1)                             default 0                 not null comment '是否敏感信息(0:否 1:是)',
    status       enum ('active', 'archived', 'deleted') default 'active'          not null comment '状态',
    created      datetime                               default CURRENT_TIMESTAMP not null comment '创建时间',
    modified     datetime                               default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '修改时间'
)
    comment '记忆单元表';

create index idx_agent
    on memory_unit (agent_id);

create index idx_category
    on memory_unit (category, sub_category);

create index idx_created
    on memory_unit (created);

create index idx_status
    on memory_unit (status);

create index idx_tenant_user
    on memory_unit (_tenant_id, user_id);

create table memory_unit_tag
(
    id         bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id bigint                             not null comment '租户ID',
    user_id    bigint                             not null comment '用户ID',
    memory_id  bigint                             not null comment '记忆ID',
    tag_name   varchar(100)                       not null comment '标签名称',
    created    datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modified   datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '修改时间',
    constraint uk_tag_memory
        unique (tag_name, memory_id)
)
    comment '记忆单元标签表';

create index idx_memory
    on memory_unit_tag (memory_id);

create index idx_tenant_user
    on memory_unit_tag (_tenant_id, user_id);

create table model_config
(
    id                 bigint auto_increment
        primary key,
    _tenant_id         bigint                                                                                                              default 1                    not null comment '商户ID',
    space_id           bigint                                                                                                                                           null comment '空间ID',
    creator_id         bigint                                                                                                                                           not null comment '创建者ID',
    scope              enum ('Space', 'Tenant', 'Global')                                                                                  default 'Tenant'             not null comment '模型生效范围',
    name               varchar(255)                                                                                                                                     not null comment '模型名称',
    description        text                                                                                                                                             null comment '模型描述',
    model              varchar(128)                                                                                                                                     null comment '模型标识',
    type               varchar(64)                                                                                                                                      null comment '模型类型',
    is_reason_model    int(4)                                                                                                              default 0                    not null comment '是否为深度思考模型',
    network_type       enum ('Internet', 'Intranet')                                                                                       default 'Internet'           not null comment '联网类型',
    nat_info           json                                                                                                                                             null comment '网络配置信息（内网模式使用）',
    function_call      enum ('Unsupported', 'CallSupported', 'StreamCallSupported')                                                        default 'CallSupported'      not null comment '函数调用支持程度',
    max_tokens         int(10)                                                                                                             default 4096                 not null comment '请求token上限',
    max_context_tokens int(10)                                                                                                             default 128000               not null comment '模型支持最大上下文',
    api_protocol       varchar(64)                                                                                                                                      not null comment '模型接口协议',
    api_info           json                                                                                                                                             not null comment 'API列表 [{"url":"","key":"","weight":1}]',
    strategy           enum ('RoundRobin', 'WeightedRoundRobin', 'LeastConnections', 'WeightedLeastConnections', 'Random', 'ResponseTime') default 'WeightedRoundRobin' not null comment '接口调用策略',
    dimension          int(10)                                                                                                             default 1536                 not null comment '向量维度',
    modified           datetime                                                                                                            default CURRENT_TIMESTAMP    not null on update CURRENT_TIMESTAMP comment '修改时间',
    created            datetime                                                                                                            default CURRENT_TIMESTAMP    not null comment '创建时间',
    enabled            tinyint                                                                                                             default 1                    null comment '启用状态',
    access_control     tinyint                                                                                                             default 0                    not null comment '是否管控',
    usage_scenario     varchar(255)                                                                                                                                     null comment '可用的场景范围',
    pid                varchar(64)                                                                                                              default 'custom'             not null comment '提供商ID',
    types              json                                                                                                                                             null comment '模型能力类型列表（Text/Image/Audio/Video/TextEmbedding/MultiEmbedding/Reasoning）'
);

create table notify_message
(
    id         bigint auto_increment
        primary key,
    _tenant_id bigint   default 1                 not null comment '商户ID',
    sender_id  bigint                             null comment '发送用户',
    scope      varchar(32)                        not null comment '消息范围 Broadcast 广播消息；Private 私对私消息',
    content    mediumtext                         not null comment '消息内容',
    modified   datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created    datetime default CURRENT_TIMESTAMP not null
);

create table notify_message_user
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint                  default 1                 not null comment '商户ID',
    notify_id   bigint                                            null comment '通知消息ID',
    user_id     bigint                                            null comment '接收用户，广播消息user_id=-1',
    read_status enum ('Read', 'Unread') default 'Unread'          not null comment '已读状态',
    modified    datetime                default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created     datetime                default CURRENT_TIMESTAMP not null
);

create index idx_user_notify
    on notify_message_user (user_id, notify_id);

create table pf_retry_data
(
    id              bigint auto_increment
        primary key,
    project_code    varchar(50)                        not null comment '应用code',
    app_code        varchar(50)                        not null comment '模块code',
    bean_name       varchar(200)                       not null comment '服务接口',
    method_name     varchar(100)                       not null comment '接口方法',
    tid             varchar(100)                       not null comment 'tid',
    status          tinyint  default 1                 not null comment '状态，1待重试，2重试成功，3重试失败，4禁止重试',
    max_retry_cnt   int      default 5                 not null comment '最大重试次数',
    retry_cnt       int      default 0                 not null comment '已重试次数',
    arg_class_names varchar(600)                       null comment '参数类型名称组',
    arg_str         mediumtext                         null comment '参数数组JSONString格式，可编辑',
    result          mediumtext                         null comment '调用结果',
    creator_id      bigint                             null comment '操作人ID',
    creator_name    varchar(100)                       null comment '操作人名称',
    created         datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modified        datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modifier_id     bigint                             null comment '编辑人ID',
    modifier_name   varchar(100)                       null comment '编辑人名称',
    lock_time       datetime                           null comment '锁定至时间',
    yn              tinyint  default 1                 not null comment '是否有效',
    ext             longtext collate utf8mb4_bin       null comment '扩展信息',
    _tenant_id      bigint   default -1                not null
)
    comment '重试上报数据';

create index idx_project_app_bean_method
    on pf_retry_data (project_code, app_code, bean_name, method_name, tid);

create table plugin_config
(
    id             bigint auto_increment
        primary key,
    _tenant_id     bigint                                       default 1                 not null comment '租户ID',
    space_id       bigint                                                                 not null comment '空间ID',
    creator_id     bigint                                                                 not null comment '创建用户ID',
    name           varchar(64)                                                            not null comment '插件名称',
    description    text                                                                   null comment '插件描述信息',
    icon           varchar(255)                                                           null comment 'icon图片地址',
    type           varchar(64)                                                            not null comment '插件类型',
    code_lang      varchar(64)                                                            null comment '插件类型为代码时，该字段填写代码语言js、python',
    publish_status enum ('Developing', 'Applying', 'Published') default 'Developing'      not null comment '发布状态',
    config         json                                                                   null comment '插件配置',
    modified       datetime                                     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created        datetime                                     default CURRENT_TIMESTAMP not null
);

create table publish_apply
(
    id              bigint auto_increment
        primary key,
    _tenant_id      bigint                                                       not null,
    space_id        bigint                                                       null comment '空间ID',
    apply_user_id   bigint                                                       not null comment '申请用户ID',
    target_type     enum ('Agent', 'Plugin', 'Workflow', 'Skill')                not null comment '审核目标类型',
    target_sub_type varchar(32)                                                  null comment '子类型',
    target_id       bigint                                                       not null,
    name            varchar(64)                                                  not null comment '发布名称',
    description     text                                                         null comment '描述信息',
    icon            varchar(255)                                                 null comment '图标',
    remark          text                                                         null comment '发布记录',
    config          json                                                         not null comment '发布配置',
    channel         json                                                         null comment '发布渠道：Square 广场；System 系统发布',
    scope           enum ('Space', 'Tenant', 'Global') default 'Tenant'          null comment '发布范围',
    publish_status  varchar(32)                                                  not null comment '发布审核状态',
    category        varchar(64)                        default ''                not null comment '分类',
    allow_copy      tinyint                            default 0                 not null comment '是否允许复制',
    only_template   tinyint                            default 0                 not null comment '仅展示模板',
    ext             json                               null comment '扩展字段',
    modified        datetime                           default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created         datetime                           default CURRENT_TIMESTAMP not null
);

create index _tenant_id
    on publish_apply (_tenant_id, target_type);

create index idx_target
    on publish_apply (_tenant_id, target_type, target_id);

create table published
(
    id              bigint auto_increment
        primary key,
    _tenant_id      bigint                                                       not null,
    space_id        bigint                                                       null comment '空间ID',
    user_id         bigint                                                       null comment '发布者ID',
    target_id       bigint                                                       not null comment '发布目标对象ID',
    target_type     enum ('Agent', 'Plugin', 'Workflow', 'Skill')                not null comment '发布类型',
    target_sub_type varchar(32)                        default 'Single'          not null,
    name            varchar(64)                                                  not null comment '发布名称',
    description     text                                                         null comment '描述信息',
    icon            varchar(255)                                                 null comment '图标',
    remark          text                                                         null comment '发布记录',
    config          json                                                         not null comment '发布配置',
    channel         varchar(32)                        default 'Square'          not null comment '发布渠道：Square 广场；System 系统发布',
    scope           enum ('Tenant', 'Global', 'Space') default 'Tenant'          not null comment '发布范围',
    category        varchar(64)                        default 'Other'           null comment '分类',
    allow_copy      tinyint                            default 0                 not null comment '是否允许复制',
    access_control  tinyint                            default 0                 not null comment '是否受权限管控，0 不受管控；1 受控',
    only_template   tinyint                            default 0                 not null comment '仅展示模板',
    ext             json                               null comment '扩展字段',
    modified        datetime                           default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created         datetime                           default CURRENT_TIMESTAMP not null
)
    comment '发布';

create index idx_space_id
    on published (space_id);

create index idx_target_id
    on published (target_id);

create index idx_tenant_target_type
    on published (_tenant_id, target_type, category);

create table published_statistics
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint   default -1                           not null comment '商户ID',
    target_id   bigint                                        not null comment '目标统计对象ID',
    target_type enum ('Agent', 'Plugin', 'Workflow', 'Skill') not null comment '目标对象类型',
    name        varchar(32)                                   not null comment '统计名称',
    value       bigint   default 0                            not null comment '统计值',
    modified    datetime default CURRENT_TIMESTAMP            not null on update CURRENT_TIMESTAMP comment '更新时间',
    created     datetime default CURRENT_TIMESTAMP            not null comment '创建时间',
    constraint uk_target_id
        unique (target_id, target_type, name)
);

create table sandbox_config
(
    id           bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id   bigint                               not null comment '租户id',
    scope        varchar(100)                         not null comment '配置范围：global-全局配置 user-个人配置',
    user_id      bigint                               null comment '用户ID（scope为user时必填）',
    agent_id     bigint                               null comment '智能体电脑绑定的agentId',
    name         varchar(100)                         not null comment '配置名称（用于界面显示）',
    config_key   varchar(100)                         null comment '唯一标识',
    config_value json                                 not null comment '配置值（JSON格式存储）',
    server_info  json                                 null comment '内部访问信息',
    description  varchar(500)                         null comment '配置描述',
    is_active    tinyint(1) default 1                 not null comment '是否启用：1-启用 0-禁用',
    max_agent    int(10)    default 5                 not null comment '最大可以开多少个agent并行执行（个人客户端有效'),
    type         varchar(16) default 'Agent'         not null comment '沙箱类型：Agent 智能体沙箱；PageApp 应用开发沙箱',
    bind_info    json                               null comment '关系绑定',
    isolation    varchar(16)                        null comment '隔离策略，仅页面开发有效',
    created      timestamp  default CURRENT_TIMESTAMP not null comment '创建时间',
    modified     timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    constraint uk_scope_user_key
        unique (scope, user_id, config_key)
);

create index idx_config_key
    on sandbox_config (config_key);

create index idx_is_active
    on sandbox_config (is_active);

create index idx_scope
    on sandbox_config (scope);

create index idx_user_id
    on sandbox_config (user_id);

create table sandbox_proxy
(
    id           bigint auto_increment
        primary key,
    _tenant_id   bigint   default 1                 not null comment '租户ID',
    user_id      bigint                             not null comment '用户ID',
    sandbox_id   bigint                             not null comment '沙盒ID',
    proxy_key    varchar(64)                        not null comment '代理键',
    backend_host varchar(255)                       not null comment '后端主机地址',
    backend_port int                                not null comment '后端端口',
    modified     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created      datetime default CURRENT_TIMESTAMP not null comment '创建时间'
)
    comment '临时代理配置表';

create index idx_proxy_key
    on sandbox_proxy (proxy_key);

create index idx_sandbox_id
    on sandbox_proxy (sandbox_id);

create index idx_user_id
    on sandbox_proxy (user_id);

create table schedule_task
(
    id               bigint auto_increment
        primary key,
    _tenant_id       bigint       default -1                not null comment '租户ID',
    space_id         bigint       default -1                not null comment '空间ID',
    creator_id       bigint       default -1                not null comment '创建用户ID',
    task_name        varchar(128) default ''                not null comment '任务名称',
    target_type      varchar(32)  default 'System'          not null comment '类型',
    target_id        varchar(64)  default '-1'              not null comment '目标对象ID',
    task_id          varchar(255)                           not null comment '任务ID',
    bean_id          varchar(128)                           not null comment '回调处理器',
    cron             varchar(32)                            not null comment '执行周期',
    params           json                                   null comment '附加参数',
    status           varchar(32)                            not null comment '调用状态',
    lock_time        datetime     default CURRENT_TIMESTAMP not null comment '锁定时间',
    latest_exec_time datetime                               null comment '最近一次执行时间',
    exec_times       bigint       default 0                 not null comment '已执行次数',
    max_exec_times   bigint                                 not null comment '最大执行次数',
    error            text                                   null comment '错误信息',
    server_info      varchar(32)                            null comment '执行任务的服务器信息',
    modified         datetime     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created          datetime     default CURRENT_TIMESTAMP not null comment '创建时间'
)
    comment '任务调度表';

create index idx_user_status
    on schedule_task (status);

create index status
    on schedule_task (status);

create index task_id
    on schedule_task (task_id);

create table skill_config
(
    id             bigint auto_increment comment '主键ID'
        primary key,
    name           varchar(255)                           not null comment '技能名称',
    description    text                                   null comment '技能描述',
    icon           varchar(500)                           null comment '技能图标',
    files          longtext                               null comment '内容',
    publish_status varchar(100) default 'Developing'      not null comment '发布状态',
    _tenant_id     bigint                                 not null comment '租户ID',
    space_id       bigint                                 null comment '空间ID',
    created        datetime     default CURRENT_TIMESTAMP not null comment '创建时间',
    creator_id     bigint                                 null comment '创建人ID',
    creator_name   varchar(64)                            null comment '创建人',
    modified       datetime     default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    modified_id    bigint                                 null comment '最后修改人ID',
    modified_name  varchar(64)                            null comment '最后修改人',
    yn             tinyint      default 1                 not null comment '逻辑标记,1:有效;-1:无效',
    ext            json                               null comment '扩展字段'
)
    comment '技能配置';

create index idx_space_id
    on skill_config (space_id);

create table space
(
    id              bigint auto_increment
        primary key,
    _tenant_id      bigint                             default 1                 not null comment '商户ID',
    name            varchar(64)                                                  not null comment '空间名称',
    description     varchar(255)                                                 null comment '空间介绍',
    icon            text                                                         null comment '空间图标',
    creator_id      bigint                                                       not null comment '创建者ID',
    type            enum ('Personal', 'Team', 'Class') default 'Team'            not null comment '空间类型',
    receive_publish tinyint                            default 1                 not null comment '是否允许来自外部空间的发布',
    allow_develop   tinyint                            default 1                 not null comment '是否开启开发者功能',
    yn              tinyint                            default 0                 not null comment '逻辑删除，1为删除',
    modified        datetime                           default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    created         datetime                           default CURRENT_TIMESTAMP not null comment '创建时间'
)
    comment '团队空间';

create index idx_tenant_id
    on space (_tenant_id);

create table space_user
(
    id         bigint auto_increment
        primary key,
    _tenant_id bigint                          default 1                 not null comment '商户ID',
    space_id   bigint                                                    not null comment '空间ID',
    user_id    bigint                                                    not null comment '人员ID',
    role       enum ('Owner', 'Admin', 'User') default 'User'            not null comment '空间角色',
    modified   datetime                        default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    created    datetime                        default CURRENT_TIMESTAMP not null comment '创建时间',
    constraint uk_space_user
        unique (space_id, user_id)
)
    comment '空间人员';

create table sys_data_permission
(
    id                         bigint auto_increment comment '主键ID'
        primary key,
    target_type                tinyint                            not null comment '目标类型，对应 PermissionTargetTypeEnum',
    target_id                  bigint                             not null comment '目标ID',
    token_limit                json                               null comment 'token 限制（JSON）',
    max_space_count            int                                null comment '可创建工作空间数量，-1 表示不限制',
    max_agent_count            int                                null comment '可创建智能体数量，-1 表示不限制',
    max_page_app_count         int                                null comment '可创建网页应用数量，-1 表示不限制',
    max_knowledge_count        int                                null comment '可创建知识库数量，-1 表示不限制',
    knowledge_storage_limit_gb decimal(10, 3)                     null comment '知识库存储空间上限(GB)，-1 表示不限制',
    max_data_table_count       int                                null comment '可创建数据表数量，-1 表示不限制',
    max_scheduled_task_count   int                                null comment '可创建定时任务数量，-1 表示不限制',
    allow_api_external_call    tinyint                            null comment '是否允许API外部调用，1-允许，0-不允许',
    agent_computer_cpu_cores   int                                null comment '智能体电脑CPU核心数',
    agent_computer_memory_gb   int                                null comment '智能体电脑内存(GB)',
    agent_computer_swap_gb     int                                null comment '智能体电脑交换分区(GB)',
    agent_file_storage_days    int                                null comment '通用智能体执行结果文件存储天数(仅云端电脑受限)，-1 表示不限制',
    agent_daily_prompt_limit   int                                null comment '通用智能体每天对话次数(含编排调试，问答智能体不限)，-1 表示不限制',
    page_daily_prompt_limit    int                                null comment '页面应用每天对话次数，-1表示不限制',
    _tenant_id                 bigint                             not null comment '租户ID',
    creator_id                 bigint                             null comment '创建人ID',
    creator                    varchar(64)                        null comment '创建人',
    created                    datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id                bigint                             null comment '修改人ID',
    modifier                   varchar(64)                        null comment '修改人',
    modified                   datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn                         tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效',
    constraint idx_tenant_target_type_id
        unique (_tenant_id, target_type, target_id)
)
    comment '数据权限';

create table sys_group
(
    id             bigint auto_increment comment 'ID'
        primary key,
    parent_id      bigint                             null comment '父节点 ID',
    code           varchar(128)                       not null comment '编码',
    name           varchar(128)                       not null comment '名称',
    description    varchar(512)                       null comment '描述',
    max_user_count int                                null comment '最大用户数',
    source         tinyint                            not null comment '来源：1-系统内置，2-用户自定义，对应 SourceEnum',
    status         tinyint                            not null comment '状态：1-启用，0-禁用',
    sort_index     int                                null comment '排序',
    _tenant_id     bigint                             not null comment '租户ID',
    creator_id     bigint                             null comment '创建人ID',
    creator        varchar(64)                        null comment '创建人',
    created        datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id    bigint                             null comment '修改人ID',
    modifier       varchar(64)                        null comment '修改人',
    modified       datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn             tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效',
    constraint uk_tenant_code
        unique (_tenant_id, code)
)
    comment '用户组';

create table sys_group_menu
(
    id                 bigint auto_increment comment '主键ID'
        primary key,
    group_id           bigint                             not null comment '用户组ID',
    menu_id            bigint                             not null comment '菜单ID',
    menu_bind_type     tinyint  default 0                 not null comment '子菜单绑定类型 0:未绑定 1:全部绑定 2:部分绑定',
    resource_tree_json json                               null comment '资源树JSON（包含每个节点的绑定类型）',
    _tenant_id         bigint                             not null comment '租户ID',
    creator_id         bigint                             null comment '创建人ID',
    creator            varchar(64)                        null comment '创建人',
    created            datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id        bigint                             null comment '修改人ID',
    modifier           varchar(64)                        null comment '修改人',
    modified           datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn                 tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效'
)
    comment '用户组和菜单关联';

create index idx_group_id
    on sys_group_menu (group_id);

create index idx_menu_id
    on sys_group_menu (menu_id);

create table sys_menu
(
    id          bigint auto_increment comment '菜单ID'
        primary key,
    parent_id   bigint                             null comment '父级ID',
    code        varchar(128)                       not null comment '资源码，唯一标识',
    name        varchar(128)                       not null comment '菜单名称',
    description varchar(512)                       null comment '描述',
    source      tinyint                            not null comment '来源，对应 SourceEnum',
    path        varchar(500)                       null comment '访问路径/路由地址',
    open_type   tinyint  default 1                 null comment '打开方式',
    icon        varchar(500)                       null comment '图标',
    sort_index  int                                null comment '排序',
    status      tinyint  default 1                 not null comment '状态：1-启用，0-禁用',
    _tenant_id  bigint                             not null comment '租户ID',
    creator_id  bigint                             null comment '创建人ID',
    creator     varchar(64)                        null comment '创建人',
    created     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id bigint                             null comment '修改人ID',
    modifier    varchar(64)                        null comment '修改人',
    modified    datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn          tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效',
    constraint uk_tenant_code
        unique (_tenant_id, code)
)
    comment '菜单';

create index idx_parent_id
    on sys_menu (parent_id);

create table sys_menu_resource
(
    id                 bigint auto_increment comment '主键ID'
        primary key,
    menu_id            bigint                             not null comment '菜单ID',
    resource_id        bigint                             not null comment '资源ID',
    resource_bind_type tinyint  default 0                 not null comment '资源绑定类型 0:未绑定 1:全部绑定 2:部分绑定',
    _tenant_id         bigint                             not null comment '租户ID',
    creator_id         bigint                             null comment '创建人ID',
    creator            varchar(64)                        null comment '创建人',
    created            datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id        bigint                             null comment '修改人ID',
    modifier           varchar(64)                        null comment '修改人',
    modified           datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn                 tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效'
)
    comment '菜单资源关联';

create index idx_menu_id
    on sys_menu_resource (menu_id);

create index idx_resource_id
    on sys_menu_resource (resource_id);

create table sys_operator_log
(
    id              bigint auto_increment comment '自增主键'
        primary key,
    operate_type    tinyint                             not null comment '1:操作类型;2:访问日志',
    system_code     varchar(64)                         null comment '系统编码',
    system_name     varchar(64)                         not null comment '系统名称',
    object_op       varchar(64)                         not null comment '操作对象,比如:用户表,角色表,菜单表',
    action          varchar(64)                         not null comment '操作动作,比如:新增,删除,修改,查看',
    operate_content varchar(256)                        null comment '操作内容,比如评估页面',
    extra_content   text                                null comment '额外的操作内容信息记录,比如:更新提交的数据内容',
    org_id          bigint                              not null comment '操作人所属机构id',
    org_name        varchar(256)                        not null comment '操作人所属机构名称',
    creator_id      bigint                              not null comment '创建人id',
    creator         varchar(64)                         null comment '创建人名称',
    created         timestamp default CURRENT_TIMESTAMP not null comment '创建时间',
    modified        timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    _tenant_id      bigint                              not null comment '租户ID',
    yn              tinyint   default 1                 not null comment '是否有效；1：有效，-1：无效'
)
    comment '操作日志';

create table sys_resource
(
    id          bigint auto_increment comment '资源ID'
        primary key,
    parent_id   bigint                             null comment '父级ID',
    code        varchar(128)                       not null comment '编码',
    name        varchar(128)                       not null comment '名称',
    description varchar(512)                       null comment '描述',
    source      tinyint                            not null comment '来源，对应 SourceEnum',
    type        tinyint                            not null comment '类型，对应 ResourceTypeEnum',
    path        varchar(500)                       null comment '访问路径',
    icon        varchar(500)                       null comment '图标',
    sort_index  int                                null comment '排序',
    status      tinyint  default 1                 not null comment '状态：1-启用，0-禁用',
    _tenant_id  bigint                             not null comment '租户ID',
    creator_id  bigint                             null comment '创建人ID',
    creator     varchar(64)                        null comment '创建人',
    created     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id bigint                             null comment '修改人ID',
    modifier    varchar(64)                        null comment '修改人',
    modified    datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn          tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效',
    constraint uk_tenant_code
        unique (_tenant_id, code)
)
    comment '资源';

create index idx_parent_id
    on sys_resource (parent_id);

create table sys_role
(
    id          bigint auto_increment comment '角色ID'
        primary key,
    code        varchar(128)                       not null comment '编码',
    name        varchar(128)                       not null comment '名称',
    description varchar(512)                       null comment '描述',
    source      tinyint                            not null comment '来源，对应 SourceEnum',
    status      tinyint                            not null comment '状态：1-启用，0-禁用',
    sort_index  int                                null comment '排序',
    _tenant_id  bigint                             not null comment '租户ID',
    creator_id  bigint                             null comment '创建人ID',
    creator     varchar(64)                        null comment '创建人',
    created     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id bigint                             null comment '修改人ID',
    modifier    varchar(64)                        null comment '修改人',
    modified    datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn          tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效',
    constraint uk_tenant_code
        unique (_tenant_id, code)
)
    comment '角色';

create table sys_role_menu
(
    id                 bigint auto_increment comment '主键ID'
        primary key,
    role_id            bigint                             not null comment '角色ID',
    menu_id            bigint                             not null comment '菜单ID',
    menu_bind_type     tinyint  default 0                 not null comment '子菜单绑定类型 0:未绑定 1:全部绑定 2:部分绑定',
    resource_tree_json json                               null comment '资源树JSON（包含每个节点的绑定类型）',
    _tenant_id         bigint                             not null comment '租户ID',
    creator_id         bigint                             null comment '创建人ID',
    creator            varchar(64)                        null comment '创建人',
    created            datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id        bigint                             null comment '修改人ID',
    modifier           varchar(64)                        null comment '修改人',
    modified           datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn                 tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效'
)
    comment '角色和菜单关联';

create index idx_menu_id
    on sys_role_menu (menu_id);

create index idx_role_id
    on sys_role_menu (role_id);

create table sys_subject_permission
(
    id           bigint auto_increment comment '主键ID'
        primary key,
    subject_type tinyint                            not null comment '主体类型，对应 PermissionSubjectTypeEnum（1-通用智能体，2-应用页面）',
    subject_id   bigint                             not null comment '主体ID（智能体ID/页面ID）',
    target_type  tinyint                            not null comment '目标类型，对应 PermissionTargetTypeEnum（角色/用户组）',
    target_id    bigint                             not null comment '目标ID（角色/用户组ID）',
    _tenant_id   bigint                             not null comment '租户ID',
    creator_id   bigint                             null comment '创建人ID',
    creator      varchar(64)                        null comment '创建人',
    created      datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id  bigint                             null comment '修改人ID',
    modifier     varchar(64)                        null comment '修改人',
    modified     datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn           tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效',
    config       json                               null comment '配置',
    subject_key  varchar(255)                       null,
    constraint uk_subject_target
        unique (_tenant_id, subject_type, subject_id, target_type, target_id)
)
    comment '主体访问权限';

create index idx_subject_type_id
    on sys_subject_permission (subject_type, subject_id);

create index idx_target_type_id
    on sys_subject_permission (target_type, target_id);

create table sys_user_group
(
    id          bigint auto_increment comment '主键ID'
        primary key,
    user_id     bigint                             not null comment '用户ID',
    group_id    bigint                             not null comment '组ID',
    _tenant_id  bigint                             not null comment '租户ID',
    creator_id  bigint                             null comment '创建人ID',
    creator     varchar(64)                        null comment '创建人',
    created     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id bigint                             null comment '修改人ID',
    modifier    varchar(64)                        null comment '修改人',
    modified    datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn          tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效'
)
    comment '用户和组关联';

create index idx_group_id
    on sys_user_group (group_id);

create index idx_user_id
    on sys_user_group (user_id);

create table sys_user_role
(
    id          bigint auto_increment comment '主键ID'
        primary key,
    user_id     bigint                             not null comment '用户ID',
    role_id     bigint                             not null comment '角色ID',
    _tenant_id  bigint                             not null comment '租户ID',
    creator_id  bigint                             null comment '创建人ID',
    creator     varchar(64)                        null comment '创建人',
    created     datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modifier_id bigint                             null comment '修改人ID',
    modifier    varchar(64)                        null comment '修改人',
    modified    datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    yn          tinyint  default 1                 not null comment '是否有效；1：有效，-1：无效'
)
    comment '用户和角色关联';

create index idx_role_id
    on sys_user_role (role_id);

create index idx_user_id
    on sys_user_role (user_id);

create table system_config
(
    config_id   int auto_increment
        primary key,
    name        varchar(32)                           not null,
    value       text                                  not null,
    type        varchar(32) default 'system'          not null,
    input_type  varchar(16)                           null,
    description varchar(255)                          not null,
    created     datetime    default CURRENT_TIMESTAMP not null,
    constraint name
        unique (name)
)
    comment '系统全局配置';

create table tenant
(
    id          bigint auto_increment
        primary key,
    name        varchar(255)                            not null comment '商户名称',
    description text                                    null comment '商户介绍',
    status      enum ('Pending', 'Enabled', 'Disabled') not null comment '商户状态',
    domain      varchar(64) default ''                  not null,
    version     varchar(64) default '1.0.1'             not null,
    modified    datetime    default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP comment '更新时间',
    created     datetime    default CURRENT_TIMESTAMP   not null comment '创建时间',
    constraint uk_domain
        unique (domain)
);

create table tenant_config
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint                                not null,
    description varchar(255)                          not null,
    name        varchar(32)                           not null,
    value       json                                  not null,
    category    varchar(32) default 'Base'            null,
    input_type  varchar(16) default 'Input'           null,
    data_type   varchar(16) default 'String'          null,
    notice      varchar(255)                          not null,
    placeholder varchar(255)                          not null,
    min_height  int(50)                               null,
    required    varchar(8)  default 'true'            not null,
    sort        int(10)     default 0                 not null,
    created     datetime    default CURRENT_TIMESTAMP not null,
    constraint name
        unique (name, _tenant_id)
);

create table tool
(
    tool_id       bigint auto_increment
        primary key,
    tool_key      varchar(32)                            not null comment '工具唯一标识',
    name          varchar(64)                            not null comment '工具名称',
    icon_url      varchar(255)                           null comment '图标地址',
    description   text                                   null comment '工具描述',
    handler_clazz varchar(255)                           null comment '处理类',
    dto_clazz     varchar(255) default ''                not null comment 'DTO类',
    modified      datetime     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created       datetime     default CURRENT_TIMESTAMP not null
);

create table user
(
    id              bigint auto_increment comment '平台用户ID'
        primary key,
    _tenant_id      bigint                       default 1                 not null comment '商户ID',
    uid             varchar(128)                                           null comment '用户唯一标识',
    user_name       varchar(64)                                            null comment '用户姓名',
    nick_name       varchar(64)                                            null comment '用户昵称',
    avatar          varchar(255)                                           null comment '用户头像',
    status          varchar(16)                      default 'Enabled'         not null comment '状态，启用或禁用',
    role            enum ('Admin', 'User')       default 'User'            null comment '角色',
    password        varchar(255)                                           not null comment '管理员密码',
    reset_pass      tinyint                      default 0                 not null comment '是否设置过密码',
    email           varchar(255)                                           null comment '管理员邮箱',
    phone           varchar(64)                                            null comment '电话号码',
    last_login_time datetime                                               null comment '最后登录时间',
    lang            varchar(32)                                            null comment '用户当前语言环境',
    created         datetime                     default CURRENT_TIMESTAMP not null comment '创建时间',
    modified        datetime                     default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间'
)
    comment '用户表';

create index idx_phone
    on user (phone, _tenant_id);

create index idx_uid
    on user (uid, _tenant_id);

create table user_access_key
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint                               not null comment '租户ID',
    user_id     bigint                               not null comment '用户ID',
    name        varchar(255)                         null comment '密钥备注名称',
    target_type varchar(64)                          not null comment '目标业务类型',
    target_id   varchar(64)                          null comment '目标业务ID',
    access_key  varchar(255)                         null comment '访问密钥',
    config      json                                 null comment '其他配置',
    expire      datetime                             null comment '过期时间，留空为不过期',
    status      tinyint(1) default 1                 not null comment '状态，启用 1; 停用 0',
    modified    datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created     datetime   default CURRENT_TIMESTAMP not null
);

create index idx_access_key
    on user_access_key (access_key);

create index idx_user_id
    on user_access_key (user_id);

create table user_agent_sort
(
    id                bigint auto_increment
        primary key,
    _tenant_id        bigint                             not null,
    user_id           bigint                             not null comment '用户ID',
    category          varchar(64)                        not null comment '排序分类',
    sort              int(10)                            not null comment '分类排序',
    agent_sort_config json                               null comment '分类下智能体排序配置',
    modified          datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created           datetime default CURRENT_TIMESTAMP not null,
    constraint uk_user_id_category
        unique (user_id, category)
);

create index idx_user_id
    on user_agent_sort (user_id);

create table user_metric
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint                      null,
    user_id     bigint                      not null comment '用户ID',
    biz_type    varchar(64)                 not null comment '业务类型',
    period_type varchar(16)                 not null comment '时段类型: YEAR, MONTH, DAY, HOUR',
    period varchar (16) not null comment '时段值: 2026, 202601, 20260129, 2026012912',
    value       decimal(20, 2) default 0.00 not null comment '计量值',
    modified    datetime                    null,
    created     datetime                    null,
    constraint uk_metric
        unique (user_id, biz_type, period_type, period)
);

create index idx_biz_type
    on user_metric (biz_type);

create index idx_user_id
    on user_metric (user_id);

create table user_req
(
    id         bigint auto_increment comment '主键ID'
        primary key,
    _tenant_id bigint   default 1                 not null comment '商户ID',
    user_id    bigint                             not null comment '用户ID',
    dt         varchar(16)                        not null comment '日期 YYYYMMDD',
    req_count  int      default 1                 not null comment '请求次数',
    created    datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modified   datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间',
    constraint idx_unique_user_date
        unique (_tenant_id, user_id, dt)
)
    comment '用户每日请求统计表';

create index idx_dt
    on user_req (dt);

create table user_request
(
    id         bigint auto_increment comment '平台用户ID'
        primary key,
    _tenant_id bigint   default 1                 not null comment '商户ID',
    user_id    bigint   default -1                not null comment '用户ID',
    uri        varchar(5000)                      null comment '请求地址',
    created    datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    modified   datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新时间'
)
    comment '请求记录表';

create index idx_user_request_tenant_created
    on user_request (_tenant_id, created);

create index modified
    on user_request (modified);

create table user_share
(
    id         bigint auto_increment
        primary key,
    share_key  varchar(64)                        not null comment '唯一key',
    _tenant_id bigint                             not null comment '租户id',
    user_id    bigint                             not null comment '用户id',
    type       varchar(64)                        not null comment '分享类型',
    target_id  varchar(64)                        null comment '类型可能存在的id',
    content    json                               null comment '分享内容',
    expire     datetime                           null comment '过期时间',
    modified   datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created    datetime default CURRENT_TIMESTAMP not null comment '创建时间'
);

create index idx_type
    on user_share (type, target_id);

create index share_key
    on user_share (share_key);

create index user_id
    on user_share (user_id);

create table user_target_relation
(
    id          bigint auto_increment
        primary key,
    _tenant_id  bigint                                not null comment '商户ID',
    user_id     bigint                                not null comment '用户ID',
    target_type varchar(32)                           not null comment '目标对象类型',
    target_id   bigint                                not null comment '目标对象ID',
    type        varchar(32) default 'Add'             not null comment '关系类型',
    extra       json                                  null,
    modified    datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新时间',
    created     datetime    default CURRENT_TIMESTAMP not null comment '创建时间',
    constraint uk_user_agent_type
        unique (user_id, target_type, target_id, type)
)
    comment '用户与目标对象关系表';

create index idx_user_id
    on user_target_relation (user_id);

create table workflow_config
(
    id             bigint auto_increment
        primary key,
    _tenant_id     bigint                                       default 1                 not null comment '租户ID',
    space_id       bigint                                                                 not null comment '空间ID',
    creator_id     bigint                                                                 not null comment '创建用户ID',
    name           varchar(100)                                                           not null comment '工作流名称',
    description    text                                                                   null comment '工作流描述信息',
    icon           varchar(255)                                                           null comment 'icon图片地址',
    start_node_id  bigint                                                                 null comment '起始节点ID',
    end_node_id    bigint                                                                 null comment '结束节点ID',
    publish_status enum ('Developing', 'Applying', 'Published') default 'Developing'      not null comment '发布状态',
    ext            json                                                                   null,
    modified       datetime                                     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created        datetime                                     default CURRENT_TIMESTAMP not null
);

create table workflow_node_config
(
    id                  bigint auto_increment
        primary key,
    _tenant_id          bigint   default 1                 not null comment '商户ID',
    name                varchar(100)                       null comment '节点名称',
    icon                varchar(255)                       null comment '图标',
    description         text                               null comment '描述',
    workflow_id         bigint                             null comment '工作流ID',
    type                varchar(32)                        not null comment '节点类型',
    config              json                               null comment '详细配置',
    loop_node_id        bigint                             null comment '循环体中各节点记录循环节点ID',
    next_node_ids       json                               null comment '下级节点ID列表',
    inner_node_Ids      json                               null comment '循环节点的内部节点',
    inner_start_node_id bigint                             null comment '循环节点内部开始节点',
    inner_end_node_id   bigint                             null comment '循环节点内部结束节点',
    modified            datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created             datetime default CURRENT_TIMESTAMP not null
)
    comment '智能体组件配置';


-- ============================================================
-- 以下为 2026-03~2026-05 增量迁移合并的新表
-- ============================================================

create table i18n_lang
(
    id         bigint      not null auto_increment comment 'ID',
    _tenant_id bigint      not null,
    name       varchar(64) not null comment '语言名称，例如 简体中文',
    lang       varchar(16) not null comment '语言，中文：zh-cn，英文:en-us 等等',
    status     tinyint              default 1 comment '语言状态，0 停用；1 启用',
    is_default tinyint              default 0 comment '是否为默认语言，0 否；1 是',
    sort       int                  default 0 comment '排序，值越小越靠前',
    modified   datetime    not null default CURRENT_TIMESTAMP comment '更新时间',
    created    datetime    not null default CURRENT_TIMESTAMP comment '创建时间',
    primary key (id),
    key idx_tenant (_tenant_id)
);

create table i18n_config
(
    id          bigint       not null auto_increment comment 'ID',
    _tenant_id  bigint       not null,
    type        varchar(32)  not null comment '类型，包括：系统 System；业务数据 BizData',
    side        varchar(32)  not null comment '端',
    module      varchar(32)  not null comment '模块标记',
    data_id     varchar(64)  not null default '-1' comment '类型为BizData时有效',
    lang        varchar(16)  not null comment '语言，中文：zh-cn，英文:en-us 等等',
    field_key   varchar(512) not null comment '键',
    field_value mediumtext            null comment '值',
    remark      varchar(255)          null comment '备注',
    modified    datetime     not null default CURRENT_TIMESTAMP comment '更新时间',
    created     datetime     not null default CURRENT_TIMESTAMP comment '创建时间',
    primary key (id),
    unique key uk_lang_key (_tenant_id, lang, type, side, field_key, module, data_id)
);

create table file_record
(
    id              bigint       not null auto_increment comment '主键ID',
    _tenant_id      bigint       not null comment '租户ID',
    user_id         bigint       not null comment '用户ID',
    target_type     varchar(50)           null comment '来源对象类型（如：agent、knowledge、message等）',
    target_id       bigint                null comment '来源对象ID',
    file_name       varchar(255) not null comment '文件名称',
    file_size       bigint       not null comment '文件大小（字节）',
    file_type       varchar(100)          null comment '文件类型（MIME类型）',
    file_extension  varchar(20)           null comment '文件扩展名',
    metadata        text                  null comment '文件元数据（JSON格式，存储图片宽高、视频时长等）',
    file_key        varchar(500) not null comment '文件存储标识key',
    storage_type    varchar(20)  not null default 'file' comment '存储方式（cos:腾讯云COS, oss:阿里云OSS, s3:S3协议, local:本地存储）',
    file_url        varchar(1000)         null comment '文件访问URL',
    auth_required   tinyint      not null default 1 comment '是否需要认证',
    status          varchar(20)  not null default 'active' comment '文件状态（active:正常, deleted:已删除）',
    created         datetime     not null default CURRENT_TIMESTAMP comment '创建时间',
    modified        datetime     not null default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_file_key (file_key),
    key idx_created (created),
    key idx_storage_type (storage_type),
    key idx_target (target_type, target_id),
    key idx_tenant_user (_tenant_id, user_id)
);

create table bill_withdraw_application
(
    id            bigint         not null auto_increment comment '主键ID',
    _tenant_id    bigint         not null comment '租户ID',
    user_id       bigint         not null comment '用户ID',
    amount        decimal(10, 2) not null comment '提现金额',
    fee           decimal(10, 2) not null default 0.00 comment '平台服务费',
    actual_amount decimal(10, 2) not null default 0.00 comment '实收金额',
    status        varchar(50)    not null default 'PENDING_REVIEW' comment '状态：PENDING_REVIEW-待审核，APPROVED-已通过，REJECTED-已驳回，PAID-已打款',
    reject_reason varchar(500)            null comment '驳回原因',
    payment_extra json                    null comment '打款补充信息',
    created       datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified      datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    key idx_status (status),
    key idx_tenant_id (_tenant_id),
    key idx_user_id (user_id)
);

create table pay_developer_account
(
    id                      bigint not null auto_increment,
    _tenant_id              bigint not null comment '租户',
    user_id                 bigint not null comment '用户ID',
    email                   varchar(256) null comment '邮箱',
    phone                   varchar(32)  null comment '手机号',
    real_name               varchar(64)  null comment '真实姓名',
    id_card_no              varchar(32)  null comment '身份证号',
    id_card_front_photo_url varchar(1024) null comment '身份证正面照片URL',
    id_card_back_photo_url  varchar(1024) null comment '身份证反面照片URL',
    bank_name               varchar(128) null comment '开户银行名称',
    branch_name             varchar(256) null comment '开户支行名称',
    bank_card_no            varchar(64)  null comment '银行卡号',
    created                 datetime default CURRENT_TIMESTAMP,
    modified                datetime default CURRENT_TIMESTAMP,
    primary key (id),
    unique key uk_tenant_user (_tenant_id, user_id),
    key idx_user (user_id)
);

create table subscription_plan
(
    id               bigint         not null auto_increment comment '主键ID',
    _tenant_id       bigint         not null comment '租户ID',
    name             varchar(200)   not null comment '计划名称',
    description      varchar(1000)           null comment '计划描述',
    price            decimal(10, 2) not null comment '价格',
    first_price      decimal(10, 2)          null comment '首次订阅价格',
    period           tinyint        not null comment '周期：1-月，3-季度，12-年',
    credit_amount    decimal(10, 2) not null default 0.00 comment '每月赠送积分',
    call_limit_count int            not null default -1 comment '可调用次数，-1表示不限制',
    function_only    tinyint        not null default 0 comment '是否仅为功能订阅：0-否，1-是',
    is_hot           tinyint                 default 0 comment '是否热门',
    status           tinyint                 default 1 comment '状态：0-下线，1-上线',
    biz_type         varchar(50)    not null comment '业务类型：SYSTEM-系统，AGENT-智能体，SKILL-技能',
    biz_id           varchar(100)            null comment '业务对象ID，非SYSTEM时必填',
    group_ids        json                    null comment '关联用户组ID（JSON数组）',
    extra            json                    null comment '扩展字段（JSON）',
    sort             bigint         not null default 0 comment '排序',
    created          datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified         datetime                default CURRENT_TIMESTAMP comment '更新时间',
    primary key (id),
    key idx_plan_biz (biz_type, _tenant_id, biz_id)
);

create table model_price_tier
(
    id             bigint         not null auto_increment comment '主键',
    model_id       bigint         not null comment '模型ID',
    context_length int            not null comment '上下文长度（如32代表32k）',
    input_price    decimal(20, 6) not null comment '输入价格',
    output_price   decimal(20, 6) not null comment '输出价格',
    cache_price    decimal(20, 6) not null default 0.000000 comment '缓存价格',
    _tenant_id     bigint         not null comment '租户ID',
    created        datetime       not null default CURRENT_TIMESTAMP comment '创建时间',
    modified       datetime       not null default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_model_context (model_id, context_length, _tenant_id)
);

create table user_credit
(
    id            bigint         not null auto_increment comment '主键ID',
    _tenant_id    bigint         not null comment '租户ID',
    user_id       bigint         not null comment '用户ID',
    batch_no      varchar(64)    not null comment '批次号',
    credit_type   tinyint        not null comment '积分类型：1-订阅积分，2-增购积分，3-活动积分，4-手动发放',
    total_amount  decimal(20, 2) not null comment '总积分',
    used_amount   decimal(20, 2) default 0.00 comment '已使用积分',
    remain_amount decimal(20, 2) not null comment '剩余积分',
    expire_time   datetime                null comment '过期时间，NULL表示永不过期',
    repaid_amount decimal(20, 2) default 0.00 comment '已还款金额',
    repay_status  tinyint        default 0 comment '还款状态：0-未还清，1-已还清',
    remark        varchar(500)            null comment '备注',
    extra         json                    null comment '扩展信息',
    version       int            default 1 comment '乐观锁版本号',
    modified      datetime       default CURRENT_TIMESTAMP comment '更新时间',
    created       datetime       default CURRENT_TIMESTAMP comment '创建时间',
    primary key (id),
    key idx_batch_no (batch_no),
    key idx_expire_time (expire_time),
    key idx_user_expire (user_id, expire_time),
    key idx_user_id (user_id),
    key idx_user_type (user_id, credit_type)
);

create table credit_package
(
    id            bigint         not null auto_increment comment '主键ID',
    _tenant_id    bigint         not null comment '租户ID',
    package_name  varchar(100)   not null comment '套餐名称',
    credit_amount decimal(20, 2) not null comment '积分数量',
    price         decimal(20, 2) not null comment '价格',
    sort          int                     default 0 comment '排序',
    status        tinyint                 default 1 comment '状态：0-禁用，1-启用',
    remark        varchar(500)            null comment '备注',
    period        tinyint        not null default 1 comment '有效期（月）',
    created       datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified      datetime                default CURRENT_TIMESTAMP comment '更新时间',
    primary key (id)
);

create table bill_resource_stat
(
    id                 bigint         not null auto_increment comment '主键ID',
    _tenant_id         bigint         not null comment '租户ID',
    user_id            bigint         not null comment '用户ID',
    type               varchar(50)    not null comment '类型：CONSUMPTION-消费，SALES-销售',
    target_type        varchar(50)    not null comment '目标类型：Agent-智能体，Model-模型，Workflow-工作流，Plugin-插件',
    target_id          bigint         not null comment '目标ID',
    dt                 varchar(8)     not null comment '日期（yyyyMMdd）',
    call_count         bigint         not null default 0 comment '调用次数',
    call_failed_count  bigint         not null default 0 comment '调用失败次数',
    credit_amount      decimal(30, 6) not null default 0.000000 comment '积分金额',
    fee_amount         decimal(30, 6) not null default 0.000000 comment '费用金额',
    cache_input_tokens bigint         not null default 0 comment '缓存输入Token数',
    input_tokens       bigint         not null default 0 comment '输入Token数',
    output_tokens      bigint         not null default 0 comment '输出Token数',
    extra              json                    null comment '扩展字段',
    created            datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified           datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    key idx_dt (dt),
    key idx_target (target_type, target_id),
    key idx_tenant_user_dt (_tenant_id, user_id, dt)
);

create table bill_order
(
    id           bigint         not null auto_increment comment '主键ID',
    _tenant_id   bigint         not null comment '租户ID',
    user_id      bigint         not null comment '用户ID',
    description  varchar(500)            null comment '订单描述',
    biz_type     varchar(50)    not null comment '业务类型：CreditPurchase-积分购买，Subscription-订阅',
    order_status varchar(50)    not null default 'PENDING' comment '订单状态：PENDING-待支付，PAID-已支付，CANCELLED-已取消',
    pay_status   varchar(50)    not null default 'PENDING' comment '支付状态：PENDING-待支付，PROCESSING-处理中，SUCCESS-支付成功，FAILED-支付失败，CLOSED-已关闭',
    amount       decimal(10, 2) not null default 0.00 comment '订单金额',
    extra        json                    null comment '扩展字段',
    created      datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified     datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    key idx_created (_tenant_id, created),
    key idx_order_status (_tenant_id, order_status),
    key idx_pay_status (_tenant_id, pay_status),
    key idx_tenant_id (_tenant_id, biz_type),
    key idx_user_id (user_id, biz_type)
);

create table bill_daily_revenue
(
    id         bigint         not null auto_increment comment '主键ID',
    _tenant_id bigint         not null comment '租户ID',
    user_id    bigint         not null comment '用户ID',
    dt         varchar(8)     not null comment '日期（yyyyMMdd）',
    amount     decimal(30, 6) not null default 0.000000 comment '收益金额',
    status     varchar(50)    not null default 'PENDING' comment '结算状态：PENDING-待结算，WITHDRAW_APPLYING-提现申请中，PAYING-打款中，SETTLED-已结算',
    created    datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified   datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_user_dt (_tenant_id, user_id, dt),
    key idx_status (status),
    key idx_user_id (user_id)
);

create table pricing_config
(
    id           bigint       not null auto_increment comment '主键',
    space_id     bigint       not null default -1 comment '工作空间ID，-1为系统级',
    target_type  varchar(50)  not null comment '定价对象类型：AGENT/SKILL/KNOWLEDGE/MODEL',
    target_id    varchar(100) not null comment '定价对象ID',
    pricing_type varchar(50)  not null comment '定价类型：ONE_TIME/BUYOUT/MONTHLY/SUBSCRIPTION_PLAN/TIERED',
    price        decimal(10, 2)         null comment '价格（单次、买断、包月时有效）',
    trial_count  int          not null default 0 comment '可试用次数，0=不支持试用',
    status       tinyint      not null default 1 comment '状态：0-禁用，1-启用',
    _tenant_id   bigint       not null comment '租户ID',
    created      datetime     not null default CURRENT_TIMESTAMP comment '创建时间',
    modified     datetime     not null default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_target (target_type, target_id, _tenant_id)
);

create table bill_withdraw_revenue_ref
(
    id             bigint not null auto_increment comment '主键ID',
    _tenant_id     bigint not null comment '租户ID',
    application_id bigint not null comment '提现申请ID',
    revenue_id     bigint not null comment '每日收益ID',
    primary key (id),
    key idx_application_id (application_id),
    key idx_revenue_id (revenue_id)
);

create table bill_withdraw_config
(
    id            bigint         not null auto_increment comment '主键ID',
    _tenant_id    bigint         not null comment '租户ID',
    min_amount    decimal(10, 2) not null default 0.00 comment '最低提现金额',
    monthly_limit int            not null default 0 comment '每月提现次数限制（0表示不限制）',
    daily_limit   int            not null default 0 comment '每日提现次数限制（0表示不限制）',
    limit_mode    varchar(50)    not null default 'ALL' comment '限制模式：ALL-同时满足，ANY-任一满足',
    created       datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified      datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_tenant_id (_tenant_id)
);

create table credit_flow
(
    id             bigint         not null auto_increment comment '主键ID',
    _tenant_id     bigint         not null comment '租户ID',
    user_id        bigint         not null comment '用户ID',
    batch_no       varchar(64)             null comment '批次号',
    credit_type    tinyint        not null comment '积分类型：1-订阅积分，2-增购积分，3-活动积分，4-手动发放',
    operation_type tinyint        not null comment '操作类型：1-增加，2-扣减',
    amount         decimal(20, 2) not null comment '积分数量',
    before_amount  decimal(20, 2) not null comment '操作前积分',
    after_amount   decimal(20, 2) not null comment '操作后积分',
    biz_no         varchar(64)             null comment '业务单号',
    created        datetime default CURRENT_TIMESTAMP comment '创建时间',
    remark         varchar(500)            null comment '备注',
    primary key (id),
    key idx_batch_no (batch_no),
    key idx_biz_no (biz_no),
    key idx_created (created),
    key idx_user_id (user_id)
);

create table bill_order_item
(
    id          bigint         not null auto_increment comment '主键ID',
    _tenant_id  bigint         not null comment '租户ID',
    order_id    bigint         not null comment '订单ID',
    target_type varchar(50)    not null comment '目标类型：Plan-订阅计划，CreditPackage-积分套餐',
    target_name varchar(200)            null comment '目标名称',
    target_id   bigint         not null comment '目标ID',
    price       decimal(10, 2) not null default 0.00 comment '单价',
    count       int            not null default 1 comment '数量',
    snapshot    json                    null comment '快照',
    created     datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified    datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    key idx_order_id (order_id)
);

create table trial_record
(
    id          bigint       not null auto_increment comment '主键',
    user_id     bigint       not null comment '用户ID',
    target_type varchar(50)  not null comment '业务类型',
    target_id   varchar(100) not null comment '业务对象ID',
    used_count  int          not null default 0 comment '已使用次数',
    _tenant_id  bigint       not null comment '租户ID',
    created     datetime     not null default CURRENT_TIMESTAMP comment '创建时间',
    modified    datetime     not null default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_user_target (user_id, target_type, target_id, _tenant_id)
);

create table user_subscription
(
    id              bigint      not null auto_increment comment '主键ID',
    _tenant_id      bigint      not null comment '租户ID',
    user_id         bigint      not null comment '用户ID',
    plan_id         bigint      not null comment '计划ID',
    biz_type        varchar(32) not null comment '业务类型',
    biz_id          varchar(32) not null default '-1' comment '业务ID',
    period          tinyint     not null comment '订阅周期类型',
    start_time      datetime    not null comment '开始时间',
    end_time        datetime    not null comment '结束时间',
    status          tinyint              default 0 comment '状态：0-生效中，1-已过期，2-已取消',
    call_used_count int         not null default 0 comment '已使用调用次数',
    next_reset_time datetime             null comment '下次重置时间',
    extra           json                 null comment '扩展数据',
    created         datetime             default CURRENT_TIMESTAMP comment '创建时间',
    modified        datetime             default CURRENT_TIMESTAMP comment '更新时间',
    primary key (id),
    unique key uk_user_plan (user_id, plan_id),
    key idx_biz_type (biz_type),
    key idx_end_time (end_time),
    key idx_next_reset_time (next_reset_time),
    key idx_plan_id (plan_id),
    key idx_user_biz (user_id, biz_type, biz_id)
);

create table model_provider
(
    id         bigint       not null auto_increment comment '主键ID',
    _tenant_id bigint       not null comment '租户ID',
    pid        varchar(64)  not null comment '提供商ID',
    name       varchar(200) not null comment '提供商名称',
    icon       varchar(500)          null comment '图标',
    api_info   json                 null comment 'API信息',
    created    datetime default CURRENT_TIMESTAMP comment '创建时间',
    modified   datetime default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    key idx_tenant_id (_tenant_id)
);

create table pay_order
(
    id                       bigint       not null auto_increment comment '主键',
    _tenant_id               bigint       not null comment '租户ID',
    biz_order_no             varchar(128) not null comment '业务订单号',
    biz_scene                varchar(64)           null comment '业务场景',
    order_amount             bigint       not null comment '订单金额（分）',
    subject                  varchar(512)          null comment '摘要',
    ext                      json                 null comment '扩展',
    pay_mode                 varchar(32)  not null comment '支付模式：scan',
    pay_channel              varchar(32)           null comment '支付渠道：WxPay / AliPay / UnionPay',
    platform_fee             bigint                null comment '平台费（分）',
    provider_fee             bigint                null comment '通道费（分）',
    net_amount               bigint                null comment '净额（分）',
    gateway_payment_order_no varchar(128)          null comment '网关支付单号',
    gateway_sync_status      varchar(32)  not null comment '网关同步：PENDING / SUCCESS / FAILED',
    gateway_last_error       varchar(2000)         null comment '网关最近一次错误信息',
    gateway_order_status     varchar(64)           null comment '网关订单状态',
    biz_notify_status        varchar(32)           null comment '业务通知：POLLING / NOTIFIED / TIMEOUT',
    paid_at                  datetime              null comment '支付成功时间',
    created                  datetime default CURRENT_TIMESTAMP comment '创建时间',
    modified                 datetime default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    key idx_tenant_biz_id (_tenant_id, biz_order_no, id),
    key idx_tenant_gateway (_tenant_id, gateway_payment_order_no),
    key idx_tenant_created_id (_tenant_id, created, id),
    key idx_sync_fail_scan (gateway_sync_status, biz_notify_status, modified, id),
    key idx_reconcile_scan (gateway_sync_status, gateway_order_status, modified, id),
    unique key uk_tenant_biz_order (_tenant_id, biz_order_no)
);

create table bill_revenue_detail
(
    id          bigint         not null auto_increment comment '主键ID',
    _tenant_id  bigint         not null comment '租户ID',
    user_id     bigint         not null comment '用户ID',
    dt          varchar(8)     not null comment '日期（yyyyMMdd）',
    amount      decimal(30, 6) not null default 0.000000 comment '金额',
    type        varchar(50)    not null comment '类型：Plan-计划购买，ModelCall-模型调用，ToolCall-工具调用',
    type_id     bigint                  null comment '类型关联ID（Plan时为订阅计划ID）',
    order_id    bigint                  null comment '关联订单ID',
    target_type varchar(50)             null comment '目标类型：Agent/Skill/Model/Plugin/Mcp/Workflow',
    target_id   bigint                  null comment '目标ID',
    remark      varchar(500)            null comment '备注',
    extra       json                    null comment '扩展字段（如模型token使用等）',
    biz_no      varchar(100)            null comment '业务单号（幂等性保证，相同bizNo不会重复记录）',
    created     datetime                default CURRENT_TIMESTAMP comment '创建时间',
    modified    datetime                default CURRENT_TIMESTAMP comment '修改时间',
    primary key (id),
    unique key uk_biz_no (biz_no),
    key idx_dt (dt),
    key idx_order_id (order_id),
    key idx_target (target_type, target_id),
    key idx_type (type),
    key idx_user_id (user_id)
);

create table document_parse_status_record
(
    id                 bigint not null auto_increment comment '主键',
    create_time        datetime          null comment '创建时间',
    execute_state      varchar(20)       null comment '执行状态（1:执行成功、2：执行失败、0进行中）',
    success_count      bigint            null comment '成功条数',
    error_count        bigint            null comment '失败条数',
    start_time         datetime          null comment '执行开始时间',
    end_time           datetime          null comment '执行结束时间',
    execute_content    varchar(800)      null comment '存放完成了哪些知识库同步，需要包含同步成功或失败的状态',
    execute_error_logs varchar(800)      null comment '执行的异常日志',
    _tenant_id         bigint            null,
    primary key (id)
);

create table document_parse_status
(
    id            bigint  not null auto_increment comment '主键ID',
    document_id   bigint  not null comment '文档ID（逻辑外键，关联knowledge_document.id）',
    kb_id         bigint  not null comment '知识库ID',
    triple_status tinyint not null default 0 comment '三元组解析状态：0-未开始，1-进行中，2-成功，3-禁用，10-失败',
    _tenant_id    bigint           null comment '租户ID',
    created       datetime         default CURRENT_TIMESTAMP comment '创建时间',
    modified      datetime         default CURRENT_TIMESTAMP comment '更新时间',
    task_id       bigint           null comment '任务编号',
    primary key (id),
    key idx_document_id (document_id),
    key idx_kb_id (kb_id)
);

