/*-- Last Change Revision: $Rev: 2026784 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_hidrics IS
    g_num_records CONSTANT NUMBER(24) := 50;
    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        TÈrcio Soares
    * @since                         2010/06/04
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER IS
    BEGIN
        RETURN g_num_records;
    END get_num_records;
    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_pesq_list      List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/02/05
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET INST_HIDRICS_LIST CURSOR';
        OPEN o_inst_pesq_list FOR
            SELECT id, name, values_desc, id_hidrics_type
              FROM (SELECT h.id_hidrics id,
                           pk_translation.get_translation(i_lang, h.code_hidrics) || ' (' ||
                           pk_translation.get_translation(i_lang, ht.code_hidrics_type) || ')' name,
                           get_inst_hidrics_list_state(i_lang,
                                                       i_id_institution,
                                                       i_software,
                                                       h.id_hidrics,
                                                       ht.id_hidrics_type) values_desc,
                           ht.id_hidrics_type
                      FROM hidrics h, hidrics_type ht
                     WHERE ht.flg_available = pk_alert_constant.g_available
                       AND pk_translation.get_translation(i_lang, h.code_hidrics) IS NOT NULL
                     ORDER BY id, flg_type)
             WHERE name IS NOT NULL
             GROUP BY id, name, id_hidrics_type
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_HIDRICS',
                                              'GET_INST_HIDRICS_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_inst_pesq_list);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_hidrics_list;

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
    * @author                      JTS
    * @version                     1.0
    * @since                       2009/02/05
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
               AND flg_available = pk_alert_constant.g_available
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
                                              'PK_BACKOFFICE_HIDRICS',
                                              'GET_STATE_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_list);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_state_list;

    /********************************************************************************************
    * Set Hidric state in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_software        Software ID
    * @param i_id_hidrics      Hidric ID
    * @param i_state           New hidric state
    * @param i_id_hidrics_type Hidric Type ID
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 1.0
    * @since                   2009/02/06
    ********************************************************************************************/
    FUNCTION set_inst_soft_hidric_state
    (
        i_lang            IN language.id_language%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        i_software        IN software.id_software%TYPE,
        i_id_hidrics      IN hidrics.id_hidrics%TYPE,
        i_state           IN VARCHAR2,
        i_id_hidrics_type IN hidrics_type.id_hidrics_type%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_state    VARCHAR2(1);
        l_count_ht NUMBER;
    
        l_id_hidrics_relation hidrics_relation.id_hidrics_relation%TYPE;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
    
        SELECT decode(i_state, pk_alert_constant.g_active, pk_alert_constant.g_yes, pk_alert_constant.g_no)
          INTO l_state
          FROM dual;
    
        SELECT COUNT(hr.id_hidrics_relation)
          INTO l_count_ht
          FROM hidrics_relation hr
         WHERE hr.id_hidrics = i_id_hidrics
           AND hr.id_software = i_software
           AND hr.id_institution = i_institution
           AND hr.id_hidrics_type = i_id_hidrics_type;
    
        IF l_count_ht = 0
        THEN
            g_error := 'INSERT INTO HIDRICS_RELATION';
            /*INSERT INTO hidrics_relation
                (id_hidrics_relation,
                 id_hidrics_type,
                 id_hidrics,
                 flg_state,
                 flg_available,
                 adw_last_update,
                 id_software,
                 id_institution)
            VALUES
                (seq_hidrics_relation.NEXTVAL,
                 i_id_hidrics_type,
                 i_id_hidrics,
                 i_state,
                 l_state,
                 SYSDATE,
                 i_software,
                 i_institution);*/
            --Sofia Mendes (18-11-2009)
            l_id_hidrics_relation := ts_hidrics_relation.next_key;
        
            g_error := 'CALL TS_HIDRICS_RELATION.INS WITH ID_HIDRICS_RELATION ' || l_id_hidrics_relation;
            pk_alertlog.log_debug(g_error);
            ts_hidrics_relation.ins(id_hidrics_relation_in => l_id_hidrics_relation,
                                    id_hidrics_type_in     => i_id_hidrics_type,
                                    id_hidrics_in          => i_id_hidrics,
                                    flg_state_in           => i_state,
                                    flg_available_in       => l_state,
                                    id_software_in         => i_software,
                                    id_institution_in      => i_institution,
                                    rows_out               => l_rows);
        
            g_error := 'PROCESS INSERT WITH ID_HIDRICS_RELATION ' || l_id_hidrics_relation;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, NULL, 'HIDRICS_RELATION', l_rows, o_error);
            --
        ELSE
        
            /*g_error := 'UPDATE HIDRICS_RELATION';
            UPDATE hidrics_relation hr
               SET hr.flg_state = i_state, hr.flg_available = pk_alert_constant.g_available
             WHERE hr.id_hidrics = i_id_hidrics
               AND hr.id_software = i_software
               AND hr.id_institution = i_institution
               AND hr.id_hidrics_type = i_id_hidrics_type;*/
        
            --Sofia Mendes (18-11-2009)
            l_rows  := table_varchar();
            g_error := 'CALL TS_HIDRICS_RELATION.INS WITH ID_HIDRICS ' || i_id_hidrics;
            pk_alertlog.log_debug(g_error);
            ts_hidrics_relation.upd(flg_state_in     => i_state,
                                    flg_available_in => pk_alert_constant.g_available,
                                    where_in         => 'id_hidrics = ' || i_id_hidrics || ' AND id_software = ' ||
                                                        i_software || ' AND id_institution = ' || i_institution ||
                                                        ' AND id_hidrics_type = ' || i_id_hidrics_type,
                                    rows_out         => l_rows);
        
            g_error := 'PROCESS UPDATE WITH ID_HIDRICS ' || i_id_hidrics;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang,
                                          NULL,
                                          'HIDRICS_RELATION',
                                          l_rows,
                                          o_error,
                                          i_list_columns => table_varchar('FLG_STATE', 'FLG_AVAILABLE'));
            --
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
                                              'PK_BACKOFFICE_HIDRICS',
                                              'SET_INST_SOFT_HIDRIC_STATE',
                                              o_error);
        
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_inst_soft_hidric_state;

    /********************************************************************************************
    * Get the states of hidric in the institution for all software
    *
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_software        Software ID
    * @param i_id              Hidric ID
    * @param i_hidric_type     New hidric state
    *
    *
    * @return                  table_varchar with results
    *
    * @author                  RMGM
    * @version                 2.0
    * @since                   2011/07/07
    ********************************************************************************************/

    FUNCTION get_inst_hidrics_list_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_id             IN hidrics.id_hidrics%TYPE,
        i_hidric_type    IN hidrics_type.id_hidrics_type%TYPE
    ) RETURN table_varchar IS
    
        l_active VARCHAR2(200);
        l_data   table_varchar := table_varchar();
        l_error  t_error_out;
    
    BEGIN
    
        l_active := pk_sysdomain.get_domain('HIDRICS_RELATION.FLG_STATE', 'A', i_lang);
    
        g_error := 'GET INST_HIDRICS_LIST CURSOR';
        SELECT t.column_value || ',' || pk_alert_constant.g_active || ',' || l_active BULK COLLECT
          INTO l_data
          FROM hidrics h
         INNER JOIN hidrics_relation hr
            ON (hr.id_hidrics = h.id_hidrics)
         INNER JOIN (SELECT column_value
                       FROM TABLE(CAST(i_software AS table_number))) t
            ON (t.column_value = hr.id_software)
         WHERE hr.id_institution = i_id_institution
           AND h.id_hidrics = i_id
           AND hr.flg_state = pk_alert_constant.g_active
           AND nvl(hr.id_department, -1) = -1 -- new hidrics functionality doesnt support backoffice yet
           AND nvl(hr.id_dept, -1) = -1
           AND h.flg_available = pk_alert_constant.g_yes
           AND hr.id_hidrics_type = i_hidric_type;
    
        RETURN l_data;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_BACKOFFICE_HIDRICS',
                                              i_function => 'GET_INST_HIDRICS_LIST_STATE',
                                              o_error    => l_error);
            RETURN l_data;
        
    END get_inst_hidrics_list_state;
    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_search              search string filter   
    * @param o_count               List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/07/06
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_search         IN VARCHAR2,
        o_count          OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_search VARCHAR2(4000) := '%' ||
                                   translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'), '_', '\_')),
                                             '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                             'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
    BEGIN
    
        IF l_search IS NOT NULL
        THEN
            SELECT COUNT(*)
              INTO o_count
              FROM (SELECT *
                      FROM (SELECT h.id_hidrics id,
                                   pk_translation.get_translation(i_lang, h.code_hidrics) || ' (' ||
                                   pk_translation.get_translation(i_lang, ht.code_hidrics_type) || ')' name,
                                   ht.id_hidrics_type
                              FROM hidrics h, hidrics_type ht
                             WHERE ht.flg_available = pk_alert_constant.g_available
                               AND pk_translation.get_translation(i_lang, h.code_hidrics) IS NOT NULL
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
                       AND translate(upper(name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           l_search ESCAPE '\'
                     ORDER BY name) res;
        ELSE
            SELECT COUNT(*)
              INTO o_count
              FROM (SELECT *
                      FROM (SELECT h.id_hidrics id,
                                   pk_translation.get_translation(i_lang, h.code_hidrics) || ' (' ||
                                   pk_translation.get_translation(i_lang, ht.code_hidrics_type) || ')' name,
                                   ht.id_hidrics_type
                              FROM hidrics h, hidrics_type ht
                             WHERE ht.flg_available = pk_alert_constant.g_available
                               AND pk_translation.get_translation(i_lang, h.code_hidrics) IS NOT NULL
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
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
                                              'PK_BACKOFFICE_HIDRICS',
                                              'GET_INST_HIDRICS_COUNT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_inst_hidrics_count;
    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_search              search string filter   
    * @param i_start_record          start record
    * @param i_num_records           number of records to show   
    * @param o_count               List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/07/06
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hid_data t_table_hidrics;
        l_search   VARCHAR2(4000) := '%' || translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'),
                                                                    '_',
                                                                    '\_')),
                                                      '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ',
                                                      'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
    BEGIN
    
        IF l_search IS NOT NULL
        THEN
            SELECT t_rec_hidrics(id, name, values_desc, id_hidrics_type) BULK COLLECT
              INTO l_hid_data
              FROM (SELECT id, name, values_desc, id_hidrics_type
                      FROM (SELECT h.id_hidrics id,
                                   pk_translation.get_translation(i_lang, h.code_hidrics) || ' (' ||
                                   pk_translation.get_translation(i_lang, ht.code_hidrics_type) || ')' name,
                                   pk_backoffice_hidrics.get_inst_hidrics_list_state(i_lang,
                                                                                     i_id_institution,
                                                                                     i_software,
                                                                                     h.id_hidrics,
                                                                                     ht.id_hidrics_type) values_desc,
                                   ht.id_hidrics_type
                              FROM hidrics h, hidrics_type ht
                             WHERE ht.flg_available = pk_alert_constant.g_available
                               AND pk_translation.get_translation(i_lang, h.code_hidrics) IS NOT NULL
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
                       AND translate(upper(name), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹—› ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           l_search ESCAPE '\'
                     ORDER BY name) res;
        ELSE
            SELECT t_rec_hidrics(id, name, values_desc, id_hidrics_type) BULK COLLECT
              INTO l_hid_data
              FROM (SELECT id, name, values_desc, id_hidrics_type
                      FROM (SELECT h.id_hidrics id,
                                   pk_translation.get_translation(i_lang, h.code_hidrics) || ' (' ||
                                   pk_translation.get_translation(i_lang, ht.code_hidrics_type) || ')' name,
                                   pk_backoffice_hidrics.get_inst_hidrics_list_state(i_lang,
                                                                                     i_id_institution,
                                                                                     i_software,
                                                                                     h.id_hidrics,
                                                                                     ht.id_hidrics_type) values_desc,
                                   ht.id_hidrics_type
                              FROM hidrics h, software s, hidrics_type ht
                             WHERE ht.flg_available = pk_alert_constant.g_available
                               AND pk_translation.get_translation(i_lang, h.code_hidrics) IS NOT NULL
                             ORDER BY id, flg_type)
                     WHERE name IS NOT NULL
                     ORDER BY name) res;
        END IF;
        g_error := 'GET INST_HIDRICS_DATA CURSOR';
        OPEN o_inst_pesq_list FOR
            SELECT hids.id, hids.name, hids.values_desc, hids.id_hidrics_type
              FROM (SELECT rownum rn, t.*
                      FROM TABLE(CAST(l_hid_data AS t_table_hidrics)) t) hids
             WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_HIDRICS',
                                              'GET_INST_HIDRICS_DATA',
                                              o_error);
        
            pk_types.open_my_cursor(o_inst_pesq_list);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_inst_hidrics_data;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_hidrics;
/
