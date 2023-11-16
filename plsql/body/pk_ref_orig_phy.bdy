/*-- Last Change Revision: $Rev: 2027588 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_orig_phy AS

    g_error         VARCHAR2(1000 CHAR);
    g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    /**
    * Get a default priority or home  to referral mcdt request
    *
    * @param  i_arr_priority_home array with priority_home information
    * @param  i_arr_priority_home array with priority_home information
    *
    * @RETURN  VARCHAR2 if sucess, NULL otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   10-12-2012
    */

    FUNCTION get_priority_home
    (
        i_lang              IN language.id_language%TYPE,
        i_arr_priority_home IN table_table_varchar,
        i_val               IN NUMBER -- 1 priority, 2 home
    ) RETURN VARCHAR2 IS
    
        l_arr_priority_home table_varchar := table_varchar();
        i                   PLS_INTEGER;
        l_val               VARCHAR2(1);
    
    BEGIN
        l_arr_priority_home.extend(i_arr_priority_home.count);
    
        FOR i IN 1 .. i_arr_priority_home.count
        LOOP
            l_arr_priority_home(i) := i_arr_priority_home(i) (i_val);
        END LOOP;
    
        IF i_val = 1 --prio
        THEN
            SELECT column_value
              INTO l_val
              FROM (SELECT column_value,
                           pk_ref_utils.get_domain_cached_rank(i_lang, NULL, pk_ref_constant.g_ref_prio, column_value) prio_rank
                      FROM TABLE(CAST(l_arr_priority_home AS table_varchar))
                     ORDER BY prio_rank)
             WHERE rownum = 1;
        ELSE
            -- home
            SELECT column_value
              INTO l_val
              FROM (SELECT column_value,
                           pk_ref_utils.get_domain_cached_rank(i_lang, NULL, pk_ref_constant.g_ref_home, column_value) home_rank
                      FROM TABLE(CAST(l_arr_priority_home AS table_varchar))
                     ORDER BY home_rank)
             WHERE rownum = 1;
        
        END IF;
        RETURN l_val;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_priority_home;
    --CheckISO7064Mod11_2  
    FUNCTION cumpute_check(i_string VARCHAR2) RETURN NUMBER IS
        l_p          PLS_INTEGER;
        l_str_length PLS_INTEGER;
        l_c          PLS_INTEGER;
    BEGIN
        l_str_length := length(i_string);
        l_p          := 0;
        FOR i IN 1 .. l_str_length
        LOOP
            l_c := ascii(substr(i_string, i, 1)) - 48;
            l_p := 2 * (l_p + l_c);
        END LOOP;
    
        l_p := MOD(l_p, 11);
        RETURN MOD((12 - l_p), 11);
    
    END cumpute_check;

    FUNCTION get_check_digit(i_string VARCHAR2) RETURN NUMBER IS
        l_c          PLS_INTEGER;
        l_str_length PLS_INTEGER;
    BEGIN
        l_str_length := length(i_string);
        l_c          := substr(i_string, l_str_length, 1);
    
        IF l_c = 'x'
           OR l_c = 'X'
        THEN
            RETURN 10;
        ELSE
            l_c := ascii(substr(i_string, l_str_length, 1));
            RETURN l_c - 48;
        END IF;
    END get_check_digit;

    FUNCTION verify(i_string VARCHAR2) RETURN BOOLEAN IS
    
    BEGIN
        IF cumpute_check(i_string) = get_check_digit(i_string)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END verify;

    FUNCTION getdata(i_string VARCHAR2) RETURN VARCHAR2 IS
        l_str_length PLS_INTEGER;
    BEGIN
        l_str_length := length(i_string);
        RETURN substr(i_string, 0, l_str_length - 1);
    END getdata;

    FUNCTION encode(i_string VARCHAR2) RETURN VARCHAR2 IS
        l_c PLS_INTEGER;
    BEGIN
        l_c := cumpute_check(i_string);
    
        IF l_c = 10
        THEN
            RETURN i_string || 'X';
        ELSE
            RETURN i_string || l_c;
        END IF;
    END encode;

    /**
    * Gets referral orig institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids    
    * @param   i_workflow       Referral workflow identifier
    * @param   i_id_institution Origin institution identifier (in case of at hospital entrance workflow)
    * @param   o_id_inst_orig   Referral origin institution
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   05-08-2010
    */
    FUNCTION get_ref_inst_orig
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        o_id_inst_orig OUT p1_external_request.id_inst_orig%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow || ' i_id_inst_orig=' ||
                    i_id_inst_orig;
        g_error  := 'Init get_ref_inst_orig / ' || l_params;
    
        IF i_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
            IF i_id_inst_orig IS NULL
            THEN
                o_id_inst_orig := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_external_inst,
                                                          i_prof    => i_prof);
            ELSE
                o_id_inst_orig := i_id_inst_orig;
            END IF;
        ELSE
            o_id_inst_orig := i_prof.institution;
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
                                              i_function => 'GET_REF_INST_ORIG',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ref_inst_orig;

    /**
    * Outdates details related to flg_home and flg_priority and adds new records with the new values (only if they are different)
    * Used by database functions only.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids    
    * @param   i_id_ref         Referral identifier    
    * @param   i_flg_priority   New value of flg_priority
    * @param   i_flg_home       New value of flg_home
    * @param   io_detail_tab    Detail structure
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   01-04-2011
    */
    FUNCTION add_flgs_to_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_flg_priority IN p1_external_request.flg_priority%TYPE,
        i_flg_home     IN p1_external_request.flg_home%TYPE,
        io_detail_tab  IN OUT NOCOPY table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_detail IS
            SELECT d.id_detail, d.text, d.flg_type
              FROM p1_detail d
             WHERE d.id_external_request = i_id_ref
               AND d.flg_type IN (pk_ref_constant.g_detail_type_fpriority, pk_ref_constant.g_detail_type_fhome)
               AND d.flg_status = pk_ref_constant.g_detail_status_a;
    
        TYPE t_coll_detail IS TABLE OF c_detail%ROWTYPE;
        l_detail_tab   t_coll_detail;
        l_detail_count PLS_INTEGER;
        l_params       VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_id_ref=' || i_id_ref || ' i_flg_priority=' || i_flg_priority || ' i_flg_home=' || i_flg_home;
        g_error  := 'Init add_flgs_to_detail / ' || l_params;
        IF io_detail_tab IS NULL
        THEN
            io_detail_tab := table_table_varchar();
        END IF;
        l_detail_count := io_detail_tab.count;
    
        -- Outdate old details with flg_priority and flg_home and add new values (if different)
        g_error := 'Cancelling old details with flg_priority and flg_home / ' || l_params;
        OPEN c_detail;
        FETCH c_detail BULK COLLECT
            INTO l_detail_tab;
        CLOSE c_detail;
    
        IF l_detail_tab.count = 0
        THEN
            -- no records found, add the new values
            g_error := 'FLG_PRIORITY / ' || l_params;
            io_detail_tab.extend(2);
        
            io_detail_tab(l_detail_count + 1) := table_varchar(NULL,
                                                               pk_ref_constant.g_detail_type_fpriority,
                                                               i_flg_priority,
                                                               pk_ref_constant.g_detail_flg_i,
                                                               NULL);
        
            io_detail_tab(l_detail_count + 2) := table_varchar(NULL,
                                                               pk_ref_constant.g_detail_type_fhome,
                                                               i_flg_home,
                                                               pk_ref_constant.g_detail_flg_i,
                                                               NULL);
        ELSE
            -- records found, outdate the old ones and add new values (if different)
            FOR i IN 1 .. l_detail_tab.count
            LOOP
            
                g_error := 'i=' || i || ' FLG_TYPE=' || l_detail_tab(i).flg_type || ' ID_DETAIL=' || l_detail_tab(i).id_detail ||
                           ' / ' || l_params;
                IF l_detail_tab(i).flg_type = pk_ref_constant.g_detail_type_fpriority
                THEN
                
                    IF l_detail_tab(i).text != i_flg_priority
                    THEN
                    
                        -- outdate old value and add new value
                        g_error := 'FLG_PRIORITY / ' || g_error;
                        io_detail_tab.extend(2);
                        io_detail_tab(l_detail_count + 1) := table_varchar(l_detail_tab(i).id_detail,
                                                                           NULL,
                                                                           NULL,
                                                                           pk_ref_constant.g_detail_flg_o,
                                                                           NULL);
                    
                        io_detail_tab(l_detail_count + 2) := table_varchar(NULL,
                                                                           pk_ref_constant.g_detail_type_fpriority,
                                                                           i_flg_priority,
                                                                           pk_ref_constant.g_detail_flg_i,
                                                                           NULL);
                    
                    END IF;
                
                ELSIF l_detail_tab(i).flg_type = pk_ref_constant.g_detail_type_fhome
                THEN
                
                    IF l_detail_tab(i).text != i_flg_home
                    THEN
                    
                        -- outdate old value and add new value
                        g_error := 'FLG_HOME / ' || g_error;
                        io_detail_tab.extend(2);
                        io_detail_tab(l_detail_count + 1) := table_varchar(l_detail_tab(i).id_detail,
                                                                           NULL,
                                                                           NULL,
                                                                           pk_ref_constant.g_detail_flg_o,
                                                                           NULL);
                    
                        io_detail_tab(l_detail_count + 2) := table_varchar(NULL,
                                                                           pk_ref_constant.g_detail_type_fhome,
                                                                           i_flg_home,
                                                                           pk_ref_constant.g_detail_flg_i,
                                                                           NULL);
                    
                    END IF;
                END IF;
            
            END LOOP;
        
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
                                              i_function => 'ADD_FLGS_TO_DETAIL',
                                              o_error    => o_error);
            RETURN FALSE;
    END add_flgs_to_detail;

    /**
    * Create the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Referral workflow identification    
    * @param   i_id_patient         Patient id
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service (can be null)
    * @param   i_req_type           (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type           (A)nalisys; (C)onsultation (E)xam, (I)ntervention,
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Origin institution identifier (may be different from i_prof.institution in case of "at hospital entrance" workflow)
    * @param   i_inst_dest          Destination institution   
    * @param   i_problems           Referral data - problem identifier to solve
    * @param   i_problems_desc      Referral data - problem description to solve
    * @param   i_dt_problem_begin   Referral data - date of problem begining
    * @param   i_detail             P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis          Referral data - diagnosis
    * @param   i_completed          Referral completed (Y/N)
    * @param   i_id_task            Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done    
    * @param   i_epis               Episode Id
    * @param   i_num_order          Professional num_order
    * @param   i_prof_name          Professional name
    * @param   i_prof_id            Professional Id
    * @param   i_institution_name   Origin institution name
    * @param   i_external_sys       External system identifier    
    * @param   i_date               Operation date
    * @param   o_ext_req            Referral id
    * @param   o_flg_show           Show message (Y/N)
    * @param   o_msg                Message text
    * @param   o_msg_title          Message title
    * @param   o_button             Type of button to show with message
    * @param   O_ERROR              an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-06-2009 
    */
    FUNCTION create_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_workflow         IN wf_workflow.id_workflow%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig     IN p1_external_request.id_inst_orig%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_epis             IN episode.id_episode%TYPE,
        i_num_order        IN professional.num_order%TYPE DEFAULT NULL,
        i_prof_name        IN professional.name%TYPE DEFAULT NULL,
        i_prof_id          IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        i_institution_name IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        i_external_sys     IN p1_external_request.id_external_sys%TYPE,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption   IN NUMBER DEFAULT NULL,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_ext_req     OUT p1_external_request.id_external_request%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_data          t_rec_prof_data;
        l_ref_row            p1_external_request%ROWTYPE;
        l_rowids             table_varchar;
        l_flg_status_n       wf_status.id_status%TYPE;
        l_track_row          p1_tracking%ROWTYPE;
        l_exrdiag_row        p1_exr_diagnosis%ROWTYPE;
        o_track              table_number;
        l_wf_transition_info table_varchar;
        l_wf_transitions     t_coll_wf_transition := t_coll_wf_transition();
        l_ref_orig_data      ref_orig_data%ROWTYPE;
        l_var                p1_exr_diagnosis.id_exr_diagnosis%TYPE;
        l_id_workflow_action p1_tracking.id_workflow_action%TYPE;
        l_detail             table_table_varchar;
        l_flg_status         p1_external_request.flg_status%TYPE;
        l_params             VARCHAR2(1000 CHAR);
        l_flg_available      VARCHAR2(1 CHAR);
        l_flg_availability   p1_spec_dep_clin_serv.flg_availability%TYPE;
        l_id_ref_comment     ref_comments.id_ref_comment%TYPE;
        -- config
        l_create_msg        sys_config.value%TYPE;
        l_ref_temp_msg      sys_config.value%TYPE;
        l_ref_external_inst sys_config.value%TYPE;
    
        l_problems  pk_edis_types.rec_in_epis_diagnoses;
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow || ' i_id_patient=' ||
                    i_id_patient || ' i_speciality=' || i_speciality || ' i_dcs=' || i_dcs || ' i_req_type=' ||
                    i_req_type || ' i_flg_type=' || i_flg_type || ' i_flg_priority=' || i_flg_priority ||
                    ' i_flg_home=' || i_flg_home || ' i_id_inst_orig=' || i_id_inst_orig || ' i_inst_dest=' ||
                    i_inst_dest || ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed ||
                    ' i_epis=' || i_epis || ' i_num_order=' || i_num_order || ' i_prof_id=' || i_prof_id ||
                    ' i_external_sys=' || i_external_sys;
    
        g_error := 'Init create_referral / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        ----------------------
        -- VAL
        ----------------------
        -- check dep_clin_serv - this validation was already done in flash/interface layer... double checking...
        IF i_dcs IS NOT NULL
        THEN
            g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv / ' || l_params;
            g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_inst_dest  => i_inst_dest,
                                                          i_dcs           => i_dcs,
                                                          o_flg_available => l_flg_available,
                                                          o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error := 'DEP_CLIN_SERV does not match DEST INSTITUTION / ' || l_params;
                RAISE g_exception;
            END IF;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------    
        g_error             := 'Call pk_sysconfig.get_config / ' || pk_ref_constant.g_ref_create_msg || ' / ' ||
                               l_params;
        l_create_msg        := nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_create_msg,
                                                           i_prof    => i_prof),
                                   pk_ref_constant.g_no);
        l_ref_temp_msg      := nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_temp_msg,
                                                           i_prof    => i_prof),
                                   pk_ref_constant.g_no);
        l_ref_external_inst := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_external_inst,
                                                       i_prof    => i_prof);
    
        ----------------------
        -- FUNC
        ----------------------    
        -- getting professional data
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL, -- functionality must be related to the institution (not to the dep_clin_serv)
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        g_error                       := 'ts_p1_external_request.next_key() / ' || l_params;
        l_ref_row.id_external_request := ts_p1_external_request.next_key();
    
        g_error                     := 'l_ref_row / ' || l_params;
        l_ref_row.id_patient        := i_id_patient;
        l_ref_row.num_req           := l_ref_row.id_external_request;
        l_ref_row.id_speciality     := i_speciality;
        l_ref_row.id_inst_dest      := i_inst_dest;
        l_ref_row.id_external_sys   := i_external_sys;
        l_ref_row.req_type          := i_req_type;
        l_ref_row.flg_type          := i_flg_type;
        l_ref_row.id_prof_requested := i_prof.id;
        l_ref_row.id_prof_created   := i_prof.id;
        l_ref_row.flg_priority      := i_flg_priority;
        l_ref_row.flg_home          := i_flg_home;
        l_ref_row.id_workflow       := i_workflow;
        l_ref_row.id_dep_clin_serv  := i_dcs;
        l_ref_row.prof_certificate  := i_prof_cert;
        l_ref_row.prof_name         := i_prof_first_name;
        l_ref_row.prof_surname      := i_prof_surname;
        l_ref_row.prof_phone        := i_prof_phone;
        l_ref_row.id_fam_rel        := i_id_fam_rel;
        l_ref_row.name_first_rel    := i_name_first_rel;
        l_ref_row.name_middle_rel   := i_name_middle_rel;
        l_ref_row.name_last_rel     := i_name_last_rel;
    
        -- getting referral origin institution
        g_error  := 'Call get_ref_inst_orig / ' || l_params;
        g_retval := get_ref_inst_orig(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_workflow     => i_workflow,
                                      i_id_inst_orig => i_id_inst_orig,
                                      o_id_inst_orig => l_ref_row.id_inst_orig,
                                      o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_workflow = pk_ref_constant.g_wf_srv_srv
           AND l_ref_row.id_speciality IS NULL
        THEN
            l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_ref_row.id_workflow,
                                                                     i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                     i_id_inst_dest => l_ref_row.id_inst_dest);
        
            g_error  := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / l_flg_availability=' ||
                        l_flg_availability || ' / ' || l_params;
            g_retval := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_id_dep_clin_serv => l_ref_row.id_dep_clin_serv,
                                                                         i_id_patient       => i_id_patient,
                                                                         i_id_external_sys  => l_ref_row.id_external_sys,
                                                                         i_flg_availability => l_flg_availability,
                                                                         o_id_speciality    => l_ref_row.id_speciality,
                                                                         o_error            => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error := l_params;
        IF i_workflow IN (pk_ref_constant.g_wf_x_hosp, pk_ref_constant.g_wf_gp)
        THEN
        
            IF i_prof_id IS NULL
            THEN
                -- professional must be created (does not exists)
                g_error  := 'Call pk_ref_interface.set_professional_num_ord / ' || l_params;
                g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => i_lang,
                                                                      i_prof      => i_prof,
                                                                      i_num_order => i_num_order,
                                                                      i_prof_name => i_prof_name,
                                                                      o_id_prof   => l_ref_orig_data.id_professional,
                                                                      o_error     => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- professional already exists
                l_ref_orig_data.id_professional := i_prof_id;
            END IF;
        
            IF l_ref_row.id_inst_orig = l_ref_external_inst
            THEN
                -- only filled when is the external institution
                l_ref_orig_data.institution_name := i_institution_name; -- only filled when is the external institution
            END IF;
        
            l_ref_orig_data.id_external_request := l_ref_row.id_external_request;
            l_ref_orig_data.dt_create           := g_sysdate_tstz;
        END IF;
    
        -- getting status begin
        g_error  := 'Calling PK_WORKFLOW.get_status_begin / ' || l_params;
        g_retval := pk_workflow.get_status_begin(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_id_workflow  => i_workflow,
                                                 o_status_begin => l_flg_status_n,
                                                 o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_flg_status         := pk_ref_status.convert_status_v(i_status => l_flg_status_n);
        g_error              := 'Calling pk_ref_core.init_param_tab / ' || l_params;
        l_wf_transition_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_ext_req            => l_ref_row.id_external_request,
                                                           i_completed          => i_completed,
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
                                                           i_flg_status         => l_flg_status);
    
        -- checking transition availability    
        g_error  := 'Calling pk_workflow.check_transition / ID_REF=' || l_ref_row.id_external_request ||
                    ' ID_WORKFLOW=' || l_ref_row.id_workflow || ' ID_STATUS_BEGIN=' || l_flg_status_n ||
                    ' id_category=' || l_prof_data.id_category || ' ID_PROFILE_TEMPLATE=' ||
                    l_prof_data.id_profile_template || ' ID_FUNCTIONALITY=' || l_prof_data.id_functionality ||
                    ' i_param=' || pk_utils.to_string(l_wf_transition_info);
        g_retval := pk_workflow.get_transitions(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => l_ref_row.id_workflow,
                                                i_id_status_begin     => l_flg_status_n,
                                                i_id_category         => l_prof_data.id_category,
                                                i_id_profile_template => l_prof_data.id_profile_template,
                                                i_id_functionality    => l_prof_data.id_functionality,
                                                i_param               => l_wf_transition_info,
                                                i_flg_auto_transition => pk_ref_constant.g_yes,
                                                o_transitions         => l_wf_transitions,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            g_error := g_error || ' / COUNT=' || l_wf_transitions.count;
            RAISE g_exception_np;
        END IF;
    
        -- todo: colocar aqui a validacao do estado 'G' (conteudo de get_status_mcdt aqui ou no wf?)
        -- quando se passar ALERT-910 para a framework workflows
    
        IF l_wf_transitions.count = 1
        THEN
            -- referral begin status
            g_error              := 'Calling pk_ref_status.convert_status_v / ID_STATUS=' || l_wf_transitions(1).id_status_end ||
                                    ' / ' || l_params;
            l_ref_row.flg_status := pk_ref_status.convert_status_v(i_status => l_wf_transitions(1).id_status_end);
            l_id_workflow_action := l_wf_transitions(1).id_workflow_action;
        
        ELSE
            g_error := 'No transition available. / WF=' || l_ref_row.id_workflow || ' STS_BEGIN=' || l_flg_status_n ||
                       ' ID_CAT=' || l_prof_data.id_category || ' ID_PROFILE_TEMPLATE=' ||
                       l_prof_data.id_profile_template || ' ID_FUNCTIONALITY=' || l_prof_data.id_functionality ||
                       ' I_PARAM=' || pk_utils.to_string(l_wf_transition_info) || ' i_flg_auto_transition=' ||
                       pk_ref_constant.g_yes || ' TRANSITIONS_COUNT=' || l_wf_transitions.count;
            RAISE g_exception;
        END IF;
    
        g_error                   := 'l_ref_row 2 / ' || l_params;
        l_ref_row.id_prof_status  := i_prof.id;
        l_ref_row.dt_status_tstz  := g_sysdate_tstz;
        l_ref_row.id_inst_dest    := i_inst_dest;
        l_ref_row.flg_paper_doc   := pk_ref_constant.g_no;
        l_ref_row.flg_digital_doc := pk_ref_constant.g_no;
        l_ref_row.flg_mail        := pk_ref_constant.g_no;
    
        l_wf_transition_info(pk_ref_constant.g_idx_id_prof_status) := l_ref_row.id_prof_status;
        l_wf_transition_info(pk_ref_constant.g_idx_id_inst_dest) := l_ref_row.id_inst_dest;
    
        -- ALERT-194568: problem begin date
        --l_ref_row.dt_probl_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_problem_begin, NULL);
        g_error  := 'Call pk_ref_utils.parse_dt_str / ' || l_params;
        g_retval := pk_ref_utils.parse_dt_str(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dt_str_flash => i_dt_problem_begin,
                                              o_year         => l_ref_row.year_begin,
                                              o_month        => l_ref_row.month_begin,
                                              o_day          => l_ref_row.day_begin,
                                              o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_ref_row.dt_requested       := g_sysdate_tstz;
        l_ref_row.id_episode         := i_epis;
        l_ref_row.id_pat_health_plan := i_health_plan;
        l_ref_row.id_pat_exemption   := i_exemption;
    
        -- creating referral row in database
        g_error := 'Call ts_p1_external_request.ins / ' || l_params;
        ts_p1_external_request.ins(rec_in => l_ref_row, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- creating ref_orig_data row in database
        IF l_ref_orig_data.id_external_request IS NOT NULL
        THEN
            g_error := 'Call ts_ref_orig_data.ins / ' || l_params;
            ts_ref_orig_data.ins(rec_in => l_ref_orig_data, rows_out => l_rowids);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REF_ORIG_DATA',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error                         := 'UPDATE STATUS / ' || l_params;
        l_track_row.id_external_request := l_ref_row.id_external_request;
        l_track_row.ext_req_status      := l_ref_row.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_dep_clin_serv    := l_ref_row.id_dep_clin_serv;
        l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        l_track_row.id_workflow_action  := l_id_workflow_action;
    
        IF l_ref_row.flg_status = pk_ref_constant.g_p1_status_n
        THEN
            g_error := 'INST_DEST / ' || l_params;
            IF i_inst_dest IS NULL
            THEN
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => pk_ref_constant.g_sm_doctor_cs_t073);
                RAISE g_exception;
            END IF;
        
            l_track_row.id_inst_dest  := l_ref_row.id_inst_dest;
            l_track_row.id_speciality := l_ref_row.id_speciality;
        END IF;
    
        g_error  := 'Calling PK_REF_STATUS.update_status / ' || l_params;
        g_retval := pk_ref_status.update_status(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_track_row => l_track_row,
                                                io_param    => l_wf_transition_info,
                                                o_track     => o_track,
                                                o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Referral details / ' || i_detail.count || ' / ' || l_params;
        l_detail := i_detail;
    
        -- adding flg_priority and flg_home to l_detail
        -- i_detail format: [id_detail|flg_type|text|flg|id_group]
        g_error  := 'Call add_flgs_to_detail / ' || l_params;
        g_retval := add_flgs_to_detail(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_ref       => l_ref_row.id_external_request,
                                       i_flg_priority => l_ref_row.flg_priority,
                                       i_flg_home     => l_ref_row.flg_home,
                                       io_detail_tab  => l_detail,
                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- inserting details 
        g_error  := 'Calling pk_ref_core.set_detail / ' || l_params;
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_ext_req       => l_ref_row.id_external_request,
                                           i_detail        => l_detail,
                                           i_ext_req_track => o_track(1), -- first iteration
                                           i_date          => g_sysdate_tstz,
                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'CALL PK_DIAGNOSIS_FORM.GET_SAVE_PARAMETERS';
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_problems,
                                                     o_rec_in_epis_diagnoses => l_problems,
                                                     o_error                 => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Inserting problems        
        IF l_problems.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_problems.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_problems.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error                           := 'Problems(' || i || ') / ' || l_params;
                    l_exrdiag_row                     := NULL;
                    l_exrdiag_row.id_external_request := l_ref_row.id_external_request;
                    l_exrdiag_row.id_diagnosis        := l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis;
                    l_exrdiag_row.id_alert_diagnosis  := l_problems.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis;
                    l_exrdiag_row.id_professional     := i_prof.id;
                    l_exrdiag_row.id_institution      := i_prof.institution;
                    l_exrdiag_row.flg_type            := pk_ref_constant.g_exr_diag_type_p;
                    l_exrdiag_row.flg_status          := pk_ref_constant.g_active;
                    l_exrdiag_row.dt_insert_tstz      := g_sysdate_tstz;
                    -- all problems have the same problem begin date
                    l_exrdiag_row.year_begin  := l_ref_row.year_begin; -- ALERT-194568
                    l_exrdiag_row.month_begin := l_ref_row.month_begin;
                    l_exrdiag_row.day_begin   := l_ref_row.day_begin;
                
                    g_error  := 'Calling PK_REF_API.set_p1_exr_diagnosis ' || pk_ref_constant.g_exr_diag_type_p ||
                                ' / ' || l_params;
                    g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_p1_exr_diagnosis    => l_exrdiag_row,
                                                                o_id_p1_exr_diagnosis => l_var,
                                                                o_error               => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'CALL PK_DIAGNOSIS_FORM.GET_SAVE_PARAMETERS';
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_diagnosis,
                                                     o_rec_in_epis_diagnoses => l_diagnoses,
                                                     o_error                 => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Inserting diagnosis        
        IF l_diagnoses.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_diagnoses.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_diagnoses.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error                           := 'Diagnosis(' || i || ') / ' || l_params;
                    l_exrdiag_row                     := NULL;
                    l_exrdiag_row.id_external_request := l_ref_row.id_external_request;
                    l_exrdiag_row.id_diagnosis        := l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis;
                    l_exrdiag_row.id_alert_diagnosis  := l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis;
                    l_exrdiag_row.id_professional     := i_prof.id;
                    l_exrdiag_row.id_institution      := i_prof.institution;
                    l_exrdiag_row.flg_type            := pk_ref_constant.g_exr_diag_type_d;
                    l_exrdiag_row.flg_status          := pk_ref_constant.g_active;
                    l_exrdiag_row.dt_insert_tstz      := g_sysdate_tstz;
                
                    g_error  := 'Calling PK_REF_API.set_p1_exr_diagnosis ' || pk_ref_constant.g_exr_diag_type_d ||
                                ' / ' || l_params;
                    g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_p1_exr_diagnosis    => l_exrdiag_row,
                                                                o_id_p1_exr_diagnosis => l_var,
                                                                o_error               => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        IF i_workflow <> pk_ref_constant.g_wf_ref_but
        THEN
            g_error  := 'Insert tasks / ' || l_params;
            g_retval := create_tasks_done(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_ext_req  => l_ref_row.id_external_request,
                                          i_id_tasks => i_id_tasks,
                                          i_id_info  => i_id_info,
                                          i_date     => g_sysdate_tstz,
                                          o_error    => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        g_error  := 'Call pk_ref_core.process_auto_transition / ID_REF=' || l_ref_row.id_external_request || ' WF=' ||
                    l_ref_row.id_workflow || ' I_PARAM=' || pk_utils.to_string(l_wf_transition_info);
        g_retval := pk_ref_core.process_auto_transition(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_prof_data => l_prof_data,
                                                        i_id_ref    => l_ref_row.id_external_request,
                                                        i_date      => g_sysdate_tstz,
                                                        io_param    => l_wf_transition_info,
                                                        io_track    => o_track,
                                                        o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_ext_req := l_ref_row.id_external_request;
        g_error   := 'o_ext_req =' || o_ext_req || ' / ' || l_params;
    
        IF i_epis IS NOT NULL
        THEN
            g_error := 'Calling pk_visit.set_first_obs / ' || l_params;
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_epis,
                                          i_pat                 => i_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => NULL,
                                          o_error               => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error := 'IF i_comments IS NOT NULL / ' || l_params;
        IF i_comments IS NOT NULL
        THEN
        
            FOR i IN 1 .. i_comments.count
            LOOP
            
                g_error := 'IF i_comments IS NOT NULL / ' || i_comments(i) (2) || ' /' || l_params;
                CASE i_comments(i) (2)
                    WHEN pk_ref_constant.g_active_comment THEN
                    
                        g_error  := 'Call pk_ref_core.create_ref_comment / ' || l_params;
                        g_retval := pk_ref_core.create_ref_comment(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_ref         => l_ref_row.id_external_request,
                                                                   i_text           => i_comments(i) (3),
                                                                   i_dt_comment     => g_sysdate_tstz,
                                                                   o_id_ref_comment => l_id_ref_comment,
                                                                   o_error          => o_error);
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                END CASE;
            
            END LOOP;
        
        END IF;
    
        -- ALERT-70087
        g_error := 'l_create_msg=' || l_create_msg || ' l_ref_temp_msg=' || l_ref_temp_msg || ' FLG_STATUS=' ||
                   l_wf_transition_info(pk_ref_constant.g_idx_flg_status) || ' / ' || l_params;
        IF l_create_msg = pk_ref_constant.g_yes
           AND l_wf_transition_info(pk_ref_constant.g_idx_flg_status) != pk_ref_constant.g_p1_status_o
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t003);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        
        ELSIF l_ref_temp_msg = pk_ref_constant.g_yes
              AND l_wf_transition_info(pk_ref_constant.g_idx_flg_status) = pk_ref_constant.g_p1_status_o
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t006);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'CREATE_REFERRAL',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END create_referral;

    /**
    * Create new mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_workflow            Referral workflow identifier
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_id_patient          Patient identifier   
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type    
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_epis                Episode identifier
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information    
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_ext_req             Referral identifier
    * @param   o_error               An error message, set when return=false
    *
    * @value   i_flg_type            {*}'A' analysis {*}'I' Image {*}'E' Other Exams {*}'P' Intervention/Procedures {*}'F' Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-01-2013
    */
    FUNCTION create_mcdt_referral
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_workflow          IN wf_workflow.id_workflow%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_diagnosis         IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_epis              IN episode.id_episode%TYPE,
        i_date              IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_codification      IN codification.id_codification%TYPE,
        i_flg_laterality    IN table_varchar DEFAULT NULL,
        i_consent           IN VARCHAR2,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_ext_req           OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CREATE_MCDT_REFERRAL',
                                                     o_error    => o_error);
    END create_mcdt_referral;

    /**
    * Updates referral info
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_ext_req            Referral identifier
    * @param   i_dt_modified        Referral last interaction (dt_last_interaction)
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service 
    * @param   i_req_type           Referral req type (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type           Referral type
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?    
    * @param   i_id_inst_orig       Origin institution identifier (may be different from i_prof.institution in case of "at hospital entrance" workflow)
    * @param   i_inst_dest          Destination institution    
    * @param   i_problems           Referral data - problem identifier to solve
    * @param   i_problems_desc      Referral data - problem description to solve
    * @param   i_dt_problem_begin   Referral data - date of problem begining
    * @param   i_detail             P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis          Referral data - diagnosis
    * @param   i_completed          Referral completed (Y/N)
    * @param   i_id_task            Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done        
    * @param   i_num_order          Professional num_order
    * @param   i_prof_name          Professional name
    * @param   i_prof_id            Professional ID
    * @param   i_institution_name   Origin institution name
    * @param   i_date               Operation date
    * @param   o_ext_req            Referral identification
    * @param   o_flg_show           Show message
    * @param   o_msg                Message text
    * @param   o_msg_title          Message title
    * @param   o_button             Type of button to show with message
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_req_type           {*} 'M' - manual  {*} 'P' - Using clinical protocol
    * @value   i_flg_type           {*} 'C' - Appointments {*} 'A'  - Lab tests {*} 'I' - Imaging exams {*} 'E' - Other exams
    *                               {*} 'P' - Procedures {*} 'F' -  Rehabilitation {*} 'S'  - Surgery requests
    *                               {*} 'N' - Admission requests
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - otherwise
    * @value   i_completed          {*} 'Y' - Referral completed {*} 'N' - otherwise  
    * @value   i_p_flg_type         {*} 'P' - problem {*} 'A' - allergie {*} 'H' - habit {*} 'D' - Relevant diseases {*} 'E'
    * @param   o_flg_show           {*} 'Y' - Show message {*} 'N' - otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-06-2009
    */
    FUNCTION update_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig     IN p1_external_request.id_inst_orig%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_num_order        IN professional.num_order%TYPE DEFAULT NULL,
        i_prof_name        IN professional.name%TYPE DEFAULT NULL,
        i_prof_id          IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        --i_id_institution   IN ref_orig_data.id_institution%TYPE DEFAULT NULL,
        i_institution_name IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto   
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption   IN NUMBER DEFAULT NULL,
        o_ext_req     OUT p1_external_request.id_external_request%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref IS
            SELECT *
              FROM p1_external_request
             WHERE id_external_request = i_ext_req
               FOR UPDATE;
    
        l_prof_data          t_rec_prof_data;
        l_ref_row            p1_external_request%ROWTYPE;
        l_rowids             table_varchar;
        l_flg_status_ori     p1_external_request.flg_status%TYPE;
        o_track              table_number;
        l_track_tab          table_number;
        l_track_row          p1_tracking%ROWTYPE;
        l_exrdiag_row        p1_exr_diagnosis%ROWTYPE;
        l_wf_transition_info table_varchar;
        l_ref_orig_data      ref_orig_data%ROWTYPE;
        l_var                p1_exr_diagnosis.id_exr_diagnosis%TYPE;
        l_flg_status         p1_external_request.flg_status%TYPE;
        l_detail             table_table_varchar;
        l_params             VARCHAR2(1000 CHAR);
        l_flg_available      VARCHAR2(1 CHAR);
        l_flg_availability   p1_spec_dep_clin_serv.flg_availability%TYPE;
        -- config
        l_ref_create_msg     sys_config.value%TYPE;
        l_ref_temp_msg       sys_config.value%TYPE;
        l_id_ref_comment     ref_comments.id_ref_comment%TYPE;
        l_id_ref_comment_arr table_number;
        l_ref_external_inst  sys_config.value%TYPE;
    
        l_problems  pk_edis_types.rec_in_epis_diagnoses;
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ext_req=' || i_ext_req || ' i_dt_modified=' ||
                    i_dt_modified || ' i_speciality=' || i_speciality || ' i_dcs=' || i_dcs || ' i_req_type=' ||
                    i_req_type || ' i_flg_type=' || i_flg_type || ' i_flg_priority=' || i_flg_priority ||
                    ' i_flg_home=' || i_flg_home || ' i_id_inst_orig=' || i_id_inst_orig || ' i_inst_dest=' ||
                    i_inst_dest || ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed ||
                    ' i_num_order=' || i_num_order || ' i_prof_id=' || i_prof_id || ' i_date=' || i_date;
    
        g_error := 'Init update_referral / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        ----------------------
        -- VAL
        ----------------------
        IF i_dcs IS NOT NULL
        THEN
            g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv / ' || l_params;
            g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_inst_dest  => i_inst_dest,
                                                          i_dcs           => i_dcs,
                                                          o_flg_available => l_flg_available,
                                                          o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error := 'DEP_CLIN_SERV does not match DEST INSTITUTION / ' || l_params;
                RAISE g_exception;
            END IF;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------    
        g_error             := 'Call pk_sysconfig.get_config / ' || l_params;
        l_ref_create_msg    := nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_create_msg,
                                                           i_prof    => i_prof),
                                   pk_ref_constant.g_no);
        l_ref_temp_msg      := nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_temp_msg,
                                                           i_prof    => i_prof),
                                   pk_ref_constant.g_no);
        l_ref_external_inst := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_external_inst,
                                                       i_prof    => i_prof);
    
        ----------------------
        -- FUNC
        ----------------------    
        -- getting professional data
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL, -- functionality must be related to the institution (not to the dep_clin_serv)
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting referral row
        g_error := 'Check referral / ' || l_params;
        OPEN c_ref;
        FETCH c_ref
            INTO l_ref_row;
        g_found := c_ref%FOUND;
        CLOSE c_ref;
    
        IF NOT g_found
        THEN
            g_error := 'Referral id=' || i_ext_req || ' does not exists / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' WF=' || l_ref_row.id_workflow || ' FLG_STATUS=' || l_ref_row.flg_status;
    
        g_error          := l_params;
        l_flg_status_ori := l_ref_row.flg_status;
    
        IF i_completed = pk_ref_constant.g_yes -- Referral completed
        THEN
            IF l_ref_row.flg_status IN (pk_ref_constant.g_p1_status_d, pk_ref_constant.g_p1_status_y)
            THEN
                g_error    := 'Validating changes / ' || l_params;
                o_flg_show := pk_ref_constant.g_no;
                IF pk_date_utils.trunc_insttimezone(i_prof, l_ref_row.dt_last_interaction_tstz, 'SS') >
                   pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
                THEN
                    g_error     := 'REFERRAL CHANGED / ' || l_params;
                    o_flg_show  := pk_ref_constant.g_yes;
                    o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => pk_ref_constant.g_sm_doctor_cs_t075);
                    o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => pk_ref_constant.g_sm_doctor_cs_t076);
                    o_button    := pk_ref_constant.g_button_read;
                    -- do not return, referral data must be changed
                END IF;
            END IF;
        
        END IF;
    
        g_error                       := 'l_ref_row / ' || l_params;
        l_ref_row.id_external_request := i_ext_req;
        l_ref_row.id_prof_requested   := i_prof.id;
        l_ref_row.flg_priority        := i_flg_priority;
        l_ref_row.flg_home            := i_flg_home;
        l_ref_row.id_prof_status      := i_prof.id;
    
        IF l_flg_status_ori = pk_ref_constant.g_p1_status_o
        THEN
            g_error                    := 'FLG_STATUS=O / ' || l_params;
            l_ref_row.id_speciality    := i_speciality;
            l_ref_row.id_inst_dest     := i_inst_dest;
            l_ref_row.id_dep_clin_serv := i_dcs;
        
            -- getting referral origin institution
            g_error  := 'Call get_ref_inst_orig / ' || l_params;
            g_retval := get_ref_inst_orig(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_workflow     => l_ref_row.id_workflow,
                                          i_id_inst_orig => i_id_inst_orig,
                                          o_id_inst_orig => l_ref_row.id_inst_orig,
                                          o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- Calculate id_speciality again (i_dcs may be changed)
            IF l_ref_row.id_workflow = pk_ref_constant.g_wf_srv_srv
            THEN
                l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_ref_row.id_workflow,
                                                                         i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                         i_id_inst_dest => l_ref_row.id_inst_dest);
            
                g_error  := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / ID_DEP_CLIN_SERV=' ||
                            l_ref_row.id_dep_clin_serv || ' ID_PATIENT=' || l_ref_row.id_patient || ' ID_WORKFLOW=' ||
                            l_ref_row.id_workflow || ' ID_EXTERNAL_SYS=' || l_ref_row.id_external_sys ||
                            ' FLG_AVAILABILITY=' || l_flg_availability || ' / ID_REF=' || l_ref_row.id_external_request;
                g_retval := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_id_dep_clin_serv => l_ref_row.id_dep_clin_serv,
                                                                             i_id_patient       => l_ref_row.id_patient,
                                                                             i_id_external_sys  => l_ref_row.id_external_sys,
                                                                             i_flg_availability => l_flg_availability,
                                                                             o_id_speciality    => l_ref_row.id_speciality,
                                                                             o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
            -- this data must be updated when referral is in status 'Being created'
            g_error := 'ID_WF=' || l_ref_row.id_workflow || ' / ' || l_params;
            IF l_ref_row.id_workflow IN (pk_ref_constant.g_wf_x_hosp, pk_ref_constant.g_wf_gp) -- JB 2010-10-08
            THEN
            
                IF i_prof_id IS NULL
                THEN
                    -- professional must be created (does not exists)
                    g_error  := 'Call pk_ref_interface.set_professional_num_ord / ' || l_params;
                    g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_num_order => i_num_order,
                                                                          i_prof_name => i_prof_name,
                                                                          o_id_prof   => l_ref_orig_data.id_professional,
                                                                          o_error     => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                ELSE
                    -- professional already exists
                    l_ref_orig_data.id_professional := i_prof_id;
                END IF;
            
                IF l_ref_row.id_inst_orig = l_ref_external_inst
                THEN
                    -- only filled when is the external institution
                    l_ref_orig_data.institution_name := i_institution_name; -- only filled when is the external institution
                END IF;
            
                l_ref_orig_data.id_external_request := i_ext_req;
                --l_ref_orig_data.num_order           := i_num_order;
                --l_ref_orig_data.prof_name           := i_prof_name;
            END IF;
        END IF;
    
        l_ref_row.dt_last_interaction_tstz := g_sysdate_tstz;
        l_ref_row.id_prof_requested        := i_prof.id;
        l_ref_row.prof_certificate         := i_prof_cert;
        l_ref_row.prof_name                := i_prof_first_name;
        l_ref_row.prof_surname             := i_prof_surname;
        l_ref_row.prof_phone               := i_prof_phone;
        l_ref_row.id_fam_rel               := i_id_fam_rel;
        l_ref_row.name_first_rel           := i_name_first_rel;
        l_ref_row.name_middle_rel          := i_name_middle_rel;
        l_ref_row.name_last_rel            := i_name_last_rel;
    
        -- ALERT-194568: problem begin date
        g_error  := 'Call pk_ref_utils.parse_dt_str / ' || l_params;
        g_retval := pk_ref_utils.parse_dt_str(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dt_str_flash => i_dt_problem_begin,
                                              o_year         => l_ref_row.year_begin,
                                              o_month        => l_ref_row.month_begin,
                                              o_day          => l_ref_row.day_begin,
                                              o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call ts_p1_external_request.upd / ' || l_params;
        l_rowids := NULL;
        ts_p1_external_request.upd(rec_in => l_ref_row, handle_error_in => TRUE, rows_out => l_rowids);
        ts_p1_external_request.upd(id_external_request_in => l_ref_row.id_external_request,
                                   year_begin_in          => l_ref_row.year_begin,
                                   year_begin_nin         => FALSE,
                                   month_begin_in         => l_ref_row.month_begin,
                                   month_begin_nin        => FALSE,
                                   day_begin_in           => l_ref_row.day_begin,
                                   day_begin_nin          => FALSE,
                                   id_pat_health_plan_in  => i_health_plan,
                                   id_pat_health_plan_nin => TRUE,
                                   id_pat_exemption_in    => i_exemption,
                                   id_pat_exemption_nin   => TRUE,
                                   handle_error_in        => TRUE,
                                   rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'Insert tasks / ' || l_params;
        IF i_id_tasks IS NOT NULL
        THEN
            g_error  := 'Call create_tasks_done / ' || l_params;
            g_retval := create_tasks_done(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_ext_req  => i_ext_req,
                                          i_id_tasks => i_id_tasks,
                                          i_id_info  => i_id_info,
                                          i_date     => i_date,
                                          o_error    => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error              := 'Calling pk_ref_core.init_param_tab / ' || l_params;
        l_wf_transition_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_ext_req            => l_ref_row.id_external_request,
                                                           i_completed          => i_completed,
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
    
        -- process automatic transitions available
        g_error  := 'Call pk_ref_core.process_auto_transition / ID_REF=' || l_ref_row.id_external_request || ' WF=' ||
                    l_ref_row.id_workflow || ' I_PARAM=' || pk_utils.to_string(l_wf_transition_info);
        g_retval := pk_ref_core.process_auto_transition(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_prof_data => l_prof_data,
                                                        i_id_ref    => l_ref_row.id_external_request,
                                                        i_dcs       => l_ref_row.id_dep_clin_serv,
                                                        i_date      => g_sysdate_tstz,
                                                        io_param    => l_wf_transition_info,
                                                        io_track    => o_track,
                                                        o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF o_track.count = 0
        THEN
            -- there was no status change, registering update on p1_tracking
            g_error                         := 'l_track_row / ' || l_params;
            l_track_row.id_external_request := l_ref_row.id_external_request;
            l_track_row.ext_req_status      := l_ref_row.flg_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_u;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        
            g_error  := 'Calling pk_ref_status.update_status / ' || l_params;
            g_retval := pk_ref_status.update_status(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_track_row => l_track_row,
                                                    io_param    => l_wf_transition_info,
                                                    o_track     => l_track_tab,
                                                    o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            o_track := o_track MULTISET UNION l_track_tab;
        END IF;
    
        g_error  := 'Referral details / ' || i_detail.count || ' / ' || l_params;
        l_detail := i_detail;
    
        -- adding flg_priority and flg_home to l_detail
        -- i_detail format: [id_detail|flg_type|text|flg|id_group]
        g_error  := 'Call add_flgs_to_detail / FLG_PRIORITY=' || l_ref_row.flg_priority || ' FLG_HOME=' ||
                    l_ref_row.flg_home || '  / ' || l_params;
        g_retval := add_flgs_to_detail(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_ref       => l_ref_row.id_external_request,
                                       i_flg_priority => l_ref_row.flg_priority,
                                       i_flg_home     => l_ref_row.flg_home,
                                       io_detail_tab  => l_detail,
                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Calling pk_ref_core.set_detail / ' || l_params;
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_ext_req       => l_ref_row.id_external_request,
                                           i_detail        => l_detail,
                                           i_ext_req_track => o_track(1), -- first iteration
                                           i_date          => g_sysdate_tstz,
                                           o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'UPDATE DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_p || ' / ' || l_params; -- Problems    
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_alert_constant.g_cancelled
         WHERE id_external_request = i_ext_req
           AND flg_type = pk_ref_constant.g_exr_diag_type_p
           AND flg_status = pk_alert_constant.g_active;
    
        -- Inserting problems        
        g_error := 'CALL PK_DIAGNOSIS_FORM.GET_SAVE_PARAMETERS';
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_problems,
                                                     o_rec_in_epis_diagnoses => l_problems,
                                                     o_error                 => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Problems
        IF l_problems.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_problems.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_problems.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error                           := 'Problems(' || i || ') / ' || l_params;
                    l_exrdiag_row                     := NULL;
                    l_exrdiag_row.id_external_request := l_ref_row.id_external_request;
                    l_exrdiag_row.id_diagnosis        := l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis;
                    l_exrdiag_row.id_alert_diagnosis  := l_problems.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis;
                    l_exrdiag_row.desc_diagnosis      := l_problems.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis;
                    l_exrdiag_row.id_professional     := i_prof.id;
                    l_exrdiag_row.id_institution      := i_prof.institution;
                    l_exrdiag_row.flg_type            := pk_ref_constant.g_exr_diag_type_p;
                    l_exrdiag_row.flg_status          := pk_ref_constant.g_active;
                    l_exrdiag_row.dt_insert_tstz      := g_sysdate_tstz;
                    -- all problems have the same problem begin date
                    l_exrdiag_row.year_begin  := l_ref_row.year_begin; -- ALERT-194568
                    l_exrdiag_row.month_begin := l_ref_row.month_begin;
                    l_exrdiag_row.day_begin   := l_ref_row.day_begin;
                
                    g_error  := 'Calling PK_REF_API.set_p1_exr_diagnosis ' || l_exrdiag_row.flg_type || ' / ' ||
                                l_params;
                    g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_p1_exr_diagnosis    => l_exrdiag_row,
                                                                o_id_p1_exr_diagnosis => l_var,
                                                                o_error               => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'UPDATE DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_d || ' / ' || l_params; -- Diagnosis
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_alert_constant.g_cancelled
         WHERE id_external_request = i_ext_req
           AND flg_type = pk_ref_constant.g_exr_diag_type_d
           AND flg_status = pk_alert_constant.g_active;
    
        -- Inserting diagnosis            
        g_error := 'CALL PK_DIAGNOSIS_FORM.GET_SAVE_PARAMETERS';
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_diagnosis,
                                                     o_rec_in_epis_diagnoses => l_diagnoses,
                                                     o_error                 => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_diagnoses.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_diagnoses.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_diagnoses.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error                           := 'Diagnosis(' || i || ') / ' || l_params;
                    l_exrdiag_row                     := NULL;
                    l_exrdiag_row.id_external_request := l_ref_row.id_external_request;
                    l_exrdiag_row.id_diagnosis        := l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis;
                    l_exrdiag_row.id_alert_diagnosis  := l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis;
                    l_exrdiag_row.desc_diagnosis      := l_diagnoses.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis;
                    l_exrdiag_row.id_professional     := i_prof.id;
                    l_exrdiag_row.id_institution      := i_prof.institution;
                    l_exrdiag_row.flg_type            := pk_ref_constant.g_exr_diag_type_d;
                    l_exrdiag_row.flg_status          := pk_ref_constant.g_active;
                    l_exrdiag_row.dt_insert_tstz      := g_sysdate_tstz;
                
                    g_error  := 'Calling PK_REF_API.set_p1_exr_diagnosis ' || l_exrdiag_row.flg_type || ' / ' ||
                                l_params;
                    g_retval := pk_ref_api.set_p1_exr_diagnosis(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_p1_exr_diagnosis    => l_exrdiag_row,
                                                                o_id_p1_exr_diagnosis => l_var,
                                                                o_error               => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'ID_REF=' || l_ref_row.id_external_request || ' WF=' || l_ref_row.id_workflow;
        IF l_ref_orig_data.id_external_request IS NOT NULL -- updates only if it is supposed to
        THEN
            l_rowids := NULL;
            g_error  := 'REF_ORIG_DATA / ID_REF=' || l_ref_orig_data.id_external_request || ' ID_PROF=' ||
                        l_ref_orig_data.id_professional || ' INSTITUTION_NAME=' || l_ref_orig_data.institution_name;
            ts_ref_orig_data.upd(rec_in => l_ref_orig_data, handle_error_in => TRUE, rows_out => l_rowids);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REF_ORIG_DATA',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        g_error      := 'o_ext_req / ' || l_params;
        o_ext_req    := l_ref_row.id_external_request;
        l_flg_status := l_wf_transition_info(pk_ref_constant.g_idx_flg_status);
    
        g_error := 'IF i_comments IS NOT NULL / ' || l_params;
        IF i_comments IS NOT NULL
        THEN
            FOR i IN 1 .. i_comments.count
            LOOP
                g_error := 'IF i_comments IS NOT NULL / ' || i_comments(i) (2) || ' /' || l_params;
                CASE i_comments(i) (2)
                    WHEN pk_ref_constant.g_active_comment THEN
                    
                        g_error  := 'Call pk_ref_core.create_ref_comment / ' || l_params;
                        g_retval := pk_ref_core.create_ref_comment(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_ref         => l_ref_row.id_external_request,
                                                                   i_text           => i_comments(i) (3),
                                                                   i_dt_comment     => g_sysdate_tstz,
                                                                   o_id_ref_comment => l_id_ref_comment,
                                                                   o_error          => o_error);
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    WHEN pk_ref_constant.g_outdated_comment THEN
                    
                        g_error  := 'Call pk_ref_core.edit_ref_comment / ' || l_params;
                        g_retval := pk_ref_core.edit_ref_comment(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_ref         => l_ref_row.id_external_request,
                                                                 i_text           => i_comments(i) (3),
                                                                 i_id_ref_comment => to_number(i_comments(i) (1)),
                                                                 i_dt_edit        => g_sysdate_tstz,
                                                                 o_id_ref_comment => l_id_ref_comment_arr,
                                                                 o_error          => o_error);
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                    WHEN pk_ref_constant.g_canceled_comment THEN
                    
                        g_error  := 'Call pk_ref_core.create_ref_comment / ' || l_params;
                        g_retval := pk_ref_core.cancel_ref_comment(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_ref         => l_ref_row.id_external_request,
                                                                   i_id_ref_comment => to_number(i_comments(i) (1)),
                                                                   i_dt_cancel      => g_sysdate_tstz,
                                                                   o_id_ref_comment => l_id_ref_comment,
                                                                   o_error          => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    ELSE
                        g_error := 'Invalid Option!';
                        RAISE g_exception_np;
                END CASE;
            END LOOP;
        END IF;
    
        IF l_flg_status_ori != pk_ref_constant.g_p1_status_d
        THEN
            -- when the referral is declined, the event must be triggered when the transition N->I occurs
            -- done in PK_API_REF_EVENT.set_tracking
            g_error := 'Call pk_api_ref_event.set_ref_update / FLG_STATUS=' || l_flg_status || ' / ' || l_params;
            pk_api_ref_event.set_ref_update(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_ref     => l_ref_row.id_external_request,
                                            i_flg_status => l_flg_status,
                                            i_id_inst    => i_prof.institution);
        END IF;
    
        -- show helpsave
        g_error := 'l_ref_create_msg=' || l_ref_create_msg || ' l_ref_temp_msg=' || l_ref_temp_msg ||
                   ' l_flg_status_ori=' || l_flg_status_ori || ' l_flg_status=' || l_flg_status || ' / ' || l_params;
        IF l_flg_status_ori = pk_ref_constant.g_p1_status_o
           AND l_flg_status != l_flg_status_ori
           AND l_ref_create_msg = pk_ref_constant.g_yes
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t003);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        ELSIF l_ref_temp_msg = pk_ref_constant.g_yes
              AND l_flg_status = pk_ref_constant.g_p1_status_o
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t006);
            o_button    := pk_ref_constant.g_c_green_check_icon;
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
                                              i_function => 'UPDATE_REFERRAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_referral;

    /**
    * Update mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_workflow            Referral workflow identifier
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral    
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_id_episode          Episode identifier
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]* @param   i_diagnosis           Referral Diagnosis
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_date                Operation date
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information    
    * @param   o_ext_req             Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-01-2013
    */
    FUNCTION update_mcdt_referral
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_workflow          IN wf_workflow.id_workflow%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_diagnosis         IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_date              IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_codification      IN codification.id_codification%TYPE,
        i_flg_laterality    IN table_varchar DEFAULT NULL,
        i_consent           IN VARCHAR2,
        i_health_plan       IN table_number DEFAULT NULL,
        i_exemption         IN table_number DEFAULT NULL,
        o_ext_req           OUT table_number,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
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
                                              i_function => 'UPDATE_MCDT_REFERRAL',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END update_mcdt_referral;

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
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        o_number            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode episode.id_episode%TYPE;
        l_dt         p1_external_request.dt_requested%TYPE;
    BEGIN
        g_error := 'Init get_referral_number / ID_REF=' || i_ext_req || ' ID_REF_COMPLETION=' || i_id_ref_completion;
        SELECT exr.dt_requested, exr.id_episode
          INTO l_dt, l_id_episode
          FROM p1_external_request exr
         WHERE exr.id_external_request = i_ext_req;
    
        g_error  := 'Call get_referral_number / ID_REF=' || i_ext_req || ' ID_REF_COMPLETION=' || i_id_ref_completion;
        g_retval := get_referral_number(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_id_episode        => l_id_episode,
                                        i_dt_req            => l_dt,
                                        i_id_ref_completion => i_id_ref_completion,
                                        o_number            => o_number,
                                        o_error             => o_error);
    
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
                                                     i_function => 'GET_REFERRAL_NUMBER',
                                                     o_error    => o_error);
    END get_referral_number;

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
        l_params              VARCHAR2(1000 CHAR);
        l_sql                 VARCHAR2(200 CHAR);
        l_count               PLS_INTEGER;
        l_seq_val             NUMBER(24);
        l_id_clinical_service dep_clin_serv.id_clinical_service%TYPE;
        l_sequence_name       user_sequences.sequence_name%TYPE;
        l_num_req             VARCHAR2(200 CHAR);
    
        l_form_type           sys_config.value%TYPE;
        l_accs_orif_soft_code sys_config.value%TYPE;
        l_acss_db_instance    sys_config.value%TYPE;
        l_doc_via             sys_config.value%TYPE;
        l_ap                  VARCHAR2(200 CHAR);
        l_cnes                VARCHAR2(200 CHAR);
        l_rs_inst             VARCHAR2(200 CHAR);
    
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode ||
                    ' i_dt_req=' || i_dt_req || ' i_id_ref_completion=' || i_id_ref_completion;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_episode IS NOT NULL
        THEN
            SELECT epis.id_clinical_service
              INTO l_id_clinical_service
              FROM episode epis
             WHERE epis.id_episode = i_id_episode;
        END IF;
    
        g_error  := 'Call pk_api_pfh_in.get_presc_number_seq / i_flg_type=' ||
                    pk_api_pfh_in.g_presc_number_seq_flg_type_r || ' l_id_clinical_service=' || l_id_clinical_service ||
                    ' / ' || l_params;
        g_retval := pk_api_pfh_in.get_presc_number_seq(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_institution      => i_prof.institution,
                                                       i_flg_type            => pk_api_pfh_in.g_presc_number_seq_flg_type_r,
                                                       i_id_clinical_service => l_id_clinical_service,
                                                       o_sequence_name       => l_sequence_name,
                                                       o_error               => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Validate if sequence exists / l_sequence_name=' || l_sequence_name || ' / ' || l_params;
        SELECT COUNT(1)
          INTO l_count
          FROM user_sequences us
         WHERE us.sequence_name = l_sequence_name;
    
        IF l_count = 0
        THEN
            g_error := 'Sequence ' || l_sequence_name || ' is missing / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- sequential number calculated in the same way as prescriptions codification
        -- Getting next value of the sequence
        l_sql := 'select ' || l_sequence_name || '.nextval from dual';
    
        g_error := l_sql || ' / ' || l_params;
        EXECUTE IMMEDIATE l_sql
            INTO l_seq_val;
    
        IF i_id_ref_completion = pk_ref_constant.g_ref_compl_ap_cnes -- for BR
        THEN
            g_error := 'Call pk_api_backoffice.get_inst_account_val 57 / ' || l_params;
            l_ap    := pk_api_backoffice.get_inst_account_val(i_lang        => i_lang,
                                                              i_institution => i_prof.institution,
                                                              i_account     => 57,
                                                              o_error       => o_error);
        
            g_error := 'Call pk_api_backoffice.get_inst_account_val 55 / ' || l_params;
            l_cnes  := pk_api_backoffice.get_inst_account_val(i_lang        => i_lang,
                                                              i_institution => i_prof.institution,
                                                              i_account     => 55,
                                                              o_error       => o_error);
        
            IF l_ap IS NULL
               OR l_cnes IS NULL
            THEN
                g_error := 'Institution ''AP'' / ''cnes'' is missing / ' || l_params;
                RAISE g_exception;
            END IF;
        
            g_error  := 'o_number / ' || l_params;
            o_number := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYY') || '.' || l_ap || '.' || l_cnes || '/' ||
                        lpad(l_seq_val, 5, '0');
        
        ELSIF i_id_ref_completion = pk_ref_constant.g_ref_compl_330_10 -- BDNP
        THEN
            -- 1º digito Região de saude da instituição l_rs_inst
            -- 2º e 3º digitos Tipo de formulario (sempre 04 para MCDTS) l_form_type
            -- 4º a 6º digitos Origem do Software (valor entre 111 e 999 valor atribuido pela ACSS) l_accs_orif_soft_code
            -- 7º a 10º digitos instancia da bd responsável pela produção do impresso (valor atribuido pela ACSS) 
            -- 11' ao 17º valor da sequência l_sequence_name
            -- 18º digito via do documento (sempre 0) l_doc_via
            -- 19º check-digit ISO/IEC 7064, MOD 11,2 
        
            -- getting configs
            g_error               := 'Getting configs / ' || l_params;
            l_form_type           := pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp_form_type, i_prof);
            l_accs_orif_soft_code := pk_sysconfig.get_config(pk_ref_constant.g_accs_orig_soft_code, i_prof);
            l_acss_db_instance    := pk_sysconfig.get_config(pk_ref_constant.g_acss_db_instance, i_prof);
            l_doc_via             := pk_sysconfig.get_config(pk_ref_constant.g_ref_via_bdnp, i_prof);
        
            IF l_accs_orif_soft_code IS NULL
            THEN
                g_error := 'ID_SYS_CONFIG=' || pk_ref_constant.g_accs_orig_soft_code || ' IS NULL / ' || l_params;
                RAISE g_exception;
            END IF;
        
            IF l_acss_db_instance IS NULL
            THEN
                g_error := 'ID_SYS_CONFIG=' || pk_ref_constant.g_acss_db_instance || ' IS NULL / ' || l_params;
                RAISE g_exception;
            END IF;
        
            g_error   := 'Call pk_api_backoffice.get_instit_ars / ' || l_params;
            l_rs_inst := pk_api_backoffice.get_instit_ars(i_lang  => i_lang,
                                                          i_inst  => i_prof.institution,
                                                          o_error => o_error);
            IF l_rs_inst IS NULL
            THEN
                g_error := 'Institution ARS is missing. Please check intitution Backoffice! / ' || l_params;
                RAISE g_exception;
            END IF;
        
            g_error   := 'l_num_req / ' || l_params;
            l_num_req := l_rs_inst || l_form_type || l_accs_orif_soft_code || l_acss_db_instance ||
                         lpad(l_seq_val, 7, '0') || l_doc_via;
            o_number  := encode(l_num_req);
        
        ELSE
            -- 2<codigo instituicao><YY><sequencia_size5>    
            g_error  := 'o_number 2 / ' || l_params;
            o_number := to_number('2' || substr(l_sequence_name, 21, 4) ||
                                  pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YY') || lpad(l_seq_val, 6, '0'));
        END IF;
    
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
    END get_referral_number;

    /**
    * Returns message if there are active (emited and not closed) requests for the
    * patient/speciality provided in the last 30 days.  
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_patient         Patient identifier
    * @param   i_spec               Referral speciality identifier
    * @param   i_type               Referral type. If null returns all referrals, otherwise returns the referrals selected type
    * @param   o_flg_show           Show message (Y/N)
    * @param   o_msg                Message text
    * @param   o_msg_title          Message title
    * @param   o_button             Type of button to show with message
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_type               {*} 'C' - consulation {*} 'A' - lab tests {*} 'I' - imaging exams {*} 'E' - other exams
    *                               {*} 'P' - procedures {*} 'F' - MFR
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   07-12-2007
    */
    FUNCTION get_pat_spec_active_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_spec       IN p1_speciality.id_speciality%TYPE,
        i_type       IN p1_external_request.flg_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    
        CURSOR c_ref
        (
            x_active_status    IN table_varchar,
            x_active_status_dt IN table_varchar
        ) IS
            SELECT COUNT(1), 'A' -- active referrals
              FROM p1_external_request exr
             WHERE exr.id_patient = i_id_patient
               AND exr.id_speciality = i_spec
               AND exr.flg_type = i_type
               AND (
                   -- validate dt_status_tstz and flg_status
                    (exr.flg_status IN (SELECT column_value
                                          FROM TABLE(CAST(x_active_status_dt AS table_varchar))) AND
                    exr.dt_status_tstz BETWEEN
                    pk_date_utils.trunc_insttimezone(i_prof, current_timestamp - INTERVAL '30' DAY) AND
                    pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY)) OR
                   -- validate only flg_status
                    (exr.flg_status IN (SELECT column_value
                                          FROM TABLE(CAST(x_active_status AS table_varchar)))))
            UNION ALL
            SELECT COUNT(1), 'C' -- closed referrals
              FROM p1_external_request exr
             WHERE exr.id_patient = i_id_patient
               AND exr.id_speciality = i_spec
               AND exr.flg_type = i_type
               AND exr.flg_status IN
                   (SELECT column_value
                      FROM TABLE(CAST(pk_ref_core.get_pat_closed_status(i_lang, i_prof) AS table_varchar)))
               AND exr.dt_status_tstz BETWEEN
                   CAST(pk_date_utils.trunc_insttimezone(i_prof, trunc(SYSDATE, 'YYYY')) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                   CAST(pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY) AS TIMESTAMP WITH
                        LOCAL TIME ZONE);
    
        l_count      table_number;
        l_count_type table_varchar;
    
        l_count_active PLS_INTEGER;
        l_count_closed PLS_INTEGER;
    
        l_active_status    table_varchar;
        l_active_status_dt table_varchar;
        l_params           VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_id_patient=' || i_id_patient || ' i_spec=' || i_spec || ' i_type=' || i_type;
        g_error  := 'Init get_pat_spec_active_count / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_flg_show := pk_ref_constant.g_no;
    
        ----------------------
        -- FUNC
        ----------------------                
    
        -- getting sys_messages
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_ref_common_t004,
                                        pk_ref_constant.g_sm_ref_common_t005,
                                        pk_ref_constant.g_sm_doctor_cs_t078,
                                        pk_ref_constant.g_sm_doctor_cs_t079);
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ' || l_params || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_core.get_pat_active_status / ' || l_params;
        g_retval := pk_ref_core.get_pat_active_status(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      o_active_status    => l_active_status,
                                                      o_active_status_dt => l_active_status_dt,
                                                      o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        OPEN c_ref(l_active_status, l_active_status_dt);
        FETCH c_ref BULK COLLECT
            INTO l_count, l_count_type;
        CLOSE c_ref;
    
        g_error := 'FOR i IN 1 .. ' || l_count.count || ' / ' || l_params;
        FOR i IN 1 .. l_count.count
        LOOP
            CASE l_count_type(i)
                WHEN 'A' THEN
                    l_count_active := l_count(i);
                WHEN 'C' THEN
                    l_count_closed := l_count(i);
                ELSE
                    NULL;
            END CASE;
        END LOOP;
    
        g_error := 'l_count_active=' || l_count_active || ' l_count_closed=' || l_count_closed || ' / ' || l_params;
        IF l_count_active > 0
           AND l_count_closed > 0
        THEN
            -- active and closed referrals
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t078);
            o_msg       := l_desc_message_ibt(pk_ref_constant.g_sm_ref_common_t005);
            o_button    := pk_ref_constant.g_button_read;
        ELSIF l_count_active > 0
              AND l_count_closed = 0
        THEN
            -- active referrals only
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t078);
            o_msg       := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t079);
            o_button    := pk_ref_constant.g_button_read;
        ELSIF l_count_active = 0
              AND l_count_closed > 0
        THEN
            -- closed referrals only
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t078);
            o_msg       := l_desc_message_ibt(pk_ref_constant.g_sm_ref_common_t004);
            o_button    := pk_ref_constant.g_button_read;
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
                                              i_function => 'GET_PAT_SPEC_ACTIVE_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_spec_active_count;

    /**
    * Returns number of days to active requests for the i_mcdt
    *
    * @param   i_lang language
    * @param   i_prof profissional, institution, software
    * @param   i_mcdt  id_analysis, id_exam, Intervention
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    *
    * @return  Number of days
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-08-2011
    */
    FUNCTION get_mcdt_active_count
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_mcdt IN ref_mcdt_active_count.id_mcdt%TYPE,
        i_type IN ref_mcdt_active_count.flg_mcdt%TYPE
    ) RETURN NUMBER IS
    
        CURSOR c_active_count
        (
            x_mcdt ref_mcdt_active_count.id_mcdt%TYPE,
            x_flg  ref_mcdt_active_count.flg_mcdt%TYPE
        ) IS
            SELECT active_num_days
              FROM ref_mcdt_active_count
             WHERE id_mcdt = x_mcdt
               AND flg_mcdt = x_flg
               AND flg_available = pk_ref_constant.g_yes;
        l_active_count ref_mcdt_active_count.active_num_days%TYPE;
    BEGIN
        g_error := 'Init get_mcdt_active_count / i_mcdt=' || i_mcdt || ' i_type=' || i_type;
        OPEN c_active_count(i_mcdt, i_type);
        FETCH c_active_count
            INTO l_active_count;
    
        IF c_active_count%NOTFOUND
        THEN
            l_active_count := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_issue_print_req_days, i_prof), -1);
        END IF;
    
        CLOSE c_active_count;
    
        RETURN l_active_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN - 1;
    END get_mcdt_active_count;

    /**
    * Returns message if there are active (emited and not closed) requests for the
    * patient/i_mcdt provided in the last 30 days.  
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_patient      Patient identifier
    * @param   i_mcdt            id_analysis, id_exam, Intervention
    * @param   i_type            Referral type. If null returns all request, otherwise return for the selected type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_type            {*} NULL- all referral types {*} C-Consulation {*} A-Lab tests {*} E-Exam {*} I-Intervention {*} F-Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   19-08-2011
    */
    FUNCTION get_pat_mcdt_active_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_mcdt       IN table_number,
        i_type       IN p1_external_request.flg_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis(x_active_status IN table_varchar) IS
            SELECT DISTINCT --t.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                      i_prof                      => i_prof,
                                                                      i_flg_type                  => 'A',
                                                                      i_analysis_code_translation => pk_ref_constant.g_analysis_code ||
                                                                                                     t.id_analysis,
                                                                      i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                     t.id_sample_type,
                                                                      i_dep_clin_serv             => NULL) desc_analysis,
                            get_mcdt_active_count(i_lang, i_prof, t.column_value, i_type) active_count
              FROM (SELECT pea.id_analysis, pea.id_sample_type, tt.column_value
                      FROM p1_external_request per
                      JOIN p1_exr_analysis pea
                        ON per.id_external_request = pea.id_external_request
                      JOIN TABLE(CAST(i_mcdt AS table_number)) tt
                        ON pea.id_analysis = tt.column_value
                     WHERE per.flg_status IN (SELECT column_value
                                                FROM TABLE(CAST(x_active_status AS table_varchar)))
                       AND per.flg_type = i_type
                       AND per.id_patient = i_id_patient
                       AND per.dt_status_tstz < =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY)
                       AND per.dt_status_tstz >
                           (current_timestamp - get_mcdt_active_count(i_lang, i_prof, tt.column_value, i_type))) t;
    
        CURSOR c_exam(x_active_status IN table_varchar) IS
            SELECT DISTINCT --t.id_exam,
                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  pk_ref_constant.g_exam_code || t.id_exam) desc_exam,
                            get_mcdt_active_count(i_lang, i_prof, t.column_value, i_type) active_count
              FROM (SELECT pee.id_exam, tt.column_value
                      FROM p1_external_request per
                      JOIN p1_exr_exam pee
                        ON per.id_external_request = pee.id_external_request
                      JOIN TABLE(CAST(i_mcdt AS table_number)) tt
                        ON pee.id_exam = tt.column_value
                     WHERE per.flg_status IN (SELECT column_value
                                                FROM TABLE(CAST(x_active_status AS table_varchar)))
                       AND
                          
                           per.flg_type = i_type
                       AND per.id_patient = i_id_patient
                       AND per.dt_status_tstz < =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY)
                       AND per.dt_status_tstz >
                           (current_timestamp - get_mcdt_active_count(i_lang, i_prof, tt.column_value, i_type))) t;
    
        CURSOR c_intervention(x_active_status IN table_varchar) IS
            SELECT DISTINCT --t.id_intervention,
                            pk_procedures_api_db.get_alias_translation(i_lang,
                                                                       i_prof,
                                                                       pk_ref_constant.g_interv_code ||
                                                                       t.id_intervention,
                                                                       NULL) desc_interv,
                            get_mcdt_active_count(i_lang, i_prof, t.column_value, i_type) active_count
              FROM (SELECT pei.id_intervention, tt.column_value
                      FROM p1_external_request per
                      JOIN p1_exr_intervention pei
                        ON per.id_external_request = pei.id_external_request
                      JOIN TABLE(CAST(i_mcdt AS table_number)) tt
                        ON pei.id_intervention = tt.column_value
                     WHERE per.flg_status IN (SELECT column_value
                                                FROM TABLE(CAST(x_active_status AS table_varchar)))
                       AND per.flg_type = i_type
                       AND per.id_patient = i_id_patient
                       AND per.dt_status_tstz < =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY)
                       AND per.dt_status_tstz >
                           (current_timestamp - get_mcdt_active_count(i_lang, i_prof, tt.column_value, i_type))) t;
    
        l_desc_name        table_varchar;
        l_active_count     table_number;
        l_message          VARCHAR2(1000 CHAR);
        l_active_status    table_varchar;
        l_active_status_dt table_varchar;
        l_params           VARCHAR2(1000 CHAR);
        l_code_mess        VARCHAR2(1000 CHAR);
    BEGIN
        l_params   := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient || ' i_mcdt.count=' ||
                      i_mcdt.count || ' i_type=' || i_type;
        g_error    := 'Init get_pat_mcdt_active_count / ' || l_params;
        l_message  := '';
        o_flg_show := pk_ref_constant.g_no;
        g_retval   := pk_ref_core.get_pat_active_status(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        o_active_status    => l_active_status,
                                                        o_active_status_dt => l_active_status_dt,
                                                        o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'CASE i_type / ' || l_params;
        CASE
            WHEN i_type = pk_ref_constant.g_p1_type_a THEN
            
                OPEN c_analysis(l_active_status);
                FETCH c_analysis BULK COLLECT
                    INTO l_desc_name, l_active_count;
                CLOSE c_analysis;
            
                l_code_mess := pk_ref_constant.g_ref_analysis_presc_m001;
            
            WHEN i_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e) THEN
            
                OPEN c_exam(l_active_status);
                FETCH c_exam BULK COLLECT
                    INTO l_desc_name, l_active_count;
                CLOSE c_exam;
            
                l_code_mess := pk_ref_constant.g_ref_exam_presc_m001;
            
            WHEN i_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f) THEN
            
                OPEN c_intervention(l_active_status);
                FETCH c_intervention BULK COLLECT
                    INTO l_desc_name, l_active_count;
                CLOSE c_intervention;
            
                l_code_mess := pk_ref_constant.g_ref_interv_presc_m001;
            
            ELSE
                NULL;
        END CASE;
    
        g_error := 'o_flg_show=' || o_flg_show || ' / ' || l_params;
        IF l_desc_name.count > 0
        THEN
            g_error := 'FOR i IN 1 .. ' || l_desc_name.count || ' / ' || l_params;
            FOR i IN 1 .. l_desc_name.count
            LOOP
                l_message := l_message || chr(10) || '- <b>' || l_desc_name(i) || '</b>' ||
                             pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_ref_mcdt_presc_m001) ||
                             l_active_count(i) ||
                             pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => pk_ref_constant.g_ref_mcdt_presc_m002);
            END LOOP;
        
            g_error     := 'o_flg_show / ' || g_error;
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_doctor_cs_t078);
            o_msg       := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => l_code_mess),
                                   '@1',
                                   l_message);
            o_button    := pk_ref_constant.g_button_read;
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
                                              i_function => 'GET_PAT_MCDT_ACTIVE_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_mcdt_active_count;

    /**
    * Insert tasks
    *
    * @param   I_LANG     Language associated to the professional executing the request
    * @param   I_PROF     Professional, institution and software ids
    * @param   i_ext_req  Referral id   
    * @param   i_id_task  Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info  Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_date     Operation date
    * @param   O_ERROR    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   09-10-2007
    */
    FUNCTION create_tasks_done
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_id_tasks IN table_table_number,
        i_id_info  IN table_table_number,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_patient_data_task(x p1_external_request.id_external_request%TYPE) IS
            SELECT id_task_done
              FROM p1_task_done td
             WHERE td.id_external_request = x
               AND td.flg_type = pk_ref_constant.g_p1_task_done_type_z;
    
        l_tsd p1_task_done%ROWTYPE;
    
        l_error         t_error_out;
        l_pat           patient.id_patient%TYPE;
        l_flg_task_done VARCHAR2(1 CHAR);
        l_flg_status    p1_external_request.flg_status%TYPE;
        l_id_task_done  p1_task_done.id_task_done%TYPE;
    
        l_dt_completed_tstz p1_task_done.dt_completed_tstz%TYPE; -- ACM 2009-04-27 ALERT-24625
        l_p1_fill_id_data   sys_config.value%TYPE;
        l_p1_task_done      p1_task_done%ROWTYPE;
        l_op                PLS_INTEGER;
        l_var               p1_task_done.id_task_done%TYPE;
        l_op_date           p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------     
        g_error := 'Init create_tasks_done / ID_REF=' || i_ext_req;
        pk_alertlog.log_debug(g_error);
        --l_op_date := nvl(i_date, current_timestamp);
        l_op_date := nvl(i_date, pk_ref_utils.get_sysdate);
    
        l_p1_fill_id_data := pk_sysconfig.get_config('P1_FILL_ID_DATA', i_prof);
    
        ----------------------
        -- FUNC
        ----------------------     
        g_error := 'SELECT / ID_REF=' || i_ext_req;
        SELECT id_patient, flg_status
          INTO l_pat, l_flg_status
          FROM p1_external_request
         WHERE id_external_request = i_ext_req;
    
        l_tsd.id_external_request := i_ext_req;
        l_tsd.notes               := NULL;
        l_tsd.dt_inserted_tstz    := l_op_date;
        l_tsd.dt_completed_tstz   := NULL;
    
        -- Check if task "Complete missing patient data" is already done
        g_error := 'OPEN c_patient_data_task(' || i_ext_req || ')';
        OPEN c_patient_data_task(i_ext_req);
        FETCH c_patient_data_task
            INTO l_id_task_done;
        g_found := c_patient_data_task%FOUND;
        CLOSE c_patient_data_task;
    
        IF NOT g_found
        THEN
            -- Task 'Complete missing patient data' not completed
            l_flg_task_done     := pk_ref_constant.g_no;
            l_dt_completed_tstz := l_tsd.dt_completed_tstz;
        
            g_error := 'Call pk_ref_core.check_mandatory_data / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
            IF pk_ref_core.check_mandatory_data(i_lang   => i_lang,
                                                i_prof   => i_prof,
                                                i_pat    => l_pat,
                                                i_id_ref => i_ext_req,
                                                o_error  => l_error)
            THEN
                l_flg_task_done     := pk_ref_constant.g_yes;
                l_dt_completed_tstz := l_op_date;
            END IF;
        
            -- Inserting task 'Complete missing patient data'
            g_error        := 'Clean l_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
            l_p1_task_done := NULL;
        
            g_error                            := 'fill l_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' ||
                                                  l_pat;
            l_p1_task_done.id_task             := to_number(l_p1_fill_id_data);
            l_p1_task_done.id_external_request := l_tsd.id_external_request;
            l_p1_task_done.flg_task_done       := l_flg_task_done;
            l_p1_task_done.flg_type            := pk_ref_constant.g_p1_task_done_type_z; -- Complete (P)atient data
            l_p1_task_done.notes               := l_tsd.notes;
            l_p1_task_done.dt_inserted_tstz    := l_tsd.dt_inserted_tstz;
            l_p1_task_done.dt_completed_tstz   := l_dt_completed_tstz;
        
            IF l_flg_task_done = pk_ref_constant.g_yes
            THEN
                l_p1_task_done.id_prof_exec := i_prof.id;
                l_p1_task_done.id_inst_exec := i_prof.institution;
            ELSE
                -- not completed yet
                l_p1_task_done.id_prof_exec := NULL;
                l_p1_task_done.id_inst_exec := NULL;
            END IF;
        
            l_p1_task_done.flg_status      := pk_ref_constant.g_active;
            l_p1_task_done.id_group        := NULL;
            l_p1_task_done.id_professional := i_prof.id;
            l_p1_task_done.id_institution  := i_prof.institution;
        
            g_error  := 'Calling PK_REF_API.set_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
            g_retval := pk_ref_api.set_p1_task_done(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_p1_task_done => l_p1_task_done,
                                                    o_id_task_done => l_var,
                                                    o_error        => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        -- Tasks "For scheduling"        
        FOR i IN 1 .. i_id_tasks.count
        LOOP
            g_error            := 'ID_TASKS(' || i || ') / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
            l_tsd.id_task      := i_id_tasks(i) (1); -- id_task
            l_tsd.id_group     := i_id_tasks(i) (2); -- id_group
            l_tsd.id_task_done := i_id_tasks(i) (4); -- id_task_done
        
            l_op := i_id_tasks(i) (3); -- id_operator
        
            IF nvl(l_op, pk_ref_constant.g_task_done_insert) = pk_ref_constant.g_task_done_insert
            THEN
            
                g_error := 'INSERT P1_TASK_DONE / ID_TASK=' || l_tsd.id_task || '|ID_EXT_REQ=' ||
                           l_tsd.id_external_request || '|ID_GROUP=' || l_tsd.id_group || '|FLG_TYPE=S';
                pk_alertlog.log_debug(g_error);
            
                g_error                            := 'Clean l_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' ||
                                                      l_pat;
                l_p1_task_done                     := NULL;
                l_p1_task_done.id_task             := l_tsd.id_task;
                l_p1_task_done.id_external_request := l_tsd.id_external_request;
                l_p1_task_done.flg_task_done       := pk_ref_constant.g_no; -- Not completed
                l_p1_task_done.flg_type            := pk_ref_constant.g_p1_task_done_type_s; -- Needed for (S)cheduling
                l_p1_task_done.notes               := l_tsd.notes;
                l_p1_task_done.dt_inserted_tstz    := l_tsd.dt_inserted_tstz;
                l_p1_task_done.dt_completed_tstz   := l_tsd.dt_completed_tstz;
                l_p1_task_done.id_prof_exec        := NULL;
                l_p1_task_done.id_inst_exec        := NULL;
                l_p1_task_done.flg_status          := pk_ref_constant.g_active;
                l_p1_task_done.id_group            := l_tsd.id_group;
                l_p1_task_done.id_professional     := i_prof.id;
                l_p1_task_done.id_institution      := i_prof.institution;
            
                g_error  := 'Calling PK_REF_API.set_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
                g_retval := pk_ref_api.set_p1_task_done(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_p1_task_done => l_p1_task_done,
                                                        o_id_task_done => l_var,
                                                        o_error        => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSIF l_op = pk_ref_constant.g_task_done_update
            THEN
            
                g_error := 'UPDATE P1_TASK_DONE / ID_TASK=' || l_tsd.id_task || '|ID_EXT_REQ=' ||
                           l_tsd.id_external_request || '|ID_GROUP=' || l_tsd.id_group || '|FLG_TYPE=S|FLG_STATUS=' ||
                           pk_ref_constant.g_cancelled || ' ID_TASK_DONE=' || l_tsd.id_task_done;
                UPDATE p1_task_done
                   SET flg_status = pk_ref_constant.g_cancelled
                 WHERE id_task_done = l_tsd.id_task_done
                   AND flg_type = pk_ref_constant.g_p1_task_done_type_s; -- Needed for (S)cheduling   
            
            ELSIF l_op = pk_ref_constant.g_task_done_delete
            THEN
                g_error := 'Deleting P1_TASK_DONE ID_TASK=' || l_tsd.id_task || '|ID_EXT_REQ=' ||
                           l_tsd.id_external_request || '|ID_GROUP=' || l_tsd.id_group || '|FLG_TYPE=S';
                DELETE FROM p1_task_done
                 WHERE id_task = l_tsd.id_task
                   AND id_external_request = l_tsd.id_external_request
                   AND id_group = l_tsd.id_group
                   AND flg_type = pk_ref_constant.g_p1_task_done_type_s;
            END IF;
        END LOOP;
    
        -- Tasks "For appointment"
        FOR i IN 1 .. i_id_info.count
        LOOP
        
            g_error            := 'ID_INFO(' || i || ') / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
            l_tsd.id_task      := i_id_info(i) (1); -- id_task
            l_tsd.id_group     := i_id_info(i) (2); -- id_group
            l_tsd.id_task_done := i_id_info(i) (4); -- id_task_done
        
            l_op := i_id_info(i) (3); -- id_operator
        
            IF nvl(l_op, pk_ref_constant.g_task_done_insert) = pk_ref_constant.g_task_done_insert
            THEN
            
                g_error := 'INSERT INTO P1_TASK_DONE / ID_TASK=' || l_tsd.id_task || '|ID_EXT_REQ=' ||
                           l_tsd.id_external_request || '|ID_GROUP=' || l_tsd.id_group || '|FLG_TYPE=C';
                pk_alertlog.log_debug(g_error);
            
                g_error                            := 'Clean l_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' ||
                                                      l_pat;
                l_p1_task_done                     := NULL;
                l_p1_task_done.id_task             := l_tsd.id_task;
                l_p1_task_done.id_external_request := l_tsd.id_external_request;
                l_p1_task_done.flg_task_done       := pk_ref_constant.g_no; -- Not completed
                l_p1_task_done.flg_type            := pk_ref_constant.g_p1_task_done_type_c; -- Needed for the (C)onsultation
                l_p1_task_done.notes               := l_tsd.notes;
                l_p1_task_done.dt_inserted_tstz    := l_tsd.dt_inserted_tstz;
                l_p1_task_done.dt_completed_tstz   := l_tsd.dt_completed_tstz;
                l_p1_task_done.id_prof_exec        := NULL;
                l_p1_task_done.id_inst_exec        := NULL;
                l_p1_task_done.flg_status          := pk_ref_constant.g_active;
                l_p1_task_done.id_group            := l_tsd.id_group;
                l_p1_task_done.id_professional     := i_prof.id;
                l_p1_task_done.id_institution      := i_prof.institution;
            
                g_error  := 'Calling PK_REF_API.set_p1_task_done / ID_REF=' || i_ext_req || ' ID_PATIENT=' || l_pat;
                g_retval := pk_ref_api.set_p1_task_done(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_p1_task_done => l_p1_task_done,
                                                        o_id_task_done => l_var,
                                                        o_error        => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSIF l_op = pk_ref_constant.g_task_done_update
            THEN
            
                g_error := 'UPDATE P1_TASK_DONE / ID_TASK=' || l_tsd.id_task || '|ID_EXT_REQ=' ||
                           l_tsd.id_external_request || '|ID_GROUP=' || l_tsd.id_group || '|FLG_TYPE=C|FLG_STATUS=' ||
                           pk_ref_constant.g_cancelled || ' ID_TASK_DONE=' || l_tsd.id_task_done;
                UPDATE p1_task_done
                   SET flg_status = pk_ref_constant.g_cancelled
                 WHERE id_task_done = l_tsd.id_task_done
                   AND flg_type = pk_ref_constant.g_p1_task_done_type_c; -- Needed for (C)onsultation
            
            ELSIF l_op = pk_ref_constant.g_task_done_delete
            THEN
                g_error := 'Deleting P1_TASK_DONE / ID_TASK=' || l_tsd.id_task || '|ID_EXT_REQ=' ||
                           l_tsd.id_external_request || '|ID_GROUP=' || l_tsd.id_group || '|FLG_TYPE=C';
                DELETE FROM p1_task_done
                 WHERE id_task = l_tsd.id_task
                   AND id_external_request = l_tsd.id_external_request
                   AND id_group = l_tsd.id_group
                   AND flg_type = pk_ref_constant.g_p1_task_done_type_c;
            END IF;
        
        END LOOP;
    
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
                                              i_function => 'CREATE_TASKS_DONE',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_tasks_done;

    /***********************************************************************************************************
    FUNCTION NAME: GET_P1_NUM_REQ
    FUNCTION GOAL: RETURNS NEXT CODE_NUMBER FOR P1_EXTERNAL_REQUEST
    RETURN:      : VARCHAR2.
    
    
    PARAMETERS NAME         TYPE            DESCRIPTION
    I_LANG                NUMBER            ID OF CURRENT LANGUAGE
    I_ID_INST                       PROFISSIONAL    ID OF INSTITUITION
    O_ERROR                VARCHAR2        ERROR MESSAGE WHEN APPLICABLE.
    *************************************************************************************************************/
    FUNCTION get_ref_num_req(i_inst IN NUMBER) RETURN VARCHAR2 IS
        xreturn VARCHAR2(0050);
        xval    NUMBER;
    BEGIN
    
        SELECT seq_p1_external_request.currval
          INTO xval
          FROM dual;
    
        xreturn := lpad(to_char(xval), 8, '0') ||
                   lpad(pk_sysconfig.get_config('ID_IMPLEMENTATION', profissional(0, 0, 0)), 4, '0');
    
        RETURN xreturn;
    
    END get_ref_num_req;

    /**
    * Cancel referral
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof id professional, institution and software    
    * @param   i_ext_req        Referral identifier    
    * @param   i_id_patient     Patient identifier
    * @param   i_id_episode     Episode identifier        
    * @param   i_notes          Cancelation notes 
    * @param   i_reason         Cancelation reason 
    * @param   i_transaction_id Scheduler 3.0 identifier
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason         IN p1_reason_code.id_reason_code%TYPE,
        i_transaction_id IN VARCHAR2,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row        p1_external_request%ROWTYPE;
        l_prof_data      t_rec_prof_data;
        l_param          table_varchar;
        l_transaction_id VARCHAR2(4000);
        l_params         VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_ext_req || ' i_id_patient=' ||
                    i_id_patient || ' i_id_episode=' || i_id_episode || ' i_reason=' || i_reason;
        g_error  := 'Init cancel_referral / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_track := table_number();
    
        g_error          := 'Call  pk_schedule_api_upstream.begin_new_transaction / ' || l_params ||
                            ' / i_transaction_id=' || i_transaction_id;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        g_error  := 'Call pk_ref_core.get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- processing action CANCEL
        g_error  := 'Call pk_ref_core.process_transition / ' || l_params || ' /  FLG_STATUS=' || l_ref_row.flg_status ||
                    ' ACTION=' || pk_ref_constant.g_ref_action_c;
        g_retval := pk_ref_core.process_transition2(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_prof_data      => l_prof_data,
                                                    i_ref_row        => l_ref_row,
                                                    i_action         => pk_ref_constant.g_ref_action_c,
                                                    i_status_end     => NULL,
                                                    i_notes          => i_notes,
                                                    i_reason_code    => i_reason,
                                                    i_date           => NULL,
                                                    io_param         => l_param,
                                                    io_track         => o_track,
                                                    i_transaction_id => l_transaction_id,
                                                    o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REFERRAL',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancel_referral;

    /**
    * Get help data for this speciality (p1_speciality)/institution
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_P1_SPEC request speciality id
    * @param   O_HELP canceling reason id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION get_spec_help
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_p1_spec IN p1_speciality.id_speciality%TYPE,
        i_inst    IN institution.id_institution%TYPE,
        o_help    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_spec_help / ID_REF=' || i_p1_spec || ' i_inst=' || i_inst;
        OPEN o_help FOR
            SELECT pk_translation.get_translation(i_lang, code_title) title,
                   pk_translation.get_translation(i_lang, code_text) text
              FROM (SELECT sh.code_title, sh.code_text
                      FROM p1_spec_help sh
                     WHERE sh.id_speciality = i_p1_spec
                       AND sh.id_institution = i_inst
                       AND sh.flg_available = pk_ref_constant.g_yes
                     ORDER BY sh.rank);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SPEC_HELP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_help);
            RETURN FALSE;
    END get_spec_help;

    /**
    * Validates if the professional can add tasks to be executed by the registrar of the origin institution    
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer
    * @param   i_ref          Referral identifier
    * @param   i_inst_orig    Referral orig institution identifier
    * @param   o_can_add      Flag indicating if the professional can add tasks to be executed by the registrar  
    * @param   o_error        An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-03-25
    */
    FUNCTION can_add_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref       IN p1_external_request.id_external_request%TYPE,
        i_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        o_can_add   OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref IS
            SELECT exr.flg_status, exr.id_prof_requested
              FROM p1_external_request exr
             WHERE exr.id_external_request = i_ref;
    
        l_flg_status        p1_external_request.flg_status%TYPE;
        l_id_prof_requested p1_external_request.id_prof_requested%TYPE;
    
        l_flg_result VARCHAR2(1 CHAR);
        l_params     VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ref=' || i_ref || ' i_inst_orig=' || i_inst_orig;
        g_error  := 'Init can_add_tasks / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_can_add := pk_ref_constant.g_no;
    
        -- check if orig institution is private or not
        g_error  := 'Call pk_ref_core.check_private_inst / ' || l_params;
        g_retval := pk_ref_core.check_private_inst(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_inst    => i_inst_orig,
                                                   o_flg_result => l_flg_result,
                                                   o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := g_error || ' RESULT=' || l_flg_result;
        IF l_flg_result = pk_ref_constant.g_yes
        THEN
            -- is private, cannot add tasks
            o_can_add := pk_ref_constant.g_no;
        ELSE
        
            g_error := 'OPEN c_ref / ' || l_params || ' / l_flg_result=' || l_flg_result;
            OPEN c_ref;
            FETCH c_ref
                INTO l_flg_status, l_id_prof_requested;
            CLOSE c_ref;
        
            IF i_ref IS NULL
            THEN
                -- when creating the referral, the id_external_request is null
                -- professional can add tasks
                g_error   := 'Creating the referral / ' || l_params;
                o_can_add := pk_ref_constant.g_yes;
            ELSE
            
                g_error := 'I_PROF.ID=' || i_prof.id || ' ID_REF=' || i_ref || ' ID_PROF_REQUESTED=' ||
                           l_id_prof_requested || ' FLG_STATUS=' || l_flg_status;
                IF i_prof.id = l_id_prof_requested -- must be the professional that created the referral
                   AND l_flg_status IN -- referral must be in one of these states
                   (pk_ref_constant.g_p1_status_o,
                        pk_ref_constant.g_p1_status_n,
                        pk_ref_constant.g_p1_status_d,
                        pk_ref_constant.g_p1_status_y)
                THEN
                    o_can_add := pk_ref_constant.g_yes;
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
                                              i_function => 'CAN_ADD_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
    END can_add_tasks;

    /**
    * Creates an EHR episode (to be used in referral)    
    *
    * @param   i_lang               Language identififer
    * @param   i_prof               Professional identififer
    * @param   i_id_patient         Patient identifier
    * @param   i_id_dep_clin_serv   Department and clinical service identifier
    * @param   o_id_episode         Episode identifier  
    * @param   o_error              An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise    
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-07-2011
    */
    FUNCTION create_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN p1_external_request.id_patient%TYPE,
        i_id_dep_clin_serv IN p1_external_request.id_dep_clin_serv%TYPE,
        o_id_episode       OUT p1_external_request.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(200 CHAR);
    BEGIN
    
        g_error := 'Init can_add_tasks / ID_PATIENT=' || i_id_patient || ' ID_DEP_CLIN_SERV=' || i_id_dep_clin_serv;
        pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call pk_ehr_access.create_ehr_access_no_commit / ID_PATIENT=' || i_id_patient ||
                    ' ID_DEP_CLIN_SERV=' || i_id_dep_clin_serv;
        g_retval := pk_ehr_access.create_ehr_access_no_commit(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_patient       => i_id_patient,
                                                              i_id_episode       => NULL,
                                                              i_id_schedule      => NULL,
                                                              i_access_area      => 2, -- 2 - criar processo clínico electrónico
                                                              i_access_type      => NULL,
                                                              i_id_access_reason => table_number(),
                                                              i_access_text      => NULL,
                                                              i_new_ehr_event    => NULL,
                                                              i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                              i_transaction_id   => NULL,
                                                              o_episode          => o_id_episode,
                                                              o_flg_show         => l_flg_show,
                                                              o_msg_title        => l_msg_title,
                                                              o_msg              => l_msg,
                                                              o_button           => l_button,
                                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
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
                                              i_function => 'CREATE_EPISODE',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_episode;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_orig_phy;
/
