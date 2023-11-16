/*-- Last Change Revision: $Rev: 2027898 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wlsession AS

    /**
    * Unset queues from a professional working in a machine.
    * This function does not end a connection
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006
    */
    FUNCTION unset_queues_internal
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- lg, 2006-11-14: allow one user to have different queues allocated in different machines
        g_error := 'UNSET_QUEUES_INTERNAL';
        DELETE FROM wl_mach_prof_queue w
         WHERE w.id_professional = i_id_prof.id
           AND w.id_wl_machine = i_id_mach;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UNSET_QUEUES_INTERNAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END unset_queues_internal;

    /**
    * Associate a professional with a number of queues in a machine.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine id
    * @param   I_ID_QUEUES Queues to which the professional will be allocated
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006
    */
    FUNCTION set_queues
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_mach   IN wl_machine.id_wl_machine%TYPE,
        i_id_queues IN table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_queue NUMBER;
    
    BEGIN
    
        g_error := 'UNSET_QUEUES';
        IF NOT unset_queues_internal(i_lang, i_prof, i_id_mach, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_QUEUES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'SET_QUEUES';
        FOR i IN 1 .. i_id_queues.count
        LOOP
            l_id_queue := i_id_queues(i);
            INSERT INTO wl_mach_prof_queue
                (id_wl_machine, id_professional, id_wl_queue)
            VALUES
                (i_id_mach, i_prof.id, l_id_queue);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_QUEUES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_queues;

    /********************************************************************************************
     *  Unset queues from a professional working in a machine. 
     * 
     *
     * @param i_lang                   Language ID (supposedly mandatory, although of no real use in this function).
     * @param i_prof                   professional to be unset
     * @param i_id_mach                Machine ID to be unset.
     * @param o_error                  
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION unset_queues
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UNSET_QUEUES';
        IF NOT unset_queues_internal(i_lang, i_prof, i_id_mach, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UNSET_QUEUES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UNSET_QUEUES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END unset_queues;

BEGIN

    g_error_msg_code := 'COMMON_M001';
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
