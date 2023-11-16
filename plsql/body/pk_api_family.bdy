/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_family IS

    /** @headcom
    * Public Function. Detect which patients have left the family I_ID_PAT_FAMILY 
                       comparing the data from SINUS whith the ones in ALERT 
                       and erase the family reference on that patients
    *
    * Note: Esta é a função chamada pelos Interfaces.
    *
    * @param    i_lang           língua registada como preferência do profissional.
    * @param    i_id_pat_family  Family ID
    * @param    i_id_patient     Patients that belong to that family
    * @param    o_error          erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     ASM 
    * @version    0.1
    * @since      2007/07/26
    */
    FUNCTION intf_update_orphan_fam_mem
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_family IN patient.id_pat_family%TYPE,
        i_id_patient    IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'PK_API_FAMILY.CALL_UPDATE_ORPHAN_FAM_MEM';
        IF NOT pk_family.call_update_orphan_fam_mem(i_lang          => i_lang,
                                                    i_id_pat_family => i_id_pat_family,
                                                    i_id_patient    => i_id_patient,
                                                    o_error         => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_API_FAMILY',
                                   'INTF_UPDATE_ORPHAN_FAM_MEM');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END intf_update_orphan_fam_mem;

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
    END error_handling;

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        o_error := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_common_m001) || chr(10) ||
                   g_package_name || '.' || i_func_proc_name;
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
        RETURN FALSE;
    END error_handling;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_api_family;
/
