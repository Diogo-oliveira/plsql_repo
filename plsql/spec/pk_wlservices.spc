/*-- Last Change Revision: $Rev: 2029059 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wlservices IS

    -- Author  : RICARDO.ALMEIDA
    -- Created : 02-03-2009 16:43:02
    -- Purpose : To isolate the functions that trigger the usage of java logic, in the java/middleware tier.
    --           The main objective is to easen up the Middleware team's work.

    /********************************************************************************************
     *
     *  Creates a new entry to be called by the Screen application.
     *
     * @param i_lang                  Language ID
     * @param i_id_wl                 ID of the ticket to be called
     * @param i_id_mach_ped           ID of the machine issuing the call.
     * @param i_prof                  Professional issuing the call.
     * @param i_id_mach_ped           ID of the destination machine
     * @param o_message_audio         Message to be converted into an audio file.
     * @param o_sound_file            Name of the audio file to be created.
     * @param o_mac                   IDs of the machines where the message will be displayed
     * @param o_msg                   Messages to appear on the screen
     * @param o_error
     *
     * @return                         true or false
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           10/02/2009
    **********************************************************************************************/
    FUNCTION set_item_call_queue
    (
        i_lang          IN language.id_language%TYPE,
        i_id_wl         IN wl_waiting_line.id_wl_waiting_line%TYPE,
        i_id_mach_ped   IN wl_machine.id_wl_machine%TYPE,
        i_prof          IN profissional,
        i_id_mach_dest  IN wl_machine.id_wl_machine%TYPE,
        i_id_episode    IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_room       IN NUMBER,
        o_message_audio OUT VARCHAR2,
        o_sound_file    OUT VARCHAR2,
        o_mac           OUT table_varchar,
        o_msg           OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- ########################################################################################
    /**
    * Generates a call to patient. Unlike the set_item_call_queue family of functions, it does not depend on
    * ticket or episodes, thus allowing the Screen application to call patients without them being efectivated
    * or taking a ticket. Also, this function assumes that the machine of the professional calling the patient is on the
    * same clinical service than the screen. (at least, currently)
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_PAT  The patient id
    * @param   O_MESSAGE_AUDIO The audio message in text
    * @param   O_SOUND_FILE The sound file created
    * @param   O_MAC Internal name of machine
    * @param   O_MSG Id of WL_CALL_QUEUE
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 0.1
    * @since   26-01-2009
    */
    FUNCTION set_item_call
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
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
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009-10-23
    */
    FUNCTION set_item_call_epis
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
    * Shortcut to the function @ PK_WLSESSION. This happens because even though  UNSET_QUEUES does not have 
    * any associated java logic, it is nevertheless called by the middleware and therefore needs to be instanciated 
    * in this package, to avoid instanciating two diferent packages instead of one.
    *    
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_MACH   ID of the machine.
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   26-03-2009
    **********************************************************************************************/
    FUNCTION unset_queues
    (
        i_prof    IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE
    ) RETURN BOOLEAN;

    /**
    * Notify the patient call to external admission software
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param  i_id_episode epsisode
    */
    FUNCTION set_item_call_external
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000); -- Localização do erro

    xsp                VARCHAR2(0050);
    pk_med_msg_01      VARCHAR2(0050);
    pk_med_msg_02      VARCHAR2(0050);
    g_ret              BOOLEAN;
    pk_med_msg_tit_01  VARCHAR2(0050);
    pk_med_msg_tit_02  VARCHAR2(0050);
    pk_med_msg_tit_03  VARCHAR2(0050);
    pk_voice           VARCHAR2(0050);
    pk_bip             VARCHAR2(0050);
    pk_none            VARCHAR2(0050);
    pk_wavfile_prefix  VARCHAR2(0050);
    pk_wavfile_sufix   VARCHAR2(0050);
    pk_wl_titulo       VARCHAR2(0050);
    pk_wl_wav_bip_name VARCHAR2(0050);
    pk_wl_id_sonho     VARCHAR2(0050);
    pk_pendente        VARCHAR2(0050);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_exception EXCEPTION;

END pk_wlservices;
/
