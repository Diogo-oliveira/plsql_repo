/*-- Last Change Revision: $Rev: 2028564 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_clinical_notes IS

    /*
    * Get summary of medical notes ( grouping by topics )  FOR REPORTS
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF_ID                  ID OF professional
    * @param   I_PROF_INSTITUTION         ID OF  institution 
    * @param   I_PROF_SOFTWARE            ID OF software
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   o_more_records             Has more records to show: 1 - Yes; 0 - No; 
    * @param   o_sql                      notes made in given interval
    * @param   o_notes_desc               notes description grouped by session
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-JUL-2008
    *
    */
    FUNCTION get_summary_externo
    (
        i_lang             IN language.id_language%TYPE,
        i_prof_id          IN professional.id_professional%TYPE,
        i_prof_institution IN institution.id_institution%TYPE,
        i_prof_software    IN software.id_software%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_type         IN epis_recomend.flg_type%TYPE,
        o_more_records     OUT NUMBER,
        o_sql              OUT NOCOPY pk_types.cursor_type,
        o_notes_desc       OUT table_table_clob,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *   WRITES MEDICAL NOTES for diagnosis ( DIARIES )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               ID OF EPISODE
    * @param   I_ID_diagnosis             ID OF DIAGNOSIS
    * @param   I_FLG_STATUS               STATUS OF DIAGNOSIS
    * @param   I_SPECIFIC_NOTES           SPECIFIC NOTES REGISTERED WITH DIAGNOSIS
    * @param   I_GENERAL_NOTES            ENERAL NOTES FOR REGISTERED DIAGNOSIS
    * @param   I_ID_ALERT_DIAG            Id of alert_diagnosis (ALERT-736: diagnosis synonyms support)
    * @param   I_EPIS_DIAG_FLG_TYPE       Type of association between episode and diagnose (Final or Differential)
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   20-JUL-2007
    *
    */
    FUNCTION set_diagnosis_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_diagnosis       diagnosis.id_diagnosis%TYPE,
        i_flg_status         epis_diagnosis.flg_status%TYPE,
        i_specific_notes     epis_diagnosis.notes%TYPE,
        i_general_notes      epis_diagnosis_notes.notes%TYPE,
        i_id_alert_diag      epis_diagnosis.id_alert_diagnosis%TYPE,
        i_epis_diag_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *   WRITES MEDICAL NOTES TO EPIS_RECOMEND ( DIARIES )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               ID OF EPISODE
    * @param   I_ID_HABIT                 ID OF HABIT
    * @param   I_FLG_STATUS               STATUS OF HABIT
    * @param   I_FLG_NATURE               NATURE OF HABIT
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_habit_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_habit   habit.id_habit%TYPE,
        i_flg_status pat_problem.flg_status%TYPE,
        i_flg_nature pat_problem.flg_nature%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *   WRITES MEDICAL NOTES TO EPIS_RECOMEND ( DIARIES )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               ID OF EPISODE
    * @param   I_ID_ALLERGY               ID OF ALLERGY
    * @param   I_ID_PAT_ALLERGY           Patient Allergy identifier
    * @param   I_FLG_STATUS               STATUS OF ALLERGY
    * @param   I_FLG_NATURE               NATURE OF ALLERGY
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   20-DEC-2007
    *
    */
    FUNCTION set_allergy_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_allergy     allergy.id_allergy%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_flg_status     pat_allergy.flg_status%TYPE,
        i_flg_nature     pat_allergy.flg_nature%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get DESCRIPTION O FINTERVENTION 
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_interv_presc_det        id of prescribed INTERVENTION
    *
    * @RETURN  string of INTERVENTION prescribed or null if no_data_found, or error msg
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-JUL-2008
    *
    */
    FUNCTION get_itv_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Returns a set of medical/nursing notes based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID 
    * @param   i_flg_type           Type of notes
    * @param   i_flg_summary        Type of summary 
    * @param   i_flg_report         Function invoked by reports 
    * @param   i_fltr_time_frame    Filter sessions of a specific time frame rank. Default NULL (no filter)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_day          Number of the start day. Just considered when paging is used. Default 1
    * @param   i_num_days           Number of days to be retrieved. Just considered when paging is used.  Default 5
    * @param   o_more_records       Give how many days of records should be presented according to one institution;
    * @param   o_more_days          All registries were returned in this function: 1 -> If there are more results; 0 -> If there are not more results.
    * @param   o_sql                Notes made in given interval
    * @param   o_notes_desc         Notes description grouped by session
    * @param   o_status             Notes status grouped by session
    * @param   o_error              Error message 
    *
    * @value   i_flg_type         {*} g_medical_notes Medical notes {*} g_nursing_notes Nursing notes
    * @value   i_flg_summary      {*} g_flg_smry_full Full summary {*} g_flg_smry_last_days Summary with the most recent [i_days_on_summary] days {*} g_flg_smry_last_days_timeframe Summary with the most recent [i_days_on_summary] days for each time frame rank/interval
    * @value   i_flg_report       {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    * @value   i_paging           {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.8.2
    * @since   18-10-2011
    */
    FUNCTION get_paginated_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_flg_summary     IN VARCHAR2,
        i_flg_report      IN notes_profile_inst.flg_print%TYPE,
        i_fltr_time_frame IN NUMBER DEFAULT NULL,
        i_paging          IN VARCHAR2 DEFAULT 'N',
        i_start_day       IN NUMBER DEFAULT 1,
        i_num_days        IN NUMBER DEFAULT 5,
        o_more_records    OUT NUMBER,
        o_more_days       OUT NUMBER,
        o_sql             OUT pk_types.cursor_type,
        o_notes_desc      OUT table_table_clob,
        o_status          OUT table_table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get summary of medical notes ( grouping by topics )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_flg_summary              It is supposed return all registries ('N') or only the first's ones ('Y');
    * @param   o_more_records             Give how many days of records should be presented according to one institution;
    * @param   o_more_days                All registries were returned in this function: 1 -> If there are more results; 0 -> If there are not more results.
    * @param   o_sql                      notes made in given interval
    * @param   o_notes_desc               notes description grouped by session
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-JUL-2008
    *
    */
    FUNCTION get_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_flg_type     IN epis_recomend.flg_type%TYPE,
        i_flg_summary  IN VARCHAR2, -- INP LMAIA 04-03-2009. IF 'Y' only returns last 3 days of registries, otherwise returns all.
        o_more_records OUT NUMBER,
        o_more_days    OUT NUMBER, -- INP LMAIA 04-03-2009. 1 -> If there are more results; 0 -> If there are not more results.
        o_sql          OUT NOCOPY pk_types.cursor_type,
        o_notes_desc   OUT table_table_clob,
        o_status       OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Processes lines for grouping.
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_FLG_ID_ITEM              FLAG WHICH SAYS IF WE USE THE DESC OU THE ID_ITEM
    * @param   i_DESC_epis_recomend       DESCRIPTION OF ITEM TO PROCESS
    * @param   i_ID_ITEM                  ID OF ITEM TO PROCESS
    * @param   i_NOTES_CODE               TYPE OF ITEM FROM NOTES_CONFIG
    * @param   i_FORMAT                   STRING FOR FORMATING OUTPUT
    * @param   i_flg_show_outd_data       Y - show the outdated data; 
    *                                     N - to the outdated shows a message saying 'outdated'
    * @param   O_line                     line processed
    * @param   o_status                   Record status (active, outdated)
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-Jul-2008
    *
    */
    FUNCTION get_item
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_id_item        IN notes_config.flg_id_item%TYPE,
        i_desc_epis_recomend IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item            IN epis_recomend.id_item%TYPE,
        i_notes_code         IN notes_config.notes_code%TYPE,
        i_format             IN notes_group.desc_format%TYPE,
        i_flg_show_outd_data IN VARCHAR2,
        o_item               OUT CLOB,
        o_status             OUT epis_documentation.flg_status%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * SAves beginning of session ( can end previous unfinished session )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION init_session
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * SAves end of session
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION end_session
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * insert into table epis_recomend
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_rec                      record structure of epis_recomend
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION ins_epis_recomend
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_rec   IN epis_recomend%ROWTYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get profile of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   o_profile_template         id_profile of professional
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION get_profile_template
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_profile_template OUT profile_template.id_profile_template%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get category of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   o_category                 category of active professional
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION get_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT category.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * set notes of professional based on access granted and profiles
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_valuer                   secondary value
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_clinical_notes_no_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_value      IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item    IN epis_recomend.id_item%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_clinical_notes_no_commit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_value      IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * set notes of professional based on access granted and profiles
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_valuer                   secondary value
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   19-DEC-2007
    *
    */
    FUNCTION set_clinical_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_value      IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set notes for inpatient episodes in visit of current episode
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_notes_code               code to identify which kind of record is being saved.
    * @param   i_desc                     Main description
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   07-FEB-2008
    *
    */
    FUNCTION set_clinical_notes_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN VARCHAR2, --notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item    IN epis_recomend.id_item%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_clinical_notes_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes_code IN VARCHAR2, --notes_config.notes_code%TYPE,
        i_desc       IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set notes for inpatient episodes in visit of current episode
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_doc_area              id_doc_area given to find corresponding notes_code
    * @param   i_desc                     Main description
    * @param   i_id_item                  Id item
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   07-FEB-2008
    *
    */
    FUNCTION set_clinical_notes_doc_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_desc        IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_id_item     IN epis_recomend.id_item%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_clinical_notes_doc_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_desc        IN epis_recomend.desc_epis_recomend_clob%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notes_format
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_notes_code IN notes_config.notes_code%TYPE,
        o_format     OUT notes_config.code_group_desc%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get summary of medical notes registered in one specific session ( registries order by time )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_session_id               Session_id of section to be presented in detail screen
    * @param   o_session_summary          Has summary information about current session: "Hour INIT - Hour END (DAY)"
    * @param   o_session_detail           Notes made in current session order by registry time
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   07-JAN-2009
    *
    */
    FUNCTION get_summary_session_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_session_id      IN epis_recomend.session_id%TYPE,
        o_session_summary OUT VARCHAR2,
        o_session_detail  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get diaries info in one session, episode, patient or visit ( registries ordered by time )
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_flg_type                 diary type: M - doctor N - Nurse
    * @param   i_flg_scope                Scope: P -patient; E- episode; V-visit; S-session
    * @param   i_id_episode               Episode identifier; mandatory if i_flg_scope='E'
    * @param   i_id_patient               Patient identifier; mandatory if i_flg_scope='P'
    * @param   i_id_visit                 Visit identifier; mandatory if i_flg_scope='V'
    * @param   i_flg_report_type          Report type: C-complete; D-detailed
    * @param   i_session_id               Session_id of section to be presented in detail screen. Mandatory if i_flg_scop='S'
    * @param   i_start_date               Start date to be considered
    * @param   i_end_date                 End date to be considered    
    * @param   o_detail                   Notes made in current session/episode/patient/visit order by registry time
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   23-Nov-2010
    *
    */
    FUNCTION get_diary_info_reports
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN epis_recomend.flg_type%TYPE,
        i_session_id      IN epis_recomend.session_id%TYPE,
        i_flg_scope       IN VARCHAR2, -- P -patient; E- episode; V-visit
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Processes group and lines for sumarry page.
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_session_id               id of session to process
    * @param   i_id_notes_ground          id of group to process
    * @param   i_id_episode               id of episode
    * @param   o_list_notes               List of notes of a group
    * @param   o_list_status              List of status of a group
    * @param   O_line                     line processed
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   14-Jul-2008
    *
    */
    FUNCTION get_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_session_id     IN epis_recomend.session_id%TYPE,
        i_id_notes_group IN notes_group.id_notes_group%TYPE,
        i_id_episode     IN epis_recomend.id_episode%TYPE,
        i_flg_report     IN notes_profile_inst.flg_print%TYPE,
        o_list_notes     OUT table_clob,
        o_list_status    OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the Areas where the professional has access to write
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_flg_diary    Type of Diary
    *                            'P' - Physician Diary Notes
    *                            'N' - Nurse Diary Notes
    * @param o_areas        Areas with permissions to write
    * @param o_error        Error object
    *
    * @return               true if sucess, false otherwise
    *
    * @author               António Neto
    * @version              2.6.1
    * @since                13-Oct-2011
    ********************************************************************************************/
    FUNCTION get_area_write_permissions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_diary IN VARCHAR2,
        o_areas     OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    -- Log initialization.    
    g_owner   VARCHAR2(0050);
    g_package VARCHAR2(0050);

    g_cat_nurse        CONSTANT category.flg_type%TYPE := 'N';
    g_cat_doctor       CONSTANT category.flg_type%TYPE := 'D';
    g_cat_adm          CONSTANT category.flg_type%TYPE := 'A';
    g_cat_nutri        CONSTANT category.flg_type%TYPE := 'U';
    g_cat_pharmacist   CONSTANT category.flg_type%TYPE := 'P';
    g_cat_technician   CONSTANT category.flg_type%TYPE := 'T';
    g_cat_director     CONSTANT category.flg_type%TYPE := 'R';
    g_cat_coordinator  CONSTANT category.flg_type%TYPE := 'C';
    g_cat_physical     CONSTANT category.flg_type%TYPE := 'F';
    g_definitive       CONSTANT VARCHAR2(0001) := 'D';
    g_yes              CONSTANT VARCHAR2(0001) := 'Y';
    g_no               CONSTANT VARCHAR2(0001) := 'N';
    g_begin_session    CONSTANT notes_config.notes_code%TYPE := 'BGN';
    g_end_session      CONSTANT notes_config.notes_code%TYPE := 'END';
    g_exam_session     CONSTANT notes_config.notes_code%TYPE := 'IMG';
    g_analysis_session CONSTANT notes_config.notes_code%TYPE := 'ANL';
    g_physexam_session CONSTANT notes_config.notes_code%TYPE := 'PHY';
    g_revsys_session   CONSTANT notes_config.notes_code%TYPE := 'RSY';
    g_plan_session     CONSTANT notes_config.notes_code%TYPE := 'PLA';
    g_hpi_session      CONSTANT notes_config.notes_code%TYPE := 'HPI';
    g_pbm_session      CONSTANT notes_config.notes_code%TYPE := 'PBM';
    g_rds_session      CONSTANT notes_config.notes_code%TYPE := 'RDS';
    g_alg_session      CONSTANT notes_config.notes_code%TYPE := 'ALG';
    g_hbt_session      CONSTANT notes_config.notes_code%TYPE := 'HBT';
    g_exr_session      CONSTANT notes_config.notes_code%TYPE := 'EXR';
    g_otr_session      CONSTANT notes_config.notes_code%TYPE := 'OTR';
    g_anr_session      CONSTANT notes_config.notes_code%TYPE := 'ANR';
    g_mec_session      CONSTANT notes_config.notes_code%TYPE := 'MEC';
    g_xrv_session      CONSTANT notes_config.notes_code%TYPE := 'XRV';
    g_crv_session      CONSTANT notes_config.notes_code%TYPE := 'CRV';
    g_trs_session      CONSTANT notes_config.notes_code%TYPE := 'TRS';
    g_dgn_session      CONSTANT notes_config.notes_code%TYPE := 'DGN';
    --
    g_id_session_begin CONSTANT epis_recomend.session_id%TYPE := 1;
    g_id_session_end   CONSTANT epis_recomend.session_id%TYPE := 2;
    --


    g_review_exam     CONSTANT tests_review.flg_type%TYPE := 'E';
    g_review_analysis CONSTANT tests_review.flg_type%TYPE := 'A';
    g_review_result   CONSTANT tests_review.flg_type%TYPE := 'R';

    g_disagree    CONSTANT epis_attending_notes.flg_agree%TYPE := 'D';
    g_treat_drugs CONSTANT treatment_management.flg_type%TYPE := 'D';

    g_cfg_text    CONSTANT VARCHAR2(0010) := 'TXT';
    g_empty_space CONSTANT VARCHAR2(1) := ' ';
    
    g_true      CONSTANT NUMBER := 1;
    g_false     CONSTANT NUMBER := 0;
    g_msg_error CONSTANT VARCHAR2(0010) := 'ERROR:';

    

    g_none_alert_diagnosis    CONSTANT NUMBER(24) := -1;
    g_unknown_alert_diagnosis CONSTANT NUMBER(24) := 0;

    g_msg_edited        CONSTANT VARCHAR2(30) := 'DETAIL_COMMON_M002';
    g_msg_cancelled     CONSTANT VARCHAR2(30) := 'DETAIL_COMMON_M003';
    g_slash             CONSTANT VARCHAR2(30) := ' / ';
    g_open_parenthesis  CONSTANT VARCHAR2(30) := ' (';
    g_close_parenthesis CONSTANT VARCHAR2(30) := ')';
    g_comma             CONSTANT VARCHAR2(30) := '; ';
    g_colon             CONSTANT VARCHAR2(30) := ': ';

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_ret          BOOLEAN;
    g_error        VARCHAR2(4000);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    --Antonio.Neto (19-Nov-2010) Constants needed ro remove "Free Text" from Physicians Diaries (ALERT-126888)
    g_cfg_show_free_text     CONSTANT sys_message.code_message%TYPE := 'PHYSICIAN_DIARIES_HEADER_FREE_TEXT_FILTER';
    g_cfg_show_free_text_det CONSTANT sys_message.code_message%TYPE := 'PHYSICIAN_DIARIES_HEADER_FREE_TEXT_FILTER_DETAIL';
    g_free_text              CONSTANT notes_group.intern_name%TYPE := 'GRP_FREE_TEXT';

    -- Scope to be used in the diaries get info
    g_scope_session_s CONSTANT VARCHAR2(1) := 'S';
    g_scope_episode_e CONSTANT VARCHAR2(1) := 'E';
    g_scope_patient_p CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit_v   CONSTANT VARCHAR2(1) := 'V';

    -- report types
    g_report_complete_c CONSTANT VARCHAR2(1) := 'C';
    g_report_complete_d CONSTANT VARCHAR2(1) := 'D';

    --ALERT-196894 (AN)
    g_diary_physician   CONSTANT VARCHAR2(13) := 'INP_DIARY_DOC';
    g_diary_nurse       CONSTANT VARCHAR2(15) := 'INP_DIARY_NURSE';
    g_diary_entry_notes CONSTANT VARCHAR2(21) := 'INP_DIARY_ENTRY_NOTES';
    g_diary_sch_disch   CONSTANT VARCHAR2(19) := 'INP_DIARY_SCH_DISCH';

    g_flg_diary_physician_p CONSTANT VARCHAR2(19) := 'P';
    g_flg_diary_nurse_n     CONSTANT VARCHAR2(19) := 'N';

    /** Full summary with all days (slow). Just for reports or data export */
    g_flg_smry_full CONSTANT VARCHAR2(1 CHAR) := 'N';
    /** Summary with the most recent "N" days. Used in Dashboards */
    g_flg_smry_last_days CONSTANT VARCHAR2(1 CHAR) := 'Y';
    /** Chronological summary: Summary with the most recent "N" days for each time frame rank/interval */
    g_flg_smry_last_days_timeframe CONSTANT VARCHAR2(1 CHAR) := 'T';

    /** Medical notes*/
    g_medical_notes CONSTANT VARCHAR2(1 CHAR) := 'M';
    /** Nursing notes*/
    g_nursing_notes CONSTANT VARCHAR2(1 CHAR) := 'N';

END;
/
