/*-- Last Change Revision: $Rev: 2027573 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_core AS

    g_error         VARCHAR2(4000);
    g_sysdate_tstz  TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    --g_found  BOOLEAN;

    /**
    * Initializes table_varchar as input of workflow transition function
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_ext_req                 Referral identifier    
    * @param   i_id_patient              Referral patient identifier
    * @param   i_id_inst_orig            Referral institution origin
    * @param   i_id_inst_dest            Referral institution dest
    * @param   i_id_dep_clin_serv        Referral dep_clin_serv
    * @param   i_id_speciality           Referral speciality (origin)
    * @param   i_flg_type                Referral type
    * @param   i_decision_urg_level      Decision urgency level assigned when triaging referral
    * @param   i_id_prof_requested       Professional that requested referral   
    * @param   i_id_prof_redirected      Professional to whom the referral was forwarded to   
    * @param   i_id_prof_status          Professional that changed referral status
    * @param   i_external_sys            Referral external system where the referral was created
    * @param   i_location                Referral location
    * @param   i_completed               Flag indicating if referral has been completed   
    * @param   i_flg_status              Referral status
    * @param   i_flg_prof_dcs            Flag indicating if professional is related to this id_dep_clin_serv (used for the registrar)
    * @param   i_prof_clin_dir           Flag indicating if professional is clinical director in this institution
    *   
    * @value   i_flg_type                {*} 'C' - Appointments
    *                                    {*} 'A' - Lab tests
    *                                    {*} 'I' - Imaging exams
    *                                    {*} 'E' - Other exams
    *                                    {*} 'P' - Procedures
    *                                    {*} 'F' - Physical Medicine and Rehabilitation
    * @value   o_location                {*} 'G' - grid {*} 'D' - detail
    * @value   o_completed               {*} 'Y' - referral completed {*} 'N' - otherwise
    *
    */
    FUNCTION init_param_tab
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ext_req            IN p1_external_request.id_external_request%TYPE,
        i_id_patient         IN p1_external_request.id_patient%TYPE DEFAULT NULL,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE DEFAULT NULL,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE DEFAULT NULL,
        i_flg_type           IN p1_external_request.flg_type%TYPE DEFAULT NULL,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE DEFAULT NULL,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE DEFAULT NULL,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE DEFAULT NULL,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE DEFAULT NULL,
        i_location           IN VARCHAR2 DEFAULT pk_ref_constant.g_location_detail,
        i_completed          IN VARCHAR2 DEFAULT pk_ref_constant.g_no,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_flg_prof_dcs       IN VARCHAR2 DEFAULT NULL,
        i_prof_clin_dir      IN VARCHAR2 DEFAULT NULL
    ) RETURN table_varchar IS
        l_result table_varchar;
    BEGIN
    
        l_result := table_varchar();
        l_result.extend(19);
    
        l_result(pk_ref_constant.g_idx_id_ref) := i_ext_req;
        l_result(pk_ref_constant.g_idx_id_patient) := i_id_patient;
        l_result(pk_ref_constant.g_idx_id_inst_orig) := i_id_inst_orig;
        l_result(pk_ref_constant.g_idx_id_inst_dest) := i_id_inst_dest;
        l_result(pk_ref_constant.g_idx_id_dcs) := i_id_dep_clin_serv;
        l_result(pk_ref_constant.g_idx_id_speciality) := i_id_speciality;
        l_result(pk_ref_constant.g_idx_flg_type) := i_flg_type;
        l_result(pk_ref_constant.g_idx_decision_urg_level) := i_decision_urg_level;
        l_result(pk_ref_constant.g_idx_id_prof_requested) := i_id_prof_requested;
        l_result(pk_ref_constant.g_idx_id_prof_redirected) := i_id_prof_redirected;
        l_result(pk_ref_constant.g_idx_id_prof_status) := i_id_prof_status;
        l_result(pk_ref_constant.g_idx_external_sys) := i_external_sys;
        l_result(pk_ref_constant.g_idx_location) := i_location;
        l_result(pk_ref_constant.g_idx_completed) := i_completed;
        l_result(pk_ref_constant.g_idx_id_action) := NULL;
        l_result(pk_ref_constant.g_idx_flg_status) := i_flg_status;
        l_result(pk_ref_constant.g_idx_n_auto_trans) := 0;
        l_result(pk_ref_constant.g_idx_flg_prof_dcs) := i_flg_prof_dcs;
        l_result(pk_ref_constant.g_idx_prof_clin_dir) := i_prof_clin_dir;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END init_param_tab;

    /**
    * Gets the institution to be shown
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_flg_status     referral status
    * @param   i_id_institution   Institution ID
    * @param   i_code_institution Institution Code
    * @param   i_inst_abbrev      Institution Abbreviation
    */
    FUNCTION get_inst_name
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN p1_external_request.flg_status%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_code_institution IN institution.code_institution%TYPE,
        i_inst_abbrev      IN institution.abbreviation%TYPE
    ) RETURN VARCHAR2 IS
        l_sc_doctor_cs_t040    sys_config.desc_sys_config%TYPE;
        l_sc_other_institution sys_config.desc_sys_config%TYPE;
    BEGIN
        g_error := 'Init get_inst_name / i_flg_status=' || i_flg_status || ' i_id_institution=' || i_id_institution ||
                   ' i_inst_abbrev=' || i_inst_abbrev;
        IF i_flg_status = pk_ref_constant.g_p1_status_o
        THEN
            IF i_id_institution IS NOT NULL
            THEN
                RETURN pk_translation.get_translation(i_lang, i_code_institution);
            ELSE
                RETURN NULL;
            END IF;
        
        ELSIF i_flg_status = pk_ref_constant.g_p1_status_p
        THEN
            l_sc_doctor_cs_t040    := pk_message.get_message(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_code_mess => pk_ref_constant.g_sm_p1_doctor_cs_t040);
            l_sc_other_institution := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                  i_id_sys_config => pk_ref_constant.g_sc_other_institution);
        
            IF i_id_institution IS NOT NULL
            THEN
                IF i_id_institution = l_sc_other_institution
                THEN
                    RETURN l_sc_doctor_cs_t040;
                ELSE
                    RETURN pk_translation.get_translation(i_lang, i_code_institution);
                END IF;
            ELSE
                RETURN l_sc_doctor_cs_t040;
            END IF;
        END IF;
    
        RETURN pk_translation.get_translation(i_lang, i_code_institution);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_inst_name;

    /**
    * Returns origin instituion name
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_inst_orig            Origin institution identifier
    * @param   i_inst_name_roda          External institution name (in case of WF=4)
    * @param   i_inst_parent_name        Name of the parent institution
    *
    * @RETURN  Origin institution name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-09-2013
    */
    FUNCTION get_inst_orig_name
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_inst_orig     IN p1_external_request.id_inst_orig%TYPE,
        i_inst_name_roda   IN ref_orig_data.institution_name%TYPE,
        i_inst_parent_name IN pk_translation.t_desc_translation DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_result            VARCHAR2(1000 CHAR);
        l_params            VARCHAR2(1000 CHAR);
        l_ref_external_inst institution.id_institution%TYPE;
    BEGIN
        l_params            := 'i_id_inst_orig=' || i_id_inst_orig || ' i_inst_name_roda=' ||
                               substr(i_inst_name_roda, 1, 200) || ' i_inst_parent_name=' ||
                               substr(i_inst_parent_name, 1, 200);
        g_error             := 'Init get_inst_orig_name / ' || l_params;
        l_ref_external_inst := to_number(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                     i_id_sys_config => pk_ref_constant.g_ref_external_inst));
    
        g_error := 'l_ref_external_inst=' || l_ref_external_inst || ' / ' || l_params;
        IF i_id_inst_orig = l_ref_external_inst
        THEN
            l_result := i_inst_name_roda;
        ELSE
            l_result := pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || i_id_inst_orig);
        END IF;
    
        -- adding parent name to the orig institution
        g_error := 'i_inst_parent_name / ' || l_params;
        IF i_inst_parent_name IS NOT NULL
        THEN
            l_result := l_result || ' (' || i_inst_parent_name || ')';
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_inst_orig_name;

    /**
    * Returns origin instituion name to be shown in referral detail
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_inst_orig            Origin institution identifier
    * @param   i_inst_name_roda          External institution name (in case fo WF=4)
    * @param   i_id_inst_orig_parent     Parent of the origin institution identifier
    *
    * @RETURN  Origin institution name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-10-2012
    */
    FUNCTION get_inst_orig_name_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_inst_orig        IN p1_external_request.id_inst_orig%TYPE,
        i_inst_name_roda      IN ref_orig_data.institution_name%TYPE,
        i_id_inst_orig_parent IN institution.id_parent%TYPE
    ) RETURN VARCHAR2 IS
        l_inst_parent_name VARCHAR2(1000 CHAR);
        l_sc_value         sys_config.value%TYPE;
        l_params           VARCHAR2(1000 CHAR);
        l_cfg_flg_type_tab table_varchar;
        l_par_flg_type_tab table_varchar;
        l_par_id_inst_tab  table_number;
    BEGIN
        l_params := 'i_id_inst_orig=' || i_id_inst_orig || ' i_id_inst_orig_parent=' || i_id_inst_orig_parent;
        g_error  := 'Init get_inst_orig_name_detail / ' || l_params;
    
        IF i_id_inst_orig_parent IS NOT NULL
        THEN
            l_sc_value         := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                              i_id_sys_config => pk_ref_constant.g_ref_inst_p_type_name);
            l_cfg_flg_type_tab := pk_utils.str_split_l(i_list => l_sc_value, i_delim => ',');
        
            -- getting all parent types of this institution
            g_error := 'SELECT flg_type, i.id_institution / ' || l_params;
            SELECT flg_type, i.id_institution
              BULK COLLECT
              INTO l_par_flg_type_tab, l_par_id_inst_tab
              FROM institution i
             WHERE id_institution != i_id_inst_orig
             START WITH id_institution = i_id_inst_orig
            CONNECT BY PRIOR id_parent = id_institution;
        
            -- getting desc of the parent institution type configured
            BEGIN
                g_error := 'SELECT pk_translation.get_translation / ' || l_params;
                SELECT pk_translation.get_translation(i_lang, pk_ref_constant.g_institution_code || t.id_institution)
                  INTO l_inst_parent_name
                  FROM (SELECT tpid.column_value id_institution
                          FROM (SELECT rownum rn, column_value
                                  FROM TABLE(CAST(l_par_flg_type_tab AS table_varchar))) tp -- parent types
                          JOIN (SELECT rownum rn, column_value
                                 FROM TABLE(CAST(l_par_id_inst_tab AS table_number))) tpid -- parent ids
                            ON tpid.rn = tp.rn
                          JOIN TABLE(CAST(l_cfg_flg_type_tab AS table_varchar)) tc -- types configured in sys_config
                            ON tc.column_value = tp.column_value) t;
            EXCEPTION
                WHEN no_data_found THEN
                    l_inst_parent_name := NULL;
                WHEN too_many_rows THEN
                    l_inst_parent_name := NULL;
            END;
        
        END IF;
    
        g_error := 'Call get_inst_orig_name / l_inst_parent_name=' || l_inst_parent_name || ' / ' || l_params;
        RETURN get_inst_orig_name(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_id_inst_orig     => i_id_inst_orig,
                                  i_inst_name_roda   => i_inst_name_roda,
                                  i_inst_parent_name => l_inst_parent_name);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_inst_orig_name_detail;

    /**
    * Gets professional functionality
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_dcs           department clinical service
    *
    * @RETURN  professional functionality
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION get_prof_func
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER IS
        l_func_tab table_number;
    BEGIN
        g_error := 'Init get_prof_func / i_prof=' || pk_utils.to_string(i_prof) || ' i_dcs=' || i_dcs;
        IF i_dcs IS NOT NULL
        THEN
            l_func_tab := get_prof_func_dcs(i_lang => i_lang, i_prof => i_prof, i_id_dcs => i_dcs);
        ELSE
            l_func_tab := get_prof_func_inst(i_lang => i_lang, i_prof => i_prof);
        END IF;
    
        IF l_func_tab.exists(1)
        THEN
            RETURN l_func_tab(1);
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' ' || SQLERRM);
            RETURN NULL;
    END get_prof_func;

    /**
    * Gets professional functionality not related to id_dep_clin_serv 
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    *
    * @RETURN  professional functionality
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-12-2012
    */
    FUNCTION get_prof_func_inst
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
    
        CURSOR c_prof_func IS
            SELECT pf.id_functionality
              FROM prof_func pf
              JOIN sys_functionality sf
                ON (pf.id_functionality = sf.id_functionality)
             WHERE pf.id_professional = i_prof.id
               AND sf.flg_available = pk_ref_constant.g_yes
               AND sf.id_software = i_prof.software
               AND pf.id_dep_clin_serv IS NULL -- not related to dep_clin_serv
               AND pf.id_institution = i_prof.institution; -- in this institution
    
        l_result table_number;
    BEGIN
    
        g_error := 'Init get_prof_func_inst / i_prof=' || pk_utils.to_string(i_prof);
        OPEN c_prof_func;
        FETCH c_prof_func BULK COLLECT
            INTO l_result;
        CLOSE c_prof_func;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' ' || SQLERRM);
            RETURN table_number();
    END get_prof_func_inst;

    /**
    * Gets professional functionality related to id_dep_clin_serv 
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_dcs        Department and service identifier
    *
    * @RETURN  professional functionality
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-12-2012
    */
    FUNCTION get_prof_func_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN table_number IS
    
        CURSOR c_prof_func IS -- any change to this query, remember to change the referral filter base to (VALUE_15)
            SELECT pf.id_functionality
              FROM prof_func pf
              JOIN prof_dep_clin_serv pdcs
                ON (pdcs.id_dep_clin_serv = pf.id_dep_clin_serv AND pdcs.id_professional = pf.id_professional)
              JOIN sys_functionality sf
                ON (pf.id_functionality = sf.id_functionality)
             WHERE pf.id_professional = i_prof.id
               AND pf.id_dep_clin_serv = i_id_dcs
               AND pdcs.flg_status = pk_ref_constant.g_status_selected
                  --AND sf.flg_available = pk_ref_constant.g_yes
               AND sf.id_software = i_prof.software;
    
        l_result table_number;
    BEGIN
        g_error := 'Init get_prof_func_dcs / i_prof=' || pk_utils.to_string(i_prof) || ' i_id_dcs=' || i_id_dcs;
        IF i_id_dcs IS NULL
        THEN
            RETURN table_number();
        END IF;
    
        OPEN c_prof_func;
        FETCH c_prof_func BULK COLLECT
            INTO l_result;
        CLOSE c_prof_func;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' ' || SQLERRM);
            RETURN table_number();
    END get_prof_func_dcs;

    /**
    * Checks if the professional is an intervener of the referral at origin institution
    *
    * @param   i_lang               Language associated to the professional
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_cat             Professional category identifier
    * @param   i_id_prof_requested  Referral professional that is responsible dor the referral
    * @param   i_id_inst_orig       Referral orig institution identifier    
    *
    * @RETURN  'Y' if professional is the intervener at origin institution, 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-12-2012
    */
    FUNCTION check_prof_orig
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cat            IN prof_cat.id_category%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_cat=' || i_id_cat || ' i_id_prof_requested=' ||
                    i_id_prof_requested || ' i_id_inst_orig=' || i_id_inst_orig;
        g_error  := 'Init check_prof_orig / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        IF i_prof.institution = i_id_inst_orig
        THEN
            IF i_id_cat = pk_ref_constant.g_cat_id_med
            THEN
                -- is the professional responsible for the referral
                g_error := 'check_prof_orig 1 / ' || l_params;
                IF i_prof.id = i_id_prof_requested
                THEN
                    l_result := pk_ref_constant.g_yes;
                END IF;
            ELSIF i_id_cat = pk_ref_constant.g_cat_id_adm
            THEN
                -- this professional works as registrar at origin institution
                g_error := 'check_prof_orig 2 / ' || l_params;
                IF pk_tools.get_prof_cat(i_prof => i_prof) = pk_ref_constant.g_registrar
                THEN
                    l_result := pk_ref_constant.g_yes;
                END IF;
            END IF;
        END IF;
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_prof_orig;

    /**
    * Checks if the professional is an intervener of the referral at dest institution
    *
    * @param   i_lang               Language associated to the professional
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_cat             Professional category identifier
    * @param   i_id_prof_requested  Referral professional that is responsible dor the referral
    * @param   i_id_inst_dest       Referral dest institution identifier
    * @param   i_id_dcs             Referral dep_clin_serv identifier
    *
    * @RETURN  'Y' if professional is the intervener at origin institution, 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-12-2012
    */
    FUNCTION check_prof_dest
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cat            IN prof_cat.id_category%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_dest      IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs            IN p1_external_request.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_cat=' || i_id_cat || ' i_id_prof_requested=' ||
                    i_id_prof_requested || ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_dcs=' || i_id_dcs;
        g_error  := 'Init check_prof_dest / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        IF i_prof.institution = i_id_inst_dest
        THEN
            IF i_id_cat = pk_ref_constant.g_cat_id_med
            THEN
                -- this professional can triage the referrals
                g_error := 'check_prof_dest 1 / ' || l_params;
                IF pk_ref_dest_phy.validate_dcs_triage(i_prof => i_prof, i_dcs => i_id_dcs) = pk_ref_constant.g_yes
                THEN
                    l_result := pk_ref_constant.g_yes;
                END IF;
            ELSIF i_id_cat = pk_ref_constant.g_cat_id_adm
            THEN
                -- this professional works as registrar at origin institution
                g_error := 'check_prof_dest 2 / ' || l_params;
                IF pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => i_id_dcs) = pk_ref_constant.g_yes
                THEN
                    l_result := pk_ref_constant.g_yes;
                END IF;
            END IF;
        END IF;
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_prof_dest;

    /**
    * Check if is Clinical Director
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-10-2009
    */
    FUNCTION is_clinical_director
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
        l_funcs_tab table_number;
    BEGIN
        g_error     := 'Call get_prof_func_inst / i_prof=' || pk_utils.to_string(i_prof);
        l_funcs_tab := get_prof_func_inst(i_lang => i_lang, i_prof => i_prof);
    
        <<prof_func>>
        FOR i IN 1 .. l_funcs_tab.count
        LOOP
            IF l_funcs_tab(i) = pk_ref_constant.g_ref_func_cd
            THEN
                RETURN TRUE;
            END IF;
        END LOOP prof_func;
    
        RETURN FALSE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
    END is_clinical_director;

    /**
    * Validate if the professional is a clinical director or not. Function used for grid
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   5-5-2010
    */
    FUNCTION validate_clin_dir
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error  := 'Call is_clinical_director / ID_PROF=' || i_prof.id || ' ID_INSTITUTION=' || i_prof.institution;
        g_retval := is_clinical_director(i_lang => i_lang, i_prof => i_prof);
    
        IF NOT g_retval
        THEN
            RETURN pk_ref_constant.g_no;
        END IF;
    
        RETURN pk_ref_constant.g_yes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN pk_ref_constant.g_no;
        
    END validate_clin_dir;

    /**
    * Gets professional profile template and functionality
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_dcs           department clinical service
    * @param   o_prof_data     Professional data: profile template, functionality and category
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2009
    */
    FUNCTION get_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof_data OUT t_rec_prof_data,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_prof_data / I_PROF=' || pk_utils.to_string(i_prof) || ' DCS=' || i_dcs;
    
        o_prof_data                     := t_rec_prof_data(NULL, NULL, NULL, NULL, NULL);
        o_prof_data.id_profile_template := pk_tools.get_prof_profile_template(i_prof);
        o_prof_data.id_functionality    := nvl(get_prof_func(i_lang => i_lang, i_prof => i_prof, i_dcs => i_dcs), 0);
        o_prof_data.id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        o_prof_data.flg_category        := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        o_prof_data.id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                           i_id_institution => i_prof.institution);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_DATA',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_data;

    /**
    * Process automatic referral status change
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_prof_data     Professional data    
    * @param   i_ref_row       P1_EXTERNAL_REQUEST row info
    * @param   i_status_end    Status end of this transition
    * @param   i_date          Status change date   
    * @param   i_flg_completed Flag indicating if referral is completed or not. Used in action='NEW'    
    * @param   i_notes         Referral notes related to the status change
    * @param   i_reason_code   Refuse reason code
    * @param   i_schedule      Schedule identification    
    * @param   i_diagnosis     Referral diagnosis id (referral answer)
    * @param   i_diag_desc     Referral diagnosis description (referral answer)
    * @param   i_answer        Referral answer details
    * @param   i_episode       Episode identifier (used by scheduler when scheduling ORIS/INP referral)   
    * @param   io_param        Parameters for framework workflows evaluation    
    * @param   io_track        Array of ID_TRACKING transitions    
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-10-2010
    */
    FUNCTION process_auto_transition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mode           IN VARCHAR2 DEFAULT NULL,
        i_flg_completed  IN VARCHAR2 DEFAULT NULL,
        i_notes          IN p1_detail.text%TYPE DEFAULT NULL,
        i_reason_code    IN p1_tracking.id_reason_code%TYPE DEFAULT NULL,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_level          IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_prof_dest      IN professional.id_professional%TYPE DEFAULT NULL,
        i_subtype        IN p1_tracking.flg_type%TYPE DEFAULT NULL,
        i_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        i_schedule       IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_diagnosis      IN table_number DEFAULT NULL,
        i_diag_desc      IN table_varchar DEFAULT NULL,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_answer         IN table_table_varchar DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        io_param         IN OUT NOCOPY table_varchar,
        io_track         IN OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date           p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row        p1_external_request%ROWTYPE;
        l_action_name    wf_workflow_action.internal_name%TYPE;
        l_flg_status_end p1_external_request.flg_status%TYPE;
        l_params         VARCHAR2(1000 CHAR);
    BEGIN
        l_params         := 'I_PROF=' || pk_utils.to_string(i_prof) || ' I_PROF_DATA=' ||
                            pk_ref_utils.to_string(i_prof_data) || ' ID_REF=' || i_id_ref || ' MODE=' || i_mode ||
                            ' REASON_CODE=' || i_reason_code || ' DCS=' || i_dcs || ' LEVEL=' || i_level ||
                            ' PROF_DEST=' || i_prof_dest || ' SUB_TYPE=' || i_subtype || ' INST_DEST=' || i_inst_dest ||
                            ' ID_SCHEDULE=' || i_schedule || ' i_flg_completed=' || i_flg_completed || ' ID_EPISODE=' ||
                            i_episode || ' IO_PARAM=' || pk_utils.to_string(io_param);
        g_error          := 'Init process_auto_transition / ' || l_params;
        l_date           := nvl(i_date, pk_ref_utils.get_sysdate);
        l_flg_status_end := NULL;
    
        IF io_track IS NULL
        THEN
            io_track := table_number();
        END IF;
    
        --  getting referral row (up to date)
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
    
        l_params := l_params || ' WF=' || l_ref_row.id_workflow || ' FLG_STATUS=' || l_ref_row.flg_status;
    
        -- getting next automatic action available (only one can be available)
        g_error  := 'Call pk_ref_status.get_next_action / ' || l_params;
        g_retval := pk_ref_status.get_next_action(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_prof_data   => i_prof_data,
                                                  i_id_workflow => l_ref_row.id_workflow,
                                                  i_flg_status  => l_ref_row.flg_status,
                                                  io_param      => io_param,
                                                  o_action_name => l_action_name,
                                                  o_flg_status  => l_flg_status_end,
                                                  o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ACTION_NAME=' || l_action_name || ' FLG_STATUS_END=' || l_flg_status_end;
    
        io_param(pk_ref_constant.g_idx_n_auto_trans) := nvl(io_param(pk_ref_constant.g_idx_n_auto_trans), 0) + 1;
    
        IF l_action_name IS NOT NULL
           AND io_param(pk_ref_constant.g_idx_n_auto_trans) <= pk_ref_constant.g_max_auto_transitions
        THEN
        
            g_error := 'Call pk_date_utils.add_to_ltstz / ' || l_params;
            l_date  := pk_date_utils.add_to_ltstz(i_timestamp => l_date,
                                                  i_amount    => 1, -- adds one second to l_date
                                                  i_unit      => pk_ref_constant.g_second);
        
            -- IF l_action_name is not null then process this transition
            g_error  := 'Call process_transition2 / ' || l_params;
            g_retval := process_transition2(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_data  => i_prof_data,
                                            i_ref_row    => l_ref_row,
                                            i_action     => l_action_name,
                                            i_dcs        => i_dcs,
                                            i_status_end => l_flg_status_end,
                                            i_date       => l_date,
                                            i_mode       => i_mode,
                                            io_param     => io_param,
                                            io_track     => io_track,
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
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PROCESS_AUTO_TRANSITION',
                                              o_error    => o_error);
            RETURN FALSE;
    END process_auto_transition;

    /**
    * Process referral status change 
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_prof_data     Professional data    
    * @param   i_ref_row       P1_EXTERNAL_REQUEST row info
    * @param   i_action        Action to process to change status
    * @param   i_status_end    Status end of this transition
    * @param   i_date          Status change date       
    * @param   i_notes         Referral notes related to the status change
    * @param   i_reason_code   Refuse reason code
    * @param   i_schedule      Schedule identification    
    * @param   i_diagnosis     Referral diagnosis id (referral answer)
    * @param   i_diag_desc     Referral diagnosis description (referral answer)
    * @param   i_answer        Referral answer details
    * @param   i_episode       Episode identifier (used by scheduler when scheduling ORIS/INP referral)   
    * @param   io_param        Parameters for framework workflows evaluation
    * @param   io_track        Array of ID_TRACKING transitions    
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2009
    */
    FUNCTION process_transition2
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_data        IN t_rec_prof_data,
        i_ref_row          IN p1_external_request%ROWTYPE,
        i_action           IN VARCHAR2,
        i_status_end       IN p1_external_request.flg_status%TYPE,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mode             IN VARCHAR2 DEFAULT NULL,
        i_notes            IN p1_detail.text%TYPE DEFAULT NULL,
        i_reason_code      IN p1_tracking.id_reason_code%TYPE DEFAULT NULL,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_level            IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_prof_dest        IN professional.id_professional%TYPE DEFAULT NULL,
        i_subtype          IN p1_tracking.flg_type%TYPE DEFAULT NULL,
        i_inst_dest        IN institution.id_institution%TYPE DEFAULT NULL,
        i_schedule         IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_diagnosis        IN table_number DEFAULT NULL,
        i_diag_desc        IN table_varchar DEFAULT NULL,
        i_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_answer           IN table_table_varchar DEFAULT NULL,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        io_param           IN OUT NOCOPY table_varchar,
        io_track           IN OUT table_number,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date           p1_tracking.dt_tracking_tstz%TYPE;
        l_flg_status_end p1_external_request.flg_status%TYPE;
        l_status_end     p1_external_request.flg_status%TYPE;
        l_track_tab      table_number;
        l_params         VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_prof_data=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' ID_REF=' || i_ref_row.id_external_request || ' FLG_STATUS=' || i_ref_row.flg_status ||
                    ' i_action=' || i_action || ' i_status_end=' || i_status_end || ' i_mode=' || i_mode ||
                    ' i_reason_code=' || i_reason_code || ' i_dcs=' || i_dcs || ' i_level=' || i_level ||
                    ' i_prof_dest=' || i_prof_dest || ' i_subtype=' || i_subtype || ' i_inst_dest=' || i_inst_dest ||
                    ' i_schedule=' || i_schedule || ' i_episode=' || i_episode || ' io_param=' ||
                    pk_utils.to_string(io_param);
        g_error  := 'Init process_transition / ' || l_params;
        l_date   := nvl(i_date, pk_ref_utils.get_sysdate);
    
        IF io_track IS NULL
        THEN
            io_track := table_number();
        END IF;
    
        IF io_param IS NULL
        THEN
            g_error  := 'Calling init_param_tab / ' || l_params;
            io_param := init_param_tab(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_ext_req            => i_ref_row.id_external_request,
                                       i_id_patient         => i_ref_row.id_patient,
                                       i_id_inst_orig       => i_ref_row.id_inst_orig,
                                       i_id_inst_dest       => i_ref_row.id_inst_dest,
                                       i_id_dep_clin_serv   => i_ref_row.id_dep_clin_serv,
                                       i_id_speciality      => i_ref_row.id_speciality,
                                       i_flg_type           => i_ref_row.flg_type,
                                       i_decision_urg_level => i_ref_row.decision_urg_level,
                                       i_id_prof_requested  => i_ref_row.id_prof_requested,
                                       i_id_prof_redirected => i_ref_row.id_prof_redirected,
                                       i_id_prof_status     => i_ref_row.id_prof_status,
                                       i_external_sys       => i_ref_row.id_external_sys,
                                       i_flg_status         => i_ref_row.flg_status);
        
        END IF;
    
        ----------------------------
        -- getting status_end IF NULL
        IF i_status_end IS NULL
        THEN
        
            g_error  := 'Call pk_ref_status.get_next_status / ' || l_params;
            g_retval := pk_ref_status.get_next_status(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_prof_data           => i_prof_data,
                                                      i_id_workflow         => i_ref_row.id_workflow,
                                                      i_flg_status          => i_ref_row.flg_status,
                                                      i_action_name         => i_action,
                                                      io_param              => io_param,
                                                      i_flg_auto_transition => pk_ref_constant.g_no,
                                                      o_flg_status          => l_status_end,
                                                      o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSE
            g_error      := 'l_status_end=' || i_status_end;
            l_status_end := i_status_end;
        END IF;
    
        ----------------------------        
        -- updating referral status   
        l_params := l_params || ' l_status_end=' || l_status_end;
        g_error  := 'CASE ' || i_action || ' / ' || l_params;
        CASE i_action
            WHEN pk_ref_constant.g_ref_action_i THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_issued / ' || l_params;
                g_retval := pk_ref_status.set_ref_issued2(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_prof_data  => i_prof_data,
                                                          i_ref_row    => i_ref_row,
                                                          i_action     => i_action,
                                                          i_status_end => l_status_end,
                                                          i_mode       => i_mode,
                                                          i_dcs        => i_dcs,
                                                          i_date       => l_date,
                                                          io_param     => io_param,
                                                          o_track      => l_track_tab,
                                                          o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_di THEN
            
                -- changing dest_institution
                g_error  := 'Calling pk_ref_status.set_ref_dest_inst / ' || l_params;
                g_retval := pk_ref_status.set_ref_dest_inst2(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_prof_data  => i_prof_data,
                                                             i_ref_row    => i_ref_row,
                                                             i_action     => i_action,
                                                             i_status_end => l_status_end,
                                                             i_inst_dest  => i_inst_dest,
                                                             i_dcs        => i_dcs,
                                                             i_notes      => i_notes,
                                                             i_date       => l_date,
                                                             io_param     => io_param,
                                                             o_track      => l_track_tab,
                                                             o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_t THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_sent_triage / ' || l_params;
                g_retval := pk_ref_status.set_ref_sent_triage(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_prof_data   => i_prof_data,
                                                              i_ref_row     => i_ref_row,
                                                              i_action      => i_action,
                                                              i_status_end  => l_status_end,
                                                              i_reason_code => i_reason_code,
                                                              i_dcs         => i_dcs,
                                                              i_notes       => i_notes,
                                                              i_date        => l_date,
                                                              io_param      => io_param,
                                                              o_track       => l_track_tab,
                                                              o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_cs THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_cs / ' || l_params;
                g_retval := pk_ref_status.set_ref_cs2(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_prof_data  => i_prof_data,
                                                      i_ref_row    => i_ref_row,
                                                      i_action     => i_action,
                                                      i_status_end => l_status_end,
                                                      i_dcs        => i_dcs,
                                                      i_subtype    => i_subtype,
                                                      i_notes      => i_notes,
                                                      i_date       => l_date,
                                                      io_param     => io_param,
                                                      o_track      => l_track_tab,
                                                      o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_a THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_triaged2 / ' || l_params;
                g_retval := pk_ref_status.set_ref_triaged2(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_prof_data  => i_prof_data,
                                                           i_ref_row    => i_ref_row,
                                                           i_action     => i_action,
                                                           i_status_end => l_status_end,
                                                           i_date       => l_date,
                                                           i_notes      => i_notes,
                                                           i_prof_dest  => i_prof_dest,
                                                           i_dcs        => i_dcs,
                                                           i_level      => i_level,
                                                           io_param     => io_param,
                                                           o_track      => l_track_tab,
                                                           o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_b THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_prof_data   => i_prof_data,
                                                       i_ref_row     => i_ref_row,
                                                       i_action      => i_action,
                                                       i_status_end  => l_status_end,
                                                       i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                                       i_reason_code => i_reason_code,
                                                       i_notes_desc  => i_notes,
                                                       i_notes_type  => pk_ref_constant.g_detail_type_bdcl,
                                                       i_op_date     => l_date,
                                                       io_param      => io_param,
                                                       o_track       => l_track_tab,
                                                       o_flg_status  => l_flg_status_end,
                                                       o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_s THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_scheduled / ' || l_params;
                g_retval := pk_ref_status.set_ref_scheduled2(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_prof_data  => i_prof_data,
                                                             i_ref_row    => i_ref_row,
                                                             i_action     => i_action,
                                                             i_status_end => l_status_end,
                                                             i_date       => l_date,
                                                             i_schedule   => i_schedule,
                                                             i_episode    => i_episode,
                                                             io_param     => io_param,
                                                             o_track      => l_track_tab,
                                                             o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_m THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_mailed / ' || l_params;
                g_retval := pk_ref_status.set_ref_mailed2(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_prof_data  => i_prof_data,
                                                          i_ref_row    => i_ref_row,
                                                          i_action     => i_action,
                                                          i_status_end => l_status_end,
                                                          i_date       => l_date,
                                                          io_param     => io_param,
                                                          o_track      => l_track_tab,
                                                          o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_e THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_efectv / ' || l_params;
                g_retval := pk_ref_status.set_ref_efectv2(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_prof_data      => i_prof_data,
                                                          i_ref_row        => i_ref_row,
                                                          i_action         => i_action,
                                                          i_status_end     => l_status_end,
                                                          i_date           => l_date,
                                                          i_transaction_id => i_transaction_id,
                                                          io_param         => io_param,
                                                          o_track          => l_track_tab,
                                                          o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_d THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_decline / ' || l_params;
                g_retval := pk_ref_status.set_ref_decline2(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_prof_data   => i_prof_data,
                                                           i_ref_row     => i_ref_row,
                                                           i_action      => i_action,
                                                           i_status_end  => l_status_end,
                                                           i_date        => l_date,
                                                           i_notes       => i_notes,
                                                           i_reason_code => i_reason_code,
                                                           io_param      => io_param,
                                                           o_track       => l_track_tab,
                                                           o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_y THEN
                g_error  := 'Calling pk_ref_status.set_ref_decline_cd / ' || l_params;
                g_retval := pk_ref_status.set_ref_decline_cd(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_prof_data   => i_prof_data,
                                                             i_ref_row     => i_ref_row,
                                                             i_action      => i_action,
                                                             i_status_end  => l_status_end,
                                                             i_date        => l_date,
                                                             i_notes       => i_notes,
                                                             i_reason_code => i_reason_code,
                                                             io_param      => io_param,
                                                             o_track       => l_track_tab,
                                                             o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_r THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_forward / ' || l_params;
                g_retval := pk_ref_status.set_ref_forward2(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_prof_data  => i_prof_data,
                                                           i_ref_row    => i_ref_row,
                                                           i_action     => i_action,
                                                           i_status_end => l_status_end,
                                                           i_date       => l_date,
                                                           i_notes      => i_notes,
                                                           i_prof_dest  => i_prof_dest,
                                                           i_subtype    => i_subtype,
                                                           io_param     => io_param,
                                                           o_track      => l_track_tab,
                                                           o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_x THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_refuse / ' || l_params;
                g_retval := pk_ref_status.set_ref_refuse2(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_prof_data   => i_prof_data,
                                                          i_ref_row     => i_ref_row,
                                                          i_action      => i_action,
                                                          i_status_end  => l_status_end,
                                                          i_date        => l_date,
                                                          i_notes       => i_notes,
                                                          i_reason_code => i_reason_code,
                                                          i_subtype     => i_subtype,
                                                          io_param      => io_param,
                                                          o_track       => l_track_tab,
                                                          o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_c THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_cancel / ' || l_params;
                g_retval := pk_ref_status.set_ref_cancel2(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_prof_data   => i_prof_data,
                                                          i_ref_row     => i_ref_row,
                                                          i_action      => i_action,
                                                          i_status_end  => l_status_end,
                                                          i_date        => l_date,
                                                          i_notes       => i_notes,
                                                          i_reason_code => i_reason_code,
                                                          io_param      => io_param,
                                                          o_track       => l_track_tab,
                                                          o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_w THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_answer / ' || l_params;
                g_retval := pk_ref_status.set_ref_answer2(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_prof_data        => i_prof_data,
                                                          i_ref_row          => i_ref_row,
                                                          i_action           => i_action,
                                                          i_status_end       => l_status_end,
                                                          i_date             => l_date,
                                                          i_diagnosis        => i_diagnosis,
                                                          i_diag_desc        => i_diag_desc,
                                                          i_answer           => i_answer,
                                                          io_param           => io_param,
                                                          i_health_prob      => i_health_prob,
                                                          i_health_prob_desc => i_health_prob_desc,
                                                          o_track            => l_track_tab,
                                                          o_error            => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_n THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_new / ' || l_params;
                g_retval := pk_ref_status.set_ref_new2(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_prof_data  => i_prof_data,
                                                       i_ref_row    => i_ref_row,
                                                       i_action     => i_action,
                                                       i_dcs        => i_dcs,
                                                       i_status_end => l_status_end,
                                                       i_date       => l_date,
                                                       io_param     => io_param,
                                                       o_track      => l_track_tab,
                                                       o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_csh THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_cancel_sch / ' || l_params;
                g_retval := pk_ref_status.set_ref_cancel_sch2(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_prof_data   => i_prof_data,
                                                              i_ref_row     => i_ref_row,
                                                              i_action      => i_action,
                                                              i_status_end  => l_status_end,
                                                              i_schedule    => i_schedule,
                                                              i_notes       => i_notes,
                                                              i_date        => l_date,
                                                              i_reason_code => i_reason_code,
                                                              io_param      => io_param,
                                                              o_track       => l_track_tab,
                                                              o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_l THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_prof_data  => i_prof_data,
                                                       i_ref_row    => i_ref_row,
                                                       i_action     => i_action,
                                                       i_status_end => l_status_end,
                                                       i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                                       i_op_date    => l_date,
                                                       io_param     => io_param,
                                                       o_track      => l_track_tab,
                                                       o_flg_status => l_flg_status_end,
                                                       o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_unl THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_prev_status / ' || l_params;
                g_retval := pk_ref_status.set_ref_prev_status(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_prof_data  => i_prof_data,
                                                              i_ref_row    => i_ref_row,
                                                              i_action     => i_action,
                                                              i_status_end => l_status_end,
                                                              i_op_date    => l_date,
                                                              io_param     => io_param,
                                                              o_track      => l_track_tab,
                                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_f THEN
                g_error  := 'Calling pk_ref_status.set_ref_noshow / ' || l_params;
                g_retval := pk_ref_status.set_ref_noshow(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_prof_data      => i_prof_data,
                                                         i_ref_row        => i_ref_row,
                                                         i_action         => i_action,
                                                         i_status_end     => l_status_end,
                                                         i_notes          => i_notes,
                                                         i_reason_code    => i_reason_code,
                                                         i_date           => l_date,
                                                         i_transaction_id => i_transaction_id,
                                                         io_param         => io_param,
                                                         o_track          => l_track_tab,
                                                         o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_k THEN
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_prof_data  => i_prof_data,
                                                       i_ref_row    => i_ref_row,
                                                       i_action     => i_action,
                                                       i_status_end => l_status_end,
                                                       i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                                       i_op_date    => l_date,
                                                       io_param     => io_param,
                                                       o_track      => l_track_tab,
                                                       o_flg_status => l_flg_status_end,
                                                       o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_j THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_prof_data  => i_prof_data,
                                                       i_ref_row    => i_ref_row,
                                                       i_action     => i_action,
                                                       i_status_end => l_status_end,
                                                       i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                                       i_op_date    => l_date,
                                                       io_param     => io_param,
                                                       o_track      => l_track_tab,
                                                       o_flg_status => l_flg_status_end,
                                                       o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_v THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_approved / ' || l_params;
                g_retval := pk_ref_status.set_ref_approved2(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_prof_data  => i_prof_data,
                                                            i_ref_row    => i_ref_row,
                                                            i_action     => i_action,
                                                            i_status_end => l_status_end,
                                                            i_notes      => i_notes,
                                                            i_date       => l_date,
                                                            io_param     => io_param,
                                                            o_track      => l_track_tab,
                                                            o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_h THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_prof_data  => i_prof_data,
                                                       i_ref_row    => i_ref_row,
                                                       i_action     => i_action,
                                                       i_status_end => l_status_end,
                                                       i_flg_type   => pk_ref_constant.g_tracking_type_s,
                                                       i_notes_desc => i_notes,
                                                       i_notes_type => pk_ref_constant.g_detail_type_ndec,
                                                       i_op_date    => l_date,
                                                       io_param     => io_param,
                                                       o_track      => l_track_tab,
                                                       o_flg_status => l_flg_status_end,
                                                       o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_z THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_prof_data   => i_prof_data,
                                                       i_ref_row     => i_ref_row,
                                                       i_action      => i_action,
                                                       i_status_end  => l_status_end,
                                                       i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                                       i_reason_code => i_reason_code,
                                                       i_notes_desc  => i_notes,
                                                       i_notes_type  => pk_ref_constant.g_detail_type_req_can,
                                                       i_op_date     => l_date,
                                                       io_param      => io_param,
                                                       o_track       => l_track_tab,
                                                       o_flg_status  => l_flg_status_end,
                                                       o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_zdn THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_prev_status / ' || l_params;
                g_retval := pk_ref_status.set_ref_prev_status(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_prof_data  => i_prof_data,
                                                              i_ref_row    => i_ref_row,
                                                              i_action     => i_action,
                                                              i_status_end => l_status_end,
                                                              i_notes_desc => i_notes,
                                                              i_notes_type => pk_ref_constant.g_detail_type_req_can_answ,
                                                              i_op_date    => l_date,
                                                              io_param     => io_param,
                                                              o_track      => l_track_tab,
                                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_dcl_r THEN
            
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_prof_data   => i_prof_data,
                                                       i_ref_row     => i_ref_row,
                                                       i_action      => i_action,
                                                       i_status_end  => l_status_end,
                                                       i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                                       i_reason_code => i_reason_code,
                                                       i_notes_desc  => i_notes,
                                                       i_notes_type  => pk_ref_constant.g_detail_type_dcl_r,
                                                       i_op_date     => l_date,
                                                       io_param      => io_param,
                                                       o_track       => l_track_tab,
                                                       o_flg_status  => l_flg_status_end,
                                                       o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_ute THEN
                g_error  := 'Calling pk_ref_status.set_ref_prev_status / ' || l_params;
                g_retval := pk_ref_status.set_ref_prev_status(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_prof_data  => i_prof_data,
                                                              i_ref_row    => i_ref_row,
                                                              i_action     => i_action,
                                                              i_status_end => l_status_end,
                                                              i_op_date    => l_date,
                                                              io_param     => io_param,
                                                              o_track      => l_track_tab,
                                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_utm THEN
                g_error  := 'Calling pk_ref_status.set_ref_prev_status / ' || l_params;
                g_retval := pk_ref_status.set_ref_prev_status(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_prof_data  => i_prof_data,
                                                              i_ref_row    => i_ref_row,
                                                              i_action     => i_action,
                                                              i_status_end => l_status_end,
                                                              i_op_date    => l_date,
                                                              io_param     => io_param,
                                                              o_track      => l_track_tab,
                                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
            WHEN pk_ref_constant.g_ref_action_uts THEN
                g_error  := 'Calling pk_ref_status.set_ref_prev_status / ' || l_params;
                g_retval := pk_ref_status.set_ref_prev_status(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_prof_data  => i_prof_data,
                                                              i_ref_row    => i_ref_row,
                                                              i_action     => i_action,
                                                              i_status_end => l_status_end,
                                                              i_op_date    => l_date,
                                                              io_param     => io_param,
                                                              o_track      => l_track_tab,
                                                              o_error      => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            ELSE
            
                -- just updates status
                g_error  := 'Calling pk_ref_status.set_ref_base / ' || l_params;
                g_retval := pk_ref_status.set_ref_base(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_prof_data   => i_prof_data,
                                                       i_ref_row     => i_ref_row,
                                                       i_action      => i_action,
                                                       i_status_end  => l_status_end,
                                                       i_flg_type    => pk_ref_constant.g_tracking_type_s,
                                                       i_reason_code => NULL,
                                                       i_notes_desc  => NULL,
                                                       i_notes_type  => NULL,
                                                       i_op_date     => l_date,
                                                       io_param      => io_param,
                                                       o_track       => l_track_tab,
                                                       o_flg_status  => l_flg_status_end,
                                                       o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                io_track := io_track MULTISET UNION l_track_tab;
            
        END CASE;
    
        g_error := 'Add action ' || i_action || ' to io_param / ' || l_params;
        io_param(pk_ref_constant.g_idx_id_action) := pk_ref_constant.get_action_id(i_action);
    
        ----------------------------        
        -- processing automatic transitions
        g_error  := 'Call process_auto_transition / ACTION_NAME=' || i_action || ' / ' || l_params;
        g_retval := process_auto_transition(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_prof_data      => i_prof_data,
                                            i_id_ref         => i_ref_row.id_external_request,
                                            i_date           => l_date,
                                            i_mode           => i_mode,
                                            i_notes          => i_notes,
                                            i_reason_code    => i_reason_code,
                                            i_dcs            => i_dcs,
                                            i_level          => i_level,
                                            i_prof_dest      => i_prof_dest,
                                            i_subtype        => i_subtype,
                                            i_inst_dest      => i_inst_dest,
                                            i_schedule       => i_schedule,
                                            i_diagnosis      => i_diagnosis,
                                            i_diag_desc      => i_diag_desc,
                                            i_episode        => i_episode,
                                            i_answer         => i_answer,
                                            io_param         => io_param,
                                            i_transaction_id => i_transaction_id,
                                            io_track         => io_track,
                                            o_error          => o_error);
    
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
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PROCESS_TRANSITION',
                                              o_error    => o_error);
            RETURN FALSE;
    END process_transition2;

    /**
    * Changes referral status.
    *
    * @param   I_LANG                Language associated to the professional executing the request
    * @param   I_PROF                Professional, institution and software ids
    * @param   i_ext_req             Referral identification
    * @param   i_status_begin        Begin Transition status. This parameter will be ignored.
    * @param   i_status_end          End Transition status. This parameter will be ignored.
    * @param   i_action              Action to process    
    * @param   i_level               Referral decision urgency level    
    * @param   i_prof_dest           Dest professional id (when forwarding or scheduling the request)   
    * @param   i_dcs                 Service id, used when changing clinical service
    * @param   i_notes               Notes related to transition
    * @param   i_dt_modified         Last modified date as provided by get_referral
    * @param   i_mode                (V)alidate date modified or do(N)t
    * @param   i_reason_code         Decline or refuse reason code 
    * @param   i_subtype             Flag used to mark refusals made by the interface
    * @param   i_inst_dest           Id of new institution, used when changing institution    
    * @param   i_date                Operation date
    * @param   o_track               Array of ID_TRACKING transitions
    * @param   o_flg_show            Flag indicating if o_msg is shown
    * @param   o_msg                 Message indicating that referral has been changed
    * @param   o_msg_title           Message title
    * @param   o_button              Button type    
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.1
    * @since   23-06-2009
    */
    FUNCTION set_status2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_status_begin   IN p1_external_request.flg_status%TYPE, -- deprecated (ignored)
        i_status_end     IN p1_external_request.flg_status%TYPE, -- deprecated (ignored)
        i_action         IN wf_workflow_action.internal_name%TYPE, -- new parameter
        i_level          IN p1_external_request.decision_urg_level%TYPE,
        i_prof_dest      IN professional.id_professional%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_dt_modified    IN VARCHAR2,
        i_mode           IN VARCHAR2,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE,
        i_subtype        IN p1_tracking.flg_subtype%TYPE,
        i_inst_dest      IN institution.id_institution%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_track          OUT table_number,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_data t_rec_prof_data;
        l_ref_row   p1_external_request%ROWTYPE;
        l_param     table_varchar;
        l_params    VARCHAR2(1000 CHAR);
    BEGIN
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        l_params       := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_ext_req || ' STATUS_BEGIN=' ||
                          i_status_begin || ' STATUS_END=' || i_status_end || ' ACTION=' || i_action || ' LEVEL=' ||
                          i_level || ' ID_PROF_DEST=' || i_prof_dest || ' ID_DCS=' || i_dcs || ' DT_MODIFIED=' ||
                          i_dt_modified || ' MODE=' || i_mode || ' ID_REASON_CODE=' || i_reason_code || ' FLG_SUBTYPE=' ||
                          i_subtype || ' ID_INST_DEST=' || i_inst_dest || ' I_DATE=' ||
                          pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDDHH24MISS');
    
        g_error := 'Init set_status / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_track := table_number();
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- JS: 2007-04-13, check if referral was updated while edited
        o_flg_show := pk_ref_constant.g_no;
        IF i_mode = pk_ref_constant.g_validate_changes
        THEN
        
            g_error := 'Validating changes / ' || l_params;
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
    
        l_params := l_params || ' DCS=' || l_ref_row.id_dep_clin_serv;
    
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => l_ref_row.id_dep_clin_serv,
                                  o_prof_data => l_prof_data,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' PROF_DATA=' || pk_ref_utils.to_string(l_prof_data);
    
        g_error := 'Calling init_param_tab / ' || l_params;
        l_param := init_param_tab(i_lang               => i_lang,
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
    
        g_error  := 'Calling process_transition / ' || l_params;
        g_retval := process_transition2(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_prof_data      => l_prof_data,
                                        i_ref_row        => l_ref_row,
                                        i_action         => i_action,
                                        i_status_end     => i_status_end,
                                        i_date           => g_sysdate_tstz,
                                        i_notes          => i_notes,
                                        i_reason_code    => i_reason_code,
                                        i_dcs            => i_dcs,
                                        i_level          => i_level,
                                        i_prof_dest      => i_prof_dest,
                                        i_subtype        => i_subtype,
                                        i_inst_dest      => i_inst_dest,
                                        i_transaction_id => i_transaction_id,
                                        io_param         => l_param,
                                        io_track         => o_track,
                                        o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_row.id_speciality != l_param(pk_ref_constant.g_idx_id_speciality)
        THEN
            -- referral speciality has been changed, notify inter-alert
            g_error := 'Call pk_api_ref_event.set_ref_update / ' || l_params || ' FLG_STATUS=' ||
                       l_param(pk_ref_constant.g_idx_flg_status) || ' ID_SPEC_INITIAL=' || l_ref_row.id_speciality ||
                       ' ID_SPEC_FINAL=' || l_param(pk_ref_constant.g_idx_id_speciality);
            pk_api_ref_event.set_ref_update(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_ref     => l_ref_row.id_external_request,
                                            i_flg_status => l_param(pk_ref_constant.g_idx_flg_status), -- actual flg_status
                                            i_id_inst    => i_prof.institution);
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
                                              i_function => 'SET_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_status2;

    /**
    * Function used in grids to return referral priority information
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional id, institution and software    
    * @param   I_EXT_REQ            Referral identifier    
    * @param   I_FLG_PRIORITY       Professional functionality   
    *
    * @RETURN  icon|priority_color|l_text_color|l_val|rank|l_priority|l_desc_priority
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-10-2012
    */
    FUNCTION get_ref_priority_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_priority IN p1_external_request.flg_priority%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(4000);
        --l_desc_dom_ref_prio   sys_domain.code_domain%TYPE;
        --l_priority_level      sys_config.value%TYPE;
        l_color_ref_prio      sys_domain.code_domain%TYPE;
        l_text_color_ref_prio sys_domain.code_domain%TYPE;
        l_val                 sys_domain.val%TYPE;
        l_icon                sys_domain.img_name%TYPE;
        l_rank                sys_domain.rank%TYPE;
        l_priority            sys_domain.desc_val%TYPE;
        l_desc_priority       sys_domain.desc_val%TYPE;
        l_priority_color      sys_domain.desc_val%TYPE;
        l_text_color          sys_domain.desc_val%TYPE;
    BEGIN
        g_error := 'Init get_ref_priority_info / I_FLG_PRIORITY' || i_flg_priority;
        --l_priority_level := pk_ref_utils.get_sys_config(i_prof          => i_prof,
        --                                                i_id_sys_config => pk_ref_constant.g_ref_priority_level);
        --l_desc_dom_ref_prio   := pk_ref_constant.g_ref_prio; -- || '.' || l_priority_level;
        l_color_ref_prio      := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.COLOR';
        l_text_color_ref_prio := 'P1_EXTERNAL_REQUEST.FLG_PRIORITY.TEXT_COLOR';
    
        l_val  := i_flg_priority;
        l_icon := pk_ref_utils.get_domain_cached_img_name(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_code_domain => pk_ref_constant.g_ref_prio,
                                                          i_val         => i_flg_priority);
        l_rank := lpad(pk_ref_utils.get_domain_cached_rank(i_lang, i_prof, pk_ref_constant.g_ref_prio, i_flg_priority),
                       6,
                       '0');
    
        l_priority_color := pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_code_domain => l_color_ref_prio,
                                                                i_val         => i_flg_priority);
    
        l_text_color := pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_code_domain => l_text_color_ref_prio,
                                                            i_val         => i_flg_priority);
    
        l_priority := pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_code_domain => pk_ref_constant.g_ref_prio,
                                                          i_val         => i_flg_priority);
    
        -- todo: texto para a tooltip                                                             
    
        IF nvl(l_priority_color, ' ') = ' '
        THEN
            l_priority_color := NULL;
        END IF;
    
        IF nvl(l_text_color, ' ') = ' '
        THEN
            l_text_color := NULL;
        END IF;
    
        l_desc_priority := NULL;
    
        -- l_result has the following format: 
        -- icon|priority_color|l_text_color|l_val|rank|l_priority|l_desc_priority    
        l_result := l_icon || '|' || l_priority_color || '|' || l_text_color || '|' || l_val || '|' || l_rank || '|' ||
                    l_priority || '|' || l_desc_priority;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_ref_priority_info /  I_FLG_PRIORITY' || i_flg_priority || ' / ' || g_error || ' / ' ||
                       SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_ref_priority_info;

    /**
    * Function used in grids to return referral priority description
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software        
    * @param   i_flg_priority       Professional functionality   
    *
    * @RETURN  Priority description
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-10-2013
    */
    FUNCTION get_ref_priority_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_priority IN p1_external_request.flg_priority%TYPE
    ) RETURN VARCHAR2 IS
        l_params               VARCHAR2(1000 CHAR);
        l_result               VARCHAR2(1000 CHAR);
        l_priority_code        sys_config.desc_sys_config%TYPE;
        l_desc_dom_detail      sys_config.desc_sys_config%TYPE;
        l_desc_priority        sys_domain.desc_val%TYPE;
        l_desc_priority_detail sys_domain.desc_val%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' I_FLG_PRIORITY' || i_flg_priority;
        g_error  := 'Init get_ref_priority_desc / ' || l_params;
    
        l_priority_code   := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                         i_id_sys_config => pk_ref_constant.g_ref_priority_level);
        l_desc_dom_detail := pk_ref_constant.g_ref_prio || '.' || l_priority_code;
    
        g_error                := 'Call pk_ref_utils.get_domain_cached_desc / ' || pk_ref_constant.g_ref_prio || ',' ||
                                  l_desc_dom_detail || ' / ' || l_params;
        l_desc_priority        := pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_code_domain => pk_ref_constant.g_ref_prio,
                                                                      i_val         => i_flg_priority);
        l_desc_priority_detail := pk_ref_utils.get_domain_cached_desc(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_code_domain => l_desc_dom_detail,
                                                                      i_val         => i_flg_priority);
    
        g_error := 'Result / ' || pk_ref_constant.g_ref_prio || ',' || l_desc_dom_detail || ' / ' || l_params;
        IF l_desc_priority_detail IS NOT NULL
           AND l_desc_priority != l_desc_priority_detail -- this is not to repeat the label: lala-lala
        THEN
            l_result := l_desc_priority || '-' || l_desc_priority_detail;
        ELSE
            l_result := l_desc_priority;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_ref_priority_desc;

    /**
    * Returuns value to show in observations column in referral grids 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_prof_profile          Professional profile template
    * @param   i_id_ref                Referral identifier    
    * @param   i_flg_status            Referral status       
    * @param   i_id_prof_status        Professional that changed the referral status
    * @param   i_dt_schedule           Referral schedule timestamp
    * @param   i_view_clin_data        If professional can view clinical data
    * @param   i_id_prof_triage        Professional that has triaged the referral
    * @param   i_id_prof_sch_sugg     Scheduled professional suggested by triage physician
    *
    * @value   i_view_clin_data        {*} 'Y' - can view clinical data {*} 'N' - otherwise
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-03-2011
    */
    FUNCTION get_ref_observations
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_profile     IN profile_template.id_profile_template%TYPE,
        i_id_ref           IN referral_ea.id_external_request%TYPE,
        i_flg_status       IN referral_ea.flg_status%TYPE,
        i_id_prof_status   IN referral_ea.id_prof_status%TYPE,
        i_dt_schedule      IN referral_ea.dt_schedule%TYPE,
        i_view_clin_data   IN VARCHAR2,
        i_id_prof_triage   IN referral_ea.id_prof_triage%TYPE,
        i_id_prof_sch_sugg IN referral_ea.id_prof_sch_sugg%TYPE
    ) RETURN VARCHAR2 IS
        l_result             VARCHAR2(1000 CHAR);
        l_id_workflow_action p1_tracking.id_workflow_action%TYPE;
        l_dt_schedule_v      VARCHAR2(50 CHAR);
        l_hour_schedule_v    VARCHAR2(50 CHAR);
        l_id_prof_sch_sugg   referral_ea.id_prof_sch_sugg%TYPE;
    BEGIN
        g_error := 'Init get_ref_observations / i_id_ref=' || i_id_ref || ' i_flg_status=' || i_flg_status ||
                   ' i_id_prof_status=' || i_id_prof_status || ' i_view_clin_data=' || i_view_clin_data;
        IF i_flg_status IN (pk_ref_constant.g_p1_status_d,
                            pk_ref_constant.g_p1_status_x,
                            pk_ref_constant.g_p1_status_y,
                            pk_ref_constant.g_p1_status_f,
                            pk_ref_constant.g_p1_status_q)
        THEN
            l_result := pk_ref_core.get_referral_obs(i_lang, i_prof, i_id_ref, i_flg_status, i_view_clin_data);
        ELSIF i_flg_status = pk_ref_constant.g_p1_status_z
        THEN
            -- status name: professional name
            l_result := pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', i_flg_status, i_lang) || ': ' ||
                        pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof_status);
        
        ELSIF i_flg_status = pk_ref_constant.g_p1_status_i
        THEN
            g_error              := 'i_flg_status=' || i_flg_status;
            l_id_workflow_action := pk_ref_utils.get_cur_action(i_lang, i_prof, i_id_ref);
        
            IF l_id_workflow_action = pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_dcl_r)
            THEN
                -- DECLINE_TO_REG action
                l_result := pk_message.get_message(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_code_mess => pk_ref_constant.g_sm_ref_grid_t024) || ': ' ||
                            pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof_status);
            END IF;
        
        ELSIF i_flg_status = pk_ref_constant.g_p1_status_a
        THEN
            IF i_id_prof_sch_sugg IS NULL
            THEN
            
                g_error            := 'i_flg_status=' || i_flg_status;
                l_id_prof_sch_sugg := pk_ref_dest_phy.get_suggested_physician(i_lang   => i_lang,
                                                                              i_prof   => i_prof,
                                                                              i_id_ref => i_id_ref);
            
            ELSE
                l_id_prof_sch_sugg := i_id_prof_sch_sugg;
            END IF;
        
            IF l_id_prof_sch_sugg IS NOT NULL
            THEN
            
                l_result := pk_message.get_message(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_code_mess => pk_ref_constant.g_sm_p1_detail_t039) || ' ' ||
                            pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_prof_sch_sugg);
            END IF;
        
        ELSIF i_prof_profile = pk_ref_constant.g_profile_med_hs
        THEN
            -- prof_triage_name    
            g_error  := 'Call pk_prof_utils.get_name_signature / PROF_ID=' || i_id_prof_triage;
            l_result := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_prof_id => i_id_prof_triage);
        ELSIF i_dt_schedule IS NOT NULL
        THEN
            -- Schedule date
            g_error           := 'ELSE';
            l_dt_schedule_v   := pk_date_utils.dt_chr_tsz(i_lang, i_dt_schedule, i_prof);
            l_hour_schedule_v := pk_date_utils.dt_chr_hour_tsz(i_lang, i_dt_schedule, i_prof);
        
            g_error := 'l_dt_schedule_v=' || l_dt_schedule_v || ' l_hour_schedule_v=' || l_hour_schedule_v;
        
            l_result := '';
            IF l_hour_schedule_v IS NOT NULL
            THEN
                l_result := l_hour_schedule_v || chr(13);
            END IF;
        
            IF l_dt_schedule_v IS NOT NULL
            THEN
                l_result := l_result || l_dt_schedule_v;
            END IF;
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_ref_observations i_id_ref=' || i_id_ref || ' i_flg_status=' || i_flg_status ||
                       ' i_id_prof_status=' || i_id_prof_status || ' / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_ref_observations;

    /**
    * Get referral obs.
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_id_external_request     Referral identifier
    * @param   i_flg_status              Referral status          
    * @param   i_view_clin_data          Clinical data can be viewed? {*} Y - yes, {*} N - no
    *
    * @RETURN  referral obs.
    * @author  Filipe Sousa
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_view_clin_data      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text pk_translation.t_desc_translation;
    BEGIN
        IF i_flg_status IN (pk_ref_constant.g_p1_status_d,
                            pk_ref_constant.g_p1_status_x,
                            pk_ref_constant.g_p1_status_y,
                            pk_ref_constant.g_p1_status_f,
                            pk_ref_constant.g_p1_status_q)
        THEN
            SELECT p1td.text
              INTO l_text
              FROM (SELECT pk_translation.get_translation(i_lang, pk_ref_constant.g_p1_reason_code || t.id_reason_code) text,
                           t.dt_tracking_tstz
                      FROM (SELECT p1t.id_reason_code, p1t.dt_tracking_tstz
                              FROM p1_tracking p1t
                             WHERE p1t.id_external_request = i_id_external_request
                               AND p1t.ext_req_status = i_flg_status
                               AND p1t.flg_type = pk_ref_constant.g_tracking_type_s
                            --AND i_view_clin_data = pk_ref_constant.g_yes
                            ) t
                     ORDER BY t.dt_tracking_tstz DESC) p1td
             WHERE rownum = 1;
        END IF;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**
    * Get referral obs. text
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_id_external_request     Referral identifier
    * @param   i_flg_status              Referral status     
    * @param   i_view_clin_data          Clinical data can be viewed? {*} Y - yes, {*} N - no
    *
    * @RETURN  referral obs. text
    * @author  Filipe Sousa
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_obs_text
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_view_clin_data      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text p1_detail.text%TYPE;
    BEGIN
        IF i_flg_status IN
           (pk_ref_constant.g_p1_status_d, pk_ref_constant.g_p1_status_x, pk_ref_constant.g_p1_status_y)
        THEN
            SELECT p1td.text
              INTO l_text
              FROM (SELECT p1d.text, p1t.dt_tracking_tstz, p1d.dt_insert_tstz
                      FROM p1_tracking p1t
                      LEFT JOIN p1_detail p1d
                        ON (p1d.id_tracking = p1t.id_tracking AND p1d.id_external_request = p1t.id_external_request)
                    -- must be left join to get the last notes (may not exist if there are more than one decline/refusal)
                     WHERE p1t.ext_req_status = i_flg_status
                       AND i_id_external_request = p1t.id_external_request
                       AND p1t.flg_type = pk_ref_constant.g_tracking_type_s
                    --AND i_view_clin_data = pk_ref_constant.g_yes
                     ORDER BY p1t.dt_tracking_tstz DESC, p1d.dt_insert_tstz DESC) p1td
             WHERE rownum = 1;
        END IF;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_referral_obs_text;

    /**
    * Checks if the referral can be canceled
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_ref                     Referral identifier
    * @param   i_flg_status              Referral status
    * @param   i_id_workflow             Referral workflow identifier
    * @param   i_id_profile_template     Professional profile template that is requesting cancelation
    * @param   i_id_functionality        Professional functionality that is requesting cancelation
    * @param   i_id_category             Professional category that is requesting cancelation   
    * @param   i_id_patient              Referral patient identifier
    * @param   i_id_inst_orig            Referral institution origin
    * @param   i_id_inst_dest            Referral institution dest
    * @param   i_id_dep_clin_serv        Referral dep_clin_serv
    * @param   i_id_speciality           Referral speciality (origin)
    * @param   i_flg_type                Referral type
    * @param   i_id_prof_requested       Professional that requested referral   
    * @param   i_id_prof_redirected      Professional to whom the referral was forwarded to   
    * @param   i_decision_urg_level      Urgency level used in triage
    *
    * @value   i_completed               {*} 'Y' - Yes {*} 'N' - No   
    * @value   i_flg_type                {*} 'C' - Appointments
    *                                    {*} 'A' - Lab tests
    *                                    {*} 'I' - Imaging exams
    *                                    {*} 'E' - Other exams
    *                                    {*} 'P' - Procedures
    *                                    {*} 'F' - Physical Medicine and Rehabilitation
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   16-09-2009
    */
    FUNCTION can_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref                 IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        -- workflow data
        i_id_patient         IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE
    ) RETURN VARCHAR2 IS
        l_wf_transition_info table_varchar;
        l_error              t_error_out;
        l_result             VARCHAR2(1 CHAR);
        l_params             VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_ref=' || i_ref || ' i_flg_status=' || i_flg_status || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_profile_template=' || i_id_profile_template || ' i_id_functionality=' || i_id_functionality ||
                    ' i_id_category=' || i_id_category || ' i_id_patient=' || i_id_patient || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_dep_clin_serv=' ||
                    i_id_dep_clin_serv || ' i_id_speciality=' || i_id_speciality || ' i_flg_type=' || i_flg_type ||
                    ' i_id_prof_requested=' || i_id_prof_requested || ' i_id_prof_redirected=' || i_id_prof_redirected ||
                    ' i_id_prof_status=' || i_id_prof_status || ' i_external_sys=' || i_external_sys ||
                    ' i_decision_urg_level=' || i_decision_urg_level;
        g_error  := 'can_cancel / ' || l_params;
        --g_sysdate_tstz := current_timestamp;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error              := 'Calling init_param_tab';
        l_wf_transition_info := init_param_tab(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_ext_req            => i_ref,
                                               i_id_patient         => i_id_patient,
                                               i_id_inst_orig       => i_id_inst_orig,
                                               i_id_inst_dest       => i_id_inst_dest,
                                               i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                               i_id_speciality      => i_id_speciality,
                                               i_flg_type           => i_flg_type,
                                               i_decision_urg_level => i_decision_urg_level,
                                               i_id_prof_requested  => i_id_prof_requested,
                                               i_id_prof_redirected => i_id_prof_redirected,
                                               i_id_prof_status     => i_id_prof_status,
                                               i_external_sys       => i_external_sys,
                                               i_flg_status         => i_flg_status);
    
        -- checking if referral can be canceled
        g_error  := 'Calling pk_workflow.check_transition / ' || l_params || ' PARAM=' ||
                    pk_utils.to_string(l_wf_transition_info);
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => nvl(i_id_workflow,
                                                                              pk_ref_constant.g_wf_pcc_hosp),
                                                 i_id_status_begin     => pk_ref_status.convert_status_n(i_flg_status),
                                                 i_id_status_end       => pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_c),
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_c),
                                                 i_id_category         => i_id_category,
                                                 i_id_profile_template => i_id_profile_template,
                                                 i_id_functionality    => i_id_functionality,
                                                 i_param               => l_wf_transition_info,
                                                 o_flg_available       => l_result,
                                                 o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CAN_CANCEL',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state();
            RETURN pk_ref_constant.g_no;
    END can_cancel;

    /**
    * Checks if the referral can be scheduled
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_ref                     Referral identifier
    * @param   i_flg_status              Referral status
    * @param   i_id_workflow             Referral workflow identifier
    * @param   i_id_profile_template     Professional profile template that is requesting cancelation
    * @param   i_id_functionality        Professional functionality that is requesting cancelation
    * @param   i_id_category             Professional category that is requesting cancelation   
    * @param   i_id_patient              Referral patient identifier
    * @param   i_id_inst_orig            Referral institution origin
    * @param   i_id_inst_dest            Referral institution dest
    * @param   i_id_dep_clin_serv        Referral dep_clin_serv
    * @param   i_id_speciality           Referral speciality (origin)
    * @param   i_flg_type                Referral type
    * @param   i_id_prof_requested       Professional that requested referral   
    * @param   i_id_prof_redirected      Professional to whom the referral was forwarded to   
    * @param   i_decision_urg_level      Urgency level used in triage
    *
    * @value   i_completed               {*} 'Y' - Yes {*} 'N' - No   
    * @value   i_flg_type                {*} 'C' - Appointments
    *                                    {*} 'A' - Lab tests
    *                                    {*} 'I' - Imaging exams
    *                                    {*} 'E' - Other exams
    *                                    {*} 'P' - Procedures
    *                                    {*} 'F' - Physical Medicine and Rehabilitation
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-05-2011
    */
    FUNCTION can_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref                 IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        -- workflow data
        i_id_patient         IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE
    ) RETURN VARCHAR2 IS
        l_wf_transition_info table_varchar;
        l_error              t_error_out;
        l_result             VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'can_schedule / ID_REF=' || i_ref || ' FLG_STATUS=' || i_flg_status || ' WF=' || i_id_workflow ||
                   ' PRF_TEMPL=' || i_id_profile_template || ' FUNC=' || i_id_functionality || ' CAT=' || i_id_category;
        pk_alertlog.log_debug(g_error);
        --g_sysdate_tstz := current_timestamp;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error              := 'Calling init_param_tab';
        l_wf_transition_info := init_param_tab(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_ext_req            => i_ref,
                                               i_id_patient         => i_id_patient,
                                               i_id_inst_orig       => i_id_inst_orig,
                                               i_id_inst_dest       => i_id_inst_dest,
                                               i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                               i_id_speciality      => i_id_speciality,
                                               i_flg_type           => i_flg_type,
                                               i_decision_urg_level => i_decision_urg_level,
                                               i_id_prof_requested  => i_id_prof_requested,
                                               i_id_prof_redirected => i_id_prof_redirected,
                                               i_id_prof_status     => i_id_prof_status,
                                               i_external_sys       => i_external_sys,
                                               i_flg_status         => i_flg_status);
    
        -- checking if referral can be scheduled
        g_error := 'Calling pk_workflow.check_transition / ID_EXT_REQ=' || i_ref || ' WF=' ||
                   nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) || ' BEG=' ||
                   pk_ref_status.convert_status_n(i_flg_status) || ' END=' ||
                   pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_s) || ' ACTION=' ||
                   pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_s) || ' CAT=' || i_id_category ||
                   ' PRF_TEMPL=' || i_id_profile_template || ' FUNC=' || i_id_functionality || ' PARAM=' ||
                   pk_utils.to_string(l_wf_transition_info);
        --pk_alertlog.log_debug(g_error);
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => nvl(i_id_workflow,
                                                                              pk_ref_constant.g_wf_pcc_hosp),
                                                 i_id_status_begin     => pk_ref_status.convert_status_n(i_flg_status),
                                                 i_id_status_end       => pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_s),
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_s),
                                                 i_id_category         => i_id_category,
                                                 i_id_profile_template => i_id_profile_template,
                                                 i_id_functionality    => i_id_functionality,
                                                 i_param               => l_wf_transition_info,
                                                 o_flg_available       => l_result,
                                                 o_error               => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CAN_SCHEDULE',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state();
            RETURN pk_ref_constant.g_no;
    END can_schedule;

    /**
    * chek if the referral can be approved 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ref  referral id
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-05-2012
    */
    FUNCTION can_approve
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref                 IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        -- workflow data
        i_id_patient         IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE
    ) RETURN VARCHAR2 IS
        l_wf_transition_info table_varchar;
        l_error              t_error_out;
        l_result             VARCHAR2(1 CHAR);
        l_params             VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_ref=' || i_ref || ' i_flg_status=' || i_flg_status || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_profile_template=' || i_id_profile_template || ' i_id_functionality=' || i_id_functionality ||
                    ' i_id_category=' || i_id_category || ' i_id_patient=' || i_id_patient || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_dep_clin_serv=' ||
                    i_id_dep_clin_serv || ' i_id_speciality=' || i_id_speciality || ' i_flg_type=' || i_flg_type ||
                    ' i_id_prof_requested=' || i_id_prof_requested || ' i_id_prof_redirected=' || i_id_prof_redirected ||
                    ' i_id_prof_status=' || i_id_prof_status || ' i_external_sys=' || i_external_sys ||
                    ' i_decision_urg_level=' || i_decision_urg_level;
    
        g_error              := 'Calling init_wf_trans_tab / ' || l_params;
        l_wf_transition_info := init_param_tab(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_ext_req            => i_ref,
                                               i_id_patient         => i_id_patient,
                                               i_id_inst_orig       => i_id_inst_orig,
                                               i_id_inst_dest       => i_id_inst_dest,
                                               i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                               i_id_speciality      => i_id_speciality,
                                               i_flg_type           => i_flg_type,
                                               i_decision_urg_level => i_decision_urg_level,
                                               i_id_prof_requested  => i_id_prof_requested,
                                               i_id_prof_redirected => i_id_prof_redirected,
                                               i_id_prof_status     => i_id_prof_status,
                                               i_external_sys       => i_external_sys,
                                               i_flg_status         => i_flg_status);
    
        -- checking if referral can be refused(if we can approve we also can refuse)
        -- id_wf 2 approve status = 'V'
        -- id_wf 28 approve status = 'N'
        g_error  := 'Calling pk_workflow.check_transition / ' || l_params;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => nvl(i_id_workflow,
                                                                              pk_ref_constant.g_wf_pcc_hosp),
                                                 i_id_status_begin     => pk_ref_status.convert_status_n(i_flg_status),
                                                 i_id_status_end       => pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_h),
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(pk_ref_constant.g_p1_status_h),
                                                 i_id_category         => i_id_category,
                                                 i_id_profile_template => i_id_profile_template,
                                                 i_id_functionality    => i_id_functionality,
                                                 i_param               => l_wf_transition_info,
                                                 o_flg_available       => l_result,
                                                 o_error               => l_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CAN_APPROVE',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state();
            RETURN pk_ref_constant.g_no;
    END can_approve;

    /**
    * Get id content just for p1_external_request.flg_type = 'C'
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_dcs            Values to populate multichoice
    * @param   id_prof_sch      Prof Schedule
    *    
    * @RETURN  Id Content 
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-01-2010
    */
    FUNCTION get_content
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        id_prof_sch IN professional.id_professional%TYPE
    ) RETURN appointment.id_appointment%TYPE IS
        l_ref_first_appoint_spec VARCHAR2(1 CHAR);
        l_ref_schedule_3         VARCHAR2(1 CHAR);
        l_var                    VARCHAR2(1 CHAR);
        l_ret                    appointment.id_appointment%TYPE;
        l_flg_proceed            VARCHAR2(4000);
        l_flg_show               VARCHAR2(4000);
        l_msg_title              VARCHAR2(4000);
        l_msg                    VARCHAR2(4000);
        l_button                 VARCHAR2(4000);
        l_error                  t_error_out;
    BEGIN
        l_ref_schedule_3 := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                            i_id_sys_config => pk_ref_constant.g_scheduler3_installed),
                                pk_ref_constant.g_no);
    
        g_error := 'SCHEDULE_3 AVAILABLE=' || l_ref_schedule_3 || ' i_dcs=' || i_dcs || ' id_prof_sch=' || id_prof_sch;
        IF l_ref_schedule_3 = pk_ref_constant.g_no
        THEN
            l_ret := NULL;
        ELSE
            l_ref_first_appoint_spec := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                        i_id_sys_config => pk_ref_constant.g_ref_first_appoint_spec),
                                            pk_ref_constant.g_no);
        
            g_error := 'REFERRAL FIRST APPOINT SPEC=' || l_ref_first_appoint_spec;
            IF l_ref_first_appoint_spec = pk_ref_constant.g_no
            THEN
                l_var := pk_ref_constant.g_yes;
            ELSE
                IF id_prof_sch IS NULL
                THEN
                    l_var := pk_ref_constant.g_no;
                ELSE
                    l_var := pk_ref_constant.g_yes;
                END IF;
            END IF;
        
            g_error  := 'Call pk_schedule_api_downstream.get_id_content / i_dcs=' || i_dcs || ' id_prof_sch=' ||
                        id_prof_sch || ' i_flg_prof=' || l_var;
            g_retval := pk_schedule_api_downstream.get_id_content(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_dep_type       => 'C',
                                                                  i_flg_occurr     => 'F',
                                                                  i_id_dcs         => i_dcs,
                                                                  i_flg_prof       => l_var,
                                                                  i_domain_p1_type => 'C',
                                                                  o_id_content     => l_ret,
                                                                  o_flg_proceed    => l_flg_proceed,
                                                                  o_flg_show       => l_flg_show,
                                                                  o_msg_title      => l_msg_title,
                                                                  o_msg            => l_msg,
                                                                  o_button         => l_button,
                                                                  o_error          => l_error);
        
        END IF;
    
        RETURN l_ret;
    END get_content;

    /**
    * Get Id Prof destination
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_id_ref         Referral Id
    * @param   i_status         referral status
    *    
    * @RETURN  id_professional
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-04-2010
    */
    FUNCTION get_prof_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_status IN p1_external_request.flg_status%TYPE
    ) RETURN professional.id_professional%TYPE IS
        l_ret professional.id_professional%TYPE;
    BEGIN
        SELECT t.id_prof_dest
          INTO l_ret
        
          FROM (SELECT *
                  FROM p1_tracking
                 WHERE id_external_request = i_id_ref
                   AND ext_req_status = i_status
                   AND flg_type = pk_ref_constant.g_tracking_type_s
                 ORDER BY id_tracking DESC) t
         WHERE rownum = 1;
    
        RETURN l_ret;
    END get_prof_status;

    /**
    * Gets referral detail
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_ext_req        Referral identifier
    * @param   i_status_detail     Detail status returned    
    * @param   o_patient           Patient general data
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
    * @param   o_can_cancel        'Y' if the request can be canceled, 'N' otherwise
    * @param   o_ref_orig_data     Referral orig data   
    * @param   o_fields_rank       Cursor with field names and ranks
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_status_detail     {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @value   o_can_cancel        {*} 'Y' if the request can be canceled {*} 'N' otherwise   
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   03-11-2006
    */
    FUNCTION get_referral
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_status_detail IN p1_detail.flg_status%TYPE,
        o_patient       OUT pk_types.cursor_type,
        --o_detail           OUT pk_ref_core.row_detail_cur,
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
        o_ref_comments     OUT pk_types.cursor_type,
        o_fields_rank      OUT pk_types.cursor_type,
        o_med_dest_data    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params  VARCHAR2(1000 CHAR);
        l_my_data t_rec_prof_data;
        -- sys_configs
        l_module sys_config.value%TYPE;
    
        l_exr_row        p1_external_request%ROWTYPE;
        l_flg_status_n   wf_status.id_status%TYPE;
        o_track          table_number;
        l_view_clin_data VARCHAR2(1 CHAR);
        l_wf_param       table_varchar;
        l_track_tab      table_number;
    
        l_priority_level sys_config.desc_sys_config%TYPE;
        --l_desc_dom_ref_prio sys_config.desc_sys_config%TYPE;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ext_req || ' i_status_detail=' ||
                    i_status_detail;
        g_error  := 'Init get_referral / ' || l_params;
        o_track  := table_number();
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'Call pk_sysconfig.get_config / ' || l_params || ' / SYS_CONFIG=' ||
                            pk_ref_constant.g_sc_ref_module;
        l_module         := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
        l_priority_level := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                        i_id_sys_config => pk_ref_constant.g_ref_priority_level);
        --l_desc_dom_ref_prio := pk_ref_constant.g_ref_prio || '.' || l_priority_level;
    
        ----------------------
        -- FUNC
        ----------------------
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => l_exr_row.id_dep_clin_serv,
                                  o_prof_data => l_my_data,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if this professional can view clinical data
        g_error          := 'Call pk_ref_utils.can_view_clinical_data / ' || l_params;
        l_view_clin_data := pk_ref_utils.can_view_clinical_data(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_cat               => l_my_data.flg_category,
                                                                i_prof_profile      => l_my_data.id_profile_template,
                                                                i_id_prof_requested => l_exr_row.id_prof_requested,
                                                                i_id_workflow       => l_exr_row.id_workflow);
    
        g_error        := 'Calling pk_ref_status.convert_status_n / ' || l_params || ' / FLG_STATUS=' ||
                          l_exr_row.flg_status;
        l_flg_status_n := pk_ref_status.convert_status_n(l_exr_row.flg_status);
    
        g_error    := 'Calling init_param_tab / ' || l_params;
        l_wf_param := init_param_tab(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_ext_req            => l_exr_row.id_external_request,
                                     i_id_patient         => l_exr_row.id_patient,
                                     i_id_inst_orig       => l_exr_row.id_inst_orig,
                                     i_id_inst_dest       => l_exr_row.id_inst_dest,
                                     i_id_dep_clin_serv   => l_exr_row.id_dep_clin_serv,
                                     i_id_speciality      => l_exr_row.id_speciality,
                                     i_flg_type           => l_exr_row.flg_type,
                                     i_decision_urg_level => l_exr_row.decision_urg_level,
                                     i_id_prof_requested  => l_exr_row.id_prof_requested,
                                     i_id_prof_redirected => l_exr_row.id_prof_redirected,
                                     i_id_prof_status     => l_exr_row.id_prof_status,
                                     i_external_sys       => l_exr_row.id_external_sys,
                                     i_location           => pk_ref_constant.g_location_detail,
                                     i_flg_status         => l_exr_row.flg_status);
    
        l_params := l_params || 'ID_WF=' || l_exr_row.id_workflow || ' FLG_STATUS=' || l_exr_row.flg_status ||
                    ' ID_CATEGORY=' || l_my_data.id_category || ' ID_PRF_TEMPL=' || l_my_data.id_profile_template ||
                    ' ID_FUNC=' || l_my_data.id_functionality || ' PARAM=' || pk_utils.to_string(l_wf_param);
    
        -- checking if referral can be canceled
        g_error  := 'Calling pk_workflow.check_transition / ' || l_params || ' / STS_BEGIN=' || l_flg_status_n ||
                    ' STS_END=' || pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_c) || ' ACTION=' ||
                    pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_c);
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => nvl(l_exr_row.id_workflow,
                                                                              pk_ref_constant.g_wf_pcc_hosp),
                                                 i_id_status_begin     => l_flg_status_n,
                                                 i_id_status_end       => pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_c),
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_c),
                                                 i_id_category         => l_my_data.id_category,
                                                 i_id_profile_template => l_my_data.id_profile_template,
                                                 i_id_functionality    => l_my_data.id_functionality,
                                                 i_param               => l_wf_param,
                                                 o_flg_available       => o_can_cancel,
                                                 o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- o_patient
        g_error  := 'Call pk_ref_list.get_referral_patient / ' || l_params;
        g_retval := pk_ref_list.get_referral_patient(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_patient   => l_exr_row.id_patient,
                                                     i_id_inst_orig => l_exr_row.id_inst_orig,
                                                     o_patient      => o_patient,
                                                     o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- o_detail
        g_error  := 'Call pk_ref_list.get_referral_detail / ' || l_params;
        g_retval := pk_ref_list.get_referral_detail(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_prof_data      => l_my_data,
                                                    i_ref_row        => l_exr_row,
                                                    i_view_clin_data => l_view_clin_data,
                                                    o_detail         => o_detail,
                                                    o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_retval := pk_ref_list.get_referral_med_dest_data(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_id_ref        => l_exr_row.id_external_request,
                                                           o_med_dest_data => o_med_dest_data,
                                                           o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- o_text
        g_error  := 'Call pk_ref_list.get_referral_text / ' || l_params;
        g_retval := pk_ref_list.get_referral_text(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_ref         => l_exr_row.id_external_request,
                                                  i_view_clin_data => l_view_clin_data,
                                                  i_flg_status     => i_status_detail,
                                                  o_text           => o_text,
                                                  o_error          => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_view_clin_data = pk_ref_constant.g_yes
        THEN
            -- o_problem
            g_error  := 'Call pk_ref_list.get_referral_diagnosis / ' || l_params || ' / ' ||
                        pk_ref_constant.g_exr_diag_type_p;
            g_retval := pk_ref_list.get_referral_diagnosis(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_id_ref    => i_id_ext_req,
                                                           i_flg_type  => pk_ref_constant.g_exr_diag_type_p,
                                                           o_diagnosis => o_problem,
                                                           o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- o_diagnosis
            g_error  := 'Call pk_ref_list.get_referral_diagnosis / ' || l_params || ' / ' ||
                        pk_ref_constant.g_exr_diag_type_d;
            g_retval := pk_ref_list.get_referral_diagnosis(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_id_ref    => i_id_ext_req,
                                                           i_flg_type  => pk_ref_constant.g_exr_diag_type_d,
                                                           o_diagnosis => o_diagnosis,
                                                           o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- o_answer
            IF l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_w, pk_ref_constant.g_p1_status_k)
            THEN
                g_error  := 'Call pk_ref_list.get_referral_answer / ' || l_params;
                g_retval := pk_ref_list.get_referral_answer(i_lang   => i_lang,
                                                            i_prof   => i_prof,
                                                            i_id_ref => i_id_ext_req,
                                                            o_answer => o_answer,
                                                            o_error  => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            ELSE
                pk_types.open_my_cursor(o_answer);
            END IF;
        
            -- o_mcdt cursor filled below        
        ELSE
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_answer);
        END IF;
    
        -- Getting o_mcdt    
        g_error := 'View clinica data / ' || l_params || ' / l_view_clin_data=' || l_view_clin_data;
        IF l_view_clin_data = pk_ref_constant.g_yes
           OR l_my_data.flg_category = pk_ref_constant.g_technician -- ALERT-123316 because of ALERT-910
        THEN
            g_error  := g_error || ' / Call pk_ref_list.get_referral_mcdt';
            g_retval := pk_ref_list.get_referral_mcdt(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_id_ref   => l_exr_row.id_external_request,
                                                      i_ref_type => l_exr_row.flg_type,
                                                      o_mcdt     => o_mcdt,
                                                      o_error    => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_answer);
        END IF;
    
        -- o_needs
        g_error  := 'Call pk_ref_list.get_referral_taskdone / ' || l_params;
        g_retval := pk_ref_list.get_referral_taskdone(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_id_ref    => i_id_ext_req,
                                                      i_flg_type  => pk_ref_constant.g_p1_task_done_type_s,
                                                      o_task_done => o_needs,
                                                      o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- o_info
        g_error  := 'Call pk_ref_list.get_referral_taskdone / ' || l_params;
        g_retval := pk_ref_list.get_referral_taskdone(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_id_ref    => i_id_ext_req,
                                                      i_flg_type  => pk_ref_constant.g_p1_task_done_type_c,
                                                      o_task_done => o_info,
                                                      o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'MODULE =' || l_module || ' / ' || l_params;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- circle
                g_error  := 'Call pk_ref_module.get_referral_circle / ' || l_params;
                g_retval := pk_ref_module.get_referral_circle(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_prof_data        => l_my_data,
                                                              i_ref_row          => l_exr_row,
                                                              o_notes_status     => o_notes_status,
                                                              o_notes_status_det => o_notes_status_det,
                                                              o_error            => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- default module            
                g_error  := 'Call pk_ref_module.get_referral_circle / ' || l_params;
                g_retval := pk_ref_module.get_referral_generic(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_prof_data          => l_my_data,
                                                               i_ref_row            => l_exr_row,
                                                               i_can_view_clin_data => l_view_clin_data,
                                                               o_notes_status       => o_notes_status,
                                                               o_notes_status_det   => o_notes_status_det,
                                                               o_error              => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
        END CASE;
    
        -- If referral status is answer and is the preofessional thar requested the referral, than change to status Read
        IF l_exr_row.flg_status = pk_ref_constant.g_p1_status_w
           AND l_exr_row.id_prof_requested = i_prof.id
        THEN
            g_error  := 'Calling process_transition / ' || l_params || ' / ACTION=' || pk_ref_constant.g_ref_action_k;
            g_retval := process_transition2(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_data  => l_my_data,
                                            i_ref_row    => l_exr_row,
                                            i_action     => pk_ref_constant.g_ref_action_k,
                                            i_status_end => NULL, -- to be calculated inside this function
                                            i_date       => NULL,
                                            io_param     => l_wf_param,
                                            io_track     => o_track,
                                            o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        -- Register that professional has read the referral
        g_error  := 'Calling pk_ref_status.set_ref_read / ' || l_params;
        g_retval := pk_ref_status.set_ref_read(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_prof_data => l_my_data,
                                               i_ref_row   => l_exr_row,
                                               i_date      => NULL,
                                               io_param    => l_wf_param,
                                               o_track     => l_track_tab,
                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_track := o_track MULTISET UNION l_track_tab;
    
        g_error  := 'Calling pk_ref_list.get_referral_orig_data / ' || l_params;
        g_retval := pk_ref_list.get_referral_orig_data(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_ref        => l_exr_row.id_external_request,
                                                       o_ref_orig_data => o_ref_orig_data,
                                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_list.get_ref_comments / ' || l_params;
        g_retval := pk_ref_list.get_ref_comments(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_prof_data    => l_my_data,
                                                 i_ref_row      => l_exr_row,
                                                 o_ref_comments => o_ref_comments,
                                                 o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_list.get_fields_rank / ' || l_params;
        g_retval := pk_ref_list.get_fields_rank(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                o_fields_rank => o_fields_rank,
                                                o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_patient);
            pk_types.open_my_cursor(o_text);
            --pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            pk_types.open_my_cursor(o_ref_orig_data);
            pk_types.open_my_cursor(o_ref_comments);
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
            pk_types.open_my_cursor(o_patient);
            pk_types.open_my_cursor(o_text);
            --pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            pk_types.open_my_cursor(o_ref_orig_data);
            pk_types.open_my_cursor(o_ref_comments);
            RETURN FALSE;
    END get_referral;

    /**
    * Gets referral cancellation request data to be shown in the brief screen
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional id, institution and software
    * @param   I_ID_REF         Referral identifier
    * @param   I_ID_ACTION      Action identifier. This Parameter will be used to return o_c_req_answ
    * @param   O_REF_DATA       Referral data nedded for the cancellation request brief screen
    * @param   O_C_REQ_DATA     Cancellation request data
    * @param   O_C_REQ_ANSW     Cancellation request answer
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-09-2010
    */
    FUNCTION get_referral_req_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_id_action  IN wf_action.id_action%TYPE,
        o_ref_data   OUT pk_types.cursor_type,
        o_c_req_data OUT pk_types.cursor_type,
        o_c_req_answ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        -- config
        l_answer_default VARCHAR2(1 CHAR);
    
        l_ref_row   p1_external_request%ROWTYPE;
        l_prof_data t_rec_prof_data;
        l_track_row p1_tracking%ROWTYPE;
    
        l_id_workflow        p1_external_request.id_workflow%TYPE;
        l_status_n           wf_status.id_status%TYPE;
        l_wf_transition_info table_varchar;
        l_params             VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------     
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_id_action=' ||
                    i_id_action;
        g_error  := 'Init get_referral_req_cancel / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'Configs / ' || l_params;
        l_answer_default := pk_sysconfig.get_config(pk_ref_constant.g_sc_cancel_req_answ, i_prof);
    
        ----------------------
        -- FUNC
        ----------------------        
    
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
    
        l_params := l_params || ' WF=' || l_ref_row.id_workflow || ' FLG_STATUS=' || l_ref_row.flg_status || ' DCS=' ||
                    l_ref_row.id_dep_clin_serv;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => l_ref_row.id_dep_clin_serv,
                                  o_prof_data => l_prof_data,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ID_CAT=' || l_prof_data.id_category || ' ID_PROF_TEMPL=' ||
                    l_prof_data.id_profile_template || ' ID_FUNC=' || l_prof_data.id_functionality;
    
        g_error              := 'Calling init_param_tab / ' || l_params;
        l_wf_transition_info := init_param_tab(i_lang               => i_lang,
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
    
        -- getting actual referral status
        g_error  := 'Call pk_ref_utils.get_status_data / ' || l_params;
        g_retval := pk_ref_utils.get_cur_status_data(i_lang   => i_lang,
                                                     i_prof   => i_prof,
                                                     i_id_ref => i_id_ref,
                                                     o_data   => l_track_row,
                                                     o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_list.get_referral_detail_short / ' || l_params;
        g_retval := pk_ref_list.get_referral_detail_short(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_prof_data => l_prof_data,
                                                          i_ref_row   => l_ref_row,
                                                          i_param     => l_wf_transition_info,
                                                          o_ref_data  => o_ref_data,
                                                          o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_c_req_data / ID_TRACK=' || l_track_row.id_tracking || ' / ' || l_params;
        OPEN o_c_req_data FOR
            SELECT pk_translation.get_translation(i_lang, 'P1_REASON_CODE.CODE_REASON.' || l_track_row.id_reason_code) reason_desc,
                   (SELECT text
                      FROM p1_detail d
                     WHERE d.id_external_request = l_track_row.id_external_request
                       AND d.id_tracking = l_track_row.id_tracking
                       AND d.flg_type = pk_ref_constant.g_detail_type_req_can) notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_track_row.dt_tracking_tstz, i_prof) dt_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, l_track_row.id_professional) prof_status
              FROM dual;
    
        IF i_id_action IS NOT NULL
        THEN
        
            l_id_workflow := nvl(l_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp);
            l_status_n    := pk_ref_status.convert_status_n(i_status => l_ref_row.flg_status);
        
            -- getting valid transitions for this action
            g_error  := 'Call pk_ref_list.get_trans_from_action / ' || l_params;
            g_retval := pk_ref_list.get_trans_from_action(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_prof_data       => l_prof_data,
                                                          i_id_action       => i_id_action,
                                                          i_id_workflow     => l_id_workflow,
                                                          i_id_status_begin => l_status_n,
                                                          i_param           => l_wf_transition_info,
                                                          i_value_default   => l_answer_default,
                                                          o_transitions     => o_c_req_answ,
                                                          o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            g_error := 'ACTION IS NULL / ' || l_params;
            pk_alertlog.log_debug(g_error);
            pk_types.open_my_cursor(o_c_req_answ);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_ref_data);
            pk_types.open_my_cursor(o_c_req_data);
            pk_types.open_my_cursor(o_c_req_answ);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_REQ_CANCEL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ref_data);
            pk_types.open_my_cursor(o_c_req_data);
            pk_types.open_my_cursor(o_c_req_answ);
            RETURN FALSE;
    END get_referral_req_cancel;

    /**
    * Insert, Update or/and Cancel p1 detail records
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_ext_req       Request ID
    * @param   i_prof          Professional, institution and software ids
    * @param   i_detail        P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_ext_req_track Tracking ID
    * @param   i_date          Operation date   
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   06-01-2009
    * Notes:   - id_detail null, text not null, flg=I: inserts an active detail record
    *          - id_detail not null, flg=C: cancels detail record id_detail
    *          - id_detail null, flg=C: inserts a canceled detail record
    *          - id_detail not null, flg=O: updates detail_record id_detail (Outdated)
    *          - id_detail null, flg=O: inserts an outdated detail record   
    *          - id_detail not null, flg=D: deletes detail record id_detail from db (in case text is null)
    *          - id_detail not null, text not null, flg=U: updates detail_record id_detail (updates text and dt_insert_tstz only)     
    */
    FUNCTION set_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_prof          IN profissional,
        i_detail        IN table_table_varchar,
        i_ext_req_track IN p1_tracking.id_tracking%TYPE,
        i_date          IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_detail_row p1_detail%ROWTYPE;
        l_var        p1_detail.id_detail%TYPE;
        l_params     VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_ext_req=' || i_ext_req || ' i_ext_req_track=' || i_ext_req_track;
        g_error  := 'Init set_detail / ' || l_params;
        --g_sysdate_tstz := nvl(i_date, current_timestamp);
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
    
        g_error := 'LOOP i_detail / ' || l_params;
        FOR i IN 1 .. i_detail.count
        LOOP
            IF i_detail(i) IS NOT NULL
            THEN
            
                CASE i_detail(i) (4)
                    WHEN pk_ref_constant.g_detail_flg_i THEN
                        -- id_detail null, text not null, flg=I: inserts an active detail record
                    
                        IF i_detail(i) (1) IS NULL -- id_detail
                           AND i_detail(i) (3) IS NOT NULL -- text
                        THEN
                        
                            g_error      := 'Clean l_detail_row 2 / ' || l_params;
                            l_detail_row := NULL;
                        
                            g_error                          := 'INSERT detail a / ' || l_params;
                            l_detail_row.id_external_request := i_ext_req;
                            l_detail_row.text                := i_detail(i) (3); -- text
                            l_detail_row.dt_insert_tstz      := g_sysdate_tstz;
                            l_detail_row.flg_type            := i_detail(i) (2); -- flg_type
                            l_detail_row.id_professional     := i_prof.id;
                            l_detail_row.id_institution      := i_prof.institution;
                            l_detail_row.id_tracking         := i_ext_req_track;
                            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
                            l_detail_row.id_group            := i_detail(i) (5); -- id_group                    
                        
                            g_error  := 'Calling pk_ref_api.set_p1_detail 2 / ' || l_params;
                            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_p1_detail => l_detail_row,
                                                                 o_id_detail => l_var,
                                                                 o_error     => o_error);
                        
                            IF NOT g_retval
                            THEN
                                RAISE g_exception_np;
                            END IF;
                        
                        ELSE
                        
                            g_error := 'Cannot insert detail ' || i_detail(i) (1) || ' / ' || l_params;
                            RAISE g_exception;
                        END IF;
                    
                    WHEN pk_ref_constant.g_detail_flg_c THEN
                        -- id_detail not null, flg=C: cancels detail record id_detail
                    
                        IF i_detail(i) (1) IS NOT NULL
                        THEN
                        
                            g_error := 'Cancel detail ' || i_detail(i) (1) || ' / ' || l_params;
                            UPDATE p1_detail
                               SET flg_status = pk_ref_constant.g_detail_status_c
                             WHERE id_detail = i_detail(i) (1)
                               AND flg_status = pk_ref_constant.g_detail_status_a;
                        
                        ELSE
                            -- id_detail null, flg=C: inserts a canceled detail record
                        
                            g_error      := 'Clean l_detail_row 4 / ' || l_params;
                            l_detail_row := NULL;
                        
                            g_error                          := 'INSERT detail c / ' || l_params;
                            l_detail_row.id_external_request := i_ext_req;
                            l_detail_row.text                := i_detail(i) (3); -- text
                            l_detail_row.dt_insert_tstz      := g_sysdate_tstz;
                            l_detail_row.flg_type            := i_detail(i) (2); -- flg_type
                            l_detail_row.id_professional     := i_prof.id;
                            l_detail_row.id_institution      := i_prof.institution;
                            l_detail_row.id_tracking         := i_ext_req_track;
                            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_c;
                            l_detail_row.id_group            := i_detail(i) (5); -- id_group                    
                        
                            g_error  := 'Calling pk_ref_api.set_p1_detail 4 / ' || l_params;
                            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_p1_detail => l_detail_row,
                                                                 o_id_detail => l_var,
                                                                 o_error     => o_error);
                        
                            IF NOT g_retval
                            THEN
                                RAISE g_exception_np;
                            END IF;
                        
                        END IF;
                    
                    WHEN pk_ref_constant.g_detail_flg_o THEN
                        -- id_detail not null, flg=O: updates detail_record id_detail (Outdated)
                        IF i_detail(i) (1) IS NOT NULL
                        THEN
                        
                            g_error := 'Outdating detail ' || i_detail(i) (1) || ' / ' || l_params;
                            UPDATE p1_detail
                               SET flg_status = pk_ref_constant.g_detail_status_o
                             WHERE id_detail = i_detail(i) (1)
                               AND flg_status = pk_ref_constant.g_detail_status_a;
                        
                        ELSE
                        
                            g_error      := 'Clean l_detail_row 6 / ' || l_params;
                            l_detail_row := NULL;
                        
                            g_error                          := 'INSERT detail O / ' || l_params;
                            l_detail_row.id_external_request := i_ext_req;
                            l_detail_row.text                := i_detail(i) (3); -- text
                            l_detail_row.dt_insert_tstz      := g_sysdate_tstz;
                            l_detail_row.flg_type            := i_detail(i) (2); -- flg_type
                            l_detail_row.id_professional     := i_prof.id;
                            l_detail_row.id_institution      := i_prof.institution;
                            l_detail_row.id_tracking         := i_ext_req_track;
                            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_o;
                            l_detail_row.id_group            := i_detail(i) (5); -- id_group                    
                        
                            g_error  := 'Calling pk_ref_api.set_p1_detail 6 / ' || l_params;
                            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_p1_detail => l_detail_row,
                                                                 o_id_detail => l_var,
                                                                 o_error     => o_error);
                        
                            IF NOT g_retval
                            THEN
                                RAISE g_exception_np;
                            END IF;
                        
                        END IF;
                    
                    WHEN pk_ref_constant.g_detail_flg_d THEN
                        -- id_detail not null, flg=D: deletes detail record id_detail from db (in case text is null)
                    
                        IF i_detail(i) (1) IS NOT NULL
                        THEN
                        
                            g_error := 'Deleting detail ' || i_detail(i) (1) || ' / ' || l_params;
                            DELETE FROM p1_detail
                             WHERE id_detail = i_detail(i) (1);
                        
                        ELSE
                            g_error := 'Cannot delete detail ' || i_detail(i) (1) || ' / ' || l_params;
                            RAISE g_exception;
                        END IF;
                    
                    WHEN pk_ref_constant.g_detail_flg_u THEN
                        -- id_detail not null, text not null, flg=U: updates detail_record id_detail (updates text and dt_insert_tstz only)     
                    
                        IF i_detail(i) (1) IS NOT NULL -- id_detail
                           AND i_detail(i) (3) IS NOT NULL -- text
                        THEN
                        
                            g_error := 'UPDATE detail ' || i_detail(i) (1) || ' / ' || l_params;
                            UPDATE p1_detail
                               SET text           = i_detail(i) (3), -- text                               
                                   dt_insert_tstz = g_sysdate_tstz
                             WHERE id_detail = i_detail(i) (1)
                               AND flg_status = pk_ref_constant.g_detail_status_a;
                        
                        ELSE
                            g_error := 'Cannot update detail ' || i_detail(i) (1) || ' / ' || l_params;
                            RAISE g_exception;
                        END IF;
                    
                    ELSE
                        g_error := 'CASE NOT FOUND ' || i_detail(i) (4) || ' / ' || l_params;
                        RAISE g_exception;
                END CASE;
            
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
                                              i_function => 'SET_DETAIL',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_detail;

    /**
    * Verificar se os dados obrigat½rios do utente est’o preenchidos
    *
    * @param I_LANG         Lingua registada como preferencia do profissional
    * @param I_PROF         Profissional q regista
    * @param I_PAT          Id do paciente
    * @param O_ERROR        Erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    */
    FUNCTION check_mandatory_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_pat    IN patient.id_patient%TYPE,
        i_id_ref IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sc_multi_instit VARCHAR2(1 CHAR);
    
        CURSOR c_adt_pt(i_id_hp IN pat_health_plan.id_health_plan%TYPE) IS
            SELECT v.name,
                   v.dt_birth,
                   v.gender,
                   v.address_line1          address,
                   v.location,
                   v.postal_code            zip_code,
                   v.id_country_address,
                   pha.num_health_plan,
                   v.flg_sns_unknown_reason,
                   v.mobile_number,
                   v.phone_number
              FROM v_mandatoryfields v
              LEFT JOIN v_pat_health_plan pha
                ON (pha.id_patient = v.id_patient AND pha.id_institution = 0 AND
                   pha.flg_status = pk_ref_constant.g_active AND pha.id_health_plan = i_id_hp)
             WHERE v.id_patient = i_pat
             ORDER BY v.flg_main_address DESC, v.id_contact_entity;
    
        CURSOR c_adt_cl IS
            SELECT v.name,
                   v.middle_name,
                   v.last_name,
                   v.dt_birth,
                   v.gender,
                   v.run_number,
                   v.id_city,
                   v.id_comuna,
                   v.flg_address_type,
                   v.id_region
              FROM v_mandatoryfields v
             WHERE v.id_patient = i_pat
             ORDER BY v.flg_main_address DESC, v.id_contact_entity;
    
        CURSOR c_adt_mx IS
            SELECT v.first_name, -- Nombres
                   v.last_name, -- Primer apellido
                   v.dt_birth, -- Fecha de nacimiento
                   v.gender, -- Sexo
                   v.id_place_of_birth, -- Estado (nacimiento)
                   v.id_country_address, -- Pais (nacimiento) -- todo: rever
                   v.social_security_number, -- CURP
                   v.flg_ssn_status, -- Cuenta con CURP
                   v.address_line1, -- Direccion
                   v.door_number, -- Numero exterior                         
                   v.location, -- Colonia
                   v.postal_code, -- Codigo Postal
                   v.id_country, -- Pais (Direccion)
                   v.first_level, -- Estado
                   v.second_level, -- Municipio
                   v.third_level -- Localidade
              FROM v_mandatoryfields v
             WHERE v.id_patient = i_pat
             ORDER BY v.flg_main_address DESC, v.id_contact_entity;
    
        CURSOR c_adt_other IS
            SELECT pat.name, pat.dt_birth, pat.gender
              FROM patient pat
             WHERE pat.id_patient = i_pat;
    
        l_pat patient%ROWTYPE;
    
        l_adt_pt    c_adt_pt%ROWTYPE;
        l_adt_cl    c_adt_cl%ROWTYPE;
        l_adt_mx    c_adt_mx%ROWTYPE;
        l_adt_other c_adt_other%ROWTYPE;
    
        l_inst_mk market.id_market%TYPE;
    
        l_country_mx CONSTANT country.id_country%TYPE := 484;
    
        l_id_hp   health_plan.id_health_plan%TYPE;
        l_flg_aux VARCHAR2(1 CHAR);
    
        l_params VARCHAR2(1000 CHAR);
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat;
        g_error  := 'Init check_mandatory_data / ' || l_params;
    
        ----------------------
        -- CONFIG
        ----------------------
        l_sc_multi_instit := nvl(pk_sysconfig.get_config(pk_ref_constant.g_sc_multi_institution, i_prof),
                                 pk_ref_constant.g_no);
        l_inst_mk         := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        l_params            := l_params || ' sc_multi_instit=' || l_sc_multi_instit || ' l_inst_mk=' || l_inst_mk;
        l_pat.flg_migration := 'A';
    
        g_error := l_params;
        IF pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof) = pk_ref_constant.g_sc_ref_module_gpportal
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := l_params;
        IF l_inst_mk = pk_ref_constant.g_market_pt -- PT ACSS
        THEN
            l_id_hp := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
        
            g_error := 'OPEN c_adt_pt(' || l_id_hp || ') / ' || l_params;
            OPEN c_adt_pt(l_id_hp);
            FETCH c_adt_pt
                INTO l_adt_pt.name,
                     l_adt_pt.dt_birth,
                     l_adt_pt.gender,
                     l_adt_pt.address,
                     l_adt_pt.location,
                     l_adt_pt.zip_code,
                     l_adt_pt.id_country_address,
                     l_adt_pt.num_health_plan,
                     l_adt_pt.flg_sns_unknown_reason,
                     l_adt_pt.mobile_number,
                     l_adt_pt.phone_number;
            CLOSE c_adt_pt;
        
            IF l_adt_pt.name IS NULL
            THEN
                g_error := pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'NAME', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.gender IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'GENDER', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.dt_birth IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'DT_BIRTH', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.address IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'ADDRESS', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.location IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'LOCATION', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.zip_code IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'ZIP_CODE', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.id_country_address IS NULL
            THEN
                g_error := g_error || '; ' ||
                           pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'COUNTRY_ADDRESS', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_pt.num_health_plan IS NULL
                  AND l_adt_pt.flg_sns_unknown_reason = 'D' -- when this flag is D the health plan is mandatory
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'SNS', i_lang) || ' ';
                RAISE g_exception_np;
                -- mobile_number or phone_number
            ELSIF l_adt_pt.mobile_number IS NULL
                  AND l_adt_pt.phone_number IS NULL
            THEN
                IF i_id_ref IS NOT NULL -- this is because of the existing referrals
                THEN
                    -- check if the referral is being issued for the first time
                    l_flg_aux := pk_ref_status.check_ref_issued_once(i_lang   => i_lang,
                                                                     i_prof   => i_prof,
                                                                     i_id_ref => i_id_ref);
                
                END IF;
            
                pk_alertlog.log_error('i_id_ref=' || i_id_ref || ' l_flg_aux=' || l_flg_aux); -- todo: remover
                IF i_id_ref IS NULL -- when creating the referral from external systems, this validation is done before the referral is created or when updating patient data
                   OR l_flg_aux = pk_ref_constant.g_no
                THEN
                    -- referral has never been issued before
                    g_error := g_error || '; ' ||
                               pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'CONTACT_NUMBER', i_lang) || ' ';
                    RAISE g_exception_np;
                END IF;
            ELSE
                RETURN TRUE;
            END IF;
        
        ELSIF l_inst_mk = pk_ref_constant.g_market_cl -- CL SSMN
        THEN
            g_error := 'OPEN c_adt_cl / ' || l_params;
            OPEN c_adt_cl;
            FETCH c_adt_cl
                INTO l_adt_cl.name,
                     l_adt_cl.middle_name,
                     l_adt_cl.last_name,
                     l_adt_cl.dt_birth,
                     l_adt_cl.gender,
                     l_adt_cl.run_number,
                     l_adt_cl.id_city,
                     l_adt_cl.id_comuna,
                     l_adt_cl.flg_address_type,
                     l_adt_cl.id_region;
            CLOSE c_adt_cl;
        
            IF l_adt_cl.name IS NULL
            THEN
                g_error := pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'NAME', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_cl.middle_name IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'NAME', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_cl.last_name IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'NAME', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_cl.dt_birth IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'DT_BIRTH', i_lang) || ' ';
                RAISE g_exception_np;
            
            ELSIF l_adt_cl.gender IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'GENDER', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_cl.run_number IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'RUN_NUMBER', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_cl.id_city IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'ID_CITY', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_cl.id_comuna IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'ID_COMUNA', i_lang) || ' ';
                RAISE g_exception_np;
            
            ELSIF l_adt_cl.flg_address_type IS NULL
            THEN
                g_error := g_error || '; ' ||
                           pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'FLG_ADDRESS_TYPE', i_lang) || ' ';
                RAISE g_exception_np;
            
            ELSIF l_adt_cl.id_region IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'ID_REGION', i_lang) || ' ';
                RAISE g_exception_np;
            ELSE
                RETURN TRUE;
            END IF;
        
        ELSIF l_inst_mk = pk_ref_constant.g_market_mx
        THEN
            g_error := 'OPEN c_adt_cl / ' || l_params;
            OPEN c_adt_mx;
            FETCH c_adt_mx
                INTO l_adt_mx;
            CLOSE c_adt_mx;
        
            IF l_adt_mx.first_name IS NULL
               OR l_adt_mx.last_name IS NULL
            THEN
                --g_error := pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'NAME', i_lang) || ' ';
                g_error := 'first_name or last_name ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.dt_birth IS NULL
            THEN
                --g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'DT_BIRTH', i_lang) || ' ';
                g_error := g_error || '; dt_birth ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.gender IS NULL
            THEN
                --g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'GENDER', i_lang) || ' ';
                g_error := g_error || '; gender ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.id_place_of_birth IS NULL
                  AND l_adt_mx.id_country_address != l_country_mx -- MX -- todo: mudar isto 
            THEN
                g_error := g_error || '; id_place_of_birth ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.social_security_number IS NULL
                  AND l_adt_mx.flg_ssn_status = 'D'
            THEN
                --g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'RUN_NUMBER', i_lang) || ' ';
                g_error := g_error || '; social_security_number ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.address_line1 IS NULL
            THEN
                g_error := g_error || '; address_line1 ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.door_number IS NULL
            THEN
                g_error := g_error || '; door_number ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.id_country = l_country_mx -- MX -- todo: mudar isto
            THEN
                IF l_adt_mx.first_level IS NULL
                THEN
                    g_error := g_error || '; first_level ';
                    RAISE g_exception_np;
                
                ELSIF l_adt_mx.second_level IS NULL
                THEN
                    g_error := g_error || '; second_level ';
                    RAISE g_exception_np;
                
                ELSIF l_adt_mx.third_level IS NULL
                THEN
                    g_error := g_error || '; third_level ';
                    RAISE g_exception_np;
                END IF;
            
            ELSIF l_adt_mx.location IS NULL
            THEN
                g_error := g_error || '; location ';
                RAISE g_exception_np;
            
            ELSIF l_adt_mx.postal_code IS NULL
            THEN
                g_error := g_error || '; postal_code ';
                RAISE g_exception_np;
            
            ELSE
                RETURN TRUE;
            END IF;
        
        ELSE
            -- Ficha CORE - Demos
            g_error := 'OPEN c_adt_demos / ' || l_params;
            OPEN c_adt_other;
            FETCH c_adt_other
                INTO l_adt_other.name, l_adt_other.dt_birth, l_adt_other.gender;
            CLOSE c_adt_other;
        
            IF l_adt_other.name IS NULL
            THEN
                g_error := pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'NAME', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_other.gender IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'GENDER', i_lang) || ' ';
                RAISE g_exception_np;
            ELSIF l_adt_other.dt_birth IS NULL
            THEN
                g_error := g_error || '; ' || pk_sysdomain.get_domain('P1_ID_MANDATORY.ADM_CS', 'DT_BIRTH', i_lang) || ' ';
                RAISE g_exception_np;
            ELSE
                RETURN TRUE;
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
                                                     i_function => 'CHECK_MANDATORY_DATA',
                                                     o_error    => o_error);
    END check_mandatory_data;

    FUNCTION get_doctor_test
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_doc   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_doc FOR
            SELECT DISTINCT p.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name
              FROM professional p, prof_cat pc
             WHERE p.id_professional = pc.id_professional
               AND pc.id_category = pk_ref_constant.g_cat_id_med
               AND pc.id_institution = i_prof.institution
               AND p.flg_state = pk_ref_constant.g_active
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_ref_constant.g_yes
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DOCTOR_TEST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END get_doctor_test;

    FUNCTION set_sched_test
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_doc     IN professional.id_professional%TYPE,
        i_date    IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date_tstz      TIMESTAMP;
        l_exr_row        p1_external_request%ROWTYPE;
        l_my_data        t_rec_prof_data;
        l_transaction_id VARCHAR2(4000);
        l_sch            table_number := table_number();
        l_id_ext         sch_api_map_ids.id_schedule_ext%TYPE;
    BEGIN
        g_error := 'Init set_sched_test / ID_REF=' || i_ext_req || ' ID_PROFESSIONAL=' || i_doc || ' DT_SCHEDULE=' ||
                   i_date;
        pk_alertlog.log_debug(g_error);
    
        IF i_date IS NULL
        THEN
            l_date_tstz := pk_ref_utils.get_sysdate + INTERVAL '10' DAY;
        ELSE
            l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
        END IF;
    
        --  getting referral row (up to date)
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data / DCS=' || l_exr_row.id_dep_clin_serv;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => l_exr_row.id_dep_clin_serv,
                                  o_prof_data => l_my_data,
                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --
        -- Creates schedule and updates referral status       
        g_error  := 'Call pk_schedule_api_upstream.create_schedule / id_external_req=' || l_exr_row.id_external_request ||
                    ' id_instit_requests=' || i_prof.institution || ' id_dcs_requests=' || l_exr_row.id_dep_clin_serv ||
                    ' id_prof_requests=' || i_doc || ' id_prof_schedules=' || i_prof.id || ' id_schedule_ref=' ||
                    l_exr_row.id_schedule;
        g_retval := pk_schedule_api_upstream.create_schedule(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_event_id          => pk_ref_constant.g_sch_event_1,
                                                             i_professional_id   => i_doc, -- id_prof_requests
                                                             i_id_patient        => l_exr_row.id_patient,
                                                             i_id_dep_clin_serv  => l_exr_row.id_dep_clin_serv, -- id_dcs_requested
                                                             i_dt_begin_tstz     => pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                     l_date_tstz +
                                                                                                                     INTERVAL '9' hour),
                                                             i_dt_end_tstz       => NULL,
                                                             i_flg_vacancy       => NULL,
                                                             i_id_episode        => NULL,
                                                             i_flg_rqst_type     => NULL,
                                                             i_flg_sch_via       => NULL,
                                                             i_sch_notes         => NULL,
                                                             i_id_inst_requests  => i_prof.institution,
                                                             i_id_dcs_requests   => l_exr_row.id_dep_clin_serv,
                                                             i_id_prof_requests  => i_doc,
                                                             i_id_prof_schedules => i_prof.id,
                                                             i_id_sch_ref        => l_exr_row.id_schedule,
                                                             i_transaction_id    => l_transaction_id,
                                                             i_id_external_req   => l_exr_row.id_external_request,
                                                             o_ids_schedule      => l_sch,
                                                             o_id_schedule_ext   => l_id_ext,
                                                             o_error             => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- Referral status change has already been done inside scheduler integration
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_SCHED_TEST',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_sched_test;

    FUNCTION set_efectiv_test
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sched    schedule.id_schedule%TYPE;
        l_schedout schedule_outp.id_schedule_outp%TYPE;
    BEGIN
        g_error := 'Get schedule / ID_REF=' || i_ext_req;
        SELECT s.id_schedule, so.id_schedule_outp
          INTO l_sched, l_schedout
          FROM p1_external_request exr
          JOIN schedule s
            ON (exr.id_schedule = s.id_schedule)
          JOIN schedule_outp so
            ON (so.id_schedule = s.id_schedule)
         WHERE exr.id_external_request = i_ext_req;
    
        g_error := 'Update schedule_outp / ID_REF=' || i_ext_req;
        UPDATE schedule_outp
           SET flg_state = pk_ref_constant.g_sched_outp_status_e
         WHERE id_schedule_outp = l_schedout;
    
        g_error  := 'pk_ref_ext_sys.update_referral_status / ID_REF=' || i_ext_req;
        g_retval := pk_ref_ext_sys.update_referral_status(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_ext_req        => i_ext_req,
                                                          i_status         => pk_ref_constant.g_p1_status_e,
                                                          i_notes          => NULL,
                                                          i_schedule       => NULL,
                                                          i_episode        => NULL,
                                                          i_transaction_id => i_transaction_id,
                                                          o_error          => o_error);
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
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EFECTIV_TEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_efectiv_test;

    /**
    * Gets number of available dcs for the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_count number of available dcs    
    * @param   o_id dcs id, when there's only one.
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count  NUMBER DEFAULT 0;
        l_values table_varchar;
    
        CURSOR c_ref IS
            SELECT flg_forward_dcs, id_speciality, id_inst_dest, id_inst_orig, id_workflow
              FROM p1_external_request
             WHERE id_external_request = i_ext_req;
    
        l_ref_row c_ref%ROWTYPE;
    BEGIN
        g_error := 'OPEN c_ref / ID_REF=' || i_ext_req;
        OPEN c_ref;
        FETCH c_ref
            INTO l_ref_row;
        CLOSE c_ref;
    
        IF nvl(l_ref_row.flg_forward_dcs, pk_ref_constant.g_no) <> pk_ref_constant.g_yes
        THEN
            g_error  := 'Calling get_workflow_config / ID_REF=' || i_ext_req;
            l_values := get_workflow_config_list(i_prof       => i_prof,
                                                 i_code_param => pk_ref_constant.g_adm_forward_dcs,
                                                 i_speciality => l_ref_row.id_speciality,
                                                 i_inst_dest  => l_ref_row.id_inst_dest,
                                                 i_inst_orig  => l_ref_row.id_inst_orig,
                                                 i_workflow   => nvl(l_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp));
        
            FOR i IN 1 .. l_values.count
            LOOP
            
                -- guarda id do primeiro
                IF l_count = 0
                THEN
                    o_id := to_number(l_values(i));
                END IF;
            
                l_count := l_count + 1;
            END LOOP;
        END IF;
    
        -- So retorna id se for so um
        IF l_count != 1
        THEN
            o_id := NULL;
        END IF;
    
        o_count := l_count;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_clin_serv_forward_count;

    /**
    * Gets value from p1_worflow_config
    * 
    * @param   i_prof professional, institution and software ids
    * @param   i_code_param name of the parameter (column p1_speciality.code_workflow_config)
    * @param   i_speciality p1 speciality for which the parameter applies
    * @param   i_inst_orig  id of referral origin institution for which the parameter applies
    * @param   i_inst_dest  id of referral destination institution for which the parameter applies        
    * @param   i_workflow id of referral workflow
    *
    * @RETURN  
    * @author  Joao Sa
    * @version 1.0
    * @since   06-05-2008
    */
    FUNCTION get_workflow_config
    (
        i_prof       IN profissional,
        i_code_param IN p1_workflow_config.code_workflow_config%TYPE,
        i_speciality IN p1_speciality.id_speciality%TYPE,
        i_inst_dest  IN institution.id_institution%TYPE,
        i_inst_orig  IN institution.id_institution%TYPE,
        i_workflow   IN wf_workflow.id_workflow%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c IS
            SELECT VALUE
              FROM p1_workflow_config wc
              JOIN p1_workflow w
                ON w.code_workflow = wc.code_workflow_config
             WHERE wc.code_workflow_config = i_code_param
               AND wc.id_institution IN (i_prof.institution, 0)
               AND wc.id_speciality IN (i_speciality, 0)
               AND wc.id_inst_dest IN (i_inst_dest, 0)
               AND wc.id_inst_orig IN (i_inst_orig, 0)
               AND wc.id_workflow IN (i_workflow, 0)
               AND w.flg_available = pk_ref_constant.g_yes
             ORDER BY id_workflow DESC, id_institution DESC, id_speciality DESC, id_inst_dest DESC, id_inst_orig DESC;
    
        l_msg p1_workflow_config.value%TYPE;
    BEGIN
        OPEN c;
        FETCH c
            INTO l_msg;
        CLOSE c;
    
        RETURN l_msg;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_workflow_config;

    /**
    * Gets the value list from p1_worflow_config
    * 
    * @param   i_prof professional, institution and software ids
    * @param   i_code_param name of the parameter (column p1_speciality.code_workflow_config)
    * @param   i_speciality p1 speciality for which the parameter applies
    * @param   i_inst_orig  id of referral origin institution for which the parameter applies
    * @param   i_inst_dest  id of referral destination institution for which the parameter applies        
    * @param   i_workflow id of referral workflow
    *
    * @RETURN  List of values
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION get_workflow_config_list
    (
        i_prof       IN profissional,
        i_code_param IN p1_workflow_config.code_workflow_config%TYPE,
        i_speciality IN p1_speciality.id_speciality%TYPE,
        i_inst_dest  IN institution.id_institution%TYPE,
        i_inst_orig  IN institution.id_institution%TYPE,
        i_workflow   IN wf_workflow.id_workflow%TYPE
    ) RETURN table_varchar IS
        CURSOR c_wf_c IS
            SELECT VALUE
              FROM p1_workflow_config wc
              JOIN p1_workflow w
                ON w.code_workflow = wc.code_workflow_config
             WHERE wc.code_workflow_config = i_code_param
               AND wc.id_institution IN (i_prof.institution, 0)
               AND wc.id_speciality IN (i_speciality, 0)
               AND wc.id_inst_dest IN (i_inst_dest, 0)
               AND wc.id_inst_orig IN (i_inst_orig, 0)
               AND wc.id_workflow IN (i_workflow, 0)
               AND w.flg_available = pk_ref_constant.g_yes
             ORDER BY id_institution DESC, id_speciality DESC, id_inst_dest DESC, id_inst_orig DESC;
    
        l_tab_result table_varchar := table_varchar();
    BEGIN
        OPEN c_wf_c;
        FETCH c_wf_c BULK COLLECT
            INTO l_tab_result;
        CLOSE c_wf_c;
    
        RETURN l_tab_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_workflow_config_list;

    /**
    * Gets the default dep_clin_serv for this institution/speciality 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_exr_row             Referral data (uses only id_speciality, id_inst_dest and id_external_sys)
    * @param   o_dcs                 Deaprtment and service identifier   
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   30-04-2008
    */
    FUNCTION get_default_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_exr_row IN p1_external_request%ROWTYPE,
        o_dcs     OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_default_dcs / ID_REF=' || i_exr_row.id_external_request || ' ID_SPECIALITY=' ||
                   i_exr_row.id_speciality || ' ID_INST_DEST=' || i_exr_row.id_inst_dest || ' ID_EXTERNAL_SYS=' ||
                   i_exr_row.id_external_sys;
    
        RETURN get_default_dcs(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_id_ref        => i_exr_row.id_external_request,
                               i_id_speciality => i_exr_row.id_speciality,
                               i_id_inst_dest  => i_exr_row.id_inst_dest,
                               i_id_ext_sys    => i_exr_row.id_external_sys,
                               o_dcs           => o_dcs,
                               o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_default_dcs / ' || g_error || ' / ' || SQLERRM;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEFAULT_DCS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_default_dcs;

    /**
    * Gets the default dep_clin_serv for this institution/speciality 
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_ref              Referral identifier
    * @param   i_id_speciality       Referral speciality identifier
    * @param   i_id_inst_dest        Dest institution identifier
    * @param   i_id_ext_sys          External system identifier   
    * @param   o_dcs                 Deaprtment and service identifier   
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-10-2012
    */
    FUNCTION get_default_dcs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        i_id_speciality IN p1_external_request.id_speciality%TYPE,
        i_id_inst_dest  IN p1_external_request.id_inst_dest%TYPE,
        i_id_ext_sys    IN p1_external_request.id_external_sys%TYPE,
        o_dcs           OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_default_dcs IS
            SELECT v.id_dep_clin_serv
              FROM v_ref_spec_inst_dcs v
             WHERE v.id_speciality = i_id_speciality
               AND v.id_institution = i_id_inst_dest
               AND v.flg_default = pk_ref_constant.g_yes
               AND v.flg_availability <> pk_ref_constant.g_flg_availability_i
               AND v.id_external_sys IN (nvl(i_id_ext_sys, 0), 0);
    BEGIN
        g_error := 'Init get_default_dcs / ID_REF=' || i_id_ref || ' ID_SPECIALITY=' || i_id_speciality ||
                   ' ID_INST_DEST=' || i_id_inst_dest || ' ID_EXTERNAL_SYS=' || i_id_ext_sys;
        OPEN c_default_dcs;
        FETCH c_default_dcs
            INTO o_dcs;
    
        g_error := 'o_dcs=' || o_dcs || '  / ID_REF=' || i_id_ref || ' ID_SPECIALITY=' || i_id_speciality ||
                   ' ID_INST_DEST=' || i_id_inst_dest || ' ID_EXTERNAL_SYS=' || i_id_ext_sys;
        IF c_default_dcs%NOTFOUND
        THEN
            g_error := 'No default dep_clin_serv defined for request id: ' || i_id_ref || ' / ' || g_error;
            RAISE g_exception;
        END IF;
    
        CLOSE c_default_dcs;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_default_dcs / ' || g_error || ' / ' || SQLERRM;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEFAULT_DCS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_default_dcs;

    /**
    * Get descriptions for provided tables and ids.
    * Used by the interface to get Alert description of mapped ids.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_key  table names and ids, third field used only for sys_domain. (TABLE_NAME, ID[VAL], [CODE_DOMAIN])
    * @param   o_id   result id  description. (ID[VAL])
    * @param   o_desc result description. (Description)    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   28-10-2008
    */
    FUNCTION get_description
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_key   IN table_table_varchar, -- (TABELA, ID[VAL], [CODE_DOMAIN])
        o_id    OUT table_varchar,
        o_desc  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql VARCHAR2(4000);
    BEGIN
        g_error := 'Init get_description';
        o_id    := table_varchar(NULL);
        o_id.extend(i_key.count - 1, 1);
        o_desc := table_varchar(NULL);
        o_desc.extend(i_key.count - 1, 1);
    
        FOR i IN 1 .. i_key.count
        LOOP
            CASE i_key(i) (1)
                WHEN 'SYS_CONFIG' THEN
                    g_error := 'SYS_CONFIG';
                    o_desc(i) := pk_sysconfig.get_config(i_key(i) (2), i_prof);
                
                    g_error := 'SYS_CONFIG / KEY(2)=' || i_key(i) (2) || ' DESC=' || o_desc(i);
                    pk_alertlog.log_debug(g_error);
                
                WHEN 'SYS_DOMAIN' THEN
                    g_error := 'SYS_DOMAIN';
                    o_desc(i) := pk_sysdomain.get_domain(i_key(i) (3), i_key(i) (2), i_lang);
                
                    g_error := 'SYS_DOMAIN / KEY(2)=' || i_key(i) (2) || ' KEY(3)= ' || i_key(i)
                               (3) || ' DESC=' || o_desc(i);
                    pk_alertlog.log_debug(g_error);
                
                WHEN 'COUNTRY' THEN
                    g_error := 'COUNTRY';
                    l_sql   := 'SELECT id_country, pk_translation.get_translation(' || to_char(i_lang) || ', ''' ||
                               i_key(i) (1) || '.CODE_' || i_key(i) (1) ||
                               '.''|| id_country ) FROM COUNTRY WHERE FLG_AVAILABLE = ''Y'' and ALPHA2_CODE = ''' ||
                               i_key(i) (2) || '''';
                
                    pk_alertlog.log_debug(l_sql);
                
                    BEGIN
                        EXECUTE IMMEDIATE l_sql
                            INTO o_id(i), o_desc(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                    g_error := 'COUNTRY / KEY(1)=' || i_key(i) (1) || ' KEY(2)= ' || i_key(i)
                               (2) || ' ID=' || o_id(i) || ' DESC=' || o_desc(i);
                    pk_alertlog.log_debug(g_error);
                
                WHEN 'DISTRICT' THEN
                    g_error := 'DISTRICT';
                    l_sql   := 'SELECT id_district, pk_translation.get_translation(' || to_char(i_lang) || ', ''' ||
                               i_key(i) (1) || '.CODE_' || i_key(i) (1) ||
                               '.''|| id_district ) FROM DISTRICT WHERE FLG_AVAILABLE = ''Y'' and ID_DISTRICT = ''' ||
                               i_key(i) (2) || '''';
                
                    pk_alertlog.log_debug(l_sql);
                
                    BEGIN
                        EXECUTE IMMEDIATE l_sql
                            INTO o_id(i), o_desc(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                    g_error := 'DISTRICT / KEY(1)=' || i_key(i) (1) || ' KEY(2)= ' || i_key(i)
                               (2) || ' ID=' || o_id(i) || ' DESC=' || o_desc(i);
                    pk_alertlog.log_debug(g_error);
                
                ELSE
                    g_error := 'ELSE';
                    l_sql   := 'SELECT pk_translation.get_translation(' || to_char(i_lang) || ', ''' || i_key(i)
                               (1) || '.CODE_' || i_key(i) (1) || '.' || i_key(i) (2) || ''') FROM dual';
                
                    pk_alertlog.log_debug(l_sql);
                
                    BEGIN
                        EXECUTE IMMEDIATE l_sql
                            INTO o_desc(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                    g_error := 'TRANSLATION / KEY(1)=' || i_key(i) (1) || ' KEY(2)= ' || i_key(i)
                               (2) || ' DESC=' || o_desc(i);
                    pk_alertlog.log_debug(g_error);
                
            END CASE;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DESCRIPTION',
                                                     o_error    => o_error);
    END get_description;

    /**
    * Get patient age and gender
    *
    * @param   i_dt_birth  Patient birth date
    * @param   i_age       Patient age (in table patient)
    *
    * @RETURN  Patient age
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-06-2013
    */
    FUNCTION get_pat_age
    (
        i_dt_birth IN patient.dt_birth%TYPE,
        i_age      IN patient.age%TYPE
    ) RETURN patient.age%TYPE IS
        l_result patient.age%TYPE;
    BEGIN
    
        IF i_dt_birth IS NOT NULL
        THEN
            l_result := trunc(months_between(SYSDATE, i_dt_birth) / 12);
        ELSE
            l_result := i_age;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_pat_age;

    /**
    * Get patient age and gender
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_patient  patient id (to get age and gender)
    * @param   o_info  output
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   18-11-2008
    */
    FUNCTION get_pat_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_INFO / i_patient=' || i_patient;
        OPEN o_info FOR
            SELECT p.gender, get_pat_age(i_dt_birth => p.dt_birth, i_age => p.age) age
              FROM patient p
             WHERE id_patient = i_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_INFO',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_pat_info;

    /**
    * Get patient age and gender
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Professional id, institution and software
    * @param   i_patient  Patient identifier
    * @param   o_gender   Patient gender
    * @param   o_age      Patient age in years
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-07-2013
    */
    FUNCTION get_pat_age_gender
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_cur pk_types.cursor_type;
    BEGIN
        g_error  := 'Init get_pat_age_gender / i_patient=' || i_patient;
        g_retval := get_pat_info(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_patient => i_patient,
                                 o_info    => l_ref_cur,
                                 o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        FETCH l_ref_cur
            INTO o_gender, o_age;
        CLOSE l_ref_cur;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_AGE_GENDER',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_age_gender;

    /**
    * Get patient sns health plan
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_patient  patient identifier
    * @param   i_active If set to 'Y' only returns the Patient's SNS number if defaluled 
    *             (check_sns_active_epis returns 'Y')    
    * @param   i_epis   episode id
    * @param   o_info  output
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    *
    * @changed by: Ricardo Patrocínio
    * @changed in: 2009-11-06
    * @change reason: [ALERT-54754]
    */
    FUNCTION get_pat_sns
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_epis    IN episode.id_episode%TYPE,
        i_active  IN VARCHAR2 DEFAULT pk_ref_constant.g_no, -- ALERT-50017: Only return SNS if FLG_DEFAULT is 'Y'
        o_num_sns OUT pat_health_plan.num_health_plan%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sc_multi_instit VARCHAR2(1);
    
        CURSOR o_sns(x_id_health_plan IN VARCHAR2) IS
            SELECT php.num_health_plan
              FROM pat_health_plan php
              JOIN health_plan hp
                ON (php.id_health_plan = hp.id_health_plan)
             WHERE php.id_patient = i_patient
               AND php.flg_status = pk_ref_constant.g_active
               AND ((php.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                   (php.id_institution = i_prof.institution AND l_sc_multi_instit = pk_ref_constant.g_no))
               AND hp.flg_available = pk_ref_constant.g_yes
               AND hp.id_health_plan = x_id_health_plan;
    
        CURSOR o_sns_active(x_id_health_plan IN VARCHAR2) IS
            SELECT php.num_health_plan
              FROM pat_health_plan php
              JOIN health_plan hp
                ON (php.id_health_plan = hp.id_health_plan)
             WHERE php.id_patient = i_patient
               AND pk_epis_health_plan.check_sns_active_epis(i_lang,
                                                             i_prof,
                                                             php.id_pat_health_plan,
                                                             i_epis,
                                                             php.flg_default) = pk_ref_constant.g_yes
               AND php.flg_status = pk_ref_constant.g_active
               AND ((php.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                   (php.id_institution = i_prof.institution AND l_sc_multi_instit = pk_ref_constant.g_no))
               AND hp.flg_available = pk_ref_constant.g_yes
               AND hp.id_health_plan = x_id_health_plan;
    
        l_id_health_plan NUMBER(24);
    
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'Calling pk_ref_utils.get_default_health_plan ' || ' / i_patient=' || i_patient;
        l_id_health_plan := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
    
        l_sc_multi_instit := pk_sysconfig.get_config(pk_ref_constant.g_sc_multi_institution, i_prof);
    
        ----------------------
        -- FUNC
        ----------------------    
        IF i_active = pk_ref_constant.g_yes
        THEN
            g_error := 'OPEN O_SNS_ACTIVE / i_patient=' || i_patient;
            OPEN o_sns_active(l_id_health_plan);
            FETCH o_sns_active
                INTO o_num_sns;
            CLOSE o_sns_active;
        
        ELSE
            g_error := 'OPEN O_SNS / i_patient=' || i_patient;
            OPEN o_sns(l_id_health_plan);
            FETCH o_sns
                INTO o_num_sns;
            CLOSE o_sns;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_SNS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_sns;

    /**
    * Validates if the referral is editable.
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_ext_req       Referral id
    *
    * @RETURN  Y if editable, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION is_editable
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2 IS
        l_my_data t_rec_prof_data;
        l_exr_row p1_external_request%ROWTYPE;
        l_error   t_error_out;
    BEGIN
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting professional data
        g_error  := 'Calling get_prof_data';
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => l_exr_row.id_dep_clin_serv,
                                  o_prof_data => l_my_data,
                                  o_error     => l_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Calling is_editable';
        RETURN is_editable(i_lang => i_lang, i_prof => i_prof, i_prof_data => l_my_data, i_ext_row => l_exr_row);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / is_editable in / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END is_editable;

    /**
    * Validates if the referral is editable.
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_ext_row       Referral info
    * @param   i_prof_data     Professional data
    *
    * @RETURN  Y if editable, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION is_editable
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ext_row   IN p1_external_request%ROWTYPE
    ) RETURN VARCHAR2 IS
        l_result          VARCHAR2(1 CHAR);
        l_flg_status_n    wf_status.id_status%TYPE;
        l_wf_status_info  table_varchar;
        l_status_info_row t_rec_wf_status_info := t_rec_wf_status_info();
        l_error           t_error_out;
        l_old_status      VARCHAR2(50 CHAR);
        l_config          VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'Init is_editable / ID_REF=' || i_ext_row.id_external_request || ' FLG_STATUS=' ||
                   i_ext_row.flg_status || ' WF=' || i_ext_row.id_workflow;
        IF i_ext_row.id_workflow IS NULL
        THEN
            g_error  := 'Call pk_ref_status.check_config_enabled / ID_REF=' || i_ext_row.id_external_request ||
                        ' CONFIG=' || pk_ref_constant.g_ref_upd_sts_a_enabled;
            l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_config => pk_ref_constant.g_ref_upd_sts_a_enabled);
        
            l_old_status := pk_ref_constant.g_p1_status_n || pk_ref_constant.g_p1_status_o ||
                            pk_ref_constant.g_p1_status_d || pk_ref_constant.g_p1_status_i ||
                            pk_ref_constant.g_p1_status_b || pk_ref_constant.g_p1_status_t ||
                            pk_ref_constant.g_p1_status_r;
        
            IF l_config = pk_ref_constant.g_yes
            THEN
                l_old_status := l_old_status || pk_ref_constant.g_p1_status_a; -- ALERT-66740
            END IF;
        
            IF instr(l_old_status, i_ext_row.flg_status, 1) = 0
            THEN
                l_result := pk_ref_constant.g_no;
            ELSE
                l_result := pk_ref_constant.g_yes;
            END IF;
        ELSE
            g_error        := 'Calling  pk_ref_status.convert_status_n / ID_REF=' || i_ext_row.id_external_request ||
                              ' FLG_STATUS=' || i_ext_row.flg_status || ' WF=' || i_ext_row.id_workflow;
            l_flg_status_n := pk_ref_status.convert_status_n(i_ext_row.flg_status);
        
            g_error          := 'Calling init_param_tab / ID_REF=' || i_ext_row.id_external_request || ' FLG_STATUS=' ||
                                i_ext_row.flg_status || ' WF=' || i_ext_row.id_workflow;
            l_wf_status_info := init_param_tab(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_ext_req            => i_ext_row.id_external_request,
                                               i_id_patient         => i_ext_row.id_patient,
                                               i_id_inst_orig       => i_ext_row.id_inst_orig,
                                               i_id_inst_dest       => i_ext_row.id_inst_dest,
                                               i_id_dep_clin_serv   => i_ext_row.id_dep_clin_serv,
                                               i_id_speciality      => i_ext_row.id_speciality,
                                               i_flg_type           => i_ext_row.flg_type,
                                               i_decision_urg_level => i_ext_row.decision_urg_level,
                                               i_id_prof_requested  => i_ext_row.id_prof_requested,
                                               i_id_prof_redirected => i_ext_row.id_prof_redirected,
                                               i_id_prof_status     => i_ext_row.id_prof_status,
                                               i_external_sys       => i_ext_row.id_external_sys,
                                               i_flg_status         => i_ext_row.flg_status);
        
            g_error  := 'Calling PK_WORKFLOW.get_status_info / ID_REF=' || i_ext_row.id_external_request ||
                        ' FLG_STATUS=' || i_ext_row.flg_status || ' WF=' || i_ext_row.id_workflow;
            g_retval := pk_workflow.get_status_info(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_workflow         => nvl(i_ext_row.id_workflow,
                                                                                 pk_ref_constant.g_wf_pcc_hosp),
                                                    i_id_status           => l_flg_status_n,
                                                    i_id_category         => i_prof_data.id_category,
                                                    i_id_profile_template => i_prof_data.id_profile_template,
                                                    i_id_functionality    => i_prof_data.id_functionality,
                                                    i_param               => l_wf_status_info,
                                                    o_status_info         => l_status_info_row,
                                                    o_error               => l_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_status_info_row.flg_update = pk_ref_constant.g_na
            THEN
                l_result := pk_ref_constant.g_no;
            ELSE
                l_result := l_status_info_row.flg_update;
            END IF;
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / is_editable / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END is_editable;

    /**
    * Validates if dest institution is inside orig institution ref area
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_inst_orig     Origin institution identifier
    * @param   i_inst_dest     Dest institution identifier
    * @param   i_ref_type      Referral type
    * @param   i_id_spec       Speciality identifier
    *
    * @value   i_ref_type      {*} 'C' consultation {*} 'A' analisys {*} 'E' exam {*} 'I' intervention {*} 'P' procedures {*} 'F' mfr
    *
    * @RETURN  Y if inside ref area, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-07-2009
    */
    FUNCTION get_inside_ref_area
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        i_inst_dest IN p1_dest_institution.id_inst_dest%TYPE,
        i_ref_type  IN p1_dest_institution.flg_type%TYPE,
        i_id_spec   IN ref_dest_institution_spec.id_speciality%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_ref_area IS
            SELECT rdis.flg_inside_ref_area
              FROM p1_dest_institution pdi
              JOIN ref_dest_institution_spec rdis
                ON (pdi.id_dest_institution = rdis.id_dest_institution)
             WHERE pdi.id_inst_orig = i_inst_orig
               AND pdi.id_inst_dest = i_inst_dest
               AND pdi.flg_type = i_ref_type
               AND rdis.id_speciality = i_id_spec
               AND rdis.flg_available = pk_ref_constant.g_yes;
    
        l_flg_inside_ref_area ref_dest_institution_spec.flg_inside_ref_area%TYPE;
        l_params              VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'i_inst_orig=' || i_inst_orig || ' i_inst_dest=' || i_inst_dest || ' i_ref_type=' || i_ref_type ||
                    ' i_id_spec=' || i_id_spec;
        g_error  := 'OPEN c_ref_area / ' || l_params;
        OPEN c_ref_area;
    
        g_error := 'FETCH c_ref_area / ' || l_params;
        FETCH c_ref_area
            INTO l_flg_inside_ref_area;
    
        g_error := 'CLOSE c_ref_area / ' || l_params;
        CLOSE c_ref_area;
    
        g_error               := 'NVL ' || l_flg_inside_ref_area || ' / ' || l_params;
        l_flg_inside_ref_area := nvl(l_flg_inside_ref_area, pk_ref_constant.g_no);
    
        RETURN l_flg_inside_ref_area;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / get_inside_ref_area / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END get_inside_ref_area;

    /**
    * Inserts notes into p1_detail 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_detail_row notes   
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   07-05-2008
    */
    FUNCTION set_ref_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_detail_row IN p1_detail%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_detail_row p1_detail%ROWTYPE;
        l_var        p1_detail.id_detail%TYPE;
    BEGIN
        g_error := 'Init set_ref_detail / ID_REF=' || i_detail_row.id_external_request;
        IF i_detail_row.dt_insert_tstz IS NOT NULL
        THEN
            l_detail_row.dt_insert_tstz := i_detail_row.dt_insert_tstz;
        ELSE
            l_detail_row.dt_insert_tstz := pk_ref_utils.get_sysdate;
        END IF;
    
        IF i_detail_row.text IS NOT NULL
        THEN
            g_error                          := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_ndec || '  / ID_REF=' ||
                                                i_detail_row.id_external_request;
            l_detail_row.id_external_request := i_detail_row.id_external_request;
            l_detail_row.text                := i_detail_row.text;
            l_detail_row.flg_type            := i_detail_row.flg_type;
            l_detail_row.id_professional     := i_prof.id;
            l_detail_row.id_institution      := i_prof.institution;
            l_detail_row.id_tracking         := i_detail_row.id_tracking;
            l_detail_row.flg_status          := pk_ref_constant.g_detail_status_a;
        
            g_error := 'Call pk_ref_api.set_p1_detail / ID_REF=' || i_detail_row.id_external_request;
            IF NOT pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_p1_detail => l_detail_row,
                                            o_id_detail => l_var,
                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              i_function => 'SET_NOTES',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_detail;

    /**
    * Gets referral error description
    *
    * @param   i_lang             Language
    * @param   i_id_ref_error     Referral error code
    *
    * @return  professional interface
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION get_ref_error_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_id_ref_error IN ref_error.id_ref_error%TYPE
    ) RETURN VARCHAR2 IS
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, r.code_ref_error)
          INTO l_error_desc
          FROM ref_error r
         WHERE r.id_ref_error = i_id_ref_error;
    
        RETURN l_error_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ref_error_desc;

    /**
    * Checks if this institution is private or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_inst       Institution identifier   
    * @param   o_flg_result    Flag indicating if this institution is private or not
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION check_private_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_inst    IN institution.id_institution%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type institution.flg_type%TYPE;
    BEGIN
        g_error      := 'Init check_private_inst / ID_INSTITUTION=' || i_id_inst;
        o_flg_result := pk_ref_constant.g_no;
    
        g_retval := pk_ref_utils.get_inst_type(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_id_inst   => i_id_inst,
                                               o_inst_type => l_flg_type,
                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'ID_INSTITUTION=' || i_id_inst || ' FLG_TYPE=' || l_flg_type;
        IF l_flg_type = pk_ref_constant.g_private_practice
        THEN
            o_flg_result := pk_ref_constant.g_yes;
        END IF;
    
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
                                              i_function => 'CHECK_PRIVATE_INST',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_private_inst;
    /**
    * Get run_number
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_external_request 
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2010 
    */
    FUNCTION get_run_curp_number
    (
        i_id_patient patient.id_patient%TYPE,
        i_id_market  market.id_market%TYPE
    ) RETURN VARCHAR IS
        l_var person.run_number%TYPE;
    BEGIN
        IF i_id_market = pk_ref_constant.g_market_cl
        THEN
            g_error := 'select run_number id_patient = ' || i_id_patient;
            SELECT per.run_number
              INTO l_var
              FROM v_person per
              JOIN v_patient pat
                ON (pat.id_person = per.id_person)
             WHERE pat.id_patient = i_id_patient;
            RETURN l_var;
        
        ELSIF i_id_market = pk_ref_constant.g_market_mx
        THEN
            g_error := 'select CURP_number id_patient = ' || i_id_patient;
            SELECT per.social_security_number
              INTO l_var
              FROM v_person per
              JOIN v_patient pat
                ON (pat.id_person = per.id_person)
             WHERE pat.id_patient = i_id_patient;
            RETURN l_var;
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_run_curp_number;

    /**
    * Get the master profile
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_profile 
    * @param   o_master_prof
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_profile_owner
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_profile     IN profile_template.id_profile_template%TYPE,
        o_master_prof OUT profile_template.id_profile_template%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        SELECT pt.id_profile_template
          INTO o_master_prof
          FROM profile_template pt
         WHERE pt.id_parent IS NULL
        CONNECT BY PRIOR pt.id_parent = pt.id_profile_template
         START WITH pt.id_profile_template = i_profile;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROFILE_OWNER',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_profile_owner;

    /**
    * Get the master profile identifier
    *
    * @param   i_profile      Professional profile identifier
    *
    * @RETURN  the master profile identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-03-2013 
    */
    FUNCTION get_profile_owner(i_profile IN profile_template.id_profile_template%TYPE)
        RETURN profile_template.id_profile_template%TYPE IS
        l_result    profile_template.id_profile_template%TYPE;
        l_error_out t_error_out;
    BEGIN
    
        g_retval := get_profile_owner(i_lang        => NULL,
                                      i_prof        => NULL,
                                      i_profile     => i_profile,
                                      o_master_prof => l_result,
                                      o_error       => l_error_out);
    
        RETURN l_result;
    END get_profile_owner;

    /**
    * Get the Ref type for prof
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_clinical_service 
    * @param   i_id_institution 
    * @param   i_id_software 
    * @param   o_prof
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_ref_flg_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_requested IN table_varchar,
        o_flg_type          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_flg_type FOR
            SELECT pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_type, pk_ref_constant.g_p1_type_c, i_lang) flg_type_desc,
                   pk_ref_constant.g_p1_type_c flg_type
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_REF_FLG_TYPE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_ref_flg_type;

    /**
    * Gets Referral Status F description
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_ID_REF       Referral identifier
    * @param   I_SUBJECT      Subject for grouping of actions   
    * @param   I_FROM_STATE   Begin action state     
    * @param   O_ACTIONS      Referral actions
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   27-09-2010
    */
    FUNCTION get_ref_f_information
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_professional     IN professional.id_professional%TYPE DEFAULT NULL,
        i_id_external_request IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        i_id_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        o_cursor              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_ref_f_information / i_id_professional=' || i_id_professional || ' i_id_external_request=' ||
                   i_id_external_request || ' i_id_patient=' || i_id_patient;
        OPEN o_cursor FOR
            SELECT t.id_patient pacient,
                   pk_adt.get_patient_name(i_lang,
                                           i_prof,
                                           t.id_patient,
                                           pk_p1_external_request.check_prof_resp(i_lang, i_prof, t.id_external_request)) pacient_desc,
                   t.id_professional medico,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_dest,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_begin_tstz, i_prof) data_agendamento,
                   pk_date_utils.dt_chr_tsz(i_lang, t.dt_begin_tstz, i_prof) || ' ' ||
                   pk_date_utils.dt_chr_hour_tsz(i_lang, t.dt_begin_tstz, i_prof) date_desc,
                   t.id_dcs_requested dep_clin_serv,
                   t.id_clinical_service,
                   pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_clinical_service_code || t.id_clinical_service) clin_serv_desc,
                   t.id_dcs_requested,
                   t.id_clinical_service,
                   t.flg_status
              FROM (SELECT p.id_patient,
                           p.id_external_request,
                           spo.id_professional,
                           s.dt_begin_tstz,
                           s.id_dcs_requested,
                           p.flg_status,
                           dcs.id_clinical_service
                      FROM p1_external_request p
                      JOIN schedule s
                        ON (s.id_schedule = p.id_schedule AND s.flg_status = pk_ref_constant.g_active)
                      LEFT JOIN schedule_outp so
                        ON s.id_schedule = so.id_schedule
                      LEFT JOIN sch_prof_outp spo
                        ON so.id_schedule_outp = spo.id_schedule_outp
                      LEFT JOIN dep_clin_serv dcs
                        ON s.id_dcs_requested = dcs.id_dep_clin_serv
                     WHERE (p.id_external_request = i_id_external_request OR i_id_external_request IS NULL)
                       AND (p.id_patient = i_id_patient OR i_id_patient IS NULL)
                       AND (p.id_prof_requested = i_id_professional OR i_id_professional IS NULL)) t
             ORDER BY 2, 4;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_ref_f_information',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_ref_f_information;

    /**
    * Get professionals available for schedule
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_spec              P1_SPECIALITY Id
    * @param   i_inst_dest         Institution Id
    * @param   o_sql               List of professionals 
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-10-2010
    */
    FUNCTION get_prof_to_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_spec      IN p1_speciality.id_speciality%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        o_sql       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_sql / i_spec=' || i_spec || ' i_inst_dest=' || i_inst_dest;
        OPEN o_sql FOR
            SELECT t.id_professional id_prof_sch,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_sch_name
              FROM (SELECT pdcs.id_professional
                      FROM prof_dep_clin_serv pdcs
                      JOIN v_ref_spec_inst_dcs v
                        ON (v.id_dep_clin_serv = pdcs.id_dep_clin_serv)
                     WHERE pdcs.flg_status = pk_ref_constant.g_status_selected
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, i_prof.institution) =
                           pk_ref_constant.g_yes
                       AND v.id_speciality = i_spec
                       AND v.id_institution = i_inst_dest) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_TO_SCHEDULE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_prof_to_schedule;

    /**
    * Check if prof is a GP physican
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   o_error
    *
    * @RETURN  VARCHAR2
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-10-2010
    */
    FUNCTION check_prof_phy
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN VARCHAR2 IS
    BEGIN
        IF pk_prof_utils.get_prof_profile_template(i_prof => i_prof) = pk_ref_constant.g_profile_gp_med
        THEN
            RETURN pk_ref_constant.g_yes;
        ELSE
            RETURN pk_ref_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PROF_PHY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
    END check_prof_phy;

    FUNCTION get_no_show_id_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_p1_reason_code IN p1_reason_code.id_reason_code%TYPE,
        o_value          OUT cancel_reason.id_cancel_reason%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cancel_reason
        (
            x_profile_template profile_template.id_profile_template%TYPE,
            x_p1_reason_code   p1_reason_code.id_reason_code%TYPE
        ) IS
            SELECT id_cancel_reason --, cancel_reason_desc, notes_mandatory, flg_default
              FROM (SELECT cr.id_cancel_reason id_cancel_reason,
                           nvl2(rsi.desc_synonym,
                                rsi.desc_synonym,
                                pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason_desc,
                           cr.flg_notes_mandatory notes_mandatory,
                           rank() over(PARTITION BY crsi.id_cancel_reason ORDER BY crsi.id_profile_template DESC, crsi.id_institution DESC, crsi.id_software DESC) origin_rank,
                           prcr.flg_default
                      FROM cancel_reason cr
                      LEFT JOIN reason_synonym_inst rsi
                        ON rsi.id_reason = cr.id_cancel_reason
                      JOIN reason_action_relation rar
                        ON rar.id_reason = cr.id_cancel_reason
                      JOIN reason_action ra
                        ON ra.id_action = rar.id_action
                       AND ra.flg_type = pk_ref_constant.g_reason_action_cancel
                      JOIN cancel_rea_soft_inst crsi
                        ON crsi.id_cancel_reason = cr.id_cancel_reason
                      JOIN cancel_rea_area cra
                        ON cra.id_cancel_rea_area = crsi.id_cancel_rea_area
                      JOIN p1_reason_to_cancel_reason prcr
                        ON prcr.id_cancel_reason = cr.id_cancel_reason
                     WHERE upper(cra.intern_name) = upper(pk_ref_constant.g_patient_no_show)
                       AND crsi.id_profile_template IN (0, x_profile_template)
                       AND crsi.id_software IN (0, i_prof.software)
                       AND crsi.id_institution IN (0, i_prof.institution)
                       AND crsi.flg_available = pk_ref_constant.g_yes
                       AND prcr.flg_available = pk_ref_constant.g_yes
                       AND prcr.id_reason_code = x_p1_reason_code
                     ORDER BY crsi.rank ASC, cr.rank ASC, cancel_reason_desc ASC)
             WHERE rownum = 1;
    
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
    
        g_error               := 'Call pk_tools.get_prof_profile_template';
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        g_error := 'GET id reason PATIENT_NO_SHOW';
        OPEN c_cancel_reason(l_id_profile_template, i_p1_reason_code);
        FETCH c_cancel_reason
            INTO o_value;
        IF c_cancel_reason%NOTFOUND
        THEN
            o_value := NULL;
        END IF;
    
        CLOSE c_cancel_reason;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NO_SHOW_ID_REASON',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_no_show_id_reason;

    FUNCTION get_no_show_id_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_p1_reason_code OUT p1_reason_code.id_reason_code%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cancel_reason(x_p1_reason_code p1_reason_code.id_reason_code%TYPE) IS
            SELECT prcr.id_reason_code
              FROM p1_reason_to_cancel_reason prcr
             WHERE prcr.id_cancel_reason = x_p1_reason_code
               AND prcr.flg_available = pk_ref_constant.g_yes
               AND rownum = 1;
    
    BEGIN
        g_error := 'GET id_reason_code PATIENT_NO_SHOW';
        pk_alertlog.log_debug(g_error);
        OPEN c_cancel_reason(i_cancel_reason);
        FETCH c_cancel_reason
            INTO o_p1_reason_code;
        IF c_cancel_reason%NOTFOUND
        THEN
            o_p1_reason_code := NULL;
        END IF;
        CLOSE c_cancel_reason;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NO_SHOW_ID_REASON',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_no_show_id_reason;

    /**
    * Returns referral status that are considered active (emited and not closed) 
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    * @param   o_active_status     Active status not considering dt_status
    * @param   o_active_status_dt  Active status considering dt_status
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  table_varchar referral status
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2011
    */
    FUNCTION get_pat_active_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_active_status    OUT NOCOPY table_varchar,
        o_active_status_dt OUT NOCOPY table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error         := 'Init get_pat_active_status';
        o_active_status := table_varchar(pk_ref_constant.g_p1_status_n,
                                         pk_ref_constant.g_p1_status_i,
                                         pk_ref_constant.g_p1_status_b,
                                         pk_ref_constant.g_p1_status_t,
                                         pk_ref_constant.g_p1_status_r,
                                         pk_ref_constant.g_p1_status_d,
                                         pk_ref_constant.g_p1_status_y,
                                         pk_ref_constant.g_p1_status_j,
                                         pk_ref_constant.g_p1_status_v,
                                         pk_ref_constant.g_p1_status_z,
                                         pk_ref_constant.g_p1_status_l);
    
        o_active_status_dt := table_varchar(pk_ref_constant.g_p1_status_a,
                                            pk_ref_constant.g_p1_status_s,
                                            pk_ref_constant.g_p1_status_m);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_active_status    := table_varchar();
            o_active_status_dt := table_varchar();
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_ACTIVE_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_active_status;

    /**
    * Returns referral status that are considered closed 
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    *
    * @RETURN  table_varchar referral status
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-01-2012
    */
    FUNCTION get_pat_closed_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar IS
        l_result table_varchar;
    BEGIN
        g_error  := 'Init get_pat_active_status';
        l_result := table_varchar(pk_ref_constant.g_p1_status_e,
                                  pk_ref_constant.g_p1_status_f,
                                  pk_ref_constant.g_p1_status_w,
                                  pk_ref_constant.g_p1_status_k,
                                  pk_ref_constant.g_p1_status_x,
                                  pk_ref_constant.g_p1_status_h,
                                  pk_ref_constant.g_p1_status_p);
        RETURN l_result;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN table_varchar();
    END get_pat_closed_status;

    /**
    * Get MCDT's Nature 
    *
    * @param   i_mcdt              Id MCDT
    * @param   i_type              MCDT type: {*} 'A' Analysis
                                              {*} 'I' Image
                                              {*} 'E' Other exams
                                              {*} 'P' intervetions
                                              {*} 'F' MFR                                                                                           
    * @RETURN  Varchar 
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-08-2011
    **/

    FUNCTION get_mcdt_nature
    (
        i_mcdt IN mcdt_nature.id_mcdt%TYPE,
        i_type IN mcdt_nature.flg_mcdt%TYPE
    ) RETURN VARCHAR IS
    
        CURSOR c_nature
        (
            x_mcdt mcdt_nature.id_mcdt%TYPE,
            x_type mcdt_nature.flg_mcdt%TYPE
        ) IS
            SELECT flg_nature
              FROM mcdt_nature
             WHERE flg_available = pk_ref_constant.g_yes
               AND flg_mcdt = x_type
               AND id_mcdt = x_mcdt
             ORDER BY flg_nature;
    
        nature_record c_nature%ROWTYPE;
        nature        VARCHAR2(4000);
        l_error       t_error_out;
    BEGIN
        nature := NULL;
        OPEN c_nature(i_mcdt, i_type);
        LOOP
            FETCH c_nature
                INTO nature_record;
            EXIT WHEN c_nature%NOTFOUND;
            IF nature IS NOT NULL
            THEN
                nature := nature || '|' || nature_record.flg_nature;
            ELSE
                nature := nature_record.flg_nature;
            END IF;
        
        END LOOP;
        CLOSE c_nature;
        RETURN nature;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_MCDT_NATURE',
                                              o_error    => l_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN NULL;
        
    END get_mcdt_nature;

    FUNCTION get_mcdt_nature_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_nature IN VARCHAR2
    ) RETURN VARCHAR IS
    
        l_tbl_nature table_varchar;
        l_ret        VARCHAR2(4000) := NULL;
        l_error      t_error_out;
    BEGIN
    
        l_tbl_nature := pk_utils.str_split_l(i_list => i_nature, i_delim => '|');
    
        FOR i IN l_tbl_nature.first .. l_tbl_nature.last
        LOOP
            l_ret := l_ret || pk_sysdomain.get_domain('MCDT_NATURE.FLG_NATURE', l_tbl_nature(i), i_lang) || CASE
                         WHEN l_tbl_nature.count > 1
                              AND i < l_tbl_nature.count THEN
                          ', '
                     END;        
        END LOOP;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_MCDT_NATURE_DESC',
                                              o_error    => l_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN NULL;
        
    END get_mcdt_nature_desc;

    /**
    * Get MCDT's nisencao
    * apensar de um paciente ser isento pode no ser por mcdt 
    *
    * @param   i_mcdt              Id MCDT
    * @param   i_type              MCDT type: {*} 'A' Analysis
                                              {*} 'I' Image
                                              {*} 'E' Other exams
                                              {*} 'P' intervetions
                                              {*} 'F' MFR                                                                                           
    * @RETURN  Varchar 
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-08-2011
    **/
    FUNCTION get_mcdt_nisencao
    (
        i_mcdt IN mcdt_nature.id_mcdt%TYPE,
        i_type IN mcdt_nature.flg_mcdt%TYPE
    ) RETURN VARCHAR2 IS
        l_nisencao PLS_INTEGER;
        l_error    t_error_out;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_nisencao
          FROM mcdt_nisencao
         WHERE flg_available = pk_ref_constant.g_yes
           AND flg_mcdt = i_type
           AND id_mcdt = i_mcdt;
    
        IF l_nisencao = 1
        THEN
            RETURN pk_ref_constant.g_no;
        ELSE
            RETURN pk_ref_constant.g_yes;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_MCDT_NISENCAO',
                                              o_error    => l_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN pk_ref_constant.g_no;
        
    END get_mcdt_nisencao;

    /** 
    * Check if referral home is active
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_type         Referral type: {*} (C)onsultation 
                                             {*} (A)nalysis 
                                             {*} (I)mage 
                                             {*} (E)xam 
                                             {*} (P)rocedure 
                                             {*} (M)fr 
    * @param   o_home_active  Return :       {*} (Y)es if home is active
                                             {*} (N)o if home is inactive
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-09-2011
    */

    FUNCTION check_referral_home
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN p1_external_request.flg_type%TYPE,
        o_home_active OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_bdnp_available sys_config.value%TYPE;
    BEGIN
        g_error := 'Call pk_sysconfig.get_config ' || pk_ref_constant.g_ref_mcdt_bdnp;
    
        /* 
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
        
         IF l_bdnp_available = pk_ref_constant.g_yes
        THEN
            g_error  := 'Callpk_dbnp.check_referral_home ';
            g_retval := pk_bdnp.check_referral_home(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_type        => i_type,
                                                    o_home_active => o_home_active,
                                                    o_error       => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE*/
        o_home_active := pk_ref_constant.g_yes;
        /*END IF;*/
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REFERRAL_HOME',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_home;

    /**
    * Check if referral reason is mandatory
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional, institution and software ids
    * @param   i_type       Referral type: {*} (C)onsultation 
                                           {*} (A)nalysis 
                                           {*} (I)mage 
                                           {*} (E)xam 
                                           {*} (P)rocedure 
                                           {*} (M)fr
    * @param   i_home        Array with all flg_home
    * @param   i_priority    Array with all flg_prioritys
    * @param   o_reason_mandatory Return : {*} (Y)es if home is active
                                           {*} (N)o if home is inactive
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-09-2011
    */

    FUNCTION check_referral_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_type             IN p1_external_request.flg_type%TYPE,
        i_home             IN table_varchar,
        i_priority         IN table_varchar,
        o_reason_mandatory OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
        g_error          := 'Call pk_sysconfig.get_config ' || pk_ref_constant.g_ref_mcdt_bdnp;
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof), pk_ref_constant.g_no);
    
        IF i_prof.software = pk_ref_constant.g_id_soft_referral
        THEN
            --REASON IS MANDATORY IN REFERRAL 
            o_reason_mandatory := pk_ref_constant.g_yes;
        ELSE
            IF i_home.count <> i_priority.count
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_bdnp_available = pk_ref_constant.g_no
            THEN
            
                g_error            := 'Call check_reason_mandatory_cfg / i_type=' || i_type;
                o_reason_mandatory := check_reason_mandatory_cfg(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_flg_type => i_type);
            ELSE
                --bdnp available
                o_reason_mandatory := pk_ref_constant.g_no;
                FOR i IN 1 .. i_home.count
                LOOP
                    IF i_home(i) = pk_ref_constant.g_yes
                       OR i_priority(i) = pk_ref_constant.g_yes
                    THEN
                        o_reason_mandatory := pk_ref_constant.g_yes;
                    END IF;
                END LOOP;
            END IF;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REFERRAL_REASON',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_reason;

    /**
    * Check if Referral diagnosis is mandatory
    *
    * @param   I_LANG             language associated to the professional executing the request
    * @param   I_PROF             professional, institution and software ids
    * @param   o_diag_mandatory   Referral Diagnosis: {*} 'Y' Mandatory {*} 'N' Not mandatory    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-08-2013 
    */
    FUNCTION check_referral_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_diag_mandatory OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_diag_mandatory := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_diag_mandatory, i_prof),
                                pk_ref_constant.g_no);
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REFERRAL_DIAGNOSIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_diagnosis;

    /**
    * Get BDNP title
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_ref               Referral identifier
    * @param   i_id_prof_requested Professional that requested the referral
    * @param   i_flg_event         Event identifier           
    * @param   i_id_prof_requested Professional identifier that requested the referral
    *   
    * @RETURN  BDNP title
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-11-2011
    */
    FUNCTION get_bdnp_title
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ref               IN p1_external_request.id_external_request%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_flg_event         IN bdnp_presc_tracking.flg_event_type%TYPE
    ) RETURN VARCHAR2 IS
        l_message_code sys_message.code_message%TYPE;
    BEGIN
        g_error := 'Init get_bdnp_title / i_ref=' || i_ref || ' i_flg_event=' || i_flg_event;
        IF i_flg_event IN (pk_ref_constant.g_bdnp_event_type_i, pk_ref_constant.g_bdnp_event_type_ri)
        THEN
            IF i_prof.id = i_id_prof_requested
            THEN
                l_message_code := 'REF_DETAIL_BDNP_M001';
            ELSE
                l_message_code := 'REF_DETAIL_BDNP_M002'; --'Envio';
            END IF;
        
        ELSIF i_flg_event IN (pk_ref_constant.g_bdnp_event_type_c, pk_ref_constant.g_bdnp_event_type_rc)
        THEN
            IF i_prof.id = i_id_prof_requested
            THEN
                l_message_code := 'REF_DETAIL_BDNP_M003'; --'Pedido de cancelamento';
            ELSE
                l_message_code := 'REF_DETAIL_BDNP_M004'; --'Cancelamento';
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    
        RETURN pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => l_message_code);
    
    EXCEPTION
        WHEN no_data_found THEN
        
            RETURN NULL;
    END get_bdnp_title;

    /**
    * Validates if the professional can create referrals and returns labels showing the type of referrals that can be created
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer
    * @param   i_id_patient   Patient identififer
    * @param   i_external_sys External system identifier
    * @param   o_cursor       Labels showing the type of referrals that can be created  
    * @param   o_error        An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-10-2012
    */
    FUNCTION check_ref_creation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cursor       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql pk_types.cursor_type;
    
        l_id    NUMBER(24);
        l_desc  VARCHAR2(1000 CHAR);
        l_desc2 VARCHAR2(1000 CHAR);
    
        l_label_tab      table_varchar;
        l_flg_avail_tab  table_varchar;
        l_flg_status_tab table_varchar;
        l_func_tab       table_number;
        l_func           PLS_INTEGER;
        l_prof_cat       category.id_category%TYPE;
        l_ref_type       VARCHAR2(1 CHAR);
        l_label          sys_message.code_message%TYPE;
        l_pp             profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'Init get_ref_label_creation / i_id_patient=' || i_id_patient || ' i_external_sys=' ||
                   i_external_sys;
        pk_alertlog.log_debug(g_error);
        l_label_tab      := table_varchar();
        l_flg_avail_tab  := table_varchar();
        l_flg_status_tab := table_varchar();
    
        l_prof_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        IF l_prof_cat = pk_ref_constant.g_cat_id_adm -- registrar
        THEN
            l_pp := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
            IF l_pp NOT IN (pk_ref_constant.g_profile_adm_cs_vo, pk_ref_constant.g_profile_adm_hs_vo)
            THEN
                -- registrar must have sys_functionality in order to create referrals
                l_func_tab := get_prof_func_inst(i_lang => i_lang, i_prof => i_prof);
            
                <<prof_func>>
                FOR i IN 1 .. l_func_tab.count
                LOOP
                    IF l_func_tab(i) = pk_ref_constant.g_func_ref_create
                    THEN
                        l_func := 1;
                        EXIT prof_func;
                    END IF;
                END LOOP prof_func;
            
                -- check at hospital entrance referrals
                IF l_func = 1
                THEN
                    l_ref_type := pk_ref_constant.g_flg_availability_p;
                    l_label    := pk_ref_constant.g_sm_ref_h_entrance;
                END IF;
            END IF;
        ELSIF l_prof_cat = pk_ref_constant.g_cat_id_med -- physician
        THEN
            -- external referrals
            l_ref_type := pk_ref_constant.g_flg_availability_e;
            l_label    := pk_ref_constant.g_sm_ref_common_t001;
        END IF;
    
        IF l_ref_type IS NOT NULL
        THEN
            -- check if professional can create this kind of referrals
            g_error  := 'Call pk_ref_list.get_net_spec / i_pat=' || i_id_patient || ' i_ref_type=' || l_ref_type ||
                        ' i_external_sys=' || i_external_sys;
            g_retval := pk_ref_list.get_net_spec(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_pat          => i_id_patient,
                                                 i_ref_type     => l_ref_type,
                                                 i_external_sys => i_external_sys,
                                                 o_sql          => l_sql,
                                                 o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            FETCH l_sql
                INTO l_id, l_desc, l_desc2;
            CLOSE l_sql;
        
            l_label_tab.extend;
            l_flg_avail_tab.extend;
            l_flg_status_tab.extend;
        
            l_label_tab(l_label_tab.last) := l_label; -- label to be shown
            l_flg_avail_tab(l_flg_avail_tab.last) := l_ref_type;
        
            g_error := g_error || ' l_id=' || l_id;
            IF l_id IS NOT NULL -- data returned
            THEN
                l_flg_status_tab(l_flg_status_tab.last) := pk_ref_constant.g_active;
            ELSE
                l_flg_status_tab(l_flg_status_tab.last) := pk_ref_constant.g_inactive;
            END IF;
        END IF;
    
        -- check if professional can create internal referrals
        IF l_prof_cat = pk_ref_constant.g_cat_id_med -- physician
        THEN
            l_id     := NULL;
            l_desc   := NULL;
            l_desc2  := NULL;
            g_error  := 'Call pk_ref_list.get_internal_dep / i_pat=' || i_id_patient || ' i_external_sys=' ||
                        i_external_sys;
            g_retval := pk_ref_list.get_internal_dep(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_pat          => i_id_patient,
                                                     i_external_sys => i_external_sys,
                                                     o_dep          => l_sql,
                                                     o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            FETCH l_sql
                INTO l_id, l_desc, l_desc2;
            CLOSE l_sql;
        
            l_label_tab.extend;
            l_flg_avail_tab.extend;
            l_flg_status_tab.extend;
        
            l_label_tab(l_label_tab.last) := pk_ref_constant.g_sm_ref_common_t002; -- internal referral
            l_flg_avail_tab(l_flg_avail_tab.last) := pk_ref_constant.g_flg_availability_i;
        
            g_error := g_error || ' l_id=' || l_id;
            IF l_id IS NOT NULL -- data returned
            THEN
                l_flg_status_tab(l_flg_status_tab.last) := pk_ref_constant.g_active;
            ELSE
                l_flg_status_tab(l_flg_status_tab.last) := pk_ref_constant.g_inactive;
            END IF;
        END IF;
    
        g_error := 'OPEN o_cursor FOR / l_label_tab.count=' || l_label_tab.count || ' l_flg_avail_tab.count=' ||
                   l_flg_avail_tab.count || ' l_flg_status_tab.count=' || l_flg_status_tab.count;
        OPEN o_cursor FOR
            SELECT pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => t_label.column_value) label_desc,
                   t_flg_avail.column_value flg_availability,
                   t_flg_sts.column_value flg_status
              FROM (SELECT rownum r, column_value
                      FROM TABLE(CAST(l_label_tab AS table_varchar))) t_label
              JOIN (SELECT rownum r, column_value
                      FROM TABLE(CAST(l_flg_avail_tab AS table_varchar))) t_flg_avail
                ON (t_label.r = t_flg_avail.r)
              JOIN (SELECT rownum r, column_value
                      FROM TABLE(CAST(l_flg_status_tab AS table_varchar))) t_flg_sts
                ON (t_label.r = t_flg_sts.r);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_CREATION',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END check_ref_creation;

    /**
    * Returns sibling institutions that has the same parent of type 'H'
    * Returns self instituion if i_flg_slef is set to 'Y'
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer  
    * @param   i_flg_slef     Flag indicating if returns self instituion or not
    *
    * @return  TRUE array of sibling institutions    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2012
    */
    FUNCTION get_sibling_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_slef IN VARCHAR2 DEFAULT pk_ref_constant.g_no
    ) RETURN table_number IS
    BEGIN
        g_error := 'Init get_sibling_inst / i_prof=' || pk_utils.to_string(i_prof);
        RETURN get_sibling_inst(i_id_institution => i_prof.institution, i_flg_slef => i_flg_slef);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN table_number();
    END get_sibling_inst;

    /**
    * Returns sibling institutions that has the same parent of type 'H'
    * Returns self instituion if i_flg_slef is set to 'Y'
    *
    * @param   i_id_institution  Institution identififer  
    * @param   i_flg_slef        Flag indicating if returns self instituion or not
    *
    * @return  TRUE array of sibling institutions    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2012
    */
    FUNCTION get_sibling_inst
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_slef       IN VARCHAR2 DEFAULT pk_ref_constant.g_no
    ) RETURN table_number IS
        CURSOR c_sib_inst(x_id_inst IN institution.id_institution%TYPE) IS
            SELECT sib.id_institution
              FROM institution son
              JOIN institution par
                ON (son.id_parent = par.id_institution)
              JOIN institution sib
                ON (par.id_institution = sib.id_parent)
             WHERE son.id_institution = x_id_inst
               AND par.flg_type = pk_ref_constant.g_hospital
               AND sib.id_institution != son.id_institution
            UNION ALL
            SELECT x_id_inst
              FROM dual
             WHERE i_flg_slef = pk_ref_constant.g_yes;
    
        l_inst_tab table_number;
    BEGIN
        g_error := 'Init get_sibling_inst / i_id_institution=' || i_id_institution;
        OPEN c_sib_inst(i_id_institution);
        FETCH c_sib_inst BULK COLLECT
            INTO l_inst_tab;
        CLOSE c_sib_inst;
    
        RETURN l_inst_tab;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN table_number();
    END get_sibling_inst;

    /**
    * Returns child institutions 
    *
    * @param   i_id_institution  Institution identififer  
    * @param   i_flg_slef        Flag indicating if returns self instituion or not
    *
    * @return  TRUE array of sibling institutions    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-05-2013
    */
    FUNCTION get_child_inst(i_id_institution IN institution.id_institution%TYPE) RETURN table_number IS
        CURSOR c_child_inst(x_id_inst IN institution.id_institution%TYPE) IS
            SELECT i.id_institution
              FROM institution i
             WHERE i.id_parent = x_id_inst;
    
        l_inst_tab table_number;
    BEGIN
        g_error := 'Init get_child_inst / i_id_institution=' || i_id_institution;
        OPEN c_child_inst(i_id_institution);
        FETCH c_child_inst BULK COLLECT
            INTO l_inst_tab;
        CLOSE c_child_inst;
    
        RETURN l_inst_tab;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN table_number();
    END get_child_inst;

    /**
    * Get last referral active detail for a given type
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional id, institution and software
    * @param   I_PAT            Patient identifier
    * @param   I_FLG_TYPE       Detail type
    * @param   O_DETAIL_TEXT    Detail description 
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   13-02-2013
    **/

    FUNCTION get_ref_last_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_flg_type    IN table_varchar,
        o_detail_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Open o_detail_text I_PAT=' || i_pat;
        OPEN o_detail_text FOR
            SELECT tt.flg_type, tt.text
              FROM (SELECT pd.flg_type,
                           pd.text,
                           row_number() over(PARTITION BY pd.flg_type ORDER BY per.dt_requested DESC) num,
                           per.dt_requested
                      FROM p1_detail pd
                      JOIN p1_external_request per
                        ON (pd.id_external_request = per.id_external_request)
                      JOIN TABLE(i_flg_type) t
                        ON (t.column_value = pd.flg_type)
                     WHERE per.flg_status NOT IN (pk_ref_constant.g_p1_status_o)
                       AND per.id_patient = i_pat
                       AND pd.flg_status = pk_ref_constant.g_detail_status_a
                       AND (pd.id_institution = i_prof.institution OR pd.id_professional = i_prof.id)) tt
             WHERE tt.num = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail_text);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_LAST_DETAIL',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ref_last_detail;

    /**
    * Gets the last comment read of a given professional
    * If professional not specified, returns the last comment read of any professional.
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    * @param   i_ref       Referral identifier
    * @param   i_id_prof   Professional identifier that is being checked. If null, returns the last comment read of any professional.
    * @param   i_flg_type  Referral comments type
    *
    * @value   i_flg_type  {*} 'A'- administrative type {*} 'C'- clinical type
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2013
    */
    FUNCTION get_last_comment_read
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ref      IN p1_external_request.id_external_request%TYPE,
        i_id_prof  IN professional.id_professional%TYPE,
        i_flg_type IN ref_comments.flg_type%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_dt_comment_read ref_comments_read.dt_comment_read%TYPE;
        l_error           t_error_out;
    
        --CURSOR c_read IS
        --    SELECT t.dt_comment_read
        --      FROM (SELECT row_number() over(ORDER BY rcr.dt_comment_read DESC) my_row, rcr.dt_comment_read
        --              FROM ref_comments rc
        --              JOIN ref_comments_read rcr
        --                ON (rcr.id_ref_comment = rc.id_ref_comment)
        --             WHERE rc.flg_status = pk_ref_constant.g_active_comment
        --               AND rc.flg_type = i_flg_type
        --               AND rc.id_external_request = i_ref
        --               AND rcr.id_professional = nvl(i_id_prof, rcr.id_professional)) t
        --     WHERE t.my_row = 1;
    
        CURSOR c_read IS -- if professional has no reads and if he was the comment creator, assume creation time
            SELECT CASE
                       WHEN rcr.id_professional IS NOT NULL THEN
                        rcr.dt_comment_read -- the most recent read
                       WHEN rc.id_professional = nvl(i_id_prof, rc.id_professional) THEN
                        rc.dt_comment -- it was the professional that created the comment that is the most recent read
                       ELSE
                        NULL -- professional never read the comment
                   END
              FROM ref_comments rc
              LEFT JOIN ref_comments_read rcr
                ON (rcr.id_ref_comment = rc.id_ref_comment AND
                   rcr.id_professional = nvl(i_id_prof, rcr.id_professional))
             WHERE rc.flg_status = pk_ref_constant.g_active_comment
               AND rc.flg_type = i_flg_type
               AND rc.id_external_request = i_ref
             ORDER BY 1 DESC NULLS LAST; -- important to get the most recent record                 
    
    BEGIN
    
        OPEN c_read;
        FETCH c_read
            INTO l_dt_comment_read; -- fetching once, gets the most recent record
        CLOSE c_read;
    
        RETURN l_dt_comment_read;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LAST_COMMENT_READ',
                                              o_error    => l_error);
        
            RETURN NULL;
    END get_last_comment_read;

    /**
    * Crate new Referral comment
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_dt_comment     Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION create_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_dt_comment     IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_data      t_rec_prof_data;
        l_params         VARCHAR2(1000 CHAR);
        l_id_ref_comment table_number;
    BEGIN
    
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
    
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => NULL,
                                  o_prof_data => l_prof_data,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Calling pk_ref_api.set_ref_comments / ' || l_params;
        g_retval := pk_ref_api.set_ref_comments(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_prof_data      => l_prof_data,
                                                i_id_ref         => i_id_ref,
                                                i_id_ref_comment => NULL,
                                                i_text           => i_text,
                                                i_flg_status     => pk_ref_constant.g_active_comment,
                                                i_dt_comment     => i_dt_comment,
                                                o_id_ref_comment => l_id_ref_comment,
                                                o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_id_ref_comment := l_id_ref_comment(1);
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
                                              i_function => 'CREATE_REF_COMMENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_ref_comment;
    /**
    * Cancel Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_cancel      Cancel Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION cancel_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_cancel      IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_data      t_rec_prof_data;
        l_params         VARCHAR2(1000 CHAR);
        l_id_ref_comment table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref || ' i_id_ref_comment=' ||
                    i_id_ref_comment || ' i_dt_cancel=' || i_dt_cancel;
    
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => NULL,
                                  o_prof_data => l_prof_data,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Calling pk_ref_api.set_ref_comments / ' || l_params;
        g_retval := pk_ref_api.set_ref_comments(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_prof_data      => l_prof_data,
                                                i_id_ref         => i_id_ref,
                                                i_id_ref_comment => i_id_ref_comment,
                                                i_text           => NULL,
                                                i_flg_status     => pk_ref_constant.g_canceled_comment,
                                                i_dt_comment     => i_dt_cancel,
                                                o_id_ref_comment => l_id_ref_comment,
                                                o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_id_ref_comment := l_id_ref_comment(1);
    
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
                                              i_function => 'CANCEL_REF_COMMENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_ref_comment;
    /**
    * Edit Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_edit        Edit comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION edit_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_edit        IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_data t_rec_prof_data;
        l_params    VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref;
    
        g_error  := 'Calling get_prof_data / ' || l_params;
        g_retval := get_prof_data(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_dcs       => NULL,
                                  o_prof_data => l_prof_data,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Calling pk_ref_api.set_ref_comments / ' || l_params;
        g_retval := pk_ref_api.set_ref_comments(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_prof_data      => l_prof_data,
                                                i_id_ref         => i_id_ref,
                                                i_id_ref_comment => i_id_ref_comment,
                                                i_text           => i_text,
                                                i_flg_status     => pk_ref_constant.g_outdated_comment,
                                                i_dt_comment     => i_dt_edit,
                                                o_id_ref_comment => o_id_ref_comment,
                                                o_error          => o_error);
    
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
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EDIT_REF_COMMENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END edit_ref_comment;

    /**
    * Gets Referral comments info
    * Function used by pagination grids
    *
    * @param   i_lang                       Language associated to the professional executing the request
    * @param   i_prof                       Professional id, institution and software
    * @param   i_prof_data                  Professional id_profile_template, id_functionality, id_category, flg_category, id_market
    * @param   i_ref                        Referral identifier
    * @param   i_id_workflow                Referral workflow identifier
    * @param   i_id_prof_requested          Professional identifier that is responsible for the referral
    * @param   i_id_inst_orig               Referral orig institution identifier
    * @param   i_id_inst_dest               Referral dest institution identifier
    * @param   i_id_dcs                     Referral dep_clin_serv identifier
    * @param   i_dt_last_comment            Last comment date
    * @param   i_comment_count              Number of comments
    * @param   i_prof_comment               Professional that created the last comment    
    * @param   i_inst_comment               Institution where the last comment was created
    *
    * @RETURN  t_rec_ref_comments_info
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION get_ref_comments_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_prof_data         IN t_rec_prof_data,
        i_ref               IN p1_external_request.id_external_request%TYPE,
        i_id_workflow       IN p1_external_request.id_workflow%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest      IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_dt_last_comment   IN ref_comments.dt_comment%TYPE,
        i_comment_count     IN NUMBER,
        i_prof_comment      IN ref_comments.id_professional%TYPE,
        i_inst_comment      IN ref_comments.id_institution%TYPE
    ) RETURN t_rec_ref_comments_info IS
        l_my_last_read ref_comments_read.dt_comment_read%TYPE;
        l_flg_type     ref_comments.flg_type%TYPE;
        l_check_date   VARCHAR2(1 CHAR);
        l_flg_receiver VARCHAR2(1 CHAR);
        l_result       t_rec_ref_comments_info;
        l_params       VARCHAR2(1000 CHAR);
    
        /**
        * function that sets the result if comment has not been read yet (by the professional)
        */
        PROCEDURE set_comment_not_read IS
        BEGIN
            l_result.val      := i_comment_count;
            l_result.shortcut := pk_ref_constant.g_shortcut_detail;
            l_result.bg_color := pk_ref_constant.g_bg_color_contessa;
            l_result.status   := pk_ref_constant.g_yes;
            l_result.fg_color := pk_ref_constant.g_fg_color_yellow;
        END set_comment_not_read;
    
        /**
        * function that sets the result if comment has been read by the professional
        */
        PROCEDURE set_comment_read IS
        BEGIN
            l_result.val      := i_comment_count;
            l_result.shortcut := pk_ref_constant.g_shortcut_detail;
            l_result.bg_color := NULL;
            l_result.status   := pk_ref_constant.g_no;
            l_result.fg_color := pk_ref_constant.g_fg_color_yellow;
            --l_result.fg_color := pk_ref_constant.g_fg_color_granite_green;
        END set_comment_read;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_prof_data=' || pk_ref_utils.to_string(i_prof_data) ||
                    ' i_ref=' || i_ref || ' i_wf=' || i_id_workflow || ' i_id_prof_requested=' || i_id_prof_requested ||
                    ' i_id_inst_orig=' || i_id_inst_orig || ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_dcs=' ||
                    i_id_dcs || ' i_comment_count=' || i_comment_count || ' i_prof_comment=' || i_prof_comment ||
                    ' i_inst_comment=' || i_inst_comment;
        g_error  := 'Init get_ref_comments_info / ' || l_params;
        l_result := t_rec_ref_comments_info();
    
        IF i_comment_count IS NULL
           OR i_comment_count = 0
           OR i_dt_last_comment IS NULL
        THEN
            -- there are no comments
            l_result.val      := NULL;
            l_result.bg_color := NULL;
            --l_result.fg_color := NULL;
            l_result.shortcut := pk_ref_constant.g_shortcut_detail;
            l_result.status   := pk_ref_constant.g_no;
        
        ELSIF i_prof_data.id_profile_template IN
              (pk_ref_constant.g_profile_adm_cs_vo, pk_ref_constant.g_profile_adm_hs_vo)
        THEN
            -- view only
            set_comment_read; -- behaviour as if the comments were read by the professional
        ELSE
            -- there are comments
            g_error := 'Check type of coment / ' || l_params;
            IF i_prof_data.id_category = pk_ref_constant.g_cat_id_med
            THEN
                l_flg_type := pk_ref_constant.g_clinical_comment;
            ELSE
                l_flg_type := pk_ref_constant.g_administrative_comment;
            END IF;
        
            -- check if professional is one of the professional comment receivers
            g_error        := 'Call check_comm_receiver / ' || l_params;
            l_flg_receiver := check_comm_receiver(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_cat            => i_prof_data.id_category,
                                                  i_id_workflow       => i_id_workflow,
                                                  i_id_prof_requested => i_id_prof_requested,
                                                  i_id_inst_orig      => i_id_inst_orig,
                                                  i_id_inst_dest      => i_id_inst_dest,
                                                  i_id_dcs            => i_id_dcs,
                                                  i_flg_type_comm     => l_flg_type,
                                                  --i_id_prof_comm      => i_prof_comment,
                                                  i_id_inst_comm => i_inst_comment);
        
            l_params := l_params || ' l_flg_receiver=' || l_flg_receiver;
        
            g_error := 'IF l_flg_receiver / ' || l_params;
            IF l_flg_receiver = pk_ref_constant.g_no
            THEN
                set_comment_read; -- behaviour as if the comments were read by the professional
            ELSE
            
                g_error        := 'Call get_last_comment_read / ' || l_params;
                l_my_last_read := get_last_comment_read(i_lang     => i_lang,
                                                        i_prof     => i_prof,
                                                        i_ref      => i_ref,
                                                        i_id_prof  => i_prof.id,
                                                        i_flg_type => l_flg_type);
            
                -- check if professional has read the comment
                IF l_my_last_read IS NOT NULL
                THEN
                    g_error      := 'Call pk_date_utils.compare_dates_tsz / I_DATE2=' || l_my_last_read || ' / ' ||
                                    l_params;
                    l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                    i_date1 => i_dt_last_comment,
                                                                    i_date2 => l_my_last_read);
                
                    IF l_check_date = pk_ref_constant.g_date_greater
                    THEN
                        set_comment_not_read;
                    ELSE
                        set_comment_read;
                    END IF;
                ELSE
                    -- professional has no comment reads for this referral
                    g_error := 'Read not found / ' || l_params;
                    IF i_prof_comment != i_prof.id
                    THEN
                        set_comment_not_read;
                    ELSE
                        set_comment_read;
                    END IF;
                END IF;
            END IF;
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := 'get_ref_comments_info / ' || 'I_REF=' || i_ref || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_ref_comments_info;

    /**
    * Checks if the professional is one of the comment receivers
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software
    * @param   i_id_cat             Professional category identifier
    * @param   i_id_workflow        Referral identifier
    * @param   i_id_prof_requested  Professional that is responsible for the referral   
    * @param   i_id_inst_orig       Referral orig institution identifier
    * @param   i_id_inst_dest       Referral dest institution identifier    
    * @param   i_id_dcs             Referral dep_clin_serv identifier
    * @param   i_flg_type_comm      Referral comment type
    * @param   i_id_inst_comm       Institution identifier where the comment was done   
    *
    * @value   i_flg_type_comm      'C'- clinical, 'A'- administrative
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-01-2014
    */
    FUNCTION check_comm_receiver
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cat            IN prof_cat.id_category%TYPE,
        i_id_workflow       IN p1_external_request.id_workflow%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest      IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_type_comm     IN ref_comments.flg_type%TYPE,
        i_id_inst_comm      IN ref_comments.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1 CHAR);
        l_error  t_error_out;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_cat=' || i_id_cat || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_prof_requested=' || i_id_prof_requested || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_dcs=' || i_id_dcs ||
                    ' i_flg_type_comm=' || i_flg_type_comm || ' i_id_inst_comm=' || i_id_inst_comm;
        g_error  := 'Init check_comm_receiver / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        IF (i_flg_type_comm = pk_ref_constant.g_administrative_comment AND i_id_cat = pk_ref_constant.g_cat_id_adm)
           OR (i_flg_type_comm = pk_ref_constant.g_clinical_comment AND i_id_cat = pk_ref_constant.g_cat_id_med)
        THEN
        
            g_error := 'i_id_workflow / ' || l_params;
            CASE i_id_workflow
                WHEN pk_ref_constant.g_wf_x_hosp THEN
                    -- this workflow does not have comments
                    l_result := pk_ref_constant.g_no;
                
                WHEN pk_ref_constant.g_wf_srv_srv THEN
                
                    g_error  := 'Call check_prof_orig 1 / ' || l_params;
                    l_result := check_prof_orig(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_cat            => i_id_cat,
                                                i_id_prof_requested => i_id_prof_requested,
                                                i_id_inst_orig      => i_id_inst_orig);
                
                    IF l_result = pk_ref_constant.g_no
                    THEN
                        g_error  := 'Call check_prof_dest 1 / ' || l_params;
                        l_result := check_prof_dest(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_cat            => i_id_cat,
                                                    i_id_prof_requested => i_id_prof_requested,
                                                    i_id_inst_dest      => i_id_inst_dest,
                                                    i_id_dcs            => i_id_dcs);
                    END IF;
                
                ELSE
                    -- all other workflows                
                    CASE i_id_inst_comm -- institution where the comment was done
                        WHEN i_id_inst_orig THEN
                            g_error  := 'Call check_prof_dest / ' || l_params;
                            l_result := check_prof_dest(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_cat            => i_id_cat,
                                                        i_id_prof_requested => i_id_prof_requested,
                                                        i_id_inst_dest      => i_id_inst_dest,
                                                        i_id_dcs            => i_id_dcs);
                        WHEN i_id_inst_dest THEN
                            g_error  := 'Call check_prof_orig / ' || l_params;
                            l_result := check_prof_orig(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_cat            => i_id_cat,
                                                        i_id_prof_requested => i_id_prof_requested,
                                                        i_id_inst_orig      => i_id_inst_orig);
                        ELSE
                            NULL;
                    END CASE;
                
            END CASE;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN l_result;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_COMM_RECEIVER',
                                              o_error    => l_error);
            RETURN l_result;
    END check_comm_receiver;

    /**
    * Checks if the professional can create the comment
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software
    * @param   i_id_cat             Professional category identifier
    * @param   i_id_workflow        Referral identifier
    * @param   i_id_prof_requested  Professional that is responsible for the referral
    * @param   i_id_inst_orig       Referral orig institution identifier
    * @param   i_id_inst_dest       Referral dest institution identifier    
    * @param   i_id_dcs             Referral dep_clin_serv identifier   
    * @param   i_flg_comm_available Flag indicating if comments funcionality is available at both institutions (orig and dest)
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-01-2014
    */
    FUNCTION check_comm_create
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_cat             IN prof_cat.id_category%TYPE,
        i_id_workflow        IN p1_external_request.id_workflow%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs             IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_comm_available IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1 CHAR);
        l_error  t_error_out;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_cat=' || i_id_cat || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_prof_requested=' || i_id_prof_requested || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_dcs=' || i_id_dcs ||
                    ' i_flg_comm_available=' || i_flg_comm_available;
        g_error  := 'Init check_comm_create / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        g_error := 'i_flg_comm_available / ' || l_params;
        IF i_flg_comm_available = pk_ref_constant.g_yes
        THEN
        
            CASE i_id_workflow
                WHEN pk_ref_constant.g_wf_x_hosp THEN
                    -- this workflow does not have comments
                    l_result := pk_ref_constant.g_no;
                
                WHEN pk_ref_constant.g_wf_srv_srv THEN
                
                    g_error  := 'Call check_prof_orig 1 / ' || l_params;
                    l_result := check_prof_orig(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_cat            => i_id_cat,
                                                i_id_prof_requested => i_id_prof_requested,
                                                i_id_inst_orig      => i_id_inst_orig);
                
                    IF l_result = pk_ref_constant.g_no
                    THEN
                        g_error  := 'Call check_prof_dest 1 / ' || l_params;
                        l_result := check_prof_dest(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_cat            => i_id_cat,
                                                    i_id_prof_requested => i_id_prof_requested,
                                                    i_id_inst_dest      => i_id_inst_dest,
                                                    i_id_dcs            => i_id_dcs);
                    END IF;
                
                ELSE
                    -- all other workflows                
                    IF i_prof.institution = i_id_inst_orig
                    THEN
                        g_error  := 'Call check_prof_orig 2 / ' || l_params;
                        l_result := check_prof_orig(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_cat            => i_id_cat,
                                                    i_id_prof_requested => i_id_prof_requested,
                                                    i_id_inst_orig      => i_id_inst_orig);
                    
                    ELSIF i_prof.institution = i_id_inst_dest
                    THEN
                        g_error  := 'Call check_prof_dest 2 / ' || l_params;
                        l_result := check_prof_dest(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_cat            => i_id_cat,
                                                    i_id_prof_requested => i_id_prof_requested,
                                                    i_id_inst_dest      => i_id_inst_dest,
                                                    i_id_dcs            => i_id_dcs);
                    END IF;
            END CASE;
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_ref_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_COMM_CREATE',
                                              o_error    => l_error);
            RETURN pk_ref_constant.g_no;
    END check_comm_create;

    /**
    * Checks if the referral can be re-sent to BDNP
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    * @param   i_ref             Referral identifier
    * @param   i_flg_status      Referral status
    * @param   i_flg_migrated    Referral migrated status
    * @param   i_bdnp_available  Flag indicating if BDNP is available
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-11-2011
    */
    FUNCTION can_sent
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref            IN p1_external_request.id_external_request%TYPE,
        i_flg_status     IN p1_external_request.flg_status%TYPE,
        i_flg_migrated   IN p1_external_request.flg_migrated%TYPE,
        i_bdnp_available IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_bdnp_available VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'Init can_sent / i_ref=' || i_ref || ' i_flg_status=' || i_flg_status || ' i_flg_migrated=' ||
                   i_flg_migrated || ' i_bdnp_available=' || i_bdnp_available;
    
        IF i_bdnp_available IS NULL
        THEN
            l_bdnp_available := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                                i_id_sys_config => pk_ref_constant.g_ref_mcdt_bdnp),
                                    pk_ref_constant.g_no);
        ELSE
            l_bdnp_available := i_bdnp_available;
        END IF;
    
        IF l_bdnp_available = pk_ref_constant.g_no
        THEN
            RETURN pk_ref_constant.g_no;
        ELSE
            g_error := 'OPEN c_cur / i_ref=' || i_ref || ' i_flg_status=' || i_flg_status || ' i_flg_migrated=' ||
                       i_flg_migrated || ' l_bdnp_available=' || l_bdnp_available;
            IF i_flg_status IN (pk_ref_constant.g_p1_status_p, pk_ref_constant.g_p1_status_c)
               AND i_flg_migrated IN (pk_ref_constant.g_bdnp_msg_e) --, pk_ref_constant.g_bdnp_msg_n
            THEN
                RETURN pk_ref_constant.g_yes;
            ELSE
                RETURN pk_ref_constant.g_no;
            END IF;
        
        END IF;
    
        RETURN pk_ref_constant.g_no;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_ref_constant.g_no;
    END can_sent;

    /**
    * Decodes sys_config 'REF_REASON_NOT_MANDATORY': returns 'Y' if reason is mandatory, 'N' otherwise
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   i_flg_type  Referral type
    *
    * @value   i_flg_type  {*} (C)onsultation {*} (A)nalysis {*} (I)mage {*} (E)xam {*} (P)rocedure {*} M(F)r
    *
    * @RETURN  'Y' if reason is mandatory, 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-09-2013
    */
    FUNCTION check_reason_mandatory_cfg
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN p1_external_request.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ref_reason_not_mandatory sys_config.value%TYPE;
        l_params                   VARCHAR2(1000 CHAR);
        l_result                   VARCHAR2(1 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_flg_type=' || i_flg_type;
        g_error  := 'Init check_reason_mandatory_cfg / ' || l_params;
        l_result := pk_ref_constant.g_no;
    
        l_ref_reason_not_mandatory := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_reason_not_mandatory, i_prof),
                                          '0');
    
        IF instr(l_ref_reason_not_mandatory, i_flg_type) = 0 -- flg_type is not in sys_config, indicates that reason is mandatory
        THEN
            l_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN pk_ref_constant.g_no;
    END check_reason_mandatory_cfg;

    /**
    * Gets shortcut to clinical documents
    *
    * @param   i_lang  Language associated to the professional executing the request
    * @param   i_prof  Professional id, institution and software
    *
    * @RETURN  Shortcut id 
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-07-2013
    **/
    FUNCTION get_documents_shortcut
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_ref_constant.g_shortcut_clin_doc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_documents_shortcut;

    /**
    * Checks if comments funcionality is enabled in both institution: orig and dest
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_inst_orig   Referral orig institution identifier
    * @param   i_id_inst_dest   Referral dest institution identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  'Y'- config is enabled, 'N' - otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2012-01-13
    */
    FUNCTION check_comm_enabled
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE
    ) RETURN VARCHAR2 IS
        l_enabled                 VARCHAR2(1 CHAR);
        l_comments_available_dest sys_config.value%TYPE;
        l_comments_available_orig sys_config.value%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error                   := 'Init check_comm_enabled / i_id_inst_orig=' || i_id_inst_orig ||
                                     ' i_id_inst_dest=' || i_id_inst_dest;
        l_comments_available_dest := pk_sysconfig.get_config(pk_ref_constant.g_ref_comments_available,
                                                             profissional(NULL, i_id_inst_dest, i_prof.software));
        l_comments_available_orig := pk_sysconfig.get_config(pk_ref_constant.g_ref_comments_available,
                                                             profissional(NULL, i_id_inst_orig, i_prof.software));
    
        IF l_comments_available_dest = l_comments_available_orig
           AND l_comments_available_orig = pk_ref_constant.g_yes
        THEN
            l_enabled := pk_ref_constant.g_yes;
        ELSE
            l_enabled := pk_ref_constant.g_no;
        END IF;
    
        RETURN l_enabled;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN pk_ref_constant.g_no;
    END check_comm_enabled;

    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_family_relat OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
          PURPOSE :   Possible Family Relationships filtering by gender
          PARAMETERS:  IN:  I_LANG - User Selected language
                I_PROF - User
                                I_PATIENT - Patient ID
                        OUT:    O_FAMILY_RELAT - Return of the possible relationships
                                O_ERROR - Error
          CREATION : RdSN 2006/10/13
              NOTES:
        *********************************************************************************/
    
    BEGIN
    
        OPEN o_family_relat FOR
            SELECT fr.id_family_relationship id_fr,
                   pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_fr
              FROM family_relationship fr
             WHERE fr.flg_available = 'Y'
             ORDER BY pk_translation.get_translation(i_lang, fr.code_family_relationship);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_FAMILY', 'GET_FAMILY_RELATIONSHIPS');
            
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy
                pk_types.open_my_cursor(o_family_relat);
                RETURN FALSE;
            
            END;
        
    END;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_core;
/
