/*-- Last Change Revision: $Rev: 2029057 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wlinternal IS

    -- Author  : RICARDO.ALMEIDA
    -- Created : 23-03-2009 16:31:12
    -- Purpose : Includes functions not intended to be mapped by the MW layer.

    /**
    * 
    * Create next call after having a ticket.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_QUEUES The queues to look for tickets.
    * @param   O_ID_WAITING_LINE The ticket id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   15-11-2006
    * 
    ********************************************/
    FUNCTION get_next_call_queue_internal
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_id_prof         IN profissional,
        i_id_queues       IN table_number,
        i_flg_prior_too   IN NUMBER,
        o_wl_waiting_line OUT wl_waiting_line%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    
    /**
    * Get last ticket called by a professional.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_ID_PROF            professional, institution and software ids
    * @param   o_wl_waiting_line    Ticket Info    
    * @param   O_ERROR              error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   24-Nov-2010
    *    
    */
    FUNCTION get_last_called_ticket
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_wl_waiting_line OUT wl_waiting_line%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000); -- Localização do erro
    g_ret           BOOLEAN;

END pk_wlinternal;
/
