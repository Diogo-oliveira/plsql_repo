/*-- Last Change Revision: $Rev: 2029051 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wladm AS

    /**
    * Call next patient waiting after having a ticket.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   O_DATA_WAIT The info about next call
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   15-11-2006
    */
    FUNCTION get_next_call
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_mach       IN wl_machine.id_wl_machine%TYPE,
        i_flg_prior_too IN NUMBER,
        o_data_wait     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns the next ticket to be called, from the provided group of queues.  
     *
     * @param i_lang                    Language ID
     * @param i_id_queues               Table Number with the queues to verify
     * @param i_flg_prior_too           Param to check wether the priority queues should or not be taken into account.
     * @param o_id_waiting_line         ID of the ticket to be called next.
     * @param o_error     
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_next_call_queue
    (
        i_lang            IN language.id_language%TYPE,
        i_id_queues       IN table_number,
        i_flg_prior_too   IN NUMBER,
        o_id_waiting_line OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patients registered at sonho/sinus
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   i_episode ID EPISODE for demo insertion in WL_WAITING_LINE
    * @param   O_DADOS The patients info
    * @param   o_last_called_ticket Last called ticket be the i_id_prof.id professional info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   21-11-2006
    *
    * @EDIT 08-03-2009 RNAlmeida:
    *  Function now incorporates DEMO features.
    *
    */
    FUNCTION get_sonho
    (
        i_lang               IN language.id_language%TYPE,
        i_id_prof            IN profissional,
        i_id_mach            IN NUMBER,
        i_episode            IN episode.id_episode%TYPE,
        o_dados              OUT pk_types.cursor_type,
        o_last_called_ticket OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_language_num   NUMBER;
    g_date_mask      VARCHAR2(16) := 'YYYYMMDDHH24MISS';
    pk_adm_mode      NUMBER;
    pk_med_mode      NUMBER;
    pk_nur_mode      NUMBER;
    pk_id_software   NUMBER;
    pk_nur_flg_type  VARCHAR2(0050);
    pk_e_status      VARCHAR2(0050);
    pk_a_status      VARCHAR2(0050);
    pk_x_status      VARCHAR2(0050);
    xsp              VARCHAR2(0050);
    xpl              VARCHAR2(0050);
    pk_wl_id_sonho   VARCHAR2(0050);
    pk_nurse_queue   VARCHAR2(0050);
    pk_id_department VARCHAR2(0050);
    pk_wl_lang       VARCHAR2(0050);
    xerr             VARCHAR2(2000);

    g_error                VARCHAR2(4000); -- Localização do erro
    g_ret                  BOOLEAN;
    g_error_msg_code       VARCHAR2(200);
    g_prof_room_flg_pref_y VARCHAR2(1);
    g_pdcs_flg_status_s    VARCHAR2(1);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
END pk_wladm;
/