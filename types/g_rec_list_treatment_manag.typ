create or replace TYPE g_rec_list_treatment_manag force as object(
        id_treat_manag                      NUMBER(24),
        desc_treat_manag                    VARCHAR2(1000 CHAR),
        desc_dosage                         VARCHAR2(32767 CHAR),
        flg_status                          VARCHAR2(1 CHAR),
        desc_status                         VARCHAR2(1000 CHAR),
        flg_type                            VARCHAR2(200 CHAR),
        desc_treatment_management           VARCHAR2(1000 CHAR),
        date_target                         VARCHAR2(200 CHAR),
        hour_target                         VARCHAR2(200 CHAR),
        status_icon_name                    VARCHAR2(1000 CHAR),
        type_icon_name                      VARCHAR2(200 CHAR),
        dt_server                           VARCHAR2(50 CHAR));

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 19/11/2015 11:32
-- CHANGE REASON: [ALERT-316951] 
CREATE OR REPLACE TYPE g_rec_list_treatment_manag AS OBJECT
(
    id_treat_manag            NUMBER(24),
    desc_treat_manag          VARCHAR2(1000 CHAR),
    desc_dosage               VARCHAR2(32767 BYTE),
    flg_status                VARCHAR2(1 CHAR),
    desc_status               VARCHAR2(1000 CHAR),
    flg_type                  VARCHAR2(200 CHAR),
    desc_treatment_management VARCHAR2(1000 CHAR),
    date_target               VARCHAR2(200 CHAR),
    hour_target               VARCHAR2(200 CHAR),
    status_icon_name          VARCHAR2(1000 CHAR),
    type_icon_name            VARCHAR2(200 CHAR),
    dt_server                 VARCHAR2(50 CHAR)
);
/
-- CHANGE END: Paulo Teixeira