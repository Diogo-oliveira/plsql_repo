CREATE OR REPLACE PACKAGE BODY pk_sig_ux IS

    PROCEDURE process_error
    (
        i_lang     IN NUMBER,
        i_code     IN NUMBER,
        i_errm     IN VARCHAR2,
        i_function IN VARCHAR2,
        o_error    OUT t_error_out
    ) IS
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang, i_code, i_errm, i_errm, 'ALERT', 'PK_SIG_UX', i_function, o_error);
        pk_utils.undo_changes;
    
    END process_error;

    FUNCTION set_active_sig
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_sig.set_active_sig(i_id_prof => i_id_prof, i_id_sig => i_id_sig);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_code     => SQLCODE,
                          i_errm     => SQLERRM,
                          i_function => 'SET_ACTIVE_SIG',
                          o_error    => o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
    END set_active_sig;

    --***************************
    FUNCTION save_sig
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_epis_sig    IN NUMBER,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_image       IN BLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_sig.save_sig(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_epis_sig    => i_epis_sig,
                                  i_tbl_mkt_rel => i_tbl_mkt_rel,
                                  i_value       => i_value,
                                  i_image       => i_image,
                                  o_error       => o_error);
    
        IF l_bool
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes();
            process_error(i_lang     => i_lang,
                          i_code     => SQLCODE,
                          i_errm     => SQLERRM,
                          i_function => 'SAVE_SIG',
                          o_error    => o_error);
        
            RETURN FALSE;
    END save_sig;

    --********************
    FUNCTION cancel_signature
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_epis_sig IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_sig.cancel_signature(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_epis_sig         => i_epis_sig,
                                          i_id_cancel_reason => NULL,
                                          o_error            => o_error);
    
        IF l_bool
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes();
            process_error(i_lang     => i_lang,
                          i_code     => SQLCODE,
                          i_errm     => SQLERRM,
                          i_function => 'CANCEL_SIGNATURE',
                          o_error    => o_error);
        
            RETURN FALSE;
        
    END cancel_signature;

    FUNCTION get_address
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_sig.get_address(i_prof.id);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_code     => SQLCODE,
                          i_errm     => SQLERRM,
                          i_function => 'GET_ADDRESS',
                          o_error    => o_error);
            RETURN FALSE;
    END get_address;

END pk_sig_ux;
