/*-- Last Change Revision: $Rev: 2027542 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:32 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_progress_notes IS

    g_error         VARCHAR2(1000 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_found         BOOLEAN;
    g_fault     EXCEPTION;
    g_exception EXCEPTION;

    g_caller user_objects.object_name%TYPE;

    g_domain_flg_rep_by CONSTANT sys_domain.code_domain%TYPE := 'EPIS_COMPLAINT.FLG_REPORTED_BY';

    -- it available configurations
    g_it_this_visit CONSTANT sys_config.value%TYPE := 'VST';
    g_it_my_visits  CONSTANT sys_config.value%TYPE := 'PRF';
    g_it_this_spec  CONSTANT sys_config.value%TYPE := 'SPC';
    g_it_all_visits CONSTANT sys_config.value%TYPE := 'ALL';

    -- signature available configurations
    g_sign_all  CONSTANT sys_config.value%TYPE := 'ALL';
    g_sign_otm  CONSTANT sys_config.value%TYPE := 'OTM';
    g_sign_none CONSTANT sys_config.value%TYPE := 'NONE';

    g_long_notes CONSTANT cancel_info_det.flg_notes_cancel_type%TYPE := 'L';

    -- shared cursors
    CURSOR c_per_ids(i_epis_reason IN pn_epis_reason.id_pn_epis_reason%TYPE) IS
        SELECT per.id_epis_complaint, per.id_epis_anamnesis
          FROM pn_epis_reason per
         WHERE per.id_pn_epis_reason = i_epis_reason;

    /**
    * Checks if the reports layer is consuming the current service call.
    *
    * @return               'Y' if service is for reports consumption, 'N' otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/12
    */
    FUNCTION check_rep_consumer RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        -- reports consumer is identified by having REP in its name
        IF instr(str1 => upper(g_caller), str2 => 'REP') > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END check_rep_consumer;

    /**
    * Get the episode's current DEP_CLIN_SERV identifier.
    *
    * @param i_episode      episode identifier
    *
    * @return               DEP_CLIN_SERV identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/21
    */
    FUNCTION get_dep_clin_serv(i_episode IN epis_info.id_episode%TYPE) RETURN epis_info.id_dep_clin_serv%TYPE IS
        l_id_dcs epis_info.id_dep_clin_serv%TYPE;
    BEGIN
        BEGIN
            g_error := 'SELECT l_dep_clin_serv';
            SELECT ei.id_dep_clin_serv
              INTO l_id_dcs
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_dcs := NULL;
        END;
    
        RETURN l_id_dcs;
    END get_dep_clin_serv;

    /**
    * Get the episode's current SCH_EVENT identifier.
    *
    * @param i_episode      episode identifier
    *
    * @return               SCH_EVENT identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/21
    */
    FUNCTION get_sch_event(i_episode IN epis_info.id_episode%TYPE) RETURN schedule.id_sch_event%TYPE IS
        l_sch_event schedule.id_sch_event%TYPE;
    BEGIN
        BEGIN
            g_error := 'SELECT l_sch_event';
            SELECT s.id_sch_event
              INTO l_sch_event
              FROM epis_info ei
              LEFT JOIN schedule s
                ON ei.id_schedule = s.id_schedule
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_sch_event := NULL;
        END;
    
        RETURN l_sch_event;
    END get_sch_event;

    /**
    * Check if "reported by" field should be enabled.
    *
    * @param i_prof         logged professional structure
    *
    * @return               'Y' if it should be enabled, 'N' otherwise.
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/25
    */
    FUNCTION get_enable_rep_by(i_prof IN profissional) RETURN VARCHAR2 IS
        l_market        market.id_market%TYPE;
        l_enable_rep_by VARCHAR2(1 CHAR);
    BEGIN
        g_error  := 'CALL pk_core.get_inst_mkt';
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF l_market = pk_alert_constant.g_id_market_usa
        THEN
            l_enable_rep_by := pk_alert_constant.g_yes;
        ELSE
            l_enable_rep_by := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_enable_rep_by;
    END get_enable_rep_by;

    /**
    * Get reported by flag.
    *
    * @param i_epis_reason  record identifier
    *
    * @return               reported by flag
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/27
    */
    FUNCTION get_flg_rep_by(i_epis_reason IN pn_epis_reason.id_pn_epis_reason%TYPE)
        RETURN epis_anamnesis.flg_reported_by%TYPE IS
        l_flg_rep_by epis_anamnesis.flg_reported_by%TYPE;
    BEGIN
        g_error := 'SELECT l_flg_rep_by';
        SELECT nvl(ec.flg_reported_by, ea.flg_reported_by) flg_reported_by
          INTO l_flg_rep_by
          FROM pn_epis_reason per
          LEFT JOIN epis_complaint ec
            ON per.id_epis_complaint = ec.id_epis_complaint
          LEFT JOIN epis_anamnesis ea
            ON per.id_epis_anamnesis = ea.id_epis_anamnesis
         WHERE per.id_pn_epis_reason = i_epis_reason;
    
        RETURN l_flg_rep_by;
    END get_flg_rep_by;

    /**
    * Get record signature, integrating Progress notes signature mode.
    * Similar to PK_TOOLS.GET_PROF_DESCRIPTION.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_id      professional identifier
    * @param i_date         record date
    * @param i_episode      episode identifier
    *
    * @return               reported by flag
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/10
    */
    FUNCTION get_signature
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_ret       pk_translation.t_desc_translation;
        l_sign_mode sys_config.value%TYPE;
    BEGIN
        IF check_rep_consumer = pk_alert_constant.g_yes
        THEN
            l_sign_mode := g_sign_all;
        ELSE
            l_sign_mode := pk_sysconfig.get_config(i_code_cf => g_config_sign_mode, i_prof => i_prof);
        END IF;
    
        IF l_sign_mode = g_sign_all
        THEN
            -- showing all signatures
            l_ret := pk_tools.get_prof_description(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_prof_id => i_prof_id,
                                                   i_date    => i_date,
                                                   i_episode => i_episode) || ' / ' ||
                     pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                 i_date => i_date,
                                                 i_inst => i_prof.institution,
                                                 i_soft => i_prof.software);
        ELSIF l_sign_mode = g_sign_otm
        THEN
            -- showing all signatures, other than mine
            IF i_prof_id = i_prof.id
            THEN
                l_ret := NULL;
            ELSE
                l_ret := pk_tools.get_prof_description(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_prof_id => i_prof_id,
                                                       i_date    => i_date,
                                                       i_episode => i_episode) || ' / ' ||
                         pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                     i_date => i_date,
                                                     i_inst => i_prof.institution,
                                                     i_soft => i_prof.software);
            END IF;
        ELSIF l_sign_mode = g_sign_none
        THEN
            -- showing no signatures
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_signature;

    /********************************************************************************************
    * Gets the last change on SOAP (author and date).
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_episode           episode identifier
    * @param i_blk_info          blocks to retrieve records from
    *
    * @return                    author and date of last change
    *
    * @author                    Teresa Coutinho
    * @version                    2.5.0.2
    * @since                     2009/??/??
    ********************************************************************************************/
    FUNCTION get_prof_rec
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_blk_info IN t_coll_soap_block
    ) RETURN pk_translation.t_desc_translation IS
        l_prof_rec    pk_translation.t_desc_translation;
        l_last_change epis_recomend.dt_epis_recomend_tstz%TYPE;
        l_prof_id     professional.id_professional%TYPE;
    
        CURSOR c_last_change IS
            SELECT ft.dt_change, ft.id_professional
              FROM (SELECT NULL id_pn_soap_block,
                           g_type_reason_visit flg_type,
                           nvl(ec.id_professional, ea.id_professional) id_professional,
                           nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_change
                      FROM pn_epis_reason per
                      LEFT JOIN epis_complaint ec
                        ON per.id_epis_complaint = ec.id_epis_complaint
                      LEFT JOIN epis_anamnesis ea
                        ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                     WHERE per.id_episode = i_episode
                       AND per.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                    UNION ALL
                    SELECT NULL id_pn_soap_block, er.flg_type, er.id_professional, er.dt_epis_recomend_tstz dt_change
                      FROM epis_recomend er
                     WHERE er.id_episode = i_episode
                       AND er.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                    UNION ALL
                    SELECT epn.id_pn_soap_block,
                           g_type_user_defined     flg_type,
                           epn.id_prof_last_update id_professional,
                           epn.dt_last_update      dt_change
                      FROM epis_prog_notes epn
                     WHERE epn.id_episode = i_episode
                       AND epn.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) ft
              JOIN (SELECT t.id_block, t.flg_type
                      FROM TABLE(i_blk_info) t) blk
                ON ft.flg_type = blk.flg_type
             WHERE ft.id_pn_soap_block IS NULL
                OR ft.id_pn_soap_block = blk.id_block
             ORDER BY ft.dt_change DESC;
    BEGIN
        IF i_blk_info IS NULL
           OR i_blk_info.count < 1
        THEN
            l_prof_rec := NULL;
        ELSE
            g_error := 'OPEN c_last_change';
            OPEN c_last_change;
            FETCH c_last_change
                INTO l_last_change, l_prof_id;
            g_found := c_last_change%FOUND;
            CLOSE c_last_change;
        
            IF g_found
            THEN
                g_error    := 'SET l_prof_rec';
                l_prof_rec := pk_tools.get_prof_description(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_prof_id,
                                                            i_date    => l_last_change,
                                                            i_episode => i_episode) || ' / ' ||
                              pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                          i_date => l_last_change,
                                                          i_inst => i_prof.institution,
                                                          i_soft => i_prof.software);
            ELSE
                l_prof_rec := NULL;
            END IF;
        END IF;
    
        RETURN l_prof_rec;
    END get_prof_rec;

    /**
    * Similar to PK_SYSDOMAIN.GET_DOMAINS for domain DIAGNOSIS.FLG_TYPE.
    * Marks one option as default.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_domains      cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.?
    * @since                2009/05/20
    */
    FUNCTION get_diag_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DIAG_TYPES';
        l_def_diag_type  sys_config.value%TYPE;
        l_exc_diag_types sys_config.value%TYPE;
        l_prof_cat       category.flg_type%TYPE;
    BEGIN
        g_error         := 'GET configs';
        l_def_diag_type := pk_sysconfig.get_config(i_code_cf => g_config_def_diag_type, i_prof => i_prof);
        l_prof_cat      := pk_tools.get_prof_cat(i_prof => i_prof);
    
        IF l_prof_cat = pk_alert_constant.g_cat_type_nurse
        THEN
            l_exc_diag_types := pk_sysconfig.get_config(i_code_cf => g_config_exc_diag_type, i_prof => i_prof);
        END IF;
    
        g_error := 'OPEN o_domains';
        OPEN o_domains FOR
            SELECT sd.flg_terminology val,
                   sd.desc_terminology desc_val,
                   sd.rank,
                   NULL img_name,
                   decode(sd.flg_terminology, l_def_diag_type, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_select
              FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_tbl_task_type => table_number(pk_alert_constant.g_task_problems))) sd
             WHERE (l_exc_diag_types != sd.flg_terminology OR l_exc_diag_types IS NULL)
             ORDER BY sd.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_diag_types;

    /**
    * Retrieve all vital sign and monitorization records for the given episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_order        'N' to order by name, 'D' to order by date
    * @param o_enc_info     cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7
    * @since                2010/01/06
    */
    FUNCTION get_epis_vs_all
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_order   IN VARCHAR2,
        o_vs_data OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_name_sort CONSTANT VARCHAR2(1 CHAR) := 'N';
        l_date_sort CONSTANT VARCHAR2(1 CHAR) := 'D';
        l_visit          vital_signs_ea.id_visit%TYPE;
        l_decimal_symbol sys_config.value%TYPE;
    BEGIN
        l_visit          := pk_episode.get_id_visit(i_episode => i_episode);
        l_decimal_symbol := pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof);
    
        g_error := 'OPEN o_vs_data';
        OPEN o_vs_data FOR
            SELECT vsu.description, vsu.id_professional, vsu.change_date
              FROM (
                    -- Simple vital signs records
                    SELECT pk_vital_sign.get_vs_desc(i_lang, vsp.id_vital_sign) || ': ' ||
                            nvl2(vsp.id_vital_sign_desc,
                                 pk_vital_sign.get_vs_alias(i_lang,
                                                            vsp.id_patient,
                                                            (SELECT vsd.code_vital_sign_desc
                                                               FROM vital_sign_desc vsd
                                                              WHERE vsd.id_vital_sign_desc = vsp.id_vital_sign_desc)),
                                 pk_utils.to_str(vsp.value, l_decimal_symbol)) || ' ' ||
                            pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                      vsp.id_unit_measure,
                                                                      vsp.id_vs_scales_element) ||
                            nvl2(vsp.id_vs_scales_element,
                                 ' ' || pk_vital_sign.get_vs_scale_shortdesc(i_lang, vsp.id_vs_scales_element),
                                 NULL) || decode(pk_vital_sign.check_vs_notes(vsp.id_vital_sign_read),
                                                 pk_alert_constant.g_yes,
                                                 ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                                 '') AS description,
                            vsp.id_prof_read AS id_professional,
                            vsp.dt_vital_sign_read AS change_date
                      FROM (SELECT vsea.id_vital_sign_read,
                                    vsea.id_vital_sign,
                                    vsea.value,
                                    vsea.id_unit_measure,
                                    vsea.id_vital_sign_desc,
                                    vsea.id_vs_scales_element,
                                    vsea.id_patient,
                                    vsea.id_prof_read,
                                    vsea.dt_vital_sign_read,
                                    rank() over(PARTITION BY vsea.id_vital_sign ORDER BY vsea.dt_vital_sign_read DESC NULLS LAST) AS rank
                               FROM vital_signs_ea vsea
                              INNER JOIN episode e
                                 ON vsea.id_episode = e.id_episode
                              WHERE vsea.id_visit = l_visit
                                AND vsea.flg_state != pk_alert_constant.g_cancelled
                                AND pk_delivery.check_vs_read_from_fetus(vsea.id_vital_sign_read) = 0
                                AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                AND NOT EXISTS
                              (SELECT 1
                                       FROM vital_sign_relation vsr
                                      WHERE vsr.id_vital_sign_detail = vsea.id_vital_sign
                                        AND vsr.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum))) vsp
                     WHERE vsp.rank = 1 -- most recent vital signs records for a visit
                    
                    UNION ALL
                    
                    -- Composed vital signs records (Glasgow total and Blood pressures)
                    SELECT pk_vital_sign.get_vs_desc(i_lang, vsp.id_vital_sign) || ': ' ||
                            decode(vsp.relation_domain,
                                   pk_alert_constant.g_vs_rel_conc,
                                   pk_vital_sign.get_bloodpressure_value(vsp.id_vital_sign,
                                                                         vsp.id_patient,
                                                                         vsp.id_episode,
                                                                         vsp.dt_vital_sign_read,
                                                                         l_decimal_symbol) || ' ' ||
                                   pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsp.id_unit_measure, NULL),
                                   pk_alert_constant.g_vs_rel_sum,
                                   pk_vital_sign.get_glasgowtotal_value(vsp.id_vital_sign,
                                                                        vsp.id_patient,
                                                                        vsp.id_episode,
                                                                        vsp.dt_vital_sign_read)) ||
                            decode(pk_vital_sign.check_vs_notes(vsp.id_vital_sign_read),
                                   pk_alert_constant.g_yes,
                                   ' ' || pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                   '') AS description,
                            vsp.id_prof_read AS id_professional,
                            vsp.dt_vital_sign_read AS change_date
                      FROM (SELECT vsea.id_vital_sign_read,
                                    vsr.id_vital_sign_parent AS id_vital_sign,
                                    vsr.relation_domain,
                                    vsea.id_patient,
                                    vsea.id_episode,
                                    vsea.value,
                                    vsea.id_unit_measure,
                                    vsea.id_prof_read,
                                    vsea.dt_vital_sign_read,
                                    rank() over(PARTITION BY vsr.id_vital_sign_parent ORDER BY vsea.dt_vital_sign_read DESC NULLS LAST, vsr.id_vital_sign_detail ASC) AS rank
                               FROM vital_signs_ea vsea
                              INNER JOIN episode e
                                 ON vsea.id_episode = e.id_episode
                              INNER JOIN vital_sign_relation vsr
                                 ON vsea.id_vital_sign = vsr.id_vital_sign_detail
                              WHERE vsea.id_visit = l_visit
                                AND vsea.flg_state != pk_alert_constant.g_cancelled
                                AND pk_delivery.check_vs_read_from_fetus(vsea.id_vital_sign_read) = 0
                                AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                AND vsr.relation_domain IN
                                    (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)) vsp
                     WHERE vsp.rank = 1 -- most recent vital signs records for a visit
                    
                    UNION ALL
                    
                    -- Vital signs with monitorization requests but still without records
                    SELECT pk_vital_sign.get_vs_desc(i_lang, mp.id_vital_sign) AS description,
                            mp.id_professional,
                            mp.dt_monitorization AS change_date
                      FROM (SELECT mea.id_vital_sign,
                                    mea.dt_monitorization,
                                    mea.id_professional,
                                    rank() over(PARTITION BY mea.id_vital_sign ORDER BY mea.dt_monitorization DESC) AS rank
                               FROM monitorizations_ea mea
                              INNER JOIN episode e
                                 ON mea.id_episode = e.id_episode
                              WHERE mea.id_visit = l_visit
                                AND mea.flg_status NOT IN
                                    (pk_alert_constant.g_monitor_vs_canc, pk_alert_constant.g_monitor_vs_draft)
                                AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                AND NOT EXISTS
                              (SELECT 1
                                       FROM vital_signs_ea vsea
                                       LEFT OUTER JOIN vital_sign_relation vsr
                                         ON vsea.id_vital_sign = vsr.id_vital_sign_detail
                                        AND vsr.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                      WHERE vsea.id_visit = mea.id_visit
                                        AND mea.id_vital_sign IN (vsea.id_vital_sign, vsr.id_vital_sign_parent))) mp
                     WHERE mp.rank = 1 -- most recent vital signs with monitorization request for a visit
                    ) vsu
            
             ORDER BY decode(i_order, l_name_sort, nlssort(vsu.description, 'NLS_SORT=BINARY_AI')) ASC, -- sort order case insensitive and accent insensitive
                      decode(i_order, l_date_sort, vsu.change_date) DESC NULLS LAST;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EPIS_VS_ALL',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_vs_all;

    /**
    * Turns a collection of INFO into a TABLE_VARCHAR.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               TABLE_VARCHAR
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/15
    */
    FUNCTION get_table_varchar(i_info_coll IN table_info) RETURN table_varchar IS
        l_ret table_varchar := table_varchar();
    BEGIN
        IF i_info_coll IS NOT NULL
           AND i_info_coll.count > 0
        THEN
            l_ret.extend(i_info_coll.count * 2);
        
            FOR i IN i_info_coll.first .. i_info_coll.last
            LOOP
                l_ret((i * 2) - 1) := i_info_coll(i).id;
                l_ret(i * 2) := i_info_coll(i).desc_info;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_table_varchar;

    /**
    * Gets the descriptions of a collection of INFO into a TABLE_VARCHAR.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               TABLE_VARCHAR
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/09
    */
    FUNCTION get_info_desc(i_info_coll IN table_info) RETURN table_varchar IS
        l_ret table_varchar := table_varchar();
    BEGIN
        IF i_info_coll IS NOT NULL
           AND i_info_coll.count > 0
        THEN
            l_ret.extend(i_info_coll.count);
        
            FOR i IN i_info_coll.first .. i_info_coll.last
            LOOP
                l_ret(i) := i_info_coll(i).desc_info;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_info_desc;

    /**
    * Gets the identifiers of a collection of INFO into a TABLE_NUMBER.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               TABLE_NUMBER
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/09
    */
    FUNCTION get_info_id(i_info_coll IN table_info) RETURN table_number IS
        l_ret table_number := table_number();
    BEGIN
        IF i_info_coll IS NOT NULL
           AND i_info_coll.count > 0
        THEN
            l_ret.extend(i_info_coll.count);
        
            FOR i IN i_info_coll.first .. i_info_coll.last
            LOOP
                l_ret(i) := i_info_coll(i).id;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_info_id;

    /**
    * Concatenates INFO collection descriptions.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               concatenated descriptions
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/15
    */
    FUNCTION get_desc_concat(i_info_coll IN table_info) RETURN VARCHAR2 IS
        l_ret VARCHAR2(32767) := NULL;
    BEGIN
        IF i_info_coll IS NOT NULL
           AND i_info_coll.count > 0
        THEN
            FOR i IN i_info_coll.first .. i_info_coll.last
            LOOP
                l_ret := l_ret || i_info_coll(i).desc_info || '. ';
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_desc_concat;

    /**
    * Get epis_complaint record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ec        episode complaint identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_ec
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_ec IN epis_complaint.id_epis_complaint%TYPE
    ) RETURN table_info IS
        l_diags table_info;
    BEGIN
        IF i_id_ec IS NULL
        THEN
            l_diags := table_info();
        ELSE
            SELECT info(t.id_diagnosis, t.desc_diagnosis, NULL)
              BULK COLLECT
              INTO l_diags
              FROM (SELECT pn.id_diagnosis,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => pk_alert_constant.g_yes,
                                                      i_flg_show_term_code => pk_alert_constant.g_yes) desc_diagnosis
                      FROM progress_notes pn
                      JOIN diagnosis d
                        ON pn.id_diagnosis = d.id_diagnosis
                     WHERE pn.id_epis_complaint = i_id_ec
                     ORDER BY desc_diagnosis) t;
        END IF;
    
        RETURN l_diags;
    END get_coding_ec;

    /**
    * Get epis_anamnesis record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ea        episode anamnesis identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_ea
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_ea IN epis_anamnesis.id_epis_anamnesis%TYPE
    ) RETURN table_info IS
        l_diags table_info;
    BEGIN
        IF i_id_ea IS NULL
        THEN
            l_diags := table_info();
        ELSE
            SELECT info(t.id_diagnosis, t.desc_diagnosis, NULL)
              BULK COLLECT
              INTO l_diags
              FROM (SELECT pn.id_diagnosis,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => pk_alert_constant.g_yes,
                                                      i_flg_show_term_code => pk_alert_constant.g_yes) desc_diagnosis
                      FROM progress_notes pn
                      JOIN diagnosis d
                        ON pn.id_diagnosis = d.id_diagnosis
                     WHERE pn.id_epis_anamnesis = i_id_ea
                     ORDER BY desc_diagnosis) t;
        END IF;
    
        RETURN l_diags;
    END get_coding_ea;

    /**
    * Get epis_recomend record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_er        episode recomend identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_er
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_er IN epis_recomend.id_epis_recomend%TYPE
    ) RETURN table_info IS
        l_diags table_info;
    BEGIN
        IF i_id_er IS NULL
        THEN
            l_diags := table_info();
        ELSE
            SELECT info(t.id_diagnosis, t.desc_diagnosis, NULL)
              BULK COLLECT
              INTO l_diags
              FROM (SELECT pn.id_diagnosis,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => pk_alert_constant.g_yes,
                                                      i_flg_show_term_code => pk_alert_constant.g_yes) desc_diagnosis
                      FROM progress_notes pn
                      JOIN diagnosis d
                        ON pn.id_diagnosis = d.id_diagnosis
                     WHERE pn.id_epis_recomend = i_id_er
                     ORDER BY desc_diagnosis) t;
        END IF;
    
        RETURN l_diags;
    END get_coding_er;

    /**
    * Get epis_prog_notes record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epn       episode progress notes identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_epn
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_epn IN epis_prog_notes.id_epis_prog_notes%TYPE
    ) RETURN table_info IS
        l_diags table_info;
    BEGIN
        IF i_id_epn IS NULL
        THEN
            l_diags := table_info();
        ELSE
            SELECT info(t.id_diagnosis, t.desc_diagnosis, NULL)
              BULK COLLECT
              INTO l_diags
              FROM (SELECT pn.id_diagnosis,
                           pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => pk_alert_constant.g_yes,
                                                      i_flg_show_term_code => pk_alert_constant.g_yes) desc_diagnosis
                      FROM progress_notes pn
                      JOIN diagnosis d
                        ON pn.id_diagnosis = d.id_diagnosis
                     WHERE pn.id_epis_prog_notes = i_id_epn
                     ORDER BY desc_diagnosis) t;
        END IF;
    
        RETURN l_diags;
    END get_coding_epn;

    /**
    * Checks of a clinical service has "children".
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_clin_serv    parent type of appointment identifier
    *
    * @return               'Y' if "children" exist, 'N' otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION exist_dcs_child
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_clin_serv IN clinical_service.id_clinical_service_parent%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    
        CURSOR c_dcs_child IS
            SELECT ta.id_clinical_service
              FROM (SELECT t.id_clinical_service,
                           t.id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, t.code_department) desc_department,
                           pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service
                      FROM (SELECT DISTINCT cs.id_clinical_service,
                                            dcs.id_dep_clin_serv,
                                            d.code_department,
                                            cs.code_clinical_service
                              FROM clinical_service cs
                              JOIN dep_clin_serv dcs
                                ON cs.id_clinical_service = dcs.id_clinical_service
                              JOIN department d
                                ON dcs.id_department = d.id_department
                              JOIN software_dept sd
                                ON d.id_dept = sd.id_dept
                             WHERE cs.id_clinical_service_parent = i_clin_serv
                               AND cs.flg_available = pk_alert_constant.g_yes
                               AND dcs.flg_available = pk_alert_constant.g_yes
                               AND d.flg_available = pk_alert_constant.g_yes
                               AND d.id_institution = i_prof.institution
                               AND sd.id_software = i_prof.software) t) ta
             WHERE ta.desc_department IS NOT NULL
               AND ta.desc_clinical_service IS NOT NULL;
        l_dcs_child_row c_dcs_child%ROWTYPE;
    BEGIN
        IF i_clin_serv IS NULL
           OR i_clin_serv < 1
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSE
            g_error := 'OPEN c_dcs_child';
            OPEN c_dcs_child;
            FETCH c_dcs_child
                INTO l_dcs_child_row;
            g_found := c_dcs_child%FOUND;
            CLOSE c_dcs_child;
        
            IF g_found
            THEN
                l_ret := pk_alert_constant.g_yes;
            ELSE
                l_ret := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN l_ret;
    END exist_dcs_child;

    /**
    * Get current appointment type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_parent       parent type of appointment identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_id_dcs   OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_desc_dcs OUT pk_translation.t_desc_translation,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_APPOINTMENT_TYPE';
    BEGIN
        g_error  := 'CALL get_dep_clin_serv';
        o_id_dcs := get_dep_clin_serv(i_episode => i_episode);
    
        IF o_id_dcs IS NOT NULL
           AND o_id_dcs > 0
        THEN
            g_error    := 'GET desc';
            o_desc_dcs := pk_hea_prv_aux.get_service(i_lang => i_lang, i_prof => i_prof, i_id_dep_clin_serv => o_id_dcs) ||
                          ' - ' || pk_hea_prv_aux.get_clin_service(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_dep_clin_serv => o_id_dcs);
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_appointment_type;

    /**
    * Get appointment types. Considers parenting.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_parent       parent type of appointment identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_parent  IN clinical_service.id_clinical_service_parent%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_APPOINTMENT_TYPES';
        l_id_dcs epis_info.id_dep_clin_serv%TYPE;
    BEGIN
        -- debug input
        pk_alertlog.log_debug(text            => 'i_episode: ' || i_episode || ', i_parent: ' || i_parent,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        g_error  := 'CALL get_dep_clin_serv';
        l_id_dcs := get_dep_clin_serv(i_episode => i_episode);
    
        IF i_parent IS NULL
           OR i_parent < 1
        THEN
            g_error := 'OPEN o_data (no parent)';
            OPEN o_data FOR
                SELECT ta.id_clinical_service,
                       ta.id_dep_clin_serv,
                       ta.desc_department || ' - ' || ta.desc_clinical_service desc_dep_clin_serv,
                       exist_dcs_child(i_lang, i_prof, ta.id_clinical_service) has_child,
                       decode(ta.id_dep_clin_serv, l_id_dcs, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_select
                  FROM (SELECT t.id_clinical_service,
                               t.id_dep_clin_serv,
                               pk_translation.get_translation(i_lang, t.code_department) desc_department,
                               pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service
                          FROM (SELECT cs.id_clinical_service,
                                       dcs.id_dep_clin_serv,
                                       d.code_department,
                                       cs.code_clinical_service,
                                       cs.id_clinical_service_parent
                                  FROM clinical_service cs
                                  JOIN dep_clin_serv dcs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                  JOIN department d
                                    ON dcs.id_department = d.id_department
                                  JOIN software_dept sd
                                    ON d.id_dept = sd.id_dept
                                 WHERE cs.flg_available = pk_alert_constant.g_yes
                                   AND dcs.flg_available = pk_alert_constant.g_yes
                                   AND d.flg_available = pk_alert_constant.g_yes
                                   AND d.id_institution = i_prof.institution
                                   AND sd.id_software = i_prof.software) t
             /*            WHERE t.id_clinical_service NOT IN
                               (SELECT nvl(cs.id_clinical_service_parent, 0)
                                  FROM clinical_service cs
                                  JOIN dep_clin_serv dcs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                  JOIN department d
                                    ON dcs.id_department = d.id_department
                                  JOIN software_dept sd
                                    ON d.id_dept = sd.id_dept
                                 WHERE cs.flg_available = pk_alert_constant.g_yes
                                   AND dcs.flg_available = pk_alert_constant.g_yes
                                   AND d.flg_available = pk_alert_constant.g_yes
                                   AND d.id_institution = i_prof.institution
                                   AND sd.id_software = i_prof.software)*/) ta
                 WHERE ta.desc_department IS NOT NULL
                   AND ta.desc_clinical_service IS NOT NULL
                 ORDER BY desc_dep_clin_serv;
        ELSE
            g_error := 'OPEN o_data (parent = ' || i_parent || ')';
            OPEN o_data FOR
                SELECT ta.id_clinical_service,
                       ta.id_dep_clin_serv,
                       ta.desc_department || ' - ' || ta.desc_clinical_service desc_dep_clin_serv,
                       pk_alert_constant.g_no has_child,
                       decode(ta.id_dep_clin_serv, l_id_dcs, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_select
                  FROM (SELECT t.id_clinical_service,
                               t.id_dep_clin_serv,
                               pk_translation.get_translation(i_lang, t.code_department) desc_department,
                               pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service
                          FROM (SELECT DISTINCT cs.id_clinical_service,
                                                dcs.id_dep_clin_serv,
                                                d.code_department,
                                                cs.code_clinical_service
                                  FROM clinical_service cs
                                  JOIN dep_clin_serv dcs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                  JOIN department d
                                    ON dcs.id_department = d.id_department
                                  JOIN software_dept sd
                                    ON d.id_dept = sd.id_dept
                                 WHERE cs.id_clinical_service_parent = i_parent
                                   AND cs.flg_available = pk_alert_constant.g_yes
                                   AND dcs.flg_available = pk_alert_constant.g_yes
                                   AND d.flg_available = pk_alert_constant.g_yes
                                   AND d.id_institution = i_prof.institution
                                   AND sd.id_software = i_prof.software) t) ta
                 WHERE ta.desc_department IS NOT NULL
                   AND ta.desc_clinical_service IS NOT NULL
                 ORDER BY desc_dep_clin_serv;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_appointment_types;

    /**
    * Get appointment types.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_appointment_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_APPOINTMENT_TYPES';
    BEGIN
        -- debug input
        pk_alertlog.log_debug(text            => 'i_episode: ' || i_episode,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        g_error := 'OPEN o_data';
        OPEN o_data FOR
            SELECT ta.id_clinical_service,
                   ta.id_dep_clin_serv,
                   ta.desc_department || ' - ' || ta.desc_clinical_service desc_dep_clin_serv,
                   exist_dcs_child(i_lang, i_prof, ta.id_clinical_service) has_child
              FROM (SELECT t.id_clinical_service,
                           t.id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, t.code_department) desc_department,
                           pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service
                      FROM (SELECT DISTINCT cs.id_clinical_service,
                                            dcs.id_dep_clin_serv,
                                            d.code_department,
                                            cs.code_clinical_service
                              FROM clinical_service cs
                              JOIN dep_clin_serv dcs
                                ON cs.id_clinical_service = dcs.id_clinical_service
                              JOIN department d
                                ON dcs.id_department = d.id_department
                              JOIN software_dept sd
                                ON d.id_dept = sd.id_dept
                             WHERE cs.flg_available = pk_alert_constant.g_yes
                               AND dcs.flg_available = pk_alert_constant.g_yes
                               AND d.flg_available = pk_alert_constant.g_yes
                               AND d.id_institution = i_prof.institution
                               AND sd.id_software = i_prof.software) t) ta
             WHERE ta.desc_department IS NOT NULL
               AND ta.desc_clinical_service IS NOT NULL
             ORDER BY desc_dep_clin_serv;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_appointment_types;

    /**
    * Set appointment type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_dcs          appointment identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION set_appointment_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_APPOINTMENT_TYPE';
        l_rows             table_varchar := table_varchar();
        l_clinical_service dep_clin_serv.id_clinical_service%TYPE;
    BEGIN
        -- debug input
        pk_alertlog.log_debug(text            => 'i_episode: ' || i_episode || ', i_dcs: ' || i_dcs,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        IF i_dcs IS NULL
           OR i_dcs < 1
        THEN
            g_error := 'Invalid parameter: i_dcs = ' || i_dcs;
            RAISE g_exception;
        ELSE
            g_error := 'CALL ts_epis_info.upd';
            ts_epis_info.upd(id_episode_in        => i_episode,
                             id_dep_clin_serv_in  => i_dcs,
                             id_dep_clin_serv_nin => FALSE,
                             rows_out             => l_rows);
            g_error := 'CALL t_data_gov_mnt.process_update EPIS_INFO';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_INFO',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_DEP_CLIN_SERV'));
            g_error := 'FAIL TO OBTAIN CLINICAL SERVICE';
            -- GET CLINICAL SERVICE FOR DEP_CLIN_SERV TO UPDATE EPISODE                                                              
            SELECT dcs.id_clinical_service
              INTO l_clinical_service
              FROM dep_clin_serv dcs
             WHERE dcs.id_dep_clin_serv = i_dcs;
        
            g_error := 'CALL ts_episode.upd';
            ts_episode.upd(id_episode_in           => i_episode,
                           id_clinical_service_in  => l_clinical_service,
                           id_clinical_service_nin => FALSE,
                           rows_out                => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update EPISODE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_CLINICAL_SERVICE'));
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_appointment_type;

    /**
    * Get complaints.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_use_curr_dcs use current episode's DEP_CLIN_SERV?
    * @param i_id_dcs       DEP_CLIN_SERV identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    PROCEDURE get_complaints_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_use_curr_dcs IN BOOLEAN,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_user_query   IN VARCHAR2,
        o_complaints   OUT t_tbl_complaint
    ) IS
        l_id_dcs       dep_clin_serv.id_dep_clin_serv%TYPE;
        l_sch_event    schedule.id_sch_event%TYPE;
        l_profile      profile_template.id_profile_template%TYPE;
        l_compl_column complaint.code_complaint%TYPE;
        l_gender       patient.gender%TYPE;
        l_age          patient.age%TYPE;
    BEGIN
        -- set dep_clin_serv
        IF i_id_dcs IS NULL
        THEN
            IF i_use_curr_dcs
            THEN
                g_error  := 'CALL get_dep_clin_serv';
                l_id_dcs := get_dep_clin_serv(i_episode => i_episode);
            ELSE
                l_id_dcs := NULL;
            END IF;
        ELSE
            l_id_dcs := i_id_dcs;
        END IF;
    
        g_error     := 'CALL get_sch_event';
        l_sch_event := get_sch_event(i_episode => i_episode);
        g_error     := 'CALL pk_tools.get_prof_profile_template';
        l_profile   := pk_tools.get_prof_profile_template(i_prof => i_prof);
        g_error     := 'CALL pk_patient.get_pat_info_by_episode';
        IF NOT pk_patient.get_pat_info_by_episode(i_lang    => i_lang,
                                                  i_episode => i_episode,
                                                  o_gender  => l_gender,
                                                  o_age     => l_age)
        THEN
            RAISE g_fault;
        END IF;
    
        IF i_user_query IS NULL
        THEN
            NULL;
        ELSE
            g_error := 'SELECT l_compl_column';
            SELECT pk_translation.format_column_name(c.code_complaint)
              INTO l_compl_column
              FROM complaint c
             WHERE rownum < 2;
        END IF;
    
        IF l_id_dcs IS NULL
        THEN
            IF i_user_query IS NULL
            THEN
                g_error := 'OPEN o_complaints (no dep_clin_serv and no user query)';
                SELECT t_complaint(id_complaint, desc_complaint)
                  BULK COLLECT
                  INTO o_complaints
                  FROM (SELECT cpl.id_complaint, cpl.desc_complaint
                          FROM (SELECT c.id_complaint,
                                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                                  FROM (SELECT DISTINCT t1.id_context
                                          FROM (SELECT dtc.id_context,
                                                       row_number() over(PARTITION BY dtc.id_context ORDER BY dtc.id_sch_event DESC) rn
                                                  FROM doc_template_context dtc
                                                 WHERE dtc.id_institution IN (0, i_prof.institution)
                                                   AND dtc.id_software IN (0, i_prof.software)
                                                   AND (dtc.id_profile_template = l_profile OR
                                                       dtc.id_profile_template IS NULL)
                                                   AND dtc.flg_type = pk_touch_option.g_flg_type_complaint_sch_evnt
                                                   AND dtc.id_sch_event IN (0, l_sch_event)) t1
                                         WHERE t1.rn = 1) t2
                                  JOIN complaint c
                                    ON t2.id_context = c.id_complaint
                                 WHERE c.flg_available = pk_alert_constant.g_yes
                                   AND pk_patient.validate_pat_gender(l_gender, c.flg_gender) = 1
                                   AND (c.age_min <= l_age OR c.age_min IS NULL OR l_age IS NULL)
                                   AND (c.age_max >= l_age OR c.age_max IS NULL OR l_age IS NULL)) cpl
                         ORDER BY cpl.desc_complaint);
            ELSE
                g_error := 'OPEN o_complaints (no dep_clin_serv)';
                SELECT t_complaint(id_complaint, desc_complaint)
                  BULK COLLECT
                  INTO o_complaints
                  FROM (SELECT c.id_complaint, tf.desc_translation desc_complaint
                          FROM (SELECT DISTINCT t1.id_context
                                  FROM (SELECT dtc.id_context,
                                               row_number() over(PARTITION BY dtc.id_context ORDER BY dtc.id_sch_event DESC) rn
                                          FROM doc_template_context dtc
                                         WHERE dtc.id_institution IN (0, i_prof.institution)
                                           AND dtc.id_software IN (0, i_prof.software)
                                           AND (dtc.id_profile_template = l_profile OR dtc.id_profile_template IS NULL)
                                           AND dtc.flg_type = pk_touch_option.g_flg_type_complaint_sch_evnt
                                           AND dtc.id_sch_event IN (0, l_sch_event)) t1
                                 WHERE t1.rn = 1) t2
                          JOIN complaint c
                            ON t2.id_context = c.id_complaint
                          JOIN TABLE(pk_translation.get_search_translation(i_lang, i_user_query, l_compl_column)) tf
                            ON c.code_complaint = tf.code_translation
                         WHERE c.flg_available = pk_alert_constant.g_yes
                           AND pk_patient.validate_pat_gender(l_gender, c.flg_gender) = 1
                           AND (c.age_min <= l_age OR c.age_min IS NULL OR l_age IS NULL)
                           AND (c.age_max >= l_age OR c.age_max IS NULL OR l_age IS NULL)
                         ORDER BY tf.position);
            END IF;
        ELSE
            IF i_user_query IS NULL
            THEN
                g_error := 'OPEN o_complaints (no user query)';
                SELECT t_complaint(id_complaint, desc_complaint)
                  BULK COLLECT
                  INTO o_complaints
                  FROM (SELECT c.id_complaint, pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                          FROM (SELECT DISTINCT t1.id_context
                                  FROM (SELECT dtc.id_context,
                                               row_number() over(PARTITION BY dtc.id_context ORDER BY dtc.id_sch_event DESC) rn
                                          FROM doc_template_context dtc
                                         WHERE dtc.id_institution IN (0, i_prof.institution)
                                           AND dtc.id_software IN (0, i_prof.software)
                                           AND (dtc.id_profile_template = l_profile OR dtc.id_profile_template IS NULL)
                                           AND dtc.id_dep_clin_serv = l_id_dcs
                                           AND dtc.flg_type = pk_touch_option.g_flg_type_complaint_sch_evnt
                                           AND dtc.id_sch_event IN (0, l_sch_event)) t1
                                 WHERE t1.rn = 1) t2
                          JOIN complaint c
                            ON t2.id_context = c.id_complaint
                         WHERE c.flg_available = pk_alert_constant.g_yes
                           AND pk_patient.validate_pat_gender(l_gender, c.flg_gender) = 1
                           AND (c.age_min <= l_age OR c.age_min IS NULL OR l_age IS NULL)
                           AND (c.age_max >= l_age OR c.age_max IS NULL OR l_age IS NULL)
                         ORDER BY desc_complaint);
            ELSE
                g_error := 'OPEN o_complaints';
                SELECT t_complaint(id_complaint, desc_complaint)
                  BULK COLLECT
                  INTO o_complaints
                  FROM (SELECT c.id_complaint, tf.desc_translation desc_complaint
                          FROM (SELECT DISTINCT t1.id_context
                                  FROM (SELECT dtc.id_context,
                                               row_number() over(PARTITION BY dtc.id_context ORDER BY dtc.id_sch_event DESC) rn
                                          FROM doc_template_context dtc
                                         WHERE dtc.id_institution IN (0, i_prof.institution)
                                           AND dtc.id_software IN (0, i_prof.software)
                                           AND (dtc.id_profile_template = l_profile OR dtc.id_profile_template IS NULL)
                                           AND dtc.id_dep_clin_serv = l_id_dcs
                                           AND dtc.flg_type = pk_touch_option.g_flg_type_complaint_sch_evnt
                                           AND dtc.id_sch_event IN (0, l_sch_event)) t1
                                 WHERE t1.rn = 1) t2
                          JOIN complaint c
                            ON t2.id_context = c.id_complaint
                          JOIN TABLE(pk_translation.get_search_translation(i_lang, i_user_query, l_compl_column)) tf
                            ON c.code_complaint = tf.code_translation
                         WHERE c.flg_available = pk_alert_constant.g_yes
                           AND pk_patient.validate_pat_gender(l_gender, c.flg_gender) = 1
                           AND (c.age_min <= l_age OR c.age_min IS NULL OR l_age IS NULL)
                           AND (c.age_max >= l_age OR c.age_max IS NULL OR l_age IS NULL)
                         ORDER BY tf.position);
            END IF;
        END IF;
    END get_complaints_int;

    /**
    * Get complaints for current episode's type of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_user_query IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINTS_EPIS';
    
        l_complaint t_tbl_complaint;
    
    BEGIN
        g_error := 'CALL get_complaints_int';
        get_complaints_int(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_episode      => i_episode,
                           i_use_curr_dcs => TRUE,
                           i_id_dcs       => NULL,
                           i_user_query   => i_user_query,
                           o_complaints   => l_complaint);
    
        g_error := 'OPEN O_COMPLAINTS';
        OPEN o_complaints FOR
            SELECT t.id_complaint, t.desc_complaint
              FROM TABLE(l_complaint) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaints);
            RETURN FALSE;
    END get_complaints_epis;

    /**
    * Get complaints for given type of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_dcs          appointment identifier
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_dcs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINTS_DCS';
    
        l_complaint t_tbl_complaint;
    
    BEGIN
        g_error := 'CALL get_complaints_int';
        get_complaints_int(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_episode      => i_episode,
                           i_use_curr_dcs => FALSE,
                           i_id_dcs       => i_dcs,
                           i_user_query   => NULL,
                           o_complaints   => l_complaint);
    
        g_error := 'OPEN O_COMPLAINTS';
        OPEN o_complaints FOR
            SELECT t.id_complaint, t.desc_complaint
              FROM TABLE(l_complaint) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaints);
            RETURN FALSE;
    END get_complaints_dcs;

    /**
    * Get complaints for all types of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_all
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_user_query IN VARCHAR2,
        o_complaints OUT t_tbl_complaint,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINTS_ALL';
    BEGIN
        g_error := 'CALL get_complaints_int';
        get_complaints_int(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_episode      => i_episode,
                           i_use_curr_dcs => FALSE,
                           i_id_dcs       => NULL,
                           i_user_query   => i_user_query,
                           o_complaints   => o_complaints);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complaints_all;

    /**
    * Get epis_complaint record complaints.
    *
    * @param i_lang         language identifier
    * @param i_id_ec        epis_complaint record identifier
    *
    * @return               complaints collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_ec
    (
        i_lang  IN language.id_language%TYPE,
        i_id_ec IN epis_complaint.id_epis_complaint%TYPE
    ) RETURN table_info IS
        l_complaints table_info;
    BEGIN
        IF i_id_ec IS NULL
        THEN
            l_complaints := table_info();
        ELSE
            SELECT info(t.id_complaint, t.desc_complaint, NULL)
              BULK COLLECT
              INTO l_complaints
              FROM (SELECT c.id_complaint, pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                      FROM complaint c
                      JOIN (SELECT ec1.id_complaint
                             FROM epis_complaint ec1
                            WHERE ec1.id_epis_complaint = i_id_ec
                           UNION ALL
                           SELECT ec2.id_complaint
                             FROM epis_complaint ec2
                            WHERE ec2.id_epis_complaint_root = i_id_ec) ec
                        ON c.id_complaint = ec.id_complaint
                     ORDER BY desc_complaint) t;
        END IF;
    
        RETURN l_complaints;
    END get_complaints_ec;

    /**
    * Get list of free text records.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_blk_info     blocks to retrieve records from
    * @param o_free_text    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_blk_info  IN t_coll_soap_block,
        o_free_text OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT';
    BEGIN
        IF i_blk_info IS NULL
           OR i_blk_info.count < 1
        THEN
            pk_types.open_my_cursor(i_cursor => o_free_text);
        ELSE
            g_error := 'OPEN o_free_text';
            OPEN o_free_text FOR
                SELECT blk.id_block block_id,
                       ft.id_record,
                       ft.flg_type,
                       ft.flg_status,
                       decode(ft.flg_status,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              decode(ft.id_professional, i_prof.id, pk_alert_constant.g_yes, pk_alert_constant.g_no)) flg_cancel,
                       decode(ft.flg_status,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              decode(ft.id_professional, i_prof.id, pk_alert_constant.g_yes, pk_alert_constant.g_no)) flg_write,
                       ft.text,
                       get_signature(i_lang, i_prof, ft.id_professional, ft.dt_record, i_episode) desc_prof_date,
                       get_info_id(ft.coding) id_diagnosis,
                       get_info_desc(ft.coding) desc_diagnosis,
                       pk_date_utils.date_send_tsz(i_lang, ft.dt_record, i_prof.institution, i_prof.software) dt_record,
                       ft.id_professional
                  FROM (SELECT er.id_epis_recomend id_record,
                               er.flg_type,
                               NULL id_pn_soap_block,
                               er.flg_status,
                               er.desc_epis_recomend_clob text,
                               er.id_professional,
                               er.dt_epis_recomend_tstz dt_record,
                               get_coding_er(i_lang, i_prof, er.id_epis_recomend) coding
                          FROM epis_recomend er
                         WHERE er.id_episode = i_episode
                           AND er.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                           AND er.flg_type IN (g_type_subjective, g_type_objective, g_type_assessment, g_type_plan)
                        UNION ALL
                        SELECT epn.id_epis_prog_notes id_record,
                               g_type_user_defined flg_type,
                               epn.id_pn_soap_block,
                               epn.flg_status,
                               epn.text,
                               epn.id_prof_last_update id_professional,
                               epn.dt_last_update dt_record,
                               get_coding_epn(i_lang, i_prof, epn.id_epis_prog_notes) coding
                          FROM epis_prog_notes epn
                         WHERE epn.id_episode = i_episode
                           AND epn.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) ft
                  JOIN (SELECT t.id_block, t.flg_type
                          FROM TABLE(i_blk_info) t) blk
                    ON ft.flg_type = blk.flg_type
                 WHERE ft.id_pn_soap_block IS NULL
                    OR ft.id_pn_soap_block = blk.id_block
                 ORDER BY ft.flg_status, ft.dt_record DESC;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_free_text;

    /**
    * Get free text record detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param o_detail       detail cursor
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        o_detail     OUT pk_types.cursor_type,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_DET';
        l_colon     CONSTANT VARCHAR2(2 CHAR) := ': ';
        l_enable_rep_by VARCHAR(1 CHAR);
        l_flg_type      VARCHAR(1 CHAR);
        l_id_ec         pn_epis_reason.id_epis_complaint%TYPE;
        l_id_ea         pn_epis_reason.id_epis_anamnesis%TYPE;
        l_count         PLS_INTEGER;
        l_lbl_reasons   sys_message.desc_message%TYPE;
        l_lbl_text      sys_message.desc_message%TYPE;
        l_lbl_rep_by    sys_message.desc_message%TYPE;
        l_lbl_coding    sys_message.desc_message%TYPE;
        l_lbl_canc_rea  sys_message.desc_message%TYPE;
        l_lbl_canc_not  sys_message.desc_message%TYPE;
        l_lbl_create    sys_message.desc_message%TYPE;
        l_lbl_edit      sys_message.desc_message%TYPE;
        l_lbl_cancel    sys_message.desc_message%TYPE;
    BEGIN
        -- validate input
        IF i_record IS NULL
        THEN
            g_error := 'Record identifier cannot be null!';
            RAISE g_fault;
        ELSIF i_soap_block IS NULL
        THEN
            g_error := 'Block identifier cannot be null!';
            RAISE g_fault;
        END IF;
    
        -- get screen labels
        l_lbl_reasons  := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T107') || l_colon;
        l_lbl_text     := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T108') || l_colon;
        l_lbl_rep_by   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T109') || l_colon;
        l_lbl_coding   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T110') || l_colon;
        l_lbl_canc_rea := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T111') || l_colon;
        l_lbl_canc_not := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T112') || l_colon;
        l_lbl_create   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T113') || l_colon;
        l_lbl_edit     := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T114') || l_colon;
        l_lbl_cancel   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T115') || l_colon;
    
        g_error    := 'CALL pk_progress_notes_upd.get_freetext_block_info';
        l_flg_type := pk_progress_notes_upd.get_freetext_block_info(i_lang => i_lang, i_prof => i_prof, i_soap_block => i_soap_block)
                      .flg_type;
    
        IF l_flg_type = g_type_reason_visit
        THEN
            g_error         := 'CALL get_enable_rep_by';
            l_enable_rep_by := get_enable_rep_by(i_prof => i_prof);
        
            g_error := 'OPEN o_detail (reason for visit)';
            OPEN o_detail FOR
                SELECT det.flg_status,
                       decode(det.flg_status,
                              pk_alert_constant.g_cancelled,
                              l_lbl_cancel,
                              decode(det.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                       pk_date_utils.date_char_tsz(i_lang, det.dt_record, i_prof.institution, i_prof.software) dt_record,
                       pk_tools.get_prof_description(i_lang, i_prof, det.id_professional, det.dt_record, det.id_episode) prof,
                       l_lbl_reasons label_reasons,
                       det.reasons desc_reasons,
                       l_lbl_text label_text,
                       det.text desc_text,
                       l_lbl_rep_by label_reported_by,
                       (SELECT pk_sysdomain.get_domain(g_domain_flg_rep_by, det.flg_reported_by, i_lang)
                          FROM dual) desc_reported_by,
                       l_lbl_coding label_coding,
                       det.coding desc_coding,
                       l_lbl_canc_rea label_cancel_reason,
                       (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                          FROM cancel_reason cr
                         WHERE cr.id_cancel_reason = det.id_cancel_reason) desc_cancel_reason,
                       l_lbl_canc_not label_cancel_notes,
                       det.notes_cancel_long desc_cancel_notes
                  FROM (SELECT nvl(ec.id_episode, ea.id_episode) id_episode,
                               nvl(ec.id_professional, ea.id_professional) id_professional,
                               nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record,
                               nvl(ec.flg_status, ea.flg_status) flg_status,
                               nvl(ec.id_epis_complaint_parent, ea.id_epis_anamnesis_parent) id_parent,
                               get_desc_concat(get_complaints_ec(i_lang, ec.id_epis_complaint)) reasons,
                               ea.desc_epis_anamnesis text,
                               decode(l_enable_rep_by,
                                      pk_alert_constant.g_yes,
                                      nvl(ec.flg_reported_by, ea.flg_reported_by)) flg_reported_by,
                               get_desc_concat(decode(ec.id_epis_complaint,
                                                      NULL,
                                                      get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis),
                                                      get_coding_ec(i_lang, i_prof, ec.id_epis_complaint))) coding,
                               nvl(ec_cid.id_cancel_reason, ea_cid.id_cancel_reason) id_cancel_reason,
                               nvl(ec_cid.notes_cancel_long, ea_cid.notes_cancel_long) notes_cancel_long
                          FROM pn_epis_reason per
                          LEFT JOIN epis_complaint ec
                            ON per.id_epis_complaint = ec.id_epis_complaint
                          LEFT JOIN epis_anamnesis ea
                            ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                          LEFT JOIN cancel_info_det ec_cid
                            ON ec.id_cancel_info_det = ec_cid.id_cancel_info_det
                          LEFT JOIN cancel_info_det ea_cid
                            ON ea.id_cancel_info_det = ea_cid.id_cancel_info_det
                         WHERE per.id_pn_epis_reason = i_record) det;
        
            -- get number of record changes in the new structure
            g_error := 'SELECT l_count';
            SELECT COUNT(*)
              INTO l_count
              FROM pn_epis_reason per
            CONNECT BY PRIOR per.id_parent = per.id_pn_epis_reason
             START WITH per.id_pn_epis_reason = i_record;
        
            -- get record ids
            g_error := 'OPEN c_per_ids';
            OPEN c_per_ids(i_epis_reason => i_record);
            FETCH c_per_ids
                INTO l_id_ec, l_id_ea;
            CLOSE c_per_ids;
        
            -- when no record changes exist in the new structure,
            -- and the record is made for only one area (complaint or free text),
            -- then get the record's history from the old structure...
            IF l_count < 2
               AND (l_id_ec IS NULL OR l_id_ea IS NULL)
            THEN
                pk_alertlog.log_debug(text            => 'history from old structure',
                                      object_name     => g_package_name,
                                      sub_object_name => l_func_name);
            
                g_error := 'OPEN o_history (reason for visit - old structure)';
                OPEN o_history FOR
                    SELECT hist.flg_status,
                           decode(hist.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  l_lbl_cancel,
                                  decode(hist.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                           pk_date_utils.date_char_tsz(i_lang, hist.dt_record, i_prof.institution, i_prof.software) dt_record,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         hist.id_professional,
                                                         hist.dt_record,
                                                         hist.id_episode) prof,
                           l_lbl_reasons label_reasons,
                           hist.reasons desc_reasons,
                           l_lbl_text label_text,
                           hist.text desc_text,
                           l_lbl_rep_by label_reported_by,
                           (SELECT pk_sysdomain.get_domain(g_domain_flg_rep_by, hist.flg_reported_by, i_lang)
                              FROM dual) desc_reported_by,
                           l_lbl_coding label_coding,
                           hist.coding desc_coding,
                           l_lbl_canc_rea label_cancel_reason,
                           (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                              FROM cancel_reason cr
                             WHERE cr.id_cancel_reason = hist.id_cancel_reason) desc_cancel_reason,
                           l_lbl_canc_not label_cancel_notes,
                           hist.notes_cancel_long desc_cancel_notes
                      FROM (SELECT get_desc_concat(get_complaints_ec(i_lang, ec.id_epis_complaint)) reasons,
                                   ec.id_episode,
                                   ec.id_professional,
                                   ec.adw_last_update_tstz dt_record,
                                   ec.flg_status,
                                   ec.id_epis_complaint_parent id_parent,
                                   decode(l_enable_rep_by, pk_alert_constant.g_yes, ec.flg_reported_by) flg_reported_by,
                                   NULL text,
                                   get_desc_concat(get_coding_ec(i_lang, i_prof, ec.id_epis_complaint)) coding,
                                   cid.id_cancel_reason,
                                   cid.notes_cancel_long
                              FROM epis_complaint ec
                              LEFT JOIN cancel_info_det cid
                                ON ec.id_cancel_info_det = cid.id_cancel_info_det
                            CONNECT BY PRIOR ec.id_epis_complaint_parent = ec.id_epis_complaint
                             START WITH ec.id_epis_complaint = l_id_ec
                            UNION ALL
                            SELECT NULL reasons,
                                   ea.id_episode,
                                   ea.id_professional,
                                   ea.dt_epis_anamnesis_tstz dt_record,
                                   ea.flg_status,
                                   ea.id_epis_anamnesis_parent id_parent,
                                   decode(l_enable_rep_by, pk_alert_constant.g_yes, ea.flg_reported_by) flg_reported_by,
                                   ea.desc_epis_anamnesis text,
                                   get_desc_concat(get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis)) coding,
                                   cid.id_cancel_reason,
                                   cid.notes_cancel_long
                              FROM epis_anamnesis ea
                              LEFT JOIN cancel_info_det cid
                                ON ea.id_cancel_info_det = cid.id_cancel_info_det
                            CONNECT BY PRIOR ea.id_epis_anamnesis_parent = ea.id_epis_anamnesis
                             START WITH ea.id_epis_anamnesis = l_id_ea) hist
                     ORDER BY hist.dt_record DESC;
            ELSE
                pk_alertlog.log_debug(text            => 'history from new structure',
                                      object_name     => g_package_name,
                                      sub_object_name => l_func_name);
            
                g_error := 'OPEN o_history (reason for visit - new structure)';
                OPEN o_history FOR
                    SELECT hist.flg_status,
                           decode(hist.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  l_lbl_cancel,
                                  decode(hist.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                           pk_date_utils.date_char_tsz(i_lang, hist.dt_record, i_prof.institution, i_prof.software) dt_record,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         hist.id_professional,
                                                         hist.dt_record,
                                                         hist.id_episode) prof,
                           l_lbl_reasons label_reasons,
                           hist.reasons desc_reasons,
                           l_lbl_text label_text,
                           hist.text desc_text,
                           l_lbl_rep_by label_reported_by,
                           (SELECT pk_sysdomain.get_domain(g_domain_flg_rep_by, hist.flg_reported_by, i_lang)
                              FROM dual) desc_reported_by,
                           l_lbl_coding label_coding,
                           hist.coding desc_coding,
                           l_lbl_canc_rea label_cancel_reason,
                           (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                              FROM cancel_reason cr
                             WHERE cr.id_cancel_reason = hist.id_cancel_reason) desc_cancel_reason,
                           l_lbl_canc_not label_cancel_notes,
                           hist.notes_cancel_long desc_cancel_notes
                      FROM (SELECT get_desc_concat(get_complaints_ec(i_lang, ec.id_epis_complaint)) reasons,
                                   nvl(ec.id_episode, ea.id_episode) id_episode,
                                   nvl(ec.id_professional, ea.id_professional) id_professional,
                                   nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record,
                                   nvl(ec.flg_status, ea.flg_status) flg_status,
                                   per.id_parent,
                                   decode(l_enable_rep_by,
                                          pk_alert_constant.g_yes,
                                          nvl(ec.flg_reported_by, ea.flg_reported_by)) flg_reported_by,
                                   ea.desc_epis_anamnesis text,
                                   get_desc_concat(nvl(get_coding_ec(i_lang, i_prof, ec.id_epis_complaint),
                                                       get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis))) coding,
                                   nvl(ec_cid.id_cancel_reason, ea_cid.id_cancel_reason) id_cancel_reason,
                                   nvl(ec_cid.notes_cancel_long, ea_cid.notes_cancel_long) notes_cancel_long
                              FROM (SELECT per.id_parent, per.id_epis_complaint, per.id_epis_anamnesis
                                      FROM pn_epis_reason per
                                    CONNECT BY PRIOR per.id_parent = per.id_pn_epis_reason
                                     START WITH per.id_pn_epis_reason = i_record) per
                              LEFT JOIN epis_complaint ec
                                ON per.id_epis_complaint = ec.id_epis_complaint
                              LEFT JOIN epis_anamnesis ea
                                ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                              LEFT JOIN cancel_info_det ec_cid
                                ON ec.id_cancel_info_det = ec_cid.id_cancel_info_det
                              LEFT JOIN cancel_info_det ea_cid
                                ON ea.id_cancel_info_det = ea_cid.id_cancel_info_det) hist
                     ORDER BY hist.dt_record DESC;
            END IF;
        
        ELSIF l_flg_type IN (g_type_subjective, g_type_objective, g_type_assessment, g_type_plan)
        THEN
            g_error := 'OPEN o_detail (free text record)';
            OPEN o_detail FOR
                SELECT det.flg_status,
                       decode(det.flg_status,
                              pk_alert_constant.g_cancelled,
                              l_lbl_cancel,
                              decode(det.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                       pk_date_utils.date_char_tsz(i_lang, det.dt_record, i_prof.institution, i_prof.software) dt_record,
                       pk_tools.get_prof_description(i_lang, i_prof, det.id_professional, det.dt_record, det.id_episode) prof,
                       l_lbl_text label_text,
                       det.text desc_text,
                       l_lbl_coding label_coding,
                       det.coding desc_coding,
                       l_lbl_canc_rea label_cancel_reason,
                       (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                          FROM cancel_reason cr
                         WHERE cr.id_cancel_reason = det.id_cancel_reason) desc_cancel_reason,
                       l_lbl_canc_not label_cancel_notes,
                       det.notes_cancel_long desc_cancel_notes
                  FROM (SELECT er.id_episode,
                               er.id_professional,
                               er.dt_epis_recomend_tstz dt_record,
                               er.flg_status,
                               er.id_epis_recomend_parent id_parent,
                               er.desc_epis_recomend_clob text,
                               get_desc_concat(get_coding_er(i_lang, i_prof, er.id_epis_recomend)) coding,
                               cid.id_cancel_reason,
                               cid.notes_cancel_long
                          FROM epis_recomend er
                          LEFT JOIN cancel_info_det cid
                            ON er.id_cancel_info_det = cid.id_cancel_info_det
                         WHERE er.id_epis_recomend = i_record
                           AND er.flg_type = l_flg_type
                           AND er.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) det;
        
            g_error := 'OPEN o_history (free text record)';
            OPEN o_history FOR
                SELECT hist.flg_status,
                       decode(hist.flg_status,
                              pk_alert_constant.g_cancelled,
                              l_lbl_cancel,
                              decode(hist.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                       pk_date_utils.date_char_tsz(i_lang, hist.dt_record, i_prof.institution, i_prof.software) dt_record,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     hist.id_professional,
                                                     hist.dt_record,
                                                     hist.id_episode) prof,
                       l_lbl_text label_text,
                       hist.text desc_text,
                       l_lbl_coding label_coding,
                       hist.coding desc_coding,
                       l_lbl_canc_rea label_cancel_reason,
                       (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                          FROM cancel_reason cr
                         WHERE cr.id_cancel_reason = hist.id_cancel_reason) desc_cancel_reason,
                       l_lbl_canc_not label_cancel_notes,
                       hist.notes_cancel_long desc_cancel_notes
                  FROM (SELECT er.id_episode,
                               er.id_professional,
                               er.dt_epis_recomend_tstz dt_record,
                               er.flg_status,
                               er.id_epis_recomend_parent id_parent,
                               er.desc_epis_recomend_clob text,
                               get_desc_concat(get_coding_er(i_lang, i_prof, er.id_epis_recomend)) coding,
                               cid.id_cancel_reason,
                               cid.notes_cancel_long
                          FROM epis_recomend er
                          LEFT JOIN cancel_info_det cid
                            ON er.id_cancel_info_det = cid.id_cancel_info_det
                         WHERE er.flg_type = l_flg_type
                        CONNECT BY PRIOR er.id_epis_recomend_parent = er.id_epis_recomend
                         START WITH er.id_epis_recomend = i_record) hist;
        
        ELSIF l_flg_type = g_type_user_defined
        THEN
            g_error := 'OPEN o_detail (user defined)';
            OPEN o_detail FOR
                SELECT det.flg_status,
                       decode(det.flg_status,
                              pk_alert_constant.g_cancelled,
                              l_lbl_cancel,
                              decode(det.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                       pk_date_utils.date_char_tsz(i_lang, det.dt_record, i_prof.institution, i_prof.software) dt_record,
                       pk_tools.get_prof_description(i_lang, i_prof, det.id_professional, det.dt_record, det.id_episode) prof,
                       l_lbl_text label_text,
                       det.text desc_text,
                       l_lbl_coding label_coding,
                       det.coding desc_coding,
                       l_lbl_canc_rea label_cancel_reason,
                       (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                          FROM cancel_reason cr
                         WHERE cr.id_cancel_reason = det.id_cancel_reason) desc_cancel_reason,
                       l_lbl_canc_not label_cancel_notes,
                       det.notes_cancel_long desc_cancel_notes
                  FROM (SELECT epn.id_episode,
                               epn.id_prof_last_update id_professional,
                               epn.dt_last_update dt_record,
                               epn.flg_status,
                               epn.id_epn_parent id_parent,
                               epn.text,
                               get_desc_concat(get_coding_epn(i_lang, i_prof, epn.id_epis_prog_notes)) coding,
                               cid.id_cancel_reason,
                               cid.notes_cancel_long
                          FROM epis_prog_notes epn
                          LEFT JOIN cancel_info_det cid
                            ON epn.id_cancel_info_det = cid.id_cancel_info_det
                         WHERE epn.id_epis_prog_notes = i_record
                           AND epn.id_pn_soap_block = i_soap_block
                           AND epn.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) det;
        
            g_error := 'OPEN o_history (user defined)';
            OPEN o_history FOR
                SELECT hist.flg_status,
                       decode(hist.flg_status,
                              pk_alert_constant.g_cancelled,
                              l_lbl_cancel,
                              decode(hist.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                       pk_date_utils.date_char_tsz(i_lang, hist.dt_record, i_prof.institution, i_prof.software) dt_record,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     hist.id_professional,
                                                     hist.dt_record,
                                                     hist.id_episode) prof,
                       l_lbl_text label_text,
                       hist.text desc_text,
                       l_lbl_coding label_coding,
                       hist.coding desc_coding,
                       l_lbl_canc_rea label_cancel_reason,
                       (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                          FROM cancel_reason cr
                         WHERE cr.id_cancel_reason = hist.id_cancel_reason) desc_cancel_reason,
                       l_lbl_canc_not label_cancel_notes,
                       hist.notes_cancel_long desc_cancel_notes
                  FROM (SELECT epn.id_episode,
                               epn.id_prof_last_update id_professional,
                               epn.dt_last_update dt_record,
                               epn.flg_status,
                               epn.id_epn_parent id_parent,
                               epn.text,
                               get_desc_concat(get_coding_epn(i_lang, i_prof, epn.id_epis_prog_notes)) coding,
                               cid.id_cancel_reason,
                               cid.notes_cancel_long
                          FROM epis_prog_notes epn
                          LEFT JOIN cancel_info_det cid
                            ON epn.id_cancel_info_det = cid.id_cancel_info_det
                         WHERE epn.id_pn_soap_block = i_soap_block
                        CONNECT BY PRIOR epn.id_epn_parent = epn.id_epis_prog_notes
                         START WITH epn.id_epis_prog_notes = i_record) hist;
        
        ELSE
            g_error := 'Unrecognized record type!';
            RAISE g_fault;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_free_text_det;

    /**
    * Get free text records complete detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/08
    */
    FUNCTION get_free_text_complete
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_history OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_COMPLETE';
        l_colon     CONSTANT VARCHAR2(2 CHAR) := ': ';
        l_blocks        t_coll_soap_block := t_coll_soap_block();
        l_enable_rep_by VARCHAR(1 CHAR);
        l_lbl_reasons   sys_message.desc_message%TYPE;
        l_lbl_text      sys_message.desc_message%TYPE;
        l_lbl_rep_by    sys_message.desc_message%TYPE;
        l_lbl_coding    sys_message.desc_message%TYPE;
        l_lbl_canc_rea  sys_message.desc_message%TYPE;
        l_lbl_canc_not  sys_message.desc_message%TYPE;
        l_lbl_create    sys_message.desc_message%TYPE;
        l_lbl_edit      sys_message.desc_message%TYPE;
        l_lbl_cancel    sys_message.desc_message%TYPE;
    BEGIN
        -- validate input
        IF i_episode IS NULL
        THEN
            g_error := 'Episode identifier cannot be null!';
            RAISE g_fault;
        END IF;
    
        -- get screen labels
        l_lbl_reasons  := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T107') || l_colon;
        l_lbl_text     := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T108') || l_colon;
        l_lbl_rep_by   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T109') || l_colon;
        l_lbl_coding   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T110') || l_colon;
        l_lbl_canc_rea := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T111') || l_colon;
        l_lbl_canc_not := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T112') || l_colon;
        l_lbl_create   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T113') || l_colon;
        l_lbl_edit     := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T114') || l_colon;
        l_lbl_cancel   := pk_message.get_message(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_code_mess => 'PROGRESS_NOTES_T115') || l_colon;
    
        g_error := 'CALL pk_progress_notes_upd.get_freetext_block_info';
        IF NOT pk_progress_notes_upd.get_freetext_block_info(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_episode    => i_episode,
                                                             o_soap_block => l_blocks,
                                                             o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error         := 'CALL get_enable_rep_by';
        l_enable_rep_by := get_enable_rep_by(i_prof => i_prof);
    
        g_error := 'OPEN o_history';
        OPEN o_history FOR
            SELECT blk.desc_block,
                   decode(hist.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_lbl_cancel,
                          decode(hist.id_parent, NULL, l_lbl_create, l_lbl_edit)) status,
                   pk_date_utils.date_char_tsz(i_lang, hist.dt_record, i_prof.institution, i_prof.software) dt_record,
                   pk_tools.get_prof_description(i_lang, i_prof, hist.id_professional, hist.dt_record, hist.id_episode) prof,
                   decode(hist.reasons, NULL, NULL, l_lbl_reasons || hist.reasons) desc_reasons,
                   decode(length(hist.text), 0, NULL, l_lbl_text || hist.text) desc_text,
                   decode(hist.flg_reported_by,
                          NULL,
                          NULL,
                          l_lbl_rep_by ||
                          (SELECT pk_sysdomain.get_domain(g_domain_flg_rep_by, hist.flg_reported_by, i_lang)
                             FROM dual)) desc_reported_by,
                   decode(hist.coding, NULL, NULL, l_lbl_coding || hist.coding) desc_coding,
                   decode(hist.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_lbl_canc_rea || (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                                               FROM cancel_reason cr
                                              WHERE cr.id_cancel_reason = hist.id_cancel_reason)) desc_cancel_reason,
                   decode(hist.flg_status,
                          pk_alert_constant.g_cancelled,
                          decode(length(hist.notes_cancel_long), 0, NULL, l_lbl_canc_not || hist.notes_cancel_long)) desc_cancel_notes
              FROM (SELECT connect_by_root ec.id_epis_complaint id_record,
                           g_type_reason_visit flg_type,
                           ec.id_episode,
                           ec.id_professional,
                           ec.adw_last_update_tstz dt_record,
                           ec.flg_status,
                           ec.id_epis_complaint_parent id_parent,
                           get_desc_concat(get_complaints_ec(i_lang, ec.id_epis_complaint)) reasons,
                           decode(l_enable_rep_by, pk_alert_constant.g_yes, ec.flg_reported_by) flg_reported_by,
                           NULL text,
                           get_desc_concat(get_coding_ec(i_lang, i_prof, ec.id_epis_complaint)) coding,
                           cid.id_cancel_reason,
                           cid.notes_cancel_long
                      FROM epis_complaint ec
                      LEFT JOIN cancel_info_det cid
                        ON ec.id_cancel_info_det = cid.id_cancel_info_det
                     WHERE ec.id_episode = i_episode
                    CONNECT BY PRIOR ec.id_epis_complaint = ec.id_epis_complaint_parent
                     START WITH ec.id_epis_complaint_parent IS NULL
                    UNION ALL
                    SELECT connect_by_root ea.id_epis_anamnesis id_record,
                           g_type_reason_visit flg_type,
                           ea.id_episode,
                           ea.id_professional,
                           ea.dt_epis_anamnesis_tstz dt_record,
                           ea.flg_status,
                           ea.id_epis_anamnesis_parent id_parent,
                           NULL reasons,
                           decode(l_enable_rep_by, pk_alert_constant.g_yes, ea.flg_reported_by) flg_reported_by,
                           ea.desc_epis_anamnesis text,
                           get_desc_concat(get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis)) coding,
                           cid.id_cancel_reason,
                           cid.notes_cancel_long
                      FROM epis_anamnesis ea
                      LEFT JOIN cancel_info_det cid
                        ON ea.id_cancel_info_det = cid.id_cancel_info_det
                     WHERE ea.id_episode = i_episode
                    CONNECT BY PRIOR ea.id_epis_anamnesis = ea.id_epis_anamnesis_parent
                     START WITH ea.id_epis_anamnesis_parent IS NULL
                    UNION ALL
                    SELECT connect_by_root er.id_epis_recomend id_record,
                           er.flg_type,
                           er.id_episode,
                           er.id_professional,
                           er.dt_epis_recomend_tstz dt_record,
                           er.flg_status,
                           er.id_epis_recomend_parent id_parent,
                           NULL reasons,
                           NULL flg_reported_by,
                           er.desc_epis_recomend_clob text,
                           get_desc_concat(get_coding_er(i_lang, i_prof, er.id_epis_recomend)) coding,
                           cid.id_cancel_reason,
                           cid.notes_cancel_long
                      FROM epis_recomend er
                      LEFT JOIN cancel_info_det cid
                        ON er.id_cancel_info_det = cid.id_cancel_info_det
                     WHERE er.id_episode = i_episode
                    CONNECT BY PRIOR er.id_epis_recomend = er.id_epis_recomend_parent
                     START WITH er.id_epis_recomend_parent IS NULL
                    UNION ALL
                    SELECT connect_by_root epn.id_epis_prog_notes id_record,
                           g_type_user_defined flg_type,
                           epn.id_episode,
                           epn.id_prof_last_update id_professional,
                           epn.dt_last_update dt_record,
                           epn.flg_status,
                           epn.id_epn_parent id_parent,
                           NULL reasons,
                           NULL flg_reported_by,
                           epn.text,
                           get_desc_concat(get_coding_epn(i_lang, i_prof, epn.id_epis_prog_notes)) coding,
                           cid.id_cancel_reason,
                           cid.notes_cancel_long
                      FROM epis_prog_notes epn
                      LEFT JOIN cancel_info_det cid
                        ON epn.id_cancel_info_det = cid.id_cancel_info_det
                     WHERE epn.id_episode = i_episode
                    CONNECT BY PRIOR epn.id_epis_prog_notes = epn.id_epn_parent
                     START WITH epn.id_epn_parent IS NULL) hist
              JOIN (SELECT t.id_block, t.desc_block, t.flg_type, t.rank
                      FROM TABLE(l_blocks) t) blk
                ON hist.flg_type = blk.flg_type
             ORDER BY blk.rank, hist.id_record, hist.dt_record;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_free_text_complete;

    /**
    * Get free text records of a given area.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_soap_block   block identifier
    * @param i_inc_cancel   include cancelled records? Y/N
    * @param o_free_text    detail cursor
    * @param o_warning      user warning
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_area
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_inc_cancel IN VARCHAR2,
        o_free_text  OUT pk_types.cursor_type,
        o_warning    OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_AREA';
        l_flg_type  VARCHAR(1 CHAR);
        l_rec_count PLS_INTEGER := 0;
    BEGIN
        -- validate input
        IF i_soap_block IS NULL
        THEN
            g_error := 'Block identifier cannot be null!';
            RAISE g_fault;
        END IF;
    
        -- get area type
        g_error    := 'CALL pk_progress_notes_upd.get_freetext_block_info';
        l_flg_type := pk_progress_notes_upd.get_freetext_block_info(i_lang => i_lang, i_prof => i_prof, i_soap_block => i_soap_block)
                      .flg_type;
    
        pk_alertlog.log_debug(text            => 'i_inc_cancel: ' || i_inc_cancel || ', l_flg_type: ' || l_flg_type,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- given the area, count available records
        -- if records are available, open the records cursor
        IF l_flg_type = g_type_reason_visit
        THEN
            g_error := 'SELECT l_rec_count (' || l_flg_type || ')';
            SELECT COUNT(*)
              INTO l_rec_count
              FROM pn_epis_reason per
             WHERE per.id_episode = i_episode
               AND (per.flg_status = pk_alert_constant.g_active OR
                   (per.flg_status = pk_alert_constant.g_cancelled AND i_inc_cancel = pk_alert_constant.g_yes));
        
            IF l_rec_count > 0
            THEN
                g_error := 'OPEN o_free_text (reason for visit)';
                OPEN o_free_text FOR
                    SELECT ft.id_record,
                           pk_tools.get_prof_description(i_lang, i_prof, ft.id_professional, ft.dt_record, i_episode) prof,
                           pk_date_utils.date_char_tsz(i_lang, ft.dt_record, i_prof.institution, i_prof.software) dt_record,
                           ft.text,
                           get_info_id(ft.coding) id_diagnosis,
                           get_info_desc(ft.coding) desc_diagnosis
                      FROM (SELECT per.id_pn_epis_reason id_record,
                                   nvl(ec.id_professional, ea.id_professional) id_professional,
                                   nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record,
                                   
                                   get_desc_concat(get_complaints_ec(i_lang, per.id_epis_complaint)) ||
                                   decode(length(ea.desc_epis_anamnesis),
                                          0,
                                          NULL,
                                          decode(per.id_epis_complaint, NULL, NULL, chr(10)) || ea.desc_epis_anamnesis) text,
                                   
                                   decode(ec.id_epis_complaint,
                                          NULL,
                                          get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis),
                                          get_coding_ec(i_lang, i_prof, ec.id_epis_complaint)) coding
                              FROM pn_epis_reason per
                              LEFT JOIN epis_complaint ec
                                ON per.id_epis_complaint = ec.id_epis_complaint
                              LEFT JOIN epis_anamnesis ea
                                ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                             WHERE per.id_episode = i_episode
                               AND (per.flg_status = pk_alert_constant.g_active OR
                                   (per.flg_status = pk_alert_constant.g_cancelled AND
                                   i_inc_cancel = pk_alert_constant.g_yes))) ft
                     ORDER BY ft.dt_record DESC;
            END IF;
        ELSIF l_flg_type IN (g_type_subjective, g_type_objective, g_type_assessment, g_type_plan)
        THEN
            g_error := 'SELECT l_rec_count (' || l_flg_type || ')';
            SELECT COUNT(*)
              INTO l_rec_count
              FROM epis_recomend er
             WHERE er.id_episode = i_episode
               AND er.flg_type = l_flg_type
               AND (er.flg_status = pk_alert_constant.g_active OR
                   (er.flg_status = pk_alert_constant.g_cancelled AND i_inc_cancel = pk_alert_constant.g_yes));
        
            IF l_rec_count > 0
            THEN
                g_error := 'OPEN o_free_text (free text record)';
                OPEN o_free_text FOR
                    SELECT ft.id_record,
                           pk_tools.get_prof_description(i_lang, i_prof, ft.id_professional, ft.dt_record, i_episode) prof,
                           pk_date_utils.date_char_tsz(i_lang, ft.dt_record, i_prof.institution, i_prof.software) dt_record,
                           ft.text,
                           get_info_id(ft.coding) id_diagnosis,
                           get_info_desc(ft.coding) desc_diagnosis
                      FROM (SELECT er.id_epis_recomend id_record,
                                   er.id_professional,
                                   er.dt_epis_recomend_tstz dt_record,
                                   er.desc_epis_recomend_clob text,
                                   get_coding_er(i_lang, i_prof, er.id_epis_recomend) coding
                              FROM epis_recomend er
                             WHERE er.id_episode = i_episode
                               AND er.flg_type = l_flg_type
                               AND (er.flg_status = pk_alert_constant.g_active OR
                                   (er.flg_status = pk_alert_constant.g_cancelled AND
                                   i_inc_cancel = pk_alert_constant.g_yes))) ft
                     ORDER BY ft.dt_record DESC;
            END IF;
        ELSIF l_flg_type = g_type_user_defined
        THEN
            g_error := 'SELECT l_rec_count (' || l_flg_type || ')';
            SELECT COUNT(*)
              INTO l_rec_count
              FROM epis_prog_notes epn
             WHERE epn.id_episode = i_episode
               AND epn.id_pn_soap_block = i_soap_block
               AND (epn.flg_status = pk_alert_constant.g_active OR
                   (epn.flg_status = pk_alert_constant.g_cancelled AND i_inc_cancel = pk_alert_constant.g_yes));
        
            IF l_rec_count > 0
            THEN
                g_error := 'OPEN o_free_text (user defined)';
                OPEN o_free_text FOR
                    SELECT ft.id_record,
                           pk_tools.get_prof_description(i_lang, i_prof, ft.id_professional, ft.dt_record, i_episode) prof,
                           pk_date_utils.date_char_tsz(i_lang, ft.dt_record, i_prof.institution, i_prof.software) dt_record,
                           ft.text,
                           get_info_id(ft.coding) id_diagnosis,
                           get_info_desc(ft.coding) desc_diagnosis
                      FROM (SELECT epn.id_epis_prog_notes id_record,
                                   epn.id_prof_last_update id_professional,
                                   epn.dt_last_update dt_record,
                                   epn.text,
                                   get_coding_epn(i_lang, i_prof, epn.id_epis_prog_notes) coding
                              FROM epis_prog_notes epn
                             WHERE epn.id_episode = i_episode
                               AND epn.id_pn_soap_block = i_soap_block
                               AND (epn.flg_status = pk_alert_constant.g_active OR
                                   (epn.flg_status = pk_alert_constant.g_cancelled AND
                                   i_inc_cancel = pk_alert_constant.g_yes))) ft
                     ORDER BY ft.dt_record DESC;
            END IF;
        ELSE
            g_error := 'Unrecognized record type!';
            RAISE g_fault;
        END IF;
    
        pk_alertlog.log_debug(text            => 'l_rec_count: ' || l_rec_count,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- if no records are available, set user warning
        IF l_rec_count < 1
        THEN
            pk_types.open_my_cursor(i_cursor => o_free_text);
            o_warning := table_varchar(pk_message.get_message(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_code_mess => 'COMMON_T013'),
                                       pk_message.get_message(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_code_mess => 'PROGRESS_NOTES_M009'));
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_free_text_area;

    /**
    * Set free text for subjective, objective, assessment and plan blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_flg_type     record type
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_id_er        created record identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/13
    */
    PROCEDURE set_free_text_er
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN epis_recomend.flg_type%TYPE,
        i_record   IN epis_recomend.id_epis_recomend%TYPE,
        i_text     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_id_er    OUT epis_recomend.id_epis_recomend%TYPE,
        o_error    OUT t_error_out
    ) IS
        l_id_er_new   epis_recomend.id_epis_recomend%TYPE;
        l_pn_row_coll ts_progress_notes.progress_notes_tc;
        l_rowids      table_varchar := table_varchar();
    BEGIN
        IF i_reason IS NULL
        THEN
            -- create new record
            g_error := 'CALL pk_discharge.set_epis_recomend_int';
            IF NOT pk_discharge.set_epis_recomend_int(i_lang             => i_lang,
                                                      i_episode          => i_episode,
                                                      i_prof             => i_prof,
                                                      i_patient          => i_patient,
                                                      i_flg_type         => i_flg_type,
                                                      i_desc             => i_text,
                                                      i_parent           => i_record,
                                                      o_id_epis_recomend => l_id_er_new,
                                                      o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            -- cancel record
            g_error := 'CALL pk_discharge.set_epis_recomend_int';
            IF NOT pk_discharge.set_epis_recomend_cancel_int(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_epis_rec => i_record,
                                                             i_reason   => i_reason,
                                                             i_notes    => i_notes,
                                                             o_epis_rec => l_id_er_new,
                                                             o_error    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- copy coding
        IF i_record IS NOT NULL
        THEN
            g_error := 'SELECT l_pn_row_coll (er)';
            SELECT pn.*
              BULK COLLECT
              INTO l_pn_row_coll
              FROM progress_notes pn
             WHERE pn.id_epis_recomend = i_record;
        
            IF l_pn_row_coll IS NOT NULL
               AND l_pn_row_coll.count > 0
            THEN
                FOR i IN l_pn_row_coll.first .. l_pn_row_coll.last
                LOOP
                    l_pn_row_coll(i).id_progress_notes := ts_progress_notes.next_key;
                    l_pn_row_coll(i).id_epis_recomend := l_id_er_new;
                END LOOP;
            
                l_rowids := table_varchar();
                g_error  := 'CALL ts_progress_notes.ins';
                ts_progress_notes.ins(rows_in => l_pn_row_coll, rows_out => l_rowids);
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PROGRESS_NOTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        o_id_er := l_id_er_new;
    END set_free_text_er;

    PROCEDURE set_free_text_ed
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_record   IN epis_documentation.id_epis_documentation%TYPE,
        i_text     IN epis_documentation.notes%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_id_ed    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error    OUT t_error_out
    ) IS
        l_id_ed_new   epis_recomend.id_epis_recomend%TYPE;
        l_pn_row_coll ts_progress_notes.progress_notes_tc;
        l_rowids      table_varchar := table_varchar();
        l_prof_cat    category.flg_type%TYPE;
    BEGIN
    
        IF i_reason IS NULL
        THEN
            -- create new record        
            IF NOT pk_touch_option.set_epis_documentation(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_prof_cat_type         => i_prof_cat,
                                                     i_epis                  => i_episode,
                                                     i_doc_area              => i_doc_area,
                                                     i_doc_template          => NULL,
                                                     i_epis_documentation    => i_record,
                                                     i_flg_type              => CASE
                                                                                    WHEN i_record IS NULL THEN
                                                                                     'N'
                                                                                    ELSE
                                                                                     'E'
                                                                                END,
                                                     i_id_documentation      => table_number(),
                                                     i_id_doc_element        => NULL,
                                                     i_id_doc_element_crit   => NULL,
                                                     i_value                 => NULL,
                                                     i_notes                 => i_text, --13
                                                     i_id_doc_element_qualif => table_table_number(),
                                                     i_epis_context          => NULL,
                                                     i_summary_and_notes     => i_text,
                                                     i_episode_context       => NULL,
                                                     i_flg_table_origin      => pk_touch_option.g_flg_tab_origin_epis_doc,
                                                     i_vs_element_list       => NULL,
                                                     i_vs_save_mode_list     => NULL,
                                                     i_vs_list               => NULL,
                                                     i_vs_value_list         => NULL,
                                                     i_vs_uom_list           => NULL,
                                                     i_vs_scales_list        => NULL,
                                                     i_vs_date_list          => NULL,
                                                     i_vs_read_list          => NULL,
                                                     o_epis_documentation    => l_id_ed_new,
                                                     o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        o_id_ed := l_id_ed_new;
    END set_free_text_ed;

    /**
    * Set free text for user defined blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_id_epn       created record identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/13
    */
    PROCEDURE set_free_text_epn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN epis_prog_notes.id_epis_prog_notes%TYPE,
        i_text       IN epis_prog_notes.text%TYPE,
        i_reason     IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_long%TYPE,
        o_id_epn     OUT epis_prog_notes.id_epis_prog_notes%TYPE,
        o_error      OUT t_error_out
    ) IS
        l_id_epn_new  epis_prog_notes.id_epis_prog_notes%TYPE;
        l_id_cid      cancel_info_det.id_cancel_info_det%TYPE;
        l_pn_row_coll ts_progress_notes.progress_notes_tc;
        l_rowids      table_varchar := table_varchar();
    BEGIN
        IF i_record IS NOT NULL
        THEN
            -- outdate existing record
            l_rowids := table_varchar();
            g_error  := 'CALL ts_epis_prog_notes.upd';
            ts_epis_prog_notes.upd(id_epis_prog_notes_in   => i_record,
                                   flg_status_in           => pk_alert_constant.g_outdated,
                                   flg_status_nin          => FALSE,
                                   id_prof_last_update_in  => i_prof.id,
                                   id_prof_last_update_nin => FALSE,
                                   dt_last_update_in       => g_sysdate_tstz,
                                   dt_last_update_nin      => FALSE,
                                   rows_out                => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_PROG_NOTES',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_LAST_UPDATE',
                                                                          'DT_LAST_UPDATE'));
        END IF;
    
        IF i_reason IS NULL
        THEN
            -- create new record
            l_rowids := table_varchar();
            g_error  := 'CALL ts_epis_prog_notes.ins I';
            ts_epis_prog_notes.ins(id_episode_in          => i_episode,
                                   id_pn_soap_block_in    => i_soap_block,
                                   flg_status_in          => pk_alert_constant.g_active,
                                   text_in                => i_text,
                                   id_prof_created_in     => i_prof.id,
                                   dt_created_in          => g_sysdate_tstz,
                                   id_prof_last_update_in => i_prof.id,
                                   dt_last_update_in      => g_sysdate_tstz,
                                   id_epn_parent_in       => i_record,
                                   id_epis_prog_notes_out => l_id_epn_new,
                                   rows_out               => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert I';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_PROG_NOTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            -- cancel record
            -- create cancel information
            l_rowids := table_varchar();
            g_error  := 'CALL ts_cancel_info_det.ins';
            ts_cancel_info_det.ins(id_prof_cancel_in        => i_prof.id,
                                   id_cancel_reason_in      => i_reason,
                                   dt_cancel_in             => g_sysdate_tstz,
                                   notes_cancel_long_in     => i_notes,
                                   flg_notes_cancel_type_in => CASE
                                                                   WHEN i_notes IS NULL THEN
                                                                    NULL
                                                                   ELSE
                                                                    g_long_notes
                                                               END,
                                   id_cancel_info_det_out   => l_id_cid,
                                   rows_out                 => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert II';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CANCEL_INFO_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- cancel epis_prog_notes
            l_rowids := table_varchar();
            g_error  := 'CALL ts_epis_prog_notes.ins II';
            ts_epis_prog_notes.ins(id_episode_in          => i_episode,
                                   id_pn_soap_block_in    => i_soap_block,
                                   flg_status_in          => pk_alert_constant.g_cancelled,
                                   text_in                => i_text,
                                   id_prof_created_in     => i_prof.id,
                                   dt_created_in          => g_sysdate_tstz,
                                   id_prof_last_update_in => i_prof.id,
                                   dt_last_update_in      => g_sysdate_tstz,
                                   id_cancel_info_det_in  => l_id_cid,
                                   id_epn_parent_in       => i_record,
                                   id_epis_prog_notes_out => l_id_epn_new,
                                   rows_out               => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert III';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_PROG_NOTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        -- copy coding
        IF i_record IS NOT NULL
        THEN
            g_error := 'SELECT l_pn_row_coll (epn)';
            SELECT pn.*
              BULK COLLECT
              INTO l_pn_row_coll
              FROM progress_notes pn
             WHERE pn.id_epis_prog_notes = i_record;
        
            IF l_pn_row_coll IS NOT NULL
               AND l_pn_row_coll.count > 0
            THEN
                FOR i IN l_pn_row_coll.first .. l_pn_row_coll.last
                LOOP
                    l_pn_row_coll(i).id_progress_notes := ts_progress_notes.next_key;
                    l_pn_row_coll(i).id_epis_prog_notes := l_id_epn_new;
                END LOOP;
            
                l_rowids := table_varchar();
                g_error  := 'CALL ts_progress_notes.ins';
                ts_progress_notes.ins(rows_in => l_pn_row_coll, rows_out => l_rowids);
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PROGRESS_NOTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        o_id_epn := l_id_epn_new;
    END set_free_text_epn;

    /**
    * Cancels record from free text data blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_free_text_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        i_reason     IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_FREE_TEXT_CANCEL';
        l_flg_type    VARCHAR2(1 CHAR);
        l_id_er_prev  epis_recomend.id_epis_recomend%TYPE;
        l_id_epn_prev epis_prog_notes.id_epis_prog_notes%TYPE;
        l_id_er_new   epis_recomend.id_epis_recomend%TYPE;
        l_id_epn_new  epis_prog_notes.id_epis_prog_notes%TYPE;
        l_text_er     epis_recomend.desc_epis_recomend_clob%TYPE;
        l_text_epn    epis_prog_notes.text%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate input
        IF i_record IS NULL
        THEN
            g_error := 'Record identifier cannot be null!';
            RAISE g_fault;
        ELSIF i_soap_block IS NULL
        THEN
            g_error := 'Block identifier cannot be null!';
            RAISE g_fault;
        END IF;
    
        -- debug input
        pk_alertlog.log_debug(text            => 'i_soap_block: ' || i_soap_block || ', i_record: ' || i_record,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        g_error    := 'CALL pk_progress_notes_upd.get_freetext_block_info';
        l_flg_type := pk_progress_notes_upd.get_freetext_block_info(i_lang => i_lang, i_prof => i_prof, i_soap_block => i_soap_block)
                      .flg_type;
    
        -- debug block info
        pk_alertlog.log_debug(text            => 'l_flg_type: ' || l_flg_type,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        IF l_flg_type IN (g_type_subjective, g_type_objective, g_type_assessment, g_type_plan)
        THEN
            l_id_er_prev := i_record;
        
            g_error := 'SELECT l_text_er';
            SELECT er.desc_epis_recomend_clob
              INTO l_text_er
              FROM epis_recomend er
             WHERE er.id_epis_recomend = l_id_er_prev;
        
            g_error := 'CALL set_free_text_er';
            set_free_text_er(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_episode  => i_episode,
                             i_patient  => i_patient,
                             i_flg_type => l_flg_type,
                             i_record   => l_id_er_prev,
                             i_text     => l_text_er,
                             i_reason   => i_reason,
                             i_notes    => i_notes,
                             o_id_er    => l_id_er_new,
                             o_error    => o_error);
        ELSIF l_flg_type = g_type_user_defined
        THEN
            l_id_epn_prev := i_record;
        
            g_error := 'SELECT l_text_epn';
            SELECT epn.text
              INTO l_text_epn
              FROM epis_prog_notes epn
             WHERE epn.id_epis_prog_notes = l_id_epn_prev;
        
            g_error := 'CALL set_free_text_epn';
            set_free_text_epn(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_episode    => i_episode,
                              i_soap_block => i_soap_block,
                              i_record     => l_id_epn_prev,
                              i_text       => l_text_epn,
                              i_reason     => i_reason,
                              i_notes      => i_notes,
                              o_id_epn     => l_id_epn_new,
                              o_error      => o_error);
        ELSE
            g_error := 'Unrecognized free text data block info: ' || nvl(l_flg_type, 'NULL');
            RAISE g_fault;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_free_text_cancel;

    /**
    * Stores user input from free text data blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_blocks  block identifiers list
    * @param i_records      record identifiers list
    * @param i_texts        texts list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_free_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_soap_blocks IN table_number,
        i_records     IN table_number,
        i_texts       IN table_clob,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_FREE_TEXT';
        l_flg_type VARCHAR2(1 CHAR);
        l_id_er    epis_recomend.id_epis_recomend%TYPE;
        l_id_ed    epis_documentation.id_epis_documentation%TYPE;
        l_id_epn   epis_prog_notes.id_epis_prog_notes%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- debug input
        pk_alertlog.log_debug(text            => 'i_soap_blocks: ' || pk_utils.to_string(i_input => i_soap_blocks) ||
                                                 ', i_records: ' || pk_utils.to_string(i_input => i_records),
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        IF i_soap_blocks IS NULL
           OR i_soap_blocks.count < 1
        THEN
            g_error := 'No blocks were specified!';
            RAISE g_fault;
        ELSE
            FOR i IN i_soap_blocks.first .. i_soap_blocks.last
            LOOP
                g_error    := 'CALL pk_progress_notes_upd.get_freetext_block_info';
                l_flg_type := pk_progress_notes_upd.get_freetext_block_info(i_lang => i_lang, i_prof => i_prof, i_soap_block => i_soap_blocks(i))
                              .flg_type;
            
                -- debug block info
                pk_alertlog.log_debug(text            => 'l_flg_type: ' || l_flg_type,
                                      object_name     => g_package_name,
                                      sub_object_name => l_func_name);
            
                IF l_flg_type IN (g_type_subjective, g_type_objective, g_type_assessment)
                THEN
                    g_error := 'CALL set_free_text_er';
                    set_free_text_er(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     i_episode  => i_episode,
                                     i_patient  => i_patient,
                                     i_flg_type => l_flg_type,
                                     i_record   => i_records(i),
                                     i_text     => i_texts(i),
                                     i_reason   => NULL,
                                     i_notes    => NULL,
                                     o_id_er    => l_id_er,
                                     o_error    => o_error);
                ELSIF l_flg_type = g_type_plan
                THEN
                    g_error := 'CALL set_free_text_epn';
                    set_free_text_ed(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     i_prof_cat => i_prof_cat,
                                     i_episode  => i_episode,
                                     i_patient  => i_patient,
                                     i_doc_area => pk_summary_page.g_doc_area_plan,
                                     i_record   => i_records(i),
                                     i_text     => i_texts(i),
                                     i_reason   => NULL,
                                     i_notes    => NULL,
                                     o_id_ed    => l_id_ed,
                                     o_error    => o_error);
                
                ELSIF l_flg_type = g_type_user_defined
                THEN
                    g_error := 'CALL set_free_text_epn';
                    set_free_text_epn(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_episode    => i_episode,
                                      i_soap_block => i_soap_blocks(i),
                                      i_record     => i_records(i),
                                      i_text       => i_texts(i),
                                      i_reason     => NULL,
                                      i_notes      => NULL,
                                      o_id_epn     => l_id_epn,
                                      o_error      => o_error);
                ELSE
                    g_error := 'Unrecognized free text data block info: ' || nvl(l_flg_type, 'NULL');
                    RAISE g_fault;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_free_text;

    /**
    * Updates episode templates.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_id_ec        episode complaint root identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/10
    */
    PROCEDURE set_templates
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_id_ec   IN epis_complaint.id_epis_complaint%TYPE,
        o_error   OUT t_error_out
    ) IS
        l_id_dcs     epis_info.id_dep_clin_serv%TYPE;
        l_sch_event  schedule.id_sch_event%TYPE;
        l_profile    profile_template.id_profile_template%TYPE;
        l_complaints table_number := table_number();
        l_templates  table_number := table_number();
        l_edt_prev   table_number := table_number();
        l_edt_new    table_number := table_number();
        l_count      PLS_INTEGER;
        l_gender     patient.gender%TYPE;
        l_age        patient.age%TYPE;
    
        CURSOR c_complaint IS
            SELECT ec.id_complaint
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode
               AND ec.flg_status = pk_alert_constant.g_active;
    
        CURSOR c_template IS
            SELECT tpl.id_doc_template
              FROM (SELECT dtc.id_doc_template,
                           row_number() over(PARTITION BY dtc.id_doc_template ORDER BY dtc.id_sch_event DESC) rn
                      FROM doc_template_context dtc
                      JOIN doc_template dt
                        ON dtc.id_doc_template = dt.id_doc_template
                     WHERE dtc.id_institution IN (0, i_prof.institution)
                       AND dtc.id_software IN (0, i_prof.software)
                       AND (dtc.id_profile_template = l_profile OR dtc.id_profile_template IS NULL)
                       AND dtc.id_dep_clin_serv = l_id_dcs
                       AND dtc.id_context IN (SELECT /*+opt_estimate(table t rows=1)*/
                                               t.column_value id_complaint
                                                FROM TABLE(l_complaints) t)
                       AND dtc.flg_type = pk_touch_option.g_flg_type_complaint_sch_evnt
                       AND dtc.id_sch_event IN (0, l_sch_event)
                       AND dt.flg_available = pk_alert_constant.g_yes
                       AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                       AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                       AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)) tpl
             WHERE tpl.rn = 1;
    
        CURSOR c_edt_prev IS
            SELECT edt.id_epis_doc_template
              FROM epis_doc_template edt
             WHERE edt.id_episode = i_episode
               AND edt.id_prof_cancel IS NULL;
    BEGIN
        g_error     := 'CALL get_dep_clin_serv';
        l_id_dcs    := get_dep_clin_serv(i_episode => i_episode);
        g_error     := 'CALL get_sch_event';
        l_sch_event := get_sch_event(i_episode => i_episode);
        g_error     := 'CALL pk_tools.get_prof_profile_template';
        l_profile   := pk_tools.get_prof_profile_template(i_prof => i_prof);
        g_error     := 'CALL pk_patient.get_pat_info_by_patient';
        IF NOT pk_patient.get_pat_info_by_patient(i_lang    => i_lang,
                                                  i_patient => i_patient,
                                                  o_gender  => l_gender,
                                                  o_age     => l_age)
        THEN
            RAISE g_fault;
        END IF;
    
        -- get complaints
        g_error := 'OPEN c_complaint';
        OPEN c_complaint;
        FETCH c_complaint BULK COLLECT
            INTO l_complaints;
        CLOSE c_complaint;
    
        IF l_complaints IS NULL
           OR l_complaints.count < 1
        THEN
            -- the user specified no reasons for visit
            g_error := 'SELECT l_count';
            SELECT COUNT(*)
              INTO l_count
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode;
        
            IF l_count < 1
            THEN
                -- the user never specified reasons for visit:
                -- do not change the episode's templates!
                NULL;
            ELSE
                -- the user had already specified reasons for visit,
                -- which he now "disabled", by editing/cancelling the record:
                -- set the default templates for the episode!
                g_error := 'CALL pk_touch_option.set_default_epis_doc_templates';
                IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_episode            => i_episode,
                                                                      i_flg_type           => pk_touch_option.g_flg_type_appointment,
                                                                      o_epis_doc_templates => l_edt_new,
                                                                      o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        ELSE
            -- get applicable templates for episode reason
            g_error := 'OPEN c_template';
            OPEN c_template;
            FETCH c_template BULK COLLECT
                INTO l_templates;
            CLOSE c_template;
        
            -- get active templates in episode
            g_error := 'OPEN c_edt_prev';
            OPEN c_edt_prev;
            FETCH c_edt_prev BULK COLLECT
                INTO l_edt_prev;
            CLOSE c_edt_prev;
        
            -- update episode templates
            g_error := 'CALL pk_touch_option.set_epis_doc_templ_no_commit';
            IF NOT pk_touch_option.set_epis_doc_templ_no_commit(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_episode               => i_episode,
                                                                i_doc_template_in       => l_templates,
                                                                i_epis_doc_template_out => l_edt_prev,
                                                                i_doc_area              => NULL,
                                                                o_epis_doc_template     => l_edt_new,
                                                                o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- set complaint root and clear profile
            IF l_edt_new IS NOT NULL
               AND l_edt_new.count > 0
            THEN
                g_error := 'UPDATE epis_doc_template';
                FORALL i IN l_edt_new.first .. l_edt_new.last
                    UPDATE epis_doc_template edt
                       SET edt.id_epis_complaint = i_id_ec, edt.id_profile_template = NULL
                     WHERE edt.id_epis_doc_template = l_edt_new(i);
            END IF;
        END IF;
    END set_templates;

    /**
    * Get list of reason for visit records.
    * Used in pk_prev_encounter.
    *
    * @param i_lang         language identifier
    * @param i_episode      episode identifier
    * @param o_rea_visit    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_rea_visit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_REASON_FOR_VISIT';
    BEGIN
        g_error := 'OPEN o_rea_visit';
        OPEN o_rea_visit FOR
            SELECT to_clob(get_desc_concat(get_complaints_ec(i_lang, per.id_epis_complaint))) || CASE
                        WHEN length(ea.desc_epis_anamnesis) = 0 THEN
                         NULL
                        ELSE
                         decode(per.id_epis_complaint, NULL, NULL, chr(10)) || ea.desc_epis_anamnesis
                    END description,
                   nvl(ec.id_professional, ea.id_professional) id_professional,
                   nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record
              FROM pn_epis_reason per
              LEFT JOIN epis_complaint ec
                ON per.id_epis_complaint = ec.id_epis_complaint
              LEFT JOIN epis_anamnesis ea
                ON per.id_epis_anamnesis = ea.id_epis_anamnesis
             WHERE per.id_episode = i_episode
               AND per.flg_status = pk_alert_constant.g_active
             ORDER BY dt_record DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_reason_for_visit;

    /**
    * Internal function to open o_rea_visit.
    * Used in the reports layer as well.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_show_block   show reason for visit block? Y/N
    * @param o_rea_visit    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/30
    */
    FUNCTION get_reason_for_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_show_block     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_cancelled IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_rea_visit      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_REASON_FOR_VISIT';
        l_owner all_objects.owner%TYPE;
        l_line  NUMBER;
        l_type  user_objects.object_type%TYPE;
    BEGIN
    
        -- check if reported by is enabled
        g_error := 'CALL get_enable_rep_by';
    
        g_error := 'OPEN o_rea_visit';
        OPEN o_rea_visit FOR
            SELECT ft.id_record,
                   ft.flg_type,
                   ft.flg_status,
                   decode(ft.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_cancel,
                   decode(ft.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_write,
                   ft.text,
                   get_signature(i_lang, i_prof, ft.id_professional, ft.dt_record, i_episode) desc_prof_date,
                   get_info_id(ft.coding) id_diagnosis,
                   get_info_desc(ft.coding) desc_diagnosis,
                   get_info_id(ft.complaint) id_complaint,
                   get_info_desc(ft.complaint) desc_complaint,
                   ft.flg_reported_by,
                   (SELECT pk_sysdomain.get_domain(g_domain_flg_rep_by, ft.flg_reported_by, i_lang)
                      FROM dual) desc_reported_by,
                   ft.description,
                   pk_date_utils.date_send_tsz(i_lang, ft.dt_record, i_prof) dt_record,
                   ft.id_professional
              FROM (SELECT per.id_pn_epis_reason id_record,
                           g_type_reason_visit flg_type,
                           NULL id_pn_soap_block,
                           nvl(ec.flg_status, ea.flg_status) flg_status,
                           ea.desc_epis_anamnesis text,
                           nvl(ec.id_professional, ea.id_professional) id_professional,
                           nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record,
                           decode(ec.id_epis_complaint,
                                  NULL,
                                  get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis),
                                  get_coding_ec(i_lang, i_prof, ec.id_epis_complaint)) coding,
                           get_complaints_ec(i_lang, ec.id_epis_complaint) complaint,
                           nvl(ec.flg_reported_by, ea.flg_reported_by) flg_reported_by,
                           to_clob(get_desc_concat(get_complaints_ec(i_lang, per.id_epis_complaint))) || CASE
                                WHEN length(ea.desc_epis_anamnesis) = 0 THEN
                                 NULL
                                ELSE
                                 decode(per.id_epis_complaint, NULL, NULL, chr(10)) || ea.desc_epis_anamnesis
                            END description
                      FROM pn_epis_reason per
                      LEFT JOIN epis_complaint ec
                        ON per.id_epis_complaint = ec.id_epis_complaint
                      LEFT JOIN epis_anamnesis ea
                        ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                     WHERE per.id_episode = i_episode
                       AND (CASE
                               WHEN per.flg_status = pk_alert_constant.g_active THEN
                                1
                               WHEN per.flg_status = pk_alert_constant.g_cancelled
                                    AND i_show_cancelled = pk_alert_constant.g_yes THEN
                                1
                               ELSE
                                0
                           END) = 1) ft
             WHERE i_show_block = pk_alert_constant.g_yes
             ORDER BY ft.flg_status, ft.dt_record DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_reason_for_visit;

    /**
    * Get list of reason for visit records.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_blk_info     blocks to retrieve records from
    * @param o_rea_visit    cursor
    * @param o_app_type     cursor
    * @param o_prof_rec     author and date of last change
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_blk_info  IN t_coll_soap_block,
        o_rea_visit OUT pk_types.cursor_type,
        o_app_type  OUT pk_types.cursor_type,
        o_prof_rec  OUT pk_translation.t_desc_translation,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_REASON_FOR_VISIT';
        l_prof_rec      pk_translation.t_desc_translation;
        l_edit_app_type sys_config.value%TYPE;
        l_block_avail   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_id_dcs        epis_info.id_dep_clin_serv%TYPE;
        l_desc_dcs      pk_translation.t_desc_translation;
    
        l_check_first_obs VARCHAR2(10 CHAR);
        l_id_group        schedule.id_group%TYPE;
        l_flg_write       VARCHAR2(10 CHAR);
    BEGIN
        IF i_blk_info IS NULL
           OR i_blk_info.count < 1
        THEN
            pk_types.open_my_cursor(i_cursor => o_rea_visit);
            pk_types.open_my_cursor(i_cursor => o_app_type);
        ELSE
            -- check if type of appointment is editable
            g_error         := 'CALL pk_sysconfig.get_config';
            l_edit_app_type := pk_sysconfig.get_config(i_code_cf => g_config_edit_app_type, i_prof => i_prof);
        
            -- get appointment type
            g_error    := 'CALL get_dep_clin_serv';
            l_id_dcs   := get_dep_clin_serv(i_episode => i_episode);
            g_error    := 'CALL pk_hea_prv_aux.gets';
            l_desc_dcs := pk_hea_prv_aux.get_service(i_lang => i_lang, i_prof => i_prof, i_id_dep_clin_serv => l_id_dcs) ||
                          ' - ' || pk_hea_prv_aux.get_clin_service(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_dep_clin_serv => l_id_dcs);
        
            /*            -- get last change signature
            g_error    := 'CALL get_prof_rec';
            l_prof_rec := get_prof_rec(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       i_episode  => i_episode,
                                       i_blk_info => i_blk_info);*/
        
            g_error := 'CALL pk_visit.check_first_obs';
            -- Check if theres data already associated on this episode/schedule
            l_check_first_obs := pk_visit.check_first_obs(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_id_episode  => i_episode,
                                                          i_id_schedule => NULL);
        
            g_error := 'VERIFY GROUP SCHEDULE';
            -- Verify if this episode as been schedule in a group and dont let write
            BEGIN
                SELECT s.id_group
                  INTO l_id_group
                  FROM epis_info ei
                  JOIN schedule s
                    ON s.id_schedule = ei.id_schedule
                 WHERE ei.id_episode = i_episode;
            
                -- overwrite permissions
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_group := NULL;
            END;
        
            -- check if reason for visit block is available
            FOR i IN i_blk_info.first .. i_blk_info.last
            LOOP
                IF i_blk_info(i).flg_type = g_type_reason_visit
                THEN
                    l_block_avail := pk_alert_constant.g_yes;
                    EXIT;
                END IF;
            END LOOP;
        
            -- debug reason for visit block availability
            pk_alertlog.log_debug(text            => 'l_block_avail: ' || l_block_avail,
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_name);
        
            g_error := 'CALL get_reason_for_visit';
            IF NOT get_reason_for_visit(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_episode    => i_episode,
                                        i_show_block => l_block_avail,
                                        o_rea_visit  => o_rea_visit,
                                        o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_check_first_obs = pk_alert_constant.g_yes
            THEN
                l_flg_write := pk_alert_constant.g_no;
            ELSIF l_id_group != 0
                  AND l_id_group IS NOT NULL
            THEN
                l_flg_write := pk_alert_constant.g_no;
            ELSE
                l_flg_write := l_edit_app_type;
            END IF;
        
            g_error := 'OPEN o_app_type';
            OPEN o_app_type FOR
                SELECT l_id_dcs id_dep_clin_serv, l_desc_dcs desc_dep_clin_serv, l_flg_write flg_write
                  FROM dual
                 WHERE l_block_avail = pk_alert_constant.g_yes;
        
            o_prof_rec := l_prof_rec;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_reason_for_visit;

    /**
    * Get reason for visit current record data.
    *
    * @param i_epis_reason  episode progress notes reason identifier
    * @param o_complaints   complaint identifiers list
    * @param o_text         text
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/05
    */
    PROCEDURE get_reason_for_visit_cur
    (
        i_epis_reason IN pn_epis_reason.id_pn_epis_reason%TYPE,
        o_complaints  OUT table_number,
        o_text        OUT epis_anamnesis.desc_epis_anamnesis%TYPE
    ) IS
        l_id_ec pn_epis_reason.id_epis_complaint%TYPE;
        l_id_ea pn_epis_reason.id_epis_anamnesis%TYPE;
    BEGIN
        -- get record ids
        IF i_epis_reason IS NOT NULL
        THEN
            g_error := 'OPEN c_per_ids';
            OPEN c_per_ids(i_epis_reason => i_epis_reason);
            FETCH c_per_ids
                INTO l_id_ec, l_id_ea;
            CLOSE c_per_ids;
        END IF;
    
        -- get record predefined reasons for visit
        IF l_id_ec IS NOT NULL
        THEN
            g_error := 'SELECT o_complaints';
            SELECT t.id_complaint
              BULK COLLECT
              INTO o_complaints
              FROM (SELECT ec.id_complaint
                      FROM epis_complaint ec
                     WHERE ec.id_epis_complaint = l_id_ec
                    UNION ALL
                    SELECT ec.id_complaint
                      FROM epis_complaint ec
                     WHERE ec.id_epis_complaint_root = l_id_ec) t;
        END IF;
    
        -- get record free text reason for visit
        IF l_id_ea IS NOT NULL
        THEN
            g_error := 'SELECT o_text';
            SELECT ea.desc_epis_anamnesis
              INTO o_text
              FROM epis_anamnesis ea
             WHERE ea.id_epis_anamnesis = l_id_ea;
        END IF;
    END get_reason_for_visit_cur;

    /**
    * Stores user input from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param i_flg_rep_by   complaint reported by
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    PROCEDURE set_reason_for_visit_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        i_reason     IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_long%TYPE,
        i_context    IN VARCHAR2 DEFAULT NULL,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) IS
        l_id_ec_prev   pn_epis_reason.id_epis_complaint%TYPE;
        l_id_ea_prev   pn_epis_reason.id_epis_anamnesis%TYPE;
        l_id_ec_new    epis_complaint.id_epis_complaint%TYPE;
        l_id_ea_new    epis_anamnesis.id_epis_anamnesis%TYPE;
        l_edit_type_ec epis_complaint.flg_edition_type%TYPE;
        l_edit_type_ea epis_anamnesis.flg_edition_type%TYPE;
        l_flg_rep_by   epis_anamnesis.flg_reported_by%TYPE;
        l_status       pn_epis_reason.flg_status%TYPE;
        l_id_cid       cancel_info_det.id_cancel_info_det%TYPE;
        l_id_dcs       dep_clin_serv.id_dep_clin_serv%TYPE;
        l_pn_row_coll  ts_progress_notes.progress_notes_tc;
        l_rowids       table_varchar := table_varchar();
    BEGIN
        --set flags and get previous record ids
        IF i_record IS NULL
        THEN
            -- creating new record
            l_edit_type_ec := pk_complaint.g_flg_edition_type_new;
            l_edit_type_ea := pk_clinical_info.g_flg_edition_type_new;
            l_flg_rep_by   := i_flg_rep_by;
        ELSE
            -- get previous record ids
            g_error := 'OPEN c_per_ids';
            OPEN c_per_ids(i_epis_reason => i_record);
            FETCH c_per_ids
                INTO l_id_ec_prev, l_id_ea_prev;
            CLOSE c_per_ids;
        
            -- updating existing record
            l_edit_type_ec := pk_complaint.g_flg_edition_type_edit;
            l_edit_type_ea := pk_clinical_info.g_flg_edition_type_edit;
        
            -- check if calling function is from Single Page to allow changing flg_rep_by
            IF i_context = g_context_single_page
            THEN
                l_flg_rep_by := i_flg_rep_by;
            ELSE
                l_flg_rep_by := get_flg_rep_by(i_epis_reason => i_record);
            END IF;
        END IF;
    
        -- handle epis_complaint
        IF i_complaints IS NOT NULL
           AND i_complaints.count > 0
        THEN
            -- predefined reasons for visit were set:
            -- insert on epis_complaint
            g_error  := 'CALL get_dep_clin_serv';
            l_id_dcs := get_dep_clin_serv(i_episode => i_episode);
        
            g_error := 'CALL pk_complaint.set_reason_epis_complaint_int';
            IF NOT pk_complaint.set_reason_epis_complaint_int(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_epis            => i_episode,
                                                              i_complaint       => i_complaints,
                                                              i_pat_complaint   => NULL,
                                                              i_flg_type        => l_edit_type_ec,
                                                              i_flg_reported_by => l_flg_rep_by,
                                                              i_dep_clin_serv   => l_id_dcs,
                                                              i_parent          => l_id_ec_prev,
                                                              o_epis_complaint  => l_id_ec_new,
                                                              o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_id_ec_prev IS NOT NULL
        THEN
            -- predefined reasons for visit had been set, but have now been deselected
            -- outdate previous record
            l_rowids := table_varchar();
            g_error  := 'CALL ts_epis_complaint.upd I';
            ts_epis_complaint.upd(id_epis_complaint_in => l_id_ec_prev,
                                  flg_status_in        => pk_alert_constant.g_outdated,
                                  flg_status_nin       => FALSE,
                                  rows_out             => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_update I';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_COMPLAINT',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
    
        -- handle epis_anamnesis
        IF i_text IS NOT NULL
        THEN
            -- free text reason for visit was set:
            -- insert on epis_anamnesis
            g_error := 'CALL pk_clinical_info.set_epis_anamnesis_int';
            IF NOT pk_clinical_info.set_epis_anamnesis_int(i_lang              => i_lang,
                                                           i_episode           => i_episode,
                                                           i_prof              => i_prof,
                                                           i_desc              => i_text,
                                                           i_flg_type          => g_type_reason_visit,
                                                           i_flg_type_mode     => l_edit_type_ea,
                                                           i_id_epis_anamnesis => l_id_ea_prev,
                                                           i_id_diag           => NULL,
                                                           i_flg_class         => NULL,
                                                           i_prof_cat_type     => i_prof_cat,
                                                           i_flg_rep_by        => l_flg_rep_by,
                                                           o_id_epis_anamnesis => l_id_ea_new,
                                                           o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_id_ea_prev IS NOT NULL
        THEN
            -- free text reason for visit had been set,
            -- but has now been deleted
            l_rowids := table_varchar();
            g_error  := 'CALL ts_epis_anamnesis.upd I';
            ts_epis_anamnesis.upd(id_epis_anamnesis_in => l_id_ea_prev,
                                  flg_status_in        => pk_alert_constant.g_outdated,
                                  flg_status_nin       => FALSE,
                                  rows_out             => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_update II';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ANAMNESIS',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
    
        IF i_reason IS NOT NULL
        THEN
            l_status := pk_alert_constant.g_cancelled;
        
            -- cancel record
            -- create cancel information
            l_rowids := table_varchar();
            g_error  := 'CALL ts_cancel_info_det.ins';
            ts_cancel_info_det.ins(id_prof_cancel_in        => i_prof.id,
                                   id_cancel_reason_in      => i_reason,
                                   dt_cancel_in             => g_sysdate_tstz,
                                   notes_cancel_long_in     => i_notes,
                                   flg_notes_cancel_type_in => CASE
                                                                   WHEN i_notes IS NULL THEN
                                                                    NULL
                                                                   ELSE
                                                                    g_long_notes
                                                               END,
                                   id_cancel_info_det_out   => l_id_cid,
                                   rows_out                 => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CANCEL_INFO_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF l_id_ec_new IS NOT NULL
            THEN
                -- cancel epis_complaint
                l_rowids := table_varchar();
                g_error  := 'CALL ts_epis_complaint.upd II';
                -- change on applying Single Page PPN in ambulatory, there was a bug (on epis_complaint only one complaint was being cancelled)
                ts_epis_complaint.upd(flg_status_in         => pk_alert_constant.g_cancelled,
                                      id_cancel_info_det_in => l_id_cid,
                                      where_in              => ' id_episode = ' || i_episode || ' AND flg_status = ''' ||
                                                               pk_complaint.g_complaint_act || '''',
                                      rows_out              => l_rowids);
                g_error := 'CALL t_data_gov_mnt.process_update III';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_COMPLAINT',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'ID_CANCEL_INFO_DET'));
            END IF;
        
            IF l_id_ea_new IS NOT NULL
            THEN
                -- cancel epis_anamnesis
                l_rowids := table_varchar();
                g_error  := 'CALL ts_epis_anamnesis.upd II';
                -- change on applying Single Page PPN in ambulatory, there was a bug (on epis_complaint only one complaint was being cancelled)
                ts_epis_anamnesis.upd(flg_status_in         => pk_alert_constant.g_cancelled,
                                      id_cancel_info_det_in => l_id_cid,
                                      where_in              => ' id_episode = ' || i_episode || ' AND flg_status = ''' ||
                                                               pk_complaint.g_complaint_act || '''',
                                      rows_out              => l_rowids);
            
                g_error := 'CALL t_data_gov_mnt.process_update IV';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_ANAMNESIS',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'ID_CANCEL_INFO_DET'));
            END IF;
        ELSE
            l_status := pk_alert_constant.g_active;
        END IF;
    
        pk_alertlog.log_debug(text => 'l_status: ' || l_status, object_name => g_package_name);
    
        -- insert record
        l_rowids := table_varchar();
        g_error  := 'CALL ts_pn_epis_reason.ins';
        ts_pn_epis_reason.ins(id_episode_in         => i_episode,
                              id_epis_complaint_in  => l_id_ec_new,
                              id_epis_anamnesis_in  => l_id_ea_new,
                              flg_status_in         => l_status,
                              id_parent_in          => i_record,
                              id_pn_epis_reason_out => o_id_per,
                              rows_out              => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PN_EPIS_REASON',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_record IS NOT NULL
        THEN
            -- update record
            l_rowids := table_varchar();
            g_error  := 'CALL ts_pn_epis_reason.upd';
            ts_pn_epis_reason.upd(id_pn_epis_reason_in => i_record,
                                  flg_status_in        => pk_alert_constant.g_outdated,
                                  flg_status_nin       => FALSE,
                                  rows_out             => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_update V';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'PN_EPIS_REASON',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
    
        -- copy coding
        IF i_record IS NOT NULL
        THEN
            g_error := 'SELECT l_pn_row_coll (per)';
            SELECT pn.*
              BULK COLLECT
              INTO l_pn_row_coll
              FROM progress_notes pn
             WHERE (l_id_ec_prev IS NOT NULL AND pn.id_epis_complaint = l_id_ec_prev)
                OR (l_id_ea_prev IS NOT NULL AND pn.id_epis_anamnesis = l_id_ea_prev);
        
            IF l_pn_row_coll IS NOT NULL
               AND l_pn_row_coll.count > 0
            THEN
                FOR i IN l_pn_row_coll.first .. l_pn_row_coll.last
                LOOP
                    l_pn_row_coll(i).id_progress_notes := ts_progress_notes.next_key;
                    l_pn_row_coll(i).id_epis_complaint := l_id_ec_new;
                    l_pn_row_coll(i).id_epis_anamnesis := l_id_ea_new;
                END LOOP;
            
                l_rowids := table_varchar();
                g_error  := 'CALL ts_progress_notes.ins';
                ts_progress_notes.ins(rows_in => l_pn_row_coll, rows_out => l_rowids);
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PROGRESS_NOTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        g_error := 'CALL set_templates';
        set_templates(i_lang    => i_lang,
                      i_prof    => i_prof,
                      i_episode => i_episode,
                      i_patient => i_patient,
                      i_id_ec   => l_id_ec_new,
                      o_error   => o_error);
    END set_reason_for_visit_int;

    /**
    * Cancels record from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_reason_for_visit_cancel
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_record   IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REASON_FOR_VISIT_CANCEL';
        l_text       epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_complaints table_number := table_number();
        l_id_per     pn_epis_reason.id_pn_epis_reason%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate input
        IF i_record IS NULL
        THEN
            g_error := 'Record identifier cannot be null!';
            RAISE g_fault;
        END IF;
    
        -- debug input
        pk_alertlog.log_debug(text            => 'i_record: ' || i_record,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- get current record data
        g_error := 'CALL get_reason_for_visit_cur';
        get_reason_for_visit_cur(i_epis_reason => i_record, o_complaints => l_complaints, o_text => l_text);
    
        g_error := 'CALL set_reason_for_visit';
        set_reason_for_visit_int(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_cat   => i_prof_cat,
                                 i_episode    => i_episode,
                                 i_patient    => i_patient,
                                 i_record     => i_record,
                                 i_text       => l_text,
                                 i_complaints => l_complaints,
                                 i_flg_rep_by => NULL,
                                 i_reason     => i_reason,
                                 i_notes      => i_notes,
                                 o_id_per     => l_id_per,
                                 o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_reason_for_visit_cancel;

    /**
    * Stores user input from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_reason_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REASON_FOR_VISIT';
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL set_reason_for_visit_int';
        set_reason_for_visit_int(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_cat   => i_prof_cat,
                                 i_episode    => i_episode,
                                 i_patient    => i_patient,
                                 i_record     => i_record,
                                 i_text       => i_text,
                                 i_complaints => i_complaints,
                                 i_flg_rep_by => NULL,
                                 i_reason     => NULL,
                                 i_notes      => NULL,
                                 o_id_per     => o_id_per,
                                 o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_reason_for_visit;

    /**
    * Stores user input from reason for visit and coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param i_diags        diagnoses identifiers list
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Alves
    * @version               2.6.4.1
    * @since                2014/08/27
    */
    FUNCTION set_reason_for_visit_coding
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        i_diags      IN table_number,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REASON_FOR_VISIT_CODING';
        l_id_ec       epis_complaint.id_epis_complaint%TYPE;
        l_id_ea       epis_anamnesis.id_epis_anamnesis%TYPE;
        l_pn_row      progress_notes%ROWTYPE;
        l_pn_row_coll ts_progress_notes.progress_notes_tc;
        l_rowids      table_varchar := table_varchar();
        l_prog_notes  table_number := table_number();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- coding reason for visit
        g_error := 'CALL set_reason_for_visit_int';
        set_reason_for_visit_int(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_cat   => i_prof_cat,
                                 i_episode    => i_episode,
                                 i_patient    => i_patient,
                                 i_record     => i_record,
                                 i_text       => i_text,
                                 i_complaints => i_complaints,
                                 i_flg_rep_by => i_flg_rep_by,
                                 i_reason     => NULL,
                                 i_notes      => NULL,
                                 i_context    => g_context_single_page,
                                 o_id_per     => o_id_per,
                                 o_error      => o_error);
    
        IF o_id_per IS NOT NULL
        THEN
            -- get record active ids
            g_error := 'OPEN c_per_ids';
            OPEN c_per_ids(i_epis_reason => o_id_per);
            FETCH c_per_ids
                INTO l_id_ec, l_id_ea;
            CLOSE c_per_ids;
        
            SELECT id_progress_notes
              BULK COLLECT
              INTO l_prog_notes
              FROM progress_notes
             WHERE id_epis_anamnesis = l_id_ea
                OR id_epis_complaint = l_id_ec;
        
            FOR i IN 1 .. l_prog_notes.count
            LOOP
                l_rowids := table_varchar();
                ts_progress_notes.del(id_progress_notes_in => l_prog_notes(i), rows_out => l_rowids);
            
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PROGRESS_NOTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END LOOP;
        END IF;
    
        IF i_diags IS NOT NULL
           AND i_diags.count > 0
        THEN
            l_pn_row.id_epis_anamnesis  := l_id_ea;
            l_pn_row.id_epis_complaint  := l_id_ec;
            l_pn_row.id_diag_inst_owner := 0;
        
            FOR i IN i_diags.first .. i_diags.last
            LOOP
                l_pn_row.id_progress_notes := ts_progress_notes.next_key;
                l_pn_row.id_diagnosis := i_diags(i);
                l_pn_row_coll(l_pn_row_coll.count) := l_pn_row;
            END LOOP;
        
            --insert coding
            l_rowids := table_varchar();
            g_error  := 'CALL ts_progress_notes.ins';
            ts_progress_notes.ins(rows_in => l_pn_row_coll, rows_out => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PROGRESS_NOTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_reason_for_visit_coding;

    /**
    * Stores user input from reported by field.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_flg_rep_by   complaint reported by
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_reported_by
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REPORTED_BY';
        l_text       epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_complaints table_number := table_number();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate input
        IF i_record IS NULL
        THEN
            g_error := 'Record identifier cannot be null!';
            RAISE g_fault;
        END IF;
    
        -- debug input
        pk_alertlog.log_debug(text            => 'i_record: ' || i_record,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- get current record data
        g_error := 'CALL get_reason_for_visit_cur';
        get_reason_for_visit_cur(i_epis_reason => i_record, o_complaints => l_complaints, o_text => l_text);
    
        g_error := 'CALL set_reason_for_visit';
        set_reason_for_visit_int(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_prof_cat   => i_prof_cat,
                                 i_episode    => i_episode,
                                 i_patient    => i_patient,
                                 i_record     => i_record,
                                 i_text       => l_text,
                                 i_complaints => l_complaints,
                                 i_flg_rep_by => i_flg_rep_by,
                                 i_reason     => NULL,
                                 i_notes      => NULL,
                                 o_id_per     => o_id_per,
                                 o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_reported_by;

    /**
    * Stores user input from coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_diags        diagnoses identifiers list
    * @param i_codes        diagnoses icd codes list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_coding
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        i_diags      IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_CODING';
        l_flg_type    VARCHAR2(1 CHAR);
        l_id_per_prev pn_epis_reason.id_pn_epis_reason%TYPE;
        l_id_er_prev  epis_recomend.id_epis_recomend%TYPE;
        l_id_epn_prev epis_prog_notes.id_epis_prog_notes%TYPE;
        l_id_per_new  pn_epis_reason.id_pn_epis_reason%TYPE;
        l_id_er_new   epis_recomend.id_epis_recomend%TYPE;
        l_id_epn_new  epis_prog_notes.id_epis_prog_notes%TYPE;
        l_id_ec       epis_complaint.id_epis_complaint%TYPE;
        l_id_ea       epis_anamnesis.id_epis_anamnesis%TYPE;
        l_complaints  table_number := table_number();
        l_text        epis_recomend.desc_epis_recomend_clob%TYPE;
        l_text_clob   epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_pn_row      progress_notes%ROWTYPE;
        l_pn_row_coll ts_progress_notes.progress_notes_tc;
        l_rowids      table_varchar := table_varchar();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate input
        IF i_soap_block IS NULL
        THEN
            g_error := 'SOAP block identifier cannot be null!';
            RAISE g_fault;
        ELSIF i_record IS NULL
        THEN
            g_error := 'Record identifier cannot be null!';
            RAISE g_fault;
        ELSIF i_diags IS NULL
              OR i_diags.count < 1
        THEN
            g_error := 'No diagnoses were specified!';
            RAISE g_fault;
        END IF;
    
        -- get record type
        g_error    := 'CALL pk_progress_notes_upd.get_freetext_block_info';
        l_flg_type := pk_progress_notes_upd.get_freetext_block_info(i_lang => i_lang, i_prof => i_prof, i_soap_block => i_soap_block)
                      .flg_type;
    
        IF l_flg_type = g_type_reason_visit
        THEN
            -- coding reason for visit
            l_id_per_prev := i_record;
        
            -- get current record data
            g_error := 'CALL get_reason_for_visit_cur';
            get_reason_for_visit_cur(i_epis_reason => l_id_per_prev,
                                     o_complaints  => l_complaints,
                                     o_text        => l_text_clob);
        
            g_error := 'CALL set_reason_for_visit_int';
            set_reason_for_visit_int(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_prof_cat   => i_prof_cat,
                                     i_episode    => i_episode,
                                     i_patient    => i_patient,
                                     i_record     => l_id_per_prev,
                                     i_text       => l_text_clob,
                                     i_complaints => l_complaints,
                                     i_flg_rep_by => NULL,
                                     i_reason     => NULL,
                                     i_notes      => NULL,
                                     o_id_per     => l_id_per_new,
                                     o_error      => o_error);
        ELSIF l_flg_type IN (g_type_subjective, g_type_objective, g_type_assessment, g_type_plan)
        THEN
            -- coding other default blocks
            l_id_er_prev := i_record;
        
            IF l_id_er_prev IS NOT NULL
            THEN
                g_error := 'SELECT l_text';
                SELECT er.desc_epis_recomend_clob
                  INTO l_text
                  FROM epis_recomend er
                 WHERE er.id_epis_recomend = l_id_er_prev;
            END IF;
        
            g_error := 'CALL set_free_text_er';
            set_free_text_er(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_episode  => i_episode,
                             i_patient  => i_patient,
                             i_flg_type => l_flg_type,
                             i_record   => l_id_er_prev,
                             i_text     => l_text,
                             i_reason   => NULL,
                             i_notes    => NULL,
                             o_id_er    => l_id_er_new,
                             o_error    => o_error);
        ELSIF l_flg_type = g_type_user_defined
        THEN
            -- coding user defined block
            l_id_epn_prev := i_record;
        
            IF l_id_epn_prev IS NOT NULL
            THEN
                g_error := 'SELECT l_text_clob';
                SELECT epn.text
                  INTO l_text_clob
                  FROM epis_prog_notes epn
                 WHERE epn.id_epis_prog_notes = l_id_epn_prev;
            END IF;
        
            g_error := 'CALL set_free_text_epn';
            set_free_text_epn(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_episode    => i_episode,
                              i_soap_block => i_soap_block,
                              i_record     => l_id_epn_prev,
                              i_text       => l_text_clob,
                              i_reason     => NULL,
                              i_notes      => NULL,
                              o_id_epn     => l_id_epn_new,
                              o_error      => o_error);
        ELSE
            g_error := 'Unrecognized record type!';
            RAISE g_fault;
        END IF;
    
        IF l_id_per_new IS NOT NULL
           OR l_id_per_prev IS NOT NULL
        THEN
            -- get record active ids
            g_error := 'OPEN c_per_ids';
            OPEN c_per_ids(i_epis_reason => nvl(l_id_per_new, l_id_per_prev));
            FETCH c_per_ids
                INTO l_id_ec, l_id_ea;
            CLOSE c_per_ids;
        END IF;
    
        -- set coding rows
        l_pn_row.id_epis_recomend   := l_id_er_new;
        l_pn_row.id_epis_anamnesis  := l_id_ea;
        l_pn_row.id_epis_complaint  := l_id_ec;
        l_pn_row.id_epis_prog_notes := l_id_epn_new;
        l_pn_row.id_diag_inst_owner := 0;
    
        FOR i IN i_diags.first .. i_diags.last
        LOOP
            l_pn_row.id_progress_notes := ts_progress_notes.next_key;
            l_pn_row.id_diagnosis      := i_diags(i);
        
            l_pn_row_coll(i) := l_pn_row;
        END LOOP;
    
        -- insert coding
        g_error := 'CALL ts_progress_notes.ins';
        ts_progress_notes.ins(rows_in => l_pn_row_coll, rows_out => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PROGRESS_NOTES',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_coding;

    /**
    * Get information transfer data, given a list of episodes.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_epis_list    episode identifiers list
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_epis_list IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT';
        l_blocks t_coll_soap_block := t_coll_soap_block();
    BEGIN
        IF i_epis_list IS NULL
           OR i_epis_list.count < 1
        THEN
            pk_types.open_my_cursor(i_cursor => o_data);
        ELSE
            g_error := 'CALL pk_progress_notes_upd.get_freetext_block_info';
            IF NOT pk_progress_notes_upd.get_freetext_block_info(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_episode    => i_episode,
                                                                 o_soap_block => l_blocks,
                                                                 o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_blocks IS NULL
               OR l_blocks.count < 1
            THEN
                pk_types.open_my_cursor(i_cursor => o_data);
            ELSE
                g_error := 'OPEN o_data';
                OPEN o_data FOR
                    SELECT pk_date_utils.date_year_tsz(i_lang, ft.dt_record, i_prof.institution, i_prof.software) dt_year,
                           blk.desc_block block_desc,
                           ft.text,
                           pk_tools.get_prof_description(i_lang, i_prof, ft.id_professional, ft.dt_record, i_episode) ||
                           ' / ' ||
                           pk_date_utils.date_char_tsz(i_lang, ft.dt_record, i_prof.institution, i_prof.software) desc_prof_date
                      FROM (SELECT er.id_episode,
                                   NULL                       id_pn_soap_block,
                                   er.flg_type,
                                   er.desc_epis_recomend_clob text,
                                   er.id_professional,
                                   er.dt_epis_recomend_tstz   dt_record
                              FROM epis_recomend er
                             WHERE er.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                      t.column_value id_episode
                                                       FROM TABLE(i_epis_list) t)
                               AND er.flg_status = pk_alert_constant.g_active
                               AND er.flg_type IN (g_type_subjective, g_type_objective, g_type_assessment, g_type_plan)
                            UNION ALL
                            SELECT per.id_episode,
                                   NULL id_pn_soap_block,
                                   g_type_reason_visit flg_type,
                                   ea.desc_epis_anamnesis text,
                                   nvl(ec.id_professional, ea.id_professional) id_professional,
                                   nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record
                              FROM pn_epis_reason per
                              LEFT JOIN epis_complaint ec
                                ON per.id_epis_complaint = ec.id_epis_complaint
                              LEFT JOIN epis_anamnesis ea
                                ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                             WHERE per.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                       t.column_value id_episode
                                                        FROM TABLE(i_epis_list) t)
                               AND per.flg_status = pk_alert_constant.g_active
                            UNION ALL
                            SELECT epn.id_episode,
                                   epn.id_pn_soap_block,
                                   g_type_user_defined     flg_type,
                                   epn.text,
                                   epn.id_prof_last_update id_professional,
                                   epn.dt_last_update      dt_record
                              FROM epis_prog_notes epn
                             WHERE epn.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                       t.column_value id_episode
                                                        FROM TABLE(i_epis_list) t)
                               AND epn.flg_status = pk_alert_constant.g_active) ft
                      JOIN (SELECT t.id_block, t.flg_type, t.desc_block, t.rank
                              FROM TABLE(l_blocks) t) blk
                        ON ft.flg_type = blk.flg_type
                     WHERE ft.id_pn_soap_block IS NULL
                        OR ft.id_pn_soap_block = blk.id_block
                     ORDER BY dt_year DESC, blk.rank, ft.dt_record DESC;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_it;

    /**
    * Get information transfer default data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_default
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_DEFAULT';
        l_default_it sys_config.value%TYPE;
    BEGIN
        l_default_it := pk_sysconfig.get_config(i_code_cf => g_config_default_it, i_prof => i_prof);
    
        -- log default it
        pk_alertlog.log_debug(text            => 'l_default_it: ' || l_default_it,
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- switch default it
        IF l_default_it = g_it_this_visit
        THEN
            g_error := 'CALL get_it_this_visit';
            IF NOT get_it_this_visit(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_episode => i_episode,
                                     i_patient => i_patient,
                                     o_data    => o_data,
                                     o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_default_it = g_it_my_visits
        THEN
            g_error := 'CALL get_it_my_visits';
            IF NOT get_it_my_visits(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_episode => i_episode,
                                    i_patient => i_patient,
                                    o_data    => o_data,
                                    o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_default_it = g_it_this_spec
        THEN
            g_error := 'CALL get_it_this_spec';
            IF NOT get_it_this_spec(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_episode => i_episode,
                                    i_patient => i_patient,
                                    o_data    => o_data,
                                    o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_default_it = g_it_all_visits
        THEN
            g_error := 'CALL get_it_all_visits';
            IF NOT get_it_all_visits(i_lang    => i_lang,
                                     i_prof    => i_prof,
                                     i_episode => i_episode,
                                     i_patient => i_patient,
                                     o_data    => o_data,
                                     o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_data);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_it_default;

    /**
    * Get information transfer data for current visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_this_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_THIS_VISIT';
    BEGIN
        g_error := 'CALL get_it';
        IF NOT get_it(i_lang      => i_lang,
                      i_prof      => i_prof,
                      i_episode   => i_episode,
                      i_epis_list => table_number(i_episode),
                      o_data      => o_data,
                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_it_this_visit;

    /**
    * Get information transfer data for current user.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_my_visits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_MY_VISITS';
        l_epis_list table_number := table_number();
    BEGIN
        g_error := 'SELECT l_epis_list';
        SELECT e.id_episode
          BULK COLLECT
          INTO l_epis_list
          FROM episode e
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         WHERE e.id_patient = i_patient
           AND e.id_institution = i_prof.institution
           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
           AND e.flg_ehr IN (pk_alert_constant.g_epis_ehr_normal, pk_alert_constant.g_epis_ehr_schedule)
           AND ei.id_software = i_prof.software
           AND ei.id_professional = i_prof.id;
    
        g_error := 'CALL get_it';
        IF NOT get_it(i_lang      => i_lang,
                      i_prof      => i_prof,
                      i_episode   => i_episode,
                      i_epis_list => l_epis_list,
                      o_data      => o_data,
                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_it_my_visits;

    /**
    * Get information transfer data for current specialty.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_this_spec
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_THIS_SPEC';
        l_epis_cs   episode.id_clinical_service%TYPE;
        l_epis_list table_number := table_number();
    BEGIN
        g_error   := 'CALL pk_periodic_observation.get_id_clinical_service';
        l_epis_cs := pk_periodic_observation.get_id_clinical_service(i_episode => i_episode);
    
        IF l_epis_cs < 1
        THEN
            l_epis_list := table_number();
        ELSE
            g_error := 'SELECT l_epis_list';
            SELECT e.id_episode
              BULK COLLECT
              INTO l_epis_list
              FROM episode e
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             WHERE e.id_patient = i_patient
               AND e.id_institution = i_prof.institution
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.flg_ehr IN (pk_alert_constant.g_epis_ehr_normal, pk_alert_constant.g_epis_ehr_schedule)
               AND ei.id_software = i_prof.software
               AND e.id_clinical_service = l_epis_cs;
        END IF;
    
        g_error := 'CALL get_it';
        IF NOT get_it(i_lang      => i_lang,
                      i_prof      => i_prof,
                      i_episode   => i_episode,
                      i_epis_list => l_epis_list,
                      o_data      => o_data,
                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_it_this_spec;

    /**
    * Get information transfer data for all visits.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_all_visits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_ALL_VISITS';
        l_epis_list table_number := table_number();
    BEGIN
        g_error := 'SELECT l_epis_list';
        SELECT e.id_episode
          BULK COLLECT
          INTO l_epis_list
          FROM episode e
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         WHERE e.id_patient = i_patient
           AND e.id_institution = i_prof.institution
           AND e.flg_status = pk_alert_constant.g_epis_status_inactive
           AND e.flg_ehr IN (pk_alert_constant.g_epis_ehr_normal, pk_alert_constant.g_epis_ehr_schedule)
           AND ei.id_software = i_prof.software;
    
        g_error := 'CALL get_it';
        IF NOT get_it(i_lang      => i_lang,
                      i_prof      => i_prof,
                      i_episode   => i_episode,
                      i_epis_list => l_epis_list,
                      o_data      => o_data,
                      o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_it_all_visits;

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_epis_pn   episode id
    * @param o_id_task      id_task 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vítor Sá
    * @version               2.7.1.5
    * @since                2017/09/21
    */
    FUNCTION get_id_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_id_task    OUT epis_pn_det_task.id_task%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get_id_task';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT id_task
          INTO o_id_task
          FROM (SELECT epdt.id_task, epdt.dt_last_update, row_number() over(ORDER BY epdt.dt_last_update DESC) rn
                  FROM epis_pn ep
                  JOIN epis_pn_det epd
                    ON ep.id_epis_pn = epd.id_epis_pn
                  JOIN epis_pn_det_task epdt
                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                 WHERE ep.id_pn_note_type = pk_prog_notes_constants.g_note_type_aih_62
                   AND epdt.id_task_type = pk_prog_notes_constants.g_task_templates
                   AND ep.id_epis_pn = i_id_epis_pn)
         WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_id_epis_documentation;

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_epis_pn   episode id
    * @param o_id_task      id_task 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Coelho
    * @version              2.8.0.1
    * @since                2019/10/16
    */
    FUNCTION get_id_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_pn.id_episode%TYPE,
        i_id_pn_area IN pn_area.id_pn_area%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get_id_task';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_data FOR
            SELECT epdt.id_task, pdb.id_doc_area, ep.id_prof_create
              FROM epis_pn ep
              JOIN epis_pn_det epd
                ON ep.id_epis_pn = epd.id_epis_pn
              JOIN epis_pn_det_task epdt
                ON epd.id_epis_pn_det = epdt.id_epis_pn_det
              JOIN pn_data_block pdb
                ON epd.id_pn_data_block = pdb.id_pn_data_block
             WHERE ep.id_episode = i_id_episode
               AND ep.id_pn_area = i_id_pn_area
               AND epdt.flg_status = pk_alert_constant.g_active;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_EPIS_DOCUMENTATION',
                                              o_error);
            RETURN FALSE;
        
    END get_id_epis_documentation;

    /**
    * Returns a selection list  with the attending physicians names that took patient
    * responsability along the episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         profissional
    * @param i_id_episode   id of current episode
    * @param o_sql          cursor returning list of attending professionals
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Carlos Ferreira
    * @version              2.7.2
    * @since                2017/11/15
    */
    FUNCTION get_epis_att_profs
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_flg_resp_type CONSTANT VARCHAR2(1 CHAR) := 'O';
        l_error VARCHAR2(4000);
    BEGIN
    
        l_error := 'get_attending professionals';
        OPEN o_sql FOR
            SELECT p.id_professional,
                   pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => vp.id_prof_comp) prof_name,
                   pk_prof_utils.get_nickname(i_lang => i_lang, i_prof_id => vp.id_prof_comp) prof_nick_name,
                   vp.flg_main_responsible
              FROM v_epis_prof_resp vp
              JOIN professional p
                ON vp.id_prof_comp = p.id_professional
              JOIN prof_profile_template ppt
                ON ppt.id_professional = p.id_professional
              JOIN profile_template pt
                ON pt.id_profile_template = ppt.id_profile_template
             WHERE vp.id_episode = i_id_episode
               AND flg_resp_type = k_flg_resp_type
               AND pt.flg_submit_mode = 'S'
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND pt.flg_available = pk_alert_constant.g_yes
               AND pt.id_templ_assoc IS NOT NULL
               AND p.flg_state = 'A'
             ORDER BY vp.dt_comp_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_ATT_PROFS',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
    END get_epis_att_profs;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_progress_notes;
/