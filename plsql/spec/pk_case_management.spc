/*-- Last Change Revision: $Rev: 2028552 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_case_management IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 18-08-2009 8:33:49
    -- Purpose : CASE MANAGER
    /**********************************************************************************************
    * Grelha do case manager com os encontros 
    *      i_type= D -  encontros do dia
    *      i_type= A -  Todos os case managements
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type                  Tipo de pesquisa: D - os encontros do dia
    *                                A - Todos os case managements
    * @param i_prof_cat_type         Tipo de categoria do profissional, tal
    *                               como é retornada em PK_LOGIN.GET_PROF_PREF
    *
    * @param o_consult               Cursor with encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/18
    **********************************************************************************************/

    FUNCTION get_case_manager
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_consult       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Grelha dos pedidos de case manager por responder 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_opinion               Cursor with the opinion request
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/19
    **********************************************************************************************/

    FUNCTION get_pending_case_manager
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_opinion OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Function for urgency level  
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_opinion               Cursor with the opinion request
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_list_mng_level
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_level OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the summary of plan
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_encounter           ID encounter
    *
    * @param o_create                flag that indicates if button + is active(Y/N)
    * @param o_plan                  Cursor with the plan
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_mng_plan_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_encounter  IN epis_encounter.id_epis_encounter%TYPE,
        o_create        OUT VARCHAR2,
        o_plan_register OUT pk_types.cursor_type,
        o_plan          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the detail of a plan
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_plan                  Cursor with the plan
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/21
    **********************************************************************************************/

    FUNCTION get_mng_plan_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_management_plan IN management_plan.id_management_plan%TYPE,
        o_plan_register      OUT pk_types.cursor_type,
        o_plan               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Create/Edit management plan
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_encounter          ID encounter
    * @param i_id_mng_plan           ID Management plan (in case od edit)
    * @param i_level                 ID of level
    * @param i_admission             Admission notes
    * @param i_needs                 Immediate needs
    * @param i_goals                 Goals
    * @param i_plan                  Plan
    
    *
    * @param o_id_management_plan    ID of plan 
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/21
    **********************************************************************************************/

    FUNCTION create_mng_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_encounter       IN epis_encounter.id_epis_encounter%TYPE,
        i_id_mng_plan        IN management_plan.id_management_plan%TYPE,
        i_level              IN management_plan.id_management_level%TYPE,
        i_admission          IN management_plan.admission_notes%TYPE,
        i_needs              IN management_plan.immediate_needs%TYPE,
        i_goals              IN management_plan.goals%TYPE,
        i_plan               IN management_plan.plan%TYPE,
        o_id_management_plan OUT management_plan.id_management_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the information of a plan for edit
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_id_encounter          ID encounter
    * @param i_id_management_plan    ID management plan
    
    *
    * @param o_plan                  Cursor with the plan
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/21
    **********************************************************************************************/

    FUNCTION get_mng_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_id_encounter       IN epis_encounter.id_epis_encounter%TYPE,
        i_id_management_plan IN management_plan.id_management_plan%TYPE,
        o_plan               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a case management plan.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_epis_encounter        epis_encounter identifier
    * @param i_id_management_plan    case management plan identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_notes                 cancellation notes
    * @param o_id_management_plan    case management plan identifier
    * @param o_error                 error message
    *
    * @return                        false, if errors occur, or true otherwise
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/26
    **********************************************************************************************/
    FUNCTION cancel_mng_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_encounter     IN management_follow_up.id_epis_encounter%TYPE,
        i_id_management_plan IN management_plan.id_management_plan%TYPE,
        i_cancel_reason      IN management_plan.id_cancel_reason%TYPE,
        i_notes              IN management_plan.notes_cancel%TYPE,
        o_id_management_plan OUT management_plan.id_management_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
        * Gets the summary of FOLLOW-UP
        *
        * @param i_lang                  Language ID
        * @param i_prof                  Professional's details
        * @param i_patient               ID Patient
        * @param i_episode               ID Episode
        * @param i_id_encounter           ID encounter
        *
    * @param O_FOLLOW_UP_register                  Cursor with the  follow-up register   
     * @param O_FOLLOW_UP                  Cursor with the follow-up
        * @param o_error                 Error message
        *
        * @return                        True on success, false otherwise
        *                        
        * @author                        Elisabete Bugalho
        * @version                       2.5
        * @since                         2009/08/24
        **********************************************************************************************/

    FUNCTION get_mng_fu_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_encounter       IN epis_encounter.id_epis_encounter%TYPE,
        o_total_time         OUT VARCHAR2,
        o_follow_up_register OUT pk_types.cursor_type,
        o_follow_up          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves a case management follow up reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_sep                   reason separator
    *
    * @return                        case management follow up reasons
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION get_mng_fu_reason
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_sep               IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Retrieves a case management follow up data (prior to creation/edition).
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        episode encounter identifier
    * @param o_reasons               management followup reasons (id, desc, flg_select)
    * @param o_time_spent            time spent (id, desc, value)
    * @param o_notes                 management followup notes
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION get_mng_followup
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode           IN management_follow_up.id_episode%TYPE,
        i_epis_encounter    IN management_follow_up.id_epis_encounter%TYPE,
        o_reasons           OUT pk_types.cursor_type,
        o_time_spent        OUT pk_types.cursor_type,
        o_notes             OUT management_follow_up.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves a case management follow up history of operations.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param o_hist                  cursor
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION get_mng_followup_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_hist              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates or edits a case management follow up.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        episode encounter identifier
    * @param i_reasons               management followup reasons
    * @param i_time_spent            time spent
    * @param i_unit_time             time unit identifier
    * @param i_notes                 management followup notes
    * @param o_mng_plan_followup     management followup identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION set_mng_followup
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode           IN management_follow_up.id_episode%TYPE,
        i_epis_encounter    IN management_follow_up.id_epis_encounter%TYPE,
        i_reasons           IN table_number,
        i_time_spent        IN management_follow_up.time_spent%TYPE,
        i_unit_time         IN management_follow_up.id_unit_time%TYPE,
        i_notes             IN management_follow_up.notes%TYPE,
        o_mng_plan_followup OUT management_follow_up.id_management_follow_up%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates or edits a case management follow up.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        episode encounter identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_notes                 management followup cancellation notes
    * @param o_mng_plan_followup     management followup identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION cancel_mng_followup
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode           IN management_follow_up.id_episode%TYPE,
        i_epis_encounter    IN management_follow_up.id_epis_encounter%TYPE,
        i_cancel_reason     IN management_follow_up.id_cancel_reason%TYPE,
        i_notes             IN management_follow_up.notes_cancel%TYPE,
        o_mng_plan_followup OUT management_follow_up.id_management_follow_up%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves available options for the create button.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_options               cursor
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/28
    **********************************************************************************************/
    FUNCTION get_summary_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN management_plan.id_episode%TYPE,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves required data for the case management request's answer.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_opinion               opinion identifier
    * @param o_request               cursor (request data)
    * @param o_accept_list           cursor (acceptances list)
    * @param o_level_list            cursor (urgency levels list)
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/09/02
    **********************************************************************************************/
    FUNCTION get_req_answer
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_opinion     IN opinion.id_opinion%TYPE,
        o_request     OUT pk_types.cursor_type,
        o_accept_list OUT pk_types.cursor_type,
        o_level_list  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates or edits an encounter.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        episode encounter identifier
    * @param i_episode               episode identifier
    * @param i_patient               patient identifier
    * @param i_dt_begin              episode encounter start date
    * @param i_id_professional       episode encounter professional (CM)
    * @param i_flg_type              episode encounter type flag
    * @param i_notes                 episode encounter notes
    * @param i_reasons               episode encounter reasons
    * @param i_transaction_id        remote SCH 3.0 transaction id
    * @param o_epis_encounter        episode encounter identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/09/03
    **********************************************************************************************/
    FUNCTION set_encounter
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_encounter  IN epis_encounter.id_epis_encounter%TYPE,
        i_episode         IN epis_encounter.id_episode%TYPE,
        i_patient         IN epis_encounter.id_patient%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_id_professional IN professional.id_professional%TYPE,
        i_flg_type        IN epis_encounter.flg_type%TYPE,
        i_notes           IN epis_encounter.notes%TYPE,
        i_reasons         IN table_number,
        i_transaction_id  IN VARCHAR2,
        o_epis_encounter  OUT epis_encounter.id_epis_encounter%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        acceptance
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param i_transaction_id   remote SCH 3.0 transaction id
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/09/03
    ********************************************************************************************/
    FUNCTION set_cm_req_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the status of encounter
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_id_encounter          ID encounter
    *
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/09/7
    **********************************************************************************************/

    FUNCTION set_encounter_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel an encounter
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_epis_encounter        epis_encounter identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_notes                 cancellation notes
    * @param o_id_management_plan    epis encounter
    *
    * @return                        false, if errors occur, or true otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         09-09-2009
    **********************************************************************************************/
    FUNCTION cancel_encounter
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_epis_encounter    IN epis_encounter.id_epis_encounter%TYPE,
        i_cancel_reason     IN epis_encounter.id_cancel_reason%TYPE,
        i_notes             IN epis_encounter.notes_cancel%TYPE,
        o_id_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve options for creating/editing the end of an encounter.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 encounter discharge identifier
    * @param i_epis_encounter        encounter identifier
    * @param o_reasons               cursor
    * @param o_end_dt                encounter discharge date
    * @param o_notes                 encounter discharge notes
    * @param o_min_dt                encounter end date left bound
    * @param o_max_dt                encounter end date right bound
    * @param o_flg_warn              show "no encounter start date" warning (Y/N)
    * @param o_flg_type              flg_type of encounter
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_disch          IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_reasons        OUT pk_types.cursor_type,
        o_end_dt         OUT VARCHAR2,
        o_notes          OUT epis_encounter_disch.notes%TYPE,
        o_min_dt         OUT VARCHAR2,
        o_max_dt         OUT VARCHAR2,
        o_flg_warn       OUT VARCHAR2,
        o_flg_type       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve encounter discharges.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_discharges
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_disch          OUT pk_types.cursor_type,
        o_flg_status     OUT epis_encounter.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel an encounter discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param i_disch                 encounter discharge identifier
    * @param i_canc_reas             cancel reason identifier
    * @param i_canc_notes            cancel notes
    * @param o_epis_encounter        encounter identifier
    * @param o_disch                 encounter discharge identifier
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION cancel_enc_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_disch          IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_canc_reas      IN epis_encounter_disch.id_cancel_reason%TYPE,
        i_canc_notes     IN epis_encounter_disch.notes%TYPE,
        o_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_disch          OUT epis_encounter_disch.id_epis_encounter_disch%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set encounter discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_prof_cat              logged professional category
    * @param i_disch                 encounter discharge identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        encounter identifier
    * @param i_dt_end                discharge date
    * @param i_notes                 discharge notes_med
    * @param i_disch_reason          list of reasons of discharge
    * @param o_flg_show              warn
    * @param o_msg_title             warn
    * @param o_msg_text              warn
    * @param o_button                warn
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION set_enc_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat       IN category.flg_type%TYPE,
        i_disch          IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_dt_end         IN VARCHAR2,
        i_notes          IN discharge.notes_med%TYPE,
        i_disch_reason   IN table_number,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve encounter discharge reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param o_reasons               cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_disch_reasons
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_reasons        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve an encounter discharge history of operations.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_disch_hist
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_disch IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        o_hist  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list os encounters of a CM episode
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    *
    * @param o_follow_up             Cursor with all the encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_mng_follow_up_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_mng_followup OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list of encounter reasons
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_flg_type              FLG_TYPE (F - first encounter/ U - follow-up encounter)
    *
    * @param o_mng_followup          Cursor with all the encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         11-09-2009
    **********************************************************************************************/
    FUNCTION get_reasons_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_encounter.flg_type%TYPE,
        o_reasons  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves a case management follow up history of operations.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    *
    
    * @param o_follow_register       cursor with professional 
    * @param o_follow                cursor with the information of follow up 
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Elisabere Bugalho
    * @version                        2.5.0.7
    * @since                         30-09-20009
    **********************************************************************************************/
    FUNCTION get_mng_followup_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_register   OUT pk_types.cursor_type,
        o_follow            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves the time spent on CM Episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               ID Episode
    *
    
    * @return                        String with time spent
    *                        
    * @author                        Elisabere Bugalho
    * @version                       2.5.0.7
    * @since                         12-10-2009
    **********************************************************************************************/
    FUNCTION get_time_spent
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_encounter.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks the discharge
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_epis_encounter        encounter identifier
    * @param O_FLG_SHOW              Y - existe msg para mostrar; N - ñ existe
    * @param O_MSG                   mensagem no caso se ir dar alta ao episódio
    * @param O_MSG_TITLE             Título da msg a mostrar ao utilizador, 
    * @param O_BUTTON                Botões a mostrar: N - não, R - lido, C - confirmado; NC - Não e Confirmado
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Elisabete Bugalho
    * @version                       2.5.0.7  
    * @since                         14-10-2009
    ********************************************************************************************/
    FUNCTION check_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN epis_encounter.id_episode%TYPE,
        i_encounter    IN epis_encounter.id_epis_encounter%TYPE,
        i_disch_reason IN table_number,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the information of a concat
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_epis_encounter        ID Encounter
    * @param i_episode               ID Episode
    *
    * @param o_encounter             Cursor with the information of concat
    * @param o_reasons               Cursor with the reason of concat
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         20-10-2009
    **********************************************************************************************/

    FUNCTION get_encounter
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_episode        IN epis_encounter.id_episode%TYPE,
        o_encounter      OUT pk_types.cursor_type,
        o_reasons        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the information of a concat
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_epis_encounter        ID Encounter
    * @param i_episode               ID Episode
    *
    * @param o_encounter             Cursor with the information of concat
    * @param o_reasons               Cursor with the reason of concat
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         20-10-2009
    **********************************************************************************************/

    FUNCTION get_encounter_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_register       OUT pk_types.cursor_type,
        o_encounter      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves a case management encounter reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param i_sep                   reason separator
    *
    * @return                        case management encounter reasons
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/10/24
    **********************************************************************************************/
    FUNCTION get_encounter_reas
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_sep            IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Creates or edits an encounter. overload created so that flash code keeps working unaltered.
    * This function simply calls the original one.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        episode encounter identifier
    * @param i_episode               episode identifier
    * @param i_patient               patient identifier
    * @param i_dt_begin              episode encounter start date
    * @param i_id_professional       episode encounter professional (CM)
    * @param i_flg_type              episode encounter type flag
    * @param i_notes                 episode encounter notes
    * @param i_reasons               episode encounter reasons
    * @param o_epis_encounter        episode encounter identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Telmo Castro
    * @version                       2.6.0.1
    * @since                         27-04-2010
    **********************************************************************************************/
    FUNCTION set_encounter
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_encounter  IN epis_encounter.id_epis_encounter%TYPE,
        i_episode         IN epis_encounter.id_episode%TYPE,
        i_patient         IN epis_encounter.id_patient%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_id_professional IN professional.id_professional%TYPE,
        i_flg_type        IN epis_encounter.flg_type%TYPE,
        i_notes           IN epis_encounter.notes%TYPE,
        i_reasons         IN table_number,
        o_epis_encounter  OUT epis_encounter.id_epis_encounter%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request. overload created so that flash code keeps working unaltered.
    * This function simply calls the original one.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        acceptance
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Telmo Castro
    * @version                  2.6.0.1
    * @since                    27-04-2010
    ********************************************************************************************/
    FUNCTION set_cm_req_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve encounter discharges.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Elisabete Bugalho
    * @version                        2.5.0.7  
    * @since                         27-04-2010
    ********************************************************************************************/
    FUNCTION get_enc_disch_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_disch   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all professionals associated with a determined
     * category of an institution with the login professional selected
     *
     * @param  IN  Language ID
     * @param  IN  Category Flag
     * @param  IN  Institution ID
     * @param  OUT Professional cursor
     * @param  OUT Error structure
     *
     * @return BOOLEAN
     *
     * @since   30/09/2010
     * @version 2.6.0.4
     * @author  Rita Lopes
    */
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_category    IN category.flg_type%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get current state of case management plan for viewer checlist 
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
    FUNCTION get_mng_plan_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current end of encounter for viewer checlist 
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
    FUNCTION get_vwr_end_of_enc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE init_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_cm_request_reason
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE
    ) RETURN VARCHAR2;

    ----------------------------------------------------------------------
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char  VARCHAR2(50);
    g_error         VARCHAR2(4000);
    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);
    g_exception EXCEPTION;
    g_outdated  EXCEPTION;

    g_epis_type_cm CONSTANT NUMBER := 19; -- EPIS TYPE CASE MANAGER
    g_type_grid_d  CONSTANT VARCHAR2(1) := 'D'; -- ENCOUNTER DAY
    g_type_grid_a  CONSTANT VARCHAR2(1) := 'A'; -- ALL ENCOUNTER

    g_enc_flg_status_r CONSTANT epis_encounter.flg_status%TYPE := 'R'; --REQUESTED
    g_enc_flg_status_a CONSTANT epis_encounter.flg_status%TYPE := 'A'; --ACTIVE
    g_enc_flg_status_c CONSTANT epis_encounter.flg_status%TYPE := 'C'; --CANCELED
    g_enc_flg_status_i CONSTANT epis_encounter.flg_status%TYPE := 'I'; --INACTIVE
    g_enc_flg_status_o CONSTANT epis_encounter.flg_status%TYPE := 'O'; --OUTDATED

    g_no  CONSTANT VARCHAR2(1) := 'N'; --no
    g_yes CONSTANT VARCHAR2(1) := 'Y'; --yes

    g_active   CONSTANT VARCHAR2(1) := 'A';
    g_inactive CONSTANT VARCHAR2(1) := 'I';

    g_episode_flg_status_c CONSTANT VARCHAR2(1) := 'C'; --CANCELED
    g_episode_flg_status_i CONSTANT VARCHAR2(1) := 'I'; --INACTIVE

    g_domain_enc_flg_type    sys_domain.code_domain%TYPE := 'EPIS_ENCOUNTER.FLG_TYPE';
    g_domain_enc_flg_status  sys_domain.code_domain%TYPE := 'EPIS_ENCOUNTER.FLG_STATUS';
    g_domain_opn_flg_state   sys_domain.code_domain%TYPE := 'OPINION.FLG_STATE';
    g_domain_plan_flg_status sys_domain.code_domain%TYPE := 'MANAGEMENT_PLAN.FLG_STATUS';

    g_opn_flg_type_c  opinion.flg_type%TYPE := 'C';
    g_opn_flg_state_r opinion.flg_state%TYPE := 'R';
    g_opn_flg_state_f opinion.flg_state%TYPE := 'F';
    g_opn_flg_state_e opinion.flg_state%TYPE := 'E';

    g_opn_prof_flg_type_c opinion_prof.flg_type%TYPE := 'C';
    g_opn_prof_flg_type_a opinion_prof.flg_type%TYPE := 'A';

    g_mnp_flg_status_a management_plan.flg_status%TYPE := 'A';
    g_mnp_flg_status_c management_plan.flg_status%TYPE := 'C';
    g_mnp_flg_status_o management_plan.flg_status%TYPE := 'O';

    -- management_follow_up.flg_status
    g_mfu_status_active CONSTANT management_follow_up.flg_status%TYPE := 'A';
    g_mfu_status_outd   CONSTANT management_follow_up.flg_status%TYPE := 'O';
    g_mfu_status_canc   CONSTANT management_follow_up.flg_status%TYPE := 'C';

    -- FLAG OF STATUS OF ENCOUNTER ON GRID
    g_enc_grid_status_l CONSTANT VARCHAR2(1) := 'L';
    g_enc_grid_status_c CONSTANT VARCHAR2(1) := 'C';
    g_enc_grid_status_f CONSTANT VARCHAR2(1) := 'F';
    g_enc_grid_status_n CONSTANT VARCHAR2(1) := 'N';

    -- epis_encounter.flg_type
    g_enc_first    CONSTANT epis_encounter.flg_type%TYPE := 'F';
    g_enc_followup CONSTANT epis_encounter.flg_type%TYPE := 'U';

    -- epis_encounter_disch.flg_status
    g_disch_active CONSTANT epis_encounter_disch.flg_status%TYPE := 'A';
    g_disch_outd   CONSTANT epis_encounter_disch.flg_status%TYPE := 'O';
    g_disch_canc   CONSTANT epis_encounter_disch.flg_status%TYPE := 'C';

    g_config_epis_discharge sys_config.id_sys_config%TYPE := 'CASE_MANAGER_DISCHARGE';
    g_disch_type_f       CONSTANT discharge.flg_type%TYPE := 'F';
    g_disch_type_disch_c CONSTANT discharge.flg_type_disch%TYPE := 'C';

END pk_case_management;
/
