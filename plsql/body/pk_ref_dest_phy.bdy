/*-- Last Change Revision: $Rev: 2027578 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_dest_phy AS

    g_error        VARCHAR2(1000 CHAR);
    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    --g_found  BOOLEAN;

    /**
    * Gets list of available professionals for triage.
    * Returns all triage professionals that are connect to the request dep_clin_serv.
    * Excludes the professional calling the function.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof  professional, institution and software ids
    * @param   i_ext_req request id.
    * @param   o_prof professionals list
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   23-04-2008
    */
    FUNCTION get_prof_triage_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_prof_triage_list / ID_REF=' || i_ext_req;
        OPEN o_prof FOR
            SELECT DISTINCT p.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name
              FROM sys_functionality sf1
              JOIN prof_func pf1
                ON (pf1.id_functionality = sf1.id_functionality AND sf1.id_functionality = pf1.id_functionality)
              JOIN prof_func pf2
                ON (pf1.id_dep_clin_serv = pf2.id_dep_clin_serv)
              JOIN sys_functionality sf2
                ON (pf2.id_functionality = sf2.id_functionality)
              JOIN p1_external_request exr
                ON (exr.id_dep_clin_serv = pf2.id_dep_clin_serv) -- ALERT-80559
              JOIN professional p
                ON (p.id_professional = pf2.id_professional)
              JOIN prof_institution pi
                ON (pi.id_professional = p.id_professional)
             WHERE pf1.id_professional = i_prof.id
               AND sf1.id_functionality = pk_ref_constant.g_func_d
                  -- JS, 2007-12-29: can forward the referral to "Triage physician" or "Clinical service triage physician"
               AND sf2.id_functionality IN (pk_ref_constant.g_func_d, pk_ref_constant.g_func_t)
               AND sf1.id_software = i_prof.software
               AND pf1.id_institution = i_prof.institution
               AND pf2.id_institution = i_prof.institution
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = pk_ref_constant.g_active
               AND pi.dt_end_tstz IS NULL
               AND pf2.id_professional != i_prof.id
               AND exr.id_external_request = i_ext_req
               AND p.flg_state = pk_ref_constant.g_active
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_ref_constant.g_yes
             ORDER BY prof_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_TRIAGE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END get_prof_triage_list;

    /**
    * Gets list of available clinical services
    *
    * @param   i_lang           Language
    * @param   i_prof           Professional, institution, software
    * @param   i_dep_clin_serv  Department and clinical service identifier
    * @param   i_external_sys   External system identifier    
    * @param   o_levels         Triage urgency levels
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   05-03-2010
    */
    FUNCTION get_triage_level_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_external_sys  IN external_sys.id_external_sys%TYPE,
        o_levels        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_triage_level_list / ID_DEP_CLIN_SERV=' || i_dep_clin_serv || ' i_external_sys=' ||
                   i_external_sys;
        OPEN o_levels FOR
            SELECT DISTINCT desc_val, val, img_name, rank
              FROM (SELECT sd.desc_val, sd.val, sd.img_name, sd.rank
                      FROM p1_spec_dep_clin_serv sdcs, sys_domain sd
                     WHERE sdcs.id_dep_clin_serv = i_dep_clin_serv
                       AND sdcs.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND sd.code_domain = 'P1_TRIAGE_LEVEL.MED_HS_' || sdcs.triage_style
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAGE_LEVEL_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_levels);
            RETURN FALSE;
    END get_triage_level_list;

    /**
    * Returns the list of professionals available for scheduling.
    *
    * @param   i_lang             Language id
    * @param   i_prof             Professional, institution, software
    * @param   i_dep_clin_serv    Dep_clin_serv id for the scheduling beeing requested
    * @param   i_external_sys     External system identifier
    * @param   i_dep              Service id (DEPARTMENT)
    * @param   o_cs               Specialities list (CLINICAL_SERVICES)
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   05-06-2007
    */
    FUNCTION get_prof_schedule_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_external_sys  IN external_sys.id_external_sys%TYPE,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_p1_doctor_hs_t026 sys_message.desc_message%TYPE;
    BEGIN
    
        g_error := 'Init get_prof_schedule_list / ID_PROFESSIONAL=' || i_prof.id || ' ID_DEP_CLIN_SERV=' ||
                   i_dep_clin_serv || ' ID_EXTERNAL_SYS=' || i_external_sys;
        pk_alertlog.log_debug(g_error);
    
        l_p1_doctor_hs_t026 := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => pk_ref_constant.g_sm_doctor_hs_t026);
    
        g_error := 'OPEN O_PROF';
        OPEN o_prof FOR
            SELECT DISTINCT t.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) nick_name,
                            1 rank
              FROM (SELECT p.id_professional
                      FROM professional p
                      JOIN prof_dep_clin_serv pdcs
                        ON (pdcs.id_professional = p.id_professional)
                      JOIN p1_spec_dep_clin_serv sdcs
                        ON (sdcs.id_dep_clin_serv = pdcs.id_dep_clin_serv)
                      JOIN prof_institution pi
                        ON (pi.id_professional = p.id_professional)
                      JOIN prof_cat pc
                        ON (pc.id_professional = p.id_professional)
                     WHERE pdcs.id_dep_clin_serv = i_dep_clin_serv
                       AND sdcs.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = pk_ref_constant.g_active
                       AND pi.dt_end_tstz IS NULL
                       AND pc.id_category = pk_ref_constant.g_cat_id_med
                       AND pc.id_institution = i_prof.institution -- ALERT-80559
                       AND p.flg_state = pk_ref_constant.g_active
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                           pk_ref_constant.g_yes) t
            UNION ALL
            SELECT NULL id_professional, l_p1_doctor_hs_t026 nick_name, 0 rank
              FROM dual
             ORDER BY rank, nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_SCHEDULE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END get_prof_schedule_list;

    /**
    * Validates if the professional has the functionality for the dcs provided 
    *
    * @param   i_prof professional id
    * @param   i_dcs dep_clin_serv id
    * @param   i_func functionality id (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION validate_dcs_func
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_func IN sys_functionality.id_functionality%TYPE
    ) RETURN VARCHAR2 IS
        l_func_tab table_number;
    BEGIN
        g_error := 'Init validate_dcs_func / ID_PROFESSIONAL=' || i_prof.id || ' ID_DEP_CLIN_SERV=' || i_dcs ||
                   ' ID_FUNC=' || i_func;
    
        l_func_tab := pk_ref_core.get_prof_func_dcs(i_lang => NULL, i_prof => i_prof, i_id_dcs => i_dcs);
    
        <<prof_func>>
        FOR i IN 1 .. l_func_tab.count
        LOOP
            IF l_func_tab(i) = i_func
            THEN
                RETURN pk_ref_constant.g_yes;
            END IF;
        END LOOP prof_func;
    
        RETURN pk_ref_constant.g_no;
    END validate_dcs_func;

    /**
    * Validates if the professional has at least one of the functionalities for the dcs provided 
    * Used on grids 
    *
    * @param   i_prof  Professional identifier
    * @param   i_dcs   Dep_clin_serv identifier
    * @param   i_func  Functionalities identifiers (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-09-2010
    */
    FUNCTION validate_dcs_func
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_func IN table_number
    ) RETURN VARCHAR2 IS
        l_func_tab table_number;
        l_count    PLS_INTEGER;
    BEGIN
        g_error    := 'Init validate_dcs_func / i_prof=' || pk_utils.to_string(i_prof) || ' ID_DEP_CLIN_SERV=' || i_dcs ||
                      ' ID_FUNC=' || pk_utils.to_string(i_func);
        l_func_tab := pk_ref_core.get_prof_func_dcs(i_lang => NULL, i_prof => i_prof, i_id_dcs => i_dcs);
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT column_value
                  FROM TABLE(CAST(l_func_tab AS table_number))) tf
          JOIN (SELECT column_value
                  FROM TABLE(CAST(i_func AS table_number))) ti
            ON (tf.column_value = ti.column_value);
    
        IF l_count > 0
        THEN
            RETURN pk_ref_constant.g_yes;
        END IF;
    
        RETURN pk_ref_constant.g_no;
    
    END validate_dcs_func;

    /**
    * Validates if the professional has the functionality "Triage" or "Speciality Triage" for the dcs provided 
    *
    * @param   i_prof professional id
    * @param   i_dcs dep_clin_serv id
    * @param   i_func functionality id (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION validate_dcs_triage
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
        l_func_tab table_number;
    BEGIN
        g_error := 'Init validate_dcs_triage / i_prof=' || pk_utils.to_string(i_prof) || ' ID_DEP_CLIN_SERV=' || i_dcs;
    
        -- check triage physician or speciality triage physician
        l_func_tab := pk_ref_core.get_prof_func_dcs(i_lang => NULL, i_prof => i_prof, i_id_dcs => i_dcs);
    
        <<prof_func>>
        FOR i IN 1 .. l_func_tab.count
        LOOP
            IF l_func_tab(i) IN (pk_ref_constant.g_func_d, pk_ref_constant.g_func_t)
            THEN
                RETURN pk_ref_constant.g_yes;
            END IF;
        END LOOP prof_func;
    
        -- do not validate clinical director: this func only makes sense in orig institution        
        RETURN pk_ref_constant.g_no;
    END validate_dcs_triage;

    /**
    * Returns the list of available institutions to forward the referral.
    * The institutions must belong to the same hospital centre.
    * Notice that if the parameter INST_FORWARD_TYPE is (I)nstitution then the destination institution
    * must accept requests for the referral speciality.
    * If that parameter is (C)linical service then all institutions from the hospital centre that accept
    * any kind of referrals (all configured in p1_spec_dep_clin_serv) are listed 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_ext_req         Referral identifier
    * @param   o_inst available institutions
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   06-05-2008
    */
    FUNCTION get_inst_forward_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func    VARCHAR2(1 CHAR);
        l_params  VARCHAR2(1000 CHAR);
        l_ref_row p1_external_request%ROWTYPE;
        l_gender  patient.gender%TYPE;
        l_age     patient.age%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_ext_req=' || i_ext_req;
        g_error  := 'Init get_inst_forward_list / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ID_WF=' || l_ref_row.id_workflow || ' ID_SPEC=' || l_ref_row.id_speciality ||
                    ' FLG_STATUS=' || l_ref_row.flg_status || ' ID_DCS=' || l_ref_row.id_dep_clin_serv ||
                    ' ID_INST_DEST=' || l_ref_row.id_inst_dest || ' ID_PAT=' || l_ref_row.id_patient;
    
        g_error := 'Call validate_dcs_func / ' || l_params;
        l_func  := validate_dcs_func(i_prof => i_prof,
                                     i_dcs  => l_ref_row.id_dep_clin_serv,
                                     i_func => pk_ref_constant.g_func_d);
    
        -- all this conditions were already validated in flash layer
        IF l_func = pk_ref_constant.g_yes
           AND l_ref_row.id_inst_dest = i_prof.institution
           AND l_ref_row.flg_status IN
           (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_r, pk_ref_constant.g_p1_status_a)
        THEN
        
            l_ref_row.id_workflow := nvl(l_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp);
        
            g_error  := 'Call pk_ref_core.get_pat_age_gender / ' || l_params;
            g_retval := pk_ref_core.get_pat_age_gender(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => l_ref_row.id_patient,
                                                       o_gender  => l_gender,
                                                       o_age     => l_age,
                                                       o_error   => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'OPEN o_inst FOR / ' || l_params;
            OPEN o_inst FOR
                SELECT DISTINCT t.id_institution, -- DISTINCT is done to return id_institution once, and not as many as the clinical services of the institution
                                pk_translation.get_translation(i_lang,
                                                               pk_ref_constant.g_institution_code || t.id_institution) inst,
                                t.flg_inst_forward_type inst_forward_type
                  FROM TABLE(CAST(get_inst_dcs_forward_p(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_spec      => l_ref_row.id_speciality,
                                                         i_id_workflow  => l_ref_row.id_workflow,
                                                         i_id_inst_orig => l_ref_row.id_inst_orig,
                                                         i_id_inst_dest => l_ref_row.id_inst_dest,
                                                         i_pat_gender   => l_gender,
                                                         i_pat_age      => l_age,
                                                         i_external_sys => l_ref_row.id_external_sys) AS
                                  t_coll_ref_inst_dcs_fwd)) t
                 ORDER BY inst;
        ELSE
            g_error := 'The referral cannot be forwarded to another institution / l_func=' || l_func ||
                       ' ID_INST_DEST=' || l_ref_row.id_inst_dest || ' i_prof.institution=' || i_prof.institution ||
                       ' FLG_STATUS=' || l_ref_row.flg_status;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INST_FORWARD_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            RETURN FALSE;
    END get_inst_forward_list;

    /**
    * Pipeline function that returns the list of available institutions and dep_clin_servs to forward the referral.
    * Notice that if the parameter INST_FORWARD_TYPE is (I)nstitution then the destination institution
    * must accept requests for the referral speciality.
    * If that parameter is (C)linical service then all institutions from the hospital centre that accept
    * any kind of referrals (all configured in p1_spec_dep_clin_serv) are listed 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_spec         Referral speciality identifier
    * @param   i_id_workflow     Referral workflow identifier
    * @param   i_id_inst_orig    Referral origin institution
    * @param   i_id_inst_dest    Referral dest institution
    * @param   i_pat_gender      Patient gender
    * @param   i_pat_age         Patient age
    * @param   i_external_sys    External system identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-07-2013
    */
    FUNCTION get_inst_dcs_forward_p
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_spec      IN p1_external_request.id_speciality%TYPE,
        i_id_workflow  IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE
    ) RETURN t_coll_ref_inst_dcs_fwd
        PIPELINED IS
        l_id_market        market.id_market%TYPE;
        l_id_workflow      p1_external_request.id_workflow%TYPE;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
    
        CURSOR c_inst_forwd IS
        -- Institution/Service and speciality 
            SELECT DISTINCT t.*, pk_ref_constant.g_inst_forward_type_c flg_inst_forward_type
              FROM (SELECT v.id_institution,
                           v.id_department,
                           v.code_department,
                           v.id_dep_clin_serv,
                           v.id_clinical_service,
                           v.code_clinical_service
                      FROM v_ref_spec_inst_dcs v
                      JOIN institution i
                        ON (v.id_institution = i.id_institution)
                     WHERE v.id_market = l_id_market
                       AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND v.flg_availability IN (l_flg_availability, pk_ref_constant.g_flg_availability_a)
                       AND i.flg_available = pk_ref_constant.g_yes
                       AND v.id_institution != i_id_inst_orig
                       AND v.id_institution != i_id_inst_dest
                       AND ((i_pat_gender IS NOT NULL AND
                           nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                           i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
                       AND (nvl(i_pat_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(i_pat_age, 0)) OR
                           nvl(i_pat_age, 0) = 0)) t
              JOIN (SELECT column_value id_institution
                      FROM TABLE(CAST(pk_ref_core.get_sibling_inst(i_id_institution => i_id_inst_dest,
                                                                   i_flg_slef       => pk_ref_constant.g_no) AS
                                      table_number))) sib
                ON (t.id_institution = sib.id_institution)
             WHERE pk_ref_core.get_workflow_config(i_prof       => i_prof,
                                                   i_code_param => pk_ref_constant.g_inst_forward_type,
                                                   i_speciality => i_id_spec,
                                                   i_inst_dest  => sib.id_institution, -- config for sibling inst
                                                   i_inst_orig  => i_prof.institution, -- config of prof institution
                                                   i_workflow   => l_id_workflow) =
                   pk_ref_constant.g_inst_forward_type_c
            UNION ALL
            -- Only institution 
            SELECT DISTINCT t.*, pk_ref_constant.g_inst_forward_type_i flg_inst_forward_type
              FROM (SELECT v.id_institution,
                           v.id_department,
                           v.code_department,
                           v.id_dep_clin_serv,
                           v.id_clinical_service,
                           v.code_clinical_service
                      FROM v_ref_spec_inst_dcs v
                      JOIN institution i
                        ON (v.id_institution = i.id_institution)
                     WHERE v.id_market = l_id_market
                       AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                       AND v.flg_availability IN (l_flg_availability, pk_ref_constant.g_flg_availability_a)
                       AND v.id_speciality = i_id_spec -- of this speciality
                       AND v.flg_default = pk_ref_constant.g_yes -- default dcs
                       AND i.flg_available = pk_ref_constant.g_yes
                       AND v.id_institution != i_id_inst_orig
                       AND v.id_institution != i_id_inst_dest
                       AND ((i_pat_gender IS NOT NULL AND
                           nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                           i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
                       AND (nvl(i_pat_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(i_pat_age, 0)) OR
                           nvl(i_pat_age, 0) = 0)) t
              JOIN (SELECT column_value id_institution
                      FROM TABLE(CAST(pk_ref_core.get_sibling_inst(i_id_institution => i_id_inst_dest,
                                                                   i_flg_slef       => pk_ref_constant.g_no) AS
                                      table_number))) sib
                ON (t.id_institution = sib.id_institution)
             WHERE pk_ref_core.get_workflow_config(i_prof       => i_prof,
                                                   i_code_param => pk_ref_constant.g_inst_forward_type,
                                                   i_speciality => i_id_spec,
                                                   i_inst_dest  => sib.id_institution, -- config for sibling inst
                                                   i_inst_orig  => i_prof.institution, -- config of prof institution
                                                   i_workflow   => l_id_workflow) =
                   pk_ref_constant.g_inst_forward_type_i;
    
        l_rec    t_rec_ref_inst_dcs_fwd;
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'ID_PROFESSIONAL=' || i_prof.id || ' i_id_spec=' || i_id_spec || ' i_id_workflow=' || i_id_workflow ||
                    ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' || i_pat_age || ' i_external_sys=' ||
                    i_external_sys;
        g_error  := 'Init get_inst_dcs_forward_p / ' || l_params;
        pk_alertlog.log_debug(g_error);
        l_id_market   := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_id_workflow := nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp);
    
        g_error            := 'Call pk_api_ref_ws.get_flg_availability / ' || l_params;
        l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow => l_id_workflow);
    
        l_params := l_params || ' ID_MARKET=' || l_id_market || ' ID_WF=' || l_id_workflow || ' FLG_AVAILABILITY=' ||
                    l_flg_availability;
    
        FOR l_row IN c_inst_forwd
        LOOP
        
            g_error                     := 't_rec_ref_inst_dcs_fwd() / id_inst=' || l_row.id_institution ||
                                           ' flg_inst_forward_type=' || l_row.flg_inst_forward_type || ' / ' ||
                                           l_params;
            l_rec                       := t_rec_ref_inst_dcs_fwd();
            l_rec.id_institution        := l_row.id_institution;
            l_rec.id_department         := l_row.id_department;
            l_rec.code_department       := l_row.code_department;
            l_rec.id_dep_clin_serv      := l_row.id_dep_clin_serv;
            l_rec.id_clinical_service   := l_row.id_clinical_service;
            l_rec.code_clinical_service := l_row.code_clinical_service;
            l_rec.flg_inst_forward_type := l_row.flg_inst_forward_type;
        
            PIPE ROW(l_rec);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN no_data_needed THEN
            -- this is because of this kind of calls:
            --  AND exists (select 1 from pk_ref_dest_phy.get_inst_dcs_forward_p()...) - used in PK_P1_MED_HS.get_status_options
            NULL;
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_INST_DCS_FORWARD_P');
                RETURN;
            END;
    END get_inst_dcs_forward_p;

    /**
    * Returns then department and services available to forward or schedule referrals
    *
    * @param   i_lang           Language
    * @param   i_prof           Professional, institution, software    
    * @param   i_id_institution Departments returned from this institution
    * @param   i_id_market      Institution market related to i_id_institution
    * @param   i_pat_gender     Patient gender
    * @param   i_pat_age        Patient age
    * @param   i_external_sys   External system identifier
    *
    * @RETURN  Return table (t_coll_ref_inst_dcs_fwd) pipelined
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-06-2013
    */
    FUNCTION get_dcs_forward_list_p
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_market      IN market.id_market%TYPE DEFAULT NULL,
        i_pat_gender     IN patient.gender%TYPE,
        i_pat_age        IN patient.age%TYPE,
        i_external_sys   IN external_sys.id_external_sys%TYPE
    ) RETURN t_coll_ref_inst_dcs_fwd
        PIPELINED IS
    
        l_rec       t_rec_ref_inst_dcs_fwd;
        l_id_market institution.id_market%TYPE;
        l_params    VARCHAR2(1000 CHAR);
    
        CURSOR c_dcs_forward IS
            SELECT DISTINCT v.id_department,
                            v.code_department,
                            v.id_dep_clin_serv,
                            v.id_clinical_service,
                            v.code_clinical_service,
                            v.id_institution
              FROM v_ref_spec_inst_dcs v
             WHERE ((i_pat_gender IS NOT NULL AND
                   nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, i_pat_gender)) OR
                   i_pat_gender IS NULL OR i_pat_gender = pk_ref_constant.g_gender_i)
               AND (nvl(i_pat_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(i_pat_age, 0)) OR
                   nvl(i_pat_age, 0) = 0)
               AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
               AND v.id_market = l_id_market
               AND v.id_institution = i_id_institution;
    BEGIN
        l_params    := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_market=' || i_id_market || ' i_pat_gender=' ||
                       i_pat_gender || ' i_pat_age=' || i_pat_age || ' i_external_sys=' || i_external_sys;
        g_error     := 'Init get_dcs_forward_list_p / ' || l_params;
        l_id_market := nvl(i_id_market, pk_utils.get_institution_market(i_lang, i_id_institution));
    
        FOR l_row IN c_dcs_forward
        LOOP
        
            g_error                     := 't_rec_ref_inst_dcs_fwd()';
            l_rec                       := t_rec_ref_inst_dcs_fwd();
            l_rec.id_department         := l_row.id_department;
            l_rec.code_department       := l_row.code_department;
            l_rec.id_dep_clin_serv      := l_row.id_dep_clin_serv;
            l_rec.id_clinical_service   := l_row.id_clinical_service;
            l_rec.code_clinical_service := l_row.code_clinical_service;
            l_rec.id_institution        := l_row.id_institution;
        
            PIPE ROW(l_rec);
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_DCS_FORWARD_LIST_P');
                RETURN;
            END;
    END get_dcs_forward_list_p;

    /**
    * Insert consultation doctor 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_exr             Referral identifier
    * @param   i_diagnosis       Selected diagnosis
    * @param   i_diag_desc       Diagnosis description, when entered in text mode
    * @param   i_answer          Observation, Therapy, Exam and Conclusion
    * @param   i_date            Operation date
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */

    FUNCTION set_ref_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exr              IN p1_external_request.id_external_request%TYPE,
        i_diagnosis        IN table_number,
        i_diag_desc        IN table_varchar,
        i_answer           IN table_table_varchar,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_track            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
        l_my_data t_rec_prof_data;
        l_param   table_varchar;
    BEGIN
        g_error := 'Init set_ref_answer / ID_REF=' || i_exr;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        o_track        := table_number();
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_exr;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_exr,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data / ID_REF=' || l_ref_row.id_external_request || ' ID_DEP_CLIN_SERV=' ||
                    l_ref_row.id_dep_clin_serv || ' ID_PROFESSIONAL=' || i_prof.id;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- processing action ANSWER
        g_error  := 'Call pk_ref_core.process_transition / ID_REF=' || l_ref_row.id_external_request || ' FLG_STATUS=' ||
                    l_ref_row.flg_status || ' ACTION=' || pk_ref_constant.g_ref_action_w;
        g_retval := pk_ref_core.process_transition2(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_prof_data        => l_my_data,
                                                    i_ref_row          => l_ref_row,
                                                    i_action           => pk_ref_constant.g_ref_action_w, -- answering referral
                                                    i_status_end       => NULL,
                                                    i_date             => g_sysdate_tstz,
                                                    i_diagnosis        => i_diagnosis,
                                                    i_diag_desc        => i_diag_desc,
                                                    i_answer           => i_answer,
                                                    i_health_prob      => i_health_prob,
                                                    i_health_prob_desc => i_health_prob_desc,
                                                    io_param           => l_param,
                                                    io_track           => o_track,
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REF_ANSWER',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_answer;

    /**
    * Returns the suggested physician who will provide consultation
    *
    * @param   i_lang           Language id
    * @param   i_prof           Professional, institution, software
    * @param   i_id_ref         Referral identifier
    *
    * @RETURN  Professional identifier
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   27-05-2011
    */
    FUNCTION get_suggested_physician
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN professional.id_professional%TYPE IS
    
        CURSOR c_track IS
            SELECT id_prof_dest
              FROM p1_tracking
             WHERE flg_type = pk_ref_constant.g_tracking_type_s
               AND ext_req_status = pk_ref_constant.g_p1_status_a
               AND id_external_request = i_id_ref
             ORDER BY dt_tracking_tstz DESC;
    
        l_result professional.id_professional%TYPE;
        l_error  t_error_out;
    BEGIN
        g_error := 'Init get_suggested_physician / i_id_ref=' || i_id_ref;
        OPEN c_track;
        FETCH c_track
            INTO l_result;
        CLOSE c_track;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SUGGESTED_PHYSICIAN',
                                              o_error    => l_error);
            RETURN NULL;
    END get_suggested_physician;

    /**
    * Returns the list of services (DEPARTMENT) available for forward the request (dest physician)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_external_sys    External system identifier
    * @param   i_pat_gender      Patient gender
    * @param   i_pat_age         Patient age
    * @param   i_id_inst         Departments returned from this institution
    * @param   i_dcs_except      Dep_clin_Serv exception: not to be returned
    * @param   o_dep             Service identifier (DEPARTMENT)
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION get_dep_forward_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_id_inst      IN p1_external_request.id_inst_dest%TYPE,
        i_dcs_except   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_dep          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_external_sys=' || i_external_sys || ' i_pat_gender=' ||
                    i_pat_gender || ' i_pat_age=' || i_pat_age || ' i_id_inst=' || i_id_inst;
        g_error  := 'Init get_dep_forward_list / ' || l_params;
        OPEN o_dep FOR
            SELECT DISTINCT t.id_department, pk_translation.get_translation(i_lang, t.code_department) dep -- ALERT-55820
              FROM TABLE(CAST(get_dcs_forward_list_p(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_pat_gender     => i_pat_gender,
                                                     i_pat_age        => i_pat_age,
                                                     i_id_institution => i_id_inst,
                                                     i_external_sys   => i_external_sys) AS t_coll_ref_inst_dcs_fwd)) t
             WHERE (i_dcs_except IS NULL OR i_dcs_except != t.id_dep_clin_serv)
             ORDER BY dep;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DEP_FORWARD_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
    END get_dep_forward_list;

    /**
    * Returns the list of services (DEPARTMENT) available for schedule
    * Returns all departments in which the professional has at least one speciality (prof_dep_clin_serv).
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_external_sys    External system identifier
    * @param   i_pat_gender      Patient gender
    * @param   i_pat_age         Patient age
    * @param   o_dep             Service identifier (DEPARTMENT)
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   23-04-2008
    */
    FUNCTION get_dep_schedule_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        o_dep          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_external_sys=' || i_external_sys || ' i_pat_gender=' ||
                    i_pat_gender || ' i_pat_age=' || i_pat_age;
        g_error  := 'Init get_dep_schedule_list / ' || l_params;
        OPEN o_dep FOR
            SELECT DISTINCT t.id_department, pk_translation.get_translation(i_lang, t.code_department) dep -- ALERT-55820
              FROM TABLE(CAST(get_dcs_forward_list_p(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_pat_gender     => i_pat_gender,
                                                     i_pat_age        => i_pat_age,
                                                     i_id_institution => i_prof.institution, -- professional institution
                                                     i_external_sys   => i_external_sys) AS t_coll_ref_inst_dcs_fwd)) t
              JOIN prof_dep_clin_serv pdcs
                ON (pdcs.id_dep_clin_serv = t.id_dep_clin_serv)
             WHERE pdcs.id_professional = i_prof.id
            -- AND pdcs.flg_status = g_dcs_available -- does not to have to be selected in the tools, just to be assigned
             ORDER BY dep;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DEP_SCHEDULE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
    END get_dep_schedule_list;

    /**
    * Returns the list of specialities available for forward/schedule the request (dest physician)
    * Retuns all specialities in the department that are configured in p1_spec_dep_clin_serv
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids    
    * @param   i_dep            Service identifier (DEPARTMENT)
    * @param   i_external_sys   External system identifier
    * @param   i_pat_gender     Patient gender
    * @param   i_pat_age        Patient age
    * @param   i_id_inst        Institution identifier (to return the list of specialities available)
    * @param   i_dcs_except     Dep_clin_Serv exception: not to be returned
    * @param   o_cs             Clinical services list (CLINICAL_SERVICES)
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   04-06-2007
    */
    FUNCTION get_clin_serv_forward_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dep          IN department.id_department%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_id_inst      IN p1_external_request.id_inst_dest%TYPE,
        i_dcs_except   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_cs           OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_inst=' || i_id_inst || ' i_dep=' || i_dep ||
                    ' i_external_sys=' || i_external_sys || ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' ||
                    i_pat_age;
        g_error  := 'Init get_clin_serv_forward_list / ' || l_params;
        OPEN o_cs FOR
            SELECT DISTINCT t.id_dep_clin_serv id,
                            pk_translation.get_translation(i_lang, t.code_clinical_service) clin_serv
              FROM TABLE(CAST(get_dcs_forward_list_p(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_pat_gender     => i_pat_gender,
                                                     i_pat_age        => i_pat_age,
                                                     i_id_institution => i_id_inst,
                                                     i_external_sys   => i_external_sys) AS t_coll_ref_inst_dcs_fwd)) t
             WHERE t.id_department = i_dep
               AND (i_dcs_except IS NULL OR i_dcs_except != t.id_dep_clin_serv)
             ORDER BY clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CLIN_SERV_FORWARD_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cs);
            RETURN FALSE;
    END get_clin_serv_forward_list;

BEGIN

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_ref_dest_phy;
/
