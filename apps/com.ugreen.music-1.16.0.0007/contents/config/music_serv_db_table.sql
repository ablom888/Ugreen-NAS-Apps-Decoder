CREATE TABLE music_setting (
    music_setting_id SERIAL, --'音乐设置主键id'
    uid INT NOT NULL DEFAULT 0, --'用户id'
    support_cue_file BOOLEAN NOT NULL DEFAULT TRUE, --'是否支持 cue 文件。true-支持；false-不支持'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (music_setting_id),
    CONSTRAINT uq_uid
        UNIQUE(uid)
);

CREATE TABLE music_path_setting (
    music_path_setting_id SERIAL, --'音乐路径配置id'
    path_type INT NOT NULL DEFAULT 0, --'路径类型。1-共享音乐路径；2-个人音乐路径；3-用户设置路径'
    uid INT NOT NULL DEFAULT 0, --'用户 id'
    dir VARCHAR(1024) NOT NULL DEFAULT '', --'目录'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (music_path_setting_id),
    CONSTRAINT uq_uid_dir
        UNIQUE(uid,dir)
);

CREATE TABLE IF NOT EXISTS audio (
    audio_id SERIAL, -- '音频主键 id'
    source INT NOT NULL DEFAULT 0, -- '来源。1-内部存储；2-外部存储'
    song_title VARCHAR(200) NOT NULL DEFAULT '', -- '歌曲标题'
    audio_cover_url VARCHAR(200) NOT NULL DEFAULT '', -- '歌曲封面链接'
    duration INT NOT NULL DEFAULT 0, -- '持续时间'
    lyric_url VARCHAR(200) NOT NULL DEFAULT '', -- '歌词链接'
    singer_id BIGINT NOT NULL DEFAULT 0, -- '歌手 id'
    album_id BIGINT NOT NULL DEFAULT 0, -- '专辑 id'
    genre_id BIGINT NOT NULL DEFAULT 0, -- '类型 id'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (audio_id),
    CONSTRAINT uq_file_path
        UNIQUE(file_path),

    file_path VARCHAR(500) NOT NULL DEFAULT '' -- 冗余字段方便查看文件、删除文件等处理
)

CREATE TABLE IF NOT EXISTS singer (
    singer_id SERIAL, -- '歌手主键id'
    singer_name VARCHAR(200) NOT NULL DEFAULT '', -- '歌手名'
    pinyin_first VARCHAR(4) NOT NULL DEFAULT '', -- '拼音首字母'
    singer_intro VARCHAR(4096) NOT NULL DEFAULT '', -- '简介'
    singer_cover_url VARCHAR(255) NOT NULL DEFAULT '', --'封面链接'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (singer_id),
    CONSTRAINT uq_singer_name
        UNIQUE(singer_name)
)

CREATE TABLE IF NOT EXISTS album (
    album_id SERIAL, -- '专辑主键 id'
    singer_id BIGINT NOT NULL DEFAULT 0, -- '歌手 id'
    album_name VARCHAR(200) NOT NULL DEFAULT '', -- '专辑名'
    album_intro VARCHAR(4096) NOT NULL DEFAULT '', -- '简介'
    album_cover_url VARCHAR(255) NOT NULL DEFAULT '', --'封面链接'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (album_id),
    CONSTRAINT uq_singer_id_album_name
        UNIQUE(singer_id,album_name)
)

CREATE TABLE IF NOT EXISTS genre (
    genre_id SERIAL, -- '类型主键 id'
    genre_type INT NOT NULL DEFAULT 0, --'类型type。1-默认；2-来源文件tag或用户自己输入'
    genre_name VARCHAR(200) NOT NULL DEFAULT '', -- '类型名'
    genre_intro VARCHAR(4096) NOT NULL DEFAULT '', -- '简介'
    genre_cover_url VARCHAR(255) NOT NULL DEFAULT '', --'封面链接'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (genre_id),
    CONSTRAINT uq_genre_name
        UNIQUE(genre_name)
)


CREATE TABLE recently_played (
    recently_played_id SERIAL, --'最近播放主键 id'
    uid INT NOT NULL DEFAULT 0, --'用户id'
    audio_id BIGINT NOT NULL DEFAULT 0, --'音频id'
    last_access_time BIGINT NOT NULL DEFAULT 0, -- '上次访问时间。同一音乐再次访问会更新'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (recently_played_id),
    CONSTRAINT recently_played_uq_uid_audio_id
        UNIQUE(uid,audio_id)
);

CREATE TABLE audio_collect (
    audio_collect_id SERIAL, --'音乐收藏主键id'
    uid INT NOT NULL DEFAULT 0, --'用户id'
    audio_id BIGINT NOT NULL DEFAULT 0, --'音频id'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (audio_collect_id),
    CONSTRAINT audio_collect_uq_uid_audio_id
        UNIQUE(uid,audio_id)
);

CREATE TABLE songlist (
    songlist_id SERIAL, --'歌单主键id'
    uid INT NOT NULL DEFAULT 0, --'用户id'
    title VARCHAR(255) NOT NULL DEFAULT '', --'标题'
    cover_url VARCHAR(255) NOT NULL DEFAULT '', --'封面链接'
    intro VARCHAR(2048) NOT NULL DEFAULT '', --'简介'
    create_time BIGINT NOT NULL DEFAULT 0, -- '创建时间'
    PRIMARY KEY (songlist_id)
);

CREATE TABLE songlist_content (
    songlist_content_id SERIAL, --'歌单内容主键id'
    uid INT NOT NULL DEFAULT 0, --'用户id'。冗余个字段方便操作
    songlist_id INT NOT NULL DEFAULT 0, --'歌单id'
    audio_id BIGINT NOT NULL DEFAULT 0, --'音频id'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (songlist_content_id),
    CONSTRAINT songlist_content_uq_uid_songlist_id_audio_id
        UNIQUE(uid,songlist_id,audio_id)
);

CREATE TABLE songlist_share (
    songlist_share_id VARCHAR(255) NOT NULL DEFAULT '', --'主键id'
    uid INT NOT NULL DEFAULT 0, --'用户id'
    songlist_id INT NOT NULL DEFAULT 0, --'歌单id'
    password VARCHAR(255) NOT NULL DEFAULT '', --'密码'
    can_download BOOLEAN NOT NULL DEFAULT FALSE, --'能否下载音乐文件。true-能；false-不能。下载音频文件相关接口就检查password'
    validity_time BIGINT NOT NULL DEFAULT 0, -- '有效截止时间戳。单位是秒'
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, -- '创建时间'
    PRIMARY KEY (songlist_share_id)
);
