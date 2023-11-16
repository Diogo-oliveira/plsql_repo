/*-- Last Change Revision: $Rev: 2050863 $*/
/*-- Last Change by: $Author: pedro.teixeira $*/
/*-- Date of last change: $Date: 2022-11-23 17:38:31 +0000 (qua, 23 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_ordertools_in IS

    -- purpose: order tools database api for incomming data

    /********************************************************************************************
    * copy to a new prescription all instructions from an existing prescription
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id (copy from)
    * @param       i_id_patient           patient id
    * @param       i_id_episode           episode id
    * @param       o_id_presc             prescription id (copy to)
    * @param       o_error                structure for error handling
    *   
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              22-JUL-2011
    ********************************************************************************************/
    FUNCTION copy_medication_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_presc   IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_id_patient IN pk_rt_med_pfh.r_presc.id_patient%TYPE DEFAULT NULL, -- nullable for tools area
        i_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE DEFAULT NULL, -- nullable for tools area
        o_id_presc   OUT pk_rt_med_pfh.r_presc.id_presc%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete existing prescription (to use only in CPOE drafts and temporary prescriptions)
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id 
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              22-JUL-2011
    ********************************************************************************************/
    FUNCTION delete_medication_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * get medication directions string for any given prescription detail
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    * @param       i_flg_complete         controls if descriptives show all information, or only 
    *                                     significative instructions (without dates) 
    *
    * @return      varchar2               directions string based on the parameterized presc_dir 
    *                                     string
    *
    * @author                             Carlos Loureiro
    * @since                              25-JUL-2011
    **********************************************************************************************/
    FUNCTION get_medication_directions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_complete IN VARCHAR2 DEFAULT pk_rt_med_pfh.g_yes
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * get the name of the product(s) for a given prescription
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    *
    * @return      varchar2               description of the product(s)
    *
    * @author                             Carlos Loureiro
    * @since                              25-JUL-2011
    **********************************************************************************************/
    FUNCTION get_medication_description
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * get the icon that distinguishes the different types of medication / workflows for a given 
    * prescription
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    *
    * @return      varchar2               prescription type's icon name
    *
    * @author                             Carlos Loureiro
    * @since                              25-JUL-2011
    **********************************************************************************************/
    FUNCTION get_medication_type_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************
    * set medication co-sign info
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    * @param       i_prof_co_sign         ordering professional
    * @param       i_order_type           request order type
    * @param       i_dt_co_sign           request order date
    * @param       i_co_sign_notes        request order notes
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              09-AUG-2011
    **********************************************************************************************/
    FUNCTION set_medication_co_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_prof_co_sign  IN NUMBER,
        i_order_type    IN NUMBER,
        i_dt_co_sign    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_co_sign_notes IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * get medication conflicts
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    * @param       i_flg_check_cosign     indicates if co-sign conflicts must be checked or not
    * @param       o_flg_conflicts        flag the indicates if the prescription has conflicts or not
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              09-AUG-2011
    **********************************************************************************************/
    FUNCTION get_medication_conflicts
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_check_cosign IN VARCHAR2,
        o_flg_conflicts    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * set medication request
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_patient              patient id
    * @param       i_episode              episode id
    * @param       i_presc                prescription ids
    * @param       i_cdr_call             clinical decision rule call id
    * @param       o_presc                new prescription ids
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              09-AUG-2011
    **********************************************************************************************/
    FUNCTION set_request_medication
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_presc    IN table_number,
        i_cdr_call IN NUMBER,
        o_presc    OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * set medication execution time
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    * @param       i_flg_execution        flag that indicates the execution time value
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              09-AUG-2011
    **********************************************************************************************/
    FUNCTION set_medication_execution_time
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_execution IN pk_rt_med_pfh.r_presc.flg_execution%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get medication status string
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    * @param       o_status_string        status string
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              10-AUG-2011
    **********************************************************************************************/
    FUNCTION get_medication_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel medication
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_patient              patient id
    * @param       i_episode              episode id
    * @param       i_presc                array of prescription ids
    * @param       i_cancel_reason        array of cancel reason ids
    * @param       i_cancel_notes         array of cancel notes
    * @param       i_dt_cancel            array of cancel dates
    * @param       i_prof_co_sign         ordering professional (co-sign)
    * @param       i_order_type           request order type (co-sign)
    * @param       i_dt_co_sign           request order date (co-sign)
    * @param       o_presc                array of new prescription ids
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              11-AUG-2011
    **********************************************************************************************/
    FUNCTION cancel_medication
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_presc         IN table_number,
        i_cancel_reason IN table_number,
        i_cancel_notes  IN table_varchar,
        i_dt_cancel     IN table_timestamp_tstz,
        i_prof_co_sign  IN NUMBER,
        i_order_type    IN NUMBER,
        i_dt_co_sign    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_presc         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if it's possible to cancel a medication task or not
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_presc                prescription id
    * @param       o_flg_available        flag that indicates if cancel option is available or not for this medication task
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              11-AUG-2011
    **********************************************************************************************/
    FUNCTION check_cancel_medication
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_presc         IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get medication timestamp interval (start/end dates)
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_presc                prescription id
    * @param       o_date_limits          cursor with prescriptions' start/end dates
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              10-OCT-2011
    **********************************************************************************************/
    FUNCTION get_medication_date_limits
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_presc       IN table_number,
        o_date_limits OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * get medication list
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_patient              patient id
    * @param       i_episode              episode id
    * @param       i_task_request         array with prescription request ids
    * @param       i_filter_tstz          timestamp filter 
    * @param       i_filter_status        status filter flags
    * @param       i_flg_report           indicates if task list APIs should return additional report fields
    * @param       i_dt_begin             lower limit of the time interval
    * @param       i_dt_end               upper limit of the time interval
    * @param       o_task_list            cursor with medication tasks
    * @param       o_admin_list           cursor with administration's info
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       i_flg_report           {*} 'Y' additional report columns should be considered by task list APIs
    *                                     {*} 'N' additional report columns should be discarded by task list APIs
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    **********************************************************************************************/
    FUNCTION get_medication_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_report      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_task_list       OUT pk_types.cursor_type,
        o_admin_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_medication_list_cpoe
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_report      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_task_list       OUT pk_types.cursor_type,
        o_admin_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * copy prescription to a new one, in draft status (CPOE)
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_id_patient           patient id
    * @param       i_id_episode           episode id  
    * @param       i_id_presc             precription id
    * @param       i_task_start_timestamp Start date
    * @param       i_task_end_timestamp   End date
    * @param       i_flg_via_job          This function was called via job?
    * @param       o_id_presc             new draft prescription id
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              31-OCT-2011
    **********************************************************************************************/
    FUNCTION copy_medication_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE DEFAULT NULL, -- nullable
        i_id_episode           IN episode.id_episode%TYPE DEFAULT NULL, -- nullable
        i_id_presc             IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_via_job          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_presc             OUT pk_rt_med_pfh.r_presc.id_presc%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * expire medication task, for a given prescription (CPOE)
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_id_patient           patient id
    * @param       i_id_episode           episode id  
    * @param       i_id_presc             precription id array
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              17-JAN-2012
    **********************************************************************************************/
    FUNCTION expire_medication_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_presc   IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get medication task status (CPOE)
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_id_episode           episode id  
    * @param       i_id_presc             precription id array
    * @param       o_presc_status         cursor with prescriptions status
    * @param       o_error                structure for error handling    
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              17-JAN-2012
    **********************************************************************************************/
    FUNCTION get_medication_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_presc     IN table_number,
        o_presc_status OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel/delete all cpoe drafts  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_episode              episode id  
    * @param       o_error                structure for error handling     
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              18-JAN-2012
    ********************************************************************************************/
    FUNCTION delete_medication_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * activate cpoe drafts  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_episode              episode id  
    * @param       i_draft_presc          array with medication drafts to activate
    * @param       i_cdr_call             clinical decision rule id
    * @param       o_created_presc        array with created medication tasks
    * @param       o_error                structure for error handling     
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              19-JAN-2012
    ********************************************************************************************/
    FUNCTION activate_medication_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft_presc   IN table_number,
        i_cdr_call      IN cdr_call.id_cdr_call%TYPE,
        o_created_presc OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              24-JAN-2012
    ********************************************************************************************/
    FUNCTION get_medication_actions
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_presc  IN cpoe_process_task.id_task_request%TYPE,
        o_action OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * resume medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       o_flg_validated        flag that indicates if user needs to validate the 
    *                                     resume action
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       o_flg_validated        {*} 'Y' validated! no user inputs are needed
    *                                     {*} 'N' not validated! user needs to validare this action
    *
    * @author                             Carlos Loureiro
    * @since                              26-JAN-2012
    ********************************************************************************************/
    FUNCTION resume_medication
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_presc         IN cpoe_process_task.id_task_request%TYPE,
        o_flg_validated OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * check if a prescription has all the required fields
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    *
    * @return                             {*} 'Y' has all required fields
    *                                     {*} 'N' has mandatory fields not filled
    *
    * @author                             Tiago Silva
    * @since                              10-MAY-2013
    **********************************************************************************************/
    FUNCTION check_med_mandatory_fields
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if a prescription task needs co-sign to be created
    *
    * @param   i_lang                   language id
    * @param   i_prof                   professional structure
    * @param   i_id_presc               pescription id
    * @param   i_id_episode             episode id
    * @param   o_flg_prof_need_cosign   professional needs cosign? Y - Yes; N - Otherwise 
    * @param   o_error                  error message
    *
    * @return  boolean                  true on success, otherwise false
    *
    * @author                           Tiago Silva
    * @since                            26-MAR-2015
    ********************************************************************************************/
    FUNCTION check_prof_needs_cosign_create
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_presc             IN presc.id_presc%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        o_flg_prof_need_cosign OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if a prescription task needs co-sign to be canceled
    *
    * @param   i_lang                   language id
    * @param   i_prof                   professional structure
    * @param   i_id_presc               pescription id
    * @param   i_id_episode             episode id
    * @param   o_flg_prof_need_cosign   professional needs cosign? Y - Yes; N - Otherwise 
    * @param   o_error                  error message
    *
    * @return  boolean                  true on success, otherwise false
    *
    * @author                           Tiago Silva
    * @since                            26-MAR-2015
    ********************************************************************************************/
    FUNCTION check_prof_needs_cosign_cancel
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_presc             IN presc.id_presc%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        o_flg_prof_need_cosign OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * get the task type id that distinguishes the different types of medication / workflows for a given 
    * prescription
    *
    * @param       i_lang                 language id
    * @param       i_prof                 professional structure
    * @param       i_id_presc             prescription id
    *
    * @return      number                 prescription task type ID
    *
    * @author                             Ariel Machado
    * @since                              18-JUN-2015
    **********************************************************************************************/
    FUNCTION get_medication_task_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- complete medication instructions/directions domain
    g_med_complete_directions_yes CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_yes;
    g_med_complete_directions_no  CONSTANT VARCHAR2(1) := pk_rt_med_pfh.g_no;

    --cpoe_draft
    g_presc_cpoe_draft CONSTANT wf_status_workflow.id_status%TYPE := 73;

END pk_api_pfh_ordertools_in;
/
