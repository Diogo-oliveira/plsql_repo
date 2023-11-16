/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_sr_approval AS
    /**************************************************************************
    * Check if the approval request can be done                               *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/13                              *
    **************************************************************************/
    FUNCTION check_status_for_approval
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns information for the approval/reject surgery pop-up              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_msg_text                   message to be display in pop-up     *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/09                              *
    **************************************************************************/
    FUNCTION get_info_for_approval
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_label   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
      * send the approval request for the director                              *
      *                                                                         *
      * @param i_lang                       language id                         *
      * @param i_prof                       professional, software and          *
      *                                     institution ids                     *
      * @param i_id_episode                 id episode ORIS                     *
      * @param i_patient                    id patient                          *
      * @param i_episode                    id episode                          *
      * @param i_notes                      notes                               *
      *                                                                         *
      * @param o_error                      Error message                       *
      *                                                                         *
      * @return                         Returns boolean                         *
      *                                                                         *
      * @author                         Filipe Silva                            *
      * @version                        1.0                                     *
      * @since                          2009/10/13                              *
    *                                                                         *
      **************************************************************************/
    FUNCTION send_approval_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_notes      IN approval_request.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * return string with the surgical procedures                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode                          *
    *                                                                         *   
    * @return                         Returns string                          *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/13                              *
    **************************************************************************/
    FUNCTION get_proposed_surgery
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * director approve the approval request                                   *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns yes or no                       *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION approve_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * director reject the approval request                                    *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns yes or no                       *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION reject_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * if the surgical process is edited then check if the consent is assign and show message to inform this.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_episode          Identifier of the Episode
    * @param i_flg_status       Target flag status (E-Edit; C-Cancel)
    * @param o_show_msg         Flag that inform If the message is showed or not
    * @param o_msg              Messages cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Filipe Silva
    * @version                  1.0
    * @since                    2009/10/19
    *
    *********************************************************************************************/
    FUNCTION check_surg_process_edition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2,
        o_show_msg   OUT VARCHAR,
        o_msg        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
       * check if the approve request can be approve or reject by the director   *
       *                                                                         *
       * @param i_lang                       language id                         *
       * @param i_prof                       professional, software and          *
       *                                     institution ids                     *
       * @param i_episode                    id_episode                          *
       * @param id_external                  id_external ( id_episode ORIS)      *
       *                                                                         *
       * @param i_dates                    table_varchar with id_doc_area and    * 
       *                                    last update date  (8|2009102110300)  *
       *                                                                         *
       * @param o_show_msg                  (Y) show message / (N) no show msg   *
       * @param o_msg                       cursor with information to show in   *
       *                                    popup                                *
       * @param o_error                      Error message                       *
       *                                                                         *
       * @return                         Returns boolean                         *
       *                                                                         *
       * @author                         Filipe Silva                            *
       * @version                        1.0                                     *
       * @since                          2009/10/21                              *
       *
    /*****************************************************************************/

    FUNCTION check_approval_to_change
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_external IN approval_request.id_external%TYPE,
        i_dates    IN table_varchar,
        o_show_msg OUT VARCHAR,
        o_msg      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_approval_proc_pipelined
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_approval_type IN approval_request.id_approval_type%TYPE
    ) RETURN t_coll_approval_proc_resume
        PIPELINED;

    /**************************************************************************
    * Returns information to put in the Cirurgical process resume             *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/22                              *
    **************************************************************************/
    FUNCTION get_approval_process_resume
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_approval_type   IN approval_request.id_approval_type%TYPE,
        o_approval_resume OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns information for detail screen                                   *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/22                              *
    **************************************************************************/
    FUNCTION get_approval_proc_resume_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_approval_type   IN approval_request.id_approval_type%TYPE,
        o_approval_resume OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * director dummy cancel the approval request                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION cancel_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * director dummy check cancel the approval request function               *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION check_cancel_approval_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    *get the last status in ti_log                                            *
    *                                                                         *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    * @param i_status                     list of status surgical process     *
    *                                                                         *
    * @return                         Returns the last status                 *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.5.07                                  *
    * @since                          2009/10/27                              *
    **************************************************************************/
    FUNCTION get_last_status_surg_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_status  IN table_varchar
    ) RETURN VARCHAR2;

    /**************************************************************************
    *check status rank to check if is available to change or not the new      *
    *status                                                                   *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    * @param i_old_status                 previous pacient status             *
    * @param i_new_status                 new pacient status                  *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/19                              *
    **************************************************************************/
    FUNCTION check_change_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_old_status IN sr_pat_status.flg_pat_status%TYPE,
        i_new_status IN sr_pat_status.flg_pat_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *get the surgery status                                                   *
    *                                                                         *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    id episode ORIS                     *
    *                                                                         *
    * @return                         Returns the last status                 *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.6                                     *
    * @since                          2010/03/12                              *
    **************************************************************************/
    FUNCTION get_status_surg_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    g_error VARCHAR2(2000);

    g_id_doc_area doc_area.id_doc_area%TYPE := 12;
    g_found       BOOLEAN;

    --surgical process status
    g_inc_request          CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'E';
    g_pending_send_request CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'N';
    g_pending_approval     CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'P';
    g_granted_approval     CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'A';
    g_rejected_approval    CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'R';
    g_in_surgery           CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'S';
    g_completed_surgery    CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'F';
    g_cancel_surgery       CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'C';
    g_pending              CONSTANT sr_surgery_record.flg_sr_proc%TYPE := 'W';

    g_appr_type_oris approval_type.id_approval_type%TYPE := 11;
    -- sr_epis_interv
    g_sr_epis_interv_status_c CONSTANT sr_epis_interv.flg_status%TYPE := 'C';

    g_flg_status CONSTANT sr_consent.flg_status%TYPE := 'A';

    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_SR_APPROVAL';

    -- 
    g_scheduled  CONSTANT sys_domain.code_domain%TYPE := 'S';
    g_undergoing CONSTANT sys_domain.code_domain%TYPE := 'U';
    g_done       CONSTANT sys_domain.code_domain%TYPE := 'D';
    g_cancelled  CONSTANT sys_domain.code_domain%TYPE := 'C';

    --revision to various content for all EN markets (AN 28-Jun-2011 [ALERT-176678])
    g_flg_status_message_c CONSTANT VARCHAR2(1) := 'C';
    g_flg_status_message_e CONSTANT VARCHAR2(1) := 'E';
    g_msg_title_1_e        CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_T397';
    g_msg_title_1_c        CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_T399';
    g_msg_title_2_e        CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_M002';
    g_msg_title_2_c        CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_M020';
    g_msg_text_1_e         CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_M009';
    g_msg_text_1_c         CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_M009';
    g_msg_text_2_e         CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_M010';
    g_msg_text_2_c         CONSTANT VARCHAR2(13 CHAR) := 'SR_LABEL_M021';

    /****************************************************************************
    * update approvals' episodes to mantain integrity during "match" operation  *
    *                                                                           *
    * @param i_lang             language id                                     *
    * @param i_prof             professional info                               *
    * @param i_episode          final episode id                                *
    * @param i_episode_temp     temporary episode id                            *
    * @param o_error            error control                                   *
    *                                                                           *
    * @return                         Returns boolean (true - succes)           *
    *                                                                           *
    * @author                         Sérgio Dias                               *
    * @version                        1.0                                       *
    * @since                          2010/07/6                                 *
    ****************************************************************************/
    FUNCTION approval_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
END pk_sr_approval;
/
