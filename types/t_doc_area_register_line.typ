-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 31-08-2017
-- CHANGE REASON: ALERT-332725 - NOM024 - Additional needs related to guide "SAEH" Pregnancy process
CREATE OR REPLACE TYPE t_doc_area_register_line IS OBJECT
(
    id_epis_documentation    NUMBER(24),
    PARENT                   VARCHAR2(50 CHAR),
    id_doc_template          NUMBER(24),
    dt_creation              VARCHAR2(50 CHAR),
    dt_register              VARCHAR2(50 CHAR),
    dt_pat_pregnancy_tstz    TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_professional          NUMBER(24),
    nick_name                VARCHAR2(800),
    desc_speciality          VARCHAR2(200 CHAR),
    id_doc_area              NUMBER(24),
    flg_status               VARCHAR2(2 CHAR),
    flg_preg_status          VARCHAR2(2 CHAR),
    desc_status              VARCHAR2(800 CHAR),
    notes                    VARCHAR2(4000),
    dt_last_update           VARCHAR2(200 CHAR),
    flg_type_register        VARCHAR2(1),
    flg_type                 VARCHAR2(2 CHAR),
    n_pregnancy              VARCHAR2(1000 CHAR),
    pregnancy_number         NUMBER,
    dt_last_menstruation     VARCHAR2(50 CHAR),
    weeks_number             NUMBER,
    days_number              NUMBER,
    weeks_measure            VARCHAR2(1000 CHAR),
    weight_measure           VARCHAR2(200 CHAR),
    n_children               NUMBER(2),
    flg_abortion_type        VARCHAR2(2),
    flg_childbirth_type      table_varchar,
    flg_child_status         table_varchar,
    flg_gender               table_varchar,
    weight                   table_number,
    weight_um                table_number,
    present_health           table_varchar,
    flg_present_health       table_varchar,
    flg_complication         VARCHAR2(1000 CHAR),
    notes_complications      VARCHAR2(1000 CHAR),
    id_inst_intervention     NUMBER(24),
    flg_desc_intervention    VARCHAR2(1),
    desc_intervention        VARCHAR2(1000 CHAR),
    dt_intervention          VARCHAR2(50 CHAR),
    dt_intervention_tstz     TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_init_pregnancy        DATE,
    flg_dt_interv_precision  VARCHAR2(1 CHAR),
    dt_intervention_chr      VARCHAR2(200),
    pregnancy_notes          VARCHAR2(1000 CHAR),
    flg_menses               VARCHAR2(1 CHAR),
    cycle_duration           NUMBER(2),
    flg_use_constraceptives  VARCHAR2(1 CHAR),
    type_description         VARCHAR2(1000 CHAR),
    type_description_field   VARCHAR2(1000 CHAR),
    type_ids                 table_varchar,
    type_free_text           CLOB,
    dt_contrac_meth_end      VARCHAR2(50 CHAR),
    flg_dt_contrac_precision VARCHAR2(1 CHAR),
    dt_pdel_lmp              VARCHAR2(50 CHAR),
    code_state               VARCHAR2(10 CHAR),
    code_year                VARCHAR2(10 CHAR),
    code_number              NUMBER(24),
    weeks_number_exam        NUMBER,
    days_number_exam         NUMBER,
    weeks_number_us          NUMBER(10, 2),
    days_number_us           NUMBER(10, 2),
    dt_pdel_correct          VARCHAR2(50 CHAR),
    dt_us_performed          VARCHAR2(50 CHAR),
    num_weeks_at_us          NUMBER,
    num_days_at_us           NUMBER,
    flg_del_onset            VARCHAR2(1 CHAR),
    del_duration             VARCHAR2(10 CHAR),
    flg_extraction           VARCHAR2(1 CHAR),
    extraction_desc          VARCHAR2(800 CHAR),
    flg_preg_out_type        VARCHAR2(2 CHAR),
    preg_out_type_desc       VARCHAR2(800 CHAR),
    num_births               NUMBER(2),
    num_abortions            NUMBER(2),
    num_gestations           NUMBER(2),
    flg_gest_weeks           VARCHAR2(1 CHAR),
    flg_gest_weeks_exam      VARCHAR2(1 CHAR),
    flg_gest_weeks_us        VARCHAR2(1 CHAR),           
    viewer_category          NUMBER,
    viewer_category_desc     VARCHAR2(50 CHAR),
    viewer_id_prof           NUMBER(24),
    viewer_id_epis           NUMBER(24),
    viewer_date              VARCHAR2(50 CHAR),
    rank                     NUMBER
);
/
-- CHANGE END: Anna Kurowska