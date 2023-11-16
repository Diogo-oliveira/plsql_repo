/*-- Last Change Revision: $Rev: 2054688 $*/
/*-- Last Change by: $Author: pedro.teixeira $*/
/*-- Date of last change: $Date: 2023-01-26 11:35:02 +0000 (qui, 26 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_ordertools_in IS

    -- purpose: order tools database api for incomming data

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    -- declared exceptions
    e_user_exception EXCEPTION;

    /********************************************************************************************
    * function to return the contents of a professional structure in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a professional structure in a string 
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_prof_str(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        IF i_prof IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
        END IF;
    END get_prof_str;

    /********************************************************************************************
    * function to return the contents of a table number in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a table number in a string 
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabnum_str(i_table IN table_number) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'table_number(' || pk_utils.concat_table(i_tab => i_table, i_delim => ',') || ')';
        END IF;
    END get_tabnum_str;

    /********************************************************************************************
    * function to return the contents of a table varchar in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a table varchar in a string
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabvar_str(i_table IN table_varchar) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'table_varchar(' || pk_utils.concat_table(i_tab => i_table, i_delim => ',') || ')';
        END IF;
    END get_tabvar_str;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.copy_medication_task called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_id_presc=' ||
                                  i_id_presc || chr(10) || 'i_id_patient=' || i_id_patient || chr(10) ||
                                  'i_id_episode=' || i_id_episode,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.copy_os_pd_presc function
        IF NOT pk_rt_med_pfh.copy_os_pd_presc(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_presc   => i_id_presc,
                                              i_id_patient => i_id_patient,
                                              i_id_episode => i_id_episode,
                                              o_id_presc   => o_id_presc,
                                              o_error      => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.copy_os_pd_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_MEDICATION_TASK',
                                              o_error);
            RETURN FALSE;
    END copy_medication_task;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.delete_medication_task called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || get_tabnum_str(i_id_presc),
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.delete_presc function
        IF NOT
            pk_rt_med_pfh.delete_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc, o_error => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.delete_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_MEDICATION_TASK',
                                              o_error);
            RETURN FALSE;
    END delete_medication_task;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_directions called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc || chr(10) || 'i_flg_complete=' || i_flg_complete,
                                  g_package_name);
        END IF;
    
        RETURN pk_rt_med_pfh.get_presc_directions(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_presc     => i_id_presc,
                                                  i_flg_complete => i_flg_complete);
    END get_medication_directions;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_description called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.get_presc_description function
        RETURN pk_rt_med_pfh.get_presc_description(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_medication_description;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_type_icon called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.get_presc_type_icon function
        RETURN pk_rt_med_pfh.get_presc_type_icon(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_medication_type_icon;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.set_medication_co_sign called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc || chr(10) || 'i_order_type=' || i_order_type || chr(10) ||
                                  'i_dt_co_sign=' || i_dt_co_sign || chr(10) || 'i_co_sign_notes=' || i_co_sign_notes,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.set_presc_co_sign function
        IF NOT pk_rt_med_pfh.set_presc_co_sign(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_presc      => i_id_presc,
                                               i_prof_co_sign  => i_prof_co_sign,
                                               i_order_type    => i_order_type,
                                               i_dt_co_sign    => i_dt_co_sign,
                                               i_co_sign_notes => i_co_sign_notes,
                                               o_error         => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_presc_co_sign function';
            RAISE e_user_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MEDICATION_CO_SIGN',
                                              o_error);
            RETURN FALSE;
    END set_medication_co_sign;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_conflicts called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.check_presc_conflicts function
        IF NOT pk_rt_med_pfh.check_presc_conflicts(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_presc         => i_id_presc,
                                                   i_flg_check_cosign => pk_alert_constant.g_no,
                                                   o_flg_conflicts    => o_flg_conflicts,
                                                   o_error            => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.check_presc_conflicts function';
            RAISE e_user_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_CONFLICTS',
                                              o_error);
            RETURN FALSE;
    END get_medication_conflicts;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.set_request_medication called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_patient=' || i_patient || chr(10) || 'i_episode=' || i_episode || chr(10) ||
                                  'i_presc=' || get_tabnum_str(i_presc) || chr(10) || 'i_cdr_call=' || i_cdr_call,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.set_os_request_presc function
        IF NOT pk_rt_med_pfh.set_os_request_presc(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_patient  => i_patient,
                                                  i_id_episode  => i_episode,
                                                  i_id_presc    => i_presc,
                                                  i_id_cdr_call => i_cdr_call,
                                                  o_id_presc    => o_presc,
                                                  o_error       => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_os_request_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REQUEST_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END set_request_medication;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.set_medication_execution_time called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc || chr(10) || 'i_flg_execution=' || i_flg_execution,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.set_presc_execution function
        IF NOT pk_rt_med_pfh.set_presc_execution(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_id_presc      => i_id_presc,
                                                 i_flg_execution => i_flg_execution,
                                                 o_error         => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_presc_execution function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MEDICATION_EXECUTION_TIME',
                                              o_error);
            RETURN FALSE;
    END set_medication_execution_time;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_status called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.get_presc_status_icon function
        IF NOT pk_rt_med_pfh.get_presc_status_icon(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_presc    => i_id_presc,
                                                   o_status_icon => o_status_string,
                                                   o_error       => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.get_presc_status_icon function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_medication_status;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.cancel_medication called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_patient=' ||
                                  i_patient || chr(10) || 'i_episode=' || i_episode || chr(10) || 'i_presc=' ||
                                  get_tabnum_str(i_presc) || chr(10) || 'i_cancel_reason=' ||
                                  get_tabnum_str(i_cancel_reason) || chr(10) || 'i_cancel_notes=' ||
                                  get_tabvar_str(i_cancel_notes),
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.cancel_presc function
        IF NOT pk_rt_med_pfh.cancel_presc(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_patient       => i_patient,
                                          i_id_episode       => i_episode,
                                          i_id_presc         => i_presc,
                                          i_id_cancel_reason => i_cancel_reason,
                                          i_notes_cancel     => i_cancel_notes,
                                          i_dt_cancel        => i_dt_cancel,
                                          i_prof_co_sign     => i_prof_co_sign,
                                          i_order_type       => i_order_type,
                                          i_dt_co_sign       => i_dt_co_sign,
                                          o_id_presc         => o_presc,
                                          o_error            => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.cancel_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END cancel_medication;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.check_cancel_medication called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_presc=' || i_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.check_cancel_presc function
        IF NOT pk_rt_med_pfh.check_cancel_presc(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_id_presc      => i_presc,
                                                o_flg_available => o_flg_available,
                                                o_error         => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.check_cancel_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_CANCEL_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END check_cancel_medication;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_date_limits called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_presc=' || get_tabnum_str(i_presc),
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.get_presc_info function
        IF NOT pk_rt_med_pfh.get_presc_info(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_id_presc => i_presc,
                                            o_info     => o_date_limits,
                                            o_error    => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.get_presc_info function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_DATE_LIMITS',
                                              o_error);
            pk_types.open_my_cursor(o_date_limits);
            RETURN FALSE;
    END get_medication_date_limits;

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
    ) RETURN BOOLEAN IS
        l_id_visit                 visit.id_visit%TYPE;
        l_presc_list               t_tbl_cpoe_med_task;
        l_id_prescs                table_number;
        l_drug_take_in_case_prefix pk_types.t_big_char;
        l_aditional_inst_desc      pk_translation.t_desc_translation;
    BEGIN
    
        l_id_visit := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_drug_take_in_case_prefix := (pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_rt_med_pfh.g_msg_sos) || ', ' ||
                                          pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_rt_med_pfh.g_sys_message_take_condition));
        
            l_aditional_inst_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_PRESC_T050') || ': ';
        END IF;
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_list called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_patient=' ||
                                  i_patient || chr(10) || 'i_episode=' || i_episode || chr(10) || ' l_id_visit=' ||
                                  l_id_visit || chr(10) || 'i_task_request=' || get_tabnum_str(i_task_request) ||
                                  chr(10) || 'i_filter_tstz=' || i_filter_tstz || chr(10) || 'i_filter_status=' ||
                                  get_tabvar_str(i_filter_status) || chr(10) || 'i_flg_report=' || i_flg_report,
                                  g_package_name);
        END IF;
    
        SELECT /*+OPT_ESTIMATE(TABLE p ROWS=1)*/
         p.id_presc,
         t_rec_cpoe_med_task(id_presc                => p.id_presc,
                             id_presc_directions     => p.id_presc_directions,
                             id_status               => p.id_status,
                             id_notes                => p.id_notes,
                             id_cds                  => p.id_cds,
                             id_prof_create          => p.id_prof_create,
                             id_prof_upd             => p.id_prof_upd,
                             id_professional_co_sign => p.id_professional_co_sign,
                             task_group_id           => p.task_group_id,
                             task_group_status_rank  => p.task_group_status_rank,
                             flg_edited              => p.flg_edited,
                             flg_prod_replace        => p.flg_prod_replace,
                             task_group_flg_edited   => p.task_group_flg_edited,
                             id_route                => p.id_route,
                             id_route_supplier       => p.id_route_supplier,
                             id_status_desc          => p.id_status_desc,
                             sos_take_condition      => p.sos_take_condition,
                             dt_begin                => p.dt_begin,
                             dt_end                  => p.dt_end,
                             dt_last_update          => p.dt_last_update,
                             dt_first_valid_plan     => p.dt_first_valid_plan,
                             dt_validation_co_sign   => p.dt_validation_co_sign,
                             task_group_date         => p.task_group_date)
          BULK COLLECT
          INTO l_id_prescs, l_presc_list
          FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_patient => i_patient,
                                                               i_id_visit   => l_id_visit)) p
         WHERE p.id_status != pk_rt_med_pfh.st_pre_defined
           AND p.id_workflow NOT IN (pk_rt_med_pfh.wf_ambulatory, pk_rt_med_pfh.wf_report)
           AND ((i_flg_out_of_cpoe = pk_alert_constant.g_yes
               -- discard cancelled, concluded, discontinued or expired task status,
               -- except if they are in the given timestamp range
               AND p.id_status NOT IN
               (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued, pk_rt_med_pfh.st_cpoe_draft) AND
               (p.id_status NOT IN (SELECT /*+OPT_ESTIMATE(TABLE req_status ROWS=1)*/
                                       to_number(req_status.column_value)
                                        FROM TABLE(i_filter_status) req_status)))
               
               OR (i_flg_out_of_cpoe = pk_alert_constant.g_no AND
               (i_task_request IS NULL
               -- discard cancelled, concluded, discontinued or expired task status,
               -- except if they are in the given timestamp range
               AND (p.id_status NOT IN (SELECT /*+OPT_ESTIMATE(TABLE req_status ROWS=1)*/
                                               to_number(req_status.column_value)
                                                FROM TABLE(i_filter_status) req_status) OR ((i_filter_tstz < CASE
                   WHEN p.id_status IN (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued) THEN
                    p.dt_cancel_presc
                   ELSE
                    p.dt_last_update
               END))))
               -- when this api is addressed with requests, it will return only required prescriptions
               OR p.id_presc IN (SELECT /*+OPT_ESTIMATE(TABLE req_filter ROWS=1)*/
                                       req_filter.column_value
                                        FROM TABLE(i_task_request) req_filter)));
    
        IF nvl(cardinality(l_presc_list), 0) > 0
        THEN
            FOR i IN l_presc_list.first .. l_presc_list.last
            LOOP
                BEGIN
                    SELECT gd.task_group_date, gd.task_group_flg_edited, gd.task_group_id, gd.task_group_status_rank
                      INTO l_presc_list(i).task_group_date,
                           l_presc_list(i).task_group_flg_edited,
                           l_presc_list(i).task_group_id,
                           l_presc_list(i).task_group_status_rank
                      FROM TABLE(pk_rt_med_pfh.get_presc_group_data(i_lang, l_presc_list(i).id_presc)) gd;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END LOOP;
        END IF;
    
        -- get medication task list
        OPEN o_task_list FOR
            SELECT task_type,
                   CASE
                        WHEN i_flg_report = pk_alert_constant.g_yes THEN
                         task_title
                        ELSE
                         CASE
                             WHEN length(task_title || ' ' || task_instructions_long) >= 1000 THEN
                              substr(task_title || ' ' || task_instructions_long, 1, 990) || '...'
                             ELSE
                              task_title || ' ' || task_instructions_long
                         END
                    END AS task_description,
                   id_professional,
                   icon_warning,
                   status_str,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   creation_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflict,
                   id_request AS id_task, -- for medication tasks, the prescription id is used for cds handling
                   -- extra report fields
                   decode(i_flg_report, pk_alert_constant.g_yes, task_title, NULL) AS task_title,
                   CASE
                        WHEN length(status_desc || task_instructions_long || CASE
                                        WHEN aditional_instr IS NOT NULL THEN
                                         chr(10) || l_aditional_inst_desc || aditional_instr
                                        ELSE
                                         NULL
                                    END) >= 10000 THEN
                         substr(status_desc || task_instructions_long, 1, 9900) || '...'
                        ELSE
                         status_desc || task_instructions_long || CASE
                             WHEN aditional_instr IS NOT NULL THEN
                              chr(10) || l_aditional_inst_desc || aditional_instr
                             ELSE
                              NULL
                         END
                    END AS task_instructions,
                   task_notes,
                   drug_dose,
                   drug_route,
                   drug_take_in_case,
                   task_status,
                   instr_bg_color,
                   instr_bg_alpha,
                   CASE
                        WHEN (SELECT pk_rt_med_pfh.presc_is_home_care(i_lang     => i_lang,
                                                                      i_prof     => i_prof,
                                                                      i_id_presc => id_request)
                                FROM dual) = pk_alert_constant.g_yes THEN
                         pk_rt_med_pfh.g_home_care_icon
                        ELSE
                         NULL
                    END task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   id_task_type_source,
                   NULL AS id_task_dependency,
                   CASE
                        WHEN flg_status IN (pk_rt_med_pfh.st_cpoe_draft,
                                            pk_rt_med_pfh.st_cancelled,
                                            pk_rt_med_pfh.st_discontinued,
                                            pk_rt_med_pfh.st_presc_cancel_ongoing,
                                            pk_rt_med_pfh.st_presc_discont_ongoing) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_rep_cancel,
                   CASE
                        WHEN flg_status = pk_rt_med_pfh.g_wf_presc_conditional_order THEN
                         pk_alert_constant.g_yes
                        WHEN sos_take_condition IS NOT NULL THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_prn_conditional
              FROM (SELECT /*+OPT_ESTIMATE(TABLE presc ROWS=1)*/
                     NULL AS task_type,
                     (SELECT pk_api_pfh_ordertools_in.get_medication_task_type(i_lang     => i_lang,
                                                                               i_prof     => i_prof,
                                                                               i_id_presc => presc.id_presc)
                        FROM dual) AS id_task_type_source,
                     (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, presc.id_presc, ' +' || chr(10))
                        FROM dual) AS task_title,
                     (SELECT pk_rt_med_pfh.get_presc_directions(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_id_presc            => presc.id_presc,
                                                                 i_flg_html            => pk_rt_med_pfh.g_no,
                                                                 i_flg_complete        => pk_rt_med_pfh.g_yes,
                                                                 i_flg_with_dt_begin   => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_sos        => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_duration   => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_executions => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_dt_end     => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_print_report        => i_flg_report,
                                                                 i_flg_with_new_lines  => CASE
                                                                                              WHEN i_flg_report = pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_yes
                                                                                              ELSE
                                                                                               pk_alert_constant.g_no
                                                                                          END)
                        FROM dual) || (SELECT pk_rt_med_pfh.get_presc_admin_method_desc(i_lang     => i_lang,
                                                                                        i_prof     => i_prof,
                                                                                        i_id_presc => presc.id_presc)
                                         FROM dual) || (SELECT pk_rt_med_pfh.get_presc_admin_site_desc(i_lang     => i_lang,
                                                                                                       i_prof     => i_prof,
                                                                                                       i_id_presc => presc.id_presc)
                                                          FROM dual) ||
                     (SELECT pk_rt_med_pfh.get_presc_duration_desc(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_id_presc => presc.id_presc)
                        FROM dual) AS task_instructions_long,
                     pk_rt_med_pfh.get_patient_instr_desc(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_id_presc => presc.id_presc) aditional_instr,
                     nvl(presc.id_professional_co_sign, nvl(presc.id_prof_upd, presc.id_prof_create)) AS id_professional,
                     (SELECT pk_rt_med_pfh.get_cds_call_icon(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_call      => presc.id_cds,
                                                             i_task_reqs => presc.id_presc)
                        FROM dual) AS icon_warning,
                     (SELECT pk_rt_med_pfh.get_presc_status_icon(i_lang, i_prof, presc.id_presc)
                        FROM dual) AS status_str,
                     presc.id_presc AS id_request,
                     presc.dt_begin AS start_date_tstz,
                     presc.dt_end AS end_date_tstz,
                     nvl(presc.dt_validation_co_sign, presc.dt_last_update) AS creation_date_tstz,
                     presc.id_status AS flg_status,
                     (SELECT pk_rt_med_pfh.check_cancel_presc(i_lang, i_prof, presc.id_presc)
                        FROM dual) AS flg_cancel,
                     decode(presc.id_status,
                            g_presc_cpoe_draft,
                            (SELECT pk_rt_med_pfh.check_presc_conflicts(i_lang, i_prof, presc.id_presc)
                               FROM dual),
                            pk_alert_constant.g_no) AS flg_conflict,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            (SELECT to_char(pk_rt_med_pfh.get_route_desc(i_lang,
                                                                         i_prof,
                                                                         presc.id_route,
                                                                         presc.id_route_supplier,
                                                                         NULL))
                               FROM dual),
                            NULL) AS drug_route,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            pk_translation.get_translation(i_lang => i_lang, i_code_mess => presc.id_status),
                            NULL) AS task_status,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            (SELECT pk_rt_med_pfh.get_dir_item_dose_desc(i_lang              => i_lang,
                                                                         i_prof              => i_prof,
                                                                         i_id_presc_dir_item => presc.id_presc_directions,
                                                                         i_id_presc          => presc.id_presc)
                               FROM dual),
                            NULL) AS drug_dose,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            (SELECT pk_rt_med_pfh.get_last_presc_notes(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_presc_notes => presc.id_notes)
                               FROM dual),
                            NULL) AS task_notes,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            nvl2(presc.sos_take_condition, (l_drug_take_in_case_prefix || presc.sos_take_condition), NULL),
                            NULL) AS drug_take_in_case,
                     (SELECT pk_rt_med_pfh.get_instr_bg_color_by_presc(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_id_presc => presc.id_presc)
                        FROM dual) instr_bg_color,
                     (SELECT pk_rt_med_pfh.get_instr_bg_alpha_by_presc(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_id_presc => presc.id_presc)
                        FROM dual) AS instr_bg_alpha,
                     presc.sos_take_condition,
                     CASE
                          WHEN presc.id_status IN (pk_rt_med_pfh.st_take_suspended,
                                                   pk_rt_med_pfh.st_take_suspended_ongoing,
                                                   pk_rt_med_pfh.st_suspended,
                                                   pk_rt_med_pfh.st_suspended_ongoing) THEN
                           (SELECT pk_translation.get_translation(i_lang, 'WF_STATUS.CODE_STATUS.' || presc.id_status)
                              FROM dual) || ' - '
                          ELSE
                           NULL
                      END status_desc
                      FROM TABLE(l_presc_list) presc
                     ORDER BY CASE (SELECT pk_rt_med_pfh.presc_is_active(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_id_presc => presc.id_presc)
                                  FROM dual)
                                  WHEN pk_alert_constant.g_yes THEN
                                   0
                                  ELSE
                                   1
                              END,
                              (SELECT pk_rt_med_pfh.get_presc_status_rank(i_id_presc => presc.id_presc)
                                 FROM dual),
                              CASE
                                  WHEN (SELECT pk_rt_med_pfh.presc_is_active(i_lang     => i_lang,
                                                                             i_prof     => i_prof,
                                                                             i_id_presc => presc.id_presc)
                                          FROM dual) = pk_alert_constant.g_yes THEN
                                   presc.task_group_date
                                  ELSE
                                   NULL
                              END,
                              CASE
                                   WHEN (SELECT pk_rt_med_pfh.presc_is_active(i_lang     => i_lang,
                                                                              i_prof     => i_prof,
                                                                              i_id_presc => presc.id_presc)
                                           FROM dual) = pk_alert_constant.g_no THEN
                                    presc.dt_last_update
                                   ELSE
                                    NULL
                               END DESC,
                              decode(task_group_flg_edited, pk_alert_constant.g_yes, 0, 1),
                              presc.dt_last_update,
                              CASE
                                  WHEN presc.sos_take_condition IS NOT NULL THEN
                                   0
                                  ELSE
                                   1
                              END,
                              (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, presc.id_presc)
                                 FROM dual) DESC,
                              presc.id_presc DESC);
    
        IF g_debug
        THEN
            pk_alertlog.log_debug(text        => 'CALL pk_rt_med_pfh.get_presc_admin_list(' || chr(10) || 'i_lang => ' ||
                                                 i_lang || ',' || chr(10) || 'i_prof => profissional(' || i_prof.id || ', ' ||
                                                 i_prof.institution || ', ' || i_prof.software || '),' || chr(10) ||
                                                 'i_id_prescs => table_number(' ||
                                                 pk_utils.concat_table(i_tab => l_id_prescs, i_delim => ',') || '),' ||
                                                 chr(10) || 'i_dt_begin => ' || i_dt_begin || ',' || chr(10) ||
                                                 'i_dt_end => ' || i_dt_end || ',' || chr(10) ||
                                                 'i_id_status_to_exclude => table_number(207)' || chr(10) || ')',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
        END IF;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            IF NOT pk_rt_med_pfh.get_presc_admin_list(i_lang                 => i_lang,
                                                      i_prof                 => i_prof,
                                                      i_id_prescs            => l_id_prescs,
                                                      i_dt_begin             => i_dt_begin,
                                                      i_dt_end               => i_dt_end,
                                                      i_id_status_to_exclude => table_number(pk_rt_med_pfh.st_take_canceled,
                                                                                             pk_rt_med_pfh.st_take_discontinued),
                                                      o_admin_list           => o_admin_list,
                                                      o_error                => o_error)
            THEN
                RAISE e_user_exception;
            END IF;
        END IF;
    
        pk_types.open_cursor_if_closed(o_admin_list);
        RETURN TRUE;
    EXCEPTION
        WHEN e_user_exception THEN
            pk_types.open_cursor_if_closed(o_task_list);
            pk_types.open_cursor_if_closed(o_admin_list);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_task_list);
            pk_types.open_cursor_if_closed(o_admin_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_LIST',
                                              o_error);
            RETURN FALSE;
    END get_medication_list;

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
    ) RETURN BOOLEAN IS
        l_id_visit                 visit.id_visit%TYPE;
        l_presc_list               t_tbl_cpoe_med_task;
        l_id_prescs                table_number;
        l_drug_take_in_case_prefix pk_types.t_big_char;
        l_aditional_inst_desc      pk_translation.t_desc_translation;
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
    
        l_id_visit := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_drug_take_in_case_prefix := (pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_rt_med_pfh.g_msg_sos) || ', ' ||
                                          pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => pk_rt_med_pfh.g_sys_message_take_condition));
        
            l_aditional_inst_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_PRESC_T050') || ': ';
        END IF;
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_list called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_patient=' ||
                                  i_patient || chr(10) || 'i_episode=' || i_episode || chr(10) || ' l_id_visit=' ||
                                  l_id_visit || chr(10) || 'i_task_request=' || get_tabnum_str(i_task_request) ||
                                  chr(10) || 'i_filter_tstz=' || i_filter_tstz || chr(10) || 'i_filter_status=' ||
                                  get_tabvar_str(i_filter_status) || chr(10) || 'i_flg_report=' || i_flg_report,
                                  g_package_name);
        END IF;
    
        SELECT /*+OPT_ESTIMATE(TABLE p ROWS=1)*/
         p.id_presc,
         t_rec_cpoe_med_task(id_presc                => p.id_presc,
                             id_presc_directions     => p.id_presc_directions,
                             id_status               => p.id_status,
                             id_notes                => p.id_notes,
                             id_cds                  => p.id_cds,
                             id_prof_create          => p.id_prof_create,
                             id_prof_upd             => p.id_prof_upd,
                             id_professional_co_sign => p.id_professional_co_sign,
                             task_group_id           => NULL, --p.task_group_id,
                             task_group_status_rank  => NULL, --p.task_group_status_rank,
                             flg_edited              => p.flg_edited,
                             flg_prod_replace        => p.flg_prod_replace,
                             task_group_flg_edited   => NULL, --p.task_group_flg_edited,
                             id_route                => p.id_route,
                             id_route_supplier       => p.id_route_supplier,
                             id_status_desc          => p.id_status_desc,
                             sos_take_condition      => p.sos_take_condition,
                             dt_begin                => p.dt_begin,
                             dt_end                  => p.dt_end,
                             dt_last_update          => p.dt_last_update,
                             dt_first_valid_plan     => p.dt_first_valid_plan,
                             dt_validation_co_sign   => p.dt_validation_co_sign,
                             task_group_date         => NULL --p.task_group_date
                             )
          BULK COLLECT
          INTO l_id_prescs, l_presc_list
          FROM TABLE(pk_rt_med_pfh.get_list_prescription_bsc(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_patient => i_patient,
                                                             i_id_visit   => l_id_visit)) p
         WHERE p.id_status != pk_rt_med_pfh.st_pre_defined
           AND p.id_workflow NOT IN (pk_rt_med_pfh.wf_ambulatory, pk_rt_med_pfh.wf_report)
           AND ((i_flg_out_of_cpoe = pk_alert_constant.g_yes
               -- discard cancelled, concluded, discontinued or expired task status,
               -- except if they are in the given timestamp range
               AND p.id_status NOT IN
               (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued, pk_rt_med_pfh.st_cpoe_draft) AND
               (p.id_status NOT IN (SELECT /*+OPT_ESTIMATE(TABLE req_status ROWS=1)*/
                                       to_number(req_status.column_value)
                                        FROM TABLE(i_filter_status) req_status)))
               
               OR (i_flg_out_of_cpoe = pk_alert_constant.g_no AND
               (i_task_request IS NULL
               -- discard cancelled, concluded, discontinued or expired task status,
               -- except if they are in the given timestamp range
               AND (p.id_status NOT IN (SELECT /*+OPT_ESTIMATE(TABLE req_status ROWS=1)*/
                                               to_number(req_status.column_value)
                                                FROM TABLE(i_filter_status) req_status) OR
               ((i_filter_tstz < p.dt_last_update AND
               p.id_status NOT IN (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued))) OR
               (p.id_status IN (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued) AND
               l_cancelled_task_filter_tstz < p.dt_cancel_presc)))
               -- when this api is addressed with requests, it will return only required prescriptions
               OR p.id_presc IN (SELECT /*+OPT_ESTIMATE(TABLE req_filter ROWS=1)*/
                                       req_filter.column_value
                                        FROM TABLE(i_task_request) req_filter)));
    
        IF nvl(cardinality(l_presc_list), 0) > 0
        THEN
            FOR i IN l_presc_list.first .. l_presc_list.last
            LOOP
                BEGIN
                    SELECT gd.task_group_date, gd.task_group_flg_edited, gd.task_group_id, gd.task_group_status_rank
                      INTO l_presc_list(i).task_group_date,
                           l_presc_list(i).task_group_flg_edited,
                           l_presc_list(i).task_group_id,
                           l_presc_list(i).task_group_status_rank
                      FROM TABLE(pk_rt_med_pfh.get_presc_group_data(i_lang, l_presc_list(i).id_presc)) gd;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END LOOP;
        END IF;
    
        -- get medication task list
        OPEN o_task_list FOR
            SELECT task_type,
                   CASE
                        WHEN i_flg_report = pk_alert_constant.g_yes THEN
                         task_title
                        ELSE
                         CASE
                             WHEN length(task_title || ' ' || task_instructions_long || ' ' || presc_notes) >= 1000 THEN
                              substr(task_title || ' ' || task_instructions_long || CASE
                                         WHEN presc_notes IS NOT NULL THEN
                                          chr(10) || presc_notes
                                         ELSE
                                          NULL
                                     END,
                                     1,
                                     990) || '...'
                             ELSE
                              task_title || ' ' || task_instructions_long || CASE
                                  WHEN presc_notes IS NOT NULL THEN
                                   chr(10) || presc_notes
                                  ELSE
                                   NULL
                              END
                         END
                    END AS task_description,
                   id_professional,
                   icon_warning,
                   status_str,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   creation_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflict,
                   id_request AS id_task, -- for medication tasks, the prescription id is used for cds handling
                   -- extra report fields
                   decode(i_flg_report, pk_alert_constant.g_yes, task_title, NULL) AS task_title,
                   CASE
                        WHEN length(status_desc || task_instructions_long || CASE
                                        WHEN aditional_instr IS NOT NULL THEN
                                         chr(10) || l_aditional_inst_desc || aditional_instr
                                        ELSE
                                         NULL
                                    END) >= 10000 THEN
                         substr(status_desc || task_instructions_long, 1, 9900) || '...'
                        ELSE
                         status_desc || task_instructions_long || CASE
                             WHEN aditional_instr IS NOT NULL THEN
                              chr(10) || l_aditional_inst_desc || aditional_instr
                             ELSE
                              NULL
                         END
                    END AS task_instructions,
                   task_notes,
                   drug_dose,
                   drug_route,
                   drug_take_in_case,
                   task_status,
                   instr_bg_color,
                   instr_bg_alpha,
                   CASE
                        WHEN (SELECT pk_rt_med_pfh.presc_is_home_care(i_lang     => i_lang,
                                                                      i_prof     => i_prof,
                                                                      i_id_presc => id_request)
                                FROM dual) = pk_alert_constant.g_yes THEN
                         pk_rt_med_pfh.g_home_care_icon
                        ELSE
                         NULL
                    END task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   id_task_type_source,
                   NULL AS id_task_dependency,
                   CASE
                        WHEN flg_status IN (pk_rt_med_pfh.st_cpoe_draft,
                                            pk_rt_med_pfh.st_cancelled,
                                            pk_rt_med_pfh.st_discontinued,
                                            pk_rt_med_pfh.st_presc_cancel_ongoing,
                                            pk_rt_med_pfh.st_presc_discont_ongoing) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_rep_cancel,
                   CASE
                        WHEN flg_status = pk_rt_med_pfh.g_wf_presc_conditional_order THEN
                         pk_alert_constant.g_yes
                        WHEN sos_take_condition IS NOT NULL THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_prn_conditional
              FROM (SELECT /*+OPT_ESTIMATE(TABLE presc ROWS=1)*/
                     (SELECT pk_api_pfh_in.get_presc_notes_serialized(i_lang     => i_lang,
                                                                      i_prof     => i_prof,
                                                                      i_id_presc => presc.id_presc)
                        FROM dual) presc_notes,
                     NULL AS task_type,
                     (SELECT pk_api_pfh_ordertools_in.get_medication_task_type(i_lang     => i_lang,
                                                                               i_prof     => i_prof,
                                                                               i_id_presc => presc.id_presc)
                        FROM dual) AS id_task_type_source,
                     (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, presc.id_presc, ' +' || chr(10))
                        FROM dual) AS task_title,
                     (SELECT pk_rt_med_pfh.get_presc_directions(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_presc     => presc.id_presc,
                                                                 i_flg_html     => pk_rt_med_pfh.g_no,
                                                                 i_flg_complete => pk_rt_med_pfh.g_yes,
                                                                 
                                                                 i_flg_with_dt_begin   => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_sos        => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_duration   => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_executions => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_flg_with_dt_end     => CASE i_flg_report
                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_no
                                                                                              ELSE
                                                                                               pk_alert_constant.g_yes
                                                                                          END,
                                                                 i_print_report        => i_flg_report,
                                                                 i_flg_with_new_lines  => CASE
                                                                                              WHEN i_flg_report = pk_alert_constant.g_yes THEN
                                                                                               pk_alert_constant.g_yes
                                                                                              ELSE
                                                                                               pk_alert_constant.g_no
                                                                                          END,
                                                                 i_flg_with_notes      => pk_alert_constant.g_no)
                        FROM dual) || (SELECT pk_rt_med_pfh.get_presc_admin_method_desc(i_lang     => i_lang,
                                                                                        i_prof     => i_prof,
                                                                                        i_id_presc => presc.id_presc)
                                         FROM dual) || (SELECT pk_rt_med_pfh.get_presc_admin_site_desc(i_lang     => i_lang,
                                                                                                       i_prof     => i_prof,
                                                                                                       i_id_presc => presc.id_presc)
                                                          FROM dual) ||
                     (SELECT pk_rt_med_pfh.get_presc_duration_desc(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_id_presc => presc.id_presc)
                        FROM dual) AS task_instructions_long,
                     pk_rt_med_pfh.get_patient_instr_desc(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_id_presc => presc.id_presc) aditional_instr,
                     nvl(presc.id_professional_co_sign, nvl(presc.id_prof_upd, presc.id_prof_create)) AS id_professional,
                     (SELECT pk_rt_med_pfh.get_cds_call_icon(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_call      => presc.id_cds,
                                                             i_task_reqs => presc.id_presc)
                        FROM dual) AS icon_warning,
                     (SELECT pk_rt_med_pfh.get_presc_status_icon(i_lang, i_prof, presc.id_presc)
                        FROM dual) AS status_str,
                     presc.id_presc AS id_request,
                     presc.dt_begin AS start_date_tstz,
                     presc.dt_end AS end_date_tstz,
                     nvl(presc.dt_validation_co_sign, presc.dt_last_update) AS creation_date_tstz,
                     presc.id_status AS flg_status,
                     (SELECT pk_rt_med_pfh.check_cancel_presc(i_lang, i_prof, presc.id_presc)
                        FROM dual) AS flg_cancel,
                     decode(presc.id_status,
                            g_presc_cpoe_draft,
                            (SELECT pk_rt_med_pfh.check_presc_conflicts(i_lang, i_prof, presc.id_presc)
                               FROM dual),
                            pk_alert_constant.g_no) AS flg_conflict,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            (SELECT to_char(pk_rt_med_pfh.get_route_desc(i_lang,
                                                                         i_prof,
                                                                         presc.id_route,
                                                                         presc.id_route_supplier,
                                                                         NULL))
                               FROM dual),
                            NULL) AS drug_route,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            pk_translation.get_translation(i_lang => i_lang, i_code_mess => presc.id_status),
                            NULL) AS task_status,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            (SELECT pk_rt_med_pfh.get_dir_item_dose_desc(i_lang              => i_lang,
                                                                         i_prof              => i_prof,
                                                                         i_id_presc_dir_item => presc.id_presc_directions,
                                                                         i_id_presc          => presc.id_presc)
                               FROM dual),
                            NULL) AS drug_dose,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            (SELECT pk_rt_med_pfh.get_last_presc_notes(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_presc_notes => presc.id_notes)
                               FROM dual),
                            NULL) AS task_notes,
                     decode(i_flg_report,
                            pk_alert_constant.g_yes,
                            nvl2(presc.sos_take_condition, (l_drug_take_in_case_prefix || presc.sos_take_condition), NULL),
                            NULL) AS drug_take_in_case,
                     (SELECT pk_rt_med_pfh.get_instr_bg_color_by_presc(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_id_presc => presc.id_presc)
                        FROM dual) instr_bg_color,
                     (SELECT pk_rt_med_pfh.get_instr_bg_alpha_by_presc(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_id_presc => presc.id_presc)
                        FROM dual) AS instr_bg_alpha,
                     presc.sos_take_condition,
                     CASE
                          WHEN presc.id_status IN (pk_rt_med_pfh.st_take_suspended,
                                                   pk_rt_med_pfh.st_take_suspended_ongoing,
                                                   pk_rt_med_pfh.st_suspended,
                                                   pk_rt_med_pfh.st_suspended_ongoing) THEN
                           (SELECT pk_translation.get_translation(i_lang, 'WF_STATUS.CODE_STATUS.' || presc.id_status)
                              FROM dual) || ' - '
                          ELSE
                           NULL
                      END status_desc
                      FROM TABLE(l_presc_list) presc
                     ORDER BY CASE (SELECT pk_rt_med_pfh.presc_is_active(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_id_presc => presc.id_presc)
                                  FROM dual)
                                  WHEN pk_alert_constant.g_yes THEN
                                   0
                                  ELSE
                                   1
                              END,
                              (SELECT pk_rt_med_pfh.get_presc_status_rank(i_id_presc => presc.id_presc)
                                 FROM dual),
                              CASE
                                  WHEN (SELECT pk_rt_med_pfh.presc_is_active(i_lang     => i_lang,
                                                                             i_prof     => i_prof,
                                                                             i_id_presc => presc.id_presc)
                                          FROM dual) = pk_alert_constant.g_yes THEN
                                   presc.task_group_date
                                  ELSE
                                   NULL
                              END,
                              CASE
                                   WHEN (SELECT pk_rt_med_pfh.presc_is_active(i_lang     => i_lang,
                                                                              i_prof     => i_prof,
                                                                              i_id_presc => presc.id_presc)
                                           FROM dual) = pk_alert_constant.g_no THEN
                                    presc.dt_last_update
                                   ELSE
                                    NULL
                               END DESC,
                              decode(task_group_flg_edited, pk_alert_constant.g_yes, 0, 1),
                              presc.dt_last_update,
                              CASE
                                  WHEN presc.sos_take_condition IS NOT NULL THEN
                                   0
                                  ELSE
                                   1
                              END,
                              (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, presc.id_presc)
                                 FROM dual) DESC,
                              presc.id_presc DESC);
    
        IF g_debug
        THEN
            pk_alertlog.log_debug(text        => 'CALL pk_rt_med_pfh.get_presc_admin_list(' || chr(10) || 'i_lang => ' ||
                                                 i_lang || ',' || chr(10) || 'i_prof => profissional(' || i_prof.id || ', ' ||
                                                 i_prof.institution || ', ' || i_prof.software || '),' || chr(10) ||
                                                 'i_id_prescs => table_number(' ||
                                                 pk_utils.concat_table(i_tab => l_id_prescs, i_delim => ',') || '),' ||
                                                 chr(10) || 'i_dt_begin => ' || i_dt_begin || ',' || chr(10) ||
                                                 'i_dt_end => ' || i_dt_end || ',' || chr(10) ||
                                                 'i_id_status_to_exclude => table_number(207)' || chr(10) || ')',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
        END IF;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            IF NOT pk_rt_med_pfh.get_presc_admin_list(i_lang                 => i_lang,
                                                      i_prof                 => i_prof,
                                                      i_id_prescs            => l_id_prescs,
                                                      i_dt_begin             => i_dt_begin,
                                                      i_dt_end               => i_dt_end,
                                                      i_id_status_to_exclude => table_number(pk_rt_med_pfh.st_take_canceled,
                                                                                             pk_rt_med_pfh.st_take_discontinued),
                                                      o_admin_list           => o_admin_list,
                                                      o_error                => o_error)
            THEN
                RAISE e_user_exception;
            END IF;
        END IF;
    
        pk_types.open_cursor_if_closed(o_admin_list);
        RETURN TRUE;
    EXCEPTION
        WHEN e_user_exception THEN
            pk_types.open_cursor_if_closed(o_task_list);
            pk_types.open_cursor_if_closed(o_admin_list);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_task_list);
            pk_types.open_cursor_if_closed(o_admin_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_LIST_CPOE',
                                              o_error);
            RETURN FALSE;
    END get_medication_list_cpoe;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.copy_medication_to_draft called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_patient=' || i_id_patient || chr(10) || 'i_id_episode=' || i_id_episode ||
                                  chr(10) || 'i_id_presc=' || i_id_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.copy_cpoe_draft_presc function
        IF NOT pk_rt_med_pfh.copy_cpoe_draft_presc(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_id_patient           => i_id_patient,
                                                   i_id_episode           => i_id_episode,
                                                   i_id_presc             => i_id_presc,
                                                   i_task_start_timestamp => i_task_start_timestamp,
                                                   i_task_end_timestamp   => i_task_end_timestamp,
                                                   i_flg_via_job          => i_flg_via_job,
                                                   o_id_presc             => o_id_presc,
                                                   o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.copy_cpoe_draft_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_MEDICATION_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_medication_to_draft;

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
    ) RETURN BOOLEAN IS
        l_presc_tmp table_number;
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.expire_medication_tasks called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_patient=' || i_id_patient || chr(10) || 'i_id_episode=' || i_id_episode ||
                                  chr(10) || 'i_id_presc=' || get_tabnum_str(i_id_presc),
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.set_cpoe_expire_presc function
        IF NOT pk_rt_med_pfh.set_cpoe_expire_presc(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_patient  => i_id_patient, -- can be null
                                                   i_id_episode  => i_id_episode,
                                                   i_id_presc    => i_id_presc,
                                                   i_id_cdr_call => NULL, -- not needed at this time
                                                   o_id_presc    => l_presc_tmp,
                                                   o_error       => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_cpoe_expire_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EXPIRE_MEDICATION_TASKS',
                                              o_error);
            RETURN FALSE;
    END expire_medication_tasks;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_task_status called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_episode=' || i_id_episode || chr(10) || 'i_id_presc=' ||
                                  get_tabnum_str(i_id_presc),
                                  g_package_name);
        END IF;
        -- open cursor with prescriptions status        
        OPEN o_presc_status FOR
            SELECT pk_alert_constant.g_task_type_medication AS id_task_type,
                   t.column_value AS id_task_request,
                   to_char(pk_rt_med_pfh.get_presc_status(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_id_presc => t.column_value)) AS flg_status
              FROM TABLE(i_id_presc) t;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_TASK_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_presc_status);
            RETURN FALSE;
    END get_medication_task_status;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.delete_medication_drafts called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_episode=' || get_tabnum_str(i_episode),
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.set_cpoe_cancel_drafts function
        IF NOT pk_rt_med_pfh.set_cpoe_cancel_drafts(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_episode => i_episode,
                                                    o_error      => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_cpoe_cancel_drafts function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_MEDICATION_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END delete_medication_drafts;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.activate_medication_drafts called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_episode=' || i_episode || chr(10) || 'i_draft_presc=' ||
                                  get_tabnum_str(i_draft_presc) || chr(10) || 'i_cdr_call=' || i_cdr_call,
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.set_cpoe_cancel_drafts function
        IF NOT pk_rt_med_pfh.set_cpoe_activate_draft(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_patient  => NULL, -- TODO NEWMED: check why we need this
                                                     i_id_episode  => i_episode,
                                                     i_id_presc    => i_draft_presc,
                                                     i_id_cdr_call => i_cdr_call,
                                                     o_id_presc    => o_created_presc,
                                                     o_error       => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_cpoe_activate_draft function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_MEDICATION_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END activate_medication_drafts;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_medication_actions called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_presc=' || i_presc,
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.get_presc_actions function
        IF NOT pk_rt_med_pfh.get_presc_actions(i_lang                 => i_lang,
                                               i_prof                 => i_prof,
                                               i_id_presc             => table_number(i_presc),
                                               i_class_origin         => 'CpoeGrid',
                                               i_class_origin_context => 'MEDICATION_CPOE',
                                               o_action               => o_action,
                                               o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.get_presc_actions function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MEDICATION_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_medication_actions;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.resume_medication called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_presc=' ||
                                  i_presc,
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.set_resume_presc function
        IF NOT pk_rt_med_pfh.set_resume_presc(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_presc         => i_presc,
                                              o_check_validation => o_flg_validated,
                                              o_error            => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_resume_presc function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESUME_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END resume_medication;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.check_med_mandatory_fields called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc,
                                  g_package_name);
        END IF;
    
        RETURN pk_rt_med_pfh.check_mandatory_fields(i_id_presc => i_id_presc);
    END check_med_mandatory_fields;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.check_prof_needs_cosign_create called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc || chr(10) || 'i_id_episode=' || i_id_episode,
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.check_prof_needs_cosign_create function
        IF NOT pk_rt_med_pfh.check_prof_needs_cosign_create(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_id_presc             => i_id_presc,
                                                            i_id_episode           => i_id_episode,
                                                            o_flg_prof_need_cosign => o_flg_prof_need_cosign,
                                                            o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.check_prof_needs_cosign_create function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROF_NEEDS_COSIGN_CREATE',
                                              o_error);
            RETURN FALSE;
    END check_prof_needs_cosign_create;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.check_prof_needs_cosign_create called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_presc=' || i_id_presc || chr(10) || 'i_id_episode=' || i_id_episode,
                                  g_package_name);
        END IF;
        -- call pk_rt_med_pfh.check_prof_needs_cosign_cancel function
        IF NOT pk_rt_med_pfh.check_prof_needs_cosign_cancel(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_id_presc             => i_id_presc,
                                                            i_id_episode           => i_id_episode,
                                                            o_flg_prof_need_cosign => o_flg_prof_need_cosign,
                                                            o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.check_prof_needs_cosign_cancel function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PROF_NEEDS_COSIGN_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_prof_needs_cosign_cancel;

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
    ) RETURN NUMBER IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_in.get_presc_task_type called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_id_presc=' ||
                                  i_id_presc,
                                  g_package_name);
        END IF;
    
        -- call pk_rt_med_pfh.get_presc_task_type function
        RETURN pk_rt_med_pfh.get_presc_task_type(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_medication_task_type;

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);
END pk_api_pfh_ordertools_in;
/
