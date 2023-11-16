/*-- Last Change Revision: $Rev: 2026777 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_ext_instit IS

    g_num_records CONSTANT NUMBER(24) := 50;

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
    * Returns Number of External Institutions
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_search                Search
    * @param o_ext_insitit           Number of External institution
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_instit_list_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        o_ext_insitit    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_LIST_COUNT ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF i_search IS NULL
        THEN
        
            g_error := 'GET EXT_INSTIT DATA';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INSTIT_LIST_DATA ' || g_error);
            SELECT COUNT(i.id_institution)
              INTO o_ext_insitit
              FROM institution i
             WHERE i.flg_available = pk_alert_constant.get_available
               AND i.flg_external = pk_alert_constant.get_yes
               AND i.id_market = l_id_market;
        
        ELSE
        
            g_error := 'GET EXT_INSTIT DATA';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INSTIT_LIST_DATA ' || g_error);
            SELECT COUNT(i.id_institution)
              INTO o_ext_insitit
              FROM institution i
             WHERE i.flg_available = pk_alert_constant.get_available
               AND i.flg_external = pk_alert_constant.get_yes
               AND i.id_market = l_id_market
               AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                             'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                             'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%';
        
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
                                              i_function => 'GET_EXT_INSTIT_LIST_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ext_instit_list_count;

    /********************************************************************************************
    * Returns External Institutions data
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    *
    * @return                        table of external institution (t_table_ext_inst)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_instit_list_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_ext_inst IS
    
        l_date     t_table_ext_inst;
        l_date_res t_table_ext_inst;
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_LIST_DATA ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF i_search IS NULL
        THEN
        
            g_error := 'GET EXT_INSTIT DATA';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INSTIT_LIST_DATA ' || g_error);
            SELECT t_rec_ext_inst(id_institution,
                                  code_institution,
                                  flg_type,
                                  zip_code,
                                  location,
                                  id_country,
                                  dn_flg_status,
                                  flg_editable) BULK COLLECT
              INTO l_date
              FROM (SELECT i.id_institution,
                           i.code_institution,
                           i.flg_type,
                           i.zip_code,
                           i.location,
                           ia.id_country,
                           i.dn_flg_status,
                           decode(i.flg_external,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_editable
                      FROM institution i, inst_attributes ia
                     WHERE i.flg_available = pk_alert_constant.get_available
                       AND i.flg_external = pk_alert_constant.get_yes
                       AND i.id_market = l_id_market
                       AND ia.id_institution = i.id_institution
                       AND ia.flg_available = pk_alert_constant.get_available
                     ORDER BY i.id_institution);
        
        ELSE
        
            g_error := 'GET EXT_INSTIT DATA';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INSTIT_LIST_DATA ' || g_error);
            SELECT t_rec_ext_inst(id_institution,
                                  code_institution,
                                  flg_type,
                                  zip_code,
                                  location,
                                  id_country,
                                  dn_flg_status,
                                  flg_editable) BULK COLLECT
              INTO l_date
              FROM (SELECT i.id_institution,
                           i.code_institution,
                           i.flg_type,
                           i.zip_code,
                           i.location,
                           ia.id_country,
                           i.dn_flg_status,
                           decode(i.flg_external,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_no,
                                  pk_alert_constant.get_yes) flg_editable
                      FROM institution i, inst_attributes ia
                     WHERE i.flg_available = pk_alert_constant.get_available
                       AND i.flg_external = pk_alert_constant.get_yes
                       AND i.id_market = l_id_market
                       AND ia.id_institution = i.id_institution
                       AND ia.flg_available = pk_alert_constant.get_available
                       AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                     'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                     'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                     ORDER BY i.id_institution);
        
        END IF;
    
        g_error := 'GET EXT_PROF TABLE FROM RECORD: ' || to_char(i_start_record) || ' TO RECORD: ' ||
                   to_char(i_start_record + i_num_records - 1);
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST_DATA ' || g_error);
        SELECT t_rec_ext_inst(id_institution,
                              institution_name,
                              flg_type,
                              zip_code,
                              city,
                              country,
                              dn_flg_status,
                              flg_editable) BULK COLLECT
          INTO l_date_res
          FROM (SELECT rownum rn, t.*
                  FROM TABLE(CAST(l_date AS t_table_ext_inst)) t)
         WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
        RETURN l_date_res;
    
    END get_ext_instit_list_data;

    /********************************************************************************************
    * Returns External Institutions
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_ext_insitit           External institution
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_instit_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_ext_insitit    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_INSTIT CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INSTIT_LIST ' || g_error);
        OPEN o_ext_insitit FOR
            SELECT t.id_institution,
                   ia.id_inst_attributes id_inst_attributes,
                   pk_translation.get_translation(i_lang, t.institution_name) institution_name,
                   get_ext_inst_license_number(i_lang, t.id_institution, NULL, l_id_market) license_number,
                   t.flg_type,
                   pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', t.flg_type, i_lang) flg_type_desc,
                   t.zip_code,
                   t.city,
                   t.dn_flg_status dn_flg_status,
                   pk_sysdomain.get_img(i_lang, 'AB_INSTITUTION.DN_FLG_STATUS', t.dn_flg_status) dn_flg_status_img,
                   t.flg_editable,
                   get_ext_inst_list_by_lic_num(i_lang,
                                                NULL,
                                                (get_ext_inst_license_number(i_lang, t.id_institution, NULL, l_id_market)),
                                                l_id_market,
                                                i_id_institution) id_stg_institution
              FROM inst_attributes ia,
                   (SELECT *
                      FROM TABLE(get_ext_instit_list_data(i_lang,
                                                          i_id_institution,
                                                          i_search,
                                                          i_start_record,
                                                          i_num_records))) t
             WHERE ia.id_institution = t.id_institution
             ORDER BY institution_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_INSTIT_LIST',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_ext_insitit);
            RETURN FALSE;
    END get_ext_instit_list;

    /********************************************************************************************
    * Cancel an External Institution
    *
    * @param i_lang                  Language id
    * @param i_institution           External insitutions ID's to cancel
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Nelson Sousa
    * @since                         2015/01/20
    * @version                       2.6.4.3
    ********************************************************************************************/
    FUNCTION cancel_ext_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_institution.count
        LOOP
            pk_api_ab_tables.upd_ab_institution(id_ab_institution_in => i_institution(i),
                                                flg_available_in     => 'N',
                                                flg_available_nin    => FALSE);
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
                                              i_function => 'CANCEL_EXT_INSTITUTION',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_ext_institution;

    /********************************************************************************************
    * Returns External Institutions License number
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_stg_institution    Staging area External Institution identifier
    * @param i_id_market             Market identifier
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_license_number
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_stg_institution IN stg_institution.id_stg_institution%TYPE,
        i_id_market          IN market.id_market%TYPE
    ) RETURN VARCHAR2 IS
    
        l_value VARCHAR2(200 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        CASE i_id_market
            WHEN g_market_pt THEN
                SELECT nvl((SELECT i.ext_code
                             FROM institution i
                            WHERE i.id_institution = i_id_institution),
                           NULL)
                  INTO l_value
                  FROM dual;
            
            WHEN g_market_nl THEN
                IF i_id_institution IS NOT NULL
                   AND i_id_stg_institution IS NULL
                THEN
                    SELECT nvl((SELECT ifd.value
                                 FROM institution_field_data ifd, field_market fm
                                WHERE ifd.id_institution = i_id_institution
                                  AND ifd.id_field_market = fm.id_field_market
                                  AND fm.id_field = 40
                                  AND fm.id_market = g_market_nl
                                  AND rownum = 1),
                               NULL)
                      INTO l_value
                      FROM dual;
                ELSIF i_id_stg_institution IS NOT NULL
                      AND i_id_institution IS NULL
                THEN
                    SELECT nvl((SELECT sifd.value
                                 FROM stg_institution_field_data sifd
                                WHERE sifd.id_stg_institution = i_id_stg_institution
                                  AND sifd.id_field = 40
                                  AND rownum = 1),
                               NULL)
                      INTO l_value
                      FROM dual;
                END IF;
            
            ELSE
                l_value := NULL;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_INST_LICENSE_NUMBER',
                                              o_error    => l_error);
            RETURN NULL;
    END get_ext_inst_license_number;

    /********************************************************************************************
    * Returns External Institution General data
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_market             Market identifier
    * @param o_ext_inst_data         Genral data in insitution table
    * @param o_ext_inst_field_data   General data from a specific country
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_general_data
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_market           IN market.id_market%TYPE,
        o_ext_inst_data       OUT pk_types.cursor_type,
        o_ext_inst_field_data OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_institution IS NULL
        THEN
        
            g_error := 'GET EXT_INST_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_data FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T016'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T018'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T052')) field_name,
                       decode(r, 1, 'T', 2, 'M', 3, 'T') field_fill_type,
                       decode(r, 2, pk_backoffice_ext_prof.get_ext_state_list(i_lang, 'AB_INSTITUTION.FLG_TYPE', 1)) multichoice_id,
                       decode(r, 2, pk_backoffice_ext_prof.get_ext_state_list(i_lang, 'AB_INSTITUTION.FLG_TYPE', 2)) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 20, 3, 30) rank,
                       decode(r, 1, 'i_inst_name', 2, 'i_flg_type', 3, 'i_abbreviation') set_parameters
                  FROM (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 3)
                 ORDER BY rank;
        
            g_error := 'GET EXT_INST_FIELD_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_field_data FOR
                SELECT fm.id_field_market,
                       f.id_field,
                       pk_translation.get_translation(i_lang, f.code_field) field_name,
                       fm.fill_type field_fill_type,
                       decode(to_char(fm.multichoice_id),
                              NULL,
                              NULL,
                              pk_utils.query_to_string(fm.multichoice_id, g_string_delim)) multichoice_id,
                       (CASE nvl(length(fm.multichoice_desc), 0)
                           WHEN 0 THEN
                            NULL
                           ELSE
                            pk_utils.query_to_clob(fm.multichoice_desc, g_string_delim)
                       END) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm
                 WHERE f.flg_field_prof_inst = 'I'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 5
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available;
        
        ELSE
        
            g_error := 'GET EXT_INST_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_data FOR
                SELECT NULL id_field_market,
                       NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T016'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T018'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T052')) field_name,
                       decode(r, 1, 'T', 2, 'M', 3, 'T') field_fill_type,
                       decode(r, 2, pk_backoffice_ext_prof.get_ext_state_list(i_lang, 'AB_INSTITUTION.FLG_TYPE', 1)) multichoice_id,
                       decode(r, 2, pk_backoffice_ext_prof.get_ext_state_list(i_lang, 'AB_INSTITUTION.FLG_TYPE', 2)) multichoice_desc,
                       decode(r,
                              1,
                              pk_translation.get_translation(i_lang, i.code_institution),
                              2,
                              i.flg_type,
                              3,
                              i.abbreviation) field_value,
                       decode(r,
                              1,
                              pk_translation.get_translation(i_lang, i.code_institution),
                              2,
                              pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang),
                              3,
                              i.abbreviation) field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 20, 3, 30) rank,
                       decode(r, 1, 'i_inst_name', 2, 'i_flg_type', 3, 'i_abbreviation') set_parameters
                  FROM institution i,
                       (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 3)
                 WHERE i.id_institution = i_id_institution
                 ORDER BY rank;
        
            g_error := 'GET EXT_INST_FIELD_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_field_data FOR
                SELECT fm.id_field_market,
                       f.id_field,
                       pk_translation.get_translation(i_lang, f.code_field) field_name,
                       fm.fill_type field_fill_type,
                       decode(to_char(fm.multichoice_id),
                              NULL,
                              NULL,
                              pk_utils.query_to_string(fm.multichoice_id, g_string_delim)) multichoice_id,
                       (CASE nvl(length(fm.multichoice_desc), 0)
                           WHEN 0 THEN
                            NULL
                           ELSE
                            pk_utils.query_to_clob(fm.multichoice_desc, g_string_delim)
                       END) multichoice_desc,
                       ifd.value field_value,
                       decode(fm.fill_type, 'M', NULL, ifd.value) field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm, institution_field_data ifd
                 WHERE f.flg_field_prof_inst = 'I'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 5
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                   AND ifd.id_institution(+) = i_id_institution
                   AND ifd.id_field_market = fm.id_field_market;
        
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
                                              i_function => 'GET_EXT_INST_GENERAL_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_inst_data);
            pk_types.open_my_cursor(o_ext_inst_field_data);
            RETURN FALSE;
        
    END get_ext_inst_general_data;

    /********************************************************************************************
    * Returns External Institution Contacts data
    *
    * @param i_lang                     Language id
    * @param i_id_institution           Institution identifier
    * @param i_id_market             Market identifier
    * @param o_ext_inst_contacts        Genral data in insitution table
    * @param o_ext_inst_field_contacts  General data from a specific country
    * @param o_error                    Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_contacts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_market               IN market.id_market%TYPE,
        o_ext_inst_contacts       OUT pk_types.cursor_type,
        o_ext_inst_field_contacts OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_institution IS NULL
        THEN
        
            g_error := 'GET EXT_INST_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_contacts FOR
                SELECT NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T025'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T058'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T008'),
                              4,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T010'),
                              5,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T055'),
                              6,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T056'),
                              7,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T029')) field_name,
                       decode(r, 1, 'T', 2, 'T', 3, 'T', 4, 'T', 5, 'T', 6, 'T', 7, 'M') field_fill_type,
                       decode(r, 7, get_ext_country_list(i_lang, 1)) multichoice_id,
                       decode(r, 7, get_ext_country_list(i_lang, 2)) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 40, 3, 50, 4, 60, 5, 70, 6, 80, 7, 90) rank,
                       decode(r,
                              1,
                              'i_street',
                              2,
                              'i_postal_code',
                              3,
                              'i_city',
                              4,
                              'i_phone',
                              5,
                              'i_fax',
                              6,
                              'i_email',
                              7,
                              'i_country') set_parameters
                  FROM (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 7)
                 ORDER BY rank;
        
            g_error := 'GET EXT_INST_FIELD_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_field_contacts FOR
                SELECT fm.id_field_market,
                       f.id_field,
                       pk_translation.get_translation(i_lang, f.code_field) field_name,
                       fm.fill_type field_fill_type,
                       decode(to_char(fm.multichoice_id),
                              NULL,
                              NULL,
                              pk_utils.query_to_string(fm.multichoice_id, g_string_delim)) multichoice_id,
                       (CASE nvl(length(fm.multichoice_desc), 0)
                           WHEN 0 THEN
                            NULL
                           ELSE
                            pk_utils.query_to_clob(fm.multichoice_desc, g_string_delim)
                       END) multichoice_desc,
                       NULL field_value,
                       NULL field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm, institution_field_data ifd
                 WHERE f.flg_field_prof_inst = 'I'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 6
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                   AND ifd.id_institution(+) = i_id_institution
                   AND ifd.id_field_market(+) = fm.id_field_market;
        
        ELSE
        
            g_error := 'GET EXT_INST_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_contacts FOR
                SELECT NULL id_field,
                       decode(r,
                              1,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T025'),
                              2,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T058'),
                              3,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T008'),
                              4,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T010'),
                              5,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T055'),
                              6,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T056'),
                              7,
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T029')) field_name,
                       decode(r, 1, 'T', 2, 'T', 3, 'T', 4, 'T', 5, 'T', 6, 'T', 7, 'M') field_fill_type,
                       decode(r, 7, get_ext_country_list(i_lang, 1)) multichoice_id,
                       decode(r, 7, get_ext_country_list(i_lang, 2)) multichoice_desc,
                       decode(r,
                              1,
                              i.address,
                              2,
                              i.zip_code,
                              3,
                              i.location,
                              4,
                              i.phone_number,
                              5,
                              i.fax_number,
                              6,
                              ia.email,
                              7,
                              ia.id_country) field_value,
                       decode(r,
                              1,
                              i.address,
                              2,
                              i.zip_code,
                              3,
                              i.location,
                              4,
                              i.phone_number,
                              5,
                              i.fax_number,
                              6,
                              ia.email,
                              7,
                              pk_translation.get_translation(i_lang,
                                                             (SELECT c.code_country
                                                                FROM country c
                                                               WHERE c.id_country = ia.id_country))) field_value_desc,
                       NULL id_institution,
                       decode(r, 1, 10, 2, 40, 3, 50, 4, 60, 5, 70, 6, 80, 7, 90) rank,
                       decode(r,
                              1,
                              'i_street',
                              2,
                              'i_postal_code',
                              3,
                              'i_city',
                              4,
                              'i_phone',
                              5,
                              'i_fax',
                              6,
                              'i_email',
                              7,
                              'i_country') set_parameters
                  FROM institution i,
                       inst_attributes ia,
                       country c,
                       (SELECT rownum r
                          FROM all_objects
                         WHERE rownum <= 7)
                 WHERE i.id_institution = i_id_institution
                   AND i.id_institution = ia.id_institution
                   AND c.id_country(+) = ia.id_country
                 ORDER BY rank;
        
            g_error := 'GET EXT_INST_FIELD_DATA CURSOR';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INST.GET_EXT_INST_GENERAL_DATA ' || g_error);
            OPEN o_ext_inst_field_contacts FOR
                SELECT fm.id_field_market,
                       f.id_field,
                       pk_translation.get_translation(i_lang, f.code_field) field_name,
                       fm.fill_type field_fill_type,
                       decode(to_char(fm.multichoice_id),
                              NULL,
                              NULL,
                              pk_utils.query_to_string(fm.multichoice_id, g_string_delim)) multichoice_id,
                       (CASE nvl(length(fm.multichoice_desc), 0)
                           WHEN 0 THEN
                            NULL
                           ELSE
                            pk_utils.query_to_clob(fm.multichoice_desc, g_string_delim)
                       END) multichoice_desc,
                       ifd.value field_value,
                       decode(fm.fill_type, 'M', NULL, ifd.value) field_value_desc,
                       0 id_institution,
                       f.rank rank,
                       NULL set_parameters
                  FROM field f, field_market fm, institution_field_data ifd
                 WHERE f.flg_field_prof_inst = 'I'
                   AND f.flg_available = pk_alert_constant.get_available
                   AND f.id_field_type = 6
                   AND f.id_field = fm.id_field
                   AND fm.id_market = i_id_market
                   AND fm.flg_available = pk_alert_constant.get_available
                   AND ifd.id_institution(+) = i_id_institution
                   AND ifd.id_field_market(+) = fm.id_field_market;
        
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
                                              i_function => 'GET_EXT_INST_CONTACTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_inst_contacts);
            pk_types.open_my_cursor(o_ext_inst_field_contacts);
            RETURN FALSE;
        
    END get_ext_inst_contacts;

    /********************************************************************************************
    * Create/Update external institution
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_inst_att           Institution Attibutes ID
    * @param i_inst_name             Institution name
    * @param i_flg_type              Flag type for institution - H - Hospital, C - Primary Care, P - Private Practice
    * @param i_abbreviation          Institution abbreviation
    * @param i_phone                 Institution phone
    * @param i_fax                   Institution fax
    * @param i_email                 Institution email
    * @param i_street                Institution address
    * @param i_city                  Institution City
    * @param i_postal_code           Institution postal code
    * @param i_country               Institution Country ID
    * @param i_market                Institution Market ID
    * @param i_flg_available         Available - Y - Yes, N - No 
    * @param i_fields                List of dynamic fields
    * @param i_values                Information values for the dynamic fields
    * @param o_id_institution        institution ID
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_inst_name      IN VARCHAR2,
        i_flg_type       IN institution.flg_type%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_phone          IN institution.phone_number%TYPE,
        i_fax            IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_street         IN institution.address%TYPE,
        i_city           IN institution.location%TYPE,
        i_postal_code    IN institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_market         IN institution.id_market%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_fields         IN table_number,
        i_values         IN table_varchar,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
    
        IF NOT pk_backoffice.set_ext_institution(i_lang           => i_lang,
                                                 i_id_institution => i_id_institution,
                                                 i_id_inst_att    => i_id_inst_att,
                                                 i_desc           => i_inst_name,
                                                 i_id_parent      => NULL,
                                                 i_flg_type       => i_flg_type,
                                                 i_abbreviation   => i_abbreviation,
                                                 i_phone_number   => i_phone,
                                                 i_fax            => i_fax,
                                                 i_email          => i_email,
                                                 i_ext_code       => NULL,
                                                 i_adress         => i_street,
                                                 i_location       => i_city,
                                                 i_district       => NULL,
                                                 i_zip_code       => i_postal_code,
                                                 i_country        => i_country,
                                                 i_flg_available  => nvl(i_flg_available, 'Y'),
                                                 i_id_tz_region   => NULL,
                                                 i_id_market      => i_market,
                                                 i_commit_at_end  => FALSE,
                                                 o_id_institution => o_id_institution,
                                                 o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        FOR i IN 1 .. i_fields.count
        LOOP
        
            g_error := 'MERGE INTO INSTITUTION_FIELD_DATA';
            MERGE INTO institution_field_data ifd
            USING (SELECT i_fields(i) fld, i_values(i) val
                     FROM dual) t
            ON (ifd.id_field_market = t.fld AND ifd.id_institution = o_id_institution)
            WHEN MATCHED THEN
                UPDATE
                   SET ifd.value = t.val
            WHEN NOT MATCHED THEN
                INSERT
                    (id_institution, id_field_market, VALUE)
                VALUES
                    (o_id_institution, t.fld, t.val);
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error || ' / ' || l_error.err_desc,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EXT_INSTITUTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EXT_INSTITUTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_ext_institution;

    /********************************************************************************************
    * Number of  external institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institutions ID
    * @param i_name                External institution name
    * @param i_category            External institution Type
    * @param i_city                External institution City
    * @param i_postal_code         External institution Postal Code
    * @param i_postal_code_from    External institution range of postal codes
    * @param i_postal_code_to      External institution range of postal codes
    * @param i_search              Search
    * @param o_ext_prof_list       Number of external institutions
    * @param o_error               error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @since                       2010/06/03
    * @version                     2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_inst_count
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN institution.address%TYPE,
        i_postal_code      IN institution.zip_code%TYPE,
        i_postal_code_from IN institution.zip_code%TYPE,
        i_postal_code_to   IN institution.zip_code%TYPE,
        i_search           IN VARCHAR2,
        o_ext_inst_list    OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
        l_license_array table_varchar := table_varchar();
    
        l_count_1_i     NUMBER := 0;
        l_count_2_i     NUMBER := 0;
        l_count_3_i1    NUMBER := 0;
        l_count_3_i2    NUMBER := 0;
        l_count_1_stgi  NUMBER := 0;
        l_count_2_stgi  NUMBER := 0;
        l_count_3_stgi1 NUMBER := 0;
        l_count_3_stgi2 NUMBER := 0;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_INST_COUNT ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_INSTITUTION linked to INSTITUTION (ID: ' || i_id_institution || ' ) LICENSES';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT license_number BULK COLLECT
          INTO l_license_array
          FROM (SELECT DISTINCT get_ext_inst_license_number(i_lang, i_id_institution, NULL, l_id_market) license_number
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market)
         WHERE license_number IS NOT NULL;
    
        IF i_postal_code IS NULL
           AND i_postal_code_from IS NULL
           AND i_postal_code_to IS NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(i.id_institution)
                  INTO l_count_1_i
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_1_stgi
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            ELSE
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(i.id_institution)
                  INTO l_count_1_i
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_1_stgi
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgi.institution_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            END IF;
        
            o_ext_inst_list := l_count_1_i + l_count_1_stgi;
        
        ELSIF i_postal_code IS NOT NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(i.id_institution)
                  INTO l_count_2_i
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.zip_code IS NULL OR
                       (translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_2_stgi
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.zip_code IS NULL OR
                       (translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            ELSE
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(i.id_institution)
                  INTO l_count_2_i
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.zip_code IS NULL OR
                       (translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')));
            
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_2_stgi
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgi.institution_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.zip_code IS NULL OR
                       (translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_postal_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            END IF;
        
            o_ext_inst_list := l_count_2_i + l_count_2_stgi;
        ELSE
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(i.id_institution)
                  INTO l_count_3_i1
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.zip_code IS NULL OR
                       ((translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (i.zip_code IS NULL OR
                       ((translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))));
            
                SELECT COUNT(i.id_institution)
                  INTO l_count_3_i2
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.zip_code IS NULL OR
                       ((translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(upper(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))));
            
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_3_stgi1
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.zip_code IS NULL OR
                       ((translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (stgi.zip_code IS NULL OR
                       ((translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_3_stgi2
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.zip_code IS NULL OR
                       ((translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(upper(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            ELSE
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT COUNT(i.id_institution)
                  INTO l_count_3_i1
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.zip_code IS NULL OR
                       ((translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (i.zip_code IS NULL OR
                       ((translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))));
            
                SELECT COUNT(i.id_institution)
                  INTO l_count_3_i2
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market
                   AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                       (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.address IS NULL OR
                       (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (i.zip_code IS NULL OR
                       ((translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(upper(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))));
            
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_3_stgi1
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgi.institution_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.zip_code IS NULL OR
                       ((translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                       (stgi.zip_code IS NULL OR
                       ((translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       (translate(upper(i_postal_code_to),
                                      ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                      ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
                SELECT COUNT(stgi.id_stg_institution)
                  INTO l_count_3_stgi2
                  FROM stg_institution stgi
                 WHERE stgi.id_institution = i_id_institution
                   AND stgi.id_market = l_id_market
                   AND (stgi.institution_name IS NULL OR
                       (translate(upper(stgi.institution_name),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND translate(upper(stgi.institution_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                       (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang)),
                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                   ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' ||
                       translate(upper(i_category), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.city IS NULL OR
                       (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                       ('%' || translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                   AND (stgi.zip_code IS NULL OR
                       ((translate(upper(stgi.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                       (translate(upper(i_postal_code_from),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                       (translate(upper(i_postal_code_to),
                                     ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                     ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                   AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                       (SELECT column_value
                          FROM TABLE(CAST(l_license_array AS table_varchar)));
            
            END IF;
        
            o_ext_inst_list := l_count_3_i1 + l_count_3_i2 + l_count_3_stgi1 + l_count_3_stgi2;
        
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
                                              i_function => 'FIND_EXT_INST_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
    END find_ext_inst_count;

    /********************************************************************************************
    * Find external institution data
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institutions ID
    * @param i_name                External institution name
    * @param i_category            External institution Type
    * @param i_city                External institution City
    * @param i_postal_code         External institution Postal Code
    * @param i_postal_code_from    External institution range of postal codes
    * @param i_postal_code_to      External institution range of postal codes
    * @param i_search              Search
    * @param i_start_record        Paging - initial recrod number
    * @param i_num_records         Paging - number of records to display
    * @param o_ext_prof_list       List of external institutions
    * @param o_error               error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @since                       2010/06/03
    * @version                     2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_inst_data
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN institution.address%TYPE,
        i_postal_code      IN institution.zip_code%TYPE,
        i_postal_code_from IN institution.zip_code%TYPE,
        i_postal_code_to   IN institution.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_stg_ext_inst IS
    
        l_date     t_table_stg_ext_inst;
        l_date_res t_table_stg_ext_inst;
    
        l_id_market market.id_market%TYPE;
    
        l_license_array table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_INST_DATA ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_INSTITUTION linked to INSTITUTION (ID: ' || i_id_institution || ' ) LICENSES';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT license_number BULK COLLECT
          INTO l_license_array
          FROM (SELECT DISTINCT get_ext_inst_license_number(i_lang, i_id_institution, NULL, l_id_market) license_number
                  FROM institution i
                 WHERE i.flg_external = pk_alert_constant.get_yes
                   AND i.flg_available = pk_alert_constant.get_available
                   AND i.id_market = l_id_market)
         WHERE license_number IS NOT NULL;
    
        IF i_postal_code IS NULL
           AND i_postal_code_from IS NULL
           AND i_postal_code_to IS NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, institution_name, city, zip_code);
            
            ELSE
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgi.institution_name),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, institution_name, city, zip_code);
            
            END IF;
        
        ELSIF i_postal_code IS NOT NULL
        THEN
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.zip_code IS NULL OR
                               (translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.zip_code IS NULL OR
                               (translate(upper(stgi.zip_code),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, institution_name, city, zip_code);
            
            ELSE
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.zip_code IS NULL OR
                               (translate(upper(i.zip_code), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgi.institution_name),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.zip_code IS NULL OR
                               (translate(upper(stgi.zip_code),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_postal_code),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, institution_name, city, zip_code);
            
            END IF;
        ELSE
        
            IF i_search IS NULL
            THEN
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.zip_code IS NULL OR
                               ((translate(upper(i.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (i.zip_code IS NULL OR
                               ((translate(upper(i.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                        
                        UNION
                        SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.zip_code IS NULL OR
                               ((translate(upper(i.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(upper(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.zip_code IS NULL OR
                               ((translate(upper(stgi.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (stgi.zip_code IS NULL OR
                               ((translate(upper(stgi.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.zip_code IS NULL OR
                               ((translate(upper(stgi.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(upper(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, institution_name, city, zip_code);
            
            ELSE
            
                g_error := 'GET EXT_INST_LIST CURSOR';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.FIND_EXT_PROF ' || g_error);
                SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
                  INTO l_date
                  FROM (SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.zip_code IS NULL OR
                               ((translate(upper(i.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (i.zip_code IS NULL OR
                               ((translate(upper(i.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                        
                        UNION
                        SELECT DISTINCT i.id_institution,
                                        pk_translation.get_translation(i_lang, i.code_institution) institution_name,
                                        i.flg_type,
                                        i.zip_code,
                                        i.location city,
                                        pk_alert_constant.get_yes flg_exist
                          FROM institution i
                         WHERE i.flg_external = pk_alert_constant.get_yes
                           AND i.flg_available = pk_alert_constant.get_available
                           AND i.id_market = l_id_market
                           AND (pk_translation.get_translation(i_lang, i.code_institution) IS NULL OR
                               (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.address IS NULL OR
                               (translate(upper(i.address), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (i.zip_code IS NULL OR
                               ((translate(upper(i.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(upper(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgi.institution_name),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.zip_code IS NULL OR
                               ((translate(upper(stgi.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))) OR
                               (stgi.zip_code IS NULL OR
                               ((translate(upper(stgi.zip_code),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun ') LIKE
                               (translate(upper(i_postal_code_to),
                                              ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                        UNION
                        SELECT stgi.id_stg_institution  id_institution,
                               stgi.institution_name,
                               stgi.flg_type,
                               stgi.zip_code,
                               stgi.city,
                               pk_alert_constant.get_no flg_exist
                          FROM stg_institution stgi
                         WHERE stgi.id_institution = i_id_institution
                           AND stgi.id_market = l_id_market
                           AND (stgi.institution_name IS NULL OR
                               (translate(upper(stgi.institution_name),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_name), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND translate(upper(stgi.institution_name),
                                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                               '%' ||
                               translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                           AND (pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', stgi.flg_type, i_lang) IS NULL OR
                               (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE',
                                                                         stgi.flg_type,
                                                                         i_lang)),
                                           ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                           ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' || translate(upper(i_category),
                                                   ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                                   ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.city IS NULL OR
                               (translate(upper(stgi.city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                               ('%' ||
                               translate(upper(i_city), ' áéíóúàèìòùâêîôûãõçäëïöüñ ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                           AND (stgi.zip_code IS NULL OR
                               ((translate(upper(stgi.zip_code),
                                            ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                            ' aeiouaeiouaeiouaocaeioun ') BETWEEN
                               (translate(upper(i_postal_code_from),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%') AND
                               (translate(upper(i_postal_code_to),
                                             ' áéíóúàèìòùâêîôûãõçäëïöüñ ',
                                             ' aeiouaeiouaeiouaocaeioun% ') || '%'))))
                           AND get_ext_inst_license_number(i_lang, NULL, stgi.id_stg_institution, l_id_market) NOT IN
                               (SELECT column_value
                                  FROM TABLE(CAST(l_license_array AS table_varchar)))
                         ORDER BY flg_exist DESC, institution_name, city, zip_code);
            
            END IF;
        
        END IF;
    
        g_error := 'GET EXT_PROF TABLE FROM RECORD: ' || to_char(i_start_record) || ' TO RECORD: ' ||
                   to_char(i_start_record + i_num_records - 1);
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_LIST_DATA ' || g_error);
        SELECT t_rec_stg_ext_inst(id_institution, institution_name, flg_type, zip_code, city, flg_exist) BULK COLLECT
          INTO l_date_res
          FROM (SELECT rownum rn, t.*
                  FROM TABLE(CAST(l_date AS t_table_stg_ext_inst)) t)
         WHERE rn BETWEEN i_start_record AND i_start_record + i_num_records - 1;
    
        RETURN l_date_res;
    
    END find_ext_inst_data;

    /********************************************************************************************
    * Find external institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institutions ID
    * @param i_name                External institution name
    * @param i_category            External institution Type
    * @param i_city                External institution City
    * @param i_postal_code         External institution Postal Code
    * @param i_postal_code_from    External institution range of postal codes
    * @param i_postal_code_to      External institution range of postal codes
    * @param i_search              Search
    * @param i_start_record        Paging - initial recrod number
    * @param i_num_records         Paging - number of records to display
    * @param o_ext_prof_list       List of external institutions
    * @param o_error               error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @since                       2010/06/03
    * @version                     2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN institution.address%TYPE,
        i_postal_code      IN institution.zip_code%TYPE,
        i_postal_code_from IN institution.zip_code%TYPE,
        i_postal_code_to   IN institution.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records,
        o_ext_inst_list    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_INST_LIST CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.FIND_EXT_PROF ' || g_error);
        OPEN o_ext_inst_list FOR
            SELECT DISTINCT id_institution,
                            institution_name,
                            pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', flg_type, i_lang) category,
                            get_ext_inst_license_number(i_lang, id_institution, NULL, l_id_market) license_number,
                            zip_code,
                            city,
                            flg_exist
              FROM (SELECT *
                      FROM TABLE(find_ext_inst_data(i_lang,
                                                    i_id_institution,
                                                    i_name,
                                                    i_category,
                                                    i_city,
                                                    i_postal_code,
                                                    i_postal_code_from,
                                                    i_postal_code_to,
                                                    i_search,
                                                    i_start_record,
                                                    i_num_records)))
             ORDER BY flg_exist DESC, institution_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'FIND_EXT_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_inst_list);
            RETURN FALSE;
        
    END find_ext_inst;

    /********************************************************************************************
    * Update/insert information for external institutions
    *
    * @param i_lang                  Prefered language ID
    * @param i_stg_professional      Staging area External Professional ID's
    * @param i_id_institution        Institution ID
    * @param o_ext_prof              External Professionals ID's imported
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_import_ext_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_stg_institution IN table_number,
        i_id_institution  IN institution.id_institution%TYPE,
        o_ext_inst        OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
        l_exception EXCEPTION;
        l_error t_error_out;
        l_index NUMBER := 1;
    
        --EXTERNAL INSTITUTION
        l_id_institution   institution.id_institution%TYPE;
        l_institution_name pk_translation.t_desc_translation;
        l_flg_type         institution.flg_type%TYPE;
        l_abbreviation     institution.abbreviation%TYPE;
        l_street           institution.address%TYPE;
        l_postal_code      institution.zip_code%TYPE;
        l_city             institution.location%TYPE;
        l_phone            institution.phone_number%TYPE;
        l_fax              institution.fax_number%TYPE;
        l_email            inst_attributes.email%TYPE;
        l_id_country       inst_attributes.id_country%TYPE;
    
        --PROFESSIONAL_FIELDS_DATA
        l_fields table_number := table_number();
        l_values table_varchar := table_varchar();
    
        CURSOR c_ext_inst(c_id_stg_institution stg_institution.id_stg_institution%TYPE) IS
            SELECT stgi.institution_name,
                   stgi.flg_type,
                   stgi.abbreviation,
                   stgi.address,
                   stgi.zip_code,
                   stgi.city,
                   stgi.phone_number,
                   stgi.fax_number,
                   stgi.email,
                   stgi.id_country
              FROM stg_institution stgi
             WHERE stgi.id_stg_institution = c_id_stg_institution
               AND stgi.id_institution = i_id_institution;
    
    BEGIN
    
        o_ext_inst := table_number();
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        FOR i IN 1 .. i_stg_institution.count
        LOOP
        
            g_error := 'GET EXT_INSTITUTION FIELDS TO INSTITUTION (ID: ' || i_id_institution || ' MARKET (ID_MARKET: ' ||
                       l_id_market || ' )';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_IMPORT_EXT_INSTITUTION ' || g_error);
            SELECT fm.id_field_market, stgid.value BULK COLLECT
              INTO l_fields, l_values
              FROM field f, field_market fm, stg_institution_field_data stgid
             WHERE f.flg_field_prof_inst = 'I'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (5, 6)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgid.id_stg_institution = i_stg_institution(i)
               AND stgid.id_field = f.id_field;
        
            OPEN c_ext_inst(i_stg_institution(i));
            LOOP
            
                FETCH c_ext_inst
                    INTO l_institution_name,
                         l_flg_type,
                         l_abbreviation,
                         l_street,
                         l_postal_code,
                         l_city,
                         l_phone,
                         l_fax,
                         l_email,
                         l_id_country;
                EXIT WHEN c_ext_inst%NOTFOUND;
            
                IF NOT set_ext_institution(i_lang           => i_lang,
                                           i_id_institution => NULL,
                                           i_id_inst_att    => NULL,
                                           i_inst_name      => l_institution_name,
                                           i_flg_type       => l_flg_type,
                                           i_abbreviation   => l_abbreviation,
                                           i_phone          => l_phone,
                                           i_fax            => l_fax,
                                           i_email          => l_email,
                                           i_street         => l_street,
                                           i_city           => l_city,
                                           i_postal_code    => l_postal_code,
                                           i_country        => l_id_country,
                                           i_market         => l_id_market,
                                           i_flg_available  => pk_alert_constant.get_available,
                                           i_fields         => l_fields,
                                           i_values         => l_values,
                                           o_id_institution => l_id_institution,
                                           o_error          => l_error)
                THEN
                    RAISE l_exception;
                
                ELSE
                
                    pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => l_id_institution,
                                                                 i_import_code                => NULL,
                                                                 i_record_status              => 'A',
                                                                 i_id_ab_market               => NULL,
                                                                 i_code                       => NULL,
                                                                 i_description                => NULL,
                                                                 i_alt_description            => NULL,
                                                                 i_shortname                  => NULL,
                                                                 i_vat_registration           => NULL,
                                                                 i_timezone_region_code       => NULL,
                                                                 i_rb_country_key             => NULL, --id_country
                                                                 i_rb_regional_classifier_key => NULL,
                                                                 i_id_ab_institution_parent   => NULL,
                                                                 i_flg_type                   => NULL,
                                                                 i_address1                   => NULL,
                                                                 i_address2                   => NULL,
                                                                 i_address3                   => NULL,
                                                                 i_zip_code                   => NULL,
                                                                 i_zip_code_description       => NULL,
                                                                 i_fax_number                 => NULL,
                                                                 i_phone_number               => NULL,
                                                                 i_email                      => NULL,
                                                                 i_logo                       => NULL,
                                                                 i_web_site                   => NULL,
                                                                 i_geo_location_key           => NULL /*l_district*/,
                                                                 i_flg_external               => pk_alert_constant.get_yes,
                                                                 i_code_institution           => NULL,
                                                                 i_flg_available              => NULL,
                                                                 i_rank                       => NULL,
                                                                 i_barcode                    => NULL,
                                                                 i_ine_location               => NULL,
                                                                 i_id_timezone_region         => NULL,
                                                                 i_ext_code                   => NULL,
                                                                 i_dn_flg_status              => 'V',
                                                                 i_adress_type                => NULL,
                                                                 i_contact_det                => NULL,
                                                                 o_id_ab_institution          => l_id_institution);
                
                    o_ext_inst.extend;
                
                    o_ext_inst(l_index) := l_id_institution;
                
                    l_index := l_index + 1;
                END IF;
            
            END LOOP;
        
            CLOSE c_ext_inst;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error || ' / ' || l_error.err_desc,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_IMPORT_EXT_INSTITUTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_IMPORT_EXT_INSTITUTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_import_ext_institution;

    /********************************************************************************************
    * Validate External Institution data changed by the file imported to the staging area
    *
    * @param i_lang                 Language id
    * @param i_institution          Institution id
    * @param o_error                Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/07/07
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION validate_ext_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market   market.id_market%TYPE;
        l_license     institution_field_data.value%TYPE;
        l_institution institution.id_institution%TYPE;
    
        l_data_changed       institution.dn_flg_status%TYPE := 'N';
        l_stg_id_institution stg_institution.id_stg_institution%TYPE;
    
        l_stg_institutions pk_types.cursor_type;
        l_exception EXCEPTION;
        l_error t_error_out;
    
        --CURSOR DAS INSTITUIÇÕES EXTERNOS
        CURSOR c_ext_inst(c_id_market IN market.id_market%TYPE) IS
            SELECT i.id_institution, get_ext_inst_license_number(i_lang, i.id_institution, NULL, c_id_market)
              FROM institution i
             WHERE i.flg_external = pk_alert_constant.get_yes
               AND i.id_market = c_id_market;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_INSTITUTIONS LINKED TO INSTITUTION (ID: ' || i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.VALIDATE_EXT_PROF ' || g_error);
        OPEN c_ext_inst(l_id_market);
        LOOP
            FETCH c_ext_inst
                INTO l_institution, l_license;
            EXIT WHEN c_ext_inst%NOTFOUND;
        
            IF l_license IS NOT NULL
            THEN
            
                g_error := 'GET EXT_STG_INSTIT LINKED TO EXTERNAL INSTITUTION (ID: ' || l_institution;
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.VALIDATE_EXT_PROF ' || g_error);
                IF NOT get_ext_inst_by_license_number(i_lang,
                                                      NULL,
                                                      l_license,
                                                      l_id_market,
                                                      i_id_institution,
                                                      l_stg_institutions,
                                                      l_error)
                THEN
                    RAISE l_exception;
                ELSE
                
                    LOOP
                        FETCH l_stg_institutions
                            INTO l_stg_id_institution;
                        EXIT WHEN l_stg_institutions%NOTFOUND;
                    
                        IF l_stg_id_institution != 0
                        THEN
                        
                            l_data_changed := get_ext_inst_data_update(i_lang,
                                                                       l_institution,
                                                                       l_stg_id_institution,
                                                                       i_id_institution);
                        
                            g_error := 'UPDATE EXTERNAL INSTITUTION (ID: ' || l_institution || ') STATUS OF DATA';
                            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.VALIDATE_EXT_INST ' || g_error);
                            IF l_data_changed = pk_alert_constant.get_yes
                            THEN
                                pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => l_institution,
                                                                             i_import_code                => NULL,
                                                                             i_record_status              => 'A',
                                                                             i_id_ab_market               => NULL,
                                                                             i_code                       => NULL,
                                                                             i_description                => NULL,
                                                                             i_alt_description            => NULL,
                                                                             i_shortname                  => NULL,
                                                                             i_vat_registration           => NULL,
                                                                             i_timezone_region_code       => NULL,
                                                                             i_rb_country_key             => NULL, --id_country
                                                                             i_rb_regional_classifier_key => NULL,
                                                                             i_id_ab_institution_parent   => NULL,
                                                                             i_flg_type                   => NULL,
                                                                             i_address1                   => NULL,
                                                                             i_address2                   => NULL,
                                                                             i_address3                   => NULL,
                                                                             i_zip_code                   => NULL,
                                                                             i_zip_code_description       => NULL,
                                                                             i_fax_number                 => NULL,
                                                                             i_phone_number               => NULL,
                                                                             i_email                      => NULL,
                                                                             i_logo                       => NULL,
                                                                             i_web_site                   => NULL,
                                                                             i_geo_location_key           => NULL /*l_district*/,
                                                                             i_flg_external               => pk_alert_constant.get_yes,
                                                                             i_code_institution           => NULL,
                                                                             i_flg_available              => NULL,
                                                                             i_rank                       => NULL,
                                                                             i_barcode                    => NULL,
                                                                             i_ine_location               => NULL,
                                                                             i_id_timezone_region         => NULL,
                                                                             i_ext_code                   => NULL,
                                                                             i_dn_flg_status              => 'A',
                                                                             i_adress_type                => NULL,
                                                                             i_contact_det                => NULL,
                                                                             o_id_ab_institution          => l_institution);
                                /*UPDATE institution i
                                  SET i.dn_flg_status = 'A'
                                WHERE i.id_institution = l_institution
                                  AND i.flg_external = pk_alert_constant.get_yes;*/
                            
                            END IF;
                        
                        END IF;
                    
                    END LOOP;
                
                    CLOSE l_stg_institutions;
                
                END IF;
            
            END IF;
        
        END LOOP;
    
        CLOSE c_ext_inst;
    
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
                                              i_function => 'VALIDATE_EXT_INST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_ext_inst;

    /********************************************************************************************
    * Returns External Institutions by License number
    *
    * @param i_lang                  Language id
    * @param i_license               License number
    * @param i_stg_license           Staging area license number
    * @param i_id_market             Market identifier
    * @param i_id_institution        Institution id
    * @param o_ext_inst              External institutions
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_by_license_number
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN institution_field_data.value%TYPE,
        i_stg_license    IN stg_institution_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_ext_inst       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        CASE i_id_market
        
            WHEN g_market_nl THEN
                IF i_license IS NOT NULL
                   AND i_stg_license IS NULL
                THEN
                
                    g_error := 'GET EXT_INST CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_BY_LICENSE_NUMBER ' || g_error);
                    OPEN o_ext_inst FOR
                        SELECT ifd.id_institution
                          FROM institution_field_data ifd, field_market fm
                         WHERE ifd.value = i_license
                           AND ifd.id_field_market = fm.id_field_market
                           AND fm.id_field = 40
                           AND fm.id_market = g_market_nl;
                
                ELSIF i_stg_license IS NOT NULL
                      AND i_license IS NULL
                THEN
                
                    g_error := 'GET EXT_PROF CURSOR';
                    pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_BY_LICENSE_NUMBER ' || g_error);
                    OPEN o_ext_inst FOR
                        SELECT sifd.id_stg_institution
                          FROM stg_institution_field_data sifd
                         WHERE sifd.value = i_stg_license
                           AND sifd.id_field = 40
                           AND sifd.id_institution = i_id_institution;
                
                END IF;
            
            ELSE
                RETURN TRUE;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_INST_BY_LICENSE_NUMBER',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_inst);
            RETURN FALSE;
        
    END get_ext_inst_by_license_number;

    /********************************************************************************************
    * Returns External Institutions list by License number
    *
    * @param i_lang                  Language id
    * @param i_license               License number
    * @param i_stg_license           Staging area license number
    * @param i_id_market             Market identifier
    * @param i_id_institution        Institution id
    *
    * @return                        List of external professonals
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_list_by_lic_num
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN institution_field_data.value%TYPE,
        i_stg_license    IN stg_institution_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_value VARCHAR2(200 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        CASE i_id_market
        
            WHEN g_market_nl THEN
                IF i_license IS NOT NULL
                   AND i_stg_license IS NULL
                THEN
                
                    SELECT nvl(pk_utils.query_to_string('SELECT ifd.id_institution
                          FROM institution_field_data ifd, field_market fm
                         WHERE ifd.value = ''' || i_license || '''
                           AND ifd.id_field_market = fm.id_field_market
                           AND fm.id_field = 40
                           AND fm.id_market = g_market_nl',
                                                        g_string_delim),
                               NULL)
                      INTO l_value
                      FROM dual;
                
                ELSIF i_stg_license IS NOT NULL
                      AND i_license IS NULL
                THEN
                
                    SELECT nvl(pk_utils.query_to_string('SELECT sifd.id_stg_institution
                          FROM stg_institution_field_data sifd
                         WHERE sifd.value = ''' || i_stg_license || '''
                           AND sifd.id_field = 40
                           and sifd.id_institution = ' ||
                                                        i_id_institution,
                                                        g_string_delim),
                               NULL)
                      INTO l_value
                      FROM dual;
                
                END IF;
            
            ELSE
                l_value := NULL;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_INST_LIST_BY_LIC_NUM',
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_ext_inst_list_by_lic_num;

    /********************************************************************************************
    * Compare an External Institutions data with the staging area data
    *
    * @param i_lang                  Language id
    * @param i_id_ext_institution    External institution ID
    * @param i_id_stg_institution    External institution ID in staging area
    * @param i_id_institution        Institution ID
    *
    * @return                        Flag of changed data ('Y' - different data, 'N' - no different data)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_data_update
    (
        i_lang               IN language.id_language%TYPE,
        i_id_ext_institution IN institution.id_institution%TYPE,
        i_id_stg_institution IN stg_institution.id_stg_institution%TYPE,
        i_id_institution     IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_market    market.id_market%TYPE;
        l_data_changed prof_institution.dn_flg_status%TYPE := 'N';
    
        l_error t_error_out;
    
        --EXTERNAL INSTITUTION
        l_ext_inst_data    VARCHAR2(4000 CHAR);
        l_institution_name pk_translation.t_desc_translation;
        l_flg_type         institution.flg_type%TYPE;
        l_abbreviation     institution.abbreviation%TYPE;
        l_street           institution.address%TYPE;
        l_postal_code      institution.zip_code%TYPE;
        l_city             institution.location%TYPE;
        l_phone            institution.phone_number%TYPE;
        l_fax              institution.fax_number%TYPE;
        l_email            inst_attributes.email%TYPE;
        l_country          inst_attributes.id_country%TYPE;
    
        --EXTERNAL STG INSTITUTION
        l_ext_stg_inst_data    VARCHAR2(4000 CHAR);
        l_stg_institution_name stg_institution.institution_name%TYPE;
        l_stg_flg_type         stg_institution.flg_type%TYPE;
        l_stg_abbreviation     stg_institution.abbreviation%TYPE;
        l_stg_street           stg_institution.address%TYPE;
        l_stg_postal_code      stg_institution.zip_code%TYPE;
        l_stg_city             stg_institution.city%TYPE;
        l_stg_phone            stg_institution.phone_number%TYPE;
        l_stg_fax              stg_institution.fax_number%TYPE;
        l_stg_email            stg_institution.email%TYPE;
        l_stg_country          stg_institution.id_country%TYPE;
    
        --INSTITUTION_FIELDS_DATA
        l_ifd_value institution_field_data.value%TYPE;
    
        --INSTITUTION_STG_FIELDS_DATA
        l_stg_fields table_number := table_number();
        l_stg_values table_varchar := table_varchar();
    
    BEGIN
    
        l_data_changed := pk_alert_constant.get_no;
    
        g_error := 'GET INSTITUTION COUNTRY';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_UPDATE ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        SELECT pk_translation.get_translation(i_lang, i.code_institution),
               i.flg_type,
               i.abbreviation,
               i.address,
               i.zip_code,
               i.location,
               i.phone_number,
               i.fax_number,
               ia.email,
               ia.id_country
          INTO l_institution_name,
               l_flg_type,
               l_abbreviation,
               l_street,
               l_postal_code,
               l_city,
               l_phone,
               l_fax,
               l_email,
               l_country
          FROM institution i, inst_attributes ia
         WHERE i.id_institution = i_id_ext_institution
           AND i.flg_external = pk_alert_constant.get_yes
           AND ia.id_institution = i.id_institution;
    
        SELECT stgi.institution_name,
               stgi.flg_type,
               stgi.abbreviation,
               stgi.address,
               stgi.zip_code,
               stgi.city,
               stgi.phone_number,
               stgi.fax_number,
               stgi.email,
               stgi.id_country
          INTO l_stg_institution_name,
               l_stg_flg_type,
               l_stg_abbreviation,
               l_stg_street,
               l_stg_postal_code,
               l_stg_city,
               l_stg_phone,
               l_stg_fax,
               l_stg_email,
               l_stg_country
          FROM stg_institution stgi
         WHERE stgi.id_stg_institution = i_id_stg_institution
           AND stgi.id_institution = i_id_institution;
    
        l_ext_inst_data := l_institution_name || '|' || l_flg_type || '|' || l_abbreviation || '|' || l_street || '|' ||
                           l_postal_code || '|' || l_city || '|' || l_phone || '|' || l_fax || '|' || l_email || '|' ||
                           l_country;
    
        l_ext_stg_inst_data := l_stg_institution_name || '|' || l_stg_flg_type || '|' || l_stg_abbreviation || '|' ||
                               l_stg_street || '|' || l_stg_postal_code || '|' || l_stg_city || '|' || l_stg_phone || '|' ||
                               l_stg_fax || '|' || l_stg_email || '|' || l_stg_country;
    
        IF l_ext_inst_data = l_ext_stg_inst_data
        THEN
        
            g_error := 'GET EXT_INST FIELDS TO INSTITUTION (ID: ' || i_id_institution || ' ) MARKET (ID_MARKET: ' ||
                       l_id_market || ' )';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_UPDATE ' || g_error);
            SELECT fm.id_field_market, stgid.value BULK COLLECT
              INTO l_stg_fields, l_stg_values
              FROM field f, field_market fm, stg_institution_field_data stgid
             WHERE f.flg_field_prof_inst = 'I'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (5, 6)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgid.id_stg_institution = i_id_stg_institution
               AND stgid.id_institution = i_id_institution
               AND stgid.id_field = f.id_field;
        
            FOR i IN 1 .. l_stg_fields.count
            LOOP
            
                SELECT nvl((SELECT ifd.value
                             FROM institution_field_data ifd
                            WHERE ifd.id_field_market = l_stg_fields(i)
                              AND ifd.id_institution = i_id_ext_institution),
                           NULL)
                  INTO l_ifd_value
                  FROM dual;
            
                IF l_ifd_value != l_stg_values(i)
                THEN
                
                    l_data_changed := pk_alert_constant.get_yes;
                
                END IF;
            
            END LOOP;
        
        ELSE
        
            l_data_changed := pk_alert_constant.get_yes;
        
        END IF;
    
        RETURN l_data_changed;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_INST_DATA_UPDATE',
                                              o_error    => l_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        
    END get_ext_inst_data_update;

    /********************************************************************************************
    * Compare an External Institution data with the staging area data
    *
    * @param i_lang                      Language id
    * @param i_id_ext_institution        External institution ID
    * @param i_stg_institution           External institution ID's in staging area
    * @param i_id_institution            Institution ID
    * @param o_ext_inst_data             Cursor containing the different data
    * @param o_ext_inst_fields_data      Cursor containing the different data
    * @param o_ext_stg_inst_data         Cursor containing the different data
    * @param o_ext_stg_inst_fields_data  Cursor containing the different data
    * @param o_error                     Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_data_review
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_ext_institution       IN institution.id_institution%TYPE,
        i_stg_institution          IN table_number,
        i_id_institution           IN institution.id_institution%TYPE,
        o_ext_inst_data            OUT pk_types.cursor_type,
        o_ext_inst_fields_data     OUT pk_types.cursor_type,
        o_ext_stg_inst_data        OUT pk_types.cursor_type,
        o_ext_stg_inst_fields_data OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_DATA_REVIEW ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET EXT_INST_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_DATA_REVIEW ' || g_error);
        OPEN o_ext_inst_data FOR
            SELECT NULL id_field_market,
                   NULL id_field,
                   decode(r,
                          1,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T016'),
                          2,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T018'),
                          3,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T052'),
                          4,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T025'),
                          5,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T058'),
                          6,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T008'),
                          7,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T010'),
                          8,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T055'),
                          9,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T056'),
                          10,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T029')) field_name,
                   decode(r, 1, 'T', 2, 'M', 3, 'T', 4, 'T', 5, 'T', 6, 'T', 7, 'T', 8, 'T', 9, 'T', 10, 'M') field_fill_type,
                   decode(r,
                          1,
                          pk_translation.get_translation(i_lang, i.code_institution),
                          2,
                          i.flg_type,
                          3,
                          i.abbreviation,
                          4,
                          i.address,
                          5,
                          i.zip_code,
                          6,
                          i.location,
                          7,
                          i.phone_number,
                          8,
                          i.fax_number,
                          9,
                          ia.email,
                          10,
                          ia.id_country) field_value,
                   decode(r,
                          1,
                          pk_translation.get_translation(i_lang, i.code_institution),
                          2,
                          pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang),
                          3,
                          i.abbreviation,
                          4,
                          i.address,
                          5,
                          i.zip_code,
                          6,
                          i.location,
                          7,
                          i.phone_number,
                          8,
                          i.fax_number,
                          9,
                          ia.email,
                          10,
                          decode(ia.id_country,
                                 NULL,
                                 NULL,
                                 pk_translation.get_translation(i_lang,
                                                                (SELECT c.code_country
                                                                   FROM country c
                                                                  WHERE c.id_country = ia.id_country)))) field_value_desc,
                   decode(r,
                          1,
                          'i_inst_name',
                          2,
                          'i_flg_type',
                          3,
                          'i_abbreviation',
                          4,
                          'i_street',
                          5,
                          'i_postal_code',
                          6,
                          'i_city',
                          7,
                          'i_phone',
                          8,
                          'i_fax',
                          9,
                          'i_email',
                          10,
                          'i_country') set_parameters
              FROM institution i,
                   inst_attributes ia,
                   (SELECT rownum r
                      FROM all_objects
                     WHERE rownum <= 10)
             WHERE i.id_institution = i_id_ext_institution
               AND ia.id_institution = i.id_institution;
    
        g_error := 'GET EXT_INST_FIELDS_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_DATA_REVIEW ' || g_error);
        OPEN o_ext_inst_fields_data FOR
            SELECT fm.id_field_market,
                   fm.id_field,
                   pk_translation.get_translation(i_lang, f.code_field) field_name,
                   fm.fill_type field_fill_type,
                   decode(to_char(fm.multichoice_id),
                          NULL,
                          NULL,
                          pk_utils.query_to_string(fm.multichoice_id, g_string_delim)) multichoice_id,
                   (CASE nvl(length(fm.multichoice_desc), 0)
                       WHEN 0 THEN
                        NULL
                       ELSE
                        pk_utils.query_to_clob(fm.multichoice_desc, g_string_delim)
                   END) multichoice_desc,
                   ifd.value field_value,
                   decode(fm.fill_type, 'M', NULL, ifd.value) field_value_desc,
                   0 id_institution,
                   NULL set_parameters
              FROM field f, field_market fm, institution_field_data ifd
             WHERE f.flg_field_prof_inst = 'I'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (5, 6)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND ifd.id_institution(+) = i_id_ext_institution
               AND ifd.id_field_market(+) = fm.id_field_market;
    
        g_error := 'GET EXT_STG_INST_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.GET_EXT_INST_DATA_REVIEW ' || g_error);
        OPEN o_ext_stg_inst_data FOR
            SELECT NULL id_field_market,
                   NULL id_field,
                   NULL id_field_market,
                   NULL id_field,
                   decode(r,
                          1,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T016'),
                          2,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T018'),
                          3,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T052'),
                          4,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T025'),
                          5,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T058'),
                          6,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T008'),
                          7,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T010'),
                          8,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T055'),
                          9,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T056'),
                          10,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_INSTITUTIONS_T029')) field_name,
                   decode(r, 1, 'T', 2, 'M', 3, 'T', 4, 'T', 5, 'T', 6, 'T', 7, 'T', 8, 'T', 9, 'T', 10, 'M') field_fill_type,
                   decode(r,
                          1,
                          stgi.institution_name,
                          2,
                          stgi.flg_type,
                          3,
                          stgi.abbreviation,
                          4,
                          stgi.address,
                          5,
                          stgi.zip_code,
                          6,
                          stgi.city,
                          7,
                          stgi.phone_number,
                          8,
                          stgi.fax_number,
                          9,
                          stgi.email,
                          10,
                          stgi.id_country) field_value,
                   decode(r,
                          1,
                          stgi.institution_name,
                          2,
                          stgi.flg_type,
                          3,
                          stgi.abbreviation,
                          4,
                          stgi.address,
                          5,
                          stgi.zip_code,
                          6,
                          stgi.city,
                          7,
                          stgi.phone_number,
                          8,
                          stgi.fax_number,
                          9,
                          stgi.email,
                          10,
                          pk_translation.get_translation(i_lang, stgi.id_country)) field_value_desc,
                   decode(r,
                          1,
                          'i_inst_name',
                          2,
                          'i_flg_type',
                          3,
                          'i_abbreviation',
                          4,
                          'i_street',
                          5,
                          'i_postal_code',
                          6,
                          'i_city',
                          7,
                          'i_phone',
                          8,
                          'i_fax',
                          9,
                          'i_email',
                          10,
                          'i_country') set_parameters
              FROM stg_institution stgi,
                   (SELECT rownum r
                      FROM all_objects
                     WHERE rownum <= 10)
             WHERE stgi.id_stg_institution IN
                   (SELECT column_value
                      FROM TABLE(CAST(i_stg_institution AS table_number)))
               AND stgi.id_institution = i_id_institution;
    
        g_error := 'GET EXT_STG_PROF_FIELDS_DATA CURSOR';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_PROF.GET_EXT_PROF_DATA_REVIEW ' || g_error);
        OPEN o_ext_stg_inst_fields_data FOR
            SELECT fm.id_field_market,
                   fm.id_field,
                   pk_translation.get_translation(i_lang, f.code_field) field_name,
                   fm.fill_type field_fill_type,
                   decode(to_char(fm.multichoice_id),
                          NULL,
                          NULL,
                          pk_utils.query_to_string(fm.multichoice_id, g_string_delim)) multichoice_id,
                   (CASE nvl(length(fm.multichoice_desc), 0)
                       WHEN 0 THEN
                        NULL
                       ELSE
                        pk_utils.query_to_clob(fm.multichoice_desc, g_string_delim)
                   END) multichoice_desc,
                   stgid.value field_value,
                   decode(fm.fill_type, 'M', NULL, stgid.value) field_value_desc,
                   0 id_institution,
                   NULL set_parameters
              FROM field f, field_market fm, stg_institution_field_data stgid
             WHERE f.flg_field_prof_inst = 'I'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (5, 6)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgid.id_stg_institution IN
                   (SELECT column_value
                      FROM TABLE(CAST(i_stg_institution AS table_number)))
               AND stgid.id_field(+) = f.id_field
               AND stgid.id_institution(+) = i_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXT_PROF_DATA_REVIEW',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ext_inst_data);
            pk_types.open_my_cursor(o_ext_stg_inst_data);
            pk_types.open_my_cursor(o_ext_inst_fields_data);
            pk_types.open_my_cursor(o_ext_stg_inst_fields_data);
            RETURN FALSE;
        
    END get_ext_inst_data_review;

    /********************************************************************************************
    * Import the staging area data for an External Institution
    *
    * @param i_lang                  Language id
    * @param i_institution           External institution ID's
    * @param i_stg_institution       External institution ID's in staging area
    * @param i_id_institution        Institution ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_accept_data_update
    (
        i_lang            IN language.id_language%TYPE,
        i_institution     IN table_number,
        i_stg_institution IN table_number,
        i_id_institution  IN institution.id_institution%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
        l_exception EXCEPTION;
        l_error t_error_out;
    
        --EXTERNAL INSTITUTION
        l_id_institution   institution.id_institution%TYPE;
        l_id_inst_att      inst_attributes.id_inst_attributes%TYPE;
        l_institution_name pk_translation.t_desc_translation;
        l_flg_type         institution.flg_type%TYPE;
        l_abbreviation     institution.abbreviation%TYPE;
        l_street           institution.address%TYPE;
        l_postal_code      institution.zip_code%TYPE;
        l_city             institution.location%TYPE;
        l_phone            institution.phone_number%TYPE;
        l_fax              institution.fax_number%TYPE;
        l_email            inst_attributes.email%TYPE;
        l_country          inst_attributes.id_country%TYPE;
    
        --INSTITUTION_FIELDS_DATA
        l_fields table_number := table_number();
        l_values table_varchar := table_varchar();
    
        CURSOR c_ext_inst(c_id_stg_institution stg_institution.id_stg_institution%TYPE) IS
            SELECT stgi.institution_name,
                   stgi.flg_type,
                   stgi.abbreviation,
                   stgi.address,
                   stgi.zip_code,
                   stgi.city,
                   stgi.phone_number,
                   stgi.fax_number,
                   stgi.email,
                   stgi.id_country
              FROM stg_institution stgi
             WHERE stgi.id_stg_institution = c_id_stg_institution
               AND stgi.id_institution = i_id_institution;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_ACCEPT_DATA_UPDATE ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        FOR i IN 1 .. i_institution.count
        LOOP
        
            SELECT nvl((SELECT ia.id_inst_attributes
                         FROM inst_attributes ia
                        WHERE ia.id_institution = i_institution(i)),
                       0)
              INTO l_id_inst_att
              FROM dual;
        
            g_error := 'GET EXT_INST FIELDS TO INSTITUTION (ID: ' || i_institution(i) || ' ) MARKET (ID_MARKET: ' ||
                       l_id_market || ' )';
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_ACCEPT_DATA_UPDATE ' || g_error);
            SELECT fm.id_field_market, stgid.value BULK COLLECT
              INTO l_fields, l_values
              FROM field f, field_market fm, stg_institution_field_data stgid
             WHERE f.flg_field_prof_inst = 'I'
               AND f.flg_available = pk_alert_constant.get_available
               AND f.id_field_type IN (5, 6)
               AND f.id_field = fm.id_field
               AND fm.id_market = l_id_market
               AND fm.flg_available = pk_alert_constant.get_available
               AND stgid.id_stg_institution = i_stg_institution(i)
               AND stgid.id_field = f.id_field;
        
            OPEN c_ext_inst(i_stg_institution(i));
            LOOP
            
                g_error := 'GET EXT_INST DATA (ID_STG_INSTITUTION: ' || i_stg_institution(i) ||
                           ' ) MARKET (ID_MARKET: ' || l_id_market || ' )';
                pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_ACCEPT_DATA_UPDATE ' || g_error);
                FETCH c_ext_inst
                    INTO l_institution_name,
                         l_flg_type,
                         l_abbreviation,
                         l_street,
                         l_postal_code,
                         l_city,
                         l_phone,
                         l_fax,
                         l_email,
                         l_country;
                EXIT WHEN c_ext_inst%NOTFOUND;
            
                IF NOT set_ext_institution(i_lang           => i_lang,
                                           i_id_institution => i_institution(i),
                                           i_id_inst_att    => l_id_inst_att,
                                           i_inst_name      => l_institution_name,
                                           i_flg_type       => l_flg_type,
                                           i_abbreviation   => l_abbreviation,
                                           i_phone          => l_phone,
                                           i_fax            => l_fax,
                                           i_email          => l_email,
                                           i_street         => l_street,
                                           i_city           => l_city,
                                           i_postal_code    => l_postal_code,
                                           i_country        => l_country,
                                           i_market         => l_id_market,
                                           i_flg_available  => pk_alert_constant.get_available,
                                           i_fields         => l_fields,
                                           i_values         => l_values,
                                           o_id_institution => l_id_institution,
                                           o_error          => l_error)
                THEN
                    RAISE l_exception;
                
                ELSE
                    pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => i_institution(i),
                                                                 i_import_code                => NULL,
                                                                 i_record_status              => 'A',
                                                                 i_id_ab_market               => NULL,
                                                                 i_code                       => NULL,
                                                                 i_description                => NULL,
                                                                 i_alt_description            => NULL,
                                                                 i_shortname                  => NULL,
                                                                 i_vat_registration           => NULL,
                                                                 i_timezone_region_code       => NULL,
                                                                 i_rb_country_key             => NULL, --id_country
                                                                 i_rb_regional_classifier_key => NULL,
                                                                 i_id_ab_institution_parent   => NULL,
                                                                 i_flg_type                   => NULL,
                                                                 i_address1                   => NULL,
                                                                 i_address2                   => NULL,
                                                                 i_address3                   => NULL,
                                                                 i_zip_code                   => NULL,
                                                                 i_zip_code_description       => NULL,
                                                                 i_fax_number                 => NULL,
                                                                 i_phone_number               => NULL,
                                                                 i_email                      => NULL,
                                                                 i_logo                       => NULL,
                                                                 i_web_site                   => NULL,
                                                                 i_geo_location_key           => NULL /*l_district*/,
                                                                 i_flg_external               => pk_alert_constant.get_yes,
                                                                 i_code_institution           => NULL,
                                                                 i_flg_available              => NULL,
                                                                 i_rank                       => NULL,
                                                                 i_barcode                    => NULL,
                                                                 i_ine_location               => NULL,
                                                                 i_id_timezone_region         => NULL,
                                                                 i_ext_code                   => NULL,
                                                                 i_dn_flg_status              => 'V',
                                                                 i_adress_type                => NULL,
                                                                 i_contact_det                => NULL,
                                                                 o_id_ab_institution          => l_id_institution);
                    /*UPDATE institution i
                      SET i.dn_flg_status = 'V'
                    WHERE i.id_institution = i_institution(i)
                      AND i.flg_external = pk_alert_constant.get_yes;*/
                
                END IF;
            
            END LOOP;
        
            CLOSE c_ext_inst;
        
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
                                              i_function => 'SET_ACCEPT_DATA_UPDATE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_accept_data_update;

    /********************************************************************************************
    * Reject the staging area data for an External Institution
    *
    * @param i_lang                  Language id
    * @param i_institution           External institution ID's
    * @param i_id_institution        Institution ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_reject_data_update
    (
        i_lang           IN language.id_language%TYPE,
        i_institution    IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institution institution.id_institution%TYPE := 0;
    BEGIN
    
        FOR i IN 1 .. i_institution.count
        LOOP
        
            g_error := 'UPDATE INSTITUTION to DN_FLG_STATUS = ''E'' - ID_INSTITUTION = ' || i_institution(i) ||
                       ' IN ID_INSTITUTION = ' || i_id_institution;
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_REJECT_DATA_UPDATE ' || g_error);
            pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => i_institution(i),
                                                         i_import_code                => NULL,
                                                         i_record_status              => 'A',
                                                         i_id_ab_market               => NULL,
                                                         i_code                       => NULL,
                                                         i_description                => NULL,
                                                         i_alt_description            => NULL,
                                                         i_shortname                  => NULL,
                                                         i_vat_registration           => NULL,
                                                         i_timezone_region_code       => NULL,
                                                         i_rb_country_key             => NULL, --id_country
                                                         i_rb_regional_classifier_key => NULL,
                                                         i_id_ab_institution_parent   => NULL,
                                                         i_flg_type                   => NULL,
                                                         i_address1                   => NULL,
                                                         i_address2                   => NULL,
                                                         i_address3                   => NULL,
                                                         i_zip_code                   => NULL,
                                                         i_zip_code_description       => NULL,
                                                         i_fax_number                 => NULL,
                                                         i_phone_number               => NULL,
                                                         i_email                      => NULL,
                                                         i_logo                       => NULL,
                                                         i_web_site                   => NULL,
                                                         i_geo_location_key           => NULL /*l_district*/,
                                                         i_flg_external               => pk_alert_constant.get_yes,
                                                         i_code_institution           => NULL,
                                                         i_flg_available              => NULL,
                                                         i_rank                       => NULL,
                                                         i_barcode                    => NULL,
                                                         i_ine_location               => NULL,
                                                         i_id_timezone_region         => NULL,
                                                         i_ext_code                   => NULL,
                                                         i_dn_flg_status              => 'E',
                                                         i_adress_type                => NULL,
                                                         i_contact_det                => NULL,
                                                         o_id_ab_institution          => l_institution);
            /*UPDATE institution i
              SET i.dn_flg_status = 'E'
            WHERE i.id_institution = i_institution(i)
              AND i.flg_external = pk_alert_constant.get_yes;*/
        
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
                                              i_function => 'SET_REJECT_DATA_UPDATE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_reject_data_update;

    /********************************************************************************************
    * Delete Staging Area data imported to an institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/07/09
    ********************************************************************************************/
    FUNCTION set_delete_stg_ext_inst_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_institution institution.id_institution%TYPE;
        l_institution    institution.id_institution%TYPE := 0;
        --CURSOR DAS INSTITUIÇÕES EXTERNOS
        CURSOR c_ext_inst IS
            SELECT i.id_institution
              FROM institution i
             WHERE i.flg_external = pk_alert_constant.get_yes
               AND i.flg_available = pk_alert_constant.get_available;
    
    BEGIN
    
        g_error := 'DELETE ALL DATA FROM EXTERNAL INSTITUTION IN STG_AREA FROM ID_INSTITUTION = ' || i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_DELETE_STG_EXT_INST_DATA: ' || g_error);
        DELETE FROM stg_professional_field_data pfd
         WHERE pfd.id_institution = i_id_institution;
        DELETE FROM stg_prof_institution pi
         WHERE pi.id_institution = i_id_institution;
        DELETE FROM stg_professional p
         WHERE p.id_institution = i_id_institution;
        DELETE FROM stg_institution_field_data ifd
         WHERE ifd.id_institution = i_id_institution;
        DELETE FROM stg_institution i
         WHERE i.id_institution = i_id_institution;
    
        g_error := 'GET EXT_PROF LINKED TO INSTITUTION (ID: ' || i_id_institution;
        pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_DELETE_STG_EXT_INST_DATA ' || g_error);
        OPEN c_ext_inst;
        LOOP
            FETCH c_ext_inst
                INTO l_id_institution;
            EXIT WHEN c_ext_inst%NOTFOUND;
        
            g_error := 'UPDATE FLAG DATA FROM EXTERNAL INSTITUTION IN  ID_INSTITUTION = ' || i_id_institution;
            pk_alertlog.log_debug('PK_BACKOFFICE_EXT_INSTIT.SET_DELETE_STG_EXT_INST_DATA: ' || g_error);
            pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => l_id_institution,
                                                         i_import_code                => NULL,
                                                         i_record_status              => 'A',
                                                         i_id_ab_market               => NULL,
                                                         i_code                       => NULL,
                                                         i_description                => NULL,
                                                         i_alt_description            => NULL,
                                                         i_shortname                  => NULL,
                                                         i_vat_registration           => NULL,
                                                         i_timezone_region_code       => NULL,
                                                         i_rb_country_key             => NULL, --id_country
                                                         i_rb_regional_classifier_key => NULL,
                                                         i_id_ab_institution_parent   => NULL,
                                                         i_flg_type                   => NULL,
                                                         i_address1                   => NULL,
                                                         i_address2                   => NULL,
                                                         i_address3                   => NULL,
                                                         i_zip_code                   => NULL,
                                                         i_zip_code_description       => NULL,
                                                         i_fax_number                 => NULL,
                                                         i_phone_number               => NULL,
                                                         i_email                      => NULL,
                                                         i_logo                       => NULL,
                                                         i_web_site                   => NULL,
                                                         i_geo_location_key           => NULL /*l_district*/,
                                                         i_flg_external               => pk_alert_constant.get_yes,
                                                         i_code_institution           => NULL,
                                                         i_flg_available              => NULL,
                                                         i_rank                       => NULL,
                                                         i_barcode                    => NULL,
                                                         i_ine_location               => NULL,
                                                         i_id_timezone_region         => NULL,
                                                         i_ext_code                   => NULL,
                                                         i_dn_flg_status              => 'V',
                                                         i_adress_type                => NULL,
                                                         i_contact_det                => NULL,
                                                         o_id_ab_institution          => l_institution);
        
        END LOOP;
    
        CLOSE c_ext_inst;
    
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
                                              i_function => 'SET_DELETE_STG_EXT_PROF_DATA',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_delete_stg_ext_inst_data;

    /********************************************************************************************
    * Get External Institution country list
    *
    * @param i_lang                Prefered language ID
    * @param i_column              Column to return (1 - VAL, 2 - DESC_VAL, 3 - ICON)
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/07/12
    ********************************************************************************************/
    FUNCTION get_ext_country_list
    (
        i_lang   IN language.id_language%TYPE,
        i_column IN NUMBER
    ) RETURN CLOB IS
    
        id_country   table_number;
        rank         table_number;
        country_desc table_varchar;
        flg_default  table_varchar;
    
        l_values pk_types.cursor_type;
    
        l_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT (pk_list.get_country_list(i_lang, profissional(0, 0, 0), l_values, l_error))
        THEN
            RAISE l_exception;
        END IF;
    
        FETCH l_values BULK COLLECT
            INTO id_country, rank, country_desc, flg_default;
    
        CLOSE l_values;
    
        IF i_column = 1
        THEN
            RETURN pk_utils.concat_table(id_country, g_string_delim);
        ELSIF i_column = 2
        THEN
            RETURN pk_utils.concat_table(country_desc, g_string_delim);
        
        ELSE
        
            RETURN NULL;
        
        END IF;
    
    EXCEPTION
        WHEN l_exception THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error.err_desc,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_INSTIT',
                                              'GET_EXT_COUNTRY_LIST',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_INSTIT',
                                              'GET_EXT_COUNTRY_LIST',
                                              l_error);
            pk_types.open_my_cursor(l_values);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_ext_country_list;
    /* Method that returns external institution address information */
    FUNCTION get_ext_institution_address
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_inst_mkt market.id_market%TYPE := 0;
    
        o_address translation.desc_lang_1%TYPE;
        -- capture inst properties
        l_inst_adress   institution.address%TYPE;
        l_inst_location institution.location%TYPE;
        l_inst_zip      institution.zip_code%TYPE;
        -- capture arrays
        l_id_field         table_number := table_number();
        l_field_fill_type  table_varchar := table_varchar();
        l_multichoice_id   table_varchar := table_varchar();
        l_multichoice_desc table_clob := table_clob();
        l_field_value_desc table_varchar := table_varchar();
        l_field_value      table_varchar := table_varchar();
    
        --search helper
        l_found_idx   NUMBER;
        l_desc_list   table_varchar := table_varchar();
        l_temp_state  VARCHAR2(200);
        l_temp_county VARCHAR2(200);
        l_temp_ogd    VARCHAR2(200);
        l_temp_od     VARCHAR2(200);
        l_desc_coutry VARCHAR2(200);
    
    BEGIN
    
        l_inst_mkt := pk_utils.get_institution_market(i_lang, i_id_institution);
        -- get institution main fields
        BEGIN
            SELECT i.address, i.location, i.zip_code
              INTO l_inst_adress, l_inst_location, l_inst_zip
              FROM institution i
             WHERE i.id_institution = i_id_institution;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_inst_adress   := NULL;
                l_inst_location := NULL;
                l_inst_zip      := NULL;
        END;
        --substr(l_list, l_idx + length(p_delim)
        o_address := l_inst_adress;
        IF l_inst_location IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_inst_location;
        END IF;
        -- get attibutes adress field
        SELECT nvl((SELECT pk_translation.get_translation(i_lang, c.code_country)
                     FROM inst_attributes ia
                     JOIN country c
                       ON (c.id_country = ia.id_country)
                    WHERE ia.id_institution = i_id_institution
                      AND c.flg_available = 'Y'),
                   NULL)
          INTO l_desc_coutry
          FROM dual;
    
        -- get_field_values
    
        SELECT fm.fill_type field_fill_type,
               decode(to_char(fm.multichoice_id), NULL, NULL, pk_utils.query_to_string(fm.multichoice_id, '|')) multichoice_id,
               (CASE nvl(length(fm.multichoice_desc), 0)
                   WHEN 0 THEN
                    NULL
                   ELSE
                    pk_utils.query_to_string(fm.multichoice_desc, '|')
               END) multichoice_desc,
               ifd.value field_value,
               decode(fm.fill_type, 'M', NULL, ifd.value) field_value_desc,
               fm.id_field BULK COLLECT
          INTO l_field_fill_type, l_multichoice_id, l_multichoice_desc, l_field_value, l_field_value_desc, l_id_field
          FROM field f, field_market fm, institution_field_data ifd
         WHERE f.flg_field_prof_inst = 'I'
           AND f.flg_available = 'Y'
           AND f.id_field_type = 6
           AND f.id_field = fm.id_field
           AND fm.id_market = l_inst_mkt
           AND fm.flg_available = 'Y'
           AND ifd.id_institution(+) = i_id_institution
           AND ifd.id_field_market(+) = fm.id_field_market;
        FOR i IN 1 .. l_id_field.count
        LOOP
            IF l_id_field(i) = 49
            THEN
                l_found_idx := pk_utils.search_table_varchar(pk_utils.str_split_l(l_multichoice_id(i), '|'),
                                                             l_field_value(i));
            
                IF l_found_idx > -1
                THEN
                    l_desc_list  := pk_utils.str_split_l(l_multichoice_desc(i), '|');
                    l_temp_state := l_desc_list(l_found_idx);
                END IF;
            
            ELSIF l_id_field(i) = 86
            THEN
                l_temp_county := l_field_value_desc(i);
            ELSIF l_id_field(i) = 84
            THEN
                l_temp_ogd := l_field_value_desc(i);
            ELSIF l_id_field(i) = 85
            THEN
                l_temp_od := l_field_value_desc(i);
            END IF;
            l_desc_list := table_varchar();
        END LOOP;
    
        IF l_temp_county IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_temp_county;
        END IF;
        IF l_temp_state IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_temp_state;
        END IF;
        IF l_desc_coutry IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_desc_coutry;
        END IF;
        IF l_inst_zip IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_inst_zip;
        END IF;
        IF l_temp_ogd IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_temp_ogd;
        END IF;
        IF l_temp_od IS NOT NULL
        THEN
            o_address := o_address || ', ' || l_temp_od;
        END IF;
        o_address := ltrim(o_address, ', ');
        RETURN o_address;
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_ext_institution_address;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_ext_instit;
/
