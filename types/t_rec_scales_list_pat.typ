-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 01/03/2010 14:31
-- CHANGE REASON: [ALERT-60380] Dev Barthel Idx
CREATE OR REPLACE TYPE t_rec_scales_list_pat IS OBJECT
(
    id_epis_documentation NUMBER(24),
    id_scales             NUMBER(24),
    id_doc_template       NUMBER(24),
    desc_class            VARCHAR2(4000),
    doc_desc_class        VARCHAR2(4000),
    soma                  NUMBER(24),
    id_professional       NUMBER(24),
    nick_name             VARCHAR2(800),
    date_target           VARCHAR2(4000),
    hour_target           VARCHAR2(4000),
    dt_last_update        VARCHAR2(4000),
dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    flg_status            VARCHAR2(1)
)
/
-- CHANGE END: Gustavo Serrano