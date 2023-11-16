/*-- Last Change Revision: $Rev: 2027629 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_reports_medication_api IS
    ------------------------------ PRIVATE PACKAGE VARIABLES ---------------------------
    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(30);
    my_exception EXCEPTION;
    SUBTYPE debug_msg IS VARCHAR2(200);
    g_debug_enable BOOLEAN;

    /********************************************************************************************
    * Get prescription details
    * This function calls pk_medication_current.get_drug_details but ignores the unused cursors 
    * in order to optimize the response time.
    *
    * @param i_lang                     Language
    * @param i_prof                     Professional
    * @param i_id_patient               Patient
    * @param i_subject                  Prescription type
    * @param i_id_presc                 Prescription ID
    *
    * @param o_drug_detail              
    * @param o_drug_detail_hist         
    * @param o_drug_hold_detail         
    * @param o_drug_cancel_detail       
    * @param o_drug_report_detail       
    * @param o_drug_local_presc_detail  
    * @param o_drug_activate_detail     
    * @param o_drug_administer_detail   
    * @param o_drug_continued_detail    
    * @param o_drug_discontinued_detail 
    * @param o_drug_refills_detail      
    * @param o_drug_int_presc_detail    
    * @param o_drug_warnings_detail     
    * @param o_error                    Error message
    *
    * @return                            TRUE if success and FALSE otherwise
    *
    * @author                Tiago Lourenço
    * @version               v2.6.0.5
    * @since                 28-Jan-2011
    ********************************************************************************************/
    FUNCTION get_drug_details
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_patient                IN patient.id_patient%TYPE,
        i_subject                   IN VARCHAR2,
        i_id_presc                  IN NUMBER,
        i_flg_direction_config      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_drug_detail               OUT pk_types.cursor_type, --
        o_drug_detail_hist          OUT pk_types.cursor_type,
        o_drug_hold_detail          OUT pk_types.cursor_type,
        o_drug_cancel_detail        OUT pk_types.cursor_type,
        o_drug_report_detail        OUT pk_types.cursor_type,
        o_drug_local_presc_detail   OUT pk_types.cursor_type,
        o_drug_activate_detail      OUT pk_types.cursor_type,
        o_drug_administer_detail    OUT pk_types.cursor_type,
        o_drug_continued_detail     OUT pk_types.cursor_type,
        o_drug_discontinued_detail  OUT pk_types.cursor_type,
        o_drug_ext_presc_emb_detail OUT pk_types.cursor_type,
        o_drug_refills_detail       OUT pk_types.cursor_type,
        o_drug_int_presc_detail     OUT pk_types.cursor_type, --
        o_drug_warnings_detail      OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drug_ext_presc_qtd_detail pk_types.cursor_type;
    BEGIN
        g_error := 'pk_rt_med_pfh.get_drug_details_4report';
        pk_rt_med_pfh.get_drug_details_4report(i_lang                      => i_lang,
                                               i_prof                      => i_prof,
                                               i_id_patient                => i_id_patient,
                                               i_subject                   => i_subject,
                                               i_id_presc                  => i_id_presc,
                                               i_flg_direction_config      => i_flg_direction_config,
                                               o_drug_detail_hist          => o_drug_detail_hist,
                                               o_drug_hold_detail          => o_drug_hold_detail,
                                               o_drug_cancel_detail        => o_drug_cancel_detail,
                                               o_drug_report_detail        => o_drug_report_detail,
                                               o_drug_local_presc_detail   => o_drug_local_presc_detail,
                                               o_drug_activate_detail      => o_drug_activate_detail,
                                               o_drug_administer_detail    => o_drug_administer_detail,
                                               o_drug_continued_detail     => o_drug_continued_detail,
                                               o_drug_discontinued_detail  => o_drug_discontinued_detail,
                                               o_drug_ext_presc_emb_detail => o_drug_ext_presc_emb_detail,
                                               o_drug_ext_presc_qtd_detail => l_drug_ext_presc_qtd_detail,
                                               o_drug_refills_detail       => o_drug_refills_detail,
                                               o_drug_warnings_detail      => o_drug_warnings_detail);
    
        pk_types.open_my_cursor(o_drug_detail);
        pk_types.open_my_cursor(o_drug_int_presc_detail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DRUG_DETAILS',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_drug_details;

    /********************************************************************************************
    * pk_reports_medication_api.get_medication_reconciliation  
    *
    * @param        I_LANG                          IN          NUMBER(6)
    * @param        I_PROF                          IN          PROFISSIONAL
    * @param        I_ID_EPISODE                    IN          NUMBER(24)
    * @param        O_MED_RECONCILIATION            OUT         REF CURSOR
    * @param        O_LABEL_RECONCILIATION          OUT         VARCHAR2
    * @param        O_LABEL_LAST_UPDATE             OUT         VARCHAR2
    * @param        O_MSG_NO_RECONCILIATION         OUT         VARCHAR2
    * @param        O_ERROR                         OUT         T_ERROR_OUT
    *
    * @return   BOOLEAN
    *
    * @author   Rui Marante
    * @version      
    * @since        2011-09-29
    *
    * @notes        
    *
    * @ext_refs     --
    *
    * @status   
    *
    ********************************************************************************************/
    FUNCTION get_medication_reconciliation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        o_med_reconciliation    OUT pk_types.cursor_type,
        o_label_reconciliation  OUT VARCHAR2,
        o_label_last_update     OUT VARCHAR2,
        o_msg_no_reconciliation OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name user_procedures.procedure_name%TYPE := 'GET_MEDICATION_RECONCILIATION';
        --
        l_id_patient episode.id_patient%TYPE;
    BEGIN
        g_error                 := 'get labels';
        o_msg_no_reconciliation := pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M094');
        o_label_reconciliation  := pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M087');
        o_label_last_update     := pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M076');
    
        g_error := 'get visit from episode';
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'pk_rt_med_pfh.get_reconciliation_status';
        RETURN pk_rt_med_pfh.get_reconciliation_status(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_patient => l_id_patient,
                                                       i_id_episode => i_id_episode,
                                                       o_info       => o_med_reconciliation,
                                                       o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_db_object_name);
            RETURN FALSE;
    END get_medication_reconciliation;

    /********************************************************************************************
    * Get id of the report for a specific market, institution, software and type of prescription
    *
    * @param  i_lang                    Language
    * @param  i_prof                    Professional
    * @param  i_presc_type              Prescription type
    * @param  i_drug_type               Drug type
    * @param  i_id_product              Product (if applicable)
    * @param  i_id_product_supplier     Product supplier (if applicable)
    * @param  o_id_reports
    * @param  o_error                   Error message
    *
    * @return  Return TRUE if sucess, FALSE otherwise
    *
    * @author  Ricardo Pires
    * @version  v2.6.1.2
    * @since  2011-08-30
    *
    ********************************************************************************************/
    FUNCTION get_rep_prescription_match
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_task_type           IN table_number,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        o_id_reports          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market       market.id_market%TYPE;
        l_dbg_msg      debug_msg;
        l_cnt_tt       NUMBER;
        l_cnt_prd      NUMBER;
        l_cnt_prd_supp NUMBER;
        e_user_exception EXCEPTION;
    
        l_id_reports          table_number;
        l_id_product          table_varchar2;
        l_id_product_supplier table_varchar2;
        l_presc_type          table_varchar2;
        l_task_type           table_number;
    
    BEGIN
    
        l_cnt_tt       := i_task_type.count;
        l_cnt_prd      := i_id_product.count;
        l_cnt_prd_supp := i_id_product_supplier.count;
    
        l_dbg_msg := 'DELETE FROM tbl_temp';
        DELETE FROM tbl_temp;
    
        --TODO: check if the list of task_type, i_id_product and i_id_product_supplier are the same
        l_dbg_msg := 'check if cursors are equal';
        IF (l_cnt_prd = l_cnt_prd_supp AND l_cnt_tt = l_cnt_prd)
        THEN
        
            --get the prescription market
            l_dbg_msg := 'get market id';
            l_market  := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        
            FOR i IN 1 .. i_task_type.count
            LOOP
                BEGIN
                    SELECT rpm.id_reports,
                           rpm.presc_type,
                           nvl(rpm.id_task_type, i_task_type(i)),
                           nvl(rpm.id_product, i_id_product(i)),
                           nvl(rpm.id_product_supplier, i_id_product_supplier(i))
                      BULK COLLECT
                      INTO l_id_reports, l_presc_type, l_task_type, l_id_product, l_id_product_supplier
                      FROM rep_prescription_match rpm
                     WHERE rpm.id_market = decode((SELECT DISTINCT 1
                                                    FROM rep_prescription_match rpm2
                                                   WHERE rpm2.id_institution IN (i_prof.institution, 0)
                                                     AND rpm2.id_software IN (i_prof.software, 0)
                                                     AND rpm2.id_market = l_market
                                                     AND rpm2.id_task_type = i_task_type(i)),
                                                  1,
                                                  l_market,
                                                  0)
                       AND rpm.id_software = decode((SELECT DISTINCT 1
                                                      FROM rep_prescription_match rpm2
                                                     WHERE rpm2.id_institution IN (i_prof.institution, 0)
                                                       AND rpm2.id_software = i_prof.software
                                                       AND rpm2.id_market IN (l_market, 0)
                                                       AND rpm2.id_task_type = i_task_type(i)),
                                                    1,
                                                    i_prof.software,
                                                    0)
                       AND rpm.id_institution = decode((SELECT DISTINCT 1
                                                         FROM rep_prescription_match rpm2
                                                        WHERE rpm2.id_institution = i_prof.institution
                                                          AND rpm2.id_software IN (i_prof.software, 0)
                                                          AND rpm2.id_market IN (l_market, 0)
                                                          AND rpm2.id_task_type = i_task_type(i)),
                                                       1,
                                                       i_prof.institution,
                                                       0)
                       AND ((rpm.id_task_type IS NULL) OR (rpm.id_task_type = i_task_type(i)))
                       AND ((rpm.id_product IS NULL) OR (rpm.id_product = i_id_product(i)))
                       AND ((rpm.id_product_supplier IS NULL) OR (rpm.id_product_supplier = i_id_product_supplier(i)));
                
                    IF (l_id_reports.count > 0)
                    THEN
                        FORALL i IN 1 .. l_id_reports.count
                            INSERT INTO tbl_temp
                                (num_1, vc_1, vc_2, vc_3, vc_4)
                            VALUES
                                (l_id_reports(i),
                                 l_presc_type(i),
                                 l_task_type(i),
                                 l_id_product(i),
                                 l_id_product_supplier(i));
                    ELSE
                        o_id_reports := NULL;
                        RETURN TRUE;
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_reports          := NULL;
                        l_presc_type          := NULL;
                        l_task_type           := NULL;
                        l_id_product          := NULL;
                        l_id_product_supplier := NULL;
                END;
            
            END LOOP;
        
            --fill o_id_reports
            l_dbg_msg := 'get market id';
            OPEN o_id_reports FOR
                SELECT num_1 id_reports, vc_1 presc_type, vc_2 task_type, vc_3 id_product, vc_4 id_product_supplier
                  FROM tbl_temp;
        
        ELSE
            RAISE e_user_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_REPORTS_MEDICATION_API',
                                              'GET_REP_PRESCRIPTION_MATCH',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END get_rep_prescription_match;

    /********************************************************************************************
    * Invokation of pk_medication_current.get_current_medication_int
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_hm_review
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_review     OUT pk_types.cursor_type,
        o_review_pnt OUT pk_types.cursor_type,
        o_review_is  OUT pk_types.cursor_type,
        o_review_pt  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_HM_REVIEW';
        l_message debug_msg;
    
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_hm_review(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_episode => i_id_episode,
                                           o_review     => o_review,
                                           o_review_pnt => o_review_pnt,
                                           o_review_is  => o_review_is,
                                           o_review_pt  => o_review_pt,
                                           o_error      => o_error)
        
        THEN
            RAISE my_exception;
        END IF;
    
        pk_types.open_cursor_if_closed(o_review);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CURRENT_MEDICATION_INT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_hm_review;

    /********************************************************************************************
    * Update table presc_duplicate_report with information
    * relating prescription and duplicata of id_epis_report 
    *
    * @author Pedro Teixeira
    * @since  12/12/2013
    *
    ********************************************************************************************/
    FUNCTION set_presc_duplicate_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN table_number,
        id_epis_report IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_PRESC_DUPLICATE_REPORT';
    
    BEGIN
        RETURN pk_rt_med_pfh.set_presc_duplicate_report(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_presc     => i_id_presc,
                                                        id_epis_report => id_epis_report,
                                                        o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END set_presc_duplicate_report;

    /********************************************************************************************
    * Get the prescription type for a report (N- Normal, D- Duplicata, V2- two copies, ...)
    *
    * @author Ricardo Pires
    * @since  21/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_report_presc_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_reports      IN reports.id_reports%TYPE,
        i_id_reports_list IN table_number,
        i_presc_type      IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_presc_type VARCHAR2(32000 CHAR);
    BEGIN
        l_id_presc_type := '';
    
        FOR i IN 1 .. i_id_reports_list.count
        LOOP
            IF i_id_reports_list(i) = i_id_reports
            THEN
                l_id_presc_type := i_presc_type(i);
            END IF;
        END LOOP;
    
        pk_alertlog.log_info('pk_reports_medication_api.get_report_presc_type.l_id_presc_type:' || l_id_presc_type);
    
        RETURN l_id_presc_type;
    END get_report_presc_type;

    /********************************************************************************************
    * Get the id_task_type for a report
    *
    * @author Ricardo Pires
    * @since  21/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_report_task_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_reports      IN reports.id_reports%TYPE,
        i_id_reports_list IN table_number,
        i_task_type       IN table_number
    ) RETURN VARCHAR2 IS
        l_id_task_type VARCHAR2(32000 CHAR);
    BEGIN
        l_id_task_type := '';
    
        FOR i IN 1 .. i_id_reports_list.count
        LOOP
            IF i_id_reports_list(i) = i_id_reports
            THEN
                IF l_id_task_type IS NULL
                THEN
                    l_id_task_type := i_task_type(i);
                ELSE
                    l_id_task_type := l_id_task_type || '|' || i_task_type(i);
                END IF;
            END IF;
        END LOOP;
    
        pk_alertlog.log_info('pk_reports_medication_api.get_report_task_type.l_id_task_type:' || l_id_task_type);
    
        RETURN l_id_task_type;
    END get_report_task_type;

    /********************************************************************************************
    * Gets the external prescription directions
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_episode        Episode ID
    * @param  i_id_visit          Visit ID
    * @param  i_id_patient        Patient ID
    * @param  o_local_presc_dirs  Cursor with data
    * @param  o_error             Error object
    *
    * @return true/false
    *
    * @author Tiago Pereira
    * @since  12/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_list_ext_presc_dirs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN episode.id_visit%TYPE,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_presc   IN presc.id_presc%TYPE,
        o_presc_dirs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_api_pfh_in.get_list_ext_presc_dirs(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_episode => i_id_episode,
                                                     i_id_visit   => i_id_visit,
                                                     i_id_patient => i_id_patient,
                                                     i_id_presc   => i_id_presc,
                                                     o_presc_dirs => o_presc_dirs,
                                                     o_error      => o_error);
    
    END get_list_ext_presc_dirs;

    /********************************************************************************************
    * Invokation of pk_rt_med_pfh.get_med_reconciliation_info
    
    * @author                                  Sofia Mendes
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_med_reconciliation_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN presc.id_patient%TYPE,
        o_new_presc        OUT pk_types.cursor_type,
        o_stopped_presc    OUT pk_types.cursor_type,
        o_changes_home_med OUT pk_types.cursor_type,
        o_home_med         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_rt_med_pfh.get_med_reconciliation_info(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_visit         => i_id_visit,
                                                         i_id_episode       => i_id_episode,
                                                         i_id_patient       => i_id_patient,
                                                         o_new_presc        => o_new_presc,
                                                         o_stopped_presc    => o_stopped_presc,
                                                         o_changes_home_med => o_changes_home_med,
                                                         o_home_med         => o_home_med,
                                                         o_error            => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_cursor_if_closed(o_new_presc);
            pk_types.open_cursor_if_closed(o_stopped_presc);
            pk_types.open_cursor_if_closed(o_changes_home_med);
            pk_types.open_cursor_if_closed(o_home_med);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_new_presc);
            pk_types.open_cursor_if_closed(o_stopped_presc);
            pk_types.open_cursor_if_closed(o_changes_home_med);
            pk_types.open_cursor_if_closed(o_home_med);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MED_RECONCILIATION_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_med_reconciliation_info;

    FUNCTION get_epis_reports_presc
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_report_duplicate IN NUMBER,
        o_id_presc                 OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_epis_reports_presc(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_epis_report_duplicate => i_id_epis_report_duplicate,
                                                    o_id_presc                 => o_id_presc,
                                                    o_error                    => o_error);
    END get_epis_reports_presc;

    FUNCTION get_presc_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_id_visit   IN NUMBER,
        i_id_episode IN NUMBER,
        i_id_presc   IN table_number,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_info(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_patient => i_id_patient,
                                            i_id_visit   => i_id_visit,
                                            i_id_episode => i_id_episode,
                                            i_id_presc   => i_id_presc,
                                            o_info       => o_info,
                                            o_error      => o_error);
    END get_presc_info;

    FUNCTION get_presc_print_report
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_presc          IN table_number,
        o_info              OUT pk_types.cursor_type,
        o_prof_data         OUT pk_types.cursor_type,
        o_presc_diags_tasks OUT pk_types.cursor_type,
        o_version           OUT VARCHAR2,
        o_service_info      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_PRINT_REPORT';
    BEGIN
        g_error := 'Get service info';
        OPEN o_service_info FOR
            SELECT dcs.id_department,
                   d.phone_number,
                   pk_translation.get_translation(i_lang, d.code_department) service_name,
                   pk_translation.get_translation(i_lang, dpt.code_dept) department_name
              FROM epis_info ei
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
              JOIN department d
                ON d.id_department = dcs.id_department
              JOIN dept dpt
                ON dpt.id_dept = d.id_dept
             WHERE ei.id_episode = i_id_episode;
    
        g_error := 'Call pk_rt_med_pfh.get_presc_print_report';
        IF NOT pk_rt_med_pfh.get_presc_print_report(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_patient        => i_id_patient,
                                                    i_id_episode        => i_id_episode,
                                                    i_id_presc          => i_id_presc,
                                                    o_info              => o_info,
                                                    o_prof_data         => o_prof_data,
                                                    o_presc_diags_tasks => o_presc_diags_tasks,
                                                    o_version           => o_version,
                                                    o_error             => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_cursor_if_closed(o_service_info);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_prof_data);
            pk_types.open_cursor_if_closed(o_presc_diags_tasks);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_service_info);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_prof_data);
            pk_types.open_cursor_if_closed(o_presc_diags_tasks);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_presc_print_report;

    /********************************************************************************************
    * Gets the prescription information regarding the narcotic and controlled drug medications 
     *
     * @param  i_lang                        The language ID
     * @param  i_prof                        The professional array
     * @param  i_id_presc                    Prescription Ids
     
     * @param  o_info                        Output cursor with medication description, dosage, frequency
     *
     * @author   Sofia Mendes
     * @since    2018-08-30
     ********************************************************************************************/
    FUNCTION get_presc_narcotic_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN table_number,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_narcotic_info(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_id_presc => i_id_presc,
                                                     o_info     => o_info,
                                                     o_error    => o_error);
    END get_presc_narcotic_info;

    /********************************************************************************************
    * Gets the prescription information regarding the Medication, Narrative and Patient instruction (EN/ARABIC)
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  i_id_presc                    Prescription Ids
    
    * @param  o_info                        Output cursor with medication description, Narrative and Patient instruction (EN/ARABIC)
    *
    * @author   Adriana Ramos
    * @since    2018-09-05
    ********************************************************************************************/
    FUNCTION get_presc_med_narrative_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN table_number,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_med_narrative_info(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_id_presc => i_id_presc,
                                                          o_info     => o_info,
                                                          o_error    => o_error);
    END get_presc_med_narrative_info;

    FUNCTION get_treatment_guide_presc_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_presc    IN table_number,
        i_print_type  IN VARCHAR2,
        o_presc       OUT pk_types.cursor_type,
        o_institution OUT pk_types.cursor_type,
        o_patient     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_TREATMENT_GUIDE_PRESC_DATA';
        l_id_ext_local_presc_syscfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'ID_EXTERNAL_SYS_LOCAL_PRESCRICAO',
                                                                                     i_prof_inst => i_prof.institution,
                                                                                     i_prof_soft => i_prof.software);
    
        l_prescriptions_ars_syscfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'PRESCRIPTION_ARS',
                                                                                    i_prof    => i_prof);
        l_sns                      pat_health_plan.num_health_plan%TYPE; --Numero SNS
        l_num_health_plan          pat_health_plan.num_health_plan%TYPE; --Numero sns/seguro saude/etc
        l_id_health_plan           pat_health_plan.id_health_plan%TYPE;
        l_pat_name                 patient.name%TYPE; --Nome paciente
        l_pat_dt_birth             VARCHAR2(200); --Data de nascimento
        l_pat_gender               patient.gender%TYPE; --Género
        l_pat_gender_desc          VARCHAR2(200);
        l_pat_birth_place          country.alpha2_code%TYPE; --Nacionalidade
        l_hp_entity                VARCHAR2(4000);
        l_flg_migrator             pat_soc_attributes.flg_migrator%TYPE;
        l_flg_occ_disease          VARCHAR2(1);
        l_flg_independent          VARCHAR2(1);
        l_dt_deceased              VARCHAR2(4000);
        l_hp_alpha2_code           VARCHAR2(4000);
        l_hp_national_ident_nbr    VARCHAR2(4000);
        l_hp_dt_effective          VARCHAR2(200);
        l_valid_sns                VARCHAR2(1);
        l_flg_recm                 VARCHAR2(2);
        l_main_phone               VARCHAR2(200);
        l_hp_country_desc          VARCHAR2(200);
        l_num_order                professional.num_order%TYPE;
        l_valid_hp                 VARCHAR2(1);
        l_flg_type_hp              health_plan.flg_type%TYPE;
        l_hp_id_content            health_plan.id_content%TYPE;
        l_hp_inst_ident_nbr        pat_health_plan.inst_identifier_number%TYPE;
        l_hp_inst_ident_desc       pat_health_plan.inst_identifier_desc%TYPE;
        l_hp_dt_valid              VARCHAR(200);
    
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_treatment_guide_presc_data';
        IF NOT pk_rt_med_pfh.get_treatment_guide_presc_data(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_presc   => i_id_presc,
                                                            i_print_type => i_print_type,
                                                            o_info       => o_presc,
                                                            o_error      => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'CALL pk_adt.get_pat_info: id_patient = ' || i_id_patient || '|id_episode = ' || i_id_episode;
        IF NOT pk_adt.get_pat_info(i_lang                    => i_lang,
                                   i_id_patient              => i_id_patient,
                                   i_prof                    => i_prof,
                                   i_id_episode              => i_id_episode,
                                   i_id_presc                => i_id_presc,
                                   i_flg_info_for_medication => pk_alert_constant.g_yes,
                                   o_name                    => l_pat_name,
                                   o_gender                  => l_pat_gender,
                                   o_desc_gender             => l_pat_gender_desc,
                                   o_dt_birth                => l_pat_dt_birth,
                                   o_dt_deceased             => l_dt_deceased,
                                   o_flg_migrator            => l_flg_migrator,
                                   o_id_country_nation       => l_pat_birth_place,
                                   o_sns                     => l_sns,
                                   o_valid_sns               => l_valid_sns,
                                   o_flg_occ_disease         => l_flg_occ_disease,
                                   o_flg_independent         => l_flg_independent,
                                   o_num_health_plan         => l_num_health_plan,
                                   o_hp_entity               => l_hp_entity,
                                   o_id_health_plan          => l_id_health_plan,
                                   o_flg_recm                => l_flg_recm,
                                   o_main_phone              => l_main_phone,
                                   o_hp_alpha2_code          => l_hp_alpha2_code,
                                   o_hp_country_desc         => l_hp_country_desc,
                                   o_hp_national_ident_nbr   => l_hp_national_ident_nbr,
                                   o_hp_dt_effective         => l_hp_dt_effective,
                                   o_valid_hp                => l_valid_hp,
                                   o_flg_type_hp             => l_flg_type_hp,
                                   o_hp_id_content           => l_hp_id_content,
                                   o_hp_inst_ident_nbr       => l_hp_inst_ident_nbr,
                                   o_hp_inst_ident_desc      => l_hp_inst_ident_desc,
                                   o_hp_dt_valid             => l_hp_dt_valid,
                                   o_error                   => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN o_institution';
        OPEN o_institution FOR
            SELECT ies.id_institution,
                   pk_utils.get_institution_name(i_lang => i_lang, i_id_institution => ies.id_institution) inst,
                   ies.value,
                   i.ine_location user_local,
                   l_prescriptions_ars_syscfg ars_code
              FROM instit_ext_sys ies
              JOIN institution i
                ON i.id_institution = ies.id_institution
             WHERE ies.id_external_sys = l_id_ext_local_presc_syscfg
               AND ies.id_institution = i_prof.institution
               AND rownum = 1;
    
        IF NOT pk_prof_utils.get_num_order(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_prof_id   => i_prof.id,
                                           o_num_order => l_num_order,
                                           o_error     => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'OPEN o_patient';
        OPEN o_patient FOR
            SELECT i_prof.id               id_professional,
                   l_num_order             num_order,
                   l_pat_name              name,
                   l_pat_gender            gender,
                   l_pat_gender_desc       gender_desc,
                   l_pat_dt_birth          dt_bith,
                   l_dt_deceased           dt_deceased,
                   l_flg_migrator          flg_migrator,
                   l_pat_birth_place       id_country_nation,
                   l_sns                   sns,
                   l_valid_sns             valid_sns,
                   l_flg_occ_disease       flg_occ_disease,
                   l_flg_independent       flg_independent,
                   l_num_health_plan       num_health_plan,
                   l_hp_entity             hp_entity,
                   l_id_health_plan        id_health_plan,
                   l_flg_recm              flg_recm,
                   l_main_phone            main_phone,
                   l_hp_alpha2_code        hp_alpha2_code,
                   l_hp_country_desc       hp_country_desc,
                   l_hp_national_ident_nbr hp_national_ident_nbr,
                   l_hp_dt_effective       hp_dt_effective,
                   l_valid_hp              valid_hp,
                   l_flg_type_hp           flg_type_hp,
                   l_hp_id_content         hp_id_content,
                   l_hp_inst_ident_nbr     hp_inst_ident_nbr,
                   l_hp_inst_ident_desc    hp_inst_ident_desc,
                   l_hp_dt_valid           hp_dt_valid
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_cursor_if_closed(o_presc);
            pk_types.open_cursor_if_closed(o_institution);
            pk_types.open_cursor_if_closed(o_patient);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_presc);
            pk_types.open_cursor_if_closed(o_institution);
            pk_types.open_cursor_if_closed(o_patient);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_treatment_guide_presc_data;

    FUNCTION generatecheckdigit
    (
        i_lang       IN language.id_language%TYPE,
        i_nr_receipt IN VARCHAR2,
        o_checkdigit OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        i         NUMBER := 0;
        digit     NUMBER := 0;
        total     NUMBER := 0;
        remainder NUMBER := 0;
        l_result  NUMBER := 0;
    BEGIN
    
        WHILE (i < length(i_nr_receipt))
        LOOP
            digit := to_number(substr(i_nr_receipt, i, 1));
            total := (total + digit) * 2;
            i     := i + 1;
        END LOOP;
    
        remainder := MOD(total, 11);
        l_result  := MOD((12 - remainder), 11);
    
        IF l_result = 10
        THEN
            o_checkdigit := 'X';
        ELSE
            o_checkdigit := to_char(l_result);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GENERATE_BARCODE_CHECKDIGIT',
                                                     o_error);
    END generatecheckdigit;

    FUNCTION ins_presc_xml
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_print_type             IN VARCHAR2,
        i_id_presc               IN table_number,
        i_local_prescricao       IN VARCHAR2,
        i_prescritor             IN VARCHAR2,
        i_receita_renovavel      IN NUMBER,
        i_recm                   IN VARCHAR2,
        i_sexo_utente            IN VARCHAR2,
        i_data_nascimento_utente IN VARCHAR2,
        i_localidade_utente      IN VARCHAR2,
        i_num_beneficiario       IN VARCHAR2,
        i_numero_vias            IN NUMBER,
        i_ent_resp               IN VARCHAR2,
        i_numero_registo         IN table_varchar,
        i_quantidade             IN table_number,
        i_descricao              IN table_varchar,
        i_numero_despacho        IN table_number,
        i_autorizacao_genericos  IN table_number,
        i_posologia              IN table_varchar,
        i_line_num               IN table_number,
        i_cn_pem                 IN table_varchar,
        i_id_inn                 IN table_varchar,
        i_id_pharm_form          IN table_varchar,
        i_emb_desc               IN table_varchar,
        i_dosage                 IN table_varchar,
        i_regulation_desc        IN table_varchar,
        i_line_type              IN table_varchar,
        i_duration_value         IN table_number,
        i_duration_unit          IN table_varchar,
        i_id_presc_xml_group     IN NUMBER,
        i_id_pesc_group          IN NUMBER,
        i_flg_cancel             IN VARCHAR2,
        i_id_reports             IN NUMBER,
        i_dt_writes              IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_presc_xml           OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'INS_PRESC_XML';
        -- sys_configs
        l_prescriptions_ars_syscfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'PRESCRIPTION_ARS',
                                                                                    i_prof    => i_prof);
    
        l_id_presc_xml       NUMBER;
        l_lst_id_presc_group table_number := table_number();
    BEGIN
        g_error := 'INIT ins_presc_xml: id_patient = ' || i_id_patient || '|id_episode = ' || i_id_episode ||
                   '|print_type = ' || i_print_type || '|i_id_reports = ' || i_id_reports;
        pk_alertlog.log_debug(g_error);
    
        o_id_presc_xml := table_number();
        IF (i_id_pesc_group IS NOT NULL AND i_flg_cancel = 'Y')
        THEN
            l_lst_id_presc_group := table_number(i_id_pesc_group);
        ELSE
            g_error := 'Call pk_rt_med_pfh.set_treatment_guide_presc';
            IF NOT pk_rt_med_pfh.set_treatment_guide_presc(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_patient     => i_id_patient,
                                                           i_id_episode     => i_id_episode,
                                                           i_id_presc       => i_id_presc,
                                                           i_print_type     => i_print_type,
                                                           i_numero_vias    => i_numero_vias,
                                                           i_id_reports     => i_id_reports,
                                                           i_dt_writes      => i_dt_writes,
                                                           o_id_presc_group => l_lst_id_presc_group,
                                                           o_error          => o_error)
            THEN
                RAISE my_exception;
            END IF;
        END IF;
    
        FOR i IN 1 .. l_lst_id_presc_group.count
        LOOP
            g_error := 'Call pk_rt_med_pfh.ins_presc_xml: id_presc_group = ' || l_lst_id_presc_group(i);
            IF NOT pk_rt_med_pfh.ins_presc_xml(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               i_id_presc_group         => l_lst_id_presc_group(i),
                                               i_id_presc               => i_id_presc,
                                               i_local_prescricao       => i_local_prescricao,
                                               i_prescritor             => i_prescritor,
                                               i_receita_renovavel      => i_receita_renovavel,
                                               i_recm                   => i_recm,
                                               i_sexo_utente            => i_sexo_utente,
                                               i_data_nascimento_utente => i_data_nascimento_utente,
                                               i_localidade_utente      => i_localidade_utente,
                                               i_num_beneficiario       => i_num_beneficiario,
                                               i_numero_vias            => i_numero_vias,
                                               i_ent_resp               => i_ent_resp,
                                               i_id_ars                 => l_prescriptions_ars_syscfg,
                                               i_origem                 => NULL, --deprecated
                                               i_numero_registo         => i_numero_registo,
                                               i_quantidade             => i_quantidade,
                                               i_descricao              => i_descricao,
                                               i_numero_despacho        => i_numero_despacho,
                                               i_autorizacao_genericos  => i_autorizacao_genericos,
                                               i_posologia              => i_posologia,
                                               i_line_num               => i_line_num,
                                               i_cn_pem                 => i_cn_pem,
                                               i_id_inn                 => i_id_inn,
                                               i_id_pharm_form          => i_id_pharm_form,
                                               i_emb_desc               => i_emb_desc,
                                               i_dosage                 => i_dosage,
                                               i_regulation_desc        => i_regulation_desc,
                                               i_line_type              => i_line_type,
                                               i_duration_value         => i_duration_value,
                                               i_duration_unit          => i_duration_unit,
                                               i_id_presc_xml_group     => i_id_presc_xml_group,
                                               o_id_presc_xml           => l_id_presc_xml,
                                               o_error                  => o_error)
            THEN
                RAISE my_exception;
            END IF;
            o_id_presc_xml.extend;
            o_id_presc_xml(o_id_presc_xml.last) := l_id_presc_xml;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            ROLLBACK;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END ins_presc_xml;

    FUNCTION ins_presc_xml_group
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_print_type             IN table_varchar,
        i_id_presc               IN table_table_number,
        i_local_prescricao       IN table_varchar,
        i_prescritor             IN table_varchar,
        i_receita_renovavel      IN table_number,
        i_recm                   IN table_varchar,
        i_sexo_utente            IN table_varchar,
        i_data_nascimento_utente IN table_varchar,
        i_localidade_utente      IN table_varchar,
        i_num_beneficiario       IN table_varchar,
        i_numero_vias            IN table_number,
        i_ent_resp               IN table_varchar,
        i_numero_registo         IN table_table_varchar,
        i_quantidade             IN table_table_number,
        i_descricao              IN table_table_varchar,
        i_numero_despacho        IN table_table_number,
        i_autorizacao_genericos  IN table_table_number,
        i_posologia              IN table_table_varchar,
        i_line_num               IN table_table_number,
        i_cn_pem                 IN table_table_varchar,
        i_id_inn                 IN table_table_varchar,
        i_id_pharm_form          IN table_table_varchar,
        i_emb_desc               IN table_table_varchar,
        i_dosage                 IN table_table_varchar,
        i_regulation_desc        IN table_table_varchar,
        i_line_type              IN table_table_varchar,
        i_duration_value         IN table_table_number,
        i_duration_unit          IN table_table_varchar,
        i_id_pesc_group          IN table_number,
        i_id_reports             IN NUMBER,
        i_flg_cancel             IN VARCHAR2,
        o_id_presc_xml           OUT table_number,
        o_id_presc_xml_group     OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'INS_PRESC_XML_GROUP';
        l_count_recipes PLS_INTEGER;
    
        l_id_presc_xml       table_number;
        l_list_presc_xml     table_number := table_number();
        l_id_presc_xml_group NUMBER;
        l_timestamp          TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
        IF (cardinality(i_print_type) > 0)
        THEN
            g_error         := 'Count nr prescs';
            l_count_recipes := i_print_type.count;
        
            /*IF i_print_type.count > 0
            THEN*/
            g_error := 'Call pk_rt_med_pfh.ins_presc_xml_group';
            IF NOT pk_rt_med_pfh.ins_presc_xml_group(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_flg_type           => i_print_type(1),
                                                     i_id_reports         => i_id_reports,
                                                     o_id_presc_xml_group => l_id_presc_xml_group,
                                                     o_error              => o_error)
            THEN
                RAISE my_exception;
            END IF;
            --END IF;
        
            IF (g_debug_enable)
            THEN
                g_error := 'l_count_recipes: ' || l_count_recipes || ' i_id_reports: ' || i_id_reports ||
                           ' i_flg_cancel: ' || i_flg_cancel;
                pk_alertlog.log_debug(g_error);
            END IF;
        
            FOR i IN 1 .. l_count_recipes
            LOOP
                g_error := 'INS_PRESC_XML i: ' || i;
                IF (g_debug_enable)
                THEN
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_print_type(i): ' || i_print_type(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_id_presc(i): ' || pk_utils.to_string(i_id_presc(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_local_prescricao(i): ' || i_local_prescricao(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_prescritor(i): ' || i_prescritor(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_receita_renovavel(i): ' || i_receita_renovavel(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_recm(i): ' || i_recm(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_sexo_utente(i): ' || i_sexo_utente(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_data_nascimento_utente(i): ' || i_data_nascimento_utente(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_localidade_utente(i): ' || i_localidade_utente(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_num_beneficiario(i): ' || i_num_beneficiario(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_numero_vias(i): ' || i_numero_vias(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_ent_resp(i): ' || i_ent_resp(i);
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_numero_registo(i): ' || pk_utils.to_string(i_numero_registo(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_quantidade(i): ' || pk_utils.to_string(i_quantidade(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_descricao(i): ' || pk_utils.to_string(i_descricao(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_numero_despacho(i): ' || pk_utils.to_string(i_numero_despacho(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_autorizacao_genericos(i): ' || pk_utils.to_string(i_autorizacao_genericos(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_posologia(i): ' || pk_utils.to_string(i_posologia(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_line_num(i): ' || pk_utils.to_string(i_line_num(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_cn_pem(i): ' || pk_utils.to_string(i_cn_pem(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_id_inn(i): ' || pk_utils.to_string(i_id_inn(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_id_pharm_form(i): ' || pk_utils.to_string(i_id_pharm_form(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_emb_desc(i): ' || pk_utils.to_string(i_emb_desc(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_dosage(i): ' || pk_utils.to_string(i_dosage(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_regulation_desc(i): ' || pk_utils.to_string(i_regulation_desc(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_line_type(i): ' || pk_utils.to_string(i_line_type(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_duration_value(i): ' || pk_utils.to_string(i_duration_value(i));
                    pk_alertlog.log_debug(g_error);
                    g_error := 'i_duration_unit(i): ' || pk_utils.to_string(i_duration_unit(i));
                    pk_alertlog.log_debug(g_error);
                
                    IF (i_id_pesc_group.exists(i) AND i_id_pesc_group IS NOT NULL)
                    THEN
                        g_error := 'i_id_pesc_group(i): ' || i_id_pesc_group(i);
                        pk_alertlog.log_debug(g_error);
                    ELSE
                        pk_alertlog.log_debug('THERE IS NO ID_PRESC_GROUP');
                    END IF;
                END IF;
            
                IF NOT ins_presc_xml(i_lang                   => i_lang,
                                i_prof                   => i_prof,
                                i_id_patient             => i_id_patient,
                                i_id_episode             => i_id_episode,
                                i_print_type             => i_print_type(i),
                                i_id_presc               => i_id_presc(i),
                                i_local_prescricao       => i_local_prescricao(i),
                                i_prescritor             => i_prescritor(i),
                                i_receita_renovavel      => i_receita_renovavel(i),
                                i_recm                   => i_recm(i),
                                i_sexo_utente            => i_sexo_utente(i),
                                i_data_nascimento_utente => i_data_nascimento_utente(i),
                                i_localidade_utente      => i_localidade_utente(i),
                                i_num_beneficiario       => i_num_beneficiario(i),
                                i_numero_vias            => i_numero_vias(i),
                                i_ent_resp               => i_ent_resp(i),
                                i_numero_registo         => i_numero_registo(i),
                                i_quantidade             => i_quantidade(i),
                                i_descricao              => i_descricao(i),
                                i_numero_despacho        => i_numero_despacho(i),
                                i_autorizacao_genericos  => i_autorizacao_genericos(i),
                                i_posologia              => i_posologia(i),
                                i_line_num               => i_line_num(i),
                                i_cn_pem                 => i_cn_pem(i),
                                i_id_inn                 => i_id_inn(i),
                                i_id_pharm_form          => i_id_pharm_form(i),
                                i_emb_desc               => i_emb_desc(i),
                                i_dosage                 => i_dosage(i),
                                i_regulation_desc        => i_regulation_desc(i),
                                i_line_type              => i_line_type(i),
                                i_duration_value         => i_duration_value(i),
                                i_duration_unit          => i_duration_unit(i),
                                i_id_presc_xml_group     => l_id_presc_xml_group,
                                i_id_pesc_group          => CASE
                                                                WHEN i_id_pesc_group.exists(i) THEN
                                                                 i_id_pesc_group(i)
                                                                ELSE
                                                                 NULL
                                                            END,
                                i_flg_cancel             => i_flg_cancel,
                                i_id_reports             => i_id_reports,
                                i_dt_writes              => l_timestamp,
                                o_id_presc_xml           => l_id_presc_xml,
                                o_error                  => o_error)
                THEN
                    RAISE my_exception;
                END IF;
                l_list_presc_xml := l_list_presc_xml MULTISET UNION l_id_presc_xml;
            END LOOP;
        END IF;
    
        o_id_presc_xml       := l_list_presc_xml;
        o_id_presc_xml_group := l_id_presc_xml_group;
    
        IF (g_debug_enable)
        THEN
            pk_alertlog.log_debug('l_id_presc_xml_group: ' || l_id_presc_xml_group);
        
            FOR i IN 1 .. o_id_presc_xml.count
            LOOP
                pk_alertlog.log_debug('o_id_presc_xml: ' || o_id_presc_xml(i));
            END LOOP;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            ROLLBACK;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END ins_presc_xml_group;

    FUNCTION upd_presc_xml
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_presc_xml      IN NUMBER,
        i_nr_receipt        IN VARCHAR2 DEFAULT NULL,
        i_error_msg         IN VARCHAR2 DEFAULT NULL,
        i_flg_xml           IN VARCHAR2 DEFAULT NULL,
        i_xml_request       IN CLOB DEFAULT NULL,
        i_xml_response      IN CLOB DEFAULT NULL,
        i_flg_print         IN VARCHAR2,
        i_contact           IN VARCHAR2,
        i_email             IN VARCHAR2,
        o_id_presc_xml_goup OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'UPD_PRESC_XML';
    BEGIN
        g_error := 'UPD_PRESC_XML';
        IF (g_debug_enable)
        THEN
            pk_alertlog.log_debug('UPD_PRESC_XML: i_id_presc_xml: ' || i_id_presc_xml || ' i_xml_request: ' ||
                                  i_xml_request);
        
            pk_alertlog.log_debug('UPD_PRESC_XML: i_id_presc_xml: ' || i_id_presc_xml || ' i_xml_request: ' ||
                                  i_xml_request);
            pk_alertlog.log_debug('UPD_PRESC_XML: i_nr_receipt: ' || i_nr_receipt);
            pk_alertlog.log_debug('UPD_PRESC_XML: i_contact: ' || i_contact || ' i_email: ' || i_email ||
                                  ' i_flg_print: ' || i_flg_print);
        
        END IF;
        IF NOT pk_rt_med_pfh.upd_presc_xml(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_presc_xml      => i_id_presc_xml,
                                           i_nr_receipt        => i_nr_receipt,
                                           i_error_msg         => i_error_msg,
                                           i_flg_xml           => i_flg_xml,
                                           i_xml_request       => i_xml_request,
                                           i_xml_response      => i_xml_response,
                                           i_flg_print         => i_flg_print,
                                           i_contact           => i_contact,
                                           i_email             => i_email,
                                           o_id_presc_xml_goup => o_id_presc_xml_goup,
                                           o_error             => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            ROLLBACK;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END upd_presc_xml;

    FUNCTION get_rx_prescr_data_aditional
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN alert.profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_presc_xml IN NUMBER,
        o_presc        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_rx_prescr_data_aditional(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_episode   => i_id_episode,
                                                          i_id_presc_xml => i_id_presc_xml,
                                                          o_presc        => o_presc,
                                                          o_error        => o_error);
    END get_rx_prescr_data_aditional;

    FUNCTION get_migrant_doc
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        o_num_doc             OUT doc_external.num_doc%TYPE,
        o_exist_doc           OUT VARCHAR2,
        o_dt_expire           OUT doc_external.dt_expire%TYPE,
        o_doc_type            OUT doc_external.id_doc_type%TYPE,
        o_id_content_doc_type OUT doc_type.id_content%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_doc.get_migrant_doc(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_patient          => i_id_patient,
                                      o_num_doc             => o_num_doc,
                                      o_exist_doc           => o_exist_doc,
                                      o_dt_expire           => o_dt_expire,
                                      o_doc_type            => o_doc_type,
                                      o_id_content_doc_type => o_id_content_doc_type,
                                      o_error               => o_error);
    END get_migrant_doc;

    FUNCTION get_epis_out_on_pass_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_epis_out_on_pass.get_epis_out_on_pass_info(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                             o_info                => o_info,
                                                             o_error               => o_error);
    END get_epis_out_on_pass_info;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE,
        i_flg_hist   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_epis_out_on_pass.get_epis_out_on_pass_rep(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode,
                                                            i_flg_hist   => i_flg_hist,
                                                            o_detail     => o_detail,
                                                            o_error      => o_error);
    
    END get_epis_out_on_pass_rep;

    FUNCTION get_admin_info_by_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_lst_id_patient IN table_number,
        i_dt_end         IN VARCHAR2 DEFAULT NULL,
        o_info_pat       OUT pk_types.cursor_type,
        o_info_med       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name  user_procedures.procedure_name%TYPE := 'GET_ADMIN_INFO_BY_PATIENT';
        l_lst_result_epis table_number;
        l_msg_undefined   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M050');
        l_dt_end          TIMESTAMP WITH LOCAL TIME ZONE;
        l_separator       VARCHAR2(10) := ' / ';
    
    BEGIN
    
        -- convert date
        l_dt_end := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => i_dt_end,
                                                  i_timezone  => NULL);
    
        IF NOT pk_rt_med_pfh.get_admin_info_by_patient(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_lst_id_patient => i_lst_id_patient,
                                                       i_dt_end         => l_dt_end,
                                                       o_lst_id_episode => l_lst_result_epis,
                                                       o_info_med       => o_info_med,
                                                       o_error          => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        OPEN o_info_pat FOR
            SELECT
            -- 1ºheader
             id_clinical_service,
             service_name || l_separator || department_name clinical_service_name,
             (SELECT pk_date_utils.date_char_tsz(i_lang, current_timestamp, i_prof.institution, i_prof.software)
                FROM dual) ||
             decode(l_dt_end,
                    NULL,
                    NULL,
                    l_separator ||
                    (SELECT pk_date_utils.date_char_tsz(i_lang, l_dt_end, i_prof.institution, i_prof.software)
                       FROM dual)) unidose_dates,
             --2ºheader
             nvl(clinical_service_name, l_msg_undefined) service_name,
             nvl(department_name, l_msg_undefined) department_name,
             nvl(room_name, l_msg_undefined) room_name,
             --3ºheader
             nvl(bed_name, l_msg_undefined) bed_name,
             id_patient,
             id_episode,
             pat_name,
             pat_age,
             nvl(pat_nr_process, l_msg_undefined) pat_nr_process
              FROM (SELECT e.id_clinical_service,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) clinical_service_name,
                           pk_translation.get_translation(i_lang, d.code_department) service_name,
                           pk_translation.get_translation(i_lang, dpt.code_dept) department_name,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name,
                           e.id_patient,
                           e.id_episode,
                           (SELECT pk_patient.get_patient_name(i_lang, e.id_patient)
                              FROM dual) pat_name,
                           (SELECT pk_patient.get_pat_age(i_lang,
                                                          pat.dt_birth,
                                                          pat.dt_deceased,
                                                          pat.age,
                                                          i_prof.institution,
                                                          i_prof.software)
                              FROM dual) pat_age,
                           (SELECT pk_patient.get_process_number(i_lang, i_prof, e.id_patient)
                              FROM dual) pat_nr_process
                      FROM episode e
                      JOIN patient pat
                        ON pat.id_patient = e.id_patient
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                      JOIN department d
                        ON (d.id_department = dcs.id_department AND d.flg_available = pk_alert_constant.g_yes)
                      JOIN clinical_service cs
                        ON (cs.id_clinical_service = e.id_clinical_service AND
                           cs.flg_available = pk_alert_constant.g_yes)
                      JOIN dept dpt
                        ON (dpt.id_dept = d.id_dept AND dpt.flg_available = pk_alert_constant.g_yes)
                      LEFT JOIN bed b
                        ON b.id_bed = ei.id_bed
                      LEFT JOIN room r
                        ON r.id_room = b.id_room
                     WHERE e.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                             epis.column_value
                                              FROM TABLE(l_lst_result_epis) epis)) t
             ORDER BY pat_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_cursor_if_closed(o_info_pat);
            pk_types.open_cursor_if_closed(o_info_med);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_info_pat);
            pk_types.open_cursor_if_closed(o_info_med);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_admin_info_by_patient;

    FUNCTION get_admin_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_info_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name  user_procedures.procedure_name%TYPE := 'GET_ADMIN_SERVICES';
        l_lst_result_epis table_number;
    
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_admin_episodes(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                o_lst_id_episode => l_lst_result_epis,
                                                o_error          => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        OPEN o_info_services FOR
            SELECT DISTINCT d.id_department id_service,
                            pk_translation.get_translation(i_lang, d.code_department) desc_service
              FROM episode e
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
              JOIN department d
                ON (d.id_department = dcs.id_department AND d.flg_available = pk_alert_constant.g_yes AND
                   d.id_institution = i_prof.institution)
            
             WHERE e.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                     epis.column_value
                                      FROM TABLE(l_lst_result_epis) epis)
               AND e.flg_status NOT IN (pk_alert_constant.g_inactive, pk_alert_constant.g_cancelled)
               AND e.id_institution = i_prof.institution
               AND ei.id_software = i_prof.software
             ORDER BY desc_service;
    
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_cursor_if_closed(o_info_services);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_info_services);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_admin_services;

    FUNCTION get_admin_patients
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN table_number,
        o_info_patients OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name  user_procedures.procedure_name%TYPE := 'GET_ADMIN_PATIENTS';
        l_lst_result_epis table_number;
        l_separator       VARCHAR2(10) := '/';
    
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_admin_episodes(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                o_lst_id_episode => l_lst_result_epis,
                                                o_error          => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        OPEN o_info_patients FOR
            SELECT DISTINCT e.id_patient,
                            (SELECT pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode)
                               FROM dual) desc_patient,
                            p.gender || l_separator || (SELECT pk_patient.get_pat_age(i_lang,
                                                                                      p.dt_birth,
                                                                                      p.dt_deceased,
                                                                                      p.age,
                                                                                      i_prof.institution,
                                                                                      i_prof.software)
                                                          FROM dual) desc_gender_age,
                            pk_translation.get_translation(i_lang, d.code_department) desc_department,
                            d.id_department
              FROM episode e
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
              JOIN patient p
                ON p.id_patient = e.id_patient
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
              JOIN department d
                ON (d.id_department = dcs.id_department AND d.flg_available = pk_alert_constant.g_yes AND
                   d.id_institution = i_prof.institution)
            
             WHERE e.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                     epis.column_value
                                      FROM TABLE(l_lst_result_epis) epis)
               AND e.flg_status NOT IN (pk_alert_constant.g_inactive, pk_alert_constant.g_cancelled)
               AND e.id_institution = i_prof.institution
               AND d.id_department IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                        dep.column_value
                                         FROM TABLE(i_id_department) dep)
             ORDER BY desc_department, desc_patient;
    
        RETURN TRUE;
    EXCEPTION
        WHEN my_exception THEN
            pk_types.open_cursor_if_closed(o_info_patients);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_info_patients);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_admin_patients;

    FUNCTION get_pharm_return_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_pha_return IN table_number DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_return_report(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_id_episode,
                                                     i_id_pha_return => CASE
                                                                            WHEN i_id_pha_return.count > 0 THEN
                                                                             i_id_pha_return
                                                                            ELSE
                                                                             NULL
                                                                        END,
                                                     o_info          => o_info,
                                                     o_error         => o_error);
    END get_pharm_return_report;
BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_debug_enable := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);

END pk_reports_medication_api;
/
