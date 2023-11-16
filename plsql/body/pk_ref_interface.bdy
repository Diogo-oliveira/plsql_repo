/*-- Last Change Revision: $Rev: 2027583 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_interface AS

    g_error VARCHAR2(1000 CHAR);
    --g_sysdate_tstz  TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    /**
    * Sets professional interface
    *
    * @param   I_PROF         Professional institution and software
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION set_prof_interface(i_prof IN profissional) RETURN profissional IS
        l_id NUMBER;
    BEGIN
        g_error := 'Init set_prof_interface / PROFISSIONAL=' || pk_utils.to_string(i_prof);
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Calling pk_sysconfig.get_config ' || pk_ref_constant.g_sc_intf_prof_id;
        l_id    := to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_intf_prof_id,
                                                     i_prof.institution,
                                                     i_prof.software));
    
        RETURN profissional(l_id, i_prof.institution, i_prof.software);
    
    END set_prof_interface;

    /**
    * Inserts schedule into tables
    *
    * @param I_LANG         Lingua registada como preferencia do profissional
    * @param I_PROF         Profissional q regista
    * @param I_PAT          Id do paciente
    * @param i_trans_id     Id da transacao pode ir a null
    * @param O_ERROR        Erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    /*
    FUNCTION set_schedule
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN profissional,
        i_sch_row  IN schedule%ROWTYPE,
        i_pat      IN p1_external_request.id_patient%TYPE,
        i_trans_id IN VARCHAR2,
        o_sched    OUT table_number,
        o_error    OUT t_error_out
        
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variable
        l_transaction_id VARCHAR2(4000);
        l_id_ext         sch_api_map_ids.id_schedule_ext%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_schedule / id_prof_requests=' || i_sch_row.id_prof_requests || ' id_dcs_requested=' ||
                   i_sch_row.id_dcs_requested || ' flg_request_type=' || i_sch_row.flg_request_type ||
                   ' flg_schedule_via=' || i_sch_row.flg_schedule_via;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := current_timestamp;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_trans_id, i_prof);
    
        --creates a new schedule
        --IF NOT pk_schedule_api_upstream.create_schedule(i_lang              => i_lang,
                                                        i_prof             => i_prof,
                                                        i_event_id         => pk_ref_constant.g_sch_event_1,
                                                        i_professional_id  => i_sch_row.id_prof_requests, -- testar
                                                        i_id_patient       => i_pat,
                                                        i_id_dep_clin_serv => i_sch_row.id_dcs_requested,
                                                        i_dt_begin_tstz    => i_sch_row.dt_begin_tstz,
                                                        i_dt_end_tstz      => NULL, -- testar
                                                        i_flg_vacancy      => i_sch_row.flg_vacancy,
                                                        i_id_episode       => NULL,
                                                        i_flg_rqst_type    => i_sch_row.flg_request_type,
                                                        i_flg_sch_via      => i_sch_row.flg_schedule_via,
                                                        i_sch_notes        => i_sch_row.schedule_notes,
                                                        i_id_inst_requests  => i_sch_row.id_instit_requests,
                                                        i_id_dcs_requests   => i_sch_row.id_dcs_requests,
                                                        i_id_prof_requests  => i_sch_row.id_prof_requests,
                                                        i_id_prof_schedules => i_sch_row.id_prof_schedules,
                                                        i_id_sch_ref        => i_sch_row.id_schedule,
                                                        i_transaction_id   => l_transaction_id,
                                                        o_ids_schedule     => o_sched,
                                                        o_id_schedule_ext  => l_id_ext,
                                                        o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- todo: confirmar que id_professional = i_sch_row.id_prof_requests e nao a i_sch_row.id_prof_schedules
        -- commits the scheduler remote transaction
        IF i_trans_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
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
                                              i_function => 'SET_SCHEDULE',
                                              o_error    => o_error);
            pk_alertlog.log_error(g_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_schedule;
    */

    /**
    * Get Referral short detail (Patient Portal)
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_patient             Patient identifier
    * @param i_id_external_request Referral identifier
    * @param o_detail              Referral short detail
    * @param o_error               An error message, set when return=false
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */
    FUNCTION get_referral
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat patient.id_patient%TYPE;
    BEGIN
        g_error := 'SELECT id_patient id_external_request = ' || i_id_external_request;
        SELECT id_patient
          INTO l_pat
          FROM p1_external_request
         WHERE id_external_request = i_id_external_request;
    
        IF l_pat = i_patient
        THEN
            g_error := 'Call pk_ref_list.get_ref_detail / i_id_external_request = ' || i_id_external_request;
            IF NOT pk_ref_list.get_ref_detail(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_external_request => table_number(i_id_external_request),
                                              o_detail              => o_detail,
                                              o_error               => o_error)
            
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            g_error := 'i_patient = ' || i_patient || ' l_pat = ' || l_pat;
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
                                                     i_function => 'GET_REFERRAL',
                                                     o_error    => o_error);
    END get_referral;

    /**
    * Get Referral list
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_patient             Patient identifier
    * @param o_ref_list            Patient referral list
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */
    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_ref_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Call pk_ref_list.get_referral_list / i_patient=' || i_patient;
        IF NOT pk_ref_list.get_referral_list(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_patient  => i_patient,
                                             i_filter   => 'PATIENT',
                                             i_type     => NULL,
                                             o_ref_list => o_ref_list,
                                             o_error    => o_error)
        
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
                                                     i_function => 'GET_REFERRAL_LIST',
                                                     o_error    => o_error);
    END get_referral_list;

    /**
    * Associate a referral sys_functionality to this professional
    *
    * @param i_lang            Language id
    * @param i_prof            Professional, Institution and Software ids
    * @param i_dcs             Deaprtment+Service identifier
    * @param i_func            Sys functionality
    * @param o_error           An error message, set when return=false
    *
    * @return  true if sucess, false otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2014
    */
    FUNCTION set_prof_func
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dcs   IN prof_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_func  IN sys_functionality.id_functionality%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_prof_func';
        l_func_inst table_number;
        l_func_dcs  table_number;
        l_func_type VARCHAR2(5 CHAR);
        l_found     PLS_INTEGER;
    
        l_dep_clin_serv table_number;
        l_func          table_number;
        l_args          table_varchar;
        l_id_inst       table_number;
        l_id_prof_func  table_number;
    
        /**
        * sets variables to add/remove the function related to the dep_clin_serv
        */
        PROCEDURE set_func_dcs
        (
            i_func_dcs IN sys_functionality.id_functionality%TYPE,
            i_flg      IN VARCHAR2
        ) IS
            l_found PLS_INTEGER;
        BEGIN
            l_found := pk_utils.search_table_number(i_table => l_func_dcs, i_search => i_func_dcs);
        
            IF (i_flg = pk_alert_constant.g_yes AND l_found = -1) -- add if not exists
               OR (i_flg = pk_alert_constant.g_no AND l_found != -1) -- remove if exists
            THEN
                l_dep_clin_serv.extend;
                l_func.extend;
                l_args.extend;
            
                l_dep_clin_serv(l_dep_clin_serv.last) := i_dcs;
                l_func(l_func.last) := i_func_dcs;
                l_args(l_args.last) := i_flg;
            END IF;
        END set_func_dcs;
    
        /**
        * sets variables to add/remove the function related to the institution
        */
        PROCEDURE set_func_inst
        (
            i_func_inst IN sys_functionality.id_functionality%TYPE,
            i_flg       IN VARCHAR2
        ) IS
            l_found PLS_INTEGER;
        BEGIN
            l_found := pk_utils.search_table_number(i_table => l_func_inst, i_search => i_func_inst);
        
            IF (i_flg = pk_alert_constant.g_yes AND l_found = -1) -- add if not exists
               OR (i_flg = pk_alert_constant.g_no AND l_found != -1) -- remove if exists
            THEN
                l_func.extend;
                l_args.extend;
                l_id_inst.extend;
            
                l_func(l_func.last) := i_func_inst;
                l_args(l_args.last) := i_flg;
                l_id_inst(l_id_inst.last) := i_prof.institution;
            
            END IF;
        END set_func_inst;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_dcs=' || i_dcs || ' i_func=' || i_func;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_init(g_error);
    
        l_dep_clin_serv := table_number();
        l_func          := table_number();
        l_args          := table_varchar();
        l_id_inst       := table_number();
    
        ----------------------
        -- FUNC
        ----------------------    
        l_func_inst := pk_ref_core.get_prof_func_inst(i_lang => i_lang, i_prof => i_prof);
        l_func_dcs  := pk_ref_core.get_prof_func_dcs(i_lang => i_lang, i_prof => i_prof, i_id_dcs => i_dcs);
    
        g_error := 'l_func_type / ' || l_params;
        IF i_func IN (pk_ref_constant.g_func_d, pk_ref_constant.g_func_t, pk_ref_constant.g_func_c)
        THEN
            l_func_type := 'DCS';
        ELSIF i_func IN (pk_ref_constant.g_ref_func_cd,
                         pk_ref_constant.g_func_ref_create,
                         pk_ref_constant.g_pat_create,
                         pk_ref_constant.g_func_ref_handoff_app)
        THEN
            l_func_type := 'INST';
        ELSE
            g_error := 'Functionality ' || i_func || ' not found / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' l_func_type=' || l_func_type;
    
        g_error := 'l_func_type 2 / ' || l_params;
        IF l_func_type = 'DCS'
        THEN
        
            g_error := 'CASE i_func / ' || l_params;
            CASE i_func
            
                WHEN pk_ref_constant.g_func_d THEN
                
                    -- remove the other funcionalities (if exist)
                    g_error := 'Remove set_func_dcs / ' || l_params;
                    set_func_dcs(i_func_dcs => pk_ref_constant.g_func_t, i_flg => pk_ref_constant.g_no);
                    set_func_dcs(i_func_dcs => pk_ref_constant.g_func_c, i_flg => pk_ref_constant.g_no);
                
                    -- add the functionality (if not exists)
                    g_error := 'Add set_func_dcs 1 / ' || l_params;
                    set_func_dcs(i_func_dcs => i_func, i_flg => pk_ref_constant.g_yes);
                
                WHEN pk_ref_constant.g_func_t THEN
                
                    -- do not add func if professional has g_func_d                   
                    l_found := pk_utils.search_table_number(i_table => l_func_dcs, i_search => pk_ref_constant.g_func_d);
                
                    IF l_found = -1
                    THEN
                        -- remove the other funcionalities (if exist) only if does not have g_func_d func
                        set_func_dcs(i_func_dcs => pk_ref_constant.g_func_c, i_flg => pk_ref_constant.g_no);
                    
                        -- add the functionality (if not exists)
                        g_error := 'Add set_func_dcs 2 / ' || l_params;
                        set_func_dcs(i_func_dcs => i_func, i_flg => pk_ref_constant.g_yes);
                    END IF;
                
                WHEN pk_ref_constant.g_func_c THEN
                
                    -- do not add func if professional has g_func_d or g_func_t
                    l_found := pk_utils.search_table_number(i_table => l_func_dcs, i_search => pk_ref_constant.g_func_d);
                    IF l_found = -1
                    THEN
                        l_found := pk_utils.search_table_number(i_table  => l_func_dcs,
                                                                i_search => pk_ref_constant.g_func_t);
                    
                        IF l_found = -1
                        THEN
                            -- add the functionality (if not exists)
                            g_error := 'Add set_func_dcs 3 / ' || l_params;
                            set_func_dcs(i_func_dcs => i_func, i_flg => pk_ref_constant.g_yes);
                        END IF;
                    END IF;
            END CASE;
        
            IF l_func.count > 0
            THEN
                g_error  := 'Call pk_backoffice_p1.set_prof_func_internal / l_func.count=' || l_func.count || ' / ' ||
                            l_params;
                g_retval := pk_backoffice_p1.set_prof_func_internal(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_id_professional => i_prof.id,
                                                                    i_id_institution  => i_prof.institution,
                                                                    i_dep_clin_serv   => l_dep_clin_serv,
                                                                    i_func            => l_func,
                                                                    i_args            => l_args,
                                                                    o_error           => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
        ELSIF l_func_type = 'INST'
        THEN
        
            -- add the functionality (if not exists)
            g_error := 'Call set_func_inst / ' || l_params;
            set_func_inst(i_func_inst => i_func, i_flg => pk_ref_constant.g_yes);
        
            IF l_func.count > 0
            THEN
                g_error  := 'Call pk_api_backoffice.intf_set_prof_func_all / l_func.count=' || l_func.count || ' / ' ||
                            l_params;
                g_retval := pk_api_backoffice.intf_set_prof_func_all(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_id_professional => i_prof.id,
                                                                     i_institution     => l_id_inst,
                                                                     i_func            => l_func,
                                                                     i_change          => l_args,
                                                                     o_id_prof_func    => l_id_prof_func,
                                                                     o_error           => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
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
                                                     i_function => 'SET_PROF_FUNC',
                                                     o_error    => o_error);
        
    END set_prof_func;

    /**
    * Checks if professional exists. If not, creates him.
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_num_order    Professional num order for the appointment physician
    * @param   i_prof_name    Professional name for the appointment physician
    * @param   i_profile_templ       Profile template of the professional being created (only if it is being created)
    * @param   i_func                Functionality of the professional
    * @param   i_dcs          Department and Service to which the professional is related
    * @param   o_id_prof      Professional identifier
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION set_professional_num_ord
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_num_order     IN professional.num_order%TYPE,
        i_prof_name     IN professional.name%TYPE,
        i_profile_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_func          IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_dcs           IN prof_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_id_prof       OUT professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_params VARCHAR2(1000 CHAR);
    
        CURSOR c_prof IS
            SELECT p.*
              FROM v_professional p
             WHERE (p.num_order = i_num_order AND i_num_order != '0')
                OR p.id_professional = o_id_prof;
    
        l_rec_prof         c_prof%ROWTYPE;
        l_flg_state        prof_institution.flg_state%TYPE;
        l_id_professional  professional.id_professional%TYPE;
        l_icon             VARCHAR2(2000 CHAR);
        l_flg_create       VARCHAR2(1 CHAR);
        l_profile_template profile_template.id_profile_template%TYPE;
        l_count            PLS_INTEGER;
    BEGIN
        ----------------------
        -- FUNC
        ----------------------   
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_num_order=' || i_num_order || ' i_id_inst=' ||
                    i_prof.institution || ' i_profile_templ=' || i_profile_templ || ' i_func=' || i_func || ' i_dcs=' ||
                    i_dcs;
        g_error  := 'Init set_professional_num_ord / ' || l_params;
        pk_alertlog.log_debug(g_error);
        l_flg_create := 0;
    
        IF i_num_order IN ('0', pk_ref_constant.g_not_app)
        THEN
        
            IF i_num_order = '0'
            THEN
                -- If num order is '0', then the referral was scheduled to the clinical service (not to a physician). Using professional interface
                o_id_prof := to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                                   i_prof.institution,
                                                                                                   i_prof.software),
                                                                   i_id_sys_config => pk_ref_constant.g_sc_intf_prof_id));
            
            ELSIF i_num_order = pk_ref_constant.g_not_app
            THEN
                -- may not be interface professional (used in PK_API_REFERRAL.import_referral)   
                o_id_prof := i_prof.id;
            END IF;
        
            -- prof_institution
            g_error  := 'Call pk_api_backoffice.intf_set_prof_institution / ID_PROF=' || o_id_prof || ' ID_INST=' ||
                        i_prof.institution;
            g_retval := pk_api_backoffice.intf_set_prof_institution(i_lang            => i_lang,
                                                                    i_id_professional => o_id_prof,
                                                                    i_id_institution  => i_prof.institution,
                                                                    i_flg_state       => pk_ref_constant.g_active, -- active
                                                                    i_num_mecan       => NULL,
                                                                    o_flg_state       => l_flg_state,
                                                                    o_icon            => l_icon,
                                                                    o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- prof_cat
            g_error  := 'Call pk_api_backoffice.intf_set_prof_cat / ID_PROF=' || o_id_prof || ' ID_INST=' ||
                        i_prof.institution;
            g_retval := pk_api_backoffice.intf_set_prof_cat(i_lang           => i_lang,
                                                            i_id_prof        => o_id_prof,
                                                            i_id_institution => i_prof.institution,
                                                            i_id_category    => pk_ref_constant.g_cat_id_med, -- physician
                                                            i_id_cat_surgery => NULL,
                                                            o_id_prof        => l_id_professional,
                                                            o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
        
            -- getting professional id        
            g_error := 'OPEN C_PROF / ' || l_params;
            OPEN c_prof;
            FETCH c_prof
                INTO l_rec_prof;
            g_found := c_prof%FOUND;
            CLOSE c_prof;
        
            -- professional does not exists, must be created
            IF NOT g_found
            THEN
                l_flg_create := 1;
                IF i_prof_name IS NULL
                THEN
                    g_error := 'Professional name IS NULL / ' || l_params;
                    RAISE g_exception;
                END IF;
            
                l_rec_prof.num_order  := i_num_order;
                l_rec_prof.first_name := i_prof_name;
            END IF;
        
            IF l_rec_prof.short_name IS NULL
            THEN
            
                -- remove Dra/Dr from the first name
                --l_prof_name := regexp_replace(i_prof_name, '^((d|D)(r|R)(a|A)?(\.)?( )+)((.)*)$', '\7, \1'); -- name with Dra/Dr at the end
                --l_prof_name := regexp_replace(i_prof_name, '^((d|D)(r|R)(a|A)?(\.)?( )+)((.)*)$', '\7');
            
                -- Nickname is the first name
                --l_rec_prof.short_name := pk_utils.str_token(i_string => l_prof_name,
                --                                           i_token  => 1, -- token number
                --                                           i_sep    => ' ');
            
                l_rec_prof.short_name := i_prof_name;
            
            END IF;
        
            IF l_rec_prof.gender IS NULL
            THEN
                l_rec_prof.gender := pk_ref_constant.g_gender_i;
            END IF;
        
            l_params := l_params || ' l_nickname=' || l_rec_prof.short_name || ' gender=' || l_rec_prof.gender;
        
            g_error  := 'Call pk_api_backoffice.intf_set_profissional / ' || l_params;
            g_retval := pk_api_backoffice.intf_set_profissional(i_lang           => i_lang,
                                                                i_id_prof        => l_rec_prof.id_professional,
                                                                i_id_inst        => i_prof.institution,
                                                                i_title          => l_rec_prof.title,
                                                                i_first_name     => l_rec_prof.first_name,
                                                                i_middle_name    => l_rec_prof.middle_name,
                                                                i_last_name      => l_rec_prof.last_name,
                                                                i_nickname       => l_rec_prof.short_name, -- mandatory
                                                                i_initials       => l_rec_prof.initials,
                                                                i_dt_birth       => l_rec_prof.dt_birth,
                                                                i_gender         => l_rec_prof.gender,
                                                                i_marital_status => l_rec_prof.marital_status,
                                                                i_category       => pk_ref_constant.g_cat_id_med, -- physician
                                                                i_id_speciality  => l_rec_prof.id_speciality,
                                                                i_num_order      => l_rec_prof.num_order,
                                                                i_upin           => l_rec_prof.upin,
                                                                i_dea            => l_rec_prof.dea,
                                                                i_id_cat_surgery => NULL,
                                                                i_num_mecan      => NULL,
                                                                i_id_lang        => i_lang,
                                                                i_flg_state      => pk_ref_constant.g_active, -- active
                                                                i_address        => l_rec_prof.address,
                                                                i_city           => l_rec_prof.city,
                                                                i_district       => l_rec_prof.district,
                                                                i_zip_code       => l_rec_prof.zip_code,
                                                                i_id_country     => l_rec_prof.id_country,
                                                                i_phone          => NULL,
                                                                i_num_contact    => l_rec_prof.num_contact,
                                                                i_mobile_phone   => NULL,
                                                                i_fax            => l_rec_prof.fax,
                                                                i_email          => l_rec_prof.email,
                                                                i_suffix         => l_rec_prof.suffix,
                                                                i_contact_det    => NULL,
                                                                i_county         => NULL,
                                                                i_other_adress   => NULL,
                                                                o_professional   => o_id_prof,
                                                                o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_params := l_params || ' o_id_prof=' || o_id_prof;
        
            IF i_profile_templ IS NOT NULL
            THEN
            
                IF l_flg_create = 1 -- only if the professional is being created or if profile_template is already nul
                THEN
                    -- assign a profile to this professional, in this institution/sofware
                    l_profile_template := i_profile_templ;
                
                ELSE
                    -- it's an update, set the profile only if it is null                               
                    g_error := 'Call pk_prof_utils.get_prof_profile_template / ' || l_params;
                    -- important note: use v_prof_profile_template_all instead of pk_prof_utils.get_prof_profile_template
                    -- because the professional has not logged in yet
                    -- todo: versao depois da reformulacao dos perfis (retirar)
                    SELECT COUNT(1)
                      INTO l_count
                      FROM v_prof_profile_template v
                     WHERE v.id_professional = o_id_prof
                       AND v.id_institution = i_prof.institution
                       AND v.id_software = i_prof.software;
                
                    IF l_count = 0
                    THEN
                        l_profile_template := i_profile_templ;
                    END IF;
                    -- todo: versao antes da reformulacao dos perfis (retirar)
                    --IF pk_prof_utils.get_prof_profile_template(i_prof => profissional(o_id_prof,
                    --                                                                  i_prof.institution,
                    --                                                                  i_prof.software)) IS NULL
                    --THEN
                    --    l_profile_template := i_profile_templ;
                    --END IF;
                
                END IF;
            
                l_params := l_params || ' l_profile_template=' || l_profile_template;
                IF l_profile_template IS NOT NULL
                THEN
                    g_error  := 'Call pk_api_backoffice.intf_set_template_list / ' || l_params;
                    g_retval := pk_api_backoffice.intf_set_template_list(i_lang             => i_lang,
                                                                         i_id_profissional  => o_id_prof,
                                                                         i_institution_list => table_number(i_prof.institution),
                                                                         i_software_list    => table_number(i_prof.software),
                                                                         i_template_list    => table_number(l_profile_template),
                                                                         o_error            => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END IF;
        
            IF i_dcs IS NOT NULL
            THEN
                -- associate this professional to the dep_clin_serv
                g_error  := 'Call pk_api_backoffice.set_prof_specialties / ' || l_params;
                g_retval := pk_api_backoffice.set_prof_specialties(i_lang             => i_lang,
                                                                   i_id_prof          => o_id_prof,
                                                                   i_id_institution   => i_prof.institution,
                                                                   i_id_dep_clin_serv => table_number(i_dcs),
                                                                   i_flg              => table_varchar(pk_ref_constant.g_yes),
                                                                   o_error            => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                -- associate to this professional a sys_functionality
                IF i_func IS NOT NULL
                THEN
                
                    g_error  := 'Call set_prof_func / ' || l_params;
                    g_retval := set_prof_func(i_lang  => i_lang,
                                              i_prof  => profissional(o_id_prof, i_prof.institution, i_prof.software),
                                              i_dcs   => i_dcs,
                                              i_func  => i_func,
                                              o_error => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                END IF;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_PROFESSIONAL_NUM_ORD',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_professional_num_ord;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_interface;
/
