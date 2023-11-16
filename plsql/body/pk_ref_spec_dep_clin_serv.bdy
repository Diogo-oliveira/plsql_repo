/*-- Last Change Revision: $Rev: 1714849 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2015-11-06 14:39:15 +0000 (sex, 06 nov 2015) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_spec_dep_clin_serv IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_retval  BOOLEAN;

    -- Function and procedure implementations

    /**
    * Gets referral speciality default related to id_dep_clin_serv
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   id_dep_clin_serv Department and clinical service identifier
    * @param   i_id_patient     Patient identifier
    * @param   i_id_external_sys       External system identifier
    * @param   i_flg_availability      Type of referring available in the institution
    * @param   o_id_speciality  Speciality identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   22-11-2010
    */
    FUNCTION get_speciality_for_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_external_sys  IN p1_spec_dep_clin_serv.id_external_sys%TYPE,
        i_flg_availability IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        o_id_speciality    OUT p1_speciality.id_speciality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_default_spec
        (
            x_market           IN market.id_market%TYPE,
            x_gender           IN patient.gender%TYPE,
            x_age              IN patient.age%TYPE,
            x_id_ext_sys       IN p1_speciality.id_speciality%TYPE,
            x_flg_availability IN p1_spec_dep_clin_serv.flg_availability%TYPE
        ) IS
            SELECT v.id_speciality
              FROM v_ref_spec_inst_dcs v
            --JOIN p1_speciality s
            --  ON (s.id_speciality = v.id_speciality)
            --JOIN ref_spec_market rsmt
            --  ON (rsmt.id_speciality = s.id_speciality)
             WHERE v.id_dep_clin_serv = i_id_dep_clin_serv
               AND v.flg_spec_dcs_default = pk_ref_constant.g_yes
               AND v.flg_availability IN (x_flg_availability, pk_ref_constant.g_flg_availability_a)
               AND v.id_external_sys IN (x_id_ext_sys, 0)
               AND ((x_gender IS NOT NULL AND
                   nvl(v.gender, pk_ref_constant.g_gender_i) IN (pk_ref_constant.g_gender_i, x_gender)) OR
                   x_gender IS NULL OR x_gender = pk_ref_constant.g_gender_i)
               AND (nvl(x_age, 0) BETWEEN nvl(v.age_min, 0) AND nvl(v.age_max, nvl(x_age, 0)) OR nvl(x_age, 0) = 0)
                  --AND s.flg_available = pk_ref_constant.g_yes
                  --AND rsmt.flg_available = pk_ref_constant.g_yes
               AND v.id_market = x_market
            --AND i_prof.institution NOT IN (SELECT rsi.id_institution
            --                                 FROM ref_spec_institution rsi
            --                                WHERE rsi.id_institution = i_prof.institution
            --                                  AND rsi.flg_available = pk_ref_constant.g_no
            --                                  AND rsi.id_speciality = s.id_speciality)
             ORDER BY v.flg_availability DESC; -- very important to return flg_availability=x and not 'A' (in case of bad configuration)
    
        l_market          market.id_market%TYPE;
        l_pat_info        pk_types.cursor_type;
        l_gender          patient.gender%TYPE;
        l_age             patient.age%TYPE;
        l_id_external_sys p1_spec_dep_clin_serv.id_external_sys%TYPE;
        l_params          VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_dep_clin_serv=' || i_id_dep_clin_serv ||
                    ' i_id_patient=' || i_id_patient || ' i_id_external_sys=' || i_id_external_sys;
        g_error  := 'Init get_speciality_for_dcs / ' || l_params;
        pk_alertlog.log_info(g_error);
    
        l_market          := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
        l_id_external_sys := nvl(i_id_external_sys, 0);
    
        g_error  := 'Call pk_ref_core.get_pat_info / ' || l_params;
        g_retval := pk_ref_core.get_pat_info(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => i_id_patient,
                                             o_info    => l_pat_info,
                                             o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_pat_info / ' || l_params;
        FETCH l_pat_info
            INTO l_gender, l_age;
        CLOSE l_pat_info;
    
        g_error := 'OPEN c_default_spec(' || l_market || ', ' || l_gender || ', ' || l_age || ',' || l_id_external_sys || ',' ||
                   i_flg_availability || ') / ' || l_params;
        OPEN c_default_spec(x_market           => l_market,
                            x_gender           => l_gender,
                            x_age              => l_age,
                            x_id_ext_sys       => l_id_external_sys,
                            x_flg_availability => i_flg_availability);
        FETCH c_default_spec
            INTO o_id_speciality;
    
        g_error := 'o_dcs=' || o_id_speciality || ' / ' || l_params;
        IF c_default_spec%NOTFOUND
        THEN
            g_error := 'No default speciality available. / ID_DEP_CLIN_SERV=' || i_id_dep_clin_serv || ' ID_PATIENT=' ||
                       i_id_patient || ' i_id_external_sys=' || l_id_external_sys || ' / ' || l_params;
            RAISE g_exception;
        END IF;
    
        CLOSE c_default_spec;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_speciality_for_dcs',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_speciality_for_dcs;

    /**
    * speciality_for_dcs_is_OK
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   id_dep_clin_serv  IN  dep_clin_serv.id_dep_clin_serv%TYPE
    *
    * @param   id_speciality  p1_speciality.id_speciality%type
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   22-11-2010
    */
    FUNCTION speciality_for_dcs_is_ok(i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE) RETURN table_number IS
    
        CURSOR c_default_spec IS
            SELECT id_dep_clin_serv
              FROM (SELECT COUNT(decode(flg_spec_dcs_default, pk_ref_constant.g_yes, pk_ref_constant.g_yes, NULL)) nr_count,
                           id_dep_clin_serv
                      FROM p1_spec_dep_clin_serv
                     WHERE id_dep_clin_serv = nvl(i_id_dep_clin_serv, id_dep_clin_serv)
                     GROUP BY id_dep_clin_serv) data
             WHERE nr_count = 0;
    
        l_id_dep_clin_serv  NUMBER;
        tn_id_dep_clin_serv table_number := table_number();
    
    BEGIN
        OPEN c_default_spec;
        FETCH c_default_spec
            INTO l_id_dep_clin_serv;
    
        LOOP
            FETCH c_default_spec
                INTO l_id_dep_clin_serv;
        
            IF c_default_spec%NOTFOUND
            THEN
                CLOSE c_default_spec;
                RETURN tn_id_dep_clin_serv;
            ELSE
                tn_id_dep_clin_serv.extend;
                tn_id_dep_clin_serv(tn_id_dep_clin_serv.count) := l_id_dep_clin_serv;
            END IF;
        END LOOP;
    
        RETURN tn_id_dep_clin_serv;
    END speciality_for_dcs_is_ok;

    /**
    * speciality_for_dcs_multi
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   id_dep_clin_serv  IN  dep_clin_serv.id_dep_clin_serv%TYPE
    *
    * @param   id_speciality  p1_speciality.id_speciality%type
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   22-11-2010
    */
    FUNCTION speciality_for_dcs_multi(i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE) RETURN table_number IS
    
        CURSOR c_default_spec IS
            SELECT id_dep_clin_serv
              FROM (SELECT COUNT(decode(flg_spec_dcs_default, pk_ref_constant.g_yes, pk_ref_constant.g_yes, NULL)) nr_count,
                           id_dep_clin_serv
                      FROM p1_spec_dep_clin_serv
                     WHERE id_dep_clin_serv = nvl(i_id_dep_clin_serv, id_dep_clin_serv)
                     GROUP BY id_dep_clin_serv) data
             WHERE nr_count > 1;
    
        l_id_dep_clin_serv  NUMBER;
        tn_id_dep_clin_serv table_number := table_number();
    
    BEGIN
        OPEN c_default_spec;
        FETCH c_default_spec
            INTO l_id_dep_clin_serv;
    
        LOOP
            FETCH c_default_spec
                INTO l_id_dep_clin_serv;
        
            IF c_default_spec%NOTFOUND
            THEN
                CLOSE c_default_spec;
                RETURN tn_id_dep_clin_serv;
            ELSE
                tn_id_dep_clin_serv.extend;
                tn_id_dep_clin_serv(tn_id_dep_clin_serv.count) := l_id_dep_clin_serv;
            END IF;
        END LOOP;
    
        RETURN tn_id_dep_clin_serv;
    END speciality_for_dcs_multi;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ref_spec_dep_clin_serv;
/
