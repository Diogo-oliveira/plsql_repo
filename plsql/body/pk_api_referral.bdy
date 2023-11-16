/*-- Last Change Revision: $Rev: 2026728 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_referral IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    --g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    -- referral data migration
    g_ref_mig_row ref_mig_inst_dest_data%ROWTYPE;

    FUNCTION get_institution_from_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN institution_group.id_group%TYPE,
        o_inst     OUT institution.id_institution%TYPE,
        o_all_inst OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Get institutions from institution_group';
        SELECT id_institution
          BULK COLLECT
          INTO o_all_inst
          FROM institution_group ig
         WHERE ig.id_group = i_id_group;
    
        g_error := 'Get 1st institution from institution_group';
    
        IF o_all_inst IS NULL
           OR o_all_inst.count = 0
           OR (o_all_inst.exists(1) AND o_all_inst(1) IS NULL)
        THEN
            o_inst := NULL;
        ELSE
            o_inst := o_all_inst(1);
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
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_INSTITUTION_FROM_GROUP',
                                                     o_error    => o_error);
        
    END get_institution_from_group;

    /*
    * Get Referral short detail (Patient Portal)
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_pat                 Paciente id
    * @param i_id_external_request Referral id
    * @param o_error               Error
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */
    FUNCTION get_referral
    (
        i_lang                IN language.id_language%TYPE,
        i_id_group            IN institution_group.id_group%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat      patient.id_patient%TYPE;
        l_inst     institution.id_institution%TYPE;
        l_all_inst table_number;
    
    BEGIN
    
        g_error := 'Call get_institution_from_group i_id_group = ' || i_id_group;
        IF NOT get_institution_from_group(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_id_group => i_id_group,
                                          o_inst     => l_inst,
                                          o_all_inst => l_all_inst,
                                          o_error    => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := ' SELECT id_patient id_external_request = ' || i_id_external_request;
        SELECT id_patient
          INTO l_pat
          FROM p1_external_request
         WHERE id_external_request = i_id_external_request;
    
        IF l_pat = i_patient
        THEN
            g_error := 'Call  pk_ref_ext_sys.get_ref_detail i_id_external_request = ' || i_id_external_request;
            IF NOT pk_ref_ext_sys.get_ref_detail(i_lang                => i_lang,
                                                 i_prof                => profissional(i_prof.id, l_inst, i_prof.software),
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
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_REFERRAL',
                                                     o_error    => o_error);
    END get_referral;

    /*
    * Get Referral short detail (Patient Portal)
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_pat                 Paciente id
    * @param i_num_req             Referral num_req 
    * @param o_detail              Referral detail    
    * @param o_error               Error
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */
    FUNCTION get_referral
    (
        i_lang     IN language.id_language%TYPE,
        i_id_group IN institution_group.id_group%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_num_req  IN p1_external_request.num_req%TYPE,
        o_detail   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ext_req p1_external_request.id_external_request%TYPE;
    BEGIN
        g_error := 'Ini get_referral / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_group=' || i_id_group ||
                   ' i_patient=' || i_patient || ' i_num_req=' || i_num_req;
        BEGIN
            g_error := 'Select id_external_request id_patient = ' || i_patient || 'and num_req = ' || i_num_req;
            SELECT id_external_request
              INTO l_ext_req
              FROM p1_external_request
             WHERE id_patient = i_patient
               AND num_req = i_num_req;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE g_exception;
        END;
    
        g_retval := get_referral(i_lang                => i_lang,
                                 i_id_group            => i_id_group,
                                 i_prof                => i_prof,
                                 i_patient             => i_patient,
                                 i_id_external_request => l_ext_req,
                                 o_detail              => o_detail,
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
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_REFERRAL',
                                                     o_error    => o_error);
        
    END get_referral;

    /*
    * Get Patient Referral List (Patient Portal)
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_patient             Paciente id
    * @param o_ref_list            Referral list
    * @param o_error               Error
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   12-10-2010
    */
    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_id_group IN institution_group.id_group%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_ref_list OUT pk_ref_ext_sys.ref_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message  VARCHAR2(4000);
        l_title    VARCHAR2(4000);
        l_buttons  VARCHAR2(4000);
        l_inst     institution.id_institution%TYPE;
        l_all_inst table_number;
    BEGIN
        g_error := 'Call get_institution_from_group / i_id_group = ' || i_id_group;
        IF NOT get_institution_from_group(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_id_group => i_id_group,
                                          o_inst     => l_inst,
                                          o_all_inst => l_all_inst,
                                          o_error    => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call pk_ref_ext_sys.get_pat_ref_gp / ID_PATIENT=' || i_patient || ' i_id_group=' || i_id_group;
        IF NOT pk_ref_ext_sys.get_pat_ref_gp(i_lang           => i_lang,
                                             i_prof           => profissional(i_prof.id, l_inst, i_prof.software),
                                             i_patient        => i_patient,
                                             i_type           => NULL,
                                             i_inst_dest_list => l_all_inst,
                                             o_ref_list       => o_ref_list,
                                             o_message        => l_message,
                                             o_title          => l_title,
                                             o_buttons        => l_buttons,
                                             o_error          => o_error)
        
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
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_REFERRAL_LIST',
                                                     o_error    => o_error);
    END get_referral_list;

    /**
    * Import Requests registed in SONHO
    *
    * @param   I_LANG                 Language associated to the professional executing the request
    * @param   I_PROF                 Professional id, institution and software    
    * @param   I_PAT                  Patient id (NOT NULL)
    * @param   I_INST_ORIG            Origin Ext Code institution    
    * @param   I_ID_DEP_CLIN_SERV     Id department/clinical_service (NOT NULL)
    * @param   I_FLG_TYPE             Referral type: {*} (C)onsultation {*} (A)nalisys {*} (I)mage {*} (E)xam {*} (P) Intervention {*} (F)Mfr  (NOT NULL)
    * @param   I_FLG_PRIORITY         Referral priority flag: {*} Y - urgent {*} N - otherwise
    * @param   I_FLG_HOME             Referral home flag: {*} Y - home {*} N - otherwise
    * @param   I_FLG_STATUS           Referral status: {*} (I)ssued {*} (T)riage {*} (A)ccepted {*} (S)cheduled (NOT NULL)
    * @param   I_DECISION_URG_LEVEL   Referral triage level (NOT NULL if I_FLG_STATUS in ('A','S')
    * @param   I_APPOITMENT_DATE      Appoitment's date/hour (NOT NULL if flg_status = 'S')
    * @param   I_NUM_ORDER_SCH        Scheduled consultation professional num order   
    * @param   I_PROF_NAME_SCH        Scheduled consultation professional name
    * @param   I_EXT_REFERENCE        External reference    
    * @param   I_JUSTIFICATION        Referral justification (NOT NULL)
    * @param   I_DT_ISSUED            Referral issued date (NOT NULL)
    * @param   i_dt_triage            Referral triaged date (NOT NULL if I_FLG_STATUS in ('T','A','S')
    * @param   i_dt_accepted          Referral accepted date (NOT NULL if I_FLG_STATUS in ('A','S')   
    * @param   i_dt_scheduled         Referral scheduled date (NOT NULL if I_FLG_STATUS in ('S')
    * @param   I_SEQ_NUM              Match sequential number
    * @param   I_CLIN_REC             Clinical record number
    * @param   I_INST_NAME            Origin institution name   (Referral Detail)
    * @param   I_PROF_NAME            Origin professional name (Referral Detail)
    *
    * @param   O_ID_EXTERNAL_REQUEST  Referral id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-11-2010
    */

    FUNCTION import_referral
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat                 IN patient.id_patient%TYPE,
        i_inst_orig           IN institution.ext_code%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE, -- not null
        i_flg_type            IN p1_external_request.flg_type%TYPE,
        i_flg_priority        IN p1_external_request.flg_priority%TYPE,
        i_flg_home            IN p1_external_request.flg_home%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE, -- not null
        i_decision_urg_level  IN p1_external_request.decision_urg_level%TYPE,
        i_appoitment_date     IN TIMESTAMP WITH TIME ZONE,
        i_num_order_sch       IN professional.num_order%TYPE,
        i_prof_name_sch       IN professional.name%TYPE,
        i_ext_reference       IN p1_external_request.ext_reference%TYPE,
        i_justification       IN table_varchar,
        i_dt_issued           IN TIMESTAMP WITH TIME ZONE,
        i_dt_triage           IN TIMESTAMP WITH TIME ZONE,
        i_dt_accepted         IN TIMESTAMP WITH TIME ZONE,
        i_dt_scheduled        IN TIMESTAMP WITH TIME ZONE,
        i_seq_num             IN p1_match.sequential_number%TYPE,
        i_clin_rec            IN clin_record.num_clin_record%TYPE,
        i_inst_name           IN pk_translation.t_desc_translation,
        i_prof_name           IN professional.name%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof               profissional;
        l_prof_interface     profissional;
        l_id_inst_dest       p1_external_request.id_inst_dest%TYPE;
        l_id_inst_orig       p1_external_request.id_inst_orig%TYPE;
        l_inst_name          pk_translation.t_desc_translation;
        l_id_speciality      p1_external_request.id_speciality%TYPE;
        l_current_timestamp  TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_external_sys    external_sys.id_external_sys%TYPE;
        l_id_software        software.id_software%TYPE;
        l_id_inst_orig_undef institution.id_institution%TYPE;
        l_id_prof_req        professional.id_professional%TYPE;
        l_text_notes         p1_detail.text%TYPE;
        l_get_institution    PLS_INTEGER;
        l_id_epis_type       schedule_outp.id_epis_type%TYPE;
        l_id_patient         p1_external_request.id_patient%TYPE;
        l_match_found        BOOLEAN;
        l_exr_row            p1_external_request%ROWTYPE;
        l_date_tstz          p1_tracking.dt_tracking_tstz%TYPE;
        l_dt_create          p1_tracking.dt_create%TYPE;
        l_rowids             table_varchar;
        l_id_prof_sch        p1_tracking.id_professional%TYPE;
        l_dt_schedule_tstz   schedule.dt_schedule_tstz%TYPE;
        l_dt_begin_tstz      schedule.dt_begin_tstz%TYPE;
        l_id_schedule        p1_external_request.id_schedule%TYPE;
        l_schedout           schedule_outp.id_schedule_outp%TYPE;
    
        TYPE t_tracking_tab IS TABLE OF p1_tracking%ROWTYPE INDEX BY BINARY_INTEGER;
        l_tracking_tab t_tracking_tab;
        l_tracking_idx PLS_INTEGER := 0;
        l_round        p1_tracking.round_id%TYPE;
    
        TYPE t_detail_tab IS TABLE OF p1_detail%ROWTYPE INDEX BY BINARY_INTEGER;
        l_detail_tab t_detail_tab;
        l_detail_idx PLS_INTEGER := 0;
    
        CURSOR c_inst_ext_code(x_institution IN institution.ext_code%TYPE) IS
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution)
              FROM institution i
             WHERE i.ext_code = x_institution;
    
        CURSOR c_institution(x_id_institution IN institution.id_institution%TYPE) IS
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution)
              FROM institution i
             WHERE i.id_institution = x_id_institution;
    
        CURSOR c_ref_net
        (
            x_inst_orig       institution.id_institution%TYPE,
            x_dcs             dep_clin_serv.id_dep_clin_serv%TYPE,
            x_id_external_sys p1_external_request.id_external_sys%TYPE
        ) IS
            SELECT v.id_institution, v.id_speciality
              FROM v_ref_network v
             WHERE v.flg_type = pk_ref_constant.g_p1_type_c
               AND v.id_inst_orig = x_inst_orig
               AND v.id_dep_clin_serv = x_dcs
               AND v.id_external_sys IN (nvl(x_id_external_sys, 0), 0);
    
        CURSOR c_pat_match
        (
            i_pat  p1_match.id_patient%TYPE,
            i_seq  p1_match.sequential_number%TYPE,
            i_inst p1_match.id_institution%TYPE
        ) IS
            SELECT id_patient
              FROM p1_match
             WHERE sequential_number = i_seq
               AND id_institution = i_inst
               AND flg_status = pk_ref_constant.g_active
               AND id_patient = i_pat;
    
        l_params VARCHAR2(1000 CHAR);
    
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_inst_orig=' || i_inst_orig ||
                    ' i_id_dep_clin_serv=' || i_id_dep_clin_serv || ' i_flg_type=' || i_flg_type || ' i_flg_priority=' ||
                    i_flg_priority || ' i_flg_home=' || i_flg_home || ' i_flg_status=' || i_flg_status ||
                    ' i_decision_urg_level=' || i_decision_urg_level || ' i_num_order_sch=' || i_num_order_sch ||
                    ' i_ext_reference=' || i_ext_reference || ' i_seq_num=' || i_seq_num || ' i_clin_rec=' ||
                    i_clin_rec || ' i_dt_triage=' || i_dt_triage || ' i_dt_accepted=' || i_dt_accepted ||
                    ' i_dt_scheduled=' || i_dt_scheduled;
    
        g_error             := 'Init import_referral / ' || l_params;
        l_current_timestamp := current_timestamp;
        l_dt_create         := current_timestamp;
        l_id_external_sys   := 0;
    
        ----------------------
        -- VAL
        ----------------------
    
        -- validating mandatory parameters
        IF i_pat IS NULL
           OR i_inst_orig IS NULL
           OR i_id_dep_clin_serv IS NULL
           OR i_flg_type IS NULL
           OR i_flg_status IS NULL
        THEN
            g_error := 'Mandatory parameters / i_pat=' || i_pat || ' i_inst_orig=' || i_inst_orig ||
                       ' i_id_dep_clin_serv=' || i_id_dep_clin_serv || ' i_flg_type=' || i_flg_type || ' i_flg_status=' ||
                       i_flg_status;
            RAISE g_exception;
        END IF;
    
        -- validating i_flg_status
        g_error := 'Validating parameters / ' || l_params;
        IF i_flg_status NOT IN (pk_ref_constant.g_p1_status_i,
                                pk_ref_constant.g_p1_status_t,
                                pk_ref_constant.g_p1_status_a,
                                pk_ref_constant.g_p1_status_s)
        THEN
            g_error := 'Invalid status ''' || i_flg_status || '''';
            RAISE g_exception;
        END IF;
    
        IF i_justification.count != 1
        THEN
            g_error := 'Invalid i_justification / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- I_decision_urg_level 
        -- Triage Level
        IF i_flg_status IN (pk_ref_constant.g_p1_status_a, pk_ref_constant.g_p1_status_s)
           AND i_decision_urg_level IS NULL
        THEN
            g_error := 'i_decision_urg_level is NULL and i_flg_status = ' || i_flg_status || ' / ' || l_params;
            RAISE g_exception;
        ELSIF i_flg_status IN (pk_ref_constant.g_p1_status_i, pk_ref_constant.g_p1_status_t)
              AND i_decision_urg_level IS NOT NULL
        THEN
            g_error := 'i_decision_urg_level must be NULL i_flg_status = ' || i_flg_status || ' / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- getting software id
        g_error := 'software id / ' || l_params;
        IF i_prof.software IS NOT NULL
        THEN
            l_id_software := i_prof.software;
        ELSE
            l_id_software := pk_ref_utils.get_sys_config(i_prof          => profissional(NULL, 0, 0),
                                                         i_id_sys_config => 'SOFTWARE_ID_P1');
        END IF;
    
        -- checking dates
        IF i_dt_issued IS NULL
        THEN
            g_error := 'DT_ISSUED IS NULL / ' || l_params;
            RAISE g_exception;
        END IF;
    
        IF i_dt_triage IS NULL
           AND i_flg_status IN
           (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_a, pk_ref_constant.g_p1_status_s)
        THEN
            g_error := 'DT_TRIAGE IS NULL / ' || l_params;
            RAISE g_exception;
        END IF;
    
        IF i_dt_accepted IS NULL
           AND i_flg_status IN (pk_ref_constant.g_p1_status_a, pk_ref_constant.g_p1_status_s)
        THEN
            g_error := 'DT_ACCEPTED IS NULL / ' || l_params;
            RAISE g_exception;
        END IF;
    
        IF i_dt_scheduled IS NULL
           AND i_flg_status = pk_ref_constant.g_p1_status_s
        THEN
            g_error := 'DT_SCHEDULED IS NULL / ' || l_params;
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error              := 'Getting sys_config parameters / ' || l_params;
        l_id_inst_orig_undef := to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                                      0,
                                                                                                      l_id_software),
                                                                      i_id_sys_config => 'P1_IMPORT_INST_ORIG'));
        l_id_prof_req        := to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                                      0,
                                                                                                      l_id_software),
                                                                      i_id_sys_config => 'P1_IMPORT_PROF_REQ'));
    
        g_error        := 'Getting sys_config / ' || l_params;
        l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', l_prof_interface)); -- todo: validar se e necessario
    
        l_params := l_params || ' l_id_inst_orig_undef=' || l_id_inst_orig_undef || ' l_id_prof_req=' || l_id_prof_req;
    
        -- getting sys_messages
        g_error        := 'Fill l_code_msg_arr / ' || l_params;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_p1_import_notes,
                                        pk_ref_constant.g_sm_adm_p1_t022,
                                        pk_ref_constant.g_sm_doctor_cs_t077);
    
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
    
        ----------------------
        -- FUNC
        ----------------------            
        g_error      := 'l_text_notes / ' || l_params;
        l_text_notes := l_desc_message_ibt(pk_ref_constant.g_sm_p1_import_notes);
    
        -- getting orig institution    
        l_get_institution := 0;
    
        g_error := 'orig institution / ' || l_params;
        IF i_inst_orig IS NOT NULL
        THEN
            OPEN c_inst_ext_code(i_inst_orig);
            FETCH c_inst_ext_code
                INTO l_id_inst_orig, l_inst_name;
            g_found := c_inst_ext_code%FOUND;
            CLOSE c_inst_ext_code;
        
            IF NOT g_found
            THEN
                l_get_institution := 1; -- institution not recognized by CTH
            END IF;
        
        ELSE
            l_get_institution := 1; -- institution not recognized by CTH        
        END IF;
    
        IF l_get_institution = 1
        THEN
            g_error := 'orig institution 2 / ' || l_params;
            OPEN c_institution(l_id_inst_orig_undef);
            FETCH c_institution
                INTO l_id_inst_orig, l_inst_name;
            g_found := c_institution%FOUND;
            CLOSE c_institution;
        
            g_error := 'i_inst_name 2 / ' || l_params;
            IF i_inst_name IS NOT NULL
            THEN
                l_inst_name := i_inst_name;
            END IF;
        END IF;
    
        -- checking prof requested
        g_error := 'prof requested / ' || l_params;
        l_prof  := profissional(l_id_prof_req, l_id_inst_orig, l_id_software);
    
        g_error  := 'Call pk_ref_interface.set_professional_num_ord / i_prof=' || pk_utils.to_string(l_prof) ||
                    ' i_num_order=0 i_prof_name=null i_dcs=NULL';
        g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => i_lang,
                                                              i_prof      => l_prof,
                                                              i_num_order => pk_ref_constant.g_not_app, -- professional used to import referrals, no num_order
                                                              i_prof_name => NULL,
                                                              i_dcs       => NULL,
                                                              o_id_prof   => l_id_prof_req,
                                                              o_error     => o_error);
    
        -- getting dest institution and p1 speciality
        g_error := 'OPEN c_ref_net / ID_INST_ORIG=' || i_prof.institution || '|ID_DEP_CLIN_SERV=' || i_id_dep_clin_serv ||
                   ' ID_EXTERNAL_SYS=' || l_id_external_sys || ' / ' || l_params;
        OPEN c_ref_net(x_inst_orig       => i_prof.institution,
                       x_dcs             => i_id_dep_clin_serv,
                       x_id_external_sys => l_id_external_sys);
        FETCH c_ref_net
            INTO l_id_inst_dest, l_id_speciality;
        CLOSE c_ref_net;
    
        IF l_id_inst_dest IS NULL
           OR l_id_speciality IS NULL
        THEN
            g_error := 'Cannot reference clinical service from this orig institution / ID_INST_ORIG=' ||
                       i_prof.institution || ' ID_DEP_CLIN_SERV=' || i_id_dep_clin_serv || ' ID_EXTERNAL_SYS=' ||
                       l_id_external_sys || ' ID_SPECIALITY=' || l_id_speciality;
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / ' || l_params;
        g_retval := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                                     i_id_patient       => i_pat,
                                                                     i_id_external_sys  => l_id_external_sys,
                                                                     i_flg_availability => pk_ref_constant.g_flg_availability_e, -- this is always WF=1, change this when importing other WFs
                                                                     o_id_speciality    => l_id_speciality,
                                                                     o_error            => o_error);
    
        g_error          := 'SET l_prof_interface / ID_INSTITUTION=' || l_id_inst_dest || ' ID_SOFTWARE=' ||
                            l_id_software || ' / ' || l_params;
        l_prof_interface := profissional(to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                                               i_prof.institution,
                                                                                                               i_prof.software),
                                                                               i_id_sys_config => pk_ref_constant.g_sc_intf_prof_id)),
                                         l_id_inst_dest,
                                         l_id_software);
    
        l_params := l_params || ' l_prof_interface=' || pk_utils.to_string(l_prof_interface);
    
        -- checking match        
        g_error := 'OPEN c_pat_match(' || i_pat || ',' || i_seq_num || ',' || l_id_inst_dest || ');';
        OPEN c_pat_match(i_pat, i_seq_num, l_id_inst_dest);
        FETCH c_pat_match
            INTO l_id_patient;
        l_match_found := c_pat_match%FOUND;
        CLOSE c_pat_match;
    
        l_id_patient := i_pat;
    
        g_error  := 'Calling pk_ref_core.check_mandatory_data / ID_PAT=' || l_id_patient || ' / ' || l_params;
        g_retval := pk_ref_core.check_mandatory_data(i_lang  => i_lang,
                                                     i_prof  => l_prof,
                                                     i_pat   => l_id_patient,
                                                     o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- set match only if i_flg_status not in ('N','I')            
        IF NOT l_match_found
           AND i_flg_status NOT IN (pk_ref_constant.g_p1_status_n, pk_ref_constant.g_p1_status_i)
        THEN
            g_error  := 'Call pk_p1_interface.set_match / ' || l_params;
            g_retval := pk_p1_interface.set_match(i_lang     => i_lang,
                                                  i_pat      => l_id_patient,
                                                  i_prof     => l_prof_interface,
                                                  i_seq_num  => i_seq_num,
                                                  i_clin_rec => i_clin_rec,
                                                  o_error    => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- creating referral
        g_error                       := 'ts_p1_external_request.next_key() / ' || l_params;
        l_exr_row.id_external_request := ts_p1_external_request.next_key();
    
        g_error                            := 'filling l_exr_row / ' || l_params;
        l_exr_row.id_patient               := l_id_patient;
        l_exr_row.id_dep_clin_serv         := i_id_dep_clin_serv;
        l_exr_row.id_prof_requested        := l_prof.id;
        l_exr_row.id_prof_created          := l_prof.id;
        l_exr_row.num_req                  := l_exr_row.id_external_request;
        l_exr_row.flg_status               := i_flg_status;
        l_exr_row.flg_priority             := nvl(i_flg_priority, pk_ref_constant.g_no);
        l_exr_row.flg_type                 := i_flg_type;
        l_exr_row.id_schedule              := NULL;
        l_exr_row.id_prof_redirected       := NULL;
        l_exr_row.flg_digital_doc          := pk_ref_constant.g_no;
        l_exr_row.flg_mail                 := pk_ref_constant.g_no;
        l_exr_row.flg_paper_doc            := pk_ref_constant.g_no;
        l_exr_row.id_inst_dest             := l_id_inst_dest;
        l_exr_row.id_inst_orig             := l_id_inst_orig;
        l_exr_row.req_type                 := pk_ref_constant.g_p1_req_type_m;
        l_exr_row.flg_home                 := nvl(i_flg_home, pk_ref_constant.g_no);
        l_exr_row.decision_urg_level       := NULL; --pk_ref_constant.g_decision_urg_level_normal;
        l_exr_row.id_prof_status           := l_prof_interface.id;
        l_exr_row.id_speciality            := l_id_speciality;
        l_exr_row.flg_import               := pk_ref_constant.g_yes;
        l_exr_row.dt_last_interaction_tstz := l_current_timestamp;
        l_exr_row.dt_requested             := l_current_timestamp;
        l_exr_row.flg_interface            := NULL;
        l_exr_row.ext_reference            := i_ext_reference;
    
        g_error := 'STATUS N / ' || l_params;
        l_round := seq_p1_exr_track_round.nextval;
    
        l_tracking_idx := l_tracking_idx + 1;
        l_tracking_tab(l_tracking_idx).id_tracking := ts_p1_tracking.next_key();
    
        g_error     := 'DATE N / ' || l_params;
        l_date_tstz := i_dt_issued - INTERVAL '1' SECOND;
    
        g_error := 'P1_TRACKING N / ID_EXT_REQ=' || l_exr_row.id_external_request || ' / ' || l_params;
        l_tracking_tab(l_tracking_idx).ext_req_status := pk_ref_constant.g_p1_status_n;
        l_tracking_tab(l_tracking_idx).id_external_request := l_exr_row.id_external_request;
        l_tracking_tab(l_tracking_idx).id_institution := l_id_inst_orig;
        l_tracking_tab(l_tracking_idx).id_professional := l_prof_interface.id;
        l_tracking_tab(l_tracking_idx).flg_type := pk_ref_constant.g_tracking_type_s;
        l_tracking_tab(l_tracking_idx).id_prof_dest := NULL;
        l_tracking_tab(l_tracking_idx).id_dep_clin_serv := NULL;
        l_tracking_tab(l_tracking_idx).round_id := l_round;
        l_tracking_tab(l_tracking_idx).reason_code := NULL;
        l_tracking_tab(l_tracking_idx).flg_reschedule := NULL;
        l_tracking_tab(l_tracking_idx).flg_subtype := NULL;
        l_tracking_tab(l_tracking_idx).decision_urg_level := NULL;
        l_tracking_tab(l_tracking_idx).dt_tracking_tstz := l_date_tstz;
        l_tracking_tab(l_tracking_idx).dt_create := l_dt_create;
        l_tracking_tab(l_tracking_idx).id_reason_code := NULL;
        l_tracking_tab(l_tracking_idx).id_schedule := NULL;
        l_tracking_tab(l_tracking_idx).id_inst_dest := l_id_inst_dest;
        l_tracking_tab(l_tracking_idx).id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_n);
        l_tracking_tab(l_tracking_idx).id_speciality := l_exr_row.id_speciality;
    
        g_error                  := 'P1_EXTERNAL_REQUEST N / ' || l_params;
        l_exr_row.dt_status_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
    
        -- inserting justification    
        g_error := 'REASON / ' || l_params;
        IF i_justification IS NOT NULL
        THEN
            FOR i IN 1 .. i_justification.count
            LOOP
                IF i_justification(i) IS NOT NULL
                THEN
                    g_error := 'P1_DETAIL REASON ' || i || ' / ' || l_params;
                    l_detail_idx := l_detail_idx + 1;
                    l_detail_tab(l_detail_idx).id_detail := seq_p1_detail.nextval;
                    l_detail_tab(l_detail_idx).id_external_request := l_exr_row.id_external_request;
                    l_detail_tab(l_detail_idx).text := i_justification(i);
                    l_detail_tab(l_detail_idx).flg_type := pk_ref_constant.g_detail_type_jstf;
                    l_detail_tab(l_detail_idx).id_professional := l_prof_interface.id;
                    l_detail_tab(l_detail_idx).id_institution := l_id_inst_orig;
                    l_detail_tab(l_detail_idx).id_tracking := l_tracking_tab(l_tracking_idx).id_tracking;
                    l_detail_tab(l_detail_idx).flg_status := pk_ref_constant.g_active;
                    l_detail_tab(l_detail_idx).dt_insert_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
                END IF;
            END LOOP;
        END IF;
    
        -- ACM, 2011-04-01: ALERT-156898 - inserting flg_priority and flg_home values
        g_error := 'P1_DETAIL FLG_PRIORITY / ' || l_params;
        l_detail_idx := l_detail_idx + 1;
        l_detail_tab(l_detail_idx).id_detail := seq_p1_detail.nextval;
        l_detail_tab(l_detail_idx).id_external_request := l_exr_row.id_external_request;
        l_detail_tab(l_detail_idx).text := l_exr_row.flg_priority;
        l_detail_tab(l_detail_idx).flg_type := pk_ref_constant.g_detail_type_fpriority;
        l_detail_tab(l_detail_idx).id_professional := l_prof_interface.id;
        l_detail_tab(l_detail_idx).id_institution := l_id_inst_orig;
        l_detail_tab(l_detail_idx).id_tracking := l_tracking_tab(l_tracking_idx).id_tracking;
        l_detail_tab(l_detail_idx).flg_status := pk_ref_constant.g_active;
        l_detail_tab(l_detail_idx).dt_insert_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
    
        g_error := 'P1_DETAIL FLG_HOME / ' || l_params;
        l_detail_idx := l_detail_idx + 1;
        l_detail_tab(l_detail_idx).id_detail := seq_p1_detail.nextval;
        l_detail_tab(l_detail_idx).id_external_request := l_exr_row.id_external_request;
        l_detail_tab(l_detail_idx).text := l_exr_row.flg_home;
        l_detail_tab(l_detail_idx).flg_type := pk_ref_constant.g_detail_type_fhome;
        l_detail_tab(l_detail_idx).id_professional := l_prof_interface.id;
        l_detail_tab(l_detail_idx).id_institution := l_id_inst_orig;
        l_detail_tab(l_detail_idx).id_tracking := l_tracking_tab(l_tracking_idx).id_tracking;
        l_detail_tab(l_detail_idx).flg_status := pk_ref_constant.g_active;
        l_detail_tab(l_detail_idx).dt_insert_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
    
        -- I - Issued
        g_error := 'STATUS I / ' || l_params;
        l_tracking_idx := l_tracking_idx + 1;
        l_tracking_tab(l_tracking_idx).id_tracking := ts_p1_tracking.next_key();
    
        g_error     := 'DATE I / ' || l_params;
        l_date_tstz := l_date_tstz + INTERVAL '1' SECOND;
        l_dt_create := l_dt_create + INTERVAL '1' SECOND;
    
        g_error := 'P1_TRACKING I / ID_EXT_REQ=' || l_exr_row.id_external_request || ' / ' || l_params;
        l_tracking_tab(l_tracking_idx).ext_req_status := pk_ref_constant.g_p1_status_i;
        l_tracking_tab(l_tracking_idx).id_external_request := l_exr_row.id_external_request;
        l_tracking_tab(l_tracking_idx).id_institution := l_id_inst_orig;
        l_tracking_tab(l_tracking_idx).id_professional := l_prof_interface.id;
        l_tracking_tab(l_tracking_idx).flg_type := pk_ref_constant.g_tracking_type_s;
        l_tracking_tab(l_tracking_idx).id_prof_dest := NULL;
        l_tracking_tab(l_tracking_idx).id_dep_clin_serv := i_id_dep_clin_serv;
        l_tracking_tab(l_tracking_idx).round_id := l_round;
        l_tracking_tab(l_tracking_idx).reason_code := NULL;
        l_tracking_tab(l_tracking_idx).flg_reschedule := NULL;
        l_tracking_tab(l_tracking_idx).flg_subtype := NULL;
        l_tracking_tab(l_tracking_idx).decision_urg_level := NULL;
        l_tracking_tab(l_tracking_idx).dt_tracking_tstz := l_date_tstz;
        l_tracking_tab(l_tracking_idx).dt_create := l_dt_create;
        l_tracking_tab(l_tracking_idx).id_reason_code := NULL;
        l_tracking_tab(l_tracking_idx).id_schedule := NULL;
        l_tracking_tab(l_tracking_idx).id_inst_dest := NULL;
        l_tracking_tab(l_tracking_idx).id_speciality := l_exr_row.id_speciality;
        l_tracking_tab(l_tracking_idx).id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_i);
        l_tracking_tab(l_tracking_idx).id_speciality := l_exr_row.id_speciality;
    
        g_error                  := 'P1_EXTERNAL_REQUEST I / ' || l_params;
        l_exr_row.dt_status_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
        l_exr_row.id_prof_status := l_tracking_tab(l_tracking_idx).id_professional;
    
        -- inserting import notes into p1_detail.flg_type=12 (Notes from the Primary Care Center Registrar)
        g_error := 'P1_DETAIL IMPORT NOTES / ' || l_params;
        l_detail_idx := l_detail_idx + 1;
        l_detail_tab(l_detail_idx).id_detail := seq_p1_detail.nextval;
    
        g_error := 'inst name / ' || l_params;
        IF l_inst_name IS NOT NULL
        THEN
            l_text_notes := l_text_notes || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_adm_p1_t022) || ': ' ||
                            l_inst_name;
        END IF;
    
        g_error := 'prof name / ' || l_params;
        IF i_prof_name IS NOT NULL
        THEN
            l_text_notes := l_text_notes || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t077) || ': ' ||
                            i_prof_name;
        
        ELSE
            l_text_notes := l_text_notes || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t077) || ': ' ||
                            pk_prof_utils.get_name(i_lang, l_prof.id);
        
        END IF;
    
        g_error := 'IMPORT NOTES / ' || l_params;
        l_detail_tab(l_detail_idx).id_external_request := l_exr_row.id_external_request;
        l_detail_tab(l_detail_idx).text := l_text_notes;
        l_detail_tab(l_detail_idx).flg_type := pk_ref_constant.g_detail_type_admi;
        l_detail_tab(l_detail_idx).id_professional := l_prof_interface.id;
        l_detail_tab(l_detail_idx).id_institution := l_id_inst_orig;
        l_detail_tab(l_detail_idx).id_tracking := l_tracking_tab(l_tracking_idx).id_tracking;
        l_detail_tab(l_detail_idx).flg_status := pk_ref_constant.g_active;
        l_detail_tab(l_detail_idx).dt_insert_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
    
        IF i_flg_status != pk_ref_constant.g_p1_status_i
        THEN
            g_error := 'CASE / ' || l_params;
            CASE
                WHEN i_flg_status IN
                     (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_a, pk_ref_constant.g_p1_status_s) THEN
                
                    -- T - Triage                   
                    g_error := 'STATUS T / ' || l_params;
                    pk_alertlog.log_debug(g_error);
                
                    l_tracking_idx := l_tracking_idx + 1;
                    l_tracking_tab(l_tracking_idx).id_tracking := ts_p1_tracking.next_key();
                
                    g_error     := 'DATE T / ' || l_params;
                    l_date_tstz := i_dt_triage + INTERVAL '2' SECOND;
                    l_dt_create := l_dt_create + INTERVAL '2' SECOND;
                
                    g_error := 'P1_TRACKING T / ID_EXT_REQ=' || l_exr_row.id_external_request || ' / ' || l_params;
                    l_tracking_tab(l_tracking_idx).ext_req_status := pk_ref_constant.g_p1_status_t;
                    l_tracking_tab(l_tracking_idx).id_external_request := l_exr_row.id_external_request;
                    l_tracking_tab(l_tracking_idx).id_institution := l_id_inst_dest;
                    l_tracking_tab(l_tracking_idx).id_professional := l_prof_interface.id;
                    l_tracking_tab(l_tracking_idx).flg_type := pk_ref_constant.g_tracking_type_s;
                    l_tracking_tab(l_tracking_idx).id_prof_dest := NULL;
                    l_tracking_tab(l_tracking_idx).id_dep_clin_serv := i_id_dep_clin_serv;
                    l_tracking_tab(l_tracking_idx).round_id := l_round;
                    l_tracking_tab(l_tracking_idx).reason_code := NULL;
                    l_tracking_tab(l_tracking_idx).flg_reschedule := NULL;
                    l_tracking_tab(l_tracking_idx).flg_subtype := NULL;
                    l_tracking_tab(l_tracking_idx).decision_urg_level := NULL;
                    l_tracking_tab(l_tracking_idx).dt_tracking_tstz := l_date_tstz;
                    l_tracking_tab(l_tracking_idx).dt_create := l_dt_create;
                    l_tracking_tab(l_tracking_idx).id_reason_code := NULL;
                    l_tracking_tab(l_tracking_idx).id_schedule := NULL;
                    l_tracking_tab(l_tracking_idx).id_inst_dest := NULL;
                    l_tracking_tab(l_tracking_idx).id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_t);
                
                    g_error                  := 'P1_EXTERNAL_REQUEST T / ' || l_params;
                    l_exr_row.dt_status_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
                    l_exr_row.id_prof_status := l_tracking_tab(l_tracking_idx).id_professional;
                
                    IF i_flg_status IN (pk_ref_constant.g_p1_status_a, pk_ref_constant.g_p1_status_s)
                    THEN
                    
                        g_error := 'STATUS A / ' || l_params;
                        l_tracking_idx := l_tracking_idx + 1;
                        l_tracking_tab(l_tracking_idx).id_tracking := ts_p1_tracking.next_key();
                    
                        g_error     := 'DATE A / ' || l_params;
                        l_date_tstz := i_dt_accepted + INTERVAL '3' SECOND;
                        l_dt_create := l_dt_create + INTERVAL '3' SECOND;
                    
                        g_error := 'P1_TRACKING A / ID_EXT_REQ=' || l_exr_row.id_external_request || ' / ' || l_params;
                        l_tracking_tab(l_tracking_idx).ext_req_status := pk_ref_constant.g_p1_status_a;
                        l_tracking_tab(l_tracking_idx).id_external_request := l_exr_row.id_external_request;
                        l_tracking_tab(l_tracking_idx).id_institution := l_id_inst_dest;
                        l_tracking_tab(l_tracking_idx).id_professional := l_prof_interface.id;
                        l_tracking_tab(l_tracking_idx).flg_type := pk_ref_constant.g_tracking_type_s;
                        l_tracking_tab(l_tracking_idx).id_prof_dest := NULL; -- nao fica preenchido o prof sugerido na marcacao
                        l_tracking_tab(l_tracking_idx).id_dep_clin_serv := i_id_dep_clin_serv;
                        l_tracking_tab(l_tracking_idx).round_id := l_round;
                        l_tracking_tab(l_tracking_idx).reason_code := NULL;
                        l_tracking_tab(l_tracking_idx).flg_reschedule := NULL;
                        l_tracking_tab(l_tracking_idx).flg_subtype := NULL;
                        l_tracking_tab(l_tracking_idx).decision_urg_level := pk_ref_constant.g_decision_urg_level_normal;
                        l_tracking_tab(l_tracking_idx).dt_tracking_tstz := l_date_tstz;
                        l_tracking_tab(l_tracking_idx).dt_create := l_dt_create;
                        l_tracking_tab(l_tracking_idx).id_reason_code := NULL;
                        l_tracking_tab(l_tracking_idx).id_schedule := NULL;
                        l_tracking_tab(l_tracking_idx).id_inst_dest := NULL;
                        l_tracking_tab(l_tracking_idx).id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_a);
                    
                        g_error                      := 'P1_EXTERNAL_REQUEST A / ' || l_params;
                        l_exr_row.dt_status_tstz     := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
                        l_exr_row.decision_urg_level := pk_ref_constant.g_decision_urg_level_normal;
                        l_exr_row.id_prof_status     := l_tracking_tab(l_tracking_idx).id_professional;
                    
                    END IF;
                
                    IF i_flg_status = pk_ref_constant.g_p1_status_s
                    THEN
                    
                        -- S - Scheduled 
                        g_error := 'STATUS S / ID_EXT_REQ=' || l_exr_row.id_external_request || ' / ' || l_params;
                    
                        -- Identify scheduled professional
                        g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_num_order => i_num_order_sch,
                                                                              i_prof_name => i_prof_name_sch,
                                                                              i_dcs       => i_id_dep_clin_serv,
                                                                              o_id_prof   => l_id_prof_sch,
                                                                              o_error     => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    
                        --  ALERT-88669: DT_SCHEDULE_TSTZ must have the value l_current_timestamp (this is schedule creation date)
                        g_error            := 'SCHEDULING calc dates / ' || l_params;
                        l_dt_schedule_tstz := l_current_timestamp;
                        l_dt_begin_tstz    := i_appoitment_date;
                    
                        -- todo: isto nao pode ficar assim... tem q ser alterado por uma funcao q apenas faca o agendamento (sem alterar o estado do P1)
                    
                        -- Scheduling the appointment - BEGIN
                        -- Insert into schedule
                        g_error := 'INSERT INTO SCHEDULE / ID_PROF=' || l_id_prof_sch || '|ID_INST=' ||
                                   l_prof_interface.institution || '|DCS=' || i_id_dep_clin_serv || '|ID_SCH_REF=' ||
                                   l_exr_row.id_schedule || '|APPOITMENT_DATE=' || i_appoitment_date || ' / ' ||
                                   l_params;
                        INSERT INTO schedule
                            (id_schedule,
                             id_instit_requests,
                             id_instit_requested,
                             id_dcs_requested,
                             id_prof_requests,
                             id_prof_schedules,
                             flg_urgency,
                             dt_schedule_tstz,
                             flg_status,
                             dt_begin_tstz,
                             id_schedule_ref,
                             id_sch_event)
                        VALUES
                            (seq_schedule.nextval,
                             l_prof_interface.institution,
                             l_prof_interface.institution,
                             i_id_dep_clin_serv,
                             l_id_prof_sch,
                             l_id_prof_sch,
                             pk_ref_constant.g_sched_urg_n,
                             l_dt_schedule_tstz,
                             pk_ref_constant.g_sched_status_a,
                             l_dt_begin_tstz,
                             l_exr_row.id_schedule,
                             pk_ref_constant.g_sch_event_1)
                        RETURNING id_schedule INTO l_id_schedule;
                    
                        -- Insert into schedule_outp
                        g_error := 'INSERT INTO SCHEDULE_OUTP / ' || l_params;
                        INSERT INTO schedule_outp
                            (id_schedule_outp,
                             id_schedule,
                             dt_target_tstz,
                             flg_state,
                             flg_sched,
                             id_software,
                             id_epis_type,
                             flg_type)
                        VALUES
                            (seq_schedule_outp.nextval,
                             l_id_schedule,
                             i_appoitment_date, --pk_date_utils.get_string_tstz(i_lang, l_prof_interface, i_date, NULL),
                             pk_ref_constant.g_sched_outp_status_a,
                             pk_ref_constant.g_sched_outp_sched_p,
                             l_prof_interface.software,
                             l_id_epis_type,
                             pk_ref_constant.g_consult_type_first)
                        RETURNING id_schedule_outp INTO l_schedout;
                    
                        -- Insert into sch_prof_outp
                        g_error := 'INSERT INTO SCH_PROF_OUTP / ' || l_params;
                        INSERT INTO sch_prof_outp
                            (id_sch_prof_outp, id_professional, id_schedule_outp)
                        VALUES
                            (seq_sch_prof_outp.nextval, l_id_prof_sch, l_schedout);
                    
                        -- Insert into sch_group                
                        MERGE INTO sch_group sg
                        USING (SELECT l_id_schedule id_schedule, l_exr_row.id_patient id_patient
                                 FROM dual) t
                        ON (t.id_schedule = sg.id_schedule AND t.id_patient = sg.id_patient)
                        WHEN NOT MATCHED THEN
                            INSERT
                                (id_group, id_schedule, id_patient)
                            VALUES
                                (seq_sch_group.nextval, l_id_schedule, l_exr_row.id_patient);
                    
                        -- Scheduling the appointment - END
                        l_tracking_idx := l_tracking_idx + 1;
                        l_tracking_tab(l_tracking_idx).id_tracking := ts_p1_tracking.next_key();
                    
                        g_error     := 'DATE S / ' || l_params;
                        l_date_tstz := i_dt_scheduled + INTERVAL '4' SECOND;
                        l_dt_create := l_dt_create + INTERVAL '4' SECOND;
                    
                        g_error := 'P1_TRACKING S / ID_EXT_REQ=' || l_exr_row.id_external_request || ' / ' || l_params;
                        l_tracking_tab(l_tracking_idx).ext_req_status := pk_ref_constant.g_p1_status_s;
                        l_tracking_tab(l_tracking_idx).id_external_request := l_exr_row.id_external_request;
                        l_tracking_tab(l_tracking_idx).id_institution := l_id_inst_dest;
                        l_tracking_tab(l_tracking_idx).id_professional := l_prof_interface.id; -- interface
                        l_tracking_tab(l_tracking_idx).flg_type := pk_ref_constant.g_tracking_type_s;
                        l_tracking_tab(l_tracking_idx).id_prof_dest := NULL;
                        l_tracking_tab(l_tracking_idx).id_dep_clin_serv := i_id_dep_clin_serv;
                        l_tracking_tab(l_tracking_idx).round_id := l_round;
                        l_tracking_tab(l_tracking_idx).reason_code := NULL;
                        l_tracking_tab(l_tracking_idx).flg_reschedule := NULL;
                        l_tracking_tab(l_tracking_idx).flg_subtype := NULL;
                        l_tracking_tab(l_tracking_idx).decision_urg_level := NULL;
                        l_tracking_tab(l_tracking_idx).dt_tracking_tstz := l_date_tstz;
                        l_tracking_tab(l_tracking_idx).dt_create := l_dt_create;
                        l_tracking_tab(l_tracking_idx).id_reason_code := NULL;
                        l_tracking_tab(l_tracking_idx).id_schedule := l_id_schedule;
                        l_tracking_tab(l_tracking_idx).id_inst_dest := NULL;
                        l_tracking_tab(l_tracking_idx).id_workflow_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_s);
                    
                        g_error                  := 'P1_EXTERNAL_REQUEST S / ' || l_params;
                        l_exr_row.dt_status_tstz := l_tracking_tab(l_tracking_idx).dt_tracking_tstz;
                        l_exr_row.id_schedule    := l_id_schedule;
                        l_exr_row.id_prof_status := l_tracking_tab(l_tracking_idx).id_professional;
                    
                    END IF;
                ELSE
                    g_error := 'FLG_STATUS ' || i_flg_status || ' not found / ' || l_params;
                    RAISE g_exception;
            END CASE;
        
        END IF;
    
        -- inserting data into tables
        -- p1_external_request
        g_error := 'Calling ts_p1_external_request.upd id=' || l_exr_row.id_external_request || ' / ' || l_params;
        ts_p1_external_request.ins(rec_in => l_exr_row, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF o_error.err_desc IS NOT NULL
        THEN
            g_error := 't_data_gov_mnt.process_insert error=' || o_error.err_desc || ' / ' || l_params;
            pk_alertlog.log_debug(g_error);
        END IF;
    
        -- p1_tracking
        l_rowids := NULL;
        FOR i IN 1 .. l_tracking_tab.count
        LOOP
            g_error := 'Calling ts_p1_tracking.ins EXT_REQ=' || l_tracking_tab(i).id_external_request ||
                       ' EXT_REQ_STATUS=' || l_tracking_tab(i).ext_req_status || ' FLG_TYPE=' || l_tracking_tab(i)
                      .flg_type || ' / ' || l_params;
            ts_p1_tracking.ins(rec_in          => l_tracking_tab(i),
                               gen_pky_in      => FALSE,
                               handle_error_in => TRUE,
                               rows_out        => l_rowids);
        
        END LOOP;
    
        g_error := 'process_insert P1_TRACKING / ' || l_params;
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_TRACKING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF o_error.err_desc IS NOT NULL
        THEN
            g_error := 't_data_gov_mnt.process_insert error=' || o_error.err_desc || ' / ' || l_params;
            pk_alertlog.log_debug(g_error);
        END IF;
    
        -- p1_detail        
        g_error := 'INSERT INTO p1_detail / ' || l_params;
        FORALL i IN 1 .. l_detail_tab.count
            INSERT INTO p1_detail
            VALUES l_detail_tab
                (i);
    
        g_error               := 'o_id_external_request / ' || l_params;
        o_id_external_request := l_exr_row.id_external_request;
    
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
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'IMPORT_REFERRAL',
                                                     o_error    => o_error);
    END import_referral;

    FUNCTION get_referrals_to_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_inst_dest_list IN table_number,
        i_ref_type       IN table_varchar,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_schedule    IN schedule.dt_schedule_tstz%TYPE,
        o_ref_list       OUT pk_ref_ext_sys.ref_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message VARCHAR2(4000);
        l_title   VARCHAR2(4000);
        l_buttons VARCHAR2(4000);
    BEGIN
        g_error := 'Call pk_ref_ext_sys.get_pat_ref_to_schedule / i_patient=' || i_patient || ' i_dcs=' || i_dcs;
        IF NOT pk_ref_ext_sys.get_pat_ref_to_schedule(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_patient        => i_patient,
                                                      i_type           => i_ref_type,
                                                      i_schedule       => NULL,
                                                      i_inst_dest_list => i_inst_dest_list,
                                                      i_dcs            => i_dcs,
                                                      i_dt_schedule    => i_dt_schedule,
                                                      o_p1             => o_ref_list,
                                                      o_message        => l_message,
                                                      o_title          => l_title,
                                                      o_buttons        => l_buttons,
                                                      o_error          => o_error)
        
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
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_REFERRALS_TO_SCHEDULE',
                                                     o_error    => o_error);
        
    END get_referrals_to_schedule;

    /**
    * Checks if this referral has conditions to be migrated
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_ref_row           Referral data
    * @param   i_id_inst_dest      Dest institution identifier
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION check_ref_conditions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ref_row      IN p1_external_request%ROWTYPE,
        i_id_inst_dest IN institution.id_institution%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
        g_error := 'Init check_ref_conditions / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow || ' NEW ID_INST_DEST=' || i_id_inst_dest;
    
        -- check workflow
        IF i_ref_row.id_workflow IS NOT NULL
           AND i_ref_row.id_workflow != pk_ref_constant.g_wf_pcc_hosp
        THEN
            g_error := 'Invalid workflow. Referral ID=' || i_ref_row.id_external_request || ' / ID_WORKFLOW=' ||
                       i_ref_row.id_workflow;
            --g_error := 'Workflow inválido. Referral ID=' || i_ref_row.id_external_request || ' / ID_WORKFLOW=' ||i_ref_row.id_workflow;
            RAISE g_exception;
        END IF;
    
        -- check id_inst_dest
        IF i_id_inst_dest = i_ref_row.id_inst_dest
        THEN
            g_error := 'New dest institution must be different from the actual dest institution / ID_REF=' ||
                       i_ref_row.id_external_request || ' New ID_INST_DEST=' || i_id_inst_dest ||
                       ' Actual ID_INST_DEST=' || i_ref_row.id_inst_dest;
            --g_error := 'A nova instituição de destino tem que ser diferente da actual / ID_REF=' ||
            --           i_ref_row.id_external_request || ' New ID_INST_DEST=' || i_id_inst_dest ||
            --           ' Actual ID_INST_DEST=' || i_ref_row.id_inst_dest;
            RAISE g_exception;
        END IF;
    
        -- check flg_status
        g_error := 'FLG_STATUS=' || i_ref_row.flg_status || ' / ID_REF=' || i_ref_row.id_external_request ||
                   ' FLG_STATUS=' || i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow || ' NEW ID_INST_DEST=' ||
                   i_id_inst_dest;
        IF i_ref_row.flg_status NOT IN (pk_ref_constant.g_p1_status_o,
                                        pk_ref_constant.g_p1_status_n,
                                        pk_ref_constant.g_p1_status_i,
                                        pk_ref_constant.g_p1_status_b,
                                        pk_ref_constant.g_p1_status_t,
                                        pk_ref_constant.g_p1_status_d,
                                        pk_ref_constant.g_p1_status_r,
                                        pk_ref_constant.g_p1_status_a,
                                        pk_ref_constant.g_p1_status_z
                                        -- todo: descomentar
                                        --,pk_ref_constant.g_p1_status_s 
                                        --,pk_ref_constant.g_p1_status_m
                                        )
        THEN
            g_error := 'The current status does not allow this operation. Referral ID=' ||
                       i_ref_row.id_external_request || ' / FLG_STATUS=' || i_ref_row.flg_status;
            --g_error := 'O estado actual do pedido não permite esta operaçãoThe current status does not allow this operation. Referral ID=' ||
            --           i_ref_row.id_external_request || ' / FLG_STATUS=' || i_ref_row.flg_status; 
            RAISE g_exception;
        END IF;
    
        -- check if p1_speciality can be referenced to i_id_inst_dest for the specified speciality
        g_error := 'ID_SPEC=' || i_ref_row.id_speciality || ' ID_INST_ORIG=' || i_ref_row.id_inst_orig ||
                   ' ID_INST_DEST=' || i_id_inst_dest || ' FLG_TYPE=' || i_ref_row.flg_type || ' ID_EXTERNAL_SYS=' ||
                   i_ref_row.id_external_sys || ' / ID_REF=' || i_ref_row.id_external_request;
    
        -- external referrals only (id_workflow is null)
        SELECT COUNT(1)
          INTO l_count
          FROM v_ref_network v
         WHERE v.flg_type = i_ref_row.flg_type
           AND v.id_inst_orig = i_ref_row.id_inst_orig
           AND v.id_institution = i_id_inst_dest
           AND v.id_speciality = i_ref_row.id_speciality
           AND v.id_external_sys IN (nvl(i_ref_row.id_external_sys, 0), 0);
    
        IF l_count = 0
        THEN
            g_error := 'Speciality "' ||
                       pk_translation.get_translation(i_lang,
                                                      'P1_SPECIALITY.CODE_SPECIALITY.' || i_ref_row.id_speciality) ||
                       '" (id=' || i_ref_row.id_speciality || ') not available from institution "' ||
                       pk_translation.get_translation(1, pk_ref_constant.g_institution_code || i_ref_row.id_inst_orig) ||
                       '" (id=' || i_ref_row.id_inst_orig || ') to institution "' ||
                       pk_translation.get_translation(1, pk_ref_constant.g_institution_code || i_id_inst_dest) ||
                       '" (id=' || i_id_inst_dest || '). Referral ID=' || i_ref_row.id_external_request;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            --IF g_error_code IS NOT NULL
            --THEN
            g_flg_action := pk_ref_constant.g_err_flg_action_u;
            g_error_desc := g_error;
            --ELSE
            --    g_error_code := SQLCODE;
            --    g_error_desc := SQLERRM;
            --    g_flg_action := pk_ref_constant.g_err_flg_action_s;
            --END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'CHECK_REF_CONDITIONS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END check_ref_conditions;

    /**
    * Maps the 
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_definition        Origin definition
    * @param   i_old_value         Value to be mapped
    * @param   i_definition_get    Definition to be got
    * @param   o_new_value         New value
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION get_mapped_value
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_definition     IN VARCHAR2,
        i_old_value      IN VARCHAR2,
        i_definition_get IN VARCHAR2,
        o_new_value      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_out  VARCHAR2(1000 CHAR);
        l_new_id_tab pk_map.map_table;
        l_new_id_ibt pk_map.map_type;
        l_count      NUMBER;
    BEGIN
        g_error := 'Init get_mapped_value / i_definition=' || i_definition || ' i_old_value=' || i_old_value;
        IF i_definition_get IS NULL
        THEN
            g_error := 'i_definition_get is null';
            RAISE g_exception;
        END IF;
    
        l_count := pk_map.get_maps_a_b(i_a_system       => pk_ref_constant.g_map_system_alert,
                                       i_b_system       => pk_ref_constant.g_map_system_alert,
                                       i_a_value        => i_old_value,
                                       i_a_definition   => i_definition,
                                       i_id_institution => i_prof.institution,
                                       i_id_software    => i_prof.software,
                                       o_b_values       => l_new_id_tab,
                                       o_error          => l_error_out);
    
        g_error := i_definition || ' calculated from MAP table / count result=' || l_count ||
                   ' / SELECT b_value FROM maps WHERE a_system = ''' || pk_ref_constant.g_map_system_alert ||
                   ''' AND a_def = ''' || i_definition || ''' AND a_value = ' || i_old_value || ' AND b_system = ''' ||
                   pk_ref_constant.g_map_system_alert || ''' AND b_def = ''' || i_definition_get ||
                   ''' AND id_institution = ' || i_prof.institution || ' AND id_software = ' || i_prof.software || '';
    
        IF l_count > 0
        THEN
        
            g_error      := i_definition || ' to ' || i_definition_get || ' calculated from MAP table / OLD VALUE=' ||
                            i_old_value || ' / count result=' || l_count;
            l_new_id_ibt := l_new_id_tab(l_new_id_tab.first); -- several definitions can map old value
        
            IF l_new_id_ibt.exists(i_definition_get)
            THEN
                o_new_value := l_new_id_ibt(i_definition_get);
            END IF;
        
            /*ELSE
            g_error := 'Error mapping ' || i_definition || ' for ID_INSTITUTION=' || i_prof.institution ||
                       ' / count result=' || l_new_id_tab.count || ' / SELECT b_value FROM maps WHERE a_system = ''' ||
                       pk_ref_constant.g_map_system_alert || ''' AND a_def = ''' || i_definition || ''' AND a_value = ' ||
                       i_old_value || ' AND b_system = ''' || pk_ref_constant.g_map_system_alert || ''' AND b_def = ''' ||
                       i_definition_get || ''' AND id_institution = ' || i_prof.institution || ' AND id_software = ' ||
                       i_prof.software || '';
            RAISE g_exception;*/
        ELSE
            g_error := 'Error mapping ' || i_definition || ' for ID_INSTITUTION=' || i_prof.institution ||
                       ' / count result=' || l_new_id_tab.count || ' / SELECT b_value FROM maps WHERE a_system = ''' ||
                       pk_ref_constant.g_map_system_alert || ''' AND a_def = ''' || i_definition || ''' AND a_value = ' ||
                       i_old_value || ' AND b_system = ''' || pk_ref_constant.g_map_system_alert || ''' AND b_def = ''' ||
                       i_definition_get || ''' AND id_institution = ' || i_prof.institution || ' AND id_software = ' ||
                       i_prof.software || '';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'GET_MAPPED_VALUE',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_mapped_value;

    /**
    * Set clinical record and sequential number in the new institution
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_patient        Referral data
    * @param   i_id_institution    New destination institution identifier
    * @param   i_flg_ws            Flag indicating if this referral is beeing called by webservice or not (different behaviour) in dest institution
    * @param   o_id_match          Patient sequential number
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_flg_ws            {*} Y- webservice behaviour {*} N- otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2012
    */
    FUNCTION set_match
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN p1_external_request.id_patient%TYPE,
        i_id_inst_dest_new IN p1_external_request.id_inst_dest%TYPE,
        i_id_inst_dest_old IN p1_external_request.id_inst_dest%TYPE,
        i_flg_ws           IN VARCHAR2,
        o_id_match_new     OUT p1_match.id_match%TYPE,
        o_num_cr_new       OUT clin_record.num_clin_record%TYPE,
        o_seq_num_new      OUT p1_match.sequential_number%TYPE,
        o_id_match_old     OUT p1_match.id_match%TYPE,
        o_num_cr_old       OUT clin_record.num_clin_record%TYPE,
        o_seq_num_old      OUT p1_match.sequential_number%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_cr    clin_record.id_clin_record%TYPE;
        l_new_prof profissional;
    
        l_id_match_tab   table_number;
        l_id_inst_tab    table_number;
        l_seq_number_tab table_varchar;
        l_num_cr_tab     table_varchar;
    
        CURSOR c_match IS
            SELECT id_match, id_institution, m.sequential_number
              FROM p1_match m
             WHERE id_patient = i_id_patient
               AND id_institution IN (i_id_inst_dest_new, i_id_inst_dest_old) -- old and new institutions
               AND flg_status = pk_ref_constant.g_active
             ORDER BY m.dt_create_tstz DESC;
    
        CURSOR c_clin_rec IS
            SELECT cr.num_clin_record, cr.id_institution
              FROM clin_record cr
             WHERE cr.id_patient = i_id_patient
               AND cr.id_institution IN (i_id_inst_dest_new, i_id_inst_dest_old) -- old and new institutions
               AND cr.id_instit_enroled = cr.id_institution
               AND cr.flg_status = pk_ref_constant.g_active
             ORDER BY cr.id_clin_record DESC;
    BEGIN
        --g_error := 'Init set_match / i_id_patient=' || i_id_patient || ' i_flg_ws=' || i_flg_ws;
    
        -- g_ref_mig_row.num_clin_record - patient clinical record in the new institution 
        g_error    := 'i_flg_ws=' || i_flg_ws || ' / ID_PATIENT=' || i_id_patient || ' NEW CLIN_RECORD=' ||
                      g_ref_mig_row.num_clin_record || ' NEW SEQUENTIAL_NUMBER=' || g_ref_mig_row.sequential_number;
        l_new_prof := profissional(i_prof.id, i_id_inst_dest_new, i_prof.software);
        CASE i_flg_ws
            WHEN pk_ref_constant.g_yes THEN
            
                -- behaviour as if dest institution is using referral webservices
                g_error := 'OPEN c_clin_rec / ID_PATIENT=' || i_id_patient || ' ID_INST_DEST_NEW=' ||
                           i_id_inst_dest_new || ' ID_INST_DEST_OLD=' || i_id_inst_dest_old;
            
                OPEN c_clin_rec;
                FETCH c_clin_rec BULK COLLECT
                    INTO l_num_cr_tab, l_id_inst_tab;
                CLOSE c_clin_rec;
            
                g_error := 'FOR i IN 1 .. ' || l_num_cr_tab.count || ' / ID_PATIENT=' || i_id_patient ||
                           ' ID_INST_DEST_NEW=' || i_id_inst_dest_new || ' ID_INST_DEST_OLD=' || i_id_inst_dest_old;
                FOR i IN 1 .. l_num_cr_tab.count
                LOOP
                    IF l_id_inst_tab(i) = i_id_inst_dest_new
                    THEN
                        -- new institution
                        o_num_cr_new := l_num_cr_tab(i);
                    ELSIF l_id_inst_tab(i) = i_id_inst_dest_old
                    THEN
                        -- old institution
                        o_num_cr_old := l_num_cr_tab(i);
                    END IF;
                END LOOP;
            
                -- if this patient has already a clinical_record for the new institution, do not update
                IF o_num_cr_new IS NULL
                THEN
                    g_error      := 'o_num_cr_new / o_num_cr_new=' || o_num_cr_new || ' g_ref_mig_row.num_clin_record=' ||
                                    g_ref_mig_row.num_clin_record;
                    o_num_cr_new := g_ref_mig_row.num_clin_record;
                
                    IF o_num_cr_new IS NOT NULL
                    THEN
                        g_error  := 'Call pk_ref_dest_reg.set_clin_record / ID_PATIENT=' || i_id_patient ||
                                    ' NUM_CLIN_RECORD=' || o_num_cr_new;
                        g_retval := pk_ref_dest_reg.set_clin_record(i_lang         => i_lang,
                                                                    i_prof         => l_new_prof, -- must have the new institution id
                                                                    i_pat          => i_id_patient,
                                                                    i_num_clin_rec => o_num_cr_new,
                                                                    i_epis         => NULL,
                                                                    o_id_clin_rec  => l_id_cr,
                                                                    o_error        => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'ERROR: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                END IF;
            
            WHEN pk_ref_constant.g_no THEN
                -- behaviour as if dest institution is using referral screens
                -- getting sequential number (mandatory)
                -- g_ref_mig_row.sequential_number - patient sequential number in the new institution
            
                g_error := 'open c_match / ID_PATIENT=' || i_id_patient || ' ID_INST_DEST_NEW=' || i_id_inst_dest_new ||
                           ' ID_INST_DEST_OLD=' || i_id_inst_dest_old;
                OPEN c_match;
                FETCH c_match BULK COLLECT
                    INTO l_id_match_tab, l_id_inst_tab, l_seq_number_tab;
                CLOSE c_match;
            
                g_error := 'FOR i IN 1 .. ' || l_id_match_tab.count || ' / ID_PATIENT=' || i_id_patient ||
                           ' ID_INST_DEST_NEW=' || i_id_inst_dest_new || ' ID_INST_DEST_OLD=' || i_id_inst_dest_old;
                FOR i IN 1 .. l_id_match_tab.count
                LOOP
                    IF l_id_inst_tab(i) = i_id_inst_dest_new
                    THEN
                        -- new institution
                        o_id_match_new := l_id_match_tab(i);
                        o_seq_num_new  := l_seq_number_tab(i);
                    ELSIF l_id_inst_tab(i) = i_id_inst_dest_old
                    THEN
                        -- old institution
                        o_id_match_old := l_id_match_tab(i);
                        o_seq_num_old  := l_seq_number_tab(i);
                    END IF;
                END LOOP;
            
                IF o_seq_num_new IS NULL
                THEN
                
                    g_error := 'o_num_cr_new / o_num_cr_new=' || o_num_cr_new || ' g_ref_mig_row.num_clin_record=' ||
                               g_ref_mig_row.num_clin_record || ' g_ref_mig_row.sequential_number=' ||
                               g_ref_mig_row.sequential_number;
                    --o_num_cr_new  := nvl(o_num_cr_new, g_ref_mig_row.num_clin_record);
                    o_num_cr_new  := g_ref_mig_row.num_clin_record;
                    o_seq_num_new := g_ref_mig_row.sequential_number;
                
                    -- sets match for this institution
                    IF o_seq_num_new IS NOT NULL
                    THEN
                        g_error  := 'Call pk_ref_dest_reg.set_match / ID_PATIENT=' || i_id_patient || ' SEQ_NUMBER=' ||
                                    o_seq_num_new || ' CLIN_REC=' || o_num_cr_new;
                        g_retval := pk_ref_dest_reg.set_match(i_lang     => i_lang,
                                                              i_prof     => l_new_prof, -- must have the new institution id,
                                                              i_pat      => i_id_patient,
                                                              i_seq_num  => o_seq_num_new,
                                                              i_clin_rec => o_num_cr_new,
                                                              i_epis     => NULL,
                                                              o_id_match => o_id_match_new,
                                                              o_error    => o_error);
                    
                        IF NOT g_retval
                        THEN
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                END IF;
            ELSE
                g_error := 'i_flg_ws=' || i_flg_ws;
                RAISE g_exception;
        END CASE;
    
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
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'SET_MATCH',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END set_match;

    /**
    * Checks if this referral has conditions to be migrated
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_ref_row           Referral data
    * @param   i_id_inst_dest_new  New dest institution identifier
    * @param   i_default_dcs       Indicates if dep_clin_serv is mapped or calculated by default
    * @param   i_notes             Notes associated to the migration
    * @param   i_op_date           Operation date
    * @param   i_flg_ws            Flag indicating if this referral is beeing called by webservice or not (different behaviour) in dest institution
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_default_dcs       {*} Y- calculated by default for the referral speciality {*} N- calculated from table MAP
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION mig_ref_dest_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ref_row          IN p1_external_request%ROWTYPE,
        i_id_inst_dest_new IN institution.id_institution%TYPE,
        i_default_dcs      IN VARCHAR2 DEFAULT pk_ref_constant.g_yes,
        i_notes            IN VARCHAR2 DEFAULT NULL,
        i_op_date          IN p1_tracking.dt_tracking_tstz%TYPE,
        i_flg_ws           IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_track_row          p1_tracking%ROWTYPE;
        l_prev_track_row     p1_tracking%ROWTYPE;
        l_round              p1_tracking.round_id%TYPE;
        l_id_dcs_new         p1_external_request.id_dep_clin_serv%TYPE;
        l_id_spec_new        p1_external_request.id_speciality%TYPE;
        l_ref_row            p1_external_request%ROWTYPE;
        l_id_prof_redirected professional.id_professional%TYPE;
        l_id_prof_scheduled  professional.id_professional%TYPE;
        l_sch_row            schedule%ROWTYPE;
        l_id_schedule        schedule.id_schedule%TYPE;
        l_dt_appointment_v   VARCHAR2(50 CHAR);
        l_count              PLS_INTEGER;
        l_flg_availability   p1_spec_dep_clin_serv.flg_availability%TYPE;
    
        l_num_cr_new   clin_record.num_clin_record%TYPE;
        l_num_cr_old   clin_record.num_clin_record%TYPE;
        l_id_match_new p1_match.id_match%TYPE;
        l_id_match_old p1_match.id_match%TYPE;
        l_seq_num_new  p1_match.sequential_number%TYPE;
        l_seq_num_old  p1_match.sequential_number%TYPE;
        l_check_match  VARCHAR2(1 CHAR);
    
        l_detail_row    p1_detail%ROWTYPE;
        l_id_detail     p1_detail.id_detail%TYPE;
        l_rowids        table_varchar;
        l_flg_available VARCHAR2(1 CHAR);
    
        CURSOR c_ref_mig_data
        (
            x_id_ext_req   IN p1_external_request.id_external_request%TYPE,
            x_id_inst_dest IN p1_external_request.id_inst_dest%TYPE
        ) IS
            SELECT *
              INTO g_ref_mig_row
              FROM ref_mig_inst_dest_data r
             WHERE r.id_external_request = x_id_ext_req
               AND r.id_inst_dest = x_id_inst_dest; -- new id_inst_dest
    
        FUNCTION check_professional_exists
        (
            i_id_prof IN professional.id_professional%TYPE,
            i_id_inst IN institution.id_institution%TYPE,
            i_id_soft IN software.id_software%TYPE
        ) RETURN NUMBER IS
            l_count PLS_INTEGER;
        BEGIN
        
            g_error := 'SELECT COUNT(1) FROM PROFESSIONAL WHERE id_professional = ' || l_id_prof_scheduled;
            SELECT COUNT(1)
              INTO l_count
              FROM professional p
              JOIN prof_profile_template ppt
                ON (ppt.id_professional = p.id_professional)
             WHERE p.id_professional = i_id_prof
               AND ppt.id_institution = i_id_inst
               AND ppt.id_software = i_id_soft
               AND ppt.id_profile_template = pk_ref_constant.g_profile_med_hs;
        
            RETURN l_count;
        END check_professional_exists;
    
        -- checks if match was done correctly
        FUNCTION check_match
        (
            i_flg_ws      IN VARCHAR2,
            i_seq_num_new IN p1_match.sequential_number%TYPE,
            i_num_cr_new  IN clin_record.num_clin_record%TYPE
        ) RETURN VARCHAR2 IS
            l_result VARCHAR2(1 CHAR);
        BEGIN
            g_error  := 'Init check_match / i_flg_ws=' || i_flg_ws || ' i_seq_num_new=' || i_seq_num_new ||
                        ' i_num_cr_new=' || i_num_cr_new;
            l_result := pk_ref_constant.g_no;
        
            CASE i_flg_ws
                WHEN pk_ref_constant.g_yes THEN
                    -- behaviour as if dest institution is using referral webservices
                    -- clin_record not mandatory
                    l_result := pk_ref_constant.g_yes;
                
                WHEN pk_ref_constant.g_no THEN
                    -- behaviour as if dest institution is using referral screens
                    -- sequential number (mandatory), clin_record not mandatory
                    IF i_seq_num_new IS NOT NULL
                    THEN
                        l_result := pk_ref_constant.g_yes;
                    END IF;
                ELSE
                    g_error := 'check_match: Case not found / i_flg_ws=' || i_flg_ws;
                    RAISE g_exception;
            END CASE;
        
            RETURN l_result;
        
        END check_match;
    BEGIN
        g_error := 'Init mig_ref_dest_institution / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow;
    
        -------------------------
        -- 1- get new dep_clin_serv
        IF i_ref_row.id_dep_clin_serv IS NOT NULL -- old
        THEN
        
            IF i_default_dcs = pk_ref_constant.g_yes
            THEN
                -- calculated by default for the referral speciality
                g_error                := 'DEP_CLIN_SERV calculated by default / ID_REF=' ||
                                          i_ref_row.id_external_request;
                l_ref_row              := i_ref_row;
                l_ref_row.id_inst_dest := i_id_inst_dest_new; -- this is needed to be used in pk_ref_core.get_default_dcs
            
                g_error  := 'Call pk_ref_core.get_default_dcs / ID_REF=' || i_ref_row.id_external_request;
                g_retval := pk_ref_core.get_default_dcs(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_exr_row => l_ref_row,
                                                        o_dcs     => l_id_dcs_new,
                                                        o_error   => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error       := 'l_id_spec_new=' || l_id_spec_new;
                l_id_spec_new := i_ref_row.id_speciality; -- p1_speciality remains the same
            
            ELSE
                --calculated from MAP table
                g_error  := 'Call get_mapped_value / ID_REF=' || l_ref_row.id_external_request || ' i_definition=' ||
                            pk_ref_constant.g_map_dcs || ' i_old_value=' || i_ref_row.id_dep_clin_serv ||
                            ' i_definition_get=' || pk_ref_constant.g_map_dcs;
                g_retval := get_mapped_value(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_definition     => pk_ref_constant.g_map_dcs,
                                             i_old_value      => to_char(i_ref_row.id_dep_clin_serv),
                                             i_definition_get => pk_ref_constant.g_map_dcs,
                                             o_new_value      => l_id_dcs_new,
                                             o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END IF;
        
            g_error := g_error || ' / new_DCS=' || l_id_dcs_new;
            IF l_id_dcs_new IS NULL
            THEN
                g_error := 'No default dep_clin_serv defined for ID_INSTITUTION=' || i_id_inst_dest_new ||
                           ' ID_SPECIALITY=' || l_ref_row.id_speciality || ' / ID_REF=' ||
                           l_ref_row.id_external_request;
                RAISE g_exception;
            END IF;
        
            -- gets id_speciality
            IF l_id_spec_new IS NULL
            THEN
            
                l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => i_ref_row.id_workflow,
                                                                         i_id_inst_orig => i_ref_row.id_inst_orig,
                                                                         i_id_inst_dest => i_ref_row.id_inst_dest);
                g_error            := 'Call pk_ref_spec_dep_clin_serv.get_speciality_for_dcs / ID_REF=' ||
                                      i_ref_row.id_external_request || ' OLD DCS=' || i_ref_row.id_dep_clin_serv ||
                                      ' NEW DCS=' || l_id_dcs_new || ' ID_PATIENT=' || i_ref_row.id_patient ||
                                      ' ID_EXTERNAL_SYS=' || i_ref_row.id_external_sys || ' FLG_AVAILABILITY=' ||
                                      l_flg_availability;
                g_retval           := pk_ref_spec_dep_clin_serv.get_speciality_for_dcs(i_lang             => i_lang,
                                                                                       i_prof             => i_prof,
                                                                                       i_id_dep_clin_serv => l_id_dcs_new,
                                                                                       i_id_patient       => i_ref_row.id_patient,
                                                                                       i_id_external_sys  => i_ref_row.id_external_sys,
                                                                                       i_flg_availability => l_flg_availability,
                                                                                       o_id_speciality    => l_id_spec_new, -- new spec
                                                                                       o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            -- check referral network with the new dep_clin_serv
            -- external referrals only (id_workflow is null)
            g_error := 'Check referral network / ID_REF=' || i_ref_row.id_external_request || ' FLG_TYPE=' ||
                       i_ref_row.flg_type || ' ID_INST_ORIG=' || i_ref_row.id_inst_orig || ' ID_INSTITUTION=' ||
                       i_id_inst_dest_new || ' ID_SPECIALITY=' || l_id_spec_new || ' ID_EXTERNAL_SYS=' ||
                       i_ref_row.id_external_sys || ' ID_DEP_CLIN_SERV=' || l_id_dcs_new;
            SELECT COUNT(1)
              INTO l_count
              FROM v_ref_network v
             WHERE v.flg_type = i_ref_row.flg_type
               AND v.id_inst_orig = i_ref_row.id_inst_orig
               AND v.id_institution = i_id_inst_dest_new
               AND v.id_speciality = l_id_spec_new -- the new speciality
               AND v.id_external_sys IN (nvl(i_ref_row.id_external_sys, 0), 0)
               AND v.id_dep_clin_serv = l_id_dcs_new; -- new dep_clin_serv
        
            IF l_count = 0
            THEN
                g_error := 'Speciality ' || l_id_spec_new || ' not available for institution ' || i_id_inst_dest_new ||
                           ' / ID_REF=' || i_ref_row.id_external_request || ' NEW_DEP_CLIN_SERV=' || l_id_dcs_new;
                RAISE g_exception;
            END IF;
        
        END IF;
    
        -------------------------
        -- 2- Gets data needed for migration (from table ref_mig_inst_dest_data)
        g_ref_mig_row := NULL;
        g_error       := 'OPEN c_ref_mig_data(' || i_ref_row.id_external_request || ',' || i_id_inst_dest_new || ');';
        OPEN c_ref_mig_data(i_ref_row.id_external_request, i_id_inst_dest_new); -- new id_inst_dest
        FETCH c_ref_mig_data
            INTO g_ref_mig_row;
        CLOSE c_ref_mig_data;
    
        -------------------------
        -- 3- tries to do patient match in the new institution
        g_error  := 'Call set_match / ID_PATIENT=' || i_ref_row.id_patient || ' ID_INSTITUTION=' || i_id_inst_dest_new ||
                    ' i_flg_ws=' || i_flg_ws;
        g_retval := set_match(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_id_patient       => i_ref_row.id_patient,
                              i_id_inst_dest_new => i_id_inst_dest_new,
                              i_id_inst_dest_old => i_ref_row.id_inst_dest,
                              i_flg_ws           => i_flg_ws,
                              o_id_match_new     => l_id_match_new,
                              o_num_cr_new       => l_num_cr_new,
                              o_seq_num_new      => l_seq_num_new,
                              o_id_match_old     => l_id_match_old,
                              o_num_cr_old       => l_num_cr_old,
                              o_seq_num_old      => l_seq_num_old,
                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -------------------------
        -- 4- WORKFLOW is null or 1
        g_error := 'CASE / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status;
        CASE
            WHEN i_ref_row.flg_status = pk_ref_constant.g_p1_status_o THEN
            
                -- O - Being Created
                g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_INST_DEST=' || i_id_inst_dest_new || ' FLG_STATUS=' || i_ref_row.flg_status;
                l_rowids := NULL;
                ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                           id_inst_dest_in             => i_id_inst_dest_new,
                                           dt_last_interaction_tstz_in => i_op_date,
                                           handle_error_in             => TRUE,
                                           rows_out                    => l_rowids);
            
                g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request || ' ID_INST_DEST=' ||
                            i_id_inst_dest_new || ' FLG_STATUS=' || i_ref_row.flg_status;
                l_rowids := NULL;
                ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                   id_inst_dest_in             => i_id_inst_dest_new,
                                   dt_dg_last_update_in        => i_op_date,
                                   dt_last_interaction_tstz_in => i_op_date,
                                   handle_error_in             => TRUE,
                                   rows_out                    => l_rowids);
            
            WHEN i_ref_row.flg_status = pk_ref_constant.g_p1_status_n THEN
            
                -- N - New
                IF i_ref_row.id_dep_clin_serv IS NULL
                THEN
                    -- this referral was not declined yet
                    g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || i_id_inst_dest_new || ' FLG_STATUS=' || i_ref_row.flg_status;
                    l_rowids := NULL;
                    ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                               id_inst_dest_in             => i_id_inst_dest_new,
                                               dt_last_interaction_tstz_in => i_op_date,
                                               handle_error_in             => TRUE,
                                               rows_out                    => l_rowids);
                
                    g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || i_id_inst_dest_new || ' FLG_STATUS=' || i_ref_row.flg_status;
                    l_rowids := NULL;
                    ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                       id_inst_dest_in             => i_id_inst_dest_new,
                                       dt_dg_last_update_in        => i_op_date,
                                       dt_last_interaction_tstz_in => i_op_date,
                                       handle_error_in             => TRUE,
                                       rows_out                    => l_rowids);
                ELSE
                    -- this referral was already declined, proceed as if it was declined or returned by registrar
                
                    -- do not need to check match, registrar can do the match again 
                
                    g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                                i_ref_row.flg_status || ' ID_SPECIALITY=' || l_id_spec_new;
                    l_rowids := NULL;
                    ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                               id_inst_dest_in             => i_id_inst_dest_new,
                                               id_dep_clin_serv_in         => l_id_dcs_new,
                                               flg_forward_dcs_in          => pk_ref_constant.g_yes,
                                               dt_last_interaction_tstz_in => i_op_date,
                                               id_speciality_in            => l_id_spec_new,
                                               handle_error_in             => TRUE,
                                               rows_out                    => l_rowids);
                
                    g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                                i_ref_row.flg_status || ' ID_SPECIALITY=' || l_id_spec_new;
                    l_rowids := NULL;
                    ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                       id_inst_dest_in             => i_id_inst_dest_new,
                                       id_dep_clin_serv_in         => l_id_dcs_new,
                                       id_match_in                 => l_id_match_new,
                                       id_match_nin                => FALSE, -- update if null
                                       dt_dg_last_update_in        => i_op_date,
                                       dt_last_interaction_tstz_in => i_op_date,
                                       id_speciality_in            => l_id_spec_new,
                                       handle_error_in             => TRUE,
                                       rows_out                    => l_rowids);
                END IF;
            
            WHEN i_ref_row.flg_status IN
                 (pk_ref_constant.g_p1_status_i, pk_ref_constant.g_p1_status_b, pk_ref_constant.g_p1_status_d) THEN
            
                -- I - Issued
                -- B - Returned by Registrar
                -- D - Declined
            
                -- do not need to check match, registrar can do the match again 
            
                g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                            i_ref_row.flg_status || ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                           id_inst_dest_in             => i_id_inst_dest_new,
                                           id_dep_clin_serv_in         => l_id_dcs_new,
                                           flg_forward_dcs_in          => pk_ref_constant.g_yes,
                                           dt_last_interaction_tstz_in => i_op_date,
                                           id_speciality_in            => l_id_spec_new,
                                           handle_error_in             => TRUE,
                                           rows_out                    => l_rowids);
            
                g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request || ' ID_INST_DEST=' ||
                            i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' || i_ref_row.flg_status ||
                            ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                   id_inst_dest_in             => i_id_inst_dest_new,
                                   id_dep_clin_serv_in         => l_id_dcs_new,
                                   id_match_in                 => l_id_match_new,
                                   id_match_nin                => FALSE, -- update if null
                                   dt_dg_last_update_in        => i_op_date,
                                   dt_last_interaction_tstz_in => i_op_date,
                                   id_speciality_in            => l_id_spec_new,
                                   handle_error_in             => TRUE,
                                   rows_out                    => l_rowids);
            
            WHEN i_ref_row.flg_status IN (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_a) THEN
            
                -- T - Triage
                -- A - Appointment being scheduled
            
                -- check if match was done correctly
                g_error       := 'Call check_match / ID_REF=' || i_ref_row.id_external_request || ' i_flg_ws=' ||
                                 i_flg_ws || ' l_seq_num_new=' || l_seq_num_new || ' l_num_cr_new=' || l_num_cr_new;
                l_check_match := check_match(i_flg_ws      => i_flg_ws,
                                             i_seq_num_new => l_seq_num_new,
                                             i_num_cr_new  => l_num_cr_new);
            
                -- do not need to check match, registrar can do the match again
                IF l_check_match IS NULL
                   OR l_check_match = pk_ref_constant.g_no
                THEN
                    g_error := g_error || ' Match invalid';
                    RAISE g_exception;
                END IF;
            
                -- Update referral
                g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                            i_ref_row.flg_status || ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                           id_inst_dest_in             => i_id_inst_dest_new,
                                           id_dep_clin_serv_in         => l_id_dcs_new,
                                           flg_forward_dcs_in          => pk_ref_constant.g_yes,
                                           dt_last_interaction_tstz_in => i_op_date,
                                           id_speciality_in            => l_id_spec_new,
                                           handle_error_in             => TRUE,
                                           rows_out                    => l_rowids);
            
                g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request || ' ID_INST_DEST=' ||
                            i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                   id_inst_dest_in             => i_id_inst_dest_new,
                                   id_dep_clin_serv_in         => l_id_dcs_new,
                                   id_match_in                 => l_id_match_new,
                                   id_match_nin                => FALSE, -- update if null
                                   dt_dg_last_update_in        => i_op_date,
                                   dt_last_interaction_tstz_in => i_op_date,
                                   id_prof_redirected_in       => NULL, -- there is no redirected professional in the new institution
                                   id_prof_redirected_nin      => FALSE, -- update if null
                                   id_speciality_in            => l_id_spec_new,
                                   handle_error_in             => TRUE,
                                   rows_out                    => l_rowids);
            
            WHEN i_ref_row.flg_status = pk_ref_constant.g_p1_status_z THEN
            
                -- Z - Cancellation request
                g_error := 'l_id_match_new=' || l_id_match_new || ' / ID_REF=' || i_ref_row.id_external_request ||
                           ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                           i_ref_row.flg_status;
            
                -- gets the previsou status
                g_retval := pk_ref_utils.get_prev_status_data(i_lang   => i_lang,
                                                              i_prof   => i_prof,
                                                              i_id_ref => i_ref_row.id_external_request,
                                                              o_data   => l_prev_track_row,
                                                              o_error  => o_error);
            
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error;
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'l_prev_track_row.ext_req_status=' || l_prev_track_row.ext_req_status || ' ID_REF=' ||
                           l_prev_track_row.id_external_request;
                IF l_prev_track_row.ext_req_status NOT IN
                   (pk_ref_constant.g_p1_status_n,
                    pk_ref_constant.g_p1_status_i,
                    pk_ref_constant.g_p1_status_b,
                    pk_ref_constant.g_p1_status_d)
                THEN
                    -- check if match was done correctly
                    g_error       := 'Call check_match / ID_REF=' || i_ref_row.id_external_request || ' i_flg_ws=' ||
                                     i_flg_ws || ' l_seq_num_new=' || l_seq_num_new || ' l_num_cr_new=' || l_num_cr_new;
                    l_check_match := check_match(i_flg_ws      => i_flg_ws,
                                                 i_seq_num_new => l_seq_num_new,
                                                 i_num_cr_new  => l_num_cr_new);
                
                    -- do not need to check match, registrar can do the match again
                    IF l_check_match IS NULL
                       OR l_check_match = pk_ref_constant.g_no
                    THEN
                        g_error := g_error || ' Match invalid';
                        RAISE g_exception;
                    END IF;
                END IF;
            
                -- Update referral
                g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                            i_ref_row.flg_status;
                l_rowids := NULL;
                ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                           id_inst_dest_in             => i_id_inst_dest_new,
                                           id_dep_clin_serv_in         => l_id_dcs_new,
                                           flg_forward_dcs_in          => pk_ref_constant.g_yes,
                                           dt_last_interaction_tstz_in => i_op_date,
                                           id_speciality_in            => l_id_spec_new,
                                           handle_error_in             => TRUE,
                                           rows_out                    => l_rowids);
            
                g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request || ' ID_INST_DEST=' ||
                            i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                   id_inst_dest_in             => i_id_inst_dest_new,
                                   id_dep_clin_serv_in         => l_id_dcs_new,
                                   id_match_in                 => l_id_match_new,
                                   id_match_nin                => FALSE, -- update if null
                                   dt_dg_last_update_in        => i_op_date,
                                   dt_last_interaction_tstz_in => i_op_date,
                                   id_prof_redirected_in       => NULL, -- there is no redirected professional in the new institution
                                   id_prof_redirected_nin      => FALSE, -- update if null
                                   id_speciality_in            => l_id_spec_new,
                                   handle_error_in             => TRUE,
                                   rows_out                    => l_rowids);
            
            WHEN i_ref_row.flg_status = pk_ref_constant.g_p1_status_r THEN
            
                -- R - Re-sent
            
                -- check if match was done correctly
                g_error       := 'Call check_match / ID_REF=' || i_ref_row.id_external_request || ' i_flg_ws=' ||
                                 i_flg_ws || ' l_seq_num_new=' || l_seq_num_new || ' l_num_cr_new=' || l_num_cr_new;
                l_check_match := check_match(i_flg_ws      => i_flg_ws,
                                             i_seq_num_new => l_seq_num_new,
                                             i_num_cr_new  => l_num_cr_new);
            
                -- do not need to check match, registrar can do the match again
                IF l_check_match IS NULL
                   OR l_check_match = pk_ref_constant.g_no
                THEN
                    g_error := g_error || ' Match invalid';
                    RAISE g_exception;
                END IF;
            
                -- getting ID_PROF_FORWARD:  g_ref_mig_row.id_prof_forward
                g_error              := 'g_ref_mig_row.id_prof_forward=' || g_ref_mig_row.id_prof_forward || ' ID_REF=' ||
                                        g_ref_mig_row.id_external_request || ' ID_INST_DEST=' ||
                                        g_ref_mig_row.id_inst_dest;
                l_id_prof_redirected := g_ref_mig_row.id_prof_forward;
            
                -- check if l_id_prof_redirected is valid
                g_error := g_error || ' / l_id_prof_redirected=' || l_id_prof_redirected;
                IF l_id_prof_redirected IS NULL
                THEN
                    g_error := 'Professional redirected is null / ID_REF=' || i_ref_row.id_external_request ||
                               ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                               i_ref_row.flg_status;
                    RAISE g_exception;
                ELSE
                    -- validate professional identifier
                    g_error := 'Call check_professional_exists / i_id_prof=' || l_id_prof_redirected || ' i_id_inst=' ||
                               i_id_inst_dest_new || ' i_id_soft=' || i_prof.software;
                    l_count := check_professional_exists(i_id_prof => l_id_prof_redirected,
                                                         i_id_inst => i_id_inst_dest_new,
                                                         i_id_soft => i_prof.software);
                
                    IF l_count = 0
                    THEN
                        g_error := 'Non-existent professional / ' || g_error;
                    END IF;
                END IF;
            
                g_error         := 'Call pk_ref_dest_phy.validate_dcs_triage / ID_PROF=' || l_id_prof_redirected ||
                                   ' ID_DCS=' || i_ref_row.id_dep_clin_serv;
                l_flg_available := pk_ref_dest_phy.validate_dcs_triage(i_prof => profissional(l_id_prof_redirected,
                                                                                              i_prof.institution,
                                                                                              i_prof.software),
                                                                       i_dcs  => i_ref_row.id_dep_clin_serv);
            
                IF l_flg_available = pk_ref_constant.g_no
                THEN
                    g_error := 'PROFESSIONAL ID=' || l_id_prof_redirected ||
                               ' is not a triage professional for DEP_CLIN_SERV=' || i_ref_row.id_dep_clin_serv;
                    RAISE g_exception;
                END IF;
            
                -- Update referral
                g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                            i_ref_row.flg_status || ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                           id_inst_dest_in             => i_id_inst_dest_new,
                                           id_dep_clin_serv_in         => l_id_dcs_new,
                                           flg_forward_dcs_in          => pk_ref_constant.g_yes,
                                           dt_last_interaction_tstz_in => i_op_date,
                                           id_speciality_in            => l_id_spec_new,
                                           handle_error_in             => TRUE,
                                           rows_out                    => l_rowids);
            
                g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request || ' ID_INST_DEST=' ||
                            i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                   id_inst_dest_in             => i_id_inst_dest_new,
                                   id_dep_clin_serv_in         => l_id_dcs_new,
                                   id_match_in                 => l_id_match_new,
                                   id_match_nin                => FALSE, -- update if null
                                   dt_dg_last_update_in        => i_op_date,
                                   dt_last_interaction_tstz_in => i_op_date,
                                   id_prof_redirected_in       => l_id_prof_redirected,
                                   id_prof_redirected_nin      => FALSE, -- update if null
                                   id_speciality_in            => l_id_spec_new,
                                   handle_error_in             => TRUE,
                                   rows_out                    => l_rowids);
            
            WHEN i_ref_row.flg_status IN (pk_ref_constant.g_p1_status_s, pk_ref_constant.g_p1_status_m) THEN
                -- S - Scheduled
                -- M - Patient notified
            
                -- getting dt_schedule
                g_error            := 'Converting DATEs to VARCHARs';
                l_dt_appointment_v := to_char(g_ref_mig_row.dt_schedule, pk_ref_constant.g_format_date_2);
            
                g_error := g_error || ' / DT_SCHEDULE=' || l_dt_appointment_v;
                IF g_ref_mig_row.dt_schedule IS NOT NULL
                THEN
                    -- using new schedule date in table REF_MIG_DEST_INST_DATA.dt_schedule
                
                    -- converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs
                    g_error                 := 'Converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs / DT_APPOINTMENT=' ||
                                               l_dt_appointment_v;
                    l_sch_row.dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_timestamp => l_dt_appointment_v,
                                                                             i_timezone  => NULL,
                                                                             i_mask      => pk_ref_constant.g_format_date_2);
                
                ELSE
                    -- do not schedule
                    g_error := 'Error: new DT_SCHEDULE not found / ID_REF=' || i_ref_row.id_external_request;
                    RAISE g_exception;
                END IF;
            
                -- check if match was done correctly
                g_error       := 'Call check_match / ID_REF=' || i_ref_row.id_external_request || ' i_flg_ws=' ||
                                 i_flg_ws || ' l_seq_num_new=' || l_seq_num_new || ' l_num_cr_new=' || l_num_cr_new;
                l_check_match := check_match(i_flg_ws      => i_flg_ws,
                                             i_seq_num_new => l_seq_num_new,
                                             i_num_cr_new  => l_num_cr_new);
            
                -- do not need to check match, registrar can do the match again
                IF l_check_match IS NULL
                   OR l_check_match = pk_ref_constant.g_no
                THEN
                    g_error := g_error || ' Match invalid';
                    RAISE g_exception;
                END IF;
            
                -- getting ID_PROF_SCHEDULED
                g_error             := 'g_ref_mig_row.id_prof_schedule=' || g_ref_mig_row.id_prof_schedule ||
                                       ' ID_REF=' || g_ref_mig_row.id_external_request || ' ID_INST_DEST=' ||
                                       g_ref_mig_row.id_inst_dest;
                l_id_prof_scheduled := g_ref_mig_row.id_prof_schedule;
            
                g_error := 'l_id_prof_scheduled=' || l_id_prof_scheduled || ' / ID_REF=' ||
                           i_ref_row.id_external_request;
                IF l_id_prof_scheduled IS NULL
                THEN
                    -- schedules the referral for the dep_clin_serv
                    l_id_prof_scheduled := i_prof.id; -- interface professional
                ELSE
                    -- validate professional identifier
                    g_error := 'Call check_professional_exists / i_id_prof=' || l_id_prof_scheduled || ' i_id_inst=' ||
                               i_id_inst_dest_new || ' i_id_soft=' || i_prof.software;
                    l_count := check_professional_exists(i_id_prof => l_id_prof_scheduled,
                                                         i_id_inst => i_id_inst_dest_new,
                                                         i_id_soft => i_prof.software);
                
                    IF l_count = 0
                    THEN
                        g_error := 'Non-existent professional / ' || g_error;
                    END IF;
                
                    g_error := 'i_flg_ws=' || i_flg_ws || ' l_id_prof_scheduled=' || l_id_prof_scheduled ||
                               ' / ID_REF=' || l_ref_row.id_external_request;
                    IF i_flg_ws = pk_ref_constant.g_yes
                    THEN
                        -- webservices behaviour - referral professional may not be configured with the right sys_functionalities
                        NULL;
                    ELSE
                        -- using referral screens, professional configurations must be validated                        
                        g_error         := 'Call pk_ref_dest_phy.validate_dcs_func / ID_PROF=' || i_prof.id ||
                                           ' ID_INSTITUTION=' || i_prof.institution || ' ID_DCS=' || l_id_dcs_new;
                        l_flg_available := pk_ref_dest_phy.validate_dcs_func(i_prof => profissional(l_id_prof_scheduled,
                                                                                                    i_id_inst_dest_new,
                                                                                                    i_prof.software),
                                                                             i_dcs  => l_id_dcs_new,
                                                                             i_func => table_number(pk_ref_constant.g_func_d,
                                                                                                    pk_ref_constant.g_func_t,
                                                                                                    pk_ref_constant.g_func_c));
                    
                        IF l_flg_available = pk_ref_constant.g_no
                        THEN
                            -- professional is not configured to the new dep_clin_serv
                            g_error := 'Professional ID_PROF=' || l_id_prof_scheduled ||
                                       ' is not configured for the dep_clin_serv=' || l_id_dcs_new ||
                                       ' id the institution id=' || i_id_inst_dest_new;
                            RAISE g_exception;
                        END IF;
                    
                    END IF;
                END IF;
            
                -- cancels the old referral schedule
                -- todo: completar
                /*g_error := 'Call pk_schedule_api_upstream.cancel_schedule / ID_REF='||i_ref_row.id_external_request||' ID_SCHEDULE=' || i_ref_row.id_schedule;
                IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_id_schedule      => i_ref_row.id_schedule,
                                                            i_id_cancel_reason => NULL,
                                                            i_cancel_notes     => NULL, -- notes to scheduler and referral status
                                                            i_transaction_id   => NULL,
                                                            i_dt_referral      => i_op_date,
                                                            o_error            => o_error)
                THEN
                    RAISE g_exception_np;
                END IF;
                
                g_error := 'UPDATE EPIS_INFO';
                ts_epis_info.upd(flg_sch_status_in => g_sched_status_c,
                                 where_in          => 'id_schedule =' || l_id_schedule,
                                 rows_out          => l_rows_ei);*/
            
                -- and creates a new one in the new institution
            
                -- todo: completar            
                -- Creates schedule and updates referral status       
                /*g_error  := 'Call pk_schedule_api_upstream.create_schedule / ID_REF=' ||
                            i_ref_row.id_external_request || ' i_professional_id=' || i_prof.id || ' i_id_patient=' ||
                            i_ref_row.id_patient || ' i_id_dep_clin_serv=' || l_id_dcs_new || ' i_id_inst_requests=' ||
                            i_prof.institution || ' i_id_dcs_requests=' || l_id_dcs_new || ' i_id_prof_requests=' ||
                            i_prof.id || ' i_id_prof_schedules=' || i_prof.id || ' i_id_sch_ref=' ||
                            i_ref_row.id_schedule||' DT_SCHEDULE=' || l_dt_appointment_v;
                g_retval := pk_schedule_api_upstream.create_schedule(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_event_id          => pk_ref_constant.g_sch_event_1,
                                                                     i_professional_id   => i_prof.id, -- interface professional (id_prof_requests)
                                                                     i_id_patient        => i_ref_row.id_patient,
                                                                     i_id_dep_clin_serv  => l_id_dcs_new, -- id_dcs_requested
                                                                     i_dt_begin_tstz     => l_dt_begin_tstz,
                                                                     i_dt_end_tstz       => NULL,
                                                                     i_flg_vacancy       => NULL,
                                                                     i_id_episode        => NULL,
                                                                     i_flg_rqst_type     => NULL,
                                                                     i_flg_sch_via       => NULL,
                                                                     i_sch_notes         => NULL, -- notes to scheduler and referral status
                                                                     i_id_inst_requests  => i_prof.institution,
                                                                     i_id_dcs_requests   => l_id_dcs_new,
                                                                     i_id_prof_requests  => i_prof.id, -- interface professional
                                                                     i_id_prof_schedules => i_prof.id, -- interface professional
                                                                     i_id_sch_ref        => i_ref_row.id_schedule,
                                                                     i_transaction_id    => l_transaction_id,
                                                                     i_id_external_req   => i_ref_row.id_external_request,
                                                                     i_dt_referral       => i_op_date,
                                                                     o_ids_schedule      => l_sch_ids,
                                                                     o_id_schedule_ext   => l_id_ext,
                                                                     o_error             => o_error);
                IF NOT g_retval
                THEN
                    g_error := 'ERROR: ' || g_error;
                    RAISE g_exception_np;
                END IF;*/
            
                -- Update referral
                g_error  := 'Call ts_p1_external_request.upd / ID_REF=' || i_ref_row.id_external_request ||
                            ' ID_INST_DEST=' || i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' FLG_STATUS=' ||
                            i_ref_row.flg_status || ' ID_SCHEDULE=' || l_id_schedule || ' ID_SPECIALITY=' ||
                            l_id_spec_new;
                l_rowids := NULL;
                ts_p1_external_request.upd(id_external_request_in      => i_ref_row.id_external_request,
                                           id_inst_dest_in             => i_id_inst_dest_new,
                                           id_dep_clin_serv_in         => l_id_dcs_new,
                                           flg_forward_dcs_in          => pk_ref_constant.g_yes,
                                           dt_last_interaction_tstz_in => i_op_date,
                                           id_schedule_in              => l_id_schedule,
                                           id_speciality_in            => l_id_spec_new,
                                           handle_error_in             => TRUE,
                                           rows_out                    => l_rowids);
            
                g_error  := 'Call ts_referral_ea.upd / ID_REF=' || i_ref_row.id_external_request || ' ID_INST_DEST=' ||
                            i_id_inst_dest_new || ' ID_DCS=' || l_id_dcs_new || ' ID_SCHEDULE=' || l_id_schedule ||
                            ' ID_SPECIALITY=' || l_id_spec_new;
                l_rowids := NULL;
                ts_referral_ea.upd(id_external_request_in      => i_ref_row.id_external_request,
                                   id_inst_dest_in             => i_id_inst_dest_new,
                                   id_dep_clin_serv_in         => l_id_dcs_new,
                                   id_match_in                 => l_id_match_new,
                                   id_match_nin                => FALSE, -- update if null
                                   dt_dg_last_update_in        => i_op_date,
                                   dt_last_interaction_tstz_in => i_op_date,
                                   id_prof_redirected_in       => l_id_prof_redirected,
                                   id_prof_redirected_nin      => FALSE, -- update if null
                                   id_schedule_in              => l_id_schedule,
                                   dt_schedule_in              => l_sch_row.dt_begin_tstz,
                                   id_speciality_in            => l_id_spec_new,
                                   handle_error_in             => TRUE,
                                   rows_out                    => l_rowids);
            
            ELSE
                g_error := 'Referral could not be migrated / ID_REF=' || i_ref_row.id_external_request ||
                           ' FLG_STATUS=' || i_ref_row.flg_status;
                RAISE g_exception;
        END CASE;
    
        -------------------------
        -- 5- insert on p1_tracking a record indicating that this referral was migrated
        g_error := 'Getting round_id / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow;
        SELECT MAX(t.round_id)
          INTO l_round
          FROM p1_tracking t
         WHERE t.id_external_request = i_ref_row.id_external_request;
    
        g_error := 'Fill p1_tracking / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                   i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow;
    
        l_track_row.id_tracking         := ts_p1_tracking.next_key;
        l_track_row.ext_req_status      := i_ref_row.flg_status;
        l_track_row.id_external_request := i_ref_row.id_external_request;
        l_track_row.id_institution      := i_prof.institution;
        l_track_row.id_professional     := i_prof.id;
        l_track_row.flg_type            := pk_ref_constant.g_tracking_type_m;
        l_track_row.round_id            := l_round;
        l_track_row.dt_tracking_tstz    := i_op_date;
        l_track_row.dt_create           := i_op_date;
        l_track_row.id_inst_dest        := i_id_inst_dest_new;
        l_track_row.id_dep_clin_serv    := l_id_dcs_new;
        l_track_row.id_prof_dest        := l_id_prof_redirected; -- only set when the referral is re-sent
        l_track_row.id_schedule         := l_id_schedule;
        l_track_row.id_speciality       := l_id_spec_new;
    
        g_error  := 'Call ts_p1_tracking.ins / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                    i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow;
        l_rowids := NULL;
        ts_p1_tracking.ins(rec_in => l_track_row, handle_error_in => TRUE, rows_out => l_rowids);
    
        IF i_notes IS NOT NULL
        THEN
            g_error                          := 'Fill DETAIL=' || pk_ref_constant.g_detail_type_system || ' / ID_REF=' ||
                                                i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status ||
                                                ' ID_WF=' || i_ref_row.id_workflow;
            l_detail_row.id_external_request := l_track_row.id_external_request;
            l_detail_row.text                := i_notes;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_system; -- system notes
            l_detail_row.id_professional     := l_track_row.id_professional;
            l_detail_row.id_institution      := l_track_row.id_institution;
            l_detail_row.id_tracking         := l_track_row.id_tracking;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
            l_detail_row.dt_insert_tstz      := i_op_date;
        
            g_error := 'CALL pk_ref_api.set_p1_detail / ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' ||
                       i_ref_row.flg_status || ' ID_WF=' || i_ref_row.id_workflow;
            IF NOT pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_p1_detail => l_detail_row,
                                            o_id_detail => l_id_detail,
                                            o_error     => o_error)
            
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'MIG_REF_DEST_INSTITUTION',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END mig_ref_dest_institution;

    /**
    * Migrate a referral to a different dest institution
    * This function has COMMITs/ROLLBACKs
    *
    * @param   i_id_ref_tab        Array of referral identifiers
    * @param   i_id_institution    Dest institution identifier
    * @param   i_default_dcs       Indicates if dep_clin_serv is mapped or calculated by default
    * @param   i_notes             Notes associated to the migration
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_default_dcs       {*} Y- calculated by default for the referral speciality {*} N- calculated from table MAP
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION mig_ref_dest_institution
    (
        i_id_ref_tab     IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        i_default_dcs    IN VARCHAR2 DEFAULT pk_ref_constant.g_yes,
        i_notes          IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref IS
            SELECT *
              FROM p1_external_request p
              JOIN TABLE(CAST(i_id_ref_tab AS table_number)) t
                ON t.column_value = p.id_external_request;
    
        TYPE t_ref_tab IS TABLE OF c_ref%ROWTYPE;
        l_ref_tab t_ref_tab;
    
        l_limit PLS_INTEGER := 2000;
    
        l_lang       language.id_language%TYPE;
        l_prof       profissional;
        l_ref_row    p1_external_request%ROWTYPE;
        l_op_date    p1_tracking.dt_tracking_tstz%TYPE;
        l_seq_number p1_match.sequential_number%TYPE;
        l_flg_ws     VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'Init mig_ref_dest_institution / i_default_dcs=' || i_default_dcs || ' i_id_institution=' ||
                   i_id_institution || ' i_id_ref_tab.count=' || i_id_ref_tab.count;
        pk_alertlog.log_debug(g_error);
        l_lang    := 1;
        l_prof    := pk_ref_interface.set_prof_interface(profissional(NULL, 0, pk_ref_constant.g_id_soft_referral));
        l_op_date := current_timestamp;
    
        IF i_id_ref_tab IS NULL
           OR i_id_ref_tab.count = 0
           OR i_id_institution IS NULL
        THEN
            g_error := 'Invalid parameters / i_id_institution=' || i_id_institution || ' or i_id_ref_tab is empty';
            RAISE g_exception;
        END IF;
    
        g_error := 'select pk_interfaces_referral.get_is_inst_ref_simulation(' || i_id_institution || ') from dual';
        EXECUTE IMMEDIATE 'select pk_interfaces_referral.get_is_inst_ref_simulation(:inst) from dual'
            INTO l_flg_ws
            USING i_id_institution;
    
        g_error := g_error || ' / l_flg_ws=' || l_flg_ws;
        IF l_flg_ws = '1'
        THEN
            -- webservices behaviour
            l_flg_ws := pk_ref_constant.g_yes;
        ELSE
            -- using referral screens
            l_flg_ws := pk_ref_constant.g_no;
        END IF;
    
        g_error := 'OPEN c_ref / i_id_institution=' || i_id_institution;
        OPEN c_ref;
        LOOP
            g_error := 'FETCH c_ref BULK COLLECT / i_id_institution=' || i_id_institution || ' i_id_ref_tab.count=' ||
                       i_id_ref_tab.count;
            FETCH c_ref BULK COLLECT
                INTO l_ref_tab LIMIT l_limit;
        
            FOR i IN 1 .. l_ref_tab.count
            LOOP
            
                -- set savepoint
                g_error := 'SAVEPOINT sp_mig_referral / i_id_institution=' || i_id_institution ||
                           ' i_id_ref_tab.count=' || i_id_ref_tab.count || ' i=' || i;
                SAVEPOINT sp_mig_referral;
            
                g_error                            := 'l_ref_row / i_id_institution=' || i_id_institution || ' ID_REF=' || l_ref_tab(i)
                                                     .id_external_request;
                l_prof.institution                 := l_ref_tab(i).id_inst_dest;
                l_ref_row.id_external_request      := l_ref_tab(i).id_external_request;
                l_ref_row.id_patient               := l_ref_tab(i).id_patient;
                l_ref_row.id_dep_clin_serv         := l_ref_tab(i).id_dep_clin_serv;
                l_ref_row.id_schedule              := l_ref_tab(i).id_schedule;
                l_ref_row.id_prof_requested        := l_ref_tab(i).id_prof_requested;
                l_ref_row.num_req                  := l_ref_tab(i).num_req;
                l_ref_row.flg_status               := l_ref_tab(i).flg_status;
                l_ref_row.flg_digital_doc          := l_ref_tab(i).flg_digital_doc;
                l_ref_row.flg_mail                 := l_ref_tab(i).flg_mail;
                l_ref_row.flg_paper_doc            := l_ref_tab(i).flg_paper_doc;
                l_ref_row.flg_priority             := l_ref_tab(i).flg_priority;
                l_ref_row.flg_type                 := l_ref_tab(i).flg_type;
                l_ref_row.id_inst_dest             := l_ref_tab(i).id_inst_dest;
                l_ref_row.id_inst_orig             := l_ref_tab(i).id_inst_orig;
                l_ref_row.req_type                 := l_ref_tab(i).req_type;
                l_ref_row.flg_home                 := l_ref_tab(i).flg_home;
                l_ref_row.decision_urg_level       := l_ref_tab(i).decision_urg_level;
                l_ref_row.id_prof_status           := l_ref_tab(i).id_prof_status;
                l_ref_row.id_speciality            := l_ref_tab(i).id_speciality;
                l_ref_row.flg_import               := l_ref_tab(i).flg_import;
                l_ref_row.dt_last_interaction_tstz := l_ref_tab(i).dt_last_interaction_tstz;
                l_ref_row.dt_status_tstz           := l_ref_tab(i).dt_status_tstz;
                l_ref_row.dt_requested             := l_ref_tab(i).dt_requested;
                l_ref_row.flg_interface            := l_ref_tab(i).flg_interface;
                l_ref_row.id_episode               := l_ref_tab(i).id_episode;
                l_ref_row.flg_forward_dcs          := l_ref_tab(i).flg_forward_dcs;
                l_ref_row.id_workflow              := l_ref_tab(i).id_workflow;
                l_ref_row.id_prof_redirected       := l_ref_tab(i).id_prof_redirected;
                l_ref_row.ext_reference            := l_ref_tab(i).ext_reference;
                l_ref_row.id_external_sys          := l_ref_tab(i).id_external_sys;
                l_ref_row.id_prof_created          := l_ref_tab(i).id_prof_created;
                -- problem begin date
                --l_ref_row.dt_probl_begin_tstz := l_ref_tab(i).dt_probl_begin_tstz; -- ALERT-194568
                l_ref_row.year_begin  := l_ref_tab(i).year_begin;
                l_ref_row.month_begin := l_ref_tab(i).month_begin;
                l_ref_row.day_begin   := l_ref_tab(i).day_begin;
            
                BEGIN
                    -- check if referral is valid for migration
                    g_error  := 'Call check_ref_conditions / ID_REF=' || l_ref_tab(i).id_external_request ||
                                ' ID_INST_DEST=' || i_id_institution;
                    g_retval := check_ref_conditions(i_lang         => l_lang,
                                                     i_prof         => l_prof,
                                                     i_ref_row      => l_ref_row,
                                                     i_id_inst_dest => i_id_institution,
                                                     o_error        => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    -- Migrate referral 
                    g_error  := 'Call check_ref_conditions / ID_REF=' || l_ref_tab(i).id_external_request ||
                                ' ID_INST_DEST=' || i_id_institution || ' i_default_dcs=' || i_default_dcs ||
                                ' l_flg_ws=' || l_flg_ws;
                    g_retval := mig_ref_dest_institution(i_lang             => l_lang,
                                                         i_prof             => l_prof,
                                                         i_ref_row          => l_ref_row,
                                                         i_id_inst_dest_new => i_id_institution,
                                                         i_default_dcs      => i_default_dcs,
                                                         i_notes            => i_notes,
                                                         i_op_date          => l_op_date,
                                                         i_flg_ws           => l_flg_ws,
                                                         o_error            => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    -- log with success
                    g_error  := 'Call pk_ref_api.create_ref_mig_inst / ID_REF=' || l_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || i_id_institution || ' i_flg_result=' ||
                                pk_ref_constant.g_mig_successful || ' l_seq_number=' || l_seq_number;
                    g_retval := pk_ref_api.create_ref_mig_inst(i_lang             => l_lang,
                                                               i_prof             => l_prof,
                                                               i_id_ref           => l_ref_row.id_external_request,
                                                               i_id_inst_dest_new => i_id_institution,
                                                               i_flg_result       => pk_ref_constant.g_mig_successful,
                                                               o_error            => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                    g_error  := 'Call pk_ref_api.set_ref_mig_inst_data / ID_REF=' || l_ref_row.id_external_request ||
                                ' ID_INST_DEST=' || i_id_institution || ' i_flg_result=' ||
                                pk_ref_constant.g_mig_successful;
                    g_retval := pk_ref_api.set_ref_mig_inst_data(i_lang          => l_lang,
                                                                 i_prof          => l_prof,
                                                                 i_id_ref        => l_ref_row.id_external_request,
                                                                 i_id_inst_dest  => i_id_institution,
                                                                 i_flg_processed => pk_ref_constant.g_mig_successful,
                                                                 o_error         => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                EXCEPTION
                    WHEN g_exception_np THEN
                        ROLLBACK TO sp_mig_referral; -- savepoint
                        pk_alertlog.log_warn(g_error);
                        --g_error  := 'LCALL=' || o_error.log_id || ' / ' || o_error.err_desc;
                        g_error  := o_error.ora_sqlerrm;
                        g_retval := pk_ref_api.create_ref_mig_inst(i_lang             => l_lang,
                                                                   i_prof             => l_prof,
                                                                   i_id_ref           => l_ref_row.id_external_request,
                                                                   i_id_inst_dest_new => i_id_institution,
                                                                   i_flg_result       => pk_ref_constant.g_mig_unsuccessful,
                                                                   i_error_desc       => g_error,
                                                                   o_error            => o_error);
                        g_retval := pk_ref_api.set_ref_mig_inst_data(i_lang          => l_lang,
                                                                     i_prof          => l_prof,
                                                                     i_id_ref        => l_ref_row.id_external_request,
                                                                     i_id_inst_dest  => i_id_institution,
                                                                     i_flg_processed => pk_ref_constant.g_mig_unsuccessful,
                                                                     o_error         => o_error);
                        pk_alert_exceptions.reset_error_state();
                    WHEN OTHERS THEN
                        ROLLBACK TO sp_mig_referral; -- savepoint
                        pk_alertlog.log_warn(g_error);
                        --g_error := 'LCALL=' || o_error.log_id || ' / ' || o_error.err_desc;
                        g_error  := o_error.ora_sqlerrm;
                        g_retval := pk_ref_api.create_ref_mig_inst(i_lang             => l_lang,
                                                                   i_prof             => l_prof,
                                                                   i_id_ref           => l_ref_row.id_external_request,
                                                                   i_id_inst_dest_new => i_id_institution,
                                                                   i_flg_result       => pk_ref_constant.g_mig_unsuccessful,
                                                                   i_error_desc       => g_error,
                                                                   o_error            => o_error);
                        g_retval := pk_ref_api.set_ref_mig_inst_data(i_lang          => l_lang,
                                                                     i_prof          => l_prof,
                                                                     i_id_ref        => l_ref_row.id_external_request,
                                                                     i_id_inst_dest  => i_id_institution,
                                                                     i_flg_processed => pk_ref_constant.g_mig_unsuccessful,
                                                                     o_error         => o_error);
                        pk_alert_exceptions.reset_error_state();
                END;
            END LOOP;
        
            COMMIT;
        
            g_error := 'EXIT WHEN l_ref_tab.count < l_limit / i_id_institution=' || i_id_institution || ' ID_REF=' ||
                       l_ref_row.id_external_request;
            EXIT WHEN l_ref_tab.count < l_limit;
        
        END LOOP;
    
        g_error := 'CLOSE c_ref < l_limit / i_id_institution=' || i_id_institution || ' i_id_ref_tab.count=' ||
                   i_id_ref_tab.count || ' ID_REF=' || l_ref_row.id_external_request;
        CLOSE c_ref;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.process_error(i_lang        => l_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'MIG_REF_DEST_INSTITUTION',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END mig_ref_dest_institution;

    /**
    * Migrate a referral to a different dest institution
    * This function has COMMITs/ROLLBACKs
    *
    * @param   i_default_dcs       Indicates if dep_clin_serv is mapped or calculated by default
    * @param   i_notes             Notes associated to the migration
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_default_dcs       {*} Y- calculated by default for the referral speciality {*} N- calculated from table MAP
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION mig_ref_dest_institution
    (
        i_default_dcs IN VARCHAR2 DEFAULT pk_ref_constant.g_yes,
        i_notes       IN VARCHAR2 DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_validate IS
            SELECT 1
              FROM ref_mig_inst_dest_data d
             WHERE d.flg_processed = pk_ref_constant.g_no
             GROUP BY d.id_external_request
            HAVING COUNT(1) > 1;
    
        CURSOR c_ref IS
            SELECT d.id_inst_dest,
                   CAST(MULTISET (SELECT i.id_external_request
                           FROM ref_mig_inst_dest_data i
                          WHERE i.id_inst_dest = d.id_inst_dest
                            AND i.flg_processed = pk_ref_constant.g_no
                          ORDER BY 1) AS table_number) AS id_ref_tab
              FROM ref_mig_inst_dest_data d
             WHERE d.flg_processed = pk_ref_constant.g_no
             GROUP BY d.id_inst_dest;
    
        TYPE t_ref_tab IS TABLE OF table_number;
        l_ref_tab_tab t_ref_tab;
    
        l_lang        language.id_language%TYPE;
        l_id_inst_tab table_number;
        l_count       PLS_INTEGER;
    BEGIN
        g_error := 'Init mig_ref_dest_institution / i_default_dcs=' || i_default_dcs;
        pk_alertlog.log_debug(g_error);
        l_lang := 1;
    
        -- validate data in ref_mig_inst_dest_data
        -- id_external_request cannot be duplicated when flg_processed=N
        g_error := 'Validate table ref_mig_inst_dest_data';
        OPEN c_validate;
        FETCH c_validate
            INTO l_count;
        CLOSE c_validate;
    
        IF l_count IS NOT NULL
        THEN
            g_error := 'Invalid data in table ref_mig_inst_dest_data';
            RAISE g_exception;
        END IF;
    
        -- getting data to be migrated    
        OPEN c_ref;
        FETCH c_ref BULK COLLECT
            INTO l_id_inst_tab, l_ref_tab_tab;
        CLOSE c_ref;
    
        IF l_id_inst_tab.count = 0
        THEN
            g_error := 'Nothing to migrate';
            RAISE g_exception;
        END IF;
    
        -- migrate referrals
        FOR i IN 1 .. l_id_inst_tab.count
        LOOP
        
            g_error  := 'Call mig_ref_dest_institution / ID_INST_DEST=' || l_id_inst_tab(i) || ' refs_count=' ||
                        l_ref_tab_tab.count;
            g_retval := mig_ref_dest_institution(i_id_ref_tab     => l_ref_tab_tab(i),
                                                 i_id_institution => l_id_inst_tab(i),
                                                 i_default_dcs    => i_default_dcs,
                                                 i_notes          => i_notes,
                                                 o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.process_error(i_lang        => l_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_owner,
                                              i_package     => g_package,
                                              i_function    => 'MIG_REF_DEST_INSTITUTION',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END mig_ref_dest_institution;

BEGIN
    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_referral;
/
