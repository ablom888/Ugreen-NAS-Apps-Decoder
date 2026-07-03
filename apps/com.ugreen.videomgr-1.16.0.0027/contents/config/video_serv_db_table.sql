CREATE TABLE media_lib_set (
    media_lib_set_id BIGSERIAL, --'主键id'
    media_name VARCHAR(1024) NOT NULL DEFAULT '', -- '媒体库名称'
    media_type_id INT NOT NULL DEFAULT 0, -- '媒体库类型id。1-电影；2-剧集；3-混合'
    media_lib_folder_arr VARCHAR(1024)[] NOT NULL DEFAULT '', -- '媒体库文件夹数组

    metadata_scraper_id_arr VARCHAR(1024)[] NOT NULL DEFAULT '', -- '元数据刮削器id数组。1-TMDB；2-DOUBAN
    pic_scraper_id_arr VARCHAR(1024)[] NOT NULL DEFAULT '', -- '图片刮削器id数组。1-TMDB；2-DOUBAN；3-缩略图

    read_local_info_first BOOLEAN NOT NULL DEFAULT false, -- '优先读取本地信息'
    nfo_info_save_to_local BOOLEAN NOT NULL DEFAULT false, -- 'nfo信息保存到本地'
    auto_add_to_collection BOOLEAN NOT NULL DEFAULT false, -- '自动添加到合集'
    pic_res_save_to_media_dir BOOLEAN NOT NULL DEFAULT false, -- '图片资源保存到媒体所在文件夹'
    -- user_privilege 用户可查看、管理、下载权限设置。用另外表关联处理
    tv_visible BOOLEAN NOT NULL DEFAULT false, -- 'tv端可见'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (media_lib_set_id)
);

CREATE TABLE video_config (
    video_config_id BIGSERIAL, --'主键id'
    douban_recognize BOOLEAN NOT NULL DEFAULT true, -- '豆瓣识别。总开关，false 时metadata_scraper_id_arr、pic_scraper_id_arr里的DOUBAN也不生效'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (video_config_id)
)

CREATE TABLE media_type (
    media_type_id BIGSERIAL, --'主键id'
    media_type_name VARCHAR(1024) NOT NULL DEFAULT '', --'名'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (media_type_id)
)

CREATE TABLE user_media_lib_permission (
    user_media_lib_permission_id BIGSERIAL, --'主键id'
    uid INT NOT NULL DEFAULT '', -- '用户id'
    media_lib_set_id INT NOT NULL DEFAULT '', -- '媒体库id'
    can_view BOOLEAN NOT NULL DEFAULT false, -- '可查看'
    can_manage BOOLEAN NOT NULL DEFAULT false, -- '可管理'
    can_download BOOLEAN NOT NULL DEFAULT false, -- '可下载'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (user_media_lib_permission_id),
    CONSTRAINT uq_uid_media_lib_set_id
        UNIQUE(uid,media_lib_set_id)
);

CREATE TABLE user_media_lib_permission_init (
    user_media_lib_permission_init_id BIGSERIAL, --'主键id。用户第一次访问影视中心时让前端请求下init接口，不存在则初始化user_media_lib_permission表里所有默认权限，分普通用户、管理员'
    uid INT NOT NULL DEFAULT '', -- '用户id'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (user_media_lib_permission_init_id),
    CONSTRAINT uq_uid
        UNIQUE(uid)
);

CREATE TABLE tmdb_set (
    tmdb_set_id BIGSERIAL, --'主键id'
    api_secret_key VARCHAR(255) NOT NULL DEFAULT '', --'api密钥'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (tmdb_set_id)
);

CREATE TABLE video_server_init (
    video_server_init_id BIGSERIAL, --'主键id'
    video_config_init BOOLEAN NOT NULL DEFAULT false, -- 'video_config表初始化'
    media_type_init BOOLEAN NOT NULL DEFAULT false, -- 'media_type表初始化'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (video_server_init_id)
);
