/*-- Last Change Revision: $Rev: 2029058 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wlpatient AS

    g_language_num NUMBER;

    xpl                      VARCHAR2(0010);
    xsp                      VARCHAR2(0010);
    pk_wl_stat_sample_size   VARCHAR2(0500);
    pk_wait_status           VARCHAR2(0050);
    pk_info_get_ticket       VARCHAR2(0500);
    pk_msg_hours_kiosk       VARCHAR2(0050);
    pk_wl_lang               VARCHAR2(0050);
    pk_wl_url_photo_read     VARCHAR2(0050);
    pk_wl_url_photo_pub_read VARCHAR2(0050);
    pk_tempo_espera_lim      NUMBER;

    g_ret            BOOLEAN;
    g_error          VARCHAR2(4000); -- Localização do erro
    g_error_msg_code VARCHAR2(200);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    /**
    * Get configuration about available queues to department and which ones the user is allocated in context of I_ID_MACHINE;
    * Also, returns the last queues that the professional allocated himself to.
    * NOTE: This function unifies all previous versions of get_queues, which are considered to now be deprecated. 
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_DEPARTMENT The department id
    * @param   I_ID_WL_MACHINE The machine beeing operated
    * @param   O_QUEUES The cursor with queues info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-11-2008
    */
    FUNCTION get_queues
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************************
    *  
    * Returns the path for a patient's photo, but accesses a more restricted repository
    *
    * @param   I_ID_PAT The patient id
    *
    * @RETURN  STRING WITH PATH FOR PHOTOGRAPH if sucess, NULL otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    **********************************************************************************************************/
    FUNCTION get_pat_pub_foto
    (
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION generate_ticket
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_wl_machine_name   IN wl_machine.machine_name%TYPE,
        i_id_episode        IN NUMBER,
        i_char_queue        IN VARCHAR2,
        i_number_queue      IN NUMBER,
        o_ticket_number     OUT VARCHAR2,
        o_ticket_print      OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *  Returns the info to be printed in the ticket
     *
     * @param i_lang                   Language ID
     * @param i_id_wl_queue            ID of the Queue that the ticket 
     * @param i_id_mach                ID of the machine (kiosk)
     * @param i_prof                   ID of the professional (presumively UTENTE)
     * @param o_ticket_number          Ticket number (in the corresponding queue)
     * @param o_msg_dept               Description of the machine
     * @param o_frase                  Configured Message
     * @param o_msg_inst               Configured Message
     * @param o_error
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_ticket
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl_queue   IN wl_queue.id_wl_queue%TYPE,
        i_id_mach       IN wl_machine.id_wl_machine%TYPE,
        i_id_episode    IN NUMBER,
        i_char_queue    IN VARCHAR2,
        i_number_queue  IN NUMBER,
        i_prof          IN profissional,
        o_ticket_number OUT VARCHAR2,
        o_msg_dept      OUT VARCHAR2,
        o_frase         OUT VARCHAR2,
        o_msg_inst      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *  Function for use with the kiosk, it returns the stats regarding the provided queue (number of people ahead and the average waiting time). 
     *
     * @param i_lang                Language in which to return the results
     * @param i_id_wl_queue         ID of the queue to check stats from 
     * @param i_prof        
     * @param o_total_people_ahead       number of people ahead
     * @param o_tempo_medio_espera       average waiting time.
     * @param o_error 
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_queue_stat
    (
        i_lang               IN language.id_language%TYPE,
        i_id_wl_queue        IN wl_queue.id_wl_queue%TYPE,
        i_prof               IN profissional,
        o_total_people_ahead OUT NUMBER,
        o_tempo_medio_espera OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *  Function for use with the kiosk, it returns an informative text regarding the provided queue with the number of people ahead and the average waiting time. 
     *
     * @param i_lang                Language in which to return the results
     * @param i_id_wl_queue         ID of the queue to check stats from 
     * @param i_prof                
     * @param o_message 
     * @param o_error 
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_message_with_stat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_queue   IN wl_queue.id_wl_queue%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_message       OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************************
    * 
    * Returns NUMBER OF PEOPLE NOT ATTENDED BY ADMINISTRATIVE IN A PARTICULAR QUEUE
    *
    * @param   I_ID_WL_QUEUE  ID of the ticket
    * @param   I_ID_PROF      Information of the professional calling this function. 
    *
    * @RETURN  NUMBER the number of people ahead of provided ticket.
    * @author  ?
    * @version 1.0
    * @since   ?
    **********************************************************************************************************/
    FUNCTION get_people_ahead
    (
        i_id_wl_queue IN wl_queue.id_wl_queue%TYPE,
        i_prof        IN profissional
    ) RETURN NUMBER;

    /***********************************************************************************************************************
    * 
    * GET PHOTO FOR AN PATIENT
    *
    * @param   I_ID_PAT The patient id
    * @param   O_IMG    the blob containing the image
    *
    * @RETURN  TRUE if sucess, NULL otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   25-02-2009
    ***********************************************************************************************************************/
    FUNCTION get_blob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        o_img   OUT BLOB,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    -- function for printing label via print tool
    FUNCTION report_ticket
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_wl_machine_name IN wl_machine.machine_name%TYPE,
        i_id_episode      IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_popup_queues
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2,
        o_result    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_ticket
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dept_room
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

END pk_wlpatient;
/
