/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_ref IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_row_r.id_external_request := NULL;
        g_row_r                     := NULL;
    END;

    /**
    * Fetchs all the variables for the referral if they have not been fetched yet.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) IS
        l_module sys_config.value%TYPE; -- specifies referral module
    
    BEGIN
    
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
    
        IF i_id_external_request IS NULL
        THEN
            IF g_row_r.id_external_request IS NOT NULL
            THEN
                reset_var;
            END IF;
            RETURN;
        END IF;
        IF g_row_r.id_external_request IS NULL
           OR g_row_r.id_external_request != i_id_external_request
        THEN
            reset_var();
            g_error := 'SELECT * INTO g_row FROM episode';
            --pk_alertlog.log_debug(g_error);
            SELECT *
              INTO g_row_r
              FROM referral_ea ea
             WHERE ea.id_external_request = i_id_external_request;
        
            g_error := 'MODULE =' || l_module;
            CASE l_module
                WHEN pk_ref_constant.g_sc_ref_module_circle THEN
                    g_row_r.dt_schedule := NULL;
                    g_row_r.id_schedule := NULL;
                
                ELSE
                    NULL;
            END CASE;
        END IF;
    END;

    /**
    * Returns the referral number.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral number
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_number
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_external_request);
        RETURN nvl(g_row_r.num_req, '---');
    END;

    /**
    * Returns the label for Referral 'Number'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_referral_number
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'P1_INFO_T001');
    END;

    /**
    * Returns the referral date.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral date
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_date
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_date_utils.dt_chr_tsz(i_lang,
                                        pk_ref_utils.get_ref_detail_date(i_lang       => i_lang,
                                                                         i_id_ext_req => i_id_external_request),
                                        i_prof);
    END;

    /**
    * Returns the label for Referral 'Date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_referral_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'P1_INFO_T002');
    END;

    /**
    * Returns the referral origin.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral origin
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_origin
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
        l_var sys_config.value%TYPE;
    BEGIN
        check_var(i_lang, i_prof, i_id_external_request);
        l_var := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_external_inst, i_prof => i_prof);
    
        IF g_row_r.id_inst_orig = l_var
        THEN
            RETURN g_row_r.institution_name_roda;
        END IF;
    
        RETURN pk_hea_prv_inst.get_value(i_lang, i_prof, g_row_r.id_inst_orig, 'INST_ACRONYM');
    END;

    /**
    * Returns the label for Referral 'Origin'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_referral_origin
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'P1_INFO_T003');
    END;

    /**
    * Returns the referral process.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral process
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_process
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
        l_process_number pat_identifier.alert_process_number%TYPE;
    
        CURSOR c_clin_record IS
            SELECT *
              FROM (SELECT num_clin_record
                      FROM clin_record c
                     WHERE c.id_patient = g_row_r.id_patient
                       AND c.flg_status = pk_alert_constant.g_active
                     ORDER BY decode(c.id_institution, i_prof.institution, 1, 0) DESC)
             WHERE rownum = 1;
    BEGIN
        check_var(i_lang, i_prof, i_id_external_request);
        --RETURN pk_hea_prv_aux.get_process(i_lang, i_prof, g_row_r.id_patient, g_row_r.id_inst_dest);
    
        -- ACM, 2010-04-09: ALERT-87841
        -- ACM, 2010-04-13: ALERT-88046 - getting clinical record based on ID_INSTIT_ENROLED and on ID_INSTITUTION
        OPEN c_clin_record;
        FETCH c_clin_record
            INTO l_process_number;
        CLOSE c_clin_record;
    
        RETURN nvl(l_process_number, '---');
    
    END get_process;

    /**
    * Returns the label for Referral 'Process'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_referral_process
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'P1_INFO_T005');
    END;

    /**
    * Returns the referral appointment type.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral appointment type
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_appointment
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_external_request);
        IF g_row_r.id_dep_clin_serv IS NOT NULL
        THEN
            RETURN pk_hea_prv_aux.get_clin_service(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_dep_clin_serv => g_row_r.id_dep_clin_serv);
        ELSE
            RETURN pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_p1_speciality_code || g_row_r.id_speciality);
        END IF;
    END;

    /**
    * Returns the referral schedule date.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral schedule date
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_schedule_date
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_external_request);
        IF g_row_r.dt_schedule IS NULL
        THEN
            RETURN '---';
        ELSE
            RETURN pk_date_utils.dt_year_day_hour_chr_short_tsz(i_lang, g_row_r.dt_schedule, i_prof);
        END IF;
    END;

    /**
    * Returns the label for Referral 'Schedule'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_referral_schedule
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'P1_INFO_T006');
    END;

    /**
    * Returns the referral destiny.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    *
    * @return                      The referral destiny
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_destiny
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_external_request);
        IF g_row_r.id_inst_dest IS NULL
        THEN
            RETURN '---';
        ELSE
            RETURN pk_hea_prv_inst.get_value(i_lang, i_prof, g_row_r.id_inst_dest, 'INST_ACRONYM');
        END IF;
    END;

    /**
    * Returns the label for Referral 'Destiny'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_referral_destiny
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'P1_INFO_T009');
    END;

    /**
    * Returns the referral value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    * @param i_tag                 Tag to be replaced
    * @param o_data_rec            Tag's data   
    *
    * @return                      The value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_tag                 IN header_tag.internal_name%TYPE,
        o_data_rec            OUT t_rec_header_data
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_data_rec  t_rec_header_data := t_rec_header_data(NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL);
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_external_request IS NULL
        THEN
            RETURN FALSE;
        END IF;
        CASE i_tag
            WHEN 'REFERRAL_NUMBER' THEN
                l_data_rec.text        := get_number(i_lang, i_prof, i_id_external_request);
                l_data_rec.description := get_referral_number(i_lang, i_prof);
            WHEN 'REFERRAL_DATE' THEN
                l_data_rec.text        := get_date(i_lang, i_prof, i_id_external_request);
                l_data_rec.description := get_referral_date(i_lang, i_prof);
            WHEN 'REFERRAL_ORIGIN' THEN
                l_data_rec.text        := get_origin(i_lang, i_prof, i_id_external_request);
                l_data_rec.description := get_referral_origin(i_lang, i_prof);
            WHEN 'REFERRAL_PROCESS' THEN
                l_data_rec.text        := get_process(i_lang, i_prof, i_id_external_request);
                l_data_rec.description := get_referral_process(i_lang, i_prof);
            WHEN 'REFERRAL_APPOINTMENT' THEN
                l_data_rec.text := get_appointment(i_lang, i_prof, i_id_external_request);
            WHEN 'REFERRAL_SCHEDULE_DATE' THEN
                l_data_rec.text        := get_schedule_date(i_lang, i_prof, i_id_external_request);
                l_data_rec.description := get_referral_schedule(i_lang, i_prof);
            WHEN 'REFERRAL_DESTINY' THEN
                l_data_rec.text        := get_destiny(i_lang, i_prof, i_id_external_request);
                l_data_rec.description := get_referral_destiny(i_lang, i_prof);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the referral value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_external_request Referral Id
    * @param i_tag                 Tag to be replaced
    *
    * @return                      The value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_tag                 IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_external_request IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_ret := get_value_html(i_lang, i_prof, i_id_external_request, i_tag, l_data_rec);
    
        CASE i_tag
            WHEN 'REFERRAL_NUMBER' THEN
                RETURN l_data_rec.text;
            WHEN 'REFERRAL_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'REFERRAL_ORIGIN' THEN
                RETURN l_data_rec.text;
            WHEN 'REFERRAL_PROCESS' THEN
                RETURN l_data_rec.text;
            WHEN 'REFERRAL_APPOINTMENT' THEN
                RETURN l_data_rec.text;
            WHEN 'REFERRAL_SCHEDULE_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'REFERRAL_DESTINY' THEN
                RETURN l_data_rec.text;
            ELSE
                RETURN 'ref_' || i_tag;
        END CASE;
        RETURN 'ref_' || i_tag;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_hea_prv_ref;
/
