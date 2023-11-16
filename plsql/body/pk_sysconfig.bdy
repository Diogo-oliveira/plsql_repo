/*-- Last Change Revision: $Rev: 2027775 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sysconfig IS

    /* Stores the package name. */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(30);
    g_num_records CONSTANT NUMBER(24) := 50;

    g_default_impact_msg CONSTANT sys_message.code_message%TYPE := 'ADMINISTRATOR_T172';

    k_accent_y CONSTANT VARCHAR2(0100 CHAR) := 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑÝ ';
    k_accent_n CONSTANT VARCHAR2(0100 CHAR) := 'AEIOUAEIOUAEIOUAOCAEIOUNY%';

    --g_available_y CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_available_n CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_client_config   CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_global_config   CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_internal_config CONSTANT VARCHAR2(1 CHAR) := 'I';
    /*
    Method to get desc of value set in sys_config
    */
    FUNCTION get_desc_val_cmf
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_val_sys_config IN sys_config.value%TYPE,
        i_id_software    IN sys_config.id_software%TYPE,
        i_fill_type      IN sys_config.fill_type%TYPE,
        i_mvalue         IN sys_config.mvalue%TYPE
    ) RETURN VARCHAR2 IS
        l_error     t_error_out;
        l_tb_res    table_varchar := table_varchar();
        o_desc_cfg  VARCHAR2(1000) := '';
        l_func_name VARCHAR2(30) := 'GET_DESC_VAL';
        l_scf_vals  VARCHAR2(1000) := '';
    BEGIN
        IF i_fill_type = 'M'
        THEN
            -- get typed contents to table
            EXECUTE IMMEDIATE 'SELECT t_res.desc_val              
              FROM table(' || i_mvalue || ') t_res
             WHERE t_res.val = ''' || i_val_sys_config || ''''
                INTO o_desc_cfg
                USING i_lang, i_id_institution, i_id_software;
        ELSE
            l_scf_vals := REPLACE(i_val_sys_config, '|', ''',''');
        
            EXECUTE IMMEDIATE 'SELECT t_res.desc_val              
             FROM table(' || i_mvalue ||
                              ') t_res
            WHERE t_res.val in (select column_value from table(table_varchar(''' ||
                              l_scf_vals || ''') )tbl)' BULK COLLECT
                INTO l_tb_res
                USING i_lang, i_id_institution, i_id_software;
        
            o_desc_cfg := pk_utils.concat_table(l_tb_res, '; ');
        END IF;
        -- return desc_val
        RETURN o_desc_cfg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_desc_val_cmf;

    FUNCTION get_desc_val
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_val_sys_config IN sys_config.value%TYPE,
        i_id_software    IN sys_config.id_software%TYPE,
        i_fill_type      IN sys_config.fill_type%TYPE,
        i_mvalue         IN sys_config.mvalue%TYPE
    ) RETURN VARCHAR2 IS
        l_error     t_error_out;
        l_func_name VARCHAR2(30 CHAR) := 'GET_DESC_VAL';
        o_desc_cfg  VARCHAR2(1000) := '';
        l_sql       VARCHAR2(4000);
    
        -- *********************************************************
        FUNCTION prepare_sql RETURN VARCHAR2 IS
            l_text     VARCHAR2(4000);
            l_sql      VARCHAR2(4000);
            l_add      VARCHAR2(4000);
            l_scf_vals VARCHAR2(1000 CHAR);
        
        BEGIN
        
            l_text := 'SELECT t_res.desc_val FROM table(' || i_mvalue || ') t_res WHERE t_res.val';
        
            IF i_fill_type = 'M'
            THEN
            
                l_sql := l_text;
                l_add := ' = ''' || i_val_sys_config || '''';
                l_sql := l_sql || l_add;
            
            ELSIF i_fill_type = 'F'
            THEN
                l_sql      := l_text;
                l_scf_vals := REPLACE(i_val_sys_config, '|', ''',''');
                l_add      := ' in (select column_value from table(table_varchar(''' || l_scf_vals || ''') )tbl)';
                l_sql      := l_sql || l_add;
            ELSE
            
                l_sql := NULL;
            
            END IF;
        
            RETURN l_sql;
        
        END prepare_sql;
    
        --*********************************************
        FUNCTION process_sql(i_sql IN VARCHAR2) RETURN VARCHAR2 IS
            l_tb_res table_varchar;
            l_return VARCHAR2(4000);
        BEGIN
        
            EXECUTE IMMEDIATE i_sql BULK COLLECT
                INTO l_tb_res
                USING i_lang, i_id_institution, i_id_software;
        
            IF l_tb_res.count = 0
            THEN
                l_return := NULL;
            ELSIF l_tb_res.count > 1
            THEN
                l_return := pk_utils.concat_table(l_tb_res, '; ');
            ELSE
                l_return := l_tb_res(1);
            END IF;
        
            RETURN l_return;
        
        END process_sql;
    
    BEGIN
    
        l_sql      := prepare_sql();
        o_desc_cfg := process_sql(i_sql => l_sql);
    
        RETURN o_desc_cfg;
    
    END get_desc_val;

    FUNCTION get_config
    (
        i_code_cf IN table_varchar,
        i_prof    IN profissional,
        o_msg_cf  OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL GET_CONFIG 2';
        RETURN get_config(i_code_cf, i_prof.institution, i_prof.software, o_msg_cf);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_msg_cf);
            RETURN pk_alert_exceptions.error_handling('GET_CONFIG 1', 'PK_SYSCONFIG', g_error, SQLERRM);
    END;
    ---

    FUNCTION get_config
    (
        i_code_cf IN sys_config.id_sys_config%TYPE,
        i_prof    IN profissional,
        o_msg_cf  OUT sys_config.value%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'CALL GET_CONFIG 6';
        o_msg_cf := get_config(i_code_cf, i_prof.institution, i_prof.software);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.error_handling('GET_CONFIG 3', 'PK_SYSCONFIG', g_error, SQLERRM);
    END get_config;

    ----

    FUNCTION get_config
    (
        i_code_cf IN sys_config.id_sys_config%TYPE,
        i_prof    IN profissional
    ) RETURN sys_config.value%TYPE IS
    BEGIN
        g_error := 'CALL GET_CONFIG 6';
        RETURN get_config(i_code_cf, i_prof.institution, i_prof.software);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling('GET_CONFIG 5', 'PK_SYSCONFIG', g_error, SQLERRM);
            RETURN NULL;
    END;

    FUNCTION get_config
    (
        i_code_cf   IN sys_config.id_sys_config%TYPE,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE
    ) RETURN sys_config.value%TYPE result_cache relies_on(sys_config) IS
    
        l_config    sys_config.value%TYPE;
        l_id_market market.id_market%TYPE;
    BEGIN
    
        g_error     := 'GET_INST_MKT';
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof_inst);
    
        BEGIN
            g_error := 'get config vals';
            SELECT decode(flg_schema,
                          'F',
                          (SELECT VALUE
                             FROM finger_db.sys_config fsc
                            WHERE fsc.id_sys_config = i_code_cf),
                          VALUE) VALUE
              INTO l_config
              FROM (SELECT VALUE,
                           flg_schema,
                           row_number() over(PARTITION BY id_sys_config ORDER BY id_institution DESC, id_software DESC, id_market DESC) rn
                      FROM sys_config
                     WHERE id_sys_config = i_code_cf
                       AND id_institution IN (i_prof_inst, 0)
                       AND id_market IN (l_id_market, 0)
                       AND id_software IN (i_prof_soft, 0))
             WHERE rn = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_config := NULL;
        END;
    
        RETURN l_config;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling('GET_CONFIG 6', 'PK_SYSCONFIG', g_error, SQLERRM);
            RETURN NULL;
    END;

    FUNCTION get_config
    (
        i_code_cf   IN sys_config.id_sys_config%TYPE,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT sys_config.value%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'CALL GET_CONFIG 2';
        o_msg_cf := get_config(i_code_cf, i_prof_inst, i_prof_soft);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.error_handling('GET_CONFIG 4', 'PK_SYSCONFIG', g_error, SQLERRM);
    END;

    ----

    /** @headcom
    * Public Function. Get all configurations available
    * 
    * @param      I_LANG                       Language ID
    * @param      I_ID_INSTITUTION             Institution ID
    * @param      I_SEARCH                     Search filter
    * @param      O_SYS_CONFIG                 Cursor with all configurations available
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/08
    */

    FUNCTION get_all_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_client         IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_sys_config     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ALL_SYS_CONFIG';
        -- instit vars
        a_inst_sc_id        table_varchar := table_varchar();
        a_inst_sc_desc      table_varchar := table_varchar();
        a_inst_sc_desc_func table_varchar := table_varchar();
        a_inst_sc_desc_val  table_varchar := table_varchar();
        a_inst_sc_fill      table_varchar := table_varchar();
        a_inst_sc_sw        table_number := table_number();
        a_inst_sc_desc_sw   table_varchar := table_varchar();
        a_inst_sc_flg_edit  table_varchar := table_varchar();
        a_inst_sc_flg_schm  table_varchar := table_varchar();
        -- mkt vars
        a_mkt_sc_id        table_varchar := table_varchar();
        a_mkt_sc_desc      table_varchar := table_varchar();
        a_mkt_sc_desc_func table_varchar := table_varchar();
        a_mkt_sc_desc_val  table_varchar := table_varchar();
        a_mkt_sc_fill      table_varchar := table_varchar();
        a_mkt_sc_sw        table_number := table_number();
        a_mkt_sc_desc_sw   table_varchar := table_varchar();
        a_mkt_sc_flg_edit  table_varchar := table_varchar();
        a_mkt_sc_flg_schm  table_varchar := table_varchar();
        -- generic vars
        a_gnrc_sc_id        table_varchar := table_varchar();
        a_gnrc_sc_desc      table_varchar := table_varchar();
        a_gnrc_sc_desc_func table_varchar := table_varchar();
        a_gnrc_sc_desc_val  table_varchar := table_varchar();
        a_gnrc_sc_fill      table_varchar := table_varchar();
        a_gnrc_sc_sw        table_number := table_number();
        a_gnrc_sc_desc_sw   table_varchar := table_varchar();
        a_gnrc_sc_flg_edit  table_varchar := table_varchar();
        a_gnrc_sc_flg_schm  table_varchar := table_varchar();
    
        -- final vars
        a_final_sc_id        table_varchar := table_varchar();
        a_final_sc_desc      table_varchar := table_varchar();
        a_final_sc_desc_func table_varchar := table_varchar();
        a_final_sc_desc_val  table_varchar := table_varchar();
        a_final_sc_fill      table_varchar := table_varchar();
        a_final_sc_sw        table_number := table_number();
        a_final_sc_desc_sw   table_varchar := table_varchar();
        a_final_sc_flg_edit  table_varchar := table_varchar();
        a_final_sc_flg_schm  table_varchar := table_varchar();
    
        l_generic NUMBER := 0;
        l_market  market.id_market%TYPE := 0;
    
        l_search VARCHAR2(4000) := '%' ||
                                   translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'), '_', '\_')),
                                             k_accent_y,
                                             k_accent_n) || '%';
    
        CURSOR c_instit_param
        (
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config,
                   pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config) desc_sys_config,
                   pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config) desc_functionality,
                   decode(sc.fill_type,
                          'M',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 pk_sysconfig.get_desc_val(i_lang,
                                                           i_id_institution,
                                                           sc.id_sys_config,
                                                           sc.value,
                                                           sc.id_software,
                                                           sc.fill_type,
                                                           sc.mvalue)),
                          decode(sc.flg_schema,
                                 'F',
                                 (SELECT fsc.value
                                    FROM finger_db.sys_config fsc
                                   WHERE fsc.id_sys_config = sc.id_sys_config),
                                 sc.value)) desc_value,
                   
                   sc.fill_type,
                   s.id_software,
                   decode(s.id_software, l_generic, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                   nvl(sc.client_configuration, pk_alert_constant.get_available) flg_edit,
                   sc.flg_schema
              FROM sys_config sc
              JOIN software s
                ON sc.id_software = s.id_software
             WHERE sc.id_institution = i_id_institution
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND (i_search IS NULL OR
                   decode(i_search,
                           NULL,
                           NULL,
                           (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                      k_accent_y,
                                      k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution);
    
        CURSOR c_mkt_param
        (
            a_inst   table_varchar,
            i_mkt    market.id_market%TYPE,
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config,
                   pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config) desc_sys_config,
                   pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config) desc_functionality,
                   decode(sc.fill_type,
                          'M',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          decode(sc.flg_schema,
                                 'F',
                                 (SELECT fsc.value
                                    FROM finger_db.sys_config fsc
                                   WHERE fsc.id_sys_config = sc.id_sys_config),
                                 sc.value)) desc_value,
                   
                   sc.fill_type,
                   s.id_software,
                   decode(s.id_software, l_generic, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                   nvl(sc.client_configuration, pk_alert_constant.get_available) flg_edit,
                   sc.flg_schema
              FROM sys_config sc
              JOIN software s
                ON sc.id_software = s.id_software
             WHERE sc.id_institution = l_generic
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND sc.id_market = i_mkt
               AND (i_search IS NULL OR
                   decode(i_search,
                           NULL,
                           NULL,
                           (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                      k_accent_y,
                                      k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution)
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_inst AS table_varchar)));
    
        CURSOR c_generic_param
        (
            a_inst   table_varchar,
            a_mkt    table_varchar,
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config,
                   pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config) desc_sys_config,
                   pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config) desc_functionality,
                   decode(sc.fill_type,
                          'M',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          decode(sc.flg_schema,
                                 'F',
                                 (SELECT fsc.value
                                    FROM finger_db.sys_config fsc
                                   WHERE fsc.id_sys_config = sc.id_sys_config),
                                 sc.value)) desc_value,
                   
                   sc.fill_type,
                   s.id_software,
                   decode(s.id_software, l_generic, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                   nvl(sc.client_configuration, pk_alert_constant.get_available) flg_edit,
                   sc.flg_schema
              FROM sys_config sc, software s
             WHERE sc.id_institution = l_generic
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND sc.id_market = l_generic
               AND (i_search IS NULL OR
                   decode(i_search,
                           NULL,
                           NULL,
                           (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                      k_accent_y,
                                      k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution)
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_inst AS table_varchar)))
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_mkt AS table_varchar)));
    BEGIN
    
        g_error  := upper('GET institution market');
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        -- open and colect institution configurations
        g_error := upper('GET institution param cursor');
        OPEN c_instit_param(i_client, i_search);
        FETCH c_instit_param BULK COLLECT
            INTO a_inst_sc_id,
                 a_inst_sc_desc,
                 a_inst_sc_desc_func,
                 a_inst_sc_desc_val,
                 a_inst_sc_fill,
                 a_inst_sc_sw,
                 a_inst_sc_desc_sw,
                 a_inst_sc_flg_edit,
                 a_inst_sc_flg_schm;
        g_error := upper('close institution param cursor');
        CLOSE c_instit_param;
        -- open and colect market configurations
        g_error := upper('GET market param cursor');
        OPEN c_mkt_param(a_inst_sc_id, l_market, i_client, i_search);
        FETCH c_mkt_param BULK COLLECT
            INTO a_mkt_sc_id,
                 a_mkt_sc_desc,
                 a_mkt_sc_desc_func,
                 a_mkt_sc_desc_val,
                 a_mkt_sc_fill,
                 a_mkt_sc_sw,
                 a_mkt_sc_desc_sw,
                 a_mkt_sc_flg_edit,
                 a_mkt_sc_flg_schm;
        g_error := upper('close market param cursor');
        CLOSE c_mkt_param;
    
        -- open and colect generic configurations   
        g_error := upper('open generic param cursor');
        OPEN c_generic_param(a_inst_sc_id, a_mkt_sc_id, i_client, i_search);
        FETCH c_generic_param BULK COLLECT
            INTO a_gnrc_sc_id,
                 a_gnrc_sc_desc,
                 a_gnrc_sc_desc_func,
                 a_gnrc_sc_desc_val,
                 a_gnrc_sc_fill,
                 a_gnrc_sc_sw,
                 a_gnrc_sc_desc_sw,
                 a_gnrc_sc_flg_edit,
                 a_gnrc_sc_flg_schm;
    
        g_error := upper('close generic param cursor');
        CLOSE c_generic_param;
    
        g_error := upper('Join All results');
        -- join all result arrays as final data
        a_final_sc_id        := a_inst_sc_id MULTISET UNION a_mkt_sc_id MULTISET UNION a_gnrc_sc_id;
        a_final_sc_desc      := a_inst_sc_desc MULTISET UNION a_mkt_sc_desc MULTISET UNION a_gnrc_sc_desc;
        a_final_sc_desc_func := a_inst_sc_desc_func MULTISET UNION a_mkt_sc_desc_func MULTISET UNION
                                a_gnrc_sc_desc_func;
        a_final_sc_desc_val  := a_inst_sc_desc_val MULTISET UNION a_mkt_sc_desc_val MULTISET UNION a_gnrc_sc_desc_val;
        a_final_sc_fill      := a_inst_sc_fill MULTISET UNION a_mkt_sc_fill MULTISET UNION a_gnrc_sc_fill;
        a_final_sc_sw        := a_inst_sc_sw MULTISET UNION a_mkt_sc_sw MULTISET UNION a_gnrc_sc_sw;
        a_final_sc_desc_sw   := a_inst_sc_desc_sw MULTISET UNION a_mkt_sc_desc_sw MULTISET UNION a_gnrc_sc_desc_sw;
        a_final_sc_flg_edit  := a_inst_sc_flg_edit MULTISET UNION a_mkt_sc_flg_edit MULTISET UNION a_gnrc_sc_flg_edit;
        a_final_sc_flg_schm  := a_inst_sc_flg_schm MULTISET UNION a_mkt_sc_flg_schm MULTISET UNION a_gnrc_sc_flg_schm;
    
        g_error := upper('return data');
        -- convert info into ordered result table
        OPEN o_sys_config FOR
            SELECT all_sc.id_sys_config,
                   all_sc.desc_sys_config,
                   all_sc.desc_functionality,
                   all_sc.desc_value,
                   all_sc.fill_type,
                   all_sc.id_software,
                   all_sc.software_name,
                   all_sc.flg_edit,
                   all_sc.flg_schema
              FROM (SELECT sc_id.id_sys_config,
                           sc_desc.desc_sys_config,
                           sc_df.desc_functionality,
                           sc_dv.desc_value,
                           sc_f.fill_type,
                           sc_sw.id_software,
                           sc_dsw.software_name,
                           sc_fe.flg_edit,
                           sc_fs.flg_schema,
                           sc_id.rn
                      FROM (SELECT rownum rn, column_value id_sys_config
                              FROM TABLE(CAST(a_final_sc_id AS table_varchar))) sc_id,
                           (SELECT rownum rn, column_value desc_sys_config
                              FROM TABLE(CAST(a_final_sc_desc AS table_varchar))) sc_desc,
                           (SELECT rownum rn, column_value desc_functionality
                              FROM TABLE(CAST(a_final_sc_desc_func AS table_varchar))) sc_df,
                           (SELECT rownum rn, column_value desc_value
                              FROM TABLE(CAST(a_final_sc_desc_val AS table_varchar))) sc_dv,
                           (SELECT rownum rn, column_value fill_type
                              FROM TABLE(CAST(a_final_sc_fill AS table_varchar))) sc_f,
                           (SELECT rownum rn, column_value id_software
                              FROM TABLE(CAST(a_final_sc_sw AS table_number))) sc_sw,
                           (SELECT rownum rn, column_value software_name
                              FROM TABLE(CAST(a_final_sc_desc_sw AS table_varchar))) sc_dsw,
                           (SELECT rownum rn, column_value flg_edit
                              FROM TABLE(CAST(a_final_sc_flg_edit AS table_varchar))) sc_fe,
                           (SELECT rownum rn, column_value flg_schema
                              FROM TABLE(CAST(a_final_sc_flg_schm AS table_varchar))) sc_fs
                     WHERE sc_id.rn = sc_desc.rn
                       AND sc_id.rn = sc_df.rn
                       AND sc_id.rn = sc_dv.rn
                       AND sc_id.rn = sc_f.rn
                       AND sc_id.rn = sc_sw.rn
                       AND sc_id.rn = sc_dsw.rn
                       AND sc_id.rn = sc_fe.rn
                       AND sc_id.rn = sc_fs.rn) all_sc
             ORDER BY all_sc.id_sys_config;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sys_config);
            RETURN FALSE;
        
    END get_all_sys_config;

    /** @headcom
    * Public Function. Get configuration possible values
    *
    * @param      I_LANG                     Language ID
    * @param      I_ID_SYS_CONFIG            Configuration ID
    * @param      O_VALUES                   Configuration possible values
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/08
    */
    FUNCTION get_sys_config_values
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE,
        o_values        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SYS_CONFIG_VALUES';
    BEGIN
        g_error := 'GET SYS_CONFIG VALUES CURSOR';
        RETURN pk_sysdomain.get_values_domain(i_id_sys_config, i_lang, o_values);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_values);
            RETURN FALSE;
    END get_sys_config_values;

    /** @headcom
    * Public Function. Get configuration information
    * 
    * @param      I_LANG                       Language ID
    * @param      I_ID_INSTITUTION             Institution ID
    * @param      I_ID_SYS_CONFIG              Configuration ID
    * @param      O_SYS_CONFIG                 Cursor with all configurations available
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/11
    */
    FUNCTION get_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        o_func_desc      OUT sys_config_translation.desc_functionality%TYPE,
        o_config_desc    OUT sys_config_translation.desc_config%TYPE,
        o_sys_config     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SYS_CONFIG';
        l_id_market market.id_market%TYPE;
    BEGIN
        g_error       := 'GET SYS_CONFIG CURSOR';
        o_config_desc := pk_sysconfig.get_desc_config(i_lang, i_id_sys_config);
        o_func_desc   := pk_sysconfig.get_desc_functionality(i_lang, i_id_sys_config);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        IF i_id_institution = 0
        THEN
        
            OPEN o_sys_config FOR
                SELECT s.id_software id_software,
                       decode(s.id_software, 0, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                       decode(sc.flg_schema,
                              'F',
                              (SELECT fsc.value
                                 FROM finger_db.sys_config fsc
                                WHERE fsc.id_sys_config = sc.id_sys_config),
                              sc.value) VALUE,
                       decode(sc.fill_type,
                              'M',
                              decode(sc.flg_schema,
                                     'F',
                                     pk_sysdomain.get_domain(sc.id_sys_config,
                                                             (SELECT fsc.value
                                                                FROM finger_db.sys_config fsc
                                                               WHERE fsc.id_sys_config = sc.id_sys_config),
                                                             i_lang),
                                     get_desc_val(i_lang,
                                                  i_id_institution,
                                                  sc.id_sys_config,
                                                  sc.value,
                                                  sc.id_software,
                                                  sc.fill_type,
                                                  sc.mvalue)),
                              'F',
                              decode(sc.flg_schema,
                                     'F',
                                     pk_sysdomain.get_domain(sc.id_sys_config,
                                                             (SELECT fsc.value
                                                                FROM finger_db.sys_config fsc
                                                               WHERE fsc.id_sys_config = sc.id_sys_config),
                                                             i_lang),
                                     get_desc_val(i_lang,
                                                  i_id_institution,
                                                  sc.id_sys_config,
                                                  sc.value,
                                                  sc.id_software,
                                                  sc.fill_type,
                                                  sc.mvalue)),
                              decode(sc.flg_schema,
                                     'F',
                                     (SELECT fsc.value
                                        FROM finger_db.sys_config fsc
                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                     sc.value)) desc_value,
                       pk_date_utils.date_hour_chr_extend_tsz(i_lang,
                                                              sct.adw_last_update,
                                                              profissional(0, i_id_institution, 0)) adw_last_update,
                       sc.id_software real_id_software,
                       sc.flg_schema
                  FROM sys_config sc, sys_config_translation sct, software s
                 WHERE sc.id_institution = i_id_institution
                   AND sc.id_market = 0
                   AND sc.id_sys_config = i_id_sys_config
                   AND sct.id_sys_config(+) = sc.id_sys_config
                   AND sct.id_language(+) = i_lang
                   AND s.id_software = sc.id_software
                   AND s.id_software = 0
                 ORDER BY adw_last_update;
        
        ELSE
        
            OPEN o_sys_config FOR
                SELECT id_software,
                       decode(id_software, 0, pk_translation.get_translation(i_lang, code_software), name) software_name,
                       VALUE,
                       desc_value,
                       adw_last_update,
                       real_id_software,
                       flg_schema
                  FROM (SELECT si.id_software,
                               s.name,
                               s.code_software,
                               sc.id_sys_config,
                               decode(sc.flg_schema,
                                      'F',
                                      (SELECT fsc.value
                                         FROM finger_db.sys_config fsc
                                        WHERE fsc.id_sys_config = sc.id_sys_config),
                                      sc.value) VALUE,
                               decode(sc.fill_type,
                                      'M',
                                      decode(sc.flg_schema,
                                             'F',
                                             pk_sysdomain.get_domain(sc.id_sys_config,
                                                                     (SELECT fsc.value
                                                                        FROM finger_db.sys_config fsc
                                                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                                                     i_lang),
                                             pk_sysdomain.get_domain(sc.id_sys_config, sc.value, i_lang)),
                                      
                                      'F',
                                      decode(sc.flg_schema,
                                             'F',
                                             pk_sysdomain.get_domain(sc.id_sys_config,
                                                                     (SELECT fsc.value
                                                                        FROM finger_db.sys_config fsc
                                                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                                                     i_lang),
                                             get_desc_val(i_lang,
                                                          i_id_institution,
                                                          sc.id_sys_config,
                                                          sc.value,
                                                          sc.id_software,
                                                          sc.fill_type,
                                                          sc.mvalue)),
                                      decode(sc.flg_schema,
                                             'F',
                                             (SELECT fsc.value
                                                FROM finger_db.sys_config fsc
                                               WHERE fsc.id_sys_config = sc.id_sys_config),
                                             sc.value)) desc_value,
                               nvl(pk_date_utils.date_hour_chr_extend_tsz(1,
                                                                          sc.update_time,
                                                                          profissional(0, i_id_institution, 0)),
                                   pk_date_utils.date_hour_chr_extend_tsz(1,
                                                                          sc.create_time,
                                                                          profissional(0, i_id_institution, 0))) adw_last_update,
                               sc.id_software real_id_software,
                               sc.flg_schema,
                               sc.id_market,
                               row_number() over(PARTITION BY sc.id_sys_config, sc.id_software ORDER BY sc.id_institution DESC, si.id_software DESC, sc.id_market DESC) rn
                          FROM software_institution si, software s, sys_config sc
                         WHERE s.id_software = si.id_software
                           AND si.id_institution = i_id_institution
                           AND sc.id_sys_config = i_id_sys_config
                           AND sc.id_market IN (0, l_id_market)
                           AND sc.id_software IN (0, si.id_software)
                           AND sc.id_institution IN (0, si.id_institution)) data_aux
                 WHERE data_aux.rn = 1
                 ORDER BY software_name;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sys_config);
            RETURN FALSE;
        
    END get_sys_config;

    /** @headcom
    * Public Function. Update Value in SYS_CONFIG
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    * @param      I_VALUE                              Configuration value
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/08
    */
    FUNCTION set_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_software    IN table_number,
        i_value          IN table_varchar,
        i_fill_type      IN sys_config.fill_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(30) := 'GET_SYS_CONFIG';
        l_flg_schema VARCHAR2(1);
    BEGIN
    
        FOR i IN 1 .. i_id_software.count
        LOOP
        
            BEGIN
                SELECT sc.flg_schema
                  INTO l_flg_schema
                  FROM sys_config sc
                 WHERE sc.id_sys_config = i_id_sys_config
                   AND sc.id_institution = i_id_institution
                   AND sc.id_software = i_id_software(i)
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_schema := 'A';
            END;
        
            IF l_flg_schema = 'F'
            THEN
            
                MERGE INTO finger_db.sys_config fsc
                USING (SELECT i_id_sys_config id_sys_config, i_value(i) VALUE
                         FROM dual) f_sys_conf
                ON (fsc.id_sys_config = f_sys_conf.id_sys_config)
                WHEN MATCHED THEN
                    UPDATE
                       SET fsc.value = f_sys_conf.value
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sys_config, VALUE, desc_sys_config)
                    VALUES
                        (f_sys_conf.id_sys_config,
                         f_sys_conf.value,
                         (SELECT desc_sys_config
                            FROM (SELECT desc_sys_config
                                    FROM sys_config cc
                                   WHERE cc.id_sys_config = i_id_sys_config
                                     AND cc.id_institution IN (i_id_institution, 0)
                                     AND cc.id_software IN (i_id_software(i), 0)
                                   ORDER BY id_software DESC, id_institution DESC)
                           WHERE rownum < 2));
            
                g_error := 'UPDATE SYS_CONFIG_TRANSLATION';
                UPDATE sys_config_translation
                   SET adw_last_update = SYSDATE
                 WHERE id_sys_config = i_id_sys_config
                   AND id_language = i_lang;
            
            ELSE
            
                MERGE INTO sys_config sc
                USING (SELECT i_id_sys_config id_sys_config,
                              i_id_institution id_institution,
                              i_id_software(i) id_software,
                              i_fill_type fill_type,
                              i_value(i) VALUE
                         FROM dual) sys_conf
                ON (sc.id_sys_config = sys_conf.id_sys_config AND sc.id_institution = sys_conf.id_institution AND sc.id_software = sys_conf.id_software)
                WHEN MATCHED THEN
                    UPDATE
                       SET sc.value = sys_conf.value
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sys_config,
                         VALUE,
                         id_institution,
                         id_software,
                         fill_type,
                         client_configuration,
                         internal_configuration,
                         global_configuration,
                         desc_sys_config,
                         flg_schema,
                         mvalue)
                    VALUES
                        (sys_conf.id_sys_config,
                         sys_conf.value,
                         sys_conf.id_institution,
                         sys_conf.id_software,
                         sys_conf.fill_type,
                         'Y',
                         'Y',
                         'N',
                         (SELECT desc_sys_config
                            FROM (SELECT desc_sys_config
                                    FROM sys_config cc
                                   WHERE cc.id_sys_config = i_id_sys_config
                                     AND cc.id_institution IN (i_id_institution, 0)
                                     AND cc.id_software IN (i_id_software(i), 0)
                                   ORDER BY id_software DESC, id_institution DESC)
                           WHERE rownum < 2),
                         l_flg_schema,
                         (SELECT mvalue
                            FROM (SELECT cc.mvalue
                                    FROM sys_config cc
                                   WHERE cc.id_sys_config = i_id_sys_config
                                     AND cc.id_institution IN (i_id_institution, 0)
                                     AND cc.id_software IN (i_id_software(i), 0)
                                   ORDER BY id_software DESC, id_institution DESC)
                           WHERE rownum < 2));
            
                g_error := 'UPDATE SYS_CONFIG_TRANSLATION';
                UPDATE sys_config_translation
                   SET adw_last_update = SYSDATE
                 WHERE id_sys_config = i_id_sys_config
                   AND id_language = i_lang;
            
            END IF;
        
        END LOOP;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_sys_config;

    FUNCTION get_config
    (
        i_code_cf   IN table_varchar,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        o_msg_cf    OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_MSG_CF';
        OPEN o_msg_cf FOR
            SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
             column_value id_sys_config, pk_sysconfig.get_config(column_value, i_prof_inst, i_prof_soft) VALUE
              FROM TABLE(CAST(i_code_cf AS table_varchar)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.error_handling('GET_CONFIG 2', 'PK_SYSCONFIG', g_error, SQLERRM);
    END get_config;

    /**
    * This function returns the title of the configuration
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    *
    * @return     varchar2 with title
    */
    FUNCTION get_desc_config
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config_translation.desc_config%TYPE IS
        l_desc sys_config_translation.desc_config%TYPE;
    BEGIN
        pk_backoffice_translation.set_read_translation(i_id_sys_config, 'SYS_CONFIG_TRANSLATION.DESC_CONFIG');
    
        SELECT desc_config
          INTO l_desc
          FROM sys_config_translation s
         WHERE id_language = i_lang
           AND id_sys_config = i_id_sys_config;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**
    * This function returns the description of the configuration
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    *
    * @return     varchar2 with description
    */
    FUNCTION get_desc_functionality
    (
        i_lang          IN language.id_language%TYPE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config_translation.desc_functionality%TYPE IS
        l_desc sys_config_translation.desc_functionality%TYPE;
    BEGIN
        pk_backoffice_translation.set_read_translation(i_id_sys_config, 'SYS_CONFIG_TRANSLATION.DESC_FUNCTIONALITY');
    
        SELECT desc_functionality
          INTO l_desc
          FROM sys_config_translation s
         WHERE id_language = i_lang
           AND id_sys_config = i_id_sys_config;
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    ----

    /** @headcom
    * Public Function. Get configuration information
    * 
    * @param      I_LANG                       Language ID
    * @param      I_ID_INSTITUTION             Institution ID
    * @param      I_ID_SYS_CONFIG              Configuration ID
    * @param      O_SYS_CONFIG                 Cursor with all configurations available
    * @param      O_ERROR                      Error
    * @param      o_impact_msg                 Impact message description
    * @param      o_impact_screen_msg          Impact message of a change in sys_config table, for a screen
    *
    * @return     boolean
    * @author     ARM
    * @version    0.1
    * @since      2008/11/18
    */

    FUNCTION get_sys_config
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN sys_config.id_institution%TYPE,
        i_id_sys_config     IN sys_config.id_sys_config%TYPE,
        o_func_desc         OUT sys_config_translation.desc_functionality%TYPE,
        o_config_desc       OUT sys_config_translation.desc_config%TYPE,
        o_sys_config        OUT pk_types.cursor_type,
        o_error             OUT t_error_out,
        o_impact_msg        OUT sys_config_translation.impact_msg%TYPE,
        o_impact_screen_msg OUT sys_config_translation.impact_msg%TYPE
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SYS_CONFIG';
        l_market    market.id_market%TYPE := 0;
    BEGIN
        g_error       := 'GET SYS_CONFIG CURSOR';
        o_config_desc := pk_sysconfig.get_desc_config(i_lang, i_id_sys_config);
        o_func_desc   := pk_sysconfig.get_desc_functionality(i_lang, i_id_sys_config);
        l_market      := pk_utils.get_institution_market(i_lang, i_id_institution);
    
        BEGIN
            SELECT impact_msg, impact_screen_msg
              INTO o_impact_msg, o_impact_screen_msg
              FROM sys_config_translation s
             WHERE s.id_language = i_lang
               AND s.id_sys_config = i_id_sys_config;
        
            IF o_impact_screen_msg IS NULL
            THEN
                o_impact_screen_msg := pk_message.get_message(i_lang, g_default_impact_msg);
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_impact_msg        := '';
                o_impact_screen_msg := pk_message.get_message(i_lang, g_default_impact_msg);
        END;
    
        IF i_id_institution = 0
        THEN
        
            OPEN o_sys_config FOR
                SELECT id_software, software_name, VALUE, desc_value, adw_last_update, real_id_software, flg_schema
                  FROM (SELECT s.id_software id_software,
                               decode(s.id_software, 0, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                               decode(s.id_software, 0, 10, 0) rank,
                               decode(sc.flg_schema,
                                      'F',
                                      (SELECT fsc.value
                                         FROM finger_db.sys_config fsc
                                        WHERE fsc.id_sys_config = sc.id_sys_config),
                                      sc.value) VALUE,
                               decode(sc.fill_type,
                                      'M',
                                      decode(sc.flg_schema,
                                             'F',
                                             pk_sysdomain.get_domain(sc.id_sys_config,
                                                                     (SELECT fsc.value
                                                                        FROM finger_db.sys_config fsc
                                                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                                                     i_lang),
                                             get_desc_val(i_lang,
                                                          i_id_institution,
                                                          sc.id_sys_config,
                                                          sc.value,
                                                          sc.id_software,
                                                          sc.fill_type,
                                                          sc.mvalue)),
                                      'F',
                                      decode(sc.flg_schema,
                                             'F',
                                             pk_sysdomain.get_domain(sc.id_sys_config,
                                                                     (SELECT fsc.value
                                                                        FROM finger_db.sys_config fsc
                                                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                                                     i_lang),
                                             get_desc_val(i_lang,
                                                          i_id_institution,
                                                          sc.id_sys_config,
                                                          sc.value,
                                                          sc.id_software,
                                                          sc.fill_type,
                                                          sc.mvalue)),
                                      decode(sc.flg_schema,
                                             'F',
                                             (SELECT fsc.value
                                                FROM finger_db.sys_config fsc
                                               WHERE fsc.id_sys_config = sc.id_sys_config),
                                             sc.value)) desc_value,
                               pk_date_utils.date_hour_chr_extend_tsz(i_lang,
                                                                      sct.adw_last_update,
                                                                      profissional(0, i_id_institution, 0)) adw_last_update,
                               sc.id_software real_id_software,
                               sc.flg_schema
                          FROM sys_config sc, sys_config_translation sct, software s
                         WHERE sc.id_institution = i_id_institution
                           AND sc.id_sys_config = i_id_sys_config
                           AND sct.id_sys_config(+) = sc.id_sys_config
                           AND sct.id_language(+) = i_lang
                           AND s.id_software = sc.id_software
                           AND s.id_software = 0
                           AND sc.id_market = 0) sc_data
                 ORDER BY rank, software_name;
        
        ELSE
            OPEN o_sys_config FOR
            -- Configuration for each software in the institution
                SELECT id_software, software_name, VALUE, desc_value, adw_last_update, real_id_software, flg_schema
                  FROM (SELECT si.id_software,
                               decode(si.id_software, 0, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                               decode(si.id_software, 0, 10, 0) rank,
                               sc.id_sys_config,
                               decode(sc.flg_schema,
                                      'F',
                                      (SELECT fsc.value
                                         FROM finger_db.sys_config fsc
                                        WHERE fsc.id_sys_config = sc.id_sys_config),
                                      sc.value) VALUE,
                               decode(sc.fill_type,
                                      'M',
                                      decode(sc.flg_schema,
                                             'F',
                                             pk_sysdomain.get_domain(sc.id_sys_config,
                                                                     (SELECT fsc.value
                                                                        FROM finger_db.sys_config fsc
                                                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                                                     i_lang),
                                             get_desc_val(i_lang,
                                                          i_id_institution,
                                                          sc.id_sys_config,
                                                          sc.value,
                                                          sc.id_software,
                                                          sc.fill_type,
                                                          sc.mvalue)),
                                      'F',
                                      decode(sc.flg_schema,
                                             'F',
                                             pk_sysdomain.get_domain(sc.id_sys_config,
                                                                     (SELECT fsc.value
                                                                        FROM finger_db.sys_config fsc
                                                                       WHERE fsc.id_sys_config = sc.id_sys_config),
                                                                     i_lang),
                                             get_desc_val(i_lang,
                                                          i_id_institution,
                                                          sc.id_sys_config,
                                                          sc.value,
                                                          sc.id_software,
                                                          sc.fill_type,
                                                          sc.mvalue)),
                                      decode(sc.flg_schema,
                                             'F',
                                             (SELECT fsc.value
                                                FROM finger_db.sys_config fsc
                                               WHERE fsc.id_sys_config = sc.id_sys_config),
                                             sc.value)) desc_value,
                               nvl(pk_date_utils.date_hour_chr_extend_tsz(1,
                                                                          sc.update_time,
                                                                          profissional(0, i_id_institution, 0)),
                                   pk_date_utils.date_hour_chr_extend_tsz(1,
                                                                          sc.create_time,
                                                                          profissional(0, i_id_institution, 0))) adw_last_update,
                               sc.id_software real_id_software,
                               sc.flg_schema,
                               sc.id_market,
                               row_number() over(PARTITION BY sc.id_sys_config, si.id_software ORDER BY sc.id_institution DESC, sc.id_software DESC, sc.id_market DESC) rn
                          FROM software_institution si, software s, sys_config sc
                         WHERE s.id_software = si.id_software
                           AND si.id_institution = i_id_institution
                           AND sc.id_sys_config = i_id_sys_config
                           AND sc.id_market IN (0, l_market)
                           AND sc.id_software IN (0, si.id_software)
                           AND sc.id_institution IN (0, si.id_institution)) data_aux
                 WHERE data_aux.rn = 1
                 ORDER BY rank, software_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sys_config);
            RETURN FALSE;
        
    END get_sys_config;

    /***************************************************************************************
    * Merges a record into sys_config_translation table                                    *
    *                                                                                      *
    * @param i_lang              record language                                           *     
    * @param i_sys_config        sys_config code                                           *
    * @param i_desc_config       description                                               *
    * @param i_desc_func         functionality description                                 *
    * @param i_impact_msg        configuration impact description title                    *
    * @param i_impact_screen_msg configuration impact description message                  *
    *                                                                                      *
    ***************************************************************************************/
    PROCEDURE insert_into_syscfg_translation
    (
        i_lang              IN language.id_language%TYPE,
        i_sys_config        IN sys_config_translation.id_sys_config%TYPE,
        i_desc_config       IN sys_config_translation.desc_config %TYPE,
        i_desc_func         IN sys_config_translation.desc_functionality%TYPE,
        i_impact_msg        IN sys_config_translation.impact_msg%TYPE,
        i_impact_screen_msg IN sys_config_translation.impact_screen_msg%TYPE
    ) IS
        --l_max translation.id_translation%TYPE;
    BEGIN
    
        MERGE INTO sys_config_translation t
        USING (SELECT i_sys_config        id_sys_config,
                      i_desc_config       desc_config,
                      i_desc_func         desc_functionality,
                      i_lang              id_language,
                      i_impact_msg        impact_msg,
                      i_impact_screen_msg impact_screen_msg
                 FROM dual) args
        ON (t.id_language = args.id_language AND t.id_sys_config = args.id_sys_config)
        WHEN MATCHED THEN
            UPDATE
               SET desc_config        = args.desc_config,
                   desc_functionality = args.desc_functionality,
                   adw_last_update    = SYSDATE,
                   impact_msg         = args.impact_msg,
                   impact_screen_msg  = args.impact_screen_msg
        WHEN NOT MATCHED THEN
            INSERT
                (id_sys_config,
                 id_language,
                 desc_config,
                 desc_functionality,
                 adw_last_update,
                 impact_msg,
                 impact_screen_msg)
            VALUES
                (args.id_sys_config,
                 args.id_language,
                 args.desc_config,
                 args.desc_functionality,
                 SYSDATE,
                 args.impact_msg,
                 args.impact_screen_msg);
    END;

    PROCEDURE insert_into_sysconfig
    (
        i_idsysconfig     IN sys_config.id_sys_config%TYPE,
        i_value           IN sys_config.value%TYPE,
        i_institution     IN sys_config.id_institution%TYPE,
        i_software        IN sys_config.id_software%TYPE,
        i_market          IN sys_config.id_market%TYPE,
        i_desc            IN sys_config.desc_sys_config%TYPE,
        i_fill_type       IN sys_config.fill_type%TYPE,
        i_client_config   IN sys_config.client_configuration%TYPE,
        i_internal_config IN sys_config.internal_configuration%TYPE,
        i_global_config   IN sys_config.global_configuration%TYPE,
        i_schema          IN sys_config.flg_schema%TYPE,
        i_mvalue          IN sys_config.mvalue%TYPE DEFAULT NULL
    ) IS
    BEGIN
    
        pk_sys_configuration.ins_config(i_id_sys_config => i_idsysconfig, i_desc_sys_config => i_desc);
    
        g_error := 'TRY UPDATE';
        UPDATE sys_config
           SET VALUE                  = i_value,
               desc_sys_config        = i_desc,
               fill_type              = i_fill_type,
               client_configuration   = i_client_config,
               internal_configuration = i_internal_config,
               global_configuration   = i_global_config,
               flg_schema             = i_schema,
               mvalue                 = nvl(i_mvalue, mvalue)
         WHERE id_institution = i_institution
           AND id_software = i_software
           AND id_market = i_market
           AND id_sys_config = i_idsysconfig;
    
        IF SQL%ROWCOUNT = 0
        THEN
            g_error := 'INSERT';
            INSERT INTO sys_config
                (id_sys_config,
                 VALUE,
                 desc_sys_config,
                 id_institution,
                 id_software,
                 fill_type,
                 client_configuration,
                 internal_configuration,
                 global_configuration,
                 flg_schema,
                 id_market,
                 mvalue)
            VALUES
                (i_idsysconfig,
                 i_value,
                 i_desc,
                 i_institution,
                 i_software,
                 i_fill_type,
                 i_client_config,
                 i_internal_config,
                 i_global_config,
                 i_schema,
                 i_market,
                 i_mvalue);
        
        END IF;
    
    EXCEPTION
    
        WHEN pk_sys_configuration.e_cfg_deprecated THEN
            g_error := pk_sys_configuration.k_msg_deprecated;
            /*
            pk_alert_exceptions.raise_error(error_code_in => 0001,
                                            text_in       => g_error,
                                            name1_in      => 'G_ERROR',
                                            value1_in     => g_error);
            RAISE pk_sys_configuration.e_cfg_deprecated;
            */
            raise_application_error(-20998, g_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            text_in       => SQLERRM,
                                            name1_in      => 'G_ERROR',
                                            value1_in     => g_error);
    END insert_into_sysconfig;

    PROCEDURE insert_into_sysconfig
    (
        i_idsysconfig     IN sys_config.id_sys_config%TYPE,
        i_value           IN sys_config.value%TYPE,
        i_institution     IN sys_config.id_institution%TYPE,
        i_software        IN sys_config.id_software%TYPE,
        i_desc            IN sys_config.desc_sys_config%TYPE,
        i_fill_type       IN sys_config.fill_type%TYPE,
        i_client_config   IN sys_config.client_configuration%TYPE,
        i_internal_config IN sys_config.internal_configuration%TYPE,
        i_global_config   IN sys_config.global_configuration%TYPE,
        i_schema          IN sys_config.flg_schema%TYPE,
        i_mvalue          IN sys_config.mvalue%TYPE DEFAULT NULL
    ) IS
        l_market market.id_market%TYPE;
    BEGIN
        g_error  := 'GET INSTITUTION MARKET';
        l_market := pk_utils.get_institution_market(pk_utils.get_institution_language(i_institution, i_software),
                                                    i_institution);
    
        g_error := 'CALL INSERT_INTO_SYSCONFIG';
        insert_into_sysconfig(i_idsysconfig     => i_idsysconfig,
                              i_value           => i_value,
                              i_institution     => i_institution,
                              i_software        => i_software,
                              i_market          => l_market,
                              i_desc            => i_desc,
                              i_fill_type       => i_fill_type,
                              i_client_config   => i_client_config,
                              i_internal_config => i_internal_config,
                              i_global_config   => i_global_config,
                              i_schema          => i_schema,
                              i_mvalue          => i_mvalue);
    EXCEPTION
        WHEN pk_sys_configuration.e_cfg_deprecated THEN
            g_error := pk_sys_configuration.k_msg_deprecated;
            pk_alert_exceptions.raise_error(error_code_in => 0001,
                                            text_in       => g_error,
                                            name1_in      => 'G_ERROR',
                                            value1_in     => g_error);
            RAISE pk_sys_configuration.e_cfg_deprecated;
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            text_in       => SQLERRM,
                                            name1_in      => 'G_ERROR',
                                            value1_in     => g_error);
    END insert_into_sysconfig;

    PROCEDURE insert_into_sysconfig
    (
        i_idsysconfig     IN sys_config.id_sys_config%TYPE,
        i_value           IN sys_config.value%TYPE,
        i_market          IN sys_config.id_market%TYPE,
        i_software        IN sys_config.id_software%TYPE,
        i_desc            IN sys_config.desc_sys_config%TYPE,
        i_fill_type       IN sys_config.fill_type%TYPE,
        i_client_config   IN sys_config.client_configuration%TYPE,
        i_internal_config IN sys_config.internal_configuration%TYPE,
        i_global_config   IN sys_config.global_configuration%TYPE,
        i_schema          IN sys_config.flg_schema%TYPE,
        i_mvalue          IN sys_config.mvalue%TYPE DEFAULT NULL
    ) IS
    BEGIN
        g_error := 'CALL INSERT_INTO_SYSCONFIG';
        insert_into_sysconfig(i_idsysconfig     => i_idsysconfig,
                              i_value           => i_value,
                              i_institution     => 0,
                              i_software        => i_software,
                              i_market          => i_market,
                              i_desc            => i_desc,
                              i_fill_type       => i_fill_type,
                              i_client_config   => i_client_config,
                              i_internal_config => i_internal_config,
                              i_global_config   => i_global_config,
                              i_schema          => i_schema,
                              i_mvalue          => i_mvalue);
    EXCEPTION
        WHEN pk_sys_configuration.e_cfg_deprecated THEN
            g_error := pk_sys_configuration.k_msg_deprecated;
            pk_alert_exceptions.raise_error(error_code_in => 0001,
                                            text_in       => g_error,
                                            name1_in      => 'G_ERROR',
                                            value1_in     => g_error);
            RAISE pk_sys_configuration.e_cfg_deprecated;
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                            text_in       => SQLERRM,
                                            name1_in      => 'G_ERROR',
                                            value1_in     => g_error);
    END insert_into_sysconfig;
    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        Tércio Soares
    * @since                         2010/06/04
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER IS
    BEGIN
        RETURN g_num_records;
    END get_num_records;
    /********************************************************************************************
    * Returns Number of Sys_config Records 
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_client                Flag Client Configuration
    * @param i_search                Search
    * @param o_scf_out               SysConfig count
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Rui Gomes
    * @since                         2011/06/15
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_all_sys_config_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_client         IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_scf_out        OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ALL_SYS_CONFIG';
        l_search    VARCHAR2(4000) := '%' || translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'),
                                                                     '_',
                                                                     '\_')),
                                                       k_accent_y,
                                                       k_accent_n) || '%';
        l_generic   NUMBER := 0;
        l_market    market.id_market%TYPE;
    
        -- instit vars
        a_inst_sc_id table_varchar := table_varchar();
    
        -- mkt vars
        a_mkt_sc_id table_varchar := table_varchar();
    
        -- generic vars
        a_gnrc_sc_id table_varchar := table_varchar();
    
        -- final vars
        a_final_sc_id table_varchar := table_varchar();
    
        -- cursors
        CURSOR c_instit_param
        (
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config
              FROM sys_config sc, software s
             WHERE sc.id_institution = i_id_institution
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND (i_search IS NULL OR decode(i_search,
                                               NULL,
                                               NULL,
                                               (translate(upper(pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config)),
                                                          k_accent_y,
                                                          k_accent_n))) LIKE l_search ESCAPE
                    '\' OR decode(i_search,
                                  NULL,
                                  NULL,
                                  (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                             k_accent_y,
                                             k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution);
    
        CURSOR c_mkt_param
        (
            a_inst   table_varchar,
            i_mkt    market.id_market%TYPE,
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config
              FROM sys_config sc, software s
             WHERE sc.id_institution = l_generic
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND sc.id_market = i_mkt
               AND (i_search IS NULL OR decode(i_search,
                                               NULL,
                                               NULL,
                                               (translate(upper(pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config)),
                                                          k_accent_y,
                                                          k_accent_n))) LIKE l_search ESCAPE
                    '\' OR decode(i_search,
                                  NULL,
                                  NULL,
                                  (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                             k_accent_y,
                                             k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution)
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_inst AS table_varchar)));
    
        CURSOR c_generic_param
        (
            a_inst   table_varchar,
            a_mkt    table_varchar,
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config
              FROM sys_config sc, software s
             WHERE sc.id_institution = l_generic
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND sc.id_market = l_generic
               AND (i_search IS NULL OR decode(i_search,
                                               NULL,
                                               NULL,
                                               (translate(upper(pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config)),
                                                          k_accent_y,
                                                          k_accent_n))) LIKE l_search ESCAPE
                    '\' OR decode(i_search,
                                  NULL,
                                  NULL,
                                  (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                             k_accent_y,
                                             k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution)
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_inst AS table_varchar)))
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_mkt AS table_varchar)));
    BEGIN
        g_error := upper('Get institution market');
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   l_generic)
          INTO l_market
          FROM dual;
        -- open and colect institution configurations
        g_error := upper('open institution data cursor');
        OPEN c_instit_param(i_client, i_search);
        FETCH c_instit_param BULK COLLECT
            INTO a_inst_sc_id;
        CLOSE c_instit_param;
        -- open and colect market configurations
        g_error := upper('open market data cursor');
        OPEN c_mkt_param(a_inst_sc_id, l_market, i_client, i_search);
        FETCH c_mkt_param BULK COLLECT
            INTO a_mkt_sc_id;
        CLOSE c_mkt_param;
    
        -- open and colect generic configurations   
        g_error := upper('open generic data cursor');
        OPEN c_generic_param(a_inst_sc_id, a_mkt_sc_id, i_client, i_search);
        FETCH c_generic_param BULK COLLECT
            INTO a_gnrc_sc_id;
        CLOSE c_generic_param;
        g_error := upper('join data');
        -- join all result arrays as final data
        a_final_sc_id := a_inst_sc_id MULTISET UNION a_mkt_sc_id MULTISET UNION a_gnrc_sc_id;
    
        IF a_final_sc_id IS NOT NULL
        THEN
            o_scf_out := a_final_sc_id.count;
        ELSE
            o_scf_out := 0;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- pk_types.open_my_cursor(o_sys_config);
            RETURN FALSE;
        
    END get_all_sys_config_count;
    /********************************************************************************************
    * Returns Sys_Config data from an specific Institution
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_client                Flg Client Configuration
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    *
    * @return                        table of SysConfig (t_table_sysconfig)
    *
    * @author                        Rui Gomes
    * @since                         2011/06/15
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_all_sys_config_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_client         IN VARCHAR2,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_sysconfig_out  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- instit vars
        a_inst_sc_id        table_varchar := table_varchar();
        a_inst_sc_desc      table_varchar := table_varchar();
        a_inst_sc_desc_func table_varchar := table_varchar();
        a_inst_sc_desc_val  table_varchar := table_varchar();
        a_inst_sc_fill      table_varchar := table_varchar();
        a_inst_sc_sw        table_number := table_number();
        a_inst_sc_desc_sw   table_varchar := table_varchar();
        a_inst_sc_flg_edit  table_varchar := table_varchar();
        a_inst_sc_flg_schm  table_varchar := table_varchar();
        -- mkt vars
        a_mkt_sc_id        table_varchar := table_varchar();
        a_mkt_sc_desc      table_varchar := table_varchar();
        a_mkt_sc_desc_func table_varchar := table_varchar();
        a_mkt_sc_desc_val  table_varchar := table_varchar();
        a_mkt_sc_fill      table_varchar := table_varchar();
        a_mkt_sc_sw        table_number := table_number();
        a_mkt_sc_desc_sw   table_varchar := table_varchar();
        a_mkt_sc_flg_edit  table_varchar := table_varchar();
        a_mkt_sc_flg_schm  table_varchar := table_varchar();
        -- generic vars
        a_gnrc_sc_id        table_varchar := table_varchar();
        a_gnrc_sc_desc      table_varchar := table_varchar();
        a_gnrc_sc_desc_func table_varchar := table_varchar();
        a_gnrc_sc_desc_val  table_varchar := table_varchar();
        a_gnrc_sc_fill      table_varchar := table_varchar();
        a_gnrc_sc_sw        table_number := table_number();
        a_gnrc_sc_desc_sw   table_varchar := table_varchar();
        a_gnrc_sc_flg_edit  table_varchar := table_varchar();
        a_gnrc_sc_flg_schm  table_varchar := table_varchar();
    
        -- final vars
        a_final_sc_id        table_varchar := table_varchar();
        a_final_sc_desc      table_varchar := table_varchar();
        a_final_sc_desc_func table_varchar := table_varchar();
        a_final_sc_desc_val  table_varchar := table_varchar();
        a_final_sc_fill      table_varchar := table_varchar();
        a_final_sc_sw        table_number := table_number();
        a_final_sc_desc_sw   table_varchar := table_varchar();
        a_final_sc_flg_edit  table_varchar := table_varchar();
        a_final_sc_flg_schm  table_varchar := table_varchar();
    
        t_scfg_data alert.t_table_sysconfig;
    
        l_generic   NUMBER := 0;
        l_market    market.id_market%TYPE := 0;
        l_func_name VARCHAR2(100) := 'GET_ALL_SYS_CONFIG_DATA';
    
        l_search VARCHAR2(4000) := '%' ||
                                   translate(upper(REPLACE(REPLACE(REPLACE(i_search, '\', '\\'), '%', '\%'), '_', '\_')),
                                             k_accent_y,
                                             k_accent_n) || '%';
        CURSOR c_instit_param
        (
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config,
                   pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config) desc_sys_config,
                   pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config) desc_functionality,
                   decode(sc.fill_type,
                          'M',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          'F',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          decode(sc.flg_schema,
                                 'F',
                                 (SELECT fsc.value
                                    FROM finger_db.sys_config fsc
                                   WHERE fsc.id_sys_config = sc.id_sys_config),
                                 sc.value)) desc_value,
                   sc.fill_type,
                   s.id_software,
                   decode(s.id_software, l_generic, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                   nvl(sc.client_configuration, pk_alert_constant.get_available) flg_edit,
                   sc.flg_schema
              FROM sys_config sc, software s
             WHERE sc.id_institution = i_id_institution
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND (i_search IS NULL OR decode(i_search,
                                               NULL,
                                               NULL,
                                               (translate(upper(pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config)),
                                                          k_accent_y,
                                                          k_accent_n))) LIKE l_search ESCAPE
                    '\' OR decode(i_search,
                                  NULL,
                                  NULL,
                                  (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                             k_accent_y,
                                             k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution);
    
        CURSOR c_mkt_param
        (
            a_inst   table_varchar,
            i_mkt    market.id_market%TYPE,
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config,
                   pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config) desc_sys_config,
                   pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config) desc_functionality,
                   decode(sc.fill_type,
                          'M',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          'F',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          decode(sc.flg_schema,
                                 'F',
                                 (SELECT fsc.value
                                    FROM finger_db.sys_config fsc
                                   WHERE fsc.id_sys_config = sc.id_sys_config),
                                 sc.value)) desc_value,
                   
                   sc.fill_type,
                   s.id_software,
                   decode(s.id_software, l_generic, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                   nvl(sc.client_configuration, pk_alert_constant.get_available) flg_edit,
                   sc.flg_schema
              FROM sys_config sc, software s
             WHERE sc.id_institution = l_generic
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND sc.id_market = i_mkt
               AND (i_search IS NULL OR decode(i_search,
                                               NULL,
                                               NULL,
                                               (translate(upper(pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config)),
                                                          k_accent_y,
                                                          k_accent_n))) LIKE l_search ESCAPE
                    '\' OR decode(i_search,
                                  NULL,
                                  NULL,
                                  (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                             k_accent_y,
                                             k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution)
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_inst AS table_varchar)));
    
        CURSOR c_generic_param
        (
            a_inst   table_varchar,
            a_mkt    table_varchar,
            i_flg    VARCHAR2,
            i_search VARCHAR2
        ) IS
            SELECT sc.id_sys_config,
                   pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config) desc_sys_config,
                   pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config) desc_functionality,
                   decode(sc.fill_type,
                          'M',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          'F',
                          decode(sc.flg_schema,
                                 'F',
                                 pk_sysdomain.get_domain(sc.id_sys_config,
                                                         (SELECT fsc.value
                                                            FROM finger_db.sys_config fsc
                                                           WHERE fsc.id_sys_config = sc.id_sys_config),
                                                         i_lang),
                                 get_desc_val(i_lang,
                                              i_id_institution,
                                              sc.id_sys_config,
                                              sc.value,
                                              sc.id_software,
                                              sc.fill_type,
                                              sc.mvalue)),
                          decode(sc.flg_schema,
                                 'F',
                                 (SELECT fsc.value
                                    FROM finger_db.sys_config fsc
                                   WHERE fsc.id_sys_config = sc.id_sys_config),
                                 sc.value)) desc_value,
                   
                   sc.fill_type,
                   s.id_software,
                   decode(s.id_software, l_generic, pk_translation.get_translation(i_lang, s.code_software), s.name) software_name,
                   nvl(sc.client_configuration, pk_alert_constant.get_available) flg_edit,
                   sc.flg_schema
              FROM sys_config sc, software s
             WHERE sc.id_institution = l_generic
               AND sc.id_software = s.id_software
               AND decode(i_flg,
                          g_client_config,
                          sc.client_configuration,
                          g_internal_config,
                          sc.internal_configuration,
                          g_global_config,
                          sc.global_configuration) = pk_alert_constant.get_available
               AND decode(i_flg, g_client_config, nvl(sc.global_configuration, g_available_n), g_available_n) =
                   g_available_n
               AND sc.id_market = l_generic
               AND (i_search IS NULL OR decode(i_search,
                                               NULL,
                                               NULL,
                                               (translate(upper(pk_sysconfig.get_desc_config(i_lang, sc.id_sys_config)),
                                                          k_accent_y,
                                                          k_accent_n))) LIKE l_search ESCAPE
                    '\' OR decode(i_search,
                                  NULL,
                                  NULL,
                                  (translate(upper(pk_sysconfig.get_desc_functionality(i_lang, sc.id_sys_config)),
                                             k_accent_y,
                                             k_accent_n))) LIKE l_search ESCAPE '\')
               AND sc.id_software IN (SELECT l_generic
                                        FROM dual
                                      UNION ALL
                                      SELECT si.id_software
                                        FROM software_institution si
                                       WHERE si.id_institution = i_id_institution)
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_inst AS table_varchar)))
               AND sc.id_sys_config NOT IN (SELECT column_value
                                              FROM TABLE(CAST(a_mkt AS table_varchar)));
    
    BEGIN
        g_error := upper('Get institution market cursor');
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   l_generic)
          INTO l_market
          FROM dual;
        -- open and colect institution configurations
        g_error := upper('Open Institution cursor');
        OPEN c_instit_param(i_client, i_search);
        FETCH c_instit_param BULK COLLECT
            INTO a_inst_sc_id,
                 a_inst_sc_desc,
                 a_inst_sc_desc_func,
                 a_inst_sc_desc_val,
                 a_inst_sc_fill,
                 a_inst_sc_sw,
                 a_inst_sc_desc_sw,
                 a_inst_sc_flg_edit,
                 a_inst_sc_flg_schm;
        CLOSE c_instit_param;
        -- open and colect market configurations
        g_error := upper('Open Market cursor');
        OPEN c_mkt_param(a_inst_sc_id, l_market, i_client, i_search);
        FETCH c_mkt_param BULK COLLECT
            INTO a_mkt_sc_id,
                 a_mkt_sc_desc,
                 a_mkt_sc_desc_func,
                 a_mkt_sc_desc_val,
                 a_mkt_sc_fill,
                 a_mkt_sc_sw,
                 a_mkt_sc_desc_sw,
                 a_mkt_sc_flg_edit,
                 a_mkt_sc_flg_schm;
        CLOSE c_mkt_param;
    
        -- open and colect generic configurations  
        g_error := upper('Open Generic cursor');
        OPEN c_generic_param(a_inst_sc_id, a_mkt_sc_id, i_client, i_search);
        FETCH c_generic_param BULK COLLECT
            INTO a_gnrc_sc_id,
                 a_gnrc_sc_desc,
                 a_gnrc_sc_desc_func,
                 a_gnrc_sc_desc_val,
                 a_gnrc_sc_fill,
                 a_gnrc_sc_sw,
                 a_gnrc_sc_desc_sw,
                 a_gnrc_sc_flg_edit,
                 a_gnrc_sc_flg_schm;
        CLOSE c_generic_param;
    
        g_error := upper('Join all arrays');
        -- join all result arrays as final data
        a_final_sc_id        := a_inst_sc_id MULTISET UNION a_mkt_sc_id MULTISET UNION a_gnrc_sc_id;
        a_final_sc_desc      := a_inst_sc_desc MULTISET UNION a_mkt_sc_desc MULTISET UNION a_gnrc_sc_desc;
        a_final_sc_desc_func := a_inst_sc_desc_func MULTISET UNION a_mkt_sc_desc_func MULTISET UNION
                                a_gnrc_sc_desc_func;
        a_final_sc_desc_val  := a_inst_sc_desc_val MULTISET UNION a_mkt_sc_desc_val MULTISET UNION a_gnrc_sc_desc_val;
        a_final_sc_fill      := a_inst_sc_fill MULTISET UNION a_mkt_sc_fill MULTISET UNION a_gnrc_sc_fill;
        a_final_sc_sw        := a_inst_sc_sw MULTISET UNION a_mkt_sc_sw MULTISET UNION a_gnrc_sc_sw;
        a_final_sc_desc_sw   := a_inst_sc_desc_sw MULTISET UNION a_mkt_sc_desc_sw MULTISET UNION a_gnrc_sc_desc_sw;
        a_final_sc_flg_edit  := a_inst_sc_flg_edit MULTISET UNION a_mkt_sc_flg_edit MULTISET UNION a_gnrc_sc_flg_edit;
        a_final_sc_flg_schm  := a_inst_sc_flg_schm MULTISET UNION a_mkt_sc_flg_schm MULTISET UNION a_gnrc_sc_flg_schm;
    
        g_error := upper('get ordered final cursor');
        -- convert info into ordered result table
        SELECT t_rec_sysconfig(all_sc.id_sys_config,
                               all_sc.desc_sys_config,
                               all_sc.desc_functionality,
                               all_sc.desc_value,
                               all_sc.fill_type,
                               all_sc.id_software,
                               all_sc.software_name,
                               all_sc.flg_edit,
                               all_sc.flg_schema)
          BULK COLLECT
          INTO t_scfg_data
          FROM (SELECT sc_id.id_sys_config,
                       sc_desc.desc_sys_config,
                       sc_df.desc_functionality,
                       sc_dv.desc_value,
                       sc_f.fill_type,
                       sc_sw.id_software,
                       sc_dsw.software_name,
                       sc_fe.flg_edit,
                       sc_fs.flg_schema,
                       sc_id.rn
                  FROM (SELECT rownum rn, column_value id_sys_config
                          FROM TABLE(CAST(a_final_sc_id AS table_varchar))) sc_id,
                       (SELECT rownum rn, column_value desc_sys_config
                          FROM TABLE(CAST(a_final_sc_desc AS table_varchar))) sc_desc,
                       (SELECT rownum rn, column_value desc_functionality
                          FROM TABLE(CAST(a_final_sc_desc_func AS table_varchar))) sc_df,
                       (SELECT rownum rn, column_value desc_value
                          FROM TABLE(CAST(a_final_sc_desc_val AS table_varchar))) sc_dv,
                       (SELECT rownum rn, column_value fill_type
                          FROM TABLE(CAST(a_final_sc_fill AS table_varchar))) sc_f,
                       (SELECT rownum rn, column_value id_software
                          FROM TABLE(CAST(a_final_sc_sw AS table_number))) sc_sw,
                       (SELECT rownum rn, column_value software_name
                          FROM TABLE(CAST(a_final_sc_desc_sw AS table_varchar))) sc_dsw,
                       (SELECT rownum rn, column_value flg_edit
                          FROM TABLE(CAST(a_final_sc_flg_edit AS table_varchar))) sc_fe,
                       (SELECT rownum rn, column_value flg_schema
                          FROM TABLE(CAST(a_final_sc_flg_schm AS table_varchar))) sc_fs
                 WHERE sc_id.rn = sc_desc.rn
                   AND sc_id.rn = sc_df.rn
                   AND sc_id.rn = sc_dv.rn
                   AND sc_id.rn = sc_f.rn
                   AND sc_id.rn = sc_sw.rn
                   AND sc_id.rn = sc_dsw.rn
                   AND sc_id.rn = sc_fe.rn
                   AND sc_id.rn = sc_fs.rn) all_sc
         ORDER BY all_sc.desc_functionality;
    
        g_error := upper('REturn list cursor');
        -- open output cursor and colect records in defined interval
        OPEN o_sysconfig_out FOR
            SELECT id_sys_config,
                   desc_sys_config,
                   desc_functionality,
                   desc_value,
                   flg_fill_type fill_type,
                   id_software,
                   software_name,
                   flg_edit,
                   flg_schema
              FROM (SELECT rownum rn, t.*
                      FROM TABLE(CAST(t_scfg_data AS t_table_sysconfig)) t)
             WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sysconfig_out);
            RETURN FALSE;
        
    END get_all_sys_config_data;
    /** @headcom
    * Public Function. Update Value in SYS_CONFIG when is in security or global administrator
    *
    * @param      I_LANG                               Language ID
    * @param      I_ID_SYS_CONFIG                      Configuration ID
    * @param      I_VALUE                              Configuration value
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     RMG
    * @version    0.1
    * @since      2013/11/06
    */
    FUNCTION set_sys_config_global
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_software    IN table_number,
        i_value          IN table_varchar,
        i_fill_type      IN sys_config.fill_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(30) := 'GET_SYS_CONFIG';
        l_flg_schema VARCHAR2(1);
    BEGIN
    
        FOR i IN 1 .. i_id_software.count
        LOOP
        
            BEGIN
                SELECT sc.flg_schema
                  INTO l_flg_schema
                  FROM sys_config sc
                 WHERE sc.id_sys_config = i_id_sys_config
                   AND sc.id_institution = i_id_institution
                   AND sc.id_software = i_id_software(i)
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_schema := 'A';
            END;
        
            IF l_flg_schema = 'F'
            THEN
            
                MERGE INTO finger_db.sys_config fsc
                USING (SELECT i_id_sys_config id_sys_config, i_value(i) VALUE
                         FROM dual) f_sys_conf
                ON (fsc.id_sys_config = f_sys_conf.id_sys_config)
                WHEN MATCHED THEN
                    UPDATE
                       SET fsc.value = f_sys_conf.value
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sys_config, VALUE, desc_sys_config)
                    VALUES
                        (f_sys_conf.id_sys_config,
                         f_sys_conf.value,
                         (SELECT desc_sys_config
                            FROM (SELECT desc_sys_config
                                    FROM sys_config cc
                                   WHERE cc.id_sys_config = i_id_sys_config
                                     AND cc.id_institution IN (i_id_institution, 0)
                                     AND cc.id_software IN (i_id_software(i), 0)
                                   ORDER BY id_software DESC, id_institution DESC)
                           WHERE rownum < 2));
            
                g_error := 'UPDATE SYS_CONFIG_TRANSLATION';
                UPDATE sys_config_translation
                   SET adw_last_update = SYSDATE
                 WHERE id_sys_config = i_id_sys_config
                   AND id_language = i_lang;
            
            ELSE
            
                MERGE INTO sys_config sc
                USING (SELECT i_id_sys_config id_sys_config,
                              i_id_institution id_institution,
                              i_id_software(i) id_software,
                              i_fill_type fill_type,
                              i_value(i) VALUE
                       
                         FROM dual) sys_conf
                ON (sc.id_sys_config = sys_conf.id_sys_config AND sc.id_institution = sys_conf.id_institution AND sc.id_software = sys_conf.id_software)
                WHEN MATCHED THEN
                    UPDATE
                       SET sc.value = sys_conf.value
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sys_config,
                         VALUE,
                         id_institution,
                         id_software,
                         fill_type,
                         client_configuration,
                         internal_configuration,
                         global_configuration,
                         desc_sys_config,
                         flg_schema,
                         mvalue)
                    VALUES
                        (sys_conf.id_sys_config,
                         sys_conf.value,
                         sys_conf.id_institution,
                         sys_conf.id_software,
                         sys_conf.fill_type,
                         'N',
                         'Y',
                         'Y',
                         (SELECT desc_sys_config
                            FROM (SELECT desc_sys_config
                                    FROM sys_config cc
                                   WHERE cc.id_sys_config = i_id_sys_config
                                     AND cc.id_institution IN (i_id_institution, 0)
                                     AND cc.id_software IN (i_id_software(i), 0)
                                   ORDER BY id_software DESC, id_institution DESC)
                           WHERE rownum < 2),
                         l_flg_schema,
                         (SELECT mvalue
                            FROM (SELECT cc.mvalue
                                    FROM sys_config cc
                                   WHERE cc.id_sys_config = i_id_sys_config
                                     AND cc.id_institution IN (i_id_institution, 0)
                                     AND cc.id_software IN (i_id_software(i), 0)
                                   ORDER BY id_software DESC, id_institution DESC)
                           WHERE rownum < 2));
            
                g_error := 'UPDATE SYS_CONFIG_TRANSLATION';
                UPDATE sys_config_translation
                   SET adw_last_update = SYSDATE
                 WHERE id_sys_config = i_id_sys_config
                   AND id_language = i_lang;
            
            END IF;
        
        END LOOP;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_sys_config_global;

    /**
    Method that returns list of values to sys_config multichoices
    **/
    FUNCTION get_sys_config_values
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sys_config  IN sys_config.id_sys_config%TYPE,
        i_id_institution IN sys_config.id_institution%TYPE,
        i_id_software    IN sys_config.id_software%TYPE,
        o_values         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SYS_CONFIG_VALUES';
        l_market    market.id_market%TYPE := 0;
    
        l_source_code VARCHAR2(1000) := '';
        l_res_vals    t_coll_values_domain_mkt;
    BEGIN
        g_error  := 'GET INSTITUTION ' || i_id_institution || ' MARKET ID';
        l_market := pk_utils.get_institution_market(i_lang, i_id_institution);
    
        -- get typed list of values 
        g_error := 'GET CONFIGURATION MULTICHOICE SOURCE CODE';
        SELECT mvalue
          INTO l_source_code
          FROM (SELECT mvalue,
                       row_number() over(PARTITION BY id_sys_config ORDER BY id_institution DESC, id_software DESC, id_market DESC) rn
                  FROM sys_config
                 WHERE id_sys_config = i_id_sys_config
                   AND id_institution IN (i_id_institution, 0)
                   AND id_market IN (l_market, 0)
                   AND id_software IN (i_id_software, 0))
         WHERE rn = 1;
    
        g_error := 'EXECUTE AND COLLECT CONFIGURATION MULTICHOICE RESULTS';
        EXECUTE IMMEDIATE 'SELECT t_rec_values_domain_mkt(t_res.desc_val, t_res.val, t_res.img_name, t_res.rank, t_res.code_domain)             
              FROM table(' || l_source_code || ') t_res' BULK COLLECT
            INTO l_res_vals
            USING i_lang, i_id_institution, i_id_software;
    
        -- >> check source code (need sys_config uk values) << --    
        g_error := 'GET SYS_CONFIG VALUES CURSOR';
        OPEN o_values FOR
            SELECT *
              FROM TABLE(l_res_vals);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_TEST',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_values);
            RETURN FALSE;
    END get_sys_config_values;

    PROCEDURE set_deprecated(i_id_sys_config IN VARCHAR2) IS
    BEGIN
    
        pk_sys_configuration.set_deprecated(i_id_sys_config => i_id_sys_config);
    
    END set_deprecated;

    PROCEDURE set_activated(i_id_sys_config IN VARCHAR2) IS
    BEGIN
    
        pk_sys_configuration.set_activated(i_id_sys_config => i_id_sys_config);
    
    END set_activated;

    PROCEDURE upd_desc_config
    (
        i_id_sys_config   IN VARCHAR2,
        i_desc_sys_config IN VARCHAR2
    ) IS
    BEGIN
    
        pk_sys_configuration.upd_desc_config(i_id_sys_config   => i_id_sys_config,
                                             i_desc_sys_config => i_desc_sys_config);
    
    END upd_desc_config;

    -- only for data_access purpose
    function get_data_access_inst return number is
      l_id_institution	number;
    begin

        l_id_institution := pk_sysconfig.get_config('DATA_ACCES_DEFAULT_INSTITUTION', 0, 0);
    		
        return l_id_institution;

    end get_data_access_inst;


BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_sysconfig;
/
