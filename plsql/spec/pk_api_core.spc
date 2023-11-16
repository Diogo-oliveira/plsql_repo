/*-- Last Change Revision: $Rev: 1859740 $*/
/*-- Last Change by: $Author: vitor.sa $*/
/*-- Date of last change: $Date: 2018-08-22 14:34:08 +0100 (qua, 22 ago 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_core IS

    /********************************************************************************************
     *  Clears data related to monitorization for a patient/episode
     *
     * @param i_lang                 ID language
     * @param i_market               Market ID
     * @param i_array_institution    Institutions IDs
     * @param i_id_timezone_region   New timezone
     * 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Sergio Dias
     * @since                        2-2-2011
    ********************************************************************************************/
    FUNCTION update_timezone
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN market.id_market%TYPE,
        i_array_institution  IN table_number,
        i_id_timezone_region IN timezone_region.id_timezone_region%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *  Clears monitorization data for a patient/episode
     *
     * @param i_lang                 ID language
     * @param i_table_id_episodes    Episodes IDs
     * @param i_table_id_patients    Patients IDs
     * 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Sergio Dias
     * @since                        2-2-2011
    ********************************************************************************************/
    FUNCTION clear_monitorization_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_episodes IN table_number,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *  Clears vital signs data for a patient/episode
     *
     * @param i_lang                 ID language
     * @param i_table_id_episodes    Episodes IDs
     * @param i_table_id_patients    Patients IDs
     * 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Sergio Dias
     * @since                        2-2-2011
    ********************************************************************************************/
    FUNCTION clear_vital_sign_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_episodes IN table_number,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Past History Surgical procedures
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_id_context        Identifier of the Episode/Patient/Visit based on the i_flg_type_context
    * @param i_flg_type_context  Flag to filter by Episode (E), by Visit (V) or by Patient (P)
    * @param o_doc_area          Data cursor
    * @param o_error             Error Message
    *
    * @return                    TRUE/FALSE
    *     
    * @author                    António Neto
    * @version                   2.6.1
    * @since                     2011-05-04
    *
    *********************************************************************************************/
    FUNCTION get_past_hist_surgical
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_context       IN NUMBER,
        i_flg_type_context IN VARCHAR2,
        o_doc_area         OUT NOCOPY pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_consult_request
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN opinion.id_clinical_service%TYPE,
        i_reason_ft    IN opinion.desc_problem%TYPE,
        i_reason_mc    IN table_number,
        i_prof_id      IN opinion.id_prof_questioned%TYPE,
        i_notes        IN opinion.notes%TYPE,
        i_dt_problem   IN VARCHAR2 DEFAULT NULL,
        o_opinion      OUT opinion.id_opinion%TYPE,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION intf_set_follow_up_state
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason    IN opinion_prof.id_cancel_reason%TYPE,
        i_dt_opinion       IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_mng_followup          IN management_follow_up.id_management_follow_up%TYPE,
        i_episode               IN management_follow_up.id_episode%TYPE,
        i_notes                 IN management_follow_up.notes%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE,
        i_dt_register           IN VARCHAR2 DEFAULT NULL,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_create_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_prof             IN profissional,
        i_prof_questioned  IN opinion.id_prof_questioned%TYPE DEFAULT NULL,
        i_speciality       IN opinion.id_speciality%TYPE DEFAULT NULL,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE DEFAULT NULL,
        i_desc             IN opinion.desc_problem%TYPE DEFAULT NULL,
        i_prof_cat_type    IN category.flg_type%TYPE DEFAULT NULL,
        i_flg_type         IN opinion.flg_type%TYPE DEFAULT NULL,
        i_dt_creation      IN VARCHAR2 DEFAULT NULL,
        o_id_opinion       OUT opinion.id_opinion%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_read_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        i_dt_read    IN VARCHAR2 DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_reply_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_opinion       IN opinion.id_opinion%TYPE,
        i_desc             IN opinion.desc_problem%TYPE DEFAULT NULL,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE,
        i_dt_reply         IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_cancel_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        i_dt_cancel  IN VARCHAR2,
        i_notes      IN opinion.notes_cancel%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_opinion            IN opinion.id_opinion%TYPE,
        i_notes                 IN management_follow_up.notes%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE,
        i_dt_register           IN VARCHAR2 DEFAULT NULL,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    g_error        VARCHAR2(4000);
    g_package_name VARCHAR2(32);
    g_found        BOOLEAN;
    g_exception EXCEPTION;
    g_package_owner VARCHAR2(50);

END pk_api_core;
/
