/*-- Last Change Revision: $Rev: 2026808 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_vacc IS

    g_num_records CONSTANT NUMBER(24) := 50;

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        RMGM
    * @since                         2011/06/28
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER IS
    BEGIN
        RETURN g_num_records;
    END get_num_records;
    /********************************************************************************************
    * Get State List
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List od states
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/12/05
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET LIST CURSOR';
        OPEN o_list FOR
        
            SELECT val, desc_val, img_name icon
              FROM sys_domain
             WHERE code_domain = i_code_domain
               AND flg_available = pk_alert_constant.g_yes
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_STATE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_state_list;

    /********************************************************************************************
    * Set Analysis Types in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_software        Software ID
    * @param i_group           Vaccine Group ID
    * @param i_flg_type        Operation to perform on database
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  BM
    * @version                 1.0
    * @since                   2008/11/21
    ********************************************************************************************/
    FUNCTION set_group_state
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_group       IN NUMBER,
        i_flg_type    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_vacc_type_group_soft_inst vacc_type_group_soft_inst.id_vacc_type_group_soft_inst%TYPE;
    
    BEGIN
    
        IF i_flg_type = pk_alert_constant.g_inactive
        THEN
        
            DELETE FROM vacc_type_group_soft_inst v
             WHERE v.id_vacc_type_group = i_group
               AND v.id_institution = i_institution
               AND v.id_software = i_software;
        
        ELSE
        
            g_error := 'GET SEQ_VACC_GROUP_SOFT_INST.NEXTVAL';
            SELECT seq_vacc_type_group_soft_inst.nextval
              INTO l_vacc_type_group_soft_inst
              FROM dual;
        
            g_error := 'INSERT INTO VACC_GROUP_SOFT_INST';
            INSERT INTO vacc_type_group_soft_inst
                (id_vacc_type_group_soft_inst, id_vacc_type_group, id_institution, id_software)
            VALUES
                (l_vacc_type_group_soft_inst, i_group, i_institution, i_software);
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'SET_GROUP_STATE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_group_state;

    /********************************************************************************************
    * Get (Vaccine) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software_t            Table of Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param o_inst_pesq_list        Vaccine Group List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_group_list
    (
        i_lang           IN language.id_language%TYPE,
        i_institution    IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software_t     IN table_number,
        i_context        IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_active   VARCHAR2(200);
        l_inactive VARCHAR2(200);
    BEGIN
    
        l_active := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'A', i_lang);
    
        l_inactive := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'I', i_lang);
    
        g_error := 'GET GROUP_LIST CURSOR';
        OPEN o_inst_pesq_list FOR
            SELECT id,
                   name_aux,
                   name,
                   CAST(COLLECT(to_char(id_software) || ',' || flg_type || ',' || type_desc) AS table_varchar) values_desc
              FROM (SELECT ais.id_vacc_type_group id,
                           pk_translation.get_translation(i_lang, a.code_vacc_type_group) name_aux,
                           pk_translation.get_translation(i_lang, a.code_vacc_type_group) name,
                           l_active type_desc,
                           pk_alert_constant.g_active flg_type,
                           ais.id_software
                      FROM vacc_type_group_soft_inst ais, vacc_type_group a
                     WHERE ais.id_institution = i_institution
                       AND ais.id_vacc_type_group = a.id_vacc_type_group
                       AND ais.id_software IN (SELECT column_value
                                                 FROM TABLE(CAST(i_software_t AS table_number)))
                    UNION
                    SELECT a.id_vacc_type_group id,
                           pk_translation.get_translation(i_lang, a.code_vacc_type_group) name_aux,
                           pk_translation.get_translation(i_lang, a.code_vacc_type_group) name,
                           l_inactive,
                           pk_alert_constant.g_inactive flg_type,
                           s.id_software
                      FROM software s, vacc_type_group a
                     WHERE s.id_software NOT IN
                           (SELECT DISTINCT ais.id_software
                              FROM vacc_type_group_soft_inst ais
                             WHERE ais.id_institution = i_institution
                               AND ais.id_vacc_type_group = a.id_vacc_type_group
                               AND ais.id_software IN
                                   (SELECT column_value
                                      FROM TABLE(CAST(i_software_t AS table_number))))
                       AND s.id_software IN (SELECT column_value
                                               FROM TABLE(CAST(i_software_t AS table_number)))
                     ORDER BY id, id_software, flg_type)
             WHERE name_aux IS NOT NULL
             GROUP BY id, name_aux, name
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_GROUP_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_inst_pesq_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_group_list;

    /********************************************************************************************
    * Get (Vaccine) Group Type List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param o_gt_list               Vaccine Group Type List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_group_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN vacc_type_group_soft_inst.id_institution%TYPE,
        o_gt_list     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET GROUP_TYPE_LIST CURSOR';
        OPEN o_gt_list FOR
            SELECT vg.id_vacc_type_group, pk_translation.get_translation(i_lang, vg.code_vacc_type_group) name
              FROM vacc_type_group vg
             WHERE id_vacc_type_group IN (SELECT id_vacc_type_group
                                            FROM vacc_type_group_soft_inst vs
                                           WHERE vs.id_institution = g_all
                                              OR vs.id_institution = i_institution)
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_GROUP_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_group_type_list;

    /********************************************************************************************
    * Get Vaccine List
    *
    * @param i_lang                  Prefered language ID
    * @param i_group                 Group Id
    * @param o_vacc_list             Vaccine List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_list
    (
        i_lang      IN language.id_language%TYPE,
        i_group     IN vacc_type_group.id_vacc_type_group%TYPE,
        o_vacc_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET VACC_LIST CURSOR';
        OPEN o_vacc_list FOR
            SELECT pk_translation.get_translation(i_lang, v.code_desc_vacc) name, v.id_vacc
              FROM vacc v
              JOIN vacc_group vg
                ON v.id_vacc = vg.id_vacc
             WHERE vg.id_vacc_type_group = i_group
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacc_list;

    /********************************************************************************************
    * Get Vaccine Details
    *
    * @param i_prof                  Object Profissional (professional ID, institution ID, software ID)
    * @param i_lang                  Prefered language ID
    * @param i_vacc                  Vaccine Id
    * @param o_vacc_details          Vaccine Details
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_details
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE,
        o_vacc_details OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET VACC_DETAILS CURSOR';
        OPEN o_vacc_details FOR
            SELECT vg.id_vacc_group,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) vacc_desc,
                   pk_translation.get_translation(i_lang, v.code_vacc) vacc_code,
                   pk_translation.get_translation(i_lang, vtg.code_vacc_type_group) vacc_group
              FROM vacc v
              LEFT JOIN vacc_group vg
                ON v.id_vacc = vg.id_vacc
              LEFT JOIN vacc_type_group vtg
                ON vg.id_vacc_type_group = vtg.id_vacc_type_group
             WHERE v.id_vacc = i_vacc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_DETAILS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacc_details;

    /********************************************************************************************
    * Get Vaccine CI 
    *
    * @param i_lang                  Prefered language ID
    * @param i_vacc                  Vaccine Id
    * @param o_vacc_ci               CI
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_ci
    (
        i_lang    IN language.id_language%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE,
        o_vacc_ci OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET VACC_CI CURSOR';
        OPEN o_vacc_ci FOR
            SELECT nvl((SELECT v.contra_indic
                         FROM vacc_info v
                        WHERE v.id_vacc = i_vacc
                          AND v.id_language = i_lang),
                       pk_message.get_message(i_lang, 'ADMINISTRATOR_T224')) contra_indic
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_CI',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacc_ci;

    /********************************************************************************************
    * Get Vaccine Doses 
    *
    * @param i_lang                  Prefered language ID
    * @param i_vacc                  Vaccine Id
    * @param o_vacc_dose             Doses
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_dose
    (
        i_lang      IN language.id_language%TYPE,
        i_vacc      IN vacc.id_vacc%TYPE,
        o_vacc_dose OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET VACC_CI CURSOR';
        OPEN o_vacc_dose FOR
            SELECT vd.id_vacc, CAST(COLLECT(t.desc_time) AS table_varchar) AS contraindications
              FROM vacc_dose vd
              JOIN TIME t
                ON vd.id_time = t.id_time
             WHERE vd.id_vacc = i_vacc
             GROUP BY vd.id_vacc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_DOSE',
                                              o_error);
            pk_types.open_my_cursor(o_vacc_dose);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacc_dose;

    /********************************************************************************************
    * Get Vacc Type Group state
    * Internal usage only!
    ********************************************************************************************/
    FUNCTION get_vacc_type_group_state
    (
        i_lang        IN language.id_language%TYPE,
        i_group       IN vacc_type_group_soft_inst.id_vacc_type_group%TYPE,
        i_institution IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software    IN vacc_type_group_soft_inst.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_inactive  VARCHAR2(200);
        l_active    VARCHAR2(200);
        dummynbr    NUMBER(1);
        l_error_out t_error_out;
    
    BEGIN
    
        l_active := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'A', i_lang);
    
        l_inactive := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'I', i_lang);
    
        SELECT 1
          INTO dummynbr
          FROM vacc_type_group_soft_inst v
         WHERE v.id_vacc_type_group = i_group
           AND (v.id_institution = i_institution OR v.id_institution = g_all)
           AND (v.id_software = i_software OR v.id_software = g_all);
    
        RETURN l_active;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_TYPE_GROUP_STATE',
                                              l_error_out);
            RETURN l_inactive;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_TYPE_GROUP_STATE',
                                              l_error_out);
            RETURN l_inactive;
    END get_vacc_type_group_state;
    /********************************************************************************************
    * Get (Vaccine) Group List state
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software              array of Software
    * @param i_vacc_tg               Vacinnes type group
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.2
    * @since                       2011/07/07
    ********************************************************************************************/
    FUNCTION get_group_list_state
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software_t  IN table_number,
        i_vacc_tg     IN vacc_type_group.id_vacc_type_group%TYPE
    ) RETURN table_varchar IS
        l_active VARCHAR2(4000);
        l_data   table_varchar := table_varchar();
        l_error  t_error_out;
    
    BEGIN
    
        l_active := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'A', i_lang);
    
        g_error := 'GET STATE';
        -- changed to table_varchar to get best performance in main query
        SELECT t.column_value || ',' || pk_alert_constant.g_active || ',' || l_active
          BULK COLLECT
          INTO l_data
          FROM vacc_type_group_soft_inst ais
         INNER JOIN (SELECT column_value
                       FROM TABLE(CAST(i_software_t AS table_number))) t
            ON (t.column_value = ais.id_software)
         WHERE ais.id_institution = i_institution
           AND ais.id_vacc_type_group = i_vacc_tg;
    
        RETURN l_data;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_GROUP_LIST_STATE',
                                              l_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN l_data;
        
    END get_group_list_state;
    /********************************************************************************************
    * Get (Vaccine) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software_t            Table of Software ID's
    * @param i_search                Search filter
    * @param o_count                 number of total records
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     1.0
    * @since                       2011/07/07
    ********************************************************************************************/
    FUNCTION get_vacc_group_count
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software_t  IN table_number,
        i_search      IN VARCHAR2,
        o_count       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_active VARCHAR2(200);
        l_search VARCHAR2(4000) := '%' ||
                                   translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'), '_', '\_')),
                                             '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                             'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
    
    BEGIN
    
        l_active := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'A', i_lang);
        IF i_search IS NULL
        THEN
            g_error := 'NUMBER OF RECORDS COLECTION';
            SELECT COUNT(*)
              INTO o_count
              FROM (SELECT id, name
                      FROM (SELECT a.id_vacc_type_group id,
                                   pk_translation.get_translation(i_lang, a.code_vacc_type_group) name
                              FROM vacc_type_group a
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
                     ORDER BY name) res;
        ELSE
            SELECT COUNT(*)
              INTO o_count
              FROM (SELECT id, name
                      FROM (SELECT a.id_vacc_type_group id,
                                   pk_translation.get_translation(i_lang, a.code_vacc_type_group) name
                              FROM vacc_type_group a
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
                       AND translate(upper(name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           l_search ESCAPE '\'
                     ORDER BY name) res;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_GROUP_COUNT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacc_group_count;
    /********************************************************************************************
    * Get (Vaccine) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software_t            Table of Software ID's
    * @param i_search                Search filter
    * @param i_start_record          start record
    * @param i_num_records           number of records to show   
    * @param o_inst_pesq_list        total records info
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     1.0
    * @since                       2011/07/07
    ********************************************************************************************/
    FUNCTION get_vacc_group_data
    (
        i_lang           IN language.id_language%TYPE,
        i_institution    IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software_t     IN table_number,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_active VARCHAR2(200);
    
        l_vacc_data t_table_vacc;
        l_search    VARCHAR2(4000) := '%' || translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'),
                                                                     '_',
                                                                     '\_')),
                                                       '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                                       'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
    
    BEGIN
    
        l_active := pk_sysdomain.get_domain('VACC_TYPE_GROUP_SOFT_INST.FLG_TYPE', 'A', i_lang);
        IF i_search IS NULL
        THEN
            g_error := 'NUMBER OF RECORDS COLECTION';
            SELECT t_rec_vacc(id, name, values_desc)
              BULK COLLECT
              INTO l_vacc_data
              FROM (SELECT id, name, values_desc
                      FROM (SELECT a.id_vacc_type_group id,
                                   pk_translation.get_translation(i_lang, a.code_vacc_type_group) name,
                                   pk_backoffice_vacc.get_group_list_state(i_lang,
                                                                           i_institution,
                                                                           i_software_t,
                                                                           a.id_vacc_type_group) values_desc
                              FROM vacc_type_group a
                             ORDER BY id, a.flg_type)
                     WHERE name IS NOT NULL
                     ORDER BY name) res;
        ELSE
            g_error := 'NUMBER OF RECORDS SEARCHED';
            SELECT t_rec_vacc(id, name, values_desc)
              BULK COLLECT
              INTO l_vacc_data
              FROM (SELECT id, name, values_desc
                      FROM (SELECT a.id_vacc_type_group id,
                                   pk_translation.get_translation(i_lang, a.code_vacc_type_group) name,
                                   pk_backoffice_vacc.get_group_list_state(i_lang,
                                                                           i_institution,
                                                                           i_software_t,
                                                                           a.id_vacc_type_group) values_desc
                              FROM vacc_type_group a
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
                       AND translate(upper(name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           l_search ESCAPE '\'
                     ORDER BY name) res;
        END IF;
    
        g_error := 'GET INST_HIDRICS_DATA CURSOR';
        OPEN o_inst_pesq_list FOR
            SELECT vacc.id, vacc.name, vacc.values_desc
              FROM (SELECT rownum rn, t.*
                      FROM TABLE(CAST(l_vacc_data AS t_table_vacc)) t) vacc
             WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_VACC',
                                              'GET_VACC_GROUP_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_inst_pesq_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vacc_group_data;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_vacc;
/
