CREATE OR REPLACE TYPE t_rec_sysconfig AS OBJECT
(
    id_sys_config      VARCHAR2(200),
    desc_sys_config    VARCHAR2(4000),
    desc_functionality VARCHAR2(200),
    desc_value         VARCHAR2(4000),
    flg_fill_type      VARCHAR2(1),
    id_software        NUMBER(24),
    software_name      VARCHAR2(4000),
    flg_edit           VARCHAR2(1),
    flg_schema         VARCHAR2(1)
)
;
