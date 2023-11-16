CREATE OR REPLACE TYPE t_rec_alert_config FORCE AS OBJECT
(
    id_sys_alert_config  NUMBER(24),
    id_sys_alert         NUMBER(24),
    id_software          NUMBER(24),
    id_institution       NUMBER(24),
    id_profile_template  NUMBER(12),
    id_sys_shortcut      NUMBER(24),
    id_shortcut_pk       NUMBER(24),
    flg_read             VARCHAR2(1 CHAR),
    flg_duplicate        VARCHAR2(1 CHAR),
    msg_dup_yes          VARCHAR2(200 CHAR),
    msg_dup_no           VARCHAR2(200 CHAR),
    flg_sms              VARCHAR2(1 CHAR),
    flg_email            VARCHAR2(1 CHAR),
    flg_im               VARCHAR2(1 CHAR),
    flg_notification_all VARCHAR2(1 CHAR),
    flg_delete           VARCHAR2(1 CHAR) 
);
/
