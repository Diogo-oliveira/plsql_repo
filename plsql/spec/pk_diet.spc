/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_diet IS

    -- Author  : RITA.LOPES
    -- Created : 3/30/2009 2:28:30 PM
    -- Purpose : 
    FUNCTION get_menu_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_state      IN action.from_state%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_menu       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the type of food and the food for building a diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet_type          Id of type of diet 
    * @param i_id_diet_parent        id of type of food (parent) for getting food
    * @param o_diet                  Cursor with the food
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/01
    **********************************************************************************************/
    FUNCTION get_diet_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diet_type   IN diet_type.id_diet_type%TYPE,
        i_id_diet_parent IN diet.id_diet%TYPE,
        o_diet           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the diet for the episode
    *
    * @param i_lang                  Language ID
    * @param i_episode               ID Episode
    * @param i_type                  Type of information (T - Type of Diet, N - Name of diet) 
    
    * @param o_error                 Error message
    *
    * @return                        A String with active diets
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/07
    **********************************************************************************************/

    FUNCTION get_active_diet
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_id_epis_diet IN epis_diet_req.id_epis_diet_req%TYPE,
        i_start_date   IN VARCHAR2,
        i_end_date     IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION create_epis_diet
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'Y',
        i_resume_notes       IN epis_diet_req.resume_notes%TYPE DEFAULT NULL,
        i_flg_status_default IN epis_diet_req.flg_status%TYPE DEFAULT 'R',
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates one predefined diet for the professional
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_desc_diet             Description of diet
    * @param i_food_plan             Food plan 
    * @param i_flg_SHARE             Flag that indicates if professional want's to share is diet(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param o_id_DIET_PROF          ID of predefined diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/02
    **********************************************************************************************/
    FUNCTION create_diet_pref
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_id_diet_type        IN diet_type.id_diet_type%TYPE,
        i_desc_diet           IN diet_prof_instit.desc_diet%TYPE,
        i_food_plan           IN diet_prof_instit.food_plan%TYPE,
        i_flg_help            IN diet_prof_instit.flg_help%TYPE,
        i_flg_institution     IN diet_prof_instit.flg_institution%TYPE,
        i_flg_share           IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_notes               IN diet_prof_instit.notes%TYPE,
        i_id_diet_schedule    IN table_number,
        i_id_diet             IN table_number,
        i_quantity            IN table_number,
        i_id_unit             IN table_number,
        i_notes_diet          IN table_varchar,
        i_dt_hour             IN table_varchar,
        o_id_diet_prof        OUT diet_prof_instit.id_diet_prof_instit%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_diet               ID diet (For pre-defined diet tools menu)
    *
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/

    FUNCTION get_diet_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_diet       IN NUMBER,
        o_diet_register OUT NOCOPY pk_types.cursor_type,
        o_diet          OUT NOCOPY pk_types.cursor_type,
        o_diet_food     OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_diet               ID diet (For pre-defined diet tools menu)
    *
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/

    FUNCTION get_diet_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_flg_scope       IN VARCHAR2,
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_cancelled       IN VARCHAR2,
        i_crit_type       IN VARCHAR2,
        i_flg_report      IN VARCHAR2,
        i_current_episode IN episode.id_episode%TYPE,
        i_id_diet         IN NUMBER,
        i_flg_epis_type   IN VARCHAR2,
        o_diet_register   OUT pk_types.cursor_type,
        o_diet            OUT pk_types.cursor_type,
        o_diet_food       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_diet               ID diet (For pre-defined diet tools menu)
    * @param i_flg_type              Type of summary - H History, E - Episode
    *
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/

    FUNCTION get_diet_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_diet       IN NUMBER,
        i_flg_type      IN VARCHAR2 DEFAULT 'H',
        o_diet_register OUT pk_types.cursor_type,
        o_diet          OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param I_LANG                  Language ID
    * @param I_PROF                  Professional's details    
    * @param I_SCOPE                 Scope ID
    *                                    E-Episode ID
    *                                    V-Visit ID
    *                                    P-Patient ID
    * @param I_FLG_SCOPE             Scope type
    *                                    E-Episode
    *                                    V-Visit
    *                                    P-Patient
    * @param I_START_DATE            Start date for temporal filtering
    * @param I_END_DATE              End date for temporal filtering
    * @param I_CANCELLED             Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param I_CRIT_TYPE             Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...) 
    * @param I_FLG_REPORT            Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param I_CURRENT_EPISODE       Current Episode Identifier
    * @param I_ID_DIET               ID diet (For pre-defined diet tools menu)
    * @param I_FLG_TYPE              Type of summary - H History, E - Episode
    * @param I_FLG_EPIS_TYPE         If INP or EDIS Episode receives 'Y' otherwise 'N'
    *
    * @param O_DIET_REGISTER         Cursor with the name of diet and the register
    * @param O_DIET                  Cursor with the description of diet 
    * @param O_DIET_FOOD             Cursor with de detail of diet
    * @param O_ERROR                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/
    FUNCTION get_diet_summary_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_flg_scope       IN VARCHAR2,
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_cancelled       IN VARCHAR2,
        i_crit_type       IN VARCHAR2,
        i_flg_report      IN VARCHAR2,
        i_current_episode IN episode.id_episode%TYPE,
        i_id_diet         IN NUMBER,
        i_flg_type        IN VARCHAR2 DEFAULT 'H',
        i_flg_epis_type   IN VARCHAR2,
        o_diet_register   OUT pk_types.cursor_type,
        o_diet            OUT pk_types.cursor_type,
        o_diet_food       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient (from tools this is null)
    * @param i_episode               ID Episode
    * @param i_id_diet               ID DIET
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/06
    **********************************************************************************************/

    FUNCTION get_diet_summary_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        o_diet_register OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the scheduled hour of meals in the institution
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param o_schedule              Cursor with the meal hour
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/07
    **********************************************************************************************/
    FUNCTION get_schedule_default_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_schedule OUT pk_types.cursor_type,
        o_error    OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be canceled
    * @param i_notes                 Cancel Notes 
    * @param i_reason                Reason
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/08
    **********************************************************************************************/
    FUNCTION cancel_diet
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_diet     IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes       IN epis_diet_req.notes_cancel%TYPE,
        i_reason      IN epis_diet_req.id_cancel_reason%TYPE,
        i_auto_cancel IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_diet_internal
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_diet IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes   IN epis_diet_req.notes_cancel%TYPE,
        i_reason  IN epis_diet_req.id_cancel_reason%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list of pre-defined diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type                  Type od pre-defined diets(P - Professional/I-Institution)
    
    * @param o_diet                  Cursor with the description of diet and the register
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/08
    **********************************************************************************************/
    FUNCTION get_diet_prof_choice
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_diet  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel one pre-defined diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet               id of diet
    * @param O_FLG_SHOW              Y - existe msg para mostrar; N - ?iste
    * @param O_MSG                   mensagem no caso de a dieta estar activa para outros profissionais
    * @param O_MSG_TITLE             - T?lo da msg a mostrar ao utilizador, 
    * @param O_BUTTON - Bot?a mostrar: N - n? R - lido, C - confirmado
                            Tb pode mostrar combina?s destes, qd ?/ mostrar
                          + do q 1 bot?   
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/09
    **********************************************************************************************/
    FUNCTION cancel_diet_pref
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_diet   IN diet_prof_instit.id_diet_prof_instit%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the information of a determined diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type_diet             Type of diet (1 - Institucionalizada, 2 - Personalizada, 3 - Pre-definida)
    * @param i_id_diet               ID DIET
    
    * @param o_diet                  Cursor with the description of diet and the register
    * @param o_diet_schedule         Cursor with schedule of diet.
    * @param o_diet_food             Cursor with de detail of diet.
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/09
    **********************************************************************************************/

    FUNCTION get_diet
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_diet     IN diet_type.id_diet_type%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_diet       IN NUMBER,
        o_diet          OUT pk_types.cursor_type,
        o_diet_schedule OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_food_energy
    (
        i_quantity         IN NUMBER,
        i_quantity_default IN NUMBER,
        i_energy           IN NUMBER
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Creates one diet for the patient (with transaction control)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_predefined    id of predefined diet 
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_commit                commits or not the db transaction in the end
    * @param i_flg_institution       flg that indicates if it is available out of the institution
    * @param i_flg_share             flg that indicates if it is shared with other users
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/01
    **********************************************************************************************/
    FUNCTION create_diet
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_commit             IN VARCHAR2,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share          IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_flg_status_default IN epis_diet_req.flg_status%TYPE DEFAULT 'R',
        i_flg_order_set      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_force          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_warning        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * creates one diet for the patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_predefined    id of predefined diet 
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       flg that indicates if it is available out of the institution
    * @param i_flg_share             flg that indicates if it is shared with other users
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2009/07/23
    **********************************************************************************************/
    FUNCTION create_diet
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share          IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_flg_order_set      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_force          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_warning        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set's the list of preferred diet of the professional
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet               list of diet's
    * @param i_selected              list of status diet
    
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/13
    **********************************************************************************************/
    FUNCTION set_diet_preference
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_diet  IN table_number,
        i_selected IN table_varchar,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list of preferenced diets of professional
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param o_diet                  Cursor with the lists os prefered diets
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/15
    **********************************************************************************************/
    FUNCTION get_diet_prof_pref
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_diet  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set's the status of actives diets when discharge
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_visit                 ID Visit
    *
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/21
    **********************************************************************************************/

    FUNCTION set_diet_interrupt
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_visit IN episode.id_visit%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the diet for the episode
    *
    * @param i_lang                  Language ID
    * @param i_episode               ID Episode
    * @param i_type                  Type of information (T - Type of Diet, N - Name of diet) 
    
    *
    * @return                        A String with active diets
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/11
    **********************************************************************************************/
    FUNCTION get_active_diet
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_diet_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof profissional,
        i_diet IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * returns the status of a diet (overload created for order sets feature)
    *
    * @param i_lang                  language id
    * @param i_prof                  professional's details 
    * @param i_diet                  id of the diet 
    * @param o_status_string         diet flg status (pre-processed)
    * @param o_flag_canceled         indicates if it is canceled
    * @param o_flag_finished         indicates if it is finished
    * @param o_error                 error structure    
    *
    * @return                        boolean with return status
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2009/07/22
    **********************************************************************************************/
    FUNCTION get_diet_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diet          IN epis_diet_req.id_epis_diet_req%TYPE,
        o_status_string OUT VARCHAR2,
        o_flag_canceled OUT VARCHAR2,
        o_flag_finished OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * returns the status of a diet (overload created for order sets feature)
    *
    * @param i_lang                  language id
    * @param i_prof                  professional's details 
    * @param i_diet                  id of the diet 
    * @param o_status_string         diet flg status (pre-processed)
    * @param o_flag_canceled         indicates if it is canceled
    * @param o_flag_finished         indicates if it is finished
    * @param o_error                 error structure    
    *
    * @return                        boolean with return status
    *                        
    * @author                        Rita Lopes
    * @version                       1.0
    * @since                         2011/11/08
    **********************************************************************************************/
    FUNCTION get_diet_status_internal
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diet IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Suspend a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be suspended
    * @param i_notes                 Suspend Notes 
    * @param i_reason                ID Reason for suspend
    * @param i_dt_initial            Initial date for suspend
    * @param i_dt_end                End date for suspend
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/

    FUNCTION suspend_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_reason         IN epis_diet_req.id_cancel_reason%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Suspend a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be suspended
    * @param i_notes                 Suspend Notes 
    * @param i_reason                ID Reason for suspend
    * @param i_dt_initial            Initial date for suspend
    * @param i_dt_end                End date for suspend
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION suspend_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_reason         IN epis_diet_req.id_cancel_reason%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_force_cancel   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_commit         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Resume a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_episode               ID EPISODE
    * @param i_id_diet               ID Diet to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION resume_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_commit         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Resume a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_episode               ID EPISODE
    * @param i_id_diet               ID Diet to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION resume_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the unit for suspend duration 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param o_duration_units        cursor with the units
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/21
    **********************************************************************************************/

    FUNCTION get_suspend_unit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_duration_units OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets a flag that indicates the questions in that are visible in the diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Id Type diet
    * @param i_Episode               ID episode
    * @param o_flg_visible           F ? First (Help) S ? Second (Institution), B ? Both; N - None 
    * @param o_flg_mandatory         Indicates if fields are mandatory
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/21
    **********************************************************************************************/
    FUNCTION get_type_episode_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diet_type     IN diet_type.id_diet_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_flg_visible   OUT VARCHAR2,
        o_flg_mandatory OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION migracao RETURN BOOLEAN;

    /**********************************************************************************************
    * check if diet can be executed or not (order sets feature)
    *
    * @param i_lang                  language id
    * @param i_prof                  professional details
    * @param i_diet                  id of diet to be checked
    * @param o_flg_conflict          conflict status 
    * @param o_error                 error message
    *
    * @return                        true on success, false otherwise
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2009/07/23
    **********************************************************************************************/
    FUNCTION check_diet_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_diet_type    IN diet_type.id_diet_type%TYPE,
        i_diet_ref     IN NUMBER,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list of active diets for kitchen
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_department         ID department
    * @param i_id_dep_serv           ID of department service
    *
    * @param o_diet                  Cursor with all active diets 
    * @param o_diet_totals           Cursor with the totals of diets
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_active_diet_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN dept.id_dept%TYPE,
        i_id_dep_serv   IN department.id_department%TYPE,
        o_diet          OUT pk_types.cursor_type,
        o_diet_totals   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the last active diet of a episode
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @param o_diet                  Cursor with the last active diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/09/01
    **********************************************************************************************/
    FUNCTION get_last_active_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diet       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns 1 if is an nutritionist episode, 0 other else
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @return                        True or False
    *                        
    * @author                        Rita Lopes
    * @version                       2.5.0.6
    * @since                         2009/09/22
    **********************************************************************************************/
    FUNCTION get_nutritionist_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_episode    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_processed_diet_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        profissional,
        i_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_status_type IN VARCHAR DEFAULT 'D'
    ) RETURN VARCHAR2;

    -------------------------------------  CPOE  -------------------------------------------------
    /**********************************************************************************************
    * CPOE - Computerized physician order entry
    * Retrieves the diets list to be shown in the main CPOE grid 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param i_episode                episode id
    * @param i_task_request           task id to be returned
    * @param i_filter_tstz            timestamp filter 
    * @param i_filter_status          status filter  
    * @param o_task_list              array with diets list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2009/10/27
    **********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_task_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Build status string for diet requests.
    * Used internally, and for EA logic only.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_flg_status     diet request status
    * @param i_dt_inicial     diet start date
    * @param i_sys_date       system date
    * @param o_status_str     string
    * @param o_status_msg     message code
    * @param o_status_icon    icon
    * @param o_status_flg     flag
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.2
    * @since                  2012/04/19
    */
    PROCEDURE build_status_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN epis_diet_req.flg_status%TYPE,
        i_dt_inicial  IN epis_diet_req.dt_inicial%TYPE,
        i_sys_date    IN epis_diet_req.dt_inicial%TYPE,
        o_status_str  OUT sys_domain.desc_val%TYPE,
        o_status_msg  OUT sys_domain.code_domain%TYPE,
        o_status_icon OUT sys_domain.img_name%TYPE,
        o_status_flg  OUT sys_domain.val%TYPE
    );

    FUNCTION get_diet_status_str
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN epis_diet_req.flg_status%TYPE,
        i_dt_inicial IN epis_diet_req.dt_inicial%TYPE,
        i_dt_end     IN epis_diet_req.dt_end%TYPE,
        i_sys_date   IN epis_diet_req.dt_inicial%TYPE
    ) RETURN VARCHAR;

    /******************************************************************************************** 
    * Synchronize requested task with cpoe processes  
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_task_type               cpoe task type id 
    * @param       i_task_request            task request id (also used for drafts)
    * @param       i_task_request_old        task request id for previous diet state, when applicable
    * @param       i_dt_task                 Date task sync
    * @param       o_error                   error message 
    * 
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2009/11/16    
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN cpoe_task_type.id_task_type%TYPE,
        i_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_task_request_old IN cpoe_process_task.id_task_request%TYPE DEFAULT NULL,
        i_dt_task          IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates one diet for the patient, in draf state
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       Flg institution
    * @param i_resume_notes          Resume notes
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16
    **********************************************************************************************/
    FUNCTION create_draft
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'Y',
        i_resume_notes       IN epis_diet_req.resume_notes%TYPE DEFAULT NULL,
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Deletes one diet for the patient, in draf state
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_draf                  List of draft deits to delete
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/13
    **********************************************************************************************/
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Get diets parameters needed to fill edit screen  
    * 
    * @param       i_lang                  Preferred language id for this professional 
    * @param       i_prof                  Professional id structure
    * @param       i_type_diet             Type of diet (1 - Institucionalizada, 2 - Personalizada, 3 - Pre-definida)
    * @param       i_id_diet               ID DIET
    *
    * @param       o_diet                  Cursor with the description of diet and the register
    * @param       o_diet_schedule         Cursor with schedule of diet.
    * @param       o_diet_food             Cursor with de detail of diet.
    * @param       o_error                 Error message
    *         
    * @return      boolean                 True on success, otherwise false     
    *
    * @author                              Orlando Antunes
    * @version                             2.5
    * @since                               2009/11/13
    ********************************************************************************************/
    FUNCTION get_task_parameters
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_diet     IN diet_type.id_diet_type%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_diet       IN NUMBER,
        o_diet          OUT pk_types.cursor_type,
        o_diet_schedule OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Creates new records in diets tabels to keep the histoty of changes 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_diets                   current diet 
    * @param       i_flg_commit              transaction control 
    * @param       o_diet                    new diet
    * @param       o_error                   error message 
    * 
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction 
    *                                        {*} 'N' transaction control is done outside  
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/19
    **********************************************************************************************/
    FUNCTION create_diet_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_commit IN VARCHAR2 DEFAULT 'N',
        o_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Activates a set of draft Diets (task goes from draft to active workflow) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   array of selected draft diets  
    * @param       i_flg_commit              transaction control 
    * @param       o_created_tasks           array of created taksk requests     
    * @param       o_error                   error message 
    * 
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction 
    *                                        {*} 'N' transaction control is done outside  
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/13
    **********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Set the select diet in an expired state 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16    
    ********************************************************************************************/
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION expire_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Save the diet information, after editing
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       Flg institution
    * @param i_resume_notes          Resume notes
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16
    **********************************************************************************************/
    FUNCTION set_task_parameters
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share          IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Get available actions for a requested diet 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id (also used for drafts) 
    * @param       o_actions_list            list of available actions for the task request 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16    
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN epis_diet_req.id_epis_diet_req%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Copy diet to draft (from an existing active/inactive task) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id (current episode) 
    * @param       i_task_request            task request id (used for active/inactive tasks) 
    * @param       o_draft                   draft id 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16     
    ********************************************************************************************/
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN epis_diet_req.id_epis_diet_req%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_drafts_conflicts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators 
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_text                array of message texts 
    * @param       o_button                  array of buttons to show (it can have more than one button) 
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_button                  {*} 'N' NO button is displayed 
    *                                        {*} 'R' READ button is displayed    
    *                                        {*} 'C' CONFIRM button is displayed 
    *                                        {*} Example: 'NC' NO/CONFIRM buttons are displayed 
    *         
    * @return                        True on success, false otherwise
    *
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/17       
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN epis_diet_req.id_epis_diet_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diet_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diet_type   IN diet_type.id_diet_type%TYPE,
        i_diet_name   IN epis_diet_req.desc_diet%TYPE,
        i_flg_default IN VARCHAR2 DEFAULT 'Y',
        o_diet_descr  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diet_description
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_diet_type  IN diet_type.id_diet_type%TYPE,
        i_diet_name  IN epis_diet_req.desc_diet%TYPE,
        o_diet_descr OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diet_description_internal
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diet_type   IN diet_type.id_diet_type%TYPE,
        i_diet_name   IN epis_diet_req.desc_diet%TYPE,
        i_flg_default IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get patient's Dietitian Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_diet                  Patient diets
    * @ param o_diet_prof             Professional that prescribes the diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_evaluation_tools_prof Professional that creates the evaluation
    * @ param o_dietitian_report      Dietitian report
    * @ param o_dietitian_report_prof Professional that creates/edit the dietitian report
    * @ param o_dietitian_request     Dietitian request
    * @ param o_dietitian_request_prof Professional that creates/edit the dietitian request
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_dietitian_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_dietitian_request      OUT pk_types.cursor_type,
        o_dietitian_request_prof OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's EHR Dietitian Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_screen_labels         Labels
    * @ param o_episodes_det          List of patient's episodes
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_follow_up             Follow up notes list
    * @ param o_diet                  Patient diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_dietitian_report         dietitian report list
    * @ param o_dietitian_request        dietitian requests list
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_dietitian_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --request
        o_dietitian_request OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the dietitian summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_dietitian_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/
    **********************************************************************************************/
    FUNCTION get_dietitian_summary_labels
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        o_dietitian_summary_labels OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**********************************************************************************************
    * Get the diet description to be shown in the grids
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_epis_diet_req      Diet order identifier
    * @param i_diet_descr_format     Format of returned description
    * @param i_grouped               To be grouped the severals foods by meals for institutionalized diets
    *
    * @return                        Diet description
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/27
    **********************************************************************************************/
    FUNCTION get_diet_description_internal2
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diet_req  IN epis_diet_req.id_epis_diet_req%TYPE,
        i_diet_descr_format IN VARCHAR2 DEFAULT ('S'),
        i_grouped           IN VARCHAR2 DEFAULT ('N'),
        i_show_all_meal     IN VARCHAR2 DEFAULT ('Y'),
        i_flg_report        IN VARCHAR2 DEFAULT ('N')
    ) RETURN CLOB;

    /**********************************************************************************************
    * Gets the summary of the diets to be used in the generic summary page
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_flg_type              Diet type
    *
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_prof             Cursor with the prof details
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.6.0.1
    * @since                         2010/04/13
    **********************************************************************************************/
    FUNCTION get_diet_general_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN VARCHAR2 DEFAULT 'H',
        o_diet      OUT pk_types.cursor_type,
        o_diet_prof OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the episodes detail information 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_dietitian_episodes_det
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the evaluation tools template info for the summary screen.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_patient               Patient ID 
    * @ param i_episode               Episode ID
    * @ param i_is_ehr                Indicates if the information is to be displayed in the ehr summary screen
    * @ param o_evaluation_tools      Cursor evaluation tools history
    * @ param o_evaluation_tools_prof Cursor with prof history information for the 
    *                                 given evaluation tools
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION get_evaluation_tools_summary
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN table_number,
        i_is_ehr                IN VARCHAR2 DEFAULT ('N'),
        o_evaluation_tools      OUT pk_types.cursor_type,
        o_evaluation_tools_prof OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nutrition_assessments_sum
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN patient.id_patient%TYPE,
        i_episode                    IN table_number,
        i_is_ehr                     IN VARCHAR2 DEFAULT ('N'),
        o_nutrition_assessments      OUT pk_types.cursor_type,
        o_nutrition_assessments_prof OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_templates_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN table_number,
        i_id_summary_page    IN summary_page.id_summary_page%TYPE,
        i_summary_page_scope IN VARCHAR2 DEFAULT ('E'),
        i_is_ehr             IN VARCHAR2 DEFAULT ('N'),
        o_template           OUT pk_types.cursor_type,
        o_template_prof      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get nutritian episode origin type
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID
    *
    * @return                         A for appointments or R for requests
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/16
    **********************************************************************************************/
    FUNCTION get_nutritian_epis_origin_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get Nutritian requests list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_requests_prof  requests cursor prof
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Orlando Antnes
    * @version                 2.6.0.1
    * @since                  2010/04/16
    */
    FUNCTION get_dietitian_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get Nutritian requests list based on get_dietitian_requests_summary
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_requests_prof  requests cursor prof
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                 2.6.0.3
    * @since                  2010/12/06
    */
    FUNCTION get_dietitian_requests_sum_ehr
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get all active Diets available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return       tf_tasks_list            table of tr_tasks_list
    *
    * @author                                Orlando Antunes                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_diets
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /********************************************************************************************
    * Suspend a given patient's Diet
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 Diet id
    * @param       i_flg_reason              Reason for the WF suspension: 'D' (Death)
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Orlando Antunes
    * @version                               2.6.0.3
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION suspend_task_diet
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_reason    IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_force_cancel  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_msg_error     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Reactivate a given patient's Diet, in case of error. 
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Orlando Antunes
    * @version                               2.6.0.3
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION reactivate_task_diet
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Provide list of reactivatable Diets tasks for the patient death feature. 
    * All Diets must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_susp_action          SUSP_ACTION ID
    * @param       i_wfstatus                Pretended WF Status (from the SUSP_TASK table)
    *
    * @return      tf_tasks_list (table of tr_tasks_list)
    *
    * @author                                Orlando Antunes
    * @version                               2.6.0.3
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION get_wfstatus_tasks_diets
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;
    --

    /********************************************************************************************
    * Get Diets tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of diets requests
    * @param       o_task_status          cursor with all requested diets tasks status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.x
    * @since                              2010/09/16       
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**********************************************************************************************
    * Cancel all Diet draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.x
    * @since                              2010/09/16       
    ********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get active diets (this logic has been copy exactly the same present in inpatient's main grid)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return        varchar2
    *
    * @author                             Filipe Silva
    * @version                            2.6.1.2
    * @since                              2011/07/22      
    ********************************************************************************************/
    FUNCTION get_active_diet_description
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Delete institucionalized diet task for a order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_diet_prof_instit  Id Diet 
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/01
    **********************************************************************************************/
    FUNCTION cancel_diet_orderset
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_diet_prof_inst IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Duplicate diet for a new order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/01
    **********************************************************************************************/
    FUNCTION duplicate_diet_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_diet_prof_inst IN diet_prof_instit.id_diet_prof_instit%TYPE,
        o_id_diet_prof_inst OUT diet_prof_instit.id_diet_prof_instit%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Order sets
    * Retrieves the diets instructions to be shown in the order set functionality 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_task_request           task id
    * @param i_separator              the separator to be added between the results
    *
    * @return                         Instructions
    *                        
    * @author                         Ant? Neto
    * @version                        2.5.1.8
    * @since                          16-Sep-2011
    **********************************************************************************************/
    FUNCTION get_task_food_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_separator        IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Order sets
    * Retrieves the diets instructions to be shown in the order set functionality (backoffice) 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_task_request           task id
    * @param i_flg_process            Y - Frontofice; N - Backofice
    * @param o_task_list              Instructions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rita Lopes
    * @version                        1.0
    * @since                          2011/09/12
    **********************************************************************************************/
    FUNCTION get_task_instructions_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_flg_process      IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_task_instructions_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_flg_process      IN VARCHAR2,
        o_task_instr       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Order sets
    * Retrieves the diets instructions to be shown in the order set functionality (backoffice) 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_task_request           task id
    * @param i_flg_process            Y - Frontofice; N - Backofice
    * @param o_task_list              Instructions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rita Lopes
    * @version                        1.0
    * @since                          2011/09/12
    **********************************************************************************************/
    FUNCTION get_task_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_flg_process      IN VARCHAR2,
        o_task_instr       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set diet for a patient on order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/014
    **********************************************************************************************/
    FUNCTION set_pat_diet_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_task    IN diet_prof_instit.id_diet_prof_instit%TYPE,
        o_id_task    OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set diet requested for a patient on order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet_req           Id Diet req
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/14
    **********************************************************************************************/
    FUNCTION set_req_pat_diet_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_force   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_cancel_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns incial and end date
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Id Diet type
    * @param i_req                   Array de requisicoes
    * @param o_date_limits           Cursor de saida
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/21
    **********************************************************************************************/
    FUNCTION get_date_limits
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diet_type   IN epis_diet_req.id_diet_type%TYPE,
        i_id_req      IN table_number,
        o_date_limits OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get diet task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_edr          diet request identifier
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_edr                   IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;

    /**********************************************************************************************
    * Get active diets (this logic has been copy exactly the same present in inpatient's main grid)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return        varchar2
    *
    * @author                             Elisabete Bugalho
    * @version                            2.6.3.8.2
    * @since                              2013/10/02     
    ********************************************************************************************/
    FUNCTION get_active_diet_tooltip
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get diet title of institution diet
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_id_epis_diet_req  req det episode id
    * @param          o_error             error message
    *
    * @return        varchar2
    *
    * @author                             Jorge Silva
    * @version                            2.6.3.10
    * @since                              2014/01/27     
    ********************************************************************************************/
    FUNCTION get_diet_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get diet title and parent diet title 
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_id_diet           diet id
    *
    * @return        varchar2
    *
    * @author                             Jorge Silva
    * @version                            2.6.4.3.1
    * @since                              2015/02/12     
    ********************************************************************************************/
    FUNCTION get_diet_description_title
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_diet IN diet.id_diet%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of nutrition discharge for viewer checklist 
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
    FUNCTION get_vwr_diag_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of diets for viewer checklist 
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
    FUNCTION get_vwr_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of Nutrition discharge for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author    Elisabete Bugalho                 
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_nutri_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the active diets list of a episode
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @return                        Table with records t_tbl_diet
    *                        
    * @author                        Anna Kurowska
    * @version                       2.7.1
    * @since                         2017/04/03
    **********************************************************************************************/
    FUNCTION get_active_diets
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_diet;

    FUNCTION inactivate_diet_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_init_parameters
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

    ---------------------------------------------------------------------------------------------------
    g_found   BOOLEAN;
    g_sysdate DATE;
    g_exception EXCEPTION;
    g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_sysdate_char  VARCHAR2(50);
    g_error         VARCHAR2(2000);
    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(32);

    g_flg_available   CONSTANT VARCHAR2(1) := 'Y';
    g_epis_type_inpt  CONSTANT epis_type.id_epis_type%TYPE := 5;
    g_epis_type_edis  CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_type_outp  CONSTANT epis_type.id_epis_type%TYPE := 1;
    g_epis_type_care  CONSTANT epis_type.id_epis_type%TYPE := 8;
    g_epis_type_pp    CONSTANT epis_type.id_epis_type%TYPE := 11;
    g_epis_type_nutri CONSTANT epis_type.id_epis_type%TYPE := 18;

    -- Type of diet
    g_diet_type_inst CONSTANT diet_type.id_diet_type%TYPE := 1;
    g_diet_type_pers CONSTANT diet_type.id_diet_type%TYPE := 2;
    g_diet_type_defi CONSTANT diet_type.id_diet_type%TYPE := 3;
    --
    -- CPOE Type of diet
    g_cpoe_diet_type_inst CONSTANT diet_type.id_diet_type%TYPE := 36;
    g_cpoe_diet_type_pers CONSTANT diet_type.id_diet_type%TYPE := 37;
    g_cpoe_diet_type_defi CONSTANT diet_type.id_diet_type%TYPE := 38;

    -- status
    g_flg_diet_status_r CONSTANT epis_diet_req.flg_status%TYPE := 'R';
    g_flg_diet_status_i CONSTANT epis_diet_req.flg_status%TYPE := 'I';
    g_flg_diet_status_s CONSTANT epis_diet_req.flg_status%TYPE := 'S';
    g_flg_diet_status_c CONSTANT epis_diet_req.flg_status%TYPE := 'C';
    g_flg_diet_status_a CONSTANT epis_diet_req.flg_status%TYPE := 'A';
    g_flg_diet_status_e CONSTANT epis_diet_req.flg_status%TYPE := 'E';
    g_flg_diet_status_f CONSTANT epis_diet_req.flg_status%TYPE := 'F';
    g_flg_diet_status_h CONSTANT epis_diet_req.flg_status%TYPE := 'H';
    --CPOE
    --expired
    g_flg_diet_status_x CONSTANT epis_diet_req.flg_status%TYPE := 'X';
    --draft
    g_flg_diet_status_t CONSTANT epis_diet_req.flg_status%TYPE := 'T';
    --ORDER SET
    --TEMPORARIO
    g_flg_diet_status_o CONSTANT epis_diet_req.flg_status%TYPE := 'O';
    --CPOE grid states
    g_cpoe_diet_status_i CONSTANT epis_diet_req.flg_status%TYPE := 'I';
    g_cpoe_diet_status_a CONSTANT epis_diet_req.flg_status%TYPE := 'A';
    g_cpoe_diet_status_d CONSTANT epis_diet_req.flg_status%TYPE := 'D';
    g_cpoe_diet_status_c CONSTANT epis_diet_req.flg_status%TYPE := 'C';

    g_id_unit_kcal   CONSTANT unit_measure.id_unit_measure%TYPE := 10407;
    g_id_unit_days   CONSTANT unit_measure.id_unit_measure%TYPE := 1039;
    g_id_unit_months CONSTANT unit_measure.id_unit_measure%TYPE := 1127;
    g_id_unit_weeks  CONSTANT unit_measure.id_unit_measure%TYPE := 10375;

    g_yes_no sys_domain.code_domain%TYPE := 'YES_NO';

    g_diet_prof_p CONSTANT VARCHAR2(1) := 'P'; -- PROFESSIONAL DIET
    g_diet_prof_i CONSTANT VARCHAR2(1) := 'I'; -- INSTITUTION DIET

    g_flg_diet_t CONSTANT VARCHAR2(1) := 'T'; -- DIET PREDEFINED (TOOLS)
    g_flg_diet_n CONSTANT VARCHAR2(1) := 'N'; -- DIET EPISODE

    g_yes      CONSTANT VARCHAR2(1) := 'Y';
    g_no       CONSTANT VARCHAR2(1) := 'N';
    g_active   CONSTANT VARCHAR2(1) := 'A'; -- Predefined diet active
    g_inactive CONSTANT VARCHAR2(1) := 'I'; -- predefined diet inactive

    g_documentation    sys_config.value%TYPE;
    g_flg_complaint    VARCHAR2(1) := 'C';
    g_flg_cancel       pat_notes.flg_status%TYPE := 'C';
    g_flg_pe           VARCHAR2(2) := 'PE';
    g_flg_avail        VARCHAR2(1) := 'Y';
    g_flg_active       VARCHAR2(1) := 'A';
    g_pat_blood_active pat_blood_group.flg_status%TYPE := 'A';
    g_flg_def          VARCHAR2(1) := 'D';
    g_flg_temp         VARCHAR2(1) := 'T';
    g_flg_aval         epis_recomend.flg_type%TYPE := 'A';
    g_flg_plan         epis_recomend.flg_type%TYPE := 'L';

    g_flg_date_g CONSTANT VARCHAR2(1) := 'G';
    g_flg_date_l CONSTANT VARCHAR2(1) := 'L';
    -- discharge status
    g_flg_status_p VARCHAR2(1) := 'P';
    g_flg_status_a VARCHAR2(1) := 'A';

    -- episode status
    g_episode_status_m VARCHAR2(1) := 'M';
    g_episode_status_d VARCHAR2(1) := 'D';
    g_episode_status_a VARCHAR2(1) := 'A';
    -- VISIT STATUS 
    g_visit_status_i VARCHAR2(1) := 'I';

    --status type: D - diet, F - flag, C - CPOE type
    g_status_type_d CONSTANT VARCHAR2(1) := 'D';
    g_status_type_f CONSTANT VARCHAR2(1) := 'F';
    g_status_type_c CONSTANT VARCHAR2(1) := 'C';

    -- Hospital social worker profile template identifier
    g_hospital_nutr_pt CONSTANT profile_template.id_profile_template%TYPE := 70;
    -- Non Hospital social worker profile template identifier
    g_non_hospital_nutr_pt CONSTANT profile_template.id_profile_template%TYPE := 83;

    --templates information scope
    g_templates_info_scope_p CONSTANT VARCHAR2(1) := 'P';
    g_templates_info_scope_e CONSTANT VARCHAR2(1) := 'E';

    --diet description format
    g_diet_descr_format_s  CONSTANT VARCHAR2(1) := 'S'; --short
    g_diet_descr_format_m  CONSTANT VARCHAR2(1) := 'M'; --meals only
    g_diet_descr_format_l  CONSTANT VARCHAR2(1) := 'L'; --complete (long)
    g_diet_descr_format_sp CONSTANT VARCHAR2(2) := 'SP'; --single page

    -- order set task type
    g_odst_task_predef_diet CONSTANT order_set_task.id_task_type%TYPE := 22;
    g_odst_task_instit_diet CONSTANT order_set_task.id_task_type%TYPE := 53;

    --timeline for reports (ALERT-196786)
    g_diet_crit_type_all_a CONSTANT VARCHAR2(1 CHAR) := 'A'; --All

    --Title of diet INSTITUTION DIET
    g_diet_title CONSTANT diet_schedule.id_diet_schedule%TYPE := 7;
END pk_diet;
/
