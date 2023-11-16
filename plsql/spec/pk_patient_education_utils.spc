/*-- Last Change Revision: $Rev: 2028851 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_education_utils IS

    FUNCTION get_desc_topic
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_topic   IN nurse_tea_req.id_nurse_tea_topic%TYPE,
        i_desc_topic_aux       IN nurse_tea_req.desc_topic_aux%TYPE,
        i_code_nurse_tea_topic IN nurse_tea_topic.code_nurse_tea_topic%TYPE
        
    ) RETURN nurse_tea_req.desc_topic_aux%TYPE;

    FUNCTION get_instructions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE prv_alter_ntr_by_id
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE DEFAULT NULL,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE DEFAULT NULL,
        i_dt_nurse_tea_req_str IN VARCHAR2 DEFAULT NULL,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE DEFAULT NULL,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE DEFAULT NULL,
        i_id_cancel_reason     IN nurse_tea_req.id_cancel_reason%TYPE DEFAULT NULL,
        o_rowids               IN OUT table_varchar
    );

    FUNCTION prv_new_nurse_tea_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_flg_status           IN nurse_tea_req.flg_status%TYPE,
        i_dt_nurse_tea_req_str IN VARCHAR2,
        i_id_prof_req          IN profissional,
        i_dt_begin_str         IN VARCHAR2 DEFAULT NULL,
        i_notes_req            IN nurse_tea_req.notes_req%TYPE,
        i_dt_close_str         IN VARCHAR2 DEFAULT NULL,
        i_id_prof_close        IN nurse_tea_req.id_prof_close%TYPE DEFAULT NULL,
        i_notes_close          IN nurse_tea_req.notes_close%TYPE DEFAULT NULL,
        i_req_header           IN nurse_tea_req.req_header%TYPE DEFAULT NULL,
        i_id_patient           IN nurse_tea_req.id_patient%TYPE,
        i_id_visit             IN nurse_tea_req.id_visit%TYPE,
        o_rowids               OUT table_varchar
    ) RETURN nurse_tea_req.id_nurse_tea_req%TYPE;

    FUNCTION get_pat_educ_add_resources
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN CLOB;

    FUNCTION get_pat_education_end_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN nurse_tea_req.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

    FUNCTION tf_get_order_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order;

    FUNCTION tf_get_order_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_order_hist;

    FUNCTION tf_get_execution_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_exec;

    FUNCTION tf_get_cancel_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN t_tbl_health_education_cancel;

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_diagnosis_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    --
    FUNCTION get_id_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_number;

    FUNCTION get_desc_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_varchar;

    FUNCTION get_diagnosis_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_composition_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_nurse_teach_topic_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_nurse_tea_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_subject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB;

    g_error VARCHAR2(100);
    g_exception EXCEPTION;
    g_package_owner VARCHAR2(5) := 'ALERT';
    g_package_name  VARCHAR2(50) := 'PK_PATIENT_EDUCATION_UTILS';
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;

END pk_patient_education_utils;
/
