/*-- Last Change Revision: $Rev: 2028674 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ehr_nursing IS

    -- Author  : THIAGO.BRITO
    -- Created : 20-05-2008 18:42:18
    -- Purpose : NURSING - ALERT EHR

    /**
    * Returns EHR nursing notes for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  The patient nursing notes array for the EPISODE identifier.
    *
    * @author   Thiago Brito
    * @version  2.4.3
    * @since    2008/05/21
    */
    FUNCTION get_nursing_notes_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_clob;

    /**
    * Returns EHR nursing notes for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR nursing notes for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   THIAGO BRITO
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_nursing_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR assessments for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    * @param i_doc_area     DOC_AREA identifrier.
    *
    * @return  The patient assessments array for the EPISODE identifier.
    *
    * @author   Thiago Brito
    * @version  2.4.3
    * @since    2008/05/21
    */
    FUNCTION get_assessment_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE
    ) RETURN table_varchar;

    /**
    * Returns EHR assessments for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    * @param i_doc_area     DOC_AREA identifier.    
    *
    * @param o_cursor       The cursor with EHR assessments for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   THIAGO BRITO
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_assessment
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR diagnoses and interventions for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_id_episode   EPISODE identifier.
    *
    * @return  The patient diagnoses and interventions array for the EPISODE identifier.
    *
    * @author   Thiago Brito
    * @version  2.4.3
    * @since    2008/05/21
    */
    FUNCTION get_diagnosis_interv_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar;

    /**
    * Returns EHR diagnoses and interventions for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR diagnoses and interventions for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   THIAGO BRITO
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_diagnosis_interventions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_male   patient.gender%TYPE;
    g_female patient.gender%TYPE;
    g_both   patient.gender%TYPE;

    g_action    icnp_composition.flg_type%TYPE;
    g_diagnosis icnp_composition.flg_type%TYPE;
    g_yes       VARCHAR2(1);
    g_no        VARCHAR2(1);
    g_icon      sys_domain.img_name%TYPE;
    g_date      VARCHAR2(1);
    g_no_color  VARCHAR2(1);

    /*
    * diagnosis / intervention status
    */
    g_interrupted icnp_epis_intervention.flg_status%TYPE;
    g_terminated  icnp_epis_intervention.flg_status%TYPE;
    g_active      icnp_epis_diagnosis.flg_status%TYPE;
    g_finished    icnp_epis_diagnosis.flg_status%TYPE;
    g_revaluated  icnp_epis_diagnosis.flg_status%TYPE;
    g_canceled    icnp_epis_diagnosis.flg_status%TYPE;
    g_solved      icnp_epis_diagnosis.flg_status%TYPE;

    g_flg_time_epis icnp_epis_intervention.flg_time%TYPE;
    g_flg_time_next icnp_epis_intervention.flg_time%TYPE;
    g_flg_time_betw icnp_epis_intervention.flg_time%TYPE;

    g_interv_plan_admt  icnp_interv_plan.flg_status%TYPE;
    g_interv_plan_nadmt icnp_interv_plan.flg_status%TYPE;
    g_interv_plan_req   icnp_interv_plan.flg_status%TYPE;
    g_interv_plan_pend  icnp_interv_plan.flg_status%TYPE;
    g_interv_plan_canc  icnp_interv_plan.flg_status%TYPE;
    g_interv_plan_mod   icnp_interv_plan.flg_status%TYPE;

    g_interv_req  interv_prescription.flg_status%TYPE;
    g_interv_exec interv_prescription.flg_status%TYPE;
    g_interv_canc interv_prescription.flg_status%TYPE;
    g_interv_pend interv_prescription.flg_status%TYPE;
    g_interv_fin  interv_prescription.flg_status%TYPE;
    g_interv_part interv_prescription.flg_status%TYPE;

    g_take_sos  icnp_epis_intervention.flg_type%TYPE;
    g_take_nor  icnp_epis_intervention.flg_type%TYPE;
    g_take_uni  icnp_epis_intervention.flg_type%TYPE;
    g_take_cont icnp_epis_intervention.flg_type%TYPE;
    g_take_eter icnp_epis_intervention.flg_type%TYPE;

    g_doc_area_phy_exam   CONSTANT doc_area.id_doc_area%TYPE := 28; --physical exam
    g_epis_obs_flg_type_a CONSTANT epis_observation.flg_type%TYPE := 'A';
    g_epis_obs_flg_type_e CONSTANT epis_observation.flg_type%TYPE := 'E';

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';
    /* DIAGNOSIS CODE_DOMAIN */
    g_icnp_epis_diagnosis VARCHAR(200);
    /* INTERVENTION CODE_DOMAIN */
    g_icnp_epis_interv VARCHAR(200);
    /* REASSESSED FLAG */
    g_flg_reassessed CHAR;

    g_available CONSTANT VARCHAR2(1) := 'Y';

    g_flg_type_nursing_notes VARCHAR2(1);

END pk_ehr_nursing;
/
