/*-- Last Change Revision: $Rev: 2027244 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inpatient IS

    /*******************************************************************************************************************************************
    * GET_SERVICES                    GET INPATIENT AVAILABLE DEPARTMENTS WHERE CREATE AN EPISODE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_DPT                    Cursor that returns available department
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dpt   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET DEPARTMENT INFORMATION: OPEN CURSOR O_DPT';
        OPEN o_dpt FOR
            SELECT DISTINCT res.data, res.label, res.rank
              FROM (SELECT dep.id_department data,
                           pk_translation.get_translation(i_lang, dep.code_department) label,
                           dep.rank rank
                      FROM department dep
                     INNER JOIN dept d
                        ON (dep.id_dept = d.id_dept)
                     INNER JOIN dep_clin_serv dcs
                        ON (dcs.id_department = dep.id_department)
                     INNER JOIN clinical_service cs
                        ON (cs.id_clinical_service = dcs.id_clinical_service)
                     WHERE dep.id_institution = i_prof.institution
                       AND d.id_institution = i_prof.institution
                       AND dep.flg_available = pk_alert_constant.g_yes
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND cs.flg_available = pk_alert_constant.g_yes
                       AND instr(dep.flg_type, g_dpt_flg_type_inpatient) > 0) res
             ORDER BY res.rank, res.label;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SERVICES',
                                              o_error);
            pk_types.open_my_cursor(o_dpt);
            RETURN FALSE;
    END get_services;

    /*******************************************************************************************************************************************
    * GET_TRANSFER_SERVICES           GET INPATIENT AVAILABLE DEPARTMENTS TO TRANSFER AN EPISODE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEP_CLIN_SERV       dep_clin_serv identifier                   
    * @param O_DPT                    Cursor that returns available department
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2007/03/19
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_transfer_services
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dpt              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age    NUMBER;
        l_gender patient.gender%TYPE;
    BEGIN
        g_error := 'GET PATIENT AGE';
        l_age   := pk_patient.get_pat_age(i_lang        => i_lang,
                                          i_dt_birth    => NULL,
                                          i_dt_deceased => NULL,
                                          i_age         => NULL,
                                          i_patient     => i_patient);
    
        g_error  := 'GET PATIENT GENDER';
        l_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
    
        g_error := 'GET DEPARTMENT INFORMATION: OPEN CURSOR O_DPT';
        OPEN o_dpt FOR
            SELECT res.data, res.label, res.rank
              FROM (SELECT dep.id_department data,
                           pk_translation.get_translation(i_lang, dep.code_department) label,
                           dep.rank
                      FROM dept d
                     INNER JOIN department dep
                        ON (dep.id_dept = d.id_dept)
                     INNER JOIN software_dept sd
                        ON (sd.id_dept = d.id_dept)
                     WHERE dep.id_institution = i_prof.institution
                       AND dep.id_department NOT IN
                           (SELECT dcs.id_department
                              FROM dep_clin_serv dcs
                             WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv)
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND dep.flg_available = pk_alert_constant.g_yes
                       AND instr(dep.flg_type, 'I') > 0
                       AND sd.id_software = pk_alert_constant.g_soft_inpatient
                       AND (dep.adm_age_min IS NULL OR (dep.adm_age_min IS NOT NULL AND dep.adm_age_min <= l_age) OR
                           l_age IS NULL)
                       AND (dep.adm_age_max IS NULL OR (dep.adm_age_max IS NOT NULL AND dep.adm_age_max >= l_age) OR
                           l_age IS NULL)
                       AND ((dep.gender IS NOT NULL AND dep.gender <> l_gender) OR dep.gender IS NULL)) res
             GROUP BY res.data, res.label, res.rank
             ORDER BY res.rank, res.label;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TRANSFER_SERVICES',
                                              o_error);
            pk_types.open_my_cursor(o_dpt);
            RETURN FALSE;
    END get_transfer_services;

    /*******************************************************************************************************************************************
    * GET_CLINICAL_SERVICES           GET INPATIENT AVAILABLE CLINICAL SERVICES WHERE CREATE AN EPISODE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEPARTMENT          DEPARTMENT identifier                   
    * @param O_DCS                    Cursor that returns available clinical services
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_clinical_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_dcs           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CLINICAL SERVICES INFORMATION: OPEN CURSOR O_DCS';
        OPEN o_dcs FOR
            SELECT dcs.id_dep_clin_serv data, pk_translation.get_translation(i_lang, cs.code_clinical_service) label
              FROM dep_clin_serv dcs
             INNER JOIN clinical_service cs
                ON (dcs.id_clinical_service = cs.id_clinical_service)
             WHERE dcs.id_department = i_id_department
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND cs.flg_available = pk_alert_constant.g_yes
             ORDER BY cs.rank, label;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CLINICAL_SERVICES',
                                              o_error);
            pk_types.open_my_cursor(o_dcs);
            RETURN FALSE;
    END get_clinical_services;

    /*******************************************************************************************************************************************
    * GET_ROOMS                       GET INPATIENT AVAILABLE ROOMS IN AN SPECIFIC DEPARTMENT
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEPARTMENT          DEPARTMENT identifier                   
    * @param O_ROO                    Cursor that returns available rooms
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_roo           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ROOMS INFORMATION: OPEN CURSOR O_ROO';
        OPEN o_roo FOR
            SELECT roo.id_room data, nvl(roo.desc_room, pk_translation.get_translation(i_lang, roo.code_room)) label
              FROM department dep
             INNER JOIN room roo
                ON (roo.id_department = dep.id_department)
             WHERE dep.id_department = i_id_department
               AND instr(dep.flg_type, g_dpt_flg_type_inpatient) > 0
               AND roo.flg_available = pk_alert_constant.g_yes
             ORDER BY roo.rank, label;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOMS',
                                              o_error);
            pk_types.open_my_cursor(o_roo);
            RETURN FALSE;
    END get_rooms;

    /*******************************************************************************************************************************************
    * GET_BEDS                        GET INPATIENT AVAILABLE BEDS IN AN SPECIFIC ROOM
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_ROOM                Room identifier                   
    * @param O_BED                    Cursor that returns available beds
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_beds
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_id_room IN room.id_room%TYPE,
        o_bed     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET BEDS INFORMATION: OPEN CURSOR O_BED';
        OPEN o_bed FOR
            SELECT id_bed data, nvl(b.desc_bed, pk_translation.get_translation(i_lang, code_bed)) label
              FROM bed b
             WHERE b.id_room = i_id_room
               AND b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
               AND b.flg_available = pk_alert_constant.g_yes
               AND b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
             ORDER BY b.rank, label;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED',
                                              o_error);
            pk_types.open_my_cursor(o_bed);
            RETURN FALSE;
    END get_beds;

-- ********************************************************************************
-- ************************************ CONSTRUCTOR *******************************
-- ********************************************************************************
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    -- Constants initialization
    g_dpt_flg_type_inpatient := 'I';

END;
/
