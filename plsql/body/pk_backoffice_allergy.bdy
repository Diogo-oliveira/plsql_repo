/*-- Last Change Revision: $Rev: 2026765 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_allergy IS

    -- Author  : ANA.RITA & FABIO.OLIVEIRA
    -- Created : 02-12-2008 11:23:41
    -- Purpose : Parametrização de Alergias
    -- Function and procedure implementations

    g_error VARCHAR2(2000);

    /********************************************************************************************
    * get_allergy_state_list
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List of states - allergys
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     0.1
    * @since                       2008/12/02
    ********************************************************************************************/
    FUNCTION get_allergy_state_list
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET LIST CURSOR';
        /* Get a set of statuses available for choice inside the application */
        /* Currently on 'A' for active and 'I' for inactive */
        OPEN o_list FOR
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = i_code_domain
               AND flg_available = pk_alert_constant.g_yes
               AND id_language = i_lang
               AND length(val) <= 1
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_ALLERGY',
                                   'GET_ALLERGY_STATE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_allergy_state_list;

    /********************************************************************************************
    * Get (Primarys Allergies) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param o_primary_allergy       Primary Allergy Group List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/09
    ********************************************************************************************/
    FUNCTION get_primary_allergies_list
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        o_primary_allergy OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'get_primary_allergies_list CURSOR';
        /* Get a set of primary allergies (those who have no parent allergy) available for selection */
        OPEN o_primary_allergy FOR
            SELECT a.id_allergy id, pk_translation.get_translation(i_lang, a.code_allergy) name, a.rank rank
              FROM allergy a
             WHERE a.id_allergy_parent IS NULL
               AND a.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
               AND EXISTS (SELECT 0
                      FROM allergy a2
                     WHERE a2.id_allergy_parent = a.id_allergy
                       AND a2.flg_available = pk_alert_constant.g_yes
                       AND pk_translation.get_translation(i_lang, a2.code_allergy) IS NOT NULL)
             ORDER BY name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_primary_allergy);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_ALLERGY',
                                   'GET_PRIMARY_ALLERGIES_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_primary_allergies_list;

    /********************************************************************************************
    * Get Active Allergies List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software            Software ID
    * @param o_list                Allergy List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_active_allergies_list
    (
        i_software    IN software.id_software%TYPE,
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sysdomain_active sys_domain.desc_val%TYPE;
    BEGIN
        g_error            := 'PREFETCH';
        l_sysdomain_active := pk_sysdomain.get_domain('BO_ALLERGY_INST_SOFT.FLG_TYPE',
                                                      pk_alert_constant.g_active,
                                                      i_lang);
    
        g_error := 'get_active_allergies_list CURSOR';
        OPEN o_list FOR
            SELECT ais.id_allergy id,
                   l_sysdomain_active status_desc,
                   pk_alert_constant.g_active flg_status,
                   (pk_backoffice_allergy.get_allergy_parent(i_lang, a.id_allergy_parent) || '/' ||
                   pk_translation.get_translation(i_lang, a.code_allergy)) name
              FROM allergy_inst_soft ais, allergy a
             WHERE ais.id_software IN (i_software, 0)
               AND a.id_allergy = ais.id_allergy
               AND a.id_allergy_parent IS NOT NULL
               AND ais.id_institution = i_institution
               AND a.flg_available = pk_alert_constant.g_yes
               AND ais.id_allergy = a.id_allergy
               AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
             ORDER BY name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_ALLERGY',
                                   'GET_ACTIVE_ALLERGIES_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_active_allergies_list;

    /********************************************************************************************
    * Get (Secondary Allergies) Group List
    *
    * @param i_allergy_parent        Allergy Parent ID
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param o_g_list                Allergy List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_sec_allergies_list
    (
        i_allergy_parent IN allergy.id_allergy%TYPE,
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        o_g_list         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sysdomain_active   sys_domain.desc_val%TYPE;
        l_sysdomain_inactive sys_domain.desc_val%TYPE;
    BEGIN
        g_error              := 'PREFETCH';
        l_sysdomain_active   := pk_sysdomain.get_domain('BO_ALLERGY_INST_SOFT.FLG_TYPE',
                                                        pk_alert_constant.g_active,
                                                        i_lang);
        l_sysdomain_inactive := pk_sysdomain.get_domain('BO_ALLERGY_INST_SOFT.FLG_TYPE',
                                                        pk_alert_constant.g_inactive,
                                                        i_lang);
    
        g_error := 'get_sec_allergies_list CURSOR';
        OPEN o_g_list FOR
            SELECT id,
                   name,
                   CAST(COLLECT(to_char(id_software) || ',' || flg_type || ',' || type_desc) AS table_varchar) values_desc
              FROM (SELECT ais.id_allergy id,
                           pk_translation.get_translation(i_lang, a.code_allergy) name,
                           pk_alert_constant.g_active flg_type,
                           l_sysdomain_active type_desc,
                           si.id_software id_software
                      FROM allergy a, allergy_inst_soft ais, software_institution si, software s
                     WHERE a.id_allergy = ais.id_allergy
                       AND ais.id_software IN (si.id_software, 0)
                       AND si.id_institution = i_institution
                       AND ais.id_institution = i_institution
                       AND s.flg_mni = pk_alert_constant.g_yes
                       AND a.flg_available = pk_alert_constant.g_yes
                       AND si.id_software = s.id_software
                       AND a.id_allergy_parent = i_allergy_parent
                       AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                    UNION ALL
                    SELECT a.id_allergy id,
                           pk_translation.get_translation(1, a.code_allergy) name,
                           pk_alert_constant.g_inactive flg_type,
                           l_sysdomain_inactive type_desc,
                           s.id_software id_software
                      FROM software s, allergy a, software_institution si
                     WHERE a.id_allergy_parent = i_allergy_parent
                       AND si.id_software = s.id_software
                       AND s.flg_mni = pk_alert_constant.g_yes
                       AND a.flg_available = pk_alert_constant.g_yes
                       AND si.id_institution = i_institution
                       AND NOT EXISTS (SELECT 0
                              FROM allergy_inst_soft ais
                             WHERE ais.id_software IN (si.id_software, 0)
                               AND ais.id_allergy = a.id_allergy
                               AND ais.id_institution = si.id_institution)
                       AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL)
             GROUP BY id, name
             ORDER BY id, name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_g_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_ALLERGY',
                                   'GET_SEC_ALLERGIES_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_sec_allergies_list;

    /********************************************************************************************
    * Get Secondary Allergies Group Status List
    *
    * @param i_allergy_parent        Allergy Parent ID
    * @param i_institution           Institution ID
    * @param i_lang                  Prefered language ID
    * @param o_allergy               Allergy List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_allergy_all_flg_type
    (
        i_allergy_parent IN allergy.id_allergy%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_lang           IN LANGUAGE.id_language%TYPE,
        o_allergy        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_children_count NUMBER;
    BEGIN
        /* Counts the number of children allergies for the current parent allergy */
        g_error := 'Children count';
        SELECT COUNT(*) c
          INTO l_children_count
          FROM allergy a
         WHERE a.id_allergy_parent = i_allergy_parent
           AND a.flg_available = pk_alert_constant.g_yes
           AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL;
    
        IF l_children_count = 0
        THEN
            pk_types.open_my_cursor(o_allergy);
        ELSE
            g_error := 'OPEN CURSOR';
            OPEN o_allergy FOR
                SELECT id_software,
                       flg_type,
                       (SELECT pk_sysdomain.get_domain('BO_ALLERGY_INST_SOFT.FLG_TYPE', flg_type, i_lang)
                          FROM dual) flg_type_desc
                  FROM (SELECT s.id_software,
                               /* Chooses the state ('A', 'I' or 'A/I') based on the operation (number of active children/number of children) result */
                               decode((SELECT COUNT(*) c
                                         FROM allergy a, allergy_inst_soft ais
                                        WHERE a.id_allergy_parent = i_allergy_parent
                                          AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                                          AND ais.id_allergy = a.id_allergy
                                          AND a.flg_available = pk_alert_constant.g_yes
                                          AND ais.id_institution = i_institution
                                          AND ais.id_software IN (s.id_software, 0)) / l_children_count,
                                      0.0,
                                      'I',
                                      1.0,
                                      'A',
                                      'A/I') flg_type
                          FROM software s
                         WHERE EXISTS (SELECT 0
                                  FROM software_institution si
                                 WHERE si.id_software = s.id_software
                                   AND si.id_institution = i_institution)
                           AND s.flg_mni = pk_alert_constant.g_yes)
                 ORDER BY id_software;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_allergy);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_ALLERGY',
                                   'GET_ALLERGY_ALL_FLG_TYPE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_allergy_all_flg_type;

    /********************************************************************************************
    * Get Parent Allergy Description
    *
    * @param i_lang                  Prefered language ID
    * @param i_allergy_parent        Allergy Parent ID
    *
    *
    * @return                      allergy description
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_allergy_parent
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_allergy_parent IN allergy.id_allergy%TYPE
    ) RETURN VARCHAR2 IS
        l_allergy_parent VARCHAR(2000);
    BEGIN
        IF i_allergy_parent IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, a.code_allergy)
              INTO l_allergy_parent
              FROM allergy a
             WHERE a.id_allergy = i_allergy_parent
               AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL;
        END IF;
    
        RETURN l_allergy_parent;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_allergy_parent;

    /********************************************************************************************
    * Update an allergy status or a group of allergies statuses
    *
    *
    * @param i_allergy_parent        Allergy Parent ID
    * @param i_software        Software ID
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_allergy         Allergy ID
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2009/01/07
    ********************************************************************************************/
    FUNCTION set_sec_allergies_list
    (
        i_allergy_parent IN allergy.id_allergy%TYPE,
        i_software       IN software.id_software%TYPE,
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_val            IN sys_domain.val%TYPE,
        i_allergy        IN allergy.id_allergy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_soft_inst IS
            SELECT si.id_software
              FROM software_institution si, software s
             WHERE si.id_software = s.id_software
               AND si.id_software <> i_software
               AND si.id_institution = i_institution
               AND s.flg_mni = 'Y'
             ORDER BY 1;
    
        l_flg_ins NUMBER;
    
    BEGIN
    
        g_error := 'set_sec_allergies_list';
    
        IF i_allergy = -1
        THEN
            IF i_val = 'A'
            THEN
                /* Inserts a record for all the children allergies and correspondant parent that don't have any parametrization yet for the current institution and software */
                INSERT INTO allergy_inst_soft
                    (id_allergy, id_software, id_institution, rank, adw_last_update)
                    SELECT a.id_allergy, i_software id_software, i_institution id_institution, 0 rank, SYSDATE
                      FROM allergy a
                     WHERE NOT EXISTS (SELECT 0
                              FROM allergy_inst_soft ais
                             WHERE ais.id_allergy = a.id_allergy
                               AND ais.id_software IN (i_software, 0)
                               AND ais.id_institution = i_institution)
                       AND (a.id_allergy = i_allergy_parent OR a.id_allergy_parent = i_allergy_parent)
                       AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL;
            ELSIF i_val = 'I'
            THEN
                FOR w_soft_inst IN c_soft_inst
                LOOP
                    /* Inserts records for all the other softwares in the current institution */
                    INSERT INTO allergy_inst_soft
                        (id_allergy, id_software, id_institution, rank, adw_last_update)
                        SELECT a.id_allergy,
                               w_soft_inst.id_software id_software,
                               i_institution id_institution,
                               0 rank,
                               SYSDATE
                          FROM allergy a, allergy_inst_soft ais2
                         WHERE NOT EXISTS (SELECT 0
                                  FROM allergy_inst_soft ais
                                 WHERE ais.id_allergy = a.id_allergy
                                   AND ais.id_software = w_soft_inst.id_software
                                   AND ais.id_institution = i_institution)
                           AND (a.id_allergy = i_allergy_parent OR a.id_allergy_parent = i_allergy_parent)
                           AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                           AND ais2.id_allergy = a.id_allergy
                           AND ais2.id_software = 0
                           AND ais2.id_institution = i_institution;
                END LOOP;
            
                /* Delete all the records for the current software */
                DELETE FROM allergy_inst_soft ais
                 WHERE EXISTS (SELECT 0
                          FROM allergy a
                         WHERE pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                              
                           AND a.flg_available = pk_alert_constant.g_yes
                           AND ais.id_allergy = a.id_allergy)
                   AND ais.id_institution = i_institution
                   AND ais.id_software IN (i_software, 0)
                   AND ais.id_allergy IN
                       (SELECT a2.id_allergy
                          FROM allergy a2
                         WHERE (a2.id_allergy = i_allergy_parent OR a2.id_allergy_parent = i_allergy_parent)
                           AND a2.flg_available = pk_alert_constant.g_yes);
            END IF;
        ELSIF i_allergy IS NOT NULL
        THEN
            IF i_val = 'A'
            THEN
                /* Insert records for the allergies but check if there isn't already a 0 (zero) set */
                INSERT INTO allergy_inst_soft
                    (id_allergy, id_software, id_institution, rank, adw_last_update)
                    SELECT a.id_allergy, i_software id_software, i_institution id_institution, 0 rank, SYSDATE
                      FROM allergy a
                     WHERE NOT EXISTS (SELECT 0
                              FROM allergy_inst_soft ais
                             WHERE ais.id_allergy = a.id_allergy
                               AND ais.id_software = i_software
                               AND ais.id_institution = i_institution)
                       AND a.id_allergy_parent = i_allergy_parent
                       AND a.id_allergy = i_allergy
                       AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                    UNION ALL
                    SELECT a.id_allergy, i_software id_software, i_institution id_institution, 0 rank, SYSDATE
                      FROM allergy a
                     WHERE NOT EXISTS (SELECT 0
                              FROM allergy_inst_soft ais
                             WHERE ais.id_allergy = a.id_allergy
                               AND ais.id_software IN (i_software, 0)
                               AND ais.id_institution = i_institution)
                       AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                       AND a.id_allergy = i_allergy_parent;
            
            ELSIF i_val = 'I'
            THEN
                SELECT decode((SELECT 1
                                FROM dual
                               WHERE NOT EXISTS
                               (SELECT 0
                                        FROM allergy_inst_soft ais, allergy a
                                       WHERE a.id_allergy_parent = i_allergy_parent
                                         AND ais.id_allergy = a.id_allergy
                                         AND ais.id_software IN (i_software, 0)
                                         AND ais.id_institution = i_institution
                                         AND ais.id_allergy != i_allergy
                                         AND a.flg_available = pk_alert_constant.g_yes
                                         AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL)),
                              1,
                              1,
                              NULL,
                              0) flg
                  INTO l_flg_ins
                  FROM dual;
            
                /* Delete records for the allergies but check if there isn't already a 0 (zero) set */
                FOR w_soft_inst IN c_soft_inst
                LOOP
                    /* Inserir registos para os restantes softwares parametrizados na instituição seleccionada */
                    INSERT INTO allergy_inst_soft
                        (id_allergy, id_software, id_institution, rank, adw_last_update)
                        SELECT a.id_allergy,
                               w_soft_inst.id_software id_software,
                               i_institution id_institution,
                               0 rank,
                               SYSDATE
                          FROM allergy a, allergy_inst_soft ais2
                         WHERE NOT EXISTS (SELECT 0
                                  FROM allergy_inst_soft ais
                                 WHERE ais.id_allergy = a.id_allergy
                                   AND ais.id_software = w_soft_inst.id_software
                                   AND ais.id_institution = i_institution)
                           AND a.id_allergy = i_allergy
                           AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                           AND ais2.id_allergy = a.id_allergy
                           AND ais2.id_software = 0
                           AND ais2.id_institution = i_institution
                        UNION ALL
                        SELECT a.id_allergy,
                               w_soft_inst.id_software id_software,
                               i_institution id_institution,
                               0 rank,
                               SYSDATE
                          FROM allergy a
                         WHERE a.id_allergy = i_allergy_parent
                           AND l_flg_ins = 1
                           AND NOT EXISTS
                         (SELECT 0
                                  FROM allergy_inst_soft ais
                                 WHERE ais.id_allergy = a.id_allergy
                                   AND ais.id_software = w_soft_inst.id_software
                                   AND ais.id_institution = i_institution)
                           AND pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL;
                END LOOP;
            
                /* Delete all the records for the current software */
                DELETE FROM allergy_inst_soft ais
                 WHERE ais.id_institution = i_institution
                   AND ais.id_software IN (i_software, 0)
                   AND ais.id_allergy = i_allergy
                   AND pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || ais.id_allergy) IS NOT NULL;
            
                DELETE FROM allergy_inst_soft ais
                 WHERE NOT EXISTS
                 (SELECT 0
                          FROM allergy_inst_soft ais2, allergy a2
                         WHERE a2.id_allergy_parent = i_allergy_parent
                           AND ais2.id_allergy = a2.id_allergy
                           AND ais2.id_software IN (i_software, 0)
                           AND a2.flg_available = pk_alert_constant.g_yes
                           AND ais2.id_institution = i_institution
                           AND ais2.id_allergy != i_allergy
                           AND pk_translation.get_translation(i_lang, a2.code_allergy) IS NOT NULL)
                   AND ais.id_allergy = i_allergy_parent
                   AND ais.id_institution = i_institution
                   AND ais.id_software IN (i_software, 0)
                   AND pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || ais.id_allergy) IS NOT NULL;
            ELSE
                RETURN FALSE;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_ALLERGY',
                                   'SET_SEC_ALLERGIES_LIST');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END set_sec_allergies_list;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_backoffice_allergy;
/
