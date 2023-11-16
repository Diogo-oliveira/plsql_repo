/*-- Last Change Revision: $Rev: 2027418 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_auto_complete AS

    g_retval BOOLEAN;
    g_found  BOOLEAN;
    g_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    g_package_name  VARCHAR2(30) := 'PK_P1_AUTO_COMPLETE';
    g_package_owner VARCHAR2(50) := 'ALERT';

    g_sim                 CONSTANT VARCHAR(1 CHAR) := 'S';
    g_max_text_field_size CONSTANT NUMBER := 4000;

    CURSOR c_prof
    (
        x_i institution.ext_code%TYPE,
        x_p professional.num_order%TYPE
    ) IS
        SELECT p.id_professional, i.id_institution
          FROM professional p, institution i, prof_institution pi, ab_user_info su
         WHERE p.num_order = x_p
           AND p.flg_state = pk_ref_constant.g_active
           AND i.ext_code = x_i
           AND p.id_professional = su.id_ab_user_info
           AND p.id_professional = pi.id_professional
           AND i.id_institution = pi.id_institution
           AND pi.flg_state = pk_ref_constant.g_active
           AND pi.dt_end_tstz IS NULL;

    /**
    * Validates if user is active
    *
    * @param   i_inst_code   institution.ext_code%TYPE,
    * @param   i_prof_number professional.num_order%TYPE,
    * @param   i_pass        VARCHAR2,
    * @param   o_error error
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   10-12-2007
    */
    FUNCTION validate_user
    (
        i_inst_code   institution.ext_code%TYPE,
        i_prof_number professional.num_order%TYPE,
        i_pass        VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof professional.id_professional%TYPE;
        l_inst institution.id_institution%TYPE;
        l_soft software.id_software%TYPE;
        l_pass VARCHAR2(2000);
        l_lang language.id_language%TYPE := 1;
    BEGIN
    
        g_error := 'OPEN c_prof';
        OPEN c_prof(i_inst_code, i_prof_number);
        FETCH c_prof
            INTO l_prof, l_inst;
        g_found := c_prof%FOUND;
        CLOSE c_prof;
    
        IF NOT g_found
        THEN
            g_error := 'User ' || i_prof_number || ' not found in institution ' || i_inst_code;
            RAISE g_exception;
        END IF;
    
        g_error := 'Get SOFTWARE_ID_P1';
        SELECT pk_sysconfig.get_config('SOFTWARE_ID_P1', profissional(l_prof, l_inst, 0))
          INTO l_soft
          FROM dual;
    
        IF l_soft IS NULL
        THEN
            g_error := 'Parameter SOFTWARE_ID_P1 not found';
            RAISE g_exception;
        END IF;
    
        g_error := 'Get P1_AUTO_LOGIN_PASS';
        SELECT pk_sysconfig.get_config('P1_AUTO_LOGIN_PASS', profissional(l_prof, l_inst, l_soft))
          INTO l_pass
          FROM dual;
    
        IF l_pass IS NULL
        THEN
            g_error := 'Parameter P1_AUTO_LOGIN_PASS not found';
            RAISE g_exception;
        END IF;
    
        IF l_pass = i_pass
        THEN
            RETURN TRUE;
        ELSE
            g_error := 'Utilizador invalido. Password incorrecta: ' || i_pass;
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => l_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'VALIDATE_USER',
                                                     o_error    => o_error);
    END validate_user;

    /**
    * Return patient data
    *
    * @param   i_lang external request id
    * @param   i_id_ext_req external request id
    * @param   o_data patient data
    * @param   o_health_plan patient health plans    
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   11-12-2007
    */
    FUNCTION get_patient_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_session  IN VARCHAR2,
        o_data        OUT pk_types.cursor_type,
        o_health_plan OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_inst(x institution.ext_code%TYPE) IS
            SELECT id_institution
              FROM institution i
             WHERE i.ext_code = x
               AND i.flg_available = pk_ref_constant.g_yes;
    
        CURSOR c_match
        (
            x_i institution.id_institution%TYPE,
            x_s p1_match.sequential_number%TYPE
        ) IS
            SELECT id_patient
              FROM p1_match m
             WHERE m.id_institution = x_i
               AND m.sequential_number = x_s
               AND m.flg_status = pk_ref_constant.g_match_status_a;
    
        l_i_code       institution.ext_code%TYPE;
        l_order_number professional.num_order%TYPE;
        l_seq_number   p1_match.sequential_number%TYPE;
    
        l_id_institution institution.id_institution%TYPE;
        l_id_patient     patient.id_patient%TYPE := NULL;
    BEGIN
    
        g_error := 'Init get_patient_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        -----------------------------------------------
    
        g_error := 'Call interface_p1.pk_p1_url.get_session_data';
        /*
        -- CMF OPSDEV-1073
        g_retval := interface_p1.pk_p1_url.get_session_data(i_id_session,
                                                            l_i_code,
                                                            l_order_number,
                                                            l_seq_number,
                                                            g_error);
        */
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'open c_inst';
        OPEN c_inst(l_i_code);
        FETCH c_inst
            INTO l_id_institution;
        g_found := c_inst%FOUND;
        CLOSE c_inst;
    
        IF NOT g_found
        THEN
            g_error := 'No institution found for ext_code: ' || l_i_code;
            RAISE g_exception;
        END IF;
    
        g_error := 'open c_match';
        OPEN c_match(l_id_institution, l_seq_number);
        FETCH c_match
            INTO l_id_patient;
        CLOSE c_match;
    
        g_error := 'OPEN o_data';
        OPEN o_data FOR
        -- cmf OPSDEV-1073
            SELECT NULL id_patient,
                   NULL name,
                   NULL gender,
                   NULL gender_desc,
                   NULL dt_birth,
                   NULL isencao,
                   NULL isencao_desc,
                   NULL recm,
                   NULL recm_desc,
                   NULL num_main_contact,
                   NULL address,
                   NULL zip_code,
                   NULL location,
                   NULL district,
                   NULL district_desc,
                   NULL country_address,
                   NULL country_address_desc,
                   NULL marital_status,
                   NULL marital_status_desc,
                   NULL scholarship,
                   NULL scholarship_desc,
                   NULL occupation,
                   NULL occupation_desc, -- ACM, 2010-05-25: ALERT-100182
                   NULL job_status,
                   NULL job_status_desc,
                   NULL father_name,
                   NULL mother_name,
                   NULL sns_number
              FROM dual;
        /*
         -- cmf OPSDEV-1073
        SELECT l_id_patient id_patient,
               name,
               sex gender,
               pk_sysdomain.get_domain('PATIENT.GENDER', sex, i_lang) gender_desc,
               get_date_str(birth_date_year, birth_date_month, birth_date_day) dt_birth,
               decode(exemption_type, -1, NULL, exemption_type) isencao,
               pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || exemption_type) isencao_desc,
               decode(recm, -1, NULL, recm) recm,
               pk_translation.get_translation(i_lang, 'RECM.CODE_RECM.' || recm) recm_desc,
               phone num_main_contact,
               address,
               postal_code zip_code,
               locality location,
               t_d.id_rb_regional_classifier district,
               t_d.district_desc,
               c.id_country country_address,
               pk_translation.get_translation(i_lang, c.code_country) country_address_desc,
               decode(marital_state, '-1', NULL, marital_state) marital_status,
               pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', marital_state, i_lang) marital_status_desc,
               decode(qualifications, -1, NULL, qualifications) scholarship,
               pk_translation.get_translation(i_lang, 'SCHOLARSHIP.CODE_SCHOLARSHIP.' || qualifications) scholarship_desc,
               decode(profession, -1, NULL, profession) occupation,
               pk_translation.get_translation(i_lang, 'OCCUPATION.CODE_OCCUPATION.' || profession) occupation_desc, -- ACM, 2010-05-25: ALERT-100182
               decode(profession_practice, '-1', NULL, profession_practice) job_status,
               pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', profession_practice, i_lang) job_status_desc,
               father father_name,
               mother mother_name,
               (SELECT health_plan_number
                  FROM TABLE(interface_p1.pk_p1_url.get_patient_data_health_plan(i_id_session)) t
                 WHERE t.health_plan_code = pk_sysconfig.get_config(pk_ref_constant.g_ident_health_plan, i_prof)) sns_number
          FROM TABLE(interface_p1.pk_p1_url.get_patient_data(i_id_session)) t
          LEFT JOIN country c
            ON (c.alpha2_code = t.country)
          LEFT JOIN (SELECT r.id_rb_regional_classifier,
                            pk_translation.get_translation(i_lang, r.code_rb_regional_classifier) district_desc
                       FROM rb_regional_classifier r
                      WHERE r.id_rb_regional_classifier >= 6200100001
                        AND r.id_rb_regional_classifier <= 6200100029) t_d -- district mapping
            ON upper(t_d.district_desc) = upper(t.district)
            ;
            */
        g_error := 'OPEN o_health_plan';
        OPEN o_health_plan FOR
        -- cmf OPSDEV-1073
            SELECT *
              FROM dual;
        -- cmf OPSDEV-1073
        /*
        SELECT health_plan_code, health_plan_number num_health_plan
          FROM TABLE(interface_p1.pk_p1_url.get_patient_data_health_plan(i_id_session));
          */
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_DATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            pk_types.open_my_cursor(o_health_plan);
            RETURN FALSE;
    END get_patient_data;

    FUNCTION history_list_to_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_text      IN VARCHAR2,
        i_code_desc IN VARCHAR2,
        i_notes     IN VARCHAR2,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_parent    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text     VARCHAR2(4000);
        l_text_aux VARCHAR2(200);
        l_dt_aux   VARCHAR2(50);
    BEGIN
    
        g_error := 'history_list_to_text';
        pk_alertlog.log_debug(g_error);
        l_text := i_text;
    
        g_error := 'history_list_to_text 1';
        IF l_text IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text || chr(10) || chr(10)), 0)) <=
               g_max_text_field_size
            THEN
                l_text := l_text || chr(10) || chr(10);
            END IF;
        END IF;
    
        g_error := 'history_list_to_text 2';
        IF i_parent IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + nvl(length(chr(10) || i_parent), 0)) <= g_max_text_field_size
            THEN
                l_text := l_text || i_parent || ': ';
            END IF;
        END IF;
    
        g_error := 'history_list_to_text 3';
        IF to_number(nvl(length(l_text), 0) + nvl(length(i_code_desc), 0)) <= g_max_text_field_size
        THEN
            l_text := l_text || i_code_desc;
        END IF;
    
        g_error := 'history_list_to_text 4';
        IF i_dt_begin IS NOT NULL
        THEN
            l_dt_aux   := pk_date_utils.dt_chr_tsz(i_lang,
                                                   pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL),
                                                   i_prof);
            l_text_aux := '; ' || pk_message.get_message(i_lang, i_prof, 'P1_AUTO_COMPLETE_T001');
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || l_dt_aux), 0)) <= g_max_text_field_size
            THEN
                l_text := l_text || l_text_aux || l_dt_aux;
            END IF;
        END IF;
    
        g_error := 'history_list_to_text 5';
        IF i_dt_end IS NOT NULL
        THEN
        
            l_dt_aux := pk_date_utils.dt_chr_tsz(i_lang,
                                                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL),
                                                 i_prof);
        
            l_text_aux := '; ' || pk_message.get_message(i_lang, i_prof, 'P1_AUTO_COMPLETE_T002');
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || l_dt_aux), 0)) <= g_max_text_field_size
            THEN
                l_text := l_text || l_text_aux || l_dt_aux;
            END IF;
        END IF;
    
        g_error := 'history_list_to_text 6';
        IF i_notes IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + nvl(length(chr(10) || i_notes), 0)) <= g_max_text_field_size
            THEN
                l_text := l_text || chr(10) || i_notes;
            END IF;
        END IF;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            alertlog.pk_alertlog.log_error(g_error);
            RETURN NULL;
    END history_list_to_text;

    FUNCTION exam_list_to_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_text      IN VARCHAR2,
        i_code_desc IN VARCHAR2,
        i_result    IN VARCHAR2,
        i_dt        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text     VARCHAR2(4000);
        l_text_aux VARCHAR2(200);
        l_dt_aux   VARCHAR2(50);
    BEGIN
    
        g_error := 'exam_list_to_text';
        pk_alertlog.log_debug(g_error);
        l_text := i_text;
    
        g_error := 'exam_list_to_text 1';
        IF l_text IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + length(chr(10) || chr(10))) <= g_max_text_field_size
            THEN
                l_text := l_text || chr(10) || chr(10);
            END IF;
        END IF;
    
        g_error := 'exam_list_to_text 2';
        IF (to_number(nvl(length(l_text), 0) + nvl(length(i_code_desc), 0))) <= g_max_text_field_size
        THEN
            l_text := l_text || i_code_desc;
        END IF;
    
        g_error := 'exam_list_to_text 3';
        IF i_result IS NOT NULL
        THEN
            l_text_aux := '; ' || pk_message.get_message(i_lang, i_prof, 'P1_AUTO_COMPLETE_T003');
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || i_result), 0)) <= g_max_text_field_size
            THEN
                l_text := l_text || l_text_aux || i_result;
            END IF;
        END IF;
    
        g_error := 'exam_list_to_text 4';
        IF i_dt IS NOT NULL
        THEN
        
            l_dt_aux := pk_date_utils.dt_chr_tsz(i_lang,
                                                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                 i_prof);
        
            l_text_aux := '; ' || pk_message.get_message(i_lang, i_prof, 'P1_AUTO_COMPLETE_T004');
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || l_dt_aux), 0)) <= g_max_text_field_size
            THEN
                l_text := l_text || l_text_aux || l_dt_aux;
            END IF;
        END IF;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            alertlog.pk_alertlog.log_error(g_error);
            RETURN NULL;
    END exam_list_to_text;

    /**
    * Return clinical data
    *
    * @param   i_lang external request id
    * @param   i_id_session session id
    * @param   o_data last record data
    * @param   o_problem problems,
    * @param   o_history personal history,
    * @param   o_family_history family history,
    * @param   o_exams executed exams,
    * @param   o_diagnosis diagnosis,    
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   11-12-2007
    * @modify  Ana Monteiro 2009/02/09 ALERT-11633
    */

    FUNCTION get_clinical_data_new
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_session       IN VARCHAR2,
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
        o_can_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_id_market market.id_market%TYPE;
    
        CURSOR c_problem_date IS
            SELECT NULL year_begin, NULL month_begin, NULL day_begin
              FROM dual;
        -- cmf OPSDEV-1073
        --SELECT get_date_str(data_ini_year, data_ini_month, data_ini_day) data_ini
        /*
        SELECT 
        data_ini_year year_begin, 
        data_ini_month month_begin, 
        data_ini_day day_begin
          FROM TABLE(interface_p1.pk_p1_url.get_clinical_data_problem(i_id_session))
         ORDER BY year_begin, month_begin, day_begin;
         */
    
        -- Para validar se a especialidade existe para as instituições de referenciação deste CS
        -- Tem que corresponder ao código de pk_ref_waiting_time.get_clinical_institution
        CURSOR c_spec_inst(x_spec p1_speciality.id_speciality%TYPE) IS
        -- external referrals
            SELECT v.id_institution
              FROM v_ref_network v
             WHERE v.flg_type = pk_ref_constant.g_p1_type_c
               AND v.id_inst_orig = i_prof.institution
               AND v.id_speciality = x_spec
               AND v.id_external_sys = 0 -- for backward compatibility, this column should the value 0
               AND v.flg_default_dcs = pk_ref_constant.g_yes;
    
        l_prof_name professional.name%TYPE;
        l_prof_spec VARCHAR2(500 CHAR);
    
        -- Problem begin date       
        l_year_begin           p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin          p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin            p1_exr_diagnosis.day_begin%TYPE;
        l_dt_probl_begin_str   VARCHAR2(100 CHAR);
        l_dt_probl_begin_flash VARCHAR2(10 CHAR);
    
        l_history        VARCHAR2(4000);
        l_family_history VARCHAR2(4000);
        l_exams          VARCHAR2(4000);
    
        l_speciality p1_speciality.id_speciality%TYPE;
        l_spec_desc  pk_translation.t_desc_translation;
        l_spec_inst  institution.id_institution%TYPE;
    BEGIN
    
        g_error := 'Init get_clinical_data_new / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
        --l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error     := 'Get prof name / ID_PROFESSIONAL=' || i_prof.id;
        l_prof_name := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                        i_prof    => i_prof, -- profissional actual
                                                        i_prof_id => i_prof.id -- profissional que efectuou os registos
                                                        );
    
        g_error     := 'Get prof spec / ID_PROFESSIONAL=' || i_prof.id;
        l_prof_spec := pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_prof_id   => i_prof.id, -- profissional que efectuou o registo correspondente a esta assinatura
                                                        i_prof_inst => i_prof.institution);
    
        g_error := 'open c_problem_date';
        OPEN c_problem_date;
        FETCH c_problem_date
            INTO l_year_begin, l_month_begin, l_day_begin;
        CLOSE c_problem_date;
    
        g_error                := 'Call pk_ref_utils.parse_dt_str_flash / i_id_session=' || i_id_session ||
                                  ' YEAR_BEGIN=' || l_year_begin || ' MONTH_BEGIN=' || l_month_begin || ' DAY_BEGIN=' ||
                                  l_day_begin;
        l_dt_probl_begin_flash := pk_ref_utils.parse_dt_str_flash(i_lang  => i_lang,
                                                                  i_prof  => i_prof,
                                                                  i_year  => l_year_begin,
                                                                  i_month => l_month_begin,
                                                                  i_day   => l_day_begin);
    
        l_dt_probl_begin_str := pk_ref_utils.parse_dt_str_app(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_year  => l_year_begin,
                                                              i_month => l_month_begin,
                                                              i_day   => l_day_begin);
    
        -- Get speciality    
        g_error := 'Get speciality';
        /*
        -- cmf OPSDEV-1073
        SELECT speciality id_speciality,
               pk_translation.get_translation(i_lang, 'P1_SPECIALITY.CODE_SPECIALITY.' || speciality)
          INTO l_speciality, l_spec_desc
          FROM TABLE(interface_p1.pk_p1_url.get_clinical_data(i_id_session));
          */
        l_speciality := NULL;
        l_spec_desc  := NULL;
    
        -- Is there any available institution for this speciality?
        g_error := 'OPEN c_spec_inst(' || l_speciality || ')';
        pk_alertlog.log_debug(g_error);
    
        OPEN c_spec_inst(l_speciality);
        FETCH c_spec_inst
            INTO l_spec_inst;
        g_found := c_spec_inst%FOUND;
        CLOSE c_spec_inst;
    
        IF NOT g_found
        THEN
            l_speciality := NULL;
            l_spec_desc  := NULL;
        END IF;
    
        g_error := 'OPEN o_detail';
        OPEN o_detail FOR
            SELECT NULL id_p1,
                   NULL num_p1,
                   NULL dt_p1,
                   NULL flg_type, -- ALERT-85673 Referrals originated in SAM are always of type consultation
                   NULL status_icon,
                   NULL flg_status,
                   NULL status_colors,
                   NULL desc_status,
                   NULL priority_icon,
                   NULL dt_elapsed,
                   NULL prof_name_request,
                   NULL prof_spec_request,
                   NULL priority_desc, -- ALERT-273753
                   NULL id_dep_clin_serv,
                   NULL id_speciality,
                   NULL spec_name,
                   NULL id_institution,
                   NULL inst_abbrev,
                   NULL inst_name,
                   NULL dep_name,
                   NULL dt_schedule,
                   NULL dt_probl_begin,
                   NULL dt_probl_begin_ts,
                   NULL flg_priority,
                   NULL flg_home,
                   NULL prof_redirected,
                   NULL dt_last_interaction,
                   NULL id_external_sys
              FROM dual;
    
        /*
         -- CMF OPSDEV1073
        SELECT NULL id_p1,
               NULL num_p1,
               NULL dt_p1,
               pk_ref_constant.g_p1_type_c flg_type, -- ALERT-85673 Referrals originated in SAM are always of type consultation
               pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_STATUS', pk_ref_constant.g_p1_status_o) status_icon,
               pk_ref_constant.g_p1_status_o flg_status,
               pk_sysdomain.get_domain('P1_STATUS_COLOR.MED_CS', pk_ref_constant.g_p1_status_o, i_lang) status_colors,
               pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', pk_ref_constant.g_p1_status_o, i_lang) desc_status,
               nvl2(pk_sysdomain.get_img(i_lang,
                                         'P1_EXTERNAL_REQUEST.FLG_PRIORITY',
                                         decode(urgent, g_sim, pk_ref_constant.g_yes, urgent)),
                    lpad(pk_sysdomain.get_rank(i_lang,
                                               'P1_EXTERNAL_REQUEST.FLG_PRIORITY',
                                               decode(urgent, g_sim, pk_ref_constant.g_yes, urgent)),
                         6,
                         '0') ||
                    pk_sysdomain.get_img(i_lang,
                                         'P1_EXTERNAL_REQUEST.FLG_PRIORITY',
                                         decode(urgent, g_sim, pk_ref_constant.g_yes, urgent)),
                    NULL) priority_icon,
               pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, g_sysdate_tstz) dt_elapsed,
               l_prof_name prof_name_request,
               l_prof_spec prof_spec_request,
               pk_sysdomain.get_domain('YES_NO', decode(urgent, g_sim, pk_ref_constant.g_yes, urgent), i_lang) priority_desc, -- ALERT-273753
               NULL id_dep_clin_serv,
               l_speciality id_speciality,
               l_spec_desc spec_name,
               NULL id_institution,
               NULL inst_abbrev,
               NULL inst_name,
               NULL dep_name,
               NULL dt_schedule,
               pk_date_utils.dt_chr_tsz(i_lang,
                                        l_dt_probl_begin_str, -- ALERT-194568
                                        i_prof) dt_probl_begin,
               pk_date_utils.date_send_tsz(i_lang,
                                           l_dt_probl_begin_flash, -- ALERT-194568
                                           i_prof) dt_probl_begin_ts,
               decode(urgent, g_sim, pk_ref_constant.g_yes, urgent) flg_priority,
               NULL flg_home,
               NULL prof_redirected,
               pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) dt_last_interaction,
               NULL id_external_sys
          FROM TABLE(interface_p1.pk_p1_url.get_clinical_data(i_id_session));
          */
    
        g_error := 'OPEN o_text';
        OPEN o_text FOR
            SELECT NULL label_group, --
                   NULL label, --
                   NULL id,
                   NULL id_parent, --
                   NULL id_req, --
                   NULL title, --                                      
                   NULL text,
                   NULL dt_insert,
                   NULL prof_name,
                   NULL prof_spec,
                   NULL flg_type,
                   NULL flg_status, --
                   NULL id_institution, --
                   NULL flg_priority, --
                   NULL flg_home, --
                   NULL id_group
              FROM dual;
        /*
            -- cmf OPSDEV-1073
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_jstf, i_lang) title, --                                      
                       justification text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_jstf flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data(i_id_session))
                UNION ALL
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_sntm, i_lang) title, --                                      
                       symptoms text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_sntm flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data(i_id_session))
                
                UNION ALL
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_evlt, i_lang) title, --                                      
                       evolution text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_evlt flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data(i_id_session))
                UNION ALL
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_hstr, i_lang) title, --                                      
                       history_list_to_text(i_lang,
                                            i_prof,
                                            l_history,
                                            get_icd_desc(i_lang, code),
                                            notes,
                                            get_date_str(data_ini_year, data_ini_month, data_ini_day),
                                            get_date_str(data_end_year, data_end_month, data_end_day),
                                            NULL) text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_hstr flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data_history(i_id_session))
                UNION ALL
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_hstf, i_lang) title, --                                      
                       history_list_to_text(i_lang,
                                            i_prof,
                                            l_family_history,
                                            get_icd_desc(i_lang, code),
                                            notes,
                                            get_date_str(data_ini_year, data_ini_month, data_ini_day),
                                            get_date_str(data_end_year, data_end_month, data_end_day),
                                            PARENT) text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_hstf flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data_hist_family(i_id_session))
                UNION ALL
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_obje, i_lang) title, --                                      
                       examination text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_obje flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data(i_id_session))
                UNION ALL
                SELECT NULL label_group, --
                       NULL label, --
                       NULL id,
                       NULL id_parent, --
                       NULL id_req, --
                       pk_sysdomain.get_domain('P1_DETAIL.FLG_TYPE', pk_ref_constant.g_detail_type_cmpe, i_lang) title, --                                      
                       exam_list_to_text(i_lang,
                                         i_prof,
                                         l_exams,
                                         name,
                                         RESULT,
                                         get_date_str(data_year, data_month, data_day)) text,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                       l_prof_name prof_name,
                       l_prof_spec prof_spec,
                       pk_ref_constant.g_detail_type_cmpe flg_type,
                       pk_ref_constant.g_active flg_status, --
                       NULL id_institution, --
                       NULL flg_priority, --
                       NULL flg_home, --
                       NULL id_group
                  FROM TABLE(interface_p1.pk_p1_url.get_clinical_data_exams(i_id_session));
        */
        g_error := 'OPEN o_problem';
        OPEN o_problem FOR
            SELECT NULL label_group,
                   NULL label,
                   NULL id,
                   NULL id_parent,
                   NULL id_req, --
                   NULL title, --problem,
                   NULL text, --                   
                   NULL dt_insert,
                   NULL prof_name,
                   NULL prof_spec,
                   NULL flg_type, --
                   NULL flg_status, --record status
                   NULL id_institution, --
                   NULL flg_priority, --
                   NULL flg_home --                  
              FROM dual;
        /*
         -- CMF OPSDEV-1073
        SELECT NULL label_group,
               NULL label,
               get_icd_id(code) id,
               get_icd_parent_id(code) id_parent,
               NULL id_req, --
               get_icd_desc(i_lang, code) title, --problem,
               NULL text, --                   
               pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
               l_prof_name prof_name,
               l_prof_spec prof_spec,
               pk_ref_constant.g_exr_diag_type_p flg_type, --
               pk_ref_constant.g_active flg_status, --record status
               NULL id_institution, --
               NULL flg_priority, --
               NULL flg_home --                  
          FROM TABLE(interface_p1.pk_p1_url.get_clinical_data_problem(i_id_session));
          */
    
        g_error := 'OPEN o_diagnosis';
        OPEN o_diagnosis FOR
            SELECT NULL label_group,
                   NULL label,
                   NULL id,
                   NULL id_parent,
                   NULL id_req, --
                   NULL title, --problem,
                   NULL text, --                   
                   NULL dt_insert,
                   NULL prof_name,
                   NULL prof_spec,
                   NULL flg_type, --
                   NULL flg_status, --record status
                   NULL id_institution, --
                   NULL flg_priority, --
                   NULL flg_home --                  
              FROM dual;
        /*
                -- cmf OPSDEV-1073
                    SELECT NULL label_group,
                           NULL label,
                           get_icd_id(code) id,
                           get_icd_parent_id(code) id_parent,
                           NULL id_req, --
                           get_icd_desc(i_lang, code) title, -- diagnosis,
                           NULL text, --
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                           l_prof_name prof_name,
                           l_prof_spec prof_spec,
                           pk_ref_constant.g_exr_diag_type_d flg_type, --
                           pk_ref_constant.g_active flg_status, --record status
                           NULL id_institution, --
                           NULL flg_priority, --
                           NULL flg_home --                  
                      FROM TABLE(interface_p1.pk_p1_url.get_clinical_diagnosis(i_id_session));
        */
        g_error := 'Open the other cursors';
        pk_types.open_my_cursor(o_mcdt);
        pk_types.open_my_cursor(o_needs);
        pk_types.open_my_cursor(o_info);
        pk_types.open_my_cursor(o_notes_status);
        pk_types.open_my_cursor(o_notes_status_det);
        pk_types.open_my_cursor(o_answer);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLINICAL_DATA_NEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_text);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            RETURN FALSE;
    END get_clinical_data_new;

    /**
    * Return the url used to access the application.
    * Used by the interface.
    *
    * @param   i_lang external request id
    * @param   i_id_ext_req external request id
    * @param   o_data last record data
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_url
    (
        i_inst_code   institution.ext_code%TYPE,
        i_prof_number professional.num_order%TYPE,
        i_session     VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_prof professional.id_professional%TYPE;
        l_inst institution.id_institution%TYPE;
        l_soft software.id_software%TYPE;
        l_url  VARCHAR2(2000);
        l_lang language.id_language%TYPE := 1;
    BEGIN
    
        g_error := 'Init get_url / i_inst_code=' || i_inst_code || ' i_prof_number=' || i_prof_number || ' i_session=' ||
                   i_session;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN c_prof';
        OPEN c_prof(i_inst_code, i_prof_number);
        FETCH c_prof
            INTO l_prof, l_inst;
        g_found := c_prof%FOUND;
        CLOSE c_prof;
    
        IF NOT g_found
        THEN
            g_error := 'User ' || i_prof_number || ' not found in institution ' || i_inst_code;
            RAISE g_exception;
        END IF;
    
        g_error := 'Get SOFTWARE_ID_P1';
        SELECT pk_sysconfig.get_config('SOFTWARE_ID_P1', profissional(l_prof, l_inst, 0))
          INTO l_soft
          FROM dual;
    
        IF l_soft IS NULL
        THEN
            g_error := 'Paramteter SOFTWARE_ID_P1 not found';
            RAISE g_exception;
        END IF;
    
        g_error := 'Get P1_AUTO_LOGIN_URL';
        SELECT pk_sysconfig.get_config('P1_AUTO_LOGIN_URL', profissional(l_prof, l_inst, l_soft))
          INTO l_url
          FROM dual;
    
        IF l_url IS NULL
        THEN
            g_error := 'Parameter P1_AUTO_LOGIN_URL not found';
            RAISE g_exception;
        END IF;
    
        g_error := 'URL replace';
        l_url   := REPLACE(l_url, '@1', i_session);
        l_url   := REPLACE(l_url, '@2', pk_ref_constant.g_provider_p1);
    
        RETURN l_url;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_USER',
                                              o_error    => o_error);
            RETURN NULL;
    END get_url;

    /**
    * Converts year, month and day sting into normalized date string
    *
    * @param   y year
    * @param   m month
    * @param   d day   
    *
    * @RETURN  date string, NULL in case of error
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_date_str
    (
        y VARCHAR2,
        m VARCHAR2,
        d VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        -- JB 14/10/2009
        g_error := 'get_date_str / y=' || y || ' m=' || m || ' d=' || d;
        pk_alertlog.log_debug(g_error);
    
        IF y IS NULL
           OR m IS NULL
           OR d IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN to_char(y) || lpad(to_char(m), 2, '0') || lpad(to_char(d), 2, '0') || '000000';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('y=' || y || ' m=' || m || ' d=' || d || ' / ' || SQLERRM);
            RETURN NULL;
    END get_date_str;

    /**
    * Gets the translation code for the provided icd code
    *
    * @param   i_lang   professional language id
    * @param   i_code   icpc2 code
    *
    * @RETURN  translation code if exists, NULL otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_icd_desc
    (
        i_lang language.id_language%TYPE,
        i_code diagnosis.code_icd%TYPE
    ) RETURN VARCHAR2 IS
        l_desc pk_translation.t_desc_translation;
    BEGIN
    
        g_error := 'get_icd_desc / i_code=' || i_code;
        SELECT pk_translation.get_translation(i_lang, code_diagnosis)
          INTO l_desc
          FROM diagnosis
         WHERE code_icd = i_code
           AND flg_type = pk_ref_constant.g_diag_type_icpc;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('i_code=' || i_code || ' / ' || SQLERRM);
            RETURN NULL;
    END get_icd_desc;

    /**
    * Gets alert id for the icd code provided.
    *
    * @param   i_code   icpc2 code
    *
    * @RETURN  translation code if exists, NULL otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_icd_id(i_code diagnosis.code_icd%TYPE) RETURN NUMBER IS
        l_id diagnosis.id_diagnosis%TYPE;
    BEGIN
    
        g_error := 'get_icd_id / i_code=' || i_code;
        SELECT id_diagnosis
          INTO l_id
          FROM diagnosis
         WHERE code_icd = i_code
           AND flg_type = pk_ref_constant.g_diag_type_icpc;
    
        RETURN l_id;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('i_code=' || i_code || ' / ' || SQLERRM);
            RETURN NULL;
    END get_icd_id;

    /**
    * Gets alert parent id for the icd code provided.
    *
    * @param   i_code   icpc2 code
    *
    * @RETURN  translation code if exists, NULL otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-07-2009
    */
    FUNCTION get_icd_parent_id(i_code diagnosis.code_icd%TYPE) RETURN NUMBER IS
        l_id diagnosis.id_diagnosis%TYPE;
    BEGIN
    
        g_error := 'get_icd_parent_id / i_code=' || i_code;
        SELECT id_diagnosis_parent
          INTO l_id
          FROM diagnosis
         WHERE code_icd = i_code
           AND flg_type = pk_ref_constant.g_diag_type_icpc;
    
        RETURN l_id;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('i_code=' || i_code || ' / ' || SQLERRM);
            RETURN NULL;
    END get_icd_parent_id;

    /**
    * Matchs patient Alert's and external system's id's.
    *
    * @param   i_lang        Professional language id
    * @param   i_prof        Professional  id, institution and software
    * @param   i_patient     Patient identifier
    * @param   i_id_session  Session identifier    
    * @param   o_error       Error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   21-12-2007
    */
    FUNCTION set_match
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_session IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_number p1_match.sequential_number%TYPE; -- ALERT-47077
    BEGIN
    
        g_error := 'Get data';
        /*
        --cmf OPSDEV-1073
        SELECT internal_number
          INTO l_internal_number
          FROM TABLE(interface_p1.pk_p1_url.get_patient_data(i_id_session)) t;
          */
    
        g_error  := 'Call pk_p1_adm_hs.set_match_internal';
        g_retval := pk_p1_adm_hs.set_match_internal(i_lang     => i_lang,
                                                    i_pat      => i_patient,
                                                    i_prof     => i_prof,
                                                    i_seq_num  => to_char(l_internal_number),
                                                    i_clin_rec => NULL,
                                                    i_epis     => NULL,
                                                    o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
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
                                              i_function => 'SET_MATCH',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_auto_complete;
/
