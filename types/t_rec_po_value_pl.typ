CREATE OR REPLACE TYPE t_rec_po_value_pl force AS OBJECT
(
    id_parameter      NUMBER(24), -- Parameter identifier
    flg_type          VARCHAR2(2 CHAR), -- Lab Tests/Vital Signs/Imaging
    id_result         NUMBER(24), -- local result identifier
    id_episode        NUMBER(24), -- result registration episode
    id_institution    NUMBER(24), -- result registration institution
    id_prof_reg       NUMBER(24), -- professional who registered result
    dt_result         TIMESTAMP WITH LOCAL TIME ZONE, -- result date
    dt_reg            TIMESTAMP WITH LOCAL TIME ZONE, -- registration date
    flg_status        VARCHAR2(1 CHAR), -- result status: (A)ctive, (C)anceled
    desc_result       clob, -- result description
    id_unit_measure   NUMBER(24), -- Id unit
    desc_unit_measure VARCHAR2(1000 CHAR), -- result measurement unit description
    icon              VARCHAR2(200 CHAR), -- result icon
    lab_param_count   NUMBER(3, 0), -- lab test result parameter count
    lab_param_id      NUMBER(24), -- lab test parameter identifier (ANALYSIS_PARAMETER)
    lab_param_rank    NUMBER(24), -- lab test parameter rank
    val_min           VARCHAR2(200 CHAR), -- minimum reference value
    val_max           VARCHAR2(200 CHAR), -- maximum reference value
    abnorm_value      VARCHAR2(200 CHAR), -- result abnormality value
    option_codes      table_varchar, -- result multichoice option codes
    flg_cancel        VARCHAR2(1 CHAR), -- value cancelable? Y/N
    dt_cancel         TIMESTAMP WITH LOCAL TIME ZONE, -- result cancelation date
    id_prof_cancel    NUMBER(24), -- professional who canceled result
    id_cancel_reason  NUMBER(24), -- cancelation reason
    notes_cancel      clob, -- result cancelation notes
    woman_health_id   VARCHAR2(50 CHAR), -- WOMAN_HEALTH indentifier
    flg_ref_value     VARCHAR2(1 CHAR), -- WOMAN_HEALTH indentifier
    dt_harvest        TIMESTAMP WITH LOCAL TIME ZONE,
    dt_execution      TIMESTAMP WITH LOCAL TIME ZONE,
    notes             clob,
    id_sample_type    NUMBER(12)
);
/