/*-- Last Change Revision: $Rev: 430489 $*/
/*-- Last Change by: $Author: joao.almeida $*/
/*-- Date of last change: $Date: 2010-03-08 19:03:50 +0000 (seg, 08 mar 2010) $*/

CREATE OR REPLACE PACKAGE pk_p1_exr_diagnosis IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 04-11-2009 17:34:50
    -- Purpose : API for table P1_EXR_DIAGNOSIS

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations
    g_error         VARCHAR2(1000 CHAR);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    -- Public function and procedure declarations

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
        i_lang  LANGUAGE.id_language%TYPE,
        i_rec   IN p1_exr_diagnosis%ROWTYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

END pk_p1_exr_diagnosis;
/
