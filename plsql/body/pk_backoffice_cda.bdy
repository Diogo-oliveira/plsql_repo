/*-- Last Change Revision: $Rev: 1828492 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-03-05 14:34:13 +0000 (seg, 05 mar 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_backoffice_cda IS
    k_active   CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_active;
    k_inactive CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_inactive;

    k_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_available;
    k_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;

    k_code_domain_type     CONSTANT sys_domain.code_domain%TYPE := 'CDA_REQ.FLG_TYPE';
    k_code_domain_status   CONSTANT sys_domain.code_domain%TYPE := 'CDA_REQ.FLG_STATUS';
    k_code_domain_det_type CONSTANT sys_domain.code_domain%TYPE := 'CDA_REQ_DET.FLG_TYPE';

    k_cda_report_id   CONSTANT reports.id_reports%TYPE := 691;
    k_qrda1_report_id CONSTANT reports.id_reports%TYPE := 693;
    k_qrda3_report_id CONSTANT reports.id_reports%TYPE := 694;

    g_alert_rep_gen CONSTANT sys_alert.id_sys_alert%TYPE := 312;

    k_cda_flg_type  CONSTANT cda_req.flg_type%TYPE := 'P';
    k_qrda_flg_type CONSTANT cda_req.flg_type%TYPE := 'M';

    k_finish_status CONSTANT cda_req.flg_status%TYPE := 'F';
    k_cancel_status CONSTANT cda_req.flg_status%TYPE := 'C';
    k_ready_status  CONSTANT cda_req.flg_status%TYPE := 'R';

    g_debug     BOOLEAN;
    g_error_out t_error_out;

    TYPE tbl_cda_req IS TABLE OF cda_req%ROWTYPE;
    TYPE tbl_cda_req_det IS TABLE OF cda_req_det%ROWTYPE;
    -- private methods
    FUNCTION get_cda_date_ready(i_cda_req IN cda_req_det.id_cda_req%TYPE) RETURN cda_req_det.dt_status_end%TYPE IS
        l_date_ret cda_req_det.dt_status_end%TYPE;
    BEGIN
        SELECT nvl(crd.dt_status_start, crd.dt_status_end)
          INTO l_date_ret
          FROM cda_req_det crd
         WHERE crd.id_cda_req = i_cda_req
           AND crd.flg_status = k_ready_status;
        RETURN l_date_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_cda_date_ready;
    FUNCTION get_cda_date_finished(i_cda_req IN cda_req_det.id_cda_req%TYPE) RETURN cda_req_det.dt_status_end%TYPE IS
        l_date_ret cda_req_det.dt_status_end%TYPE;
    BEGIN
        SELECT nvl(crd.dt_status_end, crd.dt_status_start)
          INTO l_date_ret
          FROM cda_req_det crd
         WHERE crd.id_cda_req = i_cda_req
           AND crd.flg_status = k_finish_status;
        RETURN l_date_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_cda_date_finished;
    FUNCTION get_cda_table
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE
    ) RETURN tbl_cda_req IS
        l_cda_res tbl_cda_req := tbl_cda_req();
    BEGIN
        SELECT cr.*
          BULK COLLECT
          INTO l_cda_res
          FROM cda_req cr
         WHERE cr.id_cda_req = i_id_cda_req;
    
        RETURN l_cda_res;
    END get_cda_table;
    FUNCTION get_cda_det_table
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE
    ) RETURN tbl_cda_req_det IS
        l_cda_req_res tbl_cda_req_det := tbl_cda_req_det();
    BEGIN
        SELECT crd.*
          BULK COLLECT
          INTO l_cda_req_res
          FROM cda_req_det crd
         WHERE crd.id_cda_req = i_id_cda_req
         ORDER BY crd.id_cda_req_det DESC;
    
        RETURN l_cda_req_res;
    END get_cda_det_table;
    /********************************************************************************************
    * Get the fields data to be shown in the detail current information screen 
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_actual_row              CDA_REQ data current record
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                RMGM                   
    * @version                               2.6.4.1                                    
    * @since                                 2014/07/15       
    ********************************************************************************************/
    FUNCTION get_cda_current_val
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN cda_req%ROWTYPE,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar
    ) RETURN BOOLEAN IS
        -- auxiliar vars
        l_ret          BOOLEAN;
        l_error        t_error_out;
        l_report_id    reports.id_reports%TYPE;
        l_reports_desc translation.desc_lang_1%TYPE;
    
        l_qrda_type      VARCHAR2(200);
        l_qrda_list_desc VARCHAR2(1000);
    
        o_tab_type_emeasure alert_inter.tab_type_emeasure := alert_inter.tab_type_emeasure();
        -- auxiliar arrays
        l_qrda_list table_number := table_number();
        l_qrda_desc table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'GET STATUS DETAILS FOR REQUEST ' || i_actual_row.id_cda_req;
        SELECT DISTINCT crh.id_report, crh.qrda_type
          INTO l_report_id, l_qrda_type
          FROM cda_req_det crh
         WHERE crh.id_cda_req = i_actual_row.id_cda_req;
    
        g_error := 'GET REPORT DESC ' || l_report_id;
        SELECT pk_translation.get_translation(i_lang, r.code_reports)
          INTO l_reports_desc
          FROM reports r
         WHERE r.id_reports = l_report_id;
    
        g_error := 'GET QRDA LIST FOR REQUEST ' || i_actual_row.id_cda_req;
        l_ret   := alert_inter.pk_rt_adw_hie.get_emeasures_list(i_lang,
                                                                NULL,
                                                                profissional(0, 0, 0),
                                                                o_tab_type_emeasure,
                                                                l_error);
    
        g_error     := 'CONVERT QRDA TO TABLE ' || l_qrda_type;
        l_qrda_list := pk_utils.str_split_n(l_qrda_type, '|');
    
        g_error := 'QUERY MEASURES DETAILS FOR REQUEST ' || l_qrda_type;
        SELECT tbl.measure_short_name desc_measure
          BULK COLLECT
          INTO l_qrda_desc
          FROM TABLE(o_tab_type_emeasure) tbl
         WHERE tbl.measure IN (SELECT /*+dynamic_sampling recs(2)*/
                                column_value
                                 FROM TABLE(l_qrda_list) recs);
        g_error          := 'CONVERT QRDA DESC TABLE TO VC2 ' || l_qrda_type;
        l_qrda_list_desc := pk_utils.concat_table(l_qrda_desc, ';');
    
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => l_reports_desc,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        -- CDA request
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T002'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_backoffice_cda.get_cda_desc(i_lang, i_actual_row.id_cda_req),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --status         
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T026'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain('CDA_REQ.FLG_STATUS',
                                                                         i_actual_row.flg_status,
                                                                         i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        IF i_actual_row.flg_type != 'P'
        THEN
            -- QRDA type
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T004'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain('CDA_REQ_HIST.FLG_TYPE',
                                                                             l_report_id,
                                                                             i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
            -- measures list
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T006'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_qrda_list_desc,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
            -- Range Date start
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_T821'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.dt_chr(i_lang,
                                                                          i_actual_row.dt_range_start,
                                                                          profissional(0, i_actual_row.id_institution, 0)),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
            -- Range date end
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_T822'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.dt_chr(i_lang,
                                                                          i_actual_row.dt_range_end,
                                                                          profissional(0, i_actual_row.id_institution, 0)),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        END IF;
        -- Request date
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T011'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_date_utils.get_string_strtimezone(2,
                                                                                      profissional(0,
                                                                                                   i_actual_row.id_institution,
                                                                                                   0),
                                                                                      pk_date_utils.dt_chr_date_hour_tsz(2,
                                                                                                                         get_cda_date_ready(i_actual_row.id_cda_req),
                                                                                                                         profissional(0,
                                                                                                                                      i_actual_row.id_institution,
                                                                                                                                      0))),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        -- Request date
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T012'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_date_utils.get_string_strtimezone(2,
                                                                                      profissional(0,
                                                                                                   i_actual_row.id_institution,
                                                                                                   0),
                                                                                      pk_date_utils.dt_chr_date_hour_tsz(2,
                                                                                                                         get_cda_date_finished(i_actual_row.id_cda_req),
                                                                                                                         profissional(0,
                                                                                                                                      i_actual_row.id_institution,
                                                                                                                                      0))),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_tools.get_prof_description(i_lang,
                                                                               profissional(0, 0, 0),
                                                                               i_actual_row.id_professional,
                                                                               i_actual_row.dt_start,
                                                                               NULL) || ' ' ||
                                                 pk_date_utils.get_string_strtimezone(i_lang,
                                                                                      profissional(0,
                                                                                                   i_actual_row.id_institution,
                                                                                                   0),
                                                                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                                                         nvl(i_actual_row.dt_end,
                                                                                                                             i_actual_row.dt_start),
                                                                                                                         profissional(0,
                                                                                                                                      i_actual_row.id_institution,
                                                                                                                                      0))),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        RETURN TRUE;
    END get_cda_current_val;

    /********************************************************************************************
    * Get the fields data to be shown in the detail current information screen 
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_actual_row              CDA_REQ_DET data current record
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                RMGM                   
    * @version                               2.6.4.1                                    
    * @since                                 2014/07/15       
    ********************************************************************************************/
    FUNCTION get_cda_hist_val
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN cda_req_det%ROWTYPE,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar
    ) RETURN BOOLEAN IS
        -- auxiliar vars
        l_ret   BOOLEAN;
        l_error t_error_out;
    
        l_cda_req_inst   cda_req.id_institution%TYPE;
        l_cda_req_type   cda_req.flg_type%TYPE;
        l_cda_req_prof   cda_req.id_professional%TYPE;
        l_cda_req_status cda_req.flg_status%TYPE;
        l_cda_req_start  cda_req.dt_range_start%TYPE;
        l_cda_req_end    cda_req.dt_range_end%TYPE;
    
        l_qrda_list_desc VARCHAR2(1000);
        l_reports_desc   translation.desc_lang_1%TYPE;
    
        o_tab_type_emeasure alert_inter.tab_type_emeasure := alert_inter.tab_type_emeasure();
        -- auxiliar arrays
        l_qrda_list table_number := table_number();
        l_qrda_desc table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'GET REQUEST INITIAL DATA ' || i_actual_row.id_cda_req;
        SELECT cr.id_institution, cr.flg_type, cr.flg_status, cr.dt_range_start, cr.dt_range_end, cr.id_professional
          INTO l_cda_req_inst, l_cda_req_type, l_cda_req_status, l_cda_req_start, l_cda_req_end, l_cda_req_prof
          FROM cda_req cr
         WHERE cr.id_cda_req = i_actual_row.id_cda_req;
    
        g_error := 'GET REPORT DESC ' || i_actual_row.id_report;
        SELECT pk_translation.get_translation(i_lang, r.code_reports)
          INTO l_reports_desc
          FROM reports r
         WHERE r.id_reports = i_actual_row.id_report;
    
        g_error := 'GET QRDA LIST FOR REQUEST ' || i_actual_row.id_cda_req;
        l_ret   := alert_inter.pk_rt_adw_hie.get_emeasures_list(i_lang,
                                                                NULL,
                                                                profissional(0, l_cda_req_inst, 0),
                                                                o_tab_type_emeasure,
                                                                l_error);
    
        g_error     := 'CONVERT QRDA TO TABLE ' || i_actual_row.qrda_type;
        l_qrda_list := pk_utils.str_split_n(i_actual_row.qrda_type, '|');
    
        g_error := 'QUERY MEASURES DETAILS FOR REQUEST ' || i_actual_row.qrda_type;
        SELECT tbl.measure_short_name desc_measure
          BULK COLLECT
          INTO l_qrda_desc
          FROM TABLE(o_tab_type_emeasure) tbl
         WHERE tbl.measure IN (SELECT /*+dynamic_sampling recs(2)*/
                                column_value
                                 FROM TABLE(l_qrda_list) recs);
        g_error          := 'CONVERT QRDA DESC TABLE TO VC2 ' || i_actual_row.qrda_type;
        l_qrda_list_desc := pk_utils.concat_table(l_qrda_desc, ';');
    
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => l_reports_desc,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        -- CDA request
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T002'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_backoffice_cda.get_cda_desc(i_lang, i_actual_row.id_cda_req),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --status         
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T026'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain('CDA_REQ.FLG_STATUS',
                                                                         i_actual_row.flg_status,
                                                                         i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        IF l_cda_req_type != 'P'
        THEN
            -- QRDA type
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T004'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain('CDA_REQ_HIST.FLG_TYPE',
                                                                             i_actual_row.id_report,
                                                                             i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
            -- measures list
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T006'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_qrda_list_desc,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
            -- Range Date start
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_T821'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.dt_chr(i_lang,
                                                                          l_cda_req_start,
                                                                          profissional(0, l_cda_req_inst, 0)),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
            -- Range date end
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_T822'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.dt_chr(i_lang,
                                                                          l_cda_req_end,
                                                                          profissional(0, l_cda_req_inst, 0)),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        END IF;
        -- Request date
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T011'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_date_utils.get_string_strtimezone(2,
                                                                                      profissional(0, l_cda_req_inst, 0),
                                                                                      pk_date_utils.dt_chr_date_hour_tsz(2,
                                                                                                                         i_actual_row.dt_status_start,
                                                                                                                         profissional(0,
                                                                                                                                      l_cda_req_inst,
                                                                                                                                      0))),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        -- Request date
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'ADMINISTRATOR_CDA_T012'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_date_utils.get_string_strtimezone(2,
                                                                                      profissional(0, l_cda_req_inst, 0),
                                                                                      pk_date_utils.dt_chr_date_hour_tsz(2,
                                                                                                                         i_actual_row.dt_status_end,
                                                                                                                         profissional(0,
                                                                                                                                      l_cda_req_inst,
                                                                                                                                      0))),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_tools.get_prof_description(i_lang,
                                                                               profissional(0, 0, 0),
                                                                               l_cda_req_prof,
                                                                               i_actual_row.dt_status_start,
                                                                               NULL) || ' ' ||
                                                 pk_date_utils.get_string_strtimezone(i_lang,
                                                                                      profissional(0, l_cda_req_inst, 0),
                                                                                      pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                                                         i_actual_row.dt_status_start,
                                                                                                                         profissional(0,
                                                                                                                                      l_cda_req_inst,
                                                                                                                                      0))),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        RETURN TRUE;
    END get_cda_hist_val;

    FUNCTION get_id_from_rowid
    (
        i_rowid      IN VARCHAR2,
        i_table_name IN VARCHAR2
    ) RETURN NUMBER IS
    
        l_function_name VARCHAR2(30 CHAR) := 'insert_into_ab_market';
        l_ret           NUMBER(24);
        l_sql           VARCHAR2(1000 CHAR);
    
    BEGIN
        g_error := 'Get rowid ' || i_rowid || ' in table ' || i_table_name;
        l_sql   := 'select id_' || i_table_name || ' from ' || i_table_name || ' where rowid = ''' || i_rowid || '''';
    
        EXECUTE IMMEDIATE l_sql
            INTO l_ret;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              g_error_out);
            RETURN NULL;
    END get_id_from_rowid;
    FUNCTION get_cda_institution(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN NUMBER IS
        l_institution institution.id_institution%TYPE;
    BEGIN
        SELECT cr.id_institution
          INTO l_institution
          FROM cda_req cr
         WHERE cr.id_cda_req = i_id_cda_req;
        RETURN l_institution;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cda_institution;
    FUNCTION get_cda_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_cda_req IN cda_req.id_cda_req%TYPE
    ) RETURN VARCHAR2 IS
        l_cda_req_id   cda_req.id_cda_req%TYPE;
        l_cda_req_type cda_req.flg_type%TYPE;
        l_cda_desc     translation.desc_lang_1%TYPE;
    BEGIN
        SELECT cr.id_cda_req, cr.flg_type
          INTO l_cda_req_id, l_cda_req_type
          FROM cda_req cr
         WHERE cr.id_cda_req = i_id_cda_req;
    
        l_cda_desc := pk_sysdomain.get_domain(i_code_dom => k_code_domain_type,
                                              i_val      => l_cda_req_type,
                                              i_lang     => i_lang) || '_' || l_cda_req_id;
        RETURN l_cda_desc;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cda_desc;
    /********************************************************************************************
    * Get request Next rank status
    *
    * @param i_lang 
    * @param i_id_institution 
    * @param i_previous_status 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_next_ranked_status
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_previous_status IN cda_req.flg_status%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_rank NUMBER := 0;
        o_val  VARCHAR2(1) := NULL;
    BEGIN
        g_error := '4.Get Min next Rank after status ' || i_previous_status;
        SELECT MIN(x.rank)
          INTO l_rank
          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                              profissional(0, i_id_institution, 0),
                                                              'CDA_REQ.FLG_STATUS',
                                                              NULL)) x
         WHERE (x.val = i_previous_status OR i_previous_status IS NULL);
        g_error := '4.Get next status with rank ' || l_rank;
        SELECT tbl.val
          INTO o_val
          FROM (SELECT x.val
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      profissional(0, i_id_institution, 0),
                                                                      'CDA_REQ.FLG_STATUS',
                                                                      NULL)) x
                 WHERE (x.rank > l_rank OR (x.rank = l_rank AND i_previous_status IS NULL))
                 ORDER BY x.rank) tbl
         WHERE rownum = 1;
        g_error := '4.Return next status ' || o_val;
        RETURN o_val;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_next_ranked_status;
    /********************************************************************************************
    * Get current request status
    *
    * @param i_id_cda_req 
    *
    * @return                        status value
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_det_status(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN VARCHAR2 IS
        l_id_pk cda_req_det.id_cda_req_det%TYPE := 0;
        o_val   VARCHAR2(1) := NULL;
    BEGIN
        g_error := '5.Get max status in det table for req ' || i_id_cda_req;
        SELECT MAX(crh.id_cda_req_det)
          INTO l_id_pk
          FROM cda_req_det crh
         WHERE crh.id_cda_req = i_id_cda_req;
        g_error := '5.PK found ' || l_id_pk;
        SELECT crh.flg_status
          INTO o_val
          FROM cda_req_det crh
         WHERE crh.id_cda_req_det = l_id_pk;
        g_error := '5.Starting with status  ' || o_val;
        RETURN o_val;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_cda_req_det_status;
    /********************************************************************************************
    * Get status from request
    *
    * @param i_id_cda_req
    *
    * @return                        current status
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_status(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN VARCHAR2 IS
        l_status cda_req.flg_status%TYPE := NULL;
    BEGIN
        SELECT cr.flg_status
          INTO l_status
          FROM cda_req cr
         WHERE cr.id_cda_req = i_id_cda_req;
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cda_req_status;
    /********************************************************************************************
    * Get Latest ID cda request detory
    *
    * @param i_id_cda_req 
    *
    * @return                        detory id
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_current_cda_req_det(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN NUMBER IS
        l_pk cda_req_det.id_cda_req_det%TYPE := 0;
    BEGIN
        SELECT crh.id_cda_req_det
          INTO l_pk
          FROM cda_req_det crh
         WHERE crh.id_cda_req = i_id_cda_req
           AND crh.dt_status_end IS NULL;
        RETURN l_pk;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_current_cda_req_det;
    /********************************************************************************************
    * Set next cda request detory record
    *
    * @param i_id_cda_req_det 
    * @param i_id_cda_req 
    * @param i_flg_status 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_next_cda_req_det
    (
        i_id_cda_req_det IN cda_req_det.id_cda_req_det%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_flg_status     IN cda_req_det.flg_status%TYPE
    ) RETURN BOOLEAN IS
        l_flg_type    cda_req_det.id_report%TYPE := NULL;
        l_flg_subtype cda_req_det.qrda_type%TYPE := NULL;
    BEGIN
        g_error := 'Get FLGS from previous cda request detory ' || i_id_cda_req_det;
        SELECT crh.id_report, crh.qrda_type
          INTO l_flg_type, l_flg_subtype
          FROM cda_req_det crh
         WHERE crh.id_cda_req_det = i_id_cda_req_det;
        IF i_flg_status IN (k_finish_status, k_cancel_status)
        THEN
            g_error := 'Set New Status record ' || i_flg_status;
            ts_cda_req_det.ins(id_cda_req_det_in  => seq_cda_req_det.nextval,
                               id_cda_req_in      => i_id_cda_req,
                               flg_status_in      => i_flg_status,
                               id_report_in       => l_flg_type,
                               qrda_type_in       => l_flg_subtype,
                               dt_status_start_in => current_timestamp,
                               dt_status_end_in   => current_timestamp);
        ELSE
            g_error := 'Set New Status record ' || i_flg_status;
            ts_cda_req_det.ins(id_cda_req_det_in  => seq_cda_req_det.nextval,
                               id_cda_req_in      => i_id_cda_req,
                               flg_status_in      => i_flg_status,
                               id_report_in       => l_flg_type,
                               qrda_type_in       => l_flg_subtype,
                               dt_status_start_in => current_timestamp);
        END IF;
        RETURN TRUE;
    END set_next_cda_req_det;
    /********************************************************************************************
    * Get CDA Report ID 
    *
    * @param o_id_report 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_report_id
    (
        i_id_software IN software.id_software%TYPE,
        o_id_report   OUT report_software.id_report%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        --o_id_report := k_cda_report_id;
        SELECT rs.id_report
          INTO o_id_report
          FROM report_software rs
         WHERE rs.id_software = i_id_software
           AND rs.flg_cda_type = 'P';
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_id_report := NULL;
            RETURN FALSE;
    END get_cda_report_id;
    -- get search ids
    FUNCTION get_cda_search
    (
        i_lang       IN language.id_language%TYPE,
        i_search_val IN translation.desc_lang_1%TYPE
    ) RETURN table_number IS
        l_cda_req_id table_number := table_number();
        l_search_val translation.desc_lang_1%TYPE := '%' || translate(upper(i_search_val),
                                                                      'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                                                      'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%';
    BEGIN
        SELECT a.id_cda_req
          BULK COLLECT
          INTO l_cda_req_id
          FROM cda_req a
         WHERE translate(upper(pk_backoffice_cda.get_cda_desc(i_lang, a.id_cda_req)),
                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE l_search_val
        
        ;
        RETURN l_cda_req_id;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN table_number();
        WHEN OTHERS THEN
            RETURN table_number();
    END get_cda_search;
    -- PUBLIC METHODS
    /********************************************************************************************
    * Get detailed CDA request table
    *
    * @param i_lang 
    * @param i_id_institution 
    * @param o_results 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_results        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Get CDA Req list for institution  ' || i_id_institution;
        OPEN o_results FOR
            SELECT cr.id_cda_req,
                   cr.flg_status,
                   pk_sysdomain.get_domain(k_code_domain_status, cr.flg_status, i_lang) status_desc,
                   cr.flg_type,
                   pk_backoffice_cda.get_cda_desc(i_lang, cr.id_cda_req) req_desc,
                   pk_date_utils.get_string_strtimezone(i_lang,
                                                        profissional(0, i_id_institution, 0),
                                                        pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                           nvl(cr.dt_end,
                                                                                               (SELECT MAX(crh.dt_status_end)
                                                                                                  FROM cda_req_det crh
                                                                                                 WHERE crh.id_cda_req =
                                                                                                       cr.id_cda_req
                                                                                                   AND crh.dt_status_end IS NOT NULL)),
                                                                                           profissional(0,
                                                                                                        i_id_institution,
                                                                                                        0))) dt_end
              FROM cda_req cr
             WHERE id_institution = i_id_institution;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CDA_REQ',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_results);
            RETURN FALSE;
    END get_cda_req;
    /********************************************************************************************
    * Get detailed CDA request detory
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param o_results 
    * @param o_results_prof 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_id_cda_req   IN cda_req.id_cda_req%TYPE,
        o_results      OUT pk_types.cursor_type,
        o_results_prof OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret               BOOLEAN;
        o_tab_type_emeasure alert_inter.tab_type_emeasure := alert_inter.tab_type_emeasure();
    
        l_report_id    reports.id_reports%TYPE;
        l_reports_desc translation.desc_lang_1%TYPE;
    
        l_qrda_type      VARCHAR2(200);
        l_qrda_list      table_number := table_number();
        l_qrda_desc      table_varchar := table_varchar();
        l_qrda_list_desc VARCHAR2(1000);
    
    BEGIN
        g_error := 'GET STATUS DETAILS FOR REQUEST ' || i_id_cda_req;
        SELECT DISTINCT crh.id_report, crh.qrda_type
          INTO l_report_id, l_qrda_type
          FROM cda_req_det crh
         WHERE crh.id_cda_req = i_id_cda_req;
    
        g_error := 'GET REPORT DESC ' || l_report_id;
        SELECT pk_translation.get_translation(i_lang, r.code_reports)
          INTO l_reports_desc
          FROM reports r
         WHERE r.id_reports = l_report_id;
    
        -- get cda req_det value fieds
        IF l_report_id != 691
        THEN
        
            g_error := 'GET QRDA LIST FOR REQUEST ' || i_id_cda_req;
            l_ret   := alert_inter.pk_rt_adw_hie.get_emeasures_list(i_lang,
                                                                    NULL,
                                                                    profissional(0, 0, 0),
                                                                    o_tab_type_emeasure,
                                                                    o_error);
        
            g_error     := 'CONVERT QRDA TO TABLE ' || l_qrda_type;
            l_qrda_list := pk_utils.str_split_n(l_qrda_type, '|');
        
            g_error := 'QUERY MEASURES DETAILS FOR REQUEST ' || l_qrda_type;
            SELECT tbl.measure_short_name desc_measure
              BULK COLLECT
              INTO l_qrda_desc
              FROM TABLE(o_tab_type_emeasure) tbl
             WHERE tbl.measure IN (SELECT /*+dynamic_sampling recs(2)*/
                                    column_value
                                     FROM TABLE(l_qrda_list) recs);
            g_error          := 'CONVERT QRDA DESC TABLE TO VC2 ' || l_qrda_type;
            l_qrda_list_desc := pk_utils.concat_table(l_qrda_desc, ';');
        
            g_error := 'Get CDA Req Detail for Cda request  ' || i_id_cda_req;
            OPEN o_results FOR
                SELECT cr.id_cda_req id,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T002')) ||
                       pk_backoffice_cda.get_cda_desc(i_lang, cr.id_cda_req) req_desc,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375')) ||
                       l_reports_desc rep_type,
                       -- STATUS
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_IDENT_T026')) ||
                       pk_sysdomain.get_domain('CDA_REQ.FLG_STATUS', cr.flg_status, i_lang) status_desc,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T004')) ||
                       pk_sysdomain.get_domain('CDA_REQ_HIST.FLG_TYPE', l_report_id, i_lang) det_type,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T006')) ||
                       
                       l_qrda_list_desc det_stp,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T821')) ||
                       cr.dt_range_start dt_search_start,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T822')) ||
                       cr.dt_range_end dt_search_end,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T011')) ||
                       pk_date_utils.get_string_strtimezone(i_lang,
                                                            profissional(0, cr.id_institution, 0),
                                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                               cr.dt_start,
                                                                                               profissional(0,
                                                                                                            cr.id_institution,
                                                                                                            0))) dt_req_start,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T012')) ||
                       pk_date_utils.get_string_strtimezone(i_lang,
                                                            profissional(0, cr.id_institution, 0),
                                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                               cr.dt_end,
                                                                                               profissional(0,
                                                                                                            cr.id_institution,
                                                                                                            0))) dt_req_end
                  FROM cda_req cr
                 WHERE cr.id_cda_req = i_id_cda_req;
        ELSE
            g_error := 'Get CDA Req Detail for Cda request  ' || i_id_cda_req;
            OPEN o_results FOR
                SELECT cr.id_cda_req id,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T002')) ||
                       pk_backoffice_cda.get_cda_desc(i_lang, cr.id_cda_req) req_desc,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375')) ||
                       l_reports_desc rep_type,
                       -- STATUS
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_IDENT_T026')) ||
                       pk_sysdomain.get_domain('CDA_REQ.FLG_STATUS', cr.flg_status, i_lang) status_desc,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T011')) ||
                       pk_date_utils.get_string_strtimezone(i_lang,
                                                            profissional(0, cr.id_institution, 0),
                                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                               cr.dt_start,
                                                                                               profissional(0,
                                                                                                            cr.id_institution,
                                                                                                            0))) dt_req_start,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_CDA_T012')) ||
                       pk_date_utils.get_string_strtimezone(i_lang,
                                                            profissional(0, cr.id_institution, 0),
                                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                               cr.dt_end,
                                                                                               profissional(0,
                                                                                                            cr.id_institution,
                                                                                                            0))) dt_req_end
                  FROM cda_req cr
                 WHERE cr.id_cda_req = i_id_cda_req;
        END IF;
        OPEN o_results_prof FOR
            SELECT cr.id_cda_req id,
                   pk_date_utils.get_string_strtimezone(i_lang,
                                                        profissional(0, cr.id_institution, 0),
                                                        pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                           cr.dt_start,
                                                                                           profissional(0,
                                                                                                        cr.id_institution,
                                                                                                        0))) dt,
                   pk_tools.get_prof_description(i_lang, profissional(0, 0, 0), cr.id_professional, cr.dt_start, NULL) prof_sign,
                   cr.dt_end dt_last_update,
                   cr.flg_status flg_status,
                   pk_sysdomain.get_domain('CDA_REQ.FLG_STATUS', cr.flg_status, i_lang) desc_status
            
              FROM cda_req cr
             WHERE cr.id_cda_req = i_id_cda_req;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CDA_REQ_det',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_results);
            RETURN FALSE;
    END get_cda_req_det;
    /********************************************************************************************
    * Insert a report generation request
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_id_institution 
    * @param i_flg_type 
    * @param i_dt_start 
    * @param i_dt_end 
    * @param i_sw_list 
    * @param o_cda_req 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION insert_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN cda_req.flg_type%TYPE,
        i_dt_start       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_sw_list        IN cda_req.id_software%TYPE,
        o_cda_req        OUT cda_req.id_cda_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next_status cda_req.flg_status%TYPE;
        l_out         table_varchar := table_varchar();
    BEGIN
        g_error       := ' 2 -Get Next available status for institution  ' || i_id_institution;
        l_next_status := get_next_ranked_status(i_lang, i_id_institution);
    
        g_error := ' 2 -GOt status ' || l_next_status;
        ts_cda_req.ins(id_cda_req_in      => seq_cda_req.nextval,
                       id_professional_in => i_prof.id,
                       id_institution_in  => i_id_institution,
                       flg_status_in      => l_next_status,
                       flg_type_in        => i_flg_type,
                       dt_start_in        => current_timestamp,
                       dt_range_start_in  => to_date(i_dt_start, pk_date_utils.g_dateformat),
                       dt_range_end_in    => to_date(i_dt_end, pk_date_utils.g_dateformat),
                       id_software_in     => i_sw_list,
                       rows_out           => l_out);
    
        o_cda_req := pk_backoffice_cda.get_id_from_rowid(l_out(1), 'CDA_REQ');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_CDA_REQ',
                                              o_error    => o_error);
            o_cda_req := NULL;
            RETURN FALSE;
    END insert_cda_req;
    /********************************************************************************************
    * Insert a report generation request detory
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param i_id_institution 
    * @param i_flg_type 
    * @param i_flg_stype 
    * @param o_cda_req_det 
    * @param o_error  
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION insert_cda_req_det
    (
        i_lang           IN language.id_language%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE,
        i_flg_type       IN cda_req_det.id_report%TYPE,
        i_flg_stype      IN cda_req_det.qrda_type%TYPE,
        o_cda_req_det    OUT cda_req_det.id_cda_req_det%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_status cda_req.flg_status%TYPE := NULL;
        l_next_status    cda_req.flg_status%TYPE := NULL;
        l_out            table_varchar := table_varchar();
    BEGIN
        l_current_status := get_cda_req_det_status(i_id_cda_req);
        g_error          := '  3 -GOt current status ' || l_current_status;
        IF l_current_status IS NULL
        THEN
            l_next_status := get_cda_req_status(i_id_cda_req);
            g_error       := '  3 -GOt next status (request) ' || l_next_status;
        ELSE
            l_next_status := get_next_ranked_status(i_lang, i_id_institution, l_current_status);
            g_error       := '  3 -GOt next status (detory) ' || l_next_status;
        END IF;
        ts_cda_req_det.ins(id_cda_req_det_in  => seq_cda_req_det.nextval,
                           id_cda_req_in      => i_id_cda_req,
                           flg_status_in      => l_next_status,
                           id_report_in       => i_flg_type,
                           qrda_type_in       => i_flg_stype,
                           dt_status_start_in => current_timestamp,
                           rows_out           => l_out);
        o_cda_req_det := pk_backoffice_cda.get_id_from_rowid(l_out(1), 'CDA_REQ_det');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_CDA_REQ_det',
                                              o_error    => o_error);
            o_cda_req_det := NULL;
            RETURN FALSE;
    END insert_cda_req_det;
    /********************************************************************************************
    * Set a Complete CDA request
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_id_institution 
    * @param i_flg_type 
    * @param i_dt_start 
    * @param i_dt_end 
    * @param i_qrda_type 
    * @param i_qrda_stype 
    * @param i_sw_list 
    * @param o_cda_req 
    * @param o_cda_req_det 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN cda_req.flg_type%TYPE,
        i_dt_start       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_qrda_type      IN cda_req_det.id_report%TYPE,
        i_qrda_stype     IN cda_req_det.qrda_type%TYPE,
        i_sw_list        IN cda_req.id_software%TYPE,
        o_cda_req        OUT cda_req.id_cda_req%TYPE,
        o_cda_req_det    OUT cda_req_det.id_cda_req_det%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET CDA REQUEST INFO';
        IF NOT pk_backoffice_cda.insert_cda_req(i_lang,
                                                i_prof,
                                                i_id_institution,
                                                i_flg_type,
                                                i_dt_start,
                                                i_dt_end,
                                                i_sw_list,
                                                o_cda_req,
                                                g_error_out)
        THEN
            RAISE g_exception;
        ELSE
            g_error := 'SET CDA REQUEST DETAILS INFO FOR REQUEST ' || o_cda_req;
            IF NOT pk_backoffice_cda.insert_cda_req_det(i_lang,
                                                        o_cda_req,
                                                        i_id_institution,
                                                        i_qrda_type,
                                                        i_qrda_stype,
                                                        o_cda_req_det,
                                                        g_error_out)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => g_error_out.ora_sqlcode,
                                              i_sqlerrm  => g_error_out.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CDA_REQ',
                                              o_error    => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CDA_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_cda_req;
    /********************************************************************************************
    * Set report next logical status
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param i_id_institution 
    * @param o_error  
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    PROCEDURE set_cda_next_status
    (
        i_lang           IN language.id_language%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE
    ) IS
        l_current_status cda_req.flg_status%TYPE;
        l_next_status    cda_req.flg_status%TYPE;
        l_curr_id_crh    cda_req_det.id_cda_req_det%TYPE := 0;
        l_ret            BOOLEAN;
        l_error          t_error_out;
    BEGIN
    
        g_error          := 'Get current status ' || i_id_cda_req;
        l_current_status := pk_backoffice_cda.get_cda_req_det_status(i_id_cda_req => i_id_cda_req);
    
        IF l_current_status NOT IN (k_finish_status, k_cancel_status)
        THEN
            g_error       := 'Get Next status ' || i_id_cda_req;
            l_next_status := pk_backoffice_cda.get_next_ranked_status(i_lang, i_id_institution, l_current_status);
        
            IF l_next_status IN (k_finish_status, k_cancel_status)
            THEN
                g_error := 'Set status date ' || i_id_cda_req;
                ts_cda_req.upd(id_cda_req_in  => i_id_cda_req,
                               flg_status_nin => TRUE,
                               flg_status_in  => l_next_status,
                               dt_end_nin     => TRUE,
                               dt_end_in      => current_timestamp);
            ELSE
                g_error := 'Set status date ' || i_id_cda_req;
                ts_cda_req.upd(id_cda_req_in => i_id_cda_req, flg_status_nin => TRUE, flg_status_in => l_next_status);
            END IF;
            g_error       := 'Get current cda request detory id ' || i_id_cda_req;
            l_curr_id_crh := get_current_cda_req_det(i_id_cda_req);
        
            g_error := 'Close cda request detail status ' || i_id_cda_req;
            ts_cda_req_det.upd(id_cda_req_det_in => l_curr_id_crh,
                               dt_status_end_nin => TRUE,
                               dt_status_end_in  => current_timestamp);
        
            g_error := 'Set New cda request detail Status ' || i_id_cda_req;
            l_ret   := set_next_cda_req_det(l_curr_id_crh, i_id_cda_req, l_next_status);
            IF l_next_status IN (k_finish_status, k_cancel_status)
            THEN
                g_error       := 'Get current cda request detory id ' || i_id_cda_req;
                l_curr_id_crh := get_current_cda_req_det(i_id_cda_req);
            
                ts_cda_req_det.upd(id_cda_req_det_in => l_curr_id_crh,
                                   dt_status_end_nin => TRUE,
                                   dt_status_end_in  => current_timestamp);
            END IF;
        END IF;
        IF l_current_status = k_ready_status
        THEN
            l_ret := pk_alerts.delete_evt_gen_report(i_lang, i_id_cda_req, i_id_institution, l_error);
        END IF;
    
    END set_cda_next_status;
    /********************************************************************************************
    * Get Measures list
    *
    * @param i_lang 
    * @param i_prof 
    * @param o_tab_emeasure 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_qrda_measures
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_tab_emeasure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret               BOOLEAN;
        o_tab_type_emeasure alert_inter.tab_type_emeasure := alert_inter.tab_type_emeasure();
    BEGIN
        l_ret := alert_inter.pk_rt_adw_hie.get_emeasures_list(i_lang, NULL, i_prof, o_tab_type_emeasure, o_error);
        OPEN o_tab_emeasure FOR
            SELECT tblv.id_measure, tblv.desc_measure, tblv.rank
              FROM (SELECT tbl.measure id_measure, tbl.measure_short_name desc_measure, 1 rank
                      FROM TABLE(o_tab_type_emeasure) tbl
                    UNION
                    SELECT -1 id_measure, pk_message.get_message(i_lang, 'COMMON_M014') desc_measure, 0 rank
                      FROM dual) tblv
             ORDER BY tblv.rank, tblv.desc_measure;
        RETURN l_ret;
    END get_qrda_measures;
    /********************************************************************************************
    * Get software CDA request list
    *
    * @param i_lang 
    * @param i_flg_cda_req_type 
    * @param i_flg_type_qrda 
    * @param o_result_sw 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_software_list
    (
        i_lang             IN language.id_language%TYPE,
        i_flg_cda_req_type IN cda_req.flg_type%TYPE,
        i_flg_type_qrda    IN cda_req_det.qrda_type%TYPE,
        o_result_sw        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_qrda_type_list table_number := table_number();
    
        l_temp_sw   table_number := table_number();
        l_resutl_sw table_number := table_number();
    BEGIN
        IF (i_flg_cda_req_type IS NULL AND i_flg_type_qrda IS NULL)
        THEN
            RAISE l_exception;
        END IF;
    
        IF (i_flg_cda_req_type = k_cda_flg_type AND i_flg_type_qrda IS NULL)
        THEN
            SELECT rx.id_software
              BULK COLLECT
              INTO l_resutl_sw
              FROM report_software rx
             WHERE rx.flg_cda_type = k_cda_flg_type
             GROUP BY rx.id_software;
        
        ELSIF (i_flg_cda_req_type = k_qrda_flg_type AND i_flg_type_qrda IS NOT NULL)
        THEN
            l_qrda_type_list := pk_utils.str_split_n(i_flg_type_qrda, '|');
        
            SELECT rx.id_software
              BULK COLLECT
              INTO l_resutl_sw
              FROM report_software rx
             WHERE rx.id_report IN (SELECT /*+opt_estimate (x=2)*/
                                     x.column_value
                                      FROM TABLE(l_qrda_type_list) x)
             GROUP BY rx.id_software;
        
        ELSIF (i_flg_cda_req_type = k_qrda_flg_type AND i_flg_type_qrda IS NULL)
        THEN
            SELECT rx.id_software
              BULK COLLECT
              INTO l_resutl_sw
              FROM report_software rx
             WHERE rx.flg_cda_type = k_qrda_flg_type
             GROUP BY rx.id_software;
        ELSE
            RAISE l_exception;
        END IF;
        OPEN o_result_sw FOR
            SELECT s.id_ab_software id_software, pk_translation.get_translation(i_lang, s.code_software) desc_software
              FROM TABLE(l_resutl_sw) sw
             INNER JOIN ab_software s
                ON (sw.column_value = s.id_ab_software);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CDA_SOFTWARE_LIST',
                                              g_error_out);
            RETURN FALSE;
    END get_cda_software_list;
    /********************************************************************************************
    * Save zipped report file, go to next status and generate alert
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_id_cda_req 
    * @param i_id_institution 
    * @param i_file 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION save_req_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE,
        i_file           IN BLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    
    BEGIN
        g_error := 'SAVE REPORT IN REQUEST ' || i_id_cda_req;
        ts_cda_req.upd(id_cda_req_in => i_id_cda_req, cda_report_file_nin => TRUE, cda_report_file_in => i_file);
    
        g_error := 'UPDATE STATUS IN ' || i_id_cda_req;
        pk_backoffice_cda.set_cda_next_status(i_lang           => i_lang,
                                              i_id_cda_req     => i_id_cda_req,
                                              i_id_institution => i_id_institution);
    
        g_error := 'LAUCH ALERT FOR REQUEST ' || i_id_cda_req;
        l_ret   := pk_alerts.insert_evt_gen_report(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_cda_req => i_id_cda_req,
                                                   o_error   => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SAVE_REQ_REPORT',
                                              o_error    => o_error);
            RETURN FALSE;
    END save_req_report;
    /********************************************************************************************
    * Retrieve file to servlet in order to be sent to ux for download
    *
    * @param i_cda_req 
    * @param o_file 
    * @param o_error  
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_file
    (
        i_cda_req IN cda_req.id_cda_req%TYPE,
        o_file    OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ZIP FILE FOR REPORT REQUESTED ' || i_cda_req;
        SELECT cr.cda_report_file
          INTO o_file
          FROM cda_req cr
         WHERE cr.id_cda_req = i_cda_req
              /* REQUEST MUST BE READY FOR DOWNLOAD*/
           AND cr.flg_status = k_ready_status;
    
        o_file := pk_tech_utils.set_empty_blob(o_file);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CDA_REQ_FILE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cda_req_file;
    /********************************************************************************************
    * Cancel CDA requests
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION cancel_cda_req
    (
        i_lang       IN language.id_language%TYPE,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_status cda_req.flg_status%TYPE;
        l_curr_id_crh    cda_req_det.id_cda_req_det%TYPE := 0;
        l_ret            BOOLEAN;
        l_institution    institution.id_institution%TYPE;
    BEGIN
        g_error          := 'Get current status ' || i_id_cda_req;
        l_current_status := pk_backoffice_cda.get_cda_req_det_status(i_id_cda_req => i_id_cda_req);
    
        IF l_current_status NOT IN (k_finish_status, k_cancel_status)
        THEN
            g_error := 'Set status date ' || i_id_cda_req;
            ts_cda_req.upd(id_cda_req_in  => i_id_cda_req,
                           flg_status_nin => TRUE,
                           flg_status_in  => k_cancel_status,
                           dt_end_nin     => TRUE,
                           dt_end_in      => current_timestamp);
        
            g_error       := 'Get current cda request detory id ' || i_id_cda_req;
            l_curr_id_crh := get_current_cda_req_det(i_id_cda_req);
        
            g_error := 'Close cda request detory status ' || i_id_cda_req;
            ts_cda_req_det.upd(id_cda_req_det_in => l_curr_id_crh,
                               dt_status_end_nin => TRUE,
                               dt_status_end_in  => current_timestamp);
        
            g_error := 'Set New cda request detory Status ' || i_id_cda_req;
            l_ret   := set_next_cda_req_det(l_curr_id_crh, i_id_cda_req, k_cancel_status);
        END IF;
    
        IF l_current_status = k_ready_status
        THEN
            l_institution := get_cda_institution(i_id_cda_req);
            l_ret         := pk_alerts.delete_evt_gen_report(i_lang, i_id_cda_req, l_institution, o_error);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_CDA_REQ',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END cancel_cda_req;
    /** @headcom
    * Public Function. Get certification identifiers
    *
    * @param      I_LANG                   Identificação do Idioma
    * @param      i_id_institution         Identificador da instituição
    * @param      io_id_software           Lista de modulos de identificadores de software
    * @param      o_cert_id                Valor do identificador de certificação
    * @param      o_error                  tipificação de Erro
    *
    * @return     boolean
    * @author     RMGM
    * @version    2.6.4.0.2
    * @since      2014/05/19
    */
    FUNCTION get_cms_ehr_id
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        io_id_software   IN OUT table_number,
        o_cert_id        OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_cfg sys_config.id_sys_config%TYPE := 'CMS_EHR_CN';
        l_sw_temp  table_number := table_number();
        l_cms_temp sys_config.value%TYPE;
        l_idx      NUMBER := 1;
    BEGIN
        o_cert_id := table_varchar();
    
        FOR i IN 1 .. io_id_software.count
        LOOP
            g_error    := 'GET CERTIFICATION IDENTIFIER FOR MODULE ' || io_id_software(i);
            l_cms_temp := pk_sysconfig.get_config(l_code_cfg, profissional(0, i_id_institution, io_id_software(i)));
            IF l_cms_temp IS NOT NULL
            THEN
                o_cert_id.extend;
                l_sw_temp.extend;
                l_sw_temp(l_idx) := io_id_software(i);
                o_cert_id(l_idx) := l_cms_temp;
                l_idx := l_idx + 1;
            END IF;
            l_cms_temp := NULL;
        END LOOP;
        io_id_software := l_sw_temp;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CMS_EHR_ID',
                                              o_error);
            RETURN FALSE;
    END get_cms_ehr_id;
    /********************************************************************************************
    * Get CDA requests Detail or History
    *
    * @param i_lang                 Application current language
    * @param i_prof                 Professional Information array
    * @param i_id_cda_req           CDA request identified
    * @param i_screen_flg           Flg showing the screen request (H or D)
    * @param o_results              Cursor with returned information
    * @param o_error                Error information type
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/07/15
    * @version                       2.6.4.1
    ********************************************************************************************/
    FUNCTION get_cda_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        i_screen_flg IN VARCHAR2,
        o_results    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret       BOOLEAN;
        l_info_vals VARCHAR2(1 CHAR) := k_active;
        -- auxiliar types        
        l_cda_res     tbl_cda_req := tbl_cda_req();
        l_cda_req_res tbl_cda_req_det := tbl_cda_req_det();
        l_tab_hist    t_table_history_data := t_table_history_data();
    
        l_tbl_lables table_varchar := table_varchar();
        l_tbl_values table_varchar := table_varchar();
        l_tbl_types  table_varchar := table_varchar();
        -- data capture support vars      
        l_code_messages table_varchar2 := table_varchar2('ADMINISTRATOR_CDA_T002',
                                                         'ADMINISTRATOR_T375',
                                                         'ADMINISTRATOR_IDENT_T026',
                                                         'ADMINISTRATOR_CDA_T004',
                                                         'ADMINISTRATOR_CDA_T006',
                                                         'ADMINISTRATOR_T821',
                                                         'ADMINISTRATOR_T822',
                                                         'ADMINISTRATOR_CDA_T011',
                                                         'ADMINISTRATOR_CDA_T012');
        l_desc_messages table_varchar2 := table_varchar2();
    BEGIN
    
        IF i_screen_flg = 'D'
        THEN
            g_error   := 'GET CDA_REQ DATA FOR ID ' || i_id_cda_req;
            l_cda_res := get_cda_table(i_lang, i_prof, i_id_cda_req);
        
            g_error := 'LOOP RECORDS ' || l_cda_res.count;
            FOR i IN 1 .. l_cda_res.count
            LOOP
                g_error := 'GET_STRUCTURED VALUES FOR ' || l_cda_res(i).id_cda_req;
                IF NOT get_cda_current_val(i_lang, i_prof, l_cda_res(i), l_tbl_lables, l_tbl_values, l_tbl_types)
                THEN
                    RETURN FALSE;
                END IF;
                IF (l_cda_res(i).flg_status = k_cancel_status)
                   OR (i > 1)
                THEN
                    l_info_vals := k_cancel_status;
                ELSE
                    l_info_vals := k_active;
                END IF;
                g_error := 'ADD RECORD TO TABLE STRUCTURE TO RETURN ' || i_screen_flg;
                l_tab_hist.extend;
                l_tab_hist(i) := t_rec_history_data(id_rec          => l_cda_res(i).id_cda_req,
                                                    flg_status      => l_cda_res(i).flg_status,
                                                    date_rec        => l_cda_res(i).dt_start,
                                                    tbl_labels      => l_tbl_lables,
                                                    tbl_values      => l_tbl_values,
                                                    tbl_types       => l_tbl_types,
                                                    tbl_info_labels => table_varchar('RECORD_STATE_TO_FORMAT'),
                                                    tbl_info_values => table_varchar(l_info_vals),
                                                    table_origin    => 'CDA_REQ');
            END LOOP;
        ELSE
            -- get cda_req_hist info
            l_cda_req_res := get_cda_det_table(i_lang, i_prof, i_id_cda_req);
            FOR i IN 1 .. l_cda_req_res.count
            LOOP
                g_error := 'GET_STRUCTURED VALUES FOR ' || l_cda_req_res(i).id_cda_req;
                IF NOT get_cda_hist_val(i_lang, i_prof, l_cda_req_res(i), l_tbl_lables, l_tbl_values, l_tbl_types)
                THEN
                    RETURN FALSE;
                END IF;
                IF (l_cda_req_res(i).flg_status = k_cancel_status)
                   OR (i > 1)
                THEN
                    l_info_vals := k_cancel_status;
                ELSE
                    l_info_vals := k_active;
                END IF;
                g_error := 'ADD RECORD TO TABLE STRUCTURE TO RETURN ' || i_screen_flg;
                l_tab_hist.extend;
                l_tab_hist(i) := t_rec_history_data(id_rec          => l_cda_req_res(i).id_cda_req,
                                                    flg_status      => l_cda_req_res(i).flg_status,
                                                    date_rec        => l_cda_req_res(i).dt_status_start,
                                                    tbl_labels      => l_tbl_lables,
                                                    tbl_values      => l_tbl_values,
                                                    tbl_types       => l_tbl_types,
                                                    tbl_info_labels => table_varchar('RECORD_STATE_TO_FORMAT'),
                                                    tbl_info_values => table_varchar(l_info_vals),
                                                    table_origin    => 'CDA_REQ_DET');
            END LOOP;
        END IF;
    
        g_error := 'RETURN RECORDS IN ARRAY ' || l_tab_hist.count;
        OPEN o_results FOR
            SELECT t.id_rec,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels info_labels,
                   t.tbl_info_values info_values
              FROM TABLE(l_tab_hist) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CDA_REQ_DET_HIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_results);
            RETURN FALSE;
    END get_cda_det;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);
END;
/
