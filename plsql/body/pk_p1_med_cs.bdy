/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_med_cs AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_retval       BOOLEAN;
    g_error        VARCHAR2(4000 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_found        BOOLEAN;

    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;

    --CheckISO7064Mod11_2  
    FUNCTION cumpute_check(i_string VARCHAR2) RETURN NUMBER IS
        l_p          PLS_INTEGER;
        l_str_length PLS_INTEGER;
        l_c          PLS_INTEGER;
    BEGIN
        l_str_length := length(i_string);
        l_p          := 0;
        FOR i IN 0 .. l_str_length - 1
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
    * Service to create a referral request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_patient          Patient identifier
    * @param   i_speciality          Request speciality (P1_SPECIALITY)
    * @param   i_id_dep_clin_serv    Department/clinical_service identifier (can be null)
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            (A)nalisys; (C)onsultation (E)xam, (I)ntervention,
    * @param   i_flg_priority        Referral priority flag
    * @param   i_flg_home            Referral home flag
    * @param   i_inst_dest           Destination institution
    * @param   i_id_sched            @deprecated
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done       
    * @param   i_epis                Episode where the referral was created
    * @param   i_external_sys        External system identifier that is creating the referral           
    * @param   i_date                Operation date   
    * @param   i_comments            Referral comments [ID_ref_comment|Flg_Status|text]
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    */
    FUNCTION create_external_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_epis             IN episode.id_episode%TYPE,
        i_external_sys     IN p1_external_request.id_external_sys%TYPE DEFAULT NULL,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto 
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_fam_rel_spec     IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan         IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption           IN NUMBER DEFAULT NULL,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr            p1_external_request%ROWTYPE;
        l_track_row      p1_tracking%ROWTYPE;
        l_rowids         table_varchar;
        l_exception      EXCEPTION;
        l_detail         table_table_varchar;
        l_flg_available  VARCHAR2(1 CHAR);
        l_params         VARCHAR2(1000 CHAR);
        o_track          table_number;
        l_track_tab      table_number;
        l_id_ref_comment ref_comments.id_ref_comment%TYPE;
    
        l_problems  pk_edis_types.rec_in_epis_diagnoses;
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params       := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient ||
                          ' i_speciality=' || i_speciality || ' i_dcs=' || i_id_dep_clin_serv || ' i_req_type=' ||
                          i_req_type || ' i_flg_type=' || i_flg_type || ' i_flg_priority=' || i_flg_priority ||
                          ' i_flg_home=' || i_flg_home || ' i_inst_dest=' || i_inst_dest || ' i_dt_problem_begin=' ||
                          i_dt_problem_begin || ' i_completed=' || i_completed || ' i_epis=' || i_epis ||
                          ' i_external_sys=' || i_external_sys;
        g_error        := 'Init create_external_request / ' || l_params;
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        ----------------------
        -- VAL
        ----------------------    
    
        -- check dep_clin_serv - this validation was already done in flash/interface layer... double checking...
        IF i_id_dep_clin_serv IS NOT NULL
        THEN
            g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv / ' || l_params;
            g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_inst_dest  => i_inst_dest,
                                                          i_dcs           => i_id_dep_clin_serv,
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
        -- FUNC
        ----------------------        
        g_error                   := 'GET SEQ_P1_EXTERNAL_REQUEST.NEXTVAL / ' || l_params;
        l_exr.id_external_request := ts_p1_external_request.next_key;
    
        g_error                := 'Fill referral data / ' || l_params;
        l_exr.id_patient       := i_id_patient;
        l_exr.num_req          := l_exr.id_external_request;
        l_exr.id_speciality    := i_speciality;
        l_exr.req_type         := i_req_type;
        l_exr.flg_type         := i_flg_type;
        l_exr.flg_priority     := i_flg_priority;
        l_exr.flg_home         := i_flg_home;
        l_exr.id_external_sys  := i_external_sys;
        l_exr.id_dep_clin_serv := i_id_dep_clin_serv;
    
        IF i_completed = pk_ref_constant.g_yes
        THEN
            l_exr.flg_status := pk_ref_constant.g_p1_status_n;
        
            IF i_inst_dest IS NULL
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_exr.flg_status := pk_ref_constant.g_p1_status_o;
        END IF;
    
        g_error                         := 'Fill referral data 2 / ' || l_params;
        l_exr.id_prof_status            := i_prof.id;
        l_exr.dt_status_tstz            := g_sysdate_tstz;
        l_exr.id_inst_orig              := i_prof.institution;
        l_exr.id_prof_requested         := i_prof.id;
        l_exr.id_prof_created           := i_prof.id;
        l_exr.id_inst_dest              := i_inst_dest;
        l_exr.flg_paper_doc             := pk_ref_constant.g_no;
        l_exr.flg_digital_doc           := pk_ref_constant.g_no;
        l_exr.flg_mail                  := pk_ref_constant.g_no;
        l_exr.dt_requested              := g_sysdate_tstz;
        l_exr.id_workflow               := NULL;
        l_exr.id_episode                := i_epis;
        l_exr.prof_certificate          := i_prof_cert;
        l_exr.prof_name                 := i_prof_first_name;
        l_exr.prof_surname              := i_prof_surname;
        l_exr.prof_phone                := i_prof_phone;
        l_exr.id_fam_rel                := i_id_fam_rel;
        l_exr.family_relationship_notes := i_fam_rel_spec;
        l_exr.name_first_rel            := i_name_first_rel;
        l_exr.name_middle_rel           := i_name_middle_rel;
        l_exr.name_last_rel             := i_name_last_rel;
        l_exr.id_pat_health_plan        := i_health_plan;
        l_exr.id_pat_exemption          := i_exemption;
    
        -- ALERT-194568: problem begin date
        --l_exr.dt_probl_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_problem_begin, NULL);
        g_error  := 'Call pk_ref_utils.parse_dt_str / ' || l_params;
        g_retval := pk_ref_utils.parse_dt_str(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dt_str_flash => i_dt_problem_begin,
                                              o_year         => l_exr.year_begin,
                                              o_month        => l_exr.month_begin,
                                              o_day          => l_exr.day_begin,
                                              o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call ts_p1_external_request.ins / ' || l_params;
        ts_p1_external_request.ins(rec_in => l_exr, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error                         := 'UPDATE STATUS / ' || l_params;
        l_track_row.id_external_request := l_exr.id_external_request;
        l_track_row.ext_req_status      := l_exr.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_dep_clin_serv    := l_exr.id_dep_clin_serv;
        l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        l_track_row.id_speciality       := l_exr.id_speciality;
    
        IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
        THEN
            l_track_row.id_inst_dest       := l_exr.id_inst_dest;
            l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_n);
        END IF;
    
        g_error  := 'Call pk_p1_core.update_status / ' || l_params;
        g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_track_row   => l_track_row,
                                             i_old_status  => pk_ref_constant.g_p1_status_n ||
                                                              pk_ref_constant.g_p1_status_o,
                                             i_flg_isencao => NULL,
                                             i_mcdt_nature => NULL,
                                             o_track       => l_track_tab,
                                             o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_track := o_track MULTISET UNION l_track_tab;
    
        g_error  := 'Referral details / ' || i_detail.count || ' / ' || l_params;
        l_detail := i_detail;
    
        -- adding flg_priority and flg_home to l_detail
        -- i_detail format: [id_detail|flg_type|text|flg|id_group]
        g_error  := 'Call pk_ref_orig_phy.add_flgs_to_detail / ' || l_params;
        g_retval := pk_ref_orig_phy.add_flgs_to_detail(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_ref       => l_exr.id_external_request,
                                                       i_flg_priority => l_exr.flg_priority,
                                                       i_flg_home     => l_exr.flg_home,
                                                       io_detail_tab  => l_detail,
                                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Inserting details in P1_DETAIL       
        g_error  := 'Calling pk_ref_core.set_detail / ' || l_params;
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_ext_req       => l_exr.id_external_request,
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
    
        -- Problems
        IF l_problems.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_problems.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_problems.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error := 'INSERT DIAGNOSIS' || pk_ref_constant.g_exr_diag_type_p || ' / ' || l_params;
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status,
                         year_begin,
                         month_begin,
                         day_begin) -- ALERT-275636
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         l_exr.id_external_request,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_p,
                         pk_ref_constant.g_active,
                         l_exr.year_begin, -- all problems have the same problem begin date
                         l_exr.month_begin,
                         l_exr.day_begin);
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
    
        IF l_diagnoses.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_diagnoses.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_diagnoses.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error := 'INSERT DIAGNOSIS' || pk_ref_constant.g_exr_diag_type_p || ' / ' || l_params;
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status,
                         year_begin,
                         month_begin,
                         day_begin) -- ALERT-275636
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         l_exr.id_external_request,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_d,
                         pk_ref_constant.g_active,
                         l_exr.year_begin, -- all problems have the same problem begin date
                         l_exr.month_begin,
                         l_exr.day_begin);
                END IF;
            END LOOP;
        END IF;
    
        g_error  := 'Call pk_ref_orig_phy.create_tasks_done / ' || l_params;
        g_retval := pk_ref_orig_phy.create_tasks_done(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_ext_req  => l_exr.id_external_request,
                                                      i_id_tasks => i_id_tasks,
                                                      i_id_info  => i_id_info,
                                                      i_date     => g_sysdate_tstz,
                                                      o_error    => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Issue referral if completed   
        IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
        THEN
        
            -- l_exr.id_dep_clin_serv is already filled with dep_clin_serv (if FLG_VISIBLE_ORIG=Y)
            g_error  := 'Call pk_p1_core.issue_request / ' || l_params;
            g_retval := pk_p1_core.issue_request(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_ext_req => l_exr.id_external_request,
                                                 i_date    => g_sysdate_tstz,
                                                 o_track   => l_track_tab,
                                                 o_error   => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            o_track := o_track MULTISET UNION l_track_tab;
        
        END IF;
    
        o_id_external_request := l_exr.id_external_request;
    
        g_error := 'i_epis=' || i_epis || ' / ' || l_params;
        IF i_epis IS NOT NULL
        THEN
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
                                                                   i_id_ref         => l_exr.id_external_request,
                                                                   i_text           => i_comments(i) (3),
                                                                   i_dt_comment     => g_sysdate_tstz,
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
    
        -- ALERT-70087
        IF nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_create_msg, i_prof => i_prof),
               pk_ref_constant.g_no) = pk_ref_constant.g_yes
           AND l_exr.flg_status != pk_ref_constant.g_p1_status_o
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t003);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        
        ELSIF nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_temp_msg, i_prof => i_prof),
                  pk_ref_constant.g_no) = pk_ref_constant.g_yes
              AND l_exr.flg_status = pk_ref_constant.g_p1_status_o
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
        WHEN l_exception THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'P1_DOCTOR_CS_T073');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'P1_DOCTOR_CS_T073',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CREATE_EXTERNAL_REQUEST',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'CREATE_EXTERNAL_REQUEST',
                                                     o_error    => o_error);
    END create_external_request;

    /**
    * Updates referral info
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_speciality          Referral speciality identifier (P1_SPECIALITY)    
    * @param   i_id_dep_clin_serv    Department/clinical_service identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority        Referral priority flag
    * @param   i_flg_home            Referral home flag
    * @param   i_inst_dest           Destination institution
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done           
    * @param   i_date                Operation date
    * @param   i_comments            Referral comments [ID_ref_comment|Flg_Status|text]
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    */
    FUNCTION update_external_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto        
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_fam_rel_spec     IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan         IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption           IN NUMBER DEFAULT NULL,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exr_ori p1_external_request%ROWTYPE;
        l_exr     p1_external_request%ROWTYPE;
    
        CURSOR c_p1 IS
            SELECT *
              FROM p1_external_request
             WHERE id_external_request = i_ext_req
               FOR UPDATE;
    
        l_track_row          p1_tracking%ROWTYPE;
        l_rowids             table_varchar;
        e_invalid_status     EXCEPTION;
        l_exception          EXCEPTION;
        l_flg_status         p1_external_request.flg_status%TYPE;
        l_detail             table_table_varchar;
        l_flg_status_ori     p1_external_request.flg_status%TYPE;
        l_old_status         VARCHAR2(50 CHAR);
        l_config             VARCHAR2(1 CHAR);
        l_params             VARCHAR2(1000 CHAR);
        l_flg_available      VARCHAR2(1 CHAR);
        o_track              table_number;
        l_track_tab          table_number;
        l_id_ref_comment     ref_comments.id_ref_comment%TYPE;
        l_id_ref_comment_arr table_number;
    
        l_problems  pk_edis_types.rec_in_epis_diagnoses;
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    
        l_wf_ref_med sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'REFERRAL_WF_MED', i_prof => i_prof);
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ext_req=' || i_ext_req || ' i_dt_modified=' ||
                    i_dt_modified || ' i_speciality=' || i_speciality || ' i_dcs=' || i_id_dep_clin_serv ||
                    ' i_req_type=' || i_req_type || ' i_flg_type=' || i_flg_type || ' i_flg_priority=' ||
                    i_flg_priority || ' i_flg_home=' || i_flg_home || ' i_inst_dest=' || i_inst_dest ||
                    ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed;
    
        g_error := 'Init update_external_request / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        ----------------------
        -- VAL
        ----------------------
        -- Valida se o P1 existe
        g_error := 'CHECK REQUEST / ' || l_params;
        OPEN c_p1;
        FETCH c_p1
            INTO l_exr_ori;
        g_found := c_p1%FOUND;
        CLOSE c_p1;
    
        g_error := 'REQUEST EXISTS / ' || l_params;
        IF NOT g_found
        THEN
            RAISE g_exception;
        END IF;
    
        -- check dep_clin_serv - this validation was already done in flash/interface layer... double checking...
        IF i_id_dep_clin_serv IS NOT NULL
        THEN
            g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv / ' || l_params;
            g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_inst_dest  => i_inst_dest,
                                                          i_dcs           => i_id_dep_clin_serv,
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
        -- FUNC
        ----------------------
        l_params         := l_params || ' WF=' || l_exr_ori.id_workflow || ' FLG_STATUS=' || l_exr_ori.flg_status;
        g_error          := l_params;
        l_flg_status_ori := l_exr_ori.flg_status;
    
        IF i_completed = pk_ref_constant.g_yes -- Pedido completo
        THEN
            CASE l_exr_ori.flg_status
                WHEN pk_ref_constant.g_p1_status_o THEN
                    l_exr.flg_status := pk_ref_constant.g_p1_status_n;
                
                WHEN pk_ref_constant.g_p1_status_d THEN
                    -- Declined
                    l_exr.flg_status := pk_ref_constant.g_p1_status_n;
                
                    IF pk_date_utils.trunc_insttimezone(i_prof, l_exr_ori.dt_last_interaction_tstz, 'SS') !=
                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
                    THEN
                        o_msg_title      := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'P1_DOCTOR_CS_T075');
                        o_msg            := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'P1_DOCTOR_CS_T076');
                        o_flg_show       := pk_ref_constant.g_yes;
                        o_button         := 'R';
                        l_exr.flg_status := l_exr_ori.flg_status; -- JS: 2007-04-18, Se o pedido for modificado enquanto é editado o profissional é avisado e o estado não é alterado
                    ELSE
                        l_exr.flg_status := pk_ref_constant.g_p1_status_n; -- Being created
                    END IF;
                
                ELSE
                    l_exr.flg_status := l_exr_ori.flg_status; -- In the remaining cases, do not change referral status
            END CASE;
        
        ELSE
            l_exr.flg_status := l_exr_ori.flg_status; -- if completed, do not change referral status
        END IF;
    
        g_error                   := 'Fill l_exr / ' || l_params;
        l_exr.id_external_request := i_ext_req;
        l_exr.id_prof_requested   := i_prof.id;
        l_exr.flg_priority        := i_flg_priority;
        l_exr.flg_home            := i_flg_home;
        l_exr.id_prof_status      := i_prof.id;
    
        IF l_exr_ori.flg_status = pk_ref_constant.g_p1_status_o
        THEN
            l_exr.id_speciality    := i_speciality;
            l_exr.id_inst_dest     := i_inst_dest;
            l_exr.id_dep_clin_serv := i_id_dep_clin_serv; -- ALERT-231108
        ELSE
            l_exr.id_speciality    := l_exr_ori.id_speciality;
            l_exr.id_inst_dest     := l_exr_ori.id_inst_dest;
            l_exr.id_dep_clin_serv := l_exr_ori.id_dep_clin_serv; -- ALERT-231108
        END IF;
    
        l_exr.dt_last_interaction_tstz  := g_sysdate_tstz;
        l_exr.id_prof_requested         := i_prof.id;
        l_exr.id_workflow               := NULL;
        l_exr.prof_certificate          := i_prof_cert;
        l_exr.prof_name                 := i_prof_first_name;
        l_exr.prof_surname              := i_prof_surname;
        l_exr.prof_phone                := i_prof_phone;
        l_exr.id_fam_rel                := i_id_fam_rel;
        l_exr.family_relationship_notes := i_fam_rel_spec;
        l_exr.name_first_rel            := i_name_first_rel;
        l_exr.name_middle_rel           := i_name_middle_rel;
        l_exr.name_last_rel             := i_name_last_rel;
        l_exr.id_pat_health_plan        := i_health_plan;
        l_exr.id_pat_exemption          := i_exemption;
    
        -- ALERT-194568: problem begin date
        g_error  := 'Call pk_ref_utils.parse_dt_str / ' || l_params;
        g_retval := pk_ref_utils.parse_dt_str(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dt_str_flash => i_dt_problem_begin,
                                              o_year         => l_exr.year_begin,
                                              o_month        => l_exr.month_begin,
                                              o_day          => l_exr.day_begin,
                                              o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call ts_p1_external_request.upd / ' || l_params;
        ts_p1_external_request.upd(id_external_request_in        => l_exr.id_external_request,
                                   flg_priority_in               => l_exr.flg_priority,
                                   flg_home_in                   => l_exr.flg_home,
                                   id_prof_status_in             => l_exr.id_prof_status,
                                   id_inst_dest_in               => l_exr.id_inst_dest,
                                   id_prof_requested_in          => l_exr.id_prof_requested,
                                   year_begin_in                 => l_exr.year_begin,
                                   year_begin_nin                => FALSE,
                                   month_begin_in                => l_exr.month_begin,
                                   month_begin_nin               => FALSE,
                                   day_begin_in                  => l_exr.day_begin,
                                   day_begin_nin                 => FALSE,
                                   dt_last_interaction_tstz_in   => l_exr.dt_last_interaction_tstz,
                                   id_speciality_in              => l_exr.id_speciality,
                                   id_dep_clin_serv_in           => l_exr.id_dep_clin_serv,
                                   prof_certificate_in           => l_exr.prof_certificate,
                                   prof_name_in                  => l_exr.prof_name,
                                   prof_surname_in               => l_exr.prof_surname,
                                   prof_phone_in                 => l_exr.prof_phone,
                                   id_fam_rel_in                 => l_exr.id_fam_rel,
                                   name_first_rel_in             => l_exr.name_first_rel,
                                   name_middle_rel_in            => l_exr.name_middle_rel,
                                   name_last_rel_in              => l_exr.name_last_rel,
                                   id_pat_health_plan_in         => i_health_plan,
                                   id_pat_health_plan_nin        => FALSE,
                                   id_pat_exemption_in           => i_exemption,
                                   id_pat_exemption_nin          => FALSE,
                                   family_relationship_notes_in  => l_exr.family_relationship_notes,
                                   family_relationship_notes_nin => FALSE,
                                   rows_out                      => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'Call pk_ref_orig_phy.create_tasks_done / ' || l_params;
        g_retval := pk_ref_orig_phy.create_tasks_done(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_ext_req  => i_ext_req,
                                                      i_id_tasks => i_id_tasks,
                                                      i_id_info  => i_id_info,
                                                      i_date     => g_sysdate_tstz,
                                                      o_error    => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_exr.flg_status != l_exr_ori.flg_status
        THEN
            -- Se o estado não muda não se regista mudança de estado, dah!
            -- Chama UPDATE_STATUS para registar no P1_TRACKING
            --- Retirado estado de partida 'N' - Correcção update simultaneo
            g_error                         := 'UPDATE STATUS S / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := l_exr.flg_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        
            IF l_track_row.ext_req_status = pk_ref_constant.g_p1_status_n
            THEN
                l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_n);
            END IF;
        
            IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
               AND l_exr_ori.flg_status = pk_ref_constant.g_p1_status_o
            THEN
                -- 2009-09-29, ALERT-46872: apenas no ambito da integracao do CARE-CTH e' que se ira
                -- afectar esta validacao. Nao devera' ser utilizada em mais nenhuma circunstancia...
                -- A mudar futuramente
                IF i_prof.software != pk_alert_constant.g_soft_primary_care
                THEN
                
                    IF l_exr.id_inst_dest IS NULL
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    l_track_row.id_inst_dest := l_exr.id_inst_dest;
                END IF;
            
                l_track_row.id_speciality    := l_exr.id_speciality;
                l_track_row.id_dep_clin_serv := l_exr.id_dep_clin_serv; -- ALERT-231108
            
            END IF;
        
            g_error  := 'Call pk_p1_core.update_status / FLG_TYPE=' || l_track_row.flg_type || ' / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_o ||
                                                                  pk_ref_constant.g_p1_status_d,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => l_track_tab,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            o_track := o_track MULTISET UNION l_track_tab;
        
            -- 2009-09-29, ALERT-46872: apenas no ambito da integracao do CARE-CTH e' que se ira
            -- afectar esta validacao. Nao devera' ser utilizada em mais nenhuma circunstancia...
            -- A mudar futuramente
            IF i_prof.software != pk_alert_constant.g_soft_primary_care
               OR l_wf_ref_med = pk_alert_constant.g_yes
            THEN
            
                -- JS: 2007-DEZ-17: Emitir se completo e sem tarefas pendentes 
                IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
                THEN
                    g_error  := 'Call pk_p1_core.issue_request / ' || l_params;
                    g_retval := pk_p1_core.issue_request(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_ext_req => i_ext_req,
                                                         i_date    => g_sysdate_tstz,
                                                         o_track   => l_track_tab,
                                                         o_error   => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    o_track := o_track MULTISET UNION l_track_tab;
                
                END IF;
            
            END IF;
        
        ELSE
            -- JS: 10-04-2007 Nos restantes casos faz registo de update (Novo tracking type)
            g_error  := 'Call pk_ref_status.check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_upd_sts_a_enabled ||
                        ' / ' || l_params;
            l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_config => pk_ref_constant.g_ref_upd_sts_a_enabled);
        
            g_error                         := 'UPDATE STATUS U / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := l_exr.flg_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_u;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        
            l_old_status := pk_ref_constant.g_p1_status_n || pk_ref_constant.g_p1_status_o ||
                            pk_ref_constant.g_p1_status_d || pk_ref_constant.g_p1_status_i ||
                            pk_ref_constant.g_p1_status_b || pk_ref_constant.g_p1_status_t ||
                            pk_ref_constant.g_p1_status_r;
        
            IF l_config = pk_ref_constant.g_yes
            THEN
                l_old_status := l_old_status || pk_ref_constant.g_p1_status_a; -- ALERT-66740
            END IF;
        
            g_error  := 'Call pk_p1_core.update_status / FLG_TYPE=' || l_track_row.flg_type || ' / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => l_old_status,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => l_track_tab,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            o_track := o_track MULTISET UNION l_track_tab;
        
        END IF;
    
        g_error := 'Referral details / ' || l_params;
        -- i_detail format: [id_detail|flg_type|text|flg|id_group]
        l_detail := i_detail;
    
        -- Outdate old details with flg_priority and flg_home and add new values (if different)
        g_error  := 'Call pk_ref_orig_phy.add_flgs_to_detail / ' || l_params;
        g_retval := pk_ref_orig_phy.add_flgs_to_detail(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_ref       => i_ext_req,
                                                       i_flg_priority => i_flg_priority,
                                                       i_flg_home     => i_flg_home,
                                                       io_detail_tab  => l_detail,
                                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- inserting all details 
        g_error  := 'Calling pk_ref_core.set_detail / ' || l_params;
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_ext_req       => i_ext_req,
                                           i_detail        => l_detail,
                                           i_ext_req_track => o_track(1), -- first iteration
                                           i_date          => g_sysdate_tstz,
                                           o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_p || ' / ' || l_params; -- Problems
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = i_ext_req
           AND flg_type = pk_ref_constant.g_exr_diag_type_p
           AND flg_status = pk_ref_constant.g_active;
    
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
                    g_error := 'INSERT DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_p; -- Problems
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         desc_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status,
                         year_begin,
                         month_begin,
                         day_begin) -- ALERT-275636
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         i_ext_req,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_p,
                         pk_ref_constant.g_active,
                         l_exr.year_begin, -- all problems have the same problem begin date
                         l_exr.month_begin,
                         l_exr.day_begin);
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'UPDATE DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_d || ' / ' || l_params; -- Diagnosis 
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = i_ext_req
           AND flg_type = pk_ref_constant.g_exr_diag_type_d
           AND flg_status = pk_ref_constant.g_active;
    
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
                    g_error := 'INSERT DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_d; -- Diagnosis
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         desc_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status)
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         i_ext_req,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_d,
                         pk_ref_constant.g_active);
                END IF;
            END LOOP;
        END IF;
    
        o_id_external_request := l_exr.id_external_request;
    
        g_error  := 'Call pk_p1_external_request.get_flg_status / ' || l_params;
        g_retval := pk_p1_external_request.get_flg_status(i_lang       => i_lang,
                                                          i_id_ref     => l_exr.id_external_request,
                                                          o_flg_status => l_flg_status,
                                                          o_error      => o_error);
    
        IF l_flg_status_ori != pk_ref_constant.g_p1_status_d
        THEN
            -- when the referral is declined, the event must be triggered when the transition N->I occurs
            -- done in PK_API_REF_EVENT.set_tracking
            g_error := 'Call pk_api_ref_event.set_ref_update / FLG_STATUS=' || l_flg_status || ' / ' || l_params;
            pk_api_ref_event.set_ref_update(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_ref     => l_exr.id_external_request,
                                            i_flg_status => l_flg_status,
                                            i_id_inst    => i_prof.institution);
        
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
                                                                   i_id_ref         => l_exr.id_external_request,
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
                                                                 i_id_ref         => l_exr.id_external_request,
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
                                                                   i_id_ref         => l_exr.id_external_request,
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
    
        -- show helpsave
        IF l_flg_status_ori = pk_ref_constant.g_p1_status_o
           AND l_flg_status != l_flg_status_ori
           AND nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_create_msg, i_prof => i_prof),
                   pk_ref_constant.g_no) = pk_ref_constant.g_yes
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t003);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        
        ELSIF l_flg_status_ori = pk_ref_constant.g_p1_status_o
              AND l_flg_status = l_flg_status_ori
              AND nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_temp_msg, i_prof => i_prof),
                      pk_ref_constant.g_no) = pk_ref_constant.g_yes
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
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_exception THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'P1_DOCTOR_CS_T073');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'P1_DOCTOR_CS_T073',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPDATE_EXTERNAL_REQUEST',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        WHEN e_invalid_status THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_EXTERNAL_REQUEST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_EXTERNAL_REQUEST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_external_request;

    FUNCTION get_interv_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_NOTES / I_ID_INTERV_PRESC_DET=' ||
                   i_interv_presc_det;
    
        RETURN pk_procedures_external_api_db.get_procedure_notes(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_interv_presc_det => i_interv_presc_det);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_interv_notes;

    FUNCTION get_rehab_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE
    ) RETURN VARCHAR IS
    
        CURSOR c_cur(x_rehab_presc rehab_presc.id_rehab_presc%TYPE) IS
            SELECT rsn.sessions, rp.notes
              FROM rehab_presc rp
              JOIN rehab_sch_need rsn
                ON (rp.id_rehab_sch_need = rsn.id_rehab_sch_need)
             WHERE rp.id_rehab_presc = x_rehab_presc;
    
        l_cur_row c_cur%ROWTYPE;
        l_ret     VARCHAR2(4000);
    BEGIN
    
        OPEN c_cur(i_id_rehab_presc);
        FETCH c_cur
            INTO l_cur_row;
    
        IF c_cur%FOUND
        THEN
            IF l_cur_row.sessions IS NOT NULL
               AND l_cur_row.notes IS NOT NULL
            THEN
                l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_T002') || ' ' ||
                         l_cur_row.sessions || chr(10) ||
                         pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_T093') || ' ' ||
                         l_cur_row.notes;
            ELSIF l_cur_row.sessions IS NOT NULL
                  AND l_cur_row.notes IS NULL
            THEN
                l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_T002') || ' ' ||
                         l_cur_row.sessions;
            ELSIF l_cur_row.sessions IS NULL
                  AND l_cur_row.notes IS NOT NULL
            THEN
                l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'REHAB_T093') || ' ' ||
                         l_cur_row.notes;
            END IF;
        END IF;
        CLOSE c_cur;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rehab_notes;

    FUNCTION get_exam_notes
    (
        i_lang          IN language.id_language%TYPE,
        id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR IS
    
        CURSOR c_cur(x_exam_req_det exam_req_det.id_exam_req_det%TYPE) IS
            SELECT er.notes_patient, erd.notes, erd.notes_tech
              FROM exam_req er
              JOIN exam_req_det erd
                ON (er.id_exam_req = erd.id_exam_req)
             WHERE erd.id_exam_req_det = x_exam_req_det;
    
        l_cur_row c_cur%ROWTYPE;
        l_ret     VARCHAR2(4000);
    BEGIN
    
        OPEN c_cur(id_exam_req_det);
        FETCH c_cur
            INTO l_cur_row;
    
        l_ret := NULL;
        IF c_cur%FOUND
        THEN
            IF l_cur_row.notes_patient IS NOT NULL
            THEN
                l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EXAMS_T020') || ' ' ||
                         l_cur_row.notes_patient;
            
                IF l_cur_row.notes IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) || pk_message.get_message(i_lang => i_lang, i_code_mess => 'EXAMS_T019') || ' ' ||
                             l_cur_row.notes;
                END IF;
            
                IF l_cur_row.notes_tech IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) || pk_message.get_message(i_lang => i_lang, i_code_mess => 'EXAMS_T059') || ' ' ||
                             l_cur_row.notes_tech;
                END IF;
            
            ELSE
                IF l_cur_row.notes IS NOT NULL
                THEN
                
                    l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EXAMS_T019') || ' ' ||
                             l_cur_row.notes;
                END IF;
            
                IF l_cur_row.notes_tech IS NOT NULL
                THEN
                    IF l_ret IS NOT NULL
                    THEN
                        l_ret := l_ret || chr(10);
                    END IF;
                
                    l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'EXAMS_T059') || ' ' ||
                             l_cur_row.notes_tech;
                
                END IF;
            END IF;
        END IF;
    
        CLOSE c_cur;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_notes;

    FUNCTION get_analysis_notes
    (
        i_lang              IN language.id_language%TYPE,
        id_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR IS
    
        CURSOR c_cur(x_analysis_req_det analysis_req_det.id_analysis_req_det%TYPE) IS
            SELECT to_char(ard.notes_patient) notes_patient, ard.notes, ard.notes_tech
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = x_analysis_req_det;
    
        l_cur_row c_cur%ROWTYPE;
        l_ret     VARCHAR2(4000);
    BEGIN
    
        OPEN c_cur(id_analysis_req_det);
        FETCH c_cur
            INTO l_cur_row;
    
        l_ret := NULL;
        IF c_cur%FOUND
        THEN
            IF l_cur_row.notes_patient IS NOT NULL
            THEN
                l_ret := pk_message.get_message(i_lang, 'LAB_TESTS_T026') || ' ' || l_cur_row.notes_patient;
            
                IF l_cur_row.notes IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) ||
                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'LAB_TESTS_T032') || ' ' ||
                             l_cur_row.notes;
                END IF;
            
                IF l_cur_row.notes_tech IS NOT NULL
                THEN
                    l_ret := l_ret || chr(10) ||
                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'LAB_TESTS_T033') || ' ' ||
                             l_cur_row.notes_tech;
                END IF;
            
            ELSE
                IF l_cur_row.notes IS NOT NULL
                THEN
                
                    l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'LAB_TESTS_T032') || ' ' ||
                             l_cur_row.notes;
                END IF;
            
                IF l_cur_row.notes_tech IS NOT NULL
                THEN
                
                    IF l_ret IS NOT NULL
                    THEN
                        l_ret := l_ret || chr(10);
                    END IF;
                
                    l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'LAB_TESTS_T033') || ' ' ||
                             l_cur_row.notes_tech;
                
                END IF;
            END IF;
        END IF;
    
        CLOSE c_cur;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_analysis_notes;

    FUNCTION get_p1_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
    
        CURSOR c_cur(x_id_external_request p1_external_request.id_external_request%TYPE) IS
            SELECT pd.text
              FROM p1_detail pd
             WHERE pd.id_external_request = x_id_external_request
               AND pd.flg_type = 17
               AND pd.flg_status = pk_alert_constant.g_active;
    
        l_cur_row c_cur%ROWTYPE;
        l_ret     VARCHAR2(4000);
    BEGIN
    
        OPEN c_cur(id_external_request);
        FETCH c_cur
            INTO l_cur_row;
    
        l_ret := NULL;
        IF c_cur%FOUND
        THEN
            IF l_cur_row.text IS NOT NULL
            THEN
                l_ret := l_cur_row.text;
            END IF;
        END IF;
    
        CLOSE c_cur;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_p1_notes;

    /**
    * Returns the list of referral MCDTs grouped as required the specified report
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_exr               Referral identifier
    * @param   i_type              Splitting type
    * @param   i_id_report         Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion Referral completion option id. Needed to get the maximum number of MCDTs in each referral report
    *
    * @value   i_type              {*} 'PV' print preview (do not generate codes)
    *                              {*} 'PF' print final(generate codes)
    *                              {*} 'A' application
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   02-06-2008
    */
    FUNCTION get_exr_group_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_gen_ref           IN VARCHAR2 DEFAULT 'N',
        i_flg_isencao       IN VARCHAR2
    ) RETURN t_coll_ref_group
        PIPELINED IS
        l_ref_barcode_null sys_config.value%TYPE;
        l_bdnp_available   sys_config.value%TYPE;
        l_ref_type         p1_external_request.flg_type%TYPE;
    
        -- joining mcdt req detail
        CURSOR c_group_req(x_bdnp sys_config.value%TYPE) IS
            SELECT 0 id_group,
                   id_exr_temp,
                   exr_code,
                   id,
                   id_req,
                   decode(standard_desc, NULL, name, standard_desc) name,
                   decode(translate(upper(name), 'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇç', 'AAAAAAAAEEEEIIOOOOOOUUUUCC'),
                          translate(upper(standard_desc), 'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇç', 'AAAAAAAAEEEEIIOOOOOOUUUUCC'),
                          NULL,
                          standard_desc) standard_desc,
                   decode(l_ref_barcode_null, pk_ref_constant.g_yes, NULL, barcode) barcode,
                   mcdt_notes,
                   nvl2(clinical_indication,
                        decode(type_mcdt,
                               pk_ref_constant.g_p1_type_a,
                               pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'LAB_TESTS_T012') || ' ' ||
                               clinical_indication,
                               pk_ref_constant.g_p1_type_p,
                               pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'PROCEDURES_T081') || ' ' || clinical_indication,
                               pk_ref_constant.g_p1_type_i,
                               pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'EXAMS_T047') || ' ' ||
                               clinical_indication,
                               clinical_indication),
                        NULL) clinical_indication,
                   id_institution,
                   flg_priority,
                   pk_ref_core.get_ref_priority_desc(i_lang, i_prof, flg_priority) priority_desc, -- ALERT-273753
                   flg_home,
                   pk_translation.get_translation(i_lang, code_sample_type) sample_type_desc,
                   id_sample_type,
                   id_content_sample_type,
                   mcdt_cat,
                   mcdt_nature,
                   pk_ref_core.get_mcdt_nature_desc(i_lang, i_prof, mcdt_nature) mcdt_nature_desc,
                   isencao,
                   amount,
                   decode(flg_laterality,
                          'N',
                          NULL,
                          decode(type_mcdt,
                                 pk_ref_constant.g_p1_type_i,
                                 pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_LATERALITY', flg_laterality, i_lang),
                                 pk_ref_constant.g_p1_type_p,
                                 pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', flg_laterality, i_lang),
                                 NULL)) laterality_desc,
                   flg_laterality,
                   flg_ald,
                   type_mcdt flg_type,
                   pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_TYPE', type_mcdt, i_lang) desc_type,
                   consent,
                   complementary_information,
                   reason,
                   (SELECT pk_p1_med_cs.get_p1_notes(i_lang, i_prof, i_exr)
                      FROM dual) p1_notes
              FROM (WITH cod AS (SELECT ac.id_analysis,
                                        ac.id_sample_type,
                                        ac.flg_concatenate_info,
                                        row_number() over(PARTITION BY ac.id_analysis, ac.id_sample_type ORDER BY ac.id_analysis_codification ASC) AS rn
                                   FROM p1_exr_temp pt
                                   JOIN analysis_req_det ard
                                     ON (pt.id_analysis_req_det = ard.id_analysis_req_det)
                                   JOIN analysis_codification ac
                                     ON ac.id_analysis = ard.id_analysis
                                    AND ac.id_sample_type = ard.id_sample_type
                                    AND ac.flg_available = pk_alert_constant.g_yes
                                  WHERE pt.id_external_request = i_exr)
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              a.id_analysis id,
                              pt.id_analysis_req_det id_req,
                              pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                        i_prof                      => i_prof,
                                                                        i_flg_type                  => 'A',
                                                                        i_analysis_code_translation => pk_ref_constant.g_analysis_code ||
                                                                                                       pt.id_analysis,
                                                                        i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                       pt.id_sample_type,
                                                                        i_dep_clin_serv             => NULL) name,
                              ac.standard_desc standard_desc,
                              get_analysis_notes(i_lang, pt.id_analysis_req_det) mcdt_notes,
                              pk_diagnosis.concat_diag(i_lang, NULL, pt.id_analysis_req_det, NULL, i_prof) clinical_indication,
                              ac.standard_code barcode,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              pk_ref_constant.g_sample_type_code || ard.id_sample_type code_sample_type,
                              ard.id_sample_type,
                              st.id_content id_content_sample_type,
                              NULL mcdt_cat,
                              NULL flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_analysis, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_a type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              per.consent,
                              decode(c.flg_concatenate_info,
                                     pk_alert_constant.g_yes,
                                     pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                              i_prof,
                                                                              'A',
                                                                              'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                                              NULL) || ', ' ||
                                     pt.complementary_information,
                                     pt.complementary_information) complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN analysis_req_det ard
                           ON (pt.id_analysis_req_det = ard.id_analysis_req_det)
                         JOIN analysis a
                           ON (ard.id_analysis = a.id_analysis)
                         LEFT JOIN analysis_codification ac
                           ON (ard.id_analysis = ac.id_analysis AND ard.id_sample_type = ac.id_sample_type AND
                              ac.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ac.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                         LEFT JOIN sample_type st
                           ON st.id_sample_type = ard.id_sample_type
                         LEFT JOIN cod c
                           ON c.id_analysis = ard.id_analysis
                          AND c.id_sample_type = ard.id_sample_type
                          AND c.rn = 1
                        WHERE (pt.id_external_request = i_exr OR per.id_p1_ext_req_parent = i_exr)
                       UNION ALL
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              e.id_exam id,
                              pt.id_exam_req_det id_req,
                              pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) name,
                              ec.standard_desc standard_desc,
                              pk_p1_med_cs.get_exam_notes(i_lang, pt.id_exam_req_det) mcdt_notes,
                              pk_diagnosis.concat_diag(i_lang, pt.id_exam_req_det, NULL, NULL, i_prof) clinical_indication,
                              ec.standard_code barcode,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              e.id_exam_cat mcdt_cat,
                              erd.flg_laterality flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_exam, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_i type_mcdt,
                              to_number(decode(ec.flg_show_quantity, 'N', NULL, pt.amount)) amount,
                              pt.flg_ald,
                              per.consent,
                              pt.complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN exam_req_det erd
                           ON (pt.id_exam_req_det = erd.id_exam_req_det)
                         JOIN exam_req er
                           ON (er.id_exam_req = erd.id_exam_req)
                         JOIN exam e
                           ON (erd.id_exam = e.id_exam)
                         LEFT JOIN exam_codification ec
                           ON (e.id_exam = ec.id_exam AND
                              ec.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ec.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                        WHERE (pt.id_external_request = i_exr OR per.id_p1_ext_req_parent = i_exr)
                       UNION ALL
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              i.id_intervention id,
                              pt.id_interv_presc_det id_req,
                              pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) name,
                              ic.standard_desc standard_desc,
                              pk_p1_med_cs.get_interv_notes(i_lang, i_prof, ipd.id_interv_presc_det) mcdt_notes,
                              pk_diagnosis.concat_diag(i_lang, NULL, NULL, pt.id_interv_presc_det, i_prof) clinical_indication,
                              nvl(ic.standard_code, i.barcode) barcode,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              NULL mcdt_cat,
                              ipd.flg_laterality flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_intervention, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_p type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              per.consent,
                              pt.complementary_information,
                              pt.reason
                         FROM p1_external_request per
                         JOIN p1_exr_temp pt
                           ON (per.id_external_request = pt.id_external_request)
                         JOIN interv_presc_det ipd
                           ON (pt.id_interv_presc_det = ipd.id_interv_presc_det)
                         JOIN intervention i
                           ON (ipd.id_intervention = i.id_intervention)
                         LEFT JOIN interv_codification ic
                           ON (i.id_intervention = ic.id_intervention AND
                              ic.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ic.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                        WHERE (pt.id_external_request = i_exr OR per.id_p1_ext_req_parent = i_exr)
                       UNION ALL
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              i.id_intervention id,
                              pt.id_rehab_presc id_req,
                              pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) ||
                              ' - ' || pk_translation.get_translation(i_lang, ra.code_rehab_area) name,
                              ic.standard_desc standard_desc,
                              pk_p1_med_cs.get_rehab_notes(i_lang, pt.id_rehab_presc) mcdt_notes,
                              NULL clinical_indication,
                              nvl(ic.standard_code, i.barcode) barcode,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              NULL mcdt_cat,
                              rp.flg_laterality flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_intervention, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_f type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              per.consent,
                              pt.complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN rehab_presc rp
                           ON (rp.id_rehab_presc = pt.id_rehab_presc)
                         JOIN rehab_sch_need rsn
                           ON (rp.id_rehab_sch_need = rsn.id_rehab_sch_need)
                         JOIN intervention i
                           ON (pt.id_intervention = i.id_intervention)
                         JOIN rehab_area_interv rai
                           ON (rai.id_rehab_area_interv = rp.id_rehab_area_interv)
                         JOIN rehab_area ra
                           ON (ra.id_rehab_area = rai.id_rehab_area)
                         LEFT JOIN interv_codification ic
                           ON (i.id_intervention = ic.id_intervention AND
                              ic.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ic.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                        WHERE (pt.id_external_request = i_exr OR per.id_p1_ext_req_parent = i_exr)
                       UNION ALL
                       SELECT per.id_external_request,
                              NULL exr_code,
                              p.id_speciality id,
                              NULL id_req,
                              pk_translation.get_translation(i_lang, p.code_speciality) name,
                              rsm.standard_desc,
                              NULL mcdt_notes,
                              NULL clinical_indication,
                              rsm.standard_code barcode,
                              per.id_inst_dest id_institution,
                              per.flg_priority,
                              per.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              NULL mcdt_cat,
                              NULL flg_laterality,
                              nvl(pk_ref_core.get_mcdt_nature(per.id_speciality, l_ref_type), 'N') mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_c type_mcdt,
                              1 amount,
                              NULL flg_ald,
                              per.consent,
                              NULL complementary_information,
                              NULL reason
                         FROM p1_external_request per
                         JOIN p1_speciality p
                           ON (per.id_speciality = p.id_speciality)
                         JOIN ref_spec_market rsm
                           ON (rsm.id_speciality = p.id_speciality)
                        WHERE per.id_external_request = i_exr
                          AND per.flg_type = pk_ref_constant.g_p1_type_c
                          AND rsm.flg_available = pk_ref_constant.g_yes
                          AND rsm.id_market = pk_utils.get_institution_market(i_lang, per.id_inst_orig))
                        ORDER BY id_institution, flg_priority, flg_home, mcdt_nature, isencao, barcode, id;
    
    
        -- without mcdt req detail
        CURSOR c_group(x_bdnp sys_config.value%TYPE) IS
            SELECT 0 id_group,
                   id_exr_temp,
                   exr_code,
                   id,
                   id_req,
                   decode(standard_desc, NULL, name, standard_desc) name,
                   decode(translate(upper(name), 'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇç', 'AAAAAAAAEEEEIIOOOOOOUUUUCC'),
                          translate(upper(standard_desc), 'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇç', 'AAAAAAAAEEEEIIOOOOOOUUUUCC'),
                          NULL,
                          standard_desc) standard_desc,
                   decode(l_ref_barcode_null, pk_ref_constant.g_yes, NULL, barcode) barcode,
                   mcdt_notes,
                   nvl2(clinical_indication,
                        decode(type_mcdt,
                               pk_ref_constant.g_p1_type_a,
                               pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'LAB_TESTS_T012') || ' ' ||
                               clinical_indication,
                               pk_ref_constant.g_p1_type_p,
                               pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'PROCEDURES_T081') || ' ' || clinical_indication,
                               pk_ref_constant.g_p1_type_i,
                               pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'EXAMS_T047') || ' ' ||
                               clinical_indication,
                               clinical_indication),
                        NULL) clinical_indication,
                   id_institution,
                   flg_priority,
                   pk_ref_core.get_ref_priority_desc(i_lang, i_prof, flg_priority) priority_desc, -- ALERT-273753
                   flg_home,
                   pk_translation.get_translation(i_lang, code_sample_type) sample_type_desc,
                   id_sample_type,
                   id_content_sample_type,
                   mcdt_cat,
                   mcdt_nature,
                   pk_ref_core.get_mcdt_nature_desc(i_lang, i_prof, mcdt_nature) mcdt_nature_desc,
                   isencao,
                   amount,
                   decode(flg_laterality,
                          'N',
                          NULL,
                          decode(type_mcdt,
                                 pk_ref_constant.g_p1_type_i,
                                 pk_sysdomain.get_domain('EXAM.FLG_LATERALITY', flg_laterality, i_lang),
                                 pk_ref_constant.g_p1_type_p,
                                 pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_LATERALITY', flg_laterality, i_lang),
                                 NULL)) laterality_desc,
                   flg_laterality,
                   flg_ald,
                   type_mcdt flg_type,
                   pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_TYPE', type_mcdt, i_lang) desc_type,
                   consent,
                   complementary_information,
                   reason,
                   (SELECT pk_p1_med_cs.get_p1_notes(i_lang, i_prof, i_exr)
                      FROM dual) p1_notes
              FROM (WITH cod AS (SELECT ac.id_analysis,
                                        ac.id_sample_type,
                                        ac.flg_concatenate_info,
                                        row_number() over(PARTITION BY ac.id_analysis, ac.id_sample_type ORDER BY ac.id_analysis_codification ASC) AS rn
                                   FROM p1_exr_temp pt
                                   JOIN analysis_req_det ard
                                     ON (pt.id_analysis_req_det = ard.id_analysis_req_det)
                                   JOIN analysis_codification ac
                                     ON ac.id_analysis = ard.id_analysis
                                    AND ac.id_sample_type = ard.id_sample_type
                                    AND ac.flg_available = pk_alert_constant.g_yes
                                  WHERE pt.id_external_request = i_exr)
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              a.id_analysis id,
                              pt.id_analysis_req_det id_req,
                              pk_lab_tests_api_db.get_alias_translation(i_lang                      => i_lang,
                                                                        i_prof                      => i_prof,
                                                                        i_flg_type                  => 'A',
                                                                        i_analysis_code_translation => pk_ref_constant.g_analysis_code ||
                                                                                                       pt.id_analysis,
                                                                        i_sample_code_translation   => pk_ref_constant.g_sample_type_code ||
                                                                                                       pt.id_sample_type,
                                                                        i_dep_clin_serv             => NULL) name,
                              ac.standard_desc standard_desc,
                              ac.standard_code barcode,
                              pk_p1_med_cs.get_analysis_notes(i_lang, pt.id_analysis_req_det) mcdt_notes,
                              pk_diagnosis.concat_diag(i_lang, NULL, pt.id_analysis_req_det, NULL, i_prof) clinical_indication,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              pk_ref_constant.g_sample_type_code || ard.id_sample_type code_sample_type,
                              ard.id_sample_type,
                              st.id_content id_content_sample_type,
                              NULL mcdt_cat,
                              NULL flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_analysis, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_a type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              NULL consent,
                              decode(c.flg_concatenate_info,
                                     pk_alert_constant.g_yes,
                                     pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                              i_prof,
                                                                              'A',
                                                                              'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                                              NULL) || ', ' ||
                                     pt.complementary_information,
                                     pt.complementary_information) complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN analysis a
                           ON (pt.id_analysis = a.id_analysis)
                         JOIN analysis_req_det ard
                           ON (ard.id_analysis_req_det = pt.id_analysis_req_det)
                         LEFT JOIN analysis_codification ac
                           ON (ard.id_analysis = ac.id_analysis AND ard.id_sample_type = ac.id_sample_type AND
                              ac.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ac.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN sample_type st
                           ON st.id_sample_type = ard.id_sample_type
                         LEFT JOIN cod c
                           ON c.id_analysis = ard.id_analysis
                          AND c.id_sample_type = ard.id_sample_type
                          AND c.rn = 1
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                        WHERE pt.id_external_request = i_exr
                          AND pt.id_analysis_req_det IS NOT NULL
                       UNION ALL
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              e.id_exam id,
                              pt.id_exam_req_det id_req,
                              pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) name,
                              ec.standard_desc,
                              ec.standard_code barcode,
                              pk_p1_med_cs.get_exam_notes(i_lang, pt.id_exam_req_det) mcdt_notes,
                              pk_diagnosis.concat_diag(i_lang, pt.id_exam_req_det, NULL, NULL, i_prof) clinical_indication,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              e.id_exam_cat mcdt_cat,
                              erd.flg_laterality flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_exam, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_i type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              NULL consent,
                              pt.complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN exam e
                           ON (pt.id_exam = e.id_exam)
                         JOIN exam_req_det erd
                           ON (erd.id_exam_req_det = pt.id_exam_req_det)
                         JOIN exam_req er
                           ON (er.id_exam_req = erd.id_exam_req)
                         LEFT JOIN exam_codification ec
                           ON (e.id_exam = ec.id_exam AND
                              ec.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND
                              
                              x_bdnp = pk_ref_constant.g_yes AND ec.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                        WHERE pt.id_external_request = i_exr
                          AND pt.id_exam_req_det IS NOT NULL
                       UNION ALL
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              i.id_intervention id,
                              pt.id_interv_presc_det id_req,
                              pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) name,
                              ic.standard_desc,
                              nvl(ic.standard_code, i.barcode) barcode,
                              pk_p1_med_cs.get_interv_notes(i_lang, i_prof, ipd.id_interv_presc_det) mcdt_notes,
                              pk_diagnosis.concat_diag(i_lang, NULL, NULL, pt.id_interv_presc_det, i_prof) clinical_indication,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              NULL mcdt_cat,
                              ipd.flg_laterality flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_intervention, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_i type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              NULL consent,
                              pt.complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN p1_external_request per
                           ON (per.id_external_request = pt.id_external_request)
                         JOIN intervention i
                           ON (pt.id_intervention = i.id_intervention)
                         JOIN interv_presc_det ipd
                           ON (ipd.id_interv_presc_det = pt.id_interv_presc_det)
                         LEFT JOIN interv_codification ic
                           ON (i.id_intervention = ic.id_intervention AND
                              ic.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ic.flg_available = pk_ref_constant.g_yes)
                        WHERE pt.id_external_request = i_exr
                          AND pt.id_interv_presc_det IS NOT NULL
                       UNION ALL
                       SELECT pt.id_exr_temp,
                              NULL exr_code,
                              i.id_intervention id,
                              pt.id_rehab_presc id_req,
                              pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) name,
                              ic.standard_desc,
                              nvl(ic.standard_code, i.barcode) barcode,
                              pk_p1_med_cs.get_rehab_notes(i_lang, pt.id_rehab_presc) mcdt_notes,
                              NULL clinical_indication,
                              pt.id_institution,
                              pt.flg_priority,
                              pt.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              NULL mcdt_cat,
                              rp.flg_laterality flg_laterality,
                              pk_ref_core.get_mcdt_nature(pt.id_intervention, l_ref_type) mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_i type_mcdt,
                              pt.amount,
                              pt.flg_ald,
                              NULL consent,
                              pt.complementary_information,
                              pt.reason
                         FROM p1_exr_temp pt
                         JOIN intervention i
                           ON (pt.id_intervention = i.id_intervention)
                         JOIN rehab_presc rp
                           ON (rp.id_rehab_presc = pt.id_rehab_presc)
                         JOIN rehab_sch_need rsn
                           ON (rp.id_rehab_sch_need = rsn.id_rehab_sch_need)
                         LEFT JOIN interv_codification ic
                           ON (i.id_intervention = ic.id_intervention AND
                              ic.id_codification IN
                              (SELECT id_codification
                                  FROM codification
                                 WHERE id_content = pk_ref_constant.g_conv_codification
                                   AND flg_available = pk_ref_constant.g_yes) AND x_bdnp = pk_ref_constant.g_yes AND
                              ic.flg_available = pk_ref_constant.g_yes)
                         LEFT JOIN p1_external_request per
                           ON per.id_external_request = pt.id_external_request
                        WHERE pt.id_external_request = i_exr
                          AND pt.id_rehab_presc IS NOT NULL
                       UNION ALL
                       SELECT per.id_external_request,
                              NULL exr_code,
                              p.id_speciality id,
                              NULL id_req,
                              pk_translation.get_translation(i_lang, p.code_speciality) name,
                              rsm.standard_desc,
                              rsm.standard_code barcode,
                              NULL mcdt_notes,
                              NULL clinical_indication,
                              per.id_inst_dest id_institution,
                              per.flg_priority,
                              per.flg_home,
                              NULL code_sample_type,
                              NULL id_sample_type,
                              NULL id_content_sample_type,
                              NULL mcdt_cat,
                              NULL flg_laterality,
                              nvl(pk_ref_core.get_mcdt_nature(per.id_speciality, l_ref_type), 'N') mcdt_nature,
                              decode(i_flg_isencao,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_no,
                                     pk_ref_constant.g_yes,
                                     decode(per.id_pat_exemption, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                     pk_ref_constant.g_no) isencao,
                              pk_ref_constant.g_p1_type_c type_mcdt,
                              1 amount,
                              NULL flg_ald,
                              per.consent,
                              NULL complementary_information,
                              NULL reason
                         FROM p1_external_request per
                         JOIN p1_speciality p
                           ON (per.id_speciality = p.id_speciality)
                         JOIN ref_spec_market rsm
                           ON (rsm.id_speciality = p.id_speciality)
                        WHERE per.id_external_request = i_exr
                          AND per.flg_type = pk_ref_constant.g_p1_type_c
                          AND rsm.flg_available = pk_ref_constant.g_yes
                          AND rsm.id_market = pk_utils.get_institution_market(i_lang, per.id_inst_orig))
                        ORDER BY id_institution, flg_priority, flg_home, mcdt_nature, isencao, barcode, id;
    
    
        l_group_row     t_rec_ref_group;
        l_group_old_row t_rec_ref_group;
    
        l_id_group NUMBER DEFAULT 0;
    
        i                 NUMBER DEFAULT 0;
        l_number_per_form NUMBER DEFAULT 0;
        l_exr_code        VARCHAR(30 CHAR);
        l_error           t_error_out;
    
        l_profile_template profile_template.id_profile_template%TYPE;
        l_id_market        market.id_market%TYPE;
    
        CURSOR c_ref_completion_cfg IS
            SELECT t.number_per_form number_per_form
              FROM (SELECT rc.*
                      FROM ref_completion r
                      JOIN ref_completion_cfg rc
                        ON (r.id_ref_completion = rc.id_ref_completion)
                     WHERE id_software IN (0, i_prof.software)
                       AND id_institution IN (0, i_prof.institution)
                       AND id_profile_template IN (0, l_profile_template)
                       AND rc.id_ref_completion = i_id_ref_completion
                       AND rc.id_reports = i_id_report
                       AND rc.id_market = l_id_market
                     ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC) t
              JOIN p1_external_request p
                ON (p.id_external_request = i_exr AND p.flg_type = t.flg_type_ref)
             WHERE rownum = 1;
    
    BEGIN
        g_error := 'Init get_exr_group_internal ID_EXT_REQ=' || i_exr || ' TYPE=' || i_type;
        pk_alertlog.log_debug(g_error);
    
        -- sending null barcode, depending on SYS_CONFIG param
        l_ref_barcode_null := nvl(pk_sysconfig.get_config('REF_BARCODE_NULL', i_prof), pk_ref_constant.g_no);
        l_bdnp_available   := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                  pk_ref_constant.g_no);
    
        l_group_old_row := NULL;
    
        SELECT per.flg_type
          INTO l_ref_type
          FROM p1_external_request per
         WHERE per.id_external_request = i_exr;
    
        IF i_type IN (pk_ref_constant.g_rep_mode_pv, pk_ref_constant.g_rep_mode_pf)
        THEN
            -- Print
            -- getting number of MCDTs per form        
            g_error            := 'Call pk_tools.get_prof_profile_template / ID_PROF=' || i_prof.id || ' INSTITUTION=' ||
                                  i_prof.institution || ' SOFTWARE=' || i_prof.software;
            l_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
            l_id_market        := pk_utils.get_institution_market(i_lang, i_prof.institution);
        
            /* Na certificação perceber se faz sentido esta configuração */
        
            g_error := 'OPEN c_ref_completion_cfg / ID_EXT_REQ=' || i_exr || ' ID_REPORTS=' || i_id_report ||
                       ' ID_REF_COMPLETION=' || i_id_ref_completion || ' ID_SOFTWARE=' || i_prof.software ||
                       ' ID_INSTITUTION=' || i_prof.institution || ' ID_PROFILE_TEMPLATE=' || l_profile_template;
        
            OPEN c_ref_completion_cfg;
            FETCH c_ref_completion_cfg
                INTO l_number_per_form;
            g_found := c_ref_completion_cfg%FOUND;
            CLOSE c_ref_completion_cfg;
        
            IF NOT g_found
            THEN
                g_error := 'c_ref_completion_cfg NOT FOUND - ' || i_id_ref_completion;
                RAISE g_exception;
            END IF;
        
            IF l_number_per_form = 0
            THEN
                l_number_per_form := NULL;
            END IF;
        
            -- Gets code for the first one
            IF i_type = pk_ref_constant.g_rep_mode_pf
               AND i_gen_ref = pk_ref_constant.g_yes
            THEN
                g_error := 'Call pk_ref_orig_phy.get_referral_number';
                IF NOT pk_ref_orig_phy.get_referral_number(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_ext_req           => i_exr,
                                                           i_id_ref_completion => i_id_ref_completion,
                                                           o_number            => l_exr_code,
                                                           o_error             => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            g_error := 'OPEN c_group_req l_bdnp_available= ' || l_bdnp_available;
            OPEN c_group_req(l_bdnp_available);
            LOOP
            
                g_error := 'initializing l_group_row / l_ref_barcode_null=' || l_ref_barcode_null;
                pk_alertlog.log_debug(g_error);
                l_group_row := t_rec_ref_group();
            
                FETCH c_group_req
                    INTO l_group_row.id_group,
                         l_group_row.id_exr_temp,
                         l_group_row.exr_code,
                         l_group_row.id,
                         l_group_row.id_req,
                         l_group_row.name,
                         l_group_row.standard_desc,
                         l_group_row.barcode,
                         l_group_row.mcdt_notes,
                         l_group_row.clinical_indication,
                         l_group_row.id_institution,
                         l_group_row.flg_priority,
                         l_group_row.priority_desc, -- ALERT-273753
                         l_group_row.flg_home,
                         l_group_row.sample_type_desc,
                         l_group_row.id_sample_type,
                         l_group_row.id_content_sample_type,
                         l_group_row.mcdt_cat,
                         l_group_row.mcdt_nature,
                         l_group_row.mcdt_nature_desc,
                         l_group_row.isencao,
                         l_group_row.amount,
                         l_group_row.laterality_desc,
                         l_group_row.flg_laterality,
                         l_group_row.flg_ald,
                         l_group_row.flg_type,
                         l_group_row.desc_type,
                         l_group_row.consent,
                         l_group_row.complementary_information,
                         l_group_row.reason,
                         l_group_row.p1_notes;
                EXIT WHEN c_group_req%NOTFOUND;
            
                g_error := 'ID_GROUP=' || l_group_row.id_group || ' ID_EXR_TEMP=' || l_group_row.id_exr_temp ||
                           ' EXR_CODE=' || l_group_row.exr_code || ' ID=' || l_group_row.id || ' ID_REQ=' ||
                           l_group_row.id_req || ' NAME=' || l_group_row.name || ' BARCODE=' || l_group_row.barcode ||
                           ' ID_INSTITUTION=' || l_group_row.id_institution || ' FLG_PRIORITY=' ||
                           l_group_row.flg_priority || ' FLG_HOME=' || l_group_row.flg_home || ' DESC_SAMP_TYPE=' ||
                           l_group_row.sample_type_desc || ' MCDT_CAT=' || l_group_row.mcdt_cat;
                IF i = 0
                THEN
                    l_group_old_row := l_group_row;
                END IF;
            
                IF nvl(l_group_old_row.id_institution, 0) != nvl(l_group_row.id_institution, 0)
                   OR nvl(l_group_old_row.flg_priority, 0) != nvl(l_group_row.flg_priority, 0)
                   OR nvl(l_group_old_row.flg_home, 0) != nvl(l_group_row.flg_home, 0)
                  -- OR nvl(l_group_old_row.mcdt_cat, 0) != nvl(l_group_row.mcdt_cat, 0)
                  --OR nvl(l_group_old_row.complementary_information, 0) != nvl(l_group_row.complementary_information, 0)
                   OR nvl(l_group_old_row.reason, 0) != nvl(l_group_row.reason, 0)
                   OR nvl(l_group_old_row.mcdt_nature, 0) != nvl(l_group_row.mcdt_nature, 0)
                   OR (l_number_per_form IS NOT NULL AND i >= l_number_per_form AND i_id_report <> 909) -- if null than unlimited MCDTs
                THEN
                    IF i_id_ref_completion = 2
                    THEN
                        l_id_group := 0;
                    ELSE
                        l_id_group := l_id_group + 1;
                    END IF;
                
                    IF l_number_per_form IS NOT NULL
                       AND i_id_report <> 909
                       AND i_id_ref_completion <> 2
                    THEN
                        i := 0;
                    ELSIF l_number_per_form IS NOT NULL
                          AND i >= l_number_per_form
                          AND i_id_report <> 909
                          AND i_id_ref_completion = 2
                    THEN
                        i := 0;
                    END IF;
                
                    -- Gets new code
                    IF i_type = pk_ref_constant.g_rep_mode_pf
                       AND i_gen_ref = pk_ref_constant.g_yes
                    THEN
                        g_error := 'Call pk_ref_orig_phy.get_referral_number';
                        IF NOT pk_ref_orig_phy.get_referral_number(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_ext_req           => i_exr,
                                                                   i_id_ref_completion => i_id_ref_completion,
                                                                   o_number            => l_exr_code,
                                                                   o_error             => l_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                
                END IF;
            
                i                    := i + 1;
                l_group_old_row      := l_group_row;
                l_group_row.id_group := l_id_group;
                l_group_row.exr_code := to_number(i_exr || l_id_group);
            
                PIPE ROW(l_group_row);
            
            END LOOP;
        
            g_error := 'CLOSE c_group_req';
            CLOSE c_group_req;
        
        ELSIF i_type = pk_ref_constant.g_rep_mode_a
        THEN
        
            g_error := 'OPEN c_group l_bdnp_available= ' || l_bdnp_available;
            OPEN c_group(l_bdnp_available);
            LOOP
                g_error := 'initializing l_group_row / l_ref_barcode_null=' || l_ref_barcode_null;
                pk_alertlog.log_debug(g_error);
            
                l_group_row := t_rec_ref_group();
                FETCH c_group
                    INTO l_group_row.id_group,
                         l_group_row.id_exr_temp,
                         l_group_row.exr_code,
                         l_group_row.id,
                         l_group_row.id_req,
                         l_group_row.name,
                         l_group_row.standard_desc,
                         l_group_row.barcode,
                         l_group_row.mcdt_notes,
                         l_group_row.clinical_indication,
                         l_group_row.id_institution,
                         l_group_row.flg_priority,
                         l_group_row.priority_desc, -- ALERT-273753
                         l_group_row.flg_home,
                         l_group_row.sample_type_desc,
                         l_group_row.id_sample_type,
                         l_group_row.id_content_sample_type,
                         l_group_row.mcdt_cat,
                         l_group_row.mcdt_nature,
                         l_group_row.mcdt_nature_desc,
                         l_group_row.isencao,
                         l_group_row.amount,
                         l_group_row.laterality_desc,
                         l_group_row.flg_laterality,
                         l_group_row.flg_ald,
                         l_group_row.flg_type,
                         l_group_row.desc_type,
                         l_group_row.consent,
                         l_group_row.complementary_information,
                         l_group_row.reason,
                         l_group_row.p1_notes;
                EXIT WHEN c_group%NOTFOUND;
            
                IF i = 0
                THEN
                    l_group_old_row := l_group_row;
                END IF;
            
                IF nvl(l_group_old_row.id_institution, 0) != nvl(l_group_row.id_institution, 0)
                   OR nvl(l_group_old_row.flg_priority, 0) != nvl(l_group_row.flg_priority, 0)
                   OR nvl(l_group_old_row.flg_home, 0) != nvl(l_group_row.flg_home, 0)
                THEN
                    l_id_group := l_id_group + 1;
                END IF;
            
                i                    := i + 1;
                l_group_old_row      := l_group_row;
                l_group_row.id_group := l_id_group;
                l_group_row.exr_code := to_number(i_exr || l_id_group);
            
                PIPE ROW(l_group_row);
            END LOOP;
        
            g_error := 'CLOSE c_group';
            CLOSE c_group;
        
        END IF;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF c_group%ISOPEN
            THEN
                CLOSE c_group;
            END IF;
            IF c_group_req%ISOPEN
            THEN
                CLOSE c_group_req;
            END IF;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXR_GROUP_INTERNAL',
                                              o_error    => l_error);
            RETURN;
    END get_exr_group_internal;

    /**
    * Returns the list of referral MCDTs grouped as required the specified report
    * 
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_exr               Referral identifier
    * @param   i_type              Splitting type
    * @param   i_id_report         Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion Referral completion option id. Needed to get the maximum number of MCDTs in each referral report
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_type              {*} 'PV' print preview (do not generate codes)
    *                              {*} 'PF' print final(generate codes)
    *                              {*} 'A' application    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008   
    */
    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_var VARCHAR2(4000);
    BEGIN
        g_error := 'Init get_exr_group / ID_REF=' || i_exr || ' FLG_TYPE=' || i_type || ' ID_REPORT=' || i_id_report ||
                   ' ID_REF_COMPLETION=' || i_id_ref_completion || ' FLG_ISENCAO=' || i_flg_isencao;
    
        IF i_type = pk_ref_constant.g_rep_mode_pf
        THEN
            l_var := pk_ref_constant.g_yes;
        ELSE
            l_var := pk_ref_constant.g_no;
        END IF;
    
        OPEN o_ref FOR
            SELECT *
              FROM TABLE(CAST(get_exr_group_internal(i_lang,
                                                     i_prof,
                                                     i_exr,
                                                     i_type,
                                                     i_id_report,
                                                     i_id_ref_completion,
                                                     l_var,
                                                     i_flg_isencao) AS t_coll_ref_group)) t;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXR_GROUP',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref);
            RETURN FALSE;
    END get_exr_group;

    /**
    * Split a referral request into several copies
    * 
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Professional, institution and software ids
    * @param   i_exr_ori  Referral original identifier
    * @param   o_exr_new  Referral new identifier
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    */
    FUNCTION copy_exr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_exr_ori IN p1_external_request.id_external_request%TYPE,
        o_exr_new OUT p1_external_request.id_external_request%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_track IS
            SELECT *
              FROM p1_tracking
             WHERE id_external_request = i_exr_ori
             ORDER BY dt_tracking_tstz;
    
        CURSOR c_detail(x p1_tracking.id_tracking%TYPE) IS
            SELECT *
              FROM p1_detail
             WHERE id_external_request = i_exr_ori
               AND id_tracking = x
             ORDER BY dt_insert_tstz;
    
        CURSOR c_diagnosis IS
            SELECT *
              FROM p1_exr_diagnosis
             WHERE id_external_request = i_exr_ori
               AND flg_type IN (pk_ref_constant.g_exr_diag_type_d, pk_ref_constant.g_exr_diag_type_p)
             ORDER BY dt_insert_tstz;
    
        l_exr_diag_row p1_exr_diagnosis%ROWTYPE;
    
        l_exr_row      p1_external_request%ROWTYPE;
        l_track_row    p1_tracking%ROWTYPE;
        l_detail_row   p1_detail%ROWTYPE;
        l_track_id_ori p1_tracking.id_tracking%TYPE;
        l_rowids       table_varchar;
    
        l_bdnp_available sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'Init copy_exr / ID_REF_ORIG=' || i_exr_ori;
    
        g_error          := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_exr_ori;
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
        g_retval         := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                               i_prof   => i_prof,
                                                               i_id_ref => i_exr_ori,
                                                               o_rec    => l_exr_row,
                                                               o_error  => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        l_exr_row.id_external_request  := ts_p1_external_request.next_key();
        l_exr_row.num_req              := NULL;
        l_exr_row.id_p1_ext_req_parent := i_exr_ori;
    
        g_error := 'INSERT INTO p1_external_request';
        ts_p1_external_request.ins(rec_in => l_exr_row, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := NULL;
    
        IF l_bdnp_available = pk_ref_constant.g_yes
        THEN
            g_error  := 'Call pk_bdnp.set_bdnp_presc_detail ';
            g_retval := pk_bdnp.set_bdnp_presc_detail(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_patient     => l_exr_row.id_patient,
                                                      i_episode     => l_exr_row.id_episode,
                                                      i_type        => 'R',
                                                      i_presc       => l_exr_row.id_external_request,
                                                      i_flg_isencao => NULL,
                                                      o_error       => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error(g_error);
                RAISE g_exception;
            END IF;
        
            g_error := 'Call pk_ia_event_prescription.prescription_mcdt_new i_id_external_request=' ||
                       l_exr_row.id_external_request;
            pk_ia_event_prescription.prescription_mcdt_new(i_id_external_request => l_exr_row.id_external_request,
                                                           i_id_institution      => i_prof.institution);
        END IF;
    
        g_error := 'OPEN c_diagnosis';
        OPEN c_diagnosis;
        LOOP
            g_error := 'FETCH c_diagnosis';
            FETCH c_diagnosis
                INTO l_exr_diag_row;
            EXIT WHEN c_diagnosis%NOTFOUND;
        
            g_error                            := 'new values';
            l_exr_diag_row.id_exr_diagnosis    := seq_p1_exr_diagnosis.nextval;
            l_exr_diag_row.id_external_request := l_exr_row.id_external_request;
        
            g_error := 'INSERT INTO p1_exr_diagnosis';
            INSERT INTO p1_exr_diagnosis
            VALUES l_exr_diag_row;
        
        END LOOP;
        CLOSE c_diagnosis;
    
        l_rowids := NULL;
        g_error  := 'OPEN c_track';
        OPEN c_track;
        LOOP
            g_error := 'FETCH c_track';
            FETCH c_track
                INTO l_track_row;
            EXIT WHEN c_track%NOTFOUND;
        
            l_track_id_ori                  := l_track_row.id_tracking; -- old id_tracking value           
            l_track_row.id_tracking         := ts_p1_tracking.next_key(); -- new id_tracking value        
            l_track_row.id_external_request := l_exr_row.id_external_request;
        
            g_error := 'INSERT INTO p1_tracking';
            ts_p1_tracking.ins(rec_in => l_track_row, rows_out => l_rowids);
        
            g_error := 'OPEN c_detail';
            OPEN c_detail(l_track_id_ori);
            LOOP
                FETCH c_detail
                    INTO l_detail_row;
                EXIT WHEN c_detail%NOTFOUND;
            
                l_detail_row.id_detail := seq_p1_detail.nextval;
            
                g_error                          := 'ID_REF=' || l_exr_row.id_external_request || ' ID_TRACKING=' ||
                                                    l_track_row.id_tracking;
                l_detail_row.id_tracking         := l_track_row.id_tracking;
                l_detail_row.id_external_request := l_exr_row.id_external_request;
            
                g_error := 'INSERT INTO p1_detail';
                INSERT INTO p1_detail
                VALUES l_detail_row;
            
            END LOOP;
            CLOSE c_detail;
        
        END LOOP;
        CLOSE c_track;
    
        g_error := 't_data_gov_mnt.process_insert / P1_TRACKING';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_TRACKING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_exr_new := l_exr_row.id_external_request;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'COPY_EXR',
                                              o_error    => o_error);
            RETURN FALSE;
    END copy_exr;

    /**
    * Updates MCDT data
    * 
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_exr             Referral identifier
    * @param   i_id_episode      Episode identifier
    * @param   i_req_det         MCDT detail identifier    
    * @param   i_type            Referral type
    * @param   i_status          Flag referral related to the MCDT
    * @param   i_inst_dest       MCDT dest institution identifier
    * @param   i_flg_laterality  Flag laterality related to the MCDT (analysis not included)
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_type            {*} (A)nalysis {*} Other (E)xam {*} (I)mage {*} (P) Intervention {*} M(F)R
    * @value   i_status          {*} (R)eserved {*} (S)ent
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-06-2009
    */
    FUNCTION update_flg_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exr            IN p1_external_request.id_external_request%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_req_det        IN NUMBER,
        i_type           IN VARCHAR2,
        i_status         IN VARCHAR2,
        i_inst_dest      IN institution.id_institution%TYPE,
        i_flg_laterality IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- referrals related to this order (analysis)
        CURSOR c_ref_analysis IS
            SELECT DISTINCT et.id_external_request
              FROM p1_exr_temp et
              JOIN p1_external_request p
                ON (p.id_external_request = et.id_external_request)
             WHERE et.id_analysis_req_det = i_req_det
               AND et.id_external_request != i_exr
               AND p.flg_status != pk_ref_constant.g_p1_status_c;
    
        -- referrals related to this order  (exam)
        CURSOR c_ref_exam IS
            SELECT DISTINCT et.id_external_request
              FROM p1_exr_temp et
              JOIN p1_external_request p
                ON (p.id_external_request = et.id_external_request)
             WHERE et.id_exam_req_det = i_req_det
               AND et.id_external_request != i_exr
               AND p.flg_status != pk_ref_constant.g_p1_status_c;
    
        -- referrals related to this order  (procedures)
        CURSOR c_ref_proc IS
            SELECT DISTINCT et.id_external_request
              FROM p1_exr_temp et
              JOIN p1_external_request p
                ON (p.id_external_request = et.id_external_request)
             WHERE et.id_interv_presc_det = i_req_det
               AND et.id_external_request != i_exr
               AND p.flg_status != pk_ref_constant.g_p1_status_c;
    
        -- referrals related to this order  (rehab)
        CURSOR c_ref_rehab IS
            SELECT DISTINCT et.id_external_request
              FROM p1_exr_temp et
              JOIN p1_external_request p
                ON (p.id_external_request = et.id_external_request)
             WHERE et.id_rehab_presc = i_req_det
               AND et.id_external_request != i_exr
               AND p.flg_status != pk_ref_constant.g_p1_status_c;
    
        l_analysis_req_det_row analysis_req_det%ROWTYPE;
        l_exam_req_det_row     exam_req_det%ROWTYPE;
        reserved_req_a_ex      EXCEPTION;
        reserved_req_e_ex      EXCEPTION;
        reserved_req_i_ex      EXCEPTION;
    
        l_exr_req p1_external_request.id_external_request%TYPE;
    
        l_prof_cat_type category.flg_type%TYPE;
        l_dest_inst     institution.id_institution%TYPE;
        l_params        VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'ID_REF=' || i_exr || ' ID_EPISODE=' || i_id_episode || ' ID_REQ_DET=' || i_req_det || ' TYPE=' ||
                    i_type || ' STATUS=' || i_status || ' ID_INST_DEST=' || i_inst_dest || ' FLG_LATERALITY=' ||
                    i_flg_laterality;
        g_error  := 'Init update_flg_referral / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_prof_cat_type := pk_tools.get_prof_cat(i_prof);
    
        IF i_inst_dest IS NULL
        THEN
            g_error := 'SELECT P1_EXTERNAL_REQUEST / ' || l_params;
            SELECT id_inst_dest
              INTO l_dest_inst
              FROM p1_external_request
             WHERE id_external_request = i_exr;
        ELSE
            l_dest_inst := i_inst_dest;
        END IF;
    
        g_error := 'i_type = ' || i_type || ' / ' || l_params;
        IF i_type = pk_ref_constant.g_p1_type_a
        THEN
        
            IF i_req_det IS NOT NULL
            THEN
                -- getting referral related to this order (if any)
                g_error := 'OPEN c_ref_analysis / ' || l_params;
                OPEN c_ref_analysis;
                FETCH c_ref_analysis
                    INTO l_exr_req;
                CLOSE c_ref_analysis;
            
                -- Validate status (the request cannot be already associated to other referral)
                IF l_exr_req != i_exr
                THEN
                    RAISE reserved_req_a_ex;
                END IF;
            
                g_error  := 'Calling pk_lab_tests_external_api_db.update_lab_test_referral ' || l_params;
                g_retval := pk_lab_tests_external_api_db.update_lab_test_referral(i_lang             => i_lang,
                                                                                  i_prof             => i_prof,
                                                                                  i_analysis_req_det => i_req_det,
                                                                                  i_flg_referral     => i_status,
                                                                                  o_error            => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'SELECT id_analysis_req / ' || l_params;
                SELECT id_analysis_req, id_analysis_req_det
                  INTO l_analysis_req_det_row.id_analysis_req, l_analysis_req_det_row.id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req_det = i_req_det;
            
                g_error  := 'Call pk_lab_tests_api_db.set_lab_test_grid_task / ID_ANALYSIS_REQ=' ||
                            l_analysis_req_det_row.id_analysis_req || ' ID_ANALYSIS_REQ_DET=' ||
                            l_analysis_req_det_row.id_analysis_req_det || ' / ' || l_params;
                g_retval := pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                       i_prof             => i_prof,
                                                                       i_patient          => NULL,
                                                                       i_episode          => i_id_episode,
                                                                       i_analysis_req     => l_analysis_req_det_row.id_analysis_req,
                                                                       i_analysis_req_det => l_analysis_req_det_row.id_analysis_req_det,
                                                                       o_error            => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Call pk_lab_tests_external_api_db.update_lab_test_institution / i_exec_institution = ' ||
                            l_dest_inst || ' / ' || l_params;
                g_retval := pk_lab_tests_external_api_db.update_lab_test_institution(i_lang             => i_lang,
                                                                                     i_prof             => i_prof,
                                                                                     i_analysis_req_det => i_req_det,
                                                                                     i_exec_institution => l_dest_inst,
                                                                                     o_error            => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
        ELSIF (i_type = pk_ref_constant.g_p1_type_i OR i_type = pk_ref_constant.g_p1_type_e)
        THEN
        
            IF i_req_det IS NOT NULL
            THEN
            
                -- getting referral related to this order (if any)
                g_error := 'OPEN c_ref_exam / ' || l_params;
                OPEN c_ref_exam;
                FETCH c_ref_exam
                    INTO l_exr_req;
                CLOSE c_ref_exam;
            
                g_error := l_exr_req;
            
                -- Validate status (the request cannot be already associated to other referral)
                IF l_exr_req != i_exr
                THEN
                    RAISE reserved_req_e_ex;
                END IF;
            
                g_error  := 'Calling pk_exams_external_api_db.update_exam_referral / ' || l_params;
                g_retval := pk_exams_external_api_db.update_exam_referral(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_exam_req_det => i_req_det,
                                                                          i_flg_referral => i_status,
                                                                          o_error        => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'SELECT ID_EXAM_REQ_DET=' || i_req_det || ' / ' || l_params;
                SELECT id_exam_req, id_exam_req_det, flg_status
                  INTO l_exam_req_det_row.id_exam_req,
                       l_exam_req_det_row.id_exam_req_det,
                       l_exam_req_det_row.flg_status
                  FROM exam_req_det
                 WHERE id_exam_req_det = i_req_det;
            
                g_error  := 'Call pk_exams_api_db.set_exam_grid_task / ID_EXAM_REQ=' || l_exam_req_det_row.id_exam_req ||
                            ' ID_EXAM_REQ_DET=' || l_exam_req_det_row.id_exam_req_det || ' FLG_STATUS_REQ_DET=' ||
                            l_exam_req_det_row.flg_status || ' / ' || l_params;
                g_retval := pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_patient      => NULL,
                                                               i_episode      => i_id_episode,
                                                               i_exam_req     => l_exam_req_det_row.id_exam_req,
                                                               i_exam_req_det => l_exam_req_det_row.id_exam_req_det,
                                                               o_error        => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Calling pk_exams_external_api_db.update_exam_laterality / ' || l_params;
                g_retval := pk_exams_external_api_db.update_exam_laterality(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_exam_req_det   => i_req_det,
                                                                            i_flg_laterality => i_flg_laterality,
                                                                            o_error          => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Call pk_exams_external_api_db.update_exam_institution / I_EXEC_INSTITUTION=' ||
                            l_dest_inst || ' / ' || l_params;
                g_retval := pk_exams_external_api_db.update_exam_institution(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_exam_req_det     => i_req_det,
                                                                             i_exec_institution => l_dest_inst,
                                                                             o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
        ELSIF i_type = pk_ref_constant.g_p1_type_p
        THEN
            IF i_req_det IS NOT NULL
            THEN
                -- getting referral related to this order (if any)
                g_error := 'OPEN c_ref_proc / ' || l_params;
                OPEN c_ref_proc;
                FETCH c_ref_proc
                    INTO l_exr_req;
                CLOSE c_ref_proc;
            
                -- Validate status (the request cannot be already associated to other referral)
                IF l_exr_req != i_exr
                THEN
                    RAISE reserved_req_i_ex;
                END IF;
            
                g_error  := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.UPDATE_PROCEDURE_REFERRAL /' || l_params;
                g_retval := pk_procedures_external_api_db.update_procedure_referral(i_lang             => i_lang,
                                                                                    i_prof             => i_prof,
                                                                                    i_interv_presc_det => i_req_det,
                                                                                    i_flg_referral     => i_status,
                                                                                    o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.UPDATE_PROCEDURE_LATERALITY /' || l_params;
                g_retval := pk_procedures_external_api_db.update_procedure_laterality(i_lang             => i_lang,
                                                                                      i_prof             => i_prof,
                                                                                      i_interv_presc_det => i_req_det,
                                                                                      i_flg_laterality   => i_flg_laterality,
                                                                                      o_error            => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.UPDATE_PROCEDURE_INSTITUTION / ID_INSTITUTION=' ||
                            l_dest_inst || ' / ' || l_params;
                g_retval := pk_procedures_external_api_db.update_procedure_institution(i_lang             => i_lang,
                                                                                       i_prof             => i_prof,
                                                                                       i_interv_presc_det => i_req_det,
                                                                                       i_exec_institution => l_dest_inst,
                                                                                       o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
        ELSIF i_type = pk_ref_constant.g_p1_type_f
        THEN
            IF i_req_det IS NOT NULL
            THEN
            
                -- getting referral related to this order (if any)
                g_error := 'OPEN c_ref_rehab / ' || l_params;
                OPEN c_ref_rehab;
                FETCH c_ref_rehab
                    INTO l_exr_req;
                CLOSE c_ref_rehab;
            
                -- Validate status (the request cannot be already associated to other referral)
                IF l_exr_req != i_exr
                THEN
                    RAISE reserved_req_i_ex;
                END IF;
            
                g_error  := 'Calling pk_rehab.update_flg_referral / ' || l_params;
                g_retval := pk_rehab.update_flg_referral(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_rehab_presc => i_req_det,
                                                         i_flg_referral   => i_status,
                                                         o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Calling pk_rehab.update_flg_laterality / ' || l_params;
                g_retval := pk_rehab.update_flg_laterality(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_rehab_presc => i_req_det,
                                                           i_flg_laterality => i_flg_laterality,
                                                           o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF l_dest_inst IS NOT NULL
                THEN
                    g_error  := 'Calling pk_rehab.update_exec_institution / i_id_institution = ' || l_dest_inst ||
                                ' / ' || l_params;
                    g_retval := pk_rehab.update_exec_institution(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_rehab_presc => i_req_det,
                                                                 i_id_institution => l_dest_inst,
                                                                 o_error          => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN reserved_req_a_ex THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000);
            BEGIN
            
                SELECT REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'P1_DOCTOR_CS_T115'),
                               '@1',
                               pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL))
                  INTO l_error_message
                  FROM analysis_req_det ad
                  JOIN analysis a
                    ON (ad.id_analysis = a.id_analysis)
                 WHERE ad.id_analysis_req_det = l_analysis_req_det_row.id_analysis_req_det;
            
                l_error_in.set_all(i_lang,
                                   'P1_DOCTOR_CS_T115',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPDATE_FLG_REFERRAL',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
        WHEN reserved_req_e_ex THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000);
            BEGIN
            
                SELECT REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'P1_DOCTOR_CS_T115'),
                               '@1',
                               pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam))
                  INTO l_error_message
                  FROM exam_req_det ed
                  JOIN exam e
                    ON (ed.id_exam = e.id_exam)
                 WHERE ed.id_exam_req_det = l_exam_req_det_row.id_exam_req_det;
            
                l_error_in.set_all(i_lang,
                                   'P1_DOCTOR_CS_T115',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPDATE_FLG_REFERRAL',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
        WHEN reserved_req_i_ex THEN
        
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000);
            BEGIN
            
                SELECT REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'P1_DOCTOR_CS_T115'),
                               '@1',
                               pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL))
                  INTO l_error_message
                  FROM interv_presc_det id
                  JOIN intervention i
                    ON (id.id_intervention = i.id_intervention)
                 WHERE id.id_interv_presc_det = i_req_det;
            
                l_error_in.set_all(i_lang,
                                   'P1_DOCTOR_CS_T115',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPDATE_FLG_REFERRAL',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        
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
                                              i_function => 'UPDATE_FLG_REFERRAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_flg_referral;

    /**
    * Splits referral MCDTs into groups, as required the specified report    
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_id_patient              Patient id    
    * @param   i_exr                     Referral identifier
    * @param   i_id_episode              Episode identifier
    * @param   i_type                    Splitting type
    * @param   i_num_req                 Num_req ids        
    * @param   i_id_report               Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion       Referral completion option id. Needed to get the maximum number of MCDTs in each referral report
    * @param   o_id_external_request     Referral requests identifiers
    * @param   o_error                   An error message, set when return=false
    *
    * @value   i_type                    {*} 'PV' print preview (do not generate codes)
    *                                    {*} 'PF' print final(generate codes)
    *                                    {*} 'A' application
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    */
    FUNCTION split_mcdt_request_by_group
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_exr                 IN p1_external_request.id_external_request%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_type                IN VARCHAR2,
        i_num_req             IN table_varchar,
        i_id_report           IN reports.id_reports%TYPE,
        i_id_ref_completion   IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao         IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exr_row p1_external_request%ROWTYPE;
    
        l_old_group NUMBER DEFAULT - 1;
        l_exr_new   p1_external_request.id_external_request%TYPE;
        l_track_row p1_tracking%ROWTYPE;
    
        i NUMBER DEFAULT 1;
    
        l_num_req           p1_external_request.num_req%TYPE;
        l_num_req_exception EXCEPTION;
        l_rowids            table_varchar;
    
        l_flg_referral   VARCHAR2(1 CHAR);
        l_codification   codification.id_codification%TYPE;
        l_gen_number     VARCHAR2(1);
        l_track          table_number;
        l_id_p1_exr_temp p1_exr_temp.id_exr_temp%TYPE;
    
    BEGIN
    
        g_error := 'Init split_mcdt_request_by_group / ID_REF=' || i_exr || ' ID_PATIENT=' || i_id_patient ||
                   ' ID_EPISODE=' || i_id_episode || ' TYPE=' || i_type || ' ID_REPORT=' || i_id_report ||
                   ' REF_COMPLETION=' || i_id_ref_completion;
    
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
        l_gen_number   := pk_ref_constant.g_no;
        l_track        := table_number();
    
        --  getting referral row (up to date)
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_exr;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_exr,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_exr_new := i_exr;
    
        -- Updates referral status
        IF i_type = pk_ref_constant.g_rep_mode_pf
        THEN
        
            g_error                         := 'UPDATE STATUS / ID_REF=' || i_exr;
            l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_p;
            l_track_row.id_external_request := l_exr_row.id_external_request;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_o ||
                                                                  pk_ref_constant.g_p1_status_g,
                                                 i_flg_isencao => i_flg_isencao,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => l_track,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error        := 'ID_REF=' || l_exr_row.id_external_request || ' FLG_REFERRAL = ' ||
                              pk_ref_constant.g_flg_referral_s; -- Sent (printed)
            l_flg_referral := pk_ref_constant.g_flg_referral_s;
        
        ELSIF i_type = pk_ref_constant.g_rep_mode_a
        THEN
        
            g_error := 'FLG_REFERRAL / ID_REF=' || i_exr;
            IF l_exr_row.flg_status = pk_ref_constant.g_p1_status_g
            THEN
                l_flg_referral := pk_ref_constant.g_flg_referral_r;
            ELSE
                l_flg_referral := pk_ref_constant.g_flg_referral_i;
            END IF;
        
            g_error := 'ID_REF=' || l_exr_row.id_external_request || ' FLG_REFERRAL = ' || l_flg_referral;
        
        ELSE
            g_error := 'Invalid value for i_type';
            RAISE g_exception;
        END IF;
    
        g_error := 'FOR get_exr_group / ID_EXT_REQ=' || i_exr || ' TYPE=' || i_type || ' ID_REPORT=' || i_id_report ||
                   ' ID_REF_COMPLETION=' || i_id_ref_completion;
        FOR w IN (SELECT t.*
                    FROM TABLE(get_exr_group_internal(i_lang,
                                                      i_prof,
                                                      i_exr,
                                                      i_type,
                                                      i_id_report,
                                                      i_id_ref_completion,
                                                      l_gen_number,
                                                      i_flg_isencao)) t)
        LOOP
        
            g_error := 'w.id_group=' || w.id_group || ' l_old_group=' || l_old_group;
            IF w.id_group != l_old_group
            THEN
                IF i_num_req IS NOT NULL
                   AND i > i_num_req.count
                THEN
                    RAISE l_num_req_exception;
                END IF;
            
                -- Copy the referral (not for the first)
                IF i != 1
                THEN
                    g_error  := 'Call copy_exr / ID_REF=' || i_exr;
                    g_retval := copy_exr(i_lang    => i_lang,
                                         i_prof    => i_prof,
                                         i_exr_ori => i_exr,
                                         o_exr_new => l_exr_new,
                                         o_error   => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            
                IF i_num_req IS NOT NULL
                THEN
                    l_num_req := i_num_req(i);
                ELSE
                    l_num_req := to_char(l_exr_new);
                END IF;
            
                -- Updates id_inst_dest, flg_priority, flg_home and num_req            
                g_error := 'Call ts_p1_external_request.upd / ID_REF=' || i_exr;
                ts_p1_external_request.upd(id_external_request_in => l_exr_new,
                                           id_inst_dest_in        => w.id_institution,
                                           flg_priority_in        => w.flg_priority,
                                           flg_home_in            => w.flg_home,
                                           num_req_in             => l_num_req,
                                           rows_out               => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'P1_EXTERNAL_REQUEST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                IF i = 1
                THEN
                    o_id_external_request := table_number(NULL);
                ELSE
                    o_id_external_request.extend(1, 1);
                END IF;
            
                o_id_external_request(i) := l_exr_new;
                i := i + 1;
            
            END IF;
        
            l_old_group := w.id_group;
        
            UPDATE p1_exr_temp a
               SET id_group = w.id_group
             WHERE id_exr_temp = w.id_exr_temp;
        
            g_error := 'w.id_req=' || w.id_req;
            IF w.id_req IS NOT NULL
            THEN
            
                g_error := 'Call update_flg_referral / ID_REF=' || i_exr || ' ID_EPISODE=' || i_id_episode ||
                           ' REQ_DET=' || w.id_req || ' TYPE=' || l_exr_row.flg_type || ' FLG_REFERRAL=' ||
                           l_flg_referral || ' ID_INST_DEST=' || l_exr_row.id_inst_dest;
                IF NOT update_flg_referral(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_exr            => i_exr,
                                           i_id_episode     => i_id_episode,
                                           i_req_det        => w.id_req,
                                           i_type           => l_exr_row.flg_type,
                                           i_status         => l_flg_referral, -- sent or issued
                                           i_inst_dest      => l_exr_row.id_inst_dest,
                                           i_flg_laterality => w.flg_laterality,
                                           o_error          => o_error)
                THEN
                    NULL;
                END IF;
            END IF;
        
            IF l_exr_row.flg_type = pk_ref_constant.g_p1_type_a
            THEN
                -- Remove from p1_exr_temp               
                g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                /*DELETE FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_analysis = w.id
                   AND pt.id_sample_type = w.id_sample_type
                   AND pt.id_analysis_req_det = w.id_req
                   AND pt.id_exr_temp = w.id_exr_temp
                RETURNING id_codification INTO l_codification;*/
                SELECT id_codification, pt.id_exr_temp
                  INTO l_codification, l_id_p1_exr_temp
                  FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_analysis = w.id
                   AND pt.id_sample_type = w.id_sample_type
                   AND pt.id_analysis_req_det = w.id_req
                   AND pt.id_exr_temp = w.id_exr_temp;
            
                g_error := 'INSERT INTO p1_exr_analysis';
                INSERT INTO p1_exr_analysis
                    (id_exr_analysis,
                     id_external_request,
                     id_analysis,
                     id_analysis_req_det,
                     id_codification,
                     amount,
                     flg_ald,
                     id_sample_type,
                     id_p1_exr_temp)
                VALUES
                    (seq_p1_exr_analysis.nextval,
                     l_exr_new,
                     w.id,
                     w.id_req,
                     l_codification,
                     w.amount,
                     w.flg_ald,
                     w.id_sample_type,
                     l_id_p1_exr_temp);
            
                -- Remove from p1_exr_temp                     
                /* DELETE FROM p1_exr_temp pt
                WHERE id_external_request = l_exr_row.id_external_request
                  AND pt.id_analysis_req_det = w.id_req
                  AND pt.id_analysis = w.id
                  AND pt.id_exr_temp = w.id_exr_temp
                  AND pt.id_sample_type = w.id_sample_type;*/
            
            ELSIF (l_exr_row.flg_type = pk_ref_constant.g_p1_type_i OR l_exr_row.flg_type = pk_ref_constant.g_p1_type_e)
            THEN
            
                -- Remove from p1_exr_temp            
                g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                /*DELETE FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_exam = w.id
                   AND pt.id_exam_req_det = w.id_req
                RETURNING id_codification INTO l_codification;*/
                SELECT id_codification, pt.id_exr_temp
                  INTO l_codification, l_id_p1_exr_temp
                  FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_exam = w.id
                   AND pt.id_exam_req_det = w.id_req;
            
                g_error := 'INSERT INTO p1_exr_exam' || l_exr_row.flg_type;
                INSERT INTO p1_exr_exam
                    (id_exr_exam,
                     id_external_request,
                     id_exam,
                     id_exam_req_det,
                     id_codification,
                     amount,
                     flg_ald,
                     id_p1_exr_temp)
                VALUES
                    (seq_p1_exr_exam.nextval,
                     l_exr_new,
                     w.id,
                     w.id_req,
                     l_codification,
                     w.amount,
                     w.flg_ald,
                     l_id_p1_exr_temp);
            
                -- remove from p1_exr_temp      
                g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                /* DELETE FROM p1_exr_temp pt
                WHERE id_external_request = l_exr_row.id_external_request
                  AND pt.id_exam = w.id;*/
            
            ELSIF l_exr_row.flg_type = pk_ref_constant.g_p1_type_p
            THEN
            
                -- remove from p1_exr_temp
                g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                /*DELETE FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_intervention = w.id
                   AND pt.id_interv_presc_det = w.id_req
                RETURNING id_codification INTO l_codification;*/
                SELECT id_codification, pt.id_exr_temp
                  INTO l_codification, l_id_p1_exr_temp
                  FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_intervention = w.id
                   AND pt.id_interv_presc_det = w.id_req;
            
                g_error := 'INSERT INTO p1_exr_intervention' || l_exr_row.flg_type;
                INSERT INTO p1_exr_intervention
                    (id_exr_intervention,
                     id_external_request,
                     id_intervention,
                     id_interv_presc_det,
                     id_codification,
                     amount,
                     flg_ald,
                     id_p1_exr_temp)
                VALUES
                    (seq_p1_exr_intervention.nextval,
                     l_exr_new,
                     w.id,
                     w.id_req,
                     l_codification,
                     w.amount,
                     w.flg_ald,
                     l_id_p1_exr_temp);
            
                -- remove from p1_exr_temp
                /*g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                DELETE FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_intervention = w.id;*/
            
            ELSIF l_exr_row.flg_type = pk_ref_constant.g_p1_type_f
            THEN
                -- remove from p1_exr_temp
                g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                /*DELETE FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_intervention = w.id
                   AND pt.id_rehab_presc = w.id_req
                RETURNING id_codification INTO l_codification;*/
                SELECT id_codification, pt.id_exr_temp
                  INTO l_codification, l_id_p1_exr_temp
                  FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_intervention = w.id
                   AND pt.id_rehab_presc = w.id_req;
            
                g_error := 'INSERT INTO p1_exr_intervention' || l_exr_row.flg_type;
                INSERT INTO p1_exr_intervention
                    (id_exr_intervention,
                     id_external_request,
                     id_intervention,
                     id_rehab_presc,
                     id_codification,
                     amount,
                     flg_ald,
                     id_p1_exr_temp)
                VALUES
                    (seq_p1_exr_intervention.nextval,
                     l_exr_new,
                     w.id,
                     w.id_req,
                     l_codification,
                     w.amount,
                     w.flg_ald,
                     l_id_p1_exr_temp);
            
                -- remove from p1_exr_temp
                /* g_error := 'DELETE FROM p1_exr_temp' || l_exr_row.flg_type;
                DELETE FROM p1_exr_temp pt
                 WHERE id_external_request = l_exr_row.id_external_request
                   AND pt.id_intervention = w.id;*/
            
            END IF;
        
            UPDATE p1_exr_temp a
               SET a.id_external_request = l_exr_new
             WHERE id_exr_temp = w.id_exr_temp;
        END LOOP;
    
        g_error := 'ID_EPISODE=' || i_id_episode || ' ID_PATIENT=' || i_id_patient;
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => i_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => NULL,
                                          o_error               => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- set print list job as completed (if exists in printing list)
            g_error  := 'Call pk_ref_ext_sys.set_print_jobs_complete / ID_EPISODE=' || i_id_episode || ' ID_PATIENT=' ||
                        i_id_patient;
            g_retval := pk_ref_ext_sys.set_print_jobs_complete(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_patient => i_id_patient,
                                                               i_id_episode => i_id_episode,
                                                               i_id_ref     => i_exr,
                                                               o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN l_num_req_exception THEN
        
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := 'Array i_num_req must have as many values as created referrals';
            BEGIN
                l_error_in.set_all(i_lang,
                                   'Array i_num_req',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SPLIT_MCDT_REQUEST_BY_GROUP',
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
                                              i_function => 'SPLIT_MCDT_REQUEST_BY_GROUP',
                                              o_error    => o_error);
            RETURN FALSE;
    END split_mcdt_request_by_group;

    /**
    * Insert mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_id_patient          Patient identifier
    * @param   i_id_episode          Episode identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information
    * @param   i_ref_completion      
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @value   i_flg_type            {*}'A' analysis {*}'I' Image {*}'E' Other Exams {*}'P' Intervention/Procedures {*}'F' Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION insert_referral_mcdt_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        --i_id_sched            IN schedule.id_schedule%TYPE, --- Not used
        i_problems            IN CLOB,
        i_dt_problem_begin    IN VARCHAR2,
        i_detail              IN table_table_varchar,
        i_diagnosis           IN CLOB,
        i_completed           IN VARCHAR2,
        i_id_tasks            IN table_table_number,
        i_id_info             IN table_table_number,
        i_codification        IN codification.id_codification%TYPE,
        i_flg_laterality      IN table_varchar DEFAULT NULL,
        i_ref_completion      IN ref_completion.id_ref_completion%TYPE,
        i_consent             IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_a_req_det_row     analysis_req_det%ROWTYPE;
        l_e_req_det_row     exam_req_det%ROWTYPE;
        l_i_presc_det_row   interv_presc_det%ROWTYPE;
        l_i_rehab_presc_row rehab_presc%ROWTYPE;
        l_exception         EXCEPTION;
        l_params            VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ext_req=' || i_ext_req || ' i_dt_modified=' ||
                    i_dt_modified || ' i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode ||
                    ' i_req_type=' || i_req_type || ' i_flg_type=' || i_flg_type || ' i_dt_problem_begin=' ||
                    i_dt_problem_begin || ' i_completed=' || i_completed || ' i_codification=' || i_codification ||
                    ' i_ref_completion=' || i_ref_completion;
        g_error  := 'Init insert_referral_mcdt_internal / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        -- check if i_mcdt and i_inst_dest are empty
        IF i_mcdt IS NULL
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'Validate i_mcdt count=' || i_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
        
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NOT NULL
            THEN
                -- this is checked only if MCDTs have been ordered
                BEGIN
                
                    g_error := 'i_flg_type=' || i_flg_type || ' i_mcdt(' || i || ')(' || pk_ref_constant.g_idx_id_mcdt || ')=' ||
                               i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt) || ' i_mcdt(' || i || ')(' ||
                               pk_ref_constant.g_idx_id_req_det || ')=' || i_mcdt(i)
                               (pk_ref_constant.g_idx_id_req_det) || ' / ' || l_params;
                    pk_alertlog.log_debug(g_error);
                
                    IF i_flg_type = pk_ref_constant.g_p1_type_a
                    THEN
                        SELECT *
                          INTO l_a_req_det_row
                          FROM analysis_req_det ard
                         WHERE ard.id_analysis = i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt)
                           AND ard.id_analysis_req_det = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                    
                    ELSIF (i_flg_type = pk_ref_constant.g_p1_type_i OR i_flg_type = pk_ref_constant.g_p1_type_e)
                    THEN
                    
                        SELECT *
                          INTO l_e_req_det_row
                          FROM exam_req_det erd
                         WHERE erd.id_exam = i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt)
                           AND erd.id_exam_req_det = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                    
                    ELSIF i_flg_type = pk_ref_constant.g_p1_type_p
                    THEN
                    
                        SELECT *
                          INTO l_i_presc_det_row
                          FROM interv_presc_det ipd
                         WHERE ipd.id_intervention = i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt)
                           AND ipd.id_interv_presc_det = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                    
                    ELSIF i_flg_type = pk_ref_constant.g_p1_type_f
                    THEN
                    
                        SELECT rp.*
                          INTO l_i_rehab_presc_row
                          FROM rehab_presc rp
                          JOIN rehab_area_interv rai
                            ON (rp.id_rehab_area_interv = rai.id_rehab_area_interv)
                         WHERE rai.id_intervention = i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt)
                           AND rp.id_rehab_presc = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'Error in i_mcdt data. : i_exr: ' || i_ext_req || '; id_mcdt: ' || i_mcdt(i)
                                   (pk_ref_constant.g_idx_id_mcdt) || '; id_mcdt_req: ' || i_mcdt(i)
                                   (pk_ref_constant.g_idx_id_req_det) || ' / ' || l_params;
                        RAISE g_exception;
                END;
            END IF;
        
        END LOOP;
    
        IF i_ext_req IS NULL
        THEN
            g_error  := 'Call create_external_request_mcdt / ' || l_params;
            g_retval := create_external_request_mcdt(i_lang              => i_lang,
                                                     i_id_patient        => i_id_patient,
                                                     i_id_episode        => i_id_episode,
                                                     i_req_type          => i_req_type,
                                                     i_flg_type          => i_flg_type,
                                                     i_flg_priority_home => i_flg_priority_home,
                                                     i_mcdt              => i_mcdt,
                                                     i_prof              => i_prof,
                                                     --i_id_sched            => i_id_sched,
                                                     i_problems            => i_problems,
                                                     i_dt_problem_begin    => i_dt_problem_begin,
                                                     i_detail              => i_detail,
                                                     i_diagnosis           => i_diagnosis,
                                                     i_completed           => i_completed,
                                                     i_id_tasks            => i_id_tasks,
                                                     i_id_info             => i_id_info,
                                                     i_codification        => i_codification,
                                                     i_flg_laterality      => i_flg_laterality,
                                                     i_consent             => i_consent,
                                                     o_id_external_request => o_id_external_request,
                                                     o_flg_show            => o_flg_show,
                                                     o_msg                 => o_msg,
                                                     o_msg_title           => o_msg_title,
                                                     o_button              => o_button,
                                                     o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            g_error  := 'Call update_external_request_mcdt / ' || l_params;
            g_retval := update_external_request_mcdt(i_lang              => i_lang,
                                                     i_ext_req           => i_ext_req,
                                                     i_dt_modified       => i_dt_modified,
                                                     i_id_episode        => i_id_episode,
                                                     i_req_type          => i_req_type,
                                                     i_flg_type          => i_flg_type,
                                                     i_flg_priority_home => i_flg_priority_home,
                                                     i_mcdt              => i_mcdt,
                                                     i_prof              => i_prof,
                                                     --i_id_sched            => i_id_sched,
                                                     i_problems            => i_problems,
                                                     i_dt_problem_begin    => i_dt_problem_begin,
                                                     i_detail              => i_detail,
                                                     i_diagnosis           => i_diagnosis,
                                                     i_completed           => i_completed,
                                                     i_id_tasks            => i_id_tasks,
                                                     i_id_info             => i_id_info,
                                                     i_codification        => i_codification,
                                                     i_flg_laterality      => i_flg_laterality,
                                                     i_consent             => i_consent,
                                                     o_id_external_request => o_id_external_request,
                                                     o_flg_show            => o_flg_show,
                                                     o_msg                 => o_msg,
                                                     o_msg_title           => o_msg_title,
                                                     o_button              => o_button,
                                                     o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN l_exception THEN
        
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'P1_DOCTOR_CS_T110');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'P1_DOCTOR_CS_T110',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'INSERT_REFERRAL_MCDT_INTERNAL',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_REFERRAL_MCDT_INTERNAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END insert_referral_mcdt_internal;

    /**
    * Gets next status of mcdt referral: (N)ew or (G) Harvest
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_flg_type            Referral type: {*} 'A' analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR   
    * @param   i_mcdt_req_det        MCDT req detail identification    
    * @param   o_flg_status          Referral flag status
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-09-2009
    */
    FUNCTION get_status_mcdt
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN p1_external_request.flg_type%TYPE,
        i_mcdt_req_det IN table_number,
        o_flg_status   OUT p1_external_request.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_completed VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'Init get_status_mcdt';
        IF i_flg_type = pk_ref_constant.g_p1_type_a
        THEN
        
            g_error  := 'get_status_mcdt / Calling PK_P1_ANALYSIS.check_ref_completed / mcdt_req_det.COUNT=' ||
                        i_mcdt_req_det.count;
            g_retval := pk_p1_analysis.check_ref_completed(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_analysis_req_det => i_mcdt_req_det,
                                                           o_flg_completed    => l_flg_completed,
                                                           o_error            => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            -- checking if all analysis are harvested
            IF l_flg_completed = pk_ref_constant.g_yes
            THEN
                o_flg_status := pk_ref_constant.g_p1_status_n; -- all analysis are harvested
            ELSE
                o_flg_status := pk_ref_constant.g_p1_status_g; -- there is at least one analysis that is not harvested
            END IF;
        
        ELSE
            o_flg_status := pk_ref_constant.g_p1_status_n;
        END IF;
    
        g_error := 'get_status_mcdt / flg_type=' || i_flg_type || ' flg_status=' || o_flg_status;
        --pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_MCDT',
                                              o_error    => o_error);
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
    END get_status_mcdt;

    /**
    * Create new mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_patient          Patient identifier
    * @param   i_id_episode          Episode identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @value   i_flg_type            {*}'A' analysis {*}'I' Image {*}'E' Other Exams {*}'P' Intervention/Procedures {*}'F' Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION create_external_request_mcdt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems                  IN CLOB,
        i_dt_problem_begin          IN VARCHAR2,
        i_detail                    IN table_table_varchar,
        i_diagnosis                 IN CLOB,
        i_completed                 IN VARCHAR2,
        i_id_tasks                  IN table_table_number,
        i_id_info                   IN table_table_number,
        i_codification              IN codification.id_codification%TYPE,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_consent                   IN VARCHAR2,
        i_reason                    IN table_varchar DEFAULT NULL,
        i_complementary_information IN table_varchar DEFAULT NULL,
        i_health_plan               IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption                 IN pat_isencao.id_pat_isencao%TYPE DEFAULT NULL,
        i_id_fam_rel                IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec              IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel            IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel           IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel             IN VARCHAR2 DEFAULT NULL,
        o_id_external_request       OUT table_number,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr                       p1_external_request%ROWTYPE;
        l_track_row                 p1_tracking%ROWTYPE;
        l_id_external_request       table_number := table_number(NULL);
        l_rowids                    table_varchar;
        l_mcdt_req_det              table_number := table_number();
        l_flg_referral              VARCHAR2(1 CHAR);
        l_detail                    table_table_varchar;
        l_flg_laterality            VARCHAR2(1 CHAR);
        l_track                     table_number;
        l_track_tab                 table_number;
        l_reason                    VARCHAR2(1000 CHAR);
        l_complementary_information VARCHAR2(1000 CHAR);
    
        l_problems  pk_edis_types.rec_in_epis_diagnoses;
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    BEGIN
        g_error := 'Init create_external_request_mcdt / ID_PAT=' || i_id_patient || ' ID_EPISODE=' || i_id_episode ||
                   ' FLG_TYPE=' || i_flg_type;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
        l_track        := table_number();
    
        IF i_mcdt.count = 0
        THEN
            g_error := g_error || ' / i_mcdt.COUNT=' || i_mcdt.count;
            RAISE g_exception;
        END IF;
    
        g_error := 'CHECK ARRAYS SIZE';
        IF (i_mcdt.count != i_flg_priority_home.count)
        THEN
            g_error := g_error || ' / i_mcdt.COUNT=' || i_mcdt.count || ' i_flg_priority_home.COUNT=' ||
                       i_flg_priority_home.count;
            RAISE g_exception;
        END IF;
    
        g_error          := 'l_exr';
        l_exr.id_patient := i_id_patient;
        l_exr.req_type   := i_req_type;
        l_exr.flg_type   := i_flg_type;
    
        IF i_flg_type = pk_ref_constant.g_p1_type_a
        THEN
            g_error := 'EXTEND(' || i_mcdt.count || ')';
            l_mcdt_req_det.extend(i_mcdt.count);
        
            FOR i IN 1 .. i_mcdt.count
            LOOP
                l_mcdt_req_det(i) := i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
            END LOOP;
        END IF;
    
        g_error := 'i_completed=' || i_completed;
        IF i_completed = pk_ref_constant.g_yes
        THEN
            g_error  := 'Calling get_status_mcdt / FLG_TYPE=' || i_flg_type;
            g_retval := get_status_mcdt(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_flg_type     => i_flg_type,
                                        i_mcdt_req_det => l_mcdt_req_det,
                                        o_flg_status   => l_exr.flg_status,
                                        o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error        := 'STATUS=' || l_exr.flg_status || ' |FLG_TYPE=' || i_flg_type;
            l_flg_referral := pk_ref_constant.g_flg_referral_r;
        
        ELSE
            l_exr.flg_status := pk_ref_constant.g_p1_status_o;
            l_flg_referral   := pk_ref_constant.g_flg_referral_r;
        END IF;
    
        g_error                 := 'l_exr2';
        l_exr.id_prof_status    := i_prof.id;
        l_exr.dt_status_tstz    := g_sysdate_tstz;
        l_exr.id_inst_orig      := i_prof.institution;
        l_exr.id_prof_requested := i_prof.id;
        l_exr.id_prof_created   := i_prof.id;
        l_exr.flg_paper_doc     := pk_ref_constant.g_no;
        l_exr.flg_digital_doc   := pk_ref_constant.g_no;
        l_exr.flg_mail          := pk_ref_constant.g_no;
    
        -- ALERT-194568: problem begin date
        g_error  := 'Call pk_ref_utils.parse_dt_str / ID_REF=' || l_exr.id_external_request;
        g_retval := pk_ref_utils.parse_dt_str(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dt_str_flash => i_dt_problem_begin,
                                              o_year         => l_exr.year_begin,
                                              o_month        => l_exr.month_begin,
                                              o_day          => l_exr.day_begin,
                                              o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_exr.id_episode                := i_id_episode;
        l_exr.flg_priority              := pk_ref_orig_phy.get_priority_home(i_lang, i_flg_priority_home, 1);
        l_exr.flg_home                  := pk_ref_orig_phy.get_priority_home(i_lang, i_flg_priority_home, 2);
        l_exr.id_inst_dest              := i_mcdt(1) (pk_ref_constant.g_idx_id_inst_dest_mcdt);
        l_exr.dt_requested              := g_sysdate_tstz;
        l_exr.consent                   := i_consent;
        l_exr.id_pat_health_plan        := i_health_plan;
        l_exr.id_pat_exemption          := i_exemption;
        l_exr.id_external_request       := ts_p1_external_request.next_key;
        l_exr.id_fam_rel                := i_id_fam_rel;
        l_exr.family_relationship_notes := i_fam_rel_spec;
        l_exr.name_first_rel            := i_name_first_rel;
        l_exr.name_middle_rel           := i_name_middle_rel;
        l_exr.name_last_rel             := i_name_last_rel;
    
        g_error := 'ts_p1_external_request.ins / ID_EXTERNAL_REQUEST=' || l_exr.id_external_request;
        ts_p1_external_request.ins(rec_in => l_exr, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_completed = pk_ref_constant.g_yes
        THEN
            l_exr.num_req := l_exr.id_external_request;
        END IF;
    
        g_error := 'i_mcdt.count=' || i_mcdt.count;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            g_error := 'l_flg_laterality';
            IF i_flg_laterality IS NOT NULL
            THEN
                l_flg_laterality := i_flg_laterality(i);
            ELSE
                l_flg_laterality := NULL;
            END IF;
        
            g_error := 'l_reason';
            IF i_reason.exists(i)
            THEN
                l_reason := i_reason(i);
            ELSE
                l_reason := NULL;
            END IF;
        
            g_error := 'l_complementary_information';
            IF i_complementary_information.exists(i)
            THEN
                l_complementary_information := i_complementary_information(i);
            ELSE
                l_complementary_information := NULL;
            END IF;
        
            -- Actualizar analysis_req_det.flg_referral
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NOT NULL
            THEN
                g_error  := 'Call update_flg_referral / id_ref=' || l_exr.id_external_request || ' i_req_det=' ||
                            i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) || ' i_inst_dest=' || i_mcdt(i)
                            (pk_ref_constant.g_idx_id_inst_dest_mcdt) || ' flg_referral=' || l_flg_referral ||
                            ' flg_type=' || i_flg_type;
                g_retval := update_flg_referral(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_exr            => l_exr.id_external_request,
                                                i_id_episode     => i_id_episode,
                                                i_req_det        => i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                                                i_type           => i_flg_type,
                                                i_status         => l_flg_referral,
                                                i_inst_dest      => i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt),
                                                i_flg_laterality => l_flg_laterality,
                                                o_error          => o_error);
                IF NOT g_retval
                THEN
                    g_error := g_error || ' / error / ID_EXT_REQ=' || l_exr.id_external_request || '|ID_EPISODE=' ||
                               i_id_episode || '|ID_REQ_DET=' || i_mcdt(i)
                               (pk_ref_constant.g_idx_id_req_det) || '|FLG_REFERRAL=' || l_flg_referral || '|FLG_TYPE=' ||
                               i_flg_type || '|ID_INST_DEST=' || i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt);
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
            g_error := 'FLG_TYPE=' || i_flg_type;
            IF i_flg_type = pk_ref_constant.g_p1_type_a
            THEN
                g_error := 'insert p1_exr_temp / id_analysis=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_mcdt) || ' id_analysis_req_det=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_req_det) || ' id_institution=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || ' flg_priority=' || i_flg_priority_home(i)
                           (1) || ' flg_home=' || i_flg_priority_home(i)
                           (2) || ' id_codification=' || i_codification || ' amount=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_amount) || ' id_sample_type=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_sample_type);
                INSERT INTO p1_exr_temp
                    (id_exr_temp,
                     id_external_request,
                     id_analysis,
                     id_analysis_req_det,
                     id_institution,
                     flg_priority,
                     flg_home,
                     id_codification,
                     amount,
                     id_sample_type,
                     reason,
                     complementary_information)
                VALUES
                    (seq_p1_exr_temp.nextval,
                     l_exr.id_external_request,
                     i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt),
                     i_flg_priority_home(i) (1),
                     i_flg_priority_home(i) (2),
                     i_codification,
                     i_mcdt(i) (pk_ref_constant.g_idx_amount),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_sample_type),
                     l_reason,
                     l_complementary_information);
            
            ELSIF (i_flg_type = pk_ref_constant.g_p1_type_i OR i_flg_type = pk_ref_constant.g_p1_type_e)
            THEN
            
                g_error := 'insert p1_exr_temp / id_exam=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_mcdt) || ' id_exam_req_det=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_req_det) || ' id_institution=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || ' flg_priority=' || i_flg_priority_home(i)
                           (1) || ' flg_home=' || i_flg_priority_home(i)
                           (2) || ' id_codification=' || i_codification || 'Amount=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_amount);
                INSERT INTO p1_exr_temp
                    (id_exr_temp,
                     id_external_request,
                     id_exam,
                     id_exam_req_det,
                     id_institution,
                     flg_priority,
                     flg_home,
                     id_codification,
                     amount,
                     reason,
                     complementary_information)
                VALUES
                    (seq_p1_exr_temp.nextval,
                     l_exr.id_external_request,
                     i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt),
                     i_flg_priority_home(i) (1),
                     i_flg_priority_home(i) (2),
                     i_codification,
                     i_mcdt(i) (pk_ref_constant.g_idx_amount),
                     l_reason,
                     l_complementary_information);
            
            ELSIF i_flg_type = pk_ref_constant.g_p1_type_p
            THEN
            
                g_error := 'insert p1_exr_temp / id_intervention=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_mcdt) || ' id_interv_presc_det=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_req_det) || ' id_institution=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || ' flg_priority=' || i_flg_priority_home(i)
                           (1) || ' flg_home=' || i_flg_priority_home(i)
                           (2) || ' id_codification=' || i_codification || ' amount=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_amount);
                INSERT INTO p1_exr_temp
                    (id_exr_temp,
                     id_external_request,
                     id_intervention,
                     id_interv_presc_det,
                     id_institution,
                     flg_priority,
                     flg_home,
                     id_codification,
                     amount,
                     reason,
                     complementary_information)
                VALUES
                    (seq_p1_exr_temp.nextval,
                     l_exr.id_external_request,
                     i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt),
                     i_flg_priority_home(i) (1),
                     i_flg_priority_home(i) (2),
                     i_codification,
                     i_mcdt(i) (pk_ref_constant.g_idx_amount),
                     l_reason,
                     l_complementary_information);
            
            ELSIF i_flg_type = pk_ref_constant.g_p1_type_f
            THEN
            
                g_error := 'insert p1_exr_temp / id_intervention=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_mcdt) || ' id_rehab_presc=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_req_det) || ' id_institution=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_id_inst_dest_mcdt) || ' flg_priority=' || i_flg_priority_home(i)
                           (1) || ' flg_home=' || i_flg_priority_home(i)
                           (2) || ' id_codification=' || i_codification || ' amount=' || i_mcdt(i)
                           (pk_ref_constant.g_idx_amount);
                INSERT INTO p1_exr_temp
                    (id_exr_temp,
                     id_external_request,
                     id_intervention,
                     id_rehab_presc,
                     id_institution,
                     flg_priority,
                     flg_home,
                     id_codification,
                     amount,
                     reason,
                     complementary_information)
                VALUES
                    (seq_p1_exr_temp.nextval,
                     l_exr.id_external_request,
                     i_mcdt(i) (pk_ref_constant.g_idx_id_mcdt),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                     i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt),
                     i_flg_priority_home(i) (1),
                     i_flg_priority_home(i) (2),
                     i_codification,
                     i_mcdt(i) (pk_ref_constant.g_idx_amount),
                     l_reason,
                     l_complementary_information);
            
            END IF;
        END LOOP;
    
        g_error                         := 'UPDATE STATUS';
        l_track_row.id_external_request := l_exr.id_external_request;
        l_track_row.ext_req_status      := l_exr.flg_status;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_dep_clin_serv    := l_exr.id_dep_clin_serv;
        l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
    
        g_error  := 'Call pk_p1_core.update_status / ID_REF=' || l_track_row.id_external_request;
        g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_track_row   => l_track_row,
                                             i_old_status  => pk_ref_constant.g_p1_status_n ||
                                                              pk_ref_constant.g_p1_status_o ||
                                                              pk_ref_constant.g_p1_status_g,
                                             i_flg_isencao => NULL,
                                             i_mcdt_nature => NULL,
                                             o_track       => l_track_tab,
                                             o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_track := l_track MULTISET UNION l_track_tab;
    
        g_error  := 'Referral details';
        l_detail := i_detail;
    
        -- adding flg_priority and flg_home to l_detail
        -- i_detail format: [id_detail|flg_type|text|flg|id_group]
        g_error  := 'Call pk_ref_orig_phy.add_flgs_to_detail / ID_REF=' || l_exr.id_external_request ||
                    ' FLG_PRIORITY=' || l_exr.flg_priority || ' FLG_HOME=' || l_exr.flg_home;
        g_retval := pk_ref_orig_phy.add_flgs_to_detail(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_ref       => l_exr.id_external_request,
                                                       i_flg_priority => l_exr.flg_priority,
                                                       i_flg_home     => l_exr.flg_home,
                                                       io_detail_tab  => l_detail,
                                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Inserting details in P1_DETAIL
        g_error  := 'Calling pk_ref_core.set_detail';
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_ext_req       => l_exr.id_external_request,
                                           i_detail        => l_detail,
                                           i_ext_req_track => l_track(1), -- first iteration
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
    
        -- Problems
        IF l_problems.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_problems.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_problems.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error := 'INSERT DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_p; -- Problems
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         desc_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status,
                         year_begin,
                         month_begin,
                         day_begin) -- ALERT-275636
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         l_exr.id_external_request,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_p,
                         pk_ref_constant.g_active,
                         l_exr.year_begin, -- all problems have the same problem begin date
                         l_exr.month_begin,
                         l_exr.day_begin);
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
    
        IF l_diagnoses.epis_diagnosis.tbl_diagnosis IS NOT NULL
           AND l_diagnoses.epis_diagnosis.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. l_diagnoses.epis_diagnosis.tbl_diagnosis.count
            LOOP
                IF l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    g_error := 'INSERT DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_d; -- Diagnosis
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         desc_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status)
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         l_exr.id_external_request,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_d,
                         pk_ref_constant.g_active);
                END IF;
            END LOOP;
        END IF;
    
        g_error  := 'Call pk_ref_orig_phy.create_tasks_done / ID_REF=' || l_exr.id_external_request;
        g_retval := pk_ref_orig_phy.create_tasks_done(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_ext_req  => l_exr.id_external_request,
                                                      i_id_tasks => i_id_tasks,
                                                      i_id_info  => i_id_info,
                                                      o_error    => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- JS: 2007-DEZ-17: Issuing referral
        IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
        THEN
        
            g_error  := 'Call issue_request / ID_REF=' || l_exr.id_external_request;
            g_retval := pk_p1_core.issue_request(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_ext_req => l_exr.id_external_request,
                                                 o_track   => l_track_tab,
                                                 o_error   => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_track := l_track MULTISET UNION l_track_tab;
        
        END IF;
    
        g_error := 'l_id_external_request(1)=' || l_exr.id_external_request;
        l_id_external_request(1) := l_exr.id_external_request;
    
        IF i_completed = pk_ref_constant.g_yes
        THEN
            g_error  := 'Calling split_mcdt_request_by_group / ID_EXT_REQ=' || l_exr.id_external_request || '|ID_PAT=' ||
                        l_exr.id_patient || '|ID_EPISODE=' || i_id_episode || '|ID_CODIFICATION=' || i_codification;
            g_retval := split_mcdt_request_by_group(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_exr                 => l_exr.id_external_request,
                                                    i_id_patient          => i_id_patient,
                                                    i_id_episode          => i_id_episode,
                                                    i_type                => pk_ref_constant.g_rep_mode_a, -- Application
                                                    i_num_req             => NULL,
                                                    i_id_report           => NULL,
                                                    i_id_ref_completion   => NULL,
                                                    i_flg_isencao         => NULL,
                                                    o_id_external_request => l_id_external_request,
                                                    o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        o_id_external_request := l_id_external_request;
    
        g_error := 'i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode;
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => i_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => NULL,
                                          o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_create_msg, i_prof => i_prof),
               pk_ref_constant.g_no) = pk_ref_constant.g_yes
           AND l_exr.flg_status != pk_ref_constant.g_p1_status_o
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t003);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        
        ELSIF nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_temp_msg, i_prof => i_prof),
                  pk_ref_constant.g_no) = pk_ref_constant.g_yes
              AND l_exr.flg_status = pk_ref_constant.g_p1_status_o
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
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_EXTERNAL_REQUEST_MCDT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_external_request_mcdt;

    /**
    * Update mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_id_episode          Episode identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]* @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION update_external_request_mcdt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems                  IN CLOB,
        i_dt_problem_begin          IN VARCHAR2,
        i_detail                    IN table_table_varchar,
        i_diagnosis                 IN CLOB,
        i_completed                 IN VARCHAR2,
        i_id_tasks                  IN table_table_number,
        i_id_info                   IN table_table_number,
        i_codification              IN codification.id_codification%TYPE,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_consent                   IN VARCHAR2,
        i_health_plan               IN table_number DEFAULT NULL,
        i_exemption                 IN table_number DEFAULT NULL,
        i_reason                    IN table_varchar DEFAULT NULL,
        i_complementary_information IN table_varchar DEFAULT NULL,
        i_id_fam_rel                IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec              IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel            IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel           IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel             IN VARCHAR2 DEFAULT NULL,
        o_id_external_request       OUT table_number,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr                       p1_external_request%ROWTYPE;
        l_req                       p1_external_request%ROWTYPE;
        l_track_row                 p1_tracking%ROWTYPE;
        l_id_external_request       table_number := table_number(NULL);
        l_rowids                    table_varchar;
        l_mcdt_req_det              table_number := table_number();
        l_mcdt_remove               table_number := table_number();
        l_flg_referral              VARCHAR2(1 CHAR);
        l_detail                    table_table_varchar;
        l_year_begin                p1_external_request.year_begin%TYPE;
        l_month_begin               p1_external_request.month_begin%TYPE;
        l_day_begin                 p1_external_request.day_begin%TYPE;
        l_flg_laterality            VARCHAR2(1 CHAR);
        l_params                    VARCHAR2(1000 CHAR);
        l_track                     table_number;
        l_track_tab                 table_number;
        l_reason                    VARCHAR2(1000 CHAR);
        l_complementary_information VARCHAR2(1000 CHAR);
    
        l_problems  pk_edis_types.rec_in_epis_diagnoses;
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    
        l_id_pat_health_plan NUMBER(24);
        l_id_pat_exemption   NUMBER(24);
        l_rows_out           table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ext_req=' || i_ext_req || ' i_dt_modified=' ||
                    i_dt_modified || ' i_id_episode=' || i_id_episode || ' i_req_type=' || i_req_type || ' i_flg_type=' ||
                    i_flg_type || ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' || i_completed ||
                    ' i_codification=' || i_codification;
    
        g_error        := 'Init update_external_request_mcdt / ' || l_params;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
        l_track        := table_number();
    
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_req,
                                                       o_error  => o_error);
    
        g_error := 'REQUEST EXISTS / ID_REF=' || i_ext_req;
        IF l_req.id_external_request IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' ID_WF=' || l_req.id_workflow || ' FLG_STATUS=' || l_req.flg_status || ' FLG_TYPE=' ||
                    l_req.flg_type;
    
        g_error := 'CHECK ARRAYS EMPTY / ' || l_params;
        IF i_mcdt.count = 0
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CHECK ARRAYS SIZE / ' || l_params;
        IF (i_mcdt.count != i_flg_priority_home.count)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'EXTEND(' || i_mcdt.count || ') / ' || l_params;
        l_mcdt_req_det.extend(i_mcdt.count);
    
        FOR i IN 1 .. i_mcdt.count
        LOOP
            l_mcdt_req_det(i) := i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
        END LOOP;
    
        g_error := 'i_completed=' || i_completed || ' / ' || l_params;
        IF i_completed = pk_ref_constant.g_yes
        THEN
            CASE l_req.flg_status
            
                WHEN pk_ref_constant.g_p1_status_o THEN
                
                    g_error  := 'Calling get_status_mcdt / ' || l_params;
                    g_retval := get_status_mcdt(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_flg_type     => i_flg_type,
                                                i_mcdt_req_det => l_mcdt_req_det,
                                                o_flg_status   => l_exr.flg_status,
                                                o_error        => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    --  remove temporary data from p1_exr_temp
                    g_error := 'DELETE FROM p1_exr_temp / ' || i_ext_req || ' / ' || l_params;
                    /*DELETE FROM p1_exr_temp pet
                    WHERE pet.id_external_request = i_ext_req;*/
            
                WHEN pk_ref_constant.g_p1_status_g THEN
                
                    g_error  := 'Calling get_status_mcdt / ' || l_params;
                    g_retval := get_status_mcdt(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_flg_type     => i_flg_type,
                                                i_mcdt_req_det => l_mcdt_req_det,
                                                o_flg_status   => l_exr.flg_status,
                                                o_error        => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    END IF;
                
                WHEN pk_ref_constant.g_p1_status_d THEN
                
                    l_exr.flg_status := pk_ref_constant.g_p1_status_n;
                
                    IF pk_date_utils.trunc_insttimezone(i_prof, l_req.dt_last_interaction_tstz, 'SS') !=
                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
                    THEN
                        o_msg_title      := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'P1_DOCTOR_CS_T075');
                        o_msg            := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'P1_DOCTOR_CS_T076');
                        o_flg_show       := pk_ref_constant.g_yes;
                        o_button         := 'R';
                        l_exr.flg_status := l_req.flg_status; -- JS: 2007-04-18, If referral is changed while editing, professional is notified and the state is not changed
                    ELSE
                        l_exr.flg_status := pk_ref_constant.g_p1_status_n;
                    END IF;
                
                ELSE
                    l_exr.flg_status := l_req.flg_status; -- In other cases the referral status remains the same
            END CASE;
        
            g_error := 'FLG_REFERRAL / ' || l_params;
            IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
            THEN
                l_flg_referral := pk_ref_constant.g_flg_referral_i;
            ELSE
                l_flg_referral := pk_ref_constant.g_flg_referral_r;
            END IF;
        
        ELSE
            l_exr.flg_status := l_req.flg_status; -- If not completed, the status does not change
            l_flg_referral   := pk_ref_constant.g_flg_referral_r;
        END IF;
    
        -- removing mcdts
        g_error := 'FLG_TYPE=' || i_flg_type || ' / ' || l_params;
        IF i_flg_type = pk_ref_constant.g_p1_type_a
        THEN
        
            g_error := 'REMOVING id_analysis_req_det / ' || l_params;
            DELETE FROM p1_exr_temp p
             WHERE p.id_external_request = i_ext_req
               AND p.id_analysis_req_det NOT IN
                   (SELECT column_value
                      FROM TABLE(CAST(l_mcdt_req_det AS table_number)))
            RETURNING id_analysis_req_det BULK COLLECT INTO l_mcdt_remove;
        
        ELSIF i_flg_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e)
        THEN
            g_error := 'REMOVING id_exam_req_det / ' || l_params;
            DELETE FROM p1_exr_temp p
             WHERE p.id_external_request = i_ext_req
               AND p.id_exam_req_det NOT IN
                   (SELECT column_value
                      FROM TABLE(CAST(l_mcdt_req_det AS table_number)))
            RETURNING id_exam_req_det BULK COLLECT INTO l_mcdt_remove;
        
        ELSIF i_flg_type = pk_ref_constant.g_p1_type_p
        THEN
            g_error := 'REMOVING id_interv_req_det / ' || l_params;
            DELETE FROM p1_exr_temp p
             WHERE p.id_external_request = i_ext_req
               AND p.id_interv_presc_det NOT IN
                   (SELECT column_value
                      FROM TABLE(CAST(l_mcdt_req_det AS table_number)))
            RETURNING id_interv_presc_det BULK COLLECT INTO l_mcdt_remove;
        
        ELSIF i_flg_type = pk_ref_constant.g_p1_type_f
        THEN
            g_error := 'REMOVING id_rehab_presc / ' || l_params;
            DELETE FROM p1_exr_temp p
             WHERE p.id_external_request = i_ext_req
               AND p.id_rehab_presc NOT IN (SELECT column_value
                                              FROM TABLE(CAST(l_mcdt_req_det AS table_number)))
            RETURNING id_rehab_presc BULK COLLECT INTO l_mcdt_remove;
        END IF;
    
        g_error := 'Updating FLG_REFERRAL / l_mcdt_remove.COUNT=' || l_mcdt_remove.count || ' / ' || l_params;
        FOR i IN 1 .. l_mcdt_remove.count
        LOOP
            g_error  := 'Calling update_flg_referral / ID_REQ_DET=' || l_mcdt_remove(i) || ' / ' || l_params;
            g_retval := update_flg_referral(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_exr            => i_ext_req,
                                            i_id_episode     => i_id_episode,
                                            i_req_det        => l_mcdt_remove(i),
                                            i_type           => i_flg_type,
                                            i_status         => pk_ref_constant.g_flg_referral_a, -- available again
                                            i_inst_dest      => NULL,
                                            i_flg_laterality => NULL,
                                            o_error          => o_error);
        
            IF NOT g_retval
            THEN
                g_error := g_error || ' / error / ID_EXT_REQ=' || i_ext_req || '|ID_EPISODE=' || i_id_episode ||
                           '|ID_REQ_DET=' || l_mcdt_remove(i) || '|FLG_REFERRAL=' || pk_ref_constant.g_flg_referral_a ||
                           '|FLG_TYPE=' || i_flg_type;
                RAISE g_exception_np;
            END IF;
        
        END LOOP;
    
        g_error := 'i_mcdt.count=' || i_mcdt.count || ' / ' || l_params;
        FOR i IN 1 .. i_mcdt.count
        LOOP
            g_error := 'l_flg_laterality';
            IF i_flg_laterality IS NOT NULL
            THEN
                l_flg_laterality := i_flg_laterality(i);
            ELSE
                l_flg_laterality := NULL;
            END IF;
        
            g_error := 'l_reason';
            IF i_reason.exists(i)
            THEN
                l_reason := i_reason(i);
            ELSE
                l_reason := NULL;
            END IF;
        
            g_error := 'l_complementary_information';
            IF i_complementary_information.exists(i)
            THEN
                l_complementary_information := i_complementary_information(i);
            ELSE
                l_complementary_information := NULL;
            END IF;
        
            -- Actualizar analysis_req_det.flg_referral
            IF i_mcdt(i) (pk_ref_constant.g_idx_id_req_det) IS NOT NULL
            THEN
            
                g_error  := 'Call update_flg_referral / ID_REQ_DET=' || i_mcdt(i)
                            (pk_ref_constant.g_idx_id_req_det) || ' FLG_REFERRAL=' || l_flg_referral ||
                            ' ID_INST_DEST=' || i_mcdt(i)
                            (pk_ref_constant.g_idx_id_inst_dest_mcdt) || ' / ' || l_params;
                g_retval := update_flg_referral(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_exr            => i_ext_req,
                                                i_id_episode     => i_id_episode,
                                                i_req_det        => i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                                                i_type           => i_flg_type,
                                                i_status         => l_flg_referral,
                                                i_inst_dest      => i_mcdt(i) (pk_ref_constant.g_idx_id_inst_dest_mcdt),
                                                i_flg_laterality => l_flg_laterality,
                                                o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        
            IF i_flg_type = pk_ref_constant.g_p1_type_a
            THEN
            
                g_error := 'merge p1_exr_temp ' || i_flg_type || ' / ' || l_params;
                MERGE INTO p1_exr_temp et
                USING (SELECT i_ext_req id_exr,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) id_mcdt,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) id_mcdt_req_det,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_inst_dest_mcdt) id_institution,
                              i_flg_priority_home(i)(1) flg_priority,
                              i_flg_priority_home(i)(2) flg_home,
                              i_codification id_codification,
                              i_mcdt(i)(pk_ref_constant.g_idx_amount) amount,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_sample_type) id_sample_type,
                              l_reason reason,
                              l_complementary_information complementary_information
                         FROM dual) t
                ON (et.id_external_request = t.id_exr AND et.id_analysis = t.id_mcdt AND et.id_sample_type = t.id_sample_type AND et.id_analysis_req_det = id_mcdt_req_det)
                WHEN MATCHED THEN
                    UPDATE
                       SET id_institution            = t.id_institution,
                           flg_priority              = t.flg_priority,
                           flg_home                  = t.flg_home,
                           amount                    = t.amount,
                           reason                    = t.reason,
                           complementary_information = t.complementary_information
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_exr_temp,
                         id_external_request,
                         id_analysis,
                         id_analysis_req_det,
                         id_institution,
                         flg_priority,
                         flg_home,
                         id_codification,
                         amount,
                         id_sample_type,
                         reason,
                         complementary_information)
                    VALUES
                        (seq_p1_exr_temp.nextval,
                         t.id_exr,
                         t.id_mcdt,
                         t.id_mcdt_req_det,
                         t.id_institution,
                         t.flg_priority,
                         t.flg_home,
                         t.id_codification,
                         t.amount,
                         t.id_sample_type,
                         t.reason,
                         t.complementary_information);
            
                --Health plan   
                BEGIN
                    SELECT ard.id_pat_health_plan, ard.id_pat_exemption
                      INTO l_id_pat_health_plan, l_id_pat_exemption
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req_det = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_pat_health_plan := NULL;
                        l_id_pat_exemption   := NULL;
                END;
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_analysis_req_det.upd(id_analysis_req_det_in => i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                                                id_pat_health_plan_in  => i_health_plan(i),
                                                id_pat_health_plan_nin => FALSE,
                                                id_pat_exemption_in    => i_exemption(i),
                                                id_pat_exemption_nin   => FALSE,
                                                handle_error_in        => TRUE,
                                                rows_out               => l_rows_out);
                    END IF;
                END IF;
            
            ELSIF i_flg_type IN (pk_ref_constant.g_p1_type_i, pk_ref_constant.g_p1_type_e)
            THEN
                g_error := 'merge p1_exr_temp ' || i_flg_type || ' / ' || l_params;
                MERGE INTO p1_exr_temp et
                USING (SELECT i_ext_req id_exr,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) id_mcdt,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) id_mcdt_req_det,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_inst_dest_mcdt) id_institution,
                              i_flg_priority_home(i)(1) flg_priority,
                              i_flg_priority_home(i)(2) flg_home,
                              i_codification id_codification,
                              i_mcdt(i)(pk_ref_constant.g_idx_amount) amount,
                              l_reason reason,
                              l_complementary_information complementary_information
                         FROM dual) t
                ON (et.id_external_request = t.id_exr AND et.id_exam = t.id_mcdt AND et.id_exam_req_det = id_mcdt_req_det)
                WHEN MATCHED THEN
                    UPDATE
                       SET id_institution            = t.id_institution,
                           flg_priority              = t.flg_priority,
                           flg_home                  = t.flg_home,
                           amount                    = t.amount,
                           reason                    = t.reason,
                           complementary_information = t.complementary_information
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_exr_temp,
                         id_external_request,
                         id_exam,
                         id_exam_req_det,
                         id_institution,
                         flg_priority,
                         flg_home,
                         id_codification,
                         amount,
                         reason,
                         complementary_information)
                    VALUES
                        (seq_p1_exr_temp.nextval,
                         t.id_exr,
                         t.id_mcdt,
                         t.id_mcdt_req_det,
                         t.id_institution,
                         t.flg_priority,
                         t.flg_home,
                         t.id_codification,
                         t.amount,
                         t.reason,
                         t.complementary_information);
            
                --Health plan   
                BEGIN
                    SELECT erd.id_pat_health_plan, erd.id_pat_exemption
                      INTO l_id_pat_health_plan, l_id_pat_exemption
                      FROM exam_req_det erd
                     WHERE erd.id_exam_req_det = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_pat_health_plan := NULL;
                        l_id_pat_exemption   := NULL;
                END;
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_exam_req_det.upd(id_exam_req_det_in     => i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                                            id_pat_health_plan_in  => i_health_plan(i),
                                            id_pat_health_plan_nin => FALSE,
                                            id_pat_exemption_in    => i_exemption(i),
                                            id_pat_exemption_nin   => FALSE,
                                            handle_error_in        => TRUE,
                                            rows_out               => l_rows_out);
                    END IF;
                END IF;
            
            ELSIF i_flg_type = pk_ref_constant.g_p1_type_p
            THEN
                g_error := 'merge p1_exr_temp ' || i_flg_type || ' / ' || l_params;
                MERGE INTO p1_exr_temp et
                USING (SELECT i_ext_req id_exr,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) id_mcdt,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) id_mcdt_req_det,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_inst_dest_mcdt) id_institution,
                              i_flg_priority_home(i)(1) flg_priority,
                              i_flg_priority_home(i)(2) flg_home,
                              i_codification id_codification,
                              i_mcdt(i)(pk_ref_constant.g_idx_amount) amount,
                              l_reason reason,
                              l_complementary_information complementary_information
                         FROM dual) t
                ON (et.id_external_request = t.id_exr AND et.id_intervention = t.id_mcdt AND et.id_interv_presc_det = id_mcdt_req_det)
                WHEN MATCHED THEN
                    UPDATE
                       SET id_institution            = t.id_institution,
                           flg_priority              = t.flg_priority,
                           flg_home                  = t.flg_home,
                           amount                    = t.amount,
                           reason                    = t.reason,
                           complementary_information = t.complementary_information
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_exr_temp,
                         id_external_request,
                         id_intervention,
                         id_interv_presc_det,
                         id_institution,
                         flg_priority,
                         flg_home,
                         id_codification,
                         amount,
                         reason,
                         complementary_information)
                    VALUES
                        (seq_p1_exr_temp.nextval,
                         t.id_exr,
                         t.id_mcdt,
                         t.id_mcdt_req_det,
                         t.id_institution,
                         t.flg_priority,
                         t.flg_home,
                         t.id_codification,
                         t.amount,
                         t.reason,
                         t.complementary_information);
                --Health plan   
                BEGIN
                    SELECT ipd.id_pat_health_plan, ipd.id_pat_exemption
                      INTO l_id_pat_health_plan, l_id_pat_exemption
                      FROM interv_presc_det ipd
                     WHERE ipd.id_interv_presc_det = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_pat_health_plan := NULL;
                        l_id_pat_exemption   := NULL;
                END;
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_interv_presc_det.upd(id_interv_presc_det_in => i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                                                id_pat_health_plan_in  => i_health_plan(i),
                                                id_pat_health_plan_nin => FALSE,
                                                id_pat_exemption_in    => i_exemption(i),
                                                id_pat_exemption_nin   => FALSE,
                                                handle_error_in        => TRUE,
                                                rows_out               => l_rows_out);
                    END IF;
                END IF;
            
            ELSIF i_flg_type = pk_ref_constant.g_p1_type_f
            THEN
                g_error := 'merge p1_exr_temp ' || i_flg_type || ' / ' || l_params;
                MERGE INTO p1_exr_temp et
                USING (SELECT i_ext_req id_exr,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_mcdt) id_mcdt,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_req_det) id_mcdt_req_det,
                              i_mcdt(i)(pk_ref_constant.g_idx_id_inst_dest_mcdt) id_institution,
                              i_flg_priority_home(i)(1) flg_priority,
                              i_flg_priority_home(i)(2) flg_home,
                              i_codification id_codification,
                              i_mcdt(i)(pk_ref_constant.g_idx_amount) amount,
                              l_reason reason,
                              l_complementary_information complementary_information
                         FROM dual) t
                ON (et.id_external_request = t.id_exr AND et.id_intervention = t.id_mcdt AND et.id_rehab_presc = id_mcdt_req_det)
                WHEN MATCHED THEN
                    UPDATE
                       SET id_institution            = t.id_institution,
                           flg_priority              = t.flg_priority,
                           flg_home                  = t.flg_home,
                           amount                    = t.amount,
                           reason                    = t.reason,
                           complementary_information = t.complementary_information
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_exr_temp,
                         id_external_request,
                         id_intervention,
                         id_rehab_presc,
                         id_institution,
                         flg_priority,
                         flg_home,
                         id_codification,
                         amount,
                         reason,
                         complementary_information)
                    VALUES
                        (seq_p1_exr_temp.nextval,
                         t.id_exr,
                         t.id_mcdt,
                         t.id_mcdt_req_det,
                         t.id_institution,
                         t.flg_priority,
                         t.flg_home,
                         t.id_codification,
                         t.amount,
                         t.reason,
                         t.complementary_information);
            
                --Health plan   
                BEGIN
                    SELECT rp.id_pat_health_plan, rp.id_pat_exemption
                      INTO l_id_pat_health_plan, l_id_pat_exemption
                      FROM rehab_presc rp
                     WHERE rp.id_rehab_presc = i_mcdt(i) (pk_ref_constant.g_idx_id_req_det);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_pat_health_plan := NULL;
                        l_id_pat_exemption   := NULL;
                END;
            
                IF i_health_plan.exists(i)
                   AND i_exemption.exists(i)
                THEN
                    IF i_health_plan(i) <> l_id_pat_health_plan
                       OR (i_health_plan(i) IS NULL AND l_id_pat_health_plan IS NOT NULL)
                       OR (i_health_plan(i) IS NOT NULL AND l_id_pat_health_plan IS NULL)
                       OR i_exemption(i) <> l_id_pat_exemption
                       OR (i_exemption(i) IS NULL AND l_id_pat_exemption IS NOT NULL)
                       OR (i_exemption(i) IS NOT NULL AND l_id_pat_exemption IS NULL)
                    THEN
                        ts_rehab_presc.upd(id_rehab_presc_in      => i_mcdt(i) (pk_ref_constant.g_idx_id_req_det),
                                           id_pat_health_plan_in  => i_health_plan(i),
                                           id_pat_health_plan_nin => FALSE,
                                           id_pat_exemption_in    => i_exemption(i),
                                           id_pat_exemption_nin   => FALSE,
                                           handle_error_in        => TRUE,
                                           rows_out               => l_rows_out);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        -- ALERT-194568: problem begin date
        g_error  := 'Call pk_ref_utils.parse_dt_str / ID_REF=' || l_exr.id_external_request;
        g_retval := pk_ref_utils.parse_dt_str(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_dt_str_flash => i_dt_problem_begin,
                                              o_year         => l_year_begin,
                                              o_month        => l_month_begin,
                                              o_day          => l_day_begin,
                                              o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call  ts_p1_external_request.upd / ' || l_params;
        ts_p1_external_request.upd(id_external_request_in        => i_ext_req,
                                   req_type_in                   => i_req_type,
                                   flg_type_in                   => i_flg_type,
                                   flg_priority_in               => pk_ref_orig_phy.get_priority_home(i_lang,
                                                                                                      i_flg_priority_home,
                                                                                                      1),
                                   flg_home_in                   => pk_ref_orig_phy.get_priority_home(i_lang,
                                                                                                      i_flg_priority_home,
                                                                                                      2),
                                   id_prof_status_in             => i_prof.id,
                                   id_prof_requested_in          => i_prof.id,
                                   year_begin_in                 => l_year_begin,
                                   year_begin_nin                => FALSE,
                                   month_begin_in                => l_month_begin,
                                   month_begin_nin               => FALSE,
                                   day_begin_in                  => l_day_begin,
                                   day_begin_nin                 => FALSE,
                                   dt_last_interaction_tstz_in   => g_sysdate_tstz,
                                   id_fam_rel_in                 => i_id_fam_rel,
                                   id_fam_rel_nin                => FALSE,
                                   name_first_rel_in             => i_name_first_rel,
                                   name_first_rel_nin            => FALSE,
                                   name_middle_rel_in            => i_name_middle_rel,
                                   name_middle_rel_nin           => FALSE,
                                   name_last_rel_in              => i_name_last_rel,
                                   name_last_rel_nin             => FALSE,
                                   consent_in                    => i_consent,
                                   id_pat_health_plan_in         => CASE
                                                                        WHEN i_health_plan IS NULL THEN
                                                                         NULL
                                                                        ELSE
                                                                         i_health_plan(1)
                                                                    END,
                                   id_pat_health_plan_nin        => FALSE,
                                   id_pat_exemption_in           => CASE
                                                                        WHEN i_health_plan IS NULL THEN
                                                                         NULL
                                                                        ELSE
                                                                         i_exemption(1)
                                                                    END,
                                   id_pat_exemption_nin          => FALSE,
                                   family_relationship_notes_in  => i_fam_rel_spec,
                                   family_relationship_notes_nin => FALSE,
                                   rows_out                      => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'Call pk_ref_orig_phy.create_tasks_done / ' || l_params;
        g_retval := pk_ref_orig_phy.create_tasks_done(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_ext_req  => i_ext_req,
                                                      i_id_tasks => i_id_tasks,
                                                      i_id_info  => i_id_info,
                                                      --i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                      o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'l_exr.flg_status=' || l_exr.flg_status || ' l_req.flg_status=' || l_req.flg_status || ' / ' ||
                   l_params;
        IF l_exr.flg_status != l_req.flg_status
        THEN
            g_error                         := 'UPDATE STATUS S / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := l_exr.flg_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
            l_track_row.id_dep_clin_serv    := l_exr.id_dep_clin_serv;
            l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_o ||
                                                                  pk_ref_constant.g_p1_status_d ||
                                                                  pk_ref_constant.g_p1_status_g,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => l_track_tab,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_track := l_track MULTISET UNION l_track_tab;
        
            -- JS: 2007-DEZ-17: Issuing referral 
            IF l_exr.flg_status = pk_ref_constant.g_p1_status_n
            THEN
            
                g_error  := 'Call pk_p1_core.issue_request / ' || l_params;
                g_retval := pk_p1_core.issue_request(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_ext_req => i_ext_req,
                                                     --i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                     o_track => l_track_tab,
                                                     o_error => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_track := l_track MULTISET UNION l_track_tab;
            
            END IF;
        
            g_error := 'i_completed=' || i_completed || ' / ' || l_params;
            IF i_completed = pk_ref_constant.g_yes
            THEN
            
                g_error  := 'Calling split_mcdt_request_by_group / ID_PAT=' || l_exr.id_patient || ' / ' || l_params;
                g_retval := split_mcdt_request_by_group(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_exr                 => i_ext_req,
                                                        i_id_patient          => l_exr.id_patient,
                                                        i_id_episode          => i_id_episode,
                                                        i_type                => pk_ref_constant.g_rep_mode_a, -- Application
                                                        i_num_req             => NULL,
                                                        i_id_report           => NULL,
                                                        i_id_ref_completion   => NULL,
                                                        i_flg_isencao         => NULL,
                                                        o_id_external_request => l_id_external_request,
                                                        o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        ELSE
            -- JS: 10-04-2007 In other cases register an update
            g_error                         := 'UPDATE STATUS U / ' || l_params;
            l_track_row.id_external_request := i_ext_req;
            l_track_row.ext_req_status      := l_exr.flg_status;
            l_track_row.flg_type            := pk_ref_constant.g_tracking_type_u;
            l_track_row.id_dep_clin_serv    := l_exr.id_dep_clin_serv;
            l_track_row.dt_tracking_tstz    := NULL;
        
            g_error  := 'Call pk_p1_core.update_status / ' || l_params;
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => pk_ref_constant.g_p1_status_n ||
                                                                  pk_ref_constant.g_p1_status_o ||
                                                                  pk_ref_constant.g_p1_status_d ||
                                                                  pk_ref_constant.g_p1_status_i ||
                                                                  pk_ref_constant.g_p1_status_b ||
                                                                  pk_ref_constant.g_p1_status_t ||
                                                                  pk_ref_constant.g_p1_status_r,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => l_track_tab,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_track := l_track MULTISET UNION l_track_tab;
        
        END IF;
    
        g_error  := 'Referral details / ' || i_detail.count || ' / ' || l_params;
        l_detail := i_detail;
    
        -- adding flg_priority and flg_home to l_detail. i_detail format: [id_detail|flg_type|text|flg|id_group]
        g_error  := 'Call pk_ref_orig_phy.add_flgs_to_detail / FLG_PRIORITY=' || l_exr.flg_priority || ' FLG_HOME=' ||
                    l_exr.flg_home || ' / ' || l_params;
        g_retval := pk_ref_orig_phy.add_flgs_to_detail(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_ref       => l_req.id_external_request,
                                                       i_flg_priority => l_req.flg_priority,
                                                       i_flg_home     => l_req.flg_home,
                                                       io_detail_tab  => l_detail,
                                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Updating details
        g_error  := 'Calling pk_ref_core.set_detail / ' || l_params;
        g_retval := pk_ref_core.set_detail(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_ext_req       => i_ext_req,
                                           i_detail        => l_detail,
                                           i_ext_req_track => l_track(1), -- first iteration
                                           i_date          => g_sysdate_tstz,
                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- JS: 2007-04-13, Canceling problems (instead of removing)
        g_error := 'UPDATE DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_p || ' / ' || l_params;
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = i_ext_req
           AND flg_type = pk_ref_constant.g_exr_diag_type_p
           AND flg_status = pk_ref_constant.g_active;
    
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
                    g_error := 'INSERT DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_p; -- Problems
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         desc_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status,
                         year_begin,
                         month_begin,
                         day_begin) -- ALERT-275636
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         i_ext_req,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         l_problems.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_p,
                         pk_ref_constant.g_active,
                         l_year_begin, -- all problems have the same problem begin date
                         l_month_begin,
                         l_day_begin);
                END IF;
            END LOOP;
        END IF;
    
        -- JS: 2007-04-13, Canceling diagnosis (instead of removing)
        g_error := 'UPDATE DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_d || ' / ' || l_params;
        UPDATE p1_exr_diagnosis
           SET flg_status = pk_ref_constant.g_cancelled
         WHERE id_external_request = i_ext_req
           AND flg_type = pk_ref_constant.g_exr_diag_type_d
           AND flg_status = pk_ref_constant.g_active;
    
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
                    g_error := 'INSERT DIAGNOSIS ' || pk_ref_constant.g_exr_diag_type_d; -- Diagnosis
                    INSERT INTO p1_exr_diagnosis
                        (id_exr_diagnosis,
                         id_external_request,
                         id_diagnosis,
                         id_alert_diagnosis,
                         desc_diagnosis,
                         dt_insert_tstz,
                         id_professional,
                         id_institution,
                         flg_type,
                         flg_status)
                    VALUES
                        (seq_p1_exr_diagnosis.nextval,
                         i_ext_req,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).id_alert_diagnosis,
                         l_diagnoses.epis_diagnosis.tbl_diagnosis(i).desc_diagnosis,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_prof.institution,
                         pk_ref_constant.g_exr_diag_type_d,
                         pk_ref_constant.g_active);
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'GET EXTERNAL REQUESTS / ' || l_params;
        l_id_external_request(1) := i_ext_req;
        o_id_external_request := l_id_external_request;
    
        IF i_id_episode IS NOT NULL
        THEN
            g_error  := 'Calling pk_visit.set_first_obs / ID_PATIENT=' || l_exr.id_patient || ' / ' || l_params;
            g_retval := pk_visit.set_first_obs(i_lang                => i_lang,
                                               i_id_episode          => i_id_episode,
                                               i_pat                 => l_exr.id_patient,
                                               i_prof                => i_prof,
                                               i_prof_cat_type       => NULL,
                                               i_dt_last_interaction => g_sysdate_tstz,
                                               i_dt_first_obs        => NULL,
                                               o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        IF l_exr.flg_status != l_req.flg_status
           AND l_req.flg_status = pk_ref_constant.g_p1_status_o
        THEN
            -- set print list job as canceled (if exists in printing list)
            g_error  := 'Call pk_ref_ext_sys.set_print_jobs_cancel / ' || l_params;
            g_retval := pk_ref_ext_sys.set_print_jobs_cancel(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_patient => l_exr.id_patient,
                                                             i_id_episode => l_exr.id_episode,
                                                             i_id_ref     => l_exr.id_external_request,
                                                             o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error := 'l_exr.flg_status=' || l_exr.flg_status || ' / ' || l_params;
        IF nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_create_msg, i_prof => i_prof),
               pk_ref_constant.g_no) = pk_ref_constant.g_yes
           AND l_exr.flg_status != pk_ref_constant.g_p1_status_o
        THEN
            o_flg_show  := pk_ref_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_helpsave_w);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => pk_ref_constant.g_sm_ref_common_t003);
            o_button    := pk_ref_constant.g_c_green_check_icon;
        
        ELSIF nvl(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_temp_msg, i_prof => i_prof),
                  pk_ref_constant.g_no) = pk_ref_constant.g_yes
              AND l_exr.flg_status = pk_ref_constant.g_p1_status_o
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
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_EXTERNAL_REQUEST_MCDT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_external_request_mcdt;

    /***********************************************************************************************************
    FUNCTION NAME: GET_P1_NUM_REQ
    FUNCTION GOAL: RETURNS NEXT CODE_NUMBER FOR P1_EXTERNAL_REQUEST
    RETURN:      : VARCHAR2.
    
    
    PARAMETERS NAME         TYPE            DESCRIPTION
    I_LANG                NUMBER            ID OF CURRENT LANGUAGE
    I_ID_INST                       PROFISSIONAL    ID OF INSTITUITION
    O_ERROR                VARCHAR2        ERROR MESSAGE WHEN APPLICABLE.
    *************************************************************************************************************/
    FUNCTION get_p1_num_req(i_inst IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'Init get_p1_num_req';
        RETURN pk_ref_orig_phy.get_ref_num_req(i_inst => i_inst);
    
    END get_p1_num_req;

    /*******************************************************************************
       OBJECTIVO:   Obter tipos de pedidos: Consulta, an lises, exames ou procedimento
       PARAMETROS:  Entrada: I_LANG - L¡ngua registada como prefer¿ncia do profissional
    
                    Saida:   O_METHODS - lista de tipos disponiveis
                             O_ERROR - erro
    
      CRIA¿ÇO: JS
      NOTAS:
    *******************************************************************************/
    FUNCTION get_request_methods
    (
        i_lang    IN language.id_language%TYPE,
        o_methods OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_methods FOR
            SELECT desc_val label, val data
              FROM sys_domain s
             WHERE code_domain = 'P1_FLG_REQUEST_METHOD'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = 'Y'
               AND id_language = i_lang;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST_METHODS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_methods);
            RETURN FALSE;
    END;

    /**
    * Cancel referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_ext_req        Referral id    
    * @param   i_id_patient     Patient id
    * @param   i_id_episode     Episode id        
    * @param   i_notes          Cancelation notes    
    * @param   i_reason         Cancelation reason code    
    * @param   i_transaction_id Scheduler 3.0 id
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_external_request_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_mcdts          IN table_number,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason         IN p1_reason_code.id_reason_code%TYPE,
        i_transaction_id IN VARCHAR2,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exam_req IS
            SELECT ROWID
              FROM exam_req_det
             WHERE id_exam_req_det IN (SELECT id_exam_req_det
                                         FROM p1_exr_exam
                                        WHERE id_external_request = i_ext_req
                                       UNION ALL
                                       SELECT id_exam_req_det
                                         FROM p1_exr_temp pt
                                        WHERE id_external_request = i_ext_req);
        TYPE l_t_analysis_req_det_row IS TABLE OF analysis_req_det%ROWTYPE;
        l_analysis_req_det_rows l_t_analysis_req_det_row;
        l_exam_req_det_row      exam_req_det%ROWTYPE;
    
        l_valid_status     VARCHAR2(20 CHAR);
        l_tab_valid_status table_varchar;
    
        l_track_row     p1_tracking%ROWTYPE;
        l_patient       patient.id_patient%TYPE;
        l_prof_cat_type category.flg_type%TYPE;
        l_rows_out      table_varchar := table_varchar();
        l_rowids        table_varchar;
    
        CURSOR c_ref IS
            SELECT flg_status, id_patient, flg_type
              FROM p1_external_request
             WHERE id_external_request = i_ext_req;
    
        l_flg_type   p1_external_request.flg_type%TYPE;
        l_flg_status p1_external_request.flg_status%TYPE;
        l_id_patient p1_external_request.id_patient%TYPE;
    
        l_mcdt_req_det  table_number;
        l_cancel_reason table_number := table_number();
        l_notes_cancel  table_varchar := table_varchar();
    
        l_transaction_id VARCHAR2(4000);
    
        l_bdnp_available      sys_config.value%TYPE;
        l_bdnp_presc_tracking bdnp_presc_tracking%ROWTYPE;
    
        l_notes  p1_detail.text%TYPE;
        l_params VARCHAR2(1000 CHAR);
    
        l_id_reqs table_number := table_number();
    
        l_id_reqs_count NUMBER;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params       := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ext_req=' || i_ext_req || ' i_id_patient=' ||
                          i_id_patient || ' i_id_episode=' || i_id_episode || ' i_reason=' || i_reason;
        g_error        := 'Init cancel_external_request_int / ' || l_params;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
        o_track        := table_number();
    
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                pk_alert_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------        
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION / ' || l_params;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'OPEN c_ref / ' || l_params;
        OPEN c_ref;
        FETCH c_ref
            INTO l_flg_status, l_id_patient, l_flg_type;
        CLOSE c_ref;
    
        g_error            := 'Call pk_p1_core.get_cancel_prev_status / ' || l_params;
        l_tab_valid_status := pk_p1_core.get_cancel_prev_status(i_lang => i_lang, i_prof => i_prof);
        l_valid_status     := pk_utils.concat_table(i_tab => l_tab_valid_status, i_delim => '');
    
        g_error                         := 'UPDATE STATUS / ' || l_params;
        l_track_row.id_external_request := i_ext_req;
        l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_c;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
        l_track_row.id_reason_code      := i_reason;
        l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_c);
    
        g_error := 'Call pk_p1_core.update_status / ' || l_params;
    
        IF i_mcdts IS NOT NULL
           AND i_mcdts.count > 0
        THEN
        
            SELECT coalesce(a.id_analysis_req_det, a.id_exam_req_det, a.id_interv_presc_det, a.id_rehab_presc)
              BULK COLLECT
              INTO l_id_reqs
              FROM p1_exr_temp a
             WHERE a.id_exr_temp IN (SELECT column_value
                                       FROM TABLE(i_mcdts));
        
        END IF;
    
        IF l_id_reqs.count = 0
        THEN
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => l_valid_status,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF pk_prof_utils.get_category(i_lang, i_prof) = pk_ref_constant.g_registrar
        THEN
            l_notes := pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_code_mess => 'REF_ADM_CANCEL_DETAIL') || chr(10) || i_notes;
        ELSE
            l_notes := i_notes;
        END IF;
    
        IF l_id_reqs.count = 0
        THEN
            IF l_notes IS NOT NULL
            THEN
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_ncan || ' / ' || l_params;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_ext_req,
                     l_notes,
                     g_sysdate_tstz,
                     pk_ref_constant.g_detail_type_ncan,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_detail_status_a);
            END IF;
        END IF;
    
        g_error         := 'CALL PK_TOOLS.get_prof_cat / ' || l_params;
        l_prof_cat_type := pk_tools.get_prof_cat(i_prof);
    
        g_error := 'l_flg_type=' || l_flg_type || ' / ' || l_params;
        IF l_flg_type = pk_ref_constant.g_p1_type_a
        THEN
        
            IF l_flg_status = pk_ref_constant.g_p1_status_p
            THEN
            
                -- getting analysis req to cancel
                g_error := 'SELECT id_analysis_req_det FROM ID_REF=' || i_ext_req || ' / ' || l_params;
                SELECT *
                  BULK COLLECT
                  INTO l_mcdt_req_det
                  FROM (SELECT ard.id_analysis_req_det
                          FROM analysis_req_det ard
                          JOIN p1_exr_analysis p
                            ON (ard.id_analysis_req_det = p.id_analysis_req_det)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_analysis_req_det IN (SELECT column_value
                                                            FROM TABLE(l_id_reqs)))
                        UNION ALL
                        SELECT ard.id_analysis_req_det
                          FROM analysis_req_det ard
                          JOIN p1_exr_temp p
                            ON (ard.id_analysis_req_det = p.id_analysis_req_det)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_analysis_req_det IN (SELECT column_value
                                                            FROM TABLE(l_id_reqs))));
            
                -- cancel analysis req
                g_error  := 'Call pk_lab_tests_api_db.cancel_lab_test_request / ' || l_params;
                g_retval := pk_lab_tests_api_db.cancel_lab_test_request(i_lang             => i_lang,
                                                                        i_prof             => i_prof,
                                                                        i_analysis_req_det => l_mcdt_req_det,
                                                                        i_dt_cancel        => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                                              i_prof,
                                                                                                                              current_timestamp,
                                                                                                                              NULL),
                                                                        i_cancel_reason    => i_reason,
                                                                        i_cancel_notes     => i_notes,
                                                                        i_prof_order       => NULL,
                                                                        i_dt_order         => NULL,
                                                                        i_order_type       => NULL,
                                                                        o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
            
                g_error  := 'Call ts_analysis_req_det.upd / ' || l_params;
                l_rowids := table_varchar();
                ts_analysis_req_det.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                        flg_referral_nin => FALSE,
                                        where_in         => 'id_analysis_req_det IN (SELECT id_analysis_req_det
                                                 FROM p1_exr_analysis
                                                WHERE id_external_request = ' ||
                                                            i_ext_req || '
                                               UNION ALL
                                               SELECT pt.id_analysis_req_det
                                                 FROM p1_exr_temp pt
                                                WHERE pt.id_external_request = ' ||
                                                            i_ext_req || ')',
                                        rows_out         => l_rowids);
            
                SELECT *
                  BULK COLLECT
                  INTO l_analysis_req_det_rows
                  FROM analysis_req_det
                 WHERE ROWID IN (SELECT column_value
                                   FROM TABLE(l_rowids));
            
                g_error := 'FOR i IN ' || l_analysis_req_det_rows.first || ' .. ' || l_analysis_req_det_rows.last ||
                           ' / ' || l_params;
                FOR i IN l_analysis_req_det_rows.first .. l_analysis_req_det_rows.last
                LOOP
                    g_error  := 'Call pk_lab_tests_api_db.set_lab_test_grid_task / ID_ANALYSIS_REQ_DET=' || l_analysis_req_det_rows(i).id_analysis_req_det ||
                                ' / ' || l_params;
                    g_retval := pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_patient          => NULL,
                                                                           i_episode          => i_id_episode,
                                                                           i_analysis_req     => NULL,
                                                                           i_analysis_req_det => l_analysis_req_det_rows(i).id_analysis_req_det,
                                                                           o_error            => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                END LOOP;
            
                g_error := 'Call t_data_gov_mnt.process_update / ' || l_params;
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'ANALYSIS_REQ_DET',
                                              l_rowids,
                                              o_error,
                                              table_varchar('FLG_REFERRAL'));
            END IF;
        
            SELECT COUNT(*)
              INTO l_id_reqs_count
              FROM p1_exr_temp p
             INNER JOIN analysis_req_det a
                ON a.id_analysis_req_det = p.id_analysis_req_det
             WHERE a.flg_status != pk_lab_tests_constant.g_analysis_cancel
               AND p.id_external_request = i_ext_req;
        
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_i
              OR l_flg_type = pk_ref_constant.g_p1_type_e
        THEN
        
            IF l_flg_status = pk_ref_constant.g_p1_status_p
            THEN
            
                -- getting exams req to cancel
                g_error := 'SELECT id_exam_req_det FROM ID_REF=' || i_ext_req || ' / ' || l_params;
                SELECT *
                  BULK COLLECT
                  INTO l_mcdt_req_det
                  FROM (SELECT erd.id_exam_req_det
                          FROM exam_req_det erd
                          JOIN p1_exr_exam p
                            ON (erd.id_exam_req_det = p.id_exam_req_det)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_exam_req_det IN (SELECT column_value
                                                        FROM TABLE(l_id_reqs)))
                        UNION ALL
                        SELECT erd.id_exam_req_det
                          FROM exam_req_det erd
                          JOIN p1_exr_temp p
                            ON (erd.id_exam_req_det = p.id_exam_req_det)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_exam_req_det IN (SELECT column_value
                                                        FROM TABLE(l_id_reqs))));
            
                g_error := 'tables / ' || l_params;
                l_cancel_reason.extend(l_mcdt_req_det.count);
                l_notes_cancel.extend(l_mcdt_req_det.count);
            
                -- cancel exams req
                g_error  := 'Call pk_exams_api_db.cancel_exam_request / ' || l_params;
                g_retval := pk_exams_api_db.cancel_exam_request(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_exam_req_det   => l_mcdt_req_det,
                                                                i_dt_cancel      => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                                    i_prof,
                                                                                                                    current_timestamp,
                                                                                                                    NULL),
                                                                i_cancel_reason  => i_reason,
                                                                i_cancel_notes   => i_notes,
                                                                i_prof_order     => NULL,
                                                                i_dt_order       => NULL,
                                                                i_order_type     => NULL,
                                                                i_transaction_id => l_transaction_id,
                                                                o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
            
                FOR w IN c_exam_req
                LOOP
                
                    g_error := 'select for update ' || pk_ref_constant.g_p1_type_i || ' / ' || l_params;
                    SELECT *
                      INTO l_exam_req_det_row
                      FROM exam_req_det
                     WHERE ROWID = w.rowid
                       FOR UPDATE;
                
                    g_error := 'Call ts_exam_req_det.upd / ' || pk_ref_constant.g_p1_type_i || ' / ' || l_params;
                    ts_exam_req_det.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                        flg_referral_nin => FALSE,
                                        where_in         => 'ROWID = ''' || w.rowid || '''',
                                        rows_out         => l_rows_out);
                
                    g_error  := 'Call pk_exams_api_db.set_exam_grid_task / i_id_exam_req=' ||
                                l_exam_req_det_row.id_exam_req || ' i_id_exam_req_det=' ||
                                l_exam_req_det_row.id_exam_req_det || ' ID_EPISODE=' || i_id_episode || ' / ' ||
                                l_params;
                    g_retval := pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                                   i_prof         => i_prof,
                                                                   i_patient      => NULL,
                                                                   i_episode      => i_id_episode,
                                                                   i_exam_req     => l_exam_req_det_row.id_exam_req,
                                                                   i_exam_req_det => l_exam_req_det_row.id_exam_req_det,
                                                                   o_error        => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                END LOOP;
            
                g_error := 'Call t_data_gov_mnt.process_update / ' || l_params;
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EXAM_REQ_DET',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END IF;
        
            SELECT COUNT(*)
              INTO l_id_reqs_count
              FROM p1_exr_temp p
             INNER JOIN exam_req_det a
                ON a.id_exam_req_det = p.id_exam_req_det
             WHERE a.flg_status != pk_lab_tests_constant.g_analysis_cancel
               AND p.id_external_request = i_ext_req;
        
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_p
        THEN
        
            IF l_flg_status = pk_ref_constant.g_p1_status_p
            THEN
            
                -- getting interv req to cancel
                g_error := 'SELECT id_interv_presc_det FROM ID_REF=' || i_ext_req || ' / ' || l_params;
                SELECT *
                  BULK COLLECT
                  INTO l_mcdt_req_det
                  FROM (SELECT ird.id_interv_presc_det
                          FROM interv_presc_det ird
                          JOIN p1_exr_intervention p
                            ON (ird.id_interv_presc_det = p.id_interv_presc_det)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_interv_presc_det IN (SELECT column_value
                                                            FROM TABLE(l_id_reqs)))
                        UNION ALL
                        SELECT ird.id_interv_presc_det
                          FROM interv_presc_det ird
                          JOIN p1_exr_temp p
                            ON (ird.id_interv_presc_det = p.id_interv_presc_det)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_interv_presc_det IN (SELECT column_value
                                                            FROM TABLE(l_id_reqs))));
            
                -- cancel interv req
                FOR i IN 1 .. l_mcdt_req_det.count
                LOOP
                
                    g_error  := 'CALL PK_PROCEDURES_API_DB.CANCEL_PROCEDURE_REQUEST / id_interv_presc_det=' ||
                                l_mcdt_req_det(i) || ' / ' || l_params;
                    g_retval := pk_procedures_api_db.cancel_procedure_request(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_interv_presc_det => l_mcdt_req_det,
                                                                              i_dt_cancel        => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    g_sysdate_tstz,
                                                                                                                                    NULL),
                                                                              i_cancel_reason    => i_reason,
                                                                              i_cancel_notes     => i_notes,
                                                                              i_prof_order       => NULL,
                                                                              i_dt_order         => NULL,
                                                                              i_order_type       => NULL,
                                                                              o_error            => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END LOOP;
            
            ELSE
            
                g_error  := 'Call ts_interv_presc_det.upd / ' || l_flg_type || ' / ' || l_params;
                l_rowids := table_varchar();
                ts_interv_presc_det.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                        flg_referral_nin => FALSE,
                                        where_in         => 'id_interv_presc_det IN (SELECT id_interv_presc_det
                                                 FROM p1_exr_intervention
                                                WHERE id_external_request = ' ||
                                                            i_ext_req || '
                                               UNION ALL
                                               SELECT id_interv_presc_det
                                                 FROM p1_exr_temp pt
                                                WHERE id_external_request = ' ||
                                                            i_ext_req || ')',
                                        rows_out         => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'INTERV_PRESC_DET',
                                              l_rowids,
                                              o_error,
                                              table_varchar('FLG_REFERRAL'));
            END IF;
        
            SELECT COUNT(*)
              INTO l_id_reqs_count
              FROM p1_exr_temp p
             INNER JOIN interv_presc_det a
                ON a.id_interv_presc_det = p.id_interv_presc_det
             WHERE a.flg_status != pk_lab_tests_constant.g_analysis_cancel
               AND p.id_external_request = i_ext_req;
        
        ELSIF l_flg_type = pk_ref_constant.g_p1_type_f
        THEN
        
            IF l_flg_status = pk_ref_constant.g_p1_status_p
            THEN
            
                -- getting rehab_presc to cancel
                g_error := 'SELECT id_rehab_presc FROM ID_REF=' || i_ext_req || ' / ' || l_params;
                SELECT *
                  BULK COLLECT
                  INTO l_mcdt_req_det
                  FROM (SELECT ird.id_rehab_presc
                          FROM rehab_presc ird
                          JOIN p1_exr_intervention p
                            ON (ird.id_rehab_presc = p.id_rehab_presc)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_interv_presc_det IN (SELECT column_value
                                                            FROM TABLE(l_id_reqs)))
                        UNION ALL
                        SELECT ird.id_rehab_presc
                          FROM rehab_presc ird
                          JOIN p1_exr_temp p
                            ON (ird.id_rehab_presc = p.id_rehab_presc)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_interv_presc_det IN (SELECT column_value
                                                            FROM TABLE(l_id_reqs)))
                        UNION ALL
                        SELECT ird.id_rehab_presc
                          FROM rehab_presc ird
                          JOIN p1_exr_temp p
                            ON (ird.id_rehab_presc = p.id_rehab_presc)
                         WHERE p.id_external_request = i_ext_req
                           AND (i_mcdts IS NULL OR
                               p.id_rehab_presc IN (SELECT column_value
                                                       FROM TABLE(l_id_reqs))));
            
                -- cancel rehab_presc
                FOR i IN 1 .. l_mcdt_req_det.count
                LOOP
                    g_error  := 'Call pk_rehab.cancel_rehab_presc / i_id_rehab_presc=' || l_mcdt_req_det(i) || ' / ' ||
                                l_params;
                    g_retval := pk_rehab.cancel_rehab_presc_nocommit(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_id_rehab_presc   => l_mcdt_req_det(i),
                                                                     i_id_cancel_reason => i_reason,
                                                                     i_notes            => i_notes,
                                                                     i_dt_cancel        => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                                           i_prof,
                                                                                                                           current_timestamp,
                                                                                                                           NULL),
                                                                     o_error            => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END LOOP;
            
            ELSE
            
                g_error  := 'Call ts_rehab_presc.upd / ' || l_flg_type || ' / ' || l_params;
                l_rowids := table_varchar();
                ts_rehab_presc.upd(flg_referral_in  => pk_ref_constant.g_flg_referral_a,
                                   flg_referral_nin => FALSE,
                                   where_in         => 'id_rehab_presc IN (SELECT id_rehab_presc
                                                 FROM p1_exr_intervention
                                                WHERE id_external_request = ' ||
                                                       i_ext_req || '
                                               UNION ALL
                                               SELECT id_rehab_presc
                                                 FROM p1_exr_temp pt
                                                WHERE id_external_request = ' ||
                                                       i_ext_req || ')',
                                   rows_out         => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'REHAB_PRESC',
                                              l_rowids,
                                              o_error,
                                              table_varchar('FLG_REFERRAL'));
            
            END IF;
        
            SELECT COUNT(*)
              INTO l_id_reqs_count
              FROM (SELECT 1
                      FROM p1_exr_temp p
                     INNER JOIN interv_presc_det a
                        ON a.id_interv_presc_det = p.id_interv_presc_det
                     WHERE a.flg_status != pk_lab_tests_constant.g_analysis_cancel
                       AND p.id_external_request = i_ext_req
                    UNION ALL
                    SELECT 1
                      FROM p1_exr_temp p
                     INNER JOIN rehab_presc rp
                        ON rp.id_rehab_presc = p.id_rehab_presc
                     WHERE rp.flg_status != pk_lab_tests_constant.g_analysis_cancel
                       AND p.id_external_request = i_ext_req);
        END IF;
    
        IF i_id_episode IS NOT NULL
           AND l_id_reqs.count = 0
        THEN
        
            g_error   := 'i_id_patient=' || i_id_patient || ' l_id_patient=' || l_id_patient || ' / ' || l_params;
            l_patient := nvl(i_id_patient, l_id_patient);
        
            g_error  := 'Call pk_visit.set_first_obs / ID_PATIENT=' || l_patient || ' / ' || l_params;
            g_retval := pk_visit.set_first_obs(i_lang                => i_lang,
                                               i_id_episode          => i_id_episode,
                                               i_pat                 => l_patient,
                                               i_prof                => i_prof,
                                               i_prof_cat_type       => NULL,
                                               i_dt_last_interaction => g_sysdate_tstz,
                                               i_dt_first_obs        => NULL,
                                               o_error               => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- set print list job as canceled (if exists in printing list)
            g_error  := 'Call pk_ref_ext_sys.set_print_jobs_cancel / ' || l_params;
            g_retval := pk_ref_ext_sys.set_print_jobs_cancel(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_patient => l_patient,
                                                             i_id_episode => i_id_episode,
                                                             i_id_ref     => i_ext_req,
                                                             o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        IF l_id_reqs_count = 0
        THEN
        
            g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_track_row   => l_track_row,
                                                 i_old_status  => l_valid_status,
                                                 i_flg_isencao => NULL,
                                                 i_mcdt_nature => NULL,
                                                 o_track       => o_track,
                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF pk_prof_utils.get_category(i_lang, i_prof) = pk_ref_constant.g_registrar
            THEN
                l_notes := pk_message.get_message(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_code_mess => 'REF_ADM_CANCEL_DETAIL') || chr(10) || i_notes;
            ELSE
                l_notes := i_notes;
            END IF;
        
            IF l_notes IS NOT NULL
            THEN
                g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_ncan || ' / ' || l_params;
                INSERT INTO p1_detail
                    (id_detail,
                     id_external_request,
                     text,
                     dt_insert_tstz,
                     flg_type,
                     id_professional,
                     id_institution,
                     id_tracking,
                     flg_status)
                VALUES
                    (seq_p1_detail.nextval,
                     i_ext_req,
                     l_notes,
                     g_sysdate_tstz,
                     pk_ref_constant.g_detail_type_ncan,
                     i_prof.id,
                     i_prof.institution,
                     o_track(1), -- first iteration
                     pk_ref_constant.g_detail_status_a);
            END IF;
        
        END IF;
    
        IF l_bdnp_available = pk_ref_constant.g_yes
           AND l_id_reqs.count = 0
           OR l_id_reqs_count = 0
        THEN
        
            CASE l_flg_status
                WHEN pk_ref_constant.g_p1_status_p THEN
                
                    g_error := 'pk_ia_event_prescription.prescription_mcdt_cancel i_id_external_request=' || i_ext_req;
                    pk_alertlog.log_info(g_error);
                    pk_ia_event_prescription.prescription_mcdt_cancel(i_id_tracking    => o_track(1),
                                                                      i_id_institution => i_prof.institution);
                
                    l_bdnp_presc_tracking.id_presc          := i_ext_req;
                    l_bdnp_presc_tracking.flg_presc_type    := pk_ref_constant.g_bdnp_ref_type;
                    l_bdnp_presc_tracking.dt_presc_tracking := g_sysdate_tstz;
                    l_bdnp_presc_tracking.dt_event          := g_sysdate_tstz;
                    l_bdnp_presc_tracking.flg_event_type    := pk_ref_constant.g_bdnp_event_type_c;
                    l_bdnp_presc_tracking.id_prof_event     := i_prof.id;
                    l_bdnp_presc_tracking.id_institution    := i_prof.institution;
                
                    g_error  := 'Call pk_bdnp.set_bdnp_presc_tracking';
                    g_retval := pk_bdnp.set_bdnp_presc_tracking(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_bdnp_presc_tracking => l_bdnp_presc_tracking,
                                                                o_error               => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error  := 'Call  pk_ref_api.set_referral_flg_migrated / i_flg_migrated=' ||
                                pk_ref_constant.g_bdnp_mig_n || ' i_id_external_request=' || i_ext_req;
                    g_retval := pk_ref_api.set_referral_flg_migrated(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_external_request => i_ext_req,
                                                                     i_flg_migrated        => pk_ref_constant.g_bdnp_mig_n,
                                                                     o_error               => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    END IF;
                
                WHEN pk_ref_constant.g_p1_status_o THEN
                
                    -- ALERT-213629 - this is done only to show the right calncelled icon 
                    g_error  := 'Call  pk_ref_api.set_referral_flg_migrated / i_flg_migrated=' ||
                                pk_ref_constant.g_bdnp_mig_x || ' i_id_external_request=' || i_ext_req;
                    g_retval := pk_ref_api.set_referral_flg_migrated(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_external_request => i_ext_req,
                                                                     i_flg_migrated        => pk_ref_constant.g_bdnp_mig_x,
                                                                     o_error               => o_error);
                    IF NOT g_retval
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    NULL;
            END CASE;
        
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              i_function => 'CANCEL_EXTERNAL_REQUEST_INT',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancel_external_request_int;

    /**
    * Only used to cancel referral or decline cancellation request from actions button
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            professional id, institution and software    
    * @param   i_id_ref          Referral identifier
    * @param   i_action          Action to be processed
    * @param   i_reason_code     Reason code for cancellation
    * @param   i_notes           Notes of answering referral cancellation request    
    * @param   i_op_date         Operation date   
    * @param   i_dt_modified     Last modified date as provided by get_referral
    * @param   i_mode            (V)alidate date modified or do(N)t
    * @param   o_flg_show        Flag indicating if o_msg is shown
    * @param   o_msg             Message indicating that referral has been changed
    * @param   o_msg_title       Message title
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   21-09-2010
    */
    FUNCTION set_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_action      IN VARCHAR2,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN VARCHAR2,
        i_op_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_dt_modified IN VARCHAR2,
        i_mode        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row   p1_external_request%ROWTYPE;
        l_params    VARCHAR2(1000 CHAR);
        l_track_tab table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_action=' || i_action ||
                    ' i_reason_code=' || i_reason_code || ' i_dt_modified=' || i_dt_modified || ' i_mode=' || i_mode;
        g_error  := 'Init set_status / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_op_date, pk_ref_utils.get_sysdate);
    
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
    
        l_params   := l_params || ' WF=' || l_ref_row.id_workflow || ' FLG_STATUS=' || l_ref_row.flg_status;
        o_flg_show := pk_ref_constant.g_no;
        IF i_mode = pk_ref_constant.g_validate_changes
        THEN
        
            g_error := 'Validating changes / ' || l_params;
            pk_alertlog.log_info(g_error);
            IF pk_date_utils.trunc_insttimezone(i_prof, l_ref_row.dt_last_interaction_tstz, 'SS') >
               pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_modified, NULL)
            THEN
                o_flg_show  := pk_ref_constant.g_yes;
                o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => pk_ref_constant.g_sm_doctor_hs_t023);
                o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => pk_ref_constant.g_sm_doctor_hs_t024);
                RETURN TRUE;
            END IF;
        
        END IF;
    
        g_error := 'CASE i_action=' || i_action || ' / ' || l_params;
        CASE i_action
            WHEN pk_ref_constant.g_ref_action_c THEN
            
                -- Cancel referral                
                g_error  := 'Call cancel_external_request_int / ' || l_params;
                g_retval := cancel_external_request_int(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_ext_req        => i_id_ref,
                                                        i_mcdts          => NULL,
                                                        i_id_patient     => NULL,
                                                        i_id_episode     => NULL,
                                                        i_notes          => i_notes,
                                                        i_reason         => NULL,
                                                        i_transaction_id => NULL,
                                                        o_track          => l_track_tab,
                                                        o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            WHEN pk_ref_constant.g_ref_action_zdn THEN
                -- Decline cancellation request            
                g_error  := 'Call pk_ref_utils.get_prev_status_data / ' || l_params;
                g_retval := decline_req_cancellation(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_id_ref  => i_id_ref,
                                                     i_notes   => i_notes,
                                                     i_op_date => NULL,
                                                     o_error   => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
                g_error := 'Invalid action / ' || l_params;
                RAISE g_exception;
        END CASE;
    
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
                                              i_function => 'SET_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_status;

    /**
    * Declines a cancellation request
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            professional id, institution and software    
    * @param   i_id_ref          Referral identifier
    * @param   i_notes           Notes of answering referral cancellation request    
    * @param   i_op_date         Operation date   
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   28-09-2010
    */
    FUNCTION decline_req_cancellation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_ref  IN p1_external_request.id_external_request%TYPE,
        i_notes   IN VARCHAR2,
        i_op_date IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row p1_tracking%ROWTYPE;
        l_config    VARCHAR2(1 CHAR);
        o_track     table_number;
    BEGIN
        g_error := 'Init decline_req_cancellation / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_op_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        -- checks if this functionality is enabled
        g_error  := 'Call pk_ref_status.check_config_enabled / ID_REF=' || i_id_ref || ' CONFIG=' ||
                    pk_ref_constant.g_ref_cancel_req_enabled;
        l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_config => pk_ref_constant.g_ref_cancel_req_enabled);
    
        IF l_config = pk_ref_constant.g_no
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting previous referral status            
        g_error  := 'Call pk_ref_utils.get_prev_status_data / ID_REF=' || i_id_ref;
        g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => i_id_ref,
                                                      o_data   => l_track_row,
                                                      o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error                        := 'UPDATE STATUS / ID_REF=' || i_id_ref;
        l_track_row.dt_tracking_tstz   := g_sysdate_tstz;
        l_track_row.id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_zdn);
    
        g_error  := 'Call pk_p1_core.update_status / TRACK_ROW=' ||
                    pk_ref_utils.to_string(i_lang => i_lang, i_prof => i_prof, i_tracking_row => l_track_row);
        g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_track_row   => l_track_row,
                                             i_old_status  => pk_ref_constant.g_p1_status_z,
                                             i_flg_isencao => NULL,
                                             i_mcdt_nature => NULL,
                                             o_track       => o_track,
                                             o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_notes IS NOT NULL
        THEN
        
            g_error := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_req_can_answ || ' / ID_REF=' || i_id_ref;
            INSERT INTO p1_detail
                (id_detail,
                 id_external_request,
                 text,
                 dt_insert_tstz,
                 flg_type,
                 id_professional,
                 id_institution,
                 id_tracking,
                 flg_status)
            VALUES
                (seq_p1_detail.nextval,
                 i_id_ref,
                 i_notes,
                 g_sysdate_tstz,
                 pk_ref_constant.g_detail_type_req_can_answ,
                 i_prof.id,
                 i_prof.institution,
                 o_track(1), -- first iteration
                 pk_ref_constant.g_detail_status_a);
        
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
                                              i_function => 'DECLINE_REQ_CANCELLATION',
                                              o_error    => o_error);
            RETURN FALSE;
    END decline_req_cancellation;

BEGIN

    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_med_cs;
/
