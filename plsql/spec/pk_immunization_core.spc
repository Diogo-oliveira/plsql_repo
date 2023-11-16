/*-- Last Change Revision: $Rev: 1968195 $*/
/*-- Last Change by: $Author: pedro.teixeira $*/
/*-- Date of last change: $Date: 2020-10-22 14:55:16 +0100 (qui, 22 out 2020) $*/
CREATE OR REPLACE PACKAGE pk_immunization_core IS

    SUBTYPE obj_name IS VARCHAR2(30 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);
    g_error_message_20001 CONSTANT VARCHAR2(100) := 'INVALID_INPUT_PARAMETERS';
    g_error_message_20002 CONSTANT VARCHAR2(100) := 'CANNOT_INSERT_DATA_IN_TABLE';
    g_error_message_20003 CONSTANT VARCHAR2(100) := 'CANNOT_UPDATE_DATA_IN_TABLE';

    g_package_name VARCHAR2(32);

    g_package_owner CONSTANT obj_name := 'ALERT';
    g_package_names CONSTANT obj_name := pk_alertlog.who_am_i();

    --Variáveis globais do package
    --
    g_found BOOLEAN;
    g_error VARCHAR2(2000);

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;

    FUNCTION count_vacc_take
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_lasttake IN drug_presc_plan.dt_take_tstz%TYPE,
        i_prof     IN profissional
    ) RETURN NUMBER;

    FUNCTION get_year_from_timestamp(i_dt TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR;
    FUNCTION get_month_year_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR;
    FUNCTION get_has_adm_canceled(i_drug IN drug_prescription.id_drug_prescription%TYPE) RETURN VARCHAR2;
    FUNCTION get_has_rep_canceled(i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE) RETURN VARCHAR2;

    FUNCTION get_vacc_ndose
    (
        i_lang    IN language.id_language%TYPE,
        i_vaccine IN vacc.id_vacc%TYPE
    ) RETURN NUMBER;

    FUNCTION get_age_recommend
    (
        i_lang IN language.id_language%TYPE,
        i_val  IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_gap_between_doses
    (
        i_lang   IN language.id_language%TYPE,
        i_n_dose IN vacc_dose.n_dose%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN NUMBER;

    FUNCTION get_dose_age
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --i_datetake IN DATE --drug_presc_plan.dt_take%TYPE
        i_datetake_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /************************************************************************************************************
    * This function returns the ordinality of a dose
    *
    * @param      n_dose           dose
    * @param      i_lang           language
    *
    * @return     string
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/11/04
    ***********************************************************************************************************/

    FUNCTION vacc_ordinal
    (
        n_dose IN NUMBER,
        i_lang IN language.id_language%TYPE
    ) RETURN VARCHAR2;

    /*
    * This function checks if a specified value is valid (>= 0) or not (< 0).
    * When the value is invalid the function returns 0.
    *
    * @param      i_val               number
    *
    * @return     the value of i_val if i_val is great than zero, and zero otherwise
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/09/18
    */

    FUNCTION validate_take_date(i_val IN NUMBER) RETURN NUMBER;

    FUNCTION has_discontinue_vacc
    (
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_last_take_icon(i_dt IN drug_presc_plan.dt_plan_tstz%TYPE) RETURN VARCHAR2;

    FUNCTION get_last_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION has_discontinue_dose
    (
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_pnv_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_review_notes       IN VARCHAR2,
        o_review             OUT pk_types.cursor_type,
        o_vaccine_group_name OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pnv_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_flg_group_status OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_pnv_flg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_vaccinated OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns a string with the day and month(abbreviation) separated by a space,
    *  for a specified TIMESTAMP (e.g. 12 Nov)
    *
    * @param      i_lang           language
    * @param      i_dt             date as a timestamp
    * @param      i_prof           professional
    *
    * @return     day and month(abbreviation) as a string
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/05/14
    ***********************************************************************************************************/
    FUNCTION get_day_month_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    FUNCTION get_summary_value_icon_color
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION get_summary_time_min
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_summary_time_hour
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_summary_time_day
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_summary_value_bg_color
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION get_summary_value_icon
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2,
        i_result  IN drug_presc_result.id_evaluation%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_summary_value_label
    (
        i_lang      IN language.id_language%TYPE,
        i_minutes   IN VARCHAR2,
        i_hours     IN VARCHAR2,
        i_days      IN VARCHAR2,
        i_state     IN VARCHAR2,
        i_dt_cancel IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_value     IN drug_presc_result.value%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_tuberculin_test_timestamp
    (
        i_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_take   TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_result TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_tuberculin_test_state
    (
        i_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_take   TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_result TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_cancel TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;
    FUNCTION get_tuberculin_test_state(i_test_id IN drug_prescription.id_drug_prescription%TYPE) RETURN VARCHAR2;

    FUNCTION has_active_option
    (
        i_status IN VARCHAR2,
        i_option IN VARCHAR2
    ) RETURN VARCHAR2;

    /************************************************************************************************************
    * This function checks whether the taking was made in the same episode
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/

    FUNCTION has_recorded_this_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_take_id IN NUMBER,
        i_flg     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION has_recorded_this_episode_yn
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_take_id IN NUMBER,
        i_flg     IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of documents source
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of documents source
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_source_description
    (
        i_lang           IN language.id_language%TYPE,
        i_vacc_source_id IN vacc_funding_source.id_vacc_funding_source%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of origin documents
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of origin documents
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_cat_description
    (
        i_lang        IN language.id_language%TYPE,
        i_vacc_cat_id IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a doc description of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_doc_id      doc identifier
    *
    * @return     Description doc description of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_doc_description
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_doc_id IN vacc_doc_vis.id_vacc_doc_vis%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_description_adm_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN drug_prescription.id_drug_prescription%TYPE,
        i_vacc IN vacc.id_vacc%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * Return a description of origin
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of origin
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_origin_description
    (
        i_lang      IN language.id_language%TYPE,
        i_origin_id IN vacc_origin.id_vacc_origin%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a adverse reaction description of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_adv_reactions_id   adverse reaction identifier
    *
    * @return     Description of adverse reaction description of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_adv_reactions_description
    (
        i_lang             IN language.id_language%TYPE,
        i_adv_reactions_id IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of manufactured
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_manufactured_id   manufactured identifier
    *
    * @return     Description of manufactured
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_manufacturer_description
    (
        i_lang            IN language.id_language%TYPE,
        i_manufactured_id IN vacc_manufacturer.id_vacc_manufacturer%TYPE
    ) RETURN VARCHAR2;

    /************************************************************************************************************
    * This function returns the details for all takes for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_vacc_id            vaccine's id
    *
    * @param      o_adm                detail of administration (Date of administration)
    * @param      o_desc               cursor with the description details
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/
    FUNCTION get_vacc_details
    
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        o_adm     OUT pk_types.cursor_type,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_desc_disc_dose_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
    ) RETURN CLOB;

    FUNCTION get_pnv_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Gets the next take date of a vaccine
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient identifier
    * @param      i_vacc               vacc identifier
    * @param      min_val              min val for vaccine
    * @param      max val              max val for vaccine
    *
    * @return     next take date
    * @author     Elisabete Bugalho
    * @version    2.5.1.11
    * @since      12-02-2012
    ***********************************************************************************************************/
    FUNCTION get_vacc_next_take
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE,
        min_val   IN time.val_min%TYPE,
        max_val   IN time.val_max%TYPE,
        i_type    IN VARCHAR2 DEFAULT 'E'
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /*
    * Returns the predicted take ( Only PNV)
    *
    * @param      i_lang               language
    * @param      i_vacc               vaccine
    * @param      i_id_pat             patient
    * @param      i_prof               professional
    *
    * @param      o_error              error message
    *
    * @return     number of takes
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/24
    */

    FUNCTION get_vacc_predicted_take
    (
        i_lang                IN language.id_language%TYPE,
        i_vacc                IN vacc.id_vacc%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        o_info_predicted_take OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN pat_vacc.flg_status%TYPE;

    /************************************************************************************************************
    * Returns the number of the dose considering the canceled dose administration .
    *
    * @param      i_lang               language
    * @param      i_id_pat             patient
    * @param      i_vacc               vaccine's ID
    * @param      i_lasttake           dose's administration date
    *
    * @return
    * @author     Elisabete Bugalho    
    * @version    2.5.2
    * @since      2012/03/14
    ***********************************************************************************************************/
    FUNCTION count_vacc_dose
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_lasttake IN drug_presc_plan.dt_take_tstz%TYPE,
        i_prof     IN profissional
    ) RETURN NUMBER;

    /************************************************************************************************************
    * This function 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/

    FUNCTION get_description_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        i_labels  IN table_varchar2,
        i_res     IN table_varchar2,
        i_dt      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_updated IN VARCHAR2
    ) RETURN CLOB;

    /************************************************************************************************************
    * Returns the date of the last administration for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_id_pat             patient's ID
    * @param      i_vacc               vaccine's ID
    *
    * @return     date for the last vaccine administration
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/04/28
    ***********************************************************************************************************/
    FUNCTION get_next_take_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**
     * This function returned a viewer details    
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_vacc          IN   Vacc ID
     * 
     * @param  o_detail_info_out  OUT Cursor of viewer details
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_viewer_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vacc        IN vacc.id_vacc%TYPE,
        o_detail_info OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get patient vaccine status.
    *
    * @param i_patient      logged professional structure
    * @param i_vacc         presc type flag
    *
    * @return               patient vaccine status
    *
    * @author               Elisabete Bugalho
    * @version               2.5.3
    * @since                2012/05/31
    */
    FUNCTION get_vacc_status
    (
        i_patient IN patient.id_patient%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN pat_vacc.flg_status%TYPE;

    FUNCTION get_vacc_summary_all
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --OUT
        --        o_vacc_header_title    OUT VARCHAR2,
        --        o_vacc_header_subtitle OUT VARCHAR2,
        --Other Vaccines (outside PNV)
        --  o_oth_vaccine_group_name OUT VARCHAR2,
        
        o_oth_vaccine_time OUT pk_types.cursor_type,
        o_oth_vaccine_par  OUT pk_types.cursor_type,
        o_oth_vaccine_val  OUT pk_types.cursor_type,
        --PNV Vaccines
        o_vaccine_group_name OUT pk_types.cursor_type,
        o_vaccine_time       OUT pk_types.cursor_type,
        o_vaccine_par        OUT pk_types.cursor_type,
        o_vaccine_val        OUT pk_types.cursor_type,
        
        --Tuberculin tests
        o_tuberculin_group_name OUT VARCHAR2,
        o_tuberculin_time       OUT pk_types.cursor_type,
        o_tuberculin_par        OUT pk_types.cursor_type,
        o_tuberculin_val        OUT pk_types.cursor_type,
        o_review                OUT pk_types.cursor_type,
        o_create                OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return name of vaccine with default value of route and dose
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  Return name of vaccine
    *
    * @author                   Jorge Silva
    * @since                    18/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_description
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN mi_med.id_drug%TYPE,
        i_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of information source of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_report_id   information source identifier
    *
    * @return     Description of information source
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_report_description
    (
        i_lang      IN language.id_language%TYPE,
        i_report_id IN vacc_report.id_vacc_report%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_description_report_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE
    ) RETURN CLOB;

    FUNCTION get_desc_adm_cancel_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN drug_prescription.id_drug_prescription%TYPE
    ) RETURN CLOB;

    FUNCTION get_desc_rep_cancel_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
    ) RETURN CLOB;

    FUNCTION get_desc_disc_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_vacc_hist IN pat_vacc_hist.id_pat_vacc_hist%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * Return a route description
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    * @param IN   i_id_route       toute identifier
    *
    * @return     Route description
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_route_description
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        i_id_route IN mi_med.route_id%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_add
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        i_orig       IN VARCHAR2,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_type_vacc  IN VARCHAR2,
        i_id_reg     IN NUMBER,
        i_flg_status IN VARCHAR2,
        o_val        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- ACTIONS BELOW    
    FUNCTION get_vacc_adm_warnings
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Return name of vaccine with last take 
        *
        * @param IN   i_lang            Language ID
        * @param IN   i_prof            Professional ID
        * @param IN   i_id_vacc         Vaccine id
        * @param IN   i_dose            Dose (-1 dose selected or null)
        *
        * @param OUT  Return name of vaccine with date of dose report 
        *
        * @author                   Jorge Silva
        * @since                    05/05/2014
    ********************************************************************************************/
    FUNCTION get_vacc_descontinue_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_dose    IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returned if a next date is enabled or not
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient ID
     * @param  i_tk_date       IN   Take Date
     * @param  i_vacc          IN   Vacc ID
     * @param  i_dt_adm_str    IN   Date Administration
     * 
     * @return  next date is available (Y/N)
     *
     * @version  2.6.4.0.2
     * @since    22-05-2014
     * @author   Jorge Silva
    */
    FUNCTION get_next_date_available
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_tk_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function return all values of administration screen create or edit   
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient Identifier
     * @param  i_vacc          IN   Vacc ID
     * @param  i_drug          IN   Prescription drug ID
     * 
     * @param  o_form_out      OUT Cursor of all values of administration screen   
     * @param  o_doc_show      OUT Y/N Show doc in this screen
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_form_administration
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN drug_prescription.id_drug_prescription%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function return all values of report screen create or edit
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient Identifier
     * @param  i_vacc          IN   Vacc ID
     * @param  i_drug          IN   Prescription drug ID
     * 
     * @param  o_form_out      OUT Cursor of all values of report screen   
     * @param  o_doc_show      OUT Y/N Show doc in this screen  
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_form_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_discontinue_dose
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_vacc            IN pat_vacc_adm.id_vacc%TYPE,
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE,
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returned all professional (doctor and nurse) in this institution    
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * 
     * @param  o_prof_list  OUT     Cursor of professional (order by)
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    11-04-2014
     * @author   Jorge Silva
    */

    FUNCTION get_order_by_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adverse_reaction_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_adv_reaction OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_unit_measure
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_unit_measure OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_med_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc         IN vacc.id_vacc%TYPE,
        i_orig         IN VARCHAR2,
        o_vacc_med_ext OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_application_spot_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_funding_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vacc_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_origin_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_origin OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_funding_source
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_source OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_choice_type
    (
        i_lang  IN language.id_language%TYPE,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_route_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_drug    IN mi_med.id_drug%TYPE,
        o_vacc_route OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_drug           IN mi_med.id_drug%TYPE,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_doc_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        o_vacc_doc OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_dose_default
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_drug   IN mi_med.id_drug%TYPE,
        o_vacc_dose OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_administration
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN drug_prescription.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat           IN patient.id_patient%TYPE,
        i_drug_presc    IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_begin      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN drug_presc_det.id_drug%TYPE,
        i_id_vacc       IN vacc.id_vacc%TYPE DEFAULT NULL,
        
        --adverse reaction
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        --Application_spot
        i_application_spot      IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_application_spot_desc IN drug_presc_plan.application_spot%TYPE,
        
        i_lot_number IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp     IN VARCHAR2,
        
        --Manufactured
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        
        --Administration route
        i_adm_route IN VARCHAR2,
        
        --Vaccine origin
        i_vacc_origin      IN vacc_origin.id_vacc_origin%TYPE,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery IN VARCHAR2,
        i_doc_cat         IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE,
        i_doc_source      IN vacc_funding_source.id_vacc_funding_source%TYPE,
        i_doc_source_desc IN drug_presc_plan.funding_source_desc%TYPE,
        
        --Ordered By
        i_order_by   IN professional.id_professional%TYPE,
        i_order_desc IN VARCHAR2,
        
        --Administer By
        i_administer_by   IN professional.id_professional%TYPE,
        i_administer_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        --Notes
        i_notes IN drug_presc_plan.notes%TYPE,
        
        o_drug_presc_plan OUT NUMBER,
        o_drug_presc_det  OUT NUMBER,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set_pat_administration_all
    *
    * @param i_lang                   Language ID
    * @param i_id_episode             Episode ID
    * @param i_prof                   Profissional ID
    * @param i_id_pat                 Patient ID
    * @param i_dt_begin               array data for take date
    * @param i_prof_cat_type          category type
    * @param i_id_drug                vaccination medication
    * @param i_vacc                   vaccination ID
    * @param o_drug_presc_plan
    * @param o_drug_presc_det        
    * @param o_flg_show
    * @param o_msg
    * @param o_msg_result
    * @param o_msg_title
    * @param o_type_admin          type of admin
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.1.0
    * @since                          04/10/2019
    **************************************************************************/
    FUNCTION set_pat_administration_all
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN drug_prescription.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat           IN patient.id_patient%TYPE,
        i_drug_presc    IN table_number,
        i_dt_begin      IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN table_varchar,
        
        i_vacc            IN table_number,
        o_drug_presc_plan OUT NOCOPY table_number,
        o_drug_presc_det  OUT NOCOPY table_number,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_resume_dose
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_vacc       IN pat_vacc_adm.id_vacc%TYPE,
        i_drug       IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_adm_take_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_drug    IN drug_prescription.id_drug_prescription%TYPE,
        o_desc    OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_advers_react
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN NUMBER,
        i_type_vacc IN VARCHAR2,
        o_id_value  OUT NUMBER,
        o_notes     OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_advers_react
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_reg     IN drug_prescription.id_drug_prescription%TYPE,
        i_value      IN vacc_advers_react.id_vacc_adver_reac%TYPE,
        i_notes      IN vacc_advers_react.notes_advers_react%TYPE,
        i_type_vacc  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_adm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_drug_prescription IN drug_prescription.id_drug_prescription%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_status     IN pat_vacc.flg_status%TYPE,
        i_id_reason  IN NUMBER,
        i_notes      IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_most_freq_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_type           IN VARCHAR2,
        i_button         IN VARCHAR2,
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_report
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_presc         IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str  IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN mi_med.id_drug%TYPE,
        i_vacc          IN pat_vacc_adm.id_vacc%TYPE,
        i_desc_vaccine  IN pat_vacc_adm_det.desc_vaccine%TYPE,
        
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str IN VARCHAR2,
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE,
        
        i_adm_route IN VARCHAR2,
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery     IN VARCHAR2,
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE,
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE,
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        i_notes IN pat_vacc_adm_det.notes%TYPE,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_report
    (
        i_lang               IN language.id_language%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_presc              IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str       IN VARCHAR2 DEFAULT '',
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_id_drug            IN mi_med.id_drug%TYPE,
        i_vacc               IN pat_vacc_adm.id_vacc%TYPE,
        i_desc_vaccine       IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE DEFAULT NULL,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE DEFAULT '',
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE DEFAULT NULL,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE DEFAULT '',
        i_dt_expiration_str IN VARCHAR2 DEFAULT '',
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2 DEFAULT '',
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE DEFAULT NULL,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE DEFAULT NULL,
        
        i_adm_route IN VARCHAR2 DEFAULT '',
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2 DEFAULT '',
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE DEFAULT NULL,
        i_doc_vis_desc IN VARCHAR2 DEFAULT '',
        
        i_dt_doc_delivery     IN VARCHAR2 DEFAULT '',
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE DEFAULT '',
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE DEFAULT '',
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2 DEFAULT '',
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2 DEFAULT '',
        
        i_notes IN pat_vacc_adm_det.notes%TYPE DEFAULT '',
        
        i_flg_status      IN pat_vacc_adm_det.flg_status%TYPE DEFAULT 'A',
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE DEFAULT '',
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE DEFAULT NULL,
        i_dt_suspended    IN pat_vacc_adm_det.dt_suspended%TYPE DEFAULT NULL,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_vacc_next_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_vacc           IN vacc.id_vacc%TYPE,
        i_dt_adm_str     IN VARCHAR2,
        o_info_next_date OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_next_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_reported
    (
        i_lang    IN sys_domain.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_type_dose
    (
        i_lang    IN language.id_language%TYPE,
        i_vaccine IN vacc.id_vacc%TYPE,
        time_var  IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_type_dose
    (
        i_vaccine IN vacc.id_vacc%TYPE,
        i_dose    IN vacc_dose.n_dose%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_rep_take_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_vacc      IN vacc.id_vacc%TYPE,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_desc         OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_next_icon
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_dt           IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max       IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max_age   IN patient.dt_birth%TYPE,
        i_dt_take      IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_next_take IN drug_presc_plan.dt_next_take%TYPE,
        i_dt_birth     IN patient.dt_birth%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_max_age
    (
        i_max_val  IN time.val_max%TYPE,
        i_dt_birth IN patient.dt_birth%TYPE
    ) RETURN DATE;

    FUNCTION get_vacc_display_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_dt           IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max       IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max_age   IN patient.dt_birth%TYPE,
        i_dt_take      IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_next_take IN drug_presc_plan.dt_next_take%TYPE,
        i_dt_birth     IN patient.dt_birth%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_last_bgcolor
    (
        i_dt           IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max       IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max_age   IN patient.dt_birth%TYPE,
        i_dt_take      IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_next_take IN drug_presc_plan.dt_next_take%TYPE,
        i_dt_birth     IN patient.dt_birth%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_icon_color
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_dt           IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max       IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max_age   IN patient.dt_birth%TYPE,
        i_dt_take      IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_next_take IN drug_presc_plan.dt_next_take%TYPE,
        i_dt_birth     IN patient.dt_birth%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_review
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_auto   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_vacc_presc_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacc_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_reg        IN vacc_update_admin.id_reg%TYPE,
        i_type       IN vacc_update_admin.flg_type%TYPE,
        i_dt_admin   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_vacc_update
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_vacc      IN vacc.id_vacc%TYPE,
        o_vacc_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_text_message
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dt           IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max       IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_max_age   IN patient.dt_birth%TYPE,
        i_dt_take      IN drug_presc_plan.dt_plan_tstz%TYPE,
        i_dt_next_take IN drug_presc_plan.dt_next_take%TYPE,
        i_dt_birth     IN patient.dt_birth%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_availability(i_dt_max_age IN patient.dt_birth%TYPE) RETURN VARCHAR2;

    FUNCTION set_tuberculin_test_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_drug         IN drug_presc_det.id_drug%TYPE, --mi_med.id_drug%TYPE,
        i_dosage       IN drug_presc_det.dosage_description%TYPE,
        i_unit_measure IN drug_presc_det.id_unit_measure%TYPE,
        i_admin_via    IN drug_presc_det.route_id%TYPE,
        --
        i_prof_write          IN professional.id_professional%TYPE,
        i_notes_justif        IN drug_presc_det.notes_justif%TYPE,
        i_notes               IN drug_presc_det.notes%TYPE,
        i_presc_date          IN VARCHAR2,
        i_requested_by        IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --OUT
        o_test_id    OUT drug_prescription.id_drug_prescription%TYPE,
        o_id_admin   OUT drug_presc_plan.id_drug_presc_plan%TYPE,
        o_type_admin OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cancel_info
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_cancel_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op IN VARCHAR,
        --Out
        o_main_title  OUT VARCHAR2,
        o_notes_title OUT VARCHAR2,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_test_warnings
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN drug_prescription.id_drug_prescription%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION format_tuberculin_test_date
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_type_date IN VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION format_dt_expiration_test_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR;

    FUNCTION get_value_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_key     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_prof_resp_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_tuberculin_test_presc_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_oth_vacc_value_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc_take_id IN NUMBER,
        i_key          IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_tuberculin_test_add
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        --OUT
        o_main_title OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_summary_state_label
    (
        i_lang  IN language.id_language%TYPE,
        i_state VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION get_tuberculin_tests_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        -- Adverses React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_info
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_cancel_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op    IN VARCHAR,
        i_notes_cancel IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tuberculin_test_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_test_id             IN NUMBER,
        i_dt_adm              IN VARCHAR2,
        i_lote_adm            IN VARCHAR2,
        i_dt_valid            IN VARCHAR2,
        i_app_place           IN VARCHAR2,
        i_prof_write          professional.id_professional%TYPE,
        i_notes               IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reading_unit_list
    (
        i_lang      IN language.id_language%TYPE,
        o_read_unit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_evaluation_values
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notes_advers_react_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_tuberculin_test_res
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_test_id       IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_read       IN VARCHAR2,
        i_value         IN drug_presc_result.value%TYPE,
        i_evaluation    IN drug_presc_result.evaluation%TYPE,
        i_evaluation_id IN drug_presc_result.id_evaluation%TYPE,
        i_reactions     IN drug_presc_result.notes_advers_react%TYPE,
        i_prof_write    IN professional.id_professional%TYPE,
        i_notes         IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_care_dash_vacc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vacc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION count_vacc_take_all
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE,
        i_prof   IN profissional
    ) RETURN NUMBER;

    FUNCTION get_label_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_id_admin          IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_type_admin        IN VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_value_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc_take_id IN NUMBER,
        i_key          IN VARCHAR2
    ) RETURN VARCHAR2;

    /******************************************************************************
       OBJECTIVO:   Retorna informação sobre a vacina
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_EPISODE - ID do episódio
                   I_VACC- ID da vacina
                   I_PAT - ID do paciente
              Saida: O_INFO - retorna se a vacina ?do PNV e as contra-indicações.
                     O_INFO_AGE - retorna as idades minimas para as doses e os intervalos
                     O_ERROR - erro
    
      CRIAÇÃO: Teresa Coutinho
      ALTERAÇÃO :Teresa Coutinho
      NOTAS:
    *********************************************************************************/
    FUNCTION get_vacc_dose_info_detail_new
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_emb      IN me_med.emb_id%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_info_age OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Retornar a toma a administrar.
    *
    * @param      i_lang    Língua registada como preferência do profissional
    * @param      i_vacc    ID da vacina
    * @param      i_pat     ID do paciente
    * @param      i_emb     ID da embalagem
    *
    * @return     TRUE se a função termina com sucesso e FALSE caso contrário
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2007/12/10
    */

    FUNCTION get_vacc_last_take_detail_new
    (
        i_lang            IN language.id_language%TYPE,
        i_vacc            IN vacc.id_vacc%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_emb             IN me_med.emb_id%TYPE,
        i_prof            IN profissional,
        o_info_last_take  OUT pk_types.cursor_type,
        o_predicted_take  OUT pk_types.cursor_type,
        o_predicted_label OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_review
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_review  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_group_name
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE DEFAULT NULL,
        o_group_name         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /* *******************************************************************************************
    *  Get current state of immunization_status for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_vaccines
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get Vaccine name
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient             patient id
    * @param i_id_vacc_type_group vacc_type_group id by market
    * @param i_id_drug            drug id
    *
    * @return                         Vaccine name
    *
    * @author                         Lillian Lu
    * @version                        2.7.3.3
    * @since                          2018/04/27
    *
    **********************************************************************************************/
    FUNCTION get_vacc_name
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_vacc_type_group IN vacc_type_group.id_vacc_type_group%TYPE,
        i_id_drug            IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get Vaccination information by patient
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient             patient id
    *
    * @return                         Vaccination info
    *
    * @author                         Lillian Lu
    * @version                        2.7.3.3
    * @since                          2018/04/27
    *
    **********************************************************************************************/
    FUNCTION get_vaccination_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN CLOB;

    FUNCTION get_dashboard_vacc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vacc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_vacc_type_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_presc_type IN vacc_type_group.flg_presc_type%TYPE,
        o_type_group     OUT vacc_type_group.id_vacc_type_group%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_months_sign VARCHAR2(200);
    g_days_sign   VARCHAR2(200);

    l_green_color  CONSTANT VARCHAR2(50) := '0x829664';
    l_red_color    CONSTANT VARCHAR2(50) := '0xC86464';
    l_normal_color CONSTANT VARCHAR2(50) := '0xEBEBC8';
    --Icons
    g_vacc_icon_check_take  CONSTANT VARCHAR2(15) := 'CheckIcon';
    g_cancel_icon           CONSTANT VARCHAR2(50) := 'CancelIcon';
    g_waitingicon           CONSTANT VARCHAR2(50) := 'WaitingIcon';
    g_presc_prescribed_icon CONSTANT VARCHAR2(50) := 'PrescriptionPrescribedIcon';
    g_not_icon              CONSTANT VARCHAR2(50) := 'NotNeededIcon';

    g_interval_icon CONSTANT VARCHAR2(50) := 'TimeIntervalIcon';

    g_vacc_icon_report_take CONSTANT VARCHAR2(50) := 'PrescriptionReportedByIcon';
    g_administration_label  CONSTANT VARCHAR2(100 CHAR) := 'MED_PRESC_T201';

    g_flg_active CONSTANT VARCHAR2(1) := 'A';
    g_flg_cancel CONSTANT VARCHAR2(1) := 'C';
    g_orig_r     CONSTANT VARCHAR2(1) := 'R';
    g_orig_v     CONSTANT VARCHAR2(1) := 'V';
    g_orig_i     CONSTANT VARCHAR2(1) := 'I'; -- origem do registo na PAT_VACC_ADM: importação SINUS

    g_presc_fin drug_prescription.flg_status%TYPE := 'F';

    g_vacc_status_edit CONSTANT VARCHAR2(1) := 'E';

    g_vacc_dose_report CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Relato de dose administrada
    g_vacc_dose_int    CONSTANT VARCHAR2(1 CHAR) := 'I'; -- Relato vindo do SINUS
    g_vacc_dose_adm    CONSTANT VARCHAR2(1 CHAR) := 'V'; -- Administração

    g_flg_new_vacc drug.flg_type%TYPE;

    g_flg_time_e CONSTANT pat_vacc_adm.flg_time%TYPE := 'E';

    g_nvp_scheduled   CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_nvp_unscheduled CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_nvp_unknown     CONSTANT VARCHAR2(1 CHAR) := 'U';

    g_flg_pnv_yes vacc_type_group.flg_pnv%TYPE;
    g_flg_pnv_no  vacc_type_group.flg_pnv%TYPE;

    -- constantes associadas aos tipos de prescrições possíveis na àrea de vacinas
    g_flg_presc_pnv        vacc_type_group.flg_presc_type%TYPE := 'P';
    g_flg_presc_tuberculin vacc_type_group.flg_presc_type%TYPE := 'T';
    g_flg_presc_other_vacc vacc_type_group.flg_presc_type%TYPE := 'O';

    g_status_s CONSTANT pat_vacc.flg_status%TYPE := 'S'; --Discontinue
    g_status_a CONSTANT pat_vacc.flg_status%TYPE := 'A'; --Resume vaccinse
    g_status_r CONSTANT pat_vacc.flg_status%TYPE := 'R'; --Resume dose    

    g_year  CONSTANT VARCHAR2(1 CHAR) := 'Y'; --Year
    g_month CONSTANT VARCHAR2(1 CHAR) := 'M'; --Month
    g_day   CONSTANT VARCHAR2(1 CHAR) := 'D'; --Day

    g_cat_type_nurse CONSTANT VARCHAR2(1 CHAR) := 'N'; --[UNI264]

    g_vacc_tetano pat_vacc_adm.id_pat_vacc_adm%TYPE := 15; --[UNI264]
    g_vaccine_title        CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_administration_title CONSTANT VARCHAR2(1 CHAR) := 'A';

    --Details launknbels
    g_name_vacc_details CONSTANT VARCHAR2(15 CHAR) := 'VACC_T138'; --Type / vaccine / dose
    -- [uni264] - 'VACC_T005' na linha de cima
    g_adm_details                CONSTANT VARCHAR2(15 CHAR) := 'VACC_T112'; --Administration date/time
    g_adm_dose_details           CONSTANT VARCHAR2(15 CHAR) := 'VACC_T113'; --Administered dose amount
    g_adm_route_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T123'; --Administration route
    g_adm_site_details           CONSTANT VARCHAR2(15 CHAR) := 'VACC_T124'; --Administration site
    g_manufactured_details       CONSTANT VARCHAR2(15 CHAR) := 'VACC_T085'; --Manufacturer name
    g_lot_details                CONSTANT VARCHAR2(15 CHAR) := 'VACC_T007'; --Lot
    g_exp_date_details           CONSTANT VARCHAR2(15 CHAR) := 'VACC_T008'; --Expiration date
    g_origin_details             CONSTANT VARCHAR2(15 CHAR) := 'VACC_T111'; --Vaccine origin
    g_doc_vis_details            CONSTANT VARCHAR2(15 CHAR) := 'VACC_T118'; --VIS document type (edition date)
    g_doc_vis_date_details       CONSTANT VARCHAR2(15 CHAR) := 'VACC_T119'; --VIS presentation date
    g_doc_cat_details            CONSTANT VARCHAR2(15 CHAR) := 'VACC_T116'; --Vaccine funding program eligibility category
    g_doc_source_details         CONSTANT VARCHAR2(15 CHAR) := 'VACC_T117'; --Vaccine funding source
    g_ordered_details            CONSTANT VARCHAR2(15 CHAR) := 'VACC_T114'; --Ordered by
    g_adm_by_details             CONSTANT VARCHAR2(15 CHAR) := 'VACC_T115'; --Administered by
    g_next_dose_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T125'; --Next dose schedule
    g_adv_reaction_details       CONSTANT VARCHAR2(15 CHAR) := 'VACC_T009'; --Adverse reactions
    g_notes_details              CONSTANT VARCHAR2(15 CHAR) := 'VACC_T020'; --Notes                                                        
    g_information_source_details CONSTANT VARCHAR2(15 CHAR) := 'VACC_T120'; --Information source     

    g_adm_title_details      CONSTANT VARCHAR2(15 CHAR) := 'VACC_T129'; --Administration     
    g_adm_edit_title_details CONSTANT VARCHAR2(15 CHAR) := 'VACC_T130'; --Administration edition
    g_rep_title_details      CONSTANT VARCHAR2(15 CHAR) := 'VACC_T131'; --Report     
    g_rep_edit_title_details CONSTANT VARCHAR2(15 CHAR) := 'VACC_T132'; --Report edition
    g_cancel_reason_details  CONSTANT VARCHAR2(15 CHAR) := 'COMMON_M072'; --Cancellation reason
    g_cancel_notes_details   CONSTANT VARCHAR2(15 CHAR) := 'COMMON_M073'; --Cancellation notes
    g_cancel_title_details   CONSTANT VARCHAR2(15 CHAR) := 'COMMON_T032'; --Cancellation
    g_documented_details     CONSTANT VARCHAR2(25 CHAR) := 'DOCUMENTATION_MACRO_M024'; --Documented:
    g_updated_details        CONSTANT VARCHAR2(25 CHAR) := 'DOCUMENTATION_MACRO_M023'; --Updated:

    g_vacc_title_discontinue CONSTANT VARCHAR2(25 CHAR) := 'VACC_T134'; --Discontinuation
    g_vacc_title_resume      CONSTANT VARCHAR2(25 CHAR) := 'VACC_T133'; --Resume

    g_vacc_title_adv_react CONSTANT VARCHAR2(25 CHAR) := 'VACC_T084'; --Record adverse reaction

    g_vacc_sub_title_discontinue CONSTANT VARCHAR2(25 CHAR) := 'VACC_T137'; --Scheduled
    g_vacc_dose_sch_details      CONSTANT VARCHAR2(25 CHAR) := 'VACC_T135'; --Dose schedule
    g_vacc_adm                   CONSTANT VARCHAR2(25 CHAR) := 'VACC_T129'; --Administration
    g_vacc_discontinue           CONSTANT VARCHAR2(25 CHAR) := 'VACC_T138'; --Vaccine

    g_vacc_no_app CONSTANT VARCHAR2(25 CHAR) := 'COMMON_M018'; --'No applicable'

    g_reason CONSTANT VARCHAR2(25 CHAR) := 'VACC_T140'; --Reason

    -- Constants used for reports purpose (by episode; by visit; by patient)    

    g_domain_application_spot sys_domain.code_domain%TYPE := 'DRUG_PRESC_PLAN.APPLICATION_SPOT';
    g_presc_det_fin           drug_presc_det.flg_status%TYPE := 'F';
    g_presc_take_uni          drug_presc_det.flg_take_type%TYPE := 'U';
    g_presc_plan_stat_adm     drug_presc_det.flg_status%TYPE := 'A';
    -- tuberculin
    g_presc_plan_stat_req  drug_presc_plan.flg_status%TYPE := 'R';
    g_presc_plan_stat_pend drug_presc_plan.flg_status%TYPE := 'D';

    g_presc_type_int drug_prescription.flg_type%TYPE := 'I';

    g_tuberculin_test_state_presc CONSTANT VARCHAR2(1) := 'P';
    g_tuberculin_test_state_adm   CONSTANT VARCHAR2(1) := 'A';
    g_tuberculin_test_state_res   CONSTANT VARCHAR2(1) := 'R';
    g_tuberculin_test_state_canc  CONSTANT VARCHAR2(1) := 'C';

    g_upd_admin_status_a CONSTANT vacc_update_admin.flg_status%TYPE := 'A';
    g_upd_admin_status_i CONSTANT vacc_update_admin.flg_status%TYPE := 'I';

    g_vacc_dose_b CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_vacc_dose_d CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_display_type_t  CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_display_type_ti CONSTANT VARCHAR2(2 CHAR) := 'TI';
    g_display_type_tc CONSTANT VARCHAR2(2 CHAR) := 'TC';

    g_drug_presc_det_f CONSTANT drug_presc_det.flg_status%TYPE := 'F';

    g_domain_notes_adv_react_list sys_domain.code_domain%TYPE := 'DRUG_PRESC_PLAN.NOTES_ADVERS_REACT';

    --VALORES DA BD INFARMED
    g_mnsrm           inf_class_disp.class_disp_id%TYPE;
    g_msrm_e          inf_class_disp.class_disp_id%TYPE;
    g_msrm_ra         inf_class_disp.class_disp_id%TYPE;
    g_msrm_rb         inf_class_disp.class_disp_id%TYPE;
    g_msrm_rc         inf_class_disp.class_disp_id%TYPE;
    g_msrm_rc_disable inf_class_disp.class_disp_id%TYPE;
    g_msrm_r_ea       inf_class_disp.class_disp_id%TYPE;
    g_msrm_r_ec       inf_class_disp.class_disp_id%TYPE;
    g_emb_hosp        inf_class_disp.class_disp_id%TYPE;
    g_disp_in_v       inf_class_disp.class_disp_id%TYPE;

    g_prod_diabetes inf_tipo_prod.tipo_prod_id%TYPE;
    g_grupo_0       inf_grupo_hom.grupo_hom_id%TYPE;

    --identifica o grupo das tuberculinas
    --[UNI264] TODO: Este valor deve ser parametrizado
    g_tuberculin_default_dci_id CONSTANT mi_med.dci_id%TYPE := 12156; --[UNI264]
    --parametrização
    g_tuberculin_test_id CONSTANT NUMBER(2) := 18; --[UNI264]

    g_other_value CONSTANT NUMBER := -1;

    g_other_label CONSTANT VARCHAR2(100 CHAR) := 'COMMON_M041';

END pk_immunization_core;
/
