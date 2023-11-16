/*-- Last Change Revision: $Rev: 1988366 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2021-05-06 15:11:58 +0100 (qui, 06 mai 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_triage_audit IS

    /*
    Vars de config
    */
    FUNCTION get_triage_epis_count(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_edis_triage.get_triage_config_by_name(0, i_prof, NULL, NULL, 'NUM_EPIS_TRIAGE_AUDIT');
    END get_triage_epis_count;
    --
    FUNCTION get_interval_min_days(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_sysconfig.get_config('AUDIT_INTERVAL_MIN_DAYS', i_prof);
    END get_interval_min_days;
    --
    FUNCTION get_interval_max_days(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_sysconfig.get_config('AUDIT_INTERVAL_MAX_DAYS', i_prof);
    END get_interval_max_days;
    --
    FUNCTION get_min_auditors_per_audit(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_sysconfig.get_config('AUDIT_MIN_PROFS', i_prof);
    END get_min_auditors_per_audit;
    --
    FUNCTION get_max_auditors_per_audit(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_sysconfig.get_config('AUDIT_MAX_PROFS', i_prof);
    END get_max_auditors_per_audit;
    --
    FUNCTION get_mult_open_adt_allowed(i_prof IN profissional) RETURN BOOLEAN IS
        l_val sys_config.value%TYPE;
    BEGIN
        l_val := pk_sysconfig.get_config('AUDIT_MULTIPLE_OPENED_ALOWED', i_prof);
        IF l_val = 'Y'
        THEN
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END get_mult_open_adt_allowed;
    /**
        Principal
    **/
    FUNCTION is_regular_auditor
    (
        i_audit_req IN audit_req.id_audit_req%TYPE,
        i_prof      IN profissional
    ) RETURN BOOLEAN IS
        l_adt_cnt PLS_INTEGER;
    BEGIN
        --TODO: verificar melhor permissões deste auditor
        SELECT COUNT(0)
          INTO l_adt_cnt
          FROM audit_req_prof arp
         WHERE arp.id_audit_req = i_audit_req
           AND arp.id_professional = i_prof.id
           AND arp.flg_rel_type = g_adt_req_prf_rel_auditor;
    
        RETURN l_adt_cnt > 0;
    
    END is_regular_auditor;

    FUNCTION is_super_auditor
    (
        i_audit_req IN audit_req.id_audit_req%TYPE,
        i_prof      IN profissional
    ) RETURN BOOLEAN IS
        l_adt_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(0)
          INTO l_adt_cnt
          FROM audit_req ar
         WHERE ar.id_audit_req = i_audit_req
           AND ar.id_prof_req = i_prof.id;
    
        RETURN l_adt_cnt > 0 OR is_regular_auditor(i_audit_req, i_prof);
    END is_super_auditor;

    FUNCTION is_super_auditor_v
    (
        i_audit_req IN audit_req.id_audit_req%TYPE,
        i_prof      IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
        IF is_super_auditor(i_audit_req, i_prof)
        
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    END is_super_auditor_v;

    FUNCTION calc_period
    (
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN DATE IS
        --xerr     VARCHAR2(2000);
        dt_begin DATE;
        dt_end   DATE;
        dt_ini   DATE;
        dt_fin   DATE;
        mes1     NUMBER;
        mes9     NUMBER;
        meses    NUMBER;
        dias     NUMBER;
        xmax     NUMBER;
        l_period DATE;
    BEGIN
    
        dt_begin := to_date(to_char(i_dt_begin, g_date_mask), g_date_mask);
        dt_end   := to_date(to_char(i_dt_end, g_date_mask), g_date_mask);
        mes1     := to_char(dt_begin, 'YYYYMM');
        mes9     := to_char(dt_end, 'YYYYMM');
        meses    := mes9 - mes1 + 1;
        xmax     := 0;
    
        dt_ini := dt_begin;
        FOR i IN 1 .. meses
        LOOP
            IF i != meses
            THEN
                dt_fin := last_day(dt_ini);
            ELSE
                dt_fin := dt_end;
            END IF;
        
            dias := dt_fin - dt_ini + 1;
        
            IF (dias) > xmax
            THEN
                xmax     := dias;
                l_period := dt_ini;
                dt_ini   := dt_fin + 1;
            END IF;
        END LOOP;
    
        RETURN trunc(l_period, 'MM');
    
    END calc_period;

    FUNCTION get_audited_periods
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_periods OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'GET SHORTCUTS';
        IF NOT pk_access.preload_shortcuts(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_screens => table_varchar('AUDIT_GRID'),
                                           o_error   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'OPEN O_PERIODS';
        OPEN o_periods FOR
            SELECT extract(MONTH FROM ar.period) MONTH,
                   extract(YEAR FROM ar.period) YEAR,
                   to_char(ar.period, 'MM-YYYY') period_show,
                   to_char(ar.period, g_date_mask) period,
                   (SELECT '0|xxxxxxxxxxxxxx|I|X|' || sd.img_name
                      FROM sys_domain sd
                     WHERE sd.id_language = i_lang
                       AND sd.code_domain = 'AUDIT_REQ.FLG_STATUS'
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.rank = ar.rank) icon,
                   pk_access.get_shortcut('AUDIT_GRID') shortcut
              FROM (SELECT period, MIN(pk_sysdomain.get_rank(i_lang, 'AUDIT_REQ.FLG_STATUS', flg_status)) rank
                      FROM audit_req
                     WHERE i_prof.institution = id_institution
                     GROUP BY period) ar
             ORDER BY ar.rank ASC, period DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_AUDITED_PERIODS',
                                              o_error);
            pk_types.open_my_cursor(o_periods);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_audited_periods;

    FUNCTION get_all_auditors
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_auditors     OUT pk_types.cursor_type,
        o_min_profs    OUT INTEGER,
        o_max_profs    OUT INTEGER,
        o_require_self OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --TODO: ver profissionais que podem auditar !
        g_error := 'OPEN O_AUDITORS';
        OPEN o_auditors FOR
            SELECT DISTINCT p.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name
              FROM professional p, prof_profile_template ppt, prof_institution pi
             WHERE ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND p.id_professional = ppt.id_professional
               AND p.flg_state = g_prof_flg_active
               AND pi.id_professional = ppt.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = g_prof_flg_active
               AND pi.dt_end_tstz IS NULL
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes;
    
        g_error        := 'GET VARS';
        o_min_profs    := get_min_auditors_per_audit(i_prof);
        o_max_profs    := get_max_auditors_per_audit(i_prof);
        o_require_self := g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ALL_AUDITORS',
                                              o_error);
            pk_types.open_my_cursor(o_auditors);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_all_auditors;

    FUNCTION check_audits_gap
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_period         IN DATE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        xerr     VARCHAR2(2000);
        mes1     NUMBER;
        mes9     NUMBER;
        meses    NUMBER;
        j        NUMBER;
        xcount   NUMBER;
        l_period DATE := trunc(i_period, 'MM');
    
        CURSOR cnt_c IS
            SELECT DISTINCT ar.period
              FROM audit_req ar
             WHERE ar.id_institution = i_id_institution
               AND ar.period < l_period
               AND ar.flg_status != g_adt_req_canc
             ORDER BY ar.period DESC;
    
    BEGIN
        g_error := 'ENTER';
        xcount  := 0;
    
        g_error := 'OPEN CNT_C';
        FOR cnt IN cnt_c
        LOOP
            xcount := xcount + 1;
            IF xcount = 1
            THEN
            
                mes1 := to_number(to_char(cnt.period, 'YYYYMM'));
                mes9 := to_number(to_char(l_period, 'YYYYMM'));
                j    := 0;
                LOOP
                    j    := j + 1;
                    xerr := to_char(add_months(cnt.period, j), 'MM-YYYY');
                    EXIT WHEN xerr = to_char(l_period, 'MM-YYYY');
                END LOOP;
                --meses := mes9 - mes1 - 1;
                meses := j - 1;
                IF meses = 0
                THEN
                    o_flg_show := 'N';
                ELSE
                    o_msg      := '';
                    o_flg_show := 'Y';
                    FOR i IN 1 .. meses
                    LOOP
                        o_msg := o_msg || chr(10) || to_char(add_months(cnt.period, i), 'MM-YYYY');
                    END LOOP;
                END IF;
            ELSE
                EXIT;
            END IF;
        
        END LOOP;
    
        IF o_flg_show = 'Y'
        THEN
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T031');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR005') || chr(10) || o_msg;
            o_button    := 'NC';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_AUDITS_GAP',
                                              o_error);
            RETURN FALSE;
    END check_audits_gap;

    FUNCTION check_interval
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_audit_type  IN audit_type.id_audit_type%TYPE,
        i_tb_auditors IN table_number,
        o_period      OUT DATE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_result    OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count_prev_triages PLS_INTEGER;
        l_count_periods      PLS_INTEGER;
        l_count_adt_reqs     PLS_INTEGER;
        l_num_days           PLS_INTEGER;
        l_max_days           PLS_INTEGER;
        l_num_triage_profs   PLS_INTEGER;
        l_triage_epis_cnt    PLS_INTEGER;
    
        l_many_allowed BOOLEAN;
    
        l_goto_end EXCEPTION;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_error        := 'CHECK DATES';
        o_msg          := NULL;
        --parametros especificados
        IF i_dt_begin IS NULL
           OR i_dt_end IS NULL
        THEN
            o_msg := 'AUDIT_ERR002';
            RAISE l_goto_end;
        END IF;
    
        --datas na ordem correcta
        IF i_dt_begin > i_dt_end
        THEN
            o_msg := 'AUDIT_ERR001';
            RAISE l_goto_end;
        END IF;
    
        --data de fim superior à actual
        IF i_dt_end > pk_date_utils.trunc_insttimezone(i_prof, pk_date_utils.add_days_to_tstz(g_sysdate_tstz, 1), 'DD')
        THEN
            o_msg := 'AUDIT_ERR004';
            RAISE l_goto_end;
        END IF;
        --intervalo de tempo pequeno ou grande
        l_num_days := pk_date_utils.diff_timestamp(i_dt_end, i_dt_begin);
        l_max_days := get_interval_max_days(i_prof);
        IF l_num_days < get_interval_min_days(i_prof)
        THEN
            o_msg := 'AUDIT_ERR011';
            RAISE l_goto_end;
        ELSIF l_max_days IS NOT NULL
              AND l_num_days > l_max_days
        THEN
            o_msg := 'AUDIT_ERR012';
            RAISE l_goto_end;
        END IF;
    
        /*
          verificar se há triagens anteriores cujas datas coincidem
        */
        g_error := 'COUNT PREV TRIAGES';
        SELECT COUNT(*)
          INTO l_count_prev_triages
          FROM audit_req ar
         WHERE (ar.dt_begin_tstz BETWEEN i_dt_begin AND i_dt_end OR ar.dt_end_tstz BETWEEN i_dt_begin AND i_dt_end)
           AND ar.flg_status != g_adt_req_canc
           AND ar.id_institution = i_prof.institution;
    
        IF l_count_prev_triages > 0
        THEN
            o_msg := 'AUDIT_ERR003';
            RAISE l_goto_end;
        END IF;
    
        l_triage_epis_cnt := get_triage_epis_count(i_prof);
    
        --verificar se há episódios para auditar nesse período
        g_error := 'COUNT AVAIL EPIS';
        SELECT COUNT(0)
          INTO l_num_triage_profs
          FROM (SELECT epis.id_prof_triage
                  FROM v_epis_one_triage_no_audit epis, visit vis
                 WHERE epis.dt_end_triage_tstz BETWEEN i_dt_begin AND i_dt_end
                   AND epis.id_triage_type IN (SELECT at.id_triage_type
                                                 FROM audit_type_triage_type at
                                                WHERE at.id_audit_type = i_audit_type)
                   AND vis.id_visit = epis.id_visit
                   AND pk_prof_utils.is_internal_prof(i_lang, i_prof, epis.id_prof_triage, i_prof.institution) =
                       pk_alert_constant.g_yes
                   AND nvl(epis.id_institution_origin, vis.id_institution) = i_prof.institution
                   AND epis.id_prof_triage NOT IN (SELECT *
                                                     FROM TABLE(i_tb_auditors))
                 GROUP BY epis.id_prof_triage
                HAVING COUNT(epis.id_episode) >= l_triage_epis_cnt);
    
        IF l_num_triage_profs = 0
        THEN
            --caso um dos auditores tenha realizado auditorias e seja o único profissional com auditorias suficientes, da-se o aviso
            g_error := 'COUNT AVAIL EPIS ADTR';
            SELECT COUNT(0)
              INTO l_num_triage_profs
              FROM (SELECT epis.id_prof_triage
                      FROM v_epis_one_triage_no_audit epis, visit vis
                     WHERE epis.dt_end_triage_tstz BETWEEN i_dt_begin AND i_dt_end
                       AND epis.id_triage_type IN (SELECT at.id_triage_type
                                                     FROM audit_type_triage_type at
                                                    WHERE at.id_audit_type = i_audit_type)
                       AND vis.id_visit = epis.id_visit
                       AND nvl(epis.id_institution_origin, vis.id_institution) = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, epis.id_prof_triage, i_prof.institution) =
                           pk_alert_constant.g_yes
                       AND epis.id_prof_triage IN (SELECT *
                                                     FROM TABLE(i_tb_auditors))
                     GROUP BY epis.id_prof_triage
                    HAVING COUNT(epis.id_episode) >= l_triage_epis_cnt);
        
            IF l_num_triage_profs = 0
            THEN
                o_msg := 'AUDIT_ERR006';
            ELSE
                o_msg := 'AUDIT_ERR019';
            END IF;
            RAISE l_goto_end;
        
        END IF;
    
        --ir ler período (mês e ano)
        g_error  := 'CALL GET_PERIOD';
        o_period := calc_period(i_dt_begin, i_dt_end);
    
        --mesmo que as próximas verificações falhem, a auditoria pode ser requerida
    
        -- Verificar se há actualmente uma auditoria aberta.
        -- Caso seja possível requisitar, o aviso de que há uma aberta
        -- é devolvido na check_can_create_audit_req
        l_many_allowed := get_mult_open_adt_allowed(i_prof);
    
        SELECT COUNT(0)
          INTO l_count_adt_reqs
          FROM audit_req
         WHERE flg_status = g_adt_req_open
           AND id_institution = i_prof.institution;
    
        IF l_count_adt_reqs > 0
           AND NOT l_many_allowed
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR032');
            o_result    := g_no;
            o_button    := 'R';
        
            RETURN TRUE;
        END IF;
    
        --saber se há auditorias por realizar
        g_error := 'CALL CHECK_AUDITS_GAP';
        IF NOT check_audits_gap(i_lang, i_prof.institution, o_period, o_flg_show, o_msg_title, o_msg, o_button, o_error)
        THEN
            o_result := g_no;
            RETURN FALSE;
        END IF;
    
        IF o_flg_show <> g_yes
        THEN
            g_error := 'GET AUDITS BY PERIOD';
            SELECT COUNT(*)
              INTO l_count_periods
              FROM audit_req ar
             WHERE ar.period = o_period
               AND ar.id_institution = i_prof.institution
               AND ar.flg_status != g_adt_req_canc;
            IF l_count_periods > 0
            THEN
                o_flg_show  := g_yes;
                o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T037');
                o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR009');
                o_result    := g_yes;
                o_button    := 'NC';
            END IF;
        
        END IF;
    
        o_result := g_yes;
        g_error  := 'CHECK_INTERVAL OK';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_goto_end THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, o_msg);
            o_result    := g_no;
            o_button    := 'R';
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_INTERVAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_interval;

    FUNCTION check_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        i_auditors IN table_number,
        
        o_period OUT VARCHAR2,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_audit_type audit_type.id_audit_type%TYPE;
        l_period     DATE;
        l_ret        BOOLEAN;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_triage_type    triage_type.id_triage_type%TYPE;
        l_triage_acronym triage_type.acronym%TYPE;
        l_triage_error EXCEPTION;
    BEGIN
        g_error := 'GET TRIAGE_TYPE';
        IF NOT pk_edis_triage.get_default_triage_type(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      o_triage_type    => l_triage_type,
                                                      o_triage_acronym => l_triage_acronym,
                                                      o_error          => o_error)
        THEN
            RAISE l_triage_error;
        END IF;
    
        --l_audit_type := i_audit_type;
        --Por enquanto só há uma auditoria, que é a de Manchester,
        --associada a uma triagem
        BEGIN
            g_error := 'GET AUDIT_TYPE';
            SELECT id_audit_type
              INTO l_audit_type
              FROM audit_type_triage_type attt, triage_type tt
             WHERE tt.id_triage_type = l_triage_type
               AND attt.id_triage_type = tt.id_triage_type;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_show  := g_yes;
                o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
                o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR010');
                o_result    := g_no;
                o_button    := 'R';
                RETURN TRUE;
        END;
        g_error := 'CALL CHECK_INTERVAL 2';
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL),
                                                       'DD');
                      
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof,
                                                     pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL) ,
                                                     'DD') +
                                                     ( INTERVAL '1' DAY - INTERVAL '1' SECOND) ;
                      
    
        l_ret := check_interval(i_lang,
                                i_prof,
                                l_dt_begin,
                                l_dt_end,
                                l_audit_type,
                                i_auditors,
                                l_period,
                                o_flg_show,
                                o_msg_title,
                                o_msg,
                                o_button,
                                o_result,
                                o_error);
    
        o_period := to_char(l_period, g_date_mask);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_INTERVAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_interval;

    FUNCTION check_can_create_audit_req
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_count        PLS_INTEGER;
        l_many_allowed BOOLEAN;
    BEGIN
    
        l_many_allowed := get_mult_open_adt_allowed(i_prof);
    
        g_error := 'COUNT AUDITS';
        SELECT COUNT(0)
          INTO l_count
          FROM audit_req
         WHERE flg_status = g_adt_req_open
           AND id_institution = i_prof.institution;
    
        IF l_count = 0
        THEN
            o_result   := g_yes;
            o_flg_show := g_no;
        ELSIF l_many_allowed
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_GRID_T046');
            o_result    := g_yes;
            o_button    := 'NC';
        ELSE
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR032');
            o_result    := g_no;
            o_button    := 'R';
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_CAN_CREATE_AUDIT_REQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_can_create_audit_req;

    FUNCTION get_all_audit_reqs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_period IN VARCHAR2,
        
        o_all_audits OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_period     DATE;
        l_cancel_msg sys_message.desc_message%TYPE;
        l_internal_error EXCEPTION;
    BEGIN
        g_error  := 'TRUNC I_PERIOD';
        l_period := trunc(to_date(i_period, g_date_mask), 'MM');
    
        g_error := 'GET SHORTCUTS';
        IF NOT pk_access.preload_shortcuts(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_screens => table_varchar('AUDITED_PROF'),
                                           o_error   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        l_cancel_msg := ' (' || lower(pk_message.get_message(i_lang, 'COMMON_M008')) || ')';
    
        g_error := 'OPEN O_ALL_AUDITS';
        OPEN o_all_audits FOR
            SELECT ar.id_audit_req,
                   nvl(pk_translation.get_translation(i_lang, 'AUDIT_TYPE.CODE_ABBREVIATION.' || ar.id_audit_type),
                       pk_translation.get_translation(i_lang, 'AUDIT_TYPE.CODE_AUDIT_TYPE.' || ar.id_audit_type)) desc_audit_type,
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                      decode(ar.flg_status,
                                                             g_adt_req_req,
                                                             ar.dt_req_tstz,
                                                             g_adt_req_open,
                                                             ar.dt_open_tstz,
                                                             g_adt_req_close,
                                                             ar.dt_close_tstz,
                                                             g_adt_req_intr,
                                                             nvl(ar.dt_open_tstz, ar.dt_req_tstz),
                                                             g_adt_req_canc,
                                                             ar.dt_cancel_tstz),
                                                      g_date_mask) dt_status,
                   pk_date_utils.to_char_insttimezone(i_prof, ar.dt_req_tstz, g_date_mask) dt_req,
                   pk_date_utils.to_char_insttimezone(i_prof, ar.dt_begin_tstz, g_date_mask) dt_begin,
                   pk_date_utils.to_char_insttimezone(i_prof, ar.dt_end_tstz, g_date_mask) dt_end,
                   ar.flg_status,
                   pk_sysdomain.get_domain('AUDIT_REQ.FLG_STATUS', ar.flg_status, i_lang) ||
                   decode(ar.flg_status, g_adt_req_canc, nvl2(ar.notes_cancel, l_cancel_msg, '')) desc_status,
                   to_char(ar.period, 'Mon-YYYY') period,
                   (SELECT pk_utils.concat_table(CAST(COLLECT(pk_prof_utils.get_name_signature(i_lang,
                                                                                               i_prof,
                                                                                               p.id_professional)) AS
                                                      table_varchar),
                                                 '|') profs_names
                      FROM audit_req_prof arp, professional p
                     WHERE arp.id_audit_req = ar.id_audit_req
                       AND arp.flg_rel_type = g_adt_req_prf_rel_auditor
                       AND arp.id_professional = p.id_professional) profs_names,
                   pk_sysdomain.get_rank(i_lang, 'AUDIT_REQ.FLG_STATUS', ar.flg_status) rank,
                   decode(ar.flg_status,
                          g_adt_req_req,
                          g_yes, --is_regular_auditor_v(ar.id_audit_req,i_prof),
                          g_adt_req_open,
                          g_yes,
                          g_adt_req_close,
                          g_no,
                          g_adt_req_intr,
                          g_no, --is_super_auditor_v(ar.id_audit_req,i_prof),
                          g_adt_req_canc,
                          g_no) avail_butt_ok,
                   decode((SELECT SUM( --epis quest
                                     (SELECT COUNT(ar.id_audit_req_comment)
                                         FROM audit_req_comment ar, audit_quest_answer aq
                                        WHERE ar.id_audit_quest_answer = aq.id_audit_quest_answer
                                          AND aq.id_audit_req_prof_epis = ae.id_audit_req_prof_epis) +
                                     --epis comment
                                      (SELECT COUNT(id_audit_req_comment)
                                         FROM audit_req_comment ar
                                        WHERE id_audit_req_prof_epis = ae.id_audit_req_prof_epis) +
                                     --prof quest
                                      (SELECT COUNT(id_audit_req_comment)
                                         FROM audit_req_comment ar, audit_quest_answer aq
                                        WHERE ar.id_audit_quest_answer = aq.id_audit_quest_answer
                                          AND aq.id_audit_req_prof = ap.id_audit_req_prof) +
                                     --prof comment 
                                      (SELECT COUNT(id_audit_req_comment)
                                         FROM audit_req_comment
                                        WHERE id_audit_req_prof = ap.id_audit_req_prof))
                            FROM audit_req_prof ap, audit_req_prof_epis ae
                           WHERE ap.id_audit_req = ar.id_audit_req
                             AND ae.id_audit_req_prof = ap.id_audit_req_prof),
                          0,
                          g_yes,
                          g_no) can_cancel,
                   decode(ar.flg_status, g_adt_req_close, g_no, g_adt_req_canc, g_no, g_yes) avail_butt_cancel,
                   pk_access.get_shortcut('AUDITED_PROF') shortcut,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_prof_cancel) prof_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, ar.dt_cancel_tstz, g_date_mask) dt_cancel,
                   ar.notes_cancel
              FROM audit_req ar
             WHERE i_prof.institution = ar.id_institution
               AND (l_period IS NULL OR l_period = trunc(ar.period, 'MM'))
             ORDER BY rank ASC, ar.period DESC, ar.dt_begin_tstz, ar.dt_end_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_ALL_AUDIT_REQS',
                                              o_error);
            pk_types.open_my_cursor(o_all_audits);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_all_audit_reqs;

    FUNCTION create_audit_req
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_auditors  IN table_number,
        o_audit_req OUT audit_req.id_audit_req%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_audit_type   audit_type.id_audit_type%TYPE;
        l_id_audit_req audit_req.id_audit_req%TYPE;
    
        l_dummy              VARCHAR2(4000);
        l_msg_text           sys_message.desc_message%TYPE;
        l_period             DATE;
        l_dt_begin           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end             TIMESTAMP WITH LOCAL TIME ZONE;
        l_max_auditors       PLS_INTEGER;
        l_triage_profs       table_number;
        l_id_audit_req_profs table_number;
        l_prof_epis_cnt      PLS_INTEGER;
    
        l_can_request  BOOLEAN;
        l_chk_interval VARCHAR2(1);
    
        l_error_message sys_message.desc_message%TYPE;
        l_common_error   EXCEPTION;
        l_internal_error EXCEPTION;
    
        l_triage_type    triage_type.id_triage_type%TYPE;
        l_triage_acronym triage_type.acronym%TYPE;
        l_triage_error EXCEPTION;
    
        l_vs_pain       vital_sign.id_vital_sign%TYPE;
        l_id_content_vs vital_sign.id_content%TYPE := 'TMP33.108';
    BEGIN
        g_error := 'GET TRIAGE_TYPE';
        IF NOT pk_edis_triage.get_default_triage_type(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      o_triage_type    => l_triage_type,
                                                      o_triage_acronym => l_triage_acronym,
                                                      o_error          => o_error)
        THEN
            RAISE l_triage_error;
        END IF;
    
        g_error := 'CONVERT DATES';
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL),
                                                       'DD');
        --this line transforms our date from 
        l_dt_end := pk_date_utils.trunc_insttimezone(i_prof,
                                                     pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL) ,
                                                     'DD') +
                                                     ( INTERVAL '1' DAY - INTERVAL '1' SECOND) ;
    
        g_error        := 'CHECKING DATES';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --TODO: verifica se o utilizador tem permissões para requisitar uma auditoria
        l_can_request := TRUE;
    
        IF NOT l_can_request
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR017');
            RAISE l_common_error;
        END IF;
    
        l_max_auditors := get_max_auditors_per_audit(i_prof);
        IF i_auditors.count < get_min_auditors_per_audit(i_prof)
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR008');
            RAISE l_common_error;
        ELSIF l_max_auditors IS NOT NULL
              AND i_auditors.count > l_max_auditors
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR007');
            RAISE l_common_error;
        END IF;
    
        --l_audit_type := i_audit_type;
        --Por enquanto só há uma auditoria, que é a de Manchester,
        --associada a uma triagem
        BEGIN
            g_error := 'GET AUDIT_TYPE';
            SELECT id_audit_type
              INTO l_audit_type
              FROM audit_type_triage_type attt, triage_type tt
             WHERE tt.id_triage_type = l_triage_type
               AND attt.id_triage_type = tt.id_triage_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR010');
                RAISE l_common_error;
        END;
    
        g_error := 'CALL CHECK_INTERVAL';
        IF NOT check_interval(i_lang,
                              i_prof,
                              l_dt_begin,
                              l_dt_end,
                              l_audit_type,
                              i_auditors,
                              l_period,
                              l_dummy, --o_flg_show,
                              l_dummy, --o_msg_title,
                              l_msg_text, --o_msg,
                              l_dummy, --o_button,
                              l_chk_interval,
                              o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_chk_interval = g_no
        THEN
            l_error_message := l_msg_text;
            RAISE l_common_error;
        END IF;
    
        --criar audit_req
        g_error := 'INSERT AUDIT_REQ';
        INSERT INTO audit_req
            (id_audit_req,
             id_audit_type,
             dt_req_tstz,
             dt_open_tstz,
             flg_status,
             id_prof_req,
             id_institution,
             dt_begin_tstz,
             dt_end_tstz,
             period)
        VALUES
            (seq_audit_req.nextval,
             l_audit_type,
             g_sysdate_tstz,
             g_sysdate_tstz,
             g_adt_req_open,
             i_prof.id,
             i_prof.institution,
             l_dt_begin,
             l_dt_end,
             l_period)
        RETURNING id_audit_req INTO l_id_audit_req;
    
        l_prof_epis_cnt := get_triage_epis_count(i_prof);
    
        g_error := 'INSERT AUDITORS';
        --inserir auditores
        FORALL idx IN 1 .. i_auditors.count
            INSERT INTO audit_req_prof
                (id_audit_req_prof, id_audit_req, id_professional, flg_rel_type, num_adt_epis)
            VALUES
                (seq_audit_req_prof.nextval,
                 l_id_audit_req,
                 i_auditors(idx),
                 g_adt_req_prf_rel_auditor,
                 l_prof_epis_cnt);
    
        -- ler profissionais a ser auditados
        -- e inserir registo de prof auditado
        g_error := 'INSERT AUDITED';
        INSERT INTO audit_req_prof
            (id_audit_req_prof, id_audit_req, id_professional, flg_rel_type, num_adt_epis)
            SELECT seq_audit_req_prof.nextval id_audit_req_prof,
                   l_id_audit_req             id_audit_req,
                   t.id_prof_triage           id_professional,
                   g_adt_req_prf_rel_audited  flg_rel_type,
                   l_prof_epis_cnt            num_adt_epis
              FROM (SELECT epis.id_prof_triage
                      FROM v_epis_one_triage_no_audit epis, visit vis
                     WHERE epis.dt_end_triage_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND epis.id_triage_type IN (SELECT at.id_triage_type
                                                     FROM audit_type_triage_type at
                                                    WHERE at.id_audit_type = l_audit_type)
                       AND vis.id_visit = epis.id_visit
                       AND nvl(epis.id_institution_origin, vis.id_institution) = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, epis.id_prof_triage, i_prof.institution) =
                           pk_alert_constant.g_yes
                       AND epis.id_prof_triage NOT IN (SELECT *
                                                         FROM TABLE(i_auditors))
                     GROUP BY epis.id_prof_triage
                    HAVING COUNT(epis.id_episode) >= l_prof_epis_cnt) t;
        -- :( RETURNING id_professional, id_audit_req_prof BULK COLLECT INTO l_triage_profs, l_id_audit_req_profs;
    
        g_error := 'GET TRIAGE_PROFS';
        SELECT id_professional, id_audit_req_prof
          BULK COLLECT
          INTO l_triage_profs, l_id_audit_req_profs
          FROM audit_req_prof
         WHERE id_audit_req = l_id_audit_req
           AND flg_rel_type = g_adt_req_prf_rel_audited;
    
        --por cada prof a ser auditado...
        --inserir registo de 5 episódios aleatórios para serem auditados
        g_error := 'INSERT EPIS';
        FORALL idx IN 1 .. l_triage_profs.count
            INSERT INTO audit_req_prof_epis
                (id_audit_req_prof_epis, id_epis_triage, id_audit_req_prof)
                SELECT seq_audit_req_prof_epis.nextval id_audit_req_prof_epis,
                       id_epis_triage,
                       l_id_audit_req_profs(idx) id_audit_req_prof
                  FROM (SELECT epis.id_epis_triage
                          FROM v_epis_one_triage_no_audit epis, visit vis
                         WHERE epis.dt_end_triage_tstz BETWEEN l_dt_begin AND l_dt_end
                           AND epis.id_triage_type IN (SELECT at.id_triage_type
                                                         FROM audit_type_triage_type at
                                                        WHERE at.id_audit_type = l_audit_type)
                           AND epis.id_prof_triage = l_triage_profs(idx)
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, epis.id_prof_triage, i_prof.institution) =
                               pk_alert_constant.g_yes
                           AND vis.id_visit = epis.id_visit
                           AND nvl(epis.id_institution_origin, vis.id_institution) = i_prof.institution
                         ORDER BY dbms_random.value)
                 WHERE rownum <= l_prof_epis_cnt;
    
        BEGIN
            SELECT vs.id_vital_sign
              INTO l_vs_pain
              FROM vital_sign vs
             WHERE vs.id_content = l_id_content_vs;
        EXCEPTION
            WHEN no_data_found THEN
                l_vs_pain := NULL;
        END;
    
        g_error := 'CALC DEFAULT ANSWERS';
        --calcular respostas automaticas para os episódios
        INSERT INTO audit_quest_answer
            (id_audit_quest_answer,
             id_audit_criteria,
             id_professional,
             id_audit_req,
             id_audit_req_prof,
             id_audit_req_prof_epis,
             answer,
             dt_answer_tstz)
            SELECT seq_audit_quest_answer.nextval id_audit_quest_answer,
                   id_audit_criteria,
                   id_professional,
                   id_audit_req,
                   id_audit_req_prof,
                   id_audit_req_prof_epis,
                   answer,
                   dt_answer_tstz
              FROM (SELECT DISTINCT ac.id_audit_criteria,
                                    NULL id_professional,
                                    NULL id_audit_req,
                                    NULL id_audit_req_prof,
                                    arpe.id_audit_req_prof_epis id_audit_req_prof_epis,
                                    decode(ac.flg_ans_criteria,
                                           g_adt_qt_crit_doc_read,
                                           g_yes,
                                           g_adt_qt_crit_pain,
                                           (SELECT decode(COUNT(0), 0, g_no, g_yes)
                                              FROM vital_sign_read vsr
                                             WHERE vsr.id_epis_triage = etr.id_epis_triage
                                               AND vsr.id_vital_sign = l_vs_pain),
                                           g_adt_qt_crit_repain,
                                           (SELECT decode(COUNT(0), 0, g_no, g_yes)
                                              FROM vital_sign_read vsr
                                             WHERE vsr.id_episode = etr.id_episode
                                               AND vsr.id_vital_sign = l_vs_pain
                                               AND vsr.id_epis_triage != etr.id_epis_triage),
                                           g_adt_qt_crit_rtr,
                                           (SELECT decode(COUNT(0), 1, g_no, g_yes)
                                              FROM epis_triage etr2
                                             WHERE etr2.id_episode = etr.id_episode)) answer,
                                    g_sysdate_tstz dt_answer_tstz
                      FROM audit_req_prof_epis arpe, audit_req_prof arp, epis_triage etr, audit_criteria ac
                     WHERE arp.id_audit_req = l_id_audit_req
                       AND arpe.id_audit_req_prof = arp.id_audit_req_prof
                       AND etr.id_epis_triage = arpe.id_epis_triage
                       AND ac.flg_for = g_adt_quest_for_epis
                       AND ac.flg_ans_criteria IN
                           (g_adt_qt_crit_pain, g_adt_qt_crit_repain, g_adt_qt_crit_doc_read, g_adt_qt_crit_rtr)
                       AND ac.id_audit_type = l_audit_type);
    
        o_audit_req := l_id_audit_req;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_common_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'CREATE_AUDIT_REQ',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes; -- ROLLBACK
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CREATE_AUDIT_REQ',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_audit_req;

    /**
    * Indica se as perguntas de um profissional foram todas respondidas e se pode proceder à retrospectiva
    * Não valida permissões do utilizador !
    * Apenas valida pela quantidade de dados preenchidos 
    */
    FUNCTION check_can_do_prof_retrosp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_unanswered_cnt PLS_INTEGER;
        l_audit_req      audit_req.id_audit_req%TYPE;
    
        l_can_open_close BOOLEAN; --auditor normal
    BEGIN
        g_error := 'GET AUDIT ID';
        SELECT id_audit_req
          INTO l_audit_req
          FROM audit_req_prof
         WHERE id_audit_req_prof = i_audit_req_prof;
    
        g_error := 'VALIDATE PERMISSIONS';
        --validar permissões deste utilizador para alterar o estado desta auditoria
        l_can_open_close := is_regular_auditor(l_audit_req, i_prof);
    
        IF NOT l_can_open_close
        THEN
            o_result    := g_no;
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR018');
            o_button    := 'R';
        END IF;
    
        g_error := 'COUNT UNANSWERED EPIS';
    
        SELECT COUNT(0)
          INTO l_unanswered_cnt
          FROM --sim, a multiplicação (audit_criteria x audit_req_prof_epis) é pretendida
               (SELECT arpe.id_audit_req_prof_epis, aq.id_audit_criteria
                  FROM audit_criteria      aq,
                       audit_req           ar,
                       audit_req_prof_epis arpe,
                       audit_req_prof      arp,
                       audit_req_prof      arp0
                 WHERE ar.id_audit_req = arp0.id_audit_req
                   AND arp0.id_audit_req_prof = i_audit_req_prof
                   AND aq.id_audit_type = ar.id_audit_type
                   AND aq.flg_for = g_adt_quest_for_epis
                   AND aq.flg_required = g_yes
                   AND aq.flg_ans_type <> g_adt_quest_tp_qnt
                   AND aq.flg_ans_criteria NOT IN ('L', 'T', 'O', 'R')
                      
                   AND arp.id_audit_req_prof = arpe.id_audit_req_prof
                   AND arp.id_audit_req_prof = i_audit_req_prof
                   AND arp.flg_rel_type = g_adt_req_prf_rel_audited) uans
         WHERE NOT EXISTS (SELECT 0
                  FROM audit_quest_answer a
                 WHERE a.id_audit_req_prof_epis = uans.id_audit_req_prof_epis
                   AND a.id_audit_criteria = uans.id_audit_criteria
                   AND a.answer IS NOT NULL);
    
        g_error := 'PARSE ANS';
        IF l_unanswered_cnt = 0
        --tudo ok!
        THEN
            o_flg_show := g_no;
            o_result   := g_yes;
        ELSE
            o_result    := g_no;
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T039');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR026');
            o_button    := 'R';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_CAN_DO_PROF_RETROSP',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_can_do_prof_retrosp;

    /**
    * Indica se uma auditoria pode ser fechada.
    * Não valida permissões do utilizador !
    * Apenas valida pela quantidade de dados preenchidos 
    */
    FUNCTION check_can_close_audit_req
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_audit_req IN audit_req.id_audit_req%TYPE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cur_status          audit_req.flg_status%TYPE;
        l_unanswered_epis_cnt PLS_INTEGER;
        l_unanswered_prof_cnt PLS_INTEGER;
        prof_names            VARCHAR2(32767);
        -- l_unanswered_audt_cnt NUMBER;
    
        l_can_open_close BOOLEAN; --auditor normal
    BEGIN
        g_error := 'VALIDATE PERMISSIONS';
        --validar permissões deste utilizador para alterar o estado desta auditoria
        l_can_open_close := is_regular_auditor(i_audit_req, i_prof);
    
        IF NOT l_can_open_close
        THEN
            o_result    := g_no;
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR024');
            o_button    := 'R';
            RETURN TRUE;
        END IF;
    
        SELECT flg_status
          INTO l_cur_status
          FROM audit_req
         WHERE id_audit_req = i_audit_req;
    
        IF l_cur_status = g_adt_req_close
        THEN
            o_result    := g_no;
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR022');
            o_button    := 'R';
            RETURN TRUE;
        ELSIF l_cur_status = g_adt_req_canc
        THEN
            o_result    := g_no;
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR034');
            o_button    := 'R';
            RETURN TRUE;
        ELSIF l_cur_status != g_adt_req_open
        THEN
            o_result    := g_no;
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T038');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR031');
            o_button    := 'R';
            RETURN TRUE;
        END IF;
    
        g_error := 'COUNT UNANSWERED EPIS';
        SELECT COUNT(0)
          INTO l_unanswered_epis_cnt
          FROM (SELECT arpe.id_audit_req_prof_epis, aq.id_audit_criteria
                  FROM audit_criteria aq, audit_req ar, audit_req_prof_epis arpe, audit_req_prof arp
                 WHERE ar.id_audit_req = i_audit_req
                   AND aq.id_audit_type = ar.id_audit_type
                   AND aq.flg_for = 'E'
                   AND aq.flg_required = g_yes
                   AND aq.flg_ans_type <> 'Q'
                   AND aq.flg_ans_criteria NOT IN ('L', 'T', 'O', 'R')
                      
                   AND arp.id_audit_req_prof = arpe.id_audit_req_prof
                   AND arp.id_audit_req = i_audit_req) uans
         WHERE NOT EXISTS (SELECT 0
                  FROM audit_quest_answer a
                 WHERE a.id_audit_req_prof_epis = uans.id_audit_req_prof_epis
                   AND a.id_audit_criteria = uans.id_audit_criteria
                   AND a.answer IS NOT NULL);
    
        IF l_unanswered_epis_cnt <> 0
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T039');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR027');
            o_button    := 'R';
            o_result    := g_no;
            RETURN TRUE;
        END IF;
    
        g_error := 'COUNT UNANSWERED PROF';
        SELECT COUNT(0),
               pk_utils.concat_table(CAST(COLLECT(pk_prof_utils.get_name_signature(i_lang, i_prof, uans.id_professional)) AS
                                          table_varchar),
                                     chr(10))
          INTO l_unanswered_prof_cnt, prof_names
          FROM (SELECT arp.id_audit_req_prof, arp.id_professional, aq.id_audit_criteria
                  FROM audit_criteria aq, audit_req ar, audit_req_prof arp
                 WHERE ar.id_audit_req = i_audit_req
                   AND aq.id_audit_type = ar.id_audit_type
                   AND aq.flg_for = 'P'
                   AND aq.flg_required = 'Y'
                   AND aq.flg_ans_type <> 'Q'
                      
                   AND arp.id_audit_req = i_audit_req
                      -- AND arp.id_professional = i_professional
                   AND arp.flg_rel_type = 'D'
                 ORDER BY arp.id_audit_req_prof, aq.id_audit_criteria) uans
         WHERE NOT EXISTS (SELECT 0
                  FROM audit_quest_answer a
                 WHERE a.id_audit_req_prof = uans.id_audit_req_prof
                   AND a.id_audit_criteria = uans.id_audit_criteria
                   AND a.answer IS NOT NULL);
    
        IF l_unanswered_prof_cnt <> 0
        THEN
            o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T039');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_ERR028') || chr(10) || prof_names;
            o_button    := 'R';
            o_result    := g_no;
            RETURN TRUE;
        END IF;
    
        /*
        g_error := 'COUNT UNANSWERED AUDIT';
        --não usado por enquanto
        --perguntas gerais a uma auditoria
        SELECT COUNT(0)
          INTO l_unanswered_audt_cnt
          FROM (SELECT ar.id_audit_req,
                       aq.id_audit_criteria
                  FROM audit_criteria aq,
                       audit_req      ar
                 WHERE ar.id_audit_req = i_audit_req
                   AND aq.id_audit_type = ar.id_audit_type
                   AND aq.flg_for = 'A'
                   AND aq.flg_required = 'Y'
                 ORDER BY ar.id_audit_req,
                          aq.id_audit_criteria
                
                ) uans
         WHERE NOT EXISTS (SELECT 0
                             FROM audit_quest_answer a
                            WHERE a.id_audit_req = uans.id_audit_req
                              AND a.id_audit_criteria = uans.id_audit_criteria
                              AND a.answer IS NOT NULL);
        
        IF l_unanswered_audt_cnt <> 0
        THEN o_flg_show  := g_yes;
            o_msg_title := pk_message.get_message(i_lang,
                                                  'AUDIT_GRID_T039');
            o_msg  := pk_message.get_message(i_lang,
                                                  'AUDIT_ERR029');
            o_button    := 'R';
            o_result    := g_no;
            RETURN TRUE;
        END IF;
        */
    
        o_flg_show := g_no;
        o_result   := g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'CHECK_CAN_CLOSE_AUDIT_REQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_can_close_audit_req;

    FUNCTION get_open_audit_title
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_audit_req IN audit_req.id_audit_req%TYPE,
        
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status audit_req.flg_status%TYPE;
    BEGIN
        g_error := 'GET FLG_STATUS';
        SELECT flg_status
          INTO l_flg_status
          FROM audit_req
         WHERE id_audit_req = i_audit_req;
    
        IF l_flg_status = g_adt_req_req
        THEN
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T040');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_GRID_T041');
        ELSIF l_flg_status = g_adt_req_intr
        THEN
            o_msg_title := pk_message.get_message(i_lang, 'AUDIT_GRID_T042');
            o_msg       := pk_message.get_message(i_lang, 'AUDIT_GRID_T043');
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'INVALID ID_AUDIT_REQ: GOT(' || nvl(i_audit_req, 'NULL') || ')',
                                              g_owner,
                                              g_package_name,
                                              'GET_OPEN_AUDIT_TITLE',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_OPEN_AUDIT_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_open_audit_title;

    FUNCTION set_audit_req_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_audit_req    IN audit_req.id_audit_req%TYPE,
        i_flg_status   IN audit_req.flg_status%TYPE,
        i_notes_cancel IN audit_req.notes_cancel%TYPE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cur_flg_status VARCHAR2(1);
        l_b_result       VARCHAR2(1);
    
        l_can_open_close       BOOLEAN; --auditor normal
        l_can_cancel_interrupt BOOLEAN; --auditor super
    
        l_internal_error EXCEPTION;
        l_common_error   EXCEPTION;
        l_error_message sys_message.desc_message%TYPE;
    
    BEGIN
        g_error := 'INVALID FLG_STATUS - ' || i_flg_status;
        IF NOT pk_sysdomain.check_val_in_domain('AUDIT_REQ.FLG_STATUS', i_flg_status)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error        := 'GET AUDIT_REQ.FLG_STATUS';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        SELECT ar.flg_status
          INTO l_cur_flg_status
          FROM audit_req ar
         WHERE ar.id_audit_req = i_audit_req;
    
        --validar permissões deste utilizador para alterar o estado desta auditoria
        l_can_open_close       := is_regular_auditor(i_audit_req, i_prof);
        l_can_cancel_interrupt := is_super_auditor(i_audit_req, i_prof);
    
        g_error := 'VALIDATE STATE CHANGE';
        IF i_flg_status = g_adt_req_req
        --mudar estado para requisitada
        THEN
            --uma auditoria fica com estado requisitado quando é criada, e nunca mais
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR013');
            RAISE l_common_error;
        ELSIF i_flg_status = g_adt_req_open
        --mudar estado para aberta
        THEN
            --abrir uma auditoria: so é posivel se o estado for requisitado, ou interrompido
            IF l_cur_flg_status = g_adt_req_req
            THEN
                IF l_can_open_close
                THEN
                    g_error := 'CHANGE STATE 1';
                    --auditoria requisitada, passa a aberta
                    UPDATE audit_req
                       SET flg_status = g_adt_req_open, id_prof_open = i_prof.id, dt_open_tstz = g_sysdate_tstz
                     WHERE id_audit_req = i_audit_req;
                ELSE
                    --este auditor não pode abrir a auditoria (não é auditor)
                    l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR018');
                    RAISE l_common_error;
                END IF;
            ELSIF l_cur_flg_status = g_adt_req_intr
            THEN
                IF l_can_cancel_interrupt
                THEN
                    g_error := 'CHANGE STATE 2';
                    --auditoria interrompida passa a aberta
                    UPDATE audit_req
                       SET flg_status = g_adt_req_open
                     WHERE id_audit_req = i_audit_req;
                ELSE
                    --este auditor não pode abrir a auditoria (não é auditor)
                    l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR018');
                    RAISE l_common_error;
                END IF;
            ELSIF l_cur_flg_status = g_adt_req_open
            THEN
                --auditoria já está aberta
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR020');
                RAISE l_common_error;
            ELSE
                --auditoria está fechada ou cancelada, logo não pode ser aberta
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR014');
                RAISE l_common_error;
            END IF;
        
        ELSIF i_flg_status = g_adt_req_canc
        --mudar estado para cancelada
        THEN
            IF l_cur_flg_status = g_adt_req_req
               OR l_cur_flg_status = g_adt_req_open
               OR l_cur_flg_status = g_adt_req_intr
            THEN
                IF l_can_cancel_interrupt
                THEN
                    g_error := 'CHANGE STATE 3';
                
                    --auditoria requisitada, aberta ou interrompida passa a cancelada
                    UPDATE audit_req
                       SET flg_status     = g_adt_req_canc,
                           notes_cancel   = i_notes_cancel,
                           id_prof_cancel = i_prof.id,
                           dt_cancel_tstz = g_sysdate_tstz
                     WHERE id_audit_req = i_audit_req;
                ELSE
                    l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR015');
                    RAISE l_common_error;
                END IF;
            ELSIF l_cur_flg_status = g_adt_req_canc
            THEN
                --auditoria já cancelada
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR021');
                RAISE l_common_error;
            ELSE
                --auditoria fechada
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR022');
                RAISE l_common_error;
            END IF;
        
        ELSIF i_flg_status = g_adt_req_intr
        --mudar estado para interrompida
        THEN
            IF l_cur_flg_status = g_adt_req_open
            THEN
                IF l_can_cancel_interrupt
                THEN
                    g_error := 'CHANGE STATE 4';
                    --auditoria requisitada, aberta ou interrompida passa a cancelada
                    UPDATE audit_req
                       SET flg_status = g_adt_req_intr
                     WHERE id_audit_req = i_audit_req;
                ELSE
                    l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR015');
                    RAISE l_common_error;
                END IF;
            ELSE
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR023');
                RAISE l_common_error;
            END IF;
        ELSE
            --mudar estado para fechada
            IF l_cur_flg_status = g_adt_req_open
            THEN
                IF l_can_open_close
                THEN
                    --verificar se todos os dados obrigatórios estão preenchidos
                    IF NOT check_can_close_audit_req(i_lang,
                                                     i_prof,
                                                     i_audit_req,
                                                     o_flg_show,
                                                     o_msg_title,
                                                     o_msg,
                                                     o_button,
                                                     l_b_result,
                                                     o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                    IF l_b_result <> 'Y'
                    THEN
                        l_error_message := o_msg;
                        RAISE l_common_error;
                    END IF;
                
                    g_error := 'CHANGE STATE 5';
                    UPDATE audit_req
                       SET flg_status = g_adt_req_close, id_prof_close = i_prof.id, dt_close_tstz = g_sysdate_tstz
                     WHERE id_audit_req = i_audit_req;
                
                ELSE
                    l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR024');
                    RAISE l_common_error;
                END IF;
            ELSE
                l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR022');
                RAISE l_common_error;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_common_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'SET_AUDIT_REQ_STATE',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_AUDIT_REQ_STATE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_audit_req_state;

    FUNCTION set_prof_saw_result
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        i_answer         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'UPDATE ARP';
        IF i_answer NOT IN (g_yes, g_no)
        THEN
            g_error := 'INVALID I_ANSWER';
            RAISE l_internal_error;
        END IF;
    
        UPDATE audit_req_prof
           SET flg_saw_result = i_answer
         WHERE id_audit_req_prof = i_audit_req_prof;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_PROF_SAW_RESULT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END;

    FUNCTION get_criteria_icons
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_icons OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_ICONS';
        RETURN pk_sysdomain.get_values_domain('AUDIT_QUEST_ANSWER.ANSWER', i_lang, o_icons);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_CRITERIA_ICONS',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_list_audited_profs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_audit_req IN audit_req.id_audit_req%TYPE,
        
        o_profs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'GET SHORTCUTS';
        IF NOT pk_access.preload_shortcuts(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_screens => table_varchar('AUDITED_EPIS'),
                                           o_error   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'OPEN O_PROFS';
        OPEN o_profs FOR
            SELECT arp.id_audit_req_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name,
                   arp.num_adt_epis - nvl(calc_adt.num_pats, 0) num_audited,
                   nvl(calc_adt.num_pats, 0) num_to_audit,
                   calc_ans.num_pri_ok,
                   calc_ans.num_pri_ans,
                   round(calc_ans.num_pri_ok * 100 / calc_ans.num_pri_ans, 1) perc_pri_ok,
                   arp.flg_saw_result,
                   pk_access.get_shortcut('AUDITED_EPIS') shortcut
              FROM audit_req_prof arp,
                   (SELECT arpe.id_audit_req_prof, COUNT(DISTINCT arpe.id_audit_req_prof_epis) num_pats
                      FROM audit_criteria aq, audit_req_prof_epis arpe, audit_req_prof arp, audit_req ar
                     WHERE aq.id_audit_type = ar.id_audit_type
                       AND aq.flg_for = g_adt_quest_for_epis
                       AND aq.flg_required = g_yes
                       AND aq.flg_ans_type <> g_adt_quest_tp_qnt
                       AND aq.flg_ans_criteria NOT IN ('L', 'T', 'O', 'R')
                       AND NOT EXISTS (SELECT 0
                              FROM audit_quest_answer aqa
                             WHERE aqa.id_audit_criteria = aq.id_audit_criteria
                               AND aqa.id_audit_req_prof_epis = arpe.id_audit_req_prof_epis
                               AND aqa.answer IS NOT NULL)
                       AND arp.id_audit_req_prof = arpe.id_audit_req_prof
                       AND arp.id_audit_req = i_audit_req
                       AND ar.id_audit_req = i_audit_req
                     GROUP BY arpe.id_audit_req_prof) calc_adt,
                   (SELECT arp.id_audit_req_prof, SUM(decode(aqa.answer, g_yes, 1, 0)) num_pri_ok, COUNT(0) num_pri_ans
                      FROM audit_quest_answer aqa, audit_req_prof_epis arpe, audit_req_prof arp, audit_criteria aq
                     WHERE arp.id_audit_req = i_audit_req
                       AND arp.id_audit_req_prof = arpe.id_audit_req_prof
                       AND aqa.id_audit_req_prof_epis = arpe.id_audit_req_prof_epis
                       AND aq.id_audit_criteria = aqa.id_audit_criteria
                       AND aq.flg_ans_criteria = g_adt_qt_crit_pri
                       AND aq.flg_ans_type = g_adt_quest_tp_bool
                       AND aqa.answer IS NOT NULL
                     GROUP BY arp.id_audit_req_prof) calc_ans,
                   professional p
             WHERE arp.flg_rel_type = g_adt_req_prf_rel_audited
               AND arp.id_audit_req = i_audit_req
               AND p.id_professional = arp.id_professional
               AND calc_adt.id_audit_req_prof(+) = arp.id_audit_req_prof
               AND calc_ans.id_audit_req_prof(+) = arp.id_audit_req_prof
             ORDER BY num_to_audit DESC, name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_LIST_AUDITED_PROFS',
                                              o_error);
            pk_types.open_my_cursor(o_profs);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_list_audited_profs;

    FUNCTION get_audited_prof_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof_epis.id_audit_req_prof%TYPE,
        o_det            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_DET';
        OPEN o_det FOR
            SELECT rec.group_id,
                   pk_date_utils.to_char_insttimezone(i_prof, rec.dt_saved_tstz, g_date_mask) dt_saved,
                   rec.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rec.id_professional) prof_name,
                   arc_main.t_comment main_comment,
                   pk_translation.get_translation(i_lang, ac.code_audit_criteria) question,
                   decode(ac.flg_ans_type,
                          g_adt_quest_tp_bool,
                          decode(arc.answer,
                                 g_yes,
                                 pk_message.get_message(i_lang, 'AUDIT_GRID_T024'),
                                 g_no,
                                 pk_message.get_message(i_lang, 'AUDIT_GRID_T025'),
                                 NULL),
                          arc.answer) answer,
                   arc.t_comment
              FROM audit_req_comment  arc,
                   audit_quest_answer aqa,
                   audit_criteria     ac,
                   audit_req_comment  arc_main,
                   
                   (SELECT dt_saved_tstz, id_professional, rownum group_id
                      FROM (SELECT *
                              FROM (SELECT DISTINCT * --union é mais pesado!!!
                                      FROM (SELECT arc.dt_saved_tstz, arc.id_professional
                                              FROM audit_req_comment arc
                                             WHERE arc.id_audit_req_prof = i_audit_req_prof
                                            UNION ALL
                                            SELECT arc.dt_saved_tstz, arc.id_professional
                                              FROM audit_req_comment arc, audit_quest_answer aqa
                                             WHERE aqa.id_audit_req_prof = i_audit_req_prof
                                               AND arc.id_audit_quest_answer = aqa.id_audit_quest_answer
                                               AND arc.id_professional IS NOT NULL))
                             ORDER BY dt_saved_tstz DESC)) rec
             WHERE arc.dt_saved_tstz = rec.dt_saved_tstz
               AND arc.id_professional = rec.id_professional
               AND arc.id_audit_quest_answer = aqa.id_audit_quest_answer
               AND aqa.id_audit_req_prof = i_audit_req_prof
               AND ac.id_audit_criteria = aqa.id_audit_criteria
                  
               AND arc_main.dt_saved_tstz(+) = rec.dt_saved_tstz
               AND arc_main.id_professional(+) = rec.id_professional
               AND arc_main.id_audit_req_prof(+) = i_audit_req_prof
             ORDER BY rec.dt_saved_tstz DESC, prof_name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_AUDITED_PROF_DET',
                                              o_error);
            pk_types.open_my_cursor(o_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_audited_prof_det;

    FUNCTION get_list_quests_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        --o_flg_show  OUT VARCHAR2,
        --o_msg_title OUT VARCHAR2,
        --o_msg  OUT VARCHAR2,
        --o_button    OUT VARCHAR2,
        
        o_quests      OUT pk_types.cursor_type,
        o_comments    OUT pk_types.cursor_type,
        o_has_history OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_audit_req  audit_req.id_audit_req%TYPE;
        l_audit_type audit_req.id_audit_type%TYPE;
    BEGIN
        g_error := 'GET AUDIT IDS';
        SELECT ar.id_audit_req, ar.id_audit_type
          INTO l_audit_req, l_audit_type
          FROM audit_req ar, audit_req_prof arp
         WHERE ar.id_audit_req = arp.id_audit_req
           AND arp.id_audit_req_prof = i_audit_req_prof;
    
        g_error := 'OPEN O_QUESTS';
        OPEN o_quests FOR
        --respostas não quantitativas
            SELECT aq.id_audit_criteria,
                   pk_translation.get_translation(i_lang, aq.code_audit_criteria) desc_audit_criteria,
                   aq.flg_ans_type,
                   aq.flg_ans_criteria,
                   aqa.answer answer_bool,
                   NULL answer_qnt_total,
                   NULL answer_qnt_yes,
                   NULL answer_qnt_no,
                   g_yes editable,
                   (SELECT decode(COUNT(0), 0, g_no, g_yes)
                      FROM audit_req_comment arc
                     WHERE arc.id_audit_quest_answer = aqa.id_audit_quest_answer
                       AND arc.t_comment IS NOT NULL) has_notes
            --decode(aq.flg_ans_type,
            --       g_adt_quest_tp_bool,
            --       decode(aqa.answer,
            --              g_yes,
            --              '0|xxxxxxxxxxxxxx|I|G|' ||
            --              pk_sysdomain.get_img(i_lang, 'AUDIT_QUEST_ANSWER.ANSWER', aqa.answer))) icon_yes,
            --decode(aq.flg_ans_type,
            --       g_adt_quest_tp_bool,
            --       decode(aqa.answer,
            --              g_no,
            --              '0|xxxxxxxxxxxxxx|I|R|' ||
            --              pk_sysdomain.get_img(i_lang, 'AUDIT_QUEST_ANSWER.ANSWER', aqa.answer))) icon_no
              FROM audit_criteria aq, audit_req_prof arp, audit_quest_answer aqa
             WHERE arp.id_audit_req_prof = i_audit_req_prof
               AND arp.flg_rel_type = g_adt_req_prf_rel_audited
               AND aq.id_audit_type = l_audit_type
               AND aq.flg_for = g_adt_qt_for_prof
               AND aq.flg_required = g_yes
               AND aq.flg_ans_type <> g_adt_quest_tp_qnt
               AND aqa.id_audit_req_prof(+) = i_audit_req_prof
               AND aqa.id_audit_criteria(+) = aq.id_audit_criteria
            UNION ALL
            --resposta quantitativas
            SELECT aq.id_audit_criteria,
                   pk_translation.get_translation(i_lang, aq.code_audit_criteria) desc_criteria,
                   aq.flg_ans_type,
                   aq.flg_ans_criteria,
                   NULL answer_bool,
                   arp.num_adt_epis answer_qnt_total,
                   coalesce(ans_calc.ans_yes, to_number(aqa.answer), 0) answer_qnt_yes,
                   coalesce(ans_calc.ans_no, to_number(aqa.answer), 0) answer_qnt_no,
                   g_no editable,
                   (SELECT decode(COUNT(0), 0, g_no, g_yes)
                      FROM audit_quest_answer aqa, audit_req_comment arc
                     WHERE arc.id_audit_quest_answer = aqa.id_audit_quest_answer
                       AND aqa.id_audit_req_prof = i_audit_req_prof
                       AND aqa.id_audit_criteria = aq.id_audit_criteria) has_notes
            --decode(aq.flg_ans_type,
            --       g_adt_quest_tp_qnt,
            --       '0|xxxxxxxxxxxxxx|T|X|' || coalesce(ans_calc.ans_yes, to_number(aqa.answer), 0)) icon_yes,
            --decode(aq.flg_ans_type,
            --       g_adt_quest_tp_qnt,
            --       '0|xxxxxxxxxxxxxx|T|X|' || coalesce(ans_calc.ans_no, to_number(aqa.answer), 0)) icon_no
              FROM audit_criteria aq,
                   audit_req_prof arp,
                   (SELECT aq.flg_ans_criteria,
                           SUM(decode(aqa.answer, g_yes, 1, 0)) ans_yes,
                           SUM(decode(aqa.answer, g_no, 1, 0)) ans_no
                      FROM audit_criteria aq, audit_quest_answer aqa, audit_req_prof_epis arpe
                     WHERE arpe.id_audit_req_prof = i_audit_req_prof
                       AND aqa.id_audit_req_prof_epis = arpe.id_audit_req_prof_epis
                       AND aqa.id_audit_criteria = aq.id_audit_criteria
                       AND aq.flg_for = g_adt_qt_for_epis
                       AND aq.flg_ans_type = g_adt_quest_tp_bool
                       AND aq.flg_ans_criteria IN (SELECT DISTINCT aq.flg_ans_criteria
                                                     FROM audit_criteria aq
                                                    WHERE aq.flg_ans_type = g_adt_quest_tp_qnt
                                                      AND aq.flg_for = g_adt_qt_for_prof
                                                      AND aq.id_audit_type = l_audit_type)
                     GROUP BY aq.flg_ans_criteria) ans_calc,
                   audit_quest_answer aqa
             WHERE arp.id_audit_req_prof = i_audit_req_prof
               AND arp.flg_rel_type = g_adt_req_prf_rel_audited
               AND aq.id_audit_type = l_audit_type
               AND aq.flg_for = g_adt_qt_for_prof
                  
               AND aq.flg_ans_type = g_adt_quest_tp_qnt
               AND ans_calc.flg_ans_criteria(+) = aq.flg_ans_criteria
               AND aqa.id_audit_req_prof(+) = i_audit_req_prof
               AND aqa.id_audit_criteria(+) = aq.id_audit_criteria
             ORDER BY editable DESC, desc_audit_criteria;
    
        g_error := 'OPEN O_COMMENTS';
        OPEN o_comments FOR
            SELECT arc.t_comment,
                   pk_date_utils.to_char_insttimezone(i_prof, arc.dt_saved_tstz, g_date_mask) dt_saved,
                   arc.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name
              FROM audit_req_comment arc, professional p
             WHERE arc.id_audit_req_prof = i_audit_req_prof
               AND arc.id_professional = p.id_professional
             ORDER BY arc.dt_saved_tstz DESC;
    
        g_error := 'COUNT HISTORY';
        SELECT decode((SELECT COUNT(0)
                         FROM audit_quest_answer q, audit_req_comment r
                        WHERE q.id_audit_quest_answer = r.id_audit_quest_answer
                          AND q.id_audit_req_prof = i_audit_req_prof) +
                      (SELECT COUNT(0)
                         FROM audit_req_comment r
                        WHERE r.id_audit_req_prof = i_audit_req_prof),
                      0,
                      g_no,
                      g_yes)
          INTO o_has_history
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_LIST_QUESTS_PROF',
                                              o_error);
            pk_types.open_my_cursor(o_quests);
            pk_types.open_my_cursor(o_comments);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_list_quests_prof;

    FUNCTION get_quest_answer_prof_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        i_audit_criteria IN audit_criteria.id_audit_criteria%TYPE,
        o_notes          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_NOTES';
        OPEN o_notes FOR
            SELECT arc.t_comment,
                   pk_date_utils.to_char_insttimezone(i_prof, arc.dt_saved_tstz, g_date_mask) dt_saved,
                   arc.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name
              FROM audit_req_comment arc, professional p, audit_quest_answer aqa
             WHERE aqa.id_audit_criteria = i_audit_criteria
               AND aqa.id_audit_req_prof = i_audit_req_prof
               AND arc.id_audit_quest_answer = aqa.id_audit_quest_answer
               AND arc.id_professional = p.id_professional
               AND arc.t_comment IS NOT NULL
             ORDER BY arc.dt_saved_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_QUEST_ANSWER_PROF_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_quest_answer_prof_notes;

    FUNCTION set_quest_answer_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        i_ids_criterias  IN table_number,
        i_answers        IN table_varchar,
        i_notes          IN table_varchar,
        i_comment        IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_audit_req      audit_req.id_audit_req%TYPE;
        l_audit_type     audit_type.id_audit_type%TYPE;
        l_flg_status     audit_req.flg_status%TYPE;
        l_quest_ans_id   audit_quest_answer.id_audit_quest_answer%TYPE;
        l_quest_ans_tp   audit_criteria.flg_ans_type%TYPE;
        l_quest_editable VARCHAR2(1);
        l_can_answer     BOOLEAN;
        l_last_comment   audit_req_comment.t_comment%TYPE;
        l_answer         audit_quest_answer.answer%TYPE;
        l_last_ans       audit_quest_answer.answer%TYPE;
        l_count          PLS_INTEGER;
        l_notes          audit_req_comment.t_comment%TYPE;
        l_found          BOOLEAN;
    
        l_error_message sys_message.desc_message%TYPE;
        l_internal_error EXCEPTION;
        l_common_error   EXCEPTION;
    
        CURSOR c_answers(i_id_audit_criteria IN audit_criteria.id_audit_criteria%TYPE) IS
            SELECT aqa.id_audit_quest_answer,
                   aq.flg_ans_type,
                   decode(aq.flg_ans_type, g_adt_quest_tp_qnt, g_no, g_yes) editable,
                   aqa.answer
              FROM audit_quest_answer aqa, audit_criteria aq
             WHERE aqa.id_audit_req_prof = i_audit_req_prof
               AND aqa.id_audit_criteria = i_id_audit_criteria
               AND aq.id_audit_criteria = i_id_audit_criteria;
    
        CURSOR c_comment IS
            SELECT t_comment
              FROM audit_req_comment
             WHERE id_audit_req_prof = i_audit_req_prof
               AND t_comment IS NOT NULL
             ORDER BY dt_saved_tstz DESC;
    
    BEGIN
        g_error        := 'GET ID_AUDIT_REQ';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        SELECT DISTINCT ar.id_audit_req, ar.id_audit_type, ar.flg_status
          INTO l_audit_req, l_audit_type, l_flg_status
          FROM audit_req ar, audit_req_prof arp, audit_req_prof_epis arpe
         WHERE arp.id_audit_req_prof = i_audit_req_prof
           AND ar.id_audit_req = arp.id_audit_req;
    
        g_error      := 'GET PERM';
        l_can_answer := is_regular_auditor(l_audit_req, i_prof);
    
        IF NOT l_can_answer
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR030');
            RAISE l_common_error;
        ELSIF l_flg_status <> g_adt_req_open
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR031');
            RAISE l_common_error;
        END IF;
    
        --filtrar arrays
        IF i_ids_criterias.count <> i_answers.count
        THEN
            --número de perguntas e respostas diferente
            g_error := 'NUM ANS DIF NUM QUESTS';
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CLEAN DUPS';
        --duplicados
        SELECT COUNT(0)
          INTO l_count
          FROM audit_criteria aq, TABLE(i_ids_criterias) ids
         WHERE aq.id_audit_criteria = ids.column_value
           AND aq.flg_for = g_adt_quest_for_prof
           AND aq.id_audit_type = l_audit_type;
    
        IF l_count <> i_ids_criterias.count
        THEN
            --ids de perguntas inválidos ou repetidos
            g_error := 'DUP\INVALID QUEST ID ';
            RAISE l_internal_error;
        END IF;
    
        --inserir respostas
        g_error := 'LOOP ANSWERS';
        FOR idx IN 1 .. i_ids_criterias.count
        LOOP
            --ler resposta anterior, para actualizar
            g_error := 'OPEN C_ANSWERS(' || idx || ')';
            OPEN c_answers(i_ids_criterias(idx));
            FETCH c_answers
                INTO l_quest_ans_id, l_quest_ans_tp, l_quest_editable, l_last_ans;
            l_found := c_answers%NOTFOUND;
            CLOSE c_answers;
        
            l_answer := i_answers(idx);
            IF l_quest_editable = 'N'
               OR l_answer = l_last_ans
            THEN
                l_answer := NULL;
            ELSIF l_quest_ans_tp = g_adt_quest_tp_bool
                  AND l_answer NOT IN (g_yes, g_no)
            --filtrar booleanos
            THEN
                g_error := 'INVALID BOOL VALUE (''' || l_answer || ''')';
                RAISE l_internal_error;
            END IF;
        
            IF l_found
            --resposta nova
            THEN
                g_error := 'INSERT ANSWER (' || i_audit_req_prof || ',' || i_ids_criterias(idx) || ')';
                INSERT INTO audit_quest_answer
                    (id_audit_quest_answer,
                     id_audit_criteria,
                     id_professional,
                     id_audit_req_prof,
                     dt_answer_tstz,
                     answer)
                VALUES
                    (seq_audit_quest_answer.nextval,
                     i_ids_criterias(idx),
                     i_prof.id,
                     i_audit_req_prof,
                     g_sysdate_tstz,
                     l_answer)
                RETURNING id_audit_quest_answer INTO l_quest_ans_id;
            ELSIF l_quest_editable != g_no
            THEN
                --resposta existente - actualizar
                g_error := 'UPDATE ANSWER (' || i_audit_req_prof || ',' || i_ids_criterias(idx) || ')';
                UPDATE audit_quest_answer
                   SET id_professional = i_prof.id, dt_answer_tstz = g_sysdate_tstz, answer = nvl(l_answer, answer)
                 WHERE id_audit_quest_answer = l_quest_ans_id;
            END IF;
        
            IF i_notes IS NOT NULL
               AND i_notes.count >= idx
               AND i_notes(idx) IS NOT NULL
               AND length(TRIM(i_notes(idx))) > 0
            THEN
                l_notes := i_notes(idx);
            ELSE
                l_notes := NULL;
            END IF;
        
            --inserir notas da pergunta
            IF l_notes IS NOT NULL
               OR l_answer IS NOT NULL
            THEN
                g_error := 'INSERT COMMENT QUEST';
                INSERT INTO audit_req_comment
                    (id_audit_req_comment,
                     id_professional,
                     id_audit_quest_answer,
                     flg_status,
                     dt_saved_tstz,
                     t_comment,
                     answer)
                VALUES
                    (seq_audit_req_comment.nextval,
                     i_prof.id,
                     l_quest_ans_id,
                     g_adt_req_cmt_flg_norm,
                     g_sysdate_tstz,
                     i_notes(idx),
                     l_answer);
            END IF;
        END LOOP;
    
        OPEN c_comment;
        FETCH c_comment
            INTO l_last_comment;
        CLOSE c_comment;
    
        IF i_comment IS NOT NULL
           AND length(TRIM(i_comment)) > 0
           AND (l_last_comment != i_comment OR l_last_comment IS NULL)
        --inserir comentário sobre o episódio
        THEN
            g_error := 'INSERT COMMENT EPIS';
            INSERT INTO audit_req_comment
                (id_audit_req_comment, id_professional, id_audit_req_prof, flg_status, dt_saved_tstz, t_comment)
            VALUES
                (seq_audit_req_comment.nextval,
                 i_prof.id,
                 i_audit_req_prof,
                 g_adt_req_cmt_flg_norm,
                 g_sysdate_tstz,
                 i_comment);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_common_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'SET_QUEST_ANSWER_PROF',
                                   NULL,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_INTERNAL_ERROR',
                                              'INVALID DATA',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_QUEST_ANSWER_PROF',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_QUEST_ANSWER_PROF',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_quest_answer_prof;

    FUNCTION get_list_audited_epis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_EPIS';
        OPEN o_epis FOR
            SELECT arpe.id_audit_req_prof_epis,
                   etr.id_episode,
                   (SELECT epi.id_visit
                      FROM episode epi
                     WHERE epi.id_episode = etr.id_episode) id_visit,
                   (SELECT epi.id_patient
                      FROM episode epi
                     WHERE epi.id_episode = etr.id_episode) id_patient,
                   (SELECT tco.color
                      FROM triage_color tco
                     WHERE tco.id_triage_color = etr.id_triage_color) acuity,
                   (SELECT tco.color_text
                      FROM triage_color tco
                     WHERE tco.id_triage_color = etr.id_triage_color) color_text,
                   (SELECT tco.rank
                      FROM triage_color tco
                     WHERE tco.id_triage_color = etr.id_triage_color) rank_acuity,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, epi.id_patient, epi.id_episode)
                      FROM episode epi
                     WHERE epi.id_episode = etr.id_episode) pat_name,
                   -- ALERT-102882 Patient name used for sorting 
                   (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, epi.id_patient, epi.id_episode)
                      FROM episode epi
                     WHERE epi.id_episode = etr.id_episode) name_pat_sort,
                   (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, epi.id_patient)
                      FROM episode epi
                     WHERE epi.id_episode = etr.id_episode) pat_ndo,
                   (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epi.id_patient)
                      FROM episode epi
                     WHERE epi.id_episode = etr.id_episode) pat_nd_icon,
                   -- <DENORM_EPISODE_JOSE_BRITO>
                   (SELECT VALUE
                      FROM epis_ext_sys ees, episode epi
                     WHERE ees.id_episode = etr.id_episode
                       AND epi.id_episode = etr.id_episode
                       AND ees.id_institution = i_prof.institution
                          --
                       AND ees.id_external_sys =
                           pk_sysconfig.get_config('ID_EXTERNAL_SYS',
                                                   i_prof.institution,
                                                   pk_episode.get_soft_by_epis_type(epi.id_epis_type, i_prof.institution))) id_ext_epis,
                   --AND etsi.id_institution = vis.id_institution) id_ext_epis,
                   decode(ids_nadt.id_audit_req_prof_epis, NULL, g_yes, g_no) audit_ok,
                   pk_message.get_message(i_lang,
                                          decode(ids_nadt.id_audit_req_prof_epis,
                                                 NULL,
                                                 'AUDIT_GRID_T044',
                                                 'AUDIT_GRID_T045')) desc_audit_state,
                   etr.id_epis_triage,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, etr.id_episode, etr.id_triage_color)
                      FROM dual) esi_level -- José Brito 26/02/2010 ALERT-721 ESI Level triage, when applicable
              FROM audit_req_prof_epis arpe,
                   epis_triage etr,
                   (SELECT DISTINCT arpe.id_audit_req_prof_epis
                      FROM audit_criteria aq, audit_req_prof_epis arpe
                     WHERE aq.flg_for = g_adt_quest_for_epis
                       AND aq.flg_ans_type <> g_adt_quest_tp_qnt
                       AND aq.flg_required = g_yes
                       AND aq.flg_ans_criteria NOT IN ('L', 'T', 'O', 'R')
                       AND NOT EXISTS (SELECT 0
                              FROM audit_quest_answer aqa
                             WHERE aqa.id_audit_criteria = aq.id_audit_criteria
                               AND aqa.id_audit_req_prof_epis = arpe.id_audit_req_prof_epis
                               AND aqa.answer IS NOT NULL)
                       AND arpe.id_audit_req_prof = i_audit_req_prof) ids_nadt
             WHERE arpe.id_audit_req_prof = i_audit_req_prof
               AND ids_nadt.id_audit_req_prof_epis(+) = arpe.id_audit_req_prof_epis
               AND etr.id_epis_triage = arpe.id_epis_triage
             ORDER BY decode(audit_ok, g_yes, 1, g_no, 0) ASC, pat_name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_LIST_AUDITED_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_epis);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_list_audited_epis;

    FUNCTION get_audited_epis_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        o_det   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_DET';
        OPEN o_det FOR
            SELECT rec.group_id,
                   pk_date_utils.to_char_insttimezone(i_prof, rec.dt_saved_tstz, g_date_mask) dt_saved,
                   rec.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rec.id_professional) prof_name,
                   arc_main.t_comment main_comment,
                   pk_translation.get_translation(i_lang, ac.code_audit_criteria) question,
                   decode(ac.flg_ans_type,
                          g_adt_quest_tp_bool,
                          decode(arc.answer,
                                 g_yes,
                                 pk_message.get_message(i_lang, 'AUDIT_GRID_T024'),
                                 g_no,
                                 pk_message.get_message(i_lang, 'AUDIT_GRID_T025'),
                                 NULL),
                          arc.answer) answer,
                   arc.t_comment
              FROM audit_req_comment arc,
                   audit_quest_answer aqa,
                   audit_criteria ac,
                   audit_req_comment arc_main,
                   (SELECT dt_saved_tstz, id_professional, rownum group_id
                      FROM (SELECT *
                              FROM (SELECT DISTINCT *
                                      FROM (SELECT arc.dt_saved_tstz, arc.id_professional
                                              FROM audit_req_comment arc
                                             WHERE arc.id_audit_req_prof_epis = i_audit_req_prof_epis
                                            UNION ALL
                                            SELECT arc.dt_saved_tstz, arc.id_professional
                                              FROM audit_req_comment arc, audit_quest_answer aqa
                                             WHERE aqa.id_audit_req_prof_epis = i_audit_req_prof_epis
                                               AND arc.id_audit_quest_answer = aqa.id_audit_quest_answer
                                               AND arc.id_professional IS NOT NULL))
                             ORDER BY dt_saved_tstz DESC)) rec
             WHERE arc.dt_saved_tstz = rec.dt_saved_tstz
               AND arc.id_professional = rec.id_professional
               AND arc.id_audit_quest_answer = aqa.id_audit_quest_answer
               AND aqa.id_audit_req_prof_epis = i_audit_req_prof_epis
               AND ac.id_audit_criteria = aqa.id_audit_criteria
                  --main comment
               AND arc_main.dt_saved_tstz(+) = rec.dt_saved_tstz
               AND arc_main.id_professional(+) = rec.id_professional
               AND arc_main.id_audit_req_prof_epis(+) = i_audit_req_prof_epis
             ORDER BY rec.dt_saved_tstz DESC, prof_name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_AUDITED_EPIS_DET',
                                              o_error);
            pk_types.open_my_cursor(o_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_audited_epis_det;

    FUNCTION get_list_quests_epis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        o_quests      OUT pk_types.cursor_type,
        o_comments    OUT pk_types.cursor_type,
        o_has_history OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_QUESTS';
        OPEN o_quests FOR
            SELECT aq.id_audit_criteria,
                   pk_translation.get_translation(i_lang, aq.code_audit_criteria) desc_audit_criteria,
                   aq.flg_ans_type,
                   aq.flg_ans_criteria,
                   aqa.answer answer_bool,
                   NULL answer_qnt_total,
                   aq.editable,
                   (SELECT decode(COUNT(0), 0, g_no, g_yes)
                      FROM audit_req_comment arc
                     WHERE arc.id_audit_quest_answer = aqa.id_audit_quest_answer
                       AND arc.t_comment IS NOT NULL) has_notes
            --decode(decode(aq.flg_ans_type, g_adt_quest_tp_bool, 1, g_adt_quest_tp_qnt, 1, 0),
            --       1,
            --       decode(aqa.answer,
            --              NULL,
            --              NULL,
            --              '0|xxxxxxxxxxxxxx|' || decode(aq.flg_ans_type, g_adt_quest_tp_bool, 'I', 'T') || '|' ||
            --              decode(aq.editable, g_no, 'X', 'G') || '|' ||
            --              decode(aq.flg_ans_type,
            --                     g_adt_quest_tp_bool,
            --                     pk_sysdomain.get_img(i_lang, 'AUDIT_QUEST_ANSWER.ANSWER', aqa.answer),
            --                     aqa.answer))) icon_yes,
            --decode(decode(aq.flg_ans_type, g_adt_quest_tp_bool, 1, g_adt_quest_tp_qnt, 1, 0),
            --       1,
            --       decode(aqa.answer,
            --              NULL,
            --              NULL,
            --              '0|xxxxxxxxxxxxxx|' || decode(aq.flg_ans_type, g_adt_quest_tp_bool, 'I', 'T') || '|' ||
            --              decode(aq.editable, g_no, 'X', 'R') || '|' ||
            --              decode(aq.flg_ans_type,
            --                     g_adt_quest_tp_bool,
            --                     pk_sysdomain.get_img(i_lang, 'AUDIT_QUEST_ANSWER.ANSWER', aqa.answer),
            --                     aqa.answer))) icon_no
              FROM (SELECT ac.*,
                           decode(ac.flg_ans_type,
                                  g_adt_quest_tp_qnt,
                                  g_no,
                                  decode(ac.flg_ans_criteria,
                                         g_adt_qt_crit_pain,
                                         g_no,
                                         g_adt_qt_crit_repain,
                                         g_no,
                                         g_adt_qt_crit_doc_read,
                                         g_no,
                                         g_adt_qt_crit_rtr,
                                         g_no,
                                         g_yes)) editable
                      FROM audit_criteria ac) aq,
                   audit_req ar,
                   audit_req_prof arp,
                   audit_req_prof_epis arpe,
                   audit_quest_answer aqa
             WHERE arpe.id_audit_req_prof_epis = i_audit_req_prof_epis
               AND arp.id_audit_req_prof = arpe.id_audit_req_prof
               AND ar.id_audit_req = arp.id_audit_req
               AND aq.id_audit_type = ar.id_audit_type
               AND aq.flg_for = g_adt_quest_for_epis
               AND aq.flg_ans_type <> g_adt_quest_tp_qnt
               AND aqa.id_audit_req_prof_epis(+) = i_audit_req_prof_epis
               AND aqa.id_audit_criteria(+) = aq.id_audit_criteria
             ORDER BY editable DESC, desc_audit_criteria;
    
        g_error := 'OPEN O_COMMENTS';
        OPEN o_comments FOR
            SELECT arc.t_comment,
                   pk_date_utils.to_char_insttimezone(i_prof, arc.dt_saved_tstz, g_date_mask) dt_saved,
                   arc.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name
              FROM audit_req_comment arc, professional p
             WHERE arc.id_audit_req_prof_epis = i_audit_req_prof_epis
               AND arc.id_professional = p.id_professional
             ORDER BY dt_saved DESC;
    
        g_error := 'COUNT HISTORY';
        SELECT decode((SELECT COUNT(0)
                         FROM audit_quest_answer q, audit_req_comment r
                        WHERE q.id_audit_quest_answer = r.id_audit_quest_answer
                          AND q.id_audit_req_prof_epis = i_audit_req_prof_epis) +
                      (SELECT COUNT(0)
                         FROM audit_req_comment r
                        WHERE r.id_audit_req_prof_epis = i_audit_req_prof_epis),
                      0,
                      g_no,
                      g_yes)
          INTO o_has_history
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_LIST_QUESTS_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_quests);
            pk_types.open_my_cursor(o_comments);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_list_quests_epis;

    FUNCTION get_quest_answer_epis_notes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_audit_criteria      IN audit_criteria.id_audit_criteria%TYPE,
        o_notes               OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_NOTES';
        OPEN o_notes FOR
            SELECT arc.t_comment,
                   pk_date_utils.to_char_insttimezone(i_prof, arc.dt_saved_tstz, g_date_mask) dt_saved,
                   arc.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name
              FROM audit_req_comment arc, professional p, audit_quest_answer aqa
             WHERE aqa.id_audit_criteria = i_audit_criteria
               AND aqa.id_audit_req_prof_epis = i_audit_req_prof_epis
               AND arc.id_audit_quest_answer = aqa.id_audit_quest_answer
               AND arc.id_professional = p.id_professional
               AND arc.t_comment IS NOT NULL
             ORDER BY dt_saved DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_QUEST_ANSWER_EPIS_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_quest_answer_epis_notes;

    FUNCTION set_quest_answer_epis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        i_ids_criterias IN table_number,
        i_answers       IN table_varchar,
        i_notes         IN table_varchar,
        i_comment       IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_audit_req      audit_req.id_audit_req%TYPE;
        l_audit_type     audit_type.id_audit_type%TYPE;
        l_flg_status     audit_req.flg_status%TYPE;
        l_quest_ans_id   audit_quest_answer.id_audit_quest_answer%TYPE;
        l_quest_ans_tp   audit_criteria.flg_ans_type%TYPE;
        l_quest_editable VARCHAR2(1);
        l_can_answer     BOOLEAN;
        l_last_comment   audit_req_comment.t_comment%TYPE;
        l_answer         audit_quest_answer.answer%TYPE;
        l_last_ans       audit_quest_answer.answer%TYPE;
        l_count          PLS_INTEGER;
        l_notes          audit_req_comment.t_comment%TYPE;
        l_found          BOOLEAN;
    
        l_internal_error EXCEPTION;
        l_common_error   EXCEPTION;
        l_error_message sys_message.desc_message%TYPE;
    
        CURSOR c_answers(i_id_audit_criteria IN audit_criteria.id_audit_criteria%TYPE) IS
            SELECT aqa.id_audit_quest_answer,
                   aq.flg_ans_type,
                   decode(aq.flg_ans_type,
                          g_adt_quest_tp_qnt,
                          g_no,
                          decode(aq.flg_ans_criteria,
                                 g_adt_qt_crit_pain,
                                 g_no,
                                 g_adt_qt_crit_repain,
                                 g_no,
                                 g_adt_qt_crit_doc_read,
                                 g_no,
                                 g_adt_qt_crit_rtr,
                                 g_no,
                                 g_yes)) editable,
                   aqa.answer
              FROM audit_quest_answer aqa, audit_criteria aq
             WHERE aqa.id_audit_req_prof_epis = i_audit_req_prof_epis
               AND aqa.id_audit_criteria = i_id_audit_criteria
               AND aq.id_audit_criteria = i_id_audit_criteria;
    
        CURSOR c_comment IS
            SELECT t_comment
              FROM audit_req_comment
             WHERE id_audit_req_prof = i_audit_req_prof_epis
               AND t_comment IS NOT NULL
             ORDER BY dt_saved_tstz DESC;
    
    BEGIN
        g_error        := 'GET ID_AUDIT_REQ';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        SELECT DISTINCT ar.id_audit_req, ar.id_audit_type, ar.flg_status
          INTO l_audit_req, l_audit_type, l_flg_status
          FROM audit_req ar, audit_req_prof arp, audit_req_prof_epis arpe
         WHERE arpe.id_audit_req_prof_epis = i_audit_req_prof_epis
           AND arp.id_audit_req_prof = arpe.id_audit_req_prof
           AND ar.id_audit_req = arp.id_audit_req;
    
        g_error      := 'GET PERM';
        l_can_answer := is_regular_auditor(l_audit_req, i_prof);
    
        IF NOT l_can_answer
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR030');
            RAISE l_common_error;
        ELSIF l_flg_status <> g_adt_req_open
        THEN
            l_error_message := pk_message.get_message(i_lang, 'AUDIT_ERR031');
            RAISE l_common_error;
        END IF;
    
        g_error := 'CLEAN DUPS';
        --duplicados
        SELECT COUNT(0)
          INTO l_count
          FROM audit_criteria aq
         WHERE aq.id_audit_criteria IN (SELECT *
                                          FROM TABLE(i_ids_criterias))
           AND aq.flg_for = g_adt_quest_for_epis
           AND aq.id_audit_type = l_audit_type;
    
        --filtrar arrays
        IF i_ids_criterias.count <> i_answers.count
        THEN
            --número de perguntas e respostas diferente
            g_error := 'NUM ANS DIF NUM QUESTS';
            RAISE l_internal_error;
        ELSIF l_count <> i_ids_criterias.count
        THEN
            --ids de perguntas inválidos ou repetidos
            g_error := 'DUP\INVALID QUEST ID ';
            RAISE l_internal_error;
        END IF;
        --inserir respostas
        g_error := 'LOOP ANSWERS';
        FOR idx IN 1 .. i_ids_criterias.count
        LOOP
            --ler resposta anterior, para actualizar
            g_error := 'OPEN C_ANSWERS(' || idx || ')';
            OPEN c_answers(i_ids_criterias(idx));
            FETCH c_answers
                INTO l_quest_ans_id, l_quest_ans_tp, l_quest_editable, l_last_ans;
            l_found := c_answers%NOTFOUND;
            CLOSE c_answers;
        
            l_answer := i_answers(idx);
            --filtrar booleanos
            IF l_quest_editable = 'N'
               OR l_answer = l_last_ans
            THEN
                l_answer := NULL;
            ELSIF l_quest_ans_tp = g_adt_quest_tp_bool
                  AND l_answer IS NOT NULL
                  AND l_answer <> g_yes
                  AND l_answer <> g_no
            THEN
                g_error := 'INVALID BOOL VALUE (''' || l_answer || ''')';
                RAISE l_internal_error;
            END IF;
        
            IF l_found
            --resposta nova
            THEN
                g_error := 'INSERT ANSWER (' || i_audit_req_prof_epis || ',' || i_ids_criterias(idx) || ')';
                INSERT INTO audit_quest_answer
                    (id_audit_quest_answer,
                     id_audit_criteria,
                     id_professional,
                     id_audit_req_prof_epis,
                     dt_answer_tstz,
                     answer)
                VALUES
                    (seq_audit_quest_answer.nextval,
                     i_ids_criterias(idx),
                     i_prof.id,
                     i_audit_req_prof_epis,
                     g_sysdate_tstz,
                     l_answer)
                RETURNING id_audit_quest_answer INTO l_quest_ans_id;
            ELSIF l_quest_editable != g_no
            THEN
                --resposta existente - actualizar
                g_error := 'UPDATE ANSWER (' || i_audit_req_prof_epis || ',' || i_ids_criterias(idx) || ')';
                UPDATE audit_quest_answer
                   SET id_professional = i_prof.id, dt_answer_tstz = g_sysdate_tstz, answer = nvl(l_answer, answer)
                 WHERE id_audit_quest_answer = l_quest_ans_id;
            END IF;
        
            IF i_notes IS NOT NULL
               AND i_notes.count >= idx
               AND i_notes(idx) IS NOT NULL
               AND length(TRIM(i_notes(idx))) > 0
            THEN
                l_notes := i_notes(idx);
            ELSE
                l_notes := NULL;
            END IF;
            --inserir notas da pergunta
        
            IF l_notes IS NOT NULL
               OR l_answer IS NOT NULL
            THEN
                g_error := 'INSERT COMMENT QUEST';
                INSERT INTO audit_req_comment
                    (id_audit_req_comment,
                     id_professional,
                     id_audit_quest_answer,
                     flg_status,
                     dt_saved_tstz,
                     t_comment,
                     answer)
                VALUES
                    (seq_audit_req_comment.nextval,
                     i_prof.id,
                     l_quest_ans_id,
                     g_adt_req_cmt_flg_norm,
                     g_sysdate_tstz,
                     l_notes,
                     l_answer);
            END IF;
        
        END LOOP;
    
        OPEN c_comment;
        FETCH c_comment
            INTO l_last_comment;
        CLOSE c_comment;
    
        IF i_comment IS NOT NULL
           AND length(TRIM(i_comment)) > 0
           AND (l_last_comment != i_comment OR l_last_comment IS NULL)
        --inserir comentário sobre o episódio
        THEN
            g_error := 'INSERT COMMENT EPIS';
            INSERT INTO audit_req_comment
                (id_audit_req_comment, id_professional, id_audit_req_prof_epis, flg_status, dt_saved_tstz, t_comment)
            VALUES
                (seq_audit_req_comment.nextval,
                 i_prof.id,
                 i_audit_req_prof_epis,
                 g_adt_req_cmt_flg_norm,
                 g_sysdate_tstz,
                 i_comment);
        
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_common_error THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   'SET_QUEST_ANSWER_EPIS',
                                   NULL,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes; -- ROLLBACK
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_INTERNAL_ERROR',
                                              'INVALID DATA',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_QUEST_ANSWER_EPIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_QUEST_ANSWER_EPIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_quest_answer_epis;

    FUNCTION get_epis_compl
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_episode          episode.id_episode%TYPE,
        o_title_epis_compl OUT VARCHAR2,
        o_epis_compl       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
    
    BEGIN
        BEGIN
            g_error := 'GET DIAG';
            SELECT t.desc_diagnosis
              INTO o_epis_compl
              FROM (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis
                      FROM diagnosis d, epis_diagnosis ed, alert_diagnosis ad
                     WHERE ed.id_episode = i_episode
                       AND ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND ed.flg_type = 'P'
                       AND ed.flg_status IN ('F', 'D')
                     ORDER BY ed.dt_epis_diagnosis_tstz, ed.dt_confirmed_tstz DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF o_epis_compl IS NOT NULL
        THEN
            o_title_epis_compl := pk_message.get_message(i_lang, 'DIAGNOSIS_FINAL_T023');
        ELSE
            o_title_epis_compl := pk_message.get_message(i_lang, 'TRIAGE_T002');
        
            g_error := 'GET EMERGENCY COMPLAINT';
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
            CLOSE l_cur_epis_complaint;
        
            o_epis_compl := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                 i_prof,
                                                                 l_row_epis_complaint.desc_complaint,
                                                                 l_row_epis_complaint.patient_complaint);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_EPIS_COMPL',
                                              o_error);
            RETURN FALSE;
    END get_epis_compl;

    FUNCTION get_header
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_audit_req           audit_req.id_audit_req%TYPE,
        i_audit_req_prof      audit_req_prof.id_audit_req_prof%TYPE,
        i_audit_req_prof_epis audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        o_prof_photo     OUT VARCHAR2,
        o_prof_name      OUT VARCHAR2,
        o_prof_nick_name OUT VARCHAR2,
        o_prof_spec      OUT VARCHAR2,
        o_prof_inst      OUT VARCHAR2,
        o_prof_inst_abbr OUT VARCHAR2,
        
        o_audit_type        OUT VARCHAR2,
        o_title_period      OUT VARCHAR2,
        o_title_desc_period OUT VARCHAR2,
        o_period_begin      OUT VARCHAR2,
        o_period_end        OUT VARCHAR2,
        
        o_adt_prof_name   OUT VARCHAR2,
        o_adt_prof_photo  OUT VARCHAR2,
        o_adt_prof_gender OUT patient.gender%TYPE,
        o_adt_prof_age    OUT NUMBER,
        
        o_title_pat_name OUT VARCHAR2,
        o_pat_name       OUT VARCHAR2,
        
        o_title_epis_anamnesis OUT VARCHAR2,
        o_epis_anamnesis       OUT VARCHAR2,
        
        o_title_id_epis_ext_sys OUT VARCHAR2,
        o_id_epis_ext_sys       OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis episode.id_episode%TYPE;
        l_ext_sys external_sys.id_external_sys%TYPE;
    
        l_prof profissional := profissional(i_prof.id, i_prof.institution, g_soft_edis);
    BEGIN
        g_error      := 'GET_PROF_PHOTO 1';
        o_prof_photo := pk_profphoto.get_prof_photo(l_prof);
        g_error      := 'GET PROF INFO';
        SELECT -- Since this is the header function, don't use the names/specialty API
         p.name,
         p.nick_name,
         pk_translation.get_translation_dtchk(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality),
         --
         '(' || pk_translation.get_translation(i_lang, i.code_institution) || ')',
         i.abbreviation
          INTO o_prof_name, o_prof_nick_name, o_prof_spec, o_prof_inst, o_prof_inst_abbr
          FROM institution i, professional p
         WHERE i.id_institution = l_prof.institution
           AND p.id_professional = l_prof.id;
    
        IF i_audit_req IS NOT NULL
        THEN
            g_error             := 'GET AUDIT INFO';
            o_title_period      := pk_message.get_message(i_lang, 'AUDIT_GRID_T001');
            o_title_desc_period := pk_message.get_message(i_lang, 'AUDIT_GRID_T048');
            SELECT pk_translation.get_translation(i_lang, t.code_audit_type),
                   pk_date_utils.date_send_tsz(i_lang, a.dt_begin_tstz, i_prof),
                   pk_date_utils.date_send_tsz(i_lang, a.dt_end_tstz, i_prof)
              INTO o_audit_type, o_period_begin, o_period_end
              FROM audit_req a, audit_type t
             WHERE a.id_audit_req = i_audit_req
               AND t.id_audit_type = a.id_audit_type;
        
            SELECT pk_utils.concat_table(CAST(COLLECT(p.name) AS table_varchar), '; ')
              INTO o_prof_name
              FROM audit_req_prof a, professional p
             WHERE a.id_audit_req = i_audit_req
               AND a.flg_rel_type = g_adt_req_prf_rel_auditor
               AND p.id_professional = a.id_professional;
        
            IF i_audit_req_prof IS NOT NULL
            THEN
                g_error := 'GET AUDIT PROF INFO';
                SELECT p.name,
                       pk_profphoto.get_prof_photo(profissional(a.id_professional, l_prof.institution, l_prof.software)),
                       decode(p.gender, 'F', 'F', 'M', 'M', NULL),
                       floor(months_between(SYSDATE, p.dt_birth) / 12)
                  INTO o_adt_prof_name, o_adt_prof_photo, o_adt_prof_gender, o_adt_prof_age
                  FROM audit_req_prof a, professional p
                 WHERE a.id_audit_req_prof = i_audit_req_prof
                   AND p.id_professional = a.id_professional;
            
                IF i_audit_req_prof_epis IS NOT NULL
                THEN
                    o_title_pat_name        := pk_message.get_message(i_lang, 'AUDIT_GRID_T018');
                    o_title_id_epis_ext_sys := pk_message.get_message(i_lang, 'COMMON_M026');
                
                    l_ext_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', l_prof);
                    g_error   := 'GET AUDIT EPIS INFO';
                    SELECT (SELECT p.name
                              FROM patient p
                             WHERE p.id_patient = v.id_patient),
                           nvl((SELECT s.value
                                 FROM epis_ext_sys s
                                WHERE s.id_episode = e.id_episode
                                  AND s.id_external_sys = l_ext_sys
                                  AND s.id_institution = v.id_institution),
                               '---'),
                           e.id_episode
                      INTO o_pat_name, o_id_epis_ext_sys, l_id_epis
                      FROM audit_req_prof_epis a, epis_triage t, episode e, visit v
                     WHERE a.id_audit_req_prof_epis = i_audit_req_prof_epis
                       AND t.id_epis_triage = a.id_epis_triage
                       AND e.id_episode = t.id_episode
                       AND v.id_visit = e.id_visit;
                
                    IF NOT get_epis_compl(i_lang, l_prof, l_id_epis, o_title_epis_anamnesis, o_epis_anamnesis, o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HEADER',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_header;

    -- Not being used
    FUNCTION test_complex_cursor
    (
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_complex_object AS OBJECT(txt VARCHAR2(4000), num number)';
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE tbl_complex_object AS TABLE OF t_complex_object';
        OPEN o_cursor FOR 'SELECT CAST(MULTISET (SELECT ''hello ''||column_value question, column_value answer FROM table(table_number(1,2))) AS tbl_complex_object) FROM table(table_number(1,2))';
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END test_complex_cursor;

    FUNCTION check_can_create
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_count        PLS_INTEGER;
        l_many_allowed BOOLEAN;
    BEGIN
    
        l_many_allowed := get_mult_open_adt_allowed(i_prof);
    
        IF NOT l_many_allowed
        THEN
            g_error := 'COUNT AUDITS';
            SELECT COUNT(0)
              INTO l_count
              FROM audit_req
             WHERE flg_status = g_adt_req_open
               AND id_institution = i_prof.institution;
        ELSE
            l_count := 0;
        END IF;
    
        IF l_count > 0
        THEN
            RETURN 'N';
        ELSE
            RETURN 'Y';
        END IF;
    END;

    /******************************************************************************
    * Returns the IDs of the reports that depend on ID_AUDIT_REQ, 
    * ID_AUDIT_REQ_PROF_EPIS and ID_AUDIT_REQ_PROF.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_reports         Report IDs that depend on ID_AUDIT_REQ
    * @param o_reports_audit   Report IDs that depend on ID_AUDIT_REQ_PROF
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-11-25
    *
    ******************************************************************************/
    FUNCTION get_audit_reports
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_reports       OUT pk_types.cursor_type,
        o_reports_audit OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- Reports depending on ID_AUDIT_REQ
        g_error := 'GET ID_REPORTS';
        OPEN o_reports FOR
            SELECT r.id_reports
              FROM reports r
             WHERE r.flg_context_column = 'ID_AUDIT_REQ';
    
        -- Reports depending on ID_AUDIT_REQ_PROF
        g_error := 'GET ID_REPORTS';
        OPEN o_reports_audit FOR
            SELECT r.id_reports
              FROM reports r
             WHERE r.flg_context_column = 'ID_AUDIT_REQ_PROF';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_AUDIT_REPORTS',
                                              o_error);
            pk_types.open_my_cursor(o_reports);
            pk_types.open_my_cursor(o_reports_audit);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_audit_reports;

BEGIN

    g_owner        := 'ALERT';
    g_package_name := pk_alertlog.who_am_i;

    pk_alertlog.who_am_i(g_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_triage_audit;
/
