/*-- Last Change Revision: $Rev: 2028676 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ehr_visits IS

    /**
    * Returns EHR individual encounter plans for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with the EHR individual encounter plans for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_individual_encounter_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR history of past illnesses for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR history of past illnesses for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_history_past_illnesses
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR reviews of systems for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR reviews of systems for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_reviews_of_systems
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR physical exams for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR physical exams for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_physical_exams
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns individual encounter plans by EPISODE identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  The plan description array for the EPISODE identifier.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_indiv_encnt_plans_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_clob;

    /**
    * Returns EHR planned visits for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR planned visits for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_planned_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR other events for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR other events for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_other_events
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns EHR diagnosis for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR diagnoses for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns disposition instruction by EPISODE identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  The disposition instruction array for the EPISODE identifier.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/18
    */
    FUNCTION get_disposition_instr_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar;

    /**
    * Returns EHR disposition instructions for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR disposition instructions for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_disposition_instructions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns reasons for visits for the given PATIENT identifier.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR reasons for visits for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Rui Batista
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_reasons_for_visits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns reason for visit for a specific episode 
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  a table of varchar with the reasons for visits values
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_reason_for_visit_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar;

    /**
    * Returns the last complaint of the episode
    *
    * @param i_lang         Language identifier.
    * @param i_episode      EPISODE identifier.
    * @param i_epis_type    Episode type
    * @param i_prof         The professional record.
    *
    * @return  a table of varchar with last complaint
    *
    * @author   Rui Batista
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_last_complaint
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_anamnesis.id_episode%TYPE,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        i_prof      IN profissional
    ) RETURN table_varchar;

    /**
    * Returns all advanced directives grouped by episode for a patient
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_patient   PATIENT identifier.
    *
    * @param o_cursor       The cursor with EHR reasons for visits for the given PATIENT identifier.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Pedro Teixeira
    * @version  2.4.3
    * @since    2008/05/26
    */
    FUNCTION get_adv_directives_for_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns advanced directives for a certain episode
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    *
    * @return  a table of varchar with the advanced directives for a apisode
    *
    * @author   Pedro Teixeira
    * @version  2.4.3
    * @since    2008/05/26
    */
    FUNCTION get_adv_directives_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE --,
        --o_table        OUT table_varchar
    ) RETURN table_varchar;

    /**
    * Returns the deepnav path from the first level to the given sbp level
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_sys_button_prop   Target id_sys_button_prop
    * @param o_deepnavs             The deepnav list
    * @param o_error                Error object
    *
    * @return  True if success, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/09/29
    */
    FUNCTION get_deepnav_path_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_deepnavs           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the creation date of the parent record
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_epis_recommend    Epis recommend ID
    *
    * @return  True if success, false otherwise
    *
    * @author   Sofia Mendes
    * @version  2.6.3
    * @since    16-Dec-2013
    */
    FUNCTION get_epis_recommend_parent_dt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_recommend IN epis_recomend.id_epis_recomend%TYPE
    ) RETURN epis_recomend.dt_epis_recomend_tstz%TYPE;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    /*Tipos de episódio*/
    g_epis_type_outp epis_type.id_epis_type%TYPE := 1;
    g_epis_type_edis epis_type.id_epis_type%TYPE := 2;
    g_epis_type_oris epis_type.id_epis_type%TYPE := 4;
    g_epis_type_inp  epis_type.id_epis_type%TYPE := 5;
    g_epis_type_care epis_type.id_epis_type%TYPE := 8;
    g_epis_type_pp   epis_type.id_epis_type%TYPE := 11;

    /* Document Area*/
    g_doc_area_adv_directives1 CONSTANT doc_area.id_doc_area%TYPE := 38;
    g_doc_area_adv_directives2 CONSTANT doc_area.id_doc_area%TYPE := 6092;
    g_doc_area_adv_directives3 CONSTANT doc_area.id_doc_area%TYPE := 6093;
    --
    g_vs_read_active VARCHAR2(1) := 'A';
    g_vs_read_cancel VARCHAR2(1) := 'C';
    --
    g_anam_flg_type_c epis_anamnesis.flg_type%TYPE := 'C';
    g_cancel          VARCHAR2(1) := 'C';
    g_excluded        VARCHAR2(1) := 'R';

    g_flg_ehr VARCHAR(1) := pk_ehr_access.g_flg_ehr_ehr;

    g_dictation_area_plan dictation_report.id_work_type%TYPE := 10;
    g_flg_sep CONSTANT VARCHAR2(3 CHAR) := ' - ';
    g_sd_dr sys_domain.code_domain%TYPE := 'DICTATION_REPORT.REPORT_STATUS';
END pk_ehr_visits;
/
