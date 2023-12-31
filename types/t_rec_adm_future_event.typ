-- CHANGED BY: Jorge Silva
-- CHANGE DATE: 14/08/2014
-- CHANGE REASON: [ALERT-292603] dev db - Scheduler: missing professional chosen in requisition
BEGIN
  EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_adm_future_event as Object(
        sel_type                      VARCHAR2(4000 CHAR),
        event_type                    VARCHAR2(4000 CHAR),
        id_event                      NUMBER(24),
        id_exam_req_det               NUMBER(24),
        id_exam_req                   NUMBER(24),
        num_clin_record               VARCHAR2(4000 CHAR),
        id_event_type                 VARCHAR2(4000 CHAR),
        event_type_icon               VARCHAR2(4000 CHAR),
        event_type_name_title         VARCHAR2(4000 CHAR),
        event_type_clinical_service   VARCHAR2(4000 CHAR),
        location                      VARCHAR2(4000 CHAR),
        id_location                   NUMBER(24),
        id_schedule                   NUMBER(24),
        desc_dep_clin_serv            VARCHAR2(4000 CHAR),
        id_dep_clin_serv              VARCHAR2(4000 CHAR),
        id_professional               VARCHAR2(4000 CHAR),
        professional                  VARCHAR2(4000 CHAR),
        nick_name                     VARCHAR2(4000 CHAR),
        dt_request                    VARCHAR2(4000 CHAR),
        dt_request_desc               VARCHAR2(4000 CHAR),
        dt_scheduled                  VARCHAR2(4000 CHAR),
        dt_scheduled_desc             VARCHAR2(4000 CHAR),
        flg_status                    VARCHAR2(4000 CHAR),
        desc_status                   VARCHAR2(4000 CHAR),
        photo                         VARCHAR2(4000 CHAR),
        id_patient                    NUMBER(24),
        patient_name                  VARCHAR2(4000 CHAR),
        pat_age                       VARCHAR2(4000 CHAR),
        gender                        VARCHAR2(4000 CHAR),
        id_complaint                  NUMBER(24),
        desc_reason                   VARCHAR2(4000 CHAR),
        id_prof_orig                  VARCHAR2(4000 CHAR),
        desc_prof_orig                VARCHAR2(4000 CHAR),
        id_prof_dest                  VARCHAR2(4000 CHAR),
        desc_prof_dest                VARCHAR2(4000 CHAR),
        dt_server                     VARCHAR2(4000 CHAR),
        dt_proposed                   VARCHAR2(4000 CHAR),
        request_date                  VARCHAR2(4000 CHAR),
        status_desc                   VARCHAR2(4000 CHAR),
        epis_id_dep_clin_serv         VARCHAR2(4000 CHAR),
        flg_epis_type                 VARCHAR2(4000 CHAR),
        consult_decision              VARCHAR2(4000 CHAR),
        flg_can_ok                    VARCHAR2(4000 CHAR),
        flg_can_cancel                VARCHAR2(4000 CHAR),
        status_icon                   VARCHAR2(4000 CHAR),
        request_status_desc           VARCHAR2(4000 CHAR),
        id_episode                    NUMBER(24),
        status                        VARCHAR2(4000 CHAR),
        flag_status                   VARCHAR2(4000 CHAR),
        id_clinical_service           VARCHAR2(4000 CHAR),
        id_exam                       NUMBER(24),
        dt_req_begin                  VARCHAR2(4000 CHAR),
        order_date                    VARCHAR2(4000 CHAR),
        id_created_professional       NUMBER(24),
        notes                         VARCHAR2(4000 CHAR),
        flg_contact_type              VARCHAR2(4000 CHAR),
        id_content                    VARCHAR2(4000 CHAR),
        id_workflow                   NUMBER(24),
        flg_type_of_external_resource VARCHAR2(1 CHAR),
        id_external_resource          NUMBER(24))';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/