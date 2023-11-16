/*-- Last Change Revision: $Rev: 2055066 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2023-02-03 16:25:00 +0000 (sex, 03 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_in IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 27-07-2011 10:27:46
    -- Purpose : Handle PFH calls to medication

    r_presc      pk_rt_med_pfh.r_presc%ROWTYPE;
    r_presc_plan pk_rt_med_pfh.r_presc_plan%ROWTYPE;

    -- workflow types
    g_wf_institution CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_institution;
    g_wf_ambulatory  CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_ambulatory;
    g_wf_report      CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_report;
    g_wf_iv          CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_iv;
    g_wf_inst_pharm  CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_inst_pharm;

    --Drug origin identifier
    g_int_drug CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_int_drug; --'I'
    g_ext_drug CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_ext_drug; --'E'

    g_out_status CONSTANT VARCHAR2(30) := pk_rt_med_pfh.g_out_status;

    -- Sys_config
    g_prescription_type CONSTANT VARCHAR2(30) := pk_rt_med_pfh.g_prescription_type;

    --Presc Status
    g_presc_can CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_presc_can; --'C'

    -- pat_medication_list
    g_pat_med_list_del CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_pat_med_list_del; -- 'D'

    g_presc_take_sos CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_presc_take_sos;

    g_wfg_presc_med_active   CONSTANT table_number_id := pk_rt_med_pfh.g_wfg_presc_med_active;
    g_wfg_presc_med_inactive CONSTANT table_number_id := pk_rt_med_pfh.g_wfg_presc_med_inactive;
    g_tmp_presc_states       CONSTANT table_number := pk_rt_med_pfh.g_tmp_presc_states;

    g_flg_exec_curr_episode     CONSTANT r_presc.flg_execution%TYPE := pk_rt_med_pfh.g_flg_exec_curr_episode;
    g_flg_exec_next_episode     CONSTANT r_presc.flg_execution%TYPE := pk_rt_med_pfh.g_flg_exec_next_episode;
    g_flg_exec_before_next_epis CONSTANT r_presc.flg_execution%TYPE := pk_rt_med_pfh.g_flg_exec_before_next_epis;

    -- HM review constants
    g_hm_review_none            CONSTANT NUMBER(24) := pk_rt_med_pfh.g_hm_review_none;
    g_hm_review_cannot_review   CONSTANT NUMBER(24) := pk_rt_med_pfh.g_hm_review_cannot_review;
    g_hm_review_cannot_identify CONSTANT NUMBER(24) := pk_rt_med_pfh.g_hm_review_cannot_review;
    g_hm_review_dont_take       CONSTANT NUMBER(24) := pk_rt_med_pfh.g_hm_review_dont_take;
    g_hm_review_dont_take_relev CONSTANT NUMBER(24) := pk_rt_med_pfh.g_hm_review_dont_take_relev;

    --prescription_number_seq
    g_presc_number_seq_flg_type_r CONSTANT prescription_number_seq.flg_type%TYPE := 'R';

    g_home_care_icon CONSTANT VARCHAR2(30 CHAR) := pk_rt_med_pfh.g_home_care_icon;

    -- editor lookup
    el_duration_smaller_month_unit CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.el_duration_smaller_month_unit;

    /********************************************************************************************
    * process_presc_grid_task
    *
    *
    * @author                          Pedro Teixeira
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    PROCEDURE process_presc_grid_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*********************************************************************************************
    * This function will update the Grid Task for a certain episode
    *
    * @param i_lang               The ID of the user language
    * @param i_prof               The profissional array
    * @param i_id_episode         Episode Id
    *
    *
    * @author  Pedro Teixeira 
    * @since   2011/08/19
    **********************************************************************************************/
    PROCEDURE process_epis_grid_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN r_presc.id_epis_create%TYPE
    );

    /******************************************************************************************
    * This procedure returns the rank for given prescription
    *
    * @param i_lang          The ID of the user language
    * @param i_prof          The profissional information array
    * @param i_id_presc      The prescription ID
    * 
    * @return The rank for the given prescription
    *
    * @author                Bruno Rego
    * @version               V.2.6.1
    * @since                 2011/08/25
    ********************************************************************************************/
    FUNCTION get_presc_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function processes the prescription time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author                            Pedro Teixeira
    * @since                             02/08/2011
    ********************************************************************************************/
    PROCEDURE get_presc_time_task_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rowids     IN table_varchar,
        o_presc_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    );

    /********************************************************************************************
    * This function processes the prescription time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author                            Pedro Teixeira
    * @since                             26/08/2011
    ********************************************************************************************/
    PROCEDURE get_presc_time_task_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_episode IN r_presc.id_last_episode%TYPE,
        o_presc_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    );

    /********************************************************************************************
    * This function processes the recon time task, returning to PFH the necessary information to update recon task
    *
    * @author                          Pedro Teixeira
    * @since                           09/06/2017
    ********************************************************************************************/
    PROCEDURE get_recon_time_task_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN presc.id_last_episode%TYPE,
        o_recon_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    );

    /********************************************************************************************
    * This function processes notes time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author           Pedro Teixeira
    * @since            2012/05/04
    ********************************************************************************************/
    PROCEDURE get_presc_notes_ttl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rowids     IN table_varchar,
        o_notes_info OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * This function processes notes time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author           Pedro Teixeira
    * @since            2012/05/04
    ********************************************************************************************/
    PROCEDURE get_presc_notes_ttl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_episode IN r_presc.id_last_episode%TYPE,
        o_notes_info OUT pk_types.cursor_type
    );
    /********************************************************************************************
    * This function returns generic information about prescription basic version
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_WORKFLOW   The workflow 
    * @param  I_ID_PATIENT    The ids to filter data
    * @param  I_ID_VISIT      The visit   
    * @param  I_ID_PRESC      The prescription
    *
    * @author  Alexis Nascimento
    * @since   2013-07-16 
    *
    ********************************************************************************************/
    FUNCTION get_list_prescription_basic
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN table_number_id DEFAULT NULL, --[WF_INSTITUTION, WF_AMBULATORY, WF_REPORT]
        i_id_patient   IN r_presc.id_patient%TYPE DEFAULT NULL,
        i_id_visit     IN r_presc.id_epis_create%TYPE DEFAULT NULL,
        i_id_presc     IN r_presc.id_presc%TYPE DEFAULT NULL,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_history_data IN VARCHAR2 DEFAULT 'N' -- [Y,N] checks if history data will be shown
    ) RETURN pk_rt_types.g_tbl_list_prescription_basic
        PIPELINED;

    /********************************************************************************************
    * This function returns DATA_GOV_ADMIN prescription count 
    *
    *
    * @author  Pedro Teixeira
    * @version 2.6.2.0.1
    * @since   2011-12-07 
    *
    ********************************************************************************************/
    FUNCTION get_dga_prescription_count
    (
        i_id_workflow IN table_number_id, --[WF_INSTITUTION, WF_AMBULATORY, WF_REPORT]
        i_id_visit    IN r_presc.id_epis_create%TYPE,
        i_id_episode  IN r_presc.id_last_episode%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Gets the prescription status string
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_presc              Prescription identifier 
    *
    * @return                        Returns the status string of the prescription
    *                        
    * @author                        Pedro Teixeira
    * @version                       2.6.1.2
    * @since                         2011/08/25
    **********************************************************************************************/
    FUNCTION get_presc_status_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the description of a most frequent product
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_most_freq          id most frequent product 
    *
    * @return                        Returns the name of the product
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/08/26
    **********************************************************************************************/
    FUNCTION get_most_freq_product_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_most_freq IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the treatment management
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID 
    *
    * @return                        Returns treatments with at least one execution should appear in grid
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/26
    **********************************************************************************************/
    FUNCTION get_treat_manag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN g_tbl_list_treat_manag
        PIPELINED;

    /**********************************************************************************************
    * Gets the treatment management notes
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               Tipo de revisão sobre: I - Intervention ;D - Drug
    * @param i_treat_manag            treatment management id 
    *
    * @return                        Returns treatment management notes
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/29
    **********************************************************************************************/
    FUNCTION get_treat_manag_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_flg_type    IN treatment_management.flg_type%TYPE,
        i_treat_manag IN treatment_management.id_treatment%TYPE
    ) RETURN g_tbl_list_treat_manag_notes
        PIPELINED;

    /**********************************************************************************************
    * Gets the professional and date of the last update treatment notes
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    *
    * @return                        Returns the professional and date of the last update treatment notes
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/31
    **********************************************************************************************/
    FUNCTION get_summary_list_last_upd
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN g_tbl_list_treat_manag_l_upd
        PIPELINED;

    /**********************************************************************************************
    * Gets the title of treatment notes
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    *
    * @return                        Returns the title of treatment notes
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/31
    **********************************************************************************************/
    FUNCTION get_title_treatement_manag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN g_tbl_title_treat_manag
        PIPELINED;

    /**********************************************************************************************
    * Gets the directions of a prescription 
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional's details
    * @param i_id_product                 id product
    * @param i_id_product_supplier        id product supplier
    * @param i_id_presc_dir               id prescription directions
    * @param i_flg_with_dt_begin          Begin date is included or not
    * @param i_flg_with_duration          Duration is included or not    
    * @param i_flg_with_executions        Executions are included or not    
    * @param i_flg_with_dt_end            End date is included or not
    *
    * @return                        Returns the directions prescription
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/02
    **********************************************************************************************/
    FUNCTION get_presc_resumed_dir_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc_dir        IN presc.id_presc_directions%TYPE,
        i_flg_with_dt_begin   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_duration   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_executions IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_dt_end     IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Lucene Search
    *
    * @param i_lang                  Language ID
    * @param i_search                string to search
    * @param i_column_name           column name
    * @param i_id_description_type   i_id_description_type
    *
    * @return                        Returns the search results
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/02
    **********************************************************************************************/
    FUNCTION get_src_entity
    (
        i_lang                IN language.id_language%TYPE,
        i_search              IN VARCHAR2,
        i_column_name         IN VARCHAR2,
        i_id_description_type IN NUMBER
    ) RETURN table_t_search;

    /**********************************************************************************************
    * Initialize params for filters search 
    *
    * @param i_context_ids            array with context ids
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/05
    **********************************************************************************************/
    PROCEDURE init_params_products
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**********************************************************************************************
    * Gets the translation of a given entity
    *
    * @param i_lang                  Language ID
    * @param i_code_entity           code entity to translate
    * @param i_column_name           description type
    * @param i_id_description_type   i_id_description_type
    *
    * @return                        Returns the entity translation
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/06
    **********************************************************************************************/
    FUNCTION get_entity_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_code_entity         IN VARCHAR2,
        i_id_description_type IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns generic information about prescription administrations
    * intended to replace pk_api_drug.get_ongoing_task_med_int
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-07
    *
    ********************************************************************************************/
    FUNCTION get_list_ongoing_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE
    ) RETURN tf_tasks_list;

    FUNCTION create_presc_exterior
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN r_presc.id_patient%TYPE,
        i_id_episode            IN r_presc.id_epis_create%TYPE,
        i_id_product_serialized IN VARCHAR2,
        i_id_task_dependency    IN r_presc.id_task_dependency%TYPE,
        i_flg_req_origin_module IN r_presc.flg_req_origin_module%TYPE,
        i_id_presc_directions   IN r_presc.id_presc_directions%TYPE DEFAULT NULL,
        i_flg_confirm           IN VARCHAR2 DEFAULT 'Y',
        o_id_presc              OUT r_presc.id_presc%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_presc_local
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN r_presc.id_patient%TYPE,
        i_id_episode            IN r_presc.id_epis_create%TYPE,
        i_id_product_serialized IN VARCHAR2,
        i_id_task_dependency    IN r_presc.id_task_dependency%TYPE,
        i_flg_req_origin_module IN r_presc.flg_req_origin_module%TYPE,
        i_id_presc_directions   IN r_presc.id_presc_directions%TYPE DEFAULT NULL,
        i_flg_confirm           IN VARCHAR2 DEFAULT 'Y',
        o_id_presc              OUT r_presc.id_presc%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function descontinue or cancel all the prescriptions of an episode
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    Episode whose prescription are to be cancelled
    *
    * @author  Pedro Teixeira
    * @since   2011-10-10
    *
    ********************************************************************************************/
    FUNCTION set_cancel_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN r_presc.id_epis_create%TYPE,
        i_notes      IN VARCHAR2 DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function descontinue or cancel the prescription depending on the current state
    *
    * @author  Pedro Teixeira
    * @since   2011-09-09
    *
    ********************************************************************************************/
    FUNCTION set_cancel_presc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN r_presc.id_presc%TYPE,
        i_id_reason   IN r_presc.id_cancel_reason%TYPE,
        i_reason      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_flg_confirm IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function suspends the prescription
    *
    * @author  Pedro Teixeira
    * @since   2011-09-12
    *
    ********************************************************************************************/
    FUNCTION set_suspend_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN r_presc.id_presc%TYPE,
        i_dt_begin_suspend IN VARCHAR2,
        i_dt_end_suspend   IN VARCHAR2,
        i_id_reason        IN r_presc.id_cancel_reason%TYPE,
        i_reason           IN VARCHAR2,
        i_notes            IN VARCHAR2,
        i_flg_confirm      IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function suspends the administration
    *
    * @author  Pedro Teixeira
    * @since   2011-10-25
    *
    ********************************************************************************************/
    FUNCTION set_suspend_adm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN r_presc.id_presc%TYPE,
        i_id_presc_plan IN r_presc_plan.id_presc_plan%TYPE,
        i_id_reason     IN r_presc.id_cancel_reason%TYPE,
        i_reason        IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_dt_suspend    IN VARCHAR2,
        i_flg_confirm   IN VARCHAR2 DEFAULT 'Y',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function resumes the prescription
    *
    * @author  Pedro Teixeira
    * @since   2011-09-12
    *
    ********************************************************************************************/
    FUNCTION set_resume_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN r_presc.id_presc%TYPE,
        i_dt_begin_resume IN VARCHAR2,
        i_id_reason       IN r_presc.id_cancel_reason%TYPE,
        i_reason          IN VARCHAR2,
        i_notes           IN VARCHAR2,
        i_flg_confirm     IN VARCHAR2 DEFAULT 'Y',
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function resumes the administration
    *
    * @author  Pedro Teixeira
    * @since   2011-10-25
    *
    ********************************************************************************************/
    FUNCTION set_resume_adm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN r_presc.id_presc%TYPE,
        i_id_presc_plan IN r_presc_plan.id_presc_plan%TYPE,
        i_flg_confirm   IN VARCHAR2 DEFAULT 'Y',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function resumes the administration
    *
    * @author  Pedro Teixeira
    * @since   2014-05-23
    *
    ********************************************************************************************/
    FUNCTION set_resume_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN r_presc.id_presc%TYPE,
        i_id_presc_plan    IN r_presc_plan.id_presc_plan%TYPE,
        i_id_resume_reason IN r_presc.id_cancel_reason%TYPE,
        i_resume_reason    IN VARCHAR2,
        i_notes_resume     IN VARCHAR2,
        i_dt_resume        IN VARCHAR2,
        i_flg_confirm      IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function cancel an administration
    *
    * @author  Pedro Teixeira
    * @since   2011-09-12
    *
    ********************************************************************************************/
    FUNCTION set_cancel_adm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN r_presc.id_presc%TYPE,
        i_id_presc_plan IN r_presc_plan.id_presc_plan%TYPE,
        i_id_reason     IN r_presc.id_cancel_reason%TYPE,
        i_reason        IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_flg_confirm   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function is supposed to reactivate the prescription, but no workflow is defined
    * to reactivate a discontinued or canceled presc, so, instead it return the presc description
    * -- created to replace: PK_API_DRUG.REACTIVATE_TASK_MED_INT
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PRESC      The prescription Id
    *
    * @author  Pedro Teixeira
    * @since   2011-09-08
    *
    ********************************************************************************************/
    FUNCTION reactivate_presc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_api_med_out.get_prod_desc_by_presc  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PRESC                      IN        NUMBER(24)
    *
    * @return   VARCHAR2
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-08-24
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    FUNCTION get_prod_desc_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * This function return the id presc type rel for a specific pick list
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Array with the professional information 
    * @param i_id_pick_list          id pick list
    * @param i_id_prod_med_type      id product type
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/13
    **********************************************************************************************/
    FUNCTION get_type_rel_pick_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pick_list     IN NUMBER,
        i_id_prod_med_type IN NUMBER
    ) RETURN NUMBER;

    /**********************************************************************************************
    * This function return the directions of a specific product
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Array with the professional information 
    * @param i_id_product                 id product
    * @param i_id_product_supplier        id product supplier
    * @param i_id_pick_list             ID pick list
    * @param i_flg_with_dt_begin          Begin date is included or not
    * @param i_flg_with_duration          Duration is included or not    
    * @param i_flg_with_executions        Executions are included or not    
    * @param i_flg_with_dt_end            End date is included or not
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/13
    **********************************************************************************************/

    FUNCTION get_presc_directions_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_pick_list        IN NUMBER DEFAULT 2,
        i_flg_with_dt_begin   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_duration   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_executions IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_dt_end     IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Gets the permission of product by financial (configured on ALERT_PRODUCT_TR.CONFIG_FINANCIAL_TYPE_MED_PER by default have permission)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_product            id product
    * @param  I_ID_PATIENT    The ids to filter data
    *
    * @return                        returns W or B (warning or block)
    *                        
    * @author                        Mário Mineiro
    * @version                       2.6.3.8.4
    * @since                         2013/11/13
    *******************************************************************************************************************************************/
    /*  FUNCTION get_financial_aprove
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_product          IN table_varchar DEFAULT table_varchar(NULL),
        i_id_product_supplier IN table_varchar DEFAULT table_varchar(NULL)
        
    ) RETURN VARCHAR2;*/

    /********************************************************************************************
    * get_patients_for_rowids  
    *
    * @param    I_ROWIDS                        IN        TABLE_VARCHAR
    * @param    I_SOURCE_TABLE_NAME             IN        VARCHAR2
    *
    * @return   TABLE_NUMBER
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-08-23
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    FUNCTION get_patients_for_rowids
    (
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2
    ) RETURN table_number;

    /********************************************************************************************
    * get_prescs_for_patient  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    *
    * @return   TABLE_TABLE_VARCHAR
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-08-23
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    FUNCTION get_prescs_for_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_table_varchar;

    /**********************************************************************************************
    * This function return the id directions of a specific product
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Array with the professional information 
    * @param i_id_product            id product
    * @param i_id_product_supplier   id product supplier
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/13
    **********************************************************************************************/
    FUNCTION get_id_std_presc_directions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_pick_list        IN NUMBER DEFAULT 0
    ) RETURN NUMBER;

    /*********************************************************************************************
    * get medication directions string for any given prescription detail
    *
    * @param i_lang                 language id
    * @param i_prof                 professional structure
    * @param i_id_presc             prescription id
    * @param i_flg_complete         controls if descriptives show all information, or only 
    *                               significative instructions (without dates) 
    *
    * @return varchar2              directions string based on the parameterized presc_dir 
    *                               string
    *
    * @author                       Elisabete Bugalho
    * @version                      2.6.1.2
    * @since                        2011/09/19
    **********************************************************************************************/
    FUNCTION get_presc_directions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_html     IN VARCHAR2 DEFAULT pk_rt_core_all.g_no,
        i_flg_complete IN VARCHAR2 DEFAULT pk_rt_core_all.g_yes
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function gets route rank
    *
    * @param i_lang                  id language
    * @param i_prof                  Array with the professional information 
    * @param i_id_route              id route
    * @param i_id_route_supplier     id route supplier
    *
    * @return                        route rank
    * 
    * @author                Elisabete Bugalho
    * @version               2.6.1.2
    * @since                 2011/09/19
    ********************************************************************************************/
    FUNCTION get_route_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function returns the last execution date of a prescription
    *
    * @param i_lang          id language
    * @param i_prof          array with the professional information 
    * @param i_id_presc      id prescription
    *
    * @return                last execution date
    * 
    * @author                Elisabete Bugalho
    * @version               2.6.1.2
    * @since                 2011/09/19
    ********************************************************************************************/
    FUNCTION get_last_adm_start_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * This function returns the last date of a prescription
    *
    * @param i_lang          id language
    * @param i_prof          array with the professional information 
    * @param i_patient       id patient
    * @param i_id_episode    id episode
    *
    * @return                last presription
    * 
    * @author                Cristina Oliveira
    * @version               2.6.1.2
    * @since                 2022/05/06
    ********************************************************************************************/
    FUNCTION get_last_presc_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * This function returns the prescriptor
    *
    * @param i_lang          id language
    * @param i_prof          array with the professional information 
    * @param i_patient       id patient
    * @param i_id_episode    id episode
    *
    * @return                id profissional of prescriptor
    * 
    * @author                Cristina Oliveira
    * @version               2.6.1.2
    * @since                 2022/05/06
    ********************************************************************************************/
    FUNCTION get_prescriber
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function returns the id of the last professional that executed 
    *
    * @param i_lang          id language
    * @param i_prof          array with the professional information 
    * @param i_id_presc      id prescription
    *
    * @return                professional id
    * 
    * @author                Elisabete Bugalho
    * @version               2.6.1.2
    * @since                 2011/09/20
    ********************************************************************************************/

    FUNCTION get_last_adm_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function gets route color
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_route              id route
    * @param i_id_route_supplier     id route supplier
    *
    * @return                        route color
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/20
    ********************************************************************************************/
    FUNCTION get_route_color
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * This function returns product Route description
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_route              id route
    * @param i_id_route_supplier     id route supplier
    * @value i_id_description_type   {*} 1 - normal {*} 2 - abbreviation
    *
    * @return                        route color
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/20
    *********************************************************************************************/
    FUNCTION get_route_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_route            IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier   IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE,
        i_id_route_status     IN pk_rt_med_pfh.r_presc_dir.id_route_status%TYPE,
        i_id_description_type IN NUMBER DEFAULT pk_rt_med_pfh.g_entity_description_type_def
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Initialize params for filters search (Administrations and Tasks)
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/20
    **********************************************************************************************/
    PROCEDURE init_params_adm_task
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /*********************************************************************************************
    * This function returns the code description for a prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        array with code_
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/22
    *********************************************************************************************/
    FUNCTION get_code_prod_by_presc
    (
        i_lang     language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN table_varchar;

    /**********************************************************************************************
    * This function returns a array with the active states for a prescription
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/23
    **********************************************************************************************/
    FUNCTION get_wfg_presc_active RETURN table_number_id;

    /**********************************************************************************************
    * This function returns a array with the inactive states for a prescription
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/23
    **********************************************************************************************/
    FUNCTION get_wfg_presc_inactive RETURN table_number_id;

    /**********************************************************************************************
    * This function returns a array with the temporary states for a prescription
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/23
    **********************************************************************************************/
    FUNCTION get_tmp_presc_temp RETURN table_number;

    /********************************************************************************************
    * This procedure updates viewer_ea precriptions
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-26
    *
    ********************************************************************************************/
    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    /********************************************************************************************
    * GET_PRESC_NUMBER_SEQ
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param i_id_institution      Institution identifier
    * @param i_flg_type            Flg_type
    * @param i_id_clinical_service Clinical service identifier
    * @param o_sequence_name       Sequence name
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/19
    * @dependents                  PK_REF_ORIG_PHY.GET_REFERRAL_NUMBER
    **********************************************************************************************/
    FUNCTION get_presc_number_seq
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN prescription_number_seq.id_institution%TYPE,
        i_flg_type            IN prescription_number_seq.flg_type%TYPE,
        i_id_clinical_service IN prescription_number_seq.id_clinical_service%TYPE,
        o_sequence_name       OUT prescription_number_seq.sequence_name%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * This function will return all chronic prescription for a specific       *
    * patient \ visit                                                         *
    *                                                                         *
    * @param i_lang               The ID of the user language                 *
    * @param i_prof               The profissional array                      *
    * @param i_patient            Patient identifier                          *
    * @param i_visit              Visit identifier                            *
    *                                                                         *
    * @param o_info               Cursor with information                     *
    * @param o_error              Error message                               *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/09/28                                                     *
    **************************************************************************/
    FUNCTION get_active_chronic_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*****************************************************************************************
    * This function returns product description
    *         
    *
    * @author                Pedro Quinteiro
    * @version               V.2.6.1
    * @since                 2011/09/07
    ********************************************************************************************/
    FUNCTION get_product_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_product IN VARCHAR2,
        i_id_presc   IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This functions returns prescription last change date
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-28
    *
    ********************************************************************************************/
    FUNCTION get_presc_change_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription is in an active state, otherwise 'N'
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-29
    *
    ********************************************************************************************/
    FUNCTION is_active_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription has administrations
    *
    *
    * @author  Pedro Teixeira
    * @since   2012-07-11
    *
    ********************************************************************************************/
    FUNCTION has_administrations
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription is canceled, otherwise 'N'
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-10-28
    *
    ********************************************************************************************/
    FUNCTION is_canceled_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the product description
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_product            id product
    * @param i_id_product_supplier   id product supplier
    * @param i_id_presc              Prescription id
    *
    * @return                        Returns the product description
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/29
    **********************************************************************************************/
    FUNCTION get_product_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN pk_rt_med_pfh.r_product.id_product%TYPE,
        i_id_product_supplier IN pk_rt_med_pfh.r_product.id_product_supplier%TYPE,
        i_id_presc            IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /**************************************************************************
    * This function will return all reported prescription for a specific      *
    * patient                                                                 *
    *                                                                         *
    * @param i_lang               The ID of the user language                 *
    * @param i_prof               The profissional array                      *
    * @param i_patient            Patient identifier                          *
    *                                                                         *
    * @param o_info               Cursor with information                     *
    * @param o_error              Error message                               *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/09/28                                                     *
    **************************************************************************/
    FUNCTION get_list_report_active_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the directions of a prescription 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_product            id product
    * @param i_id_product_supplier   id product supplier
    * @param i_id_presc_dir          id prescription directions
    *
    * @return                        Returns the directions prescription
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/29
    **********************************************************************************************/
    FUNCTION get_presc_dir_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN pk_rt_med_pfh.r_product.id_product%TYPE,
        i_id_product_supplier IN pk_rt_med_pfh.r_product.id_product_supplier%TYPE,
        i_id_presc_dir        IN pk_rt_med_pfh.r_presc.id_presc_directions%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    *  This function will return the icon that distinguishes the different types of medication / workflows for a given id_presc
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        type of presc icon
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/29
    *********************************************************************************************/

    FUNCTION get_presc_type_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    *  This function will return the prescription notes
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        prescription notes
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    *********************************************************************************************/
    FUNCTION get_presc_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * This function returns the status name of a icon
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_workflow           id workflow
    * @param i_id_status             id status 
    *
    * @return                        Returns the icon name
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    FUNCTION get_icon_wf_status_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN NUMBER,
        i_id_status   IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * This function returns the icon back color
    *
    * @param i_id_workflow           id workflow
    * @param i_id_status             id status 
    *
    * @return                        Returns the icon back color
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    FUNCTION get_icon_bg_color
    (
        i_id_workflow IN NUMBER,
        i_id_status   IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * This function returns the icon color
    *
    * @param i_id_workflow           id workflow
    * @param i_id_status             id status 
    *
    * @Returns                       icon color
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    FUNCTION get_icon_color
    (
        i_id_workflow IN NUMBER,
        i_id_status   IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Initialize params for filters search (Ambulatory Medication (Pending Prescriptions))
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    PROCEDURE init_params_amb_pend
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************
    * Gets the task_list_by_patient for PDMS 
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-29
    *
    ********************************************************************************************/
    FUNCTION get_task_list_by_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_first_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_last_date  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_presc      OUT pk_types.cursor_type,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the presc_plan task actions 
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-30
    *
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function for get all action for a prescription or administration
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)    
    * @param   i_id_patient                Patient Identifier
    * @param   i_id_episode                Episode Identifier
    * @param   i_id_presc                  Prescription Identifier
    * @param   i_id_presc_plan             Prescription Plan Identifier 
    * @param   i_id_print_group            Print Group Identifier
    * @param   i_flg_action_type           Flag action type
    * @param   o_action                    All Actions and availability
    * @param   o_error                     Error information
    *
    * @RETURN                             true or false if the function was executed correctly
    *
    * @author                             Miguel Gomes (This function should be review)
    * @version                            2.6.4.3
    * @since                              10-11-2014
    *
    **********************************************************************************************/
    FUNCTION get_med_tab_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN presc.id_patient%TYPE,
        i_id_episode           IN presc.id_epis_create%TYPE,
        i_id_presc             IN table_number,
        i_id_presc_plan        IN table_number,
        i_id_presc_plan_task   IN table_number DEFAULT NULL,
        i_id_print_group       IN table_number,
        i_id_editor_tab        IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        i_flg_ignore_inactive  IN VARCHAR2,
        i_flg_action_type      IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the prescription actions 
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-10-20
    *
    ********************************************************************************************/
    FUNCTION get_presc_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function returns a array with the status for printed and Faxed RX
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    FUNCTION get_pg_print_fax RETURN table_number;

    /**********************************************************************************************
    * This function returns a array with the status for printed  RX
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    FUNCTION get_pg_printed RETURN table_number;

    /**********************************************************************************************
    * This function returns a array with the status for faxed  RX
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    FUNCTION get_pg_faxed RETURN table_number;

    /**********************************************************************************************
    * Initialize params for filters search (Ambulatory Medication (Printed and Faxed RX))
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    PROCEDURE init_params_amb_print_fax
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**********************************************************************************************
    * Initialize params for filters search (Prescribed Medication )
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/06
    **********************************************************************************************/
    PROCEDURE init_params_prod_med
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    TYPE t_rec_med IS RECORD(
        flg_status            drug_presc_det.flg_status%TYPE,
        dt_status             TIMESTAMP WITH LOCAL TIME ZONE,
        tran_status           VARCHAR2(1000 CHAR),
        pharm                 VARCHAR2(1000 CHAR),
        dose                  presc_dir_dosefreq.dose%TYPE,
        id_unit_dose          VARCHAR2(1000 CHAR),
        dose_rng_min          presc_dir_dosefreq.dose_rng_min%TYPE,
        id_unit_rng_min       VARCHAR2(1000 CHAR),
        dose_rng_max          presc_dir_dosefreq.dose_rng_max%TYPE,
        id_unit_rng_max       VARCHAR2(1000 CHAR),
        value_bolus           drug_presc_det.value_bolus%TYPE,
        id_unit_measure_bolus VARCHAR2(1000 CHAR),
        value_drip            drug_presc_det.value_drip%TYPE,
        id_unit_measure_drip  VARCHAR2(1000 CHAR));

    TYPE t_coll_tab_med IS TABLE OF t_rec_med;

    /********************************************************************************************
    * pk_api_pfh_in.get_hand_off_med (PIPELINED) 
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    I_FLG_STATUS                    IN        VARCHAR2
    *
    * @return   PK_API_PFH_IN.T_COLL_TAB_MED
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-10-06
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   
    *
    ********************************************************************************************/
    FUNCTION get_hand_off_med
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN t_coll_tab_med
        PIPELINED;

    /********************************************************************************************
    * This function copy to a new one all information of a given prescription
    *
    * @param  I_LANG                                  The language id
    * @param  I_PROF                                  The profissional
    * @param  I_ID_PRESC                              Prescription Id
    * @param  i_id_patient                            Patient Id
    * @param  i_id_episode                            Episode Id
    * @param  i_id_workflow                           Workflow Id
    * @param  i_id_status                             Status Id
    * @param  i_id_presc_type_rel                     Prescription type
    * @param  i_flg_exclude_detail                    flag that controls if copys only the main information
    * @param  i_flg_execution                         flag that specifies the type of execution: B; E; N
    *   
    *
    * @author  Pedro Quinteiro
    * @since   2011-08-18
    *
    ********************************************************************************************/
    FUNCTION copy_presc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_presc           IN r_presc.id_presc%TYPE,
        i_id_patient         IN r_presc.id_patient%TYPE DEFAULT NULL, -- nullable
        i_id_episode         IN r_presc.id_epis_create%TYPE DEFAULT NULL, -- nullable
        i_id_workflow        IN r_presc.id_workflow%TYPE DEFAULT NULL, -- nullable
        i_id_status          IN r_presc.id_status%TYPE DEFAULT NULL, -- nullable
        i_id_presc_type_rel  IN r_presc.id_presc_type_rel%TYPE DEFAULT NULL, -- nullable
        i_flg_exclude_detail IN VARCHAR2 DEFAULT pk_rt_core_all.g_no, -- nullable
        i_flg_confirm        IN VARCHAR2 DEFAULT pk_rt_core_all.g_no,
        i_flg_execution      IN r_presc.flg_execution%TYPE DEFAULT NULL,
        o_id_presc           OUT r_presc.id_presc%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This functions returns prescription for a given patient and episode
    * where flg_execution = 'N' (Next episode)
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-10-07
    *
    ********************************************************************************************/
    FUNCTION get_next_epis_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_episode IN r_presc.id_epis_create%TYPE,
        o_id_presc   OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function deletes all information of a given prescription
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    Episode whose prescriptions will be deleted
    * @param i_flg_clean_vital_sign_only     Y: cleans only the presc associated to a vital_sign_read 
    *
    * @author  Pedro Quinteiro
    * @since   2011-08-18
    *
    ********************************************************************************************/
    FUNCTION delete_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_presc_vital_sign_assoc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN table_number,
        i_id_vital_sign_read IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * This function returns 'Y' if presc is active for current visit
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_patient            patient identification
    * @param i_id_presc_type         Prescription type
    * @param i_product               Product
    *
    *
    * @author                        Pedro Teixeira
    * @since                         2012/07/25
    *********************************************************************************************/
    FUNCTION is_presc_med_view_active
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN presc.id_patient%TYPE,
        i_id_presc_type IN NUMBER,
        i_product       IN VARCHAR2,
        i_id_episode    IN presc.id_epis_create%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * This function returns the status icon for a given product prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_patient            patient identification
    * @param i_id_presc_type         Prescription type
    * @param i_product               Product
    *
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/10
    *********************************************************************************************/
    FUNCTION get_product_status_icon
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_presc_type IN NUMBER,
        i_product       IN VARCHAR2,
        i_id_episode    IN presc.id_epis_create%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * when new visit is created the on_create_visit procedure is executed
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Bruno Rego
    * @version                            2.6.1.1
    * @since                              02-06-2011 12:45
    *
    **********************************************************************************************/
    PROCEDURE on_create_visit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*********************************************************************************************
    * This function returns rank for a given product prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_patient            patient identification
    * @param i_id_presc_type         Prescription type
    * @param i_product               Product
    *
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/11
    *********************************************************************************************/
    FUNCTION get_product_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_presc_type IN NUMBER,
        i_product       IN VARCHAR2
    ) RETURN NUMBER;

    /*********************************************************************************************
    * This function returns the prescription type icon name for a given prescription detail identifier
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              The ID of the prescription
    *
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/11
    *********************************************************************************************/
    FUNCTION get_presc_icon_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * This function returns a array with the temporary states for a prescription reconciliation
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/11
    **********************************************************************************************/
    FUNCTION get_tmp_presc_recon RETURN table_number;

    /**********************************************************************************************
    * Initialize params for filters search (Home Medication )
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/06
    **********************************************************************************************/
    PROCEDURE init_params_home_med
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************
    * Get editor lookup list
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EDITOR_LOOKUP         the editor lookup type, as defined in el_* types
    * @param   I_ID_PRODUCT               the product identification (if needed)
    * @param   I_ID_PRODUCT_SUPPLIER      the product suppliter identification (if needed)
    * @param   O_INFO                     cursor with lookup list
    * @param   O_ERROR                    error information
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Bruno Rego
    * @version                            2.6.1.1
    * @since                              02-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_editor_lookup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_editor_lookup    IN NUMBER,
        i_id_product          IN NUMBER DEFAULT NULL,
        i_id_product_supplier IN NUMBER DEFAULT NULL,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns presc details based on presc_med row_id
    * necessary for awareness processing
    *
    * @author  Pedro Teixeira
    * @since   2011-11-04
    *
    ********************************************************************************************/
    FUNCTION get_presc_med_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rowid      IN VARCHAR2,
        o_id_patient OUT r_presc.id_patient%TYPE,
        o_id_episode OUT r_presc.id_epis_create%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns all agregated information about medication (should be used to send detailed data to outside systems like CDA)
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PATIENT    The patient id
    * @param  I_ID_VISIT      The visit id
    * @param  I_ID_PRESC      The prescription id
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011-09-30 
    *
    ********************************************************************************************/
    FUNCTION get_list_medication_aggr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_visit   IN visit.id_visit%TYPE DEFAULT NULL,
        i_id_presc   IN pk_rt_med_pfh.r_presc.id_presc%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN CLOB;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    * based on the product/ingred/... AND supplier 
    *
    * @param i_id_product                         Input - Product ID
    * @param i_id_product_supplier                Input - Supplier ID
    *
    * @return  Medication Unique ID
    *          null if error
    * @raises                
    *
    * @author                Pedro Morais
    * @version               V.2.6.1
    * @since                 2011/07/12
    ********************************************************************************************/
    FUNCTION get_unique_id_by_id_and_supp
    (
        i_lang        IN NUMBER,
        i_id          IN VARCHAR2,
        i_id_supplier IN VARCHAR2,
        o_id_unique   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    *
    * @param i_id_product                         Input - Product ID
    * @param i_id_product_supplier                Input - Supplier ID
    *
    * @return  Medication Unique ID
    *          null if error
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.8.0.1
    * @since                 2019/11/11
    ********************************************************************************************/
    FUNCTION get_unique_id_by_id_and_supp
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    * based on the product/ingred/... AND supplier 
    *
    * @param i_id_product                         Input - list of Product ID
    * @param i_id_product_supplier                Input - list of Supplier ID
    *
    * @return  Medication Unique ID
    *          null if error
    * @raises                
    *
    * @author                Pedro Quinteiro
    * @version               V.2.6.1
    * @since                 2011/08/24
    ********************************************************************************************/
    FUNCTION get_unique_ids_by_id_and_supp
    (
        i_lang        IN NUMBER,
        i_id          IN table_varchar,
        i_id_supplier IN table_varchar,
        o_id_unique   OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * This function returns the product configurations
    *
    * @author  Pedro Teixeira
    * @since   2011-12-13
    *********************************************************************************************/
    FUNCTION get_product_configurations
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN pk_rt_med_pfh.r_product.id_product%TYPE,
        i_id_product_supplier IN pk_rt_med_pfh.r_product.id_product_supplier%TYPE,
        i_id_pick_list        IN NUMBER
    ) RETURN table_varchar;

    /********************************************************************************************
    * Returns CDS call icon associated to the passed prescription
    *
    *
    * @author               Pedro Teixeira
    * @since                2011/12/13
    ********************************************************************************************/
    FUNCTION get_cds_call_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_call      IN NUMBER,
        i_task_reqs IN VARCHAR2
    ) RETURN VARCHAR;

    /**********************************************************************************************
    * Initialize params for eRx filter
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Pedro Teixeira
    * @since                         2011/12/22
    **********************************************************************************************/
    PROCEDURE init_params_amb_erx
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
    * Checks if there are active prescriptions for the given episode.
    * Used in the Information desk patients grid detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    *
    * @return               Y if such prescriptions exist, N otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/01/20
    */
    FUNCTION check_epis_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Create new review for home medication
    *
    * @param  i_prof                        The professional array
    * @param  i_id_patient                  Patient ID
    * @param  o_id_review                   Id review
    * @param  o_code_review                 Review Code
    * @param  o_review_desc                 Review Desc
    * @param  o_dt_create                   Review Creation Date
    * @param  o_id_prof_create              Review Creation Professional
    *
    * @return boolean
    *
    * @author Pedro Quinteiro
    * @last_rev Pedro Teixeira
    * @since  09/05/2012
    *
    ********************************************************************************************/
    FUNCTION get_last_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN episode.id_patient%TYPE DEFAULT NULL,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_id_review      OUT NUMBER,
        o_code_review    OUT NUMBER,
        o_review_desc    OUT VARCHAR2,
        o_dt_create      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_update      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_prof_create OUT NUMBER,
        o_info_source    OUT CLOB,
        o_pat_not_take   OUT CLOB,
        o_pat_take       OUT CLOB,
        o_notes          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This procedure sets the information about home medication global information.
    *
    * @param i_lang                    The user language ID
    * @param i_prof                    The profissional information array
    * @param i_id_patient              The patient ID 
    * @param i_id_episode              The the prescription report info details
    * @param io_id_review              The ID review
    * @param i_global_info             The global information multichoice
    * @param o_error                   The output error
    *
    * @author  Bruno Rego
    * @last_rev Pedro Teixeira
    * @since  13/03/2012
    ********************************************************************************************/
    FUNCTION set_hm_review_global_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        io_id_review  IN OUT NUMBER,
        i_code_review IN NUMBER
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This procedure gets the reconciliation status
    *
    * @param i_lang                   The ID of the user language
    * @param i_prof                   The profissional information array
    * @param i_id_patient             The patient name
    * @param i_id_episode             The ID of the episode
    *
    * @author  Pedro Teixeira
    * @since   12/03/2012
    ********************************************************************************************/
    FUNCTION get_recon_status_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        o_flg_rev_reviewed     OUT VARCHAR2,
        o_flg_rev_reconciled   OUT VARCHAR2,
        o_flg_revision_warning OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * This function will return prescription basic information:
    * - product description
    * - directions description
    * - status description
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             The profissional array
    * @param i_id_presc         The ID of the prescription
    *
    * @return boolean
    *
    * @author Pedro Teixeira
    * @since  26/01/2012
    *
    ********************************************************************************************/
    FUNCTION get_presc_basic_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_presc          IN r_presc.id_presc%TYPE,
        o_presc_prod_desc   OUT VARCHAR2,
        o_presc_dir_desc    OUT VARCHAR2,
        o_presc_status_desc OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Adds notes to a prescription
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        ALERT_PRODUCT_TR.PROFISSIONAL
    * @param    I_ID_PRESC                      IN        PRESCRIPTION ID
    * @param    I_NOTES                         IN        NOTES TEXT
    *
    * @author   Pedro Morais
    * @version    
    * @since    2011-11-04
    *
    * @added to this package         Pedro Teixeira
    * @version                       2.6.2
    * @since                         08/02/2012
    ********************************************************************************************/
    FUNCTION set_prescription_notes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_presc            IN r_presc.id_presc%TYPE,
        i_notes               IN VARCHAR2,
        o_id_presc_notes      OUT NUMBER,
        o_id_presc_notes_item OUT NUMBER
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function is for single_page
    *
    * @author           Pedro Teixeira
    * @since            2012/06/22
    ********************************************************************************************/
    PROCEDURE get_presc_for_single_page
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_presc             IN table_number,
        i_flg_with_notes       IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_recon_notes IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_no,
        o_info                 OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * This function is to obtain prescription list with less returned columns
    *
    * @author           Pedro Teixeira
    * @since            2012/12/04
    ********************************************************************************************/
    FUNCTION get_list_presc_resumed
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN table_number_id DEFAULT NULL,
        i_id_patient           IN r_presc.id_patient%TYPE DEFAULT NULL,
        i_id_visit             IN r_presc.id_epis_create%TYPE DEFAULT NULL,
        i_eliminate_duplicates IN VARCHAR2 DEFAULT 'N'
    ) RETURN pk_rt_types.g_tbl_list_presc_resumed
        PIPELINED;

    /********************************************************************************************
    * pk_api_med_out.create_reported_freetext
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    I_DESC_PRODUCT                  IN        VARCHAR2
    * @param    O_ID_PRESC                      OUT       NUMBER(24)
    *
    * @author   Rita Lopes
    * @version    
    * @since    2013-02-20
    *
    * @notes    cria relatos medicacao em texto livre
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    PROCEDURE create_reported_freetext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN presc.id_patient%TYPE,
        i_id_episode   IN presc.id_epis_create%TYPE,
        i_desc_product IN VARCHAR2,
        o_id_presc     OUT presc.id_presc%TYPE,
        o_error        OUT t_error_out
    );

    /********************************************************************************************
    * This function returns information of Home and Local medication to reports
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    The Episode
    *
    * @author  Alexis Nascimento
    * @since   2013-07-22 
    *
    ********************************************************************************************/

    FUNCTION get_medication_info_4report
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_flg_reconciliantion  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_review           IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_home_medication  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_local_medication IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_administ   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_stat_hist  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_revisions  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_local_presc_dirs IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_direction_config IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_hm_revision          OUT pk_types.cursor_type,
        o_hm_reports           OUT pk_types.cursor_type,
        o_reconciliantion_info OUT pk_types.cursor_type,
        o_local_presc          OUT pk_types.cursor_type,
        o_local_admin          OUT pk_types.cursor_type,
        o_local_admin_detail   OUT pk_types.cursor_type,
        o_presc_stat_hist      OUT pk_types.cursor_type,
        o_list_revisions       OUT pk_types.cursor_type,
        o_list_prod_revisions  OUT pk_types.cursor_type,
        o_local_presc_dirs     OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This procedure returns the necessary data to delete or create an Alert
    *
    * @author Pedro Teixeira
    * @since  07/08/2013
    *
    ********************************************************************************************/
    PROCEDURE get_presc_alerts_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_source_table_name   IN VARCHAR2 DEFAULT 'PRESC',
        i_rowids              IN table_varchar,
        o_id_presc            OUT presc.id_presc%TYPE,
        o_dt_first_valid_plan OUT r_presc.dt_first_valid_plan%TYPE,
        o_id_patient          OUT r_presc.id_patient%TYPE,
        o_id_episode          OUT r_presc.id_epis_create%TYPE,
        o_prod_desc           OUT VARCHAR2,
        o_id_prof_co_sign     OUT NUMBER,
        o_id_status           OUT r_presc.id_status%TYPE,
        o_dt_last_update      OUT r_presc.dt_last_update%TYPE,
        o_flg_edited          OUT r_presc.flg_edited%TYPE,
        o_trigger_event       OUT NUMBER,
        o_error               OUT t_error_out
    );

    /********************************************************************************************
    * This procedure processes the presc alerts
    *
    * @author Pedro Teixeira
    * @since  07/08/2013
    *
    ********************************************************************************************/
    PROCEDURE process_presc_alerts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************************
    * This procedure emits an alert every time a prescription is updated.
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_event_type        Event type
    * @param  i_rowids            Row ID's
    * @param  i_source_table_name Source table name
    * @param  i_list_columns      List of columns
    * @param  i_dg_table_name     Data governance table
    *
    * @author Jose Brito
    * @since  04/11/2014
    *
    ********************************************************************************************/
    PROCEDURE process_presc_update_alerts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    -- logging variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000);

    /**********************************************************************************************
    * Initialize params for filters search 
    *
    * @param i_context_ids            array with context ids
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/05
    **********************************************************************************************/
    PROCEDURE init_params_witness
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************
    * This function returns data for the details and history
    *
    * @param  I_LANG          The langiage id
    * @param  I_PROF          The profissional
    * @param  I_ID_DETAIL     The details id to get the data as defined in presc_details_history table    
    * @param  I_ID_EPISODE    The visit episode (MED_ENTRY_DETAILS, MED_ENTRY_HISTORY, RECONCILIATION_DETAILS, RECONCILIATION_HISTORY) 
    * @param  I_ID_PRESC_PLAN The id prescription plan (ADMINISTRATION_DETAILS, ADMINISTRATION_HISTORY)
    * @param  I_ID_PRESC      The product id prescription list (PRESCRIPTION_DETAILS, PRESCRIPTION_HISTORY)         
    * @param  O_CUR_DATA      The cursor output with information
    * @param  O_CUR_TABLES    The cursor output with tables
    * @param  O_ERROR         The output for error information
    *
    * @author  Rui Teixeira
    * @version 2.6.3.8.5
    * @since   2013-11-18 
    *
    ********************************************************************************************/
    FUNCTION get_details_history
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_detail     IN NUMBER,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_presc_plan IN episode.id_episode%TYPE,
        i_id_presc      IN table_number,
        o_cur_data      OUT pk_types.cursor_type,
        o_cur_tables    OUT table_table_varchar,
        o_header_presc  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns data for the details and history
    *
    * @param  I_LANG          The langiage id
    * @param  I_PROF          The profissional
    * @param  I_ID_DETAIL     The details id to get the data as defined in presc_details_history table    
    * @param  I_ID_EPISODE    The visit episode (MED_ENTRY_DETAILS, MED_ENTRY_HISTORY, RECONCILIATION_DETAILS, RECONCILIATION_HISTORY) 
    * @param  I_ID_PRESC_PLAN The id prescription plan (ADMINISTRATION_DETAILS, ADMINISTRATION_HISTORY)
    * @param  I_ID_PRESC      The product id prescription list (PRESCRIPTION_DETAILS, PRESCRIPTION_HISTORY)         
    * @param  O_CUR_DATA      The cursor output with information
    * @param  O_CUR_TABLES    The cursor output with tables
    * @param  O_ERROR         The output for error information
    *
    * @author  Rui Teixeira
    * @version 2.6.3.8.5
    * @since   2013-11-18 
    *
    ********************************************************************************************/
    FUNCTION get_details
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_detail          IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_presc_plan      IN episode.id_episode%TYPE,
        i_id_presc           IN table_number,
        i_id_presc_plan_task IN NUMBER DEFAULT NULL,
        o_cur_data           OUT pk_types.cursor_type,
        o_cur_tables         OUT table_table_varchar,
        o_header_presc       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient and presc products for CDR validations
    ********************************************************************************************/
    FUNCTION get_patient_presc_prods
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN r_presc.id_patient%TYPE,
        i_id_product_sup IN table_varchar DEFAULT NULL,
        i_id_presc       IN table_number,
        o_products       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @grant_by_soft_inst
    * Public Function. gets most relevant grant by institution/software criteria
    *
    * @param    i_context            context to be used ( table name )
    * @param    i_prof               info of current user
    * @param    i_dcs                array od dep_clin_Sev to compare( if available )
    * @param    i_specialty          array of clinical_service to compare ( if available )
    *
    * @return   array of relevant id_grant 
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2013/11/29
    */
    FUNCTION grant_by_soft_inst
    (
        i_context   IN VARCHAR2,
        i_prof      IN profissional,
        i_dcs       IN table_number DEFAULT table_number(0),
        i_specialty IN table_number DEFAULT table_number(0)
    ) RETURN table_number;

    FUNCTION grant_by_prof_dcs
    (
        i_context IN VARCHAR2,
        i_prof    IN profissional
    ) RETURN table_number;

    /*************************************************************************
    * This function returns home medication ranks!                           *
    *                                                                        *
    * @param                 i_status                 Input - id status      *
    * @return                rank                                            *
    *                                                                        *
    * @raises                                                                *
    *                                                                        *
    * @author                Alexis Nascimento                               *
    * @version               V.2.6.3                                         *
    * @since                 2013/11/29                                      *
    *************************************************************************/

    FUNCTION get_hm_rank_by_status
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_presc  IN presc.id_presc%TYPE,
        i_status IN NUMBER
    ) RETURN NUMBER;

    /**
    * Check if product anda directions are vailable in favorite list
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    *
    *
    * @return  'Y'es if is favorite, otherwise 'N'o 
    *
    * @author  JOANA.BARROSO
    * @version <Product Version>
    * @since   28-11-2013
    */

    FUNCTION check_prod_favorite
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_pick_list        IN NUMBER,
        i_id_most_freq        IN NUMBER,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_type                IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Receives id_product_level and returns the level_tag
    *
    * @param  i_id_product_level                                Input - id_product_level          
    *
    * @return                       level_Tag 
    *                        
    * @author                        Mário Mineiro
    * @version                       2.6.3.8.9
    * @since                         2013/12/11
    *******************************************************************************************************************************************/
    FUNCTION get_product_level_tag
    (
        i_id_product           IN VARCHAR2,
        i_id_product_level     IN VARCHAR2,
        i_id_product_level_sup IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Receives id_product and returns the id_product without the level_tag
    *
    * @param  i_id_product_level                                Input - id_product_level          
    *
    * @return                       level_Tag 
    *                        
    * @author                        Mário Mineiro
    * @version                       2.6.3.8.9
    * @since                         2013/12/11
    *******************************************************************************************************************************************/

    FUNCTION remove_product_level_tag
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * This function check if products are available in lnk_product_pick_list_grant
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                The profissional information array
    * @param i_id_product          Array of product id
    * @param i_id_product_supplier Array of product supplier id    
    * @param i_grant               ID grant
    * @param i_id_pick_list        ID pick list
    *
    * @author  Joana Madureira Barroso
    * @version 2.6.3.9
    * @since   2013/12/19
    */
    FUNCTION check_product_pkl_available
    (
        i_lang                language.id_language%TYPE,
        i_prof                profissional,
        i_id_product          table_varchar,
        i_id_product_supplier table_varchar,
        i_grant               NUMBER,
        i_id_pick_list        NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get instructions background color
    *
    * @author      Joana Madureira Barroso
    * @version     
    * @since       07/01/2014
    *
    ********************************************************************************************/

    FUNCTION get_instr_bg_color
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_stoptime IN presc.dt_stoptime%TYPE,
        i_id_workflow IN presc.id_workflow%TYPE,
        i_id_status   IN presc.id_status%TYPE,
        i_flg_edited  IN presc.flg_edited%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_instr_bg_alpha
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_stoptime IN presc.dt_stoptime%TYPE,
        i_id_workflow IN presc.id_workflow%TYPE,
        i_id_status   IN presc.id_status%TYPE,
        i_flg_edited  IN presc.flg_edited%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_instr_bg_color_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_instr_bg_alpha_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get draft RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_draft
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN presc.id_epis_create%TYPE
    ) RETURN pk_rt_types.g_tbl_presc_viewer_list
        PIPELINED;

    /**
    * Get all active RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_epis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN pk_rt_types.g_tbl_presc_viewer_list
        PIPELINED;

    /**
    * Get all active RX prescription list for a given patient from previous episodes
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_pat          Patient identification
    * @param   i_epis         Episode identification
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_all
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE,
        i_epis IN episode.id_episode%TYPE
    ) RETURN pk_rt_types.g_tbl_presc_viewer_list
        PIPELINED;

    /**
    * Get detail for a given RX prescription
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id           Prescription identification
    * @param   i_type         Type of prescription list
    *
    * @value   i_type   {*} 'DRAFT' get_rx_prescription_darft 
                        {*} 'ALL' get_rx_prescription_all    
                        {*} 'EPIS' get_rx_prescription_epis    
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_id   IN NUMBER,
        i_type IN VARCHAR2
    ) RETURN pk_rt_types.g_tbl_presc_viewer_detail
        PIPELINED;

    PROCEDURE pat_take_not_take_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_pat_take     OUT VARCHAR2,
        o_pat_not_take OUT VARCHAR2,
        o_info_source  OUT VARCHAR2,
        o_notes        OUT VARCHAR2
    );

    FUNCTION get_info_button_med
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_elements IN table_varchar,
        o_id_rxnorm   OUT table_varchar,
        o_desc_rxnorm OUT table_varchar,
        o_terminology OUT table_varchar
    ) RETURN BOOLEAN;

    FUNCTION get_products_by_presc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN NUMBER,
        o_elements      OUT table_varchar,
        o_elements_type OUT table_varchar
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a string of info icons for a given prescription ID
    *
    * @param  I_LANG                 The language id
    * @param  I_PROF                 The profissional
    * @param  I_ID_PRESC             Prescription ID
    *
    * @return  PL/SQL VARCHAR2
    *
    * @author      Sérgio Cunha
    * @version     
    * @since       13/06/2014
    *
    ********************************************************************************************/
    FUNCTION get_presc_info_icons
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * @author      Pedro Teixeira
    * @since       20/06/2014
    *********************************************************************************************/
    FUNCTION get_last_request_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This functions returns 'Y' if all the prescriptions for a product are cancelled.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional ID / Institution ID / Software ID
    * @param   i_id_episode               Episode ID
    * @param   i_product                  Product description
    *
    * @return                             (Y) All prescriptions are cancelled. 
    *                                     (N) At least one prescription is not cancelled.
    *
    * @author  José Brito
    * @version 2.6.4.2
    * @since   05/09/2014
    *
    ********************************************************************************************/
    FUNCTION check_all_cancel_presc_by_prod
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN presc.id_epis_create%TYPE,
        i_product    IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * pk_api_pfh_in.get_entity_desc_by_grant
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRODUCT                            IN        VARCHAR2
    * @param  I_ID_PRODUCT_SUPPLIER                   IN        VARCHAR2
    * @param  I_CODE_PRODUCT                          IN        VARCHAR2
    * @param  I_CODE_SYNONYM                          IN        VARCHAR2
    * @param  I_ID_PICK_LIST                          IN        NUMBER
    * @param  I_USE_SYNONYM                           IN        VARCHAR2
    * @param  I_ID_DESCRIPTION_TYPE                   IN        NUMBER
    * @param  I_FLG_SYNS_ONLY                         IN        VARCHAR2
    *
    * @return  VARCHAR2
    *
    * @author      Pedro Miranda
    * @version     
    * @since       19/09/2014
    *
    ********************************************************************************************/
    FUNCTION get_entity_desc_by_grant
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_code_product        IN VARCHAR2,
        i_code_synonym        IN VARCHAR2,
        i_id_pick_list        IN NUMBER,
        i_use_synonym         IN VARCHAR2,
        i_id_description_type IN NUMBER DEFAULT 1,
        i_flg_syns_only       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get a string of pharmacy icons for a given prescription ID
    *
    * @author      Alexis Nascimento
    * @version     
    * @since       05/09/2014
    *
    ********************************************************************************************/
    FUNCTION get_presc_pharm_icons
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_presc_type   IN NUMBER,
        i_id_pha_dispense IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_pharm_bg_color
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_presc_type   IN NUMBER,
        i_id_pha_dispense IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_pharm_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc_type   IN NUMBER,
        i_id_pha_dispense IN NUMBER
    ) RETURN NUMBER;

    /********************************************************************************************
    * Return 'Y' or 'N', if the product in medication backoffice was edited or not edited
    *
    * @author      Joel Lopes
    * @version     
    * @since       07/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_product_edit
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional DEFAULT NULL,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return 'Y' or 'N', if the product in medication backoffice is or isn't a composite product
    *
    * @author      Joel Lopes
    * @version     
    * @since       07/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_prod_comp
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional DEFAULT NULL,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Initialize params for filters search (Replacing The prescribed medication)
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name
    *
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Joana Madureira Barroso
    * @version                       2.6.4.2.1
    * @since                         2014/10/02
    **********************************************************************************************/
    PROCEDURE init_params_product_replace
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_my_src_entity
    (
        i_lang                IN language.id_language%TYPE,
        i_inn_search          IN VARCHAR2,
        i_brand_search        IN VARCHAR2,
        i_id_description_type IN NUMBER
    ) RETURN table_t_search;

    /**********************************************************************************************
    * Gets information about print list job related to the medication
    * Used by print list
    *
    * @param     i_lang               Professional preferred language
    * @param     i_prof               Professional identification and its context (institution and software)
    * @param     i_id_print_list_job  Print list job identifier, related to the referral
    *
    * @return    t_rec_print_list_job Print list job information
    *                        
    * @author    Pedro Teixeira
    * @version   2.6.4.2.1 - issue ALERT-281418 
    * @since     14/10/2014
    **********************************************************************************************/
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    /**********************************************************************************************
    * Compares if a print list job context data is similar to the array of print list jobs
    * Used by print list
    *
    * @param     i_lang                         Professional preferred language
    * @param     i_prof                         Professional identification and its context (institution and software)
    * @param     i_print_job_context_data       Print list job context data
    * @param     i_print_list_jobs              Array of print list job identifiers
    *
    * @return    table_number                   Arry of print list jobs that are similar
    *                        
    * @author    Pedro Teixeira - based on code by ana.monteiro
    * @version   2.6.4.2.1 - issue ALERT-281418 
    * @since     14/10/2014
    **********************************************************************************************/
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_presc_print_list_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_rowids          IN table_varchar,
        o_id_patient      OUT patient.id_patient%TYPE,
        o_id_episode      OUT episode.id_episode%TYPE,
        o_print_list_area OUT NUMBER,
        o_id_workflow     OUT table_number,
        o_id_presc        OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION update_list_job_prescs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN table_number,
        i_action_type IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_api_pfh_in.get_info_button_med_ddi
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_ELEMENTS                           IN        TABLE_VARCHAR
    * @param  O_ID_RXNORM                             OUT       TABLE_VARCHAR
    * @param  O_DESC_RXNORM                           OUT       TABLE_VARCHAR
    * @param  O_TERMINOLOGY                           OUT       TABLE_VARCHAR
    *
    * @return  BOOLEAN
    *
    * @author      Pedro Miranda
    * @version     
    * @since       03/11/2014
    *
    ********************************************************************************************/
    FUNCTION get_info_button_med_therap
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN NUMBER,
        i_id_elements IN table_varchar,
        o_id_rxnorm   OUT table_varchar,
        o_desc_rxnorm OUT table_varchar,
        o_terminology OUT table_varchar
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * alert_product_mt.pk_product.get_product_icons
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_SESSION_DATA                          IN        SESSION_DATA
    * @param  I_ID_PRODUCT                            IN        VARCHAR2(120)
    * @param  I_ID_PRODUCT_SUPPLIER                   IN        VARCHAR2(120)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.2.4
    * @since       18/11/2014
    *
    ********************************************************************************************/

    FUNCTION get_product_icons
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_product              IN VARCHAR2 DEFAULT NULL,
        i_id_product_supplier     IN VARCHAR2 DEFAULT NULL,
        i_tbl_id_product          IN table_varchar DEFAULT table_varchar(),
        i_tbl_id_product_supplier IN table_varchar DEFAULT table_varchar(),
        i_id_picklist             IN NUMBER DEFAULT NULL,
        i_id_grant                IN NUMBER DEFAULT NULL,
        i_chk_prod_restrictions   IN NUMBER DEFAULT 0,
        i_flg_needs_dilution      IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_product_search_by_name
    (
        i_lang              language.id_language%TYPE,
        i_prof              profissional,
        i_syn_str           IN VARCHAR2,
        i_prd_str           IN VARCHAR2,
        i_search            IN VARCHAR2,
        i_column_name       IN VARCHAR2,
        i_description_type  IN NUMBER,
        i_id_pick_list      IN NUMBER,
        i_id_market         IN NUMBER,
        i_flg_similar_prods IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_grant_group       IN NUMBER DEFAULT NULL
    ) RETURN t_tab_product_search;

    /********************************************************************************************
    * alert_product_tr.pk_api_med_out.get_supply_source_pat_desc
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Pedro Miranda
    * @version     
    * @since       02/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_supply_source_pat_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the external prescription directions
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_episode        Episode ID
    * @param  i_id_visit          Visit ID
    * @param  i_id_patient        Patient ID
    * @param  o_local_presc_dirs  Cursor with data
    * @param  o_error             Error object
    *
    * @return true/false
    *
    * @author Sofia Mendes
    * @since  12/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_list_ext_presc_dirs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN episode.id_visit%TYPE,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_presc   IN presc.id_presc%TYPE,
        o_presc_dirs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_api_pfh_in.get_std_version_date
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  O_ID_VERSION                            OUT       VARCHAR2
    * @param  O_PUBLISH_DATE                          OUT       VARCHAR2
    *
    *
    *
    * @author      Pedro Miranda
    * @version     
    * @since       24/12/2014
    * @issue       ALERT-293097
    *
    ********************************************************************************************/
    PROCEDURE get_std_version_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_id_version   OUT VARCHAR2,
        o_publish_date OUT VARCHAR2
    );

    /********************************************************************************************
    * Get the product price
    *
    * @param  i_lang                          Language ID
    * @param  i_prof                          Professional info array
    * @param  i_tbl_id_product                Product ID
    * @param  i_tbl_id_product_supplier       Product supplier ID
    * @param  i_id_price_type                 Price type ID
    *
    * @return Formatted text with product price
    *
    * @author Jose Brito
    * @since  30/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_prod_unit_price
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_tbl_id_product          IN table_varchar DEFAULT table_varchar(),
        i_tbl_id_product_supplier IN table_varchar DEFAULT table_varchar(),
        i_id_price_type           IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Calculate the Rx overall treatment cost.
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_episode        Episode ID
    * @param  i_id_patient        Patient ID
    * @param  i_id_presc_group    Prescription group ID
    *
    * @return Treatment cost by prescription group
    *
    * @author Jose Brito
    * @since  12/01/2015
    *
    ********************************************************************************************/
    FUNCTION calc_overall_treatment_cost
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_presc_group IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * alert_product_tr.pk_presc_cosign.get_medication_description
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_medication_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * alert_product_tr.pk_presc_cosign.get_medication_instructions
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_medication_instructions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_cosign_action_description
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_task         NUMBER,
        i_id_action       IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * alert_product_tr.pk_presc_cosign.get_med_admin_description
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC_PLAN                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_med_admin_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc_plan   IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * alert_product_tr.pk_presc_cosign.get_med_admin_instructions
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  i_id_presc_plan                         IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_med_admin_instructions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc_plan   IN NUMBER,
        i_id_co_sign_hist IN NUMBER
        
    ) RETURN VARCHAR2;

    FUNCTION get_presc_doses_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN presc.id_patient%TYPE,
        i_id_presc     IN table_number,
        i_id_task_type IN NUMBER,
        i_tbl_xml      IN table_varchar DEFAULT NULL,
        o_doses_info   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the id cds call of the prescriptions associated to the i_products 
    * in the visit of the given id_episode
    *
    * @param  I_LANG                 language identifier                            
    * @param  I_PROF                 professional infor                          
    * @param  i_id_episode           episode id   
    * @param  i_id_product           Product Ids   
    * @param  i_id_product_supplier  Product supplier Ids                 
    * @param  i_id_call              cdr call id                    
    * @param  O_ERROR                error info                    
    *
    * @author      Sofia Mendes
    * @version     2.6.5
    * @since       28/05/2015
    ********************************************************************************************/
    FUNCTION set_presc_cds_id_call
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN presc.id_epis_upd%TYPE,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_call             IN NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get FLG_EDITED for a given prescription ID
    *
    * @param  I_LANG                 The language id
    * @param  I_PROF                 The profissional
    * @param  I_ID_PRESC             Prescription ID
    *
    * @return  PL/SQL VARCHAR2
    *
    * @author      Pedro Teixeira
    * @version     
    * @since       30/06/2015
    *
    ********************************************************************************************/
    FUNCTION get_presc_flg_edited
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * alert_product_tr.pk_presc_core.get_presc_by_prod_search
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_EPISODE                            IN        NUMBER(22,24)
    * @param  I_SEARCH_VALUE                          IN        VARCHAR2
    *
    * @return  PUBLIC.TABLE_NUMBER
    *
    * @author      Alexis Nascimento
    * @version     2.6.5.0.3
    * @since       08/07/2015
    *
    ********************************************************************************************/

    FUNCTION get_presc_by_prod_search
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN presc.id_epis_create%TYPE,
        i_search_value          IN VARCHAR2,
        i_flg_search_by_patient IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_number;

    /*********************************************************************************************
    *  This function will return the product group description for group type configured
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        product group description
    *
    * @author                        Vitor Reis
    * @version                       2.6.5.0.3
    * @since                         2015/07/10
    *********************************************************************************************/

    FUNCTION get_product_category_descr
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN r_presc.id_presc%TYPE,
        i_id_grant IN NUMBER
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    *  This function will return the product group rank for group type configured
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        product group rank
    *
    * @author                        Vitor Reis
    * @version                       2.6.5.0.3
    * @since                         2015/07/10
    *********************************************************************************************/

    FUNCTION get_product_category_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN r_presc.id_presc%TYPE,
        i_id_grant IN NUMBER
    ) RETURN NUMBER;

    /*********************************************************************************************
    *  This function will return the number of prescriptions of all active institutions
    *
    * @param i_number_of_days        number(24)
    *
    * @return                        number 
    *
    * @author                        Alexis Nascimento
    * @version                       2.6.5.0.4
    * @since                         2015/08/11
    *********************************************************************************************/
    FUNCTION get_prescriptions_noc(i_number_of_days NUMBER DEFAULT NULL) RETURN NUMBER;

    /*********************************************************************************************
    *  This function will return the product group id for a given prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        product group id
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.5
    * @since                         2015/09/21
    *********************************************************************************************/
    FUNCTION get_presc_category_id
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN presc.id_presc%TYPE,
        i_id_grant IN NUMBER
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    *  This function will return the prescription's start date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription start date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_presc_start_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /*********************************************************************************************
    *  This function will return the prescription interruption date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription interruption date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_presc_interruption_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /*********************************************************************************************
    *  This function will return the prescription suspension date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription suspension date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_presc_suspension_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /*********************************************************************************************
    *  This function will return the administration start date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        administration start date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_admin_start_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * Check if the product supplier are available in the market
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                The profissional information array
    * @param i_id_product_supplier Product supplier id    
    *
    * @return                      VARCHAR2 ('Y' or 'N')
    *
    * @author                      CRISTINA.OLIVEIRA
    * @version                     2.6.5.1
    * @since                       2016/03/11
    ********************************************************************************************/
    FUNCTION check_supplier_mkt_available
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * Inserts given department id into tbl_temp
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             Current professional
    * @param i_id_department    Department id
    *
    * @author                   rui.mendonca
    * @version                  2.6.5.2
    * @since                    2016/06/06
    **********************************************************************************************/
    PROCEDURE ins_prof_dept_into_tbl_temp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN NUMBER
    );

    /********************************************************************************************
    * This function returns the end date of the last administration for a prescription
    *
    * @param  i_lang                     The language ID
    * @param  i_prof                     The professional array
    * @param  i_id_presc                 Prescription List
    *
    * @return                            TIMESTAMP
    *
    * @author                            CRISTINA.OLIVEIRA
    * @since                             15/06/2016
    ********************************************************************************************/
    FUNCTION get_end_date_last_adm
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**************************************************************************
    **************************************************************************/
    FUNCTION get_favorite_prefix_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_favorite IN NUMBER
    ) RETURN VARCHAR2;

    /**************************************************************************
    **************************************************************************/
    FUNCTION get_favorite_suffix_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_favorite IN NUMBER
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * Returns the instructions descriptions to the favorites filter
    *
    * @param i_lang                         The ID of the user language
    * @param i_prof                         Current professional
    * @param i_id_product_favorite          Favorite ID
    * @param i_id_presc_directions          Presc directions ID
    *
    * @author                   Sofia Mendes
    * @version                  2.7.0
    * @since                    2016/12/02
    **********************************************************************************************/
    FUNCTION get_favorite_instructions_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_favorite IN NUMBER,
        i_id_presc_directions IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (home medication list)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           07/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_hm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (local medication list)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *          'O' - Unfinished prescriptions / ongoing prescriptions
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           07/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_lm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (ambulatory medication list)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *          'O' - Unfinished prescriptions / ongoing prescriptions
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           07/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_am
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (pharmacy validations)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *          'O' - Unfinished prescriptions / ongoing prescriptions
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           09/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_pv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the pharmacy validation info icon if the pharmacist added any notes
    *
    * @param   i_lang      IN  language.id_language%TYPE
    * @param   i_prof      IN  profissional
    * @param   i_id_presc  IN  presc.id_presc%TYPE
    * 
    * @return  VARCHAR2
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           21/12/2016
    ********************************************************************************************/
    FUNCTION get_pharm_validation_info_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the background color for the end date cell at the admin and tasks tab
    *
    * @param  i_lang     Language id
    * @param  i_prof     Professional type
    * @param  i_id_presc Prescription id
    *
    * @return VARCHAR2
    *
    * @author  rui.mendonca
    * @version 2.7.1.1
    * @since   23/06/2017
    ********************************************************************************************/
    FUNCTION get_dt_end_bg_color
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    FUNCTION add_print_list_jobs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_presc                IN table_varchar,
        i_json_list               IN table_varchar,
        i_prescription_print_type IN VARCHAR2,
        o_print_list_job          OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the pharmacy dispense details. Function for populating the grid with information
    * regarding the dispense status.Checks for interface information if there is no information 
    * associated
    *
    * @param   i_lang              language.id_language%TYPE
    * @param   i_prof              profissional
    * @param   i_id_presc          Prescription ID
    * @param   i_id_pha_dispense   Dispense ID
    * 
    * @return  varchar
    *
    * @author   João Coutinho  
    * @version  2.7.2   
    * @since  15/11/2017
    ********************************************************************************************/
    FUNCTION get_pharm_dispense_details
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_presc            IN r_presc.id_presc%TYPE,
        i_id_pha_dispense     IN VARCHAR2,
        i_id_pha_dispense_det IN NUMBER DEFAULT NULL,
        i_id_pha_return       IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function to check if a certain cancelled dispensed should still be shown
    *
    * @param   i_lang             Language ID
    * @param   i_prof             Professional ID
    * @param   i_id_episode       Prescription ID
    * @param   i_id_pha_dispense  Dispense ID
    *
    * @return  VARCHAR
    *
    * @author          João Coutinho
    * @version         2.7.2.2
    * @since           13/12/2017
    ********************************************************************************************/
    FUNCTION get_pha_disp_cancel_show
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pha_dispense IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Initialize params for filters - Pharmacy Dispense
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        João Coutinho
    * @version                       2.7.2.3
    * @since                         15/01/2018
    **********************************************************************************************/
    PROCEDURE init_params_pharm_dispense
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

    /**
    *  This function updates the episode temp id to the definitive one in the pharmacy table
    * To be used in match functionality
    *
    * @param      I_LANG                      Language id
    * @param      i_prof                      Professional, institution and software ids
    * @param      i_episode_temp              Temporary episode ID
    * @param      i_episode                   Definitive episode ID
    * @param      o_error                     Error message
    *
    * @return     BOOLEAN             TRUE if sucess, FALSE otherwise
    *
    * @author     Sofia Mendes
    * @since      16/01/2018
    */
    FUNCTION match_episode_pharmacy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function updates the patient temp id to the definitive one in the pharmacy table.
    * To be used in match functionality
    *
    * @param      I_LANG                      Language id
    * @param      i_prof                      Professional, institution and software ids
    * @param      i_patient_temp              Temporary patient ID
    * @param      i_patient                   Definitive patient ID
    * @param      o_error                     Error message
    *
    * @return     BOOLEAN             TRUE if sucess, FALSE otherwise
    *
    * @author     Sofia Mendes
    * @since      16/01/2018
    */
    FUNCTION match_patient_pharmacy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_temp IN patient.id_patient%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pharm_presc_prop_by_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN presc.id_presc%TYPE,
        i_prop_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_dispense_return_icon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER,
        i_id_pha_return   IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_dispense_return_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER,
        i_id_pha_return   IN NUMBER,
        i_id_task         IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    /******************************************************************************
    * get pharmacy status string
    ******************************************************************************/
    FUNCTION get_pharm_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_workflow     IN v_pha_review.id_workflow%TYPE,
        i_id_status       IN v_pha_review.id_status%TYPE,
        i_dt_status       IN v_pha_review.dt_status%TYPE,
        i_id_pha_dispense IN NUMBER DEFAULT NULL,
        i_id_pha_return   IN NUMBER DEFAULT NULL,
        i_id_presc        IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_revised_prof_id
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN presc.id_presc%TYPE,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    --******************************************************************
    FUNCTION get_pha_status_icon
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_pha_return    IN NUMBER,
        i_pha_dispense  IN NUMBER,
        i_status_review IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_pha_bg_color
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_pha_return   IN NUMBER,
        i_presc        IN NUMBER,
        i_pha_dispense IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_correct_workflow
    (
        i_pha_return   IN NUMBER,
        i_pha_dispense IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_correct_id_status
    (
        i_pha_return    IN NUMBER,
        i_pha_dispense  IN NUMBER,
        i_status_review IN NUMBER
    ) RETURN NUMBER;

    -- ********************************************
    FUNCTION get_correct_dt_status
    (
        i_pha_return   IN NUMBER,
        i_pha_dispense IN NUMBER,
        i_dt_status    IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    -- *************************************************************
    FUNCTION get_pha_status_str
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_pha_return    IN NUMBER,
        i_pha_dispense  IN NUMBER,
        i_status_review IN NUMBER,
        i_dt_creat_disp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_pha_cars
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    FUNCTION inactivate_presc_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_allow_label_print
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_prepare_label_print_label
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_presc_plan IN NUMBER
    ) RETURN CLOB;

    FUNCTION get_amb_dispense_print_label
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_code_patient_instructions IN pk_translation.t_desc_translation,
        i_id_pha_dispense           IN NUMBER,
        i_id_task                   IN NUMBER,
        i_id_patient                IN NUMBER,
        i_pat_name                  IN pk_translation.t_desc_translation,
        i_rownum                    IN NUMBER,
        i_nr_of_labels              IN NUMBER,
        i_cfg_value                 IN pk_translation.t_desc_translation,
        i_cfg_label_y_start         IN NUMBER DEFAULT NULL,
        i_cfg_label_y_increment     IN NUMBER DEFAULT NULL,
        i_cfg_label_height          IN NUMBER DEFAULT NULL,
        i_cfg_label_chars_by_line   IN NUMBER DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_local_dispense_print_label
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_single_label        IN VARCHAR2 DEFAULT 'N',
        i_id_pha_dispense         IN NUMBER DEFAULT NULL,
        i_id_product              IN pk_translation.t_desc_translation,
        i_id_product_supplier     IN pk_translation.t_desc_translation,
        i_qty_dispensed           IN NUMBER,
        i_id_unit_mea_dispensed   IN NUMBER,
        i_dt_expiration_product   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_task                 IN NUMBER,
        i_id_patient              IN NUMBER,
        i_id_episode              IN NUMBER,
        i_pat_name                IN pk_translation.t_desc_translation,
        i_rownum                  IN NUMBER,
        i_nr_of_labels            IN NUMBER,
        i_cfg_value               IN pk_translation.t_desc_translation,
        i_barcode                 IN VARCHAR2 DEFAULT NULL,
        i_cfg_label_y_start       IN NUMBER DEFAULT NULL,
        i_cfg_label_y_increment   IN NUMBER DEFAULT NULL,
        i_cfg_label_height        IN NUMBER DEFAULT NULL,
        i_cfg_label_chars_by_line IN NUMBER DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Verifies if the given product is a high alert
    *
    * @param   i_lang                 language 
    * @param   i_id_product           Product 
    * @param   i_id_product_supplier  Supplier
    *
    * @return  Y - the product is a high  N-otherwise
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.7.2
    * @since   20/04/2018
    */
    FUNCTION is_product_high_alert
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_grant            IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_pha_depts
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    /********************************************************************************************
    * Returns the number of refills and date for a given episode 
    *
    * @param   i_lang             language
    * @param   i_id_episode       Episode ID
    * 
    * @return  VARCHAR2
    *
    * @author          CRISTINA.OLIVEIRA
    * @version         2.7.0.0
    * @since           02/05/2018
    ********************************************************************************************/
    FUNCTION get_review_refill_date
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN r_presc.id_last_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function that returns the products description associated to a dispense record
    *
    * @param i_lang              IN  language.id_language%TYPE      Language ID
    * @param i_prof              IN  profissional                   Professional structure data
    * @param i_id_pha_dispense   Pha dispense id
    * @param i_id_task           Prescription id
    * @param i_id_task_type      Task type id
    *
    * @author   Sofia Mendes
    * @version  2.7.3
    * @since    17/05/2018            
    ********************************************************************************************/
    FUNCTION get_dispense_products_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER,
        i_id_task         IN NUMBER,
        i_id_task_type    IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_dt_last_take
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_count_dt_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_workflow IN NUMBER
        
    ) RETURN NUMBER;

    PROCEDURE init_params_patient_grids
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

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_home_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_presc_prod_restrictions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN NUMBER,
        i_id_pick_list IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_check_co_sign
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN alert.profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_check_prod_pat_weight
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_presc                  IN NUMBER,
        o_id_patient                OUT patient.id_patient%TYPE,
        o_flg_prod_weight_mandatory OUT VARCHAR2,
        o_flg_invalid_weighing      OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pharm_car_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_pha_car IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION count_patient_by_car
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_pha_car IN NUMBER
    ) RETURN NUMBER;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION location_by_car
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_status    IN NUMBER,
        i_desc_service IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/

    FUNCTION get_prepare_ivroom_print_label
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_dispense   IN NUMBER,
        i_id_presc_plan IN NUMBER
    ) RETURN CLOB;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION get_all_product_routes
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN table_varchar;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION get_all_product_inn
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN table_varchar;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION inactivate_pharm_dispense
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pharm_dispense_ivroom_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER
    ) RETURN NUMBER;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION get_product_price_lst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_patient          IN NUMBER
    ) RETURN table_varchar;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_presc_out_on_pass
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN presc.id_epis_create%TYPE,
        i_first_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_last_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_presc_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION set_presc_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_presc            IN table_number,
        i_id_epis_out_on_pass IN NUMBER,
        i_first_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_last_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION complete_presc_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_epis_out_on_pass IN NUMBER,
        i_dt_in_returned      IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the prescriptions out ou pass to complete
    *
    * @param      i_lang                Língua registada como preferência do profissional
    * @param      I_PROF                Profissional que acede
    * @param      i_id_episode          Episode Id
    * @param      i_id_epis_out_on_pass Epis out on pass detail record identifier
    * @param      o_presc_data          Output cursor with prescriptions info.
    * @param      O_ERROR               erro
    *
    * @return     boolean
    * @author     CRISTINA.OLIVEIRA
    * @since      2019-05-23
    ********************************************************************************************/
    FUNCTION get_presc_out_on_pass_complete
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN presc.id_epis_create%TYPE,
        i_id_epis_out_on_pass     IN NUMBER,
        i_flg_html                IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_force_pp_oop_status IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        o_presc_data              OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Initialize params for pharmacy cars configurations by service grid
    *
    * @param i_context_ids            array with context ids
    * @param i_name                   parammeter name
    *
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author  Sofia Mendes
    * @version 2.8.1
    * @since   03-12-2019
    */

    PROCEDURE init_params_cars
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_unidose_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_pharm_slots
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * Get default values for the dynamic screen creation of car configurations by service
    *
    * @param   i_tbl_id_pk    receives id_pha_car_model
    *
    * @author          Sofia Mendes
    * @since           05/12/2019
    ********************************************************************************************/
    FUNCTION get_values
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

    FUNCTION get_pha_car_model_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pha_car_model IN NUMBER,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pha_car_model_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pha_car_model IN NUMBER,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prescs_grouped_by_prod
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_antibiotic   IN VARCHAR2,
        i_last_x_h         IN NUMBER DEFAULT NULL,
        o_grouped_products OUT t_tbl_prescs_grouped_by_prod,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the number of credits of a PP Light profile
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    *
    * @return number                        
    * @author   CRISTINA.OLIVEIRA
    * @since    2020-12-10
    ********************************************************************************************/
    FUNCTION get_light_license_credits
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    /*************************************************************************************************
    *************************************************************************************************/
    FUNCTION presc_is_copy_other_epis
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /*************************************************************************************************
    *************************************************************************************************/
    FUNCTION get_allow_show_all_med
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Initialize params for filters search (Reconciliation Medication )
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        cristina.oliveira
    * @version                       2.8.2.4
    * @since                         2021/04/13
    **********************************************************************************************/
    PROCEDURE init_params_reconciliation
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /***********************************************************************************************************
    * Return icon for a given prescription:
    *
    *
    * @param i_id_presc             prescription id
    *
    * @return varchar2
    *
    * @author  Alexis Nascimento
    * @since   2014/02/25
    ************************************************************************************************************/
    FUNCTION get_presc_icon_untyped(i_id_presc IN NUMBER) RETURN VARCHAR2;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION is_parent_presc_pending_val
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /***********************************************************************************************************
    * Check if a given prescription is migrated
    *
    * @return 'Y' / 'N'
    *
    * @author  Pedro Teixeira
    * @since   2013/03/07
    ************************************************************************************************************/
    FUNCTION check_presc_migrated(i_id_presc IN NUMBER) RETURN VARCHAR;

    FUNCTION presc_is_home_care
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION presc_is_episode_home_care
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_presc   IN NUMBER,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION presc_is_prod_visit_active
    (
        i_id_unique IN VARCHAR2,
        i_id_visit  IN episode.id_visit%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns clinical purposes for a given set of products
    * for the specified patient and episode
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PATIENT    Patient ID
    * @param  I_ID_EPISODE    Episode ID
    * @param  i_id_product    Product ID
    * @param  i_id_product_supplier  Product Supplier ID
    * @param  i_id_presc_type_rel    TPrescription type
    *
    * @author  Cristina Oliveira
    ********************************************************************************************/
    FUNCTION get_clinical_purpose_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN presc.id_patient%TYPE,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_presc_type_rel   IN NUMBER,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_purpose_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN presc.id_patient%TYPE,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_presc_type_rel   IN NUMBER
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * This function returns the list of diagnosis / problems / habits / allergies
    * for the specified patient and episode
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PATIENT    Patient ID
    * @param  I_ID_EPISODE    Episode ID
    *
    * @author  Pedro Teixeira
    * @since   2011-10-13
    *
    ********************************************************************************************/
    FUNCTION get_diag_problem_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN presc.id_epis_create%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_problem_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN presc.id_epis_create%TYPE
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * This procedure gets a list of admin sites for given route
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                  array with the professional information
    * @param i_id_route            The route
    * @param i_id_route_supplier   The route supplier
    * @param o_admin_site          The adverse reaction list
    *
    * @author  Pedro Quinteiro
    * @version alpha
    * @since   2012/02/23
    ********************************************************************************************/
    FUNCTION get_presc_list_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2 DEFAULT NULL,
        i_id_product_supplier IN VARCHAR2 DEFAULT NULL,
        i_presc_list_type     IN NUMBER,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_presc_list_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2 DEFAULT NULL,
        i_id_product_supplier IN VARCHAR2 DEFAULT NULL,
        i_presc_list_type     IN NUMBER
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * This procedure gets a list of admin sites for given route
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                  array with the professional information
    * @param i_id_route            The route
    * @param i_id_route_supplier   The route supplier
    * @param o_admin_site          The adverse reaction list
    *
    * @author  Pedro Quinteiro
    * @version alpha
    * @since   2012/02/23
    ********************************************************************************************/
    FUNCTION get_admin_method_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE,
        o_info              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admin_method_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * This procedure gets a list of admin sites for given route
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                  array with the professional information
    * @param i_id_route            The route
    * @param i_id_route_supplier   The route supplier
    * @param o_admin_site          The adverse reaction list
    *
    * @author  Pedro Quinteiro
    * @version alpha
    * @since   2012/02/23
    ********************************************************************************************/
    FUNCTION get_admin_site_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE,
        o_info              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admin_site_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN t_tbl_core_domain;

    /*********************************************************************************************
    *  This function will return the prescription resume date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription suspension date
    *
    * @author                        Cristina Oliveira
    * @version                       2.8.3.1
    * @since                         2021/07/23
    *********************************************************************************************/
    FUNCTION get_presc_resume_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_cancel_reasons_by_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_presc_list_type IN NUMBER
    ) RETURN t_tbl_core_domain;

    FUNCTION get_presc_rate_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_presc_list_type     IN NUMBER,
        i_context             IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_core_domain;

    FUNCTION get_process_status_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_frequencies_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_freq_type           IN NUMBER
    ) RETURN t_tbl_core_domain;

    FUNCTION pharm_is_out_of_stock_by_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN NUMBER,
        i_id_status IN NUMBER --g_wf_declined, g_wf_on_hold
    ) RETURN VARCHAR2;

    FUNCTION get_review_flg_remove_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_task IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_pharm_show_alert_out_of_stock
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_presc_disp_method(i_id_presc IN NUMBER) RETURN NUMBER;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_notes_serialized
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_dispense_type(i_id_presc IN NUMBER) RETURN VARCHAR2;

    /**
    * Verifies if the given product is GLP-1 receptor agonists in PEMAMB
    *
    * @param   i_lang                 language 
    * @param   i_id_product           Product 
    * @param   i_id_product_supplier  Supplier
    *
    * @return  Y - the product is a GLP-1 receptor agonists. N-otherwise
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.8
    * @since   02/02/2023
    */
    FUNCTION check_product_is_glp1agonist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_grant            IN NUMBER
    ) RETURN VARCHAR2;

END pk_api_pfh_in;
/
