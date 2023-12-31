/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_list IS

    SUBTYPE obj_name IS VARCHAR2(30);
    SUBTYPE debug_msg IS VARCHAR2(4000);

    TYPE rec_origin IS RECORD(
        id_origin NUMBER(24),
        rank      NUMBER(24),
        ordena    pk_translation.t_desc_translation,
        origin    pk_translation.t_desc_translation);

    TYPE cursor_origin IS REF CURSOR RETURN rec_origin;

    TYPE table_origin IS TABLE OF rec_origin;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_origin);

    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_speciality    IN professional.id_speciality%TYPE,
        i_category      IN prof_cat.id_category%TYPE,
        i_dep_clin_serv IN prof_dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter lista dos profissionais da institui��o
    *
    * @param i_lang                   L�ngua registada como prefer�ncia do profissional
    * @param i_prof                   professional, software and institution ids
    * @param i_speciality             ID da especialidade
    * @param i_prof_cat               professional Category  
    * @param i_dep_clin_serv          ID do departamento + serv. cl�nico               
    * @param i_flg_option_none        Show option "None"? (Y) Yes (N) No
    * @param o_prof                   Lista dos professionais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         CRS
    * @since                          2005/03/09
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_speciality      IN professional.id_speciality%TYPE,
        i_category        IN prof_cat.id_category%TYPE,
        i_dep_clin_serv   IN prof_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_option_none IN VARCHAR2,
        o_prof            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter lista dos profissionais da institui��o (para medica��o)
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  o_error                       The error object
    *
    * @return boolean
    *
    * @author Pedro Teixeira
    * @since  23/05/2010
    *
    ********************************************************************************************/
    FUNCTION get_prof_med_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_category IN table_varchar,
        o_prof     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_list_array
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_speciality    IN table_number,
        i_category      IN table_number,
        i_dep_clin_serv IN table_number,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_list
    (
        i_lang     IN language.id_language%TYPE,
        o_schedule OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the room list inside a department or software (both optional)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_department             department ID (optional)
    * @param i_software               software ID (optional)
    * @param i_msg_other              'Other' code message (if applicable)
    * @param o_room                   Room list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos� Silva
    * @version                        1.0 
    * @since                          08-10-2010
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE DEFAULT NULL,
        i_software   IN software.id_software%TYPE DEFAULT NULL,
        i_msg_other  IN sys_message.code_message%TYPE DEFAULT NULL,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_department    IN room.id_department%TYPE,
        i_epis_type     IN NUMBER,
        i_dep_clin_serv IN room_dep_clin_serv.id_dep_clin_serv%TYPE,
        o_room          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_country_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_isencao_list
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_isencao OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_recm_description_list
    (
        i_lang  IN language.id_language%TYPE,
        o_recm  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_scholarship_list
    (
        i_lang        IN language.id_language%TYPE,
        o_scholarship OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_religion_list
    (
        i_lang     IN language.id_language%TYPE,
        o_religion OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_gender_list
    (
        i_lang   IN language.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_instit_list
    (
        i_lang   IN language.id_language%TYPE,
        i_type   IN institution.flg_type%TYPE,
        o_instit OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hplan_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_hplan OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_type_list
    (
        i_lang     IN language.id_language%TYPE,
        o_doc_type OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_occup_list
    (
        i_lang  IN language.id_language%TYPE,
        o_occup OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_marital_list
    (
        i_lang    IN language.id_language%TYPE,
        o_marital OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_job_stat_list
    (
        i_lang     IN language.id_language%TYPE,
        o_job_stat OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_cat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        o_spec  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_origin_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_origin OUT cursor_origin,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ext_cause_list
    (
        i_lang      IN language.id_language%TYPE,
        o_ext_cause OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type_list
    (
        i_lang      IN language.id_language%TYPE,
        o_epis_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type_list_with_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_epis_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_list
    (
        i_lang  IN language.id_language%TYPE,
        o_vacc  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_take_type_list
    (
        i_lang  IN language.id_language%TYPE,
        o_vacc  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_active_cancel_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_active_inactive_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_yes_no_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dcs_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_dep_clin_serv IN diagnosis_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_prof          IN profissional,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_freq_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_diag
    (
        i_lang      IN language.id_language%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cat_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_cat_diag_death
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_section   IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diag_type
    (
        i_lang      IN language.id_language%TYPE,
        o_diag_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_probl_type
    (
        i_lang      IN language.id_language%TYPE,
        o_pat_probl OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_probl_age
    (
        i_lang      IN language.id_language%TYPE,
        o_pat_probl OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_primary_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_secondary_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_allergy IN allergy.id_allergy%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_allergy_type
    (
        i_lang    IN language.id_language%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_allergy_appr
    (
        i_lang    IN language.id_language%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cons_req_prof_accept_deny
    (
        i_lang  IN language.id_language%TYPE,
        o_read  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_discharge_reason_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cat_type        IN category.flg_type%TYPE,
        i_flg_type        IN VARCHAR2,
        i_id_episode      IN episode.id_episode%TYPE,
        o_disch_reas_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_discharge_dest_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_disch_reason IN discharge_reason.id_discharge_reason%TYPE,
        i_prof            IN profissional,
        o_disch_dest_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_search_list
    (
        i_lang               IN language.id_language%TYPE,
        i_id_sys_button      IN search_screen.id_sys_button%TYPE,
        i_prof               IN profissional,
        o_list               OUT pk_types.cursor_type,
        o_list_cs            OUT pk_types.cursor_type,
        o_list_fs            OUT pk_types.cursor_type,
        o_list_payment_state OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_habit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_service_list
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_button IN search_screen.id_sys_button%TYPE,
        i_prof          IN profissional,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_time
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_time  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION monit_dates_manage
    (
        i_lang              IN language.id_language%TYPE,
        i_flg_time          IN analysis_req.flg_time%TYPE,
        i_flg_tp            IN VARCHAR2,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE DEFAULT NULL,
        o_dt_begin          OUT VARCHAR2,
        o_flg_edit_dt_begin OUT VARCHAR2,
        o_interval          OUT VARCHAR2,
        o_interval_send     OUT VARCHAR2,
        o_flg_edit_interval OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_dt_end_send       OUT VARCHAR2,
        o_dt_begin_send     OUT VARCHAR2,
        o_flg_edit_dt_end   OUT VARCHAR2,
        o_flg_min_date      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_param
    (
        i_lang        IN language.id_language%TYPE,
        i_flg_time    IN analysis_req.flg_time%TYPE,
        i_flg_tp      IN VARCHAR2,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        o_param       OUT pk_types.cursor_type,
        o_sysdate_str OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_presc_param
    (
        i_lang            IN language.id_language%TYPE,
        i_time            IN drug_prescription.flg_time%TYPE,
        i_type            IN drug_presc_det.flg_take_type%TYPE,
        i_take            IN drug_presc_det.takes%TYPE,
        i_interval        IN VARCHAR2,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_flg_type        IN VARCHAR2,
        i_prof            IN profissional,
        o_sysdate         OUT VARCHAR2,
        o_type            OUT drug_presc_det.flg_take_type%TYPE,
        o_take            OUT VARCHAR2,
        o_interval        OUT VARCHAR2,
        o_dt_begin        OUT VARCHAR2,
        o_dt_end          OUT VARCHAR2,
        o_hr_begin        OUT VARCHAR2,
        o_hr_end          OUT VARCHAR2,
        o_type_edit       OUT VARCHAR2,
        o_take_edit       OUT VARCHAR2,
        o_interval_edit   OUT VARCHAR2,
        o_dt_begin_edit   OUT VARCHAR2,
        o_dt_end_edit     OUT VARCHAR2,
        o_type_param      OUT drug_presc_det.flg_take_type%TYPE,
        o_take_param      OUT drug_presc_det.takes%TYPE,
        o_interval_param  OUT VARCHAR2,
        o_dt_begin_param  OUT VARCHAR2,
        o_dt_end_param    OUT VARCHAR2,
        o_realizacao_edit OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_blood_type
    (
        i_lang  IN language.id_language%TYPE,
        o_blood OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_blood_rhesus
    (
        i_lang  IN language.id_language%TYPE,
        o_blood OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_print_type
    (
        i_lang       IN language.id_language%TYPE,
        i_barcode    IN VARCHAR2,
        i_image      IN VARCHAR2,
        i_other_exam IN VARCHAR2,
        i_analysis   IN VARCHAR2,
        i_prof       IN profissional,
        o_print      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sample_text_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all professionals associated with a determined
     * category of an institution.
     *
     * @param  IN  Language ID
     * @param  IN  Category ID
     * @param  IN  Institution ID
     * @param  OUT Professional cursor
     * @param  OUT Error structure
     *
     * @return BOOLEAN
     *
     * @since   2009-Mar-12
     * @version 2.4.4
     * @author  Thiago Brito
    */
    FUNCTION get_professionals_by_category
    (
        i_lang          IN language.id_language%TYPE,
        i_category      IN category.id_category%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_geo_location
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_country    IN country.id_country%TYPE,
        o_geo_locations OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admin_plus_button_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_exam_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_schedule   IN schedule.id_schedule%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_exam_state IN VARCHAR2,
        i_flg_type   IN VARCHAR2,
        o_domains    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nationality_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter lista dos tipos de hist�ria de um paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               Qual o tipo de hist�ria: HMC - Hist�ria m�dica / cirurgica
                                                               HFS - Hist�ria familiar / social                  
    * @param o_pat_htype              Lista dos tipos de hist�ria do paciente 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Em�lia Taborda
    * @version                        1.0 
    * @since                          2007/01/12
    **********************************************************************************************/
    FUNCTION get_pat_history_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN pat_history_type.acronym%TYPE,
        o_pat_htype OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets district list.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_district the cursur with the districts info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Lu�s Gaspar
    * @version 1.0
    * @since   06-fev-2007
    */
    FUNCTION get_district_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_district OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets districts for a state.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof object with user data
    * @param   i_geo_state object with user data
    * @param   o_district the cursur with the districts info
    * @param   o_error an error message, set when return=false
    *
    * @return  true if sucess, false otherwise
    * @author  Jo�o Eiras
    * @version 1.0
    * @since   2008-05-15
    */
    FUNCTION get_state_district_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_geo_state IN geo_state.id_geo_state%TYPE,
        o_district  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns available states for the specified country
    *
    * @param   i_lang ui language
    * @param   i_prof object with user info
    * @param   i_country country id. If NULL, then institution's default country is used
    * @param   o_state cursor with states
    * @param   o_error erroe message
    *
    * @RETURN  true if sucess, false otherwise
    * @author  Jo�o Eiras
    * @version 1.0
    * @since   19-05-2008
    */
    FUNCTION get_state_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_country IN country.id_country%TYPE,
        o_state   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dept_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dept  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dept_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_dept       IN dept.id_dept%TYPE,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter lista dos profissionais da institui��o
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat               professional Category                 
    * @param o_professional           Lista dos professionais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Em�lia Taborda
    * @version                        1.0 
    * @since                          2007/10/12
    **********************************************************************************************/
    FUNCTION get_prof_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_cat     IN category.flg_type%TYPE,
        o_professional OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /************************************************************************************************************ 
    * Obter uma lista dos profissionais da institui��o, que pertencem a uma das categorias espec�ficadas. 
    * A lista cont�m como primeiro elemento a op��o 'Outros'.
    *
    * @param      i_lang             id language
    * @param      i_prof             id professional
    * @param      i_prof_cat         array with categories 
    * @param      o_prof_list        lista de todos o profissionais da institui��o
    * @param      o_error            error message   
    *
    * @return     TRUE if sucess, FALSE otherwise
    * @author     Orlando Antunes 
    * @version    0.1
    * @since      2008/01/08
    ***********************************************************************************************************/
    FUNCTION get_prof_inst_and_other_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_cat  IN table_varchar,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Gets the dep_clin_serv list selected by the given professional
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_dep                 department ID
    * @param o_dcs                 selected dep_clin_serv
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Jos� Silva
    * @version                     1.0
    * @since                       17-10-2007
    **********************************************************************************************/
    FUNCTION get_selected_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_dep     IN department.id_department%TYPE,
        o_dcs     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the list of specialties (for on-call physicians and physician's office)
    * or clinical services (for external institutions). Used to select a follow-up entity
    * in discharge instructions.
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_flg_entity          Type of entity: (OC) on-call physician
    *                                              (PH) physician's office
    *                                              (CL) clinic (external institutions)
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Jos� Brito
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_dischinstr_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_entity IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the list of professionals (on-call physicians or physician's office) or
    * external institutions (clinics) for a given speciality or clinical service
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_spec                Speciality or Clinical Service ID
    * @param i_flg_entity          Type of entity: (OC) on-call physician
    *                                              (PH) physician's office
    *                                              (CL) clinic (external institutions)
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Jos� Brito
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_dischinstr_names_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_spec       IN NUMBER,
        i_flg_entity IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- fun��es obten��o de listas de CIT (certificados de incapacidade tempor�ria)
    FUNCTION get_cit_disease_state
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_prof_health_subsys
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_benef_health_subsys
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_classification_ss
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_classification_fp
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_internment
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_incapacity_period
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_home_absence
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_cancel_reason
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_status
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_type
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_ill_affinity
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_appointment_type
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Given a institution returns a list of all institutions that belong to the same group
    *
    * @param i_institution         institution id
    * @param i_flg_relation        type of relation between institutions
    *    
    * @return                      list of all institutions that belong to the same group
    *
    * @author                      Alexandre Santos
    * @version                     1.0
    * @since                       21-05-2009
    **********************************************************************************************/
    FUNCTION tf_get_all_inst_group
    (
        i_institution  IN institution_group.id_institution%TYPE,
        i_flg_relation IN institution_group.flg_relation%TYPE
    ) RETURN table_number;

    /**
     * This function returns all professionals associated with a determined
     * category of an institution.
     *
     * @param  IN  Language ID
     * @param  IN  Category Flag
     * @param  IN  Institution ID
     * @param  OUT Professional cursor
     * @param  OUT Error structure
     *
     * @return BOOLEAN
     *
     * @since   11/09/2009
     * @version 2.5.0.7
     * @author  Pedro Carneiro
    */
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_category    IN category.flg_type%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns possible values for "Admitido na institui��o"
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @since                       01/03/2010
    **********************************************************************************************/
    FUNCTION get_dti_admission_state
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns possible values for transportation needs (Y / N)
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @since                       01/03/2010
    **********************************************************************************************/
    FUNCTION get_dti_granted_transport
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns possible refused reasons
    *
    * @param i_lang                language ID
    * @param o_refused_reasons     List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @since                       01/03/2010
    **********************************************************************************************/
    FUNCTION get_dti_refused_reasons
    (
        i_lang            IN language.id_language%TYPE,
        o_refused_reasons OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns 'Y' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  Y
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_available_yes RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns 'N' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  N
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_available_no RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns 'A' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  A
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_state_active RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns 'I' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  I
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_state_inactive RETURN VARCHAR2;
    /********************************************************************************************
    * replaces desc_criteria from table criteria variable fields and returns it's result
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_desc_criteria       function that returns label
    *    
    * @return                      varchar
    *
    * @author                      Paulo Teixeira
    * @version                     2.6.1
    * @since                       2011-05-05
    **********************************************************************************************/
    FUNCTION replace_desc_criteria
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_desc_criteria IN criteria.desc_criteria%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * Returns available languages list
    * 
    * @param         i_lang                user language
    *
    * @param         o_language_list       languages list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Rui Spratley
    * @version       2.6.0.4
    * @date          2010/10/29
    ********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang          IN language.id_language%TYPE,
        o_language_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_language_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    /*********************************************************************************************
    * Returns available specialties list
    * 
    * @param         i_lang                user language
    *
    * @param         o_specialty_list      specialty list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Rui Spratley
    * @version       2.6.0.4
    * @date          2010/10/29
    ********************************************************************************************/
    FUNCTION get_specialty_list
    (
        i_lang           IN language.id_language%TYPE,
        o_specialty_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_specialty_list(i_lang IN language.id_language%TYPE) RETURN t_tbl_core_domain;

    /**********************************************************************************************
    * Returns is discharge reason is default ou not 
    * 
    * @return  A or I
    * 
    * @author        Elisabete Bugalho 
    * @version       2.6.3.4
    * @date          2013/04/17
    **********************************************************************************************/
    FUNCTION is_disch_reason_def
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_discharge_reason IN discharge_reason.id_discharge_reason%TYPE
    ) RETURN VARCHAR2;
    /*********************************************************************************************
    * Returns available categories list
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    *
    * @return        pipelined results
    *
    * @author        RMGM
    * @version       2.6.4.0
    * @date          2014/05/12
    ********************************************************************************************/
    FUNCTION get_pipelined_cat_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_values_domain_mkt
        PIPELINED;

    /*********************************************************************************************
    * Returns available nationalities
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    * @param         o_nationality         nationality list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Anna Kurowska
    * @version       2.8.0.0
    * @date          2019/07/12
    ********************************************************************************************/
    FUNCTION get_nationality
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_nationality OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Returns available countries
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    * @param         o_country             country list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Anna Kurowska
    * @version       2.8.0.0
    * @date          2019/07/12
    ********************************************************************************************/
    FUNCTION get_country
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Returns types of closure
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    * @param         o_list                types of closure list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        CRISTINA.OLIVEIRA
    * @version       2.8.0.0
    * @date          2019/07/12
    ********************************************************************************************/
    FUNCTION get_disch_type_closure_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --    
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_package_name  obj_name;
    g_package_owner obj_name;
    --
    g_selected CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';
    --    
    g_cat_type_doctor CONSTANT category.flg_type%TYPE := 'D';
    g_cat_type_nurse  CONSTANT category.flg_type%TYPE := 'N';
    g_cat_type_tech   CONSTANT category.flg_type%TYPE := 'T';
    g_cat_type_physio CONSTANT category.flg_type%TYPE := 'F';
    --
    g_diag_freq CONSTANT diagnosis_dep_clin_serv.flg_type%TYPE := 'M';
    g_diag_req  CONSTANT diagnosis_dep_clin_serv.flg_type%TYPE := 'P';
    --
    g_sys_config_default_country CONSTANT sys_config.id_sys_config%TYPE := 'COUNTRY_LOCATION';
    --
    g_active_cancel              CONSTANT sys_domain.code_domain%TYPE := 'ACTIVE_CANCEL';
    g_active_inactive            CONSTANT sys_domain.code_domain%TYPE := 'ACTIVE_INACTIVE';
    g_yes_no                     CONSTANT sys_domain.code_domain%TYPE := 'YES_NO';
    g_cons_req_prof_accept_deny  CONSTANT sys_domain.code_domain%TYPE := 'CONSULT_REQ_PROF.FLG_ACCEPT_DENY';
    g_pat_probl_type             CONSTANT sys_domain.code_domain%TYPE := 'PAT_PROBLEM.FLG_TYPE';
    g_pat_probl_age              CONSTANT sys_domain.code_domain%TYPE := 'PAT_PROBLEM.FLG_AGE';
    g_allergy_type               CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY.FLG_TYPE';
    g_allergy_appr               CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY.FLG_APROVED';
    g_domain_gender              CONSTANT sys_domain.code_domain%TYPE := 'PATIENT.GENDER';
    g_domain_schedule            CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_TYPE';
    g_domain_marital             CONSTANT sys_domain.code_domain%TYPE := 'PAT_SOC_ATTRIBUTES.MARITAL_STATUS';
    g_domain_job_stat            CONSTANT sys_domain.code_domain%TYPE := 'PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS';
    g_domain_vaccine             CONSTANT sys_domain.code_domain%TYPE := 'PAT_VACCINE.FLG_TAKE_TYPE';
    g_domain_print               CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE';
    g_domain_print_barcode       CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_BARCODE';
    g_domain_print_image         CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_IMAGE';
    g_domain_print_analysis      CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_ANALYSIS';
    g_domain_print_other         CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_OTHER_EXAM';
    g_domain_print_social        CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_SOCIAL';
    g_domain_oris                CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_ORIS';
    g_domain_edis                CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_EDIS';
    g_domain_inp                 CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_INP';
    g_domain_p1                  CONSTANT sys_domain.code_domain%TYPE := 'PRINT.FLG_TYPE_P1';
    g_domain_diagnosis           CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_TYPE';
    g_domain_flg_time            CONSTANT sys_domain.code_domain%TYPE := 'EXAM_REQ.FLG_TIME';
    g_domain_blood               CONSTANT sys_domain.code_domain%TYPE := 'PAT_BLOOD_GROUP.FLG_BLOOD_GROUP';
    g_domain_rhesus              CONSTANT sys_domain.code_domain%TYPE := 'PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS';
    g_domain_admin_creates       CONSTANT sys_domain.code_domain%TYPE := 'ADMIN_PLUS_BUTTON';
    g_domain_first_subs          CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_TYPE';
    g_domain_schedule_outp_state CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_STATE_ACTION';
    g_flg_payment_domain         CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE.FLG_PAYMENT';
    g_domain_schedule_exam       CONSTANT sys_domain.code_domain%TYPE := 'ADMIN_SCH_EXAM';
    g_domain_dti_refused_reason  CONSTANT sys_domain.code_domain%TYPE := 'DISCH_TRANSF_INST.FLG_REFUSED_REASON';

    -- defici��es para listas de CIT - tabela PAT_CIT
    g_cit_disease_state       CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_PAT_DISEASE_STATE';
    g_cit_prof_health_subsys  CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_PROF_HEALTH_SUBSYS';
    g_cit_benef_health_subsys CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_BENEF_HEALTH_SUBSYS';
    g_cit_classification_ss   CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_CIT_CLASSIFICATION_SS';
    g_cit_classification_fp   CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_CIT_CLASSIFICATION_FP';
    g_cit_internment          CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_INTERNMENT';
    g_cit_incapacity_period   CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_INCAPACITY_PERIOD';
    g_cit_home_absence        CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_HOME_ABSENCE';
    g_cit_cancel_reason       CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_CANCEL_REASON';
    g_cit_status              CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_STATUS';
    g_cit_type                CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_TYPE';
    g_cit_ill_affinity        CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_ILL_AFFINITY';

    g_dcs_available_y CONSTANT dep_clin_serv.flg_available%TYPE := 'Y';
END;
/
