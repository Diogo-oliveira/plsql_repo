/*-- Last Change Revision: $Rev: 2029060 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wlsession AS

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
    ) RETURN BOOLEAN;

    /**
    * Unset queues from a professional working in a machine.
    * This function does not end a connection
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006
    */
    FUNCTION unset_queues
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_error          VARCHAR2(4000); -- Localização do erro
    g_ret            BOOLEAN;
    g_error_msg_code VARCHAR2(200);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END;
/
