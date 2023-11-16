/*-- Last Change Revision: $Rev: 2028450 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_alert_constant IS

    FUNCTION get_no RETURN VARCHAR2;
    FUNCTION get_yes RETURN VARCHAR2;
    FUNCTION get_available RETURN VARCHAR2;

    -- Author  : CARLOS.VIEIRA
    -- Created : 17-04-2008 14:31:08
    -- Purpose : Generic alert constant configuration

    /*
    ******************************************************************************************************************************************
      * Nome :                          date_hour_send_format                                                                                    *
      * Descrição:  Return global format date to sent to flash                                                                                   *
      *                                                                                                                                          *
      * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
      *                                                                                                                                          *
      * @return                         Return global true/false                                                                                 *
      * @raises                         Generic oracle error                                                                                     *
      *                                                                                                                                          *
      * @author                         Carlos Vieira                                                                                            *
      * @version                         1.0                                                                                                     *
      * @since                          2008/04/17                                                                                               *
      *******************************************************************************************************************************************/
    PROCEDURE date_hour_send_format(i_prof IN profissional);

    /*
    ******************************************************************************************************************************************
      * Nome :                          GET_TIMESCALE_ID                                                                                    *
      * Descrição:  Return TIMESCALE IDENTIFIERS                                                                                   *
      *                                                                                                                                          *
      * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
      *                                                                                                                                          *
      *                                                                                                                                          *
      * @author                         Carlos Vieira                                                                                            *
      * @version                         1.0                                                                                                     *
      * @since                          2008/04/17                                                                                               *
      *******************************************************************************************************************************************/
    PROCEDURE get_timescale_id;
    /*
    ******************************************************************************************************************************************
      * Nome :                          get_timezone                                                                                             *
      * Descrição:  Return timezone for each institution                                                                                         *
      *                                                                                                                                          *
      * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
      * @param i_prof                   Professional                                                                                             *
      * @param o_error                  Error message, if an error occurred.                                                                     *
      *                                                                                                                                          *
      *                                                                                                                                          *
      * @author                         Carlos Vieira                                                                                            *
      * @version                         1.0                                                                                                     *
      * @since                          2008/04/17                                                                                               *
      *******************************************************************************************************************************************/
    PROCEDURE get_timezone
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    );

    -- Global variables
    g_date_hour_send_format VARCHAR2(50);
    g_decade                NUMBER(4) := 1;
    g_year                  NUMBER(4) := 2;
    g_month                 NUMBER(2) := 3;
    g_week                  NUMBER(2) := 4;
    g_day                   NUMBER(4) := 5;
    g_hour                  NUMBER(4) := 6;
    g_shift                 NUMBER(4) := 7;
    g_institution_timezone  VARCHAR2(250);

    g_seconds_per_day CONSTANT NUMBER := 86400;

    g_active    CONSTANT VARCHAR2(1) := 'A';
    g_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_pending   CONSTANT VARCHAR2(1) := 'P';
    g_cancelled CONSTANT VARCHAR2(1) := 'C';
    g_outdated  CONSTANT VARCHAR2(1) := 'O';

    g_available CONSTANT VARCHAR2(1) := 'Y';

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';
    g_na  CONSTANT VARCHAR2(1) := 'A'; -- Not applicable
    g_si  CONSTANT VARCHAR2(2) := 'SI'; -- SI ignora
    g_ne  CONSTANT VARCHAR2(2) := 'NE'; -- NO ESPECIFICADO

    g_flg_time_e CONSTANT VARCHAR2(1) := 'E'; -- In this episode
    g_flg_time_b CONSTANT VARCHAR2(1) := 'B'; -- Between episodes
    g_flg_time_n CONSTANT VARCHAR2(1) := 'N'; -- Next episode
    g_flg_time_r CONSTANT VARCHAR2(1) := 'R'; -- Brought by patient
    g_flg_time_a CONSTANT VARCHAR2(1) := 'A'; -- across care settings

    g_flg_ehr_n CONSTANT VARCHAR2(1) := 'N';

    g_flg_status_a     CONSTANT VARCHAR2(1) := 'A'; -- Scheduled
    g_flg_status_c     CONSTANT VARCHAR2(1) := 'C'; -- Canceled
    g_flg_status_d     CONSTANT VARCHAR2(1) := 'D'; -- Pending
    g_flg_status_r     CONSTANT VARCHAR2(1) := 'R'; -- Requested
    g_flg_status_e     CONSTANT VARCHAR2(1) := 'E'; -- In execution
    g_flg_status_f     CONSTANT VARCHAR2(1) := 'F'; -- Finished
    g_flg_status_fp    CONSTANT VARCHAR2(1) := 'P'; -- Partially finished
    g_flg_status_l     CONSTANT VARCHAR2(1) := 'L'; -- Result read
    g_flg_status_adm   CONSTANT VARCHAR2(1) := 'A'; -- Administred
    g_flg_status_nexec CONSTANT VARCHAR2(1) := 'N'; -- Not executed

    g_rank_acuity CONSTANT NUMBER(3) := 999;

    -- epis_type enum
    g_epis_type_outpatient        CONSTANT epis_type.id_epis_type%TYPE := 1;
    g_epis_type_emergency         CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_type_operating         CONSTANT epis_type.id_epis_type%TYPE := 4;
    g_epis_type_inpatient         CONSTANT epis_type.id_epis_type%TYPE := 5;
    g_epis_type_observation       CONSTANT epis_type.id_epis_type%TYPE := 6;
    g_epis_type_primary_care      CONSTANT epis_type.id_epis_type%TYPE := 8;
    g_epis_type_urgent_care       CONSTANT epis_type.id_epis_type%TYPE := 9;
    g_epis_type_private_practice  CONSTANT epis_type.id_epis_type%TYPE := 11;
    g_epis_type_lab               CONSTANT epis_type.id_epis_type%TYPE := 12;
    g_epis_type_rad               CONSTANT epis_type.id_epis_type%TYPE := 13;
    g_epis_type_case_manager      CONSTANT epis_type.id_epis_type%TYPE := 19;
    g_epis_type_exam              CONSTANT epis_type.id_epis_type%TYPE := 21;
    g_epis_type_social            CONSTANT epis_type.id_epis_type%TYPE := 22;
    g_epis_type_interv            CONSTANT epis_type.id_epis_type%TYPE := 24;
    g_epis_type_nurse_care        CONSTANT epis_type.id_epis_type%TYPE := 14;
    g_epis_type_nurse_outp        CONSTANT epis_type.id_epis_type%TYPE := 16;
    g_epis_type_nurse_pp          CONSTANT epis_type.id_epis_type%TYPE := 17;
    g_epis_type_dietitian         CONSTANT epis_type.id_epis_type%TYPE := 18;
    g_epis_type_rehab_session     CONSTANT epis_type.id_epis_type%TYPE := 15;
    g_epis_type_rehab_appointment CONSTANT epis_type.id_epis_type%TYPE := 25;
    g_epis_type_psychologist      CONSTANT epis_type.id_epis_type%TYPE := 26;
    g_epis_type_resp_therapist    CONSTANT epis_type.id_epis_type%TYPE := 27;
    g_epis_type_cdc_appointment   CONSTANT epis_type.id_epis_type%TYPE := 28;
    g_epis_type_home_health_care  CONSTANT epis_type.id_epis_type%TYPE := 50;
    g_epis_type_hhc_process       CONSTANT epis_type.id_epis_type%TYPE := 99;
    g_epis_type_speech_therapy    CONSTANT epis_type.id_epis_type%TYPE := 29;
    g_epis_type_occup_therapy     CONSTANT epis_type.id_epis_type%TYPE := 30;

    -- software enum
    g_soft_all              CONSTANT software.id_software%TYPE := 0;
    g_soft_outpatient       CONSTANT software.id_software%TYPE := 1;
    g_soft_oris             CONSTANT software.id_software%TYPE := 2;
    g_soft_primary_care     CONSTANT software.id_software%TYPE := 3;
    g_soft_referral         CONSTANT software.id_software%TYPE := 4;
    g_soft_edis             CONSTANT software.id_software%TYPE := 8;
    g_soft_inpatient        CONSTANT software.id_software%TYPE := 11;
    g_soft_private_practice CONSTANT software.id_software%TYPE := 12;
    g_soft_labtech          CONSTANT software.id_software%TYPE := 16;
    g_soft_imgtech          CONSTANT software.id_software%TYPE := 15;
    g_soft_social           CONSTANT software.id_software%TYPE := 24;
    g_soft_extech           CONSTANT software.id_software%TYPE := 25;
    g_soft_backoffice       CONSTANT software.id_software%TYPE := 26;
    g_soft_triage           CONSTANT software.id_software%TYPE := 35;
    g_soft_ubu              CONSTANT software.id_software%TYPE := 29;
    g_soft_adt              CONSTANT software.id_software%TYPE := 39;
    g_soft_case_manager     CONSTANT software.id_software%TYPE := 47;
    g_soft_nutritionist     CONSTANT software.id_software%TYPE := 43;
    g_soft_act_therapist    CONSTANT software.id_software%TYPE := 80;
    g_soft_pharmacy         CONSTANT software.id_software%TYPE := 20;
    g_soft_director         CONSTANT software.id_software%TYPE := 45;
    g_soft_resptherap       CONSTANT software.id_software%TYPE := 33;
    g_soft_rehab            CONSTANT software.id_software%TYPE := 36;
    g_soft_psychologist     CONSTANT software.id_software%TYPE := 310;
    g_soft_home_care        CONSTANT software.id_software%TYPE := 312;

    -- all institutions
    g_inst_all CONSTANT institution.id_institution%TYPE := 0;

    -- all profile templates
    g_profile_template_all profile_template.id_profile_template%TYPE := 0;

    -- institution type
    g_inst_type_primary_care      CONSTANT institution.flg_type%TYPE := 'C'; -- Primary care center
    g_inst_type_outpatient        CONSTANT institution.flg_type%TYPE := 'E'; -- Outpatient healthcare center
    g_inst_type_hospital          CONSTANT institution.flg_type%TYPE := 'H'; -- Hospital
    g_inst_type_private_practice  CONSTANT institution.flg_type%TYPE := 'P'; -- Private practice
    g_inst_type_health_department CONSTANT institution.flg_type%TYPE := 'R'; -- Health department
    g_inst_type_familiar_health   CONSTANT institution.flg_type%TYPE := 'U'; -- Familiar health center

    -- triage_color.flg_type
    g_triage_color_flgtype_outp    CONSTANT triage_color.flg_type%TYPE := 'C';
    g_triage_color_flgtype_nocolor CONSTANT triage_color.flg_type%TYPE := 'S';
    g_triage_color_flgtype_manches CONSTANT triage_color.flg_type%TYPE := 'M';
    g_triage_color_flgtype_noaval  CONSTANT triage_color.flg_type%TYPE := 'N';
    g_triage_color_flgtype_white   CONSTANT triage_color.flg_type%TYPE := 'W';

    -- ********************************************************************** --
    -- STATUS MESSAGE
    -- ********************************************************************** --

    -- task status color
    g_color_none              CONSTANT VARCHAR2(8 CHAR) := 'X';
    g_color_red               CONSTANT VARCHAR2(8 CHAR) := '0xC86464';
    g_color_green             CONSTANT VARCHAR2(8 CHAR) := '0x829664';
    g_color_white             CONSTANT VARCHAR2(8 CHAR) := '0xFFFFFF';
    g_color_orange            CONSTANT VARCHAR2(8 CHAR) := '0xD2A05A';
    g_color_black             CONSTANT VARCHAR2(8 CHAR) := '0x3C3C32';
    g_color_icon_light_yellow CONSTANT VARCHAR2(8 CHAR) := '0xF6D300';
    g_color_gray              CONSTANT VARCHAR2(8 CHAR) := '0x787864';
    g_color_icon_light_grey   CONSTANT VARCHAR2(8 CHAR) := '0xEBEBC8';
    g_color_icon_medium_grey  CONSTANT VARCHAR2(8 CHAR) := '0x919178';
    g_color_icon_dark_grey    CONSTANT VARCHAR2(8 CHAR) := '0x787864';
    g_color_null              CONSTANT VARCHAR2(8 CHAR) := NULL;

    -- status replace characters
    g_status_rpl_chr_text        CONSTANT VARCHAR2(1 CHAR) := '@';
    g_status_rpl_chr_text_domain CONSTANT VARCHAR2(1 CHAR) := '?';
    g_status_rpl_chr_icon        CONSTANT VARCHAR2(1 CHAR) := '#';
    g_status_rpl_chr_fixed_date  CONSTANT VARCHAR2(1 CHAR) := '$';
    g_status_rpl_chr_dt_server   CONSTANT VARCHAR2(1 CHAR) := '&';

    -- task status display types
    g_display_type_label      CONSTANT VARCHAR(1) := 'L';
    g_display_type_date       CONSTANT VARCHAR(1) := 'D';
    g_display_type_text       CONSTANT VARCHAR(1) := 'T';
    g_display_type_icon       CONSTANT VARCHAR(1) := 'I';
    g_display_type_text_icon  CONSTANT VARCHAR(2) := 'TI';
    g_display_type_date_icon  CONSTANT VARCHAR(2) := 'DI';
    g_display_type_fixed_date CONSTANT VARCHAR(2) := 'FD';

    -- date compare constants
    g_date_equal   CONSTANT VARCHAR(1) := 'E';
    g_date_greater CONSTANT VARCHAR(1) := 'G';
    g_date_lower   CONSTANT VARCHAR(1) := 'L';

    -- date formats
    g_dt_yyyymmddhh24miss     CONSTANT VARCHAR(30) := 'YYYYMMDDHH24MISS';
    g_dt_yyyymmddhh24miss_tzr CONSTANT VARCHAR(30) := 'YYYYMMDDHH24MISS TZR';
    g_dt_yyyymmddhh24miss_tzh CONSTANT VARCHAR(30) := 'YYYY-MM-DD HH24:MI:SS TZH:TZM';
    g_dt_tzh                  CONSTANT VARCHAR(30) := 'TZH:TZM';
    g_dt_yyyy                 CONSTANT VARCHAR2(30) := 'YYYY';
    g_dt_mm                   CONSTANT VARCHAR2(30) := 'MM';
    g_dt_iw                   CONSTANT VARCHAR2(30) := 'IW';
    g_dt_mi                   CONSTANT VARCHAR2(30) := 'MI';

    -- exam_req_det.flg_status
    g_exam_det_tosched    CONSTANT exam_req_det.flg_status%TYPE := 'PA';
    g_exam_det_sched      CONSTANT exam_req_det.flg_status%TYPE := 'A';
    g_exam_det_efectiv    CONSTANT exam_req_det.flg_status%TYPE := 'EF';
    g_exam_det_pend       CONSTANT exam_req_det.flg_status%TYPE := 'D';
    g_exam_det_req        CONSTANT exam_req_det.flg_status%TYPE := 'R';
    g_exam_det_canc       CONSTANT exam_req_det.flg_status%TYPE := 'C';
    g_exam_det_exec       CONSTANT exam_req_det.flg_status%TYPE := 'E';
    g_exam_det_result     CONSTANT exam_req_det.flg_status%TYPE := 'F';
    g_exam_det_read       CONSTANT exam_req_det.flg_status%TYPE := 'L';
    g_exam_det_transp     CONSTANT exam_req_det.flg_status%TYPE := 'T';
    g_exam_det_end_transp CONSTANT exam_req_det.flg_status%TYPE := 'M';
    g_exam_deq_not_done   CONSTANT exam_req_det.flg_status%TYPE := 'NR';
    g_exam_det_ext        CONSTANT exam_req_det.flg_status%TYPE := 'X';
    g_exam_det_performed  CONSTANT exam_req_det.flg_status%TYPE := 'EX';

    -- exam_req.flg_status
    g_exam_req_tosched  CONSTANT exam_req.flg_status%TYPE := 'PA';
    g_exam_req_sched    CONSTANT exam_req.flg_status%TYPE := 'A';
    g_exam_req_efectiv  CONSTANT exam_req.flg_status%TYPE := 'EF';
    g_exam_req_pend     CONSTANT exam_req.flg_status%TYPE := 'D';
    g_exam_req_req      CONSTANT exam_req.flg_status%TYPE := 'R';
    g_exam_req_canc     CONSTANT exam_req.flg_status%TYPE := 'C';
    g_exam_req_exec     CONSTANT exam_req.flg_status%TYPE := 'E';
    g_exam_req_result   CONSTANT exam_req.flg_status%TYPE := 'F';
    g_exam_req_read     CONSTANT exam_req.flg_status%TYPE := 'L';
    g_exam_req_partial  CONSTANT exam_req.flg_status%TYPE := 'P';
    g_exam_req_not_done CONSTANT exam_req.flg_status%TYPE := 'NR';

    -- exam_dep_clin_serv.flg_type
    g_exam_freq    CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'M';
    g_exam_can_req CONSTANT exam_dep_clin_serv.flg_type%TYPE := 'P';

    -- movement.flg_status
    g_mov_status_transp CONSTANT movement.flg_status%TYPE := 'T';
    g_mov_status_finish CONSTANT movement.flg_status%TYPE := 'F';
    g_mov_status_pend   CONSTANT movement.flg_status%TYPE := 'P';
    g_mov_status_req    CONSTANT movement.flg_status%TYPE := 'R';
    g_mov_status_interr CONSTANT movement.flg_status%TYPE := 'S';
    g_mov_status_cancel CONSTANT movement.flg_status%TYPE := 'C';

    -- discharge_schedule
    g_disch_sched_status_yes CONSTANT discharge_schedule.flg_status%TYPE := 'Y';
    g_disch_sched_status_no  CONSTANT discharge_schedule.flg_status%TYPE := 'N';

    -- ti_log.flg_type
    g_ti_type_vs            CONSTANT ti_log.flg_type%TYPE := 'VS'; -- Vital Signs
    g_ti_type_mn            CONSTANT ti_log.flg_type%TYPE := 'MN'; -- Monitorizations
    g_exam_type_req         CONSTANT ti_log.flg_type%TYPE := 'ER';
    g_exam_type_det         CONSTANT ti_log.flg_type%TYPE := 'ED';
    g_analysis_type_req     CONSTANT ti_log.flg_type%TYPE := 'AR';
    g_analysis_type_req_det CONSTANT ti_log.flg_type%TYPE := 'AD';
    g_comm_order_req        CONSTANT ti_log.flg_type%TYPE := 'CO';

    -- analysis_req_det.flg_status
    g_analysis_det_req    CONSTANT analysis_req_det.flg_status%TYPE := 'R';
    g_analysis_det_result CONSTANT analysis_req_det.flg_status%TYPE := 'F';
    g_analysis_det_canc   CONSTANT analysis_req_det.flg_status%TYPE := 'C';
    g_analysis_det_read   CONSTANT analysis_req_det.flg_status%TYPE := 'L';
    g_analysis_det_pend   CONSTANT analysis_req_det.flg_status%TYPE := 'D';
    g_analysis_det_exec   CONSTANT analysis_req_det.flg_status%TYPE := 'E';
    g_analysis_det_review CONSTANT analysis_req_det.flg_status%TYPE := 'S';
    g_analysis_det_ext    CONSTANT analysis_req_det.flg_status%TYPE := 'X';

    -- analysis_instit_soft.flg_type
    g_analysis_freq    analysis_instit_soft.flg_type%TYPE := 'M';
    g_analysis_request analysis_instit_soft.flg_type%TYPE := 'P';
    g_analysis_exec    analysis_instit_soft.flg_type%TYPE := 'W';

    -- harvest.flg_status
    g_harvest_harv  CONSTANT harvest.flg_status%TYPE := 'H';
    g_harvest_trans CONSTANT harvest.flg_status%TYPE := 'T';
    g_harvest_fin   CONSTANT harvest.flg_status%TYPE := 'F';
    g_harvest_canc  CONSTANT harvest.flg_status%TYPE := 'C';

    -- monitorization_vs.flg_status
    g_monitor_vs_exec   CONSTANT monitorization_vs.flg_status%TYPE := 'A';
    g_monitor_vs_fini   CONSTANT monitorization_vs.flg_status%TYPE := 'F';
    g_monitor_vs_pend   CONSTANT monitorization_vs.flg_status%TYPE := 'D';
    g_monitor_vs_canc   CONSTANT monitorization_vs.flg_status%TYPE := 'C';
    g_monitor_vs_inte   CONSTANT monitorization_vs.flg_status%TYPE := 'I';
    g_monitor_vs_draft  CONSTANT monitorization_vs.flg_status%TYPE := 'R';
    g_monitor_vs_expire CONSTANT monitorization_vs.flg_status%TYPE := 'E';

    -- drug_presc_det.flg_status
    g_presc_det_can  CONSTANT drug_presc_det.flg_status%TYPE := 'C';
    g_presc_det_sus  CONSTANT drug_presc_det.flg_status%TYPE := 'S';
    g_presc_det_exe  CONSTANT drug_presc_det.flg_status%TYPE := 'E';
    g_presc_det_fin  CONSTANT drug_presc_det.flg_status%TYPE := 'F';
    g_presc_det_intr CONSTANT drug_presc_det.flg_status%TYPE := 'I';
    g_presc_det_pend CONSTANT drug_presc_det.flg_status%TYPE := 'D';
    g_presc_det_req  CONSTANT drug_presc_det.flg_status%TYPE := 'R';
    g_presc_det_oset CONSTANT drug_presc_det.flg_status%TYPE := 'K';

    -- drug_presc_det.flg_take_type
    g_presc_take_sos  CONSTANT drug_presc_det.flg_take_type%TYPE := 'S';
    g_presc_take_cont CONSTANT drug_presc_det.flg_take_type%TYPE := 'C';
    g_presc_take_uni  CONSTANT drug_presc_det.flg_take_type%TYPE := 'U';

    -- drug_presc_plan.flg_status
    g_presc_plan_stat_can CONSTANT drug_presc_plan.flg_status%TYPE := 'C';
    g_presc_plan_stat_adm CONSTANT drug_presc_plan.flg_status%TYPE := 'A';
    g_presc_plan_stat_nd  CONSTANT drug_presc_plan.flg_status%TYPE := 'D';
    g_presc_plan_stat_nr  CONSTANT drug_presc_plan.flg_status%TYPE := 'R';
    g_presc_plan_stat_nn  CONSTANT drug_presc_plan.flg_status%TYPE := 'N';

    -- mi_med.flg_type
    g_mi_med_type_med CONSTANT mi_med.flg_type%TYPE := 'M';
    g_mi_med_type_nur CONSTANT mi_med.flg_type%TYPE := 'N';
    g_mi_med_type_fin CONSTANT mi_med.flg_type%TYPE := 'F';

    -- interv_presc_det.flg_status
    g_interv_det_exec CONSTANT interv_presc_det.flg_status%TYPE := 'E';
    g_interv_det_fin  CONSTANT interv_presc_det.flg_status%TYPE := 'F';
    g_interv_det_pend CONSTANT interv_presc_det.flg_status%TYPE := 'D';
    g_interv_det_req  CONSTANT interv_presc_det.flg_status%TYPE := 'R';
    --
    g_interv_det_cancel   CONSTANT interv_presc_det.flg_status%TYPE := 'C';
    g_interv_det_partial  CONSTANT interv_presc_det.flg_status%TYPE := 'P';
    g_interv_det_sos      CONSTANT interv_presc_det.flg_status%TYPE := 'S';
    g_interv_det_inter    CONSTANT interv_presc_det.flg_status%TYPE := 'I';
    g_interv_det_schedule CONSTANT interv_presc_det.flg_status%TYPE := 'A';
    g_interv_det_propose  CONSTANT interv_presc_det.flg_status%TYPE := 'V';
    g_interv_det_rejected CONSTANT interv_presc_det.flg_status%TYPE := 'G';
    g_interv_det_ext      CONSTANT interv_presc_det.flg_status%TYPE := 'X';

    -- interv_presc_plan.flg_status
    g_interv_plan_admt CONSTANT interv_presc_plan.flg_status%TYPE := 'A';
    g_interv_plan_pend CONSTANT interv_presc_plan.flg_status%TYPE := 'D';
    g_interv_plan_req  CONSTANT interv_presc_plan.flg_status%TYPE := 'R';

    -- interv_presc_det.flg_interv_type
    g_interv_type_sos CONSTANT interv_presc_det.flg_interv_type%TYPE := 'S';
    g_interv_type_con CONSTANT interv_presc_det.flg_interv_type%TYPE := 'C';

    -- interv_dep_clin_serv.flg_type
    g_interv_freq    CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'M';
    g_interv_can_req CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'P';
    g_interv_execute CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'R';

    -- Referral constant
    -- status
    g_p1_status_f CONSTANT p1_external_request.flg_status%TYPE := 'F'; -- Failed  (Faltou a consulta)
    g_p1_status_e CONSTANT p1_external_request.flg_status%TYPE := 'E'; -- Executed (Consulta efectivada)
    g_p1_status_m CONSTANT p1_external_request.flg_status%TYPE := 'M'; -- Mailed (Enviada notifica?o);
    g_p1_status_s CONSTANT p1_external_request.flg_status%TYPE := 'S'; -- Scheduled (Agendado);
    g_p1_status_a CONSTANT p1_external_request.flg_status%TYPE := 'A'; -- Accepted (Aceite, para agendar);

    -- Types of referrals
    g_p1_type_c CONSTANT p1_external_request.flg_type%TYPE := 'C'; -- Consultation

    -- doc_crit.flg_criteria
    g_doccrit_flg_crit_initial     CONSTANT doc_criteria.flg_criteria%TYPE := 'I'; -- Initial state
    g_doccrit_flg_crit_selected    CONSTANT doc_criteria.flg_criteria%TYPE := 'Y'; -- Selected state
    g_doccrit_flg_crit_no_selected CONSTANT doc_criteria.flg_criteria%TYPE := 'N'; -- NO Selected (2nd touch) state

    -- category.flg_type
    g_cat_type_doc             CONSTANT category.flg_type%TYPE := 'D';
    g_cat_type_nurse           CONSTANT category.flg_type%TYPE := 'N';
    g_cat_type_technician      CONSTANT category.flg_type%TYPE := 'T';
    g_cat_type_registrar       CONSTANT category.flg_type%TYPE := 'A';
    g_cat_type_triage          CONSTANT category.flg_type%TYPE := 'M';
    g_cat_type_pharmacist      CONSTANT category.flg_type%TYPE := 'P';
    g_cat_type_case_manager    CONSTANT category.flg_type%TYPE := 'Q';
    g_cat_type_social          CONSTANT category.flg_type%TYPE := 'S';
    g_cat_type_nutritionist    CONSTANT category.flg_type%TYPE := 'U';
    g_cat_type_coordinator     CONSTANT category.flg_type%TYPE := 'C';
    g_cat_type_physiotherapist CONSTANT category.flg_type%TYPE := 'F';
    g_cat_type_psychologist    CONSTANT category.flg_type%TYPE := 'G';
    g_cat_type_cdc             CONSTANT category.flg_type%TYPE := 'E';

    -- epis_diagnosis.flg_status
    g_epis_diag_flg_status_a CONSTANT VARCHAR2(1) := 'A'; -- Active
    g_epis_diag_flg_status_c CONSTANT VARCHAR2(1) := 'C'; -- Cancelled
    g_epis_diag_flg_status_d CONSTANT VARCHAR2(1) := 'D'; -- Screening
    g_epis_diag_flg_status_f CONSTANT VARCHAR2(1) := 'F'; -- Confirmed
    g_epis_diag_flg_status_r CONSTANT VARCHAR2(1) := 'R'; -- Declined
    g_epis_diag_flg_status_b CONSTANT VARCHAR2(1) := 'B'; -- Base
    g_epis_diag_flg_status_p CONSTANT VARCHAR2(1) := 'P'; -- Presumptive

    --epis_diagnosis.flg_type
    g_epis_diag_flg_type_d CONSTANT VARCHAR2(1) := 'D'; -- Final
    g_epis_diag_flg_type_p CONSTANT VARCHAR2(1) := 'P'; -- Diferential
    g_epis_diag_flg_type_b CONSTANT VARCHAR2(1) := 'B'; -- Base

    -- lens.flg_type
    g_lens_flg_type_g CONSTANT VARCHAR2(1) := 'G'; -- Glasses
    g_lens_flg_type_l CONSTANT VARCHAR2(1) := 'L'; -- Contact Lens

    -- lens_presc.flg_status
    g_lens_presc_flg_status_i CONSTANT VARCHAR2(1) := 'I'; -- In construction
    g_lens_presc_flg_status_p CONSTANT VARCHAR2(1) := 'P'; -- Printed
    g_lens_presc_flg_status_c CONSTANT VARCHAR2(1) := 'C'; -- Cancelled

    -- lens prescription information
    g_lens_presc_info_r CONSTANT VARCHAR2(1) := 'R'; -- Right eye
    g_lens_presc_info_l CONSTANT VARCHAR2(1) := 'L'; -- Left eye
    g_lens_presc_info_o CONSTANT VARCHAR2(1) := 'O'; -- Other information

    -- on-call physician
    g_on_call_active    CONSTANT VARCHAR2(1) := 'A'; -- Active
    g_on_call_cancelled CONSTANT VARCHAR2(1) := 'C'; -- Cancelled

    -- discharge cancel types
    g_disch_flgcanceltype_n CONSTANT VARCHAR2(1) := 'N'; -- Normal
    g_disch_flgcanceltype_r CONSTANT VARCHAR2(1) := 'R'; -- Refusal (patient refuses to be discharged/transfered)

    -- discharge notes - type of follow-up with
    g_followupwith_oc CONSTANT follow_up_entity.flg_type%TYPE := 'OC';
    g_followupwith_ph CONSTANT follow_up_entity.flg_type%TYPE := 'PH';
    g_followupwith_cl CONSTANT follow_up_entity.flg_type%TYPE := 'CL';
    g_followupwith_o  CONSTANT follow_up_entity.flg_type%TYPE := 'O';

    -- prof_team.flg_status
    g_team_active   CONSTANT prof_team.flg_status%TYPE := 'A';
    g_team_cancel   CONSTANT prof_team.flg_status%TYPE := 'C';
    g_team_inactive CONSTANT prof_team.flg_status%TYPE := 'I';

    -- prof_team_det.flg_status
    g_team_det_active CONSTANT prof_team_det.flg_status%TYPE := 'A';
    g_team_det_cancel CONSTANT prof_team_det.flg_status%TYPE := 'C';

    -- prof_team_hist.flg_type_register%TYPE
    g_flg_type_reg_c CONSTANT prof_team_hist.flg_type_register%TYPE := 'C';
    g_flg_type_reg_e CONSTANT prof_team_hist.flg_type_register%TYPE := 'E';

    -- prof_dep_clin_serv.flg_status
    g_status_selected CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';

    -- external_sys.id_external_sys
    g_external_sys_built_in CONSTANT external_sys.id_external_sys%TYPE := 8; -- Built-in

    -- On-call physician period status
    -- Shown in the "Status" column of the on-call physician search results
    g_oncallperiod_status_c CONSTANT VARCHAR2(1) := 'C';
    g_oncallperiod_status_f CONSTANT VARCHAR2(1) := 'F';
    g_oncallperiod_status_p CONSTANT VARCHAR2(1) := 'P';

    -- sys_domain_instit_soft.flg_action
    g_sdis_flag_add CONSTANT sys_domain_instit_soft_dcs.flg_action%TYPE := 'A';
    g_sdis_flag_rem CONSTANT sys_domain_instit_soft_dcs.flg_action%TYPE := 'R';

    -- sys_domain_mkt.flg_action
    g_sdm_flag_base CONSTANT sys_domain_mkt.flg_action%TYPE := 'B';
    g_sdm_flag_add  CONSTANT sys_domain_mkt.flg_action%TYPE := 'A';
    g_sdm_flag_rem  CONSTANT sys_domain_mkt.flg_action%TYPE := 'R';

    -- discharge_notes.flg_issue_assign
    g_disch_issue_assign_p CONSTANT discharge_notes.flg_issue_assign%TYPE := 'P';
    g_disch_issue_assign_g CONSTANT discharge_notes.flg_issue_assign%TYPE := 'G';

    -- epis_positioning.flg_status
    g_team_det_r CONSTANT epis_positioning.flg_status%TYPE := 'R'; -- Required
    g_team_det_i CONSTANT epis_positioning.flg_status%TYPE := 'I'; -- Interrupted
    g_team_det_c CONSTANT epis_positioning.flg_status%TYPE := 'C'; -- Canceled
    g_team_det_e CONSTANT epis_positioning.flg_status%TYPE := 'E'; -- In execution

    -- epis_hidrics.flg_status
    g_team_det_r CONSTANT epis_hidrics.flg_status%TYPE := 'R'; -- Required
    g_team_det_i CONSTANT epis_hidrics.flg_status%TYPE := 'I'; -- Interrupted
    g_team_det_c CONSTANT epis_hidrics.flg_status%TYPE := 'C'; -- Canceled
    g_team_det_e CONSTANT epis_hidrics.flg_status%TYPE := 'E'; -- In execution
    g_team_det_e CONSTANT epis_hidrics.flg_status%TYPE := 'F'; -- In execution

    -- episode.flg_status
    g_epis_status_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_status_inactive CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_status_temp     CONSTANT episode.flg_status%TYPE := 'T';
    g_epis_status_pendent  CONSTANT episode.flg_status%TYPE := 'P';
    g_epis_status_cancel   CONSTANT episode.flg_status%TYPE := 'C';

    -- episode.flg_type
    g_epis_type_def CONSTANT episode.flg_type%TYPE := 'D';
    g_epis_type_tmp CONSTANT episode.flg_type%TYPE := 'T';

    -- episode.flg_ehr
    g_epis_ehr_normal   CONSTANT episode.flg_type%TYPE := 'N';
    g_epis_ehr_schedule CONSTANT episode.flg_type%TYPE := 'S';
    g_epis_ehr_ehr      CONSTANT episode.flg_type%TYPE := 'E';

    -- epis_info.flg_unknown
    g_epis_info_unknown_def CONSTANT epis_info.flg_unknown%TYPE := 'N';
    g_epis_info_unknown_tmp CONSTANT epis_info.flg_unknown%TYPE := 'Y';

    -- epis_info.flg_status
    g_epis_physician_discharge CONSTANT epis_info.flg_status%TYPE := 'D';
    g_epis_adm_discharge       CONSTANT epis_info.flg_status%TYPE := 'M';
    g_epis_pat_waiting         CONSTANT epis_info.flg_status%TYPE := 'E';

    -- Shortcut's 
    g_shortcut_position_inten   CONSTANT sys_shortcut.intern_name%TYPE := 'POSITIONING_LIST';
    g_shortcut_hidrics_inten    CONSTANT sys_shortcut.intern_name%TYPE := 'HIDRICS_LIST';
    g_shortcut_exams_inten      CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_IMAGE';
    g_shortcut_analisys_inten   CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_HARVEST';
    g_shortcut_monit_inten      CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_MONITOR';
    g_shortcut_prescrip_inten   CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_DRUG_ADMIN';
    g_shortcut_procedur_inten   CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_PROC';
    g_shortcut_transp_inten     CONSTANT sys_shortcut.intern_name%TYPE := 'GRID_TRANSPORT';
    g_shortcut_surg_inten       CONSTANT sys_shortcut.intern_name%TYPE := 'SR_SURGERY';
    g_shortcut_surg_inten_adm   CONSTANT sys_shortcut.intern_name%TYPE := 'SR_SURGERY_ADM';
    g_shortcut_admiss_inten     CONSTANT sys_shortcut.intern_name%TYPE := 'ADMISSION_REQUEST';
    g_shortcut_admiss_inten_adm CONSTANT sys_shortcut.intern_name%TYPE := 'ADMISSION_REQUEST_ADM';
    g_shortcut_disch_inten      CONSTANT sys_shortcut.intern_name%TYPE := 'HISTORY';

    -- Task Timeline
    g_tl_oriented_visit   VARCHAR2(2) := 'V';
    g_tl_oriented_episode VARCHAR2(2) := 'E';
    g_tl_oriented_patient VARCHAR2(2) := 'P';
    --
    g_tl_table_name_posit         VARCHAR2(4000) := 'EPIS_POSITIONING_PLAN';
    g_tl_table_name_hidrics       VARCHAR2(4000) := 'EPIS_HIDRICS';
    g_tl_table_name_exams         VARCHAR2(4000) := 'EXAM_REQ_DET';
    g_tl_table_name_exams_res     VARCHAR2(4000) := 'EXAM_RESULT';
    g_tl_table_name_analysis      VARCHAR2(4000) := 'ANALYSIS_REQ_DET';
    g_tl_table_name_analysis_res  VARCHAR2(4000) := 'ANALYSIS_RESULT_PAR';
    g_tl_table_name_monitor       VARCHAR2(4000) := 'MONITORIZATION_VS';
    g_tl_table_name_procedur      VARCHAR2(4000) := 'INTERV_PRESC_DET';
    g_tl_table_name_transp        VARCHAR2(4000) := 'MOVEMENT';
    g_tl_table_name_surg          VARCHAR2(4000) := 'EPISODE';
    g_tl_table_name_sche_inp      VARCHAR2(4000) := 'EPISODE';
    g_tl_table_name_disch         VARCHAR2(4000) := 'DISCHARGE_SCHEDULE';
    g_tl_table_name_medication    VARCHAR2(4000) := 'DRUG_PRESC_DET';
    g_tl_table_name_complaint     VARCHAR2(4000) := 'EPIS_COMPLAINT';
    g_tl_table_name_anamnesis     VARCHAR2(4000) := 'EPIS_ANAMNESIS';
    g_tl_table_name_recomend      VARCHAR2(4000) := 'EPIS_RECOMEND';
    g_tl_table_name_diagnosis     VARCHAR2(4000) := 'EPIS_DIAGNOSIS';
    g_tl_table_name_diag_notes    VARCHAR2(4000) := 'EPIS_DIAGNOSIS_NOTES';
    g_tl_table_name_documentation VARCHAR2(4000) := 'EPIS_DOCUMENTATION';
    g_tl_table_name_consult       VARCHAR2(4000) := 'CONSULT_REQ';
    g_tl_table_name_referral      VARCHAR2(4000) := 'P1_EXTERNAL_REQUEST';

    g_wtl_dcs_flg_type_s CONSTANT VARCHAR2(1) := 'S'; -- S - Speciality
    g_wtl_dcs_flg_type_d CONSTANT VARCHAR2(1) := 'D'; -- D - External Discipline

    g_wtl_prof_flg_type_s CONSTANT VARCHAR2(1) := 'S'; -- S - Surgeon
    g_wtl_prof_flg_type_a CONSTANT VARCHAR2(1) := 'A'; -- A - Admitting physician

    -- task_timeline_ea.flg_type_viewer
    -- CONSTANTS used internally by viewer code to identify association to exams, analysis, procedures, prescriptions and comm orders
    g_flg_type_viewer_exams        CONSTANT task_timeline_ea.flg_type_viewer%TYPE := 'E';
    g_flg_type_viewer_proced       CONSTANT task_timeline_ea.flg_type_viewer%TYPE := 'P';
    g_flg_type_viewer_analysis_res CONSTANT task_timeline_ea.flg_type_viewer%TYPE := 'AR';
    g_flg_type_viewer_analysis     CONSTANT task_timeline_ea.flg_type_viewer%TYPE := 'AA';

    g_viewer_filter_comm_orders CONSTANT action.to_state%TYPE := 'COMM_ORDER';
    g_viewer_filter_rehab       CONSTANT action.to_state%TYPE := 'REHAB_TREATMENTS';

    -- consult_req.flg_type_date
    g_flg_type_date_f CONSTANT consult_req.flg_type_date%TYPE := 'F';

    -- adm_indication.flg_escape
    g_flg_escape_a CONSTANT adm_indication.flg_escape%TYPE := 'A';
    g_flg_escape_n CONSTANT adm_indication.flg_escape%TYPE := 'N';
    g_flg_escape_e CONSTANT adm_indication.flg_escape%TYPE := 'E';

    -- sr_pos_status.id_sr_pos_status
    g_sr_pos_status_approv    CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 1;
    g_sr_pos_status_tempappr  CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 2;
    g_sr_pos_status_tempnotap CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 3;
    g_sr_pos_status_notappr   CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 4;
    g_sr_pos_status_nodecis   CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 5;
    -- sr_pos_status.flg_status
    g_sr_pos_status_nd CONSTANT sr_pos_status.flg_status%TYPE := 'ND';
    g_sr_pos_status_a  CONSTANT sr_pos_status.flg_status%TYPE := 'A';
    g_sr_pos_status_ta CONSTANT sr_pos_status.flg_status%TYPE := 'TA';
    g_sr_pos_status_tn CONSTANT sr_pos_status.flg_status%TYPE := 'TN';
    g_sr_pos_status_na CONSTANT sr_pos_status.flg_status%TYPE := 'NA';
    g_sr_pos_status_no CONSTANT sr_pos_status.flg_status%TYPE := 'NO';
    g_sr_pos_status_c  CONSTANT sr_pos_status.flg_status%TYPE := 'C';
    g_sr_pos_status_ns CONSTANT sr_pos_status.flg_status%TYPE := 'NS';
    g_sr_pos_status_u  CONSTANT sr_pos_status.flg_status%TYPE := 'U';
    g_sr_pos_status_s  CONSTANT sr_pos_status.flg_status%TYPE := 'S';
    g_sr_pos_status_ex CONSTANT sr_pos_status.flg_status%TYPE := 'EX';

    -- adm_request.flg_status
    g_adm_req_status_pend    CONSTANT adm_request.flg_status%TYPE := 'P';
    g_adm_req_status_wait    CONSTANT adm_request.flg_status%TYPE := 'W';
    g_adm_req_status_inwa    CONSTANT adm_request.flg_status%TYPE := 'I';
    g_adm_req_status_sche    CONSTANT adm_request.flg_status%TYPE := 'S';
    g_adm_req_status_unde    CONSTANT adm_request.flg_status%TYPE := 'U';
    g_adm_req_status_done    CONSTANT adm_request.flg_status%TYPE := 'D';
    g_adm_req_status_canc    CONSTANT adm_request.flg_status%TYPE := 'C';
    g_adm_req_status_notneed CONSTANT adm_request.flg_status%TYPE := 'N';

    -- schedule_sr.flg_status
    g_schedule_sr_status_i CONSTANT schedule_sr.flg_status%TYPE := 'I';
    g_schedule_sr_status_a CONSTANT schedule_sr.flg_status%TYPE := 'A';
    g_schedule_sr_status_c CONSTANT schedule_sr.flg_status%TYPE := 'C';
    g_schedule_sr_status_p CONSTANT schedule_sr.flg_status%TYPE := 'P';
    g_schedule_sr_status_s CONSTANT schedule_sr.flg_status%TYPE := 'S';

    --schedule_sr.flg_sched
    g_schedule_sr_sched_a CONSTANT schedule_sr.flg_sched%TYPE := 'A';
    g_schedule_sr_sched_n CONSTANT schedule_sr.flg_sched%TYPE := 'N';

    --sr_surgery_record.flg_state
    g_surgery_record_status_t CONSTANT sr_surgery_record.flg_state%TYPE := 'T';
    g_surgery_record_status_a CONSTANT sr_surgery_record.flg_state%TYPE := 'A';
    g_surgery_record_status_v CONSTANT sr_surgery_record.flg_state%TYPE := 'V';
    g_surgery_record_status_p CONSTANT sr_surgery_record.flg_state%TYPE := 'P';
    g_surgery_record_status_s CONSTANT sr_surgery_record.flg_state%TYPE := 'S';
    g_surgery_record_status_o CONSTANT sr_surgery_record.flg_state%TYPE := 'O';
    g_surgery_record_status_r CONSTANT sr_surgery_record.flg_state%TYPE := 'R';
    g_surgery_record_status_f CONSTANT sr_surgery_record.flg_state%TYPE := 'F';
    g_surgery_record_status_c CONSTANT sr_surgery_record.flg_state%TYPE := 'C';
    -- waiting_list.flg_status
    g_wl_status_i CONSTANT waiting_list.flg_status%TYPE := 'I';
    g_wl_status_a CONSTANT waiting_list.flg_status%TYPE := 'A';
    g_wl_status_c CONSTANT waiting_list.flg_status%TYPE := 'C';
    g_wl_status_p CONSTANT waiting_list.flg_status%TYPE := 'P';
    g_wl_status_s CONSTANT waiting_list.flg_status%TYPE := 'S';

    ---- waiting_list.flg_type
    g_wl_type_b CONSTANT waiting_list.flg_type%TYPE := 'B';
    g_wl_type_s CONSTANT waiting_list.flg_type%TYPE := 'S';
    g_wl_type_a CONSTANT waiting_list.flg_type%TYPE := 'A';

    -- analysis_instit_soft.flg_collection_author
    g_flg_collection_author_l analysis_instit_soft.flg_collection_author%TYPE := 'L';
    g_flg_collection_author_d analysis_instit_soft.flg_collection_author%TYPE := 'D';

    -- SYS_CONFIG when looking for the type of coding being used
    g_sys_config_surg_coding CONSTANT sys_config.id_sys_config%TYPE := 'SURGICAL_PROCEDURES_CODING';

    --
    g_sql_varchar2_maxsize   CONSTANT NUMBER := 4000; -- Maximum length for SQL VARCHAR2 type
    g_plsql_varchar2_maxsize CONSTANT NUMBER := 32767; -- Maximum length for PL/SQL VARCHAR2 type

    -- Vital Sign Type
    g_vs_flg_vs  CONSTANT vital_sign.flg_vs%TYPE := 'VS'; -- Vital Sign
    g_vs_flg_bio CONSTANT vital_sign.flg_vs%TYPE := 'PE'; -- Biometry

    -- Vital Signs Fill Type
    g_vs_ft_bar_keypad  CONSTANT vital_sign.flg_fill_type%TYPE := 'B'; -- Keypad with a Bar
    g_vs_ft_keypad      CONSTANT vital_sign.flg_fill_type%TYPE := 'N'; -- Keypad
    g_vs_ft_scale       CONSTANT vital_sign.flg_fill_type%TYPE := 'P'; -- Scale
    g_vs_ft_multichoice CONSTANT vital_sign.flg_fill_type%TYPE := 'V'; -- Multi Choice

    -- Vital Signs Views
    g_vs_view_s  CONSTANT vs_soft_inst.flg_view%TYPE := 'S'; -- Summary
    g_vs_view_h  CONSTANT vs_soft_inst.flg_view%TYPE := 'H'; -- End of shift
    g_vs_view_v1 CONSTANT vs_soft_inst.flg_view%TYPE := 'V1'; -- Reduced Grid
    g_vs_view_v2 CONSTANT vs_soft_inst.flg_view%TYPE := 'V2'; -- Complete Grid
    g_vs_view_v3 CONSTANT vs_soft_inst.flg_view%TYPE := 'V3'; -- Biometrics Grid
    g_vs_view_t  CONSTANT vs_soft_inst.flg_view%TYPE := 'T'; -- Triage
    g_vs_view_p  CONSTANT vs_soft_inst.flg_view%TYPE := 'P'; -- Pregnancy
    g_vs_view_ps CONSTANT vs_soft_inst.flg_view%TYPE := 'PS'; -- Partogram
    g_vs_view_pt CONSTANT vs_soft_inst.flg_view%TYPE := 'PT'; -- Partogram (graphic)
    g_vs_view_pg CONSTANT vs_soft_inst.flg_view%TYPE := 'PG'; -- Pregnancy (summary)
    g_vs_view_aa CONSTANT vs_soft_inst.flg_view%TYPE := 'AA'; -- Announced Arrival

    -- Vital Signs Relation Domain
    g_vs_rel_man        CONSTANT vital_sign_relation.relation_domain%TYPE := 'M'; -- Manchester
    g_vs_rel_conc       CONSTANT vital_sign_relation.relation_domain%TYPE := 'C'; -- Concatenation (Blood Pressure)
    g_vs_rel_sum        CONSTANT vital_sign_relation.relation_domain%TYPE := 'S'; -- Sum (Glasgow)
    g_vs_rel_div        CONSTANT vital_sign_relation.relation_domain%TYPE := 'D'; -- Division
    g_vs_rel_gr         CONSTANT vital_sign_relation.relation_domain%TYPE := 'G'; -- Partogram graphic
    g_vs_rel_group      CONSTANT vital_sign_relation.relation_domain%TYPE := 'T'; -- Group of vital signs
    g_vs_rel_percentile CONSTANT vital_sign_relation.relation_domain%TYPE := 'P'; -- Percentile relation between VS

    -- Waiting Room
    g_wr_wq_type_a CONSTANT wl_queue.flg_type_queue%TYPE := 'A'; -- Registar Queue
    g_wr_wq_type_d CONSTANT wl_queue.flg_type_queue%TYPE := 'D'; -- Doctor Queue
    g_wr_wq_type_n CONSTANT wl_queue.flg_type_queue%TYPE := 'N'; -- Nurse Intake Queue
    g_wr_wq_type_c CONSTANT wl_queue.flg_type_queue%TYPE := 'C'; -- Nursing consult Queue

    g_wr_wl_status_x CONSTANT wl_waiting_line.flg_wl_status%TYPE := 'X'; --Called
    g_wr_wl_status_e CONSTANT wl_waiting_line.flg_wl_status%TYPE := 'E'; --Waiting
    g_wr_wl_status_n CONSTANT wl_waiting_line.flg_wl_status%TYPE := 'N'; --In nurse intake
    g_wr_wl_status_a CONSTANT wl_waiting_line.flg_wl_status%TYPE := 'A'; --Admitted
    g_wr_wl_status_h CONSTANT wl_waiting_line.flg_wl_status%TYPE := 'H'; --Discharged 

    g_wr_col_blue     CONSTANT wl_queue.color%TYPE := '0083D7'; --BLUE
    g_wr_col_drk_blue CONSTANT wl_queue.color%TYPE := '004D91'; --DARK BLUE
    g_wr_col_lgh_blue CONSTANT wl_queue.color%TYPE := '77C7C7'; --LIGHT BLUE
    g_wr_col_drk_yell CONSTANT wl_queue.color%TYPE := 'FFA700'; --DARK YELLOW
    g_wr_col_gren     CONSTANT wl_queue.color%TYPE := '6EAB24'; --GREEN
    g_wr_col_lgh_gren CONSTANT wl_queue.color%TYPE := 'E1D803'; --LIGHT GREEN
    g_wr_col_lgh_vlt  CONSTANT wl_queue.color%TYPE := '98699E'; --LIGHT VIOLET
    g_wr_col_orange   CONSTANT wl_queue.color%TYPE := 'FC7216'; --LIGHT VIOLET
    g_wr_col_red      CONSTANT wl_queue.color%TYPE := 'E20A16'; --RED
    g_wr_col_violet   CONSTANT wl_queue.color%TYPE := '671464'; --VIOLET

    -- sr_epis_interv.flg_status
    g_interv_status_requisition CONSTANT sr_epis_interv.flg_status%TYPE := 'R';
    g_interv_status_finished    CONSTANT sr_epis_interv.flg_status%TYPE := 'F';
    g_interv_status_execution   CONSTANT sr_epis_interv.flg_status%TYPE := 'E';
    g_interv_status_cancel      CONSTANT sr_epis_interv.flg_status%TYPE := 'C';

    --sr_epis_interv.flg_code_type: Indicates the kind of surgical procedure 
    g_interv_code_type_coded   CONSTANT sr_epis_interv.flg_code_type%TYPE := 'C'; -- Coded
    g_interv_code_type_uncoded CONSTANT sr_epis_interv.flg_code_type%TYPE := 'U'; -- Uncoded

    --sr_epis_interv.flg_type
    g_interv_type_principal CONSTANT sr_epis_interv.flg_type%TYPE := 'P';
    g_interv_type_secondary CONSTANT sr_epis_interv.flg_type%TYPE := 'S';

    -- internal name for POS functionality
    g_pos_intern_name_func CONSTANT sys_functionality.intern_name_func%TYPE := 'POS';

    g_grp_flg_rel_instcnt CONSTANT VARCHAR2(8) := 'INST_CNT';

    -- Task type IDs
    g_task_lab_tests             CONSTANT task_type.id_task_type%TYPE := 11;
    g_task_imaging_exams         CONSTANT task_type.id_task_type%TYPE := 7;
    g_task_other_exams           CONSTANT task_type.id_task_type%TYPE := 8;
    g_task_monitoring            CONSTANT task_type.id_task_type%TYPE := 9;
    g_task_proc_interv           CONSTANT task_type.id_task_type%TYPE := 43;
    g_task_procedure             CONSTANT task_type.id_task_type%TYPE := 43;
    g_task_rehab                 CONSTANT task_type.id_task_type%TYPE := 50;
    g_task_sr_procedures         CONSTANT task_type.id_task_type%TYPE := 27;
    g_task_inp_hidrics           CONSTANT task_type.id_task_type%TYPE := 47;
    g_task_inp_positioning       CONSTANT task_type.id_task_type%TYPE := 48;
    g_task_med_parent            CONSTANT task_type.id_task_type%TYPE := 12;
    g_task_med_local             CONSTANT task_type.id_task_type%TYPE := 13;
    g_task_med_local_op          CONSTANT task_type.id_task_type%TYPE := 49;
    g_task_discharge_instruction CONSTANT task_type.id_task_type%TYPE := 5;
    -- Diagnosis Task Types
    g_task_diagnosis             CONSTANT task_type.id_task_type%TYPE := 63;
    g_task_problems              CONSTANT task_type.id_task_type%TYPE := 60;
    g_task_surgical_history      CONSTANT task_type.id_task_type%TYPE := 61;
    g_task_medical_history       CONSTANT task_type.id_task_type%TYPE := 62;
    g_task_congenital_anomalies  CONSTANT task_type.id_task_type%TYPE := 64;
    g_task_cds                   CONSTANT task_type.id_task_type%TYPE := 84;
    g_task_patient_edu           CONSTANT task_type.id_task_type%TYPE := 42;
    g_task_medication            CONSTANT task_type.id_task_type%TYPE := 51;
    g_task_comm_orders           CONSTANT task_type.id_task_type%TYPE := 83;
    g_task_medical_orders        CONSTANT task_type.id_task_type%TYPE := 147;
    g_task_age                   CONSTANT task_type.id_task_type%TYPE := 85;
    g_task_gender                CONSTANT task_type.id_task_type%TYPE := 86;
    g_task_diag_result_exams     CONSTANT task_type.id_task_type%TYPE := 93;
    g_task_diag_result_oth_exams CONSTANT task_type.id_task_type%TYPE := 94;
    g_task_discharge_los         CONSTANT task_type.id_task_type%TYPE := 99; -- DISCHARGE LEVEL OF SERVICE - 
    g_task_discharge_admission   CONSTANT task_type.id_task_type%TYPE := 130;
    g_task_discharge_home        CONSTANT task_type.id_task_type%TYPE := 134; -- alta para o domicilio 
    g_task_discharge_transfer    CONSTANT task_type.id_task_type%TYPE := 137; -- transfer institution
    g_task_discharge_mse         CONSTANT task_type.id_task_type%TYPE := 140; -- MSE
    g_task_discharge_ama         CONSTANT task_type.id_task_type%TYPE := 135; -- AMA
    g_task_discharge_lwbs        CONSTANT task_type.id_task_type%TYPE := 136; -- LWBS
    g_task_discharge_expired     CONSTANT task_type.id_task_type%TYPE := 138; -- Died
    g_task_discharge_follow      CONSTANT task_type.id_task_type%TYPE := 139; -- Follow
    g_task_gynecology_history    CONSTANT task_type.id_task_type%TYPE := 150; -- Gynecology history
    g_task_family_history        CONSTANT task_type.id_task_type%TYPE := 151; -- family history

    -- CPOE task type IDs
    g_task_type_diet               CONSTANT cpoe_task_type.id_task_type%TYPE := 1; -- diet (group)   
    g_task_type_local_drug         CONSTANT cpoe_task_type.id_task_type%TYPE := 10; -- local drug (group)
    g_task_type_local_drug_w_tp    CONSTANT cpoe_task_type.id_task_type%TYPE := 11; -- local drug with therapeutic protocol    
    g_task_type_local_drug_wo_tp   CONSTANT cpoe_task_type.id_task_type%TYPE := 12; -- local drug without therapeutic protocol
    g_task_type_ext_drug           CONSTANT cpoe_task_type.id_task_type%TYPE := 16; -- outside medication
    g_task_type_iv_solution        CONSTANT cpoe_task_type.id_task_type%TYPE := 18; -- iv solutions
    g_task_type_hidric             CONSTANT cpoe_task_type.id_task_type%TYPE := 22; -- hidrics (group)
    g_task_type_hidric_in_out      CONSTANT cpoe_task_type.id_task_type%TYPE := 23; -- hidrics (intake and output)
    g_task_type_hidric_out         CONSTANT cpoe_task_type.id_task_type%TYPE := 24; -- hidrics (output)
    g_task_type_hidric_drain       CONSTANT cpoe_task_type.id_task_type%TYPE := 25; -- hidrics (drainage)
    g_task_type_positioning        CONSTANT cpoe_task_type.id_task_type%TYPE := 26; -- inpatient positioning    
    g_task_type_nursing            CONSTANT cpoe_task_type.id_task_type%TYPE := 27; -- nursing activities
    g_task_type_procedure          CONSTANT cpoe_task_type.id_task_type%TYPE := 31; -- procedure
    g_task_type_analysis           CONSTANT cpoe_task_type.id_task_type%TYPE := 33; -- analysis
    g_task_type_image_exam         CONSTANT cpoe_task_type.id_task_type%TYPE := 34; -- image exam
    g_task_type_other_exam         CONSTANT cpoe_task_type.id_task_type%TYPE := 35; -- other exam
    g_task_type_diet_inst          CONSTANT cpoe_task_type.id_task_type%TYPE := 36; -- institutionalized diet 
    g_task_type_diet_spec          CONSTANT cpoe_task_type.id_task_type%TYPE := 37; -- specific diet
    g_task_type_diet_predefined    CONSTANT cpoe_task_type.id_task_type%TYPE := 38; -- predefined diet
    g_task_type_monitorization     CONSTANT cpoe_task_type.id_task_type%TYPE := 40; -- monitorization
    g_task_type_hidric_in          CONSTANT cpoe_task_type.id_task_type%TYPE := 41; -- hidrics (intake)
    g_task_type_hidric_out_group   CONSTANT cpoe_task_type.id_task_type%TYPE := 42; -- hidrics (output group)
    g_task_type_hidric_out_all     CONSTANT cpoe_task_type.id_task_type%TYPE := 43; -- hidrics (output all) 
    g_task_type_medication         CONSTANT cpoe_task_type.id_task_type%TYPE := 44; -- new medication   
    g_task_type_hidric_irrigations CONSTANT cpoe_task_type.id_task_type%TYPE := 45; -- hidrics (irrigations) 
    g_task_type_com_order          CONSTANT cpoe_task_type.id_task_type%TYPE := 46; -- communication order
    g_task_type_med_order          CONSTANT cpoe_task_type.id_task_type%TYPE := 51; -- communication order

    -- Order_Set Task Priorities    
    g_task_priority_normal      CONSTANT VARCHAR2(1) := 'N';
    g_task_priority_urgent      CONSTANT VARCHAR2(1) := 'U';
    g_task_priority_very_urgent CONSTANT VARCHAR2(1) := 'M';

    -- Modal Window Templates
    g_modal_win_warning_read      CONSTANT VARCHAR2(30) := 'WARNING_READ'; -- Warning Read
    g_modal_win_warning_confirm   CONSTANT VARCHAR2(30) := 'WARNING_CONFIRMATION'; -- Warning Confirmation
    g_modal_win_warning_cancel    CONSTANT VARCHAR2(30) := 'WARNING_CANCEL'; -- Warning Cancel
    g_modal_win_warning_help_save CONSTANT VARCHAR2(30) := 'WARNING_HELP_SAVE'; -- Warning Help Save
    g_modal_win_warning_security  CONSTANT VARCHAR2(30) := 'WARNING_SECURITY'; -- Warning Security
    g_modal_win_confirm           CONSTANT VARCHAR2(30) := 'CONFIRMATION'; -- Confirmation
    g_modal_win_detail            CONSTANT VARCHAR2(30) := 'DETAIL'; -- Detail
    g_modal_win_help              CONSTANT VARCHAR2(30) := 'HELP'; -- Help
    g_modal_win_wizard            CONSTANT VARCHAR2(30) := 'WIZARD'; -- Wizard
    g_modal_win_advanced_input    CONSTANT VARCHAR2(30) := 'ADVANCED_INPUT'; -- Advanced Input

    -- Default language configuration 
    g_sys_config_def_language CONSTANT sys_config.id_sys_config%TYPE := 'LANGUAGE';

    -- EDIS grids
    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';
    g_desc_header      CONSTANT VARCHAR2(1) := 'H';
    g_desc_grid        CONSTANT VARCHAR2(1) := 'G';
    g_ft_color         CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white  CONSTANT VARCHAR2(200) := '0x787864';
    g_ft_status        CONSTANT VARCHAR2(1) := 'A';

    -- markets
    g_id_market_all CONSTANT market.id_market%TYPE := 0;
    g_id_market_pt  CONSTANT market.id_market%TYPE := 1;
    g_id_market_usa CONSTANT market.id_market%TYPE := 2;
    g_id_market_br  CONSTANT market.id_market%TYPE := 3;
    g_id_market_it  CONSTANT market.id_market%TYPE := 4;
    g_id_market_nl  CONSTANT market.id_market%TYPE := 5;
    g_id_market_es  CONSTANT market.id_market%TYPE := 6;
    g_id_market_my  CONSTANT market.id_market%TYPE := 7;
    g_id_market_gb  CONSTANT market.id_market%TYPE := 8;
    g_id_market_fr  CONSTANT market.id_market%TYPE := 9;
    g_id_market_be  CONSTANT market.id_market%TYPE := 10;
    g_id_market_cl  CONSTANT market.id_market%TYPE := 12;
    g_id_market_gq  CONSTANT market.id_market%TYPE := 13;
    g_id_market_sg  CONSTANT market.id_market%TYPE := 14;
    g_id_market_ib  CONSTANT market.id_market%TYPE := 15;
    g_id_market_mx  CONSTANT market.id_market%TYPE := 16;
    g_id_market_ch  CONSTANT market.id_market%TYPE := 17;
    g_id_market_kw  CONSTANT market.id_market%TYPE := 18;
    g_id_market_tw  CONSTANT market.id_market%TYPE := 20;
    g_id_market_sa  CONSTANT market.id_market%TYPE := 11;

    -- Social episodes: A - appointments, R - requests
    g_social_episode_type_a CONSTANT VARCHAR(1 CHAR) := 'A';
    g_social_episode_type_r CONSTANT VARCHAR(1 CHAR) := 'R';
    --
    --Intervention plan parametrization types
    g_interv_plan_type_p CONSTANT VARCHAR(1 CHAR) := 'P';
    g_interv_plan_type_m CONSTANT VARCHAR(1 CHAR) := 'M';
    ---

    -- TDE relationship types
    g_tde_rel_start2start  CONSTANT tde_relationship_type.id_relationship_type%TYPE := 1;
    g_tde_rel_finish2start CONSTANT tde_relationship_type.id_relationship_type%TYPE := 2;

    -- Dependency icon
    g_dependency_icon CONSTANT VARCHAR2(30) := 'ExtendIcon';

    -- Dependency support options (TASK_TYPE.FLG_DEPENDENCY_SUPPORT)
    g_tt_tde_rel_all          CONSTANT task_type.flg_dependency_support%TYPE := 'A';
    g_tt_tde_rel_none         CONSTANT task_type.flg_dependency_support%TYPE := 'N';
    g_tt_tde_rel_start2start  CONSTANT task_type.flg_dependency_support%TYPE := 'S';
    g_tt_tde_rel_finish2start CONSTANT task_type.flg_dependency_support%TYPE := 'F';

    -- TDE task states
    g_tde_task_state_requested    CONSTANT tde_task_dependency.flg_task_state%TYPE := 'R';
    g_tde_task_state_start_depend CONSTANT tde_task_dependency.flg_task_state%TYPE := 'D';
    g_tde_task_state_started_tde  CONSTANT tde_task_dependency.flg_task_state%TYPE := 'T';
    g_tde_task_state_started_user CONSTANT tde_task_dependency.flg_task_state%TYPE := 'U';
    g_tde_task_state_finished     CONSTANT tde_task_dependency.flg_task_state%TYPE := 'F';
    g_tde_task_state_canceled     CONSTANT tde_task_dependency.flg_task_state%TYPE := 'C';
    g_tde_task_state_suspended    CONSTANT tde_task_dependency.flg_task_state%TYPE := 'S';
    g_tde_task_state_future_sched CONSTANT tde_task_dependency.flg_task_state%TYPE := 'H';

    -- Dependencies from episodes (TASK_TYPE.ID_TASK_TYPE)
    g_task_current_epis CONSTANT task_type.id_task_type%TYPE := -1;
    g_task_future_epis  CONSTANT task_type.id_task_type%TYPE := -2;

    -- Task type episode support flag domain (TASK_TYPE.FLG_EPISODE_TASK)
    g_tt_tde_support_task      CONSTANT task_type.flg_episode_task%TYPE := 'T';
    g_tt_tde_support_epis      CONSTANT task_type.flg_episode_task%TYPE := 'E';
    g_tt_tde_support_task_epis CONSTANT task_type.flg_episode_task%TYPE := 'B';

    -- Task origin
    g_task_origin_care_plan  CONSTANT VARCHAR2(1) := 'C';
    g_task_origin_order_set  CONSTANT VARCHAR2(1) := 'O';
    g_task_origin_cpoe       CONSTANT VARCHAR2(1) := 'P';
    g_task_origin_scheduler  CONSTANT VARCHAR2(1) := 'S';
    g_task_origin_referral   CONSTANT VARCHAR2(1) := 'R';
    g_task_origin_medication CONSTANT VARCHAR2(1) := 'M';

    --Medication
    g_popup_local CONSTANT VARCHAR2(1) := 'L'; -- Administer Here Popup

    -- Constants for the type of scope of information (by episode; by visit; by patient)
    g_scope_type_patient CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_scope_type_visit   CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_scope_type_episode CONSTANT VARCHAR2(1 CHAR) := 'E';

    --Constants for procedures and patient education
    g_task_procedures        CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_task_patient_education CONSTANT VARCHAR2(1 CHAR) := 'T';

    -- Discharge status
    g_disch_pend_episode CONSTANT discharge_status.id_discharge_status%TYPE := 8;

    -- Chronological order of records returned
    g_order_ascending  CONSTANT VARCHAR2(3 CHAR) := 'ASC';
    g_order_descending CONSTANT VARCHAR2(4 CHAR) := 'DESC';

    -- order recurrence options
    g_order_recurr_option_once     CONSTANT order_recurr_option.id_order_recurr_option%TYPE := 0;
    g_order_recurr_option_other    CONSTANT order_recurr_option.id_order_recurr_option%TYPE := -1;
    g_order_recurr_option_no_sched CONSTANT order_recurr_option.id_order_recurr_option%TYPE := -2;

    -- Constants used for Diagnoses areas
    g_diag_area_config_show_own   CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_diag_area_config_show_all   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_diag_area_past_history      CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_diag_area_problems          CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_diag_area_not_defined       CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_diag_area_surgical_hist     CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_diag_area_family_hist       CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_diag_area_sys_config        CONSTANT VARCHAR2(30 CHAR) := 'HISTORY_PROBLEMS_SHOW_DIAGS';
    g_problems_show_surgical_hist CONSTANT VARCHAR2(30 CHAR) := 'PROBLEMS_SHOW_SURGICAL_HISTORY';
    g_problems_default_area       CONSTANT VARCHAR2(30 CHAR) := 'PROBLEMS_DEFAULT_AREA';
    --
    g_birth_hist_search_mechanism CONSTANT VARCHAR2(40 CHAR) := 'BIRTH_HISTORY_SEARCH_MECHANISM';
    g_surg_hist_search_mechanism  CONSTANT VARCHAR2(40 CHAR) := 'SURGICAL_HISTORY_SEARCH_MECHANISM';
    g_med_hist_search_mechanism   CONSTANT VARCHAR2(40 CHAR) := 'MEDICAL_HISTORY_SEARCH_MECHANISM';
    g_problems_search_mechanism   CONSTANT VARCHAR2(40 CHAR) := 'PROBLEMS_SEARCH_MECHANISM';
    g_diagnoses_search_mechanism  CONSTANT VARCHAR2(40 CHAR) := 'DIAGNOSES_SEARCH_MECHANISM';
    g_diag_new_search_mechanism   CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_diag_old_search_mechanism   CONSTANT VARCHAR2(1 CHAR) := 'O';

    --Viewer filters
    g_last_x_records    CONSTANT VARCHAR2(1 CHAR) := 'L';
    g_my_last_x_recods  CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_past_x            CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_past_x_from_visit CONSTANT VARCHAR2(1 CHAR) := 'V';

    --Time period 
    g_time_interval_hour  CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_time_interval_day   CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_time_interval_week  CONSTANT VARCHAR2(1 CHAR) := 'W';
    g_time_interval_month CONSTANT VARCHAR2(1 CHAR) := 'M';

    -- NECESSITY_DEPT_INST_SOFT - FLG_AREA TYPES
    g_nece_dept_inst_soft_movement CONSTANT VARCHAR2(30 CHAR) := 'MOVEMENT';
    g_nece_dept_inst_soft_config   CONSTANT VARCHAR2(30 CHAR) := 'NECESSITY_INST_SOFT';

    -- LINKS FLG TYPES    
    g_link_flg_l CONSTANT links.flg_type%TYPE := 'L'; -- Link
    g_link_flg_f CONSTANT links.flg_type%TYPE := 'F'; -- Folder
    g_link_flg_i CONSTANT links.flg_type%TYPE := 'I'; -- infobutton

    g_flg_doctor     CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_flg_student    CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_flg_nurse      CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_pharmacist CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_flg_aux        CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_flg_admin      CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_tech       CONSTANT VARCHAR2(1 CHAR) := 'T';
    -- FOR DIAGNOSIS 
    g_diag_search_mode_x CONSTANT VARCHAR2(1 CHAR) := 'X';

    -- MEDICATION ACTIONS
    g_action_presc_for_local CONSTANT action.id_action%TYPE := 700011;

    g_alert_cpoe_draft sys_alert.id_sys_alert%TYPE := 320;
    g_alert_hhc_team   sys_alert.id_sys_alert%TYPE := 330;

    -- Diagnosis flg_show_code
    g_diag_flg_show_t CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_diag_flg_show_f CONSTANT VARCHAR2(1 CHAR) := 'F';

    g_flg_profile_specialist CONSTANT sys_domain.val%TYPE := 'S';
    g_flg_profile_resident   CONSTANT sys_domain.val%TYPE := 'R';
    g_flg_profile_intern     CONSTANT sys_domain.val%TYPE := 'I';
    g_flg_profile_nurse      CONSTANT sys_domain.val%TYPE := 'N';
    g_flg_profile_student    CONSTANT sys_domain.val%TYPE := 'T';
    g_flg_profile_religious  CONSTANT sys_domain.val%TYPE := 'I';

    --default entity description type
    g_entity_description_type_def CONSTANT NUMBER := 1;

    --Out on pass
    g_wf_epis_out_on_pass          CONSTANT wf_status_workflow.id_workflow%TYPE := 70;
    g_status_out_on_pass_active    CONSTANT wf_status_workflow.id_status%TYPE := 1800;
    g_status_out_on_pass_ongoing   CONSTANT wf_status_workflow.id_status%TYPE := 1801;
    g_status_out_on_pass_completed CONSTANT wf_status_workflow.id_status%TYPE := 1802;
    g_status_out_on_pass_cancelled CONSTANT wf_status_workflow.id_status%TYPE := 1803;
    g_cat_id_administrative_clerk  CONSTANT category.id_category%TYPE := 4;
    g_subject_out_on_pass          CONSTANT action.subject%TYPE := 'OUT_ON_PASS';
    g_out_on_pass_cancel_reason    CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_CANCEL_REASON.';
    g_out_on_pass_cancel_reason_ar CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_CANCEL_REASON';
    g_out_on_pass_request_reason   CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_REQUEST_REASON.';
    g_out_on_pass_reqst_reason_ar  CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_REQUEST_REASO';
    g_out_on_pass_other_notes      CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_OTHER_NOTES.';
    g_out_on_pass_other_notes_ar   CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_OTHER_NOTES';
    g_out_on_pass_note_admis_offic CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_NOTE_ADMISSION_OFFICE.';
    g_out_on_pass_note_adm_offi_ar CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_NOTE_ADM_OFF';
    g_out_on_pass_conclude_reason  CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_CONCLUDE_REASON.';
    g_out_on_pass_conclu_reason_ar CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_CONCLU_REASON';
    g_out_on_pass_conclude_notes   CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_CONCLUDE_NOTES.';
    g_out_on_pass_conclu_notes_ar  CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_CONCLU_NOTES';
    g_out_on_pass_start_notes      CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_START_NOTES.';
    g_out_on_pass_start_notes_ar   CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_START_NOTES';
    g_out_on_pass_requested_by     CONSTANT VARCHAR2(55 CHAR) := 'EPIS_OUT_ON_PASS.CODE_REQUESTED_BY.';
    g_out_on_pass_requested_by_ar  CONSTANT VARCHAR2(30 CHAR) := 'EPIS_OUT_ON_PASS_REQUESTED_BY';
    g_out_on_pass_req_by_patient   CONSTANT NUMBER := 3071;
    g_out_on_pass_req_by_leg_gard  CONSTANT NUMBER := 3072;
    g_out_on_pass_req_by_next_kin  CONSTANT NUMBER := 3073;
    --origin to create healt program
    g_pregnancy CONSTANT VARCHAR2(1 CHAR) := 'P';
    --
    g_type_appointment CONSTANT VARCHAR2(1 CHAR) := 'A';

    g_flg_status_report_a CONSTANT VARCHAR2(0010 CHAR) := 'A';
    g_flg_status_report_h CONSTANT VARCHAR2(0010 CHAR) := 'H';

    g_two_points CONSTANT VARCHAR2(0010 CHAR) := ': ';
    g_semicolon  CONSTANT VARCHAR2(0010 CHAR) := '; ';

    g_flg_screen_l0  CONSTANT VARCHAR2(0010 CHAR) := 'L0';
    g_flg_screen_l1  CONSTANT VARCHAR2(0010 CHAR) := 'L1';
    g_flg_screen_l2  CONSTANT VARCHAR2(0010 CHAR) := 'L2';
    g_flg_screen_l3  CONSTANT VARCHAR2(0010 CHAR) := 'L3';
    g_flg_screen_l2n CONSTANT VARCHAR2(0010 CHAR) := 'L2N';
    g_flg_screen_lp  CONSTANT VARCHAR2(0010 CHAR) := 'LP';
    g_flg_screen_wl  CONSTANT VARCHAR2(0010 CHAR) := 'WL';
    g_flg_screen_l2b CONSTANT VARCHAR2(0010 CHAR) := 'L2B';
    --intensity hhc doc area
    g_doc_area_intensity_hhc CONSTANT doc_area.id_doc_area%TYPE := 36064;

    g_flg_action_d CONSTANT VARCHAR2(1 CHAR) := 'D'; --detail
    g_flg_action_h CONSTANT VARCHAR2(1 CHAR) := 'H'; --history
    g_flg_action_e CONSTANT VARCHAR2(1 CHAR) := 'E'; --edit
    g_flg_action_t CONSTANT VARCHAR2(1 CHAR) := 'T'; --title

    g_hhc_epis_type_shadow CONSTANT NUMBER := 99; -- epis type hhc shadow episodes
    g_hhc_epis_type        CONSTANT NUMBER := 50; -- epis type hhc episodes 

    g_flg_add CONSTANT VARCHAR2(1 CHAR) := 'A'; --ADD
    g_flg_rem CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Remove

END pk_alert_constant;
/
