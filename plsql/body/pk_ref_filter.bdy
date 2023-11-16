/*-- Last Change Revision: $Rev: 1974697 $*/
/*-- Last Change by: $Author: anna.kurowska $*/
/*-- Date of last change: $Date: 2020-12-21 12:45:25 +0000 (seg, 21 dez 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_filter IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Gets mapping contexts in referral grids 
    * Used by filters
    *
    * @param i_context_ids      Predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals     All remaining contexts array(configurable with bind variable definition)
    * @param i_name             Variable name
    * @param o_vc2              Output variable type varchar2
    * @param o_num              Output variable type NUMBER
    * @param o_id               Output variable type Id
    * @param o_tstz             Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    PROCEDURE init_params_ref
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
        g_search_pat_name  CONSTANT NUMBER(24) := 7;
    
        l_prof            profissional;
        l_lang            language.id_language%TYPE;
        l_patient         patient.id_patient%TYPE;
        l_episode         episode.id_episode%TYPE;
        l_search_pat_name VARCHAR2(1000 CHAR);
    BEGIN
    
        -- log
        /*IF i_context_vals IS NULL
        THEN
            pk_alertlog.log_error('i_context_ids.count=' || i_context_ids.count || ' i_context_vals IS NULL');
        ELSE
            pk_alertlog.log_error('i_context_ids.count=' || i_context_ids.count || ' i_context_vals.count=' ||
                                  i_context_vals.count);
        END IF;
        
        FOR i IN 1 .. i_context_ids.count
        LOOP
            pk_alertlog.log_error('i_context_ids(' || i || ')=' || i_context_ids(i));
        END LOOP;
        
        IF i_context_vals IS NOT NULL
        THEN
            FOR i IN 1 .. i_context_vals.count
            LOOP
                pk_alertlog.log_error('i_context_vals(' || i || ')=' || i_context_vals(i));
            END LOOP;
        END IF;*/
    
        l_prof    := profissional(i_context_ids(g_prof_id),
                                  i_context_ids(g_prof_institution),
                                  i_context_ids(g_prof_software));
        l_lang    := i_context_ids(g_lang);
        l_patient := i_context_ids(g_patient);
        l_episode := i_context_ids(g_episode);
    
        g_error := 'i_name=' || i_name;
        IF i_context_vals IS NULL
        THEN
            l_search_pat_name := '';
        
        ELSIF i_context_vals.count > 0
              AND i_context_vals.exists(g_search_pat_name)
        THEN
            l_search_pat_name := i_context_vals(g_search_pat_name);
        ELSE
            l_search_pat_name := '';
        END IF;
    
        g_error := 'i_name=' || i_name || ' l_search_pat_name=' || l_search_pat_name;
        CASE i_name
        
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'i_prof_flg_cat' THEN
                o_vc2 := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_id_cat' THEN
                o_id := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_prof_templ' THEN
                o_id := pk_prof_utils.get_prof_profile_template(l_prof);
            
            WHEN 'g_cat_id_adm' THEN
                o_id := pk_ref_constant.g_cat_id_adm;
            
            WHEN 'g_profile_adm_hs_vo' THEN
                o_id := pk_ref_constant.g_profile_adm_hs_vo;
            
            WHEN 'g_current_timestamp' THEN
                o_tstz := current_timestamp;
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_ref_constant.g_yes;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_ref_constant.g_no;
            
            WHEN 'g_active' THEN
                o_vc2 := pk_ref_constant.g_active;
            
            WHEN 'g_inst_market' THEN
                o_id := pk_utils.get_institution_market(i_lang => l_lang, i_id_institution => l_prof.institution);
            
            WHEN 'g_status_selected' THEN
                o_vc2 := pk_ref_constant.g_status_selected;
            
            WHEN 'g_sm_common_t003' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, pk_ref_constant.g_sm_common_t003);
            
            WHEN 'g_sm_common_m20' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, pk_ref_constant.g_sm_common_m20);
            
            WHEN 'g_sm_common_m19' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, pk_ref_constant.g_sm_common_m19);
            
            WHEN 'g_sm_ref_devstatus_notes' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, pk_ref_constant.g_sm_ref_devstatus_notes);
            
            WHEN 'l_doc_can_receive' THEN
                o_vc2 := pk_doc.get_config('DOC_CAN_RECEIVE',
                                           l_prof,
                                           pk_prof_utils.get_prof_profile_template(l_prof),
                                           NULL);
            
            WHEN 'l_img_receive_ko' THEN
                o_vc2 := pk_sysdomain.get_img(l_lang, 'DOC_EXTERNAL.FLG_RECEIVED', pk_ref_constant.g_no);
            
            WHEN 'l_img_receive_ok' THEN
                o_vc2 := pk_sysdomain.get_img(l_lang, 'DOC_EXTERNAL.FLG_RECEIVED', pk_ref_constant.g_yes);
            
            WHEN 'g_wf_hosp_hosp' THEN
                o_id := pk_ref_constant.g_wf_hosp_hosp;
            
            WHEN 'g_wf_pcc_hosp' THEN
                o_id := pk_ref_constant.g_wf_pcc_hosp;
            
            WHEN 'g_wf_x_hosp' THEN
                o_id := pk_ref_constant.g_wf_x_hosp;
            
            WHEN 'g_wf_srv_srv' THEN
                o_id := pk_ref_constant.g_wf_srv_srv;
            
            WHEN 'g_wf_ref_but' THEN
                o_id := pk_ref_constant.g_wf_ref_but;
            
            WHEN 'g_wf_cc' THEN
                o_id := pk_ref_constant.g_wf_cc;
            
            WHEN 'g_p1_status_o' THEN
                o_vc2 := pk_ref_constant.g_p1_status_o;
            
            WHEN 'g_p1_status_n' THEN
                o_vc2 := pk_ref_constant.g_p1_status_n;
            
            WHEN 'g_p1_status_i' THEN
                o_vc2 := pk_ref_constant.g_p1_status_i;
            
            WHEN 'g_p1_status_b' THEN
                o_vc2 := pk_ref_constant.g_p1_status_b;
            
            WHEN 'g_p1_status_t' THEN
                o_vc2 := pk_ref_constant.g_p1_status_t;
            
            WHEN 'g_p1_status_r' THEN
                o_vc2 := pk_ref_constant.g_p1_status_r;
            
            WHEN 'g_p1_status_a' THEN
                o_vc2 := pk_ref_constant.g_p1_status_a;
            
            WHEN 'g_p1_status_d' THEN
                o_vc2 := pk_ref_constant.g_p1_status_d;
            
            WHEN 'g_p1_status_e' THEN
                o_vc2 := pk_ref_constant.g_p1_status_e;
            
            WHEN 'g_p1_status_f' THEN
                o_vc2 := pk_ref_constant.g_p1_status_f;
            
            WHEN 'g_p1_status_v' THEN
                o_vc2 := pk_ref_constant.g_p1_status_v;
            
            WHEN 'g_p1_status_y' THEN
                o_vc2 := pk_ref_constant.g_p1_status_y;
            
            WHEN 'g_p1_status_x' THEN
                o_vc2 := pk_ref_constant.g_p1_status_x;
            
            WHEN 'g_p1_status_s' THEN
                o_vc2 := pk_ref_constant.g_p1_status_s;
            
            WHEN 'g_p1_status_m' THEN
                o_vc2 := pk_ref_constant.g_p1_status_m;
            
            WHEN 'g_p1_status_q' THEN
                o_vc2 := pk_ref_constant.g_p1_status_q;
            
            WHEN 'g_p1_status_k' THEN
                o_vc2 := pk_ref_constant.g_p1_status_k;
            
            WHEN 'g_p1_status_w' THEN
                o_vc2 := pk_ref_constant.g_p1_status_w;
            
            WHEN 'g_p1_status_c' THEN
                o_vc2 := pk_ref_constant.g_p1_status_c;
            
            WHEN 'g_p1_status_l' THEN
                o_vc2 := pk_ref_constant.g_p1_status_l;
            
            WHEN 'g_p1_status_z' THEN
                o_vc2 := pk_ref_constant.g_p1_status_z;
            
            WHEN 'g_p1_status_j' THEN
                o_vc2 := pk_ref_constant.g_p1_status_j;
            
            WHEN 'g_p1_status_h' THEN
                o_vc2 := pk_ref_constant.g_p1_status_h;
            
            WHEN 'g_p1_type_c' THEN
                o_vc2 := pk_ref_constant.g_p1_type_c;
            
            WHEN 'g_tracking_type_r' THEN
                o_vc2 := pk_ref_constant.g_tracking_type_r;
            
            WHEN 'g_tracking_type_p' THEN
                o_vc2 := pk_ref_constant.g_tracking_type_p;
            
            WHEN 'g_tracking_type_c' THEN
                o_vc2 := pk_ref_constant.g_tracking_type_c;
            
            WHEN 'g_tracking_type_s' THEN
                o_vc2 := pk_ref_constant.g_tracking_type_s;
            
            WHEN 'g_adm_required' THEN
                o_vc2 := pk_ref_constant.g_adm_required;
            
            WHEN 'g_adm_required_match' THEN
                o_vc2 := pk_ref_constant.g_adm_required_match;
            
            WHEN 'g_location_grid' THEN
                o_vc2 := pk_ref_constant.g_location_grid;
            
            WHEN 'g_func_d' THEN
                o_id := pk_ref_constant.g_func_d;
            
            WHEN 'g_func_t' THEN
                o_id := pk_ref_constant.g_func_t;
            
            WHEN 'g_func_c' THEN
                o_id := pk_ref_constant.g_func_c;
            
            WHEN 'dt_missed_limit' THEN
                o_tstz := trunc(current_timestamp) -
                          to_number(nvl(pk_sysconfig.get_config('REF_FILTER_MISSED_LIMIT', l_prof), 0));
            
            WHEN 'dt_schedule_limit' THEN
                o_tstz := trunc(current_timestamp) -
                          to_number(nvl(pk_sysconfig.get_config('REF_FILTER_SCHEDULED_LIMIT', l_prof), 0));
            
            WHEN 'dt_refused_limit' THEN
                o_tstz := trunc(current_timestamp) -
                          to_number(nvl(pk_sysconfig.get_config('REF_FILTER_REFUSED_X_LIMIT', l_prof), 0));
            
            WHEN 'dt_status_today' THEN
                o_tstz := trunc(current_timestamp) - INTERVAL '1' DAY; -- todo: retirar
        
            WHEN 'dt_yesterday' THEN
                o_tstz := trunc(current_timestamp) - INTERVAL '1' DAY;
            
            WHEN 'dt_5_days_ago' THEN
                o_tstz := trunc(current_timestamp) - INTERVAL '5' DAY;
            
            WHEN 'dt_1_day_after' THEN
                o_tstz := trunc(current_timestamp) + INTERVAL '1' DAY;
            
            WHEN 'dt_today' THEN
                o_tstz := trunc(current_timestamp);
            
            WHEN 'search_pat_name' THEN
                o_vc2 := l_search_pat_name;
            
            WHEN 'prof_clin_dir' THEN
                -- check if this professional is clinical director in this institution
                o_vc2 := pk_ref_core.validate_clin_dir(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'g_ref_prio' THEN
                o_vc2 := pk_ref_constant.g_ref_prio;
            
        END CASE;
    
    END init_params_ref;

    /**
    * Gets mapping contexts in referral handoff grids 
    * Used by filters
    *
    * @param i_context_ids      Predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals     All remaining contexts array(configurable with bind variable definition)
    * @param i_name             Variable name
    * @param o_vc2              Output variable type varchar2
    * @param o_num              Output variable type NUMBER
    * @param o_id               Output variable type Id
    * @param o_tstz             Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-05-2013
    */
    PROCEDURE init_params_handoff
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        g_search_pat_name     CONSTANT NUMBER(24) := 7;
        g_search_pat_gender   CONSTANT NUMBER(24) := 8;
        g_search_pat_dt_birth CONSTANT NUMBER(24) := 9;
        g_search_pat_sns      CONSTANT NUMBER(24) := 10;
        g_search_prof_req     CONSTANT NUMBER(24) := 11;
        g_search_flg_type     CONSTANT NUMBER(24) := 12;
        g_search_id_ref       CONSTANT NUMBER(24) := 13;
        g_search_flg_status   CONSTANT NUMBER(24) := 14;
        g_search_tr_id_sts    CONSTANT NUMBER(24) := 15;
        g_search_tr_id_prof_d CONSTANT NUMBER(24) := 16;
    
        l_prof                profissional;
        l_lang                language.id_language%TYPE;
        l_patient             patient.id_patient%TYPE;
        l_episode             episode.id_episode%TYPE;
        l_search_pat_name     VARCHAR2(1000 CHAR);
        l_search_pat_gender   VARCHAR2(1000 CHAR);
        l_search_pat_dt_birth VARCHAR2(1000 CHAR);
        l_search_pat_sns      VARCHAR2(1000 CHAR);
        l_search_prof_req     VARCHAR2(1000 CHAR);
        l_search_flg_type     VARCHAR2(1000 CHAR);
        l_search_id_ref       VARCHAR2(1000 CHAR);
        l_search_flg_status   VARCHAR2(1000 CHAR);
        l_search_tr_id_sts    VARCHAR2(1000 CHAR);
        l_search_tr_id_prof_d VARCHAR2(1000 CHAR);
    BEGIN
    
        /*-- log
        IF i_context_vals IS NULL
        THEN
            pk_alertlog.log_error('i_context_ids.count=' || i_context_ids.count || ' i_context_vals IS NULL');
        ELSE
            pk_alertlog.log_error('i_context_ids.count=' || i_context_ids.count || ' i_context_vals.count=' ||
                                  i_context_vals.count);
        END IF;
        
        FOR i IN 1 .. i_context_ids.count
        LOOP
            pk_alertlog.log_error('i_context_ids(' || i || ')=' || i_context_ids(i));
        END LOOP;
        
        IF i_context_vals IS NOT NULL
        THEN
            FOR i IN 1 .. i_context_vals.count
            LOOP
                pk_alertlog.log_error('i_context_vals(' || i || ')=' || i_context_vals(i));
            END LOOP;
        END IF;*/
    
        l_prof    := profissional(i_context_ids(g_prof_id),
                                  i_context_ids(g_prof_institution),
                                  i_context_ids(g_prof_software));
        l_lang    := i_context_ids(g_lang);
        l_patient := i_context_ids(g_patient);
        l_episode := i_context_ids(g_episode);
    
        g_error := 'i_context_vals / i_name=' || i_name;
        IF i_context_vals IS NULL
        THEN
            l_search_pat_name := '';
        
        ELSIF i_context_vals.count > 0
        THEN
        
            -- g_search_pat_name
            IF i_context_vals.exists(g_search_pat_name)
            THEN
                l_search_pat_name := i_context_vals(g_search_pat_name);
            END IF;
        
            -- g_search_pat_gender
            IF i_context_vals.exists(g_search_pat_gender)
            THEN
                l_search_pat_gender := i_context_vals(g_search_pat_gender);
            END IF;
        
            -- g_search_pat_dt_birth
            IF i_context_vals.exists(g_search_pat_dt_birth)
            THEN
                l_search_pat_dt_birth := i_context_vals(g_search_pat_dt_birth);
            END IF;
        
            -- g_search_pat_sns
            IF i_context_vals.exists(g_search_pat_sns)
            THEN
                l_search_pat_sns := i_context_vals(g_search_pat_sns);
            END IF;
        
            -- g_search_prof_req
            IF i_context_vals.exists(g_search_prof_req)
            THEN
                l_search_prof_req := i_context_vals(g_search_prof_req);
            END IF;
        
            -- g_search_flg_type
            IF i_context_vals.exists(g_search_flg_type)
            THEN
                l_search_flg_type := i_context_vals(g_search_flg_type);
            END IF;
        
            -- g_search_id_ref
            IF i_context_vals.exists(g_search_id_ref)
            THEN
                l_search_id_ref := i_context_vals(g_search_id_ref);
            END IF;
        
            -- g_search_flg_status
            IF i_context_vals.exists(g_search_flg_status)
            THEN
                l_search_flg_status := i_context_vals(g_search_flg_status);
            END IF;
        
            -- g_search_tr_id_sts
            IF i_context_vals.exists(g_search_tr_id_sts)
            THEN
                l_search_tr_id_sts := i_context_vals(g_search_tr_id_sts);
            END IF;
        
            -- g_search_tr_id_prof_d
            IF i_context_vals.exists(g_search_tr_id_prof_d)
            THEN
                l_search_tr_id_prof_d := i_context_vals(g_search_tr_id_prof_d);
            END IF;
        
        END IF;
    
        g_error := 'i_name=' || i_name || ' l_search_pat_name=' || l_search_pat_name || ' l_search_pat_gender=' ||
                   l_search_pat_gender || ' l_search_pat_dt_birth=' || l_search_pat_dt_birth || ' l_search_pat_sns=' ||
                   l_search_pat_sns || ' l_search_prof_req=' || l_search_prof_req || ' l_search_id_ref=' ||
                   l_search_id_ref || ' l_search_flg_status=' || l_search_flg_status || ' l_search_tr_id_sts=' ||
                   l_search_tr_id_sts || ' l_search_tr_id_prof_d=' || l_search_tr_id_prof_d;
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'g_wf_x_hosp' THEN
                o_id := pk_ref_constant.g_wf_x_hosp;
            
            WHEN 'g_wf_srv_srv' THEN
                o_id := pk_ref_constant.g_wf_srv_srv;
            
            WHEN 'g_wf_pcc_hosp' THEN
                o_id := pk_ref_constant.g_wf_pcc_hosp;
            
            WHEN 'i_prof_id_cat' THEN
                o_id := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_prof_templ' THEN
                o_id := pk_prof_utils.get_prof_profile_template(l_prof);
            
            WHEN 'g_location_grid' THEN
                o_vc2 := pk_ref_constant.g_location_grid;
            
            WHEN 'g_sm_common_m20' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, pk_ref_constant.g_sm_common_m20);
            
            WHEN 'g_sm_common_m19' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, pk_ref_constant.g_sm_common_m19);
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_ref_constant.g_yes;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_ref_constant.g_no;
            
            WHEN 'g_institution_code' THEN
                o_vc2 := pk_ref_constant.g_institution_code;
            
            WHEN 'g_active' THEN
                o_vc2 := pk_ref_constant.g_active;
            
            WHEN 'g_p1_status_k' THEN
                o_vc2 := pk_ref_constant.g_p1_status_k;
            
            WHEN 'g_p1_status_c' THEN
                o_vc2 := pk_ref_constant.g_p1_status_c;
            
            WHEN 'g_tr_status_pend_app' THEN
                o_vc2 := pk_ref_constant.g_tr_status_pend_app;
            
            WHEN 'g_tr_status_approved' THEN
                o_vc2 := pk_ref_constant.g_tr_status_approved;
            
            WHEN 'g_tr_status_declined' THEN
                o_vc2 := pk_ref_constant.g_tr_status_declined;
            
            WHEN 'g_tr_status_cancelled' THEN
                o_vc2 := pk_ref_constant.g_tr_status_cancelled;
            
            WHEN 'g_tr_status_inst_app' THEN
                o_vc2 := pk_ref_constant.g_tr_status_inst_app;
            
            WHEN 'g_tr_status_declined_inst' THEN
                o_vc2 := pk_ref_constant.g_tr_status_declined_inst;
            
            WHEN 'g_id_health_plan' THEN
                o_id := pk_ref_utils.get_default_health_plan(i_prof => l_prof);
            
            WHEN 'g_current_timestamp' THEN
                o_tstz := current_timestamp;
            
            WHEN 'g_wf_transfresp' THEN
                o_id := pk_ref_constant.g_wf_transfresp;
            
            WHEN 'g_wf_transfresp_inst' THEN
                o_id := pk_ref_constant.g_wf_transfresp_inst;
            
        -- searching criterias
            WHEN 'search_pat_name' THEN
                o_vc2 := l_search_pat_name;
            
            WHEN 'search_pat_gender' THEN
                o_vc2 := l_search_pat_gender;
            
            WHEN 'search_pat_dt_birth' THEN
                o_vc2 := l_search_pat_dt_birth;
            
            WHEN 'search_pat_sns' THEN
                o_vc2 := l_search_pat_sns;
            
            WHEN 'search_prof_req' THEN
                o_vc2 := l_search_prof_req; -- list of professional ids
        
            WHEN 'search_flg_type' THEN
                o_vc2 := l_search_flg_type; -- list of referral types
        
            WHEN 'search_id_ref' THEN
                o_id := l_search_id_ref; -- a referral identifier
        
            WHEN 'search_flg_status' THEN
                o_vc2 := l_search_flg_status; -- list of referral status
        
            WHEN 'search_tr_id_sts' THEN
                o_vc2 := l_search_tr_id_sts; -- list of referral handoff status identifiers
        
            WHEN 'search_tr_id_prof_d' THEN
                o_vc2 := l_search_tr_id_prof_d; -- list of referral handoff dest professional identifiers                         
        
            WHEN 'g_ref_prio' THEN
                o_vc2 := pk_ref_constant.g_ref_prio;
            
        END CASE;
    
    END init_params_handoff;

    /**
    * Gets mapping contexts in referral origin institution list
    * Used by filters
    *
    * @param i_context_ids      Predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals     All remaining contexts array(configurable with bind variable definition)
    * @param i_name             Variable name
    * @param o_vc2              Output variable type varchar2
    * @param o_num              Output variable type NUMBER
    * @param o_id               Output variable type Id
    * @param o_tstz             Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-10-2013
    */
    PROCEDURE init_params_inst_orig_net
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        g_search_inst_name CONSTANT NUMBER(24) := 7;
        g_id_dcs           CONSTANT NUMBER(24) := 8;
        g_id_external_sys  CONSTANT NUMBER(24) := 9;
        g_flg_type         CONSTANT NUMBER(24) := 10;
        g_id_speciality    CONSTANT NUMBER(24) := 11;
    
        l_prof             profissional;
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_search_inst_name pk_translation.t_desc_translation;
        l_id_dcs           p1_external_request.id_dep_clin_serv%TYPE;
        l_id_external_sys  p1_external_request.id_external_sys%TYPE;
        l_flg_type         p1_external_request.flg_type%TYPE;
        l_id_speciality    p1_external_request.id_speciality%TYPE;
    BEGIN
    
        /*-- log
        IF i_context_vals IS NULL
        THEN
            pk_alertlog.log_error('i_context_ids.count=' || i_context_ids.count || ' i_context_vals IS NULL');
        ELSE
            pk_alertlog.log_error('i_context_ids.count=' || i_context_ids.count || ' i_context_vals.count=' ||
                                  i_context_vals.count);
        END IF;
        
        FOR i IN 1 .. i_context_ids.count
        LOOP
            pk_alertlog.log_error('i_context_ids(' || i || ')=' || i_context_ids(i));
        END LOOP;
        
        IF i_context_vals IS NOT NULL
        THEN
            FOR i IN 1 .. i_context_vals.count
            LOOP
                pk_alertlog.log_error('i_context_vals(' || i || ')=' || i_context_vals(i));
            END LOOP;
        END IF;*/
    
        l_prof    := profissional(i_context_ids(g_prof_id),
                                  i_context_ids(g_prof_institution),
                                  i_context_ids(g_prof_software));
        l_lang    := i_context_ids(g_lang);
        l_patient := i_context_ids(g_patient);
        l_episode := i_context_ids(g_episode);
    
        g_error := 'i_context_vals / i_name=' || i_name;
        IF i_context_vals IS NULL
        THEN
            l_search_inst_name := '';
        
        ELSIF i_context_vals.count > 0
        THEN
        
            -- g_search_inst_name
            IF i_context_vals.exists(g_search_inst_name)
            THEN
                l_search_inst_name := i_context_vals(g_search_inst_name);
            END IF;
        
            -- g_id_dcs
            IF i_context_vals.exists(g_id_dcs)
            THEN
                l_id_dcs := i_context_vals(g_id_dcs);
            END IF;
        
            -- g_search_id_external_sys
            IF i_context_vals.exists(g_id_external_sys)
            THEN
                l_id_external_sys := i_context_vals(g_id_external_sys);
            END IF;
        
            -- g_flg_type
            IF i_context_vals.exists(g_flg_type)
            THEN
                l_flg_type := i_context_vals(g_flg_type);
            END IF;
        
            -- g_id_speciality
            IF i_context_vals.exists(g_id_speciality)
            THEN
                l_id_speciality := i_context_vals(g_id_speciality);
            END IF;
        
        END IF;
    
        g_error := 'i_name=' || i_name || ' l_search_inst_name=' || l_search_inst_name || ' l_id_dcs=' || l_id_dcs ||
                   ' l_id_external_sys=' || l_id_external_sys || ' l_flg_type=' || l_flg_type || ' l_id_speciality=' ||
                   l_id_speciality;
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_id_prof', l_prof.id);
        pk_context_api.set_parameter('i_id_institution', l_prof.institution);
        pk_context_api.set_parameter('i_id_software', l_prof.software);
    
        -- referral
        pk_context_api.set_parameter('i_id_dep_clin_serv', l_id_dcs);
        pk_context_api.set_parameter('i_id_external_sys', l_id_external_sys);
        pk_context_api.set_parameter('i_flg_type', l_flg_type);
        pk_context_api.set_parameter('i_id_speciality', l_id_speciality);
    
        -- external institution
        pk_context_api.set_parameter('g_id_ref_external_inst',
                                     pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, l_prof));
        pk_context_api.set_parameter('g_sm_ref_grid_t032', pk_ref_constant.g_sm_ref_grid_t032);
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_ref_constant.g_yes;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_ref_constant.g_no;
            
        -- searching criterias
            WHEN 'search_inst_name' THEN
                o_vc2 := l_search_inst_name;
            
        END CASE;
    
    END init_params_inst_orig_net;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_filter;
/
