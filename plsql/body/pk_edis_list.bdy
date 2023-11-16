/*-- Last Change Revision: $Rev: 2027084 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_list AS

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_transp) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_transp_entity, NULL transp_entity, NULL flg_status, NULL rank
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    /**********************************************************************************************
    * Obter lista de entidades que transportam doentes
    *
    * @param i_lang                   the id language
    * @param i_transp                 Tipo de transporte: A - chegada, D - partida  
    * @param i_prof                   professional, software and institution ids
    * @param o_transp                 cursor with transports entity 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/19 
    **********************************************************************************************/
    FUNCTION get_transp_entity_list
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_transp IN transp_entity.flg_transp%TYPE,
        i_prof   IN alert.profissional,
        o_transp OUT cursor_transp,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- ALERT-237185
        -- l_id_transp_ent := pk_sysconfig.get_config('ID_TRANSP_ENTITY', i_prof);
    
        g_error := 'OPEN O_TRANSP';
        OPEN o_transp FOR
            SELECT *
              FROM (SELECT te.id_transp_entity,
                           pk_translation.get_translation(i_lang, te.code_transp_entity) transp_entity,
                           pk_alert_constant.g_inactive flg_status,
                           te.rank
                      FROM transp_entity te
                      JOIN transp_ent_inst tei
                        ON tei.id_transp_entity = te.id_transp_entity
                     WHERE tei.id_institution = i_prof.institution
                       AND te.flg_transp = i_transp
                       AND te.flg_type = 'A'
                       AND te.flg_available = g_yes
                       AND tei.flg_available = g_yes
                       AND nvl(tei.flg_type, g_transp_all) IN (g_transp_disch, g_transp_all)
                       AND rownum > 0) -- dummy condition in order to prevent performance issues
             WHERE transp_entity IS NOT NULL
             ORDER BY rank, transp_entity;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_LIST',
                                              'GET_TRANSP_ENTITY_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            open_my_cursor(o_transp);
            RETURN FALSE;
    END get_transp_entity_list;
    --
    /**********************************************************************************************
    * Obter lista das especialidades das urgências
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro    
    * @param o_special                cursor with speciality
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/20
    **********************************************************************************************/
    FUNCTION get_speciality_list
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN alert.profissional,
        i_flg_type IN category.flg_type%TYPE,
        o_special  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_SPECIAL';
        OPEN o_special FOR
            SELECT DISTINCT sp.id_speciality,
                            pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality
              FROM prof_soft_inst psi
              JOIN professional p
                ON psi.id_professional = p.id_professional
              JOIN speciality sp
                ON p.id_speciality = sp.id_speciality
              JOIN prof_cat pc
                ON pc.id_professional = psi.id_professional
              JOIN category c
                ON pc.id_category = c.id_category
             WHERE psi.id_software = i_prof.software
               AND psi.id_institution = i_prof.institution
               AND sp.flg_available = g_yes
               AND psi.flg_log = 'Y'
               AND p.flg_state = g_prof_active
               AND pc.id_institution = i_prof.institution
               AND c.flg_type = i_flg_type
             ORDER BY desc_speciality;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_LIST',
                                              'GET_SPECIALITY_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_special);
            RETURN FALSE;
    END get_speciality_list;
    --
    /**********************************************************************************************
    * Obter lista de todos os profissionais de uma especialidade e que ainda não tenham saída de turno
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_speciality             speciality id     
    * @param i_flg_screen             Identifica qual o ecran onde se realiza a transferência de responsabilidade: 
                                                        OUT - Ecran do Hand Off; IN - Ecran do Hand Off do paciente 
    * @param i_flg_type               Tipo de listagem: A - All: É possível a transferência de responsabilidade para um ou mais profissionais                                               
                                                        S - Single: Só é possível a transferência de responsabilidade para um profissional 
    * @param o_spec_p                 cursor with speciality / professional
    * @param o_flg_type               cursor with types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/20
    **********************************************************************************************/
    FUNCTION get_spec_prof_list
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN alert.profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        i_flg_screen IN VARCHAR2,
        i_flg_type   IN category.flg_type%TYPE,
        o_spec_p     OUT pk_types.cursor_type,
        o_flg_type   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_screen = 'OUT'
        THEN
            o_flg_type := pk_sysconfig.get_config('EDIS_HAND_OFF_OUT', i_prof);
        ELSE
            o_flg_type := pk_sysconfig.get_config('EDIS_HAND_OFF_IN', i_prof);
        END IF;
    
        g_error := 'OPEN O_SPEC_P';
        OPEN o_spec_p FOR
            SELECT p.id_professional,
                   1 rank,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
              FROM professional p
              JOIN prof_in_out pio
                ON pio.id_professional = p.id_professional
              JOIN prof_cat pc
                ON pc.id_professional = pio.id_professional
              JOIN category c
                ON pc.id_category = c.id_category
             WHERE p.id_professional != i_prof.id
               AND p.id_speciality = i_speciality
               AND pio.id_software = i_prof.software
               AND pio.id_institution = i_prof.institution
               AND p.flg_state = g_prof_active
               AND pc.id_institution = i_prof.institution
               AND c.flg_type = i_flg_type
               AND pio.dt_out_tstz IS NULL
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
            UNION ALL
            SELECT -1 id_professional, -1 rank, pk_message.get_message(i_lang, 'OPINION_M001') nick_name
              FROM dual
             WHERE o_flg_type = 'A'
             ORDER BY rank, nick_name;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_LIST',
                                              'GET_SPEC_PROF_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_spec_p);
            RETURN FALSE;
    END get_spec_prof_list;
    --
    /**********************************************************************************************
    * Return professional's category.flg_type within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         FLG_TYPE from category table
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/12/17
    **********************************************************************************************/
    FUNCTION get_prof_cat(i_prof IN alert.profissional) RETURN VARCHAR2 IS
        l_type category.flg_type%TYPE;
        tbl_type table_varchar;
    BEGIN
        SELECT c.flg_type
          BULK COLLECT
          INTO tbl_type
          FROM prof_cat pc
          JOIN category c
            ON pc.id_category = c.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
	
        IF tbl_type.count > 0
        THEN
            l_type := tbl_type(1);
        END IF;
    
        RETURN l_type;
     END get_prof_cat;
    --
    /**********************************************************************************************
    * Lista serviços clinicos para filtrar profissionais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_soft               'Y' is to filtrate by software otherwise 'N'
    * @param o_clin_servs             cursor with clinical services
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/06/30
    **********************************************************************************************/
    FUNCTION get_clin_serv_list
    (
        i_lang       IN NUMBER,
        i_prof       IN alert.profissional,
        i_flg_soft   IN VARCHAR2,
        o_clin_servs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_clin_servs';
        OPEN o_clin_servs FOR
            SELECT DISTINCT dcs.id_clinical_service,
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           dcs.id_clinical_service) desc_clin_serv
              FROM dept d
              JOIN software_dept sd
                ON sd.id_dept = d.id_dept
              JOIN department dt
                ON dt.id_dept = d.id_dept
              JOIN dep_clin_serv dcs
                ON dcs.id_department = dt.id_department
             WHERE d.id_institution = i_prof.institution
               AND ((sd.id_software = i_prof.software AND i_flg_soft = pk_alert_constant.g_yes) OR
                   i_flg_soft = pk_alert_constant.g_no)
               AND EXISTS
             (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                      JOIN dep_clin_serv dcs_prof
                        ON dcs_prof.id_dep_clin_serv = pdcs.id_dep_clin_serv
                      JOIN prof_institution pi
                        ON pi.id_professional = pdcs.id_professional
                     WHERE dcs_prof.id_clinical_service = dcs.id_clinical_service
                       AND pk_edis_list.get_prof_cat(profissional(pdcs.id_professional,
                                                                  i_prof.institution,
                                                                  i_prof.software)) = g_prof_cat_doc
                       AND pdcs.flg_status = g_prof_dcs_status_active
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = g_prof_active
                       AND pi.dt_end_tstz IS NULL
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes
                       AND pdcs.id_institution = i_prof.institution)
               AND d.flg_available = g_yes
               AND dcs.flg_available = g_yes
               AND dt.flg_available = g_yes
             ORDER BY desc_clin_serv ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_LIST',
                                              'GET_CLIN_SERV_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_clin_servs);
            RETURN FALSE;
    END get_clin_serv_list;
    --

    /**********************************************************************************************
    * Lista profissionais por serviço clinico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_clin_serv              clinical service department id    
    * @param o_profs                  cursor with professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/06/30
    **********************************************************************************************/
    FUNCTION get_profs_by_clin_serv
    (
        i_lang      IN NUMBER,
        i_prof      IN alert.profissional,
        i_clin_serv IN dep_clin_serv.id_clinical_service%TYPE,
        o_profs     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'OPEN O_PROFS';
        IF NOT get_profs_by_clin_serv(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_clin_serv       => i_clin_serv,
                                      i_flg_option_none => pk_alert_constant.g_no,
                                      o_profs           => o_profs,
                                      o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_LIST',
                                              'GET_PROFS_BY_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_profs_by_clin_serv;

    /**********************************************************************************************
    * Lista profissionais por serviço clinico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_clin_serv              clinical service department id    
    * @param i_flg_option_none        Show option "None"? (Y) Yes (N) No
    * @param o_profs                  cursor with professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/06/30
    **********************************************************************************************/
    FUNCTION get_profs_by_clin_serv
    (
        i_lang            IN NUMBER,
        i_prof            IN alert.profissional,
        i_clin_serv       IN dep_clin_serv.id_clinical_service%TYPE,
        i_flg_option_none IN VARCHAR2,
        o_profs           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_PROFS';
        OPEN o_profs FOR
            SELECT NULL id_professional, pk_message.get_message(i_lang, 'COMMON_M043') prof_name, 0 rank
              FROM dual
             WHERE i_flg_option_none = pk_alert_constant.g_yes
            UNION ALL
            SELECT DISTINCT pdcs.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) prof_name,
                            1 rank
              FROM prof_dep_clin_serv pdcs
              JOIN dep_clin_serv dcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
             WHERE dcs.id_clinical_service = i_clin_serv
               AND pdcs.flg_status = g_prof_dcs_status_active
               AND pdcs.id_institution = i_prof.institution
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND pk_edis_list.get_prof_cat(profissional(pdcs.id_professional, i_prof.institution, i_prof.software)) =
                   g_prof_cat_doc
             ORDER BY rank, prof_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_LIST',
                                              'GET_PROFS_BY_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_profs_by_clin_serv;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_edis_list;
/
