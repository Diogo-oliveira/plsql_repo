-- CMF
drop type t_tbl_rehab_treat;
drop type t_rec_rehab_treat;




CREATE OR REPLACE TYPE t_rec_rehab_treat AS OBJECT
(
    rec_type                  VARCHAR2(4000),
    id_rehab_presc            NUMBER,
		id_rehab_sch_need         NUMBER,
    id_rehab_area_interv      NUMBER,
    id_intervention           NUMBER,
    desc_interv               VARCHAR2(4000),
    desc_area                 VARCHAR2(4000),
    id_rehab_area             NUMBER,
    prof_requested            VARCHAR2(4000),
    id_prof_requested         NUMBER,
    dt_requested_str          VARCHAR2(4000),
    dt_requested              TIMESTAMP(6) WITH LOCAL TIME ZONE,
    icon                      VARCHAR2(4000),
    icon_label                VARCHAR2(4000),
    icon_color                VARCHAR2(50),
    back_color                VARCHAR2(50),
    flg_status                VARCHAR2(4000),
    id_exec_institution       NUMBER,
    exec_institution          VARCHAR2(4000),
    instructions              VARCHAR2(4000),
    has_notes                 VARCHAR2(4000),
    notes                     VARCHAR2(4000),
    flg_status_description    VARCHAR2(4000),
    session_type              VARCHAR2(4000),
    execution_local           VARCHAR2(4000),
    prof_name_requested       VARCHAR2(4000),
    prof_speciality_requested VARCHAR2(4000),
    cancel_reason_desc        VARCHAR2(4000),
    cancel_reason_notes       VARCHAR2(4000),
    label_cancel_reason       VARCHAR2(4000),
    label_reason_notes        VARCHAR2(4000),
    flg_laterality            VARCHAR2(4000),
    desc_laterality           VARCHAR2(4000),
    flg_laterality_mcdt       VARCHAR2(4000),
    id_codification           NUMBER,
    codification              VARCHAR2(4000),
    id_mcdt_codification      NUMBER,
    flg_priority              VARCHAR2(4000),
    not_order_reason_desc     VARCHAR2(4000),
    flg_clinical_question     VARCHAR2(1)
);
  
create or replace type t_tbl_rehab_treat is table of t_rec_rehab_treat;
