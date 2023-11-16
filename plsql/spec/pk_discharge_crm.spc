/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE pk_discharge_crm IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 17-09-2013 09:09:33
    -- Purpose : Communication to CRM

    -- Public type declarations
    TYPE t_rec_disch_rep_cfg IS RECORD(
        id_report       reports.id_reports%TYPE, -- ID_RECORD
        flg_send        VARCHAR2(1 CHAR), -- FIELD_01
        flg_send_to_crm VARCHAR2(1 CHAR), -- FIELD_02
        generation_rank NUMBER(24) -- FIELD_03
        );
    TYPE t_table_disch_rep_cfg IS TABLE OF t_rec_disch_rep_cfg;

    -- Config table for reports sent on discharge
    g_discharge_reports_ct VARCHAR2(30 CHAR) := 'DISCHARGE_REPORT';
    g_flg_status_crm_req   discharge_report.flg_status%TYPE := 'R';
    g_flg_status_crm_sent  discharge_report.flg_status%TYPE := 'S';

    g_discharge_message VARCHAR2(200 CHAR) := 'EDIS_EMAIL_001';

    g_gp_name                CONSTANT VARCHAR2(100 CHAR) := 'GP_NAME';
    g_episode_date           CONSTANT VARCHAR2(100 CHAR) := 'EPISODE_DATE';
    g_episode_time           CONSTANT VARCHAR2(100 CHAR) := 'EPISODE_TIME';
    g_episode_finaldiagnoses CONSTANT VARCHAR2(100 CHAR) := 'EPISODE_FINALDIAGNOSES';
    g_episode_prof_name      CONSTANT VARCHAR2(100 CHAR) := 'EPISODE_PROFESSIONAL_NAME';
    g_patient_name           CONSTANT VARCHAR2(100 CHAR) := 'PATIENT_NAME';
    g_patient_nhs            CONSTANT VARCHAR2(100 CHAR) := 'PATIENT_NHS';
    g_address_1              CONSTANT VARCHAR2(100 CHAR) := 'ADDRESS_1';
    g_address_2              CONSTANT VARCHAR2(100 CHAR) := 'ADDRESS_2';
    g_address_3              CONSTANT VARCHAR2(100 CHAR) := 'ADDRESS_3';
    g_address_4              CONSTANT VARCHAR2(100 CHAR) := 'ADDRESS_4';
    g_address_5              CONSTANT VARCHAR2(100 CHAR) := 'ADDRESS_5';
    g_gp_id_01               CONSTANT VARCHAR2(100 CHAR) := 'GP_ID_01';

    /**********************************************************************************************
    * Send Message to CRM 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_ws_name               Web service name
    * @param i_id_diet               ID Diet to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.3
    * @since                         2013/09/18
    **********************************************************************************************/
    FUNCTION send_message_to_crm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_ws_name       IN VARCHAR2,
        i_discharge_msg IN pk_edis_types.rec_disch_message,
        o_ws_response   OUT CLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Set a discharge_report configuration.                                   *
    *                                                                         *
    * @param i_id_report                Report to be generated                *
    * @param i_flg_send                 Send report on discharge?             *
    *                                        Y - yes; N - otherwise           *
    * @param i_flg_send_by_crm          Send report to crm?                   *
    *                                        Y - yes; N - otherwise           *
    * @param i_generation_rank          Rank for report sending               *
    *                                                                         *
    * @author   Nuno Alves                                                    *
    * @version  2.6.3.8.2                                                     *
    * @since    14-05-2015                                                    *
    **************************************************************************/
    PROCEDURE set_discharge_rep_cfg
    (
        i_software        IN software.id_software%TYPE,
        i_market          IN market.id_market%TYPE DEFAULT 0,
        i_institution     IN institution.id_institution%TYPE DEFAULT 0,
        i_id_report       IN reports.id_reports%TYPE, -- id_record
        i_flg_send        IN VARCHAR2, -- FIELD_01
        i_flg_send_to_crm IN VARCHAR2, -- FIELD_02
        i_generation_rank IN VARCHAR2, -- FIELD_03
        i_id_inst_owner   IN NUMBER DEFAULT 0,
        i_flg_add_remove  IN VARCHAR2 DEFAULT 'A'
    );

    /**************************************************************************
    * return configurations for discharge reports                             *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                                                         *
    * @return                         return list of configs                  *
    *                                                                         *
    * @author                         Nuno Alves                              *
    * @version                        2.6.3.8.2                               *
    * @since                          2015/05/14                              *
    **************************************************************************/
    FUNCTION tf_discharge_report_cfg
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_report IN reports.id_reports%TYPE DEFAULT NULL
    ) RETURN t_table_disch_rep_cfg
        PIPELINED;

    /**************************************************************************
    * Check if report is to be sent to crm                                    *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    * @param i_id_report              Report ID                               *
    *                                                                         *
    * @return                         'Y' or 'N'                              *
    *                                                                         *
    * @author                         Nuno Alves                              *
    * @version                        2.6.3.8.2                               *
    * @since                          2015/05/14                              *
    **************************************************************************/
    FUNCTION check_send_to_crm
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get report generation rank                                              *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    * @param i_id_report              Report ID                               *
    *                                                                         *
    * @return                         Rank                                    *
    *                                                                         *
    * @author                         Nuno Alves                              *
    * @version                        2.6.3.8.2                               *
    * @since                          2015/05/14                              *
    **************************************************************************/
    FUNCTION get_report_rank
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN NUMBER;

END pk_discharge_crm;
/
