-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 18/03/2010 17:55
-- CHANGE REASON: [ALERT-82146] 
CREATE OR REPLACE TYPE t_rec_doc_area_register IS OBJECT
(
    id_epis_documentation NUMBER(24),
    PARENT                NUMBER(24),
    id_doc_template       NUMBER(24),
    template_desc         VARCHAR2(4000),
    dt_creation           VARCHAR2(4000),
    dt_register           VARCHAR2(4000),
    id_professional       NUMBER(24),
    nick_name             VARCHAR2(800),
    desc_speciality       VARCHAR2(200),
    id_doc_area           NUMBER(24),
    flg_status            VARCHAR2(1),
    desc_status           VARCHAR2(800),
    notes                 VARCHAR2(4000),
    dt_last_update        VARCHAR2(4000),
    flg_type_register     VARCHAR2(1),
    flg_table_origin      VARCHAR2(1),
    dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE
)
/
-- CHANGE END: Gustavo Serrano