CREATE OR REPLACE TYPE t_bp_task_detail_hist force AS OBJECT
(
    action                               VARCHAR2(1000 CHAR),
    desc_action                          VARCHAR2(1000 CHAR),
    exec_number                          NUMBER(24),
    desc_hemo_type                       VARCHAR2(1000 CHAR),
    desc_diagnosis                       VARCHAR2(1000 CHAR),
    desc_diagnosis_new                   VARCHAR2(1000 CHAR),
    clinical_purpose                     VARCHAR2(1000 CHAR),
    clinical_purpose_new                 VARCHAR2(1000 CHAR),
    priority                             VARCHAR2(1000 CHAR),
    priority_new                         VARCHAR2(1000 CHAR),
    special_type                         VARCHAR2(1000 CHAR),
    special_type_new                     VARCHAR2(1000 CHAR),
    desc_time                            VARCHAR2(1000 CHAR),
    desc_time_new                        VARCHAR2(1000 CHAR),
    order_recurrence                     VARCHAR2(1000 CHAR),
    execution                            VARCHAR2(1000 CHAR),
    transfusion_type_desc                VARCHAR2(1000 CHAR),
    transfusion_type_desc_new            VARCHAR2(1000 CHAR),
    quantity_ordered                     VARCHAR2(1000 CHAR),
    quantity_ordered_new                 VARCHAR2(1000 CHAR),
    perform_location                     VARCHAR2(1000 CHAR),
    perform_location_new                 VARCHAR2(1000 CHAR),
    dt_req                               VARCHAR2(1000 CHAR),
    special_instr                        VARCHAR2(1000 CHAR),
    special_instr_new                    VARCHAR2(1000 CHAR),
    tech_notes                           VARCHAR2(1000 CHAR),
    tech_notes_new                       VARCHAR2(1000 CHAR),
    notes                                VARCHAR2(1000 CHAR),
    prof_order                           VARCHAR2(1000 CHAR),
    dt_order                             VARCHAR2(200 CHAR),
    order_type                           VARCHAR2(1000 CHAR),
    financial_entity                     VARCHAR2(1000 CHAR),
    health_plan                          VARCHAR2(1000 CHAR),
    insurance_number                     NUMBER(24),
    dt_blood_product_det_hist            VARCHAR2(1000 CHAR),
    transfusion                          VARCHAR2(1000 CHAR),
    quantity_received                    VARCHAR2(1000 CHAR),
    barcode                              VARCHAR2(1000 CHAR),
    blood_group                          VARCHAR2(1000 CHAR),
    blood_group_rh                       VARCHAR2(1000 CHAR),
    expiration_date                      VARCHAR2(1000 CHAR),
    prof_perform                         VARCHAR2(1000 CHAR),
    start_time                           VARCHAR2(1000 CHAR),
    end_time                             VARCHAR2(1000 CHAR),
    qty_given                            VARCHAR2(1000 CHAR),
    desc_perform                         VARCHAR2(1000 CHAR),
    exec_notes                           VARCHAR2(1000 CHAR),
    action_reason                        VARCHAR2(1000 CHAR),
    action_notes                         VARCHAR2(1000 CHAR),
    id_prof_match                        VARCHAR2(1000 CHAR),
    dt_match_tstz                        VARCHAR2(1000 CHAR),
    dt_req_tstz                          VARCHAR2(1000 CHAR),
    dt_last_update_tstz                  VARCHAR2(1000 CHAR),
    dt_blood_product_det_h               VARCHAR2(1000 CHAR),
    dt_last_update_h                     VARCHAR2(1000 CHAR),
    id_professional                      NUMBER(24),
    id_prof_last_update                  NUMBER(24),
    id_professional_h                    NUMBER(24),
    id_prof_last_update_h                NUMBER(24),
    co_sign                              VARCHAR2(1000 CHAR),
    clinical_indication                  VARCHAR2(1000 CHAR),
    instructions                         VARCHAR2(1000 CHAR),
    health_insurance                     VARCHAR2(1000 CHAR),
    registry                             VARCHAR2(1000 CHAR),
    desc_compatibility                   VARCHAR2(1000 CHAR),
    notes_compatibility                  VARCHAR2(1000 CHAR),
    condition                            VARCHAR2(1000 CHAR),
    blood_group_desc                     VARCHAR2(1000 CHAR),
    lab_test_mother                      VARCHAR2(1000 CHAR),
    donation_code                        VARCHAR2(200 CHAR),
    duration                             VARCHAR2(50),
    result_1                             VARCHAR2(200 CHAR),
    dt_result_1                          VARCHAR2(200 CHAR),
    result_sig_1                         VARCHAR2(200 CHAR),
    result_2                             VARCHAR2(200 CHAR),
    dt_result_2                          VARCHAR2(200 CHAR),
    result_sig_2                         VARCHAR2(200 CHAR),
    req_statement_without_crossmatch     VARCHAR2(1000 CHAR),
    req_statement_without_crossmatch_new VARCHAR2(1000 CHAR),
    req_prof_without_crossmatch          VARCHAR2(1000 CHAR),
    req_prof_without_crossmatch_new      VARCHAR2(1000 CHAR),
    screening                            VARCHAR2(200 CHAR),
    nat_test                             VARCHAR2(200 CHAR),
    send_unit                        VARCHAR2(200 CHAR)
);
/