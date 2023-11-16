-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 08/04/2011 19:45
-- CHANGE REASON: [ALERT-122481] - Terminal illness
CREATE OR REPLACE TYPE "T_REC_ADV_DIR_DAR" force AS OBJECT
(
    order_by_default      INTERVAL DAY(9) TO SECOND,
    order_default         DATE,
    id_epis_documentation NUMBER(24),
    PARENT                NUMBER(24),
    id_doc_template       NUMBER(24),
    template_desc         VARCHAR2(1000 CHAR),
    dt_creation           VARCHAR2(1000 CHAR),
    dt_creation_tstz      TIMESTAMP WITH LOCAL TIME ZONE,
    dt_register           VARCHAR2(1000 CHAR),
    id_professional       NUMBER(24),
    nick_name             VARCHAR2(800 CHAR),
    desc_speciality       VARCHAR2(1000 CHAR),
    id_doc_area           NUMBER(24),
    flg_status            VARCHAR2(1 CHAR),
    desc_status           VARCHAR2(1000 CHAR),
    flg_current_episode   VARCHAR2(1 CHAR),
    notes                 CLOB,
    dt_last_update        VARCHAR2(1000 CHAR),
    dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    flg_detail            VARCHAR2(1 CHAR),
    flg_external          VARCHAR2(1 CHAR),
    flg_type_register     VARCHAR2(1 CHAR),
    flg_table_origin      VARCHAR2(1 CHAR),
    flg_was_reviewed      VARCHAR2(1 CHAR),
    flg_scope             VARCHAR2(1 CHAR),
    signature             VARCHAR2(1000 CHAR)
--FLG_SCOPE @values 
--          E - Adv. Directives inserted/edited or validated in the current episode
--          V - Adv. Directives inserted/edited or validated in the current visit
--          P - All Patient Adv. Directives
)
-- CHANGE END: Alexandre Santos
/
