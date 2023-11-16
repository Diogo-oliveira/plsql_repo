/*-- Last Change Revision: $Rev: 2027602 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_utils AS

    g_error VARCHAR2(1000 CHAR);

    --g_sysdate_tstz  TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION; -- do not process exception with PK_ALERT_EXCEPTIONS
    g_retval BOOLEAN;
    --g_found  BOOLEAN;

    TYPE t_sd IS RECORD(
        desc_val sys_domain.desc_val%TYPE,
        rank     sys_domain.rank%TYPE,
        img_name sys_domain.img_name%TYPE);
    TYPE t_sd_val IS TABLE OF t_sd INDEX BY VARCHAR2(4000); --index -> val
    TYPE t_sd_code IS TABLE OF t_sd_val INDEX BY VARCHAR2(200); --index -> code_domain
    TYPE t_sd_lang IS TABLE OF t_sd_code INDEX BY PLS_INTEGER; --index -> id_language

    g_sd_all_cache t_sd_lang;

    TYPE ibt_vc_sc IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(4000);
    TYPE ibt_num_inst IS TABLE OF ibt_vc_sc INDEX BY BINARY_INTEGER;
    TYPE ibt_num_soft IS TABLE OF ibt_num_inst INDEX BY BINARY_INTEGER;

    g_ibt_sysconfig ibt_num_soft;

    -- referral context variables
    g_ref_context t_rec_ref_context;

    /**
    * Returns the external request's workflow.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_ext_sys           Patients Id
    * @param i_id_inst_orig         Institution where the referral was created
    * @param i_id_inst_dest         Destination Institution of the referral  
    * @param i_detail               detail of the referral, used to differentiate 2 circle WF 
    *
    * @return                       id_workflow
    *
    * @author   João Almeida
    * @version  2.6.03
    * @since    2010/07/26
    */
    FUNCTION get_workflow
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        i_detail       IN table_table_varchar
    ) RETURN NUMBER IS
        g_error_out         t_error_out;
        l_ref_external_inst sys_config.value%TYPE;
        l_inst_orig_type    institution.flg_type%TYPE;
        l_inst_dest_type    institution.flg_type%TYPE;
        l_ext_sys_fertis    sys_config.value%TYPE;
    
    BEGIN
        g_error             := 'GET REF_EXTERNAL_INST value';
        l_ref_external_inst := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_external_inst,
                                                       i_prof    => i_prof);
    
        g_error  := 'GET inst_orig type';
        g_retval := get_inst_type(i_lang      => i_lang,
                                  i_prof      => i_prof, --profissional(i_prof.id, i_id_inst_orig, i_prof.software),
                                  i_id_inst   => i_id_inst_orig,
                                  o_inst_type => l_inst_orig_type,
                                  o_error     => g_error_out);
    
        g_error  := 'GET inst_dest type';
        g_retval := get_inst_type(i_lang      => i_lang,
                                  i_prof      => i_prof, --profissional(i_prof.id, i_id_inst_dest, i_prof.software),
                                  i_id_inst   => i_id_inst_dest,
                                  o_inst_type => l_inst_dest_type,
                                  o_error     => g_error_out);
    
        IF i_id_ext_sys = pk_ref_constant.g_ext_sys_pas
        THEN
        
            FOR i IN 1 .. i_detail.count
            LOOP
                IF i_detail(i) (2) = pk_ref_constant.g_detail_type_ubrn
                THEN
                    RETURN pk_ref_constant.g_wf_circle_cb;
                END IF;
            END LOOP;
        
            RETURN pk_ref_constant.g_wf_circle_normal;
        
        END IF;
    
        -- Important note:
        -- ALERT-262716 - for interface purposes, 'At hospital entrance' only considers origin institution as external. 
        -- By interface, the referrals must be created with the original workflows (if institution is not external) and not as WF=4
        IF l_ref_external_inst = i_id_inst_orig
           AND l_inst_dest_type = pk_ref_constant.g_hospital
        THEN
            RETURN pk_ref_constant.g_wf_x_hosp;
        END IF;
    
        g_error          := 'GET FERTIS_EXT_SYS';
        l_ext_sys_fertis := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ext_sys_fertis, i_prof => i_prof);
    
        IF i_id_ext_sys = l_ext_sys_fertis
        THEN
            RETURN pk_ref_constant.g_wf_fertis;
        END IF;
    
        IF i_id_inst_orig = i_id_inst_dest
           AND l_inst_orig_type = pk_ref_constant.g_hospital
        THEN
            RETURN pk_ref_constant.g_wf_srv_srv;
        END IF;
    
        IF l_inst_orig_type = pk_ref_constant.g_hospital
          --AND l_inst_dest_type = pk_ref_constant.g_hospital
           AND i_id_inst_orig != i_id_inst_dest
        THEN
            RETURN pk_ref_constant.g_wf_hosp_hosp;
        END IF;
    
        IF l_inst_orig_type = pk_ref_constant.g_primary_care
          --AND l_inst_dest_type = pk_ref_constant.g_hospital
           AND i_id_inst_orig != i_id_inst_dest
        THEN
            RETURN NULL; --pk_ref_constant.g_wf_pcc_hosp; -- while framework workflows is not used
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            g_error := g_error || ' / I_PROF=' || pk_utils.to_string(i_prof);
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
        
    END get_workflow;

    /**
    * Returns the patient photo or silhuette.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patients Id
    * @param i_id_ext_req           id_external_request
    *
    * @return                       The patient s photo
    *
    * @author   João Almeida
    * @version  2.6
    * @since    2010/03/15
    */
    FUNCTION get_pat_photo
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2 IS
        l_result PLS_INTEGER;
        l_vip    sys_config.value%TYPE;
    BEGIN
    
        g_error  := 'Init get_pat_photo / ID_PATIENT=' || i_id_patient || ' ID_REF=' || i_id_ext_req;
        l_result := pk_p1_external_request.check_prof_resp(i_lang, i_prof, i_id_ext_req);
        l_vip    := nvl(pk_sysconfig.get_config(i_code_cf => 'REF_VIP_AVAILABLE', i_prof => i_prof),
                        pk_ref_constant.g_no);
    
        IF l_result = pk_p1_external_request.g_i_true
           OR l_vip = pk_ref_constant.g_no
        THEN
            RETURN pk_patphoto.get_pat_foto(i_id_patient, i_prof);
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
        
            RETURN NULL;
        
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error('i_id_ext_req : ' || i_id_ext_req || ' i_prof.institution : ' ||
                                           i_prof.institution || ' i_prof.software : ' || i_prof.software ||
                                           '  i_prof.id :: ' || i_prof.id || ' / ' || SQLERRM);
            RETURN NULL;
        
    END get_pat_photo;

    /**
    * Return institution flag type
    *
    * @param   i_lang application language
    * @param   i_prof professional using the application
    * @param   i_id_inst       institution identifier
    * @param   o_inst_type institution type
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   01-03-2010   
    */
    FUNCTION get_inst_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_inst   IN institution.id_institution%TYPE,
        o_inst_type OUT institution.flg_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_inst_type / i_id_inst=' || i_id_inst;
        SELECT i.flg_type
          INTO o_inst_type
          FROM institution i
         WHERE i.id_institution = i_id_inst
           AND rownum <= 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := g_error || ' / I_PROF=' || pk_utils.to_string(i_prof);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_INST_TYPE',
                                                     o_error    => o_error);
    END get_inst_type;

    /**
    * Return last status change data for the request and
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_data last record data
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007   
    */
    FUNCTION get_status_data
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        o_data       OUT p1_tracking%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Se ha  mais do que um registo neste estado devolve a data do mais recente.
        g_error := 'Init get_status_data / ID_REF=' || i_id_ext_req || ' FLG_STATUS=' || i_flg_status;
        SELECT *
          INTO o_data
          FROM (SELECT *
                  FROM p1_tracking exrt
                 WHERE exrt.id_external_request = i_id_ext_req
                   AND ext_req_status = i_flg_status
                      -- JS: 25-09-08: Correccao para o estado R
                      -- AM: 03-11-08: Retirado g_tracking_type_c
                   AND flg_type IN (pk_ref_constant.g_tracking_type_s, pk_ref_constant.g_tracking_type_p)
                 ORDER BY dt_tracking_tstz DESC)
         WHERE rownum <= 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_STATUS_DATA',
                                                     o_error    => o_error);
    END get_status_data;

    /**
    * Returns the previous status change data for the referral
    *
    * @param   i_lang      Language identifier
    * @param   i_prof      Professional id, institution and software    
    * @param   i_id_ref    Referral identifier
    * @param   o_data      Last record data
    * @param   o_error     Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-09-2010   
    */
    FUNCTION get_prev_status_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_data   OUT p1_tracking%ROWTYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref IS
            SELECT *
              FROM (SELECT *
                      FROM p1_tracking t
                     WHERE t.id_external_request = i_id_ref
                       AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                        pk_ref_constant.g_tracking_type_p,
                                        pk_ref_constant.g_tracking_type_c)
                     ORDER BY t.dt_tracking_tstz DESC)
             WHERE rownum <= 2;
    BEGIN
    
        g_error := 'Init get_prev_status_data / ID_REF=' || i_id_ref;
        OPEN c_ref;
    
        FETCH c_ref
            INTO o_data; -- actual status
    
        o_data := NULL;
    
        FETCH c_ref
            INTO o_data; -- previous status           
    
        CLOSE c_ref;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_PREV_STATUS_DATA',
                                                     o_error    => o_error);
    END get_prev_status_data;

    /**
    * Returns the current status change data for the referral
    *
    * @param   i_lang      Language identifier
    * @param   i_prof      Professional id, institution and software    
    * @param   i_id_ref    Referral identifier
    * @param   o_data      Last record data
    * @param   o_error     Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2010   
    */
    FUNCTION get_cur_status_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_data   OUT p1_tracking%ROWTYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref IS
            SELECT *
              FROM (SELECT *
                      FROM p1_tracking t
                     WHERE t.id_external_request = i_id_ref
                       AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                        pk_ref_constant.g_tracking_type_p,
                                        pk_ref_constant.g_tracking_type_c)
                     ORDER BY t.dt_tracking_tstz DESC)
             WHERE rownum <= 2;
    BEGIN
    
        g_error := 'Init get_prev_status_data / ID_REF=' || i_id_ref;
        OPEN c_ref;
    
        FETCH c_ref
            INTO o_data; -- actual status
    
        CLOSE c_ref;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_CUR_STATUS_DATA',
                                                     o_error    => o_error);
    END get_cur_status_data;

    /**
    * Returns the current action identifier (related to the current status change)
    *
    * @param   i_lang      Language identifier
    * @param   i_prof      Professional id, institution and software    
    * @param   i_id_ref    Referral identifier
    *
    * @RETURN  action identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2010   
    */
    FUNCTION get_cur_action
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN p1_tracking.id_workflow_action%TYPE IS
        l_track_row p1_tracking%ROWTYPE;
        l_error     t_error_out;
    BEGIN
    
        g_error  := 'Call get_cur_status_data / ID_REF=' || i_id_ref;
        g_retval := get_cur_status_data(i_lang   => i_lang,
                                        i_prof   => i_prof,
                                        i_id_ref => i_id_ref,
                                        o_data   => l_track_row,
                                        o_error  => l_error);
    
        RETURN l_track_row.id_workflow_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || l_error.ora_sqlcode;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_cur_action;

    /**
    * Return last status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_status_date
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        retval  BOOLEAN;
        l_data  p1_tracking%ROWTYPE;
        l_error t_error_out;
    BEGIN
    
        g_error := 'Call get_status_data / ID_REF=' || i_id_ext_req || ' FLG_STATUS=' || i_flg_status;
        retval  := get_status_data(i_lang, i_id_ext_req, i_flg_status, l_data, l_error);
    
        IF NOT retval
        THEN
            g_error := 'ERROR: ' || g_error;
            pk_alertlog.log_debug(g_error);
            RETURN NULL;
        ELSE
            RETURN l_data.dt_tracking_tstz;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_status_date;

    /**
    * Return first status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-03-2009
    */
    FUNCTION get_first_status_date
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_dt_tracking_tstz p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
    
        -- Se ha  mais do que um registo neste estado devolve a data do mais antigo. [ALERT-21459]
        g_error := 'Init get_first_status_date / ID_REF=' || i_id_ext_req || ' FLG_STATUS=' || i_flg_status;
        SELECT dt_tracking_tstz
          INTO l_dt_tracking_tstz
          FROM (SELECT dt_tracking_tstz
                  FROM p1_tracking exrt
                 WHERE exrt.id_external_request = i_id_ext_req
                   AND ext_req_status = i_flg_status
                   AND flg_type IN (pk_ref_constant.g_tracking_type_s, pk_ref_constant.g_tracking_type_p)
                 ORDER BY dt_tracking_tstz ASC)
         WHERE rownum <= 1;
    
        RETURN l_dt_tracking_tstz;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_debug(g_error);
            RETURN NULL;
    END get_first_status_date;

    /**
    * Returns referral active appointment date
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   o_dt_schedule    Referral active appointment date 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-11-2009
    */
    FUNCTION get_ref_schedule_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        o_dt_schedule OUT schedule.dt_begin_tstz%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sch IS
            SELECT s.dt_begin_tstz
              FROM p1_external_request exr
              JOIN schedule s
                ON (exr.id_schedule = s.id_schedule AND s.flg_status = pk_ref_constant.g_active)
             WHERE exr.id_external_request = i_id_ref;
    BEGIN
    
        -- getting active appointment date        
        g_error := 'GET_REF_SCHEDULE_DATE / OPEN c_sch / ID_REF=' || i_id_ref;
        --pk_alertlog.log_debug(g_error);
        OPEN c_sch;
        FETCH c_sch
            INTO o_dt_schedule;
        CLOSE c_sch;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_SCHEDULE_DATE',
                                              o_error    => o_error);
            IF c_sch%ISOPEN
            THEN
                CLOSE c_sch;
            END IF;
            RETURN FALSE;
    END get_ref_schedule_date;

    /**
    * Returns referral data in a string
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_ref_row        Referral row
    *
    * @RETURN  Referral data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-02-2010
    */
    FUNCTION to_string
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ref_row IN p1_external_request%ROWTYPE
    ) RETURN VARCHAR2 IS
        l_ref_str VARCHAR2(1000 CHAR);
    BEGIN
        g_error   := 'to_string / ID_REF=' || i_ref_row.id_external_request;
        l_ref_str := ' ID_EXTERNAL_REQUEST=' || i_ref_row.id_external_request || ' ID_PATIENT=' || i_ref_row.id_patient ||
                     ' ID_DEP_CLIN_SERV=' || i_ref_row.id_dep_clin_serv || ' ID_SCHEDULE=' || i_ref_row.id_schedule ||
                     ' ID_PROF_REQUESTED=' || i_ref_row.id_prof_requested || ' NUM_REQ=' || i_ref_row.num_req ||
                     ' FLG_STATUS=' || i_ref_row.flg_status || ' FLG_DIGITAL_DOC=' || i_ref_row.flg_digital_doc ||
                     ' FLG_MAIL=' || i_ref_row.flg_mail || ' FLG_PAPER_DOC=' || i_ref_row.flg_paper_doc ||
                     ' FLG_PRIORITY=' || i_ref_row.flg_priority || ' FLG_TYPE=' || i_ref_row.flg_type ||
                     ' ID_INST_DEST=' || i_ref_row.id_inst_dest || ' ID_INST_ORIG=' || i_ref_row.id_inst_orig ||
                     ' REQ_TYPE=' || i_ref_row.req_type || ' FLG_HOME=' || i_ref_row.flg_home || ' DECISION_URG_LEVEL=' ||
                     i_ref_row.decision_urg_level || ' ID_PROF_STATUS=' || i_ref_row.id_prof_status ||
                     ' ID_SPECIALITY=' || i_ref_row.id_speciality || ' FLG_IMPORT=' || i_ref_row.flg_import ||
                     ' DT_LAST_INTERACTION_TSTZ=' ||
                     pk_date_utils.to_char_insttimezone(i_prof,
                                                        i_ref_row.dt_last_interaction_tstz,
                                                        pk_ref_constant.g_format_date_2) || ' YEAR_BEGIN=' ||
                     i_ref_row.year_begin || ' MONTH_BEGIN=' || i_ref_row.month_begin || ' DAY_BEGIN=' ||
                     i_ref_row.day_begin || ' DT_STATUS_TSTZ=' ||
                     pk_date_utils.to_char_insttimezone(i_prof,
                                                        i_ref_row.dt_status_tstz,
                                                        pk_ref_constant.g_format_date_2) || ' DT_REQUESTED=' ||
                     pk_date_utils.to_char_insttimezone(i_prof, i_ref_row.dt_requested, pk_ref_constant.g_format_date_2) ||
                     ' FLG_INTERFACE=' || i_ref_row.flg_interface || ' ID_EPISODE=' || i_ref_row.id_episode ||
                     ' FLG_FORWARD_DCS=' || i_ref_row.flg_forward_dcs || ' ID_WORKFLOW=' || i_ref_row.id_workflow ||
                     ' ID_PROF_REDIRECTED=' || i_ref_row.id_prof_redirected || ' EXT_REFERENCE=' ||
                     i_ref_row.ext_reference || ' ID_EXTERNAL_SYS=' || i_ref_row.id_external_sys;
    
        RETURN l_ref_str;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alertlog.log_debug('TO_STRING / ' || g_error);
            RETURN NULL;
    END to_string;

    /**
    * Returns referral detail data in a string
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_detail_row     Referral detail row
    *
    * @RETURN  Referral data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-02-2010
    */
    FUNCTION to_string
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_detail_row IN p1_detail%ROWTYPE
    ) RETURN VARCHAR2 IS
        l_detail_str VARCHAR2(1000 CHAR);
    BEGIN
        g_error      := 'to_string 2 / ID_DETAIL=' || i_detail_row.id_detail;
        l_detail_str := ' ID_DETAIL=' || i_detail_row.id_detail || ' ID_EXTERNAL_REQUEST=' ||
                        i_detail_row.id_external_request || ' FLG_TYPE=' || i_detail_row.flg_type ||
                        ' ID_PROFESSIONAL=' || i_detail_row.id_professional || ' ID_INSTITUTION=' ||
                        i_detail_row.id_institution || ' ID_TRACKING=' || i_detail_row.id_tracking || ' FLG_STATUS=' ||
                        i_detail_row.flg_status || ' DT_INSERT_TSTZ=' ||
                        pk_date_utils.to_char_insttimezone(i_prof,
                                                           i_detail_row.dt_insert_tstz,
                                                           pk_ref_constant.g_format_date_2) || ' ID_GROUP=' ||
                        i_detail_row.id_group || ' TEXT=' || i_detail_row.text;
    
        RETURN l_detail_str;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alertlog.log_debug('to_string / ' || g_error);
            RETURN NULL;
    END to_string;

    /**
    * Returns referral tracking data in a string
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_tracking_row   Referral tracking row
    *
    * @RETURN  Referral data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-03-2010
    */
    FUNCTION to_string
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tracking_row IN p1_tracking%ROWTYPE
    ) RETURN VARCHAR2 IS
        l_tracking_str VARCHAR2(1000 CHAR);
    BEGIN
    
        g_error        := 'to_string 2 / ID_TRACKING=' || i_tracking_row.id_tracking;
        l_tracking_str := ' ID_TRACKING=' || i_tracking_row.id_tracking || ' EXT_REQ_STATUS=' ||
                          i_tracking_row.ext_req_status || ' ACTION=' || i_tracking_row.id_workflow_action ||
                          ' ID_EXTERNAL_REQUEST=' || i_tracking_row.id_external_request || ' ID_INSTITUTION=' ||
                          i_tracking_row.id_institution || ' ID_PROFESSIONAL=' || i_tracking_row.id_professional ||
                          ' FLG_TYPE=' || i_tracking_row.flg_type || ' ID_PROF_DEST=' || i_tracking_row.id_prof_dest ||
                          ' ID_DEP_CLIN_SERV=' || i_tracking_row.id_dep_clin_serv || ' ROUND_ID=' ||
                          i_tracking_row.round_id || ' REASON_CODE=' || i_tracking_row.reason_code ||
                          ' FLG_RESCHEDULE=' || i_tracking_row.flg_reschedule || ' FLG_SUBTYPE=' ||
                          i_tracking_row.flg_subtype || ' DECISION_URG_LEVEL=' || i_tracking_row.decision_urg_level ||
                          ' DT_TRACKING_TSTZ=' ||
                          pk_date_utils.to_char_insttimezone(i_prof,
                                                             i_tracking_row.dt_tracking_tstz,
                                                             pk_ref_constant.g_format_date_2) || ' ID_REASON_CODE=' ||
                          i_tracking_row.id_reason_code || ' ID_SCHEDULE=' || i_tracking_row.id_schedule ||
                          ' ID_INST_DEST=' || i_tracking_row.id_inst_dest;
        RETURN l_tracking_str;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alertlog.log_debug('TO_STRING / ' || g_error);
            RETURN NULL;
    END to_string;

    /**
    * Returns referral detail date
    *
    * @param  i_lang          Language
    * @param   i_id_ref         Referral identifier
    * @param   i_flg_status     Referral status
    * @param   i_id_workflow    Referral's Workflow
    *
    * @RETURN  
    * @author  João Almeida
    * @version 1.0
    * @since   25-02-2010
    */
    FUNCTION get_ref_detail_date
    (
        i_lang        IN language.id_language%TYPE,
        i_id_ext_req  IN p1_tracking.id_external_request%TYPE,
        i_flg_status  IN p1_tracking.ext_req_status%TYPE,
        i_id_workflow IN p1_external_request.id_workflow%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    BEGIN
        -- getting referral detail date        
        g_error := 'GET_REF_DETAIL_DATE / ID_WF=' || i_id_workflow || ' ID_REF=' || i_id_ext_req || ' FLG_STATUS=' ||
                   i_flg_status;
        -- ALERT-87339 - removed wf pk_ref_constant.g_wf_x_hosp        
        CASE
            WHEN i_flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_p) THEN
                RETURN get_status_date(i_lang, i_id_ext_req, i_flg_status);
            WHEN i_flg_status IN (pk_ref_constant.g_p1_status_c) THEN
                RETURN get_first_status_date(i_lang, i_id_ext_req, pk_ref_constant.g_p1_status_c);
            ELSE
                IF i_id_workflow = pk_ref_constant.g_wf_gp
                THEN
                    RETURN get_first_status_date(i_lang, i_id_ext_req, pk_ref_constant.g_p1_status_a);
                ELSE
                    RETURN get_first_status_date(i_lang, i_id_ext_req, pk_ref_constant.g_p1_status_n);
                END IF;
        END CASE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_ref_detail_date;

    /**
    * Returns referral detail date
    *
    * @param   i_lang          Language
    * @param   i_id_ref         Referral identifier
    *
    * @RETURN  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2010
    */
    FUNCTION get_ref_detail_date
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ext_req IN p1_tracking.id_external_request%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_flg_status p1_external_request.flg_status%TYPE;
        l_error      t_error_out;
    BEGIN
        -- getting referral detail date        
        g_error  := 'Call pk_p1_external_request.get_flg_status / ID_REF=' || i_id_ext_req;
        g_retval := pk_p1_external_request.get_flg_status(i_lang       => i_lang,
                                                          i_id_ref     => i_id_ext_req,
                                                          o_flg_status => l_flg_status,
                                                          o_error      => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Call get_ref_detail_date / ID_REF=' || i_id_ext_req;
        RETURN get_ref_detail_date(i_lang        => i_lang,
                                   i_id_ext_req  => i_id_ext_req,
                                   i_flg_status  => l_flg_status,
                                   i_id_workflow => NULL);
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_ref_detail_date;

    /**
    * Returns the professional name that is responsible for the referral 
    * Used by reports
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_professional    Identifier of the professional    
    * @param   i_id_instititution   Institutions Identifier   
    *
    * @RETURN  VARCHAR2
    * @author  João Almeida
    * @version 0.1
    * @since   20-04-2010   
    */
    FUNCTION get_prof_spec_signature
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_instititution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_category category.flg_type%TYPE := NULL;
    BEGIN
        l_prof_category := pk_prof_utils.get_category(i_lang, profissional(i_id_professional, i_id_instititution, 0));
    
        IF l_prof_category != pk_alert_constant.g_cat_type_registrar
        THEN
            RETURN pk_prof_utils.get_spec_signature(i_lang, i_prof, i_id_professional, i_id_instititution);
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alertlog.log_debug(g_error);
            RETURN NULL;
    END get_prof_spec_signature;

    /**
    * Gets the last referral tracking row related to triaging referral or canceling referral schedule
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_action         Action pretended: {*} 'A1' Triaging referral
                                                  {*} 'A2' Canceling referral schedule
    * @param   o_track_row      Tracking row
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-04-26
    */
    FUNCTION get_last_track_row
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_action    IN VARCHAR2,
        o_track_row OUT p1_tracking%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tracking(x_id_ref IN p1_external_request.id_external_request%TYPE) IS
            SELECT *
              FROM p1_tracking
             WHERE id_external_request = x_id_ref
               AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                pk_ref_constant.g_tracking_type_p,
                                pk_ref_constant.g_tracking_type_c)
             ORDER BY dt_tracking_tstz DESC;
    
        TYPE t_tracking IS TABLE OF c_tracking%ROWTYPE INDEX BY PLS_INTEGER;
        l_tracking t_tracking;
    
        l_prev_status p1_tracking.ext_req_status%TYPE;
        l_curr_status p1_tracking.ext_req_status%TYPE;
    
        l_prev_id_track     p1_tracking.id_tracking%TYPE;
        l_status_considered VARCHAR2(50 CHAR);
    
    BEGIN
    
        g_error := 'Init get_last_track_row / ID_REF=' || i_id_ref || ' ACTION=' || i_action;
        --pk_alertlog.log_debug(g_error);
    
        IF i_action = 'A1'
        THEN
            l_status_considered := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                                   pk_ref_constant.g_p1_status_a;
        ELSIF i_action = 'A2'
        THEN
            l_status_considered := pk_ref_constant.g_p1_status_s;
        END IF;
    
        g_error := 'OPEN c_tracking(' || i_id_ref || ') / i_action=' || i_action || ' l_status_considered=' ||
                   l_status_considered;
        --pk_alertlog.log_debug(g_error);
    
        OPEN c_tracking(i_id_ref);
        FETCH c_tracking BULK COLLECT
            INTO l_tracking;
        CLOSE c_tracking;
    
        g_error := 'l_tracking.COUNT=' || l_tracking.count;
        --pk_alertlog.log_debug(g_error);
    
        <<loop_tracking>>
        FOR i IN 1 .. l_tracking.count
        LOOP
        
            -- initializing var
            l_curr_status := l_tracking(i).ext_req_status;
        
            g_error := 'l_prev_status=' || l_prev_status || ' l_curr_status=' || l_tracking(i).ext_req_status || ' i=' || i;
            --pk_alertlog.log_debug(g_error);
        
            IF l_prev_status = pk_ref_constant.g_p1_status_a
            THEN
                IF instr(l_status_considered, l_curr_status, 1) > 0
                THEN
                    g_error := 'Event occured / i_action=' || i_action || ' l_curr_status=' || l_curr_status ||
                               ' l_prev_status=' || l_prev_status || ' l_status_considered=' || l_status_considered ||
                               ' l_prev_id_track=' || l_prev_id_track;
                    --pk_alertlog.log_debug(g_error);
                
                    o_track_row := l_tracking(i);
                    EXIT loop_tracking;
                END IF;
            END IF;
        
            g_error         := 'l_prev_status';
            l_prev_status   := l_tracking(i).ext_req_status;
            l_prev_id_track := l_tracking(i).id_tracking;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LAST_TRACK_ROW',
                                              o_error    => o_error);
            IF c_tracking%ISOPEN
            THEN
                CLOSE c_tracking;
            END IF;
            RETURN FALSE;
    END get_last_track_row;

    /**
    * Converts operation date DATE format into TIMESTAMP WITH LOCAL TIME ZONE format
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software
    * @param   i_dt_d     Operation date (DATE format)
    * @param   o_dt_tstz  Operation date (TIMESTAMP WITH LOCAL TIME ZONE format)
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2009
    */
    FUNCTION get_operation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_dt_d    IN DATE,
        o_dt_tstz OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_date_v VARCHAR2(50 CHAR);
    BEGIN
        g_error := 'Init get_operation_date / DATE_D=' || i_dt_d;
        --pk_alertlog.log_debug(g_error);
    
        -- converting DATEs to VARCHARs
        g_error     := 'Converting DATE to VARCHAR';
        l_dt_date_v := to_char(i_dt_d, pk_ref_constant.g_format_date_2);
    
        g_error := g_error || ' DATE_V=' || l_dt_date_v;
        --pk_alertlog.log_debug(g_error);
    
        -- converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs
        g_error   := 'Converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs';
        o_dt_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_timestamp => l_dt_date_v,
                                                   i_timezone  => NULL,
                                                   i_mask      => pk_ref_constant.g_format_date_2);
    
        o_dt_tstz := nvl(o_dt_tstz, current_timestamp);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_OPERATION_DATE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_operation_date;

    /**
    * Returns professional data in a string
    *
    * @param   i_prof_data   Professional data
    *
    * @RETURN  Professional data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2010
    */
    FUNCTION to_string(i_prof_data IN t_rec_prof_data) RETURN VARCHAR2 IS
        l_str VARCHAR2(1000 CHAR);
    BEGIN
        g_error := 'to_string prof_data';
        l_str   := ' PROF_TEMPL=' || i_prof_data.id_profile_template || ' FUNCT=' || i_prof_data.id_functionality ||
                   ' ID_CAT=' || i_prof_data.id_category || ' FLG_CAT=' || i_prof_data.flg_category || ' MARKET=' ||
                   i_prof_data.id_market;
        RETURN l_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug('to_string prof_data / ' || g_error);
            RETURN NULL;
    END to_string;

    /**
    * Gets description messages from sys_message
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_code_msg_arr   Code message array
    * @param   o_desc_msg_ibt   Description message
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-11-2010
    */
    FUNCTION get_message_ibt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_msg_arr  IN table_varchar,
        io_desc_msg_ibt IN OUT NOCOPY pk_ref_constant.ibt_varchar_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cursor       pk_types.cursor_type;
        l_code_message table_varchar;
        l_desc_message table_varchar;
        l_img_name     table_varchar;
        l_limit        PLS_INTEGER := 1000;
    BEGIN
        g_error := 'Init get_message_ibt';
        FOR i IN 1 .. i_code_msg_arr.count
        LOOP
            io_desc_msg_ibt(i_code_msg_arr(i)) := NULL;
        END LOOP;
    
        g_error  := 'Call pk_message.get_message_array';
        g_retval := pk_message.get_message_array(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_code_msg_arr => i_code_msg_arr,
                                                 o_desc_msg_arr => l_cursor);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_code_message, l_desc_message, l_img_name LIMIT l_limit;
        
            g_error := 'l_code_message.COUNT=' || l_code_message.count;
            FOR idx IN 1 .. l_code_message.count
            LOOP
                io_desc_msg_ibt(l_code_message(idx)) := l_desc_message(idx);
            END LOOP;
        
            EXIT WHEN l_code_message.count < l_limit;
        
        END LOOP;
    
        CLOSE l_cursor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_MESSAGE_IBT',
                                              o_error    => o_error);
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            RETURN FALSE;
    END get_message_ibt;

    /**
    * Check if the professional can view the referral clinical data
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_cat                Professional category type
    * @param   i_prof_profile       Professional profile template
    * @param   i_id_prof_requested  Professional identifier that requested the referral
    * @param   i_id_workflow        Workflow ID
    *
    * @RETURN  {*} Y - can view clinical data; {*} N - otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-11-2010
    */
    FUNCTION can_view_clinical_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cat               IN category.flg_type%TYPE,
        i_prof_profile      IN profile_template.id_profile_template%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_workflow       IN wf_workflow.id_workflow%TYPE
    ) RETURN VARCHAR2 IS
        l_cat          category.flg_type%TYPE;
        l_prof_sam     professional.id_professional%TYPE;
        l_prof_profile profile_template.id_profile_template%TYPE;
        l_workflow     p1_external_request.id_prof_requested%TYPE;
    BEGIN
        g_error        := 'Init can_view_clinical_data / i_prof=' || pk_utils.to_string(i_prof) || ' i_cat=' || i_cat;
        l_cat          := nvl(i_cat, pk_tools.get_prof_cat(i_prof => i_prof));
        l_prof_profile := nvl(i_prof_profile, pk_prof_utils.get_prof_profile_template(i_prof => i_prof));
        l_workflow     := nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp);
        -- if is a physician or a technician, can view clinical data
        IF l_cat IN (pk_ref_constant.g_doctor,
                     pk_ref_constant.g_nutritionist,
                     pk_ref_constant.g_nurse,
                     pk_ref_constant.g_psychologist)
        THEN
            RETURN pk_ref_constant.g_yes;
        END IF;
    
        g_error    := 'Call pk_sysconfig.get_config / ' || pk_ref_constant.g_ref_prof_not_registered;
        l_prof_sam := to_number(get_sys_config(i_prof          => i_prof,
                                               i_id_sys_config => pk_ref_constant.g_ref_prof_not_registered));
    
        -- if is the professional from SAM external system, can view clinical data
        -- if is the professional that requested the referral (because of "at hospital entrance" workflow, for the clerk)
        -- if is the profile template 312 (Brasil registrar)
        IF i_prof.id = l_prof_sam
           OR i_prof.id = i_id_prof_requested
           OR l_prof_profile = pk_ref_constant.g_profile_adm_cs_br
           OR l_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
            RETURN pk_ref_constant.g_yes;
        END IF;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN pk_ref_constant.g_no;
    END can_view_clinical_data;

    /**
    * This procedure logs a CLOB to alert log tables
    *
    * @param   i_clob            CLOB to print
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   10-05-2010
    */
    PROCEDURE log_clob(i_clob IN CLOB) IS
        l_offset PLS_INTEGER;
        l_qty    PLS_INTEGER;
    BEGIN
    
        l_offset := 1;
        l_qty    := 1000;
    
        g_error := 'CLOB=';
        pk_alertlog.log_debug(g_error);
        LOOP
            EXIT WHEN l_offset > dbms_lob.getlength(i_clob);
        
            g_error := dbms_lob.substr(i_clob, l_qty, l_offset);
            pk_alertlog.log_debug(g_error);
        
            l_offset := l_offset + l_qty;
        END LOOP;
    END log_clob;
    /**
    * Gets institution of the dep_clin_serv
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software
    * @param   i_dcs            Department and clinical service
    * @param   o_id_institution Institution identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-12-2011
    */
    FUNCTION get_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_dcs_inst IS
            SELECT d.id_institution
              FROM dep_clin_serv dcs
              JOIN department d
                ON (d.id_department = dcs.id_department)
             WHERE dcs.id_dep_clin_serv = i_dcs;
    BEGIN
        g_error := 'Init get_institution / i_dcs=' || i_dcs;
        OPEN c_dcs_inst;
        FETCH c_dcs_inst
            INTO o_id_institution;
        CLOSE c_dcs_inst;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INSTITUTION',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_institution;

    /**
    * Check if referral needs to by aprroved By Clinical Director
    * WF = 28 CARE BR
    *
    * @param   i_prof           Id professional, institution and software    
    * @param   i_ref           Referral Id
    * @param   i_flg_type      Referral type {*} 'C' Visit, 
                                             {*} 'A' Analysis 
                                             {*} 'E' Other Exams
                                             {*} 'I' Image
                                             {*} 'P' Procedures                                            
                                             {*} 'F' MFR                                          
    *
    * @RETURN  VARCHAR 
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-12-2012
    */

    FUNCTION check_ref_mcdt_to_aprove
    (
        i_prof     IN profissional,
        i_ref      IN p1_external_request.id_external_request%TYPE,
        i_flg_type IN p1_external_request.flg_type%TYPE
        
    ) RETURN VARCHAR IS
    
        CURSOR c_ref_visit(x_ref p1_external_request.id_external_request%TYPE) IS
            SELECT id_speciality
              FROM p1_external_request
             WHERE id_external_request = x_ref;
        l_row_visit c_ref_visit%ROWTYPE;
    
        CURSOR c_ref_analysis(x_ref p1_external_request.id_external_request%TYPE) IS
            SELECT nvl(pea.id_analysis, pet.id_analysis) id_analysis
              FROM p1_external_request per
              LEFT JOIN p1_exr_analysis pea
                ON per.id_external_request = pea.id_external_request
              LEFT JOIN p1_exr_temp pet
                ON per.id_external_request = per.id_external_request
             WHERE per.id_external_request = x_ref;
        l_row_ref_analysis c_ref_analysis%ROWTYPE;
    
        CURSOR c_ref_exam(x_ref p1_external_request.id_external_request%TYPE) IS
            SELECT nvl(pee.id_exam, pet.id_exam) id_exam
              FROM p1_external_request per
              LEFT JOIN p1_exr_exam pee
                ON per.id_external_request = pee.id_external_request
              LEFT JOIN p1_exr_temp pet
                ON per.id_external_request = per.id_external_request
             WHERE per.id_external_request = x_ref;
        l_row_ref_exam c_ref_exam%ROWTYPE;
    
        CURSOR c_ref_interv(x_ref p1_external_request.id_external_request%TYPE) IS
            SELECT nvl(pei.id_intervention, pet.id_intervention) id_intervention
              FROM p1_external_request per
              LEFT JOIN p1_exr_intervention pei
                ON per.id_external_request = pei.id_external_request
              LEFT JOIN p1_exr_temp pet
                ON per.id_external_request = per.id_external_request
             WHERE per.id_external_request = x_ref;
        l_row_ref_interv c_ref_interv%ROWTYPE;
    
        l_config  sys_config.value%TYPE;
        l_cfg_tab table_varchar;
        l_error   t_error_out;
        l_par_tab table_varchar;
        l_var     PLS_INTEGER;
    
    BEGIN
    
        l_config := nvl(pk_sysconfig.get_config(pk_ref_constant.g_referral_need_aproval, i_prof), 'N');
    
        IF l_config = pk_ref_constant.g_no
        THEN
            RETURN pk_ref_constant.g_no;
        ELSE
        
            IF i_flg_type = pk_ref_constant.g_p1_type_c
            THEN
                g_error  := 'Call pk_sysconfig.get_config / ID_SYSCONFIG=' || pk_ref_constant.g_ref_visit_not_aprove;
                l_config := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_visit_not_aprove, i_prof), '0');
            
                l_cfg_tab := pk_utils.str_split_l(i_list => l_config, i_delim => ',');
                g_error   := '';
                OPEN c_ref_visit(i_ref);
                FETCH c_ref_visit BULK COLLECT
                    INTO l_par_tab;
                CLOSE c_ref_visit;
            
            ELSIF i_flg_type = pk_ref_constant.g_p1_type_a
            THEN
                g_error   := 'Call pk_sysconfig.get_config / ID_SYSCONFIG=' ||
                             pk_ref_constant.g_ref_analysis_not_aprove;
                l_config  := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_analysis_not_aprove, i_prof), '0');
                l_cfg_tab := pk_utils.str_split_l(i_list => l_config, i_delim => ',');
                OPEN c_ref_analysis(i_ref);
                FETCH c_ref_analysis BULK COLLECT
                    INTO l_par_tab;
                CLOSE c_ref_analysis;
            
            ELSIF i_flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i)
            THEN
                g_error   := 'Call pk_sysconfig.get_config / ID_SYSCONFIG=' || pk_ref_constant.g_ref_exam_not_aprove;
                l_config  := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_exam_not_aprove, i_prof), '0');
                l_cfg_tab := pk_utils.str_split_l(i_list => l_config, i_delim => ',');
                OPEN c_ref_exam(i_ref);
                FETCH c_ref_exam BULK COLLECT
                    INTO l_par_tab;
                CLOSE c_ref_exam;
            
            ELSIF i_flg_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f)
            THEN
                g_error   := 'Call pk_sysconfig.get_config / ID_SYSCONFIG=' || pk_ref_constant.g_ref_interv_not_aprove;
                l_config  := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_interv_not_aprove, i_prof), '0');
                l_cfg_tab := pk_utils.str_split_l(i_list => l_config, i_delim => ',');
                OPEN c_ref_interv(i_ref);
                FETCH c_ref_interv BULK COLLECT
                    INTO l_par_tab;
                CLOSE c_ref_interv;
            
            ELSE
                RETURN pk_ref_constant.g_yes;
            END IF;
        
            SELECT COUNT(1)
              INTO l_var
              FROM (SELECT rownum rn, column_value
                      FROM TABLE(CAST(l_cfg_tab AS table_varchar))) tp
              JOIN (SELECT rownum rn, column_value
                      FROM TABLE(CAST(l_par_tab AS table_varchar))) tpid
                ON tpid.column_value = tp.column_value;
        
            IF l_var > 0
            THEN
                RETURN pk_ref_constant.g_no;
            ELSE
                RETURN pk_ref_constant.g_yes;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 0,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_MCDT_TO_APROVE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_yes;
    END check_ref_mcdt_to_aprove;

    /**
    * Gets description domain from sys_domain
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_code_dom_arr   Code domain array
    * @param   io_desc_dom_ibt  Description domain
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.5
    * @since   11-10-2012
    */

    FUNCTION get_all_domains_cached
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_code_dom_arr IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_all_domains_cached';
    BEGIN
        g_error := 'Init ' || g_package_name || '.get_all_domains_cached';
        FOR line IN (SELECT sd.code_domain, sd.id_language, sd.desc_val, sd.val, sd.rank, sd.img_name
                       FROM sys_domain sd
                       JOIN TABLE(CAST(i_code_dom_arr AS table_varchar)) t
                         ON (sd.code_domain = t.column_value)
                      WHERE sd.id_language = i_lang
                        AND sd.domain_owner = pk_sysdomain.k_default_schema
                        AND sd.flg_available = pk_alert_constant.g_yes)
        LOOP
            g_sd_all_cache(line.id_language)(line.code_domain)(line.val).desc_val := line.desc_val;
            g_sd_all_cache(line.id_language)(line.code_domain)(line.val).img_name := line.img_name;
            g_sd_all_cache(line.id_language)(line.code_domain)(line.val).rank := line.rank;
            pk_backoffice_translation.set_read_translation(line.code_domain, 'SYS_DOMAIN');
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_all_domains_cached;

    FUNCTION get_domain_cached
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE,
        i_context     IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_result    VARCHAR2(4000);
        l_error     t_error_out;
        l_func_name VARCHAR2(30) := 'get_domain_cached';
    BEGIN
        IF i_val IS NULL
        THEN
            RETURN NULL;
        ELSIF NOT g_sd_all_cache.exists(i_lang)
              OR NOT g_sd_all_cache(i_lang).exists(i_code_domain)
              OR NOT g_sd_all_cache(i_lang)(i_code_domain).exists(i_val)
        THEN
            g_error  := 'Call' || g_package_name || '.get_all_domains_cached / i_lang=' || i_lang || ' i_code_domain=' ||
                        i_code_domain || ' i_val=' || i_val;
            g_retval := get_all_domains_cached(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_code_dom_arr => table_varchar(i_code_domain),
                                               o_error        => l_error);
            IF NOT g_retval
            THEN
                RETURN NULL;
            END IF;
        
        END IF;
    
        g_error := 'i_context=' || i_context || ' i_lang=' || i_lang || ' i_code_domain=' || i_code_domain || ' i_val=' ||
                   i_val;
        IF i_context = pk_ref_constant.g_context_desc
        THEN
            l_result := g_sd_all_cache(i_lang) (i_code_domain)(i_val).desc_val;
        ELSIF i_context = pk_ref_constant.g_context_rank
        THEN
            l_result := to_char(g_sd_all_cache(i_lang) (i_code_domain)(i_val).rank);
        ELSIF i_context = pk_ref_constant.g_context_img
        THEN
            l_result := g_sd_all_cache(i_lang) (i_code_domain)(i_val).img_name;
        ELSE
            RETURN NULL;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'Error ' || l_func_name || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_domain_cached;

    FUNCTION get_domain_cached_img_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.img_name%TYPE IS
        l_value     sys_domain.img_name%TYPE;
        l_func_name VARCHAR2(30) := 'get_domain_cached_img_name';
    BEGIN
    
        g_error := 'Call' || g_package_name || '.' || l_func_name || ' / I_CODE_DOMAIN=' || i_code_domain || ' I_VAL=' ||
                   i_val;
        l_value := get_domain_cached(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_code_domain => i_code_domain,
                                     i_val         => i_val,
                                     i_context     => pk_ref_constant.g_context_img);
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'Error ' || l_func_name || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_domain_cached_img_name;

    FUNCTION get_domain_cached_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.rank%TYPE IS
        l_value     sys_domain.rank%TYPE;
        l_func_name VARCHAR2(30) := 'get_domain_cached_rank';
    BEGIN
        g_error := 'Call' || g_package_name || '.' || l_func_name || ' / I_CODE_DOMAIN=' || i_code_domain || ' I_VAL=' ||
                   i_val;
        l_value := to_number(get_domain_cached(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_code_domain => i_code_domain,
                                               i_val         => i_val,
                                               i_context     => pk_ref_constant.g_context_rank));
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'Error ' || l_func_name || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_domain_cached_rank;

    FUNCTION get_domain_cached_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
        l_value     sys_domain.desc_val%TYPE;
        l_func_name VARCHAR2(30) := 'get_domain_cached_desc';
    BEGIN
        g_error := 'Call' || g_package_name || '.' || l_func_name || ' / I_CODE_DOMAIN=' || i_code_domain || ' I_VAL=' ||
                   i_val;
        l_value := get_domain_cached(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_code_domain => i_code_domain,
                                     i_val         => i_val,
                                     i_context     => pk_ref_constant.g_context_desc);
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'Error ' || l_func_name || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_domain_cached_desc;

    /**
    * Returns a sys_config value
    *
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_sys_config      Sys config identifier
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-08-2012
    */
    FUNCTION get_sys_config
    (
        i_prof          IN profissional,
        i_id_sys_config IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config.value%TYPE IS
        l_sc_value       sys_config.value%TYPE;
        l_id_software    software.id_software%TYPE;
        l_id_institution institution.id_institution%TYPE;
        l_prof           profissional;
    BEGIN
        l_id_software    := nvl(i_prof.software, 0);
        l_id_institution := nvl(i_prof.institution, 0);
    
        IF NOT g_ibt_sysconfig.exists(l_id_software)
           OR NOT g_ibt_sysconfig(l_id_software).exists(l_id_institution)
           OR NOT g_ibt_sysconfig(l_id_software)(l_id_institution).exists(i_id_sys_config)
           OR g_ibt_sysconfig(l_id_software) (l_id_institution) (i_id_sys_config) IS NULL
        THEN
            l_prof := profissional(i_prof.id, l_id_institution, l_id_software);
            l_sc_value := pk_sysconfig.get_config(i_id_sys_config, l_prof);
            g_ibt_sysconfig(l_id_software)(l_id_institution)(i_id_sys_config) := l_sc_value;
        END IF;
    
        BEGIN
            RETURN g_ibt_sysconfig(l_id_software)(l_id_institution)(i_id_sys_config);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    END get_sys_config;

    /*
    * Compares two timestamps at the minute level only 
    *
    * @param i_timestamp1         Timestamp
    * @param i_timestamp2         Timestamp
    *
    * @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise
    *
    * @author Ana Monteiro
    * @version 1.0
    * @since 17-10-2012
    */
    FUNCTION compare_tsz_min
    (
        i_date1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_date2 IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_date_1 DATE;
        l_date_2 DATE;
    BEGIN
        g_error  := 'Init compare_tsz_min';
        l_date_1 := trunc(i_date1, 'MI');
        l_date_2 := trunc(i_date2, 'MI');
    
        IF l_date_1 > l_date_2
        THEN
            RETURN pk_ref_constant.g_date_greater;
        ELSIF l_date_1 < l_date_2
        THEN
            RETURN pk_ref_constant.g_date_lower;
        ELSIF l_date_1 = l_date_2
        THEN
            RETURN pk_ref_constant.g_date_equal;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLCODE || ' / ' || SQLERRM);
            RETURN NULL;
    END compare_tsz_min;

    /**
    * Parses date string into year, month and day separately
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_dt_str_flash Date in string format YYYY[MM[DD]] (flash interpretation)
    * @param   o_year         Year date
    * @param   o_month        Month date
    * @param   o_day          Day date
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION parse_dt_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dt_str_flash IN VARCHAR,
        o_year         OUT NUMBER,
        o_month        OUT NUMBER,
        o_day          OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params    VARCHAR2(1000 CHAR);
        l_year_chr  VARCHAR2(200 CHAR);
        l_month_chr VARCHAR2(200 CHAR);
        l_day_chr   VARCHAR2(200 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_dt_str_flash=' || i_dt_str_flash;
        g_error  := 'Init parse_dt_probl_begin / ' || l_params;
    
        IF instr(i_dt_str_flash, '-') = 0
        THEN
            g_error := 'CASE ' || length(i_dt_str_flash) || ' / ' || l_params;
            CASE length(i_dt_str_flash)
                WHEN 1 THEN
                    IF i_dt_str_flash <> 'U'
                    THEN
                        RAISE g_exception;
                    END IF;
                    l_year_chr := -1;
                
                WHEN 4 THEN
                    l_year_chr := i_dt_str_flash;
                
                WHEN 6 THEN
                    l_year_chr  := substr(i_dt_str_flash, 1, 4);
                    l_month_chr := substr(i_dt_str_flash, -2, 2);
                
                WHEN 8 THEN
                    l_year_chr  := substr(i_dt_str_flash, 1, 4);
                    l_month_chr := substr(substr(i_dt_str_flash, 1, 6), -2, 2);
                    l_day_chr   := substr(i_dt_str_flash, -2, 2);
                ELSE
                    RAISE g_exception;
            END CASE;
        
        ELSE
            g_error     := 'i_dt_str_flash / ' || l_params;
            l_year_chr  := substr(i_dt_str_flash, 1, instr(i_dt_str_flash, '-') - 1);
            l_month_chr := substr(substr(i_dt_str_flash, instr(i_dt_str_flash, '-') + 1),
                                  1,
                                  instr(substr(i_dt_str_flash, instr(i_dt_str_flash, '-') + 1), '-') - 1);
            l_day_chr   := substr(substr(i_dt_str_flash, instr(i_dt_str_flash, '-') + 1),
                                  instr(substr(i_dt_str_flash, instr(i_dt_str_flash, '-') + 1), '-') + 1);
        END IF;
    
        g_error := 'l_year_chr=' || l_year_chr || ' / ' || l_params;
        IF l_year_chr IS NOT NULL
        THEN
            o_year := to_number(l_year_chr);
        ELSE
            o_year := NULL;
        END IF;
    
        g_error := 'l_month_chr=' || l_month_chr || ' / ' || l_params;
        IF l_month_chr IS NOT NULL
        THEN
            o_month := to_number(l_month_chr);
        ELSE
            o_month := NULL;
        END IF;
    
        g_error := 'l_day_chr=' || l_day_chr || ' / ' || l_params;
        IF l_day_chr IS NOT NULL
        THEN
            o_day := to_number(l_day_chr);
        ELSE
            o_day := NULL;
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
                                              i_function => 'PARSE_DT_STR',
                                              o_error    => o_error);
            RETURN FALSE;
    END parse_dt_str;

    /**
    * Parses date year, month and day into string (for flash interpretation)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids        
    * @param   i_year            Year date
    * @param   i_month           Month date
    * @param   i_day             Day date
    *
    * @RETURN  Problem begin date (string format for flash interpretation)
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION parse_dt_str_flash
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_year  IN NUMBER,
        i_month IN NUMBER,
        i_day   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_params    VARCHAR2(1000 CHAR);
        l_dt_result VARCHAR2(10 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_year=' || i_year || ' i_month=' || i_month ||
                    ' i_day=' || i_day;
        g_error  := 'Init parse_dt_str_flash / ' || l_params;
    
        l_dt_result := '';
    
        IF i_year IS NOT NULL
        THEN
            l_dt_result := i_year;
        
            IF i_month IS NOT NULL
            THEN
                IF length(i_month) = 1
                THEN
                    l_dt_result := l_dt_result || lpad(i_month, 2, '0');
                ELSE
                    l_dt_result := l_dt_result || i_month;
                END IF;
            
                IF i_day IS NOT NULL
                THEN
                    IF length(i_day) = 1
                    THEN
                        l_dt_result := l_dt_result || lpad(i_day, 2, '0');
                    ELSE
                        l_dt_result := l_dt_result || i_day;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_dt_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error || ' / ' || SQLCODE || ' / ' || SQLERRM);
            RETURN NULL;
    END parse_dt_str_flash;

    /**
    * Parses date year, month and day into string (to be shown in flash and reports)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids        
    * @param   i_year            Year date
    * @param   i_month           Month date
    * @param   i_day             Day date
    *
    * @RETURN  Problem begin date (string))
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION parse_dt_str_app
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_year  IN NUMBER,
        i_month IN NUMBER,
        i_day   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_params    VARCHAR2(1000 CHAR);
        l_dt_result VARCHAR2(50 CHAR);
        l_date_mask VARCHAR2(50 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_year=' || i_year || ' i_month=' || i_month ||
                    ' i_day=' || i_day;
        g_error  := 'Init parse_dt_str_app / ' || l_params;
    
        l_dt_result := '';
        IF i_year IS NOT NULL
        THEN
            IF i_month IS NOT NULL
            THEN
                IF i_day IS NOT NULL
                THEN
                    l_dt_result := pk_date_utils.dt_chr(i_lang,
                                                        to_date(i_year || lpad(i_month, 2, '0') || lpad(i_day, 2, '0'),
                                                                'YYYYMMDD'),
                                                        i_prof);
                ELSE
                
                    l_date_mask := get_sys_config(i_prof => i_prof, i_id_sys_config => 'DATE_FORMAT');
                    --l_dt_result := substr(to_char(to_date(i_year || lpad(i_month, 2, '0'), 'YYYYMM'), l_date_mask, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''), 4);
                
                    SELECT substr(to_char(to_date(i_year || lpad(i_month, 2, '0'), 'YYYYMM'),
                                          l_date_mask,
                                          'NLS_DATE_LANGUAGE=''' || l.nls_code || ''''),
                                  4)
                      INTO l_dt_result
                      FROM LANGUAGE l
                     WHERE l.id_language = i_lang;
                END IF;
            ELSE
                l_dt_result := i_year;
            END IF;
        END IF;
    
        RETURN l_dt_result;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END parse_dt_str_app;

    /**
    * Parses date string into year, month and day separately
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_dt_str_flash Date in string format YYYY[MM[DD]] (flash interpretation)
    * @param   i_year_1       Year date
    * @param   i_month_1      Month date
    * @param   i_day_1        Day date
    * @param   i_year_2       Year date
    * @param   i_month_2      Month date
    * @param   i_day_2        Day date    
    *
    * @return 'G' if i_date_1 is more recent than i_date_2, 'E' if they are equal, 'L' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION compare_dt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_year_1  IN NUMBER,
        i_month_1 IN NUMBER,
        i_day_1   IN NUMBER,
        i_year_2  IN NUMBER,
        i_month_2 IN NUMBER,
        i_day_2   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_year_1=' || i_year_1 || ' i_month_1=' || i_month_1 ||
                    ' i_day_1=' || i_day_1 || ' i_year_2=' || i_year_2 || ' i_month_2=' || i_month_2 || ' i_day_2=' ||
                    i_day_2;
        g_error  := 'Init compare_dt / ' || l_params;
    
        IF i_year_1 IS NOT NULL
           AND i_year_2 IS NOT NULL
        THEN
            IF i_year_1 > i_year_2
            THEN
                RETURN pk_ref_constant.g_date_greater;
            ELSIF i_year_1 < i_year_2
            THEN
                RETURN pk_ref_constant.g_date_lower;
            ELSIF i_year_1 = i_year_2
            THEN
                -- check month
                IF i_month_1 IS NOT NULL
                   AND i_month_2 IS NOT NULL
                THEN
                    IF i_month_1 > i_month_2
                    THEN
                        RETURN pk_ref_constant.g_date_greater;
                    ELSIF i_month_1 < i_month_2
                    THEN
                        RETURN pk_ref_constant.g_date_lower;
                    ELSIF i_month_1 = i_month_2
                    THEN
                        -- check day
                        IF i_day_1 IS NOT NULL
                           AND i_day_1 IS NOT NULL
                        THEN
                            IF i_day_1 > i_day_2
                            THEN
                                RETURN pk_ref_constant.g_date_greater;
                            ELSIF i_day_1 < i_day_2
                            THEN
                                RETURN pk_ref_constant.g_date_lower;
                            ELSIF i_day_1 = i_day_2
                            THEN
                                RETURN pk_ref_constant.g_date_equal;
                            END IF;
                        ELSIF i_day_1 IS NULL
                              AND i_day_2 IS NULL
                        THEN
                            RETURN pk_ref_constant.g_date_equal;
                        ELSE
                            RETURN NULL;
                        END IF;
                    END IF;
                ELSIF i_month_1 IS NULL
                      AND i_month_2 IS NULL
                THEN
                    RETURN pk_ref_constant.g_date_equal;
                ELSE
                    RETURN NULL;
                END IF;
            END IF;
        END IF;
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLCODE || ' / ' || SQLERRM);
            RETURN NULL;
    END compare_dt;

    /**
    * Gets the referral system date (time when the operation was executed in the system)
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    FUNCTION get_sysdate RETURN p1_tracking.dt_create%TYPE IS
    BEGIN
        RETURN coalesce(g_ref_context.dt_system_date, current_timestamp);
    END get_sysdate;

    /**
    * Gets the referral context variable
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    FUNCTION get_ref_context RETURN t_rec_ref_context IS
    BEGIN
        RETURN g_ref_context;
    END get_ref_context;

    /**
    * Sets the referral context variable
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    PROCEDURE set_ref_context
    (
        i_id_external_request IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        i_dt_system_date      IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL
    ) IS
    BEGIN
        g_ref_context.id_external_request := nvl(i_id_external_request, g_ref_context.id_external_request);
        g_ref_context.dt_system_date      := nvl(i_dt_system_date, g_ref_context.dt_system_date);
    END set_ref_context;

    /**
    * Resets the referral context
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    PROCEDURE reset_ref_context IS
    BEGIN
        init_ref_context;
    END reset_ref_context;

    /**
    * Initializes the referral context
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    PROCEDURE init_ref_context IS
    BEGIN
        g_ref_context := t_rec_ref_context();
    END init_ref_context;

    /**
    * Fucntion to evaluate an expression
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2013
    */
    FUNCTION eval(i_expr IN VARCHAR2) RETURN VARCHAR2 IS
        l_result VARCHAR2(1000 CHAR);
        l_str    VARCHAR2(1000 CHAR);
    BEGIN
        l_str := 'begin :result := ' || i_expr || '; end;';
        --pk_alertlog.log_debug(l_str);
    
        EXECUTE IMMEDIATE l_str
            USING OUT l_result;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END eval;

    FUNCTION get_default_health_plan(i_prof IN profissional) RETURN health_plan.id_health_plan%TYPE IS
        l_id_cnt_hp     health_plan.id_content%TYPE;
        l_id_default_hp health_plan.id_health_plan%TYPE;
    BEGIN
    
        l_id_cnt_hp := get_sys_config(i_prof, 'ADT_NATIONAL_HEALTH_PLAN_ID');
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_default_hp
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_default_hp := NULL;
        END;
    
        RETURN l_id_default_hp;
    END get_default_health_plan;

    FUNCTION get_health_plan_other(i_prof IN profissional) RETURN health_plan.id_health_plan%TYPE IS
        l_id_cnt_hp   health_plan.id_content%TYPE;
        l_id_hp_other health_plan.id_health_plan%TYPE;
    BEGIN
    
        l_id_cnt_hp := get_sys_config(i_prof, 'HEALTH_PLAN_OTHER');
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_hp_other
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_hp_other := NULL;
        END;
    
        RETURN l_id_hp_other;
    END get_health_plan_other;

    FUNCTION get_icon_request_type(i_id_p1_external_request p1_external_request.id_external_request%TYPE) RETURN VARCHAR2 AS
        l_flg_type VARCHAR2(5 CHAR);
    BEGIN
    
        SELECT a.flg_type
          INTO l_flg_type
          FROM referral_xml_req a
         WHERE a.id_p1_external_request = i_id_p1_external_request
           AND rownum = 1;
        IF l_flg_type LIKE '%RCP'
        THEN
            RETURN 'PrintPrescriptionConcludedIcon';
        ELSE
            RETURN 'ElectronicPrescriptionConcludedIcon';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN 'PrintPrescriptionConcludedIcon';
    END get_icon_request_type;

    FUNCTION get_id_completion(i_id_p1_external_request p1_external_request.id_external_request%TYPE) RETURN NUMBER AS
        l_flg_type VARCHAR2(5 CHAR);
    BEGIN
    
        SELECT a.flg_type
          INTO l_flg_type
          FROM referral_xml_req a
         WHERE a.id_p1_external_request = i_id_p1_external_request
           AND rownum = 1;
        IF l_flg_type LIKE '%RCP'
        THEN
            RETURN 13;
        ELSE
            RETURN 2;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN 13;
    END get_id_completion;

    FUNCTION get_id_report(i_id_p1_external_request p1_external_request.id_external_request%TYPE) RETURN NUMBER AS
        l_flg_type VARCHAR2(5 CHAR);
    BEGIN
    
        SELECT a.flg_type
          INTO l_flg_type
          FROM referral_xml_req a
         WHERE a.id_p1_external_request = i_id_p1_external_request
           AND rownum = 1;
        IF l_flg_type LIKE '%RCP'
        THEN
            RETURN 198;
        ELSE
            RETURN 909;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN 198;
    END get_id_report;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_utils;
/
