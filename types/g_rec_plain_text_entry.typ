-- CHANGED BY: Pedro Henriques
-- CHANGED DATE: 2017-07-04
-- CHANGE REASON: ALERT-331803

CREATE OR REPLACE TYPE g_rec_plain_text_entry AS OBJECT (
				id_epis_documentation NUMBER(24),
        dt_creation_tstz      TIMESTAMP(6) WITH LOCAL TIME ZONE,
        template_title        VARCHAR2(4000),
        plain_text_entry      CLOB,
        area_name              VARCHAR2(4000),
				desc_component        VARCHAR2(4000)
				)
;

-- CHANGED END: Pedro Henriques