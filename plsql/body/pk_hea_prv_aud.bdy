/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_aud IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_id_audit_req_prof_epis := NULL;
        g_id_audit_req_prof      := NULL;
    END;

    /**
    * Fetchs all the variables for the manchester audit if they have not been fetched yet.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var
    (
        i_lang                   language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE
    ) IS
        l_error t_error_out;
    BEGIN
        IF g_id_audit_req_prof_epis IS NULL
           OR i_id_audit_req_prof_epis != g_id_audit_req_prof_epis
        THEN
            g_id_audit_req_prof_epis := i_id_audit_req_prof_epis;
            SELECT pk_patient.get_pat_name(i_lang, i_prof, v.id_patient, e.id_episode) a,
                   nvl((SELECT s.value
                         FROM epis_ext_sys s
                        WHERE s.id_episode = e.id_episode
                          AND s.id_external_sys = 1
                             --pk_sysconfig.get_config('ID_EXTERNAL_SYS',
                             --                        profissional(i_prof.id,
                             --                                     i_prof.institution,
                             --                                     pk_triage_audit.g_soft_edis))
                          AND s.id_institution = v.id_institution),
                       '---') b,
                   e.id_episode
              INTO g_pat_name, g_id_epis_ext_sys, g_id_episode
              FROM audit_req_prof_epis a, epis_triage t, episode e, visit v
             WHERE a.id_audit_req_prof_epis = i_id_audit_req_prof_epis
               AND t.id_epis_triage = a.id_epis_triage
               AND e.id_episode = t.id_episode
               AND v.id_visit = e.id_visit;
        
            IF NOT pk_hea_prv_aux.get_epis_compl(i_lang,
                                                 profissional(i_prof.id, i_prof.institution, pk_triage_audit.g_soft_edis),
                                                 g_id_episode,
                                                 g_title_epis_anamnesis,
                                                 g_epis_anamnesis,
                                                 l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    END;

    /**
    * Fetchs all the variables for the manchester audit if they have not been fetched yet.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var(i_id_audit_req_prof audit_req_prof.id_audit_req_prof%TYPE) IS
    BEGIN
        IF g_id_audit_req_prof IS NULL
           OR g_id_audit_req_prof != i_id_audit_req_prof
        THEN
            SELECT a.id_professional
              INTO g_id_professional
              FROM audit_req_prof a
             WHERE a.id_audit_req_prof = i_id_audit_req_prof;
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END;

    /**
    * Returns the manchester audit period.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_period
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_audit_req IN audit_req.id_audit_req%TYPE
    ) RETURN VARCHAR IS
        l_title_period      sys_message.desc_message%TYPE;
        l_title_desc_period sys_message.desc_message%TYPE;
        l_period_begin      pk_translation.t_desc_translation;
        l_period_end        pk_translation.t_desc_translation;
    BEGIN
    
        l_title_period      := pk_message.get_message(i_lang, 'AUDIT_GRID_T001');
        l_title_desc_period := pk_message.get_message(i_lang, 'AUDIT_GRID_T048');
        BEGIN
            SELECT pk_date_utils.dt_chr_tsz(i_lang, a.dt_begin_tstz, i_prof),
                   pk_date_utils.dt_chr_tsz(i_lang, a.dt_end_tstz, i_prof)
              INTO l_period_begin, l_period_end
              FROM audit_req a, audit_type t
             WHERE a.id_audit_req = i_id_audit_req
               AND t.id_audit_type = a.id_audit_type;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        RETURN l_title_period || ': ' || REPLACE(REPLACE(l_title_desc_period, '@1', l_period_begin),
                                                 '@2',
                                                 l_period_end);
    END;

    /**
    * Returns the manchester audit professional photo.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prof_photo
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_audit_req_prof);
        RETURN pk_hea_prv_aux.get_photo(i_lang,
                                        profissional(i_prof.id, i_prof.institution, pk_triage_audit.g_soft_edis),
                                        g_id_professional);
    END;

    /**
    * Returns the manchester audit professional name.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prof_name
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_audit_req_prof);
        RETURN pk_hea_prv_prof.get_name(i_lang, i_prof, g_id_professional);
    END;

    /**
    * Returns the manchester audit professional full name.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prof_fullname
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_audit_req_prof);
        RETURN pk_hea_prv_prof.get_fullname(i_lang, i_prof, g_id_professional);
    END;

    /**
    * Returns the manchester audit professional specialty.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prof_specialty
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_audit_req_prof);
        RETURN pk_hea_prv_prof.get_speciality(i_lang, i_prof, g_id_professional);
    END;

    /**
    * Returns the manchester audit type.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_software
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_audit_req IN audit_req.id_audit_req%TYPE
    ) RETURN VARCHAR IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, t.code_audit_type)
          INTO l_ret
          FROM audit_req a, audit_type t
         WHERE a.id_audit_req = i_id_audit_req
           AND t.id_audit_type = a.id_audit_type;
    
        RETURN l_ret;
    END;

    /**
    * Returns the manchester audit episode number.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_epis_number
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_audit_req_prof_epis);
        RETURN g_id_epis_ext_sys;
    END;

    /**
    * Returns the manchester audit patient name.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_pat_name
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_audit_req_prof_epis);
        RETURN g_pat_name;
    END;

    /**
    * Returns the label for audit trail 'Patient'
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
    FUNCTION get_audit_patient
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'AUDIT_GRID_T018');
    END;

    /**
    * Returns the manchester audit institution name.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_inst_name
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_inst.get_name(i_lang, i_prof, i_prof.institution);
    END;

    /**
    * Returns the manchester audit episode diagnosis.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_epis_diagnosis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_audit_req_prof_epis);
        RETURN g_epis_anamnesis;
    END;

    /**
    * Returns the manchester audit value for label 'diagnosis'.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_label_diagnosis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_lang, i_prof, i_id_audit_req_prof_epis);
        RETURN g_title_epis_anamnesis;
    END;

    /**
    * Returns the manchester audit professional photo timestamp.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prof_photo_timestamp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_aux.get_photo_timestamp(i_lang,
                                                  profissional(i_prof.id,
                                                               i_prof.institution,
                                                               pk_triage_audit.g_soft_edis),
                                                  g_id_professional);
    END;

    /**
    * Returns the manchester audit value for the tag given as parameter.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    * @param i_tag                    Tag to be replaced
    * @param o_data_rec               Tag's data
    *
    * @return                         The manchester audit value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req           IN audit_req.id_audit_req%TYPE,
        i_id_audit_req_prof      IN audit_req_prof.id_audit_req_prof%TYPE,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_tag                    IN header_tag.internal_name%TYPE,
        o_data_rec               OUT t_rec_header_data
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
        IF i_id_audit_req IS NULL
        THEN
            RETURN FALSE;
        END IF;
        CASE i_tag
            WHEN 'AUDIT_INST_NAME' THEN
                l_data_rec.text := get_inst_name(i_lang, i_prof);
            WHEN 'AUDIT_PERIOD' THEN
                l_data_rec.text := get_period(i_lang, i_prof, i_id_audit_req);
            WHEN 'AUDIT_SOFTWARE' THEN
                l_data_rec.text := get_software(i_lang, i_prof, i_id_audit_req);
            ELSE
                IF i_id_audit_req_prof IS NULL
                THEN
                    RETURN FALSE;
                ELSE
                    CASE i_tag
                        WHEN 'AUDIT_PROF_PHOTO' THEN
                            l_data_rec.source      := get_prof_photo(i_lang, i_prof, i_id_audit_req_prof);
                            l_data_rec.description := get_prof_photo_timestamp(i_lang, i_prof, i_id_audit_req_prof);
                        WHEN 'AUDIT_PROF_NAME' THEN
                            l_data_rec.text        := get_prof_name(i_lang, i_prof, i_id_audit_req_prof);
                            l_data_rec.description := get_prof_fullname(i_lang, i_prof, i_id_audit_req_prof);
                        WHEN 'AUDIT_PROF_SPECIALTY' THEN
                            l_data_rec.text := get_prof_specialty(i_lang, i_prof, i_id_audit_req_prof);
                        ELSE
                            IF i_id_audit_req_prof_epis IS NULL
                            THEN
                                RETURN FALSE;
                            ELSE
                                CASE i_tag
                                    WHEN 'AUDIT_EPIS_NUMBER' THEN
                                        l_data_rec.text := get_epis_number(i_lang, i_prof, i_id_audit_req_prof_epis);
                                    WHEN 'AUDIT_PAT_NAME' THEN
                                        l_data_rec.text        := get_pat_name(i_lang, i_prof, i_id_audit_req_prof_epis);
                                        l_data_rec.description := get_audit_patient(i_lang, i_prof);
                                    WHEN 'AUDIT_EPIS_DIAGNOSIS' THEN
                                        l_data_rec.text        := get_epis_diagnosis(i_lang,
                                                                                     i_prof,
                                                                                     i_id_audit_req_prof_epis);
                                        l_data_rec.description := get_label_diagnosis(i_lang,
                                                                                      i_prof,
                                                                                      i_id_audit_req_prof_epis);
                                    ELSE
                                        RETURN FALSE;
                                END CASE;
                            END IF;
                    END CASE;
                END IF;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the manchester audit value for the tag given as parameter.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    * @param i_tag                    Tag to be replaced
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req           IN audit_req.id_audit_req%TYPE,
        i_id_audit_req_prof      IN audit_req_prof.id_audit_req_prof%TYPE,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_tag                    IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_tag       header_tag.internal_name%TYPE;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_audit_req IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        -- Translate old tags to html version
        CASE i_tag
            WHEN 'AUDIT_PROF_FULLNAME' THEN
                l_tag := 'AUDIT_PROF_NAME';
            WHEN 'AUDIT_PROF_PHOTO_TIMESTAMP' THEN
                l_tag := 'AUDIT_PROF_PHOTO';
            ELSE
                l_tag := i_tag;
        END CASE;
    
        l_ret := get_value_html(i_lang,
                                i_prof,
                                i_id_audit_req,
                                i_id_audit_req_prof,
                                i_id_audit_req_prof_epis,
                                l_tag,
                                l_data_rec);
    
        CASE i_tag
            WHEN 'AUDIT_INST_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'AUDIT_PERIOD' THEN
                RETURN l_data_rec.text;
            WHEN 'AUDIT_SOFTWARE' THEN
                RETURN l_data_rec.text;
            ELSE
                IF i_id_audit_req_prof IS NULL
                THEN
                    RETURN NULL;
                ELSE
                
                    CASE i_tag
                        WHEN 'AUDIT_PROF_PHOTO' THEN
                            RETURN l_data_rec.source;
                        WHEN 'AUDIT_PROF_PHOTO_TIMESTAMP' THEN
                            RETURN l_data_rec.description;
                        WHEN 'AUDIT_PROF_NAME' THEN
                            RETURN l_data_rec.text;
                        WHEN 'AUDIT_PROF_FULLNAME' THEN
                            RETURN l_data_rec.description;
                        WHEN 'AUDIT_PROF_SPECIALTY' THEN
                            RETURN get_prof_specialty(i_lang, i_prof, i_id_audit_req_prof);
                        ELSE
                            IF i_id_audit_req_prof_epis IS NULL
                            THEN
                                RETURN NULL;
                            ELSE
                                CASE i_tag
                                    WHEN 'AUDIT_EPIS_NUMBER' THEN
                                        RETURN l_data_rec.text;
                                    WHEN 'AUDIT_PAT_NAME' THEN
                                        RETURN l_data_rec.text;
                                    WHEN 'AUDIT_EPIS_DIAGNOSIS' THEN
                                        RETURN l_data_rec.text;
                                    WHEN 'AUDIT_LABEL_DIAGNOSIS' THEN
                                        RETURN l_data_rec.description;
                                    ELSE
                                        RETURN 'audit_' || i_tag;
                                END CASE;
                            END IF;
                    END CASE;
                END IF;
        END CASE;
        RETURN 'audit_' || i_tag;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
