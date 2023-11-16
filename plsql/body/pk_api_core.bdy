/*-- Last Change Revision: $Rev: 2012660 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-04-13 15:34:11 +0100 (qua, 13 abr 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_core IS

    /********************************************************************************************
     *  Clears data related to monitorization for a patient/episode
     *
     * @param i_lang                 ID language
     * @param i_market               Market ID
     * @param i_array_institution    Institutions IDs
     * @param i_id_timezone_region   New timezone
     * 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Sergio Dias
     * @since                        2-2-2011
    ********************************************************************************************/
    FUNCTION update_timezone
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN market.id_market%TYPE,
        i_array_institution  IN table_number,
        i_id_timezone_region IN timezone_region.id_timezone_region%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30) := 'UPDATE_TIMEZONE';
    
        l_id_institution institution.id_institution%TYPE;
        l_tbl_inst       table_number;
    
    BEGIN
        IF i_array_institution.count = 0
        THEN
            SELECT ai.id_ab_institution
              BULK COLLECT
              INTO l_tbl_inst
              FROM ab_institution ai
             WHERE ai.id_ab_market = i_market
               AND ai.flg_available = pk_alert_constant.g_yes;
        ELSE
            l_tbl_inst := i_array_institution;
        END IF;
    
        FOR i IN l_tbl_inst.first .. l_tbl_inst.last
        LOOP
            pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => l_tbl_inst(i),
                                                         i_import_code                => NULL,
                                                         i_record_status              => NULL,
                                                         i_id_ab_market               => NULL,
                                                         i_code                       => NULL,
                                                         i_description                => NULL,
                                                         i_alt_description            => NULL,
                                                         i_shortname                  => NULL,
                                                         i_vat_registration           => NULL,
                                                         i_timezone_region_code       => NULL,
                                                         i_rb_country_key             => NULL,
                                                         i_rb_regional_classifier_key => NULL,
                                                         i_id_ab_institution_parent   => NULL,
                                                         i_flg_type                   => NULL,
                                                         i_address1                   => NULL,
                                                         i_address2                   => NULL,
                                                         i_address3                   => NULL,
                                                         i_zip_code                   => NULL,
                                                         i_zip_code_description       => NULL,
                                                         i_fax_number                 => NULL,
                                                         i_phone_number               => NULL,
                                                         i_email                      => NULL,
                                                         i_logo                       => NULL,
                                                         i_web_site                   => NULL,
                                                         i_geo_location_key           => NULL,
                                                         i_flg_external               => NULL,
                                                         i_code_institution           => NULL,
                                                         i_flg_available              => NULL,
                                                         i_rank                       => NULL,
                                                         i_barcode                    => NULL,
                                                         i_ine_location               => NULL,
                                                         i_id_timezone_region         => i_id_timezone_region,
                                                         i_ext_code                   => NULL,
                                                         i_dn_flg_status              => NULL,
                                                         i_adress_type                => NULL,
                                                         i_contact_det                => NULL,
                                                         o_id_ab_institution          => l_id_institution);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_timezone;

    /********************************************************************************************
     *  Clears data related to monitorization for a patient/episode
     *
     * @param i_lang                 ID language
     * @param i_table_id_episodes    Episodes IDs
     * @param i_table_id_patients    Patients IDs
     * 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Sergio Dias
     * @since                        2-2-2011
    ********************************************************************************************/
    FUNCTION clear_monitorization_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_episodes IN table_number,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_table_id_monitorizations    table_number;
        l_table_id_monitorizations_vs table_number;
        l_table_id_moni_vs_plan       table_number;
        l_function_name               VARCHAR2(30) := 'clear_monitorization_reset';
    
    BEGIN
        -- call check_environment to validate environment variables
        g_error := 'IF NOT check_environment(' || i_lang || ' , o_error)';
        /*IF NOT check_environment(i_lang, o_error)
        THEN
            g_error := 'Environment error';
            pk_alertlog.log_debug(g_error, g_package_name);
            RETURN FALSE;
        END IF;*/
    
        -- get IDs to delete from monitorizations table
        SELECT m.id_monitorization
          BULK COLLECT
          INTO l_table_id_monitorizations
          FROM monitorization m
         WHERE m.id_episode IN (SELECT *
                                  FROM TABLE(i_table_id_episodes))
            OR (m.id_episode IS NULL AND
               m.id_patient IN (SELECT *
                                   FROM TABLE(i_table_id_patients)));
    
        -- get IDs to delete from MONITORIZATION_VS table
        SELECT m.id_monitorization_vs
          BULK COLLECT
          INTO l_table_id_monitorizations_vs
          FROM monitorization_vs m
         WHERE m.id_monitorization IN (SELECT *
                                         FROM TABLE(l_table_id_monitorizations));
    
        -- get IDs to delete from MONITORIZATION_VS_PLAN table
        SELECT m.id_monitorization_vs_plan
          BULK COLLECT
          INTO l_table_id_moni_vs_plan
          FROM monitorization_vs_plan m
         WHERE m.id_monitorization_vs IN (SELECT *
                                            FROM TABLE(l_table_id_monitorizations_vs));
    
        -- delete from EA table with previous IDs
        DELETE FROM monitorizations_ea mea
         WHERE mea.id_monitorization IN (SELECT *
                                           FROM TABLE(l_table_id_monitorizations))
            OR mea.id_monitorization_vs_plan IN
               (SELECT *
                  FROM TABLE(l_table_id_moni_vs_plan))
            OR mea.id_monitorization_vs IN (SELECT *
                                              FROM TABLE(l_table_id_monitorizations_vs))
            OR mea.id_episode IN (SELECT *
                                    FROM TABLE(i_table_id_episodes));
    
        -- delete references to present episodes from vital_sign                            
        UPDATE vital_sign_read vsr
           SET vsr.id_monitorization_vs_plan = NULL
         WHERE vsr.id_monitorization_vs_plan IN
               (SELECT *
                  FROM TABLE(l_table_id_moni_vs_plan));
    
        -- delete references to present episodes
        UPDATE monitorizations_ea mea
           SET mea.id_episode_origin = NULL, mea.id_prev_episode = NULL
         WHERE mea.id_episode_origin IN (SELECT *
                                           FROM TABLE(i_table_id_episodes))
            OR mea.id_prev_episode IN (SELECT *
                                         FROM TABLE(i_table_id_episodes));
    
        -- delete from MONITORIZATION_VS_PLAN table with previous IDs
        DELETE FROM monitorization_vs_plan mvp
         WHERE mvp.id_monitorization_vs IN (SELECT *
                                              FROM TABLE(l_table_id_monitorizations_vs));
    
        -- delete from MONITORIZATION_VS table with previous IDs
        DELETE FROM monitorization_vs mv
         WHERE mv.id_monitorization IN (SELECT *
                                          FROM TABLE(l_table_id_monitorizations));
    
        -- delete from SUSP_TASK_MONITORING table with previous IDs
        DELETE FROM susp_task_monitoring sm
         WHERE sm.id_monitorization IN (SELECT *
                                          FROM TABLE(l_table_id_monitorizations));
    
        -- delete from MONITORIZATION table with previous IDs
        DELETE FROM monitorization m
         WHERE m.id_episode IN (SELECT *
                                  FROM TABLE(i_table_id_episodes));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END clear_monitorization_reset;

    /********************************************************************************************
     *  Clears vital signs data for a patient/episode
     *
     * @param i_lang                 ID language
     * @param i_table_id_episodes    Episodes IDs
     * @param i_table_id_patients    Patients IDs
     * 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Sergio Dias
     * @since                        2-2-2011
    ********************************************************************************************/
    FUNCTION clear_vital_sign_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_episodes IN table_number,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_table_id_vital_signs      table_number;
        l_table_id_vital_signs_hist table_number;
        l_table_id_epis_mtos_score  table_number;
        l_function_name             VARCHAR2(30) := 'clear_vital_sign_reset';
        rows_vsr_out                table_varchar := table_varchar();
        l_rowids                    table_varchar := table_varchar();
    BEGIN
        -- collect vital_signs ids to delete
        g_error := 'collect vital_signs ids to delete';
        alertlog.pk_alertlog.log_debug(g_error);
        SELECT vsr.id_vital_sign_read
          BULK COLLECT
          INTO l_table_id_vital_signs
          FROM vital_sign_read vsr
         WHERE vsr.id_episode IN (SELECT *
                                    FROM TABLE(i_table_id_episodes))
            OR (vsr.id_episode IS NULL AND
               vsr.id_patient IN (SELECT *
                                     FROM TABLE(i_table_id_patients)));
    
        g_error := 'CALL pk_api_pfh_in.delete_presc';
        alertlog.pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_in.del_presc_vital_sign_assoc(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_episode         => i_table_id_episodes,
                                                        i_id_vital_sign_read => l_table_id_vital_signs,
                                                        o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'collect vital_signs ids to delete';
        alertlog.pk_alertlog.log_debug(g_error);
        SELECT vsr.id_vital_sign_read_hist
          BULK COLLECT
          INTO l_table_id_vital_signs_hist
          FROM vital_sign_read_hist vsr
         WHERE vsr.id_vital_sign_read IN (SELECT *
                                            FROM TABLE(l_table_id_vital_signs));
    
        -- delete from MONITORIZATION_VS_PLAN table with previous IDs
        g_error := 'DELETE FROM vital_signs_ea';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vital_signs_ea vsea
         WHERE vsea.id_vital_sign_read IN (SELECT *
                                             FROM TABLE(l_table_id_vital_signs));
    
        -- delete from VITAL_SIGN_PREGNANCY table with previous IDs
        g_error := 'DELETE FROM vital_sign_pregnancy';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vital_sign_pregnancy vsp
         WHERE vsp.id_vital_sign_read IN (SELECT *
                                            FROM TABLE(l_table_id_vital_signs));
    
        -- delete references from PRE_HOSP_VS_READ table with previous IDs
        g_error := 'DELETE FROM pre_hosp_vs_read';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM pre_hosp_vs_read phvr
         WHERE phvr.id_vital_sign_read IN (SELECT *
                                             FROM TABLE(l_table_id_vital_signs));
    
        -- delete all references in vs_read_hist_attribute
        g_error := 'DELETE FROM vs_read_hist_attribute';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vs_read_hist_attribute vse
         WHERE vse.id_vital_sign_read_hist IN
               (SELECT *
                  FROM TABLE(l_table_id_vital_signs_hist));
    
        -- delete references from VITAL_SIGN_READ_HIST table with previous IDs
        g_error := 'DELETE FROM vital_sign_read_hist';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vital_sign_read_hist vsrh
         WHERE vsrh.id_vital_sign_read IN (SELECT *
                                             FROM TABLE(l_table_id_vital_signs));
    
        -- collect EPIS_MTOS_PARAM ids to delete
        g_error := 'collect epis_mtos_param ids to delete';
        alertlog.pk_alertlog.log_debug(g_error);
        SELECT emp.id_epis_mtos_score
          BULK COLLECT
          INTO l_table_id_epis_mtos_score
          FROM epis_mtos_param emp
         WHERE decode(emp.flg_param_task_type,
                      pk_sev_scores_constant.g_flg_param_task_vital_sign,
                      emp.id_task_refid,
                      NULL) IN (SELECT *
                                  FROM TABLE(l_table_id_vital_signs));
    
        -- delete from EPIS_MTOS_PARAM table with previous IDs
        g_error := 'DELETE FROM epis_mtos_param';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM epis_mtos_param emp
         WHERE decode(emp.flg_param_task_type,
                      pk_sev_scores_constant.g_flg_param_task_vital_sign,
                      emp.id_task_refid,
                      NULL) IN (SELECT *
                                  FROM TABLE(l_table_id_vital_signs))
            OR emp.id_epis_mtos_score IN (SELECT *
                                            FROM TABLE(l_table_id_epis_mtos_score));
    
        -- delete from EPIS_MTOS_SCORE table with previous IDs                                             
        g_error := 'DELETE FROM epis_mtos_score';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM epis_mtos_score ems
         WHERE ems.id_epis_mtos_score IN (SELECT *
                                            FROM TABLE(l_table_id_epis_mtos_score));
    
        -- delete all references to the patient ids from VS_PATIENT_EA
        g_error := 'DELETE FROM vs_patient_ea';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vs_patient_ea vpe
         WHERE vpe.id_last_1_vsr IN (SELECT *
                                       FROM TABLE(l_table_id_vital_signs))
            OR vpe.id_last_2_vsr IN (SELECT *
                                       FROM TABLE(l_table_id_vital_signs))
            OR vpe.id_last_3_vsr IN (SELECT *
                                       FROM TABLE(l_table_id_vital_signs))
            OR vpe.id_first_vsr IN (SELECT *
                                      FROM TABLE(l_table_id_vital_signs))
            OR vpe.id_max_vsr IN (SELECT *
                                    FROM TABLE(l_table_id_vital_signs))
            OR vpe.id_min_vsr IN (SELECT *
                                    FROM TABLE(l_table_id_vital_signs));
    
        -- delete all references to the episodes ids from VS_VISIT_EA
        g_error := 'DELETE FROM vs_visit_ea';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vs_visit_ea vve
         WHERE vve.id_last_1_vsr IN (SELECT *
                                       FROM TABLE(l_table_id_vital_signs))
            OR vve.id_last_2_vsr IN (SELECT *
                                       FROM TABLE(l_table_id_vital_signs))
            OR vve.id_last_3_vsr IN (SELECT *
                                       FROM TABLE(l_table_id_vital_signs))
            OR vve.id_first_vsr IN (SELECT *
                                      FROM TABLE(l_table_id_vital_signs))
            OR vve.id_max_vsr IN (SELECT *
                                    FROM TABLE(l_table_id_vital_signs))
            OR vve.id_min_vsr IN (SELECT *
                                    FROM TABLE(l_table_id_vital_signs));
    
        -- delete all references in VITAL_SIGNS_EA
        g_error := 'DELETE FROM vital_signs_ea';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vital_signs_ea vse
         WHERE vse.id_vital_sign_read IN (SELECT *
                                            FROM TABLE(l_table_id_vital_signs));
    
        -- delete all references in vs_read_attribute
        g_error := 'DELETE FROM vs_read_attribute';
        alertlog.pk_alertlog.log_debug(g_error);
        DELETE FROM vs_read_attribute vse
         WHERE vse.id_vital_sign_read IN (SELECT *
                                            FROM TABLE(l_table_id_vital_signs));
    
        -- delete from VITAL_SIGN_READ table with previous IDs
        g_error := 'DELETE FROM vital_sign_read';
        alertlog.pk_alertlog.log_debug(g_error);
        FOR l_id_vsr IN (SELECT t.column_value AS id
                           FROM TABLE(l_table_id_vital_signs) t)
        LOOP
            ts_vital_sign_read.del(id_vital_sign_read_in => l_id_vsr.id, rows_out => rows_vsr_out);
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VITAL_SIGN_READ',
                                      i_rowids     => rows_vsr_out,
                                      o_error      => o_error);
    
        -- Update easy access
        FOR i IN 1 .. i_table_id_patients.count
        LOOP
            IF i_table_id_patients(i) IS NOT NULL
            THEN
                g_error := 'TS_VIEWER_EHR_EA.UPD';
                ts_viewer_ehr_ea.upd(id_patient_in => i_table_id_patients(i),
                                     num_vs_in     => NULL,
                                     num_vs_nin    => FALSE,
                                     desc_vs_in    => NULL,
                                     desc_vs_nin   => FALSE,
                                     code_vs_in    => NULL,
                                     code_vs_nin   => FALSE,
                                     dt_vs_in      => NULL,
                                     dt_vs_nin     => FALSE,
                                     rows_out      => l_rowids);
            END IF;
        END LOOP;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END clear_vital_sign_reset;

    /********************************************************************************************
    * Get Past History Surgical procedures
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_id_context        Identifier of the Episode/Patient/Visit based on the i_flg_type_context
    * @param i_flg_type_context  Flag to filter by Episode (E), by Visit (V) or by Patient (P)
    * @param o_doc_area          Data cursor
    * @param o_error             Error Message
    *
    * @return                    TRUE/FALSE
    *     
    * @author                    António Neto
    * @version                   2.6.1
    * @since                     2011-05-04
    *
    *********************************************************************************************/
    FUNCTION get_past_hist_surgical
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_context       IN NUMBER,
        i_flg_type_context IN VARCHAR2,
        o_doc_area         OUT NOCOPY pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_call_past_hist_surgical EXCEPTION;
    BEGIN
        g_error := 'CALL PK_PAST_HISTORY.GET_PAST_HIST_SURGICAL_API';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_past_history.get_past_hist_surgical_api(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_context       => i_id_context,
                                                          i_flg_type_context => i_flg_type_context,
                                                          o_doc_area         => o_doc_area,
                                                          o_error            => o_error)
        THEN
            RAISE l_call_past_hist_surgical;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_SURGICAL',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area);
        
            RETURN FALSE;
    END get_past_hist_surgical;

    /*********************************************************************************************************************
    *
    *              FOLLOW UP
    *
    *********************************************************************************************************************/
    FUNCTION interface_consult_request
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN opinion.id_clinical_service%TYPE,
        i_reason_ft    IN opinion.desc_problem%TYPE,
        i_reason_mc    IN table_number,
        i_prof_id      IN opinion.id_prof_questioned%TYPE,
        i_notes        IN opinion.notes%TYPE,
        i_dt_problem   IN VARCHAR2 DEFAULT NULL,
        o_opinion      OUT opinion.id_opinion%TYPE,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tot_opinion NUMBER(24) := 0;
        l_dt_problem  TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    
    BEGIN
    
        IF i_dt_problem IS NOT NULL
        THEN
            l_dt_problem := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_problem, NULL);
        END IF;
    
        g_error := 'counting number of pending opinions in episode';
    
        SELECT COUNT(1)
          INTO l_tot_opinion
          FROM opinion
         WHERE id_episode = i_episode
           AND id_opinion_type = i_opinion_type
           AND flg_state NOT IN ('O', 'C');
    
        g_error := 'Number of opinions: ' || l_tot_opinion;
        IF l_tot_opinion > 0
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT pk_opinion.set_consult_request(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_episode             => i_episode,
                                              i_patient             => i_patient,
                                              i_opinion             => i_opinion,
                                              i_opinion_type        => i_opinion_type,
                                              i_clin_serv           => i_clin_serv,
                                              i_reason_ft           => i_reason_ft,
                                              i_reason_mc           => i_reason_mc,
                                              i_tbl_alert_diagnosis => NULL,
                                              i_prof_id             => i_prof_id,
                                              i_notes               => i_notes,
                                              i_do_commit           => pk_alert_constant.g_no,
                                              i_followup_auto       => pk_alert_constant.get_no,
                                              i_dt_problem          => l_dt_problem,
                                              o_opinion             => o_opinion,
                                              o_opinion_hist        => o_opinion_hist,
                                              o_error               => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CONSULT_REQUEST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_consult_request;

    FUNCTION interface_set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_mng_followup          IN management_follow_up.id_management_follow_up%TYPE,
        i_episode               IN management_follow_up.id_episode%TYPE,
        i_notes                 IN management_follow_up.notes%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE,
        i_dt_register           IN VARCHAR2 DEFAULT NULL,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_register TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    
    BEGIN
    
        IF i_dt_register IS NOT NULL
        THEN
            l_dt_register := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_register, NULL);
        END IF;
    
        g_error := 'CALL pk_paramedical_prof_core.set_followup_notes';
        IF NOT pk_paramedical_prof_core.set_followup_notes(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_mng_followup          => i_mng_followup,
                                                           i_episode               => i_episode,
                                                           i_notes                 => i_notes,
                                                           i_start_dt              => i_start_dt,
                                                           i_time_spent            => i_time_spent,
                                                           i_unit_time             => i_unit_time,
                                                           i_next_dt               => i_next_dt,
                                                           i_flg_end_followup      => i_flg_end_followup,
                                                           i_dt_next_enc_precision => i_dt_next_enc_precision,
                                                           i_dt_register           => l_dt_register,
                                                           o_mng_followup          => o_mng_followup,
                                                           o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_SET_FOLLOWUP_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_set_followup_notes;

    FUNCTION intf_set_follow_up_state
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason    IN opinion_prof.id_cancel_reason%TYPE,
        i_dt_opinion       IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_opinion_prof   opinion_prof.id_opinion_prof%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_epis_encounter epis_encounter.id_epis_encounter%TYPE;
        l_id_patient     episode.id_patient%TYPE;
        l_do_commit      VARCHAR2(10) DEFAULT pk_alert_constant.g_no;
        l_dt_opinion     TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    BEGIN
    
        BEGIN
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e, opinion o
             WHERE e.id_episode = o.id_episode
               AND o.id_opinion = i_opinion;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        IF i_dt_opinion IS NOT NULL
        THEN
            l_dt_opinion := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_opinion, NULL);
        END IF;
    
        IF NOT pk_opinion.set_request_answer(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_opinion          => i_opinion,
                                             i_patient          => l_id_patient,
                                             i_flg_state        => i_flg_state,
                                             i_management_level => i_management_level,
                                             i_notes            => i_notes,
                                             i_cancel_reason    => i_cancel_reason,
                                             i_transaction_id   => NULL,
                                             i_do_commit        => l_do_commit,
                                             i_dt_opinion       => l_dt_opinion,
                                             o_opinion_prof     => l_opinion_prof,
                                             o_episode          => l_episode,
                                             o_epis_encounter   => l_epis_encounter,
                                             o_error            => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_SET_FOLLOW_UP_STATE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_set_follow_up_state;

    /*********************************************************************************************************************
    *
    *              CONSULT
    *
    *********************************************************************************************************************/

    FUNCTION interface_create_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_prof             IN profissional,
        i_prof_questioned  IN opinion.id_prof_questioned%TYPE DEFAULT NULL,
        i_speciality       IN opinion.id_speciality%TYPE DEFAULT NULL,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE DEFAULT NULL,
        i_desc             IN opinion.desc_problem%TYPE DEFAULT NULL,
        i_prof_cat_type    IN category.flg_type%TYPE DEFAULT NULL,
        i_flg_type         IN opinion.flg_type%TYPE DEFAULT NULL,
        i_dt_creation      IN VARCHAR2,
        o_id_opinion       OUT opinion.id_opinion%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_creation opinion.dt_problem_tstz%TYPE;
    BEGIN
    
        l_dt_creation := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => i_dt_creation,
                                                       i_timezone  => NULL);
        l_dt_creation := nvl(l_dt_creation, current_timestamp);
    
        IF NOT pk_opinion.create_opinion(i_lang             => i_lang,
                                         i_episode          => i_episode,
                                         i_prof_questions   => i_prof,
                                         i_prof_questioned  => i_prof_questioned,
                                         i_speciality       => i_speciality,
                                         i_clinical_service => i_clinical_service,
                                         i_desc             => i_desc,
                                         i_prof_cat_type    => i_prof_cat_type,
                                         i_flg_type         => i_flg_type,
                                         i_commit_data      => 'N',
                                         i_diag             => table_number(),
                                         i_patient          => NULL,
                                         i_dt_creation      => l_dt_creation,
                                         o_opinion          => o_id_opinion,
                                         o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CREATE_OPINION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_create_opinion;

    FUNCTION interface_read_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        i_dt_read    IN VARCHAR2 DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_opinion_prof opinion_prof.id_opinion_prof%TYPE;
    BEGIN
    
        IF NOT pk_opinion.create_opin_prof_int(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_opinion          => i_id_opinion,
                                               i_desc             => NULL,
                                               i_flg_face_to_face => NULL,
                                               i_commit_data      => 'N',
                                               i_dt_reply         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                   i_prof      => i_prof,
                                                                                                   i_timestamp => i_dt_read,
                                                                                                   i_timezone  => NULL),
                                               o_opinion_prof     => l_opinion_prof,
                                               o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CREATE_OPINION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_read_opinion;

    FUNCTION get_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_date TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => i_date,
                                                i_timezone  => NULL);
    
        l_date := nvl(l_date, current_timestamp);
    
        RETURN l_date;
    END get_date;

    FUNCTION interface_reply_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_opinion       IN opinion.id_opinion%TYPE,
        i_desc             IN opinion.desc_problem%TYPE DEFAULT NULL,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE,
        i_dt_reply         IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_opinion_prof opinion_prof.id_opinion_prof%TYPE;
        l_dt_reply     opinion.dt_problem_tstz%TYPE;
    BEGIN
    
        l_dt_reply := get_date(i_lang, i_prof, i_dt_reply);
    
        IF NOT pk_opinion.create_opin_prof_int(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_opinion          => i_id_opinion,
                                               i_desc             => i_desc,
                                               i_flg_face_to_face => i_flg_face_to_face,
                                               i_commit_data      => 'N',
                                               i_dt_reply         => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                   i_prof      => i_prof,
                                                                                                   i_timestamp => l_dt_reply,
                                                                                                   i_timezone  => NULL),
                                               o_opinion_prof     => l_opinion_prof,
                                               o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CREATE_OPINION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_reply_opinion;

    FUNCTION interface_cancel_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        i_dt_cancel  IN VARCHAR2,
        i_notes      IN opinion.notes_cancel%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_cancel opinion.dt_cancel_tstz%TYPE;
    
    BEGIN
    
        l_dt_cancel := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => i_dt_cancel,
                                                     i_timezone  => NULL);
        l_dt_cancel := nvl(l_dt_cancel, current_timestamp);
    
        IF NOT pk_opinion.cancel_opinion(i_lang          => i_lang,
                                         i_opinion       => i_id_opinion,
                                         i_prof          => i_prof,
                                         i_notes         => i_notes,
                                         i_flg_type      => 'O',
                                         i_cancel_reason => NULL,
                                         i_dt_cancel     => l_dt_cancel,
                                         i_commit_data   => pk_alert_constant.g_no,
                                         o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CREATE_OPINION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_cancel_opinion;

    FUNCTION interface_set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_opinion            IN opinion.id_opinion%TYPE,
        i_notes                 IN management_follow_up.notes%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE,
        i_dt_register           IN VARCHAR2 DEFAULT NULL,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT e.id_episode
              INTO l_id_episode
              FROM episode e, opinion o
             WHERE e.id_episode = o.id_episode
               AND o.id_opinion = i_id_opinion;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        IF NOT interface_set_followup_notes(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_mng_followup          => NULL,
                                            i_episode               => l_id_episode,
                                            i_notes                 => i_notes,
                                            i_start_dt              => i_start_dt,
                                            i_time_spent            => i_time_spent,
                                            i_unit_time             => i_unit_time,
                                            i_next_dt               => i_next_dt,
                                            i_flg_end_followup      => i_flg_end_followup,
                                            i_dt_next_enc_precision => i_dt_next_enc_precision,
                                            i_dt_register           => i_dt_register,
                                            o_mng_followup          => o_mng_followup,
                                            o_error                 => o_error)
        THEN
        
            RAISE g_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_SET_FOLLOWUP_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END interface_set_followup_notes;
BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_api_core;
/
