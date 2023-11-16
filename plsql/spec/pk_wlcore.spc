/*-- Last Change Revision: $Rev: 2029054 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wlcore AS

    SUBTYPE g_wl_queue_char IS VARCHAR2(2);

    g_language_num      NUMBER;
    g_ret               BOOLEAN;
    pk_med_msg_01       VARCHAR2(0050);
    pk_med_msg_02       VARCHAR2(0050);
    pk_wl_titulo        VARCHAR2(0050);
    pk_med_msg_tit_01   VARCHAR2(0050);
    pk_med_msg_tit_02   VARCHAR2(0050);
    pk_med_msg_tit_03   VARCHAR2(0050);
    pk_voice            VARCHAR2(0050);
    pk_bip              VARCHAR2(0050);
    pk_wavfile_prefix   VARCHAR2(0050);
    pk_wavfile_sufix    VARCHAR2(0050);
    pk_pendente         VARCHAR2(0050);
    pk_nurse_queue      VARCHAR2(0050);
    pk_wl_path_wav_read VARCHAR2(0050);
    pk_wl_wav_bip_name  VARCHAR2(0050);
    pk_h_status         VARCHAR2(0050);
    pk_a_status         VARCHAR2(0050);
    pk_t_status         VARCHAR2(0050);
    pk_n_status         VARCHAR2(0050);
    xsp                 VARCHAR2(0050);
    xpl                 VARCHAR2(0050);
    pk_wl_lang          VARCHAR2(0050);

    g_flg_epis_type_nurse_care epis_type.id_epis_type%TYPE;
    g_flg_epis_type_nurse_outp epis_type.id_epis_type%TYPE;
    g_flg_epis_type_nurse_pp   epis_type.id_epis_type%TYPE;

    g_error                VARCHAR2(4000); -- Localização do erro
    g_error_msg_code       VARCHAR2(200);
    g_prof_room_flg_pref_y VARCHAR2(1);
    g_flg_available        VARCHAR2(1);

    g_sys_config_wr         VARCHAR2(200);
    g_flg_type_queue_doctor VARCHAR2(1);

    g_associate_pat_ticket sys_config.id_sys_config%TYPE := 'WR_INF_ASSOCIATE_PAT_TICKET';

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_wl_demo_flg sys_config.id_sys_config%TYPE := 'WL_DEMO_FLG';

    g_demo_department_0 department.id_department%TYPE := 0;
    g_exception         EXCEPTION;

    /**
    *Validates if the episode is
    */
    FUNCTION get_episode_efective
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *
    *  Creates a new entry to be called by the Screen application.
    *
    * @param i_lang                  Language ID
    * @param i_id_wl                 ID of the ticket to be called
    * @param i_id_mach_ped           ID of the machine issuing the call.
    * @param i_prof                  Professional issuing the call.
    * @param i_id_mach_ped           ID of the destination machine
    * @param i_id_episode            episode id
    * @param o_message_audio         Message to be converted into an audio file.
    * @param o_sound_file            Name of the audio file to be created.
    * @param o_mac                   IDs of the machines where the message will be displayed
    * @param o_msg                   Messages to appear on the screen
    * @param o_error
    */
    FUNCTION item_call_system_queue
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl         IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_mach_ped   IN wl_machine.id_wl_machine%TYPE,
        i_prof          IN profissional,
        i_id_mach_dest  IN wl_machine.id_wl_machine%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Generates a call to patient. Unlike the set_item_call_queue family of functions, it does not depend on
    * ticket or episodes, thus allowing the Screen application to call patients without them being efectivated
    * or taking a ticket. Also, this function assumes that the machine of the professional calling the patient is on the
    * same clinical service than the screen. (at least, currently)
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE  The episode ID
    * @param   O_MESSAGE_AUDIO The audio message in text
    * @param   O_SOUND_FILE The sound file created
    * @param   O_MAC Internal name of machine
    * @param   O_MSG Id of WL_CALL_QUEUE
    * @param   O_ERROR an error message, set when return=false
    */
    FUNCTION item_call_system_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_room       IN NUMBER,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Notify the patient call to external admission software
     * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_PAT  The patient id
    * @param  i_id_episode The episode id
    */
    FUNCTION item_call_system
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************************************
    *
    * Get configuration about the machine executing a waiting line module.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_NAME_PC the machine name.
    * @param   O_ID_PC The wl_machine to which I_NAME_PC is associated.
    * @param   O_VIDEO 'Y' if machine trasmits video, 'N' otherwise
    * @param   O_AUDIO 'B' if machine trasmits bip, 'V' for voice, 'B' for both
    * @param   O_ID_DEPARTMENT The department id where the machine is located
    * @param   O_ID_INSTITUTION The institution id associated with the department
    * @param   o_call_exec_mapping 'Y' call execute_mapping service, 'N' otherwise
    * @param   O_INTERFACE_UPDATE_TIME The interval time in ms to get patients from the interface
    * @param   O_SOFTWARE_ID The Waiting Room software id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006
    */
    FUNCTION get_id_machine
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_name_pc               IN VARCHAR2,
        o_id_pc                 OUT NUMBER,
        o_video                 OUT VARCHAR2,
        o_audio                 OUT VARCHAR2,
        o_id_department         OUT NUMBER,
        o_id_institution        OUT NUMBER,
        o_call_exec_mapping     OUT VARCHAR2,
        o_interface_update_time OUT NUMBER,
        o_software_id           OUT NUMBER,
        o_flg_mach_type         OUT VARCHAR2,
        o_max_ticket_shown      OUT NUMBER,
        o_kiosk_exists          OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the defined value for a sys_config. Does not require user validation.
    *
    * @param      i_code_cf               Configs required
    * @param      i_prof_inst             Institution ID
    * @param      i_prof_soft              Software ID
    * @param      o_msg_cf                 Cursor with all configurations requested
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   17-02-2009
    */
    FUNCTION get_config
    (
        i_code_cf   IN table_varchar,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the machine currently associated with the professional (for calls of type M).
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      io_dep                  department identifier
    * @param      o_id_wl_mach            ID_WL_MACHINE of the professional's machine
    * @param      o_id_wl_room            ID_WL_ROOM of the professional's machine
    * @param      O_ERROR an error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Luís Maia
    * @version 2.5.0.7.7.3
    * @since   22-10-2009
    */
    FUNCTION get_prof_wl_mach
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        io_dep       IN OUT department.id_department%TYPE,
        o_id_wl_mach OUT wl_machine.id_wl_machine%TYPE,
        o_id_wl_room OUT room.id_room%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /********************************************************************************************
    *
    * Get configuration about the machine executing a waiting line module.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_SOUND_FILE The sound file name.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   21-11-2006
    **********************************************************************************************/
    FUNCTION set_item_call_queue_sound_gen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_sound_file IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *
    * Gets the next ticket to be called of the specified queue, or of all available queues if i_id_queue is null.
    *
    * @param      i_lang                language    ID;
    * @param      i_id_mach             ID of the Screen machine searching for the next ticket;
    * @param      i_id_queue            ID of the queue where to look for more tickets;
    * @param      i_flg_type            Type of the call: A - Admin (only displays the ticket number and the destination) or M - Clinical (displays the patient's name, photo and service where to head to);
    * @param      i_prf                 ID of the professional;
    * @param      o_message_audio       Message to be converted into an audio file.
    * @param      o_message_sound_file     ID of the professional;
    * @param      o_message_video       Messagf
    * @param      o_error               ID of the professional;
    *
    * @RETURN  The ID of the language.
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    **********************************************************************************************/
    FUNCTION get_item_call_queue
    (
        i_lang               IN NUMBER,
        i_id_mach            IN NUMBER,
        i_id_queue           IN NUMBER,
        i_prf                IN profissional,
        o_message_audio      OUT VARCHAR2,
        o_message_sound_file OUT VARCHAR2,
        o_message_video      OUT pk_types.cursor_type,
        o_flg_type           OUT VARCHAR2,
        o_item_call_queue    OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *
    * Send the ID of the machine and it will return its name
    *
    * @param      i_id_pc        ID of the WL_MACHINE
    * @param      o_name_pc      Name of the machine       
    *
    * @RETURN  True or False
    * @author  ?
    * @version 1.0
    * @since   ?
    **********************************************************************************************/
    FUNCTION get_name_machine
    (
        i_id_pc   IN NUMBER,
        o_name_pc OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *
    * Gets the language for the provided professional. If no language is set, it assumes the general language configured for WR
    *
    * @param      i_id_prof               ID of the professional    
    *
    * @RETURN  The ID of the language.
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_default_language(i_id_prof IN profissional) RETURN language.id_language%TYPE;

    /**
    * Gets the language for the provided professional. If no language is set, it assumes the general language configured for WR
    *
    * @param      i_id_prof               ID of the professional    
    * @param      o_id_lang               language
    * @param      o_error                 Error message
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   03-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_default_language
    (
        i_id_prof IN profissional,
        o_id_lang OUT language.id_language%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * 
    *  Get_timestamp_anytimezone criteria
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date    
    * @param      O_TIMESTAMP                  Timestamp variable output
    * @param      O_TIMESTAMP_STR              Timestamp variable ouput as string
    * @param      O_ERROR                      error
    *
    * @return     true or false
    * @author     Ricardo Nuno Almeida
    * @version    0.1
    * @since      2009/03/03
    **********************************************************************************************/
    FUNCTION get_timestamp_anytimezone
    (
        i_lang          IN language.id_language%TYPE,
        i_inst          IN institution.id_institution%TYPE,
        o_timestamp     OUT TIMESTAMP WITH TIME ZONE,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --  função auxiliar de pesquisa em PL/SQL table
    FUNCTION search_table_number
    (
        i_table  IN table_number,
        i_search IN NUMBER
    ) RETURN NUMBER;

    /********************************************************************************************
     *   
     *  Function called by Jobs to reset the provided queue.
     *
     * @param x_id_queue              ID of the Queue to clean.          
     * @param x_num_queue             Initial value of the queue number.
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    PROCEDURE clean_queues
    (
        x_id_queue  IN NUMBER,
        x_num_queue IN NUMBER,
        o_error     OUT t_error_out
        
    );

    PROCEDURE clean_queues
    (
        x_id_queue  IN NUMBER,
        x_num_queue IN NUMBER
    );

    /********************************************************************************************
     *   
     *  Returns the Ads to be displayed on a Screen, for the provided department and machine.     
     *
     * @param i_lang                  i_lang
     * @param i_prof                  ID of the professional asking     
     * @param i_id_department         ID of the department
     * @param o_error             
     * @param o_ads                   Cursor with the advertisement files.
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           10-02-2009
    **********************************************************************************************/
    FUNCTION get_ad
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_machine IN wl_machine.id_wl_machine%TYPE,
        o_error         OUT t_error_out,
        o_ads           OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns the ID from the WR software     
     *
     *
     * @return                         NUMBER representing the ID of the WR software 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         1.0
     * @since                           03-03-2009
    **********************************************************************************************/
    FUNCTION get_id_software RETURN NUMBER;

    /********************************************************************************************
    * Get Waiting Room software id.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_ID_SOFTWARE The software id associated with the Waiting Room
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   14-11-2006
    **********************************************************************************************/
    FUNCTION get_id_software
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns the ID from the WR software     
     *
     *
     * @param o_id_software            ID of the software.
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         1.0
     * @since                           03-03-2009
    **********************************************************************************************/
    FUNCTION get_id_software
    (
        o_id_software OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns a description of the institutions available 
     *
     * @param i_prf                   The ALERT professional to be logged          
     * @param o_dpt                   ID of the Institution
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_institution
    (
        i_prf   IN profissional,
        o_ist   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns a description of all departments available for WR. 
     *
     * @param i_prf                   The ALERT professional to be logged          
     * @param o_dpt                ID of the Department
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           ?
    **********************************************************************************************/
    FUNCTION get_department
    (
        i_prf   IN profissional,
        o_dpt   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Logging function; registers the login of the professional in table prof_soft_inst
     *
     * @param i_prf                   The ALERT professional to be logged          
     * @param i_id_dpt                ID of the Department
     * @param o_error 
     *
     * @return                         true or false 
     *
     * @author                          ?
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION set_default
    (
        i_prf    IN profissional,
        i_id_dpt IN department.id_department%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns the messages that should appear on the kiosk. 
     *  Note that the language provided may not be the same of the messages returned. Those will be translated to the language defined in SYS_CONFIG
     *
     * @param i_lang                   Language ID
     * @param i_prf                   The ALERT professional calling this function          
     * @param o_sql                    Cursor containing the messages
     * @param o_error 
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_kiosk_button
    (
        i_lang  IN language.id_language%TYPE,
        i_prf   IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns the messages that should appear on the applet buttons. 
     *
     * @param i_lang                   Language ID
     * @param i_prof                   The ALERT professional calling this function     
     * @param o_error 
     * @param o_sql                    Cursor containing the messages
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_applet_button
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out,
        o_sql   OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *
     *  Function used for WR-INT integration with the ambulatory. Should be invoked when a 
     *
     * @param i_lang                   Language ID
     * @param i_prof                   The ALERT professional calling this function
     * @param i_c_prof                 And "extra" professional, when necessary for the admission process.
     * @param i_pat                    The patient going through admission process
     * @param i_clin_serv                   Clinical service ID
     * @param i_epis                  The episode to be associated with the WR ticket.
     * @param i_dt_cons                 Date of the consult.
     * @param o_error                  Structure instanciated whenever there's an exception.
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/03/12
    **********************************************************************************************/
    FUNCTION set_pat_admission
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_c_prof    IN professional.id_professional%TYPE,
        i_pat       IN patient.id_patient%TYPE,
        i_clin_serv IN clinical_service.id_clinical_service%TYPE,
        i_inst      IN institution.id_institution%TYPE,
        i_epis      IN episode.id_episode%TYPE,
        i_dt_cons   IN wl_waiting_line.dt_consult_tstz%TYPE,
        o_id_wl     OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *  Mainly for usage in WR-INT, on the nurse's and physician's patient grids. Checks if a given episode 
     * is available to be called.
     *
     * @param i_lang 
     * @param i_prof 
     * @param i_id_episode 
     * @param i_flg_state 
     * @param i_flg_ehr
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/05
    **********************************************************************************************/
    FUNCTION get_available_for_call
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_state  IN schedule_outp.flg_state%TYPE,
        i_flg_ehr    IN episode.flg_ehr%TYPE
    ) RETURN VARCHAR2;

    -- Overload for use in SQL queries.
    FUNCTION get_available_for_call
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    -- Core function of the above, which in fact simply calls this one overload.
    FUNCTION get_available_for_call
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out,
        o_result     OUT VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Ends admin ticket attending and creates support to nurse or doctor call .
    * Patients with "efectivação" are treated.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_MACH The machine name id.
    * @param   I_ID_PAT The patient  id.
    * @param   I_ID_ROOM The room id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   15-11-2006
    */
    FUNCTION set_end_line
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        i_id_wait IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_pat  IN table_number,
        i_id_room IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Ends admin ticket attending and creates support to nurse or doctor call .
    * Patients with "efectivação" are treated. Function to be use by interface.
    *
    * @param   I_LANG             language associated to the professional executing the request
    * @param   I_PROF             professional, institution and software ids    
    * @param   I_ID_PATIENT       Patient id.
    *
    * @param   O_ERROR            error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   24-Nov-2010
    *
    * dependencies: Interfaces Team
    */
    FUNCTION set_end_line_intf
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Internal function to check if the value for wl_queue.char_queue needs to be altered in order to be
     * correctly read by Loquendo. Example: for the Portuguese language, the letter 'A' should be read like 'À'
     * 
     *
     * @param i_lang                   Language of the call
     * @param i_prof                   ALERT Professional  
     * @param i_char                   Char_Queue to be 
     * @param o_result                 The value for the char to be correctly read by Loquendo
     * @param o_error                  Error structure
     *
     * @return                         true or false for success
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         2.5.0.6
     * @since                           2009/09/22
    **********************************************************************************************/
    FUNCTION get_wl_queue_char_queue
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_char   IN wl_queue.char_queue%TYPE,
        o_result OUT g_wl_queue_char,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the screen machines that correspond to the provided clinical machine.
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_id_wl_mach            ID_WL_MACHINE of the professional's machine
    * @param      o_id_wl_screens         List of IDs of WL_MACHINEs that will issue the provided machine's calls
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009/10/23
    **********************************************************************************************/
    FUNCTION get_screen_mach
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_wl_mach    IN wl_machine.id_wl_machine%TYPE,
        o_id_wl_screens OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *
    * Makes the correspondence between the WR code of a color and its hexadecimal value. If no correspondance is possible,
    * the same value entered is returned. 
    *
    * @param      i_lang        ID of the language
    * @param      i_prof       professional
    * @param      i_color       Code of the color. 
    *
    * @RETURN  VARCHAR2 the hexa value of the color.
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14/01/2010
    **********************************************************************************************/
    FUNCTION get_queue_color
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_color IN wl_queue.color%TYPE
    ) RETURN wl_queue.color%TYPE;

    /********************************************************************************************
    *
    * Call next patient waiting after having a ticket, for the specified type of queue.
    *
    * @param   I_LANG language id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_TYPE_QUEUE Queue type to be considered on the next call.
    * @param   O_DATA_WAIT The info about next call
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   20-03-2009
    **********************************************************************************************/
    FUNCTION get_next_call_ni
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_queue IN wl_queue.flg_type_queue%TYPE,
        o_data_wait  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Generates a waiting_line to patient from the nurse or doctor
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE  The episode id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   26-11-2006
    */
    FUNCTION set_discharge_internal
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION count_kiosk_department
    (
        i_prof         IN profissional,
        i_machine_name IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION wr_call
    (
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_max_tickets_shown
    (
        i_prof       IN profissional,
        i_id_machine IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_last_called_tickets
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_machine IN NUMBER,
        o_result     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_from_mach(i_id_machine IN NUMBER) RETURN NUMBER;

    FUNCTION get_mach_of_room(i_id_room IN NUMBER) RETURN NUMBER;

END pk_wlcore;
/
