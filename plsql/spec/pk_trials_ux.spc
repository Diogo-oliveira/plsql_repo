/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_trials_ux IS

    -- Author  : ORLANDO.ANTUNES
    -- Created : 25-01-2011 09:37:09
    -- Purpose : The goal of this package is to support all APIs that will be used 
    --           by the Flash layer in the Trials functionality.

    --generic exception
    g_exception EXCEPTION;
    --current time
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    --Types
    SUBTYPE varchar_1 IS VARCHAR2(1 CHAR);
    SUBTYPE varchar_date IS VARCHAR2(20 CHAR);

    --trial typE    
    --external
    g_trial_f_trial_type_e CONSTANT varchar_1 := 'E';
    --internal
    g_trial_f_trial_type_i CONSTANT varchar_1 := 'I';

    --pat_trial status
    g_pat_trial_f_status_c CONSTANT varchar_1 := 'C';
    g_pat_trial_f_status_f CONSTANT varchar_1 := 'F';
    g_pat_trial_f_status_d CONSTANT varchar_1 := 'D';
    g_pat_trial_f_status_r CONSTANT varchar_1 := 'R';
    g_pat_trial_f_status_h CONSTANT varchar_1 := 'H';

    --trial status
    g_trial_f_status_a CONSTANT varchar_1 := 'A';
    g_trial_f_status_i CONSTANT varchar_1 := 'I';
    g_trial_f_status_r CONSTANT varchar_1 := 'R';
    g_trial_f_status_d CONSTANT varchar_1 := 'D';
    g_trial_f_status_f CONSTANT varchar_1 := 'F';
    g_trial_f_status_c CONSTANT varchar_1 := 'C';

    /**********************************************************************************************
    * Retrieves the list of internal trials. This list excludes all the trials that 
    * have been canceled by the professionals.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_trials_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_trials_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Change the state of a given trial.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_status           New trial status
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION set_internal_trial_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_trial_id     IN trial_hist.id_trial%TYPE,
        i_trial_status IN trial.flg_status%TYPE,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves the list of internal trials that are under responsability of a given professional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_my_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_trials_list   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves the list of internal trials that are under responsability of a given professional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_my_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_trials_list   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Retrieves the list Trials (internal and external) in which a patient is participating 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param o_trials_int_list        array with the list of internal Trials
    * @param o_trials_ext_list        array with the list of external Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_pat_trials_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_trials_int_list OUT pk_types.cursor_type,
        o_trials_ext_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves the information for a given internal trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param o_trials_list            Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_internal_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN trial.id_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a new internal trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     List of IDs of professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION set_internal_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a new internal trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     List of IDs of professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_internal_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_pharma_code        IN trial.pharma_code%TYPE,
        i_pharma_name        IN trial.pharma_name%TYPE,
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Creates a new external trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     Text with the name of the responsible(s) for the trial
    * @param i_trial_resp_contact     Contact details for the responsible(s) for the trial    
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION set_external_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN VARCHAR2,
        i_trial_resp_contact IN VARCHAR2,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_commit             IN VARCHAR2 DEFAULT 'Y',
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set the internal trials in which the patient is paticipating
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_episode             ID episode
    * @param i_trials_id              array with internal trial IDs
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date  
    * @param o_pat_trial_ids          array with the created pat trials 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_pat_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_trials_ids    IN table_number,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_pat_trial_ids OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Create an external trials in which the patient is paticipating
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_episode             ID episode
    * @param i_id_pat_trial           ID pat_trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_responsibles     Text with the name of the responsible(s) for the trial
    * @param i_trial_resp_contact     Contact details for the responsible(s) for the trial    
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param i_trials_id              array with internal trial IDs
    * @param o_pat_trial_ids          array with the created pat trials 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_pat_external_trials
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_pat_trial       IN pat_trial.id_pat_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_responsibles IN trial.responsible%TYPE DEFAULT NULL,
        i_trial_resp_cont    IN trial.resp_contact_det%TYPE DEFAULT NULL,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_pat_trial_id       OUT pat_trial.id_pat_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list of professionals that can be responsible for internal trials.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_prof_list              list of professionals 
    * @param o_cat_list               list of possible categories 
    * @param o_screen_labels          Labels   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_responsibles_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_prof_list     OUT pk_types.cursor_type,
        o_cat_list      OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel internal trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason     
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION cancel_internal_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves the list of follow ups for a given patient's trial.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_trial_follow_up_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_trial   IN pat_trial.id_pat_trial%TYPE,
        o_follow_up_list OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_trial_desc     OUT trial.name%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Create or edit a follow up associated with a given patient internal Trial
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_pat_trial_follow_up   ID trial follow up
    * @param i_id_pat_trial           ID pat_trial
    * @param i_follow_up_notes        Follow_up_notes 
    * @param o_id_pat_trial_follow_up Follow up ID for the created follow up 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/02/01
    **********************************************************************************************/
    FUNCTION set_pat_trial_follow_up
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        i_id_pat_trial           IN pat_trial.id_pat_trial%TYPE,
        i_follow_up_notes        IN pat_trial_follow_up.notes%TYPE,
        o_id_pat_trial_follow_up OUT pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************
    * Returns all professionals associated with a given list of categories
    * for an institution
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_categories             array with categories
    * @param i_institution            ID institution 
    * @param o_profs                  list of professionals 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/02/01
    **********************************************************************************************/
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_categories  IN table_number,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************
    * Get patient trial create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient                ID patient
    * @param o_actions      actions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    ***********************************************************************************************/
    FUNCTION get_create_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_create_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Gets the detail of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_trial_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_trial IN trial.id_trial%TYPE,
        o_trial    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_trial_detail_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_trial   IN trial.id_trial%TYPE,
        o_trial      OUT pk_types.cursor_type,
        o_trial_hist OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Descontinue the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION hold_pat_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Descontinue the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION descontinue_pat_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Discontinue the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION discontinue_pat_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Conclude the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION conclude_pat_trial
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail of a patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_followup      cursor with followup
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/09
    **********************************************************************************************/
    FUNCTION get_pat_trial_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_trial   IN pat_trial.id_pat_trial%TYPE,
        o_trial          OUT pk_types.cursor_type,
        o_followup_title OUT pk_types.cursor_type,
        o_followup       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial id  PAT trial
    * @param o_trial        trial cursor
    * @param o_followup     follow up notes
    * @param o_trial_hist   trial hist cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_pat_trial_detail_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN trial.id_trial%TYPE,
        o_trial        OUT pk_types.cursor_type,
        o_followup     OUT pk_types.cursor_type,
        o_trial_hist   OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail of a patient trial for viewer
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/09
    **********************************************************************************************/
    FUNCTION get_trials_details_viewer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        o_trial        OUT pk_types.cursor_type,
        o_responsible  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves the information for a given follow up.
    * If the i_id_pat_trial_follow_up parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                    the id language
    * @param i_prof                    professional, software and institution ids
    * @param i_id_pat_trial_follow_up  ID follow up to edit, or NULL for follow  creation
    * @param o_follow_up               Information for the follow up to edit
    * @param o_screen_labels           Labels for the edit screen
    * @param o_error                   Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/10
    **********************************************************************************************/
    FUNCTION get_pat_trial_follow_up_edit
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_follow_up              OUT pk_types.cursor_type,
        o_screen_labels          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail of a patient trial
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pat_trial_follow_up id  pat trial follow up
    * @param o_followup               cursor with followup
    * @param o_error                  error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/10
    **********************************************************************************************/
    FUNCTION get_follow_up_detail
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_followup               OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel patient follow up trials .
    *
    * @param i_lang                      Id language
    * @param i_prof                      Professional, software and institution ids
    * @param i_id_pat_trial_follow_up    ID Follow up
    * @param i_notes                     Cancel notes
    * @param i_cancel_reason             ID Cancel reason    
    * @param o_error                     Error message
    *
    * @return                            TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/10
    **********************************************************************************************/
    FUNCTION cancel_follow_up_trial
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        i_notes                  IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Retrieves the information for a given external trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param o_trial                  Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_external_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN pat_trial.id_pat_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Resume the patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/08
    **********************************************************************************************/
    FUNCTION resume_pat_trial
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_followup_det_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_follow_up  IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_followup      OUT pk_types.cursor_type,
        o_followup_hist OUT table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get actions for patient trials
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_subject           Subject of action
    * @param i_from_state        Array of status of trials
    * @param i_pat_trial         Array of patient trials
    * @param o_actions           Cursor with available actions    
    * @param o_error             Error message
    *
    * @return                    TRUE if sucess, FALSE otherwise
    *                        
    * @author                    Elisabete Bugalho
    * @version                   1.0
    * @since                     2011/02/16
    **********************************************************************************************/
    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_pat_trial  IN table_number,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if theres is any schedule for a trial  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_pat_trial              list of patien trials
    * @param i_flg_status             status os trials (H / D / F)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/24
    **********************************************************************************************/

    FUNCTION check_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_pat_trial  IN table_number,
        i_flg_status IN pat_trial.flg_status%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_buttons    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Cancel internal trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/06
    **********************************************************************************************/
    FUNCTION discontinue_internal_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
END pk_trials_ux;
/
