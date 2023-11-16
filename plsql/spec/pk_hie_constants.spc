/*-- Last Change Revision: $Rev: 2028718 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hie_constants IS
    -- Author  : ARIEL.MACHADO
    -- Created : 25-Nov-09 6:49:32 PM
    -- Purpose : Constants used in HIE modules

    g_xds_cfg_alert_content_scheme CONSTANT sys_config.id_sys_config%TYPE := 'XDS_ALERT_CONTENT_SCHEME';
    g_xds_cfg_xds_enabled          CONSTANT sys_config.id_sys_config%TYPE := 'XDS_ENABLED';
    g_xds_submission_status_pend   CONSTANT xds_document_submission.flg_submission_status%TYPE := 'P';
    g_xds_submission_status_sent   CONSTANT xds_document_submission.flg_submission_status%TYPE := 'S';
    g_xds_submission_status_err    CONSTANT xds_document_submission.flg_submission_status%TYPE := 'X';
    g_rpt_area_report_report       CONSTANT rep_profile_template_det.flg_area_report%TYPE := 'R'; --Report documents
    g_rpt_area_report_cda          CONSTANT rep_profile_template_det.flg_area_report%TYPE := 'CDA'; --CDA(Clinical Document Architecture) Documents

END pk_hie_constants;
/
