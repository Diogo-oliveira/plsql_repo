/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_trials IS

    -- Author  : ORLANDO.ANTUNES
    -- Created : 25-01-2011 09:37:09
    -- Purpose ~~: This package contains all logic to handle the trials functionality.

    g_temp VARCHAR2(1 CHAR);
    --Types
    SUBTYPE varchar_1 IS VARCHAR2(1 CHAR);
    SUBTYPE varchar_date IS VARCHAR2(20 CHAR);

    --Public constant declarations
    --trial domains
    g_trial_f_status_domain CONSTANT sys_domain.val%TYPE := 'TRIAL.FLG_STATUS';
    g_trial_f_type_domain   CONSTANT sys_domain.val%TYPE := 'TRIAL.FLG_TRIAL_TYPE';
    g_trial_action_internal CONSTANT action.internal_name%TYPE := 'INTERNAL';
    --pat_trial_domains
    g_pat_trial_f_status_domain CONSTANT sys_domain.val%TYPE := 'PAT_TRIAL.FLG_STATUS';
    g_follow_up_f_status_domain CONSTANT sys_domain.val%TYPE := 'PAT_TRIAL_FOLLOW_UP.FLG_STATUS';

    --trial status
    g_trial_f_status_a CONSTANT varchar_1 := 'A';
    g_trial_f_status_i CONSTANT varchar_1 := 'I';
    g_trial_f_status_r CONSTANT varchar_1 := 'R';
    g_trial_f_status_d CONSTANT varchar_1 := 'D';
    g_trial_f_status_f CONSTANT varchar_1 := 'F';
    g_trial_f_status_c CONSTANT varchar_1 := 'C';

    --pat_trial status
    g_pat_trial_f_status_a CONSTANT varchar_1 := 'A';
    g_pat_trial_f_status_c CONSTANT varchar_1 := 'C';
    g_pat_trial_f_status_f CONSTANT varchar_1 := 'F';
    g_pat_trial_f_status_d CONSTANT varchar_1 := 'D';
    g_pat_trial_f_status_r CONSTANT varchar_1 := 'R';
    g_pat_trial_f_status_h CONSTANT varchar_1 := 'H';
    g_pat_trial_f_status_e CONSTANT varchar_1 := 'E';

    --pat_trial_follow_up
    g_pat_trial_follow_status_a CONSTANT varchar_1 := 'A';
    g_pat_trial_follow_status_e CONSTANT varchar_1 := 'E';
    g_pat_trial_follow_status_c CONSTANT varchar_1 := 'C';
    --trial type
    --external
    g_trial_f_trial_type_e CONSTANT varchar_1 := 'E';
    --internal
    g_trial_f_trial_type_i CONSTANT varchar_1 := 'I';

    -- ACTION SUBJECT FOR PATIENT TRIALS
    g_pat_trial_action_i CONSTANT action.subject%TYPE := 'PATIENT_TRIAL_INTERNAL';
    g_pat_trial_action_e CONSTANT action.subject%TYPE := 'PATIENT_TRIAL_EXTERNAL';

    g_action_internal_i CONSTANT action.internal_name%TYPE := 'FOLLOWUP';
    g_action_internal_e CONSTANT action.internal_name%TYPE := 'EDIT';
    --current time
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    --generic exception
    g_exception EXCEPTION;

    --sys_config
    g_config_internal CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT_TRIAL_INTERNAL';
    g_config_external CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT_TRIAL_EXTERNAL';
    --

    g_category_doctor CONSTANT PLS_INTEGER := 1;

    g_semicolon CONSTANT VARCHAR2(2 CHAR) := '; ';
    g_space     CONSTANT VARCHAR2(1 CHAR) := ' ';

    --TRIALS SHORTCUT
    g_trial_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 10100;

    TYPE trial_type IS RECORD(
        name           VARCHAR2(4000 CHAR),
        code           VARCHAR2(100 CHAR),
        trial_type     VARCHAR2(1),
        dt_start       VARCHAR2(4000 CHAR),
        dt_end         VARCHAR2(4000 CHAR),
        responsibles   VARCHAR2(4000 CHAR),
        pharma_code    VARCHAR2(100 CHAR),
        pharma_name    VARCHAR2(4000 CHAR),
        flg_status     VARCHAR2(1 CHAR),
        create_time    VARCHAR2(4000 CHAR),
        trial_contact  VARCHAR2(4000 CHAR),
        status         VARCHAR2(4000 CHAR),
        notes          CLOB,
        registered     VARCHAR2(4000 CHAR),
        dt_record      VARCHAR2(4000 CHAR),
        dt_record_tstz TIMESTAMP WITH TIME ZONE,
        cancel_reason  VARCHAR2(4000 CHAR),
        cancel_notes   CLOB);

    TYPE trial_type_dif IS RECORD(
        name_b          VARCHAR2(4000 CHAR),
        name_a          VARCHAR2(4000 CHAR),
        code_b          VARCHAR2(4000 CHAR),
        responsibles_a  VARCHAR2(4000 CHAR),
        responsibles_b  VARCHAR2(4000 CHAR),
        code_a          VARCHAR2(4000 CHAR),
        status_b        VARCHAR2(4000 CHAR),
        status_a        VARCHAR2(4000 CHAR),
        flg_status_a    VARCHAR2(1 CHAR),
        dt_start_b      VARCHAR2(4000 CHAR),
        dt_start_a      VARCHAR2(4000 CHAR),
        dt_end_b        VARCHAR2(4000 CHAR),
        dt_end_a        VARCHAR2(4000 CHAR),
        trial_contact_b VARCHAR2(4000 CHAR),
        trial_contact_a VARCHAR2(4000 CHAR),
        pharma_name_b   VARCHAR2(4000 CHAR),
        pharma_name_a   VARCHAR2(4000 CHAR),
        pharma_code_b   VARCHAR2(4000 CHAR),
        pharma_code_a   VARCHAR2(4000 CHAR),
        notes_b         CLOB,
        notes_a         CLOB,
        registered      VARCHAR2(4000 CHAR),
        create_time     VARCHAR2(4000 CHAR),
        cancel_reason_b VARCHAR2(4000 CHAR),
        cancel_reason_a VARCHAR2(4000 CHAR),
        cancel_notes_b  CLOB,
        cancel_notes_a  CLOB);

    TYPE trial_type_dif_table IS TABLE OF trial_type_dif INDEX BY BINARY_INTEGER;

    TYPE followup_type IS RECORD(
        notes          CLOB,
        flg_status     VARCHAR2(1 CHAR),
        dt_record      VARCHAR2(4000 CHAR),
        status         VARCHAR2(4000 CHAR),
        registered     VARCHAR2(4000 CHAR),
        dt_record_tstz TIMESTAMP WITH TIME ZONE,
        cancel_reason  VARCHAR2(4000 CHAR),
        cancel_notes   CLOB);

    TYPE followup_type_diff IS RECORD(
        notes_b         CLOB,
        notes_a         CLOB,
        dt_record       VARCHAR2(4000 CHAR),
        status_b        VARCHAR2(4000 CHAR),
        status_a        VARCHAR2(4000 CHAR),
        cancel_reason_b VARCHAR2(4000 CHAR),
        cancel_reason_a VARCHAR2(4000 CHAR),
        cancel_notes_b  CLOB,
        cancel_notes_a  CLOB,
        registered      VARCHAR2(4000 CHAR));

    TYPE followup_type_dif_table IS TABLE OF followup_type_diff INDEX BY BINARY_INTEGER;

    /*    TYPE r_pat_trial IS RECORD(
    id_trial trial.id_trial%TYPE,
    code     trial.code%TYPE,
    name     trial.name%TYPE);*/

    --    TYPE l_r_pat_trial IS TABLE OF r_pat_trial INDEX BY BINARY_INTEGER;

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
    * Get the list of professionals responsible for a trial (list of IDs).
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    
    * @param o_trials_list            array with the list of 
    * @param o_error                  Error message
    *
    * @return                         List of professionals 
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_trial_resp_id_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_trial_id IN trial.id_trial%TYPE
    ) RETURN table_number;

    /**********************************************************************************************
    * Get the list of professionals responsible for a trial (list of professional names).
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    *
    * @param o_error                  Error message
    *
    * @return                         List of professionals 
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_trial_resp_name_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_trial_id IN trial.id_trial%TYPE
    ) RETURN table_varchar;

    /**********************************************************************************************
    * Get the trial's name.
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    * @param i_trial_id               ID Trial 
    * @param o_error                  Error message
    *
    * @return                         Name of the trial 
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_pat_trial_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN pat_trial.id_pat_trial%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Retrieves the information for a given trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param i_trial_type             Type of trial: I -internal, E - external
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
    FUNCTION get_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN trial.id_trial%TYPE,
        i_trial_type    IN trial.flg_trial_type%TYPE DEFAULT 'I',
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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
        i_id_trial      IN trial.id_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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
        o_id_trial_hist      OUT trial_hist.id_trial_hist%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a new trial (internal or external) or edit an existing one. 
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
    * @param i_trial_resp_ext         Free text list os professionals responsible for this trial
    * @param i_trial_resp_cont        Contact details for the professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param i_trial_type             Type of trial: I -internal, E - external
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION set_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_trial_resp_ext     IN trial.responsible%TYPE DEFAULT NULL,
        i_trial_resp_cont    IN trial.resp_contact_det%TYPE DEFAULT NULL,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_trial_type         IN trial.flg_trial_type%TYPE DEFAULT 'I',
        i_pharma_code        IN trial.pharma_code%TYPE DEFAULT NULL,
        i_pharma_name        IN trial.pharma_name%TYPE DEFAULT NULL,
        i_commit             IN VARCHAR2 DEFAULT 'Y',
        o_id_trial           OUT trial.id_trial%TYPE,
        o_id_trial_hist      OUT trial_hist.id_trial_hist%TYPE,
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
    * Create the internal trial history (for created or updated records).
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param o_id_trial_hist          ID of the created trial history record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION set_internal_trial_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        o_id_trial_hist OUT trial_hist.id_trial_hist%TYPE,
        o_error         OUT t_error_out
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
        i_trial_status IN trial.flg_status%TYPE DEFAULT 'A',
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
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
    FUNCTION inactivate_internal_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        i_flg_status    IN trial.flg_status%TYPE,
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
    * Returns the number of follow up notes for a patient 
    *
    * @param i_pat_trial              id patient trial
    *
    * @return                         the number of follow up notes 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_count_trial_follow_up(i_pat_trial IN pat_trial.id_pat_trial%TYPE) RETURN NUMBER;

    /**********************************************************************************************
    * Cancel patient trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_pat_trial           ID patient trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION cancel_patient_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN pat_trial.id_pat_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Create the PATIENT trial history (for created or updated records).
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_pat_trial           ID patienttrial
    * @param o_id_pat_trial_hist      ID of the created trial history record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION set_patient_trial_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_pat_trial      IN pat_trial.id_pat_trial%TYPE,
        o_id_pat_trial_hist OUT pat_trial_hist.id_pat_trial_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************
    * Returns if the prget_count_trial_follow_upofessional is responsible for trial
    *
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_trial               ID of trial
    *
    * @return                         Y - professional responsible; N - Professioanl not responsaible 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION check_prof_responsible
    (
        i_prof     IN profissional,
        i_id_trial IN trial.id_trial%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************
    * Get patient trial create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      ID patient
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
    * Get the list of professionals responsible for a trial (list of professional names) from history.
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    *
    * @param o_error                  Error message
    *
    * @return                         List of professionals 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/09
    **********************************************************************************************/
    FUNCTION get_trial_resp_name_hist_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_hist_id IN trial.id_trial%TYPE
    ) RETURN table_varchar;

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
    /**********************************************************************
    * Returns the number of trials i'am responsible
    *
    * @param i_pat_trial              id patient trial
    *
    * @return                         the number of follow up notes 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_count_trial_responsible(i_prof IN profissional) RETURN NUMBER;

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
    * Gets the detail of a patient trial for viewer and popup
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
    FUNCTION get_trials_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        i_type         IN VARCHAR2 DEFAULT 'V',
        o_trial        OUT pk_types.cursor_type,
        o_responsible  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************
    * Returns the number of patients on a trial in a determinated status
    *
    * @param i_id_trial              id trial
    *
    * @return                        the number of patient in that status 
    *                        
    * @author                        Elisabete Bugalho
    * @version                       1.0
    * @since                         2011/02/10
    **********************************************************************************************/
    FUNCTION get_count_trial_patients
    (
        i_id_trial IN trial.id_trial%TYPE,
        i_status   IN table_varchar
    ) RETURN NUMBER;

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

    /***********************************************************************************************
    * Concludethe patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param i_flg_status      status of patient trial    
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION set_pat_trial_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        i_flg_status   IN pat_trial.flg_status%TYPE,
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

    /**********************************************************************
    * Returns the number of trials i'am responsible and available for patient
    *
    * @param i_pat_trial              id patient trial
    *
    * @return                         the number of follow up notes 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_count_trial_resp_patient
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /***********************************************************************************************
    * Suspend or Descontinue patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param i_flg_status      status of patient trial   
    * @param i_cancel_reason     cancel reason
    * @param i_cancel_notes   cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/15
    **********************************************************************************************/
    FUNCTION set_pat_trial_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_flg_status    IN pat_trial.flg_status%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
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
    * Gets all patient trials (undergoing)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/16
    **********************************************************************************************/
    FUNCTION get_pat_trials_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_type        IN VARCHAR2 DEFAULT 'P',
        o_trial       OUT pk_types.cursor_type,
        o_responsible OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/16
    **********************************************************************************************/
    FUNCTION check_patient_on_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_pat_trial  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/16
    **********************************************************************************************/
    FUNCTION check_patient_trial_ehr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/24
    **********************************************************************************************/
    FUNCTION check_patient_trial(i_id_patient IN patient.id_patient%TYPE) RETURN VARCHAR2;

    /**********************************************************************************************
    * Retrieves the list of internal Trials undergoing  for a patient 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param o_trials                 array with the list of internal Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/18
    **********************************************************************************************/
    FUNCTION get_pat_trials_undergoing
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_trials     OUT t_coll_pat_trial,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if theres is any schedule for a trial  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_pat_trial              list of patien trials
    * @param i_flg_status             status os trials (H / D / F / R)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/23
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
    * Sets an shcedule/episode for a specific trial 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_id_episode             ID Episode
    * @param i_id_trial               ID trial
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/30
    **********************************************************************************************/

    FUNCTION set_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_trial   IN trial.id_trial%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Match the patient trial 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_id_patient_temp        ID Patient
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/28
    **********************************************************************************************/

    FUNCTION set_match_pat_trial
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_patient_temp IN patient.id_patient%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a list a schedule for a trial 
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
    * @since                          2011/03/18
    **********************************************************************************************/

    FUNCTION cancel_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_pat_trial  IN table_number,
        i_flg_status IN pat_trial.flg_status%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_short%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Delete all trials by episode 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             ID Episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2014/04/01
    **********************************************************************************************/
    FUNCTION delete_trials_by_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_trials;
/
