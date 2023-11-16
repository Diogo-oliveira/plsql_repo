/*-- Last Change Revision: $Rev: 2027581 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_ext_sys AS

    g_error         VARCHAR2(1000 CHAR);
    g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    --g_rep_action_duplicata CONSTANT reports.flg_action%TYPE := 'D';

    /**
    * Updates referral status
    * Note: This function must not called for features that have several schedules associated to the same referral id
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software    
    * @param   i_ext_req  Referral id              
    * @param   i_status   (S)chedule, (E)fectivation, (M)ailed, appointment (C)anceled  and (F)ailed appointment  
    * @param   i_notes    Notes    
    * @param   i_schedule Schedule identifier   
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION update_referral_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_status         IN p1_external_request.flg_status%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_episode        IN episode.id_episode%TYPE, -- ALERT-27343
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_my_data t_rec_prof_data;
        l_ref_row p1_external_request%ROWTYPE;
        l_action  wf_workflow_action.internal_name%TYPE;
        l_invalid_status EXCEPTION;
        l_exception      EXCEPTION;
        l_sysdate_tstz p1_tracking.dt_tracking_tstz%TYPE;
        l_param        table_varchar;
        o_track        table_number;
    
        -- error codes
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- VAL
        ----------------------        
        g_error := 'Init update_referral_status / ID_REF=' || i_ext_req || ' STATUS ' || i_status || ' ID_SCHEDULE=' ||
                   i_schedule || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'CASE i_status=' || i_status;
        CASE i_status
            WHEN pk_ref_constant.g_p1_status_s THEN
                l_action := pk_ref_constant.g_ref_action_s; -- SCHEDULE
        
            WHEN pk_ref_constant.g_p1_status_m THEN
                l_action := pk_ref_constant.g_ref_action_m; -- MAIL
        
            WHEN pk_ref_constant.g_p1_status_e THEN
                l_action := pk_ref_constant.g_ref_action_e; -- EFFECTIVE
        
            WHEN pk_ref_constant.g_p1_status_a THEN
                l_action := pk_ref_constant.g_ref_action_csh; -- CANCEL_SCH
        
            WHEN pk_ref_constant.g_p1_status_f THEN
                l_action := pk_ref_constant.g_ref_action_f; -- MISSED
        
            ELSE
                RAISE l_exception;
        END CASE;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ID=' || i_prof.id || ' DEP_CLIN_SERV=' ||
                    l_ref_row.id_dep_clin_serv;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Calling init_param_tab / ID_REF=' || l_ref_row.id_external_request;
        l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_ext_req            => l_ref_row.id_external_request,
                                              i_id_patient         => l_ref_row.id_patient,
                                              i_id_inst_orig       => l_ref_row.id_inst_orig,
                                              i_id_inst_dest       => l_ref_row.id_inst_dest,
                                              i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                              i_id_speciality      => l_ref_row.id_speciality,
                                              i_flg_type           => l_ref_row.flg_type,
                                              i_decision_urg_level => l_ref_row.decision_urg_level,
                                              i_id_prof_requested  => l_ref_row.id_prof_requested,
                                              i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                              i_id_prof_status     => l_ref_row.id_prof_status,
                                              i_external_sys       => l_ref_row.id_external_sys,
                                              i_flg_status         => l_ref_row.flg_status);
    
        g_error  := 'Calling pk_ref_core.process_transition';
        g_retval := pk_ref_core.process_transition2(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_prof_data      => l_my_data,
                                                    i_action         => l_action,
                                                    i_status_end     => NULL,
                                                    i_ref_row        => l_ref_row,
                                                    i_date           => l_sysdate_tstz,
                                                    i_notes          => i_notes,
                                                    i_schedule       => i_schedule,
                                                    i_episode        => i_episode, -- ACM, 2009-11-04: ALERT-27343
                                                    i_transaction_id => i_transaction_id,
                                                    io_param         => l_param,
                                                    io_track         => o_track,
                                                    i_reason_code    => i_id_reason_code,
                                                    o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN l_invalid_status THEN
            l_error_code := pk_ref_constant.g_ref_error_1008;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => l_error_code,
                                              i_sqlerrm     => l_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'UPDATE_REFERRAL_STATUS',
                                              i_action_type => pk_ref_constant.g_err_flg_action_u,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
        WHEN l_exception THEN
            DECLARE
                --Initialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(1000 CHAR) := 'Invalid option';
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   l_error_message,
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPDATE_REFERRAL_STATUS',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_REFERRAL_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_referral_status;

    /**
    * Changes request status after schedule cancelation 
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software    
    * @param   i_ext_req  Referral id
    * @param   i_notes    Cancelation notes
    * @param   O_ERROR    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION cancel_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- changing referral status to (A)ccepted, indicating id_prof_dest,id_dep_clin_serv,decision_urg_level and flg_subtype
    
        RETURN update_referral_status(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_ext_req        => i_ext_req,
                                      i_status         => pk_ref_constant.g_p1_status_a,
                                      i_notes          => i_notes,
                                      i_schedule       => NULL,
                                      i_episode        => NULL,
                                      i_id_reason_code => i_id_reason_code,
                                      o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_SCHEDULE',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_schedule;

    /**
    * Gets referral completion options.
    * This function is used when creating one or multiple requests.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_epis          Episode identifier
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type    
    * @param   i_spec          Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   o_options       Referrals completion options
    * @param   o_error         An error message, set when return=false
    *
    * @value   i_flg_type      {*} 'C' Consultation 
    *                          {*} 'A' Lab tests 
    *                          {*} 'I' Imaging exams
    *                          {*} 'E' Other exams
    *                          {*} 'P' Procedure
    *                          {*} 'F' Rehab
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    */
    FUNCTION get_completion_options_new
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        i_codification IN table_number,
        i_inst_dest    IN table_number,
        i_flg_type     IN p1_external_request.flg_type%TYPE,
        i_spec         IN ref_completion_cfg.id_mcdt%TYPE,
        o_options      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_completion_options_new';
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_epis=' || i_epis ||
                    ' i_codification=' || pk_utils.to_string(i_codification) || ' i_inst_dest=' ||
                    pk_utils.to_string(i_inst_dest) || ' i_flg_type=' || i_flg_type || ' i_spec=' || i_spec;
        g_error  := 'Init get_completion_options_new / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        OPEN o_options FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_ref_completion,
             pk_translation.get_translation(i_lang, t.code_ref_completion) ref_completion,
             pk_translation.get_translation(i_lang, t.code_ref_compl_short) ref_compl_short,
             pk_translation.get_translation(i_lang, t.code_warning) ref_compl_warning,
             t.id_reports,
             t.flg_type,
             t.flg_default,
             t.flg_active,
             t.flg_ald,
             t.flg_bdnp
              FROM TABLE(CAST(get_compl_options_tf(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_patient      => i_patient,
                                                   i_epis         => i_epis,
                                                   i_codification => i_codification,
                                                   i_inst_dest    => i_inst_dest,
                                                   i_flg_type     => i_flg_type,
                                                   i_spec         => i_spec) AS t_coll_ref_completion)) t
            -- remove duplicata and reprint options... must appear in report button, but not in completion options pop-up;
             WHERE t.id_ref_completion NOT IN
                   (pk_ref_constant.g_ref_compl_duplicata, pk_ref_constant.g_ref_compl_reprint)
             ORDER BY 2;
    
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
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_completion_options_new;

    /**
    * Gets referral completion options.
    * Used internally
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_flg_type           Referral type    
    * @param   i_spec               Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   i_id_market          Market identifier 
    * @param   i_reports_excep      List of id_reports that will not be considered (exception)
    * @param   i_ref_compl_excep    List of referral completion options identifiers that will not be considered (exception)
    * @param   o_options            Array of completion options available
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_type           {*} 'C' Consultation 
    *                               {*} 'A' Lab tests 
    *                               {*} 'I' Imaging exams
    *                               {*} 'E' Other exams
    *                               {*} 'P' Procedure
    *                               {*} 'F' Rehab
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-10-2014
    */
    FUNCTION get_compl_options_cfg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN p1_external_request.flg_type%TYPE,
        i_spec            IN ref_completion_cfg.id_mcdt%TYPE,
        i_id_market       IN market.id_market%TYPE DEFAULT NULL,
        i_reports_excep   IN table_number DEFAULT table_number(),
        i_ref_compl_excep IN table_number DEFAULT table_number(),
        o_options         OUT t_coll_ref_completion,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_compl_options_cfg';
    
        l_prof_templ         profile_template.id_profile_template%TYPE;
        l_id_market          market.id_market%TYPE;
        l_referral_mcdt_bdnp VARCHAR2(1 CHAR);
    
        TYPE t_ibt_number IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        l_ids_tab t_ibt_number;
    
        l_options t_coll_ref_completion;
    
        CURSOR c_ref_compl
        (
            x_market     market.id_market%TYPE,
            x_prof_templ profile_template.id_profile_template%TYPE,
            x_ref_type   p1_external_request.flg_type%TYPE,
            x_mcdt       ref_completion_cfg.id_mcdt%TYPE
        ) IS
            SELECT t_rec_ref_completion(r.id_ref_completion,
                                        r.code_ref_completion,
                                        r.code_ref_compl_short,
                                        r.code_warning,
                                        rc.id_reports,
                                        r.flg_type,
                                        pk_ref_constant.g_inactive, -- flg_default
                                        pk_ref_constant.g_no, -- flg_active
                                        rc.flg_available,
                                        rc.id_mcdt,
                                        r.flg_ald,
                                        CASE r.id_ref_completion
                                            WHEN pk_ref_constant.g_ref_compl_330_10 THEN
                                             l_referral_mcdt_bdnp
                                            ELSE
                                             pk_ref_constant.g_no
                                        END) --flg_bdnp
              FROM ref_completion r
              JOIN ref_completion_cfg rc
                ON (r.id_ref_completion = rc.id_ref_completion)
             WHERE rc.flg_type_ref = x_ref_type
               AND rc.id_software IN (0, i_prof.software)
               AND rc.id_institution IN (0, i_prof.institution)
               AND rc.id_profile_template IN (0, x_prof_templ)
               AND rc.id_market IN (0, x_market) -- ALERT-273361
               AND NOT EXISTS (SELECT column_value
                      FROM TABLE(i_reports_excep) t
                     WHERE column_value = rc.id_reports) -- must be done with not exists instead of IN (because of null values)
               AND NOT EXISTS
             (SELECT column_value
                      FROM TABLE(i_ref_compl_excep) t
                     WHERE column_value = rc.id_ref_completion) -- must be done with not exists instead of IN (because of null values)
               AND (nvl(rc.id_mcdt, 0) = decode((SELECT COUNT(1)
                                                  FROM ref_completion r
                                                  JOIN ref_completion_cfg rc
                                                    ON (r.id_ref_completion = rc.id_ref_completion)
                                                 WHERE rc.flg_type_ref = x_ref_type
                                                   AND rc.id_software IN (0, i_prof.software)
                                                   AND rc.id_institution IN (0, i_prof.institution)
                                                   AND rc.id_profile_template IN (0, x_prof_templ)
                                                   AND rc.id_market IN (0, x_market) -- ALERT-273361
                                                   AND rc.id_mcdt = x_mcdt),
                                                0,
                                                0,
                                                x_mcdt) OR (rc.id_mcdt IS NULL AND x_mcdt IS NULL))
             ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_flg_type=' || i_flg_type || ' i_spec=' || i_spec ||
                    ' i_reports_excep=' || pk_utils.to_string(i_reports_excep) || ' i_ref_compl_excep=' ||
                    pk_utils.to_string(i_ref_compl_excep);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        o_options   := t_coll_ref_completion();
        l_id_market := nvl(i_id_market,
                           pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution));
    
        l_params := l_params || ' id_market=' || l_id_market;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error              := 'pk_sysconfig.get_config ' || pk_ref_constant.g_ref_external_inst || ' / ' || l_params;
        l_referral_mcdt_bdnp := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                    pk_ref_constant.g_no);
    
        g_error      := 'Calling pk_tools.get_prof_profile_template / ' || l_params;
        l_prof_templ := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        g_error := 'OPEN c_ref_compl(' || l_id_market || ',' || l_prof_templ || ',' || i_flg_type || ',' || i_spec ||
                   ') / ' || l_params;
        OPEN c_ref_compl(x_market     => l_id_market,
                         x_prof_templ => l_prof_templ,
                         x_ref_type   => i_flg_type,
                         x_mcdt       => i_spec);
        FETCH c_ref_compl BULK COLLECT
            INTO l_options;
        CLOSE c_ref_compl;
    
        ---------------------------------------------------------------------------
        -- 1- removing duplicates and flg_available=N from o_options var
        g_error := 'FOR i IN 1 .. ' || l_options.count || ' / ' || l_params;
        FOR i IN 1 .. l_options.count
        LOOP
            -- l_ids_tab is an auxiliar table to mark ID_REF_COMPLETION as "read"
            IF NOT l_ids_tab.exists(l_options(i).id_ref_completion)
               AND l_options(i).flg_available = pk_ref_constant.g_yes
            THEN
                -- valid option to output
                g_error := 'FOR i IN 1 .. ' || l_options.count || ' / ' || l_params;
                o_options.extend;
                o_options(o_options.last) := t_rec_ref_completion();
                o_options(o_options.last) := l_options(i);
            
            END IF;
        
            -- mark as "read"
            l_ids_tab(l_options(i).id_ref_completion) := 1;
        
        END LOOP;
    
        IF o_options.count = 0
        THEN
            g_error := 'No options available / ' || l_params;
            pk_alertlog.log_warn(g_error);
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
    END get_compl_options_cfg;

    /**
    * Gets referral completion options (used internally)
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_patient               Patient identifier   
    * @param   i_epis                  Episode identifier
    * @param   i_codification          Codification identifiers   
    * @param   i_inst_dest             Referrals destination institutions
    * @param   i_flg_type              Referral type    
    * @param   i_spec                  Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   i_reports_excep         List of id_reports that will not be considered (exception)
    * @param   i_ref_compl_excep       List of referral completion options identifiers that will not be considered (exception)
    *
    * @value   i_flg_type              {*} 'C' Consultation 
    *                                  {*} 'A' Lab tests 
    *                                  {*} 'I' Imaging exams
    *                                  {*} 'E' Other exams
    *                                  {*} 'P' Procedure
    *                                  {*} 'F' Rehab
    *
    * @RETURN  t_coll_ref_completion   List of completion options available
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    */
    FUNCTION get_compl_options_tf
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        i_codification    IN table_number,
        i_inst_dest       IN table_number,
        i_flg_type        IN p1_external_request.flg_type%TYPE,
        i_spec            IN ref_completion_cfg.id_mcdt%TYPE,
        i_reports_excep   IN table_number DEFAULT table_number(),
        i_ref_compl_excep IN table_number DEFAULT table_number()
    ) RETURN t_coll_ref_completion IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_compl_options_tf';
        l_electronic  PLS_INTEGER;
        l_print       PLS_INTEGER;
        l_id_market   market.id_market%TYPE;
        l_num_sns     pat_health_plan.num_health_plan%TYPE;
        l_count       PLS_INTEGER;
        l_id_ext_inst institution.id_institution%TYPE;
        --l_ref_compl_p_auto     VARCHAR2(1 CHAR);
        l_print_default_option ref_completion.id_ref_completion%TYPE;
        l_electronic_found     PLS_INTEGER;
        l_print_found          PLS_INTEGER;
        l_error_out            t_error_out;
    
        CURSOR c_standard_type
        (
            x_market   market.id_market%TYPE,
            x_ref_spec p1_external_request.id_speciality%TYPE
        ) IS
            SELECT standard_type
              FROM ref_spec_market
             WHERE id_speciality = x_ref_spec
               AND id_market = x_market;
        l_standard_type c_standard_type%ROWTYPE;
    
        l_ref_completion_tab t_coll_ref_completion := t_coll_ref_completion(); -- to open cursor o_options
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_epis=' || i_epis ||
                    ' i_codification=' || pk_utils.to_string(i_codification) || ' i_inst_dest=' ||
                    pk_utils.to_string(i_inst_dest) || ' i_flg_type=' || i_flg_type || ' i_spec=' || i_spec ||
                    ' i_reports_excep.count=' || i_reports_excep.count || ' i_ref_compl_excep.count=' ||
                    i_ref_compl_excep.count;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- INIT
        ----------------------
        l_electronic_found := 0;
        l_print_found      := 0;
        l_count            := 0;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error       := 'pk_sysconfig.get_config ' || pk_ref_constant.g_ref_external_inst || ' / ' || l_params;
        l_id_ext_inst := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
        --l_ref_compl_p_auto := nvl(pk_sysconfig.get_config('REF_COMPL_P_AUTO', i_prof), pk_ref_constant.g_no); -- configuration removed during printing list development (ALERT-281418)
    
        g_error     := 'Call pk_utils.get_institution_market / ' || l_params;
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        ----------------------
        -- FUNC
        ----------------------
        -- get available completion options from table
        g_error  := 'Call get_compl_options_cfg / ' || l_params;
        g_retval := get_compl_options_cfg(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_flg_type        => i_flg_type,
                                          i_spec            => i_spec,
                                          i_id_market       => l_id_market,
                                          i_reports_excep   => i_reports_excep,
                                          i_ref_compl_excep => i_ref_compl_excep,
                                          o_options         => l_ref_completion_tab,
                                          o_error           => l_error_out);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_completion_tab.count > 0
        THEN
            ---------------------------------------------------------------------------
            -- 1- initializing vars l_x_found
            g_error := 'FOR i IN 1 .. ' || l_ref_completion_tab.count || ' / ' || l_params;
            FOR i IN 1 .. l_ref_completion_tab.count
            LOOP
                CASE l_ref_completion_tab(i).flg_type
                
                    WHEN pk_ref_constant.g_ref_compl_type_e THEN
                        l_electronic_found := 1;
                        -- standard_type checked below (step 4)
                
                    WHEN pk_ref_constant.g_ref_compl_type_p THEN
                        l_print_found := 1;
                        -- standard_type checked below (step 4)
                    ELSE
                        NULL;
                END CASE;
            END LOOP;
        
            ---------------------------------------------------------------------------
            -- 2- checking for electronic options        
            l_electronic := 0;
            IF l_electronic_found = 1
            THEN
            
                IF i_flg_type != pk_ref_constant.g_p1_type_c
                THEN
                    -- a) codification "Convencionado" not allowed for electronic option (only MCDTs have codifications associated)
                    g_error := 'ELECTRONIC validation. a) codification / ' || l_params;
                    l_count := pk_utils.search_table_number(i_table  => i_codification,
                                                            i_search => pk_ref_constant.g_codification_c);
                    IF l_count = -1 -- not found
                    THEN
                        l_electronic := 1;
                    END IF;
                ELSE
                    -- Consultation referral type
                    l_electronic := 1;
                END IF;
            
                -- b) dest institutions must be specified and must accept electronic referrals (the latter was already validated by flash)
                g_error := 'ELECTRONIC validation. b) dest institutions / ' || l_params;
                l_count := pk_utils.search_table_number(i_table => i_inst_dest, i_search => l_id_ext_inst);
            
                IF l_count = -1 -- not found                
                   AND l_electronic = 1
                THEN
                    l_electronic := 1;
                ELSE
                    -- dest institutions not specified
                    l_electronic := 0;
                END IF;
            END IF;
        
            ---------------------------------------------------------------------------
            -- 3- checking for printable options
            g_error := 'PRINT validation: ' || l_electronic || ' / ' || l_params;
            l_print := 0;
            IF l_print_found = 1
            THEN
            
                l_print := 1;
            
                -- getting patient sns
                g_error  := 'Calling pk_ref_core.get_pat_sns / ' || l_params;
                g_retval := pk_ref_core.get_pat_sns(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    i_epis    => i_epis,
                                                    i_active  => pk_ref_constant.g_yes,
                                                    o_num_sns => l_num_sns,
                                                    o_error   => l_error_out);
            
            END IF;
        
            -- log
            FOR i IN 1 .. l_ref_completion_tab.count
            LOOP
                g_error := 'OPTIONS [ELECTRONIC=' || l_electronic || '|PRINT=' || l_print || ' / ID_PAT=' || i_patient ||
                           ' NUM_SNS=' || l_num_sns || ' ID_REF_COMPL=' || l_ref_completion_tab(i).id_ref_completion ||
                           ' FLG_TYPE=' || l_ref_completion_tab(i).flg_type;
                pk_alertlog.log_debug(g_error);
            END LOOP;
        
            ---------------------------------------------------------------------------
            -- 4- setting flg_available and flg_default for each option in l_ref_compl_tab
        
            g_error := 'IF i_flg_type = pk_ref_constant.g_p1_type_c / ' || l_params;
            IF i_flg_type = pk_ref_constant.g_p1_type_c
            THEN
                g_error := 'Open c_standard_type(' || l_id_market || ',' || i_spec || ') / ' || l_params;
                OPEN c_standard_type(l_id_market, i_spec);
                FETCH c_standard_type
                    INTO l_standard_type;
                CLOSE c_standard_type;
            END IF;
        
            g_error := 'FOR i IN 1 .. ' || l_ref_completion_tab.count || ' / ' || l_params;
            FOR i IN 1 .. l_ref_completion_tab.count
            LOOP
                g_error := 'OPTIONS [ELECTRONIC=' || l_electronic || '|PRINT=' || l_print || ' / ID_PAT=' || i_patient ||
                           ' NUM_SNS=' || l_num_sns || ' ID_REF_COMPL=' || l_ref_completion_tab(i).id_ref_completion ||
                           ' FLG_TYPE=' || l_ref_completion_tab(i).flg_type;
                --pk_alertlog.log_debug(g_error);            
            
                CASE
                    WHEN l_ref_completion_tab(i).flg_type = pk_ref_constant.g_ref_compl_type_s THEN
                        g_error := 'Save option active / ' || l_params;
                        l_ref_completion_tab(i).flg_active := pk_ref_constant.g_yes;
                    
                    WHEN l_ref_completion_tab(i)
                     .flg_type IN (pk_ref_constant.g_ref_compl_type_e, pk_ref_constant.g_ref_compl_type_a) THEN
                        ---------
                        -- electronic
                    
                        -- especialidade apenas do botão REF não podem ser enviadas eletronicamente
                        IF l_standard_type.standard_type = pk_ref_constant.g_ref
                        THEN
                            g_error := 'Electronic option inactive 1 / ' || l_params;
                            l_ref_completion_tab(i).flg_active := pk_ref_constant.g_no;
                            l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                        ELSE
                            IF l_electronic = 1
                            THEN
                                g_error := 'Electronic option active 2 / ' || l_params;
                                l_ref_completion_tab(i).flg_active := pk_ref_constant.g_yes;
                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_active;
                            ELSE
                                g_error := 'Electronic option inactive 3 / ' || l_params;
                                l_ref_completion_tab(i).flg_active := pk_ref_constant.g_no;
                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                            END IF;
                        END IF;
                    
                    WHEN l_ref_completion_tab(i).flg_type = pk_ref_constant.g_ref_compl_type_p THEN
                    
                        ---------
                        -- print
                        IF l_print = 1
                        THEN
                        
                            -- especialidade apenas do CTH só podem ser impressas no modelo generico de requisição
                            -- apenas para DEMOS 
                            IF l_standard_type.standard_type = pk_ref_constant.g_cth
                               AND l_ref_completion_tab(i).id_ref_completion <> pk_ref_constant.g_ref_compl_print_req
                            THEN
                                g_error := 'Printable option inactive 1 / ' || l_params;
                                l_ref_completion_tab(i).flg_active := pk_ref_constant.g_no;
                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                            ELSE
                            
                                g_error := 'Printable option active 2 / ' || l_params;
                                l_ref_completion_tab(i).flg_active := pk_ref_constant.g_yes;
                            
                                CASE l_id_market
                                
                                    WHEN pk_ref_constant.g_market_pt THEN
                                        -- PT market
                                        IF l_ref_completion_tab(i)
                                         .id_ref_completion = pk_ref_constant.g_ref_compl_330_10
                                        THEN
                                            -- Setting flg_default = 'A'
                                            g_error := 'Printable default option 3 / ' || l_params;
                                            l_ref_completion_tab(i).flg_default := pk_ref_constant.g_active;
                                            l_print_default_option := l_ref_completion_tab(i).id_ref_completion;
                                        ELSE
                                            -- Setting flg_default = 'I'                            
                                            l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                                        END IF;
                                    
                                    WHEN pk_ref_constant.g_market_fr THEN
                                    
                                        -- FR market
                                        IF i_flg_type = pk_ref_constant.g_p1_type_c
                                        THEN
                                            IF l_ref_completion_tab(i)
                                             .id_ref_completion = pk_ref_constant.g_ref_compl_print_req
                                            THEN
                                                g_error := 'Printable default option 1 / ' || l_params;
                                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_active;
                                                l_print_default_option := l_ref_completion_tab(i).id_ref_completion;
                                            ELSE
                                                -- Setting flg_default = 'I'                            
                                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                                            END IF;
                                        ELSE
                                            IF l_ref_completion_tab(i)
                                             .id_ref_completion = pk_ref_constant.g_ref_compl_ordon
                                            THEN
                                                g_error := 'Printable default option 2 / ' || l_params;
                                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_active;
                                                l_print_default_option := l_ref_completion_tab(i).id_ref_completion;
                                            ELSE
                                                -- Setting flg_default = 'I'                            
                                                l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                                            END IF;
                                        END IF;
                                    
                                    ELSE
                                        -- all other markets
                                        IF l_ref_completion_tab(i)
                                         .id_ref_completion = pk_ref_constant.g_ref_compl_print_req
                                        THEN
                                            -- Setting flg_default = 'A'
                                            l_ref_completion_tab(i).flg_default := pk_ref_constant.g_active;
                                            l_print_default_option := l_ref_completion_tab(i).id_ref_completion;
                                        ELSE
                                            -- Setting flg_default = 'I'                            
                                            l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                                        END IF;
                                END CASE;
                            
                                -- set electronic option exists, printable option must not be default
                                IF l_electronic = 1
                                THEN
                                    g_error := 'electronic default option already set / ' || l_params;
                                    l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                                END IF;
                            
                            END IF;
                        
                        ELSE
                            g_error := 'Printable option inactive / ' || l_params;
                            --pk_alertlog.log_debug(g_error);
                            l_ref_completion_tab(i).flg_active := pk_ref_constant.g_no;
                            l_ref_completion_tab(i).flg_default := pk_ref_constant.g_inactive;
                        END IF;
                    
                    WHEN l_ref_completion_tab(i).flg_type = pk_ref_constant.g_ref_compl_type_s THEN
                        NULL; -- Save option, do nothing
                    ELSE
                        g_error := 'CASE NOT FOUND / FLG_TYPE=' || l_ref_completion_tab(i).flg_type || ' is invalid / ' ||
                                   l_params;
                        pk_alertlog.log_warn(g_error);
                        RAISE g_exception;
                END CASE;
            
            END LOOP;
        
            ---------------------------------------------------------------------------
            -- 5- If print options are chosen automaticaly (depends on sys_config parameter)
            -- then send only the 'l_print_default_option' print option to the output 
            -- configuration removed during printing list development (ALERT-281418)
            --g_error := 'REF_COMPL_P_AUTO=' || l_ref_compl_p_auto || ' / ' || l_params;
            --IF l_ref_compl_p_auto = pk_ref_constant.g_yes -- ALERT-50017
            --THEN
        
            -- removing all printable options of array l_ref_completion_tab, except for the l_print_default_option
            --    g_error := 'Removing printable options / ' || l_params;
            --    FOR i IN 1 .. l_ref_completion_tab.count
            --    LOOP
        
            --        IF l_ref_completion_tab(i).flg_type = pk_ref_constant.g_ref_compl_type_p
            --            AND l_ref_completion_tab(i).id_ref_completion != l_print_default_option
            --        THEN
        
            --            g_error := 'Printable option to remove=' || l_ref_completion_tab(i).id_ref_completion ||
            --                       ' printable default option=' || l_print_default_option || ' / ' || l_params;
            --pk_alertlog.log_debug(g_error);
        
            -- removing array entry                       
            --            l_ref_completion_tab.delete(i);
        
            --        END IF;
            --    END LOOP;
        
            --END IF;
        
            ---------------------------------------------------------------------------
            -- 6- output completion options: t_coll_ref_completion
        
        ELSE
            g_error := 'No options available / ' || l_params;
            pk_alertlog.log_warn(g_error);
        END IF;
    
        RETURN l_ref_completion_tab;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN t_coll_ref_completion();
    END get_compl_options_tf;

    /**
    * Checks if the given option is available for concluding the request.
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_patient           Patient identifier   
    * @param   i_episode           Episode identifier
    * @param   i_codification      Codification identifiers   
    * @param   i_inst_dest         Referrals destination institutions
    * @param   i_flg_type          Referral type
    * @param   i_option            Completion option identifier to be validated
    * @param   o_flg_available     Option availability
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_flg_type          {*} 'C' Consultation 
    *                              {*} 'A' Lab tests 
    *                              {*} 'I' Imaging exams
    *                              {*} 'E' Other exams
    *                              {*} 'P' Procedure
    *                              {*} 'F' Rehab
    *
    * @value   o_flg_available     {*} 'Y' - available  
    *                              {*} 'N' - otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2009
    */
    FUNCTION check_completion_option
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_codification  IN table_number,
        i_inst_dest     IN table_number,
        i_flg_type      IN p1_external_request.flg_type%TYPE,
        i_option        IN ref_completion.id_ref_completion%TYPE,
        i_spec          IN p1_speciality.id_speciality%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_completion_option';
        l_params VARCHAR2(1000 CHAR);
        l_count  PLS_INTEGER;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_epis=' || i_epis ||
                    ' i_codification=' || pk_utils.to_string(i_codification) || ' i_inst_dest=' ||
                    pk_utils.to_string(i_inst_dest) || ' i_flg_type=' || i_flg_type || ' i_option=' || i_option ||
                    ' i_spec=' || i_spec;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_flg_available := pk_ref_constant.g_no;
    
        -- checking available options        
        g_error := 'SELECT get_compl_options_tf / ' || l_params;
        SELECT /*+opt_estimate (table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM TABLE(CAST(get_compl_options_tf(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_epis         => i_epis,
                                               i_codification => i_codification,
                                               i_inst_dest    => i_inst_dest,
                                               i_flg_type     => i_flg_type,
                                               i_spec         => i_spec,
                                               -- remove duplicata and reprint options... must appear in report button, but not in completion options pop-up;
                                               i_ref_compl_excep => table_number(pk_ref_constant.g_ref_compl_duplicata,
                                                                                 pk_ref_constant.g_ref_compl_reprint)) AS
                          t_coll_ref_completion)) t
         WHERE t.id_ref_completion = i_option
           AND t.flg_active = pk_ref_constant.g_yes;
    
        g_error := 'l_count=' || l_count || ' / ' || l_params;
        IF l_count > 0
        THEN
            o_flg_available := pk_ref_constant.g_yes;
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
    END check_completion_option;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_schedule            Current schedule identifier
    * @param   o_p1                  Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   29-08-2007
    */

    FUNCTION get_pat_ref
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_type           IN table_varchar,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_status         IN table_varchar,
        i_inst_dest_list IN table_number,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_schedule    IN schedule.dt_schedule_tstz%TYPE,
        i_filter         IN p1_grid_config.filter%TYPE DEFAULT NULL,
        o_ref_list       OUT ref_cur,
        o_message        OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_buttons        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql         VARCHAR2(32000);
        l_filter      p1_grid_config.filter%TYPE;
        l_var_desc    table_varchar := table_varchar();
        l_var_val     table_varchar := table_varchar();
        l_type        table_varchar;
        l_instit_list table_number;
        l_my_data     t_rec_prof_data;
        g_ok_button_code CONSTANT VARCHAR2(7) := 'C829664';
        l_module sys_config.value%TYPE;
        l_params VARCHAR2(1000 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        l_params       := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_schedule=' ||
                          i_schedule || ' i_dcs=' || i_dcs || ' i_filter=' || i_filter;
        g_error        := 'Init get_pat_ref_to_schedule / ' || l_params;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error  := 'Call pk_sysconfig.get_config / ' || l_params || ' / SYS_CONFIG=' ||
                    pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
    
        ----------------------
        -- FUNC
        ----------------------
        l_var_desc.extend(6);
        l_var_val.extend(6);
    
        l_var_desc(1) := '@LANG';
        l_var_val(1) := to_char(i_lang);
    
        l_var_desc(2) := '@PROFESSIONAL';
        l_var_val(2) := to_char(i_prof.id);
    
        l_var_desc(3) := '@INSTITUTION';
        l_var_val(3) := to_char(i_prof.institution);
    
        l_var_desc(4) := '@SOFTWARE';
        l_var_val(4) := to_char(i_prof.software);
    
        l_var_desc(5) := '@PATIENT';
        l_var_val(5) := nvl(to_char(i_patient), 'NULL');
    
        l_var_desc(6) := '@DCS';
        l_var_val(6) := nvl(to_char(i_dcs), 'NULL');
    
        g_error := 'CASE MODULE=' || l_module || ' / ' || l_params;
        IF i_filter IS NULL
        THEN
            CASE l_module
                WHEN pk_ref_constant.g_sc_ref_module_circle THEN
                    -- CIRCLE module
                    l_filter := pk_ref_constant.g_gc_filter_schpat_circle;
                WHEN pk_ref_constant.g_sc_ref_module_gpportal THEN
                    -- CIRCLE GP PORTAL ALERT-14479
                    l_filter := pk_ref_constant.g_gc_filter_schpat_gpportal;
                ELSE
                    -- default behaviour (GENERIC)
                    l_filter := pk_ref_constant.g_gc_filter_schpat_generic;
            END CASE;
        
        ELSE
            l_filter := i_filter;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_type IS NULL
           OR i_type.count = 0
           OR (i_type.exists(1) AND i_type(1) IS NULL)
        THEN
            -- getting all referral types
            g_error := 'SELECT sys_domain / ' || l_params;
            SELECT val
              BULK COLLECT
              INTO l_type
              FROM sys_domain s
             WHERE s.code_domain = 'P1_EXTERNAL_REQUEST.FLG_TYPE'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND s.flg_available = pk_ref_constant.g_yes;
        ELSE
            l_type := i_type;
        END IF;
    
        IF i_inst_dest_list IS NULL
           OR i_inst_dest_list.count = 0
           OR (i_inst_dest_list.exists(1) AND i_inst_dest_list(1) IS NULL)
        THEN
            -- getting all referral types
            g_error := 'SELECT sys_domain / ' || l_params;
            SELECT i.id_institution
              BULK COLLECT
              INTO l_instit_list
              FROM institution i
             WHERE i.id_institution = i_prof.institution;
        ELSE
            l_instit_list := i_inst_dest_list;
        END IF;
    
        g_error  := 'Call pk_ref_core_internal.get_grid_sql / ' || l_params;
        g_retval := pk_ref_core_internal.get_grid_sql(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_var_desc => l_var_desc,
                                                      i_var_val  => l_var_val,
                                                      i_filter   => l_filter,
                                                      o_sql      => l_sql,
                                                      o_error    => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_ref_list FOR / ' || l_params;
        OPEN o_ref_list FOR
            SELECT to_char(t.id_patient) id_patient,
                   t.id_external_request,
                   t.num_req num_req,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                    (SELECT pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                             t.id_external_request,
                                                                                             t.flg_status,
                                                                                             t.id_workflow)
                                                       FROM dual),
                                                    i_prof)
                      FROM dual) dt_p1,
                   (SELECT pk_ref_utils.get_ref_detail_date(i_lang, t.id_external_request, t.flg_status, t.id_workflow)
                      FROM dual) dt_p1_tstz,
                   t.flg_type,
                   nvl2(pk_sysdomain.get_img(i_lang, pk_ref_constant.g_p1_exr_flg_type, t.flg_type),
                        lpad(pk_sysdomain.get_rank(i_lang, pk_ref_constant.g_p1_exr_flg_type, t.flg_type), 6, '0') ||
                        pk_sysdomain.get_img(i_lang, pk_ref_constant.g_p1_exr_flg_type, t.flg_type),
                        NULL) type_icon,
                   t.id_dep_clin_serv,
                   nvl2(t.code_department,
                        pk_translation.get_translation(i_lang, t.code_department) || '/' ||
                        pk_translation.get_translation(i_lang, t.code_clinical_service),
                        (SELECT desc_val
                           FROM sys_domain
                          WHERE id_language = i_lang
                            AND code_domain = pk_ref_constant.g_p1_exr_flg_type
                            AND domain_owner = pk_sysdomain.k_default_schema
                            AND val = t.flg_type)) serv_spec_desc,
                   (SELECT text
                      FROM p1_detail d
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_item
                       AND d.flg_status = pk_ref_constant.g_active
                       AND d.id_external_request = t.id_external_request
                       AND rownum = 1) desc_activity,
                   pk_ref_core.get_inst_name(i_lang,
                                             i_prof,
                                             t.flg_status,
                                             t.id_inst_dest,
                                             t.code_inst_dest,
                                             t.inst_dest_abbrev) inst_dest,
                   t.id_inst_dest id_inst_dest,
                   pk_translation.get_translation(i_lang, t.code_inst_orig) inst_orig,
                   t.id_inst_orig id_inst_orig,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_triage)
                      FROM dual) prof_triage,
                   t.flg_status,
                   (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', t.flg_status, i_lang)
                      FROM dual) flg_status_desc,
                   lpad('0', 6, '0') ||
                   pk_workflow.get_status_icon(i_lang,
                                               i_prof,
                                               nvl(t.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                               pk_ref_status.convert_status_n(t.flg_status),
                                               l_my_data.id_category,
                                               l_my_data.id_profile_template,
                                               (SELECT pk_ref_core.get_prof_func(i_lang, i_prof, t.id_dep_clin_serv)
                                                  FROM dual),
                                               (SELECT pk_ref_core.init_param_tab(i_lang,
                                                                                  i_prof,
                                                                                  t.id_external_request,
                                                                                  t.id_patient,
                                                                                  t.id_inst_orig,
                                                                                  t.id_inst_dest,
                                                                                  t.id_dep_clin_serv,
                                                                                  t.id_speciality,
                                                                                  t.flg_type,
                                                                                  t.decision_urg_level,
                                                                                  t.id_prof_requested,
                                                                                  t.id_prof_redirected,
                                                                                  t.id_prof_status,
                                                                                  t.id_external_sys,
                                                                                  pk_ref_constant.g_location_grid,
                                                                                  NULL,
                                                                                  t.flg_status)
                                                  FROM dual)) status_icon,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                    (SELECT pk_p1_utils.get_status_date(i_lang,
                                                                                        t.id_external_request,
                                                                                        pk_ref_constant.g_p1_status_e)
                                                       FROM dual),
                                                    i_prof)
                      FROM dual) dt_execution,
                   (SELECT pk_p1_utils.get_status_date(i_lang, t.id_external_request, pk_ref_constant.g_p1_status_e)
                      FROM dual) dt_execution_tstz,
                   -- ID_SCHEDULE (CIRCLE or GENERIC)
                   CASE l_module
                       WHEN pk_ref_constant.g_sc_ref_module_circle THEN
                        pk_ref_module.check_ref_sch_circle(i_lang, i_prof, t.id_external_request, i_schedule)
                       WHEN pk_ref_constant.g_sc_ref_module_gpportal THEN
                        pk_ref_module.get_ref_sch_ext(i_lang, i_prof, t.id_schedule)
                       ELSE
                        pk_ref_module.get_ref_sch_generic(i_lang, i_prof, t.id_external_request)
                   END id_schedule,
                   t.dt_requested,
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t.id_prof_requested,
                                                            i_id_prof_roda      => t.id_prof_roda) prof_requested_name,
                   decode(t.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          pk_ref_core.get_content(i_lang, i_prof, t.id_dep_clin_serv, t.id_prof_schedule),
                          NULL) id_content,
                   (SELECT sd.desc_val
                      FROM sys_domain sd
                     WHERE sd.code_domain = pk_ref_constant.g_p1_exr_flg_type
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = t.flg_type) desc_ref_type,
                   pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_status, t.flg_status, i_lang) desc_ref_status,
                   t.dt_schedule_tstz dt_schedule,
                   t.id_department,
                   pk_translation.get_translation(i_lang, t.code_department) desc_department,
                   t.id_clinical_service,
                   pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service,
                   decode(t.flg_type, pk_ref_constant.g_p1_type_c, t.id_speciality, NULL) id_procedure,
                   decode(t.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          (pk_translation.get_translation(i_lang, 'P1_SPECIALITY.CODE_SPECIALITY.' || t.id_speciality)),
                          NULL) desc_procedure,
                   t.id_prof_requested,
                   CASE t.flg_status
                       WHEN pk_ref_constant.g_p1_status_a THEN
                        pk_ref_core.get_prof_status(i_lang, i_prof, t.id_external_request, t.flg_status)
                       ELSE
                        t.id_prof_schedule
                   END id_prof_sch
              FROM (SELECT v.id_patient,
                           v.id_external_request,
                           v.num_req,
                           v.flg_status,
                           v.id_workflow,
                           v.flg_type,
                           v.id_dep_clin_serv,
                           v.code_department,
                           v.code_clinical_service,
                           v.id_inst_dest,
                           v.code_inst_dest,
                           v.inst_dest_abbrev,
                           v.code_inst_orig,
                           v.id_inst_orig,
                           v.id_prof_triage,
                           v.id_speciality,
                           v.decision_urg_level,
                           v.id_prof_requested,
                           v.id_prof_redirected,
                           v.id_prof_status,
                           v.id_external_sys,
                           v.id_schedule,
                           v.dt_schedule_tstz,
                           v.dt_requested,
                           v.id_prof_orig id_prof_roda,
                           v.id_prof_schedule,
                           dcs.id_department,
                           dcs.id_clinical_service
                      FROM TABLE(CAST(pk_ref_core_internal.get_grid_data(l_sql) AS t_coll_p1_request)) v
                      LEFT JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = v.id_dep_clin_serv AND
                           (i_dt_schedule IS NULL OR
                           pk_date_utils.compare_dates_tsz(i_prof, i_dt_schedule, v.dt_requested) = 'G'))
                      LEFT JOIN(TABLE(CAST(i_status AS table_varchar))) st
                        ON (st.column_value = v.flg_status)
                      JOIN(TABLE(CAST(l_type AS table_varchar))) tt
                        ON (tt.column_value = v.flg_type)
                      JOIN(TABLE(CAST(l_instit_list AS table_number))) it
                        ON (it.column_value = v.id_inst_dest)) t
            UNION
            SELECT to_char(t1.id_patient) id_patient,
                   t1.id_external_request,
                   t1.num_req num_req,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                    (SELECT pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                             t1.id_external_request,
                                                                                             t1.flg_status,
                                                                                             t1.id_workflow)
                                                       FROM dual),
                                                    i_prof)
                      FROM dual) dt_p1,
                   (SELECT pk_ref_utils.get_ref_detail_date(i_lang,
                                                            t1.id_external_request,
                                                            t1.flg_status,
                                                            t1.id_workflow)
                      FROM dual) dt_p1_tstz,
                   t1.flg_type,
                   nvl2(pk_sysdomain.get_img(i_lang, pk_ref_constant.g_p1_exr_flg_type, t1.flg_type),
                        lpad(pk_sysdomain.get_rank(i_lang, pk_ref_constant.g_p1_exr_flg_type, t1.flg_type), 6, '0') ||
                        pk_sysdomain.get_img(i_lang, pk_ref_constant.g_p1_exr_flg_type, t1.flg_type),
                        NULL) type_icon,
                   t1.id_dep_clin_serv,
                   nvl2(t1.code_department,
                        pk_translation.get_translation(i_lang, t1.code_department) || '/' ||
                        pk_translation.get_translation(i_lang, t1.code_clinical_service),
                        (SELECT desc_val
                           FROM sys_domain
                          WHERE id_language = i_lang
                            AND code_domain = pk_ref_constant.g_p1_exr_flg_type
                            AND val = t1.flg_type)) serv_spec_desc,
                   (SELECT text
                      FROM p1_detail d
                     WHERE d.flg_type = pk_ref_constant.g_detail_type_item
                       AND d.flg_status = pk_ref_constant.g_active
                       AND d.id_external_request = t1.id_external_request
                       AND rownum = 1) desc_activity,
                   pk_ref_core.get_inst_name(i_lang,
                                             i_prof,
                                             t1.id_inst_dest,
                                             t1.id_inst_dest,
                                             t1.code_inst_dest,
                                             t1.inst_dest_abbrev) inst_dest,
                   t1.id_inst_dest,
                   pk_translation.get_translation(i_lang, t1.code_inst_orig) inst_orig,
                   t1.id_inst_orig,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t1.id_prof_triage)
                      FROM dual) prof_triage,
                   t1.flg_status,
                   (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', t1.flg_status, i_lang)
                      FROM dual) flg_status_desc,
                   lpad('0', 6, '0') ||
                   pk_workflow.get_status_icon(i_lang,
                                               i_prof,
                                               nvl(t1.id_workflow, pk_ref_constant.g_wf_pcc_hosp),
                                               pk_ref_status.convert_status_n(t1.flg_status),
                                               l_my_data.id_category,
                                               l_my_data.id_profile_template,
                                               pk_ref_core.get_prof_func(i_lang, i_prof, t1.id_dep_clin_serv),
                                               (SELECT pk_ref_core.init_param_tab(i_lang,
                                                                                  i_prof,
                                                                                  t1.id_external_request,
                                                                                  t1.id_patient,
                                                                                  t1.id_inst_orig,
                                                                                  t1.id_inst_dest,
                                                                                  t1.id_dep_clin_serv,
                                                                                  t1.id_speciality,
                                                                                  t1.flg_type,
                                                                                  t1.decision_urg_level,
                                                                                  t1.id_prof_requested,
                                                                                  t1.id_prof_redirected,
                                                                                  t1.id_prof_status,
                                                                                  t1.id_external_sys,
                                                                                  pk_ref_constant.g_location_grid,
                                                                                  NULL,
                                                                                  t1.flg_status)
                                                  FROM dual)) status_icon,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                    (SELECT pk_p1_utils.get_status_date(i_lang,
                                                                                        t1.id_external_request,
                                                                                        pk_ref_constant.g_p1_status_e)
                                                       FROM dual),
                                                    i_prof)
                      FROM dual) dt_execution,
                   (SELECT pk_p1_utils.get_status_date(i_lang, t1.id_external_request, pk_ref_constant.g_p1_status_e)
                      FROM dual) dt_execution_tstz,
                   CASE l_module
                       WHEN pk_ref_constant.g_sc_ref_module_circle THEN
                        pk_ref_module.check_ref_sch_circle(i_lang, i_prof, t1.id_external_request, i_schedule)
                       WHEN pk_ref_constant.g_sc_ref_module_gpportal THEN
                        pk_ref_module.get_ref_sch_ext(i_lang, i_prof, t1.id_schedule)
                       ELSE
                        pk_ref_module.get_ref_sch_generic(i_lang, i_prof, t1.id_external_request)
                   END id_schedule,
                   t1.dt_requested,
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t1.id_prof_requested,
                                                            i_id_prof_roda      => t1.id_prof_roda) prof_requested_name,
                   decode(t1.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          pk_ref_core.get_content(i_lang, i_prof, t1.id_dep_clin_serv, t1.id_prof_schedule),
                          NULL) id_content,
                   (SELECT sd.desc_val
                      FROM sys_domain sd
                     WHERE sd.code_domain = pk_ref_constant.g_p1_exr_flg_type
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = t1.flg_type) desc_ref_type,
                   pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_status, t1.flg_status, i_lang) desc_ref_status,
                   t1.dt_schedule_tstz dt_schedule,
                   t1.id_department,
                   pk_translation.get_translation(i_lang, t1.code_department) desc_department,
                   t1.id_clinical_service,
                   pk_translation.get_translation(i_lang, t1.code_clinical_service) desc_clinical_service,
                   decode(t1.flg_type, pk_ref_constant.g_p1_type_c, t1.id_speciality, NULL) id_procedure,
                   decode(t1.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          (pk_translation.get_translation(i_lang, 'P1_SPECIALITY.CODE_SPECIALITY.' || t1.id_speciality)),
                          NULL) desc_procedure,
                   t1.id_prof_requested,
                   CASE t1.flg_status
                       WHEN pk_ref_constant.g_p1_status_a THEN
                        pk_ref_core.get_prof_status(i_lang, i_prof, t1.id_external_request, t1.flg_status)
                       ELSE
                        t1.id_prof_schedule
                   END id_prof_sch
              FROM (SELECT vc.id_patient,
                           vc.id_external_request,
                           vc.num_req,
                           vc.flg_status,
                           vc.id_workflow,
                           vc.flg_type,
                           vc.id_dep_clin_serv,
                           vc.code_department,
                           vc.code_clinical_service,
                           vc.id_inst_dest,
                           vc.code_inst_dest,
                           vc.inst_dest_abbrev,
                           vc.code_inst_orig,
                           vc.id_inst_orig,
                           vc.id_prof_triage,
                           vc.id_speciality,
                           vc.decision_urg_level,
                           vc.id_prof_requested,
                           vc.id_prof_redirected,
                           vc.id_prof_status,
                           vc.id_external_sys,
                           vc.id_schedule,
                           vc.dt_schedule_tstz,
                           vc.id_prof_schedule,
                           vc.dt_requested,
                           vc.id_prof_orig id_prof_roda,
                           dcs.id_department,
                           dcs.id_clinical_service
                      FROM TABLE(CAST(pk_ref_core_internal.get_grid_data(l_sql) AS t_coll_p1_request)) vc
                      LEFT JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = vc.id_dep_clin_serv)
                      JOIN(TABLE(CAST(i_status AS table_varchar))) st
                        ON (st.column_value = vc.flg_status)
                      JOIN(TABLE(CAST(l_type AS table_varchar))) tt
                        ON (tt.column_value = vc.flg_type)
                      JOIN(TABLE(CAST(l_instit_list AS table_number))) it
                        ON (it.column_value = vc.id_inst_dest)
                     WHERE i_dt_schedule IS NULL
                        OR pk_date_utils.compare_dates_tsz(i_prof, i_dt_schedule, vc.dt_requested) = 'G') t1
             ORDER BY id_schedule DESC, dt_requested, status_icon DESC;
    
        o_message := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_DOCTOR_REQ_T064');
        o_title   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_DOCTOR_REQ_T065');
        o_buttons := g_ok_button_code ||
                     pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'P1_DOCTOR_REQ_T066') || '|';
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ref_list);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_PAT_REF_TO_SCHEDULE',
                                                     o_error    => o_error);
    END get_pat_ref;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_schedule            Current schedule identifier
    * @param   o_p1                  Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-10-2010
    */

    FUNCTION get_pat_ref_to_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_type     IN table_varchar,
        i_schedule IN schedule.id_schedule%TYPE,
        o_p1       OUT ref_cur,
        o_message  OUT VARCHAR2,
        o_title    OUT VARCHAR2,
        o_buttons  OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error  := 'Calling get_pat_ref';
        g_retval := get_pat_ref(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_patient        => i_patient,
                                i_type           => i_type,
                                i_schedule       => i_schedule,
                                i_status         => table_varchar(pk_ref_constant.g_p1_status_s,
                                                                  pk_ref_constant.g_p1_status_m,
                                                                  pk_ref_constant.g_p1_status_e),
                                i_inst_dest_list => NULL,
                                i_dcs            => NULL,
                                i_dt_schedule    => NULL,
                                o_ref_list       => o_p1,
                                o_message        => o_message,
                                o_title          => o_title,
                                o_buttons        => o_buttons,
                                o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_p1);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_PAT_REF_TO_SCHEDULE',
                                                     o_error    => o_error);
        
    END get_pat_ref_to_schedule;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_schedule            Current schedule identifier
    * @param   o_p1                  Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-10-2010
    */

    FUNCTION get_pat_ref_to_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_type           IN table_varchar,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_inst_dest_list IN table_number,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_schedule    IN schedule.dt_schedule_tstz%TYPE,
        o_p1             OUT ref_cur,
        o_message        OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_buttons        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error  := 'Calling get_pat_ref';
        g_retval := get_pat_ref(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_patient        => i_patient,
                                i_type           => i_type,
                                i_schedule       => i_schedule,
                                i_status         => table_varchar(pk_ref_constant.g_p1_status_a),
                                i_inst_dest_list => i_inst_dest_list,
                                i_dcs            => i_dcs,
                                i_dt_schedule    => i_dt_schedule,
                                i_filter         => 'REF_TO_SCHEDULE',
                                o_ref_list       => o_p1,
                                o_message        => o_message,
                                o_title          => o_title,
                                o_buttons        => o_buttons,
                                o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_p1);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_PAT_REF_TO_SCHEDULE',
                                                     o_error    => o_error);
        
    END get_pat_ref_to_schedule;

    /**
    * Gets list of patient referrals available for Patient Portal
    * Used by schema ALERT_INTER
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_inst_dest_list         Institution dest list
    * @param   o_ref_list            Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-10-2010
    */

    FUNCTION get_pat_ref_gp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_type           IN table_varchar,
        i_inst_dest_list IN table_number,
        o_ref_list       OUT ref_cur,
        o_message        OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_buttons        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error  := 'Calling get_pat_ref';
        g_retval := get_pat_ref(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_patient        => i_patient,
                                i_type           => i_type,
                                i_schedule       => NULL,
                                i_status         => table_varchar(pk_ref_constant.g_p1_status_s,
                                                                  pk_ref_constant.g_p1_status_m,
                                                                  pk_ref_constant.g_p1_status_e,
                                                                  pk_ref_constant.g_p1_status_c,
                                                                  pk_ref_constant.g_p1_status_w,
                                                                  pk_ref_constant.g_p1_status_k,
                                                                  pk_ref_constant.g_p1_status_a,
                                                                  pk_ref_constant.g_p1_status_i),
                                i_inst_dest_list => i_inst_dest_list,
                                i_dcs            => NULL,
                                i_dt_schedule    => NULL,
                                o_ref_list       => o_ref_list,
                                o_message        => o_message,
                                o_title          => o_title,
                                o_buttons        => o_buttons,
                                o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ref_list);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_PAT_REF_GP',
                                                     o_error    => o_error);
        
    END get_pat_ref_gp;

    /**
    * Associates a referral to a schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes           
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate    p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row    p1_external_request%ROWTYPE;
        l_prof_data  t_rec_prof_data;
        l_param      table_varchar;
        l_reschedule VARCHAR2(1 CHAR);
        l_params     VARCHAR2(1000 CHAR);
        o_track      table_number;
    BEGIN
        l_params := 'ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
        g_error  := '->Init set_ref_schedule / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_track := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        l_params  := l_params || ' OP_DATE=' ||
                     pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, pk_ref_constant.g_format_date_2);
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => i_id_ref,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            -- old workflow
        
            IF l_ref_row.id_schedule IS NOT NULL
            THEN
                -- old schedule
                l_reschedule := pk_ref_constant.g_yes;
            ELSE
                l_reschedule := pk_ref_constant.g_no;
            END IF;
        
            g_error  := 'Call pk_p1_ext_sys.update_referral_status / ' || l_params;
            g_retval := pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_ext_req    => l_ref_row.id_external_request,
                                                             i_id_sch     => i_schedule,
                                                             i_status     => pk_ref_constant.g_p1_status_s,
                                                             i_notes      => i_notes,
                                                             i_reschedule => l_reschedule,
                                                             i_date       => l_sysdate,
                                                             o_error      => o_error);
        ELSE
        
            -- new workflow
            g_error := 'Calling pk_ref_core.init_param_tab / ' || l_params;
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => l_ref_row.id_external_request,
                                                  i_id_patient         => l_ref_row.id_patient,
                                                  i_id_inst_orig       => l_ref_row.id_inst_orig,
                                                  i_id_inst_dest       => l_ref_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                                  i_id_speciality      => l_ref_row.id_speciality,
                                                  i_flg_type           => l_ref_row.flg_type,
                                                  i_decision_urg_level => l_ref_row.decision_urg_level,
                                                  i_id_prof_requested  => l_ref_row.id_prof_requested,
                                                  i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                                  i_id_prof_status     => l_ref_row.id_prof_status,
                                                  i_external_sys       => l_ref_row.id_external_sys,
                                                  i_flg_status         => l_ref_row.flg_status);
        
            g_error  := 'Call PK_REF_CORE.process_transition / ACTION=' || pk_ref_constant.g_ref_action_s || ' / ' ||
                        l_params;
            g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_prof_data  => l_prof_data,
                                                        i_ref_row    => l_ref_row,
                                                        i_action     => pk_ref_constant.g_ref_action_s,
                                                        i_status_end => NULL,
                                                        i_date       => l_sysdate,
                                                        i_schedule   => i_schedule,
                                                        i_episode    => i_episode,
                                                        i_notes      => i_notes,
                                                        io_param     => l_param,
                                                        io_track     => o_track,
                                                        o_error      => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_REF_SCHEDULE',
                                                     o_error    => o_error);
    END set_ref_schedule;

    /**
    * Cancels association between referral and schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION cancel_ref_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate   p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
        l_param     table_varchar;
        o_track     table_number;
    BEGIN
        g_error := '->Init cancel_ref_schedule / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule || ' OP_DATE=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, i_date, pk_ref_constant.g_format_date_2);
        pk_alertlog.log_debug(g_error);
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => i_id_ref,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            -- old workflow        
            g_error  := 'Call pk_p1_ext_sys.update_referral_status';
            g_retval := pk_p1_ext_sys.update_referral_status(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_ext_req        => l_ref_row.id_external_request,
                                                             i_id_sch         => NULL,
                                                             i_status         => pk_ref_constant.g_p1_status_a,
                                                             i_notes          => i_notes,
                                                             i_reschedule     => NULL,
                                                             i_date           => l_sysdate,
                                                             i_id_reason_code => i_id_reason_code,
                                                             o_error          => o_error);
        ELSE
            g_error := 'Calling pk_ref_core.init_param_tab';
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => l_ref_row.id_external_request,
                                                  i_id_patient         => l_ref_row.id_patient,
                                                  i_id_inst_orig       => l_ref_row.id_inst_orig,
                                                  i_id_inst_dest       => l_ref_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                                  i_id_speciality      => l_ref_row.id_speciality,
                                                  i_flg_type           => l_ref_row.flg_type,
                                                  i_decision_urg_level => l_ref_row.decision_urg_level,
                                                  i_id_prof_requested  => l_ref_row.id_prof_requested,
                                                  i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                                  i_id_prof_status     => l_ref_row.id_prof_status,
                                                  i_external_sys       => l_ref_row.id_external_sys,
                                                  i_flg_status         => l_ref_row.flg_status);
        
            g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || i_id_ref || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_csh || ' ID_SCHEDULE=' || i_schedule || ' L_SYSDATE=' ||
                        pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
            g_retval := pk_ref_core.process_transition2(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_prof_data   => l_prof_data,
                                                        i_ref_row     => l_ref_row,
                                                        i_action      => pk_ref_constant.g_ref_action_csh,
                                                        i_status_end  => NULL,
                                                        i_schedule    => i_schedule,
                                                        i_notes       => i_notes,
                                                        i_date        => l_sysdate,
                                                        i_reason_code => i_id_reason_code,
                                                        io_param      => l_param,
                                                        io_track      => o_track,
                                                        o_error       => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CANCEL_REF_SCHEDULE',
                                                     o_error    => o_error);
    END cancel_ref_schedule;

    /**
    * Notifies the patient about the referral schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_notify
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate   p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
        l_param     table_varchar;
        o_track     table_number;
    BEGIN
        g_error := '->Init set_ref_notify / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule || ' OP_DATE=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, i_date, pk_ref_constant.g_format_date_2);
        pk_alertlog.log_debug(g_error);
        o_track := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => i_id_ref,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            -- old workflow        
            g_error  := 'Call pk_p1_ext_sys.update_referral_status';
            g_retval := pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_ext_req    => l_ref_row.id_external_request,
                                                             i_id_sch     => NULL,
                                                             i_status     => pk_ref_constant.g_p1_status_m,
                                                             i_notes      => i_notes,
                                                             i_reschedule => NULL,
                                                             i_date       => l_sysdate,
                                                             o_error      => o_error);
        ELSE
        
            g_error := 'Calling pk_ref_core.init_param_tab';
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => l_ref_row.id_external_request,
                                                  i_id_patient         => l_ref_row.id_patient,
                                                  i_id_inst_orig       => l_ref_row.id_inst_orig,
                                                  i_id_inst_dest       => l_ref_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                                  i_id_speciality      => l_ref_row.id_speciality,
                                                  i_flg_type           => l_ref_row.flg_type,
                                                  i_decision_urg_level => l_ref_row.decision_urg_level,
                                                  i_id_prof_requested  => l_ref_row.id_prof_requested,
                                                  i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                                  i_id_prof_status     => l_ref_row.id_prof_status,
                                                  i_external_sys       => l_ref_row.id_external_sys,
                                                  i_flg_status         => l_ref_row.flg_status);
        
            g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || i_id_ref || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_m || ' L_SYSDATE=' ||
                        pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
            g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_prof_data  => l_prof_data,
                                                        i_ref_row    => l_ref_row,
                                                        i_action     => pk_ref_constant.g_ref_action_m,
                                                        i_status_end => NULL,
                                                        i_notes      => i_notes,
                                                        i_date       => l_sysdate,
                                                        io_param     => l_param,
                                                        io_track     => o_track,
                                                        o_error      => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_REF_NOTIFY',
                                                     o_error    => o_error);
    END set_ref_notify;

    /**
    * Starts the registration process. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_notes    Notes       
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_efectiv
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate   p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
        l_param     table_varchar;
        o_track     table_number;
    BEGIN
        g_error := '->Init set_ref_efectiv / ID_REF=' || i_id_ref || ' OP_DATE=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, i_date, pk_ref_constant.g_format_date_2);
        pk_alertlog.log_debug(g_error);
        o_track := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => i_id_ref,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            -- old workflow        
            g_error  := 'Call pk_p1_ext_sys.update_referral_status';
            g_retval := pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_ext_req    => l_ref_row.id_external_request,
                                                             i_id_sch     => NULL,
                                                             i_status     => pk_ref_constant.g_p1_status_e,
                                                             i_notes      => i_notes,
                                                             i_reschedule => NULL,
                                                             i_date       => l_sysdate,
                                                             o_error      => o_error);
        ELSE
            g_error := 'Calling pk_ref_core.init_param_tab';
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => l_ref_row.id_external_request,
                                                  i_id_patient         => l_ref_row.id_patient,
                                                  i_id_inst_orig       => l_ref_row.id_inst_orig,
                                                  i_id_inst_dest       => l_ref_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                                  i_id_speciality      => l_ref_row.id_speciality,
                                                  i_flg_type           => l_ref_row.flg_type,
                                                  i_decision_urg_level => l_ref_row.decision_urg_level,
                                                  i_id_prof_requested  => l_ref_row.id_prof_requested,
                                                  i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                                  i_id_prof_status     => l_ref_row.id_prof_status,
                                                  i_external_sys       => l_ref_row.id_external_sys,
                                                  i_flg_status         => l_ref_row.flg_status);
        
            g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || i_id_ref || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_e || ' L_SYSDATE=' ||
                        pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
            g_retval := pk_ref_core.process_transition2(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_prof_data      => l_prof_data,
                                                        i_ref_row        => l_ref_row,
                                                        i_action         => pk_ref_constant.g_ref_action_e,
                                                        i_status_end     => NULL,
                                                        i_notes          => i_notes,
                                                        i_date           => l_sysdate,
                                                        i_transaction_id => NULL,
                                                        io_param         => l_param,
                                                        io_track         => o_track,
                                                        o_error          => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_REF_EFECTIV',
                                                     o_error    => o_error);
    END set_ref_efectiv;

    /**
    * Notifies about a scheduled patient no-show
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_notes    Notes       
    * @param   i_reason   Id_cancel_reason 
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-09-2011
    */
    FUNCTION set_ref_no_show
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason         IN NUMBER,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdate   p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
        l_param     table_varchar;
        l_reason    p1_reason_code.id_reason_code%TYPE;
        o_track     table_number;
    BEGIN
        g_error := '->Init set_ref_no_show / ID_REF=' || i_id_ref || ' OP_DATE=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, i_date, pk_ref_constant.g_format_date_2);
        pk_alertlog.log_debug(g_error);
        o_track := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => i_id_ref,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            -- old workflow        
            g_error  := 'Call pk_p1_ext_sys.update_referral_status';
            g_retval := pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_ext_req    => l_ref_row.id_external_request,
                                                             i_id_sch     => NULL,
                                                             i_status     => pk_ref_constant.g_p1_status_f,
                                                             i_notes      => i_notes,
                                                             i_reschedule => NULL,
                                                             i_date       => l_sysdate,
                                                             o_error      => o_error);
        ELSE
            g_error := 'Calling pk_ref_core.init_param_tab';
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => l_ref_row.id_external_request,
                                                  i_id_patient         => l_ref_row.id_patient,
                                                  i_id_inst_orig       => l_ref_row.id_inst_orig,
                                                  i_id_inst_dest       => l_ref_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                                  i_id_speciality      => l_ref_row.id_speciality,
                                                  i_flg_type           => l_ref_row.flg_type,
                                                  i_decision_urg_level => l_ref_row.decision_urg_level,
                                                  i_id_prof_requested  => l_ref_row.id_prof_requested,
                                                  i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                                  i_id_prof_status     => l_ref_row.id_prof_status,
                                                  i_external_sys       => l_ref_row.id_external_sys,
                                                  i_flg_status         => l_ref_row.flg_status);
        
            IF i_transaction_id IS NOT NULL
            THEN
                g_error  := 'Call  pk_ref_core.get_no_show_id_reason i_cancel_reason=' || i_reason;
                g_retval := pk_ref_core.get_no_show_id_reason(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_cancel_reason  => i_reason,
                                                              o_p1_reason_code => l_reason,
                                                              o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            ELSE
                l_reason := i_reason;
            END IF;
        
            g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || i_id_ref || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_f || ' L_SYSDATE=' ||
                        pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
            g_retval := pk_ref_core.process_transition2(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_prof_data      => l_prof_data,
                                                        i_ref_row        => l_ref_row,
                                                        i_action         => pk_ref_constant.g_ref_action_f, -- No SHOW 
                                                        i_status_end     => NULL,
                                                        i_notes          => i_notes,
                                                        i_reason_code    => l_reason,
                                                        i_date           => l_sysdate,
                                                        i_transaction_id => i_transaction_id,
                                                        io_param         => l_param,
                                                        io_track         => o_track,
                                                        o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_REF_NO_SHOW',
                                                     o_error    => o_error);
    END set_ref_no_show;
    /**
    * Notifies about a cancel patient no-show
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier                       
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-09-2011
    */
    FUNCTION set_ref_cancel_noshow
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row   p1_external_request%ROWTYPE;
        l_track_row p1_tracking%ROWTYPE;
        l_prof_data t_rec_prof_data;
        l_action    wf_workflow_action.internal_name%TYPE;
        l_param     table_varchar;
        l_sysdate   p1_tracking.dt_tracking_tstz%TYPE;
        o_track     table_number;
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_sysdate := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track   := table_number();
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Calling pk_ref_core.get_prof_data / ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => i_id_ref,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_utils.get_prev_status_data i_id_ref=' || i_id_ref;
        g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => i_id_ref,
                                                      o_data   => l_track_row,
                                                      o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'ext_req_status CASE ' || l_track_row.ext_req_status;
        <<ext_req_status>>CASE l_track_row.ext_req_status
            WHEN pk_ref_constant.g_p1_status_e THEN
                l_action := pk_ref_constant.g_ref_action_ute;
            WHEN pk_ref_constant.g_p1_status_m THEN
                l_action := pk_ref_constant.g_ref_action_utm;
            WHEN pk_ref_constant.g_p1_status_s THEN
                l_action := pk_ref_constant.g_ref_action_uts;
            ELSE
                RETURN FALSE;
        END CASE ext_req_status;
    
        g_error := 'Calling pk_ref_core.init_param_tab / ID_REF=' || i_id_ref;
        l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_ext_req            => l_ref_row.id_external_request,
                                              i_id_patient         => l_ref_row.id_patient,
                                              i_id_inst_orig       => l_ref_row.id_inst_orig,
                                              i_id_inst_dest       => l_ref_row.id_inst_dest,
                                              i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                              i_id_speciality      => l_ref_row.id_speciality,
                                              i_flg_type           => l_ref_row.flg_type,
                                              i_decision_urg_level => l_ref_row.decision_urg_level,
                                              i_id_prof_requested  => l_ref_row.id_prof_requested,
                                              i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                              i_id_prof_status     => l_ref_row.id_prof_status,
                                              i_external_sys       => l_ref_row.id_external_sys,
                                              i_flg_status         => l_ref_row.flg_status);
    
        g_error  := 'Call PK_REF_CORE.process_transition / ID_REF=' || i_id_ref || ' ACTION=' || l_action ||
                    ' L_SYSDATE=' || pk_date_utils.to_char_insttimezone(i_prof, l_sysdate, 'YYYYMMDDHH24MISS');
        g_retval := pk_ref_core.process_transition2(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_prof_data  => l_prof_data,
                                                    i_ref_row    => l_ref_row,
                                                    i_action     => l_action,
                                                    i_status_end => NULL,
                                                    i_notes      => NULL,
                                                    i_date       => l_sysdate,
                                                    io_param     => l_param,
                                                    io_track     => o_track,
                                                    o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_REF_CANCEL_NOSHOW',
                                                     o_error    => o_error);
    END set_ref_cancel_noshow;

    /**
    * Gets referral identifier associated to given schedule identifier
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_schedule            Schedule Identifier 
    * @param   o_id_external_request    Referral Identifier
    * @param   o_error                  An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-04-2011
    */
    FUNCTION get_referral_id
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_req p1_external_request.num_req%TYPE;
    BEGIN
        g_error := 'Init get_referral_id / ID_SCHEDULE=' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call pk_ref_module.get_ref_sch';
        g_retval := pk_ref_module.get_ref_sch(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_schedule         => i_id_schedule,
                                              o_id_external_request => o_id_external_request,
                                              o_num_req             => l_num_req,
                                              o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_REFERRAL_ID',
                                                     o_error    => o_error);
    END get_referral_id;

    /**
    * Returns the sys_config option that determines if the destination column is to be shown or not
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software  
    * @param   o_show_opt 'Y' or 'N' depending if the destination column is to be shown or not. 
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Almeida 
    * @version 1.0
    * @since   22-02-2010
    */
    FUNCTION get_screen_dest_option
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_show_opt OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_config_val sys_config.value%TYPE;
    BEGIN
    
        g_error := 'CALL pk_sysconfig.get_config / ID_INST = ' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
    
        l_config_val := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                    i_id_sys_config => pk_ref_constant.g_sc_ref_module);
    
        CASE
            WHEN l_config_val IN (pk_ref_constant.g_sc_ref_module_circle) THEN
                o_show_opt := pk_ref_constant.g_no;
            ELSE
                o_show_opt := pk_ref_constant.g_yes;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_SCREEN_DEST_OPTION',
                                                     o_error    => o_error);
    END get_screen_dest_option;

    /**
    * Get Referral short detail (Patient Portal)
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_external_request 
    * @param   O_sql referral detail
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-11-2010 
    */
    FUNCTION get_ref_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN table_number,
        o_detail              OUT ref_detail_cur,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_module sys_config.value%TYPE;
    BEGIN
        g_error  := 'Call pk_ref_utils.get_sys_config / ' || i_id_external_request.count;
        l_module := pk_ref_utils.get_sys_config(i_prof => i_prof, i_id_sys_config => pk_ref_constant.g_sc_ref_module);
    
        g_error := 'Open o_detail / ' || i_id_external_request.count;
        OPEN o_detail FOR
            SELECT to_char(t.id_patient),
                   t.id_external_request,
                   t.num_req,
                   t.flg_type,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang)
                      FROM dual) desc_referral_type,
                   t.flg_status,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_status, t.flg_status, i_lang)
                      FROM dual) desc_referral_status,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_prio, t.flg_priority, i_lang)
                      FROM dual) priority,
                   (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_decision_urg_level || t.decision_urg_level,
                                                   t.decision_urg_level,
                                                   i_lang)
                      FROM dual) decision_urg_level,
                   pk_ref_utils.get_ref_detail_date(i_lang, t.id_external_request, t.flg_status, t.id_workflow) dt_request,
                   pk_p1_external_request.get_prof_req_id(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_prof_requested => t.id_prof_requested,
                                                          i_id_prof_roda      => t.id_prof_roda) id_prof_requested,
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t.id_prof_requested,
                                                            i_id_prof_roda      => t.id_prof_roda) prof_requested_name,
                   t.id_inst_orig id_inst_orig,
                   pk_ref_core.get_inst_orig_name(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_inst_orig   => t.id_inst_orig,
                                                  i_inst_name_roda => t.inst_name_roda) inst_orig_name,
                   t.id_inst_dest,
                   pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || t.id_inst_dest) inst_dest_name,
                   t.id_speciality id_procedure,
                   nvl2(t.code_speciality,
                        pk_translation.get_translation(i_lang, t.code_speciality),
                        pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang)) ||
                   nvl2(t.code_speciality,
                        ' - ' || pk_translation.get_translation(i_lang, t.code_speciality),
                        pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang)) procedure_name,
                   t.id_dep_clin_serv,
                   t.id_department,
                   pk_translation.get_translation(i_lang, t.code_department) desc_department,
                   t.id_clinical_service,
                   pk_translation.get_translation(i_lang, t.code_clinical_service) desc_clinical_service,
                   decode(t.flg_type,
                          pk_ref_constant.g_p1_type_c,
                          pk_ref_core.get_content(i_lang, i_prof, t.id_dep_clin_serv, t.id_prof_schedule),
                          NULL) id_content,
                   t.dt_schedule dt_sch_tstz,
                   CASE t.flg_status
                       WHEN pk_ref_constant.g_p1_status_a THEN
                        pk_ref_core.get_prof_status(i_lang, i_prof, t.id_external_request, t.flg_status)
                       ELSE
                        t.id_prof_schedule
                   END id_prof_sch,
                   CASE t.flg_status
                       WHEN pk_ref_constant.g_p1_status_a THEN
                        pk_prof_utils.get_name_signature(i_lang,
                                                         i_prof,
                                                         pk_ref_core.get_prof_status(i_lang,
                                                                                     i_prof,
                                                                                     t.id_external_request,
                                                                                     t.flg_status))
                       ELSE
                        pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_schedule)
                   END prof_sch_name,
                   CASE l_module
                       WHEN pk_ref_constant.g_sc_ref_module_circle THEN
                        pk_ref_module.check_ref_sch_circle(i_lang, i_prof, t.id_external_request, t.id_schedule)
                       WHEN pk_ref_constant.g_sc_ref_module_gpportal THEN
                        pk_ref_module.get_ref_sch_ext(i_lang, i_prof, t.id_schedule)
                       ELSE
                        pk_ref_module.get_ref_sch_generic(i_lang, i_prof, t.id_external_request)
                   END id_schedule,
                   pk_ref_utils.get_prof_spec_signature(i_lang, i_prof, t.id_prof_requested, t.id_inst_orig) prof_spec_request
              FROM (SELECT per.id_patient,
                           per.id_external_request,
                           per.num_req,
                           per.flg_type,
                           per.flg_status,
                           per.flg_priority,
                           per.decision_urg_level,
                           per.id_workflow,
                           per.id_prof_requested,
                           per.id_inst_orig,
                           per.id_inst_dest,
                           per.id_dep_clin_serv,
                           per.id_prof_schedule,
                           per.dt_schedule,
                           per.id_schedule,
                           per.id_speciality,
                           pk_ref_constant.g_p1_speciality_code || per.id_speciality code_speciality,
                           dcs.id_department,
                           pk_ref_constant.g_department_code || dcs.id_department code_department,
                           dcs.id_clinical_service,
                           pk_ref_constant.g_clinical_service_code || dcs.id_clinical_service code_clinical_service,
                           per.id_prof_orig id_prof_roda,
                           per.institution_name_roda inst_name_roda
                      FROM referral_ea per
                      LEFT JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = per.id_dep_clin_serv)
                      JOIN (SELECT column_value
                             FROM TABLE(CAST(i_id_external_request AS table_number))) t
                        ON (t.column_value = per.id_external_request)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_DETAIL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_ref_detail;

    /*******************************************************************************************************************************************
    * Returns the information of the prescription light license of an user/institution                                                         *
    *                                                                                                                                          *
    * @param i_lang            LANGUAGE                                                                                                        *
    * @param i_prof            PROFESSIONAL ARRAY                                                                                              *
    * @param o_licenses_left   Licenses remaining (for PRE only)                                                                               *
    *                                                                                                                                          *
    * @param o_error           Message error to be shown to the user.                                                                          *
    *                                                                                                                                          *
    * @return  TRUE if succeeded. FALSE otherwise.                                                                                             *
    *                                                                                                                                          *
    * @author                         JOana Barroso                                                                                            *
    * @version                        1.0                                                                                                      *
    * @since                          2011/11/18                                                                                               
    *                                                                                                                                          *
    ********************************************************************************************************************************************/
    FUNCTION presc_light_get_license_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_licenses_left         OUT NUMBER,
        o_flg_show_almost_empty OUT VARCHAR2,
        o_almost_empty_msg      OUT VARCHAR2,
        o_flg_show_warning      OUT VARCHAR2,
        o_warning_msg           OUT VARCHAR2,
        o_header_msg            OUT VARCHAR2,
        o_show_warnings         OUT VARCHAR2,
        o_shortcut              OUT NUMBER,
        o_buttons               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'Call pk_bdnp.presc_light_get_license_info';
        g_retval := pk_bdnp.presc_light_get_license_info(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         o_licenses_left         => o_licenses_left,
                                                         o_flg_show_almost_empty => o_flg_show_almost_empty,
                                                         o_almost_empty_msg      => o_almost_empty_msg,
                                                         o_flg_show_warning      => o_flg_show_warning,
                                                         o_warning_msg           => o_warning_msg,
                                                         o_header_msg            => o_header_msg,
                                                         o_show_warnings         => o_show_warnings,
                                                         o_shortcut              => o_shortcut,
                                                         o_buttons               => o_buttons,
                                                         o_error                 => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('Error: ' || g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_buttons);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'PRES_LIGHT_GET_LICENSE_INFO',
                                                     o_error    => o_error);
    END presc_light_get_license_info;

    FUNCTION get_available_actions
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_active OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
        o_active         := l_bdnp_available;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_AVAILABLE_ACTIONS',
                                                     o_error    => o_error);
    END get_available_actions;

    /**
    * Gets request detail
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_ext_req        Referral identifier
    * @param   i_status_detail     Detail status returned    
    * @param   o_detail            Referral general data
    * @param   o_text              Referral information detail
    * @param   o_problem           Patient problems
    * @param   o_diagnosis         Patient diagnosis
    * @param   o_mcdt              MCDTs information
    * @param   o_needs             Additional needs for scheduling
    * @param   o_info              Additional needs for the appointment
    * @param   o_notes_status      Referral historical data
    * @param   o_notes_status_det  Referral historical data detail
    * @param   o_answer            Referral answer information
    * @param   o_title_status      Deprecated   
    * @param   o_editable          Flag inficating if referral can be canceled by this professional   
    * @param   o_can_cancel        'Y' if the request can be canceled, 'N' otherwise
    * @param   o_ref_orig_data     Referral orig data   
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_status_detail     {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @value   o_can_cancel        {*} 'Y' if the request can be canceled {*} 'N' otherwise
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.1
    * @since   25-01-2012
    */
    FUNCTION get_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_status_detail    IN p1_detail.flg_status%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_title_status     OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_orig_data    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient      pk_types.cursor_type;
        l_params       VARCHAR2(1000 CHAR);
        l_ref_comments pk_types.cursor_type;
        l_fields_rank  pk_types.cursor_type;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ext_req=' || i_id_ext_req || ' i_status_detail=' ||
                    i_status_detail;
        g_error  := 'Init get_referral / ' || l_params;
        g_retval := pk_ref_service.get_referral(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_ext_req       => i_id_ext_req,
                                                i_status_detail    => i_status_detail,
                                                o_patient          => l_patient,
                                                o_detail           => o_detail,
                                                o_text             => o_text,
                                                o_problem          => o_problem,
                                                o_diagnosis        => o_diagnosis,
                                                o_mcdt             => o_mcdt,
                                                o_needs            => o_needs,
                                                o_info             => o_info,
                                                o_notes_status     => o_notes_status,
                                                o_notes_status_det => o_notes_status_det,
                                                o_answer           => o_answer,
                                                o_title_status     => o_title_status,
                                                o_can_cancel       => o_can_cancel,
                                                o_ref_orig_data    => o_ref_orig_data,
                                                o_ref_comments     => l_ref_comments,
                                                o_fields_rank      => l_fields_rank,
                                                o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_orig_data);
            pk_types.open_cursor_if_closed(l_patient);
            pk_alert_exceptions.reset_error_state();
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_orig_data);
            pk_types.open_cursor_if_closed(l_patient);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral;

    /**
    * Indicates for each MCDT, whether it is a chronic disease or not (FLG_ALD)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ref            Referral identifier    
    * @param   i_mcdt_ald       Chronic disease information for each MCDT (FLG_ALD) [id_mcdt|id_sample_type|flg_ald]
    * @param   o_p1_exr_temp    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-09-2012
    */
    FUNCTION set_p1_exr_flg_ald
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ref         IN p1_external_request.id_external_request%TYPE,
        i_mcdt_ald    IN table_table_varchar,
        o_p1_exr_temp OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(0100 CHAR) := 'SET_P1_EXR_FLG_ALD';
    BEGIN
    
        g_error  := 'CALL pk_ref_api.set_p1_exr_flg_ald / I_REF= ' || i_ref;
        g_retval := pk_ref_api.set_p1_exr_flg_ald(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_ref         => i_ref,
                                                  i_mcdt_ald    => i_mcdt_ald,
                                                  o_p1_exr_temp => o_p1_exr_temp,
                                                  o_error       => o_error);
    
        IF NOT g_retval
        THEN
        
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            ROLLBACK;
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
            ROLLBACK;
            RETURN FALSE;
    END set_p1_exr_flg_ald;

    FUNCTION get_p1_exr_flg_ald
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref       IN p1_external_request.id_external_request%TYPE,
        o_mcdt_list OUT pk_types.cursor_type,
        o_message   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(0100 CHAR) := 'GET_P1_EXR_FLG_ALD';
        l_flg_type         p1_external_request.flg_type%TYPE;
        l_title            sys_message.code_message%TYPE;
        l_text             sys_message.code_message%TYPE;
        l_header           sys_message.code_message%TYPE;
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    BEGIN
    
        g_error  := 'Call pk_p1_external_request.get_flg_type / I_ID_REF=' || i_ref;
        g_retval := pk_p1_external_request.get_flg_type(i_lang     => i_lang,
                                                        i_id_ref   => i_ref,
                                                        o_flg_type => l_flg_type,
                                                        o_error    => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        SELECT nvl(sd.desc_val, '')
          INTO l_title
          FROM sys_domain sd
         WHERE sd.code_domain = pk_ref_constant.g_p1_exr_flg_type
           AND sd.domain_owner = pk_sysdomain.k_default_schema
           AND val = l_flg_type
           AND id_language = i_lang;
    
        IF l_flg_type = pk_ref_constant.g_p1_type_a
        THEN
        
            l_text   := pk_ref_constant.g_ref_comp_alda_m001;
            l_header := pk_ref_constant.g_ref_comp_alda_t001;
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_e
        THEN
            l_text   := pk_ref_constant.g_ref_comp_alde_m001;
            l_header := pk_ref_constant.g_ref_comp_alde_t001;
        
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_i
        THEN
            l_text   := pk_ref_constant.g_ref_comp_aldi_m001;
            l_header := pk_ref_constant.g_ref_comp_aldi_t001;
        
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_p
        THEN
            l_text   := pk_ref_constant.g_ref_comp_aldp_m001;
            l_header := pk_ref_constant.g_ref_comp_aldp_t001;
        
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_f
        THEN
            l_text   := pk_ref_constant.g_ref_comp_aldf_m001;
            l_header := pk_ref_constant.g_ref_comp_aldf_t001;
        
        ELSE
            g_error := 'ERROR: Referral type not available for ALD FLG_TYPE=' || l_flg_type;
            RAISE g_exception;
        END IF;
    
        l_code_msg_arr := table_varchar(l_text, l_header);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / l_code_msg_arr.COUNT=' || l_code_msg_arr.count ||
                    ' ID_EXT_REQ=' || i_ref;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        OPEN o_mcdt_list FOR
            SELECT CASE
                        WHEN l_flg_type = pk_ref_constant.g_p1_type_a THEN
                         pet.id_analysis
                        WHEN l_flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i) THEN
                         pet.id_exam
                        WHEN l_flg_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f) THEN
                         pet.id_intervention
                        ELSE
                         NULL
                    END id_mcdt,
                   pet.id_sample_type,
                   CASE
                        WHEN l_flg_type = pk_ref_constant.g_p1_type_a THEN
                         pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                   i_prof                      => i_prof,
                                                                   i_flg_type                  => 'A',
                                                                   i_analysis_code_translation => pk_ref_constant.g_analysis_code ||
                                                                                                  pet.id_analysis,
                                                                   i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                  pet.id_sample_type,
                                                                   i_dep_clin_serv             => NULL)
                    
                        WHEN l_flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i) THEN
                         pk_exams_api_db.get_alias_translation(i_lang,
                                                               i_prof,
                                                               pk_ref_constant.g_exam_code || pet.id_exam,
                                                               NULL)
                        WHEN l_flg_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f) THEN
                         pk_procedures_api_db.get_alias_translation(i_lang,
                                                                    i_prof,
                                                                    pk_ref_constant.g_interv_code || pet.id_intervention,
                                                                    NULL)
                        ELSE
                         NULL
                    END label,
                   pet.flg_ald
              FROM p1_exr_temp pet
             WHERE pet.id_external_request = i_ref
             ORDER BY label;
    
        OPEN o_message FOR
            SELECT l_desc_message_ibt(l_header) header, l_desc_message_ibt(l_text) text, l_title title
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_mcdt_list);
            pk_types.open_cursor_if_closed(o_message);
            pk_alert_exceptions.reset_error_state();
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
            pk_types.open_cursor_if_closed(o_mcdt_list);
            pk_types.open_cursor_if_closed(o_message);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_p1_exr_flg_ald;

    /**
    * Associate ID_EPIS_REPORT to the referral identifier, for this type of report
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral_tab    Array of referral identifiers
    * @param   i_id_epis_report_tab Array of epis_reports identifiers
    * @param   i_flg_rep_type_tab   Array of report types flags
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   18-12-2014
    */
    FUNCTION set_ref_report_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_referral_tab    IN table_number,
        i_id_epis_report_tab IN table_number,
        i_flg_rep_type_tab   IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_ref_report_internal';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_referral_tab.count=' || i_id_referral_tab.count ||
                    ' i_id_epis_report_tab.count=' || i_id_epis_report_tab.count || ' i_flg_rep_type_tab.count=' ||
                    i_flg_rep_type_tab.count;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        IF i_id_referral_tab.count != i_id_epis_report_tab.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        FOR i IN 1 .. i_id_referral_tab.count
        LOOP
            g_error := 'INSERT INTO ref_report / ID_REF=' || i_id_referral_tab(i) || ' ID_EPIS_REPORT=' ||
                       i_id_epis_report_tab(i) || ' FLG_TYPE=' || i_flg_rep_type_tab(i) || ' / ' || l_params;
            INSERT INTO ref_report
                (id_external_request, id_epis_report, flg_type)
            VALUES
                (i_id_referral_tab(i), i_id_epis_report_tab(i), i_flg_rep_type_tab(i));
        END LOOP;
    
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_report_internal;

    /**
    * Update information about the duplicata report generated to this referral identifier
    * Used by reports
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral_tab    Array of referral identifiers
    * @param   i_id_epis_report_tab Array of epis_reports identifiers
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   18-03-2014
    */
    FUNCTION set_ref_report_duplicata
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_referral_tab    IN table_number,
        i_id_epis_report_tab IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_ref_report_duplicata';
        l_params           VARCHAR2(1000 CHAR);
        l_flg_rep_type_tab table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_referral_tab.count=' || i_id_referral_tab.count ||
                    ' i_id_epis_report_tab.count=' || i_id_epis_report_tab.count;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        IF i_id_referral_tab.count != i_id_epis_report_tab.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_flg_rep_type_tab := table_varchar();
        l_flg_rep_type_tab.extend(i_id_referral_tab.count);
    
        FOR i IN 1 .. l_flg_rep_type_tab.count
        LOOP
            l_flg_rep_type_tab(i) := pk_ref_constant.g_rep_type_duplicata;
        END LOOP;
    
        g_retval := set_ref_report_internal(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_referral_tab    => i_id_referral_tab,
                                            i_id_epis_report_tab => i_id_epis_report_tab,
                                            i_flg_rep_type_tab   => l_flg_rep_type_tab,
                                            o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_report_duplicata;

    /**
    * Update information about the original report generated to this referral identifier
    * Used by reports
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral_tab    Array of referral identifiers
    * @param   i_id_epis_report_tab Array of epis_reports identifiers
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   18-03-2014
    */
    FUNCTION set_ref_report_reprint
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_referral_tab    IN table_number,
        i_id_epis_report_tab IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_ref_report_reprint';
        l_params           VARCHAR2(1000 CHAR);
        l_flg_rep_type_tab table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_referral_tab.count=' || i_id_referral_tab.count ||
                    ' i_id_epis_report_tab.count=' || i_id_epis_report_tab.count;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        IF i_id_referral_tab.count != i_id_epis_report_tab.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_flg_rep_type_tab := table_varchar();
        l_flg_rep_type_tab.extend(i_id_referral_tab.count);
    
        FOR i IN 1 .. l_flg_rep_type_tab.count
        LOOP
            l_flg_rep_type_tab(i) := pk_ref_constant.g_rep_type_reprint;
        END LOOP;
    
        g_error  := 'Call set_ref_report_internal / ' || l_params;
        g_retval := set_ref_report_internal(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_referral_tab    => i_id_referral_tab,
                                            i_id_epis_report_tab => i_id_epis_report_tab,
                                            i_flg_rep_type_tab   => l_flg_rep_type_tab,
                                            o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_report_reprint;

    /**
    * Get epis_report related to this referral, for the report type specified
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral        Referral identifier
    * @param   i_flg_rep_type       Report types flag
    *
    * @value   i_flg_rep_type       {*} D- duplicata
    *                               {*} R- reprint
    *
    * @return  number               Epis_report identifier
    *
    * @author  ana.monteiro
    * @since   18-03-2014
    */
    FUNCTION get_ref_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_referral  IN ref_report.id_external_request%TYPE,
        i_flg_rep_type IN ref_report.flg_type%TYPE
    ) RETURN epis_report.id_epis_report%TYPE IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_ref_report';
        l_params VARCHAR2(1000 CHAR);
        l_result epis_report.id_epis_report%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_referral=' || i_id_referral;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        BEGIN
            SELECT id_epis_report
              INTO l_result
              FROM ref_report r
             WHERE r.id_external_request = i_id_referral
               AND r.flg_type = i_flg_rep_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_result := NULL; -- there is no duplicata for this referral identifier
        END;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN NULL;
    END get_ref_report;

    /**
    * Gets information about print list job related to the referral
    * Used by print list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_print_list_job  Print list job identifier, related to the referral
    *
    * @return  t_rec_print_list_job Print list job information
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   30-09-2014
    */
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_get_print_job_info';
        l_params        VARCHAR2(1000 CHAR);
        l_result        t_rec_print_list_job;
        l_context_data  print_list_job.context_data%TYPE;
        l_id_ref        p1_external_request.id_external_request%TYPE;
        l_ref_row       p1_external_request%ROWTYPE;
        l_flg_type_desc VARCHAR2(1000 CHAR);
        l_dt_req_desc   VARCHAR2(50 CHAR);
        l_error_out     t_error_out;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' || i_id_print_list_job;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        l_result := t_rec_print_list_job();
    
        -- getting context data of this print list job
        SELECT v.context_data
          INTO l_context_data
          FROM v_print_list_context_data v
         WHERE v.id_print_list_job = i_id_print_list_job;
    
        -- getting information of this referral
        g_error  := 'l_id_ref / ' || l_params;
        l_id_ref := to_number(l_context_data);
    
        l_params := l_params || ' id_ref=' || l_id_ref;
    
        g_error  := 'Call pk_p1_external_request.get_flg_type / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => l_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => l_error_out);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting flg type desc
        g_error         := 'Call pk_sysdomain.get_domain / FLG_TYPE=' || l_ref_row.flg_type || ' / ' || l_params;
        l_flg_type_desc := pk_sysdomain.get_domain(i_code_dom => pk_ref_constant.g_p1_exr_flg_type,
                                                   i_val      => l_ref_row.flg_type,
                                                   i_lang     => i_lang);
    
        -- getting requested date desc
        g_error       := 'Call pk_date_utils.dt_chr_tsz / ' || l_params;
        l_dt_req_desc := pk_date_utils.dt_chr_tsz(i_lang => i_lang, i_date => l_ref_row.dt_requested, i_prof => i_prof);
    
        -- Setting the output type
        g_error                    := 'Setting output / ' || l_params;
        l_result.id_print_list_job := i_id_print_list_job;
        l_result.title_desc        := pk_message.get_message(i_lang, i_prof, 'P1_HEADER_M001');
        l_result.subtitle_desc     := l_flg_type_desc || ' (' || l_dt_req_desc || ')';
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN t_rec_print_list_job();
    END tf_get_print_job_info;

    /**
    * Compares if a print list job context data is similar to the array of print list jobs
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_print_job_context_data       Print list job context data
    * @param   i_print_list_jobs              Array of print list job identifiers
    *
    * @return  table_number                   Arry of print list jobs that are similar
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_compare_print_jobs';
        l_params VARCHAR2(1000 CHAR);
        l_result table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_job_context_data=' || i_print_job_context_data ||
                    ' i_print_list_jobs=' || pk_utils.to_string(i_print_list_jobs);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- getting all id_print_list_jobs from i_print_list_jobs that have the same context_data (id_ref) as i_print_list_job
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v2.id_print_list_job
                  FROM v_print_list_context_data v2
                  JOIN TABLE(CAST(i_print_list_jobs AS table_number)) t
                    ON t.column_value = v2.id_print_list_job
                 WHERE dbms_lob.compare(v2.context_data, i_print_job_context_data) = 0) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN table_number();
    END tf_compare_print_jobs;

    /**
    * Gets the reports and referral information available to print the referrals
    * Used by reports, in print button
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_id_tasks                     Array of referral identifiers
    * @param   i_id_report                    Report identifier
    *
    * @return  t_coll_print_report            Array with all the reports and referral information available for printing
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-10-2014
    */
    FUNCTION tf_get_print_reports_int
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_tasks  IN table_varchar,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN t_coll_print_report IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'tf_get_print_reports_int';
        l_params VARCHAR2(1000 CHAR);
    
        l_id_ref            p1_external_request.id_external_request%TYPE;
        l_ref_row           p1_external_request%ROWTYPE;
        l_result            t_coll_print_report;
        l_error_out         t_error_out;
        l_ref_compl_options t_coll_ref_completion := t_coll_ref_completion();
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_tasks=' || pk_utils.to_string(i_id_tasks) ||
                    ' i_id_report=' || i_id_report;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- getting referral identifier
        l_id_ref := i_id_tasks(1); -- there is only one referral (can only select one referral at a time)
    
        -- getting referral data
        g_error  := 'l_ref_row.flg_status=' || l_ref_row.flg_status || ' / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => l_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => l_error_out);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error             := 'Call get_compl_options_tf / ' || l_params;
        l_ref_compl_options := get_compl_options_tf(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => l_ref_row.id_patient,
                                                    i_epis         => l_ref_row.id_episode,
                                                    i_codification => table_number(), -- not needed for print options
                                                    i_inst_dest    => table_number(), -- not needed for print options
                                                    i_flg_type     => l_ref_row.flg_type,
                                                    i_spec         => l_ref_row.id_speciality);
    
        -- getting reports available to print the referral identifiers
        -- note: table_varchar array is **used by flash**, in order to generate the report. Any changes must be done according to flash
        g_error := 'SELECT t_rec_print_report() / ' || l_params;
        SELECT t_rec_print_report(t.id_reports,
                                  pk_translation.get_translation(i_lang      => i_lang,
                                                                 i_code_mess => pk_ref_constant.g_reports_code ||
                                                                                t.id_reports),
                                  pk_alert_constant.g_yes,
                                  table_varchar(l_ref_row.id_external_request,
                                                t.id_reports,
                                                t.flg_type,
                                                t.id_ref_completion,
                                                t.flg_ald,
                                                t.flg_bdnp) -- used by flash in order to generate the report. Any changes must be done according to flash
                                  )
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_reports, t.flg_type, t.id_ref_completion, t.flg_ald, t.flg_bdnp
                  FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
                 WHERE t.flg_type = pk_ref_constant.g_ref_compl_type_p -- print options only
                   AND t.flg_active = pk_ref_constant.g_yes -- only active options
                   AND t.id_reports = nvl(i_id_report, t.id_reports)
                   AND l_ref_row.flg_status = pk_ref_constant.g_p1_status_o -- reports returned when referral is in state "Being created"
                      -- duplicata and reprint options returned below
                   AND t.id_ref_completion NOT IN
                       (pk_ref_constant.g_ref_compl_duplicata, pk_ref_constant.g_ref_compl_reprint)
                UNION ALL
                -- duplicata report
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_reports, t.flg_type, t.id_ref_completion, t.flg_ald, t.flg_bdnp
                  FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
                 WHERE t.flg_type = pk_ref_constant.g_ref_compl_type_p -- print options only
                   AND t.flg_active = pk_ref_constant.g_yes -- only active options
                   AND t.id_reports = nvl(i_id_report, t.id_reports)
                   AND t.id_ref_completion = pk_ref_constant.g_ref_compl_duplicata
                UNION ALL
                -- reprint report
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.id_reports, t.flg_type, t.id_ref_completion, t.flg_ald, t.flg_bdnp
                  FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
                 WHERE t.flg_type = pk_ref_constant.g_ref_compl_type_p -- print options only
                   AND t.flg_active = pk_ref_constant.g_yes -- only active options
                   AND t.id_ref_completion = pk_ref_constant.g_ref_compl_reprint) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN t_coll_print_report();
    END tf_get_print_reports_int;

    /**
    * Gets the reports available to print the referrals
    * Used by reports, in print button
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_id_tasks                     Array of referral identifiers
    *
    * @return  t_coll_print_report            Array with all the reports available for printing
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-10-2014
    */
    FUNCTION tf_get_print_reports
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_tasks IN table_varchar
    ) RETURN t_coll_print_report IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_get_print_reports';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_tasks=' || pk_utils.to_string(i_id_tasks);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        RETURN tf_get_print_reports_int(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_id_tasks  => i_id_tasks,
                                        i_id_report => NULL -- all the reports
                                        );
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN t_coll_print_report();
    END tf_get_print_reports;

    /**
    * Gets the reports and referral information available to print the referrals
    * Used by reports, in print button
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_id_tasks                     Array of referral identifiers
    * @param   i_id_report                    Report identifier
    *
    * @return  t_rec_print_report             Report and referral information available for printing
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-10-2014
    */
    FUNCTION tf_get_print_report
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_tasks  IN table_varchar,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN t_rec_print_report IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_get_print_report';
        l_params            VARCHAR2(1000 CHAR);
        l_coll_print_report t_coll_print_report;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_tasks=' || pk_utils.to_string(i_id_tasks);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        l_coll_print_report := tf_get_print_reports_int(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_id_tasks  => i_id_tasks,
                                                        i_id_report => i_id_report);
    
        RETURN l_coll_print_report(1);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN t_rec_print_report();
    END tf_get_print_report;

    /**
    * Adds the referral to the print list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_id_refs             List of referral identifiers to  be added to the print list
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    List of print list job identifiers
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_refs         IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_list_jobs';
        l_params           VARCHAR2(1000 CHAR);
        l_context_data     table_clob;
        l_print_list_areas table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_id_refs=' || pk_utils.to_string(i_id_refs);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
    
        -- getting context data
        IF i_id_refs.count = 0
           OR i_id_refs.count != i_print_arguments.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_context_data.extend(i_id_refs.count);
        l_print_list_areas.extend(i_id_refs.count);
        FOR i IN 1 .. i_id_refs.count
        LOOP
            l_context_data(i) := to_clob(i_id_refs(i));
            l_print_list_areas(i) := pk_print_list_db.g_print_list_area_ref;
        END LOOP;
    
        -- call function to add job to the print list
        g_error  := 'Call pk_print_list_db.add_print_jobs / ' || l_params;
        g_retval := pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_patient          => i_patient,
                                                    i_episode          => i_episode,
                                                    i_print_list_areas => l_print_list_areas,
                                                    i_context_data     => l_context_data,
                                                    i_print_arguments  => i_print_arguments,
                                                    o_print_list_jobs  => o_print_list_job,
                                                    o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
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
    END add_print_list_jobs;

    /**
    * Gets referral completion options.
    * Pop-up reformulation after development print list functionality
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_epis               Episode identifier
    * @param   i_codification       Codification identifiers   
    * @param   i_inst_dest          Referrals destination institutions
    * @param   i_flg_type           Referral type    
    * @param   i_spec               Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   o_options            Referrals completion options
    * @param   o_print_options      Reports available to print the referral
    * @param   o_flg_show_popup     Flag that indicates if the pop-up is shown or not. If not, default option is assumed
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_type           {*} 'C' Consultation 
    *                               {*} 'A' Lab tests 
    *                               {*} 'I' Imaging exams
    *                               {*} 'E' Other exams
    *                               {*} 'P' Procedure
    *                               {*} 'F' Rehab
    *
    * @value   o_flg_show_popup     {*} 'Y' the pop-up is shown 
    *                               {*} 'N' otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-10-2014
    */
    FUNCTION get_completion_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_codification   IN table_number,
        i_inst_dest      IN table_number,
        i_flg_type       IN p1_external_request.flg_type%TYPE,
        i_spec           IN ref_completion_cfg.id_mcdt%TYPE,
        o_options        OUT pk_types.cursor_type,
        o_print_options  OUT pk_types.cursor_type,
        o_flg_show_popup OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        g_compl_opt_save_print      CONSTANT VARCHAR2(100 CHAR) := 'SAVE_PRINT';
        g_compl_opt_save_print_list CONSTANT VARCHAR2(100 CHAR) := 'SAVE_PRINT_LIST';
        g_compl_opt_save            CONSTANT VARCHAR2(100 CHAR) := 'SAVE';
        l_func_name                 CONSTANT VARCHAR2(24 CHAR) := 'get_completion_options';
    
        l_params                   VARCHAR2(1000 CHAR);
        l_ref_compl_options        t_coll_ref_completion := t_coll_ref_completion();
        l_count                    PLS_INTEGER;
        l_default_print_option     sys_list.internal_name%TYPE;
        l_show_concl_popup_ref     VARCHAR2(1 CHAR);
        l_flg_can_add              VARCHAR2(1 CHAR);
        l_has_active_print_options VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_epis=' || i_epis ||
                    ' i_codification=' || pk_utils.to_string(i_codification) || ' i_inst_dest=' ||
                    pk_utils.to_string(i_inst_dest) || ' i_flg_type=' || i_flg_type || ' i_spec=' || i_spec;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_flg_show_popup := pk_ref_constant.g_yes;
    
        -- configs
        l_show_concl_popup_ref := nvl(pk_sysconfig.get_config(pk_ref_constant.g_sc_show_concl_popup_ref, i_prof),
                                      pk_ref_constant.g_yes);
    
        -- check if this professional can add items to the print list
        g_retval := pk_print_list_db.check_func_can_add(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        o_flg_can_add => l_flg_can_add,
                                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting all referral available completion options
        g_error             := 'Call get_compl_options_tf / ' || l_params;
        l_ref_compl_options := get_compl_options_tf(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_epis         => i_epis,
                                                    i_codification => i_codification,
                                                    i_inst_dest    => i_inst_dest,
                                                    i_flg_type     => i_flg_type,
                                                    i_spec         => i_spec,
                                                    -- remove duplicata and reprint options... must appear in report button, but not in completion options pop-up;
                                                    i_ref_compl_excep => table_number(pk_ref_constant.g_ref_compl_duplicata,
                                                                                      pk_ref_constant.g_ref_compl_reprint));
    
        -- check if print option is the default option
        g_error := 'SELECT count(1) 1 / ' || l_params;
        SELECT /*+opt_estimate (table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
         WHERE flg_type = pk_ref_constant.g_ref_compl_type_p
           AND flg_default = pk_ref_constant.g_active
           AND flg_active = pk_ref_constant.g_yes;
    
        IF l_count = 1
        THEN
            -- getting default option of print list configured in sys_list data model
            g_error  := 'Call pk_print_list_db.get_print_list_def_option / ' || l_params;
            g_retval := pk_print_list_db.get_print_list_def_option(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_print_list_area => pk_print_list_db.g_print_list_area_ref,
                                                                   o_default_option  => l_default_print_option,
                                                                   o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- check if default option is print list option, and if professional can print
            g_error := 'l_default_print_option=' || l_default_print_option || ' / ' || l_params;
            IF l_default_print_option = g_compl_opt_save_print_list
               AND l_flg_can_add = pk_ref_constant.g_no
            THEN
                -- professional can't print and default option is a printable option, change default to g_compl_opt_save_print
                l_default_print_option := g_compl_opt_save_print;
            END IF;
        
            l_has_active_print_options := pk_ref_constant.g_yes;
        
        ELSE
            -- check if exists at least one print option available
            g_error := 'SELECT count(1) 2 / ' || l_params;
            SELECT /*+opt_estimate (table t rows=1)*/
             COUNT(1)
              INTO l_count
              FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
             WHERE flg_type = pk_ref_constant.g_ref_compl_type_p
               AND flg_active = pk_ref_constant.g_yes;
        
            IF l_count > 0
            THEN
                l_has_active_print_options := pk_ref_constant.g_yes;
            ELSE
                l_has_active_print_options := pk_ref_constant.g_no;
            END IF;
        END IF;
    
        -- check if there is any active default option
        g_error := 'SELECT count(1) 1 / ' || l_params;
        SELECT /*+opt_estimate (table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
         WHERE flg_default = pk_ref_constant.g_active
           AND flg_active = pk_ref_constant.g_yes;
    
        IF l_count = 0
        THEN
            -- setting save as default option
            l_default_print_option := g_compl_opt_save;
        END IF;
    
        -- open cursor with the options to complete the referral
        g_error := 'OPEN o_options FOR / ' || l_params;
        OPEN o_options FOR
            SELECT DISTINCT t.id_ref_completion, -- distinct because there may be several options to the same id_reports
                            t.val_option,
                            t.desc_option,
                            CASE t.flg_active
                                WHEN pk_ref_constant.g_no THEN
                                 pk_translation.get_translation(i_lang, t.code_warning)
                                ELSE
                                 NULL
                            END warning_option, -- warning shown if option is inactive
                            t.flg_type,
                            CASE
                                 WHEN l_default_print_option IS NULL THEN
                                  flg_default
                                 ELSE
                                  decode(t.sys_list_internal_name,
                                         l_default_print_option,
                                         pk_ref_constant.g_active,
                                         pk_ref_constant.g_inactive)
                             END flg_default,
                            t.flg_active,
                            t.rank
              FROM (
                    -- getting print options 
                    SELECT CASE flg_type
                                WHEN pk_ref_constant.g_ref_compl_type_p THEN
                                 NULL
                                ELSE
                                 t.id_ref_completion
                            END id_ref_completion, -- only return id_ref_completion if it is not a print option
                            tt.flg_context val_option,
                            tt.desc_list desc_option,
                            tt.sys_list_internal_name,
                            t.code_warning,
                            t.flg_type,
                            t.flg_default,
                            -- flg_active                            
                            CASE t.flg_active
                                WHEN pk_ref_constant.g_yes THEN
                                 CASE tt.sys_list_internal_name
                                     WHEN g_compl_opt_save_print_list THEN
                                      decode(l_flg_can_add, pk_ref_constant.g_no, pk_ref_constant.g_no, t.flg_active)
                                     ELSE
                                      t.flg_active
                                 END
                                ELSE
                                 pk_ref_constant.g_no
                            END flg_active,
                            tt.rank rank
                    ----------------
                      FROM (SELECT /*+opt_estimate (table t rows=1)*/
                              t.id_ref_completion,
                              NULL                       AS code_warning, -- warning of print options displayed below
                              t.flg_type,
                              t.flg_default,
                              l_has_active_print_options flg_active
                               FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
                              WHERE t.flg_type = pk_ref_constant.g_ref_compl_type_p
                             UNION ALL
                             SELECT /*+opt_estimate (table t rows=1)*/
                              t.id_ref_completion, t.code_warning, t.flg_type, t.flg_default, t.flg_active
                               FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
                              WHERE t.flg_type != pk_ref_constant.g_ref_compl_type_p) t
                    ----------------
                      JOIN ref_compl_sys_list s
                        ON s.id_ref_completion = t.id_ref_completion
                      JOIN TABLE(CAST(pk_sys_list.tf_sys_list_values(i_lang => i_lang, i_prof => i_prof, i_internal_name => pk_ref_constant.g_slg_ref_compl_options) AS t_table_sys_list)) tt
                        ON s.id_sys_list = tt.id_sys_list) t
             ORDER BY t.rank, t.desc_option;
    
        -- getting referral printable options and outputs the name of the report
        g_error := 'OPEN o_print_options FOR / ' || l_params;
        OPEN o_print_options FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_ref_completion,
             NULL val_option,
             pk_translation.get_translation(i_lang, pk_ref_constant.g_reports_code || t.id_reports) desc_option,
             CASE t.flg_active
                 WHEN pk_ref_constant.g_no THEN
                  pk_translation.get_translation(i_lang, t.code_warning)
                 ELSE
                  NULL
             END warning_option, -- warning shown if option is inactive
             t.id_reports,
             t.flg_type,
             t.flg_default,
             t.flg_active,
             t.flg_ald,
             t.flg_bdnp
              FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
             WHERE t.flg_type = pk_ref_constant.g_ref_compl_type_p;
    
        -- setting o_flg_show_popup
        g_error := 'l_show_concl_popup_ref=' || l_show_concl_popup_ref || ' / ' || l_params;
        IF l_show_concl_popup_ref = pk_ref_constant.g_no
        THEN
            -- check if pop-up will be displayed (check completion options available)
        
            -- check print options (there must exist only one option (if any)
            g_error := 'check print options / SELECT COUNT(1) / ' || l_params;
            SELECT COUNT(1)
              INTO l_count
              FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
             WHERE t.flg_type = pk_ref_constant.g_ref_compl_type_p
               AND t.flg_active = pk_ref_constant.g_yes;
        
            IF l_count > 1
            THEN
                o_flg_show_popup := pk_ref_constant.g_yes;
            ELSE
            
                -- check if there are options besides print and save
                g_error := 'check if there are options besides print and save / SELECT COUNT(1) / ' || l_params;
                SELECT COUNT(1)
                  INTO l_count
                  FROM TABLE(CAST(l_ref_compl_options AS t_coll_ref_completion)) t
                 WHERE t.flg_type NOT IN (pk_ref_constant.g_ref_compl_type_p, pk_ref_constant.g_ref_compl_type_s)
                   AND t.flg_active = pk_ref_constant.g_yes;
            
                IF l_count > 0
                THEN
                    o_flg_show_popup := pk_ref_constant.g_yes;
                ELSE
                    o_flg_show_popup := pk_ref_constant.g_no;
                END IF;
            
            END IF;
        
        ELSE
            -- pop-up must always be displayed
            o_flg_show_popup := pk_ref_constant.g_yes;
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
    END get_completion_options;

    /**
    * Returns reports information available for the referral area
    * Used in print button by flash, in order to distinguish reports of referral area and general reports
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   o_cur_reports        Cursor with referral reports information:     
    *                               - id_reports: referral report identifiers
    *                               - column_name: column name from cursor PK_P1_EXT_SYS.get_pat_p1.o_detail, that has the value that flash must read, in order to enable/disable option in report button
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   16-10-2014
    */
    FUNCTION get_available_reports
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_cur_reports OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_available_reports / i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
        OPEN o_cur_reports FOR
            SELECT DISTINCT id_reports,
                            CASE c.id_ref_completion
                                WHEN pk_ref_constant.g_ref_compl_duplicata THEN
                                 'ID_REP_DUPLICATA'
                                WHEN pk_ref_constant.g_ref_compl_reprint THEN
                                 'ID_REP_REPRINT'
                                ELSE
                                 NULL
                            END column_name
              FROM ref_completion_cfg c
             WHERE id_reports IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cur_reports);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_AVAILABLE_REPORTS',
                                                     o_error    => o_error);
    END get_available_reports;

    /**
    * Cancel all print items from the printing list (referral area)
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_id_patient         Patient identifier
    * @param   i_id_episode         Episode identifier
    * @param   i_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   23-10-2014
    */
    FUNCTION set_print_jobs_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN p1_external_request.id_patient%TYPE,
        i_id_episode IN p1_external_request.id_episode%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_print_jobs_cancel';
        l_params             VARCHAR2(1000 CHAR);
        l_id_print_list_jobs table_number;
        l_print_list_jobs    table_number;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient ||
                    ' i_id_episode=' || i_id_episode || ' i_id_ref=' || i_id_ref;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        -- getting id_print_list_job related to this referral
        g_error              := 'Call pk_print_list_db.get_similar_print_list_jobs / ' || l_params;
        l_id_print_list_jobs := pk_print_list_db.get_similar_print_list_jobs(i_lang                   => i_lang,
                                                                             i_prof                   => i_prof,
                                                                             i_patient                => i_id_patient,
                                                                             i_episode                => i_id_episode,
                                                                             i_print_list_area        => pk_print_list_db.g_print_list_area_ref,
                                                                             i_print_job_context_data => to_clob(i_id_ref));
    
        IF l_id_print_list_jobs IS NOT NULL
           AND l_id_print_list_jobs.count > 0
        THEN
        
            g_error  := 'Call pk_print_list_db.set_print_jobs_cancel / ' || l_params;
            g_retval := pk_print_list_db.set_print_jobs_cancel(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_print_list_job => l_id_print_list_jobs,
                                                               o_id_print_list_job => l_print_list_jobs,
                                                               o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END set_print_jobs_cancel;

    /**
    * Complete all print items from the printing list (referral area)
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_id_patient         Patient identifier
    * @param   i_id_episode         Episode identifier
    * @param   i_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   23-10-2014
    */
    FUNCTION set_print_jobs_complete
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN p1_external_request.id_patient%TYPE,
        i_id_episode IN p1_external_request.id_episode%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_print_jobs_complete';
        l_params             VARCHAR2(1000 CHAR);
        l_id_print_list_jobs table_number;
        l_print_list_jobs    table_number;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient ||
                    ' i_id_episode=' || i_id_episode || ' i_id_ref=' || i_id_ref;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        -- getting id_print_list_job related to this referral
        g_error              := 'Call pk_print_list_db.get_similar_print_list_jobs / ' || l_params;
        l_id_print_list_jobs := pk_print_list_db.get_similar_print_list_jobs(i_lang                   => i_lang,
                                                                             i_prof                   => i_prof,
                                                                             i_patient                => i_id_patient,
                                                                             i_episode                => i_id_episode,
                                                                             i_print_list_area        => pk_print_list_db.g_print_list_area_ref,
                                                                             i_print_job_context_data => to_clob(i_id_ref));
    
        IF l_id_print_list_jobs IS NOT NULL
           AND l_id_print_list_jobs.count > 0
        THEN
        
            g_error  := 'Call pk_print_list_db.set_print_jobs_complete / ' || l_params;
            g_retval := pk_print_list_db.set_print_jobs_complete(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_id_print_list_job => l_id_print_list_jobs,
                                                                 o_id_print_list_job => l_print_list_jobs,
                                                                 o_error             => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END set_print_jobs_complete;

    /**
    * Get new print arguments to the reports that need to be regenerated
    * Used by reports (pk_print_tool) when sending report to the printer (after selecting print button)    
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   io_print_arguments          Json string to be printed
    * @param   o_flg_regenerate_report     Flag indicating if the report needs to be regenerated or not
    * @param   o_error                     Error information
    *
    * @value   o_flg_regenerate_report     {*} Y- report needs to be regenerated {*} N- otherwise
    *
    * @RETURN  boolean                     TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   27-10-2014
    */
    FUNCTION get_print_args_to_regen_report
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        io_print_arguments      IN OUT print_list_job.print_arguments%TYPE,
        o_flg_regenerate_report OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(40 CHAR) := 'get_print_args_to_regen_report';
        l_params VARCHAR2(1000 CHAR);
        l_json   json_object_t;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_flg_regenerate_report := pk_ref_constant.g_no;
    
        -- func
        -- search for parameter 'PRINT_TYPE'
        l_json := json_object_t(io_print_arguments);
        IF l_json.has('PRINT_TYPE')
        THEN
            -- if found, replace value of parameter PRINT_TYPE by 1
            g_error := 'Set PRINT_TYPE=1 / ' || l_params;
            l_json.put('PRINT_TYPE', 1);
            o_flg_regenerate_report := pk_ref_constant.g_yes;
            io_print_arguments      := l_json.to_string();
        ELSE
            -- parameter not found, do not re-generate the report
            g_error                 := 'No PRINT_TYPE found / ' || l_params;
            o_flg_regenerate_report := pk_ref_constant.g_no;
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
    END get_print_args_to_regen_report;

    /** @headcom
    * Public Function. Return number to be used in printed referrals.   
    *
    * @param      i_lang         professional language
    * @param      i_prof         professional, institution and software ids
    * @param      i_ext_req      referral id
    * @param      o_number       referral number
    * @param      O_ERROR        erro
    *
    * @return     boolean
    * @author     Joao Sa
    * @version    0.1
    * @since      2008/07/17
    * @modified    
    */
    FUNCTION get_referral_number
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_dt_req            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        o_number            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_referral_number';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode ||
                    ' i_dt_req=' || i_dt_req || ' i_id_ref_completion=' || i_id_ref_completion;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call pk_ref_orig_phy.get_referral_number / ' || l_params;
        g_retval := pk_ref_orig_phy.get_referral_number(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_episode        => i_id_episode,
                                                        i_dt_req            => i_dt_req,
                                                        i_id_ref_completion => i_id_ref_completion,
                                                        o_number            => o_number,
                                                        o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
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
    END get_referral_number;

    /**
    * Gets **active** referrals information related to this episode
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_episode             Episode identifier
    * @param   o_coll_ref_info          Referral information
    * @param   o_error                  An error message, set when return=false    
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Ana Monteiro
    * @since   30-04-2015
    */
    FUNCTION get_referrals_by_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN p1_external_request.id_episode%TYPE,
        o_coll_ref_info OUT t_coll_ref_info,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_referrals_by_epis';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        -- Destination facility; Type of request (Specialty/List of MCDTs); Referral reason
        SELECT t.id_external_request,
               t.id_patient,
               t.dt_requested,
               pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, t.flg_type, i_lang) AS desc_ref_type,
               t.desc_items,
               pk_translation.get_translation(i_lang => i_lang, i_code_mess => t.code_institution) AS desc_inst_dest,
               (SELECT d.text
                  FROM p1_detail d
                 WHERE d.id_external_request = t.id_external_request
                   AND d.flg_type = pk_ref_constant.g_detail_type_jstf -- reason
                   AND d.flg_status = pk_ref_constant.g_active) AS reason,
               pk_prof_utils.get_detail_signature(i_lang, i_prof, NULL, t.dt_requested, t.id_prof_requested) signature
          BULK COLLECT
          INTO o_coll_ref_info
          FROM (
                -- Appointments
                SELECT p.id_external_request,
                        p.id_patient,
                        p.flg_type,
                        pk_translation.get_translation(i_lang => i_lang, i_code_mess => s.code_speciality) AS desc_items,
                        i.code_institution,
                        p.dt_requested,
                        p.id_prof_requested
                  FROM p1_external_request p
                  JOIN p1_speciality s
                    ON (p.id_speciality = s.id_speciality)
                  JOIN institution i
                    ON (i.id_institution = p.id_inst_dest)
                 WHERE p.id_episode = i_id_episode
                   AND p.flg_status NOT IN (pk_ref_constant.g_p1_status_c, pk_ref_constant.g_p1_status_o)
                   AND p.flg_type = pk_ref_constant.g_p1_type_c -- appointments
                UNION ALL
                -- Lab tests
                SELECT p.id_external_request,
                        p.id_patient,
                        p.flg_type,
                        (SELECT listagg(pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                                  i_prof                      => i_prof,
                                                                                  i_analysis_code_translation => pk_ref_constant.g_analysis_code ||
                                                                                                                 pa.id_analysis,
                                                                                  i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                                 pa.id_sample_type,
                                                                                  i_dep_clin_serv             => NULL),
                                        '; ') within GROUP(ORDER BY pk_lab_tests_api_db.get_alias_translation(i_lang => i_lang, i_prof => i_prof, i_analysis_code_translation => pk_ref_constant.g_analysis_code || pa.id_analysis, i_sample_code_translation => pk_ref_constant.g_sample_type_code || pa.id_sample_type, i_dep_clin_serv => NULL))
                           FROM p1_exr_analysis pa
                          WHERE pa.id_external_request = p.id_external_request) AS desc_items,
                        i.code_institution,
                        p.dt_requested,
                        p.id_prof_requested
                  FROM p1_external_request p
                  JOIN institution i
                    ON (i.id_institution = p.id_inst_dest)
                 WHERE p.id_episode = i_id_episode
                   AND p.flg_status NOT IN (pk_ref_constant.g_p1_status_c, pk_ref_constant.g_p1_status_o)
                   AND p.flg_type = pk_ref_constant.g_p1_type_a -- lab tests
                UNION ALL
                -- Imaging exams and Other exams
                SELECT p.id_external_request,
                        p.id_patient,
                        p.flg_type,
                        (SELECT listagg(pk_translation.get_translation(i_lang, pk_ref_constant.g_exam_code || pe.id_exam),
                                        '; ') within GROUP(ORDER BY pk_translation.get_translation(i_lang, pk_ref_constant.g_exam_code || pe.id_exam))
                           FROM p1_exr_exam pe
                          WHERE pe.id_external_request = p.id_external_request) AS desc_items,
                        i.code_institution,
                        p.dt_requested,
                        p.id_prof_requested
                  FROM p1_external_request p
                  JOIN institution i
                    ON (i.id_institution = p.id_inst_dest)
                 WHERE p.id_episode = i_id_episode
                   AND p.flg_status NOT IN (pk_ref_constant.g_p1_status_c, pk_ref_constant.g_p1_status_o)
                   AND p.flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i) -- Imaging exams and Other exams
                UNION ALL
                -- Procedures and Rehabilitation
                SELECT p.id_external_request,
                        p.id_patient,
                        p.flg_type,
                        (SELECT listagg(pk_procedures_api_db.get_alias_translation(i_lang,
                                                                                   i_prof,
                                                                                   pk_ref_constant.g_interv_code ||
                                                                                   pi.id_intervention,
                                                                                   NULL),
                                        '; ') within GROUP(ORDER BY pk_procedures_api_db.get_alias_translation(i_lang, i_prof, pk_ref_constant.g_interv_code || pi.id_intervention, NULL))
                           FROM p1_exr_intervention pi
                          WHERE pi.id_external_request = p.id_external_request) AS desc_items,
                        i.code_institution,
                        p.dt_requested,
                        p.id_prof_requested
                  FROM p1_external_request p
                  JOIN institution i
                    ON (i.id_institution = p.id_inst_dest)
                 WHERE p.id_episode = i_id_episode
                   AND p.flg_status NOT IN (pk_ref_constant.g_p1_status_c, pk_ref_constant.g_p1_status_o)
                   AND p.flg_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f) -- procedures and rehab
                ) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_referrals_by_epis;

    FUNCTION send_ref_to_bdnp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_ref   IN p1_external_request.id_external_request%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur_staus
        (
            x_prof professional.id_professional%TYPE,
            x_ref  p1_external_request.id_external_request%TYPE
        ) IS
            SELECT flg_status
              FROM p1_external_request
             WHERE id_external_request = i_ref
               AND id_prof_requested = i_prof.id
               AND flg_migrated = pk_ref_constant.g_bdnp_msg_e; -- erro
    
        CURSOR c_cur_tracking
        (
            x_prof professional.id_professional%TYPE,
            x_ref  p1_external_request.id_external_request%TYPE
        ) IS
            SELECT id_tracking
              FROM p1_tracking pt
              JOIN p1_external_request per
                ON (pt.id_external_request = per.id_external_request AND pt.id_professional = per.id_prof_requested AND
                   per.flg_status = pt.ext_req_status)
             WHERE pt.id_external_request = i_ref
               AND pt.id_professional = i_prof.id
               AND pt.ext_req_status = pk_ref_constant.g_p1_status_c
               AND pt.flg_type = pk_ref_constant.g_tracking_type_s;
    
        l_bdnp_available      sys_config.value%TYPE;
        l_status              p1_external_request.flg_status%TYPE;
        l_tracking            p1_tracking.id_tracking%TYPE;
        l_bdnp_presc_tracking bdnp_presc_tracking%ROWTYPE;
        l_date                bdnp_presc_tracking.dt_presc_tracking%TYPE;
    
    BEGIN
        g_error                                 := 'Init';
        l_bdnp_available                        := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                                       pk_ref_constant.g_no);
        l_date                                  := current_timestamp;
        l_bdnp_presc_tracking.id_presc          := i_ref;
        l_bdnp_presc_tracking.flg_presc_type    := pk_ref_constant.g_bdnp_ref_type;
        l_bdnp_presc_tracking.dt_presc_tracking := l_date;
        l_bdnp_presc_tracking.dt_event          := l_date;
        l_bdnp_presc_tracking.id_institution    := i_prof.institution;
    
        IF l_bdnp_available = pk_ref_constant.g_no
        THEN
            RETURN FALSE;
        ELSE
            OPEN c_cur_staus(i_prof.id, i_ref);
            FETCH c_cur_staus
                INTO l_status;
        
            g_found := c_cur_staus%FOUND;
        
            IF NOT g_found
            THEN
                RAISE g_exception;
            END IF;
            CLOSE c_cur_staus;
        
            IF l_status = pk_ref_constant.g_p1_status_p
            THEN
                -- RESENDED INSERT MESSAGE INTO BDNP
                l_bdnp_presc_tracking.flg_event_type := pk_ref_constant.g_bdnp_event_type_ri;
            
                g_error := 'CALL pk_ia_event_prescription.prescription_mcdt_new i_id_external_request' || i_ref;
                pk_ia_event_prescription.prescription_mcdt_resend_new(i_id_external_request => i_ref,
                                                                      i_id_institution      => i_prof.institution);
            
                g_error  := 'CALL pk_bdnp.set_bdnp_presc_tracking';
                g_retval := pk_bdnp.set_bdnp_presc_tracking(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_bdnp_presc_tracking => l_bdnp_presc_tracking,
                                                            o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSIF l_status = pk_ref_constant.g_p1_status_c
            THEN
                -- RESENDED DELETE MESSAGE INTO BDNP
                l_bdnp_presc_tracking.flg_event_type := pk_ref_constant.g_bdnp_event_type_rc;
            
                OPEN c_cur_tracking(i_prof.id, i_ref);
                FETCH c_cur_tracking
                    INTO l_tracking;
            
                IF c_cur_tracking%NOTFOUND
                THEN
                    RAISE g_exception;
                END IF;
                CLOSE c_cur_tracking;
            
                g_error := 'CALL pk_ia_event_prescription.prescription_mcdt_cancel' || l_tracking;
                pk_ia_event_prescription.prescription_mcdt_re_cancel(i_id_tracking    => l_tracking,
                                                                     i_id_institution => i_prof.institution);
            
                g_error  := 'CALL pk_bdnp.set_bdnp_presc_tracking';
                g_retval := pk_bdnp.set_bdnp_presc_tracking(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_bdnp_presc_tracking => l_bdnp_presc_tracking,
                                                            o_error               => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
            
                g_error := 'l_status Should be P or C l_status=' || l_status;
                RETURN FALSE;
            END IF;
        
            g_error  := 'CALL pk_ref_api.set_referral_flg_migrated i_id_external_request=' || i_ref;
            g_retval := pk_ref_api.set_referral_flg_migrated(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_external_request => i_ref,
                                                             i_flg_migrated        => pk_ref_constant.g_bdnp_mig_n,
                                                             o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SEND_REF_TO_BDNP',
                                                     o_error    => o_error);
    END send_ref_to_bdnp;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_ext_sys;
/
