/*-- Last Change Revision: $Rev: 1714849 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2015-11-06 14:39:15 +0000 (sex, 06 nov 2015) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_exr_diagnosis IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    -- Function and procedure implementations

    /**
    * Verify if for a given Referral the diagnosis have changed
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_id_ref            Referral identifier 
    * @param   O_ERROR             an error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   04-11-2009
    */
    /**
    * Verify if for a given Referral the diagnosis have changed
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_rec               p1_exr_diagnosis record
    * @param   O_ERROR             an error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   04-11-2009
    */
    FUNCTION have_changes
    (
        i_lang  language.id_language%TYPE,
        i_rec   IN p1_exr_diagnosis%ROWTYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        FOR c1 IN (SELECT DISTINCT d.id_diagnosis id_diagnosis_a, dd.id_diagnosis id_diagnosis_b
                     FROM (SELECT d.id_diagnosis
                             FROM p1_exr_diagnosis d
                            WHERE d.id_external_request = i_rec.id_external_request
                              AND d.flg_type IN (pk_ref_constant.g_exr_diag_type_d, pk_ref_constant.g_exr_diag_type_p)
                              AND d.flg_status = pk_ref_constant.g_active
                           UNION
                           SELECT i_rec.id_diagnosis
                             FROM dual) d
                     FULL OUTER JOIN (SELECT d.id_diagnosis
                                       FROM p1_exr_diagnosis d
                                      WHERE id_external_request = i_rec.id_external_request
                                        AND d.flg_type IN
                                            (pk_ref_constant.g_exr_diag_type_d, pk_ref_constant.g_exr_diag_type_p)
                                        AND dt_insert_tstz IN
                                            (SELECT MAX(dt_insert_tstz)
                                               FROM p1_exr_diagnosis dd
                                              WHERE dd.id_external_request = d.id_external_request
                                                AND dd.flg_status = pk_ref_constant.g_cancelled)) dd
                       ON d.id_diagnosis = dd.id_diagnosis)
        LOOP
            IF c1.id_diagnosis_a IS NULL
            THEN
                RETURN TRUE;
            ELSIF c1.id_diagnosis_b IS NULL
            THEN
                RETURN TRUE;
            END IF;
        END LOOP;
    
        RETURN FALSE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'HAVE_CHANGES',
                                              o_error    => o_error);
            RETURN FALSE;
    END have_changes;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_p1_exr_diagnosis;
/
