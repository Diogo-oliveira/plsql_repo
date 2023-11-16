/*-- Last Change Revision: $Rev: 2027320 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_list IS

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_origin) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_origin, NULL rank, NULL ordena, NULL origin
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    /**********************************************************************************************
    * Returns 'Y' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  Y
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_available_yes RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_yes;
    END get_flg_available_yes;

    /**********************************************************************************************
    * Returns 'N' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  N
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_available_no RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_no;
    END get_flg_available_no;

    /**********************************************************************************************
    * Returns 'A' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  A
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_state_active RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_active;
    END get_flg_state_active;

    /**********************************************************************************************
    * Returns 'I' to use in SQL queries and to not be necessary to change the constants to values
    * when testing.
    * 
    * @return  I
    * 
    * @author  Eduardo Reis
    * @since   20-04-2010
    **********************************************************************************************/
    FUNCTION get_flg_state_inactive RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_inactive;
    END get_flg_state_inactive;

    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   Língua registada como preferência do profissional
    * @param i_prof                   professional, software and institution ids
    * @param i_speciality             ID da especialidade
    * @param i_prof_cat               professional Category  
    * @param i_dep_clin_serv          ID do departamento + serv. clínico               
    * @param o_prof                   Lista dos professionais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         CRS
    * @since                          2005/03/09
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_speciality    IN professional.id_speciality%TYPE,
        i_category      IN prof_cat.id_category%TYPE,
        i_dep_clin_serv IN prof_dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_internal_error EXCEPTION;
    BEGIN
    
        l_message := 'CALL TO GET_PROF_LIST';
        IF NOT pk_list.get_prof_list(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_speciality      => i_speciality,
                                     i_category        => i_category,
                                     i_dep_clin_serv   => i_dep_clin_serv,
                                     i_flg_option_none => pk_alert_constant.g_no,
                                     o_prof            => o_prof,
                                     o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END get_prof_list;

    /********************************************************************************************
    * Obter lista dos profissionais da instituição (para medicação)
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  o_error                       The error object
    *
    * @return boolean
    *
    * @author Pedro Teixeira
    * @since  23/05/2010
    *
    ********************************************************************************************/
    FUNCTION get_prof_med_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_category IN table_varchar,
        o_prof     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_category table_varchar := table_varchar('D', 'N');
    
    BEGIN
        BEGIN
            IF i_category.count != 0
            THEN
                l_category := i_category;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        l_message := 'GET CURSOR';
    
        OPEN o_prof FOR
            SELECT data, label, TYPE, 1 SUBTYPE, rank, NULL VALUE, NULL unit, NULL unit_desc
              FROM (SELECT v.id_professional AS data,
                           'V' TYPE,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, v.id_professional) label,
                           1 rank
                      FROM (SELECT p.id_professional
                              FROM professional p, prof_cat pc, category c, prof_institution pi
                             WHERE pi.flg_state = pk_alert_constant.g_active
                               AND nvl(p.flg_prof_test, pk_alert_constant.g_no) = pk_alert_constant.g_no
                               AND p.id_professional = pc.id_professional
                               AND p.id_professional = pi.id_professional
                               AND pi.id_institution = i_prof.institution
                               AND pc.id_category = c.id_category
                               AND pc.id_institution = i_prof.institution
                               AND pi.dt_end_tstz IS NULL
                               AND pi.flg_external = pk_alert_constant.g_no
                               AND (c.flg_type IN (SELECT t.column_value
                                                     FROM TABLE(l_category) t) OR p.id_professional = i_prof.id)) v
                    /*UNION ALL - PS - Remove Other option from list
                    SELECT -1 data, 'FT' TYPE, pk_message.get_message(i_lang, 'COMMON_M096') label, 0 rank
                      FROM dual*/
                     ORDER BY rank, label, data);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_MED_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   Língua registada como preferência do profissional
    * @param i_prof                   professional, software and institution ids
    * @param i_speciality             ID da especialidade
    * @param i_prof_cat               professional Category  
    * @param i_dep_clin_serv          ID do departamento + serv. clínico               
    * @param i_flg_option_none        Show option "None"? (Y) Yes (N) No
    * @param o_prof                   Lista dos professionais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         CRS
    * @since                          2005/03/09
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_speciality      IN professional.id_speciality%TYPE,
        i_category        IN prof_cat.id_category%TYPE,
        i_dep_clin_serv   IN prof_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_option_none IN VARCHAR2,
        o_prof            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
    
        OPEN o_prof FOR
            SELECT t.id_professional, t.nick_name
              FROM (SELECT NULL id_professional, pk_message.get_message(i_lang, 'COMMON_M043') nick_name, 0 rank
                      FROM dual
                     WHERE i_flg_option_none = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT p.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                           1 rank
                      FROM professional p
                     INNER JOIN prof_institution pi
                        ON p.id_professional = pi.id_professional
                       AND pi.flg_state = get_flg_state_active()
                     WHERE pi.id_institution = i_prof.institution
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pi.dt_end_tstz IS NULL
                       AND p.id_speciality = nvl(i_speciality, p.id_speciality)
                       AND p.id_professional IN (SELECT pc.id_professional
                                                   FROM prof_cat pc
                                                  WHERE pc.id_category = nvl(i_category, pc.id_category)
                                                    AND pc.id_institution = i_prof.institution)
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes
                       AND p.id_professional IN
                           (SELECT pd.id_professional
                              FROM prof_dep_clin_serv pd
                             WHERE pd.flg_status = g_selected
                               AND pd.id_dep_clin_serv = nvl(i_dep_clin_serv, pd.id_dep_clin_serv))
                     ORDER BY rank, nick_name) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_prof_list',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END;

    FUNCTION get_prof_list_array
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_speciality    IN table_number,
        i_category      IN table_number,
        i_dep_clin_serv IN table_number,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de profissionais da instituição
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_INSTITUTION - ID da instituição. Se ñ for preenchido,
                               considera-se o valor em SYS_CONFIG (opcional)
                       I_SPECIALITY - ID da especialidade (opcional)
                     I_CATEGORY - ID da categoria profissional (opcional)
                     I_DEP_CLIN_SERV - ID do departamento + serv. clínico (opcional)
                  Saida:   O_PROF - array de profissionais
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/09
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
    
        OPEN o_prof FOR
            SELECT p.id_professional data,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                   decode(i_prof.id, p.id_professional, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM professional p
             INNER JOIN prof_institution pi
                ON p.id_professional = pi.id_professional
             WHERE pi.id_institution = i_prof.institution
               AND pi.flg_state = pk_alert_constant.g_active
               AND pi.dt_end_tstz IS NULL
               AND (i_speciality IS NULL OR
                   i_speciality IS NOT NULL AND
                   p.id_speciality IN (SELECT column_value
                                          FROM TABLE(i_speciality)))
               AND p.id_professional IN (SELECT pc.id_professional
                                           FROM prof_cat pc
                                          WHERE (i_category IS NULL OR
                                                i_category IS NOT NULL AND
                                                pc.id_category IN (SELECT column_value
                                                                      FROM TABLE(i_category)))
                                            AND pc.id_institution = i_prof.institution)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND p.id_professional IN
                   (SELECT pd.id_professional
                      FROM prof_dep_clin_serv pd
                     WHERE pd.flg_status = g_selected
                       AND (i_dep_clin_serv IS NULL OR
                           i_dep_clin_serv IS NOT NULL AND
                           pd.id_dep_clin_serv IN (SELECT column_value
                                                      FROM TABLE(i_dep_clin_serv))))
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END get_prof_list_array;

    /**
     * This function returns all professionals associated with a determined
     * category of an institution.
     *
     * @param  IN  Language ID
     * @param  IN  Category ID
     * @param  IN  Institution ID
     * @param  OUT Professional cursor
     * @param  OUT Error structure
     *
     * @return BOOLEAN
     *
     * @since   2009-Mar-12
     * @version 2.4.4
     * @author  Thiago Brito
    */
    FUNCTION get_professionals_by_category
    (
        i_lang          IN language.id_language%TYPE,
        i_category      IN category.id_category%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'OPEN o_professionals';
        OPEN o_professionals FOR
            SELECT p.id_professional data,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    profissional(p.id_professional, i_institution, NULL),
                                                    p.id_professional) AS label
              FROM professional p
             WHERE p.id_professional IN (SELECT pc.id_professional
                                           FROM prof_cat pc
                                          WHERE pc.id_category = i_category
                                            AND pc.id_institution = i_institution);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROFESSIONALS_BY_CATEGORY',
                                              o_error);
            pk_types.open_my_cursor(o_professionals);
            RETURN FALSE;
        
    END get_professionals_by_category;

    --
    FUNCTION get_schedule_list
    (
        i_lang     IN language.id_language%TYPE,
        o_schedule OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de TIPO DE CONSULTAS
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_SCHEDULE - TIPO
                     O_ERROR - erro
        
          CRIAÇÃO: AA 2005/11/24
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_domain_schedule, i_lang, o_schedule);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_schedule_list',
                                              o_error);
            pk_types.open_my_cursor(o_schedule);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Gets the room list inside a department or software (both optional)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_department             department ID (optional)
    * @param i_software               software ID (optional)
    * @param i_msg_other              'Other' code message (if applicable)
    * @param o_room                   Room list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          08-10-2010
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE DEFAULT NULL,
        i_software   IN software.id_software%TYPE DEFAULT NULL,
        i_msg_other  IN sys_message.code_message%TYPE DEFAULT NULL,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ROOM_LIST';
        l_message debug_msg;
        l_flg_other  CONSTANT VARCHAR2(1 CHAR) := 'O';
        l_id_no_room CONSTANT room.id_room%TYPE := -1;
        l_rank_0     CONSTANT room.rank%TYPE := 0;
    
    BEGIN
        l_message := 'GET ROOM LIST';
        OPEN o_room FOR
            SELECT id_room,
                   nvl(desc_room, pk_translation.get_translation(i_lang, code_room)) || ' (' ||
                   pk_bmng_core.get_room_avail_beds_qty(id_room) || '/' ||
                   pk_bmng_core.get_room_beds_qty(id_room, i_prof) || ')' nome_sala,
                   pk_alert_constant.g_no flg_other,
                   rank
              FROM (SELECT DISTINCT r.id_room, r.code_room, r.rank, r.desc_room
                      FROM room r
                      JOIN department d
                        ON r.id_department = d.id_department
                      JOIN software_dept sd
                        ON sd.id_dept = d.id_dept
                     WHERE d.id_department = nvl(i_department, d.id_department)
                       AND r.flg_transp = pk_alert_constant.g_yes
                       AND r.flg_available = pk_alert_constant.g_yes
                       AND d.id_institution = i_prof.institution
                       AND sd.id_software = nvl(i_software, sd.id_software))
            UNION ALL
            SELECT l_id_no_room id_room,
                   pk_message.get_message(i_lang, i_prof, i_msg_other) nome_sala,
                   l_flg_other flg_other,
                   l_rank_0 rank
              FROM dual
             WHERE i_msg_other IS NOT NULL
             ORDER BY flg_other, rank, nome_sala;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END get_room_list;
    --
    /**********************************************************************************************
    * Obter lista de salas da instituição
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_department             department ID (optional)
    * @param i_epis_type              episode type associated with a department
    * @param i_dep_clin_serv          Clinical service and department ID (optional)
    * @param o_room                   Room list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         CRS
    * @version                        1.0 
    * @since                          2005/03/09
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_department    IN room.id_department%TYPE,
        i_epis_type     IN NUMBER,
        i_dep_clin_serv IN room_dep_clin_serv.id_dep_clin_serv%TYPE,
        o_room          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_message debug_msg;
    
    BEGIN
    
        l_message := 'CALL TO GET_ROOM_LIST';
        IF NOT get_room_list(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_department => i_department,
                             o_room       => o_room,
                             o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_room_list',
                                              o_error);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END get_room_list;
    --
    FUNCTION get_country_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de países
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_COUNTRY - países
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
        l_default_country sys_config.value%TYPE;
        l_message         debug_msg;
    
    BEGIN
        -- luís gaspar, 2007-nov-14
        -- o get_sys_config passou para fora do sql
        l_message         := 'GET DEFAULT COUNTRY';
        l_default_country := pk_sysconfig.get_config('ID_COUNTRY', i_prof.institution, i_prof.software);
        l_message         := 'GET CURSOR';
        OPEN o_country FOR
            SELECT id_country,
                   1 rank,
                   pk_translation.get_translation(i_lang, code_country) country,
                   decode(id_country, l_default_country, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM country
             WHERE flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_country,
                   -1 rank,
                   pk_message.get_message(i_lang, 'COMMON_M002') country,
                   pk_alert_constant.g_no flg_default
              FROM dual
             ORDER BY rank, country;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_country_list',
                                              o_error);
            pk_types.open_my_cursor(o_country);
            RETURN FALSE;
    END;
    --
    FUNCTION get_isencao_list
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_isencao OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de regimes de isenção
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_ISENCAO - regime de isenção
                     O_ERROR - erro
        
          CRIAÇÃO: SS 2005/09/20
          NOTAS:
        *********************************************************************************/
        CURSOR c_pat IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        r_pat     c_pat%ROWTYPE;
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        l_message := 'GET CURSOR';
        OPEN o_isencao FOR
            SELECT id_isencao, 1 rank, pk_translation.get_translation(i_lang, code_isencao) isencao
              FROM isencao i
             WHERE flg_available = pk_alert_constant.g_yes
               AND ((r_pat.gender IS NOT NULL AND nvl(i.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
                   r_pat.gender = 'I')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND nvl(i.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
            UNION ALL
            SELECT -1 id_isencao, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') isencao
              FROM dual
             ORDER BY rank, isencao;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_isencao_list',
                                              o_error);
            pk_types.open_my_cursor(o_isencao);
            RETURN FALSE;
    END;
    --

    FUNCTION get_recm_description_list
    (
        i_lang  IN language.id_language%TYPE,
        o_recm  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de RECM COM DESCRIÇÃO
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida: O_RECM - códigos RECM
                 O_ERROR - erro
        
          CRIAÇÃO: LG 2006/JAN/24
          ---
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'CALL PK_ADT.GET_RECM_DESCRIPTION_LIST';
        IF NOT pk_adt.get_recm_description_list(i_lang => i_lang, i_prof => NULL, o_recm => o_recm, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_recm_description_list',
                                              o_error);
            pk_types.open_my_cursor(o_recm);
            RETURN FALSE;
    END;
    --
    FUNCTION get_scholarship_list
    (
        i_lang        IN language.id_language%TYPE,
        o_scholarship OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de habilitações literárias
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_SCHOLARSHIP - níveis de escolaridade
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_scholarship FOR
            SELECT id_scholarship, rank, pk_translation.get_translation(i_lang, code_scholarship) scholarship
              FROM scholarship
             WHERE flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_scholarship, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') scholarship
              FROM dual
             ORDER BY rank, scholarship;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_scholarship_list',
                                              o_error);
            pk_types.open_my_cursor(o_scholarship);
            RETURN FALSE;
    END;

    FUNCTION get_religion_list
    (
        i_lang     IN language.id_language%TYPE,
        o_religion OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de religiões
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_RELIGION - religiões
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_religion FOR
            SELECT id_religion, rank, pk_translation.get_translation(i_lang, code_religion) religion
              FROM religion
             WHERE flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_religion, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') religion
              FROM dual
             ORDER BY rank, religion;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_religion_list',
                                              o_error);
            pk_types.open_my_cursor(o_religion);
            RETURN FALSE;
    END;

    FUNCTION get_gender_list
    (
        i_lang   IN language.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de sexos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_GENDER - sexo
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_domain_gender, i_lang, o_gender);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_gender_list',
                                              o_error);
            pk_types.open_my_cursor(o_gender);
            RETURN FALSE;
    END;

    FUNCTION get_instit_list
    (
        i_lang   IN language.id_language%TYPE,
        i_type   IN institution.flg_type%TYPE,
        o_instit OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de instituição
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_TYPE - tipo de instituição:  H - hospital,
                                          C - centro de saúde,
                                    P - clínica privada
                  Saida:   O_INSTIT - instituições
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_instit FOR
            SELECT id_institution,
                   abbreviation,
                   barcode,
                   rank,
                   pk_translation.get_translation(i_lang, code_institution) institution
              FROM institution
             WHERE flg_available = pk_alert_constant.g_yes
               AND flg_type = nvl(i_type, flg_type)
            UNION ALL
            SELECT -1 id_institution,
                   '' abbreviation,
                   '' barcode,
                   -1 rank,
                   pk_message.get_message(i_lang, 'COMMON_M002') institution
              FROM dual
             ORDER BY rank, institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_instit_list',
                                              o_error);
            pk_types.open_my_cursor(o_instit);
            RETURN FALSE;
    END;

    /*FUNCTION GET_HPLAN_LIST ( I_LANG IN LANGUAGE.ID_LANGUAGE%TYPE,
              I_TYPE IN HEALTH_PLAN.FLG_TYPE%TYPE,
              O_HPLAN OUT PK_TYPES.CURSOR_TYPE, o_error        OUT t_error_out) RETURN BOOLEAN IS
    /******************************************************************************
       OBJECTIVO:   Obter lista de Serviços / subsistemas / seguros de saúde
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
              Saida:   O_HPLAN - Serviços / subsistemas / seguros de saúde
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/03/14
      NOTAS:
    *********************************************************************************/
    /*        l_message debug_msg;
    BEGIN
      l_message := 'GET CURSOR';
      OPEN O_HPLAN FOR 'SELECT ID_HEALTH_PLAN, RANK, '||
                  'PK_TRANSLATION.GET_TRANSLATION('||I_LANG||', CODE_HEALTH_PLAN) HEALTH_PLAN '||
                  'FROM HEALTH_PLAN '||
              'WHERE FLG_AVAILABLE = '''||pk_alert_constant.g_yes||''''||
              ' AND FLG_TYPE = NVL('''||I_TYPE||''', FLG_TYPE)'||
              ' UNION ALL '||
              'SELECT -1 ID_HEALTH_PLAN, -1 RANK, '||
              'PK_MESSAGE.GET_MESSAGE('||I_LANG||', ''COMMON_M002'') HEALTH_PLAN '||
              'FROM DUAL '||
              ' ORDER BY RANK, HEALTH_PLAN';
    
    RETURN TRUE;
    
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR := PK_MESSAGE.GET_MESSAGE(I_LANG, 'COMMON_M001') || CHR(10)|| 'PK_LIST.GET_HPLAN_LIST / ' || l_message || ' / ' || SQLERRM;
        PK_TYPES.OPEN_MY_CURSOR(O_HPLAN);
        RETURN FALSE;
    END;
    */

    FUNCTION get_hplan_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_hplan OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de Serviços / subsistemas / seguros de saúde
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_PROF - profissional que acede
                  Saida: O_HPLAN - Serviços / subsistemas / seguros de saúde
                 O_ERROR - erro
        
          CRIAÇÃO: SS 2006/04/08
          NOTAS:
        *********************************************************************************/
        l_soft    software.id_software%TYPE;
        l_message debug_msg;
    
        l_hp_other     health_plan.id_health_plan%TYPE;
        l_hp_other_cnt health_plan.id_content%TYPE;
    
    BEGIN
        l_hp_other_cnt := pk_sysconfig.get_config('HEALTH_PLAN_OTHER', i_prof);
    BEGIN
            SELECT hp.id_health_plan
              INTO l_hp_other
              FROM health_plan hp
             WHERE hp.id_content = l_hp_other_cnt
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_hp_other := NULL;
        END;
    
        l_soft := to_number(pk_sysconfig.get_config('SOFTWARE_ID_P1', i_prof));
        -- If referral software
        IF i_prof.software = l_soft
        THEN
            l_message := 'GET CURSOR';
            OPEN o_hplan FOR
                SELECT hp.id_health_plan data,
                       pk_translation.get_translation(i_lang, code_health_plan) label,
                       decode(pk_sysconfig.get_config('ID_HPLAN', i_prof.institution, i_prof.software),
                              hp.id_health_plan,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) flg_default,
                       decode(hp.id_health_plan, l_hp_other, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_other
                  FROM health_plan hp
                 WHERE hp.flg_available = pk_alert_constant.g_yes
                   AND pk_translation.get_translation(i_lang, code_health_plan) IS NOT NULL
                 ORDER BY rank, label;
        ELSE
            l_message := 'GET CURSOR';
            OPEN o_hplan FOR
                SELECT hp.id_health_plan data,
                       pk_translation.get_translation(i_lang, code_health_plan) label,
                       decode(pk_sysconfig.get_config('ID_HPLAN', i_prof.institution, i_prof.software),
                              hp.id_health_plan,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) flg_default,
                       decode(hp.id_health_plan, l_hp_other, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_other
                  FROM health_plan hp, health_plan_instit hpi
                 WHERE hp.flg_available = pk_alert_constant.g_yes
                   AND hpi.id_health_plan = hp.id_health_plan
                   AND hpi.id_institution = i_prof.institution
                   AND pk_translation.get_translation(i_lang, code_health_plan) IS NOT NULL
                 ORDER BY rank, label;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_hplan_list',
                                              o_error);
            pk_types.open_my_cursor(o_hplan);
            RETURN FALSE;
    END;

    FUNCTION get_doc_type_list
    (
        i_lang     IN language.id_language%TYPE,
        o_doc_type OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de docs
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_DOC_TYPE - tipos de docs
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_doc_type FOR
            SELECT d.id_doc_type, d.rank, pk_translation.get_translation(i_lang, d.code_doc_type) doc_type
              FROM doc_type d
             INNER JOIN doc_types_config dtc
                ON dtc.id_doc_type = d.id_doc_type
             WHERE d.flg_available = pk_alert_constant.g_yes
                  --This was referencing directly a column that was discontinued
                  --The column was changed but hardcoded variables remained the same
               AND dtc.id_doc_ori_type_parent = 1
                  --As we do not have i_prof variable we can only search for default (0) values
               AND dtc.id_institution = 0
               AND dtc.id_software = 0
            --UNION ALL
            --SELECT -1 id_doc_type, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') doc_type
            --  FROM dual
             ORDER BY rank, doc_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_doc_type_list',
                                              o_error);
            pk_types.open_my_cursor(o_doc_type);
            RETURN FALSE;
    END;

    FUNCTION get_occup_list
    (
        i_lang  IN language.id_language%TYPE,
        o_occup OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de profissões
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_OCCUP - profissões
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_occup FOR
            SELECT id_occupation, rank, pk_translation.get_translation(i_lang, code_occupation) occupation
              FROM occupation
             WHERE pk_translation.get_translation(i_lang, code_occupation) IS NOT NULL
               AND flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_occupation, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') occupation
              FROM dual
             ORDER BY rank, occupation;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_occup_list',
                                              o_error);
            pk_types.open_my_cursor(o_occup);
            RETURN FALSE;
    END;

    FUNCTION get_marital_list
    (
        i_lang    IN language.id_language%TYPE,
        o_marital OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de estados civis
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_MARITAL - estado civil
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_marital FOR
            SELECT val, rank, desc_val marital
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_marital
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT '-1' val, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') marital
              FROM dual
             ORDER BY rank, marital;
    
        pk_backoffice_translation.set_read_translation(g_domain_marital, 'SYS_DOMAIN');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_marital_list',
                                              o_error);
            pk_types.open_my_cursor(o_marital);
            RETURN FALSE;
    END;

    FUNCTION get_job_stat_list
    (
        i_lang     IN language.id_language%TYPE,
        o_job_stat OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de estados profissionais
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_JOB_STAT - estados profissionais
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          ----
          ALERTADO POR: Ricardo Patrocinio 2009/03/19
          NOTAS: Substiuit a ordenação de desc_val pelo Rank
          ----
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_job_stat FOR
            SELECT val, rank, desc_val, rank ordena
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_job_stat
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT '-1' val, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') desc_val, -1 ordena
              FROM dual
             ORDER BY ordena;
    
        pk_backoffice_translation.set_read_translation(g_domain_job_stat, 'SYS_DOMAIN');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_job_stat_list',
                                              o_error);
            pk_types.open_my_cursor(o_job_stat);
            RETURN FALSE;
    END;

    FUNCTION get_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_cat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de categorias
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_CAT - categorias
                     O_ERROR - erro
        
          CRIAÇÃO: SS 2005/08/26
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_cat FOR
            SELECT id_category,
                   1 rank,
                   pk_translation.get_translation(i_lang, code_category) category,
                   decode(flg_type, 'D', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_clinical
              FROM category
             WHERE flg_available = pk_alert_constant.g_yes
               AND flg_prof = pk_alert_constant.g_yes
             ORDER BY category;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_cat_list',
                                              o_error);
            pk_types.open_my_cursor(o_cat);
            RETURN FALSE;
    END;

    FUNCTION get_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        o_spec  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de espeialidades
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_SPEC - especialidades
                     O_ERROR - erro
        
          CRIAÇÃO: SS 2005/08/26
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_spec FOR
            SELECT id_speciality, 1 rank, pk_translation.get_translation(i_lang, code_speciality) speciality
              FROM speciality
             WHERE flg_available = pk_alert_constant.g_yes
             ORDER BY speciality;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_spec_list',
                                              o_error);
            pk_types.open_my_cursor(o_spec);
            RETURN FALSE;
    END;

    FUNCTION get_origin_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_origin OUT cursor_origin,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de origens
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 i_prof   IN profissional,
                        Saida:   O_ORIGIN - origens
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_origin FOR
            SELECT id_origin, rank, text ordena, text origin
              FROM (SELECT o.id_origin, o.rank, pk_translation.get_translation(i_lang, o.code_origin) text
                      FROM origin o
                     INNER JOIN origin_soft_inst osi
                        ON o.id_origin = osi.id_origin
                     WHERE o.flg_available = pk_alert_constant.g_yes
                       AND osi.id_software IN (0, i_prof.software)
                       AND osi.id_institution IN (0, i_prof.institution))
             WHERE text IS NOT NULL
             ORDER BY rank, ordena;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_origin_list',
                                              o_error);
            open_my_cursor(o_origin);
            RETURN FALSE;
    END;

    FUNCTION get_ext_cause_list
    (
        i_lang      IN language.id_language%TYPE,
        o_ext_cause OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de causas externas
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_EXT_CAUSE - causas externas
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_ext_cause FOR
            SELECT id_external_cause, rank, external_cause
              FROM (SELECT id_external_cause,
                           rank,
                           pk_translation.get_translation(i_lang, code_external_cause) external_cause
                      FROM external_cause
                     WHERE flg_available = pk_alert_constant.g_yes)
             WHERE external_cause IS NOT NULL
            UNION ALL
            SELECT -1 id_external_cause, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') external_cause
              FROM dual
             ORDER BY rank, external_cause;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_ext_cause_list',
                                              o_error);
            pk_types.open_my_cursor(o_ext_cause);
            RETURN FALSE;
    END;

    FUNCTION get_all_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de serviços clínicos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_CLIN_SERV - serviços clínicos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_clin_serv FOR
            SELECT id_clinical_service,
                   rank,
                   pk_translation.get_translation(i_lang, code_clinical_service) clinical_service
              FROM clinical_service
            UNION ALL
            SELECT -1 id_clinical_service, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') clinical_service
              FROM dual
             ORDER BY rank, clinical_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_all_clin_serv_list',
                                              o_error);
            pk_types.open_my_cursor(o_clin_serv);
            RETURN FALSE;
    END;

    FUNCTION get_dep_clin_serv_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de serviços clínicos de 1 departamento
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_CLIN_SERV - serviços clínicos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_clin_serv FOR
            SELECT dcs.id_dep_clin_serv,
                   c.id_clinical_service data,
                   c.rank,
                   pk_translation.get_translation(i_lang, c.code_clinical_service) label,
                   dcs.flg_show_warning flg_show_warning
              FROM clinical_service c, dep_clin_serv dcs
             WHERE dcs.id_clinical_service = c.id_clinical_service
               AND dcs.id_dep_clin_serv != i_id_dep_clin_serv
               AND dcs.id_department = i_id_department
               AND dcs.flg_available = pk_alert_constant.g_yes
             ORDER BY c.rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_dep_clin_serv_list',
                                              o_error);
            pk_types.open_my_cursor(o_clin_serv);
            RETURN FALSE;
    END;

    FUNCTION get_epis_type_list
    (
        i_lang      IN language.id_language%TYPE,
        o_epis_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_EPIS_TYPE - tipos de episódio
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_epis_type FOR
            SELECT id_epis_type, rank, pk_translation.get_translation(i_lang, code_epis_type) epis_type
              FROM epis_type
             WHERE flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_epis_type, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') epis_type
              FROM dual
             ORDER BY rank, epis_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_type_list',
                                              o_error);
            pk_types.open_my_cursor(o_epis_type);
            RETURN FALSE;
    END;

    FUNCTION get_epis_type_list_with_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_epis_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_EPIS_TYPE - tipos de episódio
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/14
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_epis_type FOR
            SELECT DISTINCT et.id_epis_type,
                            et.rank,
                            pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                            1 i_mode
              FROM epis_type et
              JOIN epis_type_soft_inst ets
                ON ets.id_epis_type = et.id_epis_type
              JOIN ab_software_institution asi
                ON (asi.id_ab_institution IN (ets.id_institution, i_prof.institution) AND
                   asi.id_ab_software = ets.id_software)
             WHERE et.flg_available = 'Y'
               AND ets.id_institution IN (i_prof.institution, 0)
            UNION ALL
            SELECT 0 id_epis_type,
                   0 rank,
                   pk_translation.get_translation(i_lang, 'VIEW_OPTION.CODE_VIEW_OPTION.4000') epis_type,
                   0 i_mode
              FROM dual
             ORDER BY i_mode, epis_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_type_list_with_all',
                                              o_error);
            pk_types.open_my_cursor(o_epis_type);
            RETURN FALSE;
    END get_epis_type_list_with_all;

    FUNCTION get_vacc_list
    (
        i_lang  IN language.id_language%TYPE,
        o_vacc  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de vacinas
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_VACC - vacinas
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/17
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        OPEN o_vacc FOR
            SELECT id_vaccine, rank, pk_translation.get_translation(i_lang, code_vaccine) vacc
              FROM vaccine
             WHERE flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_epis_type, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002')
              FROM dual
             ORDER BY rank, vacc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_vacc_list',
                                              o_error);
            pk_types.open_my_cursor(o_vacc);
            RETURN FALSE;
    END;

    FUNCTION get_vacc_take_type_list
    (
        i_lang  IN language.id_language%TYPE,
        o_vacc  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de tomas de vacinas
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_VACC - tipos de tomas de vacinas
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/17
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_vacc FOR
            SELECT val, rank, desc_val vacc
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_vaccine
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT '' val, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') vacc
              FROM dual
             ORDER BY rank, vacc;
    
        pk_backoffice_translation.set_read_translation(g_domain_vaccine, 'SYS_DOMAIN');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_vacc_take_type_list',
                                              o_error);
            pk_types.open_my_cursor(o_vacc);
            RETURN FALSE;
    END;

    --

    FUNCTION get_active_cancel_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista: activo / cancelado
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_LIST - lista de valores activo / cancelado
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/22
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_active_cancel, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_active_cancel_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    FUNCTION get_active_inactive_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista: activo / inactivo
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_LIST - lista de valores activo / inactivo
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/22
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_active_inactive, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_active_inactive_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    FUNCTION get_yes_no_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista: sim / não
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_LIST - lista de valores
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/22
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_yes_no, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_yes_no_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    FUNCTION get_prof_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os diagnósticos +  frequentes de um profissional
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_PROF - profissional
                  Saida:   O_DIAGNOSIS - lista de diagnósticos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/12
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_diagnosis FOR
            SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) diag,
                   d.id_diagnosis,
                   d.code_icd
              FROM diagnosis_content d
             WHERE d.id_professional = i_prof.id
               AND d.id_institution = i_prof.institution
               AND d.flg_available = pk_alert_constant.g_yes
               AND d.flg_select = pk_alert_constant.g_yes
               AND d.flg_type IN
                   (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                     column_value flg_terminology
                      FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
             ORDER BY d.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_prof_diag',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;

    FUNCTION get_dcs_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_dep_clin_serv IN diagnosis_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_prof          IN profissional,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os diagnósticos +  frequentes de um dep. + serv clínico
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_DEP_CLIN_SERV - dep. + serv clínico
                  Saida:   O_DIAGNOSIS - lista de diagnósticos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/12
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_diagnosis FOR
            SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) diag,
                   d.id_diagnosis,
                   d.code_icd
              FROM diagnosis_content d
             WHERE d.id_dep_clin_serv = i_dep_clin_serv
               AND d.flg_select = pk_alert_constant.g_yes
               AND d.flg_type_dep_clin = g_diag_freq
               AND d.id_software = i_prof.software
               AND d.flg_type IN
                   (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                     column_value flg_terminology
                      FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
             ORDER BY d.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_dcs_diag',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;

    FUNCTION get_freq_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os diagnósticos +  frequentes de um prof. e do dep. + serv
                  clínico a q está associado
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - profissional
                                 I_PATIENT - ID do doente
                  Saida:   O_DIAGNOSIS - lista de diagnósticos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/31
          NOTAS:
        *********************************************************************************/
        CURSOR c_instit IS
            SELECT i.flg_type
              FROM institution i
             WHERE i.id_institution = i_prof.institution;
    
        l_inst_type institution.flg_type%TYPE;
    
        CURSOR c_pat IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age --, (SYSDATE-DT_BIRTH) DAYS
              FROM patient
             WHERE id_patient = i_patient;
        r_pat     c_pat%ROWTYPE;
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        l_message := 'OPEN C_INSTIT';
        OPEN c_instit;
        FETCH c_instit
            INTO l_inst_type;
        CLOSE c_instit;
    
        l_message := 'GET CURSOR';
        OPEN o_diagnosis FOR
            SELECT DISTINCT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_diagnosis => d.id_diagnosis,
                                                       i_code         => d.code_icd,
                                                       i_flg_other    => d.flg_other,
                                                       i_flg_std_diag => pk_alert_constant.g_yes) diag,
                            d.id_diagnosis,
                            d.code_icd,
                            d.rank
              FROM diagnosis_content d,
                   (SELECT pd.id_dep_clin_serv
                      FROM prof_dep_clin_serv pd
                     WHERE pd.id_professional = i_prof.id
                       AND pd.flg_status = g_selected
                       AND pd.id_institution = i_prof.institution) z
             WHERE (d.id_dep_clin_serv = z.id_dep_clin_serv OR d.id_professional = i_prof.id)
               AND d.id_software = i_prof.software
               AND d.flg_select = pk_alert_constant.g_yes
               AND d.flg_type_dep_clin = g_diag_freq
               AND ((r_pat.gender IS NOT NULL AND nvl(d.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
                   r_pat.gender = 'I')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(d.age_min, 0) AND nvl(d.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
               AND d.flg_type IN
                   (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                     column_value flg_terminology
                      FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
             ORDER BY rank, diag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_freq_diag',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;

    FUNCTION get_all_diag
    (
        i_lang      IN language.id_language%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de todos os diagnósticos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_DIAGNOSIS - lista de diagnósticos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/31
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_diagnosis FOR
            SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => NULL,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) diag,
                   d.id_diagnosis,
                   d.code_icd
              FROM diagnosis d
             WHERE d.flg_available = pk_alert_constant.g_yes
               AND d.flg_select = pk_alert_constant.g_yes
             ORDER BY diag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_all_diag',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;

    FUNCTION get_cat_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO  :   Obter lista de diagóstios dos vários níveis. se I_ID_PARENT for null, tráz os diagnósticos de 1º nível,
                               senão, tráz todos os diagnósticos "filhos" do seleccionado.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_PARENT - ID do diagnóstico "pai" seleccionado.
                                      Se for NULL, traz os diagnósticos de 1º nível
                                 I_PATIENT - ID do doente
                  Saida: O_LIST - array de diagnósticos
                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/18
          NOTAS: LG 2007-Mar-21 entrar em conta com a configuração de tipos de diagnóstico em uso no software/instituição
        *********************************************************************************/
        l_message debug_msg;
    
        l_tbl_diags t_coll_diagnosis_config;
    BEGIN
        l_message   := 'CALL PK_DIAGNOSIS_CORE.TF_DIAGNOSES_LIST';
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => i_patient,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_synonym_list_enable      => pk_alert_constant.g_no,
                                                               i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                               i_parent_diagnosis         => i_id_parent,
                                                               i_only_diag_filter_by_prt  => pk_alert_constant.g_yes);
    
        l_message := 'GET CURSOR';
        OPEN o_list FOR
            SELECT d.id_diagnosis,
                   d.id_alert_diagnosis,
                   d.desc_diagnosis      desc_diagnsis,
                   d.id_diagnosis_parent,
                   d.avail_for_select    flg_select
              FROM TABLE(l_tbl_diags) d;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_cat_diag',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_cat_diag;

    FUNCTION get_cat_diag_death
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_section   IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO  :   Obter lista de diagóstios dos vários níveis. se I_ID_PARENT for null, tráz os diagnósticos de 1º nível,
                               senão, tráz todos os diagnósticos "filhos" do seleccionado.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_PARENT - ID do diagnóstico "pai" seleccionado.
                                      Se for NULL, traz os diagnósticos de 1º nível
                                 I_PATIENT - ID do doente
                  Saida: O_LIST - array de diagnósticos
                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/18
          NOTAS: LG 2007-Mar-21 entrar em conta com a configuração de tipos de diagnóstico em uso no software/instituição
        *********************************************************************************/
        l_message debug_msg;
    
        l_tbl_diags        t_coll_diagnosis_config;
        l_filter_diagnosis sys_config.value%TYPE;
    
    BEGIN
        l_filter_diagnosis := pk_sysconfig.get_config('DEATH_REGISTRY_DIAG_FILTER_MX_CAT', i_prof);
    
        l_message   := 'CALL PK_DIAGNOSIS_CORE.TF_DIAGNOSES_LIST';
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => i_patient,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_synonym_list_enable      => pk_alert_constant.g_no,
                                                               i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                               i_parent_diagnosis         => i_id_parent,
                                                               i_only_diag_filter_by_prt  => pk_alert_constant.g_yes);
    
        IF l_filter_diagnosis = pk_alert_constant.g_yes
        THEN
            l_message := 'GET CURSOR filter';
            OPEN o_list FOR
                SELECT d.id_diagnosis,
                       d.id_alert_diagnosis,
                       d.desc_diagnosis      desc_diagnsis,
                       d.id_diagnosis_parent,
                       d.avail_for_select    flg_select
                  FROM TABLE(l_tbl_diags) d
                  JOIN cat_diagnosis cd
                    ON cd.id_concept_term = d.id_alert_diagnosis
                 WHERE ((cd.no_cbd = 'F' AND i_section = 'DEATH_DATA') OR
                       (cd.fetal = 'T' AND i_section = 'DEATH_DATA_FETAL'))
                   AND cd.flg_available = 'Y';
        ELSE
            l_message := 'GET CURSOR';
            OPEN o_list FOR
                SELECT d.id_diagnosis,
                       d.id_alert_diagnosis,
                       d.desc_diagnosis      desc_diagnsis,
                       d.id_diagnosis_parent,
                       d.avail_for_select    flg_select
                  FROM TABLE(l_tbl_diags) d;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_cat_diag',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_cat_diag_death;

    FUNCTION get_epis_diag_type
    (
        i_lang      IN language.id_language%TYPE,
        o_diag_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de diagnóstico
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_DIAG_TYPE - tipos de diagnóstico
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/18
          NOTAS:
        *********************************************************************************/
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_domain_diagnosis, i_lang, o_diag_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_diag_type',
                                              o_error);
            pk_types.open_my_cursor(o_diag_type);
            RETURN FALSE;
    END;

    FUNCTION get_pat_probl_type
    (
        i_lang      IN language.id_language%TYPE,
        o_pat_probl OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de valores possíveis para PAT_PROBLEM.FLG_TYPE
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_PAT_PROBL - lista de valores
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/22
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_pat_probl_type, i_lang, o_pat_probl);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_pat_probl_type',
                                              o_error);
            pk_types.open_my_cursor(o_pat_probl);
            RETURN FALSE;
    END;

    FUNCTION get_pat_probl_age
    (
        i_lang      IN language.id_language%TYPE,
        o_pat_probl OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de valores possíveis para PAT_PROBLEM .FLG_AGE
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_PAT_PROBL - lista de valores
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/23
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_pat_probl_age, i_lang, o_pat_probl);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_pat_probl_age',
                                              o_error);
            pk_types.open_my_cursor(o_pat_probl);
            RETURN FALSE;
    END;

    FUNCTION get_primary_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de alergias de 1ª categoria
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - Object (ID of professional, ID of institution, ID of software)
                        Saida:   O_ALLERGY - lista de alergias de 1ª categoria
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/23
          ALTERAÇÃO: Tiago Silva 2008/06/04 - Passou a ser utilizada a tabela ALLERGY_INST_SOFT
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_allergy FOR
            SELECT alg.id_allergy,
                   alg.rank AS rank_alg,
                   alg_inst_soft.rank AS rank_alg_inst_soft,
                   alg.flg_select,
                   pk_translation.get_translation(i_lang, alg.code_allergy) allergy
              FROM allergy alg, allergy_inst_soft alg_inst_soft
             WHERE alg.id_allergy = alg_inst_soft.id_allergy
               AND alg.flg_available = pk_alert_constant.g_yes
               AND alg.flg_active = pk_alert_constant.g_active
               AND (alg_inst_soft.id_institution, alg_inst_soft.id_software) =
                   (SELECT MAX(ais1.id_institution), MAX(ais1.id_software)
                      FROM allergy_inst_soft ais1
                     WHERE ais1.id_allergy = alg_inst_soft.id_allergy
                       AND ais1.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND ais1.id_software IN (i_prof.software, pk_alert_constant.g_soft_all))
               AND id_allergy_parent IS NULL
             ORDER BY rank_alg_inst_soft, rank_alg, allergy;
    
        -- Nota: a condição "WHERE allergy IS NOT NULL" foi retirada, pois dever-se-á parametrizar as alergias por instituição
        -- e não usar a ausencia de tradução como filtro    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_primary_allergy',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            RETURN FALSE;
    END;

    FUNCTION get_secondary_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_allergy IN allergy.id_allergy%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de alergias de 1ª categoria
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - Object (ID of professional, ID of institution, ID of software)
                        Saida:   O_ALLERGY - lista de alergias de 1ª categoria
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/23
          ALTERAÇÃO: Tiago Silva 2008/06/04 - Passou a ser utilizada a tabela ALLERGY_INST_SOFT         
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_allergy FOR
            SELECT alg.id_allergy,
                   alg.rank AS rank_alg,
                   alg_inst_soft.rank AS rank_alg_inst_soft,
                   alg.flg_select,
                   pk_translation.get_translation(i_lang, alg.code_allergy) allergy
              FROM allergy alg, allergy_inst_soft alg_inst_soft
             WHERE alg.id_allergy = alg_inst_soft.id_allergy
               AND alg.flg_available = pk_alert_constant.g_yes
               AND alg.flg_active = pk_alert_constant.g_active
               AND (alg_inst_soft.id_institution, alg_inst_soft.id_software) =
                   (SELECT MAX(ais1.id_institution), MAX(ais1.id_software)
                      FROM allergy_inst_soft ais1
                     WHERE ais1.id_allergy = alg_inst_soft.id_allergy
                       AND ais1.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND ais1.id_software IN (i_prof.software, pk_alert_constant.g_soft_all))
               AND alg.id_allergy_parent = i_allergy
             ORDER BY rank_alg_inst_soft, rank_alg, allergy;
    
        -- Nota: a condição "WHERE allergy IS NOT NULL" foi retirada, pois dever-se-á parametrizar as alergias por instituição
        -- e não usar a ausencia de tradução como filtro
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_secondary_allergy',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            RETURN FALSE;
    END;

    FUNCTION get_allergy_type
    (
        i_lang    IN language.id_language%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de reacção: I - reacção idiossincrática, A - alergia
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_ALLERGY - lista
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/23
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_allergy_type, i_lang, o_allergy);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_allergy_type',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            RETURN FALSE;
    END;

    FUNCTION get_allergy_appr
    (
        i_lang    IN language.id_language%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de modos de obtenção do registo de alergia:
                  U - relatada pelo utente, M - comprovada clinicamente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_ALLERGY - lista
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/23
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_allergy_appr, i_lang, o_allergy);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_allergy_appr',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            RETURN FALSE;
    END;

    FUNCTION get_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de departamentos de uma instituição
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_INSTIT - instituição
                  Saida:   O_DEPARTMENT - lista de departamentos de uma instituição
                           O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/25
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_department FOR
            SELECT id_department, abbreviation, pk_translation.get_translation(i_lang, code_department) department
              FROM department d
             WHERE id_institution = i_prof.institution
               AND EXISTS (SELECT r.id_department
                      FROM room r
                     WHERE r.id_department = d.id_department
                       AND r.flg_transp = pk_alert_constant.g_yes
                       AND r.flg_available = pk_alert_constant.g_yes)
               AND d.flg_available = pk_alert_constant.g_yes
             ORDER BY rank, department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_department',
                                              o_error);
            pk_types.open_my_cursor(o_department);
            RETURN FALSE;
    END;

    FUNCTION get_cons_req_prof_accept_deny
    (
        i_lang  IN language.id_language%TYPE,
        o_read  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de valores p/ CONSULT_REQ_PROF.FLG_READ
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_READ - valores possíveis
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/25
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cons_req_prof_accept_deny, i_lang, o_read);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_cons_req_prof_accept_deny',
                                              o_error);
            pk_types.open_my_cursor(o_read);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Returns is discharge reason is default ou not 
    * 
    * @return  A or I
    * 
    * @author        Elisabete Bugalho 
    * @version       2.6.3.4
    * @date          2013/04/17
    **********************************************************************************************/
    FUNCTION is_disch_reason_def
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_discharge_reason IN discharge_reason.id_discharge_reason%TYPE
    ) RETURN VARCHAR2 IS
        l_default disch_reas_dest.flg_default%TYPE;
    BEGIN
        SELECT decode(flg_default, pk_alert_constant.g_yes, pk_alert_constant.g_active, pk_alert_constant.g_inactive)
          INTO l_default
          FROM (SELECT drd.flg_default,
                       row_number() over(ORDER BY decode(drd.flg_default, pk_alert_constant.g_yes, 1, 2)) line_number
                  FROM disch_reas_dest drd
                 WHERE drd.id_discharge_reason = i_discharge_reason
                   AND drd.flg_active = pk_alert_constant.g_active
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = i_prof.software)
         WHERE line_number = 1;
        RETURN l_default;
    END is_disch_reason_def;

    FUNCTION get_discharge_reason_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cat_type        IN category.flg_type%TYPE,
        i_flg_type        IN VARCHAR2,
        i_id_episode      IN episode.id_episode%TYPE,
        o_disch_reas_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de motivos de alta. A lista é limitada aos valores possíveis de acordo com a categoria do profissional (médico/Enfermeiro)
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                     I_PROF - ID do profissional
                     I_CAT_TYPE - Tipo de categoria do profissional, tal
                               como é retornada em PK_LOGIN.GET_PROF_PREF
                  Saida:   O_DISCH_REAS_LIST - array de motivos de alta
                     O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/06
          NOTAS: A lista depende da categoria do Profissional (por ex, Médicos só podem
               visualizar motivos de Alta dos tipos M (Médicos) e B (ambos)).
             Tb depende do tipo de instituição do profissional (CS, hospital, etc)
        *********************************************************************************/
    
        l_message      debug_msg;
        l_adm_separate sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_ADMISSION_SEPARATE', i_prof);
        l_epis_type    episode.id_epis_type%TYPE;
        --Configuration that allows to configure the discharge reason per type of episode
        l_id_content_reason sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_REAS_HHC', i_prof);
    BEGIN
    
        l_message := 'INIT get_discharge_reason_list: id_episode = ' || i_id_episode;
    
        l_epis_type := pk_episode.get_epis_type(i_lang, i_id_episode);
    
        IF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            --When accessing a Home health care appointment, only the reason "End of home health care" is displayed
            OPEN o_disch_reas_list FOR
                SELECT DISTINCT dr.id_discharge_reason,
                                pk_translation.get_translation(i_lang, dr.code_discharge_reason) dis_reason,
                                dr.flg_admin_medic,
                                dr.file_to_execute,
                                dr.rank,
                                is_disch_reason_def(i_lang, i_prof, drd.id_discharge_reason) selected_flg
                  FROM discharge_reason dr, disch_reas_dest drd
                 WHERE flg_available = pk_alert_constant.g_yes
                   AND drd.flg_active = pk_alert_constant.g_active
                   AND dr.flg_available = pk_alert_constant.g_yes
                   AND drd.id_discharge_reason = dr.id_discharge_reason
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = i_prof.software
                   AND dr.id_content = l_id_content_reason;
        ELSE
            OPEN o_disch_reas_list FOR
                SELECT DISTINCT dr.id_discharge_reason,
                                pk_translation.get_translation(i_lang, dr.code_discharge_reason) dis_reason,
                                dr.flg_admin_medic,
                                dr.file_to_execute,
                                dr.rank,
                                is_disch_reason_def(i_lang, i_prof, drd.id_discharge_reason) selected_flg
                  FROM discharge_reason dr, disch_reas_dest drd
                 WHERE flg_available = pk_alert_constant.g_yes
                   AND instr(flg_admin_medic, i_cat_type) != 0
                   AND drd.flg_active = pk_alert_constant.g_active
                   AND dr.flg_available = pk_alert_constant.g_yes
                   AND drd.id_discharge_reason = dr.id_discharge_reason
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = i_prof.software
                   AND ((dr.file_to_execute <> pk_discharge.g_disch_screen_disp_admit AND i_flg_type IS NULL AND
                       l_adm_separate = pk_alert_constant.g_yes) OR l_adm_separate = pk_alert_constant.g_no OR
                       (l_adm_separate = pk_alert_constant.g_yes AND i_flg_type = 'A' AND
                       dr.file_to_execute = pk_discharge.g_disch_screen_disp_admit))
                 ORDER BY rank, dis_reason ASC;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_discharge_reason_list',
                                              o_error);
            pk_types.open_my_cursor(o_disch_reas_list);
            RETURN FALSE;
        
    END;

    FUNCTION get_discharge_dest_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_disch_reason IN discharge_reason.id_discharge_reason%TYPE,
        i_prof            IN profissional,
        o_disch_dest_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de destinos de alta.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                I_ID_DISCH_REASON - ID motivo de alta
                  Saida:   O_DISCH_DEST_LIST - array de destinos de alta
                     O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/06
          NOTAS:
        *********************************************************************************/
        CURSOR c_cat IS
            SELECT flg_type
              FROM category cat, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category;
    
        l_type    category.flg_type%TYPE;
        l_message debug_msg;
        --Configuration that allows to configure the discharge reason per type of episode
        l_id_content_reason sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_REAS_HHC', i_prof);
    BEGIN
    
        l_message := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_type;
        CLOSE c_cat;
    
        l_message := 'GET CURSOR';
        OPEN o_disch_dest_list FOR
            SELECT drd.id_disch_reas_dest,
                   decode(nvl(drd.id_discharge_dest, 0),
                          0,
                          decode(nvl(drd.id_dep_clin_serv, 0),
                                 0,
                                 decode(nvl(drd.id_institution, 0),
                                        0,
                                        pk_translation.get_translation(i_lang, dpt.code_department),
                                        pk_translation.get_translation(i_lang, i.code_institution)),
                                 nvl2(drd.id_department,
                                      pk_translation.get_translation(i_lang, dpt.code_department) || ' - ',
                                      '') || pk_translation.get_translation(i_lang, cs.code_clinical_service)),
                          pk_translation.get_translation(i_lang, dd.code_discharge_dest)) desc_discharge_dest,
                   dpt.id_department,
                   dpt.flg_type,
                   decode(l_id_content_reason,
                          dr.id_content,
                          pk_alert_constant.g_epis_type_home_health_care,
                          drd.id_epis_type) id_epis_type,
                   decode(drd.flg_default, pk_alert_constant.g_yes, 'A', 'I') selected_flg,
                   pk_discharge_inst.has_disch_dest_inst(i_lang, i_prof, drd.id_discharge_dest) has_child -- PST 19-02-2010
              FROM disch_reas_dest  drd,
                   discharge_reason dr,
                   discharge_dest   dd,
                   dep_clin_serv    dcs,
                   department       dpt,
                   clinical_service cs,
                   institution      i
             WHERE drd.id_discharge_reason = i_id_disch_reason
               AND drd.id_discharge_reason = dr.id_discharge_reason
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.id_department = dpt.id_department(+) -- CMF 24-02-2007
               AND drd.flg_active = pk_alert_constant.g_active
               AND dd.id_discharge_dest(+) = drd.id_discharge_dest
               AND dd.flg_available(+) = pk_alert_constant.g_yes
               AND dcs.id_dep_clin_serv(+) = drd.id_dep_clin_serv
               AND drd.flg_active != pk_alert_constant.g_inactive -- CMF 2007-04-24 05H55
               AND cs.id_clinical_service(+) = dcs.id_clinical_service
               AND i.id_institution(+) = drd.id_institution
               AND ((instr(dd.flg_type, l_type) != 0 AND dd.id_discharge_dest = drd.id_discharge_dest) OR
                   dd.id_discharge_dest IS NULL OR dr.id_content = l_id_content_reason)
             ORDER BY drd.rank, dd.rank, desc_discharge_dest;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_discharge_dest_list',
                                              o_error);
            pk_types.open_my_cursor(o_disch_dest_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * replaces desc_criteria from table criteria variable fields and returns it's result
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_desc_criteria       function that returns label
    *    
    * @return                      varchar
    *
    * @author                      Paulo Teixeira
    * @version                     2.6.1
    * @since                       2011-05-05
    **********************************************************************************************/
    FUNCTION replace_desc_criteria
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_desc_criteria IN criteria.desc_criteria%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_criteria criteria.desc_criteria%TYPE := i_desc_criteria;
    BEGIN
    
        l_desc_criteria := REPLACE(l_desc_criteria, '@PROFESSIONAL', i_prof.id);
        l_desc_criteria := REPLACE(l_desc_criteria, '@INSTITUTION', i_prof.institution);
        l_desc_criteria := REPLACE(l_desc_criteria, '@SOFTWARE', i_prof.software);
        l_desc_criteria := REPLACE(l_desc_criteria, '@I_LANG', i_lang);
    
        EXECUTE IMMEDIATE 'select ' || l_desc_criteria || ' FROM DUAL'
            INTO l_desc_criteria;
    
        RETURN l_desc_criteria;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN i_desc_criteria;
    END;

    FUNCTION get_pat_search_list
    (
        i_lang               IN language.id_language%TYPE,
        i_id_sys_button      IN search_screen.id_sys_button%TYPE,
        i_prof               IN profissional,
        o_list               OUT pk_types.cursor_type,
        o_list_cs            OUT pk_types.cursor_type,
        o_list_fs            OUT pk_types.cursor_type,
        o_list_payment_state OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de critérios da pesquisa de pacientes.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                     I_ID_SYS_BUTTON - ID do botão seleccionado
                 I_PROF - profissional
                  Saida: O_LIST - array de critérios de pesquisa de pacientes
                 O_LIST_CS - array de tipos de consulta
                 O_LIST_FS - array de valores (1ª / subsequente)
                 O_MESS_NO_RESULT - Mensagem a mostrar no caso de a pesquisa não devolver resultados
                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/18
          ALTERAÇÃO: CRS 2005/11/30 novos cursores de saída p/ listas dos critérios "tipo de consulta" e "1ª / subs."
               CRS 2006/11/08 Substituição das configurações de serv. clínicos associados
                    a exames por DEP_CLIN_SERV_TYPE.FLG_TYPE
                    FO 2008/05/19 Adaptação ao novo modelo de dados e optimização das chamadas a pk_message.get_message
          NOTAS:
        *********************************************************************************/
    
        l_msg_common_m002 VARCHAR2(4000);
        l_msg_common_m059 sys_message.desc_message%TYPE;
        l_message         debug_msg;
        l_inst_mkt        market.id_market%TYPE;
    BEGIN
        l_message := 'GET CURSOR CRITERIA';
    
        SELECT i.id_market
          INTO l_inst_mkt
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        OPEN o_list FOR
            SELECT rank,
                   id_criteria,
                   desc_criteria,
                   flg_type,
                   flg_mandatory,
                   decode(flg_mandatory,
                          pk_alert_constant.g_yes,
                          REPLACE((SELECT pk_message.get_message(i_lang, 'SEARCH_CRITERIA_M002')
                                    FROM dual),
                                  '@1',
                                  desc_criteria),
                          NULL) mess_mandatory,
                   CASE default_value
                       WHEN 'i_prof_id' THEN
                        CAST(i_prof.id AS VARCHAR2(40))
                       WHEN 'i_prof_institution' THEN
                        CAST(i_prof.institution AS VARCHAR2(40))
                       WHEN 'i_prof_software' THEN
                        CAST(i_prof.software AS VARCHAR2(40))
                       WHEN 'i_lang' THEN
                        CAST(i_lang AS VARCHAR2(40))
                       ELSE
                        default_value
                   END default_value
              FROM (SELECT sc.rank,
                           sc.id_criteria,
                           decode(c.desc_criteria,
                                  NULL,
                                  (SELECT pk_translation.get_translation(i_lang, c.code_criteria)
                                     FROM dual),
                                  replace_desc_criteria(i_lang, i_prof, c.desc_criteria)) desc_criteria,
                           c.flg_type,
                           sc.flg_mandatory,
                           sc.default_value
                      FROM search_screen ss
                      JOIN sscr_crit sc
                        ON sc.id_search_screen = ss.id_search_screen
                      JOIN criteria c
                        ON c.id_criteria = sc.id_criteria
                      JOIN criteria_market cm
                        ON cm.id_criteria = c.id_criteria
                       AND cm.id_market IN (l_inst_mkt, pk_alert_constant.g_id_market_all)
                     WHERE ss.id_sys_button = i_id_sys_button
                       AND sc.flg_available = pk_alert_constant.g_yes
                       AND NOT EXISTS (SELECT 1
                              FROM criteria_market cme
                             WHERE cme.flg_add_remove = pk_alert_constant.g_sdm_flag_rem
                               AND cme.id_criteria = c.id_criteria
                               AND cme.id_market = l_inst_mkt)
                     ORDER BY rank);
    
        /*  l_message := 'CALL TO PK_SYSCONFIG.GET_CONFIG';
          IF NOT Pk_Sysconfig.GET_CONFIG('ID_DEPARTMENT_CONSULT', I_PROF, L_DEP) THEN
            O_ERROR := Pk_Message.GET_MESSAGE(I_LANG, 'COMMON_M001') || CHR(10)|| 'PK_LIST.GET_PAT_SEARCH_LIST / ' || l_message;
            RETURN FALSE;
          END IF;
        */
        l_msg_common_m002 := pk_message.get_message(i_lang, 'COMMON_M002');
        l_msg_common_m059 := pk_message.get_message(i_lang, 'COMMON_M059');
    
        IF i_prof.software = 11
        THEN
            -- internamento / inpatient
        
            OPEN o_list_cs FOR
                SELECT dpt.id_department data,
                       1 rank,
                       pk_translation.get_translation(i_lang, dpt.code_department) label
                  FROM department dpt
                 WHERE dpt.id_institution = i_prof.institution
                   AND instr(dpt.flg_type, 'I') > 0
                   AND dpt.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT -1 data, -1 rank, l_msg_common_m002 label
                  FROM dual
                 ORDER BY rank, label;
        
            -- JM 2008/07/24 Search does not currently support CRITERIA.CRIT_MCHOICE_SELECT...
        ELSIF pk_sysconfig.get_config('SOFTWARE_ID_PHISIOTERAPY', i_prof) = i_prof.software
              AND i_id_sys_button IN (6556, 6557)
        THEN
            -- MFR: prioridade do tratamento
            OPEN o_list_cs FOR
                SELECT s.val data, s.desc_val label, s.rank
                  FROM sys_domain s
                 WHERE s.code_domain = 'INTERV_PRESC_DET.FLG_PRTY'
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND s.id_language = i_lang
                UNION ALL
                SELECT '-1' data, l_msg_common_m059 label, -1 rank
                  FROM dual
                 ORDER BY rank ASC;
        
        ELSE
            OPEN o_list_cs FOR
                SELECT dcs.id_dep_clin_serv,
                       c.id_clinical_service data,
                       c.rank,
                       pk_translation.get_translation(i_lang, c.code_clinical_service) label
                  FROM clinical_service c, dep_clin_serv dcs, department dep, software_dept sd --SS 2006/11/28 , DEP_CLIN_SERV_TYPE DCST
                 WHERE dcs.id_clinical_service = c.id_clinical_service
                      --AND DCS.ID_DEPARTMENT = L_DEP
                      --SS 2006/11/28
                      --AND dcst.id_dep_clin_serv = dcs.id_dep_clin_serv
                      --AND dcst.flg_type = g_cons
                      --AND dcst.id_software = i_prof.software
                      --SS 2006/11/28
                   AND dep.id_department = dcs.id_department
                   AND dep.id_institution = i_prof.institution
                   AND instr(dep.flg_type, 'C') > 0 --SS 2006/11/28
                   AND dep.id_department IN (SELECT id_department
                                               FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                                              WHERE pdcs.id_professional = i_prof.id
                                                AND pdcs.flg_status = g_selected
                                                AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv) --SS 2006/11/28
                   AND sd.id_dept = dep.id_dept --SS 2006/11/28
                   AND sd.id_software = i_prof.software --SS 2006/11/28
                   AND dcs.flg_available = pk_alert_constant.g_yes --RL 20080709
                UNION ALL
                SELECT -1 id_dep_clin_serv, -1 data, -1 rank, l_msg_common_m002 label
                  FROM dual
                 ORDER BY rank, label;
        END IF;
    
        l_message := 'GET CURSOR FIRST / SUBSEQUENT';
    
        -- JM 2008/07/24 Search does not currently support CRITERIA.CRIT_MCHOICE_SELECT...
        IF pk_sysconfig.get_config('SOFTWARE_ID_PHISIOTERAPY', i_prof) = i_prof.software
           AND i_id_sys_button IN (6556, 6557)
        THEN
            -- MFR: terapeuta alocado
            OPEN o_list_fs FOR
                SELECT data, label, rank
                  FROM (SELECT p.id_professional data,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                               20 rank
                          FROM professional p, prof_cat pc, category c
                         WHERE p.id_professional = pc.id_professional
                           AND pc.id_institution = i_prof.institution
                           AND c.id_category = pc.id_category
                           AND c.id_category IN (23, 24) -- terapeuta e coordenador
                         ORDER BY p.name ASC)
                UNION ALL
                SELECT -1 data, l_msg_common_m059 label, 10 rank
                  FROM dual
                 ORDER BY rank ASC, label ASC;
        ELSE
            OPEN o_list_fs FOR
                SELECT val data, rank, desc_val label
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_first_subs
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT '-1' data, -1 rank, l_msg_common_m002 label
                  FROM dual
                 ORDER BY rank, label;
        END IF;
    
        pk_backoffice_translation.set_read_translation(g_domain_first_subs, 'SYS_DOMAIN');
    
        -- JM 2008/07/28 Search does not currently support CRITERIA.CRIT_MCHOICE_SELECT...
        IF pk_sysconfig.get_config('SOFTWARE_ID_PHISIOTERAPY', i_prof) = i_prof.software
           AND i_id_sys_button IN (6556, 6557)
        THEN
            -- MFR: autor do pedido de tratamento
            OPEN o_list_payment_state FOR
                SELECT val, desc_val, rank
                  FROM (SELECT p.id_professional val,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) desc_val,
                               20 rank
                          FROM professional p, prof_cat pc, category c
                         WHERE p.id_professional = pc.id_professional
                           AND pc.id_institution = i_prof.institution
                           AND c.id_category = pc.id_category
                           AND c.id_category IN (1, 23, 24) -- medico, terapeuta e coordenador
                         ORDER BY p.name ASC)
                UNION ALL
                SELECT -1 val, l_msg_common_m059 desc_val, 10 rank
                  FROM dual
                 ORDER BY rank ASC, desc_val ASC;
        
        ELSE
            -- lgaspar 2007-fev-08
            l_message := 'GET PAYMENT STATE';
            IF (pk_sysdomain.get_domains_none_option(i_lang,
                                                     g_flg_payment_domain,
                                                     i_prof,
                                                     o_list_payment_state,
                                                     o_error) = FALSE)
            THEN
                RAISE no_data_found;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_pat_search_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_list_cs);
            pk_types.open_my_cursor(o_list_fs);
            RETURN FALSE;
    END get_pat_search_list;

    FUNCTION get_habit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Obter lista de hábitos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_LIST - array de critérios de pesquisa de pacientes
                     O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/19
          NOTAS:
          CHANGES:
                  Filipe Machado 25-Ago-2010: 
                              adapt for institution or market (ALERT-119454) v2.5.1
          
          Dependents: PK_PERIODIC_OBSERVATION.GET_OTHER_PERIODIC_PARAM
          (please do not change o_list cursor, without propagating changes adequately)
        *********************************************************************************/
    
        l_message debug_msg;
        l_count   NUMBER;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM habit hat
         INNER JOIN habit_inst hti
            ON hti.id_habit = hat.id_habit
         WHERE hat.flg_available = pk_alert_constant.g_available
           AND hti.flg_available = pk_alert_constant.g_available
           AND hti.id_institution = i_prof.institution
           AND rownum = 1;
    
        l_message := 'GET CURSOR';
        OPEN o_list FOR
            SELECT id_habit, desc_habit
              FROM (SELECT hat.id_habit, pk_translation.get_translation(i_lang, hat.code_habit) desc_habit, hat.rank
                      FROM habit hat
                     INNER JOIN habit_inst hti
                        ON hti.id_habit = hat.id_habit
                     WHERE hat.flg_available = pk_alert_constant.g_available
                       AND hti.id_institution = decode(l_count, 1, i_prof.institution, pk_alert_constant.g_inst_all)
                       AND hti.flg_available = pk_alert_constant.g_available)
             ORDER BY rank, translate(upper(desc_habit), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑÝ', 'AEIOUAEIOUAEIOUAOCAEIOUNY');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_habit_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_habit_list;

    FUNCTION get_clinical_service_list
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_button IN search_screen.id_sys_button%TYPE,
        i_prof          IN profissional,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos de consulta para a pesquisa
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                     I_ID_SYS_BUTTON - ID do botão seleccionado
                                 I_PROF - profissional
                  Saida: O_LIST - array de tipos de consulta de pesquisa de pacientes
                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/23
          ALTERAÇÃO: CRS 2006/02/09 Novo par. entrada I_PROF
               CRS 2006/11/08 Substituição das configurações de serv. clínicos associados
                    a exames por DEP_CLIN_SERV_TYPE.FLG_TYPE
             SS 2006/11/28 Substituição da DEP_CLIN_SERV_TYPE.FLG_TYPE por DEPARTMENT.FLG_TYPE
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_list FOR
            SELECT ss.id_criteria id_sys_btn_crit,
                   a.id_clinical_service,
                   a.rank,
                   pk_translation.get_translation(i_lang, code_clinical_service) desc_clinical_service
              FROM clinical_service a, search_screen s, sscr_crit ss, dep_clin_serv dcs, department dep -- SS 2006/11/28, DEP_CLIN_SERV_TYPE DCST
             WHERE s.id_sys_button = i_id_sys_button
               AND ss.id_search_screen = s.id_search_screen
                  --AND DCS.ID_DEPARTMENT = Pk_Sysconfig.GET_CONFIG( 'ID_DEPARTMENT_CONSULT', I_PROF)
               AND dcs.id_clinical_service = a.id_clinical_service
               AND dcs.flg_available = g_dcs_available_y
                  --SS 2006/11/28
                  --AND dcst.id_dep_clin_serv = dcs.id_dep_clin_serv
                  --AND dcst.flg_type = g_cons
                  --SS 2006/11/28
               AND instr(dep.flg_type, 'C') > 0 --SS 2006/11/28
               AND dep.id_department = dcs.id_department
               AND dep.id_institution = i_prof.institution
            UNION
            SELECT ss.id_criteria id_sys_btn_crit,
                   -1 id_clinical_service,
                   -1 rank,
                   pk_message.get_message(i_lang, 'COMMON_M014') desc_clinical_service
              FROM search_screen s, sscr_crit ss
             WHERE s.id_sys_button = i_id_sys_button
               AND ss.id_search_screen = s.id_search_screen
             ORDER BY rank, desc_clinical_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_clinical_service_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_clinical_service_list;

    FUNCTION get_exam_time
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_time  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de "tempos" para requisição
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_PROF - profissional que acede
                 I_TYPE - E: exames e análises
                      P: procedimentos, pensos e medicamentos
                  Saida: O_TIME -
                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/28
          NOTAS:
        *********************************************************************************/
        l_flg_time sys_config.value%TYPE;
        l_message  debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
    
        IF i_type = 'E'
        THEN
            l_flg_time := pk_sysconfig.get_config('FLG_TIME_E', i_prof.institution, i_prof.software);
            --análises
            OPEN o_time FOR
                SELECT val,
                       rank,
                       desc_val,
                       decode(l_flg_time, val, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_domain_flg_time, NULL))
                 ORDER BY rank;
        
            pk_backoffice_translation.set_read_translation(g_domain_flg_time, 'SYS_DOMAIN');
        
        ELSE
            l_flg_time := pk_sysconfig.get_config('FLG_TIME_P', i_prof.institution, i_prof.software);
            --procedimentos, pensos e medicamentos
            OPEN o_time FOR
                SELECT val,
                       rank,
                       desc_val,
                       decode(l_flg_time, val, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      i_prof,
                                                                      'INTERV_PRESCRIPTION.FLG_TIME',
                                                                      NULL));
        
            pk_backoffice_translation.set_read_translation(g_domain_flg_time, 'SYS_DOMAIN');
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_exam_time',
                                              o_error);
            pk_types.open_my_cursor(o_time);
            RETURN FALSE;
    END;
    FUNCTION monit_dates_manage
    (
        i_lang              IN language.id_language%TYPE,
        i_flg_time          IN analysis_req.flg_time%TYPE,
        i_flg_tp            IN VARCHAR2,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE DEFAULT NULL,
        o_dt_begin          OUT VARCHAR2,
        o_flg_edit_dt_begin OUT VARCHAR2,
        o_interval          OUT VARCHAR2,
        o_interval_send     OUT VARCHAR2,
        o_flg_edit_interval OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_dt_end_send       OUT VARCHAR2,
        o_dt_begin_send     OUT VARCHAR2,
        o_flg_edit_dt_end   OUT VARCHAR2,
        o_flg_min_date      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_message      VARCHAR2(4000);
        g_error        VARCHAR2(4000); -- Localização dos erros
    BEGIN
        IF i_episode IS NULL
        THEN
            o_flg_min_date := NULL;
        ELSE
            --  MONITORIZAÇÃO E PENSOS   --
            IF NOT pk_episode.get_epis_dt_begin(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_episode,
                                                o_dt_begin   => o_flg_min_date,
                                                o_error      => o_error)
            
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        o_dt_begin := pk_date_utils.date_char_tsz(i_lang, l_sysdate_tstz, i_prof.institution, i_prof.software);
    
        o_dt_begin_send     := pk_date_utils.to_char_insttimezone(i_prof, l_sysdate_tstz, 'yyyymmddhh24miss');
        o_flg_edit_dt_begin := pk_alert_constant.g_yes;
        o_interval          := NULL;
        o_interval_send     := NULL;
        o_flg_edit_interval := pk_alert_constant.g_yes;
        o_dt_end            := NULL;
        o_dt_end_send       := NULL;
        o_flg_edit_dt_end   := pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'Erro',
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_LIST',
                                              i_function => 'MONIT_DATES_MANAGE',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END monit_dates_manage;

    FUNCTION check_param
    (
        i_lang        IN language.id_language%TYPE,
        i_flg_time    IN analysis_req.flg_time%TYPE,
        i_flg_tp      IN VARCHAR2,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        o_param       OUT pk_types.cursor_type,
        o_sysdate_str OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter parametros de datas nas requisição
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   I_FLG_TIME -
                         I_FLG_TP -
                     O_PARAM - Resultado
                     O_ERROR - erro
          CRIAÇÃO: SS/AA 2005/10/31
          NOTAS:
        *********************************************************************************/
        l_dt_begin            VARCHAR2(30);
        l_dt_end              VARCHAR2(30);
        l_interval            VARCHAR2(30);
        l_flg_edit_dt_begin   VARCHAR2(1);
        l_flg_edit_dt_end     VARCHAR2(1);
        l_flg_edit_interval   VARCHAR2(1);
        l_flg_edit_realizacao VARCHAR2(1);
        l_min_date            VARCHAR2(30) := '';
        l_cat                 category.flg_type%TYPE;
        l_outp                VARCHAR2(200);
        l_care                VARCHAR2(200);
        l_clin                VARCHAR2(200);
        --Sílvia Freitas 21-11-2007
        l_dt_begin_send VARCHAR2(30);
        l_dt_end_send   VARCHAR2(30);
        l_interval_send VARCHAR2(30);
    
        CURSOR c_cat IS
            SELECT c.flg_type
              FROM prof_cat pc, category c
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND c.id_category = pc.id_category;
    
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_message debug_msg;
        l_exception EXCEPTION;
    BEGIN
        l_message := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        l_outp := pk_sysconfig.get_config('SOFTWARE_ID_OUTP', i_prof);
        l_care := pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
        l_clin := pk_sysconfig.get_config('SOFTWARE_ID_CLINICS', i_prof);
    
        IF i_prof.software IN (l_outp, l_care, l_clin)
        THEN
            IF l_cat IN (g_cat_type_physio, g_cat_type_tech)
              --OR
              --I_PROF.SOFTWARE = L_CARE AND I_FLG_TP = 'E') THEN */ -- CRS 2006/08/16 Os CS ñ podem seleccionar realização
               OR (pk_sysconfig.get_config('EXAM_RESULT', i_prof.institution, i_prof.software) = pk_alert_constant.g_no AND
               i_flg_tp = 'E')
            THEN
                l_flg_edit_realizacao := pk_alert_constant.g_no;
            ELSE
                l_flg_edit_realizacao := pk_alert_constant.g_yes;
            END IF;
        
            IF i_flg_time = pk_alert_constant.g_flg_time_b
            THEN
                IF i_flg_tp = 'M'
                THEN
                    IF NOT monit_dates_manage(i_lang              => i_lang,
                                              i_flg_time          => i_flg_time,
                                              i_flg_tp            => i_flg_tp,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              o_dt_begin          => l_dt_begin,
                                              o_flg_edit_dt_begin => l_flg_edit_dt_begin,
                                              o_interval          => l_interval,
                                              o_interval_send     => l_interval_send,
                                              o_flg_edit_interval => l_flg_edit_interval,
                                              o_dt_end            => l_dt_end,
                                              o_dt_end_send       => l_dt_end_send,
                                              o_dt_begin_send     => l_dt_begin_send,
                                              o_flg_edit_dt_end   => l_flg_edit_dt_end,
                                              o_flg_min_date      => l_min_date,
                                              o_error             => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                ELSIF i_flg_tp = 'E'
                THEN
                    --  IMAGENS, ANÁLISES E OUTROS EXAMES --
                    l_dt_begin          := pk_message.get_message(i_lang, 'COMMON_M018');
                    l_dt_begin_send     := NULL;
                    l_flg_edit_dt_begin := pk_alert_constant.g_no;
                    l_interval          := pk_message.get_message(i_lang, 'COMMON_M018');
                    l_interval_send     := NULL;
                    l_flg_edit_interval := pk_alert_constant.g_no;
                    l_dt_end            := l_dt_begin;
                    l_dt_end_send       := NULL;
                    l_flg_edit_dt_end   := pk_alert_constant.g_no;
                END IF;
            ELSIF i_flg_time IN (pk_alert_constant.g_flg_time_n, pk_alert_constant.g_flg_time_r)
            THEN
                l_dt_begin          := pk_message.get_message(i_lang, 'COMMON_M018');
                l_dt_begin_send     := NULL;
                l_flg_edit_dt_begin := pk_alert_constant.g_no;
                l_interval          := pk_message.get_message(i_lang, 'COMMON_M018');
                l_interval_send     := NULL;
                l_flg_edit_interval := pk_alert_constant.g_no;
                l_dt_end            := l_dt_begin;
                l_dt_end_send       := NULL;
                l_flg_edit_dt_end   := pk_alert_constant.g_no;
            ELSE
                IF i_flg_tp = 'M'
                THEN
                    IF NOT monit_dates_manage(i_lang              => i_lang,
                                              i_flg_time          => i_flg_time,
                                              i_flg_tp            => i_flg_tp,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              o_dt_begin          => l_dt_begin,
                                              o_flg_edit_dt_begin => l_flg_edit_dt_begin,
                                              o_interval          => l_interval,
                                              o_interval_send     => l_interval_send,
                                              o_flg_edit_interval => l_flg_edit_interval,
                                              o_dt_end            => l_dt_end,
                                              o_dt_end_send       => l_dt_end_send,
                                              o_dt_begin_send     => l_dt_begin_send,
                                              o_flg_edit_dt_end   => l_flg_edit_dt_end,
                                              o_flg_min_date      => l_min_date,
                                              o_error             => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                ELSE
                    --  I_FLG_TIME = PK_ALERT_CONSTANT.G_FLG_TIME_E
                    l_dt_begin          := pk_date_utils.date_char_tsz(i_lang,
                                                                       l_sysdate_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software);
                    l_dt_begin_send     := pk_date_utils.to_char_insttimezone(i_prof,
                                                                              l_sysdate_tstz,
                                                                              'yyyymmddhh24miss');
                    l_flg_edit_dt_begin := pk_alert_constant.g_yes;
                    l_interval          := NULL;
                    l_interval_send     := NULL;
                    l_flg_edit_interval := pk_alert_constant.g_yes;
                    l_dt_end            := NULL;
                    l_dt_end_send       := NULL;
                    l_flg_edit_dt_end   := pk_alert_constant.g_yes;
                END IF;
            END IF;
        ELSE
            IF pk_sysconfig.get_config('EXAM_RESULT', i_prof.institution, i_prof.software) = pk_alert_constant.g_yes
               AND i_flg_tp = 'E'
            THEN
                l_flg_edit_realizacao := pk_alert_constant.g_yes;
            ELSE
                l_flg_edit_realizacao := pk_alert_constant.g_no;
            END IF;
            IF i_flg_tp = 'M'
            THEN
                --  MONITORIZAÇÃO E PENSOS   --
                IF NOT monit_dates_manage(i_lang              => i_lang,
                                          i_flg_time          => i_flg_time,
                                          i_flg_tp            => i_flg_tp,
                                          i_prof              => i_prof,
                                          i_episode           => i_episode,
                                          o_dt_begin          => l_dt_begin,
                                          o_flg_edit_dt_begin => l_flg_edit_dt_begin,
                                          o_interval          => l_interval,
                                          o_interval_send     => l_interval_send,
                                          o_flg_edit_interval => l_flg_edit_interval,
                                          o_dt_end            => l_dt_end,
                                          o_dt_end_send       => l_dt_end_send,
                                          o_dt_begin_send     => l_dt_begin_send,
                                          o_flg_edit_dt_end   => l_flg_edit_dt_end,
                                          o_flg_min_date      => l_min_date,
                                          o_error             => o_error)
                
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSE
            
                l_dt_begin          := pk_date_utils.date_char_tsz(i_lang,
                                                                   l_sysdate_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software);
                l_dt_begin_send     := pk_date_utils.to_char_insttimezone(i_prof, l_sysdate_tstz, 'yyyymmddhh24miss');
                l_flg_edit_dt_begin := pk_alert_constant.g_yes;
                l_interval          := NULL;
                l_interval_send     := NULL;
                l_flg_edit_interval := pk_alert_constant.g_yes;
                l_dt_end            := NULL;
                l_dt_end_send       := NULL;
                l_flg_edit_dt_end   := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        l_message := 'GET CURSOR';
        OPEN o_param FOR
            SELECT l_dt_begin            dt_begin,
                   l_dt_begin_send       dt_begin_send,
                   l_flg_edit_dt_begin   flg_edit_dt_begin,
                   l_dt_end              dt_end,
                   l_dt_end_send         dt_end_send,
                   l_flg_edit_dt_end     flg_edit_dt_end,
                   l_interval            INTERVAL,
                   l_interval_send       interval_send,
                   l_flg_edit_interval   flg_edit_interval,
                   l_flg_edit_realizacao flg_edit_realizacao,
                   l_min_date            dt_min_date
              FROM dual;
    
        o_sysdate_str := pk_date_utils.get_timestamp_str(i_lang, i_prof, l_sysdate_tstz, NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_PARAM',
                                              o_error);
            pk_types.open_my_cursor(o_param);
            RETURN FALSE;
    END;

    FUNCTION check_presc_param
    (
        i_lang            IN language.id_language%TYPE,
        i_time            IN drug_prescription.flg_time%TYPE,
        i_type            IN drug_presc_det.flg_take_type%TYPE,
        i_take            IN drug_presc_det.takes%TYPE,
        i_interval        IN VARCHAR2,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_flg_type        IN VARCHAR2,
        i_prof            IN profissional,
        o_sysdate         OUT VARCHAR2,
        o_type            OUT drug_presc_det.flg_take_type%TYPE,
        o_take            OUT VARCHAR2,
        o_interval        OUT VARCHAR2,
        o_dt_begin        OUT VARCHAR2,
        o_dt_end          OUT VARCHAR2,
        o_hr_begin        OUT VARCHAR2,
        o_hr_end          OUT VARCHAR2,
        o_type_edit       OUT VARCHAR2,
        o_take_edit       OUT VARCHAR2,
        o_interval_edit   OUT VARCHAR2,
        o_dt_begin_edit   OUT VARCHAR2,
        o_dt_end_edit     OUT VARCHAR2,
        o_type_param      OUT drug_presc_det.flg_take_type%TYPE,
        o_take_param      OUT drug_presc_det.takes%TYPE,
        o_interval_param  OUT VARCHAR2,
        o_dt_begin_param  OUT VARCHAR2,
        o_dt_end_param    OUT VARCHAR2,
        o_realizacao_edit OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Verificar e retornar os valores para tomas, intervalo, data início, ...  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_TYPE - tipo 
                     I_TAKE - tomas 
                     I_INTERVAL - intervalo 
                     I_DT_BEGIN - data início
                                             I_FLG_TYPE - tipo: I - procedimentos, D - medicamentos 
                  Saida:   O_TYPE - tipo 
                     O_TAKE - tomas 
                     O_INTERVAL - intervalo 
                     O_DT_BEGIN - data início 
                     O_DT_END - data fim 
                     O_TYPE_EDIT - campo tipo é editável 
                     O_TAKE_EDIT - campo tomas é editável 
                     O_INTERVAL_EDIT - campo intervalo é editável 
                     O_DT_BEGIN_EDIT - campo data início é editável 
                     O_DT_END_EDIT - campo data fim é editável 
                     O_TYPE_PARAM - valor do tipo  
                     O_TAKE_PARAM - valor das tomas  
                     O_INTERVAL_PARAM - valor do intervalo  
                     O_DT_BEGIN_PARAM - valor da data início  
                     O_DT_END_PARAM - valor da data fim  
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/08/05  
          NOTAS: 
        *********************************************************************************/
        l_interval      drug_presc_det.interval%TYPE;
        l_cat           category.flg_type%TYPE;
        i_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        i_dt_end_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_cat IS
            SELECT c.flg_type
              FROM prof_cat pc, category c
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND c.id_category = pc.id_category;
    
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_message debug_msg;
    
    BEGIN
    
        i_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        i_dt_end_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
        --
        l_message  := 'INITIALIZE(1)';
        o_take     := i_take;
        o_interval := i_interval;
    
        o_dt_begin := pk_date_utils.dt_chr_tsz(i_lang,
                                               nvl(i_dt_begin_tstz, l_sysdate_tstz),
                                               i_prof.institution,
                                               i_prof.software); --
        o_dt_end   := pk_date_utils.dt_chr_tsz(i_lang,
                                               nvl(i_dt_begin_tstz, l_sysdate_tstz),
                                               i_prof.institution,
                                               i_prof.software); --
    
        o_hr_begin := pk_date_utils.date_char_hour_tsz(i_lang,
                                                       nvl(i_dt_begin_tstz, l_sysdate_tstz),
                                                       i_prof.institution,
                                                       i_prof.software);
        o_hr_end   := pk_date_utils.date_char_hour_tsz(i_lang,
                                                       nvl(i_dt_begin_tstz, l_sysdate_tstz),
                                                       i_prof.institution,
                                                       i_prof.software);
    
        -- JM 2008/12/23 Changed from DRUG_PRESC_DET.FLG_TAKE_TYPE (ALERT-12193)
        o_type := pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_INTERV_TYPE', i_type, i_lang);
    
        l_message        := 'INITIALIZE(2)';
        o_type_param     := i_type;
        o_dt_begin_param := pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_begin_tstz, l_sysdate_tstz), i_prof);
        o_dt_end_param   := pk_date_utils.date_send_tsz(i_lang, nvl(i_dt_begin_tstz, l_sysdate_tstz), i_prof);
        o_take_param     := i_take;
        o_interval_param := i_interval;
    
        l_message       := 'INITIALIZE(3)';
        o_type_edit     := pk_alert_constant.g_yes;
        o_take_edit     := pk_alert_constant.g_yes;
        o_interval_edit := pk_alert_constant.g_yes;
        o_dt_begin_edit := pk_alert_constant.g_yes;
        o_dt_end_edit   := pk_alert_constant.g_no;
    
        IF nvl(i_type, '@') != '@'
        THEN
            -- I_TYPE preenchido 
            l_message := 'I_TYPE NOT NULL';
            IF i_type = 'U'
            THEN
                -- unitário 
                l_message        := 'I_TYPE U';
                o_take           := '1';
                o_interval       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_take_edit      := pk_alert_constant.g_no;
                o_interval_edit  := pk_alert_constant.g_no;
                o_take_param     := 1;
                o_interval_param := NULL;
            
            ELSIF i_type = 'X'
            THEN
                -- <nenhum> 
                l_message        := 'I_TYPE X';
                o_take           := NULL;
                o_interval       := NULL;
                o_type           := NULL;
                o_take_param     := NULL;
                o_interval_param := NULL;
                o_type_param     := NULL;
            
            ELSIF i_type = 'A'
            THEN
                -- ad eternum 
                l_message      := 'I_TYPE A';
                o_take         := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_dt_end       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_hr_end       := NULL;
                o_take_edit    := pk_alert_constant.g_no;
                o_take_param   := 999;
                o_dt_end_param := NULL;
            
            ELSIF i_type = 'C'
            THEN
                -- contínuo   
                l_message       := 'I_TYPE C';
                o_take          := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_interval      := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_take_edit     := pk_alert_constant.g_no;
                o_interval_edit := pk_alert_constant.g_no;
                o_dt_end        := NULL;
                o_hr_end        := NULL;
            
                IF i_dt_end_tstz != i_dt_begin_tstz
                THEN
                    o_dt_end := pk_date_utils.dt_chr_tsz(i_lang, i_dt_end_tstz, i_prof.institution, i_prof.software);
                    o_hr_end := pk_date_utils.date_char_hour(i_lang, i_dt_end_tstz, i_prof.institution, i_prof.software);
                END IF;
                --
                o_dt_end_edit    := pk_alert_constant.g_yes;
                o_take_param     := 0;
                o_interval_param := NULL;
                o_dt_end_param   := i_dt_end;
            
            ELSIF i_type = 'N'
            THEN
                -- normal 
                l_message := 'I_TYPE N';
                IF i_take = 1
                THEN
                    -- normal c/ tomas = 1 
                    -- passagem de normal p/ unitário 
                    l_message    := 'I_TAKE 1';
                    o_type       := pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_INTERV_TYPE', 'U', i_lang);
                    o_type_param := 'U';
                    o_interval   := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                    --        END IF;
                    o_take_edit      := pk_alert_constant.g_no;
                    o_interval_edit  := pk_alert_constant.g_no;
                    o_take_param     := 1;
                    o_interval_param := NULL;
                
                    o_dt_end_param := NULL;
                    o_dt_end       := NULL;
                    o_hr_end       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                
                ELSIF i_take = 0
                THEN
                    -- normal c/ tomas = 0 
                    l_message := 'I_TAKE 0';
                    IF nvl(i_interval, '@') != '@'
                    THEN
                        -- com intervalo preenchido 
                        l_message        := 'I_INTERVAL (3)';
                        o_interval       := NULL;
                        o_take           := NULL;
                        o_take_param     := o_take;
                        o_interval_param := o_interval;
                    
                    ELSE
                        IF i_flg_type = 'I'
                        THEN
                            -- procedimentos 
                            o_take       := NULL;
                            o_take_param := o_take;
                        
                        ELSE
                            -- passagem de normal p/ contínuo (medicamentos)  
                            l_message        := 'I_INTERVAL (4)';
                            o_type_param     := 'C';
                            o_type           := pk_sysdomain.get_domain('DRUG_PRESC_DET.FLG_TAKE_TYPE', 'C', i_lang);
                            o_take           := '0';
                            o_interval       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                            o_take_edit      := pk_alert_constant.g_no;
                            o_interval_edit  := pk_alert_constant.g_no;
                            o_take_param     := 0;
                            o_interval_param := NULL;
                            o_dt_end_param   := i_dt_end;
                        END IF;
                    END IF;
                
                ELSE
                    -- tomas > 1 
                
                    IF instr(i_interval, ':') != 0
                    THEN
                        l_interval := to_number(to_char(to_date(i_interval, 'HH24:MI'), 'SSSSS'));
                    ELSE
                        l_interval := to_number(nvl(i_interval, 0)) * 86400;
                    END IF;
                
                    IF instr(i_interval, ':') != 0
                    THEN
                        o_dt_end       := pk_date_utils.dt_chr_tsz(i_lang,
                                                                   nvl(i_dt_begin_tstz, l_sysdate_tstz) +
                                                                   (i_take - 1) * (l_interval / 86400),
                                                                   i_prof.institution,
                                                                   i_prof.software);
                        o_hr_end       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                           nvl(i_dt_begin_tstz, l_sysdate_tstz) +
                                                                           (i_take - 1) * (l_interval / 86400),
                                                                           i_prof.institution,
                                                                           i_prof.software);
                        o_dt_end_param := pk_date_utils.date_send_tsz(i_lang,
                                                                      nvl(i_dt_begin_tstz, l_sysdate_tstz) +
                                                                      (i_take - 1) * (l_interval / 86400),
                                                                      i_prof);
                    
                    ELSIF nvl(i_interval, '@') != '@'
                    THEN
                        -- intervalo preenchido 
                        o_dt_end       := pk_date_utils.dt_chr_tsz(i_lang,
                                                                   nvl(i_dt_begin_tstz, l_sysdate_tstz) +
                                                                   (i_take - 1) * to_number(trunc(l_interval / 86400)),
                                                                   i_prof.institution,
                                                                   i_prof.software);
                        o_hr_end       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                           nvl(i_dt_begin_tstz, l_sysdate_tstz) +
                                                                           (i_take - 1) *
                                                                           to_number(trunc(l_interval / 86400)),
                                                                           i_prof.institution,
                                                                           i_prof.software);
                        o_dt_end_param := pk_date_utils.date_send_tsz(i_lang,
                                                                      nvl(i_dt_begin_tstz, l_sysdate_tstz) +
                                                                      (i_take - 1) *
                                                                      to_number(trunc(l_interval / 86400)),
                                                                      i_prof);
                    ELSIF i_interval IS NULL
                          AND
                          pk_sysconfig.get_config('PROCEDURES_INTERVAL_MANDATORY', i_prof) = pk_alert_constant.get_no
                    THEN
                        o_dt_end_param := NULL;
                        o_dt_end       := NULL;
                        o_hr_end       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                    END IF;
                
                END IF;
            
            ELSIF i_type = 'S'
            THEN
                l_message        := 'I_TYPE S';
                o_take           := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_interval       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_take_edit      := pk_alert_constant.g_no;
                o_interval_edit  := pk_alert_constant.g_no;
                o_dt_begin       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_hr_begin       := NULL;
                o_dt_end         := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
                o_hr_end         := NULL;
                o_dt_begin_edit  := pk_alert_constant.g_no;
                o_dt_begin_param := NULL;
                o_dt_end_param   := NULL;
                o_take_param     := NULL;
                o_interval_param := NULL;
            END IF;
        
        ELSE
            l_message        := 'I_TYPE NULL';
            o_take           := NULL;
            o_interval       := NULL;
            o_take_edit      := NULL;
            o_interval_edit  := NULL;
            o_take_param     := NULL;
            o_interval_param := NULL;
        END IF;
    
        l_message := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        l_message := 'GET SOFTWARE ID';
        IF i_prof.software IN (pk_sysconfig.get_config('SOFTWARE_ID_OUTP', i_prof),
                               pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof),
                               pk_sysconfig.get_config('SOFTWARE_ID_CLINICS', i_prof))
        THEN
            IF l_cat IN (g_cat_type_physio, g_cat_type_tech)
            THEN
                o_realizacao_edit := pk_alert_constant.g_no;
            ELSE
                o_realizacao_edit := pk_alert_constant.g_yes;
            END IF;
        ELSE
            o_realizacao_edit := pk_alert_constant.g_no;
        END IF;
    
        IF i_time = pk_alert_constant.g_flg_time_n
        THEN
            o_dt_begin       := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
            o_hr_begin       := NULL;
            o_dt_begin_param := NULL;
            o_dt_end         := pk_message.get_message(i_lang, 'PRESCRIPTION_M001');
            o_hr_end         := NULL;
            o_dt_end_param   := NULL;
            o_dt_begin_edit  := pk_alert_constant.g_no;
            o_dt_end_edit    := pk_alert_constant.g_no;
            IF i_type IN ('DRUG_PRESCRIPTION.FLG_TIME', 'U', 'C', 'S')
            THEN
                o_interval_edit := pk_alert_constant.g_no;
            ELSE
                o_interval_edit := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        o_sysdate := pk_date_utils.date_send_tsz(i_lang, l_sysdate_tstz, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'check_param',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_blood_type
    (
        i_lang  IN language.id_language%TYPE,
        o_blood OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de tipos sanguíneos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_BLOOD - tipos sanguíneos
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/07/06
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_domain_blood, i_lang, o_blood);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_blood_type',
                                              o_error);
            pk_types.open_my_cursor(o_blood);
            RETURN FALSE;
    END;

    FUNCTION get_blood_rhesus
    (
        i_lang  IN language.id_language%TYPE,
        o_blood OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de factores RH
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_BLOOD - factores RH
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/07/07
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_domain_rhesus, i_lang, o_blood);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_blood_rhesus',
                                              o_error);
            pk_types.open_my_cursor(o_blood);
            RETURN FALSE;
    END;

    FUNCTION get_print_type
    (
        i_lang       IN language.id_language%TYPE,
        i_barcode    IN VARCHAR2,
        i_image      IN VARCHAR2,
        i_other_exam IN VARCHAR2,
        i_analysis   IN VARCHAR2,
        i_prof       IN profissional,
        o_print      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de escolhas de impressão
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_PRINT - lista de escolhas de impressão
                     O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/07/21
          NOTAS:
        *********************************************************************************/
    
        CURSOR c_cat IS
            SELECT c.flg_type
              FROM prof_cat pc, category c
             WHERE id_professional = i_prof.id
               AND c.id_category = pc.id_category;
    
        l_cat     category.flg_type%TYPE;
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        IF i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_ORIS', i_prof)
        THEN
            l_message := 'GET CURSOR';
            OPEN o_print FOR
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_oris
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_barcode
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_barcode = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_analysis
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_analysis = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_image
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_image = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_other
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_other_exam = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                 ORDER BY rank, label;
        
            pk_backoffice_translation.set_read_translation(g_domain_oris, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_barcode, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_analysis, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_image, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_other, 'SYS_DOMAIN');
        
        ELSIF i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof)
        THEN
            l_message := 'GET CURSOR';
            OPEN o_print FOR
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_inp
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_barcode
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_barcode = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_analysis
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_analysis = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_image
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_image = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_other
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_other_exam = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                 ORDER BY rank, label;
        
            pk_backoffice_translation.set_read_translation(g_domain_inp, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_barcode, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_analysis, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_image, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_other, 'SYS_DOMAIN');
        
        ELSIF i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof)
        THEN
            l_message := 'GET CURSOR';
            OPEN o_print FOR
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_edis
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                --SELECT val data, desc_val label, rank
                --  FROM sys_domain
                -- WHERE id_language = i_lang
                --   AND code_domain = g_domain_print
                --   AND flg_available = pk_alert_constant.g_yes
                --UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_barcode
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_barcode = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_analysis
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_analysis = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_image
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_image = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_print_other
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND i_other_exam = pk_alert_constant.g_yes
                   AND flg_available = pk_alert_constant.g_yes
                 ORDER BY rank, label;
        
            pk_backoffice_translation.set_read_translation(g_domain_edis, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_barcode, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_analysis, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_image, 'SYS_DOMAIN');
            pk_backoffice_translation.set_read_translation(g_domain_print_other, 'SYS_DOMAIN');
        
        ELSIF i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_P1', i_prof)
        THEN
            l_message := 'GET CURSOR';
            OPEN o_print FOR
                SELECT val data, desc_val label, rank
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_domain_p1
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND flg_available = pk_alert_constant.g_yes
                 ORDER BY rank, label;
        
            pk_backoffice_translation.set_read_translation(g_domain_p1, 'SYS_DOMAIN');
        
        ELSE
            IF l_cat = 'S'
            THEN
                --assistente social
                l_message := 'GET CURSOR';
                OPEN o_print FOR
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_social
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = pk_alert_constant.g_yes
                     ORDER BY rank, label;
            
                pk_backoffice_translation.set_read_translation(g_domain_print_social, 'SYS_DOMAIN');
            
            ELSIF l_cat = 'D'
            THEN
                --médico
                l_message := 'GET CURSOR';
                OPEN o_print FOR
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_barcode
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_barcode = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_analysis
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_analysis = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_image
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_image = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_other
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_other_exam = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                     ORDER BY rank, label;
            
                pk_backoffice_translation.set_read_translation(g_domain_print, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_barcode, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_analysis, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_image, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_other, 'SYS_DOMAIN');
            
            ELSE
                l_message := 'GET CURSOR';
                OPEN o_print FOR
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND val != 'M' --nos perfis q não são médicos, não aparece o relatório "Recomendações ao doente"
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_barcode
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_barcode = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_analysis
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_analysis = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_image
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_image = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT val data, desc_val label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_print_other
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_other_exam = pk_alert_constant.g_yes
                       AND flg_available = pk_alert_constant.g_yes
                     ORDER BY rank, label;
            
                pk_backoffice_translation.set_read_translation(g_domain_print, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_barcode, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_analysis, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_image, 'SYS_DOMAIN');
                pk_backoffice_translation.set_read_translation(g_domain_print_other, 'SYS_DOMAIN');
            
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_print_type',
                                              o_error);
            pk_types.open_my_cursor(o_print);
            RETURN FALSE;
    END;

    FUNCTION get_sample_text_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de áreas de textos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_LIST - lista
                     O_ERROR - erro
        
          CRIAÇÃO: SS 2005/08/26
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_list FOR
            SELECT stt.id_sample_text_type, pk_translation.get_translation(i_lang, stt.code_sample_text_type) area
              FROM sample_text_type stt
             WHERE stt.id_software = i_prof.software
               AND stt.flg_available = pk_alert_constant.g_yes
               AND EXISTS
             (SELECT 1
                      FROM sample_text_type_cat sttc
                     WHERE sttc.id_sample_text_type = stt.id_sample_text_type
                       AND sttc.id_category = (SELECT id_category
                                                 FROM prof_cat
                                                WHERE id_professional = i_prof.id
                                                  AND id_institution IN (0, i_prof.institution))
                       AND sttc.id_institution IN (0, i_prof.institution))
             ORDER BY area;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_sample_text_type_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /**
    * Gets all geographic locations belonging to a country.
    * If I_ID_COUNTRY=NULL returns locations associated to the DEFAULT_COUNTRY Sys_Domain
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_COUNTRY country id, optional.
    * @param   O_GEO_LOCATIONS list of options
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   04-09-2006
    */

    FUNCTION get_geo_location
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_country    IN country.id_country%TYPE,
        o_geo_locations OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_country country.id_country%TYPE;
        l_value      sys_config.value%TYPE;
    
        l_exception EXCEPTION;
        l_message debug_msg;
    
    BEGIN
        l_id_country := i_id_country;
        IF (l_id_country IS NULL)
        THEN
            l_message := 'GET_COUNTRY_ID';
        
            IF NOT pk_sysconfig.get_config(g_sys_config_default_country, i_prof, l_value)
            THEN
                RAISE l_exception;
            END IF;
        
            dbms_output.put_line('L_VALUE = ' || l_value);
        
            IF (l_value IS NOT NULL)
            THEN
                l_id_country := to_number(l_value);
            ELSE
                l_message := 'NO COUNTRY DEFINED';
                RAISE l_exception;
            END IF;
        
        END IF;
    
        l_message := 'GET CURSOR';
        OPEN o_geo_locations FOR
            SELECT id_geo_location, pk_translation.get_translation(i_lang, code_geo_location) geo_location
              FROM geo_location
             WHERE flg_available = pk_alert_constant.g_yes
               AND id_country = l_id_country
             ORDER BY geo_location;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_geo_location',
                                              o_error);
            pk_types.open_my_cursor(o_geo_locations);
            RETURN FALSE;
    END;

    /**
    * Gets admin options to the plus button
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_LIST list of options
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   01-09-2006
    */
    FUNCTION get_admin_plus_button_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_message debug_msg;
    
    BEGIN
        -- get sys domains
        l_message := 'GET_VALUES_DOMAIN';
        IF NOT pk_sysdomain.get_values_domain(g_domain_admin_creates, i_lang, o_list)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_admin_plus_button_list',
                                              o_error);
            RETURN FALSE;
        
    END get_admin_plus_button_list;

    FUNCTION get_schedule_exam_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_schedule   IN schedule.id_schedule%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_exam_state IN VARCHAR2,
        i_flg_type   IN VARCHAR2,
        o_domains    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_is_contact VARCHAR2(1 CHAR);
        l_id_patient patient.id_patient%TYPE;
    
        l_epis_type                 epis_type.id_epis_type%TYPE;
        l_registration_availability VARCHAR2(1 CHAR);
    
        l_message debug_msg;
    
    BEGIN
    
        BEGIN
            SELECT sg.id_patient
              INTO l_id_patient
              FROM sch_group sg
             WHERE sg.id_schedule = i_schedule;
        
            l_is_contact := pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_patient := -1;
        END;
    
        IF i_flg_type = 'A'
        THEN
            l_epis_type := pk_lab_tests_constant.g_episode_type_lab;
        ELSIF i_flg_type = 'EI'
        THEN
            l_epis_type := pk_exam_constant.g_episode_type_rad;
        ELSIF i_flg_type = 'EO'
        THEN
            l_epis_type := pk_exam_constant.g_episode_type_exm;
        ELSE
            l_epis_type := pk_procedures_constant.g_episode_type_interv;
        END IF;
    
        BEGIN
            SELECT t.field_01
              INTO l_registration_availability
              FROM TABLE(pk_core_config.tf_config(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_config_table => 'EPIS_REGISTRATION_AVAILABILITY')) t
             WHERE t.id_record = l_epis_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_registration_availability := pk_alert_constant.g_yes;
        END;
    
        l_message := 'OPEN CURSOR';
        OPEN o_domains FOR
            SELECT val,
                   desc_val,
                   rank,
                   img_name,
                   decode(i_flg_type,
                          'I',
                          decode(i_exam_state,
                                 'D',
                                 decode(i_episode,
                                        NULL,
                                        decode(val,
                                               pk_exam_constant.g_exam_efectiv,
                                               decode(l_is_contact,
                                                      pk_alert_constant.g_yes,
                                                      pk_alert_constant.g_no,
                                                      l_registration_availability),
                                               pk_exam_constant.g_exam_nr,
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no),
                                        pk_alert_constant.g_no),
                                 pk_alert_constant.g_no),
                          decode(i_exam_state,
                                 pk_exam_constant.g_exam_sched,
                                 decode(val,
                                        pk_exam_constant.g_exam_efectiv,
                                        decode(l_is_contact,
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no,
                                               l_registration_availability),
                                        pk_exam_constant.g_exam_nr,
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_no),
                                 pk_alert_constant.g_no)) flg_action
              FROM sys_domain
             WHERE code_domain = g_domain_schedule_exam
               AND id_language = i_lang
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = pk_alert_constant.g_yes
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCHEDULE_EXAM_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_schedule_exam_list;

    FUNCTION get_nationality_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de nacionalidades
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  Saida:   O_COUNTRY - países
                     O_ERROR - erro
        
          CRIAÇÃO: LG 2007/01/11
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_country FOR
            SELECT id_country,
                   1 rank,
                   pk_translation.get_translation(i_lang, code_nationality) nationality,
                   decode(pk_sysconfig.get_config('ID_COUNTRY', i_prof.institution, i_prof.software),
                          id_country,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_default
              FROM country
             WHERE flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_country,
                   -1 rank,
                   pk_message.get_message(i_lang, 'COMMON_M002') nationality,
                   pk_alert_constant.g_no flg_default
              FROM dual
             ORDER BY rank, nationality;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_nationality_list',
                                              o_error);
            pk_types.open_my_cursor(o_country);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter lista dos tipos de história de um paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               Qual o tipo de história: HMC - História médica / cirurgica
                                                               HFS - História familiar / social                  
    * @param o_pat_htype              Lista dos tipos de história do paciente 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/12
    **********************************************************************************************/
    FUNCTION get_pat_history_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN pat_history_type.acronym%TYPE,
        o_pat_htype OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_pat_htype';
        OPEN o_pat_htype FOR
            SELECT id_pat_history_type,
                   pk_translation.get_translation(i_lang, code_pat_history_type) desc_pat_hist_type,
                   flg_type
              FROM pat_history_type
             WHERE acronym = i_flg_type
             ORDER BY 1 ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_pat_history_type',
                                              o_error);
            pk_types.open_my_cursor(o_pat_htype);
            RETURN FALSE;
    END;

    /**
    * Gets district list.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_district the cursur with the districts info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   06-fev-2007
    */
    FUNCTION get_district_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_district OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        RETURN pk_list.get_state_district_list(i_lang, i_prof, NULL, o_district, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_district_list',
                                              o_error);
        
            pk_types.open_my_cursor(o_district);
            RETURN FALSE;
    END get_district_list;

    /**
    * Gets districts for a state.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof object with user data
    * @param   i_geo_state object with user data
    * @param   o_district the cursur with the districts info
    * @param   o_error an error message, set when return=false
    *
    * @return  true if sucess, false otherwise
    * @author  João Eiras
    * @version 1.0
    * @since   2008-05-15
    */
    FUNCTION get_state_district_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_geo_state IN geo_state.id_geo_state%TYPE,
        o_district  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_default_country sys_config.value%TYPE;
        l_message         debug_msg;
    
    BEGIN
        IF i_geo_state IS NULL
        THEN
            l_message         := 'GET DEFAULT COUNTRY';
            l_default_country := pk_sysconfig.get_config('ID_COUNTRY', i_prof.institution, i_prof.software);
            l_message         := 'OPEN O_DISTRICT NO STATE';
            OPEN o_district FOR
                SELECT id_district,
                       nvl2(desc_state_abbr, desc_district || ' - ' || desc_state_abbr, desc_district) desc_district,
                       id_geo_state
                  FROM (SELECT id_district,
                               (SELECT pk_translation.get_translation(i_lang,
                                                                      'GEO_STATE.CODE_GEO_STATE_ABBR.' || id_geo_state)
                                  FROM dual) desc_state_abbr,
                               pk_translation.get_translation(i_lang, code_district) desc_district,
                               id_geo_state
                          FROM district
                         WHERE flg_available = pk_alert_constant.g_yes
                           AND id_country = l_default_country)
                 WHERE desc_district IS NOT NULL
                 ORDER BY desc_district;
        
        ELSE
            l_message := 'OPEN O_DISTRICT WITH STATE';
            OPEN o_district FOR
                SELECT id_district,
                       nvl2(desc_state_abbr, desc_district || ' - ' || desc_state_abbr, desc_district) desc_district,
                       id_geo_state
                  FROM (SELECT to_char(id_district) id_district,
                               (SELECT pk_translation.get_translation(i_lang,
                                                                      'GEO_STATE.CODE_GEO_STATE_ABBR.' || i_geo_state)
                                  FROM dual) desc_state_abbr,
                               pk_translation.get_translation(i_lang, code_district) desc_district,
                               id_geo_state
                          FROM district d
                         WHERE flg_available = pk_alert_constant.g_yes
                           AND id_geo_state = i_geo_state)
                 WHERE desc_district IS NOT NULL
                 ORDER BY desc_district;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_state_district_list',
                                              o_error);
            pk_types.open_my_cursor(o_district);
            RETURN FALSE;
        
    END get_state_district_list;

    /**
    * Returns available states for the specified country
    *
    * @param   i_lang ui language
    * @param   i_prof object with user info
    * @param   i_country country id. If NULL, then institution's default country is used
    * @param   o_state cursor with states
    * @param   o_error erroe message
    *
    * @RETURN  true if sucess, false otherwise
    * @author  João Eiras
    * @version 1.0
    * @since   19-05-2008
    */
    FUNCTION get_state_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_country IN country.id_country%TYPE,
        o_state   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_country country.id_country%TYPE;
        l_message debug_msg;
    
    BEGIN
        IF i_country IS NULL
        THEN
            l_message := 'GET DEFAULT COUNTRY';
            l_country := pk_sysconfig.get_config('ID_COUNTRY', i_prof.institution, i_prof.software);
        ELSE
            l_country := i_country;
        END IF;
    
        l_message := 'OPEN O_STATE';
        OPEN o_state FOR
            SELECT *
              FROM (SELECT to_char(id_geo_state) id_geo_state,
                           pk_translation.get_translation(i_lang, code_geo_state) desc_state,
                           pk_translation.get_translation(i_lang, code_geo_state_abbr) desc_abbr,
                           id_country
                      FROM geo_state
                     WHERE flg_available = pk_alert_constant.g_yes
                       AND id_country = l_country)
             WHERE desc_state IS NOT NULL
             ORDER BY desc_state;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_state_list',
                                              o_error);
            pk_types.open_my_cursor(o_state);
            RETURN FALSE;
    END;

    --
    FUNCTION get_dept_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dept  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de departamentos de uma instituição
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - informação do profissional
                        Saida:   O_DEPT - lista de departamentos de uma instituição
                                 O_ERROR - erro
        
          CRIAÇÃO: jsilva 02/05/2007
          NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR O_DEPT';
        OPEN o_dept FOR
            SELECT id_dept, abbreviation, pk_translation.get_translation(i_lang, code_dept) dept
              FROM dept d
             WHERE id_institution = i_prof.institution
               AND d.flg_available = pk_alert_constant.g_yes
             ORDER BY d.rank, dept;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_dept_list',
                                              o_error);
            pk_types.open_my_cursor(o_dept);
            RETURN FALSE;
        
    END get_dept_list;
    --
    FUNCTION get_dept_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_dept       IN dept.id_dept%TYPE,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
               OBJECTIVO:   Obter lista dos serviços de um dado departamento
               PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                     I_PROF - informação do profissional
                                     I_DEPT - ID do departamento
                            Saida:   O_DEPT - lista de departamentos de uma instituição
                                     O_ERROR - erro
            
              CRIAÇÃO: jsilva 02/05/2007
              NOTAS:
        *********************************************************************************/
    
        l_message debug_msg;
        l_age     NUMBER;
        l_gender  patient.gender%TYPE;
    
    BEGIN
        l_message := 'GET PATIENT AGE';
        l_age     := pk_patient.get_pat_age(i_lang        => i_lang,
                                            i_dt_birth    => NULL,
                                            i_dt_deceased => NULL,
                                            i_age         => NULL,
                                            i_patient     => i_patient);
    
        l_message := 'GET PATIENT GENDER';
        l_gender  := pk_patient.get_pat_gender(i_id_patient => i_patient);
    
        l_message := 'GET CURSOR O_DEPARTMENT';
        OPEN o_department FOR
            SELECT id_department, abbreviation, pk_translation.get_translation(i_lang, code_department) department
              FROM department d
             WHERE id_institution = i_prof.institution
               AND d.id_dept = i_dept
               AND d.flg_available = pk_alert_constant.g_yes
               AND (d.adm_age_min IS NULL OR (d.adm_age_min IS NOT NULL AND d.adm_age_min <= l_age) OR l_age IS NULL)
               AND (d.adm_age_max IS NULL OR (d.adm_age_max IS NOT NULL AND d.adm_age_max >= l_age) OR l_age IS NULL)
               AND ((d.gender IS NOT NULL AND d.gender <> l_gender) OR d.gender IS NULL)
             ORDER BY d.rank, department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_dept_department',
                                              o_error);
            pk_types.open_my_cursor(o_department);
            RETURN FALSE;
    END get_dept_department;
    --
    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat               professional Category                 
    * @param o_professional           Lista dos professionais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/12
    **********************************************************************************************/
    FUNCTION get_prof_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_cat     IN category.flg_type%TYPE,
        o_professional OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_professional';
        OPEN o_professional FOR
            SELECT -1 data, pk_message.get_message(i_lang, 'COMMON_M002') label, 1 rank
              FROM dual
            UNION
            SELECT p.id_professional data,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                   2 rank
              FROM professional p
             WHERE p.id_professional = pk_sysconfig.get_config('ID_PROF_EXT', i_prof)
            UNION
            SELECT p.id_professional data,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                   3 rank
              FROM professional p, prof_cat pc, category c, prof_institution pi
             WHERE p.id_professional = pc.id_professional
               AND p.id_professional = pi.id_professional
               AND pi.id_institution = i_prof.institution
               AND pc.id_category = c.id_category
               AND pc.id_institution = pi.id_institution
               AND pi.dt_end_tstz IS NULL
               AND c.flg_type IN (g_cat_type_doctor, g_cat_type_nurse, g_cat_type_tech)
               AND c.flg_available = get_flg_available_yes()
               AND pi.flg_state = get_flg_state_active()
               AND p.flg_state = get_flg_state_active()
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_prof_institution',
                                              o_error);
            pk_types.open_my_cursor(o_professional);
            RETURN FALSE;
    END get_prof_institution;
    --

    /************************************************************************************************************ 
    * Obter uma lista dos profissionais da instituição, que pertencem a uma das categorias específicadas. 
    * A lista contém como primeiro elemento a opção 'Outros'.
    *
    * @param      i_lang             id language
    * @param      i_prof             id professional
    * @param      i_prof_cat         array with categories 
    * @param      o_prof_list        lista de todos o profissionais da instituição
    * @param      o_error            error message   
    *
    * @return     TRUE if sucess, FALSE otherwise
    * @author     Orlando Antunes 
    * @version    0.1
    * @since      2008/01/08
    ***********************************************************************************************************/
    FUNCTION get_prof_inst_and_other_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_cat  IN table_varchar,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        OPEN o_prof_list FOR
            SELECT DISTINCT p.id_professional data,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                            1 rank
              FROM professional p, prof_cat pc, category c, prof_institution pi
             WHERE p.flg_state = pk_alert_constant.g_active
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND p.id_professional = pc.id_professional
               AND p.id_professional = pi.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.dt_end_tstz IS NULL
               AND pi.flg_state = pk_alert_constant.g_active
               AND pc.id_category = c.id_category
               AND pc.id_institution = i_prof.institution
                  --  Ao seleccionar o "order by" deverá aparecer a lista de médicos que podem realizar co-sign e o nome do profissional 
                  -- que está a documentar (para o caso de poder realizar essa documentação) -- Daniela vinhas
                  -- PN, September 16, 2008 
               AND c.flg_type IN (SELECT *
                                    FROM TABLE(i_prof_cat))
            UNION ALL
            --ALERT-77788: Canastro - Changed used label from M041 "Others (free text)" to M096 "Other"
            SELECT -1 data, pk_message.get_message(i_lang, 'COMMON_M096') label, 0 rank
              FROM dual
             ORDER BY rank, label, data;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_prof_inst_and_other_list',
                                              o_error);
            pk_types.open_my_cursor(o_prof_list);
            RETURN FALSE;
    END get_prof_inst_and_other_list;
    --

    /********************************************************************************************
    * Gets the dep_clin_serv list selected by the given professional
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_dep                 department ID
    * @param o_dcs                 selected dep_clin_serv
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @version                     1.0
    * @since                       17-10-2007
    **********************************************************************************************/
    FUNCTION get_selected_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_dep     IN department.id_department%TYPE,
        o_dcs     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_message       debug_msg;
    
    BEGIN
        l_message := 'FIND DCS';
        SELECT nvl(ei.id_dcs_requested, ei.id_dep_clin_serv)
          INTO l_dep_clin_serv
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        OPEN o_dcs FOR
            SELECT dcs.id_dep_clin_serv,
                   dcs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_clin_serv,
                   decode(dcs.id_dep_clin_serv, l_dep_clin_serv, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_selected,
                   pdc.flg_default,
                   cli.rank
              FROM dep_clin_serv dcs, clinical_service cli, prof_dep_clin_serv pdc, department dpt
             WHERE dcs.id_dep_clin_serv = pdc.id_dep_clin_serv
               AND pdc.id_professional = i_prof.id
               AND dcs.id_clinical_service = cli.id_clinical_service
               AND dcs.id_department = nvl(i_dep, dcs.id_department)
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND cli.flg_available = pk_alert_constant.g_yes
               AND dpt.id_department = dcs.id_department
               AND dpt.flg_available = pk_alert_constant.g_yes
               AND dpt.id_institution = i_prof.institution
               AND pdc.flg_status = g_selected
               AND dpt.id_software = nvl2(i_dep, dpt.id_software, i_prof.software)
             ORDER BY cli.rank, desc_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_selected_dcs',
                                              o_error);
            pk_types.open_my_cursor(o_dcs);
            RETURN FALSE;
    END get_selected_dcs;

    /********************************************************************************************
    * Returns the list of specialties (for on-call physicians and physician's office)
    * or clinical services (for external institutions). Used to select a follow-up entity
    * in discharge instructions.
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_flg_entity          Type of entity: (OC) on-call physician
    *                                              (PH) physician's office
    *                                              (CL) clinic (external institutions)
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      José Brito
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_dischinstr_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_entity IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_invalid_param  EXCEPTION;
        l_internal_error EXCEPTION;
        l_dt_start       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end         TIMESTAMP WITH LOCAL TIME ZONE;
        l_default_period sys_config.value%TYPE;
        l_message        debug_msg;
    
        -- new RMGM
        l_str      VARCHAR2(4000 CHAR);
        l_inst_mkt market.id_market%TYPE;
        l_idx      NUMBER := 1;
        CURSOR c_fdata(i_mkt market.id_market%TYPE) IS
            SELECT REPLACE(ifd.value, '|', ',') ifdlist
              FROM institution_field_data ifd
             INNER JOIN field_market fm
                ON (fm.id_field_market = ifd.id_field_market)
             WHERE ifd.id_institution IN
                   (SELECT i.id_institution
                      FROM institution i
                     WHERE i.id_market = i_mkt
                       AND i.flg_external = pk_alert_constant.get_available
                       AND i.flg_available = pk_alert_constant.get_available)
               AND fm.id_field = 50;
    BEGIN
        SELECT i.id_market
          INTO l_inst_mkt
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        IF i_flg_entity = pk_alert_constant.g_followupwith_oc -- ON-CALL PHYSICIAN specialities
        THEN
            l_message := 'GET ON-CALL PERIOD DATES';
            pk_alertlog.log_debug(l_message);
            IF NOT pk_on_call_physician.get_on_call_period_dates(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 o_default_period => l_default_period, -- Length of the period (number of days)
                                                                 o_start_date     => l_dt_start, -- On-call period start date
                                                                 o_end_date       => l_dt_end, -- On-call period end date
                                                                 o_error          => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            l_message := 'OPEN SPEC LIST (OC)';
            pk_alertlog.log_debug(l_message);
            OPEN o_list FOR
                SELECT DISTINCT p.id_speciality data,
                                (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                   FROM speciality s
                                  WHERE s.id_speciality = p.id_speciality) label
                  FROM professional p, on_call_physician ocp
                 WHERE p.id_professional = ocp.id_professional
                   AND ocp.flg_status = pk_alert_constant.g_on_call_active
                   AND ocp.id_institution = i_prof.institution
                      -- Return only on-call physicians within the current list period
                   AND ocp.dt_start >= l_dt_start
                   AND ocp.dt_start < l_dt_end
                UNION ALL
                SELECT DISTINCT p.id_speciality data,
                                (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                   FROM speciality s
                                  WHERE s.id_speciality = p.id_speciality) label
                  FROM professional p, on_call_physician ocp
                 WHERE p.id_professional = ocp.id_professional
                   AND ocp.flg_status = pk_alert_constant.g_on_call_active
                   AND ocp.id_institution = i_prof.institution
                   AND ocp.dt_end > l_dt_start
                   AND ocp.dt_start < l_dt_start
                 ORDER BY label;
        
        ELSIF i_flg_entity = pk_alert_constant.g_followupwith_ph -- PHYSICIAN'S OFFICE specialities
        THEN
            l_message := 'OPEN SPEC LIST (PH)';
            pk_alertlog.log_debug(l_message);
            OPEN o_list FOR
            -- should be new clinical services from new multichoice
                SELECT DISTINCT p.id_speciality data, pk_translation.get_translation(i_lang, s.code_speciality) label
                  FROM professional p
                 INNER JOIN speciality s
                    ON (s.id_speciality = p.id_speciality)
                 WHERE p.flg_state = pk_alert_constant.g_active
                   AND EXISTS (SELECT 1
                          FROM prof_institution pi
                         WHERE pi.id_professional = p.id_professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_external = pk_alert_constant.g_yes
                           AND pi.flg_state = pk_alert_constant.g_active)
                 ORDER BY label;
        
        ELSIF i_flg_entity = pk_alert_constant.g_followupwith_cl -- CLINIC clinical services
        THEN
            FOR fd IN c_fdata(l_inst_mkt)
            LOOP
                IF l_idx = 1
                THEN
                    l_str := fd.ifdlist;
                ELSE
                    l_str := l_str || ',' || fd.ifdlist;
                END IF;
                l_idx := l_idx + 1;
            END LOOP;
            l_message := 'OPEN SPEC LIST (CL)';
            pk_alertlog.log_debug(l_message);
            OPEN o_list FOR
                SELECT cs.id_clinical_service data,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) label
                  FROM clinical_service cs
                 WHERE cs.id_clinical_service IN (SELECT column_value
                                                    FROM TABLE(pk_utils.str_split_n(l_str)))
                   AND cs.flg_available = pk_alert_constant.g_available
                   AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL;
        
        ELSE
            RAISE l_invalid_param;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHINSTR_SPEC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN l_invalid_param THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID PARAM',
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHINSTR_SPEC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHINSTR_SPEC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dischinstr_spec_list;

    /********************************************************************************************
    * Returns the list of professionals (on-call physicians or physician's office) or
    * external institutions (clinics) for a given speciality or clinical service
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_spec                Speciality or Clinical Service ID
    * @param i_flg_entity          Type of entity: (OC) on-call physician
    *                                              (PH) physician's office
    *                                              (CL) clinic (external institutions)
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      José Brito
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_dischinstr_names_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_spec       IN NUMBER,
        i_flg_entity IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_invalid_param  EXCEPTION;
        l_internal_error EXCEPTION;
        l_dt_start       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end         TIMESTAMP WITH LOCAL TIME ZONE;
        l_default_period sys_config.value%TYPE;
        l_message        debug_msg;
    
    BEGIN
        IF i_flg_entity = pk_alert_constant.g_followupwith_oc -- ON-CALL PHYSICIAN names
        THEN
            l_message := 'GET ON-CALL PERIOD DATES';
            pk_alertlog.log_debug(l_message);
            IF NOT pk_on_call_physician.get_on_call_period_dates(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 o_default_period => l_default_period, -- Length of the period (number of days)
                                                                 o_start_date     => l_dt_start, -- On-call period start date
                                                                 o_end_date       => l_dt_end, -- On-call period end date
                                                                 o_error          => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            l_message := 'OPEN NAMES LIST (OC)';
            pk_alertlog.log_debug(l_message);
            OPEN o_list FOR
                SELECT p.id_professional data,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                       -- Info for the discharge instructions screen
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_spec,
                       --
                       p.address,
                       p.city,
                       p.district,
                       p.zip_code,
                       (SELECT pk_translation.get_translation(i_lang, c.code_country)
                          FROM country c
                         WHERE c.id_country = p.id_country) desc_country,
                       --
                       p.work_phone,
                       p.fax,
                       NULL         website,
                       p.email
                  FROM professional p
                 WHERE p.id_speciality = i_spec
                   AND EXISTS (SELECT 1
                          FROM on_call_physician ocp
                         WHERE ocp.id_professional = p.id_professional
                           AND ocp.flg_status = pk_alert_constant.g_on_call_active
                           AND ocp.id_institution = i_prof.institution
                              -- Return only on-call physicians within the current list period
                           AND ocp.dt_start >= l_dt_start
                           AND ocp.dt_start < l_dt_end)
                UNION ALL
                SELECT p.id_professional data,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                       -- Info for the discharge instructions screen
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_spec,
                       --
                       p.address,
                       p.city,
                       p.district,
                       p.zip_code,
                       (SELECT pk_translation.get_translation(i_lang, c.code_country)
                          FROM country c
                         WHERE c.id_country = p.id_country) desc_country,
                       --
                       p.work_phone,
                       p.fax,
                       NULL         website,
                       p.email
                  FROM professional p
                 WHERE p.id_speciality = i_spec
                   AND EXISTS (SELECT 1
                          FROM on_call_physician ocp
                         WHERE ocp.id_professional = p.id_professional
                           AND ocp.flg_status = pk_alert_constant.g_on_call_active
                           AND ocp.id_institution = i_prof.institution
                              -- Return only on-call physicians within the current list period
                           AND ocp.dt_end > l_dt_start
                           AND ocp.dt_start < l_dt_start)
                 ORDER BY label;
        
        ELSIF i_flg_entity = pk_alert_constant.g_followupwith_ph -- PHYSICIAN'S OFFICE names
        THEN
            l_message := 'OPEN NAMES LIST (PH)';
            pk_alertlog.log_debug(l_message);
            OPEN o_list FOR
                SELECT p.id_professional data,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label,
                       -- Info for the discharge instructions screen
                       (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                          FROM speciality s
                         WHERE s.id_speciality = p.id_speciality) desc_spec,
                       --
                       p.address,
                       p.city,
                       p.district,
                       p.zip_code,
                       (SELECT pk_translation.get_translation(i_lang, c.code_country)
                          FROM country c
                         WHERE c.id_country = p.id_country) desc_country,
                       --
                       p.work_phone,
                       p.fax,
                       NULL         website,
                       p.email
                  FROM professional p
                 WHERE p.flg_state = pk_alert_constant.g_active
                   AND p.id_speciality = i_spec
                   AND EXISTS (SELECT 1
                          FROM prof_institution pi
                         WHERE pi.id_professional = p.id_professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_external = pk_alert_constant.get_available)
                 ORDER BY label;
        
        ELSIF i_flg_entity = pk_alert_constant.g_followupwith_cl -- CLINIC names
        THEN
            l_message := 'OPEN NAMES LIST (CL)';
            pk_alertlog.log_debug(l_message);
            OPEN o_list FOR
                SELECT i.id_institution data,
                       pk_translation.get_translation(i_lang, i.code_institution) label,
                       -- Info for the discharge instructions screen
                       (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                          FROM clinical_service cs
                         WHERE cs.id_clinical_service = i_spec) desc_spec,
                       --
                       i.address,
                       i.location city,
                       i.district,
                       i.zip_code,
                       (SELECT pk_translation.get_translation(i_lang, c.code_country)
                          FROM country c
                         WHERE c.id_country = ia.id_country) desc_country,
                       --
                       i.phone_number work_phone,
                       i.fax_number fax,
                       (SELECT decode(ifd1.value, 0, NULL, ifd1.value)
                          FROM institution_field_data ifd1
                         WHERE ifd1.id_institution = i.id_institution
                           AND ifd1.id_field_market = 22) website,
                       ia.email
                  FROM institution i
                 INNER JOIN inst_attributes ia
                    ON (ia.id_institution = i.id_institution)
                 INNER JOIN institution_field_data ifd
                    ON (ifd.id_institution = i.id_institution AND ifd.id_field_market = 24)
                 WHERE i.flg_available = pk_alert_constant.g_yes
                   AND i.flg_external = pk_alert_constant.g_yes
                   AND i.id_market IN (SELECT id_market
                                         FROM institution i
                                        WHERE i.id_institution = i_prof.institution)
                   AND i_spec IN (SELECT column_value
                                    FROM TABLE(pk_utils.str_split_n(REPLACE(ifd.value, '|', ','))))
                 ORDER BY label;
        
        ELSE
            RAISE l_invalid_param;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHINSTR_NAMES_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN l_invalid_param THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID PARAM',
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHINSTR_NAMES_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHINSTR_NAMES_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dischinstr_names_list;

    /********************************************************************************************
    * N3 - Estado de doença do paciente: 'I'-incapacitante para actividade profissional, 'E'-exige cuidados inadiáveis
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_disease_state
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_disease_state, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_DISEASE_STATE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N26 (subsistema saúde convencionado - Médico): 'E'-ADSE, 'M'-ADM, 'J'-SSMJ, 'P'-SADPSP, 'R'-SADGNR
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_prof_health_subsys
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_prof_health_subsys, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_PROF_HEALTH_SUBSYS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N33 (subsistema saúde convencionado - Funcionário / agente) : 'E'-ADSE, 'M'-ADM, 'J'-SSMJ, 'P'-SADPSP, 'R'-SADGNR
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_benef_health_subsys
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_benef_health_subsys, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_BENEF_HEALTH_SUBSYS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N10 (Classificação da situação - Segurança Social): 'N'-Doença natural, 'D'-Doença directa, 'A'-Assistência a familiares, 'P'-Doença profissional, 'T'-Acidente de trabalho
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_classification_ss
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_classification_ss, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_CLASSIFICATION_SS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N34 (Classificação da situação - Função Pública): 'N'-Doença natural, 'D'-Doença directa, 'A'-Assistência a familiares, 'P'-Doença prolongada, 'F'-Assistência a filhos menores de 10 anos
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_classification_fp
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_classification_fp, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_CLASSIFICATION_FP',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N38 (Internamento): 'Y'-Sim, 'N'-Não
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_internment
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_internment, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_INTERNMENT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N12 (Período de incapacidade): 'I'-Inicial, 'P'-Prorrogação
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_incapacity_period
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_incapacity_period, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_INCAPACITY_PERIOD',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * N39 (Ausência do domicílio): 'Y'-Sim, 'N'-Não
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_home_absence
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_home_absence, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_HOME_ABSENCE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Razões de Cancelamento CIT: 'E'-Engano/erro, 'A'-Alteração da situação clínica, 'O'-Outros
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_cancel_reason
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_cancel_reason, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_CANCEL_REASON',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Status da CIT: 'I'-Impresso, 'T'-Construção, 'C'-Cancelado
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_status
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_status, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Tipo de CIT: 'S'-Segurança Social, 'P'-Função Publica
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_type
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_type, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CIT_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Ill affinity de CIT: 'F' - Filho(a) ou equiparado, 'C' - Cônjuge ou equiparado, 
    * 'P' - Pai/Mãe ou equiparado, 'A' - Avô/Avó ou equiparado, 'N' - Neto(a) ou equiparado, 'O' - Outro
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       03-04-2009
    **********************************************************************************************/
    FUNCTION get_cit_ill_affinity
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR';
        RETURN pk_sysdomain.get_values_domain(g_cit_ill_affinity, i_lang, o_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_cit_ill_affinity',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns episode appoitment type - S - sem presenca do utente, V - vigilância, D - Doença. NULL representa um contacto directo.
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @version                     1.0
    * @since                       36-05-2009
    **********************************************************************************************/
    FUNCTION get_epis_appointment_type
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'CALL pk_sysdomain.get_values_domain';
        IF NOT pk_sysdomain.get_values_domain(i_code_dom        => pk_grid_amb.g_domain_sch_presence,
                                              i_lang            => i_lang,
                                              o_data_grid_color => o_list,
                                              o_error           => o_error)
        THEN
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_APPOINTMENT_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_epis_appointment_type;
    --
    /********************************************************************************************
    * Given a institution returns a list of all institutions that belong to the same group
    *
    * @param i_institution         institution id
    * @param i_flg_relation        type of relation between institutions
    *    
    * @return                      list of all institutions that belong to the same group
    *
    * @author                      Alexandre Santos
    * @version                     1.0
    * @since                       21-05-2009
    **********************************************************************************************/
    FUNCTION tf_get_all_inst_group
    (
        i_institution  IN institution_group.id_institution%TYPE,
        i_flg_relation IN institution_group.flg_relation%TYPE
    ) RETURN table_number IS
        l_tbl_inst table_number;
    BEGIN
    
        SELECT id_institution
          BULK COLLECT
          INTO l_tbl_inst
          FROM (SELECT ig.id_institution
                  FROM institution_group ig
                 WHERE ig.id_group = (SELECT ig2.id_group
                                        FROM institution_group ig2
                                       WHERE ig2.id_institution = i_institution
                                         AND ig2.flg_relation = i_flg_relation)
                   AND ig.flg_relation = i_flg_relation);
    
        IF (l_tbl_inst.count = 0)
        THEN
            l_tbl_inst := table_number(i_institution);
        END IF;
    
        RETURN l_tbl_inst;
    EXCEPTION
        WHEN no_data_found THEN
            l_tbl_inst := table_number(i_institution);
            RETURN l_tbl_inst;
    END;

    /**
     * This function returns all professionals associated with a determined
     * category of an institution.
     *
     * @param  IN  Language ID
     * @param  IN  Category Flag
     * @param  IN  Institution ID
     * @param  OUT Professional cursor
     * @param  OUT Error structure
     *
     * @return BOOLEAN
     *
     * @since   11/09/2009
     * @version 2.5.0.7
     * @author  Pedro Carneiro
    */
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_category    IN category.flg_type%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        OPEN o_profs FOR
            SELECT pc.id_professional,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    profissional(pc.id_professional, NULL, NULL),
                                                    pc.id_professional) prof_name
              FROM prof_cat pc
              JOIN category c
             USING (id_category)
             WHERE pc.id_institution = i_institution
               AND c.flg_type = i_category;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CAT_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_cat_prof_list;

    /********************************************************************************************
    * Returns possible values for "Admitido na instituição"
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @since                       01/03/2010
    **********************************************************************************************/
    FUNCTION get_dti_admission_state
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR O_LIST';
        RETURN pk_sysdomain.get_values_domain('YES_NO', i_lang, o_list);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DTI_ADMISSION_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns possible values for transportation needs (Y / N)
    *
    * @param i_lang                language ID
    * @param o_list                List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @since                       01/03/2010
    **********************************************************************************************/
    FUNCTION get_dti_granted_transport
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR O_LIST';
        RETURN pk_sysdomain.get_values_domain('YES_NO', i_lang, o_list);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DTI_NEEDS_TRANSPORTATION',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns possible refused reasons
    *
    * @param i_lang                language ID
    * @param o_refused_reasons     List of results
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Pedro Teixeira
    * @since                       01/03/2010
    **********************************************************************************************/
    FUNCTION get_dti_refused_reasons
    (
        i_lang            IN language.id_language%TYPE,
        o_refused_reasons OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR O_REFUSED_REASONS';
        RETURN pk_sysdomain.get_values_domain(g_domain_dti_refused_reason, i_lang, o_refused_reasons);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DTI_REFUSED_STATES',
                                              o_error);
            pk_types.open_my_cursor(o_refused_reasons);
            RETURN FALSE;
    END;

    /*********************************************************************************************
    * Returns available languages list
    * 
    * @param         i_lang                user language
    *
    * @param         o_language_list       languages list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Rui Spratley
    * @version       2.6.0.4
    * @date          2010/10/29
    ********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang          IN language.id_language%TYPE,
        o_language_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'GET LIST';
        OPEN o_language_list FOR
            SELECT l.id_language, pk_translation.get_translation(i_lang, l.code_language) desc_language
              FROM LANGUAGE l
             ORDER BY 2;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_LIST',
                                              i_function => 'GET_LANGUAGE_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_language_list);
            RETURN FALSE;
    END get_language_list;

    FUNCTION get_language_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
    
        l_message debug_msg;
        l_return  t_tbl_core_domain;
        l_error   t_error_out;
    
        l_id_market market.id_market%TYPE := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
    BEGIN
    
        l_message := 'OPEN L_RETURN';
        SELECT *
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_language,
                                         domain_value  => id_language,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT t.id_language,
                               t.desc_language,
                               translate(upper(t.desc_language), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') desc_lang_order,
                               1 rank
                          FROM (SELECT il.id_iso_lang id_language,
                                       pk_translation.get_translation(i_lang, il.code_iso_lang) desc_language,
                                       1 rank
                                  FROM iso_lang il
                                  JOIN iso_norm_lang inl
                                    ON inl.id_iso_lang = il.id_iso_lang
                                  JOIN iso_norm i
                                    ON i.id_iso_norm = inl.id_iso_norm
                                  JOIN market_iso mi
                                    ON mi.id_iso_norm = i.id_iso_norm
                                 WHERE mi.id_market = l_id_market
                                   AND il.flg_available = pk_alert_constant.g_yes
                                   AND il.flg_free_text = pk_alert_constant.g_no) t
                         WHERE t.desc_language IS NOT NULL
                        UNION
                        SELECT il.id_iso_lang id_language,
                               pk_message.get_message(i_lang, 'COMMON_M096') desc_language,
                               NULL desc_lang_order,
                               999 rank
                          FROM iso_lang il
                         WHERE il.flg_available = pk_alert_constant.g_yes
                           AND il.flg_free_text = pk_alert_constant.g_yes
                         ORDER BY rank, desc_lang_order));
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_core_domain();
    END get_language_list;

    /*********************************************************************************************
    * Returns available specialties list
    * 
    * @param         i_lang                user language
    *
    * @param         o_specialty_list      specialty list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Rui Spratley
    * @version       2.6.0.4
    * @date          2010/10/29
    ********************************************************************************************/
    FUNCTION get_specialty_list
    (
        i_lang           IN language.id_language%TYPE,
        o_specialty_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'GET LIST';
        OPEN o_specialty_list FOR
            SELECT s.id_speciality, pk_translation.get_translation(i_lang, s.code_speciality) desc_specialty
              FROM speciality s
             WHERE s.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, s.code_speciality) IS NOT NULL
             ORDER BY pk_translation.get_translation(i_lang, s.code_speciality);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_LIST',
                                              i_function => 'GET_SPECIALTY_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_specialty_list);
            RETURN FALSE;
    END get_specialty_list;

    FUNCTION get_specialty_list(i_lang IN language.id_language%TYPE) RETURN t_tbl_core_domain IS
        l_message debug_msg;
    
        l_return t_tbl_core_domain;
        l_error  t_error_out;
    BEGIN
    
        l_message := 'GET LIST';
        SELECT *
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_specialty,
                                         domain_value  => id_speciality,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT s.id_speciality, pk_translation.get_translation(i_lang, s.code_speciality) desc_specialty
                          FROM speciality s
                         WHERE s.flg_available = pk_alert_constant.g_yes
                           AND pk_translation.get_translation(i_lang, s.code_speciality) IS NOT NULL
                         ORDER BY pk_translation.get_translation(i_lang, s.code_speciality)));
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SPECIALTY_LIST',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_specialty_list;
    /*********************************************************************************************
    * Returns available categories list
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    *
    * @return        pipelined results
    *
    * @author        RMGM
    * @version       2.6.4.0
    * @date          2014/05/12
    ********************************************************************************************/
    FUNCTION get_pipelined_cat_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_values_domain_mkt
        PIPELINED IS
    
        CURSOR c_cat IS
            SELECT pk_translation.get_translation(i_lang, code_category) desc_val,
                   id_category val,
                   NULL img_name,
                   1 rank,
                   
                   NULL code_domain
              FROM category
             WHERE flg_available = pk_alert_constant.g_yes
               AND flg_prof = pk_alert_constant.g_yes
             ORDER BY 1;
        l_message /*debug_msg*/
        VARCHAR2(1000);
        rec_out   t_rec_values_domain_mkt;
        o_error   t_error_out;
    BEGIN
        l_message := 'GET CURSOR';
        FOR rec IN c_cat
        LOOP
            rec_out := t_rec_values_domain_mkt(rec.desc_val, rec.val, rec.img_name, rec.rank, rec.code_domain);
            PIPE ROW(rec_out);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              /*g_package_owner*/
                                              'A',
                                              /*g_package_name*/
                                              'B',
                                              'get_cat_list',
                                              o_error);
            RETURN;
    END get_pipelined_cat_list;

    /*********************************************************************************************
    * Returns available countries
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    * @param         o_country             country list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Anna Kurowska
    * @version       2.8.0.0
    * @date          2019/07/12
    ********************************************************************************************/
    FUNCTION get_country
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_default_country sys_config.value%TYPE;
        l_message         debug_msg;
    
    BEGIN
    
        l_message         := 'GET DEFAULT COUNTRY';
        l_default_country := pk_sysconfig.get_config('ID_COUNTRY', i_prof.institution, i_prof.software);
        l_message         := 'GET CURSOR';
        OPEN o_country FOR
            SELECT c.id_country id,
                   1 rank,
                   pk_translation.get_translation(i_lang, c.code_country) description,
                   decode(id_country, l_default_country, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM country c
             WHERE c.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, c.code_country) IS NOT NULL
             ORDER BY pk_translation.get_translation(i_lang, c.code_country);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_country',
                                              o_error);
            pk_types.open_my_cursor(o_country);
            RETURN FALSE;
    END get_country;

    /*********************************************************************************************
    * Returns available nationalities
    * 
    * @param         i_lang                user language
    * @param         i_prof                prof_array
    * @param         o_nationality         nationality list
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Anna Kurowska
    * @version       2.8.0.0
    * @date          2019/07/12
    ********************************************************************************************/
    FUNCTION get_nationality
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_nationality OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_default_country sys_config.value%TYPE;
        l_message         debug_msg;
    
    BEGIN
    
        l_message         := 'GET DEFAULT COUNTRY';
        l_default_country := pk_sysconfig.get_config('ID_COUNTRY', i_prof.institution, i_prof.software);
        l_message         := 'GET CURSOR';
    
        OPEN o_nationality FOR
        
            SELECT id,
                   rank,
                   desc_nationality || nvl2(desc_country, '(' || desc_country || ')', '') description,
                   flg_default
              FROM (SELECT c.id_country id,
                           1 rank,
                           pk_translation.get_translation(i_lang, c.code_nationality) desc_nationality,
                           pk_translation.get_translation(i_lang, c.code_country) desc_country,
                           decode(l_default_country, id_country, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                      FROM country c
                     WHERE pk_translation.get_translation(i_lang, c.code_nationality) IS NOT NULL
                       AND c.flg_available = 'Y')
             ORDER BY desc_nationality, desc_country;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_nationality',
                                              o_error);
            pk_types.open_my_cursor(o_nationality);
            RETURN FALSE;
    END get_nationality;

    FUNCTION get_disch_type_closure_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    BEGIN
        l_message := 'CALL pk_discharge_amb.get_disch_type_closure_list';
        pk_discharge_amb.get_disch_type_closure_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'get_disch_type_closure_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_disch_type_closure_list;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
