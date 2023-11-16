/*-- Last Change Revision: $Rev: 2028842 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:16 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_paramedical_prof_core IS
    -- Author  : ORLANDO.ANTUNES
    -- Created : 20-01-2010 10:20:49
    -- Purpose : Core package for the paramedical professions development. This package contains generic functions used by the specific packages.

    -- Public type declarations
    --TYPE <TypeName> IS <Datatype>;

    -- Public constant declarations
    --<ConstantName> CONSTANT <Datatype> := <Value>;

    -- Public variable declarations
    --<VariableName> <Datatype>;

    TYPE table_message_array IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(200);

    FUNCTION format_str_header_w_colon
    (
        i_srt          IN VARCHAR2,
        i_is_report    IN VARCHAR2 DEFAULT 'N',
        i_is_mandatory IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        i_prof         IN profissional,
        o_desc_msg_arr OUT table_message_array
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the cancel information: Professional, date, reason and notes
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID 
    *
    * @param o_cancel_info            Cursor with all information regarding the cancel action
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_info_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE,
        o_cancel_info   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the signature of the professional that cancel a given record
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID 
    *
    * @return                         The professional signature on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_professional_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the date for a given cancel detail ID
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID 
    *
    * @return                         The string format of the cancel date on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_date
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the cancel reason for a given cancel detail ID
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID 
    *
    * @return                         The string format of the cancel date on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_reason_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the cancel notes for a given cancel detail ID
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID 
    *
    * @return                         The notes on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_notes_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get followup notes time spent unit subtype and default unit.
    *
    * @param i_prof           logged professional structure
    * @param o_time_units     time units
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_followup_time_units
    (
        i_prof       IN profissional,
        o_time_units OUT pk_types.cursor_type
    );

    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    * Only returns the registies done in the specified time period.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param i_start_date     Registry time period start date
    * @param i_end_date       Registry time period end date
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  22-Jun-2010
    */
    FUNCTION get_followup_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number,
        --i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_opinion_type   IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param i_opinion_type   Id opinion type 
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Teresa Coutinho
    * @version                 2.6.4.2
    * @since                  2014/09/19
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        i_opinion_type   IN opinion_type.id_opinion_type%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get an episode's follow up notes list, for reports layer usage.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up    follow up notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/02
    */
    FUNCTION get_followup_notes_rep
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2 DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get follow up notes data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up      follow up notes
    * @param o_time_units     time units
    * @param o_domain         option of end of follow up
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up    OUT pk_types.cursor_type,
        o_time_units   OUT pk_types.cursor_type,
        o_domain       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_notes          follow up notes
    * @param i_start_dt       start date
    * @param i_time_spent     time spent
    * @param i_unit_time      time spent unit measure
    * @param i_next_dt        next date
    * @param i_flg_end_followup flag end of followup  Y/N  
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION set_followup_notes
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
        i_flg_end_followup      IN sys_domain.val%TYPE DEFAULT NULL,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE DEFAULT NULL,
        i_dt_register           IN TIMESTAMP DEFAULT NULL,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'searchable'.
    * This function is prepared to return categories or plans hierarchy, where either 
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans             
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        i_inter_type       IN interv_plan_type.flg_type%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'more frequents'.
    * This function is prepared to return categories or plans hierarchy, where either 
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans             
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_freq_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        i_inter_type       IN interv_plan_type.flg_type%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate if a given intervention plan category has childs
    *
    * @ param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat        ID intervention plan category
    *
    * @return                         Y/N 
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION has_child_interv_plan_cat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_plan_cat IN interv_plan_category.id_interv_plan_category%TYPE,
        i_ipdcs_flg_type  IN interv_plan_dep_clin_serv.flg_type%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Validate if a given intervention plan has childs
    *
    * @ param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan            ID intervention plan
    *
    * @return                         Y/N 
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION has_child_interv_plan
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_plan    IN interv_plan.id_interv_plan%TYPE,
        i_ipdcs_flg_type IN interv_plan_dep_clin_serv.flg_type%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Retrieves the list Intervention plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan           List of categories/intervention plans             
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_list_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_plan_cat IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan     IN interv_plan.id_interv_plan%TYPE,
        i_ipdcs_flg_type  IN interv_plan_dep_clin_serv.flg_type%TYPE,
        o_interv_plan     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of intervention plans for a patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_patient               Patient ID 
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Jorge Silva
    * @version                         0.1
    * @since                           2014/01/20
    **********************************************************************************************/
    FUNCTION get_interv_ehr_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode for a list of episodes(i_id_epis).
    * The goal of this function is to return the data for the patient ehr
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               List of Episode IDs (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN table_number,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set one or more intervention plans for a given episode. This function can be used either to 
    * create new intervention plans or to edit existing ones. When editing intervention plans
    * the parameter i_id_epis_interv_plan must be not null.
    *
    * @param i_lang                   Preferred language ID for this professional     
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   List of IDs for the existing intervention plans to edit
    * @ param i_id_interv_plan        List of IDs for the intervention plans
    * @ param i_desc_other_interv_plan List of description of free text intervention plans
    * @ param i_dt_begin               List of begin dates for the intervention plans
    * @ param i_dt_end                 List of end dates for the intervention plans
    * @ param i_interv_plan_state      List of current states for the intervention plans
    * @ param i_notes                  List of notes for the intervention plans
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_interv_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        i_id_epis_interv_plan IN table_number,
        i_id_interv_plan      IN table_number,
        --
        i_desc_other_interv_plan IN table_varchar,
        i_dt_begin               IN table_varchar,
        i_dt_end                 IN table_varchar,
        i_interv_plan_state      IN table_varchar,
        i_notes                  IN table_varchar,
        i_tb_tb_diag             IN table_table_number,
        i_tb_tb_alert_diag       IN table_table_number,
        i_tb_tb_desc_diag        IN table_table_varchar,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Set one or more intervention plans for a given episode. This function can be used either to 
    * create new intervention plans or to edit existing ones. When editing intervention plans
    * the parameter i_id_epis_interv_plan must be not null.
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   List of IDs for the existing intervention plans to edit
    * @ param i_id_interv_plan        List of IDs for the intervention plans
    * @ param i_desc_other_interv_plan List of description of free text intervention plans
    * @ param i_dt_begin               List of begin dates for the intervention plans
    * @ param i_dt_end                 List of end dates for the intervention plans
    * @ param i_interv_plan_state      List of current states for the intervention plans
    * @ param i_notes                  List of notes for the intervention plans
    * @ param i_id_task_goal_det       List of task/goal detail identifier         
    * @ param i_id_task_goal           List of coded task/goal identifier   
    * @ param i_desc_task_goal         List of description of tasks/goals
    * @ param i_tb_tb_diag             table with id_diagnosis to associate
    * @ param i_tb_tb_desc_diag        table with diagnosis desctiptions to associate   
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_interv_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        i_id_epis_interv_plan IN table_number,
        i_id_interv_plan      IN table_number,
        --
        i_desc_other_interv_plan IN table_varchar,
        i_dt_begin               IN table_varchar,
        i_dt_end                 IN table_varchar,
        i_interv_plan_state      IN table_varchar,
        i_notes                  IN table_varchar,
        i_id_task_goal_det       IN table_number,
        i_id_task_goal           IN table_number,
        i_desc_task_goal         IN table_varchar,
        i_tb_tb_diag             IN table_table_number,
        i_tb_tb_desc_diag        IN table_table_varchar,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get domains values for the intervention plan states. 
    * If the parameter i_current_state is null then all available states will be returned, 
    * otherwise the function returns only the states that are different form the current one.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state
    *
    * @ param o_interv_plan_state     List with available states
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_state_domains
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_state     IN epis_interv_plan.flg_status%TYPE,
        o_interv_plan_state OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_id_epis_interv_plan   List of intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_epis  IN episode.id_episode%TYPE,
        i_dt_begin IN table_varchar,
        i_dt_end   IN table_varchar,
        i_state    IN table_varchar,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_id_interv_plan IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_state          IN table_varchar,
        i_notes          IN table_varchar,
        i_task_goal_det  IN table_number,
        i_task_goal      IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_id_interv_plan IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_state          IN table_varchar,
        i_notes          IN table_varchar,
        i_epis_diag      IN table_table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get labels and domains for the edit screen
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    
    * @ param o_interv_plan           State domains
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_state_domains OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN table_number,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set(change) a new intervention plan state 
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   Intervention plan ID
    * @ param i_new_interv_plan_state New state for the existing plan
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_new_interv_plan_state
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_id_epis_interv_plan   IN table_number,
        i_new_interv_plan_state IN epis_interv_plan.flg_status%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel Intervention plans.
    *
    * @param i_lang                    Preferred language ID for this professional
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_epis                 Episode ID
    * @ param i_id_epis_interv_plan     Intervention plan ID
    * @ param i_notes                   Cancel notes
    * @ param i_cancel_reason           Cancel reason
    *
    * @ param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                           Orlando Antunes
    * @version                          0.1
    * @since                            2010/02/25
    **********************************************************************************************/
    FUNCTION set_cancel_interv_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        i_notes               IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get Intervention plans available actiosn 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state     
    * @param o_interv_plan_actions    List of actions 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_current_state       IN table_varchar,
        o_interv_plan_actions OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get an episode's paramedical service reports list. Specify the report
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_report         report identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info 
    * @param o_report         reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION get_paramed_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_report         IN paramed_report.id_paramed_report%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_report_prof    OUT pk_types.cursor_type,
        o_report         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set paramedical service report.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_report         report identifier
    * @param i_episode        episode identifier
    * @param i_text           report text
    * @param o_report         created report identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION set_paramed_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_report  IN paramed_report.id_paramed_report%TYPE,
        i_episode IN paramed_report.id_episode%TYPE,
        i_text    IN paramed_report.text%TYPE,
        o_report  OUT paramed_report.id_paramed_report%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Retrieve the number of follow up notes of an episode.
    *
    * @param i_episode        episode identifier
    *
    * @return                 count of follow up notes.
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION get_encounter_count(i_episode IN episode.id_episode%TYPE) RETURN PLS_INTEGER;

    /*
    * Retrieve the number of follow up notes of an episode.
    *
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_time_spent     total time spent  
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    PROCEDURE time_spent
    (
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_time_spent OUT management_follow_up.time_spent%TYPE
    );

    /*
    * Get total time spent description.
    *
    * @param i_lang           language identifier
    * @param i_time_spent     total time spent
    * @param i_time_unit      unit measure identifier
    *
    * @return                 total time spent description
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION get_time_spent_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_time_spent IN management_follow_up.time_spent%TYPE,
        i_time_unit  IN management_follow_up.id_unit_time%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /*
    * Retrieve the number of follow up notes of an episode.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 total time spent description
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION get_time_spent
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Return a string with the intervention plan state
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_flg       Intervention plane state
    *
    * @return                         intervention plan state
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/03/17
    **********************************************************************************************/
    FUNCTION get_interv_plan_state_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_plan_flg IN epis_interv_plan.flg_status%TYPE
    ) RETURN sys_message.desc_message%TYPE;

    /********************************************************************************************
    * Get the intervention plan list for the summary screen.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/22
    **********************************************************************************************/
    FUNCTION get_interv_plan_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN table_number,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * Get the intervention plan list for the summary screen
    * (implementation of get_interv_plan_summary for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epis      list of episodes
    * @param o_interv_plan  social intervention plans
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    PROCEDURE get_interv_plan_summary_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis     IN table_number,
        o_interv_plan OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Create parametrization values for Intervention plans
    *
    * @author                           Orlando Antunes
    * @version                          0.1
    * @since                            2010/03/25
    **********************************************************************************************/
    PROCEDURE set_interv_plan_dep_clin_serv
    (
        i_id_interv_plan   IN interv_plan_dep_clin_serv.id_interv_plan%TYPE,
        i_id_dep_clin_serv IN interv_plan_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_professional  IN interv_plan_dep_clin_serv.id_professional%TYPE,
        i_id_software      IN interv_plan_dep_clin_serv.id_software%TYPE,
        i_id_institution   IN interv_plan_dep_clin_serv.id_institution%TYPE,
        i_flg_available    IN interv_plan_dep_clin_serv.flg_available%TYPE,
        i_flg_type         IN interv_plan_dep_clin_serv.flg_type%TYPE
    );

    /*
    * Get the last registered next encounter date. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_episode        episode identifier
    *
    * @return                 last registered next encounter date.
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_dt_next_enc(i_episode IN episode.id_episode%TYPE) RETURN management_follow_up.dt_next_encounter%TYPE;

    /*
    * Build status string for social assistance requests. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION get_req_status_str
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN opinion.flg_state%TYPE,
        i_dt_req IN opinion.dt_problem_tstz%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get data for the paramedical requests grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_show_all       'Y' to show all requests,
    *                         'N' to show a specific SW requests.
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.0.1
    * @since                  06-04-2010
    */
    FUNCTION get_paramedical_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all parametrizations for the paramedical professional
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_paramedical_param      List with all parametrizations  (name/value) 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_paramedical_param
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_paramedical_param OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the task/goal description based on i_id_task_goal_det
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_task_goal_det       Identifier of the task/goal defined within the scope
    *
    * @return                         description of the task/goal
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since                           2010/04/08
    **********************************************************************************************/
    FUNCTION get_task_goal_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_goal_det IN task_goal_det.id_task_goal_det%TYPE
        
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the task/goal id based on i_id_task_goal_det
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_task_goal_det       Identifier of the task/goal defined within the scope
    *
    * @return                         id of the task/goal
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since                           2010/04/08
    **********************************************************************************************/
    FUNCTION get_id_task_goal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_goal_det IN task_goal_det.id_task_goal_det%TYPE
        
    ) RETURN NUMBER;

    /********************************************************************************************
    * Get the task/goal for the specific intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_interv_plan         Intervention Plan array
    *
    * @param o_task_goal              list of task/goal defined for the specific intervention plan
    * @return                         TRUE/FALSE
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since 
    **********************************************************************************************/
    FUNCTION get_task_goal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_interv_plan IN table_number,
        o_task_goal      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get all parametrizations for the paramedical professional
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations  (name/value) 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Elisabete Bugalho
    * @version                         0.1
    * @since                          12-04-2010
    **********************************************************************************************/
    FUNCTION get_parametrizations
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_configs           IN table_varchar,
        o_paramedical_param OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * 
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_task_goal_det       Identifier of the task/goal detail from intervention plans
    * @param i_id_task_goal           Identifier of the coded task/goal
    * @param i_desc_task_goal         Free text description of the task/goal
    * @param o_id_task_goal_det       Identifier of the task/goal detail from intervention plans
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         João Almeida
    * @version                        0.1
    * @since                          2010/04/12
    **********************************************************************************************/
    FUNCTION set_task_goal_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_goal_det IN task_goal_det.id_task_goal_det%TYPE,
        i_id_task_goal     IN task_goal.id_task_goal%TYPE,
        i_desc_task_goal   IN task_goal_det.desc_task_goal%TYPE,
        o_id_task_goal_det OUT task_goal_det.id_task_goal_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the current environment is of an hospital, through the
    * logged professional's profile template.
    *
    * @param i_prof           logged professional structure
    *
    * @returns                'Y', if under an hospital environment, or 'N' otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/18
    * @change                 Elisabete Bugalho
    */
    FUNCTION check_hospital_profile(i_prof IN profissional) RETURN VARCHAR2;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date
    * @param i_disch_dest     discharge reason destiny identifier
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_disch_dest       IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************
    * Returns a string with the last update information to be 
    * used in the ehr summay.
    *
    * @ param i_lang               language identifier
    * @ param i_prof               professional information
    * @ param i_dt                 last update date
    * @ param i_id_prof_descr      professional ID that 
    * @ param i_dt_prof_descr      last update date
    * @ param i_epis_prof_descr    last update episode
    *
    * @param o_error          error
    *
    * @return                 string with the last update information
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    *************************************************************************/
    FUNCTION get_ehr_last_update_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_descr   IN professional.id_professional%TYPE,
        i_dt_prof_descr   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_epis_prof_descr IN episode.id_episode%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /*********************************************************************
    * Returns a string with the last update information to be 
    * used in the ehr summay.
    *
    * @ param i_lang               language identifier
    * @ param i_prof               professional information
    * @ param i_dt                 last update date
    * @ param i_id_prof_descr      professional ID that 
    * @ param i_dt_prof_descr      last update date
    * @ param i_epis_prof_descr    last update episode
    *
    * @param o_error          error
    *
    * @return                 string with the last update information
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    *
    * UPDATED: included the possibility to include different messages
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  23-Jun-2010
    *************************************************************************/
    FUNCTION get_ehr_last_update_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_descr   IN professional.id_professional%TYPE,
        i_dt_prof_descr   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_epis_prof_descr IN episode.id_episode%TYPE DEFAULT NULL,
        i_start_message   IN sys_message.desc_message%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Listar todos os diagnósticos do episódio para usar nas summary pages
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_prof_cat_type          categoty of professional
    *
    * @param o_diagnosis              Informação relativa aos diagnósticos
    * @param o_diagnosis_prof         Informação relativa ao profissional que efectuou o registo
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sérgio Santos
    * @version                        1.0 
    * @since                          23-Mar-2010
    **********************************************************************************************/
    FUNCTION get_summ_page_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN table_number,
        o_diagnosis      OUT pk_types.cursor_type,
        o_diagnosis_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the diagnoses list for the summary screen
    * (implementation of get_summ_page_diag for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_epis         list of episodes
    * @param o_diagnosis    diagnoses
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    PROCEDURE get_summ_page_diag_rep
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN table_number,
        o_diagnosis OUT pk_types.cursor_type
    );

    /*
    * Get list of follow up notes as string.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/21
    */
    FUNCTION get_followup_notes_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up    OUT NOCOPY CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get list of paramedical service reports as string.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_report         paramedical reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/21
    */
    FUNCTION get_paramed_report_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_report       OUT NOCOPY CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the Intervention plans list, concatenated as a String (CLOB)
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan_summ_str  String with all the intervention plans information
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_interv_plan_summary_str
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_opinion_type         IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_interv_plan_summ_str OUT NOCOPY CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the Diagnosis list, concatenated as a String (CLOB)
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_diagnosis_str         String with all the diagnosis information
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_summ_page_diag_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_opinion_type  IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_diagnosis_str OUT NOCOPY CLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Get a follow up notes record history.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_followup_notes_hist_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    );
    /*
    * Get the follow up notes list for the given array of episodes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/15
    */
    PROCEDURE get_followup_notes_list_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        i_report         IN VARCHAR2 DEFAULT 'N',
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    );
    /********************************************************************************************
    * Get the list of intervention plans for a patient episode for a list of episodes(i_id_epis).
    * The goal of this function is to return the data for the patient ehr
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               List of Episode IDs (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN table_number,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get the history of a given intervention plan (when i_epis_interv_plan is not null) or the 
    * history of all intervention plans (the current state) for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      ID Intervention plan
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_report
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN table_number,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Get an episode's paramedical service reports list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info 
    * @param o_report         reports
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_paramed_report_list_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        o_report_prof    OUT pk_types.cursor_type,
        o_report         OUT pk_types.cursor_type
    );
    /*
    * Get list of follow up notes as string.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/21
    */
    FUNCTION get_followup_notes_str_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up    OUT NOCOPY CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*************************************************
    * set_epis_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_episode
    * @param i_id_epis_interv_plan_hist              epis_interv_plan_hist identifier to associate
    * @param i_tb_diag                     table with diagnosis to insert
    * @param i_tb_desc_diag                     table with desc_diagnosis to insert
    * @param i_tb_epis_diag                     table with epis_diagnosis to insert
    *    
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION set_epis_interv_plan_diag_nc
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_interv_plan_hist IN epis_interv_plan_hist.id_epis_interv_plan_hist%TYPE,
        i_tb_diag                  IN table_number,
        i_tb_alert_diag            IN table_number,
        i_tb_desc_diag             IN table_varchar,
        i_tb_epis_diag             IN table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_episode                                  episode identifier
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_interv_plan_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diag       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_epis_interv_plan                   epis_interv_plan identifier
    * @param i_id_epis_interv_plan_hist              epis_interv_plan_hist identifier
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_epis_interv_plan_diag
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_interv_plan      IN epis_interv_plan.id_epis_interv_plan%TYPE,
        i_id_epis_interv_plan_hist IN epis_interv_plan_hist.id_epis_interv_plan_hist%TYPE
    ) RETURN table_number;
    /*************************************************
    * get_desc_epis_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_tb_epis_diag                           epis_diag table
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_desc_epis_diag
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tb_epis_diag IN table_number
    ) RETURN table_varchar;
    /*************************************************
    * get_id_diagnosis
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_tb_epis_diag                           epis_diag table
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_id_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tb_epis_diag IN table_number
    ) RETURN table_number;

    FUNCTION get_id_alert_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tb_epis_diag IN table_number
    ) RETURN table_number;
    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_tb_diag                               diag table
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_desc_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_tb_diag IN table_number
    ) RETURN table_varchar;

    /*************************************************
    * Check if button create is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_create_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_active OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*************************************************
    * Check a values of opinion table where followup is active in the opion_type of prof 
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    *
    *
    * @return                 a opinion table_function 
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_opinion_active_value
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_rec_opinion;

    /*************************************************
    * Get a id opinion type of professional
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    *
    *
    * @return                 opinion type identifier
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/19
    ***********************************************/
    FUNCTION get_id_opinion_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN opinion_type.id_opinion_type%TYPE;

    /*************************************************
    * Check if cancel and actions button is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    * @param i_flg_status                            management_follow_up status 
    * @param i_id_management_follow_up               management_follow_up identifier
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_actions_active
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_flg_status              IN VARCHAR2,
        i_id_management_follow_up IN NUMBER
    ) RETURN VARCHAR2;

    /*************************************************
    * Check if ok actions button is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_flg_opinion_state                     opinion state
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/21
    ***********************************************/
    FUNCTION get_ok_active
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_opinion_state IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_swf_by_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_type      IN category.code_category%TYPE,
        o_swf_file_name OUT swf_file.swf_file_name%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION parse_date
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_precision IN VARCHAR2,
        o_date      OUT management_follow_up.dt_next_encounter%TYPE,
        o_precision OUT management_follow_up.dt_next_enc_precision%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_partial_date_format
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN management_follow_up.dt_next_encounter%TYPE,
        i_precision IN management_follow_up.dt_next_enc_precision%TYPE
    ) RETURN VARCHAR2;

    FUNCTION time_spent_convert
    (
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_management_follow_up IN management_follow_up.id_management_follow_up%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_format_time_spent
    (
        i_lang         language.id_language%TYPE,
        i_val          management_follow_up.time_spent%TYPE,
        i_unit_measure unit_measure.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_followup_access
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_followup_access OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get current state of management follow-up for viewer checlist 
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
    FUNCTION get_followup_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get patient's Psychologist Summary. This includes information of:
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
    * @author                          Nuno Coelho
    * @version                         
    * @since                           04-12-2018
    **********************************************************************************************/
    FUNCTION get_psycho_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_psychologist_request      OUT pk_types.cursor_type,
        o_psychologist_request_prof OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the Psychologist summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_psychologist_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Nuno Coelho
    * @version                         
    * @since                           04-12-2018
    **********************************************************************************************/
    FUNCTION get_psycho_summary_labels
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        o_psychologist_summary_labels OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get Psychologist requests list.
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
    * @author                          Nuno Coelho
    * @version                         
    * @since                           04-12-2018
    */
    FUNCTION get_psycho_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get psychologist episode origin type
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID
    *
    * @return                         A for appointments or R for requests
    *
    * @author                          Nuno Coelho
    * @version                         
    * @since                           04-12-2018
    **********************************************************************************************/
    FUNCTION get_psycho_epis_origin_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = psychologist)
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
    /********************************************************************************************
    * Get the opinion type of professional
    *
    * @param i_lang            Preferred language ID for this professional
    * @param i_prof            Object (professional ID, institution ID, software ID)
    * @ param o_opinion_type   opinion type of professional
    *
    * @param o_error           Error Message
    *
    * @return                  true or false on success or error
    *
    * @author                  Nuno Coelho
    * @version                 2.7.4.7
    * @since                   2019/01/31
    **********************************************************************************************/
    FUNCTION get_opinion_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_opinion_type OUT opinion_type.id_opinion_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create a follow-up request and sets it as accepted. To be used in the All patient button when
    * the user presses OK in a valid episode (those without follow-up). Also used in the same button
    * inside the dietitian software.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             episode that will be followed
    * @param i_id_patient             episode patient
    * @param i_id_dcs                 episode dcs
    * @param i_id_prof                professional that is creating this follow up
    * @param i_id_opinion_type        1 = dietitian;  3 = soc worker 5 = psychologist
    * @param o_id_opinion             resulting follow up request id
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                         Telmo
    * @version                        2.6.1.2
    * @since                          21-09-2011
    **********************************************************************************************/
    FUNCTION set_accepted_follow_up
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof         IN opinion.id_prof_questioned%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        o_id_opinion      OUT opinion.id_opinion%TYPE,
        o_id_episode      OUT opinion.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode for a list of episodes(i_id_epis).
    * The goal of this function is to return the data for the patient 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               List of Episode IDs (Epis type = psychologist)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_psycho
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN table_number,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = psychologist)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_psycho
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_psycho
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_psycho
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN table_number,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_labels
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_summary_labels OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the task/goal for the specific intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_interv_plan         Intervention Plan
    *
    * @return                         task/goal defined for the specific intervention plan
    *
    * @author                          Nuno Coelho
    * @version                         0.1
    * @since
    **********************************************************************************************/
    FUNCTION get_task_goal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the message for start follow-up
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param o_message              The message to show
    * @param o_error                Error object
    *
    * @return  True if success, false otherwise
    *
    * @author   Ana Moita
    * @version  2.8
    * @since    2019/07/05
    */
    FUNCTION get_followup_start_message
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_message OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lst_id_opinion_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number;

    FUNCTION get_followup_notes_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION set_followup_notes
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_mng_followup         IN management_follow_up.id_management_follow_up%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_str          IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
         i_tbl_val_umea      IN table_table_varchar DEFAULT NULL,
        o_mng_followup         OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_followup_notes_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_followup_notes_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
 

    FUNCTION get_time_spent_send
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_val          IN management_follow_up.time_spent%TYPE,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;
     
    
    FUNCTION tf_followup_notes_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE
    ) RETURN t_tab_dd_block_data;      
    -- Public constant declarations
    c_open_bold_html  CONSTANT VARCHAR2(5) := '<b>';
    c_close_bold_html CONSTANT VARCHAR2(5) := '</b>';
    c_colon           CONSTANT VARCHAR2(1) := ':';
    c_whitespace      CONSTANT VARCHAR2(1) := ' ';
    c_mandatory_field CONSTANT VARCHAR2(1) := '*';
    c_dashes          CONSTANT VARCHAR2(2) := '--';

    g_req_status_pend CONSTANT VARCHAR2(1) := 'P';
    g_req_status_req  CONSTANT VARCHAR2(1) := 'R';
    g_found BOOLEAN;

    --origin type for paramedical episodes
    --request
    g_paramedical_epis_origin_r CONSTANT VARCHAR2(1) := 'R';
    --appointment request
    g_paramedical_epis_origin_c CONSTANT VARCHAR2(1) := 'C';
    --scheduled appointment
    g_paramedical_epis_origin_a CONSTANT VARCHAR2(1) := 'A';
    --other
    g_paramedical_epis_origin_o CONSTANT VARCHAR2(1) := 'O';

    --diagnosis
    g_epis_diag_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_STATUS';
    g_diag_type_p      CONSTANT VARCHAR2(1) := 'P';
    g_diag_type_d      CONSTANT VARCHAR2(1) := 'D';
    g_diag_type_b      CONSTANT VARCHAR2(1) := 'B';
    g_diag_type_x      CONSTANT VARCHAR2(1) := 'X';
    --
    g_ed_flg_status_ca CONSTANT epis_diagnosis.flg_status%TYPE := 'C';
    g_ed_flg_status_d  CONSTANT epis_diagnosis.flg_status%TYPE := 'D';
    g_ed_flg_status_co CONSTANT epis_diagnosis.flg_status%TYPE := 'F';
    g_ed_flg_status_r  CONSTANT epis_diagnosis.flg_status%TYPE := 'R';
    g_ed_flg_status_b  CONSTANT epis_diagnosis.flg_status%TYPE := 'B';

    g_exception EXCEPTION;
    g_eip_status_e CONSTANT epis_diagnosis.flg_status%TYPE := 'E';
    g_eip_status_a CONSTANT epis_diagnosis.flg_status%TYPE := 'A';

    TYPE t_rec_yes_or_not_domain IS RECORD(
        data  VARCHAR2(1000 CHAR),
        label VARCHAR2(1000 CHAR));

    g_date_precision_day   CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_date_precision_month CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_date_precision_year  CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_date_precision_hour  CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_date_unknown         CONSTANT VARCHAR2(1 CHAR) := 'U';

    g_id_unit_minutes CONSTANT unit_measure.id_unit_measure%TYPE := 10374;
    g_hour            CONSTANT PLS_INTEGER := 60;

    g_report_active CONSTANT paramed_report.flg_status%TYPE := 'A';
    g_report_edit   CONSTANT paramed_report.flg_status%TYPE := 'E';
    g_report_cancel CONSTANT paramed_report.flg_status%TYPE := 'C';

END pk_paramedical_prof_core;
/
