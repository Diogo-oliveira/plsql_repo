/*-- Last Change Revision: $Rev: 2026871 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cit IS

    g_package VARCHAR2(30 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_error   VARCHAR2(1000 CHAR);
    g_exception EXCEPTION;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * Devolve o nome a listagem de CITs existentes para um certo paciente
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION get_cit_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CIT_LIST';
        l_market market.id_market%TYPE;
    BEGIN
    
        update_status_cit_int(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'l_market: ' || l_market;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_market = pk_alert_constant.g_id_market_it
        THEN
            g_error := 'OPEN o_cits (it market)';
            OPEN o_cits FOR
                SELECT id_cit,
                       flg_type,
                       cit_name,
                       prof_name,
                       dt_start,
                       dt_end,
                       dt_end_order,
                       flg_status,
                       icon_name,
                       cit_edit_mode
                  FROM (SELECT pc.id_pat_cit id_cit,
                               pc.flg_type flg_type,
                               pk_string_utils.concat_if_exists(pk_sysdomain.get_domain(g_cit_flg_type,
                                                                                        pc.flg_type,
                                                                                        i_lang),
                                                                pk_sysdomain.get_domain(g_cit_flg_reason,
                                                                                        pc.flg_reason,
                                                                                        i_lang),
                                                                ' - ') cit_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_prof_writes) prof_name,
                               pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start,
                               pk_date_utils.date_send(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_order,
                               pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end,
                               pk_date_utils.date_send(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_order,
                               pc.flg_status flg_status,
                               pk_sysdomain.get_img(i_lang, g_cit_report_domain, pc.flg_status) icon_name,
                               get_cit_edit_mode(i_lang, i_prof, pc.id_episode) cit_edit_mode,
                               decode(pc.flg_status,
                                      g_flg_status_construction,
                                      1,
                                      g_flg_status_edited,
                                      1,
                                      g_flg_status_printed,
                                      2,
                                      g_flg_status_canceled,
                                      3,
                                      1) rank
                          FROM pat_cit pc
                         WHERE pc.id_patient = i_patient
                           AND pc.id_episode = i_episode
                         ORDER BY rank, pc.dt_start_period_tstz DESC);
        ELSE
            g_error := 'OPEN o_cits (other markets)';
            OPEN o_cits FOR
                SELECT id_cit,
                       flg_type,
                       cit_name,
                       prof_name,
                       dt_start,
                       dt_start_order,
                       dt_end,
                       dt_end_order,
                       flg_status,
                       icon_name,
                       cit_edit_mode
                  FROM (SELECT pc.id_pat_cit id_cit,
                               pc.flg_type flg_type,
                               pk_string_utils.concat_if_exists(pk_sysdomain.get_domain(g_cit_flg_type,
                                                                                        pc.flg_type,
                                                                                        i_lang),
                                                                pk_sysdomain.get_domain(g_cit_flg_reason,
                                                                                        pc.flg_reason,
                                                                                        i_lang),
                                                                ' - ') cit_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_prof_writes) prof_name,
                               nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof),
                                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof)) dt_start,
                               nvl(pk_date_utils.date_send(i_lang, pc.dt_start_period_tstz, i_prof),
                                   pk_date_utils.date_send(i_lang, pc.dt_other_capac_start, i_prof)) dt_start_order,
                               decode(pc.dt_zero_capac_end,
                                      NULL,
                                      nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz - 1, i_prof),
                                          pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang)),
                                      pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_zero_capac_end, i_prof)) dt_end,
                               decode(pc.dt_zero_capac_end,
                                      NULL,
                                      decode(pk_date_utils.date_send(i_lang, pc.dt_end_period_tstz - 1, i_prof),
                                             NULL,
                                             '0',
                                             pk_date_utils.date_send(i_lang, pc.dt_end_period_tstz - 1, i_prof)),
                                      pk_date_utils.date_send(i_lang, pc.dt_zero_capac_end, i_prof)) dt_end_order,
                               pc.flg_status flg_status,
                               pk_sysdomain.get_img(i_lang, g_cit_report_domain, pc.flg_status) icon_name,
                               get_cit_edit_mode(i_lang, i_prof, pc.id_episode) cit_edit_mode,
                               decode(pc.flg_status,
                                      g_flg_status_construction,
                                      1,
                                      g_flg_status_edited,
                                      1,
                                      g_flg_status_renew,
                                      1,
                                      g_flg_status_ongoing,
                                      2,
                                      g_flg_status_printed,
                                      3,
                                      g_flg_status_concluded,
                                      4,
                                      g_flg_status_expired,
                                      5,
                                      g_flg_status_canceled,
                                      6,
                                      1) rank
                          FROM pat_cit pc
                         WHERE pc.id_patient = i_patient)
                 ORDER BY rank, dt_start_order DESC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cits);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     l_func_name,
                                                     o_error);
    END;

    /********************************************************************************************
    * Devolve o nome a listagem de CITs existentes para um certo paciente para os reports
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Jorge Silva
    * @since                    27/08/2013
    ********************************************************************************************/
    FUNCTION get_cit_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CIT_REPORT';
        l_market       market.id_market%TYPE;
        l_prev_episode table_number;
    BEGIN
    
        l_market       := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_prev_episode := get_prev_pat_episode(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_pat     => i_patient,
                                               i_episode => i_episode);
    
        IF (l_market <> pk_alert_constant.g_id_market_ch)
        THEN
            IF NOT get_cit_list(i_lang    => i_lang,
                                i_prof    => i_prof,
                                i_patient => i_patient,
                                i_episode => i_episode,
                                o_cits    => o_cits,
                                o_error   => o_error)
            THEN
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'OPEN o_cits (other markets)';
            OPEN o_cits FOR
                SELECT id_cit, flg_type, cit_name, prof_name, dt_start, dt_end, flg_status, icon_name, cit_edit_mode
                  FROM (SELECT pc.id_pat_cit id_cit,
                               pc.flg_type flg_type,
                               pk_sysdomain.get_domain(g_cit_flg_type, pc.flg_type, i_lang) cit_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_prof_writes) prof_name,
                               nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof),
                                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof)) dt_start,
                               nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
                                   pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang)) dt_end,
                               pc.flg_status flg_status,
                               pk_sysdomain.get_img(i_lang, g_cit_report_domain, pc.flg_status) icon_name,
                               get_cit_edit_mode(i_lang, i_prof, pc.id_episode) cit_edit_mode,
                               decode(pc.flg_status,
                                      g_flg_status_construction,
                                      1,
                                      g_flg_status_edited,
                                      1,
                                      g_flg_status_renew,
                                      1,
                                      g_flg_status_ongoing,
                                      2,
                                      g_flg_status_printed,
                                      3,
                                      g_flg_status_concluded,
                                      4,
                                      g_flg_status_expired,
                                      5,
                                      g_flg_status_canceled,
                                      6,
                                      1) rank
                          FROM pat_cit pc
                         WHERE pc.id_patient = i_patient
                           AND pc.id_episode IN (SELECT /*+opt_estimate(table,s,scale_rows=1)*/
                                                  column_value
                                                   FROM TABLE(l_prev_episode))
                         ORDER BY rank, pc.dt_start_period_tstz DESC);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cits);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     l_func_name,
                                                     o_error);
    END;

    ----------------------------------------------------------------------------------------------------------------

    /********************************************************************************************
    * Função que retorna dados de CIT já existente (no caso de i_cit não ser null) ou então
    * os dados básicos e necessários para a criação de uma nova - Segurança Social
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION get_cit_new_social
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_type_ss doc_type.id_doc_type%TYPE;
    
    BEGIN
        l_doc_type_ss := pk_sysconfig.get_config('CIT_SOCIAL_SECURITY_NUM', i_prof);
        IF l_doc_type_ss IS NULL
        THEN
            l_doc_type_ss := 1032;
        END IF;
    
        IF i_cit IS NULL -- novo CIT portanto a maioria dos parâmetros vai nulo
        THEN
            g_error := 'OPEN o_cits - new social';
            OPEN o_cits FOR
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                       p.num_order prof_code,
                       NULL flg_pat_disease_state,
                       NULL desc_pat_disease_state,
                       pk_doc.get_pat_doc_num(i_patient, l_doc_type_ss) beneficiary_num,
                       pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                       pat.name pat_name,
                       NULL ill_parent_name,
                       NULL flg_ill_affinity,
                       NULL desc_ill_affinity,
                       NULL ill_id_card,
                       NULL flg_cit_classification_ss,
                       NULL desc_cit_classification_ss,
                       NULL flg_internment,
                       NULL desc_internment,
                       NULL flg_incapacity_period,
                       NULL desc_incapacity_period,
                       NULL dt_start_period_tstz,
                       NULL dt_end_period_tstz,
                       NULL home_authorization
                  FROM patient pat, professional p
                 WHERE p.id_professional = i_prof.id
                   AND pat.id_patient = i_patient;
        ELSE
            -- actualização do CIT existente
            g_error := 'OPEN o_cits - edit record';
            OPEN o_cits FOR
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                       p.num_order prof_code,
                       pc.flg_pat_disease_state flg_pat_disease_state,
                       pk_sysdomain.get_domain(g_cit_flg_pat_disease_state, pc.flg_pat_disease_state, i_lang) desc_pat_disease_state,
                       pc.beneficiary_number beneficiary_num,
                       pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                       pat.name pat_name,
                       pc.ill_parent_name ill_parent_name,
                       pc.flg_ill_affinity flg_ill_affinity,
                       pk_sysdomain.get_domain(g_cit_flg_ill_affinity, pc.flg_ill_affinity, i_lang) desc_ill_affinity,
                       pc.ill_id_card ill_id_card,
                       pc.flg_cit_classification_ss flg_cit_classification_ss,
                       pk_sysdomain.get_domain(g_cit_flg_cit_ss, pc.flg_cit_classification_ss, i_lang) desc_cit_classification_ss,
                       pc.flg_internment flg_internment,
                       pk_sysdomain.get_domain(g_cit_flg_internment, pc.flg_internment, i_lang) desc_internment,
                       pc.flg_incapacity_period flg_incapacity_period,
                       pk_sysdomain.get_domain(g_cit_flg_incapacity_period, pc.flg_incapacity_period, i_lang) desc_incapacity_period,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_period_tstz,
                       pc.home_authorization home_authorization,
                       to_date(to_char(pc.dt_end_period_tstz, 'yyyymmdd'), 'yyyymmdd') -
                       to_date(to_char(pc.dt_start_period_tstz, 'yyyymmdd'), 'yyyymmdd') num_days,
                       ies.value inst_barcode,
                       pk_translation.get_translation(i_lang, i.code_institution) inst_name,
                       to_char(SYSDATE, 'DD-MM-YYYY') dt_system,
                       to_char(pat.dt_birth, 'DD-MM-YYYY') rep_pat_dt_birth,
                       to_char(pc.dt_start_period_tstz, 'DD-MM-YYYY') rep_dt_start_period_tstz,
                       to_char(pc.dt_end_period_tstz, 'DD-MM-YYYY') rep_dt_end_period_tstz
                  FROM pat_cit pc, patient pat, professional p, institution i, instit_ext_sys ies
                 WHERE pc.id_pat_cit = i_cit
                   AND pc.id_prof_writes = p.id_professional
                   AND pc.id_patient = pat.id_patient
                   AND i.id_institution = i_prof.institution
                   AND i.id_institution = ies.id_institution
                   AND ies.id_external_sys = 5;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cits);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_NEW_SOCIAL',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função que retorna dados de CIT já existente (no caso de i_cit não ser null) ou então
    * os dados básicos e necessários para a criação de uma nova - Função Pública
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION get_cit_new_public
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_type_ss doc_type.id_doc_type%TYPE;
    
    BEGIN
        l_doc_type_ss := pk_sysconfig.get_config('CIT_SOCIAL_SECURITY_NUM', i_prof);
        IF l_doc_type_ss IS NULL
        THEN
            l_doc_type_ss := 1032;
        END IF;
    
        IF i_cit IS NULL -- novo CIT portanto a maioria dos parâmetros vai nulo
        THEN
            g_error := 'OPEN o_cits - new public';
            OPEN o_cits FOR
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                       p.num_order prof_code,
                       NULL flg_pat_disease_state,
                       NULL desc_pat_disease_state,
                       NULL flg_prof_health_subsys,
                       NULL desc_prof_health_subsys,
                       pk_doc.get_pat_doc_num(i_patient, l_doc_type_ss) beneficiary_num,
                       pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                       pat.name pat_name,
                       NULL ill_parent_name,
                       NULL flg_ill_affinity,
                       NULL desc_ill_affinity,
                       NULL ill_id_card,
                       NULL flg_benef_health_subsys,
                       NULL desc_benef_health_subsys,
                       NULL flg_cit_classification_fp,
                       NULL desc_cit_classification_fp,
                       NULL flg_internment,
                       NULL desc_internment,
                       NULL dt_start_period_tstz,
                       NULL dt_end_period_tstz,
                       NULL flg_home_absence,
                       NULL desc_home_absence
                  FROM patient pat, professional p
                 WHERE p.id_professional = i_prof.id
                   AND pat.id_patient = i_patient;
        ELSE
            -- actualização do CIT existente
            g_error := 'OPEN o_cits - edit record';
            OPEN o_cits FOR
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                       p.num_order prof_code,
                       pc.flg_pat_disease_state flg_pat_disease_state,
                       pk_sysdomain.get_domain(g_cit_flg_pat_disease_state, pc.flg_pat_disease_state, i_lang) desc_pat_disease_state,
                       pc.flg_prof_health_subsys flg_prof_health_subsys,
                       pk_sysdomain.get_domain(g_cit_flg_prof_health_subsys, pc.flg_prof_health_subsys, i_lang) desc_prof_health_subsys,
                       pc.beneficiary_number beneficiary_num,
                       pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                       pat.name pat_name,
                       pc.ill_parent_name ill_parent_name,
                       pc.flg_ill_affinity flg_ill_affinity,
                       pk_sysdomain.get_domain(g_cit_flg_ill_affinity, pc.flg_ill_affinity, i_lang) desc_ill_affinity,
                       pc.ill_id_card ill_id_card,
                       pc.flg_benef_health_subsys flg_benef_health_subsys,
                       pk_sysdomain.get_domain(g_cit_flg_benef_health_subsys, pc.flg_benef_health_subsys, i_lang) desc_benef_health_subsys,
                       pc.flg_cit_classification_fp flg_cit_classification_fp,
                       pk_sysdomain.get_domain(g_cit_flg_cit_fp, pc.flg_cit_classification_fp, i_lang) desc_cit_classification_fp,
                       pc.flg_internment flg_internment,
                       pk_sysdomain.get_domain(g_cit_flg_internment, pc.flg_internment, i_lang) desc_internment,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_period_tstz,
                       pc.flg_home_absence flg_home_absence,
                       pk_sysdomain.get_domain(g_cit_flg_home_absence, pc.flg_home_absence, i_lang) desc_home_absence,
                       to_date(to_char(pc.dt_end_period_tstz, 'yyyymmdd'), 'yyyymmdd') -
                       to_date(to_char(pc.dt_start_period_tstz, 'yyyymmdd'), 'yyyymmdd') num_days,
                       ies.value inst_barcode,
                       pk_translation.get_translation(i_lang, i.code_institution) inst_name,
                       to_char(SYSDATE, 'DD-MM-YYYY') dt_system,
                       to_char(pat.dt_birth, 'DD-MM-YYYY') rep_pat_dt_birth,
                       to_char(pc.dt_start_period_tstz, 'DD-MM-YYYY') rep_dt_start_period_tstz,
                       to_char(pc.dt_end_period_tstz, 'DD-MM-YYYY') rep_dt_end_period_tstz
                  FROM pat_cit pc, patient pat, professional p, institution i, instit_ext_sys ies
                 WHERE pc.id_pat_cit = i_cit
                   AND pc.id_prof_writes = p.id_professional
                   AND pc.id_patient = pat.id_patient
                   AND i.id_institution = i_prof.institution
                   AND ies.id_institution = i_prof.institution
                   AND ies.id_external_sys = 5;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cits);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_NEW_PUBLIC',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função que retorna dados de CIT já existente (no caso de i_cit não ser null) ou então
    * os dados básicos e necessários para a criação de uma nova - Certificado médico de paragem de trabalho
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Jorge Silva
    * @since                    11/12/2012
    ********************************************************************************************/
    FUNCTION get_cit_new_sick_leave
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_cit IS NULL -- novo CIT portanto a vai tudo a nulo
        THEN
            g_error := 'OPEN o_cits - new sick leave';
            OPEN o_cits FOR
                SELECT NULL dt_begin_zero_value,
                       NULL dt_begin_zero_str,
                       
                       NULL duration_zero_str,
                       NULL flg_duration_zero,
                       NULL duration_zero_str,
                       NULL duration_zero_value,
                       NULL duration_zero_unit,
                       
                       NULL percentage_value,
                       
                       NULL dt_begin_other_value,
                       NULL dt_begin_other_str,
                       
                       NULL duration_other_str,
                       NULL flg_duration_other,
                       NULL duration_other_str,
                       NULL duration_other_value,
                       NULL duration_other_unit,
                       
                       NULL flg_end_value,
                       NULL dt_end_value,
                       NULL dt_end_str,
                       
                       NULL reason_desc,
                       NULL reason_value,
                       
                       NULL notes,
                       NULL dt_internment_begin_value,
                       NULL dt_internment_begin_str,
                       NULL dt_treatment_end_value,
                       NULL dt_internment_end_str,
                       NULL dt_treatment_end_value,
                       NULL dt_treatment_end_str
                  FROM dual;
        ELSE
            -- actualização do CIT existente
            g_error := 'OPEN o_cits - edit record';
            OPEN o_cits FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_begin_zero_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_begin_zero_str,
                       
                       decode(pc.flg_zero_capac_end,
                              g_capacity_date,
                              pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_zero_capac_end, i_prof),
                              g_capacity_indefinite,
                              pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                              g_capacity_periode,
                              pk_string_utils.concat_if_exists(pc.zero_capac_end_num,
                                                               pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                            i_prof,
                                                                                                            pc.zero_capac_end_unit),
                                                               ' ')) duration_zero_str,
                       pc.flg_zero_capac_end flg_duration_zero,
                       nvl(pc.zero_capac_end_num, pk_date_utils.date_send_tsz(i_lang, pc.dt_zero_capac_end, i_prof)) duration_zero_value,
                       pc.zero_capac_end_unit duration_zero_unit,
                       
                       pc.other_percentage_num percentage_value,
                       
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_other_capac_start, i_prof) dt_begin_other_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_other_capac_start, i_prof) dt_begin_other_str,
                       
                       decode(pc.flg_other_capac,
                              g_capacity_date,
                              pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_other_capac_end, i_prof),
                              g_capacity_indefinite,
                              pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                              g_capacity_periode,
                              pk_string_utils.concat_if_exists(pc.other_capac_end_num,
                                                               pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                            i_prof,
                                                                                                            pc.other_capac_end_unit),
                                                               ' ')) duration_other_str,
                       
                       pc.flg_other_capac flg_duration_other,
                       nvl(pc.other_capac_end_num, pk_date_utils.date_send_tsz(i_lang, pc.dt_other_capac_end, i_prof)) duration_other_value,
                       pc.other_capac_end_unit duration_other_unit,
                       
                       decode(pc.dt_end_period_tstz, NULL, g_capacity_indefinite, g_capacity_date) flg_end_value,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_value,
                       nvl(pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
                           pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang)) dt_end_str,
                       
                       pk_sysdomain.get_domain(g_cit_flg_reason, pc.flg_reason, i_lang) reason_desc,
                       pc.flg_reason reason_value,
                       
                       pc.notes_desc notes,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_internment_pat_begin, i_prof) dt_internment_begin_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_internment_pat_begin, i_prof) dt_internment_begin_str,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_internment_pat_end, i_prof) dt_internment_end_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_internment_pat_end, i_prof) dt_internment_end_str,
                       pk_date_utils.date_send_tsz(i_lang, pc.dt_treatment_end, i_prof) dt_treatment_end_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, pc.dt_treatment_end, i_prof) dt_treatment_end_str
                  FROM pat_cit pc, institution i
                 WHERE pc.id_pat_cit = i_cit
                   AND i.id_institution = i_prof.institution;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cits);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_NEW_PUBLIC',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função de actualização/criação de CIT  - Segurança Social (dependendo da passagem ou não da i_cit)
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION set_cit_social
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                       IN pat_cit.id_pat_cit%TYPE,
        i_flg_pat_disease_state     IN pat_cit.flg_pat_disease_state%TYPE,
        i_beneficiary_number        IN pat_cit.beneficiary_number%TYPE,
        i_ill_parent_name           IN pat_cit.ill_parent_name%TYPE,
        i_flg_ill_affinity          IN pat_cit.flg_ill_affinity%TYPE,
        i_ill_id_card               IN pat_cit.ill_id_card%TYPE,
        i_flg_cit_classification_ss IN pat_cit.flg_cit_classification_ss%TYPE,
        i_flg_internment            IN pat_cit.flg_internment%TYPE,
        i_flg_incapacity_period     IN pat_cit.flg_incapacity_period%TYPE,
        i_dt_start_period_tstz      IN VARCHAR2,
        i_dt_end_period_tstz        IN VARCHAR2,
        i_home_authorization        IN pat_cit.home_authorization%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_id_cit          pat_cit.id_pat_cit%TYPE;
        l_cit_status      pat_cit.flg_status%TYPE;
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
    
        l_dt_start_period_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_period_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        IF i_cit IS NULL -- insere um registo novo
        THEN
            l_id_cit     := ts_pat_cit.next_key;
            l_cit_status := g_flg_status_construction;
        ELSE
            l_id_cit     := i_cit;
            l_cit_status := g_flg_status_edited;
            set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
        END IF;
    
        g_sysdate_tstz         := current_timestamp;
        l_dt_start_period_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start_period_tstz, NULL);
        l_dt_end_period_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_period_tstz, NULL);
    
        g_error := 'SET PAT_CIT SS';
        ts_pat_cit.upd_ins(id_pat_cit_in                => l_id_cit,
                           id_patient_in                => i_patient,
                           id_episode_in                => i_episode,
                           flg_pat_disease_state_in     => i_flg_pat_disease_state,
                           beneficiary_number_in        => i_beneficiary_number,
                           ill_parent_name_in           => i_ill_parent_name,
                           flg_ill_affinity_in          => i_flg_ill_affinity,
                           ill_id_card_in               => i_ill_id_card,
                           flg_cit_classification_ss_in => i_flg_cit_classification_ss,
                           flg_internment_in            => i_flg_internment,
                           flg_incapacity_period_in     => i_flg_incapacity_period,
                           dt_start_period_tstz_in      => l_dt_start_period_tstz,
                           dt_end_period_tstz_in        => l_dt_end_period_tstz,
                           home_authorization_in        => i_home_authorization,
                           flg_status_in                => l_cit_status, -- construction ou edited dependendo do caso
                           flg_type_in                  => g_flg_type_social,
                           id_prof_writes_in            => i_prof.id,
                           dt_writes_tstz_in            => g_sysdate_tstz,
                           rows_out                     => l_rowids);
    
        IF l_cit_status = g_flg_status_construction
        THEN
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        IF l_rowids.count != 0
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CIT_SOCIAL',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função de actualização/criação de CIT  - Função Pública (dependendo da passagem ou não da i_cit)
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION set_cit_public
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                       IN pat_cit.id_pat_cit%TYPE,
        i_flg_pat_disease_state     IN pat_cit.flg_pat_disease_state%TYPE,
        i_flg_prof_health_subsys    IN pat_cit.flg_prof_health_subsys%TYPE,
        i_beneficiary_number        IN pat_cit.beneficiary_number%TYPE,
        i_ill_parent_name           IN pat_cit.ill_parent_name%TYPE,
        i_flg_ill_affinity          IN pat_cit.flg_ill_affinity%TYPE,
        i_ill_id_card               IN pat_cit.ill_id_card%TYPE,
        i_flg_benef_health_subsys   IN pat_cit.flg_benef_health_subsys%TYPE,
        i_flg_cit_classification_fp IN pat_cit.flg_cit_classification_fp%TYPE,
        i_flg_internment            IN pat_cit.flg_internment%TYPE,
        i_dt_start_period_tstz      IN VARCHAR2,
        i_dt_end_period_tstz        IN VARCHAR2,
        i_flg_home_absence          IN pat_cit.flg_home_absence%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_id_cit          pat_cit.id_pat_cit%TYPE;
        l_cit_status      pat_cit.flg_status%TYPE;
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
    
        l_dt_start_period_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_period_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        IF i_cit IS NULL -- insere um registo novo
        THEN
            l_id_cit     := ts_pat_cit.next_key;
            l_cit_status := g_flg_status_construction;
        ELSE
            l_id_cit     := i_cit;
            l_cit_status := g_flg_status_edited;
            set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
        END IF;
    
        g_sysdate_tstz         := current_timestamp;
        l_dt_start_period_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start_period_tstz, NULL);
        l_dt_end_period_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_period_tstz, NULL);
    
        g_error := 'UPDATE PAT_CIT FP';
        ts_pat_cit.upd_ins(id_pat_cit_in                => l_id_cit,
                           id_patient_in                => i_patient,
                           id_episode_in                => i_episode,
                           flg_pat_disease_state_in     => i_flg_pat_disease_state,
                           flg_prof_health_subsys_in    => i_flg_prof_health_subsys,
                           beneficiary_number_in        => i_beneficiary_number,
                           ill_parent_name_in           => i_ill_parent_name,
                           flg_ill_affinity_in          => i_flg_ill_affinity,
                           ill_id_card_in               => i_ill_id_card,
                           flg_benef_health_subsys_in   => i_flg_benef_health_subsys,
                           flg_cit_classification_fp_in => i_flg_cit_classification_fp,
                           flg_internment_in            => i_flg_internment,
                           dt_start_period_tstz_in      => l_dt_start_period_tstz,
                           dt_end_period_tstz_in        => l_dt_end_period_tstz,
                           flg_home_absence_in          => i_flg_home_absence,
                           flg_status_in                => l_cit_status, -- construction ou edited dependendo do caso
                           flg_type_in                  => g_flg_type_public,
                           id_prof_writes_in            => i_prof.id,
                           dt_writes_tstz_in            => g_sysdate_tstz,
                           rows_out                     => l_rowids);
    
        IF l_cit_status = g_flg_status_construction
        THEN
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        IF l_rowids.count != 0
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CIT_PUBLIC',
                                                     o_error);
    END;

    /********************************************************************************************
    * Create or update Work disability document - INAIL's 
    * (at the moment this feature is specific for IT market)
    * IMPORTANT: This function will be used directly be the ADT layer, and for that reason it cannot 
    * commit the transaction.
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @param IN   i_cit
    * @param IN   i_accident_cause
    * @param IN   i_flg_cit_type
    * @param IN   i_flg_prognosis_type
    * @param IN   i_flg_permanent_disability
    * @param IN   i_flg_life_danger
    * @param IN   i_dt_start_period_tstz
    * @param IN   i_dt_end_period_tstz
    * @param IN   i_dt_event_tstz
    * @param IN   i_dt_stop_work_tstz
    * @param IN   i_id_county_accident
    * @param IN   i_flg_accident_type       
    * @param IN   i_landline_prefix        
    * @param IN   i_landline_number        
    * @param IN   i_mobile_prefix          
    * @param IN   i_mobile_number          
    *
    * @return                   true on success and false if error occurs
    *
    * @author                   Orlando Antunes
    * @since                    24/12/2010
    ********************************************************************************************/
    FUNCTION set_cit_inail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_cit                      IN pat_cit.id_pat_cit%TYPE,
        i_accident_cause           IN pat_cit.accident_cause%TYPE,
        i_flg_cit_type             IN pat_cit.flg_cit_type%TYPE,
        i_flg_prognosis_type       IN pat_cit.flg_prognosis_type%TYPE,
        i_flg_permanent_disability IN pat_cit.flg_permanent_disability%TYPE,
        i_flg_life_danger          IN pat_cit.flg_life_danger%TYPE,
        i_dt_start_period_tstz     IN VARCHAR2,
        i_dt_end_period_tstz       IN VARCHAR2,
        i_dt_event_tstz            IN VARCHAR2,
        i_dt_stop_work_tstz        IN VARCHAR2,
        i_id_county_accident       IN pat_cit.id_county_accident%TYPE,
        i_flg_accident_type        IN pat_cit.flg_accident_type%TYPE,
        i_landline_prefix          IN pat_cit.landline_prefix%TYPE,
        i_landline_number          IN pat_cit.landline_number%TYPE,
        i_mobile_prefix            IN pat_cit.mobile_prefix%TYPE,
        i_mobile_number            IN pat_cit.mobile_number%TYPE,
        o_id_pat_cit               OUT pat_cit.id_pat_cit%TYPE,
        o_id_pat_cit_hist          OUT pat_cit_hist.id_pat_cit_hist%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_id_cit          pat_cit.id_pat_cit%TYPE;
        l_cit_status      pat_cit.flg_status%TYPE;
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
    
        l_dt_start_period_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_period_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_event_tstz        TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_stop_work_tstz    TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        pk_alertlog.log_info('SET_CIT_INAIL: i_patient = ' || i_patient || ', i_episode = ' || i_episode ||
                             ', i_cit = ' || i_cit);
    
        g_sysdate_tstz         := current_timestamp;
        l_dt_start_period_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start_period_tstz, NULL);
        l_dt_end_period_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_period_tstz, NULL);
        l_dt_event_tstz        := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_event_tstz, NULL);
        l_dt_stop_work_tstz    := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_stop_work_tstz, NULL);
    
        g_error := 'UPDATE or EDIT CIT';
        pk_alertlog.log_debug(g_error);
    
        IF i_cit IS NULL
        THEN
            -- insere um registo novo
            l_id_cit     := ts_pat_cit.next_key;
            l_cit_status := g_flg_status_construction;
        
            g_error := 'INSERT PAT_CIT FP';
            ts_pat_cit.ins(id_pat_cit_in               => l_id_cit,
                           id_patient_in               => i_patient,
                           id_episode_in               => i_episode,
                           accident_cause_in           => i_accident_cause,
                           flg_cit_type_in             => i_flg_cit_type,
                           flg_prognosis_type_in       => i_flg_prognosis_type,
                           flg_permanent_disability_in => i_flg_permanent_disability,
                           flg_life_danger_in          => i_flg_life_danger,
                           dt_start_period_tstz_in     => l_dt_start_period_tstz,
                           dt_end_period_tstz_in       => l_dt_end_period_tstz,
                           dt_event_tstz_in            => l_dt_event_tstz,
                           id_county_accident_in       => i_id_county_accident,
                           flg_accident_type_in        => i_flg_accident_type,
                           landline_prefix_in          => i_landline_prefix,
                           landline_number_in          => i_landline_number,
                           mobile_prefix_in            => i_mobile_prefix,
                           mobile_number_in            => i_mobile_number,
                           flg_status_in               => l_cit_status, -- construction ou edited dependendo do caso
                           flg_type_in                 => g_flg_type_inail,
                           id_prof_writes_in           => i_prof.id,
                           dt_writes_tstz_in           => g_sysdate_tstz,
                           dt_stop_work_tstz_in        => l_dt_stop_work_tstz,
                           rows_out                    => l_rowids);
        
            g_error := 'PROCESS DATA_GOV_MNT';
            pk_alertlog.log_debug(g_error);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            --update
            l_id_cit     := i_cit;
            l_cit_status := g_flg_status_edited;
        
            g_error := 'CREATE THE HISTORY RECORD';
            pk_alertlog.log_debug(g_error);
        
            set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
        
            g_error := 'UPDATE PAT_CIT FP';
            ts_pat_cit.upd(id_pat_cit_in                => l_id_cit,
                           id_patient_in                => i_patient,
                           id_episode_in                => i_episode,
                           accident_cause_in            => i_accident_cause,
                           accident_cause_nin           => FALSE,
                           flg_cit_type_in              => i_flg_cit_type,
                           flg_cit_type_nin             => FALSE,
                           flg_prognosis_type_in        => i_flg_prognosis_type,
                           flg_prognosis_type_nin       => FALSE,
                           flg_permanent_disability_in  => i_flg_permanent_disability,
                           flg_permanent_disability_nin => FALSE,
                           flg_life_danger_in           => i_flg_life_danger,
                           flg_life_danger_nin          => FALSE,
                           dt_start_period_tstz_in      => l_dt_start_period_tstz,
                           dt_start_period_tstz_nin     => FALSE,
                           dt_end_period_tstz_in        => l_dt_end_period_tstz,
                           dt_end_period_tstz_nin       => FALSE,
                           dt_event_tstz_in             => l_dt_event_tstz,
                           dt_event_tstz_nin            => FALSE,
                           id_county_accident_in        => i_id_county_accident,
                           id_county_accident_nin       => FALSE,
                           flg_accident_type_in         => i_flg_accident_type,
                           flg_accident_type_nin        => FALSE,
                           landline_prefix_in           => i_landline_prefix,
                           landline_prefix_nin          => FALSE,
                           landline_number_in           => i_landline_number,
                           landline_number_nin          => FALSE,
                           mobile_prefix_in             => i_mobile_prefix,
                           mobile_prefix_nin            => FALSE,
                           mobile_number_in             => i_mobile_number,
                           mobile_number_nin            => FALSE,
                           flg_status_in                => l_cit_status, -- construction ou edited dependendo do caso
                           flg_type_in                  => g_flg_type_inail,
                           id_prof_writes_in            => i_prof.id,
                           dt_writes_tstz_in            => g_sysdate_tstz,
                           dt_stop_work_tstz_in         => l_dt_stop_work_tstz,
                           dt_stop_work_tstz_nin        => FALSE,
                           rows_out                     => l_rowids);
        
            g_error := 'PROCESS DATA_GOV_MNT';
            pk_alertlog.log_debug(g_error);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        --IMPORTANT: This function will be used directly be the ADT layer, and for that reason it cannot commit the transaction.
        o_id_pat_cit      := l_id_cit;
        o_id_pat_cit_hist := l_id_pat_cit_hist;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CIT_INAIL',
                                                     o_error);
    END set_cit_inail;

    /********************************************************************************************
    * Função de actualização/criação de CIT  - Sick leave (dependendo da passagem ou não da i_cit)
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @param IN   i_cit                            CIT ID
    * @param IN   i_dt_start_period_tstz           Inicial date (working capacity 0%)
    * @param IN   i_dt_end_period_tstz             End date (working capacity 100%)
    * @param IN   i_flg_work_zero_capac_end        Flg Duration (working capacity 0%) value(D,P,I)
    * @param IN   i_dt_work_zero_capac_end         Duration date (working capacity 0%)
    * @param IN   i_num_work_zero_capac_end        Duration value (working capacity 0%)
    * @param IN   i_num_work_zero_capac_end_unit   Duration unit (working capacity 0%)
    * @param IN   i_num_work_other_percentage      Percentage of intermediate work capacity
    * @param IN   i_dt_work_other_capac_start      Intermediate work capacity start
    * @param IN   i_flg_work_other_capac_end       Flg Duration (intermediate work capacity) value(D,P,I)
    * @param IN   i_dt_work_other_capac_end        Duration date (intermediate working capacity)
    * @param IN   i_num_work_other_capac_end       Duration value (intermediate working capacity)
    * @param IN   i_num_work_other_capac_end_unit  Duration unit (intermediate working capacity)
    * @param IN   i_reason                         Reason       
    * @param IN   i_notes                          Notes       
    * @param IN   i_dt_internment_begin            Internment begin
    * @param IN   i_dt_internment_end              Internment end
    * @param IN   i_dt_treatment_end               Treatmend end
    * @param IN   i_dt_renew                       Renew Date
    *
    * @author                   Jorge Silva
    * @since                    11/12/2012
    ********************************************************************************************/
    FUNCTION set_cit_sick_leave
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                          IN pat_cit.id_pat_cit%TYPE,
        i_dt_start_period_tstz         IN VARCHAR2,
        i_dt_end_period_tstz           IN VARCHAR2,
        i_flg_work_zero_capac_end      IN pat_cit.flg_zero_capac_end%TYPE,
        i_dt_work_zero_capac_end       IN VARCHAR2,
        i_num_work_zero_capac_end      IN pat_cit.zero_capac_end_num%TYPE,
        i_num_work_zero_capac_end_unit IN pat_cit.zero_capac_end_unit%TYPE,
        i_num_work_other_percentage    IN pat_cit.other_percentage_num%TYPE,
        i_dt_work_other_capac_start    IN VARCHAR2,
        i_flg_work_other_capac_end     IN pat_cit.flg_other_capac%TYPE,
        i_dt_work_other_capac_end      IN VARCHAR2,
        i_num_work_other_capac_end     IN pat_cit.other_capac_end_num%TYPE,
        i_work_other_capac_end_unit    IN pat_cit.other_capac_end_unit%TYPE,
        i_reason                       IN pat_cit.flg_reason%TYPE,
        i_notes                        IN pat_cit.notes_desc%TYPE,
        i_dt_internment_begin          IN VARCHAR2,
        i_dt_internment_end            IN VARCHAR2,
        i_dt_treatment_end             IN VARCHAR2,
        i_dt_renew                     IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_id_cit          pat_cit.id_pat_cit%TYPE;
        l_cit_status      pat_cit.flg_status%TYPE;
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
    
        l_dt_start_period_tstz         TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_period_tstz           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_work_zero_capac_end_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_work_other_capac_start_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_work_other_capac_end_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_internment_begin_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_internment_end_tstz       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_treatment_end_tstz        TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_renew_tstz                TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        IF i_cit IS NULL -- insere um registo novo
        THEN
            l_id_cit     := ts_pat_cit.next_key;
            l_cit_status := g_flg_status_construction;
        ELSE
            IF i_dt_renew IS NULL
            THEN
                l_id_cit     := i_cit;
                l_cit_status := g_flg_status_edited;
                set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
            ELSE
                l_id_cit     := i_cit;
                l_cit_status := g_flg_status_renew;
                set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
            END IF;
        END IF;
    
        g_sysdate_tstz                 := current_timestamp;
        l_dt_start_period_tstz         := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start_period_tstz, NULL);
        l_dt_end_period_tstz           := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_period_tstz, NULL);
        l_dt_work_zero_capac_end_tstz  := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_work_zero_capac_end, NULL);
        l_work_other_capac_start_tstz  := pk_date_utils.get_string_tstz(i_lang,
                                                                        i_prof,
                                                                        i_dt_work_other_capac_start,
                                                                        NULL);
        l_dt_work_other_capac_end_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_work_other_capac_end, NULL);
        l_dt_internment_begin_tstz     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_internment_begin, NULL);
        l_dt_internment_end_tstz       := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_internment_end, NULL);
        l_dt_treatment_end_tstz        := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_treatment_end, NULL);
        l_dt_renew_tstz                := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_renew, NULL);
    
        g_error := 'UPDATE PAT_CIT FP';
    
        IF l_cit_status = g_flg_status_construction
        THEN
            ts_pat_cit.ins(id_pat_cit_in              => l_id_cit,
                           id_patient_in              => i_patient,
                           id_episode_in              => i_episode,
                           flg_zero_capac_end_in      => i_flg_work_zero_capac_end,
                           dt_zero_capac_end_in       => l_dt_work_zero_capac_end_tstz,
                           zero_capac_end_num_in      => i_num_work_zero_capac_end,
                           zero_capac_end_unit_in     => i_num_work_zero_capac_end_unit,
                           other_percentage_num_in    => i_num_work_other_percentage,
                           flg_other_capac_in         => i_flg_work_other_capac_end,
                           dt_other_capac_start_in    => l_work_other_capac_start_tstz,
                           dt_other_capac_end_in      => l_dt_work_other_capac_end_tstz,
                           other_capac_end_num_in     => i_num_work_other_capac_end,
                           other_capac_end_unit_in    => i_work_other_capac_end_unit,
                           flg_reason_in              => i_reason,
                           notes_desc_in              => i_notes,
                           dt_internment_pat_begin_in => l_dt_internment_begin_tstz,
                           dt_internment_pat_end_in   => l_dt_internment_end_tstz,
                           dt_treatment_end_in        => l_dt_treatment_end_tstz,
                           dt_start_period_tstz_in    => l_dt_start_period_tstz,
                           dt_end_period_tstz_in      => l_dt_end_period_tstz,
                           flg_status_in              => l_cit_status, -- construction ou edited dependendo do caso
                           flg_type_in                => g_flg_type_sick_leave,
                           id_prof_writes_in          => i_prof.id,
                           dt_writes_tstz_in          => g_sysdate_tstz,
                           rows_out                   => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            ts_pat_cit.upd(id_pat_cit_in               => l_id_cit,
                           id_patient_in               => i_patient,
                           id_episode_in               => i_episode,
                           flg_zero_capac_end_in       => i_flg_work_zero_capac_end,
                           flg_zero_capac_end_nin      => FALSE,
                           dt_zero_capac_end_nin       => FALSE,
                           dt_zero_capac_end_in        => l_dt_work_zero_capac_end_tstz,
                           zero_capac_end_num_nin      => FALSE,
                           zero_capac_end_num_in       => i_num_work_zero_capac_end,
                           zero_capac_end_unit_nin     => FALSE,
                           zero_capac_end_unit_in      => i_num_work_zero_capac_end_unit,
                           other_percentage_num_nin    => FALSE,
                           other_percentage_num_in     => i_num_work_other_percentage,
                           flg_other_capac_nin         => FALSE,
                           flg_other_capac_in          => i_flg_work_other_capac_end,
                           dt_other_capac_start_nin    => FALSE,
                           dt_other_capac_start_in     => l_work_other_capac_start_tstz,
                           dt_other_capac_end_nin      => FALSE,
                           dt_other_capac_end_in       => l_dt_work_other_capac_end_tstz,
                           other_capac_end_num_nin     => FALSE,
                           other_capac_end_num_in      => i_num_work_other_capac_end,
                           other_capac_end_unit_nin    => FALSE,
                           other_capac_end_unit_in     => i_work_other_capac_end_unit,
                           flg_reason_nin              => FALSE,
                           flg_reason_in               => i_reason,
                           notes_desc_nin              => FALSE,
                           notes_desc_in               => i_notes,
                           dt_internment_pat_begin_nin => FALSE,
                           dt_internment_pat_begin_in  => l_dt_internment_begin_tstz,
                           dt_internment_pat_end_nin   => FALSE,
                           dt_internment_pat_end_in    => l_dt_internment_end_tstz,
                           dt_treatment_end_nin        => FALSE,
                           dt_treatment_end_in         => l_dt_treatment_end_tstz,
                           dt_start_period_tstz_nin    => FALSE,
                           dt_start_period_tstz_in     => l_dt_start_period_tstz,
                           dt_end_period_tstz_nin      => FALSE,
                           dt_end_period_tstz_in       => l_dt_end_period_tstz,
                           flg_status_in               => l_cit_status, -- construction ou edited dependendo do caso
                           flg_type_in                 => g_flg_type_sick_leave,
                           dt_certificate_renew_nin    => FALSE,
                           dt_certificate_renew_in     => l_dt_renew_tstz,
                           id_prof_writes_in           => i_prof.id,
                           dt_writes_tstz_in           => g_sysdate_tstz,
                           rows_out                    => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        IF l_rowids.count != 0
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CIT_SICK_LEAVE',
                                                     o_error);
    END;

    /**
    * Change a CI status to printed.
    * Generates change history.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_cit          ci identifier
    * @param i_episode      episode identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2012/06/20
    */
    PROCEDURE print_cit_int
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) IS
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
        l_rowids          table_varchar;
        l_error           t_error_out;
        l_type            pat_cit.flg_type%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT pc.flg_type flg_type
          INTO l_type
          FROM pat_cit pc
         WHERE pc.id_pat_cit = i_cit;
    
        set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
    
        g_error := 'UPDATE PAT_CIT';
    
        IF (l_type <> g_flg_type_sick_leave)
        THEN
            ts_pat_cit.upd(id_pat_cit_in     => i_cit,
                           flg_status_in     => g_flg_status_printed, -- fica com estado Impresso
                           id_prof_writes_in => i_prof.id,
                           dt_writes_tstz_in => g_sysdate_tstz,
                           id_episode_in     => i_episode,
                           rows_out          => l_rowids);
        ELSE
            ts_pat_cit.upd(id_pat_cit_in     => i_cit,
                           flg_status_in     => g_flg_status_ongoing, -- fica com estado Em curso
                           id_prof_writes_in => i_prof.id,
                           dt_writes_tstz_in => g_sysdate_tstz,
                           id_episode_in     => i_episode,
                           rows_out          => l_rowids);
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_CIT',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
    END print_cit_int;

    /********************************************************************************************
    * Função de registo que a CIT foi impressa  - Segurança Social 
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
       
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION print_cit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_cit IS NULL
        THEN
            g_error := 'i_cit cannot be NULL!';
            RAISE g_exception;
        END IF;
    
        print_cit_int(i_lang => i_lang, i_prof => i_prof, i_cit => i_cit, i_episode => i_episode);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'PRINT_CIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END print_cit;

    /********************************************************************************************
    * Function to update the INAIL state, after the data has been sent and correctly received 
    * by the external system.
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param IN   i_cit         CIT ID    
    *
    * @param OUT  o_error       Error structure
    *
    * @return                   true on success and false if error occurs                   
    *
    * @author                   Orlando Antunes
    * @since                    11/01/2011
    ********************************************************************************************/
    FUNCTION set_cit_inail_received
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_info('SET_CIT_INAIL_RECEIVED: i_patient = ' || i_patient || ', i_cit = ' || i_cit);
    
        IF NOT print_cit(i_lang    => i_lang,
                         i_prof    => i_prof,
                         i_patient => i_patient,
                         i_episode => i_episode,
                         i_cit     => i_cit,
                         o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CIT_INAIL_RECEIVED',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função de cancelamento do CIT
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
       
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION cancel_cit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_cit              IN pat_cit.id_pat_cit%TYPE,
        i_id_cancel_reason IN pat_cit.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_cit.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
    
    BEGIN
        IF i_cit IS NULL
        THEN
            RETURN FALSE;
        ELSE
            set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
        END IF;
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'UPDATE PAT_CIT';
        ts_pat_cit.upd(id_pat_cit_in       => i_cit,
                       id_patient_in       => i_patient,
                       id_episode_in       => i_episode,
                       flg_status_in       => g_flg_status_canceled, -- fica com estado Cancelado
                       id_prof_writes_in   => i_prof.id,
                       dt_writes_tstz_in   => g_sysdate_tstz,
                       id_cancel_reason_in => i_id_cancel_reason,
                       cancel_notes_in     => i_cancel_notes,
                       rows_out            => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_CIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_CIT',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função de criação de registo de histórico de CIT baseado no id do CIT enviado
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
       
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    PROCEDURE set_cit_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cit             IN pat_cit.id_pat_cit%TYPE,
        o_id_pat_cit_hist OUT pat_cit_hist.id_pat_cit_hist%TYPE
    ) IS
    
        l_rowids   table_varchar;
        l_cit      pat_cit%ROWTYPE;
        l_cit_hist pat_cit_hist%ROWTYPE;
        l_error    t_error_out;
    BEGIN
    
        g_error := 'SELECT INTO .. FROM PAT_CIT';
        SELECT *
          INTO l_cit
          FROM pat_cit pc
         WHERE pc.id_pat_cit = i_cit;
    
        l_cit_hist.id_pat_cit_hist           := ts_pat_cit_hist.next_key;
        l_cit_hist.id_pat_cit                := l_cit.id_pat_cit;
        l_cit_hist.id_patient                := l_cit.id_patient;
        l_cit_hist.id_episode                := l_cit.id_episode;
        l_cit_hist.flg_pat_disease_state     := l_cit.flg_pat_disease_state;
        l_cit_hist.flg_prof_health_subsys    := l_cit.flg_prof_health_subsys;
        l_cit_hist.beneficiary_number        := l_cit.beneficiary_number;
        l_cit_hist.ill_parent_name           := l_cit.ill_parent_name;
        l_cit_hist.flg_ill_affinity          := l_cit.flg_ill_affinity;
        l_cit_hist.ill_id_card               := l_cit.ill_id_card;
        l_cit_hist.flg_benef_health_subsys   := l_cit.flg_benef_health_subsys;
        l_cit_hist.flg_cit_classification_ss := l_cit.flg_cit_classification_ss;
        l_cit_hist.flg_cit_classification_fp := l_cit.flg_cit_classification_fp;
        l_cit_hist.flg_internment            := l_cit.flg_internment;
        l_cit_hist.flg_incapacity_period     := l_cit.flg_incapacity_period;
        l_cit_hist.dt_start_period_tstz      := l_cit.dt_start_period_tstz;
        l_cit_hist.dt_end_period_tstz        := l_cit.dt_end_period_tstz;
        l_cit_hist.flg_home_absence          := l_cit.flg_home_absence;
        l_cit_hist.home_authorization        := l_cit.home_authorization;
        l_cit_hist.flg_status                := l_cit.flg_status; -- fica com o status que o CIT tinha
        l_cit_hist.flg_type                  := l_cit.flg_type;
        l_cit_hist.id_prof_writes            := l_cit.id_prof_writes;
        l_cit_hist.dt_writes_tstz            := l_cit.dt_writes_tstz;
        l_cit_hist.id_cancel_reason          := l_cit.id_cancel_reason;
        l_cit_hist.cancel_notes              := l_cit.cancel_notes;
        l_cit_hist.accident_cause            := l_cit.accident_cause;
        l_cit_hist.flg_cit_type              := l_cit.flg_cit_type;
        l_cit_hist.flg_prognosis_type        := l_cit.flg_prognosis_type;
        l_cit_hist.flg_permanent_disability  := l_cit.flg_permanent_disability;
        l_cit_hist.flg_life_danger           := l_cit.flg_life_danger;
        l_cit_hist.dt_event_tstz             := l_cit.dt_event_tstz;
        l_cit_hist.dt_stop_work_tstz         := l_cit.dt_stop_work_tstz;
        l_cit_hist.id_county_accident        := l_cit.id_county_accident;
        l_cit_hist.flg_accident_type         := l_cit.flg_accident_type;
        l_cit_hist.landline_prefix           := l_cit.landline_prefix;
        l_cit_hist.landline_number           := l_cit.landline_number;
        l_cit_hist.mobile_prefix             := l_cit.mobile_prefix;
        l_cit_hist.mobile_number             := l_cit.mobile_number;
        l_cit_hist.flg_zero_capac_end        := l_cit.flg_zero_capac_end;
        l_cit_hist.dt_zero_capac_end         := l_cit.dt_zero_capac_end;
        l_cit_hist.zero_capac_end_num        := l_cit.zero_capac_end_num;
        l_cit_hist.zero_capac_end_unit       := l_cit.zero_capac_end_unit;
        l_cit_hist.other_percentage_num      := l_cit.other_percentage_num;
        l_cit_hist.dt_other_capac_start      := l_cit.dt_other_capac_start;
        l_cit_hist.flg_other_capac           := l_cit.flg_other_capac;
        l_cit_hist.dt_other_capac_end        := l_cit.dt_other_capac_end;
        l_cit_hist.other_capac_end_num       := l_cit.other_capac_end_num;
        l_cit_hist.other_capac_end_unit      := l_cit.other_capac_end_unit;
        l_cit_hist.flg_reason                := l_cit.flg_reason;
        l_cit_hist.notes_desc                := l_cit.notes_desc;
        l_cit_hist.dt_internment_pat_begin   := l_cit.dt_internment_pat_begin;
        l_cit_hist.dt_internment_pat_end     := l_cit.dt_internment_pat_end;
        l_cit_hist.dt_treatment_end          := l_cit.dt_treatment_end;
        l_cit_hist.dt_certificate_renew      := l_cit.dt_certificate_renew;
    
        g_error := 'INSERT INTO PAT_CIT_HIST SS';
        ts_pat_cit_hist.ins(rec_in => l_cit_hist, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_CIT_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
        o_id_pat_cit_hist := l_cit_hist.id_pat_cit_hist;
    END;

    /********************************************************************************************
    * Função que retorna detalhe do CIT seleccionado - Segurança Social 
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION get_cit_det_social
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cit_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_cit_det FOR
            SELECT pk_sysdomain.get_domain(g_cit_flg_status, pc.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit,
                   pk_date_utils.date_send_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_prof_name,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   p.num_order prof_code,
                   pk_sysdomain.get_domain(g_cit_flg_pat_disease_state, pc.flg_pat_disease_state, i_lang) desc_pat_disease_state,
                   pc.beneficiary_number beneficiary_num,
                   pk_date_utils.dt_chr_tsz(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                   pat.name pat_name,
                   nvl(pc.ill_parent_name, '--') ill_parent_name,
                   nvl(pk_sysdomain.get_domain(g_cit_flg_ill_affinity, pc.flg_ill_affinity, i_lang), '--') desc_ill_affinity,
                   pc.ill_id_card ill_id_card,
                   pk_sysdomain.get_domain(g_cit_flg_cit_ss, pc.flg_cit_classification_ss, i_lang) desc_cit_classification_ss,
                   pk_sysdomain.get_domain(g_cit_flg_internment, pc.flg_internment, i_lang) desc_internment,
                   pk_sysdomain.get_domain(g_cit_flg_incapacity_period, pc.flg_incapacity_period, i_lang) desc_incapacity_period,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_period_tstz,
                   to_date(to_char(pc.dt_end_period_tstz, 'yyyymmdd'), 'yyyymmdd') -
                   to_date(to_char(pc.dt_start_period_tstz, 'yyyymmdd'), 'yyyymmdd') num_days,
                   pc.home_authorization home_authorization,
                   pc.flg_status flg_status,
                   decode(pc.flg_status,
                          g_flg_status_canceled,
                          nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pc.id_cancel_reason), '--'),
                          '--') cancel_reason,
                   decode(pc.flg_status, g_flg_status_canceled, nvl(pc.cancel_notes, '--'), '--') cancel_notes,
                   1 sequence
              FROM pat_cit pc, patient pat, professional p
             WHERE pc.id_pat_cit = i_cit
               AND pc.id_patient = pat.id_patient
               AND pc.id_prof_writes = p.id_professional
            UNION ALL
            SELECT pk_sysdomain.get_domain(g_cit_flg_status, pc.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit,
                   pk_date_utils.date_send_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_prof_name,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   p.num_order prof_code,
                   pk_sysdomain.get_domain(g_cit_flg_pat_disease_state, pc.flg_pat_disease_state, i_lang) desc_pat_disease_state,
                   pc.beneficiary_number beneficiary_num,
                   pk_date_utils.dt_chr_tsz(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                   pat.name pat_name,
                   nvl(pc.ill_parent_name, '--') ill_parent_name,
                   nvl(pk_sysdomain.get_domain(g_cit_flg_ill_affinity, pc.flg_ill_affinity, i_lang), '--') desc_ill_affinity,
                   pc.ill_id_card ill_id_card,
                   pk_sysdomain.get_domain(g_cit_flg_cit_ss, pc.flg_cit_classification_ss, i_lang) desc_cit_classification_ss,
                   pk_sysdomain.get_domain(g_cit_flg_internment, pc.flg_internment, i_lang) desc_internment,
                   pk_sysdomain.get_domain(g_cit_flg_incapacity_period, pc.flg_incapacity_period, i_lang) desc_incapacity_period,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_period_tstz,
                   to_date(to_char(pc.dt_end_period_tstz, 'yyyymmdd'), 'yyyymmdd') -
                   to_date(to_char(pc.dt_start_period_tstz, 'yyyymmdd'), 'yyyymmdd') num_days,
                   pc.home_authorization home_authorization,
                   pc.flg_status flg_status,
                   decode(pc.flg_status,
                          g_flg_status_canceled,
                          nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pc.id_cancel_reason), '--'),
                          '--') cancel_reason,
                   decode(pc.flg_status, g_flg_status_canceled, nvl(pc.cancel_notes, '--'), '--') cancel_notes,
                   2 sequence
              FROM pat_cit_hist pc, patient pat, professional p
             WHERE pc.id_pat_cit = i_cit
               AND pc.id_patient = pat.id_patient
               AND pc.id_prof_writes = p.id_professional
             ORDER BY sequence, dt_cit_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cit_det);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_DET_SOCIAL',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função que retorna detalhe do CIT seleccionado - Função Pública
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION get_cit_det_public
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cit_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_cit_det FOR
            SELECT pk_sysdomain.get_domain(g_cit_flg_status, pc.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit,
                   pk_date_utils.date_send_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_prof_name,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   p.num_order prof_code,
                   pk_sysdomain.get_domain(g_cit_flg_pat_disease_state, pc.flg_pat_disease_state, i_lang) desc_pat_disease_state,
                   pk_sysdomain.get_domain(g_cit_flg_prof_health_subsys, pc.flg_prof_health_subsys, i_lang) desc_prof_health_subsys,
                   pc.beneficiary_number beneficiary_num,
                   pk_date_utils.dt_chr_tsz(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                   pat.name pat_name,
                   nvl(pc.ill_parent_name, '--') ill_parent_name,
                   nvl(pk_sysdomain.get_domain(g_cit_flg_ill_affinity, pc.flg_ill_affinity, i_lang), '--') desc_ill_affinity,
                   pc.ill_id_card ill_id_card,
                   pk_sysdomain.get_domain(g_cit_flg_prof_health_subsys, pc.flg_benef_health_subsys, i_lang) desc_benef_health_subsys,
                   pk_sysdomain.get_domain(g_cit_flg_cit_fp, pc.flg_cit_classification_fp, i_lang) desc_cit_classification_fp,
                   pk_sysdomain.get_domain(g_cit_flg_internment, pc.flg_internment, i_lang) desc_internment,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_period_tstz,
                   to_date(to_char(pc.dt_end_period_tstz, 'yyyymmdd'), 'yyyymmdd') -
                   to_date(to_char(pc.dt_start_period_tstz, 'yyyymmdd'), 'yyyymmdd') num_days,
                   pk_sysdomain.get_domain(g_cit_flg_home_absence, pc.flg_home_absence, i_lang) desc_home_absence,
                   pc.flg_status flg_status,
                   decode(pc.flg_status,
                          g_flg_status_canceled,
                          nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pc.id_cancel_reason), '--'),
                          '--') cancel_reason,
                   decode(pc.flg_status, g_flg_status_canceled, nvl(pc.cancel_notes, '--'), '--') cancel_notes,
                   1 sequence
              FROM pat_cit pc, patient pat, professional p
             WHERE pc.id_pat_cit = i_cit
               AND pc.id_patient = pat.id_patient
               AND pc.id_prof_writes = p.id_professional
            UNION ALL
            SELECT pk_sysdomain.get_domain(g_cit_flg_status, pc.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit,
                   pk_date_utils.date_send_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_prof_name,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   p.num_order prof_code,
                   pk_sysdomain.get_domain(g_cit_flg_pat_disease_state, pc.flg_pat_disease_state, i_lang) desc_pat_disease_state,
                   pk_sysdomain.get_domain(g_cit_flg_prof_health_subsys, pc.flg_prof_health_subsys, i_lang) desc_prof_health_subsys,
                   pc.beneficiary_number beneficiary_num,
                   pk_date_utils.dt_chr_tsz(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                   pat.name pat_name,
                   nvl(pc.ill_parent_name, '--') ill_parent_name,
                   nvl(pk_sysdomain.get_domain(g_cit_flg_ill_affinity, pc.flg_ill_affinity, i_lang), '--') desc_ill_affinity,
                   pc.ill_id_card ill_id_card,
                   pk_sysdomain.get_domain(g_cit_flg_prof_health_subsys, pc.flg_benef_health_subsys, i_lang) desc_benef_health_subsys,
                   pk_sysdomain.get_domain(g_cit_flg_cit_fp, pc.flg_cit_classification_fp, i_lang) desc_cit_classification_fp,
                   pk_sysdomain.get_domain(g_cit_flg_internment, pc.flg_internment, i_lang) desc_internment,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof) dt_end_period_tstz,
                   to_date(to_char(pc.dt_end_period_tstz, 'yyyymmdd'), 'yyyymmdd') -
                   to_date(to_char(pc.dt_start_period_tstz, 'yyyymmdd'), 'yyyymmdd') num_days,
                   pk_sysdomain.get_domain(g_cit_flg_home_absence, pc.flg_home_absence, i_lang) desc_home_absence,
                   pc.flg_status flg_status,
                   decode(pc.flg_status,
                          g_flg_status_canceled,
                          nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pc.id_cancel_reason), '--'),
                          '--') cancel_reason,
                   decode(pc.flg_status, g_flg_status_canceled, nvl(pc.cancel_notes, '--'), '--') cancel_notes,
                   2 sequence
              FROM pat_cit_hist pc, patient pat, professional p
             WHERE pc.id_pat_cit = i_cit
               AND pc.id_patient = pat.id_patient
               AND pc.id_prof_writes = p.id_professional
             ORDER BY sequence, dt_cit_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cit_det);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_DET_PUBLIC',
                                                     o_error);
    END;

    /********************************************************************************************
    * Função que retorna detalhe do CIT seleccionado - Sick leave
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_history     Boolean que indica se queremos que devolve o histórico 
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return    Boolean
    *
    * @author                   Jorge Silva
    * @since                    13-12-2012
    ********************************************************************************************/
    FUNCTION get_cit_det_sick_leave
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        i_history IN BOOLEAN,
        o_cit_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_history NUMBER(1);
    
    BEGIN
        IF i_history = TRUE
        THEN
            l_history := 1;
        ELSE
            l_history := 0;
        END IF;
    
        OPEN o_cit_det FOR
            SELECT pk_sysdomain.get_domain(g_cit_flg_status, pc.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit, --cit date  
                   pk_date_utils.date_send_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_prof_name,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   p.num_order prof_code,
                   pk_date_utils.dt_chr_tsz(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                   pat.name pat_name,
                   pk_message.get_message(i_lang, 'PAT_CIT_T043') capacity_title_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T044') capacity_subtitle_zero_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T045') capacity_start_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz, -- capacity start 0%
                   pk_message.get_message(i_lang, 'PAT_CIT_T046') capacity_end_period_desc,
                   decode(pc.flg_zero_capac_end,
                          g_capacity_date,
                          pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_zero_capac_end, i_prof),
                          g_capacity_indefinite,
                          pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                          g_capacity_periode,
                          pk_string_utils.concat_if_exists(pc.zero_capac_end_num,
                                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                        i_prof,
                                                                                                        pc.zero_capac_end_unit),
                                                           '')) dt_duration_zero_str, -- Duration 0%
                   pk_message.get_message(i_lang, 'PAT_CIT_T047') capacity_subtitle_other_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T048') capacity_percentage_desc,
                   decode(pc.other_percentage_num,
                          NULL,
                          '',
                          pk_string_utils.concat_if_exists(pc.other_percentage_num, '%', ' ')) percentage_str, -- Percentage (other %)
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof) dt_begin_other_str, -- start date (other %)
                   decode(pc.flg_other_capac,
                          g_capacity_date,
                          pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_end, i_prof),
                          g_capacity_indefinite,
                          pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                          g_capacity_periode,
                          pk_string_utils.concat_if_exists(pc.other_capac_end_num,
                                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                        i_prof,
                                                                                                        pc.other_capac_end_unit),
                                                           '')) dt_duration_other_str, -- End date (other %)
                   pk_message.get_message(i_lang, 'PAT_CIT_T056') capacity_end_desc,
                   nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
                       pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang)) dt_end_period_tstz, -- capacity start (100%)
                   pk_message.get_message(i_lang, 'PAT_CIT_T047') capacity_subtitle_other_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T048') capacity_percentage_desc,
                   pk_sysdomain.get_domain(g_cit_flg_reason, pc.flg_reason, i_lang) reason_desc, -- reason
                   pk_message.get_message(i_lang, 'PAT_CIT_T050') other_notes_desc,
                   pc.notes_desc notes, --notes
                   pk_message.get_message(i_lang, 'PAT_CIT_T054') other_internment_begin_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_internment_pat_begin, i_prof) dt_internment_begin_str, -- internment start
                   pk_message.get_message(i_lang, 'PAT_CIT_T051') other_internment_end_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_internment_pat_end, i_prof) dt_internment_end_str, -- internment end
                   pk_message.get_message(i_lang, 'PAT_CIT_T053') other_treatment_end_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_treatment_end, i_prof) dt_treatment_end_str, -- treatment end
                   pc.flg_status flg_status, -- flag status
                   decode(pc.flg_status,
                          g_flg_status_canceled,
                          nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pc.id_cancel_reason), '--'),
                          '--') cancel_reason,
                   decode(pc.flg_status, g_flg_status_canceled, nvl(pc.cancel_notes, '--'), '--') cancel_notes,
                   1 sequence
              FROM pat_cit pc, patient pat, professional p
             WHERE pc.id_pat_cit = i_cit
               AND pc.id_patient = pat.id_patient
               AND pc.id_prof_writes = p.id_professional
            UNION ALL
            SELECT pk_sysdomain.get_domain(g_cit_flg_status, pc.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit, --cit date 
                   pk_date_utils.date_send_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) dt_cit_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_prof_name,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   p.num_order prof_code,
                   pk_date_utils.dt_chr_tsz(i_lang, pat.dt_birth, i_prof) pat_dt_birth,
                   pat.name pat_name,
                   pk_message.get_message(i_lang, 'PAT_CIT_T043') capacity_title_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T044') capacity_subtitle_zero_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T045') capacity_start_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) dt_start_period_tstz, -- capacity start 0%
                   pk_message.get_message(i_lang, 'PAT_CIT_T046') capacity_end_period_desc,
                   decode(pc.flg_zero_capac_end,
                          g_capacity_date,
                          pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_zero_capac_end, i_prof),
                          g_capacity_indefinite,
                          pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                          g_capacity_periode,
                          pk_string_utils.concat_if_exists(pc.zero_capac_end_num,
                                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                        i_prof,
                                                                                                        pc.zero_capac_end_unit),
                                                           ' ')) dt_duration_zero_str, -- Duration 0%
                   pk_message.get_message(i_lang, 'PAT_CIT_T047') capacity_subtitle_other_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T048') capacity_percentage,
                   pk_string_utils.concat_if_exists(pc.other_percentage_num, '%', ' ') percentage_str, -- Percentage (other %)
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof) dt_begin_other_str, -- start date (other %)
                   decode(pc.flg_other_capac,
                          g_capacity_date,
                          pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_end, i_prof),
                          g_capacity_indefinite,
                          pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                          g_capacity_periode,
                          pk_string_utils.concat_if_exists(pc.other_capac_end_num,
                                                           pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                        i_prof,
                                                                                                        pc.other_capac_end_unit),
                                                           ' ')) dt_duration_other_str, -- End date (other %)
                   pk_message.get_message(i_lang, 'PAT_CIT_T056') capacity_end_desc,
                   nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
                       pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang)) dt_end_period_tstz, -- capacity start
                   pk_message.get_message(i_lang, 'PAT_CIT_T049') other_title_desc,
                   pk_message.get_message(i_lang, 'PAT_CIT_T052') other_reason_desc,
                   pk_sysdomain.get_domain(g_cit_flg_reason, pc.flg_reason, i_lang) reason_desc, -- reason
                   pk_message.get_message(i_lang, 'PAT_CIT_T050') other_notes_desc,
                   pc.notes_desc notes, --notes
                   pk_message.get_message(i_lang, 'PAT_CIT_T054') other_internment_begin_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_internment_pat_begin, i_prof) dt_internment_begin_str, -- internment start
                   pk_message.get_message(i_lang, 'PAT_CIT_T051') other_internment_end_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_internment_pat_end, i_prof) dt_internment_end_str, -- internment end
                   pk_message.get_message(i_lang, 'PAT_CIT_T053') other_treatment_end_desc,
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_treatment_end, i_prof) dt_treatment_end_str, -- treatment end
                   pc.flg_status flg_status, -- flag status
                   decode(pc.flg_status,
                          g_flg_status_canceled,
                          nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pc.id_cancel_reason), '--'),
                          '--') cancel_reason,
                   decode(pc.flg_status, g_flg_status_canceled, nvl(pc.cancel_notes, '--'), '--') cancel_notes,
                   2 sequence
              FROM pat_cit_hist pc, patient pat, professional p
             WHERE pc.id_pat_cit = i_cit
               AND l_history = 1
               AND pc.id_patient = pat.id_patient
               AND pc.id_prof_writes = p.id_professional
             ORDER BY sequence, dt_cit_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cit_det);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_DET_PUBLIC',
                                                     o_error);
    END;

    /********************************************************************************************
    * Devolve o nome do icone a mostrar que indica se o CIT está impresso, em construção ou cancelado
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_cit         CIT ID
    *
    * @return                   Nome do icone
    *
    * @author                   Pedro Teixeira
    * @since                    06/04/2009
    ********************************************************************************************/
    FUNCTION get_cit_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_desc_msg_arr FOR
            SELECT DISTINCT *
              FROM (SELECT code_message,
                           REPLACE(first_value(desc_message)
                                   over(PARTITION BY code_message ORDER BY id_institution ASC, id_software ASC),
                                   '*') desc_message,
                           first_value(img_name) over(PARTITION BY code_message ORDER BY id_institution ASC, id_software ASC) img_name
                      FROM sys_message
                     WHERE id_language = i_lang
                       AND code_message IN (SELECT /*+dynamic_sampling(t 2)*/
                                             t.column_value
                                              FROM TABLE(i_code_msg_arr) t)
                       AND flg_available = pk_alert_constant.g_yes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_desc_msg_arr);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CIT_MESSAGE_ARRAY',
                                                     o_error);
    END;

    /********************************************************************************************
    * This function validates if it is possible to edit a given CI. The only information needed to
    * perform this validation is the episode ID in which the CI was created, to check if the 
    * patient was discharged from the episode or not.
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_id_episode  Episode ID
    *
    * @return                   Y if the CIT can be edited or N otherwise
    *
    * @author                   Orlando Antunes
    * @since                    06/01/2011
    ********************************************************************************************/
    FUNCTION get_cit_edit_mode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_cit_edit_mode      sys_config.value%TYPE := pk_alert_constant.g_yes;
        l_cit_edit_mode_conf sys_config.value%TYPE;
        l_error              t_error_out;
    BEGIN
        pk_alertlog.log_debug('GET_CIT_EDIT_MODE: i_id_episode = ' || i_id_episode);
        l_cit_edit_mode_conf := pk_sysconfig.get_config('INAIL_EDIT_MODE', i_prof);
    
        pk_alertlog.log_debug('CIT_EDIT_MODE_CONF = ' || l_cit_edit_mode_conf);
    
        IF l_cit_edit_mode_conf = g_ci_inail_edit_mode_a
        THEN
            --Always possible to edit INAIL CIs
            l_cit_edit_mode := pk_alert_constant.g_yes;
        ELSIF l_cit_edit_mode_conf = g_ci_inail_edit_mode_d
        THEN
            --Only before the discharge is possible to edit INAIL CIs
            IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_episode   => i_id_episode,
                                                         o_discharge => l_cit_edit_mode,
                                                         o_error     => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            --It's not possible to edit INAIL CIs
            l_cit_edit_mode := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_cit_edit_mode;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- this is the default behavior.
            RETURN pk_alert_constant.g_yes;
    END;

    /**
    * Prints existing INAIL typed CIs.
    * To be called on medical discharges.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2012/06/20
    */
    PROCEDURE print_inail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'PRINT_INAIL';
        l_cit pat_cit.id_pat_cit%TYPE;
    
        CURSOR c_inail IS
            SELECT pc.id_pat_cit
              FROM pat_cit pc
             WHERE pc.id_patient = i_patient
               AND pc.id_episode = i_episode
               AND pc.flg_status IN
                   (g_flg_status_construction, g_flg_status_edited, g_flg_status_ongoing, g_flg_status_renew)
               AND pc.flg_type = g_flg_type_inail;
    BEGIN
        OPEN c_inail;
        FETCH c_inail
            INTO l_cit;
        CLOSE c_inail;
    
        IF l_cit IS NOT NULL
        THEN
            g_error := 'changing status of cit ' || l_cit || ' to printed...';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            print_cit_int(i_lang => i_lang, i_prof => i_prof, i_cit => l_cit, i_episode => i_episode);
        END IF;
    END print_inail;

    /**
    * Change a CI status to concluded.
    * Generates change history.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_cit          ci identifier
    * @param i_episode      episode identifier
    *
    * @author               Jorge Silva
    * @version               2.6.3
    * @since                2012/12/12
    */
    PROCEDURE conclude_cit_int
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cit         IN pat_cit.id_pat_cit%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_update_date IN BOOLEAN
    ) IS
        l_id_pat_cit_hist pat_cit_hist.id_pat_cit_hist%TYPE;
        l_rowids          table_varchar;
        l_error           t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        set_cit_hist(i_lang, i_prof, i_cit, l_id_pat_cit_hist); -- faz inserção do registo em histórico
    
        g_error := 'UPDATE PAT_CIT';
    
        IF (i_update_date)
        THEN
            ts_pat_cit.upd(id_pat_cit_in         => i_cit,
                           flg_status_in         => g_flg_status_concluded, -- fica com estado Concluido
                           dt_end_period_tstz_in => g_sysdate_tstz,
                           id_prof_writes_in     => i_prof.id,
                           dt_writes_tstz_in     => g_sysdate_tstz,
                           id_episode_in         => i_episode,
                           rows_out              => l_rowids);
        ELSE
            ts_pat_cit.upd(id_pat_cit_in     => i_cit,
                           flg_status_in     => g_flg_status_concluded, -- fica com estado Concluido
                           id_prof_writes_in => i_prof.id,
                           dt_writes_tstz_in => g_sysdate_tstz,
                           id_episode_in     => i_episode,
                           rows_out          => l_rowids);
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_CIT',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
    END conclude_cit_int;

    /********************************************************************************************
    * Função de registo que a CIT foi concluída - Seack Leave
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param IN   i_cit         CIT identifier
    *
    * @param OUT  o_error       Error structure
    *
    * @author                   Jorge Silva
    * @since                    12/12/2012
    ********************************************************************************************/
    FUNCTION conclude_cit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_cit IS NULL
        THEN
            g_error := 'i_cit cannot be NULL!';
            RAISE g_exception;
        END IF;
    
        conclude_cit_int(i_lang        => i_lang,
                         i_prof        => i_prof,
                         i_cit         => i_cit,
                         i_update_date => TRUE,
                         i_episode     => i_episode);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'PRINT_CIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END conclude_cit;
    /********************************************************************************************
    * Actualizar o estado do cit - Seack Leave
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @author                   Jorge Silva
    * @since                    14/12/2012
    ********************************************************************************************/
    PROCEDURE update_status_cit_int
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    
        g_sysdate_one_month_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_pat_cit_hist  pat_cit_hist.id_pat_cit_hist%TYPE;
        l_rowids           table_varchar;
        l_error            t_error_out;
        l_flg_status       VARCHAR2(1);
        l_table_id_pat_cit table_number_id;
        l_table_dt_begin   table_timestamp;
        l_table_dt_end     table_timestamp;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT nvl(pc.dt_certificate_renew, nvl(pc.dt_start_period_tstz, pc.dt_other_capac_start)) dt_start,
               pc.dt_end_period_tstz dt_end,
               pc.id_pat_cit id_pat_cit
          BULK COLLECT
          INTO l_table_dt_begin, l_table_dt_end, l_table_id_pat_cit
          FROM pat_cit pc
         WHERE pc.id_patient = i_patient
           AND pc.flg_status IN
               (g_flg_status_ongoing, g_flg_status_construction, g_flg_status_edited, g_flg_status_renew)
           AND pc.flg_type = g_flg_type_sick_leave;
    
        FOR indx IN 1 .. l_table_dt_begin.count
        LOOP
            l_flg_status := ' ';
        
            g_sysdate_one_month_tstz := add_months(l_table_dt_begin(indx), 1);
        
            IF (l_table_dt_end(indx) <= g_sysdate_tstz) -- Resolvido
            THEN
                l_flg_status := g_flg_status_concluded;
            ELSE
                IF (g_sysdate_one_month_tstz <= g_sysdate_tstz) -- Expirado
                THEN
                    l_flg_status := g_flg_status_expired;
                END IF;
            END IF;
        
            IF (l_flg_status <> ' ')
            THEN
                set_cit_hist(i_lang, i_prof, l_table_id_pat_cit(indx), l_id_pat_cit_hist); -- faz inserção do registo em histórico
            
                ts_pat_cit.upd(id_pat_cit_in     => l_table_id_pat_cit(indx),
                               flg_status_in     => l_flg_status,
                               dt_writes_tstz_in => g_sysdate_tstz,
                               id_episode_in     => i_episode,
                               rows_out          => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_CIT',
                                              i_rowids     => l_rowids,
                                              o_error      => l_error);
            END IF;
        END LOOP;
        IF l_rowids IS NOT NULL
           AND l_rowids.count != 0
        THEN
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'UPDATE_STATUS_CIT_INT',
                                              l_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END update_status_cit_int;

    /********************************************************************************************
    * Returns a description with all the relevant info of the sick leave certificate
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_cit         CIT ID
    * @param   i_use_html_format Use HTML tags to format output. Default: No
    *
    * @return    cits detailed description
    *
    * @author                   Sofia Mendes
    * @since                    10-Jul-2013
    ********************************************************************************************/
    FUNCTION get_cit_det_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cit             IN pat_cit.id_pat_cit%TYPE,
        i_use_html_format IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(23 CHAR) := 'GET_CIT_DET_DESCRIPTION';
        l_new_line  CONSTANT VARCHAR2(2 CHAR) := chr(10);
        l_space     CONSTANT VARCHAR2(1 CHAR) := ' ';
        l_desc              CLOB;
        l_desc_expected_dur sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PAT_CIT_T046');
        l_desc_from         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PAT_CIT_T045');
    BEGIN
        g_error := 'get_cit_det_description. i_cit: ' || i_cit;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT
        -- capacity start 0%
         pk_message.get_message(i_lang, 'PAT_CIT_T044') || l_new_line || l_desc_from || l_space ||
          pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof) || l_new_line ||
          l_desc_expected_dur || l_space ||
          decode(pc.flg_zero_capac_end,
                 g_capacity_date,
                 pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_zero_capac_end, i_prof),
                 g_capacity_indefinite,
                 pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                 g_capacity_periode,
                 pk_string_utils.concat_if_exists(pc.zero_capac_end_num,
                                                  pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                               i_prof,
                                                                                               pc.zero_capac_end_unit),
                                                  l_space)) || l_new_line ||
         -- capacity Percentage (other %)
          CASE
              WHEN pc.other_percentage_num IS NOT NULL THEN
              
               pk_message.get_message(i_lang, 'PAT_CIT_T047') || l_new_line ||
               pk_message.get_message(i_lang, 'PAT_CIT_T048') || l_space ||
               decode(pc.other_percentage_num,
                      NULL,
                      '',
                      pk_string_utils.concat_if_exists(pc.other_percentage_num, '%', ' ')) || l_new_line || -- Percentage (other %)
               l_desc_from || l_space || pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof) ||
               l_new_line || -- start date (other %)
               l_desc_expected_dur || l_space ||
               decode(pc.flg_other_capac,
                      g_capacity_date,
                      pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_end, i_prof),
                      g_capacity_indefinite,
                      pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang),
                      g_capacity_periode,
                      pk_string_utils.concat_if_exists(pc.other_capac_end_num,
                                                       pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                    i_prof,
                                                                                                    pc.other_capac_end_unit),
                                                       l_space)) || l_new_line
              ELSE
               ''
          END || -- End date (other %)
         
          pk_message.get_message(i_lang, 'PAT_CIT_T056') || l_new_line || l_desc_expected_dur || l_space ||
          nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
              pk_sysdomain.get_domain(g_cit_flg_without_period, g_capacity_indefinite, i_lang)) -- capacity start (100%)
          || l_new_line --
          || pk_message.get_message(i_lang, 'PAT_CIT_T050') || l_space ||
          pk_sysdomain.get_domain(g_cit_flg_reason, pc.flg_reason, i_lang) -- reason
         
          || l_new_line || pk_sysdomain.get_domain(pk_cit.g_cit_flg_status, pc.flg_status, i_lang) ||
          pk_date_utils.date_char_tsz(i_lang, pc.dt_writes_tstz, i_prof.institution, i_prof.software) || ', ' ||
          pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_prof_writes)
          INTO l_desc
          FROM pat_cit pc
         WHERE pc.id_pat_cit = i_cit;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_cit_det_description exception error: ' || SQLERRM;
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
    END get_cit_det_description;

    /********************************************************************************************
    * Returns a description with sick leave certificate info: cit desctiption, start and end date
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_cit         CIT ID
    *
    * @return    cits detailed description
    *
    * @author                   Sofia Mendes
    * @since                    15-Jul-2013
    ********************************************************************************************/
    FUNCTION get_cit_short_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_cit  IN pat_cit.id_pat_cit%TYPE
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(23 CHAR) := 'GET_CIT_SHORT_DESC';
        l_new_line  CONSTANT VARCHAR2(2 CHAR) := chr(10);
        l_space     CONSTANT VARCHAR2(1 CHAR) := ' ';
        l_desc          CLOB;
        l_desc_start_dt sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M006');
        l_desc_end_dt   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M007');
    BEGIN
        g_error := 'get_cit_short_desc. i_cit: ' || i_cit;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT pk_sysdomain.get_domain(pk_cit.g_cit_flg_type, pc.flg_type, i_lang) || l_new_line || l_desc_start_dt || ' ' ||
               nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_start_period_tstz, i_prof),
                   pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_other_capac_start, i_prof)) || '; ' || l_desc_end_dt || ' ' ||
               nvl(pk_date_utils.date_chr_extend_tsz(i_lang, pc.dt_end_period_tstz, i_prof),
                   pk_sysdomain.get_domain(pk_cit.g_cit_flg_without_period, pk_cit.g_capacity_indefinite, i_lang))
          INTO l_desc
          FROM pat_cit pc
         WHERE pc.id_pat_cit = i_cit;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_cit_short_desc exception error: ' || SQLERRM;
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
    END get_cit_short_desc;

    /********************************************************************************************
    * Return the detailed descriptions of all the CITS of the patient, except the cancelled ones.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * @param IN   i_excluded_status Status to be excluded
    * @param   i_use_html_format Use HTML tags to format output. Default: No
    * @param OUT  o_cit_desc      CIT list descriptions   
    * @param OUT  o_cit_title     CIT type description
    * @param OUT  o_error       Error structure
    *
    * @return    Boolean
    *
    * @author                   Sofia Mendes
    * @since                    10-Jul-2013
    ********************************************************************************************/
    FUNCTION get_cits_by_patient
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_excluded_status IN table_varchar,
        i_use_html_format IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_cit_desc        OUT table_varchar,
        o_cit_title       OUT table_varchar,
        o_signature       OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_CITS_BY_PATIENT';
    BEGIN
        g_error := 'update_status_cit_int';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        update_status_cit_int(i_lang => i_lang, i_prof => i_prof, i_patient => i_id_patient, i_episode => i_id_episode);
    
        g_error := 'get_cits_by_patient. i_id_patient: ' || i_id_patient;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT get_cit_det_description(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_cit             => t.id_pat_cit,
                                        i_use_html_format => i_use_html_format) || CASE
                    WHEN rn > 1 THEN
                     chr(10)
                    ELSE
                     ''
                END cit_desc,
               pk_sysdomain.get_domain(pk_cit.g_cit_flg_type, t.flg_type, i_lang),
               pk_prof_utils.get_detail_signature(i_lang, i_prof, t.id_episode, t.dt_writes_tstz, t.id_prof_writes) signature
          BULK COLLECT
          INTO o_cit_desc, o_cit_title, o_signature
          FROM (SELECT pc.id_pat_cit,
                       pc.flg_type,
                       pc.dt_writes_tstz,
                       pc.id_prof_writes,
                       pc.id_episode,
                       row_number() over(PARTITION BY pc.id_patient ORDER BY pc.dt_writes_tstz) rn
                  FROM pat_cit pc
                 WHERE pc.id_patient = i_id_patient
                      --AND (i_id_episode IS NULL OR pc.id_episode = i_id_episode)
                   AND (pc.flg_status NOT IN (SELECT /*+opt_estimate(table,s,scale_rows=1)*/
                                               column_value
                                                FROM TABLE(i_excluded_status) s) OR i_excluded_status IS NULL)) t
         ORDER BY t.dt_writes_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CITS_BY_PATIENT',
                                                     o_error);
    END get_cits_by_patient;

    /********************************************************************************************
    * Return a set of id previous episode.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    27-Ago-2013
    ********************************************************************************************/
    FUNCTION get_prev_pat_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number IS
    
        l_prev_episode  table_number;
        l_dt_begin_tstz episode.dt_begin_tstz%TYPE;
    
    BEGIN
        SELECT e.dt_begin_tstz
          INTO l_dt_begin_tstz
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        SELECT e.id_episode
          BULK COLLECT
          INTO l_prev_episode
          FROM episode e
         WHERE e.id_patient = i_pat
           AND pk_date_utils.compare_dates_tsz(i_prof, e.dt_begin_tstz, l_dt_begin_tstz) <> 'G';
    
        RETURN l_prev_episode;
    
    END get_prev_pat_episode;

    /********************************************************************************************
    * Return if a create button is active
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    24-10-2013
    ********************************************************************************************/
    FUNCTION get_create_permission
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market             market.id_market%TYPE;
        l_patient_cit_active table_number := table_number();
        reason_count         NUMBER;
        t_coll_cit           t_coll_cit_info;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT pc.id_pat_cit
          BULK COLLECT
          INTO l_patient_cit_active
          FROM pat_cit pc
         WHERE pc.id_patient = i_pat
           AND pc.flg_status NOT IN (g_flg_status_canceled, g_flg_status_concluded);
    
        IF (l_market <> pk_alert_constant.g_id_market_ch)
        THEN
        
            IF (l_patient_cit_active.count = 0)
            THEN
                o_create := pk_alert_constant.get_yes;
            ELSE
                o_create := pk_alert_constant.get_no;
            END IF;
        ELSE
            SELECT COUNT(*)
              INTO reason_count
              FROM TABLE(pk_cit.tf_reasons_list(i_lang, i_prof, i_pat, NULL));
        
            IF reason_count > 0
            THEN
                o_create := pk_alert_constant.get_yes;
            ELSE
                o_create := pk_alert_constant.get_no;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'get_create_permission',
                                                     o_error);
        
    END get_create_permission;

    /********************************************************************************************
    * Return a list of reason
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    24-10-2013
    ********************************************************************************************/
    FUNCTION get_reasons_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_pat_cit IN pat_cit.id_pat_cit%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_reasons FOR
            SELECT rl.*
              FROM TABLE(pk_cit.tf_reasons_list(i_lang, i_prof, i_pat, i_pat_cit)) rl;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'get_reasons_list',
                                                     o_error);
        
    END get_reasons_list;

    /********************************************************************************************
    * Return a table function list of reason
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    24-10-2013
    ********************************************************************************************/
    FUNCTION tf_reasons_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_pat_cit IN pat_cit.id_pat_cit%TYPE
    ) RETURN t_coll_cit_info
        PIPELINED IS
        t_reasons_list       t_rec_cit_info;
        l_patient_flg_reason table_varchar2 := table_varchar2();
    BEGIN
        SELECT pc.flg_reason
          BULK COLLECT
          INTO l_patient_flg_reason
          FROM pat_cit pc
         WHERE pc.id_patient = i_pat
           AND (pc.id_pat_cit <> i_pat_cit OR i_pat_cit IS NULL)
           AND pc.flg_status NOT IN (g_flg_status_canceled, g_flg_status_concluded);
    
        FOR t_reasons_list IN (SELECT desc_val, val, img_name, rank
                                 FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                                     i_prof,
                                                                                     g_cit_flg_reason,
                                                                                     NULL)) s
                                WHERE s.val NOT IN
                                      ((SELECT /* +opt_estimate(TABLE t rows = 1) */
                                        t.column_value flg_type
                                         FROM TABLE(CAST(l_patient_flg_reason AS table_varchar2)) t)))
        LOOP
            PIPE ROW(t_reasons_list);
        END LOOP;
    
        RETURN;
    END tf_reasons_list;

BEGIN
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_cit;
/