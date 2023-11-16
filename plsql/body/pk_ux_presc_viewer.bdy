/*-- Last Change Revision: $Rev: 2027843 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_presc_viewer IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  JOANA.BARROSO
    * @version <Product Version>
    * @since   14-03-2014
    */
    /**
    * Get draft RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_draft
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN presc.id_epis_create%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_functionname VARCHAR2(100 CHAR) := 'GET_RX_PRESCRIPTION_DARFT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        g_error := 'Execution code: Call pk_api_pfh_in.get_rx_prescription_draft / I_EPIS=' || i_epis;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        IF i_epis IS NOT NULL
        THEN
            OPEN o_list FOR
                SELECT *
                  FROM TABLE(pk_api_pfh_in.get_rx_prescription_draft(i_lang => i_lang,
                                                                     i_prof => i_prof,
                                                                     i_epis => i_epis));
        ELSE
            pk_types.open_cursor_if_closed(o_list);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_functionname,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_rx_prescription_draft;

    /**
    * Get all active RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_epis
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_functionname VARCHAR2(100 CHAR) := 'GET_RX_PRESCRIPTION_EPIS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        g_error := 'Execution code: Call pk_api_pfh_in.get_rx_prescription_epis / I_EPIS=' || i_epis;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        IF i_epis IS NOT NULL
        THEN
            OPEN o_list FOR
                SELECT *
                  FROM TABLE(pk_api_pfh_in.get_rx_prescription_epis(i_lang => i_lang,
                                                                    i_prof => i_prof,
                                                                    i_epis => i_epis));
        ELSE
            pk_types.open_cursor_if_closed(o_list);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_functionname,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rx_prescription_epis;

    /**
    * Get all active RX prescription list for a given patient from previous episodes
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_pat          Patient identification
    * @param   i_epis         Episode identification    
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_all
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_pat   IN patient.id_patient%TYPE,
        i_epis  IN episode.id_episode%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_functionname VARCHAR2(100 CHAR) := 'GET_RX_PRESCRIPTION_EPIS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        g_error := 'Execution code: Call pk_api_pfh_in.get_rx_prescription_all / I_PAT=' || i_pat;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
        IF i_pat IS NOT NULL
        THEN
            OPEN o_list FOR
                SELECT *
                  FROM TABLE(pk_api_pfh_in.get_rx_prescription_all(i_lang => i_lang,
                                                                   i_prof => i_prof,
                                                                   i_pat  => i_pat,
                                                                   i_epis => i_epis));
        ELSE
            pk_types.open_cursor_if_closed(o_list);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_functionname,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rx_prescription_all;

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
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_detail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id     IN NUMBER,
        i_type   IN VARCHAR2,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_functionname VARCHAR2(100 CHAR) := 'GET_RX_PRESCRIPTION_DETAIL';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        g_error := 'Execution code: Call pk_api_pfh_in.get_rx_prescription_detail / I_ID=' || i_id || 'I_TYPE=' ||
                   i_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_functionname);
    
        IF i_type IS NOT NULL
           AND i_id IS NOT NULL
        THEN
            OPEN o_detail FOR
                SELECT *
                  FROM TABLE(pk_api_pfh_in.get_rx_prescription_detail(i_lang => i_lang,
                                                                      i_prof => i_prof,
                                                                      i_id   => i_id,
                                                                      i_type => i_type));
        
        ELSE
            pk_types.open_cursor_if_closed(o_detail);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_detail);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_functionname,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rx_prescription_detail;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ux_presc_viewer;
/
