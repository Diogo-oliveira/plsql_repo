/*-- Last Change Revision: $Rev: 2028467 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_discharge IS

    -- Author  : JOSE.SILVA
    -- Created : 03-03-2010 14:52:11
    -- Purpose : API to be used by the interfaces team in the discharge area

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Gets the list of tasks that were selected in the GP Letter
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID
    * @param   i_episode      Episode ID
    * @param   i_discharge    Discharge ID
    *
    * @param   o_tasks        List of tasks         
    *
    * @param   o_error        Error information
    *
    * @return  True or False
    *
    * @author  JOSE.SILVA
    * @version 2.6
    * @since   04-03-2010
    */
    FUNCTION get_task_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_tasks     OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get admission date
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID
    * @param   i_episode      Episode ID
    *
    * @param   o_info         Admission date
    *
    * @param   o_error        Error information
    *
    * @return  True or False
    *
    * @author  JOSE.SILVA
    * @version 2.6
    * @since   04-03-2010
    */
    FUNCTION get_admission_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets a discharge, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_prof_cat              logged professional category
    * @param i_disch                 discharge identifier
    * @param i_episode               episode identifier
    * @param i_dt_end                discharge date
    * @param i_disch_dest            discharge reason destiny identifier
    * @param i_notes                 discharge notes_med
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Teixeira
    * @since                         26/07/2010
    ********************************************************************************************/
    FUNCTION set_discharge_amb
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_disch      IN discharge.id_discharge%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_end     IN VARCHAR2,
        i_disch_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes      IN discharge.notes_med%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets medical discharge info in enviroments where price is specified.
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    * @param   i_reas_dest           discharge reason by destination
    * @param   i_disch_type          discharge type
    * @param   i_flg_type            flag type
    * @param   i_notes               discharge notes
    * @param   i_transp              transport id
    * @param   i_justify             discharge justify
    * @param   i_prof_cat_type       prof category type
    * @param   i_price               appointment price
    * @param   i_currency            appointment price currency
    * @param   i_flg_payment         payment condition
    * @param   i_flg_surgery         indicates if discharge for internment is associated to a surgery (Y/N)
    * @param   i_dt_surgery          date of surgery
    * @param   i_clin_serv           id_clinical_service of internment speciality, in case od discharge for internment
    * @param   i_department          department id
    * @param   i_flg_print_report    print report (Y/N)
    * @param   i_sysdate             record date
    * @param   i_flg_pat_condition   patient condition
    * @param   o_reports_pat         patient report
    * @param   o_flg_show            does it shows buttons
    * @param   o_msg_title           warning/error message title
    * @param   o_msg_text            warning/error message
    * @param   o_button              the buttons to show in the warning/error
    * @param   o_id_episode          episode id
    * @param   o_id_shortcut         shortcut id
    * @param   o_discharge           discharge id
    * @param   o_discharge_detail    discharge_detail id
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.4
    * @since   18-08-2010
    *
    */
    FUNCTION intf_set_discharge
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN discharge.id_episode%TYPE,
        i_prof              IN profissional,
        i_reas_dest         IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type        IN discharge.flg_type%TYPE,
        i_flg_type          IN VARCHAR2,
        i_notes             IN discharge.notes_med%TYPE,
        i_transp            IN transp_entity.id_transp_entity%TYPE,
        i_justify           IN discharge.notes_justify %TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_price             IN discharge.price%TYPE,
        i_currency          IN discharge.currency%TYPE,
        i_flg_payment       IN discharge.flg_payment%TYPE,
        i_flg_surgery       IN VARCHAR2,
        i_dt_surgery        IN VARCHAR2,
        i_clin_serv         IN clinical_service.id_clinical_service%TYPE,
        i_department        IN department.id_department%TYPE,
        i_flg_print_report  IN discharge_detail.flg_print_report%TYPE DEFAULT NULL,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_pat_condition IN discharge_detail.flg_pat_condition%TYPE,
        o_reports_pat       OUT reports.id_reports%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_id_episode        OUT episode.id_episode%TYPE,
        o_id_shortcut       OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_discharge         OUT discharge.id_discharge%TYPE,
        o_discharge_detail  OUT discharge_detail.id_discharge_detail%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert discharge notes, follow-up entities
    * and manages pending issues related to discharge instructions.
    *
    * @param i_lang                    Language id
    * @param i_prof                    Professional, software and institution ids
    * @param i_prof_cat_type           Professional category
    * @param i_epis                    Episode id
    * @param i_patient                 Patient id
    * @param i_id_disch                Discharge notes id
    * @param i_epis_complaint          Patient complaint
    * @param i_epis_diagnosis          Patient diagnosis
    * @param i_recommended             Recommendations for patient    
    * @param i_release_from            Release from work or school
    * @param i_dt_from                 Release from this date...
    * @param i_dt_until                ...until this date
    * @param i_notes_release           Release notes
    * @param i_instructions_discussed  Instructions discussed with...
    * @param i_follow_up_with          Follow-up entities ID (can be a physician, external physician or external institution)
    * @param i_follow_up_in            Array of dates or number of days from which the patient must be followed-up
    * @param i_id_follow_up_type       Array of type of follow-up: D - Date; DY - Days; S - SOS
    * @param i_flg_follow_up_with      Follow-up with: (OC) on-call physician (PH) external physician
                                                       (CL) clinic (OF) office (O) other (free text specified in 'i_follow_up_text')
    * @param i_follow_up_text          Specified follow-up entity, with free text, if 'i_flg_follow_up_with' is 'O'
    * @param i_follow_up_notes         Specific notes for follow-up
    * @param i_issue_assignee         Selected assignee(s) in the multichoice, in the format: P<id> or G<id>
                                       Examples:
                                                P142 (Professional with ID_PROFESSIONAL = 142)
                                                G27  (Group with ID_GROUP = 27)
    * @param i_issue_title             Title for the pending issue
    * @param i_flg_printer             Flag printer: P - Printed
    * @param i_commit_data             Commit date? (Y) Yes (N) No   
    * @param i_sysdate                 record date   
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Alexandre Santos
    * @version                         2.6.0.4
    * @since                           2010-08-18
    *
    ********************************************************************************************/
    FUNCTION intf_set_discharge_notes
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_id_disch               IN discharge_notes.id_discharge_notes%TYPE,
        i_epis_complaint         IN discharge_notes.epis_complaint%TYPE,
        i_epis_diagnosis         IN discharge_notes.epis_diagnosis%TYPE,
        i_recommended            IN discharge_notes.discharge_instructions%TYPE,
        i_release_from           IN discharge_notes.release_from%TYPE,
        i_dt_from                IN VARCHAR2,
        i_dt_until               IN VARCHAR2,
        i_notes_release          IN discharge_notes.notes_release%TYPE,
        i_instructions_discussed IN discharge_notes.instructions_discussed%TYPE,
        i_follow_up_with         IN table_number,
        i_follow_up_in           IN table_varchar,
        i_id_follow_up_type      IN table_number,
        i_flg_follow_up_type     IN follow_up_entity.flg_type%TYPE,
        i_follow_up_text         IN VARCHAR2,
        i_follow_up_notes        IN VARCHAR2,
        i_issue_assignee         IN table_varchar,
        i_issue_title            IN pending_issue.title%TYPE,
        i_flg_printer            IN VARCHAR,
        i_commit_data            IN VARCHAR2,
        i_sysdate                IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_discharge_note      OUT discharge_notes.id_discharge_notes%TYPE,
        o_reports_pat            OUT reports.id_reports%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Clears all records from discharge and related (FK's) tables for the given id_episode's
    *
    * @param i_lang                    Language id
    * @param i_table_id_episodes       table with id episodes
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Alexandre Santos
    * @version                         2.6.0.4
    * @since                           2010-09-08
    *
    ********************************************************************************************/
    FUNCTION clear_discharge_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_episodes IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**
    * Valid if there report request by the user, if not, creates a report asynchronously.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_EPISODE episode id
    * @param   I_DISCHARGE discharge id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CURRENCY appointment price currency
    
    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Nuno Neves
    * @version 2.6.05
    * @since   23-Dec-2010
    */
    FUNCTION check_request_print_report
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN discharge.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        i_prof      IN profissional,
        i_currency  IN discharge.currency%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Checks if the current discharge record shows the MyAlert purchase form
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_episode            episode ID
    * @param o_flg_has_trans_model   has transactional model: Y - yes, N - No
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        José Silva
    * @version                       2.6.0.5
    * @since                         13-01-2011
    ********************************************************************************************/
    FUNCTION check_transactional_model
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_flg_has_trans_model OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets administrative discharge and ends the episode
    *
    * @param i_lang                           language id
    * @param i_prof                           professional, software and institution ids
    * @param i_episode                        episode id
    * @param i_reas_dest                      Relation between discharge reason and destiny
    * @param i_notes                          Discharge notes
    * @param i_transp                         Transport id
    * @param i_flg_status                     Status                     
    * @param o_flg_show
    * @param o_msg_title
    * @param o_msg_text
    * @param o_button
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Alexandre Santos
    * @version                                1.0
    * @since                                  27-09-2012
    ********************************************************************************************/
    FUNCTION intf_set_epis_discharge
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_episode      IN NUMBER,
        i_flg_new_epis IN VARCHAR2,
        i_reas_dest    IN NUMBER,
        i_notes        IN discharge.notes_med%TYPE,
        i_transp       IN discharge.id_transp_ent_med%TYPE,
        i_flg_status   IN discharge.flg_status%TYPE,
        i_dt_admin     IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_reports      OUT reports.id_reports%TYPE,
        o_reports_pat  OUT reports.id_reports%TYPE,
        o_id_episode   OUT episode.id_episode%TYPE,
        o_id_discharge OUT discharge.id_discharge%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION intf_set_discharge_date
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN discharge_schedule.id_episode%TYPE,
        i_prof                  IN profissional,
        i_dt_discharge_schedule IN VARCHAR2,
        i_flg_hour_origin       IN VARCHAR2 DEFAULT 'DH',
        o_id_discharge_schedule OUT discharge_schedule.id_discharge_schedule%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets  discharge note instructions 
    *
    * @param i_lang                           language id
    * @param i_prof                           professional, software and institution ids
    * @param i_episode                        episode id
    * @param i_patient                        patient id    
    * @param i_discharge_instructions         discharge instructions
    * @param o_id_discharge_notes
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Alexis Nascimento
    ********************************************************************************************/

    FUNCTION intf_set_discharge_instr
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_discharge_instructions IN discharge_notes.discharge_instructions%TYPE,
        o_id_discharge_notes     OUT discharge_notes.id_discharge_notes%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    --
    g_yes VARCHAR2(1);
    g_no  VARCHAR2(1);

END pk_api_discharge;
/
